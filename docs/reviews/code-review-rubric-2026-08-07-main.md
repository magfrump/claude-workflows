# Code Review Rubric

**Commit:** 2f5ad0b
**Scope:** `HEAD~3..HEAD` on `main` (de9ccf7, 45fa1df, 2f5ad0b) | **Reviewed:** 2026-08-07 | **Status: 🟡 CONDITIONAL PASS** — 2 amber item(s) awaiting resolution or justification (R1 + 8 ambers fixed in iteration 1; A3/A7 fixed in iteration 2 per decision log row 35)

Pipeline: fact-check k=3 (merged most-severe-wins, agreement 23/27) → critics: performance, api-consistency (core; security skipped by Stage-1.5 gate), test-strategy, tech-debt-triage (contextual). Dispatch mode: parallel. Fact-check gate fired (2 Incorrect-high) — autonomous session, proceeded with "Continue"; both findings tiered below under decision-031 tier policy T.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | Step 1's new conditional diff-inlining policy (`SKILL.md:99`, `:228-285`) is contradicted by the three instruction surfaces an orchestrator actually executes: Stage-1 dispatch step 3 (`:340-344`), Stage-2 dispatch step 3 (`:634`), and Important Reminders "**Pass scope, not diffs**" (`:1406`) — all still command unconditional self-read. Lever #3 ships inert (or, if both are followed, *additive*: inlined prefix **plus** every critic re-fetching, raising per-pass cost above the pre-change baseline). Convergence: fact-check Stale 3/3 replicates + api-consistency **Breaking** + performance **High** + tech-debt **Fix now** + test-strategy escalation. Contested-Soundness annotation: intent (`:99` "inline it once as the shared cacheable prefix") and defeating mechanism (`:1406` "Pass scope, not diffs") both quoted verbatim in the reports. | API consistency (+ Performance) | Breaking (native) | `skills/code-review/SKILL.md:340-344,634,1406` vs `:99` | for-author | — | ✅ Fixed (iter 1 — all three sites now cross-reference Step 1's conditional rule; guarded by new `test/skills/code-review-context-delivery.bats`) |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Hunt doc claims "both already fixed, HEAD clean" — false for candidate A (its own line 13 says the comment "persists unchanged at HEAD"; external repo confirms). Tiered 🟡 not 🔴 per decision-031 policy T (doc-subject; only consequence is a misinformed reader) — but this is a decision-feeding evidence doc with forward-quote risk. | Fact-check | Incorrect (High) | Fact-check (r1; corroborated by r2/r3 observations) | for-author | — | ✅ Fixed (iter 1 — corrected with dated correction note in hunt doc) | — |
| A2 | `candB-fact-check.md:8-9` header summary miscounts its own body: says 7 verified / 1 unverifiable; body has 8 Verified / 0 Unverifiable. | Fact-check | Incorrect (High) | Fact-check (r1) + api-consistency #7 + tech-debt item 4 | for-author | — | ✅ Fixed (iter 1 — header now 8/0, correction comment added) | — |
| A3 | The inlined shared block has no numeric budget: `SKILL.md:248` forward-references "the budget below" but the size guard (`:261-266`) contains no number and keys off diff line count / churn — the wrong quantity, since the payload is dominated by enclosing-file bytes (measured spread 7,663–69,575 chars/cell). Failure is a cliff: an over-budget prefix breaks the whole parallel wave pre-dispatch. | Performance | High | performance-reviewer #2 (+ test-strategy Q2 on the `>40%-churn` mis-citation: `:263` cites it as a size threshold; `:116` defines it as a size-independent per-file greenfield rule) | for-author | — | ✅ Fixed (iter 2 — 25k-token budget (chars/4) on the assembled block, degrade ladder inline→diff-only→self-read, churn removed from the delivery gate; log row 35; pinned by contract tests 7–9) |
| A4 | Decision docs still describe the pre-inlining loop in the present tense: 032:120-126 "The production Agent-tool loop does **not** inline — critic agents self-read"; 032:103 names the pre-rename heading "Shared-context prefix"; `log.md:53` "the production SKILL has critics self-read". Made false by 2f5ad0b — the #4 bullet was recalibrated, the #3 bullet was not. | API consistency | Inconsistent | api-consistency #2 + tech-debt item 2 + test-strategy escalation | for-author | — | ✅ Fixed (iter 1 — 032 #3 bullets + log row 34 now past-tense with pointer to 2f5ad0b; ~5% marked as projection) | — |
| A5 | Normative sibling docs restate the old delivery rule: `guides/sub-agent-briefing.md:78` "For code review, sub-agents run their own `git diff` rather than receive a pasted diff"; `patterns/orchestrated-review.md:153` (cited as normative by `SKILL.md:648`). Outside the diff but made stale by it. | API consistency | Inconsistent | api-consistency #3 | for-author | — | ✅ Fixed (iter 1 — both docs now state the inline-prefix exception) | — |
| A6 | Hunt-verify sub-run breaks the run's own record conventions: flat `cand{A,B}-critic-*.md` files vs the `<instance>/critic-<domain>.md` layout `manifest.json`'s resume procedure keys on; the sub-run's 8 agents / 577,971 tokens absent from `manifest.json` and `token-ledger.md`; raw per-agent figures exist only as prose from ephemeral task notifications. | API consistency | Inconsistent | api-consistency #4+#5 + fact-check Unverifiable (Claim 16) + tech-debt item 3 | for-author | — | 🟡 Open | Per tech-debt triage: fix is the provenance convention at the *next* measurement run (ledger rows at measurement time); retroactive transcription is cosmetic |
| A7 | Prefix ordering forfeits cross-pass cache warmth: the diff sits at shared-block position 2, ahead of four parts stable across the whole loop, so every fix commit invalidates essentially the entire cacheable prefix. Reorder stable-parts-first. | Performance | Medium | performance-reviewer #3 | for-author | — | ✅ Fixed (iter 2 — shared block reordered stable-parts-first, diff+enclosing now part 5 of 6; pinned by contract test 10) |
| A8 | "Leave it on because it is free" / "0% of token count" (`SKILL.md:276-278`) is not established for the newly inlined enclosing-file half — inlining adds real prompt tokens each agent previously fetched selectively; the 5.3% figure is a pre-change projection (`levers-3-4-measurement.md:33-48`), not a post-restructure measurement. | Performance | Medium | performance-reviewer #4 (+ #7, tech-debt "Measured vs projected" rider) | for-author | — | 🟡 Open | Resolvable only by a post-restructure measurement of ≥1 cell against the 2.99M baseline |
| A9 | 032:135-136 "~1 clean trigger in 225 commits" — rate holds, but the candidate the hunt labelled the "clean trigger" (A/throttle) is the one that did NOT fire; B fired. Tighten to "~1 empirically-confirmed trigger in 225 (not the predicted one)". | Fact-check | Mostly accurate | Fact-check (Claim 3) | for-author | — | ✅ Fixed (iter 1 — "~1 empirically-confirmed trigger … not the predicted one") | — |
| A10 | Hunt doc wording precision: line 11-14 "persists **unchanged** at HEAD" (docstring later gained a `.cancel()` line) and line 40-41 "the fix-commit message says so outright" (message states the field mismatch, not the no-op consequence). | Fact-check | Mostly accurate | Fact-check (Claims 6, 10) | for-author | — | ✅ Fixed (iter 1 — both phrasings tightened) | — |
| A11 | `candB-fact-check.md:129-131` cites `integrateValidation.ts:56`; the quoted line sits at `:51` at 6cf4b0d. | Fact-check | Mostly accurate | Fact-check (Claim 13) | for-author | — | ✅ Fixed (iter 1 — :56 → :51, both occurrences) | — |
| A12 | `SKILL.md:239-243` "agents self-reading via tools shares no prefix" overstates the source, which measured a ~330-token shared instruction prefix ("barely shares a prefix", ~8k across the canon). | Fact-check | Mostly accurate | Fact-check (Claim 19, 2/3 replicates) | for-author | — | ✅ Fixed (iter 1 — "share only a ~330-token instruction prefix") | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Land a diff-delivery contract bats suite (`test/skills/code-review-context-delivery.bats`): negative assertion that every `runs its own git diff` / `Pass scope, not diffs` line carries a conditionality marker — fails today at the three R1 sites; the one test that would have caught this commit as landed. Ship with the R1 fix in the same commit. | test-strategy (rec 1, closes G1–G4) | Consider | for-author | — | 🟢 Open |
| C2 | Pin both arms of the #4 short-circuit prose (incl. the "not the common case" polarity inversion) and add a lever-measurement drift guard binding 238,155 / ~73% / 0-of-8 across SKILL.md, 032, log.md, and the run artifact (model: `test/sandbox-tool-map-drift.bats`). | test-strategy (recs 2–3, closes G6–G10) | Consider | for-author | — | 🟢 Open |
| C3 | State the expected value next to the bolded #4 conditional (~73.3% × ~1/225 ≈ 0.33%/pass) so the "rare big win" framing carries its own denominator. | performance-reviewer #5 | Low | for-author | — | 🟢 Open |
| C4 | Emit the inline-vs-self-read mode decision in a parseable form (rubric field or fixed plan-summary phrase), not free prose (`SKILL.md:265`). | performance-reviewer #6 | Low | for-author | — | 🟢 Open |
| C5 | `hunt-verify/results.md` cited by bare relative path from 032:129-130 and log.md:53 — unresolvable from the decision docs' directory; use repo-rooted paths. | api-consistency #6 | Minor | for-author | — | 🟢 Open |
| C6 | `workflows/pr-prep.md:223-231` restates #4 with the pre-measurement savings promise the SKILL just downgraded. | api-consistency #8 | Minor | for-author | — | 🟢 Open |
| C7 | `canon-adjacent` (`SKILL.md:494-496`) is a new, undefined provenance label with no precedent — define it or reuse an existing term. | api-consistency #9 | Minor | for-author | — | 🟢 Open |
| C8 | SKILL.md accretion: 857→1440 lines in 17 days (+68%), 2.1× the largest sibling skill. Defer and monitor — a split risks perturbing experiment-validated text; the confirmed harm (restatement drift) is addressed by fixing R1 via cross-reference, not restatement. | tech-debt item 5 | Consider | for-author | — | 🟢 Open |
| C9 | Provenance convention for future measurement runs: append per-agent token rows to a ledger at measurement time (the canon's `token-ledger.md` pattern); retrospective transcription of the hunt figures would be cosmetic. | tech-debt item 3 | Consider | for-author | — | 🟢 Open |
| C10 | 032 Decision section's "biggest input-token lever" framing vs its own measured section (pre-existing tension, not introduced by this range). | api-consistency #10 | Informational | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (The single entry in `docs/reviews/override-log.md` — 2026-06-23, `hooks/batch-feedback-routing-reminder.sh` firing breadth, security-Low — matches this diff on neither location, category, nor substance.)

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.
Every row carries `Evidence` and has passed the Confirmed-Good cross-check (checked against the
merged report and all three per-replicate reports at `Commit: 2f5ad0b`; no inconsistent
observations found for the rows below).

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| All derived arithmetic in the measurement artifacts is internally consistent | ✅ Confirmed | Enumeration executed ×3 replicates (python3): 74,502+84,050+79,603=238,155; 86,824+238,155=324,979; 238,155/324,979=73.28%; 62,230+65,996+58,049=186,275; 66,717+186,275=252,992; 252,992+238,155+86,824=577,971 — every derived number in `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-59` follows from its own inputs | Fact-check (Claims 1, 14) | for-orchestrator-synthesis |
| Commit-message test claims are true at HEAD | ✅ Confirmed | Executed: `bats test/code-review-gate.bats` → 19 ok / `bats test/skills/code-review-format-contract.bats` → 17 ok, re-run independently by all 3 replicates 2026-08-07 (and the orchestrator's full-suite run: 340/340) | Fact-check (Claim 30) | for-orchestrator-synthesis |
| "No rubric-template change" | ✅ Confirmed | Enumeration: `git diff HEAD~3..HEAD -- test/` empty; 2f5ad0b hunks at `@@ -96`, `@@ -225`, `@@ -471` all precede the template at `skills/code-review/SKILL.md:927`; format-contract template cross-check tests pass | Fact-check (Claim 31) | for-orchestrator-synthesis |
| #4 recalibration prose is faithful to its evidence — the n=1 case is presented as one case, the correction of "the common case" matches `results.md:38-45`, and the negative result (candidate A: real red, 0 saving) was kept rather than dropped | ✅ Confirmed | `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:19` — "#4 saving = 238,155 tokens = 73.3% of the red-gated pass"; `results.md:31-36` — "A red was present and #4 still saved nothing"; `skills/code-review/SKILL.md:493-504` matches both | Fact-check (Claims 22, 23) + performance-reviewer | for-orchestrator-synthesis |

(A candidate row "SKILL #3 claims match the measurement doc" was **not** published: the tech-debt and performance reports observe that `SKILL.md:276` labels the benefit "Measured" while `levers-3-4-measurement.md:33-48` presents 5.3% as a projection conditional on the restructure — that tension lives in A8 instead.)

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (Orchestrator spot-verified the 🔴/🟡 rows' citations directly: `guides/sub-agent-briefing.md:78`, `patterns/orchestrated-review.md:153`, `docs/decisions/032-review-loop-token-reduction-levers.md:120-126`, `docs/decisions/log.md:53`, `skills/code-review/SKILL.md:247-266,276,634,1406`, `runs/review-arms/baseline-2026-08-06/manifest.json`.)

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| security-reviewer | Diff is prose/docs-only with no auth, input-handling, crypto, file-I/O, network, serialization, or risky string-literal content; zero fact-check claims in domain | `git diff HEAD~3..HEAD --stat`: 14 files, all `.md`; merged fact-check report contains no security-domain claim (the proto-pollution mention describes an external repo's historical state inside a run artifact, not this diff's surface) |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
