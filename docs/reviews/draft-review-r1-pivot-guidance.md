# Draft Review: Workflow Pivot Guidance

**Branch:** feat/r1-workflow-pivot-guidance
**Reviewed:** 2026-03-23
**Status:** CONDITIONAL PASS

## Summary

This branch adds "When to pivot" subsections to four core workflow documents (RPI, DD, spike, codebase-onboarding), documenting the most common inter-workflow transitions and how to carry artifacts forward. The guidance is accurate, well-placed, and genuinely useful for reducing wasted work during workflow transitions. A few structural inconsistencies and coverage gaps keep this from a full pass.

## Factual Issues

No factual errors found. All cross-references are accurate:

- RPI's "see step 2 for signals" correctly points to the Research step, which contains the "Signals that you've hit a design decision" bullet list.
- Spike's "see step 4" correctly points to "Record the findings," which contains the RPI seed template.
- DD's reference to "DD's diagnosis step (step 2)" correctly maps to the "Diagnose" step.
- The description of artifact handoff (research doc invariants feeding into DD diagnosis, spike RPI seed feeding into RPI research) matches the actual workflow structures.

## Structural Critique

**Inconsistent arrow notation.** RPI and spike use both outbound arrows ("-> Spike") and inbound arrows ("<- From Spike") to describe the same transitions from both sides. DD and codebase-onboarding do the same but with fewer entries. The notation is intuitive but the coverage is asymmetric:

- RPI lists 4 pivot paths (2 outbound, 2 inbound).
- DD lists 3 pivot paths (1 inbound, 2 outbound).
- Spike lists 3 pivot paths (1 outbound, 2 inbound).
- Codebase-onboarding lists 2 pivot paths (2 outbound, 0 inbound).

This means the same transition is sometimes described from both ends (good for discoverability) but not always. For example, DD -> Spike is described in DD, and Spike <- From DD is described in spike, so that path is covered from both sides. But onboarding -> DD is only described in onboarding, not in DD <- From Onboarding. This is a minor inconsistency but could cause confusion about whether certain paths are supported.

**Placement is good.** The "When to pivot" section sits between "When to use" and the process steps (or working documents) in each file. This is the right location -- a reader deciding whether to use a workflow sees the pivot options before committing to the process.

**Prose is tight.** Each bullet is 1-2 sentences with a concrete artifact handoff instruction. No filler.

## What Works Well

1. **Artifact continuity is the central theme.** Every pivot path specifies what to carry forward ("carry the research doc's invariants," "load its RPI seed section," "reference it from the plan; don't duplicate the rationale"). This is the most valuable aspect -- it prevents the common failure mode of starting from scratch after a workflow switch.

2. **Bidirectional coverage for the most common paths.** The RPI <-> Spike and RPI <-> DD transitions are described from both sides, so a reader finds guidance regardless of which document they are currently reading.

3. **The guidance is opinionated about what NOT to do.** "Don't re-derive what the spike already learned" and "don't duplicate the rationale" are the kind of anti-pattern warnings that prevent real waste.

4. **Lightweight change.** At 24 new lines across 4 files, this adds genuine value without bloating the workflow docs.

## Actionable Guidance

**Priority 1 -- Add missing inbound path to DD from onboarding.**
Codebase-onboarding lists "-> DD" as a pivot, but DD has no corresponding "<- From Onboarding" entry. Add one to DD's pivot section for symmetry. Something like: "<- From Onboarding: If the architecture map reveals design conflicts, carry the onboarding doc's architecture map and constraints into DD's diagnosis step."

**Priority 2 -- Consider whether task-decomposition needs pivot guidance.**
Task-decomposition is one of the seven workflows listed in CLAUDE.md but was not updated. It has natural pivot relationships: it feeds into RPI (step 5 explicitly says "follow the normal research-plan-implement workflow"), and onboarding's architecture map could feed into task-decomposition's step 1 (identifying independent sub-investigations). If this omission is intentional (scope control), note it in the summary doc. If not, add pivot subsections to task-decomposition as well.

**Priority 3 -- Consider adding pr-prep and user-testing-workflow pivot guidance or explicitly scoping them out.**
These two workflows also appear in CLAUDE.md's list. pr-prep is a natural outbound target from RPI (step 6 already says "proceed to the pr-prep workflow if opening a PR") and could benefit from a "<- From RPI" inbound entry. If these are intentionally excluded, that is fine, but a note in the summary doc explaining the scoping decision would prevent future questions.

**Priority 4 -- Normalize symmetry or document the asymmetry convention.**
Either ensure every pivot path is documented from both sides (preferred for discoverability) or add a brief note to the summary doc explaining that outbound paths are always documented but inbound paths are only documented for the most common transitions. Either approach is fine; the current implicit convention is the problem.

**Priority 5 -- The summary doc is thin.**
`docs/working/summary-workflow-pivot-guidance.md` is a single sentence. If this is meant as an RPI-style working doc, it could benefit from listing which pivot paths were added and which workflows were intentionally excluded. This would help future sessions understand the scope of the change without re-reading all four diffs.
