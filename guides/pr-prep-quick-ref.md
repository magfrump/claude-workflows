# PR Prep Quick Reference

Actionable checklist for the review-fix loop from [workflows/pr-prep.md](../workflows/pr-prep.md). Consult the full workflow for rationale and extended discussion.

---

## Before the Loop

- [ ] Commit history cleaned (`git rebase -i origin/main`) — each commit is one coherent, independently reviewable change
- [ ] Local CI passes: lint, build, tests

## Review-Fix Loop

### a. Generate Reviews (run in parallel)

- [ ] `/code-review` — multi-critic structural review of the diff vs main
- [ ] `/self-eval <target>` — rubric assessment of new/modified skills or workflows

### b. Triage and Fix

| Tier | Action |
|------|--------|
| **Must Fix** — correctness bugs, false passes, wrong behavior | Fix before proceeding |
| **Must Address** — fragility, inconsistency, misleading tests | Fix or explicitly acknowledge |
| **Consider** — style, duplication, future-proofing | Fix if cheap, otherwise note for later |

For each finding:
1. Confirm it's real by reading the code
2. Fix and commit in coherent batches (e.g., `fix: Address code review findings A2-A5`)

### c. Run Tests

- [ ] Re-run the full test suite after fixes — tightened assertions often surface latent bugs

### d. Re-review

- [ ] Run the same review skills again
- [ ] Compare against prior findings: resolved? New issues introduced? Previously masked issues surfaced?

### e. Exit Criteria

- [ ] No **Must Fix** items remain
- [ ] All **Must Address** items resolved or explicitly acknowledged
- [ ] Findings are converging (if not converging after 3–4 loops, the problem is architectural — use divergent-design or RPI instead)

---

## After the Loop

### PR Description

```
## What this does        — 1-3 sentences: what changed and why
## How it works          — approach summary, not line-by-line
## How to test           — concrete steps for the reviewer
## Areas of uncertainty  — libraries, performance, edge cases
## Decisions made        — links to docs/decisions/ or brief notes
```

### Final Checks

- [ ] PR ≤ ~500 lines? If not, consider splitting or document why not and suggest a file review order
- [ ] Non-obvious code annotated with PR comments for the reviewer
