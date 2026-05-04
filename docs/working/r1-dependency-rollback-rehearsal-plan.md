---
Goal: Make rollback documentation + verification a precondition (not an afterthought) of any dependency upgrade.
Project state: r1 round delivers a precondition rollback-rehearsal step with template to skills/dependency-upgrade.md · standalone · not blocked
Task status: complete (analysis subsection added, output template updated with Rollback Plan precondition section, Important notes bullet added)
---

## Context

Round task: edit `skills/dependency-upgrade.md` so that documenting and rehearsing the rollback procedure (exact commands + verification step) is a precondition that happens BEFORE the migration starts — not after. Provide a template the user fills in.

The existing skill produces a "Migration Plan" but never asks for a rollback plan. Rollback comes up only implicitly (via "what could go wrong"). The implicit treatment is the gap: an upgrade where you don't know how to revert is unsafe to begin.

## Plan

Make two coordinated edits to `skills/dependency-upgrade.md`:

1. **Add a new analysis subsection** between the existing "4. Urgency" and the "Output" section, titled `### 5. Rollback rehearsal (precondition)`. It states:
   - The rollback must be documented AND rehearsed before starting the upgrade.
   - "Documented" means: the exact commands to revert (lockfile / version pin / package install command).
   - "Rehearsed" means: actually run those commands on a scratch branch (or equivalent) and confirm a verification step (smoke test, app boot, focused test) passes after rollback.
   - Why: an upgrade you can't undo is unsafe to start; rehearsal surfaces broken assumptions while they're still cheap.

2. **Add a Rollback Plan section to the output template**, placed *before* "Migration Plan" (because it's a precondition). Template fields:
   - Exact rollback commands (fill-in code block).
   - Verification step that confirms rollback succeeded.
   - Rehearsal status checkbox: rehearsed on {date/branch}, verification passed.

3. **Add a bullet to the "Important" notes**: "Don't start the migration until the rollback is documented and rehearsed. A planned rollback that's never been executed is not a rollback plan."

## Verification

- Read `skills/dependency-upgrade.md` post-edit and confirm:
  - New `### 5. Rollback rehearsal (precondition)` subsection exists between "### 4. Urgency" and "## Output".
  - Output template has a "Rollback Plan (precondition)" section ordered before "Migration Plan".
  - Template includes: exact-commands code block placeholder, verification step placeholder, rehearsal-status placeholder.
  - "Important" section includes a bullet about not starting migration before rollback rehearsal.
- Confirm no other files were modified.
