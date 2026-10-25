-- Independently versioned membership for the exact [task UUID, tag UUID].
-- No UUID aliases, parent rewrites, or changes to the fifteen applied migrations.
create table sync_private.membership_shadow (
  owner_id uuid not null,
  task_id uuid not null,
  tag_id uuid not null,
  fields jsonb not null check (sync_private.exact_keys(fields,array['membership'])
    and (jsonb_typeof(fields->'membership'->'value')='boolean') is true),
  primary key (owner_id,task_id,tag_id),
  foreign key (owner_id,task_id) references sync_private.task_shadow on delete cascade,
  foreign key (owner_id,tag_id) references sync_private.tag_shadow on delete cascade
);
create index membership_shadow_tag on sync_private.membership_shadow(owner_id,tag_id);
alter table sync_private.membership_shadow enable row level security;
alter table sync_private.membership_shadow force row level security;
create policy own_rows on sync_private.membership_shadow to dourstuff_rpc
  using (owner_id=(select sync_private.request_owner()))
  with check (owner_id=(select sync_private.request_owner()));
revoke all on sync_private.membership_shadow from public, anon, authenticated, service_role;
grant select,insert on sync_private.membership_shadow to dourstuff_rpc;
grant update(fields) on sync_private.membership_shadow to dourstuff_rpc;

-- Retain original accepted add/remove identities beyond detailed receipt expiry.
create table sync_private.membership_changes (
  owner_id uuid not null,
  task_id uuid not null,
  tag_id uuid not null,
  operation_id uuid not null,
  revision bigint not null check (revision between 1 and 9007199254740991),
  operation jsonb not null,
  primary key (owner_id,operation_id),
  foreign key (owner_id,task_id,tag_id) references sync_private.membership_shadow on delete cascade
);
create index membership_changes_entity on sync_private.membership_changes(owner_id,task_id,tag_id);
alter table sync_private.membership_changes enable row level security;
alter table sync_private.membership_changes force row level security;
create policy own_rows on sync_private.membership_changes to dourstuff_rpc
  using (owner_id=(select sync_private.request_owner()))
  with check (owner_id=(select sync_private.request_owner()));
revoke all on sync_private.membership_changes from public, anon, authenticated, service_role;
grant select,insert on sync_private.membership_changes to dourstuff_rpc;

create function sync_private.membership_visible(task uuid, tag uuid)
returns boolean language sql stable set search_path = '' as $$
  select exists(select 1 from sync_private.membership_shadow m
    join sync_private.task_shadow t on (t.owner_id,t.task_id)=(m.owner_id,m.task_id)
    join sync_private.tag_shadow g on (g.owner_id,g.tag_id)=(m.owner_id,m.tag_id)
    where m.owner_id=sync_private.request_owner() and m.task_id=task and m.tag_id=tag
      and m.fields->'membership'->'value'='true'::jsonb
      and t.fields->'existence'->'value'='true'::jsonb
      and g.fields->'existence'->'value'='true'::jsonb)
$$;

-- Called under the account row lock. Validate every dependency before selecting
-- held/recovery, so dependency-array order cannot hide invalid evidence.
create function sync_private.membership_parent_decision(op jsonb)
returns text language plpgsql stable set search_path = '' as $$
declare dep jsonb; prior sync_private.operation_receipts%rowtype; outcome jsonb;
  seen jsonb := '[]'; held boolean := false; parent_task uuid; parent_tag uuid;
begin
  parent_task := (op->'entity'->'key'->>0)::uuid;
  parent_tag := (op->'entity'->'key'->>1)::uuid;
  for dep in select v from jsonb_array_elements(op->'dependencies') as e(v) loop
    if dep->'entity' not in (jsonb_build_object('kind','task','key',jsonb_build_array(parent_task)),
        jsonb_build_object('kind','tag','key',jsonb_build_array(parent_tag)))
      or seen @> jsonb_build_array(dep->'entity') then return 'recovery'; end if;
    seen := seen||jsonb_build_array(dep->'entity');
    select * into prior from sync_private.operation_receipts where owner_id=sync_private.request_owner()
      and device_epoch=(op->>'device_epoch')::uuid and sequence=(dep->>'sequence')::bigint
      and operation_id=(dep->>'operation_id')::uuid;
    if not found or prior.operation->'entity'<>dep->'entity'
      or prior.receipt->>'disposition'='rejected' then return 'recovery'; end if;
    select f into outcome from jsonb_array_elements(prior.receipt->'fields') as e(f) where f->>'group'='existence';
    if outcome is null then return 'recovery'; end if;
    if outcome->>'disposition' in ('conflict','held') then held := true;
    elsif outcome->>'disposition' not in ('applied','equivalent')
      or outcome->'accepted'->'value' is distinct from 'true'::jsonb
      or outcome->'recovery_id' is distinct from 'null'::jsonb then return 'recovery'; end if;
  end loop;
  if held then return 'held'; end if;
  -- Explicit removals remain independent while a parent is hidden. Restoring a
  -- task must not undo a removal. Additions always require both live parents.
  if not exists(select 1 from sync_private.task_shadow t
      join sync_private.tag_shadow g on g.owner_id=t.owner_id
      where t.owner_id=sync_private.request_owner() and t.task_id=parent_task and g.tag_id=parent_tag
        and (op->'patches'->'membership'->'value'='false'::jsonb
          or (t.fields->'existence'->'value'='true'::jsonb and g.fields->'existence'->'value'='true'::jsonb)))
    then return 'recovery'; end if;
  return null;
end
$$;

create function sync_private.valid_membership_envelope(op jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
declare patch jsonb; base jsonb; dep jsonb; kind text; arity integer;
begin
  if not sync_private.exact_keys(op,array['protocol_version','operation_id','device_epoch','sequence',
      'entity','command','patches','dependencies','provenance'])
    or (op->'protocol_version')::text is distinct from '2'
    or not sync_private.is_uuid(op->'operation_id') or not sync_private.is_uuid(op->'device_epoch')
    or not sync_private.is_counter(op->'sequence')
    or not sync_private.exact_keys(op->'entity',array['kind','key'])
    or op->'entity'->>'kind' is distinct from 'membership' or jsonb_typeof(op->'entity'->'key') is distinct from 'array'
    or jsonb_typeof(op->'patches') is distinct from 'object' or op->'patches' = '{}'
    or op->>'command' is distinct from 'task.tag' or jsonb_typeof(op->'dependencies') is distinct from 'array'
    or jsonb_typeof(op->'provenance') is distinct from 'object' then return false; end if;
  if (op->>'sequence')::bigint < 1 or jsonb_array_length(op->'entity'->'key') <> 2
    or not sync_private.is_uuid(op->'entity'->'key'->0)
    or not sync_private.is_uuid(op->'entity'->'key'->1) then return false; end if;
  for dep in select v from jsonb_array_elements(op->'dependencies') as e(v) loop
    if not sync_private.exact_keys(dep,array['entity','operation_id','sequence','group'])
      or dep->>'group' is distinct from 'existence'
      or not sync_private.is_uuid(dep->'operation_id') or not sync_private.is_counter(dep->'sequence')
      or not sync_private.exact_keys(dep->'entity',array['kind','key'])
      or jsonb_typeof(dep->'entity'->'key') is distinct from 'array' then return false; end if;
    kind := dep->'entity'->>'kind';
    if kind is null or kind not in ('task','tag','milestone','membership','view','preference') then return false; end if;
    arity := case when kind='membership' then 2 else 1 end;
    if jsonb_array_length(dep->'entity'->'key')<>arity
      or (dep->>'sequence')::bigint not between 1 and (op->>'sequence')::bigint-1
      or dep->'operation_id'=op->'operation_id' then return false; end if;
    if kind='preference' then
      if dep->'entity'->'key'->0 is distinct from '"default_view"'::jsonb then return false; end if;
    elsif exists(select 1 from jsonb_array_elements(dep->'entity'->'key') as k(v)
      where not sync_private.is_uuid(v)) then return false;
    end if;
  end loop;
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

revoke all on function sync_private.valid_membership_envelope(jsonb),
  sync_private.membership_parent_decision(jsonb), sync_private.membership_visible(uuid,uuid)
  from public, anon, authenticated, service_role;
grant execute on function sync_private.valid_membership_envelope(jsonb),
  sync_private.membership_parent_decision(jsonb), sync_private.membership_visible(uuid,uuid) to dourstuff_rpc;

create or replace function public.sync_apply(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := sync_private.request_owner(); epoch uuid; device uuid;
  account sync_private.account_state%rowtype; water bigint; initial_water bigint;
  op jsonb; seq bigint; op_id uuid; task uuid; prior jsonb; previous_seq bigint;
  row_receipt sync_private.operation_receipts%rowtype;
  shadow sync_private.task_shadow%rowtype;
  deletion sync_private.task_deletions%rowtype; restoring boolean;
  membership boolean; membership_tag uuid; milestone boolean; tag boolean; tag_collision boolean; parent_decision text;
  item record; base jsonb; current_field jsonb; accepted jsonb; predecessor jsonb;
  predecessor_op jsonb; decision text; rejection text; disposition text;
  outcomes jsonb; candidates jsonb; changes jsonb; reply jsonb; results jsonb := '[]';
  candidate jsonb; recovery_id uuid; applied_count integer; held_count integer;
  next_revision bigint; changed boolean; creating boolean; identity_exists boolean; old_status jsonb; seen_ids uuid[] := '{}';
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
    milestone := op->>'command' in ('milestone.create','milestone.edit','milestone.delete');
    tag := op->>'command' in ('tag.create','tag.edit','tag.delete');
    membership := op->>'command'='task.tag';
    if membership then
      if jsonb_typeof(op->'patches')='object' and exists
        (select 1 from jsonb_object_keys(op->'patches') as g where g<>'membership') then
        return sync_private.failure('unsupportedProtocol');
      end if;
      if not sync_private.valid_membership_envelope(op) then
        raise exception using errcode='22023', message='Invalid account protocol message.';
      end if;
    elsif tag then
      if op->'dependencies' <> '[]' or (jsonb_typeof(op->'patches')='object' and exists
        (select 1 from jsonb_object_keys(op->'patches') as g where g not in ('name','existence'))) then
        return sync_private.failure('unsupportedProtocol');
      end if;
      if not sync_private.valid_tag_envelope(op) then
        raise exception using errcode='22023', message='Invalid account protocol message.';
      end if;
    elsif milestone then
      if op->>'command'<>'milestone.create' and op->'dependencies'<>'[]' then
        return sync_private.failure('unsupportedProtocol');
      end if;
      if jsonb_typeof(op->'patches')='object' and exists
        (select 1 from jsonb_object_keys(op->'patches') as g where g not in ('title','completion','parent','existence')) then
        return sync_private.failure('unsupportedProtocol');
      end if;
      if not sync_private.valid_milestone_envelope(op) then
        raise exception using errcode='22023', message='Invalid account protocol message.';
      end if;
    else
      if coalesce(op->>'command','') not in ('task.create','task.edit','task.status','task.delete','task.restore','task.milestone_order')
        or (jsonb_typeof(op->'patches')='object' and exists
            (select 1 from jsonb_object_keys(op->'patches') as g where g not in ('title','priority','status_group','existence','description','estimate_minutes','due','milestone_order')))
        or (op->>'command' not in ('task.create','task.delete','task.restore') and op->'patches' ? 'existence')
        or (op->>'command'<>'task.milestone_order' and op ? 'dependencies' and op->'dependencies' <> '[]') then
        return sync_private.failure('unsupportedProtocol');
      end if;
      if not sync_private.valid_task_envelope(op) then
        raise exception using errcode='22023', message='Invalid account protocol message.';
      end if;
    end if;
    if octet_length(sync_private.compact_json(op)) > 65536 then
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
        r.operation_id=op_id and r.record->'operation'<>op)
      or exists(select 1 from sync_private.task_deletions d where d.owner_id=caller
        and d.operation_id=op_id and d.operation<>op)
      or exists(select 1 from sync_private.task_restorations r where r.owner_id=caller
        and r.operation_id=op_id and r.operation<>op)
      or exists(select 1 from sync_private.milestone_shadow m where m.owner_id=caller
        and m.creation_operation->>'operation_id'=op_id::text and m.creation_operation<>op)
      or exists(select 1 from sync_private.milestone_deletions d where d.owner_id=caller
        and d.operation_id=op_id and d.operation<>op)
      or exists(select 1 from sync_private.tag_shadow t where t.owner_id=caller
        and t.creation_operation->>'operation_id'=op_id::text and t.creation_operation<>op)
      or exists(select 1 from sync_private.tag_deletions d where d.owner_id=caller
        and d.operation_id=op_id and d.operation<>op)
      or exists(select 1 from sync_private.membership_changes m where m.owner_id=caller
        and m.operation_id=op_id and m.operation<>op)
      -- History outlives detailed receipts. Its operation identity cannot be
      -- reassigned to a new sequence (including a title-only operation).
      or exists(select 1 from sync_private.task_status_history h
        where h.owner_id=caller and h.operation_id=op_id and
          ((h.operation is not null and h.operation<>op) or (h.operation is null and seq>water))) then
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
    milestone := op->>'command' in ('milestone.create','milestone.edit','milestone.delete');
    tag := op->>'command' in ('tag.create','tag.edit','tag.delete');
    membership := op->>'command'='task.tag';
    if membership then
      membership_tag := (op->'entity'->'key'->>1)::uuid;
      shadow := null;
      select m.fields into shadow.fields from sync_private.membership_shadow m
        where m.owner_id=caller and m.task_id=task and m.tag_id=membership_tag;
      identity_exists := found;
      if not identity_exists then shadow.fields := '{}'; end if;
    elsif tag then
      shadow := null;
      select t.fields,t.delete_operation_id into shadow.fields,shadow.delete_operation_id
        from sync_private.tag_shadow t where t.owner_id=caller and t.tag_id=task;
      identity_exists := found;
    elsif milestone then
      shadow := null;
      select m.fields,m.delete_operation_id into shadow.fields,shadow.delete_operation_id
        from sync_private.milestone_shadow m where m.owner_id=caller and m.milestone_id=task;
      identity_exists := found;
    else
      select * into shadow from sync_private.task_shadow where owner_id=caller and task_id=task;
      identity_exists := found;
    end if;
    creating := op->>'command' in ('task.create','milestone.create','tag.create');
    parent_decision := null;
    restoring := op->>'command'='task.restore';
    old_status := shadow.fields->'status_group';
    rejection := null;
    if creating then
      -- Core groups are mandatory; description, estimate and due are optional.
      -- Every supplied create group has an absent base and commits together.
      if not (op->'patches' ?& case when tag then array['existence','name']
          when milestone then array['existence','title','completion','parent']
          else array['existence','title','priority','status_group'] end)
        or op->'patches'->'existence'->'value' is distinct from 'true'::jsonb
        or exists(select 1 from jsonb_each(op->'patches') as p(k,v) where v->'base'->>'kind'<>'absent') then
        rejection := 'invalid_create';
      end if;
      if not identity_exists then shadow.fields := '{}'; end if;
    elsif not identity_exists and not milestone and not tag and not membership then rejection := 'entity_missing';
    end if;
    if op->>'command' in ('task.delete','milestone.delete','tag.delete') and (
      not sync_private.exact_keys(op->'patches',array['existence'])
      or op->'patches'->'existence'->'value' is distinct from 'false'::jsonb
      or op->'patches'->'existence'->'base'->>'kind' not in ('observed','predecessor')
      or op->'patches'->'existence'->'base'->'value' is distinct from 'true'::jsonb) then
      rejection := 'invalid_delete_command';
    end if;
    if restoring then
      if not sync_private.exact_keys(op->'patches',array['existence'])
        or op->'patches'->'existence'->'value' is distinct from 'true'::jsonb
        or op->'patches'->'existence'->'base'->>'kind' is distinct from 'observed'
        or op->'patches'->'existence'->'base'->'value' is distinct from 'false'::jsonb
        or op->'patches'->'existence'->'base'->'revision' is distinct from op->'restore'->'revision' then
        rejection := 'invalid_restore_command';
      elsif identity_exists then
        select * into deletion from sync_private.task_deletions where owner_id=caller
          and task_id=task and operation_id=shadow.delete_operation_id;
        if not found or shadow.fields->'existence'->'value' is distinct from 'false'::jsonb
          or shadow.delete_operation_id is distinct from (op->'restore'->>'delete_operation_id')::uuid
          or shadow.fields->'existence'->'revision' is distinct from op->'restore'->'revision'
          or deletion.revision is distinct from (op->'restore'->>'revision')::bigint then
          rejection := 'stale_deletion';
        elsif not (shadow.fields ?& array['title','priority','status_group'])
          or not sync_private.restore_window_open(deletion.deleted_at,clock_timestamp()) then
          rejection := 'restore_content_expired';
        end if;
      end if;
    end if;
    if membership then
      if jsonb_typeof(op->'patches'->'membership'->'value') is distinct from 'boolean'
        or (op->'patches'->'membership'->'base'->>'kind'<>'absent'
          and jsonb_typeof(op->'patches'->'membership'->'base'->'value') is distinct from 'boolean') then
        rejection := 'invalid_membership';
      elsif jsonb_array_length(op->'dependencies')>2 then
        rejection := 'invalid_parent_dependencies';
      else parent_decision := sync_private.membership_parent_decision(op);
      end if;
    end if;
    tag_collision := false;
    if tag then
      if op->>'command'='tag.edit' and not sync_private.exact_keys(op->'patches',array['name']) then
        rejection := 'invalid_tag_edit';
      end if;
      if op->'patches' ? 'name' then
        if not sync_private.valid_tag_name_v1(op->'patches'->'name'->'value') then
          rejection := 'invalid_tag_name';
        elsif rejection is null then
          -- Account row lock serializes lookup and write; the partial unique
          -- index additionally enforces live-name uniqueness using exact bytes.
          select exists(select 1 from sync_private.tag_shadow t where t.owner_id=caller
            and t.tag_id<>task and t.fields->'existence'->'value'='true'::jsonb
            and (t.fields->'name'->'value'->>'normalized_name') collate "C"
              = (op->'patches'->'name'->'value'->>'normalized_name') collate "C") into tag_collision;
        end if;
      end if;
    end if;
    if op->>'command'='task.status' and not sync_private.exact_keys(op->'patches',array['status_group']) then
      rejection := 'invalid_status_command';
    end if;
    if op->'patches' ? 'status_group' and not sync_private.valid_status_group(op->'patches'->'status_group'->'value') then
      rejection := 'invalid_status_group';
    end if;
    if op->'patches' ? 'title' and not sync_private.valid_title(op->'patches'->'title'->'value') then rejection := 'invalid_title'; end if;
    if op->'patches' ? 'priority' and not (op->'patches'->'priority'->'value'=any(
      array['"none"','"low"','"medium"','"high"']::jsonb[])) then rejection := 'invalid_priority'; end if;
    if op->'patches' ? 'description' and not sync_private.valid_description(op->'patches'->'description'->'value') then
      rejection := 'invalid_description';
    end if;
    if op->'patches' ? 'estimate_minutes' and not sync_private.valid_estimate(op->'patches'->'estimate_minutes'->'value') then
      rejection := 'invalid_estimate_minutes';
    end if;
    if op->'patches' ? 'due' and not sync_private.valid_due(op->'patches'->'due'->'value') then
      rejection := 'invalid_due';
    end if;
    if milestone then
      -- Completion retains the nullable epoch-millisecond value used locally.
      if op->'patches' ? 'completion' and not sync_private.valid_status_group(jsonb_build_object(
        'status',case when op->'patches'->'completion'->'value'='null'::jsonb then 'todo' else 'completed' end,
        'completed_at',op->'patches'->'completion'->'value')) then
        rejection := 'invalid_completion';
      end if;
      if creating then
        if not sync_private.is_uuid(op->'patches'->'parent'->'value') then rejection := 'invalid_parent'; end if;
        if jsonb_array_length(op->'dependencies')>1 then rejection := 'invalid_parent_dependencies'; end if;
        if rejection is null then parent_decision := sync_private.milestone_parent_decision(op); end if;
      elsif op->>'command'='milestone.edit' then
        if exists(select 1 from jsonb_object_keys(op->'patches') as g where g not in ('title','completion')) then
          rejection := 'invalid_milestone_edit';
        end if;
        -- Hidden parent content is recoverable, never an implicit resurrection.
        if identity_exists and not sync_private.milestone_visible(task) then parent_decision := 'recovery'; end if;
      end if;
      -- An explicit child delete compares the child's own existence even while
      -- its parent is hidden. Parent restore must not undo that independent delete.

    end if;
    if op->>'command'='task.milestone_order' then
      if not sync_private.exact_keys(op->'patches',array['milestone_order']) then
        rejection := 'invalid_order_command';
      elsif not sync_private.valid_milestone_order(op->'patches'->'milestone_order'->'value') then
        rejection := 'invalid_milestone_order';
      elsif rejection is null then
        parent_decision := sync_private.milestone_order_decision(op);
      end if;
    elsif op->'patches' ? 'milestone_order' then
      -- Ordering is a separate atomic command, never part of create/edit/status.
      rejection := 'invalid_order_command';
    end if;
    next_revision := account.revision+1;
    outcomes := '[]'; candidates := '[]'; changes := '[]'; applied_count := 0; held_count := 0; changed := false;
    for item in select k,v from jsonb_each(op->'patches') as e(k,v) order by k loop
      base := item.v->'base'; current_field := shadow.fields->item.k;
      accepted := null; decision := null;
      if rejection is not null or (shadow.fields->'existence'->'value'='false'::jsonb and not restoring) then
        decision := 'recovery';
      elsif parent_decision is not null then decision := parent_decision;
      elsif creating and identity_exists then
        -- Never field-merge a colliding create, even if a proposed value equals
        -- the existing field or a core field is absent on an older shadow.
        decision := 'conflict';
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
        -- A held child create may have no canonical row yet. Bind its actual
        -- predecessor first, retaining held results, but never create via edit.
        if (milestone or tag) and not creating and not identity_exists then decision := 'recovery';
        -- Bind a conflicted predecessor before checking names: successors
        -- stay held even if the blocking name later becomes available.
        elsif tag_collision then decision := 'conflict';
        elsif base->>'kind'='absent' and current_field is null then decision := 'applied';
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
      if membership then
        if identity_exists then
          update sync_private.membership_shadow m set fields=shadow.fields
            where m.owner_id=caller and m.task_id=task and m.tag_id=membership_tag;
        else
          insert into sync_private.membership_shadow(owner_id,task_id,tag_id,fields)
            values(caller,task,membership_tag,shadow.fields);
        end if;
        insert into sync_private.membership_changes(owner_id,task_id,tag_id,operation_id,revision,operation)
          values(caller,task,membership_tag,op_id,next_revision,op);
      end if;
      if restoring then
        insert into sync_private.task_restorations(owner_id,task_id,operation_id,deletion_operation_id,revision,operation)
          values(caller,task,op_id,shadow.delete_operation_id,next_revision,op);
      end if;
      if op->>'command'='task.delete' then
        shadow.delete_operation_id := op_id;
        insert into sync_private.task_deletions(owner_id,task_id,operation_id,revision,operation)
          values(caller,task,op_id,next_revision,op);
      end if;
      if membership then
        -- The composite membership was written above; neither parent is edited.
        null;
      elsif tag then
        if creating then
          insert into sync_private.tag_shadow(owner_id,tag_id,fields,creation_operation)
            values(caller,task,shadow.fields,op);
        else
          if op->>'command'='tag.delete' then
            shadow.delete_operation_id := op_id;
            insert into sync_private.tag_deletions(owner_id,tag_id,operation_id,revision,operation)
              values(caller,task,op_id,next_revision,op);
          end if;
          update sync_private.tag_shadow t set fields=shadow.fields,delete_operation_id=shadow.delete_operation_id
            where t.owner_id=caller and t.tag_id=task;
        end if;
      elsif milestone then
        if creating then
          insert into sync_private.milestone_shadow(owner_id,milestone_id,task_id,fields,creation_operation)
            values(caller,task,(op->'patches'->'parent'->>'value')::uuid,shadow.fields,op);
        else
          if op->>'command'='milestone.delete' then
            shadow.delete_operation_id := op_id;
            insert into sync_private.milestone_deletions(owner_id,milestone_id,operation_id,revision,operation)
              values(caller,task,op_id,next_revision,op);
          end if;
          update sync_private.milestone_shadow m set fields=shadow.fields,delete_operation_id=shadow.delete_operation_id
            where m.owner_id=caller and m.milestone_id=task;
        end if;
      elsif creating then
        insert into sync_private.task_shadow(owner_id,task_id,fields) values(caller,task,shadow.fields);
      else
        update sync_private.task_shadow set fields=shadow.fields, delete_operation_id=shadow.delete_operation_id where owner_id=caller and task_id=task;
      end if;
      -- A fresh command may accept a new revision without a status transition.
      if not membership and not milestone and not tag and shadow.fields->'status_group'->'value' is distinct from old_status->'value' then
        insert into sync_private.task_status_history(owner_id,task_id,operation_id,revision,previous_status,status,fields,provenance,operation)
          values(caller,task,op_id,next_revision,old_status,shadow.fields->'status_group',shadow.fields,op->'provenance',op);
      end if;
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
