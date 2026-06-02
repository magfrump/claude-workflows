- **Goal**: Add output discipline to divergent-design.md steps 1–3 so each step emits only a compact console summary (candidate count + headlines, constraint count, surviving-candidate count) while the full diverge/diagnose/match prose goes to a working doc — keeping the console from being flooded before the step-4 decision block.
- **Problem framing**: The console floods with full evaluation prose across steps 1–3 before the human reaches step 4, so the scrutiny surface is buried under scrollback. Considered and discarded: "the step-4 block itself is too verbose" — the step-4 block already has its progressive-disclosure Acceptance checklist; the flood happens *upstream* of it, at the surface that checklist never covered.
- **Project state**: feat/r3-dd-stepwise-compact-console-output delivers a compact-console convention on DD steps 1–3 · round-3 task in the DD-display-formatting line, sibling to the shipped r1 decision block and r2 acceptance gate · not blocked (cite: dd-display-formatting-property-acceptance.md).
- **Task status**: complete (convention added, per-step notes + Done-when rows wired, scope verified)

Failure-pattern grep: no matches found

## Research

### What exists
- `workflows/divergent-design.md` steps 1–3 (Diverge / Diagnose / Match and prune) currently have **no defined output home**: candidate lists, the generation health-check reasoning, the pre-generation grep dump, the full constraint list, and the compatibility matrix all land in the console / conversation inline. Only step 5 writes to a file (`docs/decisions/NNN-title.md`).
- Step 4's "Decision presentation" sub-step (added r1 `1bf0aa3`) renders a CLI decision block built for scrutiny, and its r2 **Acceptance checklist (structure gate)** holds it to *progressive disclosure* (index first, detail on demand), *boxed regions*, and *one decision per screen*. That checklist only governs the **step-4** surface — the flood the user complains about happens at steps 1–3, upstream of it. [observed]
- The repo already uses `docs/working/dd-{topic}.md` as the DD scratch-doc convention (e.g. `dd-display-formatting-property-acceptance.md`, `dd-failure-driven-move.md`). [observed]

### Invariants / scope
- **Strictly additive to steps 1–3.** Leave the step-4 `self_eval`-Weak seam (the Decision presentation block, its Acceptance checklist, and the step-4 Done-when rows) untouched. [observed]
- File scope: only `workflows/divergent-design.md` (+ this working doc).
- House style: internal cross-references are by **name in prose** (e.g. step 4's "Acceptance checklist (structure gate)"), not markdown anchor links — match that, avoid fragile anchors.
- The task fixes the per-step compact contents precisely: step 1 = candidate count + one-line headlines; step 2 = constraint count; step 3 = surviving-candidate count. Honor that asymmetry (only step 1 puts the headlines on the console; the rest are counts, with detail in the doc).

### Prior art
- r2 (`dd-display-formatting-property-acceptance.md`) is the direct predecessor: it made the step-4 block's structure a checkable gate by citing the brainstorm-display conventions inline. This round extends the *same* progressive-disclosure principle one diamond earlier (console = index, working doc = detail), so the addition reads as coherent with the existing design language rather than a bolt-on.

### Gotchas
- Step 1's headlines legitimately belong on the console — they are one sentence each (the search-space index). The flood is the *health-check analysis, grep dump, and per-candidate reasoning*, not the bare headlines. Compact ≠ hiding the candidate list.
- When DD runs as an RPI sub-procedure there is already a research doc; creating a second `dd-{topic}.md` would fragment the prose. The convention must say "fold into the calling research doc instead" for that case.

## Plan
1. Add a `### Output discipline (steps 1-3)` convention block right after `## Process` and before `### 1. Diverge`. It names the working doc (`docs/working/dd-{topic}.md`, or the calling RPI research doc when DD is a sub-procedure), states the principle by reference to step 4's progressive-disclosure Acceptance checklist, and shows a rendered 3-line console trail example. One commit.
2. Add a `#### Console output (compact)` note to each of steps 1, 2, 3 stating what goes to the doc vs. the console, with the step's own one-line rendered example. Add one Done-when checkbox per step enforcing it. Same commit (coherent group).

Implementation order: `1 → 2` (the per-step notes reference the convention block by name, so the block lands first). Single logical change; one commit.

## Verification
- Re-read edited regions for internal consistency (working-doc path, glyph/format identical across the shared example and the three per-step examples).
- `git diff` confirms no edits leaked into step 4 (Decision presentation, Acceptance checklist, step-4 Done-when), step 5, or the variants.
- Confirm each of steps 1–3 gained exactly one Console-output note and one Done-when row.

## Files read
Last verified: 2026-06-02
workflows/divergent-design.md
workflows/research-plan-implement.md
docs/working/dd-display-formatting-property-acceptance.md
docs/thoughts/failure-patterns.md
