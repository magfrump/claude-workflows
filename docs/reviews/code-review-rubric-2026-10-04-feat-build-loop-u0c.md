Commit: d8da1fba
Loop closed at a2630d08
# Code Review Rubric

**Scope:** full unit range; iterations 1–2 `--loop-pass` (k=1), iteration 3 the final confirming pass (k=3, full panel) at d8da1fba; its findings fixed in the commits up to a2630d08 | **Reviewed:** 2026-10-04 – 2026-10-05 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation

Loop outcome: exit condition 1 at the end of iteration 3. Iteration 3's fixes were verified by the tests (mutation-checked), `lite-review.py --mode fix-drift` and `scripts/health-check.sh`, not by another critic panel (that would be iteration 4).

Reports: `code-fact-check-report-build-loop-u0c.md`, `security-reviewer-review-2026-10-04-build-loop-u0c.md`, `performance-reviewer-review-2026-10-04-build-loop-u0c.md`, `api-consistency-reviewer-review-2026-10-04-build-loop-u0c.md`, `architecture-review-review-2026-10-04-build-loop-u0c.md`. Deviations from the skill: one critic agent per role (and one fact-check agent per replicate) reviewed all three stacked units, writing one report per unit; agents read the skill files themselves; in iteration 2 the critics ran in parallel with the fact-check instead of after it; Stage 2.5 was not run. Iteration 2 reports: `*-2026-10-05-build-loop-<unit>.md`; final pass: `*-2026-10-05-final-build-loop-<unit>.md` and `code-fact-check-report-build-loop-<unit>{,-r1,-r2,-r3}.md`.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Commit message: "build-loop.sh will need only the walk and INSTRUCTION_FILE" contradicts plan :187 | Docs / plan | Fact-check Incorrect (commit message) | Fact-check | for-author | — | ✅ Fixed: message reworded (0f37224e); plan amendment added (a57e5d27) | — |
| A2 | Import walk returns an empty set and caches it when ROOT_REAL is unset, disabling check_fix's import refusal (lib `:319-347`) | Security | Low | security-reviewer | for-author | — | ✅ Fixed in a57e5d27 (need_root; new test) | — |
| A3 | Plan amendment: "F11's Q-103 text says so" — nothing did | Docs/plan | Fact-check Incorrect (iter 2) | Fact-check | for-author | — | ✅ Fixed in fa184356 (F11 row and step 13 now carry it) | — |
| A4 | Amendment dropped the leading-dot test and the B2 note; move messages said "deferred extraction" | Docs/plan | Minor | architecture-review (iter 2) | for-author | — | ✅ Fixed in fa184356 and the reworded messages | — |
| A5 | Walk cached an empty set with ROOT_REAL ≠ cwd, or from a subdirectory | Security | Low | security-reviewer (iter 2, final) | for-author | — | ✅ Fixed by U0a's 497c8cb5 and ac96cf12 | — |
| A6 | Gate's import start set misses the checkout's untracked/ignored instruction files (CLAUDE.local.md) | Architecture/Security (B2) | Minor | architecture-review (final) | for-author | — | ✅ Fixed in a2630d08 (amendment: U2 adds them or records the gap, and tests it) | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | ROOT_REAL directive says "file rules" but the walk reads it too | Fact-check | Mostly accurate | for-author | — | Fixed |
| C2 | T29 omits IMPORTED / IMPORTED_DONE | Fact-check | Mostly accurate | for-author | — | Fixed |
| C3 | Import-walk cache not keyed on the repo root | security-reviewer | Informational | for-author | — | Fixed (IMPORTED_DONE holds the root) |
| C4 | Header doesn't say which readers read main's commit vs the working tree | api-consistency | Informational | for-author | — | Fixed |
| C5 | check_fix's predicate: belongs in U2 as a separate floor function | architecture-review | Minor | for-author | — | Deferred (plan amendment; override-log row) |
| C6 | check_fix reads the walk's cache format across the boundary; add `isimported` by U2 | architecture-review | Minor | for-author | — | Deferred (U2, plan amendment; override-log row) |
| C7 | check_fix allows docs/thoughts/ and docs/constraints.md; floor item 4 treats them as truth | architecture-review | Informational | for-author | — | Deferred (U2, plan amendment; override-log row) |
| C8 | The walk reads the working tree; the gate needs a rule (worktree at MAIN_SHA or commit variant) | architecture-review | Informational | for-author | — | Deferred (U2/Q-103 F11 text, plan amendment; override-log row) |
| C9 | check_answer reads the working tree until U1 (F28); build-loop.sh must not use it before then | security-reviewer | Informational (orchestrator) | for-author | — | Deferred (U1, D8; override-log row) |
| C10 | Cache lasts one process; build-loop.sh should call the lib directly, not dev-cycle.sh per path | performance-reviewer | Informational | for-author | — | Deferred (U1; override-log row) |
| C11 | Cache comment overstated ("once per process and root") | Fact-check (iter 2) | Mostly accurate | for-author | — | Fixed in fa184356 |
| C12 | Header's exiting list omitted check_answer; Inputs omitted check_brief's working-tree probe | Fact-check (iter 2, final) | Mostly accurate | for-author | — | Fixed (rebased header) |
| C13 | Amendment: "below" vs above; missing "no untracked instruction files" qualifier | Fact-check k=3 (final) | Mostly accurate | for-author | — | Fixed in a2630d08 |
| C14 | Approach list said U0 extracts brief_fields; rollback list lacked U0c | api-consistency + fact-check (final) | Informational | for-author | — | Fixed in a2630d08 |
| C15 | Walk's inner inrepo calls fork pwd -P (~53 per walk) | performance-reviewer (final) | Low | for-author | — | Defer to U2 (override-log row) |
| C16 | check_answer capture as merge authorisation; SKIPPED side effect | architecture + api-consistency (final) | Informational | for-author | — | Defer to U1 (override-log rows) |
| C17 | imported_names named like a getter | api-consistency (final) | Informational | for-author | — | Header names it; rename Defer to U2 (override-log row) |
| C18 | Commit 1c7373d3's pre-fix wording | Fact-check (iter 2, final) | Mostly accurate | for-author | — | Won't-Fix (override-log row) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/dev-cycle` / 2026-09-29 | `scripts/dev-cycle.sh` parses `questions.sh open`'s column output (architecture #6) | Minor → Won't-Fix | no machine-readable mode | Inherited: that code stays in dev-cycle.sh, unchanged by the move. |
| `feat/dev-cycle` / 2026-09-29 | Raw control characters reach the terminal (security #4) | Informational → Won't-Fix | same exposure as `git log`; since superseded by the scrub | Inherited: the scrub moved verbatim. |

---
## ✅ Confirmed Good

None recorded as ✅ rows: the critics' routed endorsements were not put through a Stage-2.5 submitted-claims pass, so they stay pending execution verification. Executed evidence instead: the k=3 fact-check verified byte-identical digest and check-mode output against main, verbatim moves, and that every new test fails when its guard is removed.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (Contextual: architecture-review ran (module structure changed); test-strategy not triggered (tests changed with the source); tech-debt-triage, dependency-upgrade, ui-visual-review not triggered.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/lib/dev-cycle-read.sh:316-347` | security A2, security C3, perf C10, FC C2 | distinct defects: unset root, unkeyed cache and cross-process reuse are separate mechanisms |
| 2 | plan `:187` / commit message | FC A1, arch C5 | distinct defects: arch C5 states the remedy for A1 in full |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
