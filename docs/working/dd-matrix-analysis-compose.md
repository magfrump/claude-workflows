**Goal**: Let DD step 4 optionally invoke the `matrix-analysis` skill to score the 3-5 surviving candidates across effort/risk/coverage with parallel per-criterion sub-agents, so the scorecard's comparable cells come from independent per-criterion calibration rather than one agent reasoning over every cell.

**Project state**: feat/r3-dd-matrix-analysis-compose · standalone round in the DD-mechanism series · not blocked.

**Task status**: complete (subsection added to step 4, Done-when gate added).

---

## Why this is a genuinely new external mechanism

Prior DD rounds repeatedly edited the **display lever** (the step-4 scorecard render, AskUserQuestion previews, fill-in templates). The self-eval seed records that lever as saturated. This round changes *how the scorecard's cells are produced*, not how they are drawn — it introduces **skill composition** (DD → matrix-analysis) as a new external mechanism. matrix-analysis's whole value proposition is "parallel sub-agent dispatch produces more consistent calibration than a single agent reasoning about everything at once"; DD's step 4 today is exactly the single-agent-over-every-cell case the skill exists to replace for its comparable axes.

## The composition

- **items** = 3-5 step-3 survivors (pass name + step-3 matrix row + one-line description; sub-agents can't read the working doc).
- **criteria** = the three comparable scorecard axes: effort, risk, coverage — each framed *higher-is-better* so the returned rating maps onto DD's fixed glyph legend without inversion.
- **scoring** = matrix-analysis default Strong/Adequate/Weak → `● / ◐ / ○` one-to-one. `✗` (fails hard constraint) is a step-3 prune state, never re-scored here.
- **decision-intent** = the one-line step-2 diagnosis goal.
- **DD retains**: falsifiable hypothesis, stress-test pass, key downside, Decision presentation block, Decision paths A/B/C. matrix-analysis scores only the three comparable cells.

## Safety / non-interactive

Pass the three axes as *given* criteria so matrix-analysis's Stage-1 "confirm criteria with the user" step is pre-satisfied — the composition then never blocks on input and is safe inside a non-interactive Path C / SI-loop run.

## Scope

Additive only. One new `####` subsection inside step 4 (after the falsifiable-hypothesis paragraph, before the stress-test pass) plus one optional Done-when gate. No other file touched (file-scope constraint: `workflows/divergent-design.md` only).
