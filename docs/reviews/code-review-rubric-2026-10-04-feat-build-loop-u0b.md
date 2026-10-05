Commit: 698348ac
Loop closed at 374db407
# Code Review Rubric

**Scope:** full unit range; iterations 1–2 `--loop-pass` (k=1), iteration 3 the final confirming pass (k=3, full panel) at 698348ac; its findings fixed in the commits up to 374db407 | **Reviewed:** 2026-10-04 – 2026-10-05 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation

Loop outcome: exit condition 1 at the end of iteration 3. Iteration 3's fixes were verified by the tests (mutation-checked), `lite-review.py --mode fix-drift` and `scripts/health-check.sh`, not by another critic panel (that would be iteration 4).

Reports: `code-fact-check-report-build-loop-u0b.md`, `security-reviewer-review-2026-10-04-build-loop-u0b.md`, `performance-reviewer-review-2026-10-04-build-loop-u0b.md`, `api-consistency-reviewer-review-2026-10-04-build-loop-u0b.md`, `architecture-review-review-2026-10-04-build-loop-u0b.md`. Deviations from the skill: one critic agent per role (and one fact-check agent per replicate) reviewed all three stacked units, writing one report per unit; agents read the skill files themselves; in iteration 2 the critics ran in parallel with the fact-check instead of after it; Stage 2.5 was not run. Iteration 2 reports: `*-2026-10-05-build-loop-<unit>.md`; final pass: `*-2026-10-05-final-build-loop-<unit>.md` and `code-fact-check-report-build-loop-<unit>{,-r1,-r2,-r3}.md`.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | check_brief/check_branch answer without a default branch found by name (a landed brief reads `new`; Status read from a loop-written current branch); the rule lived only in `scripts/dev-cycle.sh:332` | Security / API contract | Coupling (architecture); Minor (api); Low (security) | architecture-review + api-consistency + security-reviewer + fact-check 5, 7 | for-author | — | ✅ Fixed in 09cb3764 (main_by_name guard; globals initialised; new test) | — |
| A2 | Header said a check without ROOT_REAL exits; check_brief skipped every brief as a symlink | Docs/Security | Fact-check Incorrect (iter 2); security I2 | Fact-check + security-reviewer | for-author | — | ✅ Fixed in b0f596b2 (need_root in check_brief; test) | — |
| A3 | MAIN_BY_NAME SC2034 directive stale | Docs | Fact-check Stale (iter 2) | Fact-check | for-author | — | ✅ Fixed in b0f596b2 | — |
| A4 | From a subdirectory, check_brief printed `ok … new` for a landed brief | Security | Low (Medium once U1 calls it) | security-reviewer (final) | for-author | — | ✅ Fixed by U0a's ac96cf12 (need_root requires the top level; check_brief runs need_root) | — |
| A5 | check_brief's printed answer captured in-process can fail open (`if out=...`, `< <(...)`) | Architecture | Minor | architecture-review (final) | for-author | — | ✅ Fixed in 374db407 (header names the safe pattern; non-ok is a refusal) | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | FENCE_AWK SC2034 directive redundant | Fact-check | Mostly accurate | for-author | — | Fixed |
| C2 | check_branch comment places the by-name rule in another file | Fact-check | Mostly accurate | for-author | — | Fixed |
| C3 | Test name "1 outside a repo" but asserted only non-zero | Fact-check | Mostly accurate | for-author | — | Fixed |
| C4 | "moved verbatim" though the FENCE_AWK directive was edited | Fact-check | Mostly accurate | for-author | — | Fixed (directive restored) |
| C5 | resolve_main should be called once per process | architecture-review | Informational | for-author | — | Fixed (header) |
| C6 | check_brief's `git log -G` walk grows with history, per brief | performance-reviewer | Informational (forward note) | for-author | — | Deferred (U1 measurement; override-log row) |
| C7 | Skip blamed the repo when resolve_main had not run | api-consistency (iter 2) | Informational | for-author | — | Fixed in b0f596b2 |
| C8 | Header's subject for "calls resolve_main" unclear | api-consistency (iter 2) | Informational | for-author | — | Fixed in b0f596b2 |
| C9 | dev-cycle.sh wrote its own -z "$MAIN_BY_NAME" test | architecture-review (iter 2) | Informational | for-author | — | Fixed in b0f596b2 |
| C10 | main_by_name passes for a MAIN_SHA from another repo | security-reviewer (iter 2) | Informational | for-author | — | Won't-Fix (override-log row) |
| C11 | origin/HEAD naming a loop-created local branch untested | security-reviewer (iter 2) | Informational | for-author | — | Defer (override-log row) |
| C12 | Skip lines echo repo text; header did not say to print through scrub | security-reviewer (final) | Informational | for-author | — | Fixed in 374db407 |
| C13 | "refused" for a skip | api-consistency (final) | Informational | for-author | — | Fixed in 374db407 |
| C14 | Three guard channels; U3 --merge must check main_by_name | architecture-review (final) | Informational | for-author | — | Defer to U3 (override-log row) |
| C15 | check_brief's need_root adds a fork per brief | performance-reviewer (final) | Informational | for-author | — | Won't-Fix (override-log row) |
| C16 | 0b53fe50 message: "returns 1" test | Fact-check (final) | Mostly accurate | for-author | — | Won't-Fix (override-log row) |

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
| 1 | `scripts/lib/dev-cycle-read.sh:221-300` | arch Coupling, api Minor, security Low, FC 5/7 | distinct defects: one shared root already stated whole by each fragment (A1); no composition needed |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
