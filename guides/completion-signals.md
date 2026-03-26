# Completion Signals — Quick-Reference Checklist

Yes/no self-check questions for each major phase. If any answer is "no," revisit that phase before moving on.

---

## Research → Plan → Implement (RPI)

### Research
- [ ] Did the research doc identify all invariants that downstream code depends on?
- [ ] Were implementations read (not just signatures) for every relevant function?
- [ ] Did research surface any design decisions that need a Divergent Design sub-procedure?

### Plan
- [ ] Could someone implement each step without re-reading the research doc?
- [ ] Does the test specification cover the failure modes identified in research?
- [ ] Are size estimates included, with files flagged if they'd exceed 500 lines?

### Implement
- [ ] Were tests committed and failing before feature code was written?
- [ ] Does every commit reference the plan step it implements?
- [ ] Was the plan doc updated when any step diverged from the original?

---

## Divergent Design (DD)

### Diverge
- [ ] Were at least 8 candidates generated, including naive, do-nothing, and ideal-if-free options?
- [ ] Are candidates listed without evaluation (no premature pruning)?

### Diagnose & Match
- [ ] Are all constraints labeled as hard vs. soft?
- [ ] Does the compatibility matrix cover every candidate against every constraint?

### Decide & Document
- [ ] Were 2-4 stress-test moves applied to surviving approaches?
- [ ] Is the decision documented in `docs/decisions/` with rationale and consequences?
- [ ] If confidence was below 80%, was the user consulted before deciding?

---

## Spike

### Define
- [ ] Is the spike question stated in one sentence that a "yes/no" or short answer can resolve?
- [ ] Is a timebox set (default: 30 minutes)?

### Execute
- [ ] Was work done on a throwaway `spike/` branch, not the feature branch?
- [ ] Were corners cut appropriately (no unnecessary tests, error handling, or cleanup)?

### Record
- [ ] Does the spike record include a clear answer to the original question?
- [ ] If recommending "proceed," does the RPI seed section list scope, invariants, and gotchas?
- [ ] Are `Last verified` and `Relevant paths` fields populated for freshness tracking?

---

## PR Preparation (pr-prep)

### Clean Up & Verify
- [ ] Does each commit in the final history represent one coherent, independently reviewable change?
- [ ] Do all local CI checks (lint, build, tests) pass?

### Review-Fix Loop
- [ ] Have code-review and self-eval been run at least once?
- [ ] Are all "Must Fix" findings resolved and "Must Address" findings resolved or acknowledged?
- [ ] Did re-review after fixes show convergence (no new findings of equal or higher severity)?

### Write & Ship
- [ ] Does the PR description include "Areas of uncertainty" for anything the author isn't confident about?
- [ ] If the PR exceeds ~500 lines, has splitting been considered and ruled out with justification?
