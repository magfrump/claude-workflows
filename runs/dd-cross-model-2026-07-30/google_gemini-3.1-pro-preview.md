### 1. Diverge — generate many possibilities

**Prior pruning grep: not runnable in this setting**

1. **Implement k=3 `code-fact-check` sampling with most-severe-wins aggregation (incumbent only).**
2. **Add a second vendor (e.g., Kimi or Sol) to the production `code-fact-check` gate.**
3. **Route the soundness-escalation gap (§1.2) into a dedicated divergent-design run.**
4. **Require `Evidence:` labels on `✅ Confirmed Good` verdicts and add a synthesis cross-check (§1.3).**
5. **Run the n=1 replication test for MD1 R1 to verify single-pass cross-file boundary clearance.**
6. **Measure 20-claim fact-check agreement to establish noise floor before hardcoding k=3.**
7. **Do nothing; continue monitoring the single-agent pipeline.** (Minimal / Status Quo)
8. **Require every escalated finding to include a runnable failing test script.** (Naive / Unconventional)
9. **Eliminate tiering entirely and pass all detected anomalies to the human reviewer.** (Naive)
10. **Build a fine-tuned, flawless reviewer model trained on historically accepted PRs.** (Ideal if effort were free)
11. **Combine multi-vendor and k=3 sampling (2 incumbent, 1 external) in the synthesis gate immediately.**
12. **Require two separate Claude models (Sonnet and Opus) to agree before generating a 🔴.**

**Generation health check notes:**
- *Clustering check:* Passed. Candidates span process architecture (1, 11), prompt constraints (4), external model integrations (2), and distinct evaluative workflows (3, 5, 6).
- *Missing perspectives check:* Passed. Includes deliberate regression/UX disruption (8, 9), status quo (7), and the theoretical infinite-effort route (10).
- *Vagueness check:* Passed. Broad goals mapped to specifics (e.g., "fix false attestation" → "Require `Evidence:`... synthesis cross-check").
- *Dimensional anchoring check:* Passed. Approaches differ across math/aggregation (most-severe vs consensus), origin (incumbent vs multi-vendor), and timing (inline fix vs asynchronous design record).

---

### 2. Diagnose — specify the actual problems and constraints

**Hard Constraints**
- **C1: Targets a confirmed high-priority gap.**
  `success: the targeted issue is explicitly categorized under "1. Definitely needed" or "3. Open, highest-value unknowns" in the evaluation-state doc, with documented evidence.`
- **C2: Zero reliance on acceptance-filtered data.**
  `success: the approach's implementation mechanism does not require training, extraction, or few-shotting against historical merged PR rubrics (observing §5.4 Trap 2).`
- **C3: Operationally feasible in single-pass pipelines.**
  `success: the action can be implemented in existing shell/python orchestrators without requiring a multi-week context-architecture redesign or immediate Stage-3 agentic overhauls.`

**Soft Constraints**
- **C4 (Leverage):** Exerts high leverage on the single pipeline bottleneck (the highly unstable promotion-to-🔴 gate).
- **C5 (Stability):** Establishes foundational operational stability that subsequent pipeline metrics and multi-model additions depend on.

---

### 3. Match and prune

| # | Approach | C1 (Target) | C2 (No Trap 2) | C3 (Feasible) | C4 (Leverage) | C5 (Stability) |
|---|---|---|---|---|---|---|
| 1 | **k=3 incumbent fact-check** | ✓ | ✓ | ✓ | ✓ | ✓ |
| 2 | Second vendor to fact-check | ✓ | ✓ | ~ | ✓ | ✗ |
| 3 | **DD on soundness escalation** | ✓ | ✓ | ✓ | ✓ | ~ |
| 4 | **Confirmed Good cross-check** | ✓ | ✓ | ✓ | ~ | ✓ |
| 5 | Replicate MD1 R1 | ✓ | ✓ | ✓ | ✗ | ✗ |
| 6 | Measure 20-claim variance | ✓ | ✓ | ✓ | ✗ | ✓ |
| 7 | Do nothing | ✗ | ✓ | ✓ | ✗ | ✗ |
| 8 | Runnable test required | ~ | ✓ | ✓ | ⚠ | ~ |
| 9 | Eliminate tiers entirely | ✗ | ✓ | ✓ | ✗ | ✗ |
| 10 | Fine-tune on history | ✓ | ✗ | ✗ | ✓ | ✓ |
| 11 | **Multi-vendor k=3 fact-check** | ✓ | ✓ | ~ | ✓ | ~ |
| 12 | Sonnet+Opus consensus | ⚠ | ✓ | ✓ | ⚠ | ⚠ |

**Discards with reasons:**
- **[7, 9]:** Fails C1 (Does not address explicitly observed gaps; breaks pipeline intent).
- **[10]:** Fails C2 and C3 (Violates Trap 2 via historical data reliance; massive training complexity).
- **[8, 12]:** ⚠ on C4 (Consensus requirements severely exacerbate the pipeline's core "under-calling" failure mode described in §1.1).
- **[5, 6]:** Demoted to diagnostic sub-tasks. Evaluating these is necessary but they don't fix the architectural pipeline on their own. (Candidate 6 is folded into Candidate 1 via stress-test mitigation).
- **[2]:** Fails C5. Inserting a second vendor without first fixing incumbent stability adds structural non-determinism to an inherently noisy gate. Replaced by [11].

**Fix sketches for fixable weaknesses:**
- **[3] DD on soundness escalation:** Mitigate C5 (stability) impact by isolating the DD evaluation from the core CI loop, ensuring the live pipeline is unblocked while the design completes asynchronously.
- **[4] Confirmed Good cross-check:** Mitigate C4 (leverage on the 🔴 gate) by strictly scoping this as a false-negative catch, complementing rather than competing with the primary fact-check fix.
- **[11] Multi-vendor k=3 fact-check:** Mitigate C3 (feasibility) by strictly restricting the OpenRouter vendor invocation to 021 Stage-1 isolated diffs, avoiding live-repo context pollution and Trap 1.

**Surviving Candidates:** [1], [3], [4], [11].

---

### 4. Tradeoff matrix and decision

| Approach | Effort | Risk | Core problem coverage | Key downside |
|----------|--------|------|-----------------------|--------------|
| **[1] k=3 incumbent fact-check** | 1 day | low | 3/3 hard | Blind to incumbent's correlated blind spots |
| **[3] DD on soundness escalation** | 2 days | low | 3/3 hard | Defers actual pipeline fix for logic defects |
| **[4] Confirmed Good cross-check** | 1 day | low | 3/3 hard | Does not fix unstable finding promotion |
| **[11] Multi-vendor k=3 fact-check** | 1 week | high | 3/3 hard | Imports vendor API risk into the PR CI loop |

**Per-survivor hypotheses:**
- **[1]:** If chosen, J_self on 🔴 rows will rise from ~0.2 to >0.75 within two weeks; counter-evidence = disagreement rate across the 3 replicates remains >50%.
- **[3]:** If chosen, we surface a viable non-fact-check promotion path for logic bugs within 3 days; counter-evidence = the DD concludes all options introduce unacceptable false positives.
- **[4]:** If chosen, Fable/Haiku false attestations dropping verified defects to Confirmed Good falls to zero; counter-evidence = models successfully hallucinate `Evidence:` citations that explicitly bypass the cross-check.
- **[11]:** If chosen, the pipeline will capture at least 2 of the 4 §5.0 cross-vendor blind spots automatically in prod within 2 weeks; counter-evidence = the second vendor introduces blocking sibling-commit FPs that necessitate reverting the PR pipeline.

**Stress-test pass:**
- **[1] k=3 incumbent fact-check**
  - *Boring alternative:* Instead of blindly hardcoding k=3, isn't there a cheaper way to verify the variance? → *Mitigation:* Insert candidate 6 (measure 20-claim offline variance) as a pre-commit verification script to ensure k=2 isn't sufficient before committing k=3 infrastructure.
  - *Push to extreme:* What if all 3 runs confidently abstain? → Acknowledged limitation. Incumbent resampling solves *stability*, not *recall*. Sets the clear boundary for when to implement [11].
- **[3] DD on soundness escalation**
  - *Revealed preferences:* When tackling logic bugs historically, the pipeline relies on semantic similarity (Trap 2: Rubrics). → *Mitigation:* The DD must carry a hard constraint permanently barring intent-extraction from historical text.
- **[4] Confirmed Good cross-check**
  - *Failure-driven:* What if the synthesis agent performing the cross-check *also* hallucinates, declaring the evidence matches reality when it doesn't? → *Mitigation:* The synthesis step must be prompt-constrained to strictly validate exact-quoted line-matches only.
- **[11] Multi-vendor k=3 fact-check**
  - *Organizational survival:* Will adding rate-limited OpenRouter keys to the primary PR blocking pipeline survive CI scale? → Flags a severe risk. Merging multi-vendor sweeps into the live review loop immediately introduces unpredictable latency ceilings.

#### Decision presentation

```text
┌─ DECISION: Select the optimal next action to improve code-review pipeline accuracy ────────┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes                           │
└────────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                  effort     risk    coverage   key downside
  ───  ───────────────────────  ─────────  ──────  ──────────  ──────────────────────────────────────────
   1  ★ k=3 incumbent fact-chk   ● 1 day    ● low   ● 3/3 hard  ● Blind to correlated blind spots (mitig.)
   4    Confirmed Good check     ● 1 day    ● low   ● 3/3 hard  ◐ Fails to fix finding promotion stability
   3    DD on soundness escal.   ◐ 2 days   ● low   ● 3/3 hard  ◐ Defers primary fact validation fix
   11   Multi-vendor k=3 fact    ○ 1 week   ○ high  ● 3/3 hard  ○ OpenRouter API latency/risk in prod CI
```

```text
╭─ [1] k=3 incumbent fact-check   ★ recommended ──────────────────────────╮
│ effort    1 day                             risk   low                  │
│ coverage  3/3 hard · 2/2 soft                                           │
│ hypothesis  If chosen, J_self on 🔴 rows will rise from ~0.2 to >0.75   │
│             within two weeks; counter-evidence = disagreement rate      │
│             across 3 replicates remains >50%.                           │
│ stress-tests applied                                                    │
│   · Boring alternative → Added a 20-claim offline variance measure-     │
│     ment step prior to CI deployment to verify k=2 isn't sufficient.    │
│   · Push to extreme → Acknowledged incumbent resampling resolves        │
│     stability, not recall. Solidifies the boundary for multi-vendor.    │
│ key downside  Blind to correlated incumbent blind spots (mitig. via     │
│               explicit expectation scoping: fix stability, then recall) │
╰─────────────────────────────────────────────────────────────────────────╯
```

`▶ recommend [1] k=3 incumbent fact-check · confidence 95%`

**Decision Path:** Path A. Candidate [1] overwhelmingly dominates for immediate action. The foundational requirement for any multi-vendor recall addition or soundness routing is a stable baseline gate. Per §1.1 of the evaluation doc, the promotion-to-🔴 gate's J_self is currently ~0.2; running multi-layered tests (Candidate 11) or designing complex auxiliary channels (Candidate 3) before locking down this extreme noise floor is an architectural error. Candidates 3 and 4 are highly viable fast-follows, but 1 must be prioritized first. (No native `AskUserQuestion` is issued).

---

### 5. Document (Inline Decision Record)

**Goal:** Select the highest-leverage next action to improve code-review pipeline accuracy and stability.
**Project state:** headless evaluation standalone · unblocked.
**Task status:** complete (decision recorded inline).

**Context:**
The living synthesis of the code-review skill (2026-07-30) reveals the pipeline detects effectively but tiers defectively. The largest observed fault line is the single-sample `code-fact-check`, which acts as a binary coin flip for promoting real issues to blocking (🔴) status, leading to severe under-calling and unstable promotion rates. Simultaneous parallel issues exist with soundness escalations and "Confirmed Good" false attestations.

**Options considered:**
Implementing a standalone 20-claim variance measurement, adding a second OpenRouter vendor immediately, running a dedicated divergent design on soundness logic, requiring failing tests, and eliminating tiers entirely.

**Decision and rationale:**
Implement k=3 `code-fact-check` incumbent sampling with max-severity aggregation immediately (Candidate 1).
§1.1 explicitly names the instability of the fact-check gate as the sole bottleneck for 🔴 escalations (J_self 0.14-0.25). Before integrating secondary vendors to improve recall (which forcibly introduces OpenRouter staging complexities and latency limits into the prod ring, per §5.0), the incumbent baseline's mechanical reliability must be secured. This represents the cheapest, highest-leverage intervention available. `See alternatives considered →`

**Pruned candidates and why:**
*How to read: Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.*
- `Prior pruning grep: not runnable in this setting`
- `[7, 9]:` Fails to address explicitly documented pipeline gaps and breaks underlying system intent.
- `[10]:` Requires mass training/prompting against historical accepted PRs, directly violating §5.4 Trap 2.
- `[8, 12]:` Demanding empirical code-execution tests or Opus+Sonnet consensus sharply worsens the core "under-calling" failure mode.
- `[2]:` Injecting multi-vendor calls into a highly unstable gate without resolving the baseline noise first invites debugging chaos.
- `[11]:` OpenRouter CI integration requires significantly more engineering effort and threatens CI scale limits; sequenced for *after* pipeline stabilization.

**Stress-test mitigations:**
- *How to read: Boring alternative mitigation — Candidate 1.* Inserted the 20-claim offline variance test (Candidate 6) as a gating precondition script before hardcoding k=3 into the CI orchestrator to confirm k=2 is insufficient.
- *How to read: Revealed preferences mitigation — Candidate 3.* Recorded a strict architectural requirement that the upcoming soundness DD must structurally exclude heuristic/semantic-similarity matching derived from historical rubrics.
- *How to read: Failure-driven mitigation — Candidate 4.* Mandates prompt checks on future Confirmed-Good synthesis steps to structurally limit answers to exact quoted line-matches.

**Consequences:**
- *Easier:* Establishing a deterministic noise floor, making future cross-model sweep comparisons (like Sol and Kimi) mathematically sound.
- *Harder:* Triples token consumption specifically on the single `code-fact-check` sub-agent path. Requires careful orchestration handling so sequential runs don't artificially bottleneck the review loop.

**Revisit triggers:**
*How to read: Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes.*
- if the initial 20-claim offline variance test shows J_self agreement consistently >90% (obviating k=3 scaling).
- if the J_self rate of the new k=3 cluster remains beneath 0.50 after two weeks in production.
- if API rate limits triggered by the 3x token fan-out stall the internal CI loop on >5% of pull requests.