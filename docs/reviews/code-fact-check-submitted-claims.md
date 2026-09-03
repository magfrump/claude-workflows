# Code Fact-Check Report — Submitted Claims

Commit: abbd42d
**Repository:** claude-workflows (`/workspace`)
**Scope:** 8 endorsement claims routed by security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review, for `git diff bd41aef..HEAD -- devcontainer-config/`
**Checked:** 2026-09-03
**Total claims checked:** 8 (claims 2 and 8 split on verdict divergence → 10 verdict rows)
**Summary:** 7 verified, 2 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

**Relationship to the harvested-claims report.** `docs/reviews/code-fact-check-report.md` (44 claims, same commit) is treated as settled; its claims are cited, not re-verdicted. Three submitted claims rest on one of its rows: claim 1 on its Claim 13 (`daemonize()` returns 0 on exactly one path, gated on the readiness byte — Verified, **static** there, now **executed** here), claim 3 on its Claims 32–34, and claim 8 on its Claim 26.

**Execution environment (the same for every executed verdict).** cwd `/workspace`, `LC_ALL=C`, uid 1000 (`node`), no root, no Docker, no `CAP_NET_ADMIN`. `bats`, `shellcheck`, `python3` 3.11.2, `ipset`/`iptables` binaries present but unusable (`ipset create` → `Operation not permitted`; `unshare -Ur --net` → `Operation not permitted`, logged in `cfc-sc-2`). Full-run command sequences come from a scratch harness that reproduces `test/init-firewall-rules.bats` `setup()`'s PATH stubs outside bats, so the whole emitted `iptables`/`ipset` sequence can be read verbatim rather than grepped one assertion at a time; the harness is appended verbatim to `cfc-sc-8-phase-ab-boundary-abbd42d.txt` §G.

---

## Submitted Claims

## Claim 1: "The SNI proxy is started, and verified live, strictly before the `CC_SNI` nat REDIRECT that depends on it is installed, so a proxy that fails to start cannot leave a redirect pointing at a closed port."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/init-firewall.sh:874-886`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the start-and-readiness handshake completes before any `CC_SNI` chain or REDIRECT rule is issued; that `daemonize()` returns 0 only after the child has bound its listening socket, and returns 1 with no pidfile when the bind fails; and that a non-zero start aborts the run with zero `REDIRECT --to-ports 3443` rules emitted and forced DROP policies. Does not establish kernel-level behaviour of the redirect, nor that a child which dies *after* signalling ready is detected before the end-of-run probes.
**Legibility-target:** for-orchestrator-synthesis

The ordering is file order inside a single straight-line region, with no loop or conditional between the two points:

```
874	if ! "$SNI_PROXY_BIN" --daemon --pidfile "$SNI_PIDFILE" --user ccproxy \
875	        --listen "127.0.0.1:$SNI_PORT" --allowlist "$SNI_ALLOWLIST" --log "$SNI_LOG"; then
876	    echo "ERROR: SNI proxy failed to start (see $SNI_LOG)" >&2
877	    exit 1
878	fi
879	echo "SNI proxy running as uid $CCPROXY_UID on 127.0.0.1:$SNI_PORT, allowlist $SNI_ALLOWLIST"
...
882	iptables -t nat -N CC_SNI
...
885	iptables -t nat -A CC_SNI -p tcp -j REDIRECT --to-ports "$SNI_PORT"
886	iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI
```
(`init-firewall.sh:874-886`; the enclosing `if` is read through its `fi` at `:878`, and the `CC_SNI` block continues to the filter-side guard at `:892-896` — read.)

The emitted sequence from a full stubbed run confirms it at runtime, not just on the page: `cc-sni-proxy --daemon …` is log line 62 and the first `REDIRECT --to-ports 3443` is line 66 (`cfc-sc-8` §C).

**"Verified live" is the `daemonize()` readiness handshake, and it was executed against the real proxy.** Success path: `python3 devcontainer-config/cc-sni-proxy.py --daemon --pidfile … --allowlist … --listen 127.0.0.1:48497 --log …` → exit 0, pidfile `203952`, and a `socket.create_connection` to that port **after the parent had already returned** succeeded — i.e. the socket was listening at the moment the exit status was produced. Failure path: with the port pre-bound by another socket, exit 1, stderr `cc-sni-proxy: failed to start: error: OSError(98, "…address already in use")`, and **no pidfile written**. Command: `LC_ALL=C bash /tmp/claude-1000/cfc/daemon_probe.sh`, cwd `/workspace`, 2026-09-03T23:20:46Z; assertions all printed, wrapper shell then exited 144 because its own trailing `pkill` signalled it (noted in the log).

The mechanism is the pipe handshake — the child writes `b"ready"` strictly after `asyncio.start_server` has returned:

```
202	    server = await asyncio.start_server(
203	        lambda r, w: handle(r, w, allow, args.upstream_port), host, int(port), reuse_address=True)
...
205	    if ready_fd is not None:
206	        os.write(ready_fd, b"ready")
```
(`cc-sni-proxy.py:202-207`) and the parent returns 0 on exactly that byte, writing the pidfile only then (`:249-253`; the function continues through the child branch to `os._exit(0)` at `:286` — read). This is `code-fact-check-report.md` Claim 13, promoted here from static to executed.

Fail-closed direction, executed: `LC_ALL=C bats -f 'before the REDIRECT|fails to start aborts the run' test/init-firewall-rules.bats`, cwd `/workspace`, exit 0, 2026-09-03T23:20:46Z — both pass, and the second asserts `grep -c 'REDIRECT --to-ports 3443' "$CMD_LOG"` is `0` while `iptables -w 5 -P OUTPUT DROP` is present.

Residue the critic named, confirmed: nothing after `:878` re-checks the child. This is an asymmetry with dnsmasq, which *does* get a liveness re-check — `if [ -z "$dnsmasq_pid" ] || ! kill -0 "$dnsmasq_pid" 2>/dev/null; then` (`init-firewall.sh:674`). In practice the end-of-run probe at `:928` (`runuser -u node -- curl … https://api.anthropic.com/`) would catch a proxy that died between ready and the end of the script, since that probe must traverse the redirect; a death *after* that probe is undetected.

**Evidence:** `devcontainer-config/init-firewall.sh:874-886`, `:674`, `:928`, `devcontainer-config/cc-sni-proxy.py:199-209`, `:240-256`, `docs/reviews/execution-logs/cfc-sc-1-proxy-start-order-abbd42d.txt`, `docs/reviews/execution-logs/cfc-sc-8-phase-ab-boundary-abbd42d.txt`, `docs/reviews/code-fact-check-report.md` Claim 13

---

## Claim 2a: "Every `allowed-domains` member is written with a `tcp:` proto prefix and the OUTPUT accept matches `dst,dst`."

**Submitted by:** security-reviewer (script-side half of the submitted claim)
**Location:** `devcontainer-config/init-firewall.sh:383-385`, `:744-745`, `:902`
**Type:** Structural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every one of the three `ipset add` call sites emits a member of the form `<addr-or-cidr>,tcp:<port>`, that no other code path adds a member, that the set is created `hash:net,port`, and that the single consuming accept matches `dst,dst`. Does not establish anything about how the kernel matches a datagram against those members (claim 2b).
**Legibility-target:** for-orchestrator-synthesis

There are exactly three `ipset add` call sites, and all three hard-code the proto:

```
744	    ipset add -exist allowed-domains "$cidr,tcp:443"
745	    ipset add -exist allowed-domains "$cidr,tcp:22"
...
753	    ipset add -exist allowed-domains "$member"
```
(`init-firewall.sh:744-745`, `:753`; both enclosing `while read … done < <(…)` loops read to their closing `done` at `:746` and `:754`.) The `$member` values are the only non-literal input, and they are built one line at a time in phase A with the prefix baked in: `RESOLVED_MEMBERS="${RESOLVED_MEMBERS}${ip},tcp:${port}"$'\n'` (`init-firewall.sh:384`, inside the `for port in $(echo "$ports" | tr ',' '\n')` loop at `:383-385`, whose enclosing `while read -r ip` runs to `:386` and whose outer `while read -r domain ports` runs to `:387` — read). Both halves are pre-validated: `$ip` against a dotted-quad regex at `:373`, `$ports` against `^[0-9]{1,5}(,[0-9]{1,5})*$` plus a 1–65535 range test in `parse_entry` at `:126-130`.

The set type and the consumer:

```
731	ipset create allowed-domains hash:net,port
...
902	iptables -A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT
```
(`init-firewall.sh:731`, `:902`.)

Executed. Full stubbed run, cwd `/workspace`, 2026-09-03T23:21:34Z, exit 0: the emitted sequence contains 11 `ipset add` lines, and `grep '^ipset add' … | grep -vc 'tcp:'` is **0** — no member without a `tcp:` prefix. `bats -f 'the allowlist ipset is address'` and `bats -f 'GitHub CIDRs are admitted'` both pass.

**Evidence:** `devcontainer-config/init-firewall.sh:373`, `:383-387`, `:126-130`, `:731`, `:744-745`, `:753`, `:902`, `docs/reviews/execution-logs/cfc-sc-2-udp-typed-members-abbd42d.txt`

---

## Claim 2b: "UDP to an allowlisted address and port is therefore denied."

**Submitted by:** security-reviewer (kernel-side half of the submitted claim)
**Location:** `devcontainer-config/init-firewall.sh:902`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed (attempted; blocked)
**Scope:** Covers only that the attempt to exercise it was made and failed for a named reason. Does not establish, and cannot from this sandbox, that `ipset`'s `hash:net,port` refuses to match a UDP datagram against a `tcp:`-typed member.
**Legibility-target:** for-orchestrator-synthesis

**Blocker, named and executed.** The claim's subject is kernel matching semantics, which requires either creating the set or a network namespace. Both are refused: `$ ipset create t_cfc hash:net,port` → `ipset v7.17: Kernel error received: Operation not permitted`; `$ unshare -Ur --net true` → `unshare: unshare failed: Operation not permitted`; `$ id` → `uid=1000(node) gid=1000(node) groups=1000(node)`. cwd `/workspace`, 2026-09-03T23:21:34Z. No `CAP_NET_ADMIN`, no user namespace, no Docker. The bats suite is explicit that this is out of its scope too: "Kernel/netfilter semantics are out of scope here and need a privileged container" (`test/init-firewall-rules.bats:17-18`).

What *can* be said from the ruleset, and is the reason the conclusion is likely right rather than merely asserted: for a non-root, non-`dnsmasq` uid, the emitted OUTPUT chain offers a UDP datagram to a non-loopback allowlisted address only four possible accepts before the terminal reject — the four `--dport 53` owner-scoped resolver/gateway accepts (log lines 18–21, 53–56, all `--uid-owner 999` or `0`), the `-o lo` accept (line 39), the `ESTABLISHED,RELATED` accept (line 61), and the ipset accept (line 73). None of the first three matches; so the claim reduces entirely to whether line 73 matches, i.e. exactly the untestable half. The terminal `iptables -A OUTPUT -j REJECT` (line 74) catches it otherwise.

To settle it, run the check in a privileged container per `guides/devcontainer-setup.md`.

**Evidence:** `devcontainer-config/init-firewall.sh:902`, `:905`, `test/init-firewall-rules.bats:17-18`, `docs/reviews/execution-logs/cfc-sc-2-udp-typed-members-abbd42d.txt`, `docs/reviews/execution-logs/cfc-sc-8-phase-ab-boundary-abbd42d.txt`

---

## Claim 3: "The dnsmasq uid's exemption from `CC_DNS`/`CC_DNS_GUARD` does not grant it arbitrary outbound port-53 reach; its upstream accepts are address-scoped to the parsed resolvers and the bridge gateway."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/init-firewall.sh:541-544`, `:788-791`, `:682-683`, `:694-695`
**Type:** Behavioral / Structural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every emitted rule naming the dnsmasq uid is either an address-scoped `--dport 53` ACCEPT or a `RETURN` inside a redirect/reject chain; that zero ACCEPTs for that uid lack a `-d <addr>` scope; that zero lack `--dport 53`; and that the addresses named are exactly the resolvers `compose_dns_resolvers` parsed plus the detected bridge gateway. Does not establish kernel enforcement of `-m owner --uid-owner`, and does not cover reach the uid has in common with every other uid (loopback via `-o lo`, and the ipset accept).
**Legibility-target:** for-orchestrator-synthesis

Executed, cwd `/workspace`, 2026-09-03T23:24:58Z. From the full stubbed run, **every** rule mentioning uid 999 (the suite's dnsmasq uid) is:

```
18:iptables -A OUTPUT -p udp -d 192.168.65.7 --dport 53 -m owner --uid-owner 999 -j ACCEPT
19:iptables -A OUTPUT -p tcp -d 192.168.65.7 --dport 53 -m owner --uid-owner 999 -j ACCEPT
25:iptables -t nat -A CC_DNS -m owner --uid-owner 999 -j RETURN
32:iptables -A CC_DNS_GUARD -m owner --uid-owner 999 -j RETURN
53:iptables -A OUTPUT -p udp -d 192.168.65.1 --dport 53 -m owner --uid-owner 999 -j ACCEPT
54:iptables -A OUTPUT -p tcp -d 192.168.65.1 --dport 53 -m owner --uid-owner 999 -j ACCEPT
```
Counts: ACCEPT rules for uid 999 without a `-d` address scope = **0**; without `--dport 53` = **0**. `192.168.65.7` is precisely what `bash devcontainer-config/init-firewall.sh --print-resolvers /etc/resolv.conf` returned on this host, and `192.168.65.1` is the gateway the run's `ip route` yielded — i.e. the two address classes the claim names, and nothing else.

The two `RETURN`s are exemptions from chains that would otherwise redirect or reject, not accepts: `CC_DNS` (nat) ends in `REDIRECT --to-ports 53` (log lines 27–28) and `CC_DNS_GUARD` (filter) ends in `REJECT --reject-with icmp-admin-prohibited` (line 34). A `RETURN` grants nothing; it returns the packet to the calling chain, where the four scoped accepts above are the only port-53 matches available to it.

The source-side generators are both `for`-loops over `("$DNSMASQ_UID" 0)` with the address interpolated:

```
541	    for owner in "$DNSMASQ_UID" 0; do
542	      iptables -A OUTPUT -p udp -d "$ns" --dport 53 -m owner --uid-owner "$owner" -j ACCEPT || echo "WARNING: could not add UDP DNS rule for $ns (uid $owner)" >&2
```
(`init-firewall.sh:541-544`; the enclosing `while read -r ns` runs to `:545` and the `if [ -n "$dns_resolvers" ]` through its `else`/`fi` at `:546-571` — the else branch adds **no rules at all**, only three `echo … >&2` warnings, so it cannot widen the scope.) The gateway pair is the same shape at `:788-791`, guarded to `--dport 53` on udp and tcp only.

Two bats tests pin this and pass: `LC_ALL=C bats -f 'upstream port 53 is owner-scoped|the bridge gateway is admitted on udp/tcp 53 only' test/init-firewall-rules.bats`, cwd `/workspace`, exit 0 — the first asserts `grep -cE -- "-A OUTPUT -p (udp|tcp) -d [0-9.]+ --dport 53 -j ACCEPT"` (i.e. an accept with no owner match) is `0`.

One nuance worth carrying forward, outside the claim's covers clause: `CC_DNS_GUARD` is also jumped to for `-d 127.0.0.11` on *all* ports (log line 36), so the uid-999 RETURN there is what lets dnsmasq reach Docker's embedded resolver on its DNAT'd non-53 port while every other uid is rejected. That reach is to loopback and is admitted by the shared `-o lo` accept (line 39), not by a dnsmasq-specific accept — so the claim's enumeration of *accepts* stays exact, but "the addresses dnsmasq can reach on port 53" and "the addresses the exemption distinguishes it on" are not the same set.

**Evidence:** `devcontainer-config/init-firewall.sh:531-571`, `:682-683`, `:694-696`, `:720-723`, `:788-791`, `docs/reviews/execution-logs/cfc-sc-3-dnsmasq-uid-scope-abbd42d.txt`

---

## Claim 4: "The proxy does not terminate TLS: it replays the captured ClientHello bytes upstream and copies ciphertext in both directions without holding a key or certificate."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-sni-proxy.py:157-165`, `:190-192`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no TLS library, key, or certificate is imported or referenced; that the bytes the upstream receives are byte-identical to what the client wrote in five fragmentation shapes (one record/one write, one record/two writes, two records/one write, two records/two writes with a 50 ms gap, and two records plus trailing application data); and that everything after the replay is an untyped byte copy. Does not establish behaviour for a ClientHello spanning more than 64 KiB (rejected at `:118-119`), nor for a client that interleaves a TCP reset mid-handshake.
**Legibility-target:** for-orchestrator-synthesis

No TLS material exists in the file. `python3 -c` over the AST returns `imports: ['argparse', 'asyncio', 'os', 'pwd', 're', 'signal', 'socket', 'struct', 'sys', 'time']` — no `ssl`. A case-insensitive grep for `ssl|tls_|certificate|\.pem|\.crt|private_key|SSLContext|wrap_socket` hits three lines only, all inert: the docstring's own claim (`:8`), the constant `TLS_HANDSHAKE = 22` (`:39`), and its use as a record-type comparison (`:109`).

The replay is one write of the accumulated record bytes, followed by a symmetric untyped copy:

```
190	        log(f"ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}")
191	        up_w.write(raw)
192	        await asyncio.gather(pump(client_r, up_w), pump(up_r, client_w), return_exceptions=True)
```
(`cc-sni-proxy.py:190-192`; the enclosing `handle()` continues through its `finally` at `:193-196`, which closes both writers — read.) `raw` is built by accumulating whole records verbatim — `raw += hdr + body` (`:112`) inside `read_client_hello`, whose loop runs to the `return raw, hs[:need]` at `:117` — so every byte the client sent up to and including the record that completed the handshake message is replayed, headers included. `pump()` is a bare read/write loop with no framing or transformation:

```
159	        while data := await reader.read(65536):
160	            writer.write(data)
161	            await writer.drain()
```
(`cc-sni-proxy.py:157-165`, read to the `except OSError: pass` at `:164-165`.)

**Executed, and this closes the critic's "Not verified" item.** `LC_ALL=C python3 /tmp/claude-1000/cfc/frag_test.py`, cwd `/workspace`, exit 0, 2026-09-03T23:23:27Z. The harness imports the shipped module by `importlib` (as `test/test_cc_sni_proxy.py` does), runs the real proxy as a subprocess against a fake upstream that **records rather than echoes**, and asserts on what the upstream received:

```
F1 one record, one write: client sent 70B, upstream received 70B, byte-identical=True
F2 one record, two writes: client sent 70B, upstream received 70B, byte-identical=True
F3 two records, one write: client sent 75B, upstream received 75B, byte-identical=True
F4 two records, two writes (50ms): client sent 75B, upstream received 75B, byte-identical=True
F5 two records + trailing app data: client sent 85B, upstream received 85B, byte-identical=True
RESULT: all cases byte-identical
```
F5 matters most: the trailing 10 bytes of pretend application data arrive intact even though they were never part of `raw` — they travel via `pump`, which is the ciphertext path. The proxy's own log for the run shows only `ALLOW sni=localhost -> 127.0.0.1:43499` lines, no handshake of its own. The shipped suite also still passes: `LC_ALL=C python3 test/test_cc_sni_proxy.py -v`, exit 0, 13/13.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:102-119`, `:157-165`, `:190-196`, `docs/reviews/execution-logs/cfc-sc-4-clienthello-byte-identity-abbd42d.txt`

---

## Claim 5: "The splice itself is not the bottleneck: a relay built from this exact `pump()` body moved 512 MiB in 0.74 s — 695 MiB/s, ~5.8 Gbit/s, ~90 µs per 64 KiB chunk — on a 16-core Python 3.11.2 host with writer, relay and sink sharing one loop."

**Submitted by:** performance-reviewer
**Location:** `devcontainer-config/cc-sni-proxy.py:146-153` (`pump`)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the magnitude class of the figure and the "not the bottleneck" conclusion, independently reproduced on the same host configuration. Does not establish per-connection cost (this measures one long-lived connection; `handle()`'s per-connection `getaddrinfo` at `:182-183` and `open_connection` are outside the measured path), nor behaviour under concurrency, nor throughput on the real redirect path with TLS-sized writes from a remote peer.
**Legibility-target:** for-orchestrator-synthesis

Two notes on the citation before the number. First, the line reference is off by ~11: `pump()` is at `cc-sni-proxy.py:157-165`, not `:146-153` (at `:146-153` sit `original_dst` and `log`). The body quoted below is what was measured. Second, the claim's own framing — "a relay built from this exact `pump()` body" — is accurate here in the stronger sense: the harness *imports* the shipped function (`pump = proxy.pump`) rather than copying it, so there is no possibility of drift between the measured code and the shipped code.

Reproduced. `LC_ALL=C python3 /tmp/claude-1000/cfc/pump_bench.py`, cwd `/workspace`, exit 0, 2026-09-03T23:23:53Z, three consecutive runs, 512 MiB in 64 KiB chunks, writer/relay/sink on one loop, sink byte-count asserted equal to bytes sent each time:

| run | elapsed | throughput | per 64 KiB |
|-----|---------|-----------|-----------|
| 1 | 0.661 s | 774.6 MiB/s (6.50 Gbit/s) | 80.7 µs |
| 2 | 0.764 s | 670.2 MiB/s (5.62 Gbit/s) | 93.3 µs |
| 3 | 0.698 s | 733.4 MiB/s (6.15 Gbit/s) | 85.2 µs |

Host as claimed: `python 3.11.2 | Linux-6.18.35.2-microsoft-standard-WSL2-x86_64-with-glibc2.36`, `cpu count: 16`. The submitted 0.74 s / 695 MiB/s / 5.8 Gbit/s / ~90 µs sits inside the spread of my three runs (run 2 nearly on top of it), so the figure is reproducible rather than a lucky sample. The measured code:

```
157	async def pump(reader, writer):
158	    try:
159	        while data := await reader.read(65536):
160	            writer.write(data)
161	            await writer.drain()
162	        if writer.can_write_eof():
163	            writer.write_eof()
164	    except OSError:
165	        pass
```
(`cc-sni-proxy.py:157-165` — complete function.)

On the conclusion: at ~5–6 Gbit/s the splice sits two to three orders of magnitude above any egress link this sandbox will see, so "not the bottleneck" is endorsed for the steady-state copy. The cost that could bottleneck is per-*connection*, not per-byte, and this benchmark does not touch it — see the does-not-establish clause.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:157-165`, `:182-186`, `docs/reviews/execution-logs/cfc-sc-5-pump-throughput-abbd42d.txt`

---

## Claim 6: "The four inspection hooks are uniform and side-effect-free: all four match `[ "${1:-}" = "--flag" ]`, exit before `trap fail_closed_on_abort EXIT` is installed at `:271`, and touch no state; `--print-resolvers` and `--print-dnsmasq-conf` both take the resolv.conf path as `${2:-/etc/resolv.conf}`."

**Submitted by:** api-consistency-reviewer
**Location:** `devcontainer-config/init-firewall.sh:68-71`, `:100-103`, `:136-145`, `:210-213`, `:271`
**Type:** Structural / API-consistency
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal uniformity of all four guards, their file-order precedence over the trap, the identical `${2:-/etc/resolv.conf}` argument on both resolv.conf-taking hooks, and the absence of observable side effects (no privileged binary invoked, no config file, pidfile, or run directory created) across all four hooks in both their argument forms. Does not establish that anything *enforces* the ordering — the critic's "Not verified" stands: it is file order, and a future edit that moves the trap above `:68` would break it silently.
**Legibility-target:** for-orchestrator-synthesis

All four guards, verbatim and identical in shape:

```
68:if [ "${1:-}" = "--print-domains" ]; then
100:if [ "${1:-}" = "--print-resolvers" ]; then
136:if [ "${1:-}" = "--print-entries" ]; then
210:if [ "${1:-}" = "--print-dnsmasq-conf" ]; then
```
and the trap they precede:
```
271:trap fail_closed_on_abort EXIT
272:trap 'exit 143' INT TERM HUP QUIT
```
(`init-firewall.sh:68`, `:100`, `:136`, `:210`, `:271-272`; each hook block was read to its `exit 0` and `fi` — `:70-71`, `:102-103`, `:144-145`, `:212-213`.) The shared resolv.conf argument:
```
101:  compose_dns_resolvers "${2:-/etc/resolv.conf}"
211:  compose_dnsmasq_conf "$(compose_dns_resolvers "${2:-/etc/resolv.conf}")" "$(compose_domains)"
```

**Executed.** `LC_ALL=C bash /tmp/claude-1000/cfc/h/hooks.sh`, cwd `/workspace`, exit 0, 2026-09-03T23:22:45Z. All four hooks were run under a PATH stub in which `iptables`, `iptables-save`, `ipset`, `ip`, `dig`, `curl`, `dnsmasq`, `pkill`, `runuser`, `cc-sni-proxy` and `aggregate` each append their argv to a log — six invocations in all (both resolv.conf hooks were run twice, once with an explicit path and once relying on the default). Every hook exited 0, and:

```
CMD_LOG bytes: 0  (0 == no stubbed binary was invoked)
dnsmasq conf exists: no
dnsmasq pidfile exists: no
SNI run dir exists: no
```

The suite's own two purity tests also pass: `LC_ALL=C bats -f 'inspection hooks' test/init-firewall-rules.bats`, cwd `/workspace`, exit 0 — "inspection hooks never touch iptables" and "inspection hooks (dnsmasq-conf included) never touch iptables or start a daemon".

Two small qualifications on "touch no state", neither of which contradicts the claim: `--print-entries` assigns a shell variable (`entries="$(compose_domains)"`, `:140`) — process-local, discarded at `exit 0`; and `--print-dnsmasq-conf` can write a `WARNING: not a hostname…` line to stderr (`:200`) for a malformed profile entry. Neither writes a file, starts a process, or issues a firewall command.

**Evidence:** `devcontainer-config/init-firewall.sh:68-71`, `:100-103`, `:136-145`, `:200`, `:210-213`, `:271-272`, `docs/reviews/execution-logs/cfc-sc-6-hook-purity-abbd42d.txt`

---

## Claim 7: "The proxy is genuinely substitutable: its entire contract with the firewall is a six-flag CLI plus 'exit 0 once listening'; nothing in the firewall imports Python, reads the proxy's log format, or depends on its internals."

**Submitted by:** architecture-review
**Location:** `devcontainer-config/cc-sni-proxy.py:236-239`, `devcontainer-config/init-firewall.sh:874-878`
**Type:** Structural / API-consistency
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three negative assertions, all of which hold exactly: the firewall invokes the binary with exactly six flags, references Python nowhere in executable code, never reads the proxy's log or pidfile, and depends on no internal of the implementation. Does not establish the claim's positive quantifier — "its **entire** contract is a six-flag CLI plus exit 0" — which omits four further obligations a replacement must meet (below).
**Legibility-target:** for-orchestrator-synthesis

Everything the critic asserts negatively is confirmed, executed, cwd `/workspace`, 2026-09-03T23:24:10Z. The invocation from a full stubbed run carries exactly six flags:

```
cc-sni-proxy --daemon --pidfile …/proxy.pid --user ccproxy --listen 127.0.0.1:3443 --allowlist …/allowlist --log …/proxy.log
flag count: 6
```
matching `--listen/--allowlist/--daemon/--pidfile/--user/--log` in the proxy's own parser (`cc-sni-proxy.py:291-296`; `--upstream-port` at `:297` is `argparse.SUPPRESS`, a test seam, and is never passed by the firewall). `grep -niE 'python|\.py|pip|import '` over `init-firewall.sh` hits **only comments** plus the default path string at `:437` — no executable line invokes an interpreter; the comment at `:434-436` says so deliberately ("executed directly … rather than via a `python3` on PATH, so a PATH hijack by `node` cannot substitute the interpreter"). And `SNI_LOG`/`SNI_PIDFILE` never appear on the left of a read: they occur only as CLI arguments (`:874-875`) and inside two error strings (`:876`, `:929`), so no log format or pidfile content is parsed.

The imprecision is the word "entire". Enumerating every reference (`cfc-sc-7` §A, 23 lines) surfaces four further obligations on any replacement, none of which is expressible as a CLI flag:

1. **The allowlist file grammar.** The firewall *writes* the file the proxy must parse, and its two-tier grammar is load-bearing — plain names are exact, a leading dot means the zone and all subdomains: `echo ".github.com"` / `.githubusercontent.com` / `.githubassets.com` (`init-firewall.sh:866-868`, inside the `{ … } > "$SNI_ALLOWLIST"` group at `:857-869`). A replacement that read `.github.com` as a literal name would silently break every GitHub fetch. The critic's own note flags this.
2. **The `ccproxy` identity.** The firewall resolves `CCPROXY_UID="$(id -u ccproxy …)"` independently at `:449` and builds owner-match rules from it (`:883`, `:893`), so the replacement must actually end up running as *that* uid — passing `--user ccproxy` and then not dropping privileges would leave the REDIRECT exemption pointing at the wrong process.
3. **The run-directory layout.** `SNI_ALLOWLIST`, `SNI_PIDFILE` and `SNI_LOG` are all derived from `SNI_RUN_DIR` at `:439-441`, and the firewall pre-creates and chmods that directory (`:853-854`) and chmods the allowlist to `0444` (`:870`) — so the replacement must tolerate a read-only allowlist it did not create.
4. **Direct executability.** `if [ ! -x "$SNI_PROXY_BIN" ]` (`:443`) plus direct invocation means the artefact must be an executable file with a working shebang at that path, not a script requiring an interpreter prefix.

Precise version: "its contract with the firewall is a six-flag CLI, an 'exit 0 once listening' status, the allowlist-file grammar the firewall writes, and running as the `ccproxy` uid — no Python, no log format, no internals."

**Evidence:** `devcontainer-config/init-firewall.sh:434-451`, `:853-879`, `:883`, `:893`, `:929`, `devcontainer-config/cc-sni-proxy.py:289-304`, `docs/reviews/execution-logs/cfc-sc-7-proxy-contract-grep-abbd42d.txt`

---

## Claim 8a: "The preconditions for both new daemons are checked in phase A so a broken image aborts with the live ruleset intact (`:389-407`, `:430-453`)."

**Submitted by:** architecture-review
**Location:** `devcontainer-config/init-firewall.sh:389-453`
**Type:** Behavioral / Structural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that all four preconditions (dnsmasq binary present, dnsmasq uid numeric and non-zero, proxy binary executable, ccproxy uid numeric, non-zero and distinct from dnsmasq's) sit above the flush in file order, and that each failure aborts with zero `iptables -F` issued. Does not establish that the *live* ruleset is functional at that moment on a fresh container — on a first run there is no prior ruleset to leave intact, which is why the fail-closed trap at `:271` exists.
**Legibility-target:** for-orchestrator-synthesis

The precondition blocks are at `:389-407` (dnsmasq: `command -v dnsmasq` at `:397`, `DNSMASQ_UID` regex-and-non-zero at `:403-407`) and `:430-453` (proxy: `[ ! -x "$SNI_PROXY_BIN" ]` at `:443`, `CCPROXY_UID` at `:449-453`), and the first flush is at `:477`:

```
472	iptables -P INPUT DROP
473	iptables -P FORWARD DROP
474	iptables -P OUTPUT DROP
...
477	iptables -F
```
(`init-firewall.sh:472-483`, read through the `ipset destroy` at `:483`.)

Executed, cwd `/workspace`, 2026-09-03T23:24:36Z: `LC_ALL=C bats -f 'aborts before the flush|a ccproxy uid equal to the dnsmasq uid is refused|a GitHub fetch failure aborts' test/init-firewall-rules.bats` → exit 0, 4/4 pass — "a missing dnsmasq user aborts before the flush, leaving the live ruleset intact", "a GitHub fetch failure aborts before the flush, leaving the live ruleset intact", "a missing ccproxy user aborts before the flush", "a ccproxy uid equal to the dnsmasq uid is refused". Each asserts `grep -c -- "^iptables -F" "$CMD_LOG"` is `0`.

**Evidence:** `devcontainer-config/init-firewall.sh:389-407`, `:430-453`, `:472-483`, `test/init-firewall-rules.bats:603-615`, `:636-644`, `:773-787`, `docs/reviews/execution-logs/cfc-sc-8-phase-ab-boundary-abbd42d.txt`

---

## Claim 8b: "Phase A / phase B is a real architectural boundary: every network read is hoisted above the flush (`:293-453`)."

**Submitted by:** architecture-review
**Location:** `devcontainer-config/init-firewall.sh:293-483`
**Type:** Structural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the boundary is real and that the property the design actually needs holds — every network read *the rebuild depends on* is above the flush, and the flush→terminal-REJECT interval contains zero network calls. Does not endorse "every network read", which is false as literally stated: three verification probes issue six network calls after the flush. Does not establish kernel behaviour of any rule in the interval.
**Legibility-target:** for-orchestrator-synthesis

The mechanism and the conclusion are right. Executed, cwd `/workspace`, 2026-09-03T23:24:36Z, `LC_ALL=C bats -f 'the flush-to-DROP window contains no network call|every domain is resolved before the flush|all three DROP policies are set before the flush' test/init-firewall-rules.bats` → exit 0, 3/3 pass.

The static enumeration the task asked for, over the full emitted sequence of a successful run (`cfc-sc-8` §C/§D), classifies all 64 commands from `iptables -F` (log line 11) to `iptables -A OUTPUT -j REJECT` (line 74):

- 60 × `iptables` / `ipset` / — netlink and xtables, no egress
- 1 × `ip route` (line 52) — kernel routing table read, local
- 1 × `pkill -x -U 999 dnsmasq` (line 22) — signal, local
- 1 × `dnsmasq --conf-file=… --pid-file=…` (line 23) — daemon start; binds `127.0.0.1:53` and issues no query (the generated config carries `no-resolv`, `no-poll`, `listen-address=127.0.0.1`, `bind-interfaces`, `init-firewall.sh:179-183`)
- 1 × `cc-sni-proxy --daemon …` (line 62) — daemon start; binds `127.0.0.1:3443`, no query

**NETWORK entries in the interval: 0.** Measured, not asserted: `awk 'NR>=11 && NR<=74' cmds.log | grep -cE '^(curl|dig|runuser) '` → `0`.

**Where the literal claim fails.** After the terminal REJECT the script issues six network calls — `curl https://example.com`, `curl https://api.github.com/zen`, and the two `runuser -u node -- curl …` probes (each logged twice, once by the `runuser` stub and once by the `curl` it execs):

```
75	curl --connect-timeout 5 --max-time 15 https://example.com
76	curl --connect-timeout 5 --max-time 15 https://api.github.com/zen
77	runuser -u node -- curl … https://api.anthropic.com/
79	runuser -u node -- curl … --resolve not-allowlisted.invalid:443:203.0.113.7 https://not-allowlisted.invalid/
```
(from `cfc-sc-8` §C; source at `init-firewall.sh:911-943`, read through the final `fi` at `:943` and the `FIREWALL_COMPLETE=1` sentinel at `:948`.) These are deliberate verifications *of* the finished ruleset, not reads the rebuild consumes, and they run after the boundary is fully installed — so they do not reopen the window the phase split exists to close. But they are network reads below the flush, and the claim says "every".

The script's own comment states the property correctly, and the claim would have been Verified had it used this wording: "Every network read the rebuild depends on (GitHub's published CIDRs, plus one A lookup per allowlisted domain) happens HERE, before a single rule is touched" (`init-firewall.sh:296-298`).

Precise version: "every network read the rebuild depends on is hoisted above the flush, and the flush-to-REJECT interval contains no network call at all; the only later network calls are the post-build verification probes."

On the critic's own "Not verified" — that no library called in phase B performs a lookup of its own — the enumeration above narrows it to two candidates, `dnsmasq` and `cc-sni-proxy`, both of which only bind a loopback socket at start; whether either resolves anything at startup on a live kernel is not observable here (the bats run uses stubs for both). This is a residual, not a refutation.

**Evidence:** `devcontainer-config/init-firewall.sh:293-312`, `:472-483`, `:656-678`, `:852-879`, `:908-948`, `test/init-firewall-rules.bats:363-409`, `docs/reviews/execution-logs/cfc-sc-8-phase-ab-boundary-abbd42d.txt`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate

- **Claim 7** (architecture-review) — "its **entire** contract … is a six-flag CLI plus exit 0 once listening". The three negative assertions hold exactly (no Python, no log-format read, no internals). The quantifier omits four obligations a replacement must meet: the allowlist file's two-tier grammar (`name` vs `.zone`), running as the `ccproxy` uid the firewall separately resolves for its owner-match rules, the run-directory path layout including a `0444` allowlist it must read but not create, and direct executability at `$SNI_PROXY_BIN`. Substitutability survives — all four are still implementation-agnostic — but a synthesiser quoting "entire contract is six flags" would understate the porting surface.
- **Claim 8b** (architecture-review) — "every network read is hoisted above the flush". True for every read the rebuild depends on, and the flush→REJECT interval measurably contains zero network calls; false as a universal, because the three post-build verification probes at `:911-943` issue six network calls after the flush. The script's own comment at `:296-298` states the correct scoping.

### Unverifiable

- **Claim 2b** (security-reviewer) — that the kernel refuses to match a UDP datagram against a `tcp:`-typed `hash:net,port` member. **Blocker:** no `CAP_NET_ADMIN` and no user namespace in this sandbox — `ipset create` and `unshare -Ur --net` both return `Operation not permitted` (executed and logged). The script-side half (claim 2a: every member carries `tcp:`, the accept matches `dst,dst`) is Verified by execution, and the ruleset enumeration shows the ipset accept is the *only* rule that could admit such a datagram for the agent uid — so the claim reduces exactly to the untestable step. Settle it in a privileged container per `guides/devcontainer-setup.md`.

## Goal-Alignment Note

- **Answered:** All eight submitted endorsements were verdicted against the code at `abbd42d`, and seven of the eight were **executed** rather than read: the proxy's readiness contract was exercised against the real binary in both directions (success → listening socket; bind failure → exit 1, no pidfile); the ClientHello byte-identity gap the security-reviewer flagged as "Not verified" was closed with a new five-case fragmentation harness (all byte-identical, including trailing application data); the performance figure was independently reproduced three times on the same host class and brackets the submitted number; hook purity was demonstrated with a logging PATH stub across all four hooks in both argument forms (zero invocations, zero files); and the dnsmasq-uid and phase-boundary claims were checked against the *complete* emitted command sequence of a successful run rather than against targeted greps. Two claims were split (2a/2b, 8a/8b) where the executable and non-executable halves, or the true and overstated halves, diverged in verdict.
- **Out of scope:** Kernel and netfilter semantics — ipset proto matching, `-m owner --uid-owner` enforcement, REDIRECT/DNAT interaction, whether the `-o lo` accept behaves as reasoned. Every claim in this report that touches them says so in its does-not-establish clause. Also out of scope: the 44 harvested claims in `docs/reviews/code-fact-check-report.md`, cited but not re-verdicted; and whether `dnsmasq` or the proxy performs a startup lookup of its own on a live kernel (claim 8b residual).
- **Escalate:** (1) **To the orchestrator, wording only** — claims 7 and 8b are both over-quantified in ways a synthesis would propagate; the precise versions are given inline and should replace the submitted phrasings in any rubric row. (2) **To the security critic** — the asymmetry surfaced under claim 1: `dnsmasq` gets a `kill -0` liveness re-check after start (`:674`), the SNI proxy gets none, so between `:878` and the `:928` probe a proxy that died after signalling ready leaves a REDIRECT pointing at a closed port. The `:928` probe catches this in practice before the run completes; whether that is sufficient is a judgement call, not a documentation defect. (3) **Before the re-bless** — claim 2b is the one boundary property in this batch with no local evidence; a single privileged-container check (UDP to an allowlisted address+port from the `node` uid must be rejected) would close it.
