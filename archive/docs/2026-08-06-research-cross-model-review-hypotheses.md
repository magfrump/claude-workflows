# Cross-model review: hypotheses, cost/identification tradeoffs, and the OpenRouter harness

**Date:** 2026-07-29 · **Status:** hypotheses + harness ready; H1/H2 partially answered in-session
**Companion:** `experiment-results-code-review-2026-07-29.md` (Results 1–9)
**Harness:** `scripts/cross-model-review.py`

---

## 0. The reframe that motivates this

Result 7/8 established a tier gradient: opus-generalist found validated blocking defects
that sonnet/haiku-generalist missed 0/4, and the role-skill scaffold closed most of that
gap for sonnet. The natural next inference — and the one the user named — is that **the
gradient does not stop at opus.** If opus sees things sonnet cannot, the same logic says
some class of real defects is visible to fable, or to a non-Claude frontier model, and
invisible to opus.

That inference is not symmetric-by-assumption, and it is testable. Result 9 (fable)
already provides the first data point, and it came out on the "yes" side. Everything
below is designed to establish whether that generalizes and whether it is worth paying
for.

**Why this matters more than the usual ensembling question:** the repo's autonomous loop
gates on `CODE_REVIEW_RED`. A defect class systematically invisible to the gating model is
not merely missed — it is *certified absent*. Blind spots in a gate are worse than blind
spots in an advisor (see the false-attestation row in the Result 8 decision table).

## 1. Hypotheses

Each states the claim, the discriminating measurement, what would falsify it, and what
decision changes on the answer.

### H1 — Capability-ordering is preserved but not total (partially answered: TRUE so far)

**Claim.** Model tiers are ordered on *recall of validated defects* (haiku < sonnet <
opus ≤ fable), but the ordering is not total: each tier finds some real issues the tier
above misses, so `union(tiers) > best single tier`.

**Status: supported in-session.** Fable independently derived the ND2 blocking mechanism
(mood grant on interrupted song → creature becomes *more* approachable) that opus found in
only 1/2 replicates, and both fable MD1 runs flagged the pdf.js `worker-src` break that
only one of two opus runs caught. Meanwhile opus found ND1 issues fable did not.

**Falsifier.** A model's finding set being a strict subset of the next tier's across all
diffs. Not observed.

**Decision.** If non-total ordering holds at the frontier, the aggregation argument stops
being about variance reduction (tracker Thread 1) and becomes about **coverage of
disjoint blind spots** — a much stronger case for multi-model, and one SWR-Bench's
same-family comparison could not have detected.

### H2 — Cross-*vendor* J is lower than cross-*tier* J, which is lower than J_self

**Claim.** `J_self > J_cross-tier(same vendor) > J_cross-vendor`. Training-data and
RLHF-objective differences produce more decorrelated error than parameter-count
differences do.

**Measurement.** The harness's `overlap.json`, same diff, ≥2 replicates each, across
`anthropic/*`, `openai/*`, `google/*`, `deepseek/*`, `qwen/*`.

**Why this is the load-bearing experiment.** SWR-Bench's headline (Multi-Agg ≈ Self-Agg)
is what deflated the repo's founding premise. But its "different LLMs" were a narrow set,
and *this* repo's critics are all one model. If cross-vendor J is materially below
cross-tier J, SWR-Bench's equivalence result does not transfer to a genuinely
heterogeneous panel, and the founding premise is partially rehabilitated — on evidence
the paper never gathered.

**Falsifier.** `J_cross-vendor ≈ J_self` → vendor identity is noise; buy the cheapest
adequate model and resample. That would be a clean, money-saving negative result.

### H3 — Blind spots are *domain-structured*, not random

**Claim.** Misses cluster by defect type, and the clusters differ by model family — e.g.
one family reliably catches serialization/trust-boundary defects while missing
state-machine invariant violations, and another the reverse.

**Measurement.** Tag every adjudicated finding with a defect taxonomy (trust-boundary /
state-invariant / resource-lifecycle / API-contract / doc-drift / cross-file-interaction)
and build a model × class recall matrix. Needs ≥10 diffs to be readable.

**Weak in-session signal.** Haiku+skill *detected* the ND3 boundary issue and then
declined to report it; sonnet-generalist missed it entirely. Those are different failure
modes (judgment vs. detection) and imply the matrix should record both.

**Decision.** A structured matrix converts "run everything" into "run the two models whose
blind spots are complementary for this diff's shape" — the cheap version of multi-model.

### H4 — Cross-file/interaction defects are above the single-pass ceiling for every model

**Claim.** Defects requiring a consumer in another module (MD1 R1: `connect-src 'self'`
breaking `exportGraph.ts`'s `fetch(dataUrl)`) are missed by every single-pass reviewer at
every tier, and are recovered only by pipelines with retrieval or multi-critic breadth.

**Status: supported, 0/6 recovery** across sonnet/opus/fable on MD1 R1 (opus and fable
both found *adjacent* worker-src/CSP issues but not R1 itself).

**Decision.** If true, **no amount of model spend fixes this class** — it is a context
problem (tracker Thread 2's static context pack), not a model problem. This is the single
most budget-relevant hypothesis here: it identifies where money *doesn't* help.

### H5 — Small models are net-negative as gates, not merely weaker

**Claim.** Below some capability threshold a reviewer's output has negative expected
value in a gate, because a false "clean" verdict carries assurance weight.

**Status: supported.** Haiku's only two generalist findings across 6 runs were both false
positives (0/2 precision), and its MD1 clean verdict explicitly praised the matcher regex
sonnet flagged as defective.

**Decision.** Already actioned in the Result 8 decision table. Generalizing it: any
OpenRouter model added to a panel must clear a precision floor before its "no findings"
is allowed to contribute to a pass verdict.

### H6 — A cheap heterogeneous panel beats one expensive homogeneous reviewer at equal cost

**Claim.** At fixed dollars, `k` mid-tier models from `k` different vendors, unioned, has
higher validated-defect recall than `n` replicates of the single best model.

**Measurement.** Cost-normalize: pick a budget, enumerate compositions, score recall
against the validated ground-truth set. This is the practical decision and it depends on
H1+H2 both holding.

### H7 — The judge/adjudicator has its own blind spot, correlated with the reviewer

**Claim.** Using model X to adjudicate model X's findings inflates precision, and
doc-deferent adjudication systematically under-counts.

**Status: partially supported, and already burned us.** The fresh-findings adjudicator
ruled F18 invalid because a docstring called the behavior intentional — while the next
commit in history is the human fixing exactly that as a blocking finding.

**Decision.** Adjudicators must be a different model from the reviewer, and the harness
pins `--judge` and stamps the judge id into every row so a judge swap can't silently
invalidate a series.

## 2. Cost / identification tradeoffs

The core tension: **the configurations that best identify blind spots are not the ones you
would deploy.** Identification wants many models × many replicates on a fixed small diff
set; deployment wants the cheapest panel that clears a recall bar.

### Cost structure (list, per MTok in/out; verify against OpenRouter's live `/models`)

| Class | Examples | Rough in/out | Role in a panel |
|---|---|---|---|
| Frontier | Opus 5, Fable 5, GPT-5-class, Gemini-3-Pro-class | $5–15 / $25–75 | Detection of hard defects; adjudication |
| Mid | Sonnet 5, GPT-5-mini-class, Gemini-Flash-class | $1–3 / $5–15 | Panel breadth; role-scaffolded gates |
| Cheap/OSS | DeepSeek, Qwen-2.5-72B, Llama-class | $0.1–0.6 / $0.3–2 | Decorrelation candidates *if* they clear H5's floor |

Harness runs are diff-inline and toolless, so cost is predictable: one review ≈
(diff_tokens + ~400 prompt) in, ~1–2k out. The ND3 diff (~770 lines) is ≈ 10k input →
frontier ≈ $0.10–0.20/run, cheap ≈ $0.005/run. **A 6-model × 3-replicate sweep on 3 diffs
is ~$5–15 total.** The judge calls dominate at high finding counts: pairwise stage-2 is
O(n²) per pair, which is why stage-1 line-overlap pre-filtering is mandatory (it cuts
typical candidate pairs by ~10×).

### The identification tradeoffs, stated explicitly

1. **Replicates vs. models at fixed budget.** You cannot distinguish "model B found
   something A missed" from "sampling noise" without ≥2–3 replicates per model. With 2 you
   can only detect *consistent* blind spots; with 3 you get a usable per-model detection
   rate. Recommendation: 3 replicates, fewer models, rather than 1 replicate across many —
   single-replicate cross-model comparisons are uninterpretable and this session has
   already shown replicate disagreement is large (opus J_self 0.15–0.38 on the generalist
   prompt).
2. **Toolless vs. agentic.** Toolless is cheap, reproducible, and comparable across
   vendors; agentic is what you actually run. They differ — H4's cross-file class is
   likely *only* reachable agentically. Measure blind spots toolless (clean identification)
   then confirm the top-2 composition agentically (external validity). Don't mix them in
   one number.
3. **Ground truth is the real budget.** Model calls are ~$15; adjudicating a few hundred
   fresh findings is the expensive part, and Result 6 showed retrospective corpora are
   acceptance-saturated. Prefer diffs with *validated* historical defects (the ND/MD set)
   so recall is scorable without new adjudication; spend adjudication only on the
   novel-findings tail.
4. **Adding a model has superlinear analysis cost.** k models → k(k−1)/2 cross pairs, each
   needing stage-2 judging. Six models is ~15 pairs; ten is 45. Cap the sweep at 5–6
   vendors chosen for *expected decorrelation* (one per training lineage) rather than
   sampling the leaderboard.
5. **Precision floor before panel membership (H5).** A model that adds recall but drops
   precision below the human triage tolerance costs attention, which is the scarce
   resource. Gate membership on measured precision, not on benchmark reputation.

## 3. The harness

`scripts/cross-model-review.py` — standalone, no agent in the loop.

- **Input:** `--repo` + `--range` (explicit SHAs → replayable on merged history),
  `--models` (OpenRouter ids), `--replicates`.
- **Prompt:** byte-identical across models, diff pasted inline, no tools — matching the
  session's headless arm so numbers compose with what's already measured.
- **Output:** `findings.jsonl` (one row per run: parsed findings, raw text, token usage,
  latency, prompt SHA) + `overlap.json` (J_self per model, J_cross per model pair).
- **Matching:** stage-1 deterministic (basename + line-range overlap ±slack — basename
  because Result 6 found ~85% of citations use shorthand), stage-2 pinned judge model,
  judge id stamped in output.
- **Guards:** `--max-usd` projects spend from the live pricing endpoint and aborts before
  sending; retries with backoff; `--analyze-only` recomputes overlap without re-billing;
  degrades to stage-1-only overlap when no API key is present.

Note it deliberately does *not* set temperature — several providers reject or remap it,
and "as-deployed" variance is the quantity of interest.

### Suggested first sweep

```bash
export OPENROUTER_API_KEY=...
scripts/cross-model-review.py \
  --repo external/nature_photographer --range '319f229~1..319f229' \
  --models anthropic/claude-opus-4.5 openai/gpt-5.1 google/gemini-3-pro \
           deepseek/deepseek-v3.2 qwen/qwen3-max \
  --replicates 3 --judge anthropic/claude-sonnet-4.5 \
  --max-usd 10 --out runs/cross-model/nd3
```

ND3 first because its ground truth is the strongest in the corpus: a validated blocking
defect (unvalidated deserialize) whose fix is the next commit, and a known
tier-discriminating profile (opus 2/2, sonnet 0/2, haiku 0/2 generalist). Any model that
finds it is at least opus-class *on this defect type*; any that misses it has a blind spot
we have already characterized in three other models. Verify the model ids against
OpenRouter's `/models` before running — ids drift.
