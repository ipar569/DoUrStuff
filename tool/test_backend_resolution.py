"""Recovery v1: real local transactions, immutable retries and frozen downloads."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys

from test_backend_foundation import Backend, DB, literal, require, sql
from test_backend_apply import observed, predecessor, uid
from test_backend_task_create import TaskFixture
from test_backend_task_delete import deletion
from test_backend_history import rpc
from test_backend_retention import age, prune, wait_for_sleep
from test_backend_tag_commands import tag, name
from test_backend_memberships import membership

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20261030025201_explicit_conflict_resolution.sql'
EPOCH_MIGRATION = ROOT / 'supabase/migrations/20261030231250_recovery_retry_epoch.sql'


def candidates(f):
    return json.loads(sql(f"select coalesce(jsonb_agg(record order by record->>'revision',id),'[]') "
                          f"from sync_private.recovery_candidates where owner_id='{f.owner}';"))


def rows(f, table):
    return sql(f"select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),'[]') "
               f"from sync_private.{table} t where owner_id='{f.owner}';")


def state(f):
    return f.state(), rows(f, 'operation_identities'), rows(f, 'recovery_resolutions'), rows(f, 'resolution_requests')


def seed(backend, epoch, held=True):
    f = TaskFixture(backend, epoch)
    ops = [f.create(), f.op(2, 'canonical'), f.op(3, 'candidate')]
    if held:
        ops += [f.op(4, 'held', predecessor(ops[2], 'candidate'))]
        ops += [f.op(5, 'held again', predecessor(ops[3], 'held'))]
    f.apply(*ops)
    return f, ops


def request(f, candidate, seq, value=None, held=(), device=None):
    fields = f.fields()
    operation = f.op(seq, value, observed(fields['title']['revision'], fields['title']['value'])) if value is not None else None
    identity = operation['operation_id'] if operation else uid()
    if operation and device:
        operation['device_epoch'] = device
    return dict(protocol_version=2, resolution_version=1,
                cursor=dict(server_epoch=f.epoch, revision=int(sql(f"select revision from sync_private.account_state where owner_id='{f.owner}';"))),
                operation_id=identity, device_epoch=device or f.device, sequence=seq,
                conflict_id=candidate['id'], expected_conflict_revision=candidate['revision'],
                observed_fields=fields, choice='replace' if operation else 'discard', replacement=operation,
                held_choices=[dict(id=c['id'], revision=c['revision'], choice=choice) for c, choice in held])


def resolve(f, q):
    return f.backend.rpc('resolve_recovery', f.token, q)


def begin(f):
    return rpc(f, 'snapshot_begin', dict(protocol_version=2, history_version=1, resolution_version=1, server_epoch=f.epoch))['result']


def page(f, m, n=0):
    return rpc(f, 'snapshot_page', dict(protocol_version=2, history_version=1, resolution_version=1,
                                      server_epoch=f.epoch, token=m['token'], page=n))['result']


def pull(f, after=0, limit=200):
    return rpc(f, 'pull', dict(protocol_version=2, history_version=1, resolution_version=1,
                              after=dict(server_epoch=f.epoch, revision=after), limit=limit))


def epoch_retry(backend, epoch, candidate=False):
    f, _ = seed(backend, epoch, False)
    q = request(f, candidates(f)[0], 4)
    accepted = resolve(f, q); before = state(f)
    refreshed = deepcopy(q); refreshed['cursor']['server_epoch'] = uid()
    source = ('begin;\n' + (EPOCH_MIGRATION.read_text(encoding='utf-8') if candidate else '') +
              f"update sync_private.backend_state set server_epoch='{refreshed['cursor']['server_epoch']}'; "
              f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
              f"select public.sync_resolve_recovery({literal(json.dumps(q))}::jsonb); "
              f"select public.sync_resolve_recovery({literal(json.dumps(refreshed))}::jsonb); rollback;")
    replies = [json.loads(line) for line in sql(source).splitlines()[1:]]
    expected = deepcopy(accepted)
    expected['result']['cursor']['server_epoch'] = refreshed['cursor']['server_epoch']
    require(replies[0]['code'] == 'serverEpochChanged' and replies[1] == expected,
            'Retained decision uses current epoch and original revision')
    require(state(f) == before and sql('select server_epoch from sync_private.backend_state;') == epoch,
            'Epoch, retained decisions, candidates and every mutation roll back unchanged')
    backend.wire.append(dict(rpc='resolve_recovery', request=refreshed, reply=replies[1]))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--supabase', default='supabase')
    parser.add_argument('--wire-output', type=Path)
    parser.add_argument('--candidate', action='store_true')
    parser.add_argument('--epoch-candidate', action='store_true')
    parser.add_argument('--epoch-only', action='store_true')
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
        if args.epoch_candidate or args.epoch_only:
            epoch_retry(backend, epoch, candidate=args.epoch_candidate)
            check('retained resolution retries correlate after rollback-only server epoch change')
            return
        if args.candidate:
            f, _ = seed(backend, epoch)
            cs = candidates(f); q = request(f, cs[0], 6, 'chosen', [(c, 'keepHeld') for c in cs[1:]])
            before = f.state()
            discard = request(f, cs[1], 7, held=[(cs[2], 'discard')])
            discard['cursor']['revision'] = 6
            discard['observed_fields']['title'] = dict(revision=6, value='chosen')
            download = dict(protocol_version=2, history_version=1, resolution_version=1, server_epoch=epoch)
            source = ('begin;\n' + MIGRATION.read_text(encoding='utf-8') +
                      f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                      f"select public.sync_resolve_recovery({literal(json.dumps(q))}::jsonb); "
                      f"select public.sync_resolve_recovery({literal(json.dumps(discard))}::jsonb); "
                      f"select public.sync_snapshot_begin({literal(json.dumps(download))}::jsonb); rollback;")
            replies = [json.loads(line) for line in sql(source).splitlines()[1:]]
            require(all(r['status'] == 'success' for r in replies) and before == f.state(), 'Candidate resolution rollback')
            check('forward migration and real resolution rollback preserve originals and state')
            return

        f, ops = seed(backend, epoch); cs = candidates(f); originals = deepcopy(cs)
        old = begin(f); frozen = page(f, old)
        q = request(f, cs[0], 6, 'chosen', [(cs[1], 'keepHeld'), (cs[2], 'discard')])
        result = resolve(f, q)
        require(result['status'] == 'success' and len(result['result']['resolutions']) == 2, 'Explicit choices')
        require(f.fields()['title'] == dict(revision=6, value='chosen'), 'Fresh versioned replacement')
        require(candidates(f) == originals, 'Every original candidate/base/canonical preserved')
        require(page(f, old) == frozen, 'Frozen snapshot')
        current = begin(f); downloaded = page(f, current)
        require(current['token'] != old['token'] and len(downloaded['resolutions']) == 2, 'New complete capture')
        require(downloaded['recovery'] == sorted(originals, key=lambda c: c['id']), 'Snapshot originals')
        require(pull(f, 5)['result']['groups'][0]['resolutions'] == sorted(result['result']['resolutions'], key=lambda r: r['conflict_id']), 'Continuation closes exact candidates')
        require(all('resolutions' not in g for g in f.pull()['groups']), 'Legacy shape unchanged')
        before = state(f)
        require(resolve(f, q) == result and state(f) == before, 'Lost-reply retry exact')
        changed = deepcopy(q); changed['held_choices'][0]['choice'] = 'discard'
        require(resolve(f, changed)['code'] == 'payloadMismatch' and state(f) == before, 'Entire decision immutable')
        check('replacement, explicit transitive keep/discard, immutable originals, fixed snapshot and continuation')

        # Original transport retries remain original receipts, never resolutions.
        receipts = f.apply(*ops)['result']['results']
        require(receipts[2]['disposition'] == 'conflict' and receipts[3]['disposition'] == 'held' and state(f) == before, 'Original retries')
        q2 = request(f, cs[1], 7, 'held chosen')
        require(resolve(f, q2)['status'] == 'success', 'Held candidate requires own fresh replacement')
        late = f.op(8, 'late held', predecessor(ops[2], 'candidate'))
        require(f.apply(late)['result']['results'][0]['disposition'] == 'held', 'Resolution never changes original causal evidence')
        age(f); prune(f)
        require(resolve(f, q) == result, 'Resolution retry survives ordinary receipt/log expiry')
        qfresh = deepcopy(q); qfresh['cursor']['revision'] = 8
        require(resolve(f, qfresh) == result, 'Refreshed cursor can reconcile original resolution')
        retry = f.request(*ops); retry['after_revision'] = 8
        require(all(r['kind'] == 'already_processed' for r in backend.rpc('apply', f.token, retry)['result']['results']), 'Expired original receipts never replay')
        require(candidates(f)[:3] == originals, 'Retention keeps originals')
        check('held value reapplied only by new operation; original retries, late successors and expired receipts')

        f, _ = seed(backend, epoch, False); c = candidates(f)[0]
        q = request(f, c, 4, 'first'); other = uid(); f.register(other)
        q2 = request(f, c, 1, 'second', device=other)
        with ThreadPoolExecutor(max_workers=2) as pool:
            replies = list(pool.map(lambda x: resolve(f, x), (q, q2)))
        require(sorted(r['status'] for r in replies) == ['failure', 'success'] and
                next(r for r in replies if r['status'] == 'failure')['code'] == 'recoveryChanged', 'Resolution race')
        require(len(json.loads(rows(f, 'recovery_resolutions'))) == 1, 'Exactly one closure')
        check('concurrent devices cannot silently replace each other or consume losing sequence')

        for change in ('field', 'delete', 'held'):
            f, ops = seed(backend, epoch, False); c = candidates(f)[0]; q = request(f, c, 5, 'stale')
            if change == 'field': f.apply(f.op(4, 'newer', observed(2, 'canonical')))
            elif change == 'delete': f.apply(deletion(f, 4))
            else: f.apply(f.op(4, 'new held', predecessor(ops[2], 'candidate')))
            before = state(f)
            require(resolve(f, q)['code'] == 'recoveryChanged' and state(f) == before, 'Stale preview consumes nothing')
        check('field, deletion and new held descendant invalidate preview without consuming work')

        f, _ = seed(backend, epoch, False); c = candidates(f)[0]
        q = request(f, c, 4, ' '); before = state(f)
        require(resolve(f, q)['code'] == 'replacementRejected' and state(f) == before, 'Rejected replacement rollback')
        q = request(f, c, 4, 'canonical'); q['replacement']['patches']['title']['base'] = observed(1, 'X')
        require(resolve(f, q)['code'] == 'recoveryChanged' and state(f) == before, 'Equivalent value still needs exact base')
        q = request(f, c, 4)
        require(resolve(f, q)['status'] == 'success' and f.fields()['title']['value'] == 'canonical', 'Discard does not mutate field')
        require(f.apply(f.op(5, 'next', observed(2, 'canonical')))['status'] == 'success', 'Discard preserves contiguous unrelated progress')
        check('invalid replacement rollback, strict equivalent base and sequenced discard')

        # Inject failure after all domain writes, proving no partial resolution.
        f, _ = seed(backend, epoch, False); c = candidates(f)[0]; q = request(f, c, 4, 'rollback'); before = state(f)
        sql("create function sync_private.test_resolution_fault() returns trigger language plpgsql as $$ begin raise exception 'synthetic'; end $$; "
            "create trigger test_resolution_fault before insert on sync_private.resolution_requests for each row execute function sync_private.test_resolution_fault();")
        try:
            code, _ = backend.request('POST', '/rest/v1/rpc/sync_resolve_recovery', f.token, {'request': q})
            require(code >= 400 and state(f) == before, 'Atomic injected rollback')
        finally:
            sql('drop trigger test_resolution_fault on sync_private.resolution_requests; drop function sync_private.test_resolution_fault();')
        check('late injected failure rolls back shadow, receipt, log, watermark, closure and request')

        # Hold resolution open: pull/snapshot must wait for all closure facts.
        label = uid()
        source = (f"begin; set local application_name='{label}'; set local role authenticated; "
                  f"select set_config('request.jwt.claim.sub','{f.owner}',true); select public.sync_resolve_recovery(" +
                  literal(json.dumps(q)) + '::jsonb); select pg_sleep(2); commit;')
        with ThreadPoolExecutor(max_workers=3) as pool:
            writer = pool.submit(sql, source); wait_for_sleep(label)
            read = pool.submit(pull, f); capture = pool.submit(begin, f)
            writer.result(); m = capture.result(); changes = read.result()
        require(len(page(f, m)['resolutions']) == 1 and len(changes['result']['groups'][-1]['resolutions']) == 1, 'Atomic reader visibility')
        check('late resolution commit serializes pull and fixed-revision snapshot capture')

        y = TaskFixture(backend, epoch); yq = deepcopy(q); yq['device_epoch'] = y.device; yq['operation_id'] = uid(); yq['sequence'] = 1
        yq['cursor']['revision'] = 0; yq['expected_conflict_revision'] = 1
        # Foreign candidate with a valid local cursor still returns no content.
        y.apply(y.create()); yq['cursor']['revision'] = 1; yq['sequence'] = 2; yq['replacement'] = None; yq['choice'] = 'discard'
        require(resolve(y, yq)['code'] == 'recoveryChanged', 'Cross-owner resolution denied')
        for token in (None, f.token, y.token):
            for table in ('resolution_requests', 'recovery_resolutions'):
                for method, body in (('GET', None), ('POST', {'owner_id': f.owner}), ('PATCH', {}), ('DELETE', None)):
                    code, _ = backend.request(method, '/rest/v1/' + table, token, body)
                    require(code in (401, 403, 404), 'No raw REST bypass')
        code, _ = backend.request('POST', '/rest/v1/rpc/sync_resolve_recovery', None, {'request': q})
        require(code in (401, 403), 'Anonymous denied')
        require(backend.rpc('snapshot_page', f.token, dict(protocol_version=2, history_version=1, server_epoch=epoch, token=m['token'], page=0))['code'] == 'snapshotExpired', 'Capture downgrade denied')
        check('owner isolation, anonymous/raw REST denial and negotiated token binding')

        f = TaskFixture(backend, epoch); f.apply(f.create(), f.op(2, 'canonical'))
        ops = []
        for seq in range(3, 208):
            base = observed(1, 'X') if seq in (3, 203) else predecessor(ops[-1], ops[-1]['patches']['title']['value'])
            ops.append(f.op(seq, f'candidate {seq}', base))
        for start in range(0, len(ops), 32): f.apply(*ops[start:start+32])
        cs = sorted(candidates(f), key=lambda c: c['revision']); originals = deepcopy(cs)
        for seq, group in ((208, cs[:200]), (209, cs[200:])):
            q = request(f, group[0], seq, held=[(c, 'discard') for c in group[1:]])
            require(resolve(f, q)['status'] == 'success', 'Bounded closure batch')
        m = begin(f); pages = [page(f, m, n) for n in range(m['page_count'])]
        require(m['page_count'] > 1 and sum(len(p['resolutions']) for p in pages) == 205 and
                m['record_count'] == 412, 'Multi-page exact counts include resolutions and originals')
        require(sorted([c for p in pages for c in p['recovery']], key=lambda c: c['revision']) == originals, 'Multi-page immutable candidates')
        first = pull(f, 207, 1)['result']; second = pull(f, first['through']['revision'], 1)['result']
        require(first['has_more'] and not second['has_more'] and len(first['groups'][0]['resolutions']) == 200 and
                len(second['groups'][0]['resolutions']) == 5, 'Never split one closure revision')
        check('205 closures across bounded decisions, frozen snapshot pages and whole-revision pull pagination')

        f = TaskFixture(backend, epoch); first = tag(f, 2); collision = tag(f, 3, name('WORK'))
        held = membership(f, collision, 4, parents=(collision,))
        f.apply(f.create(), first, collision, held)
        cs = candidates(f); parent = next(c for c in cs if c['operation'] == collision and c['group'] == 'existence')
        child = next(c for c in cs if c['operation'] == held)
        q = request(f, parent, 5, held=[(child, 'discard')]); q['observed_fields'] = None
        require(resolve(f, q)['status'] == 'success' and candidates(f) == cs, 'Absent parent and held relationship explicit discard')
        require(sql(f"select count(*) from sync_private.membership_shadow where owner_id='{f.owner}';") == '0', 'No UUID alias or accidental relationship')
        check('missing collided tag identity and held parent-dependent membership preserve exact originals')

        f, _ = seed(backend, epoch, False); q = request(f, candidates(f)[0], 4); before = state(f)
        for key in ('protocol_version', 'resolution_version'):
            for value in (None, 2.0 if key == 'protocol_version' else 1.0, '2' if key == 'protocol_version' else '1'):
                changed = deepcopy(q); changed[key] = value
                code, reply = backend.request('POST', '/rest/v1/rpc/sync_resolve_recovery', f.token, {'request': changed})
                require(code == 400 if isinstance(value, float) else code == 200 and reply['code'] == 'unsupportedProtocol', 'Strict numeric version')
        for changed in (dict(q, choice=None), dict(q, held_choices=[dict(id=uid(),revision=1,choice=None)]),
                        dict(q, extra=True), dict(q, replacement={})):
            code, _ = backend.request('POST', '/rest/v1/rpc/sync_resolve_recovery', f.token, {'request': changed})
            require(code == 400, 'Malformed recovery request')
        reused = deepcopy(q); reused['operation_id'] = candidates(f)[0]['operation']['operation_id']
        require(resolve(f, reused)['code'] == 'payloadMismatch' and state(f) == before, 'Cannot reassign original identity to discard')
        require(resolve(f, q)['status'] == 'success', 'Preflight leaves sequence available')
        check('strict extension versions, malformed choices and immutable original operation identities')
        epoch_retry(backend, epoch)
        check('retained resolution retries correlate after rollback-only server epoch change')
        print(f'{passed} recovery integration groups passed.', flush=True)
    finally:
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, ensure_ascii=False), encoding='utf-8')
        backend.cleanup()


if __name__ == '__main__':
    main()
