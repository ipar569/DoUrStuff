"""Pinned native Dart/PostgreSQL tag normalization, without enabling commands.

Use --candidate for a rollback-only rehearsal before applying the new migration.
Only the existing guarded local stack is accepted. No user content is printed.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

from test_backend_foundation import literal, require, sql

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20261024083944_tag_name_normalization.sql'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--fixtures', type=Path, required=True)
    parser.add_argument('--candidate', action='store_true')
    args = parser.parse_args()
    subprocess.run([sys.executable, str(Path(__file__).with_name('local_backend.py'))], check=True)
    profile = json.loads((ROOT / 'test/fixtures/tag-normalization-v1.json').read_text(encoding='utf-8'))
    cases = json.loads(args.fixtures.read_text(encoding='utf-8'))
    require(len(cases) == 1399, 'Full scalar, whitespace and context fixture count')
    validations = json.loads((ROOT / 'test/fixtures/tag-name-validation.json').read_text(encoding='utf-8'))
    for name, valid in [('a' * 80, True), ('a' * 81, False), ('𐐀' * 40, True), ('𐐀' * 41, False)]:
        validations.append({'value': {'name': name, 'normalized_name': name.replace('𐐀', '𐐨')}, 'valid': valid})
    before = sql('select server_epoch from sync_private.backend_state;')
    source = 'begin;\n' + (MIGRATION.read_text(encoding='utf-8') if args.candidate else '')
    # Run as the real invoker role. Ambient database collation cannot define keys.
    source += "\nset local role dourstuff_rpc;\n"
    for start in range(0, len(cases), 16):
        batch = literal(json.dumps(cases[start:start + 16]))
        source += ("select bool_and(sync_private.normalized_tag_name_v1(v->>'input') collate \"C\" "
                   "= (v->>'normalized') collate \"C\") from jsonb_array_elements(" + batch + "::jsonb) e(v);\n")
    source += ("select bool_and(sync_private.clean_tag_name_v1(chr(cp)||'A'||chr(cp)||'B'||chr(cp)) collate \"C\" "
               "= (case when cp=133 then 'A'||chr(133)||'B' else 'A B' end) collate \"C\") "
               "from unnest(array[" + ','.join(map(str, profile['trim'])) + "]) e(cp);\n")
    source += ("select bool_and(sync_private.valid_tag_name_v1(v->'value') = (v->>'valid')::boolean) "
               "from jsonb_array_elements(" + literal(json.dumps(validations)) + "::jsonb) e(v);\n")
    source += "select sync_private.normalized_tag_name_v1(null) is null and not sync_private.valid_tag_name_v1(null);\n"
    source += "reset role;\n"
    for function, signature in [('clean_tag_name_v1', 'text'), ('normalized_tag_name_v1', 'text'), ('valid_tag_name_v1', 'jsonb')]:
        identity = literal('sync_private.' + function + '(' + signature + ')')
        source += ("select not has_function_privilege('anon'," + identity + ",'EXECUTE') "
                   "and not has_function_privilege('authenticated'," + identity + ",'EXECUTE') "
                   "and not has_function_privilege('service_role'," + identity + ",'EXECUTE') "
                   "and has_function_privilege('dourstuff_rpc'," + identity + ",'EXECUTE');\n")
        source += ("select not prosecdef and provolatile='i' and proconfig=array['search_path=\"\"'] "
                   "from pg_proc where oid=" + identity + "::regprocedure;\n")
    source += 'rollback;'
    results = sql(source).splitlines()
    require(len(results) == (len(cases) + 15) // 16 + 9 and all(r == 't' for r in results),
            'Full normalization parity, UTF-16/name-group validation and restricted invoker functions')
    require(sql('select server_epoch from sync_private.backend_state;') == before, 'Rehearsal preserves backend epoch')
    print(f'PASS: {len(cases)} normalization cases (all 1,112,063 PostgreSQL-representable scalars plus context)')
    print(f'PASS: {len(validations)} shared/boundary name validation cases and 26 whitespace boundaries')
    print('PASS: null handling, fixed search paths, invoker execution and restricted grants')
    print('PASS: rollback-only execution preserves the existing backend epoch')


if __name__ == '__main__':
    main()
