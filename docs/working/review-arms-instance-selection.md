# Selecting a larger review-arms instance set (without SWR-Bench's failure modes)

**Date**: 2026-08-06 · **Follows**: `review-arms-setup.md`, decision 030, the
Confirmed-Good retrospective (`retrospective-confirmed-good-2026-07-30.md`), and the
anti-pattern analysis in `docs/human-author/CodeReviewWriteup.md` · **Feeds**: the next
review-arms sweep; ultimately the SWRBench-fork v2 judge (029).

## The failure modes to not copy

From the writeup (§Verification Anti-patterns) and the 029/030 record, the SWR-Bench
traps are specifically:

- **T1 — judge scores against a "should have been commented on" label, so accurate
  findings count as false positives.** The astropy#1010 spot-check: six accurate,
  non-blocking findings scored as ten FPs. Root cause: ground truth defined as *what a
  human reviewer chose to say*, not *what is true of the code*.
- **T2 — balanced clean-PR subsets.** Balancing for clean PRs measures a reviewer's
  restraint, which matters for human-consumption reviews but not for the agent-authored
  use case where out-of-scope findings route back to the agent at near-zero cost.
- **T3 — single-commit diffs with invisible siblings.** Our own measured trap (021
  Results 3c/5): scope boundaries the instance flattens manufacture confident FPs. An
  instance set that samples commits without their branch context imports this.
- **T4 — no later-history signal.** Standalone benchmark problems freeze at the PR;
  they can't tell you which missed findings *mattered*. Local project history can: a
  bug that survived review and got fixed later is a labeled, severity-weighted miss.

## Selection principles

**P1 — Ground truth is facts about the code, never "what the reviewer said".** For each
instance, the label set is: (a) defects fixed by *later commits* in the same repo
(fix-commit mining, below), (b) findings from the full agentic pipeline that were
*verified against the code* (Evidence-grounded rubric rows, not raw critic output), and
(c) known-FP patterns to penalize (the D3/D4 classes). A lightweight arm surfacing a true
finding the ground-truth run didn't mention scores as *unmatched-true after adjudication*,
not FP — this single rule is the T1 antidote, and it's why every candidate finding needs
Evidence grounding before it enters the label set.

**P2 — Sample changesets, not commits.** Every instance is a two-dot range plus a
`--context-base` at the logical changeset boundary (branch base, or range start when
reviewing a tip). Never hand an arm a mid-branch slice without its sibling context (T3).

**P3 — Stratify by what makes findings interesting, not by clean/buggy balance (T2).**
Interesting strata, from the corpus we already have:
- **Later-fixed defects** (the gold stratum): ranges whose defect is proven by a
  subsequent `fix:` commit. Recall on these is the headline number.
- **Confirmed-Good misses**: ranges where a prior full review *certified* something
  false (retrospective §4: the fable connect-src row, the "clean nonce lifecycle" row,
  the sonnet "no unintended carve-outs" row). These test whether cheap arms catch what
  assurance-mode reviews miss — the highest-value class in the retrospective.
- **Observation-free defects**: the sonnet-MD1 class — nothing in any same-run artifact
  observed the defect. These measure whether an arm *observes* new facts vs. re-ranks
  known ones; expected recall is low, but it's the stratum where k=3 and cross-family
  arms can differentiate.
- **Comment/doc drift**: ranges with claim-bearing comments (the fact-check stage's
  bread and butter) — cheap arms historically catch these well; they anchor precision.
- **Clean-ish maintenance ranges**: a *few* (not balanced — maybe 15–20%) so abstention
  is measurable; score them by FP count only, never by "said nothing" (T2).

**P4 — Every instance ships with its adjudication budget.** An instance is only usable
if disagreements between an arm and the label set can be settled cheaply: the range is
< ~500 changed lines, the repo state at both ends is checkoutable, and the defect (if
any) has a one-paragraph statement with `path:line`. If adjudicating a candidate range
would take longer than running it, drop it.

**P5 — Operator-owned repos only** (021/030 secret-screening trigger, restated).

## Mechanical harvesting procedure

For each local project (this repo, meta-formalism-copilot, and any other owned repo with
≥6 months of history):

1. **Fix-commit mining.** `git log --oneline --grep='^fix' --grep='regression' -i` →
   for each fix commit F, locate the commit(s) that *introduced* the defect
   (`git log -L` on the fixed lines, or the fix's own message — this repo's convention
   of explanatory bodies makes this cheap). The instance is the introducing changeset
   (two-dot range + context base); the label is the defect as described by F. Discard
   pairs where the introduction predates the repo's test/review discipline if
   adjudication would be ambiguous (P4).
2. **Review-artifact mining.** For repos with `docs/reviews/` history: every dated
   rubric with 🔴/🟡 rows whose range is recoverable is an instance with pre-verified
   labels (b-type). The 11 archived eval cells (md1/nd2/nd3) come for free with the
   retrospective's per-row classifications — including the three Confirmed-Good-miss
   labels, already adjudicated.
3. **Drift mining.** `git log --oneline --grep='comment' --grep='docs(' -i` fix commits
   that correct comments → the *preceding* state is a comment-drift instance.
4. **Cap and stratify.** First target: ~25–30 instances — roughly 8–10 later-fixed,
   3–5 Confirmed-Good misses (all we have), 1–2 observation-free (all we have), 6–8
   drift, 4–5 maintenance. Small enough to hand-adjudicate every disagreement once
   (P4), large enough that a ≥30% FP-reduction hypothesis (030 arm [7]) is testable.
5. **Freeze the manifest.** One TSV: repo, range, context-base, stratum, label(s) with
   `path:line`, adjudication note. Byte-frozen ranges keep arm runs reproducible (H2).

## Scoring (T1-proofing, restated as rules)

- Match arm findings to labels with the harness's two-stage matcher (file/line overlap →
  judge same-issue), same as consensus filtering — one matcher everywhere.
- **Unmatched arm findings are "unadjudicated", not FP.** They queue for a one-shot
  adjudication pass (agentic re-verify, 021 Stage 3, or human); only findings that fail
  re-verification against the code become FPs. Adjudicated-true findings get *added to
  the label set* (append-only manifest) so later sweeps score against the enriched labels.
- Severity-weight recall by the label's stratum (a later-fixed defect miss costs more
  than a drift miss); report per-stratum, never one blended number.
- Report abstention rate alongside precision (the retrospective's empty-vs-empty lesson:
  agreement driven by silence must be legible).

## Relationship to the SWRBench fork

This instance set is the *local* complement to the fork (separate project per the
handoff doc): same scoring philosophy (v2 judge spine, 029), but instances from owned
repos with later-history labels instead of mined PRs. If the fork's kappa-gated judge
lands, these manifests should be portable into it as an extra instance source.
