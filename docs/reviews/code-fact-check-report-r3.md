# Code Fact-Check Report

**Commit:** 2f5ad0b
**Repository:** /workspace
**Scope:** Commit range `HEAD~3..HEAD` (de9ccf7, 45fa1df, 2f5ad0b) — changed files plus the three commit messages
**Checked:** 2026-08-07
**Total claims checked:** 24
**Summary:** 20 verified, 2 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read before checking; it contains no entries yet (paraphrased — no quote available because the claim covers absence of content: the Patterns section ends at its append marker with no entries). No claim in this run matched a fabrication pattern, and no Incorrect verdicts were produced, so no log update is required.

External-repo note: the hunt/measurement docs reference commits in the `mfc` project. That repo IS accessible locally at `/workspace/external/meta-formalism-copilot` (HEAD `7f30210`), with pinned worktrees at `runs/review-arms/baseline-2026-08-06/wt-candA` (checked out at `e59c7ed`) and `wt-candB` (at `6cf4b0d`), so reference claims were verified directly rather than marked Unverifiable.

---

## Claim 1: "fact-check confirmed the behavioral 🔴 and #4 skipped the whole critic panel = **238,155 tokens = 73% of that pass**"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:126-128`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The cited measurement doc records exactly these numbers:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-19
| **panel total (what #4 skips)** | **238,155** | |
- Pass **without** #4 = 86,824 + 238,155 = **324,979**
- **#4 saving = 238,155 tokens = 73.3% of the red-gated pass.**
```

Arithmetic re-checked with python3: 74,502 + 84,050 + 79,603 = 238,155; 86,824 + 238,155 = 324,979; 238,155 / 324,979 = 73.28% (paraphrased — no quote available because these are computed values, not source snippets). The candB fact-check report itself carries the confirming verdict — `**Verdict:** Incorrect` / `**Confidence:** High` on a `**Type:** Behavioral (data contract)` claim (`runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:71-73`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-19`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:68-113`

---

## Claim 2: "a second hunted commit (throttle) had a real red that api-consistency rated **Breaking** while fact-check classified it **🟡 (impact masked)** → #4 **did not fire, 0 saving despite the red**"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:128-130`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The candA api-consistency report's findings table shows two Breaking findings on the throttle contract:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:72-73
| 1 | Advertised `.cancel()` method not implemented | Breaking | `throttle.ts:9-25` | High |
| 2 | JSDoc "last call always delivered" contradicts impl | Breaking | `throttle.ts:1-2,18-24` | High |
```

The candA fact-check report rates the same claim `**Verdict:** Incorrect` / `**Confidence:** High` and then argues masked consumer impact under a "Consumer impact and subject classification" heading, quoting the consumers' cumulative-snapshot + final-flush pattern (`candA-fact-check.md:52-86`). The 🟡 classification and the resulting no-fire/0-saving are recorded in `results.md:25` ("Incorrect(High) but **subject comment/doc → 🟡** … **gate does not fire**") and `results.md:31` ("**#4 saving = 0.**"). Note the 🟡 is the tier-policy-T classification recorded by the run, not the fact-check report's own verdict field — the decision text's phrasing "fact-check classified it 🟡" compresses this correctly enough that no verdict downgrade is warranted (paraphrased — no quote available because the point is the relation between two documents' fields, not a single snippet).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:29-73`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-fact-check.md:48-86`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-36`

---

## Claim 3: "P low (0/8 canon; ~1 clean trigger in 225 commits)"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:132-133`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The 0/8 figure matches the underlying measurement doc: "Across all 8 cells, fact-check produced **zero** behavioral 🔴" (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:70-72`). The 225-commit denominator is real — `git rev-list --count HEAD` in the external repo returns 225 (paraphrased — no quote available because the evidence is a command result, not file content). "~1 clean trigger" is consistent with the empirical outcome: 2 candidates were hunted and exactly 1 (B) fired the gate (`hunt-verify/results.md:42-45`: "the 225-commit hunt found **2** candidates, and **1 of those 2 (A) still classified 🟡**"). One nuance worth knowing but not verdict-changing: the hunt doc predicted A (throttle) as "the best fact-check trigger" and B as the weaker fit (`hunt-factcheck-behavioral-lie.md:11,30`), and the empirical run inverted that — B fired, A did not. The count "~1 in 225" survives the inversion. Confidence Medium because the 0/8 canon tally is only checkable against the measurement doc's own record, not re-runnable.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:68-72`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:42-45`, `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:9-46`

---

## Claim 4: log row 34 — "#4 … measured ~73% saving when it fires, but the trigger is rare … the empirical run confirmed one fires (evidence-integrate: fact-check 🔴 → skip 238,155-token panel = 73% of the pass) and one does NOT (throttle: real red but fact-check graded it 🟡 …)"

**Location:** `docs/decisions/log.md:53`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All numeric claims match the sources checked in Claims 1–3 (238,155; 73%; 0/8; one-fires-one-does-not), and row 34's text is consistent with the amended 032 full record — both describe the same split, the same mechanism ("parallel wave already dispatched"), and the same verdict ("keep wired for loop safety … not … a steady reducer") (paraphrased — no quote available because the check is cross-document consistency over two long passages already quoted in Claims 1–2). No disagreement between log.md row 34, 032's amended #4 bullet, and the hunt-verify docs was found.

**Evidence:** `docs/decisions/log.md:53`, `docs/decisions/032-review-loop-token-reduction-levers.md:124-135`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:1-59`

---

## Claim 5: "Exhibiting commit: `e59c7ed` … introduced the utility + the false comment; the comment persists **unchanged at HEAD**"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:12-14`
**Type:** Reference / Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Commit `e59c7ed` ("feat: SSE streaming with partial-JSON previews for all artifact panels (#94)") exists in the external repo and its stat shows `app/lib/utils/throttle.ts | 26 ++` — the file's introduction (paraphrased — no quote available because the evidence is `git show --stat` output). The false sentence does persist verbatim at HEAD:

```
// external/meta-formalism-copilot/app/lib/utils/throttle.ts:1-3 (at HEAD 7f30210)
/** Returns a throttled version of `fn` that runs at most once per `ms` milliseconds.
 *  The last call is always delivered (trailing edge).
 *  Call `.cancel()` to clear any pending trailing-edge timer. */
```

"Unchanged" is the imprecision: the specific false line (line 2) is byte-identical, but the docstring block was later extended with a third `.cancel()` line (absent at `e59c7ed`, where the block is two lines — `wt-candA/app/lib/utils/throttle.ts:1-2`), and `.cancel()` was subsequently implemented. The precise version: "the false sentence persists verbatim at HEAD; the surrounding docstring gained a line."

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candA/app/lib/utils/throttle.ts:1-2`, `external/meta-formalism-copilot/app/lib/utils/throttle.ts:1-3`

---

## Claim 6: "`throttle.ts:19-25` schedules the trailing timer only when none is set and captures the **first** blocked call's args; later calls in the window are silently dropped. The actual *last* call is never delivered."

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:15-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Read directly at the pinned candidate-A checkout:

```ts
// runs/review-arms/baseline-2026-08-06/wt-candA/app/lib/utils/throttle.ts:18-24
} else if (!timer) {
  timer = setTimeout(() => {
    lastRun = Date.now();
    timer = null;
    fn(...args);
  }, remaining);
}
```

The `else if (!timer)` guard means a second-and-later in-window call takes neither branch (when `remaining > 0` and a timer exists) and returns without recording its args; the closure's `args` are frozen from the call that armed the timer (paraphrased — no quote available because the drop is the *absence* of an else branch — there is no code to quote for the dropped path). So when ≥2 calls land in a window, the timer delivers the first blocked call, not the last — the doc claim's contradiction description is correct.

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candA/app/lib/utils/throttle.ts:7-25`

---

## Claim 7: "Consumer: `useFormalizationPipeline.ts:66-68` (+ `:96,:188`, `useDecomposition.ts:130`, `useArtifactGeneration.ts:73`)"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:18-20`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every cited line resolves to a live `throttle(...)` call site at external-repo HEAD:

```ts
// external/meta-formalism-copilot/app/hooks/useFormalizationPipeline.ts:66
      const onToken = throttle((accumulated: string) => {
```

and grep confirms the rest — `useFormalizationPipeline.ts:96`, `:188`, `useDecomposition.ts:130`, `useArtifactGeneration.ts:73` each match `throttle((accumulated: string) => {` (paraphrased — no quote available because five near-identical one-line hits read more clearly as a grep summary). The doc's caveat that callers do a final flush plus `onToken.cancel()` also checks out at HEAD (`useFormalizationPipeline.ts:71,102,201` call `.cancel()`). Note the line numbers are HEAD-relative; at `e59c7ed` itself only two of the sites exist (lines 66 and 179) — the doc cites current consumers, which is the natural reading.

**Evidence:** `external/meta-formalism-copilot/app/hooks/useFormalizationPipeline.ts:66-72`, `external/meta-formalism-copilot/app/hooks/useDecomposition.ts:130`, `external/meta-formalism-copilot/app/hooks/useArtifactGeneration.ts:73`

---

## Claim 8: Candidate B — "schema doc says the artifact field is `counterexamples[i].scenario`" (route.ts:46-58); "the real artifact type is `scenarios`"; "`integrateValidation.ts:51` → `resolveFieldPath(artifact, fieldPath)` returns null … every … proposal is dropped"; "introduced by `6cf4b0d`, fixed by `2493d2a`"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:30-41`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

At the pinned candidate-B checkout the schema doc names the wrong key:

```ts
// runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/route.ts:46-56
  counterexamples: `The artifact is a counterexamples analysis with this structure:
{
  ...
  "counterexamples": [{ "id": "string", "scenario": "string", ... }],
  ...
- "counterexamples[i].scenario" — a counterexample scenario
```

while the real type uses `scenarios` (`wt-candB/app/lib/types/artifacts.ts:115-118`: `counterexamples: { claim: string; scenarios: Array<{ ... }>`). The drop mechanism is real:

```ts
// runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/integrateValidation.ts:51
  if (!resolveFieldPath(artifact, fieldPath)) return null;
```

Commits verified in the external repo: `6cf4b0d` ("feat: add assisted evidence integration with approve/reject proposals (Phase 4)") adds `route.ts` (+247 lines) and `integrateValidation.ts`; `2493d2a` is titled exactly "fix: rename counterexamples→scenarios in evidence-integrate schema docs" and touches only `app/api/evidence-integrate/route.ts`; `c2f5e8c` exists in the range (paraphrased — no quote available because the evidence is `git show --stat` output for three commits).

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/route.ts:46-58`, `runs/review-arms/baseline-2026-08-06/wt-candB/app/lib/types/artifacts.ts:115-128`, `runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/integrateValidation.ts:51`

---

## Claim 9: "Scanned all 225 commits reachable from HEAD via a 3-way subsystem fan-out"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

`git rev-list --count HEAD` in `external/meta-formalism-copilot` returns 225, so the denominator is exact, not approximate (paraphrased — no quote available because the evidence is a command result). The "3-way subsystem fan-out" process claim (that three agents actually scanned everything) is a run-history assertion that static analysis cannot re-execute — Medium confidence covers that residual; the checkable part (the count) is exact.

**Evidence:** `external/meta-formalism-copilot` (git history), `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:7`

---

## Claim 10: results.md Candidate B table — panel total 238,155; "Pass **without** #4 = 86,824 + 238,155 = **324,979**"; "#4 saving = 238,155 tokens = 73.3% of the red-gated pass"; per-agent verdict summaries

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-19`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

python3 check: 74,502 + 84,050 + 79,603 = 238,155; 86,824 + 238,155 = 324,979; 238,155/324,979 = 73.28% ≈ 73.3% (paraphrased — no quote available because these are computed values). The verdict column matches each underlying report: candB fact-check `**Verdict:** Incorrect` / `**Confidence:** High` (`candB-fact-check.md:72-73`), security's top finding `**Severity:** Medium` (`candB-critic-security.md:24`), api-consistency `**Severity:** Breaking` on the field-key defect (`candB-critic-api-consistency.md:34,79`), and architecture:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/candB-critic-architecture.md:82
| 1 | LLM field-path contract decoupled from artifact types (drift is silent) | Structural | `route.ts:38-71` / `artifacts.ts:70-134` | High |
```

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-19`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:68-113`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-critic-security.md:24`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-critic-api-consistency.md:34-79`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-critic-architecture.md:25-82`

---

## Claim 11: results.md Candidate A table — panel total 186,275; "Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**"; per-agent verdict summaries ("2 Breaking", "5 Consider", perf "Low")

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-31`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

python3 check: 62,230 + 65,996 + 58,049 = 186,275; 66,717 + 186,275 = 252,992 (paraphrased — no quote available because these are computed values). Verdict summaries match the reports: api-consistency's table lists exactly two Breaking rows (quoted under Claim 2, `candA-critic-api-consistency.md:72-73`); test-strategy carries five `Severity: Consider` entries (`candA-critic-test-strategy.md:20-28`); performance's lead finding is `**Severity:** Low` (`candA-critic-performance.md:34`); fact-check is `**Verdict:** Incorrect` / `**Confidence:** High` with the masked-impact consumer analysis (`candA-fact-check.md:52-86`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-31`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-test-strategy.md:20-28`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-performance.md:34`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-fact-check.md:48-86`

---

## Claim 12: "Per-agent tokens from task notifications. Both candidates run as a single `--loop-pass`" (and the hunt cost "≈ 335k")

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3-4,59`
**Type:** Configuration / Reference
**Verdict:** Unverifiable
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The raw per-agent token figures (86,824; 74,502; …) and the "≈ 335k" hunt cost originate from Agent-tool task notifications at run time. No transcript or notification log for these runs is committed in the repo (paraphrased — no quote available because the claim covers absence of code/artifacts: no matching files found for these figures outside the results/summary docs themselves). The figures are internally consistent everywhere they are repeated (Claims 10, 11, 13, 22), but the primary measurements cannot be confirmed or refuted by static analysis. Verifying them would need the original session's task-notification records. High confidence in the *Unverifiable* verdict itself: the search for grounding artifacts was thorough.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3-4,57-59`

---

## Claim 13: "A pass 252,992 (fc 66,717 + panel 186,275) + B panel 238,155 + B fc 86,824 = **577,971 tokens**"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:58-59`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

python3 check: 252,992 + 238,155 + 86,824 = 577,971 — exact match (paraphrased — no quote available because this is a computed value). The addends are the same figures tabulated earlier in the file (`results.md:15-31`), so the doc is internally consistent.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-31,57-59`

---

## Claim 14: levers doc EMPIRICAL UPDATE — "**When #4 fires it cuts ~73% of the pass** (candidate B … fact-check 86,824 confirms the behavioral 🔴, panel of 238,155 skipped → pass 324,979 → 86,824) … Expected loop saving ≈ P(fact-check-visible red) × ~73%, and P is low (canon 0/8; 1 clean trigger in 225 commits)"

**Location:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:94-103`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every figure matches `hunt-verify/results.md` (checked in Claims 1, 3, 10, 11) and the doc's own pre-existing 0/8 record earlier in the same file: "Across all 8 cells, fact-check produced **zero** behavioral 🔴" (`levers-3-4-measurement.md:70-71`). The A-side characterization ("api-consistency rated it **Breaking** — yet fact-check classified it **🟡**") matches the candA reports per Claim 2 (paraphrased — no quote available because the cross-checks were already quoted under Claims 1–3 and 10–11).

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:68-103`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-45`

---

## Claim 15: SKILL.md still says "**Pass scope, not diffs.** Each agent runs its own `git diff`…" (and both stage dispatch steps still say the same) after Step 1 made diff delivery conditional

**Location:** `skills/code-review/SKILL.md:1406` (also `:340`, `:634`)
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

Step 1 (edited in 2f5ad0b) now makes inlining the default for normal-sized diffs:

```
// skills/code-review/SKILL.md:99
Diff delivery to agents is conditional (decision 032 #3, …): for a normal-sized diff, inline it once as the shared cacheable prefix of every agent prompt; for a **large diff** … pass the scope specification so each agent runs its own `git diff` …
```

and the new prefix section applies to "Every Stage-1 replicate and Stage-2 critic prompt" (`SKILL.md:230`). But three un-updated statements still prescribe the pre-#3 behavior unconditionally:

```
// skills/code-review/SKILL.md:1406 (Important Reminders)
- **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.
```

```
// skills/code-review/SKILL.md:634 (Stage 2 step 3)
3. Include the scope specification so the agent runs its own `git diff`. …
```

Stage 1 step 3 (`SKILL.md:340-341`) likewise instructs including the scope spec with no mention of the inline-prefix mode (paraphrased — no quote available because the staleness there is the *absence* of the conditional language, not a contradicting sentence). An orchestrator following the Important Reminders or the stage dispatch steps literally would never inline, silently reverting #3 to the "captures ~nothing" configuration the same commit documents. These were accurate before 2f5ad0b and were not updated with it.

**Evidence:** `skills/code-review/SKILL.md:99`, `skills/code-review/SKILL.md:230-266`, `skills/code-review/SKILL.md:340-341`, `skills/code-review/SKILL.md:634`, `skills/code-review/SKILL.md:1406`

---

## Claim 16: "the 2026-08-06 measurement … found the benefit is only captured when the shared material is actually inlined as one cacheable prefix; agents self-reading via tools shares no prefix and captures ~nothing"

**Location:** `skills/code-review/SKILL.md:239-242`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The cited measurement doc supports the substance but not the absolute "shares no prefix":

```
// runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-29
**Second finding — the SKILL path barely shares a prefix.** In the production loop … critic agents are given a scope spec and **self-read** the diff … The genuinely byte-identical shared *prompt prefix* was my ~250-word instruction block (~330 tokens). So the **realized** #3 saving on the as-run structure ≈ 330 × (N−1) × 0.9 per cell ≈ **~1–1.5k cost-equiv/cell, ~8k across the canon — negligible.**
```

"Captures ~nothing" is a fair gloss of "~8k across the canon — negligible" against a 2.99M baseline, and "only captured when … inlined" matches the doc's "Realizing #3 requires **restructuring the SKILL to inline**" (`levers-3-4-measurement.md:30-31`). The precise version of the overstated part: self-reading shares only a ~330-token instruction prefix ("barely shares a prefix"), not literally none.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-31`, `skills/code-review/SKILL.md:239-242`

---

## Claim 17: "**Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a billing-rate effect, not a token-count reduction)"

**Location:** `skills/code-review/SKILL.md:276-278`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The measurement doc's bottom line matches on both axes:

```
// runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:48
**≈157k cost-equivalent ÷ 2.99M ≈ 5.3% of input cost, 0% of token count**
```

python3 check: 157,400 / 2,986,091 = 5.27% — single-digit (paraphrased — no quote available because this is a computed value). The billing-rate framing matches `levers-3-4-measurement.md:20-23` ("prompt caching does not reduce the number of tokens *processed* … reduces the *billing rate*").

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:20-59`, `skills/code-review/SKILL.md:276-278`

---

## Claim 18: fact-check-gate trigger "measured at **~73% of the pass** on the one canon-adjacent case that fired it (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`)" and "**not** the common case"

**Location:** `skills/code-review/SKILL.md:493-499`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The referenced file exists and records "**#4 saving = 238,155 tokens = 73.3% of the red-gated pass**" (`results.md:19`), on exactly one fired case of two attempted (Claims 10–11); arithmetic re-verified at 73.28% (paraphrased — no quote available because computed). The rarity framing matches `results.md:42-45` ("It fires rarely … canon reviewed states **0/8** … only ~half [of the 2 hunted candidates] actually trip the gate"). "Canon-adjacent" is a fair label: the hunted commits are from the external benchmark repo's history, not the 8-cell canon itself (paraphrased — no quote available because this is a characterization spanning the hunt doc and canon docs).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:19,40-49`, `skills/code-review/SKILL.md:493-499`

---

## Claim 19: critic-stage trigger "saves little in practice: the core panel is one parallel wave already in flight … (measured: a critic-surfaced red saved 0)"

**Location:** `skills/code-review/SKILL.md:500-504`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Candidate A is the measured instance: it carried a critic-surfaced behavioral red (api-consistency Breaking, `candA-critic-api-consistency.md:72-73`, quoted under Claim 2) and the run recorded:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:31-36
- Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**
… because the panel is one **parallel wave** there is nothing to short-circuit mid-flight.
  **A red was present and #4 still saved nothing.**
```

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-36`, `skills/code-review/SKILL.md:500-504`

---

## Claim 20: commit de9ccf7 — "read-only scan, no code changed"

**Location:** de9ccf7 (commit message, Notes line)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The commit's diffstat shows exactly one added documentation file and nothing else: `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md | 67 ++++` , "1 file changed, 67 insertions(+)" (paraphrased — no quote available because the evidence is `git log --stat` output, not file content).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md` (sole file in de9ccf7)

---

## Claim 21: commit 45fa1df — "worktrees wt-candA/wt-candB gitignored"

**Location:** 45fa1df (commit message, Notes line)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both directories exist on disk and are covered by a pre-existing glob:

```
// .gitignore:45
runs/review-arms/baseline-2026-08-06/wt-*
```

`git check-ignore -v` confirms both `wt-candA` and `wt-candB` match that rule, and `git status` shows neither as untracked (paraphrased — no quote available because the evidence is command output). The rule predates this commit range — the message claims the state ("gitignored"), not that this commit added the rule, so that is consistent.

**Evidence:** `.gitignore:45`, `runs/review-arms/baseline-2026-08-06/wt-candA`, `runs/review-arms/baseline-2026-08-06/wt-candB`

---

## Claim 22: commit 45fa1df — "238,155 tokens = 73% of the pass"; "canon 0/8; ~1 clean trigger in 225 commits"; "Measurement cost ~578k + ~335k hunt"

**Location:** 45fa1df (commit message body)
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All figures match the artifacts the same commit adds: 238,155 = 73.3% of 324,979 (`results.md:15-19`, re-computed — Claim 10); 0/8 and the 225-commit denominator (Claims 3, 9); "~578k" matches the computed 577,971 (`results.md:58-59`, Claim 13). The "~335k hunt" component inherits Claim 12's caveat — consistent with `results.md:59` ("plus the earlier 3-agent history hunt ≈ 335k") but not independently checkable (paraphrased — no quote available because the cross-checks were quoted under the claims cited).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-19,42-45,57-59`

---

## Claim 23: commit 2f5ad0b — "format-contract 17/17 and gate 19/19 green"

**Location:** 2f5ad0b (commit message, Notes line)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Re-ran both suites at HEAD: `bats test/skills/code-review-format-contract.bats` produced 17 `ok` lines and no `not ok`; `bats test/code-review-gate.bats` produced 19 `ok` lines and no `not ok` (paraphrased — no quote available because the evidence is test-runner output; the combined run's final line was `ok 36 fixture does not contain draft-review verdict vocabulary`, and 19 + 17 = 36).

**Evidence:** `test/skills/code-review-format-contract.bats`, `test/code-review-gate.bats`

---

## Claim 24: commit 2f5ad0b — "Pipeline-prose edits only; no rubric-template change"

**Location:** 2f5ad0b (commit message, Notes line)
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The commit's only file is `skills/code-review/SKILL.md`, and its three hunks sit at `@@ -96,7 +96,7 @@`, `@@ -225,41 +225,61 @@`, and `@@ -471,12 +491,17 @@` (paraphrased — no quote available because the evidence is `git diff` hunk headers) — all within Step 1, the shared-context-prefix section, and the first-red short-circuit section. The rubric template lives under `## Deliverable 2: Code Review Rubric` starting at `skills/code-review/SKILL.md:927`, past every hunk. The template's test fixture `test/skills/code-review/rubric-current-format.md` has no commits in `HEAD~3..HEAD`, and `git diff HEAD~3..HEAD -- test/` is empty (paraphrased — no quote available because the claim covers absence of changes — empty diff output). The format-contract suite asserting template shape passes (Claim 23), corroborating no template drift.

**Evidence:** `skills/code-review/SKILL.md:927`, `test/skills/code-review/rubric-current-format.md`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- **Claim 15** (`skills/code-review/SKILL.md:1406`, also `:340`, `:634`): three un-updated instructions ("Pass scope, not diffs"; Stage 1 step 3; Stage 2 step 3) still prescribe unconditional agent self-read, contradicting Step 1's new conditional diff-inlining (2f5ad0b) — an orchestrator following them literally silently reverts lever #3; update all three to reference the inline-vs-self-read conditional.

### Mostly Accurate
- **Claim 5** (`runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:12-14`): the false throttle sentence persists verbatim at external HEAD, but "the comment persists unchanged" is imprecise — the docstring block later gained a `.cancel()` line (and `.cancel()` was implemented).
- **Claim 16** (`skills/code-review/SKILL.md:239-242`): "agents self-reading … shares no prefix" overstates the source, which measured a ~330-token shared instruction prefix (~8k cost-equiv across the canon — "barely shares a prefix", not none); "captures ~nothing" is fine.

### Unverifiable
- **Claim 12** (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3-4,59`): the raw per-agent token figures and the ≈335k hunt cost come from run-time task notifications with no committed transcript; verifying them would require the original session's notification records. (All derived arithmetic on those figures checks out.)

## Goal-Alignment Note
- Answered: yes
- Out of scope: quality/design review of the SKILL.md changes and of the candA/candB critic reports' analytical soundness (fact-check verifies documentation-vs-artifact match only); commits outside HEAD~3..HEAD treated as context per the partial-scope rule
- Escalate: Claim 15 — SKILL.md:340/:634/:1406 still mandate unconditional agent self-read, contradicting the new conditional inlining at SKILL.md:99/230-266; this internal contradiction will make orchestrators skip lever #3 in practice
- Questions I would have asked: none — scope was clear
