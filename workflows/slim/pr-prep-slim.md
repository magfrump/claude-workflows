# PR Preparation (Slim)

> Quick-start checklist. Full workflow: [pr-prep.md](../pr-prep.md)
> Last synced: 2026-04-08

## When to use

Before opening any pull request. Two phases: content first, then packaging.

## Phase 1: Content

- [ ] **1. Gate checks** — Verify PR is under ~500 lines (split if possible). Check that dependency PRs have merged or base is set correctly.

- [ ] **2. Open draft PR** — Push branch, open draft so CI starts and async reviewers get visibility.

- [ ] **3. Review-fix loop** — Run code review and self-eval skills. Triage findings by tier:
  - *Must Fix*: correctness bugs → fix before proceeding
  - *Must Address*: fragility, inconsistency → fix or acknowledge
  - *Consider*: style, duplication → fix if cheap
  
  Re-run reviews after fixes. Exit when no Must Fix items remain. Max 3-4 loops.

## Phase 2: Packaging

- [ ] **4. Clean commit history** — Interactive rebase to squash WIP commits into logical chunks. Each commit = one coherent, reviewable change.

- [ ] **5. Verify & annotate** — Run lint/build/tests on final code. Add PR comments explaining unfamiliar libraries or non-obvious patterns.

- [ ] **6. Write PR description** — Include: What this does, How it works, How to test, Areas of uncertainty, Decisions made. Add screenshots for UI changes.

- [ ] **7. Retrospective** — 2 minutes in `docs/thoughts/`: plan vs. reality, skipped steps, surprises, what you'd do differently.

## Key principle

Content before packaging — don't polish commits that may change due to review findings.
