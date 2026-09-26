# FC model mini-sweep results: pin the Stage-1 fact-check to **opus** (2026-08-15)

**Design**: `runs/review-arms/fc-model-sweep/README.md`. 3 models (sonnet / opus /
fable, all with the full `code-fact-check` role-skill prompt) × 2 cells (mfc-csp
`d90d6bb`, mfc-deploy `4329d6e`) × 2 replicates = 12 in-session Stage-1 runs on
byte-identical per-cell prompts (only the output path varied). Ground truth: 6
known-bad doc claims (csp-R2/A2/A3, dep-R1/R2, N10) + csp-R1 as a cross-file bonus
row. Adjudicated by the orchestrator against the canon ledger, anti-SWR strict.

## Headline

| Model | GT rows caught (of 12 = 6 rows × 2 reps) | **False attestations** | csp-R1 bonus | Verdict stability across reps | Mean tokens/rep |
|---|---|---|---|---|---|
| sonnet | 9.5 | **3** (the disqualifier) | 0/2 (1 miss, 1 attest) | worst (3 GT rows flip) | 108k |
| **opus** | **12** (1 verdict-split) | **0** | **2/2 full** | 1 row flips channel | 103k |
| fable | **12** | **0** | **2/2 full** | **perfect — identical verdicts both reps** | 100k |

**Decision: pin opus.** Sonnet is disqualified by false attestations on exactly the
load-bearing failure mode. Fable ties opus on detection with better stability, but at
2× the price it adds no recall on this ground truth — and the deepest single trace of
the sweep came from opus. (If verdict stability were the binding concern, fable is
the defensible alternative; it is not worth 2× for zero marginal catches here.)

## Per-row adjudication

| Row | sonnet r1 | sonnet r2 | opus r1 | opus r2 | fable r1 | fable r2 |
|---|---|---|---|---|---|---|
| csp-R2 (Edge runtime) | Inc ✓ | Inc ✓ | Inc ✓ | Inc ✓ | Inc ✓ | Inc ✓ |
| csp-A2 (Tailwind misattribution) | Inc ✓ | Inc ✓ | Inc ✓ | Inc ✓ | Inc ✓ | Inc ✓ |
| csp-A3 (layout/`x-nonce` comment) | **Verified-High = ATTESTATION** | half: reason Inc ✓, auto-tag half **Verified-High = ATTESTATION** | Inc ✓ (both halves) | Inc ✓ (both halves, + x-nonce claim Inc) | Inc ✓ | Inc ✓ |
| dep-R1 (`/tmp` claim vs `cwd()/data`) | MA ✓ (full mechanism) | **Inc ✓ (full mechanism — only blocking-tier catch)** | partial: mechanism in prose, verdict split Verified+Unverifiable | MA ✓ (full mechanism) | MA ✓ (full mechanism) | MA ✓ (full mechanism) |
| dep-R2 (analytics "does not persist") | MA ✓ | Inc ✓ | MA ✓ | Inc ✓ | MA ✓ | MA ✓ |
| N10 (unset → mock; actually defaults localhost:3100) | MA ✓ | MA ✓ | MA ✓ | MA ✓ | MA ✓ | MA ✓ |
| *csp-R1 bonus (connect-src blocks export)* | miss (OpenAlex nit only) | **found `exportGraph` fetch, then certified Verified = ATTESTATION** | Inc ✓ w/ exportGraph | Inc ✓ w/ exportGraph | Inc ✓ w/ exportGraph | Inc ✓ w/ exportGraph |

Inc = Incorrect, MA = Mostly accurate (both land in the report's Claims-Requiring-
Attention section and are visible to Stage-1.5 gating; only Incorrect-at-High blocks).

## Findings

1. **Sonnet's failure is the exact one the pin exists to prevent.** Both sonnet csp
   attestations came from trusting the vendored Next.js docs ("Next parses the CSP
   header and applies the nonce automatically") **without tracing the request-vs-
   response seam** — the docs describe the *request* header, which `proxy.ts` never
   sets. Opus (both reps) traced `app-render.js` to the literal
   `getScriptNonceFromHeader(req.headers)` call and proved the nonce dies — the
   csp-A1 dead-plumbing mechanism, from a comment claim. Worse, sonnet-r2 *found*
   the refuting `exportGraph.ts` `fetch(dataUrl)` evidence for csp-R1 and still
   certified the claim Verified ("browser-implementation-dependent") — the E5-class
   found-then-waved-off certification. A false "Verified" here silently skips
   critics downstream; 3 attestations in 4 replicates is disqualifying.
2. **Opus and fable are detection-equivalent on this ground truth** — 12/12 GT
   catches each, 0 attestations, both landing csp-R1 cross-file with the full
   exportGraph mechanism. Fable's only edge is verdict stability (identical verdicts
   across reps on every GT row; opus flipped dep-R2 MA↔Inc and split dep-R1 once).
   At $10/$50 vs opus's per-token price that edge isn't worth 2×; k-across-passes
   (2-clean) already supplies redundancy for channel flips.
3. **A model-independent calibration gap, not a model gap**: all six replicates
   verdicted N10 and (5 of 6) dep-R1 as *Mostly accurate* while stating the
   Incorrect-grade mechanism in full prose ("unset does not produce the mock — it
   substitutes a default URL"; "writes never reach /tmp, they throw and are
   swallowed"). The catches are real and attention-visible, but none reach the
   blocking Incorrect-at-High channel. If this matters operationally, it's a skill-
   text calibration tweak ("a claim whose stated mechanism is refuted is Incorrect
   even when its practical conclusion holds"), not a model choice.
4. **No confirmed FPs in any of the 12 reports.** Every Incorrect verdict
   spot-checked traces to a real ledger mechanism (csp-A1/A3 plumbing, Tailwind
   attribution, Node-vs-Edge runtime, exportGraph, analytics mechanism, commit
   1859488's false graceful-degradation claim).
5. Cost: tokens/replicate are near-identical across models (~100–108k), so the
   price ratio is just the per-token ratio — sonnet : opus : fable ≈ 1 : 1.7 : 3.3
   per Stage-1 replicate. Pinning opus over ambient-sonnet sessions costs ~+70% of
   a ~100–130k stage; pinning opus over ambient-fable sessions *saves* ~50%.

## Action taken

- Pinned `model: opus` for Stage-1 fact-check replicates in
  `~/.claude/skills/code-review/SKILL.md` (see the Stage 1 section).
- Reports: `runs/review-arms/fc-model-sweep/<cell>/<model>-r<N>.md` (12 files,
  committed as records).
- Next per standing decision: pipeline config now settled (pending only E7 reps
  2–3, which don't touch pipeline config) → A8 token measurement can run.
