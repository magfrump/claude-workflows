Merge branch 'feat/build-loop-u2b3b2b': both import walks start at the instruction files Claude Code loads from outside the checkout

## What this does

U2b3b2b of the build-loop handoff (plan step 5, the U2b3b2 split note). Both import walks model which repo files Claude Code sessions load as instructions through `@` imports: the self-merge floor's main walk and `--check-fix`'s tree walk. Until now they started only at start files in the walk's own checkout (and main), so an import from your user memory, a rule or skill under `~/.claude`, an installed plugin, the managed policy, a parent directory's CLAUDE.md, or an untracked CLAUDE.local.md in another worktree was invisible, and a self-merge could change the repo file it named. `outside_seeds` now lists those files and both walks start at them. It also closes U2b3b2a's S1: an outside link into another worktree that lacks the file now reads as the repo path.

**Workflow provenance:** RPI (plan revision 4, step 5) → split before code (U2b3b2 → U2b3b2a, U2b3b2b) → pr-prep; split again at review iteration 1 (U2b3b2c).
← carried from RPI: the superset-and-fail-closed rule for both walks, U2b3b2a's second channel and import_outside as the one reader of outside files, the 400-line cap, the reader lists from reader_settings, and the carried rows A3, S1, K4, K5.

**Failures prevented:**
- A self-merge changing a repo file that `~/.claude/CLAUDE.md`, a user rule, a skill, an installed plugin, auto memory's MEMORY.md, `/etc/claude-code/CLAUDE.md` or an ancestor's CLAUDE.md imports.
- A self-merge changing a file that an untracked start in another worktree imports (`/workspace`'s `devcontainer-config/claude-home/CLAUDE.md`, seen from a gate worktree).
- An outside link into a worktree that lacks main's file being skipped as missing (S1).
- Found in review: a grep error silently dropping seeds, a link to /dev/zero hanging every walk, an argument-list overflow, and three ways the same-bytes skip dropped a seed the walks did not read the same way.

## Reviewer's path — start here

1. `scripts/lib/dev-cycle-read.sh`, the walk header above `IMPORTED=error`: what the walks now start at, and the named exceptions.
2. `outside_seeds` with its helpers `root_starts` and `with_at`: the three seed sources, the @ filter, the C1 same-bytes skip and its four conditions.
3. `outside_proj`, and the two seed loops in `imported_names` and `main_imports`.
4. `test/scripts/build-loop-check.bats`, the five U2b3b2b tests.

## How it works

- **Config dirs**: each reader home's `.claude`, `CLAUDE_CONFIG_DIR` (a relative one fails the walk) and `IMPORT_MANAGED_DIR` (`/etc/claude-code`): instruction-named files, `rules/`, the prompt directories, each installed plugin version from `installed_plugins.json` (the whole cache when it cannot be read), and auto memory's `MEMORY.md`. Trees are followed through links (the user's skills link into /opt).
- **Ancestors** of every reader root that lie below no root: their instruction files, and their `.claude` as a config dir.
- **C1**: every start file in another reader root present here, listed with `find -P` (never `git -C`: a loop writes its own worktree's `.git` file, and git there could run a command from a config it wrote). A start is skipped only when it is not a link, its bytes equal this checkout's plain copy at the same path, and that copy is a start of the same kind.
- **The @ filter**: only a seed holding an `@` byte (the parser starts every name at one) or reached through a link is kept; `with_at` greps only files outside_ok admits and fails the walk on any grep error.
- The tree walk queues seeds after the checkout's starts; the main walk pushes them onto phase 2 (K5).
- **outside_proj** projects a `//` name outside_ok rejects through `realpath -m`, so a dangling link into another root reads as the repo path.

## How to test

- `test/scripts/build-loop-check.bats`, the five U2b3b2b tests: config-dir seeds (memory, rules, prompts, auto memory, installed and uninstalled plugins, the managed policy, a relative CLAUDE_CONFIG_DIR); ancestors; C1 (an untracked start, a prompt, a `.CLAUDE` prompt, a symlinked start here, an @-free start, a worktree nested in `.claude/skills/`, no git in another root); the S1 projection; fail-closed cases (an unreadable seed directory, a newline name, a grep that exits 2).
- Each test is red on its base: the five on main's lib, iteration 2's assertions on 39f64d62, the final one on 8f99fcaf.
- `bl_setup` and `dev-cycle.bats` unset `CLAUDE_CONFIG_DIR`, so fixtures never read the real `~/.claude`; the sourcing inventory names the new functions and the global.
- Suites: build-loop-check 125, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2. `scripts/health-check.sh` passed on the branch.

## Areas of uncertainty

- **Cost**: over this repository's 8 worktrees, 50 seeds and 2 to 3.5 s per walk, against 0.5 to 0.85 s on main. Each seed holding an `@` costs 12 to 15 ms and their number is not capped (override row, revisit over ~200 seeds or a 5 s walk). Any find, grep or sha1sum failure fails the walk, so one unreadable directory in any other worktree holds every self-merge back.
- **Routed to U2b3b2c**: an import a start in another worktree reaches through a file that worktree holds with other bytes, or alone (i1 security F1); and a seed that is a dangling link into a reader root (final security F1). Seeding every @-bearing `.md` in other worktrees was tried and gave 6,720 seeds over /workspace's untracked clones, failing both walks; the fix is name-driven.
- **Named exceptions**: a host home or root this container cannot see (A3); a symlinked directory in another worktree (A5); a C1 skip in a checkout that is not clean (contract item 2).
- The final-pass fix (3b72bf8e, 1bb6040b) was not reviewed by the panel; the suites passed on it and the lite fix-drift check's one finding was refuted.

## Decisions made

- Plugins are seeds (installed versions), not a named exception.
- C1 reads other worktrees from the file system, never through git there.
- Split at review iteration 1: U2b3b2c owns other worktrees' differing non-start files and dangling-link seeds (an interim call taken without the user; the plan's U2b3b2c bullet carries it).

Decisions referenced: none — change is independent of recorded decisions (plan D5's floor, carried through the plan).

## Review evidence

Review converged in 3 iterations; 0 Must Fix; Must Address: 11 resolved, 4 acknowledged (two routed to U2b3b2c, one named exception, one deferred half).

- `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b2b.md` (iterations 1-3; the loop closed at 8f99fcaf)
- `docs/reviews/code-fact-check-report-build-loop-u2b3b2b.md` (iteration 1), `-i2.md` (iteration 2), `-final.md` with `-final-r1/-r2/-r3.md` (iteration 3)
- `docs/reviews/{security,performance,api-consistency,architecture}-review-2026-10-09-u2b3b2b.md` (iteration 1), `-i2.md` (iteration 2) and `-final.md` (iteration 3)
- 15 override-log rows dated 2026-10-09 for `feat/build-loop-u2b3b2b`

Retrospective: the first design read far more than it needed (12 s walks); the critics' measurements, not the plan, found the @ filter. Each iteration's fix to the C1 same-bytes skip broke it in a new way: it is a local copy of the walks' start rules, which U2b3b2c should own.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01WXq2z7f7uQu97mRuecPKLC
