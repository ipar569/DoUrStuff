"""Real PostgreSQL/HTTP retention tests; all accounts are synthetic and cleaned up."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import time

from test_backend_foundation import Backend, literal, require, sql
from test_backend_task_create import TaskFixture, status
from test_backend_task_delete import deletion
from test_backend_apply import observed, predecessor, uid
from test_backend_history import begin, page, pull
from test_backend_milestone_create import milestone
from test_backend_milestone_commands import remove as delete_milestone
from test_backend_tag_commands import tag, remove as delete_tag
from test_backend_memberships import membership
from test_backend_saved_views import view, preference, delete as delete_view
from test_backend_task_restore import restore

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20261028062241_log_receipt_retention.sql'


def prune(f, size=200):
    return json.loads(sql(f"select sync_private.prune_log_receipts('{f.owner}',{size});"))


def age(f):
    sql(' '.join(f"update sync_private.{table} set recorded_at=clock_timestamp()-interval '4321 hours' "
                 f"where owner_id='{f.owner}';" for table in ('change_log', 'operation_receipts')))


def apply(f, *ops, after=None):
    if after is None:
        after = int(sql(f"select retained_after from sync_private.account_state where owner_id='{f.owner}';"))
    return f.backend.rpc('apply', f.token, dict(f.request(*ops), after_revision=after))


def durable(f):
    tables = ('device_state', 'task_shadow', 'task_status_history', 'recovery_candidates',
              'task_deletions', 'task_restorations', 'milestone_shadow', 'milestone_deletions',
              'tag_shadow', 'tag_deletions', 'membership_shadow', 'membership_changes',
              'view_shadow', 'view_deletions', 'preference_shadow', 'preference_changes',
              'operation_identities', 'snapshots', 'snapshot_pages')
    parts = [f"(select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),'[]')::text "
             f"from sync_private.{table} t where owner_id='{f.owner}')" for table in tables]
    return json.loads(sql('select jsonb_build_array(' + ','.join(parts) + ');'))


def candidate(backend, epoch):
    f = TaskFixture(backend, epoch)
    f.apply(f.create(), f.op(2, 'Y'))
    before = f.state(), f.history()
    capture = begin(f); frozen = page(f, capture)
    result = sql('begin;\n' + MIGRATION.read_text(encoding='utf-8') +
                 f"select count(*) from sync_private.operation_identities where owner_id='{f.owner}'; "
                 f"select count(*) from sync_private.operation_receipts where owner_id='{f.owner}'; rollback;")
    require(result.splitlines() == ['2', '2'], 'Retained receipt identities backfilled')
    require((f.state(), f.history()) == before and page(f, capture) == frozen, 'Exact data/capture rollback')
    print('PASS: real-owner candidate backfill preserves receipts, history, watermark and snapshot through rollback', flush=True)


def wait_for_sleep(label):
    deadline = time.monotonic() + 8
    while sql(f"select exists(select 1 from pg_stat_activity where application_name='{label}' and wait_event='PgSleep');") != 't':
        require(time.monotonic() < deadline, 'Concurrent transaction reached barrier')
        time.sleep(.05)


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
            candidate(backend, epoch)
            return
        # Deterministic clock replacement exists only in a rolled-back test
        # transaction. Production exposes no clock override to any role.
        f = TaskFixture(backend, epoch)
        f.apply(f.create(), f.op(2, 'Y'), f.op(3, 'Z', observed(2, 'Y')))
        source = sql("select pg_get_functiondef('sync_private.prune_log_receipts(uuid,integer)'::regprocedure);")
        fixed = source.replace('clock_timestamp()', "'2026-10-28T00:00:00Z'::timestamptz") + ';\n'
        before = f.state(), durable(f)
        for zone in ('UTC', 'Pacific/Auckland', 'America/New_York'):
            statements = ''.join(
                f"update sync_private.{table} set recorded_at='2026-10-28T00:00:00Z'::timestamptz-interval '4320 hours' "
                f"+ case {key} when 1 then interval '-1 microsecond' when 2 then interval '0' else interval '1 microsecond' end "
                f"where owner_id='{f.owner}';" for table, key in (('change_log', 'revision'), ('operation_receipts', 'sequence')))
            result = json.loads(sql(f"begin; set local timezone='{zone}';\n" + fixed + statements +
                                   f"select sync_private.prune_log_receipts('{f.owner}',200); rollback;"))
            require(result == dict(logs_deleted=2, receipts_deleted=2, retained_after=2), 'Exact 180-day microsecond boundary')
        require((f.state(), durable(f)) == before, 'Clock fixtures roll back exactly')
        check('exact 4320-hour cutoff at minus/equal/plus one microsecond across DST/session timezones')

        age(f); before = durable(f)
        require(prune(f, 1) == dict(logs_deleted=1, receipts_deleted=1, retained_after=1), 'One row per stream bound')
        require(prune(f, 1)['retained_after'] == 2, 'Resumable next prefix')
        require(prune(f, 1)['retained_after'] == 3, 'Resumable final prefix')
        require(prune(f) == dict(logs_deleted=0, receipts_deleted=0, retained_after=3), 'Idempotent empty pass')
        require(durable(f) == before, 'All durable tables unchanged')
        require(pull(f, 2)['code'] == 'cursorExpired' and pull(f, 3)['result']['groups'] == [], 'Exact cursor boundary')
        check('bounded/resumable/idempotent whole-revision batches preserve every durable table')

        f = TaskFixture(backend, epoch)
        f.apply(f.create(), f.op(2, 'Y'), f.op(3, 'Z', observed(2, 'Y')))
        age(f)
        sql(f"update sync_private.change_log set recorded_at=clock_timestamp() where owner_id='{f.owner}' and revision=2;")
        require(prune(f)['retained_after'] == 1, 'Do not jump newer prefix blocker to older timestamp')
        require(prune(f)['retained_after'] == 1, 'Repeated pass still respects nonmonotonic legacy timestamps')
        sql(f"delete from sync_private.change_log where owner_id='{f.owner}' and revision=2;")
        require(prune(f)['retained_after'] == 1 and pull(f, 1)['code'] == 'unavailable', 'Missing revision is not hidden as expiry')
        check('nonmonotonic legacy timestamps and missing log revisions fail conservatively')

        f = TaskFixture(backend, epoch)
        create = f.create(); edit = f.op(2, 'Y')
        f.apply(create, edit)
        conflict = f.op(3, 'candidate'); held = f.op(4, 'held', predecessor(conflict, 'candidate'))
        f.apply(conflict, held)
        f.apply(deletion(f, 5))
        # Exercise retained unknown legacy provenance too.
        sql(f"update sync_private.task_status_history set operation=null where owner_id='{f.owner}';")
        capture = begin(f); frozen = page(f, capture)
        age(f); before = durable(f)
        result = prune(f)
        require(result == dict(logs_deleted=5, receipts_deleted=5, retained_after=5), 'All expired rows removed')
        require(durable(f) == before and page(f, capture) == frozen, 'Preserve candidates, history, deletion IDs and frozen pages')
        require(pull(f)['code'] == 'cursorExpired' and apply(f, edit, after=0)['code'] == 'cursorExpired', 'Stale readers/writers require bootstrap')
        # Existing immutable capture at the same R is reusable: retention only
        # changes logs/receipts/floor, never the captured representation.
        require(begin(f) == capture and page(f, capture) == frozen, 'In-flight snapshot survives pruning unchanged')
        require(pull(f, capture['at']['revision'])['result']['groups'] == [], 'Resume after snapshot R')
        require(apply(f, edit)['result']['results'][0]['kind'] == 'already_processed', 'Consumed retry cannot replay')
        require(durable(f) == before, 'Retry adds no durable changes')
        check('expired-cursor bootstrap, snapshot continuation and durable history/deletion/candidates survive pruning')

        f = TaskFixture(backend, epoch)
        create = f.create(); edit = f.op(2, 'Y'); f.apply(create, edit)
        age(f); prune(f)
        baseline = f.state(), durable(f)
        changed = deepcopy(edit); changed['patches']['title']['value'] = 'changed old payload'
        reused = deepcopy(edit); reused['sequence'] = 3
        other = uid(); f.register(other)
        baseline = f.state(), durable(f)
        across = deepcopy(edit); across['device_epoch'] = other; across['sequence'] = 1
        replaced = deepcopy(edit); replaced['operation_id'] = uid()
        for bad in (changed, reused, across, replaced):
            require(apply(f, bad)['code'] == 'payloadMismatch', 'Durable payload/sequence/operation identity')
            require((f.state(), durable(f)) == baseline, 'Identity failure consumes nothing')
        # A bad second entry must not consume an otherwise-valid first entry.
        first = f.op(3, 'valid', observed(2, 'Y')); reused['sequence'] = 4
        require(apply(f, first, reused)['code'] == 'payloadMismatch' and (f.state(), durable(f)) == baseline, 'Whole batch preflight')
        require(apply(f, edit)['result']['results'][0]['kind'] == 'already_processed', 'Original payload reconciles')
        check('ordinary edit identities survive expiry; same/new sequence, new device and late batch reuse denied atomically')

        conflict = f.op(3, 'candidate'); held = f.op(4, 'held', predecessor(conflict, 'candidate'))
        apply(f, conflict, held); age(f); prune(f)
        missing = f.op(5, 'cannot bind', predecessor(edit, 'Y'))
        still_held = f.op(6, 'still held', predecessor(held, 'held'))
        unrelated = f.op(7, 'high', observed(1, 'none'), group='priority')
        results = apply(f, missing, still_held, unrelated)['result']['results']
        require([r['fields'][0]['disposition'] for r in results] == ['recovery', 'held', 'applied'], 'No guessed predecessor; unrelated progress')
        downloaded = page(f, begin(f))
        require(any(r['operation'] == missing for r in downloaded['recovery']) and
                any(r['operation'] == still_held for r in downloaded['recovery']), 'Original dependency bases preserved')
        require(downloaded['records'][0]['fields']['title']['value'] == 'Y', 'Missing predecessor never overwrites title')
        check('missing accepted predecessor requires recovery, unresolved chains stay held and unrelated work progresses')

        f = TaskFixture(backend, epoch); create = f.create(); f.apply(create); age(f); prune(f)
        child = milestone(f, 2, dependency=create)
        result = apply(f, child)['result']['results'][0]
        require(all(field['disposition'] == 'recovery' for field in result['fields']), 'Missing parent receipt cannot bind from identity/history')
        require(any(r['operation'] == child for r in page(f, begin(f))['recovery']), 'Exact parent dependency retained')
        check('expired parent evidence requires original-candidate recovery despite retained creation identity/history')

        f = TaskFixture(backend, epoch)
        create = f.create(); child = milestone(f, 2); label = tag(f, 3); saved = view(f, 5)
        f.apply(create, child, label, membership(f, label, 4), saved,
                preference(f, 6, saved['entity']['key'][0]))
        remove = deletion(f, 10)
        f.apply(delete_milestone(f, child, 7, observed(2, True)),
                delete_tag(f, label, 8, observed(3, True)), delete_view(f, saved, 9, observed(5, True)),
                remove, restore(f, remove, 11, 10))
        capture = begin(f); frozen = page(f, capture); age(f); before = durable(f)
        require(all(json.loads(before[i]) for i in range(16) if i != 3), 'Every durable identity/content table populated')
        result = prune(f, 20)
        require(result == dict(logs_deleted=11, receipts_deleted=11, retained_after=11), 'Whole multi-record revision cleanup')
        require(durable(f) == before and page(f, capture) == frozen, 'All populated durable ledgers and shadow kinds preserved')
        check('populated task/restore/milestone/tag/membership/view/preference ledgers and multi-record revisions survive expiry')

        # Hold a real apply transaction open; pruning and both download paths
        # must wait for the complete commit, then see its fresh recording time.
        f = TaskFixture(backend, epoch); f.apply(f.create()); age(f)
        edit = f.op(2, 'Y'); label = uid()
        writer_sql = (f"begin; set local application_name='{label}'; set local role authenticated; "
                      f"select set_config('request.jwt.claim.sub','{f.owner}',true); select public.sync_apply(" +
                      literal(json.dumps(f.request(edit))) + '::jsonb); select pg_sleep(2); commit;')
        with ThreadPoolExecutor(max_workers=4) as pool:
            writer = pool.submit(sql, writer_sql); wait_for_sleep(label)
            pruning = pool.submit(prune, f); downloading = pool.submit(pull, f)
            capturing = pool.submit(begin, f)
            writer.result(); result = pruning.result(); downloaded = downloading.result(); capture = capturing.result()
        require(result == dict(logs_deleted=1, receipts_deleted=1, retained_after=1), 'Fresh late commit survives pruning')
        require(capture['at']['revision'] == 2 and page(f, capture)['records'][0]['fields']['title']['value'] == 'Y', 'Atomic snapshot after late commit')
        require(downloaded.get('code') == 'cursorExpired' or downloaded['result']['through']['revision'] == 2, 'Pull linearizes before or after prune')
        require(pull(f, 1)['result']['groups'][0]['revision'] == 2, 'No missing late log')
        check('concurrent apply/prune/pull/snapshot linearize under the account lock without losing late commits')

        f = TaskFixture(backend, epoch); f.apply(f.create()); capture = begin(f); frozen = page(f, capture); age(f)
        label = uid()
        source = (f"begin; set local application_name='{label}'; select sync_private.prune_log_receipts('{f.owner}',200); "
                  'select pg_sleep(2); commit;')
        with ThreadPoolExecutor(max_workers=5) as pool:
            pruning = pool.submit(sql, source); wait_for_sleep(label)
            reader = pool.submit(pull, f); capture_reader = pool.submit(begin, f)
            retry = pool.submit(apply, f, f.op(2, 'Y'), after=0)
            second = pool.submit(prune, f)
            pruning.result()
            require(reader.result()['code'] == 'cursorExpired' and retry.result()['code'] == 'cursorExpired', 'Blocked stale pull/apply see committed floor')
            require(capture_reader.result() == capture and page(f, capture) == frozen, 'Same-R capture remains intact')
            require(second.result()['logs_deleted'] == 0, 'Concurrent pruners never double delete')
        check('retention-first concurrency publishes floor/deletes atomically; second pruner and snapshot retries are safe')

        f = TaskFixture(backend, epoch); f.apply(f.create()); label = uid()
        # At worker start these records are still young; while it waits on the
        # account lock they cross the cutoff. transaction_timestamp() would fail.
        source = (f"begin; set local application_name='{label}'; "
                  f"select owner_id from sync_private.account_state where owner_id='{f.owner}' for update; " +
                  ''.join(f"update sync_private.{table} set recorded_at=clock_timestamp()-interval '4320 hours'+interval '1 second' "
                          f"where owner_id='{f.owner}';" for table in ('change_log', 'operation_receipts')) +
                  'select pg_sleep(2); commit;')
        with ThreadPoolExecutor(max_workers=2) as pool:
            holder = pool.submit(sql, source); wait_for_sleep(label)
            pruning = pool.submit(prune, f); holder.result(); result = pruning.result()
        require(result == dict(logs_deleted=1, receipts_deleted=1, retained_after=1), 'Cutoff clock sampled after account lock')
        check('records crossing expiry during lock wait use fresh trusted time after the lock')

        for name, request in [('pull', dict(protocol_version=2, history_version=1,
                                           after=dict(server_epoch=epoch, revision=0), limit=200)),
                              ('snapshot_begin', dict(protocol_version=2, history_version=1, server_epoch=epoch))]:
            f = TaskFixture(backend, epoch); f.apply(f.create()); age(f); label = uid()
            source = (f"begin; set local application_name='{label}'; set local role authenticated; "
                      f"select set_config('request.jwt.claim.sub','{f.owner}',true); select public.sync_{name}(" +
                      literal(json.dumps(request)) + '::jsonb); select pg_sleep(2); commit;')
            with ThreadPoolExecutor(max_workers=2) as pool:
                reader = pool.submit(sql, source); wait_for_sleep(label)
                pruning = pool.submit(prune, f)
                time.sleep(.1)
                require(not pruning.done(), 'Pruning waits for existing reader transaction')
                reader.result()
                require(pruning.result()['retained_after'] == 1, 'Prune follows completed reader')
            require(pull(f)['code'] == 'cursorExpired', 'New reader observes expired floor')
        check('pull-first and snapshot-first transactions hold retention until their complete reads commit')

        f = TaskFixture(backend, epoch); f.apply(f.create()); age(f)
        other = TaskFixture(backend, epoch); other.apply(other.create()); age(other); other_before = other.state(), durable(other)
        for token in (None, f.token, other.token):
            code, _ = backend.request('POST', '/rest/v1/rpc/prune_log_receipts', token, {'account_owner': f.owner, 'batch_size': 200})
            require(code in (401, 403, 404), 'No public retention RPC')
            for method in ('GET', 'POST', 'PATCH', 'DELETE'):
                code, _ = backend.request(method, '/rest/v1/operation_identities', token, None if method == 'GET' else {})
                require(code in (401, 403, 404), 'No raw identity access')
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                    f"select count(*) from sync_private.operation_identities where owner_id='{f.owner}'; rollback;").splitlines()[-1] == '0', 'Identity RLS')
        for role in ('anon', 'authenticated', 'service_role', 'dourstuff_rpc'):
            require(sql(f"select has_function_privilege('{role}','sync_private.prune_log_receipts(uuid,integer)','execute');") == 'f', 'No API role maintenance execution')
            require(sql(f"select has_table_privilege('{role}','sync_private.operation_identities','update') or "
                        f"has_table_privilege('{role}','sync_private.operation_identities','delete');") == 'f', 'Immutable identity grants')
        prune(f)
        require((other.state(), durable(other)) == other_before, 'Other owner untouched')
        # Operation IDs are account-qualified, not global identities.
        same = other.op(2, 'Y'); same['operation_id'] = json.loads(durable(f)[16])[0]['operation_id']
        require(other.apply(same)['status'] == 'success', 'Same operation ID allowed for different owner')
        check('private operator execution, forced RLS, immutable grants and account-qualified isolation')

        f = TaskFixture(backend, epoch); f.apply(f.create()); age(f)
        before = f.state(), durable(f)
        for size in ('null', '0', '-1', '1001'):
            try:
                sql(f"select sync_private.prune_log_receipts('{f.owner}',{size});")
                raise AssertionError('Invalid batch accepted')
            except RuntimeError:
                pass
        require((f.state(), durable(f)) == before, 'Invalid bounds do not write')
        sql("create function sync_private.test_retention_fail() returns trigger language plpgsql as $$ begin "
            "raise exception 'Injected retention failure'; end $$; "
            "create trigger test_retention_fail before delete on sync_private.operation_receipts "
            "for each row execute function sync_private.test_retention_fail();")
        try:
            try:
                prune(f)
                raise AssertionError('Injected failure not reached')
            except RuntimeError:
                pass
            require((f.state(), durable(f)) == before, 'Receipt failure rolls back log/floor and everything else')
        finally:
            sql('drop trigger test_retention_fail on sync_private.operation_receipts; drop function sync_private.test_retention_fail();')
        # Corruption cannot silently remove the last exact identity proof.
        sql(f"delete from sync_private.operation_identities where owner_id='{f.owner}';")
        before = f.state(), durable(f)
        try:
            prune(f)
            raise AssertionError('Missing identity not detected')
        except RuntimeError:
            pass
        require((f.state(), durable(f)) == before, 'Identity gap rolls back whole prune')
        check('argument bounds, injected receipt failure and missing identity all preserve atomic state')

        f = TaskFixture(backend, epoch); f.apply(f.create()); before = f.state(), durable(f)
        sql("create function sync_private.test_retention_apply_fail() returns trigger language plpgsql as $$ begin "
            "raise exception 'Injected apply failure'; end $$; "
            "create trigger test_retention_apply_fail before insert on sync_private.change_log "
            "for each row execute function sync_private.test_retention_apply_fail();")
        try:
            code, _ = backend.request('POST', '/rest/v1/rpc/sync_apply', f.token, {'request': f.request(f.op(2, 'Y'))})
            require(code == 400 and (f.state(), durable(f)) == before, 'Identity insertion rolls back with failed apply')
        finally:
            sql('drop trigger test_retention_apply_fail on sync_private.change_log; drop function sync_private.test_retention_apply_fail();')
        require(f.apply(f.op(2, 'Y'))['status'] == 'success', 'Failed apply did not reserve sequence/identity')
        check('compact identity, entity, history, receipt, log and watermark remain one atomic apply transaction')

        f = TaskFixture(backend, epoch); f.apply(f.create(), f.op(2, 'Y')); age(f)
        before = durable(f)
        subprocess.run([sys.executable, str(ROOT / 'tool/run_backend_retention.py'), '--owner', f.owner,
                        '--batch-size', '1', '--batches', '3'], check=True)
        require(durable(f) == before and prune(f)['retained_after'] == 2, 'Operator runner bounded independent commits')
        check('guarded local operator runner completes bounded batches and stops when no work remains')
        print(f'{passed} retention integration groups passed.')
    finally:
        backend.cleanup()
        if args.wire_output:
            args.wire_output.parent.mkdir(parents=True, exist_ok=True)
            args.wire_output.write_text(json.dumps(backend.wire), encoding='utf-8')


if __name__ == '__main__':
    main()
