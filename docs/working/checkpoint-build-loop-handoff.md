# Checkpoint: build-loop handoff
Date: 2026-10-02
Branch: feat/build-loop-handoff (worktree `/workspace/.claude/wt-build-loop-handoff`)
Research: docs/working/research-build-loop-handoff.md
Plan: docs/working/plan-build-loop-handoff.md

## Project state
- **Branch purpose**: `scripts/build-loop.sh` (gate and state for autonomous build loops), the shared reader lib extracted from `scripts/dev-cycle.sh`, and the dev-cycle skill/doc changes that describe the handoff as built.
- **Position in larger initiative**: roadmap In flight "Build-loop handoff" (brief `docs/working/briefs/2026-10-02-build-loop-handoff.md`); Q-103 waits on it. Stacked units U0(a/b) → U1 → U2 → U3 → U4.
- **Blocked on**: plan revision 3. **Revised 2026-10-03:** this checkpoint describes revision 2. The design conversation replaced D1–D4, D6's bless dependency and the In flight lifecycle. Read `docs/working/handoff-build-loop-handoff.md` first. The gate parts below (D5, D7, invariants, file map for the script and lib) still hold.

## Key findings
- Brief state has one reader: `check_brief` reads main's commit, never the working tree [observed]. Keep it that way: `brief_fields` lives beside it in the lib.
- `dev-cycle.sh` conventions: many arguments per mode; one `ok`/`skip` line each; exit 0 when every argument was answered; `scrub` on all output; `pathform` ASCII names; FENCE_AWK refuses Markdown shapes it doesn't model (log 69) [observed].
- `~/.claude/scripts` is the image's blessed copy at `/opt/claude-workflows/scripts`, not this checkout [observed].
- Research and plan docs are gitignored; they reach a diff only when force-added [observed].
- `install.sh` `repo_git`/`git_state_gate` is the hardened-git prior art: hooksPath=/dev/null, fsmonitor off, no optional locks, refuse local filter/include/fsmonitor/hook keys and `info/attributes` [observed].
- git 2.39.5 has `merge-tree --write-tree` [observed].
- Review history: 27 findings over passes 6–11. The pre-mortem added F25–F31 and L1–L3 (`docs/reviews/pre-mortem-build-loop-handoff.md`).

## Plan
D1 the user starts loops (`--start`/`--prompt` print the prompt) · D2 plan approval stays in the loop (explicit approve-plan, else the `handoff: plan` marker) · D3 markers → early keep-or-drop entries (`ready`: keep/drop only, with the merge command; re-filed only after a newer marker) · D4 the user runs `--merge --expect <sha>` to approve · D5 allowlist gate (`Paths:` plus own files keyed on the full brief stem) over a `check_fix` floor · D6 the gate refuses to run from inside the repo it judges · D7 merge-tree → diff-tree checks → commit-tree → CAS, all git hardened.

Steps (full detail in the plan):
1. Extract the lib (U0, maybe U0a/U0b).
2. Read tests.
3. `brief_fields`, `--policy`, `--status`.
4. Check tests.
5. `--check`.
6. Merge tests.
7. `--start`, `--prompt`, `--merge`.
8. Skill changes.
9. Docs (settings, onboarding, log row 70, seed status).
10. Q-103 re-route plus a bless `you: terminal` entry, and this brief → done.

Tests first in each unit.

## Invariants
- Briefs and policy are read from main's commit only.
- Branch names reach git only via `show-ref --verify refs/heads/<name>`.
- A refused (FENCE_AWK) file is never read: policy → review, brief → no start and no self-merge.
- Keep-or-drop answers go only through `--check-answer` and `Asked:`/`Applied:`.
- `Status: done` in the merged change is what closes an item.
- Never check out or switch a branch in a checkout the script did not create.
- dev-cycle.sh's 53 tests stay green through the extraction.
- Each review unit stays at ~400 changed code lines or under.

## File map
- `scripts/lib/dev-cycle-read.sh`: new, the extracted reader (step 1, 3).
- `scripts/dev-cycle.sh`: sources the lib (step 1).
- `scripts/build-loop.sh`: new (steps 3, 5, 7).
- `test/lib/build-loop-fixtures.bash`: new, throwaway repos with briefs and branches (step 2).
- `test/scripts/build-loop-read.bats`, `build-loop-check.bats`, `build-loop-merge.bats`: new (steps 2, 4, 6).
- `test/scripts/dev-cycle.bats`: characterization only; add T29–T30 (step 1).
- `skills/dev-cycle/SKILL.md`: machine lines, In flight check 3, final message, the F28 note (step 8).
- `docs/dev-cycle.md`, `workflows/codebase-onboarding.md`, `docs/decisions/log.md`, `docs/working/seed-build-loop-handoff.md` (step 9).
- `docs/working/questions.md`, `docs/working/briefs/2026-10-02-build-loop-handoff.md` (step 10).

## Open questions
- D1–D7 await the user's approval.
- Whether U0 needs the a/b split: measure with pr-prep 1a before its review.
- [assumed] `git -C W merge --ff-only` with hooksPath=/dev/null runs no checkout filter when the state gate passed. T26 and T23 verify it.
- F19, F28 not covered; F11, F21, F29 partly. All go to Q-103.
