# Research: RPI ← From Divergent Design pivot

## Scope

Add a bidirectional pivot entry to RPI's "When to pivot" section covering the case where implementation surfaces a hard constraint that invalidates a DD-chosen approach.

## What exists

- `workflows/research-plan-implement.md:15-23` — the "When to pivot" section, with seven entries (→ Spike, → DD, ← Spike, ← Onboarding, → Bug Diagnosis, ← Bug Diagnosis, ← Testing). Forward (→) and back (←) entries are interleaved, not strictly grouped.
- `workflows/research-plan-implement.md:18` — existing `→ Divergent Design` entry: research-time pivot when 3+ viable approaches surface; DD's decision feeds back into the plan. There is no current entry for the *return* path from implementation back to DD.
- The "How workflows compose" section in CLAUDE.md describes RPI ↔ DD as a bidirectional composition, but the back path was only documented at research time, not implementation time. [observed]

## Invariants

- Existing → DD entry must remain unchanged. [observed]
- Naming convention for back-pivots is `← From {Workflow}` (lines 19, 20, 22, 23). [observed]
- Decision records live in `docs/decisions/NNN-title.md` per global CLAUDE.md. [observed]

## Prior art

- `← From Spike` (line 19), `← From Onboarding` (line 20), `← From Bug Diagnosis` (line 22), `← From Testing` (line 23) are the existing back-pivot entries; each describes when to load that upstream workflow's artifact into RPI. The new entry inverts the direction (RPI → DD) but follows the same naming pattern. [observed]
- Decision-record updates are referenced in the user's exact text: append the new constraint to the *Consequences* section of the existing decision record, then re-invoke DD with the augmented constraint set.

## Gotchas

- The back-pivot should guard against scope abuse: implementation difficulty alone is not a valid trigger. The user's instruction explicitly distinguishes "genuine constraint discovery" from "relitigating decisions that feel harder than expected." That guard must survive in the final wording.
- File scope is limited to `workflows/research-plan-implement.md` plus `docs/working/`; the CLAUDE.md "How workflows compose" section will not be touched in this loop even though it discusses the same bidirectional path.
