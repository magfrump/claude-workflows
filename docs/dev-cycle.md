# Dev-cycle settings

This repo's settings for the dev-cycle skill (`skills/dev-cycle/SKILL.md`). Codebase
onboarding asks the user for the build-loop policy (its step 13); the idea sources are kept
by hand. Change either by editing this file.

Build-loop policy: review (interim; Q-103)

`self-merge`: a build loop the cycle hands an item to (step 6b) lands its branch through
pr-prep on its own. `review`: it runs pr-prep's review-fix loop, then stops for the user's
review (a PR, or one `you: judgment` "merge <branch>?" entry where the project has no PRs).
The skill counts the setting as made only when one line reads exactly
`Build-loop policy: self-merge` or `Build-loop policy: review`; the interim marker above keeps
it unset (so `review`) until Q-103 is answered.

## Idea sources

Step 5 reads these when it brainstorms, besides the seed log `docs/working/idea-log.md`.
Plain paths only: the skill never reads through a symlink.

| Source | Path or glob | Format |
| --- | --- | --- |
| Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files |
