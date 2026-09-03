# Code Fact-Check Report

Commit: abbd42d
**Repository:** /workspace (local-only, solo)
**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` — `init-firewall.sh`, `cc-sni-proxy.py`, `Dockerfile`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`; plus claims in the range's commit messages, `docs/decisions/log.md` rows 39–41, and `guides/cc-isolated-usage.md`
**Checked:** 2026-09-03
**Total claims checked:** 31
**Summary:** 20 verified, 6 mostly accurate, 2 stale, 1 incorrect, 2 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read before checking. Its two logged patterns are both "a measured corpus statistic quoted from a checked-in artifact set that does not contain it". Claims 26–29 below (test counts asserted in commit messages and decision rows) are the same shape, so each was counted mechanically rather than accepted; all four hold.

---

## Claim 1: "dnsmasq-base (above) is the daemon binary WITHOUT the `dnsmasq` package's sysv/systemd service wrapper: nothing in the container may auto-start a resolver"

**Location:** `devcontainer-config/Dockerfile:44-46`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the Debian packaging split (`dnsmasq-base` = `/usr/sbin/dnsmasq` binary; `dnsmasq` = the init/service wrapper) and the fact that only `dnsmasq-base` is installed. Does not establish that no *other* installed package auto-starts a resolver, and does not establish that `dnsmasq-base`'s postinst creates the `dnsmasq` user (the Dockerfile does not rely on it — see Claim 2).
**Legibility-target:** for-orchestrator-synthesis

The apt block installs `dnsmasq-base` and not `dnsmasq` (`devcontainer-config/Dockerfile:34`, within the `RUN apt-get install` list at `:20-43`). On Debian bookworm `dnsmasq-base` ships the daemon binary only; the `dnsmasq` package is the one that ships `/etc/init.d/dnsmasq` and the systemd unit. The container is confirmed to have no `dnsmasq` binary installed *in this review sandbox* (`docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`), which is a different image than the one the Dockerfile builds, so the packaging split itself could not be executed here — hence Medium confidence, from Debian packaging documentation rather than a run.

**Evidence:** `devcontainer-config/Dockerfile:34`, `devcontainer-config/Dockerfile:44-46`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`

---

## Claim 2: "The daemon drops to the unprivileged `dnsmasq` user, and the firewall's owner-match rules key on that uid, so its existence is asserted here rather than left to the package's postinst."

**Location:** `devcontainer-config/Dockerfile:48-50`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence assertion in the image and the fact that `init-firewall.sh` reads the uid and uses it in `-m owner --uid-owner` rules. Does not establish that the uid is stable across rebuilds (`useradd --system` picks the next free id).
**Legibility-target:** for-orchestrator-synthesis

The Dockerfile creates the user idempotently (`RUN id -u dnsmasq >/dev/null 2>&1 || useradd --system ...`, `devcontainer-config/Dockerfile:51-52`). `init-firewall.sh` resolves it to a number in phase A and refuses 0 or a non-numeric result — `DNSMASQ_UID="$(id -u dnsmasq 2>/dev/null || true)"` (`devcontainer-config/init-firewall.sh:403`) followed by the guard at `:404-407`. The uid is then used in owner matches at `:541-544`, `:682-683`, `:694-695`, and `:788-790`. The generated config carries `user=dnsmasq` (`:185`), confirmed by executing `--print-dnsmasq-conf` (`docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`).

**Evidence:** `devcontainer-config/Dockerfile:51-52`, `devcontainer-config/init-firewall.sh:403-407`, `devcontainer-config/init-firewall.sh:682-683`, `devcontainer-config/init-firewall.sh:185`

---

## Claim 3: "init-firewall.sh REDIRECTs every outbound tcp/443 connection that is NOT made by this proxy's own uid to 127.0.0.1:<port>"

**Location:** `devcontainer-config/cc-sni-proxy.py:4-5`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the nat REDIRECT of tcp/443 and the `ccproxy` exemption. Does not establish anything about udp/443 (QUIC) or IPv6, and omits the second exemption.
**Legibility-target:** for-author

Root is also exempt, which this docstring does not say (the file's own module docstring is the first thing a reader meets). The chain RETURNs for two uids, not one:

```
iptables -t nat -A CC_SNI -m owner --uid-owner "$CCPROXY_UID" -j RETURN
iptables -t nat -A CC_SNI -m owner --uid-owner 0 -j RETURN
```
(`devcontainer-config/init-firewall.sh:883-884`; excerpt ends `:884`, enclosing SNI PROXY block continues to `:897` — read.)

The precise version: "…that is NOT made by this proxy's own uid or by root". `init-firewall.sh:830-835` states the root exemption explicitly, so the two files disagree only in this docstring. The rest is accurate: the jump is `-A OUTPUT -p tcp --dport 443 -j CC_SNI` (`:886`) and nothing earlier in nat OUTPUT matches tcp/443 — the only prior insertions are the two port-53 rules at `:686-687` and the restored Docker 127.0.0.11:53 DNAT rules at `:490`.

**Evidence:** `devcontainer-config/init-firewall.sh:883-886`, `devcontainer-config/init-firewall.sh:830-835`, `devcontainer-config/init-firewall.sh:686-687`

---

## Claim 4: "Step 3 is why a forged SNI cannot steer a connection: the original destination (SO_ORIGINAL_DST) is read for the log line only and is never connected to."

**Location:** `devcontainer-config/cc-sni-proxy.py:14-16`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the upstream address comes from resolving the SNI and that `original_dst()`'s return value reaches only `log()`. Does not establish that the resolved address is itself trustworthy (it is whatever the container resolver returns), nor that the ipset second check actually fires (kernel-level, not exercised here).
**Legibility-target:** for-orchestrator-synthesis

`handle()` was read end to end (`devcontainer-config/cc-sni-proxy.py:168-196`). `orig` is bound once at `:169` and thereafter appears only inside f-strings passed to `log()` at `:176`, `:179`, `:188`, `:190`. The upstream address is derived solely from the SNI:

```
infos = await asyncio.get_running_loop().getaddrinfo(
    sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)
ip = infos[0][4][0]
up_r, up_w = await asyncio.wait_for(
    asyncio.open_connection(ip, upstream_port), CONNECT_TIMEOUT)
```
(`devcontainer-config/cc-sni-proxy.py:182-186`; excerpt ends `:186`, enclosing `handle()` continues to `:196` — read: the remainder logs, replays `raw` upstream, splices via `pump()`, and closes both writers in `finally`.)

`original_dst()` itself (`:145-150`) only unpacks and formats; it has no side effect on connection setup. `upstream_port` defaults to 443 (`:297`) and is a documented test seam, so the port is not taken from the original destination either. Grepping the file confirms `orig` has no other consumer.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:169`, `devcontainer-config/cc-sni-proxy.py:176-190`, `devcontainer-config/cc-sni-proxy.py:145-150`

---

## Claim 5: "Resolution uses the container's resolver (/etc/resolv.conf — Docker's embedded DNS today, a filtering dnsmasq once that lands)"

**Location:** `devcontainer-config/cc-sni-proxy.py:20-21`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "once that lands" future tense only. The substantive claim (resolution goes through the container resolver) is correct and is checked in Claim 6.
**Legibility-target:** for-author

The filtering dnsmasq landed in the same commit range — `d598bda`, merged as `1dbdabd`, two commits before the proxy commit `aa8dffc` that introduced this file. At HEAD the resolver is unconditional: `init-firewall.sh:656-678` writes the config and starts the daemon on every run, and `:686-687` redirects port 53 for every uid except dnsmasq and root — which includes `ccproxy`. What the docstring should say now: "the filtering dnsmasq that `init-firewall.sh` starts (Docker's embedded DNS is only its upstream)".

**Evidence:** `devcontainer-config/init-firewall.sh:656-678`, `devcontainer-config/init-firewall.sh:686-687`, `git log bd41aef..HEAD --no-merges`

---

## Claim 6: "…and is IPv4-only, matching the IPv4-only ipset. Non-443 ports are not redirected here and stay IP+port-matched."

**Location:** `devcontainer-config/cc-sni-proxy.py:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the AF_INET restriction in the proxy and the tcp/443-only redirect. Does not establish that IPv6 egress is *blocked* — it is unfiltered end to end, which `init-firewall.sh:510-512` states separately.
**Legibility-target:** for-orchestrator-synthesis

`getaddrinfo(..., family=socket.AF_INET, ...)` (`devcontainer-config/cc-sni-proxy.py:183`). The ipset is created as `hash:net,port` and populated only with dotted-quad IPv4 members validated by `^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$` (`init-firewall.sh:731`, `:373`, `:384`). Only tcp/443 is jumped into `CC_SNI` (`init-firewall.sh:886`); GitHub's tcp 22 members (`:744-745`) and `host.docker.internal:11434` reach the ipset accept at `:902` directly.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:183`, `devcontainer-config/init-firewall.sh:731`, `devcontainer-config/init-firewall.sh:744-745`, `devcontainer-config/init-firewall.sh:886`

---

## Claim 7: "Single file, stdlib only (python3.11 ships in the node:22 base — no apt package, no pip)"

**Location:** `devcontainer-config/cc-sni-proxy.py:24-25`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "python3.11 is present without an apt or pip install" and "the file imports only stdlib modules". Does not establish that no *future* import would need a package.
**Legibility-target:** for-orchestrator-synthesis

`FROM node:22` (`devcontainer-config/Dockerfile:11`) and the apt block (`:20-43`) installs no `python3`. Executed in this image (built from the same Dockerfile): `python3 -V` → `Python 3.11.2` — see `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`. The Dockerfile independently asserts the same fact at `:88-89` ("The node:22 (bookworm) base ships python3.11 but no pip"). Every import in the file (`argparse, asyncio, os, pwd, re, signal, socket, struct, sys, time`, `devcontainer-config/cc-sni-proxy.py:27-36`) is stdlib, and the 13-test suite runs clean under bare `python3` (`docs/reviews/execution-logs/cfc-r2-pytests-abbd42d.txt`).

**Evidence:** `devcontainer-config/Dockerfile:11`, `devcontainer-config/Dockerfile:88-89`, `devcontainer-config/cc-sni-proxy.py:27-36`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`

---

## Claim 8: "SO_ORIGINAL_DST = 80          # linux/netfilter_ipv4.h; not exposed by the socket module"

**Location:** `devcontainer-config/cc-sni-proxy.py:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the constant's value and its absence from `socket`. Does not establish that the `getsockopt` call succeeds under the container's kernel (untested — `original_dst()` returns `"unknown"` on failure).
**Legibility-target:** for-orchestrator-synthesis

`SO_ORIGINAL_DST` is 80 in `linux/netfilter_ipv4.h`, and CPython's `socket` module exposes no such name. The unpack format `"!2xH4s8x"` over a 16-byte buffer matches `struct sockaddr_in` (2-byte family skipped, 2-byte port, 4-byte addr, 8-byte pad) — `devcontainer-config/cc-sni-proxy.py:147`. Failure is caught and degraded to the string `"unknown"` (`:149-150`), so a wrong constant would surface as a degraded log line rather than a broken connection.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:38`, `devcontainer-config/cc-sni-proxy.py:145-150`

---

## Claim 9: "`name` lines match exactly; `.zone` lines match the zone and every subdomain of it. Blank lines and #-comments are ignored."

**Location:** `devcontainer-config/cc-sni-proxy.py:123-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exact-match, zone+subdomain match, comment/blank stripping, and case-insensitivity on both sides. Does not establish behaviour for a line that is a bare `.` (it becomes the empty string after `lstrip(".")`, and `allows()` would then accept any name ending in `.`; no such line is ever generated by `init-firewall.sh`).
**Legibility-target:** for-orchestrator-synthesis

`Allowlist.load()` strips `#`-comments and whitespace, lower-cases, skips empties, and routes leading-dot lines into `zones` with the dots stripped:

```
line = line.split("#", 1)[0].strip().lower()
if not line:
    continue
(al.zones if line.startswith(".") else al.exact).add(line.lstrip("."))
```
(`devcontainer-config/cc-sni-proxy.py:134-137`; excerpt ends `:137`, enclosing `load()` continues to `:138` — `return al`.)

`allows()` is `name in self.exact or any(name == z or name.endswith("." + z) for z in self.zones)` (`:141-142`), i.e. a `.zone` entry admits the apex *and* subdomains, as claimed. The incoming SNI is lower-cased and trailing-dot-stripped in `normalise_name()` (`:58`), so both sides are normalised. Executed: the 13-test Python suite (which includes allowlist cases) passes — `docs/reviews/execution-logs/cfc-r2-pytests-abbd42d.txt`.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:134-142`, `devcontainer-config/cc-sni-proxy.py:58`, `docs/reviews/execution-logs/cfc-r2-pytests-abbd42d.txt`

---

## Claim 10: "Exit status is the contract init-firewall.sh relies on: 0 only once the child is LISTENING; anything else means \"no proxy\"…"

**Location:** `devcontainer-config/cc-sni-proxy.py:237-239`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers "the parent returns 0 only after the child has bound and started serving". Does not establish that the child stays alive afterwards (a crash after `ready` is not signalled to the parent), and does not cover the `--daemon`-less path, which never returns until the server stops.
**Legibility-target:** for-orchestrator-synthesis

The readiness token is written from inside `serve()` *after* `asyncio.start_server` has returned, i.e. after the listening socket exists:

```
server = await asyncio.start_server(
    lambda r, w: handle(r, w, allow, args.upstream_port), host, int(port), reuse_address=True)
log(f"listening on {args.listen}; ...")
if ready_fd is not None:
    os.write(ready_fd, b"ready")
```
(`devcontainer-config/cc-sni-proxy.py:202-206`; excerpt ends `:206`, enclosing `serve()` continues to `:209` — `os.close(ready_fd)` then `server.serve_forever()`.)

The parent returns 0 only on that exact token, and 1 on anything else including a short read from a dead child (`:249-256`). Any exception in the child — including `pwd.getpwnam` / `setuid` failure — is written back as `error: …` and the child exits 1 (`:280-285`). Consumer side: `init-firewall.sh:874-878` treats a non-zero status as fatal under `set -e`, reaching the fail-closed trap.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:202-209`, `devcontainer-config/cc-sni-proxy.py:249-256`, `devcontainer-config/cc-sni-proxy.py:280-285`, `devcontainer-config/init-firewall.sh:874-878`

---

## Claim 11: "Close every other inherited fd: the caller's stdout is the devcontainer postStartCommand pipe, and a daemon holding it open would hang the launch."

**Location:** `devcontainer-config/cc-sni-proxy.py:264-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every inherited fd above 2 other than the readiness pipe is closed, and that fds 0/1/2 are redirected rather than left pointing at the caller's pipes. Does not establish the claim's *motivation* (that the postStartCommand pipe would hang the launch) — that is a runtime property of the devcontainer CLI, not checkable here.
**Legibility-target:** for-orchestrator-synthesis

The child redirects 0 from `/dev/null` and 1/2 onto the log fd before the sweep (`devcontainer-config/cc-sni-proxy.py:260-262`), so the inherited stdout/stderr descriptions are dropped, then:

```
for fd in os.listdir("/proc/self/fd"):
    fd = int(fd)
    if fd > 2 and fd != w:
        try:
            os.close(fd)
        except OSError:
            pass
```
(`:266-272`; excerpt ends `:272`, enclosing `daemonize()` continues to `:286` — read: the privilege drop, `asyncio.run(serve(...))`, the error report back through `w`, and `os._exit`.)

`os.listdir` materialises the list before returning, so closing the just-used directory fd mid-loop is harmless; `log_fd` (>2) is closed here but survives as the dup targets 1 and 2. `w` is deliberately skipped and is closed inside `serve()` at `:207`.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:260-272`, `devcontainer-config/cc-sni-proxy.py:207`

---

## Claim 12: "This flag disables crash reporting ONLY. Do NOT reach for DISABLE_TELEMETRY, DO_NOT_TRACK, or CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: each of those also disables feature-flag evaluation, which Remote Control depends on."

**Location:** `devcontainer-config/devcontainer.json:73-79`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (WebFetch of the cited docs)
**Scope:** Covers the three named variables breaking Remote Control via feature-flag evaluation, and `DISABLE_ERROR_REPORTING` not being among them. Does not establish that `DISABLE_ERROR_REPORTING` is *sufficient* to stop every non-`api.anthropic.com` egress, and the list is not exhaustive — the docs name a fourth variable, `DISABLE_GROWTHBOOK`, with the same effect.
**Legibility-target:** for-orchestrator-synthesis

`https://code.claude.com/docs/en/remote-control.md` states verbatim: "**Feature-flag evaluation**: [`DISABLE_TELEMETRY`, `DO_NOT_TRACK`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, and `DISABLE_GROWTHBOOK`] each disable the feature-flag evaluation that Remote Control availability depends on." The same page has a dedicated failure mode, "Remote Control requires feature-flag evaluation", naming those four and not `DISABLE_ERROR_REPORTING`. `https://code.claude.com/docs/en/network-config.md` scopes `DISABLE_ERROR_REPORTING` to the `browser-intake-us5-datadoghq.com` host — "Operational error reports … Optional: disable with `DISABLE_ERROR_REPORTING` or `DISABLE_TELEMETRY`" — which matches "crash reporting ONLY". Adding `DISABLE_GROWTHBOOK` to the do-not-set list would make the comment complete.

**Evidence:** `devcontainer-config/devcontainer.json:73-80`, WebFetch `https://code.claude.com/docs/en/remote-control.md` (2026-09-03), WebFetch `https://code.claude.com/docs/en/network-config.md` (2026-09-03)

---

## Claim 13: "sentry.io and statsig.com were removed 2026-09 …: neither appears in the documented requirements any more"

**Location:** `devcontainer-config/egress/base.txt:5-7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (WebFetch of the cited docs)
**Scope:** Covers the absence of `sentry.io` and `statsig.com` from the network-config requirements table. Does not establish that Claude Code makes no attempt to reach them at runtime — the commit message for `b04090c` flags that as unverified, and it remains so.
**Legibility-target:** for-orchestrator-synthesis

The "Network access requirements" table at `https://code.claude.com/docs/en/network-config.md` (fetched 2026-09-03) lists `api.anthropic.com`, `claude.ai`, `claude.com`, `platform.claude.com`, `mcp-proxy.anthropic.com`, `downloads.claude.ai`, `storage.googleapis.com`, `registry.npmjs.org`, `bridge.claudeusercontent.com`, `*.frame.claudeusercontent.com`, `raw.githubusercontent.com`, `http-intake.logs.us5.datadoghq.com`, `browser-intake-us5-datadoghq.com`, `formulae.brew.sh`, and `code.claude.com`. Neither `sentry.io` nor `statsig.com` appears. Both are gone from the file (`devcontainer-config/egress/base.txt:25-28`), confirmed by executing `--print-entries`, which emits exactly five base entries (`docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`).

Note for the author, not a defect in the claim: error/telemetry intake has moved to two Datadog hosts that base.txt does not carry either, which is consistent with `DISABLE_ERROR_REPORTING` being set — but `console.anthropic.com` is *also* no longer in the documented table (the docs now name `platform.claude.com` for Console authentication), so base.txt carries one host the source-of-truth page no longer lists.

**Evidence:** `devcontainer-config/egress/base.txt:5-10`, `devcontainer-config/egress/base.txt:25-28`, WebFetch `https://code.claude.com/docs/en/network-config.md` (2026-09-03), `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`

---

## Claim 14: "OAuth token exchange/refresh (platform.claude.com — per the network-config docs; a missing entry surfaces as a mid-session re-login once the access token expires)"

**Location:** `devcontainer-config/egress/base.txt:22-24`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed (WebFetch of the cited docs)
**Scope:** Covers the documented purpose of `platform.claude.com`. Does not establish the stated *symptom* of omitting it — the docs describe a first-run connectivity-check failure, not specifically a mid-session re-login.
**Legibility-target:** for-author

The docs say verbatim: "`platform.claude.com` | Anthropic Console account authentication. OAuth token exchange, refresh, and revocation also go to this host for claude.ai accounts, so both Console and claude.ai sign-ins require it". The mechanism half of the claim is exactly right. The consequence half is the comment's own inference; the docs' stated failure mode is "The first-run setup connectivity check points here when it can't reach `api.anthropic.com` or `platform.claude.com`". Precise version: drop the parenthetical or mark it as inference.

**Evidence:** `devcontainer-config/egress/base.txt:21-28`, WebFetch `https://code.claude.com/docs/en/network-config.md` (2026-09-03)

---

## Claim 15: "SCOPE: the `:11434` suffix is load-bearing. … this admits exactly the model server and nothing else listening on the host's Docker-facing interface … do not drop the suffix, which would silently fall back to 443."

**Location:** `devcontainer-config/egress/llm.txt:19-24`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parse (suffix → tcp 11434 only; no suffix → tcp 443) and the `dst,dst` ipset match. Does not establish that the *host* is unreachable on other ports by some other path (e.g. an entry in another profile, or the bridge-gateway:53 accept).
**Legibility-target:** for-orchestrator-synthesis

Executed `--print-entries` with the `llm` profile yields `host.docker.internal	11434` and every other entry at `443` — `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`. The default is applied in `parse_entry` (`devcontainer-config/init-firewall.sh:119-124`), members are emitted as `<ip>,tcp:<port>` (`:384`), the set is `hash:net,port` (`:731`), and the accept matches `dst,dst` (`:902`).

**Evidence:** `devcontainer-config/init-firewall.sh:119-124`, `devcontainer-config/init-firewall.sh:384`, `devcontainer-config/init-firewall.sh:731`, `devcontainer-config/init-firewall.sh:902`, `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`

---

## Claim 16: "both halves are constrained to their literal grammar (hostname labels; 1-65535 integers)… `10#`: a leading zero would otherwise make bash read the number as octal… Tab-separated, because IFS is \\n\\t in this script: a space would not split under `read -r domain ports` at the consumer."

**Location:** `devcontainer-config/init-firewall.sh:108-111`, `:128`, `:131-132`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the domain/port validation, the octal note, and the tab-vs-space split under the script's `IFS`. Does not establish canonical-form normalisation: `port:0443` passes validation (10#0443 = 443) and is then interpolated *verbatim* as `tcp:0443` into `ipset add` at `:384` — the raw string, not the `10#` value, is what reaches the command line.
**Legibility-target:** for-orchestrator-synthesis

`parse_entry` (`devcontainer-config/init-firewall.sh:116-134`, read in full) anchors the domain against a label grammar (`:118`, `:125`), anchors the port list against `^[0-9]{1,5}(,[0-9]{1,5})*$` (`:126`), and range-checks each port via `10#` (`:127-130`). Executed negatives, all exit 1 with the intended message: `bad name:99999`, `ok.example:70000` — `docs/reviews/execution-logs/cfc-r2-hook-negatives-abbd42d.txt`.

The `IFS` claim is correct and load-bearing. `IFS=$'\n\t'` (`:30`) means the consumers `while read -r domain ports` (`:348`, `:860`) split on tab only; a space-separated `printf` would put `443` into `$domain`. Every comma split in the file is done through `tr ',' '\n'` under the same `IFS` — `:54`, `:127`, `:191`, `:383` — which is the only form that works with newline in `IFS`.

**Evidence:** `devcontainer-config/init-firewall.sh:29-30`, `devcontainer-config/init-firewall.sh:116-134`, `devcontainer-config/init-firewall.sh:348`, `devcontainer-config/init-firewall.sh:383-384`, `docs/reviews/execution-logs/cfc-r2-hook-negatives-abbd42d.txt`

---

## Claim 17: "A `server=/github.com/...` line covers github.com AND every subdomain (api., codeload., ssh., pkg., ...); likewise githubusercontent.com covers objects./raw./media./github-cloud. — the hosts git, gh and git-lfs actually contact. Anything else on GitHub (ghcr.io, github.dev) is not in the CIDR ingest either, so it stays unresolved AND unroutable."

**Location:** `devcontainer-config/init-firewall.sh:147-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers dnsmasq's documented suffix-matching semantics for `server=/domain/addr` and the fact that `GITHUB_DNS_ZONES` contains exactly those two zones. Does not establish that the CIDR ingest excludes `ghcr.io`/`github.dev` (that depends on GitHub's live `/meta` response, not on this repo) and dnsmasq is not installed in this sandbox, so the matching was not executed.
**Legibility-target:** for-orchestrator-synthesis

`GITHUB_DNS_ZONES="github.com githubusercontent.com"` (`devcontainer-config/init-firewall.sh:154`), consumed at `:191` and emitted one `server=/<zone>/<ns>` per upstream at `:205`. Executed `--print-dnsmasq-conf` shows exactly `server=/github.com/…` and `server=/githubusercontent.com/…` appended after the profile domains (`docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`). dnsmasq's documented behaviour for `server=/<domain>/<ip>` is to route the domain *and all its subdomains* to that server; this is the semantics the claim relies on and it is not exercisable here (`command -v dnsmasq` → not installed, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`) — hence Medium confidence.

**Evidence:** `devcontainer-config/init-firewall.sh:154`, `devcontainer-config/init-firewall.sh:191`, `devcontainer-config/init-firewall.sh:205`, `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`

---

## Claim 18a: "The load-bearing property is what is ABSENT: there is no bare `server=` line and `no-resolv` stops dnsmasq reading /etc/resolv.conf, so the daemon has no default upstream at all. … With NO upstream … the config has zero server lines"

**Location:** `devcontainer-config/init-firewall.sh:161-173`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the generated config's shape in both the with-upstream and no-upstream cases. Does not establish dnsmasq's runtime response to a name with no matching `server=` line — that is Claim 18b.
**Legibility-target:** for-orchestrator-synthesis

`compose_dnsmasq_conf` (`devcontainer-config/init-firewall.sh:174-208`, read in full) emits a fixed preamble containing `no-resolv` and never a bare `server=`; every `server=` it writes is of the form `server=/$d/$ns` (`:205`). Executed with the `llm` profile and a synthetic resolv.conf: the output is the preamble plus nine `server=/<domain>/127.0.0.11` lines and nothing else. Executed with an empty resolv.conf: the early return at `:186-189` fires and the output is the preamble plus `# NO UPSTREAM: …` — zero `server=` lines. Both in `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`.

**Evidence:** `devcontainer-config/init-firewall.sh:174-208`, `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`

---

## Claim 18b: "A name that matches no `server=/<domain>/` line has nowhere to go and dnsmasq answers REFUSED — it is never forwarded"

**Location:** `devcontainer-config/init-firewall.sh:163-165`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond "the config gives dnsmasq no route for such a name" (established in 18a). Does not establish the specific RCODE returned. The security property that matters — *not forwarded* — follows from 18a; only the "REFUSED" wording is unverified.
**Legibility-target:** for-orchestrator-synthesis

Blocker: `dnsmasq` is not installed in the review sandbox (`command -v dnsmasq` → nothing, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`), and there is no Docker or root available to install or run one. Verifying would need a live container built from `devcontainer-config/Dockerfile` and a `dig @127.0.0.1 not-allowlisted.example` against the generated config, checking the RCODE. The commit message for `d598bda` independently flags "dnsmasq REFUSED-with-no-servers behaviour" as asserted from documentation and needing a live check, and `docs/working/questions.md` carries it — so the gap is already tracked, not newly discovered here.

**Evidence:** `devcontainer-config/init-firewall.sh:161-173`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`, `git log bd41aef..HEAD --no-merges` (d598bda Notes)

---

## Claim 19: "Profile entries may carry a `:port` suffix …; the resolver only wants the name. Then refuse anything that is not a plain hostname: a `/` or `#` here would be read by dnsmasq as config syntax"

**Location:** `devcontainer-config/init-firewall.sh:192-196`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering (strip `:port`, then hostname-check) and the warn-and-omit path. Does not establish that the omitted name is unreachable at the *IP* layer — it is omitted from DNS only; the ipset is populated independently in phase A.
**Legibility-target:** for-orchestrator-synthesis

The strip precedes the regex:

```
d="${d%%:*}"
[ -n "$d" ] || continue
if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]; then
  echo "WARNING: not a hostname, omitting from resolver allowlist (stays unresolvable): $d" >&2
  continue
fi
```
(`devcontainer-config/init-firewall.sh:197-202`; excerpt ends `:202`, enclosing `compose_dnsmasq_conf()` continues to `:208` — read: the inner `while read -r ns` loop that emits one `server=` line per upstream.)

Executed both halves: `host.docker.internal:11434` emits `server=/host.docker.internal/…` with no port, and a profile line `evil/line#x` produces the WARNING and no config line, exit 0 — `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`, `docs/reviews/execution-logs/cfc-r2-hook-negatives-abbd42d.txt`.

**Evidence:** `devcontainer-config/init-firewall.sh:197-208`, `docs/reviews/execution-logs/cfc-r2-hook-negatives-abbd42d.txt`

---

## Claim 20: "The policy calls are VERIFIED, not trusted. … the trap re-reads the live policies with `iptables -S` afterwards and says which of two very different things happened … The \"forced DROP\" line is printed only AFTER the read-back confirms it, so the log never claims a DROP that was not applied."

**Location:** `devcontainer-config/init-firewall.sh:237-244`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (via the bats suite's `FAIL_POLICY` stub)
**Scope:** Covers the read-back, the per-chain OPEN alarm, and the message ordering for all three chains. Does not establish real netfilter behaviour (the bats stub models policies; no privileged container was available).
**Legibility-target:** for-orchestrator-synthesis

`fail_closed_on_abort()` was read in full (`devcontainer-config/init-firewall.sh:246-270`). The three `-P … DROP || true` calls (`:250-252`) are followed by `policies="$(iptables -w 5 -S 2>/dev/null || true)"` (`:253`) and a per-chain `grep -q "^-P $chain DROP"` (`:254-259`) that sets `open=1` and prints the "may be OPEN" line for any chain that did not take. The "Forced DROP policies (verified)" line sits in the `else` of `if [ "$open" = "1" ]` (`:260-266`), so it cannot print unless every chain read back as DROP. Both `|| true`s are present and the trap has no path that can itself abort. Executed: the suite's OPEN-alarm test under `FAIL_POLICY` and the `-w 5` abort-path tests pass (98/98, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`).

**Evidence:** `devcontainer-config/init-firewall.sh:246-270`, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`

---

## Claim 21: "Chain policies survive `iptables -F` (a flush removes rules, not policies), so ordering them ahead of the flush means there is no instant … at which the chains are empty AND the policy is ACCEPT."

**Location:** `devcontainer-config/init-firewall.sh:465-471`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the source ordering (three `-P … DROP` before any `-F`) and the documented iptables semantics that `-F` does not reset policies. Does not establish kernel behaviour under the container's nf_tables backend — no privileged container was available (`iptables -S` here returns "you must be root", `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`).
**Legibility-target:** for-orchestrator-synthesis

```
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Flush existing rules and delete existing ipsets (policies set above persist)
iptables -F
```
(`devcontainer-config/init-firewall.sh:472-477`; excerpt ends `:477`, the flush block continues to `:483` — `-X`, `-t nat -F/-X`, `-t mangle -F/-X`, `ipset destroy`.)

`iptables -F` is documented to flush *rules*; only `-P` changes a built-in chain's policy. The idempotent re-assert at `:797-799` is a no-op as the comment at `:793-796` claims. A bats test asserts the ordering ("DROP precedes the flush and no network call between the flush and the terminal REJECT") and passes.

**Evidence:** `devcontainer-config/init-firewall.sh:472-483`, `devcontainer-config/init-firewall.sh:793-799`, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`

---

## Claim 22: "a loopback resolver: already admitted unconditionally by `-o lo` below … (and Docker's embedded resolver is DNAT'd off port 53 in nat OUTPUT before filter OUTPUT sees it, so a --dport 53 filter rule would not match that traffic regardless)"

**Location:** `devcontainer-config/init-firewall.sh:560-563`, and the paired guard rationale at `:626-635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the netfilter traversal order for locally generated packets (nat OUTPUT before filter OUTPUT) and the resulting need for an all-ports match on 127.0.0.11. Does not establish that Docker's DNAT is present on every runtime — the restore at `:486-493` is conditional on the pre-flush capture being non-empty.
**Legibility-target:** for-orchestrator-synthesis

For locally generated packets the traversal is raw OUTPUT → conntrack → mangle OUTPUT → nat OUTPUT → filter OUTPUT, so a DNAT in nat OUTPUT has already rewritten the destination port by the time a `--dport 53` filter rule is evaluated. The code acts on exactly that: the guard jump is on the address with no port match at all —

```
iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD
iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
iptables -A OUTPUT -o lo -j ACCEPT
```
(`devcontainer-config/init-firewall.sh:720-723`; this is the end of the loopback-accept group, which begins at `:716`.)

The three guard jumps precede the `-o lo` accept, as the comment at `:717-719` and `:631-635` both claim, and `CC_DNS_GUARD` RETURNs for the dnsmasq uid and root before rejecting (`:693-696`).

**Evidence:** `devcontainer-config/init-firewall.sh:716-723`, `devcontainer-config/init-firewall.sh:693-696`, `devcontainer-config/init-firewall.sh:626-635`

---

## Claim 23: "The nat rules are INSERTED at position 1, ahead of the `-d 127.0.0.11 -j DOCKER_OUTPUT` jump restored above: were they appended, a node query to 127.0.0.11:53 would be DNAT'd to the embedded resolver before the redirect could claim it."

**Location:** `devcontainer-config/init-firewall.sh:637-641`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the relative order of the `CC_DNS` jumps and the restored Docker DNAT rules in nat OUTPUT. Does not establish the order *between* the two `CC_DNS` jumps (udp is inserted second, so it ends up first) — immaterial, as they match disjoint protocols.
**Legibility-target:** for-orchestrator-synthesis

The Docker rules are captured pre-flush and replayed with `xargs -L 1 iptables -t nat`, i.e. with whatever verb `iptables-save` emitted — `-A` (append):

```
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)
```
(`devcontainer-config/init-firewall.sh:460`) and `echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat` (`:490`, inside the `if` block `:486-493`). That runs at `:490`, *before* the `CC_DNS` block at `:681-687`, which uses `-I OUTPUT 1`:

```
iptables -t nat -I OUTPUT 1 -p tcp --dport 53 -j CC_DNS
iptables -t nat -I OUTPUT 1 -p udp --dport 53 -j CC_DNS
```
(`:686-687`; excerpt ends `:687`, the FILTERING RESOLVER block continues to `:697`.)

An insert at position 1 after the appends therefore lands ahead of them, as claimed. `CC_SNI`'s jump uses `-A` (`:886`), which is correct there because nothing else in nat OUTPUT matches tcp/443.

**Evidence:** `devcontainer-config/init-firewall.sh:460`, `devcontainer-config/init-firewall.sh:486-493`, `devcontainer-config/init-firewall.sh:686-687`

---

## Claim 24: "Idempotent restart: kill by pidfile, then start exactly one instance." / "--daemon: … (a prior instance named by the pidfile is terminated first, so re-runs are idempotent)"

**Location:** `devcontainer-config/init-firewall.sh:661`, `devcontainer-config/init-firewall.sh:871-872`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (bats)
**Scope:** Covers both daemons' restart paths *and* the iptables/ipset objects a re-run recreates — the load-bearing part of the idempotency claim. Does not establish behaviour when a prior instance exists with no pidfile and a pid that is not `dnsmasq`/`cc-sni-proxy` (dnsmasq additionally sweeps by uid; the proxy does not).
**Legibility-target:** for-orchestrator-synthesis

Daemon side. `stop_dnsmasq` (`devcontainer-config/init-firewall.sh:413-428`, read in full) validates the pidfile's pid against `/proc/$pid/comm == dnsmasq` before killing, escalates to `-9` after 3s, removes the pidfile, then sweeps `pkill -x -U "$DNSMASQ_UID" dnsmasq`. It is called immediately before the single `dnsmasq --conf-file=…` invocation (`:667-668`). The proxy's `stop_prior` (`devcontainer-config/cc-sni-proxy.py:212-232`) does the same shape, validating `/proc/{pid}/cmdline` contains `cc-sni-proxy`, and is called first in `daemonize` (`:242`).

Chain/ipset side — this is where a second run would have bricked the container if the objects survived, so it was traced explicitly. All four chains created without `-N … || true` (`CC_DNS`, `CC_SNI` in nat at `:681`, `:882`; `CC_DNS_GUARD`, `CC_SNI_GUARD` in filter at `:693`, `:892`) are deleted by the phase-B flush before they are recreated: `iptables -F; iptables -X` clears the filter table's user chains and `iptables -t nat -F; iptables -t nat -X` the nat table's (`:477-480`). `-X` with no argument deletes every non-builtin chain in that table, and the preceding `-F` removes the rules that would otherwise hold references. The ipset is likewise destroyed before `ipset create` (`:483`, `:731`). So a second `-N` cannot fail with "chain already exists" and cannot trip the fail-closed trap.

Executed: bats tests "a re-run kills the previous dnsmasq by pidfile and does not double-start" (`test/init-firewall-rules.bats:576`) and "the SNI proxy is started as ccproxy … exactly one start per run" (`:708`) pass in the 98/98 run — `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`. The stub-based suite does not model "chain already exists" as an error, so the chain half of this verdict rests on the static trace above plus documented `iptables -X` semantics, not on the tests.

**Evidence:** `devcontainer-config/init-firewall.sh:413-428`, `devcontainer-config/init-firewall.sh:667-668`, `devcontainer-config/init-firewall.sh:477-483`, `devcontainer-config/init-firewall.sh:681`, `devcontainer-config/init-firewall.sh:693`, `devcontainer-config/init-firewall.sh:882`, `devcontainer-config/init-firewall.sh:892`, `devcontainer-config/cc-sni-proxy.py:212-242`, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`

---

## Claim 25: "The proxy reads the ClientHello, admits the connection only if the SNI is on the allowlist written here, RESOLVES THE SNI NAME ITSELF and connects there … Its name lookups go through the container resolver (the filtering dnsmasq above), so an SNI that is not allowlisted for DNS is doubly dead."

**Location:** `devcontainer-config/init-firewall.sh:818-827`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the proxy's resolve-the-SNI behaviour and the fact that `ccproxy` is *not* exempt from the DNS redirect, so its lookups do traverse dnsmasq. Does not establish that the proxy's own egress is actually constrained by the ipset at the kernel level (untested — no privileged container).
**Legibility-target:** for-orchestrator-synthesis

The resolve-and-connect path is Claim 4. The "doubly dead" half turns on `ccproxy` being absent from the `CC_DNS` exemption list, which it is: the chain RETURNs only for `$DNSMASQ_UID` and `0` (`devcontainer-config/init-firewall.sh:682-683`), while the SNI chain separately RETURNs for `$CCPROXY_UID` and `0` (`:883-884`). So a `getaddrinfo` from the proxy is redirected to dnsmasq at 127.0.0.1:53 like any other non-exempt uid, and a name with no `server=` line gets no answer (Claim 18a/18b).

**Evidence:** `devcontainer-config/init-firewall.sh:682-683`, `devcontainer-config/init-firewall.sh:883-884`, `devcontainer-config/cc-sni-proxy.py:182-186`

---

## Claim 26: "GitHub is admitted by CIDR (phase A) rather than by name; these are the zones git, gh and git-lfs actually contact over 443." (immediately above `.github.com` / `.githubusercontent.com` / `.githubassets.com`)

**Location:** `devcontainer-config/init-firewall.sh:864-868`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the third zone, `.githubassets.com`. The claim is accurate for `.github.com` and `.githubusercontent.com`; the verdict is carried entirely by the third entry, per the compound-claim rule (most-severe part wins).
**Legibility-target:** for-author

`.githubassets.com` is written into the SNI allowlist —

```
echo ".github.com"
echo ".githubusercontent.com"
echo ".githubassets.com"
} > "$SNI_ALLOWLIST"
```
(`devcontainer-config/init-firewall.sh:866-869`; excerpt ends `:869`, the SNI block continues to `:897`.)

— but `githubassets.com` is absent from `GITHUB_DNS_ZONES`, which is exactly `"github.com githubusercontent.com"` (`:154`). Executed `--print-dnsmasq-conf` confirms the generated resolver config carries `server=/github.com/…` and `server=/githubusercontent.com/…` and no `githubassets` line (`docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`). Under this design a name with no `server=` line is never forwarded, so no client using the container resolver can obtain an address for `*.githubassets.com` and the SNI entry can never be reached. The file's *own* companion comment at `:150-153` lists only `github.com` and `githubusercontent.com` as "the hosts git, gh and git-lfs actually contact", so the two comments disagree.

Separately, `githubassets.com` is GitHub's web-UI asset CDN; `git`, `gh` and `git-lfs` contact `github.com`, `codeload.github.com`, `objects.githubusercontent.com` and friends, not it — hence Medium rather than High confidence on that half (it rests on knowledge of GitHub's hosts, not on repo evidence). The repo-internal half — the entry is inert because the resolver refuses the name — is fully established. Not a fabrication (`githubassets.com` is a real host), so no hallucination-log entry.

Precise version: either drop `.githubassets.com` from the SNI allowlist, or add `githubassets.com` to `GITHUB_DNS_ZONES` and correct the "git, gh and git-lfs" attribution to name the web UI. `test/init-firewall-rules.bats:727` asserts the current (inert) entry, so it would need updating either way.

**Evidence:** `devcontainer-config/init-firewall.sh:154`, `devcontainer-config/init-firewall.sh:864-869`, `devcontainer-config/init-firewall.sh:150-153`, `test/init-firewall-rules.bats:727`, `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`

---

## Claim 27: "SNI proxy probes, run AS NODE so they traverse the redirect (root is exempt)." / "Negative: an address that IS in the ipset, asked for with a name that is NOT allowlisted, must be refused"

**Location:** `devcontainer-config/init-firewall.sh:926-936`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed (partial)
**Scope:** Covers that both probes run as `node` via `runuser`, that `runuser` exists in the image, and that `ANTHROPIC_PROBE_IP` is non-empty on every path that reaches the probe. Does not establish that the negative probe *fails for the intended reason* — a curl that errors for any other cause also lands in the else branch and prints "verification passed".
**Legibility-target:** for-author

`ANTHROPIC_PROBE_IP` is initialised to `""` (`devcontainer-config/init-firewall.sh:347`) and set to the first A record of `api.anthropic.com` inside the resolve loop (`:380-382`). `api.anthropic.com` is unconditionally in `base.txt` (`devcontainer-config/egress/base.txt:25`, confirmed by the executed `--print-entries`), and a failure to resolve it is fatal at `:364-367`, so by the time control reaches `:937` the variable is always a validated dotted quad. Multiple A records are handled by the `-z` guard — the first is kept. `runuser` is present at `/usr/sbin/runuser` in this image (`docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`), and the script runs as root so `/usr/sbin` is on `PATH`.

The imprecision: the negative probe's success condition is "curl exited non-zero", not "the proxy rejected the SNI". Any unrelated curl failure — a `--resolve` parse error, a transient DNS problem, the proxy being wedged — produces the same "Firewall verification passed - non-allowlisted SNI refused as expected" line at `:942`. The positive probe at `:928` bounds this in practice (it must succeed through the same proxy), which is why this is Mostly accurate and not Incorrect. Precise version would grep `$SNI_LOG` for a `REJECT sni=not-allowlisted.invalid` line rather than relying on curl's exit status alone.

**Evidence:** `devcontainer-config/init-firewall.sh:347`, `devcontainer-config/init-firewall.sh:364-367`, `devcontainer-config/init-firewall.sh:380-382`, `devcontainer-config/init-firewall.sh:926-943`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`, `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`

---

## Claim 28: "The blanket `INPUT -s <bridge>/24` / `OUTPUT -d <bridge>/24` accepts are replaced by `OUTPUT -d <gateway> --dport 53` (udp+tcp) with no inbound counterpart (replies are ESTABLISHED,RELATED)." / row 41: "TCP only" (nat `CC_SNI` on tcp/443)

**Location:** `docs/decisions/log.md:57` (row 39), `docs/decisions/log.md:61` (row 41)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of any bridge-/24 rule and of any inbound counterpart to the gateway:53 accept, and the tcp-only scope of the SNI redirect. Does not establish that no *other* inbound path exists (the `-i lo` accept at `:716` and the ESTABLISHED,RELATED accept at `:802` remain).
**Legibility-target:** for-orchestrator-synthesis

Grepping the resulting file, the only `$HOST_IP` rules are the four owner-scoped gateway:53 accepts:

```
for uid in "$DNSMASQ_UID" 0; do
    iptables -A OUTPUT -p udp -d "$HOST_IP" --dport 53 -m owner --uid-owner "$uid" -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$HOST_IP" --dport 53 -m owner --uid-owner "$uid" -j ACCEPT
done
```
(`devcontainer-config/init-firewall.sh:788-791`; excerpt is the complete loop, followed at `:793-799` by the idempotent policy re-assert.)

There is no `-A INPUT -s` rule anywhere except `-i lo` (`:716`) and the ESTABLISHED,RELATED accept (`:802`), and no `/24` appears in the file at all. The removed `--sport 53` inbound accept is documented as deliberately absent at `:698-703`. The SNI redirect is `-p tcp --dport 443` only (`:886`), and `CC_SNI`'s REDIRECT rule is `-p tcp` (`:885`).

**Evidence:** `devcontainer-config/init-firewall.sh:788-791`, `devcontainer-config/init-firewall.sh:698-703`, `devcontainer-config/init-firewall.sh:885-886`

---

## Claim 29: row 39 "Guarded by 7 new bats tests"; row 40 "verified by 10 new command-sequence bats tests"; row 41 "Guarded by 10 bats tests + 13 Python unit tests"

**Location:** `docs/decisions/log.md:57`, `docs/decisions/log.md:62`, `docs/decisions/log.md:61`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts of tests added by each commit and, for row 41, the count present at HEAD. Does not establish that those tests exercise real kernel behaviour — they drive stubbed `iptables`/`ipset`/`dig`/`dnsmasq` binaries, as the commit messages themselves say.
**Legibility-target:** for-orchestrator-synthesis

Counted mechanically (this claim shape matches both logged hallucination patterns, so it was not taken on trust):

- `git show f1443c5 -- test/init-firewall-rules.bats | grep -c '^+@test'` → 7 (row 39).
- `git show d598bda -- test/init-firewall-rules.bats | grep -c '^+@test'` → 10 (row 40).
- `git show aa8dffc -- test/init-firewall-rules.bats | grep -c '^+@test'` → 10, and `git show aa8dffc -- test/test_cc_sni_proxy.py | grep -c '^+    def test_'` → 13 (row 41). The 10 SNI tests are all present at HEAD (`test/init-firewall-rules.bats:708,720,733,745,764,773,781,788,799,806`) and the Python suite reports "Ran 13 tests … OK" (`docs/reviews/execution-logs/cfc-r2-pytests-abbd42d.txt`).

**Evidence:** `test/init-firewall-rules.bats:708-812`, `docs/reviews/execution-logs/cfc-r2-pytests-abbd42d.txt`, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`

---

## Claim 30: "the proxy logs every decision to `/run/cc-sni-proxy/proxy.log` as `ALLOW`, `REJECT sni=... not in allowlist`, or `FAIL` (the name resolved to an address the ipset does not admit)." / "Root inside the container. The firewall script's own fetch and probes run as root and bypass the redirect"

**Location:** `guides/cc-isolated-usage.md:296-302`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the log path and the three-verb vocabulary. Does not establish the log's contents at runtime. Two imprecisions below.
**Legibility-target:** for-author

The path is right: `SNI_LOG="$SNI_RUN_DIR/proxy.log"` with `SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"` (`devcontainer-config/init-firewall.sh:438`, `:441`), passed as `--log "$SNI_LOG"` (`:875`), and the daemon dups fds 1 and 2 onto it (`devcontainer-config/cc-sni-proxy.py:243`, `:262`). The verbs match `log()` calls at `cc-sni-proxy.py:176`, `:179`, `:188`, `:190`, and `REJECT sni={sni} orig_dst={orig}: not in allowlist` (`:179`) matches the guide's elided form.

Two corrections:

1. `FAIL` is not specific to an ipset denial. It is the handler for `(OSError, asyncio.TimeoutError)` around *both* `getaddrinfo` and `open_connection` (`cc-sni-proxy.py:187-188`), so a DNS refusal from the filtering resolver produces `FAIL` too — the code's own message hedges with a question mark ("resolved address not in the ipset?"); the guide states it as fact. Precise version: "FAIL (the name could not be resolved, or the resolved address could not be connected to — typically the ipset)".
2. "probes run as root" is wrong for the two probes that matter here. The SNI probes are deliberately run as `node`: `runuser -u node -- curl …` at `devcontainer-config/init-firewall.sh:928` and `:937`, with the comment at `:926` saying so explicitly. Only the `example.com` and `api.github.com` probes (`:911`, `:919`) run as root. The list item's headline point — root bypasses the redirect, the agent does not — is correct; the supporting detail is not.

**Evidence:** `devcontainer-config/init-firewall.sh:438-441`, `devcontainer-config/init-firewall.sh:875`, `devcontainer-config/init-firewall.sh:911-937`, `devcontainer-config/cc-sni-proxy.py:176-190`

---

## Claim 31: "98/98 bats + 13/13 python unit tests; shellcheck clean" (aa8dffc) · "77/77 pass" (b04090c) · "75/75 across both suites" and "docs/decisions/log.md: row 39 records the decision" (d598bda) · "88/88 bats pass" (1dbdabd)

**Location:** commit messages in `bd41aef..HEAD` (`aa8dffc`, `b04090c`, `d598bda`, `1dbdabd`)
**Type:** Configuration / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four test-count assertions (all correct) and the decision-row reference in `d598bda` (superseded). The verdict is carried by the row-number reference; the counts alone would be Verified.
**Legibility-target:** for-author

Counts, all confirmed:

- `aa8dffc`: executed `LC_ALL=C bats test/init-firewall-rules.bats test/cc-isolated-functions.bats` → `1..98`, 98 `ok`, 0 `not ok`, exit 0; `LC_ALL=C python3 test/test_cc_sni_proxy.py` → "Ran 13 tests … OK", exit 0; `LC_ALL=C shellcheck -S warning devcontainer-config/init-firewall.sh` → no output, exit 0. Logs: `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`, `…/cfc-r2-pytests-abbd42d.txt`, `…/cfc-r2-shellcheck-abbd42d.txt`.
- `b04090c` "77/77": the five suites the message names sum to exactly 77 `@test` blocks at that commit (cc-isolated-functions 52 + guide-index-sync 1 + init-firewall-rules 13 + link-claude-home-wiring 10 + cross-reference-integrity 1).
- `d598bda` "75/75" and `1dbdabd` "88/88" are consistent with the same per-commit `@test` counts (46 + 52 = 98 at HEAD, less the 10 SNI tests added by `aa8dffc` = 88 at the merge).

The stale part: `d598bda`'s body says "docs/decisions/log.md: row 39 records the decision", but at HEAD the filtering-resolver decision is row **40** (`docs/decisions/log.md:62`); row 39 is port scoping (`:57`). This is self-corrected in the merge commit that brought the branch in — `1dbdabd`'s body says "renumbered the branch's decision-log row to #40 (#39 was taken by port scoping)" — so the record is complete in `git log`, and the branch commit message is immutable. Flagged for the log, not for action.

**Evidence:** `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`, `docs/reviews/execution-logs/cfc-r2-pytests-abbd42d.txt`, `docs/reviews/execution-logs/cfc-r2-shellcheck-abbd42d.txt`, `docs/decisions/log.md:57`, `docs/decisions/log.md:62`

---

## Claims Requiring Attention

### Incorrect
- **Claim 26** (`devcontainer-config/init-firewall.sh:864-868`): `.githubassets.com` is written into the SNI allowlist but is absent from `GITHUB_DNS_ZONES`, so the filtering resolver never answers for it and the entry is unreachable; the comment also attributes it to `git`/`gh`/`git-lfs`, which contact `github.com` and `githubusercontent.com` (as the file's own comment at `:150-153` says). Fix by dropping the entry or adding the zone to `GITHUB_DNS_ZONES`; `test/init-firewall-rules.bats:727` pins the current form.

### Stale
- **Claim 5** (`devcontainer-config/cc-sni-proxy.py:20-21`): "a filtering dnsmasq once that lands" — it landed two commits earlier in the same range and is unconditional at HEAD.
- **Claim 31** (`d598bda` commit message): "row 39 records the decision" — the row is 40 at HEAD; already self-corrected by the merge commit `1dbdabd`, so no action.

### Mostly Accurate
- **Claim 3** (`devcontainer-config/cc-sni-proxy.py:4-5`): the module docstring omits root's exemption from the 443 redirect; `init-firewall.sh:830-835` has it right.
- **Claim 12** (`devcontainer-config/devcontainer.json:73-79`): correct on all three named variables, but the docs name a fourth with the same effect, `DISABLE_GROWTHBOOK`, which the do-not-set list should include.
- **Claim 14** (`devcontainer-config/egress/base.txt:22-24`): the documented purpose of `platform.claude.com` is verified; the "mid-session re-login" symptom is the comment's own inference, not in the cited page.
- **Claim 27** (`devcontainer-config/init-firewall.sh:934-943`): the negative SNI probe's pass condition is "curl exited non-zero", so any unrelated curl failure also prints "verification passed"; greping `$SNI_LOG` for the `REJECT` line would make it a real check.
- **Claim 30** (`guides/cc-isolated-usage.md:296-302`): `FAIL` also covers a DNS refusal, not only an ipset denial; and the SNI probes run as `node` via `runuser`, not as root.

### Unverifiable
- **Claim 18b** (`devcontainer-config/init-firewall.sh:163-165`): dnsmasq's REFUSED response to a name with no `server=` line. Blocker: `dnsmasq` is not installed in the review sandbox and there is no Docker/root to run one; needs a live container built from `devcontainer-config/Dockerfile` plus a `dig @127.0.0.1` RCODE check. The security-relevant half ("never forwarded") is established by Claim 18a. Already tracked in `docs/working/questions.md` and in `d598bda`'s Notes.

---

## Goal-Alignment Note
- Answered: yes — all 15 briefed claim areas checked; the two claims flagged as load-bearing (chain idempotency across re-runs, resolve-the-SNI) both hold.
- Out of scope: `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py`, `docs/working/questions.md` treated as context only, per the brief; code quality, architecture and security judgement left to the sibling critics.
- Escalate: (a) `.githubassets.com` (Claim 26) is a one-line fix but touches a pinned bats assertion — route it as a real change, not a comment edit. (b) The negative SNI probe's exit-status-only pass condition (Claim 27) is a verification-strength issue rather than a documentation issue; the security critic should decide whether a false-pass there matters given the positive probe runs first. (c) `console.anthropic.com` remains in `base.txt` although the page base.txt names as its source of truth no longer lists it (noted under Claim 13) — a profile-content question for the author, not a claim defect. (d) Claim 18b is the only claim in this pass whose subject could not be executed; it is the same live-container gap the commit messages already flag.
