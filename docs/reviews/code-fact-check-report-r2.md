# Code Fact-Check Report

**Commit:** 2f5ad0b
**Repository:** /workspace
**Scope:** Commit range `HEAD~3..HEAD` (de9ccf7, 45fa1df, 2f5ad0b) — changed files plus the three commit messages
**Checked:** 2026-08-07
**Total claims checked:** 29
**Summary:** 23 verified, 2 mostly accurate, 3 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read before checking; it contains no entries, so no claim could match a logged pattern. No new fabrication patterns were confirmed (zero Incorrect verdicts), so the log is unchanged.

Note on external references: the hunted commits live in the external project `mfc`, which is present locally at `/workspace/external/meta-formalism-copilot` (gitignored via `external/`). All external-repo reference claims were checked directly against that clone rather than marked Unverifiable.

---

## Claim 1: "Empirically fired on a hunted commit (evidence-integrate `counterexamples`/`scenarios`, `hunt-verify/results.md`): fact-check confirmed the behavioral 🔴 and #4 skipped the whole critic panel = 238,155 tokens = 73% of that pass"

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
- Pass **with** #4 = **86,824** (fact-check only; panel skipped once the 🔴 is confirmed)
- **#4 saving = 238,155 tokens = 73.3% of the red-gated pass.**
```

Arithmetic re-verified with python3: 74,502 + 84,050 + 79,603 = 238,155; 238,155 / 324,979 = 73.28% ≈ "73%". The fact-check red is real: the candB fact-check report rates the schema-doc claim `**Verdict:** Incorrect` with the behavioral consequence "every per-scenario counterexample proposal the LLM is instructed to make is **silently dropped**" (`runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:72,129`). One nuance, discernible from the source doc itself: the critic panel was actually *run* to measure its size, and the "skip" is the counterfactual arithmetic — the source doc presents it the same way (paraphrased — no quote available because the point is the framing shared across both documents, results.md lines 15-19 quoted above being the basis).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-19`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:72,129`

---

## Claim 2: "a second hunted commit (throttle) had a real red that api-consistency rated **Breaking** while fact-check classified it **🟡 (impact masked)** → #4 **did not fire, 0 saving despite the red**"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:131-133`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The candA api-consistency critique carries two Breaking findings, including on the throttle contract:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:29,41
**Severity:** Breaking
...
**Severity:** Breaking
```

The candA fact-check rates the same comment Incorrect but explicitly reclassifies the subject: "Therefore the subject is **comment/doc-only** for these consumers: the JSDoc misinforms a reader, but the cumulative-snapshot + final-flush pattern masks any behavioral consequence" (`candA-fact-check.md`, Claim 2 discussion). The results doc records the consequence: "Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**" (`results.md:31`). Comment/doc → 🟡 under tier policy T is the documented mapping (paraphrased — no quote available because the T mapping lives in decision 031/SKILL text outside this range and is invoked, not restated, by these docs).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:27-41`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-fact-check.md:52-110`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:21-36`

---

## Claim 3: "Expected loop saving ≈ P(fact-check-visible red) × ~73%, P low (0/8 canon; ~1 clean trigger in 225 commits)"

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:133-135`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three numerals ground out. The 0/8 canon tally is recorded in the baseline ledger:

```
// runs/review-arms/baseline-2026-08-06/token-ledger.md:19
Note: NO cell produced a fact-check behavioral 🔴 — every Incorrect(high) was comment/doc subject (→🟡 under tier policy T).
```

The 225-commit count is independently reproducible: `git rev-list --count HEAD` in `/workspace/external/meta-formalism-copilot` returns 225. "~1 clean trigger" matches the empirical split — 2 candidates found, of which only B tripped the gate: "the 225-commit hunt found **2** candidates, and **1 of those 2 (A) still classified 🟡** at fact-check" (`results.md:43-45`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/token-ledger.md:19`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:42-45`, external repo `git rev-list --count HEAD` = 225

---

## Claim 4: log.md row 34 (amended): "measured ~73% saving when it fires, but the trigger is rare … the empirical run confirmed one fires (evidence-integrate: fact-check 🔴 → skip 238,155-token panel = 73% of the pass) and one does NOT (throttle: real red but fact-check graded it 🟡 comment/doc since consumers mask impact → 0 saving despite the red)"

**Location:** `docs/decisions/log.md:53`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Row 34 restates the same numbers as the 032 full record's amended #4 bullet and both match `hunt-verify/results.md` (see Claims 1–3 for the quoted sources: 238,155-token panel, 73.3%, A's 🟡 classification, 0 saving, 0/8 canon, 225-commit hunt with 2 candidates). Cross-consistency between row 34 and the 032 record was checked side by side and no numeric or directional disagreement exists between them (paraphrased — no quote available because the check is a two-document comparison, both documents' operative figures quoted under Claims 1–3).

**Evidence:** `docs/decisions/log.md:53`, `docs/decisions/032-review-loop-token-reduction-levers.md:127-137`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-45`

---

## Claim 5: "Scanned all 225 commits reachable from HEAD via a 3-way subsystem fan-out"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git rev-list --count HEAD` in `/workspace/external/meta-formalism-copilot` returns exactly 225 (paraphrased — no quote available because the evidence is a command result, not a code snippet). The "3-way subsystem fan-out" process detail itself is a claim about how the scan was run, not statically checkable; the checkable numeral is correct.

**Evidence:** external repo `/workspace/external/meta-formalism-copilot`, `git rev-list --count HEAD`

---

## Claim 6: Candidate A provenance — "Exhibiting commit: `e59c7ed` (feat: SSE streaming partial-JSON previews, #94) — introduced the utility + the false comment; the comment persists unchanged at HEAD" and the comment text at `throttle.ts:2`

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:11-14`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The commit exists with the claimed title: `git log --oneline -1 e59c7ed` → `e59c7ed feat: SSE streaming with partial-JSON previews for all artifact panels (#94)` (paraphrased — no quote available because the evidence is git-log output from the external clone). The comment is verbatim at that commit:

```ts
// external/meta-formalism-copilot, git show e59c7ed:app/lib/utils/throttle.ts:1-2
/** Returns a throttled version of `fn` that runs at most once per `ms` milliseconds.
 *  The last call is always delivered (trailing edge). */
```

And it persists at the clone's current HEAD: `rg -n "last call is always delivered" app/lib/utils/throttle.ts` → `2: *  The last call is always delivered (trailing edge).` (line-numbered grep hit quoted).

**Evidence:** `/workspace/external/meta-formalism-copilot` at `e59c7ed:app/lib/utils/throttle.ts:1-2` and working-tree `app/lib/utils/throttle.ts:2`

---

## Claim 7: "throttle.ts:19-25 schedules the trailing timer only when none is set and captures the **first** blocked call's args; later calls in the window are silently dropped. The actual *last* call is never delivered."

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:15-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The implementation at the exhibiting commit matches:

```ts
// external clone, candA-fact-check.md:63-69 quoting app/lib/utils/throttle.ts:19-24
} else if (!timer) {
  timer = setTimeout(() => {
    lastRun = Date.now();
    timer = null;
    fn(...args);      // args frozen from the FIRST blocked call
  }, remaining);
}
```

The `else if (!timer)` guard means a second in-window call never re-arms or updates the timer, so the closure fires with the first blocked call's frozen `args` — the last call is dropped whenever ≥2 calls land in one window (paraphrased — no quote available because the drop is the *absence* of any args-update path in the quoted block; there is no code to quote for it).

**Evidence:** external clone `app/lib/utils/throttle.ts:11-25` at e59c7ed; `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-fact-check.md:56-75`

---

## Claim 8: Candidate A consumer claim — "`useFormalizationPipeline.ts:66-68` … `throttle(accumulated => setSemiformal(accumulated), 50)` for live streaming previews"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:18-20`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Spot-checked in the external clone:

```ts
// external/meta-formalism-copilot app/hooks/useFormalizationPipeline.ts:66-68 (via sed -n '60,70p')
const onToken = throttle((accumulated: string) => {
  acc.current.setSemiformal(accumulated);
}, 50);
```

The additional consumer citations (`:96,:188`, `useDecomposition.ts:130`, `useArtifactGeneration.ts:73`) were corroborated by the candA fact-check report's quoted call sites rather than each opened individually (paraphrased — no quote available because the claim covers four secondary call sites across three files; the primary site is quoted above).

**Evidence:** external clone `app/hooks/useFormalizationPipeline.ts:66-68`; `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-fact-check.md:82-101`

---

## Claim 9: Candidate B provenance and mechanism — "(c2f5e8c … introduced by 6cf4b0d, fixed by 2493d2a)"; "route.ts:46-58 — schema doc says the artifact field is `counterexamples[i].scenario`"; "the real artifact type is `scenarios` (`app/lib/types/artifacts.ts:118`)"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:31-37`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three SHAs exist in the external clone, `6cf4b0d` is an ancestor of `2493d2a` (`git merge-base --is-ancestor` succeeds), and `2493d2a` is titled `fix: rename counterexamples→scenarios in evidence-integrate schema docs` touching only `app/api/evidence-integrate/route.ts` (paraphrased — no quote available because this is git-log/ancestry output). The lie and the ground truth are both present at c2f5e8c:

```
// git show c2f5e8c:app/api/evidence-integrate/route.ts:56
- "counterexamples[i].scenario" — a counterexample scenario
```

```ts
// git show c2f5e8c:app/lib/types/artifacts.ts:118
    scenarios: Array<{
```

**Evidence:** external clone at `c2f5e8c:app/api/evidence-integrate/route.ts:46-57`, `c2f5e8c:app/lib/types/artifacts.ts:118`, commits `6cf4b0d`, `2493d2a`

---

## Claim 10: "**Evidence integration for counterexample artifacts silently no-ops** — unmasked, feature-breaking. The fix-commit message says so outright."

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:40-41`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The silent-no-op mechanism itself is confirmed by the candB fact-check: "`validateProposal` then rejects the proposal (`if (!resolveFieldPath(artifact, fieldPath)) return null;`, integrateValidation.ts:56) … So every per-scenario counterexample proposal the LLM is instructed to make is **silently dropped**" (`candB-fact-check.md:129`). But "the fix-commit message says so outright" overstates what 2493d2a's message actually says:

```
// external clone, git log -1 --format=%B 2493d2a
Without this, the LLM is told the field is "counterexamples" but the
data uses "scenarios", and proposed fieldPaths point to the wrong place.
```

The message states the mismatch and that fieldPaths point to the wrong place; it does not state the silent-no-op / feature-breaking consequence. The precise version would be: "the fix-commit message states the field mismatch outright; the no-op consequence is inferred from the validation path."

**Evidence:** external clone commit `2493d2a` (message body); `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:71-129`

---

## Claim 11: results.md arithmetic — B panel 238,155; B pass 324,979; saving "73.3% of the red-gated pass"; A panel 186,275; A pass 252,992; measurement cost 577,971

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-31,58-59`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every sum and percentage in the document was recomputed with python3: 74,502 + 84,050 + 79,603 = 238,155; 86,824 + 238,155 = 324,979; 238,155 / 324,979 = 73.28% (doc says 73.3%); 62,230 + 65,996 + 58,049 = 186,275; 66,717 + 186,275 = 252,992; 252,992 + 238,155 + 86,824 = 577,971 (paraphrased — no quote available because the evidence is arithmetic re-computation of the table values quoted under Claim 1). No internal inconsistency found.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-31,58-59`; python3 recomputation

---

## Claim 12: "Per-agent tokens from task notifications"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The individual per-agent token figures (86,824; 74,502; etc.) come from runtime task-notification telemetry of the measurement session, which leaves no artifact in the repo to check against (paraphrased — no quote available because the claim covers absence of a static source; no matching artifact exists in `runs/review-arms/baseline-2026-08-06/hunt-verify/`). The figures are internally consistent (Claim 11) and use the same instrument the baseline docs describe (`levers-3-4-measurement.md:4-5`: "**Metric available**: `subagent_tokens` (a token *count*) from task notifications"), but verifying the raw numbers would require the original session's notification log.

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:4-5`

---

## Claim 13: results.md per-agent verdict attributions (fact-check 🔴/🟡; "1 Med (proto-pollution-shaped)"; "Breaking"; "Structural 🔴"; "2 Breaking (docstring contradiction + unimplemented `.cancel()`)"; "5 Consider"; "Low (trailing-edge stale args, masked)")

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:11-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Each table cell was checked against the corresponding report file in the same directory. candB: fact-check `**Verdict:** Incorrect` behavioral (`candB-fact-check.md:72,129`); security "Field-path write sink permits `__proto__` terminal key (prototype-pollution-shaped) **Severity:** Medium" (`candB-critic-security.md:23-24`); api-consistency `**Severity:** Breaking` (`candB-critic-api-consistency.md:34`); architecture `**Severity:** Structural` (`candB-critic-architecture.md:25`). candA: fact-check Incorrect with comment/doc-only subject classification (`candA-fact-check.md:52` and the masking discussion); api-consistency has exactly two `**Severity:** Breaking` findings — the unimplemented `.cancel()` (line 29) and the docstring contradiction (line 41); performance summary row "Trailing edge delivers stale first-in-window args (docstring says last) | Low" (`candA-critic-performance.md:94`); test-strategy carries exactly five `Severity: Consider` entries (`candA-critic-test-strategy.md:20,22,24,26,28`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:72,129`, `candB-critic-security.md:23-24`, `candB-critic-api-consistency.md:34`, `candB-critic-architecture.md:25`, `candA-fact-check.md:52-110`, `candA-critic-api-consistency.md:29,41`, `candA-critic-performance.md:94`, `candA-critic-test-strategy.md:20-28`

---

## Claim 14: "Across the whole program: canon reviewed states **0/8**"

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:42-43`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The baseline ledger records it explicitly:

```
// runs/review-arms/baseline-2026-08-06/token-ledger.md:19
Note: NO cell produced a fact-check behavioral 🔴 — every Incorrect(high) was comment/doc subject (→🟡 under tier policy T).
```

**Evidence:** `runs/review-arms/baseline-2026-08-06/token-ledger.md:7-19`

---

## Claim 15: levers-3-4-measurement.md EMPIRICAL UPDATE — "**When #4 fires it cuts ~73% of the pass** (candidate B … fact-check 86,824 confirms the behavioral 🔴, panel of 238,155 skipped → pass 324,979 → 86,824) … candidate A (throttle) … **did not fire and saved 0** … P is low (canon 0/8; 1 clean trigger in 225 commits)"

**Location:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:94-103`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every figure matches `hunt-verify/results.md` (quoted under Claims 1–3, arithmetic re-verified under Claim 11), and the update paragraph correctly labels itself as superseding the doc's earlier analytical estimate rather than contradicting it (paraphrased — no quote available because the check is a cross-document numeric comparison; the operative figures are quoted under Claims 1 and 11).

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:94-103`, `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:9-45`

---

## Claim 16: "for a **large diff** (the ~1000-line / >40%-churn threshold below), do **not** inline"

**Location:** `skills/code-review/SKILL.md:99`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both thresholds exist "below" in Step 1 as claimed:

```
// skills/code-review/SKILL.md:114
Check diff size early via `git diff --stat` — if the line count crosses the ~1000-line threshold, propose the split to the user before launching Stage 1.
```

```
// skills/code-review/SKILL.md:116
When any single file in the diff has more than 40% of its lines changed ... treat that file's review as greenfield ...
```

The section anchor `#inline-shared-context-prefix-decision-032-3` also resolves: the heading `### Inline shared-context prefix (decision 032 #3)` exists at line 228 (paraphrased — no quote available because the check is GitHub-anchor derivation from the heading text).

**Evidence:** `skills/code-review/SKILL.md:99,114-116,228`

---

## Claim 17: "the 2026-08-06 measurement, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`, found the benefit is only captured when the shared material is actually inlined as one cacheable prefix; agents self-reading via tools shares no prefix and captures ~nothing"

**Location:** `skills/code-review/SKILL.md:239-243`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The cited doc does say the benefit requires inlining: "Realizing #3 requires **restructuring the SKILL to inline** the shared context into a cacheable prefix" (`levers-3-4-measurement.md:30-31`), and quantifies the self-read case as negligible. But "shares no prefix" slightly overstates the doc, which measured a small nonzero prefix:

```
// runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:26-29
**Second finding — the SKILL path barely shares a prefix.** ... The genuinely byte-identical shared *prompt prefix* was my
~250-word instruction block (~330 tokens). So the **realized** #3 saving on the as-run structure ≈
330 × (N−1) × 0.9 per cell ≈ **~1–1.5k cost-equiv/cell, ~8k across the canon — negligible.**
```

"Captures ~nothing" is accurate (~8k of 2.99M); "shares no prefix" should read "shares only a ~330-token instruction prefix." Directionally correct, one qualifier short.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-31`

---

## Claim 18: "**Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a billing-rate effect, not a token-count reduction)"

**Location:** `skills/code-review/SKILL.md:271-273`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The measurement doc's bottom line matches:

```
// runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:48
**≈157k cost-equivalent ÷ 2.99M ≈ 5.3% of input cost, 0% of token count** — and only if the SKILL
is restructured to inline+cache.
```

5.3% is single-digit; the billing-rate framing matches lines 20-23 of the same doc ("prompt caching does not reduce the number of tokens *processed* — a cached token still counts").

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:20-23,33-48`

---

## Claim 19: Stage-1 dispatch step 3 — "Include the scope specification (e.g., 'Review files changed on the current branch relative to main using `git diff main...HEAD`')"

**Location:** `skills/code-review/SKILL.md:340-344`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** Medium
**Legibility-target:** for-author

This dispatch instruction predates the #3 inlining change and was not updated by 2f5ad0b. It still describes scope-spec-only delivery with an example implying the replicate runs its own diff:

```
// skills/code-review/SKILL.md:340-341
3. Include the scope specification (e.g., "Review files changed on the current branch relative
   to main using `git diff main...HEAD`").
```

Under the new regime (SKILL.md:99, quoted under Claim 23), a normal-sized diff is inlined "as the shared cacheable prefix of every agent prompt" — and the shared-block spec (SKILL.md:245-249) makes "**The unified diff itself** (`git diff <scope>`), inlined" part 2 of every Stage-1/Stage-2 prompt. Step 3 is not flatly contradictory (a scope spec can accompany an inlined diff), but its example reads as the pre-#3 self-read delivery with no mention of the conditional. Medium confidence because the reading is arguable; the two harder contradictions are Claims 22 and 23.

**Evidence:** `skills/code-review/SKILL.md:99,245-249,340-344`

---

## Claim 20: "This is the largest saving (the whole critic block) — measured at **~73% of the pass** on the one canon-adjacent case that fired it (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`)"

**Location:** `skills/code-review/SKILL.md:493-495`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The cited file exists and records "**#4 saving = 238,155 tokens = 73.3% of the red-gated pass**" (`results.md:19`, quoted in full under Claim 1; arithmetic re-verified under Claim 11). "The one … case that fired it" is exact: of the two candidates run, only B fired ("**A red was present and #4 still saved nothing**", `results.md:36`). "Canon-adjacent" is fair — the candidates came from the hunt, not the 8-cell canon (paraphrased — no quote available because this is a characterization of provenance across the hunt doc and results doc, both cited).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:15-36`

---

## Claim 21: "Note this saves little in practice: the core panel is one parallel wave already in flight, so there is usually nothing left to skip (measured: a critic-surfaced red saved 0)"

**Location:** `skills/code-review/SKILL.md:497-502`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Candidate A is exactly this measurement: a critic-surfaced behavioral red (api-consistency Breaking, `candA-critic-api-consistency.md:29,41`) with zero saving:

```
// runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:31-36
- Pass = 66,717 + 186,275 = **252,992**. **#4 saving = 0.**
- **The sharp point**: candidate A *does* contain a behavioral red ... because the panel is one
  **parallel wave** there is nothing to short-circuit mid-flight.
```

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:29-36`, `runs/review-arms/baseline-2026-08-06/hunt-verify/candA-critic-api-consistency.md:29,41`

---

## Claim 22: Stage-2 dispatch step 3 — "Include the scope specification so the agent runs its own `git diff`"

**Location:** `skills/code-review/SKILL.md:634`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

This Stage-2 critic-dispatch instruction still mandates unconditional self-read:

```
// skills/code-review/SKILL.md:634
3. Include the scope specification so the agent runs its own `git diff`.
```

It contradicts the amended Step 1 (SKILL.md:99: "for a normal-sized diff, inline it once as the shared cacheable prefix of every agent prompt") and the shared-block spec that makes the inlined diff part 2 of "Every Stage-1 replicate and Stage-2 critic prompt" (SKILL.md:230-235,245-249). Under the new design, "runs its own `git diff`" is only the large-diff fallback; step 3 states it as the universal rule. Likely accurate when written, now stale — an orchestrator following the numbered dispatch steps literally would never inline, silently reverting #3.

**Evidence:** `skills/code-review/SKILL.md:99,230-249,634`

---

## Claim 23: "**Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues."

**Location:** `skills/code-review/SKILL.md:1406`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

The "Important Reminders" section flatly contradicts the amended Step 1:

```
// skills/code-review/SKILL.md:1406
- **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.
```

versus:

```
// skills/code-review/SKILL.md:99
Diff delivery to agents is conditional (decision 032 #3 ...): for a normal-sized diff, inline it once as the shared cacheable prefix of every agent prompt; for a **large diff** ... pass the scope specification so each agent runs its own `git diff` ...
```

This is the pre-#3 rule stated as an unconditional reminder; the code-adjacent truth is now "pass scope only for large diffs; inline otherwise." Since reminders sections are what skim-readers follow, this stale line actively undoes the change 2f5ad0b made.

**Evidence:** `skills/code-review/SKILL.md:99,1406`

---

## Claim 24: Commit 2f5ad0b — "format-contract 17/17 and gate 19/19 green"

**Location:** `git:2f5ad0b` (commit message)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Re-run at HEAD: `bats test/code-review-gate.bats test/skills/code-review-format-contract.bats` produced 36 `ok` lines and zero `not ok`; `bats -c` reports the suites contain exactly 19 (`test/code-review-gate.bats`) and 17 (`test/skills/code-review-format-contract.bats`) cases respectively (paraphrased — no quote available because the evidence is test-runner output, not source code).

**Evidence:** `test/code-review-gate.bats` (19 cases, all pass), `test/skills/code-review-format-contract.bats` (17 cases, all pass)

---

## Claim 25: Commit 2f5ad0b — "Pipeline-prose edits only; no rubric-template change"

**Location:** `git:2f5ad0b` (commit message)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The commit touches only `skills/code-review/SKILL.md`, with hunks at lines ~96-99 (Step 1), ~225-282 (Inline shared-context prefix section), and ~471-505 (#4 short-circuit mechanics) — none overlapping the rubric template (Deliverable 2) region — and `test/skills/code-review/rubric-current-format.md` is absent from the range diff entirely (paraphrased — no quote available because the claim covers absence of changes; the range `git diff --stat` lists no rubric files). Corroborated dynamically: the gate suite's template cross-check tests ("golden's table headers match the skill's rubric template", "golden's section headings match the skill's rubric template") pass at HEAD.

**Evidence:** `git diff HEAD~3..HEAD --stat`, `git diff HEAD~1..HEAD -- test/skills/code-review/rubric-current-format.md` (empty), `test/code-review-gate.bats` cases 34-35 (pass)

---

## Claim 26: Commit 2f5ad0b — "#4 — already in the skill since the 032 implementation commit"

**Location:** `git:2f5ad0b` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git log -S "first-red short-circuit" -- skills/code-review/SKILL.md` shows the string entered the SKILL at `09eb87a feat(code-review): implement decision 032 adopt-now token-reduction bundle` — the 032 implementation commit (paraphrased — no quote available because the evidence is pickaxe git-log output).

**Evidence:** commit `09eb87a` (in-repo history, outside the review range — context only)

---

## Claim 27: Commit 45fa1df — "worktrees wt-candA/wt-candB gitignored"

**Location:** `git:45fa1df` (commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both directories exist on disk under `runs/review-arms/baseline-2026-08-06/` and `git check-ignore -v` matches each to the pre-existing pattern:

```
// .gitignore:45
runs/review-arms/baseline-2026-08-06/wt-*
```

Note the rule was not added by this range — it dates to commit `2c7f10d` (baseline scaffold, context only) — but the message claims the state ("gitignored"), not that this commit added the rule, and the state is true.

**Evidence:** `.gitignore:45`, `git check-ignore -v runs/review-arms/baseline-2026-08-06/wt-candA` and `...wt-candB` (both match), directory listing of `runs/review-arms/baseline-2026-08-06/`

---

## Claim 28: Commit 45fa1df numerics — "238,155 tokens = 73% of the pass"; "canon 0/8; ~1 clean trigger in 225 commits"; "Measurement cost ~578k + ~335k hunt"; "per-agent tokens from task notifications"

**Location:** `git:45fa1df` (commit message)
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

238,155 = 73.3% of 324,979 (python3, Claim 11); 0/8 grounded in `token-ledger.md:19` (Claim 14); 225 commits confirmed by `git rev-list --count` (Claim 5); "~578k" matches the doc's "**577,971 tokens** (plus the earlier 3-agent history hunt ≈ 335k)" (`results.md:58-59`). The ~335k hunt figure and the task-notification provenance are instrument-only and inherit Claim 12's caveat — internally consistent, not independently reproducible (paraphrased — no quote available because those two sub-claims cover absent runtime telemetry; the reproducible figures are quoted/cited above).

**Evidence:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:19,58-59`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:19`, python3 recomputation

---

## Claim 29: Commit de9ccf7 — "3-way subsystem scan of all 225 commits ... Only 2 cleared the bar, both historical (HEAD clean)"; "A ... throttle.ts:2 ... commit e59c7ed"; "B ... (c2f5e8c, fixed 2493d2a)"; "read-only scan, no code changed"

**Location:** `git:de9ccf7` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

225 commits, the e59c7ed/c2f5e8c/2493d2a references, the throttle.ts:2 comment, and its persistence at the external clone's HEAD are all confirmed under Claims 5-9. "No code changed" is confirmed by the commit's own stat — it adds exactly one file, `runs/.../hunt-factcheck-behavioral-lie.md` (67 insertions), touching no code (paraphrased — no quote available because the claim covers absence of code changes; the range stat lists only the one markdown file). "Only 2 cleared the bar" is the hunt doc's own count and matches its two candidate sections; whether the scan's exclusions were complete is a property of the scan run, not statically checkable, but the two named candidates check out fully.

**Evidence:** `git log --stat de9ccf7`, `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:9-46`, external clone checks under Claims 5-9

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- **Claim 19** (`skills/code-review/SKILL.md:340-344`): Stage-1 dispatch step 3 still reads as pre-#3 scope-spec-only delivery; should reference the conditional inline-prefix rule.
- **Claim 22** (`skills/code-review/SKILL.md:634`): Stage-2 dispatch step 3 unconditionally says "the agent runs its own `git diff`" — now only the large-diff fallback; a literal reader silently reverts #3.
- **Claim 23** (`skills/code-review/SKILL.md:1406`): Important Reminders "Pass scope, not diffs" flatly contradicts the amended Step 1's conditional inlining.

### Mostly Accurate
- **Claim 10** (`runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:40-41`): the fix-commit message states the field mismatch outright, not the silent-no-op consequence — tighten "says so outright."
- **Claim 17** (`skills/code-review/SKILL.md:239-243`): "self-reading … shares no prefix" should be "shares only a ~330-token instruction prefix (~8k across the canon — negligible)."

### Unverifiable
- **Claim 12** (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3`): per-agent token figures come from runtime task-notification telemetry; verifying them would need the original session's notification log. (Also covers the ~335k hunt-cost sub-claim in Claim 28.)

## Goal-Alignment Note
- Answered: yes
- Out of scope: code-quality/design judgments (e.g., the tension between the measurement doc's "not worth a big SKILL rewrite to force-inline" recommendation and 2f5ad0b's decision to inline anyway — a design call, not a factual mismatch); completeness of the 225-commit hunt's exclusions (property of the scan run, not statically checkable)
- Escalate: the three stale SKILL.md cross-references (Claims 19, 22, 23) — the dispatch steps and Important Reminders still command unconditional agent self-read, so an orchestrator following them literally never performs the #3 inlining this range shipped; fix before further work builds on the inline-prefix behavior
