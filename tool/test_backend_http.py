"""Local-only credential transport regressions; dummy credentials, no Docker."""
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
import threading
import unittest
from unittest.mock import patch
import urllib.request

from test_backend_foundation import Backend


@contextmanager
def endpoint(kind, redirect=None):
    hits = []

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            hits.append(self.headers.get("Authorization"))
            if redirect:
                self.send_response(302)
                self.send_header("Location", redirect)
                self.end_headers()
            else:
                body = json.dumps({"source": kind}).encode()
                self.send_response(200)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

        def log_message(self, *_args):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, kwargs={"poll_interval": 0.02}, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{server.server_port}", hits
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


def backend(url):
    state = {"API_URL": "http://127.0.0.1:54321", "ANON_KEY": "dummy-anon", "SERVICE_ROLE_KEY": "dummy-admin"}
    with patch("test_backend_foundation.command", return_value=json.dumps(state)):
        result = Backend("unused")
    result.url = url  # Synthetic ephemeral loopback server; no real CLI or keys.
    return result


class LocalTransportTests(unittest.TestCase):
    def test_environment_proxy_never_receives_credentials(self):
        with endpoint("backend") as (url, direct), endpoint("proxy") as (proxy_url, proxied):
            with patch.dict(os.environ, {"http_proxy": proxy_url, "no_proxy": ""}, clear=True), \
                    patch.object(urllib.request, "_opener", None):
                status, reply = backend(url).request("GET", "/probe", "dummy-token")
            self.assertEqual((status, reply), (200, {"source": "backend"}))
            self.assertEqual(direct, ["Bearer dummy-token"])
            self.assertEqual(proxied, [])

    def test_redirect_never_forwards_credentials(self):
        with endpoint("target") as (target_url, target):
            with endpoint("backend", target_url + "/sink") as (url, direct):
                with patch.dict(os.environ, {}, clear=True), patch.object(urllib.request, "_opener", None):
                    with self.assertRaisesRegex(RuntimeError, "redirect"):
                        backend(url).request("GET", "/probe", "dummy-token")
                self.assertEqual(direct, ["Bearer dummy-token"])
                self.assertEqual(target, [])


if __name__ == "__main__":
    unittest.main()
