# Plan: roadmap staleness checks

**Goal**: Every iteration sees which roadmap Now and Next items no open questions-file entry holds, and moves or explains each one.
**Project state**: fixes the roadmap-staleness gaps found 2026-11-18 · standalone · not blocked (cite: docs/working/research-2026-11-18-roadmap-staleness.md)
**Task status**: complete (the output shape in step 1 changed in review: verdict first, then the quoted title; R5 and A11 split off)
Research: `docs/working/research-2026-11-18-roadmap-staleness.md`

## Approach

The digest's section 5 gains a per-item list for Now and Next: each item's title and the IDs it names that are open (with route), or a flag when none is open. The skill's step 6, which runs on every iteration, reads that list and moves each flagged item (finished: Done; stopped by an owner answer: Ideas) or names what holds it. Step 8's free-slot reasons point at the same list. No `--cycle-diff` change: the `8.` line is prose with no stable item IDs (research, Gotchas), so the check lives in the digest, where it can be read on every iteration.

## Steps

1. `scripts/dev-cycle.sh` section 5: after the quoted Next, print `Now and Next items, with the open entries or watches each names:` and one line per column-0 item of Now and Next: `- Now N · TITLE: open Q-NNN (route), …` or `- Now N · TITLE: no open entry or watch names it`. TITLE is the item's first bold span, else its first 80 characters. When section 3 did not read the open list, print one line saying the list was not checked. Tests in `test/scripts/dev-cycle.bats`.
2. `skills/dev-cycle/SKILL.md`: step 0's section map (5 feeds steps 6 and 8); step 6's rule for flagged items, Done lines that complete part of an item, and Ideas taking parked items; step 8's free-slot reason uses the list; the record template's `6.` line says what moved; step 3's agent-item sentence notes that step 6 covers every Now item.

## Size estimate

About 40 lines of script, 60 of tests, 20 of skill text.

Estimated context cost: research small, implementation small, review medium.
Actual context cost (post-implementation): research small, implementation small, review medium.

## Test specification

- T1: a Now item naming only answered IDs is flagged "no open entry or watch names it"; a Now item naming an open watch lists it with its route; a Next numbered item is listed as `Next 1`; indented sub-steps are not items.
- T2: section 3's failure (no archive) prints the not-checked line in section 5, never a flag per item.
- T3: no roadmap: section 5 prints as before (no list).

(Test-strategy: the gaps are the three above; the change is a read-only print with one failure branch.)

## Risks

- A title holding repo text reaches the digest: the output scrub covers it (research, Invariants).
- An item that is legitimately held by a date (a trial) is flagged every iteration: intended. Step 6 then names the date on the `6.` line, which is the per-item hold step 8 asked for.

### Failure modes considered

- `/pre-mortem`: not triggered (no enforcement file, no trust boundary beyond the scrubbed print).
- `/architecture-review`: not triggered (one script and one skill; no module boundary).

## Rollback

Revert this branch's merge: the digest loses the list and the skill its rules; no state, file format or other script depends on either.
