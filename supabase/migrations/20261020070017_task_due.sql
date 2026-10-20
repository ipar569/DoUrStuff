-- Atomic due values. Existing migrations and immutable operations stay intact.
-- Zone vocabulary is pinned to TimePolicy.zones / timezone 0.11.1.
-- PostgreSQL's installed tzdata resolves offsets; cross-runtime fixtures verify
-- current dates and gap/fold cases. Full historical/future tzdata parity remains
-- an activation gate; do not silently normalize or re-resolve existing values.
create function sync_private.due_zone_supported(value text)
returns boolean language sql immutable set search_path = '' as $$
  select value = any(array[
    'Africa/Abidjan',
    'Africa/Algiers',
    'Africa/Bissau',
    'Africa/Cairo',
    'Africa/Casablanca',
    'Africa/Ceuta',
    'Africa/El_Aaiun',
    'Africa/Johannesburg',
    'Africa/Juba',
    'Africa/Khartoum',
    'Africa/Lagos',
    'Africa/Maputo',
    'Africa/Monrovia',
    'Africa/Nairobi',
    'Africa/Ndjamena',
    'Africa/Sao_Tome',
    'Africa/Tripoli',
    'Africa/Tunis',
    'Africa/Windhoek',
    'America/Adak',
    'America/Anchorage',
    'America/Araguaina',
    'America/Argentina/Buenos_Aires',
    'America/Argentina/Catamarca',
    'America/Argentina/Cordoba',
    'America/Argentina/Jujuy',
    'America/Argentina/La_Rioja',
    'America/Argentina/Mendoza',
    'America/Argentina/Rio_Gallegos',
    'America/Argentina/Salta',
    'America/Argentina/San_Juan',
    'America/Argentina/San_Luis',
    'America/Argentina/Tucuman',
    'America/Argentina/Ushuaia',
    'America/Asuncion',
    'America/Bahia',
    'America/Bahia_Banderas',
    'America/Barbados',
    'America/Belem',
    'America/Belize',
    'America/Boa_Vista',
    'America/Bogota',
    'America/Boise',
    'America/Cambridge_Bay',
    'America/Campo_Grande',
    'America/Cancun',
    'America/Caracas',
    'America/Cayenne',
    'America/Chicago',
    'America/Chihuahua',
    'America/Ciudad_Juarez',
    'America/Costa_Rica',
    'America/Coyhaique',
    'America/Cuiaba',
    'America/Danmarkshavn',
    'America/Dawson',
    'America/Dawson_Creek',
    'America/Denver',
    'America/Detroit',
    'America/Edmonton',
    'America/Eirunepe',
    'America/El_Salvador',
    'America/Fort_Nelson',
    'America/Fortaleza',
    'America/Glace_Bay',
    'America/Goose_Bay',
    'America/Grand_Turk',
    'America/Guatemala',
    'America/Guayaquil',
    'America/Guyana',
    'America/Halifax',
    'America/Havana',
    'America/Hermosillo',
    'America/Indiana/Indianapolis',
    'America/Indiana/Knox',
    'America/Indiana/Marengo',
    'America/Indiana/Petersburg',
    'America/Indiana/Tell_City',
    'America/Indiana/Vevay',
    'America/Indiana/Vincennes',
    'America/Indiana/Winamac',
    'America/Inuvik',
    'America/Iqaluit',
    'America/Jamaica',
    'America/Juneau',
    'America/Kentucky/Louisville',
    'America/Kentucky/Monticello',
    'America/La_Paz',
    'America/Lima',
    'America/Los_Angeles',
    'America/Maceio',
    'America/Managua',
    'America/Manaus',
    'America/Martinique',
    'America/Matamoros',
    'America/Mazatlan',
    'America/Menominee',
    'America/Merida',
    'America/Metlakatla',
    'America/Mexico_City',
    'America/Miquelon',
    'America/Moncton',
    'America/Monterrey',
    'America/Montevideo',
    'America/New_York',
    'America/Nome',
    'America/Noronha',
    'America/North_Dakota/Beulah',
    'America/North_Dakota/Center',
    'America/North_Dakota/New_Salem',
    'America/Nuuk',
    'America/Ojinaga',
    'America/Panama',
    'America/Paramaribo',
    'America/Phoenix',
    'America/Port-au-Prince',
    'America/Porto_Velho',
    'America/Puerto_Rico',
    'America/Punta_Arenas',
    'America/Rankin_Inlet',
    'America/Recife',
    'America/Regina',
    'America/Resolute',
    'America/Rio_Branco',
    'America/Santarem',
    'America/Santiago',
    'America/Santo_Domingo',
    'America/Sao_Paulo',
    'America/Scoresbysund',
    'America/Sitka',
    'America/St_Johns',
    'America/Swift_Current',
    'America/Tegucigalpa',
    'America/Thule',
    'America/Tijuana',
    'America/Toronto',
    'America/Vancouver',
    'America/Whitehorse',
    'America/Winnipeg',
    'America/Yakutat',
    'Antarctica/Casey',
    'Antarctica/Davis',
    'Antarctica/Macquarie',
    'Antarctica/Mawson',
    'Antarctica/Palmer',
    'Antarctica/Rothera',
    'Antarctica/Troll',
    'Antarctica/Vostok',
    'Asia/Almaty',
    'Asia/Amman',
    'Asia/Anadyr',
    'Asia/Aqtau',
    'Asia/Aqtobe',
    'Asia/Ashgabat',
    'Asia/Atyrau',
    'Asia/Baghdad',
    'Asia/Baku',
    'Asia/Bangkok',
    'Asia/Barnaul',
    'Asia/Beirut',
    'Asia/Bishkek',
    'Asia/Chita',
    'Asia/Colombo',
    'Asia/Damascus',
    'Asia/Dhaka',
    'Asia/Dili',
    'Asia/Dubai',
    'Asia/Dushanbe',
    'Asia/Famagusta',
    'Asia/Gaza',
    'Asia/Hebron',
    'Asia/Ho_Chi_Minh',
    'Asia/Hong_Kong',
    'Asia/Hovd',
    'Asia/Irkutsk',
    'Asia/Jakarta',
    'Asia/Jayapura',
    'Asia/Jerusalem',
    'Asia/Kabul',
    'Asia/Kamchatka',
    'Asia/Karachi',
    'Asia/Kathmandu',
    'Asia/Khandyga',
    'Asia/Kolkata',
    'Asia/Krasnoyarsk',
    'Asia/Kuching',
    'Asia/Macau',
    'Asia/Magadan',
    'Asia/Makassar',
    'Asia/Manila',
    'Asia/Nicosia',
    'Asia/Novokuznetsk',
    'Asia/Novosibirsk',
    'Asia/Omsk',
    'Asia/Oral',
    'Asia/Pontianak',
    'Asia/Pyongyang',
    'Asia/Qatar',
    'Asia/Qostanay',
    'Asia/Qyzylorda',
    'Asia/Riyadh',
    'Asia/Sakhalin',
    'Asia/Samarkand',
    'Asia/Seoul',
    'Asia/Shanghai',
    'Asia/Singapore',
    'Asia/Srednekolymsk',
    'Asia/Taipei',
    'Asia/Tashkent',
    'Asia/Tbilisi',
    'Asia/Tehran',
    'Asia/Thimphu',
    'Asia/Tokyo',
    'Asia/Tomsk',
    'Asia/Ulaanbaatar',
    'Asia/Urumqi',
    'Asia/Ust-Nera',
    'Asia/Vladivostok',
    'Asia/Yakutsk',
    'Asia/Yangon',
    'Asia/Yekaterinburg',
    'Asia/Yerevan',
    'Atlantic/Azores',
    'Atlantic/Bermuda',
    'Atlantic/Canary',
    'Atlantic/Cape_Verde',
    'Atlantic/Faroe',
    'Atlantic/Madeira',
    'Atlantic/South_Georgia',
    'Atlantic/Stanley',
    'Australia/Adelaide',
    'Australia/Brisbane',
    'Australia/Broken_Hill',
    'Australia/Darwin',
    'Australia/Eucla',
    'Australia/Hobart',
    'Australia/Lindeman',
    'Australia/Lord_Howe',
    'Australia/Melbourne',
    'Australia/Perth',
    'Australia/Sydney',
    'Etc/GMT',
    'Etc/GMT+1',
    'Etc/GMT+10',
    'Etc/GMT+11',
    'Etc/GMT+12',
    'Etc/GMT+2',
    'Etc/GMT+3',
    'Etc/GMT+4',
    'Etc/GMT+5',
    'Etc/GMT+6',
    'Etc/GMT+7',
    'Etc/GMT+8',
    'Etc/GMT+9',
    'Etc/GMT-1',
    'Etc/GMT-10',
    'Etc/GMT-11',
    'Etc/GMT-12',
    'Etc/GMT-13',
    'Etc/GMT-14',
    'Etc/GMT-2',
    'Etc/GMT-3',
    'Etc/GMT-4',
    'Etc/GMT-5',
    'Etc/GMT-6',
    'Etc/GMT-7',
    'Etc/GMT-8',
    'Etc/GMT-9',
    'Etc/UTC',
    'Europe/Andorra',
    'Europe/Astrakhan',
    'Europe/Athens',
    'Europe/Belgrade',
    'Europe/Berlin',
    'Europe/Brussels',
    'Europe/Bucharest',
    'Europe/Budapest',
    'Europe/Chisinau',
    'Europe/Dublin',
    'Europe/Gibraltar',
    'Europe/Helsinki',
    'Europe/Istanbul',
    'Europe/Kaliningrad',
    'Europe/Kirov',
    'Europe/Kyiv',
    'Europe/Lisbon',
    'Europe/London',
    'Europe/Madrid',
    'Europe/Malta',
    'Europe/Minsk',
    'Europe/Moscow',
    'Europe/Paris',
    'Europe/Prague',
    'Europe/Riga',
    'Europe/Rome',
    'Europe/Samara',
    'Europe/Saratov',
    'Europe/Simferopol',
    'Europe/Sofia',
    'Europe/Tallinn',
    'Europe/Tirane',
    'Europe/Ulyanovsk',
    'Europe/Vienna',
    'Europe/Vilnius',
    'Europe/Volgograd',
    'Europe/Warsaw',
    'Europe/Zurich',
    'Factory',
    'Indian/Chagos',
    'Indian/Maldives',
    'Indian/Mauritius',
    'Pacific/Apia',
    'Pacific/Auckland',
    'Pacific/Bougainville',
    'Pacific/Chatham',
    'Pacific/Easter',
    'Pacific/Efate',
    'Pacific/Fakaofo',
    'Pacific/Fiji',
    'Pacific/Galapagos',
    'Pacific/Gambier',
    'Pacific/Guadalcanal',
    'Pacific/Guam',
    'Pacific/Honolulu',
    'Pacific/Kanton',
    'Pacific/Kiritimati',
    'Pacific/Kosrae',
    'Pacific/Kwajalein',
    'Pacific/Marquesas',
    'Pacific/Nauru',
    'Pacific/Niue',
    'Pacific/Norfolk',
    'Pacific/Noumea',
    'Pacific/Pago_Pago',
    'Pacific/Palau',
    'Pacific/Pitcairn',
    'Pacific/Port_Moresby',
    'Pacific/Rarotonga',
    'Pacific/Tahiti',
    'Pacific/Tarawa',
    'Pacific/Tongatapu',
    'UTC'
  ]::text[])
$$;

create function sync_private.valid_civil_date(value text)
returns boolean language plpgsql immutable set search_path = '' as $$
declare day date;
begin
  if value is null or length(value)<>10 or value !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    or substring(value,1,4)='0000' then return false; end if;
  day := make_date(substring(value,1,4)::integer,substring(value,6,2)::integer,substring(value,9,2)::integer);
  return true;
exception when datetime_field_overflow then return false;
end
$$;

create function sync_private.valid_due(value jsonb)
returns boolean language plpgsql stable set search_path = '' as $$
declare
  wall_text text; zone_name text; millis bigint;
  wall timestamp; instant timestamptz; actual timestamp;
  before_offset interval; after_offset interval;
begin
  if jsonb_typeof(value) is distinct from 'object' then return false; end if;
  case value->>'kind'
  when 'none' then return sync_private.exact_keys(value,array['kind']);
  when 'date' then
    return sync_private.exact_keys(value,array['kind','date'])
      and jsonb_typeof(value->'date')='string'
      and sync_private.valid_civil_date(value->>'date');
  when 'timed' then
    if not sync_private.exact_keys(value,array['kind','instant','zone','wall_time'])
      or jsonb_typeof(value->'instant') is distinct from 'number'
      or not sync_private.exact_json(value->'instant')
      or jsonb_typeof(value->'zone') is distinct from 'string'
      or jsonb_typeof(value->'wall_time') is distinct from 'string' then return false; end if;
    wall_text := value->>'wall_time'; zone_name := value->>'zone';
    if length(wall_text)<>16 or wall_text !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T([01][0-9]|2[0-3]):[0-5][0-9]$'
      or not sync_private.valid_civil_date(substring(wall_text,1,10))
      or not sync_private.due_zone_supported(zone_name) then return false; end if;
    millis := (value->>'instant')::bigint;
    -- A year 1..9999 wall time cannot resolve beyond these generous UTC bounds.
    -- Bound before PostgreSQL timestamp arithmetic (Dart's range is wider).
    if millis < -62167392000000 or millis > 253402473600000 then return false; end if;
    wall := make_timestamp(substring(wall_text,1,4)::integer,substring(wall_text,6,2)::integer,
      substring(wall_text,9,2)::integer,substring(wall_text,12,2)::integer,substring(wall_text,15,2)::integer,0);
    instant := timestamptz '1970-01-01 00:00:00+00'
      + (millis/1000)*interval '1 second' + (millis%1000)*interval '1 millisecond';
    actual := timezone(zone_name,instant);
    -- Either fold occurrence is valid. No clock or device zone orders it.
    if actual=wall then return true; end if;
    -- Match TimePolicy's gap rule, including non-hour and full-day gaps.
    before_offset := timezone(zone_name,instant-interval '48 hours') - timezone('UTC',instant-interval '48 hours');
    after_offset := timezone(zone_name,instant+interval '48 hours') - timezone('UTC',instant+interval '48 hours');
    return after_offset>before_offset and actual-wall=after_offset-before_offset
      and timezone('UTC',instant)=wall-before_offset;
  else return false;
  end case;
end
$$;

revoke all on function sync_private.due_zone_supported(text),
  sync_private.valid_civil_date(text), sync_private.valid_due(jsonb)
  from public, anon, authenticated, service_role;
grant execute on function sync_private.due_zone_supported(text),
  sync_private.valid_civil_date(text), sync_private.valid_due(jsonb) to dourstuff_rpc;

create or replace function public.sync_apply(request jsonb)
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
    if coalesce(op->>'command','') not in ('task.create','task.edit','task.status') or op ? 'restore'
      or (jsonb_typeof(op->'patches')='object' and exists
          (select 1 from jsonb_object_keys(op->'patches') as g where g not in ('title','priority','status_group','existence','description','estimate_minutes','due')))
      or (op->>'command'<>'task.create' and op->'patches' ? 'existence')
      or (op ? 'dependencies' and op->'dependencies' <> '[]') then
      return sync_private.failure('unsupportedProtocol');
    end if;
    if not sync_private.valid_task_envelope(op) or octet_length(sync_private.compact_json(op)) > 65536 then
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
    select * into shadow from sync_private.task_shadow where owner_id=caller and task_id=task;
    identity_exists := found;
    creating := op->>'command'='task.create';
    old_status := shadow.fields->'status_group';
    rejection := null;
    if creating then
      -- Core groups are mandatory; description, estimate and due are optional.
      -- Every supplied create group has an absent base and commits together.
      if not (op->'patches' ?& array['existence','title','priority','status_group'])
        or op->'patches'->'existence'->'value' is distinct from 'true'::jsonb
        or exists(select 1 from jsonb_each(op->'patches') as p(k,v) where v->'base'->>'kind'<>'absent') then
        rejection := 'invalid_create';
      end if;
      if not identity_exists then shadow.fields := '{}'; end if;
    elsif not identity_exists then rejection := 'entity_missing';
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
    next_revision := account.revision+1;
    outcomes := '[]'; candidates := '[]'; changes := '[]'; applied_count := 0; held_count := 0; changed := false;
    for item in select k,v from jsonb_each(op->'patches') as e(k,v) order by k loop
      base := item.v->'base'; current_field := shadow.fields->item.k;
      accepted := null; decision := null;
      if rejection is not null or shadow.fields->'existence'->'value'='false'::jsonb then
        decision := 'recovery';
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
      if creating then
        insert into sync_private.task_shadow(owner_id,task_id,fields) values(caller,task,shadow.fields);
      else
        update sync_private.task_shadow set fields=shadow.fields where owner_id=caller and task_id=task;
      end if;
      -- A fresh command may accept a new revision without a status transition.
      if shadow.fields->'status_group'->'value' is distinct from old_status->'value' then
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
