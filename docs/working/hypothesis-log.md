# Hypothesis Log

Tracks falsifiable predictions made at task creation time and their outcomes.

| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Evidence |
|-------|---------|------------|--------|------------------|---------|----------|
| 1 | research-doc-freshness | After adding freshness fields to templates, at least 1 document produced by these workflows in the next 3 rounds will include Last verified and Relevant paths fields, enabling a staleness check that would not have been possible before. | 3 | 4 | CONFIRMED | Round 3 self-eval baseline reports (self-eval-fact-check.md, self-eval-code-review.md, self-eval-cowen-critique.md) include Last verified and Relevant paths fields, enabling staleness checks that were not possible before the template changes. |
| 1 | complexity-budget-enforcement | The complexity check will flag at least 1 workflow as exceeding the 200-line or 15-section threshold on its first run, making growth visible to the self-improvement loop. | 3 | 5 | CONFIRMED | user-testing-workflow.md (345 lines, 16 sections) exceeds both the 200-line and 15-section thresholds and has done so since the complexity check was first added in round 1, flagging it on every run. |
| 2 | validation-gate-docs | Tasks implemented in the next 3 rounds will have a lower gate-failure rate than Round 1's 67% (2 of 3 rejected). Specifically, 0 tasks will fail on file_scope or shellcheck gates. | 3 | 5 | REFUTED | Gate-failure rate dropped to 33% (3/9) vs Round 1's 67%, but the specific claim of zero file_scope/shellcheck failures is refuted — 3 tasks failed file_scope gates across Rounds 3–4 (subtraction-mode, critic-test-harness, convergence-detection-unit-test). |
