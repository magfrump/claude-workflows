Goal: Add an optional "Failure modes considered" subsection to the plan template in `workflows/research-plan-implement.md`, required when a plan has >5 steps OR touches a trust boundary.
Project state: Round-1 edit to the RPI plan template; standalone (no sibling round); not blocked (cite: 12aa236).
Task status: complete (research drafted, planning next).

## What exists

- **`workflows/research-plan-implement.md` step 3 (Plan)** is where the plan-doc body sections are specified. The current body-section list is (in order): Approach → Steps → Implementation order → Size estimate → Estimated context cost → Actual context cost (post-implementation) → Test specification → Risks. Each section is one top-level bullet under the body; sub-bullets carry the spec text. [observed — re-read of lines 137-194]
- **The "Implementation order" bullet (line 144)** is the closest structural twin to what's being added. It has:
  - One opening sentence stating purpose
  - A **When required vs. optional** sub-bullet with two triggers and a "first triggers on X / second triggers on Y" gloss
  - A **Notation** sub-bullet
  - A **Worked example** sub-bullet built around a 7-step API-endpoint plan
  Modelling the new section on this pattern keeps reader expectations consistent. [observed]
- **The "Test specification" bullet (line 174)** holds the table-based per-test entries. Failure modes naturally reference test cases by name, so the new section lives downstream of Test specification in the body order. [observed]
- **The "Risks" bullet (line 194)** is "what could go wrong, what's uncertain, what you'd want a reviewer to scrutinize" — open-ended scrutiny prose. The new section is its more-concrete counterpart: *named* failures with *named* guards, not open-ended worries. Both should exist; the new one narrows, the old one stays broad. [observed]
- **The Done-when checklist (lines 247-255)** has one bullet per body section, with the Implementation order bullet calling out its conditional trigger explicitly ("when the plan has more than 5 steps OR will be implemented in /away mode"). The new section needs a parallel Done-when bullet so the trigger condition lives where the self-audit happens. [observed]

## Invariants

- **Plan template body sections live in step 3 only.** Step 4 (Annotate) is the human review gate, not a template location. The task brief says "step 4" but the only plan template in the file is in step 3; the edit must land in step 3 to be coherent with the rest of the doc. [observed — re-read of step 4 lines 257-278 confirms it contains no template]
- **Trigger-condition wording must mirror Implementation order.** Implementation order uses "more than 5 steps" (not ">5" symbolically); the new section should match for cross-section consistency. [observed]
- **Done-when bullet must name the conditional explicitly.** The existing Implementation order Done-when ("when the plan has more than 5 steps OR will be implemented in /away mode") is the template — copy its shape so a re-reader scanning the checklist sees the trigger without flipping back to the body. [observed]
- **Worked example must be runnable in the reader's head.** The Implementation order worked example reuses the same 7-step API endpoint plan throughout — that consistency lets the reader carry one mental model across both sections instead of context-switching. The new section should reuse the same 7-step plan so failure-mode entries can name `User.email_verified`, `Session.last_seen_at`, etc., without re-introducing the example. [observed]

## Prior art

- **`workflows/research-plan-implement.md` "Implementation order" block (line 144)** — the direct structural model. Same "When required vs. optional" → "Notation/Format" → "Worked example" cadence. Same conditional trigger pattern (one trigger on cognitive load, one on a higher-stakes context).
- **`workflows/research-plan-implement.md` "Test specification" block (line 174)** — the table-form prior art. The new section's table is the same two-column shape with different column headers (Test case/Expected behavior → Failure mode/Guard).
- **`docs/decisions/006-foregrounding-tests.md`** — frames tests as a design artifact, not a verification afterthought. The new section extends that posture: failure modes are *also* a design artifact, articulated before implementation, and the guard for each failure is preferably a test case (linking back to Test specification).
- **`workflows/bug-diagnosis.md` (and the absorbed debugging defaults in CLAUDE.md)** — the "Hypothesize specifically" rule already requires falsifiable claims about specific locations and mechanisms. Failure-modes-considered is the forward-looking twin: same specificity requirement, applied before the bug exists rather than during diagnosis. [observed]
- **The phrase "premortem"** in the task brief is the canonical term for this technique (Klein, 2007) — imagine the project failed, list specific causes, plan guards. The section name "Failure modes considered" sidesteps the jargon while keeping the practice. [inferred from common usage]

## Gotchas

- **The task brief says "step 4"** but the plan template is in step 3. Adding the subsection to step 4 (Annotate) would be incoherent — there's no template there to add a subsection to. The brief's "step 4" is best read as a miscount; the body section list it describes ("subsection to the plan template") only exists in step 3. Documenting this here so the implementation choice is auditable. [observed]
- **Failure modes ≠ Risks.** A reader skimming the doc might ask "isn't this just Risks?" The distinguishing line: Risks is open-ended scrutiny ("what would a reviewer flag?"); Failure modes is paired ("specific failure ↔ specific guard"). Without a guard, an entry is a Risk, not a Failure mode. The spec text should make that pairing requirement load-bearing. [observed]
- **Trust-boundary trigger ambiguity.** "Trust boundary" is a term-of-art from security review. The CLAUDE.md security-reviewer skill enumerates the canonical list: "auth, input handling, crypto, trust boundaries, file I/O, network calls, serialization." The new section should reuse this enumeration so the trigger lines up with the existing skill — readers shouldn't need to learn a second definition. [observed]
- **3-5 entries cap is load-bearing.** A premortem with 1-2 entries is performative; one with 10+ is unfocused. The 3-5 range forces the author to prioritize the most consequential failures, which is the point. Spec text should state the range as a soft requirement, not just a suggestion. [observed]
- **Guard must be in the plan, not aspirational.** The pairing is only credible if each guard is something the plan already commits to — a test case in Test specification, an ordering constraint in Implementation order, or a structural choice in a step. If a failure has no guard yet, the entry is a directive to add one *before implementation begins*, not a confession that the failure is acceptable. The spec text should call this out explicitly. [observed]

## Transition note

Moved to plan: diminishing returns after re-reading step 3 and the Implementation order bullet — the structural twin is identified, the placement decision is made (between Test specification and Risks), the trigger conditions are clear, and the worked example reuses the existing 7-step plan. Nothing further to research before drafting the spec text.
