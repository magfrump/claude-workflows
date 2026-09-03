# Code Fact-Check Report

**Commit:** abbd42d
**Replication:** k=3
**Repository:** claude-workflows (`/workspace`)
**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` (init-firewall.sh, cc-sni-proxy.py, Dockerfile, devcontainer.json, egress/base.txt, egress/llm.txt) plus the range's commit messages, `docs/decisions/log.md` rows 39–41, and the SNI section of `guides/cc-isolated-usage.md`. Tests and `docs/working/questions.md` were sibling context only.
**Checked:** 2026-09-03
**Total claims checked:** 44
**Summary:** 29 verified, 7 mostly accurate, 4 stale, 3 incorrect, 3 unverifiable (2 of the 3 Incorrect are single-replicate detections; see Verdict stability)

Merged from `code-fact-check-report-r1.md` (32 claims), `-r2.md` (31), `-r3.md` (39), all at `Commit: abbd42d`. Merge is most-severe-wins on verdict, union on annotations. Per-replicate execution logs: `docs/reviews/execution-logs/r1-*.log`, `cfc-r2-*-abbd42d.txt`, `r3-*.log`. Executed guarantees held in every replicate: 98/98 bats (`init-firewall-rules` 46 + `cc-isolated-functions` 52), 13/13 Python tests, shellcheck clean, and the `--print-entries` / `--print-dnsmasq-conf` / `--print-resolvers` hooks run unprivileged without touching iptables.

---

## Claim 1: "dnsmasq-base (above) is the daemon binary WITHOUT the `dnsmasq` package's sysv/systemd service wrapper: nothing in the container may auto-start a resolver"

**Location:** `devcontainer-config/Dockerfile:44-46`
**Type:** Configuration / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing positively about Debian's package split from this sandbox; the in-repo consequence (only `dnsmasq-base` is installed at `Dockerfile:34`, and `init-firewall.sh:667-668` starts exactly one instance itself) is established. Does not establish that no other installed package auto-starts a resolver, nor that the binary is present in the currently running image (r1: it is not; the image has not been rebuilt).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Unverifiable
**Replicate annotations:** r3: "`apt-cache show dnsmasq-base` → `E: No packages found`; packages.debian.org unreachable from the sandbox — blocker: no package metadata source reachable" · r1: "does not establish that the binary is present in the currently-running image (it is not)" · r2: "does not establish that `dnsmasq-base`'s postinst creates the `dnsmasq` user (the Dockerfile does not rely on it — see Claim 3)"

r1 and r2 verdicted from Debian packaging knowledge; r3 tried to confirm from package metadata and could not reach any. Under most-severe-wins the cluster is Unverifiable: the claim is about an external package's contents. What is checkable holds — `dnsmasq-base \` is the only dnsmasq package in the apt list (`Dockerfile:34`), and the daemon is started by the script, not a service manager: `stop_dnsmasq` / `dnsmasq --conf-file="$DNSMASQ_CONF" --pid-file="$DNSMASQ_PIDFILE"` (`init-firewall.sh:667-668`).

**Evidence:** `devcontainer-config/Dockerfile:34`, `:44-52`, `devcontainer-config/init-firewall.sh:667-668`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 2: "(decision log #39: the filtering resolver that closes recursive-forward DNS tunnelling)"

**Location:** `devcontainer-config/Dockerfile:47-48`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row-number pointer only. Does not establish anything about the resolver's behaviour, which the comment describes correctly.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "renumbering drift from the parallel-worktree merge, not a fabrication: `git show d598bda:docs/decisions/log.md` contains exactly one `^| 39 ` row"

The filtering resolver is row **40**: "`| 40 | 2026-09-03 | **Close recursive-forward DNS tunnelling (egress review finding 6) with a filtering resolver in the container**`" (`docs/decisions/log.md:62`); row 39 is port scoping (`:57`). Precise version: `decision log #40`.

**Evidence:** `docs/decisions/log.md:57`, `docs/decisions/log.md:62`

---

## Claim 3: "The daemon drops to the unprivileged `dnsmasq` user, and the firewall's owner-match rules key on that uid, so its existence is asserted here rather than left to the package's postinst."

**Location:** `devcontainer-config/Dockerfile:48-52`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `useradd` assertion in the image and `init-firewall.sh` reading `id -u dnsmasq` into `-m owner --uid-owner` rules. Does not establish that the uid is stable across rebuilds (`useradd --system` picks the next free id).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

`RUN id -u dnsmasq >/dev/null 2>&1 || useradd --system … dnsmasq` (`Dockerfile:51-52`); the script reads `DNSMASQ_UID="$(id -u dnsmasq 2>/dev/null || true)"` and refuses a non-numeric or zero value (paraphrased — no quote available because the check spans the precondition block at `init-firewall.sh:397-401`, read in full by r2).

**Evidence:** `devcontainer-config/Dockerfile:51-52`, `devcontainer-config/init-firewall.sh:397-401`

---

## Claim 4: "root-owned and 0555 like the firewall script it belongs to (decision log #41)"

**Location:** `devcontainer-config/Dockerfile:386-388`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `cc-sni-proxy.py` is chowned root:root and chmodded 0555. Does not establish that `init-firewall.sh` has the same mode — it does not.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Verified (compound)
**Replicate annotations:** r3 (compound with the stdlib-only half): "every import in the proxy is a CPython standard-library module"

The proxy is root-owned 0555: `chown root:root /usr/local/bin/cc-sni-proxy.py && chmod 0555 /usr/local/bin/cc-sni-proxy.py` (`Dockerfile:410`). But the firewall script is set with `chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/link-claude-home.sh` (`Dockerfile:409`) — `+x` on the `COPY` mode (0755), never chowned in this `RUN`. Precise version: "root-owned and 0555 — stricter than the firewall script, which is `chmod +x`".

**Evidence:** `devcontainer-config/Dockerfile:409-410`

---

## Claim 5: "init-firewall.sh REDIRECTs every outbound tcp/443 connection that is NOT made by this proxy's own uid to 127.0.0.1:<port>"

**Location:** `devcontainer-config/cc-sni-proxy.py:4-5`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the nat REDIRECT of tcp/443 and the `ccproxy` exemption. Does not establish anything about udp/443 (QUIC) or IPv6, and omits the second exemption.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** none

Root is also exempt, which the module docstring — the first thing a reader meets — does not say:

```
iptables -t nat -A CC_SNI -m owner --uid-owner "$CCPROXY_UID" -j RETURN
iptables -t nat -A CC_SNI -m owner --uid-owner 0 -j RETURN
```
(`init-firewall.sh:883-884`; excerpt ends `:884`, enclosing SNI PROXY block continues to `:897` — read.) `init-firewall.sh:830-835` states the root exemption explicitly. Precise version: "…NOT made by this proxy's own uid or by root".

**Evidence:** `devcontainer-config/init-firewall.sh:883-886`, `:830-835`

---

## Claim 6: "the proxy … RESOLVES THE SNI NAME ITSELF and connects to that address on 443 … Step 3 is why a forged SNI cannot steer a connection: the original destination (SO_ORIGINAL_DST) is read for the log line only and is never connected to"

**Location:** `devcontainer-config/cc-sni-proxy.py:11-16`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the upstream address is derived solely from `getaddrinfo(sni, …, AF_INET)` and that `original_dst()`'s return value flows only into `log()` strings. Does not establish that the resolver answering that lookup is the filtering dnsmasq (r1: glibc consults `/etc/hosts` first via nsswitch), that the resolved address is itself trustworthy, that the ipset second check fires at the kernel (not exercised), nor anything about the port — the connect port is `args.upstream_port`.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that the resolver answering that lookup is the filtering dnsmasq (glibc consults `/etc/hosts` first via nsswitch, and `handle()` uses the loop's default `getaddrinfo`)" · r2: "does not establish that the resolved address is itself trustworthy (it is whatever the container resolver returns), nor that the ipset second check actually fires (kernel-level)" · r3: "delegated to the ipset and to dnsmasq"

All three replicates read `handle()` end to end (`cc-sni-proxy.py:168-196`): `orig` is computed by `original_dst()` and appears only in `log()` calls; the connection target is `ip = infos[0][4][0]` from `getaddrinfo(sni, upstream_port, family=socket.AF_INET, …)` (paraphrased — no quote available because the three-line sequence is split by the `try` block at `:181-186`; all replicates quote it in their reports).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:157-165`, `:168-196`

---

## Claim 7: "Resolution uses the container's resolver (/etc/resolv.conf — Docker's embedded DNS today, a filtering dnsmasq once that lands)"

**Location:** `devcontainer-config/cc-sni-proxy.py:20-21`
**Type:** Staleness / Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "today / once that lands" tense only. Does not dispute that resolution goes through the container's configured resolver, which remains true.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Stale · r3=Stale
**Replicate annotations:** r3: "what the proxy actually reaches today is dnsmasq, and not via `/etc/resolv.conf` at all: `CC_DNS` returns early only for the dnsmasq uid and uid 0 (`:682-683`), so the `ccproxy` uid falls through to the REDIRECT (`:684-685`)"

The filtering dnsmasq landed earlier in the same range (`d598bda`, merged as `1dbdabd`, two commits before `aa8dffc`). The firewall's own comment carries the current version: "Its name lookups go through the container resolver (the filtering dnsmasq above), so an SNI that is not allowlisted for DNS is doubly dead" (`init-firewall.sh:825-827`). Precise version: "Resolution goes to the container's filtering dnsmasq — this process's port-53 traffic is REDIRECTed there by the firewall — and is IPv4-only."

**Evidence:** `devcontainer-config/init-firewall.sh:656-678`, `:682-687`, `:825-827`

---

## Claim 8: "…and is IPv4-only, matching the IPv4-only ipset. Non-443 ports are not redirected here and stay IP+port-matched."

**Location:** `devcontainer-config/cc-sni-proxy.py:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `AF_INET` restriction in the proxy's lookup and the tcp/443-only nat redirect. Does not establish that IPv6 egress is blocked anywhere — it is not; `init-firewall.sh` installs no ip6tables rules at all, which the script states at `:510-512`, so the whole allowlist is unenforced over IPv6.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "IPv6 is unfiltered end to end (`init-firewall.sh:510-512`)"

`family=socket.AF_INET` at `cc-sni-proxy.py:183`; the only redirect jump is `-A OUTPUT -p tcp --dport 443 -j CC_SNI` (`init-firewall.sh:886`).

**Evidence:** `devcontainer-config/cc-sni-proxy.py:183`, `devcontainer-config/init-firewall.sh:886`, `:510-512`

---

## Claim 9: "Single file, stdlib only (python3.11 ships in the node:22 base — no apt package, no pip)"

**Location:** `devcontainer-config/cc-sni-proxy.py:24-25`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a `python3` at 3.11.x exists in the image without any Dockerfile-added Python package and that every import is stdlib. Does not establish that `#!/usr/bin/env python3` (`cc-sni-proxy.py:1`) resolves to it under the root PATH the firewall script runs with, nor that the image built from this Dockerfile (not built here) has it — the evidence is the same base distribution.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that the interpreter is at `/usr/bin/python3` specifically, nor that `#!/usr/bin/env python3` resolves to it under the root PATH" · r3: "does not establish that the image built from this Dockerfile has python3.11 — that was not built here"

All three executed `python3 --version` (3.11.x) and grepped the Dockerfile for python packages (none added); r1's log: `docs/reviews/execution-logs/r1-env-probe.log`.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:27-36`, `docs/reviews/execution-logs/r1-env-probe.log`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`

---

## Claim 10: "root-owned in the image and hashed by the launcher's trust manifest"

**Location:** `devcontainer-config/cc-sni-proxy.py:25`
**Type:** Invariant / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the manifest half only — the root-owned half is true (`Dockerfile:410`). Does not establish anything about the image's file permissions, which are correct.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "Practical consequence: a host-side rewrite of `devcontainer-config/cc-sni-proxy.py` would not change any hashed file and would not trip `check_manifest()`'s refusal at the next launch" · r1 (Goal-Alignment Escalate): "the new enforcement-relevant file `cc-sni-proxy.py` is outside the bless manifest, so add it to `enforcement_files()` in `devcontainer-config/cc-isolated.sh` (and re-bless) before relying on these changes; the docstring is currently describing a protection that does not exist"

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
(`devcontainer-config/cc-isolated.sh:52-64`; excerpt ends at the subshell's `sort`, enclosing `enforcement_files()` continues to `:65` — read.) `compute_manifest()` sha256sums only what that function emits (`cc-isolated.sh:67-78`) and `check_manifest()` compares that against `manifest.sha256` (`:88-103`). `cc-isolated.sh` was not touched in this range and a repo-wide grep for `cc-sni-proxy` finds no hit in it. The proxy's contents are covered only insofar as the Dockerfile *text* that `COPY`s it is hashed.

**Evidence:** `devcontainer-config/cc-isolated.sh:49-65`, `:67-78`, `:88-103`, `devcontainer-config/Dockerfile:389`, `:410`

---

## Claim 11: "`SO_ORIGINAL_DST = 80` — linux/netfilter_ipv4.h; not exposed by the socket module"

**Location:** `devcontainer-config/cc-sni-proxy.py:38`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the constant's value and its absence from CPython's `socket` module. Does not establish that the `getsockopt` call succeeds under a real REDIRECT on the container's kernel (`original_dst()` returns `"unknown"` on failure), nor that the `"!2xH4s8x"` unpack is correct on a big-endian host (the 2-byte `sin_family` skip is host-order).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: big-endian caveat above · r2+r3: "does not establish that the `getsockopt` call succeeds under the container's kernel (untested)"

**Evidence:** `devcontainer-config/cc-sni-proxy.py:38`, `:138-143`

---

## Claim 12: "`name` lines match exactly; `.zone` lines match the zone and every subdomain of it. Blank lines and #-comments are ignored."

**Location:** `devcontainer-config/cc-sni-proxy.py:123-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exact-match, zone-match-including-apex, comment stripping, blank-line skipping, and case-insensitivity on both sides (executed via `test/test_cc_sni_proxy.py`). Does not establish behaviour for degenerate lines: `..foo` is silently normalised to zone `foo` by `lstrip(".")` (r1), and a bare `.` becomes the empty-string zone — r2 reads `allows()` as then accepting any name ending in `.`, r3 as matching nothing; `init-firewall.sh` never generates either line.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "`..foo` silently normalises to `foo` as a zone" · r2: "a bare `.` becomes the empty string after `lstrip(".")`, and `allows()` would then accept any name ending in `.`" · r3: "a degenerate `.` line lands in `zones` as the empty string and matches nothing, which is harmless but undocumented" (r2 and r3 disagree on the degenerate-`.` consequence; neither line is ever generated)

**Evidence:** `devcontainer-config/cc-sni-proxy.py:120-140`, `test/test_cc_sni_proxy.py` (AllowlistSemantics), `docs/reviews/execution-logs/cfc-r2-pytests-abbd42d.txt`

---

## Claim 13: "Exit status is the contract init-firewall.sh relies on: 0 only once the child is LISTENING; anything else means 'no proxy'"

**Location:** `devcontainer-config/cc-sni-proxy.py:237-239`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `daemonize()` returns 0 on exactly one path, gated on a readiness byte the child writes strictly after `asyncio.start_server` has returned. Does not establish that the listening socket is reachable through the redirect (needs a live kernel), that a child which dies immediately after signalling ready is detected, or the `--daemon`-less path.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "a crash after `ready` is not signalled to the parent"

**Evidence:** `devcontainer-config/cc-sni-proxy.py:199-209`, `:240-287`

---

## Claim 14: "Close every other inherited fd: the caller's stdout is the devcontainer postStartCommand pipe, and a daemon holding it open would hang the launch."

**Location:** `devcontainer-config/cc-sni-proxy.py:264-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every fd above 2 other than the readiness-pipe write end is closed in the child and that fds 0/1/2 are redirected first; the caller is the `postStartCommand` chain (`devcontainer.json`). Does not establish the motivation (that an open pipe would hang the devcontainer CLI — a runtime property not checkable here), and the readiness fd `w` is closed only implicitly (`os.close(ready_fd)` in `serve()` on success; `os._exit(1)` on error).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "the claim's motivation is a runtime property of the devcontainer CLI, not checkable here" · r1: "`w` is closed later only implicitly"

**Evidence:** `devcontainer-config/cc-sni-proxy.py:258-272`, `:207`

---

## Claim 15: "This flag disables crash reporting ONLY. Do NOT reach for DISABLE_TELEMETRY, DO_NOT_TRACK, or CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: each disables the feature-flag evaluation that Remote Control depends on"

**Location:** `devcontainer-config/devcontainer.json:73-78`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that all three named variables disable the feature-flag evaluation Remote Control availability depends on and that `DISABLE_ERROR_REPORTING` is not among them (WebFetch of `code.claude.com/docs/en/remote-control.md` and `env-vars.md`, 2026-09-03, r2). Does not establish completeness of the list — the docs name a fourth variable, `DISABLE_GROWTHBOOK`, that the comment omits — nor that `DISABLE_ERROR_REPORTING` has no other side effect.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "the docs name a fourth variable, `DISABLE_GROWTHBOOK`, with the same effect, which the comment omits"

**Evidence:** `devcontainer-config/devcontainer.json:73-80`, WebFetch `https://code.claude.com/docs/en/remote-control.md` (2026-09-03)

---

## Claim 16: "The remaining telemetry events go to api.anthropic.com, which is irreducible anyway."

**Location:** `devcontainer-config/devcontainer.json:78-79` (same claim at `devcontainer-config/egress/base.txt:9-10`: "the remaining telemetry events ride api.anthropic.com, which is already irreducible")
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the destination claim. Does not contradict the practical conclusion that no additional allowlist entry is needed — none is, because the omitted host is firewalled.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r3: "`api.anthropic.com` carries telemetry event logging and is unavoidable — the 'irreducible' half is right; the documented operational-telemetry intake host is a different one" · r2 (compound, covering `:73-79` as one claim): "does not establish that `DISABLE_ERROR_REPORTING` is *sufficient* to stop every non-`api.anthropic.com` egress"

The documented network requirements name two Datadog intake hosts besides `api.anthropic.com`, and only one is switched off by `DISABLE_ERROR_REPORTING` (WebFetch of `https://code.claude.com/docs/en/network-config.md`, 2026-09-03):

> `http-intake.logs.us5.datadoghq.com` | Operational telemetry events … Optional: disable with `DISABLE_TELEMETRY` or `DO_NOT_TRACK`
> `browser-intake-us5-datadoghq.com` | Operational error reports … Optional: disable with `DISABLE_ERROR_REPORTING` or `DISABLE_TELEMETRY`

With only `DISABLE_ERROR_REPORTING` set (`devcontainer.json:80`), operational telemetry is still addressed to `http-intake.logs.us5.datadoghq.com`, which no profile lists; it is dropped by the terminal `-j REJECT` (`init-firewall.sh:905`) rather than not emitted. The comment reads as "nothing else is even tried"; the actual property is "nothing else gets through". Precise version: "the telemetry that still leaves the process rides `api.anthropic.com`; Claude Code also attempts `http-intake.logs.us5.datadoghq.com`, which the allowlist rejects."

**Evidence:** WebFetch `https://code.claude.com/docs/en/network-config.md` (2026-09-03); `devcontainer-config/devcontainer.json:80`, `devcontainer-config/egress/base.txt:9-10`, `devcontainer-config/init-firewall.sh:905`

---

## Claim 17: "sentry.io and statsig.com were removed 2026-09 (security review, finding 7): neither appears in the documented requirements"

**Location:** `devcontainer-config/egress/base.txt:5-7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of `sentry.io`, `statsig.com` (and `statsig.anthropic.com`) from the current documented network-access table and their removal from `base.txt`. Does not establish that Claude Code makes no request to either host at runtime — only that the docs no longer require them; `b04090c`'s Notes flag that as unverified and it remains so.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2 (side note): "`console.anthropic.com` is also no longer in that table" · r3 (Escalate): "`network-config.md` documents several required hosts absent from `base.txt` (`claude.com`, `downloads.claude.ai`, `mcp-proxy.anthropic.com`, `raw.githubusercontent.com`, `storage.googleapis.com`) — an allowlist-completeness question, not a doc defect"

**Evidence:** `devcontainer-config/egress/base.txt:1-31`, WebFetch `https://code.claude.com/docs/en/network-config.md` (2026-09-03)

---

## Claim 18: "The optional suffix is a comma-separated list of TCP ports; when absent the entry is admitted on tcp 443 only … init-firewall.sh rejects a line that does not parse, so a typo fails the rebuild loudly"

**Location:** `devcontainer-config/egress/base.txt:12-19`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-443 rule, the comma grammar, and hard failure on a malformed line (exercised via `--print-entries` with malformed inputs, r3). Does not establish that the rebuild fails at the point of use for every malformed shape — the hook shares the parse but not the firewall path (the bats suite covers that path with a stub).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

**Evidence:** `devcontainer-config/init-firewall.sh:105-133`, `:283-295`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 19: "OAuth token exchange/refresh (platform.claude.com — per the network-config docs; a missing entry surfaces as a mid-session re-login once the access token expires)"

**Location:** `devcontainer-config/egress/base.txt:22-24`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the documented purpose of `platform.claude.com` ("OAuth token exchange, refresh, and revocation also go to this host for claude.ai accounts"). Does not establish the stated symptom of omitting it — the docs describe a first-run connectivity-check failure, not specifically a mid-session re-login.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r3: "does not establish the stated *symptom* ('a mid-session re-login once the access token expires'), which the docs do not describe" · r2: "the docs' stated failure mode is 'The first-run setup connectivity check points here when it can't reach `api.anthropic.com` or `platform.claude.com`'"

All three agree the mechanism half is verbatim in the docs and the symptom half is the comment's own inference; r2 rated the unlabelled inference as an imprecision. Precise version: drop the parenthetical or mark it as inference.

**Evidence:** `devcontainer-config/egress/base.txt:21-28`, WebFetch `https://code.claude.com/docs/en/network-config.md` (2026-09-03)

---

## Claim 20: "SCOPE: the `:11434` suffix is load-bearing … this admits exactly the model server and nothing else listening on the host's Docker-facing interface … do not drop the suffix, which would silently fall back to 443"

**Location:** `devcontainer-config/egress/llm.txt:19-24`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the entry parses to tcp 11434 alone, that a suffix-less entry defaults to 443, and the `dst,dst` ipset match. Does not establish that only the model server listens on 11434 (a host-side property), that the host is unreachable on other ports by another path (another profile entry, the gateway:53 accept), that the entry is admitted under Docker Desktop (`host.docker.internal` must resolve for phase A), nor IPv6/UDP paths to the same host (not covered).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that the entry is admitted at all under Docker Desktop — `host.docker.internal` must resolve for the phase-A `dig` to produce an ipset member" · r2: "does not establish that the *host* is unreachable on other ports by some other path" · r3: "no `ip6tables` rules; the ipset holds TCP members only"

**Evidence:** `devcontainer-config/egress/llm.txt:19-24`, `devcontainer-config/init-firewall.sh:105-133`, `docs/reviews/execution-logs/r1-print-hooks.log`

---

## Claim 21: "both halves are constrained to their literal grammar (hostname labels; 1-65535 integers) … 10#: a leading zero would otherwise make bash read the number as octal … Tab-separated, because IFS is \n\t in this script"

**Location:** `devcontainer-config/init-firewall.sh:105-133`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers grammar enforcement (both halves are label characters / digits only after the guards), the octal rationale, and that every consumer of the tab-separated output splits correctly under `IFS=$'\n\t'` (the `read -r domain ports` loops and each `tr ',' '\n'` split). Does not establish canonical-form normalisation: `good.example:0443` passes validation (10#0443 = 443) and is emitted **verbatim** as `tcp:0443` to `ipset add`; a bare single label with no dot passes the domain grammar.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "a zero-padded port reaches `ipset add` as written (`tcp:0443`) — the raw string, not the `10#` value, is what reaches the command line" · r1: "does not establish that the domain grammar excludes a name that `dig` would treat specially (a bare label with no dot passes)"

**Evidence:** `devcontainer-config/init-firewall.sh:108-133`, `:283-295`, `:346-386`, `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`

---

## Claim 22a: "A `server=/github.com/...` line covers github.com AND every subdomain (api., codeload., ssh., pkg., ...); likewise githubusercontent.com covers objects./raw./media./github-cloud."

**Location:** `devcontainer-config/init-firewall.sh:147-151`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers dnsmasq's documented suffix semantics for `server=/domain/addr` and that `GITHUB_DNS_ZONES` contains exactly those two zones (`:154`; executed hook emitted `server=/github.com/127.0.0.11` and `server=/githubusercontent.com/127.0.0.11`). Does not establish observed dnsmasq behaviour — the daemon is not installed in the sandbox.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (compound; imprecision attributed by r1 to the 22b half) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "The dnsmasq semantics half is correct" · r2+r3: "dnsmasq is not installed in this sandbox, so the matching was not executed"

**Evidence:** `devcontainer-config/init-firewall.sh:147-154`, `docs/reviews/execution-logs/r1-print-hooks.log`

---

## Claim 22b: "Anything else on GitHub (ghcr.io, github.dev) is not in the CIDR ingest either, so it stays unresolved AND unroutable."

**Location:** `devcontainer-config/init-firewall.sh:152-153`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the script ingests only `.web + .api + .git` (`jq -r '(.web + .api + .git)[]'`, `:332`) and that the meta document carries `packages`/`pages`/`actions` under keys it does not read (r3 WebFetched `api.github.com/meta`). Does not establish "unroutable": the meta keys are not documented as disjoint, and an address serving `ghcr.io` that also falls inside `.web/.api/.git` would be reachable on 443/22 by IP — the name will not resolve and the SNI proxy would reject it.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2: "does not establish that the CIDR ingest excludes `ghcr.io`/`github.dev` (that depends on GitHub's live `/meta` response)" · r1: "`ghcr.io` addresses may or may not fall inside `.web/.api/.git`, and the script never checks"

Precise version: "…is outside the `.web + .api + .git` keys this script ingests, so it stays unresolved and is not deliberately routed — though the meta keys are not guaranteed disjoint, so an incidental address overlap is not excluded."

**Evidence:** `devcontainer-config/init-firewall.sh:326`, `:332`, `:744-745`, WebFetch `https://api.github.com/meta` (r3, 2026-09-03)

---

## Claim 23a: "there is no bare `server=` line and `no-resolv` stops dnsmasq reading /etc/resolv.conf, so the daemon has no default upstream at all … With NO upstream … the config has zero server lines"

**Location:** `devcontainer-config/init-firewall.sh:161-173`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the generated config's shape in both the with-upstream and no-upstream cases (`--print-dnsmasq-conf` executed against a real and an IPv6-only resolv.conf). Does not establish dnsmasq's runtime response to a name with no matching `server=` line — Claim 23b.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none beyond the 23b split

**Evidence:** `devcontainer-config/init-firewall.sh:174-206`, `docs/reviews/execution-logs/r1-print-hooks.log`, `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`

---

## Claim 23b: "A name that matches no `server=/<domain>/` line has nowhere to go and dnsmasq answers REFUSED — it is never forwarded"

**Location:** `devcontainer-config/init-firewall.sh:163-166`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing positively about the response code. The security property that matters — *not forwarded* — follows from 23a (no upstream exists to forward to) whether the answer is REFUSED or SERVFAIL; only the RCODE wording is unverified.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r2: "Blocker: `dnsmasq` is not installed in the review sandbox and there is no Docker or root to run one. Verifying needs a live container and `dig @127.0.0.1 not-allowlisted.example` against the generated config" · r3: "`d598bda`'s body already scopes this: 'dnsmasq REFUSED-with-no-servers behaviour ... asserted from documentation ... Needs a live-container check before bless'" · r1 (compound, static half): "does not establish dnsmasq's on-the-wire RCODE, which was not exercised"

**Evidence:** `devcontainer-config/init-firewall.sh:161-173`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`, `git log bd41aef..HEAD` (`d598bda` Notes)

---

## Claim 24: "Profile entries may carry a `:port` suffix …; the resolver only wants the name. Then refuse anything that is not a plain hostname: a `/` or `#` here would be read by dnsmasq as config syntax"

**Location:** `devcontainer-config/init-firewall.sh:192-196`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the `:port` strip precedes the hostname regex and that a non-hostname is warned about and omitted rather than emitted as config (executed with a crafted profile). Does not establish that the omitted name is unreachable at the IP layer (the ipset is populated independently in phase A), and the regex requires at least one dot — stricter than `parse_entry`'s grammar — so a single-label profile entry silently gets no resolver line while still being ipset-admitted.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "a single-label profile entry silently gets no resolver line while still being ipset-admitted" · r2: "it is omitted from DNS only; the ipset is populated independently in phase A" · r3: "it is an allowlist regex, which is stronger than enumeration"

**Evidence:** `devcontainer-config/init-firewall.sh:189-204`, `docs/reviews/execution-logs/r3-hooks.log`

---

## Claim 25: "The policy calls are VERIFIED, not trusted … the trap re-reads the live policies with `iptables -S` afterwards and says which of two very different states the container is in"

**Location:** `devcontainer-config/init-firewall.sh:237-244`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read-back, the per-chain OPEN alarm, and the ordering of the two mutually exclusive messages relative to the `-P` calls (executed via the bats suite's `FAIL_POLICY` stub, r2). Does not establish real netfilter behaviour (no privileged container), that the trap fires on every abort path (that is the `INT TERM HUP QUIT` converter at `:272`), or that `iptables -S` reflects a policy the kernel silently ignored. r3: a failed read-back yields an empty string, which makes every chain look non-DROP — it fails toward the alarm.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "`policies=\"$(iptables -w 5 -S 2>/dev/null || true)\"` yields an empty string on failure, which makes every chain look non-DROP — i.e. it fails toward the alarm, the safe direction"

**Evidence:** `devcontainer-config/init-firewall.sh:237-272`, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`

---

## Claim 26: "Close the window BEFORE it opens: set the DROP policies first, then flush. Chain policies survive `iptables -F` (a flush removes rules, not policies)"

**Location:** `devcontainer-config/init-firewall.sh:462-471`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the source-level ordering (three `-P … DROP` before every `-F`) and the documented netfilter semantics that a flush clears rules but not the chain policy. Does not establish kernel behaviour by execution — no privileged container (`iptables -S` here returns "you must be root").
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish kernel behaviour under the container's nf_tables backend" · r3: "which the `6244ebf` commit message itself concedes"

**Evidence:** `devcontainer-config/init-firewall.sh:462-483`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`

---

## Claim 27: "Flush existing rules and delete existing ipsets (policies set above persist)" — the re-run recreates `CC_DNS`, `CC_DNS_GUARD`, `CC_SNI`, `CC_SNI_GUARD` without "chain already exists"

**Location:** `devcontainer-config/init-firewall.sh:476-483`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that phase B's `iptables -F; -X` and `-t nat -F; -t nat -X` delete all four `CC_*` chains before the bare `-N` calls re-create them, so a second run cannot hit "chain already exists" under `set -e` and cannot spuriously brick the container; the script's own Docker-chain recreation uses `|| true` (`:488-489`), consistent with that reasoning. Does not establish idempotency against a chain created by something other than this script between runs — nothing else creates these names.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "the load-bearing question of whether a second run's `iptables -N CC_DNS` fails … It does not" · r2: "covers … the iptables/ipset objects a re-run recreates"

**Evidence:** `devcontainer-config/init-firewall.sh:476-489`, `:678-690`, `:880-897`

---

## Claim 28: "Docker's embedded resolver is DNAT'd off port 53 in nat OUTPUT before filter OUTPUT sees it, so a --dport 53 filter rule would not match that traffic regardless"

**Location:** `devcontainer-config/init-firewall.sh:561-563` (paired guard rationale at `:626-635`)
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing positively about Docker's DNAT target port. The netfilter half (nat OUTPUT traversed before filter OUTPUT for locally generated packets) is standard and not in question; unverified is that Docker's rule rewrites the *port* rather than only the address. The design does not depend on it in detail: the all-ports guard on 127.0.0.11 (`:720`) subsumes the port-53 case either way.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Unverifiable
**Replicate annotations:** r3: "the script only captures whatever rules exist (`iptables-save -t nat | grep "127\.0\.0\.11"`, `:460`) without inspecting their targets, so nothing in the repository records the DNAT's shape. Blocker: needs a live container" · r2: "does not establish that Docker's DNAT is present on every runtime — the restore at `:486-493` is conditional on the pre-flush capture being non-empty" · r1: "does not establish the netfilter traversal order by execution"

**Evidence:** `devcontainer-config/init-firewall.sh:459-460`, `:486-493`, `:626-635`, `:720`

---

## Claim 29: "The nat rules are INSERTED at position 1, ahead of the `-d 127.0.0.11 -j DOCKER_OUTPUT` jump restored earlier"

**Location:** `devcontainer-config/init-firewall.sh:637-641`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rule ordering within nat OUTPUT: the two `CC_DNS` jumps (`-I OUTPUT 1`, `:686-687`) sit ahead of every Docker rule restored earlier in the same run (`:486-493`). Does not establish the order between the two `CC_DNS` jumps (udp inserted second, so it ends up first — immaterial, disjoint protocols), the content of the restored rules (replayed verbatim from a capture), nor that `CC_SNI` enjoys the same precedence — it does not and does not need to (nothing earlier in nat OUTPUT matches tcp/443).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "`CC_SNI` does not enjoy the same precedence — it does not, and does not need to" · r2: "the only prior insertions are the two port-53 rules at `:686-687` and the restored Docker 127.0.0.11:53 DNAT rules at `:490`"

**Evidence:** `devcontainer-config/init-firewall.sh:486-493`, `:637-641`, `:686-687`, `:886`

---

## Claim 30: "None of the base zones (api.anthropic.com, claude.ai, console.anthropic.com, sentry.io, statsig.com, registry.npmjs.org, github.com, githubusercontent.com) hand out delegations to third parties"

**Location:** `devcontainer-config/init-firewall.sh:648-651`
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the enumeration only. Does not establish or refute the delegation property itself for the zones that are current.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "The SNI block's parallel residual note already reflects the removal correctly ('base no longer carries one', `:850-851`), so the drift is confined to this one list"

The list names `sentry.io` and `statsig.com`, which this range removed from `base.txt`, and omits `platform.claude.com`, which it added. Executing `--print-entries` against the shipped profile gives the current base set: `api.anthropic.com`, `claude.ai`, `console.anthropic.com`, `platform.claude.com`, `registry.npmjs.org` (each `<TAB>443`), plus the two `GITHUB_DNS_ZONES`. Precise version: "(api.anthropic.com, claude.ai, console.anthropic.com, platform.claude.com, registry.npmjs.org, github.com, githubusercontent.com)".

**Evidence:** `devcontainer-config/init-firewall.sh:648-651`, `:154`, `:850-851`, `devcontainer-config/egress/base.txt:5-7`, `:25-31`, `docs/reviews/execution-logs/r1-print-hooks.log`

---

## Claim 31: "Idempotent restart: kill by pidfile, then start exactly one instance." (dnsmasq) / "--daemon: forks, drops to --user, binds, and exits 0 only once LISTENING (a prior instance named by the pidfile is terminated first, so re-runs are idempotent)" (proxy)

**Location:** `devcontainer-config/init-firewall.sh:661-664`, `:871-872`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both daemons' pidfile stop-then-start paths, the post-start liveness check for dnsmasq, and (with Claim 27) the iptables/ipset objects a re-run recreates (bats re-run test, r2). Does not establish behaviour when the pidfile is missing or names a pid that is not `dnsmasq`/`cc-sni-proxy`: dnsmasq additionally sweeps by uid (`pkill -x -U`), the proxy does not — `stop_prior` leaves the orphan running, the new child's bind fails, and the run fails closed (`exit 1`) rather than double-starting: safe, but not "restarted cleanly".
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "idempotency when the pidfile is missing or wrong: `stop_prior` then leaves the orphan running, the new child's bind fails, and the run fails closed (`exit 1`) rather than double-starting" · r1+r2: "the proxy has no uid sweep, only the pidfile path"

**Evidence:** `devcontainer-config/init-firewall.sh:404-423`, `:661-678`, `:871-878`, `devcontainer-config/cc-sni-proxy.py:212-229`, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`

---

## Claim 32: "NOTE: no inbound `--sport 53` accept. DNS replies to the scoped OUTPUT rules above are already admitted by the `INPUT -m state --state ESTABLISHED,RELATED` accept"

**Location:** `devcontainer-config/init-firewall.sh:698-703`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of any `--sport 53` rule and the presence of the INPUT ESTABLISHED,RELATED accept (bats: zero `--sport 53` rules emitted). Does not establish that conntrack associates every DNS reply — including redirected UDP flows — with its request on the target kernel.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r1: "does not establish that conntrack tracks the redirected UDP flows correctly on the target kernel"

**Evidence:** `devcontainer-config/init-firewall.sh:698-703`, `:802`, `docs/reviews/execution-logs/r1-bats.log`

---

## Claim 33: "127.0.0.11 on ALL ports — the embedded resolver's real port is not 53 — and any port-53 flow that is not to dnsmasq at 127.0.0.1; both RETURN for dnsmasq/root" (these must precede the loopback accept)

**Location:** `devcontainer-config/init-firewall.sh:717-722`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three guard jumps, their all-ports/port-53 shapes, the RETURN-for-exempt-uids structure of `CC_DNS_GUARD`, and that all three are appended before `-o lo -j ACCEPT`. Does not establish Docker's DNAT behaviour that motivates the all-ports form — Claim 28.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound with Claim 28) · r2=Verified (compound with Claim 28) · r3=Verified
**Replicate annotations:** none beyond Claim 28's

**Evidence:** `devcontainer-config/init-firewall.sh:690-697`, `:717-723`

---

## Claim 34: "There is no inbound counterpart: replies are ESTABLISHED,RELATED, which the INPUT accept below admits, and nothing on the bridge needs to OPEN a connection into the sandbox."

**Location:** `devcontainer-config/init-firewall.sh:775-777`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no INPUT rule references the bridge network or the gateway address and that the ESTABLISHED,RELATED accept exists. Does not establish the design assertion ("nothing on the bridge needs to open a connection") — intent, not a checkable property — nor that no other inbound path exists (the `-i lo` accept at `:716` and the ESTABLISHED,RELATED accept at `:802` remain).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that no *other* inbound path exists"

**Evidence:** `devcontainer-config/init-firewall.sh:716`, `:775-783`, `:802`

---

## Claim 35: "nat OUTPUT REDIRECTs every tcp/443 connection that is not the proxy's own (and not root's) to it. The proxy reads the ClientHello, admits the connection only if the SNI is on the allowlist written here, RESOLVES THE SNI NAME ITSELF and connects there, then splices bytes. Nothing is decrypted … Its name lookups go through the container resolver (the filtering dnsmasq above)"

**Location:** `devcontainer-config/init-firewall.sh:817-827`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the chain construction, the two owner exemptions, the peek/allow/resolve/splice sequence with no TLS termination (cross-checked in Claim 6), and that `ccproxy` is not exempt from the DNS redirect so its lookups do traverse dnsmasq. Does not establish that the kernel performs the REDIRECT on locally generated packets under Docker Desktop's kernel, that `xt_owner` is available in nat OUTPUT there, or that the proxy's own egress is constrained by the ipset at the kernel level beyond rule ordering — none exercisable in this sandbox. Does not cover udp/443 (QUIC: not redirected, though denied downstream because every ipset member is `tcp:<port>`) or IPv6 (unfiltered).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that the kernel performs the REDIRECT on locally generated packets under Docker Desktop's kernel, nor that `xt_owner` is available in nat OUTPUT there" · r3: "UDP/443 (QUIC) — not redirected, though it is denied downstream because every ipset member is `tcp:<port>`" · r2: "does not establish that the proxy's own egress is actually constrained by the ipset at the kernel level"

**Evidence:** `devcontainer-config/init-firewall.sh:817-835`, `:880-897`, `devcontainer-config/cc-sni-proxy.py:168-196`

---

## Claim 36: "GitHub is admitted by CIDR (phase A) rather than by name; these are the zones git, gh and git-lfs actually contact over 443." (immediately above `.github.com` / `.githubusercontent.com` / `.githubassets.com`)

**Location:** `devcontainer-config/init-firewall.sh:864-868`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the third entry, `.githubassets.com`; the claim is accurate for `.github.com` and `.githubusercontent.com`, which git/gh/git-lfs do contact and which the resolver serves. The repo-internal half (the entry is inert because the resolver has no `server=` line for it) is fully established; the "which hosts `gh` contacts" half rests on external knowledge — hence Medium.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=—
**Replicate annotations:** r2: "`test/init-firewall-rules.bats:727` asserts the current (inert) entry, so a fix is a real change, not a comment edit" · r1: "`githubassets.com` is GitHub's web-UI static asset host, not a host the git/gh/git-lfs CLIs contact" · r1+r2: "the file's own companion comment at `:150-153` lists only two zones for the same three tools, so the two comments disagree"

`.githubassets.com` is written into the SNI allowlist —

```
echo ".github.com"
echo ".githubusercontent.com"
echo ".githubassets.com"
} > "$SNI_ALLOWLIST"
```
(`init-firewall.sh:866-869`; excerpt ends `:869`, the SNI block continues to `:897` — read) — but `GITHUB_DNS_ZONES="github.com githubusercontent.com"` (`:154`). Both replicates executed `--print-dnsmasq-conf` and confirmed no `githubassets` line is generated, so no client using the container resolver can obtain an address for `*.githubassets.com` and the SNI entry can never be exercised. Precise version: either drop `.githubassets.com` from the SNI allowlist, or add `githubassets.com` to `GITHUB_DNS_ZONES` and correct the attribution to name the web UI; `test/init-firewall-rules.bats:727` needs updating either way.

**Evidence:** `devcontainer-config/init-firewall.sh:150-154`, `:864-869`, `test/init-firewall-rules.bats:727`, `docs/reviews/execution-logs/r1-print-hooks.log`, `docs/reviews/execution-logs/cfc-r2-print-hooks-abbd42d.txt`

---

## Claim 37: "SNI proxy probes, run AS NODE so they traverse the redirect (root is exempt)." / "Negative: an address that IS in the ipset, asked for with a name that is NOT allowlisted, must be refused"

**Location:** `devcontainer-config/init-firewall.sh:926-943`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both probes run as `node` via `runuser`, that `runuser` exists (`/usr/sbin/runuser`, executed), and that `ANTHROPIC_PROBE_IP` is non-empty on every path that reaches the probe (initialised at `:347`, set on the first A record of `api.anthropic.com` at `:380-382` under a `-z` guard, and an unresolved `api.anthropic.com` is a hard `exit 1` at `:364-367`). Does not establish that the negative probe distinguishes an SNI refusal from any other curl failure — it does not: any non-zero curl exit lands in the else branch and prints "verification passed"; a container without the redirect would also produce a failing curl and thus a passing check (r3).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r3: "does not establish that the probe *fails* for the intended reason under a live kernel — a container without the redirect would also produce a failing curl and thus a passing check" · r2: "The positive probe at `:928` bounds this in practice (it must succeed through the same proxy) … Precise version would grep `$SNI_LOG` for a `REJECT sni=not-allowlisted.invalid` line" · r2 (Escalate): "a verification-strength issue rather than a documentation issue; the security critic should decide whether a false-pass there matters given the positive probe runs first" · r1: "two bats tests do exercise the failure directions with a stub, both passing"

```
if runuser -u node -- curl --connect-timeout 5 --max-time 15 \
        --resolve "not-allowlisted.invalid:443:$ANTHROPIC_PROBE_IP" https://not-allowlisted.invalid/ >/dev/null 2>&1; then
    echo "ERROR: … a non-allowlisted SNI reached an allowlisted address"
```
(`init-firewall.sh:937-939`; enclosing `if` continues through `else`/`fi` at `:941-943` — read.) Precise version: "…must not connect — the probe does not distinguish an SNI refusal from other failure modes."

**Evidence:** `devcontainer-config/init-firewall.sh:347`, `:364-367`, `:380-382`, `:926-943`, `docs/reviews/execution-logs/r1-env-probe.log`, `docs/reviews/execution-logs/cfc-r2-env-abbd42d.txt`

---

## Claim 38a: "the proxy logs every decision to `/run/cc-sni-proxy/proxy.log` as `ALLOW`, `REJECT sni=... not in allowlist`, or `FAIL`"

**Location:** `guides/cc-isolated-usage.md:299-305`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the log path (`--log` default at `cc-sni-proxy.py:296`; `SNI_LOG="$SNI_RUN_DIR/proxy.log"` at `init-firewall.sh:438-441`, passed at `:875`; fds 1 and 2 dup'd onto it) and the three verb tokens, which match `log()` calls at `cc-sni-proxy.py:176`, `:179`, `:188`, `:190`. Does not establish that the three shapes are exhaustive — a ClientHello that cannot be parsed logs a fourth shape, `REJECT orig_dst=<...>: <error>`, with no `sni=` field, which is the line a reader debugging "connection closes immediately" is most likely to see when the client speaks something other than TLS.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (compound; imprecision attributed to 38b) · r2=Mostly accurate (compound; imprecisions attributed to 38b and 38c) · r3=Verified
**Replicate annotations:** r1+r3: "a fourth shape, `REJECT orig_dst=…` with no `sni=` field, is not mentioned"

**Evidence:** `devcontainer-config/cc-sni-proxy.py:168-196`, `:296`, `devcontainer-config/init-firewall.sh:438-441`, `:875`

---

## Claim 38b: "`FAIL` (the name resolved to an address the ipset does not admit)"

**Location:** `guides/cc-isolated-usage.md:301`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the case the gloss names, which is one of the causes. Does not establish that it is the only one: the same `except (OSError, asyncio.TimeoutError)` covers both `getaddrinfo` and `open_connection` (`cc-sni-proxy.py:181-189`), so a DNS refusal from the filtering resolver (`socket.gaierror`, an `OSError` subclass) and an upstream connect timeout also emit `FAIL`. The proxy's own text hedges ("resolved address not in the ipset?"); the guide drops the hedge.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none beyond the shared finding

Precise version: "`FAIL` (the name could not be resolved, or the address it resolved to could not be connected to — typically because the ipset does not admit it)."

**Evidence:** `devcontainer-config/cc-sni-proxy.py:181-189`, `guides/cc-isolated-usage.md:299-305`

---

## Claim 38c: "Root inside the container. The firewall script's own fetch and probes run as root and bypass the redirect; the agent runs as `node` and does not."

**Location:** `guides/cc-isolated-usage.md:296-297`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the root exemption and that the agent (`node`) is subject to the redirect. Does not hold for "probes" without qualification: the two general probes (`example.com` at `:911`, `api.github.com/zen` at `:919`) run as root, but the two SNI probes are deliberately `runuser -u node -- curl …` (`:928`, `:937`) so that they do traverse the redirect.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "the list item's headline point — root bypasses the redirect, the agent does not — is correct; the supporting detail is not"

Precise version: "…its two general reachability probes run as root and bypass the redirect; its two SNI probes are run as `node` on purpose so they don't."

**Evidence:** `guides/cc-isolated-usage.md:294-297`, `devcontainer-config/init-firewall.sh:909-943`

---

## Claim 39: decision-log rows 39–41 — "replaced by `OUTPUT -d <gateway> --dport 53` (udp+tcp) with no inbound counterpart"; "TCP only, default 443, validated — a malformed line aborts pre-flush and fails closed"; "Guarded by 7 new bats tests" (39); "verified by 10 new command-sequence bats tests" (40); "Guarded by 10 bats tests + 13 Python unit tests" (41)

**Location:** `docs/decisions/log.md:57`, `:60-62`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule replacement, the absence of an inbound counterpart, the TCP-only grammar and pre-flush abort, and the per-commit added-test counts (7 by `f1443c5`, 10 by `d598bda`, 10 + 13 by `aa8dffc`, all passing at HEAD). Does not mention that the surviving gateway rules were subsequently owner-scoped by the resolver commit (a narrowing, not a contradiction); does not establish coverage adequacy or kernel behaviour — the tests drive stubbed `iptables`/`ipset`/`dig`/`dnsmasq` binaries, as the rows themselves say.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "the surviving gateway rules were subsequently owner-scoped to the dnsmasq uid and root by the later resolver commit" · r2+r3: "the tests drive stubbed binaries"

**Evidence:** `docs/decisions/log.md:57-62`, `devcontainer-config/init-firewall.sh:775-783`, `docs/reviews/execution-logs/r1-bats.log`, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`

---

## Claim 40a: "98/98 bats + 13/13 python unit tests; shellcheck clean" (aa8dffc) · "77/77 pass" (b04090c) · "75/75 across both suites" (d598bda) · "88/88 bats pass" (1dbdabd)

**Location:** commit messages in `bd41aef..HEAD`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two suites named in the review brief and `shellcheck -S warning` on `init-firewall.sh` at HEAD (`1..98`, 98 ok, exit 0; "Ran 13 tests … OK"; shellcheck no output, exit 0), and the earlier per-commit counts reconciled against `@test` block counts at each commit. Does not establish that "98/98" covers every bats file in the repo, nor that a wider shellcheck sweep is clean.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Stale (compound; carried by the d598bda row reference, Claim 40b) · r3=Verified
**Replicate annotations:** r2: "Counts, all confirmed"

**Evidence:** `docs/reviews/execution-logs/r1-bats.log`, `docs/reviews/execution-logs/cfc-r2-bats-abbd42d.txt`, `docs/reviews/execution-logs/cfc-r2-pytests-abbd42d.txt`, `docs/reviews/execution-logs/cfc-r2-shellcheck-abbd42d.txt`

---

## Claim 40b: "docs/decisions/log.md: row 39 records the decision and the REDIRECT-vs-resolv.conf choice."

**Location:** commit message `d598bda` (body)
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row number as read against HEAD. Does not impugn the commit at the time it was written — the row was 39 in its own worktree; the merge commit `1dbdabd` records the renumbering ("renumbered the branch's decision-log row to #40").
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** r3: "Per this project's own tiering rule (`docs/decisions/log.md` row 32, item T: immutable already-merged commit-message claims → override log not 🔴), this is an override-log item, not a blocking finding" · r1: "Commit messages are immutable, so the actionable half of this is Claim 2's Dockerfile comment"

**Evidence:** `git show -s d598bda`, `git show -s 1dbdabd`, `docs/decisions/log.md:57`, `:62`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`devcontainer-config/cc-sni-proxy.py:25`): the proxy is not in `enforcement_files()` (`cc-isolated.sh:52-64`), so it is not hashed by the bless manifest; the docstring describes a protection that does not exist. Fix: add `cc-sni-proxy.py` to `enforcement_files()` and re-bless. (High confidence, single replicate.)
- **Claim 16** (`devcontainer-config/devcontainer.json:78-79`, `egress/base.txt:9-10`): operational telemetry is still addressed to `http-intake.logs.us5.datadoghq.com` and dropped by the firewall; it does not "go to api.anthropic.com". Comment-only consequence. (High confidence; r3 rated it Mostly accurate.)
- **Claim 36** (`devcontainer-config/init-firewall.sh:864-868`): `.githubassets.com` is SNI-allowlisted but has no resolver zone, so it is dead config, and the attribution to git/gh/git-lfs contradicts `:150-153`. Fix touches `test/init-firewall-rules.bats:727`. (Medium confidence, two replicates.)

### Stale
- **Claim 2** (`devcontainer-config/Dockerfile:47-48`): "decision log #39" → #40.
- **Claim 7** (`devcontainer-config/cc-sni-proxy.py:20-21`): "a filtering dnsmasq once that lands" — it landed in this range; the proxy's lookups are REDIRECTed to it.
- **Claim 30** (`devcontainer-config/init-firewall.sh:648-651`): base-zone list still names sentry.io/statsig.com and omits platform.claude.com.
- **Claim 40b** (commit `d598bda`): row 39 → 40; immutable, route to the override log per decision 031.

### Mostly Accurate
- **Claim 4** (`Dockerfile:386-388`): the firewall script is `chmod +x`, not 0555.
- **Claim 5** (`cc-sni-proxy.py:4-5`): root is also exempt from the redirect.
- **Claim 19** (`base.txt:22-24`): the "mid-session re-login" symptom is inference, not documented.
- **Claim 22b** (`init-firewall.sh:152-153`): "unroutable" is asserted; the meta keys are not guaranteed disjoint.
- **Claim 37** (`init-firewall.sh:926-943`): the negative SNI probe passes on any curl failure, not specifically a proxy refusal.
- **Claim 38b** (`guides/cc-isolated-usage.md:301`): `FAIL` also covers DNS refusal and connect timeout.
- **Claim 38c** (`guides/cc-isolated-usage.md:296-297`): the two SNI probes run as `node`, not root.

### Unverifiable
- **Claim 1** (`Dockerfile:44-46`): Debian package split — no package metadata reachable from the sandbox.
- **Claim 23b** (`init-firewall.sh:163-166`): dnsmasq's REFUSED RCODE — dnsmasq not installed; needs a live container (already tracked in `docs/working/questions.md`).
- **Claim 28** (`init-firewall.sh:561-563`): Docker's DNAT rewriting the port — needs a live container; the all-ports guard subsumes it either way.

## Escalations

| # | Entry | `path:line` | Raised by | Addressee |
|---|---|---|---|---|
| E1 | `cc-sni-proxy.py` is outside the bless manifest; add to `enforcement_files()` and re-bless before relying on these changes (Claim 10) | `devcontainer-config/cc-isolated.sh:52-64` | r1 | security-reviewer, architecture-review |
| E2 | `.githubassets.com` is dead config (SNI-allowlisted, never resolvable); decide add-zone vs drop; fix touches a pinned bats assertion (Claim 36) | `devcontainer-config/init-firewall.sh:864-868`, `test/init-firewall-rules.bats:727` | r1, r2 | orchestrator (author action) |
| E3 | Negative SNI probe passes on any curl failure — verification-strength question; does a false pass matter given the positive probe runs first? (Claim 37) | `devcontainer-config/init-firewall.sh:937-943` | r2 | security-reviewer |
| E4 | `console.anthropic.com` remains in `base.txt` though the page base.txt cites as source of truth no longer lists it; and `network-config.md` lists required hosts absent from base (`claude.com`, `downloads.claude.ai`, `mcp-proxy.anthropic.com`, `raw.githubusercontent.com`, `storage.googleapis.com`) — allowlist-completeness question | `devcontainer-config/egress/base.txt:25-31` | r2, r3 | orchestrator (author decision) |
| E5 | Three claims (1, 23b, 28) reduce to the live privileged-container check the `d598bda`/`aa8dffc` commit messages already list as a pre-`--bless` requirement; carry forward, do not treat as closed | `devcontainer-config/init-firewall.sh:163-166`, `:561-563` | r2, r3 | orchestrator |
| E6 | Decision-log row numbers collide when appended from parallel worktrees (Claims 2, 30, 40b); process note | `docs/decisions/log.md` | r1 | orchestrator |
| E7 | Code-quality observations recorded in Scope fields, not raised as findings: `parse_entry` emits a zero-padded port verbatim to `ipset add` (Claim 21); `Allowlist.load` maps a bare `.` line to an empty zone (Claim 12); single-label entries get an ipset member but no resolver line (Claim 24) | `devcontainer-config/init-firewall.sh:108-133`, `cc-sni-proxy.py:120-140` | r1, r2, r3 | security-reviewer, api-consistency-reviewer |

## Verdict stability

- **Total clusters:** 44 (40 base claims; 4 split into sub-claims where replicates diverged on a compound sentence: 22a/b, 23a/b, 38a/b/c, 40a/b).
- **Clusters where all reporting replicates agreed:** 36 (counting a compound verdict whose text attributes the imprecision to a sibling sub-claim as agreement on the sub-claim it did not fault: 22a, 38a, 40a).
- **Clusters where verdicts disagreed (8):**
  - Claim 1 — r1=Verified · r2=Verified · r3=Unverifiable (external package contents; r3 tried and failed to reach metadata)
  - Claim 4 — r1=Mostly accurate · r3=Verified (compound)
  - Claim 16 — r1=Incorrect · r2=Verified (compound) · r3=Mostly accurate (same evidence, different threshold for "misleads a reader")
  - Claim 19 — r1=Verified · r2=Mostly accurate · r3=Verified (unlabelled inference in a parenthetical)
  - Claim 22b — r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 23b — r1=Verified (compound) · r2=Unverifiable · r3=Unverifiable (r1 rated the static half Verified despite noting it was unexercised)
  - Claim 28 — r1=Verified · r2=Verified · r3=Unverifiable (Docker DNAT port rewrite; needs a live container)
  - Claim 37 — r1=Mostly accurate · r2=Mostly accurate · r3=Verified
- **Agreement rate:** 36/44 = 82%. Of the three Incorrect verdicts, two are single-replicate detections (Claims 10 and 16 at High confidence — Claim 16 was seen by all three but only r1 called it Incorrect) and one is two-replicate (Claim 36). The disagreements concentrate where one replicate insisted on execution for an external-system property (Claims 1, 23b, 28) or drew the Verified/Mostly-accurate line differently on an inference (16, 19, 22b, 37); no cluster disagreed on the underlying facts.

---

## Submitted Claims (Stage 2.5 — merged from `code-fact-check-submitted-claims.md`, k=1 by design)

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
