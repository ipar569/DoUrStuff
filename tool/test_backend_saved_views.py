"""Real local saved-query/default-reference transactions; synthetic owners only."""
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
from test_backend_memberships import dependency
from test_backend_task_create import TaskFixture

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20261026071200_saved_views_preferences.sql'
TABLES = ('view_shadow', 'view_deletions', 'preference_shadow', 'preference_changes')


def query(**changes):
    return dict(version=1, search='', builtIn='all', statuses=[], priorities=[], tags=[],
                allTags=False, **{'from': None, 'to': None}, undated=False, overdue=False,
                group='none', sort='due', descending=False) | changes


def view(f, seq=1, identity=None, name='Work', spec=None):
    op = f.op(seq, name)
    op['command'] = 'view.create'
    op['entity'] = {'kind': 'view', 'key': [identity or uid()]}
    op['patches'] = {k: {'base': {'kind': 'absent'}, 'value': v}
                     for k, v in dict(name=name, query=query() if spec is None else spec, existence=True).items()}
    return op


def edit(f, source, seq=2, value='Renamed', base=None, group='name'):
    op = f.op(seq, value, observed(1, source['patches'][group]['value']) if base is None else base, group=group)
    op['command'], op['entity'] = 'view.edit', deepcopy(source['entity'])
    return op


def delete(f, source, seq=2, base=None):
    op = edit(f, source, seq, False, observed(1, True) if base is None else base, 'existence')
    op['command'] = 'view.delete'
    return op


def preference(f, seq, value=None, base=None, parent=None):
    op = f.op(seq, value, {'kind': 'absent'} if base is None else base, group='value')
    op['command'], op['entity'] = 'preference.set', {'kind': 'preference', 'key': ['default_view']}
    op['dependencies'] = [] if parent is None else [dependency(parent)]
    return op


def rows(f, table):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(r) order by to_jsonb(r)::text),'[]') "
                         f"from sync_private.{table} r where owner_id='{f.owner}';"))


def fields(f, source):
    return next(r['fields'] for r in rows(f, 'view_shadow') if r['view_id'] == source['entity']['key'][0])


def default(f):
    found = rows(f, 'preference_shadow')
    return None if not found else found[0]['fields']['value']


def state(f):
    return f.state(), f.history(), [rows(f, table) for table in TABLES]


def candidate_smoke(backend, epoch):
    f = TaskFixture(backend, epoch)
    f.apply(f.create())
    before = f.state(), f.history()
    a = view(f, 2)
    selected = preference(f, 3, a['entity']['key'][0], parent=a)
    renamed = edit(f, a, 4, base=predecessor(a, 'Work'))
    removed = delete(f, a, 5, predecessor(a, True))
    source = 'begin;\n' + MIGRATION.read_text(encoding='utf-8')
    source += (f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
               'select public.sync_apply(' + literal(json.dumps(f.request(a, selected, renamed, removed))) + '::jsonb); rollback;')
    result = json.loads(sql(source).splitlines()[-1])
    require([r['disposition'] for r in result['result']['results']] == ['applied'] * 4, 'Candidate create/select/rename/delete')
    require((f.state(), f.history()) == before, 'Exact retained task/history/receipt/watermark rollback')
    require(sql("select to_regclass('sync_private.view_shadow') is null;") == 't', 'Candidate schema rollback')
    print('PASS: candidate real-owner create/select/rename/delete and retained-state rollback', flush=True)


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
        fixture = json.loads((ROOT / 'test/fixtures/account-protocol-v2-saved-views.json').read_text())
        f = TaskFixture(backend, epoch)
        ops = fixture['operations']
        f.device = ops[0]['device_epoch']; f.register(f.device)
        result = f.apply(*ops)
        require([r['disposition'] for r in result['result']['results']] == ['applied'] * len(ops), 'Shared fixture applies')
        require(default(f) == {'revision': 5, 'value': None}, 'Delete clears default at same revision')
        require(fields(f, ops[0])['name'] == {'revision': 3, 'value': 'Renamed'}, 'Independent name revision')
        require(fields(f, ops[0])['query'] == {'revision': 4, 'value': query(search='Focus')}, 'Atomic query revision')
        group = f.pull()['groups'][-1]
        require(len(group['records']) == 2 and group['revision'] == 5, 'Deletion and clear share one pull group')
        require(group['records'][1]['entity'] == ops[1]['entity'] and not f.history(), 'Preference key identity and no task history')
        before = state(f)
        with ThreadPoolExecutor(max_workers=2) as pool:
            require(list(pool.map(lambda _: f.apply(*ops), range(2))) == [result, result], 'Concurrent lost response retries')
        require(state(f) == before, 'Retries do not mutate')
        changed = deepcopy(ops[0]); changed['patches']['name']['value'] = 'Changed'
        require(f.apply(changed)['code'] == 'payloadMismatch', 'Immutable creation retry')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; delete from sync_private.change_log where owner_id='{f.owner}';")
        before = state(f)
        for original in (ops[0], ops[1], ops[-1]):
            changed = deepcopy(original); changed['sequence'] = 6
            require(f.apply(changed)['code'] == 'payloadMismatch', 'Creation/selection/deletion identity survives expiry')
        require(f.apply(ops[-1])['result']['results'][0]['kind'] == 'already_processed', 'Expired delete never repeats clear')
        require(state(f) == before, 'Expiry checks preserve canonical state')
        passed_check('shared atomic fixture, pull grouping, duplicate/lost replies and retained operation identities')

        # Name and query merge independently, but query filters are one unit.
        for reverse in (False, True):
            f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
            rename = edit(f, a)
            update = edit(f, a, 1, query(search='Focus'), group='query')
            update['device_epoch'] = uid(); f.register(update['device_epoch'])
            for op in ((update, rename) if reverse else (rename, update)):
                require(receipt(f, op)['disposition'] == 'applied', 'Independent name/query merge')
            require(fields(f, a)['name']['value'] == 'Renamed' and fields(f, a)['query']['value'] == query(search='Focus'), 'Both independent edits preserved')
            competing = edit(f, a, 3, query(group='priority'), group='query')
            require(receipt(f, competing)['fields'][0]['disposition'] == 'conflict', 'Whole query conflict')
            require(f.pull()['groups'][-1]['recovery'][0]['operation'] == competing, 'Original complete query/base retained')
            held = edit(f, a, 4, query(), predecessor(competing, query(group='priority')), 'query')
            require(receipt(f, held)['disposition'] == 'held', 'Conflicted query successor held')
            require(receipt(f, view(f, 5))['disposition'] == 'applied', 'Unrelated same-name view progresses')
        passed_check('both independent name/query orders, atomic filter conflicts, held successors and unrelated progress')

        f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
        left, right = edit(f, a, 2, query(search='A'), group='query'), edit(f, a, 1, query(sort='title'), group='query')
        right['device_epoch'] = uid(); f.register(right['device_epoch'])
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda op: receipt(f, op), (left, right)))
        require(sorted(r['disposition'] for r in results) == ['applied', 'conflict'], 'Simultaneous queries serialize')
        require(fields(f, a)['query']['value'] in (left['patches']['query']['value'], right['patches']['query']['value']), 'No synthetic filter combination')
        passed_check('simultaneous query writes retain one complete specification')

        f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
        receipt(f, edit(f, a, 2, 'First'))
        partial = edit(f, a, 3, 'Other')
        partial['patches']['query'] = {'base': observed(1, query()), 'value': query(search='Retained')}
        require(receipt(f, partial)['disposition'] == 'partial', 'Name conflict does not discard independent query')
        require(fields(f, a)['name']['value'] == 'First' and fields(f, a)['query']['value'] == query(search='Retained'), 'Partial update retains whole query')
        corrupted = edit(f, a, 4, query(), observed(3, query()), 'query')
        require(receipt(f, corrupted)['fields'][0]['disposition'] == 'recovery', 'Query original value must match exact revision')
        require(f.pull()['groups'][-1]['recovery'][0]['operation'] == corrupted, 'Corrupt base remains immutable')
        f.task = a['entity']['key'][0]
        require(receipt(f, f.create(5))['disposition'] == 'applied', 'Task can share view UUID without identity collision')
        require(fields(f, a)['name']['value'] == 'First' and f.fields()['title']['value'] == 'X', 'Kind-qualified fields remain independent')
        passed_check('partial name/query result and exact complete-query original-base validation')

        for reverse in (False, True):
            f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
            change, remove = edit(f, a), delete(f, a, 1)
            remove['device_epoch'] = uid(); f.register(remove['device_epoch'])
            for op in ((remove, change) if reverse else (change, remove)):
                result = receipt(f, op)
                if op is change and reverse: require(result['fields'][0]['disposition'] == 'recovery', 'Hidden name retained for recovery')
                else: require(result['disposition'] == 'applied', 'Visible edit or deletion applies')
            require(fields(f, a)['existence']['value'] is False, 'Delete always dominates')
            require(fields(f, a)['name']['value'] == ('Work' if reverse else 'Renamed'), 'Retained content')
            collision = view(f, 3, a['entity']['key'][0])
            require(receipt(f, collision)['disposition'] == 'conflict', 'Deleted identity cannot recreate')
            require(fields(f, a)['existence']['value'] is False, 'No resurrection')
        passed_check('both delete/edit orders retain content and prevent UUID resurrection')

        # A delete must clear only its own current reference; stale selection is
        # consumed/recoverable and cannot reintroduce a hidden view.
        for reverse in (False, True):
            f = TaskFixture(backend, epoch); a, b = view(f), view(f, 2); f.apply(a, b)
            aid, bid = a['entity']['key'][0], b['entity']['key'][0]
            selected = preference(f, 3, aid); f.apply(selected)
            remove = delete(f, a, 4)
            switch = preference(f, 1, bid, observed(3, aid)); switch['device_epoch'] = uid(); f.register(switch['device_epoch'])
            for op in ((switch, remove) if reverse else (remove, switch)):
                result = receipt(f, op)
                if op is switch and not reverse: require(result['disposition'] == 'conflict', 'Clear changes preference revision; stale switch preserved')
                else: require(result['disposition'] == 'applied', 'Delete/switch applies')
            require(default(f)['value'] == (bid if reverse else None), 'Different selected view never cleared')
            late = preference(f, 5, aid, observed(default(f)['revision'], default(f)['value']))
            require(receipt(f, late)['rejection_code'] == 'default_view_unavailable', 'Deleted reference is consumed rejection')
            require(f.pull()['groups'][-1]['recovery'][0]['operation'] == late, 'Rejected reference remains recoverable')
            require(default(f)['value'] == (bid if reverse else None), 'No dangling default')
        passed_check('both delete/switch orders, conditional versioned clear and consumed stale-selection recovery')

        for select_first in (False, True):
            f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
            aid = a['entity']['key'][0]
            selection = preference(f, 2, aid)
            remove = delete(f, a, 1); remove['device_epoch'] = uid(); f.register(remove['device_epoch'])
            for op in ((selection, remove) if select_first else (remove, selection)):
                result = receipt(f, op)
                if op is selection and not select_first: require(result['disposition'] == 'rejected', 'Select after delete rejected')
                else: require(result['disposition'] == 'applied', 'Selection/delete accepted')
            require(default(f) is None or default(f)['value'] is None, 'Both orders have safe fallback')
        f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
        selection, remove = preference(f, 2, a['entity']['key'][0]), delete(f, a, 1)
        remove['device_epoch'] = uid(); f.register(remove['device_epoch'])
        with ThreadPoolExecutor(max_workers=2) as pool:
            list(pool.map(lambda op: receipt(f, op), (selection, remove)))
        require(default(f) is None or default(f)['value'] is None, 'Simultaneous delete/select cannot dangle')
        passed_check('both select/delete orders and simultaneous race preserve safe default fallback')

        for reverse in (False, True):
            f = TaskFixture(backend, epoch); a, b = view(f), view(f, 2); f.apply(a, b)
            left, right = preference(f, 3, a['entity']['key'][0]), preference(f, 1, b['entity']['key'][0])
            right['device_epoch'] = uid(); f.register(right['device_epoch'])
            first, last = (right, left) if reverse else (left, right)
            require(receipt(f, first)['disposition'] == 'applied', 'First default choice')
            require(receipt(f, last)['disposition'] == 'conflict', 'Concurrent different reference retains original absent base')
            require(default(f)['value'] == first['patches']['value']['value'], 'First accepted default retained')
        f = TaskFixture(backend, epoch); a, b = view(f), view(f, 2); f.apply(a, b)
        left, right = preference(f, 3, a['entity']['key'][0]), preference(f, 1, b['entity']['key'][0])
        right['device_epoch'] = uid(); f.register(right['device_epoch'])
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda op: receipt(f, op), (left, right)))
        require(sorted(r['disposition'] for r in results) == ['applied', 'conflict'], 'Simultaneous default choices serialize')
        passed_check('opposite and simultaneous default-choice conflicts preserve independent original bases')

        f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
        aid = a['entity']['key'][0]
        choose = preference(f, 2, aid, parent=a); require(receipt(f, choose)['disposition'] == 'applied', 'Exact view create dependency')
        clear = preference(f, 3, None, predecessor(choose, aid)); require(receipt(f, clear)['disposition'] == 'applied', 'Explicit clear binds original selection')
        again = preference(f, 4, aid, predecessor(clear, None)); require(receipt(f, again)['disposition'] == 'applied', 'Reselect binds explicit clear')
        current = default(f)
        wrong = preference(f, 5, None, observed(current['revision'], None))
        require(receipt(f, wrong)['fields'][0]['disposition'] == 'recovery', 'Exact revision with wrong base rejected')
        before = len(rows(f, 'preference_changes'))
        require(receipt(f, preference(f, 6, aid))['fields'][0]['disposition'] == 'equivalent', 'Stale equivalent selection preserves revision')
        require(default(f) == current and len(rows(f, 'preference_changes')) == before, 'Equivalent has no mutation ledger')
        removed = delete(f, a, 7); receipt(f, removed)
        forged = preference(f, 8, None, predecessor(removed, None))
        require(receipt(f, forged)['fields'][0]['disposition'] == 'recovery', 'Implicit clear is not a preference command predecessor')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
        require(receipt(f, preference(f, 9, None, predecessor(clear, None)))['fields'][0]['disposition'] == 'recovery', 'Expired accepted predecessor not guessed from ledger')
        passed_check('exact preference chains, explicit clear/reselect, wrong bases, equivalence and expired evidence')

        f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
        collision = view(f, 2, a['entity']['key'][0], 'Collision'); receipt(f, collision)
        choose = preference(f, 3, a['entity']['key'][0], parent=collision)
        require(receipt(f, choose)['disposition'] == 'held', 'Exact collided view holds selection despite live UUID')
        rename = edit(f, collision, 4, 'Successor', predecessor(collision, 'Collision'))
        require(receipt(f, rename)['disposition'] == 'held', 'Colliding create name successor held')
        child = preference(f, 5, None, predecessor(choose, a['entity']['key'][0]))
        require(receipt(f, child)['disposition'] == 'held', 'Own preference predecessor held')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
        require(receipt(f, preference(f, 6, None, predecessor(child, None)))['disposition'] == 'held', 'Durable own held chain survives expiry')
        require(receipt(f, preference(f, 7, a['entity']['key'][0], parent=collision))['fields'][0]['disposition'] == 'recovery', 'Expired dependency never guessed')
        require(receipt(f, view(f, 8))['disposition'] == 'applied', 'Unrelated progress after held chain')
        passed_check('colliding view and preference dependency chains, retained held state and expired parent evidence')

        f = TaskFixture(backend, epoch); a = view(f); b = view(f, 2); f.apply(a, b)
        bad = preference(f, 3, a['entity']['key'][0], parent=b)
        require(receipt(f, bad)['fields'][0]['disposition'] == 'recovery', 'Wrong view dependency cannot authorize')
        missing = deepcopy(a); missing['operation_id'] = uid()
        require(receipt(f, preference(f, 4, a['entity']['key'][0], parent=missing))['fields'][0]['disposition'] == 'recovery', 'Wrong operation identity')
        require(receipt(f, preference(f, 5, None, parent=a))['fields'][0]['disposition'] == 'recovery', 'Clear cannot carry unrelated parent')
        duplicate = preference(f, 6, a['entity']['key'][0], parent=a); duplicate['dependencies'] *= 2
        require(receipt(f, duplicate)['fields'][0]['disposition'] == 'recovery', 'Duplicate dependencies cannot hide invalid evidence')
        passed_check('exact view dependency entity/operation and incompatible or duplicate parent rejection')

        # Complete canonical query validation, including UTF-16 boundaries.
        valid = [query(), query(search='😀' * 1000), query(statuses=['completed','todo'], priorities=['high','none'], tags=[uid()],
            **{'from': '0001-01-01', 'to': '9999-12-31'}), query(undated=True), query(builtIn='overdue', group='dueDay', sort='duration')]
        invalid = [None, {}, query(version=2), query(search=3), query(search='😀' * 1001), query(statuses=['todo','todo']),
            query(statuses=['todo','completed']), query(statuses=['bogus']), query(priorities=['urgent']), query(tags=['bad']),
            query(tags=[uid().upper()]), query(allTags=1), query(builtIn='bogus'), query(group=None), query(sort='bogus'),
            query(**{'from': '2026-02-29'}), query(**{'from': '2026-10-26', 'to': '2026-10-25'}),
            query(undated=True, builtIn='today'), query(undated=True, overdue=True), query(extra=True)]
        missing_query = query(); del missing_query['from']; invalid.append(missing_query)
        f = TaskFixture(backend, epoch)
        seq = 1
        for spec in valid + invalid:
            result = receipt(f, view(f, seq, spec=spec)) if spec is not None else receipt(f, dict(view(f, seq), patches={
                'name': {'base': {'kind':'absent'}, 'value':'Work'}, 'existence': {'base': {'kind':'absent'}, 'value':True},
                'query': {'base': {'kind':'absent'}, 'value':None}}))
            require(result['disposition'] == ('applied' if spec in valid else 'rejected'), 'Canonical query validation parity')
            if spec not in valid: require(result['rejection_code'] == 'invalid_view_query', 'Query rejection reason')
            seq += 1
        for text in ('', ' Work', 'Work\tNow', '😀' * 41, 3):
            require(receipt(f, view(f, seq, name=text))['rejection_code'] == 'invalid_view_name', 'View name rejected'); seq += 1
        require(receipt(f, view(f, seq, name='😀' * 40))['disposition'] == 'applied', 'UTF-16 name boundary')
        require(len(rows(f, 'view_shadow')) == len(valid) + 1, 'Invalid creates never partially install')
        passed_check('canonical query/name validation and UTF-16/date/set/enum/filter boundaries')

        f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
        malformed = edit(f, a); malformed['entity']['key'] = ['not-a-uuid']
        before = state(f)
        code, _ = backend.request('POST', '/rest/v1/rpc/sync_apply', f.token, {'request': f.request(malformed)})
        require(code == 400 and state(f) == before, 'Malformed envelope consumes nothing')
        bad_create = view(f, 2); del bad_create['patches']['query']
        require(receipt(f, bad_create)['rejection_code'] == 'invalid_create', 'Missing complete spec rejected')
        bad_edit = edit(f, a, 3, True, observed(1, True), 'existence')
        require(receipt(f, bad_edit)['rejection_code'] == 'invalid_view_edit', 'Edit cannot change existence')
        bad_delete = delete(f, a, 4); bad_delete['patches']['existence']['value'] = True
        require(receipt(f, bad_delete)['rejection_code'] == 'invalid_delete_command', 'Delete cannot restore')
        require(receipt(f, preference(f, 5, 'bad'))['rejection_code'] == 'invalid_default_view', 'Bad reference type')
        require(receipt(f, preference(f, 6, uid()))['rejection_code'] == 'default_view_unavailable', 'Missing reference consumed')
        missing = view(f, identity=uid())
        require(receipt(f, edit(f, missing, 7))['fields'][0]['disposition'] == 'recovery', 'Edit cannot create missing view')
        passed_check('malformed preflight, semantic consumed rejection and missing-entity recovery')

        f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
        other = TaskFixture(backend, epoch)
        before = state(f)
        require(receipt(other, preference(other, 1, a['entity']['key'][0]))['rejection_code'] == 'default_view_unavailable', 'Cross-owner reference cannot select')
        b = view(other, 2, a['entity']['key'][0]); other.apply(b)
        other.apply(preference(other, 3, b['entity']['key'][0]))
        other.apply(delete(other, b, 4, observed(2, True)))
        require(state(f) == before, 'Same UUID in separate owners stays independent')
        for table in TABLES:
            require(sql(f"select relrowsecurity and relforcerowsecurity from pg_class where oid='sync_private.{table}'::regclass;") == 't', 'Forced RLS')
            require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                        f"select count(*) from sync_private.{table} where owner_id='{f.owner}'; rollback;").splitlines()[-1] == '0', 'RLS hides foreign rows')
            for token in (None, f.token, other.token):
                for method in ('GET','POST','PATCH','DELETE'):
                    code, _ = backend.request(method, '/rest/v1/' + table, token, None if method=='GET' else {})
                    require(code in (401,403,404), 'Raw REST bypass denied')
                code, _ = backend.request('GET', '/rest/v1/' + table, token, headers={'Accept-Profile':'sync_private'})
                require(code in (401,403,404,406), 'Private schema not exposed')
        require(sql("select has_column_privilege('dourstuff_rpc','sync_private.view_shadow','view_id','UPDATE') "
                    "or has_column_privilege('dourstuff_rpc','sync_private.view_shadow','creation_operation','UPDATE') "
                    "or has_column_privilege('dourstuff_rpc','sync_private.preference_shadow','key','UPDATE') "
                    "or has_table_privilege('dourstuff_rpc','sync_private.preference_changes','UPDATE');") == 'f', 'Immutable identities and append-only ledger')
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                    f"update sync_private.view_shadow set fields=fields where owner_id='{f.owner}'; "
                    "do $test$ begin begin insert into sync_private.preference_shadow(owner_id,key,fields) "
                    f"values ('{f.owner}','default_view','{{\"value\":{{\"revision\":1,\"value\":null}}}}'); "
                    "raise exception 'Foreign preference insert allowed'; exception when insufficient_privilege then null; end; end $test$; rollback;").splitlines() == ['t']
                and state(f) == before, 'RLS rejects actual foreign insert/update')
        passed_check('owner-qualified same UUIDs, default-reference isolation, forced RLS and REST/grant boundaries')

        f = TaskFixture(backend, epoch); a = view(f); f.apply(a)
        selected = preference(f, 2, a['entity']['key'][0]); f.apply(selected)
        rename, remove = edit(f, a, 3), delete(f, a, 4)
        before = state(f)
        sql("create function sync_private.test_view_fail() returns trigger language plpgsql as $$ "
            "begin if new.revision=4 then raise exception 'Injected view failure'; end if; return new; end $$; "
            "create trigger test_view_fail before insert on sync_private.change_log for each row execute function sync_private.test_view_fail();")
        try:
            code, _ = backend.request('POST', '/rest/v1/rpc/sync_apply', f.token, {'request': f.request(rename, remove)})
            require(code == 400 and state(f) == before, 'Entire batch including implicit clear/ledgers/receipts/log/watermark rolls back')
        finally:
            sql('drop trigger test_view_fail on sync_private.change_log; drop function sync_private.test_view_fail();')
        require(all(r['disposition']=='applied' for r in f.apply(rename, remove)['result']['results']), 'Original batch retries after rollback')
        require(default(f) == {'revision': 4, 'value': None}, 'Successful retry clears atomically')
        passed_check('injected second-log failure rolls back rename/delete/default clear and all durable metadata')
        print(f'{passed} saved-view/preference integration groups passed.')
    finally:
        backend.cleanup()
        if args.wire_output:
            args.wire_output.parent.mkdir(parents=True, exist_ok=True)
            args.wire_output.write_text(json.dumps(backend.wire), encoding='utf-8')


if __name__ == '__main__':
    main()
