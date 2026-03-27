# Plan: pr-prep Weak Dimension Remediation

## Scope
Improve the fixable Weak-scored self-eval dimension (testability investment) in `workflows/pr-prep.md`.

## Approach
Add explicit, mechanically checkable completion criteria to pr-prep steps. This gives each step a structured "done" definition that automation could verify, moving testability investment from Weak (requires subjective evaluation with no shortcut) to Adequate (can check structural properties, but quality requires human judgment).

The test coverage dimension (also Weak) is not fixable within the file scope constraint — it requires writing test files in `test/`.

## Steps

### Step 1: Add completion criteria to pr-prep.md (~30 lines added)
Add a "Completion criteria" block after each process step that defines checkable properties. Keep it lightweight — a short bulleted list per step, not a separate section. Format as a fenced checklist within each step.

Criteria to add:
- **Step 1 (clean commit history):** No WIP/fixup commits remain; each commit message follows conventional format; each commit compiles independently.
- **Step 2 (verify CI):** All project checks pass (lint, build, tests). Zero warnings treated as errors.
- **Step 3 (review-fix loop):** Review artifacts exist in `docs/reviews/`; no Must Fix findings remain; Must Address items resolved or explicitly acknowledged in PR description.
- **Step 4 (PR description):** All required sections present (What/How/Test/Uncertainty/Decisions). Each section is non-empty.
- **Step 5 (annotate diff):** If PR uses unfamiliar libraries/patterns, at least one explanatory PR comment exists.
- **Step 6 (size check):** PR is under 500 lines changed, OR size justification is in PR description with suggested review order.
- **Retrospective:** At least one of the four questions answered with more than one sentence. Answer is stored in `docs/thoughts/` or commit message (not lost).

### Step 2: Commit and push

## Risks
- Adding checklists could make the workflow feel bureaucratic. Mitigation: keep criteria brief and frame them as "what done looks like" not "mandatory checklist."
- The criteria could drift out of sync with the steps. Low risk since they're co-located.

## Test specification
N/A — this is a documentation change to a workflow file. Verification is via re-running self-eval, which is outside scope.
