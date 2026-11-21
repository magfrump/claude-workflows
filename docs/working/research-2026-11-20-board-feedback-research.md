# Research: the board lists harness feedback not yet copied here, and the weekly digest

Brief: `docs/working/briefs/2026-11-20-board-feedback-research.md` (self-merge, research only, Paths: none).
Date: 2026-11-20. Base: main at 9d405e46.
Method: reads, `git` and `rg` only (acceptance criterion 6); the board was not run.
Review: a fact-check and design reviewer, four rounds, the last clean; every finding is addressed below (see "Review record").

## Sources read

- `scripts/board.sh` (421 lines) and `test/scripts/board.bats` (492 lines, 24 cases); `guides/cross-project-board.md`.
- `scripts/harness-feedback.py` (385 lines: `parse`, `check`, `next-id`, `init`, `ingest`) and `guides/harness-feedback.md`.
- `docs/working/feedback/*.md` and their history (`git log -- docs/working/feedback/`), the seeds in `docs/working/idea-log.md`, `docs/working/research-2026-11-20-harness-feedback-triage.md`, `docs/working/cycles/cycle-2026-11-20.md`.
- `scripts/lib/dev-cycle-read.sh` (`git_harden`, `resolve_main`, `main_entry`, `entry_why`, `isweekly`), `skills/dev-cycle/SKILL.md` step 9 (weekly digest), `docs/working/weekly/`, `install.sh:146` (the whole `scripts/` directory is installed).
- `docs/constraints.md` (H1-H4, S1-S11), decision log row 62 (the ~400 changed-line cap per review unit).
- Owner notes: the roadmap Now item (owner request 2026-11-20) and `docs/human-author/answers-11-20-26.txt:245` (trial T11, one deliberate look a week: "the weekly digest is worthwhile, I don't think it's surfaced as easily as I'd like ... Integrating it into the cross-project active board script would help"), with Q-327 [2] (the owner kept trials T9, T11 and T12).

## How feedback reaches this repo today

1. A project's sessions append entries to its own `docs/harness-feedback.md` (`### F-NNN · slug`, a meta line with a Date, four bullets; one `Project: NAME` line).
2. The owner copies the file here. Either by hand (ad4f0eef did this for three projects) or with `scripts/harness-feedback.py ingest FILE`, which writes the copy to `docs/working/feedback/NAME.md` (or seeds a file already under that directory in place) and appends one seed per new entry to `docs/working/idea-log.md`, ending `(signal: harness feedback NAME F-NNN, PATH)`.
3. The dev cycle notices a copy either way. A seed reaches the brainstorm. A hand copy shows up in the cycle's read of new commits on main: iteration 2026-11-21-0157 saw ad4f0eef's three files (`docs/working/cycles/cycle-2026-11-20.md`, steps 2, 3 and 8) and briefed a triage of exactly those six entries. The triage merged as aa91635c (`docs/working/research-2026-11-20-harness-feedback-triage.md`) and filed roadmap items. So the step that waits on the owner is **the copy**, not the seed.
4. The stored copy is the record of what reached this repo. `ingest` refuses a copy whose entries do not extend the stored one, so the stored file only grows. Seeds are append-only too (`git log -G`, three commits, no removal).

## Motive, with numbers (criterion 2)

Entries per project on main, and how they arrived. Lag is from the day each entry was written in its project to the commit that copied it here. For belegarth-herald, the file's own preamble (`belegarth-herald.md`, "How this was gathered") says F-001 to F-005 were written on 2026-11-07 and F-006 to F-012 on 2026-11-12, so those dates replace the backdated meta-line Dates (some go back to 2026-10-17, before the feedback file existed, 63180796 on 2026-10-29).

| Copy commit | Date | Project | Entries | How | Lag (days) |
|---|---|---|---|---|---|
| 0321ce95 | 2026-10-29 | philosophy-research | F-001 to F-003 | ingest | 0, 0, 0 |
| 30eb0229 | 2026-11-12 | belegarth-herald | F-001 to F-012 | ingest | 5 (×5), 0 (×7) |
| 7b0479ee | 2026-11-16 | philosophy-research | F-004 to F-019 | ingest | median 11, max 18 |
| ad4f0eef | 2026-11-20 | behemoth-arsenal F-001, F-002; belegarth-herald F-013; task-workspace-designer F-020 to F-022 | 6 | hand copy, no seeds | 0, 0, 0, 1, 1, 1 |

Over all 37 entries: median lag 5 days, mean 5.5, max 18; 11 of 37 waited 7 days or more, all of them in one batch (philosophy-research, copied 2026-11-16). Per project: philosophy-research / task-workspace-designer 22 entries, belegarth-herald 13, behemoth-arsenal 2.

Caveat: the project repos are not readable from this sandbox, so the dates are what the copied files say; when an entry reached its project's main is unknown, and the lag is an upper bound on "waiting on main to be copied".

Motive verdict (S5): real but modest. Copies come in batches when the owner happens to look (four in 22 days); one batch waited up to 18 days; and the cycle cannot see other repos from its sandbox, so only a host-side listing can say "this project has feedback you have not copied". The board is where the owner already looks across projects, and the owner asked for this there.

Two findings for the cycle, beyond the brief (below, "For the dev cycle"):

- **The six ad4f0eef entries have no seed.** That is harmless today (the cycle triaged them from the commit). Running `ingest` on those copies now would seed them into the brainstorm a second time.
- **A renamed project is seeded twice and stored twice.** ad4f0eef also changed `philosophy-research.md`'s `Project: philosophy-research` to `Project: task-workspace-designer`. `ingest`'s skip test keys on `harness feedback NAME F-NNN,` (`harness-feedback.py:352`), so ingesting that file in place adds 22 seeds, 19 of them duplicates; ingesting the project's own file instead also writes a second stored copy, `docs/working/feedback/task-workspace-designer.md` (`:329`), whose name then differs from the old one (the shape of FP-138). The guide offers renaming the Project line as a remedy for a refused copy, so this is a documented path.

## Context packing

- **Invariants (H1).** `board.sh` is host code. Nothing from a registered repo runs: helpers are the copies beside the script (`questions.sh`, `lib/dev-cycle-read.sh`), every git call is under `git_harden`, only git objects are read (never a working tree), output passes the lib's `scrub`. A new helper must sit beside the board and be checked for at start (exit 2 when missing, as today). Commands the board **prints** for the owner to run on the host must hold to the same rule: name the installed `~/.claude/scripts/` copy, never a script in a registered checkout, and never an unhardened `git -C REPO ...` (a repo's config, `core.pager` say, would run on the host).
- **Read main only (plan D8).** Each repo's default branch through `resolve_main`, `main_by_name`, `main_entry` (which refuses symlinks, gitlinks, a non-directory parent and a duplicated name) and `git cat-file blob`.
- **Fail closed (H2).** Every unreadable state prints its own `UNREADABLE ...` line and counts toward exit 1; never an empty list or a silent absence.
- **One grammar (S3).** The feedback grammar is enforced in `harness-feedback.py` alone; the board must not re-parse it in bash or awk.
- **Size.** `board.sh` is 421 lines; S8 forbids growth of 500-plus-line files, so board additions stay small and parsing goes in Python.
- **Prior art.** `read_main` already copies main's blobs into `$TMP/$n/` and runs a beside-the-script helper over them; the feedback read takes the same shape.

Gotchas:

- Failure-pattern grep: FP-138 (symptom:rename-makes-filename-contradict-contents), FP-176 (symptom:brainstorm-seed-trigger-counts...; loose match on "seed")
  - FP-138: a rename left a file's name contradicting its contents. `docs/working/feedback/philosophy-research.md` now holds `Project: task-workspace-designer`, so a design that finds the stored copy by file name (`NAME.md`) is wrong for this project today; match by the Project line inside each stored file.
  - FP-176: a seed count read the wrong denominator. "Copied" (a stored file) and "seeded" (an idea-log signal) are different denominators; the owner's ask is about the first.
- A project whose questions doc is missing or unreadable is UNREADABLE today (`board.sh:98`) and stops before any later line, so it shows no feedback line either. The roadmap Ideas item "the board treats a repo with no `docs/working/` as not tracked" covers that case.
- The board reads claude-workflows' **main**. After the owner copies, the line keeps counting the entries until that commit reaches main; the guide should say so.

## Design choice 1: what the board compares (criterion 3)

Seeded with H1-H4, S1-S11 and the brief's own constraints (default branches only; an unreadable file says so, never "0 new"; the line prints a count and the copy command).

The project side is the same for every option except D: main's `docs/harness-feedback.md` blob, parsed by `harness-feedback.py`; a file that fails `check` is UNREADABLE with the first problem (ingest would refuse it too). The options differ in what "already here" means.

| Option | Reads, on claude-workflows main | Fails how | Board line |
|---|---|---|---|
| **A. Highest F-NNN** | `docs/working/feedback/NAME.md`, its max ID | file-name lookup misses the renamed project (22 new); an ID gap is invisible | `feedback: new above F-019` |
| **B1. ID sets vs the stored copies** | every `docs/working/feedback/*.md`, matched by its Project line | two stored files with one Project name: UNREADABLE | `feedback: 3 not copied (F-020 to F-022): COMMAND` |
| **B2. ID sets vs the seeds** | `docs/working/idea-log.md` signals | the renamed project shows 22 when the cycle has 19; the six hand-copied entries show as new though already triaged | as B1 |
| **C. A stamp written by ingest** | a new stamp line or file | a hand copy writes none (ad4f0eef); a second record of what the copy already holds (S3) | as B1 |
| **D. No change** | nothing | the owner looks per project | none |

Paths and policy for each (criterion 3). All of A, B1 and B2 change `scripts/board.sh`, `scripts/harness-feedback.py` (a read-only mode), their two bats files and the two guides; policy **review**, since `board.sh` is host code under H1 and `harness-feedback.py` reaches the host through `install.sh`'s `scripts/` payload. C adds the same plus a change to `ingest`'s write path and its tests (review). D changes nothing (no policy).

Path A: **B1** dominates. It answers the owner's question exactly ("new harness feedback to copy to this repo"), counts a hand copy and an ingest alike, and matches by the Project line, not the file name. Assumption, unverifiable from the sandbox: the renamed project's own main also says `Project: task-workspace-designer` (the rename in ad4f0eef was a hand edit of this repo's copy). If so it shows 0 not copied; if its file still says `philosophy-research`, no stored file has that name, and the "entries stored under another name" state below catches it.

"Copied" compares each entry's signature, not just its ID: `pending` reuses `ingest`'s `sig()` (ID, slug and meta line, `harness-feedback.py:339`), so an old entry edited in the project, which `ingest` refuses, is reported, never shown as "all copied". An edited bullet (the herald file's later "Recheck" lines, for example) is not in the signature; `pending` also compares each entry's whole text with the stored copy's and counts a changed one as `changed`, so revised feedback is listed too. B2 counts against the seeds, which a hand copy never writes and which the cycle does not need to notice a copy, so it would report triaged entries as new and send the owner to re-seed them. A is B1 with a worse lookup at the same parse cost. C adds state that hand copies bypass. D fails the motive.

How each state prints under B1 (one line, after the `main DATE · N open watches` line):

- project file absent on main: no line. The file is optional; a repo that never filed has nothing to copy. (Absent is modelled, not unreadable.)
- file present, every ID in its stored copy: `feedback: 13 entries, all copied`, so a run that read the file is distinguishable from one that did not (H2: nothing present-but-inert).
- some IDs not in the stored copy, or no stored copy: `feedback: 3 not copied (F-020 to F-022): cd CW && ~/.claude/scripts/harness-feedback.py ingest P/docs/harness-feedback.md`, with CW and P the registry paths. The installed copy, not CW's own script, so nothing from a checkout runs on the host; `ingest` finds its target from the current directory, so the installed copy does the same job.
- some entries changed text but kept their signature: `feedback: 2 changed (F-001, F-004)`, with the same command (`ingest` accepts that copy).
- an old entry's signature differs from the stored copy's: `feedback: F-003 differs from the stored copy; ingest would refuse it` and **no command**.
- the stored copy's file name is not `NAME.md` (the renamed project): the count as above, then `stored as docs/working/feedback/philosophy-research.md under another name; ingest would store it twice`, and **no command**, until the rename item below is decided.
- no stored file has this Project name, but one holds the same leading entries (same signatures) under another name: `feedback: entries stored under Project OTHER (docs/working/feedback/X.md); renamed?` and **no command**.
- file unreadable, not a regular file, or failing `check`: `feedback UNREADABLE: docs/harness-feedback.md: <first problem>`; counts toward exit 1, as an unreadable questions doc does. The problem text can echo the file's bytes (`check` quotes a bad verdict); the board's existing scrub covers that.
- two stored files with the same Project name, or a stored file failing `check` (whose Project line cannot be trusted, so it cannot be tied to one project): `feedback NOT COMPARED: <why>` on **every** project with a file, exit 1.
- no stored files at all: every project with a file counts all its entries as not copied (`pending` takes zero stored paths; the board expands the glob with `nullglob`).
- claude-workflows not registered: one footer line (choice 3); its feedback directory unreadable on main: `feedback NOT COMPARED: <why>` on each project with a file (exit 1).
- claude-workflows' own block: no feedback line (the guide says that repo keeps no such file).

## Design choice 2: where the parsing runs

Options: (a) bash/awk in `board.sh`; (b) a new read-only mode in `harness-feedback.py`, e.g. `pending FILE STORED...`, printing the project name, its entry count and the IDs missing from the stored copy with that Project name, or exiting 1 with the problems; (c) a new beside-the-board script.

Path A: (b). One parser for the grammar (S3), about 45 lines, and the board already requires `python3`. (a) restates the grammar in a second language; (c) adds a second script for it. The board calls `python3 -I "$HERE/harness-feedback.py" pending "$d/hf.md" "$TMP"/stored/*.md` on blobs it copied out of git objects. `-I` keeps `PYTHON*` variables, the current directory (each `repo()` runs with the repo as its current directory, `board.sh:121`) and the script's directory off `sys.path`; the script imports only the standard library. `harness-feedback.py` joins the files that must sit beside the board (exit 2 when missing). `pending` takes every path explicitly and runs no git, so `toplevel()` is never called on the host.

## Design choice 3: how the board knows which registered repo is claude-workflows

Options: (a) the registry line whose main holds both `guides/harness-feedback.md` (the marker `ingest` tests, `harness-feedback.py:320`) and `scripts/harness-feedback.py`; (b) the line whose last part is `claude-workflows`; (c) a marked registry line (new registry syntax).

Path A: (a). No new owner step or syntax (S10), and it survives a renamed checkout directory, which (b) does not. Zero matches: one footer line `feedback not compared: no registered repo holds the harness (guides/harness-feedback.md on main)`, exit unchanged, since registering claude-workflows is the owner's choice. Two or more: `feedback NOT COMPARED: N registered repos hold the harness` and exit 1 (an ambiguity the board does not model, H2). It needs a pre-pass over the registry before the per-project loop, copying that repo's main `docs/working/feedback/*.md` blobs into `$TMP/stored/` once, each through `main_entry` (a symlink or non-file there is NOT COMPARED, not skipped).

Smaller choices (one line each):

- Exit code: an UNREADABLE feedback file counts as an unreadable project (exit 1), the same rule as the questions doc.
- The printed command names the checkout's working-tree file because `ingest` takes a path; the board itself reads only main. An uncommitted entry there is copied too, which is harmless (the file only grows, and `ingest` runs `check`).
- Ordering: the feedback line goes right after the `main DATE` line, before the open questions.

## The weekly digest on the board (criterion 4)

Facts: the dev-cycle skill's step 9 writes `docs/working/weekly/YYYY-MM-DD.md` once a week in every repo that runs the dev cycle, and lands it on main with the iteration's record (`isweekly`, `dev-cycle-read.sh:231`). This repo has four editions (2026-10-30 to 2026-11-20). The owner's T11 note says the digest is worth reading but hard to find, and asked for it on the board.

Options: (a) for each repo whose main has `docs/working/weekly/`, print the latest edition's path and date; (b) as (a), but only when newer than the board's last run (from `~/.local/state/claude-board/runs.log`); (c) no change.

Path A: (a). (b) couples the listing to a log written for another purpose and hides an unread edition whenever the board ran for another reason; it can follow if (a) proves noisy. (c) leaves the owner's stated gap.

How it reads and fails: `main_entry` models files only (a directory, mode 040000, answers `notfile`, `dev-cycle-read.sh:384`), so it cannot be asked about the directory itself. Instead one `git ls-tree -t --full-tree "$MAIN_SHA" -- docs docs/working docs/working/weekly` decides the directory, as `main_entry` does for a file's parents (`--full-tree`, since the registry path can be a subdirectory of its repo): a duplicated name, or `docs` or `docs/working` present as anything but `040000`, is UNREADABLE; `docs/working/weekly` absent (with its parents trees or absent) prints no line; present as `040000` goes on; any other mode (a symlink, a file, a gitlink) or a failed `ls-tree` prints `weekly UNREADABLE: docs/working/weekly is not a directory on the default branch` (or the failed read), and every UNREADABLE counts toward exit 1. Then `git ls-tree --full-tree "$MAIN_SHA" -- docs/working/weekly/` lists the editions with their modes (not `--name-only`); the latest name of the `YYYY-MM-DD.md` form (`isweekly`'s) is checked with `main_entry` on its own path: `blob` prints, anything else prints `weekly UNREADABLE: <entry_why>` (never a fall-back to an older edition); a directory with no edition prints `weekly: none yet`. No blob is read, so no new trust surface. About 20 lines of bash and four bats cases (present, absent, a symlinked `weekly`, a real directory holding no edition).

Line: `   weekly: P/docs/working/weekly/2026-11-20.md (2026-11-20)`, after the feedback line. That path is the checkout's file, which matches main's when main is checked out (the common case, per the board guide). The guide should not suggest `git -C P show ...` for the other case, since that runs git unhardened in the repo on the host; it can say the edition reaches the checkout when that checkout next takes main.

Suggestion: build it in the same review unit as the feedback line (same file, tests and guide section).

## Cost of the suggested change

- `scripts/board.sh`: about 55 lines (pre-pass about 15, the feedback call about 15 with `pending` printing the finished line, the weekly read about 20, the beside-the-script check). 421 to about 475: under S8's 500, but with a margin of about 25 lines, so the builder keeps line formatting in `pending` and adds nothing to the 1230-line lib (also over 500).
- `scripts/harness-feedback.py`: about 45 lines (`pending`: signatures, entry text, the other-name match).
- Tests: about 10 cases in `test/scripts/board.bats` (not-copied count and command; all copied; absent file prints nothing; a file failing check is UNREADABLE with exit 1; a stored copy under another file name withholds the command; a signature that differs withholds it; a stored file failing check is NOT COMPARED everywhere; no harness repo registered; weekly present, absent, symlinked, empty), about 7 in `test/scripts/harness-feedback.bats` (`pending`: all copied, some new, a changed entry, a differing signature, entries under another name, zero stored files, two stored files with one Project name). Hermetic: fixture repos under `BATS_TEST_TMPDIR` and the existing network shims (H3).
- `guides/cross-project-board.md` and `guides/harness-feedback.md`: a few lines each.
- Policy: **review** (host code, H1). About 220 changed lines, one unit, one `git revert` (S8); no new image package; no new host chore (S10), since the board already runs on the host.

## Review record

Round 1 (one general-purpose reviewer, fact-check and design). The figures, file sizes, seed history, the 22-seed claim, `-I` and `install.sh` all checked out. Findings and what changed:

- High: the earlier draft said the six unseeded entries were invisible to the cycle; the cycle triaged them from the commit (aa91635c). Fixed: section "How feedback reaches this repo" and the motive rewritten; that claim was B2's tiebreaker, so choice 1 now picks B1.
- Medium, lag overstated by backdated herald Dates: recomputed with the preamble's filing dates (median 5, mean 5.5, max 18, 11 of 37 at 7 days or more).
- Medium, options lacked paths and policy: added for every option.
- Medium, H1, printed commands ran a checkout's script and unhardened git: the command names `~/.claude/scripts/harness-feedback.py`; the `git -C P show` guide line is dropped.
- Medium, H2, the renamed project's count and command: under B1 its count is 0; a stored copy under another file name withholds the command.
- Medium, H2, the weekly read had no failure states: it now goes through `main_entry` and reads modes.
- Low, the marker claim (ingest tests only the guide) and the "grammar-restricted" bound on the UNREADABLE line: both corrected.
- Low, main lag after a copy and the missing-questions-doc case: added under Gotchas.

Round 2 (same reviewer, on 3c522476): seven of the eight resolved; one new High and three new Mediums, plus one Low. Fixed:

- High, `main_entry` answers `notfile` for a directory, so the weekly read would print UNREADABLE in every repo that has one: the directory is now decided by `ls-tree` mode `040000`, with `main_entry` used only on the chosen edition.
- Medium, the renamed project's "0 not copied" rests on its own main's Project line: stated as an assumption, and a "stored under another name" state added.
- Medium, ID sets miss edited entries and copies `ingest` would refuse: `pending` compares `sig()` and entry text; new `changed` and `differs` states, the latter withholding the command.
- Medium, scope of a stored file failing check: NOT COMPARED on every project.
- Low, an empty glob: `nullglob`, zero stored paths allowed.

Round 3 (same reviewer, on 39de5cdd): the five round-2 fixes held; one Medium and three Lows. Fixed: the weekly directory check now uses `ls-tree -t --full-tree` over `docs`, `docs/working` and `docs/working/weekly` with main_entry's parent rules; a latest edition that is not a blob is UNREADABLE; board.sh's cost recounted (about 55 lines, 25 under S8's 500); the dev-cycle goal line names the changed and differs states and when the command is withheld.

Round 4 (on 9cac63dd): clean.

## For the dev cycle

Suggested review brief: **the board lists harness feedback not yet copied, and the latest weekly digest**.

- Goal: in `scripts/board.sh`'s listing, after each project's `main DATE` line, print (1) how many of the project's main `docs/harness-feedback.md` entries are missing from, or changed against, the stored copy on claude-workflows' main that has the same Project line, with the first and last ID and the `~/.claude/scripts/harness-feedback.py ingest` command; withhold the command when an entry's signature differs (ingest would refuse) or the entries are stored under another name or file name; and (2) the latest `docs/working/weekly/YYYY-MM-DD.md` on main with its date. Design: this doc, choices 1 to 3 and the weekly section.
- Paths: `scripts/board.sh`, `scripts/harness-feedback.py`, `test/scripts/board.bats`, `test/scripts/harness-feedback.bats`, `guides/cross-project-board.md`, `guides/harness-feedback.md`.
- Tests: the board and harness-feedback bats files with the cases listed under Cost; `scripts/hermeticity-lint --root .`.
- Policy: review (host code, H1).

Separately, two items for the cycle to triage (not part of that brief):

1. **Leave the six ad4f0eef entries unseeded**, or seed them knowing they are already triaged (aa91635c): `ingest` on `behemoth-arsenal.md` and `belegarth-herald.md` in place would add 2 and 1 seeds that the next brainstorm counts again. Never run it on `philosophy-research.md` before item 2 is decided (22 seeds, 19 duplicated).
2. **`ingest` re-seeds and re-stores a renamed project.** Its skip test and its target file both key on the Project line, so a renamed project (task-workspace-designer, formerly philosophy-research, renamed by hand in ad4f0eef) gets every old entry seeded again and, from the project's own file, a second stored copy. Options for that item's research: match a renamed copy to the stored one by its entries (same IDs, slugs and meta lines) and keep the old name, refuse a copy whose entries are already stored under another name, or document that a rename means renaming the stored file and its seeds by hand.
