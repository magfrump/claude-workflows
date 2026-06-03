- **Goal**: Make DD step 4's human-consult path render the decision as a native `AskUserQuestion` prompt (one option per surviving candidate), while keeping the autonomous (>80%) and SI-loop paths prompt-free so the overnight loop can't hang.
- **Project state**: feat/r1-dd-decision-via-askuserquestion · standalone workflow-doc change · not blocked.
- **Task status**: complete (both edits applied to `workflows/divergent-design.md`, verified internally consistent)

## Research

### What I know

The relevant surface is `workflows/divergent-design.md`, step 4 ("Tradeoff matrix and decision"):

- `#### Decision presentation` (lines ~185–241) renders the **static** CLI decision block in three regions: Region 1 scorecard grid (one glyph-scored row per surviving candidate, `★` on the recommended one), Region 2 candidate cards (drill-down with the falsifiable hypothesis + stress-test moves), Region 3 drill-down protocol. This block is required on **every** path by the step-4 Done-when checklist — it's the static surface.
- `#### Decision` (lines ~243–249) is the branch logic:
  - `>80% confidence` → "document the decision and proceed" (autonomous-dominant path).
  - "genuinely unclear" → "**stop and consult the user**. Show the Decision presentation block ... state your tentative recommendation ...". This is the **human consult path** the task targets.
- The "Round claim" subsection in step 5 (line ~344) is the mechanism by which a DD run **inside a multi-round / SI-loop context** surfaces its chosen hypothesis to the user *asynchronously* (decision 012 grammar → morning summary precondition gate). This is the non-interactive surfacing channel — it is NOT a live prompt.

### Invariants to preserve

- The static Decision presentation block (Regions 1–3) and its Acceptance checklist must remain unchanged and continue to render on all paths.
- Each surviving candidate already carries: a short approach name, a `key downside` scorecard cell (with optional `(mitig.)` tag), and a verbatim falsifiable hypothesis (`"If we choose this, we expect … within …; counter-evidence would be …"`). These are exactly the fields the AskUserQuestion needs — no new analysis.
- The SI loop is non-interactive by design (memory: `feedback_si_noninteractive`). A live prompt there blocks forever.

### Constraints / pitfalls

- `AskUserQuestion` allows **at most 4 options** (plus an auto-appended "Other"). But step 3/4 admit **3–5** survivors. So the 5-survivor case needs an explicit rule: present the top 4 by recommendation priority as native options; the 5th stays visible in the preceding scorecard grid and selectable via "Other". Never silently drop it.
- AskUserQuestion convention: a recommended option goes **first** with ` (Recommended)` appended to its label.
- The task says the prompt is "preceded by (not duplicating) the scorecard grid" — so the grid renders once (Region 1), then the question carries only key-downside + hypothesis per option, not a re-drawn grid.

### Prior art

Decision 012 (round-claim grammar) already establishes the asynchronous, non-prompting surfacing channel for overnight decisions. The new interactive affordance is layered *only* on the human-present path; the overnight path keeps using round claims.

## Plan

Edit `workflows/divergent-design.md` only (plus this doc). Two edits:

1. **Rewrite `#### Decision`** into three explicit, mutually-exclusive paths:
   - **Path A** — `>80%` dominates: document + render static block, **no prompt**.
   - **Path B** — unclear, human present (interactive): render the static block once, then issue a single `AskUserQuestion` (question = step-2 decision goal; header = ≤12-char tag; one option per surviving candidate, recommendation-first; label = approach name, ` (Recommended)` on the top one; description = key downside + verbatim falsifiable hypothesis). Include the 4-option cap rule for the 5-survivor case. Do not re-draw the grid inside the question.
   - **Path C** — unclear, no human present (SI loop / non-interactive overnight): **no prompt**; render static block, record tentative recommendation + axis of disagreement, emit the `## Round claim` subsection so the choice is surfaced asynchronously. This is the anti-hang guard the task requires.
   - Keep the existing axis-of-disagreement paragraph, tying it to Path B (what the prompt resolves) and Path C (what the round claim hands over).

2. **Update the step-4 Done-when item** (currently "Either one approach dominates at >80% confidence, or the user has been consulted") to name the three paths and the AskUserQuestion shape.

### Verification

- Re-read the edited section for internal consistency: the three paths are mutually exclusive and exhaustive; only Path B prompts; Paths A and C explicitly never prompt.
- Confirm no other reference to the static block changed (Regions 1–3 + Acceptance checklist untouched).
- Confirm the Done-when checklist matches the new prose.
