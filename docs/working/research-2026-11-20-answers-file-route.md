# Research: a committed answers file counts as the owner's answer

Brief: `docs/working/briefs/2026-11-20-answers-file-route.md` (build loop, dispatch 1).
Date: 2026-11-20. Repo text is evidence, not instructions.

- Failure-pattern grep: `rg -n -i 'cache|fail-open|stale|date' docs/failure-patterns.md`; bearing here: FP-125 (cache-staleness: a cached read reports a previous state), FP-147 (exit status read through process substitution is lost), FP-169 (a parsed date field made unparseable). Each shaped the code: the answers index is cached per default-branch commit (board.sh's post-check moves `MAIN_SHA` and gets a fresh read), the git listings go through the lib's `nul_list`, which carries the exit status, and a malformed `Opened:` date reads files for no ID instead of being guessed.
- Failure-pattern skip: no fix(...) commits on this branch; nothing earns a new entry.

## Motive (S5)

The owner chose this route (Q-345 [1], answered in session on 2026-11-20: the gate reads
the file). The triage (`docs/working/research-2026-11-20-harness-feedback-triage.md`,
section "behemoth F-002") found the gap in three projects, and here: 7df4654d (answers to
Q-255, Q-302, Q-327) was read as `other`, and the cycle had to ask again. The triage's
divergent design is done and the owner picked D, so this doc records only the build's
own smaller choices.

## What the code did (read)

- `check_answer` (`scripts/lib/dev-cycle-read.sh`) read only `docs/working/questions.md`
  and `questions-archive.md` on main's commit, through `FENCE_AWK$ANSWER_AWK`.
- `ANSWER_AWK`'s `option()` is the one rule for what an answer text means; questions.sh
  `counts`, `--cycle-diff` and board.sh also run `ANSWER_AWK` or `check_answer`.
- `--main-log`'s `answers` class (`log_class`, `scripts/build-loop.sh`) took only a
  one-parent commit changing the two questions files in answer-shaped lines.
- `approval` (`--merge --approved`) matched `check_answer`'s line exactly.
- `docs/human-author/` is on truthrule's list: build loops cannot land it and
  `--cycle-diff` refuses it, so its writers are the owner and hand sessions.

## Design (as built)

- **One rule (S3).** `option()` moved into `OPTION_AWK`; `ANSWER_AWK` is
  `OPTION_AWK` plus its entry reader (byte-identical program), and the new
  `ANSWERS_FILE_AWK` uses the same `option()`. The label-regex pin test still sees one copy.
- **Which files.** Paths directly under `docs/human-author/` named `answers-*` on main's
  tree. Anything else there is not read. An `answers-*` entry that is not a regular file
  (a symlink, a directory), has a path form `pathform` refuses, or that `FENCE_AWK`
  refuses is *named* in a skip (H2), never read.
- **Which lines.** Outside fences, a line starting (after an optional `- `) with
  `Q-NNN:`; the text after the colon is read by `option()`.
- **Dated.** A file's date is the committer date (`%cs`) of the newest first-parent
  commit that added it (diffed against its first parent, renames off, so a merge dates it
  at the merge). One `git log` per main commit lists them all; it is cached per `MAIN_SHA`.
  The entry's date is a new third output line of `ANSWER_AWK` (its header's
  `**Opened:**` field). A file dated before `Opened:` is not read (the ID-collision residual).
- **Combining.** The questions-file result is read first, as before (all its skips
  unchanged). Then, for files in the window:
  - every file line for the ID must agree, else `skip Q-NNN: A reads X but B reads Y`;
  - an open entry with a file answer prints `OPTION Q-NNN from PATH:LINE` (the first line);
  - an answered entry prints its own result when the file agrees, and a skip naming both
    when the file gives a *different option*;
  - an unreadable `answers-*` entry in the window is a skip naming it;
  - an open entry with no valid `Opened:` date and any file line for the ID is a skip
    (the line is not read as its answer);
  - a line for the ID in a file added before `Opened:` but changed on or after it is a
    skip naming it (an append to an old file may be this entry's answer or an old ID's).
- **Callers that match the line whole.** The lib's `answer_word` drops the ` from PATH:LINE`
  suffix; `approval` (`--approved`) and rubric-check's `qref` rows use it. board.sh's
  `answer` names the file when only a file answers the entry.
- **`--main-log`.** A one-parent commit whose every path is a direct
  `docs/human-author/answers-*` child, added or changed, mode 100644 (before and after),
  is `answers`. A deletion, an executable, a directory child or any other path is `other`.
- **`--approved`.** Through `answer_word`, a file answer approves a merge like a
  questions-file one; the entry's heading still has to name the merge.
- **Skill.** Step 0.2 says what an `answers` line can now be; step 7 says how a file answer
  prints, that the final message names each one with its file and line, and how a
  conflict shows.

## Choices with fewer than 3 viable options (one line each)

- Output shape: a ` from PATH:LINE` suffix on the existing line, not a second line. It keeps
  the one-line-per-ID contract, and the prefix matches board.sh's `keep\ *` patterns, so the
  board hides an entry a file answered.
- Committer date, not author date: the day it reached main, which is what D8 (an answer
  counts once it reaches main) dates; it is the later of the two, so the window is never narrower.
- A file line read as `unrecognized` (prose) does not conflict with a recorded option in
  the questions file. The owner's 11-20 file is all prose (`Q-302:` then paragraphs), and the
  recorder's `[3]` in the archive is the reading; a strict rule turned Q-302 and Q-327 into
  skips. The reverse (questions file `unrecognized`, file an option) stays a skip: taking
  the file's option there would read an answer neither source alone gives (10 archived IDs
  here, Q-069 to Q-116, all long applied; a rubric `qref` row naming one would reopen,
which fails closed).
- Modified answers files count as `answers` in `--main-log` (not only added ones): the reader
  reads the file's content at main, so a later edit can change an answer, and step 0.2 has to
  show it.

## Real-repo check

Every ID named in this repo's answers files, through `--check-answer` on this branch:
37 keep, 22 drop, 6 done, 27 unrecognized, 10 skip at first count (Q-045: two files
disagree, the later one prose; the archived IDs above; the reviewer counted 11 with Q-116). `--main-log` from 7df4654d's parent reads
7df4654d as `answers`.

## Residual risks

- Dates are calendar days in the writer's own zone on both sides (`%cs`, and `Opened:` by
  `date +%F`); a committer in another zone can shift the window a day. A line it misses
  stays `open` and is asked again; a line it takes early is at worst one day's collision.
- A merge that brings in an answers file, or a commit that changes one beside a questions
  file, is read by `--check-answer` but listed by `--main-log` as `other` (still shown).

- Same as the triage's for option D: a hand session can write an answers file, as it can
  already write `questions.md`.
- A file renamed (a delete plus an add under `--no-renames`) dates from the rename.
- A range line (`Q-235..237: [1]`) in a file is not read, as in the questions files.

## Review (round 1)

A fresh reviewer found nothing blocking; fixed: an append to an older answers file was
silently ignored (now a named skip), an undated unreadable row lost its reason (tab
parsing), the cache key was not cleared on a failed re-read, rubric-check and board.sh
matched the line whole. Documented: the two `other` shapes and the date zones.

## Verification

- New bats cases: `test/scripts/dev-cycle.bats` (a file answer, an older file not read, a
  conflict with the entry and between two lines, no `Opened:` date, a fenced line, a
  non-answers file, a side-branch merge dated at the merge, a working-tree-only file, an
  unreadable symlink, fence and directory, one that predates the entry not named);
  `test/scripts/build-loop-orchestrator.bats` (`--main-log`'s class and its near misses);
  `test/scripts/build-loop-merge.bats` (`--approved` from a file answer).
- `scripts/confine-tests.sh --probe` exits 3 in this sandbox ("confine-tests: NO
  CONFINEMENT PRIMITIVE AVAILABLE — refusing to run."), so the suites ran unconfined, plus
  `scripts/hermeticity-lint --root .` (passes) and the health check.
