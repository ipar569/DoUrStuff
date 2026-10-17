-- First apply increment: title/priority edits on existing tasks only. Other
-- commands/groups fail preflight without consuming sequences. Client stays gated.
create table sync_private.task_shadow (
  owner_id uuid not null references sync_private.account_state on delete cascade,
  task_id uuid not null,
  fields jsonb not null check (jsonb_typeof(fields) = 'object'),
  delete_operation_id uuid,
  primary key (owner_id, task_id)
);
create table sync_private.operation_receipts (
  owner_id uuid not null,
  device_epoch uuid not null,
  sequence bigint not null check (sequence between 1 and 9007199254740991),
  operation_id uuid not null,
  operation jsonb not null,
  receipt jsonb not null,
  recorded_at timestamptz not null default transaction_timestamp(),
  primary key (owner_id, device_epoch, sequence),
  unique (owner_id, operation_id),
  foreign key (owner_id, device_epoch) references sync_private.device_state on delete cascade
);
create table sync_private.recovery_candidates (
  owner_id uuid not null references sync_private.account_state on delete cascade,
  id uuid not null default gen_random_uuid(),
  operation_id uuid not null,
  field_group text not null,
  record jsonb not null,
  primary key (owner_id, id),
  unique (owner_id, operation_id, field_group)
);
do $$
declare name text;
begin
  foreach name in array array['task_shadow','operation_receipts','recovery_candidates'] loop
    execute format('alter table sync_private.%I enable row level security', name);
    execute format('alter table sync_private.%I force row level security', name);
    execute format('create policy own_rows on sync_private.%I to dourstuff_rpc
      using (owner_id=(select sync_private.request_owner()))
      with check (owner_id=(select sync_private.request_owner()))', name);
    execute format('revoke all on sync_private.%I from public, anon, authenticated, service_role', name);
    execute format('grant select, insert on sync_private.%I to dourstuff_rpc', name);
  end loop;
end
$$;
grant update on sync_private.task_shadow, sync_private.device_state to dourstuff_rpc;
grant insert on sync_private.change_log to dourstuff_rpc;

create function sync_private.exact_json(value jsonb, depth integer default 0)
returns boolean language plpgsql immutable set search_path = '' as $$
declare child jsonb;
begin
  if value is null or depth > 16 then return false; end if;
  case jsonb_typeof(value)
    when 'number' then
      if value::text !~ '^-?(0|[1-9][0-9]{0,15})$' then return false; end if;
      return abs(value::numeric) <= 9007199254740991;
    when 'object' then
      for child in select v from jsonb_each(value) as e(k,v) loop
        if not sync_private.exact_json(child,depth+1) then return false; end if;
      end loop;
    when 'array' then
      for child in select v from jsonb_array_elements(value) as e(v) loop
        if not sync_private.exact_json(child,depth+1) then return false; end if;
      end loop;
    else null;
  end case;
  return true;
end
$$;

-- Compact representation is used ONLY for byte limits. JSONB equality is used
-- for immutable identity after exact_json rejects non-integer numbers; on this
-- accepted value domain it preserves the same objects/arrays/strings/integers
-- as Dart canonical identity, without relying on hashes or SQL key ordering.
create function sync_private.compact_json(value jsonb)
returns text language plpgsql immutable set search_path = '' as $$
declare result text;
begin
  case jsonb_typeof(value)
    when 'object' then
      select '{'||coalesce(string_agg(to_jsonb(k)::text||':'||sync_private.compact_json(v), ',' order by k collate "C"),'')||'}'
        into result from jsonb_each(value) as e(k,v);
    when 'array' then
      select '['||coalesce(string_agg(sync_private.compact_json(v), ',' order by ordinal),'')||']'
        into result from jsonb_array_elements(value) with ordinality as e(v,ordinal);
    else result := value::text;
  end case;
  return result;
end
$$;

create function sync_private.valid_edit_envelope(op jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
declare patch jsonb; base jsonb;
begin
  if not sync_private.exact_keys(op,array['protocol_version','operation_id','device_epoch','sequence',
      'entity','command','patches','dependencies','provenance'])
    or (op->'protocol_version')::text <> '2'
    or not sync_private.is_uuid(op->'operation_id') or not sync_private.is_uuid(op->'device_epoch')
    or not sync_private.is_counter(op->'sequence')
    or not sync_private.exact_keys(op->'entity',array['kind','key'])
    or op->'entity'->>'kind' is distinct from 'task' or jsonb_typeof(op->'entity'->'key') <> 'array'
    or jsonb_typeof(op->'patches') <> 'object' or op->'patches' = '{}'
    or op->>'command' <> 'task.edit' or op->'dependencies' <> '[]'
    or jsonb_typeof(op->'provenance') <> 'object' then return false; end if;
  if (op->>'sequence')::bigint < 1 or jsonb_array_length(op->'entity'->'key') <> 1
    or not sync_private.is_uuid(op->'entity'->'key'->0) then return false; end if;
  for patch in select v from jsonb_each(op->'patches') as e(k,v) loop
    if not sync_private.exact_keys(patch,array['base','value']) then return false; end if;
    base := patch->'base';
    case base->>'kind'
      when 'absent' then
        if not sync_private.exact_keys(base,array['kind']) then return false; end if;
      when 'observed' then
        if not sync_private.exact_keys(base,array['kind','revision','value'])
          or not sync_private.is_counter(base->'revision') then return false; end if;
        if (base->>'revision')::bigint < 1 then return false; end if;
      when 'predecessor' then
        if not sync_private.exact_keys(base,array['kind','operation_id','sequence','value'])
          or not sync_private.is_uuid(base->'operation_id') or not sync_private.is_counter(base->'sequence') then return false; end if;
        if (base->>'sequence')::bigint not between 1 and (op->>'sequence')::bigint-1
          or base->'operation_id'=op->'operation_id' then return false; end if;
      else return false;
    end case;
  end loop;
  return true;
end
$$;

create function sync_private.valid_title(value jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
declare title text; units integer;
begin
  if jsonb_typeof(value) <> 'string' then return false; end if;
  -- Dart trim's Unicode whitespace set, including BOM. No normalization of the
  -- retained proposed value; length is UTF-16 code units, matching Dart String.
  title := btrim(value #>> '{}', E' \t\n\r\v\f'||chr(133)||chr(160)||chr(5760)||
    chr(8192)||chr(8193)||chr(8194)||chr(8195)||chr(8196)||chr(8197)||chr(8198)||
    chr(8199)||chr(8200)||chr(8201)||chr(8202)||chr(8232)||chr(8233)||chr(8239)||
    chr(8287)||chr(12288)||chr(65279));
  if title='' then return false; end if;
  select sum(case when ascii(substr(title,n,1))>65535 then 2 else 1 end) into units
    from generate_series(1,length(title)) as n;
  return units <= 500;
end
$$;

create function public.sync_apply(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := sync_private.request_owner(); epoch uuid; device uuid;
  account sync_private.account_state%rowtype; water bigint; initial_water bigint;
  op jsonb; seq bigint; op_id uuid; task uuid; prior jsonb; previous_seq bigint;
  row_receipt sync_private.operation_receipts%rowtype;
  shadow sync_private.task_shadow%rowtype;
  item record; base jsonb; current_field jsonb; accepted jsonb; predecessor jsonb;
  predecessor_op jsonb; decision text; rejection text; disposition text;
  outcomes jsonb; candidates jsonb; changes jsonb; reply jsonb; results jsonb := '[]';
  candidate jsonb; recovery_id uuid; applied_count integer; held_count integer;
  next_revision bigint; changed boolean; seen_ids uuid[] := '{}';
begin
  if caller is null then return sync_private.failure('authenticationRequired'); end if;
  if not sync_private.live_owner() then return sync_private.failure('accountDeleted'); end if;
  if not sync_private.exact_json(request) or not sync_private.exact_keys(request,
    array['protocol_version','server_epoch','after_revision','operations'])
    or not sync_private.is_uuid(request->'server_epoch')
    or not sync_private.is_counter(request->'after_revision')
    or jsonb_typeof(request->'operations') <> 'array' then
    raise exception using errcode='22023', message='Invalid account protocol message.';
  end if;
  if (request->'protocol_version')::text <> '2' then return sync_private.failure('unsupportedProtocol'); end if;
  if jsonb_array_length(request->'operations') not between 1 and 32
    or octet_length(sync_private.compact_json(request)) > 1048576 then
    raise exception using errcode='22023', message='Invalid account protocol message.';
  end if;
  -- Entire-batch structure and supported-capability preflight precedes writes.
  for op in select v from jsonb_array_elements(request->'operations') as e(v) loop
    if op->>'command' is distinct from 'task.edit' or op ? 'restore'
      or (jsonb_typeof(op->'patches')='object' and exists
          (select 1 from jsonb_object_keys(op->'patches') as g where g not in ('title','priority')))
      or (op ? 'dependencies' and op->'dependencies' <> '[]') then
      return sync_private.failure('unsupportedProtocol');
    end if;
    if not sync_private.valid_edit_envelope(op) or octet_length(sync_private.compact_json(op)) > 65536 then
      raise exception using errcode='22023', message='Invalid account protocol message.';
    end if;
    seq := (op->>'sequence')::bigint; op_id := (op->>'operation_id')::uuid;
    if device is null then device := (op->>'device_epoch')::uuid; end if;
    if device <> (op->>'device_epoch')::uuid or (previous_seq is not null and seq<>previous_seq+1)
      or op_id=any(seen_ids) then
      raise exception using errcode='22023', message='Invalid account protocol message.';
    end if;
    seen_ids := array_append(seen_ids,op_id); previous_seq := seq;
  end loop;
  select server_epoch into strict epoch from sync_private.backend_state;
  if epoch<>(request->>'server_epoch')::uuid then return sync_private.failure('serverEpochChanged'); end if;
  select * into account from sync_private.account_state where owner_id=caller for update;
  if not found then return sync_private.failure('unavailable'); end if;
  if account.revoked_at is not null then return sync_private.failure('accountDeleted'); end if;
  if (request->>'after_revision')::bigint<account.retained_after then return sync_private.failure('cursorExpired'); end if;
  if (request->>'after_revision')::bigint>account.revision then
    raise exception using errcode='22023', message='Invalid account protocol message.';
  end if;
  select high_water into water from sync_private.device_state where owner_id=caller and device_epoch=device;
  if not found then return sync_private.failure('unavailable'); end if;
  initial_water := water;
  if (request->'operations'->0->>'sequence')::bigint>water+1 then
    return sync_private.failure('sequenceGap')||jsonb_build_object('expected_sequence',water+1);
  end if;
  if account.revision + greatest(0,previous_seq-water)>9007199254740991 then return sync_private.failure('unavailable'); end if;
  -- A mismatch anywhere must consume nothing, including earlier batch entries.
  for op in select v from jsonb_array_elements(request->'operations') as e(v) loop
    seq := (op->>'sequence')::bigint; op_id := (op->>'operation_id')::uuid;
    if exists(select 1 from sync_private.operation_receipts r where r.owner_id=caller and
       (r.operation_id=op_id or (r.device_epoch=device and r.sequence=seq)) and r.operation<>op)
      or exists(select 1 from sync_private.recovery_candidates r where r.owner_id=caller and
        r.operation_id=op_id and r.record->'operation'<>op) then
      return sync_private.failure('payloadMismatch');
    end if;
  end loop;
  for op in select v from jsonb_array_elements(request->'operations') as e(v) loop
    seq := (op->>'sequence')::bigint; op_id := (op->>'operation_id')::uuid;
    if seq<=initial_water then
      select receipt into reply from sync_private.operation_receipts
        where owner_id=caller and device_epoch=device and sequence=seq;
      if not found then reply := jsonb_build_object('kind','already_processed','operation_id',op_id,'sequence',seq); end if;
      results := results||jsonb_build_array(reply);
      continue;
    end if;
    task := (op->'entity'->'key'->>0)::uuid;
    select * into shadow from sync_private.task_shadow where owner_id=caller and task_id=task;
    rejection := null;
    if not found then rejection := 'entity_missing'; end if;
    if op->'patches' ? 'title' and not sync_private.valid_title(op->'patches'->'title'->'value') then rejection := 'invalid_title'; end if;
    if op->'patches' ? 'priority' and not (op->'patches'->'priority'->'value'=any(
      array['"none"','"low"','"medium"','"high"']::jsonb[])) then rejection := 'invalid_priority'; end if;
    next_revision := account.revision+1;
    outcomes := '[]'; candidates := '[]'; changes := '[]'; applied_count := 0; held_count := 0; changed := false;
    for item in select k,v from jsonb_each(op->'patches') as e(k,v) order by k loop
      base := item.v->'base'; current_field := shadow.fields->item.k;
      accepted := null; decision := null;
      if rejection is not null or shadow.fields->'existence'->'value'='false'::jsonb then
        decision := 'recovery';
      elsif base->>'kind'='predecessor' then
        select * into row_receipt from sync_private.operation_receipts where owner_id=caller and
          device_epoch=device and sequence=(base->>'sequence')::bigint and operation_id=(base->>'operation_id')::uuid;
        if found then
          predecessor_op := row_receipt.operation;
          select f into predecessor from jsonb_array_elements(row_receipt.receipt->'fields') as e(f)
            where f->>'group'=item.k;
        else
          select record->'operation', jsonb_build_object('disposition',record->>'disposition','accepted',null)
            into predecessor_op, predecessor from sync_private.recovery_candidates
            where owner_id=caller and operation_id=(base->>'operation_id')::uuid and field_group=item.k;
        end if;
        if predecessor_op is null or predecessor_op->'entity'<>op->'entity'
          or predecessor_op->'device_epoch'<>op->'device_epoch'
          or predecessor_op->'sequence'<>base->'sequence' or not (predecessor_op->'patches' ? item.k)
          or predecessor is null or predecessor->>'disposition'='recovery' then decision := 'recovery';
        elsif predecessor->>'disposition' in ('conflict','held') then decision := 'held';
        elsif predecessor->'accepted'->'value' is distinct from base->'value' then decision := 'recovery';
        else base := jsonb_build_object('kind','observed','revision',predecessor->'accepted'->'revision','value',base->'value');
        end if;
      end if;
      if decision is null then
        if base->>'kind'='absent' and current_field is null then decision := 'applied';
        elsif base->>'kind'='observed' and base->'revision'=current_field->'revision' then
          decision := case when base->'value'=current_field->'value' then 'applied' else 'recovery' end;
        elsif current_field is not null and item.v->'value'=current_field->'value' then decision := 'equivalent';
        else decision := 'conflict'; end if;
      end if;
      if decision='applied' then
        accepted := jsonb_build_object('revision',next_revision,'value',item.v->'value');
        shadow.fields := shadow.fields||jsonb_build_object(item.k,accepted); changed := true;
      elsif decision='equivalent' then accepted := current_field;
      end if;
      recovery_id := null;
      if accepted is not null then applied_count := applied_count+1;
      else
        recovery_id := gen_random_uuid();
        candidate := jsonb_build_object('id',recovery_id,'revision',next_revision,'operation',op,
          'group',item.k,'disposition',decision,'canonical',current_field);
        insert into sync_private.recovery_candidates(owner_id,id,operation_id,field_group,record)
          values(caller,recovery_id,op_id,item.k,candidate);
        candidates := candidates||jsonb_build_array(candidate);
      end if;
      if decision='held' then held_count := held_count+1; end if;
      outcomes := outcomes||jsonb_build_array(jsonb_build_object('group',item.k,'disposition',decision,
        'accepted',accepted,'recovery_id',recovery_id));
    end loop;
    if changed then
      update sync_private.task_shadow set fields=shadow.fields where owner_id=caller and task_id=task;
      changes := jsonb_build_array(jsonb_build_object('entity',op->'entity','fields',shadow.fields,
        'delete_operation_id',shadow.delete_operation_id));
    end if;
    disposition := case when rejection is not null then 'rejected'
      when applied_count=jsonb_array_length(outcomes) then 'applied' when applied_count>0 then 'partial'
      when held_count=jsonb_array_length(outcomes) then 'held' else 'conflict' end;
    reply := jsonb_build_object('kind','receipt','operation_id',op_id,'sequence',seq,'revision',next_revision,
      'disposition',disposition,'rejection_code',rejection,'fields',case when rejection is not null then '[]'::jsonb else outcomes end);
    insert into sync_private.operation_receipts(owner_id,device_epoch,sequence,operation_id,operation,receipt)
      values(caller,device,seq,op_id,op,reply);
    insert into sync_private.change_log(owner_id,revision,records,recovery) values(caller,next_revision,changes,candidates);
    account.revision := next_revision; water := seq;
    results := results||jsonb_build_array(reply);
  end loop;
  update sync_private.account_state set revision=account.revision where owner_id=caller;
  update sync_private.device_state set high_water=water where owner_id=caller and device_epoch=device;
  return sync_private.success(jsonb_build_object('cursor',jsonb_build_object('server_epoch',epoch,'revision',account.revision),
    'device_high_water',water,'results',results));
end
$$;
grant create on schema public to dourstuff_rpc;
alter function public.sync_apply(jsonb) owner to dourstuff_rpc;
revoke create on schema public from dourstuff_rpc;
revoke all on function public.sync_apply(jsonb) from public, anon, authenticated, service_role;
grant execute on function public.sync_apply(jsonb) to authenticated;
revoke all on function sync_private.exact_json(jsonb,integer), sync_private.compact_json(jsonb),
  sync_private.valid_edit_envelope(jsonb), sync_private.valid_title(jsonb) from public, anon, authenticated, service_role;
grant execute on function sync_private.exact_json(jsonb,integer), sync_private.compact_json(jsonb),
  sync_private.valid_edit_envelope(jsonb), sync_private.valid_title(jsonb) to dourstuff_rpc;
