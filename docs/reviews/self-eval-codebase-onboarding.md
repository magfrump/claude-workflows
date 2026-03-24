# Self-Evaluation: codebase-onboarding

**Target:** `workflows/codebase-onboarding.md` | **Type:** Workflow | **Evaluated:** 2026-03-23
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | Evaluating whether an onboarding doc accurately describes a codebase requires comparing output to ground truth — essentially a domain expert reviewing the doc against the actual code. Structural compliance (section presence) is testable, but that's a thin proxy for quality. Workflows are inherently harder to test than skills, and this one's output is a prose document whose correctness depends on the specific codebase. |
| Trigger clarity | Strong | "You just cloned a repo and need to understand it before doing any work" and "switching to a project you haven't touched in months" are specific, unambiguous triggers. No other workflow covers the same pre-task orientation role. The freshness check mechanism provides a clear re-trigger condition. No confusing overlap with RPI (which is task-scoped) or task decomposition (which assumes you already understand subsystems). |
| Overlap and redundancy | Strong | No other workflow or built-in tool provides structured codebase orientation. RPI's research phase is task-scoped, not broad. Task decomposition assumes existing knowledge of subsystems. The built-in Explore agent does quick searches but doesn't produce a persistent orientation document with architecture maps, flow traces, and tracked unknowns. The workflow is complementary to others rather than competing. |
| Test coverage | Weak | No test cases exist in `test/`. No example onboarding output artifacts exist in `docs/reviews/`. Git history shows the workflow was referenced in commits (feat adding pivot guidance, freshness tracking, complementary skills decision) but no evidence of the workflow being run to produce an actual `docs/working/onboarding-*.md` artifact in this repo. The full-evaluation.md entry notes "Working docs in this repo suggest some usage" but no concrete artifacts were found. Probationary per rubric. |
| Pipeline readiness | Strong | Standalone viable — useful when invoked directly with no pipeline dependencies. Also serves as a documented feeder into RPI ("← From Onboarding" pivot in RPI) and task decomposition (architecture map aids sub-investigation identification). No `requires` block needed since this is a top-level workflow. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: Provides a 7-step structured process for orienting to an unfamiliar codebase: identify entry points, map subsystems, trace key flows, catalog conventions, document unknowns, produce an orientation doc, and validate with the team. The key differentiator is the "Known Unknowns" section — explicitly tracking gaps in understanding — and the living-document approach with freshness tracking.

**What ad-hoc exploration achieves**: Without this workflow, onboarding is unstructured: reading files semi-randomly, following imports, maybe reading the README. A developer would likely identify entry points and major directories but miss: systematic flow tracing, convention cataloging, and most importantly, explicit tracking of what they *don't* understand. The "Known Unknowns" section and the freshness-check mechanism have no ad-hoc equivalent.

**What built-in tools cover**: The Explore agent can search code quickly but doesn't produce a persistent, structured orientation document. It handles individual queries ("how do API endpoints work?") but doesn't compose them into a coherent mental model with tracked gaps.

**Questions for the reviewer**:
- How much of the workflow's value comes from the structured process vs. the artifact it produces? Would you reference the onboarding doc in later sessions, or is the value mainly in forcing thorough exploration?
- Is the "Known Unknowns" section genuinely useful in practice, or does it become stale too quickly to matter?
- Under what conditions is the gap largest — very large codebases? Unfamiliar languages/frameworks? Returning after absence?

### User-Specific Fit

**Triggering situations**:
- Cloning a new repo for the first time
- Returning to a project after months of inactivity
- Onboarding a new team member to a codebase
- Starting RPI research but feeling lost about where to even begin

**Questions for the reviewer**:
- How often do you start working on a genuinely unfamiliar codebase?
- When you return to a project after absence, do you feel the need for structured re-orientation, or is a quick `git log` sufficient?
- The board game digitization project was noted as relatively new — did you use or wish you had used this workflow there?
- Would you actually remember to reach for this workflow, or would you jump straight into RPI and do ad-hoc exploration?

### Condition for Value

**Stated or inferred conditions**:
- User works across multiple projects (not a single long-lived codebase)
- Projects are complex enough that structured orientation provides value over just reading the README
- The orientation document is actually maintained as a living document (freshness tracking is used)

**Automated findings**:
- RPI workflow that this feeds into: EXISTS and is well-established
- Task decomposition workflow that benefits from architecture maps: EXISTS
- Freshness tracking guide referenced by the workflow: EXISTS (`guides/doc-freshness.md`)
- No actual `docs/working/onboarding-*.md` artifacts found — the living-document value proposition is UNTESTED

**Questions for the reviewer**:
- Are the conditions met today? Do you work across enough projects for this to be regularly useful?
- Has the freshness-check mechanism ever been used in practice? If the onboarding doc always goes stale without being refreshed, the "living document" framing overpromises.
- Is this an investment in a pattern (reusable orientation docs) or a one-time process (the exploration is the value, not the artifact)?

### Failure Mode Gracefulness

**Output structure**: The workflow produces a structured Markdown document with sections for entry points (file paths), architecture map (subsystem descriptions with dependencies), key flows (numbered step sequences with file paths), conventions, and known unknowns. The structured format makes omissions somewhat visible — an empty or thin section is noticeable.

**Potential silent failures**:
- **Wrong mental model**: The orientation doc describes subsystem relationships incorrectly (e.g., "A calls B" when actually "A calls C which wraps B"). This looks authoritative and could lead to wrong assumptions in subsequent RPI sessions.
- **False completeness**: The Known Unknowns section is empty not because everything is understood, but because the exploration missed entire subsystems. The doc looks complete but has blind spots.
- **Stale conventions**: Conventions documented during onboarding may change. If the doc isn't refreshed, new code may follow outdated patterns.

**Pipeline mitigations**: The validation gate (step 7: review with someone familiar) catches wrong mental models if a reviewer is available. The freshness check catches staleness if actually used. No upstream fact-checking applies.

**Questions for the reviewer**:
- Have you experienced a wrong mental model from onboarding that persisted into implementation? How costly was it?
- Is the validation gate (step 7) realistic? Do you typically have someone available to review the onboarding doc?
- Which failure mode concerns you most: wrong subsystem descriptions, missed unknowns, or stale conventions?

---

## Key Questions

1. **Living document or one-time process?** The workflow frames the onboarding doc as a living reference with freshness tracking, but no evidence exists of the document being maintained over time. If the value is primarily in the exploration process rather than the artifact, the freshness tracking machinery may be unnecessary complexity.

2. **Does the Known Unknowns section survive contact with reality?** This is the workflow's most distinctive feature — explicitly tracking gaps. But in practice, do unknowns get resolved and updated, or does the section become a stale list that nobody references? The answer determines whether this is a genuinely unique analytical move or just good intentions.

3. **Test coverage is the critical gap.** Both testability investment and test coverage score Weak. The workflow has never produced a verified output artifact in this repo. Running it on this repo (or another real project) and examining the output quality would be the single highest-value next step for building confidence.
