# Code Review Rubric

**Scope:** `harden/cc-isolated-egress` (`devcontainer-config/init-firewall.sh` + review docs) | **Reviewed:** 2026-08-29 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation

Pipeline: k=3 fact-check (unanimous) + security-reviewer (opus) + performance-reviewer (opus).
api-consistency-reviewer skipped (no public API surface). All actionable findings fixed in-loop
and re-verified; the rubric reflects the post-fix state.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | DNS fail-open `else` branch unreachable under `set -euo pipefail` (bare `var=$(pipeline)` aborts on grep exit-1) → no-resolver case bricks open instead of failing open. Unanimous k=3 Incorrect + independent repro. | Fact-check (behavioral) | Incorrect (high) | `init-firewall.sh:113` | for-author | — | ✅ Fixed (`|| true` on the command substitution; verified branch reachable, exit 0) |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Fail-open `else` re-granted blanket DNS to `0.0.0.0/0` — the exact channel the patch removes — and widened it to TCP/53 (pre-patch was UDP-only). | Security | Medium | Security | for-author | — | ✅ Fixed | Fallback now scoped to Docker embedded resolver `127.0.0.11` (UDP+TCP), never `0.0.0.0/0`. |
| A2 | IPv4 *shape* regex accepted out-of-range octets (`999.999.999.999`); iptables treats such a value as a hostname, fails, and aborts in the post-flush/pre-DROP wide-open window (brick-open). | Security | Medium | Security | for-author | — | ✅ Fixed | Regex tightened to real 0–255-octet match; per-resolver `iptables` adds made non-fatal (`\|\| echo …`) so a bad entry fails closed for that resolver, never aborts. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | DNS scoping takes on an undeclared dependency on `/etc/resolv.conf` integrity (agent can re-run firewall via NOPASSWD sudo). Not exploitable today (root-owned resolv.conf). | Security | Low | for-author | — | ✅ Fixed (trust assumption pinned in a comment next to the block) |
| C2 | `\|\| true` cannot distinguish "zero resolvers" (grep exit 1) from a genuine grep/awk error (exit ≥2) — both fail open. Acceptable given the deliberate fail-open philosophy. | Security | Informational | for-author | — | 🟢 Won't-Fix (accepted; reviewer marked no action required) |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| SSH removal opens no new gap | ✅ Confirmed | `init-firewall.sh` — GitHub CIDRs added unconditionally to `allowed-domains`; `-A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT` matches dst on any port incl. 22; `ESTABLISHED,RELATED` covers returns; removed inbound `--sport 22` rule was redundant. Verified by k=3 (unanimous Verified) + security-reviewer. | Fact-check + security | for-orchestrator-synthesis |
| DNS scoping honestly represented (direct path only; recursive-forward residual disclaimed) | ✅ Confirmed | `init-firewall.sh:96-103` comment cross-references the threat-model doc; no over-claim. | Security | for-orchestrator-synthesis |
| No material performance issues (once-per-container-start setup script; N = resolver count, capped at glibc MAXNS) | ✅ Confirmed | `performance-review.md` — `$ns` quoted + regex-validated; no duplicated work with the `dig` loop. | Performance | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| api-consistency-reviewer | No public API surface touched | Shell script; no exported symbols, no schema/route/CLI-flag changes; egress profile format unchanged |

---

To pass review: all 🔴 resolved (R1 ✅), all 🟡 fixed or acknowledged (A1, A2 ✅ fixed).
🟢 optional (C1 ✅ fixed, C2 accepted). **Rubric clean after in-loop fixes.**
