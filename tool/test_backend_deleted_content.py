"""Bounded content retention on real local PostgreSQL/HTTP; synthetic accounts only."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import time

from test_backend_foundation import Backend, literal, require, sql
from test_backend_apply import observed, predecessor, uid
from test_backend_task_create import TaskFixture
from test_backend_task_delete import deletion
from test_backend_task_restore import restore
from test_backend_milestone_create import milestone
from test_backend_milestone_commands import remove as delete_milestone
from test_backend_tag_commands import tag, remove as delete_tag
from test_backend_saved_views import view, preference, delete as delete_view
from test_backend_memberships import membership
from test_backend_history import begin, page, pull
from test_backend_snapshots import begin as legacy_begin, page as legacy_page
from test_backend_retention import durable, wait_for_sleep

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20261029002956_deleted_content_retention.sql'


def prune(f, size=200):
    return json.loads(sql(f"select sync_private.prune_deleted_content('{f.owner}',{size});"))


def age(f, hours=721):
    sql(' '.join(f"update sync_private.{kind}_deletions set deleted_at=clock_timestamp()-interval '{hours} hours' "
                 f"where owner_id='{f.owner}';" for kind in ('task', 'tag', 'view', 'milestone')))


def state(f):
    return f.state(), durable(f)


def gone(backend, epoch):
    f = TaskFixture(backend, epoch)
    remove = deletion(f)
    f.apply(f.create(), remove)
    return f, remove


def rows(f, table):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),'[]') "
                         f"from sync_private.{table} t where owner_id='{f.owner}';"))


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
            f, _ = gone(backend, epoch); age(f)
            capture = begin(f); frozen = page(f, capture); before = state(f)
            result = json.loads(sql('begin;\n' + MIGRATION.read_text(encoding='utf-8') +
                                    f"select sync_private.prune_deleted_content('{f.owner}',1); rollback;"))
            require(result == dict(shadows_compacted=1, payloads_compacted=1, revision=3), 'Candidate cleanup')
            require(state(f) == before and page(f, capture) == frozen, 'Migration and cleanup rollback preserve data')
            check('forward migration and real-owner cleanup rollback preserve exact retained data and capture')
            return

        f, remove = gone(backend, epoch)
        source = sql("select pg_get_functiondef('sync_private.prune_deleted_content(uuid,integer)'::regprocedure);")
        fixed = source.replace('clock_timestamp()', "'2026-10-29T00:00:00Z'::timestamptz") + ';\n'
        before = state(f)
        for zone in ('UTC', 'Pacific/Auckland', 'America/New_York'):
            for offset, expected in ((-1, 1), (0, 1), (1, 0)):
                result = json.loads(sql(f"begin; set local timezone='{zone}';\n" + fixed +
                    f"update sync_private.task_deletions set deleted_at='2026-10-29T00:00:00Z'::timestamptz "
                    f"-interval '720 hours'+interval '{offset} microseconds' where owner_id='{f.owner}'; "
                    f"select sync_private.prune_deleted_content('{f.owner}',200); rollback;"))
                require(result['shadows_compacted'] == expected and result['payloads_compacted'] == expected,
                        'Exact elapsed 720-hour cutoff')
        require(state(f) == before, 'Boundary transactions roll back')
        check('minus/equal/plus microsecond cutoff across UTC and two DST timezones')

        # Restoration before expiry preserves content; every expiry path closes.
        require(prune(f)['shadows_compacted'] == 0, 'Fresh deletion not cleaned')
        require(f.apply(restore(f, remove))['result']['results'][0]['disposition'] == 'applied', 'Recent restore')
        age(f); before = state(f)
        require(prune(f)['shadows_compacted'] == 0 and state(f) == before, 'Old deletion of live entity not purged')
        f, remove = gone(backend, epoch); age(f)
        require(f.apply(restore(f, remove))['result']['results'][0]['rejection_code'] == 'restore_content_expired', 'Expiry before cleanup')
        prune(f)
        sql(f"update sync_private.task_deletions set deleted_at=clock_timestamp() where owner_id='{f.owner}';")
        require(f.apply(restore(f, remove, 4))['result']['results'][0]['rejection_code'] == 'restore_content_expired',
                'Purged content cannot restore even if server time moves backwards')
        check('restore before expiry, live reappearance protection and fail-closed expiry before/after compaction')

        f, remove = gone(backend, epoch)
        late = f.op(3, 'retained original'); held = f.op(4, 'held original', predecessor(late, 'retained original'))
        f.apply(late, held); age(f)
        capture = begin(f); frozen = page(f, capture)
        legacy = legacy_begin(f); legacy_frozen = legacy_page(f, legacy)
        history = rows(f, 'task_status_history'); recovery = rows(f, 'recovery_candidates')
        receipts = rows(f, 'operation_receipts'); waters = rows(f, 'device_state')
        logs = rows(f, 'change_log')
        result = prune(f)
        require(result == dict(shadows_compacted=1, payloads_compacted=1, revision=5), 'One new cleanup revision')
        require(page(f, capture) == frozen and legacy_page(f, legacy) == legacy_frozen, 'Both frozen capture versions preserved')
        current = begin(f); downloaded = page(f, current)
        require(current['token'] != capture['token'] and current['at']['revision'] == 5, 'No stale capture reuse')
        require(downloaded['records'][0]['fields'] == {'existence': {'revision': 2, 'value': False}}, 'Minimal tombstone download')
        require(downloaded['records'][0]['delete_operation_id'] == remove['operation_id'], 'Permanent winning deletion ID')
        continuation = pull(f, capture['at']['revision'])['result']['groups']
        require(len(continuation) == 1 and continuation[0]['records'] == downloaded['records'] and
                continuation[0]['history'] == [] and continuation[0]['recovery'] == [], 'Old snapshot resumes through cleanup')
        require(rows(f, 'task_status_history') == history and rows(f, 'recovery_candidates') == recovery and
                rows(f, 'operation_receipts') == receipts and rows(f, 'device_state') == waters and
                all(row in rows(f, 'change_log') for row in logs), 'Independent retention streams unchanged')
        require(downloaded['history'] == frozen['history'] and downloaded['recovery'] == frozen['recovery'], 'Original candidates/history downloadable')
        before = state(f)
        require(prune(f) == dict(shadows_compacted=0, payloads_compacted=0, revision=5) and state(f) == before, 'Idempotent cleanup')
        check('fixed captures, new revision/reuse, pull continuation and exact history/candidate/watermark preservation')

        f = TaskFixture(backend, epoch)
        ops = []
        for index in range(205):
            task_id = uid(); sequence = index * 2 + 1
            remove = deletion(f, sequence + 1, observed(sequence, True))
            remove['entity']['key'] = [task_id]
            ops.extend((f.create(sequence, task=task_id), remove))
        for start in range(0, len(ops), 32):
            f.apply(*ops[start:start + 32])
        age(f); capture = begin(f)
        frozen = [page(f, capture, n) for n in range(capture['page_count'])]
        require(len(frozen) > 1, 'Real multipage capture')
        for expected in (100, 100, 5):
            require(prune(f, 100)['shadows_compacted'] == expected, 'Bounded multi-page cleanup')
        require([page(f, capture, n) for n in reversed(range(capture['page_count']))] == list(reversed(frozen)),
                'Interrupted reverse reads preserve original pages')
        current = begin(f); cleaned = [page(f, current, n) for n in range(current['page_count'])]
        records = [r for p in cleaned for r in p['records']]
        require(len(records) == 205 and all(set(r['fields']) == {'existence'} for r in records), 'All minimal identities captured')
        require([h for p in cleaned for h in p['history']] == [h for p in frozen for h in p['history']], 'Multipage history unchanged')
        first = pull(f, capture['at']['revision'])['result']
        second = pull(f, first['through']['revision'])['result']
        require(first['has_more'] and not second['has_more'] and
                sum(len(g['records']) for g in first['groups'] + second['groups']) == 205,
                'All cleanup revisions resume over multiple pull pages')
        check('205 deleted entities across bounded batches, frozen reverse-page reads and paginated pull continuation')

        f = TaskFixture(backend, epoch)
        child = milestone(f, 2); label = tag(f, 3); saved = view(f, 5)
        f.apply(f.create(), child, label, membership(f, label, 4), saved,
                preference(f, 6, saved['entity']['key'][0]))
        remove = deletion(f, 10)
        f.apply(delete_milestone(f, child, 7, observed(2, True)), delete_tag(f, label, 8, observed(3, True)),
                delete_view(f, saved, 9, observed(5, True)), remove, restore(f, remove, 11, 10),
                deletion(f, 12, observed(11, True)))
        age(f)
        snapshots = {t: rows(f, t) for t in ('membership_shadow', 'preference_shadow', 'task_status_history', 'device_state')}
        counts = []
        payload_capture = None
        for _ in range(30):
            result = prune(f, 1); counts.append(result)
            require(result['shadows_compacted'] <= 1 and result['payloads_compacted'] <= 1, 'Shared row budgets')
            if not result['shadows_compacted'] and result['payloads_compacted']:
                if payload_capture is None:
                    payload_capture = begin(f)
                else:
                    require(begin(f) == payload_capture, 'Payload-only passes preserve revision and capture reuse')
            if not result['shadows_compacted'] and not result['payloads_compacted']:
                break
        else:
            raise AssertionError('Cleanup failed to finish')
        require(sum(c['shadows_compacted'] for c in counts) == 4, 'Four kinds compacted')
        require(sum(c['payloads_compacted'] for c in counts) == 11, 'All creation/lifecycle/membership/implicit preference payloads compacted')
        for t, old in snapshots.items():
            require(rows(f, t) == old, 'Minimal relations, history and watermarks retained')
        for t in ('task_deletions', 'task_restorations', 'tag_deletions', 'milestone_deletions', 'view_deletions',
                  'membership_changes', 'preference_changes'):
            # Explicit preference.set is live minimal state; its ledger stays.
            for row in rows(f, t):
                if t == 'preference_changes' and row['revision'] == 6:
                    continue
                require(row['operation'] is None, 'Ledger payload scrubbed while row identity retained')
        for kind in ('tag', 'view', 'milestone'):
            require(rows(f, kind + '_shadow')[0]['creation_operation'] is None, 'Creation payload scrubbed')
        page(f, begin(f)); pull(f, 12)
        check('bounded resumable multi-kind cleanup preserves all relationship keys and lifecycle identities')

        f = TaskFixture(backend, epoch); child = milestone(f, 2)
        f.apply(f.create(), child, deletion(f, 3)); age(f)
        prune(f)
        child_row = rows(f, 'milestone_shadow')[0]
        require(set(child_row['fields']) == {'existence', 'parent'} and child_row['fields']['existence']['value'] is True
                and child_row['delete_operation_id'] is None, 'Inherited visibility preserves own lifecycle')
        page(f, begin(f)); pull(f, 3)
        check('expired parent compacts inherited child content without inventing a child deletion')

        # Backfill exact legacy evidence before nulling it, even without receipts.
        f = TaskFixture(backend, epoch); label = tag(f, 2)
        f.apply(f.create(), label, delete_tag(f, label, 3, observed(2, True))); age(f)
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; "
            f"delete from sync_private.operation_identities where owner_id='{f.owner}';")
        prune(f)
        require(len(rows(f, 'operation_identities')) == 2, 'Legacy ledger proofs compacted')
        for original in (label,):
            for mutate in ('sequence', 'payload', 'device'):
                bad = deepcopy(original)
                if mutate == 'sequence': bad['sequence'] = 4
                elif mutate == 'payload': bad['provenance'] = {'changed': True}
                else: bad['device_epoch'] = uid(); bad['sequence'] = 1; f.register(bad['device_epoch'])
                before = state(f)
                require(f.apply(bad)['code'] == 'payloadMismatch' and state(f) == before, 'Compacted identity cannot be reassigned')
        require(f.apply(label)['result']['results'][0]['kind'] == 'already_processed', 'Exact old retry reconciles')
        recreate = deepcopy(label); recreate['operation_id'] = uid(); recreate['sequence'] = 4
        tombstone = rows(f, 'tag_shadow')
        require(f.apply(recreate)['result']['results'][0]['disposition'] == 'conflict' and
                rows(f, 'tag_shadow') == tombstone and
                any(r['record']['operation'] == recreate for r in rows(f, 'recovery_candidates')),
                'Deleted UUID stays deleted and attempted recreation remains recoverable')
        check('legacy identity backfill, payload/sequence/device mismatch, old retries and permanent entity keys')

        f, _ = gone(backend, epoch); age(f)
        sql(f"update sync_private.operation_identities set payload_hash=decode(repeat('00',32),'hex') "
            f"where owner_id='{f.owner}' and sequence=2;")
        before = state(f)
        try:
            prune(f)
            raise AssertionError('Corrupt proof accepted')
        except RuntimeError:
            pass
        require(state(f) == before, 'Identity failure rolls back shadow/log/revision as well')
        check('identity corruption aborts whole compaction batch without losing originals')

        f, _ = gone(backend, epoch); age(f); before = state(f)
        for size in ('null', '0', '-1', '1001'):
            try:
                sql(f"select sync_private.prune_deleted_content('{f.owner}',{size});")
                raise AssertionError('Invalid bound accepted')
            except RuntimeError:
                pass
        sql("create function sync_private.test_content_fail() returns trigger language plpgsql as $$ begin "
            "raise exception 'Injected failure'; end $$; create trigger test_content_fail before insert "
            "on sync_private.change_log for each row execute function sync_private.test_content_fail();")
        try:
            try:
                prune(f)
                raise AssertionError('Fault did not trigger')
            except RuntimeError:
                pass
            require(state(f) == before, 'Log fault/invalid inputs roll back all state')
        finally:
            sql('drop trigger test_content_fail on sync_private.change_log; drop function sync_private.test_content_fail();')
        check('invalid bounds and injected log failure preserve whole transactional state')

        # Prune first: readers and stale restore wait for the atomic commit.
        f, remove = gone(backend, epoch); age(f); label = uid()
        with ThreadPoolExecutor(max_workers=5) as pool:
            first = pool.submit(sql, f"begin; set local application_name='{label}'; "
                f"select sync_private.prune_deleted_content('{f.owner}',200); select pg_sleep(1.5); commit;")
            wait_for_sleep(label)
            reads = [pool.submit(pull, f), pool.submit(begin, f), pool.submit(prune, f),
                     pool.submit(f.apply, restore(f, remove))]
            time.sleep(.1)
            require(all(not r.done() for r in reads), 'Readers/writers serialize behind pruning')
            first.result(); results = [r.result() for r in reads]
        require(results[2]['shadows_compacted'] == 0 and
                results[3]['result']['results'][0]['rejection_code'] == 'restore_content_expired', 'Concurrent retry/restore')
        require(page(f, results[1])['records'][0]['fields'] == {'existence': {'revision': 2, 'value': False}}, 'Concurrent coherent capture')
        check('prune-first pull/snapshot/restore/second-pruner serialize and see coherent committed state')

        # Reader/apply first: expiry is sampled after waiting for the account lock.
        f, remove = gone(backend, epoch)
        sql(f"update sync_private.task_deletions set deleted_at=clock_timestamp()-interval '720 hours'+interval '1 second' "
            f"where owner_id='{f.owner}';")
        label = uid()
        with ThreadPoolExecutor(max_workers=2) as pool:
            first = pool.submit(sql, f"begin; set local application_name='{label}'; "
                f"select revision from sync_private.account_state where owner_id='{f.owner}' for share; "
                "select pg_sleep(1.5); commit;")
            wait_for_sleep(label); second = pool.submit(prune, f)
            first.result(); result = second.result()
        require(result['shadows_compacted'] == 1, 'Expiry uses post-lock time')
        f, remove = gone(backend, epoch); label = uid()
        request = f.request(restore(f, remove))
        with ThreadPoolExecutor(max_workers=2) as pool:
            first = pool.submit(sql, f"begin; set local application_name='{label}'; set local role authenticated; "
                f"select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                f"select public.sync_apply({literal(json.dumps(request))}::jsonb)->>'status'; select pg_sleep(1.5); commit;")
            wait_for_sleep(label); second = pool.submit(prune, f)
            time.sleep(.1); require(not second.done(), 'Pruner waits for restore commit')
            first.result(); result = second.result()
        require(result['shadows_compacted'] == 0 and 'title' in f.fields(), 'Winning recent restore retains content')
        check('reader-first expiry during wait and restore-first commit both respected')

        f, _ = gone(backend, epoch); age(f)
        other, _ = gone(backend, epoch); age(other); before = state(other)
        for role in ('anon', 'authenticated', 'service_role', 'dourstuff_rpc'):
            for function in ('prune_deleted_content(uuid,integer)', 'retain_content_identity(uuid,jsonb)'):
                require(sql(f"select has_function_privilege('{role}','sync_private.{function}','execute');") == 'f', 'Operator-only functions')
            require(sql(f"select has_table_privilege('{role}','sync_private.deleted_content','select');") == 'f', 'No private-view access')
        for token in (None, f.token, other.token):
            code, _ = backend.request('POST', '/rest/v1/rpc/prune_deleted_content', token, {'owner': f.owner})
            require(code in (401, 403, 404), 'No public cleanup RPC')
            for method in ('GET', 'POST', 'PATCH', 'DELETE'):
                code, _ = backend.request(method, '/rest/v1/deleted_content', token, None if method == 'GET' else {})
                require(code in (401, 403, 404), 'No exposed cleanup view')
        subprocess.run([sys.executable, str(ROOT / 'tool/run_backend_retention.py'), '--owner', f.owner,
                        '--policy', 'deleted-content', '--batch-size', '1', '--batches', '3'], check=True)
        require(prune(f)['shadows_compacted'] == 0 and state(other) == before, 'Bounded local runner and owner isolation')
        check('private grants/raw REST isolation and guarded bounded operator runner')
        print(f'{passed} deleted-content integration groups passed.')
    finally:
        backend.cleanup()
        if args.wire_output:
            args.wire_output.parent.mkdir(parents=True, exist_ok=True)
            args.wire_output.write_text(json.dumps(backend.wire), encoding='utf-8')


if __name__ == '__main__':
    main()
