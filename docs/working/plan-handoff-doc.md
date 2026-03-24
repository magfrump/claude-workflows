# Plan: Cross-session Handoff Doc Format

## Scope
Add a lightweight handoff document format to the RPI workflow so that session state can be captured at session end and loaded by the next session. See [research-handoff-doc.md](research-handoff-doc.md).

## Approach
Extend RPI step 6 ("Verify and loop") with an optional "Session handoff" sub-step that fires when ending a session mid-task. Define a markdown template with fields for timestamp, accomplishments, unfinished work, open questions, and file paths. Place handoff docs in `docs/working/` following the existing naming convention.

## Steps

1. **Add handoff doc format and guidance to RPI step 6** (~40 lines added to `workflows/research-plan-implement.md`). Insert a new sub-section after the existing bullet points in step 6. Include:
   - When to write a handoff doc (ending mid-task, context getting heavy)
   - The markdown template with fields
   - Where to save it (`docs/working/handoff-{topic}.md`)
   - How the next session should use it

2. **Add handoff reference to "Context management" in step 5** (~2 lines). Add a sentence pointing to the handoff format as the recommended checkpoint mechanism, connecting the existing "consider starting a fresh session" advice to the new format.

3. **Add handoff reference to "Continuation" in the skip/abbreviate section** (~2 lines). The existing "Continuation of a previous session's work" bullet should mention loading the handoff doc alongside research/plan docs.

## Size estimate
~45 lines total added to one file. Well under any size concern.

## Testing strategy
- Read the modified file and verify the template renders correctly in markdown
- Verify the new sub-section integrates naturally with step 6's flow
- Verify cross-references from step 5 and the skip/abbreviate section are accurate

## Risks
- The template could be too heavy (too many fields) or too light (missing critical info). The proposed fields (timestamp, accomplishments, unfinished work, open questions, file paths) are the minimum useful set based on the task description.
- Risk of the format diverging from the spike's RPI seed format, creating inconsistency. Mitigated by noting the different purpose in the doc.
