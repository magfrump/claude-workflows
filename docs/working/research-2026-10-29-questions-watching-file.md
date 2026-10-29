# Research: questions doc owner-only, unit 2 (watching.md and migrate)

Brief: `docs/working/briefs/2026-10-29-questions-watching-file.md` (at 93aa71e6).
Branch: `feat/questions-watching-file`. Mode: build loop, no plan gate.
Design source: decision 040; unit 1's research
(`docs/working/research-2026-10-28-questions-owner-routes.md`, "Pick: 2").

## What exists

- `scripts/questions.sh` (498 lines) has one route list, `ROUTES`, with a parallel
  `ROUTE_MEANING`; `check`, the sort rank and `init`'s route table read them. The first
  four routes are the owner's (`you: ...`).
- `check` validates `questions.md` and `questions-archive.md`; `scripts/health-check.sh`
  section 14 runs it as a gate, pinning `QUESTIONS_LIVE`/`QUESTIONS_ARCHIVE` to the repo.
- `scripts/dev-cycle.sh` section 3 reads `questions.sh open` (live file only) for watched
  entries. Changing that is unit 3.
- The skill's D6 block runs `questions.sh` from a copy of main's `scripts/`, copying
  `questions.sh` and `lib/dev-cycle-read.sh` only, so `questions.sh` must stay one file:
  a new lib it sources would be missing from that copy.
- This repo's `questions.md` holds 7 `agent`, 2 `deferred` and 2 `trigger` entries, all
  opened before 2026-10-30. Build loops may not write it, and `--cycle-diff` refuses a
  removed entry without an owner answer, so neither this loop nor the cycle's chore commit
  can migrate it.

## Divergent design: how the refusal and this repo's migration meet

Seeds: repo H1 (a gate's switch is not agent-writable state), H2 (fail closed and loudly,
a refusal names a way forward, degradation only narrows), H3, S1 (honest slips, not a
hostile loop), S3, S8, S10 (no merge waiting on a manual owner act when a fail-closed
alternative exists; no safety that depends on a remembered flag); decision 040's H5a
(the refusal names a home that exists) and H5b (an owner file with old routes is told how
to migrate). Brief: `health-check.sh` passes on the branch and does not go red on main at
the merge; this loop does not write the questions files.

Candidates:

1. **Unconditional refusal, owner pastes `migrate` with the merge.**
2. **Cutoff date in the code.** A non-owner entry in `questions.md` opened before a fixed
   date (`LEGACY_BEFORE`, 2026-10-30) is reported with ⚠, naming its home and `migrate`,
   and does not fail `check`; one opened on or after it is refused (✗). The owner's one
   `migrate` run clears the warnings whenever it suits.
3. **Switch on `watching.md` existing** (unit 1's candidate 5).
4. **Switch in non-agent-writable state** (an env var or file in the root-owned image
   payload or on the host).
5. **Teach `--cycle-diff` a lossless move**, so the dev cycle's chore commit can run
   `migrate` itself.
6. **Grandfather by an ID list or highest ID** (unit 1's candidate 6, by ID).
7. **Warn only** in this unit, refuse in unit 3.

| # | Fails | Notes |
|---|---|---|
| 1 | brief (health check red on the branch and at the merge), S10 | main stays red until the owner acts; the merge gate itself refuses |
| 2 | — | refusal active for every new misfiling from the merge on; old entries are loud, not silent; no flag, no switch file. Backdating `Opened:` evades it, a hostile act S1 does not defend against |
| 3 | H1, H2 | an agent-writable file's presence switches the gate; deleting it widens access |
| 4 | S10, S8 | a new image or host setting and a release before the refusal can turn on; a flag in all but name |
| 5 | brief scope, S8 | gate code in `build-loop.sh`; agent entries have no file the move can be checked against; main is still red between the merge and the next cycle |
| 6 | S3, portability | a third list (IDs), meaningless in other projects that run the installed copy |
| 7 | H2 | present-but-inert: unit 1 pruned it, and nothing would refuse until unit 3 |

**Pick: 2 (Path A).** The only candidate with no hard or brief failure. Its cost: the
legacy warnings persist in this repo until the owner runs `migrate` once (one command, at
a time of their choosing; nothing blocks on it). A legacy entry is moved without loss, so
the warning's remedy is the same command a new misfiling gets. The cutoff is a constant,
not state: the same rule holds in every project that runs the installed copy.

Residual risk (S1): a session that backdates `Opened:` gets the ⚠ instead of ✗. An honest
session writes today's date, which is all the gate is meant to catch.

Version skew: until unit 3 the global instructions still tell sessions to file
`trigger`/`deferred`/`agent` entries in `questions.md`. From this merge such an entry is
refused by `check`, with its home and `migrate` named, so the session that filed it has a
way forward (H2). Unit 1 accepted the same skew for this unit.

## Other choices (each one dominant, no DD needed)

- **The owner subset of `ROUTES`.** A parallel `ROUTE_HOME` array, like `ROUTE_MEANING`:
  empty for the four owner routes, `docs/roadmap.md` for `agent`,
  `docs/working/watching.md` (`WATCH_HOME`) for `deferred` and `trigger`. The refusal,
  `migrate`, the watching file's own route check and both route tables read it; no route
  name is repeated (S3). The live file's route table now lists the four owner routes and
  names the other three with their homes on one line.
- **Review-unit size.** The unit is about 400 changed code lines (row 62's cap), so
  comments and tests were kept tight; no further scope fits in it.
- **Where `watching.md` resolves.** `QUESTIONS_WATCHING`, else beside the live file. So
  `health-check.sh`, which pins `QUESTIONS_LIVE`, and the test suites, which override it
  too, get the right file without a change.
- **A missing `watching.md` reads as empty.** Every project that runs the installed copy
  has none yet; requiring it would break `open` (and the dev cycle's section 3) in each one
  until `init`. Nothing goes unenforced: with no file there is no entry to check, and
  `next-id` has no IDs to miss. `init` creates it; `migrate` creates it when it has a watch
  to write.
- **The watching file's layout.** Title, a preamble with the two watch routes' table,
  `## Index` with the same markers, `## Open`, `## Closed`. `check` applies the same entry
  grammar, refuses a non-watch route there, an OPEN entry under `## Closed` and an ANSWERED
  one above it. IDs are unique across all three files, and `next-id` reads all three. A
  closed watch keeps the ANSWERED status (same grammar; `--check-answer`-style readers
  key on it).
- **Agent entries' destination.** The roadmap is the dev cycle's file and its layout is not
  `questions.sh`'s to know, so `migrate` writes agent entries verbatim to
  `docs/working/roadmap-from-questions.md` (appending, created when needed) and prints that
  the roadmap's owner should fold them in and delete the file. Printing to stdout only
  would lose the text on an uncaptured run.
- **Write order.** Destinations first, then the live file, as `archive` does: an
  interrupted run duplicates an entry, which `check` reports, rather than losing one.
- **Idempotence.** A second run finds no non-owner entry and changes nothing.
- **Size (S8).** `questions.sh` grows past 500 lines. It cannot split (D6 copies one
  file), and S8 names `cc-isolated.sh` and `install.sh` as the files not to grow; the
  additions are kept to the new modes.

## Left for later units (not changed here)

- `global-instructions/CLAUDE.md` lists `init`/`index`/`archive`/`check` and still routes
  watches to `questions.md`; unit 3 (out of this brief's scope). It is the one doc besides
  `questions.sh`'s own header that lists the modes, so the brief's "every doc that lists
  its modes" criterion is met everywhere except there.
- The dev cycle runs `questions.sh init` each iteration (`skills/dev-cycle/SKILL.md`), so
  after this merges the cycle creates this repo's `docs/working/watching.md` (header only)
  on its next pass; nothing else changes until `migrate` runs.
- `dev-cycle.sh` section 3 reads only `questions.md`: once the owner runs `migrate`, the
  watches leave the digest until unit 3 reads `watching.md`. Running `migrate` with or
  after unit 3 avoids the gap.
- This repo's `questions.md` migration: one owner command,
  `scripts/questions.sh migrate` on main, then commit the four files.

## Tests (`test/questions-doc.bats`)

- `init` creates `watching.md` with markers, `## Open` and `## Closed`; never clobbers.
- `check` on `watching.md`: a closed watch under `## Closed` passes; an OPEN one there, an
  ANSWERED one above it, and an owner route in it each fail; a stale index fails;
  a duplicate ID across files fails.
- Refusal: one case per route (`agent`, `deferred`, `trigger`) opened on the cutoff, each
  naming its home and `migrate`; the same entry before the cutoff warns and passes.
- `migrate` round-trips a fixture with every route and both statuses, comparing every
  entry's text before and after; a second run changes no file; `check` passes after.
- `next-id` counts IDs in `watching.md`.
