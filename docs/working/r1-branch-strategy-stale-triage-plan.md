- **Goal**: Add an advisory stale-branch triage protocol to `workflows/branch-strategy.md`. Trigger: feature branch >7 days old without merge or rebase. Prompts a 3-question triage and accepts a do-nothing-this-week answer that refreshes the date stamp.
- **Project state**: r1 task on `feat/r1-branch-strategy-stale-triage`; only `workflows/branch-strategy.md` may be modified (plus this plan doc).
- **Task status**: in-progress (planning → implementation)

## Design

Add a new section near the end of `workflows/branch-strategy.md` (after "Setting up or resetting dev", before "Quick reference"). The section:

1. **Header + advisory framing preamble.** State the trigger (>7 days since last merge/rebase activity on the branch), make explicit that this is advisory (a self-check, not a gate, no automation should refuse to merge a stale branch).
2. **The 3-question triage.** Phrased as questions to answer to yourself, not a checklist a tool enforces:
   - Still relevant? (does the feature still match current priorities / has the underlying problem changed?)
   - Still owner? (am I the right person, or has someone else picked it up?)
   - Still highest priority? (vs. other active branches I'm carrying)
3. **Three valid outcomes.** Map each outcome to a concrete action:
   - **Action** — rebase onto main + merge into dev OR open PR now. Resets the implicit clock by virtue of activity.
   - **Defer** — close PR / delete branch / file an issue with the work-in-progress notes. The branch is no longer carried.
   - **Mark watching** — explicitly accept "do nothing this week." Refresh the stamp via an empty `git commit --allow-empty -m "chore: still watching feat/X"` (or equivalent activity that updates the branch's last-commit date). This documents that the branch's stalled state is intentional, not forgotten.
4. **Quick-reference row** appended to the existing table so the trigger is visible at a glance.

## Why advisory, not a gate

- The user's CLAUDE.md emphasizes external impact and avoids over-engineering. A hard gate adds friction for a problem (stale branches) that's better solved by a periodic self-check.
- Branch staleness has legitimate causes — paused work, waiting on a dependency, deliberate watching. A gate would force premature commitment to defer/close.
- The advisory framing is consistent with the rest of branch-strategy.md, which uses prescriptive rules sparingly (only for the disposable-dev invariant).

## Placement

End of file, just before "Quick reference," because:
- The "Handling many feature branches" section already touches on stale-branch hygiene ("Don't keep stale branches.") — the new section deepens that one-liner into a procedure.
- Putting it after "Setting up or resetting dev" puts both maintenance-y procedures (dev reset, branch triage) together.
- Quick-reference belongs last; adding to its table is the right way to surface the new trigger.

## Risk / non-goals

- No automation. The trigger ("7 days") is a heuristic the developer applies, not something a script enforces. Avoids the SI-style bias toward measurability over external impact called out in memory.
- No change to existing rules or invariants. Purely additive.
- Date-stamp refresh leans on git's own last-commit date; no new metadata file or convention.
