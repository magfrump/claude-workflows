# 032 — Token-reduction levers for the review-fix loop

**Date**: 2026-08-06 · **Status**: adopted (bundle high-confidence; #2 queued as experiment)
· **Method**: divergent-design (Path C — autonomous, no live consult) ·
**Working doc**: `docs/working/dd-review-token-reduction.md` ·
**Follows**: [031](031-review-loop-tier-and-factcheck-policy.md) (T + k=1 + 2-clean) ·
**Grounded in**: E1 (`e1-results-2026-08-06.md`), E3 (`e3-loops-0R0A-results-2026-08-06.md`),
arm-ideas (`review-arm-ideas-2026-08-06.md`).

## Context

031 banked the fact-check savings (T tiering + k=1 + 2-clean). The remaining cost is
elsewhere: E1 measured a full pass at 0.8–1.1M tokens, **findings-independent**, split
fact-check ~30–45% / **critics ~350–550k (the largest block, untouched)** / rubric ~90–160k.
The shared diff + enclosing-file context is **re-sent to ~8 agents per pass**, every pass.
This DD asks what else reduces loop tokens without regressing behavioral-red recall.

## Decision

**Adopt a complementary bundle of three orthogonal, recall-safe levers now; queue a fourth
as a measured experiment.** The survivors act on different axes (transport / which critics /
when a pass stops / which model), so this is a portfolio, not a single pick.

**Adopt now (high confidence):**

1. **Prompt-cache the shared context (#3).** Cache the diff + enclosing-file prefix re-sent to
   all ~8 agents/pass. Pure transport change, zero recall effect (identical content). Revives
   030's pruned prompt-cache lever [13] — pruned there as a *benchmark arm* (provider-specific
   breaks byte-identical cross-model), explicitly reclassified as a "loop-only optimization,"
   which is exactly this venue. **Production-loop-only; must stay OFF the cross-model sweep
   path** (H4: the sweep's byte-identical-prompt confound control is load-bearing). Biggest
   input-token lever; adopt first and independently.
2. **Critic diff-shape + evidence gating (#1).** Enforce/tighten the existing Stage-1.5 gate
   so a critic with no domain signal in the diff or fact-check is skipped. Already specced;
   evidence-gated ⇒ recall-safe. Cuts the largest block on narrow diffs.
3. **First-red short-circuit (#4).** Abort a *red-gated* pass once a behavioral red is
   confirmed (another pass is coming regardless), skipping the remaining critics. **Mitigation
   (from failure-driven stress-test): short-circuit red-gated passes only; always run the full
   panel on the final otherwise-clean pass**, where 0A is actually adjudicated — otherwise the
   amber inventory for that pass is hidden.

**Queue as experiment (medium confidence — real recall risk):**

4. **Cascade / model-tiering critics (#2).** Cheap model (sonnet-role-prompt) first, opus only
   to re-verify flagged findings or on later passes. Revives 030's cascade [5] (the
   "agentic-escalation fails H2" objection was benchmark-confound-specific; this is the
   production loop). Not a default: E1's "sonnet-role-prompt acceptable" was measured on
   *single-pass* recall, never in a loop, so the cheap-model loop recall risk is unquantified.
   Gate it on a recall check exactly as k=1 was (reconstruct against the replicate corpus, then
   one live loop) before adopting.

**Complement (low priority):** static-analysis pre-filter (#5, eslint+tsc+tests before the
panel) — modest saving, per-repo setup; adopt if cheap on the code-heavy TS target.

## Constraints the decision satisfies

- **H1** no behavioral-red recall regression vs the 031 baseline — all three adopted levers
  are recall-neutral by construction (same content cached; only signal-less critics gated;
  red-gated passes repeat anyway). #2 is *not* H1-safe unproven → experiment.
- **H2** preserves 0R+0A, T tiering, and the 2-clean second-independent-draw property — no
  lever removes the second pre-merge draw.
- **H3** ≥15% measured pass reduction to justify build — #3 (input dominates, ×8 agents) and
  #1 (largest block) clear it; #4 saves the tail of red-gated passes.
- **H4** does not break the cross-model sweep's byte-identical-prompt confound control — the
  only provider-specific lever (#3 caching) is fenced to the production loop, off the sweep.

## Pruned (with reason)

- **Cheaper rubric synthesis (#6)** — ~15% ceiling and tiering is the least-stable stage;
  risk > reward.
- **Omnibus single-critic (#7)** — ⚠ H1: collapsing 5 independent critics loses the disjoint-
  draw coverage E1 showed matters.
- **Carry-forward / delta fact-check (#8)** — measured **~0 on both csp and corpus** (E3);
  carry yield is governed by centrality/coupling not size, and the safety-required import
  closure is what kills it on coupled modules. Niche lever for large *modular* repos only; do
  not build before an instance actually exhibits a large localized diff.
- **On-demand file read (#9)** — H4: per-provider tool plumbing + model/retrieval
  nondeterminism [carried from 021 [6]/[14]].
- **Do-nothing (#10)** — fails H3 (cost is the ask).
- **Persistent stateful session (#11)** — statelessly unachievable; approximated by #3.
- **Critic scope-restriction across passes (#12)** — same coupling failure as #8, worse for
  cross-cutting critics.

## Confidence & falsifiers

- Bundle (#1/#3/#4): **high** — recall-safe by construction; the risk is engineering
  (cache-key correctness, gate false-negatives), not recall.
  - Falsifier for #1: a canon instance where a gated critic would have surfaced a behavioral
    red the panel otherwise missed → tighten the gate signal, don't widen it.
  - Falsifier for #4: a red-gated pass whose skipped critics would have found an *independent*
    red that changes the fix → collect reds panel-wide before short-circuiting.
- #2 tiering: **medium** — falsifier is any behavioral red the cheap-model tier misses in the
  loop-recall check; that check gates adoption.

## Implementation status (2026-08-06)

The "adopt now" bundle is shipped:

- **#1 critic gating** — *already implemented* before this decision (SKILL Stage 1.5: evidence
  consultation + diff-shape skip table + `--all-critics` opt-out). No change needed; recorded
  here as adopted. It skips signal-less core critics exactly as #1 describes.
- **#3 shared-context prefix / prompt-cache discipline** — added to `skills/code-review/SKILL.md`
  as a new "Shared-context prefix" subsection under **The Pipeline**: the shared block is built
  once, placed first byte-identical across all ~8 agents, with per-agent skill text in the tail
  and the per-pass-varying fact-check summary last so the stable prefix stays cache-warm across
  passes. Fenced production-loop-only; a guard note in `scripts/cross-model-review.py`'s
  docstring forbids porting caching to the sweep path (H4).
- **#4 first-red short-circuit** — added `--loop-pass` (Step 6) and a "First-red short-circuit"
  subsection after the Fact-Check Gate in the SKILL; wired into `workflows/pr-prep.md` step 3d
  (intermediate passes get `--loop-pass`; the confirmation pass runs the full panel). Behavioral
  🔴 is defined by tier policy T (031); amber is gathered only on the terminal full-panel pass,
  which is what preserves H1.

## Measured on the canon (2026-08-06) — H3 revisited

Baseline (`runs/review-arms/baseline-2026-08-06/`, full canon single pass = 2.99M tokens) plus
the `levers-3-4-measurement.md` analysis **revise the H3 expectations downward for #3/#4** and
relocate the real savings:

- **#3 prompt-cache: ~5% cost-equivalent, 0% token-count — NOT 20–40%.** The 20–40% estimate was
  inherited from the cross-model harness, which *inlines the whole diff into the prompt*. The
  production Agent-tool loop does **not** inline — critic agents self-read the diff/files/fact-check
  via tools — so the shared cacheable *prefix* is small (~330 tok as-run). Caching is also a
  billing-rate effect, invisible to the token-count metric. Realizing even the ~5% needs a SKILL
  restructure to inline the shared diff+fact-check prefix. **Verdict: leave caching on (free),
  but it is a single-digit-% cost lever on this path, not an H3-clearing one.**
- **#4 first-red short-circuit: 0 saving on a single pass; fired 0/8 on the canon.** Its
  high-value trigger (a *fact-check* behavioral 🔴 → skip the whole panel) never fired because
  fact-check on reviewed states finds only comment/doc Incorrect (→🟡 under T); the real reds come
  from critics (one parallel wave, nothing to skip). #4 is loop-only and red-provenance-gated;
  loop-estimate ≤~10% and only when the defect is a fact-check-visible comment/contract lie.
  **Verdict: keep wired for loop safety; do not count on it for savings on structural-defect corpora.**
- **Where the token savings actually are (measured):** 031 **k=1 ≈ 29%** off a k=3 pipeline, and
  032 **#1 gating ≈ 17%** off the ungated panel. These clear H3; #3/#4 do not on this workload.

So H3 (≥15% saving) is **met by #1 + k=1, not by #3/#4**. #1 was the load-bearing 032 lever.

## Next

- (Optional) Amend #3's guidance in the SKILL to state the single-digit-% production-loop benefit,
  and only invest in inlining if a loop's cross-pass cache reuse proves it out.
- (Optional) Empirically fire #4 on an E1 dirty state whose defect is a fact-check-visible
  behavioral comment/contract lie, to convert its loop estimate to a measurement.
- Run #2 (model-tiering) as the next arm on csp+corpus (reconstruct-then-live, k=1 protocol)
  before any SKILL default change.
