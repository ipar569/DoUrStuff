-- Bounded operator-only deleted-content retention; all 21 earlier migrations stay.
-- Logs/receipts (180 days), frozen captures (24 hours), retained history and
-- unresolved candidates keep their independent policies. This is not erasure.
alter table sync_private.tag_shadow drop constraint tag_shadow_fields_check;
alter table sync_private.tag_shadow add constraint tag_shadow_fields_check check (
  (sync_private.exact_keys(fields,array['existence']) and fields->'existence'->'value'='false'::jsonb)
  or (jsonb_typeof(fields)='object' and sync_private.valid_tag_name_v1(fields->'name'->'value')
    and (fields->'existence'->'value' in ('true'::jsonb,'false'::jsonb)) is true));
alter table sync_private.view_shadow drop constraint view_shadow_fields_check;
alter table sync_private.view_shadow add constraint view_shadow_fields_check check (
  (sync_private.exact_keys(fields,array['existence']) and fields->'existence'->'value'='false'::jsonb)
  or (sync_private.exact_keys(fields,array['name','query','existence'])
    and sync_private.valid_view_name(fields->'name'->'value')
    and sync_private.valid_view_query(fields->'query'->'value')
    and (jsonb_typeof(fields->'existence'->'value')='boolean') is true));

-- No clock override is exposed. The invoker samples time after the owner lock.
create view sync_private.deleted_content with (security_invoker=true) as
select s.owner_id,'task'::text kind,s.task_id entity_id,d.deleted_at
  from sync_private.task_shadow s join sync_private.task_deletions d
    on d.owner_id=s.owner_id and d.task_id=s.task_id and d.operation_id=s.delete_operation_id
  where s.fields->'existence'->'value'='false'::jsonb
union all
select s.owner_id,'tag'::text kind,s.tag_id entity_id,d.deleted_at
  from sync_private.tag_shadow s join sync_private.tag_deletions d
    on d.owner_id=s.owner_id and d.tag_id=s.tag_id and d.operation_id=s.delete_operation_id
  where s.fields->'existence'->'value'='false'::jsonb
union all
select s.owner_id,'view'::text kind,s.view_id entity_id,d.deleted_at
  from sync_private.view_shadow s join sync_private.view_deletions d
    on d.owner_id=s.owner_id and d.view_id=s.view_id and d.operation_id=s.delete_operation_id
  where s.fields->'existence'->'value'='false'::jsonb
union all
select s.owner_id,'milestone'::text kind,s.milestone_id entity_id,d.deleted_at
  from sync_private.milestone_shadow s join sync_private.milestone_deletions d
    on d.owner_id=s.owner_id and d.milestone_id=s.milestone_id and d.operation_id=s.delete_operation_id
  where s.fields->'existence'->'value'='false'::jsonb
union all
select m.owner_id,'milestone',m.milestone_id,d.deleted_at
  from sync_private.milestone_shadow m join sync_private.task_shadow t
    on (t.owner_id,t.task_id)=(m.owner_id,m.task_id)
  join sync_private.task_deletions d
    on d.owner_id=t.owner_id and d.task_id=t.task_id and d.operation_id=t.delete_operation_id
  where t.fields->'existence'->'value'='false'::jsonb;
revoke all on sync_private.deleted_content from public,anon,authenticated,service_role,dourstuff_rpc;

-- Before discarding an original, prove its complete compact identity. Legacy
-- ledger originals can backfill missing receipts; conflicting proof aborts.
create function sync_private.retain_content_identity(owner uuid, op jsonb)
returns void language plpgsql security invoker set search_path='' as $$
declare device uuid := (op->>'device_epoch')::uuid;
  seq bigint := (op->>'sequence')::bigint;
  id uuid := (op->>'operation_id')::uuid;
  digest bytea := sha256(convert_to(op::text,'UTF8'));
begin
  if op is null or not exists(select 1 from sync_private.device_state d
      where d.owner_id=owner and d.device_epoch=device and d.high_water>=seq) then
    raise exception using errcode='23514',message='Missing content identity.';
  end if;
  insert into sync_private.operation_identities(owner_id,device_epoch,sequence,operation_id,payload_hash)
    values(owner,device,seq,id,digest) on conflict do nothing;
  if not exists(select 1 from sync_private.operation_identities i where i.owner_id=owner
      and i.device_epoch=device and i.sequence=seq and i.operation_id=id and i.payload_hash=digest) then
    raise exception using errcode='23514',message='Mismatched content identity.';
  end if;
end
$$;
revoke all on function sync_private.retain_content_identity(uuid,jsonb)
  from public,anon,authenticated,service_role,dourstuff_rpc;
alter table sync_private.milestone_shadow alter column creation_operation drop not null;
alter table sync_private.tag_shadow alter column creation_operation drop not null;
alter table sync_private.view_shadow alter column creation_operation drop not null;
alter table sync_private.task_deletions alter column operation drop not null;
alter table sync_private.task_restorations alter column operation drop not null;
alter table sync_private.milestone_deletions alter column operation drop not null;
alter table sync_private.tag_deletions alter column operation drop not null;
alter table sync_private.view_deletions alter column operation drop not null;
alter table sync_private.membership_changes alter column operation drop not null;
alter table sync_private.preference_changes alter column operation drop not null;

create function sync_private.prune_deleted_content(owner uuid, batch_size integer default 200)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare account sync_private.account_state%rowtype; cutoff timestamptz;
  item record; payload record; spec record; kept jsonb; changes jsonb;
  shadows integer := 0; payloads integer := 0;
begin
  if owner is null or batch_size is null or batch_size not between 1 and 1000 then
    raise exception using errcode='22023',message='Invalid retention batch.';
  end if;
  select * into account from sync_private.account_state where owner_id=owner for update;
  if not found then raise exception using errcode='22023',message='Unknown retention account.'; end if;
  cutoff := clock_timestamp()-interval '720 hours';
  -- Each changed shadow gets its own complete log revision. Old immutable
  -- captures remain readable; new begin cannot reuse their older revision.
  for spec in select * from (values ('task'),('tag'),('view'),('milestone')) as v(kind) loop
    for item in execute format(
      'select s.%1$I as id,s.fields,s.delete_operation_id from sync_private.%2$I s
       where s.owner_id=$1 and exists(select 1 from sync_private.deleted_content d
         where d.owner_id=s.owner_id and d.kind=$2 and d.entity_id=s.%1$I and d.deleted_at<=$3)
       and s.fields is distinct from (select jsonb_object_agg(k,v) from jsonb_each(s.fields) e(k,v)
         where k=''existence'' or ($2=''milestone'' and k=''parent''))
       order by s.%1$I limit $4', spec.kind||'_id',spec.kind||'_shadow')
      using owner,spec.kind,cutoff,batch_size-shadows
    loop
      if account.revision>=9007199254740991 then
        raise exception using errcode='22003',message='Revision capacity exceeded.';
      end if;
      select jsonb_object_agg(k,v) into kept from jsonb_each(item.fields) e(k,v)
        where k='existence' or (spec.kind='milestone' and k='parent');
      if kept is null then raise exception using errcode='23514',message='Missing deletion state.'; end if;
      execute format('update sync_private.%I set fields=$1 where owner_id=$2 and %I=$3',
        spec.kind||'_shadow',spec.kind||'_id') using kept,owner,item.id;
      account.revision := account.revision+1;
      changes := jsonb_build_array(jsonb_build_object('entity',jsonb_build_object('kind',spec.kind,'key',jsonb_build_array(item.id)),
        'fields',kept,'delete_operation_id',item.delete_operation_id));
      insert into sync_private.change_log(owner_id,revision,records,recovery,recorded_at)
        values(owner,account.revision,changes,'[]',clock_timestamp());
      shadows := shadows+1;
    end loop;
  end loop;
  -- A second shared budget bounds payload rows, including large lifecycle
  -- ledgers. No per-entity unbounded update or cascade. Retry resumes nulls.
  for payload in select s.milestone_id as id,s.creation_operation as op from sync_private.milestone_shadow s
    where s.owner_id=owner and s.creation_operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id
        and d.kind='milestone' and d.entity_id=s.milestone_id and d.deleted_at<=cutoff)
    order by s.milestone_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.milestone_shadow set creation_operation=null where owner_id=owner and milestone_id=payload.id;
    payloads := payloads+1;
  end loop;
  for payload in select s.tag_id as id,s.creation_operation as op from sync_private.tag_shadow s
    where s.owner_id=owner and s.creation_operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id
        and d.kind='tag' and d.entity_id=s.tag_id and d.deleted_at<=cutoff)
    order by s.tag_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.tag_shadow set creation_operation=null where owner_id=owner and tag_id=payload.id;
    payloads := payloads+1;
  end loop;
  for payload in select s.view_id as id,s.creation_operation as op from sync_private.view_shadow s
    where s.owner_id=owner and s.creation_operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id
        and d.kind='view' and d.entity_id=s.view_id and d.deleted_at<=cutoff)
    order by s.view_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.view_shadow set creation_operation=null where owner_id=owner and view_id=payload.id;
    payloads := payloads+1;
  end loop;
  for payload in select s.operation_id as id,s.operation as op from sync_private.task_deletions s
    where s.owner_id=owner and s.operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id
        and d.kind='task' and d.entity_id=s.task_id and d.deleted_at<=cutoff)
    order by s.operation_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.task_deletions set operation=null where owner_id=owner and operation_id=payload.id;
    payloads := payloads+1;
  end loop;
  for payload in select s.operation_id as id,s.operation as op from sync_private.task_restorations s
    where s.owner_id=owner and s.operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id
        and d.kind='task' and d.entity_id=s.task_id and d.deleted_at<=cutoff)
    order by s.operation_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.task_restorations set operation=null where owner_id=owner and operation_id=payload.id;
    payloads := payloads+1;
  end loop;
  for payload in select s.operation_id as id,s.operation as op from sync_private.milestone_deletions s
    where s.owner_id=owner and s.operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id
        and d.kind='milestone' and d.entity_id=s.milestone_id and d.deleted_at<=cutoff)
    order by s.operation_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.milestone_deletions set operation=null where owner_id=owner and operation_id=payload.id;
    payloads := payloads+1;
  end loop;
  for payload in select s.operation_id as id,s.operation as op from sync_private.tag_deletions s
    where s.owner_id=owner and s.operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id
        and d.kind='tag' and d.entity_id=s.tag_id and d.deleted_at<=cutoff)
    order by s.operation_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.tag_deletions set operation=null where owner_id=owner and operation_id=payload.id;
    payloads := payloads+1;
  end loop;
  for payload in select s.operation_id as id,s.operation as op from sync_private.view_deletions s
    where s.owner_id=owner and s.operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id
        and d.kind='view' and d.entity_id=s.view_id and d.deleted_at<=cutoff)
    order by s.operation_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.view_deletions set operation=null where owner_id=owner and operation_id=payload.id;
    payloads := payloads+1;
  end loop;
  for payload in select s.operation_id as id,s.operation as op from sync_private.membership_changes s
    where s.owner_id=owner and s.operation is not null and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id and d.deleted_at<=cutoff
        and ((d.kind='task' and d.entity_id=s.task_id) or (d.kind='tag' and d.entity_id=s.tag_id)))
    order by s.operation_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.membership_changes set operation=null where owner_id=owner and operation_id=payload.id;
    payloads := payloads+1;
  end loop;
  -- Implicit preference clears duplicate the source view deletion envelope.
  -- Keep the minimal preference fields/identity, remove that duplicate payload.
  for payload in select s.operation_id as id,s.operation as op from sync_private.preference_changes s
    where s.owner_id=owner and s.operation is not null and s.operation->>'command'='view.delete' and exists(
      select 1 from sync_private.deleted_content d where d.owner_id=s.owner_id and d.deleted_at<=cutoff
        and d.kind='view' and d.entity_id=(s.operation->'entity'->'key'->>0)::uuid)
    order by s.operation_id limit batch_size-payloads
  loop
    perform sync_private.retain_content_identity(owner,payload.op);
    update sync_private.preference_changes set operation=null where owner_id=owner and operation_id=payload.id;
    payloads := payloads+1;
  end loop;
  update sync_private.account_state set revision=account.revision where owner_id=owner;
  return jsonb_build_object('shadows_compacted',shadows,'payloads_compacted',payloads,'revision',account.revision);
end
$$;
revoke all on function sync_private.prune_deleted_content(uuid,integer)
  from public,anon,authenticated,service_role,dourstuff_rpc;
