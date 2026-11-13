# Research: the dev cycle stops leaving ready work unbriefed

Brief: docs/working/briefs/2026-11-13-dev-cycle-unblock-ready-work.md (at 117c95f6).
Branch: feat/dev-cycle-unblock-ready-work. Policy: review (gate code, `skills/dev-cycle/`).

Failure-pattern grep: `rg -n -i 'symptom:[^ ]*(slot|brief|roadmap|idle|queue|hold|blocked)' docs/failure-patterns.md` and `rg -i 'copied forward|never expire|held|stale'`: no prior pattern for idle slots or expiring holds (nearest, FP-085 "instruction-drift", is about briefs read as licence, not this).
Failure-pattern skip: no fix(...) commits; this is a wording change to a procedure (feat), with no bug in code to record.

## What the code says now

- `skills/dev-cycle/SKILL.md` step 8 took only Now items; nothing pulled a ready Next item.
- Its free-slot clause asked for a reason per slot but its example was a category ("every
  other Now item waits on the user, a host run or a choice, say"), and iteration 1925's
  `8.` line copied that category forward (docs/working/cycles/cycle-2026-11-13.md:19).
- No rule expired a "rides with another unit" hold or split a host step from its code.
- The Rules' "Attention is the budget" already says only real choices become entries; it
  did not say a call left only in a final message holds nothing.
- Pinned wording: `test/scripts/build-loop-orchestrator.bats` (test at the old line 606)
  holds step 8's clause and the record template's `8.` line exactly.

## Change

- Step 8: Next fallback; "a hold is a choice only when an entry asks it", pointing at the
  Rules' rule rather than restating it; ride-along holds expire after two cycle records;
  host-step holds hold only the step; the `8.` clause names each held item and its hold.
- Step 7: a merged brief naming a host step gets one `you: terminal` entry (an existing
  route, no new entry type, no new stop: S10).
- Final message: may list a call, never hold one alone.
- Record template `8.` line: adds "each held item and its hold".
- Test: the template assertion updated; one new test pins the new clauses (the change is
  prose, so the test is a wording pin, like its neighbour).

## Design choices

- **What "held two cycles" counts** (3 options: iterations' `8.` lines, cycle records,
  days since the item's filed date). Path A: cycle records. The skill's own data model calls
  a day's record a cycle (`# Cycle YYYY-MM-DD`, iterations under it), the `8.` lines the
  change asks for make it re-checkable from the artifact, and it bounds the extra merge
  entries a too-fast expiry would cost the owner (iterations run minutes apart, so two
  iterations would expire a hold within the hour). Filed dates are not on every hold.
- Where the host step is filed: step 7 at merge (the only place a merge is seen); one line.
- Next item moves "leaves Next as it is briefed": step 8 already moves briefed items to In
  flight, so it does not pass through Now (the brief's "moves to Now" read as that).

## Docs that restate step 8 (for the cycle; not edited here)

- `docs/working/seed-build-loop-handoff.md:81` restates the old "Take the Now items" rule
  (a historical seed).
- `docs/working/plan-build-loop-handoff.md` does not restate step 8's rule (D9 covers slots
  only).

## Verification

- `scripts/confine-tests.sh --probe`: exit 3, first line "confine-tests: NO CONFINEMENT
  PRIMITIVE AVAILABLE — refusing to run." So: `bats test/scripts/build-loop-orchestrator.bats`
  (50 ok), `scripts/hermeticity-lint --root .` (exit 0), and `scripts/run-tests.sh`.
