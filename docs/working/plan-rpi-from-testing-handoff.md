# Plan: RPI From-Testing Handoff

## Scope
Add a `← From Testing` pivot entry to RPI's "When to pivot" section. See `docs/working/research-rpi-from-testing-handoff.md`.

## Approach
Add one bullet point after the existing `← From Bug Diagnosis` entry, following the established pattern of inbound pivots. The text references user-testing-workflow Phase 4 (findings report) and specifies that severity-rated issues and the prioritization matrix replace broad exploration.

## Steps
1. Add `← From Testing` bullet to `workflows/research-plan-implement.md` "When to pivot" section, after `← From Bug Diagnosis`. (~3 lines added)

## Size estimate
~3 lines added to existing file. File remains well under 500 lines.

## Test specification
This is a documentation-only change. No automated tests apply. Verification: the new entry is consistent with user-testing-workflow's outbound `→ RPI` pivot text, follows the pattern of existing inbound pivots, and the file renders correctly.

## Risks
- The CLAUDE.md "How workflows compose" section doesn't mention this handoff path. That's a separate change outside the file scope constraint.

## Hypothesis traceability
The task hypothesis predicts this pivot will be referenced in at least 1 real user-testing-to-RPI transition within 3 rounds. Observable evidence: commit messages or working docs citing "From Testing" or referencing the findings report as RPI research input. The entry itself includes "Reference the findings doc from your research and plan docs for traceability" to encourage this citation pattern.
