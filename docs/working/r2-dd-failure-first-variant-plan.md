# Plan: Failure-First Generation variant for DD

- **Goal**: Add a third variant section to `workflows/divergent-design.md` that inverts the diverge step — candidate failure modes generated *before* candidate approaches, with approaches scored on which failure modes they cover.
- **Project state**: Surgical re-attempt of the previously rejected standalone failure-driven-design workflow · standalone (no upstream blocking branch) · not blocked.
- **Task status**: complete (variant added to `workflows/divergent-design.md`; top-level "When to use" pointer added at line 17; new section spans lines 372-453)

## Research

- `workflows/divergent-design.md` already hosts two variants — *Epistemic Reasoning* (lines 229-304) and *Double Diamond* (lines 306-369). The new variant must mirror their structural template (intro paragraph → when-to-use bullets → step modifications under `### Step modifications` or named subsections).
- RPI step 3 already contains a **Failure modes considered** premortem block (`workflows/research-plan-implement.md:194-211`) with `Failure mode / Guard` pairing. The new variant should align terminology with this block so the two artifacts can cross-reference when DD is invoked as an RPI sub-procedure.
- The existing top-level "When to use" list (lines 15-16) has one-line entries for each existing variant. The new variant needs a matching entry.
- Memory note `feedback_external_impact_priority.md` — optimize for external workflow impact, not introspective measurability. Variant value lies in being *invoked* by the user, not in producing introspection-friendly artifacts.

## Why the variant earns its keep (vs. just running standard DD harder)

Standard DD's matrix scores approaches against constraints *after* approaches are generated. When one failure has asymmetric cost (security breach, data loss, irreversible UX), a well-rounded slate of 8 approaches can share the same blind spot — the matrix then evaluates that blind spot as one weak column rather than as a discard criterion. The variant's surgical change is **failure generation precedes approach generation**, so each approach is authored to address an explicit failure list. Discard rules then escalate: ✗/⚠ on a *critical* failure is grounds for discard regardless of overall score. This is the cognitive frame shift the variant exists to enforce.

## Plan

### Step 1 — Add top-level "When to use" entry

Add one bullet under the existing variant pointers (after line 16) referencing the Failure-First variant. Keep the format identical to the Epistemic Reasoning and Double Diamond entries.

### Step 2 — Add the variant section at end of file

Place the new section *after* the Double Diamond variant. Use the Epistemic Reasoning section as the structural template (it preserves the 5-step shape; Failure-First also modifies particular steps rather than reframing the whole flow).

Section structure:
- Intro paragraph (1-2 sentences) — what the variant does and why.
- "Use this variant when:" bullet list (4 items).
- "Skip this variant when:" bullet list (3 items) — explicit so readers don't reach for it for low-stakes work.
- `### Step modifications` header.
- `#### 1a. Diverge (failures)` — generate 8-12 numbered failure modes with cost-class tags (soft / hard / critical) and a generation health check adapted from the main process.
- `#### 1b. Diverge (approaches)` — standard step 1 with the F-list visible as generation anchor.
- `#### 2. Diagnose` — failures enter constraint list with cost-class → hard/soft constraint mapping.
- `#### 3. Match and prune — failure coverage matrix` — matrix gains one column per failure; ✗/⚠ on a *critical* failure forces discard regardless of overall score.
- `#### 4. Tradeoff matrix and decision` — Core problem coverage column expands into explicit Failure coverage list; falsifiable hypothesis must name failure modes whose absence confirms the choice; stress-test loop-back rule for newly-surfaced failures.
- `#### 5. Document` — three record additions (Context note that variant was used, new *Failure modes considered* section pairing each F# with how the chosen approach addresses it, zero-tolerance Revisit trigger per critical failure).
- `### When this variant composes with others` — short subsection covering interactions with Epistemic Reasoning, Double Diamond, and RPI's premortem block. (Both existing variants implicitly compose but only Double Diamond shows it; making composition explicit here is high-leverage since the variant's value is amplified when chained.)

### Step 3 — Verify and commit

- Re-read the file end-to-end to confirm the new section is consistent with the surrounding voice and template.
- Conventional-commit message: `feat(divergent-design): add Failure-First Generation variant`.

## Failure modes considered

| Failure mode | Guard |
|-----|-----|
| Variant text drifts from RPI premortem terminology, breaking the cross-reference path | Align column naming (`Failure mode / Guard`) and cost-class language; explicitly mention the cross-reference in step 5 |
| New variant duplicates standard DD with cosmetic changes (no real cognitive shift) | Anchor the variant's value in the *generation-order inversion* + asymmetric discard rule; both are mechanically visible in steps 1a/1b and step 3 |
| Top-level "When to use" entry phrased to attract low-stakes decisions, causing variant overuse | "Skip this variant when:" block lists three explicit non-fits, including the small-reversible-trusted-code case |
| Variant section becomes longer than Epistemic Reasoning section, signaling over-engineering | Cap roughly at Epistemic Reasoning's length; skip the worked-example block (the existing Epistemic section also skips it; only Double Diamond has one) |

## Risks

- The variant could be perceived as redundant with RPI's premortem block. Mitigation: the premortem block evaluates failures *against an already-chosen plan*; this variant generates failures *to drive candidate generation*. Different cognitive moment, different artifact.
- Memory note flags that failure-driven-design was previously rejected as a standalone workflow. The surgical form (variant of an existing workflow, no new top-level file) directly addresses that rejection.
