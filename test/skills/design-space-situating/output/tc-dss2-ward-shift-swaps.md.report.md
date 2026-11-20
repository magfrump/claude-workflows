# Situating Record: Shift-swap rules for the Kestrel Valley rostering system

**Date:** 2026-11-20

## Decision under situating

> Kestrel Valley Health is choosing how the new rostering system will handle nurses swapping shifts across its 14 inpatient wards. The options are (a) free swaps between any two qualified nurses with automatic approval, (b) swaps only within a ward, approved by the ward manager, or (c) a points-based marketplace where unpopular shifts earn credits toward preferred ones.

## Situating paragraph

The brief frames this as a platform configuration decision. Its placements describe something else: a change to how 1,100 nurses negotiate their working time, which replaces 14 distinct local practices on a single day. The most load-bearing dimension is **social structure (#7)**. The brief assumes an expert-led decision, but the union agreement makes working-time changes "subject to negotiation", and nobody has said whether swap rules fall inside that clause. The next is **modeling target (#4)**. All four criteria concern structure (audit, skill-mix enforcement, configuration effort, uniformity). None concerns the nurses who use the rules or the local arrangements the rules will displace, including the surgical night-shift cohort that drives 40% of swaps. **Reversibility (#5)** has a sharp cliff. The vendor configuration window closes at week 4, but nurses first see the rules at week 9, so the people best placed to find problems only see the design after it is locked. The options also differ on the dimensions themselves: they are not three settings of the same rule. (a) gives authority to individual nurses and depends on formal skill-mix enforcement. (b) gives it to ward managers and keeps local judgment. (c) is an ongoing, emergent economy that needs tuning after launch.

## Dimensional placements

| # | Dimension | Placement | Rationale |
|---|---|---|---|
| 1 | Locus of authority | Centralized (decision) applied to Distributed practice; options vary: (a) Distributed, (b) Mixed, (c) Distributed via market rules | One architect writes one spec for 14 wards that each run their own swap arrangement today (spreadsheet, WhatsApp, the alternate-year Christmas agreement), which is the classic case of central design meeting distributed application. |
| 2 | Orientation in time | Backward (from audit and skill-mix requirements); Snapshot spec over a Process reality | The spec is handed to the vendor as a finished artifact, but swapping is continuous behaviour. Option (c) in particular is an economy whose credit values need ongoing tuning, and the brief names no post-launch owner. |
| 3 | Search / Compose / Emerge | Search (among three options); option (c) itself is Emerge | The framing treats this as picking from an enumerated set. Option (c) would delegate outcomes to emergent market behaviour, so choosing it means choosing a different navigation mode, not a different setting. |
| 4 | Modeling target | Structure (stated); Receiver and Context unowned | All four criteria are structural. Nurse experience, fairness across shift patterns, the 40% surgical night-shift load, and existing local agreements appear in the context but in no criterion. |
| 5 | Reversibility | Cheap now → Expensive after week 4 (vendor window closes) → Very expensive after go-live (all 14 wards at once, plus possible union renegotiation) | There is no staged rollout to absorb a wrong choice, and nurse feedback arrives at week 9 training, after the configuration cliff. Option (c)'s custom module makes the week-4 cliff steeper. |
| 6 | Formality | Formal (skill-mix enforcement, audit trail) replacing Tacit (current ward practice) | Option (a)'s automatic approval is only safe if skill-mix and qualification data are formal enough for the system to enforce without a human check. Option (b) keeps a human judgment layer that covers gaps in that data. The tacit arrangements being replaced, such as the Christmas rota, have no stated translation into the formal spec. |
| 7 | Social structure | Expert-led (as framed); de facto Participatory/negotiated (union clause); current practice is Community-generated | "Subject to negotiation" may make this a participatory decision regardless of the framing. Today's arrangements emerged from ward communities with no designated designer. |
| 8 | Legibility | Machine + Peer (vendor spec); Stakeholder (regulator audit); nurses appear only as end-of-pipeline trainees | The spec is written for the vendor and the regulator. The 1,100 nurses who must follow the rules are reached only through training in the final week, and no union-facing or nurse-facing version of the rules is planned. |

## Tensions surfaced

- **Authority–social-structure mismatch.** A single owner deciding for speed sits against a union agreement that may require negotiation. Whether swap rules count as a "working-time arrangement" is an unexamined default, and the answer determines whether the 4-week window is even achievable.
- **Target neglect.** The criteria cover structure only. Receiver concerns (nurse workability, especially the surgical night cohort) and context concerns (existing local agreements, union position) have no criterion, so the option comparison cannot see them.
- **Consistency vs. existing local arrangements.** Criterion 4 ("one set of rules for every ward") silently extinguishes practices like the two wards' Christmas agreement. That may be intended, but the brief does not state it as a choice.
- **Reversibility cliff precedes feedback.** Configuration locks at week 4, nurses learn the rules at week 9, and go-live is simultaneous across all 14 wards. No point in the schedule lets the affected population surface problems while changes are still cheap.
- **Snapshot spec vs. process behaviour.** A one-time rules hand-off assumes static behaviour. Option (c) requires continuous rebalancing, and every option will produce workarounds. The brief names no owner of the rules after go-live.
- **Formality dependency in option (a).** Automatic approval moves all safety weight onto formal skill-mix data. Whether that data is complete and accurate enough is a precondition the brief does not establish.
- **Configuration effort vs. option (c).** A custom module inside a 4-week window that may also need to absorb negotiation is a schedule risk, not just a cost criterion.

## Hand-off

This record is a frame, not a decision. It is input to **DD's diagnosis step (step 2)**. Before DD diverges, the team should settle these questions as testable constraints:

- **Negotiation scope (#7, #5):** Do swap rules fall under the union's "subject to negotiation" clause? If yes, negotiation becomes a hard schedule constraint that must finish inside the week-4 window, or the timeline changes.
- **Missing criteria (#4):** Add at least one receiver criterion (workability for nurses, especially surgical night shifts) and one context criterion (treatment of existing local arrangements), or record explicitly that they are out of scope.
- **Consistency (#1, #4):** State whether retiring the local arrangements is intended, and if so who communicates that and when.
- **Feedback before the cliff (#5, #8):** Name whether any nurse or ward-manager review happens before week 4.
- **Post-launch ownership (#2):** Name who owns the rules after go-live, which is mandatory if (c) stays in the set.
- **Skill-mix data readiness (#6):** Confirm the data can support automatic enforcement before (a) is treated as viable.

If the negotiation question comes back "yes", the problem statement itself changes. In that case, re-run DD's Double Diamond framing step (Diamond 1) before diagnosis, because the decision would then concern a negotiated working-time arrangement rather than configuration.
