# 009: Human Feedback Integration — Replace Internal Optimization with External Signal

**Date:** 2026-04-08
**Status:** Accepted

## Context

The self-improvement loop's hypothesis quality guide (`get_hypothesis_quality_guide()`)
was actively steering hypothesis generation toward system-internal behaviors (gate
pass rates, code metrics) and away from external-actor behaviors (workflow adoption,
user experience). This reversed the actual priority: the repo exists to produce
scaffolding useful *outside* the repo, so external workflow impact is the
optimization target.

The guide also framed hypothesis confirmation rate as a metric to optimize, when
in reality confirming hypotheses is not a goal — having significant effects on
external workflows is, and deciding *against* features is just as valuable as
implementing them.

Additionally, the `auto_expire_hypotheses` function would mark hypotheses as
INCONCLUSIVE-EXPIRED when their evaluation window elapsed, but external-impact
hypotheses inherently take longer to gather evidence for. Auto-expiry penalizes
exactly the hypotheses that matter most.

## Options considered

Evaluated via divergent design (15 candidates, pruned to 6 survivors):

1. **Feedback file + no auto-expiry** — simple markdown file for human observations, remove auto-expiry
2. **Two-tier hypothesis system** — separate internal (auto-evaluated) from external (human-evaluated) hypotheses
3. **Periodic review questionnaire** — script that surfaces TRACKING hypotheses with targeted questions
4. **Slash command for feedback** — `/feedback` skill for structured input
5. **Kill hypothesis system entirely** — replace with change log + retrospective
6. **Feedback-as-seed-ideas** — human feedback feeds idea generation, not evaluation

## Decision

Combine options 1 and 3: **feedback file + no auto-expiry + periodic review questionnaire.**

- **Removed** `get_hypothesis_quality_guide()` — the guide was harmful, not just unhelpful
- **Removed** `auto_expire_hypotheses()` — hypotheses stay TRACKING until human feedback resolves them
- **Created** `docs/human-author/feedback.md` — append-only file for human observations with minimal structure (date, observation, confidence)
- **Created** `scripts/hypothesis-review.sh` — reads TRACKING hypotheses from both `hypothesis-log.md` and `hypothesis-backlog.md`, generates targeted questions grouped by external vs. internal priority

The two-tier system (option 2) was rejected because internal-implementation
hypotheses have little standalone value — separating them adds complexity without
meaningful gain.

## Rationale

The key insight is that there are two separate problems: **feedback input** (how
does external signal get in?) and **hypothesis evaluation** (how does the system
decide what worked?). The feedback file solves input; the questionnaire solves
evaluation by making it the system's job to surface what needs human attention
rather than requiring the human to track hypotheses independently.

This aligns with decision 008's philosophy (hypothesis screening) while adding
the missing human-input mechanism.

## Consequences

- **Easier:** Human can contribute observations at any time with any level of
  confidence. The questionnaire tells you what's worth commenting on. Hypotheses
  about external impact are no longer penalized by auto-expiry.
- **Harder:** Hypotheses may accumulate in TRACKING state indefinitely if the
  review script isn't run periodically. No automated evaluation means all
  resolution requires human attention.
- **Future work:** The questionnaire script could scan hook logs
  (`~/.claude/logs/`) to surface usage data automatically, reducing reliance on
  fallible human memory. Interactive mode would allow resolving hypotheses inline
  rather than editing a separate file.
