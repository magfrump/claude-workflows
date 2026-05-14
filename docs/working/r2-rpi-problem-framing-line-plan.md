Goal: Add a Problem framing line to the RPI research-doc header so the framing choice — and the alternative the researcher discarded — is visible before any downstream work depends on it.
Problem framing: Research docs currently commit to a Goal in one line without surfacing the framing move that produced it; discarded framings live (if anywhere) in body prose where re-readers won't notice them. Considered and discarded: "the issue is goals are too vague" — but vagueness isn't the problem; an *unexamined* framing can be perfectly crisp and still wrong.
Project state: Round-2 edit to `workflows/research-plan-implement.md` step 2; sibling to the round-2 project-state cite-line that just landed; not blocked (cite: 87a0afa).
Task status: in-progress (plan drafted, implementation next).

Research: docs/working/r2-rpi-problem-framing-line-research.md

## Approach

Surgical edit to `workflows/research-plan-implement.md`, focused on step 2 (the research doc header) with knock-on rewording in steps 3 and 5 to keep the cross-references coherent.

1. **Step 2**: Grow the research-doc header from three lines to four by inserting a **Problem framing** bullet between Goal and Project state. Update the header preamble ("three lines" → "four lines"), the "three named anchors" prose, and the first Done-when item. Add one new Done-when item that audits for a named-and-discarded alternative.
2. **Step 3**: Rephrase "the same three-line header used by research docs" so the plan-doc header (which stays at three lines) inherits the three *shared* anchors by name, not by total line count, and explicitly notes that Problem framing lives only in the research doc.
3. **Step 5**: Replace the positional "three-line header (Goal · Project state · Task status)" phrasing with a named-anchors phrasing that's robust to the asymmetry between research (4 lines) and plan (3 lines). Update its Done-when items the same way.

Leave step 6's freshness check untouched: it reads the plan doc's Project state line, and the plan doc still has three lines, so its "third line of the plan doc's three-line header" wording remains (pre-existing inaccuracy about line position is out of scope).

## Steps

1. **Edit step 2 header definition** (`workflows/research-plan-implement.md` lines 64–70). Change "three lines" → "four lines" in the preamble; insert a Problem framing bullet between Goal and Project state with the spec text below; update the "three named anchors" sentence to "four named anchors" and rewrite the trailing clause to enumerate framing as the second anchor.

   Spec text for the new bullet:
   > **Problem framing**: One sentence stating the problem this loop addresses, followed by `Considered and discarded: <one alternative framing the researcher considered and rejected>`. The discarded alternative is a different way the same situation could have been read (e.g., problem: "users can't export reports offline"; discarded: "the reports page is too slow"). Naming an alternative that was explicitly rejected forces the framing choice to be visible rather than implicit — a stale problem framing is the most expensive failure to discover late, because Goal, plan, tests, and implementation are all shaped by it. A line that can't name a plausible discarded alternative is the diagnostic that the framing wasn't actually examined; surface that gap here rather than defaulting to "Considered and discarded: none."

2. **Edit step 2 Done-when checklist** (line 116). Update the first item to "four-line header (Goal · Problem framing · Project state · Task status)." Add a new item: "Problem framing line names an alternative framing that was considered and discarded, not a placeholder."

3. **Edit step 3 header introduction** (line 125). Rephrase from "the same three-line header used by research docs (see step 2)" to a wording that names the three shared anchors (Goal · Project state · Task status) and notes that the research doc's Problem framing line is *not* repeated on the plan — framing is established once in research and inherited via the `Research:` cross-link. The plan-doc header preamble at line 127 ("three lines") stays as-is, and the plan-doc Done-when at line 266 stays as-is, because the plan doc still has three lines.

4. **Edit step 5 (Self-check) prose** (line 302). Replace "the three-line header (Goal · Project state · Task status) at the top of both the research and plan docs" with a wording that names the shared three anchors on both docs and the additional Problem framing line on the research doc. Update the Done-when items at lines 305–306 the same way.

5. **Commit**: `feat(rpi): require Problem framing line on research-doc header`.

## Implementation order

Sequential: `1 → 2 → 3 → 4 → 5`. All edits touch the same file, the commit covers all four edits, and the wording of later edits depends on choices made in earlier ones (e.g., step 4's named-anchors phrasing should mirror step 1's "four named anchors" sentence). No parallelism.

## Size estimate

- Step 1: ~7 lines added to step 2 (one new bullet + preamble and prose updates).
- Step 2: ~2 lines added to step 2's Done-when checklist.
- Step 3: ~2 lines reworded in step 3's introduction.
- Step 4: ~2 lines reworded in step 5.
- Step 5: commit.
- Total: ~13 lines added/reworded in `workflows/research-plan-implement.md` (currently 453 lines → ~466 lines, well under the 500-line guideline).

## Estimated context cost

Research ~9k, Implementation ~7k, Review ~4k. Small workflow edit, similar to the cite-line predecessor; totals on the low end of the typical range.

## Actual context cost (post-implementation)

Research ~10k, Implementation ~8k, Review ~3k. In line with the estimate; the doc became slightly longer than planned because the step-3 rephrase needed more words than expected to clarify the asymmetry, but no surprises that warranted pausing.

## Test specification

| Test case | Expected behavior | Level | Diagnostic expectation |
|-----------|------------------|-------|----------------------|
| Re-read step 2's header definition | Header preamble says "four lines"; a Problem framing bullet sits between Goal and Project state; the "named anchors" prose says "four" and enumerates framing | Characterization (doc-level) | If any of these is missing, the re-read surfaces it immediately |
| Re-read step 2's Done-when checklist | The first item names the four-line header; a separate item audits for a named-and-discarded alternative | Characterization (doc-level) | Two distinct checks; missing either fails the self-audit |
| Re-read step 3's introduction | Plan-doc header still defined as three lines (Goal · Project state · Task status); the wording no longer says "same three-line header as research docs"; the asymmetry (research grows to 4, plan stays at 3) is explicitly noted | Characterization (doc-level) | If step 3 still implies plan-doc parity with the research-doc header, the cross-reference is broken |
| Re-read step 5 (Self-check) prose and Done-when | The self-check names the three shared anchors plus the research-only Problem framing line; positional "three-line header" phrasing has been replaced with named anchors | Characterization (doc-level) | If step 5 still calls the research header "three-line," it will mislead a re-reader |
| Both this round's research and plan docs include a Problem framing line that names a discarded alternative | Demonstrates the requirement in the round that ships it | Characterization (doc-level) | Shows the pattern in use, not just defined; mirrors the cite-line round's example-in-shipping-doc convention |
| Step 6's freshness-check wording about "the third line of the plan doc's three-line header" | Unchanged; the plan doc still has three lines, so the positional reference remains valid (the pre-existing line-position inaccuracy is out of scope) | Characterization (doc-level) | Confirms the scope boundary — we did not edit step 6 |

Doc-level characterization tests — re-reads, not runnable code. No test framework applies; verification is "read the file and confirm the spec is unambiguous."

## Failure modes considered

| Failure mode | Guard |
|---|---|
| Authors write a Problem framing line that names *no* discarded alternative (treating it as a slot to fill rather than a framing-accountability move) | Spec text in step 1 explicitly calls this out: "A line that can't name a plausible discarded alternative is the diagnostic that the framing wasn't actually examined." Done-when item from step 2 audits for it. Together they make the empty-placeholder case visible at re-read. |
| Step 3 silently drifts when step 2 grows: a future edit re-syncs the plan-doc header to the research-doc header without noticing the asymmetry, importing Problem framing into the plan doc | Step 3's introduction (after this round) explicitly names the asymmetry — Problem framing lives only in research, plan inherits the three shared anchors. A future re-sync edit has to actively delete that note, which is a louder action than passively re-aligning the spec. |
| Step 5 (Self-check) becomes unclear about which doc has how many lines, leading to a re-read that misses the framing line on the research doc | Step 5's rewording (step 4 of this plan) names the shared anchors and the research-only Problem framing line explicitly, instead of using a positional "three-line" shorthand that's now ambiguous. The Done-when items mirror the prose. |
| Step 6's freshness check ("the third line of the plan doc's three-line header") becomes misleading because someone assumes the *research* doc is meant too | Step 6's wording specifically references "the *plan* doc's three-line header" — it doesn't mention the research doc's header. The plan doc stays at three lines after this round, so the positional reference remains accurate for what step 6 actually reads. Left untouched on purpose to minimize blast radius. |

## Risks

- **Wording risk**: The Problem framing spec needs to be tight enough to fit the surgical-edit pattern (no more than the cite-line precedent) but explicit enough that authors don't degrade it to a goal-restatement. Mitigation: the spec text leads with the format string (`<problem sentence>. Considered and discarded: <alt>`), follows with one example, and one sentence on the empty-placeholder diagnostic. Cap added prose at ~7 lines.
- **Step 5 phrasing risk**: replacing positional "three-line" wording with named anchors makes the self-check more robust but also longer. Mitigation: keep the rewording to one sentence; rely on the bullet definitions in steps 2 and 3 for the prose, not the self-check.
- **Adoption risk**: this edit creates an asymmetry between research-doc header (4 lines) and plan-doc header (3 lines). A reader skimming step 3 might miss the asymmetry and add Problem framing to plan docs anyway. That's a minor failure mode (false positive, not false negative — over-application doesn't break anything; the framing line on a plan doc is just noise inherited from research). Accept it; the alternative (importing framing into the plan doc too) doubles the spec footprint for a marginal benefit.
- **Pre-existing step 6 inaccuracy** (Project state is line 2, not line 3, of the plan-doc header): out of scope. Leaving it noted in the research doc's Gotchas so a future round can correct it deliberately.
