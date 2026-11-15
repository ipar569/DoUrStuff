"""Synthetic original intents for SQLite-to-PostgreSQL ordering verification."""
from test_backend_apply import observed, predecessor, uid
from test_backend_milestone_create import milestone
from test_backend_milestone_commands import remove
from test_backend_milestone_order import order, value


SCENARIOS = ['ordering', 'order-held', 'order-causal', 'order-recovery']


def prepare(f, scenario):
    if scenario == 'ordering':
        parent = f.create()
        a = milestone(f, 2, dependency=parent)
        b = milestone(f, 3, dependency=parent)
        aid, bid = a['entity']['key'][0], b['entity']['key'][0]
        first = order(f, [bid, aid], 4, dependencies=[parent, a, b])
        second = order(f, [aid, bid], 5, predecessor(first, value(bid, aid)))
        deleted = remove(f, a, 6, predecessor(a, True))
        added = milestone(f, 7, dependency=parent)
        last = order(f, [bid, aid], 8, predecessor(second, value(aid, bid)), [a, b])
        return [parent, a, b, first, second, deleted, added, last], ['applied'] * 8

    a, b = milestone(f, 2), milestone(f, 3)
    f.apply(f.create(), a, b)
    aid, bid = a['entity']['key'][0], b['entity']['key'][0]
    f.device = uid()
    f.register(f.device)
    if scenario == 'order-held':
        collision = f.create(title='Collision')
        held_child = milestone(f, 2, dependency=collision)
        cid = held_child['entity']['key'][0]
        held = order(f, [cid], 3, dependencies=[held_child])
        descendant = order(f, [], 4, predecessor(held, value(cid)))
        missing = order(f, [cid, uid()], 5, dependencies=[held_child])
        unrelated = f.op(6, 'Unrelated', observed(1, 'X'))
        return [collision, held_child, held, descendant, missing, unrelated], [
            'conflict', 'held', 'held', 'held', 'conflict', 'applied']
    if scenario == 'order-causal':
        first = order(f, [aid, bid], 1)
        equivalent = order(f, [aid, bid], 2)
        next_order = order(f, [bid, aid], 3, predecessor(first, value(aid, bid)))
        stale = order(f, [], 4, predecessor(equivalent, value(aid, bid)))
        held = order(f, [bid, aid], 5, predecessor(stale, value()))
        return [first, equivalent, next_order, stale, held], [
            'applied', 'applied', 'applied', 'conflict', 'held']
    # Wrong-parent identity and expired/unavailable exact source proof cannot be
    # replaced by a same-UUID canonical child or an unrelated valid dependency.
    other = f.create(task=uid())
    foreign = milestone(f, 2, parent=other['entity']['key'][0])
    f.apply(other, foreign)
    f.device = uid()
    f.register(f.device)
    foreign_order = order(f, [foreign['entity']['key'][0]], 1)
    missing = order(f, [uid()], 2)
    unknown_source = dict(a, operation_id=uid(), sequence=1)
    proof = order(f, [aid], 3, dependencies=[unknown_source])
    valid = order(f, [bid, aid], 4)
    return [foreign_order, missing, proof, valid], ['conflict'] * 3 + ['applied']
