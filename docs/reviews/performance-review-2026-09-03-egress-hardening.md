# Performance Review — egress hardening bd41aef..abbd42d

Commit: abbd42d

**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` — `init-firewall.sh` (664/948 lines changed; read whole), `cc-sni-proxy.py` (new, read whole), `Dockerfile`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`. `devcontainer-config/cc-isolated.sh` read as context for invocation frequency. Pass 1 of a split review (enforcement files); `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py` and `docs/working/questions.md` are in the range but were consulted as context only.
**Date:** 2026-09-03
**Based on:** docs/reviews/code-fact-check-report.md (k=3 merged)

---

## Data Flow and Hot Paths

Two new long-lived daemons are inserted into paths that previously had no userspace component.

**Cold — `init-firewall.sh`, once per container start** (`devcontainer.json:117` `postStartCommand`) plus once more on the launcher's re-assert path (`cc-isolated.sh:411-420`, only when the post-start boundary probe fails). Work per run:

| Step | Cost driver | Count | Lines |
|---|---|---|---|
| `compose_domains` / `parse_entry` | file reads, one `parse_entry` subshell per entry | 5–24 entries (measured, below) | `:42-63`, `:283-290` |
| `curl https://api.github.com/meta` | 1 network RTT, `--connect-timeout 5 --max-time 15` | 1 | `:320` |
| `dig` per entry, serial | 1 DNS RTT each, `+time=3 +tries=2` → ≤6 s each | 5–24 | `:358` |
| `compose_dnsmasq_conf` | (entries + 2 GitHub zones) × resolvers `server=` lines; one process substitution per entry | ~7–26 lines | `:174-208` |
| `ipset add` | one fork+netlink per member: 2 per GitHub CIDR + 1 per (A record × port) | ~90–140 | `:737-754` |
| dnsmasq start + pidfile poll | fork, bind, ≤3 s poll | 1 | `:667-678` |
| SNI proxy start | fork, bind, readiness pipe | 1 | `:874-878` |
| 4 verification probes | network, `--connect-timeout 5 --max-time 15` each | 4 | `:911-943` |

Measured allowlist size N (`--print-entries`, this checkout): `base` = 5; `base+llm` = 7; `base+python` = 7; `base+rust` = 8; `base+vscode` = 8; `base+android` = 11; union of every profile = 24. There is no N that grows with time, users, or sessions.

**Hot — `cc-sni-proxy.py`, every tcp/443 connection the agent makes, for the session's whole lifetime (hours).** `init-firewall.sh:886` REDIRECTs all non-`ccproxy`, non-root tcp/443 in nat OUTPUT to `127.0.0.1:3443`. Per connection, `handle()` (`cc-sni-proxy.py:168-196`) does: one `getsockopt(SO_ORIGINAL_DST)`; 1–4 `readexactly` calls to assemble the ClientHello; a pure-Python `parse_sni`; an `Allowlist.allows` scan (O(exact set hash) + O(zones), zones ≤ 3); **one `getaddrinfo` with no in-process cache**; one `open_connection`; one log line; then two `pump()` coroutines splicing 64 KiB chunks with a `drain()` per chunk until either side closes. All of this runs on **one asyncio event loop in one process** — every HTTPS byte and every HTTPS connection in the container is funnelled through it.

**Hot — dnsmasq, every DNS lookup.** `init-firewall.sh:686-687` REDIRECTs all non-dnsmasq, non-root port-53 traffic to `127.0.0.1:53`. Single-threaded for UDP. The generated config (`:174-208`) sets no `cache-size`, so dnsmasq's 150-entry default cache applies — comfortably larger than N, so after the first lookup per TTL each query is a loopback round trip answered from cache. Non-allowlisted names are answered locally with no upstream at all (fact-check Claim 23a, Verified), so a blocked lookup costs nothing beyond a loopback RTT.

**Per-packet.** filter OUTPUT is now longer, and — because the agent's 443 traffic is spliced — each payload byte traverses filter OUTPUT **twice** (agent→proxy on `lo`, proxy→upstream). Rule count before the `ESTABLISHED,RELATED` accept at `:803`: up to 8 owner-scoped DNS accepts (`:541-544`), 3 `CC_DNS_GUARD` jumps (`:720-722`), the `-o lo` accept (`:723`), 4 gateway-DNS accepts (`:788-791`).

**Correction to the brief's premise:** `/run` is **not** a tmpfs here. `devcontainer.json:46-49` passes only `--cap-add`, and `:57-60` mounts only two named volumes; nothing mounts `/run`, and the `node:22` base does not declare it. `/run/cc-sni-proxy/proxy.log` therefore lands on the container's writable overlay layer (host disk), not RAM. This lowers, but does not remove, Finding 5.

---

## Findings

#### The proxy connects to `getaddrinfo`'s first address only, with no fallback and no reconciliation against the phase-A ipset snapshot

**Severity:** High
**Location:** `devcontainer-config/cc-sni-proxy.py:181-189` (enclosing `handle()` is `:168-196`, read whole), against `devcontainer-config/init-firewall.sh:346-387` and `:748-754`
**Move:** #8 — question the cache (a resolve-once snapshot consulted by a resolve-every-time client)
**Classification:** Macro (a whole class of connections fails, for a TTL at a time, independent of tuning) / **Hot** path (evidence: `handle()` is the per-connection callback registered at `cc-sni-proxy.py:203`, reached by every agent tcp/443 connection via the REDIRECT at `init-firewall.sh:886`)
**Confidence:** Medium — the code path is certain; the *frequency* depends on how often a CDN's A-record set rotates out from under the snapshot, which is unmeasured
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
>             infos = await asyncio.get_running_loop().getaddrinfo(
>                 sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)
>             ip = infos[0][4][0]
>             up_r, up_w = await asyncio.wait_for(
>                 asyncio.open_connection(ip, upstream_port), CONNECT_TIMEOUT)
>         except (OSError, asyncio.TimeoutError) as e:
>             log(f"FAIL sni={sni} orig_dst={orig}: {e} (resolved address not in the ipset?)")
>             return
> ```
> (`cc-sni-proxy.py:182-189`; the excerpt ends mid-`handle()` — the remainder is the `ALLOW` log, `up_w.write(raw)`, the `asyncio.gather` of two `pump()`s, and the `finally` that closes both writers, `:190-196` — read.)
**Legibility-target:** for-author

The ipset is populated once, in phase A, from `dig` output taken before the rebuild (`init-firewall.sh:358`, `:384`, `:748-754`); the proxy resolves the same name *live* on every connection. When those two disagree — a CDN rotating its A-record set, or simply returning a different member of a multi-record set — the proxy connects to an address the ipset does not admit, the kernel's terminal `REJECT` (`init-firewall.sh:905`) refuses it immediately, and `handle()` logs `FAIL` and drops the client. The proxy's own error text already anticipates exactly this ("resolved address not in the ipset?"), and `llm.txt:8-11` documents the snapshot's staleness for the address layer — but the code makes it strictly worse than it needs to be: `infos[0]` is taken unconditionally, so a second or third A record that *is* in the ipset is never tried. Because dnsmasq caches the answer, every client retry re-derives the same failing address until the TTL expires, so the user-visible shape is a hard multi-minute stall on an allowlisted host rather than a transient blip. Failure mode: **snapshot-versus-live DNS divergence, amplified by first-address-only selection.**

**Recommendation:** Iterate `infos` and try each address until one connects (bounded by a total deadline rather than `CONNECT_TIMEOUT` per address), and log which index succeeded so the divergence rate becomes measurable. If the ipset membership can be read cheaply (`ipset test`), preferring an admitted address turns the retry loop into a first-try hit.

---

#### Nothing supervises the proxy: a death after startup is a silent, unrecovered, session-long HTTPS outage

**Severity:** High
**Location:** `devcontainer-config/cc-sni-proxy.py:235-286` (`daemonize`, read whole), `devcontainer-config/init-firewall.sh:874-886`
**Move:** #4 — trace the lifecycle (the process lifetime is session-long; the health check is startup-only)
**Classification:** Macro (total loss of HTTPS, not a slowdown) / **Hot** path (evidence: the REDIRECT at `init-firewall.sh:886` is unconditional and kernel-enforced, so with the proxy gone every agent tcp/443 connection gets `ECONNREFUSED` from an empty `127.0.0.1:3443`)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
> if ! "$SNI_PROXY_BIN" --daemon --pidfile "$SNI_PIDFILE" --user ccproxy \
>         --listen "127.0.0.1:$SNI_PORT" --allowlist "$SNI_ALLOWLIST" --log "$SNI_LOG"; then
>     echo "ERROR: SNI proxy failed to start (see $SNI_LOG)" >&2
>     exit 1
> fi
> ```
> (`init-firewall.sh:874-878`; the excerpt ends inside the SNI PROXY block — the remainder is the success echo, the `CC_SNI` nat chain and REDIRECT, and the `CC_SNI_GUARD` filter chain, `:879-897` — read.)
**Legibility-target:** for-author

The startup contract is exit-status-only and one-shot: `daemonize()` returns 0 the moment the child writes `ready` (`cc-sni-proxy.py:249-253`), and fact-check Claim 13 (Verified) records that "a child which dies immediately after signalling ready is not detected." Nothing thereafter watches it — I grepped `devcontainer-config/` for every reference to `cc-sni-proxy`, `SNI_PIDFILE`, and `ccproxy`: the only ones are inside `init-firewall.sh` and the Dockerfile's `COPY`/`chmod`; `devcontainer.json:117` runs the script once, and `cc-isolated.sh:411-420` re-asserts only at launcher start, never mid-session. So over a multi-hour session the container's entire HTTPS capability rests on one unsupervised Python process, and its death presents to the agent as "the network broke" with the recovery step (`sudo /usr/local/bin/init-firewall.sh`) undiscoverable from inside. This is the availability cost of moving a kernel-enforced control into userspace. Failure mode: **single unsupervised process on the critical path with no liveness check after t=0.**

**Recommendation:** Add a liveness re-check to the launcher's existing `probe_boundary` path (a `kill -0` on `$SNI_PIDFILE` plus one HTTPS probe as `node`), and either restart the daemon in place or emit the exact recovery command. Cheaper still inside the proxy: an `atexit`/signal path that removes the pidfile so a stale pidfile is unambiguous.

---

#### `getaddrinfo` per connection with no in-process cache, and repeated identical lookups do not parallelise

**Severity:** Medium
**Location:** `devcontainer-config/cc-sni-proxy.py:182-183` (enclosing `handle()` is `:168-196`, read whole)
**Move:** #3 — work in the wrong place (a per-*process* concern paid per *connection*) and #7 — contention
**Classification:** Micro per unit (one resolver round trip) but with a measured concurrency cliff / **Hot** path (evidence: one lookup per connection through the `handle()` callback; `npm install`, `git`, and `uv` all open bursts of connections to a single host)
**Confidence:** Medium — the per-lookup number below is from this review sandbox, not from the container, where dnsmasq's cache should cut it by an order of magnitude
**Baseline:** measured in this sandbox (Python 3.11.2, 16 CPUs, Debian bookworm — the same base as the image): `loop.getaddrinfo(name, 443, family=AF_INET)` for a repeated name = **10.1 ms** per call, and **200 concurrent such lookups took 2.03 s** — exactly the serial time, i.e. no parallel speedup. A `ThreadPoolExecutor(32)` doing the same 200 lookups also took 2.01 s. With 90 *distinct* names, 30 threads gave a 6.8× speedup, so this is not a global lock — repeated identical queries serialise somewhere in the glibc/resolver path. A relay reproducing `handle()`'s sequence (getsockopt → read hello → getaddrinfo → connect) measured **99 conn/s and 10.1 ms/conn at both concurrency 1 and 32**, i.e. entirely DNS-bound.
**Evidence:**
> ```
>             infos = await asyncio.get_running_loop().getaddrinfo(
>                 sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)
> ```
> (`cc-sni-proxy.py:182-183`; the excerpt ends mid-`handle()` — see Finding 1 for the remainder, `:184-196` — read.)
**Legibility-target:** for-author

`Allowlist.load` is correctly hoisted to `serve()` (`cc-sni-proxy.py:200`), so the allowlist is a per-process cost; the name lookup is not. In the container dnsmasq will answer from its 150-entry cache after the first query per TTL, so the absolute per-lookup cost should be well under 1 ms — but the measurement above says the *concurrency* behaviour does not improve with threads for a repeated name, which is precisely the shape a connection burst to `registry.npmjs.org` produces. A one-entry-per-name TTL-respecting cache in the proxy removes the syscall, the executor hop, and the serialisation together. Failure mode: **per-connection resolution serialising a connection burst.**

**Recommendation:** Cache resolved addresses in the proxy keyed on the SNI, with a short fixed TTL (30–60 s is well inside any CDN's rotation window and bounded by the process lifetime). Confirm the container-side number first — one `python3 -c` timing loop inside a live container against `127.0.0.1:53` decides whether this is worth the code.

---

#### No cap on concurrent connections and no idle timeout once the ClientHello is past

**Severity:** Medium
**Location:** `devcontainer-config/cc-sni-proxy.py:157-165` (`pump`, read whole), `:168-196` (`handle`, read whole), `:199-209` (`serve`, read whole)
**Move:** #2 — what's the size of N, and #4 — memory lifecycle
**Classification:** Macro (unbounded growth) / **Hot** path (evidence: every accepted connection allocates and holds these objects for its lifetime)
**Confidence:** High on the absence; Low on it being reached in practice
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
> async def pump(reader, writer):
>     try:
>         while data := await reader.read(65536):
>             writer.write(data)
>             await writer.drain()
>         if writer.can_write_eof():
>             writer.write_eof()
>     except OSError:
>         pass
> ```
> (`cc-sni-proxy.py:157-165` — complete function.)
**Legibility-target:** for-orchestrator-synthesis

`HELLO_TIMEOUT` (10 s) bounds only the pre-ClientHello phase (`:173`); once `handle()` reaches the `asyncio.gather` of two `pump()`s (`:192`) there is no deadline, no keepalive, and no idle reaper — a connection that is spliced and then goes quiet holds two sockets, two `StreamReader` buffers (64 KiB high-water each) and a `Task` until one peer closes, which for a half-open flow behind a NAT may be never. `serve()` calls `asyncio.start_server` (`:202-203`) with no `backlog` or concurrency limit, so accepts are unbounded too. I am rating this **Medium rather than the matrix's Macro×Hot → High** because the only client is the container's own agent, the fd limit under Docker is ~2^20, and reaching it requires a runaway or looping client — but the growth is genuinely unbounded and it compounds Finding 2: the process that leaks is the one nothing restarts. Failure mode: **unbounded per-session accumulation of half-open spliced connections.**

**Recommendation:** Wrap the `gather` in an overall deadline or, better, an idle watchdog that closes a connection with no bytes in either direction for N minutes; and cap concurrent handlers with an `asyncio.Semaphore` acquired before the ClientHello read, so overload sheds cheaply instead of accumulating.

---

#### The proxy log grows for the whole session, one line per connection, with no rotation

**Severity:** Low
**Location:** `devcontainer-config/cc-sni-proxy.py:153-154` (`log`, complete function), `:243`, `devcontainer-config/init-firewall.sh:441`, `:875`
**Move:** #4 — memory/storage lifecycle
**Classification:** Micro per event / **Hot** path (evidence: `log()` is called on every connection — 1 line on the ALLOW path, 1 on each REJECT/FAIL path, `cc-sni-proxy.py:176`, `:179`, `:188`, `:190`)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
> def log(msg):
>     print(time.strftime("%Y-%m-%dT%H:%M:%S"), msg, flush=True)
> ```
> (`cc-sni-proxy.py:153-154` — complete function.)
**Legibility-target:** for-orchestrator-synthesis

`daemonize` opens the log `O_TRUNC` once (`:243`) and dups it onto fds 1 and 2, so the file is reset only when `init-firewall.sh` runs — i.e. once per container start — and then grows monotonically for hours. Each line is ~80–120 bytes; a session doing repeated `npm`/`uv` installs plausibly opens tens of thousands of connections, so single-digit MB is the realistic figure, not a problem in itself. Two details keep it on the list: `flush=True` makes every line a blocking `write(2)` **from inside the event loop**, and the destination is the container's writable overlay layer (see the Data Flow correction — `/run` is not a tmpfs here), so it grows the container's disk footprint rather than being reclaimed on restart.

**Recommendation:** Leave the format alone; either size-cap the file (reopen `O_TRUNC` past a threshold) or downgrade the `ALLOW` line to a periodic counter and keep per-connection lines for `REJECT`/`FAIL` only, which is what a reader debugging the boundary actually wants.

---

#### Filter OUTPUT: the `ESTABLISHED,RELATED` accept sits behind ~10 rules that every packet of every flow evaluates first — and the proxy doubles the traversals

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:716-723`, `:788-791`, `:797-803`, `:896`, `:902-905`
**Move:** #9 — asymptotic behaviour, and #3 — work relocated
**Classification:** Micro (netfilter rule evaluation is nanoseconds) / **Hot** path (evidence: filter OUTPUT is traversed per packet, and with the splice each payload byte crosses it twice)
**Confidence:** High on the ordering; High that the cost is immaterial
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> ```
> iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
> ```
> (`init-firewall.sh:803`; the excerpt ends before the SNI PROXY block, `:805-897`, and the terminal ipset accept and `REJECT` at `:902-905` — read.)
**Legibility-target:** for-orchestrator-synthesis

Established flows evaluate up to 8 owner-scoped DNS accepts (`:541-544`), 3 guard jumps (`:720-722`), the `-o lo` accept (`:723`) and 4 gateway-DNS accepts (`:788-791`) before reaching the fast-path accept. Several of those carry `-m owner`, which does a socket lookup. Ordinarily one would hoist the `ESTABLISHED,RELATED` rule to the top of OUTPUT — but here that would be a *security* change, not just a perf one: the `CC_DNS_GUARD` and `CC_SNI_GUARD` jumps are deliberately ahead of `-o lo` and the guards are the defence-in-depth layer behind the REDIRECTs. Recording it so the ordering is a decision rather than an accident. I am **not** recommending the reorder.

**Recommendation:** No change. If the OUTPUT chain later grows materially (many resolvers, many guard chains), measure with `iptables -nvL OUTPUT` packet counters before reordering, and keep the guard jumps ahead of `-o lo` whatever else moves.

---

#### ~90–140 `ipset add` forks in the rebuild, where one `ipset restore` would do

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:737-754`
**Move:** #1 — count the hidden multiplications
**Classification:** Micro / **Cold** path (evidence: once per container start; `devcontainer.json:117`)
**Confidence:** High
**Baseline:** attributed — `docs/reviews/performance-review-2026-08-29-harden-cc-isolated-egress-pass2.md` ("Considered and explicitly dismissed"): ~30–40 GitHub CIDRs after `aggregate -q`, each `ipset add` a fork+netlink call in the single-digit milliseconds; batching would "shave perhaps 100–200 ms once per container start."
**Evidence:**
> ```
>     ipset add -exist allowed-domains "$cidr,tcp:443"
>     ipset add -exist allowed-domains "$cidr,tcp:22"
> done < <(echo "$GH_CIDRS")
> ```
> (`init-firewall.sh:744-746`; the excerpt ends before the second population loop over `RESOLVED_MEMBERS`, `:748-754` — read.)
**Legibility-target:** for-orchestrator-synthesis

The port-scoping change **doubled** the GitHub half of this loop (was one member per CIDR, now `tcp:443` and `tcp:22`), so the count moved from ~30–40 to ~60–80, plus one per (A record × port) from the second loop. The prior review's dismissal still holds — this is inside a window that is already closed by the DROP-before-flush change (`:472-483`), so it costs startup latency only, and the per-entry `|| `-guard structure is deliberate. Noting it purely because the multiplication grew.

**Recommendation:** No change. If startup latency ever becomes the complaint, `ipset restore` from a single here-doc is the batching move — but validation already happened in phase A (`:333-339`, `:372-376`), so nothing is lost by it either.

---

## Endorsements (evidence-gated)

- The prior review's only finding is closed: the meta fetch now carries `--connect-timeout 5 --max-time 15` and the per-domain `dig` carries `+time=3 +tries=2`, lowering the degraded-path ceiling per domain from `dig`'s ~15 s default to 6 s. `[read: devcontainer-config/init-firewall.sh:320, :358]`
- The splice itself is not the bottleneck and should not be optimised: a relay built from this exact `pump()` body moved 512 MiB in 0.74 s — 695 MiB/s, ~5.8 Gbit/s, ~90 µs per 64 KiB chunk — on a 16-core Python 3.11.2 host with writer, relay and sink sharing one loop. `[unverified — submitted as claim]`
- The extra resolver hop is a cache hit after the first lookup per TTL: the generated config sets no `cache-size`, so dnsmasq's 150-entry default applies, which exceeds the largest composed allowlist (24 entries, measured via `--print-entries` over every profile). `[read: devcontainer-config/init-firewall.sh:174-208]`
- Blocked destinations fail fast rather than by timeout: the terminal rule is `REJECT --reject-with icmp-admin-prohibited` and non-allowlisted names get a local refusal with no upstream, so Claude Code's continuing telemetry attempts to the Datadog intake host cost a loopback DNS refusal per event, not a connect timeout. `[fact-check: claim 16 — Incorrect]`
- Phase A keeps every network read out of the rebuild window, so the new dnsmasq and proxy startup work does not lengthen any period of open egress — the DROP policies are set before the flush and nothing between them and the finished ruleset touches the network. `[read: devcontainer-config/init-firewall.sh:293-312, :462-474]`

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Proxy connects to `infos[0]` only; no fallback, no reconciliation with the phase-A ipset snapshot | High | `cc-sni-proxy.py:181-189` | Medium |
| 2 | No supervisor: a proxy death after startup is a silent, session-long HTTPS outage | High | `cc-sni-proxy.py:235-286`, `init-firewall.sh:874-886` | High |
| 3 | `getaddrinfo` per connection, no in-process cache; repeated identical lookups do not parallelise | Medium | `cc-sni-proxy.py:182-183` | Medium |
| 4 | No concurrency cap and no idle timeout after the ClientHello | Medium | `cc-sni-proxy.py:157-165`, `:168-196`, `:199-209` | High (absence) / Low (reached) |
| 5 | Proxy log grows for the whole session, one line per connection, no rotation | Low | `cc-sni-proxy.py:153-154`, `:243` | High |
| 6 | `ESTABLISHED,RELATED` accept sits behind ~10 rules; splice doubles OUTPUT traversals | Informational | `init-firewall.sh:803` | High |
| 7 | ~90–140 `ipset add` forks per rebuild (GitHub half doubled by port-scoping) | Informational | `init-firewall.sh:737-754` | High |

---

## Overall Assessment

The cold path is in good shape and got cheaper on its worst branch — the prior review's timeout finding is genuinely closed, phase A still keeps the network out of the rebuild window, and the per-run work grows only with a repo-checked allowlist of 5–24 entries. The interesting risk all moved into the two new daemons, and specifically into the SNI proxy, which is now a single unsupervised Python process on the critical path of every HTTPS connection for hours at a time. The reassuring half is that the splice itself is cheap: measured at ~695 MiB/s and ~90 µs per 64 KiB chunk, it is two orders of magnitude above any WAN this container will see, so neither throughput nor event-loop contention deserves attention. The concerning half is everything around the splice — a first-address-only connect against a snapshot ipset (Finding 1), no liveness check after t=0 (Finding 2), and no bound on connection lifetime or count (Finding 4). Two measurements would settle most of this and both are cheap: (a) inside a live container, time `getaddrinfo` for an allowlisted name against the local dnsmasq, serially and at concurrency 32, to decide whether Finding 3 needs code; and (b) run the existing `$SNI_LOG` through a `FAIL`-line count over a real working session, which directly measures Finding 1's frequency — the log already records exactly the event, so no instrumentation is needed. Findings 1 and 2 are the ones I would fix before re-blessing; 3 and 4 are cheap enough to fold into the same change.

## Goal-Alignment Note
- Answered: yes — performance review of `devcontainer-config/` over `bd41aef..abbd42d`, structured per the skill, report at `docs/reviews/performance-review-2026-09-03-egress-hardening.md`
- Out of scope: `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py`, `docs/working/questions.md`, `guides/cc-isolated-usage.md`, `docs/decisions/log.md` — all in the range but assigned to a later pass; read only as context. Correctness and security questions raised by the fact-check (Claim 36's inert `.githubassets.com`, Claim 37's false-passing negative probe, Claim 16's telemetry wording) are not re-litigated here.
- Escalate: (1) Finding 1 is as much a reliability/security question as a performance one — the security critic should decide whether "connect to a live-resolved address the snapshot ipset does not admit" is an intended fail-closed behaviour or an accident, since the fix (try more addresses) widens what the proxy will attempt. (2) Finding 2 belongs in the bless checklist alongside fact-check Claim 10 (the proxy is not in the bless manifest): an unsupervised daemon on the critical path needs an owner. (3) The brief's premise that `/run` is a tmpfs is not true of this configuration — worth correcting wherever else it is assumed.
