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

Reader roots: /home/magfrump/claude-workflows

Reader homes: /home/magfrump

The two lines above name the readers the self-merge floor and `--check-fix` model besides
this checkout, its registered worktrees and the running session's HOME: the host spelling of
the main checkout (when the image breaks, the user runs sessions on the host in
`~/claude-workflows`: Q-121, Q-123) and the host's HOME. Each is one line of absolute paths
separated by single spaces (or `none`), followed by a blank line (outside a code block) or the
end of the file. A second copy, a line in any other form, or a file the readers refuse (an
unclosed code block, say) fails the import walks, so the floor refuses every path. Only the
default branch's copy is read (`scripts/build-loop.sh --settings` prints its `readers` line).

## Idea sources

Step 5 reads these when it brainstorms, besides the seed log `docs/working/idea-log.md`.
Each row is passed to `~/.claude/scripts/dev-cycle.sh --check-path` (in claude-workflows
itself, `scripts/dev-cycle.sh`), which allows tracked
files and gitignored files under `docs/working/` (so the self-improvement loop's ignored round
files count), at most 50 per row, never a symlink, a directory, a `.` or `..` component,
`.git*` or any other untracked file. Paths use only letters, digits, `.`, `_`, `-`, `/`, and
`*` or `?` in a glob.

| Source | Path or glob | Format |
| --- | --- | --- |
| Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files |
