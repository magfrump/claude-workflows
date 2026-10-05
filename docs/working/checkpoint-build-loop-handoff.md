# Checkpoint: build-loop handoff
Date: 2026-10-05 (revision 5; U1 built as U1a/U1b/U1c, waiting on Q-111 and Q-112)
Branch: feat/build-loop-handoff (worktree `/workspace/.claude/wt-build-loop-handoff`)
Research: docs/working/research-build-loop-handoff.md
Plan: docs/working/plan-build-loop-handoff.md (revision 4, approved)
Design conversation: docs/working/handoff-build-loop-handoff.md

## Project state
- **Branch purpose**: `scripts/build-loop.sh` (gate, markers, dispatch plumbing), the reader lib extracted from `scripts/dev-cycle.sh`, and the dev-cycle skill rewritten as an orchestrator loop that dispatches, collects and merges.
- **Position in larger initiative**: roadmap In flight "Build-loop handoff" (brief `docs/working/briefs/2026-10-02-build-loop-handoff.md`); Q-103 waits on it. Stacked units U0(a/b) → U1 → U2 → U3 → U3b → U3c → U4 → U5.
- **Blocked on**: Q-111 (U1a iteration 4) and Q-112 (the settings copy rule) since 2026-10-05; see "U1 state".
- **U0 landed 2026-10-05** as three stacked units, each through its own review-fix loop (3 iterations, final pass k=3 with the full critic panel): U0a `fa32a2ca`, U0b `7807e703`, U0c `f5bdd726` (merges on main). Rubrics: `docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0{a,b,c}.md`. Next: **U1**, on a new branch from main (the old `feat/build-loop-handoff` worktree is stale).

## U1 state (read first)
U1 is built as three stacked branches, each in its own worktree, none merged:

| Unit | Branch / worktree | Code lines | Review loop | Waiting on |
|---|---|---|---|---|
| U1a: lib `main_entry`, `brief_fields`, `check_answer` from main (D8), NUL refusal in FENCE_AWK | `feat/build-loop-u1a`, `.claude/wt-build-loop-u1a` | 360 | 3 iterations; cap gate **escalate** | **Q-111** (authorize iteration 4: fix R3, the `--help` sed range in dev-cycle.sh, and ambers A14–A18) |
| U1b: `build-loop.sh --settings` (policy, slots, never) | `feat/build-loop-u1b`, `.claude/wt-build-loop-u1b` | 400 | 3 iterations; cap gate **escalate** (the same finding fired twice) | **Q-112** (the copy rule for look-alike settings lines), then A16–A23 |
| U1c: the constraints line and `--status` | `feat/build-loop-u1c`, `.claude/wt-build-loop-u1c` | 399 | iteration 1 done: R1 (near-miss constraint lines, decided by Q-112), A1–A11, C1–C15; no fixes yet | Q-112, then U1b's merge |

- Each rubric (`docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1{a,b,c}.md` on its branch) ends with the open items. U1a's and U1b's end with the escalation template.
- **Next session:** read the answers to Q-111 and Q-112.
  - Q-111 [1]: fix U1a, run one full pass, land U1a. Then merge it into U1b and U1c.
  - Q-112 [1]: in U1b, add "best effort" wording and make self-merge require an exact `Self-merge never:` line (`none` for an empty list). Fix A16 (`core.useReplaceRefs` overrides `GIT_NO_REPLACE_OBJECTS`: pass `-c core.useReplaceRefs=false` or `GIT_CONFIG_COUNT`) and A18–A23, then one full pass. U1b is at the 400-line cap, so expect to trim or split.
  - U1c (2 iterations left):
    - fix R1 per Q-112;
    - A1: read the marker through git (`rev-parse SHA^{tree}`, `rev-list --parents -n1`) and refuse a NUL byte;
    - A4: count open briefs in `closed/` for F31;
    - A5: make `shared_branches` lazy or fail closed;
    - A3/A6–A11 wording;
    - C14: the unused `status_of`.
- Merging a lower unit into an upper one conflicts in `scripts/build-loop.sh`. Resolve by taking the lower unit's file and re-applying the upper unit's blocks (help, constraints awk and reader, `--status` code), then re-measure. Re-worded lines count twice against the cap.
- Choices taken in /away mode, all fail-closed (recorded in commit Notes):
  - an `error` outcome from main_entry and brief_fields that every caller skips;
  - letters-only key matching;
  - a never line must end at a blank line;
  - `GIT_NO_REPLACE_OBJECTS=1`;
  - NEVER as an array;
  - a `handoff:` tip that breaks a marker rule is a skip line, not a LOOP value;
  - the constraints grammar (`H<n>:`/`S<n>:`, a hard one followed by `success:`).
- Measured for override-log row 201: `check_brief`'s `git log -G` costs about 1 ms per brief on this repo. `--status` over 3 briefs takes about 80 ms. The U1c review found `shared_branches` quadratic in brief count (1.3 s at 100 briefs; C1, asks for a new decision on row 220).
- Tests: dev-cycle.bats 67, build-loop-read.bats 16 (at U1c). Test 21 in dev-cycle.bats fails when TMPDIR has a `.`-led part.

## U0 outcome
- The lib (`scripts/lib/dev-cycle-read.sh`) holds: `scrub`, `scrub_reexec`, the plain-file rules (`rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`, `skipped`), `need_root`, `pathform`, `isbrief`, `writable`, FENCE_AWK/`oddwhy`, `main_by_name`, `check_brief`, `check_branch`, `resolve_main`, INSTRUCTION_FILE and the import walk (`lower`, `imported_names`), ANSWER_AWK/`check_answer`. `check_path`, `check_write` and `check_fix` stay in dev-cycle.sh.
- Its header is the caller contract: cd to the top level and set `ROOT_REAL="$(pwd -P)"`; `need_root` exits 1 otherwise; call `resolve_main` once and rely on `main_by_name`, not its return code; capture `check_*` output as plain `out="$(...)"` under `set -e` and treat any line that is not a positive answer as a refusal; print it through `scrub`.
- **Plan amendment (Approach, 2026-10-05):** `check_fix`'s predicate is not extracted; U2 writes D5's floor as its own lib function (leading-dot-aware dot test, an `isimported` predicate, and a stated import start set for the gate: a clean worktree at `MAIN_SHA` plus, or a recorded gap for, the checkout's untracked instruction files). F11's row and step 13 carry the precondition.
- **Deferred to later units** (override-log rows dated 2026-10-05, `feat/build-loop-u0*`): U1 — test sourcing the lib from build-loop.sh's side, `check_answer` rewrite (positive-line only, `main_by_name`, drop its SKIPPED side effect), measure `check_brief`'s `git log -G` per brief, call the lib in-process; U2 — the floor function, `isimported`, an unguarded inner helper for the walk; U3 — `--merge` checks `main_by_name`; U3b — D6 hash-checks the lib too.
- Tests: `test/scripts/dev-cycle.bats` has 59 (main's 53 plus T29, T30 and four guard tests). Test 21 fails when TMPDIR has a `.`-prefixed component (pre-existing, environmental).

## Key findings
- Brief state has one reader: `check_brief` reads main's commit, never the working tree [observed]. `brief_fields` sits beside it in the lib.
- `check_answer` reads `docs/working/questions{,-archive}.md` from the **working tree** (`scripts/dev-cycle.sh:556`) [observed]. D8 moves it to main's commit.
- `dev-cycle.sh` conventions: many arguments per mode; one `ok`/`skip` line each; exit 0 when every argument was answered; `scrub` on all output; `pathform` ASCII names; FENCE_AWK refuses Markdown shapes it does not model (log 69) [observed].
- `~/.claude/scripts` and `~/.claude/skills` are the image's root-owned copies under `/opt/claude-workflows/` [observed 2026-10-04]. The installed skill lags main until a release.
- Research and plan docs are gitignored, so they reach a diff only when force-added [observed].
- `install.sh` `repo_git`/`git_state_gate` is the hardened-git prior art [observed].
- git 2.39.5 has `merge-tree --write-tree` [observed].
- Approval-doc comments: none after 2026-10-01. C1–C4 are unanswered as of 2026-10-04, so revision 3 uses their defaults.

## Plan (revision 3 summary; revision 4 changes are in the walk-through section below)
- D1: the orchestrator starts loops (`--start` + a background subagent); after a restart it re-dispatches, with at most 2 resumes without progress.
- D2: no plan gate in loops; questions go in a `blocked` marker.
- D3: markers `ready` / `blocked` / `stopped`.
- D4: collect, per brief:
  - self-merge → the orchestrator runs `--merge`;
  - review → a PR, or a `merge-STEM-SHA12` entry;
  - blocked → entries `Asked: Q@SHA`, and the slot is freed;
  - stopped → an entry.
- D5: allowlist.
- D6: the **orchestrator** runs the gate from main's commit, extracted to a temp dir; a loop's own `--check` is advisory.
- D7: merge-tree + CAS.
- D8: answers are read from main's commit.
- D9: `Build-loop slots: N`, default 3.
- D10: your override of "user reads each brief" goes in as log row 70.
- D11: the orchestrator is the only questions writer.
- D12: `/loop /dev-cycle`; event-driven wakes plus a cheap wait.
- D13 (from the rev 3 pre-mortem): the orchestrator runs from a non-checkout directory, in its own worktree per iteration; `--state`, `--main-log` and `--cycle-diff` checks.
- D14: quiesce is scoped to own subagents; `flock` on `health-check.sh`; the loop prompt allows only research and review subagents.
- The D6 snippet is hardened: no replace refs or grafts, hash checks, root-commit identity, the `/opt` path by absolute path (F38–F40).
- Blocked bodies are plain prose; `--marker` refuses grammar lines and `> `-quotes the rest (F41; E2/E3 reproduced).

Steps: U0 lib → U1 read modes (`--settings`, `--status`, `--marker`, `--state`) and `check_answer` from main → U2 `--check` → U3 `--start`/`--prompt` (lock, dispatch cap)/`--merge --approved` → U3b `--main-log`, `--cycle-diff`, health-check `flock` → U4 SKILL.md and the pr-prep quiesce line → U5 docs, roadmap items (a)–(d), C1–C5 entries, release entry, Q-103 re-route, brief → done.

## Invariants
- Briefs, policy, slots and answers that unblock work are read from main's commit only.
- Branch names reach git only via `show-ref --verify refs/heads/<name>`.
- A refused (FENCE_AWK) file is never read: policy → review, brief → no start and no self-merge.
- Only the orchestrator's gate run, from main's commit or the image copy, moves main.
- `Status: done` in the merged change is what closes an item.
- Never check out or switch a branch in a checkout the script did not create.
- dev-cycle.sh's 53 tests stay green through the extraction (answer tests are updated in U1 to commit their fixtures).
- Each review unit stays at about 400 changed code lines or under.

## File map
- `scripts/lib/dev-cycle-read.sh`: new (U0, U1).
- `scripts/dev-cycle.sh`: sources the lib (U0).
- `scripts/build-loop.sh`: new (U1–U3).
- `test/lib/build-loop-fixtures.bash`, `test/scripts/build-loop-{read,check,merge}.bats`: new.
- `test/scripts/dev-cycle.bats`: T29–T30, and the answer fixtures committed (U1).
- `skills/dev-cycle/SKILL.md` (U4).
- `docs/dev-cycle.md`, `workflows/codebase-onboarding.md`, `docs/decisions/log.md`, `docs/working/seed-build-loop-handoff.md`, `docs/roadmap.md`, `docs/working/questions.md`, the brief (U5).

## Open questions
- Approved 2026-10-04 (walk-through below); revision 4 applied.
- C1–C3 proceed on their defaults and are filed as entries in U5. C4 goes with roadmap item (a). C5 (the cost per iteration) is new, from F53.
- Whether U0 needs the a/b split: measure with pr-prep 1a before its review.

## Walk-through of D1–D14 with the user (2026-10-04; applied as revision 4)
- D1: presented; no change requested.
- D2 (changed): the loop asks by DD's criterion. Path A (one option dominates at over 80%) → proceed. No clear winner, or no option survives even after the Double Diamond → `blocked`, with DD's scorecard, options and axis in the body; the orchestrator files it as `you: judgment` (async Path B). No `docs/constraints.md` (hard constraints with IDs and `success:` lines) → no dispatch, one entry asking for it, and a roadmap item "process for creating the constraints doc" (owner attention). Constraints are seeded into every loop prompt and DD run. Drift check: step 4's spot-check reads one Path A decision from a sampled build-loop merge and flags a soft constraint used to prune, or an unlisted constraint that decided the pick; a finding is a deep-audit trigger, and the audit gains a "constraints and guidance" dimension. Loops force-add their research doc so DD records land. No ledger (the user preferred sampling).
- D3: presented; no change requested. The stop list could later move "new dependency" into a constraint.
- D4: approved as written. Future direction to note in the plan: on a refused self-merge, send it back to the loop once with the refusal before asking the user.
- D5 (changed): the floor is narrowed to what takes effect on merge with no later review: (1) files sessions load from the checkout (instruction files and their `@`-imports, `.claude/`), (2) `.gitattributes`/`.gitmodules`, (3) the gate's own code (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/dev-cycle-read.sh`), which needs a `merge-gate-` review entry even under self-merge (user chose [1]), (4) cycle-owned files including `docs/constraints.md` (N-denied), (5) symlinks and gitlinks (the exec bit is now allowed). Code, scripts and skills are otherwise self-mergeable within `Paths:`. `docs/dev-cycle.md` gains an optional `Self-merge never:` glob list per project. The user agreed that a **release is the real gate** for code in this repo: the release entry must list the commits and changed paths since the last release, for review at release time. Future direction: whether the floor itself should come from per-project settings.
- D6–D11: presented; approved with no change. Noted as possible later hardening: signed commits to tell user answer-only commits from a loop's (D8); a cap on open loop questions while the user is away (D9, not added).
- D12 / C5: the user answered in-session: start with [1] (a full cycle every iteration), and plan to move to [2] (a light pass between full cycles) once the real cost is visible. File C5 as ANSWERED, and add a roadmap Next item to revisit it after a few days of loop runs.
- D13, D14: approved with no change.
- Revision 4 also keeps the whole dotfile family on the floor (not only `.claude/`, `.gitattributes` and `.gitmodules`), because several dotfiles run on their own (`.envrc`, `.npmrc`, `.devcontainer/`), and it sets an interim `Self-merge never: workflows/` here, because loops in this repo read workflows from their own checkout. Both are flagged to the user.
