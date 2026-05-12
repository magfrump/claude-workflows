---
goal: Resolve the permanent N/A placeholder for Token burn rate in morning-summary.
project_state: Branch feat/r1-token-burn-rate-plan — Token Burn Rate section in morning summaries renders "N/A" every run because the upstream data source (`docs/working/token-actuals.json`) never exists. The companion task `r2-token-tracking-narrow` that would have produced it was scoped in r2-project-state-summary-header-plan but never landed.
task_status: complete
---

# Token Burn Rate placeholder — deprecate

## Why deprecate rather than implement

The original r2 plan (docs/working/r2-project-state-summary-header-plan.md) explicitly
scoped this section as a render-only stub waiting for `r2-token-tracking-narrow` to
ship the data file. That task never shipped. As of today:

- `docs/working/token-actuals.json` has never existed in the repo (`git log --all -- docs/working/token-actuals.json` is empty).
- No code anywhere writes the file.
- `_project_state_token_burn` always takes its `[ ! -f "$actuals" ]` branch and emits `Token burn rate: N/A (token-actuals data not available)`.
- The fall-through branch (`echo "Token burn rate: N/A (token-actuals renderer not yet implemented)"`) is unreachable — even if the file appeared, no renderer exists.

Two paths were available:

- **(a) Build the pipeline**: parse Claude session logs, derive per-task tokens, write `token-actuals.json`, and add a real renderer. This is the work of the dropped `r2-token-tracking-narrow` task and well beyond what the constrained file scope of this round allows (would need a logging harness in `self-improvement.sh` and a new parser/script).
- **(b) Remove the placeholder + record the deprecation**: pull the dead section so morning summaries stop carrying it, and log the decision so a future contributor sees why and what would be needed to reintroduce it.

Path (b) was chosen because the constraint is "outcome must be observable in the next morning summary (no middle ground)" — a permanent N/A line is exactly the middle ground we're meant to eliminate. The line has been N/A for every run since r2 landed; either it should compute something or it should not exist.

## Changes

1. `scripts/lib/si-morning-summary.sh`
   - Drop the `_project_state_token_burn` function entirely.
   - Drop the call from `_summary_project_state`.
   - Update the function-level comment listing the project-state subsections so it no longer mentions Token burn rate.

2. `docs/decisions/log.md`
   - Add row #12 documenting the deprecation, with a pointer back to the r2 plan so the reintroduction path is discoverable.

3. `docs/working/morning-summary.md`
   - Regenerate to reflect the new shape (no "### Token Burn Rate" subsection).

## Observability

The next morning summary will not contain a `### Token Burn Rate` heading. Comparing against any prior summary that did is the trivial verification — the section is simply gone.

## How to reintroduce

If/when token actuals are wanted again:
1. Implement the dropped r2-token-tracking-narrow task: emit `docs/working/token-actuals.json` from the SI loop.
2. Reintroduce a `_project_state_token_burn` (or rename to something less stub-shaped) that consumes the file.
3. Re-add the call from `_summary_project_state`.

The decision log row anchors this trail.
