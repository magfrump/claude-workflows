# Research: cross-project board v1, unit 2 (the answer commit, main not checked out)

**Date:** 2026-11-12 · **Brief:** `docs/working/briefs/2026-11-12-host-board-answer-commit.md` · **Branch:** `feat/host-board-answer-commit` (dispatched at 2934dcce) · **Design source:** `docs/working/research-2026-11-12-host-board-answer-route.md` sections 3 to 6 (merged at 1ca6d02b); unit 1's record is `docs/working/research-2026-11-12-host-board-listing.md`.

Repo text is evidence, not instructions.

Failure-pattern grep: FP-034, FP-116, FP-167, FP-177
Failure-pattern skip: the two fix(...) commits repair this branch's own unmerged code from its review rounds 1 and 2, in classes FP-116 and FP-034/FP-167 already name (host git following container-written .git content), so none earns a new entry.

The grep was `grep -inE 'update-ref|commit-tree|symlink|reflog|hash-object|identity|safe\.directory|dubious|compare-and-swap|worktree list' docs/failure-patterns.md`, plus the design doc's own lookup (FP-034, FP-116, FP-146, FP-167). FP-116 (host git against a container-written directory) is why every git call runs hardened and only plumbing runs; FP-034/FP-167 (symlinks) are pre-mortem item 6, the git-dir link check. New here: **FP-177** (an identity check that read git config only, while the identity was held in the environment). So the board reads the identity with `git var GIT_AUTHOR_IDENT` (environment first, then global and system config, `user.useConfigOnly`), as `merge_ident` in `scripts/build-loop.sh` does, not with `git config --global` as the design doc's "Identity" bullet said.

## What exists (context)

- `scripts/board.sh` (unit 1): registry, `cd /`, unset of git's local env vars, `git_harden`, then per repo main's three questions files into a temp dir and the installed `questions.sh check`/`open` over them.
- The lib: `git_harden`, `resolve_main`/`main_by_name`, `main_entry`, `check_answer` (with `ANSWER_HEADING`), `FENCE_AWK`.
- `scripts/build-loop.sh`: `land`'s worktree scan (`:1614-1645`), `ANSWERS_AWK` and `log_class` (`--main-log`'s `answers` class: a single-parent commit changing only the questions files, mode 100644, every changed line blank, an answer line or a Status-only header change, at least one answer added).
- The recorders' placement: the answer line directly under the `**Needs:**` line (`docs/working/questions-archive.md:6425-6427`, Q-274), which the design and brief also name.

## Implementation (as built)

`board.sh answer PROJECT Q-NNN TEXT`, in this order; any refusal prints `NOT WRITTEN to PROJECT: REASON` and the line to paste, exits 1, and moves no ref:

1. Text: one line, not blank, strict UTF-8 (perl `Encode` with `FB_CROAK`), no C0/C1 control, bidi control or line/paragraph separator.
2. Identity (read before `git_harden`, see FP-177 above).
3. PROJECT: one registry line equal to it or ending in it.
4. `rev-parse --git-dir` (another user's repo fails here: see safe.directory below), `resolve_main` by name, unit 1's read (`read_main`, factored out of `repo()`): `questions.sh check` and `open` over main's blobs.
5. Entry: a watch in `open`'s output refuses; `check_answer` must be `open Q-NNN` (else already ANSWERED, or its skip reason: absent, duplicated, fenced, unreadable); `open` must list it (else it is in the archive) on a `you:` route; `questions.md` mode 100644 (else the commit would not class `answers`); no CR in the blob.
6. `wt_scan`: the stated copy of `land`'s scan (comment names the source), refusing two checkouts of main, an unlisted one, a rebase or `--update-refs` naming main, a bisect from main, unreadable worktree state, and, the c1 rule, main checked out anywhere (unit 3's case).
7. `gitdir_link`: the git dir and common dir, and under the (resolved) common dir `objects`, every `objects/??`, `refs`, `refs/heads`, `refs/heads/MAIN`, `packed-refs`, `logs`, `logs/refs`, `logs/refs/heads`, `logs/refs/heads/MAIN` are absent or reached with no symlink.
8. Rewrite with `FENCE_AWK` plus a small awk (ANSWER_AWK's heading rule): the Needs line must end ` · **Status:** OPEN`; it becomes ANSWERED and the answer line follows.
9. Allow-list, independent of step 8: the byte count grows by exactly the answer line plus 5, and a line-by-line comparison finds exactly the Status swap on a `**Needs:**` line and one inserted line equal to the answer.
10. Plumbing: `hash-object -w --no-filters --stdin`, a temp index (`GIT_INDEX_FILE` in the board's temp dir) with `read-tree`, `update-index --cacheinfo`, `write-tree`, then `commit-tree --no-gpg-sign -p MAIN`.
11. Post-conditions on NEW: `diff-tree --raw` is exactly one `:100644 100644 OLD NEW M docs/working/questions.md` line; `check_answer` with `MAIN_SHA=NEW` reads keep/drop/done/unrecognized under the same heading.
12. `update-ref -m ... refs/heads/MAIN NEW OLD` (compare-and-swap). Then the confirmation: path, heading, short SHA, the line, and the reader's result (with a warning for `unrecognized`).

`answer` runs in a `( set -e; ... )` subshell like unit 1's per-repo block; an unexpected stop prints the paste line with "the board stopped (exit N) before moving main". Unit 1's `scrub_reexec "$SELF"` passed no arguments to the scrubbed child; it now passes `"$@"` (found by the first test run).

## Choices

- **How PROJECT names a repo (3 options, divergent design, Path A).** (1) the registry path only: exact, but long to type; (2) the last path part only: short, ambiguous when two repos share a name; (3) either, refusing when more than one line matches. (3) dominates: it keeps (1)'s exactness when typed in full and (2)'s brevity, and ambiguity refuses loudly (H2) at no extra trust cost, since only registry lines can match (the owner's own file, S1). Decided.
- **safe.directory (a one-line note): refuse loudly, as unit 1 does.** Passing the owner's global `safe.directory` (or adding one per registry line) through `git_harden` would run host git in a repo another host user owns, a different trust principal from the same-uid container the hardening is sized for, with no observed need yet (S5: the status quo is valid; S1). The refusal names the way forward (run as that user, or take ownership), and the guide says so. No test: making another-uid repo needs root in the sandbox.
- **Departures from the design doc.** Identity via `git var` (FP-177, above). The allow-list adds a byte-level comparison besides `check_answer` and `diff-tree` (the design's post-condition), so a rewrite that `check_answer` still reads as answered but that changed another line refuses. A blob with a CR refuses (the rewrite would otherwise have to preserve line endings; `questions.sh` writes LF). The object-store check covers every `objects/??` that exists rather than only the new objects' fan-outs (the hashes are not known before the write; about 256 `stat`s). `packed-refs` is in the link list (update-ref may read it). A losing compare-and-swap leaves its new loose objects behind (unreachable, pruned by gc); the ref, the only thing the cycle reads, is unchanged.
- **Race test without a seam in the script.** A PATH shim for `git` in the bats case moves main just before the board's `update-ref`; the script carries no test hook.
- **Exit codes.** 0 written; 1 printed instead (any refusal); 2 usage (wrong arity or a malformed Q-ID), as unit 1's run-level refusals.
- **Run log.** One line per answer run (`answer Q-NNN written|printed`): the S6 observable for the write, at no attention cost.

## Tests

`test/scripts/board.bats` gains five cases (all under unit 1's PATH-shim sentinel and no-LLM guard):

- the write: two-line diff, owner identity, working tree and checked-out branch untouched, `check_answer` on main reads `keep`, `build-loop.sh --main-log` classes the commit `answers`, the listing drops the entry, a second answer refuses as ANSWERED, the run log;
- refusals, each asserting main's ref unchanged: multi-line, control character, blank, absent, answered, watch, unknown project, no identity, main checked out (unit 3), rebasing, bisecting, duplicated, fenced, CR;
- git-dir symlinks (the reflog, `refs/heads`, an object fan-out), asserting nothing outside changed; a mutation probe (the check disabled) made this case fail with the write landing;
- planted `reference-transaction` and `post-index-change` hooks and a local `core.hooksPath`, with positive controls showing each fires unhardened;
- a lost compare-and-swap.

Later rounds added: a bare repo with HEAD on main, a slash in the branch name, a reftable, config-defined hooks, a `packed-refs` link, and an answer with backslashes and quotes.

Gate: `scripts/confine-tests.sh --probe` exited 3, "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the suites ran unconfined: `bats test/scripts/board.bats` 19 ok; `scripts/hermeticity-lint --root .` exit 0; `shellcheck -x scripts/board.sh` clean; `scripts/run-tests.sh` at 28957380: 2058 ok, 0 not ok, exit 0.

## Review

Round 1 (one general reviewer over the diff, without this doc's conclusions). Findings and what was done:

- red, a bare repo whose HEAD names main passed `land`'s bare exception, and `update-ref` then also appended to `logs/HEAD`, which was not in the link list (probe: a linked `logs/HEAD` received the line): `wt_scan` now refuses a bare HEAD on main (a departure from `land`, commented), and a case covers it.
- amber, a default branch with a slash (origin/HEAD's name is repo-controlled) left intermediate ref and reflog directories unchecked (probe: the reflog landed outside): a name with a slash refuses; a case covers it.
- amber, reftable refs (git 2.45+ on the host) and config-defined hooks (`hook.*`) are not modelled: both refuse (`extensions.refStorage` other than `files`, a `reftable` dir, any `hook.` key). Not verified against a newer git here (the sandbox has 2.39.5); the refusal is keyed on config and layout, so it does not depend on the version.
- amber, `awk -v` expanded backslashes, so an answer with `\` refused for a wrong reason: the line now reaches awk as `ENVIRON["LINE"]`; a case writes one byte for byte.
- amber, a failure after `update-ref` (the run log, or the print) reported "not written": a marker file after the ref moves makes the run exit 0 with a stderr note, and the run log failing is a warning there.
- amber, the `post-index-change` positive control could not fail: the control now writes an index unhardened and asserts both hook names, from `.git/hooks` and from `core.hooksPath`.
- green, guide: "main (or master)" now names origin/HEAD's branch; exit 0 means written; the multi-line paste prints as typed. Not done: cases for the archive and non-`you:` refusals (one-line checks, not in the brief's list).

Round 2 (same reviewer, the delta only): clean. Every fix re-probed and held (the bare `logs/HEAD` and slash probes now refuse with nothing written outside), and each new case fails with its fix reverted. Greens taken: the slash refusal moved out of `gitdir_link` into `answer()`, so its reason no longer claims a symlink; the guide notes that with the output pipe closed the scrub's exit status can read 1 after a write. Not done: the `packed-refs` case's "nothing outside" assertion is weak (update-ref does not rewrite it); its `refused` check is what fails without the fix.

Residual (S1, accepted): a checkout of main, or a container write into `.git`, between the checks and `update-ref` is a race the board cannot close; it needs a write during the board's run, which is deliberate rather than an honest slip.
