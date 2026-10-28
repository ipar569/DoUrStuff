"""Bounded operator maintenance for one account on the guarded LOCAL stack.

No remote endpoint, startup, scheduler, credentials, or canonical-content cleanup.
Each batch commits separately. Repeating a pass is safe after interruption.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import uuid


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
    args = parser.parse_args()
    subprocess.run([sys.executable, str(Path(__file__).with_name('local_backend.py'))], check=True)
    for _ in range(args.batches):
        source = ("begin; set local lock_timeout='2s'; set local statement_timeout='10s'; "
                  f"select sync_private.prune_log_receipts('{args.owner}',{args.batch_size}); commit;")
        result = subprocess.run(['docker', 'exec', '-i', 'supabase_db_dourstuff-local',
                                 'psql', '-XqAt', '-U', 'postgres', '-d', 'postgres',
                                 '-v', 'ON_ERROR_STOP=1'], input=source, encoding='utf-8',
                                capture_output=True, timeout=20)
        if result.returncode:
            # Database errors can include row payloads; report only the category.
            raise RuntimeError('Local retention batch failed; transaction rolled back. Earlier batches remain committed.')
        counts = json.loads(result.stdout)
        print(json.dumps(counts), flush=True)
        if counts['logs_deleted'] == 0 and counts['receipts_deleted'] == 0:
            break


if __name__ == '__main__':
    main()
