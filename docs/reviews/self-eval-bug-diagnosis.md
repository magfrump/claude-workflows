# Self-Evaluation: bug-diagnosis

**Target:** `workflows/bug-diagnosis.md` | **Type:** Workflow | **Evaluated:** 2026-03-27
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | As a workflow, the meaningful question is "did this process lead to a correct diagnosis faster?" — which requires realistic bug scenarios and domain judgment. The diagnosis log template is structured and checkable for format compliance, but assessing process quality (did isolation narrow correctly? was the root cause actually root?) is inherently high-investment. |
| Trigger clarity | Strong | Triggers are specific and concrete: bugs in known code areas, regressions, observable symptoms. The boundary with RPI is explicitly articulated with a decision rule ("can you point to the area?") and the 3-hypothesis escape hatch provides a mechanical pivot signal. No ambiguous overlap with other workflows — spike, DD, onboarding, task-decomposition, and review-fix-loop all serve clearly distinct purposes. |
| Overlap and redundancy | Strong | Carves out a well-defined niche that no other workflow fills. RPI covers "bug in unfamiliar code" but uses a plan-approval gate inappropriate for rapid debugging iteration. The two workflows reference each other with explicit pivot criteria and directional handoffs (bug-diagnosis step 4 escape hatch to RPI; RPI step "When to pivot" to bug-diagnosis). No skill in the repo covers structured debugging either — the code-review and code-fact-check skills operate on diffs, not live debugging. |
| Test coverage | Weak | Zero automated tests. No example diagnosis logs exist anywhere in the repo. One git commit (`a2f408b`) is the initial addition. No evidence of real-world usage. The workflow is entirely untested and in probationary state per the rubric. |
| Pipeline readiness | Strong | Standalone viable as a top-level workflow — invoked directly when encountering a bug. Not dependent on any pipeline or orchestrator. Has well-defined integration points with RPI (bidirectional pivots) and spike (secondary pivot for unfamiliar library/technique), both of which exist. CLAUDE.md lists it in the workflow index. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: Structures debugging as a 6-step loop (reproduce, isolate, hypothesize, test, fix, verify) with specific techniques at each step: git bisect for regressions, binary code search for narrowing, characterization tests for safe fixes in untested code. Includes a diagnosis log template for tracking hypotheses, a 3-hypothesis escape hatch to prevent tunnel vision, and explicit pivot rules to RPI and spike.

**What ad-hoc debugging achieves**: Without this workflow, a developer would reproduce the bug, read error messages, try fixes, and run tests — covering steps 1, 5, and 6 informally. What's likely missing in ad-hoc debugging:
- **Systematic isolation** — most developers read the error and jump to hypotheses without deliberately narrowing the search space first
- **Written hypothesis tracking** — prevents re-testing the same thing and creates an auditable record, but few developers do this naturally
- **The escape hatch** — recognizing when to stop iterating and shift to a research-first approach; ad-hoc debugging has no built-in circuit breaker
- **Characterization tests before fixing** — a specific technique many developers skip, especially under time pressure
- **Minimal reproduction discipline** — the workflow's guidance on stripping down to the smallest trigger is advice experienced developers know but don't always follow

**What built-in tools cover**: Claude Code provides general debugging assistance (reading errors, suggesting fixes) but has no structured debugging workflow, no hypothesis tracking, and no pivot rules.

**Questions for the reviewer**:
- How much of the value is structure/discipline (writing hypotheses, the 3-hypothesis rule) vs. the specific techniques (git bisect, characterization tests, minimal reproduction)?
- Do you naturally follow a systematic isolation step, or do you tend to jump from symptom to hypothesis?
- Is the gap largest for "familiar code, bad habits" scenarios, or does it also help when the bug is genuinely tricky?

### User-Specific Fit

**Triggering situations**: Bug reports in code you already understand. Regressions in areas you've recently worked on. Failing tests with observable symptoms. Any debugging where you know roughly where to look.

**Questions for the reviewer**:
- How often do you encounter bugs in known areas of code vs. bugs in unfamiliar code?
- What fraction of your development time is debugging vs. new features vs. refactoring?
- When debugging, do you already write down hypotheses, or do you hold them in your head?
- Would you reach for this workflow naturally when a bug appears, or default to ad-hoc debugging?
- Is the frequency of debugging-in-known-code increasing or decreasing as the project matures?

### Condition for Value

**Stated or inferred conditions**:
1. User encounters bugs regularly (not purely greenfield development)
2. Bugs occur in areas the user already knows (the "known area" prerequisite for choosing this over RPI)
3. The hypothesis-test discipline adds value over the user's natural debugging style
4. RPI exists for the pivot to work
5. The diagnosis log provides enough value to justify writing it (vs. just fixing the bug)

**Automated findings**:
- RPI workflow with bidirectional pivot references: EXISTS (RPI "When to pivot" section explicitly references bug-diagnosis)
- Spike workflow for secondary pivot: EXISTS
- CLAUDE.md lists bug-diagnosis as a workflow: YES
- Real-world usage evidence: NONE
- Test coverage: NONE

**Questions for the reviewer**:
- Are conditions 1-3 met in your current work?
- Would you actually write a diagnosis log for non-trivial bugs, or does the overhead outweigh the benefit?
- Is the 3-hypothesis pivot to RPI something you'd follow, or would time pressure keep you iterating?
- Is this workflow an investment that compounds (better debugging habits over time) or a one-time benefit?

### Failure Mode Gracefulness

**Output structure**: The diagnosis log has structured sections (symptom, reproduction, hypotheses table with test/result columns, root cause, fix). The hypotheses table makes the debugging path auditable — a reviewer can see what was tried and why.

**Potential silent failures**:
- **Premature hypothesis confirmation**: A hypothesis is "confirmed" because a targeted test passes, but the root cause is actually deeper. The fix masks the symptom without addressing the real issue. The workflow's requirement for "specific, falsifiable predictions" mitigates this somewhat, but a test can pass for the wrong reasons.
- **Insufficient isolation leading to wrong hypotheses**: If step 2 is rushed, the developer forms hypotheses about the wrong code. All subsequent hypothesis-test cycles waste time. The workflow provides techniques (git bisect, binary search) but can't force their use.
- **Characterization test blind spots**: Tests written by someone who doesn't fully understand the code may capture observed behavior without covering the behavior that matters. The tests pass, the fix looks safe, but an important case was missed.
- **Escape hatch ignored under pressure**: The 3-hypothesis rule is advice, not enforcement. A developer deep in debugging may not stop to count hypotheses or acknowledge that pivoting to RPI would be more efficient.

**Pipeline mitigations**: PR review of the diagnosis log and the fix provides an external check. The pivot to RPI is the main safety valve for stuck debugging.

**Questions for the reviewer**:
- Have you experienced premature hypothesis confirmation in your debugging?
- When you've been stuck on a bug, what actually made you change approach — a rule like "3 hypotheses," or just frustration?
- Do characterization tests in practice capture the right behaviors, or do they tend to test the obvious while missing the subtle?

---

## Key Questions

1. **Does the hypothesis discipline add enough value over your natural debugging approach to justify the overhead?** The workflow's core value-add is writing down falsifiable hypotheses and tracking results. If you already debug systematically, the marginal benefit is mainly the pivot rules and characterization test pattern. If you tend to jump to fixes without isolating first, the benefit is larger.

2. **Will you actually write a diagnosis log?** The "when to skip" section wisely carves out trivial bugs, but the boundary between "obvious one-line bug" and "worth a diagnosis log" is a judgment call. If the log feels like overhead for most bugs you encounter, the workflow may not get used even when it would help.

3. **Is real-world evidence needed before trusting this workflow?** With zero test coverage and zero usage history, the workflow is entirely theoretical. Running it on a single real debugging session — even retrospectively, documenting a recent bug you fixed — would provide significant evidence about whether the structure helps or hinders. This is the lowest-investment way to move from probationary to evidenced.
