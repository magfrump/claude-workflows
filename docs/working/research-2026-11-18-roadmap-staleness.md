# Research: why the roadmap's Now went stale

**Goal**: Close the dev-cycle gaps that let finished and parked items sit in roadmap Now for weeks, so every iteration, light passes included, sees which Now and Next items no open questions-file entry holds.
**Problem framing**: Nothing in the cycle connects a roadmap item to the state of the entries it names, and Now is never shown to the orchestrator, so an item whose hold was answered keeps reading as held. Considered and discarded: "the orchestrator was careless", since the same blanket `8.` line passed for about 109 iterations from 2026-11-01, a process gap and not a single slip.
**Project state**: fixes the roadmap-staleness gaps the owner asked for in session on 2026-11-18 · standalone · not blocked (cite: a81ddd8f)
**Task status**: complete (implemented on fix/dev-cycle-roadmap-staleness)

## What exists

- `scripts/dev-cycle.sh` section 5 prints only the roadmap's Next section, quoted (`awk` at the `## 5. Roadmap` block) [observed]. Section 7 counts items in Now, In flight and Next and compares Now with the last brainstorm's commit (`now_of`) [observed]. Now's text itself is never printed.
- Section 3 runs `questions.sh open` with the three questions paths pinned (`qopen`), keeping its output in `open_q`: one line per live-file entry of any status, plus each watch not marked ANSWERED, `ID  ROUTE  slug` [observed: `scripts/questions.sh` `cmd_open`]. So an entry marked ANSWERED but not archived yet is still on it; section 5 drops those itself (review 2026-11-18, claim 11b).
- `skills/dev-cycle/SKILL.md`:
  - Step 3 checks staleness for "Now's agent work items" only [observed]. A light pass skips step 3 (step 0.5) [observed].
  - Step 6 closes In flight items through `--check-brief`. It has no rule for a Now or Next item that is finished or parked, and none for a Done line that records part of a Now item [observed].
  - Step 8 already says a free slot's reason names "each held item and its hold, not a category", and that "an owner call holds an item only when a questions-file entry asks it" [observed]. Nothing checks either.

## Invariants

- The digest is read-only and every section prints even when one input is skipped or fails. Section 3's failure prints "Watched questions were NOT checked" [observed: tests "a questions.sh failure is reported…", "section 3 lists watches…"].
- The output goes through `scrub_reexec`, so repo text printed by a new section is scrubbed like the rest [observed: `scripts/dev-cycle.sh:102`].
- Section headings and their order are pinned by `test/scripts/dev-cycle.bats` ("prints all eight sections"), and the skill's step 0 names which step reads each section [observed]. A new section number would need both changed; adding lines inside section 5 needs neither.
- `skills/dev-cycle/` and `scripts/dev-cycle.sh` are gate code (GATE_CODE in the lib), so this lands through review and runs from the next image release [observed: SKILL.md step 0.1's PATHS].
- `--cycle-diff` holds the roadmap's preamble and `## ` headings fixed, and keeps a brief path named outside Done [observed: SKILL.md step 6, row 751]. Moving an item from Now to Ideas or Done is allowed.

## Prior art

- Section 3's `open_q` already gives open entries and watches with routes; reusing it avoids a second parse of the questions files [observed].
- Section 7's heading rule (case-insensitive, `## now`, `## now (…)`) is the one to reuse for finding Now and Next [observed].

## Gotchas

- Failure-pattern grep: no matches found
- Every item names old answered IDs in its history ("Unit 1 merged at 236f21ee (Q-224 [1])"), so "names an answered ID" would flag every item. The signal is an item with **no open** ID: nothing in the questions files holds it [observed: the roadmap at 686258b1].
- Next items are numbered (`1. **…**`) and Now items are bullets (`- **…**`), with indented numbered sub-steps inside items that are not items [observed]. An item starts only at column 0.
- When section 3 could not read the questions files, `open_q` may still hold the first `qopen` call's full list (the first call succeeded, the second failed), so section 5 gates on `open_ok`, set only when both succeed, and says the list was not checked instead of reporting every item as unheld [observed: review 2026-11-18, claim 8].
- The `--cycle-diff` refusal for a blanket `8.` line, proposed in session, is not mechanical: the record's `8.` line is prose, Now has no item IDs, and an iteration edits Now before writing the line, so a check would match titles against a moving list. The digest's per-item list makes the blanket line visibly false instead, and step 8 is told to use it [inferred]. The plan records this change of approach.

## Files read

Last verified: 2026-11-18
scripts/dev-cycle.sh
skills/dev-cycle/SKILL.md
test/scripts/dev-cycle.bats
docs/roadmap.md
docs/working/cycles/cycle-2026-11-18.md
docs/failure-patterns.md
