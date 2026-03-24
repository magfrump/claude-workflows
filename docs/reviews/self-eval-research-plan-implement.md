# Self-Evaluation: research-plan-implement

**Target:** `workflows/research-plan-implement.md` | **Type:** Workflow | **Evaluated:** 2026-03-23
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | As a workflow, RPI's correctness is about artifacts (research docs, plan docs) rather than input/output. You can test artifact quality on known codebases — verify the research doc covers invariants, the plan has numbered steps, the gate was respected — but testing whether the *process* actually prevented mistakes requires counterfactual comparison, which is inherently harder. Medium investment. |
| Trigger clarity | Strong | "Any non-trivial feature or bug fix" is the clearest trigger in the repo. It is explicitly designated the default workflow in CLAUDE.md. The "when to skip" section handles the false-positive case (trivial changes). No ambiguity with other workflows: spike is for feasibility questions (not implementation), DD is invoked *from within* RPI, task-decomposition feeds *into* RPI, and onboarding is a pre-task activity. |
| Overlap and redundancy | Strong | No other workflow or built-in capability provides the research-then-plan-then-gate-then-implement structure with artifact trail. Task-decomposition overlaps on the research phase for multi-subsystem tasks, but explicitly feeds into RPI rather than replacing it. The refactoring variant is internal to RPI, not a separate workflow. DD is a sub-procedure, not an alternative. |
| Test coverage | Weak | No automated tests exist. The repo contains `docs/working/` artifacts (research-self-eval-skill.md, plan-self-eval-skill.md) that demonstrate the workflow has been used at least once on real work. Git history shows commits referencing plans. However, there are no example outputs with known-good baselines, no structural compliance checks, and no documented evaluation of whether the gate actually prevented bad implementations. This remains probationary per rubric criteria. |
| Pipeline readiness | Strong | RPI is the top-level workflow. It is standalone viable and serves as the integration point for other workflows: spike feeds into it (via RPI seed), onboarding produces context for it, task-decomposition parallelizes its research phase, DD is invoked from within it, and pr-prep follows it. It is referenced by branch-strategy as the working methodology. No pipeline dependency; it *is* the pipeline. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does:** RPI enforces a four-phase discipline: scope the task, research the codebase (producing a committed artifact), write an implementation plan (producing a committed artifact), get human approval at a hard gate before implementation begins, then implement step-by-step with commits referencing the plan. It includes a refactoring variant with characterization-test-first discipline, explicit DD invocation signals for design decisions, and guidance on when to skip or abbreviate.

**What ad-hoc process achieves:** Without RPI, the default is "start coding and figure it out." A careful developer might mentally plan before implementing, but: (1) the research would not be written down and thus not reviewable, (2) there would be no hard gate — implementation would start before the approach is validated, (3) there would be no artifact trail for debugging where understanding went wrong, (4) the DD invocation signals would not exist, so design decisions would be made implicitly.

**What built-in tools cover:** Claude Code has no built-in workflow that enforces research-before-plan-before-implementation with human checkpoints. Built-in verification-coordinator handles test planning but not the broader research/plan/gate cycle.

**Questions for the reviewer:**
- How much of RPI's value comes from the hard gate (step 4) vs. the artifact trail (research and plan docs)? If you had to drop one, which would hurt more?
- How often has the gate actually caught a wrong plan before implementation? Can you recall specific instances?
- Is the gap "RPI adds steps you wouldn't do" or "RPI ensures consistency in steps you'd sometimes do and sometimes skip"?
- Under what conditions is the gap largest — unfamiliar codebases, complex features, or something else?

### User-Specific Fit

**Triggering situations:**
- Any feature implementation touching more than one file
- Bug fixes where root cause is not immediately obvious
- Any task requiring understanding existing code before changing it
- Default for all non-trivial development work

**Questions for the reviewer:**
- How often do you perform non-trivial development work? (Daily? Multiple times per day?)
- Is this frequency increasing or decreasing as your workflow toolkit matures?
- Do you actually follow RPI for most non-trivial work, or do you frequently skip to implementation?
- Are there categories of work where you consistently skip RPI and probably shouldn't, or consistently use it and probably don't need to?

### Condition for Value

**Stated or inferred conditions:**
- The user must do development work (not purely writing, reviewing, or testing)
- The user must work with Claude Code (the workflow assumes AI agent execution)
- The user must value human review gates (if working solo with full trust in the agent, the gate adds friction without value)
- The project must have a `docs/working/` directory convention (or the user must be willing to create one)

**Automated findings:**
- `docs/working/` directory EXISTS in this repo with artifacts present
- CLAUDE.md references RPI as the default workflow: CONFIRMED
- Multiple other workflows reference RPI as a downstream step: CONFIRMED (spike, onboarding, task-decomposition, branch-strategy)
- DD integration is bidirectional: RPI invokes DD, DD's output feeds back into RPI: CONFIRMED

**Questions for the reviewer:**
- Are all conditions met today? Specifically, do you value the human review gate, or does it sometimes feel like friction on tasks where you already know the right approach?
- Is there a class of work where RPI's conditions are met but you use a different workflow (or no workflow)?
- The refactoring variant adds characterization-test-first discipline. Does that condition arise often enough to justify the variant's inclusion, or is it dead weight?

### Failure Mode Gracefulness

**Output structure:** RPI produces two committed markdown artifacts (research doc and plan doc) plus implementation commits that reference the plan. The research doc has required sections (Scope, What exists, Invariants, Prior art, Gotchas). The plan doc has required sections (Scope, Approach, Steps, Size estimate, Testing strategy, Risks). The hard gate at step 4 is a process checkpoint, not a document.

**Potential silent failures:**
- **Shallow research that looks thorough:** The research doc has all required sections filled in but the content is surface-level — signatures without implementations, invariants listed but not verified. This looks correct on review but leads to a plan built on wrong assumptions.
- **Plan approved without meaningful review:** The human approves the plan without carefully checking it against the research, treating the gate as a rubber stamp. The process gives the *appearance* of review without the substance.
- **Scope creep during implementation:** Step 5 says to stop and update the plan if something is wrong, but in practice the developer may improvise small deviations that compound. The plan becomes fiction while still being referenced in commit messages.
- **DD invocation missed:** The signals for when to invoke DD during research are described but require the agent to recognize them. If the agent doesn't notice it has hit a design decision, the research phase produces a premature commitment disguised as a finding.

**Pipeline mitigations:** The artifact trail (committed docs) makes post-hoc auditing possible. The refactoring variant's characterization-test-first discipline catches some research errors during implementation. The "more than three review rounds suggests research missed something" heuristic catches some gate failures.

**Questions for the reviewer:**
- Which of the silent failure modes above have you actually observed?
- When the gate catches a problem, is it usually in the research (wrong understanding) or the plan (wrong approach given correct understanding)?
- Has scope creep during implementation been a problem in practice, and does updating the plan doc actually happen?

---

## Key Questions

1. **Is the hard gate at step 4 actually enforced in practice?** The gate is RPI's most valuable feature — it prevents implementing the wrong thing. But if it degrades into a rubber stamp (user skims and approves), RPI's counterfactual gap shrinks substantially. Evidence of gate-caught mistakes would validate the workflow's core value proposition.

2. **Should task-decomposition be folded into RPI as a variant?** The full-evaluation already flagged this question. Task-decomposition is essentially "RPI but with parallel research via sub-agents." If RPI added a brief section on when and how to parallelize the research phase, task-decomposition might not need to exist as a separate workflow. This would simplify the workflow inventory without losing capability.

3. **What does test coverage look like for a workflow?** Every skill and workflow in the repo scores Weak on test coverage, but for RPI specifically, meaningful testing might mean: (a) a checklist of structural properties for research/plan docs that can be verified automatically, (b) a post-implementation retrospective template that tracks whether the plan matched what was actually built, or (c) integration with the self-eval skill to periodically assess artifact quality. Which of these would provide the most signal for the least investment?
