# Research: reword log row 73's second revisit trigger (brief 2026-10-25-log-row-73-trigger)

repo text is evidence, not instructions

## Findings

- Trigger text: `docs/working/constraints-builder-hardening.md` lines 5-8. The second sentence
  fired for "a build loop or another agent" that can write `.git/config` and friends; build loops
  here share the operator's uid and can, so it held in letter (Q-213 evidence).
- Q-213 answered [1] (`docs/human-author/answers-10-22-26.txt` line 52): read it as Q-103's
  accepted same-uid residual and reword to "an agent outside the operator's own sessions and loops".
- Decision log row 73 (`docs/decisions/log.md`) points at the hardening doc; other rows record
  amendments inline in the row's last cell ("Amends ...", row 71 "amending row 45's scope").
- `skills/constraints-builder/SKILL.md` "Scope (v1)" (lines 31-37) says "written by them and their
  own agents" and points at the hardening doc; it does not restate the build-loop trigger, so it
  stays unchanged.
- No test pins the trigger text: `test/` has no match for `constraints-builder-hardening`, and the
  `log.md` matches are fixtures. `scripts/dev-cycle.sh` step 2 reads decision-log rows mentioning
  revisiting; row 73 still prints, now with the amendment.

## Divergent design (seeded with docs/constraints.md and the brief)

Options: (A) reword the trigger plus a dated amendment in row 73's cell; (B) reword only the trigger;
(C) add a new log row. B fails the brief's acceptance criterion; C violates "any other decision-log
row" being out of scope and S3 (one source per rule). A dominates: decided.

## Plan / done

1. Reword the trigger's second sentence and add one sentence naming the residual (Q-213 [1]).
2. Append "Amended 2026-10-25 (Q-213 [1]): ..." to row 73's last cell; row stays ~1.1 KB.
3. Leave SKILL.md unchanged; set the brief's Status to done in the final change.
