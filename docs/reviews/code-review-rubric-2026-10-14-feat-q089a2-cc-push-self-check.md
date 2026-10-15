Commit: 840f39b0

# Code Review Rubric

**Scope:** feat/q089a2-cc-push-self-check (`f2533b33..840f39b0`, 1 commit, 93 lines; stacked on A1) | **Reviewed:** 2026-10-14 | **Status: 🟡 DOES NOT PASS** — 0 red, 3 amber, fixed in the iteration-1 fix commit, pending iteration 2

Iteration 1 of 3 of a new loop. The unit was re-cut from the reviewed feat/q089-host-tool-trust after its iteration-4 gate decision `split` (see that rubric). Run with `--loop-pass`, fact-check k=1, delivery self-read.
- **Critics run:** security-reviewer, api-consistency-reviewer.
- **Skipped:** performance-reviewer (no hot path; the check was measured at 13.5 ms per call in the parent loop) and architecture-review (no structural change beyond the duplicate already reviewed there).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The header, which is also `--help`, says "nothing unchecked runs". The prologue above the check runs first, and an overwrite or prepend that drops the check runs unrefused (probes P1, P3, Q7, Q8). | Docs / Security | Incorrect (doc) / Low | code-fact-check claim 3 + security F1 + api F2 | for-author | — | 🟢 Fixed: the header says what the check guards (cc-gitdir.sh and every line below the check) and what it can't (the lines above it, or an overwrite), which only the launcher's warning and `--list` catch. | — |
| A2 | The refusal's bless hint is bare `cc-isolated --bless`. On a custom install it blesses the wrong dir and cc-push keeps refusing. A1's refusal names `CLAUDE_DEVC_CONFIG_DIR`. | API Consistency | Inconsistent | api-consistency F1 (+ F4 multi-line shape) | for-author | — | 🟢 Fixed: `ERROR: cc-push refuses to run:`, one reason per line, then `CLAUDE_DEVC_CONFIG_DIR=<CC_PUSH_DIR> cc-isolated --bless`. | — |
| A3 | "A tampered cc-push.sh is refused without running" was untested: the test's tamper was an inert comment. | Test | Incorrect (commit message) | code-fact-check claim (commit) + security F2 | for-author | — | 🟢 Fixed: the test appends a `touch` below the check and asserts that it never ran and that the hint names the dir. The commit message is unchanged (a branch commit, not rewritten); the fix commit states the correction. | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `guides/cc-isolated-usage.md` doesn't mention that `--help` can exit 1 with no output | api-consistency F3 | Minor | for-author | — | 🟢 Moved to unit B |
| C2 | `sha256sum` and `awk` are found by PATH name: a failing shim fails closed, but a shim that prints the blessed hash would pass. This is not a regression (git is found the same way). Add it to row 71's "Not covered". | security F3 | Info | for-author | — | 🟢 Moved to unit B (row 71) |
| C3 | The exemption's "not the config dir" clause depends on `CLAUDE_DEVC_CONFIG_DIR` naming the install dir. A planted install.sh plus deleted manifests in an unnamed install dir is exempt (Q4). Row 71 accepts this. | security F4 | Info | for-author | — | 🟢 Moved to unit B (row 71 wording); the shared comment stays, since it's pinned to A1's copy |
| C4 | The parity test skips each block's first comment line, and "row 71" resolves only once B lands. | code-fact-check (Mostly accurate) | Info | for-author | — | 🟢 Won't-Fix (by design; the stack lands in order) |
| C5 | The launcher exits 0 on `--help` despite a failed host-tool check, while cc-push exits 1. This is deliberate. | api-consistency F5 | Info | for-orchestrator-synthesis | — | 🟢 Won't-Fix |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| cc-push exits 1 before parsing, `--help` included, for a changed file, both files changed, a missing or symlinked manifest, and a duplicate entry | ✅ Confirmed | executed probes in `execution-logs/fc-q089a2/` | code-fact-check (executed) | for-orchestrator-synthesis |
| No weakening against main: A2 only adds a refusal ahead of the existing logic | ✅ Confirmed | security review §answers; the only removed lines are the old `source` line and a comment | security-reviewer | for-orchestrator-synthesis |

---

## 🧩 Composition check

| Cluster | Span | Fragments | Disposition |
|---|---|---|---|
| cc-push header | :35-39 | fc 3, security F1, api F2 | same defect, stated whole in A1 |

---

## ⏭️ Skipped Core Critics

- performance-reviewer: no loop, query or hot-path change. The same check was measured in the parent loop (13.5 ms per call, cold path).
