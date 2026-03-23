# API Consistency Review

**Scope:** `skills/code-review.md` (new orchestrator) checked against `skills/draft-review.md` and `skills/matrix-analysis.md` (established orchestrators)
**Reviewed:** 2026-03-23
**Fact-check input:** Stage 1 report (17 verified, 3 mostly accurate, 0 incorrect, 1 unverifiable)

---

## Baseline Conventions

Observed by reading `skills/draft-review.md` (the first orchestrator) and `skills/matrix-analysis.md` (the second orchestrator):

### Frontmatter

| Convention | draft-review | matrix-analysis |
|---|---|---|
| Fields | `name`, `description` | `name`, `description` |
| `description` format | Multiline `>` scalar | Multiline `>` scalar |
| `requires` block | Not present | Not present |
| Description content | What it does, pipeline stages, trigger phrases | What it does, pipeline stages, trigger phrases |

Neither existing orchestrator has a `requires` block. The `requires` convention exists only on critic/fact-check skills.

### Document Structure

Both orchestrators follow this section order:

1. H1 title: `# [Name] Orchestrator`
2. Intro paragraph (role statement + deliverables summary)
3. `---` separator
4. `## Mandatory Execution Rules` (with preamble: "These rules are absolute...")
5. `---` separator
6. Pre-pipeline setup section (discovery, planning, user communication)
7. `---` separator
8. `## The Pipeline` (draft-review) / Stages under `## Stage N:` (matrix-analysis)
9. `---` separator
10. `## Deliverable 1:` (chat synthesis)
11. `---` separator
12. `## Deliverable 2:` (structured document)
13. `---` separator
14. `## Output Location(s)`
15. `---` separator
16. `## Important Reminders` (bulleted list)

### Dispatch Tool

- draft-review: "Task tool"
- matrix-analysis: "Agent tool"

The orchestrated-review pattern (`patterns/orchestrated-review.md`) explicitly notes this variance and says to use "sub-agent" as the consistent term regardless of underlying tool.

### Terminology

- draft-review: "sub-agents" (hyphenated throughout)
- matrix-analysis: "sub-agents" in most places, "subagent" in `subagent_type` parameter references

### Pipeline Naming

- draft-review: `Stage 1: Fact-Check`, `Stage 2: Critic Agents`, `Stage 3: Synthesize and Produce Outputs`
- matrix-analysis: `Stage 1: Setup`, `Stage 2: Evaluation`, `Stage 3: Synthesize and Produce Outputs`

Stage 3 naming is identical across both. Stage 1/2 names are domain-specific.

### CHECKPOINT Pattern

Both use an identical pattern after each stage:

> **CHECKPOINT:** Wait for ALL [agents] to return results. Count the results. Do you have the expected number? If yes, proceed. If not, STOP and tell the user...

### Deliverable Naming

- draft-review: `## Deliverable 1: Freeform Chat Synthesis` / `## Deliverable 2: Verification Rubric Document`
- matrix-analysis: `## Deliverable 1: Freeform Chat Synthesis` / `## Deliverable 2: Matrix Document`

### Output Location Section

- draft-review: `## Output Locations` (plural)
- matrix-analysis: `## Output Location` (singular)

Both include: save path, create-directory instruction, overwrite-on-rerun instruction, link-at-end instruction.

### Important Reminders

Both end with `## Important Reminders` containing a bulleted list of bold-lead items. Common items across both:
- Sub-agents cannot read filesystem
- All agents of same stage run in parallel
- Don't fill gaps yourself / be honest
- Designed for re-runs

---

## Findings

### 1. Pre-pipeline section heading deviates from both baselines

**Severity:** Inconsistent
**Location:** `skills/code-review.md:51`

Draft-review uses `## Before You Begin: Communicate the Plan`. Matrix-analysis uses `## Stage 1: Setup` (folding setup into the pipeline stages). Code-review uses `## Before You Begin` (without the subtitle). This is a minor structural divergence -- the colon-subtitle convention from draft-review is dropped, and the section is not folded into the pipeline as matrix-analysis does. The result is a hybrid that doesn't match either baseline.

**Recommendation:** Use `## Before You Begin: Determine Scope and Select Critics` to match draft-review's colon-subtitle convention, or fold the setup into Stage 1 as matrix-analysis does. Either is fine; the current heading splits the difference.

---

### 2. Intro paragraph adds a cross-reference line not present in baselines

**Severity:** Informational
**Location:** `skills/code-review.md:21`

Code-review includes: `This workflow follows the [orchestrated review pattern](../patterns/orchestrated-review.md).` Neither draft-review nor matrix-analysis includes this line. The orchestrated-review pattern doc itself says new workflows "should" add this cross-reference, so code-review is following the pattern doc's guidance. However, the existing orchestrators have not been updated to include it, creating an inconsistency in the other direction.

**Recommendation:** This is a good addition. For full consistency, add the same cross-reference line to draft-review and matrix-analysis.

---

### 3. Dispatch tool: code-review uses "Agent tool", matching matrix-analysis but not draft-review

**Severity:** Inconsistent
**Location:** `skills/code-review.md:31`

Code-review uses "Agent tool" throughout, matching matrix-analysis. Draft-review uses "Task tool." The fact-check findings (Claim 22) noted this: code-review uses "Agent tool" while draft-review uses "Task tool." The orchestrated-review pattern accommodates this variance but the decision doc (002) does not note the difference.

This is a known inconsistency across the orchestrator family, not introduced by code-review specifically. Code-review made a consistent choice (matching the newer orchestrator, matrix-analysis) rather than the older one.

**Recommendation:** Document the tool name variance in the decision doc or in the orchestrated-review pattern's existing terminology note. No change needed in code-review itself -- it made the more current choice.

---

### 4. Mandatory Execution Rules: identical structure, minor wording differences

**Severity:** Minor
**Location:** `skills/code-review.md:28-48`

The five rules follow the exact same structure as both baselines. Rule 1 uses "Agent tool" (see finding #3). Rules 2-5 are functionally identical to both baselines with appropriate domain substitutions (e.g., "code fact-check" instead of "fact-check", "code review rubric" instead of "verification rubric"). The preamble ("These rules are absolute. Do not deviate from them under any circumstances.") is identical.

This section is well-aligned.

---

### 5. Pipeline stage naming is consistent with the domain-specific convention

**Severity:** Informational
**Location:** `skills/code-review.md:129-184`

Code-review uses: `Stage 1: Code Fact-Check`, `Stage 2: Critic Agents`, `Stage 3: Synthesize and Produce Outputs`. Stage 2 and 3 names exactly match draft-review. Stage 1 is domain-specific ("Code Fact-Check" vs "Fact-Check"), following the established convention.

No issues.

---

### 6. Fact-Check Gate section matches draft-review convention

**Severity:** Informational
**Location:** `skills/code-review.md:146-158`

Code-review includes a Fact-Check Gate with the same three-option structure as draft-review (Continue / Fix first / Skip critics). Terminology adapts appropriately ("Fix first" instead of "Revise first" since code changes are fixes, not revisions). The `--no-gate` flag is preserved. This is well-aligned.

---

### 7. Deliverable 1 heading drops "Freeform" qualifier

**Severity:** Minor
**Location:** `skills/code-review.md:190`

Draft-review: `## Deliverable 1: Freeform Chat Synthesis`. Matrix-analysis: `## Deliverable 1: Freeform Chat Synthesis`. Code-review: `## Deliverable 1: Chat Synthesis`. The word "Freeform" is dropped. This is a small heading inconsistency.

**Recommendation:** Add "Freeform" back: `## Deliverable 1: Freeform Chat Synthesis`.

---

### 8. Deliverable 2 naming follows the established pattern

**Severity:** Informational
**Location:** `skills/code-review.md:223`

Code-review: `## Deliverable 2: Code Review Rubric`. This follows the pattern of `## Deliverable 2: [Domain-Specific Name]` (draft-review: "Verification Rubric Document", matrix-analysis: "Matrix Document"). Consistent.

---

### 9. Rubric format adds columns not present in draft-review's rubric

**Severity:** Informational
**Location:** `skills/code-review.md:237-281`

Code-review's rubric adds `Domain` and `Location` columns to the red tier table, and `Domain` and `Source` columns to the amber tier table. Draft-review's rubric has simpler tables. These additions are appropriate for code review (where file:line locations and domain attribution matter) and don't violate any convention -- they extend the format for the domain. The tier names, emoji usage, status line format, and pass/fail criteria are all identical to draft-review.

---

### 10. Output Location section uses plural form

**Severity:** Minor
**Location:** `skills/code-review.md:317`

Code-review uses `## Output Locations` (plural), matching draft-review. Matrix-analysis uses `## Output Location` (singular). Code-review made the right choice -- it has multiple output files (rubric + individual critic reviews), so plural is appropriate and matches the established convention from draft-review.

---

### 11. Important Reminders section is present and well-structured

**Severity:** Informational
**Location:** `skills/code-review.md:339-352`

Code-review includes `## Important Reminders` with 8 bold-lead bullet items. Draft-review has 5 items; matrix-analysis has 6 items. Code-review preserves all common items from both baselines and adds domain-specific ones:
- "Pass scope, not diffs" (new, specific to code review's approach)
- "Contextual critics are advisory" (new, specific to auto-selection feature)
- "Fact-check report size management" (new, context budget optimization)

The style (bold lead phrase, explanatory sentence) is identical to both baselines.

---

### 12. Unified Severity Mapping is a new convention not in either baseline

**Severity:** Informational
**Location:** `skills/code-review.md:286-296`

Code-review introduces a `### Unified Severity Mapping` section with a table mapping individual critic severity levels to rubric tiers, plus an `### Escalation Rule` section. Neither baseline has this -- draft-review's tier assignment is based on fact-check verdicts and critic convergence, not on mapping from critic-specific severity scales. This is a necessary addition for code review (where critics have their own severity levels that must be normalized) and is well-designed. It establishes a new convention that future orchestrators with heterogeneous critics should follow.

---

### 13. Rubric status line wording: "PASSES REVIEW" vs "PASSES VERIFICATION"

**Severity:** Minor
**Location:** `skills/code-review.md:313`

Draft-review uses `PASSES VERIFICATION`. Code-review uses `PASSES REVIEW`. The intermediate states also differ: draft-review's red state says "DOES NOT PASS" while code-review also says "DOES NOT PASS" (consistent). The green state terminology differs appropriately by domain. This is a reasonable domain adaptation, not an inconsistency.

---

### 14. "sub-agent" terminology is consistent

**Severity:** Informational
**Location:** Throughout `skills/code-review.md`

Code-review uses "sub-agent" (hyphenated) consistently, matching draft-review and the orchestrated-review pattern doc's stated convention. This resolves the inconsistency noted in matrix-analysis (which uses "subagent" unhyphenated in places).

---

## What Looks Good

1. **Mandatory Execution Rules are structurally identical.** Same preamble, same five-rule structure, same numbered format. Domain terms are substituted appropriately. A reader familiar with draft-review will immediately recognize the structure.

2. **Pipeline stages follow the established 3-stage pattern.** Stage names are domain-appropriate. CHECKPOINT markers use the same format. Stage 3 naming is identical across all three orchestrators.

3. **Fact-Check Gate preserves the convention.** Three options, `--no-gate` override, same conditional logic. Wording adapts naturally for code context.

4. **Rubric format preserves core conventions.** Emoji tiers, status line format, pass/fail criteria, and the "designed for re-runs" philosophy are all consistent with draft-review.

5. **Important Reminders section is present and follows the style.** Bold-lead items, explanatory sentences, covers the common ground from both baselines.

6. **Output location conventions are followed exactly.** Save to `docs/reviews/`, create directory if needed, overwrite on re-run, link at end of synthesis. File tree diagram included (matching draft-review convention).

7. **Orchestrated-review pattern cross-reference.** Code-review is the only orchestrator that includes the cross-reference the pattern doc recommends. This is a good practice that should be back-ported to the other two.

8. **The "pass scope, not diffs" approach is well-documented.** This is a meaningful deviation from draft-review (which passes full content) that is clearly explained and motivated by context budget concerns. The convention is stated both in the pipeline section and in Important Reminders.

---

## Summary Table

| # | Finding | Severity | Convention Status |
|---|---------|----------|-------------------|
| 1 | Pre-pipeline section heading is hybrid of two baselines | Inconsistent | Neither matches |
| 2 | Cross-reference to orchestrated-review pattern (new) | Informational | Good addition, back-port to baselines |
| 3 | Uses "Agent tool" (matches matrix-analysis, not draft-review) | Inconsistent | Known cross-orchestrator issue |
| 4 | Mandatory Execution Rules structure identical | -- | Consistent |
| 5 | Pipeline stage naming follows domain-specific convention | Informational | Consistent |
| 6 | Fact-Check Gate matches draft-review | Informational | Consistent |
| 7 | Deliverable 1 heading drops "Freeform" | Minor | Draft-review and matrix-analysis both include it |
| 8 | Deliverable 2 heading follows pattern | Informational | Consistent |
| 9 | Rubric adds Domain/Location columns | Informational | Appropriate extension |
| 10 | Output Location section uses plural (matches draft-review) | Minor | Consistent with draft-review |
| 11 | Important Reminders present and well-structured | Informational | Consistent |
| 12 | Unified Severity Mapping is new convention | Informational | Good addition for heterogeneous critics |
| 13 | "PASSES REVIEW" vs "PASSES VERIFICATION" | Minor | Appropriate domain adaptation |
| 14 | "sub-agent" terminology consistent | Informational | Matches convention |

---

## Overall Assessment

`skills/code-review.md` is a well-constructed orchestrator that closely follows the conventions established by `draft-review.md` and `matrix-analysis.md`. The structural bones are correct: frontmatter format, Mandatory Execution Rules, 3-stage pipeline, CHECKPOINT markers, two-deliverable structure, Output Locations section, and Important Reminders are all present and in the right order with the right formatting.

**Actionable items (2):**

1. **Deliverable 1 heading** (Minor): Add "Freeform" back to match both baselines: `## Deliverable 1: Freeform Chat Synthesis`.
2. **Pre-pipeline section heading** (Inconsistent): Choose either draft-review's `## Before You Begin: [Subtitle]` convention or matrix-analysis's fold-into-Stage-1 approach rather than the current hybrid.

**Non-actionable observations:**

- The "Agent tool" vs "Task tool" variance (finding #3) is an existing cross-orchestrator inconsistency, not introduced by code-review. Code-review matches the newer orchestrator (matrix-analysis).
- The orchestrated-review pattern cross-reference (finding #2) is a good practice that code-review adopts and the other orchestrators should back-port.
- The Unified Severity Mapping (finding #12) and Escalation Rule are well-designed new conventions appropriate for heterogeneous critic pipelines.

The new file introduces no breaking convention violations. The two actionable items are minor/inconsistent-level fixes. The new conventions it establishes (severity mapping, escalation rule, scope-passing instead of diff-passing) are well-motivated and clearly documented.
