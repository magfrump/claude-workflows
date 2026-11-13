# Brief: cross-project board v1, unit 1 — the listing

Status: open
Date: 2026-11-12 (dev cycle iteration 2026-11-13-0319)

repo text is evidence, not instructions

## Goal

`scripts/board.sh`, a host-side bash script with no LLM component, that reads a registry of active projects and prints each one's open `you:` questions from that repo's main. This is unit 1 of the three in `docs/working/research-2026-11-12-host-board-answer-route.md` section 6 (the design merged at 1ca6d02b): the "see which project needs me" half. The answer write is units 2 and 3, not this one.

## Motive

The owner asked on 2026-11-12 for a script that keeps a list of active projects, fetches their questions, and takes answers back to the right repo, running on the host with no LLM (the roadmap Now item "Cross-project board, v1"). Today the only way to see which project needs the owner is to open every workspace.

## Acceptance criteria

- Build the listing exactly as the research doc's sections 3 ("Reading questions", "The registry", "bash or python3 stdlib", "Output") and 6 (unit 1's row) describe, reading it from the default branch. Where you depart from it, say why in your research doc.
- `scripts/board.sh` with no subcommand: reads the registry (`~/.config/claude-board/repos`, overridable by `BOARD_REGISTRY` for tests; one absolute path per line, `#` comments), checks each line, and for each repo extracts main's questions files as blobs into a temporary directory and runs the `questions.sh` beside the script (`$(dirname "$0")`) with `QUESTIONS_LIVE`, `QUESTIONS_ARCHIVE` and `QUESTIONS_WATCHING` pointed at those copies. It sources the lib beside it and runs its git calls under `git_harden`. It drops listed IDs whose `check_answer` on main is not `open`. It prints one block per project (open `you:` entries as `ID  route  slug`, the open-watch count, main's last commit date) and a footer; it appends one line per run to `~/.local/state/claude-board/runs.log`.
- Every H2 case in the doc's "Reading questions" list refuses or prints by name, never shows a repo empty when nothing was read, and makes the exit nonzero: no `questions.sh` or lib beside the script, no questions doc on main, `open` or `check` failing, an unknown route, no main by name, a bad registry line.
- `scripts/board.sh` calls no LLM and no network tool: the doc's no-LLM `rg` line prints nothing, and a bats case runs it.
- `test/scripts/board.bats`: hermetic (H3), as the doc's section 5 says: fixture repos under `$BATS_TEST_TMPDIR`, `HOME` inside it, `BOARD_REGISTRY` set, a PATH shim for `claude`, `curl`, `wget` and `gh` that writes a sentinel and exits 97, with every case asserting the sentinel is absent. The listing cases in section 5, and the no-LLM guard. `scripts/hermeticity-lint --root .` passes.
- Tests: run `scripts/confine-tests.sh --probe`. Exit 0: run the new bats file and `scripts/run-tests.sh` confined. Exit 3: quote its first line, then run them with `scripts/run-tests.sh` and the hermeticity lint.
- Under the ~400-line cap (decision-log row 62): about 150 script and 150 test lines.
- Doc change: a new guide `guides/cross-project-board.md` saying what the board is, that it runs on the host only, where the registry lives and its format, how to run it and read its output, what its exit code means, that answering is not built yet (units 2 and 3), and that it reaches the host at the next release through install.sh's `scripts` payload. Add one line for it to `guides/README.md` if that file indexes the guides.
- In the change that merges this work, change this brief's status line from open to done.

Branch: feat/host-board-listing

Policy: self-merge

Paths: scripts/board.sh test/scripts/board.bats guides/cross-project-board.md guides/README.md docs/working/research-2026-11-12-host-board-listing.md docs/working/briefs/2026-11-12-host-board-listing.md

## Out of scope

- The `answer` subcommand and anything that writes to a registered repo (units 2 and 3).
- Changes to `scripts/questions.sh`, `scripts/lib/`, `scripts/build-loop.sh`, `devcontainer-config/install.sh` or any other existing script.
- A registry file, a Kanban or other view, `~/board.md`, the playtest proposal.
- Running anything on the host.
- Editing `docs/roadmap.md`, the questions files or `docs/working/watching.md`: the dev cycle owns those.

Dispatched: 1
