-- regexp_split_to_table('', '') emits one empty row. Explicitly require a
-- nonempty display name before counting UTF-16 units. Preserve applied 017.
create or replace function sync_private.valid_view_name(value jsonb)
returns boolean language sql immutable set search_path = '' as $$
  select coalesce(jsonb_typeof(value)='string' and length(value #>> '{}')>0
    and value #>> '{}' = sync_private.clean_tag_name_v1(value #>> '{}')
    and (select coalesce(sum(case when ascii(c)>65535 then 2 else 1 end),0)
      from regexp_split_to_table(value #>> '{}','') as t(c)) between 1 and 80, false)
$$;
