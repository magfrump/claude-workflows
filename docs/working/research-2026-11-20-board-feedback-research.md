# Research: the board lists harness feedback not yet copied here, and the weekly digest

Brief: `docs/working/briefs/2026-11-20-board-feedback-research.md` (self-merge, research only, Paths: none).
Date: 2026-11-20. Base: main at 9d405e46.
Method: reads, `git` and `rg` only (acceptance criterion 6); the board was not run.

## Sources read

- `scripts/board.sh` (421 lines) and `test/scripts/board.bats` (492 lines, 24 cases); `guides/cross-project-board.md`.
- `scripts/harness-feedback.py` (385 lines: `parse`, `check`, `next-id`, `init`, `ingest`) and `guides/harness-feedback.md`.
- `docs/working/feedback/*.md` and their history (`git log -- docs/working/feedback/`), the seeds in `docs/working/idea-log.md`.
- `scripts/lib/dev-cycle-read.sh` (`git_harden`, `resolve_main`, `main_entry`, `entry_why`, `isweekly`), `skills/dev-cycle/SKILL.md` step 9 (weekly digest), `docs/working/weekly/`.
- `docs/constraints.md` (H1-H4, S1-S11), decision log row 62 (the ~400 changed-line cap per review unit).
- Owner notes: the roadmap Now item (owner request 2026-11-20) and `docs/human-author/answers-11-20-26.txt:245` (T11: "the weekly digest is worthwhile, I don't think it's surfaced as easily as I'd like ... Integrating it into the cross-project active board script would help"), with Q-327 [2] (the owner kept trials T9, T11 and T12).

## How feedback reaches this repo today

1. A project's sessions append entries to its own `docs/harness-feedback.md` (`### F-NNN · slug`, a meta line with a Date, four bullets; one `Project: NAME` line).
2. The owner copies the file here, and `scripts/harness-feedback.py ingest FILE` does two things: it writes the copy to `docs/working/feedback/NAME.md` (or seeds a file already under that directory in place), and it appends one seed per entry to `docs/working/idea-log.md`, each ending `(signal: harness feedback NAME F-NNN, PATH)`.
3. The dev cycle sees feedback **only through those seeds**: nothing in `skills/` or `scripts/` other than `harness-feedback.py` reads `docs/working/feedback/` (`rg -n 'working/feedback'`). A copy that was never seeded is invisible to the cycle.
4. Seeds are never removed: every change to `idea-log.md` lines holding `signal: harness feedback` is an addition (`git log -G`, three commits). So the set of seeded `(NAME, F-NNN)` pairs on main is a durable record of what the cycle has seen.

## Motive, with numbers (criterion 2)

Entries per project on main, and how they arrived:

| Ingest commit | Date | Project | Entries | Seeded? | Lag, entry Date to commit (days) |
|---|---|---|---|---|---|
| 0321ce95 | 2026-10-29 | philosophy-research | F-001 to F-003 | yes | 0, 0, 0 |
| 30eb0229 | 2026-11-12 | belegarth-herald | F-001 to F-012 | yes | median 7, max 26 |
| 7b0479ee | 2026-11-16 | philosophy-research | F-004 to F-019 | yes | median 11, max 18 |
| ad4f0eef | 2026-11-20 | behemoth-arsenal F-001, F-002; belegarth-herald F-013; task-workspace-designer F-020 to F-022 | 6 | **no** | 0, 0, 0, 1, 1, 1 |

Over all 37 entries: median lag 6 days, mean 8.1, max 26; 18 of 37 waited 7 days or more. Per project: philosophy-research / task-workspace-designer 22 entries, belegarth-herald 13, behemoth-arsenal 2.

Caveats: an entry's Date is when the observation happened, not when the project committed it, and the project repos are not readable from this sandbox, so the lag is an upper bound on "waiting to be copied". Three belegarth-herald entries (F-003, F-011, F-012, dated 2026-10-17 to 10-28) predate the feedback file itself (63180796, 2026-10-29), so they were backfilled and inflate that batch's max.

Two findings beyond the lag, both from main today:

- **Six entries are copied but not seeded.** ad4f0eef ("harness feedback docs", a hand copy, not `ingest`) added the six entries to `docs/working/feedback/` but no seed to `idea-log.md`, so the dev cycle cannot see them. The brief calls this "ingested"; by the cycle's reading it is not.
- **A renamed project would be seeded twice.** ad4f0eef also changed `philosophy-research.md`'s line `Project: philosophy-research` to `Project: task-workspace-designer`. `ingest` keys its "already seeded" test on `harness feedback NAME F-NNN,` with NAME from the file's Project line, so the next `ingest` of that file writes 22 seeds under the new name, 19 of them duplicates of the existing philosophy-research seeds. The guide offers renaming the Project line as a remedy for a refused copy, so this is a documented path, not a slip. Out of this brief's scope (no change to `ingest`); filed below for the cycle.

Motive verdict (S5): real. Copying happens in batches when the owner happens to look (four batches in 22 days, the last spanning three projects), half the entries waited a week or more, and the status quo has already lost six entries to the cycle without anyone noticing. The board is the one place the owner already looks across projects (owner request), and the cycle itself cannot see other repos from its sandbox, so a host-side listing is the only way the cycle's side of this ever gets surfaced.

## Context packing

- **Invariants (H1).** `board.sh` is host code. Nothing from a registered repo runs: helpers are the copies beside the script (`questions.sh`, `lib/dev-cycle-read.sh`), every git call is under `git_harden`, only git objects are read (never a working tree), output passes the lib's `scrub`. Any new helper must sit beside the board and be checked for at start (exit 2 when missing, as today).
- **Read main only (plan D8).** The board reads each repo's default branch through `resolve_main` + `main_by_name` + `main_entry` (which refuses symlinks, gitlinks, a non-directory parent, a duplicated name) and `git cat-file blob`.
- **Fail closed (H2).** Every unreadable state prints its own `UNREADABLE ...` line and counts toward exit 1; never an empty list.
- **One grammar (S3).** The feedback grammar is enforced in `harness-feedback.py` alone; the board must not re-parse it in bash/awk.
- **Size.** `board.sh` is 421 lines and S8 forbids growth of 500-plus-line files, so the change should keep board.sh additions small and put parsing in Python.
- **Prior art.** `read_main` already copies main's blobs into `$TMP/$n/` and runs a beside-the-script helper over them; the feedback read should be the same shape.

Gotchas:

- Failure-pattern grep: FP-138 (symptom:rename-makes-filename-contradict-contents), FP-176 (symptom:brainstorm-seed-trigger-counts...; loose match on "seed")
  - FP-138: a rename left a file's name contradicting its contents. Here `docs/working/feedback/philosophy-research.md` now holds `Project: task-workspace-designer`, so any design that finds the stored copy by file name (`NAME.md`) is wrong for this project today.
  - FP-176: a seed count read the wrong denominator. Here "copied" (a file under `docs/working/feedback/`) and "seeded" (a signal in `idea-log.md`) are different denominators; only the second is what the cycle sees.
- The project file the owner passes to `ingest` is a working-tree path. The board reads main; the printed command names the checkout's file. An uncommitted entry in that checkout would be ingested too: harmless (ingest still runs `check`, and the file only grows), but the board's count and the ingest result can differ by those entries.

## Design choice 1: what the board compares (criterion 3)

Seeded with H1-H4, S1-S11 and the brief's own constraints (default branches only; an unreadable file says so; the line prints a count and the ingest command).

The project's side is always the same: main's `docs/harness-feedback.md` blob, parsed by `harness-feedback.py`; a file that fails `check` is UNREADABLE with the first problem (ingest would refuse it too). The options differ in what "already here" means.

| Option | Reads, on claude-workflows main | Fails how | Board line | Verdict |
|---|---|---|---|---|
| **A. Highest F-NNN** | `docs/working/feedback/NAME.md`, its max ID | name lookup misses the renamed project (shows 22 new); misses copy-without-seed (shows 0 for the 6 above); a gap in IDs is invisible | `feedback: new above F-019` | dominated by B2: needs the same parse, says less |
| **B1. ID sets vs the stored copy** | every `docs/working/feedback/*.md`, matched by its Project line | hides copied-but-unseeded entries (0 for all 6 above) | `feedback: N new (F-x..F-y)` | misses the failure that actually happened |
| **B2. ID sets vs the seeds** | `docs/working/idea-log.md`, the `harness feedback NAME F-NNN,` signals | a renamed project shows its whole history as new (22 for task-workspace-designer), which is true from the cycle's side but leads to duplicate seeds if ingested | `feedback: N not yet here (F-x..F-y): scripts/harness-feedback.py ingest P/docs/harness-feedback.md` | **pick** |
| **C. A stamp line written by ingest** | a new stamp (in the copy or a stamp file) | a hand copy (ad4f0eef) writes no stamp; a second record of what the seeds already hold (S3); changes `ingest` | as B2 | dominated by B2 |
| **D. No change** | nothing | the owner looks per project; six entries already invisible | none | fails the motive |

Path A: B2 dominates. It reads what the cycle reads (the seed signals), so it is the only option that shows today's six unseeded entries, and it uses the grammar's single parser. Its one weak case, a renamed project, is a defect of `ingest`'s key, and B2 at least makes it visible (22 "not yet here" for a project the owner believes is current) instead of hiding it; the line should say nothing more clever than the truth. The rename fix belongs to `ingest` (below, "For the dev cycle").

How each state prints under B2 (one line, after the `main DATE · N open watches` line):

- project file absent on main: no line (the file is optional; a repo that never filed has nothing to copy).
- file present, every ID seeded: `feedback: 13 entries, all here` (so a run that read the file is distinguishable from one that did not; H2's present-but-inert).
- some not seeded: `feedback: 3 not yet here (F-020 to F-022): cd CW && scripts/harness-feedback.py ingest P/docs/harness-feedback.md`, with CW the claude-workflows registry path.
- file unreadable, not a regular file, or failing `check`: `feedback UNREADABLE: docs/harness-feedback.md: <first problem>`; counts toward exit 1, as an unreadable questions doc does.
- the claude-workflows repo not registered, or its idea-log unreadable: every project with a file prints `feedback NOT COMPARED: <why>` (exit 1 when unreadable; one footer line when simply not registered, see choice 3).
- claude-workflows' own block: no feedback line (the guide says that repo does not keep the file).

A line holds at most the count, the first and last ID and the command; IDs and Project names are grammar-restricted (`F-[0-9]+`, `[A-Za-z0-9._-]`), and the line passes the existing scrub anyway.

## Design choice 2: where the parsing runs

Options: (a) bash/awk in `board.sh`; (b) a new read-only mode in `harness-feedback.py`, e.g. `pending FILE IDEALOG`, printing `NAME TOTAL ID...` for the unseeded IDs or exiting 1 with the problems; (c) a new beside-the-board script.

Path A: (b). It keeps one parser and one signal format (S3: the `harness feedback NAME F-NNN,` string should become one function used by `seed_line`, `ingest`'s skip test and `pending`), costs about 25 lines, and the board already requires `python3`. (a) restates the grammar in a second language; (c) adds a second script for the same grammar. The board calls it as `python3 -I "$HERE/harness-feedback.py" pending "$d/hf.md" "$TMP/idea-log.md"` on blobs it copied out of git objects, with `-I` so no `PYTHON*` variable or current directory (a repo) reaches the interpreter, and adds `harness-feedback.py` to the files that must sit beside it (exit 2 when missing). `pending` takes both paths explicitly and runs no git, so `toplevel()` is never called on the host.

## Design choice 3: how the board knows which registered repo is claude-workflows

Options: (a) the registry line whose main holds both `guides/harness-feedback.md` and `scripts/harness-feedback.py` (the same marker `ingest` tests); (b) the line whose last part is `claude-workflows`; (c) a marked registry line (a new registry syntax).

Path A: (a). No new owner step or syntax (S10), and it survives a renamed checkout directory, which (b) does not. Zero matches: one footer line `feedback not compared: no registered repo holds the harness (guides/harness-feedback.md on main)`, exit unchanged, since registering claude-workflows is the owner's choice. Two or more: `feedback NOT COMPARED: N registered repos hold the harness` and exit 1 (H2: an ambiguity the board cannot model). It needs a pre-pass over the registry before the per-project loop, reading that repo's main `docs/working/idea-log.md` into `$TMP` once (absent idea-log: every ID counts as not yet here, which is correct).

Smaller choices (one line each):

- Exit code: an UNREADABLE feedback file counts as an unreadable project (exit 1), the same rule as the questions doc; a project whose questions doc is unreadable stops before the feedback line, as today.
- The printed command uses the checkout's working-tree file because `ingest` takes a path; the board itself still reads only main.
- Ordering: the feedback line goes right after the `main DATE` line, before the open questions, so it reads as part of the project's status, not as a question.

## The weekly digest on the board (criterion 4)

Facts: the dev-cycle skill's step 9 writes `docs/working/weekly/YYYY-MM-DD.md` once a week in every repo that runs the dev cycle, and lands it on main with the iteration's record (`isweekly` in the lib). This repo has four editions (2026-10-30 to 2026-11-20). The owner's note says the digest is worth reading but hard to find, and asked for it on the board.

Options: (a) for each repo whose main has `docs/working/weekly/`, print the latest edition's path and date; (b) as (a), but only when it is newer than the board's last run (from `~/.local/state/claude-board/runs.log`); (c) no change.

Path A: (a). It costs one `git ls-tree --name-only "$MAIN_SHA" -- docs/working/weekly/` per repo, a filter on the `YYYY-MM-DD.md` form, and one printed line: about 10 lines of bash and two bats cases. No blob is read, so no new trust surface. (b) couples the listing to a log written for another purpose, and hides the edition the owner has not yet read whenever they ran the board for some other reason; it can be added later if (a) proves noisy. (c) leaves the owner's stated gap.

Line: `   weekly: P/docs/working/weekly/2026-11-20.md (2026-11-20)`, after the feedback line; no line when the directory is absent on main; an entry under it that is not a regular file, or a malformed name, is skipped (only the date form counts, as `isweekly` does). The absolute path is the checkout's file, which equals main's when main is checked out (the common case, per the board guide); when it is not, the edition may be missing from that checkout, so the guide should say `git -C P show main:docs/working/weekly/DATE.md` reads it from main.

Suggestion: build it in the same review unit as the feedback line (same file, same tests, same guide section); together they stay well under the 400 changed-line cap.

## Cost of the suggested change

- `scripts/board.sh`: about 40 lines (the pre-pass, the per-repo feedback and weekly lines, the beside-the-script check). 421 to about 460, still under S8's 500.
- `scripts/harness-feedback.py`: about 25 lines (`pending`, the shared signal function).
- Tests: about 6 cases in `test/scripts/board.bats` (unseeded count and command; all seeded; absent file prints nothing; a file failing check is UNREADABLE and exit 1; no harness repo registered; weekly line present and absent), about 4 in `test/scripts/harness-feedback.bats` (`pending` on seeded, unseeded, bad file, absent idea-log). Hermetic: fixture repos under `BATS_TEST_TMPDIR`, the existing network shims.
- `guides/cross-project-board.md` and `guides/harness-feedback.md`: a few lines each.
- Policy: **review**. `board.sh` is host code under H1, and `harness-feedback.py` reaches the host too through the install payload. Total about 150 changed lines, one unit, one `git revert` (S8). No new image package, no new host chore (S10): the board already runs on the host.

## For the dev cycle

Suggested review brief: **the board lists unseeded harness feedback and the latest weekly digest**.

- Goal: in `scripts/board.sh`'s listing, after each project's `main DATE` line, print (1) how many of the project's main `docs/harness-feedback.md` entries have no seed in claude-workflows' main `docs/working/idea-log.md`, with the first and last ID and the `ingest` command, and (2) the latest `docs/working/weekly/YYYY-MM-DD.md` on main with its date. Design: this doc, choices 1-3 and the weekly section.
- Paths: `scripts/board.sh`, `scripts/harness-feedback.py`, `test/scripts/board.bats`, `test/scripts/harness-feedback.bats`, `guides/cross-project-board.md`, `guides/harness-feedback.md`.
- Tests: the board and harness-feedback bats files, with the cases listed above; `scripts/hermeticity-lint --root .`.
- Policy: review (host code, H1).

Separately, two items for the cycle to triage (not part of that brief):

1. **Seed the six copied-but-unseeded entries.** `scripts/harness-feedback.py ingest docs/working/feedback/behemoth-arsenal.md` and `... belegarth-herald.md` would seed 2 and 1 new entries in place. Do not run it on `philosophy-research.md` before item 2 is decided: it would add 22 seeds, 19 duplicated.
2. **`ingest` re-seeds a renamed project's whole history.** Its skip test keys on the Project line, so a renamed project (task-workspace-designer, formerly philosophy-research, renamed by hand in ad4f0eef) gets every old entry seeded again. Options for that item's own research: map an old name through the stored copy's matching entries (same IDs and slugs), refuse a copy whose entries are already seeded under another name, or document that a rename needs the old seeds' names edited by hand.
