---
Goal: Add an 8th stress-test cognitive move ("Failure-driven") to DD step 4 so the table covers unanticipated-failure-mode enumeration alongside the existing seven moves.
Project state: feat/r1-dd-failure-driven-move · standalone · not blocked
Task status: complete
---

## Context

The existing 7-row stress-test table in `workflows/divergent-design.md` step 4 covers complexity (Boring alternative), assumption-challenging (Invert the thesis), human-behavior (Revealed preferences), logic-extension (Push to extreme), durability (Organizational survival), load (Scale test), and staffing (Implementation org chart). It does not have a move that asks "what new failure modes does this approach *introduce* that weren't on our requirements list?" — distinct from Push to extreme (which stretches existing logic) and Scale test (which stresses load).

This matters for security-sensitive, billing, compliance, and high-business-risk decisions where the cost of an unanticipated failure category dwarfs the cost of enumerating it upfront.

## Plan

- Insert a new row labeled **Failure-driven** in the stress-test cognitive moves table at lines 106-114 of `workflows/divergent-design.md`.
- Match the existing 3-column format: bold move name, 1-2 questions, "Use when…" trigger.
- Use the verbatim what-to-ask phrasing from the task: *"What new failure modes does each candidate enable that we haven't enumerated?"*
- Place the explicit distinction from Push to extreme and Scale test in the "When to use" column (where row-to-row scope clarification naturally lives) so the "What to ask" column stays consistent with the other rows.
- Add at the end of the table as the 8th row (per the task wording "8th row").

## Verification

- Visual check that the row reads uniformly with the surrounding 7 rows (same column count, same column conventions, same voice).
- Re-read the surrounding paragraphs (line 104 intro, line 116 follow-up) to confirm they still hold with 8 moves instead of 7 — both reference "moves" generically and "select 2-4," so no count update is needed.
