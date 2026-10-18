# Dev-cycle settings

This repo's settings for the dev-cycle skill (`skills/dev-cycle/SKILL.md`). Codebase
onboarding asks the user for the build-loop policy (its step 13); the idea sources are kept
by hand. Change either by editing this file.

Build-loop policy: self-merge

Build-loop slots: 3

Self-merge never: workflows/

The scripts read the three lines above, and the two reader lines below, from the default
branch's commit, never from a working tree (a build loop can write any working tree); the
orchestrator reads them through `scripts/build-loop.sh --settings`, whose header gives each
line's exact form. Each key may appear on one line only, outside code blocks (a copy is
found by its letters alone, so a bold or listed copy counts too); the never and reader
lines need a blank line or the file's end after them; a trailing CR is ignored.

- **Policy.** Under `self-merge`, when a build loop marks its branch `handoff: ready`, the
  orchestrator lands it through the gate (`build-loop.sh --merge`) with no review, but only
  when every changed path is listed in the brief's `Paths:` line or is one of the brief's
  own files (named by its stem), and none is on the gate's fixed floor (instruction files
  and what they `@`-import, any dot path, the gate's own code, files later runs read as
  truth such as `docs/decisions/` and `docs/constraints.md`, symlinks and gitlinks) or
  matches the never line. A self-merge refused for a path falls through to review; a
  conflict is filed as stopped, and an environment refusal is retried. Under `review`, the
  orchestrator files one merge entry (`merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when
  the change touches the gate's own code) holding `--check`'s output, and merges only on
  your `[1] merge`. Under both policies the N rules refuse a change to
  `docs/constraints.md`, this file, the cycle's own files (the questions files, the
  roadmap, the idea log, the cycle records) or any brief beyond the brief's own Status
  line, and any symlink, gitlink or `.git*` path: under review such a branch is filed as stopped; under self-merge it first comes to
  you as a merge entry, whose `[1] merge` the gate then refuses, so it ends as stopped. A brief self-merges only when its own `Policy:` line also
  reads `self-merge`. Only the exact line with `self-merge` or `review` sets the policy,
  and `self-merge` also needs a valid never line (its `none` form for an empty list).
  Anything else counts as unset, which means `review`. This repo is set to `self-merge`
  (Q-103 [2], 2026-10-17: a single-author repo), within the never line below.
- **Slots.** From 1 to 9 (anything else, or no line, means 3): how many build loops run at
  once. Step 10 dispatches into the slots less the loops this session runs, and step 8 writes new
  briefs only while the queue is shorter than the slots. The queue counts open briefs whose loop is absent (not yet
  dispatched) or working, plus those sent back to a loop; a blocked, stopped, capped or
  ready-for-review one, or a stalled one held, waits on you and is not counted.
- **Never line.** Globs that self-merge never lands, even when a brief lists them: `*` and
  `?` match within one path part, a glob matches the path or any directory above it, and
  paths compare lower-cased. A malformed line turns self-merge off. Here it holds every
  code and process directory whose files take effect in this repo without a release
  (interim; Q-149):
  sessions in this repo read `workflows/`, `skills/`, `guides/` and `patterns/` from their
  own checkout, and the health check the orchestrator runs every iteration executes
  `scripts/`, `test/`, `hooks/` and `devcontainer-config/` from its worktree, while the
  release paste runs `devcontainer-config/install.sh` on the host before you see its diff.
  `templates/` (a snippet other repos copy by hand) and `global-instructions/` (every
  session's global instructions after a release; the floor already refuses its `CLAUDE.md`)
  take effect outside the gate's view too. So in this repo self-merge can land only files
  outside those directories and off the floor: docs the floor does not protect, `README.md`,
  `runs/`, `archive/`, and any path under a new top-level name.
  Some of those docs are read as authority too (`docs/evaluation-rubric.md`, which
  self-eval scores against, and `docs/spikes/`, whose seeds later work loads); Q-149 asks
  whether to list them.
- **Review handoff.** No line. The pull-request route the design names is not built, and
  this repo has no PRs, so every review merge is one questions entry.

Reader roots: /home/magfrump/claude-workflows /workspace

Reader homes: /home/magfrump /home/node

The two lines above name the readers the self-merge floor and `--check-fix` model besides
this checkout, its registered worktrees and the running session's HOME: both spellings of the
main checkout, the host's and the container's (when the image breaks, the user runs sessions
on the host in `~/claude-workflows`: Q-121, Q-123), and both HOMEs, so a walk run on either
side reads the other side's names. Each is one line of absolute paths (letters, digits and
`. _ - /`, with no empty, `.` or `..` part, each listed once) separated by single spaces (or
`none`), followed by a blank line (outside a code block) or the end of the file. A second copy, a line in any other form, or a file the readers refuse (an
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
