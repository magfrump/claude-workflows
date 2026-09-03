# Code Fact-Check Report

Commit: abbd42d
**Repository:** /workspace (magfrump claude-workflows)
**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` — `init-firewall.sh`, `cc-sni-proxy.py`, `Dockerfile`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`; plus claims in the range's commit messages, `docs/decisions/log.md` rows 39–41 and `guides/cc-isolated-usage.md` that reference this code.
**Checked:** 2026-09-03
**Total claims checked:** 32
**Summary:** 21 verified, 4 mostly accurate, 3 stale, 4 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read before checking. Its two logged patterns are both "a specific measured value quoted from a checked-in artifact set that does not contain it". Claims 27–30 (bats/python test counts quoted in decision-log rows and commit messages) are the same shape and were therefore executed rather than read; all four counts hold.

Execution logs: `docs/reviews/execution-logs/r1-bats.log`, `r1-python.log`, `r1-shellcheck.log`, `r1-print-hooks.log`, `r1-env-probe.log`.

---

## Claim 1: "dnsmasq-base (above) is the daemon binary WITHOUT the `dnsmasq` package's sysv/systemd service wrapper: nothing in the container may auto-start a resolver"

**Location:** `devcontainer-config/Dockerfile:44-45`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the Debian packaging split (`dnsmasq-base` ships `/usr/sbin/dnsmasq` only; the `dnsmasq` package adds the init/systemd unit) and that the Dockerfile installs only `dnsmasq-base`. Does not establish that no *other* installed package auto-starts a resolver, and does not establish that the binary is present in the currently-running image (it is not — see Evidence; the image has not been rebuilt since this change).
**Legibility-target:** for-orchestrator-synthesis

The apt line installs `dnsmasq-base` and not `dnsmasq` (`devcontainer-config/Dockerfile:34`, in a list whose other entries are `iptables`, `ipset`, `dnsutils`, …; excerpt is one line of a `RUN apt-get install` block that continues to `:42` — read). On Debian bookworm the `dnsmasq` binary package is a wrapper that contains `/etc/init.d/dnsmasq` and the systemd unit and depends on `dnsmasq-base`, which carries the daemon binary; this is the split the comment describes. Nothing in the container starts a resolver except `init-firewall.sh`, which runs exactly one `dnsmasq --conf-file=… --pid-file=…` after `stop_dnsmasq` (`devcontainer-config/init-firewall.sh:667-668`).

Confidence is Medium rather than High because the packaging split is asserted from Debian package metadata knowledge, not verified against a package index: the review sandbox is a pre-rebuild container and has no `dnsmasq` binary at all (`docs/reviews/execution-logs/r1-env-probe.log`, `-- dnsmasq: dnsmasq absent`).

**Evidence:** `devcontainer-config/Dockerfile:34`, `devcontainer-config/init-firewall.sh:667-668`, `docs/reviews/execution-logs/r1-env-probe.log`

---

## Claim 2: "(decision log #39: the filtering resolver that closes recursive-forward DNS tunnelling)"

**Location:** `devcontainer-config/Dockerfile:47-48`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row-number pointer only. Does not establish anything about the resolver's behaviour, which is described correctly.
**Legibility-target:** for-author

The filtering resolver is decision-log row **40**, not 39. Row 39 is the port-scoping change: "`| 39 | 2026-09-03 | **Port-scope the cc-isolated egress allowlist and narrow the host-network accept.**`" (`docs/decisions/log.md:57`). The resolver row reads "`| 40 | 2026-09-03 | **Close recursive-forward DNS tunnelling (egress review finding 6) with a filtering resolver in the container**`" (`docs/decisions/log.md:62`).

This is renumbering drift from the parallel-worktree merge, not a fabrication: the resolver branch (`d598bda`) genuinely added its row as 39 in its own worktree (`git show d598bda:docs/decisions/log.md` contains exactly one `^| 39 ` row), and the port-scoping branch had independently claimed 39. Precise version: `decision log #40`.

**Evidence:** `docs/decisions/log.md:57`, `docs/decisions/log.md:62`, `git show d598bda:docs/decisions/log.md | grep -c '^| 39 '` → 1

---

## Claim 3: "root-owned and 0555 like the firewall script it belongs to (decision log #41)"

**Location:** `devcontainer-config/Dockerfile:387-388`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `cc-sni-proxy.py` is chowned root:root and chmodded 0555. Does not establish that `init-firewall.sh` has the same mode — it does not.
**Legibility-target:** for-author

The proxy is indeed root-owned 0555: `chown root:root /usr/local/bin/cc-sni-proxy.py && chmod 0555 /usr/local/bin/cc-sni-proxy.py` (`devcontainer-config/Dockerfile:410`; excerpt is one continuation line of a `RUN` that begins at `:409` and continues past `:412` — read). But `init-firewall.sh` is not 0555: the same `RUN` sets it with `chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/link-claude-home.sh` (`devcontainer-config/Dockerfile:409`), i.e. `+x` on whatever mode the `COPY` produced (0644 → 0755), and it is never chowned in this `RUN`. Precise version: "root-owned and 0555 — stricter than the firewall script, which is `chmod +x`".

**Evidence:** `devcontainer-config/Dockerfile:409-410`

---

## Claim 4: "the proxy … RESOLVES THE SNI NAME ITSELF and connects to that address on 443 … Step 3 is why a forged SNI cannot steer a connection: the original destination (SO_ORIGINAL_DST) is read for the log line only and is never connected to."

**Location:** `devcontainer-config/cc-sni-proxy.py:11-15`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the upstream address is derived solely from the parsed SNI and that `original_dst()`'s return value flows only into log strings. Does not establish that the resolver answering that lookup is the filtering dnsmasq (glibc consults `/etc/hosts` first via nsswitch, and `handle()` uses the loop's default `getaddrinfo`), and does not establish anything about the port — the connect port is `args.upstream_port` (default 443), never the original destination port.
**Legibility-target:** for-orchestrator-synthesis

`handle()` (`cc-sni-proxy.py:168-196`, read signature-to-`finally`) computes `orig = original_dst(client_w.get_extra_info("socket"))` at `:169` and thereafter uses `orig` in exactly four f-strings, all arguments to `log()`: `:176`, `:179`, `:188`, `:190`. The upstream address comes only from the SNI:

```
infos = await asyncio.get_running_loop().getaddrinfo(
    sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)
ip = infos[0][4][0]
up_r, up_w = await asyncio.wait_for(
    asyncio.open_connection(ip, upstream_port), CONNECT_TIMEOUT)
```
(`cc-sni-proxy.py:182-186`)

`sni` is `parse_sni(hs)` (`:174`) applied to the ClientHello handshake message, normalised through `normalise_name` (`:55-63`), which lower-cases, strips a trailing dot, and rejects anything that is not a ≤253-char sequence of RFC-1123 labels. The buffered ClientHello bytes `raw` are replayed to the *upstream* socket (`up_w.write(raw)`, `:191`), never to `orig`. `original_dst()` itself (`:145-150`) only reads `SO_ORIGINAL_DST` and returns a display string, falling back to `"unknown"`. There is no other reference to `orig` in the file.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:145-150`, `:168-196`, `:55-63`

---

## Claim 5a: "python3.11 ships in the node:22 base — no apt package, no pip"

**Location:** `devcontainer-config/cc-sni-proxy.py:24-25`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a `python3` at 3.11.x exists in the image without any Dockerfile-added Python package. Does not establish that the interpreter is at `/usr/bin/python3` specifically, nor that `#!/usr/bin/env python3` (`cc-sni-proxy.py:1`) resolves to it under the root PATH the firewall script runs with.
**Legibility-target:** for-orchestrator-synthesis

The Dockerfile's base is `FROM node:22` (`devcontainer-config/Dockerfile:11`), which is Debian 12 bookworm; bookworm's `python3` is 3.11. The apt block (`:29-42`) installs no Python package. Executed in the running container: `Python 3.11.2`, `PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"` (`docs/reviews/execution-logs/r1-env-probe.log`, `LC_ALL=C python3 -V`, cwd `/workspace`, exit 0, ts 2026-09-03T15:48:33-07:00). The 13 Python unit tests also ran under that interpreter and passed (`docs/reviews/execution-logs/r1-python.log`).

**Evidence:** `devcontainer-config/Dockerfile:11`, `devcontainer-config/Dockerfile:29-42`, `docs/reviews/execution-logs/r1-env-probe.log`, `docs/reviews/execution-logs/r1-python.log`

---

## Claim 5b: "root-owned in the image and hashed by the launcher's trust manifest"

**Location:** `devcontainer-config/cc-sni-proxy.py:25`
**Type:** Invariant / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the manifest half only — the root-owned half is true (`Dockerfile:410`). Does not establish anything about the image's file permissions, which are correct.
**Legibility-target:** for-author

`cc-sni-proxy.py` is **not** in the launcher's trust manifest. `enforcement_files()` enumerates exactly four fixed names plus two globs:

```
echo "devcontainer.json"
echo "Dockerfile"
echo "init-firewall.sh"
echo "cc-isolated.sh"
…
for f in egress/*.txt; do [ -e "$f" ] && echo "$f"; done | sort
for f in projects/*.profile; do [ -e "$f" ] && echo "$f"; done | sort
```
(`devcontainer-config/cc-isolated.sh:52-64`; excerpt ends at the subshell's `sort`, enclosing `enforcement_files()` continues to `:65` — read.) `compute_manifest()` sha256sums only what that function emits (`cc-isolated.sh:67-78`), and `check_manifest()` compares that against `manifest.sha256` (`:88-103`). `cc-isolated.sh` was not touched in this commit range (`git log bd41aef..HEAD -- devcontainer-config/cc-isolated.sh` is empty), and a repo-wide grep for `cc-sni-proxy` finds no hit in it.

Practical consequence: the proxy binary is baked into the image by `COPY` (`Dockerfile:389`) and so is covered transitively by the *Dockerfile*'s hash only insofar as the Dockerfile text is hashed — the proxy's own contents are not. A host-side rewrite of `devcontainer-config/cc-sni-proxy.py` would not change any hashed file and would not trip `check_manifest()`'s refusal at the next launch.

Not logged to `hallucination-patterns.md`: no fabricated symbol — the manifest mechanism exists, the file is simply absent from its list.

**Evidence:** `devcontainer-config/cc-isolated.sh:49-65`, `:67-78`, `:88-103`, `devcontainer-config/Dockerfile:389`, `devcontainer-config/Dockerfile:410`

---

## Claim 6: "Resolution … is IPv4-only, matching the IPv4-only ipset. Non-443 ports are not redirected here and stay IP+port-matched."

**Location:** `devcontainer-config/cc-sni-proxy.py:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the proxy's own upstream lookup is `AF_INET` and that only tcp/443 is redirected to it. Does not establish that IPv6 egress is blocked anywhere — it is not; `init-firewall.sh` installs no ip6tables rules at all, which the script itself states (`init-firewall.sh:510-512`).
**Legibility-target:** for-orchestrator-synthesis

`getaddrinfo(sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)` (`cc-sni-proxy.py:182-183`) pins the lookup to IPv4. The ipset is created as `ipset create allowed-domains hash:net,port` (`init-firewall.sh:731`) and populated only from dotted-quad-validated members (`init-firewall.sh:373-376`, `:335-338`), so it is IPv4-only. The redirect is scoped to 443: `iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI` (`init-firewall.sh:886`), with `CC_SNI`'s terminal rule `-p tcp -j REDIRECT --to-ports "$SNI_PORT"` (`:885`).

Worth recording for the orchestrator, though not contradicting the comment: **udp/443 (QUIC) is not redirected and not guarded** — `CC_SNI_GUARD` is jumped to only from `-p tcp --dport 443` (`init-firewall.sh:896`). QUIC to an allowlisted address is nevertheless rejected, because every ipset member is written `<ip>,tcp:<port>` (`init-firewall.sh:384`, `:744-745`) so a udp/443 packet misses `--match-set allowed-domains dst,dst` (`:902`) and falls to the terminal `-j REJECT` (`:905`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:182-183`, `devcontainer-config/init-firewall.sh:731`, `:373-376`, `:384`, `:885-886`, `:896`, `:902-905`, `:510-512`

---

## Claim 7: "`name` lines match exactly; `.zone` lines match the zone and every subdomain of it. Blank lines and #-comments are ignored."

**Location:** `devcontainer-config/cc-sni-proxy.py:123-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exact-match, zone-match-including-apex, comment stripping, blank-line skipping, and case-insensitivity. Does not establish that a `.zone` entry is distinguishable from an exact entry after loading in any other way, and does not establish behaviour for an entry with multiple leading dots (`..foo`), which `lstrip(".")` silently normalises to `foo` as a zone.
**Legibility-target:** for-orchestrator-synthesis

`Allowlist.load` (`cc-sni-proxy.py:129-138`, read through its `return`) strips at the first `#`, `.strip()`s, `.lower()`s, skips empties, and routes on a leading dot:

```
line = line.split("#", 1)[0].strip().lower()
if not line:
    continue
(al.zones if line.startswith(".") else al.exact).add(line.lstrip("."))
```
(`cc-sni-proxy.py:134-137`)

`allows` (`:140-142`) is `name in self.exact or any(name == z or name.endswith("." + z) for z in self.zones)` — so a zone matches its own apex and any suffix-separated subdomain, and an exact entry matches nothing but itself. Inputs reaching `allows` are already lower-cased by `normalise_name` (`:58`), so the load-time `.lower()` makes matching case-insensitive on both sides. The 13-test Python suite covering the parser and allowlist passes (`docs/reviews/execution-logs/r1-python.log`, `LC_ALL=C python3 test/test_cc_sni_proxy.py`, cwd `/workspace`, exit 0, ts 2026-09-03T15:45:22-07:00).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:129-142`, `:58`, `docs/reviews/execution-logs/r1-python.log`

---

## Claim 8: "Exit status is the contract init-firewall.sh relies on: 0 only once the child is LISTENING; anything else means 'no proxy'"

**Location:** `devcontainer-config/cc-sni-proxy.py:237-239`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `daemonize()` returns 0 on exactly one path, and that that path is gated on a readiness byte written after `asyncio.start_server` has returned. Does not establish that the listening socket is reachable *through the redirect* (that needs a live kernel), nor that a child that dies immediately after signalling ready is detected.
**Legibility-target:** for-orchestrator-synthesis

`daemonize()` (`cc-sni-proxy.py:235-286`, read to `os._exit(0)`) has exactly one `return 0`, inside the parent branch and guarded by the pipe read:

```
msg = os.read(r, 4096)
if msg == b"ready":
    with open(args.pidfile, "w") as f:
        f.write(f"{pid}\n")
    return 0
os.waitpid(pid, 0)
sys.stderr.write(…)
return 1
```
(`cc-sni-proxy.py:249-256`)

`b"ready"` is written only in `serve()` **after** `await asyncio.start_server(...)` has returned, i.e. after the socket is bound and listening: `server = await asyncio.start_server(...)` (`:202-203`), then `os.write(ready_fd, b"ready")` (`:206`). Any exception in the child — including `pwd.getpwnam` failure or a bind error — is caught by `except BaseException` and written to the pipe as `error: …` (`:280-285`), which the parent's `msg == b"ready"` test rejects. `main()` returns `daemonize(args)` and `sys.exit(main())` propagates it (`:302`, `:308`). The consumer honours the contract: the call is in an `if ! … ; then echo ERROR…; exit 1; fi` (`init-firewall.sh:874-878`), and `exit 1` reaches the fail-closed EXIT trap.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:235-286`, `:199-209`, `:302`, `:308`, `devcontainer-config/init-firewall.sh:874-878`

---

## Claim 9: "Close every other inherited fd: the caller's stdout is the devcontainer postStartCommand pipe, and a daemon holding it open would hang the launch."

**Location:** `devcontainer-config/cc-sni-proxy.py:264-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every fd above 2 other than the readiness-pipe write end is closed in the child, and that the caller is in fact the `postStartCommand` chain. Does not establish that the readiness fd `w` is closed later — it is, but only implicitly, by `os.close(ready_fd)` in `serve()` (`:207`) on the success path and by `os._exit(1)` on the error path.
**Legibility-target:** for-orchestrator-synthesis

The child dup2s the log fd over 1 and 2 (`cc-sni-proxy.py:262-263`), so the inherited stdout pipe is already replaced there, then sweeps the rest:

```
for fd in os.listdir("/proc/self/fd"):
    fd = int(fd)
    if fd > 2 and fd != w:
        try:
            os.close(fd)
        except OSError:
            pass
```
(`cc-sni-proxy.py:266-272`; excerpt ends at `:272`, enclosing `daemonize()` continues to `:286` — read.) `r` was already closed at `:258`, and `log_fd` — if it happens to be >2 — is closed by this loop after the dup2s, which is safe.

The "caller's stdout is the postStartCommand pipe" half checks out: `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh"` (`devcontainer-config/devcontainer.json:117`) with `"waitFor": "postStartCommand"` (`:118`), and `init-firewall.sh` invokes the proxy in the foreground of that command (`init-firewall.sh:874-875`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:257-272`, `:207`, `devcontainer-config/devcontainer.json:117-118`, `devcontainer-config/init-firewall.sh:874-875`

---

## Claim 10: "`SO_ORIGINAL_DST = 80` — linux/netfilter_ipv4.h; not exposed by the socket module"

**Location:** `devcontainer-config/cc-sni-proxy.py:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the constant's value and its absence from CPython's `socket` module. Does not establish that the `getsockopt`/`struct.unpack` pair around it decodes `sockaddr_in` correctly on a big-endian host (the format string `"!2xH4s8x"` assumes the kernel's network-order port/addr layout, which is architecture-independent, but the 2-byte `sin_family` skip is host-order).
**Legibility-target:** for-orchestrator-synthesis

`SO_ORIGINAL_DST` is 80 in `include/uapi/linux/netfilter_ipv4.h`, and CPython's `socket` module does not define it (it is not in the module's constant table on any platform). The comment is a plain restatement of a kernel header value with the correct number; the surrounding `original_dst()` (`cc-sni-proxy.py:145-150`) uses it as the optname to `getsockopt(socket.SOL_IP, SO_ORIGINAL_DST, 16)` and unpacks 16 bytes as `!2xH4s8x` → port, 4-byte address, which is the standard `sockaddr_in` decode for this option.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:38`, `:145-150`

---

## Claim 11a: "Do NOT reach for DISABLE_TELEMETRY, DO_NOT_TRACK, or CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: each of those also disables feature-flag evaluation, which Remote Control depends on"

**Location:** `devcontainer-config/devcontainer.json:75-78`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that all three named variables disable the feature-flag evaluation Remote Control availability depends on, and that `DISABLE_ERROR_REPORTING` is not among them. Does not establish completeness of the list — the docs name a fourth variable, `DISABLE_GROWTHBOOK`, that the comment omits.
**Legibility-target:** for-orchestrator-synthesis

Verified against the vendor docs (WebFetch of `https://code.claude.com/docs/en/remote-control.md`, 2026-09-03; fetched page saved as tool output, quoted here):

> **Feature-flag evaluation**: [`DISABLE_TELEMETRY`, `DO_NOT_TRACK`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, and `DISABLE_GROWTHBOOK`](/docs/en/env-vars) each disable the feature-flag evaluation that Remote Control availability depends on.

and, under the "Remote Control requires feature-flag evaluation" error entry, the same four-variable list with "the full message names the variable Claude Code found". `DISABLE_ERROR_REPORTING` appears in neither list. Non-blocking gap: `DISABLE_GROWTHBOOK` is a fourth variable with the same effect that the comment does not warn about.

**Evidence:** WebFetch `https://code.claude.com/docs/en/remote-control.md` (retrieved 2026-09-03), quoted above; `devcontainer-config/devcontainer.json:75-80`

---

## Claim 11b: "The remaining telemetry events go to api.anthropic.com, which is irreducible anyway."

**Location:** `devcontainer-config/devcontainer.json:78-79` (identical claim at `devcontainer-config/egress/base.txt:9-10`, "the remaining telemetry events ride api.anthropic.com, which is already irreducible")
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the destination claim. Does not contradict the practical conclusion that no additional allowlist entry is needed — it is not, because the omitted host is simply firewalled.
**Legibility-target:** for-author

The documented network requirements name **two Datadog intake hosts** in addition to `api.anthropic.com`, and only one of them is switched off by `DISABLE_ERROR_REPORTING` (WebFetch of `https://code.claude.com/docs/en/network-config.md`, retrieved 2026-09-03):

> `http-intake.logs.us5.datadoghq.com` | Operational telemetry events, sent only when the CLI uses the Anthropic API directly … Optional: disable with `DISABLE_TELEMETRY` or `DO_NOT_TRACK`
>
> `browser-intake-us5-datadoghq.com` | Operational error reports … Optional: disable with `DISABLE_ERROR_REPORTING` or `DISABLE_TELEMETRY`

The configuration here sets `DISABLE_ERROR_REPORTING` only (`devcontainer.json:80`) and deliberately does not set `DISABLE_TELEMETRY`/`DO_NOT_TRACK` (Claim 11a). So operational **telemetry** events continue to be addressed to `http-intake.logs.us5.datadoghq.com`, which is in neither `base.txt` nor any other profile — they are dropped by the firewall's terminal `-j REJECT` (`init-firewall.sh:905`) rather than not being emitted. Precise version: "the remaining telemetry that reaches the network rides api.anthropic.com; Claude Code still attempts `http-intake.logs.us5.datadoghq.com`, which the allowlist rejects."

This matters for a reader auditing the boundary: the comment reads as "nothing else is even tried", and the actual property is "nothing else gets through".

**Evidence:** WebFetch `https://code.claude.com/docs/en/network-config.md` (retrieved 2026-09-03), quoted above; `devcontainer-config/devcontainer.json:80`, `devcontainer-config/egress/base.txt:9-10`, `devcontainer-config/init-firewall.sh:905`

---

## Claim 12: "sentry.io and statsig.com were removed 2026-09 … neither appears in the documented requirements any more"

**Location:** `devcontainer-config/egress/base.txt:5-7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of `sentry.io` and `statsig.com` (and `statsig.anthropic.com`) from the current documented network-access table, and their removal from `base.txt`. Does not establish that Claude Code makes no request to either host at runtime — only that the docs no longer require them.
**Legibility-target:** for-orchestrator-synthesis

The full "Network access requirements" table (WebFetch of `https://code.claude.com/docs/en/network-config.md`, retrieved 2026-09-03) lists `api.anthropic.com`, `claude.ai`, `claude.com`, `platform.claude.com`, `mcp-proxy.anthropic.com`, `downloads.claude.ai`, `storage.googleapis.com`, `registry.npmjs.org`, `bridge.claudeusercontent.com`, `*.frame.claudeusercontent.com`, `raw.githubusercontent.com`, `http-intake.logs.us5.datadoghq.com`, `browser-intake-us5-datadoghq.com`, `formulae.brew.sh`, `code.claude.com`. Neither `sentry.io` nor any `statsig` host appears anywhere on the page. `base.txt` correspondingly now contains only `api.anthropic.com`, `claude.ai`, `console.anthropic.com`, `platform.claude.com`, `registry.npmjs.org` (`devcontainer-config/egress/base.txt:25-31`), confirmed by executing the composition hook (`docs/reviews/execution-logs/r1-print-hooks.log`).

**Evidence:** WebFetch `https://code.claude.com/docs/en/network-config.md` (retrieved 2026-09-03); `devcontainer-config/egress/base.txt:25-31`, `docs/reviews/execution-logs/r1-print-hooks.log`

---

## Claim 13: "OAuth token exchange/refresh (platform.claude.com — per the network-config docs; a missing entry surfaces as a mid-session re-login once the access token expires)"

**Location:** `devcontainer-config/egress/base.txt:22-24`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the docs assign OAuth token exchange, refresh and revocation to `platform.claude.com` for claude.ai accounts. Does not establish the stated *symptom* ("a mid-session re-login once the access token expires"), which the docs do not describe.
**Legibility-target:** for-orchestrator-synthesis

The docs row reads (WebFetch of `https://code.claude.com/docs/en/network-config.md`, retrieved 2026-09-03):

> `platform.claude.com` | Anthropic Console account authentication. OAuth token exchange, refresh, and revocation also go to this host for claude.ai accounts, so both Console and claude.ai sign-ins require it

Confidence is Medium because the failure-mode half of the sentence is an inference, not a documented behaviour; the docs' own statement about a blocked `platform.claude.com` is only that the first-run connectivity check points at the errors page. The commit that added the entry is candid about this (`b04090c` body: "platform.claude.com is added on the strength of the docs page alone").

**Evidence:** WebFetch `https://code.claude.com/docs/en/network-config.md` (retrieved 2026-09-03), quoted above; `devcontainer-config/egress/base.txt:28`; `git show -s b04090c`

---

## Claim 14: "the `:11434` suffix is load-bearing … this admits exactly the model server and nothing else … do not drop the suffix, which would silently fall back to 443"

**Location:** `devcontainer-config/egress/llm.txt:19-24`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the entry parses to port 11434 alone and that a suffix-less entry defaults to 443. Does not establish that only the model server listens there (that is a host-side property), and does not establish that the entry is admitted at all under Docker Desktop — `host.docker.internal` must resolve for the phase-A `dig` to produce an ipset member.
**Legibility-target:** for-orchestrator-synthesis

Executed (`docs/reviews/execution-logs/r1-print-hooks.log`, cwd `/workspace`, ts 2026-09-03T15:45:33-07:00, exit 0):

```
CC_EGRESS_DIR=devcontainer-config/egress CC_EGRESS_PROFILE_FILE=<file containing "llm"> \
  bash devcontainer-config/init-firewall.sh --print-entries
→ api.anthropic.com<TAB>443
  …
  host.docker.internal<TAB>11434
  openrouter.ai<TAB>443
```

The 443 default for a suffix-less entry is in `parse_entry`: `if [ "$domain" = "$entry" ]; then ports="443"` (`init-firewall.sh:120-121`), and the same run shows every other entry at 443. Members are written per port as `<ip>,tcp:<port>` (`:383-385`) into a `hash:net,port` set matched `dst,dst` (`:731`, `:902`), so 11434 admits nothing else on that address.

Note for the orchestrator (consistent with the comment, worth stating): because 11434 ≠ 443, `host.docker.internal` is correctly **excluded** from the SNI allowlist by the `case ",$ports," in *,443,*)` filter (`init-firewall.sh:862`) — visible in the same execution log as the entry's absence from the 443 set.

**Evidence:** `docs/reviews/execution-logs/r1-print-hooks.log`, `devcontainer-config/init-firewall.sh:120-121`, `:383-385`, `:731`, `:862`, `:902`

---

## Claim 15: "both halves are constrained to their literal grammar (hostname labels; 1-65535 integers) … 10#: a leading zero would otherwise make bash read the number as octal … Tab-separated, because IFS is \n\t in this script: a space would not split under `read -r domain ports` at the consumer."

**Location:** `devcontainer-config/init-firewall.sh:110-111`, `:128`, `:131-132`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grammar enforcement, the octal rationale, and that every consumer of the tab-separated output splits correctly under `IFS=$'\n\t'`. Does not establish that the domain grammar excludes a name that `dig` would treat specially (a bare label with no dot passes), and does not establish anything about the *content* of profile files, only their shape.
**Legibility-target:** for-orchestrator-synthesis

`parse_entry` (`init-firewall.sh:116-134`, read to its `printf`) applies both regexes before emitting anything:

```
[[ "$domain" =~ ^${label}(\.${label})*$ ]] || return 1
[[ "$ports" =~ ^[0-9]{1,5}(,[0-9]{1,5})*$ ]] || return 1
for port in $(echo "$ports" | tr ',' '\n'); do
  [ "$((10#$port))" -ge 1 ] && [ "$((10#$port))" -le 65535 ] || return 1
done
printf '%s\t%s\n' "$domain" "$ports"
```
(`init-firewall.sh:125-133`)

`label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'` (`:118`). The `10#` note is correct bash semantics — `$((08))` is an "invalid octal" error under `set -e`, `$((10#08))` is 8 — and the range test also rejects `00000` (→ 0). The tab claim holds at all three consumers under the file-level `IFS=$'\n\t'` (`:30`): `while read -r domain ports` at `:348` (phase-A resolution) and `:860` (SNI allowlist), and the `--print-entries` hook's `read -r entry` at `:141`. Every comma split in the file uses `$(echo … | tr ',' '\n')` rather than word-splitting, consistent with the IFS: `:54` (profiles), `:127` (parse_entry ports), `:383` (member emission), and `:191` for the space-separated `GITHUB_DNS_ZONES`.

Executed confirmation of the tab: `cat -A` of `--print-entries` output shows `api.anthropic.com^I443$` (`docs/reviews/execution-logs/r1-print-hooks.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:30`, `:116-134`, `:141`, `:348`, `:383`, `:860`, `docs/reviews/execution-logs/r1-print-hooks.log`

---

## Claim 16: "A `server=/github.com/...` line covers github.com AND every subdomain … Anything else on GitHub (ghcr.io, github.dev) is not in the CIDR ingest either, so it stays unresolved AND unroutable."

**Location:** `devcontainer-config/init-firewall.sh:149-153`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers dnsmasq's suffix semantics for `server=/domain/addr` and the fact that only `.web`, `.api` and `.git` are ingested. Does not establish "unroutable" for hosts that share an address with an ingested CIDR — `ghcr.io` addresses may or may not fall inside `.web/.api/.git`, and the script never checks.
**Legibility-target:** for-author

The dnsmasq semantics half is correct: `server=/<domain>/<addr>` matches the domain and every name beneath it. The zones are `GITHUB_DNS_ZONES="github.com githubusercontent.com"` (`init-firewall.sh:154`), and the generated config carries exactly one line per zone per upstream — confirmed by executing the hook, which emitted `server=/github.com/127.0.0.11` and `server=/githubusercontent.com/127.0.0.11` and no other GitHub line (`docs/reviews/execution-logs/r1-print-hooks.log`).

The imprecision is in "unroutable". The GitHub CIDRs come from `jq -r '(.web + .api + .git)[]'` (`init-firewall.sh:332`) and are added on tcp 443 and 22 (`:744-745`). Whether `ghcr.io`'s addresses lie outside `.web ∪ .api ∪ .git` is not something this code establishes; GitHub's `/meta` `web` block is broad. Precise version: "…stays unresolved through the container resolver, and is not deliberately routed — an address that happens to fall inside the ingested `.web`/`.api`/`.git` CIDRs would still be reachable on 443/22, but only by IP, since the name will not resolve and the SNI proxy would reject it."

Also note the SNI allowlist adds a third zone that has no resolver line at all — see Claim 24.

**Evidence:** `devcontainer-config/init-firewall.sh:154`, `:332`, `:744-745`, `docs/reviews/execution-logs/r1-print-hooks.log`

---

## Claim 17: "there is no bare `server=` line and `no-resolv` stops dnsmasq reading /etc/resolv.conf … A name that matches no `server=/<domain>/` line has nowhere to go and dnsmasq answers REFUSED"

**Location:** `devcontainer-config/init-firewall.sh:161-166`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed (config shape) / static (dnsmasq REFUSED semantics)
**Scope:** Covers that the generated config contains `no-resolv`, no default `server=`, and one `server=/<domain>/<upstream>` per allowlisted name — including the zero-server-line case. Does not establish dnsmasq's on-the-wire RCODE, which was not exercised (no dnsmasq binary in the review sandbox).
**Legibility-target:** for-orchestrator-synthesis

`compose_dnsmasq_conf` (`init-firewall.sh:174-208`, read to its closing `done`) emits a fixed nine-line preamble containing `no-resolv` and never emits an unqualified `server=`; every `server=` it writes is `echo "server=/$d/$ns"` (`:205`) inside the per-domain loop. The empty-upstream branch returns before that loop with only a comment line (`:186-189`).

Executed (`docs/reviews/execution-logs/r1-print-hooks.log`, exit 0):

```
no-resolv
no-hosts
no-poll
bind-interfaces
listen-address=127.0.0.1
port=53
user=dnsmasq
server=/api.anthropic.com/127.0.0.11
… (one per allowlisted name, plus the two GitHub zones)
```

No line begins `server=` without a `/`-delimited domain. The REFUSED half rests on dnsmasq's documented behaviour of answering REFUSED when it has no server for a query and no default upstream; that is asserted from documentation, not executed — the sandbox has no dnsmasq (`docs/reviews/execution-logs/r1-env-probe.log`), which is why confidence is Medium. The originating commit is explicit about the same limit (`d598bda` body: "dnsmasq REFUSED-with-no-servers behaviour … asserted from documentation").

**Evidence:** `devcontainer-config/init-firewall.sh:174-208`, `:186-189`, `:205`, `docs/reviews/execution-logs/r1-print-hooks.log`, `docs/reviews/execution-logs/r1-env-probe.log`

---

## Claim 18: "Profile entries may carry a `:port` suffix …; the resolver only wants the name. Then refuse anything that is not a plain hostname"

**Location:** `devcontainer-config/init-firewall.sh:192-196`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the `:port` strip precedes the hostname regex and that a non-hostname is warned about and omitted rather than emitted as config. Does not establish that the regex rejects every string dnsmasq would misparse — it requires at least one dot, which is stricter than `parse_entry`'s domain grammar, so a single-label profile entry silently gets no resolver line while still being ipset-admitted.
**Legibility-target:** for-orchestrator-synthesis

The order is unambiguous in the loop body: `d="${d%%:*}"` (`init-firewall.sh:197`), then the emptiness guard (`:198`), then

```
if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]; then
  echo "WARNING: not a hostname, omitting from resolver allowlist (stays unresolvable): $d" >&2
  continue
fi
```
(`init-firewall.sh:199-202`). The strip therefore cannot be defeated by a `:`-bearing entry, and a `/` or `#` in an entry fails the regex and is dropped with a warning rather than becoming a dnsmasq directive. Two bats tests cover exactly this (`print-dnsmasq-conf strips a :port suffix from profile entries`, `print-dnsmasq-conf refuses a non-hostname entry rather than emitting it as config`), both passing in the 98/98 run (`docs/reviews/execution-logs/r1-bats.log`).

**Evidence:** `devcontainer-config/init-firewall.sh:191-207`, `docs/reviews/execution-logs/r1-bats.log`

---

## Claim 19: "the trap re-reads the live policies with `iptables -S` afterwards and says which of two very different things happened … The 'forced DROP' line is printed only AFTER the read-back confirms it, so the log never claims a DROP that was not applied."

**Location:** `devcontainer-config/init-firewall.sh:239-244`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read-back, the two mutually exclusive message branches, and their ordering relative to the `-P` calls. Does not establish that the trap fires on every abort path — that depends on the `INT TERM HUP QUIT` converter at `:272` (checked separately, Claim 20) — and does not establish that `iptables -S` reflects a policy the kernel silently ignored.
**Legibility-target:** for-orchestrator-synthesis

`fail_closed_on_abort` (`init-firewall.sh:246-270`, read signature to closing brace) sets all three policies with `|| true`, then reads back and branches:

```
policies="$(iptables -w 5 -S 2>/dev/null || true)"
for chain in OUTPUT INPUT FORWARD; do
  if ! grep -q "^-P $chain DROP" <<< "$policies"; then
    open=1
    echo "ERROR: could not force DROP policy on $chain — container may be OPEN." >&2
  fi
done
if [ "$open" = "1" ]; then
  … "Do NOT start a session in this container as-is." …
else
  echo "       Forced DROP policies (verified): the container fails CLOSED (no" >&2
```
(`init-firewall.sh:253-264`; excerpt ends at `:264`, the enclosing `if [ "${FIREWALL_COMPLETE:-0}" != "1" ]` block continues to `:269` — read.)

The "verified" line is unreachable unless every one of the three chains matched, and the `|| true` on the read-back degrades to an empty string, which fails all three greps and takes the OPEN branch — i.e. the `|| true`s fail toward alarm, not toward a false all-clear. Two bats tests exercise both branches (`… trap uses -w 5 and verifies without alarm`, `… OPEN alarm under FAIL_POLICY`); both pass (`docs/reviews/execution-logs/r1-bats.log`, 98 ok / 0 not ok).

**Evidence:** `devcontainer-config/init-firewall.sh:245-272`, `docs/reviews/execution-logs/r1-bats.log`

---

## Claim 20: "Close the window BEFORE it opens: set the DROP policies first, then flush. Chain policies survive `iptables -F` (a flush removes rules, not policies) … Accept rules added below still take effect: a policy applies only when no rule matches."

**Location:** `devcontainer-config/init-firewall.sh:462-471`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the source-level ordering (three `-P … DROP` before every `-F`) and the netfilter semantics that a flush clears rules but not the chain policy. Does not establish kernel behaviour by execution — no privileged container is available in the review sandbox.
**Legibility-target:** for-orchestrator-synthesis

The ordering is literal and unbroken by any other statement:

```
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Flush existing rules and delete existing ipsets (policies set above persist)
iptables -F
```
(`init-firewall.sh:472-477`)

Nothing between `:460` (`DOCKER_DNS_RULES=$(iptables-save …)`) and `:472` performs a network read or an iptables write. The "policies survive a flush" semantics is standard netfilter (`iptables -F` operates on rules; the built-in chain policy is a separate field changed only by `-P`), asserted from the iptables man page as the originating commit states (`6244ebf` body: "Kernel/netfilter semantics of the policy-before-flush ordering are asserted from the iptables man page, not exercised"). A bats test asserts the source ordering (`policies-before-flush ordering`, in the 98/98 run).

**Evidence:** `devcontainer-config/init-firewall.sh:460`, `:472-477`, `git show -s 6244ebf`, `docs/reviews/execution-logs/r1-bats.log`

---

## Claim 21: "Idempotent restart: kill by pidfile, then start exactly one instance" (dnsmasq) and "a prior instance named by the pidfile is terminated first, so re-runs are idempotent" (SNI proxy)

**Location:** `devcontainer-config/init-firewall.sh:661`, `:871-872`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers daemon idempotency (both pidfile paths) **and** iptables-chain idempotency, which the same "re-run" property depends on — the load-bearing question of whether a second run's `iptables -N CC_DNS` fails with "chain already exists" under `set -e`. It does not. Does not establish idempotency against a daemon that lost its pidfile *and* is not the dnsmasq uid (the proxy has no uid sweep, only the pidfile + `/proc/<pid>/cmdline` check).
**Legibility-target:** for-orchestrator-synthesis

**Daemons.** `stop_dnsmasq` (`init-firewall.sh:413-428`, read to closing brace) reads the pidfile, confirms `/proc/$pid/comm` is literally `dnsmasq` before killing (so a stale pid cannot kill an unrelated process), escalates to `-9` after 3 s, removes the pidfile, and then sweeps `pkill -x -U "$DNSMASQ_UID" dnsmasq`. It is called immediately before the single `dnsmasq --conf-file=… --pid-file=…` (`:667-668`). The proxy's equivalent is `stop_prior(args.pidfile)` (`cc-sni-proxy.py:212-232`), gated on `b"cc-sni-proxy" in /proc/<pid>/cmdline`, called first thing in `daemonize` (`:242`).

**Chains — the load-bearing half.** Phase B's flush deletes the user chains before they are re-created:

```
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true
```
(`init-firewall.sh:477-483`)

`-F` empties every chain in the table (including built-ins, which removes all jumps into user chains), so the immediately following `-X` has no non-empty and no referenced chain left to refuse, and deletes all user-defined chains in that table. `CC_DNS_GUARD` and `CC_SNI_GUARD` live in filter (`:693`, `:892`) and are cleared by `:477-478`; `CC_DNS` and `CC_SNI` live in nat (`:681`, `:882`) and are cleared by `:479-480`. So the bare `iptables -N CC_DNS` at `:681` — deliberately without `|| true`, per the comment at `:642-644` — cannot hit "chain already exists" on a re-run and cannot spuriously trip the fail-closed trap. The script's own consistency check on this reasoning: Docker's chains are re-created with `2>/dev/null || true` (`:488-489`) precisely because they too were destroyed by `-t nat -X`.

**Evidence:** `devcontainer-config/init-firewall.sh:413-428`, `:477-483`, `:488-489`, `:642-644`, `:667-668`, `:681`, `:693`, `:882`, `:892`, `devcontainer-config/cc-sni-proxy.py:212-232`, `:242`

---

## Claim 22: "Docker's embedded resolver is DNAT'd off port 53 in nat OUTPUT before filter OUTPUT sees it, so a --dport 53 filter rule would not match that traffic regardless" and "the CC_DNS_GUARD jump on 127.0.0.11 for ALL ports, installed BEFORE the loopback accept"

**Location:** `devcontainer-config/init-firewall.sh:561-563`, `:630-635`, `:717-719`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the guard jump carries no port match, that it is appended to OUTPUT before the `-o lo` accept, and that Docker's own restored rules are DNATs on 127.0.0.11. Does not establish the netfilter traversal order (nat OUTPUT before filter OUTPUT) by execution — that is standard for locally generated packets but was not exercised, no privileged container being available.
**Legibility-target:** for-orchestrator-synthesis

The guard jumps are appended in this order, with the loopback accept last:

```
iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD
iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
iptables -A OUTPUT -o lo -j ACCEPT
```
(`init-firewall.sh:720-723`)

The first carries no `--dport`, so it matches 127.0.0.11 on every port — which is the point, since Docker's restored rules are DNATs to a random high port (`DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)`, `:460`, replayed at `:490`). `CC_DNS_GUARD` RETURNs for the dnsmasq uid and root and REJECTs everything else (`:693-696`), so the agent's direct hit on `127.0.0.11:<random>` is refused before it can reach `-o lo`. A bats test asserts the ordering (`the 127.0.0.11 bypass reject precedes the loopback accept`), passing in the 98/98 run. The originating commit records the same execution limit (`d598bda`: "kernel semantics … asserted from documentation and Docker's own DNAT precedent, and verified here only at the command-sequence level").

**Evidence:** `devcontainer-config/init-firewall.sh:460`, `:490`, `:693-696`, `:720-723`, `docs/reviews/execution-logs/r1-bats.log`, `git show -s d598bda`

---

## Claim 23: "The nat rules are INSERTED at position 1, ahead of the `-d 127.0.0.11 -j DOCKER_OUTPUT` jump restored above: were they appended, a node query to 127.0.0.11:53 would be DNAT'd to the embedded resolver before the redirect could claim it."

**Location:** `devcontainer-config/init-firewall.sh:637-640`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rule ordering within nat OUTPUT: the two `CC_DNS` jumps sit ahead of every Docker rule restored earlier in the same run. Does not establish that `CC_SNI` enjoys the same precedence — it does not, and does not need to (see below).
**Legibility-target:** for-orchestrator-synthesis

The restore appends Docker's captured rules with `echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat` (`init-firewall.sh:490`); an `iptables-save -t nat` capture yields `-A …` lines, so these land at the end of nat OUTPUT. The `CC_DNS` jumps are added afterwards with an explicit position:

```
iptables -t nat -I OUTPUT 1 -p tcp --dport 53 -j CC_DNS
iptables -t nat -I OUTPUT 1 -p udp --dport 53 -j CC_DNS
```
(`init-firewall.sh:686-687`)

Both are inserted at 1 after the restore (line 490 < line 686), so the final order is udp-53 jump, tcp-53 jump, then Docker's `-d 127.0.0.11 -j DOCKER_OUTPUT`. Contrast `CC_SNI`, which is appended (`iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI`, `:886`) — harmless, because Docker's restored rules are all `127.0.0.11`-scoped DNS rules that cannot match a tcp/443 flow to an external address.

**Evidence:** `devcontainer-config/init-firewall.sh:486-493`, `:686-687`, `:886`

---

## Claim 24: "None of the base zones (api.anthropic.com, claude.ai, console.anthropic.com, sentry.io, statsig.com, registry.npmjs.org, github.com, githubusercontent.com) hand out delegations to third parties"

**Location:** `devcontainer-config/init-firewall.sh:648-651`
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the enumeration only. Does not establish or refute the delegation property itself for the zones that *are* current.
**Legibility-target:** for-author

The list names `sentry.io` and `statsig.com`, which the same commit range removed from `base.txt` (`devcontainer-config/egress/base.txt:5-7`, and Claim 12), and omits `platform.claude.com`, which the same range added (`base.txt:28`). Executing the composition hook against the shipped profile confirms the current base set (`docs/reviews/execution-logs/r1-print-hooks.log`):

```
api.anthropic.com<TAB>443
claude.ai<TAB>443
console.anthropic.com<TAB>443
platform.claude.com<TAB>443
registry.npmjs.org<TAB>443
```

plus the two `GITHUB_DNS_ZONES` (`init-firewall.sh:154`). Precise version: the parenthetical should read "(api.anthropic.com, claude.ai, console.anthropic.com, platform.claude.com, registry.npmjs.org, github.com, githubusercontent.com)". The SNI block's parallel residual note already reflects the removal correctly ("base no longer carries one", `:850-851`), so the drift is confined to this one list.

**Evidence:** `devcontainer-config/init-firewall.sh:648-651`, `:154`, `:850-851`, `devcontainer-config/egress/base.txt:5-7`, `:25-31`, `docs/reviews/execution-logs/r1-print-hooks.log`

---

## Claim 25: "NOTE: no inbound `--sport 53` accept. DNS replies to the scoped OUTPUT rules above are already admitted by the `INPUT -m state --state ESTABLISHED,RELATED` accept near the end"

**Location:** `devcontainer-config/init-firewall.sh:698-701`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of any `--sport 53` rule and the presence of the INPUT ESTABLISHED,RELATED accept. Does not establish that conntrack tracks the redirected UDP flows correctly on the target kernel.
**Legibility-target:** for-orchestrator-synthesis

No `--sport` appears anywhere in the file (the only INPUT accepts are `-i lo` at `:716` and `-m state --state ESTABLISHED,RELATED` at `:802`). A bats test asserts the absence (`no --sport 53 rule`, added by `6244ebf`), passing in the 98/98 run (`docs/reviews/execution-logs/r1-bats.log`). The INPUT ESTABLISHED,RELATED rule is at `:802`, "near the end" as claimed, and precedes nothing that would shadow it (the INPUT chain has no other rules after it; the policy is DROP, `:797`).

**Evidence:** `devcontainer-config/init-firewall.sh:698-703`, `:716`, `:797`, `:802`, `docs/reviews/execution-logs/r1-bats.log`

---

## Claim 26: "nat OUTPUT REDIRECTs every tcp/443 connection that is not the proxy's own (and not root's — see below) to it … Because the proxy connects to what the NAME resolves to and never to the client's chosen address, a forged SNI cannot steer a connection to an arbitrary IP"

**Location:** `devcontainer-config/init-firewall.sh:817-824`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the chain construction, the two owner exemptions, and the resolve-the-name property (cross-checked in Claim 4). Does not establish that the kernel performs the REDIRECT on locally generated packets under Docker Desktop's kernel, nor that `xt_owner` is available in nat OUTPUT there — neither is exercisable in this sandbox. Does not cover udp/443 or IPv6 (see Claim 6).
**Legibility-target:** for-orchestrator-synthesis

The chain is built exactly as described:

```
iptables -t nat -N CC_SNI
iptables -t nat -A CC_SNI -m owner --uid-owner "$CCPROXY_UID" -j RETURN
iptables -t nat -A CC_SNI -m owner --uid-owner 0 -j RETURN
iptables -t nat -A CC_SNI -p tcp -j REDIRECT --to-ports "$SNI_PORT"
iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI
```
(`init-firewall.sh:882-886`)

`CCPROXY_UID` is validated numeric, non-zero and distinct from `DNSMASQ_UID` in phase A, before the flush (`:449-453`). The filter-side belt-and-braces chain mirrors it and is jumped to from OUTPUT **before** the ipset accept (`:892-896` then `:902`), so a 443 flow that escaped the redirect is REJECTed rather than admitted by address. The resolve-the-SNI half is established in Claim 4. Confidence is Medium only because of the unexercised kernel semantics, which the decision-log row and commit message both flag as needing one live-container check (`docs/decisions/log.md:61`; `git show -s aa8dffc`).

**Evidence:** `devcontainer-config/init-firewall.sh:449-453`, `:882-886`, `:892-896`, `:902`, `docs/decisions/log.md:61`

---

## Claim 27: "GitHub is admitted by CIDR (phase A) rather than by name; these are the zones git, gh and git-lfs actually contact over 443." (immediately preceding `.github.com`, `.githubusercontent.com`, `.githubassets.com`)

**Location:** `devcontainer-config/init-firewall.sh:864-865`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the third entry, `.githubassets.com`. Does not dispute `.github.com` or `.githubusercontent.com`, which git/gh/git-lfs do contact and which the resolver does serve.
**Legibility-target:** for-author

`.githubassets.com` is written into the SNI allowlist (`init-firewall.sh:868`) but has no counterpart in `GITHUB_DNS_ZONES`, which is `"github.com githubusercontent.com"` (`:154`). Executing the resolver-config hook confirms the omission — the generated config carries `server=/github.com/…` and `server=/githubusercontent.com/…` and no `githubassets` line at all (`docs/reviews/execution-logs/r1-print-hooks.log`). So any `*.githubassets.com` lookup from `node` is REFUSED by the filtering resolver and the SNI entry can never be exercised.

The file's own other comment contradicts this one on the same point: `GITHUB_DNS_ZONES`'s block says `github.com` plus `githubusercontent.com` cover "the hosts git, gh and git-lfs actually contact" (`:150-152`), listing only two zones for the same three tools. `githubassets.com` is GitHub's web-UI static asset host, not a host the git/gh/git-lfs CLIs contact.

Confidence is Medium because "which hosts `gh` contacts" is an external-behaviour claim not fully determinable from this repo; the *internal* contradiction and the missing resolver line are certain. Precise version: "`.github.com` and `.githubusercontent.com` are the zones git, gh and git-lfs contact over 443; `.githubassets.com` is listed defensively and is currently unreachable anyway, since the filtering resolver has no `server=` line for it."

Not logged to `hallucination-patterns.md`: `githubassets.com` is a real host, so this is drift, not a fabrication.

**Evidence:** `devcontainer-config/init-firewall.sh:150-154`, `:864-869`, `docs/reviews/execution-logs/r1-print-hooks.log`

---

## Claim 28: "Negative: an address that IS in the ipset, asked for with a name that is NOT allowlisted, must be refused … SNI proxy probes, run AS NODE so they traverse the redirect (root is exempt)."

**Location:** `devcontainer-config/init-firewall.sh:926`, `:934-936`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed (environment preconditions) / static (probe logic)
**Scope:** Covers that `ANTHROPIC_PROBE_IP` is non-empty on every path that reaches the probe, that `runuser` exists in the image, and that the probe runs as `node`. Does not establish that the negative probe *distinguishes* a refusal by the SNI proxy from any other curl failure — it does not, which is the imprecision below.
**Legibility-target:** for-author

**`ANTHROPIC_PROBE_IP` is reliably set.** It is initialised empty at `:347`, and set on the first A record of `api.anthropic.com`:

```
if [ "$domain" = "api.anthropic.com" ] && [ -z "${ANTHROPIC_PROBE_IP:-}" ]; then
    ANTHROPIC_PROBE_IP="$ip"
fi
```
(`init-firewall.sh:380-382`). `api.anthropic.com` is unconditionally in `base` (`egress/base.txt:25`, confirmed by `--print-entries`, `docs/reviews/execution-logs/r1-print-hooks.log`), and a resolution failure for exactly that name is a hard `exit 1` (`:364-367`) — so no path reaches `:938` with the variable empty. The multiple-A-record case is handled by the `-z` guard, which pins the first.

**`runuser` exists.** Executed: `-rwxr-xr-x 1 root root 72000 … /usr/sbin/runuser` in the running container (`docs/reviews/execution-logs/r1-env-probe.log`, ts 2026-09-03T15:48:33-07:00). The script runs as root under `sudo`, whose `secure_path` includes `/usr/sbin`.

**The imprecision.** The negative probe treats *any* non-zero curl exit as a pass:

```
if runuser -u node -- curl --connect-timeout 5 --max-time 15 \
        --resolve "not-allowlisted.invalid:443:$ANTHROPIC_PROBE_IP" https://not-allowlisted.invalid/ >/dev/null 2>&1; then
    echo "ERROR: … a non-allowlisted SNI reached an allowlisted address"
```
(`init-firewall.sh:937-939`; excerpt ends at `:939`, enclosing `if` continues through the `else`/`fi` at `:941-943` — read.) A `runuser` that is absent, a `node` account that cannot execute curl, a missing `--resolve` argument, or any transport error all produce the same "passed" line. The claim "must be refused" describes the intent; what is asserted is "must not succeed". Precise version: "an address that IS in the ipset, asked for with a name that is NOT allowlisted, must not connect — the probe does not distinguish an SNI refusal from other failure modes." Sibling context supports the narrower reading: two bats tests do exercise the failure directions with a stub (`a proxy that admits a non-allowlisted SNI fails verification and fails closed`, `node failing to reach api.anthropic.com through the proxy fails verification`), both passing.

**Evidence:** `devcontainer-config/init-firewall.sh:347`, `:364-367`, `:380-382`, `:926-943`, `devcontainer-config/egress/base.txt:25`, `docs/reviews/execution-logs/r1-env-probe.log`, `docs/reviews/execution-logs/r1-print-hooks.log`, `docs/reviews/execution-logs/r1-bats.log`

---

## Claim 29: "the proxy logs every decision to `/run/cc-sni-proxy/proxy.log` as `ALLOW`, `REJECT sni=... not in allowlist`, or `FAIL` (the name resolved to an address the ipset does not admit)"

**Location:** `guides/cc-isolated-usage.md:299-301`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the log path and the three verb tokens, which all match the code. Does not establish that the three listed shapes are exhaustive — there is a fourth (a `REJECT` with no `sni=` field) — and the parenthetical gloss on `FAIL` is narrower than what emits it.
**Legibility-target:** for-author

The path is right: the proxy's `--log` default is `/run/cc-sni-proxy/proxy.log` (`cc-sni-proxy.py:296`), and the firewall passes `SNI_LOG="$SNI_RUN_DIR/proxy.log"` with `SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"` (`init-firewall.sh:438`, `:441`, `:875`). The verbs are right; `handle()` emits exactly four log lines (`cc-sni-proxy.py:168-196`, read whole):

- `:176` — `REJECT orig_dst={orig}: {e}` — **no `sni=` field**, for an unparseable/timed-out/short-read ClientHello. Not mentioned in the guide, and it is the line a reader debugging "connection closes immediately" is most likely to see when the client speaks something other than TLS.
- `:179` — `REJECT sni={sni} orig_dst={orig}: not in allowlist` — matches the guide's shape.
- `:188` — `FAIL sni={sni} orig_dst={orig}: {e} (resolved address not in the ipset?)` — emitted for **any** `OSError` or timeout from `getaddrinfo` **or** `open_connection` (`:187`), which includes the DNS-REFUSED case (name not in the dnsmasq allowlist) as well as the ipset case. The code's own message hedges with a question mark; the guide's parenthetical states it as the cause.
- `:190` — `ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}`.

Precise version: "…as `ALLOW`, `REJECT` (either `sni=<name> … not in allowlist`, or without an `sni=` field when the ClientHello could not be parsed), or `FAIL` (the name did not resolve, or resolved to an address the ipset does not admit)."

**Evidence:** `devcontainer-config/cc-sni-proxy.py:168-196`, `:296`, `devcontainer-config/init-firewall.sh:438`, `:441`, `:875`, `guides/cc-isolated-usage.md:299-301`

---

## Claim 30: "The blanket `INPUT -s <bridge>/24` / `OUTPUT -d <bridge>/24` accepts are replaced by `OUTPUT -d <gateway> --dport 53` (udp+tcp) with no inbound counterpart (replies are ESTABLISHED,RELATED). … Guarded by 7 new bats tests."

**Location:** `docs/decisions/log.md:57` (row 39)
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule replacement, the absence of an inbound counterpart, and the test count for row 39's own commit. Does not mention that the surviving gateway rules were subsequently owner-scoped to the dnsmasq uid and root by the later resolver commit — a narrowing, not a contradiction.
**Legibility-target:** for-orchestrator-synthesis

No `-s <net>/24` or `-d <net>/24` rule survives anywhere in the file; the only `HOST_IP` rules are:

```
for uid in "$DNSMASQ_UID" 0; do
    iptables -A OUTPUT -p udp -d "$HOST_IP" --dport 53 -m owner --uid-owner "$uid" -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$HOST_IP" --dport 53 -m owner --uid-owner "$uid" -j ACCEPT
done
```
(`init-firewall.sh:788-791`). The INPUT chain has no `HOST_IP` rule at all, and replies ride `iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT` (`:802`). Test count: `git show f1443c5 -- test/` adds exactly 7 `@test` blocks (`the allowlist ipset is address+port…`, `GitHub CIDRs are admitted on tcp 443 and tcp 22 only`, `a port-less profile entry defaults to tcp 443`, `a profile entry with a port suffix…`, `the shipped llm profile scopes host.docker.internal to 11434…`, `a malformed profile entry is a hard failure…`, `the bridge gateway is admitted on udp/tcp 53 only, with no inbound counterpart`).

**Evidence:** `devcontainer-config/init-firewall.sh:788-791`, `:802`, `git show f1443c5 -- test/ | grep -c '^+@test'` → 7, `docs/reviews/execution-logs/r1-bats.log`

---

## Claim 31: "Guarded by 10 bats tests + 13 Python unit tests (parser, allowlist, loopback splice)." (row 41) and "verified by 10 new command-sequence bats tests" (row 40)

**Location:** `docs/decisions/log.md:61`, `docs/decisions/log.md:62`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four counts as added-test counts per originating commit, and that all of them currently pass. Does not establish coverage adequacy — this is a count check, matching the shape of the two logged hallucination patterns.
**Legibility-target:** for-orchestrator-synthesis

`git show aa8dffc -- test/ | grep -c '^+@test'` → **10**; `git show d598bda -- test/ | grep -c '^+@test'` → **10**. Executed suites (cwd `/workspace`, ts 2026-09-03T15:45:08-07:00 and 15:45:22-07:00):

- `LC_ALL=C bats test/init-firewall-rules.bats test/cc-isolated-functions.bats` → `1..98`, 98 `ok`, 0 `not ok`, exit 0 (`docs/reviews/execution-logs/r1-bats.log`)
- `LC_ALL=C python3 test/test_cc_sni_proxy.py` → `Ran 13 tests … OK`, exit 0 (`docs/reviews/execution-logs/r1-python.log`)

The row-41 parenthetical "(parser, allowlist, loopback splice)" matches the Python file's coverage as reported by the 13-test run.

**Evidence:** `docs/reviews/execution-logs/r1-bats.log`, `docs/reviews/execution-logs/r1-python.log`, `git show aa8dffc -- test/`, `git show d598bda -- test/`

---

## Claim 32a: "98/98 bats + 13/13 python unit tests; shellcheck clean"

**Location:** commit message `aa8dffc` (Notes line)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two suites named in the review brief and `shellcheck -S warning` on `init-firewall.sh` at HEAD. Does not establish that "98/98" covers every bats file in the repo — it is the union of `init-firewall-rules.bats` and `cc-isolated-functions.bats`, the two suites the brief names.
**Legibility-target:** for-orchestrator-synthesis

All three executed at HEAD (abbd42d), cwd `/workspace`:

- `LC_ALL=C bats test/init-firewall-rules.bats test/cc-isolated-functions.bats` — `1..98`, 98 ok, 0 not ok, exit 0, ts 2026-09-03T15:45:08-07:00 (`docs/reviews/execution-logs/r1-bats.log`)
- `LC_ALL=C python3 test/test_cc_sni_proxy.py` — `Ran 13 tests in 0.123s / OK`, exit 0, ts 2026-09-03T15:45:22-07:00 (`docs/reviews/execution-logs/r1-python.log`)
- `LC_ALL=C shellcheck -S warning devcontainer-config/init-firewall.sh` — no output, exit 0, ts 2026-09-03T15:45:23-07:00 (`docs/reviews/execution-logs/r1-shellcheck.log`)

**Evidence:** `docs/reviews/execution-logs/r1-bats.log`, `docs/reviews/execution-logs/r1-python.log`, `docs/reviews/execution-logs/r1-shellcheck.log`

---

## Claim 32b: "docs/decisions/log.md: row 39 records the decision and the REDIRECT-vs-resolv.conf choice."

**Location:** commit message `d598bda` (body)
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row number as read against HEAD. Does not impugn the commit at the time it was written — the row was 39 in its own worktree.
**Legibility-target:** for-author

At `d598bda` the added row was numbered 39 (`git show d598bda:docs/decisions/log.md | grep -c '^| 39 '` → 1). The parallel port-scoping branch had independently claimed 39, and the merge renumbered the resolver row to 40 (`docs/decisions/log.md:62`). Same renumbering drift as Claim 2; the two share a root cause (concurrent worktrees each appending a row without a reservation), which is why the Dockerfile comment inherited the wrong number too. Commit messages are immutable, so the actionable half of this is Claim 2's Dockerfile comment.

**Evidence:** `git show -s d598bda`, `git show d598bda:docs/decisions/log.md`, `docs/decisions/log.md:57`, `:62`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`devcontainer-config/cc-sni-proxy.py:25`): "hashed by the launcher's trust manifest" — `cc-sni-proxy.py` is absent from `enforcement_files()` in `devcontainer-config/cc-isolated.sh:49-65`, so a host-side edit of the proxy would not trip `check_manifest()`'s refusal at the next launch. The root-owned half of the sentence is true.
- **Claim 11b** (`devcontainer-config/devcontainer.json:78-79`, duplicated at `devcontainer-config/egress/base.txt:9-10`): "the remaining telemetry events go to api.anthropic.com" — with only `DISABLE_ERROR_REPORTING` set, Claude Code still addresses operational telemetry to `http-intake.logs.us5.datadoghq.com` (documented), which is not on the allowlist and is dropped by the terminal REJECT rather than not emitted.
- **Claim 27** (`devcontainer-config/init-firewall.sh:864-865`): "these are the zones git, gh and git-lfs actually contact over 443" applied to `.githubassets.com` — that zone has no `server=` line in the generated dnsmasq config (`GITHUB_DNS_ZONES` is only `github.com githubusercontent.com`, `:154`), so it is unresolvable from `node`; the file's own comment at `:150-152` lists only two zones for the same three tools.

### Stale
- **Claim 2** (`devcontainer-config/Dockerfile:47`): "decision log #39: the filtering resolver" — the resolver is row 40 (`docs/decisions/log.md:62`); row 39 is the port-scoping change.
- **Claim 24** (`devcontainer-config/init-firewall.sh:648-651`): the base-zone enumeration still names `sentry.io` and `statsig.com`, both removed from `base.txt` in this same range, and omits the newly added `platform.claude.com`.
- **Claim 32b** (commit `d598bda` body): "row 39 records the decision" — renumbered to 40 at merge. Immutable; the live copy of the error is Claim 2.

### Mostly Accurate
- **Claim 3** (`devcontainer-config/Dockerfile:387-388`): "0555 like the firewall script it belongs to" — `init-firewall.sh` is `chmod +x` (0755), not 0555; the proxy is stricter, not equal.
- **Claim 16** (`devcontainer-config/init-firewall.sh:149-153`): "stays unresolved AND unroutable" — unresolved is established; unroutable is not, since a non-ingested GitHub host's address may still fall inside the `.web`/`.api`/`.git` CIDRs.
- **Claim 28** (`devcontainer-config/init-firewall.sh:934-936`): the negative probe asserts "did not connect", not "was refused by the SNI proxy" — a missing `runuser`, an unusable `node` account, or any transport error all read as a pass.
- **Claim 29** (`guides/cc-isolated-usage.md:299-301`): the log-vocabulary list omits the `REJECT` form that carries no `sni=` field (unparseable ClientHello), and its gloss on `FAIL` is narrower than the emitting condition, which also covers DNS failure.

### Unverifiable
- None. Every claim in scope was resolvable either statically or by execution. Where kernel/netfilter behaviour could not be exercised (Claims 20, 22, 26), the source-level property the comment asserts *was* checkable and is recorded as Verified with the unexercised residue named in `Scope:`; the code's own commit messages already flag the live-container check as outstanding.

## Goal-Alignment Note
- Answered: yes — all 15 brief items checked, 32 claims verdicted, all four executable guarantees run.
- Out of scope: code quality, architecture and security judgements (sibling critics own those); `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py` and `docs/working/questions.md` were read as sibling context only, per the brief. Design-rationale prose (the "why REDIRECT over resolv.conf" and threat-model blocks) was skipped as intent, not checkable claims.
- Escalate: (1) **Claim 5b** is the one finding with a boundary consequence rather than a documentation consequence — the new enforcement-relevant file `cc-sni-proxy.py` is outside the bless manifest, so add it to `enforcement_files()` in `devcontainer-config/cc-isolated.sh` (and re-bless) before relying on these changes; the docstring is currently describing a protection that does not exist. (2) **Claim 27** — `.githubassets.com` is admitted by SNI but cannot resolve; decide whether to add it to `GITHUB_DNS_ZONES` or drop it from the SNI allowlist, since today it is dead config either way. (3) The row-39/40 renumbering (Claims 2, 24, 32b) is a recurring cost of appending decision-log rows in parallel worktrees; worth a convention.
