# 033 — Fact-check verdicts attach to atomic claims (compound-claim decomposition)

**Date**: 2026-08-15 · **Status**: adopted, validation PASSED (addendum below) ·
**Method**: divergent-design (Path C — autonomous) ·
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

## Validation addendum (2026-08-15, same session)

k=2 opus on mfc-deploy, amended skill, same brief
(`runs/review-arms/fc-model-sweep/mfc-deploy/opus-v033-r{1,2}.md`; ~95–98k
tokens/rep — no cost increase). **All pass criteria met:**

- **N10**: both reps spontaneously split the claim exactly as the worked example
  prescribes — Claim 4a "unset → mock" **Incorrect (High)** 2/2 (was 0/6 across the
  whole pre-033 sweep), 4b "unreachable → mock" Verified. The blocking-grade verdict
  now exists; the Fact-Check Gate fires.
- **dep-R1**: both reps split CLAUDE.md:77 — 6a (dev half) Verified, 6b (the
  `/tmp`-warm-container account of these writes) **Incorrect (Medium)** 2/2 (was MA
  4/6 + a Verified/Unverifiable split). Medium, not High, because the refutation
  rests partly on external platform knowledge — honest calibration; Incorrect at any
  confidence now corroborates escalation and the row reads as a defect, though the
  High-only gate stays unreached for platform-epistemics claims by design.
- **No benign inflation**: the Incorrect count rose from 1 to 4 per rep, and every
  new Incorrect is a target-class row (4a, 6b, the analytics-persistence atom, plus
  commit 1859488's already-Incorrect claim). Benign qualifier-miss rows (deploy-
  button target, required-env-var wording, README unset-row phrasing) stayed
  MA/Verified/Unverifiable. dep-R2's split (15a "written to local filesystem"
  Verified / 15b "does not persist across invocations" Incorrect-Medium) is judged
  correct, not inflation: the atom implies within-invocation persistence that never
  exists, and pre-033 opus-r2 already rated the row Incorrect (High) — post-033 is
  the better-calibrated of the two.
- **Format**: sub-claim headings (3a/3b, 4a/4b, 6a/6b, 13a/13b, 15a/15b, 17a/17b)
  used correctly, all five fields per sub-claim, splits only on verdict divergence;
  bats-compatible.

Residual observation: each rep split the CLAUDE.md instance of the unset-claim but
left its README twin (claim 12 / 13b) at MA — the merged-report clustering step is
what reconciles same-substance claims, and the Incorrect-High landed on the primary
instance in both reps, so no action; watch whether cross-location twins drift in
production merges.
