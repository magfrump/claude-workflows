# DD run — "Which actions should be taken next to improve this repo's code-review process?"

Model: claude-fable-5 (local arm) · Date: 2026-07-30 · Single-shot, headless, Path A/C only.

---

## Step 1 — Diverge

`Prior pruning grep: not runnable in this setting`

Prior-decision scan (from the material provided inline): decision 021 (reviewer context management) is an adjacent prior decision — its choice (staged diff-context path, Stage 1 git-only enrichment + Stage 3 agentic re-verification) is included below as **candidate 0** (status quo trajectory: "do what 021 already scheduled and nothing else").

### Candidates (one sentence each; no evaluation yet)

0. **Status quo trajectory** — implement only what decision 021 already commits to (Stage-1 git-only context for the sweep harness) and change nothing else about the pipeline.
1. **Minimal / do-nothing-plus-labeling** — leave the pipeline unchanged except that every single-run clean verdict consumed as assurance (Gate 1h, pr-prep sign-off) is stamped "single-sample, not an attestation" (§1.4 minimum).
2. **k≥3 fact-check with most-severe-wins** — run `code-fact-check` three times on byte-identical prompts, cluster claims by (file, line-range, claim text), take the most severe verdict, and log per-run verdicts as a tracked disagreement metric (§1.1).
3. **Measure the fact-check disagreement rate first** — before building any k-replication, run the 20-claim replicate sample of open question #2 to quantify the blocking channel's noise floor and set k empirically (§1.1's stated falsifier).
4. **Retrospective Confirmed-Good cross-check test** — replay the Confirmed-Good-vs-fact-check contradiction check against the 9 existing rubric cells to see whether it actually catches the two known MD1 misses before wiring it in (open question #4).
5. **Confirmed Good becomes a claim requiring evidence** — require an `Evidence:` citation on every Confirmed Good row plus a synthesis-stage cross-check that no Confirmed Good row contradicts an observation in the same run's fact-check report (§1.3).
6. **Design a second corroboration channel for the escalation gate** — run the §1.2 sub-DD on how soundness-class defects (the ND2 FLEE/CONTENT class) can ever reach the blocking band: quoted-intent-vs-quoted-code contradiction channel, failing-test requirement, or human routing queue.
7. **Implement 021 Stage-1 context enrichment now** — feed the sweep harness the full logical changeset (sibling commits labelled "already committed — context only") plus enclosing files, killing the sibling-commit false-positive class.
8. **Add a second vendor to the fact-check critic** — scope cross-vendor review to `code-fact-check` only (k≥3, most-severe-wins, clean-verdict audit per H5), riding on Stage-1 context (§5.0's "where to add a vendor" hypothesis).
9. **Replicate the MD1 R1 recovery** — re-run the full pipeline on MD1 (d86d2dc..d90d6bb) ≥3 times to test whether the sole cross-file-ceiling recovery replicates (open question #1, "Run this next", currently n=1).
10. **Fix the trap-1 rubric-selection bug** — replace filename-based rubric selection at `scripts/self-improvement.sh:1404` with content-based selection (commit SHA + run date match) (§5.4 trap 1).
11. **Naive: spend more model** — pin every critic and the fact-check to opus everywhere, on the theory that a bigger model tiers better.
12. **Naive/unconventional: delete tiering** — stop emitting severity bands entirely; report findings by issue identity only and push all severity triage to a human.
13. **Unconventional: widen the promotion gate ad hoc** — let any role critic directly file a 🔴 blocker without a fact-check-Incorrect or api-Breaking verdict attaching.
14. **Ideal-if-effort-were-free** — full two-vendor, all-critics k=3 ensemble with Stage-1 context at generation, Stage-3 agentic re-verification, per-claim verdict logging, Confirmed-Good cross-checks, and a human adjudication queue for soundness-class findings.
15. **Settle the MD1 nonce question empirically** — do the one prod build that resolves whether nonce delivery is really 🔴 (open question #3).

### Generation health check

- **Clustering**: candidates 2/3/4/9/15 all have a measurement flavor; they were checked for shared assumption — they do *not* share one (2 changes the pipeline, 3/4/9/15 gather evidence about it), so no corrective generation needed. Candidates 5/6/13 cluster on "gate design" — deliberate, since the doc's one-paragraph state says the gate is the problem; 12 and 13 were added to violate the shared assumption that the gate should be *repaired* rather than *removed or bypassed*.
- **Missing perspectives**: do-nothing/minimal present (0, 1); naive present (11, 13); newcomer-would-suggest present (11 "just use the biggest model", 12 "why do you even have tiers"); ideal-if-free present (14).
- **Vagueness**: every candidate names a specific mechanism, file, or experiment; none is "improve the process."
- **Dimensional anchoring** (multi-agent taxonomy): candidates span *dispatch order/iteration* (2, 3), *agent set* (8, 11), *communication topology* (5's synthesis cross-check, 7's context feed), *agent text/rules* (6, 13), *success criteria/output format* (12, 1), and *tooling/data* (10, 7). ≥2 lenses represented (technical, procedural, time-shifted, reframe); no fill-in generation triggered.

---

## Step 2 — Diagnose

Problem statement (one line, used as the decision goal): **the pipeline detects well and tiers badly — real, correctly-described defects fail to reach the blocking band, and clean verdicts are consumed as assurance without evidence; pick the next actions that fix or bound this.**

### Hard constraints

- **C1 (hard) — Blocking-channel stability.** Identical inputs must stop flipping a finding across the blocking boundary (Result 14a: same WARY_MOOD_DURATION defect rated Incorrect vs Mostly Accurate, flipping 🔴↔🟡; J_self on 🔴 rows 0.14–0.25).
  `success: on the open-question-#2 20-claim replicate sample, final band assignment for ground-truth defects is identical across ≥90% of replicate pairs, and the next full-pipeline arm measures 🔴-row J_self ≥ 0.5 (baseline 0.14–0.25).`
- **C2 (hard) — Reachability for soundness-class defects.** At least one promotion path must exist for defects that no fact-check-Incorrect or api-Breaking verdict can attach to (Result 15: ND2's FLEE/CONTENT defect fully reasoned, filed 🟢; human panel gated the merge on it).
  `success: a re-run of ND2 (commit 2d0ee3c) under the changed pipeline files the FLEE/CONTENT defect in the blocking band in ≥2 of 3 replicates (baseline 0/1 at 🟢).`
- **C3 (hard) — Assurance requires evidence.** No Confirmed Good row or single-run clean verdict may be consumed as assurance without corroboration, a contradiction check, or an explicit single-sample label (Result 12: two of three tiers filed MD1's actual blocking defect under Confirmed Good while their own fact-check reports held the disconfirming evidence verbatim; §1.4; H5 widened to sonnet/fable and the cross-vendor D2 abstention).
  `success: the retrospective cross-check over the 9 existing cells flags both known MD1 Confirmed-Good misses (open question #4), and Gate 1h / pr-prep sign-off output either aggregates k≥2 runs or carries the literal "single-sample, not an attestation" label, verified by reading the emitted rubric.`
- **C4 (hard) — No gating on 🟡-vs-🟢.** Tier assignment is the least stable output (Results 1, 17, 14a); gates key on issue identity or the blocking band only.
  `success: grep of Gate 1h and any new gate logic shows no condition comparing 🟡 against 🟢; all new gate conditions key on issue identity or blocking-band membership.`
- **C5 (hard) — Comparability discipline preserved.** Diff-inline/no-tools numbers and full-pipeline numbers measure different objects (§5.1); vendor runs without the role-skill prompts measure "model + paraphrase" (Result 8a's gap is larger than the tier gap).
  `success: every new measurement write-up carries the §4-style config row, and no cross-model number appears in a table without the config column; vendor critic runs use the actual role prompts.`
- **C6 (hard) — Sibling-commit FP class must not be reintroduced.** Any diff-only generation must run with 021 Stage-1 context (full logical changeset + enclosing files); cross-family consensus *amplified* this FP class (§5.0).
  `success: a re-run over the four cross-model ground-truth diffs yields zero sibling-commit false positives among Medium-or-higher findings (baseline: confident, sometimes unanimous FPs).`
- **C7 (hard) — Settled architecture stands.** Role critics stay (Results 2, 3 — closed twice over), no critic on haiku (Results 7/8), sonnet only with role-skill prompts (Results 8a, 13), reviewer ≠ fixer (Thread 6).
  `success: diff of skills/scripts after the action shows role-critic structure intact, no critic invocation pinned to haiku, and vendor/critic invocations passing the role skill files.`

### Soft constraints

- **S1 (soft)** — Marginal cost stays small: prefer ≤ ~3× current fact-check token cost per review and ≤ a few dollars per sweep (fact-check is one agent; Sol caught both D2 bugs for ~$0.10).
- **S2 (soft)** — Each action doubles as measurement: it closes or materially informs one of open questions #1–#4, so the evaluation program compounds rather than forks.
- **S3 (soft)** — Provider-portability and determinism of the sweep are preserved (021's Stage-1 basis; the whole ground for §5.1/§5.2 comparisons).
- **S4 (soft)** — Fast to land: ≤ ~1 week per action so the next evaluation arm can consume the change.

Non-obvious constraints considered: `--add-dir` does not propagate to Agent sub-agents (§1.5) — any design expecting a sub-agent to read a payload path directly cannot work today (bears on 6 and 8); reasoning-model empty-content must be recorded as errored, not clean (already handled in the harness, bears on 8); acceptance-filtered historical corpora cannot measure precision (trap 2 — bears on how 4 and 9 are interpreted).

---

## Step 3 — Match and prune

Reading key: C1–C3 are the problem constraints (does the candidate *address* them); C4–C7 are guardrails (does it *comply*). ✓ addresses/complies · ~ partial or uncertain · ✗ doesn't address · ⚠ actively makes worse. A candidate is discarded for ⚠ on any hard constraint or mostly-✗ with no compensating measurement value (S2).

| # | Candidate | C1 stab. | C2 reach. | C3 assur. | C4 no-🟡/🟢 | C5 compar. | C6 sibling-FP | C7 settled | S1 cost | S2 meas. | S3 port. | S4 fast |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 021 trajectory only | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ |
| 1 | Minimal labeling | ✗ | ✗ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ |
| 2 | k≥3 fact-check | ✓ | ✗ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ (Q2) | ✓ | ✓ |
| 3 | Measure disagreement | ~ | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ (Q2) | ✓ | ✓ |
| 4 | Retro cross-check test | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ (Q4) | ✓ | ✓ |
| 5 | Confirmed-Good evidence + cross-check | ~ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ (Q4) | ✓ | ✓ |
| 6 | Escalation-channel sub-DD | ~ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ✓ | ~ |
| 7 | Stage-1 context now | ✗ | ✗ | ✗ | ✓ | ✓ | ✓✓ | ✓ | ✓ | ~ | ✓ | ✓ |
| 8 | Vendor in fact-check | ~ | ~ | ✓ | ✓ | ~ | ⚠→~ | ✓ | ~ | ✓ | ✓ | ~ |
| 9 | Replicate MD1 R1 | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓✓ (Q1) | ✓ | ✓ |
| 10 | Trap-1 bug fix | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ |
| 11 | Opus everywhere | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | ~ | ⚠ | ✗ | ✓ | ✓ |
| 12 | Delete tiering | ~ | ⚠ | ⚠ | ✓ | ✓ | ✓ | ~ | ✓ | ✗ | ✓ | ✓ |
| 13 | Any critic files blocker | ✗ | ✓ | ⚠ | ✓ | ✓ | ✓ | ~ | ✓ | ✗ | ✓ | ✓ |
| 14 | Ideal full ensemble | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✗ | ~ | ~ | ✗ |
| 15 | Nonce prod build | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ (Q3) | ✓ | ✓ |

### Discards, with reasons

- **[0] 021 trajectory only** — everything already decided keeps happening, but ✗ on all three problem constraints; the observed failures (14a, 15, 12) remain unaddressed. Kept only as the baseline the survivors are measured against.
- **[1] Minimal labeling** — ✗ on C1/C2 and only half of C3 (labels the problem, doesn't check anything). Not discarded to oblivion: its labeling clause is *absorbed into candidate 5's fix sketch* as the cheap Gate-1h half of C3.
- **[3] Measure disagreement first** — sound, but it is literally §1.1's stated falsifier for candidate 2; folded into 2 as its mandatory first step rather than surviving separately (identical scope, no independent tradeoff).
- **[4] Retro cross-check test** — same relationship to 5: it is 5's validation prefix (open question #4, "cheap to test retrospectively against the 9 existing cells"); folded into 5's fix sketch.
- **[7] Stage-1 context now** — necessary but not sufficient; it addresses only C6, which is a guardrail. Folded into 8 as its hard prerequisite (8 scores ⚠ on C6 *without* 7, ~ with it).
- **[10] Trap-1 bug fix** — unconditional hygiene chore (a live measurement-corruption bug at `self-improvement.sh:1404`); it needs no DD adjudication and shouldn't compete for a portfolio slot. Recorded in the decision record as a "just do it" line item, not a survivor.
- **[11] Opus everywhere** — contradicted by the evidence it would spend money on: the 14a verdict flip happened within one model, H4's "ceiling is the config, not the model" falsification, and Result 8a showing the *prompt* (not the tier) took sonnet 0/2 → 2/2. ⚠ on S1, ✗ on every problem constraint. Discarded.
- **[12] Delete tiering** — ⚠ on hard C2 and C3: it removes the blocking band entirely, so Gate 1h has nothing to key on and all assurance collapses to human triage. Its useful kernel (gate on issue identity, not band) is already constraint C4. Discarded.
- **[13] Any critic files blocker** — ⚠ on hard C3: unverified confident findings become blockers, and the cross-model arm just demonstrated confident, sometimes unanimous wrongness (sibling-commit FPs). Also §1.2 explicitly says the escalation gap is a design decision to route through DD, not patch ad hoc — 13 is the ad hoc patch. Carried into candidate 6's option set (it is one design the sub-DD will evaluate and likely reject). Discarded here.
- **[14] Ideal full ensemble** — ✗ on S1/S4; it is the ideal-if-free reference point, and it decomposes exactly into 2 + 5 + 6 + 8 (+9 as its validation). Discarded as a unit; preserved as the asymptote the portfolio is walking toward.
- **[15] Nonce prod build** — cheap and closes Q3, but Q3 is a single finding's band dispute, not a process improvement; ✗ on all problem constraints. Moved to the backlog note in the record. Discarded as a survivor.

### Survivors and fix sketches

**Survivors: [2] [5] [6] [8] [9]** (5 of 16).

- **[2] k≥3 fact-check, most-severe-wins.** Fixable weakness: most-severe-wins converts one hallucinated Incorrect verdict into a blocker. Fix sketch: (a) run the folded-in candidate-3 measurement first — the 20-claim replicate sample sets k and quantifies the noise floor (if agreement ≥90%, drop to k=2 per §1.1's falsifier); (b) require the promoting verdict to carry a quote-anchored evidence line (the anchoring discipline Results 1–4 validated) so a promotion is checkable.
- **[5] Confirmed-Good evidence + synthesis cross-check.** Fixable weakness: could nag on trivial contradictions and bloat synthesis. Fix sketch: scope the cross-check to Confirmed Good rows only, and run the folded-in candidate-4 retrospective test on the 9 cells first — if it fails to flag the two known MD1 misses, redesign before wiring in. Absorbs candidate 1's Gate-1h "single-sample" label as the other half of C3.
- **[6] Escalation-channel sub-DD.** Fixable weakness: design risk — a new promotion channel could over-promote doc-dispute findings (Trap 4 in reverse). Fix sketch: seed the sub-DD's constraint list with C4 and with 14a/15's data; require any new channel to key on an *observable* (quoted-intent-vs-quoted-code contradiction, or a failing test per Thread 7), and sequence it after [2]'s disagreement data exists so the channel's noise floor is designed against measurements, not guesses.
- **[8] Second vendor scoped to the fact-check critic.** Fixable weakness: ⚠ on C6 if run diff-only today, and a C5 trap if run without role prompts. Fix sketch: gate it behind candidate 7 (021 Stage-1 context lands first), run the actual `code-fact-check` role prompt (Result 8a), k≥3 most-severe-wins, and audit the vendor's *clean* verdicts per H5 — all four refinements are already specified in §5.0.
- **[9] Replicate MD1 R1.** Fixable weakness: n=3 is still small and the result could be ambiguous (1/3 or 2/3). Fix sketch: report as accumulating n with per-run configs (trap-3 worktree verification: confirm no worktree contains its own rubric), and pre-register the interpretation — <2/3 recovery weakens 021's Stage-3 assumption and partially resurrects H4.

---

## Step 4 — Tradeoff matrix and decision

### Tradeoff table

| # | Approach | Effort | Risk | Core problem coverage | Key downside |
|---|---|---|---|---|---|
| 2 | k≥3 fact-check + disagreement measurement | ~1 day + ~3× fact-check tokens/review | Low (additive; FP inflation bounded by quote-anchor fix) | Stabilizes the *existing* blocking channel (C1); does nothing for reachability (C2) | Pays 3× on every review forever if disagreement turns out to be rare (mitig. — the Q2 sample gates k) |
| 5 | Confirmed-Good evidence + cross-check (+ single-sample label) | ~1 day (retro test: hours) | Low (read-only cross-check at synthesis) | Closes the false-assurance channel (C3); no promotion effect | Cross-check catches only contradictions the fact-check already recorded — a fact-check that never looked remains uncaught |
| 6 | Escalation-channel sub-DD → implement chosen channel | ~3–4 days (DD + impl) | Medium (design risk: over-promotion of doc-dispute findings) | The only survivor that addresses reachability (C2), the ND2 class | Wrong channel design trades false 🟢s for false 🔴s; needs [2]'s noise data to design against (mitig.) |
| 8 | Vendor in fact-check (after Stage-1) | ~4–5 days (Stage-1 harness + OpenRouter integration) + ~$0.10/diff | Medium (C6 FP class if context slips; C5 comparability traps) | Cross-family recall on correlated blind spots (Trap-4 class); partial C2/C3 | Blocked on 021 Stage-1; union-for-recall adds triage volume, and consensus must never be used for precision (§5.0) |
| 9 | Replicate MD1 R1 (n≥3) | ~1 day, compute-bound | Low (measurement only) | Pure information — validates the load-bearing n=1 under 021 Stage-3 | Changes nothing in the pipeline by itself; an ambiguous 1–2/3 result forces a judgment call |

### Falsifiable hypotheses

- **[2]** If we deploy k=3 most-severe-wins fact-check, we expect the WARY_MOOD-class verdict flip to stop moving final bands and 🔴-row J_self to rise from 0.14–0.25 to ≥0.5 within the next two full-pipeline arms; counter-evidence would be the Q2 sample showing ≥90% verdict agreement (instability smaller than 14a suggests — drop to k=2 or abandon) or J_self unchanged despite k=3.
- **[5]** If we require Evidence-cited Confirmed Good rows plus the synthesis cross-check, we expect the retrospective run to flag both known MD1 misses and zero new Confirmed-Good-contradicting-fact-check rows to ship in the next three arms; counter-evidence would be the retro test flagging 0–1 of the 2 known misses, or the cross-check firing mostly on trivia.
- **[6]** If we design and land a soundness corroboration channel, we expect ND2's FLEE/CONTENT defect to reach the blocking band in ≥2/3 replicates within one arm of landing; counter-evidence would be the defect still filing 🟢, or blocking-band false positives rising materially on the same ground-truth set.
- **[8]** If we add a second vendor to the fact-check critic with Stage-1 context, we expect ≥1 real incumbent-blind defect per sweep surfaced via vendor verdicts with zero sibling-commit FPs among Medium+ findings, within the first two sweeps; counter-evidence would be the vendor contributing only duplicates or FPs, or sibling-commit FPs reappearing.
- **[9]** If we replicate MD1, we expect ≥2/3 full-pipeline runs to recover R1 (both call sites, correct fix) within one day of compute; counter-evidence would be ≤1/3 recovery — which falsifies "config, not model" as stated and weakens 021's Stage-3 reliance.

### Stress-test pass (2–4 moves per survivor)

**[2] k≥3 fact-check**
- *Boring alternative* → Is k=3 needed, or is measurement alone enough? Changed the candidate: the Q2 20-claim sample is now a mandatory gate *inside* [2], and k is set by its result (k=2 if agreement ≥90%) rather than fixed a priori.
- *Push to extreme* → k=10 with most-severe-wins monotonically inflates promotions (each replicate is another draw at "one run says Incorrect"). Changed the matrix: capped k at 3 and added the quote-anchored-promotion requirement; risk stays Low only under that cap.
- *Failure-driven* → New failure mode: a single hallucinated Incorrect verdict now blocks a merge. Changed the card: promoting verdicts must quote the contradicting code line (Results 1–4 anchoring); unanchored Incorrect verdicts are logged but don't promote alone.

**[5] Confirmed-Good cross-check**
- *Boring alternative* → Would the `Evidence:` line alone suffice, skipping the cross-check? No — Result 12 shows the disconfirming evidence was *already present verbatim* in fable's own fact-check and the certification happened anyway; the contradiction check is the load-bearing half. Changed nothing in the matrix; confirmed the design's center of gravity.
- *Revealed preferences* → Reviewers already write the evidence (observed in Result 12); the miss occurs at synthesis. Confirms placement of the check at the synthesis stage, not inside the critics.
- *Failure-driven* → New failure mode: cross-check noise on incidental wording mismatches. Changed the card: scope to Confirmed Good rows only, and require the flagged contradiction to cite both the rubric row and the fact-check line (auditability over volume).

**[6] Escalation sub-DD**
- *Invert the thesis* → Argue for *not* building a channel: route soundness findings to a human queue instead — cheaper, no over-promotion risk, and the historical human panel *did* tier ND2 correctly. Survives partially: the human queue is now a required candidate in the sub-DD, and "build nothing automated" is its do-nothing option. Effort estimate range widened downward.
- *Organizational survival* → A bespoke channel keyed to one defect class rots when its champion leaves. Changed the card: prefer a channel keyed to the *general* Trap-4 signature (quoted-intent-vs-quoted-code contradiction), which the program already tracks as its dominant error class, over an ND2-shaped special case.
- *Failure-driven* → Over-promotion of doc-dispute findings (Trap 4's FP side). Changed sequencing: [6] runs *after* [2]'s disagreement data exists, so promotion thresholds are designed against a measured noise floor. Risk stays Medium but is now bounded by data.

**[8] Vendor in fact-check**
- *Push to extreme* → Four vendors with consensus gating: the cross-model arm already showed consensus *amplifies* the sibling-commit error. Changed the card: union-for-recall only; consensus is never a precision signal (hard rule inherited from §5.0).
- *Boring alternative* → Just diff the vendors' *findings* lists instead of running the vendor inside the fact-check role? Rejected: §5.0's evidence is that missed issues originate in the fact-check stage and three of four cross-family wins were Trap-4 fact-check-shaped; the role placement is the point. Confirmed as-is.
- *Failure-driven* → Kimi `content:null` budget exhaustion producing silent clean runs — already handled (errored-run recording in the harness); vendor clean verdicts audited per H5. No matrix change; verified the mitigation exists.

**[9] MD1 replication**
- *Invert the thesis* → What if it fails to replicate? That outcome is *more* valuable, not less — it falsifies "config, not model" and forces 021 Stage-3 redesign before more weight lands on it. Confirms [9]'s value is symmetric; risk stays Low.
- *Boring alternative* → Is n=3 worth a day when n=1 already "worked"? Yes: §5.0 explicitly marks the n=1 as load-bearing for Stage-3, and every future arm quietly assumes it. Changed the card: pre-register the interpretation thresholds (≥2/3 confirm; ≤1/3 falsify; exactly ambiguous → extend n) so the result can't be narrativized after the fact.

### Decision presentation block

```
┌─ DECISION: fix the tiering/blocking channel of a pipeline that detects well ─┐
│ 5 candidates survived step-3 pruning · scored on the step-4 axes             │
└──────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                    effort        risk      coverage      key downside
  ───  ─────────────────────────  ────────────  ────────  ────────────  ─────────────────────────────
   2  ★ k≥3 fact-check            ● ~1 day      ● low     ◐ 5/7 hard    ◐ 3× cost if noise rare (mitig.)
   5    Confirmed-Good x-check    ● ~1 day      ● low     ◐ 5/7 hard    ◐ blind to never-looked facts
   6    escalation-channel DD     ◐ ~3–4 days   ◐ med     ◐ 5/7 hard    ◐ over-promotion risk (mitig.)
   9    replicate MD1 R1          ● ~1 day      ● low     ◐ 4/7 hard    ○ changes nothing by itself
   8    vendor in fact-check      ○ ~4–5 days   ◐ med     ◐ 4/7 hard    ○ blocked on 021 Stage-1
```

```
╭─ [2] k≥3 fact-check, most-severe-wins   ★ recommended ──────────────────╮
│ effort    ~1 day (+~3× fact-check tokens/review; one agent, diff       │
│           already in context)               risk   low                  │
│ coverage  5/7 hard · 4/4 soft                                           │
│ hypothesis  "If chosen, WARY_MOOD-class verdict flips stop moving       │
│             final bands and 🔴-row J_self rises from 0.14–0.25 to ≥0.5  │
│             within the next two full-pipeline arms; counter-evidence =  │
│             Q2 sample shows ≥90% agreement, or J_self unchanged."       │
│ stress-tests applied                                                    │
│   · boring alternative → Q2 20-claim sample now gates k (k=2 if ≥90%)   │
│   · push to extreme → k capped at 3; quote-anchored promotion required  │
│   · failure-driven → unanchored lone Incorrect verdicts log, don't block│
│ key downside  pays 3× per review if disagreement is rare (mitig. — the  │
│               Q2 gate inside the candidate bounds exactly this)         │
╰─────────────────────────────────────────────────────────────────────────╯
```

Drill-down: cards for [5] [6] [9] [8] collapsed to their rows; expand by number on request.

```
▶ recommend [2] k≥3 fact-check · confidence 78% · runner-up [5], axis = blocking-channel noise vs silent false assurance
```

### Decision path taken: **Path C**

Rationale: no human is present, and [2] does not dominate at >80% — [5] sits within ~1 cell on every axis (same effort, same risk, adjacent coverage). The axis of disagreement is **which observed failure class to close first: blocking-channel instability (14a — verdict flips) vs silent false assurance (Result 12 — Confirmed Good certifying a blocking defect)**. The evaluation-state doc's own prioritization (§1.1 "highest-leverage change available and it is cheap") is the stated project preference along that axis, which is why [2] carries the ★; but because both are ~1 day, low risk, and touch disjoint pipeline stages (fact-check invocation vs synthesis), the tentative recommendation is an **ordered portfolio**: do [2] and [5] now in parallel; run [9] immediately after (one compute day); start [6] once [2]'s disagreement data exists; defer [8] until 021 Stage-1 lands. The Round claim subsection is skipped per the single-shot execution constraints; the static block above is the asynchronous surface.

---

## Step 5 — Decision record (inline)

**Goal**: Decide the next actions to fix the code-review pipeline's tiering/blocking failures (detects well, tiers badly) given the 2026-07-30 evaluation-state evidence.
**Project state**: cross-model review sweep branch · feeds the code-review evaluation program's next arm · not blocked.
**Task status**: complete (single-shot DD, Path C tentative recommendation; awaiting async user confirmation).

### Context

Every measured arm agrees the pipeline finds and correctly describes real defects but mis-bands them: the only promotion-to-🔴 gate (fact-check Incorrect / api Breaking) is unstable on identical input (Result 14a; 🔴-row J_self 0.14–0.25) and structurally unreachable for soundness-class defects (Result 15/ND2). Separately, the highest-assurance output — Confirmed Good — certified a branch's actual blocking defect at two of three tiers while the disconfirming evidence sat verbatim in the same run's fact-check (Result 12), and the incumbent family's blind spots are correlated (§5.0: 0/6 abstention on D2 while another vendor caught both bugs). Decision 021 already fixed context management; this DD decides what to do next on top of it.

### Options considered

16 candidates generated (0–15): status-quo/021-only, minimal labeling, k≥3 fact-check, disagreement measurement, retrospective Confirmed-Good test, Confirmed-Good evidence + cross-check, escalation-channel sub-DD, Stage-1 context, vendor-in-fact-check, MD1 replication, trap-1 bug fix, opus-everywhere, delete-tiering, any-critic-blocks, ideal full ensemble, nonce prod build. Five survived pruning: [2] [5] [6] [8] [9].

### Decision and rationale

**Ordered portfolio, led by [2].**

1. **Now (parallel, ~1 day each): [2] k≥3 fact-check with most-severe-wins** — gated internally by the open-question-#2 20-claim disagreement sample, k set by its result, promotions requiring quote-anchored evidence — **and [5] Confirmed-Good evidence requirement + synthesis cross-check**, validated first against the 9 existing cells (open question #4) and absorbing the §1.4 "single-sample, not an attestation" label for Gate 1h. They are both cheap, low-risk, touch disjoint stages, and each closes a directly observed failure (14a; Result 12).
2. **Next: [9] replicate MD1 R1** (one compute day, pre-registered thresholds) — the n=1 result is load-bearing for 021's Stage-3 and for "config, not model."
3. **Then: [6] the escalation-channel sub-DD** (per §1.2's explicit instruction to route it through DD), started once [2]'s disagreement data exists so the channel is designed against a measured noise floor; its candidate set must include the human-routing queue and the do-nothing option.
4. **Deferred: [8] second vendor in the fact-check critic** — highest expected recall gain (Trap-4 class, §5.0) but hard-blocked on 021 Stage-1 context (C6) and on [2]'s k-machinery, both of which it reuses.
5. **Unconditional chores outside the portfolio**: fix the trap-1 rubric-selection bug at `scripts/self-improvement.sh:1404` ([10]); queue the nonce prod build ([15], open question #3) as backlog.

Rationale in one sentence: every observed failure traces to the single sentence "detects well, tiers badly," and the two cheapest actions ([2], [5]) each convert an observed, reproducible failure into a checked invariant before any more expensive design work ([6], [8]) is committed.

See alternatives considered → Pruned candidates below.

### Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
`[0]: baseline only — addresses none of the three observed failure classes. [1]: labeling without checking; absorbed into [5]. [3]: is [2]'s falsifier, folded in as its gating first step. [4]: is [5]'s validation prefix, folded in. [7]: prerequisite of [8], folded in (021 already decided it). [10]: unconditional hygiene chore, not a portfolio slot. [11]: contradicted by Result 8a/H4 — the failures are config-shaped, not model-shaped, and 14a's flip was within-model. [12]: ⚠ hard C2/C3 — removes the blocking band Gate 1h keys on. [13]: ⚠ hard C3 — unverified confident findings become blockers (the cross-model arm's FP machine), and §1.2 forbids the ad hoc patch; carried into [6]'s option set. [14]: ideal-if-free reference; decomposes into 2+5+6+8(+9). [15]: settles one finding's band, not the process; backlog.`
`Prior pruning grep: not runnable in this setting` (adjacent prior decision 021 included as candidate 0 and carried forward: its Stage-1/Stage-3 split is accepted, not re-litigated).

### Stress-test mitigations

- How to read: *Boring alternative* mitigation — [2] now embeds the Q2 20-claim measurement as an internal gate; k is evidence-set (k=2 if agreement ≥90%), so the 3×-cost downside is bounded.
- How to read: *Push to extreme* mitigation — [2]'s k capped at 3 and promotion requires a quote-anchored Incorrect verdict, preventing most-severe-wins from monotonically inflating blockers.
- How to read: *Failure-driven* mitigation — [5]'s cross-check scoped to Confirmed Good rows with dual citation (rubric row + fact-check line), preventing synthesis nag-noise.
- How to read: *Invert-the-thesis* mitigation — [6]'s sub-DD must include "human queue" and "build nothing automated" as candidates, keeping the channel from being a foregone conclusion.
- How to read: *Organizational survival* mitigation — [6] prefers a channel keyed to the general Trap-4 signature (quoted-intent-vs-quoted-code) over an ND2-shaped special case.
- How to read: *Push to extreme* mitigation — [8] is union-for-recall only; consensus is never used as a precision signal (§5.0's amplified-FP result).
- How to read: *Boring alternative* mitigation — [9]'s interpretation thresholds pre-registered (≥2/3 confirm, ≤1/3 falsify) so the replication can't be narrativized post hoc.

### Consequences

Easier: the blocking channel becomes measurable (per-run verdict logs turn the coin flip into a tracked metric); Confirmed Good becomes auditable; the sub-DD for escalation starts with real noise-floor data; [8] lands on prepared ground (Stage-1 + k-machinery). Harder: every review costs ~3× fact-check tokens until Q2 data justifies less; synthesis gains a mandatory cross-check step; the ND2 reachability gap (C2) remains open until [6] completes — this portfolio deliberately sequences it second, so soundness-class defects still file 🟢 in the interim.

### Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
`if Q2 sample shows ≥90% fact-check verdict agreement (drop k to 2 or abandon [2]'s replication). if the retro test flags ≤1 of the 2 known MD1 Confirmed-Good misses (redesign [5] before wiring in). if MD1 replication recovers R1 in ≤1/3 runs (H4 partially resurrected — reopen 021 Stage-3 and re-rank [8] upward). if blocking-band FPs rise >2× after [2] lands (most-severe-wins over-promoting — revisit the anchor requirement). if 021 Stage-1 lands and a sweep still shows sibling-commit FPs (C6 unmet — [8] stays blocked). if [6]'s chosen channel fails the ND2 success line (≥2/3 blocking-band) in its first arm.`
