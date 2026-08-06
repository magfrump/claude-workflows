# Review-arms set: low-cost test of different review processes

**Date**: 2026-08-06 · **Follows**: decision 030 (lightweight review path), decision 021
(Stage-1 context harness) · **Artifact**: `scripts/review-arms.py`

## What this is

The runnable packaging of decision 030's queued arm portfolio: a small set of named
review-process configs that can all be pointed at a local project's branch and compared
side by side at ~$0.03–0.35/call (vs ~$14.6/instance for the agentic `code-review`
orchestrator). The engine is `scripts/cross-model-review.py --context-base` unchanged;
the wrapper adds arm naming, a shared output layout, the k=3 consensus filter (the one
piece 030 queued that didn't exist yet), and a cross-arm summary.

## The arms

| Arm | 030 id | Config | Hypothesis (from 030) |
|-----|--------|--------|------------------------|
| `base` | [0] | Stage-1 context, k=1, `anthropic/claude-sonnet-5` | judge-parseable findings, median ≤ $0.35/call |
| `small` | [3] | same, `openai/gpt-5.6-sol` | ≥60% of base's verified-bug recall at ≤⅓ cost |
| `k3` | [7] | same as base, k=3, keep findings ≥2 replicates agree on | cuts FP-class findings ≥30% vs k=1 |

Not built: [8] rubric/checklist call — 030 demoted it to build-only-if-base-precision-
proves-deficient.

The consensus filter reuses the engine's two-stage matching (deterministic
file+line-overlap pre-filter, then the pinned stage-2 judge when `OPENROUTER_API_KEY`
is set; stage-1-only matching without a key — looser but free and deterministic).
Kept clusters land in `<out>/k3/consensus.json` with their replicate votes.

## Usage

```
export OPENROUTER_API_KEY=sk-or-...
scripts/review-arms.py --repo /path/to/project --range 'main..HEAD' \
    --context-base main --out runs/review-arms/<project>-<date>
# cost preview first (no API calls):
scripts/review-arms.py ... --dry-run
# subset: --arms base small
```

Outputs: per-arm `findings.jsonl` + `overlap.json` (engine), `k3/consensus.json`,
and a cross-arm `arms-summary.json` (finding counts raw/consensus, token usage,
errored-run counts).

## Verified 2026-08-06

- Dry run against this repo (`82318e8~1..82318e8`, base `82318e8~4`): all three arms
  build **byte-identical prompts** (sha `e4375d1e069c`) — the 021 confound control
  survives the wrapper.
- Consensus filter offline test: 3 replicates with one shared finding (jittered lines)
  and two singletons → 3 clusters, 1 kept with votes {1,2,3}; errored runs excluded.
- No live calls made yet (no API key in this session).

## Cautions (restated from 021/030)

- Stage-1 context ships **whole repo files + branch diff** to third-party APIs, no
  secret screening. Operator-owned repos only; otherwise add a screening pass first.
- Two-dot ranges only with `--context-base` (three-dot makes sibling context overlap
  the reviewed diff — see `split_range` docstring).
- **Pick `--context-base` tightly.** The sibling section inlines the whole diff from
  the base to the range start; on a merge-heavy branch a loose base explodes the
  prompt (observed 2026-08-06 on meta-formalism-copilot: base `HEAD~10` → 789 KB
  sibling diff, ~210k tokens/call; base at the range start → ~12k tokens). When the
  range under review *is* the branch tip, set `--context-base` equal to the range
  start (empty sibling section; you still get the enclosing files). The sibling
  section only earns its tokens when reviewing a mid-branch slice whose sibling
  commits are themselves modest. Always `--dry-run` first and read the token line.
- Repos without a `main` branch need explicit refs (the wrapper preflights these and
  lists local branches on failure).
- Findings are *candidate* findings: the agentic critic remains the production
  re-verify authority (021 Stage 3); arm output is loop/benchmark signal, not verdicts.

## Next step

A first live low-cost comparison: pick 2–3 recent real branches/changesets (this repo
or another operator-owned local project), run all three arms with `--dry-run` first to
confirm the cost band, then live; compare `arms-summary.json` counts and spot-check
whether `k3` consensus drops noise vs `base`, and whether `small` catches the bugs
`base` catches. 030's counter-evidence lines are the kill criteria.
