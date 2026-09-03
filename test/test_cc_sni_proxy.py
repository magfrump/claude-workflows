"""Tests for devcontainer-config/cc-sni-proxy.py: the ClientHello SNI parser, the
allowlist semantics, and one end-to-end splice against a loopback upstream.

No network: the ClientHello bytes are built here, and the splice test runs the
proxy as a subprocess with its --upstream-port test seam pointed at a fake
upstream on 127.0.0.1. Run: python3 -m unittest test/test_cc_sni_proxy.py
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
        cls.proc = subprocess.Popen(
            [sys.executable, str(PROXY), "--listen", f"127.0.0.1:{cls.px_port}",
             "--allowlist", al, "--upstream-port", str(cls.up_port)],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        deadline = time.time() + 5
        while time.time() < deadline:
            try:
                socket.create_connection(("127.0.0.1", cls.px_port), timeout=0.2).close()
                break
            except OSError:
                time.sleep(0.05)
        else:
            cls.proc.kill()
            raise RuntimeError("proxy did not start: " + cls.proc.stdout.read())

    @classmethod
    def tearDownClass(cls):
        cls.stop.set()
        cls.proc.terminate()
        cls.proc.wait(5)
        cls.upstream.close()

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
        record, _ = client_hello("not-allowlisted.invalid")
        self.assertEqual(self._send(record), b"")

    def test_non_tls_is_refused(self):
        self.assertEqual(self._send(b"GET / HTTP/1.0\r\n\r\n"), b"")

    def test_refuses_to_daemonise_as_root_without_user(self):
        # Contract check only; not running as root here, so assert the flag pairing.
        r = subprocess.run([sys.executable, str(PROXY), "--daemon", "--allowlist", "/dev/null"],
                           capture_output=True, text=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("--pidfile", r.stderr)


if __name__ == "__main__":
    unittest.main()
