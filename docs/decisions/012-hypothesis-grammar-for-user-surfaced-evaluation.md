# Decision 012: Hypothesis Grammar for User-Surfaced Evaluation

**Date:** 2026-05-14
**Status:** Proposed
**Relation:** Extends decision 010 (three-phase model); reinstates per-task hypothesis attachments with a new grammar designed for user evaluation rather than autonomous evaluation.

## Context

Decision 010 deferred all hypothesis evaluation to the morning summary because autonomous Claude-judges-Claude evaluation was producing misleading signal (~50% REFUTED were actually never tested). That diagnosis was correct, but the over-correction was to treat hypotheses as a write-once historical artifact.

In practice the user wants hypotheses to be *load-bearing across rounds*: the morning summary surfaces hypotheses that need evaluation, the user records judgment in `si-input.md`, and the next round's planner reads that signal. This requires more than a passive log — it requires a grammar designed for human recall and judgment, plus preconditions that prevent the loop from prompting for evaluation prematurely.

A divergent-design pass on the vision produced 16 candidates. Four were selected for the core proposal because they are mutually reinforcing rather than competing. Three more are recorded as followups.

## Decision — four pillars

### Pillar 1: Two evaluators with explicit preconditions

Every hypothesis declares:

- `evaluator: script | user` — who actually decides the outcome
- `requires:` — preconditions that must hold for evaluation to be valid (e.g., `metric_logged: latency_p95`, `invocations: 10`, `days_elapsed: 7`)
- `evaluation_window` — when the script checks preconditions, *not* when it forces a verdict

When preconditions are not met within the window, the outcome is INCONCLUSIVE. The script never auto-marks REFUTED — only the user does, via `si-input.md`.

Both evaluator types are first-class: script-evaluated p95-latency claims have the same status as user-evaluated "did the skill surface something I'd have missed" claims, provided each declares appropriate preconditions.

**Target-resolvability rule (generation-time).** A hypothesis may declare `evaluator: script` *only if* it names a concrete, script-checkable target that resolves to one of:

- a path listed in the hypothesis's own `files_touched` (the per-task planning contract enforced by gate 1c — see `guides/validation-gates.md`), or
- a named log the script reads — in practice the pillar-4 invocation logger, identified by the metric/counter name the `requires:` clause already references (e.g., `metric_logged: latency_p95`, `invocations: 10`).

If neither holds — the hypothesis cites no file in its own `files_touched` and names no log the script can read — the planner **must default to `evaluator: user`** at authoring time. This is a *generation-time* gate: it selects the evaluator when the hypothesis is written, upstream of any evaluation-time verdict, and it never changes a verdict (the INCONCLUSIVE-not-REFUTED rule above is untouched).

The rule fixes the recurring "Target unresolvable → switch evaluator to `user`" defect. Previously that switch happened at *evaluation* time: the script reached an open hypothesis, found no resolvable target, and fell back to `user` — but by then the morning summary had already passed, so the hypothesis stranded as un-adjudicable for a round (or indefinitely). Moving the switch to generation time means a hypothesis that can only be judged by a human is *authored* as `evaluator: user` from the start, so it surfaces in the very next summary instead of silently waiting for a script verdict that can never come. Defaulting to `user` is not a demotion: user-evaluated hypotheses are first-class, and an honestly user-evaluable claim adjudicated on time beats a script-labelled claim that never resolves.

### Pillar 2: Adversarial (red-team) framing by default

Hypotheses are written as predicted **failures**, not predicted **successes**:

- ✗ "If we add skill X, code review will catch more bugs."
- ✓ "The most likely failure of skill X is that it triggers on every PR and adds noise without surfacing new issues. We'd see that as: thumbs-down rate > 30% in the first 10 invocations."

Why: the user is more likely to remember and evaluate "did the predicted failure happen?" than "did the predicted success happen?" Optimism bias in the planner is the most common reason hypotheses end up unfalsifiable in practice. This also aligns with the failure-driven design priority already noted in `si-input.md`.

### Pillar 3: Pre-commitment hypotheses from `si-input.md`

The primary source of hypotheses is the user. When writing a priority in `si-input.md`, the user may attach a hypothesis using a stable format:

```
## Priorities

- Build a workflow for failure-driven design
  - hypothesis: I'll know it worked if I reach for it during my next debugging session;
    I'll know it failed if I bypass it for ad-hoc debugging two times in a row.
```

The planner derives features from `si-input.md` intent and inherits the attached hypothesis as the evaluation target. The planner does not invent its own success criteria when the user has provided one.

When the planner *must* invent a hypothesis (a feature emerges from DD or convergence rather than `si-input.md`), it must use the adversarial framing from pillar 2, and the morning summary flags such hypotheses with a `planner-authored` tag so the user knows to review the framing itself.

### Pillar 4: External-watcher invocation logger

A uniform log captures, for every skill and workflow invocation:

- timestamp, name, args (sanitized to redact prompts/PII)
- duration and token count when available from the calling layer
- next-round user reaction (optional: thumbs-up / thumbs-down / disabled / patched)

This logger is the precondition supplier for script evaluators. A hypothesis with `requires: invocations: 10` queries this log; if fewer than 10 invocations have happened, the script defers. Without this logger, the entire script-eval branch of pillar 1 would produce permanent INCONCLUSIVE outcomes.

Constraints:
- Non-intrusive: a single shell hook plus a thin append-only writer, not a wrapper that intercepts arguments
- Resilient: a logging failure must never break a workflow
- Owned by the SI loop: lives in `scripts/lib/` and is read by the morning summary

### Pillar 1b: Round-level claim grammar (extension of pillars 1–3)

The same `evaluator` / `requires` / `hypothesis_window` / `hypothesis_source` grammar pillars 1–3 establish for per-task hypotheses applies at the **round-as-a-whole** scope. The planner appends a `## Hypothesis: this round's claim` section to `docs/working/feature-ideas-round-N.md` whose body is a failure-framed paragraph followed by four structured fields:

```
## Hypothesis: this round's claim

<one paragraph stating the failure-framed claim under pillar-2 adversarial
framing: name the most likely way this round (as a whole) fails to deliver
value, and the concrete observation that would tell you that failure happened.>

- evaluator: script | user
- requires: { metric_logged?: <name>, invocations?: <int>, days_elapsed?: <int> }
- hypothesis_window: <integer rounds before this claim can be evaluated>
- hypothesis_source: user | planner
```

Field names match the per-task schema verbatim (same identifiers in
`tasks-round-N.json`) so a future evaluator can apply one grammar to both
scopes. The fields carry the same semantics as their per-task counterparts:

- `evaluator` — `script` when a separate round-claim evaluator can decide from the invocation logger (pillar 4) without a human judgement call; `user` when only a human observation can decide. Both are first-class. The pillar-1 target-resolvability rule applies at this scope too, with one adaptation: a round claim has no single `files_touched`, so the *only* valid script target is the invocation logger / named log (identified by the metric or counter the round claim's `requires:` references). A round claim that names no such log must default to `evaluator: user`.
- `requires` — preconditions the round-claim evaluator checks before deciding. If unmet, the verdict is INCONCLUSIVE (never auto-REFUTED), matching the rule from decision 010 and pillar 1.
- `hypothesis_window` — integer 1–5 rounds using the same scale as per-task hypotheses (1 = observable in next round's artifacts; 2–3 = requires accumulated usage; 4–5 = requires real-world adoption).
- `hypothesis_source` — `user` when the round's claim was lifted verbatim from a matching `si-input.md` priority's attached hypothesis (pillar 3 applied at round scope); `planner` when the planner authored it. The morning summary tags `planner` round claims so the user can review framing.

The round claim covers the round taken as a unit, not any single task — e.g., "the most likely failure of this round is that the selected tasks collectively don't shift commit-prefix mix toward external-facing artifacts; we'd see that as ≥80% feat(si)-prefixed commits across the next 3 rounds." A claim that just restates one task's hypothesis is not a round claim.

This pillar is **producer-only**: it specifies the planner's output grammar so future rounds emit structured input. The round-claim evaluator that consumes it lives outside this decision and is not yet wired up — until it lands, round claims accumulate in `feature-ideas-round-N.md` files but are not auto-validated; the only validation is whether the four field labels appear in the appended section. Consequently, schema drift between round and per-task grammar would only surface when the evaluator is written, not when the planner emits a malformed section. Keep the field names synchronized with the per-task schema in `scripts/self-improvement.sh`.

## What was added relative to decision 010

- Hypothesis schema gains `evaluator`, `requires`, `evaluation_window` fields
- A generation-time target-resolvability rule: declaring `evaluator: script` requires a script-checkable target in the hypothesis's own `files_touched` or a named log the script reads; otherwise the planner defaults to `evaluator: user` at authoring time (closing the "Target unresolvable → switch evaluator to `user`" defect that stranded open hypotheses)
- `si-input.md` becomes a *source* of hypotheses, not just feedback
- A workflow/skill invocation logger
- A precondition gate in the morning summary that defers outcome rows when `requires:` is unmet
- Adversarial framing as the planner default
- Round-level claim section in `feature-ideas-round-N.md` carrying the same `evaluator` / `requires` / `hypothesis_window` / `hypothesis_source` grammar as per-task hypotheses (pillar 1b)

## What stays from decision 010

- Non-interactive autonomous execution
- Morning summary as the single mid-loop output channel
- INCONCLUSIVE ≠ REFUTED rule
- No inter-round autonomous hypothesis evaluation (this proposal does not reinstate steps 1b/4b convergence detection in `scripts/self-improvement.sh`)

## What this does NOT do

- Does not enforce an internal-vs-external task-mix gate — both kinds of work have value
- Does not autonomously mark hypotheses REFUTED
- Does not introduce additional Claude-judges-Claude evaluation
- Does not build full telemetry infrastructure — the logger is intentionally minimal

## Implementation order

1. **Pillar 4 (logger)** first — it's the substrate the script-evaluator preconditions depend on, and it can be built and validated independently.
2. **Pillar 1 (two-evaluator + preconditions)** — schema change in the planner prompt + precondition gate in the morning summary.
3. **Pillar 2 (adversarial framing)** — planner prompt rewrite. Mechanical once the schema is settled.
4. **Pillar 3 (pre-commitment from si-input)** — `si-input.md` format extension and planner integration.

## Followups deferred from the DD pass

These were strong candidates not in the core but worth revisiting once the four pillars have been in operation:

- **Multi-evaluator with convergence/divergence signal** (DD candidate #2). A single hypothesis carrying *both* a script claim and a user claim, where agreement marks CONFIRMED and disagreement is itself a flagged signal worth surfacing. Less self-referential than a "council of evaluators" because the script's verdict is grounded in the invocation logger (pillar 4), not in another Claude call. Adopting this requires pillars 1 and 4 to be solid first.

- **Survey-style morning summary** (DD candidate #12). Render open hypotheses as a single Likert-scale survey instead of one-question-per-hypothesis prose. Reduces user friction but only matters once there are enough open hypotheses to warrant batching. Worth revisiting after ~3 rounds of operation.

- **Periodic skill-level audit** (DD candidate #15). Every N rounds, run a "does each skill still earn its keep?" pass at the skill level rather than the change level. Different time scale than per-feature evaluation; complementary rather than substitutionary. Likely useful once the invocation logger has accumulated ~30 days of data.

## Consequences

- Hypothesis fields stay in the task schema (against the SI-script review's recommendation to drop them); they are the user's input-output surface, not the script's bookkeeping.
- The planner prompt (search `scripts/self-improvement.sh` for "Hypothesis guidance (decision 012 pillar 2") is rewritten to require adversarial framing and to derive intent from `si-input.md` first.
- The target-resolvability rule (pillar 1) is **producer-grammar specification only** in this revision: it defines what the planner must emit but is not yet wired into the planner prompt. Teaching the prompt to apply the rule — emit `evaluator: script` only when a resolvable target exists, else `evaluator: user` — is a deferred followup against `scripts/self-improvement.sh`, intentionally out of scope for this revision so the grammar can land without a script edit. Until that wiring lands, the rule is the normative authoring contract a reviewer checks hypotheses against, mirroring how pillar 1b is producer-only with its evaluator unwired.
- The ideas-generation prompt earlier in `scripts/self-improvement.sh` is extended to require a `## Hypothesis: this round's claim` section in `feature-ideas-round-N.md` carrying the same three structured fields per-task hypotheses do (pillar 1b).
- A new invocation logger lives in `scripts/lib/` (path tbd at implementation time) and is sourced by the morning summary.
- Steps 1b and 4b in `scripts/self-improvement.sh` (convergence detection / problem-history) remain candidates for deletion per the SI-script review — they are Claude-judges-Claude evaluation that this decision does not depend on and does not reinstate.
