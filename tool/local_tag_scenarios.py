"""Original tag/membership intents for SQLite-to-PostgreSQL parity checks."""
from test_backend_apply import observed, predecessor, uid
from test_backend_tag_commands import tag, name, edit, remove
from test_backend_memberships import membership, dependency
from test_backend_resolution import candidates, request as resolution_request, resolve, pull
from test_backend_compound_recovery import fields
from test_backend_foundation import require

SCENARIOS = ['tags-chain', 'tags-collision', 'tags-causal', 'tags-evidence', 'tags-closed']


def prepare(f, scenario):
    if scenario == 'tags-chain':
        task = f.create()
        a = tag(f, 2)
        add = membership(f, a, 3, parents=[task, a])
        rename = edit(f, a, 4, name('Renamed'), predecessor(a, a['patches']['name']['value']))
        delete = remove(f, a, 5, predecessor(a, True))
        removal = membership(f, a, 6, False, predecessor(add, True))
        replacement = tag(f, 7, name('RENAMED'))
        explicit = membership(f, replacement, 8, parents=[replacement])
        hidden = membership(f, a, 9, True, predecessor(removal, False))
        return [task, a, add, rename, delete, removal, replacement, explicit, hidden], ['applied'] * 8 + ['conflict']

    f.apply(f.create())
    original = tag(f, 2)
    f.apply(original)
    f.device = uid()
    f.register(f.device)
    if scenario == 'tags-closed':
        return [f.create(title='Collision'), tag(f, 2, name('WORK'))], ['conflict', 'conflict']
    if scenario == 'tags-collision':
        loser = tag(f, 1, name('WORK'))
        add = membership(f, loser, 2, parents=[loser])
        delete = remove(f, original, 3, observed(2, True))
        held = edit(f, loser, 4, name('Free'), predecessor(loser, loser['patches']['name']['value']))
        held_delete = remove(f, loser, 5, predecessor(loser, True))
        replacement = tag(f, 6)
        explicit = membership(f, replacement, 7, parents=[replacement])
        return [loser, add, delete, held, held_delete, replacement, explicit], ['conflict', 'held', 'applied', 'held', 'held', 'applied', 'applied']

    if scenario == 'tags-causal':
        first = edit(f, original, 1, name('Changed'), observed(2, name('Work')))
        same = edit(f, original, 2, name('Changed'), observed(2, name('Work')))
        next_edit = edit(f, original, 3, name('Next'), predecessor(same, name('Changed')))
        stale = edit(f, original, 4, name('Stale'), predecessor(first, name('Changed')))
        absent_false = membership(f, original, 5, False)
        stale_add = membership(f, original, 6)
        held_remove = membership(f, original, 7, False, predecessor(stale_add, True))
        next_add = membership(f, original, 8, True, predecessor(absent_false, False))
        return [first, same, next_edit, stale, absent_false, stale_add, held_remove, next_add], ['applied'] * 3 + ['conflict', 'applied', 'conflict', 'held', 'applied']

    loser = tag(f, 1, name('WORK'))
    missing_task = dict(entity={'kind': 'task', 'key': [f.task]}, operation_id=uid(), sequence=1, group='existence')
    first = membership(f, loser, 2, parents=[loser])
    first['dependencies'].append(missing_task)
    second = membership(f, loser, 3)
    second['dependencies'] = [missing_task, dependency(loser)]
    missing_base = membership(f, original, 4, base=dict(kind='predecessor', operation_id=uid(), sequence=1, value=False))
    independent = membership(f, original, 5)
    missing_edit = edit(f, loser, 6, name('Work'), observed(2, name('Old')))
    missing_delete = remove(f, loser, 7, observed(2, True))
    successor = edit(f, loser, 8, name('Next'), predecessor(missing_edit, name('Work')))
    return [loser, first, second, missing_base, independent, missing_edit, missing_delete, successor], ['conflict'] * 4 + ['applied'] + ['conflict'] * 3


def close_sources(f, sources, initial):
    request = f.request(*sources)
    response = f.backend.rpc('apply', f.token, request)
    require([r['disposition'] for r in response['result']['results']] == ['conflict'] * 2,
            'Source creates conflict before closure')
    resolver = uid()
    f.register(resolver)
    for seq, source in enumerate(sources, 1):
        candidate = next(c for c in candidates(f) if
                         c['operation']['operation_id'] == source['operation_id'] and c['group'] == 'existence')
        q = resolution_request(f, candidate, seq, device=resolver)
        q['observed_fields'] = fields(f, source['entity'])
        require(resolve(f, q)['status'] == 'success', 'Explicit discard closure succeeds')
    cursor, downloads = initial['at']['revision'], []
    while True:
        result = pull(f, cursor, 2)
        require(result['status'] == 'success', 'Closure pull succeeds')
        downloads.append(f.backend.wire[-1])
        cursor = result['result']['through']['revision']
        if not result['result']['has_more']:
            break
    proposals = [membership(f, sources[1], 3, parents=sources),
                 edit(f, sources[1], 4, name('Free'), predecessor(sources[1], name('WORK'))),
                 remove(f, sources[1], 5, predecessor(sources[1], True)),
                 membership(f, sources[1], 6)]
    return dict(request=request, receipt=response, downloads=downloads), proposals
