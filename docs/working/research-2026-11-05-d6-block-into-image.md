# Research: the D6 block becomes one root-owned image script

- **Goal**: The orchestrator runs `build-loop.sh`, `dev-cycle.sh` and `questions.sh` through one short call to a root-owned image script, in place of the ~60-line block the skill has it paste into every call.
- **Problem framing**: The paste costs context on every call and invites copy slips while guarding nothing the image copy does not already guard. Considered and discarded: "the call should run `bash /opt/.../scripts/SCRIPT` with no wrapper" (the audit's other wording), which would lose the variable scrub (R6f, KEEP) and the exactly-one-default check for `dev-cycle.sh` and `questions.sh`.
- **Project state**: Moves the D6 block into `scripts/d6.sh` · restriction audit unit 7 (row R6b, with R6c-R6e's block side) · not blocked (cite: docs/working/research-2026-11-01-restriction-audit.md)
- **Task status**: in-progress (design and plan done, implemented; review next)

Seeded with `docs/constraints.md` at 5b20d4bd.

## What exists

- The block: `skills/dev-cycle/SKILL.md`, "## The D6 block", pasted as `bash -s -- SCRIPT ARG... <<'D6'`. It refused on a replace ref, `info/grafts`, not exactly one of main and master, a symbolic or non-commit default branch, and a missing, non-regular or not-root-owned image file or parent directory. It then ran `/opt/claude-workflows/scripts/SCRIPT` with six variables unset [observed].
- The payload: `devcontainer-config/install.sh` `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`, extracted from one commit, a missing item fatal (FP-158). `Dockerfile` copies it to `/opt/claude-workflows/`, `chown -R root:root`, directories 0555, files 0444, and `*.sh`/`*.py` 0555 [observed].
- The installed skill: the home `skills` directory is a symlink to `/opt/claude-workflows/skills`, and the home `scripts` directory to `.../scripts` [observed in this container]. Plan D6: "inline in the installed SKILL.md, which is the root-owned image copy". No project-level skill copy shadows it in this repo [observed].
- Tests: `test/scripts/build-loop-orchestrator.bats` read the block back with awk (`d6_copy`), T27, T33, T36, T37, and pinned `G=` to the lib's HARDEN. `test/scripts/build-loop-check.bats` lists gate paths for the floor.
- GATE_CODE restated: `scripts/lib/dev-cycle-read.sh` (the one definition), SKILL step 0.1's PATHS line and the slug rule (both test-pinned), `scripts/build-loop.sh` header.

## Invariants

- R6a/H1: each call runs the root-owned image copy by absolute path, never a working-tree copy, and nothing in the repository or environment chooses which [observed: audit R6a KEEP].
- The skill's Rules key on a `refuse d6: WHY` first line with exit 2 [observed: SKILL Rules, step 0.1, step 1b]; exit 1 for a bad first argument stays, and the Rules now state it.
- The script must start from the caller's environment, with no pair of d6's exported: its own `git_harden` would count them as the caller's, and SKILL's Rules forbid exporting pins (`--state` no longer refuses one; row 702) [observed].
- R6f: the six variables stay unset for the child, and stdin stays closed (`</dev/null`) [observed].
- H1's success line: a new gate path joins GATE_CODE.

## Prior art

`git_harden` in `scripts/lib/dev-cycle-read.sh` is the one hardening list. The block repeated it only because "the snippet runs before anything is checked, so it cannot source the lib"; a file in the image has no such limit, as its presence checks run first.

## Gotchas

Failure-pattern grep: FP-021, FP-098, FP-158

- FP-021 (an agent-writable file baked into the image, a claim nobody checked): the file's protection is the image's. `scripts/d6.sh` in a working tree is agent-writable, but only the image copy is ever called, and that copy is built from a commit the owner releases.
- FP-158 (a missing payload source warned and went on): a missing payload item is now fatal at install, and `scripts` is one directory item, so a commit holding d6.sh cannot assemble a payload without it.
- FP-098 (a root-owned volume against uid 1000): only confirms that ownership differences show up at runtime; nothing here depends on it.
- `info/grafts` is NOT switched off by `GIT_NO_REPLACE_OBJECTS` or `core.useReplaceRefs=false`, contrary to the audit's reason for R6c. Probe in a scratch repo, three commits, one cut: with a graft `rev-list --count` gave 2 with and without those pins; with `git replace --graft` it gave 2 plain and 3 hardened [observed].
- A `.sh` suffix is what earns 0555: a `bin/d6` with no suffix would be 0444.

## Design

Constraints applied: H1, H2, H3, S1, S3, S4, S8 (no growth of `install.sh`), S10 (the release stays the one paste).

### 1. Where it lives and how it gets into the image (divergent design, Path A)

| Option | Image route | Cost | Verdict |
|---|---|---|---|
| **`scripts/d6.sh` → `/opt/claude-workflows/scripts/d6.sh`** | already a payload item, `.sh` is 0555 | none: no installer or Dockerfile change | **picked** |
| `bin/d6` → `/opt/claude-workflows/bin/d6` (the audit's "e.g.") | a new payload item in `install.sh`; no suffix, so 0444 unless the Dockerfile changes | grows `install.sh` (S8), touches enforcement files (Live-verified, a host probe) | pruned |
| `/usr/local/bin/d6` by `COPY` | Dockerfile edit, outside the commit-pinned payload, so skill and script could differ | enforcement file; a PATH lookup would let PATH choose (H1) | pruned |
| No wrapper: `bash /opt/.../scripts/SCRIPT` | nothing new | loses R6f's scrub (KEEP) and the default-branch check on two scripts | pruned |

One option dominates: it alone needs no enforcement-file change, and it ships in the same payload as the skill. Its call is `bash PATH`, not a bare `PATH`: the same message under zsh and bash, and independent of the mode bit.

D6_OPT stays a literal. Reading it from the environment would let a caller choose the gate (H1); deriving it from the file's own path would make a working-tree `bash scripts/d6.sh` run the working tree's gate. A test pins the literal and forbids `BASH_SOURCE`, `$0` and `dirname`.

### 2. Which of R6c, R6d and R6e keep their checks (divergent design, Path C)

Options: (A) keep every check, a pure move; (B) apply the audit's verdicts, each re-checked against the code; (C) remove every check and keep only the exec. C fails H2 (R6d's exactly-one, R6e's presence). A and B both pass the hard lines. S1 and the brief's motive ("remove every restriction without a specific, in-scope threat model") rank B first, and the audit's rule for units is to apply a verdict and record any row kept after all. But the brief's Goal sentence says "the block's checks keep running", while its criteria ask which rows keep theirs, so B is a tentative pick put to the owner below. The move is commit da07a77c, with every check kept: restoring `scripts/d6.sh` and the D6 tests from there gives A, after updating one test phrase for step 0.1's later wording and two comments in the lib (a review probe: 16 of 16 filtered tests green with those). Later commits touch the same lines, so a plain revert of the narrowing commit no longer applies alone, as its message says it would.

| Row | Check | Re-check | Decision |
|---|---|---|---|
| R6c | replace ref | The gate's git ignores it (the probe above); `git_harden` sets both pins. The refusal stopped a repo for a ref nothing reads. | **drop** |
| R6c | `info/grafts` | The audit's reason does not cover this: hardened git does follow grafts. Still dropped: `--state` dropped it (unit 1, G5) and that research accepts the residual; git has deprecated the file and prints a hint on reading one; honest use is a deliberate history splice that everything then reads consistently; a planted one is hostile, out of scope by S1. | **drop**, residual stated |
| R6d | exactly one of main/master | H2: an ambiguous default, and the only such check `dev-cycle.sh` and `questions.sh` have. | **keep** |
| R6d | symbolic ref, non-commit ref | `default_gate` refuses both in `--state` [observed: `scripts/build-loop.sh`; a new test pins it through d6], and `--state` opens every iteration. | **drop** |
| R6e | file present, regular, not a symlink | H2: the stale or partial image. | **keep** |
| R6e | ownership walk to `/` | Now self-referential: a uid able to write `/opt` rewrites d6.sh too, so a check inside the image cannot vouch for it. The Dockerfile's chown and chmod hold H1 (pinned in `test/cc-isolated-functions.bats`). It also refused a run as root. | **drop** |

Dropping the walk also lets the tests run the shipped file with one literal changed and no `own()` substitution (rule: test a check in its real position).

### 3. Hardening list (one-line note)

d6.sh's only git call is now `show-ref`, run through the image lib's `git_harden` in a subshell (S3: the repeated `G=` list and its "may stay" allowance end), so nothing is exported to the script.

### 4. Release ordering and what the orchestrator sees

The skill and d6.sh are items of one payload, extracted from one commit into one image, and a session's skill is that image's copy. So they change together, at the release.

| Skill (where) | Image | What happens |
|---|---|---|
| old (image) | old | Today. The merge to main changes nothing for running sessions; step 0.1 sees `skills/dev-cycle/` differ and files `image-lag`, the release entry. |
| new (image) | new | The normal state after the release paste and a relaunch. |
| old (a pasted block, for instance in a resumed session's context) | new | Works: the block's four files stay in the image, root-owned. No flag day. |
| new (read from a checkout, not the image) | old | `bash` prints `/opt/claude-workflows/scripts/d6.sh: No such file or directory`, exit 127, empty stdout, nothing ran. The Rules read that as the refusal: a stop, and at step 0.1 its entry gives the release paste. |

H2's "a missing script refuses and names the gap" is met by that line and the Rules. An inline guard in the call line would print a `refuse d6:` line, but it is a paste again, on every call, for a state the payload makes unreachable through the installed skill.

## Plan

1. `scripts/d6.sh` as a straight move, every check kept; skill Rules and mentions; GATE_CODE, its pins and restatements; tests read the file. Commit.
2. Narrow to section 2's decisions and `git_harden`; tests for each refusal, the pass path, the dropped checks and the hardening. Mutation-check the file. Commit.
3. Plan D6 amendment; this doc. Commit.
4. Health check, then the review-fix loop, then the brief's Status line and the marker.

### Pre-mortem (bypass families)

Assume this shipped and an enforcement path failed.

1. **A working-tree copy runs as the gate.** A session calls `bash scripts/d6.sh` from a checkout. The root is a literal, so it still runs the image's scripts; the reach is that copy's own pre-checks. Guard: the literal and its test, and T33's "never main's or the working tree's".
2. **The environment chooses.** `D6_OPT`, `BASH_ENV`, `ENV`, or a PATH `bash` or `git`. D6_OPT is assigned, never read. BASH_ENV applies to `bash d6.sh` as it did to `bash -s`: the same-uid residual Q-103 accepts, unchanged. The scrub is pinned by a new test.
3. **The release gap.** After the merge and before the release, the image's floor does not list `scripts/d6.sh`, so a self-merge naming it in `Paths:` would pass unflagged. Bounded: it reaches a session only through the release, and the `image-lag` entry this merge opens lists every changed path outside `docs/`, this file among them. The new image's GATE_CODE closes it. Step 0.1's old PATHS line also omits the file, but `skills/dev-cycle/` differs from the same merge until the release. To close the window sooner, the cycle can add `scripts/d6.sh` to `Self-merge never:` in `docs/dev-cycle.md`, which the old image reads from main, or dispatch no brief touching the file before the release; this branch may not edit that file. The security review rated the window Medium.
4. **A refusal read as a pass.** The 127 path has empty stdout, so a reader of "the first line" sees nothing. The Rules state it, step 1b's "if either fails, go on" names it as still a stop, and a test pins those phrases. Step 0.1 comes first in every iteration, so the stop lands there anyway.
5. **A regression through sourcing.** The lib is sourced in a subshell. A lib that fails to load, or a `git_harden` that refuses the environment, is tried alone before the loop and named as such (review i1), so exit 1 in the loop comes from `show-ref`. That exit also covers a ref git cannot use (a junk file, a dangling symbolic ref, an unreadable file): it counts as absent, as it did in the block. Beside a good name that passes; alone it refuses as "not exactly one". A test proves no pair reaches the script and every git call carries the pins.
6. **Planted history.** A planted `info/grafts` now reaches `--main-log`. Hostile-only (S1); `--state` already accepted it in unit 1.

### Test plan

Each refusal and the pass path in `build-loop-orchestrator.bats`, against the shipped file with D6_OPT changed: both or neither default branch, a non-repository, missing and non-regular files (a directory and a dangling link), a bad first argument; the 127 path through the skill's own call line; the variable scrub and closed stdin; hardening through the T26 shim; the dropped checks pinned as passing, and `--state` still refusing the two default-branch shapes.

## Question for the owner

The brief's Goal says the block's checks keep running; its criteria ask which of rows R6c, R6d and R6e keep theirs. The tentative pick drops what the audit marked hostile-only, and the audit's reason for grafts turned out wrong (hardened git follows them). Tiebreaker: the audit's rule that a unit applies a verdict and records any row it keeps.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Apply the audit (picked)** | d6.sh keeps exactly-one default and file presence; the replace, grafts, symbolic, non-commit and ownership checks go | none | a planted graft reaches `--main-log`: hostile-only, S1 |
| **[2] Keep every check** | restore `scripts/d6.sh` and the D6 tests from da07a77c, the move with every check kept, plus one test phrase and two lib comments | one line in the review, then one small branch | the refusals stay: a replace ref stops a repo for a ref nothing reads |

## Files read

Last verified: 2026-11-05
docs/constraints.md
docs/failure-patterns.md
docs/working/research-2026-11-01-restriction-audit.md
docs/working/research-2026-11-01-relax-gate-git-state.md
docs/working/research-2026-11-01-relax-dev-cycle-skill-prose.md
docs/working/plan-build-loop-handoff.md
skills/dev-cycle/SKILL.md
scripts/build-loop.sh
scripts/dev-cycle.sh
scripts/lib/dev-cycle-read.sh
scripts/lib/migrations.sh
devcontainer-config/install.sh
devcontainer-config/Dockerfile
devcontainer-config/link-claude-home.sh
hooks/live-verify-gate.sh
test/scripts/build-loop-orchestrator.bats
test/scripts/build-loop-check.bats
workflows/research-plan-implement.md
workflows/pr-prep.md
