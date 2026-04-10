# Self-Evaluation: pr-prep

**Target:** `workflows/pr-prep.md` | **Type:** Workflow | **Evaluated:** 2026-04-09
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions
**Scope:** Re-evaluation covering full workflow including new Step 7 (post-merge follow-up checklist, commit b27d179)

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | pr-prep is a multi-step process workflow whose quality is measured by process outcomes (clean commits, passing CI, good PR descriptions, converging review loops), not structured output. Step 7's post-merge checklist adds another outcome-oriented step (CI green on main, no regressions) that is individually verifiable but hard to test as part of the workflow. The Retrospective section remains the hardest to test — its value depends on genuine reflection, which is inherently unmeasurable by automation. |
| Trigger clarity | Strong | Trigger is unambiguous: "before opening any pull request, especially when the reviewer is in a different timezone." CLAUDE.md trigger #7 matches exactly. Step 7's trigger ("after the PR merges") is equally clear and explicitly marked optional with "act on what applies, skip the rest." No overlap with other workflows — RPI feeds into pr-prep, review-fix-loop is embedded within it. |
| Overlap and redundancy | Strong | No substantive overlap with other workflows or skills. Step 7's post-merge items (verify CI on main, monitor regressions, update docs, remove feature flags) are not covered by any other workflow. The verification-coordinator built-in agent covers pre-merge testing, not post-merge monitoring. The four checklist items are distinct from the Retrospective's reflection questions — Step 7 is operational follow-up, the Retrospective is learning capture. |
| Test coverage | Weak | Convention tests exist in `test/workflow-required-sections.bats` (structural validation only). No automated tests exercise the workflow end-to-end. No example output artifacts from a complete pr-prep run exist. Git history shows 23+ commits and active use (review-fix loop artifacts in `docs/reviews/`), but no formal documentation of end-to-end usage, retrospective outputs, or post-merge checklist completion. Step 7 is brand new (this branch) with zero usage evidence. |
| Pipeline readiness | Strong | Standalone viable and well-integrated. pr-prep is a top-level workflow invoked directly by the user. It composes `/code-review` and `/self-eval` in its review-fix loop, both of which exist and function. RPI explicitly references pr-prep as its downstream step. Step 7 is self-contained — it requires no additional tooling, only that the project has CI and/or observability (and explicitly says to skip items that don't apply). |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: pr-prep is a two-phase (Content → Packaging) workflow with 7 steps plus a retrospective for packaging work before and after opening a PR. The new Step 7 adds a post-merge follow-up checklist covering four operational items: verify CI on main, monitor for regressions, update docs, and remove stale feature flags. It's framed as lightweight (under 5 minutes) and explicitly optional.

**What ad-hoc process achieves**: Without Step 7, developers merge and move on. Some will instinctively check CI; few will systematically review whether docs need updating or feature flags should be cleaned up. The "monitor for regressions in the first hour" item is particularly easy to forget — semantic conflicts between concurrent PRs don't show up in pre-merge CI. Without the full workflow, developers also skip the structured self-review (Phase 1) and commit cleanup (Phase 2), relying on reviewer feedback to catch issues — which is more expensive in async/cross-timezone scenarios.

**What built-in tools cover**: The verification-coordinator agent handles pre-merge test planning. No built-in capability covers post-merge monitoring, doc staleness checks, or feature flag cleanup.

**Questions for the reviewer**:
- Has a semantic conflict (two PRs that individually pass CI but break main together) actually occurred in your projects? If so, Step 7's CI check would have caught it. If not, the item may be speculative.
- How much of Step 7's value is "things you'd do anyway but might forget" vs. "things you wouldn't have thought of"? The former is a consistency aid; the latter is a genuine counterfactual gap.
- Does the 5-minute framing make Step 7 more likely to be followed, or does it risk trivializing items that sometimes surface real follow-up work?

### User-Specific Fit

**Triggering situations**: Step 7 triggers after every PR merge. The full workflow triggers before every PR opening.

**Questions for the reviewer**:
- How many PRs do you merge per week? Step 7's value scales with frequency — at 1/week it's a quick mental check; at 5+/week it may feel like overhead.
- Do your projects have observability (error tracking, dashboards) that makes the "monitor for regressions" item actionable? If not, that item is a no-op.
- Do you use feature flags during development? If not, the "remove feature flags" item never applies.
- The Retrospective + Step 7 together add two post-PR-opening steps. Is this the right amount of post-completion process, or does it feel heavy?

### Condition for Value

**Stated or inferred conditions**:
- The user must open and merge PRs with some regularity — likely met given active development.
- The project must have CI for the "verify CI on main" item to apply — likely met for most projects.
- The project must have observability for the "monitor regressions" item to apply — **condition varies by project**.
- The user must actually scan the checklist after merge rather than skipping it — the critical condition.
- Step 7's "track follow-up work separately" escape valve requires a task-tracking system — implicitly assumed but not stated.

**Automated findings**:
- No evidence of Step 7 being used (it's new on this branch, commit b27d179).
- No `docs/thoughts/` files exist with retrospective content — the Retrospective section's condition ("user actually reflects") remains unverified.
- The `guides/pr-prep-quick-ref.md` exists and would need updating to include Step 7 once merged.

**Questions for the reviewer**:
- Is the "scan and skip what doesn't apply" design the right approach, or would it be better to have the checklist auto-filter based on project type (e.g., suppress "feature flags" for projects that don't use them)?
- Step 7 says "intentionally lightweight" — is this a design principle worth preserving, or should some items (like "verify CI on main") be automated rather than manual?
- Does the optional framing make it more likely to be adopted (low pressure) or more likely to be forgotten (easy to skip)?

### Failure Mode Gracefulness

**Output structure**: Step 7 produces a brief traceability note ("Post-merge actions taken") as free-text. The Retrospective produces unstructured prose. Neither has required fields or mechanical validation.

**Potential silent failures**:
- **Checklist fatigue**: After the effort of Phase 1 + Phase 2 + Retrospective, Step 7 is the fourth post-implementation step. Users may rubber-stamp it without actually checking CI or scanning docs. This is the most likely failure mode.
- **False confidence from checking boxes**: A user checks "CI green on main" by glancing at the badge without waiting for the full pipeline, missing a slow integration test failure.
- **Stale checklist items**: Over time, the four items may become irrelevant (e.g., CI auto-notifies on failure, feature flags are managed by a system). The checklist persists after the need passes.
- **Retrospective perfunctory answers**: Unchanged from prior eval — "everything went as planned" with no learning signal remains the primary risk.

**Pipeline mitigations**: None for Step 7 or the Retrospective. Both are purely self-directed with no downstream consumer.

**Questions for the reviewer**:
- Would it help to have the post-merge check automated (e.g., a hook that checks CI status after merge) rather than manual?
- Have you experienced checklist fatigue with pr-prep's existing steps? Does adding Step 7 push past a threshold?
- Is the free-text "Post-merge actions taken" note actually useful for traceability, or is it process theater?

---

## Key Questions

1. **Does Step 7 earn its place as a workflow step, or should it be a separate guide?** The post-merge checklist is operationally distinct from PR preparation — it happens after the PR lifecycle is complete. Inlining it in pr-prep keeps it visible but makes the workflow longer (now 7 steps + retrospective). An alternative is a standalone `guides/post-merge-checklist.md` referenced from pr-prep. The tradeoff is visibility vs. workflow length.

2. **Is four post-implementation steps too many?** After coding, the developer now faces: Phase 1 (review-fix loop), Phase 2 (packaging), Retrospective, and Step 7 (post-merge). Each is individually lightweight, but the cumulative overhead may cause later steps to be skipped. Is there evidence that the Retrospective is being completed? If not, adding Step 7 may compound an existing follow-through problem.

3. **Should any Step 7 items be automated rather than manual?** "Verify CI passes on main" is fully automatable (check the merge commit's CI status). "Update affected documentation" could be partially automated (diff-based doc-staleness detection). Manual checklists for automatable tasks tend to decay — the question is whether automation investment is justified at this project's scale.
