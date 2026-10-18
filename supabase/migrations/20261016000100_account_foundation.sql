-- Phase 3.1 increment 1: ownership, registration and committed-log reads.
-- No command application or client account mode is enabled by this migration.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'dourstuff_rpc') then
    create role dourstuff_rpc nologin nosuperuser nocreatedb nocreaterole
      noinherit noreplication nobypassrls;
  elsif exists (select 1 from pg_roles where rolname = 'dourstuff_rpc' and
    (rolcanlogin or rolsuper or rolcreatedb or rolcreaterole or rolinherit or rolreplication or rolbypassrls))
    or exists (select 1 from pg_auth_members where member = 'dourstuff_rpc'::regrole) then
    raise exception 'Existing RPC role has unexpected privileges.';
  end if;
end
$$;

create schema sync_private;
revoke all on schema sync_private from public, anon, authenticated, service_role;
grant usage on schema sync_private, auth to dourstuff_rpc;
grant select (id) on auth.users to dourstuff_rpc;

create table sync_private.backend_state (
  singleton boolean primary key default true check (singleton),
  server_epoch uuid not null default gen_random_uuid()
);
insert into sync_private.backend_state default values;

create table sync_private.account_state (
  owner_id uuid primary key,
  revision bigint not null default 0 check (revision between 0 and 9007199254740991),
  retained_after bigint not null default 0 check (retained_after between 0 and revision),
  revoked_at timestamptz
);
-- Account identity survives auth cleanup until the explicit deletion workflow
-- removes owned data. RPCs also require a live auth.users row, so an old JWT
-- cannot recreate an auth-deleted account. No cleanup trigger silently purges it.

create table sync_private.device_state (
  owner_id uuid not null references sync_private.account_state on delete cascade,
  device_epoch uuid not null,
  high_water bigint not null default 0 check (high_water between 0 and 9007199254740991),
  primary key (owner_id, device_epoch)
);

create table sync_private.change_log (
  owner_id uuid not null references sync_private.account_state on delete cascade,
  revision bigint not null check (revision between 1 and 9007199254740991),
  records jsonb not null check (jsonb_typeof(records) = 'array'),
  recovery jsonb not null check (jsonb_typeof(recovery) = 'array'),
  recorded_at timestamptz not null default transaction_timestamp(),
  primary key (owner_id, revision),
  check (jsonb_array_length(records) <= 1000),
  check (jsonb_array_length(recovery) <= 1000),
  -- Leave room for the envelope; never split a transaction across pull pages.
  check (octet_length(records::text) + octet_length(recovery::text) <= 3145728)
);

alter table sync_private.backend_state enable row level security;
alter table sync_private.backend_state force row level security;
create policy read_epoch on sync_private.backend_state for select
  to dourstuff_rpc using (true);
grant select on sync_private.backend_state to dourstuff_rpc;

alter table sync_private.account_state enable row level security;
alter table sync_private.account_state force row level security;
create policy own_account on sync_private.account_state to dourstuff_rpc
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
grant select, insert, update on sync_private.account_state to dourstuff_rpc;

alter table sync_private.device_state enable row level security;
alter table sync_private.device_state force row level security;
create policy own_device on sync_private.device_state to dourstuff_rpc
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
grant select, insert on sync_private.device_state to dourstuff_rpc;

alter table sync_private.change_log enable row level security;
alter table sync_private.change_log force row level security;
create policy own_log on sync_private.change_log to dourstuff_rpc
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
grant select on sync_private.change_log to dourstuff_rpc;

revoke all on all tables in schema sync_private
  from public, anon, authenticated, service_role;

create function sync_private.exact_keys(value jsonb, keys text[])
returns boolean language sql immutable set search_path = '' as $$
  select case when jsonb_typeof(value) = 'object' then
    value ?& keys and (select count(*) from jsonb_object_keys(value)) = cardinality(keys)
    else false end
$$;

create function sync_private.is_uuid(value jsonb)
returns boolean language sql immutable set search_path = '' as $$
  select coalesce(jsonb_typeof(value) = 'string' and (value #>> '{}') ~
    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', false)
$$;

create function sync_private.is_counter(value jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
begin
  if value is null or jsonb_typeof(value) <> 'number' or
     value::text !~ '^(0|[1-9][0-9]{0,15})$' then return false; end if;
  return value::numeric <= 9007199254740991;
end
$$;

create function sync_private.failure(code text)
returns jsonb language sql immutable set search_path = '' as $$
  select jsonb_build_object('protocol_version', 2, 'status', 'failure',
    'code', code, 'expected_sequence', null, 'retry_after_seconds', null)
$$;

create function sync_private.success(result jsonb)
returns jsonb language sql immutable set search_path = '' as $$
  select jsonb_build_object('protocol_version', 2, 'status', 'success', 'result', result)
$$;

create function public.sync_register_device(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
  epoch uuid;
  device uuid;
  account sync_private.account_state%rowtype;
  water bigint;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not exists (select 1 from auth.users where id = caller) then
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

create function public.sync_pull(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
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
  if not exists (select 1 from auth.users where id = caller) then
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

-- Function owners have only the grants above and remain subject to RLS.
-- Supabase's migration user is not a superuser: explicitly permit ownership
-- assignment, then remove the RPC role's temporary schema-creation grant.
grant dourstuff_rpc to postgres;
grant create on schema public to dourstuff_rpc;
alter function public.sync_register_device(jsonb) owner to dourstuff_rpc;
alter function public.sync_pull(jsonb) owner to dourstuff_rpc;
revoke create on schema public from dourstuff_rpc;
revoke all on all functions in schema sync_private from public, anon, authenticated, service_role;
grant execute on all functions in schema sync_private to dourstuff_rpc;
revoke all on function public.sync_register_device(jsonb), public.sync_pull(jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.sync_register_device(jsonb), public.sync_pull(jsonb) to authenticated;

comment on function public.sync_register_device(jsonb) is
  'Protocol v2 device registration; no guest adoption or command application.';
comment on function public.sync_pull(jsonb) is
  'Protocol v2 committed revision pages; writers must hold the account lock.';
