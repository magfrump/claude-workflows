# Step 1 — Diverge

Prior pruning grep: not runnable in this setting

1. **Minimal warning only:** Keep the pipeline unchanged but label every single-run clean verdict and every `Confirmed Good` row as non-attestational.
2. **Same-family fact-check replication:** Run `code-fact-check` three times on byte-identical prompts, cluster matching claims, use the most severe verdict, and log disagreement.
3. **Soundness escalation channel:** Add a second blocker-promotion path for corroborated intent-versus-code contradictions and state-machine soundness defects that cannot receive fact-check Incorrect or api-consistency Breaking.
4. **Evidence-backed positive outputs:** Require cited evidence for every `Confirmed Good` row, cross-check it against fact-check observations, and prohibit an unlabeled single-run clean result from serving as assurance.
5. **Calibration sprint:** Before broader changes, run a time-boxed experiment covering the four open questions in §3: MD1-R1 replication, fact-check disagreement frequency, the nonce production build, and retrospective Confirmed-Good cross-checking.
6. **Stage-1 context rollout:** Implement decision 021’s git-only full-logical-changeset and enclosing-file context in the portable harness before changing reviewer composition.
7. **Cross-vendor fact-check panel:** After Stage-1 context is available, run a second vendor in the fact-check stage with k≥3 sampling, most-severe-wins aggregation, clean-verdict auditing, and agentic re-verification.
8. **Whole-review vendor union:** Add a second vendor’s complete diff-inline review to every run and union all findings before synthesis.
9. **Nonce-only investigation:** Run the one production build needed to settle whether MD1’s nonce-delivery issue is actually 🔴, then make no other process change.
10. **Binary review output:** Eliminate 🟡 and 🟢 tiers entirely and emit only blocking versus non-blocking findings keyed by issue identity.
11. **Generalist replacement:** Remove the role critics and replace them with one stronger generalist reviewer to simplify dispatch and synthesis.
12. **Ideal if effort were free:** Replace the pipeline with an always-on, multi-vendor, multi-sample, fully agentic ensemble in which every finding and clean verdict receives independent proof, executable validation, and human adjudication.
13. **Rubric-selection repair:** Fix `scripts/self-improvement.sh:1404` to select historical rubrics by reviewed commit SHA and run date rather than filename order.

## Generation health check

- **Candidate clustering:** Candidates 2, 3, 4, and 7 initially clustered around escalation/adjudication. Candidates 5, 6, 9, and 13 add measurement, context, narrow empirical resolution, and harness correctness.
- **Missing perspectives:** Candidate 1 supplies the minimal/do-nothing-like option; candidates 10 and 11 are naive simplifications; candidate 12 is the effort-free ideal.
- **Excessive vagueness:** Every candidate names a concrete pipeline stage, output contract, experiment, or script change.
- **Dimensional anchoring:** The set spans agent set (7, 8, 11, 12), dispatch order and replication (2), communication/output contracts (4), escalation criteria (3, 10), context/data inputs (6), experimentation (5, 9), and tooling (13).
- **Relevant prior decision visible in supplied evidence:** Decision 021’s staged context path is represented by candidate 6 and treated as binding context for candidates 7 and 8; no filesystem scan was possible.

---

# Step 2 — Diagnose

**Decision goal:** Select the next actions that most reliably improve blocking decisions and assurance without sacrificing the code-review pipeline’s already-strong detection behavior.

## Hard constraints

### C1 — Target an evidenced failure or a load-bearing unknown — **hard**

The next action must address a directly observed failure or one of §3’s explicitly load-bearing unknowns, rather than optimize an unmeasured preference.

**success:** The implementation or experiment plan names at least one referenced result or §3 question and records a corresponding observable on ND2, ND3, MD1, a fresh raw corpus, or a prespecified claim sample.

Basis: the pipeline detects well but tiers badly; observed failures include unstable fact-check verdicts (Results 14a and 16), unreachable escalation for soundness defects (Results 15 and 16), false `Confirmed Good` rows (Result 12), and correlated vendor-family blind spots (§5.0).

### C2 — Preserve detection and the useful role-critic structure — **hard**

The action must not trade away band-agnostic issue recall or remove role critics without evidence overturning Results 2 and 3.

**success:** On the preserved ND2/ND3/MD1 corpus, band-agnostic issue-identity recall is no lower than the current pipeline’s baseline, and role-critic abstention/partitioning remains available unless a fresh controlled comparison shows non-inferiority.

Basis: role critics partition rather than duplicate and abstain cleanly; the generalist restructure is closed (§2, Results 2–3).

### C3 — Improve a production-relevant decision surface — **hard**

The action must materially improve at least one of blocking escalation, issue recall, false-positive rejection, or assurance semantics; changing only 🟡-versus-🟢 presentation is insufficient.

**success:** A replay or fresh run shows at least one of: a known blocking defect is promoted correctly; a known blind-spot issue is detected; a known sibling-commit false positive is rejected; or a clean/positive output is explicitly prevented from being consumed as unsupported assurance.

Basis: 🟡/🟢 tiering is unstable and should not drive gates (§2); issue identity and the blocking band are the meaningful surfaces.

### C4 — Respect configuration and context boundaries — **hard**

The action must preserve configuration provenance, use actual role-skill prompts where required, distinguish diff-inline from full-pipeline results, and obey decision 021 and sub-agent file-access limitations.

**success:** Every evaluation row records model/vendor, prompt or role skill, context stage, tool access, sample count, and aggregation rule; no diff-inline metric is presented as full-pipeline evidence; any vendor generation receives Stage-1 context and production acceptance remains subject to Stage-3 agentic verification.

Basis: Result 8a, §4, §5.1, decision 021, and §1.5.

### C5 — Do not create false assurance from abstention or a clean sample — **hard**

Neither an empty output nor a positive certification may silently become an attestation based on one model run.

**success:** Output artifacts distinguish `errored`, `no findings—single sample`, `corroborated clean`, and evidence-backed positive claims; Gate 1h and PR sign-off reject or visibly label single-sample clean results.

Basis: §1.3–1.4, Result 12, H5, and the six-of-six incumbent abstention on the sharpest cross-vendor diff (§5.0).

### C6 — Be observable, reversible, and safe to stage — **hard**

The action must expose disagreement and regressions and permit rollback without rewriting the whole review workflow.

**success:** The change is behind a configurable stage or aggregation rule, logs per-run inputs and outputs, retains the prior result for comparison, and has a documented rollback condition keyed to a measured recall, false-positive, or disagreement threshold.

Basis: the blocking channel’s instability is currently invisible (§1.1), while decision 021 explicitly chooses staged context evolution.

## Soft constraints

### C7 — Low implementation and operating cost — **soft**

Prefer changes implementable in days and targeted at cheap stages rather than always-on full-ensemble review.

Basis: §1.1 calls fact-check replication cheap; §5.0 recommends adding a vendor to fact-check first rather than funding a whole second-family review.

### C8 — Orthogonal improvement rather than redundant sampling — **soft**

Prefer a portfolio that separately addresses judgment stability, structural recall, escalation reachability, and positive-output assurance.

Basis: same-family resampling improves stability, while a second vendor improves correlated-family coverage (§2 and §5.0).

### C9 — Low maintenance and policy complexity — **soft**

Prefer explicit schemas, thresholds, and replayable tests over broad discretionary instructions requiring continual interpretation.

### C10 — Reduce high-value uncertainty early — **soft**

Prefer actions that resolve §3’s open questions before locking in k, vendor breadth, or escalation policy.

---

# Step 3 — Match and prune

## Compatibility matrix

Legend: ✓ addresses well · ~ partial or conditional · ✗ does not address · ⚠ actively worsens

| # | Candidate | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 | C10 |
|---:|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | Minimal warning only | ✓ | ✓ | ~ | ✓ | ~ | ✓ | ✓ | ✗ | ✓ | ✗ |
| 2 | Same-family fact-check replication | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ |
| 3 | Soundness escalation channel | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ~ | ~ |
| 4 | Evidence-backed positive outputs | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 5 | Calibration sprint | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 6 | Stage-1 context rollout | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ~ | ~ |
| 7 | Cross-vendor fact-check panel | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ~ | ✓ | ~ | ✓ |
| 8 | Whole-review vendor union | ✓ | ✓ | ✓ | ⚠ | ~ | ~ | ✗ | ✓ | ✗ | ~ |
| 9 | Nonce-only investigation | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ~ |
| 10 | Binary review output | ~ | ~ | ⚠ | ✓ | ~ | ~ | ✓ | ✗ | ~ | ✗ |
| 11 | Generalist replacement | ✗ | ⚠ | ~ | ~ | ~ | ~ | ✓ | ✗ | ✓ | ✗ |
| 12 | Effort-free exhaustive ensemble | ✓ | ✓ | ✓ | ~ | ✓ | ⚠ | ✗ | ✓ | ✗ | ~ |
| 13 | Rubric-selection repair | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ~ |

## Discards

- **1 — Minimal warning only:** Useful as a mitigation inside candidate 4, but alone it does not repair unstable blocking or substantiate positive claims.
- **6 — Stage-1 context rollout:** Required infrastructure under decision 021, but it does not directly fix the known fact-check, escalation, or positive-assurance defects; schedule it as a dependency of candidate 7 rather than the first review-process action.
- **8 — Whole-review vendor union:** Violates C4 in its stated diff-inline form because §5.0 observed severe sibling-commit false positives and found that consensus could amplify them.
- **9 — Nonce-only investigation:** Settles one severity dispute but offers little coverage of the systemic failures.
- **10 — Binary review output:** Removing presentation bands does not make the blocking boundary correct and risks hiding the escalation failure rather than fixing it.
- **11 — Generalist replacement:** Conflicts directly with the settled evidence that role critics partition usefully and abstain cleanly (§2, Results 2–3).
- **12 — Effort-free exhaustive ensemble:** Operational complexity, permanent cost, and difficult rollback violate the staged-safety requirement despite broad theoretical coverage.
- **13 — Rubric-selection repair:** A valid maintenance fix, but historical precision measurement is exhausted (§5.4 Trap 2), so it is lower leverage than production gate and assurance changes.

## Survivors and fix sketches

### 2 — Same-family fact-check replication

Fix its over-calling risk by retaining all three verdicts and evidence, initially comparing most-severe-wins against the old single result, and auditing every promotion before allowing it to block. Use the §1.1 falsifier: if agreement is at least 90% over 20 claims, reduce k rather than institutionalizing unnecessary sampling.

### 3 — Soundness escalation channel

Do not let free-form “this seems wrong” reasoning promote findings. Require a quoted intent statement, a quoted contradictory code path or reconstructed state transition, and either independent corroboration, a failing test, or human review before blocking.

### 4 — Evidence-backed positive outputs

Use a structured `Evidence:` field with file and line references and a synthesis check over fact-check observations; represent unresolved contradictions as findings or `not attested`, never as `Confirmed Good`. Extend the same output schema to clean verdicts so Result 12 and §1.4 are handled together.

### 5 — Calibration sprint

Pre-register configurations and observables, use detached pre-fix worktrees, select rubrics by content, and keep arm-specific result tables separate (§4 and §5.4). The sprint should feed decisions rather than defer all fixes: candidate 4 can proceed immediately, while its retrospective test runs inside the sprint.

### 7 — Cross-vendor fact-check panel

Make decision 021 Stage 1 a prerequisite, supply actual critic prompts, audit clean outputs, and require Stage-3 agentic re-verification before a cross-vendor result blocks. Start as shadow traffic so correlated recall gains and new false positives are visible before gating.

**Survivors:** [2], [3], [4], [5], [7]

---

# Step 4 — Tradeoff matrix and decision

## Detailed tradeoff table

| Candidate | Effort | Risk | Core problem coverage | Key downside |
|---|---|---|---|---|
| **2 — Same-family fact-check replication** | **2–4 engineering days**, plus roughly 3× fact-check inference | **Medium** | Directly stabilizes the sole current promotion channel (Results 14a, 16); exposes its disagreement rate and preserves detection | Most-severe-wins may promote an unsupported outlier unless evidence is audited |
| **4 — Evidence-backed positive outputs** | **1–3 engineering days** plus replay of nine existing cells | **Low** | Directly addresses Result 12 and §1.4; catches contradictions already present in a run’s own fact-check output | A citation can still be irrelevant or misinterpreted; structural evidence is not proof by itself |
| **5 — Calibration sprint** | **3–5 working days** | **Low** | Resolves all four high-value unknowns in §3 and calibrates k, positive-output checks, cross-file recovery, and nonce severity | Produces information rather than immediately repairing most production behavior |
| **3 — Soundness escalation channel** | **4–8 engineering days**, depending on test/human routing | **Medium** | Opens a promotion path for ND2-class state-machine defects that fact-check/api gates cannot reach (Results 15–16) | A broad “soundness” category could become a subjective false-positive channel |
| **7 — Cross-vendor fact-check panel** | **1–2 weeks** including Stage-1 integration and shadow evaluation | **Medium–high** | Combines same-stage stability with cross-family recall, targeting the Trap-4 blind spot documented in §5.0 | Vendor/context complexity and union-style over-calling may exceed the incremental recall benefit |

## Falsifiable hypotheses

### 2 — Same-family fact-check replication

**If chosen,** k=3 byte-identical fact-checking will expose nontrivial verdict disagreement and prevent at least one known under-called blocker from remaining non-blocking within a 20-claim calibration plus ND2/MD1 replay; **counter-evidence would be** at least 90% exact verdict agreement and no corrected blocking decision.

### 4 — Evidence-backed positive outputs

**If chosen,** the evidence requirement and fact-check contradiction pass will reject both known MD1 false `Confirmed Good` certifications and leave zero uncited positive rows within one retrospective replay of the nine existing cells; **counter-evidence would be** either known contradiction surviving unchanged or more than 5% of positive rows carrying citations that do not support the claim.

### 5 — Calibration sprint

**If chosen,** within five working days the program will produce configuration-labelled answers for all four §3 questions, including a measured fact-check disagreement rate and a replicated or failed MD1-R1 recovery; **counter-evidence would be** any question remaining unmeasured because its corpus, configuration, or observable was not pre-registered.

### 3 — Soundness escalation channel

**If chosen,** a constrained corroboration rule will promote ND2’s FLEE/CONTENT defect to at least merge-gating status while leaving a prespecified set of documented-intent controls unpromoted within two replay cycles; **counter-evidence would be** failure to promote ND2 or promotion of more than one unsupported control case.

### 7 — Cross-vendor fact-check panel

**If chosen,** Stage-1-contextualized cross-vendor fact-checking will recover at least one validated Trap-4 or incumbent-blind-spot claim missed by same-family k=3, without adding more than one adjudicated false positive per 20 claims during a two-week shadow run; **counter-evidence would be** zero incremental validated recall or a false-positive rate above 5%.

## Stress-test pass

### Candidate 2 — Same-family fact-check replication

- **Boring alternative:** Tested k=2 or majority vote; this did not displace k=3 because Result 14a shows under-calling and §1.1 already supplies a 20-claim falsifier, but it added an explicit rule to reduce k if agreement is at least 90%.
- **Invert the thesis:** Assumed the severe outlier is wrong rather than the mild verdict; this raised risk from low to medium and added evidence logging plus shadow/audit mode before blockers are enforced.
- **Failure-driven:** Identified duplicate paraphrases and line drift as ways “most severe wins” could amplify noise; this added byte-identical prompts and clustering by file, line range, and normalized claim text.
- **Organizational survival:** Asked whether future maintainers could reproduce aggregation; this strengthened C6 by requiring persisted per-run verdicts and a configurable aggregator.

### Candidate 4 — Evidence-backed positive outputs

- **Boring alternative:** A warning label alone would cheaply satisfy part of §1.4, but would not catch Result 12’s internal contradiction; the candidate retained both the label and synthesis cross-check.
- **Invert the thesis:** A citation may create stronger-looking false assurance; this changed the downside to “citation is not proof” and added contradiction checking rather than citation presence alone.
- **Push to extreme:** Requiring proof for every harmless positive row could bloat output; this limited `Confirmed Good` to claims worth certifying and permits omission instead of ceremonial evidence.
- **Organizational survival:** Free-form evidence would drift; this added a structured file/line/observation schema.

### Candidate 5 — Calibration sprint

- **Boring alternative:** Running only the 20-claim disagreement sample is faster, but would leave MD1-R1’s n=1 assumption and the positive-output cross-check untested; the full sprint remained but was capped at five working days.
- **Revealed preferences:** Historical rubrics omit rejected and never-raised findings (§5.4 Trap 2); this changed the plan from retrospective precision measurement to targeted replay and fresh raw outputs.
- **Failure-driven:** Temporal leakage and wrong-rubric selection could manufacture success; this added detached worktrees, content-based rubric selection, and configuration-labelled tables.
- **Organizational survival:** Experiments can become unactionable reports; this added predefined decision thresholds for k, cross-check adoption, and MD1-R1 interpretation.

### Candidate 3 — Soundness escalation channel

- **Invert the thesis:** The current narrow gate may intentionally protect precision; this raised the candidate’s risk to medium and ruled out unconditional automatic promotion.
- **Failure-driven:** “Contradicts intent” can reward speculative intent claims; this added quoted intent, quoted code, reconstructed consequence, and independent corroboration requirements.
- **Boring alternative:** Human-queue routing captures much of the benefit with less policy risk; this changed the initial rollout from automatic 🔴 promotion to merge-gating review, with automation earned by replay precision.
- **Push to extreme:** Treating every comment mismatch as blocking would flood reviews; this narrowed scope to externally consequential state transitions or mechanically demonstrated reward/penalty inversions.

### Candidate 7 — Cross-vendor fact-check panel

- **Invert the thesis:** Cross-family consensus amplified sibling-commit false positives in §5.0; this preserved medium-high risk and made decision 021 Stage 1 plus Stage-3 verification mandatory.
- **Boring alternative:** Candidate 2 may buy enough stability without vendor complexity; this changed candidate 7 from an immediate rollout to a conditional shadow-stage follow-up.
- **Failure-driven:** A vendor can abstain its way to apparent consistency; this added errored/empty-output separation and clean-verdict auditing.
- **Implementation org chart:** Maintaining provider adapters, prompts, and adjudication has an ownership cost; this narrowed the first vendor use to fact-check rather than the complete review.

## Decision presentation

```text
┌─ DECISION: Select the next actions that most reliably improve blocking decisions and assurance without sacrificing detection ─┐
│ 5 candidates survived step-3 pruning · scored on the step-4 axes                                                            │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                    effort          risk       coverage       key downside
  ───  ─────────────────────────  ──────────────  ──────────  ─────────────  ─────────────────────────────────
   2 ★ Fact-check replication     ● 2–4 days      ◐ medium    ● 6/6 hard     ◐ severe outlier may over-promote (mitig.)
   4   Evidence-backed positives  ● 1–3 days      ● low       ● 6/6 hard     ◐ citation may not prove the claim (mitig.)
   5   Calibration sprint         ● 3–5 days      ● low       ● 6/6 hard     ◐ information delays some production fixes
   3   Soundness escalation       ◐ 4–8 days      ◐ medium    ● 6/6 hard     ◐ subjective escalation risk (mitig.)
   7   Cross-vendor fact-check    ○ 1–2 weeks     ○ med-high  ◐ 5/6 hard     ○ context/vendor complexity (mitig.)
```

```text
╭─ [2] Fact-check replication   ★ recommended ───────────────────────────╮
│ effort    2–4 days (orchestration, clustering, logs, replay)           │
│ risk      medium                                                        │
│ coverage  6/6 hard · 3/4 soft                                           │
│ hypothesis  If chosen, k=3 byte-identical fact-checking will expose     │
│             nontrivial disagreement and correct at least one known      │
│             under-called blocker within a 20-claim plus ND2/MD1 replay; │
│             counter-evidence = ≥90% exact agreement and no corrected    │
│             blocking decision.                                          │
│ stress-tests applied                                                     │
│   · Boring alternative → added ≥90% agreement rule for reducing k       │
│   · Invert the thesis → raised risk; added shadow audit before gating    │
│   · Failure-driven → added byte identity and claim clustering            │
│   · Organizational survival → required persisted per-run verdicts        │
│ key downside  Most-severe-wins can amplify an unsupported severe outlier;│
│               mitigate with evidence logs, shadow comparison, and audit. │
╰──────────────────────────────────────────────────────────────────────────╯
```

```text
┌─ DRILL-DOWN ────────────────────────────────────────────────────────────┐
│ The grid is the full candidate index; expand another candidate by its  │
│ number (#3, #4, #5, or #7). Only the recommended card is open here.    │
└─────────────────────────────────────────────────────────────────────────┘
```

```text
▶ recommend [2] Fact-check replication · confidence 78% · runner-up [4], axis = unstable blocker promotion vs unsupported positive assurance
```

The presentation passes the structure gate: the recommendation and glyph legend are visible, every survivor appears in the grid, the expanded card matches row 2, and the drill-down affordance is explicit.

## Decision path

**Path C — tradeoff unclear, no human present.**

No single action dominates above 80% confidence because candidates 2 and 4 address separate directly observed failures: candidate 2 repairs the sole unstable blocker-promotion channel, while candidate 4 repairs false positive assurance. The evaluation state explicitly calls candidate 2 the highest-leverage cheap change (§1.1), which supplies the tiebreaker, but not a reason to defer candidate 4.

**Tentative ordered portfolio:**

1. **Implement candidate 2 now in shadow/audit mode**, with k=3, most-severe-wins, exact-prompt replication, claim clustering, per-run logs, and the 20-claim ≥90%-agreement falsifier.
2. **Implement candidate 4 concurrently or immediately next**, covering both `Confirmed Good` evidence and single-sample clean-verdict semantics.
3. **Run candidate 5 during those rollouts**, using its results to set k and validate the positive-output cross-check rather than delaying all fixes.
4. **Design and replay candidate 3 next**, initially routing qualifying soundness contradictions to a merge-gating human/independent corroboration queue rather than automatically assigning 🔴.
5. **Defer candidate 7 until decision 021 Stage 1 is operational and shadow evidence shows incremental recall**, then retain Stage-3 agentic verification.

**Axis of disagreement:** immediate stabilization of the existing blocking channel versus broader assurance and cross-family coverage. The project’s stated evidence favors stabilization first (§1.1), while the portfolio preserves the orthogonal actions established by Result 12 and §5.0.

---

# Step 5 — Decision record (inline)

**Goal:** Decide the next ordered actions for improving the repository’s code-review process.  
**Project state:** Reliability hardening for code-review detection, escalation, and assurance · standalone evaluation follow-up · blocked only on implementation and specified measurements.  
**Task status:** complete (tentative Path-C decision recorded)

## Context

The evaluation program shows stable defect detection but unstable and structurally incomplete tiering. A single `code-fact-check` verdict controls normal 🔴 promotion and changed across identical inputs (Results 14a and 16); ND2 demonstrated a correctly reasoned state-machine defect with no reachable promotion channel (Result 15); MD1 showed actual blockers certified as `Confirmed Good` despite contradictory fact-check evidence (Result 12); and §5.0 showed correlated Claude-family blind spots alongside diff-only cross-vendor false positives. Role critics, issue-identity scoring, and decision 021’s staged context path are already settled constraints.

## Options considered

The field included minimal labeling, same-family fact-check replication, a new soundness escalation channel, evidence-backed positive outputs, a four-question calibration sprint, Stage-1 context rollout, targeted and whole-review cross-vendor panels, narrow nonce testing, binary output, generalist replacement, an exhaustive ensemble, and rubric-selection repair.

## Decision and rationale

Adopt a staged portfolio led by **[2] same-family fact-check replication**, followed immediately by **[4] evidence-backed positive and clean outputs**, with **[5] a time-boxed calibration sprint** running alongside them. Then implement **[3] a constrained soundness corroboration route**, initially with independent or human confirmation, and evaluate **[7] cross-vendor fact-checking** only after decision 021 Stage 1 is available.

Candidate 2 leads because it repairs the only ordinary blocker-promotion channel, whose instability is directly observed and explicitly identified as the highest-leverage cheap change (§1.1). Candidate 4 is complementary, not an alternative: Result 12 and §1.4 show that clean and positive outputs are independently unsafe. Candidate 5 supplies the thresholds needed to set k and validate both changes. Candidates 3 and 7 address separate structural escalation and family-correlated recall gaps but carry greater policy or context risk.

See alternatives considered → **Pruned candidates and why**

## Pruned candidates and why

How to read: Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

[1]: labeling alone does not repair the gate or validate positive claims. [6]: required dependency under decision 021, but lower direct leverage than the selected gate changes. [8]: whole-review diff-inline union reproduces the sibling-commit false-positive class and can amplify it by consensus. [9]: settles only the nonce severity dispute. [10]: binary presentation hides rather than repairs escalation errors. [11]: contradicts settled evidence supporting role critics. [12]: excessive cost, maintenance, and rollback risk. [13]: valid script fix, but historical precision measurement is exhausted and production gate failures are more urgent. Prior pruning grep: not runnable in this setting.

## Stress-test mitigations

- **How to read: Invert the thesis mitigation for [2]** — raised risk to medium and required shadow comparison plus evidence auditing before most-severe-wins can block.
- **How to read: Failure-driven mitigation for [2]** — required byte-identical prompts, claim clustering, and persisted per-run verdicts to prevent duplicate or line-drift amplification.
- **How to read: Boring alternative mitigation for [2]** — added a rule to reduce k if at least 90% exact verdict agreement is observed on 20 claims.
- **How to read: Invert the thesis mitigation for [4]** — treated citations as evidence pointers rather than proof and added contradiction checking against fact-check observations.
- **How to read: Revealed-preferences mitigation for [5]** — excluded acceptance-filtered historical precision as a success measure and used fresh raw outputs or targeted replay instead.
- **How to read: Boring alternative mitigation for [3]** — changed the first rollout from automatic promotion to corroborated merge-gating review.
- **How to read: Invert-the-thesis mitigation for [7]** — made Stage-1 context, clean-verdict auditing, shadow evaluation, and Stage-3 re-verification mandatory.

## Consequences

This makes blocker decisions less dependent on one unstable sample, prevents unsupported positive or clean output from masquerading as assurance, and turns disagreement into a tracked metric. It also establishes a controlled route for ND2-class defects and a context-safe path toward vendor diversity.

Costs increase through repeated fact-check inference, structured synthesis, replay maintenance, and later provider integration. Most-severe-wins can over-promote outliers, the soundness channel can become subjective, and evidence citations can create ceremonial confidence unless their relevance is checked. Yellow-versus-green stability remains intentionally unsolved because §2 says it should not drive gates.

## Revisit triggers

How to read: Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.

If k=3 exact verdict agreement is **≥90% on the prespecified 20-claim sample**, reduce k to 2 or compare against single-run operation. If most-severe-wins produces **more than one unsupported blocker per 20 claims**, suspend blocking aggregation and use independent corroboration or majority-plus-proof. If the Confirmed-Good cross-check fails to catch either known MD1 contradiction, redesign it before production use. If MD1-R1 recovery fails to replicate in **two controlled full-pipeline reruns**, revisit the assumption that Stage-3 multi-critic breadth clears the cross-file ceiling. If the soundness channel promotes **more than one unsupported control case per replay suite**, keep it human-routed rather than automatic. If cross-vendor fact-checking yields **zero incremental validated findings or more than 5% adjudicated false positives over 20 claims**, do not promote it from shadow mode.