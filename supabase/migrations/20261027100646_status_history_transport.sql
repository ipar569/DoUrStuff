-- Opt-in history transport v1; v2 commands, receipts and old captures stay intact.
alter table sync_private.snapshots add column history_version integer not null default 0
  check (history_version in (0,1));
alter table sync_private.snapshot_pages add column history jsonb not null default '[]'
  check (jsonb_typeof(history)='array' and jsonb_array_length(history)<=200);
alter table sync_private.snapshot_pages add constraint snapshot_complete_payload_bound
  check (octet_length(records::text)+octet_length(recovery::text)+octet_length(history::text)<=3145728);
create index task_status_history_revision on sync_private.task_status_history(owner_id,revision,operation_id);

-- Retained data is serialized as-is: never invent an expired original operation.
-- Trusted recording time is represented to milliseconds; revision orders events.
create function sync_private.status_history_record(h sync_private.task_status_history)
returns jsonb language sql stable set search_path = '' as $$
  select jsonb_build_object('version',1,'operation_id',h.operation_id,'task_id',h.task_id,
    'revision',h.revision,'previous_status',h.previous_status,'status',h.status,
    'fields',h.fields,'provenance',h.provenance,'operation',h.operation,
    'recorded_at_utc',to_char(h.recorded_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'))
$$;
revoke all on function sync_private.status_history_record(sync_private.task_status_history)
  from public,anon,authenticated,service_role;
grant execute on function sync_private.status_history_record(sync_private.task_status_history) to dourstuff_rpc;

create or replace function public.sync_pull(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  include_history boolean := request ? 'history_version';
  history jsonb;
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
  if not sync_private.exact_keys(request, array['protocol_version','after','limit'] || case when include_history then array['history_version'] else '{}'::text[] end)
     or not sync_private.exact_keys(request->'after', array['server_epoch','revision'])
     or not sync_private.is_uuid(request->'after'->'server_epoch')
     or not sync_private.is_counter(request->'after'->'revision')
     or not sync_private.is_counter(request->'limit') then
    raise exception using errcode = '22023', message = 'Invalid account protocol message.';
  end if;
  if include_history and (request->'history_version')::text is distinct from '1' then
    return sync_private.failure('unsupportedProtocol');
  end if;
  if octet_length(request::text)>1048576 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
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
    if include_history then
      select coalesce(jsonb_agg(sync_private.status_history_record(h) order by h.operation_id),'[]') into history
        from sync_private.task_status_history h where h.owner_id=caller and h.revision=row_group.revision;
      if jsonb_array_length(history)>1000 then return sync_private.failure('unavailable'); end if;
      next_group := next_group||jsonb_build_object('history',history);
    end if;
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
    'groups', groups)||case when include_history then jsonb_build_object('history_version',1) else '{}'::jsonb end);
end
$$;

create or replace function public.sync_snapshot_begin(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  include_history boolean := request ? 'history_version';
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
  page_history jsonb := '[]';
  page_bytes bigint := 6;
  item_bytes bigint;
  total_bytes bigint := 0;
  total_records bigint := 0;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then return sync_private.failure('accountDeleted'); end if;
  if not sync_private.exact_keys(request,array['protocol_version','server_epoch'] || case when include_history then array['history_version'] else '{}'::text[] end)
    or not sync_private.is_uuid(request->'server_epoch') or octet_length(request::text)>1048576 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  if include_history and (request->'history_version')::text is distinct from '1' then
    return sync_private.failure('unsupportedProtocol');
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
      and s.history_version=case when include_history then 1 else 0 end
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
    select false as is_history, false as is_recovery, kind, key, jsonb_build_object('entity',jsonb_build_object('kind',kind,'key',key),
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
    union all select false,true,'recovery',jsonb_build_array(id),record
      from sync_private.recovery_candidates where owner_id=caller
    union all select true,false,'history',jsonb_build_array(revision,operation_id),sync_private.status_history_record(h)
      from sync_private.task_status_history h where h.owner_id=caller and include_history and h.revision<=account.revision
    order by is_history,is_recovery,kind,key
  loop
    item_bytes := octet_length(item.value::text)+2;
    if item_bytes+6>3145728 or total_bytes+item_bytes>67108864 then
      raise exception using errcode='54000',message='Snapshot capacity exceeded.';
    end if;
    if page_bytes+item_bytes>3145728
      or (not item.is_recovery and not item.is_history and jsonb_array_length(page_records)=200)
      or (item.is_recovery and jsonb_array_length(page_recovery)=200)
      or (item.is_history and jsonb_array_length(page_history)=200) then
      insert into sync_private.snapshot_pages(owner_id,token,page,records,recovery,history)
        values(caller,snapshot_token,page_no,page_records,page_recovery,page_history);
      page_no := page_no+1; page_records := '[]'; page_recovery := '[]'; page_history := '[]'; page_bytes := 6;
    end if;
    if item.is_history then page_history := page_history||jsonb_build_array(item.value);
    elsif item.is_recovery then page_recovery := page_recovery||jsonb_build_array(item.value);
    else page_records := page_records||jsonb_build_array(item.value); end if;
    page_bytes := page_bytes+item_bytes;
    total_bytes := total_bytes+item_bytes; total_records := total_records+1;
  end loop;
  -- An empty account still has exactly one page.
  insert into sync_private.snapshot_pages(owner_id,token,page,records,recovery,history)
        values(caller,snapshot_token,page_no,page_records,page_recovery,page_history);
  manifest := jsonb_build_object('token',snapshot_token,
    'at',jsonb_build_object('server_epoch',epoch,'revision',account.revision),
    'expires_at_utc',to_char(expiry at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'page_count',page_no+1,'record_count',total_records,'device_high_waters',waters)||case when include_history then jsonb_build_object('history_version',1) else '{}'::jsonb end;
  insert into sync_private.snapshots(owner_id,token,server_epoch,revision,expires_at,manifest,history_version)
    values(caller,snapshot_token,epoch,account.revision,expiry,manifest,case when include_history then 1 else 0 end);
  return sync_private.success(manifest);
exception when program_limit_exceeded then
  -- The implicit PL/pgSQL subtransaction rolls back every partial page/manifest.
  return sync_private.failure('rateLimited');
end
$$;
create or replace function public.sync_snapshot_page(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  include_history boolean := request ? 'history_version';
  caller uuid := sync_private.request_owner();
  epoch uuid;
  account sync_private.account_state%rowtype;
  capture sync_private.snapshots%rowtype;
  content sync_private.snapshot_pages%rowtype;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then return sync_private.failure('accountDeleted'); end if;
  if not sync_private.exact_keys(request,array['protocol_version','server_epoch','token','page'] || case when include_history then array['history_version'] else '{}'::text[] end)
    or not sync_private.is_uuid(request->'server_epoch') or not sync_private.is_uuid(request->'token')
    or not sync_private.is_counter(request->'page') or octet_length(request::text)>1048576 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  if include_history and (request->'history_version')::text is distinct from '1' then
    return sync_private.failure('unsupportedProtocol');
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
    where owner_id=caller and token=(request->>'token')::uuid and server_epoch=epoch
      and history_version=case when include_history then 1 else 0 end;
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
    'records',content.records,'recovery',content.recovery)||case when include_history then
      jsonb_build_object('history_version',1,'history',content.history) else '{}'::jsonb end);
end
$$;
