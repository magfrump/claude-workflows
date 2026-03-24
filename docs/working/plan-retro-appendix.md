# Plan: Retrospective Appendix for pr-prep

## Scope
Append a retrospective appendix section to pr-prep.md with 3-4 structured reflection questions. See [research-retro-appendix.md](research-retro-appendix.md).

## Approach
Add a new `## Appendix: Post-PR Reflection` section after the existing step 6. Frame it as a quick check-in to close the loop on the RPI workflow — not a heavyweight retro. Questions reference plan docs and size estimates from RPI to reinforce the workflow system.

## Steps
1. Append the new section to `~/.claude/workflows/pr-prep.md` (~20 lines). Questions:
   - **Plan accuracy**: How closely did the implementation follow the plan? What deviated and why?
   - **Skipped steps**: Were any workflow steps skipped or abbreviated? Was that the right call?
   - **Time vs. estimate**: How did actual effort compare to the size estimates in the plan?
   - **What to change**: What would you do differently next time — in the plan, the process, or the code?

## Testing strategy
- Read the file after editing to confirm the section was appended correctly.
- Verify existing content is unchanged.

## Risks
- None significant. This is an additive documentation change.
