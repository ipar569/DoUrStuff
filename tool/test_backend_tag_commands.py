"""Real local tag identity, normalized-name collisions, deletion and rollback."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, literal, require, sql
from test_backend_task_create import TaskFixture
from test_backend_milestone_create import receipt

ROOT = Path(__file__).resolve().parents[1]


def name(display, key=None):
    # ASCII convenience only. Non-ASCII cases always supply the frozen key.
    if key is None:
        require(display.isascii(), 'Non-ASCII fixture requires an explicit pinned key')
        key = display.lower()
    return {'name': display, 'normalized_name': key}


def tag(f, seq=1, value=None, identity=None):
    op = f.op(seq, True, {'kind': 'absent'}, group='existence')
    op['entity'] = {'kind': 'tag', 'key': [identity or uid()]}
    op['command'] = 'tag.create'
    op['patches']['name'] = {'base': {'kind': 'absent'}, 'value': value or name('Work')}
    return op


def edit(f, source, seq=2, value=None, base=None):
    op = f.op(seq, value if value is not None else name('Changed'),
              observed(1, source['patches']['name']['value']) if base is None else base, group='name')
    op['entity'] = deepcopy(source['entity'])
    op['command'] = 'tag.edit'
    return op


def remove(f, source, seq=2, base=None):
    op = f.op(seq, False, observed(1, True) if base is None else base, group='existence')
    op['entity'] = deepcopy(source['entity'])
    op['command'] = 'tag.delete'
    return op


def tags(f):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(t) order by tag_id),'[]') "
                         f"from sync_private.tag_shadow t where owner_id='{f.owner}';"))


def ledger(f):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(t) order by revision),'[]') "
                         f"from sync_private.tag_deletions t where owner_id='{f.owner}';"))


def state(f):
    return f.state(), tags(f), ledger(f)


def candidates(f):
    return json.loads(sql(f"select coalesce(jsonb_agg(record order by field_group),'[]') "
                         f"from sync_private.recovery_candidates where owner_id='{f.owner}';"))


def candidate_smoke(backend, epoch):
    f = TaskFixture(backend, epoch)
    # Retain a real preexisting task and watermark through the new schema/RPC.
    f.apply(f.create())
    before = f.state()
    a = tag(f, 2)
    b = tag(f, 3, name('WORK'))
    held = edit(f, b, 4, name('Free'), predecessor(b, b['patches']['name']['value']))
    deleted = remove(f, a, 5, predecessor(a, True))
    source = 'begin;\n' + (ROOT / 'supabase/migrations/20261025021609_tag_commands.sql').read_text(encoding='utf-8')
    source += (f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
               'select public.sync_apply(' + literal(json.dumps(f.request(a, b, held, deleted))) + '::jsonb); rollback;')
    result = json.loads(sql(source).splitlines()[-1])
    require([r['disposition'] for r in result['result']['results']] == ['applied', 'conflict', 'held', 'applied'],
            'Candidate real-owner collision/held/delete batch')
    require(f.state() == before, 'Candidate rollback preserves exact retained task/history/receipt/watermark')
    print('PASS: candidate schema/RPC, collision/held/delete and exact retained-data rollback', flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--supabase', default='supabase')
    parser.add_argument('--wire-output', type=Path)
    parser.add_argument('--candidate', action='store_true')
    args = parser.parse_args()
    subprocess.run([sys.executable, str(Path(__file__).with_name('local_backend.py'))], check=True)
    backend = Backend(args.supabase)
    epoch = sql('select server_epoch from sync_private.backend_state;')
    passed = 0

    def passed_check(label):
        nonlocal passed
        passed += 1
        print('PASS: ' + label, flush=True)

    try:
        if args.candidate:
            candidate_smoke(backend, epoch)
            return
        fixture = json.loads((ROOT / 'test/fixtures/account-protocol-v2-tag-commands.json').read_text(encoding='utf-8'))
        f = TaskFixture(backend, epoch)
        ops = fixture['operations']
        f.device, f.task = ops[0]['device_epoch'], ops[0]['entity']['key'][0]
        f.register(f.device)
        result = f.apply(*ops)
        require(all(r['disposition'] == 'applied' for r in result['result']['results']), 'Shared atomic task/tag/create/edit/delete')
        row = tags(f)[0]
        require(row['tag_id'] == f.task and row['creation_operation'] == ops[1], 'Kind-qualified identity and immutable original create')
        require(row['fields']['name']['value'] == ops[2]['patches']['name']['value'] and len(f.history()) == 1, 'Name group and no tag status history')
        require(ledger(f)[0]['operation'] == ops[3] and row['delete_operation_id'] == ops[3]['operation_id'], 'Durable deletion identity')
        require(f.pull()['groups'][-1]['records'][0]['fields'] == row['fields'], 'Pull contains retained deleted tag')
        before = state(f)
        with ThreadPoolExecutor(max_workers=2) as pool:
            require(list(pool.map(lambda _: f.apply(*ops), range(2))) == [result, result], 'Concurrent/lost reply retries')
        require(state(f) == before, 'Retry has no writes')
        changed = deepcopy(ops[2]); changed['patches']['name']['value'] = name('Different')
        require(f.apply(changed)['code'] == 'payloadMismatch' and state(f) == before, 'Immutable name payload')
        passed_check('shared atomic fixture, original identities, pull, durable deletion and duplicate retries')

        for reverse in (False, True):
            f = TaskFixture(backend, epoch)
            a, b = tag(f, value=name('Work')), tag(f, value=name('WORK'))
            if reverse: a, b = b, a
            b['device_epoch'] = uid(); f.register(b['device_epoch'])
            require(receipt(f, a)['disposition'] == 'applied', 'First named tag')
            require(receipt(f, b)['disposition'] == 'conflict', 'Distinct UUID name collision')
            require(len(tags(f)) == 1 and tags(f)[0]['tag_id'] == a['entity']['key'][0], 'Collision never aliases or inserts partial row')
            recovery = candidates(f)
            require(len(recovery) == 2 and all(c['operation'] == b and c['canonical'] is None for c in recovery), 'Both original absent groups remain under losing UUID')
            f.device = b['device_epoch']
            follow = edit(f, b, 2, name('Free'), predecessor(b, b['patches']['name']['value']))
            delete_held = remove(f, b, 3, predecessor(b, True))
            require(receipt(f, follow)['disposition'] == 'held' and receipt(f, delete_held)['disposition'] == 'held', 'Missing canonical collision successors remain held')
            require(receipt(f, f.create(4))['disposition'] == 'applied', 'Unrelated task progresses contiguously')
            sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
            require(receipt(f, edit(f, follow, 5, name('Later'), predecessor(follow, name('Free'))))['disposition'] == 'held', 'Durable recovery binds held chains after receipt expiry')
            require(len(tags(f)) == 1, 'No held tag row fabricated')
        passed_check('both collision arrival orders preserve distinct UUID candidates and held successors through expiry')

        f = TaskFixture(backend, epoch)
        a, b = tag(f), tag(f, value=name('WORK'))
        b['device_epoch'] = uid(); f.register(b['device_epoch'])
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda op: receipt(f, op), (a, b)))
        require(sorted(r['disposition'] for r in results) == ['applied', 'conflict'] and len(tags(f)) == 1, 'Account lock serializes simultaneous same-name creates')
        passed_check('simultaneous different-UUID name creation keeps one canonical and one recoverable candidate')

        f = TaskFixture(backend, epoch)
        a, b = tag(f, value=name('Alpha')), tag(f, 2, name('Beta'))
        f.apply(a, b)
        rename = edit(f, a, 3, name('BETA'))
        require(receipt(f, rename)['disposition'] == 'conflict', 'Rename collision retains canonical name')
        require(receipt(f, remove(f, b, 4, observed(2, True)))['disposition'] == 'applied', 'Delete blocking tag')
        require(receipt(f, edit(f, rename, 5, name('BETA'), predecessor(rename, name('BETA'))))['disposition'] == 'held', 'Freed name never silently applies held rename')
        require(receipt(f, edit(f, a, 6, name('BETA')))['disposition'] == 'applied', 'Explicit fresh observed edit can take available name')
        require(receipt(f, edit(f, a, 7, name('BETA')))['fields'][0]['disposition'] == 'equivalent', 'Equivalent stale same-name group')
        require(len(tags(f)) == 2 and tags(f)[0]['creation_operation'] in (a, b), 'Original identities persist')
        require(receipt(f, tag(f, 8, name('Third'), a['entity']['key'][0]))['disposition'] == 'conflict', 'Same UUID create cannot merge')
        passed_check('rename collisions, available-name reuse, held-before-equivalence and same-UUID create conflict')

        for delete_first in (True, False):
            f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
            change, delete = edit(f, a), remove(f, a)
            delete['device_epoch'] = uid(); f.register(delete['device_epoch'])
            delete['sequence'] = 1
            if delete_first:
                receipt(f, delete); require(receipt(f, change)['fields'][0]['disposition'] == 'recovery', 'Hidden edit recoverable')
            else:
                receipt(f, change); receipt(f, delete)
            row = tags(f)[0]
            require(row['fields']['existence']['value'] is False and ledger(f)[0]['operation'] == delete, 'Deletion dominates both orders')
            require(receipt(f, tag(f, 3, name('Work')))['disposition'] == 'applied', 'Deleted name can be used by new UUID')
            require(receipt(f, tag(f, 4, name('Other'), a['entity']['key'][0]))['disposition'] == 'conflict', 'Deleted UUID never recreated')
            require(receipt(f, remove(f, a, 5))['fields'][0]['disposition'] == 'recovery', 'Repeated delete retains first identity')
            require(len(ledger(f)) == 1, 'Only winning delete ledger')
        passed_check('both delete/edit arrival orders, recoverable late edits, name reuse without resurrection')

        f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
        deletion = remove(f, a); f.apply(deletion)
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; delete from sync_private.change_log where owner_id='{f.owner}';")
        before = state(f)
        require(f.apply(a)['result']['results'][0]['kind'] == 'already_processed' and state(f) == before, 'Consumed create cannot replay')
        for original in (a, deletion):
            forged = f.create(3); forged['operation_id'] = original['operation_id']
            require(f.apply(forged)['code'] == 'payloadMismatch' and state(f) == before, 'Creation/deletion identity survives receipt/log expiry')
        passed_check('durable creation/deletion operation identity prevents reassignment after receipt and log expiry')

        f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
        cases = json.loads((ROOT / 'test/fixtures/tag-name-validation.json').read_text(encoding='utf-8'))
        seq = 2
        for case in cases:
            if case['valid']: continue
            op = edit(f, a, seq); op['patches']['name']['value'] = case['value']
            require(receipt(f, op)['rejection_code'] == 'invalid_tag_name', 'Invalid atomic name rejected without write')
            seq += 1
        for op in (tag(f, seq), edit(f, a, seq + 1), remove(f, a, seq + 2)):
            if op['command'] == 'tag.create': del op['patches']['name']
            elif op['command'] == 'tag.edit': op['patches']['existence'] = {'base': observed(1, True), 'value': False}
            else: op['patches']['name'] = {'base': observed(1, name('Work')), 'value': name('Other')}
            require(receipt(f, op)['disposition'] == 'rejected', 'Invalid command mixture is atomic')
        seq += 3
        require(tags(f)[0]['fields']['name']['value'] == name('Work'), 'Semantic failures preserve tag')
        require(receipt(f, f.create(seq))['disposition'] == 'applied', 'Rejected commands consume contiguous sequence')
        passed_check('shared invalid name groups and atomic command rejection with later unrelated progress')

        f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
        before = state(f)
        for path, value in [('protocol_version', None), ('entity', {'kind': 'task', 'key': a['entity']['key']}), ('sequence', 0), ('provenance', None)]:
            op = edit(f, a); op[path] = value
            code, _ = backend.request('POST', '/rest/v1/rpc/sync_apply', f.token, {'request': f.request(op)})
            require(code == 400 and state(f) == before, 'Malformed tag preflight consumes nothing')
        for mode in ('dependency', 'unsupported', 'view'):
            op = edit(f, a)
            if mode == 'dependency': op['dependencies'] = [{'entity': a['entity'], 'operation_id': a['operation_id'], 'sequence': 1, 'group': 'existence'}]
            elif mode == 'unsupported': op['patches']['title'] = {'base': {'kind': 'absent'}, 'value': 'Bad'}
            else:
                op['command'] = 'view.restore'; op['entity'] = {'kind': 'view', 'key': [f.task]}
                op['patches'] = {'name': {'base': {'kind': 'absent'}, 'value': 'View'}}
            require(f.apply(op)['code'] == 'unsupportedProtocol' and state(f) == before, 'Unsupported capability remains preflight-gated')
        passed_check('strict tag preflight, unsupported dependencies/groups and view-restoration gate')

        f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
        missing = deepcopy(a); missing['operation_id'] = uid()
        require(receipt(f, edit(f, a, 2, name('Later'), predecessor(missing, name('Work'))))['fields'][0]['disposition'] == 'recovery', 'Missing predecessor cannot authorize')
        task = f.create(3); f.apply(task)
        require(receipt(f, edit(f, a, 4, name('Later'), predecessor(task, name('Work'))))['fields'][0]['disposition'] == 'recovery', 'Wrong entity/group cannot bind')
        require(receipt(f, edit(f, a, 5, name('Later'), observed(1, name('Forged'))))['fields'][0]['disposition'] == 'recovery', 'Corrupt original base remains recovery')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
        require(receipt(f, edit(f, a, 6, name('Later'), predecessor(a, name('Work'))))['fields'][0]['disposition'] == 'recovery', 'Expired receipt never guesses revision from creation ledger')
        require(tags(f)[0]['fields']['name']['value'] == name('Work'), 'Failed predecessors preserve canonical tag')
        passed_check('exact predecessor entity/group/identity binding and original-base recovery')

        f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
        other = TaskFixture(backend, epoch)
        b = tag(other, identity=a['entity']['key'][0]); other.apply(b)
        before = state(f)
        receipt(other, edit(other, b)); receipt(other, remove(other, b, 3))
        require(state(f) == before, 'Same UUID/name independent in X/Y')
        for table in ('tag_shadow', 'tag_deletions'):
            require(sql(f"select relrowsecurity and relforcerowsecurity from pg_class where oid='sync_private.{table}'::regclass;") == 't', 'Forced RLS')
            for token in (None, f.token, other.token):
                code, _ = backend.request('GET', '/rest/v1/' + table, token, headers={'Accept-Profile': 'sync_private'})
                require(code in (401, 403, 404, 406), 'Private table inaccessible via REST')
            require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                        f"select count(*) from sync_private.{table} where owner_id='{f.owner}'; rollback;").splitlines()[-1] == '0', 'RPC role cannot read another owner')
        require(sql("select not has_column_privilege('dourstuff_rpc','sync_private.tag_shadow','owner_id','UPDATE') "
                    "and not has_column_privilege('dourstuff_rpc','sync_private.tag_shadow','tag_id','UPDATE') "
                    "and not has_column_privilege('dourstuff_rpc','sync_private.tag_shadow','creation_operation','UPDATE') "
                    "and not has_table_privilege('dourstuff_rpc','sync_private.tag_deletions','UPDATE,DELETE');") == 't', 'Immutable identity and append-only ledger grants')
        passed_check('same-UUID account isolation, forced RLS, private REST denial and immutable identity grants')

        for competing_delete in (True, False):
            f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
            rival = uid(); f.register(rival)
            deletion = remove(f, a)
            competing = remove(f, a, 1) if competing_delete else edit(f, a, 1)
            competing['device_epoch'] = rival
            with ThreadPoolExecutor(max_workers=2) as pool:
                results = list(pool.map(lambda op: receipt(f, op), (deletion, competing)))
            require(len(ledger(f)) == 1 and tags(f)[0]['fields']['existence']['value'] is False, 'Concurrent deletion keeps a single permanent identity')
            if competing_delete:
                require(sorted(r['disposition'] for r in results) == ['applied', 'conflict'], 'Only first deletion applies')
            else:
                require(results[0]['disposition'] == 'applied', 'Concurrent rename cannot prevent deletion')
        for reverse in (False, True):
            f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
            left, right = edit(f, a, value=name('Left')), edit(f, a, 1, name('Right'))
            right['device_epoch'] = uid(); f.register(right['device_epoch'])
            first, last = (right, left) if reverse else (left, right)
            require(receipt(f, first)['disposition'] == 'applied' and receipt(f, last)['disposition'] == 'conflict', 'Concurrent same-tag names preserve whole groups')
            require(tags(f)[0]['fields']['name']['value'] == first['patches']['name']['value'], 'No hybrid display/key group')
            require(candidates(f)[0]['operation'] == last, 'Losing original name/base unchanged')
        passed_check('simultaneous deletion/edit and both same-tag rename orderings preserve atomic groups')

        f = TaskFixture(backend, epoch)
        samples = [('İ', 'i'), ('ΟΣ', 'οσ'), ('𐐀', '𐐨'), ('CAFÉ', 'café'), ('Cafe\u0301', 'cafe\u0301'), ('A\u0085B', 'a\u0085b'), ('A B', 'a b')]
        for seq, (display, key) in enumerate(samples, 1):
            require(receipt(f, tag(f, seq, name(display, key)))['disposition'] == 'applied', 'Pinned Unicode name accepted unchanged')
        require(len(tags(f)) == len(samples), 'Canonical forms and internal NEL remain distinct UUIDs')
        require(receipt(f, tag(f, len(samples) + 1, name('i')))['disposition'] == 'conflict', 'Pinned dotted-I collision reaches actual RPC')
        other = TaskFixture(backend, epoch)
        before = state(f)
        fields = literal(json.dumps(tags(f)[0]['fields']))
        creation = literal(json.dumps(tag(other)))
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
            f"update sync_private.tag_shadow set fields=fields where owner_id='{f.owner}'; "
            "do $test$ begin begin insert into sync_private.tag_shadow(owner_id,tag_id,fields,creation_operation) "
            f"values ('{f.owner}','{uid()}',{fields}::jsonb,{creation}::jsonb); "
            "raise exception 'Foreign tag insert allowed'; exception when insufficient_privilege then null; end; end $test$; rollback;").splitlines() == ['t']
            and state(f) == before, 'Real RLS blocks cross-owner update/insert')
        for token in (None, f.token, other.token):
            for table in ('tag_shadow', 'tag_deletions'):
                for method in ('POST', 'PATCH', 'DELETE'):
                    code, _ = backend.request(method, '/rest/v1/' + table, token, {})
                    require(code in (401, 403, 404), 'No raw tag table writes')
        passed_check('real Unicode collision/distinction and adversarial cross-owner insert/update/REST writes')

        f = TaskFixture(backend, epoch); a = tag(f); f.apply(a)
        rename, delete = edit(f, a), remove(f, a, 3)
        before = state(f)
        sql("create function sync_private.test_tag_fail() returns trigger language plpgsql as $$ "
            "begin if new.revision=3 then raise exception 'Injected tag failure'; end if; return new; end $$; "
            "create trigger test_tag_fail before insert on sync_private.change_log for each row execute function sync_private.test_tag_fail();")
        try:
            code, _ = backend.request('POST', '/rest/v1/rpc/sync_apply', f.token, {'request': f.request(rename, delete)})
            require(code == 400 and state(f) == before, 'Rename/delete/ledger/receipt/recovery/log/watermark rollback')
        finally:
            sql('drop trigger test_tag_fail on sync_private.change_log; drop function sync_private.test_tag_fail();')
        require(all(r['disposition'] == 'applied' for r in f.apply(rename, delete)['result']['results']), 'Original sequence retries successfully after rollback')
        passed_check('injected second-log-write failure rolls back rename and deletion batch atomically')
        print(f'{passed} tag-command integration groups passed.')
    finally:
        backend.cleanup()
        if args.wire_output:
            args.wire_output.parent.mkdir(parents=True, exist_ok=True)
            args.wire_output.write_text(json.dumps(backend.wire), encoding='utf-8')


if __name__ == '__main__':
    main()
