# Research: pr-prep Weak Dimension Remediation

## Scope
Identify which Weak-scored self-eval dimensions on `workflows/pr-prep.md` are fixable by modifying the workflow itself, and how.

## Current Weak Scores

### 1. Testability investment (Weak)
**Justification from self-eval:** "pr-prep is a multi-step process workflow. Its quality is measured by process outcomes (clean commits, passing CI, good PR descriptions, converging review loops), not structured output."

**Analysis:** The root cause is that pr-prep produces unstructured artifacts (PR descriptions, commit messages, retrospective prose). The rubric says Adequate requires "can check structural properties and planted-flaw detection, but quality requires human judgment." If pr-prep defined structured, checkable output artifacts — a completion checklist, structured PR description template with required fields, defined completion criteria per step — automated checks could verify structural compliance even if quality remains a human judgment call.

**Fixability:** Partially fixable. Can move from Weak → Adequate by adding structured completion criteria and checkable artifacts. Cannot reach Strong because workflow quality is inherently subjective.

### 2. Test coverage (Weak)
**Justification from self-eval:** "No automated tests reference pr-prep. No example output artifacts exist showing the workflow followed end-to-end."

**Analysis:** This dimension measures *current evidence*, not potential. Improving it requires writing tests (in `test/`) or producing example output artifacts (in `docs/reviews/`). Both are outside the file scope constraint (only `workflows/pr-prep.md` and `docs/working/` can be modified).

**Fixability:** Not fixable within file scope. This is a structural constraint of the task, not of the workflow. The workflow itself could be made more testable (see dimension 1), but actual test coverage requires writing test files.

## Prior Art
The rubric's scoring guidance for workflows says: "Workflows: can you test the artifacts produced, or only the process?" This suggests the path to Adequate testability is to make pr-prep produce artifacts with checkable properties.

Looking at the current pr-prep.md:
- Step 1 (clean commit history) — output: git history. Checkable: each commit is one coherent change.
- Step 2 (verify CI) — output: passing checks. Already checkable.
- Step 3 (review-fix loop) — output: review artifacts in docs/reviews/. Checkable: artifacts exist, findings converge.
- Step 4 (PR description) — output: PR description text. Checkable: required sections present.
- Step 5 (annotate diff) — output: PR comments. Partially checkable.
- Step 6 (size check) — output: assessment. Checkable: line count vs threshold.
- Retrospective — output: unstructured prose. Not checkable.

Steps 1, 2, 3, 6 already have implicit checkable properties. Steps 4 and 5 have partial structure. The retrospective has none.

## Conclusion
- **Testability investment:** Fixable (Weak → Adequate) by adding explicit completion criteria and structured output expectations to each step.
- **Test coverage:** Not fixable within file scope constraint. Requires `test/` files.

Only one Weak dimension is remediable. The fix is modest: add a "Completion criteria" subsection or checklist to pr-prep steps that defines mechanically verifiable properties of each step's output.
