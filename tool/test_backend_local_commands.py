"""SQLite-created commands through real local RPC; synthetic users only."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

from test_backend_foundation import Backend, require, sql
from test_backend_apply import uid, observed, predecessor
from test_backend_task_create import TaskFixture
from test_backend_milestone_create import milestone
from test_backend_resolution import begin, page, pull
from local_order_scenarios import SCENARIOS, prepare as prepare_order, close_sources
from test_backend_milestone_order import projected


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--supabase', default='supabase')
    parser.add_argument('--dart', default='dart')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--scenario', choices=['chain', 'equivalent', 'held', 'causal'] + SCENARIOS, default='chain')
    args = parser.parse_args()
    if Path(args.dart).is_file():
        args.dart = str(Path(args.dart).resolve())
    subprocess.run([sys.executable, 'tool/local_backend.py'], check=True)
    backend = Backend(args.supabase)
    prefix = args.output.with_suffix('')
    db = Path(str(prefix) + '-' + uid() + '.sqlite')
    commands = Path(str(prefix) + '-request.json')
    try:
        f = TaskFixture(backend, sql('select server_epoch from sync_private.backend_state;'))
        proposals = None
        order_expected = None
        if args.scenario in SCENARIOS:
            proposals, order_expected = prepare_order(f, args.scenario)
        elif args.scenario != 'chain':
            f.apply(f.create(title='Old'))
            if args.scenario == 'equivalent':
                f.apply(f.op(2, 'A', observed(1, 'Old')))
            f.device = uid()
            f.register(f.device)
            if args.scenario == 'equivalent':
                proposals = [f.op(1, 'A', observed(1, 'Old')), f.op(2, 'B', observed(2, 'A'))]
            elif args.scenario == 'causal':
                first = f.op(1, 'B', observed(1, 'Old'))
                equivalent = f.op(2, 'B', observed(1, 'Old'))
                next_edit = f.op(3, 'C', predecessor(first, 'B'))
                stale = f.op(4, 'D', predecessor(equivalent, 'B'))
                proposals = [first, equivalent, next_edit, stale]
            else:
                creation = f.create(title='Collision')
                step = milestone(f, 2)
                step['dependencies'] = [dict(entity=creation['entity'], operation_id=creation['operation_id'], sequence=1, group='existence')]
                edit = dict(f.op(3, 'First edit', predecessor(step, step['patches']['title']['value'])),
                            entity=step['entity'], command='milestone.edit')
                edit2 = dict(f.op(4, 'Second edit', predecessor(edit, 'First edit')),
                             entity=step['entity'], command='milestone.edit')
                deletion = dict(f.op(5, False, predecessor(step, True), group='existence'),
                                entity=step['entity'], command='milestone.delete')
                proposals = [creation, step, edit, edit2, deletion]
        initial = begin(f)
        pages = [page(f, initial, i) for i in range(initial['page_count'])]
        fixture = dict(owner=f.owner, device=f.device, task=f.task, child=uid(),
                       scenario=args.scenario,
                       operations=[uid() for _ in range(7)], manifest=initial, pages=pages,
                       checked_at_utc=backend.wire[-1]['checked_at_utc'])
        if args.scenario == 'order-closed':
            fixture['seed'], proposals = close_sources(f, proposals, initial)
            order_expected = ['held', 'held', 'held', 'applied']
        if proposals is not None:
            fixture['proposals'] = proposals
        args.output.write_text(json.dumps(fixture), encoding='utf-8')
        subprocess.run([args.dart, 'run', 'tool/check_backend_commands.dart', 'prepare',
                        str(args.output), str(db), str(commands)], check=True)
        request = json.loads(commands.read_text(encoding='utf-8'))
        response = backend.rpc('apply', f.token, request)
        require(response['status'] == 'success', 'Apply succeeds')
        expected = ['conflict', 'held', 'held', 'held', 'held'] if args.scenario == 'held' else ['applied'] * len(request['operations'])
        if args.scenario == 'causal':
            expected = ['applied', 'applied', 'applied', 'conflict']
        if order_expected is not None:
            expected = order_expected
        require([r['disposition'] for r in response['result']['results']] == expected,
                'Expected SQLite command outcomes')
        require(backend.rpc('apply', f.token, request) == response, 'Dropped-response retry is immutable')
        cursor = (fixture['seed']['downloads'][-1]['reply']['result']['through']['revision']
                  if 'seed' in fixture else initial['at']['revision'])
        downloads = []
        while True:
            result = pull(f, cursor, 2)
            require(result['status'] == 'success', 'Pull succeeds')
            downloads.append(backend.wire[-1])
            cursor = result['result']['through']['revision']
            if not result['result']['has_more']:
                break
        terminal = begin(f)
        fixture.update(request=request, receipt=response, downloads=downloads,
                       terminal_pages=[page(f, terminal, i) for i in range(terminal['page_count'])])
        if args.scenario in SCENARIOS:
            fixture['visible_order'] = projected(f)
        args.output.write_text(json.dumps(fixture), encoding='utf-8')
        subprocess.run([args.dart, 'run', 'tool/check_backend_commands.dart', 'verify',
                        str(args.output), str(db), str(commands)], check=True)
        seed = fixture.get('seed', {})
        command_count = len(request['operations']) + len(seed.get('request', {}).get('operations', []))
        page_count = len(downloads) + len(seed.get('downloads', []))
        print(f'PASS: SQLite-to-PostgreSQL {command_count} local commands and {page_count} pull pages', flush=True)
    finally:
        backend.cleanup()


if __name__ == '__main__':
    main()
