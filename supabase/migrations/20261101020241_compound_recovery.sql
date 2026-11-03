-- Compound entity creation/copy recovery, negotiated separately from v1.
-- All earlier migrations and original candidates/receipts remain immutable.
create function public.sync_resolve_create(request jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare caller uuid := sync_private.request_owner(); epoch uuid;
  account sync_private.account_state%rowtype; prior sync_private.resolution_requests%rowtype;
  device uuid; op_id uuid; source_id uuid; seq bigint; water bigint; revision bigint;
  op jsonb; original jsonb; roots jsonb; descendants jsonb; expected jsonb; provided jsonb;
  item jsonb; choice jsonb; fields jsonb; outcome jsonb; closure jsonb; closures jsonb := '[]'; result jsonb;
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then return sync_private.failure('accountDeleted'); end if;
  if not sync_private.exact_json(request,-4) or octet_length(sync_private.compact_json(request))>1048576
    or not sync_private.exact_keys(request,array['protocol_version','resolution_version','cursor','operation_id','device_epoch','sequence',
      'source_operation_id','source_entity','conflicts','observed_fields','choice','replacement','held_choices'])
    or not sync_private.exact_keys(request->'cursor',array['server_epoch','revision'])
    or not sync_private.is_uuid(request->'cursor'->'server_epoch') or not sync_private.is_counter(request->'cursor'->'revision')
    or not sync_private.is_uuid(request->'operation_id') or not sync_private.is_uuid(request->'device_epoch')
    or not sync_private.is_counter(request->'sequence') or (request->>'sequence')::bigint<1
    or not sync_private.is_uuid(request->'source_operation_id')
    or not sync_private.exact_keys(request->'source_entity',array['kind','key'])
    or coalesce(request->'source_entity'->>'kind','') not in ('task','tag','milestone','view')
    or jsonb_typeof(request->'source_entity'->'key')<>'array'
    or jsonb_array_length(request->'source_entity'->'key')<>1
    or not sync_private.is_uuid(request->'source_entity'->'key'->0)
    or jsonb_typeof(request->'observed_fields') not in ('object','null')
    or coalesce(request->>'choice','') not in ('create','copyAsNew')
    or jsonb_typeof(request->'replacement')<>'object'
    or jsonb_typeof(request->'conflicts')<>'array' or jsonb_array_length(request->'conflicts') not between 1 and 200
    or jsonb_typeof(request->'held_choices')<>'array'
    or jsonb_array_length(request->'conflicts')+jsonb_array_length(request->'held_choices')>200 then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  if request->'protocol_version' is distinct from '2'::jsonb or request->'resolution_version' is distinct from '2'::jsonb then
    return sync_private.failure('unsupportedProtocol');
  end if;
  for item in select v from jsonb_array_elements(request->'conflicts') e(v) loop
    if not sync_private.exact_keys(item,array['id','revision']) or not sync_private.is_uuid(item->'id')
      or not sync_private.is_counter(item->'revision') or (item->>'revision')::bigint<1
      or (item->>'revision')::bigint>(request->'cursor'->>'revision')::bigint then
      raise exception using errcode='22023',message='Invalid account protocol message.';
    end if;
  end loop;
  for item in select v from jsonb_array_elements(request->'held_choices') e(v) loop
    if not sync_private.exact_keys(item,array['id','revision','choice']) or not sync_private.is_uuid(item->'id')
      or not sync_private.is_counter(item->'revision') or (item->>'revision')::bigint<1
      or (item->>'revision')::bigint>(request->'cursor'->>'revision')::bigint
      or coalesce(item->>'choice','') not in ('keepHeld','discard') then
      raise exception using errcode='22023',message='Invalid account protocol message.';
    end if;
  end loop;
  if (select count(distinct v->>'id') from jsonb_array_elements((request->'conflicts')||(request->'held_choices')) e(v))
    <>jsonb_array_length(request->'conflicts')+jsonb_array_length(request->'held_choices') then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  select server_epoch into strict epoch from sync_private.backend_state;
  if epoch<>(request->'cursor'->>'server_epoch')::uuid then return sync_private.failure('serverEpochChanged'); end if;
  select * into account from sync_private.account_state where owner_id=caller for update;
  if not found then return sync_private.failure('unavailable'); end if;
  if account.revoked_at is not null then return sync_private.failure('accountDeleted'); end if;
  device := (request->>'device_epoch')::uuid; op_id := (request->>'operation_id')::uuid;
  source_id := (request->>'source_operation_id')::uuid; seq := (request->>'sequence')::bigint;
  select * into prior from sync_private.resolution_requests r where r.owner_id=caller
    and (r.operation_id=op_id or (r.device_epoch=device and r.sequence=seq));
  if found then
    if prior.request_hash<>sha256(convert_to((request-'cursor')::text,'UTF8')) then return sync_private.failure('payloadMismatch'); end if;
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
  -- An exact preview covers every still-unresolved group of ONE original
  -- operation. Partial earlier resolutions are neither rewritten nor reopened.
  select coalesce(jsonb_agg(r.record order by r.id),'[]') into roots from sync_private.recovery_candidates r
    where r.owner_id=caller and r.operation_id=source_id and not exists
      (select 1 from sync_private.recovery_resolutions z where z.owner_id=caller and z.candidate_id=r.id);
  select coalesce(jsonb_agg(jsonb_build_object('id',v->'id','revision',v->'revision') order by v->>'id'),'[]') into expected
    from jsonb_array_elements(roots) e(v);
  select jsonb_agg(v order by v->>'id') into provided from jsonb_array_elements(request->'conflicts') e(v);
  if expected<>provided then return sync_private.failure('recoveryChanged'); end if;
  original := roots->0->'operation';
  if original->'entity' is distinct from request->'source_entity' then return sync_private.failure('recoveryChanged'); end if;
  fields := sync_private.recovery_fields(request->'source_entity');
  if coalesce(fields,'null')<>request->'observed_fields' then return sync_private.failure('recoveryChanged'); end if;
  with recursive affected(id,operation_id,device_epoch) as (
    select r.id,r.operation_id,r.device_epoch from sync_private.recovery_candidates r
      where r.owner_id=caller and r.operation_id=source_id
    union
    select r.id,r.operation_id,r.device_epoch from sync_private.recovery_candidates r
      join affected a on r.device_epoch=a.device_epoch and a.operation_id=any(r.predecessor_ids)
      where r.owner_id=caller and r.is_held
  ) select coalesce(jsonb_agg(r.record order by r.id),'[]') into descendants
    from affected a join sync_private.recovery_candidates r on r.owner_id=caller and r.id=a.id
    where r.operation_id<>source_id and not exists
      (select 1 from sync_private.recovery_resolutions z where z.owner_id=caller and z.candidate_id=r.id);
  select coalesce(jsonb_agg(jsonb_build_object('id',v->'id','revision',v->'revision') order by v->>'id'),'[]') into expected
    from jsonb_array_elements(descendants) e(v);
  select coalesce(jsonb_agg(v-'choice' order by v->>'id'),'[]') into provided from jsonb_array_elements(request->'held_choices') e(v);
  if expected<>provided then return sync_private.failure('recoveryChanged'); end if;
  op := request->'replacement';
  if op->'operation_id' is distinct from request->'operation_id' or op->'device_epoch' is distinct from request->'device_epoch'
    or op->'sequence' is distinct from request->'sequence'
    or op->>'command' is distinct from (request->'source_entity'->>'kind')||'.create'
    or op->'entity'->'kind' is distinct from request->'source_entity'->'kind'
    or op->'dependencies' is distinct from '[]'::jsonb or jsonb_typeof(op->'patches')<>'object'
    or exists(select 1 from jsonb_each(op->'patches') p where p.value->'base' is distinct from '{"kind":"absent"}'::jsonb) then
    raise exception using errcode='22023',message='Invalid account protocol message.';
  end if;
  if request->>'choice'='create' then
    if original->>'command' is distinct from op->>'command' or op->'entity' is distinct from original->'entity'
      or fields is not null then return sync_private.failure('replacementRejected'); end if;
  elsif op->'entity'=original->'entity' then
    return sync_private.failure('replacementRejected');
  end if;
  -- Existing or compacted tombstones are occupied identities, never fresh copies.
  if sync_private.recovery_fields(op->'entity') is not null then return sync_private.failure('replacementRejected'); end if;
  if account.revision>=9007199254740991 then return sync_private.failure('unavailable'); end if;
  revision := account.revision+1;
  begin
    outcome := public.sync_apply(jsonb_build_object('protocol_version',2,'server_epoch',epoch,
      'after_revision',account.revision,'operations',jsonb_build_array(op)));
    if outcome->>'status'<>'success' then return outcome; end if;
    if outcome->'result'->'results'->0->>'disposition'<>'applied' then
      raise exception using errcode='P0004',message='Replacement not accepted.';
    end if;
  exception when sqlstate 'P0004' then return sync_private.failure('replacementRejected'); end;
  for item in select v from jsonb_array_elements(roots) e(v)
    union all select v from jsonb_array_elements(descendants) e(v)
      where exists(select 1 from jsonb_array_elements(request->'held_choices') c where c->'id'=v->'id' and c->>'choice'='discard')
  loop
    -- V1 closures remain valid for existing download clients. Mapping is an
    -- immutable decision receipt, never an alias that redirects old references.
    closure := jsonb_build_object('version',1,'conflict_id',item->'id','expected_conflict_revision',item->'revision',
      'revision',revision,'operation_id',op_id,'device_epoch',device,'sequence',seq,
      'choice',case when item->'operation'->>'operation_id'=source_id::text then 'replace' else 'discard' end);
    insert into sync_private.recovery_resolutions(owner_id,candidate_id,revision,record)
      values(caller,(item->>'id')::uuid,revision,closure);
    closures := closures||jsonb_build_array(closure);
  end loop;
  result := sync_private.success(jsonb_build_object('resolution_version',2,'cursor',jsonb_build_object('server_epoch',epoch,'revision',revision),
    'device_high_water',seq,'resolutions',closures,'mapping',jsonb_build_object('source_operation_id',source_id,
      'source_entity',request->'source_entity','created_entity',op->'entity')));
  insert into sync_private.resolution_requests(owner_id,operation_id,device_epoch,sequence,request,reply)
    values(caller,op_id,device,seq,request,result);
  return result;
end $$;
grant create on schema public to dourstuff_rpc;
alter function public.sync_resolve_create(jsonb) owner to dourstuff_rpc;
revoke create on schema public from dourstuff_rpc;
revoke all on function public.sync_resolve_create(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.sync_resolve_create(jsonb) to authenticated;

create or replace function sync_private.prune_resolved_content(owner uuid, batch_size integer default 200)
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
    if item.request->>'choice' in ('replace','create','copyAsNew') then
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
