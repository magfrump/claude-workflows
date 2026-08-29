# Performance Review — DNS resolver scoping in init-firewall.sh

Commit: c44c33a (+ working-tree fix)
**Scope:** `devcontainer-config/init-firewall.sh` — the new resolv.conf-parsing / per-resolver DNS-accept block (lines 113–125), read against the whole script for context.
**Date:** 2026-08-29

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

`init-firewall.sh` runs **once, at container start**, under `set -euo pipefail` with `IFS=$'\n\t'`. It flushes iptables, composes an egress allowlist, and installs DROP-default policies. The reviewed block sits between the flush and the DROP policy: it parses `/etc/resolv.conf`, extracts IPv4 `nameserver` entries, and adds two iptables ACCEPT rules (udp + tcp, dport 53) per resolver, with a fail-open fallback that opens DNS to any host when no IPv4 resolver is found.

Path temperature: **cold** on every axis. It executes exactly once per container lifetime, never per request, never in a loop that scales with user or data volume. `N` = the number of `nameserver` lines in `/etc/resolv.conf`, which glibc caps at `MAXNS = 3` and which in practice is 1–3. `sort -u` and the `while read` loop therefore run over a handful of lines. Every operation here (`awk`, `grep`, `sort`, two `iptables` calls per line) is a fixed, tiny constant cost incurred once. This is the least performance-sensitive category of code the skill recognizes.

## Findings

**No material performance findings.** This is a once-per-container-start setup script operating on a bounded handful of resolvers; there is no hot path, no scaling `N`, no allocation lifecycle, no query pattern, and no contention point for the performance cognitive moves to bite on. Per the skill's own guidance ("Do not recommend micro-optimizations unless they matter at the actual scale"), the candidate nitpicks below are recorded as Informational only and none rise to a fix-before-merge concern.

#### (Informational) `awk`-then-`grep` pipeline could be a single `awk`, but the saving is unmeasurable

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:113-114`
**Move:** Hidden multiplication (checked and dismissed) / Serialization tax (checked and dismissed)
**Classification:** Micro (extra process in a pipeline) / Cold path (runs once at container start)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The resolver extraction spawns `awk | grep | sort` where a single `awk` with a matching regex could do the `nameserver`-match and the IPv4-validation in one process. The cost of the extra `grep` and `sort` forks is on the order of milliseconds, incurred exactly once, against ≤3 input lines. Merging them would trade a small, genuine legibility win (the `grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'` IPv4 guard is doing clear, self-documenting validation work and pairs naturally with the identical guard used on the `dig` output at line 189) for zero measurable runtime benefit. Not worth changing for performance reasons.

**Recommendation:** Leave as-is. If it is ever touched for readability, keep the explicit IPv4-shape guard — it is load-bearing correctness, not decoration.

## What Looks Good

- **Process substitution (`done < <(echo "$dns_resolvers")`) is the correct choice here, and the alternative would not have mattered.** The reviewer's question — does anything set inside the loop need to survive it? — resolves cleanly: **no.** The loop body's only effect is `iptables -A OUTPUT ...`, which mutates kernel/global firewall state, not shell variables. Nothing is assigned to a variable that is read after the loop. So the classic `echo "$x" | while read` subshell pitfall (loop-modified variables lost when the pipeline subshell exits) does not apply — either form would be functionally correct. The process-substitution form is still marginally preferable because it keeps the loop body in the *current* shell, which matters under `set -e`: an `iptables` failure inside a `| while` subshell can have its exit status masked by the pipeline, whereas here a failure aborts the script as intended (consistent with the `-exist` and `|| true` guards used elsewhere in the file precisely to manage `set -e` interactions).
- **`$ns` is correctly quoted** (`iptables ... -d "$ns" ...`), and each value has already been shape-validated to a bare IPv4 dotted quad by the `grep -E` filter, so word-splitting and injection are both non-issues despite the strict `IFS=$'\n\t'`.
- **No duplicated resolution work.** The reviewer flagged the domain-resolution loop below (line 172–198, which re-resolves allowlist domains via `dig`) as a possible duplication. It is not: that loop resolves *allowlist destination domains* to IPs for the ipset; this block scopes DNS egress to the *resolvers themselves* from `/etc/resolv.conf`. Different inputs, different outputs, no overlap — no wasted or repeated work between them.
- **Bounded `N`.** `/etc/resolv.conf` nameserver count is capped (glibc `MAXNS`, typically 1–3); the `sort -u`, the loop, and the per-resolver rule additions cannot scale into a problem.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `awk\|grep\|sort` could be one `awk` (no measurable benefit; keep for legibility) | Informational | `init-firewall.sh:113-114` | High |

## Overall Assessment

Performance posture is a non-issue. This is cold, run-once, container-start setup code operating on a bounded handful of resolvers; there is nothing here for the performance moves to act on, and the one micro-nitpick available (merging `awk|grep` into one `awk`) has no measurable payoff and a small legibility cost, so it is explicitly *not* recommended. The design choices the reviewer asked about — process substitution vs. subshell, `$ns` quoting, and possible duplication with the `dig` loop — all check out as correct or irrelevant-to-performance. No profiling or benchmarking is warranted. Ship it on performance grounds; any remaining scrutiny belongs to the security review (the fail-open-on-no-resolver branch and the SSH-accept removal are security/robustness decisions, not performance ones), which the file's own comments already point to (`security-review-cc-isolated-egress-2026-08-29.md`).

## Goal-Alignment Note

The stated goal is hardening an egress firewall by scoping outbound DNS to configured resolvers and removing a blanket SSH accept — a **security/robustness** change, not a performance change. This review confirms the change introduces no performance regression and no new scaling risk, which is the most a performance lens can contribute to a goal that is orthogonal to it. The substantive risk in this diff (fail-open behavior when no IPv4 resolver parses, and the correctness of the `|| true` guard that makes the empty-result branch reachable under `set -e`) is a security/availability tradeoff and is correctly the province of the security review the file references, not this one. A clean performance result here should not be read as a full sign-off on the change.
