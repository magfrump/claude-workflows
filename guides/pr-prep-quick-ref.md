# PR Prep Quick Reference

Actionable checklist for [workflows/pr-prep.md](../workflows/pr-prep.md). Consult the full workflow for rationale and extended discussion.

---

## Phase 1: Content

### 1. Gate Checks (run concurrently)

- [ ] **Size check** — PR ≤ ~500 lines? If not, consider splitting before doing any other prep. If unsplittable, note in PR description and suggest file review order
- [ ] **Dependent PR check** — if this builds on unmerged PRs, verify they've landed or set the base correctly. Skip for standalone branches

### 2. Open Draft PR (optional)

- [ ] Push branch and open draft PR to start CI and give async visibility
- Skip if no CI or sole contributor

### 3. Review-Fix Loop

#### a. Generate Reviews (run in parallel)

- [ ] `/code-review` — multi-critic structural review of the diff vs main
- [ ] `/self-eval <target>` — rubric assessment of new/modified skills or workflows
- [ ] **Documentation check** — verify docs updated if PR changes public APIs, config, or user-facing behavior. Skip for internal refactors
- [ ] **Dependency audit** — check license, size, maintenance status if dependencies added/upgraded. Skip if no dependency changes

#### b. Triage and Fix

| Tier | Action |
|------|--------|
| **Must Fix** — correctness bugs, false passes, wrong behavior | Fix before proceeding |
| **Must Address** — fragility, inconsistency, misleading tests | Fix or explicitly acknowledge |
| **Consider** — style, duplication, future-proofing | Fix if cheap, otherwise note for later |

For each finding:
1. Confirm it's real by reading the code
2. Fix and commit in coherent batches (e.g., `fix: Address code review findings A2-A5`)

#### c. Run Tests

- [ ] Re-run the full test suite after fixes — tightened assertions often surface latent bugs

#### d. Re-review

- [ ] Run the same review skills again
- [ ] Compare against prior findings: resolved? New issues introduced? Previously masked issues surfaced?

#### e. Exit Criteria

- [ ] No **Must Fix** items remain
- [ ] All **Must Address** items resolved or explicitly acknowledged
- [ ] Findings are converging (if not converging after 3–4 loops, the problem is architectural — use divergent-design or RPI instead)

---

## Phase 2: Packaging

### 4. Clean Up Commit History

- [ ] Squash WIP commits into logical chunks — each commit is one coherent, independently reviewable change

### 5. Verify and Annotate (run concurrently)

- [ ] **Verify CI passes** — lint, build, tests on the rebased code. Push to trigger remote CI if draft PR exists
- [ ] **Annotate the diff** — add PR comments on non-obvious code sections for the reviewer

### 6. Write PR Description

```
## What this does        — 1-3 sentences: what changed and why
## How it works          — approach summary, not line-by-line
## How to test           — concrete steps for the reviewer
## Areas of uncertainty  — libraries, performance, edge cases
## Decisions made        — links to docs/decisions/ or brief notes
```

- [ ] For UI changes: include before/after screenshots or recording
