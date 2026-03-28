# Completion Signals Checklist

Quick-reference yes/no checks for each workflow phase. Use these to confirm a phase is actually done before moving on.

---

## Research → Plan → Implement (RPI)

### Scope
- [ ] Can you state what this loop covers in one sentence?
- [ ] Is the scope narrow enough to research, plan, and implement in one session?

### Research
- [ ] Did you read implementations (not just signatures) of the relevant code?
- [ ] Does your research doc include invariants — things that must not break?
- [ ] If 3+ viable approaches surfaced, did you run a design decision process before planning?

### Plan
- [ ] Could someone implement each step without re-reading the research?
- [ ] Does every step that creates or modifies a file include a size estimate?
- [ ] Does the test specification exist and cover at least the happy path and one failure case?

### Implement
- [ ] Were tests written and committed before feature code?
- [ ] Does each commit reference the plan step it implements?
- [ ] Did you run the full test suite after the final step?

---

## Divergent Design (DD)

### Diverge
- [ ] Did you generate at least 8 candidates?
- [ ] Do candidates include at least one "do nothing" option and one unconventional option?

### Diagnose
- [ ] Are constraints stated as concrete, testable conditions (not vague qualities)?
- [ ] Did you distinguish hard constraints from soft preferences?

### Match and Prune
- [ ] Does the compatibility matrix cover every hard constraint for every surviving candidate?
- [ ] Were candidates with a hard-constraint violation actually eliminated?

### Tradeoff and Decision
- [ ] Did you apply at least 2 stress-test moves to each finalist?
- [ ] If confidence is below 80%, did you stop and consult the user instead of picking?
- [ ] Is the decision documented with rationale and consequences?

---

## Spike

### Define
- [ ] Is the spike question stated as a single, falsifiable sentence?
- [ ] Is the timebox set before starting work?

### Execute
- [ ] Are you working on a throwaway branch (not main or a feature branch)?
- [ ] Are you cutting corners on code quality to stay within the timebox?

### Record
- [ ] Does the finding directly answer the original question?
- [ ] If recommending "proceed," does the record include an RPI seed section?
- [ ] Did you note what the spike did NOT answer?

---

## PR Preparation

### Clean Up
- [ ] Is each commit in the final history a single coherent, independently reviewable change?
- [ ] Do all local CI checks pass (lint, build, tests)?

### Review-Fix Loop
- [ ] Have you run code review and self-eval at least once?
- [ ] Are all "Must Fix" findings resolved?
- [ ] Are "Must Address" findings either resolved or explicitly acknowledged?

### PR Description
- [ ] Does the description explain what changed, how it works, and how to test it?
- [ ] Are areas of uncertainty flagged for the reviewer?
- [ ] If the PR exceeds ~500 lines, have you considered splitting it or documented why not?
