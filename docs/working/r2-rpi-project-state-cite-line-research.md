Goal: Require the Project state line of the RPI three-line header to end with a `(cite: ...)` locator so the legibility claim is self-auditable.
Project state: Round-2 edit to `workflows/research-plan-implement.md` step 2; sibling to the round-1 fact-check inline-citation requirement; not blocked (cite: 728b3f5).
Task status: complete (edits applied, commit pending).

## What exists

- `workflows/research-plan-implement.md` step 2 defines the three-line research-doc header. The Project state bullet currently reads (lines 67):
  > **Project state**: One sentence — branch context, written as `<what this branch delivers> · <position in larger initiative, or "standalone"> · <blocked on, or "not blocked">`. Same three facts the old multi-field lead block carried, compressed to one scannable line.
- The Done-when checklist at the end of step 2 (line 116) checks for the three-line header but does not verify any citation.
- Step 3 (Plan) header (line 129) inherits the Project state definition by reference: "Same one-sentence project state as the corresponding research doc, refreshed if anything has moved." So updating step 2 propagates to step 3 by reference.
- Round-1 prior art: `skills/fact-check.md` introduced an inline-citation requirement (three allowed formats: URL anchor, quoted ≤25-word span, `[source: ...]` tag). The plan doc lives at `docs/working/r1-fact-check-inline-citation-plan.md`. The pattern is "every claim must carry a locator the reader can open" — the same pattern we're transplanting here.

## Invariants

- **The three-line header order must stay Goal → Project state → Task status** [observed: lines 64–68]. The downstream drift-check (step 5) re-reads these three lines positionally; reordering would break that protocol.
- **The Project state line stays single-sentence and single-line** [observed: line 67]. The cite must fit at the end, not introduce a new paragraph.
- **Step 3's plan-doc header inherits the Project state shape via "Same one-sentence project state"** [observed: line 129]. The cite requirement propagates automatically; we do not need a separate edit in step 3 unless we want a checklist mirror.

## Prior art

- `skills/fact-check.md` § Citation Requirement (added round 1). Each verdict must carry a citation in one of three formats; missing-cite verdicts are rejected and rewritten. Same self-audit posture: the cite is what makes drift visible without re-running the search.
- Plan that shipped it: `docs/working/r1-fact-check-inline-citation-plan.md`.

## Gotchas

- The Project state line names a project-level fact (branch delivers X, sibling to Y, blocked on Z), not a research claim — so the cite forms differ from fact-check's. The natural set is: `<short-hash>` (when the load-bearing fact is "this branch delivers X" or "Y just landed"), `<branch-name>` (when the load-bearing fact is "we sit alongside branch Z"), `<docs/path>` (when the load-bearing fact is "blocked on decision N" or "follows from working doc M").
- Pick **one** locator — the single most load-bearing pointer. A complete reference list defeats the scannable-line constraint.
- The task brief notes current drift at 7%; the cite is what makes that drift externally measurable. The point is not enforcement (no linter) — it's making a stale claim immediately obvious to a re-reader.
