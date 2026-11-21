# Research: `harness-feedback.py ingest` and a renamed project

Brief: `docs/working/briefs/2026-11-20-ingest-project-rename.md` (dispatch 1). Branch `fix/ingest-project-rename` from 5627e74c.

## What the code did

- `cmd_ingest` picks its target as `docs/working/feedback/PROJECT.md` (or the source itself when it already sits in that directory) and skips an entry when the idea log holds `(signal: harness feedback PROJECT F-NNN,`. Both key on the file's `Project:` line. [observed, `scripts/harness-feedback.py` at 5627e74c]
- Its only guard compared the stored copy at the target with the new file's leading signatures (`sig()`: ID, slug, meta line). An empty stored list is a prefix of every list, so a zero-entry stored copy holding another `Project:` passed and was overwritten. [observed]
- `cmd_pending` (the board's read-only comparison) already matched stored copies by `Project:` line and withheld the command for a stored copy under another file name, entries stored under another Project, and a `NAME.md` held by another Project. Its reasons ("ingest would store it twice") described ingest's unguarded behaviour. [observed]
- Repo state: `docs/working/feedback/philosophy-research.md` says `Project: task-workspace-designer` (owner commit ad4f0eef), holds 22 entries; the idea log holds 19 seeds keyed `harness feedback philosophy-research F-NNN, docs/working/feedback/philosophy-research.md` and none keyed `task-workspace-designer`. [observed: `grep -c`]

## Failure patterns

Failure-pattern grep: FP-138 (keywords: rename, prefix, vacuous, empty list, Project, seed)
- FP-138 (a rename left a file name contradicting its contents): the shape of today's stored copy; the fix refuses that state and gives one command that makes name, Project line and seeds agree again.
- FP-038, FP-043 are loose "rename" matches (a JSON guard, a pathlib write escape), not this.
- The zero-entry overwrite is the `vacuous-assertion` class (a prefix check that passes on an empty list); recorded as FP-189.

## Design (divergent design, constraints H2, S3, S4, S5, S8)

Motive (S5): real, not loop-internal. Ingesting either file today adds 22 seeds (19 duplicates) or writes a second stored copy; the board withholds the command, but a hand run is unguarded, and the guide offered "rename its Project: line" as a remedy that leads straight into it.

| Option | What ingest does on a rename | Cost | Risk |
|---|---|---|---|
| **A. Match by entries, keep stored name** | finds the stored copy by its first entry's signature, writes there, keys seeds by stored path | seed key changes; pending must change to print the command; mixed seed names in the log | silently merges two projects that share an F-001 signature; keeps a file name that contradicts its contents (FP-138) |
| **B. Refuse, name the stored file and the fix** | refuses every disagreeing state, prints a `rename` command | ~40 lines plus a `rename` mode (S4: the mechanical fix in a tested script) | none silent; the owner runs one command |
| **C. Document only** | unchanged | guide prose | fails the brief's goal (ingest still re-seeds) |

Path A (one option dominates): **B**. It is the H2 shape (refuse and name the state), it agrees with `pending` by construction because both call one helper `stored_match()` built on `sig()` (S3), and it does not guess which project a copy belongs to. C fails the goal; A trades a refusal for a silent guess. The zero-entry overwrite is refused in B by comparing the stored copy's `Project:` line before the prefix test.

Other choices (one line each):
- The rename fix is a script mode, not a printed `git mv && sed -i` line: BSD and GNU `sed -i` differ, the seed rewrite needs an escaped path, and S4 wants mechanical steps tested.
- `rename` rekeys seeds by the stored copy's path (`, docs/working/feedback/OLD.md)` in the signal), not by the old name, so it also repairs today's state where the file name, Project line and seeds disagree.
- Ingest reads every stored copy (`*.md` in the feedback dir); one failing `check` or two holding one Project refuse ingest, as they make `pending` print NOT COMPARED.
- `pending`'s withheld lines keep their shape; only the reason now says "ingest refuses until it is renamed" (board.bats and `guides/cross-project-board.md` updated).
- The new seeds-under-another-name check reads the idea log, which `pending` does not see. A hand-made half rename (file moved, seeds not) makes the board print a command that ingest then refuses loudly: the safe direction, left as is.

## Plan and result

1. `stored_match()`, `seed_re()`, `read_stored()`, `ingest_refusal()` and `cmd_rename()` in `scripts/harness-feedback.py`; `cmd_pending` reuses `stored_match()`.
2. bats: renamed project refused by ingest and pending, renamed, then ingested with 1 new seed and one copy; stored copy under another file name; Project line changed in place (seeds under old name); empty stored copy under another Project; two stored copies with one Project and a stored copy failing check; `rename`'s refusals. Normal-path cases unchanged and passing. The five ingest cases fail with the guard disabled (mutation run).
3. Guide: "A renamed project" section in `guides/harness-feedback.md`; the edited-old-entry remedy is now `git rm` of the stored copy (a Project-line rename now refuses).

## The owner's file

`docs/working/feedback/philosophy-research.md` (owner's file; not edited here). Whether its `Project:` line should change back depends on the project's own `docs/harness-feedback.md`, which the sandbox cannot see. If the project now says `task-workspace-designer`, keep the line and run `scripts/harness-feedback.py rename docs/working/feedback/philosophy-research.md task-workspace-designer` (moves the file, rekeys the 19 seeds). If it still says `philosophy-research`, set the line back, or equivalently run `... rename docs/working/feedback/philosophy-research.md philosophy-research`. Until then every ingest of it refuses, naming that command.

## Tests

- `scripts/confine-tests.sh --probe`: exit 3, "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the suites ran unconfined plus the hermeticity lint.
- `bats test/scripts/harness-feedback.bats test/scripts/board.bats`: 93 ok. `scripts/hermeticity-lint --root .`: exit 0.

## Review round 1 (fresh reviewer, no reds)

- A2 fixed: a rename match now needs the stored copy's whole signature list to lead the new file's and the first entry's text to be equal, so two projects that filed the same F-001 heading, feature, date and verdict both ingest (new bats case). Applied in `stored_match`, so `pending` moves with it.
- A3 fixed: the first rename case holds a seed for another stored path under the same old name (left alone) and a `Project:` line in an entry body (kept); the rename refusals assert the idea log unchanged. Both new assertions fail under the matching mutation.
- G1: the guides now say which refusals print the rename command. G2: a failed idea-log write in `rename` undoes the new copy. G3: a symlinked stored `.md` pointing at the source is refused, not skipped. G4: `rename` resolves the source's directory. G5: docstring.
- A1 kept as a stated residual: `pending` reads no idea log, so for a copy whose seeds sit under another name at the project's own file name (a hand-made half rename) the board prints a command that `ingest` then refuses. Closing it means board.sh extracting main's idea log for `pending`, a second change to the board's read path for a state that only a hand edit reaches; the miss is loud and writes nothing (H2's fail-closed side). Said in `guides/harness-feedback.md`.
- G6 (a copy moved by hand with seeds left on the old path is re-seeded) is not in the repo today; left.
