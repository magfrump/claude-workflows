# PR Review Doc Inclusion

How and when to commit review artifacts from `docs/reviews/` to the PR branch so reviewers can see the quality evidence alongside the code.

## The problem

Review artifacts (fact-check reports, critic critiques, verification rubrics) are generated during pr-prep's review-fix loop but sometimes aren't committed to the branch. This means reviewers can't see what was checked, what was found, and what was fixed — they only see the final code. For async reviews across timezones, this missing context costs a full round-trip.

## The practice

Before marking a PR as ready for review (i.e., before moving from Phase 1 to Phase 2 of pr-prep), ensure all review artifacts generated during the review-fix loop are committed to the branch:

1. **Check `docs/reviews/` for uncommitted artifacts.** Run `git status` and look for new or modified files under `docs/reviews/`.
2. **Commit them as a batch.** Use a single commit: `docs: add review artifacts for <feature>`. This keeps review docs separate from code changes in the commit history.
3. **Include artifacts from all review rounds.** If the review-fix loop ran multiple iterations, commit the final versions. Earlier iterations are useful only if they show a finding that was fixed — the final artifact already reflects this via resolved/acknowledged status.

## What to include

| Artifact type | Source | Include? |
|---|---|---|
| Code review reports | `/code-review` skill | Yes |
| Self-eval rubrics | `/self-eval` skill | Yes |
| Fact-check reports | `/fact-check` skill | Yes |
| Critic critiques (Cowen, Yglesias, etc.) | critic skills | Yes |
| Verification rubrics | `/draft-review` skill | Yes |
| Working docs (research, plans) | RPI workflow | Already committed via RPI; no extra action needed |

## What NOT to include

- **Intermediate review iterations** that were fully superseded by later runs — commit only the final version.
- **Review artifacts from unrelated prior work** — only artifacts generated for *this* PR belong on *this* branch.

## Timing

Commit review docs **after the review-fix loop exits clean** (no Must Fix items, Must Address items resolved) and **before cleaning up commit history** (Phase 2, step 4). This way the docs survive any interactive rebase — they're in their own commit that won't conflict with code squashing.

## Why this matters

- **Async reviewers** see what was already checked, reducing redundant review effort.
- **Future maintainers** can trace what quality checks were run when the code was introduced.
- **Review artifacts are already gitattributes-collapsed** (`docs/reviews/** linguist-generated` in `.gitattributes`), so they won't clutter the GitHub diff view unless a reviewer explicitly expands them.
