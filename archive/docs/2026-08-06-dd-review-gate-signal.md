# DD: what should an autonomous-loop review gate consume?

**Date:** 2026-07-30 · **Status:** diverge/diagnose/match complete; one candidate adopted, rest for human review
**Calling context:** standalone (follows the measurement program in `experiment-results-code-review-2026-07-29.md`)

## Problem statement

Gate 1h runs a full multi-critic pipeline — fact-check, N critics, synthesis, rubric — and
consumes **one integer**: the count of 🔴 rows. Everything else is discarded. Now that the
pipeline's properties have been measured, the question is what signal the gate *should*
take. This is a decision among competing designs with real tradeoffs, not open-ended
ideation: at least a dozen viable options differ on the precision/recall/cost axes.

## Prior pruning grep

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "review|model|gate|critic"`

One match, carried forward:

- **[017-polyglot-test-hermeticity, candidate 9] "code-review sub-critic as a gate"** —
  pruned there as *not a gate* (failed that decision's H5) but adopted as a complement,
  "the only mechanism with cross-project reach at zero cost." **Carried forward**: the
  prior reasoning was about a *sub-critic* being asked to enforce hermeticity, a different
  question from what an existing gate should consume. Not re-proposed as-is; its lesson —
  an LLM critic is a detector, not an enforcement primitive — becomes constraint H9 below.

## 1. Diverge — 15 candidates

| # | Candidate | One line |
|---|---|---|
| 0 | **Status quo** | Nonced red-count sentinel, fail-closed (as of `6b7b2eb`). |
| 1 | Red count + archived rubric | Status quo plus artifact retention (already landed). |
| 2 | Structured findings JSON | Reviewer emits a schema-constrained findings object; gate validates and counts. |
| 3 | Two-model **union** gate | opus + fable; reject if *either* reports red. Recall-favoring. |
| 4 | Two-model **intersection** gate | Reject only if *both* report red. Precision-favoring. |
| 5 | Executable-corroboration gate | A red finding blocks only if it comes with a currently-failing test. |
| 6 | Stability gate | Run the reviewer k times; block only on findings appearing in ≥2 runs. |
| 7 | High-band gate | Ignore rubric tiers; block on critic-native **High/Critical** severity only. |
| 8 | Adversarial verifier stage | BitsAI ReviewFilter: a refute-prompted pass drops findings before the gate. |
| 9 | Never block; queue for human | Gate always passes, red findings accumulate in a review queue. |
| 10 | Head/base delta gate | Block only on findings that don't reproduce at the merge base. |
| 11 | Weighted score | Composite over 🔴/🟡/🟢 counts against a threshold. |
| 12 | **No gate at all** | Review is advisory; tests and shellcheck are the only gates. |
| 13 | Gate reads the rubric file | Drop the stdout sentinel; parse the archived rubric artifact. |
| 14 | Context-pack escalation | Cross-file findings get a second pass with a retrieval pack, gated separately. |

Deliberately included: a do-nothing (0), two that feel wrong (4, 12), two unconventional
(6, 9).

## 2. Diagnose — constraints

**Hard (H):**

- **H1 No human at decision time.** The gate resolves headless, mid-loop.
- **H2 The branch is untrusted input.** It supplied the reviewer's skill file until
  `2112dcb`; it still supplies the diff, and its content flows into the verdict channel.
- **H3 Fail closed.** "No verdict" must not read as "approved" (fixed in `6b7b2eb`).
- **H4 Tier assignment is unstable.** Identical prompts produced Medium/Low/Low on the
  same issue (Result 1) — the 🟡/🟢 boundary is the *least* reliable part of the output,
  so nothing may key on it.
- **H5 Issue identity and High-band presence are stable.** Every finding any run rated
  High appeared in all runs of that diff (Result 1). This is what a gate *can* key on.
- **H6 Cross-file defects are above the single-pass ceiling.** 0/6 recovery across all
  tiers on MD1 R1 (Result 8b). No gate design can promise to catch this class.
- **H7 Cost multiplies.** Per task × per round. A 2× reviewer cost is a 2× loop cost.
- **H8 Most findings in this repo are not testable.** The corpus is dominated by
  cross-file terminology and doc drift; a test-corroboration requirement would discard
  most of it.
- **H9 An LLM critic is a detector, not an enforcement primitive** *(carried from 017)*.

**Soft (S):**

- **S1** Prefer mechanisms that also produce measurement data (the corpus is the
  bottleneck for every open question).
- **S2** Prefer decoupling reviewer from fixer.
- **S3** Prefer mechanism over prose. The override-log failure is the standing evidence
  that unenforced instructions don't execute.
- **S4** Rejected tasks cost a re-run; false rejections are not free even with no human.

## 3. Match — pruning

| # | Verdict | Reasoning |
|---|---|---|
| 0 | **superseded** | Baseline; improved by 1/13. |
| 1 | **adopted** (landed `6b7b2eb`) | Satisfies S1 at near-zero cost. Necessary, not sufficient. |
| 2 | ⚠ H7, S3 | Right shape (Thread 3's schema-constrained handoff) but a large change to the skill's output contract; the rubric is already a schema. Revisit if the rubric proves unparseable in practice. |
| 3 | **strong, deferred** | Directly supported by measured non-total ordering (fable found a 🔴 opus missed 2/2). Blocked on H7 (2× cost) and on being unvalidated *as a gate*. Best next experiment. |
| 4 | **pruned** | Inverts the evidence. Intersection discards exactly the disjoint blind-spot coverage that makes two models worth running; would have missed both models' unique reds. |
| 5 | fails **H8** | Would discard most of this repo's real findings. Correct for a code-heavy repo, wrong here. Keep as an *escalation* path, not the gate. |
| 6 | ⚠ **H7** | Principled (keys on H5's stable quantity) but k× cost on the most expensive gate. Cheaper approximation: 7. |
| 7 | **strong; unblocked** | Keys on the *stable* signal (H5) and avoids the unstable one (H4). Cheap. Its one blocker — critic-native severity being flattened into tiers by the rubric format — was removed in `923ffca`, which adds a `Severity` column carrying the source critic's level verbatim. Still deferred as a *gate*: no High-band data has been collected in the new format yet, so promoting it now would repeat the escalation-rule mistake of enforcing on n≈0. Ready to implement once a handful of rubrics carry the column. |
| 8 | ⚠ | At 86–89% measured raw precision there is little FP mass to remove; BitsAI's 17%→57% context does not exist here. Deprioritized in Result 5 already. |
| 9 | fails **H1/H3** | A queue with no human at decision time is a gate that never gates. |
| 10 | ⚠ H8, but **promising** | The deterministic FP eliminator from Thread 7. Same testability problem as 5, but as a *filter on the testable subset* it costs one test run and is pure precision gain. |
| 11 | fails **H4** | A weighted score is maximally exposed to the least stable input. |
| 12 | **pruned, but honestly** | The null hypothesis deserved a hearing: the gate has ~5 findings/run at 86–89% precision, and its blocking tier fires rarely. Rejected because blocking-tier precision measured 104/104 across four repos — when it fires, it is right. |
| 13 | **adopted (advisory form)** | Removes nothing security-wise on its own (the reviewer writes both artifacts), but the rubric is richer, already format-tested, and now archived. Cross-checking it against the sentinel costs nothing and detects a class of failure neither artifact detects alone. |
| 14 | **deferred** | The only candidate that addresses H6, and H6 is a real coverage hole. Needs the Thread 2 context pack, which does not exist. Highest-value *future* work. |

**Survivors:** [1] [13] adopted · [3] [7] [10] [14] deferred with rationale.

## 4. Decision

**Adopt candidate 13 in advisory form**: after the reviewer returns, parse the archived
rubric's 🔴 rows and compare that count to the nonced sentinel. Log agreement/disagreement
into the gate detail. **Do not make disagreement blocking yet.**

Why advisory rather than enforcing: this is the third change to Gate 1h today, and the
session's own finding is that the repo's failure mode is enforcing unvalidated mechanisms
(the escalation rule carried blocking authority on n≈5). Measure the disagreement rate
first; if it is near zero, promoting it to fail-closed is a one-line change with evidence
behind it. If it is not near zero, that is itself the most interesting result available —
it means the sentinel and the rubric disagree about what the review found.

**Recommended next, for human decision:** candidate 3 (two-model union gate) is the
best-supported unimplemented idea, and candidate 14 is the only one that touches the
cross-file blind spot.

**Update 2026-07-30 (`923ffca`):** candidate 7's prerequisite is done — the rubric now
carries a `Severity` column with the critic's native level, so the High band survives the
tier mapping. Nothing keys on it yet. The cheapest path to a decision on 7 is to let a few
rounds accumulate rubrics in the new format and then compare, per run, the High-band count
against the 🔴 count: if High-band presence is as stable as Result 1 suggests while tier
assignment is not, 7 is a strictly better gate input than the red count, at the same cost.
That comparison is a `grep` over archived rubrics — no new experiment needed, just
patience. The same archived-rubric corpus also answers the open question left by candidate
13's advisory form (what the sentinel/rubric disagreement rate actually is), so one waiting
period settles both.
