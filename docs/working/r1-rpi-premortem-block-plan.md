Goal: Add an optional "Failure modes considered" subsection to the plan template in `workflows/research-plan-implement.md`, required when a plan has >5 steps OR touches a trust boundary.
Project state: Round-1 edit to the RPI plan template; standalone (no sibling round); not blocked (cite: 12aa236).
Task status: in-progress (plan drafted, implementing next).

Research: docs/working/r1-rpi-premortem-block-research.md

## Approach

Three-point edit to step 3 of `workflows/research-plan-implement.md`:

1. Add a new top-level body-section bullet, "Failure modes considered", between the existing "Test specification" bullet (line 174) and the existing "Risks" bullet (line 194). Model its structure on the "Implementation order" bullet (line 144): opening sentence → "When required vs. optional" → "Format" → "Worked example", with the worked example reusing the same 7-step API endpoint plan that the Implementation order bullet already uses, so the reader carries one mental model across both sections.
2. Add a parallel Done-when checklist item to step 3's "Done when..." block (lines 247-255), shaped like the existing Implementation order Done-when item, calling out the conditional trigger explicitly so a re-reader can self-audit without flipping back to the body.
3. Note in the new section's spec text that the brief's "step 4" reference was resolved as a miscount — the plan template lives only in step 3, so the subsection lands there. (Documented in research; not added to the spec text itself, which should be clean of meta-commentary.)

Step 4 (Annotate) is deliberately untouched: it is the human review gate, not a template location. Adding a subsection there would be incoherent.

## Steps

1. Edit `workflows/research-plan-implement.md`: insert a new "Failure modes considered" bullet between the current "Test specification" bullet and the current "Risks" bullet. The bullet includes: opening sentence (~3 lines), "When required vs. optional" sub-bullet (~5 lines), "Format" sub-bullet (~3 lines), "Worked example" sub-bullet with a 4-row two-column table reusing the 7-step API endpoint plan (~12 lines including table). Total ~25 lines.
2. Edit `workflows/research-plan-implement.md` step 3 "Done when..." block: insert one new checklist item naming the Failure modes block and its trigger conditions. ~1 line.
3. Commit: `feat(rpi): add Failure modes considered subsection to plan template`.

## Implementation order

Sequential: `1 → 2 → 3`. Both edits touch the same file in adjacent regions; the commit covers both. No parallelism.

## Size estimate

- Step 1: ~25 lines added to the plan template body in step 3.
- Step 2: ~1 line added to step 3's Done-when checklist.
- Total: ~26 lines of prose added to `workflows/research-plan-implement.md` (currently 433 lines → ~459 lines, under the 500-line guideline).

## Estimated context cost

Research ~10k, Implementation ~8k, Review ~4k. Small-to-medium workflow edit — one new body-section bullet plus one checklist item, no cross-file changes.

## Actual context cost (post-implementation)

Research ~9k, Implementation ~7k, Review ~3k. In line with the estimate; no surprises in the edit region.

## Test specification

| Test case | Expected behavior | Level | Diagnostic expectation |
|-----------|------------------|-------|----------------------|
| Re-read step 3 of the modified file | Body-section list now includes "Failure modes considered" between "Test specification" and "Risks" with all four sub-bullets (purpose, When required vs. optional, Format, Worked example) | Characterization (doc-level) | If any sub-bullet is missing or the placement is wrong, the re-read surfaces it |
| Re-read step 3's Done-when checklist | A distinct checklist item names the Failure modes block and its trigger conditions (>5 steps OR trust boundary) | Characterization (doc-level) | If no item names the block or the trigger conditions are absent, the checklist fails its self-audit purpose |
| Re-read the worked example table | Contains 3-5 rows; each row names a specific failure mode and a specific guard (test case from Test specification OR structural choice); rows reuse the 7-step API endpoint plan's identifiers (`User.email_verified`, `Session.last_seen_at`, `POST /verify-email`, etc.) | Characterization (doc-level) | If the example is generic (no plan-specific identifiers) or any row lacks a guard, the example fails to convey the pairing requirement |
| Read step 4 (Annotate) | Unchanged; the brief's "step 4" reference is resolved by placing the subsection in step 3 where the plan template lives | Characterization (doc-level) | If step 4 was modified, that's a scope violation per the file scope constraint and the placement reasoning in research |

These are doc-level characterization tests — re-reads, not runnable code. No test framework applies; verification is "read the file and confirm the spec is unambiguous."

## Failure modes considered

| Failure mode | Guard |
|-----|-----|
| Subsection lands in step 4 (Annotate) instead of step 3 (Plan), where there is no template to attach to | Placement decision documented in research's Invariants section; plan's Approach explicitly names step 3 line ranges and Step 4's "deliberately untouched" status |
| Worked example is generic ("failure A → test B") and fails to convey the pairing requirement | Test specification's third row asserts the example must reuse the 7-step plan's identifiers; the plan's Approach repeats this requirement |
| Trigger-condition wording drifts from the Implementation order block ("more than 5 steps" vs. ">5") | Research's Invariants section calls out the mirror requirement; the spec text in step 1 uses the exact phrase "more than 5 steps" |
| Trust-boundary trigger gets a second, divergent definition instead of pointing at the existing security-reviewer enumeration | Research's Gotchas section names the canonical list ("auth, input handling, crypto, trust boundaries, file I/O, network calls, serialization"); the spec text reuses that list verbatim |

Four entries, within the 3-5 range. Each guard is something this plan already commits to (a research line, a test case, or specific spec wording) — not aspirational.

## Risks

- **Bullet bloat**: The new section adds ~25 lines to step 3, which is already the longest step in the workflow. Mitigation: keep the opening sentence to ~3 lines, lean on the worked example to do the explanatory work instead of more prose, and reuse the existing 7-step plan so no new mental model is introduced.
- **Trigger collision with Risks**: A reader might conflate Failure modes with Risks and drop one in favor of the other. Mitigation: the spec text explicitly contrasts the two — Risks is open-ended scrutiny, Failure modes is paired (specific failure ↔ specific guard). The pairing requirement is what makes Failure modes a distinct artifact.
- **3-5 cap interpretation**: Authors may treat the cap as advisory and produce 8-entry tables. Mitigation: state the range as a soft requirement in the spec text and gloss the reasoning ("a premortem with 1-2 entries is performative; one with 10+ is unfocused").
- **Trust-boundary trigger ambiguity**: "Trust boundary" is term-of-art; some authors won't recognize it. Mitigation: enumerate the canonical list inline (auth, input handling, crypto, file I/O, network/IPC boundaries, serialization) so no second definition needs to be learned.
