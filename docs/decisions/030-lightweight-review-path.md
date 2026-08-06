# 030 — Lightweight code review path for looping and benchmarking

- **Goal**: Choose a lightweight code-review path cheap enough for iteration loops and
  benchmark arms, as the alternative to the deep agentic `code-review` orchestrator
  (~$14.6/instance mean).
- **Project state**: Follows 021 (Stage-1 context harness built+validated) and 029
  (SWRBench-fork v2 judge spine) · feeds the SWRBench fork's arm configs and the local
  review-fix loop · not blocked.
- **Task status**: complete (decision made; schema pass and arm runs are follow-up work)

## Context

The deep agentic review path (the `code-review` skill orchestrating fact-check + critic
subagents) is the production-quality reviewer but costs ~$14.6/instance mean — prohibitive
for review-fix looping and for benchmarking, where a 30-instance sweep must run repeatedly
per configuration. Decision 021 already built a cheap portable alternative for a narrower
purpose (the cross-model sweep): `scripts/cross-model-review.py --context-base` — one
chat-completions call over the labelled full-branch diff plus whole enclosing files, no
tools, byte-identical prompts, validated 2026-07-31 (median $0.226/call, sweep $3.53, 0/8
reproduction of the two known FP classes). This DD (working doc
`docs/working/dd-lightweight-review-path.md`) decided whether that harness, or some other
mechanism, becomes *the* lightweight path, and which cheap variants are worth testing.

## Options considered

14 candidates across context shape, model choice, sampling, output contract, escalation,
scope, non-LLM gates, and cost plumbing (working doc §1). Scored against 4 hard
constraints — H1 cost (median ≤ $0.35/call, 30-instance sweep ≤ $15), H2
benchmark-pluggable/confound-controlled (headless chat-completions, byte-identical
prompts), H3 no sibling-commit FP regression (D3/D4 re-run stays 0/8), H4 judge-parseable
structured output. Survivors: [0] Stage-1 harness promoted, [3] small-model arm, [7] k=3
consensus, [8] rubric single call.

## Decision and rationale

**Chosen: [0] — promote the 021 Stage-1 harness to be the named lightweight review path**,
with one ~2 h addition: a JSON findings schema (file, line, severity, claim) in the prompt
plus a parse-validate step, so output is v2-judge-parseable (H4). One config, two
consumers: the SWRBench-fork benchmark arm and the local review-fix loop (k=1 in loops).

**Queued as cheap benchmark arms** (the "ideas to test cheaply"), ranked by the 029 v2
judge once its kappa gate passes:

1. **[3] small-model arm** (~1 h): same config pinned to a Haiku/Sol-class model — the
   cost floor. Hypothesis: retains ≥60% of [0]'s verified-bug recall at ≤⅓ cost;
   counter-evidence = recall <40% or a new FP class in the D3/D4 check.
2. **[7] k=3 consensus** (~1 h, k already supported): keep findings ≥2 samples agree on.
   Hypothesis: cuts FP-class findings ≥30% vs k=1; counter-evidence = <15% reduction or
   consensus-amplified FPs (the Result-5 lesson) reappearing.
3. **[8] rubric/checklist single call** (~4 h): fixed checklist with schema-native output.
   Hypothesis: beats [0] on judged precision on the same 10 instances; counter-evidence =
   no precision gain while missing ≥2 verified bugs [0] caught.

[0]'s own hypothesis: *judge-parseable findings on a 10-instance dry run at median ≤
$0.35/call within 1 week; counter-evidence = >10% schema parse failures or median above
the band.*

Rationale: [0] is already built, already validated against the known FP classes, sits
~40× under the agentic path's cost, and dominates every rival on effort+risk with equal
hard-constraint coverage — the rivals are properly *arms on top of it*, not alternatives.
The deep agentic critic is **not retired**: it remains the production re-verify authority
(021 Stage 3); the lightweight path generates candidate findings and benchmark signal,
never the final production verdict.

See alternatives considered → **Pruned candidates and why** below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in
adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[1 do-nothing]: fails H1/H4 — the cost problem is the ask.` `[4 static-analysis pre-filter]: deferred — per-language setup vs. a mostly-bash/markdown repo; revive in a code-heavy consumer repo.` `[5 cascade escalation]: escalation leg is agentic → fails H2 for benchmarking; its trigger logic is recoverable later as a loop-only policy over [0].` `[6 trimmed orchestrator]: still multi-agent ~$2–5, Claude-Code-bound, non-deterministic, freeform output — fails H1/H2/H4.` `[9 delta review]: stateful → not per-instance reproducible (H2); reclassified as a loop-only optimization.` `[11 no-LLM gate]: emits nothing a judge can score (H4); folded into [4].` `[13 prompt-cache layout]: provider-specific cost lever, not a path; reclassified as a loop-only optimization composing with the finding-churn mitigation.` `[10 ideal-if-free agentic multi-sample union]: [carried from 021-reviewer-context-management: discarded on cost/latency].` `[14 on-demand file read]: [carried from 021-reviewer-context-management: per-provider tool plumbing + model/retrieval confound].` `[12 paired-preference]: [carried from 029-code-review-benchmark-architecture: absorbed as screening layer — a comparator for path outputs, not a review path].` `[029 [8] executable eval / [11] expert panel]: [carried from 029-code-review-benchmark-architecture: cost].`

## Stress-test mitigations

- How to read: *Boring alternative* mitigation — demoted [8] rubric call from co-equal
  spine to benchmark arm; checklist-design effort isn't justified before the instrument
  shows [0]'s open-ended precision is actually deficient.
- How to read: *Invert the thesis* mitigation — arguing for staying on the deep path
  hardened the constraint that the agentic critic remains the production re-verify gate
  (021 Stage 3); recorded in Decision so the lightweight path is never read as replacing it.
- How to read: *Failure-driven* mitigation — surfaced loop-specific finding-churn
  (re-worded or oscillating findings across iterations); queued mitigation: pass prior
  iteration's findings in-context labelled "previously reported" (composes with the
  pruned prompt-cache lever [13]). Also re-affirmed 021's secret-screening trigger before
  pointing the harness at any non-operator-owned repo.

## Consequences

Easier: review-fix loops get a ~$0.23/call reviewer instead of ~$14.6; benchmark arms
become affordable to sweep repeatedly; the arm portfolio ([3]/[7]/[8]) gives the 029
instrument real configurations to rank; one config serves loop and benchmark. Harder: the
lightweight path has a known recall ceiling (no cross-file interaction bugs — MD1 R1
class stays with the agentic gate); a JSON-schema pass and parse-validation step must be
built and held stable; per-model FP re-validation duty for arm [3].

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt
re-evaluating this decision; grep here when context changes.

`if the 10-instance dry run shows >10% schema parse failures or median call cost > $0.35 ([0]'s counter-evidence).` `if the v2 judge ranks any arm ([3]/[7]/[8]) above [0] on WUS at comparable cost — promote that arm to the spine.` `if lightweight-arm verified recall < 40% of the agentic arm's on the benchmark — the loop reviewer is too blind to loop on; revisit [5] cascade.` `if loop finding-churn is observed ≥3 iterations on one branch despite the previously-reported label — build the delta-review [9] optimization.` `if the harness is pointed at a non-operator-owned repo — add the secret-screening pass first (021 trigger, restated).` `if the production agentic critic is retired — the re-verify authority disappears and this decision's Stage-3 dependence breaks (021 trigger, restated).`
