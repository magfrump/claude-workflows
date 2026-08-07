# Code Fact-Check Report

**Commit:** 2f5ad0b
**Replication:** k=3
**Repository:** /workspace
**Scope:** Commit range `HEAD~3..HEAD` (de9ccf7, 45fa1df, 2f5ad0b) — changed files plus the three commit messages
**Checked:** 2026-08-07
**Total claims checked:** 31
**Summary:** 22 verified, 4 mostly accurate, 3 stale, 2 incorrect, 2 unverifiable

Merged from `code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` (all `Commit: 2f5ad0b`), most-severe-wins.
Clustering is semantic on (file, line-range ±5, claim substance); evidence carried from the replicate
that assigned the winning verdict.

External-repo note (all replicates): the hunted commits live at `/workspace/external/meta-formalism-copilot`
(HEAD `7f30210`) with pinned worktrees `wt-candA` (e59c7ed) / `wt-candB` (6cf4b0d), so external reference
claims were verified directly rather than marked Unverifiable.

---

## Claim 1: 032 amended #4 bullet — "fact-check confirmed the behavioral 🔴 and #4 skipped the whole critic panel = **238,155 tokens = 73% of that pass**"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:129-131`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

The cited measurement doc records exactly these numbers:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-19
| **panel total (what #4 skips)** | **238,155** | |
- Pass **without** #4 = 86,824 + 238,155 = **324,979**
- **#4 saving = 238,155 tokens = 73.3% of the red-gated pass.**
```

Arithmetic recomputed with python3 by all three replicates: 74,502 + 84,050 + 79,603 = 238,155; 238,155 / 324,979 = 73.28% ≈ "73%" (paraphrased — no quote available because the assertion is a computation, not a snippet). The fact-check-🔴 premise matches `candB-fact-check.md:71-73` (`**Verdict:** Incorrect`, `**Confidence:** High`, Behavioral).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-19`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:68-131`

---

## Claim 2: 032 — "a second hunted commit (throttle) had a real red that api-consistency rated **Breaking** while fact-check classified it **🟡 (impact masked)** → #4 **did not fire, 0 saving despite the red**"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:131-133`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:72-73
| 1 | Advertised `.cancel()` method not implemented | Breaking | `throttle.ts:9-25` | High |
| 2 | JSDoc "last call always delivered" contradicts impl | Breaking | `throttle.ts:1-2,18-24` | High |
```

The candA fact-check classifies the subject "**comment/doc-only** for these consumers … the cumulative-snapshot + final-flush pattern masks any behavioral consequence" (`hunt-verify/candA-fact-check.md:514`), and results.md records "Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**" (`hunt-verify/results.md:31`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:29-73`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-fact-check.md:456-514`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-36`

---

## Claim 3: 032 — "Expected loop saving ≈ P(fact-check-visible red) × ~73%, P low (0/8 canon; ~1 clean trigger in 225 commits)"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:133-136`
**Type:** Configuration / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified

Winning verdict from r1. The rates are grounded ("Across all 8 cells, fact-check produced **zero** behavioral 🔴", `levers-3-4-measurement.md:70-71`; 225 = `git rev-list --count HEAD` in the external repo, reproduced by all three replicates — paraphrased, no quote available because the evidence is a command result). The imprecision: "~1 *clean trigger*" echoes the hunt doc's label "One clean fact-check trigger (throttle)" (`hunt-factcheck-behavioral-lie.md:104`), but the candidate the hunt called the clean trigger (A, throttle) is the one that empirically did NOT fire; the one that fired was B, which the hunt rated the "weaker fit". The rate "~1 in 225" holds; the identity of the trigger flipped between prediction and measurement. Precise version: "~1 empirically-confirmed trigger in 225 commits (and it was not the predicted one)". r2/r3 verified the same numerals; r3 noted the same inversion without downgrading — the split is about whether the label misleads.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:68-72`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:38-45`, `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:103-107`

---

## Claim 4: `log.md` row 34 amendment — same #4 measurement content as 032; "the empirical run confirmed one fires … and one does NOT"

**Location:** `docs/decisions/log.md:53`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

All numeric and verdict content is identical to the 032 full-record bullet (Claims 1–2) and to `hunt-verify/results.md`; the two decision documents do not disagree with each other or with the evidence files (paraphrased — no quote available because the claim is agreement across four documents, not a single snippet).

**Evidence:** `docs/decisions/log.md:53`, `docs/decisions/032-review-loop-token-reduction-levers.md:127-137`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-45`

---

## Claim 5: hunt doc — "Scanned all 225 commits reachable from HEAD via a 3-way subsystem fan-out"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

`git rev-list --count HEAD` in `/workspace/external/meta-formalism-copilot` returns exactly 225 (paraphrased — no quote available because the evidence is a command output). The "3-way fan-out" process detail is a run-history assertion not checkable statically; the checkable numeral is exact (r3 held Medium confidence on that residual; the count itself is uncontested).

**Evidence:** external repo `/workspace/external/meta-formalism-copilot` (git rev-list at HEAD 7f30210)

---

## Claim 6: hunt doc — "the comment persists **unchanged at HEAD**" (candidate A provenance, e59c7ed)

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:11-14`
**Type:** Reference / Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Verified · r3=Mostly accurate

Winning verdict from r3. The false sentence does persist verbatim at HEAD:

```
// external/meta-formalism-copilot/app/lib/utils/throttle.ts:1-3 (at HEAD 7f30210)
/** Returns a throttled version of `fn` that runs at most once per `ms` milliseconds.
 *  The last call is always delivered (trailing edge).
 *  Call `.cancel()` to clear any pending trailing-edge timer. */
```

"Unchanged" is the imprecision: the specific false line is byte-identical, but the docstring block was later extended with a `.cancel()` line (absent at e59c7ed, where the block is two lines — `wt-candA/app/lib/utils/throttle.ts:1-2`). Precise version: "the false sentence persists verbatim at HEAD; the surrounding docstring gained a line." The e59c7ed commit reference and title check out (r2, paraphrased — no quote available because the evidence is git-log output).

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candA/app/lib/utils/throttle.ts:1-2`, `external/meta-formalism-copilot/app/lib/utils/throttle.ts:1-3`

---

## Claim 7: hunt doc — "`throttle.ts:19-25` schedules the trailing timer only when none is set and captures the **first** blocked call's args; later calls in the window are silently dropped"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:15-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

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

The `else if (!timer)` guard means later in-window calls take neither branch and never update `args`; the closure fires with the arming call's frozen args (paraphrased — no quote available because the drop is the absence of an args-update path in the quoted block).

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candA/app/lib/utils/throttle.ts:7-25`

---

## Claim 8: hunt doc — candidate A consumer citations (`useFormalizationPipeline.ts:66-68`, `:96`, `:188`, `useDecomposition.ts:130`, `useArtifactGeneration.ts:73`)

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:17-20`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

All cited call sites exist at the external repo's HEAD at the cited lines:

```
// grep -n "throttle(" at external HEAD (r1)
app/hooks/useFormalizationPipeline.ts:66:      const onToken = throttle((accumulated: string) => {
app/hooks/useFormalizationPipeline.ts:96:      const onToken = throttle((accumulated: string) => {
app/hooks/useFormalizationPipeline.ts:188:     const onToken = throttle((accumulated: string) => {
app/hooks/useDecomposition.ts:130:     const onToken = throttle((accumulated: string) => {
app/hooks/useArtifactGeneration.ts:73:        const onPartial = throttle((accumulated: string) => {
```

**Evidence:** `external/meta-formalism-copilot/app/hooks/useFormalizationPipeline.ts:66,96,188`, `external/meta-formalism-copilot/app/hooks/useDecomposition.ts:130`, `external/meta-formalism-copilot/app/hooks/useArtifactGeneration.ts:73`

---

## Claim 9: hunt doc — candidate B description (introduced 6cf4b0d, exhibited c2f5e8c, fixed 2493d2a; `route.ts:46-58` schema-doc says `counterexamples[i].scenario`, real key `scenarios` at `artifacts.ts:118`; `integrateValidation.ts:51` drops proposals)

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:31-42`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

All three commits exist in the external repo with matching messages; `6cf4b0d` is an ancestor of `2493d2a` (paraphrased — no quote available because the evidence is git-log/ancestry output). The lie and ground truth:

```ts
// wt-candB app/api/evidence-integrate/route.ts:46-49 (at 6cf4b0d)
counterexamples: `The artifact is a counterexamples analysis with this structure:
{
  "claim": "string",
  "counterexamples": [{ "id": "string", "scenario": "string", ... }],
```

```ts
// wt-candB app/api/evidence-integrate/integrateValidation.ts:51 (at 6cf4b0d)
if (!resolveFieldPath(artifact, fieldPath)) return null;
```

Real key is `scenarios` (`wt-candB app/lib/types/artifacts.ts:118`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/route.ts:46-61`, `runs/review-arms/baseline-2026-08-06/wt-candB/app/lib/types/artifacts.ts:115-128`, `runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/integrateValidation.ts:51`

---

## Claim 10: hunt doc — "**Evidence integration for counterexample artifacts silently no-ops** … The fix-commit message says so outright."

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:40-41`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection

The silent-no-op mechanism is confirmed (`candB-fact-check.md:129`), but "says so outright" overstates 2493d2a's message:

```
// external clone, git log -1 --format=%B 2493d2a
Without this, the LLM is told the field is "counterexamples" but the
data uses "scenarios", and proposed fieldPaths point to the wrong place.
```

The message states the field mismatch, not the silent-no-op / feature-breaking consequence. Precise version: "the fix-commit message states the field mismatch outright; the no-op consequence is inferred from the validation path."

**Evidence:** external clone commit `2493d2a` (message body); `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:71-129`

---

## Claim 11: hunt doc — "2 candidates cleared the bar (both historical); HEAD is clean" / "**both already fixed, HEAD clean**"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:10,103-106`
**Type:** Behavioral / Staleness
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection

"Both already fixed" is false for candidate A, and the document contradicts itself: its own candidate-A section says "the comment persists **unchanged at HEAD**" (`hunt-factcheck-behavioral-lie.md:13`). Verified at the external repo's HEAD (7f30210): the false docstring line is still present —

```ts
// external/meta-formalism-copilot/app/lib/utils/throttle.ts:2 (at HEAD 7f30210)
 *  The last call is always delivered (trailing edge).
```

— and the implementation still delivers the first-blocked-call's args (same mechanism as at e59c7ed; a `.cancel()` method was added later, but the last-call-delivery lie was never fixed — paraphrased for the mechanism, no quote available because the drop is the absence of an args-update path, quoted under Claim 7). Only candidate B was fixed (2493d2a). A charitable reading of "HEAD clean" — no fact-check-visible behavioral 🔴 at HEAD under tier policy T — is defensible given A empirically grades 🟡, but "both already fixed" is flatly contradicted by the file's own line 13 and by the code at HEAD. (r2 and r3 verified the line-13 "persists at HEAD" claim — observations consistent with, and reinforcing, this Incorrect: what persists cannot be already fixed.)

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:10,13,103-106`, `external/meta-formalism-copilot/app/lib/utils/throttle.ts:1-33` (at 7f30210)

---

## Claim 12: `candB-fact-check.md` header — "**Summary:** 7 verified, 0 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:8-9`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection

The report's body contains 8 Verified and 1 Incorrect, zero Unverifiable. The body's own summary section agrees with the body, not the header:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:289-290
### Unverifiable
- None material. (Claim 9 verified at Medium confidence.)
```

Header should read "8 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable". Internal-consistency defect in a committed run artifact, not a fabrication.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:8-9,13-274,289-290`

---

## Claim 13: `candB-fact-check.md` Claim 3 cites "`integrateValidation.ts:56`"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:129,131`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection

The quoted code line is real and verbatim but sits at line **51**, not 56, at 6cf4b0d:

```ts
// wt-candB app/api/evidence-integrate/integrateValidation.ts:51 (at 6cf4b0d)
if (!resolveFieldPath(artifact, fieldPath)) return null;
```

The behavioral claim is correct; only the line reference is off by 5. The hunt doc cites the correct line.

**Evidence:** `runs/review-arms/baseline-2026-08-06/wt-candB/app/api/evidence-integrate/integrateValidation.ts:51`

---

## Claim 14: `results.md` arithmetic — B panel 238,155, B pass 324,979, "73.3%"; A panel 186,275, A pass 252,992; measurement cost 577,971

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-19,28-31,57-59`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

All sums and percentages recomputed with python3 independently by all three replicates (paraphrased — no quote available because the assertions are computations over the tables quoted in Claims 1–2): 74,502+84,050+79,603=238,155; 86,824+238,155=324,979; 238,155/324,979=73.28%; 62,230+65,996+58,049=186,275; 66,717+186,275=252,992; 252,992+238,155+86,824=577,971. Every derived number follows from its own inputs.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-31,57-59`

---

## Claim 15: `results.md` verdict-attribution cells (fact-check 🔴/🟡; security "1 Med proto-pollution-shaped"; api-consistency "Breaking"/"2 Breaking"; architecture "Structural 🔴"; performance "Low"; test-strategy "5 Consider")

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:10-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Each cell matches the corresponding report in the same directory (spot quotes in the replicate reports; e.g. `candB-critic-security.md:23-24` "Field-path write sink permits `__proto__` terminal key … **Severity:** Medium"; `candA-critic-api-consistency.md:72-73` two Breaking rows, quoted under Claim 2; `candB-critic-architecture.md:82` "Structural"). Remaining cells match by side-by-side reading (paraphrased — no quote available because the claim is agreement across seven documents).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:72-73`, `candB-critic-security.md:23-24`, `candB-critic-api-consistency.md:34-79`, `candB-critic-architecture.md:25-82`, `candA-fact-check.md:48-110`, `candA-critic-performance.md:34,94`, `candA-critic-api-consistency.md:29-73`, `candA-critic-test-strategy.md:20-28`

---

## Claim 16: `results.md` — "Per-agent tokens from task notifications" (raw per-agent token figures; also the "≈ 335k" hunt cost)

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3-4,59`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable

The raw figures originate from ephemeral Agent-tool task notifications not persisted anywhere in the repository — no notification log, transcript, or ledger row for the candA/candB runs or the ≈335k hunt exists on disk (paraphrased — no quote available because the claim covers absence of artifacts; searches of `runs/review-arms/baseline-2026-08-06/` found no per-agent token source besides this file). Internal arithmetic checks out (Claim 14); the canon baseline uses the same instrument with a persisted `token-ledger.md`, so the method is established — only these specific numbers are unauditable.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3-4,10-28,59`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:4-5`

---

## Claim 17: `levers-3-4-measurement.md` EMPIRICAL UPDATE — "#4 fires → ~73% of the pass; A did not fire, saved 0; P low (canon 0/8; 1 clean trigger in 225 commits)"

**Location:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:94-103`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Numerically identical to `hunt-verify/results.md` (Claim 14 arithmetic) and consistent with the doc's own pre-existing "Across all 8 cells, fact-check produced **zero** behavioral 🔴" (`levers-3-4-measurement.md:70-71`); the 0/8 tally is also independently recorded at `token-ledger.md:19` ("NO cell produced a fact-check behavioral 🔴", quoted by r2). The "1 clean trigger" phrasing carries the Claim 3 identity-flip imprecision, but here the surrounding sentence names which candidate fired, so the reader is not misled.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:68-72,94-103`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:19`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:8-31`

---

## Claim 18: SKILL.md Step 1 — "Diff delivery to agents is conditional (decision 032 #3, see [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)) … ~1000-line / >40%-churn threshold below"

**Location:** `skills/code-review/SKILL.md:99`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—

The anchor resolves (heading at `SKILL.md:228`), and both referenced thresholds exist below in the same step:

```
// skills/code-review/SKILL.md:114
Check diff size early via `git diff --stat` — if the line count crosses the ~1000-line threshold, propose the split to the user before launching Stage 1.
```

The size-guard fallback matches the prefix section's own guard (`SKILL.md:261-266`). This line is internally consistent with the new policy; the *un-updated* references elsewhere are Claims 21, 24, 25.

**Evidence:** `skills/code-review/SKILL.md:99,114-116,228,261-266`

---

## Claim 19: SKILL.md — "the 2026-08-06 measurement … found the benefit is only captured when the shared material is actually inlined …; agents self-reading via tools **shares no prefix** and captures ~nothing"

**Location:** `skills/code-review/SKILL.md:239-243`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate

Winning verdict from r2/r3. The cited doc supports the substance but not the absolute "shares no prefix":

```
// runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:26-29
**Second finding — the SKILL path barely shares a prefix.** ... The genuinely byte-identical shared *prompt prefix* was my
~250-word instruction block (~330 tokens). So the **realized** #3 saving on the as-run structure ≈
330 × (N−1) × 0.9 per cell ≈ **~1–1.5k cost-equiv/cell, ~8k across the canon — negligible.**
```

"Captures ~nothing" is a fair gloss (~8k of 2.99M); "shares no prefix" should read "shares only a ~330-token instruction prefix". Directionally correct, one qualifier short. (r1 additionally noted, as context: the same doc's recommendation ran the other way — "Worth having …, not worth a big SKILL rewrite to force-inline", `levers-3-4-measurement.md:58-59` — a design tension, not a factual mismatch.)

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-31,56-59`

---

## Claim 20: SKILL.md — "**Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a billing-rate effect …)"

**Location:** `skills/code-review/SKILL.md:276-278`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

```
// runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:48
**≈157k cost-equivalent ÷ 2.99M ≈ 5.3% of input cost, 0% of token count** — and only if the SKILL
is restructured to inline+cache.
```

Recomputed: 157,400 / 2,986,091 = 5.27% — single-digit (paraphrased — no quote available because the check is a computation). Billing-rate framing matches `levers-3-4-measurement.md:20-23`.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:20-23,33-48`

---

## Claim 21: SKILL.md Stage-1 dispatch step 3 — "Include the scope specification (e.g., 'Review files changed … using `git diff main...HEAD`')"

**Location:** `skills/code-review/SKILL.md:340-344`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale

```
// skills/code-review/SKILL.md:340-341
3. Include the scope specification (e.g., "Review files changed on the current branch relative
   to main using `git diff main...HEAD`"). If the scope is partial ...
```

Under the new Step 1 policy (`SKILL.md:99`) and the prefix section (which makes "**The unified diff itself** (`git diff <scope>`), inlined" shared-block part 2 for "Every Stage-1 replicate and Stage-2 critic prompt", `SKILL.md:230,245-249`), a normal-sized diff should be inlined into replicate prompts, with scope-spec-only delivery reserved for the large-diff fallback. This step was accurate before 2f5ad0b and was not updated with it; as written it instructs the pre-#3 behavior unconditionally.

**Evidence:** `skills/code-review/SKILL.md:99,230-249,340-344`

---

## Claim 22: SKILL.md #4 mechanics item 2 — "the largest saving … measured at **~73% of the pass** on the one canon-adjacent case that fired it … not the common case"

**Location:** `skills/code-review/SKILL.md:493-499`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

The cited file records "73.3% of the red-gated pass" for candidate B (`hunt-verify/results.md:19`, quoted at Claim 1), and B is the only case of two that fired (`results.md:31,36`). The rarity framing matches `results.md:38-45`, correcting the pre-2f5ad0b SKILL text that called this trigger "the common case" — the correction is faithful to the evidence.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-19,29-45`

---

## Claim 23: SKILL.md #4 mechanics item 3 — "usually nothing left to skip (measured: a critic-surfaced red saved 0)"

**Location:** `skills/code-review/SKILL.md:500-504`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:31-36
- Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**
- **The sharp point**: candidate A *does* contain a behavioral red — api-consistency rated the same
  contract lie **Breaking (🔴)**. ... **A red was present and #4 still saved nothing.**
```

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-36`

---

## Claim 24: SKILL.md Stage-2 dispatch step 3 — "Include the scope specification so the agent runs its own `git diff`"

**Location:** `skills/code-review/SKILL.md:634`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale

```
// skills/code-review/SKILL.md:634
3. Include the scope specification so the agent runs its own `git diff`. If the scope is
```

The rationale clause states the pre-#3 delivery mode unconditionally, contradicting the new conditional policy (`SKILL.md:99`) and the prefix section (`SKILL.md:245-249`). Under the new policy, self-read is the large-diff fallback, not the default. An orchestrator following the numbered dispatch steps literally never inlines, silently reverting #3.

**Evidence:** `skills/code-review/SKILL.md:99,245-249,634`

---

## Claim 25: SKILL.md Important Reminders — "**Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues."

**Location:** `skills/code-review/SKILL.md:1406`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale

```
// skills/code-review/SKILL.md:1406
- **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.
```

The most direct internal contradiction left by 2f5ad0b: it categorically forbids exactly what Step 1 (`SKILL.md:99`) and the prefix section (`SKILL.md:245-249`) now mandate for normal-sized diffs. An orchestrator reading the reminders list in isolation follows the pre-#3 behavior and — per the measurement this diff cites — captures ~none of the #3 benefit. Accurate before 2f5ad0b; not updated with it.

**Evidence:** `skills/code-review/SKILL.md:99,239-249,1406`

---

## Claim 26: commit de9ccf7 — "read-only scan, no code changed" plus restated candidate facts

**Location:** commit message `de9ccf7` (checked against `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:9-46`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

The commit's diffstat is a single added markdown file (67 insertions), no code (paraphrased — no quote available because the evidence is a git diffstat). Restated candidate facts are the claims verified above (Claims 5–9). Note (r1): the message's "both historical (HEAD clean)" inherits the Claim 11 defect in weaker form — the parenthetical is defensible under the tier-T reading, and the message, unlike the hunt doc, does not say "both already fixed".

**Evidence:** git show --stat de9ccf7; `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:9-46`

---

## Claim 27: commit 45fa1df — "worktrees wt-candA/wt-candB gitignored"

**Location:** commit message `45fa1df` (checked against `.gitignore:45`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

```
// .gitignore:45
runs/review-arms/baseline-2026-08-06/wt-*
```

`git check-ignore -v` confirms both paths match (paraphrased — no quote available because the confirmation is a command output). The rule predates the range (2c7f10d); the message claims the state, which is true.

**Evidence:** `.gitignore:45`

---

## Claim 28: commit 45fa1df numerics — "238,155 = 73% of the pass; canon 0/8; ~1 clean trigger in 225; per-agent tokens from task notifications; Measurement cost ~578k + ~335k hunt"

**Location:** commit message `45fa1df` (checked against `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:57-59`)
**Type:** Configuration / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Verified

Winning verdict from r1 (split verdict dominated by the unauditable parts). Verified pieces (all replicates): 238,155 = 73.3% of 324,979; "canon 0/8" (`levers-3-4-measurement.md:70-71`, `token-ledger.md:19`); "~578k" matches results.md's 577,971. Unverifiable pieces: the per-agent token provenance (Claim 16) and the "~335k hunt" figure, which appears only as "the earlier 3-agent history hunt ≈ 335k" in `results.md:59` with no persisted per-agent source (paraphrased — no quote available because the claim covers absence of evidence). "~1 clean trigger" carries the Claim 3 imprecision. r2/r3 rated the message Verified on the strength of the reproducible figures while noting the same provenance caveat — the split is about weighting, not about any contested fact.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:57-59`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:68-72`

---

## Claim 29: commit 2f5ad0b — "#4 — already in the skill since the 032 implementation commit"

**Location:** commit message `2f5ad0b` (checked against `skills/code-review/SKILL.md:471-507`)
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—

`git log -S "first-red short-circuit" -- skills/code-review/SKILL.md` shows the mechanism entered at `09eb87a feat(code-review): implement decision 032 adopt-now token-reduction bundle` (paraphrased — no quote available because the evidence is pickaxe git-log output; commit outside the range, context only).

**Evidence:** commit `09eb87a`; git show 2f5ad0b (pre-image hunk at `skills/code-review/SKILL.md:471-507`)

---

## Claim 30: commit 2f5ad0b — "format-contract 17/17 and gate 19/19 green"

**Location:** commit message `2f5ad0b` (checked against `test/code-review-gate.bats:1`)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

All three replicates independently re-ran both suites at HEAD: `bats test/code-review-gate.bats` → 19 ok, 0 not ok; `bats test/skills/code-review-format-contract.bats` → 17 ok, 0 not ok (paraphrased — no quote available because the evidence is live test-runner output).

**Evidence:** `test/code-review-gate.bats` (19 cases), `test/skills/code-review-format-contract.bats` (17 cases) — re-run 2026-08-07

---

## Claim 31: commit 2f5ad0b — "Pipeline-prose edits only; no rubric-template change"

**Location:** commit message `2f5ad0b` (checked against `skills/code-review/SKILL.md:927`)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

The commit touches only `skills/code-review/SKILL.md`, hunks at `@@ -96,7 @@`, `@@ -225,41 @@`, `@@ -471,12 @@` — none overlapping the rubric template (Deliverable 2, `SKILL.md:927`+). `test/skills/code-review/rubric-current-format.md` is untouched in the whole range; `git diff HEAD~3..HEAD -- test/` is empty (paraphrased — no quote available because the claim covers absence of changes). The format-contract suite's template cross-check tests passing (Claim 30) independently confirms template stability.

**Evidence:** git show --stat 2f5ad0b; `skills/code-review/SKILL.md:927`; `test/skills/code-review/rubric-current-format.md`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:10,103-106`): "both already fixed, HEAD clean" — candidate A's throttle lie is NOT fixed at the external repo's HEAD (the doc's own line 13 says it "persists unchanged at HEAD"; the code confirms). Reword to "B fixed (2493d2a); A's comment persists at HEAD but grades 🟡 under T".
- **Claim 12** (`runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:8-9`): header summary says "7 verified … 1 unverifiable" but the body has 8 Verified and 0 Unverifiable.

### Stale
- **Claim 21** (`skills/code-review/SKILL.md:340-344`): Stage-1 dispatch step 3 still instructs scope-spec-only delivery unconditionally.
- **Claim 24** (`skills/code-review/SKILL.md:634`): Stage-2 dispatch step 3's "so the agent runs its own `git diff`" contradicts the new inline-by-default policy.
- **Claim 25** (`skills/code-review/SKILL.md:1406`): Important Reminders' "Pass scope, not diffs" categorically forbids what the new Step 1 mandates — the sharpest un-updated cross-reference.

### Mostly Accurate
- **Claim 3** (`docs/decisions/032-review-loop-token-reduction-levers.md:135-136`): "~1 clean trigger in 225" — rate holds, but the hunt's "clean trigger" (A) is the one that did NOT fire; B fired.
- **Claim 6** (`runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:11-14`): "persists unchanged at HEAD" — the false sentence persists verbatim; the docstring block later gained a `.cancel()` line.
- **Claim 10** (`runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:40-41`): fix-commit message states the field mismatch, not the no-op consequence — tighten "says so outright".
- **Claim 13** (`runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:129-131`): cited `integrateValidation.ts:56`; actual line is `:51` at 6cf4b0d.
- **Claim 19** (`skills/code-review/SKILL.md:239-243`): "shares no prefix" should be "shares only a ~330-token instruction prefix (~8k across the canon — negligible)".

### Unverifiable
- **Claim 16** (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3-4,59`): raw per-agent token figures and the ≈335k hunt cost come from ephemeral task notifications with no persisted record.
- **Claim 28** (commit `45fa1df`): same provenance gap; internal arithmetic (~578k) checks out.

---

## Verdict stability

- **Total clusters:** 31 (27 surfaced by ≥2 replicates; 4 single-replicate detections: Claims 10 (r2), 11 (r1), 12 (r1), 13 (r1)).
- **Multi-replicate clusters with full agreement:** 23 of 27 (**85%**).
- **Disagreeing clusters (4):**
  - Claim 3 — r1=Mostly accurate · r2=Verified · r3=Verified (does the "clean trigger" identity flip mislead?)
  - Claim 6 — r2=Verified · r3=Mostly accurate (is a docstring line-addition "unchanged"?)
  - Claim 19 — r1=Verified · r2=Mostly accurate · r3=Mostly accurate ("shares no prefix" vs measured ~330-token prefix)
  - Claim 28 — r1=Unverifiable · r2=Verified · r3=Verified (weighting of unauditable telemetry within a mixed claim)
- All four disagreements sit in the Verified/Mostly-accurate/Unverifiable band; **no cluster disagreed across the blocking boundary** (no Incorrect-vs-other splits among co-reporting replicates). The two Incorrect verdicts are single-replicate detections (r1) whose substance the other replicates' observations corroborate rather than contradict (r2/r3 verified "persists at HEAD", which is inconsistent with "both already fixed").
- Running agreement tally toward the §1.1 k=2 falsifier (≥90% on ≥20-claim sample): this run contributes 23/27 (85%).

## Goal-Alignment Note
- Answered: yes (all three replicates)
- Out of scope (union): design judgments — notably the tension between the measurement doc's "not worth a big SKILL rewrite to force-inline" recommendation and 2f5ad0b inlining anyway; completeness of the 225-commit hunt's exclusion list (property of the scan run); the external-repo defects themselves.
- Escalate (union): the three stale SKILL.md self-read instructions (`skills/code-review/SKILL.md:340-344,634,1406`) — they contradict the conditional-inlining policy this range ships and will steer future orchestrators back to the ~0-benefit delivery mode; and the hunt doc's false "both already fixed, HEAD clean" (Claim 11).
