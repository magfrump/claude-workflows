# Review arms vs. full-pipeline ground truth — mfc HEAD~3..HEAD (2026-08-06)

**Instance**: meta-formalism-copilot `HEAD~3..HEAD` (7f30210; CSP dev unsafe-eval fix,
streaming crash guard, two comment fixes; 6 files, +97/−13).
**Arms**: `runs/review-arms/mfc-2026-08-06/{base,small,k3}` (decision 030 portfolio).
**Ground truth**: full `code-review` pipeline (k=3 fact-check merged most-severe-wins +
5 opus critics + synthesis), artifacts in `runs/review-arms/mfc-2026-08-06/groundtruth/`,
rubric `code-review-rubric-2026-08-06-integration-6.1-HEAD~3.md`.

## Ground-truth result (the label set)

**Status: 🔴 DOES NOT PASS** — 1 red, 8 amber, 14 consider, 7 confirmed-good.

- **R1 (Structural)**: `mergeStreamingPreview<T>` claims completeness for partial-JSON
  streaming values; `between` contract disagrees three ways (schema/TS/renderer); guard
  patches one symptom of the seam.
- **A1**: fail-open `NODE_ENV !== "production"` unsafe-eval default (security+api+arch+
  fact-check convergence — the headline in-range finding).
- **A2**: the default call path (`buildCsp(nonce)` at `proxy.ts:53`) is exercised by zero
  tests after the tests pinned both modes explicitly.
- **A3** eval policy caller-selectable (single-call-site enforcement) · **A4** env read in
  default param breaks injectable-defaults convention · **A5** spread bound trusts OpenAlex
  `per_page`, no defensive truncation (RangeError cliff) · **A6** guard checks array
  presence not element presence (dangling `A ↔` on the reachable one-element parse state) ·
  **A7** connect-src docstring omits corpus git worker · **A8** leftover parity comment +
  "optional chaining" mischaracterization.

Cost: ~721k subagent tokens across 8 agents (3 fact-check replicates 332k + 5 critics
389k) plus orchestration — the ~$10–15/instance class at API prices (session-billed here).

## Arm scoring (matched by same-issue, adjudicated against code — not against "what the
ground-truth reviewer chose to say"; see selection doc's T1 rule)

| Arm | Cost (live) | Findings | Hits on 🔴/🟡 (9 rows) | FPs | Notes |
|---|---|---|---|---|---|
| base (sonnet-5, k=1) | **$0.075** | 2 | **1/9** — A1, at matching severity | 1 | FP: "MAX_OVERRIDE_QUERIES … neither defined nor visible" — the constant exists in `querySanitize.ts:9`, which the Stage-1 context did **not** inline (file referenced by the changed comment but not touched by the diff) |
| small (gemini-3.1-flash-lite) | **$0.0035** | 1 | 0/9 | 1 | Same cross-file-constant FP, worse: rated High/Correctness, description garbled/truncated at 154 output tokens |
| k3 (sonnet-5 ×3, ≥2 consensus) | **$0.223** | 5 raw → 3 clusters → **1 kept** | consensus: 1/9 (A1) · raw union: ~3/9 (A1; A6's dangling-endpoint state, r1; A6/R1-adjacent type-vs-runtime nullability, r2) | 0 raw, 0 kept | Consensus killed two *true* singleton findings; there were no FPs among sonnet replicates for it to kill on this instance |

All three arms together: **$0.30** ≈ 1/40th of one ground-truth run.

## What this instance shows

1. **The headline finding is cheap.** A1 (fail-open NODE_ENV) was found by 5/5 sonnet
   samples and matched ground-truth severity — the single most-converged finding of the
   full pipeline costs $0.075 to surface, not $14.
2. **A new FP class for the Stage-1 harness, directly context-attributable:**
   *referenced-but-not-touched file*. Both base and small flagged `MAX_OVERRIDE_QUERIES`
   as undefined because the changed comment references a constant in `querySanitize.ts`,
   which Stage-1 context excludes (it inlines only files the diff touches). Same
   misattribution family as 021's Results 3c/5, one hop further out. **Mitigation
   candidate for the harness (~1h): also inline files that changed comment/doc hunks
   reference by symbol or import.** Until then this FP class is a known cost of the arm.
3. **k3 consensus traded recall for precision on the wrong margin here.** The mechanism
   (kill <2-vote clusters) worked as designed, but both casualties were true findings
   (parts of A6/R1) and there were no FPs to kill — sonnet-5 under Stage-1 context was
   already precise. The 030 arm-[7] hypothesis (≥30% FP-class reduction) needs instances
   that actually *produce* FPs at k=1; on clean-precision instances, k=3's marginal value
   is the union, not the consensus — worth adding a `--consensus-min 1` (union) column to
   the summary so both margins are visible per instance.
4. **The ground-truth-only findings cluster exactly where 030 predicted.** R1 (cross-file
   type-contract seam), A2 (test-coverage-vs-callsite reasoning), A7 (whole-repo fetch
   enumeration), the conventions audit (A4, C11) — all require repo access or enumeration
   the no-tools arm structurally lacks. This is the documented recall ceiling (MD1-R1
   class), not a tuning gap.
5. **T1-proofing worked as intended in both directions.** The base arm's constant-FP was
   adjudicated against the code (constant exists → genuinely false claim → real FP), and
   k3's two singleton findings were adjudicated as true against the code even though the
   arms' "judge" (consensus) discarded them — under SWR-Bench-style what-the-reviewer-said
   scoring, both calls would have gone the other way.
6. **small-arm caveat:** flash-lite emitted 154 output tokens — likely under-generating,
   and its D3/D4 FP re-validation (030 duty) is still owed. One instance is not a recall
   estimate; its 0/9 should be read with that.

## Revisit triggers added by this run

`if the referenced-but-not-touched FP class reproduces on 2+ more instances — build the
comment-symbol inlining mitigation before running the larger sweep.` `if k=1 sonnet
precision stays clean across the first 10-instance sweep — re-rank arm [7] below a union
(k=3, min=1) arm and test the 030 hypothesis on FP-prone instances specifically.`

## Next

Run the ~25-30 instance harvest per `review-arms-instance-selection.md` (fix-commit mining
+ the 11 archived cells + drift mining), with `--dry-run` cost gate per instance; the
ground-truth arm is only needed on instances lacking pre-verified labels.
