# Plan: failure-mode pass before script generation in user-testing-workflow

## Goal
Add a brief premortem step to `workflows/user-testing-workflow.md` that requires the test designer to name 3 specific failure modes the test should reveal *before* writing tasks/script. The step anchors task design on observable user failures rather than on capabilities the designer hopes to demonstrate, reducing confirmation-test bias.

## Why
Phase 0 already names the riskiest assumption, but "riskiest assumption" is abstract — it doesn't force the designer to commit to concrete observable failures. Without that commitment, tasks tend to drift toward demonstrating the happy path. A short premortem (name 3 failures users might exhibit) turns the abstract risk into testable observations and gives task construction in Phase 1 something specific to target. Keeping the step to 3–5 lines avoids lengthening test prep noticeably.

## Placement
Insert a new subsection **`### Failure-Mode Pass`** at the very top of Phase 1 (`## Phase 1: Session Design`), before `### Task Construction`. Rationale: it's part of session design (so it sits in Phase 1, not Phase 0) but it must happen *before* tasks are written, since tasks should be aimed at the failure modes named.

## Content (target: 4–5 lines)
- Heading
- Instruction: name 3 specific failure modes the test should reveal — observable user behaviors, not designer capabilities
- 2–3 inline examples to anchor what "specific failure mode" means
- Rationale: anchors task design on what could go wrong (confirmation-test bias check)
- Escape valve: if you can't name three, the Phase 0 riskiest assumption is too abstract — revise

## Files touched
- `workflows/user-testing-workflow.md` — add `### Failure-Mode Pass` subsection at start of Phase 1
- `docs/working/r1-user-testing-premortem-step-plan.md` — this plan

## Verification
- Re-read Phase 1 in context — failure-mode pass is unmissable but doesn't crowd out Task Construction
- Line count of added content stays within 3–5 body lines (excluding heading and blank lines)
- Examples are concrete, observable behaviors (not abstract capabilities)
- No other files modified (file-scope constraint)
