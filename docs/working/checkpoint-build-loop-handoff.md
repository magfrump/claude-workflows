# Checkpoint: build-loop handoff
Date: 2026-10-04 (revision 3)
Branch: feat/build-loop-handoff (worktree `/workspace/.claude/wt-build-loop-handoff`)
Research: docs/working/research-build-loop-handoff.md
Plan: docs/working/plan-build-loop-handoff.md (revision 3)
Design conversation: docs/working/handoff-build-loop-handoff.md

## Project state
- **Branch purpose**: `scripts/build-loop.sh` (gate, markers, dispatch plumbing), the reader lib extracted from `scripts/dev-cycle.sh`, and the dev-cycle skill rewritten as an orchestrator loop that dispatches, collects and merges.
- **Position in larger initiative**: roadmap In flight "Build-loop handoff" (brief `docs/working/briefs/2026-10-02-build-loop-handoff.md`); Q-103 waits on it. Stacked units U0(a/b) → U1 → U2 → U3 → U3b → U4 → U5.
- **Blocked on**: your approval of plan revision 3 (RPI plan gate for this session's own work).

## Key findings
- Brief state has one reader: `check_brief` reads main's commit, never the working tree [observed]. `brief_fields` sits beside it in the lib.
- `check_answer` reads `docs/working/questions{,-archive}.md` from the **working tree** (`scripts/dev-cycle.sh:556`) [observed]. D8 moves it to main's commit.
- `dev-cycle.sh` conventions: many arguments per mode; one `ok`/`skip` line each; exit 0 when every argument was answered; `scrub` on all output; `pathform` ASCII names; FENCE_AWK refuses Markdown shapes it does not model (log 69) [observed].
- `~/.claude/scripts` and `~/.claude/skills` are the image's root-owned copies under `/opt/claude-workflows/` [observed 2026-10-04]. The installed skill lags main until a release.
- Research and plan docs are gitignored, so they reach a diff only when force-added [observed].
- `install.sh` `repo_git`/`git_state_gate` is the hardened-git prior art [observed].
- git 2.39.5 has `merge-tree --write-tree` [observed].
- Approval-doc comments: none after 2026-10-01. C1–C4 are unanswered as of 2026-10-04, so revision 3 uses their defaults.

## Plan (revision 3)
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
- D1–D12 await your approval.
- C1–C3 proceed on their defaults and are filed as entries in U5. C4 goes with roadmap item (a). C5 (the cost per iteration) is new, from F53.
- Whether U0 needs the a/b split: measure with pr-prep 1a before its review.
