"""Real local exact-pair membership bases, parent dependencies and visibility."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, literal, require, sql
from test_backend_milestone_create import receipt
from test_backend_tag_commands import tag, name, remove as delete_tag, state as tag_state
from test_backend_task_create import TaskFixture
from test_backend_task_delete import deletion
from test_backend_task_restore import restore

ROOT = Path(__file__).resolve().parents[1]


def dependency(op):
    return {'entity': deepcopy(op['entity']), 'operation_id': op['operation_id'],
            'sequence': op['sequence'], 'group': 'existence'}


def membership(f, source, seq=3, value=True, base=None, parents=(), task=None):
    op = f.op(seq, value, {'kind': 'absent'} if base is None else base, group='membership')
    op['command'] = 'task.tag'
    op['entity'] = {'kind': 'membership', 'key': [task or f.task, source['entity']['key'][0]]}
    op['dependencies'] = [dependency(parent) for parent in parents]
    return op


def rows(f, table='membership_shadow'):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(m) order by to_jsonb(m)::text),'[]') "
                         f"from sync_private.{table} m where owner_id='{f.owner}';"))


def state(f):
    return tag_state(f), rows(f), rows(f, 'membership_changes')


def visible(f, op):
    task, tag_id = op['entity']['key']
    return sql(f"begin; set local role dourstuff_rpc; "
               f"select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
               f"select sync_private.membership_visible('{task}','{tag_id}'); rollback;").splitlines()[-1] == 't'


def parents(backend, epoch):
    f = TaskFixture(backend, epoch)
    task, label = f.create(), tag(f, 2)
    f.apply(task, label)
    return f, task, label


def candidate_smoke(backend, epoch):
    f, task, label = parents(backend, epoch)
    before = tag_state(f)
    add = membership(f, label, parents=(task, label))
    remove = membership(f, label, 4, False, predecessor(add, True))
    again = membership(f, label, 5, True, predecessor(remove, False))
    source = 'begin;\n' + (ROOT / 'supabase/migrations/20261025080938_task_tag_memberships.sql').read_text(encoding='utf-8')
    source += (f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
               'select public.sync_apply(' + literal(json.dumps(f.request(add, remove, again))) + '::jsonb); rollback;')
    result = json.loads(sql(source).splitlines()[-1])
    require([r['disposition'] for r in result['result']['results']] == ['applied'] * 3,
            'Candidate real-owner dependent add/remove/re-add')
    require(tag_state(f) == before, 'Candidate preserves exact retained parents/history/receipt/watermark')
    require(sql("select to_regclass('sync_private.membership_shadow') is null;") == 't', 'Candidate schema rollback')
    print('PASS: candidate migration, exact dependencies/add/remove/re-add and retained-data rollback', flush=True)


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
        fixture = json.loads((ROOT / 'test/fixtures/account-protocol-v2-memberships.json').read_text(encoding='utf-8'))
        f = TaskFixture(backend, epoch)
        ops = fixture['operations']
        f.device, f.task = ops[0]['device_epoch'], ops[0]['entity']['key'][0]
        f.register(f.device)
        result = f.apply(*ops)
        require(all(r['disposition'] == 'applied' for r in result['result']['results']), 'Shared atomic parents/add/remove/re-add')
        require(rows(f)[0]['fields'] == {'membership': {'revision': 5, 'value': True}}, 'Independent canonical boolean revision')
        require(visible(f, ops[2]) and len(f.history()) == 1, 'Kind-qualified same UUID and no membership task history')
        require([r['operation'] for r in sorted(rows(f, 'membership_changes'), key=lambda r: r['revision'])] == ops[2:], 'Original accepted envelopes retained')
        require(f.pull()['groups'][-1]['records'][0]['entity'] == ops[-1]['entity'], 'Composite identity in pull')
        before = state(f)
        with ThreadPoolExecutor(max_workers=2) as pool:
            require(list(pool.map(lambda _: f.apply(*ops), range(2))) == [result, result], 'Concurrent lost-reply retries')
        require(state(f) == before, 'Retries leave all state unchanged')
        changed = deepcopy(ops[-1]); changed['entity']['key'][1] = uid()
        require(f.apply(changed)['code'] == 'payloadMismatch' and state(f) == before, 'Retry cannot redirect tag UUID')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; delete from sync_private.change_log where owner_id='{f.owner}';")
        before = state(f)
        require(f.apply(ops[-1])['result']['results'][0]['kind'] == 'already_processed', 'Expired reply never replays')
        for original in ops[2:]:
            changed = deepcopy(original); changed['sequence'] = 6
            require(f.apply(changed)['code'] == 'payloadMismatch', 'Add/remove identity outlives receipt expiry')
        require(state(f) == before, 'Expiry/mismatch does not mutate')
        passed_check('shared atomic fixture, composite pull, immutable add/remove payloads and expired retry identities')

        # Concurrent first add/remove from absence: whichever is first stays;
        # the opposite value retains its original absent candidate.
        for reverse in (False, True):
            f, task, label = parents(backend, epoch)
            add, remove = membership(f, label), membership(f, label, 1, False)
            remove['device_epoch'] = uid(); f.register(remove['device_epoch'])
            first, last = (remove, add) if reverse else (add, remove)
            require(receipt(f, first)['disposition'] == 'applied', 'First absent membership command')
            require(receipt(f, last)['fields'][0]['disposition'] == 'conflict', 'Opposite absent value conflicts')
            require(rows(f)[0]['fields']['membership']['value'] == first['patches']['membership']['value'], 'First accepted pair preserved')
            recovery = f.pull()['groups'][-1]['recovery'][0]
            require(recovery['operation'] == last, 'Original losing payload/base retained')
            successor = membership(f, label, last['sequence'] + 1, first['patches']['membership']['value'],
                                   predecessor(last, last['patches']['membership']['value']))
            successor['device_epoch'] = last['device_epoch']
            require(receipt(f, successor)['disposition'] == 'held', 'Held predecessor before equivalent boolean')
            sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
            follow = membership(f, label, successor['sequence'] + 1, True, predecessor(successor, successor['patches']['membership']['value']))
            follow['device_epoch'] = successor['device_epoch']
            require(receipt(f, follow)['disposition'] == 'held', 'Durable held own-field chain survives expiry')
        passed_check('both add/remove arrival orders retain original bases and held successors through expiry')

        f, task, label = parents(backend, epoch)
        add = membership(f, label); receipt(f, add)
        other_label = tag(f, 4, name('Other')); receipt(f, other_label)
        independent = membership(f, other_label, 5)
        remove = membership(f, label, 1, False, observed(3, True)); remove['device_epoch'] = uid(); f.register(remove['device_epoch'])
        with ThreadPoolExecutor(max_workers=2) as pool:
            require(all(r['disposition'] == 'applied' for r in pool.map(lambda op: receipt(f, op), (independent, remove))), 'Independent pairs merge')
        require(visible(f, independent) and not visible(f, add), 'Separate tag membership values')
        stale = membership(f, label, 6, True, observed(3, True))
        require(receipt(f, stale)['disposition'] == 'conflict', 'Stale add cannot undo newer remove')
        current = next(r['fields']['membership'] for r in rows(f) if r['tag_id'] == label['entity']['key'][0])
        wrong = membership(f, label, 7, True, observed(current['revision'], True))
        require(receipt(f, wrong)['fields'][0]['disposition'] == 'recovery', 'Exact revision with false original value rejected')
        again = membership(f, label, 8, True, observed(current['revision'], False))
        require(receipt(f, again)['disposition'] == 'applied', 'Observed remove can explicitly re-add')
        equivalent = membership(f, label, 9, True)
        count = len(rows(f, 'membership_changes'))
        require(receipt(f, equivalent)['fields'][0]['disposition'] == 'equivalent', 'Equivalent value retains accepted revision')
        require(len(rows(f, 'membership_changes')) == count, 'Equivalent creates no mutation ledger event')
        passed_check('independent pair races, stale add rejection, exact original bases, re-add and equivalence')

        for value in (True, False):
            f, task, label = parents(backend, epoch)
            left = membership(f, label, value=value)
            right = membership(f, label, 1, not value); right['device_epoch'] = uid(); f.register(right['device_epoch'])
            with ThreadPoolExecutor(max_workers=2) as pool:
                results = list(pool.map(lambda op: receipt(f, op), (left, right)))
            require(sorted(r['disposition'] for r in results) == ['applied', 'conflict'], 'Account lock serializes simultaneous opposite commands')
            require(len(rows(f)) == 1 and len(rows(f, 'membership_changes')) == 1, 'One canonical pair/change')
        passed_check('simultaneous same-pair add/remove serializes one accepted candidate')

        for parent_kind in ('task', 'tag'):
            f, task, label = parents(backend, epoch)
            collision = f.create(3) if parent_kind == 'task' else tag(f, 3, name('WORK'))
            child_label = label if parent_kind == 'task' else collision
            child = membership(f, child_label, 4, parents=(collision,))
            unrelated = f.op(5, 'Unrelated')
            replies = f.apply(collision, child, unrelated)['result']['results']
            require([r['disposition'] for r in replies] == ['conflict', 'held', 'applied'], 'Exact conflicted parent holds membership and allows progress')
            require(rows(f) == [] and f.pull()['groups'][3]['recovery'][0]['operation'] == child, 'No partial membership/UUID redirect')
            successor = membership(f, child_label, 6, False, predecessor(child, True))
            # No canonical tag for a collision: explicit dependency keeps parent held.
            successor['dependencies'] = child['dependencies']
            require(receipt(f, successor)['disposition'] == 'held', 'Held dependency precedes membership equivalence/absence')
        passed_check('task and collided-tag dependencies hold complete memberships while unrelated sequences advance')

        f, task, label = parents(backend, epoch)
        seq = 3
        variants = []
        for field, value in [('operation_id', uid()), ('sequence', 2), ('entity', label['entity'])]:
            deps = [dependency(task)]; deps[0][field] = value; variants.append(deps)
        variants += [[dependency(task), dependency(task)]]
        for deps in variants:
            op = membership(f, label, seq); op['dependencies'] = deps; seq += 1
            require(receipt(f, op)['fields'][0]['disposition'] == 'recovery', 'Mismatched/duplicate exact parent evidence')
        foreign_device = uid(); f.register(foreign_device)
        wrong_device = membership(f, label, 3, parents=(task, label)); wrong_device['device_epoch'] = foreign_device
        # Seed two unrelated commands on that device; same sequence is not proof.
        for number in (1, 2):
            op = f.create(number, task=uid()); op['device_epoch'] = foreign_device; receipt(f, op)
        require(receipt(f, wrong_device)['fields'][0]['disposition'] == 'recovery', 'Parent receipt cannot bind across devices')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}' and operation_id='{label['operation_id']}';")
        expired = membership(f, label, seq, parents=(label,)); seq += 1
        require(receipt(f, expired)['fields'][0]['disposition'] == 'recovery', 'Expired accepted dependency cannot guess base')
        valid = membership(f, label, seq)
        require(receipt(f, valid)['disposition'] == 'applied', 'Observed live parents need no invented dependency')
        passed_check('exact parent operation/sequence/kind/device binding, duplicate and expired evidence recovery')

        # A held first dependency must not hide a bad second dependency.
        for reverse in (False, True):
            f, task, label = parents(backend, epoch)
            collision = f.create(3); receipt(f, collision)
            deps = [dependency(collision), dependency(label)]
            deps[1]['operation_id'] = uid()
            if reverse: deps.reverse()
            op = membership(f, label, 4); op['dependencies'] = deps
            require(receipt(f, op)['fields'][0]['disposition'] == 'recovery', 'Validate every dependency regardless of array order')
        passed_check('dependency ordering cannot conceal mismatched evidence behind a held parent')

        f, task, label = parents(backend, epoch)
        add = membership(f, label); receipt(f, add)
        second = tag(f, 4, name('Second')); receipt(f, second)
        mismatches = [predecessor(add, False), predecessor(task, True),
                      {'kind': 'predecessor', 'operation_id': uid(), 'sequence': 3, 'value': True},
                      {'kind': 'predecessor', 'operation_id': add['operation_id'], 'sequence': 2, 'value': True}]
        for seq, base in enumerate(mismatches, 5):
            op = membership(f, label, seq, False, base)
            require(receipt(f, op)['fields'][0]['disposition'] == 'recovery', 'Same-pair predecessor binds exact original result/identity')
        wrong_pair = membership(f, second, 9, False, predecessor(add, True))
        require(receipt(f, wrong_pair)['fields'][0]['disposition'] == 'recovery', 'Different tag pair cannot borrow predecessor')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}' and operation_id='{add['operation_id']}';")
        expired = membership(f, label, 10, False, predecessor(add, True))
        require(receipt(f, expired)['fields'][0]['disposition'] == 'recovery', 'Accepted ledger is not substituted for missing receipt/base')
        require(visible(f, add) and len(rows(f)) == 1, 'Bad predecessor cannot remove or fabricate pair')
        passed_check('exact membership predecessor value/entity/group/operation/sequence and expired evidence')

        for parent_kind in ('task', 'tag'):
            for delete_first in (False, True):
                f, task, label = parents(backend, epoch)
                add = membership(f, label)
                deleted = deletion(f, 3) if parent_kind == 'task' else delete_tag(f, label, 3, observed(2, True))
                if delete_first:
                    add['sequence'] = 4; receipt(f, deleted)
                    require(receipt(f, add)['fields'][0]['disposition'] == 'recovery', 'Late add preserved but hidden')
                    require(rows(f) == [], 'Late add cannot fabricate a canonical relationship')
                else:
                    deleted['sequence'] = 4; receipt(f, add); receipt(f, deleted)
                    require(rows(f)[0]['fields']['membership'] == {'revision': 3, 'value': True}, 'Parent delete never rewrites membership/base')
                require(not visible(f, add), 'Either parent suppresses membership')
                # Explicit remove works under a tombstone, including first false record.
                removed = membership(f, label, 5, False, None if delete_first else observed(3, True))
                require(receipt(f, removed)['disposition'] == 'applied', 'Independent hidden remove')
                if parent_kind == 'task':
                    restored = restore(f, deleted, 6, revision=deleted['sequence'])
                    require(receipt(f, restored)['disposition'] == 'applied', 'Restore exact task deletion')
                    require(not visible(f, add) and rows(f)[0]['fields']['membership']['value'] is False, 'Task restore preserves independent remove')
                else:
                    replacement = tag(f, 6); receipt(f, replacement)
                    require(replacement['entity'] != label['entity'] and not visible(f, add), 'Same-name replacement never redirects old pair')
                    fresh = membership(f, replacement, 7); require(receipt(f, fresh)['disposition'] == 'applied', 'Explicit new-UUID membership independent')
                    require(len(rows(f)) == 2 and visible(f, fresh), 'Old removed pair retained beside new pair')
        passed_check('both parent deletion/add orders, hidden removals, task restore and no same-name UUID redirect')

        f, task, label = parents(backend, epoch)
        add = membership(f, label); receipt(f, add)
        gone = deletion(f, 4); receipt(f, gone)
        receipt(f, restore(f, gone, 5, revision=4))
        require(visible(f, add) and rows(f)[0]['fields']['membership']['revision'] == 3, 'Restore reveals unchanged retained membership')
        passed_check('parent restore reveals unchanged membership without replay or rebasing')

        f, task, label = parents(backend, epoch)
        invalid_values = [None, 0, 1, 'true', [], {}]
        seq = 3
        for value in invalid_values:
            op = membership(f, label, seq, value); seq += 1
            require(receipt(f, op)['rejection_code'] == 'invalid_membership', 'Invalid membership receives consumed rejection')
        op = membership(f, label, seq, True, observed(1, 'true')); seq += 1
        require(receipt(f, op)['rejection_code'] == 'invalid_membership', 'Original base must be boolean')
        op = membership(f, label, seq, parents=(task, label, task)); seq += 1
        require(receipt(f, op)['rejection_code'] == 'invalid_parent_dependencies', 'Too many dependencies consumed rejection')
        require(rows(f) == [], 'Semantic rejection writes no membership')
        good = membership(f, label, seq)
        malformed = []
        bad = deepcopy(good); bad['entity']['key'].pop(); malformed.append(bad)
        bad = deepcopy(good); bad['entity']['key'].append(uid()); malformed.append(bad)
        bad = deepcopy(good); bad['entity']['key'][1] = 'bad'; malformed.append(bad)
        bad = deepcopy(good); bad['dependencies'] = [dependency(task)]; bad['dependencies'][0]['sequence'] = seq; malformed.append(bad)
        bad = deepcopy(good); bad['dependencies'] = [dependency(task)]; bad['dependencies'][0]['group'] = 'name'; malformed.append(bad)
        bad = deepcopy(good); del bad['provenance']; malformed.append(bad)
        for bad in malformed:
            before = state(f)
            code, _ = backend.request('POST', '/rest/v1/rpc/sync_apply', f.token, {'request': f.request(bad)})
            require(code == 400 and state(f) == before, 'Malformed envelope fails preflight without progress')
        require(receipt(f, good)['disposition'] == 'applied', 'Valid sequence survives malformed attempts')
        passed_check('boolean/base/dependency semantic rejections and malformed composite envelope preflight')

        f, task, label = parents(backend, epoch)
        add = membership(f, label); receipt(f, add)
        other, other_task, other_label = parents(backend, epoch)
        before = state(f)
        foreign_tag = membership(other, label)
        require(receipt(other, foreign_tag)['fields'][0]['disposition'] == 'recovery', 'Foreign tag cannot be referenced')
        foreign_task = membership(other, other_label, 4, task=f.task)
        require(receipt(other, foreign_task)['fields'][0]['disposition'] == 'recovery', 'Foreign task cannot be referenced')
        same_task = other.create(5, task=f.task)
        same_tag = tag(other, 6, name('Shared identity'), identity=label['entity']['key'][0])
        other.apply(same_task, same_tag)
        own_pair = membership(other, same_tag, 7, False, task=f.task)
        require(receipt(other, own_pair)['disposition'] == 'applied' and state(f) == before, 'Same UUID pair remains owner qualified')
        for table in ('membership_shadow', 'membership_changes'):
            require(sql(f"select relrowsecurity and relforcerowsecurity from pg_class where oid='sync_private.{table}'::regclass;") == 't', 'Forced RLS')
            for token in (None, f.token, other.token):
                code, _ = backend.request('GET', '/rest/v1/' + table, token, headers={'Accept-Profile': 'sync_private'})
                require(code in (401, 403, 404, 406), 'Private REST read denied')
                for method in ('POST', 'PATCH', 'DELETE'):
                    code, _ = backend.request(method, '/rest/v1/' + table, token, {})
                    require(code in (401, 403, 404), 'Raw API mutation denied')
            require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                        f"select count(*) from sync_private.{table} where owner_id='{f.owner}'; rollback;").splitlines()[-1] == '0', 'RPC role X/Y read isolation')
        require(sql("select not has_column_privilege('dourstuff_rpc','sync_private.membership_shadow','task_id','UPDATE') "
                    "and not has_column_privilege('dourstuff_rpc','sync_private.membership_shadow','tag_id','UPDATE') "
                    "and not has_column_privilege('dourstuff_rpc','sync_private.membership_shadow','owner_id','UPDATE') "
                    "and not has_table_privilege('dourstuff_rpc','sync_private.membership_changes','UPDATE,DELETE');") == 't', 'Immutable pair/owner and append-only identity grants')
        fields = literal(json.dumps(rows(f)[0]['fields']))
        sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true); "
            f"update sync_private.membership_shadow set fields=fields where owner_id='{f.owner}'; "
            "do $test$ begin begin insert into sync_private.membership_shadow(owner_id,task_id,tag_id,fields) "
            f"values ('{f.owner}','{f.task}','{label['entity']['key'][0]}',{fields}::jsonb); "
            "raise exception 'Foreign membership insert allowed'; exception when insufficient_privilege then null; end; end $test$; rollback;")
        require(state(f) == before, 'RLS cross-owner update/insert preserves X')
        passed_check('foreign parents, same-pair X/Y isolation, forced RLS/REST and immutable identity grants')

        f, task, label = parents(backend, epoch)
        add = membership(f, label)
        remove = membership(f, label, 4, False, predecessor(add, True))
        before = state(f)
        sql("create function sync_private.test_membership_fail() returns trigger language plpgsql as $$ "
            "begin if new.revision=4 then raise exception 'Injected membership failure'; end if; return new; end $$; "
            "create trigger test_membership_fail before insert on sync_private.change_log for each row execute function sync_private.test_membership_fail();")
        try:
            code, _ = backend.request('POST', '/rest/v1/rpc/sync_apply', f.token, {'request': f.request(add, remove)})
            require(code == 400 and state(f) == before, 'Pair/ledger/receipt/recovery/log/watermark entire batch rollback')
        finally:
            sql('drop trigger test_membership_fail on sync_private.change_log; drop function sync_private.test_membership_fail();')
        require(all(r['disposition'] == 'applied' for r in f.apply(add, remove)['result']['results']), 'Original batch retries after rollback')
        passed_check('injected second-log failure rolls back complete add/remove batch')
        print(f'{passed} membership integration groups passed.', flush=True)
    finally:
        backend.cleanup()
        if args.wire_output:
            args.wire_output.parent.mkdir(parents=True, exist_ok=True)
            args.wire_output.write_text(json.dumps(backend.wire), encoding='utf-8')


if __name__ == '__main__':
    main()
