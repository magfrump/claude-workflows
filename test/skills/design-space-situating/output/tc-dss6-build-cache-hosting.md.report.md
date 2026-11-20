# Situating Record: Brightmoor remote build cache hosting

**Date:** 2026-11-20

## Decision under situating

> The Brightmoor developer-productivity team is choosing where to host the remote build cache for our monorepo's CI. Options: (a) a managed cache service from our CI vendor, (b) self-hosted cache nodes on our existing Kubernetes cluster, or (c) an object-storage bucket behind the open-source cache proxy.

## Situating paragraph

This is a **cheap-to-reverse, centralized operational choice among three already-enumerated options**. It is a search over a known space, not a design problem. The most load-bearing dimension is reversibility. Entries are regenerable, all options speak the same protocol, and the January trial showed a switch takes under an hour and the cache re-warms in about a day. A wrong choice therefore costs roughly a day of slower CI. The planned process does not reflect that low cost: three two-week trials, plus setup and analysis, fill most of a ten-week runway, which is more scrutiny than the reversal cost justifies. The second load-bearing dimension is the modeling target. The decision mostly concerns operational fit (cost, on-call, existing infrastructure). The receivers' stated needs are hit rate and upload speed, but upload speed does not appear in the criteria, and hit rate may not distinguish between the options at all.

## Dimensional placements

| # | Dimension | Placement | Rationale |
|---|---|---|---|
| 1 | Locus of authority | Centralized | The four-engineer developer-productivity team decides and operates the cache, and product teams consume it through one URL in a shared CI config. |
| 2 | Orientation in time | Forward; Snapshot (with a named revisit trigger) | The team starts from current traffic and a 9 TB footprint, expects stable needs for about two years, and will revisit only if the monorepo doubles. |
| 3 | Search / Compose / Emerge | Search | Three enumerated candidates are scored on measured criteria over trial traffic, which is a textbook search over a pre-existing space. |
| 4 | Modeling target | Context (primary), Receiver (secondary) | Cost, on-call rota and vendor dependency describe fit with Brightmoor's environment, and the receiver side (product teams' hit rate and upload speed) is only partly captured in the criteria. |
| 5 | Reversibility | Cheap; gradient flat | The January switch was demonstrated at under an hour plus about a day of re-warm, and the only possible cliff is something the brief doesn't mention, such as a multi-year vendor commitment on (a). |
| 6 | Formality | Explicit | The output is measured trial numbers and a short decision record any engineer can check, which fits the team's budget. No formal artifact is needed. |
| 7 | Social structure | Expert-led | Product teams were consulted on needs and have no stake in hosting, so expert-led is the right position rather than a hidden default. |
| 8 | Legibility | Peer + Machine | The record is for any engineer and the dashboards are machine/peer surfaces. Whoever approved the budget ceiling is a stakeholder audience with no named translation layer, so the cost-at-18 TB comparison should be stated plainly for them. |

## Tensions surfaced

- **Scrutiny vs. reversibility vs. deadline.** The evaluation is sized for an expensive-to-undo decision, but this one is cheap to undo. Run sequentially, three two-week trials plus provisioning consume roughly six to eight of the ten weeks before the disk fills, leaving little margin. The brief doesn't say whether trials run in parallel on a traffic copy or one after another. Reversibility suggests a lighter path is also legitimate: pick on cost and on-call, switch if the numbers disappoint.
- **Receiver need dropped from the criteria.** All three product teams asked for *upload speed*. Criterion 1 measures hit rate and p95 *fetch* latency only.
- **Hit rate may not discriminate.** Clients and protocol are identical and keys are content hashes, so hit rate differences come mainly from capacity and eviction policy, not hosting. If trial capacities are equal, criterion 1 reduces to latency.
- **Budget ceiling is underspecified.** Budget is "approved up to the cost of option (b)," but that cost is itself an output of the evaluation, and the brief doesn't say whether the ceiling applies at 9 TB or at the projected 18 TB.
- **Possible unnamed cliff.** The on-call criterion frames (a) and (c) as "adds a vendor dependency" but does not ask about contract term. A committed-spend or minimum-term contract on (a) would be the only thing that breaks the flat reversibility gradient.

## Hand-off

This record is a frame, not a decision. It feeds **direct implementation**: the options and criteria already exist, so neither DD nor RPI is needed. The implementer is the developer-productivity team. Their first concrete step is to decide, against the ten-week disk deadline, whether the trials run in parallel on a mirrored traffic copy or the evaluation is cut short given the cheap reversal cost. In the same pass they should add upload latency to criterion 1, state whether the budget ceiling applies at 9 TB or 18 TB, and check option (a)'s contract term for a minimum commitment.
