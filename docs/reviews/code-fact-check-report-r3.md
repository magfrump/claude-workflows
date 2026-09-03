# Code Fact-Check Report

Commit: abbd42d
**Repository:** claude-workflows (`/workspace`)
**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` — `Dockerfile`, `cc-sni-proxy.py`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`, `init-firewall.sh`; plus claims in `docs/decisions/log.md` rows 39–41, `guides/cc-isolated-usage.md`, and the range's non-merge commit messages
**Checked:** 2026-09-03
**Total claims checked:** 39
**Summary:** 27 verified, 6 mostly accurate, 2 stale, 0 incorrect, 4 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read before starting. Its two entries are both of the form "a specific measured value quoted from a checked-in artifact set that does not contain it". Claims 32–34 (bats/python test counts asserted in `docs/decisions/log.md`) and claim 38 (the "98/98 bats + 13/13 python" commit-message claim) are the matching class in this scope; all four were executed rather than read, and all four hold.

Execution logs: `docs/reviews/execution-logs/r3-bats.log`, `r3-python.log`, `r3-shellcheck.log`, `r3-hooks.log`.

---

## Claim 1: "dnsmasq-base (above) is the daemon binary WITHOUT the `dnsmasq` package's sysv/systemd service wrapper: nothing in the container may auto-start a resolver"

**Location:** `devcontainer-config/Dockerfile:44-46`
**Type:** Configuration / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing positively; the Debian package split could not be confirmed from this sandbox. Does not establish that `dnsmasq-base` omits the service wrapper, nor that it includes it.
**Legibility-target:** for-orchestrator-synthesis

The claim is about Debian package contents, not about code in this repository. Confirming it requires either the package metadata or the package itself. Neither is available: `apt-cache show dnsmasq-base` and `apt-cache show dnsmasq` both return `E: No packages found` (no apt lists in this sandbox — paraphrased — no quote available because the output is the two-word apt error already given), and `WebFetch` of `https://packages.debian.org/bookworm/dnsmasq-base` and `.../dnsmasq` both failed with no output (host unreachable from the review sandbox). Blocker: no package metadata source reachable.

What *is* checkable in-repo is the consequence the comment draws, and it holds: the image installs only `dnsmasq-base` (`devcontainer-config/Dockerfile:34`, the `dnsmasq-base \` line in the apt list), and `init-firewall.sh` never invokes a service manager — it stops any prior instance and starts exactly one itself (`devcontainer-config/init-firewall.sh:667-668`: `stop_dnsmasq` / `dnsmasq --conf-file="$DNSMASQ_CONF" --pid-file="$DNSMASQ_PIDFILE"`). The paired `useradd` assertion the comment describes is present at `devcontainer-config/Dockerfile:51-52`.

**Evidence:** `devcontainer-config/Dockerfile:34`, `devcontainer-config/Dockerfile:51-52`, `devcontainer-config/init-firewall.sh:667-668`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 2: "Stdlib-only Python so it needs no pip and no network at build time; root-owned and 0555 like the firewall script it belongs to"

**Location:** `devcontainer-config/Dockerfile:386-388`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every import in the proxy is a CPython standard-library module and that the `COPY`ed file is made root-owned 0555. Does not establish that the file's runtime behaviour is stdlib-only in the sense of never shelling out (it does not, but that is a separate reading).
**Legibility-target:** for-orchestrator-synthesis

The proxy's import block is `argparse`, `asyncio`, `os`, `pwd`, `re`, `signal`, `socket`, `struct`, `sys`, `time` (`devcontainer-config/cc-sni-proxy.py:27-36`) — all stdlib, so no `pip` step and no build-time network fetch is implied. The ownership/mode assertion is executed by `chown root:root /usr/local/bin/cc-sni-proxy.py && chmod 0555 /usr/local/bin/cc-sni-proxy.py` (`devcontainer-config/Dockerfile:410`), in the same `RUN` as the firewall script's `chmod +x` (`devcontainer-config/Dockerfile:409`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:27-36`, `devcontainer-config/Dockerfile:389`, `devcontainer-config/Dockerfile:409-410`

---

## Claim 3: "Step 3 is why a forged SNI cannot steer a connection: the original destination (SO_ORIGINAL_DST) is read for the log line only and is never connected to."

**Location:** `devcontainer-config/cc-sni-proxy.py:14-16`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the upstream address is derived solely from resolving the SNI and that `orig` reaches only `log()` calls. Does not establish that the *resolved* address is safe — that is delegated to the ipset and to dnsmasq, which the comment says separately.
**Legibility-target:** for-orchestrator-synthesis

`handle()` was read end to end (`devcontainer-config/cc-sni-proxy.py:168-196`). `orig` is bound once at `:169` (`orig = original_dst(client_w.get_extra_info("socket"))`) and thereafter appears only inside the four `log()` f-strings at `:176`, `:179`, `:188`, `:190`. The upstream address comes exclusively from resolving the SNI: `infos = await asyncio.get_running_loop().getaddrinfo(sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)` then `ip = infos[0][4][0]` (`:182-184`), and the connection is `await asyncio.open_connection(ip, upstream_port)` (`:186`). Nothing in the enclosing unit — through the `finally` block at `:193-196`, the last lines of the function — uses `orig` as an address.

`original_dst()` itself (`:145-150`) only reads the socket option and formats a string, returning `"unknown"` on any of `OSError, struct.error, AttributeError`.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:145-150`, `devcontainer-config/cc-sni-proxy.py:168-196`

---

## Claim 4: "Resolution uses the container's resolver (/etc/resolv.conf — Docker's embedded DNS today, a filtering dnsmasq once that lands)"

**Location:** `devcontainer-config/cc-sni-proxy.py:20-21`
**Type:** Staleness / Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "today / once that lands" tense only. Does not dispute that resolution goes through the container's configured resolver, which remains true.
**Legibility-target:** for-author

The filtering dnsmasq landed earlier in this same commit range (`d598bda`), so the parenthetical's future tense is out of date at `abbd42d`. What the proxy actually reaches today is dnsmasq, and not via `/etc/resolv.conf` at all: `CC_DNS` returns early only for the dnsmasq uid and uid 0 (`devcontainer-config/init-firewall.sh:682-683`), so the `ccproxy` uid falls through to `iptables -t nat -A CC_DNS -p udp -j REDIRECT --to-ports 53` (`:684-685`) and its lookups are steered to 127.0.0.1:53 by the kernel regardless of what `/etc/resolv.conf` says. The firewall's own comment states the corrected version: "Its name lookups go through the container resolver (the filtering dnsmasq above), so an SNI that is not allowlisted for DNS is doubly dead" (`devcontainer-config/init-firewall.sh:825-827`).

Precise version: "Resolution goes to the container's filtering dnsmasq — this process's port-53 traffic is REDIRECTed there by the firewall, not selected from /etc/resolv.conf — and is IPv4-only."

**Evidence:** `devcontainer-config/cc-sni-proxy.py:20-22`, `devcontainer-config/init-firewall.sh:682-687`, `devcontainer-config/init-firewall.sh:825-827`

---

## Claim 5: "is IPv4-only, matching the IPv4-only ipset. Non-443 ports are not redirected here and stay IP+port-matched."

**Location:** `devcontainer-config/cc-sni-proxy.py:21-22`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the proxy's own resolution family and the redirect's port scope. Does not establish that IPv6 traffic is *blocked* — it is not; the script installs no `ip6tables` rules at all, which its own comment concedes (`init-firewall.sh:510-512`).
**Legibility-target:** for-orchestrator-synthesis

`getaddrinfo(..., family=socket.AF_INET, ...)` pins the lookup to IPv4 (`devcontainer-config/cc-sni-proxy.py:182-183`). The ipset is created as `ipset create allowed-domains hash:net,port` and populated with IPv4 CIDRs and IPv4 A-record addresses only (`devcontainer-config/init-firewall.sh:731`, `:744-745`, `:373-384`). The redirect is scoped to a single port: `iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI` (`devcontainer-config/init-firewall.sh:886`). Other allowlisted ports reach only the `dst,dst` ipset accept (`:902`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:182-184`, `devcontainer-config/init-firewall.sh:731`, `devcontainer-config/init-firewall.sh:886`, `devcontainer-config/init-firewall.sh:902`

---

## Claim 6: "Single file, stdlib only (python3.11 ships in the node:22 base — no apt package, no pip)"

**Location:** `devcontainer-config/cc-sni-proxy.py:24-25`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the Debian 12 (bookworm) base underlying `node:22` provides python3.11 and that the proxy uses no non-stdlib import. Does not establish that the *image built from this Dockerfile* has python3.11 — that was not built here; the evidence is the same base distribution.
**Legibility-target:** for-orchestrator-synthesis

The review sandbox is the same base: `PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"` and `Python 3.11.2` (`docs/reviews/execution-logs/r3-python.log` records the 13-test run on that interpreter; the version/os-release capture is in the same session — paraphrased — no quote available because the `os-release`/`python3 -V` probe was an ad-hoc command not written to a log file). The Dockerfile independently asserts the same thing in a pre-existing comment: "The node:22 (bookworm) base ships python3.11 but no pip and, crucially, no `ensurepip`" (`devcontainer-config/Dockerfile:88-89`), and `FROM node:22` at `devcontainer-config/Dockerfile:11`.

The proxy's 13 unit tests execute against python3.11 with exit 0 (`Ran 13 tests in 0.128s` / `OK`, `docs/reviews/execution-logs/r3-python.log`), which also exercises the no-third-party-import property.

**Evidence:** `devcontainer-config/Dockerfile:11`, `devcontainer-config/Dockerfile:88-89`, `docs/reviews/execution-logs/r3-python.log`

---

## Claim 7: "SO_ORIGINAL_DST = 80          # linux/netfilter_ipv4.h; not exposed by the socket module"

**Location:** `devcontainer-config/cc-sni-proxy.py:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the constant's numeric value and the unpack layout it is used with. Does not establish that the `getsockopt` call succeeds under a real REDIRECT — that needs a live kernel and is the live-container item the commit message already flags.
**Legibility-target:** for-orchestrator-synthesis

`SO_ORIGINAL_DST` is 80 in `linux/netfilter_ipv4.h`, and Python's `socket` module exposes no such name. The consuming unpack is consistent with a `struct sockaddr_in`: `struct.unpack("!2xH4s8x", sock.getsockopt(socket.SOL_IP, SO_ORIGINAL_DST, 16))` (`devcontainer-config/cc-sni-proxy.py:147`) skips 2 bytes of `sin_family`, reads a big-endian `sin_port`, reads 4 bytes of `sin_addr`, and skips the 8-byte `sin_zero` — 16 bytes total, matching the `getsockopt` length argument.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:38`, `devcontainer-config/cc-sni-proxy.py:145-150`

---

## Claim 8: "`name` lines match exactly; `.zone` lines match the zone and every subdomain of it. Blank lines and #-comments are ignored."

**Location:** `devcontainer-config/cc-sni-proxy.py:123-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exact/zone matching, comment and blank-line handling, and case-insensitivity on both sides. Does not establish behaviour for a degenerate `.` line — that lands in `zones` as the empty string and matches nothing, which is harmless but undocumented.
**Legibility-target:** for-orchestrator-synthesis

`Allowlist.load` strips at the first `#`, strips whitespace, lower-cases, skips empties, and routes on a leading dot: `(al.zones if line.startswith(".") else al.exact).add(line.lstrip("."))` (`devcontainer-config/cc-sni-proxy.py:134-137`). `allows` is `name in self.exact or any(name == z or name.endswith("." + z) for z in self.zones)` (`:141-142`) — so a zone entry matches the apex and every subdomain, and an exact entry matches only itself. The SNI side is lower-cased and trailing-dot-stripped before comparison: `name = raw.decode("ascii").lower().rstrip(".")` (`:58`), so the lower-casing on both sides lines up.

Executed: the 13-test suite (which includes allowlist cases) passes — `Ran 13 tests in 0.128s` / `OK`, exit 0 (`docs/reviews/execution-logs/r3-python.log`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:58`, `devcontainer-config/cc-sni-proxy.py:129-142`, `docs/reviews/execution-logs/r3-python.log`

---

## Claim 9: "Exit status is the contract init-firewall.sh relies on: 0 only once the child is LISTENING; anything else means \"no proxy\""

**Location:** `devcontainer-config/cc-sni-proxy.py:237-239`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the parent returns 0 only after receiving `b"ready"`, which the child writes strictly after `start_server` has returned. Does not establish liveness beyond that instant (a proxy that dies a second later still left exit 0).
**Legibility-target:** for-orchestrator-synthesis

`daemonize` was read from signature to final line (`devcontainer-config/cc-sni-proxy.py:235-286`). The parent branch blocks on `msg = os.read(r, 4096)` and only writes the pidfile and `return 0` when `msg == b"ready"` (`:249-253`); any other message falls to `os.waitpid(pid, 0)`, a stderr line, and `return 1` (`:254-256`). The child writes `b"ready"` inside `serve`, after `server = await asyncio.start_server(...)` has completed and after the "listening on ..." log line (`:202-207`) — i.e. the socket is bound and listening. Any exception in the child, including a bind failure, is reported over the same pipe as `f"error: {e!r}"` and then `os._exit(1)` (`:280-285`), so the parent's `msg != b"ready"` path is what runs.

The caller treats it exactly as described: `if ! "$SNI_PROXY_BIN" --daemon ... ; then echo "ERROR: SNI proxy failed to start ..." >&2; exit 1; fi` (`devcontainer-config/init-firewall.sh:874-878`), and that `exit 1` reaches the EXIT trap because `FIREWALL_COMPLETE` is still 0 (`:245`, `:248`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:199-209`, `devcontainer-config/cc-sni-proxy.py:235-286`, `devcontainer-config/init-firewall.sh:874-878`

---

## Claim 10: "Close every other inherited fd: the caller's stdout is the devcontainer postStartCommand pipe, and a daemon holding it open would hang the launch."

**Location:** `devcontainer-config/cc-sni-proxy.py:264-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that fds above 2 (other than the readiness pipe) are closed in the child. Does not establish that this loop is what releases fd 1 — the `dup2` two lines earlier already did that; the loop covers the *remaining* inherited descriptors, which is what the word "other" says.
**Legibility-target:** for-orchestrator-synthesis

Read in order: `os.dup2(log_fd, 1)` and `os.dup2(log_fd, 2)` replace the child's stdout/stderr with the log file (`devcontainer-config/cc-sni-proxy.py:262-263`), so the pipe's fd 1 is released there. The loop then closes everything else: `for fd in os.listdir("/proc/self/fd"): fd = int(fd); if fd > 2 and fd != w: try: os.close(fd) except OSError: pass` (`:266-272`) — which also closes the now-redundant `log_fd` and the `null` descriptor, while preserving `w`, the readiness pipe the child still needs at `:206` and `:282`. Closing a descriptor that `listdir` itself already released raises `OSError` and is swallowed.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:257-272`, `devcontainer-config/cc-sni-proxy.py:206`, `devcontainer-config/cc-sni-proxy.py:280-285`

---

## Claim 11a: "Do NOT reach for DISABLE_TELEMETRY, DO_NOT_TRACK, or CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: each of those also disables feature-flag evaluation, which Remote Control depends on"

**Location:** `devcontainer-config/devcontainer.json:75-78`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named variables and their effect on Remote Control, and that `DISABLE_ERROR_REPORTING` is not among them. Does not establish that `DISABLE_ERROR_REPORTING` has no other side effect.
**Legibility-target:** for-orchestrator-synthesis

`https://code.claude.com/docs/en/remote-control.md` states verbatim: "**Feature-flag evaluation**: [`DISABLE_TELEMETRY`, `DO_NOT_TRACK`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, and `DISABLE_GROWTHBOOK`](/docs/en/env-vars) each disable the feature-flag evaluation that Remote Control availability depends on." The same page carries a dedicated failure-mode entry, "Remote Control requires feature-flag evaluation", naming the same set. `DISABLE_ERROR_REPORTING` appears in neither list; per `network-config.md` it governs only the `browser-intake-us5-datadoghq.com` operational-error-report host ("Optional: disable with `DISABLE_ERROR_REPORTING` or `DISABLE_TELEMETRY`"). The comment's fourth omission, `DISABLE_GROWTHBOOK`, is a documented member of the set the comment does not name — an omission, not an error.

**Evidence:** `devcontainer-config/devcontainer.json:73-80`; WebFetch of `https://code.claude.com/docs/en/remote-control.md` (lines 36, 367-369 of the fetched markdown) and `https://code.claude.com/docs/en/network-config.md`

---

## Claim 11b: "The remaining telemetry events go to api.anthropic.com, which is irreducible anyway."

**Location:** `devcontainer-config/devcontainer.json:78-79`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that `api.anthropic.com` carries telemetry event logging and is unavoidable. Does not establish that it carries *all* remaining telemetry — the documented operational-telemetry intake host is a different one.
**Legibility-target:** for-author

`network-config.md` lists `api.anthropic.com` as required for "Claude API requests, including the WebFetch domain safety check, feature flag fetches, and telemetry event logging" — so the "irreducible" half is right. But the same table also lists `http-intake.logs.us5.datadoghq.com` for "Operational telemetry events, sent only when the CLI uses the Anthropic API directly", disabled by `DISABLE_TELEMETRY`/`DO_NOT_TRACK` — neither of which is set here. Those events therefore still leave the process; they are simply firewalled (that host is not in `base.txt`, `devcontainer-config/egress/base.txt:25-31`), which is a different statement from "the remaining telemetry rides api.anthropic.com".

Precise version: "the telemetry that still leaves the process rides `api.anthropic.com`, which is irreducible; the optional Datadog intake hosts are not allowlisted, so those events are dropped at the firewall rather than disabled."

**Evidence:** `devcontainer-config/devcontainer.json:78-79`, `devcontainer-config/egress/base.txt:25-31`; WebFetch of `https://code.claude.com/docs/en/network-config.md` ("Network access requirements" table)

---

## Claim 12: "sentry.io and statsig.com were removed 2026-09 (security review, finding 7): neither appears in the documented requirements any more"

**Location:** `devcontainer-config/egress/base.txt:5-7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers absence from the current `network-config.md` requirements table and removal from `base.txt`. Does not establish that Claude Code never contacts those hosts at runtime — only that the documentation no longer requires them; the commit message already flags that as unverified live.
**Legibility-target:** for-orchestrator-synthesis

The "Network access requirements" table at `https://code.claude.com/docs/en/network-config.md` lists `api.anthropic.com`, `claude.ai`, `claude.com`, `platform.claude.com`, `mcp-proxy.anthropic.com`, `downloads.claude.ai`, `storage.googleapis.com`, `registry.npmjs.org`, `bridge.claudeusercontent.com`, `*.frame.claudeusercontent.com`, `raw.githubusercontent.com`, `http-intake.logs.us5.datadoghq.com`, `browser-intake-us5-datadoghq.com`, `formulae.brew.sh`, `code.claude.com`. Neither `sentry.io` nor `statsig.com` (nor any `*.sentry.io` / `*.statsig.com` form) appears. Error reporting is documented against `browser-intake-us5-datadoghq.com`, consistent with the comment's "Error intake is switched off with DISABLE_ERROR_REPORTING ... instead" (`devcontainer-config/egress/base.txt:8-9`). The removal itself is visible in the file: `api.anthropic.com`, `claude.ai`, `console.anthropic.com`, `platform.claude.com` are the four hosts now listed (`:25-28`).

**Evidence:** `devcontainer-config/egress/base.txt:4-10`, `devcontainer-config/egress/base.txt:25-28`; WebFetch of `https://code.claude.com/docs/en/network-config.md`

---

## Claim 13: "OAuth token exchange/refresh (platform.claude.com — per the network-config docs; a missing entry surfaces as a mid-session re-login once the access token expires)"

**Location:** `devcontainer-config/egress/base.txt:22-24`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `platform.claude.com` is documented as carrying OAuth token exchange and refresh for claude.ai accounts. Does not establish the predicted *symptom* ("mid-session re-login"), which is an inference the docs do not state.
**Legibility-target:** for-orchestrator-synthesis

`network-config.md` gives, for `platform.claude.com`: "Anthropic Console account authentication. OAuth token exchange, refresh, and revocation also go to this host for claude.ai accounts, so both Console and claude.ai sign-ins require it." That is a direct match, including the "for claude.ai accounts" qualifier the base comment relies on (this repo authenticates as a claude.ai subscription account per `docs/decisions/log.md` row 37's `--bare`/OAuth note). The host is in the file at `devcontainer-config/egress/base.txt:28`.

**Evidence:** `devcontainer-config/egress/base.txt:21-28`; WebFetch of `https://code.claude.com/docs/en/network-config.md`

---

## Claim 14: "The optional suffix is a comma-separated list of TCP ports; when absent the entry is admitted on tcp 443 only. ... init-firewall.sh rejects a line that does not parse, so a typo fails the rebuild loudly"

**Location:** `devcontainer-config/egress/base.txt:12-19`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-443 rule, the comma grammar, and hard failure on a malformed line. Does not establish that the *rebuild* fails loudly at the point of use for every malformed shape — verified via the `--print-entries` hook, which shares the parse but not the firewall path.
**Legibility-target:** for-orchestrator-synthesis

Executed (`docs/reviews/execution-logs/r3-hooks.log`): the shipped base profile prints five entries, each `<domain>\t443`, e.g. `api.anthropic.com	443`; with the `llm` profile added, `host.docker.internal	11434` and `openrouter.ai	443` appear alongside, exit 0. A synthesised profile containing `bad..entry:99999` prints `ERROR: malformed egress entry 'bad..entry:99999'` and exits 1.

The parse itself matches: `domain="${entry%%:*}"`; `if [ "$domain" = "$entry" ]; then ports="443"` (`devcontainer-config/init-firewall.sh:119-124`), the two regex guards at `:125-126`, and the 1–65535 range loop at `:127-130`. In the real (non-hook) path the same rejection runs before any network read: `parsed="$(parse_entry "$entry")" || { echo "ERROR: malformed egress entry '$entry' ..." >&2; exit 1; }` (`:285-288`).

**Evidence:** `devcontainer-config/init-firewall.sh:116-134`, `devcontainer-config/init-firewall.sh:283-290`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 15: "the `:11434` suffix is load-bearing ... this admits exactly the model server and nothing else listening on the host's Docker-facing interface ... do not drop the suffix, which would silently fall back to 443"

**Location:** `devcontainer-config/egress/llm.txt:19-24`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the port-scoping of this entry and the 443 fallback. Does not establish that only the model server listens on 11434, nor that IPv6 or UDP paths to the same host are covered — they are not (no `ip6tables` rules; the ipset holds TCP members only).
**Legibility-target:** for-orchestrator-synthesis

Executed: with the `llm` profile, `--print-entries` emits `host.docker.internal	11434` and nothing else for that host (`docs/reviews/execution-logs/r3-hooks.log`). Each parsed `(ip, port)` becomes one ipset member `"${ip},tcp:${port}"` (`devcontainer-config/init-firewall.sh:383-385`), the set is `hash:net,port` (`:731`), and the accept matches both halves: `iptables -A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT` (`:902`), with everything else hitting the terminal `REJECT` (`:905`). Dropping the suffix takes the `ports="443"` branch at `:120-121`, exactly as the comment warns. The file's entry is `host.docker.internal:11434` (`devcontainer-config/egress/llm.txt:25`).

**Evidence:** `devcontainer-config/egress/llm.txt:19-25`, `devcontainer-config/init-firewall.sh:119-124`, `devcontainer-config/init-firewall.sh:383-385`, `devcontainer-config/init-firewall.sh:902-905`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 16: "both halves are constrained to their literal grammar (hostname labels; 1-65535 integers) ... 10#: a leading zero would otherwise make bash read the number as octal. ... Tab-separated, because IFS is \n\t in this script: a space would not split under `read -r domain ports` at the consumer."

**Location:** `devcontainer-config/init-firewall.sh:105-133`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers injection-safety (both halves are digits/label characters only after the guards), the octal rationale, and the tab/IFS coupling at every consumer. Does not establish that the emitted port string is *normalised*: `good.example:0443` parses and is emitted verbatim as `0443`, so a zero-padded port reaches `ipset add` as written.
**Legibility-target:** for-orchestrator-synthesis

`parse_entry` was read in full (`devcontainer-config/init-firewall.sh:116-134`). The domain guard is `[[ "$domain" =~ ^${label}(\.${label})*$ ]] || return 1` with `label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'` (`:118`, `:125`); the port guard is `[[ "$ports" =~ ^[0-9]{1,5}(,[0-9]{1,5})*$ ]] || return 1` (`:126`), so both halves are restricted before any interpolation. The octal note is correct: `[ "$((10#$port))" -ge 1 ] && [ "$((10#$port))" -le 65535 ] || return 1` (`:129`) — without `10#`, `08`/`09` would be an arithmetic error under `set -e`.

The tab claim holds at every consumer under `IFS=$'\n\t'` (`:30`). Output is `printf '%s\t%s\n' "$domain" "$ports"` (`:133`); consumers are `while read -r domain ports` at `:348` (the resolve loop) and `:860` (the SNI allowlist writer). The comma splits inside those consumers all go through `tr`, not word-splitting, exactly as the sibling comment at `:53` says: `for port in $(echo "$ports" | tr ',' '\n')` (`:127`, `:383`), and the SNI writer uses a `case` instead: `case ",$ports," in *,443,*) echo "$domain" ;; esac` (`:862`).

Executed: `--print-entries` output is tab-separated and the malformed-entry case exits 1; `good.example:0443` parses and prints `good.example	0443` (`docs/reviews/execution-logs/r3-hooks.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:29-30`, `devcontainer-config/init-firewall.sh:116-134`, `devcontainer-config/init-firewall.sh:348`, `devcontainer-config/init-firewall.sh:383-385`, `devcontainer-config/init-firewall.sh:860-863`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 17a: "A `server=/github.com/...` line covers github.com AND every subdomain (api., codeload., ssh., pkg., ...)"

**Location:** `devcontainer-config/init-firewall.sh:149-151`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers dnsmasq's documented `server=/<domain>/` suffix semantics and that the generated config contains one such line per zone. Does not establish observed dnsmasq behaviour — the daemon is not installed in this sandbox (see Claim 18b).
**Legibility-target:** for-orchestrator-synthesis

`server=/<domain>/<ip>` is dnsmasq's documented domain-scoped upstream form, matching the named domain and all names beneath it; that is the same semantics the file relies on twice more (`devcontainer-config/init-firewall.sh:167-169`, `:646-647`). The generated config carries both zones, confirmed by execution: `server=/github.com/192.168.65.7` and `server=/githubusercontent.com/192.168.65.7` appear in the `--print-dnsmasq-conf` output (`docs/reviews/execution-logs/r3-hooks.log`), produced by the loop that appends `$GITHUB_DNS_ZONES` (`:154`, `:191`, `:205`).

**Evidence:** `devcontainer-config/init-firewall.sh:147-154`, `devcontainer-config/init-firewall.sh:191-206`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 17b: "Anything else on GitHub (ghcr.io, github.dev) is not in the CIDR ingest either, so it stays unresolved AND unroutable."

**Location:** `devcontainer-config/init-firewall.sh:152-153`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the script ingests only `.web + .api + .git` and that the meta document carries the packages/pages ranges under separate keys it does not read. Does not establish that no address serving `ghcr.io` also appears inside `.web`/`.api`/`.git` — address overlap between the meta keys was not checked, so "unroutable" is asserted, not confirmed.
**Legibility-target:** for-author

The ingest is exactly three keys: `GH_CIDRS="$(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)"` (`devcontainer-config/init-firewall.sh:332`), and the guard above it requires only those three to exist (`:326`). A WebFetch of `https://api.github.com/meta` confirms the response carries `packages`, `pages`, `actions`, `hooks`, `importer`, `github_enterprise_importer` as separate top-level keys alongside `web` (28 entries), `api` (28), `git` (40) — so the ranges GitHub publishes for the container registry are indeed under a key the script does not read. What is not established is disjointness: the meta keys are not documented as non-overlapping, and the resolved addresses were not compared. The "unresolved" half is solid (neither `ghcr.io` nor `github.dev` is under either `GITHUB_DNS_ZONES` suffix, `:154`).

Precise version: "Anything else on GitHub (ghcr.io, github.dev) is outside the `.web + .api + .git` keys this script ingests, so it stays unresolved and is not deliberately routed — though the meta keys are not guaranteed disjoint, so an incidental address overlap is not excluded."

**Evidence:** `devcontainer-config/init-firewall.sh:326`, `devcontainer-config/init-firewall.sh:332`, `devcontainer-config/init-firewall.sh:147-154`; WebFetch of `https://api.github.com/meta`

---

## Claim 18a: "there is no bare `server=` line and `no-resolv` stops dnsmasq reading /etc/resolv.conf, so the daemon has no default upstream at all. ... With NO upstream ... the config has zero server lines"

**Location:** `devcontainer-config/init-firewall.sh:161-173`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shape of the emitted config in both branches. Does not establish dnsmasq's response code for an unmatched name — Claim 18b.
**Legibility-target:** for-orchestrator-synthesis

Executed: `--print-dnsmasq-conf` emits `no-resolv`, `no-hosts`, `no-poll`, `bind-interfaces`, `listen-address=127.0.0.1`, `port=53`, `user=dnsmasq`, then exactly one `server=/<domain>/<upstream>` per allowlisted domain plus the two GitHub zones — and no bare `server=` line (`docs/reviews/execution-logs/r3-hooks.log`). The no-upstream branch is unconditional and returns before the loop: `if [ -z "$resolvers" ]; then echo '# NO UPSTREAM: ...'; return 0; fi` (`devcontainer-config/init-firewall.sh:186-189`), so zero `server=` lines can be emitted, as claimed. `compose_dnsmasq_conf` was read to its final line (`:174-208`); the only `echo "server=..."` in the function is inside the per-domain loop at `:205`.

**Evidence:** `devcontainer-config/init-firewall.sh:174-208`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 18b: "A name that matches no `server=/<domain>/` line has nowhere to go and dnsmasq answers REFUSED — it is never forwarded"

**Location:** `devcontainer-config/init-firewall.sh:163-166`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing positively about the response code. The "never forwarded" half follows from Claim 18a (no upstream exists to forward to); only the specific RCODE is unverified.
**Legibility-target:** for-orchestrator-synthesis

This is a runtime property of dnsmasq under a `no-resolv` config with no matching `server=` line. Verifying it requires running the daemon against the generated config and reading the RCODE. The daemon is not present in the review sandbox (`command -v dnsmasq` returns nothing; `apt-cache show dnsmasq-base` → `E: No packages found` — paraphrased — no quote available because the probe output is the two-word apt error already given). Blocker: execution required, dnsmasq not installed and not installable offline.

The commit message already scopes this honestly: "dnsmasq REFUSED-with-no-servers behaviour ... asserted from documentation ... verified here only at the command-sequence level. Needs a live-container check before bless" (`d598bda` body). The consequence the security argument rests on — that nothing unlisted is forwarded — does follow from 18a regardless of whether the answer is REFUSED or SERVFAIL.

**Evidence:** `devcontainer-config/init-firewall.sh:161-173`, `devcontainer-config/init-firewall.sh:186-189`, `git log bd41aef..HEAD` (`d598bda` message body)

---

## Claim 19: "Profile entries may carry a `:port` suffix ...; the resolver only wants the name. Then refuse anything that is not a plain hostname: a `/` or `#` here would be read by dnsmasq as config syntax"

**Location:** `devcontainer-config/init-firewall.sh:192-196`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that stripping precedes the hostname regex and that a non-hostname is warned about and skipped rather than emitted. Does not establish that the regex rejects every dnsmasq-meaningful character by enumeration — it is an allowlist regex, which is stronger.
**Legibility-target:** for-orchestrator-synthesis

Order is as claimed: `d="${d%%:*}"` at `devcontainer-config/init-firewall.sh:197`, the emptiness guard at `:198`, then the hostname regex at `:199`, whose failure path is `echo "WARNING: not a hostname, omitting from resolver allowlist (stays unresolvable): $d" >&2; continue` (`:200-201`). Only after both does the inner loop emit `server=/$d/$ns` (`:203-206`). Because the strip runs first, an entry like `host.docker.internal:11434` reaches the regex as `host.docker.internal` — confirmed by the `--print-dnsmasq-conf` execution, whose output contains no `:port` in any `server=` line (`docs/reviews/execution-logs/r3-hooks.log`), and by the sibling bats test `print-dnsmasq-conf strips a :port suffix from profile entries`, which passes in the 98/98 run (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:190-207`, `docs/reviews/execution-logs/r3-hooks.log`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 20: "The policy calls are VERIFIED, not trusted. ... the trap re-reads the live policies with `iptables -S` afterwards ... The \"forced DROP\" line is printed only AFTER the read-back confirms it, so the log never claims a DROP that was not applied."

**Location:** `devcontainer-config/init-firewall.sh:237-244`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read-back, the per-chain OPEN alarm, and the ordering of the two mutually exclusive messages. Does not establish that the read-back itself cannot fail silently: `policies="$(iptables -w 5 -S 2>/dev/null || true)"` yields an empty string on failure, which makes every chain look non-DROP — i.e. it fails toward the alarm, the safe direction.
**Legibility-target:** for-orchestrator-synthesis

`fail_closed_on_abort` was read signature to final line (`devcontainer-config/init-firewall.sh:246-270`). It gates on the sentinel, not `$?` (`:248`), applies the three policies with `|| true` (`:250-252`), then re-reads (`:253`) and loops all three chains: `if ! grep -q "^-P $chain DROP" <<< "$policies"; then open=1; echo "ERROR: could not force DROP policy on $chain — container may be OPEN." >&2; fi` (`:254-259`). The "Forced DROP policies (verified)" line is in the `else` of `if [ "$open" = "1" ]` (`:260-266`), so it is unreachable when any chain failed the read-back — exactly as the comment states. The recreate hint at `:267-268` prints on both paths. The trap is installed at `:271`, before any iptables work, and the signal converter at `:272` (`trap 'exit 143' INT TERM HUP QUIT`) makes the EXIT trap run on all four signals as the comment at `:228-230` claims.

Two sibling bats tests cover this and pass in the 98/98 run: `the trap waits for the xtables lock and verifies the DROP it applied` and `the trap raises a distinct OPEN alarm when the DROP policy does not take` (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:245-272`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 21: "Chain policies survive `iptables -F` (a flush removes rules, not policies), so ordering them ahead of the flush means there is no instant ... at which the chains are empty AND the policy is ACCEPT."

**Location:** `devcontainer-config/init-firewall.sh:462-471`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the source ordering (all three `-P DROP` calls precede all flush calls) and the documented netfilter semantics that `-F` does not reset a chain policy. Does not establish the kernel behaviour by execution — no privileged container is available here, which the `6244ebf` commit message itself concedes.
**Legibility-target:** for-orchestrator-synthesis

Ordering holds in the file: `iptables -P INPUT DROP` / `-P FORWARD DROP` / `-P OUTPUT DROP` at `devcontainer-config/init-firewall.sh:472-474`, then `iptables -F` / `-X` / `-t nat -F` / `-t nat -X` / `-t mangle -F` / `-t mangle -X` / `ipset destroy` at `:477-483`. `iptables -F` is documented as flushing the rules of a chain, with `-P` the separate operation that sets a policy — the two are independent, so the policy persists. The idempotent re-assert at `:797-799` is also present, matching the comment at `:793-796`.

The guarding bats test `all three DROP policies are set before the flush, so the window is empty` passes in the 98/98 run (`docs/reviews/execution-logs/r3-bats.log`), but that test drives a stub, not a kernel.

**Evidence:** `devcontainer-config/init-firewall.sh:462-483`, `devcontainer-config/init-firewall.sh:793-799`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 22: "Flush existing rules and delete existing ipsets (policies set above persist)" — i.e. a second run's `iptables -N CC_DNS_GUARD` / `-t nat -N CC_DNS` cannot fail with "chain already exists"

**Location:** `devcontainer-config/init-firewall.sh:476-483`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that all four CC_* chains are destroyed by the phase-B flush before they are recreated, so the bare (no `|| true`) `-N` calls are safe on a re-run. Does not establish idempotency against a chain created by something *other* than this script between runs — nothing else creates these names.
**Legibility-target:** for-orchestrator-synthesis

This was the load-bearing claim to check, and it holds. The four chains created later are `CC_DNS` and `CC_SNI` in `nat` (`devcontainer-config/init-firewall.sh:681`, `:882`) and `CC_DNS_GUARD` and `CC_SNI_GUARD` in `filter` (`:693`, `:892`) — all four with bare `iptables -N`, no `2>/dev/null || true`, so a "chain already exists" error would abort under `set -e` and land in the fail-closed trap.

The flush covers both tables and does so in the order that makes `-X` succeed: `iptables -F` then `iptables -X` (`:477-478`) removes the filter table's rules first — including the jumps at `:720-722` and `:896` that reference the guard chains — and only then deletes the now-unreferenced user chains; `iptables -t nat -F` then `iptables -t nat -X` (`:479-480`) does the same for `CC_DNS`/`CC_SNI` and for Docker's `DOCKER_OUTPUT`/`DOCKER_POSTROUTING`. `-X` with no chain argument deletes every user-defined chain in the table, so all four names are gone before the `-N` calls run. Docker's two chains are recreated defensively with `2>/dev/null || true` (`:488-489`) because they may or may not be present; the CC_* chains need no such tolerance precisely because the flush above is unconditional.

The `-t mangle` pair at `:481-482` and `ipset destroy allowed-domains 2>/dev/null || true` at `:483` complete the reset; the ipset destroy is after the flush, so no rule still references the set.

**Evidence:** `devcontainer-config/init-firewall.sh:476-483`, `devcontainer-config/init-firewall.sh:488-489`, `devcontainer-config/init-firewall.sh:681`, `devcontainer-config/init-firewall.sh:693`, `devcontainer-config/init-firewall.sh:882`, `devcontainer-config/init-firewall.sh:892`

---

## Claim 23: "Idempotent restart: kill by pidfile, then start exactly one instance. dnsmasq's parent only exits after the daemon has bound its socket, and exits non-zero if it could not"

**Location:** `devcontainer-config/init-firewall.sh:661-664`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the stop-then-start sequence and the post-start liveness check. Does not establish dnsmasq's own fork/exit timing, which is the daemon's documented behaviour, not this script's — but the script does not rely on it alone (see the explicit pid check below).
**Legibility-target:** for-orchestrator-synthesis

`stop_dnsmasq` (`devcontainer-config/init-firewall.sh:413-428`) is called immediately before the start (`:667-668`). It reads the pidfile through `tr -dc '0-9'`, verifies the pid is actually a dnsmasq via `[ "$(cat "/proc/$pid/comm" 2>/dev/null)" = "dnsmasq" ]` (`:417`) so a stale file cannot kill an unrelated process, escalates to `kill -9` after 3 s (`:419-423`), removes the pidfile (`:425`), and then sweeps by uid: `pkill -x -U "$DNSMASQ_UID" dnsmasq 2>/dev/null || true` (`:427`) — the second mechanism the comment at `:409-412` describes.

The script does not trust the exit status alone: after the start it polls for a non-empty pidfile (`:669-672`) and then requires a live pid — `if [ -z "$dnsmasq_pid" ] || ! kill -0 "$dnsmasq_pid" 2>/dev/null; then echo "ERROR: dnsmasq did not start ..." >&2; exit 1; fi` (`:673-677`) — which reaches the fail-closed trap. Guarding bats test `a re-run kills the previous dnsmasq by pidfile and does not double-start` passes (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:409-428`, `devcontainer-config/init-firewall.sh:661-678`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 24: "--daemon: forks, drops to --user, binds, and exits 0 only once LISTENING (a prior instance named by the pidfile is terminated first, so re-runs are idempotent)."

**Location:** `devcontainer-config/init-firewall.sh:871-872`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers idempotency via the pidfile path. Does not establish idempotency when the pidfile is missing or wrong: `stop_prior` then leaves the orphan running, the new child's bind fails, and the run fails closed (`exit 1`) rather than double-starting — safe, but a different outcome than "restarted cleanly".
**Legibility-target:** for-orchestrator-synthesis

Order in `daemonize`: the root check (`devcontainer-config/cc-sni-proxy.py:240-241`), then `stop_prior(args.pidfile)` (`:242`), then the fork (`:245`), then in the child `os.setgroups([]) / os.setgid / os.setuid` (`:274-278`) before `asyncio.run(serve(...))` binds (`:279`, `:202-203`) — so "forks, drops to --user, binds" is the actual sequence. Exit-0-only-when-listening is Claim 9.

`stop_prior` (`:212-232`) checks the pid is one of ours before signalling — `with open(f"/proc/{pid}/cmdline", "rb") as f: is_ours = b"cc-sni-proxy" in f.read()` (`:217-218`) — SIGTERMs, waits up to 3 s, then SIGKILLs via the `for/else` at `:223-228`, and unlinks the pidfile. A missing or unparseable pidfile sets `is_ours = False` (`:219-220`) and nothing is killed; in that case `asyncio.start_server` raises, the child reports over the pipe, and the parent returns 1 (`:280-285`, `:254-256`), which the caller turns into `exit 1` (`devcontainer-config/init-firewall.sh:874-878`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:212-232`, `devcontainer-config/cc-sni-proxy.py:235-286`, `devcontainer-config/init-firewall.sh:871-878`

---

## Claim 25: "The nat rules are INSERTED at position 1, ahead of the `-d 127.0.0.11 -j DOCKER_OUTPUT` jump restored above: were they appended, a node query to 127.0.0.11:53 would be DNAT'd to the embedded resolver before the redirect could claim it."

**Location:** `devcontainer-config/init-firewall.sh:637-640`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the relative ordering of the CC_DNS jumps and the restored Docker rules in `nat OUTPUT`. Does not establish the content of the restored rules — they are replayed verbatim from a capture, so their exact form depends on the live Docker install.
**Legibility-target:** for-orchestrator-synthesis

The Docker rules are captured before the flush — `DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)` (`devcontainer-config/init-firewall.sh:460`) — and replayed with `echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat` (`:490`). `iptables-save` emits `-A` rules, so the replay appends them to `nat OUTPUT`. The CC_DNS jumps come later and use explicit position-1 insertion: `iptables -t nat -I OUTPUT 1 -p tcp --dport 53 -j CC_DNS` then `-I OUTPUT 1 -p udp --dport 53 -j CC_DNS` (`:686-687`), so both land ahead of every previously appended rule (final order: udp jump, tcp jump, then the Docker rules).

By contrast the SNI jump is appended — `iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI` (`:886`) — which is consistent, since the restored Docker rules are `-d 127.0.0.11` scoped and cannot claim a 443 flow.

**Evidence:** `devcontainer-config/init-firewall.sh:459-460`, `devcontainer-config/init-firewall.sh:486-490`, `devcontainer-config/init-firewall.sh:686-687`, `devcontainer-config/init-firewall.sh:886`

---

## Claim 26a: "127.0.0.11 on ALL ports — the embedded resolver's real port is not 53 — and any port-53 flow that is not to dnsmasq at 127.0.0.1; both RETURN for dnsmasq/root." (guard jumps precede the loopback accept)

**Location:** `devcontainer-config/init-firewall.sh:717-722`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three jump rules, their all-ports/port-53 shapes, the RETURN-for-exempt-uids structure of the guard chain, and that all three precede `-o lo -j ACCEPT`. Does not establish Docker's DNAT behaviour that motivates the all-ports form — Claim 26b.
**Legibility-target:** for-orchestrator-synthesis

The three jumps are `iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD` (no proto or port match, i.e. all ports), `iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`, and the tcp twin (`devcontainer-config/init-firewall.sh:720-722`), immediately followed by `iptables -A OUTPUT -o lo -j ACCEPT` (`:723`) — so ordering is as claimed, since filter rules are evaluated in insertion order and these are appended in this sequence with nothing between them.

The guard chain itself is `-m owner --uid-owner "$DNSMASQ_UID" -j RETURN`, `-m owner --uid-owner 0 -j RETURN`, `-j REJECT --reject-with icmp-admin-prohibited` (`:693-696`) — RETURN for the two exempt uids, reject for everyone else, which is the "iptables takes one --uid-owner per rule" workaround the comment at `:623-624` describes. The bats test `the 127.0.0.11 bypass reject precedes the loopback accept` passes (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:693-696`, `devcontainer-config/init-firewall.sh:717-723`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 26b: "Docker's embedded resolver is DNAT'd off port 53 in nat OUTPUT before filter OUTPUT sees it, so a --dport 53 filter rule would not match that traffic regardless"

**Location:** `devcontainer-config/init-firewall.sh:561-563`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing positively about Docker's DNAT target port. The netfilter half — that `nat OUTPUT` is traversed before `filter OUTPUT` for locally generated packets — is standard and not in question; what is unverified is that Docker's rule rewrites the *port* (rather than only the address).
**Legibility-target:** for-orchestrator-synthesis

Confirming this needs a live Docker container: the script itself only captures whatever rules exist (`iptables-save -t nat | grep "127\.0\.0\.11"`, `devcontainer-config/init-firewall.sh:460`) without inspecting their targets, so nothing in the repository records the DNAT's shape. No Docker daemon or privileged iptables is available in the review sandbox. Blocker: execution required, needs a live container.

The commit message flags this class explicitly: "kernel semantics (xt_owner in nat OUTPUT under Docker Desktop's kernel, REDIRECT reroute of locally generated packets ...) are asserted from documentation and Docker's own DNAT precedent" (`d598bda` body). Note also that the design does not depend on this claim being right in detail: the all-ports guard at `:720` subsumes the port-53 case either way, which is exactly the argument the comment at `:632-634` makes.

**Evidence:** `devcontainer-config/init-firewall.sh:459-460`, `devcontainer-config/init-firewall.sh:626-635`, `devcontainer-config/init-firewall.sh:720`, `git log bd41aef..HEAD` (`d598bda` message body)

---

## Claim 27: "The proxy reads the ClientHello, admits the connection only if the SNI is on the allowlist written here, RESOLVES THE SNI NAME ITSELF and connects there, then splices bytes. Nothing is decrypted: peek, then splice. ... Its name lookups go through the container resolver (the filtering dnsmasq above)"

**Location:** `devcontainer-config/init-firewall.sh:819-827`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the peek/allow/resolve/splice sequence, the absence of any TLS termination, and that the proxy's own DNS is steered to dnsmasq. Does not establish the ipset half at runtime ("the proxy's own egress still traverses the address+port ipset") beyond rule ordering.
**Legibility-target:** for-orchestrator-synthesis

Peek, not decrypt: `read_client_hello` reads raw TLS records and returns both the bytes to replay and the handshake message (`devcontainer-config/cc-sni-proxy.py:102-119`); `parse_sni` walks the plaintext extension list (`:66-99`); no `ssl` module is imported (`:27-36`). The admit gate is `if not allow.allows(sni): log(...); return` (`:178-180`), before any upstream connection. Resolve-then-connect is `:182-186`, and the replay-plus-splice is `up_w.write(raw)` followed by `await asyncio.gather(pump(client_r, up_w), pump(up_r, client_w), return_exceptions=True)` (`:191-192`) — the original ClientHello bytes are forwarded verbatim, so the TLS session is end-to-end between client and origin.

The DNS-steering half holds because `CC_SNI`'s exemptions are `ccproxy` and root while `CC_DNS`'s are `dnsmasq` and root (`devcontainer-config/init-firewall.sh:883-884` vs `:682-683`): the proxy uid is *not* exempt from the DNS redirect, so its lookups hit `-j REDIRECT --to-ports 53` (`:684-685`) and land on dnsmasq. Its outbound 443 then passes `CC_SNI_GUARD` via the ccproxy RETURN (`:893`) and reaches the ipset accept (`:902`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:66-119`, `devcontainer-config/cc-sni-proxy.py:168-196`, `devcontainer-config/init-firewall.sh:682-687`, `devcontainer-config/init-firewall.sh:882-902`

---

## Claim 28: "nat OUTPUT REDIRECTs every tcp/443 connection that is not the proxy's own (and not root's) to it."

**Location:** `devcontainer-config/init-firewall.sh:817-818`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers IPv4 TCP destination port 443 from any non-exempt uid. Does not establish anything about UDP/443 (QUIC) — not redirected, though it is denied downstream because every ipset member is `tcp:<port>` — nor about IPv6, for which the script installs no rules at all and the whole allowlist is unenforced.
**Legibility-target:** for-orchestrator-synthesis

Chain construction, read in full: `iptables -t nat -N CC_SNI`; `-A CC_SNI -m owner --uid-owner "$CCPROXY_UID" -j RETURN`; `-A CC_SNI -m owner --uid-owner 0 -j RETURN`; `-A CC_SNI -p tcp -j REDIRECT --to-ports "$SNI_PORT"` (`devcontainer-config/init-firewall.sh:882-885`), entered by `iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI` (`:886`). So every uid other than `ccproxy` and 0 falls past both RETURNs onto the REDIRECT. `SNI_PORT` defaults to 3443 (`:442`) and the proxy is told to listen on exactly `127.0.0.1:$SNI_PORT` (`:875`).

The UDP residue is closed elsewhere rather than by this rule: members are added as `"${ip},tcp:${port}"` (`:384`) and `"$cidr,tcp:443"` / `"$cidr,tcp:22"` (`:744-745`), so a UDP/443 datagram misses the `dst,dst` accept (`:902`) and hits the terminal REJECT (`:905`). The IPv6 gap is acknowledged in the file's own comments at `:510-512` and `:653-654`.

**Evidence:** `devcontainer-config/init-firewall.sh:442`, `devcontainer-config/init-firewall.sh:744-745`, `devcontainer-config/init-firewall.sh:882-886`, `devcontainer-config/init-firewall.sh:902-905`

---

## Claim 29: "Negative: an address that IS in the ipset, asked for with a name that is NOT allowlisted, must be refused" (probe run as node via `runuser`)

**Location:** `devcontainer-config/init-firewall.sh:934-938`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that `ANTHROPIC_PROBE_IP` is always non-empty on every path that reaches the probe, that `runuser` exists on the base distribution, and that the probe runs as a redirect-subject uid. Does not establish that the probe *fails* for the intended reason under a live kernel — a container without the redirect would also produce a failing curl and thus a passing check.
**Legibility-target:** for-orchestrator-synthesis

Non-emptiness: `ANTHROPIC_PROBE_IP=""` is initialised at `devcontainer-config/init-firewall.sh:347`, so `set -u` is satisfied; it is assigned from the first A record of `api.anthropic.com` (`:380-382`), and that domain is unconditionally in the always-applied base profile (`devcontainer-config/egress/base.txt:25`; executed: `api.anthropic.com	443` is the first line of `--print-entries` for base alone, `docs/reviews/execution-logs/r3-hooks.log`). If it fails to resolve the script exits before ever reaching the probe: `if [ "$domain" = "api.anthropic.com" ]; then echo "ERROR: Failed to resolve critical domain $domain" >&2; exit 1; fi` (`:364-367`). Multiple A records are handled by the `[ -z "${ANTHROPIC_PROBE_IP:-}" ]` first-wins guard (`:380`).

`runuser` is present on the `node:22` base: the review sandbox is the same Debian 12 bookworm and has `/usr/sbin/runuser` (`command -v runuser` → `/usr/sbin/runuser`, exit 0 — paraphrased — no quote available because this probe was an ad-hoc command not written to a log file). The script runs as root, so `/usr/sbin` is on PATH.

Traversal: `node` is neither `ccproxy` nor uid 0, so `runuser -u node -- curl ... --resolve "not-allowlisted.invalid:443:$ANTHROPIC_PROBE_IP"` (`:937-938`) falls through both `CC_SNI` RETURNs onto the REDIRECT (`:883-885`).

**Evidence:** `devcontainer-config/init-firewall.sh:346-347`, `devcontainer-config/init-firewall.sh:364-367`, `devcontainer-config/init-firewall.sh:378-382`, `devcontainer-config/init-firewall.sh:926-943`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 30: "There is no inbound counterpart: replies are ESTABLISHED,RELATED, which the INPUT accept below admits, and nothing on the bridge needs to OPEN a connection into the sandbox."

**Location:** `devcontainer-config/init-firewall.sh:775-777`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no INPUT rule references the bridge network or the gateway address. Does not establish the second half's design assertion ("nothing on the bridge needs to open a connection"), which is intent, not a checkable property.
**Legibility-target:** for-orchestrator-synthesis

The whole script contains exactly two `-A INPUT` rules: `iptables -A INPUT -i lo -j ACCEPT` (`devcontainer-config/init-firewall.sh:716`) and `iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT` (`:802`). Neither mentions `$HOST_IP` or a `/24`; the only other occurrences of `-A INPUT` in the file are inside comments describing the deleted upstream rules (`:700`, `:765`). The gateway rules are OUTPUT-only and owner-scoped: `iptables -A OUTPUT -p udp -d "$HOST_IP" --dport 53 -m owner --uid-owner "$uid" -j ACCEPT` and its tcp twin, over `for uid in "$DNSMASQ_UID" 0` (`:788-791`). The INPUT policy is DROP (`:472`, `:797`). Guarding bats test `the bridge gateway is admitted on udp/tcp 53 only, with no inbound counterpart` passes (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:716`, `devcontainer-config/init-firewall.sh:788-791`, `devcontainer-config/init-firewall.sh:797-802`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 31: "NOTE: no inbound `--sport 53` accept. DNS replies to the scoped OUTPUT rules above are already admitted by the `INPUT -m state --state ESTABLISHED,RELATED` accept near the end"

**Location:** `devcontainer-config/init-firewall.sh:698-703`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of any `--sport` rule and the presence of the ESTABLISHED,RELATED INPUT accept. Does not establish that conntrack actually associates every DNS reply with its request under a live kernel.
**Legibility-target:** for-orchestrator-synthesis

`--sport` appears nowhere in the script except inside this comment and one historical reference (`devcontainer-config/init-firewall.sh:698`, `:700` — the grep for `sport` returns only those two comment lines plus the `-A INPUT` comment matches). The referenced accept exists at `:802`: `iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT`. Executed: the bats test `no blanket inbound source-port-53 accept is installed` passes in the 98/98 run (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:698-703`, `devcontainer-config/init-firewall.sh:802`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 32: "Guarded by 7 new bats tests." (decision log row 39, port-scoping)

**Location:** `docs/decisions/log.md:57` (row 39)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of `@test` blocks added by the commit that implements row 39 (`f1443c5`). Does not establish that those seven tests exercise the kernel — they drive an iptables stub, which the commit message says.
**Legibility-target:** for-orchestrator-synthesis

Executed: `git show f1443c5 -- test/init-firewall-rules.bats | grep -c '^+@test'` returns `7` (paraphrased — no quote available because this count was an ad-hoc pipeline; the underlying test names are in the diff). The seven are the ipset address+port test, the GitHub 443/22 test, the port-less default, the port-suffix case, the `llm` profile scoping, the malformed-entry abort, and the bridge-gateway rule. All pass in the full run: 98 `ok` lines, 0 `not ok`, exit 0 (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `docs/decisions/log.md:57`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 33: "verified by 10 new command-sequence bats tests" (decision log row 40, filtering resolver)

**Location:** `docs/decisions/log.md:62` (row 40)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count added by `d598bda`. Does not establish live-kernel behaviour, which the row itself disclaims ("Not runnable here (no Docker/iptables in the sandbox)").
**Legibility-target:** for-orchestrator-synthesis

Executed: `git show d598bda -- test/init-firewall-rules.bats | grep -c '^+@test'` returns `10` (paraphrased — no quote available because this count was an ad-hoc pipeline). They are the four `print-dnsmasq-conf` shape tests, hook purity, the full-run start test, owner-scoped upstream 53, guard-before-lo ordering, re-run idempotency, and the missing-user pre-flush abort. All pass (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `docs/decisions/log.md:62`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 34: "Guarded by 10 bats tests + 13 Python unit tests (parser, allowlist, loopback splice)." (decision log row 41, SNI proxy)

**Location:** `docs/decisions/log.md:61` (row 41)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both counts as of `abbd42d`. Does not establish coverage adequacy, which is a test-strategy question, not a fact-check one.
**Legibility-target:** for-orchestrator-synthesis

Executed: `git show aa8dffc -- test/init-firewall-rules.bats | grep -c '^+@test'` → `10`; `git show aa8dffc -- test/test_cc_sni_proxy.py | grep -c '^+    def test_'` → `13` (paraphrased — no quote available because these counts were ad-hoc pipelines). The Python suite runs green: `Ran 13 tests in 0.128s` / `OK`, exit 0 (`docs/reviews/execution-logs/r3-python.log`); the ten bats tests are inside the passing 98 (`docs/reviews/execution-logs/r3-bats.log`).

**Evidence:** `docs/decisions/log.md:61`, `docs/reviews/execution-logs/r3-python.log`, `docs/reviews/execution-logs/r3-bats.log`

---

## Claim 35: "egress profile lines gain an optional suffix, `domain[:port[,port...]]` (TCP only, default 443, validated — a malformed line aborts pre-flush and fails closed) ... replaced by `OUTPUT -d <gateway> --dport 53` (udp+tcp) with no inbound counterpart"

**Location:** `docs/decisions/log.md:57` (row 39)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grammar, the TCP-only restriction, the default, the pre-flush abort, and the OUTPUT-only gateway rules. Does not establish "fails closed" at the kernel level for the abort path — that depends on the trap's `-P DROP` taking effect (Claim 20/21).
**Legibility-target:** for-orchestrator-synthesis

TCP-only: every ipset member is written with a `tcp:` prefix (`devcontainer-config/init-firewall.sh:384`, `:744-745`), and the grammar comment states the same restriction (`:113-115`). Default 443 and validation: Claim 14, executed. Pre-flush: the parse loop is at `:283-290`, well above the flush at `:477` and above phase A's first network read at `:320`. Gateway rules: `for uid in "$DNSMASQ_UID" 0` over one udp and one tcp OUTPUT accept, no INPUT counterpart (`:788-791`; Claim 30).

**Evidence:** `docs/decisions/log.md:57`, `devcontainer-config/init-firewall.sh:283-290`, `devcontainer-config/init-firewall.sh:384`, `devcontainer-config/init-firewall.sh:744-745`, `devcontainer-config/init-firewall.sh:788-791`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 36a: "the proxy logs every decision to `/run/cc-sni-proxy/proxy.log` as `ALLOW`, `REJECT sni=... not in allowlist`, or `FAIL`"

**Location:** `guides/cc-isolated-usage.md:299-301`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path and the three verbs. Does not establish that the three cases are exhaustive: a ClientHello that cannot be parsed at all logs a fourth shape, `REJECT orig_dst=<...>: <error>`, with no `sni=` field.
**Legibility-target:** for-orchestrator-synthesis

Path: `SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"` and `SNI_LOG="$SNI_RUN_DIR/proxy.log"` (`devcontainer-config/init-firewall.sh:438`, `:441`), passed as `--log "$SNI_LOG"` (`:875`); the proxy's own default matches (`devcontainer-config/cc-sni-proxy.py:296`). The child redirects both stdout and stderr into it (`:262-263`) and `log()` writes to stdout with `flush=True` (`:153-154`).

The verbs match the four `log()` calls in `handle()`: `f"REJECT orig_dst={orig}: {e}"` (`:176`), `f"REJECT sni={sni} orig_dst={orig}: not in allowlist"` (`:179`), `f"FAIL sni={sni} orig_dst={orig}: {e} (resolved address not in the ipset?)"` (`:188`), and `f"ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}"` (`:190`). The guide's elided rendering of the REJECT line is a faithful abbreviation of `:179`.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:153-154`, `devcontainer-config/cc-sni-proxy.py:176-190`, `devcontainer-config/cc-sni-proxy.py:262-263`, `devcontainer-config/init-firewall.sh:438-441`, `devcontainer-config/init-firewall.sh:875`

---

## Claim 36b: "`FAIL` (the name resolved to an address the ipset does not admit)"

**Location:** `guides/cc-isolated-usage.md:301`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the case the gloss names, which is one of the causes. Does not establish that it is the only one: the same branch also fires when the name does not resolve at all (dnsmasq REFUSED) and when the upstream connect times out.
**Legibility-target:** for-author

The `FAIL` line is emitted from a single `except` covering both the resolution and the connection: `except (OSError, asyncio.TimeoutError) as e:` around `getaddrinfo(...)` and `await asyncio.wait_for(asyncio.open_connection(ip, upstream_port), CONNECT_TIMEOUT)` (`devcontainer-config/cc-sni-proxy.py:181-189`). A DNS failure — the common case for a name allowlisted for 443 but absent from the dnsmasq config — raises `socket.gaierror`, a subclass of `OSError`, and lands here too. The proxy's own log text hedges correctly ("(resolved address not in the ipset?)", `:188`); the guide's parenthetical drops the hedge.

Precise version: "`FAIL` (the name could not be resolved, or the address it resolved to could not be connected to — typically because the ipset does not admit it)."

**Evidence:** `devcontainer-config/cc-sni-proxy.py:181-189`, `guides/cc-isolated-usage.md:299-304`

---

## Claim 37: "Root inside the container. The firewall script's own fetch and probes run as root and bypass the redirect; the agent runs as `node` and does not."

**Location:** `guides/cc-isolated-usage.md:296-297`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the root exemption and that the agent (`node`) is subject to the redirect. Does not hold for "probes" without qualification: two of the four end-of-script probes are deliberately run as `node`, precisely so they *do* traverse the redirect.
**Legibility-target:** for-author

The root-exempt probes are the two general ones: `curl --connect-timeout 5 --max-time 15 https://example.com` (`devcontainer-config/init-firewall.sh:911`) and `curl ... https://api.github.com/zen` (`:919`). But the two SNI probes are explicitly not root — the comment above them says so: "SNI proxy probes, run AS NODE so they traverse the redirect (root is exempt)" (`:926`), implemented as `runuser -u node -- curl ...` at `:928` and `:937-938`. So the guide's blanket "probes run as root" is wrong for exactly the probes the SNI section is about.

Precise version: "Root inside the container. The firewall script's own fetch and its two general reachability probes run as root and bypass the redirect; its two SNI probes are run as `node` on purpose so they don't. The agent runs as `node` and is always subject to the redirect."

**Evidence:** `guides/cc-isolated-usage.md:294-297`, `devcontainer-config/init-firewall.sh:909-919`, `devcontainer-config/init-firewall.sh:926-943`

---

## Claim 38: "98/98 bats + 13/13 python unit tests; shellcheck clean."

**Location:** commit `aa8dffc` message body (`Notes:` line)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two suites named in the review brief and `shellcheck -S warning` on `init-firewall.sh` at `abbd42d`. Does not establish that a wider shellcheck sweep or the repo's other bats files are clean — only the named targets were run.
**Legibility-target:** for-orchestrator-synthesis

- `LC_ALL=C bats test/init-firewall-rules.bats test/cc-isolated-functions.bats`, cwd `/workspace`, 2026-09-03T15:46 — 98 `ok`, 0 `not ok`, `exit: 0` (`docs/reviews/execution-logs/r3-bats.log`).
- `LC_ALL=C python3 test/test_cc_sni_proxy.py`, cwd `/workspace` — `Ran 13 tests in 0.128s` / `OK`, `exit: 0` (`docs/reviews/execution-logs/r3-python.log`).
- `shellcheck -S warning devcontainer-config/init-firewall.sh`, cwd `/workspace` — no output, `exit: 0` (`docs/reviews/execution-logs/r3-shellcheck.log`).

**Evidence:** `docs/reviews/execution-logs/r3-bats.log`, `docs/reviews/execution-logs/r3-python.log`, `docs/reviews/execution-logs/r3-shellcheck.log`

---

## Claim 39: "docs/decisions/log.md: row 39 records the decision and the REDIRECT-vs-resolv.conf choice."

**Location:** commit `d598bda` message body
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row number only. Does not dispute that the row exists or that it records the REDIRECT-vs-resolv.conf choice — it does, verbatim, under a different number.
**Legibility-target:** for-author

`d598bda` was authored in a worktree that did not yet see `f1443c5`, and both added a row numbered 39: `git show d598bda -- docs/decisions/log.md | grep -o '^+| [0-9]* |'` → `+| 39 |`, and the same for `f1443c5` (paraphrased — no quote available because these were ad-hoc pipelines). The merge renumbered the resolver row: at `abbd42d` the filtering-resolver entry is `| 40 | 2026-09-03 | **Close recursive-forward DNS tunnelling (egress review finding 6) with a filtering resolver in the container**` (`docs/decisions/log.md:62`), while row 39 is the port-scoping decision (`docs/decisions/log.md:57`).

Per this project's own tiering rule (`docs/decisions/log.md` row 32, item T: "immutable already-merged commit-message claims → override log not 🔴"), this is an override-log item, not a blocking finding. The reader-facing artefact — the log row itself — is correct; only the pointer in an unamendable commit message is off by one.

**Evidence:** `docs/decisions/log.md:57`, `docs/decisions/log.md:62`, `git log bd41aef..HEAD` (`d598bda` message body)

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- **Claim 4** (`devcontainer-config/cc-sni-proxy.py:20-21`): the docstring still says resolution goes to "Docker's embedded DNS today, a filtering dnsmasq once that lands". The filtering dnsmasq landed in `d598bda`, earlier in this same range, and the proxy's port-53 traffic is REDIRECTed to it by the kernel regardless of `/etc/resolv.conf`.
- **Claim 39** (`d598bda` commit message): points at "row 39" for the filtering-resolver decision; the merge renumbered it to row 40. Override-log item under row 32's tiering rule, not a blocking finding.

### Mostly Accurate
- **Claim 11b** (`devcontainer-config/devcontainer.json:78-79`): "the remaining telemetry events go to api.anthropic.com" — documented operational telemetry also targets `http-intake.logs.us5.datadoghq.com`, which is not disabled here, only firewalled.
- **Claim 17b** (`devcontainer-config/init-firewall.sh:152-153`): "ghcr.io, github.dev ... stays unresolved AND unroutable" — the `packages` key really is outside the `.web + .api + .git` ingest, but the meta keys are not documented as disjoint, so the "unroutable" half is asserted rather than confirmed.
- **Claim 36b** (`guides/cc-isolated-usage.md:301`): the `FAIL` gloss names only the ipset cause; the same branch also fires on a DNS failure (the likelier case) and on a connect timeout.
- **Claim 37** (`guides/cc-isolated-usage.md:296-297`): "The firewall script's own fetch and probes run as root" — the two SNI probes are deliberately run as `node` via `runuser` (`init-firewall.sh:926-943`), which is the whole point of that section.

### Unverifiable
- **Claim 1** (`devcontainer-config/Dockerfile:44-46`): the `dnsmasq-base` vs `dnsmasq` package split. Blocker: no apt lists in the sandbox and `packages.debian.org` unreachable via WebFetch.
- **Claim 18b** (`devcontainer-config/init-firewall.sh:163-166`): dnsmasq answering REFUSED for a name with no matching `server=` line. Blocker: execution required; dnsmasq is not installed and cannot be installed offline.
- **Claim 26b** (`devcontainer-config/init-firewall.sh:561-563`): Docker's embedded resolver being DNAT'd *off port 53*. Blocker: execution required; no Docker daemon or privileged iptables in the sandbox.

---

## Goal-Alignment Note
- Answered: yes — all `devcontainer-config/` claims in `bd41aef..HEAD`, plus the log rows, guide section, and commit-message claims the brief named, were checked; the mandatory executions all ran green.
- Out of scope: `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py`, `docs/working/questions.md` were read as sibling context only, per the brief. Code-quality observations noticed while tracing (e.g. `parse_entry` emitting a zero-padded port verbatim to `ipset add`; `Allowlist.load` mapping a bare `.` line to an empty zone) are recorded in the relevant `Scope:` fields rather than raised as findings — they belong to the sibling critics.
- Escalate: three claims (1, 18b, 26b) are gated on a live privileged container and reduce to the same live-check item the `d598bda` and `aa8dffc` commit messages already list as a pre-`--bless` requirement — the orchestrator should carry that forward rather than treat it as closed. Separately, `network-config.md` documents several required hosts absent from `base.txt` (`claude.com`, `downloads.claude.ai`, `mcp-proxy.anthropic.com`, `raw.githubusercontent.com`, `storage.googleapis.com`); that is an allowlist-completeness question, not a documentation-accuracy one, so it is noted here rather than verdicted.
