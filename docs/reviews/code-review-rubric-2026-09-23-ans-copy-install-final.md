Commit: 9ae6e46

# Code Review Rubric

**Scope:** `ans/copy-install` `712c626..9ae6e46`, the final (third) pass after two fix rounds (`f84336d..44c10f5`, `44c10f5..9ae6e46`) | **Reviewed:** 2026-09-23 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) unresolved · **PARKED by user decision (rethink the trust model); not merged**

## Loop history

| Pass | HEAD | Agents | Outcome |
|---|---|---|---|
| 1 | d0fdd04 | fact-check k=3; security, performance, api, architecture, tech-debt | 5 🔴, 10 🟡 — `code-review-rubric-2026-09-23-ans-copy-install.md` |
| 2 | 44c10f5 | fact-check k=1 | R1, R3, R4, R5 closed. New: pruning deleted the current backup; mode-only changes skipped; target 1 not committed-only; manifest unhashed; newline destination — `code-fact-check-report-pass2-44c10f5.md` |
| 3 | 9ae6e46 | fact-check k=1, security, api (run in parallel; critics used pass 2 as their foundation) | this rubric |

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | Review and install can diverge. The host hash is taken at `:521`, before the review is printed, and target 1 has no check after y at all: it installs and blesses whatever is in its stage. Executed. Fix candidate: stage, review and install from copies under the destination (behind `denyWrite ~/.claude`), and re-hash immediately before the swap. | Security | High ×2 (executed) | security-reviewer (final); fact-check stale plan line :254 | `devcontainer-config/install.sh:521` | for-author | — | 🔴 Parked |
| R2 | With no `perl` on PATH, `vis` fails, every diff prints empty, and the y/N prompt still appears. The review gate fails open. perl is a new, undocumented host dependency (1592d6b). Fix: refuse when `command -v perl` fails, and treat a `vis` failure as diff trouble. | API / Security | Breaking; Incorrect (high), behavioral | api-consistency F15; fact-check Claim 13; security M (Convergence ×3, executed) | `install.sh` `vis()` | for-author | — | 🔴 Parked |

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Rebuilding the checkout's `claude-home` stage follows a symlink an agent planted there, and writes through it before any prompt (29 of 30 runs). | Security | Medium (executed) | security-reviewer (final) | for-author | — | 🟡 Parked | — |
| A2 | A NUL byte turns a file's review into "Binary files differ", yet bash still runs the hook. | Security | Medium (executed) | security-reviewer (final) | for-author | — | 🟡 Parked | — |
| A3 | `git` reads the checkout's `.git/config`, so commands an agent writes there (e.g. fsmonitor) run as the user during install. | Security | Medium (executed) | security-reviewer (final) | for-author | — | 🟡 Parked | — |
| A4 | A TAB in a backup dir's name makes `cut -f2` prune the wrong dir, including the current run's backup. | Correctness | Incorrect (high), behavioral (exotic input) | fact-check Claim 4 | for-author | — | 🟡 Parked | — |
| A5 | A relative `CLAUDE_HOME_DIR` from a working dir whose name contains a newline gets past the in-repo guard. | Security | Incorrect (high), behavioral (exotic input) | fact-check Claim 6 | for-author | — | 🟡 Parked | — |
| A6 | Rollback wording is wrong on a first install. The uncommitted-changes warning prints twice. The manifest time can't be matched to a `.<pid>`-suffixed backup dir. The README doesn't mention MODE. Three plan lines are stale. | API / Docs | Minor ×4; Stale ×3 | api-consistency F13, F14, F6′, F12; fact-check | for-author | — | 🟡 Parked | — |

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Carried over from pass 1 and untouched by any fix commit: C4–C8 (exit 1 on a host-only install; `--yes` semantics; unknown-arg exit code; hard-coded `~/.claude` in messages; `.cw-new` naming; asymmetric target headers). | api-consistency F1, F2, F5, F7, F8, F11 | Minor / Informational | for-author | — | 🟢 Parked |
| C2 | install.sh is 808 lines (the guideline is ~500). A split needs decision 035's commit gate on the new file. | fix report; tech-debt #2 | — | for-author | — | 🟢 Parked |

## ↩️ Considered Overrides

No prior overrides matched this diff.

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Tests T41–T49 fail at 44c10f5 and pass at 9ae6e46. Suites: install-host 49/49, cc-isolated-functions 92/92, link-claude-home-wiring 14/14, hooks 145/145. | ✅ Confirmed | fact-check final (executed); orchestrator re-run 300/300 | fact-check | for-orchestrator-synthesis |
| Pass-1 R1 (symlink refusal), R3 (`main "$@"; exit $?`), R4 (lock and rollback, including swap-in) and R5 (labels) hold at 9ae6e46. | ✅ Confirmed | security-reviewer final findings 1/3/5/8 hold; fact-check (executed) | security; fact-check | for-orchestrator-synthesis |

## ⚠️ Unverified Findings

All findings' evidence resolved.

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Final confirmation pass limited to security and API; perf findings A6/A7 from pass 1 were fixed and verified by fact-check | pass-3 scope |

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `install.sh` stage → review → install path | security High ×2, A1, fact-check :254 | composed → root: install.sh runs as the same uid as the agent, and it stages, reviews and installs from locations that uid can write between review and swap. Fix direction: every artifact the human reviews lives behind `denyWrite ~/.claude` until installed, or installation runs when no agent can run. This is the question the user parked for rethinking (questions.md). |

---

To pass review, every 🔴 item must be resolved. Every 🟡 item must be fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
