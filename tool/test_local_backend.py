"""Guard regression tests; no Docker calls or credentials."""
import unittest
from unittest.mock import patch
from types import SimpleNamespace

from local_backend import docker, verify_bindings


class BindingTests(unittest.TestCase):
    def test_missing_changed_or_public_bindings_fail(self):
        expected = {'5432/tcp': [{'HostIp': '127.0.0.1', 'HostPort': '54322'}]}
        for actual in ({}, {'5432/tcp': None},
                       {'5432/tcp': [{'HostIp': '127.0.0.1', 'HostPort': '54323'}]},
                       {'5432/tcp': [{'HostIp': '0.0.0.0', 'HostPort': '54322'}]}):
            with self.subTest(actual=actual), self.assertRaises(RuntimeError):
                verify_bindings({'HostConfig': {'PortBindings': expected},
                                 'NetworkSettings': {'Ports': actual}})

    def test_exact_and_internal_only_bindings_pass(self):
        for ports in ({}, {'3000/tcp': None},
                      {'5432/tcp': [{'HostIp': '127.0.0.1', 'HostPort': '54322'}]}):
            verify_bindings({'HostConfig': {'PortBindings': ports},
                             'NetworkSettings': {'Ports': ports}})

    def test_only_start_error_is_exposed(self):
        with patch('local_backend.subprocess.run', return_value=SimpleNamespace(
                returncode=1, stderr='binding denied', stdout='private output')):
            with self.assertRaisesRegex(RuntimeError, 'binding denied'):
                docker('start', 'synthetic')
            with self.assertRaisesRegex(RuntimeError, r'^Docker inspect failed \(exit 1\)$'):
                docker('inspect', 'synthetic')


if __name__ == '__main__':
    unittest.main()
