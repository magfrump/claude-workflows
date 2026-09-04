#!/usr/bin/python3
"""cc-sni-proxy — SNI-filtering splice proxy for the cc-isolated egress boundary.

init-firewall.sh REDIRECTs every outbound tcp/443 connection that is NOT made by
this proxy's own uid or by root (root runs the firewall script itself and its two
general reachability probes; its two SNI probes run as `node` on purpose) to
127.0.0.1:<port>, where this process:

  1. reads the TLS ClientHello and extracts the server_name (SNI) — nothing is
     decrypted and no certificate is involved; this is a peek, not interception;
  2. admits the connection only if the SNI matches the allowlist file exactly, or
     is the zone / a subdomain of an entry written as `.zone`;
  3. resolves THE SNI NAME ITSELF and connects to that address on 443, then
     splices bytes in both directions until either side closes.

Step 3 is why a forged SNI cannot steer a connection: the original destination
(SO_ORIGINAL_DST) is read for the log line only and is never connected to. A
client that says `api.anthropic.com` reaches whatever api.anthropic.com resolves
to — and that address must ALSO be in the firewall's address+port ipset, which
still applies to this process's egress (defence in depth, closing the
"CDN neighbour on the same IP" overreach that IP matching alone cannot).
Resolution goes to the container's filtering dnsmasq — this process's port-53
traffic is REDIRECTed there by the firewall, whatever /etc/resolv.conf says — and
is IPv4-only, matching the IPv4-only ipset (IPv6 is default-denied outright). Non-443 ports are not redirected here and stay IP+port-matched.

Single file, stdlib only (python3.11 ships in the node:22 base — no apt package,
no pip), root-owned 0555 in the image, listed in install.sh's payload and in the
launcher's bless manifest (cc-isolated.sh enforcement_files) like every other
enforcement file.
"""
import argparse
import asyncio
import os
import pwd
import re
import signal
import socket
import struct
import sys
import time

SO_ORIGINAL_DST = 80          # linux/netfilter_ipv4.h; not exposed by the socket module
TLS_HANDSHAKE = 22
CLIENT_HELLO = 1
HELLO_MAX = 65536             # a ClientHello larger than this is not a ClientHello
HELLO_TIMEOUT = 10.0
CONNECT_TIMEOUT = 10.0
LABEL = re.compile(r"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")


class HelloError(ValueError):
    """The bytes are not a ClientHello we can extract a hostname from."""


def _u16(b, i):
    return (b[i] << 8) | b[i + 1]


def normalise_name(raw):
    """Decode + validate an SNI hostname; lower-case, trailing dot stripped."""
    try:
        name = raw.decode("ascii").lower().rstrip(".")
    except UnicodeDecodeError:
        raise HelloError("non-ASCII server_name")
    if not name or len(name) > 253 or not all(LABEL.match(l) for l in name.split(".")):
        raise HelloError("server_name is not a valid hostname")
    return name


def parse_sni(hs):
    """Return the server_name from a ClientHello HANDSHAKE MESSAGE (record layer
    already stripped). Raises HelloError for anything else. Layout per RFC 8446
    §4.1.2 and RFC 6066 §3; every offset is bounds-checked by the try/except."""
    try:
        if hs[0] != CLIENT_HELLO:
            raise HelloError("handshake message is not a ClientHello")
        length = int.from_bytes(hs[1:4], "big")
        body = hs[4:4 + length]
        if len(body) < length:
            raise HelloError("truncated ClientHello")
        p = 2 + 32                                  # legacy_version + random
        p += 1 + body[p]                            # legacy_session_id
        p += 2 + _u16(body, p)                      # cipher_suites
        p += 1 + body[p]                            # legacy_compression_methods
        if p >= len(body):
            raise HelloError("ClientHello carries no extensions")
        end = p + 2 + _u16(body, p)
        p += 2
        while p + 4 <= end:
            ext_type, ext_len = _u16(body, p), _u16(body, p + 2)
            p += 4
            if ext_type == 0:                       # server_name
                q = p + 2                           # skip ServerNameList length
                while q + 3 <= p + ext_len:
                    name_type, name_len = body[q], _u16(body, q + 1)
                    q += 3
                    if name_type == 0:              # host_name
                        return normalise_name(body[q:q + name_len])
                    q += name_len
            p += ext_len
        raise HelloError("no server_name extension")
    except IndexError:
        raise HelloError("malformed ClientHello")


async def read_client_hello(reader):
    """Read TLS records until one whole handshake message is buffered. Returns
    (raw record bytes to replay upstream, the handshake message)."""
    raw, hs, need = b"", b"", None
    while True:
        hdr = await reader.readexactly(5)
        ctype, _version, rlen = struct.unpack("!BHH", hdr)
        if ctype != TLS_HANDSHAKE:
            raise HelloError(f"first record is not a TLS handshake (type {ctype})")
        body = await reader.readexactly(rlen)
        raw += hdr + body
        hs += body
        if need is None and len(hs) >= 4:
            need = 4 + int.from_bytes(hs[1:4], "big")
        if need is not None and len(hs) >= need:
            return raw, hs[:need]
        if len(raw) > HELLO_MAX:
            raise HelloError("ClientHello exceeds 64 KiB")


class Allowlist:
    """`name` lines match exactly; `.zone` lines match the zone and every
    subdomain of it. Blank lines and #-comments are ignored."""

    def __init__(self, exact=(), zones=()):
        self.exact, self.zones = set(exact), set(zones)

    @classmethod
    def load(cls, path):
        al = cls()
        with open(path) as f:
            for line in f:
                line = line.split("#", 1)[0].strip().lower()
                if not line:
                    continue
                (al.zones if line.startswith(".") else al.exact).add(line.lstrip("."))
        return al

    def allows(self, name):
        return name in self.exact or any(
            name == z or name.endswith("." + z) for z in self.zones)


def original_dst(sock):
    try:
        port, ip = struct.unpack("!2xH4s8x", sock.getsockopt(socket.SOL_IP, SO_ORIGINAL_DST, 16))
        return f"{socket.inet_ntoa(ip)}:{port}"
    except (OSError, struct.error, AttributeError):
        return "unknown"


def log(msg):
    print(time.strftime("%Y-%m-%dT%H:%M:%S"), msg, flush=True)


async def pump(reader, writer):
    try:
        while data := await reader.read(65536):
            writer.write(data)
            await writer.drain()
        if writer.can_write_eof():
            writer.write_eof()
    except OSError:
        pass


async def handle(client_r, client_w, allow, upstream_port):
    orig = original_dst(client_w.get_extra_info("socket"))
    up_w = None
    try:
        try:
            raw, hs = await asyncio.wait_for(read_client_hello(client_r), HELLO_TIMEOUT)
            sni = parse_sni(hs)
        except (HelloError, asyncio.IncompleteReadError, asyncio.TimeoutError, OSError) as e:
            log(f"REJECT orig_dst={orig}: {e}")
            return
        if not allow.allows(sni):
            log(f"REJECT sni={sni} orig_dst={orig}: not in allowlist")
            return
        try:
            infos = await asyncio.get_running_loop().getaddrinfo(
                sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)
            ip = infos[0][4][0]
            up_r, up_w = await asyncio.wait_for(
                asyncio.open_connection(ip, upstream_port), CONNECT_TIMEOUT)
        except (OSError, asyncio.TimeoutError) as e:
            log(f"FAIL sni={sni} orig_dst={orig}: {e} (resolved address not in the ipset?)")
            return
        log(f"ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}")
        up_w.write(raw)
        await asyncio.gather(pump(client_r, up_w), pump(up_r, client_w), return_exceptions=True)
    finally:
        for w in (client_w, up_w):
            if w is not None:
                w.close()


async def serve(args, ready_fd=None):
    allow = Allowlist.load(args.allowlist)
    host, _, port = args.listen.rpartition(":")
    server = await asyncio.start_server(
        lambda r, w: handle(r, w, allow, args.upstream_port), host, int(port), reuse_address=True)
    log(f"listening on {args.listen}; {len(allow.exact)} exact names, {len(allow.zones)} zones")
    if ready_fd is not None:
        os.write(ready_fd, b"ready")
        os.close(ready_fd)
    async with server:
        await server.serve_forever()


def stop_prior(pidfile):
    """Kill the instance named by the pidfile, if it is one of us and alive."""
    try:
        with open(pidfile) as f:
            pid = int(f.read().strip())
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            is_ours = b"cc-sni-proxy" in f.read()
    except (OSError, ValueError):
        is_ours = False
    if is_ours:
        os.kill(pid, signal.SIGTERM)
        for _ in range(30):
            if not os.path.exists(f"/proc/{pid}"):
                break
            time.sleep(0.1)
        else:
            os.kill(pid, signal.SIGKILL)
    try:
        os.unlink(pidfile)
    except OSError:
        pass


def daemonize(args):
    """Fork, detach, drop to --user, bind, then report readiness to the caller.
    Exit status is the contract init-firewall.sh relies on: 0 only once the
    child is LISTENING; anything else means "no proxy", and the firewall must
    then fail closed rather than install a REDIRECT to nothing."""
    if os.geteuid() == 0 and not args.user:
        sys.exit("cc-sni-proxy: refusing to run as root; pass --user")
    stop_prior(args.pidfile)
    log_fd = os.open(args.log, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
    r, w = os.pipe()
    pid = os.fork()
    if pid:
        os.close(w)
        os.close(log_fd)
        msg = os.read(r, 4096)
        if msg == b"ready":
            with open(args.pidfile, "w") as f:
                f.write(f"{pid}\n")
            return 0
        os.waitpid(pid, 0)
        sys.stderr.write(f"cc-sni-proxy: failed to start: {msg.decode(errors='replace') or 'child exited'}\n")
        return 1
    # --- child ---
    os.close(r)
    os.setsid()
    null = os.open(os.devnull, os.O_RDONLY)
    os.dup2(null, 0)
    os.dup2(log_fd, 1)
    os.dup2(log_fd, 2)
    # Close every other inherited fd: the caller's stdout is the devcontainer
    # postStartCommand pipe, and a daemon holding it open would hang the launch.
    for fd in os.listdir("/proc/self/fd"):
        fd = int(fd)
        if fd > 2 and fd != w:
            try:
                os.close(fd)
            except OSError:
                pass
    try:
        if args.user:
            pw = pwd.getpwnam(args.user)
            os.setgroups([])
            os.setgid(pw.pw_gid)
            os.setuid(pw.pw_uid)
        asyncio.run(serve(args, ready_fd=w))
    except BaseException as e:  # report to the parent, then die
        try:
            os.write(w, f"error: {e!r}".encode())
        except OSError:
            pass
        os._exit(1)
    os._exit(0)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("--listen", default="127.0.0.1:3443", help="host:port to accept redirected connections on")
    ap.add_argument("--allowlist", required=True, help="file of `name` / `.zone` lines")
    ap.add_argument("--daemon", action="store_true", help="fork, detach, write --pidfile, exit 0 once listening")
    ap.add_argument("--pidfile", help="pidfile; a prior instance named here is terminated first")
    ap.add_argument("--user", help="unprivileged user to drop to after forking (required when root)")
    ap.add_argument("--log", default="/run/cc-sni-proxy/proxy.log", help="daemon log file (truncated on start)")
    ap.add_argument("--upstream-port", type=int, default=443, help=argparse.SUPPRESS)  # test seam only
    args = ap.parse_args(argv)
    if args.daemon:
        if not args.pidfile:
            ap.error("--daemon requires --pidfile")
        return daemonize(args)
    asyncio.run(serve(args))
    return 0


if __name__ == "__main__":
    sys.exit(main())
