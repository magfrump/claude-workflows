# Code Fact-Check Report

**Commit:** 2f5ad0b

**Repository:** /workspace
**Scope:** Commit range `HEAD~3..HEAD` (de9ccf7, 45fa1df, 2f5ad0b): `skills/code-review/SKILL.md`, `docs/decisions/032-review-loop-token-reduction-levers.md`, `docs/decisions/log.md` row 34, `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md`, `runs/review-arms/baseline-2026-08-06/hunt-verify/*`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`, plus the three commit messages
**Checked:** 2026-08-07
**Total claims checked:** 29
**Summary:** 20 verified, 2 mostly accurate, 3 stale, 2 incorrect, 2 unverifiable

Pre-check: `docs/reviews/hallucination-patterns.md` read — the Patterns section is empty (no logged suspect patterns to compare against).

External-repo note: the hunted commits live in `/workspace/external/meta-formalism-copilot` (HEAD `7f30210`), with worktrees `wt-candA` (pinned `e59c7ed`) and `wt-candB` (pinned `6cf4b0d`) under `runs/review-arms/baseline-2026-08-06/` — all accessible, so external-repo reference claims were spot-checked directly rather than marked Unverifiable.

---

## Claim 1: "Empirically fired on a hunted commit (evidence-integrate `counterexamples`/`scenarios`, `hunt-verify/results.md`): fact-check confirmed the behavioral 🔴 and #4 skipped the whole critic panel = **238,155 tokens = 73% of that pass**"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:129-131`
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

Arithmetic checked with python3: 74,502 + 84,050 + 79,603 = 238,155; 86,824 + 238,155 = 324,979; 238,155 / 324,979 = 73.28% ≈ "73%" (paraphrased — no quote available because the assertion is a computation, not a snippet). The fact-check-🔴 premise matches `candB-fact-check.md` Claim 3 (Incorrect/High, "**Behavioral** — the counterexamples integration feature silently no-ops for all scenario-level edits", `hunt-verify/candB-fact-check.md:129`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-19`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:68-131`

---

## Claim 2: "a second hunted commit (throttle) had a real red that api-consistency rated **Breaking** while fact-check classified it **🟡 (impact masked)** → #4 **did not fire, 0 saving despite the red**"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:131-133`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The candA critic report rates the same contract lie Breaking:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:192
| 2 | JSDoc "last call always delivered" contradicts impl | Breaking | `throttle.ts:1-2,18-24` | High |
```

The candA fact-check classifies it masked/doc-only: "Therefore the subject is **comment/doc-only** for these consumers ... the cumulative-snapshot + final-flush pattern masks any behavioral consequence" (`hunt-verify/candA-fact-check.md:514`). And results.md records the 0 saving: "Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**" (`hunt-verify/results.md:31`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:158-192`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-fact-check.md:456-514`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-36`

---

## Claim 3: "Expected loop saving ≈ P(fact-check-visible red) × ~73%, P low (0/8 canon; ~1 clean trigger in 225 commits)"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:135-136`
**Type:** Configuration / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The two rates are grounded: "Across all 8 cells, fact-check produced **zero** behavioral 🔴" (`levers-3-4-measurement.md:70-71`), and results.md: "the 225-commit hunt found **2** candidates, and **1 of those 2 (A) still classified 🟡** at fact-check" (`hunt-verify/results.md:41-43`) — i.e., 1 of 225 empirically trips the gate. The imprecision: "~1 *clean trigger*" echoes the hunt doc's label "One clean fact-check trigger (throttle)" (`hunt-factcheck-behavioral-lie.md:104`), but the candidate the hunt called the clean trigger (A, throttle) is the one that empirically did NOT fire; the one that fired was B, which the hunt rated the "weaker fit" for the fact-check gate. The rate "~1 in 225" holds; the identity of the trigger flipped between prediction and measurement. A precise version would say "~1 empirically-confirmed trigger in 225 commits (and it was not the predicted one)".

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:68-72`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:38-45`, `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:103-107`

---

## Claim 4: log row 34 amendment — "#4 first-red short-circuit is high-variance/low-frequency: measured ~73% saving when it fires ... the empirical run confirmed one fires (evidence-integrate: fact-check 🔴 → skip 238,155-token panel = 73% of the pass) and one does NOT (throttle: real red but fact-check graded it 🟡 ...)"

**Location:** `docs/decisions/log.md:53`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All numeric and verdict content is identical to the 032 full-record bullet (Claims 1–2) and to `hunt-verify/results.md`; the two decision documents do not disagree with each other or with the evidence files. The row's "a 225-commit hunt found 2 fact-check-visible-behavioral-lie candidates" matches the hunt doc's "2 candidates cleared the bar" (`hunt-factcheck-behavioral-lie.md:10`). Cross-file consistency confirmed by side-by-side reading (paraphrased — no quote available because the claim is agreement across four documents, not a single snippet).

**Evidence:** `docs/decisions/log.md:53`, `docs/decisions/032-review-loop-token-reduction-levers.md:127-137`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-45`

---

## Claim 5: "2 candidates cleared the bar (both historical); HEAD is clean" / "One clean fact-check trigger (throttle) and one cross-file/prompt case (evidence-integrate) in 225 commits, **both already fixed, HEAD clean**"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:10,103-106`
**Type:** Behavioral / Staleness
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

"Both already fixed" is false for candidate A, and the document contradicts itself: its own candidate-A section says "the comment persists **unchanged at HEAD**" (`hunt-factcheck-behavioral-lie.md:13`). I verified at the external repo's HEAD (`7f30210`): the false docstring line is still present —

```ts
// external/meta-formalism-copilot/app/lib/utils/throttle.ts:2 (at HEAD 7f30210)
 *  The last call is always delivered (trailing edge).
```

— and the implementation still delivers the first-blocked-call's args (the trailing `setTimeout` still closes over the arming call's `args`; later in-window calls still hit `else if (!timer)` = false and are dropped — same mechanism as at e59c7ed; a `.cancel()` method was added later, but the last-call-delivery lie was never fixed). Only candidate B was fixed (`2493d2a`, "fix: rename counterexamples→scenarios in evidence-integrate schema docs" — commit message verified in the external repo). A charitable reading of "HEAD clean" — "no fact-check-visible behavioral 🔴 at HEAD under tier policy T" — is defensible given A empirically grades 🟡, but "both already fixed" is flatly contradicted by the file's own line 13 and by the code at HEAD.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:10,13,103-106`, `external/meta-formalism-copilot/app/lib/utils/throttle.ts:1-33` (at 7f30210)

---

## Claim 6: "Scanned all 225 commits reachable from HEAD"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:7` (also commit message de9ccf7)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git rev-list --count HEAD` in `/workspace/external/meta-formalism-copilot` returns exactly 225 (paraphrased — no quote available because the evidence is a command output, not file content). Whether all 225 were actually *scanned* by the three agents is a process claim not checkable statically; the count itself is exact.

**Evidence:** `external/meta-formalism-copilot` (git rev-list at HEAD 7f30210)

---

## Claim 7: Candidate A description — commit `e59c7ed` "(feat: SSE streaming partial-JSON previews, #94)" introduced `throttle.ts`; `throttle.ts:2` reads "The last call is always delivered (trailing edge)"; `throttle.ts:19-25` "schedules the trailing timer only when none is set and captures the **first** blocked call's args; later calls in the window are silently dropped"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:11-16`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Commit exists with the stated message: `e59c7ed feat: SSE streaming with partial-JSON previews for all artifact panels (#94)` (git log in wt-candA). The comment and mechanism at e59c7ed:

```ts
// wt-candA app/lib/utils/throttle.ts:1-2 (at e59c7ed)
/** Returns a throttled version of `fn` that runs at most once per `ms` milliseconds.
 *  The last call is always delivered (trailing edge). */
```

```ts
// wt-candA app/lib/utils/throttle.ts:19-25 (at e59c7ed)
} else if (!timer) {
  timer = setTimeout(() => {
    lastRun = Date.now();
    timer = null;
    fn(...args);
  }, remaining);
}
```

The `args` in the timer closure are those of the call that armed it (the first blocked call); any later call in the window finds `timer` non-null, fails `else if (!timer)`, and falls through with no else branch — dropped. The described contradiction is real.

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candA/app/lib/utils/throttle.ts:1-27` (at e59c7ed)

---

## Claim 8: Candidate A consumer references — "`useFormalizationPipeline.ts:66-68` (+ `:96,:188`, `useDecomposition.ts:130`, `useArtifactGeneration.ts:73`) — `throttle(accumulated => setSemiformal(accumulated), 50)`"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:17-19`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All cited call sites exist at the external repo's HEAD at the cited lines:

```
// grep -n "throttle(" at external HEAD
app/hooks/useFormalizationPipeline.ts:66:      const onToken = throttle((accumulated: string) => {
app/hooks/useFormalizationPipeline.ts:96:      const onToken = throttle((accumulated: string) => {
app/hooks/useFormalizationPipeline.ts:188:     const onToken = throttle((accumulated: string) => {
app/hooks/useDecomposition.ts:130:     const onToken = throttle((accumulated: string) => {
app/hooks/useArtifactGeneration.ts:73:        const onPartial = throttle((accumulated: string) => {
```

(These are HEAD line numbers; the candA-fact-check report cites different line numbers — 66, 179, 47 — because it read the worktree pinned at e59c7ed, where the same call sites sit at those earlier positions. Both sets check out in their respective states.)

**Evidence:** `external/meta-formalism-copilot/app/hooks/useFormalizationPipeline.ts:66,96,188`, `external/meta-formalism-copilot/app/hooks/useDecomposition.ts:130`, `external/meta-formalism-copilot/app/hooks/useArtifactGeneration.ts:73`

---

## Claim 9: Candidate B description — introduced by `6cf4b0d`, exhibited at `c2f5e8c`, "fixed by `2493d2a` (fix: rename counterexamples→scenarios in evidence-integrate schema docs)"; schema doc at `route.ts:46-58` says `counterexamples[i].scenario` while the real key is `scenarios` (`artifacts.ts:118`); `integrateValidation.ts:51` → `resolveFieldPath` → null → proposals dropped

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:31-42`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three commits exist in the external repo with matching messages, and `6cf4b0d` is an ancestor of `2493d2a` (git log / merge-base in wt-candB): `6cf4b0d feat: add assisted evidence integration...`, `c2f5e8c fix: prevent infinite re-render loop...`, `2493d2a fix: rename counterexamples→scenarios in evidence-integrate schema docs`. The schema-doc lie at 6cf4b0d:

```ts
// wt-candB app/api/evidence-integrate/route.ts:46-49 (at 6cf4b0d)
counterexamples: `The artifact is a counterexamples analysis with this structure:
{
  "claim": "string",
  "counterexamples": [{ "id": "string", "scenario": "string", ... }],
```

The real key is `scenarios` (`wt-candB app/lib/types/artifacts.ts:118`, `scenarios: Array<{`), and the drop site is real:

```ts
// wt-candB app/api/evidence-integrate/integrateValidation.ts:51 (at 6cf4b0d)
if (!resolveFieldPath(artifact, fieldPath)) return null;
```

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/route.ts:46-61`, `runs/review-arms/baseline-2026-08-06/wt-candB/app/lib/types/artifacts.ts:118`, `runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/integrateValidation.ts:51`

---

## Claim 10: candB-fact-check header — "**Total claims checked:** 9 / **Summary:** 7 verified, 0 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:8-9`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The report's body contains 9 claims with verdicts: Claims 1, 2, 4, 5, 6, 7, 8, 9 = **Verified** (8 of them) and Claim 3 = **Incorrect** — zero Unverifiable. The body's own summary section agrees with the body, not the header:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:289-290
### Unverifiable
- None material. (Claim 9 verified at Medium confidence.)
```

So the header should read "8 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable". The totals line (9) is right; the breakdown is wrong (7+1+1 sums to 9 but misallocates one Verified claim to Unverifiable). This is an internal-consistency defect in a committed run artifact, not a fabrication.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:8-9,13-274,289-290`

---

## Claim 11: candB-fact-check Claim 3 — "`validateProposal` then rejects the proposal (`if (!resolveFieldPath(artifact, fieldPath)) return null;`, integrateValidation.ts:56)"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:129,131`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The quoted code line is real and verbatim, but it sits at line **51**, not 56, in the worktree at 6cf4b0d:

```ts
// wt-candB app/api/evidence-integrate/integrateValidation.ts:51 (at 6cf4b0d)
if (!resolveFieldPath(artifact, fieldPath)) return null;
```

The behavioral claim (rejection on unresolvable path) is correct; only the line reference is off by 5. The hunt doc cites the correct line (`integrateValidation.ts:51`, `hunt-factcheck-behavioral-lie.md:40`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/integrateValidation.ts:51`

---

## Claim 12: results.md arithmetic — B panel 238,155, B pass 324,979, saving "73.3% of the red-gated pass"; A panel 186,275, A pass 252,992; measurement cost "577,971 tokens"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-19,28-31,57-59`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All sums and percentages recomputed with python3 from the tables' own per-agent rows (paraphrased — no quote available because the assertions are computations over the tables quoted in Claims 1–2): 74,502 + 84,050 + 79,603 = 238,155; 86,824 + 238,155 = 324,979; 238,155/324,979 = 73.28% (doc says 73.3% — correct to one decimal); 62,230 + 65,996 + 58,049 = 186,275; 66,717 + 186,275 = 252,992; 252,992 + 238,155 + 86,824 = 577,971. Every derived number in the file follows from its own inputs.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-19,23-31,57-59`

---

## Claim 13: results.md verdict column — B: fact-check "Incorrect(High), behavioral → 🔴", security "1 Med (proto-pollution-shaped)", api-consistency "Breaking", architecture "Structural 🔴"; A: fact-check "Incorrect(High) but subject comment/doc → 🟡", performance "Low", api-consistency "2 Breaking", test-strategy "5 Consider"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:10-14,23-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Each cell matches the corresponding report in the same directory. Spot quotes: candB security summary row "`__proto__` terminal key in field-path write sink | Medium" (`candB-critic-security.md` summary table); candB architecture finding 1 "**Severity:** Structural" (`candB-critic-architecture.md`); candB api-consistency finding 1 "**Severity:** Breaking" (`candB-critic-api-consistency.md`); candA api-consistency summary table lists two Breaking rows (`candA-critic-api-consistency.md:190-193`); candA performance finding 1 "**Severity:** Low" (`candA-critic-performance.md`); candA test-strategy enumerates G1–G5 all "Severity: Consider" (`candA-critic-test-strategy.md`). Remaining cells match by the same side-by-side reading (paraphrased — no quote available because the claim is agreement across seven documents).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:72-73`, `candB-critic-security.md`, `candB-critic-api-consistency.md`, `candB-critic-architecture.md`, `candA-fact-check.md:459-461,514`, `candA-critic-performance.md`, `candA-critic-api-consistency.md:190-193`, `candA-critic-test-strategy.md` (all under `runs/review-arms/baseline-2026-08-06/hunt-verify/`)

---

## Claim 14: results.md — "Per-agent tokens from task notifications" (the raw per-agent token figures, e.g. fact-check 86,824, security 74,502, etc.)

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3` (and the table rows)
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The internal arithmetic over these figures checks out (Claim 12), but the figures themselves originate from ephemeral Agent-tool task notifications that are not persisted anywhere in the repository — no notification log, transcript, or ledger row for the candA/candB runs exists on disk (paraphrased — no quote available because the claim covers absence of code: searches of `runs/review-arms/baseline-2026-08-06/` found no per-agent token source besides this file). Verifying them would require the original session's task-notification records. Note the canon baseline uses the same instrument (`token-ledger.md` exists for those cells), so the method is established; only these specific eight numbers are unauditable.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3,10-14,23-28`

---

## Claim 15: levers-3-4-measurement.md EMPIRICAL UPDATE — "fact-check 86,824 confirms the behavioral 🔴, panel of 238,155 skipped → pass 324,979 → 86,824 ... ~73% ... P is low (canon 0/8; 1 clean trigger in 225 commits)"

**Location:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:94-103`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Numerically identical to `hunt-verify/results.md` (Claim 12 arithmetic) and consistent with the pre-existing "fired **0/8**" finding earlier in the same file ("Across all 8 cells, fact-check produced **zero** behavioral 🔴", `levers-3-4-measurement.md:70-71`). The "1 clean trigger" phrasing carries the same identity-flip imprecision noted in Claim 3, but here the surrounding sentence explicitly names which candidate fired (B) and which didn't (A), so the reader is not misled.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:68-72,94-103`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-31`

---

## Claim 16: Step 1 — "Diff delivery to agents is conditional (decision 032 #3, see [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)): for a normal-sized diff, inline it once ...; for a **large diff** (the ~1000-line / >40%-churn threshold below), do **not** inline"

**Location:** `skills/code-review/SKILL.md:99`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The anchor resolves: the heading "### Inline shared-context prefix (decision 032 #3)" exists at `skills/code-review/SKILL.md:228` and slugifies to `inline-shared-context-prefix-decision-032-3`. Both referenced thresholds exist below in the same step: "if the line count crosses the ~1000-line threshold" (`SKILL.md:114`) and "more than 40% of its lines changed" (`SKILL.md:116`). The size-guard fallback described here matches the prefix section's own guard ("fall back to the pre-#3 behavior: pass the scope spec and let each agent run its own `git diff`", `SKILL.md:263-265`). This line is internally consistent with the new policy; the *un-updated* references elsewhere are Claims 19, 22, 23.

**Evidence:** `skills/code-review/SKILL.md:99,114-116,228,261-266`

---

## Claim 17: "the 2026-08-06 measurement, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`, found the benefit is only captured when the shared material is actually inlined as one cacheable prefix; agents self-reading via tools shares no prefix and captures ~nothing"

**Location:** `skills/code-review/SKILL.md:239-242`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The cited doc says exactly this:

```
// runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-29
**Second finding — the SKILL path barely shares a prefix.** In the production loop ...
critic agents are given a scope spec and **self-read** the diff, enclosing files, and
the fact-check report via tools. The genuinely byte-identical shared *prompt prefix* was my
~250-word instruction block (~330 tokens). So the **realized** #3 saving on the as-run structure ≈
330 × (N−1) × 0.9 per cell ≈ **~1–1.5k cost-equiv/cell, ~8k across the canon — negligible.**
```

One contextual note for the author (not a mismatch in the checked claim): the same doc's own recommendation ran the other way — "Worth having (caching is free to leave on), not worth a big SKILL rewrite to force-inline" (`levers-3-4-measurement.md:58-59`). The SKILL accurately reports what the measurement *found* while adopting the restructure the doc judged not worth it; that is a design choice, outside fact-check scope, but readers tracing the citation will find the divergent recommendation.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-31,56-59`

---

## Claim 18: "**Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a billing-rate effect, not a token-count reduction)"

**Location:** `skills/code-review/SKILL.md:276-278`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Matches the measurement doc:

```
// runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:48
**≈157k cost-equivalent ÷ 2.99M ≈ 5.3% of input cost, 0% of token count** — and only if the SKILL
is restructured to inline+cache.
```

Recomputed: 157,400 / 2,986,091 = 5.27% — single-digit, as claimed (paraphrased — no quote available because the check is a computation). The billing-rate framing matches `levers-3-4-measurement.md:20-23` ("prompt caching does not reduce the number of tokens *processed* ... It reduces the *billing rate*").

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:20-23,33-48`

---

## Claim 19: Stage 1 dispatch step 3 — "Include the scope specification (e.g., 'Review files changed on the current branch relative to main using `git diff main...HEAD`')"

**Location:** `skills/code-review/SKILL.md:340-344`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

This dispatch instruction still describes only the scope-spec/self-read delivery mode:

```
// skills/code-review/SKILL.md:340-341
3. Include the scope specification (e.g., "Review files changed on the current branch relative
   to main using `git diff main...HEAD`"). If the scope is partial ...
```

Under the new Step 1 policy (`SKILL.md:99`) and the Inline shared-context prefix section (`SKILL.md:239-249`, which lists "**The unified diff itself** (`git diff <scope>`), inlined" as shared-block part 2 for Stage-1 replicates and Stage-2 critics alike), a normal-sized diff should be *inlined* into the fact-check replicate prompts, with scope-spec-only delivery reserved for the large-diff fallback. This step was accurate before 2f5ad0b and was not updated with it; as written it instructs the pre-#3 behavior unconditionally.

**Evidence:** `skills/code-review/SKILL.md:99,239-249,340-344`

---

## Claim 20: #4 mechanics item 2 — "This is the largest saving (the whole critic block) — measured at **~73% of the pass** on the one canon-adjacent case that fired it (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`). But it is **not** the common case"

**Location:** `skills/code-review/SKILL.md:493-499`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The cited file records "73.3% of the red-gated pass" for candidate B (`hunt-verify/results.md:19`, quoted at Claim 1), and B is indeed the *only* case that fired it (A did not fire — `results.md:31`, "#4 saving = 0"). "One ... case that fired it" and "~73%" both match; the arithmetic behind 73.3% was recomputed and holds (Claim 12). The rarity framing ("not the common case") matches `results.md:38-45` ("It fires rarely ... canon reviewed states **0/8**"), which corrects the pre-2f5ad0b SKILL text that had called this trigger "the common case" — the correction is faithful to the evidence.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-19,29-31,38-45`

---

## Claim 21: #4 mechanics item 3 — "the core panel is one parallel wave already in flight, so there is usually nothing left to skip (measured: a critic-surfaced red saved 0)"

**Location:** `skills/code-review/SKILL.md:500-504`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Candidate A is the measured instance: it contained a genuine behavioral red surfaced by a critic, and the saving was zero —

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:31-36
- Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**
- **The sharp point**: candidate A *does* contain a behavioral red — api-consistency rated the same
  contract lie **Breaking (🔴)**. ... **A red was present and #4 still saved nothing.**
```

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-36`

---

## Claim 22: Stage 2 dispatch step 3 — "Include the scope specification so the agent runs its own `git diff`"

**Location:** `skills/code-review/SKILL.md:634-636`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

```
// skills/code-review/SKILL.md:634
3. Include the scope specification so the agent runs its own `git diff`. If the scope is
```

The rationale clause "so the agent runs its own `git diff`" states the pre-#3 delivery mode unconditionally, contradicting the new conditional policy (Step 1, `SKILL.md:99`) and the prefix section that now inlines the diff as shared-block part 2 for critic prompts (`SKILL.md:246-249`). Under the new policy, self-read is the large-diff fallback, not the default. Un-updated cross-reference from before 2f5ad0b.

**Evidence:** `skills/code-review/SKILL.md:99,246-249,634`

---

## Claim 23: Important Reminders — "**Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues."

**Location:** `skills/code-review/SKILL.md:1406`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

```
// skills/code-review/SKILL.md:1406
- **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.
```

This is the most direct internal contradiction left by 2f5ad0b: it categorically forbids exactly what Step 1 (`SKILL.md:99`, "for a normal-sized diff, inline it once as the shared cacheable prefix of every agent prompt") and the prefix section (`SKILL.md:246-249`) now mandate for normal-sized diffs. An orchestrator reading the reminders list in isolation would follow the pre-#3 behavior and — per the measurement this diff cites — capture ~none of the #3 benefit. Accurate before 2f5ad0b; not updated with it.

**Evidence:** `skills/code-review/SKILL.md:99,239-249,1406`

---

## Claim 24: commit de9ccf7 — "read-only scan, no code changed" plus the candidate facts restated from the hunt doc (throttle.ts:2, consumers in useFormalizationPipeline, e59c7ed; c2f5e8c, fixed 2493d2a)

**Location:** commit message `de9ccf7`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The commit's diffstat is a single added markdown file — `git show --stat de9ccf7` lists only `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md | 67 ++...`, no code files (paraphrased — no quote available because the evidence is a git diffstat, not file content). The restated candidate facts are the same claims verified above (Claims 6–9). Note the message's "both historical (HEAD clean)" inherits the Claim 5 defect in its weaker form — the parenthetical is defensible under the tier-T reading, and the message, unlike the hunt doc, does not say "both already fixed".

**Evidence:** git show de9ccf7; `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md` (Claims 6-9)

---

## Claim 25: commit 45fa1df — "worktrees wt-candA/wt-candB gitignored"

**Location:** commit message `45fa1df`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```
// .gitignore:45
runs/review-arms/baseline-2026-08-06/wt-*
```

`git check-ignore -v` confirms both paths match this rule (paraphrased — no quote available because the confirmation is a command output). The pattern pre-dates this range (added in `2c7f10d`, the baseline scaffold commit), so the message claims an existing fact, not new work — accurate either way.

**Evidence:** `.gitignore:45`

---

## Claim 26: commit 45fa1df — "238,155 tokens = 73% of the pass ... canon 0/8; ~1 clean trigger in 225 commits ... per-agent tokens from task notifications ... Measurement cost ~578k + ~335k hunt"

**Location:** commit message `45fa1df`
**Type:** Configuration / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Split verdict, dominated by the unauditable parts. Verified pieces: 238,155 = 73.3% of 324,979 (Claim 12 arithmetic); "canon 0/8" (`levers-3-4-measurement.md:70-71`); "~578k" matches results.md's 577,971 (`hunt-verify/results.md:57-59`, itself a correct sum). Unverifiable pieces: the per-agent token provenance ("task notifications" — Claim 14) and the "~335k hunt" figure, which appears only as "the earlier 3-agent history hunt ≈ 335k" in `results.md:59` with no persisted per-agent source anywhere in the repo (paraphrased — no quote available because the claim covers absence of evidence: no ledger or notification record for the hunt agents exists on disk). Verifying would require the original session's task-notification records. "~1 clean trigger" carries the Claim 3 imprecision.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:57-59`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:68-72`

---

## Claim 27: commit 2f5ad0b — "#4 -- already in the skill since the 032 implementation commit"

**Location:** commit message `2f5ad0b`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The 032 implementation commit exists — `09eb87a feat(code-review): implement decision 032 adopt-now token-reduction bundle` (git log on `skills/code-review/SKILL.md`) — and the 2f5ad0b diff's pre-image already contains the #4 mechanics list it edits (the `-` side of the hunk at `SKILL.md:471-507` includes "Earliest trigger — the fact-check gate" and "Critic-stage trigger"), confirming #4 predated this commit (paraphrased — no quote available because the evidence is the diff pre-image spanning a whole hunk).

**Evidence:** git log -S "first-red short-circuit" -- skills/code-review/SKILL.md (09eb87a); git show 2f5ad0b (hunk at `skills/code-review/SKILL.md:471-507`)

---

## Claim 28: commit 2f5ad0b — "format-contract 17/17 and gate 19/19 green"

**Location:** commit message `2f5ad0b`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Re-ran both suites at HEAD: `bats test/code-review-gate.bats` → 19 `ok`, 0 `not ok`; `bats test/skills/code-review-format-contract.bats` → 17 `ok`, 0 `not ok` (paraphrased — no quote available because the evidence is live test-runner output). Counts and greenness both match the claim.

**Evidence:** `test/code-review-gate.bats` (19 tests), `test/skills/code-review-format-contract.bats` (17 tests) — both run 2026-08-07

---

## Claim 29: commit 2f5ad0b — "Pipeline-prose edits only; no rubric-template change"

**Location:** commit message `2f5ad0b`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The commit touches exactly one file (`skills/code-review/SKILL.md`, per its diffstat) in three hunks: Step 1 line ~99, the shared-context-prefix section (~225–285), and the #4 mechanics (~471–507). The rubric template lives in "## Deliverable 2: Code Review Rubric" at `skills/code-review/SKILL.md:927` onward — outside every hunk. `test/skills/code-review/rubric-current-format.md` is untouched in the whole range (last modified at `a9fa0ba`, before this range) (paraphrased — no quote available because the claim is about which regions a diff does NOT touch). The format-contract suite's "golden's table headers match the skill's rubric template" test passing (Claim 28) independently confirms template stability.

**Evidence:** git show --stat 2f5ad0b; `skills/code-review/SKILL.md:927`; git log -1 -- `test/skills/code-review/rubric-current-format.md`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:10,103-106`): "both already fixed, HEAD clean" — candidate A's throttle lie is NOT fixed at the external repo's HEAD (the doc's own line 13 says the comment "persists unchanged at HEAD", and the code confirms it). Fix: reword to "B fixed (2493d2a); A's comment persists at HEAD but grades 🟡 under T".
- **Claim 10** (`runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:8-9`): header summary says "7 verified ... 1 unverifiable" but the body has 8 Verified and 0 Unverifiable. Fix the breakdown to "8 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable".

### Stale
- **Claim 19** (`skills/code-review/SKILL.md:340-344`): Stage 1 dispatch step 3 still instructs scope-spec-only delivery unconditionally; needs the inline-vs-self-read conditional from Step 1 / the prefix section.
- **Claim 22** (`skills/code-review/SKILL.md:634`): Stage 2 dispatch step 3's "so the agent runs its own `git diff`" rationale contradicts the new inline-by-default policy.
- **Claim 23** (`skills/code-review/SKILL.md:1406`): Important Reminders' "Pass scope, not diffs" categorically forbids what the new Step 1 mandates for normal diffs — the sharpest un-updated cross-reference; an orchestrator following it captures ~none of the #3 benefit the same commit claims to realize.

### Mostly Accurate
- **Claim 3** (`docs/decisions/032-review-loop-token-reduction-levers.md:135-136`): "~1 clean trigger in 225 commits" — the rate holds, but the candidate the hunt labelled the "clean trigger" (A) is the one that empirically did NOT fire; B fired. Tighten to "~1 empirically-confirmed trigger in 225".
- **Claim 11** (`runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:129-131`): cited `integrateValidation.ts:56`; the quoted line is at `:51` at 6cf4b0d.

### Unverifiable
- **Claim 14** (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3`): the raw per-agent token figures come from ephemeral task notifications with no persisted record; would need the original session's notification log to audit.
- **Claim 26** (commit `45fa1df`): same provenance gap, plus the "~335k hunt" figure has no on-disk source; internal arithmetic (~578k) does check out.

---

## Hallucination pattern log

Neither Incorrect verdict is a fabrication (no invented symbol, method, API, or behavior): Claim 5 is an internal inconsistency/staleness about fix status, and Claim 10 is a miscounted summary line. Per the skill's exclusion rules, `docs/reviews/hallucination-patterns.md` was not updated.

## Goal-Alignment Note
- Answered: yes
- Out of scope: code-quality/design judgment on the SKILL.md restructure (e.g., whether inlining against the measurement doc's "not worth a big rewrite" recommendation is wise — noted neutrally in Claim 17, not adjudicated); the hunted external-repo defects themselves (already reviewed by the run artifacts under check).
- Escalate: the three stale SKILL.md self-read instructions (Claims 19, 22, 23) — they contradict the new conditional-inlining policy this range ships and will steer future orchestrators back to the ~0-benefit delivery mode; and the hunt doc's "both already fixed, HEAD clean" (Claim 5), which misstates the external repo's current state in a decision-feeding artifact.
- Questions I would have asked: none — scope was clear.
