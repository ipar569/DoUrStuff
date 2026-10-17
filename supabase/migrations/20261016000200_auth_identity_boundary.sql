-- Supabase's postgres migration role lacks GRANT OPTION on the managed auth
-- schema. Keep the RPC role out of that schema and expose only caller identity
-- and liveness through these private, argument-free helpers. Their postgres
-- owner can read auth.users; callers cannot ask about a different identity.
create function sync_private.request_owner()
returns uuid language sql stable security definer set search_path = '' as $$
  select auth.uid()
$$;

create function sync_private.live_owner()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from auth.users where id = auth.uid())
$$;

revoke all on function sync_private.request_owner(), sync_private.live_owner()
  from public, anon, authenticated, service_role;
grant execute on function sync_private.request_owner(), sync_private.live_owner()
  to dourstuff_rpc;

alter policy own_account on sync_private.account_state
  using (owner_id = (select sync_private.request_owner()))
  with check (owner_id = (select sync_private.request_owner()));
alter policy own_device on sync_private.device_state
  using (owner_id = (select sync_private.request_owner()))
  with check (owner_id = (select sync_private.request_owner()));
alter policy own_log on sync_private.change_log
  using (owner_id = (select sync_private.request_owner()))
  with check (owner_id = (select sync_private.request_owner()));

create or replace function public.sync_register_device(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := sync_private.request_owner();
  epoch uuid;
  device uuid;
  account sync_private.account_state%rowtype;
  water bigint;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then
    return sync_private.failure('accountDeleted');
  end if;
  if not sync_private.exact_keys(request, array['protocol_version','device_epoch','server_epoch'])
     or not sync_private.is_uuid(request->'device_epoch')
     or not sync_private.is_uuid(request->'server_epoch') then
    raise exception using errcode = '22023', message = 'Invalid account protocol message.';
  end if;
  if (request->'protocol_version')::text is distinct from '2' then
    return sync_private.failure('unsupportedProtocol');
  end if;
  select server_epoch into strict epoch from sync_private.backend_state;
  if epoch <> (request->>'server_epoch')::uuid then
    return sync_private.failure('serverEpochChanged');
  end if;
  device := (request->>'device_epoch')::uuid;
  insert into sync_private.account_state (owner_id) values (caller)
    on conflict (owner_id) do nothing;
  -- Every future writer must hold this same row lock through commit, including
  -- revision allocation, entities, logs, receipts and the device watermark.
  select * into strict account from sync_private.account_state
    where owner_id = caller for update;
  if account.revoked_at is not null then
    return sync_private.failure('accountDeleted');
  end if;
  select high_water into water from sync_private.device_state
    where owner_id = caller and device_epoch = device;
  if not found then
    if (select count(*) from sync_private.device_state where owner_id = caller) >= 1000 then
      return sync_private.failure('rateLimited');
    end if;
    insert into sync_private.device_state (owner_id, device_epoch) values (caller, device);
    water := 0;
  end if;
  return sync_private.success(jsonb_build_object(
    'cursor', jsonb_build_object('server_epoch', epoch, 'revision', account.revision),
    'high_water', water));
end
$$;

create or replace function public.sync_pull(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := sync_private.request_owner();
  epoch uuid;
  account sync_private.account_state%rowtype;
  after_revision bigint;
  page_limit integer;
  through_revision bigint;
  groups jsonb := '[]';
  next_group jsonb;
  row_group record;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then
    return sync_private.failure('accountDeleted');
  end if;
  if not sync_private.exact_keys(request, array['protocol_version','after','limit'])
     or not sync_private.exact_keys(request->'after', array['server_epoch','revision'])
     or not sync_private.is_uuid(request->'after'->'server_epoch')
     or not sync_private.is_counter(request->'after'->'revision')
     or not sync_private.is_counter(request->'limit') then
    raise exception using errcode = '22023', message = 'Invalid account protocol message.';
  end if;
  if (request->'protocol_version')::text is distinct from '2' then
    return sync_private.failure('unsupportedProtocol');
  end if;
  if (request->>'limit')::bigint not between 1 and 200 then
    raise exception using errcode = '22023', message = 'Invalid account protocol message.';
  end if;
  page_limit := (request->>'limit')::integer;
  after_revision := (request->'after'->>'revision')::bigint;
  select server_epoch into strict epoch from sync_private.backend_state;
  if epoch <> (request->'after'->>'server_epoch')::uuid then
    return sync_private.failure('serverEpochChanged');
  end if;
  -- Stable high-water/log view even when subsequent statements run at READ COMMITTED.
  select * into account from sync_private.account_state where owner_id = caller for share;
  if not found then return sync_private.failure('unavailable'); end if;
  if account.revoked_at is not null then return sync_private.failure('accountDeleted'); end if;
  if after_revision < account.retained_after then
    return sync_private.failure('cursorExpired');
  end if;
  if after_revision > account.revision then
    raise exception using errcode = '22023', message = 'Invalid account protocol message.';
  end if;
  through_revision := after_revision;
  for row_group in select revision, records, recovery from sync_private.change_log
    where owner_id = caller and revision > after_revision and revision <= account.revision
    order by revision limit page_limit
  loop
    -- A missing retained revision is corruption, never permission to skip work.
    if row_group.revision <> through_revision + 1 then
      return sync_private.failure('unavailable');
    end if;
    next_group := jsonb_build_object('revision', row_group.revision,
      'records', row_group.records, 'recovery', row_group.recovery);
    if octet_length((groups || jsonb_build_array(next_group))::text) > 4193280 then exit; end if;
    groups := groups || jsonb_build_array(next_group);
    through_revision := row_group.revision;
  end loop;
  if through_revision = after_revision and after_revision < account.revision then
    return sync_private.failure('unavailable');
  end if;
  return sync_private.success(jsonb_build_object(
    'through', jsonb_build_object('server_epoch', epoch, 'revision', through_revision),
    'committed_high_water', account.revision, 'has_more', through_revision < account.revision,
    'groups', groups));
end
$$;
