# Checkpoint: build-loop handoff
Date: 2026-10-06 (revision 9; U2a2 landed; next U2a3, then U2a3b)
Branch: feat/build-loop-u2a3 (worktree `/workspace/.claude/wt-build-loop-u2a3`, at 579ebca2) and feat/build-loop-u2a3b (worktree `/workspace/.claude/wt-build-loop-u2a3b`, at 3156b995, stacked on U2a3); neither rebased onto main 0fbf9742 yet
Research: docs/working/research-build-loop-handoff.md
Plan: docs/working/plan-build-loop-handoff.md (revision 4, approved; step 5 holds the U2 split note)
Design conversation: docs/working/handoff-build-loop-handoff.md

## Project state
- **Branch purpose**: `scripts/build-loop.sh` (gate, markers, dispatch plumbing), the reader lib extracted from `scripts/dev-cycle.sh`, and the dev-cycle skill rewritten as an orchestrator loop that dispatches, collects and merges.
- **Position in larger initiative**: roadmap In flight "Build-loop handoff" (brief `docs/working/briefs/2026-10-02-build-loop-handoff.md`); Q-103 waits on it. Stacked units U0 → U1 → U2 (U2a1 → U2a2 → U2b → U2c) → U3 → U3b → U3c → U4 → U5.
- **Blocked on**: nothing. Next: U2a3 (rebase onto main, then its own review loop), then U2a3b. Q-119 (the U2a split, interim [1]) is open for the user and blocks nothing.
- U0 landed 2026-10-05 (U0a `fa32a2ca`, U0b `7807e703`, U0c `f5bdd726`); U1 landed 2026-10-05/06 (U1a adff525b, U1b 62830b0a, U1c 9f78df7e, U1d 4e12b03c). Rubrics: `docs/reviews/code-review-rubric-2026-10-0{4,5,6}-feat-build-loop-u*.md`.

## U2 state (read first)
U2 was first built as one unit, U2a (`feat/build-loop-u2a`, not merged), which hit the 3-iteration cap; it was split (Q-119, interim [1]), and its second half split twice more at the 400-line cap:

| Unit | State | What |
|---|---|---|
| U2a1 | **merged 1a94773c** | main_entry's badform word, entry_why, isclosed, constraints.md for --check-fix, U1d's rows. |
| U2a2 | **merged 1ffb72d4** (2026-10-06) | The shared token parser `import_targets` (U+FEFF, a punctuation-ended token's whole and stripped name, ..x, NUL), `isimported tree` for check_fix, U2a1's carried rows C12-C14. Loop: 3 iterations (iteration 1 short-circuited at fact-check; 2 split main_imports out; 3 final, k=3, full panel, Stage 2.5); rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md`, loop closed at 7697c6e6. D1 (an @ after a Unicode space is swallowed, as on main) waived and fixed in U2a3b. |
| U2a3 | branch 579ebca2, **unreviewed**, on U2a2's 7697c6e6 | `main_imports` (the commit-reading walk) and `isimported main`, with U2a2 iteration 2's rows B2-B6, B8, B10-B12 fixed (nested .claude/rules, unreadable checkout file, short tr output, link text leaving the repo, IMPORTED_MAIN starts as error, A5/F11 wording, test-strategy patch). 344 code lines against U2a2. Its pre-split history (iterations 1-2 of U2a2) is on `feat/build-loop-u2a3-src` and `feat/build-loop-u2a2-full`. |
| U2a3b | branch 3156b995, **unreviewed**, on U2a3 | Parser parity with Claude Code (Unicode spaces and NUL become blanks before the grep; Markdown cut points [ ] ( ) < ! * _; only ~/ dropped) and fail-closed walks (parser returns 1 on sed/grep failure; imported_names and main_imports fail on a failing lower). Fixes U2a2's final-pass D1-D3. 98 code lines against U2a3. |
| U2a4, U2b, U2c | not started | U2a4: the floor (`floor`, `ownfile`, `GATE_CODE`; code on `feat/build-loop-u2a2-full`) with the shared check_fix/floor predicate (rows C1, C3, 308). Plan step 5 for U2b, U2c. |

**Next steps:**
1. Rebase U2a3 onto main (U2a2 merged with post-split review docs only; expect conflicts in docs/reviews/override-log.md at most), then its own review loop (fresh counter; carry B14's untested candidates and the final-pass D8 nested-repo candidate into its review brief). U2a3's known-issues A5 says "(main_imports, U2a2)": fix to U2a3 (final fact-check E4).
2. Then U2a3b on U2a3, its own loop; apply test-strategy final Patch A where it still applies (override row G1-G8).
3. Then U2a4 (the floor), U2b and U2c as in plan step 5, carrying the older U2 triggers: C18/R5 (replace refs, origin/HEAD) are U3b's `--state`; A21 brief enumeration into the lib; globform into the lib; check_branch and marker_kind ignoring `git log` failures under a broken config (row 307); the per-path ls-tree cost (rows 220, 310); C16 (`pin_hermetic_git`) when a row-327 suite is edited.

Also merged on the user's request after U2a2 (2026-10-06): `feat/web-taint-fetch-log` (b8807e76) and `feat/egress-claude-config` (0fbf9742; `Live-verified: no`, carried from its commit). Main at 0fbf9742 passes scripts/health-check.sh.

**Gotchas found in U1-U2a2:**
- The hermeticity lint misreads an apostrophe inside double quotes as a quote. Keep skip messages free of `'`, or the full gate fails (`test/fixture-hermeticity.bats`).
- Changing a line that is already on main counts twice against the 400-line cap.
- `questions.sh archive` matches entries by ID, so take `next-id` from fresh main (memory `questions-id-collision-concurrent-sessions`).
- dev-cycle.bats test 25 fails whenever TMPDIR has a dot-prefixed component, such as the job scratch path under `~/.claude`. Run the suites with `TMPDIR=$(mktemp -d /tmp/<tag>-XXXX)`.
- Review agents: tell each to write only its own report and to use its own scratch dir, with a prefix no other agent's cleanup glob matches (a replicate's `rm -rf /tmp/<shared-prefix>-*` can delete a sibling's TMPDIR).
- A literal backtick in lib code (even escaped in a `[[ ]]` pattern) makes the hermeticity lint read the rest of the file as a command substitution; write it as the escape `$'\x60'`.
- Under pipefail, `a | grep` reports grep's "no match" (1) and hides a failure of `a`; split the steps when the status matters.
- A comment line that starts with "Claude" can trip the hermeticity lint (it reads the first word as a command).
- Review agents: A merge agent can put a "Claims Requiring Attention (summary)" heading near the top of the merged report; append Stage 2.5 claims after the last claim, not before the first such heading.

- Tests on main: dev-cycle.bats 75, build-loop-read.bats 19, build-loop-check.bats 2, fixture-git-env.bats 2 (100 with hermeticity).
- Stale worktrees of merged branches remain (`.claude/wt-build-loop-u1{a,b,c,d}`, `.claude/wt-build-loop-u2a1`, `.claude/wt-build-loop-u2a2`, `.claude/wt-build-loop-handoff`; branches `feat/build-loop-u2a2-full` and `feat/build-loop-u2a3-src` hold pre-split history), plus the superseded `.claude/wt-build-loop-u2a` (its branch holds the U2a review history and is not to be merged). Removing them, and deleting merged branches, is the user's call.

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
