# DD — reduce token usage in review-fix cycles

**Goal**: choose token-reduction levers for the code-review loop (fact-check + critics +
rubric, looped to 0R+0A), beyond what decision 031 (T + k=1 + 2-clean) already banked.
**Project state**: standalone follow-up to 031; grounded in E1/E2/E3 measurements · not blocked.
**Task status**: in-progress (DD drafted, autonomous Path C — no live consult).

## Measured cost model (E1/E3), the ground truth this DD optimizes against

A full pass ≈ **0.8–1.1M tokens, findings-independent** (E1). Per-pass split:
- **fact-check** k=3 ~290–400k (30–45%) — already cut to k=1 (~⅔ off) by 031.
- **critics** 5 agents ~350–550k (**the largest block, untouched so far**).
- **rubric** synthesis ~90–160k.
The shared **diff + enclosing-file context is re-sent to ~8 agents per pass** (3 fc + 5 critics),
every pass. Loop length is set by marginal-red variance (031's T fixes that).

## 1. Diverge (pre-generation grep run; revivals/carries noted)

Prior-pruning grep over `docs/decisions/*.md` for token/cost/critic/context/cache surfaced
four reusable items — three *reclassified-as-loop-only* (which is exactly this DD's scope):

1. **Critic diff-shape + evidence gating** — enforce/tighten the existing Stage-1.5 gate so a
   critic with no domain signal in the diff or fact-check is skipped. [procedural]
2. **Cascade / model-tiering critics** — cheap model (sonnet-role-prompt) first, opus only to
   re-verify flagged findings or on later passes. [revived from 030 [5] cascade — *why now
   different*: this is the production loop, not a benchmark arm; the "escalation leg is agentic
   → fails H2" objection was benchmark-confound-specific]. [technical]
3. **Prompt-cache the shared context** — cache the diff + enclosing-file prefix re-sent to all
   ~8 agents/pass. [revived from 021/030 [13] — *why now different*: 030 pruned it as a
   benchmark *arm* (provider-specific breaks byte-identical cross-model) but explicitly
   reclassified it as a "loop-only optimization"; this DD IS that loop]. [technical/cross-cutting]
4. **First-red short-circuit** — abort a red-gated pass once a behavioral red is confirmed
   (another pass is coming regardless), skipping the remaining critics; collect the full amber
   inventory only on the final otherwise-clean pass. [time-shifted/procedural]
5. **Static-analysis pre-filter** — run eslint + tsc + the existing test suite before the LLM
   panel to strip mechanical findings. [revived from 030 [4] — *why now different*: the review
   target (meta-formalism-copilot) is a code-heavy TS repo with eslint/tsc already wired, not
   the bash/markdown repo 030 deferred it for]. [technical]
6. **Cheaper/templated rubric synthesis** — a cheaper model or more mechanical merge for the
   ~120–160k rubric stage. [technical]
7. **Omnibus single-critic** — one agent covers all domains in one call. [naive]. [technical]
8. **Carry-forward / delta fact-check** — [revived+already-tested from 030 [9]; E3 measured
   ~0 carry on both csp and corpus — coupling/one-hop-closure kills it]. [pruned-with-evidence]
9. **On-demand file read** instead of enclosing-file inlining. [carried from 021 [6]/[14]:
   per-provider tool plumbing + model/retrieval nondeterminism]. [pruned]
10. **Do nothing** — accept current cost (baseline is already T + k=1 + 2-clean). [reframe]
11. **Ideal-if-free: persistent stateful review session** holding the repo in context across
    passes (statelessly unachievable; approximated by #3). [reframe/ideal]
12. **Critic scope-restriction to changed files across passes** — attention-restriction for
    critics. [same coupling root as #8, worse: critics are more cross-cutting]. [pruned]

Health check: dimensional spread OK — critic-set (1,2,7,12), context-transport (3,9,11),
pipeline-flow (4,5), stage-cost (6), fact-check (8). Do-nothing (10), ideal (11), naive (7)
present. No unaddressed clustering (the critic-stage cluster is intentional — it's the largest,
least-optimized cost block).

## 2. Diagnose — constraints

- **H1 (hard)** no behavioral-red recall regression vs the 031 baseline (T+k=1+2-clean).
  `success:` on the csp + corpus canon states, the reduced pipeline surfaces every behavioral
  red the baseline corpus surfaced (spot-checkable against the existing per-replicate reports).
- **H2 (hard)** preserves 0R+0A semantics, T tiering, and the 2-clean second-independent-draw
  property. `success:` rubric still produced under the same tier mapping; no lever removes the
  second pre-merge draw that makes k=1 safe (031).
- **H3 (hard)** delivers ≥15% measured pass-token reduction (else not worth building).
  `success:` measured token delta on a canon pass ≥15% vs the 031 baseline pass.
- **H4 (hard)** does not break the cross-model sweep's byte-identical-prompt confound control
  (021/030). `success:` the sweep path's prompts stay byte-identical across models; any
  provider-specific lever (caching) is off the sweep path, production-loop-only.
- Soft: preserve critic independence/parallelism (E1: tiers find disjoint reds); preserve
  determinism; low build complexity; compose with T/k1/2-clean.

## 3. Match & prune

| # | lever | H1 recall | H2 semantics | H3 ≥15% | H4 sweep-safe | verdict |
|---|---|---|---|---|---|---|
| 3 | prompt-cache shared context | ✓ (same content) | ✓ | ✓ (input dominates, ×8 agents) | ✓ (loop-only, off sweep) | **survive** |
| 1 | critic gating (Stage 1.5) | ✓ (evidence-gated) | ✓ | ~ (instance-dependent) | ✓ | **survive** |
| 4 | first-red short-circuit | ✓ (red⇒repass anyway) | ✓ (ambers on final clean pass) | ~ (red-gated passes only) | ✓ | **survive** |
| 2 | cascade / model-tiering | ~ (cheap-model recall risk) | ✓ | ✓ | ✓ | **survive (as experiment)** |
| 5 | static-analysis pre-filter | ✓ | ✓ | ~ (mechanical share small) | ~ (per-repo) | survive (complement) |
| 6 | cheaper rubric | ~ (tiering least-stable part) | ~ | ✗ (~15% ceiling, risky) | ✓ | prune |
| 7 | omnibus single-critic | ⚠ (loses independent draws) | ✓ | ✓ | ✓ | prune (⚠ H1) |
| 8 | carry-forward fact-check | ⚠ (E3: ~0 on both instances) | ✓ | ✗ (measured 0) | ✓ | prune (evidence) |
| 9 | on-demand file read | ~ | ✓ | ~ | ✗ (tool plumbing/nondet) | prune (H4) |
| 10 | do nothing | — | — | ✗ | — | prune (H3) |
| 11 | persistent session | ✓ | ✓ | ✓ if free | ✗ (stateless) | prune → folds into #3 |
| 12 | critic scope-restriction | ⚠ (coupling, worse than #8) | ✓ | ✗ | ✓ | prune |

**Key structural finding: the survivors are complementary, not competing.** #3 (transport),
#1 (which critics run), #4 (when a pass stops), #2 (which model) act on orthogonal axes — so
the decision is a *portfolio + sequencing*, not a single pick.

## 4. Tradeoff + decision (survivors #3, #1, #4, #2; #5 complement)

Effort/risk/coverage and the falsifiable hypotheses are in the decision block (rendered to
console). Stress-tests applied:
- *Boring alternative* on the bundle → prompt-caching alone (#3) is the 80%-safe boring win;
  it needs no logic change to the pipeline, only transport. Adopt it first and independently.
- *Invert the thesis* on #2 (argue to adopt tiering now) → the invert surfaces that E1's
  "sonnet-role-prompt acceptable" was measured on *single-pass* recall, never in a loop; the
  cheap-model recall risk is unquantified in the loop → #2 stays an experiment, not a default.
- *Failure-driven* on #4 → new failure mode: short-circuiting hides the amber inventory for
  that pass; mitigation folded in — short-circuit only red-gated passes, always run the full
  panel on the final otherwise-clean pass (where 0A is actually adjudicated).

**Decision (Path C — autonomous, no live consult): adopt the complementary safe bundle now —
#3 prompt-caching, #1 critic gating, #4 first-red short-circuit — and queue #2 model-tiering
as the next measured arm (gated on a recall check like k=1 was). #5 static pre-filter is a
low-priority complement.** Rationale: the three adopted levers are orthogonal, each H1-safe,
and hit the two biggest cost blocks (context transport re-sent ×8; the untouched critic
block). #2 is the only one with real recall risk, so it earns an experiment, not a default —
exactly how k=1 was handled.

## 5. → decision record 032
