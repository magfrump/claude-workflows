# Self-Evaluation: research-plan-implement

**Target:** `workflows/research-plan-implement.md` | **Type:** Workflow | **Evaluated:** 2026-03-26
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions
**Context:** Re-evaluation after `feat/foreground-tests` branch changes (test foregrounding in plan + implementation phases)

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | RPI produces structured artifacts (research docs, plan docs with test specification tables, test commits, implementation commits referencing plan steps) whose structural properties are checkable. The new test specification table format makes plan-level test design more mechanically verifiable (required columns: test case, expected behavior, level, diagnostic expectation). However, testing whether the *process* prevents mistakes still requires counterfactual comparison, and the new test-first gate adds another process step that's hard to verify automatically. Medium investment: structural compliance is feasible; process quality remains hard. |
| Trigger clarity | Strong | "Any non-trivial feature or bug fix" remains the broadest yet clearest trigger. CLAUDE.md designates it the default workflow. "When to skip or abbreviate" handles false positives. No ambiguity with siblings: spike handles feasibility, DD is invoked *from within* RPI, task-decomposition parallelizes research, onboarding is pre-task, pr-prep follows RPI. The test-strategy skill's description now correctly references "test specification" (per the code review fix), and its trigger ("when an RPI plan needs a testing strategy") is complementary rather than overlapping — test-strategy produces *what to test*, RPI's test specification section captures the human's design decisions about those tests. |
| Overlap and redundancy | Strong | No other workflow provides research→plan→gate→test-first→implement with committed artifact trail. The expanded test specification section might appear to overlap with the `test-strategy` skill, but they serve different roles: test-strategy is an analytical skill that recommends what to test based on code analysis; RPI's test specification is where the human records their test design decisions in the plan. RPI explicitly cross-references test-strategy ("the `test-strategy` skill has a full taxonomy") for the complete test level list. No built-in Claude Code capability provides this structure. |
| Test coverage | Weak | No automated tests in `test/` for RPI workflow compliance. Real-world usage evidence remains substantial (6+ research-plan pairs in archived working docs, 16+ commits referencing RPI, multiple self-eval and review artifacts). The branch itself demonstrates RPI usage — the decision record, code review rubric, and review artifacts were produced following the workflow. However, the new test specification format has zero usage evidence yet: no plan doc in `docs/working/` contains the new table format, and the test-first gate (step 5) has not been exercised on a real implementation task. The branch adds process steps that are entirely untested in practice. Still Weak: probationary for the new additions. |
| Pipeline readiness | Strong | RPI remains the top-level workflow and central integration point. It receives input from spike, onboarding, and task-decomposition. It invokes DD as a sub-procedure. It feeds into pr-prep and review-fix-loop. Branch-strategy references it as the working methodology. The test foregrounding changes don't alter pipeline relationships — they add internal structure (test specification in plans, test-first gate in implementation) rather than new pipeline connections. Standalone viable and pipeline root. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does:** RPI enforces a four-phase discipline: scope → research (committed artifact with required sections) → plan (with test specification table, size estimates, risks) → human gate → test-first implementation (write failing tests, human reviews tests, then implement). The `feat/foreground-tests` branch expands two areas: (1) the plan's testing section is restructured from a one-liner ("testing strategy: how to verify") into a structured table with test case, expected behavior, level, and diagnostic expectation columns, plus inline taxonomy guidance; (2) a new test-first gate in step 5 requires tests to be committed and reviewed before implementation code is written.

**What ad-hoc process achieves:** Without RPI, tests are typically an afterthought — written after implementation to confirm what already works, or skipped entirely for "simple" features. A generic prompt like "write tests first" captures the broad idea but misses: (a) the structured specification format that forces the human to think about test levels and diagnostic expectations during *planning*, (b) the separation of test design (human in plan) from test implementation (LLM in code), (c) the explicit human checkpoint on test code before implementation investment.

**What built-in tools cover:** Claude Code's verification-coordinator handles test planning after implementation, not before. It doesn't provide the plan-time specification or the test-first gate. The test-strategy skill recommends what to test but doesn't embed that recommendation into a human-reviewed plan.

**Questions for the reviewer:**
- Does the test specification table format actually change your planning behavior, or does it feel like form-filling? The value proposition is that the table forces you to think about diagnostic expectations — but only if you actually engage with the column rather than writing "should show error" for every row.
- Has the test-first gate (step 5) been followed on any real implementation since this branch? If not, this is a process prescription with zero empirical validation.
- Is the gap "the human designs better tests because of the structured format" or "the human designs any tests at all because the format makes it a required step"? These have different implications for how the section should evolve.
- Under what conditions is the diagnostic expectation column most valuable — complex integration tests where failure output is ambiguous, or is it useful even for straightforward unit tests?

### User-Specific Fit

**Triggering situations:**
- Any feature implementation touching more than one file
- Bug fixes where root cause is not immediately obvious
- Any task requiring understanding existing code before changing it
- Default for all non-trivial development work
- The test foregrounding additions are specifically motivated by "code development in other repos" (per decision record 006)

**Questions for the reviewer:**
- How often do you perform non-trivial development work with Claude Code? Is this frequency increasing?
- The decision record notes the motivating use case is "code development in other repos." How much of your current work is in other repos vs. this workflow repo itself? The test specification format is designed for code with executable tests — does that match your primary use case?
- Do you actually follow the test specification table format when planning, or do you abbreviate to prose? The "for simple features, this section can be brief" escape valve may mean the table is rarely used in practice.
- The test-first gate adds a human checkpoint. Do you want more checkpoints (catching mismatches early) or fewer (reducing friction)?

### Condition for Value

**Stated or inferred conditions:**
- The user must do development work involving testable code (the test specification section assumes executable tests exist or can be written)
- The project must have a testing framework and conventions (the test-first gate assumes tests can be committed and run)
- The human must engage with the test specification during planning (if rubber-stamped, the structured format adds overhead without value)
- The LLM must write tests that match the specification (if tests are written to match implementation rather than spec, the test-first discipline collapses)

**Automated findings:**
- `docs/working/` directory EXISTS with artifacts from multiple development rounds: CONFIRMED
- CLAUDE.md references RPI as the default workflow: CONFIRMED
- Decision record 006 accepted with status "Accepted": CONFIRMED
- Code review rubric passed with conditional status (A4 open but justified): CONFIRMED
- test-strategy skill cross-reference updated to match new terminology: CONFIRMED
- No plan doc in `docs/working/` yet uses the new test specification table format: NOT FOUND
- No evidence of the test-first gate being exercised on a real implementation: NOT FOUND

**Questions for the reviewer:**
- Are you currently working in projects with established testing frameworks where the test-first gate is practical?
- The test specification format was designed via divergent design (12+ approaches, 6 survivors, 3 combined). Does the design feel right, or has something been lost in the combination?
- Is this an investment pulling toward better test discipline across your projects, or speculative process that may not survive contact with real implementation pressure?

### Failure Mode Gracefulness

**Output structure:** RPI produces research docs, plan docs (now with structured test specification tables), test commits (new), and implementation commits referencing the plan. The test specification table makes test design visible and reviewable. The test-first gate adds a checkpoint between plan approval and implementation.

**Potential silent failures:**
- **Test specification becomes cargo cult.** The human fills in the table columns mechanically — every test gets "unit" level and "should show expected vs actual" diagnostic expectation. The structure exists but doesn't produce better test design than a one-liner would have. This is hard to detect because the artifact *looks* thorough.
- **Test-first gate degrades to test-alongside.** The LLM writes tests and implementation together, commits tests first retroactively, and the human reviews everything at once. The process appears followed but the temporal discipline (tests before implementation) is lost. Commit timestamps could detect this, but only if someone checks.
- **Diagnostic expectation column ignored during test implementation.** The plan specifies rich diagnostic expectations, but the actual test code uses bare assertions. The gap between plan and code is invisible unless someone cross-references them.
- **Test specification inflates plan review burden.** The reviewer now has more to review in the plan doc, potentially leading to faster/shallower review of the non-testing sections (approach, risks). The testing section's thoroughness cannibalizes attention from other sections.
- **Prior failure modes remain:** Shallow research that looks thorough, plan approved without meaningful review, scope creep during implementation, DD invocation missed. The test foregrounding changes don't mitigate these.

**Pipeline mitigations:** The artifact trail (committed docs + test commits) enables post-hoc auditing. The test-first gate is itself a mitigation for the "test specification becomes aspirational" failure mode identified in the prior self-eval. The pr-prep workflow's review-fix loop provides a second review layer. The code review skill can check whether test code matches the plan's test specification.

**Questions for the reviewer:**
- Have you seen the "cargo cult" failure mode in test specifications — filling in tables without engaging with the columns?
- When reviewing a plan with a test specification table, do you actually read the diagnostic expectation column, or does your attention focus on test cases and expected behavior?
- Is the test-first gate something you're willing to enforce (including reviewing test code separately), or does it feel like an extra round-trip that will be skipped under time pressure?

---

## Key Questions

1. **Has the test foregrounding been validated by real use?** The test specification table format and test-first gate are process prescriptions with zero empirical evidence. The decision record describes the *design rationale* (tests as behavioral specification, diagnostic output as human interface), and the code review confirms *internal consistency*, but neither demonstrates that the process works in practice. The strongest validation would be a real implementation task using the new format — does the structured test specification actually improve test quality or catch mismatches earlier? Until that evidence exists, this is a well-designed hypothesis, not a proven process improvement.

2. **Does the added weight justify the added precision?** The prior self-eval's Key Question 3 asked whether RPI had grown too heavy. This branch adds ~40 lines to the plan section (test specification table, taxonomy guide, diagnostic expectations) and ~15 lines to the implementation section (test-first gate with human checkpoint). For complex features, this structure likely pays for itself. For mid-complexity tasks (the workflow's sweet spot), there's a risk that the test specification table becomes overhead that discourages thorough test planning rather than encouraging it. The "for simple features, this section can be brief" escape valve is important — but escape valves tend to become the default.

3. **Is the test-strategy skill relationship clear to users?** RPI's test specification section and the test-strategy skill serve complementary but potentially confusing roles. RPI's section is where the human *records* test design decisions; test-strategy is where the LLM *recommends* what to test. The cross-reference exists ("the `test-strategy` skill has a full taxonomy"), but a user encountering the test specification table for the first time might wonder: "Should I run the test-strategy skill first, or fill this out myself?" The answer seems to be "either, depending on complexity," but this isn't stated.
