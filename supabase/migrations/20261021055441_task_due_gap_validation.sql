-- Forward fix: never shift an ordinary wall time after a DST gap.
-- Migration 007 is already applied and remains unchanged.
create or replace function sync_private.valid_due(value jsonb)
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
    -- A real wall occurrence wins over any gap-shift candidate, matching
    -- TimePolicy.resolve's exact-before-shifted rule. PostgreSQL chooses an
    -- exact fold occurrence here; a true gap cannot round-trip to the wall.
    if timezone(zone_name,timezone(zone_name,wall))=wall then return false; end if;
    -- Match TimePolicy's gap rule, including non-hour and full-day gaps.
    before_offset := timezone(zone_name,instant-interval '48 hours') - timezone('UTC',instant-interval '48 hours');
    after_offset := timezone(zone_name,instant+interval '48 hours') - timezone('UTC',instant+interval '48 hours');
    return after_offset>before_offset and actual-wall=after_offset-before_offset
      and timezone('UTC',instant)=wall-before_offset;
  else return false;
  end case;
end
$$;

