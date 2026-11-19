"""Saved-view and shared-default command sequences for the SQLite RPC harness."""
from test_backend_apply import observed, predecessor, uid
from test_backend_saved_views import delete, edit, preference, query, view


SCENARIOS = ['views-chain', 'views-switch', 'views-clear', 'views-collision', 'views-query']


def prepare(f, scenario):
    a = view(f)
    aid = a['entity']['key'][0]
    if scenario == 'views-chain':
        select = preference(f, 2, aid, parent=a)
        rename = edit(f, a, 3, base=predecessor(a, 'Work'))
        spec = edit(f, a, 4, query(search='Focus', statuses=['completed', 'in_progress']),
                    predecessor(a, query()), 'query')
        clear = preference(f, 5, None, predecessor(select, aid))
        again = preference(f, 6, aid, predecessor(clear, None))
        remove = delete(f, a, 7, predecessor(a, True))
        forged = preference(f, 8, None, predecessor(remove, None))
        late = preference(f, 9, aid, parent=a)
        return [a, select, rename, spec, clear, again, remove, forged, late], (
            ['applied'] * 7 + ['conflict', 'rejected'])

    b = view(f, 2)
    bid = b['entity']['key'][0]
    f.apply(a, b, preference(f, 3, aid))
    f.device = uid()
    f.register(f.device)
    if scenario == 'views-switch':
        switch = preference(f, 1, bid, observed(3, aid))
        remove = delete(f, a, 2)
        return [switch, remove], ['applied', 'applied']
    if scenario == 'views-clear':
        remove = delete(f, a, 1)
        stale = preference(f, 2, bid, observed(3, aid))
        equivalent = preference(f, 3, None, observed(3, aid))
        switch = preference(f, 4, bid, predecessor(equivalent, None))
        return [remove, stale, equivalent, switch], ['applied', 'conflict', 'applied', 'applied']
    if scenario == 'views-collision':
        collision = view(f, identity=aid)
        held = preference(f, 2, aid, parent=collision)
        child = preference(f, 3, None, predecessor(held, aid))
        missing = preference(f, 4, bid, parent=dict(b, operation_id=uid()))
        missing_view = view(f)
        missing_edit = edit(f, missing_view, 5)
        missing_edit['patches']['query'] = dict(base=predecessor(collision, query()),
                                              value=query(search='Missing'))
        unrelated = view(f, 6)
        return [collision, held, child, missing, missing_edit, unrelated], (
            ['conflict', 'held', 'held', 'conflict', 'conflict', 'applied'])

    changed = edit(f, a, 1, query(group='priority'), group='query')
    partial = edit(f, a, 2)
    partial['patches']['query'] = dict(base=observed(1, query()), value=query(search='Focus'))
    held = edit(f, a, 3, query(sort='title'), predecessor(partial, query(search='Focus')), 'query')
    return [changed, partial, held], ['applied', 'partial', 'held']
