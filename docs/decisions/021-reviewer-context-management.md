# 021 — Reviewer context management: how code-review models are given context

**Goal**: Decide where the code-review pipeline should sit on the reviewer-context spectrum
— diff-only → structured (harness-authored) enrichment → full agentic repo access — with
the cross-model / cheap-critic sweep as the primary consumer.
**Project state**: Follows the 2026-07-30 cross-model OpenRouter review experiment · feeds
`scripts/cross-model-review.py` and the `code-review` skill · standalone decision, not
blocked. Synthesized into the unified state doc
`docs/thoughts/code-review-evaluation-state.md` §5.0 and §2.
**Task status**: complete (decision drafted, staged recommendation). Stage 1 **built
2026-07-31** (`scripts/cross-model-review.py --context-base`, opt-in; diff-only default
byte-identical to pre-021) — offline cost measurement in
`docs/working/stage1-context-cost-2026-07-31.md` (worst call $0.248, sweep $4.37: both
guardrails hold). **Not yet validated against any model** — the D3/D4 FP-kill re-run
awaits go-ahead.

## Context

`scripts/cross-model-review.py` is **diff-only by construction**: its `PROMPT_TEMPLATE`
pastes one commit's unified diff and tells the model "*You cannot run commands or read
files; judge only from the diff below.*" The 2026-07-30 cross-model experiment
(`docs/working/experiment-cross-model-review-2026-07-30.md`) showed this arm is a strong
*recall probe* — cheap second families (Sol ~$0.03/60-90 s) found real High bugs the
incumbent Claude critic missed 0/6 (Result 4) — but also that it manufactures the run's
worst false positives:

- **Result 5**: on D4 **all four families**, several at High, flagged Tier A/B work as
  "missing" — it was present, in **sibling commits** the single-commit diff couldn't show.
  Cross-family consensus made the FP look *stronger*, not weaker.
- **Result 3c**: Gemini raised a **Critical** by merging two adjacent heredoc blocks in one
  file into one — a boundary the diff-only view flattened.

Both are the same defect: **diff-only misattributes code across boundaries the diff
flattens** (sibling commit, enclosing function/file). That FP class is the highest-value
thing to fix cheaply. The countervailing force is that diff-only is exactly what makes the
cross-model sweep *possible* — provider-agnostic (plain chat-completions across all four
families), deterministic, prompt-cacheable, and confound-controlled (model identity is not
mixed with retrieval skill). Full agentic access (the production `code-review` pipeline)
maximises recall — it alone caught the cross-file MD1 R1 bug historically
(`experiment-results-code-review-2026-07-29.md`, Result 8) — but is expensive,
non-deterministic, provider-bound, and confounds model quality with agentic skill.

**Prior treatment:** none. A grep of `docs/decisions/**`, `docs/decisions/log.md` (31
rows), `docs/working/**`, and `hypothesis-backlog.md` found no decision or log row on
reviewer context management. The two experiment docs are *evidence and a recommendation*
(follow-up #5: "a second-family critic … must have repo access, not diff-only"), not a
resolved decision. Two research docs the experiments cite
(`research-agentic-review-evidence-vs-repo-setup.md`,
`research-cross-model-review-hypotheses.md`) were never committed to git. **This record is
the first real treatment.**

## Options considered

Eleven candidates spanning the spectrum (full analysis in
`docs/working/dd-reviewer-context-management.md`): diff-only (status quo), +N context lines,
function-body enrichment, enclosing-file/module enrichment, sibling-commit/full-branch-diff
enrichment, repo-map/symbol index, on-demand constrained file read, full agentic access,
ideal-if-free (agentic + multi-sample union), reframe (diff-only as a recall probe
re-verified by an agentic gate), and judge-side enrichment.

Scored against four hard constraints — **H1** eliminate the sibling-commit FP class,
**H2** provider-agnostic/no-tools portable, **H3** preserve measurement confound-control,
**H4** stay in the cost/latency envelope. On-demand read, full agentic, and ideal-if-free
all fail H2 **and** H3 (they break the portability and confound-control that give the
cross-model sweep its value), so they are out of scope *for the portable sweep* — full
agentic remains the production endpoint, not a sweep config.

## Decision and rationale

Adopt a **staged path** rather than a single point:

- **Stage 1 (do first — git-only, portable, confound-preserving): sibling-commit /
  full-branch-diff enrichment + enclosing-file inclusion** (candidates #4 + #3). Change the
  harness from a single-commit diff to the **full logical changeset**
  (`git diff main...HEAD`, or the sibling commits appended as **explicitly labelled**
  "already committed — context only, not under review"), and **inline the enclosing files**
  of touched hunks. This directly kills Results 3c & 5 — the two most severe FPs and the
  highest-consensus FP in the run — with a ~1-hour git-only harness edit, no tool plumbing,
  no per-provider code path, byte-identical context across models, and no cost blow-up.
  Function-body/AST extraction (#2) is reserved for files too large to inline whole.
- **Stage 2 (add only if measured recall justifies the complexity): repo-map / symbol
  index** (#5), to cut the cross-file "X is undefined/missing" FPs that Stage 1's
  same-branch scope cannot cover.
- **Stage 3 (production, not the sweep): keep the incumbent agentic critic as the
  re-verification authority** (#9). Cheap portable diff+context critics produce *candidate*
  findings; the agentic critic (which has repo access) re-verifies before anything surfaces.
  This is where Result 5's "must have repo access" is honoured — at the *verification* gate,
  not the *generation* fan-out — so cheap second-family recall (Result 4) is captured
  without importing agentic non-determinism into the sweep.

**Why this level and not more:** it is the *lowest* context level that makes a cheap
second-family critic viable. It removes the FP class that would otherwise flood the cheap
critic with confident, unanimous, wrong findings (Result 5) while preserving H2/H3/H4 — so
the OpenRouter sweep keeps running and stays model-attributable. Stage 1 fixes
*misattribution*; it explicitly does **not** claim to recover cross-file interaction bugs
(MD1 R1 class) — that recall lives only in Stage 3's agentic gate.

Confidence: **high** on Stage 1 (git-only, directly targets the measured FPs); **medium**
on Stage 2/3 sequencing (gated on future recall/precision measurement).

See alternatives considered → **Pruned candidates and why** below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in
adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[0]: diff-only fails hard constraint H1 — it is the FP source, kept only as the anchor.`
`[1]: +N context lines dominated by #3/#4 — fixes only within-file adjacent gaps.`
`[2]: function-body/AST extraction — boring-alternative #3 (whole-file, git-only) gets ~80% for less complexity; kept as a large-file fallback, not Stage 1.`
`[6]: on-demand file read fails H2 (per-provider tool plumbing) and H3 (confounds model vs retrieval); reintroduces the non-determinism diff-only avoided.`
`[7]: full agentic fails H2/H3/H4 — it is the production endpoint (Stage 3 re-verify), not a portable sweep config.`
`[8]: ideal-if-free (agentic + multi-sample union) discarded on cost/latency.`
`[10]: judge-side enrichment folded into #9 as a downstream variant.`
`Prior pruning grep: no matches found for [reviewer context, enrichment, diff-only, function body, sibling commit, agentic].`

## Stress-test mitigations

- How to read: *Invert-the-thesis* mitigation — inverting #4 (argue to keep diff-only)
  surfaced that sibling-commit context can make a model flag **already-merged** code as new;
  mitigation added to Stage 1 as a build requirement: sibling-commit context must be
  **labelled "already committed — context only, not under review."**
- How to read: *Boring-alternative* mitigation — the move demoted function-body AST
  extraction (#2) in favour of git-only whole-file inclusion (#3) for Stage 1; AST
  extraction survives only as a large-file fallback.

## Consequences

**Easier:** the two most severe/high-consensus false positives (Results 3c, 5) stop
reproducing; cheap second-family critics become viable reviewers (Result 4 recall without
Result 5 noise); the sweep stays on plain chat-completions, deterministic, cacheable, and
model-attributable; Stage 1 is a ~1-hour git-only harness change.

**Harder:** prompts grow (whole files + full branch diff) — more tokens per call; the
harness must label context-vs-under-review correctly or reintroduce a new FP; cross-file
interaction-bug recall (MD1 R1) is still unmet by Stages 1-2 and depends on the Stage-3
agentic gate; a repo-map (Stage 2) adds an index build + staleness surface.

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt
re-evaluating this decision. Future readers can grep this section when their context
changes to see whether earlier decisions still apply.

`if Stage 1 is ever pointed at a repo not fully owned by the operator — add a secret-screening pass first (the harness ships whole files + branch diff to third-party APIs with no filtering; 2026-07-31 review finding A12). if a re-run of D3/D4 under Stage 1 still reproduces Results 3c or 5 (sibling-commit/heredoc misattribution). if Stage-1 whole-file+branch-diff prompts push per-call cost above the ~$0.33 median band or a sweep above $10. if a cross-file symbol FP rate is measured high enough to justify Stage 2's repo-map build. if a portable OpenRouter model gains reliable, uniform tool-calling that would let #6 satisfy H2/H3. if the production agentic critic is retired, removing the Stage-3 re-verify authority #9 depends on. if a measured cheap-critic recall gain fails to survive the Stage-3 re-verify gate (hypothesis #9 counter-evidence).`
