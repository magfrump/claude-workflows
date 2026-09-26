"""Tests for devcontainer-config/cc-sni-proxy.py: the ClientHello SNI parser, the
allowlist semantics, and one end-to-end splice against a loopback upstream.

No network: the ClientHello bytes are built here, and the splice test runs the
proxy as a subprocess with its --upstream-port test seam pointed at a fake
upstream on 127.0.0.1. Run: python3 test/test_cc_sni_proxy.py
(`python3 -m unittest test/test_cc_sni_proxy.py` does not work: the stdlib `test`
package shadows this directory). test/cc-sni-proxy-unittest.bats runs it in the
bats suite.
"""
import importlib.util
import os
import pathlib
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock

HERE = pathlib.Path(__file__).resolve().parent
PROXY = HERE.parent / "devcontainer-config" / "cc-sni-proxy.py"

spec = importlib.util.spec_from_file_location("cc_sni_proxy", PROXY)
proxy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(proxy)


def client_hello(sni=None, extra_ext=b""):
    """Build a TLS 1.2-style ClientHello record carrying the given SNI.
    Returns (record bytes, handshake message bytes)."""
    exts = b""
    if sni is not None:
        name = sni.encode()
        sn = b"\x00" + len(name).to_bytes(2, "big") + name
        sn_list = len(sn).to_bytes(2, "big") + sn
        exts += b"\x00\x00" + len(sn_list).to_bytes(2, "big") + sn_list
    exts += extra_ext
    body = (b"\x03\x03" + b"\x11" * 32          # legacy_version + random
            + b"\x00"                           # empty session id
            + b"\x00\x02\x13\x01"               # one cipher suite
            + b"\x01\x00")                      # null compression
    if sni is not None or extra_ext:
        body += len(exts).to_bytes(2, "big") + exts
    hs = b"\x01" + len(body).to_bytes(3, "big") + body
    record = b"\x16\x03\x01" + len(hs).to_bytes(2, "big") + hs
    return record, hs


class ParseSNI(unittest.TestCase):
    def test_extracts_and_normalises(self):
        _, hs = client_hello("API.Anthropic.COM.")
        self.assertEqual(proxy.parse_sni(hs), "api.anthropic.com")

    def test_sni_after_other_extensions(self):
        # A padding extension (type 21) before server_name must be skipped.
        pad = b"\x00\x15\x00\x04\x00\x00\x00\x00"
        _, hs = client_hello("github.com", extra_ext=b"")
        # Rebuild with the padding first: extensions are [pad, sni].
        name = b"github.com"
        sn = b"\x00" + len(name).to_bytes(2, "big") + name
        sn_list = len(sn).to_bytes(2, "big") + sn
        sni_ext = b"\x00\x00" + len(sn_list).to_bytes(2, "big") + sn_list
        exts = pad + sni_ext
        body = (b"\x03\x03" + b"\x11" * 32 + b"\x00" + b"\x00\x02\x13\x01" + b"\x01\x00"
                + len(exts).to_bytes(2, "big") + exts)
        hs = b"\x01" + len(body).to_bytes(3, "big") + body
        self.assertEqual(proxy.parse_sni(hs), "github.com")

    def test_no_extensions(self):
        _, hs = client_hello(None)
        with self.assertRaises(proxy.HelloError):
            proxy.parse_sni(hs)

    def test_no_server_name_extension(self):
        pad = b"\x00\x15\x00\x02\x00\x00"
        _, hs = client_hello(None, extra_ext=pad)
        with self.assertRaises(proxy.HelloError):
            proxy.parse_sni(hs)

    def test_not_a_client_hello(self):
        _, hs = client_hello("a.example")
        with self.assertRaises(proxy.HelloError):
            proxy.parse_sni(b"\x02" + hs[1:])   # ServerHello type

    def test_truncated(self):
        _, hs = client_hello("a.example")
        with self.assertRaises(proxy.HelloError):
            proxy.parse_sni(hs[:20])

    def test_invalid_hostname_rejected(self):
        for bad in ("bad_host.example", "-leading.example", "sp ace.example", ""):
            _, hs = client_hello(bad)
            with self.assertRaises(proxy.HelloError, msg=bad):
                proxy.parse_sni(hs)


class AllowlistSemantics(unittest.TestCase):
    def test_exact_and_zone(self):
        al = proxy.Allowlist(exact={"api.anthropic.com"}, zones={"github.com"})
        self.assertTrue(al.allows("api.anthropic.com"))
        self.assertFalse(al.allows("evil.api.anthropic.com"))
        self.assertFalse(al.allows("anthropic.com"))
        self.assertTrue(al.allows("github.com"))
        self.assertTrue(al.allows("api.github.com"))
        self.assertTrue(al.allows("a.b.github.com"))
        self.assertFalse(al.allows("notgithub.com"))
        self.assertFalse(al.allows("github.com.evil.example"))

    def test_load_file(self):
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write("# comment\n\nApi.Anthropic.com  # trailing\n.GitHub.com\n")
        try:
            al = proxy.Allowlist.load(f.name)
        finally:
            os.unlink(f.name)
        self.assertEqual(al.exact, {"api.anthropic.com"})
        self.assertEqual(al.zones, {"github.com"})


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class Splice(unittest.TestCase):
    """Run the proxy for real on loopback. The fake upstream echoes whatever it
    receives, so a client that gets its own ClientHello back was spliced."""

    @classmethod
    def setUpClass(cls):
        cls.up_port, cls.px_port = free_port(), free_port()
        cls.upstream = socket.socket()
        cls.upstream.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        cls.upstream.bind(("127.0.0.1", cls.up_port))
        cls.upstream.listen(5)
        cls.stop = threading.Event()

        def echo():
            cls.upstream.settimeout(0.2)
            while not cls.stop.is_set():
                try:
                    conn, _ = cls.upstream.accept()
                except socket.timeout:
                    continue
                with conn:
                    data = conn.recv(65536)
                    conn.sendall(data)
        cls.thread = threading.Thread(target=echo, daemon=True)
        cls.thread.start()

        cls.tmp = tempfile.mkdtemp()
        al = os.path.join(cls.tmp, "allowlist")
        with open(al, "w") as f:
            f.write("localhost\n")
        # The decision log goes to a file so a test can read it while the proxy runs.
        cls.log_path = os.path.join(cls.tmp, "proxy.log")
        cls.log_f = open(cls.log_path, "w")
        cls.proc = subprocess.Popen(
            [sys.executable, str(PROXY), "--listen", f"127.0.0.1:{cls.px_port}",
             "--allowlist", al, "--upstream-port", str(cls.up_port)],
            stdout=cls.log_f, stderr=subprocess.STDOUT, text=True)
        deadline = time.time() + 5
        while time.time() < deadline:
            try:
                socket.create_connection(("127.0.0.1", cls.px_port), timeout=0.2).close()
                break
            except OSError:
                time.sleep(0.05)
        else:
            cls.proc.kill()
            cls.log_f.close()
            raise RuntimeError("proxy did not start: " + open(cls.log_path).read())

    @classmethod
    def tearDownClass(cls):
        cls.stop.set()
        cls.proc.terminate()
        cls.proc.wait(5)
        cls.log_f.close()
        cls.upstream.close()

    def _log(self):
        with open(self.log_path) as f:
            return f.read()

    def _send(self, record):
        with socket.create_connection(("127.0.0.1", self.px_port), timeout=5) as c:
            c.sendall(record)
            chunks = b""
            try:
                while True:
                    d = c.recv(65536)
                    if not d:
                        break
                    chunks += d
            except socket.timeout:
                pass
            return chunks

    def test_allowlisted_sni_is_spliced_to_the_name_the_client_asked_for(self):
        record, _ = client_hello("localhost")
        self.assertEqual(self._send(record), record)

    def test_non_allowlisted_sni_is_refused_with_no_bytes(self):
        # The SNI must RESOLVE and reach the echo upstream if admitted, or a
        # missing allowlist check would still yield no bytes (the FAIL path).
        # 127.0.0.1 is a syntactically valid hostname that resolves to the fake
        # upstream (--upstream-port) and is not in the allowlist ("localhost").
        record, _ = client_hello("127.0.0.1")
        self.assertEqual(self._send(record), b"")
        self.assertIn("REJECT sni=127.0.0.1 ", self._log())
        self.assertIn("not in allowlist", self._log())
        self.assertNotIn("ALLOW sni=127.0.0.1", self._log())

    def test_non_tls_is_refused(self):
        self.assertEqual(self._send(b"GET / HTTP/1.0\r\n\r\n"), b"")

    def test_daemon_requires_pidfile(self):
        r = subprocess.run([sys.executable, str(PROXY), "--daemon", "--allowlist", "/dev/null"],
                           capture_output=True, text=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("--pidfile", r.stderr)


class RootRefusal(unittest.TestCase):
    """In-process: pretend to be root and make fork() fatal, so the only way to
    get the expected SystemExit is daemonize()'s root-without---user refusal."""

    def test_refuses_to_daemonise_as_root_without_user(self):
        tmp = tempfile.mkdtemp()

        def no_fork():
            raise AssertionError("daemonize() reached fork() as root without --user")

        with mock.patch.object(proxy.os, "geteuid", return_value=0), \
                mock.patch.object(proxy.os, "fork", side_effect=no_fork):
            with self.assertRaises(SystemExit) as cm:
                proxy.main(["--daemon", "--pidfile", os.path.join(tmp, "pid"),
                            "--log", os.path.join(tmp, "log"), "--allowlist", "/dev/null"])
        self.assertIn("refusing to run as root", str(cm.exception.code))
        self.assertFalse(os.path.exists(os.path.join(tmp, "log")),
                         "the refusal must come before any side effect")


if __name__ == "__main__":
    unittest.main()
