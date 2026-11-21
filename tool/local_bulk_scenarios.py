"""Race one selected task in each direction of a real bulk intent."""
from test_backend_apply import observed, uid
from test_backend_foundation import require
from test_backend_resolution import pull
from test_backend_task_create import status
from test_backend_task_delete import deletion
from test_backend_task_restore import restore


SCENARIOS = ['bulk-status', 'bulk-delete']


def prepare(f):
    creations = [f.create(initial=status('cancelled')),
                 f.create(2, task=uid(), initial=status('in_progress')),
                 f.create(3, task=uid())]
    require(all(r['disposition'] == 'applied' for r in f.apply(*creations)['result']['results']),
            'Three independently versioned tasks created')
    f.device = uid()
    f.register(f.device)
    return [op['entity']['key'][0] for op in creations]


def apply_forward(f, scenario, request, initial):
    operations = request['operations']
    require(len(operations) == 3, 'One forward operation per selected task')
    # A peer wins the third transition after SQLite records the selection.
    peer = uid()
    f.register(peer)
    other = dict(operations[2], device_epoch=peer, sequence=1, operation_id=uid(),
                 provenance={'occurred_at': 101})
    require(f.apply(other)['result']['results'][0]['disposition'] == 'applied', 'Peer wins third task')
    receipt = f.backend.rpc('apply', f.token, request)
    results = receipt['result']['results']
    group = 'status_group' if scenario == 'bulk-status' else 'existence'
    require([r['fields'][0]['disposition'] for r in results] ==
            ['applied', 'applied', 'equivalent' if scenario == 'bulk-status' else 'recovery'],
            'Mixed forward field outcomes')
    require(f.backend.rpc('apply', f.token, request) == receipt, 'Forward retry returns identical reply')
    require([op['patches'][group]['base']['revision'] for op in operations] == [1, 2, 3],
            'Each operation retained its own selection base')
    pull(f, initial['at']['revision'])
    return dict(request=request, receipt=receipt, downloads=[f.backend.wire[-1]])


def race_undo(f, scenario, seed, undo):
    first, second, _ = seed['request']['operations']
    require([op['entity'] for op in undo] == [first['entity'], second['entity']],
            'Undo only targets the two original winners')
    peer = uid()
    f.register(peer)
    if scenario == 'bulk-status':
        for op, before, result in zip(undo, [status('cancelled'), status('in_progress')],
                                      seed['receipt']['result']['results']):
            require(op['patches']['status_group']['value'] == before, 'Exact previous status restored')
            accepted = result['fields'][0]['accepted']
            require(op['patches']['status_group']['base'] == observed(accepted['revision'], accepted['value']),
                    'Status undo binds its own accepted transition')
        change = dict(f.set_status(1, status('todo'), undo[0]['patches']['status_group']['base']),
                      device_epoch=peer)
        require(f.apply(change)['result']['results'][0]['disposition'] == 'applied', 'Newer status wins')
        expected = ['conflict', 'applied']
    else:
        for op, original, receipt in zip(undo, (first, second), seed['receipt']['result']['results']):
            require(op['restore'] == {'delete_operation_id': original['operation_id'],
                                      'revision': receipt['revision']}, 'Undo uses original winning deletion')
        revive = dict(restore(f, first, 1, undo[0]['restore']['revision']), device_epoch=peer)
        revision = f.apply(revive)['result']['results'][0]['revision']
        remove = dict(deletion(f, 2, observed(revision, True)), device_epoch=peer)
        require(f.apply(remove)['result']['results'][0]['disposition'] == 'applied', 'New deletion wins')
        expected = ['rejected', 'applied']
    pull(f, seed['downloads'][-1]['reply']['result']['through']['revision'])
    return expected, f.backend.wire[-1]


def check_recovery(scenario, fixture):
    expected = [fixture['request']['operations'][0]]
    if scenario == 'bulk-delete':
        expected.append(fixture['seed']['request']['operations'][2])
    actual = [record['operation'] for page in fixture['terminal_pages'] for record in page['recovery']]
    require(len(actual) == len(expected) and all(original in actual for original in expected),
            'Recovery retains exactly the losing originals, including their bases and deletion proof')
