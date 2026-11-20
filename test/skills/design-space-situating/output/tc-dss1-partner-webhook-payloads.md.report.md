# Situating Record: Webhook payload format for the Ledgerline partner API

**Date:** 2026-11-20

## Decision under situating

> We are choosing the payload format for the outbound webhook events (`invoice.paid`, `invoice.overdue`, `payout.settled`) that the Ledgerline partner API will start sending on 1 March. The three options are a flat JSON object, a nested JSON envelope with a `data` block, or CloudEvents-style JSON.

## Situating paragraph

This is a **one-way, externally binding interface commitment**, not a low-stakes formatting choice. The brief treats it as cheap to change because it costs our side about a day of serializer work. But the cost of reversal is set by 312 vendors' hand-written parsers and a contractual 24-month field freeze, and neither has a version field to absorb change. Reversibility (#5) is cheap until 1 March and then falls off a cliff. Who the artifact is for (#4, #8) is the second load-bearing dimension. All three planned criteria (payload size, readability in our logs, our serializer effort) measure our own experience, while the actual readers are 312 independent parser authors and their machines. Underneath both sits a time-orientation mismatch (#2): the team frames the output as a snapshot it can "revisit after launch", but the partner agreement makes it a 24-month process with no planned evolution mechanism. The candidate set itself is incomplete along that axis, because a versioning or extensibility mechanism is absent from all three options rather than being a difference between them.

## Dimensional placements

| # | Dimension | Placement | Rationale |
|---|---|---|---|
| 1 | Locus of authority | Mixed | Five engineers decide centrally, but 312 vendors will each apply the format independently in their own parsers, with no SDK to keep them consistent until next year. |
| 2 | Orientation in time | Forward; Process (framed as Snapshot) | The team plans to "see how partners use the events" and revisit, which is forward-looking. But the 24-month field-stability commitment makes the format an ongoing obligation rather than a shipped-and-done artifact. |
| 3 | Search / Compose / Emerge | Search | The team is choosing among three enumerated candidates. The space is under-enumerated because no candidate carries a schema version, so the search can't reach the one property that governs future change. |
| 4 | Modeling target | Context (framed as Structure) | The brief frames the decision as internal structure ("one serializer class"). The binding constraints, though, are external fit: partner parsers, the January agreement, and the 1 March date. |
| 5 | Reversibility | Cheap until 1 March, then Expensive; cliff at launch | Before launch a switch is a day of work. After launch every published field is frozen for 24 months and any format change breaks up to 312 independent parsers, with no version field to let old and new coexist. |
| 6 | Formality | Explicit, binding a Formal contract | The format will be defined by example and convention, with no schema or version planned. The partner agreement nonetheless makes field names and meanings a contractual, auditable commitment, so a formal promise rests on an informally specified artifact. |
| 7 | Social structure | Expert-led | Product delegated the decision fully to the integrations team, and partners are not consulted. That fits a provider-defined API, but no partner input enters before the freeze. |
| 8 | Legibility | Self (as framed); actually Peer + Machine | Criterion 2 optimizes for our own logs. The real readers are external developers and their parsers. There is no translation layer (no SDK, no schema, no version field) between what we find pleasant and what 312 parser authors must get right the first time. |

## Tensions surfaced

- **Reversibility misplaced on the wrong side of the interface.** "Switching is a day of work" measures our serializer. The agreement and the 312 parsers mean the actual reversal cost after 1 March is a contract change plus coordinated rework across every vendor. "We can always revisit it after launch" contradicts the 24-month field commitment.
- **Snapshot framing vs. 24-month process.** The decision is being treated as a one-meeting formatting call. The agreement turns it into a two-year evolution problem, and no evolution mechanism is planned: no schema version, and no stated rule for whether adding fields is allowed under "unchanged".
- **Self-legibility criteria for a peer/machine artifact.** None of the three criteria measures what parser authors experience. Examples include how to distinguish event types, where metadata lives versus business data, how to add fields without breaking parsers, and idempotency and ordering identifiers. Payload size (criterion 1) doesn't discriminate between the options, since all three are under 2 KB.
- **Candidate set shares an unexamined default.** All three options omit versioning, so the comparison cannot surface the property most likely to matter during the freeze. That property belongs on the table as a dimension of every candidate, not as a fourth option.
- **Process budget vs. commitment size.** A 30-minute review with no written comparison is sized for a reversible choice. The team has about two weeks of webhook capacity, and the decision is effectively irreversible on 1 March. The process may be under-scaled to the stakes. Whether to change that is the team's call, but the current sizing rests on the reversibility assumption above.
- **Formal commitment, informal artifact.** The contract promises field-and-meaning stability, but there is no schema to state precisely what was promised. Disputes over what counts as "changed meaning" would have nothing to adjudicate against.

## Hand-off

This record is a frame, not a decision. It is input to **DD's diagnosis step (step 2)**, where these constraints should become testable criteria in place of, or alongside, the current three:

- **Post-launch change path (#2, #5):** for each candidate, state how a new field, a new event type, and a changed field would be introduced during the 24-month freeze without breaking existing parsers. Whether "unchanged" permits additive fields should be read off the January agreement before the review.
- **Versioning (#3, #6):** treat schema or version signalling as a property every candidate must state a position on, including an explicit "none". It should not be left as an unplanned omission.
- **Parser-author legibility (#8):** evaluate each candidate from the perspective of a vendor writing a parser without an SDK. Consider event-type dispatch, envelope/metadata versus payload separation, and identifiers for deduplication and ordering. Criterion 2 (our log readability) becomes secondary.
- **Review sizing (#5):** decide explicitly whether a 30-minute, unwritten review matches a commitment that freezes on 1 March, given the roughly two weeks of capacity.

The intended file path would have been `docs/working/situating-webhook-payload-format.md`. It was printed here instead, as requested.
