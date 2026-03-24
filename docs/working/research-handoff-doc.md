# Research: Cross-session Handoff Doc Format

## Scope
Add a lightweight handoff document format to the RPI workflow so that session state can be captured at session end and loaded by the next session.

## What exists

### RPI workflow (`workflows/research-plan-implement.md`)
- Step 6 "Verify and loop" is the final step. It runs checks, updates `docs/thoughts/`, then either loops or proceeds to pr-prep.
- No mechanism for capturing session state when ending mid-task (not at a natural loop boundary or PR point).
- `docs/working/` is the established location for disposable session artifacts (research-*, plan-*).
- The "Context management" note in step 5 mentions starting fresh sessions and loading plan docs, but doesn't define what to capture.

### Session hygiene (CLAUDE.md)
- "Fresh session for implementation" — acknowledges that sessions should load artifacts, not rely on conversational context.
- "Context budget awareness" — notes degradation after ~10-20 min, recommends breaking into steps with checkpoints.
- Neither defines a checkpoint/handoff format.

### Prior art: Spike workflow handoff
- The spike workflow has an "RPI seed" section — a structured handoff from spike to RPI research phase.
- Fields: scope, known invariants, relevant files/APIs, gotchas, what the spike did NOT answer.
- This is a cross-workflow handoff; the new format is a within-workflow, cross-session handoff. Different purpose but similar structure.

### `docs/thoughts/`
- Living documents for knowledge that persists across sessions.
- Not appropriate for session-specific state (what step you're on, what's unfinished).
- Handoff docs should live in `docs/working/` since they're disposable.

## Invariants
- RPI step numbering (1-6) is referenced by other docs and commit messages. Adding a step vs. extending step 6 matters.
- The `docs/working/` naming convention (`{type}-{topic}.md`) should be followed.
- The handoff must be optional — many sessions end cleanly at a loop boundary or PR and don't need one.

## Gotchas
- Adding a new step 7 would be a larger structural change and could confuse references. Better to extend step 6 with an optional sub-step.
- The handoff doc must be lightweight enough that writing it doesn't feel like overhead — otherwise it won't be used.
- The spike's RPI seed format is close but not quite right — it's designed for "here's what to research" rather than "here's where I am in implementation."
