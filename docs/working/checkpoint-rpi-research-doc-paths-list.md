# Checkpoint: rpi-research-doc-paths-list
Date: 2026-05-15
Branch: feat/r3-rpi-research-doc-paths-list
Research: docs/working/research-rpi-research-doc-paths-list.md
Plan: docs/working/plan-rpi-research-doc-paths-list.md

## Project state
- **Branch purpose**: Add a `## Files read` section + `Last verified: <date>` requirement to RPI step 2 (Research) so future sessions can detect codebase staleness in research docs.
- **Position in larger initiative**: Standalone (single-loop change to one workflow file).
- **Blocked on**: Nothing.

## Key findings
- Step 2 of `workflows/research-plan-implement.md` already enumerates required body sections (What exists, Invariants, Prior art, Gotchas) plus a Failure-pattern lookup. The new requirement adds a fifth required section.
- The "Freshness tracking" paragraph at line 35 currently says "RPI working docs are disposable per-task artifacts, they do not need `Last verified` or `Relevant paths` fields." This contradicts the new requirement and must be rewritten in lockstep.
- `guides/doc-freshness.md` defines the inline-bold `Last verified:` / `Relevant paths:` convention used by onboarding/spike/shared-thoughts docs. The `git log --since=<date> -- <paths>` primitive is the staleness check.
- Existing exemplars in this repo: `docs/thoughts/spike-graveyard.md` and `docs/thoughts/failure-patterns.md`.
- Section name diverges from the convention: `## Files read` (research-activity framing), not `## Relevant paths` (forward-looking maintenance scope). The `Last verified:` line lives as the first line *inside* the section so date and paths stay co-located.
- The user's task description attributes the convention to "decision records" — `grep -r "Relevant paths" docs/decisions/` returns no matches; the actual exemplars are in `docs/thoughts/`. Acting on intent (the inline-bold convention), not the misattribution.

## Plan
Single commit. Three coordinated edits to `workflows/research-plan-implement.md`:
1. **Body sections (after Gotchas, ~line 78)** — add a new "Files read" bullet describing the section.
2. **Done-when checklist (lines 138–146)** — append a bullet requiring the literal `## Files read` heading + `Last verified: <YYYY-MM-DD>` first line + one path per line.
3. **Freshness tracking paragraph (line 35)** — rewrite to reflect the nuanced policy (research docs yes; plan/checkpoint/handoff still no).

## Invariants
- Four-line header structure (Goal · Problem framing · Project state · Task status) stays intact.
- Failure-pattern lookup sub-step's `Failure-pattern grep:` recording line stays intact.
- Done-when bullets remain independently verifiable.

## File map
- `workflows/research-plan-implement.md` — three coordinated edits in one commit (single step in the plan)

## Open questions
- `guides/doc-freshness.md`'s "Which documents to track" table will be partially out of sync after this change. The file is out of scope for this branch; flagging as a follow-up in the rewritten paragraph and in the plan's Risks section.
