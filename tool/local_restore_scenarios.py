"""Exact-deletion restore and dependent SQLite commands on synthetic accounts."""
from test_backend_apply import observed, predecessor, uid
from test_backend_deleted_content import age, prune
from test_backend_foundation import require
from test_backend_memberships import membership
from test_backend_milestone_commands import remove
from test_backend_milestone_create import milestone
from test_backend_milestone_order import order
from test_backend_tag_commands import name, tag
from test_backend_task_delete import deletion
from test_backend_task_restore import restore


SCENARIOS = ['restore-visible', 'restore-cycle', 'restore-stale', 'restore-expired', 'restore-compacted',
             'restore-receipt']


def prepare(f, scenario):
    if scenario == 'restore-visible':
        live, hidden = milestone(f, 2), milestone(f, 3)
        kept, removed, new = tag(f, 4), tag(f, 5, name('Old')), tag(f, 6, name('New'))
        tombstone = deletion(f, 9)
        f.apply(f.create(), live, hidden, kept, removed, new,
                membership(f, kept, 7), membership(f, removed, 8), tombstone,
                remove(f, hidden, 10, observed(3, True)),
                membership(f, removed, 11, False, observed(8, True)),
                f.op(12, 'Preserved late edit', observed(1, 'X')))
        f.device = uid()
        f.register(f.device)
        undo = restore(f, tombstone, 1, 9)
        child = milestone(f, 2, dependency=undo)
        ordered = order(f, [child['entity']['key'][0], live['entity']['key'][0]],
                        3, dependencies=[undo, child])
        add = membership(f, new, 4, parents=[undo])
        repeat = restore(f, tombstone, 5, 9)
        return [undo, child, ordered, add, repeat,
                milestone(f, 6, dependency=repeat),
                membership(f, new, 7, parents=[repeat]),
                order(f, [], 8, dependencies=[repeat])], (
                    ['applied'] * 4 + ['rejected'] + ['conflict'] * 3)

    tombstone = deletion(f)
    f.apply(f.create(), tombstone)
    if scenario in ('restore-expired', 'restore-compacted'):
        age(f)
        if scenario == 'restore-compacted':
            require(prune(f)['shadows_compacted'] == 1, 'Exact task content compacted')
    f.device = uid()
    f.register(f.device)
    if scenario == 'restore-cycle':
        wrong_id = restore(f, dict(tombstone, operation_id=uid()), 1)
        wrong_revision = restore(f, tombstone, 2, 1)
        exact = restore(f, tombstone, 3)
        again = deletion(f, 4, predecessor(exact, True))
        stale = restore(f, tombstone, 5)
        return [wrong_id, wrong_revision, exact, again, stale, milestone(f, 6, dependency=exact)], (
            ['rejected', 'rejected', 'applied', 'applied', 'rejected', 'conflict'])
    undo = restore(f, tombstone, 1)
    if scenario == 'restore-receipt':
        return [undo, milestone(f, 2)], ['applied']
    return [undo, milestone(f, 2, dependency=undo)], ['rejected', 'conflict']


def supersede(f, undo):
    """A second device restores and deletes after SQLite committed its intent."""
    peer = uid()
    f.register(peer)
    first = dict(undo, operation_id=uid(), device_epoch=peer)
    second = dict(deletion(f, 2, observed(3, True)), device_epoch=peer)
    require([r['disposition'] for r in f.apply(first, second)['result']['results']]
            == ['applied', 'applied'], 'Second device replaces deletion')
