# Research: questions doc owner-only, unit 1 (owner routes in questions.sh)

Brief: `docs/working/briefs/2026-10-28-questions-owner-routes.md` (at 4b04a1eb).
Branch: `feat/questions-owner-routes`. Mode: build loop, no plan gate.
Design source: decision 040 and `docs/working/dd-questions-doc-purposes.md`.

## What exists

- `scripts/questions.sh` holds the route list twice: `VALID_ROUTES` (used by `check`
  and its error message) and `route_rank`'s awk table (the sort order for `index` and
  `open`), with a "keep in step" comment between them. Its usage comment lists the five
  routes a third time. `init` writes a bare header (title, `## Index`, markers, section)
  with no route table; the route table in this repo's `questions.md` was written by hand.
- `parse_entries` and `archive` are route-agnostic: `archive` moves any entry whose
  Status is ANSWERED.
- `open` prints `ID  route  slug` with the route padded to 14 columns.
  `scripts/dev-cycle.sh` section 3 splits that output on two or more spaces
  (`awk -F'  +'`), keeps `trigger`/`deferred` as watched and counts every route in
  "Open by route". `you: walkthrough` (16 characters) overflows the 14-column pad but
  still leaves the two-space separator, so the split holds; widening to 16 keeps the
  columns aligned.
- `--check-answer` (`check_answer`/`ANSWER_AWK`, `scripts/lib/dev-cycle-read.sh`),
  `--cycle-diff` (`QKEYS_AWK`/`QDIFF_AWK`, `scripts/build-loop.sh`) and `--main-log`'s
  answers class (`ANSWERS_AWK`) never read the route. They key on the heading, the
  `**Needs:**` line as a whole, the Status field and the answer labels (`Q-NNN:` at line
  start after an optional `- `, or a bold `**Answer:`/`**Answer (`/`**Answered`).

## How the fyi answer forms read today (no gate change needed)

`you: fyi` is answered `seen`. The owner may batch acknowledgements in free text
(`Q-230–Q-235: seen`, decision 040); an agent session transcribes them into the entries
(DD H2). The forms, as each reader sees them:

| Form in the entry | `--check-answer` | `--cycle-diff` | `--main-log` |
|---|---|---|---|
| `Q-NNN: seen` + Status ANSWERED | `unrecognized` (not an option) | refused unless `--answered Q-NNN` | answers |
| `**Answer:** seen` + Status ANSWERED | `unrecognized` | refused unless `--answered Q-NNN` | answers |
| `Q-230–Q-235: seen` (range line) | not an answer line | refused (the Status flip) unless `--answered` | other |

- `unrecognized` is right for an fyi: `--check-answer` serves keep-or-drop-or-done
  questions a brief names and merge approvals (`approval()` accepts only `keep`), and an
  fyi is neither. An fyi named in a brief's `Asked:` or as a merge approval would be a
  filing error, and `unrecognized` refuses it (fail closed).
- `--cycle-diff` refusing an unlisted ack is the anti-forgery rule working as designed:
  the recorder passes `--answered` for the IDs the owner acknowledged.
- The range line is not an answer label in any reader, and `--main-log` reads a commit
  adding one as `other`. So a batch is transcribed one `Q-NNN: seen` line per entry. That
  is the recorder's step, not a gate change: widening three awk programs to a range form
  would touch gate code for no reader that needs it. Tests pin every cell of the table
(`test/scripts/dev-cycle.bats` for `--check-answer`, `test/scripts/build-loop-orchestrator.bats`
for the other two).

## Divergent design: when the refusal of agent/trigger/deferred ships

Constraint seeds: repo H1 (gate logic not sourced from agent-writable state), H2 (fail
closed and loudly; a refusal names a way forward; degradation only narrows), H3
(hermetic tests), S1, S3, S6 (a call site something runs), S8 (small units), S10 (no
safety that depends on remembering a flag); decision 040's DD constraints H5a (a refusal
names a home that exists, never drops the item) and H5b (an owner file with old routes is
told how to migrate). Brief: `questions.sh check` exits 0 on the repo's files at the
merge, and this loop may not write the questions files.

Facts that bound it: today's `questions.md` holds 11 `agent`, 2 `deferred` and 2
`trigger` entries. `docs/working/watching.md` does not exist (unit 2 creates it), so a
refusal now would name a home that is not there for watches. `questions.sh` is installed
as `~/.claude/scripts/questions.sh` and runs in every project; the global instructions
(unit 3) still tell sessions to file `agent`/`trigger`/`deferred` entries.

Candidates:

1. **Off by default until unit 2** (an opt-in flag or env var turns the refusal on).
2. **Ships in unit 2**, with `watching.md` and `migrate`, as one switch.
3. **Ships here with a migration** (fold unit 2's `migrate` in and run it).
4. **Warn now, refuse in unit 2** (a ⚠ line, exit 0, flipped to ✗ later).
5. **Active only where `docs/working/watching.md` exists** (the home's presence turns it on).
6. **Grandfather existing entries** (refuse only entries opened after the merge, or IDs
   above today's highest).

| # | Fails | Notes |
|---|---|---|
| 1 | S6, S10 | no call site passes the flag until unit 2; a check that depends on a flag being remembered |
| 2 | — | refusal lands with the home it names and the `migrate` remedy (H5a, H5b); this unit stays small (S8) |
| 3 | brief scope, dispatch rule | needs unit 2's code here and a rewrite of the questions files, which this loop may not write; size (S8) |
| 4 | H2 (present-but-inert), H5a | a warning that names `watching.md` before it exists; still needs a later flip |
| 5 | H1, H2 | an agent-writable file's presence is the gate's switch, and deleting it loosens the check: degradation that widens |
| 6 | H5a, H2 | refuses a new trigger with no home to send it to; sessions following today's global instructions are refused (version skew) |

**Pick: 2 (Path A).** It is the only candidate with no hard-constraint failure. Its cost
is that this unit's Goal sentence about the refusal moves to unit 2; the brief allows that
pick. Consequences for unit 2: the refusal ships unconditionally there, together with
`watching.md` (`init` creates it) and `migrate`; its message names the home per route
(`docs/working/watching.md` for `trigger`/`deferred`, `docs/roadmap.md` for `agent`) and
the `migrate` command (H5b), and this repo's own migration runs in the same landing so
`check` stays green.

What this unit does instead, toward the refusal: the route list becomes one list in
`questions.sh` (`ROUTES`, S3), whose first four entries are the owner routes. There is no
owner flag yet; the three agent routes are marked only in the route table's prose ("Due to
move out of this file"). Unit 2 adds the flag (or an owner-route subset of `ROUTES`) that
its refusal reads, so the refusal still needs no third copy of the list.

## Other choices (each one dominant, no DD needed)

- **Sort rank.** `index`/`open` sort by how much of the owner each route costs:
  judgment, walkthrough, terminal, fyi, then agent, deferred, trigger. Walkthrough ranks
  above terminal because it takes the owner's time and attention, where a terminal entry
  is one batched paste; fyi is the cheapest owner ask. The relative order of the five
  existing routes is unchanged, so the existing order tests hold.
- **The route table text.** `init` now writes the route table above `## Index` for new
  repos, generated from the same list `check` validates against. This repo's
  `questions.md` header is a questions file this loop may not write; the dev cycle (or
  unit 2's `migrate`, which rewrites the file anyway) updates it. Listed below.
- **`open` column width** 14 → 16, so `you: walkthrough` aligns; the separator stays two
  or more spaces, which is what `dev-cycle.sh` splits on.

## Left for later units (not changed here)

- `docs/working/questions.md`'s hand-written route table (header above `## Index`):
  still lists five routes. Unit 2 (`migrate`) or the dev cycle.
- `global-instructions/CLAUDE.md` "Route, don't rank" line, `AGENTS.md`/`GEMINI.md`,
  `skills/dev-cycle/SKILL.md` and `docs/dev-cycle.md`: they name `you: judgment` and
  `you: terminal` correctly and say nothing that this unit makes false; the new routes
  and the agent-state homes go in with unit 3.

## Tests

- `test/questions-doc.bats`: `check` accepts each of the four owner routes; the invalid
  route message lists them; `index` and `open` order all seven routes by rank; an fyi
  answered `seen` archives; `init` writes a route table whose every route `check` accepts.
- `test/scripts/dev-cycle.bats`: `--check-answer` on the fyi forms (table above), and
  section 3 counts the new routes without listing them as watched.
- `test/scripts/build-loop-orchestrator.bats`: `--cycle-diff` and `--main-log` on the fyi
  forms (table above).
