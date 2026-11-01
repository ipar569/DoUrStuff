"""90-day payload lifecycle on real local PostgreSQL/HTTP, synthetic owners only."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import time

from test_backend_foundation import Backend, literal, require, sql
from test_backend_apply import predecessor, uid
from test_backend_resolution import seed, request, resolve, candidates, rows, state, begin, page, pull
from test_backend_retention import age as age_logs, prune as prune_logs, apply, wait_for_sleep
from test_backend_snapshots import begin as legacy_begin, page as legacy_page

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20261031074053_resolved_content_retention.sql'


def age(f):
    sql(' '.join(f"update sync_private.{table} set recorded_at=clock_timestamp()-interval '2161 hours' "
                 f"where owner_id='{f.owner}';" for table in ('recovery_resolutions', 'resolution_requests')))


def prune(f, size=200):
    return json.loads(sql(f"select sync_private.prune_resolved_content('{f.owner}',{size});"))


def closed(backend, epoch, value=None):
    f, ops = seed(backend, epoch, False)
    q = request(f, candidates(f)[0], 4, value)
    reply = resolve(f, q)
    require(reply['status'] == 'success', 'Resolution seed')
    return f, ops, q, reply


def all_state(f):
    return state(f), rows(f, 'change_log'), rows(f, 'snapshot_pages'), rows(f, 'snapshots')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--supabase', default='supabase')
    parser.add_argument('--wire-output', type=Path)
    parser.add_argument('--candidate', action='store_true')
    args = parser.parse_args()
    subprocess.run([sys.executable, str(ROOT / 'tool/local_backend.py')], check=True)
    backend = Backend(args.supabase)
    epoch = sql('select server_epoch from sync_private.backend_state;')
    passed = 0

    def check(label):
        nonlocal passed
        passed += 1
        print('PASS: ' + label, flush=True)

    try:
        if args.candidate:
            f, _, q, reply = closed(backend, epoch, 'chosen')
            age(f); capture = begin(f); frozen = page(f, capture); before = all_state(f)
            result = sql('begin;\n' + MIGRATION.read_text(encoding='utf-8') +
                         f"select sync_private.prune_resolved_content('{f.owner}',1); "
                         f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                         f"select public.sync_resolve_recovery({literal(json.dumps(q))}::jsonb); rollback;")
            lines = result.splitlines()
            require(json.loads(lines[0]) == dict(candidates_compacted=1, requests_compacted=1, revision=5)
                    and json.loads(lines[2]) == reply, 'Upgrade backfill and compacted retry')
            require(all_state(f) == before and page(f, capture) == frozen, 'Exact migration rollback')
            check('retained-data forward migration, payload compaction and retry roll back exactly')
            return

        f, _, _, _ = closed(backend, epoch)
        source = sql("select pg_get_functiondef('sync_private.prune_resolved_content(uuid,integer)'::regprocedure);")
        fixed = source.replace('clock_timestamp()', "'2026-10-31T00:00:00Z'::timestamptz") + ';\n'
        before = all_state(f)
        for zone in ('UTC', 'Pacific/Auckland', 'America/New_York'):
            for offset, expected in ((-1, 1), (0, 1), (1, 0)):
                updates = ' '.join(f"update sync_private.{table} set recorded_at='2026-10-31T00:00:00Z'::timestamptz "
                                  f"-interval '2160 hours'+interval '{offset} microseconds' where owner_id='{f.owner}';"
                                  for table in ('recovery_resolutions', 'resolution_requests'))
                result = json.loads(sql(f"begin; set local timezone='{zone}';\n" + fixed + updates +
                                        f"select sync_private.prune_resolved_content('{f.owner}',200); rollback;"))
                require(result['candidates_compacted'] == expected and result['requests_compacted'] == expected,
                        'Exact elapsed 90-day cutoff')
        require(all_state(f) == before and prune(f)['candidates_compacted'] == 0, 'Fresh originals preserved')
        check('minus/equal/plus microsecond elapsed cutoff in UTC and two DST timezones')

        f, ops = seed(backend, epoch); cs = candidates(f)
        q = request(f, cs[0], 6, 'chosen', [(c, 'keepHeld') for c in cs[1:]])
        reply = resolve(f, q); age(f)
        old = begin(f); frozen = page(f, old)
        legacy = legacy_begin(f); legacy_frozen = legacy_page(f, legacy)
        untouched = [rows(f, table) for table in ('operation_receipts', 'device_state', 'task_status_history',
                                                'task_shadow', 'recovery_resolutions')]
        old_logs = json.loads(rows(f, 'change_log'))
        require(prune(f) == dict(candidates_compacted=1, requests_compacted=1, revision=7), 'One cleanup revision')
        current = begin(f); fresh = page(f, current)
        require(current['token'] != old['token'] and fresh['recovery'] == sorted(cs[1:], key=lambda c: c['id']) and
                fresh['resolutions'] == frozen['resolutions'], 'New capture retains unresolved originals and permanent closures')
        require(page(f, old) == frozen and legacy_page(f, legacy) == legacy_frozen, 'Both fixed capture versions survive')
        groups = pull(f, old['at']['revision'])['result']['groups']
        require(len(groups) == 1 and groups[0]['revision'] == 7 and
                all(groups[0][key] == [] for key in ('records', 'recovery', 'history', 'resolutions')), 'Whole empty cleanup revision')
        require(untouched == [rows(f, table) for table in ('operation_receipts', 'device_state', 'task_status_history',
                                                          'task_shadow', 'recovery_resolutions')]
                and all(row in json.loads(rows(f, 'change_log')) for row in old_logs), 'Independent retention streams unchanged')
        before = all_state(f)
        require(prune(f) == dict(candidates_compacted=0, requests_compacted=0, revision=7) and
                all_state(f) == before and resolve(f, q) == reply, 'Idempotent pass and immutable decision replay')
        check('frozen and fresh snapshots, unresolved originals, closure facts, pull continuity and independent policies')

        # A resolved intermediate still connects an unresolved ancestor to a held
        # grandchild. Pruning must not let a stale incomplete preview resolve it.
        f, ops = seed(backend, epoch); cs = candidates(f)
        middle = request(f, cs[1], 6, held=[(cs[2], 'keepHeld')])
        require(resolve(f, middle)['status'] == 'success', 'Intermediate closure')
        age(f); prune(f)
        before = all_state(f)
        incomplete = request(f, cs[0], 7)
        require(resolve(f, incomplete)['code'] == 'recoveryChanged' and all_state(f) == before,
                'Compacted intermediate cannot hide held descendant')
        late = f.op(7, 'late held', predecessor(ops[3], 'held'))
        require(f.apply(late)['result']['results'][0]['disposition'] == 'held', 'Late child of compacted intermediate')
        late_candidate = next(c for c in candidates(f) if c and c['operation'] == late)
        complete = request(f, cs[0], 8, held=[(cs[2], 'discard'), (late_candidate, 'discard')])
        require(resolve(f, complete)['status'] == 'success', 'Exact transitive choice through permanent graph')
        require(json.loads(rows(f, 'recovery_candidates'))[0] is not None, 'Identity rows remain')
        check('unresolved transitive held graph survives a compacted resolved intermediate')

        for value in (None, 'replacement'):
            f, ops, q, reply = closed(backend, epoch, value); age(f); prune(f)
            age_logs(f); prune_logs(f)
            q['cursor']['revision'] = int(sql(f"select revision from sync_private.account_state where owner_id='{f.owner}';"))
            before = all_state(f)
            require(resolve(f, q) == reply, 'Exact decision replay after content/log/receipt expiry')
            require(apply(f, ops[2])['result']['results'][0]['kind'] == 'already_processed', 'Original operation never reapplied')
            for key in ('observed_fields', 'held_choices', 'operation_id', 'sequence', 'device_epoch'):
                bad = deepcopy(q)
                if key == 'observed_fields': bad[key]['title']['value'] = 'altered preview'
                elif key == 'held_choices': bad[key] = [dict(id=uid(), revision=1, choice='discard')]
                elif key == 'sequence': bad[key] = 5
                else: bad[key] = uid()
                # Replacement shape is validated only after the permanent retry check.
                require(resolve(f, bad)['code'] == 'payloadMismatch', 'Hash binds full original decision')
            bad = deepcopy(ops[2]); bad['provenance'] = {'changed': True}
            require(apply(f, bad)['code'] == 'payloadMismatch' and all_state(f) == before, 'Original operation proof survives')
            changed_epoch = uid(); refreshed = deepcopy(q); refreshed['cursor']['server_epoch'] = changed_epoch
            result = sql(f"begin; update sync_private.backend_state set server_epoch='{changed_epoch}'; "
                         f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                         f"select public.sync_resolve_recovery({literal(json.dumps(refreshed))}::jsonb); rollback;")
            actual = json.loads(result.splitlines()[1]); expected = deepcopy(reply)
            expected['result']['cursor']['server_epoch'] = changed_epoch
            require(actual == expected and all_state(f) == before, 'Compacted reply uses current epoch')
            backend.wire.append(dict(rpc='resolve_recovery', request=refreshed, reply=actual))
        check('discard/replacement retries, altered identity/payload denial and current epochs beyond all payload expiry')

        # Real multipage capture and independently bounded candidate/request work.
        f, _ = seed(backend, epoch, False)
        operations = [f.op(n, 'candidate ' + str(n)) for n in range(4, 208)]
        for start in range(0, len(operations), 32): f.apply(*operations[start:start + 32])
        cs = candidates(f)
        for index, candidate in enumerate(cs):
            require(resolve(f, request(f, candidate, 208 + index))['status'] == 'success', 'Bulk explicit closure')
        age(f); capture = begin(f)
        frozen = [page(f, capture, n) for n in range(capture['page_count'])]
        require(len(cs) == 205 and len(frozen) > 1, '205 candidates across actual pages')
        for count in (100, 100, 5):
            counts = prune(f, 100)
            require(counts['candidates_compacted'] == count and counts['requests_compacted'] == count, 'Bounded batch')
        require([page(f, capture, n) for n in reversed(range(capture['page_count']))] == list(reversed(frozen)), 'Resumed pages unchanged')
        current = begin(f); fresh = [page(f, current, n) for n in range(current['page_count'])]
        require(not any(p['recovery'] for p in fresh) and sum(len(p['resolutions']) for p in fresh) == 205, 'All compact closures downloadable')
        require(len(pull(f, capture['at']['revision'])['result']['groups']) == 3, 'One whole revision per nonempty batch')
        check('205 originals and decisions, bounded repeated batches and immutable multi-page resumes')

        # Corrupt proof and injected late write failures must restore every row.
        f, _, _, _ = closed(backend, epoch); age(f)
        for table, column, predicate in (
                ('operation_identities', 'payload_hash', 'sequence=3'),
                ('resolution_requests', 'request_hash', 'sequence=4')):
            before = all_state(f)
            try:
                sql(f"begin; update sync_private.{table} set {column}=decode(repeat('00',32),'hex') "
                    f"where owner_id='{f.owner}' and {predicate}; select sync_private.prune_resolved_content('{f.owner}',200); commit;")
                raise AssertionError('Corrupt proof accepted')
            except RuntimeError:
                pass
            require(all_state(f) == before, 'Proof failure rolls back all state')
        for size in ('null', '0', '-1', '1001'):
            try:
                sql(f"select sync_private.prune_resolved_content('{f.owner}',{size});")
                raise AssertionError('Invalid bound accepted')
            except RuntimeError:
                pass
        before = all_state(f)
        try:
            sql("begin; create function sync_private.test_resolved_fail() returns trigger language plpgsql as $$ begin "
                "raise exception 'Injected failure'; end $$; create trigger test_resolved_fail before insert "
                "on sync_private.change_log for each row execute function sync_private.test_resolved_fail(); "
                f"select sync_private.prune_resolved_content('{f.owner}',200); commit;")
            raise AssertionError('Fault did not trigger')
        except RuntimeError:
            pass
        require(all_state(f) == before, 'Late log failure rolls back content, requests and revision')
        check('invalid bounds, corrupt identity/request proof and injected log failure roll back complete batch')

        f, _, q, reply = closed(backend, epoch); age(f); label = uid()
        with ThreadPoolExecutor(max_workers=5) as pool:
            first = pool.submit(sql, f"begin; set local application_name='{label}'; "
                                f"select sync_private.prune_resolved_content('{f.owner}',200); select pg_sleep(1.5); commit;")
            wait_for_sleep(label)
            tasks = [pool.submit(pull, f), pool.submit(begin, f), pool.submit(prune, f), pool.submit(resolve, f, q)]
            time.sleep(.1)
            require(all(not task.done() for task in tasks), 'All readers/writers wait for account lock')
            first.result(); replies = [task.result() for task in tasks]
        require(replies[2]['candidates_compacted'] == 0 and replies[3] == reply and
                page(f, replies[1])['recovery'] == [], 'Concurrent committed state')
        check('prune-first pull/snapshot/decision retry/second-pruner serialize under account lock')

        f, _, _, _ = closed(backend, epoch)
        sql(' '.join(f"update sync_private.{table} set recorded_at=clock_timestamp()-interval '2160 hours'+interval '1 second' "
                     f"where owner_id='{f.owner}';" for table in ('recovery_resolutions', 'resolution_requests')))
        label = uid()
        with ThreadPoolExecutor(max_workers=2) as pool:
            first = pool.submit(sql, f"begin; set local application_name='{label}'; "
                                f"select revision from sync_private.account_state where owner_id='{f.owner}' for share; "
                                "select pg_sleep(1.5); commit;")
            wait_for_sleep(label); pending = pool.submit(prune, f)
            first.result(); result = pending.result()
        require(result['candidates_compacted'] == 1 and result['requests_compacted'] == 1, 'Time sampled after lock wait')
        check('reader-first expiry uses fresh server time after account lock acquisition')

        x, _, _, _ = closed(backend, epoch); y, _, _, _ = closed(backend, epoch)
        age(x); age(y); before_y = all_state(y); prune(x)
        require(all_state(y) == before_y, 'Per-owner cleanup isolation')
        for role in ('anon', 'authenticated', 'service_role', 'dourstuff_rpc'):
            require(sql(f"select has_function_privilege('{role}','sync_private.prune_resolved_content(uuid,integer)','EXECUTE');") == 'f', 'No maintenance execution grant')
        for table in ('recovery_candidates', 'resolution_requests', 'recovery_resolutions'):
            require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{y.owner}',true) is not null; "
                        f"select count(*) from sync_private.{table} where owner_id='{x.owner}'; rollback;").splitlines() == ['t', '0'], 'Forced RLS isolation')
            for token in (None, x.token, y.token):
                code, _ = backend.request('GET', '/rest/v1/' + table, token)
                require(code in (401, 403, 404), 'Private table REST inaccessible')
        check('X/Y ownership isolation, forced RLS and private operator-only maintenance')
        print(f'{passed} resolved-content integration groups passed.', flush=True)
    finally:
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, ensure_ascii=False), encoding='utf-8')
        backend.cleanup()


if __name__ == '__main__':
    main()
