Commit: c63da94d

# Code Review Rubric

**Scope:** feat/build-loop-u5 vs main (b279a2ba); iteration 1 full branch at 42414307, iteration 2 the fix range 42414307..c63da94d (`--loop-pass`, fact-check k=1) | **Reviewed:** 2026-10-14 | **Status: 🟡 PASSES WITH CONDITIONS at c63da94d** — 0 red; iteration 2's Must Address rows fixed in 659a1c61 and the Q-156 commit after it; final confirming pass pending

Delivery mode: self-read (diff at a scratch path; enclosing scripts too large to inline). Fix commits: 771a5d02, 57e26f6b, 87ca421e (docs fix after the fix-drift check). Fix-drift lite check over 42414307..57e26f6b found 1 (never-line prose named 8 of 10 directories), fixed in the next commit; a second check over that commit found none.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | Self-merge could land `devcontainer-config/install.sh` and the host tools, which the release paste runs on the host before its diff is shown; the never line held only `workflows/` | Security | High | security-reviewer F1 | `docs/dev-cycle.md:11` | for-author | row 682 (routed to U5) | Fixed (771a5d02: never line widened to every directory live without a release) |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | "Scripts reach sessions only through a release": health-check.sh, run-tests.sh, test/ and what they source run from the orchestrator's worktree every iteration (`docs/dev-cycle.md:38-40`, Q-149) | Docs / Security | Incorrect | Fact-check claims 12, 28; security F3, F4 | for-author | row 682 | Fixed (771a5d02, 57e26f6b) | — |
| A2 | Q-156's paste guard compared HEAD with refs/heads/main, a tautology on main; fallback could not fire before the release | Security / API | Medium | security F2; api-consistency F3 | for-author | — | Fixed (57e26f6b: fixed M, per-directory tree compare with rev-parse) | — |
| A3 | Q-103's R8 list omitted `$GATE_TMP/answer` | Docs | Incorrect | Fact-check claim 25 | for-author | row 684 | Fixed (57e26f6b) | — |
| A4 | Q-103's "also routed here" list incomplete (rows 548, 668, 682, 749, 750, 784, 786, 787, 797, 801, 802) | Docs | Incorrect | Fact-check claim 26 | for-author | those rows | Fixed (57e26f6b) | — |
| A5 | Plan as-built note says D10 names row 72; D10 said 70 | Docs | Incorrect | Fact-check claim 18 | for-author | — | Fixed (57e26f6b) | — |
| A6 | Onboarding presents `Self-merge never:` as optional; self-merge needs a valid line | API | Inconsistent | api-consistency F1 | for-author | — | Fixed (771a5d02) | — |
| A7 | Commit 2846f9fa's body inherits A4's gap | Docs | Mostly accurate | Fact-check claim 42 | for-author | — | Won't-Fix (immutable history; override row) | Corrected in 57e26f6b's body |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | "only through --settings": the scripts' gated modes read the lines too | Fact-check claim 6 | Low | for-author | — | Fixed |
| C2 | "A refused self-merge falls through to review": only path refusals | Fact-check claim 8 | Low | for-author | — | Fixed |
| C3 | Slot counting: step 8 counts absent and working briefs; "holds a slot" clashes with the skill's other meaning | Fact-check claim 10; api-consistency F2 | Low | for-author | — | Fixed |
| C4 | F37: after a merge-in the land skips questions.sh check | Fact-check claim 24 | Low | for-author | — | Fixed |
| C5 | Review merges cannot land constraints/cycle files; such branches end stopped | api-consistency F4 | Low | for-author | — | Fixed |
| C6 | Step 10's constraints entry had no slug | api-consistency F5 | Low | for-author | — | Fixed (SKILL.md step 10) |
| C7 | Q-153 slug outside the build-loop-cN family | api-consistency F6 | Low | for-author | — | Fixed |
| C8 | "the loop's own files" vs the script's "the brief's own files" | api-consistency F7 | Low | for-author | — | Fixed |
| C9 | Q-154 answer lacks `[1]`; answer date before Opened | api-consistency F8 | Informational | for-author | — | Fixed |
| C10 | Step 0.1 copies subjects and paths into questions.md unscrubbed (`<!--` breaks questions.sh index) | security F5 | Low | for-author | — | Fixed (withheld rule) |
| C11 | Release flag keys on a subject suffix, not --main-log's class | security F6 | Informational | for-author | — | Fixed (worded as a pointer, not proof) |
| C12 | Both pastes run the working-tree install.sh, not M's blob | security F7 | Informational | for-author | decision 035 | Won't-Fix (override row) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1b` / 2026-10-05 (row 244) | docs/dev-cycle.md's policy text stale | 🟢 → Defer to U5 | "The plan gives that rewrite to U5" | Discharged: rewritten in this unit |
| `feat/build-loop-u3a3` / 2026-10-10 (row 682) | health-check.sh self-mergeable, outside floor | 🟡 → Defer (routed to U5's never line) | Revisit at U5 | Discharged: never line widened; Q-149 asks the width |
| `feat/build-loop-u3a3` / 2026-10-10 (row 684) | `answer` file race | 🟢 → Defer to Q-103 list | Revisit at U5 | Discharged: added to Q-103's R8 |
| rows 548, 668, 749, 750, 784, 786, 787, 797, 801, 802 | residuals routed to Q-103 | Defer | Revisit at Q-103's re-route | Discharged: listed in Q-103 |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The new docs/dev-cycle.md parses as intended: policy review unset, slots 3, never list set; no prose line counted as a copy, also with policy flipped to self-merge | ✅ Confirmed (executed) | `build-loop.sh --settings` in a throwaway repo; `test/scripts/build-loop-read.bats` "own docs/dev-cycle.md" passes | Fact-check (executed); security endorsement | for-orchestrator-synthesis |
| Q-156's commit and path lists match git from C=8d0e660e | ✅ Confirmed (executed) | `git log --first-parent 8d0e660e..b279a2ba` (11), `git diff --name-only 8d0e660e HEAD -- . ':!docs/'` (28) | Fact-check; api-consistency | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Diff is copy-only: markdown plus two test assertion lines, no logic, query or dependency change | `git diff --stat main...HEAD`: 16 code lines outside docs/, all in a bats assertion, SKILL.md prose and a workflow doc |

Contextual critics: none triggered (no source change without tests, 12 files / ~300 lines, no manifest, no UI, no module structure change).

---

## 🧩 Composition check

| Cluster | Span | Fragments | Disposition |
|---|---|---|---|
| docs/dev-cycle.md never line | :11, :36-40 | R1, A1 (fact-check 12; security F3, F4) | composed root already stated by A1: the plan's premise "code reaches sessions only through a release" is false here; one fix (widen the line) |
| Q-156 paste | questions.md:480-484 | A2 (security F2, api F3) | distinct sources, same defect; no new root |

---

## Iteration 2 (incremental: 42414307..c63da94d; fact-check k=1, security, api-consistency)

Prior findings verified: R1, A1-A6 resolved (fact-check i2, security i2 "closes iteration 1's findings in substance"); api-consistency i1 F2 half-fixed (Q-151) and F3/F4 partly, carried below. No re-fires of a fixed finding (security i2 F1 is a new mechanism in A2's fix: tree names vs archive output). Performance still skipped (copy-only).

| # | Finding | Tier | Source | Status |
|---|---|---|---|---|
| A8 | Settings prose: cycle-file branches "filed as stopped, not as a merge entry" under both policies; under self-merge they come as a merge entry first | 🟡 (Incorrect, doc) | Fact-check i2 claim 5b; claim 30b (onboarding) | Fixed (659a1c61) |
| A9 | Q-156 tree pin bypassed by a replace ref or a root `.gitattributes` | 🟡 (Medium) | security i2 F1 | Fixed (paste exports GIT_NO_REPLACE_OBJECTS, refuses replace refs and grafts, compares `.gitattributes`) |
| A10 | install.sh's archive honors replace refs; state gate misses them (pre-existing) | 🟡 (Medium) | security i2 F2 | Deferred: override row, roadmap Idea; Q-156 refuses for this release |
| A11 | Never-line prose overstated coverage: docs/evaluation-rubric.md and docs/spikes/ read as authority, self-mergeable | 🟡 (Medium, low conf.) | security i2 F3 | Fixed (prose and Q-149 name them; listing them is the user's call in Q-149) |
| C13 | Slots also cap dispatch | 🟢 | Fact-check i2 claim 6 | Fixed |
| C14 | Paste compares all of global-instructions/ (fails closed) | 🟢 | Fact-check i2 claim 26 | Fixed (wording: "directories the release installs from") |
| C15 | Withheld rule's reason wording; line shapes, bidi, non-UTF-8 | 🟢 | Fact-check i2 claim 28; security i2 F4 | Fixed (SKILL.md step 0.1) |
| C16 | Commit bodies 771a5d02, c63da94d wording | 🟢 | Fact-check i2 claims 31, 34 | Won't-Fix (immutable; override row) |
| C17 | Q-151 [1] "holds a slot" | 🟢 | api i2 F1 | Fixed |
| C18 | Q-156's M is a branch commit, step 0.1's is main's | 🟢 | api i2 F2 | Fixed (entry says why; merge's released trees equal M's) |
| C19 | Q-103 [1] "always-on rules" vs "the N rules" | 🟢 | api i2 F3 | Fixed |
| C20 | Lists of both-policy refusals differ (idea log, cycles, own brief; onboarding lacks constraints) | 🟢 | api i2 F4 | Fixed |
| C21 | Plan D5/F57 still describe the workflows/-only interim | 🟢 | api i2 F5 | Fixed (as-built note supersedes them) |

Single-sample review; absence of findings is not an attestation.
