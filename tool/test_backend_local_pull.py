"""Capture one real snapshot/paginated-pull chain for the SQLite consumer.

Synthetic accounts only. No migrations, resets or container startup here.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

from test_backend_foundation import Backend, require, sql
from test_backend_task_create import TaskFixture, status
from test_backend_apply import observed, predecessor, uid
from test_backend_resolution import begin, page, pull, candidates, request, resolve
from test_backend_milestone_create import milestone
from test_backend_task_delete import deletion
from test_backend_deleted_content import age, prune


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--supabase', default='supabase')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--inherited-compaction', action='store_true')
    args = parser.parse_args()
    subprocess.run([sys.executable, 'tool/local_backend.py'], check=True)
    backend = Backend(args.supabase)
    try:
        epoch = sql('select server_epoch from sync_private.backend_state;')
        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        if args.inherited_compaction:
            f.apply(milestone(f, 2))
        local_device = uid()
        f.register(local_device)
        initial = begin(f)
        initial_pages = [page(f, initial, i) for i in range(initial['page_count'])]
        checked = backend.wire[-1]['checked_at_utc']
        pending = f.op(1, 'offline original', observed(1, 'X'))
        pending['device_epoch'] = local_device
        if args.inherited_compaction:
            f.apply(deletion(f, 3))
            age(f)
            require(prune(f)['shadows_compacted'] == 2, 'Task and inherited child compacted')
        else:
            first = f.op(2, 'canonical')
            conflict = f.op(3, 'candidate')
            held = f.op(4, 'held', predecessor(conflict, 'candidate'))
            f.apply(first, conflict, held)
            cs = candidates(f)
            chosen = next(c for c in cs if c['operation']['operation_id'] == conflict['operation_id'])
            descendant = next(c for c in cs if c['operation']['operation_id'] == held['operation_id'])
            result = resolve(f, request(f, chosen, 5, 'chosen', [(descendant, 'discard')]))
            require(result['status'] == 'success', 'Resolution fixture')
            f.apply(f.set_status(6, status('completed', 100), observed(1, status())))
        cursor = initial['at']['revision']
        downloads = []
        while True:
            reply = pull(f, cursor, 2)
            require(reply['status'] == 'success', 'Pull fixture')
            downloads.append(backend.wire[-1])
            cursor = reply['result']['through']['revision']
            if not reply['result']['has_more']:
                break
        terminal = begin(f)
        terminal_pages = [page(f, terminal, i) for i in range(terminal['page_count'])]
        args.output.write_text(json.dumps(dict(
            manifest=initial, pages=initial_pages, checked_at_utc=checked,
            pending_envelope='  ' + json.dumps(pending) + '\n', downloads=downloads,
            terminal_manifest=terminal, terminal_pages=terminal_pages,
            expected_title=None if args.inherited_compaction else 'chosen',
            expected_disposition='recovery' if args.inherited_compaction else 'conflict',
        ), ensure_ascii=False), encoding='utf-8')
        require(cursor == terminal['at']['revision'] and len(downloads) == (2 if args.inherited_compaction else 3), 'Whole-revision pagination')
        print(f'PASS: real snapshot and {len(downloads)} whole-revision pull pages captured', flush=True)
    finally:
        backend.cleanup()


if __name__ == '__main__':
    main()
