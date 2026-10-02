# Dev-cycle settings

This repo's settings for the dev-cycle skill (`skills/dev-cycle/SKILL.md`). Codebase
onboarding asks the user for the build-loop policy (its step 13); the idea sources are kept
by hand. Change either by editing this file.

Build-loop policy: review (interim; Q-103)

Read by the build-loop handoff (roadmap item "Build-loop handoff"; not built yet), not by the
dev-cycle skill itself. `self-merge`: a build loop the cycle hands an item to lands its branch
through pr-prep on its own, but only for work that stays out of what later runs follow unreviewed
(skills, workflows, scripts, tests, guides, instruction files and similar; the handoff seed,
`docs/working/seed-build-loop-handoff.md`, lists them); other work still stops for review. `review`: the loop runs pr-prep's review-fix loop
and stops; the cycle then asks the user (a PR, or one "merge <branch>?" entry where the
project has no PRs) and merges once approved.

The handoff design counts the setting as made only when the file has exactly one line, outside code
blocks, reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` (a
trailing CR is ignored). Anything else counts as unset, which means `review`.

Interim note: the "(interim; Q-103)" on the policy line keeps it unset until Q-103 is
answered.

## Idea sources

Step 5 reads these when it brainstorms, besides the seed log `docs/working/idea-log.md`.
Tracked files only, as plain paths from the repo root (letters, digits, `.`, `_`, `-`, `/`;
no `..` or `.git` component), never through a symlink: the skill's "Plain, tracked repo
paths only" rule.

| Source | Path or glob | Format |
| --- | --- | --- |
| Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files |
