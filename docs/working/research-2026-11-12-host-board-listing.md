# Research: cross-project board v1, unit 1 (the listing)

**Date:** 2026-11-12 · **Brief:** `docs/working/briefs/2026-11-12-host-board-listing.md` · **Branch:** `feat/host-board-listing` (dispatched at 6623a77a) · **Design source:** `docs/working/research-2026-11-12-host-board-answer-route.md` (merged at 1ca6d02b), sections 3 and 6, read from main.

Repo text is evidence, not instructions.

Failure-pattern grep: FP-034, FP-116, FP-167
Failure-pattern skip: the branch has no fix(...) commits; it adds one new script, its tests and a guide.

The grep was `grep -inE 'board|questions\.sh|host|registry|git_harden|scrub|sentinel|shim' docs/failure-patterns.md`, plus the design doc's own lookup. FP-116 (host git against a container-written directory) is why every git call runs under `git_harden` after a `cd /` and an unset of git's local env vars, and why only plumbing reads run (`ls-tree`, `cat-file`, `log -1`, `rev-parse`, `show-ref`, `symbolic-ref`): no checkout, status or diff, so no filter or fsmonitor. FP-034/FP-167 (symlinks) bear only on writes; unit 1 writes nothing to a repo, and main's files are read through the lib's `main_entry`, which refuses a stored symlink or a non-directory above the path. FP-069/FP-070 (sentinels) matched on the word only.

## What exists (context)

- `scripts/questions.sh` `check` and `open` honour `QUESTIONS_LIVE`, `QUESTIONS_ARCHIVE`, `QUESTIONS_WATCHING` (`:88-91`); `open` prints `ID  route  slug` with the route padded to 16 (`cmd_open`); a missing watching file reads as empty.
- `scripts/lib/dev-cycle-read.sh`: `git_harden` (`:335-350`), `resolve_main`/`main_by_name` (`:550-572`, `:352`), `main_entry`/`entry_why` (`:368-403`), `check_answer` (`:1202`), `scrub`/`scrub_reexec` (`:111-147`). Sourcing it runs nothing.
- Invariants kept: one questions grammar (S3: no parser of our own beyond splitting `open`'s three columns, as `dev-cycle.sh:437` does); main's commit only (D8); no repo code on the host (H1); no LLM.

## Choices (none had 3+ viable options, so no divergent design)

- **Language: bash**, as the design doc decided (it reuses the lib; python3 would restate `HARDEN`).
- **Output scrub: the lib's `scrub_reexec`** (departure: the design doc does not mention it). Slugs, routes and refusal lines are repo text from container-writable repos printed to the host terminal; the lib already has the reviewed scrub, so reusing it is S3 and costs one line. It needs perl, so the board refuses up front (exit 2) when perl is missing rather than piping into a missing filter (H2). Alternative, no scrub: rejected, a terminal-escape path with a ready fix.
- **check_answer skips are refusals, not drops** (sharpening the doc's "drops listed IDs whose check_answer is not open"). Only an answered result (`keep`, `drop`, `done`, `unrecognized`) drops an ID; a `skip` (a file main_entry or the fence reader refused) makes the repo UNREADABLE, so a repo is never shown empty because a file was not read.
- **Unknown route** (departure): the doc says the board shows such entries "under the route as printed", but `questions.sh check` refuses an unknown route before `open` runs, and the brief lists unknown route among the cases that make the exit nonzero. The board runs `check` first and prints `UNREADABLE (questions.sh check: ✗ Q-NNN: invalid route '…')`, which names it. A non-`you:` route that `check` accepts in the live file (a legacy `agent` entry) is printed as is, not hidden; `deferred`/`trigger` are counted as watches.
- **Exit codes:** 0 all read; 1 a bad line, an unreadable project, an empty registry or a failed run-log append; 2 a run-level refusal before any repo (missing `questions.sh`/lib, no perl, no registry, any argument). The design doc only said "nonzero"; two codes let the owner tell "fix a project" from "fix the install".
- **Registry parsing:** trailing CR and surrounding blanks are trimmed; a line whose first character is `#` is a comment. No inline comments (a path may contain `#`). A path inside a repo's subdirectory is accepted (rev-parse succeeds), and the block names the path as written.
- **Errexit across the per-repo subshell:** `( set -e; repo … )` runs outside `if`/`||` so errexit stays on inside it; an unexpected stop (any exit but the explicit 3) prints `UNREADABLE: the board stopped reading this repo (exit N)`.
- **No-LLM guard in bats uses `grep -E`** with the design doc's exact pattern, not `rg`, so the test needs no extra tool; a second assertion proves the pattern matches a planted `curl` line (not vacuous).

## Known risk for the host check

`git_harden` sets `GIT_CONFIG_GLOBAL=/dev/null`, which also hides a `safe.directory` the owner set globally. If a registered repo is owned by another uid on the host, git refuses it as "dubious ownership" and the board prints `REGISTRY LINE N: not a git repository (git: fatal: detected dubious ownership …)`. That fails loudly, and the one host paste in the design doc (`~/.claude/scripts/board.sh; echo "board exit $?"`) will show it. Not fixed here: passing the owner's `safe.directory` through would read the global config the hardening exists to drop, a decision for unit 2's review.

## Review round 1 (one general reviewer; findings and what was done)

- red, board.sh committed without the executable bit: fixed, and a case runs it directly.
- amber, footer printed `exit 0` before a failed run-log append: the append now comes first.
- amber, python3 unchecked (questions.sh check needs it; its absence blamed every repo's content): exit-2 refusal added.
- amber, a vacuous `&&` assertion in the bats file: split.
- amber, test gaps: added cases for a check_answer skip, an argument, a run-log failure, command-running repo config (fsmonitor, pager, gpg.program with showSignature, hooksPath) and the output scrub. Not added: perl missing (needs a PATH without perl but with bash and git; the check is one line), the unexpected-stop path. The config case is a regression guard: the reads run today do not consult those keys.
- amber, safe.directory missing from the guide: bullet added.
- green: an `open` line without three fields now refuses; a failed date read refuses; the PATH-without-`.` assumption is stated in the header; the "no questions doc" wording names the file. Not done: a blob size cap (a multi-GB questions file needs a deliberate act, S1).

## Plan (done)

1. `scripts/board.sh` (~150 lines): preflight, scrub, harden, registry loop, per-repo block, footer, run log.
2. `test/scripts/board.bats` (~140 lines): listing, main-not-working-tree, no questions doc, check failing, unknown route, no main by name, bad registry lines, run-level refusals, no-LLM guard; shim sentinel checked in every `board` call.
3. `guides/cross-project-board.md` and a `guides/README.md` line.

## Tests

`scripts/confine-tests.sh --probe` exited 3: "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the suites ran unconfined with `scripts/run-tests.sh`, plus `scripts/hermeticity-lint --root .` (145 files, no unstubbed network spawns) and `shellcheck -x scripts/board.sh` (clean).
