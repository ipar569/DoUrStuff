"""Operator lost-acknowledgement regressions, using synthetic subprocess replies."""
from contextlib import redirect_stdout
import io
import json
import subprocess
import unittest
from unittest.mock import patch

from run_backend_retention import main


class RetentionRunnerTests(unittest.TestCase):
    def test_deleted_content_selects_policy_and_stops_on_empty_pass(self):
        counts = dict(shadows_compacted=0, payloads_compacted=0, revision=42)
        calls = []

        def run(args, **kwargs):
            calls.append((args, kwargs))
            return subprocess.CompletedProcess(args, 0, json.dumps(counts), '')

        output = io.StringIO()
        with patch('sys.argv', ['retention', '--owner', '11111111-1111-4111-8111-111111111111',
                               '--policy', 'deleted-content', '--batches', '3']), \
                patch('run_backend_retention.subprocess.run', side_effect=run), redirect_stdout(output):
            main()
        self.assertEqual(len(calls), 2)
        self.assertNotIn('--start', calls[0][0])
        self.assertIn('sync_private.prune_deleted_content', calls[1][1]['input'])
        self.assertIn("lock_timeout='2s'", calls[1][1]['input'])
        self.assertEqual(json.loads(output.getvalue()), counts)

    def test_lost_commit_ack_preserves_prior_success_and_reports_unknown(self):
        counts = dict(logs_deleted=1, receipts_deleted=1, retained_after=1)
        calls = []

        def run(args, **kwargs):
            calls.append(args)
            if len(calls) == 1:  # Read-only stack guard.
                return subprocess.CompletedProcess(args, 0)
            if len(calls) == 2:  # First batch committed and confirmed.
                return subprocess.CompletedProcess(args, 0, json.dumps(counts), '')
            # Second batch may have committed before the connection failed.
            return subprocess.CompletedProcess(args, 1, '', 'private row payload')

        output = io.StringIO()
        with patch('sys.argv', ['retention', '--owner', '11111111-1111-4111-8111-111111111111',
                                '--batch-size', '1', '--batches', '3']), \
                patch('run_backend_retention.subprocess.run', side_effect=run), redirect_stdout(output):
            with self.assertRaises(RuntimeError) as caught:
                main()
        self.assertEqual(len(calls), 3)  # No further writes after uncertain outcome.
        self.assertEqual(json.loads(output.getvalue()), counts)
        self.assertIn('may have committed', str(caught.exception))
        self.assertIn('repeating the bounded pass is safe', str(caught.exception))
        self.assertIn('Earlier confirmed batches remain committed', str(caught.exception))
        self.assertNotIn('rolled back', str(caught.exception))
        self.assertNotIn('private row payload', output.getvalue() + str(caught.exception))

    def test_timeout_never_claims_rollback_or_exposes_partial_output(self):
        timeout = subprocess.TimeoutExpired('docker', 20, output='private partial output', stderr='private error')
        with patch('sys.argv', ['retention', '--owner', '11111111-1111-4111-8111-111111111111']), \
                patch('run_backend_retention.subprocess.run', side_effect=[subprocess.CompletedProcess([], 0), timeout]):
            with self.assertRaises(RuntimeError) as caught:
                main()
        self.assertIn('may have committed', str(caught.exception))
        self.assertIsNone(caught.exception.__cause__)
        self.assertTrue(caught.exception.__suppress_context__)
        self.assertNotIn('private', str(caught.exception))


if __name__ == '__main__':
    unittest.main()
