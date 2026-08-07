# Corpus pass-1 code-review, re-scored under decision 031 tier policy T

**Purpose:** Document the pass-1-under-T red load for the corpus second-instance arm run.
This is a **severity re-mapping only** of the already-produced E1 rubric
(`runs/review-arms/e1/corpus-dirty/code-review-rubric.md`, commit `2dc403e`) under the
tier policy T of `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`. **No review
was re-run**; the findings, evidence, and native severities are taken as produced.

**Tier policy T (031) applied:**
- (a) fact-check `Incorrect(high)` whose subject is a **comment/doc only** (code behaves
  correctly, reader misinformed) → 🟡, not 🔴.
- (b) fact-check `Incorrect` about an **immutable already-merged commit-message** claim →
  override log, never a tier.
- (unchanged) behavioral fact-check `Incorrect`, architecture **Structural**, security
  **Critical/High**, api **Breaking**, performance **Critical** → stay 🔴.

## Per-red re-mapping

| # | Domains / native severity | Re-map decision | T clause | Resulting tier |
|---|---------------------------|-----------------|----------|----------------|
| R1 | fc Incorrect(High) · arch **Structural** · sec Low · api Inconsistent | **keep 🔴** | unchanged (arch Structural). The fc-Incorrect subject (`paths.ts:18` "sole source of corpus paths") is contradicted by *actual code divergence* — two disjoint layouts, only the undocumented one written — i.e. code behaves wrongly, not a correct-code/misinformed-reader case. Clause (a) does not apply; red on Structural regardless. | 🔴 |
| R2 | arch **Structural** (no fact-check) | **keep 🔴** | unchanged (arch Structural). No fact-check present to demote. | 🔴 |
| R3 | arch **Structural** (+ fc corroboration) | **keep 🔴** | unchanged (arch Structural native severity). | 🔴 |
| R4 | fc **Incorrect(High)**, sole domain | **demote under T** | **(a)** — subject is the `opfsAdapter.ts:115` `writeFile` comment ("Pass a fresh ArrayBuffer view…"); code passes `bytes` unmodified and behaves correctly at S1. Only S1 consequence is a misinformed reader. Security-rationale carve-out does not bite: hazard is speculatively load-bearing only at a *future* S3, not a rationale a current change relies on. | 🟡 |

## T-adjusted counts

- **Original:** 🔴 4 (R1–R4) / 🟡 17 (A1–A17) / 🟢 13.
- **Under T:** 🔴 **3** (R1, R2, R3) / 🟡 **18** (A1–A17 + demoted R4) / 🟢 13.
- **Demoted:** R4 only (4R → 3R). No override-log routing triggered — no red on this
  instance is an immutable-commit-message claim (clause (b) inert here).
- **Verdict unchanged:** still 🔴 DOES NOT PASS — three genuine architecture-Structural
  reds remain, none of which T touches.

## Leverage of T on this instance vs csp

T's leverage on THIS instance is **low**: it demotes exactly one of four reds (R4, a
comment-only fact-check Incorrect) and does **not** flip the pass verdict — the instance
stays red on R1/R2/R3, all native architecture **Structural** findings that T leaves
untouched. Contrast **csp**, where T removed the *deciding* reds (the two marginal
comment/immutable-history reds were the sole blockers, so T flipped that arm to a clean
pass and collapsed the arm gap). Here the blocking reds are structural, not marginal, so T
changes the count but not the outcome.
