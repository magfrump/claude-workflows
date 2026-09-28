Commit: 12f96cd

# Code Review Rubric

<!-- Canonical name per skills/code-review/SKILL.md would be code-review-rubric-2026-09-28-review-q065.md; this file uses the item-slug prefix required by the 2026-09-28 parallel-review brief to avoid merge collisions. The q065-* artifacts below are the prefixed equivalents of the canonical paths. -->

**Scope:** review/q065, `git diff main...HEAD` (full branch; iteration 1, `--loop-pass`, no prior rubric) | **Reviewed:** 2026-09-28 | **Status: 🟡 PASSES WITH OPEN ITEMS** — 0 red, 1 yellow open

Iteration 1 of 3. Delivery mode: self-read of a pre-assembled shared-context file (diff + post-change `scripts/lib/si-input.sh`, ~6k tokens); agents read role skills by path rather than pasted. Fact-check k=1 (loop pass, decision 031). Critics: security, performance, api-consistency (core); architecture-review (auto-selected: public function removed from a library surface); test-strategy (`--include`, to route fact-check escalation (b)). All on `opus`.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | No surviving test asserts that `parse_si_input` discards text before the first `##` heading (and the body of an unknown heading). The deleted test "comment block does not pollute parsed sections" (`main:test/si-input-rejected-history.bats:178-188`) was the only such assertion, so the commit message's "Its 12 tests exercised only that function" is Mostly Accurate (11 of 12). Discard mechanism: `_save_si_section`'s `case` has no arm for an empty/unknown heading (`scripts/lib/si-input.sh:107-112`). | Tests / Documentation | Mostly Accurate + test-strategy Must Address + architecture Informational (one root) | Fact-check Claim 2 + test-strategy TS1 + architecture-review F1 | for-author | — | Fixed | Fixed in 2c1162b: new test "parse_si_input drops text before the first heading and under unknown headings" in `test/si-input-parse-comments.bats` (kills two mutants: preamble routed to Context, unknown heading routed to Context). The commit message's 11-of-12 imprecision is corrected in that fix commit's body; 12f96cd is not rewritten. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Pre-existing gaps next to (not caused by) the change: the missing-file branch of `parse_si_input` (`scripts/lib/si-input.sh:35-38`) and case-insensitive heading matching (`:107`) have no test. | test-strategy | Low | for-author | — | Won't-Fix (override-log row 2026-09-28 `review/q065` C1) |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The deleted function had no caller anywhere in history | ✅ Confirmed | `git log --all -S prepend_si_input_rejected_history` → hits only in the function, its tests and `docs/working` prose; `scripts/self-improvement.sh:231` sources the library and `:493` calls only `parse_si_input` | Fact-check Claim 1 (static, enumeration) | for-orchestrator-synthesis |
| The two moved tests are byte-identical to the originals and pass | ✅ Confirmed | executed: `scripts/run-tests.sh test/si-input-parse-comments.bats` → 2/2 ok; diff of old tail vs new file identical | Fact-check Claim 3 (executed) | for-orchestrator-synthesis |

Security endorsement "the branch only removes code from `scripts/`" (`route: code-fact-check`) is **pending execution verification** (Stage 2.5 skipped on a loop pass).

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `main:test/si-input-rejected-history.bats:178-188`, `scripts/lib/si-input.sh:103-112` | FC Claim 2, TS1, arch F1 | distinct defects: no — all three state the same defect and its fix completely; merged as one row A1 rather than composed |

---

## Coverage and escalations (orchestrator)

- Fact-check escalation (a), addressee orchestrator: on `answers-2026-09-28`, `docs/working/questions.md` records Q-065 as "Done in 11b79c6"; this branch lands the identical change as 12f96cd. Whichever hash reaches `main` should be cited. Outside this worktree; routed to the caller.
- Fact-check escalation (b), addressee test-strategy: routed (test-strategy ran) → A1.

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
