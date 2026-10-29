"""Bounded operator maintenance for one account on the guarded LOCAL stack.

No remote endpoint, startup, scheduler or credentials. Select deleted-content
maintenance explicitly; the default remains log/receipt cleanup.
Each batch commits separately. Repeating a pass is safe after interruption.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import uuid

UNCONFIRMED = ('Local retention batch outcome could not be confirmed. It may have committed; '
               'repeating the bounded pass is safe. Earlier confirmed batches remain committed.')


def bounded(maximum):
    def parse(value):
        number = int(value)
        if not 1 <= number <= maximum:
            raise argparse.ArgumentTypeError(f"Must be between 1 and {maximum}")
        return number
    return parse


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--owner', type=uuid.UUID, required=True)
    parser.add_argument('--batch-size', type=bounded(1000), default=200)
    parser.add_argument('--batches', type=bounded(100), default=1)
    parser.add_argument('--policy', choices=('logs', 'deleted-content'), default='logs')
    args = parser.parse_args()
    function, counters = (
        ('prune_deleted_content', ('shadows_compacted', 'payloads_compacted'))
        if args.policy == 'deleted-content'
        else ('prune_log_receipts', ('logs_deleted', 'receipts_deleted')))
    subprocess.run([sys.executable, str(Path(__file__).with_name('local_backend.py'))], check=True)
    for _ in range(args.batches):
        source = ("begin; set local lock_timeout='2s'; set local statement_timeout='10s'; "
                  f"select sync_private.{function}('{args.owner}',{args.batch_size}); commit;")
        try:
            result = subprocess.run(['docker', 'exec', '-i', 'supabase_db_dourstuff-local',
                                     'psql', '-XqAt', '-U', 'postgres', '-d', 'postgres',
                                     '-v', 'ON_ERROR_STOP=1'], input=source, encoding='utf-8',
                                    capture_output=True, timeout=20)
        except (OSError, subprocess.TimeoutExpired):
            raise RuntimeError(UNCONFIRMED) from None
        if result.returncode:
            # A transport loss can follow COMMIT. Never infer rollback or print
            # database error details, which can contain row payloads.
            raise RuntimeError(UNCONFIRMED)
        counts = json.loads(result.stdout)
        print(json.dumps(counts), flush=True)
        if all(counts[key] == 0 for key in counters):
            break


if __name__ == '__main__':
    main()
