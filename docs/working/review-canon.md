# Review canon: existing full reviews as benchmark labels + the process-composition question

**Date**: 2026-08-06 · **Follows**: `review-arms-groundtruth-comparison-2026-08-06.md`,
`review-arms-instance-selection.md`, decisions 021/030 · **Supersedes in part**: the
arm-recall framing of the comparison doc (see §2).

## 1. The canon (v1): 8 instances with pipeline-verified labels

All from meta-formalism-copilot (`/workspace/external/meta-formalism-copilot`); ranges
verified reconstructable 2026-08-06. Labels are the rubric's 🔴/🟡 rows (pipeline-verified,
Evidence-grounded), plus retrospective adjudications where noted. Context base = merge-base
(= range start) in all cases.

| ID | Range (base..head) | Size | Rubric | Status @ review | Labels (R/A/C) | Extra label provenance |
|---|---|---|---|---|---|---|
| mfc-csp | `d86d2dc..d90d6bb` | 2f +72/−1 | `docs/reviews/csp-headers/` | ✅ PASSES | 2/4/7 | **Gold stratum**: retrospective Confirmed-Good misses (fable connect-src ×2 incl. "clean nonce lifecycle"; sonnet "no unintended carve-outs") adjudicated in `retrospective-confirmed-good-2026-07-30.md` §4; defect later-fix-confirmed by `4f018ab` ("address review findings on CSP headers", exportGraph → toBlob) |
| mfc-lean | `d86d2dc..c95c9cb` | 10f +122/−20 | `docs/reviews/lean-verifier/` | ✅ PASSES | 2/1/11 | — |
| mfc-hygiene | `d86d2dc..f2f149b` | 4f +83/−23 | `docs/reviews/llm-server-hygiene/` | ✅ PASSES | 1/1/7 | — |
| mfc-secdeps | `d86d2dc..8bde50c` | 3f +46/−7 | `docs/reviews/security-deps-guardrails/` | ✅ PASSES | 1/1/7 | Manifest-touching (dependency stratum) |
| mfc-deploy | `d86d2dc..4329d6e` | 2f +41/−3 | `docs/reviews/vercel-deploy-button/` | ✅ PASSES | 2/0/5 | — |
| mfc-fscompat | `d86d2dc..b64c1ca` | 3f +21/−2 | `docs/reviews/vercel-filesystem-compat/` | ✅ PASSES | 1/4/7 | — |
| mfc-corpus | `dc6dfb0..2dc403e` | 28f +2211/−33 | `docs/reviews/code-review-rubric.md` (top-level) | 🟡 CONDITIONAL | 0/4/— | Large-diff stratum (needs split or raised budget per arm run); all 4 ambers fix-confirmed in follow-up commit |
| mfc-postfix | `9c9edf5..7f30210` | 6f +97/−13 | `runs/review-arms/mfc-2026-08-06/groundtruth/` | 🔴 DOES NOT PASS | 1/8/14 | 2026-08-06 ground-truth run; arm results already scored (comparison doc). **Post-review-fix state** — the only canon instance whose input was already lite/full-review-fixed |
| ~~11 archived eval cells~~ | md1/nd2/nd3 | — | `/home/node/cr-eval/runs/` | — | 90 ✅-rows classified | **Not reachable from this environment** — md1 labels partially recovered via mfc-csp above; nd2/nd3 (sim repo) pending access |

Freeze rule: canon rows are append-only; a re-adjudication updates the provenance column,
never rewrites the label in place.

Per-issue ledger: `canon-issue-ledger.md` (2026-08-14) enumerates all 43 distinct known
issues across the canon — the 24 original labels, the 9 postfix labels, 4 headless-arm
appends, and 6 live-at-HEAD E1 findings — with which review process found each.

## 2. Reframe: the decision-relevant question is process composition, not arm recall

Author call (2026-08-06): arm-vs-arm recall differences are not decision-relevant — the
headless sonnet pass (arm [0]) is sufficiently good and sufficiently cheap to be the lite
reviewer. The open question is how the lite loop **composes** with the full pipeline:

- **P-A (current)**: write code → full review-fix-loop (≤3 iterations of ~full-pass cost).
- **P-B (lite-first)**: write code → lite (sonnet headless) review-fix-loop → full
  review-fix-loop on the lite-clean state.
- **P-C (staged/interleaved)**: write code → for each pipeline stage (fact-check → fix →
  critics → fix), return findings and fix before the next stage — the lite process
  *directly builds up* the full process rather than preceding it.

**The crux**: does full review on a lite-clean commit cost less than on a dirty one — at
all? Two competing cost models:

- **Fixed-pass model**: full-pass cost is dominated by reading/enumeration (fact-check
  replicates + critics read the diff and repo regardless of what they find). Evidence for:
  the 2026-08-06 ground-truth pass ran on *already review-fixed* commits, still spent
  ~721k subagent tokens, and still emitted 1R/8A. Under this model P-B saves nothing on
  pass-1; it saves only **iterations** — every red/amber the lite loop clears before the
  full pipeline runs is a chance to land under the next iteration threshold, and each
  avoided full iteration is worth an entire ~$10-15 pass.
- **Findings-dependent model**: dirtier code → more findings → longer critic reports,
  longer synthesis, more fix-verification reads → materially more tokens per pass. Under
  this model P-B also thins every pass.

These are distinguishable with the canon, cheaply, because canon instances have **both
states in git history**: the reviewed (dirty) commit and the post-fix (clean) commits.

## 3. Experiment design (uses the canon; no new code needed)

**E1 — Is full-pass cost findings-dependent?** Pick 3 canon instances with fix-confirmed
labels (mfc-csp, mfc-corpus, mfc-fscompat). Run the full pipeline pass-1 on (a) the dirty
reviewed commit and (b) the post-fix state, same scope shape. Compare subagent-token
totals and finding counts. 6 full passes ≈ 6 × ~700k tokens — the priciest experiment in
this program; run once, it prices every composition decision after it.
*Prediction (fixed-pass model): (b) costs ≥85% of (a).* If confirmed, P-B's entire value
is iteration-count reduction and the analysis shifts to E2.

**E2 — How many full iterations does lite-clean save?** For each canon instance, run the
lite arm on the dirty state; count which of the instance's 🔴/🟡 labels the lite arm
catches (this is the arm-recall number, now *instrumental* rather than the headline).
Lite-catchable labels are iterations-saved candidates: if lite clears them pre-full, the
full loop starts from a state whose remaining findings are only the lite-invisible ones
(cross-file/structural/enumeration class — see comparison doc §4). Estimate:
`iterations_saved ≈ ceil(labels_total / threshold) − ceil(labels_lite_invisible / threshold)`
then validate on 1-2 instances by actually running both loops. Lite-arm cost per instance
≈ $0.08-0.25 → whole-canon sweep ≈ $2.
*mfc-postfix already provides one datapoint: lite caught 1/9 of the labels on a
post-review state — i.e., on already-fixed code, lite-first saves ~nothing; its leverage
must come on genuinely dirty states (E2 measures exactly that).*

**E3 — Does P-C (staged) dominate P-B?** Only worth running if E1 shows fixed-pass cost.
P-C's promise: fixes land between stages, so critics never spend tokens re-deriving what
the fact-check-fix already cleared, and the fix agent has fresh, small context per stage.
P-C's risk: stage-fix churn (030's finding-churn mitigation applies — pass prior findings
as "previously reported") and losing the confound-controlled byte-identical prompt
property mid-pipeline. Design after E1/E2 numbers exist.

**Metrics, all experiments**: total tokens to full-review-clean; iterations count;
verified-recall retained (no label lost relative to P-A — the safety condition); fix-churn
(re-worded/oscillating findings across iterations).

**Measurement-provenance convention (adopted 2026-08-07; closes rubric A6 of
`docs/reviews/code-review-rubric-2026-08-07-main.md`)**: any run or sub-run that reports
per-agent token figures MUST (a) append one row per agent to a `token-ledger.md` in the run
directory *at measurement time*, as each task notification arrives — not reconstructed from
memory afterward — and (b) register the sub-run's agents and totals in the run's
`manifest.json`. Figures that exist only as prose in a results doc (the 2026-08-06
`hunt-verify/` case: 8 agents / 577,971 tokens, fact-check verdict Unverifiable) are
unauditable once the session ends; the ledger is what makes the arithmetic re-derivable
from primary records. Retroactive transcription of already-lost telemetry is explicitly
not required (cosmetic, per the 2026-08-07 tech-debt triage) — the convention binds the
*next* measurement run forward.

## 4. Status

- Canon v1: frozen above (8 rows). Expansion candidates: nd2/nd3 cells if the archive
  becomes reachable; /workspace's own docs/reviews history (rubrics deleted in working
  tree, recoverable from git log).
- E2 **run and scored 2026-08-06** (`e2-results-2026-08-06.md`, actual $0.81): red recall
  3/8, overall 6/24, 0 confirmed FPs; lite caught 1 confirmed + 1 probable full-pipeline
  miss; lite-first saves ~one iteration on ~40% of instances (in-diff-behavioral
  stratum), ~zero elsewhere; lite hits are fact-check-shaped → strengthens P-C. Canon
  label appends recorded in the results doc. (Doc restored after the 2026-08-06 archive
  sweep — the canon is live/append-only, exempt from working-doc archival.)
- E1 **run and complete 2026-08-06** (`e1-results-2026-08-06.md`, 5.26M subagent tokens,
  6 cells): fixed-pass model confirmed 3/3 pairs (clean/dirty cost ratios 1.10/0.99/0.96,
  mean ~1.02) — pass cost tracks diff size sublinearly, never finding count. Larger
  second result: all three post-fix states failed re-review (4R/1R/5R), with two
  fix-introduced defects (vacuous test regexes; fails-open C2 guard) and one
  fresh-eyes-only defect (rehydration seam bypass). P-B saves iterations only (~40% of
  instances × 1 iteration); P-C's premise sharpened — same-pass review of interleaved
  fixes is the exploitable mechanism. E3 design is the open item. **E3-loops run 2026-08-06 on csp** (`e3-loops-results-2026-08-06.md`): both arms terminate; arm1 0.70× arm2 but variance-dominated (verdict draws on two marginal reds controlled loop length, ~1M tokens/pass); hypothesis not supported as mechanism; tier-policy fix identified as the high-leverage intervention. **Re-run under the production 0R+0A stopping rule (`e3-loops-0R0A-results-2026-08-06.md`)**: both arms MEET 0R+0A (arm1 3.08M / 2 full passes, arm2 4.04M / 3; ratio 0.76 — same one-pass gap, same verdict-draw-variance cause, hypothesis still not supported as mechanism). 0R+0A cost = 1 disposition round + 1 verify pass per arm, no spiral. Tier-policy edit (comment-Incorrect-High→amber; immutable-history→override log) remains the high-leverage change and would collapse the gap. New later-fix label
  candidates queued in the results doc.
- E4 **run and scored 2026-08-14** (`e4-results-2026-08-14.md`, actual $5.03): the
  middle-ground arm (opus-5, k=3, Stage-1, union-scored) recalls 11/24 canon labels
  (vs E2's 6/24) plus all three post-E2 appended labels, at 0 confirmed FPs — ~2× lite
  recall at ~6× lite cost, ~20× under the full harness. Key updates: the E2 miss
  anatomy over-classified misses as context-bound (opus recovered deploy R2 and
  fscompat R1/A1 from identical prompts — model tier moves the reachability boundary);
  union > consensus confirmed within-family (two union-only label hits, no FP for
  consensus to cut); two new full-pipeline miss candidates (csp matcher-prefix,
  fix-confirmed `ab4dbdb` against a Confirmed-Good row; corpus legacy-v2 migration
  clobber, live at HEAD) — canon appends recorded in the results doc. Actionable
  harness bug: cross-model-review.py's parser drops multi-path findings (cost one
  label hit and one new-miss candidate from parsed output). Residual misses cluster
  as cross-file-verification / repo-enumeration / test-strategy — the full harness's
  remaining moat; next middle-ground lever is context (cheap agentic pass), not model
  or k.
