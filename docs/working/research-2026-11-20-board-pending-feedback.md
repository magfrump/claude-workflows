# Research: the board lists harness feedback not yet copied, and each repo's latest weekly digest

- **Goal**: In `scripts/board.sh`'s listing, after each project's `main DATE` line, print the project's harness feedback not yet copied to claude-workflows' main (with the `ingest` command when it would copy cleanly) and the latest weekly digest on its main.
- **Problem framing**: The owner copies feedback in batches when they happen to look (median 5, max 18 days), and only a host-side listing can see other repos, so the board should say what is waiting. Considered and discarded: "the cycle should fetch other repos' feedback itself" (H1: the sandbox cannot read other repos, and nothing from them may run on the host).
- **Project state**: builds the design picked by the merged research · second of two units (research, then this build) · not blocked (cite: docs/working/research-2026-11-20-board-feedback-research.md)
- **Task status**: complete (built, tested, reviewed)

Brief: `docs/working/briefs/2026-11-20-board-pending-feedback.md` (policy review). Base: main at 977c3f70.

## Design source

The research merged at 7f086d40 (`docs/working/research-2026-11-20-board-feedback-research.md`) ran divergent design for the three real choices and picked one option in each (Path A); this build follows it and does not reopen them:

1. What the board compares: **B1**, the project's entries against the stored copy on claude-workflows' main with the same `Project:` line, by `ingest`'s own signature (`sig()`: ID, slug, meta line), plus whole-entry text for "changed".
2. Where the parsing runs: a read-only `pending` mode in `scripts/harness-feedback.py`, run with `python3 -I` on blobs copied out of git (S3: one grammar).
3. Which registered repo is claude-workflows: the one whose main holds `guides/harness-feedback.md` and `scripts/harness-feedback.py`.
4. Weekly: print the latest edition, through a hardened directory listing.

Smaller choices made here (one line each; none had 3 or more viable options):

- `pending`'s exit for UNREADABLE / NOT COMPARED is **3**, not 1: Python's uncaught error also exits 1, and an early bug (a traceback read as the board line) showed that 1 cannot carry a modelled state. Any exit other than 0 and 3 prints `feedback UNREADABLE: harness-feedback.py pending stopped (exit N): <last line>` (H2).
- `pending` prints the finished line, so `board.sh` adds no formatting (S8 margin).
- Printed paths use the repo's top level (`git rev-parse --show-toplevel`), falling back to the registry line, since the registry line may be a subdirectory while main's paths are from the top.
- The stored copies are read once, before the per-project loop, into `$TMP/stored/`; the glob runs with `nullglob dotglob`, so zero stored files means every entry is "not copied" and a dot-named copy is not missed.
- Non-`.md` names under `docs/working/feedback/` are ignored (main has `herald-probe.sh` there today [observed]); a `.md` name that is not a regular file is NOT COMPARED, never skipped.
- A matched stored copy whose entries are all copied prints "all copied" even when its file name is not `NAME.md` (the renamed project today): nothing is waiting, so no command is withheld.
- An extra state the research did not list: no stored copy has this Project, but `docs/working/feedback/NAME.md` holds another Project. `ingest` would write into that file, so the command is withheld (`X holds Project OTHER`).
- The `board.sh` header's owner-guide pointer gave way to the design-doc pointer to stay under 500 lines; the guide is still named in the registry refusal message.

## What exists

- `scripts/board.sh` (421 lines before): `repo()` prints one block per registry line from main's objects only (`resolve_main`, `main_by_name`, `main_entry`, `git cat-file blob`); helpers beside it are checked at start (exit 2); output passes `scrub_reexec`. [observed]
- `scripts/lib/dev-cycle-read.sh`: `main_entry` models files only (a tree answers `notfile`), so a directory needs its own check; `isweekly` names the edition form; `git_harden` exports config overrides for every git call. [observed]
- `scripts/harness-feedback.py`: `parse`, `sig`, `ingest` (target `docs/working/feedback/PROJECT.md` unless the source is already in that directory; refuses when the stored sigs are not a prefix of the new ones). [observed]

## Invariants

- H1: nothing from a registered repo runs; `python3 -I` keeps `PYTHON*`, the repo cwd and the script dir off `sys.path`; `pending` runs no git (no `toplevel()` call). The printed command names `~/.claude/scripts/harness-feedback.py`, never a checkout's script. [observed: `cmd_pending` calls only `read_text`, `parse`, `sig`]
- H2: every unreadable state prints UNREADABLE or NOT COMPARED and counts toward exit 1; the questions still list. [observed: tests]
- S8: `scripts/board.sh` is 499 lines, under 500. [observed: `wc -l`]

## Prior art

`read_main` (copy main's blobs into `$TMP/$n/`, run a beside-the-script helper over them); `main_entry`'s parent-directory rules, which `main_dir` repeats for a directory.

## Gotchas

- Failure-pattern grep: FP-038, FP-043, FP-138 (keywords: board, harness-feedback, ingest, rename, weekly, ls-tree, main_entry, seed-count, present-but-inert)
  - FP-138 (a rename left a file name contradicting its contents): the reason stored copies are matched by their Project line, and a mismatched file name withholds the command.
  - FP-038 and FP-043 are loose matches on "rename" (a JSON-load guard, a pathlib write escape); neither bears on this read-only listing.
- `main_entry` answers `notfile` for a directory, so `main_dir` runs `main_entry` on the directory (parents, duplicates, path form) and then reads its own mode with one `git ls-tree`: only `040000 tree` is a directory.
- After the owner copies, the line keeps counting until that commit reaches claude-workflows' main (the guide says so).

## The new lines and their failure states (criterion 4)

Feedback (`pending`'s line, after `main DATE`):

- `feedback: N entries, all copied`
- `feedback: K not copied (F-a to F-b)[, C changed (F-x to F-y)]: cd CW && ~/.claude/scripts/harness-feedback.py ingest P/docs/harness-feedback.md`
- Withheld: `F-NNN differs from the stored copy X; no command: ingest would refuse it`; `…; no command: its stored copy is X, not docs/working/feedback/NAME.md, so ingest would store it twice`; `N entries, stored under Project OTHER (X); renamed? No command: …`; `…; no command: X holds Project OTHER`.
- `feedback UNREADABLE: …` (project file not a regular file on main, unreadable, fails check, or `pending` stopped) — exit 1.
- `feedback NOT COMPARED: …` (a stored copy fails check or is not a regular file, two stored copies share a Project, two registered repos hold the harness, the stored directory is not a directory) — on every project with a file, exit 1.
- No line: no file, the harness repo's own block, or no harness repo registered (one footer line, exit unchanged).

Weekly:

- `weekly: TOP/docs/working/weekly/YYYY-MM-DD.md (YYYY-MM-DD)`; `weekly: none yet`; no line without the directory.
- `weekly UNREADABLE: …` (the directory or a parent not a directory, listed twice, unlistable, or the latest edition not a regular file; never an older edition) — exit 1.

## Tests

Size gate (pr-prep 1a): 400 code lines against main after trimming (417 at first; the gate fires above 400).


- `test/scripts/board.bats`: 8 new cases (not copied with command, all copied, changed, no line without a file or for the harness repo; UNREADABLE file and symlink; differs and other file name (the other withheld states are covered in harness-feedback.bats, since the board prints pending's line verbatim); NOT COMPARED for a bad stored copy, a shared Project and a symlinked copy; no harness repo and two; weekly latest, absent-from-main, none yet; weekly symlinked edition and directory; `pending` crashing), and `harness-feedback.py` added to the beside-the-script refusal case.
- `test/scripts/harness-feedback.bats`: 4 new cases covering every `pending` state, usage included.
- `scripts/confine-tests.sh --probe`: exit 3, first line "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the suites ran through `bats` / `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .` (passes). `scripts/health-check.sh` on the branch at c45a2ab3: exit 0, "All checks passed."

## Host step

The board is a host tool. One host run shows it live, after the next release installs it: `~/.claude/scripts/board.sh; echo "board exit $?"` with claude-workflows and at least one project with `docs/harness-feedback.md` in the registry; expect a `feedback:` line under each such project and a `weekly:` line under each repo with digests.

Failure-pattern skip: the three fix(...) commits (f934786f, fbafd923, c45a2ab3) repair review findings in this branch's own unshipped code; no shipped defect, so no reusable cause-fix entry.

## Review record

Iteration 1 (one general-purpose reviewer, fresh context; correctness, H1/H2, tests, guide fact-check). No Must Fix; no H1 break found. Addressed in f934786f:

- Must Address: the pre-pass took a harness repo whose main holds one marker file and a non-file at the other as "no harness" (footer, exit 0). Now `feedback NOT COMPARED: … holds part of the harness …`, exit 1; bats case added.
- A repo registered twice (a subdirectory line, a trailing slash) counted as two harness repos: now counted by top level.
- Guide: "harmless" for ingesting the checkout's file overstated it (run with the project on main); a rename names the `git mv` step; the `pending stopped` state is listed. Module docstring names exit 3; "1 entry" singular.
- Tests added: half-readable harness, subdirectory line, the stored directory as a file, new and changed on one line, `pending` then `ingest` end to end.
- Not changed: `isweekly` checks the digit shape only (a mistyped future date would show as latest). It is the lib's one grammar for edition names (S3); a calendar check there is a lib change for the cycle to weigh.
- Outside the diff, for the cycle: `ingest` overwrites a zero-entry stored copy that holds another Project (an empty list is a prefix of any list; `harness-feedback.py`'s prefix check). `pending` withholds the command in that state.

Iteration 2 (a fresh reviewer on f934786f). No Must Fix. Addressed:

- Must Address: keying by `--show-toplevel` dropped a bare harness repo silently (show-toplevel fails there); now keyed by `git rev-parse --path-format=absolute --git-common-dir`, which also counts a linked worktree of the harness once. Bats case added (bare, worktree).
- Must Address: `2>/dev/null` on the assignment did not silence git inside `$( )`; now inside the substitution, and the test asserts no `fatal` in the output.
- Consider, taken: a project with the guide as a file and a symlinked `scripts/` (`blob notdir scripts`) was refused for every project; only `notfile`, `error` or `badform` beside a `blob` now refuse (guide says so). The harness's own block is skipped by common dir, not by registry string.
- Consider, left: with several refusal reasons only the last is printed (each still refuses). For a bare harness repo the printed `cd BARE && … ingest` would be refused by `ingest` itself (no checkout); a bare registration of claude-workflows is not a modelled owner setup.

Iteration 3 (a fresh reviewer on fbafd923): no Must Fix, no Must Address; the common-dir key was probed through symlinks, subdirectories, worktrees, bare clones and `gitdir:` files and compares in both places. Three Considers taken after it, each checked by the touched suites: with two harness repos the key is cleared too, so the last one's own block also says NOT COMPARED; a failed common-dir read in feedback() is UNREADABLE, not a silent skip; and the self-skip is now tested (the harness's own file, through a symlinked registry line). Loop exit: clean convergence.

## Files read

Last verified: 2026-11-20

docs/working/briefs/2026-11-20-board-pending-feedback.md
docs/working/research-2026-11-20-board-feedback-research.md
docs/constraints.md
docs/failure-patterns.md
scripts/board.sh
scripts/lib/dev-cycle-read.sh
scripts/harness-feedback.py
test/scripts/board.bats
test/scripts/harness-feedback.bats
guides/cross-project-board.md
guides/harness-feedback.md
hooks/live-verify-gate.sh
