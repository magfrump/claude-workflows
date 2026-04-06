# Draft Verification Rubric

**Draft:** Two-Phase PR Prep Restructure | **Checked:** 2026-04-06 | **Status: 🟡 CONDITIONAL PASS** — 0 red, 0 amber items remaining (all fixed in review-fix loop)

## 🔴 Must Fix

| # | Item | Type | Source | Status |
|---|---|---|---|---|
| F1 | `guides/pr-prep-quick-ref.md` still reflects the old flat ordering (commit cleanup first, size check last). Will actively mislead anyone using the quick reference. Must be rewritten to match the two-phase structure. | Stale cross-reference | Code review | ✅ Fixed — rewrote to match two-phase structure |
| F2 | `patterns/orchestrated-review.md` line 26 describes pr-prep's parallel dispatch as "self-review checks (dead code, style, accidental changes)" — no longer matches the current review-fix loop structure (`/code-review`, `/self-eval`, documentation check, dependency audit). | Stale cross-reference | Self-eval | ✅ Fixed — updated to list current review dispatch |
| F3 | `test/workflow-required-sections.bats` expects `### N.` headers but pr-prep now uses `#### N.` under phase headings. Tests 145-146 fail. | Test failure | Test run | ✅ Fixed — test now accepts `###+ N.` pattern |

## 🟡 Must Address

| # | Item | Type | Source | Status |
|---|---|---|---|---|
| A1 | Decision 007 claims "issues were surfaced during a divergent design exercise evaluating 12 candidate orderings" — no DD artifact exists in the repo, and the decision record itself lists only 5 options. Either the DD exercise was never documented, or the "12" figure is inaccurate. | Unverifiable claim | Fact-check | ✅ Fixed — removed specific "12" count, now says "candidate orderings" |
| A2 | Decision 007 scope is narrower than the actual PR: it discusses only reordering existing steps, but the PR also adds dependent PR check (1b), draft PR step (2), documentation check, dependency audit, and UI screenshots. These additions are undocumented in the decision record. | Scope mismatch | Code review | ✅ Fixed — added scope note distinguishing ordering decision from independent enhancements |
| A3 | Documentation check and dependency audit (step 3a) are listed as parallel review generators alongside `/code-review` and `/self-eval`, but they are manual checks with no skill/tool support. The "run in parallel" instruction is ambiguous — clarify these are developer-performed checks while skills run. | Clarity gap | Self-eval, Code review | ✅ Fixed — labeled as "(manual)" and clarified instruction to "run skills in parallel; perform manual checks while waiting" |

## 🟢 Consider

| # | Idea | Source | Status |
|---|---|---|---|
| C1 | `docs/reviews/self-eval-review-fix-loop.md` line 16 describes the old pipeline ordering as a factual claim. Reads as current state, not historical observation. | Code review | Noted — snapshot-in-time artifact, acceptable as-is |
| C2 | Step 4 shows `git rebase -i origin/main` as a code block — this is interactive and cannot be run by Claude Code. Note as human-performed or remove the code block. | Self-eval | Noted — pr-prep is a human workflow; interactive rebase is appropriate |
| C3 | Step numbering continues across phases (1-3, 4-6). Consider restarting per phase or adding a note about continuous numbering. | Self-eval | Noted — continuous numbering enables cross-references (e.g., "step 6" from step 1a) |
| C4 | `guides/post-pr-retrospective.md` uses `SS3` notation for step reference — coincidentally still correct but fragile against future renumbering. | Code review | Noted |
| C5 | `AGENTS.md` and `README.md` descriptions of pr-prep are generic enough to not need updating, but could better reflect the two-phase framing. | Code review | Noted |
| C6 | New review sub-steps lack skill references (no `/doc-check` or `/dep-audit` skills exist). If planned, a "manual for now" note would set expectations. | Code review | Addressed by A3 fix — "(manual)" label sets expectations |
| C7 | Retrospective section: enforcement gap and storage ambiguity carried forward unchanged from prior self-eval. No retrospective artifacts exist in `docs/thoughts/`. | Self-eval | Noted — pre-existing, not introduced by this PR |

## ✅ Verified

| Claim | Verdict |
|---|---|
| Decision log entry #7 date (2026-04-06) matches decision record | ✅ Accurate |
| Cross-reference `[decision 007](../docs/decisions/007-two-phase-pr-prep.md)` resolves correctly | ✅ Accurate |
| Cross-reference `[orchestrated review pattern](../patterns/orchestrated-review.md)` resolves correctly | ✅ Accurate |
| `review-fix-loop.md` "Phase 1, step 3" matches pr-prep numbering | ✅ Accurate |
| Decision log summary aligns with full decision record content | ✅ Accurate |
| Decision record's three fixes map 1:1 to three Context problems | ✅ Accurate |
| Step 1a reference to "step 6" correctly points to PR description in new numbering | ✅ Accurate |
| Tests pass after fix (workflow-required-sections 3/3) | ✅ Verified |
