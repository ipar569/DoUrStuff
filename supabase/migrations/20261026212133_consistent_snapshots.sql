-- Immutable protocol-v2 shadow/recovery snapshots. No client activation,
-- history transport, receipt pruning or content purging is enabled here.
create table sync_private.snapshots (
  owner_id uuid not null references sync_private.account_state on delete cascade,
  token uuid not null,
  server_epoch uuid not null,
  revision bigint not null check (revision between 0 and 9007199254740991),
  expires_at timestamptz not null,
  manifest jsonb not null,
  primary key (owner_id,token)
);
create index snapshots_expiry on sync_private.snapshots(owner_id,expires_at);
create table sync_private.snapshot_pages (
  owner_id uuid not null,
  token uuid not null,
  page integer not null check (page between 0 and 999999),
  records jsonb not null check (jsonb_typeof(records)='array' and jsonb_array_length(records)<=200),
  recovery jsonb not null check (jsonb_typeof(recovery)='array' and jsonb_array_length(recovery)<=200),
  primary key (owner_id,token,page),
  foreign key (owner_id,token) references sync_private.snapshots on delete cascade deferrable initially deferred,
  check (octet_length(records::text)+octet_length(recovery::text)<=3145728)
);
do $$
declare name text;
begin
  foreach name in array array['snapshots','snapshot_pages'] loop
    execute format('alter table sync_private.%I enable row level security',name);
    execute format('alter table sync_private.%I force row level security',name);
    execute format('create policy own_rows on sync_private.%I to dourstuff_rpc
      using (owner_id=(select sync_private.request_owner()))
      with check (owner_id=(select sync_private.request_owner()))',name);
    execute format('revoke all on sync_private.%I from public,anon,authenticated,service_role',name);
    execute format('grant select,insert on sync_private.%I to dourstuff_rpc',name);
  end loop;
end
$$;
-- Only expired manifests can be removed by the RPC role. FK cleanup removes
-- their pages atomically. Unexpired captures cannot be overwritten or evicted.
drop policy own_rows on sync_private.snapshots;
create policy own_read on sync_private.snapshots for select to dourstuff_rpc
  using (owner_id=(select sync_private.request_owner()));
create policy own_insert on sync_private.snapshots for insert to dourstuff_rpc
  with check (owner_id=(select sync_private.request_owner()));
create policy own_expired on sync_private.snapshots for delete to dourstuff_rpc
  using (owner_id=(select sync_private.request_owner()) and expires_at<=clock_timestamp());
grant delete on sync_private.snapshots to dourstuff_rpc;

create function public.sync_snapshot_begin(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := sync_private.request_owner();
  epoch uuid;
  account sync_private.account_state%rowtype;
  snapshot_token uuid := gen_random_uuid();
  expiry timestamptz;
  waters jsonb;
  manifest jsonb;
  item record;
  page_no integer := 0;
  page_records jsonb := '[]';
  page_recovery jsonb := '[]';
  page_bytes bigint := 4;
  item_bytes bigint;
  total_bytes bigint := 0;
  total_records bigint := 0;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then return sync_private.failure('accountDeleted'); end if;
  if not sync_private.exact_keys(request,array['protocol_version','server_epoch'])
    or not sync_private.is_uuid(request->'server_epoch') or octet_length(request::text)>1048576 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  if (request->'protocol_version')::text is distinct from '2' then
    return sync_private.failure('unsupportedProtocol');
  end if;
  select server_epoch into strict epoch from sync_private.backend_state;
  if epoch<>(request->>'server_epoch')::uuid then return sync_private.failure('serverEpochChanged'); end if;
  -- Serialize with every canonical write, registration and retention writer.
  -- A later READ COMMITTED statement therefore sees the same committed R.
  select * into account from sync_private.account_state where owner_id=caller for update;
  if not found then return sync_private.failure('unavailable'); end if;
  if account.revoked_at is not null then return sync_private.failure('accountDeleted'); end if;
  delete from sync_private.snapshots where owner_id=caller and expires_at<=clock_timestamp();
  -- Limit retained copies, without invalidating an in-flight download. A lost
  -- begin reply may be retried at the same revision and watermark state.
  select coalesce(jsonb_object_agg(device_epoch::text,high_water),'{}') into waters
    from sync_private.device_state where owner_id=caller;
  select s.manifest into manifest from sync_private.snapshots s
    where s.owner_id=caller and s.server_epoch=epoch and s.revision=account.revision
      and s.manifest->'device_high_waters'=waters and s.expires_at>clock_timestamp()
    order by s.expires_at desc limit 1;
  if found then return sync_private.success(manifest); end if;
  if (select count(*) from sync_private.snapshots where owner_id=caller)>=3 then
    return sync_private.failure('rateLimited');
  end if;
  expiry := date_trunc('milliseconds',clock_timestamp()) + interval '24 hours';
  -- The deferred FK permits pages first and the immutable manifest last;
  -- neither table grants UPDATE, and no incomplete capture can commit.
  for item in
    select false as is_recovery, kind, key, jsonb_build_object('entity',jsonb_build_object('kind',kind,'key',key),
        'fields',fields,'delete_operation_id',delete_operation_id) as value
    from (
      select 'task'::text kind,jsonb_build_array(task_id) key,fields,delete_operation_id
        from sync_private.task_shadow where owner_id=caller
      union all select 'tag',jsonb_build_array(tag_id),fields,delete_operation_id
        from sync_private.tag_shadow where owner_id=caller
      union all select 'milestone',jsonb_build_array(milestone_id),fields,delete_operation_id
        from sync_private.milestone_shadow where owner_id=caller
      union all select 'view',jsonb_build_array(view_id),fields,delete_operation_id
        from sync_private.view_shadow where owner_id=caller
      union all select 'membership',jsonb_build_array(task_id,tag_id),fields,null::uuid
        from sync_private.membership_shadow where owner_id=caller
      union all select 'preference',jsonb_build_array(key),fields,null::uuid
        from sync_private.preference_shadow where owner_id=caller
    ) shadows
    union all select true,'recovery',jsonb_build_array(id),record
      from sync_private.recovery_candidates where owner_id=caller
    order by is_recovery,kind,key
  loop
    item_bytes := octet_length(item.value::text)+2;
    if item_bytes+4>3145728 or total_bytes+item_bytes>67108864 then
      raise exception using errcode='54000',message='Snapshot capacity exceeded.';
    end if;
    if page_bytes+item_bytes>3145728
      or (not item.is_recovery and jsonb_array_length(page_records)=200)
      or (item.is_recovery and jsonb_array_length(page_recovery)=200) then
      insert into sync_private.snapshot_pages values(caller,snapshot_token,page_no,page_records,page_recovery);
      page_no := page_no+1; page_records := '[]'; page_recovery := '[]'; page_bytes := 4;
    end if;
    if item.is_recovery then page_recovery := page_recovery||jsonb_build_array(item.value);
    else page_records := page_records||jsonb_build_array(item.value); end if;
    page_bytes := page_bytes+item_bytes;
    total_bytes := total_bytes+item_bytes; total_records := total_records+1;
  end loop;
  -- An empty account still has exactly one page.
  insert into sync_private.snapshot_pages values(caller,snapshot_token,page_no,page_records,page_recovery);
  manifest := jsonb_build_object('token',snapshot_token,
    'at',jsonb_build_object('server_epoch',epoch,'revision',account.revision),
    'expires_at_utc',to_char(expiry at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'page_count',page_no+1,'record_count',total_records,'device_high_waters',waters);
  insert into sync_private.snapshots(owner_id,token,server_epoch,revision,expires_at,manifest)
    values(caller,snapshot_token,epoch,account.revision,expiry,manifest);
  return sync_private.success(manifest);
exception when program_limit_exceeded then
  -- The implicit PL/pgSQL subtransaction rolls back every partial page/manifest.
  return sync_private.failure('rateLimited');
end
$$;
create function public.sync_snapshot_page(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := sync_private.request_owner();
  epoch uuid;
  account sync_private.account_state%rowtype;
  capture sync_private.snapshots%rowtype;
  content sync_private.snapshot_pages%rowtype;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then return sync_private.failure('accountDeleted'); end if;
  if not sync_private.exact_keys(request,array['protocol_version','server_epoch','token','page'])
    or not sync_private.is_uuid(request->'server_epoch') or not sync_private.is_uuid(request->'token')
    or not sync_private.is_counter(request->'page') or octet_length(request::text)>1048576 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  if (request->'protocol_version')::text is distinct from '2' then
    return sync_private.failure('unsupportedProtocol');
  end if;
  if (request->>'page')::bigint>999999 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  select server_epoch into strict epoch from sync_private.backend_state;
  if epoch<>(request->>'server_epoch')::uuid then return sync_private.failure('serverEpochChanged'); end if;
  -- Hold against revocation, account deletion and expired-capture cleanup.
  select * into account from sync_private.account_state where owner_id=caller for share;
  if not found then return sync_private.failure('unavailable'); end if;
  if account.revoked_at is not null then return sync_private.failure('accountDeleted'); end if;
  select * into capture from sync_private.snapshots
    where owner_id=caller and token=(request->>'token')::uuid and server_epoch=epoch;
  if not found or capture.expires_at<=clock_timestamp() then
    return sync_private.failure('snapshotExpired');
  end if;
  if (request->>'page')::integer >= (capture.manifest->>'page_count')::integer then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  select * into strict content from sync_private.snapshot_pages
    where owner_id=caller and token=capture.token and page=(request->>'page')::integer;
  return sync_private.success(jsonb_build_object('token',capture.token,'at',capture.manifest->'at',
    'page',content.page,'is_last',content.page=(capture.manifest->>'page_count')::integer-1,
    'records',content.records,'recovery',content.recovery));
end
$$;

grant create on schema public to dourstuff_rpc;
alter function public.sync_snapshot_begin(jsonb) owner to dourstuff_rpc;
alter function public.sync_snapshot_page(jsonb) owner to dourstuff_rpc;
revoke create on schema public from dourstuff_rpc;
revoke all on function public.sync_snapshot_begin(jsonb),public.sync_snapshot_page(jsonb)
  from public,anon,authenticated,service_role;
grant execute on function public.sync_snapshot_begin(jsonb),public.sync_snapshot_page(jsonb) to authenticated;
