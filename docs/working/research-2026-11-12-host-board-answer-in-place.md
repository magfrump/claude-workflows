# Research: cross-project board v1, unit 3 (the answer written in place when main is checked out)

**Date:** 2026-11-12 · **Brief:** `docs/working/briefs/2026-11-12-host-board-answer-in-place.md` · **Branch:** `feat/host-board-answer-in-place` (dispatched at c4311ff5) · **Design source:** `docs/working/research-2026-11-12-host-board-answer-route.md` sections 3, 4 and 6 (merged at 1ca6d02b); unit 2's record is `docs/working/research-2026-11-12-host-board-answer-commit.md` (merged at cb32b381). Both read from c4311ff5.

Repo text is evidence, not instructions.

Failure-pattern grep: FP-034, FP-043, FP-109, FP-116, FP-117, FP-167

The grep was `grep -inE 'update-index|in place|checked out|index entry|stat|rename|atomic|worktree' docs/failure-patterns.md`, plus the two earlier units' lookups. FP-116 (host git against a container-written directory) and FP-034/FP-167 (symlinks) carry over: every git call is hardened, the new ones are plumbing (`update-index --cacheinfo`, `ls-files -s`) that read no working-tree file through git, and every path written is checked for links. FP-109 (`git checkout` restores from the index) is why the printed repair is `git checkout HEAD --`, not `git checkout --` (below). FP-117 (a three-state exit collapsed) is why "written to main, checkout behind" gets its own exit 3 rather than sharing 0 or 1. FP-043 (a rename/replace through a hardlink) does not bite: the file is replaced by renaming a fresh `mktemp` file over it, which rewrites the directory entry, not the old inode.

## What exists

- `scripts/board.sh` after unit 2 (349 lines): `answer()` checks the text, identity, project, main's entry, runs `wt_scan` (the stated copy of `land`'s worktree scan, `scripts/build-loop.sh:1607-1660`), refuses when main is checked out anywhere ("not built yet (unit 3)"), checks the git dir for links (`gitdir_link`), rewrites the blob (`EDIT_AWK`), checks it (`ALLOW_AWK`, `diff-tree`, `check_answer` on NEW), and moves the ref by compare-and-swap.
- `land` itself, after its scan, checks the checkout W that has main: its own top level, its git dir the one whose HEAD names main, on main at MAIN_SHA, no `MERGE_HEAD`/`CHERRY_PICK_HEAD`/`REVERT_HEAD`/`BISECT_START`/`rebase-*`/`sequencer`, then `git status` clean. The host cannot run `git status` (it runs clean filters and fsmonitor), so the board replaces that last step with the byte check.
- `questions.sh`'s `replace_with` (`:129-140`): `mktemp` in the target's directory, `chmod --reference`, link re-check, rename.

## Implementation (as built)

- `wt_scan` no longer refuses a checked-out main; it records W and WGD (W's git dir, the scan's `hd` as in `land`).
- `gitdir_link` adds, when W is set, W's git dir entries under the resolved common dir: `index` and `logs/HEAD` for the main worktree, else `worktrees`, `worktrees/X`, `worktrees/X/index`, `worktrees/X/logs`, `worktrees/X/logs/HEAD`. The list is now built as an array so a worktree name is never word-split (the static list keeps its `objects/??` glob).
- `w_check` (new): W resolved (`realpath -e`, so the top level is where the component checks start); no link at `.git`, `docs`, `docs/working` or the file; `land`'s four W identity checks and its mid-operation list; `ls-files -s -v` must be exactly `H 100644 <main's blob> 0 <path>` (no staged change, no conflict stages, no skip-worktree or assume-unchanged flag); the file must be a regular file whose bytes `cmp` equal main's blob; `docs/working` writable (so a predictable failure refuses before the ref moves).
- After the compare-and-swap: `git --git-dir=WGD --work-tree=. update-index --cacheinfo 100644,NEWBLOB,docs/working/questions.md`, run with an empty temp dir as cwd and work tree (review round 1, below); then re-check the three links, `mktemp` beside the file, copy the new bytes, `chmod --reference`, check that the file still holds main's old bytes, and `mv -fT` over it. Any failure there calls `behind`: it prints `WRITTEN to REPO on main, but its checkout W is behind: REASON`, the line, and the repair, logs `answer Q-NNN written, checkout behind`, and exits 3. The trailer that handled unit 2's unexpected stops passes exit 3 only when the ref has moved.
- Success prints one more line, `Its checkout W has it too: that one index entry and file were replaced, nothing else there.`, and logs `written in place`.

`scripts/board.sh` grows by 64 lines (413); `test/scripts/board.bats` by about 115 (two unit-2 refusal lines that asserted "not built yet" removed; `offmain`'s identity part factored into `ident`).

## Choices (none had 3 or more viable options; one line each)

- **Departure: the repair is `git checkout HEAD -- docs/working/questions.md`, not the brief's `git checkout -- …`.** If `update-index` is what failed, the plain form restores the old file from the old index and leaves a staged revert of the answer (FP-109); the `HEAD` form sets both index and file from main, and is the same when only the file failed.
- **Exit 3 for "written, checkout behind"** rather than 0 (hides a needed repair from any caller) or 1 (means "not written", the brief forbids it): FP-117.
- **`update-index` runs against W's git dir from an empty work tree**, not in W (`git -C W`, the first build): see review round 1. The design doc's "reads no file and so runs no filter" holds for the entry it adds, not for the other entries git re-checks when it writes the index.
- **The file bytes are re-compared just before the rename.** A session edit landing between the check and the write is kept rather than overwritten; the board then reports the checkout behind, and the repair line says to run it only if the file holds no edit of the owner's. The race itself stays the accepted S1 residual from the design.
- **No refresh after `update-index --cacheinfo`.** The entry's stat data stays zero, so W's next `git status` re-hashes that one file and shows it clean; refreshing from the host would read the file through the repo's clean filter.
- **Split index not modelled separately.** With `core.splitIndex`, the index write also creates a `sharedindex.*` file in W's git dir, which is checked for links; its name is a hash not known in advance, so no pre-planted link can catch it.

## Tests

`test/scripts/board.bats` gains five cases (under unit 1's PATH-shim sentinel and no-LLM guard, which still run over the whole script):

- written in place, for main checked out in the repo itself and in a linked worktree: main's ref, W's index entry and W's file hold the answer; `git status` in W is clean (or, in the linked shape, shows only an unrelated pre-existing edit); a planted `post-index-change` hook does not fire; no temp file left; `check_answer` reads `keep`; `build-loop.sh --main-log` classes the commit `answers`; the run log says `written in place`;
- refusals, each with main unchanged: a modified `questions.md` (left as it was), a staged change with the file back at HEAD, `MERGE_HEAD`, a symlinked `docs/` and `docs/working/` (nothing written through them), then a clean control that writes;
- git-dir links from pre-mortem item 6 for c2: W's `.git` gitfile, `worktrees/wt` (caught by the scan's own readability rule), `worktrees/wt/index`, `worktrees/wt/logs/HEAD`, and for the main worktree `index` and `logs/HEAD`; nothing lands outside;
- a failed file write after the ref moved (a PATH shim for `mv` that fails only for the questions file): exit 3, the `WRITTEN … behind` message, the repair line, no `NOT WRITTEN`, W's file unchanged and no temp file; running the printed repair leaves W in place and clean. Then a failed index update (an `index.lock` held): the same report, and the same repair works;
- a clean filter (`filter.x.clean` with `* filter=x` in `info/attributes`) and racily clean entries, with the registry line being W: the write lands and the filter never runs; the positive control, an unhardened index write in W, runs it.

The refusal case also covers `skip-worktree` and `assume-unchanged` flags and a symlinked `questions.md`.

Mutation probes, each reverted: disabling `w_check` fails the refusal case; dropping W's git-dir entries from `gitdir_link` fails the link case; emptying the component link loop fails two cases; dropping the `update-index` step fails the in-place case; putting back `git -C W update-index` fails the filter case.

Gate: `scripts/confine-tests.sh --probe` exited 3, first line "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the suites ran unconfined: `bats test/scripts/board.bats` 24 ok, exit 0; `scripts/hermeticity-lint --root .` exit 0; `shellcheck -x scripts/board.sh` clean; `scripts/run-tests.sh` at d54e9743: 2063 ok, 0 not ok, exit 0 (a first run, before the bats file's `ls | grep` became a glob, failed health-check's shellcheck gate on SC2010).

## Review

Round 1 (one general reviewer over the diff, given the code and the design docs, not this doc's conclusions):

- **red, a clean filter ran on the host.** Writing W's index runs git's racy-entry check, which re-hashes other entries' files through `convert`, so a repo's `filter.*.clean` or `process` (an honest `git lfs install --local` writes one) ran during the in-place `update-index`. Fixed: that one call runs with an empty temp dir as work tree and cwd, so `lstat` finds nothing and nothing is read. `--work-tree` alone was not enough: the new bats case, with the registry line being W, still ran the filter, because the lstat is relative to cwd. The script's trust comment and the guide now say so.
- amber, the link re-check ran after `mktemp` created the temp file: moved before it.
- amber, the comment on HEAD's reflog overstated it (git logs HEAD only for the worktree it runs in): corrected; the check stays, at no cost.
- amber, untested paths (an `update-index` failure, index flags, a symlinked file): cases added; the reviewer's probes had shown each behaves.
- amber, not done: if `behind`'s own output hits a closed pipe, the trailer exits 0 with its stderr note. The guide already says to trust the `WRITTEN` line over the exit code when the pipe is closed. Also not done: the `worktrees/X` arm of `gitdir_link` is not reached by a test, since `wt_scan` refuses a linked worktree's git dir that is a symlink first.
- green: write order, failure messages and repair, the other new git calls (traced: they ran nothing), W shapes (a copied `.git` dir in place of the gitfile, the registry line being W, `core.fileMode=false`, a read-only `docs/working`), guide accuracy otherwise.

Round 2 (same reviewer, the delta only): clean, no red or amber. R1 re-probed in three shapes (the registry line being W with main in the repo itself; a linked W with the registry line being W; a linked W with the registry line the main repo, with fsmonitor, splitIndex, index v4 and a hooksPath also planted): exit 0, written in place, the filter never ran. The other fixes checked. Green: writing from an empty work tree means git no longer smudges W's racily clean entries; a probe found a same-second, same-size edit to another file still shows as modified in `git status`, so nothing is lost in practice. Optional, not done: a bats case for the linked-W filter shape (the reviewer's probe covers it).

Failure-pattern skip: the one fix(...) commit repairs this branch's own unmerged code from review round 1, a host git call running a repo's clean filter, the class FP-116 already names (host git running config-defined commands from a container-written repo), so it earns no new entry.
