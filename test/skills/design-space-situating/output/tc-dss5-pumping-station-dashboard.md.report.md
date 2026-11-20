# Situating Record: Harrowgate Water pumping-station alarm dashboard

**Date:** 2026-11-20

## Decision under situating

> Harrowgate Water is choosing a new dashboard for its 64 sewage and clean-water pumping stations. The options are (a) a single network health score from 0 to 100 with a red/amber/green status per region, (b) a regional map with one status tile per station, or (c) a station-level view listing each pump's pressure, flow and alarm history.

## Situating paragraph

This is a **legibility-audience decision** (dimension #8) presented as a choice of dashboard style. The question underneath is whose reading of the screen the artifact is optimised for. The primary user is the night-shift operator deciding at 3am whether to dispatch, restart or wait. That operator judges urgency by comparing one pump against its own trend and its neighbours, which is tacit, peer-level craft. All four scoring criteria instead measure stakeholder legibility: the board, the regulator, demonstrations and cost. No one in the scoring group represents the operator's modelling target (#4 Receiver) or social position (#7). The most load-bearing dimensions are #8 (legibility), #4 (modelling target) and #5 (reversibility). The contract-award cliff in six weeks and the five-month licence cliff mean an audience mismatch becomes expensive to correct soon after the decision is made. The sharpest tension is that the highest-scoring option aggregates 64 stations into one number and regional RAG colours. That aggregation is exactly what hides a slow single-pump pressure drift, the pattern operators say most real incidents start as. The three options may also not be true alternatives: they look like three zoom levels serving different audiences.

## Dimensional placements

| # | Dimension | Placement | Rationale |
|---|---|---|---|
| 1 | Locus of authority | Centralized | A five-person steering group chooses by a summed score, but the artifact is applied around the clock by rotating operator pairs whose local judgment drives dispatch decisions. |
| 2 | Orientation in time | Backward; Process | Criteria work backward from fixed outputs (the board slide and the quarterly return), yet the control-room use is a continuous monitoring process where the signal is a two-to-three-hour trend, not a snapshot. |
| 3 | Search / Compose / Emerge | Search | The group is scoring three pre-enumerated options against fixed criteria, which assumes the option set already contains the right answer and that the options are mutually exclusive. |
| 4 | Modeling target | Context (stated); Receiver (actual primary use) | The criteria model fit with board, regulator and demonstration contexts, while the safety-critical use models the operator as receiver; the operator's needs are not delegated to anyone, they are absent. |
| 5 | Reversibility | Cheap now → Expensive at contract award (6 weeks) → Very expensive at old licence expiry (5 months) | After award, changing the primary view means renegotiation or a second procurement; after the old licence ends there is no fallback screen, and the cost of a wrong choice includes missed incidents, not just rework. |
| 6 | Formality | Explicit (the decision process); Tacit (the operational knowledge being displayed) | The scoring rubric is explicit and auditable, but how operators judge urgency (own-trend plus neighbour comparison) is tacit craft that no criterion captures or tests. |
| 7 | Social structure | Expert-led, with the wrong experts | The deciders are executive and programme specialists. The domain experts for the primary use are the operators, who are neither in the group nor represented in the criteria. |
| 8 | Legibility | Stakeholder (scored); Peer/operator (needed); Machine (regulatory return) | Criteria 1 to 3 all measure stakeholder legibility, and nothing measures operator legibility; the translation from station-level detail to board and regulator summaries goes unnamed and gets treated as the dashboard itself. |

## Tensions surfaced

- **Legibility audience mismatch (#8 vs. stated context).** The brief calls this "the main screen in the control room," but every scoring criterion measures legibility to the board, the regulator or a demonstration audience. Operator legibility scores zero weight. The 17/8 ranking largely reflects this weighting, not operational fitness.
- **Aggregation hides the known incident signature (#4, #2).** Operators say most real incidents begin as a slow pressure drift on a single pump. A network 0–100 score with regional RAG status is designed to absorb local variation, so a single-pump drift is the case least likely to move it. Option (b) shows station status but not trend. Only (c) exposes per-pump history.
- **Snapshot criteria for a process task (#2).** "Understand status in under ten seconds" rewards an instantaneous reading. Operator judgment depends on a two-to-three-hour trend, and no criterion tests whether trend and neighbour comparison is visible at all.
- **Social-structure gap (#7 vs. #1).** Centralized authority is coherent on its own terms. Here, though, the people with authority are not the people with the tacit knowledge (#6) needed to judge fitness for the primary use. "Expert-led" is a default, not a chosen position, because the relevant experts were never in the room.
- **Search over a possibly false partition (#3).** The options read as three levels of one information hierarchy: network, region/station, pump. Scoring them as mutually exclusive alternatives assumes one screen must serve all audiences. That assumption was never stated.
- **Reversibility under time pressure (#5).** Award in six weeks leaves little room for operator input or a trial. The five-month licence end removes the fallback. An audience mismatch discovered in the first months of live operation is the most expensive kind to fix.
- **Unmeasured safety and regulatory risk.** Criterion 2 checks mapping onto the regulator's quarterly return. Nothing checks whether the dashboard supports detecting the incidents that would feed that return, such as pollution or supply-interruption events.

## Hand-off

This record is a frame, not a decision. It is input to **DD's diagnosis step (step 2)**. The scoring rubric should be treated as a draft constraint set, not a settled one. The constraints to make testable:

- **Operator legibility (#8, #4):** Add an explicit criterion to the rubric, for example: "Can the night-shift operator detect a single-pump pressure drift over 2–3 hours, and compare a pump with its own trend and its neighbours, without leaving the main screen?" Test it with operators against the incident pattern they described.
- **Who scores (#7):** Name the operator or control-room-lead voice in the scoring. If none is added, record that the decision is knowingly made without primary-user input.
- **Audience partition (#3, #8):** State whether one screen must serve board, regulator and control room, or whether summaries may be derived from a station-level primary view. This determines whether DD's diverge step treats (a), (b) and (c) as rivals or as layers.
- **Reversibility (#5):** State what can still change after contract award: configurable views, contract options for additional screens, or a pilot period before the old licence ends. If nothing can change, the operator-legibility constraint has to be satisfied before award, not discovered afterward.

With these constraints explicit, the current 17/13/8 ranking should be re-derived rather than carried forward.
