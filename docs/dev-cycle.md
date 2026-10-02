# Dev-cycle settings

This repo's settings for the dev-cycle skill (`skills/dev-cycle/SKILL.md`). Codebase
onboarding sets them (its step 13); change them by editing this file.

Build-loop policy: review

`autonomous`: a build loop the cycle hands an item to (step 6b) lands its branch through
pr-prep on its own. `review`: it runs pr-prep's review-fix loop, then stops for a separate
review (a PR, or one `you: judgment` "merge <branch>?" entry where the project has no PRs).

## Idea sources

Step 5 reads these when it brainstorms, besides the seed log `docs/working/idea-log.md`.
Paths must stay inside the repo.

| Source | Path or glob | Format |
| --- | --- | --- |
| Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files |
