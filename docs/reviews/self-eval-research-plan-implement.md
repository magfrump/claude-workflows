# Self-Evaluation: research-plan-implement

**Target:** `workflows/research-plan-implement.md` | **Type:** Workflow | **Evaluated:** 2026-03-26
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | RPI produces structured artifacts (research docs with required sections, plan docs with required sections, commits referencing plan steps) whose structural properties can be checked. However, testing whether the *process* prevents mistakes requires counterfactual comparison — you would need to show that the same task done without RPI produced worse results, which is inherently expensive. The artifact structure makes medium-investment structural testing feasible; quality and process adherence testing remains hard. |
| Trigger clarity | Strong | "Any non-trivial feature or bug fix" is the broadest yet clearest trigger in the repo. CLAUDE.md designates it the default workflow. The "When to skip or abbreviate" section explicitly handles false positives (trivial changes, code already understood, urgent hotfixes, continuations). No ambiguity with siblings: spike answers feasibility questions, DD is invoked *from within* RPI, task-decomposition parallelizes RPI's research phase, onboarding is a pre-task activity, and pr-prep follows RPI. Each boundary is documented with bidirectional pivot guidance. |
| Overlap and redundancy | Strong | No other workflow provides research-then-plan-then-gate-then-implement with committed artifact trail. Task-decomposition explicitly feeds *into* RPI (step 5: "follow the normal research-plan-implement workflow"). The refactoring variant is internal to RPI, not a separate workflow. DD is a sub-procedure invoked from step 2, not an alternative. Branch-strategy references RPI as the working methodology. No built-in Claude Code capability provides this structure. |
| Test coverage | Weak | No automated tests exist in `test/` for RPI. The `test/hooks/log-usage.bats` and `test/scripts/skill-usage-report.bats` reference RPI only in the context of usage tracking, not workflow validation. However, real-world usage evidence is substantial: the `docs/working/archive/` directory contains multiple research-plan pairs (`research-self-eval-skill.md` / `plan-self-eval-skill.md`, `research-convergence-detection.md` / `plan-convergence-detection.md`, `research-doc-freshness.md` / `plan-doc-freshness.md`, and several others from multiple development rounds). Git history shows 16+ commits directly referencing RPI. The prior self-eval and the full-evaluation both exist in `docs/reviews/`. Despite this usage evidence, no structural compliance checks exist (e.g., verifying that research docs contain all required sections, that plan steps reference research findings, or that implementation commits reference plan steps). This remains Weak per rubric criteria: usage without automated tests is probationary. |
| Pipeline readiness | Strong | RPI is the top-level workflow and the central integration point for the entire workflow system. It receives input from spike (via RPI seed), onboarding (via architecture map), and task-decomposition (via synthesized research). It invokes DD as a sub-procedure. It feeds into pr-prep (and by extension, review-fix-loop). Branch-strategy references it as the working methodology. It has no upstream dependency — it is standalone viable and is the pipeline root. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does:** RPI enforces a four-phase discipline: (1) scope the task in one sentence, (2) research the codebase and produce a committed artifact with required sections (What exists, Invariants, Prior art, Gotchas), (3) write an implementation plan with numbered steps, size estimates, test specifications with diagnostic expectations, and risks, (4) get human approval at a hard gate before implementation. Implementation proceeds step-by-step with commits referencing the plan, file size discipline (500-line guideline), and mandatory plan updates if deviations arise. It includes a refactoring variant with characterization-test-first discipline, explicit DD invocation signals for design decisions, session handoff docs for context management, and a detailed "when to skip" section.

**What ad-hoc process achieves:** Without RPI, a developer (or AI agent) would start coding directly. A careful developer might mentally plan, but: (1) research would not be written down or reviewable, (2) there would be no hard gate — implementation starts before the approach is validated, (3) no artifact trail exists for debugging where understanding diverged from reality, (4) DD invocation signals would not exist, meaning design decisions would be made implicitly, (5) test specifications would be an afterthought rather than a design artifact in the plan, (6) file size discipline and step-level commits would be inconsistent. However, a generic prompt like "research this codebase, write a plan, then implement" would capture the broad structure — the gap is in the specifics: required research sections, the hard gate, DD integration, test-first implementation, refactoring variant, and handoff docs.

**What built-in tools cover:** Claude Code has no built-in workflow enforcing research-before-plan-before-implementation with human checkpoints. Built-in verification-coordinator handles test planning but not the broader research/plan/gate cycle. Claude Code's default behavior is closer to "start implementing and course-correct," which is exactly what RPI replaces.

**Questions for the reviewer:**
- How much of RPI's value comes from the hard gate (step 4) vs. the artifact trail (research and plan docs)? If you had to drop one, which would hurt more?
- How often has the gate actually caught a wrong plan before implementation? Can you recall specific instances where the review changed the approach materially?
- Is the gap "RPI adds steps you wouldn't do" or "RPI ensures consistency in steps you'd sometimes do and sometimes skip"?
- Has the test-first gate (step 5) changed the quality of implementations compared to writing tests after? Is the "commit tests separately, review before implementation" step actually followed?
- Under what conditions is the gap largest — unfamiliar codebases, complex multi-file features, or refactorings?

### User-Specific Fit

**Triggering situations:**
- Any feature implementation touching more than one file
- Bug fixes where root cause is not immediately obvious
- Any task requiring understanding existing code before changing it
- Default for all non-trivial development work

**Questions for the reviewer:**
- How often do you perform non-trivial development work with Claude Code? (Daily? Multiple times per day?)
- Is this frequency increasing or decreasing as your workflow toolkit matures?
- Do you actually follow RPI for most non-trivial work, or do you frequently skip to implementation? The archived working docs suggest at least 6+ research-plan pairs were produced, but how many tasks skipped the workflow?
- Are there categories of work where you consistently skip RPI and probably shouldn't (e.g., "quick" features that turn out not to be quick)?
- The refactoring variant — have you used it? Does characterization-test-first discipline arise in your actual work?
- The session handoff docs — do you use these when ending mid-task, or do you just start fresh sessions without them?

### Condition for Value

**Stated or inferred conditions:**
- The user must do development work (not purely writing, reviewing, or testing)
- The user must work with Claude Code (the workflow assumes AI agent execution)
- The user must value human review gates (if working solo with full trust in the agent, the gate adds friction without value)
- The project must have a `docs/working/` directory convention (or the user must be willing to create one)
- The workflow assumes the developer reviews research and plan docs — if the developer routinely rubber-stamps them, the gate's value collapses

**Automated findings:**
- `docs/working/` directory EXISTS with artifacts from multiple development rounds
- CLAUDE.md references RPI as the default workflow: CONFIRMED
- Multiple workflows reference RPI as upstream/downstream: CONFIRMED (spike, onboarding, task-decomposition, branch-strategy, pr-prep, review-fix-loop)
- DD integration is bidirectional: RPI invokes DD, DD's output feeds back into RPI: CONFIRMED
- Real usage evidence in archived working docs: 6+ research-plan pairs from 2026-03-25 alone
- The workflow has been revised multiple times (handoff docs, freshness tracking, tier annotations, test foregrounding, pivot guidance all added via commits)

**Questions for the reviewer:**
- Are all conditions met today? Specifically, do you value the human review gate, or does it sometimes feel like friction on tasks where you already know the right approach?
- Is there a class of work where RPI's conditions are met but you use a different workflow (or no workflow)?
- The refactoring variant adds characterization-test-first discipline. Does that condition arise often enough to justify the variant's inclusion, or is it dead weight in the document?
- The test specification section in plans (with diagnostic expectations, test levels) is quite detailed. Do you actually fill this out, or does it get abbreviated in practice?

### Failure Mode Gracefulness

**Output structure:** RPI produces two committed markdown artifacts (research doc with required sections: Scope, What exists, Invariants, Prior art, Gotchas; and plan doc with required sections: Scope, Approach, Steps, Size estimate, Test specification, Risks) plus implementation commits that reference the plan. The hard gate at step 4 is a process checkpoint. Session handoff docs are optional artifacts for mid-task breaks.

**Potential silent failures:**
- **Shallow research that looks thorough.** The research doc has all required sections filled in but the content is surface-level — file names and signatures without understanding implementations, invariants listed but not actually verified against the code. This passes review because the document *looks* complete, but the plan is built on wrong assumptions.
- **Plan approved without meaningful review.** The human approves the plan without carefully checking it against the research, treating the gate as a rubber stamp. The process gives the *appearance* of review without the substance. This is the most dangerous failure because it undermines RPI's core value proposition.
- **Scope creep during implementation.** Step 5 says to stop and update the plan if something is wrong, but in practice the developer may improvise small deviations that compound. The plan becomes fiction while still being referenced in commit messages.
- **DD invocation missed.** The signals for when to invoke DD during research are described but require the agent to recognize that it has hit a design decision. If the agent doesn't notice, the research phase produces a premature commitment disguised as a finding.
- **Test specification becomes aspirational.** The detailed test specification format (with diagnostic expectations, test levels) is filled out during planning but doesn't match what's actually implemented. The test-first gate is the mitigation, but if tests are written to match the code rather than the spec, the spec's value is lost.
- **Handoff doc omitted or stale.** When ending a session mid-task, the next session may re-derive state from scratch rather than loading the handoff doc, wasting context budget on already-known information.

**Pipeline mitigations:** The artifact trail (committed docs) makes post-hoc auditing possible. The refactoring variant's characterization-test-first discipline catches some research errors during implementation. The "more than three review rounds suggests research missed something" heuristic catches some gate failures. The pr-prep workflow's review-fix loop provides a second layer of review before the PR is opened. The test-first gate at step 5 provides a checkpoint between plan approval and full implementation.

**Questions for the reviewer:**
- Which of the silent failure modes above have you actually observed? Which is most frequent?
- When the gate catches a problem, is it usually in the research (wrong understanding) or the plan (wrong approach given correct understanding)?
- Has scope creep during implementation been a problem in practice, and does updating the plan doc actually happen?
- Is the test specification section in plans detailed enough to catch test-implementation mismatches, or do tests end up being written to match the code regardless?

---

## Key Questions

1. **Is the hard gate at step 4 actually enforced and meaningful in practice?** The gate is RPI's most valuable differentiator from ad-hoc development. If it degrades into a rubber stamp (user skims and approves), RPI's counterfactual gap shrinks to "it produces documents" — which is still valuable for the artifact trail but far less valuable than "it prevents implementing the wrong thing." Evidence of gate-caught mistakes would validate the workflow's core value proposition. Evidence of routine rubber-stamping would suggest the gate should be redesigned (e.g., requiring the reviewer to annotate at least one question or concern before approving).

2. **What would meaningful test coverage look like for a workflow?** RPI's test coverage is Weak despite being the most-used workflow in the repo. Possible approaches: (a) structural compliance checks for research/plan docs (all required sections present, plan steps reference research findings, size estimates included), (b) a post-implementation retrospective comparing plan to actual implementation (automated diff between planned steps and actual commits), (c) integration into the self-eval skill for periodic assessment. Which of these would provide the most signal for the least investment?

3. **Has the workflow grown too heavy?** Since the prior self-eval (2026-03-23), RPI has gained test foregrounding (step 5 test-first gate with diagnostic expectations). Combined with existing features (refactoring variant, DD integration, session handoff docs, freshness tracking, size estimates, pivot guidance), the workflow is now quite long. A developer facing a moderately complex feature must navigate: scope, research with 5 required sections, plan with 6 required sections, gate, test-first gate, step-by-step implementation with plan updates and file size discipline, and verification. Is there a risk that the workflow's thoroughness discourages its use for the mid-complexity tasks where it would add the most value?
