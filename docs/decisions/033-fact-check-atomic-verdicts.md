# 033 — Fact-check verdicts attach to atomic claims (compound-claim decomposition)

**Date**: 2026-08-15 · **Status**: adopted, pending validation addendum (k=2 opus
re-run on mfc-deploy) · **Method**: divergent-design (Path C — autonomous) ·
**Working doc**: `docs/working/dd-fact-check-verdict-granularity.md` ·
**Follows**: [031](031-review-loop-tier-and-factcheck-policy.md) (tier scoping, k=1),
the 2026-08-15 fact-check model pin (`docs/working/fc-model-sweep-results-2026-08-15.md`) ·
**Grounded in**: fc-model-sweep, 12 replicates × 3 models on canon ground truth.

## Context

The fc-model-sweep exposed a spec bug, not a model bug: all three models, near-
unanimously (11/12), verdicted known-bad doc claims (canon N10, dep-R1) **Mostly
accurate** while stating the Incorrect-grade refutation in full in their own prose.
Every miscalibrated row was a **compound claim** — a refuted mechanism atom fused to
a true conclusion atom — and the one-verdict-per-claim schema forced the models to
verdict the molecule by its conclusion. Atomic claims (csp-R2/A2/A3) were verdicted
Incorrect 6/6. Downstream, Mostly accurate cannot fire the Fact-Check Gate, cannot
corroborate an Escalation-Rule tier promotion, and cannot reach 031's
binding-contract 🔴 — so the class silently loses its blocking authority. The user's
framing: a claim being "mostly true" when mostly is not enough for the circumstance.

## Decision

**Verdicts attach to atomic checkable claims, not to sentences.** Four coordinated
changes:

1. **Split-on-divergence rule** (`skills/code-fact-check/SKILL.md`): a compound claim
   whose checkable parts would earn different verdicts MUST be split into sub-claims
   (`## Claim Na:` / `## Claim Nb:`), each carrying the full five mandatory fields.
   Never split when the parts agree (anti-pedantry guard).
2. **Intra-claim most-severe-wins**: where splitting is impractical, the compound
   takes its most severe part's verdict, naming the part that carries it. A
   directionally-right conclusion never outweighs a refuted mechanism.
3. **Definition tightening**: *Mostly accurate* now requires mechanism AND conclusion
   both right (merely imprecise); a stated mechanism the code refutes is *Incorrect*
   (or *Stale*) for that part regardless of the conclusion. Worked example added
   (the N10 shape: "when X is unset the route falls back to a mock" vs code that
   substitutes a default URL).
4. **Clustering amendment** (`skills/code-review/SKILL.md` merge step): one
   replicate's compound claim clusters with another's sub-claims of it;
   most-severe-wins applies across the cluster.

**Rejected**: a new severity/materiality field or `Misleading` verdict (the user's
initial instinct, DD option #4/#3) — a per-claim materiality label is a fresh
context-dependent judgment ("unset→mock" is harmless on Vercel, wrong in dev) and
re-imports exactly the marginal-verdict instability 031 spent ~1M tokens/pass to
remove, at the highest consumer-churn cost of any option. **Queued as fallback**: if
a later canon measurement shows fact-check-shaped *omission* hazards (true claim,
dangerous omission — no refuted atom for decomposition to catch), run the
materiality-axis experiment gated on a recall check, as k=1 and the opus pin were.

## Why this is the stable-quantity fix (falsifiable)

The refutation prose was present in 12/12 replicate sections; the MA label in 11/12.
The spec change keys blocking on the stable quantity (a specific atom the replicate
itself proved refuted) and deletes the unstable one (the holistic molecule-level
Inc↔MA judgment) — the same direction as 031, not a reversal. Prediction: Result-14a
verdict flips drop on compound claims. Falsifier for the validation run: amended-
skill opus replicates on mfc-deploy fail to produce Incorrect on the N10/dep-R1
mechanism atoms, or inflate dep-R2's true conclusion atom to Incorrect.

## Consumer-churn ledger (H2)

Unchanged: verdict enum, five mandatory fields, bats format suite (sub-claims are
claims; `Na`/`Nb` still match `## Claim N` prefixes — verified against the suite),
Gate 1h parser, Fact-Check Gate, Stage-1.5, Unified Severity Mapping, escalation
rule. Changed: `code-fact-check/SKILL.md` (granularity rule + definitions + example),
`code-review/SKILL.md` (one clustering paragraph). The 2026-08-15 opus pin is
unaffected in direction (spec change is model-independent; sonnet's disqualifying
attestations were a different failure class untouched by this decision).

## Consequences

- Fact-check reports may carry more, smaller claims on doc-heavy diffs; each atom is
  closer to a clean Verified-or-Incorrect call.
- Binding-contract misdocumentation (dep-R1/N10 class) regains access to the gate,
  the escalation-corroboration channel, and 031's 🔴 carve-out via honest Incorrect
  atoms — without widening the band for benign qualifier-misses.
- Behavior-affecting skill-prose change ⇒ lands before A8 (standing sequencing
  rule), which remains the next measurement.
