# Code Review Rubric

**Scope:** `harden/cc-isolated-egress` (`devcontainer-config/init-firewall.sh`, `cc-isolated.sh`, tests, review docs) | **Reviewed:** 2026-08-29 | **Status: 🟡 CONDITIONAL PASS** — 0 red, 2 amber accepted-with-note

Two review-fix passes. **Pass 1:** k=3 fact-check + security + performance. **Pass 2:** k=3
fact-check + security + performance + test-strategy, run against pass 1's *fixes* — code no
critic had seen. Pass 2 found defects pass 1 could not have found, which is the loop working
as intended. All findings below are resolved except the two amber residuals, which are
accepted with recorded rationale.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | *(pass 1)* DNS fail-open `else` unreachable under `set -euo pipefail` — a bare `var=$(pipeline)` aborts on grep's exit-1, so the no-resolver case bricked **open**. Unanimous k=3 + independent repro. | Fact-check (behavioral) | Incorrect (high) | `init-firewall.sh` DNS block | for-author | — | ✅ Fixed (`\|\| true`; branch reachable, verified) |
| R2 | *(pass 2)* The `127.0.0.11` fail-open fallback was **inert in every reachable case** — the `else` fires only when no IPv4 resolver parsed, and `127.0.0.11` is itself a valid IPv4 the regex accepts, so had it been the resolver the `if` branch would have run. The stated availability guarantee described an unreachable situation. Unanimous k=3 + independent repro. | Fact-check (behavioral) | Incorrect (high) | `init-firewall.sh` DNS `else` | for-author | — | ✅ Fixed (branch now installs nothing and fails closed, with the enumeration that makes that safe) |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | *(p1)* Fail-open branch re-granted blanket `0.0.0.0/0` DNS and widened it to TCP/53 (pre-patch was UDP-only). | Security | Medium | Security | for-author | — | ✅ Fixed | Superseded by R2's fail-closed branch. |
| A2 | *(p1)* IPv4 regex validated shape not range; `999.999.999.999` reached `iptables`, which treats it as a hostname, fails, and aborted in the wide-open window. | Security | Medium | Security | for-author | — | ✅ Fixed | Real 0–255 octet match + non-fatal per-resolver adds. |
| A3 | *(p2)* **The bootstrap window was agent-triggerable and unbounded.** From `iptables -F` to the DROP policies, a fresh container had empty chains *and* a default-ACCEPT policy for as long as a `curl` plus N `dig`s took. | Security | **High** | Security | for-author | — | ✅ Fixed | Restructured into phase A (all network reads, before any rule is touched) / phase B (rebuild, no egress needed), so DROP moves to immediately after the flush. Window is now a few local calls. |
| A4 | *(p2)* **EXIT trap did not fire on signals.** `$?` inside the trap is the last *completed* command's status (0) when the shell is signalled, so a status-keyed guard silently no-ops and leaves the container open. | Security | **High** | Security | for-author | — | ✅ Fixed | Re-keyed on a `FIREWALL_COMPLETE` sentinel + `trap 'exit 143' INT TERM HUP`. Verified: `kill -TERM` → rc=143, all three DROP policies applied. |
| A5 | *(p2)* Trap installed too late — `compose_domains`, the empty-allowlist `exit 1`, and `iptables-save` ran unprotected, and "abort before flushing" is only safe on a re-run (a fresh container's default is all-ACCEPT). | Security | Medium | Security | for-author | — | ✅ Fixed | Trap moved to immediately after the `--print-domains` early exit. |
| A6 | *(p2)* **Failing closed made a transient failure permanently unrecoverable** — DROP + empty chains meant the next run's own `/meta` fetch was blocked → `exit 1` → forever. A regression introduced by the pass-1 trap. | Security | Medium | Security | for-author | — | ✅ Fixed (normal case) / 🟡 residual | Phase A now runs under the live ruleset, so a transient failure exits *before* the flush leaving the working firewall intact. Residual: a failure on a container's **very first** run is still terminal-but-safe; `cc-isolated.sh` now checks the status and prints the recovery command. |
| A7 | *(p2)* No `--connect-timeout`/`--max-time` on `curl`, no `+time/+tries` on `dig`; a blocked SYN hit the ~127s kernel retry ceiling, and `cc-isolated.sh` re-runs the script automatically. | Performance | Low→Medium | Performance | for-author | — | ✅ Fixed | Bounded both; `dig` deliberately at 2×3s, not the most aggressive, so a merely-slow resolver does not cause a silent skip. |
| A8 | *(p2)* Two bare command substitutions under `pipefail` (`gh_ranges=$(curl…)`, `ips=$(dig…)`) — the same construct as R1 — made their own `if [ -z ... ]` error paths dead code. | Fact-check | Mostly Accurate | Fact-check | for-author | — | ✅ Fixed | `\|\| true` on both; error paths now reachable. |
| **A9** | **IPv6 is entirely unfiltered.** The script installs no `ip6tables` rules at all, so the *whole* allowlist — not just DNS — is unenforced over IPv6. Flagged independently by all three k=3 replicates and test-strategy. | Security | **High (pre-existing)** | Fact-check ×3 | for-author | — | 🟡 **Open — accepted, out of scope** | Pre-existing; neither created nor worsened by this branch. Recorded as a residual risk in the threat-model doc and surfaced to the owner as the largest remaining hole. Closing it is a separate change. |
| **A10** | Fresh-container first-run failure is terminal in place (fail-closed, recoverable only by recreating the container). | Security | Medium | Security | for-author | — | 🟡 **Open — accepted by design** | Fail-closed is the correct direction for a boundary; the alternative (self-healing bootstrap allowlist) adds a temporary permit path to a security-critical script that cannot be tested without root here. Recovery command is printed by both the trap and the launcher. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | *(p1)* Undeclared dependency on `/etc/resolv.conf` integrity (agent can re-run the firewall via NOPASSWD sudo). | Security | Low | for-author | — | ✅ Fixed (assumption pinned in a comment, reframed in p2 as an unasserted Docker default) |
| C2 | *(p1)* `\|\| true` cannot distinguish "zero resolvers" from a genuine grep error. | Security | Informational | for-author | — | 🟢 Won't-Fix (accepted; deliberate fail-open philosophy) |
| C3 | *(p2)* The scoped DNS rules are redundant where the resolver is loopback or host-/24; the hardening comes from *deleting* the blanket accept. Mechanism was mis-emphasized. | Fact-check ×3 | Mostly Accurate | for-author | — | ✅ Fixed (PRECISION paragraph added) |
| C4 | *(p2)* "all of GitHub" overstated — only `.web + .api + .git` are ingested. | Fact-check | Mostly Accurate | for-author | — | ✅ Fixed |
| C5 | *(p2)* Blanket inbound `-A INPUT -p udp --sport 53 -j ACCEPT` bypasses INPUT DROP and is redundant with ESTABLISHED,RELATED. | Security | Low | for-author | — | 🟢 Deferred (recorded as residual; out of scope for this change) |
| C6 | *(p2)* Trap's `iptables -P` calls take no `-w` xtables lock wait and are unverified. | Security | Low | for-author | — | 🟢 Deferred (`\|\| true` already prevents an abort; a lock collision at abort time is unlikely) |
| C7 | *(p2)* Serial `dig` loop over 6–25 domains (~0.1–0.4s) — explicitly **not** worth parallelising in a security-critical script. | Performance | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix (reviewer recommended against) |
| C8 | *(p2)* 18 coverage gaps: every changed line was unreachable from the existing suite, which reached the script only via `--print-domains`. | test-strategy | Advisory | for-author | — | ✅ Largely closed — new `test/init-firewall-rules.bats` (13 tests) covers the regressed block, the window ordering, and every fail-closed path |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| SSH removal opens no new gap | ✅ Confirmed | GitHub SSH endpoints sit in the `.git` CIDRs; `-A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT` matches dst on any port incl. 22; `ESTABLISHED,RELATED` covers returns; the removed inbound `--sport 22` rule was redundant. Verified unanimously in both passes. | Fact-check ×6, security ×2 | for-orchestrator-synthesis |
| Octet regex is a true 0–255 match, and both shell-quoting concerns are unfounded | ✅ Confirmed | r2 swept 0–300 exhaustively: zero false accepts/rejects. Trailing `$` before a closing double quote stays a literal anchor; `\.` survives double-quoting. | Fact-check ×3 | for-orchestrator-synthesis |
| `INPUT DROP` does not lock out the launcher | ✅ Confirmed | `devcontainer exec` is `docker exec` — runtime-mediated, never traverses the INPUT chain; no ports are published. | Security (p2) | for-orchestrator-synthesis |
| Fail-closed DNS `else` is correct, with no fourth reachable case | ✅ Confirmed | Security review enumerated the reachable cases (IPv6-only → unfiltered; loopback → `-o lo`; host-/24 → HOST_NETWORK accept; malformed → should fail loudly) and found no omission. | Security (p2) | for-orchestrator-synthesis |
| New tests genuinely discriminate | ✅ Confirmed | Run against pre-restructure `6edaa21`: 7 of 13 fail (the behaviors round 3 fixed), 6 pass (pre-existing correct behavior). Not vacuous. | Orchestrator (executed) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved. Netfilter/kernel-semantics claims (DNAT ordering, `-F` vs
`-P`, `lo` routing) were **reasoned, not executed** — no root or `iptables` in this
environment — and are labelled as such in the source reports. They need a privileged container
to confirm.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| api-consistency-reviewer | No consumer-facing API surface | Shell script; no exported symbols, schemas, routes, or config keys. The one new interface — the `--print-resolvers` inspection hook — deliberately mirrors the existing `--print-domains` convention. |

---

To pass review: all 🔴 resolved (R1, R2 ✅). 🟡 A1–A8 fixed; **A9 and A10 remain open and
accepted with recorded rationale** — they are the two items the owner should read before
merging. 🟢 optional.

**Verification:** 65/65 tests in the two directly-affected suites, 361/361 across all
top-level suites, shellcheck clean, and the real script runs end-to-end to exit 0 under a
stub harness. One pre-existing `health-check` failure (stale spike doc, CLAUDE.md/AGENTS.md
divergence) is unrelated to these files.
