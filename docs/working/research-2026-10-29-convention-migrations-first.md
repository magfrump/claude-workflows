# Research: convention changes ship migrations the dev cycle runs first

Brief: `docs/working/briefs/2026-10-29-convention-migrations-first.md` (at 0784fc8e).
Branch: `feat/convention-migrations-first`. Mode: build loop, no plan gate. Policy: review.
Motive: owner feedback 2026-10-29, second point (format changes reach other repos only as
a red `check` or a misread digest).

## What exists

- Convention sources: `scripts/questions.sh` (entry grammar header, `ROUTES`, the files
  `init` writes); `skills/dev-cycle/SKILL.md` step 6 (roadmap template), step 8 (a brief's
  lines), step 9 (record template). All of them are GATE_CODE, so any change to them already
  goes through review, never self-merge.
- Other repos run the installed copy: the root-owned image (`git archive HEAD`, which
  carries `scripts/lib/` but none of `docs/`) and `~/.claude`. They do not have this repo's
  history or `docs/`.
- The digest (`dev-cycle.sh`, run through D6 from the image) reads the repo's files every
  iteration and sources its reader lib from its own directory, whose chain D6 checks is
  root-owned and unwritable.
- Step 9's `--cycle-diff` refuses a changed or removed questions entry without an owner
  answer, and any change to the roadmap's preamble or `## ` lines. Build loops never write
  the questions files (D11).
- Unit 2 (`feat/questions-watching-file`, still in review; tip ef1022d7 when read, moving)
  adds `questions.sh migrate` and has `check` warn, not fail, on old-route entries opened
  before 2026-10-30. Its migration is an owner command (its research doc, "This repo's
  `questions.md` migration: one owner command").

## Divergent design (seeds: H1-H4, S1-S11, and the brief's own: before collect and briefs,
## landing under `--cycle-diff`, call unit 2's `migrate` rather than duplicate it)

### Where a migration is declared

1. **A registry in a gate-code lib** (`scripts/lib/migrations.sh`): one `mig` line per
   change, with the convention's fingerprint after it, a file and pattern only the old
   shape matches, and the remedy command.
2. **A trailer in the changing commit** (`Migration: ...`), read from main's log.
3. **A version header in each file** (`<!-- convention: questions v2 -->`).
4. **A prose doc** (`docs/migrations.md`).
5. **No registry; each convention's checker warns with its remedy** (unit 2's pattern).

| # | Fails | Notes |
|---|---|---|
| 1 | — | ships in the image to every repo; data in gate code, so no repo text picks what runs (H1); testable (S4, H3) |
| 2 | S5, portability | other repos have no copy of this repo's history: the main audience never sees it |
| 3 | `--cycle-diff` (roadmap preamble is frozen), S3, S10 | every reader must skip the marker; writing it is itself a migration; a marker can disagree with the content |
| 4 | S4, portability | the image carries no `docs/`; prose does not run |
| 5 | S3, scope | only `questions` has a checker; roadmap, brief and record have none; nothing for a merge check to key on |

**Pick: 1 (Path A).**

### How a repo is found to be behind

Shape detection (the registry's ERE matched against the repo's file) over a version marker
(rejected with 3 above): it needs no write to declare a repo current, cannot disagree with
the content, and is the same test every repo runs. Residual: the ERE must match only the
old shape; the author writes it next to the remedy that removes that shape.

### How it lands (the brief's question)

1. **Owner paste**: the cycle files one `you: terminal` entry per pending migration, with
   the remedy as the paste, and goes on.
2. **The cycle applies it in WT and lands it in its chore commit.**
3. **A build brief per migration.**
4. **Hold briefs and dispatch until migrated** (a stop on the owner).
5. **Teach `--cycle-diff` to accept exactly what `migrate` produces from BASE.**

| # | Fails | Notes |
|---|---|---|
| 1 | — | the owner route for a machine chore; `questions.md` stays owner-only (decision 040) |
| 2 | `--cycle-diff` | a migration's whole job is to change entries or headings the chore commit may not touch |
| 3 | D11 | a loop may not write the questions files either |
| 4 | S10, memory "no new human stops in dev-cycle" | every loop would wait on a chore; a fail-closed alternative (1) exists |
| 5 | S8, scope | gate code in the 2300-line `build-loop.sh`; unit 2 rejected the same (its candidate 5) |

**Pick: 1 (Path A).** "Higher priority than continuing existing work" is met by order, not
by a hold: step 1b runs before triggers, collect, briefs and dispatch, files the entry, and
the final message lists pending migrations first. A hold (4) is the only stronger form, and
it fails S10. If the owner wants the hold anyway, that is a one-paragraph change to step 1b.

### Can a convention change merge without its migration line (the merge check)

1. **Fingerprint**: hash each convention's source; the newest registry line for it must
   carry the current hash, so a source change fails the bats suite (and the health check)
   until a line is added (a migration, or `none: WHY`).
2. **Fixture behaviour**: old-shape fixtures must pass the checker or have a migration.
3. **Branch diff**: a branch touching a source must touch the registry.
4. **No check, docs only.**

| # | Fails | Notes |
|---|---|---|
| 1 | — | mechanical (H4); wording-only edits cost an author one `none:` line (S1: friction on a reviewed path only, since every source is GATE_CODE) |
| 2 | scope | only `questions` has a checker; a reader-only break passes it |
| 3 | H3-ish | needs a merge base; invisible to the health check on main |
| 4 | S4, motive | prose did not run: the reason the owner asked |

**Pick: 1 (Path A).** Fingerprint sources: `questions.sh`'s "Entry grammar" header block
(from `# Entry grammar` to `# Usage:`, which holds the routes paragraph) plus every file
`questions.sh init` writes in an empty repo; SKILL.md step 6's and step 9's `markdown`
fences; step 8's paragraph from "For each, write `docs/working/briefs/" to "line a loop's
merge changes." A source whose anchor is gone fails loudly (H2), naming the convention.

## Other choices (dominant, no DD needed)

- **Registry as `mig` calls**, not a delimited table: EREs hold `|`, and bash quoting is
  the parser. A malformed line goes to `MIG_BAD`; the digest then checks nothing and says
  so (H2), and the merge check refuses it.
- **Lib, not a new script**: `scripts/lib/` is already GATE_CODE (H1's success line needs no
  change), the image ships it, and D6 already checks its directory chain. No new D6 script
  and no change to the D6 block. A copy without the lib (an image older than this change)
  prints "Migrations were NOT checked", not "none".
- **Digest section 7b**, not 9: it reads repo files, so a skipped path must reach section
  8's list, which therefore stays last; the `b` keeps every "section 8" reference valid.
- **Only the line number is printed**, never the matched text (repo text in the digest is
  kept to what a step needs).
- **One entry per migration** (slug `migrate-ID`), deduplicated by an open entry with that
  slug; several in one iteration share one paste (the global rule for terminal entries).
- **Unit 2 coordination (S3)**: this unit writes no `migrate` and no line for unit 2,
  because its code is still moving (its fingerprint changed between two reads of its
  branch today) and a pending line would hand the owner a command main does not have yet.
  Whichever of the two merges second fails the merge check after merging main in; the fix
  is the line it prints, for unit 2:
  `mig questions-owner-routes-040 questions FP docs/working/questions.md '^\*\*Needs:\*\* (agent|trigger|deferred)( |$)' '~/.claude/scripts/questions.sh migrate'`
  with FP from `bash scripts/lib/migrations.sh fingerprint` on the merged tree.
- **Coverage limit**: the readers in `build-loop.sh` and `dev-cycle-read.sh` (`Status:`,
  `Asked:`, `Main at:` parsing) are not fingerprinted; the guide tells an author changing
  one to change the matching SKILL.md source too. Fingerprinting those files would put a
  registry line on most gate commits (S1).

## Pre-mortem (this changes gate code: the digest and the skill)

Bypass and failure families: (a) a convention changed only in a reader, not its source:
the coverage limit above, documented; (b) a wrong ERE that never matches: reported "none"
forever: the author tests it against an old file; a bats fixture for a real migration is
the reviewer's ask; (c) the remedy command missing on main: the guide requires it in the
same change; (d) parallel branches: the second fails the check after merging main, by
design; (e) an image older than the skill: section 7b says NOT checked, step 1b records it.

## Review (round 1) and what it changed

A review subagent found no high findings. Fixed: rewriting the newest registry line's FP
passed the check (now the bats merge check holds the registry append-only against the
default branch's copy, `conv_append_only`); an open `migrate-ID` entry had no closing path
once the migration ran (step 1b now reports it for the owner to answer); an unparseable
registry stopped the whole digest (now `bash -n` first, "does not parse"); section 7b said
"None" with no migration to check (now its own message); `.git` paths were accepted in
PATH; the source extractions ran to end of file on a lost anchor (now each needs its end
marker, and step 8's stops at the next heading). Tests added for each. The first commit's
message says "one `you: terminal` entry"; it is one per migration, sharing one paste.

## Files

- `scripts/lib/migrations.sh` (new): registry, `mig`, `conv_source`, `conv_fingerprint`,
  `conv_check`; `check` / `fingerprint` when run directly.
- `scripts/dev-cycle.sh`: section 7b.
- `skills/dev-cycle/SKILL.md`: flow line, step 0.4's section list, step 1b, record `1b.`
  line, final message order.
- `guides/convention-changes.md` (new) and `guides/README.md`: the author's doc.
- `test/scripts/convention-migrations.bats` (new, 10 cases); `test/scripts/dev-cycle.bats`
  (section list).
