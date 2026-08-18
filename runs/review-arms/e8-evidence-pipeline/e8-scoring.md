# E8 evidence-discipline pipeline — scoring against the 56-row canon ledger

**Date:** 2026-08-18 · **Scorer:** scoring agent (anti-SWR-Bench: same-mechanism, not keyword overlap) ·
**Arm:** `feat/critic-evidence-discipline` code-review pipeline, fresh run over all 8 canon dirty
states with execution-enabled fact-check (executed-mode Stage-1 + Stage-2.5 submitted claims) ·
**Base:** 56-row ledger of 2026-08-17 (`docs/working/canon-issue-ledger.{csv,md}`)

## Headline

- **E8 recall: 47 / 54 = 87%** on the 56-row-ledger findable base.
- **0 confirmed false positives** (the E8 design's central precision claim holds).
- **0 clean false Confirmed-Goods**; **1 over-broad Confirmed-Good** (csp CG4) that functionally
  masks csp-R1 via a scope carve-out — the single notable precision blemish.
- Every historically diagnostic **false-attestation** row (deploy-N10, postfix-pf-A5) is now
  **caught with the fact-check explicitly refusing to attest safety** — the exact behavior the
  evidence-discipline redesign targeted.
- Every historically **pipeline-only** row inside the reviewed ranges (pf-R1 type-seam, D3, D4,
  D5, D6, fsc-A3, cor-A1) is **caught**.

### Findable denominator

56 ledger rows − **D1** (`4f018ab`) − **D2** (`4de2b00`) = **54**. D1/D2 are defects introduced by
*fix* commits that no E8 dirty-state cell reviewed, so they are excluded per the ledger's
findability rule (not charged as misses). N6, N16, N7 are **not in the 56** (N6/N16 candidates,
N7 refuted) and are excluded from the denominator; N16's partial catch is noted but uncounted.

## (a) Per-instance table

| Instance | Commit | Caught / findable | Notable catches | Misses |
|---|---|---|---|---|
| **csp** | d90d6bb | **7 / 10** | C4 matcher-prefix as a **RED** (flips the historical Confirmed-Good); csp-A2 Tailwind misattribution (**unfound by any prior arm at any rep**); N1 prefetch-no-CSP; A6 Node-runtime comment | **csp-R1** (exportGraph data: fetch — masked by CG4), **C1** dev-eval relaxation, **N15** img-src markdown images |
| **lean** | c95c9cb | **7 / 7** | N4+N5 as one **RED** (node-mode `unavailable` collapse + formalizeNode cascade); N3 removed-localhost-default as **RED**; N8 partialize sanitizer bypass; lean-R1 nine stale doc passages; lean-A1 dropped reason/detail | — |
| **hygiene** | f2f149b | **3 / 3** | hyg-A1 half-applied redaction as **RED**; N14 cache-poison/never-evict as **RED**; hyg-R1 SSE `{error,details}` drift | — |
| **secdeps** | 8bde50c | **4 / 5** | sec-R1 warn-exits-0 as **RED**; **N2 audit-gate-fails-green reproduced by execution** as **RED** (was fabricated-as-passing historically); C2 require/dynamic-import bypass; sec-A1 trust AST-selector gaps | **N9** .cjs lint crash (files-key gap noted at C3, crash mechanism unsurfaced) |
| **deploy** | 4329d6e | **3 / 3** | **N10 unset-LEAN_VERIFIER_URL as RED with executed ×2 refutation** (was FALSE-attested "Accurate" historically); dep-R1 CLAUDE.md `/tmp` mismatch; dep-R2 silent-write-fail mechanism | — (N16 partial via A5; not in 56) |
| **fscompat** | b64c1ca | **6 / 6** | D6 double-hashing (**explicitly labeled D6**, execution-verified) — pipeline-E1-only historically; fsc-A3 Vercel hit-rate collapse (deployment-model reasoning) — pipeline-only historically; fsc-R1 phantom README section; fsc-A1/A2/A4 | — |
| **corpus** | 2dc403e | **10 / 11** | **D3 rehydration seam as RED** (pipeline-E1-only historically); D4 false-ArrayBuffer comment; D5 write-race (A2 executed probe) + un-debounced (A3); N11 prod-enforceable flag (executed); N12/N13 uncaught-write / clobber cluster; cor-A1..A4 | **C3** optional-chaining build-inlining (flagged as unverifiable blocker at C5, mechanism not asserted) |
| **postfix** | 7f30210 | **7 / 9** | **pf-R1 type-seam root as RED** (PIPELINE-ONLY historically — every headless arm missed it); **pf-A5 Math.max RangeError caught with fact-check refusing to attest safe** (FALSE-attested historically); pf-A1 fail-open eval default; pf-A2 untested default branch; pf-A3 (folded into pf-A1); pf-A6 → pf-C1; pf-A8 optional-chaining half via pf-A6 | **pf-A4** ambient-NODE_ENV-in-default-param (purity framing not raised), **pf-A7** connect-src enumeration drift |

**Column sums:** caught 7+7+3+4+3+6+10+7 = **47**; findable 10+7+3+5+3+6+11+9 = **54**.

## (b) Overall recall — 47/54 = 87%

Findable = 54 (56 − D1 − D2, both fix-commit defects outside every E8 range). Caught = 47 by
same-mechanism matching to red/amber/consider rows or critic findings. Three of the 47 are
generous/same-mechanism folds rather than as-worded rubric rows (dep-R2 via the silent-write-fail
mechanism in A1/A6; pf-A3 folded into pf-A1's "caller-overridable exported param"; pf-A8 partial —
only the optional-chaining-mislabel half). Excluding those partials/folds gives a **firm floor of
~44/54 = 81%**. Primary figure: **47/54 = 87%**.

## (c) Comparison to the historical pipeline

| Process | Base | Recall |
|---|---|---|
| Pipeline **as operated** (~$117/sweep) | 56-row | 33/56 = **59%** (was 77% on the old 43-row base) |
| Pipeline **incl. E1 fresh re-runs** | 56-row | 39/56 = **70%** (was 91% on the old 43-row base) |
| **E8 evidence-discipline** | 56-row | **47/54 = 87%** |

The 77%/91% the ledger `.md` cites are **old 43-row-base** figures; rebased to the 56-row ledger
the same pipeline lands at **59% / 70%**. E8's **87%** on the harder 56-row base exceeds even the
pipeline-incl-E1 variant by **~17 points on the same base**. On E8's own 54-row findable set
(excluding D1/D2 which E8 never saw but the pipeline caught by reviewing fix commits),
pipeline-incl-E1 = 37/54 = 69% vs **E8 47/54 = 87%** — an apples-to-apples ~18-point margin, at a
fraction of the pipeline's per-sweep cost. E8 is the first single process to clear ~80% of the
living ledger; every prior process (pipeline included) topped out near 70%.

## (d) False-positive and false-Confirmed-Good counts

- **Confirmed false positives: 0.** Every affirmative red/amber/consider row across all 8 cells
  maps to a real ledger issue or a defensible advisory (auth/DoS surface, serverless-duration
  timeout, unbounded cache/log growth). The historical FP hotspots — E4's single-vote
  CollapsibleSection test-vacuity claim and E2's referenced-but-untouched-constant class — do not
  recur. E8's zero-FP claim is upheld in this scoring.
- **Clean false Confirmed-Goods: 0.**
- **Over-broad Confirmed-Goods: 1 — csp CG4.** Its verdict sentence ("`connect-src 'self'` blocks
  no current legitimate client request") is contradicted by csp-R1 (the exportGraph `data:`/blob
  `fetch()` — governed by `connect-src`, which does *not* allow `data:`/`blob:` — is a legitimate
  request that breaks). CG4's **scope line explicitly carves out "runtime-constructed URLs,"** and
  a `toDataURL()` result is exactly that, so the row is *technically* scoped-true — but the
  narrowing is precisely what let csp-R1 slip, and the headline sentence over-reaches. Counted as
  the one precision blemish, not a clean false attestation. (E8's img-src reasoning went only to
  the XSS-bypass angle, security B3; it never connected `connect-src` to the export path.)

## (e) Historically diagnostic rows — E8 results

| Row | History | E8 result |
|---|---|---|
| **csp-R1** exportGraph data: PNG-export break | gold; pipeline-only, cross-file | **MISSED** — CG4 scoped it out (runtime-URL carve-out) |
| **C4** matcher-prefix | contradicted a rubric Confirmed-Good historically | **CAUGHT as RED (R1)** — flipped the CG into a red |
| **N1** prefetch no-CSP | E5-origin | **CAUGHT (A7)** |
| **N15** img-src markdown images | E7r2-only | **MISSED** |
| **N3/N4/N5** lean node-mode `unavailable` handling | E5/E7-only | **ALL CAUGHT** (N3→RED R2; N4+N5→RED R1) |
| **N8** partialize sanitizer bypass | E7-only | **CAUGHT (A1)** |
| **C2** require()/dynamic import() bypass | headless-appended | **CAUGHT (A1)** |
| **N2** audit gate fails-green | **FABRICATED-as-passing historically** | **CAUGHT as RED (R2), reproduced by execution** |
| **N9** .cjs lint crash | E7r1-only | **MISSED** — files-key gap noted (C3), crash mechanism unsurfaced |
| **dep-R1** CLAUDE.md `/tmp` claim | pipeline label | **CAUGHT (A6)** |
| **N10** unset LEAN_VERIFIER_URL | **FALSE-attested "Accurate" historically** | **CAUGHT as RED (R1), executed ×2 refutation** |
| **N16** deploy demo-mode | candidate (not in 56) | partial (A5); uncounted |
| **D3** rehydration seam | pipeline-E1-only | **CAUGHT as RED (R1)** |
| **D4** ArrayBuffer comment | pipeline-E1-only | **CAUGHT (A8)** |
| **D5** OPFS write race | pipeline-E1-only | **CAUGHT (A2 executed probe + A3)** |
| **N11/N12/N13** corpus flag/write/clobber | E7r1-only | **ALL CAUGHT** (N11→A4 executed; N12→A1; N13→A1) |
| **pf-R1** type-seam root | **PIPELINE-ONLY** (via architecture) | **CAUGHT as RED (pf-R1)** |
| **pf-A5** Math.max RangeError | **FALSE-attested-safe historically** | **CAUGHT (pf-A5), fact-check refused to attest safe** |
| **fsc-R1** phantom README section | pipeline label | **CAUGHT (A5)** |
| **D6** cacheKey/double-hash | pipeline-E1-only | **CAUGHT (C2, explicitly labeled D6)** |

**Diagnostic-row scoreline: 16 caught of 19 in-base rows** (misses: csp-R1, N15, N9). Both
false-attestation traps (N10, pf-A5) and the pipeline-only type-seam (pf-R1) are caught — the three
outcomes the evidence-discipline design most needed to demonstrate.

## Misses (7 total)

csp-R1 (masked by CG4 scope carve-out), csp-C1 (dev-eval relaxation, not treated as a defect —
C3-consider frames eval-free as purely good), csp-N15 (img-src markdown images), secdeps-N9 (.cjs
crash mechanism unsurfaced), corpus-C3 (optional-chaining build-inlining — flagged unverifiable,
mechanism not asserted), pf-A4 (ambient NODE_ENV in default param — purity/coupling framing not
raised), pf-A7 (connect-src docstring enumeration drift). The residual moat is the same
enumeration / comment-accuracy / cross-file-runtime-behavior classes the ledger already identified
as the hardest tier — except E8 punched through most of it (csp-A2, cor-A1, fsc-A3, D3–D6, pf-R1
all caught).
