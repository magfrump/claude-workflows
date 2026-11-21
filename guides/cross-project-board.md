# The cross-project board

`scripts/board.sh` shows which of your projects is waiting on you, and takes a one-line answer back to the right repo. It reads a list of repos and prints the open `you:` questions each one holds, as that repo's default branch has them. It calls no LLM and no network tool.

**Host only.** Run it in your own terminal on the host, never inside a `cc-isolated` session. It reaches the host as `~/.claude/scripts/board.sh` at the next release, through `install.sh`'s existing `scripts` payload (the reviewed diff and y/N you already approve), together with the `questions.sh`, `harness-feedback.py` and `lib/dev-cycle-read.sh` it needs beside it (`harness-feedback.py` runs under `python3 -I`, on file contents read out of git). Nothing from a registered repo runs: every git call is hardened (the lib's `git_harden`), only git objects are read and written (the one exception: an answer written in place, below, replaces one file and its index entry in the checkout that has `main` out), and output is scrubbed of control characters.

## The registry

`~/.config/claude-board/repos`, a text file you edit by hand:

```
# one absolute repo path per line; lines starting # and blank lines are skipped
/home/me/code/claude-workflows
/home/me/code/other-project
```

It sits outside every repo, so no project can add itself. A project is active while its line is there; comment the line out to retire it. `BOARD_REGISTRY` overrides the path (the tests use it).

## Running it and reading the output

```
~/.claude/scripts/board.sh; echo "board exit $?"
```

One block per project:

```
== /home/me/code/other-project
   main 2026-11-12 · 3 open watches
   feedback: 3 not copied (F-020 to F-022): cd /home/me/code/claude-workflows && ~/.claude/scripts/harness-feedback.py ingest /home/me/code/other-project/docs/harness-feedback.md
   weekly: /home/me/code/other-project/docs/working/weekly/2026-11-20.md (2026-11-20)
   Q-012  you: judgment     pick-a-name
```

- The second line is the date of main's last commit and the number of open watches (`deferred`/`trigger` entries in `watching.md`), given as a count. The `feedback` and `weekly` lines are described below.
- Then each open owner entry as `ID  route  slug`, most costly route first, or `nothing open for you`. An entry already marked ANSWERED on main but not yet archived is left out.
- What is read is main's commit (`docs/working/questions.md`, `questions-archive.md`, `watching.md`), not whatever branch or edits the checkout has: that is what the dev cycle reads.
- A project that cannot be read says so in its block, never as an empty list: `no questions doc on main`, `UNREADABLE (questions.sh check: …)` with the first refusal, `UNREADABLE: no branch named main or master`, `UNREADABLE Q-NNN (check_answer: …)` when an entry's file cannot be read, or `UNREADABLE: the board stopped reading this repo (exit N)`. A bad registry line prints `REGISTRY LINE N: …`.
- `REGISTRY LINE N: not a git repository (git: fatal: detected dubious ownership …)` means the repo is owned by another user on the host. The board hides your global git config, so your `safe.directory` setting does not apply. That is deliberate: a repo another user owns is refused, for listing and answering alike. Run the board as that user, or take ownership of the repo.

## The feedback and weekly lines

**Feedback.** For a project whose main has `docs/harness-feedback.md` (see `guides/harness-feedback.md`), the board compares its entries with the stored copies on claude-workflows' main, `docs/working/feedback/*.md`, matching by the `Project:` line inside each file, not the file name. claude-workflows is the one registered repo whose main holds both `guides/harness-feedback.md` and `scripts/harness-feedback.py`; its own block has no feedback line. The comparison is `harness-feedback.py pending`, `ingest`'s own entry signature (ID, slug and meta line), so what it says `ingest` would do is what `ingest` does. The line reads:

- `feedback: N entries, all copied`.
- `feedback: K not copied (F-a to F-b), C changed (F-x to F-y): cd CW && ~/.claude/scripts/harness-feedback.py ingest P/docs/harness-feedback.md`: entries missing from the stored copy, or whose text changed (an edited bullet) with the same signature, and the command that copies them. The command names the installed script, run from your claude-workflows checkout; it reads the project checkout's file, so run it with that checkout on main: the board judged main's file, and a branch's file (another `Project:` line, say) can make `ingest` store a second copy. Commit the copy: the count drops once that commit reaches claude-workflows' main.
- With **no command**, because `ingest` would refuse or store a duplicate: `F-NNN differs from the stored copy …` (an old entry's ID, slug or meta line changed, or the stored copy has more entries); `its stored copy is X, not docs/working/feedback/NAME.md, so ingest would store it twice` (the stored file has another name); `stored under Project OTHER (X); renamed?` (the project's entries are stored under another `Project:` name); or `X holds Project OTHER` (its name's file belongs to another project). Settle the rename by hand first: for a stored copy under the old file name, `git mv` it to `docs/working/feedback/NAME.md` in claude-workflows and commit; seeds are matched by Project name and ID, so the next `ingest` seeds only new entries.
- `feedback UNREADABLE: …`: the project's file is not a regular file on main, or fails `check` (the first problem is shown), or `pending` stopped (`harness-feedback.py pending stopped (exit N): …`).
- `feedback NOT COMPARED: …`: a stored copy fails `check` or is not a regular file, two stored copies hold one `Project:` name, two registered repos (by top level) hold the harness, or a repo's main holds one of those two files while the other is there but not a regular file (a symlink, say), so the board cannot tell whether it is the harness. It shows on every project with a file.
- No line: the project has no file, or no registered repo holds the harness; the latter adds one footer line, `feedback not compared: no registered repo holds the harness …`, and leaves the exit code alone.

**Weekly.** For a repo whose main has `docs/working/weekly/` (the dev cycle writes one digest a week), `weekly: PATH (DATE)` names the latest `YYYY-MM-DD.md` there. The path is the checkout's file, which matches main's while main is checked out; otherwise the edition reaches the checkout when it next takes main. `weekly: none yet` means the directory holds no edition. `weekly UNREADABLE: …` means `docs/working/weekly` (or a directory above it) is not a directory on main, or the latest edition is not a regular file; an older edition is never shown in its place. No directory, no line.

Every `UNREADABLE` or `NOT COMPARED` line counts the project as unreadable (exit 1); its questions still list. A project whose questions doc cannot be read stops before these lines.

A footer counts projects, open entries and unreadable ones. Each run appends one line to `~/.local/state/claude-board/runs.log`.

## Exit code

- `0`: every listed project was read.
- `1`: a bad registry line, an unreadable project (a `feedback` or `weekly` line marked `UNREADABLE` or `NOT COMPARED` included), an empty registry, or the run log could not be written. The other projects still print.
- `2`: the run refused before reading any repo: no registry, `questions.sh`, `harness-feedback.py` or the lib missing beside the script, no `perl` (the scrub needs it) or `python3` (`questions.sh check` needs it), or arguments other than the `answer` form below.
- `3` (`answer` only): the answer is on main, but the checkout that has `main` out could not be brought level with it; the repair is printed (see "In place" below).

## Answering

```
~/.claude/scripts/board.sh answer PROJECT Q-NNN 'TEXT'
```

`PROJECT` is a registry line, or its last part when exactly one line ends in it (`claude-workflows`). Quote `TEXT` so it reaches the board as one argument.

**What it writes, and where.** One commit on that repo's default branch (the branch `origin/HEAD` names, else `main` or `master`), made from git objects alone: no checkout, and no working tree or index of the repo's own unless `main` is checked out (see "In place"). The commit changes two lines of `docs/working/questions.md`: the entry's `**Needs:**` line gets `**Status:** ANSWERED`, and directly under it goes `Q-NNN: TEXT (owner, board YYYY-MM-DD)`. Its subject is `docs(questions): answer Q-NNN from the board`, its author and committer are you (your `GIT_AUTHOR_NAME` and the like, else `user.name` and `user.email` in your global git config), and the branch moves by compare-and-swap, so a commit that lands on main meanwhile is never overwritten. Before the branch moves, the board checks that the new commit changes exactly those two lines and that the dev cycle's own reader (`check_answer`) reads the entry as answered.

The confirmation names the entry's slug, so a mistyped project or ID shows, and says how the cycle reads the answer: `keep`, `drop` or `done` for a leading `[1]`, `[2]` or `[3]`, or `unrecognized` for anything else, which an entry that waits on an option (a merge entry, say) does not act on.

**When the cycle sees it.** The repo's dev cycle reads answers from main's commit, so it picks this one up at its next iteration, lists the commit among the `answers` it saw, and archives the entry. Nothing needs to be told.

**In place, when `main` is checked out.** Most repos keep `main` checked out in their one checkout. Then the board writes there too, but only if that checkout's `docs/working/questions.md` is unmodified: its bytes must equal both main's committed copy and the checkout's index entry (read from git objects and raw bytes, never with `git status`, so no filter in the repo runs). The branch moves first; then the board replaces that one index entry (`git update-index --cacheinfo`, run against an empty work tree so that git reads no file there, not even to re-check other entries, and no filter runs) and then that one file (a temp file beside it, renamed over it). Nothing else in the checkout changes: other edits, staged or not, stay as they were, and `git status` there shows nothing new. If the index entry or file cannot be replaced after the branch moved, the board says main has the answer, exits 3, and prints the repair: `git -C CHECKOUT checkout HEAD -- docs/working/questions.md` (if that file holds no edit of yours). It never says "not written" then.

**When it prints instead.** If the board cannot write safely, it moves no branch, prints `NOT WRITTEN to PROJECT: REASON` and the line to paste into that repo's session (a multi-line answer prints as typed), and exits 1. Exit 0 (or 3) always means main has the answer, even if the run log could not be written after. If the board's own output cannot be written (a closed pipe), trust the `WRITTEN` line or the repo's log over the exit code. It prints instead when:

- `main` is checked out and that checkout's `questions.md` is modified or has a staged change or an index flag, the checkout is mid-merge, cherry-pick, revert, rebase or bisect, it is not at main's commit, or `docs/`, `docs/working/`, the file or its `.git` is a symlink;
- the answer is more than one line, empty, or holds a control character or invalid UTF-8: a multi-line answer needs a session's judgment to record;
- the entry is absent, already ANSWERED, duplicated, inside a code fence, in the archive, a watch in `watching.md`, or not on a `you:` route; or `questions.md` is unreadable, holds a carriage return or is not a plain file;
- a worktree is rebasing `main` or bisecting from it, or the repo is bare with `HEAD` on `main` (HEAD's reflog would be written too);
- the repo keeps its refs in a reftable, defines hooks in git config (`hook.*`), or its default branch's name holds a slash: shapes the board's checks do not cover;
- `.git` holds a symlink at the ref, its reflog, `packed-refs`, `refs/`, `logs/`, `objects/` or an object directory, or (with `main` checked out) at that checkout's git directory, its `index` or `logs/HEAD`, through which a write could land outside the repo;
- `main` moved while the board wrote (the compare-and-swap lost);
- git knows no identity for you, the project is not one registry line, or the repo cannot be read (another user's repo included).

Each answer run appends `answer Q-NNN written` (`written in place`, or `written, checkout behind`) or `answer Q-NNN printed` to the run log. The design is `docs/working/research-2026-11-12-host-board-answer-route.md`; the units' records are `docs/working/research-2026-11-12-host-board-answer-commit.md` (the commit) and `docs/working/research-2026-11-12-host-board-answer-in-place.md` (in place).
