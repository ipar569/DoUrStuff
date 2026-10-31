-- Forward review correction. Keep applied 023 and every original decision intact.
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
    if prior.request-'cursor'<>request-'cursor' then return sync_private.failure('payloadMismatch'); end if;
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
  with recursive affected(record) as (
    select original
    union
    select r.record from sync_private.recovery_candidates r join affected a on
      r.record->'operation'->'device_epoch'=a.record->'operation'->'device_epoch'
      and (exists(select 1 from jsonb_each(r.record->'operation'->'patches') p
        where p.value->'base'->'operation_id'=a.record->'operation'->'operation_id')
        or exists(select 1 from jsonb_array_elements(r.record->'operation'->'dependencies') d
          where d->'operation_id'=a.record->'operation'->'operation_id'))
      where r.owner_id=caller and r.record->>'disposition'='held'
  ) select coalesce(jsonb_agg(a.record order by a.record->>'id'),'[]') into descendants
    from affected a where a.record->>'id'<>target_id::text
      and not exists(select 1 from sync_private.recovery_resolutions z where z.owner_id=caller and z.candidate_id=(a.record->>'id')::uuid);
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
