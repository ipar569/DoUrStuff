-- Resolved payloads expire after 90 elapsed days. Compact identities, graph
-- links, content-free closure replies and all unresolved originals are permanent.
-- Earlier migrations are immutable. This adds no public maintenance endpoint.
alter table sync_private.recovery_candidates alter column record drop not null;
alter table sync_private.recovery_candidates add column device_epoch uuid;
alter table sync_private.recovery_candidates add column predecessor_ids uuid[];
alter table sync_private.recovery_candidates add column is_held boolean;
alter table sync_private.resolution_requests alter column request drop not null;
alter table sync_private.resolution_requests add column request_hash bytea;

create function sync_private.recovery_predecessors(original jsonb)
returns uuid[] language sql immutable set search_path='' as $$
  select coalesce(array_agg(distinct id order by id),'{}'::uuid[]) from (
    select (p.value->'base'->>'operation_id')::uuid id
      from jsonb_each(original->'operation'->'patches') p
      where p.value->'base'->>'operation_id' is not null
    union select (d->>'operation_id')::uuid
      from jsonb_array_elements(original->'operation'->'dependencies') d
  ) links
$$;
revoke all on function sync_private.recovery_predecessors(jsonb) from public,anon,authenticated,service_role;
grant execute on function sync_private.recovery_predecessors(jsonb) to dourstuff_rpc;

update sync_private.recovery_candidates set
  device_epoch=(record->'operation'->>'device_epoch')::uuid,
  predecessor_ids=sync_private.recovery_predecessors(record),
  is_held=record->>'disposition'='held';
alter table sync_private.recovery_candidates alter column device_epoch set not null;
alter table sync_private.recovery_candidates alter column predecessor_ids set not null;
alter table sync_private.recovery_candidates alter column is_held set not null;
update sync_private.resolution_requests set request_hash=sha256(convert_to((request-'cursor')::text,'UTF8'));
alter table sync_private.resolution_requests alter column request_hash set not null;
alter table sync_private.resolution_requests add constraint resolution_request_hash_size check(octet_length(request_hash)=32);

-- Insert-only RPC grants remain unchanged. Callers cannot rewrite these proofs.
create function sync_private.retain_recovery_metadata()
returns trigger language plpgsql set search_path='' as $$
begin
  new.device_epoch := (new.record->'operation'->>'device_epoch')::uuid;
  new.predecessor_ids := sync_private.recovery_predecessors(new.record);
  new.is_held := new.record->>'disposition'='held';
  return new;
end $$;
revoke all on function sync_private.retain_recovery_metadata() from public,anon,authenticated,service_role;
grant execute on function sync_private.retain_recovery_metadata() to dourstuff_rpc;
create trigger retain_recovery_metadata before insert on sync_private.recovery_candidates
  for each row execute function sync_private.retain_recovery_metadata();
create function sync_private.retain_resolution_hash()
returns trigger language plpgsql set search_path='' as $$
begin
  new.request_hash := sha256(convert_to((new.request-'cursor')::text,'UTF8'));
  return new;
end $$;
revoke all on function sync_private.retain_resolution_hash() from public,anon,authenticated,service_role;
grant execute on function sync_private.retain_resolution_hash() to dourstuff_rpc;
create trigger retain_resolution_hash before insert on sync_private.resolution_requests
  for each row execute function sync_private.retain_resolution_hash();
create index recovery_resolution_retention on sync_private.recovery_resolutions(owner_id,recorded_at,candidate_id);
create index resolution_request_retention on sync_private.resolution_requests(owner_id,recorded_at,operation_id)
  where request is not null;

create function sync_private.prune_resolved_content(owner uuid, batch_size integer default 200)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare account sync_private.account_state%rowtype; cutoff timestamptz; item record;
  candidate_count integer := 0; request_count integer := 0;
begin
  if owner is null or batch_size is null or batch_size not between 1 and 1000 then
    raise exception using errcode='22023',message='Invalid retention batch.';
  end if;
  select * into account from sync_private.account_state where owner_id=owner for update;
  if not found then raise exception using errcode='22023',message='Unknown retention account.'; end if;
  cutoff := clock_timestamp()-interval '2160 hours';
  for item in select c.* from sync_private.recovery_candidates c
    join sync_private.recovery_resolutions r on r.owner_id=c.owner_id and r.candidate_id=c.id
    where c.owner_id=owner and c.record is not null and r.recorded_at<=cutoff
    order by r.recorded_at,c.id limit batch_size
  loop
    -- Preserve the exact operation hash and verify graph metadata before removing
    -- content. Failure rolls back the entire batch, including identity backfills.
    perform sync_private.retain_content_identity(owner,item.record->'operation');
    if item.device_epoch is distinct from (item.record->'operation'->>'device_epoch')::uuid
      or item.operation_id is distinct from (item.record->'operation'->>'operation_id')::uuid
      or item.predecessor_ids is distinct from sync_private.recovery_predecessors(item.record)
      or item.is_held is distinct from (item.record->>'disposition'='held') then
      raise exception using errcode='23514',message='Mismatched recovery metadata.';
    end if;
    update sync_private.recovery_candidates set record=null where owner_id=owner and id=item.id;
    candidate_count := candidate_count+1;
  end loop;
  for item in select * from sync_private.resolution_requests
    where owner_id=owner and request is not null and recorded_at<=cutoff
    order by recorded_at,operation_id limit batch_size
  loop
    if item.request_hash is distinct from sha256(convert_to((item.request-'cursor')::text,'UTF8'))
      or not exists(select 1 from sync_private.device_state d where d.owner_id=owner
        and d.device_epoch=item.device_epoch and d.high_water>=item.sequence) then
      raise exception using errcode='23514',message='Mismatched resolution identity.';
    end if;
    if item.request->>'choice'='replace' then
      perform sync_private.retain_content_identity(owner,item.request->'replacement');
    elsif not exists(select 1 from sync_private.operation_identities i where i.owner_id=owner
      and i.device_epoch=item.device_epoch and i.sequence=item.sequence and i.operation_id=item.operation_id
      and i.payload_hash=item.request_hash) then
      raise exception using errcode='23514',message='Missing resolution identity.';
    end if;
    update sync_private.resolution_requests set request=null where owner_id=owner and operation_id=item.operation_id;
    request_count := request_count+1;
  end loop;
  -- New captures must not reuse pre-compaction content at the same revision.
  -- The empty whole revision advances pull without rewriting retained log rows;
  -- permanent closures already convey the resolved state. Frozen pages survive.
  if candidate_count>0 then
    if account.revision>=9007199254740991 then
      raise exception using errcode='22003',message='Revision capacity exceeded.';
    end if;
    account.revision := account.revision+1;
    update sync_private.account_state set revision=account.revision where owner_id=owner;
    insert into sync_private.change_log(owner_id,revision,records,recovery) values(owner,account.revision,'[]','[]');
  end if;
  return jsonb_build_object('candidates_compacted',candidate_count,'requests_compacted',request_count,'revision',account.revision);
end $$;
revoke all on function sync_private.prune_resolved_content(uuid,integer)
  from public,anon,authenticated,service_role,dourstuff_rpc;

create or replace function public.sync_resolve_recovery(request jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  caller uuid := sync_private.request_owner(); epoch uuid;
  account sync_private.account_state%rowtype;
  original jsonb; fields jsonb; op jsonb; prior sync_private.resolution_requests%rowtype;
  device uuid; op_id uuid; target_id uuid; seq bigint; water bigint;
  expected jsonb; provided jsonb; descendants jsonb; choice jsonb; item jsonb;
  outcome jsonb; result jsonb; closure jsonb; closures jsonb := '[]'; revision bigint;
  patch jsonb; base jsonb; current_field jsonb;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then return sync_private.failure('accountDeleted'); end if;
  if not sync_private.exact_json(request, -4) or octet_length(sync_private.compact_json(request))>1048576
    or not sync_private.exact_keys(request,array['protocol_version','resolution_version','cursor','operation_id','device_epoch','sequence','conflict_id','expected_conflict_revision','observed_fields','choice','replacement','held_choices'])
    or not sync_private.exact_keys(request->'cursor',array['server_epoch','revision'])
    or not sync_private.is_uuid(request->'cursor'->'server_epoch')
    or not sync_private.is_counter(request->'cursor'->'revision')
    or not sync_private.is_uuid(request->'operation_id') or not sync_private.is_uuid(request->'device_epoch')
    or not sync_private.is_uuid(request->'conflict_id') or not sync_private.is_counter(request->'sequence')
    or not sync_private.is_counter(request->'expected_conflict_revision')
    or (request->>'sequence')::bigint<1 or (request->>'expected_conflict_revision')::bigint<1
    or (request->>'expected_conflict_revision')::bigint>(request->'cursor'->>'revision')::bigint
    or jsonb_typeof(request->'observed_fields') not in ('object','null')
    or coalesce(request->>'choice','') not in ('replace','discard') or jsonb_typeof(request->'held_choices')<>'array'
    or jsonb_array_length(request->'held_choices')>199 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  if request->'protocol_version' is distinct from '2'::jsonb or request->'resolution_version' is distinct from '1'::jsonb then
    return sync_private.failure('unsupportedProtocol');
  end if;
  for choice in select v from jsonb_array_elements(request->'held_choices') e(v) loop
    if not sync_private.exact_keys(choice,array['id','revision','choice']) or not sync_private.is_uuid(choice->'id')
      or not sync_private.is_counter(choice->'revision') or (choice->>'revision')::bigint<1
      or coalesce(choice->>'choice','') not in ('keepHeld','discard') then
      raise exception using errcode='22023',message='Invalid account protocol message.';
    end if;
  end loop;
  if (select count(distinct v->>'id') from jsonb_array_elements(request->'held_choices') e(v))<>jsonb_array_length(request->'held_choices') then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  op := request->'replacement';
  if (request->>'choice'='discard' and op<>'null') or (request->>'choice'='replace' and jsonb_typeof(op)<>'object') then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  select server_epoch into strict epoch from sync_private.backend_state;
  if epoch<>(request->'cursor'->>'server_epoch')::uuid then return sync_private.failure('serverEpochChanged'); end if;
  select * into account from sync_private.account_state where owner_id=caller for update;
  if not found then return sync_private.failure('unavailable'); end if;
  if account.revoked_at is not null then return sync_private.failure('accountDeleted'); end if;
  device := (request->>'device_epoch')::uuid; op_id := (request->>'operation_id')::uuid;
  target_id := (request->>'conflict_id')::uuid; seq := (request->>'sequence')::bigint;
  -- Retries bind the entire preview and decision, not just the replacement op.
  -- Exclude only the transport cursor so a refreshed snapshot can reconcile it.
  select * into prior from sync_private.resolution_requests r where r.owner_id=caller
    and (r.operation_id=op_id or (r.device_epoch=device and r.sequence=seq));
  if found then
    if prior.request_hash<>sha256(convert_to((request-'cursor')::text,'UTF8')) then return sync_private.failure('payloadMismatch'); end if;
    -- Replay the immutable decision at its original revision in the CURRENT
    -- server incarnation, as sync_apply does for retained operation receipts.
    return jsonb_set(prior.reply,'{result,cursor,server_epoch}',to_jsonb(epoch));
  end if;
  if (request->'cursor'->>'revision')::bigint<account.retained_after then return sync_private.failure('cursorExpired'); end if;
  if (request->'cursor'->>'revision')::bigint>account.revision then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  select high_water into water from sync_private.device_state where owner_id=caller and device_epoch=device;
  if not found then return sync_private.failure('unavailable'); end if;
  if seq>water+1 then return sync_private.failure('sequenceGap')||jsonb_build_object('expected_sequence',water+1); end if;
  if seq<=water or exists(select 1 from sync_private.operation_identities i where i.owner_id=caller and i.operation_id=op_id)
    or exists(select 1 from sync_private.operation_receipts r where r.owner_id=caller and r.operation_id=op_id)
    or exists(select 1 from sync_private.recovery_candidates r where r.owner_id=caller and r.operation_id=op_id)
    or exists(select 1 from sync_private.task_status_history h where h.owner_id=caller and h.operation_id=op_id)
    or exists(select 1 from sync_private.task_deletions d where d.owner_id=caller and d.operation_id=op_id)
    or exists(select 1 from sync_private.task_restorations d where d.owner_id=caller and d.operation_id=op_id)
    or exists(select 1 from sync_private.milestone_deletions d where d.owner_id=caller and d.operation_id=op_id)
    or exists(select 1 from sync_private.tag_deletions d where d.owner_id=caller and d.operation_id=op_id)
    or exists(select 1 from sync_private.view_deletions d where d.owner_id=caller and d.operation_id=op_id)
    or exists(select 1 from sync_private.membership_changes d where d.owner_id=caller and d.operation_id=op_id)
    or exists(select 1 from sync_private.preference_changes d where d.owner_id=caller and d.operation_id=op_id)
    or exists(select 1 from sync_private.milestone_shadow d where d.owner_id=caller and d.creation_operation->>'operation_id'=op_id::text)
    or exists(select 1 from sync_private.tag_shadow d where d.owner_id=caller and d.creation_operation->>'operation_id'=op_id::text)
    or exists(select 1 from sync_private.view_shadow d where d.owner_id=caller and d.creation_operation->>'operation_id'=op_id::text) then
    return sync_private.failure('payloadMismatch');
  end if;
  select record into original from sync_private.recovery_candidates r where r.owner_id=caller and r.id=target_id;
  if not found or original->'revision'<>request->'expected_conflict_revision'
    or exists(select 1 from sync_private.recovery_resolutions r where r.owner_id=caller and r.candidate_id=target_id) then
    return sync_private.failure('recoveryChanged');
  end if;
  fields := sync_private.recovery_fields(original->'operation'->'entity');
  if coalesce(fields,'null')<>request->'observed_fields' then return sync_private.failure('recoveryChanged'); end if;
  -- Transitive held descendants, including parent dependencies, are never
  -- released implicitly. A new held arrival invalidates the exact preview.
  with recursive affected(id,operation_id,device_epoch) as (
    select id,operation_id,device_epoch from sync_private.recovery_candidates
      where owner_id=caller and id=target_id
    union
    select r.id,r.operation_id,r.device_epoch from sync_private.recovery_candidates r
      join affected a on r.device_epoch=a.device_epoch and a.operation_id=any(r.predecessor_ids)
      where r.owner_id=caller and r.is_held
  ) select coalesce(jsonb_agg(r.record order by r.id),'[]') into descendants
    from affected a join sync_private.recovery_candidates r on r.owner_id=caller and r.id=a.id
    where a.id<>target_id
      and not exists(select 1 from sync_private.recovery_resolutions z where z.owner_id=caller and z.candidate_id=a.id);
  select coalesce(jsonb_agg(jsonb_build_object('id',v->'id','revision',v->'revision') order by v->>'id'),'[]') into expected
    from jsonb_array_elements(descendants) e(v);
  select coalesce(jsonb_agg(v-'choice' order by v->>'id'),'[]') into provided from jsonb_array_elements(request->'held_choices') e(v);
  if expected<>provided then return sync_private.failure('recoveryChanged'); end if;
  if account.revision>=9007199254740991 then return sync_private.failure('unavailable'); end if;
  revision := account.revision+1;
  if request->>'choice'='replace' then
    if op->'operation_id' is distinct from request->'operation_id' or op->'device_epoch' is distinct from request->'device_epoch'
      or op->'sequence' is distinct from request->'sequence' or op->'entity' is distinct from original->'operation'->'entity'
      or op->'dependencies' is distinct from '[]'::jsonb or jsonb_typeof(op->'patches')<>'object'
      or (select count(*) from jsonb_object_keys(op->'patches'))<>1
      or not (op->'patches' ? (original->>'group')) then
      raise exception using errcode='22023',message='Invalid account protocol message.';
    end if;
    patch := op->'patches'->(original->>'group'); base := patch->'base'; current_field := fields->(original->>'group');
    if (current_field is null and base is distinct from jsonb_build_object('kind','absent'))
      or (current_field is not null and base is distinct from jsonb_build_object('kind','observed','revision',current_field->'revision','value',current_field->'value')) then
      return sync_private.failure('recoveryChanged');
    end if;
    -- Any rejected/conflicting replacement rolls back its receipt, recovery,
    -- history, watermark and shadow together. The original stays unresolved.
    begin
      outcome := public.sync_apply(jsonb_build_object('protocol_version',2,'server_epoch',epoch,
        'after_revision',account.revision,'operations',jsonb_build_array(op)));
      if outcome->>'status'<>'success' then return outcome; end if;
      if outcome->'result'->'results'->0->>'disposition'<>'applied' then
        raise exception using errcode='P0004',message='Replacement not accepted.';
      end if;
    exception when sqlstate 'P0004' then return sync_private.failure('replacementRejected'); end;
  else
    insert into sync_private.operation_identities(owner_id,device_epoch,sequence,operation_id,payload_hash)
      values(caller,device,seq,op_id,sha256(convert_to((request-'cursor')::text,'UTF8')));
    update sync_private.device_state set high_water=seq where owner_id=caller and device_epoch=device;
    update sync_private.account_state set revision=account.revision+1 where owner_id=caller;
    insert into sync_private.change_log(owner_id,revision,records,recovery) values(caller,revision,'[]','[]');
  end if;
  for item in select original union all select v from jsonb_array_elements(descendants) e(v)
    where exists(select 1 from jsonb_array_elements(request->'held_choices') c where c->'id'=v->'id' and c->>'choice'='discard')
  loop
    closure := jsonb_build_object('version',1,'conflict_id',item->'id','expected_conflict_revision',item->'revision',
      'revision',revision,'operation_id',op_id,'device_epoch',device,'sequence',seq,
      'choice',case when item->>'id'=target_id::text then request->>'choice' else 'discard' end);
    insert into sync_private.recovery_resolutions(owner_id,candidate_id,revision,record)
      values(caller,(item->>'id')::uuid,revision,closure);
    closures := closures||jsonb_build_array(closure);
  end loop;
  result := sync_private.success(jsonb_build_object('resolution_version',1,'cursor',jsonb_build_object('server_epoch',epoch,'revision',revision),
    'device_high_water',seq,'resolutions',closures));
  insert into sync_private.resolution_requests(owner_id,operation_id,device_epoch,sequence,request,reply)
    values(caller,op_id,device,seq,request,result);
  return result;
end $$;

create or replace function public.sync_snapshot_begin(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  include_history boolean := request ? 'history_version';
  include_resolution boolean := request ? 'resolution_version';
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
  page_resolutions jsonb := '[]';
  page_bytes bigint := 8;
  item_bytes bigint;
  total_bytes bigint := 0;
  total_records bigint := 0;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then return sync_private.failure('accountDeleted'); end if;
  if not sync_private.exact_keys(request,array['protocol_version','server_epoch'] || case when include_history then array['history_version'] else '{}'::text[] end || case when include_resolution then array['resolution_version'] else '{}'::text[] end)
    or not sync_private.is_uuid(request->'server_epoch') or octet_length(request::text)>1048576 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  if include_resolution and ((request->'resolution_version')::text is distinct from '1' or not include_history) then
    return sync_private.failure('unsupportedProtocol');
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
      and s.resolution_version=case when include_resolution then 1 else 0 end
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
    select false as is_resolution, false as is_history, false as is_recovery, kind, key, jsonb_build_object('entity',jsonb_build_object('kind',kind,'key',key),
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
    union all select false,false,true,'recovery',jsonb_build_array(id),record
      from sync_private.recovery_candidates where owner_id=caller and record is not null
    union all select false,true,false,'history',jsonb_build_array(revision,operation_id),sync_private.status_history_record(h)
      from sync_private.task_status_history h where h.owner_id=caller and include_history and h.revision<=account.revision
    union all select true,false,false,'resolution',jsonb_build_array(candidate_id),record
      from sync_private.recovery_resolutions where owner_id=caller and include_resolution
    order by is_resolution,is_history,is_recovery,kind,key
  loop
    item_bytes := octet_length(item.value::text)+2;
    if item_bytes+8>3145728 or total_bytes+item_bytes>67108864 then
      raise exception using errcode='54000',message='Snapshot capacity exceeded.';
    end if;
    if page_bytes+item_bytes>3145728
      or (not item.is_resolution and not item.is_recovery and not item.is_history and jsonb_array_length(page_records)=200)
      or (item.is_recovery and jsonb_array_length(page_recovery)=200)
      or (item.is_history and jsonb_array_length(page_history)=200)
      or (item.is_resolution and jsonb_array_length(page_resolutions)=200) then
      insert into sync_private.snapshot_pages(owner_id,token,page,records,recovery,history,resolutions)
        values(caller,snapshot_token,page_no,page_records,page_recovery,page_history,page_resolutions);
      page_no := page_no+1; page_records := '[]'; page_recovery := '[]'; page_history := '[]'; page_resolutions := '[]'; page_bytes := 8;
    end if;
    if item.is_resolution then page_resolutions := page_resolutions||jsonb_build_array(item.value);
    elsif item.is_history then page_history := page_history||jsonb_build_array(item.value);
    elsif item.is_recovery then page_recovery := page_recovery||jsonb_build_array(item.value);
    else page_records := page_records||jsonb_build_array(item.value); end if;
    page_bytes := page_bytes+item_bytes;
    total_bytes := total_bytes+item_bytes; total_records := total_records+1;
  end loop;
  -- An empty account still has exactly one page.
  insert into sync_private.snapshot_pages(owner_id,token,page,records,recovery,history,resolutions)
        values(caller,snapshot_token,page_no,page_records,page_recovery,page_history,page_resolutions);
  manifest := jsonb_build_object('token',snapshot_token,
    'at',jsonb_build_object('server_epoch',epoch,'revision',account.revision),
    'expires_at_utc',to_char(expiry at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'page_count',page_no+1,'record_count',total_records,'device_high_waters',waters)||case when include_history then jsonb_build_object('history_version',1) else '{}'::jsonb end||case when include_resolution then jsonb_build_object('resolution_version',1) else '{}'::jsonb end;
  insert into sync_private.snapshots(owner_id,token,server_epoch,revision,expires_at,manifest,history_version,resolution_version)
    values(caller,snapshot_token,epoch,account.revision,expiry,manifest,case when include_history then 1 else 0 end,case when include_resolution then 1 else 0 end);
  return sync_private.success(manifest);
exception when program_limit_exceeded then
  -- The implicit PL/pgSQL subtransaction rolls back every partial page/manifest.
  return sync_private.failure('rateLimited');
end
$$;
