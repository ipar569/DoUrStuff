"""SQLite-created commands through real local RPC; synthetic users only."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

from test_backend_foundation import Backend, require, sql
from test_backend_apply import uid
from test_backend_task_create import TaskFixture
from test_backend_resolution import begin, page, pull


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--supabase', default='supabase')
    parser.add_argument('--dart', default='dart')
    parser.add_argument('--output', type=Path, required=True)
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
        initial = begin(f)
        pages = [page(f, initial, i) for i in range(initial['page_count'])]
        fixture = dict(owner=f.owner, device=f.device, task=f.task, child=uid(),
                       operations=[uid() for _ in range(7)], manifest=initial, pages=pages,
                       checked_at_utc=backend.wire[-1]['checked_at_utc'])
        args.output.write_text(json.dumps(fixture), encoding='utf-8')
        subprocess.run([args.dart, 'run', 'tool/check_backend_commands.dart', 'prepare',
                        str(args.output), str(db), str(commands)], check=True)
        request = json.loads(commands.read_text(encoding='utf-8'))
        response = backend.rpc('apply', f.token, request)
        require(response['status'] == 'success', 'Apply succeeds')
        require(all(r['disposition'] == 'applied' for r in response['result']['results']),
                'All SQLite commands accepted')
        require(backend.rpc('apply', f.token, request) == response, 'Dropped-response retry is immutable')
        cursor, downloads = initial['at']['revision'], []
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
        args.output.write_text(json.dumps(fixture), encoding='utf-8')
        subprocess.run([args.dart, 'run', 'tool/check_backend_commands.dart', 'verify',
                        str(args.output), str(db), str(commands)], check=True)
        print(f'PASS: SQLite-to-PostgreSQL command chain and {len(downloads)} pull pages', flush=True)
    finally:
        backend.cleanup()


if __name__ == '__main__':
    main()
