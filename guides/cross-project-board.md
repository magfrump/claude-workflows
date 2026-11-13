# The cross-project board

`scripts/board.sh` shows which of your projects is waiting on you. It reads a list of repos and prints the open `you:` questions each one holds, as that repo's default branch has them. It calls no LLM and no network tool.

**Host only.** Run it in your own terminal on the host, never inside a `cc-isolated` session. It reaches the host as `~/.claude/scripts/board.sh` at the next release, through `install.sh`'s existing `scripts` payload (the reviewed diff and y/N you already approve), together with the `questions.sh` and `lib/dev-cycle-read.sh` it needs beside it. Nothing from a registered repo runs: every git call is hardened (the lib's `git_harden`), only git objects are read, and output is scrubbed of control characters.

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
== /home/me/code/claude-workflows
   main 2026-11-12 · 3 open watches
   Q-012  you: judgment     pick-a-name
```

- The second line is the date of main's last commit and the number of open watches (`deferred`/`trigger` entries in `watching.md`), given as a count.
- Then each open owner entry as `ID  route  slug`, most costly route first, or `nothing open for you`. An entry already marked ANSWERED on main but not yet archived is left out.
- What is read is main's commit (`docs/working/questions.md`, `questions-archive.md`, `watching.md`), not whatever branch or edits the checkout has: that is what the dev cycle reads.
- A project that cannot be read says so in its block, never as an empty list: `no questions doc on main`, `UNREADABLE (questions.sh check: …)` with the first refusal, `UNREADABLE: no branch named main or master`, `UNREADABLE Q-NNN (check_answer: …)` when an entry's file cannot be read, or `UNREADABLE: the board stopped reading this repo (exit N)`. A bad registry line prints `REGISTRY LINE N: …`.
- `REGISTRY LINE N: not a git repository (git: fatal: detected dubious ownership …)` means the repo is owned by another user on the host. The board hides your global git config, so your `safe.directory` setting does not apply; this is expected until the answer-writing units decide how to handle it.

A footer counts projects, open entries and unreadable ones. Each run appends one line to `~/.local/state/claude-board/runs.log`.

## Exit code

- `0`: every listed project was read.
- `1`: a bad registry line, an unreadable project, an empty registry, or the run log could not be written. The other projects still print.
- `2`: the run refused before reading any repo: no registry, `questions.sh` or the lib missing beside the script, no `perl` (the scrub needs it) or `python3` (`questions.sh check` needs it), or an argument given.

## Answering

Not built yet. Answer as today, by writing `Q-NNN: <answer>` in that repo's session. Committing an answer to main from the board is units 2 and 3 of the design in `docs/working/research-2026-11-12-host-board-answer-route.md`.
