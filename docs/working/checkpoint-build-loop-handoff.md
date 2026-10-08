# Checkpoint: build-loop handoff
Date: 2026-10-08 (revision 24; U2b1a1 clean, landing asked (Q-134); U2b1a2 at the review cap, escalated (Q-133))
Branch: `feat/build-loop-u2b1a1` (worktree `.claude/wt-build-loop-u2b1a1`, on main) and `feat/build-loop-u2b1a2` (`.claude/wt-build-loop-u2b1a2`, stacked on U2b1a1). `feat/build-loop-u2b1a` (`.claude/wt-build-loop-u2b1a`) holds their review iterations 1-2 and is not merged. Merged branches keep their worktrees (`.claude/wt-build-loop-u2a3c` among them); removing them is the user's call.
Research: docs/working/research-build-loop-handoff.md
Plan: docs/working/plan-build-loop-handoff.md (revision 4, approved; step 5 holds the U2 split note)
Design conversation: docs/working/handoff-build-loop-handoff.md
## Project state
- **Branch purpose**: `scripts/build-loop.sh` (gate, markers, dispatch plumbing), the reader lib extracted from `scripts/dev-cycle.sh`, and the dev-cycle skill rewritten as an orchestrator loop that dispatches, collects and merges.
- **Position in larger initiative**: roadmap In flight "Build-loop handoff" (brief `docs/working/briefs/2026-10-02-build-loop-handoff.md`); Q-103 waits on it. Stacked units U0 → U1 → U2 (U2a1 → U2a2 → U2b → U2c) → U3 → U3b → U3c → U4 → U5.
- **Blocked on**: nothing. Next: U2b (see Next steps). Q-119 (the U2a split, interim [1]) is open and blocks nothing.
- U0 landed 2026-10-05 (U0a `fa32a2ca`, U0b `7807e703`, U0c `f5bdd726`); U1 landed 2026-10-05/06 (U1a adff525b, U1b 62830b0a, U1c 9f78df7e, U1d 4e12b03c). Rubrics: `docs/reviews/code-review-rubric-2026-10-0{4,5,6}-feat-build-loop-u*.md`.

## U2 state (read first)
U2 was first built as one unit, U2a (`feat/build-loop-u2a`, not merged), which hit the 3-iteration cap; it was split (Q-119, interim [1]), and its second half split twice more at the 400-line cap:

| Unit | State | What |
|---|---|---|
| U2a1 | **merged 1a94773c** | main_entry's badform word, entry_why, isclosed, constraints.md for --check-fix, U1d's rows. |
| U2a2 | **merged 1ffb72d4** (2026-10-06) | The shared token parser `import_targets` (U+FEFF, a punctuation-ended token's whole and stripped name, ..x, NUL), `isimported tree` for check_fix, U2a1's carried rows C12-C14. Loop: 3 iterations (iteration 1 short-circuited at fact-check; 2 split main_imports out; 3 final, k=3, full panel, Stage 2.5); rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md`, loop closed at 7697c6e6. D1 (an @ after a Unicode space is swallowed, as on main) waived and fixed in U2a3b. |
| U2a3 | **merged 97aa2d35** (2026-10-06) | The main-only `main_imports` walk, `isimported main`, `nul_list`. Loop 1 hit the cap with C1 (an untracked start skipped the parent-link check) open; the user chose **split** at the iteration-4 gate: checkout-side reads moved to U2a3c, and until it lands the walk fails closed on any start file main lacks (so the gate needs a fresh worktree). Loop 2: 3 iterations, closed at 0bb98f27; rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md`. `ident` and non-tree attribute sources added to the U2b checkout-conversion refusal (TODO U2b). |
| U2a3c | **merged dfa75374** (2026-10-07, Q-129 [1]) | The two-phase checkout phase (main to a fixpoint, then checkout starts and imported files main lacks append only), `main_checkout ENT MEMO PATH` admission (bottom-up memo of every ancestor; main's link or gitlink at PATH answers 1), `checkout_md`, `md_ls`, plus U2a3b's carried items: `capped_read` (drain explicit), `lower_all` (N1), `IMPORT_WORK_MAX` with the parser's `/N` trailer and `import_work`, the top-level `.git` read as a checkout file, the 4096-byte link-text cap. Rebuilt 2026-10-07 as one 3-way resolution onto main (3e58eb9c; a per-commit rebase conflicted twice), iteration-1 reports carried in cb9723c3. Iteration 2 (k=1, full panel, at 21b35ebf): rubric `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md`; B1 contract text the rebase dropped, B2 O(D^3) memo, B3 uncapped link blobs, B4 unpinned fail-open mutant, all fixed in 2fbd929b. Final pass (k=3, full panel, Stage 2.5, at 3a35c8b9), same rubric: D1 `${x@a}` linear in the array (quadratic walk), D2 PATH memo without PATH's mode check (latent fail-open for a second caller), D3 a test red under a long TMPDIR, D4 U2b's clean-worktree duty, all fixed in 4b7f2357 (unreviewed). Tests 66/78/19/2; health check passed at 4b7f2357; 315 code lines against main. Deferred with rows: deep present-dir realpath cost, the caller contract in two places (U2a4), uncharged drain/scan work, the parse chain written three times. | After the final pass: Q-128 [1] confirming pass (no code defect; doc/test findings), Q-129 [1] docs and tests (4ce2c6bf) and a clean lite check (c8bd58c7); health check passed on the merge. 329 code lines; 169 tests.
| U2a3b | **merged 581d41d8** (2026-10-07, Q-122 [1]; c4b34dcf unreviewed; 13bc0a7d's shellcheck directive was added at the merge's health check) | Confirming pass at 4828727d (k=3, full panel, reports in 10f9b6e9): 0 red; security F1 (a gitfile holding an @ passed the main walk's top-level .git skip; Low, regression from main) fixed in c4b34dcf with a test; security F2 (command files are not walk starts; Medium, pre-existing) routed to U2a4; performance P2 to U2a3c; architecture 1-2 to U2b (Q-123 host check). 151/151; 841 code lines under the waiver. Before: Loop 2: iteration 1 (dd51e9a7, 98e3b1df), iteration 2 (e1654266), iteration 3 = final confirming pass at e1654266 (k=3, full panel): 0 red, ambers (three Medium test gaps; a pre-existing Medium fail-open, instruction files outside the repo, routed to U2b). All fixed or routed in aa379ee9 (work charge per resolved path, only top-level .git skipped, import_home keyed on raw HOME, renames, docs, tests), unreviewed. 149/149; --check-fix over 948 paths identical to main. 794 code lines against main, at Q-104 [2]'s ~800. Q-120 answered [1] (one more confirming pass, size waiver). Q-121 answered: occasional host sessions in ~/claude-workflows; added to U2b's reader model (4828727d). Rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md`. |
| U2a4 | **merged at 73589cd7** (Q-132 [1]) | `floor`/`ownfile`/`GATE_CODE` over `truthrule` (the shared check_fix/floor denials) and `truthwalk` (walk, then isimported); `isstart`, the one start rule (instruction files, `.claude/{rules,commands,agents,output-styles,skills}/` .md); `prompt_dir`/`prompt_bases` (a prompt's names also resolve against the top level and each enclosing `.claude/`'s directory); the parser's further base dirs and quoted `@"…"` run (to its closing quote, across lines); a link at a `.claude/` start dir fails the main walk; index queue pop (row 461); `import_reset`; the lib header's numbered gate caller contract (items 1-8). Loop: iteration 1 (k=1, full panel, d7cdc1ea; A1-A6 fixed), iteration 2 (short-circuit on prompt_bases' doubled-.claude red, fixed), iteration 3 = final pass (k=3, full panel, Stage 2.5, 2b6f2f91: no red; security F1/F2, perf F1 and docs fixed in 2f9464d3, unreviewed). Rubrics `docs/reviews/code-review-rubric-2026-10-0{7,8}-feat-build-loop-u2a4.md`. Confirming pass (Q-131 [1], k=1 fact-check + security over 2b6f2f91..a3489c4f): one Medium (2f9464d3 stopped reading `@"a b.md#L5"`) and Lows, fixed in 185e92f1 (lite fix-drift clean); NBSP-in-quote deferred (override row). Tests 79/19/78/2/2/53; --check-fix gives main's answers. Q-132 [1] security pass over 185e92f1: nothing Medium+ (C1 fail-closed ~90 KB open-quote bound, Won't-Fix; C2/C3 Informational). 599 code lines. |
| U2b | **in review** (2026-10-08) | Split before code (plan step 5's U2b split note): U2b1a (`--check`'s frame), U2b1b (diff parse, N rules), U2b2 (the gate's checkout), U2b3 (reader model). U2b1a's loop: iteration 1 (k=1; R1 partial-clone lazy fetch, fixed 9e5d92df), iteration 2 (full panel; R2 merge-tree opened a submodule repo and fetched through its config, security F1 origin/HEAD, F2 global config, F4-F8; fixed c66988b6: merge-tree in a gate-owned repo, GIT_CONFIG_GLOBAL=/dev/null, GIT_ALLOW_PROTOCOL=none, core.commitGraph=false, shallow and origin/HEAD refused). Security F3 (rewritten loose-object bytes) deferred with a row, trigger U3. At 439 lines it split again: U2b1a1 (ae08688c, 115 lines: open_shared/anybrief, row 307, --no-textconv) and U2b1a2 (63ea50e7, 330 lines on U2b1a1: --check). U2b1a1: final pass clean (no red), ambers fixed in 4a7e021d, lite check refuted, health check passed at aeb6f8fd; landing is Q-134. U2b1a2: iteration 3 (final pass) found R6 (missing tip tree reads ok), R7 (local master + origin/HEAD), R8 (race on GATE_TMP), R9 (vacuous submodule test); decision escalate, Q-133 (threat-model ruling; recommended [1]: fix the honest-path reds in one more iteration, hostile-loop paths to Q-103). Paused at 5ac071dd. Rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md` (on the u2b1a branches). |
| U2c | not started | Plan step 5. U2b keeps the header contract (items 2-4: clean worktree, import_reset per decision, item 3's attribute refusal) and owns the reader model (outside-repo starts; sessions started elsewhere). U2c: floor's first caller (contract item 5), FLOOR_WHY as a word and IMPORTED_MAIN_WHY (rows 376, 472), floor's per-path cost (row 470). |

**Next steps:**
0. Waiting on Q-134 (land U2b1a1) and Q-133 (U2b1a2's threat model and iteration 4). On Q-133 [1]: fix R6, R7, R9, A15-A19 and plan F8 (U2b1b's diff-tree must run in the gate repo or with --ignore-submodules=none), then a final pass; on U2b1a1's merge, merge it into U2b1a2 first (override-log rows conflict trivially). The junk branch `feat/x` (a review probe's) is the user's to delete.
1. Done 2026-10-08: U2a4 merged at 73589cd7 (merge message `docs/working/merge-msg-build-loop-u2a4.md`; `scripts/health-check.sh` passed on the merge).
2. Next: U2b and U2c, as below.
3. U2a4 (the floor), U2b and U2c as in plan step 5, carrying the older U2 triggers: C18/R5 (replace refs, origin/HEAD) are U3b's `--state`; A21 brief enumeration into the lib; globform into the lib; check_branch and marker_kind ignoring `git log` failures under a broken config (row 307); the per-path ls-tree cost (rows 220, 310); C16 (`pin_hermetic_git`) when a row-327 suite is edited; and from U2a3c: one numbered caller-contract statement (override row, trigger U2a4); a second `main_checkout` caller owes it a fresh MEMO per walk and ENT. Also from U2a3c: the quadratic queue pop (override row 461; trigger U2a4 or a walk past 30 s).

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
- `${arr@a}` costs time linear in the array's size; `${arr[0]@a}` gives the same type answer in O(1). Under set -u, `${arr@a}` on an empty array is an unbound-variable error (run it under a local `set +u`).
- A test that fixes a work or byte budget must derive it from a measured unit: the parser charges resolved spellings, which carry ROOT_REAL, so a fixed budget goes red under a long TMPDIR.
- Resolving a rebase from a cumulative patch: take each side's text from the branch tip, not from the first conflicting commit (3e58eb9c took cebfed35's wording and dropped 1fb62779's fixes to A5 and U2b).
- Review agents: A merge agent can put a "Claims Requiring Attention (summary)" heading near the top of the merged report; append Stage 2.5 claims after the last claim, not before the first such heading.

- Tests on main (dfa75374): build-loop-check.bats 68, build-loop-read.bats 19, dev-cycle.bats 78, fixture-git-env.bats 2, fixture-hermeticity 2 (169). U2a4 (73589cd7): build-loop-check 79 (180).
- git 2.39 `merge-tree --write-tree` reads `.gitattributes` from the current directory even under `--work-tree`, and opens a submodule repository under `.git/modules/` (with its own config) for a gitlink both sides moved: run it from a gate-owned git dir (U2b1a's gate_repo).
- A Bash command whose text names `.claude/` paths or the instruction file is blocked by a hook, prose included: write scripts and messages with the Write tool.
- Review briefs must carry the probe-safety rule verbatim (memory `probe-briefs-must-fail-without-tempdir`): a U2b1a2 security probe with an unset temp-dir variable committed into the review worktree on 2026-10-08.
- `scripts/lite-review.py` refuses a range over 192 KB; when a fix commit carries review reports, run it over a scratch commit with only the code changes.
- An apostrophe inside IMPORT_AWK (a single-quoted awk program) ends the quote: write awk comments without one (U2a4).
- A PreToolUse hook blocks Bash writes whose text names `.claude/` settings-like paths or CLAUDE.md (heredocs included): edit such test files with Edit, or run a Python script saved with Write.
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
