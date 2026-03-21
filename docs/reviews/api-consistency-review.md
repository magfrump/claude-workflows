# API Consistency Review

**Repository:** claude-workflows-cleanup
**Scope:** fd66df8~1..HEAD (10 commits)
**Checked:** 2026-03-20

> **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

---

## Baseline Conventions

The existing codebase (pre-diff) established the following conventions for skill files:

1. **Frontmatter**: YAML block with `name` (string) and `description` (multiline `>` scalar). Some skills have `requires` blocks.
2. **Section order**: Varies by skill type, but prose-critic skills (cowen-critique, yglesias-critique) follow: frontmatter, H1 title, intro paragraph, "Using the Fact-Check Report" section, "The Cognitive Moves" section (numbered subsections), "How to Structure the Critique" section, "Output Location", "Tone", (end). Fact-check follows a similar but distinct pattern.
3. **Naming**: Skill filenames use kebab-case. Skill `name` fields match filenames without `.md`.
4. **Output locations**: All skills save to `docs/reviews/` with a skill-specific filename. The convention is `docs/reviews/{skill-name}-{artifact-type}.md` (e.g., `cowen-critique.md`, `fact-check-report.md`).
5. **Orchestrator patterns**: `draft-review` uses `Task` tool for sub-agents. It references `.skills/skills/` as the discovery path for critic agents.
6. **Cross-references**: Workflows reference skills by filename (e.g., `cowen-critique.md`), sometimes with relative links (e.g., `../skills/cowen-critique.md`).
7. **Decision documents**: Numbered `NNN-title.md` in `docs/decisions/`.

---

## Findings

#### 1. Severity label inconsistency across the three code-review critics

**Severity:** Inconsistent
**Location:** `skills/security-reviewer.md:204`, `skills/performance-reviewer.md:202`, `skills/api-consistency-reviewer.md:227`
**Move:** Establish baseline conventions (Move 1), Check naming against the grain (Move 2)
**Confidence:** High

The three new code-review critics use different field names for their primary severity/impact label in the finding template. Security-reviewer uses `**Severity:**` with levels Critical/High/Medium/Low/Informational. Performance-reviewer uses `**Impact:**` with levels Critical/High/Medium/Low/Informational. API-consistency-reviewer uses `**Severity:**` with levels Breaking/Inconsistent/Minor/Informational. This means a future code-review orchestrator cannot parse findings uniformly -- it would need to handle two different field names and three different severity scales. The prose-critic skills (cowen-critique, yglesias-critique) do not use a per-finding severity field, so there is no precedent to follow, but the three new skills should be consistent with each other since they are designed to be composed in the same pipeline.

**Recommendation:** Standardize on a single field name (either `Severity` or `Impact`) across all three code-review critics. Align the severity scales or establish a documented mapping. The security-reviewer's five-tier Critical/High/Medium/Low/Informational scale is the most standard and could serve as the baseline, with domain-specific guidance on what each level means in each context.

---

#### 2. Summary table column name inconsistency between performance-reviewer and siblings

**Severity:** Inconsistent
**Location:** `skills/performance-reviewer.md:229`, `skills/security-reviewer.md:230`, `skills/api-consistency-reviewer.md:252`
**Move:** Check naming against the grain (Move 2), Look for the asymmetry (Move 7)
**Confidence:** High

The summary table in performance-reviewer uses `Impact` as the column header, while security-reviewer and api-consistency-reviewer use `Severity`. This is a downstream consequence of finding #1 but affects a different output artifact (the summary table vs. the per-finding metadata). A consumer or orchestrator attempting to merge these tables would encounter inconsistent column names.

**Recommendation:** Align column names once the field name from finding #1 is resolved.

---

#### 3. Context-framing section inconsistency across code-review critics

**Severity:** Minor
**Location:** `skills/security-reviewer.md:193-195`, `skills/performance-reviewer.md:191-193`, `skills/api-consistency-reviewer.md:211-213`
**Move:** Establish baseline conventions (Move 1)
**Confidence:** High

Each code-review critic has a different name for its "context-framing" section that appears before Findings. Security-reviewer calls it "Trust Boundary Map." Performance-reviewer calls it "Data Flow and Hot Paths." API-consistency-reviewer calls it "Baseline Conventions." These are domain-appropriate names, but a code-review orchestrator synthesizing the three outputs would need to know that each uses a different section name for the analogous structural role. This is arguably appropriate specialization rather than a bug, but it diverges from the prose-critic pattern where the structural sections (e.g., "The Argument, Decomposed" in cowen-critique, "The Goal vs. the Mechanism" in yglesias-critique) are explicitly different per critic by design.

**Recommendation:** This is likely fine as-is. If a code-review orchestrator is built later, it should parse by section position (first H3 before "Findings") rather than by name. Document this convention if it causes integration friction.

---

#### 4. draft-review references `.skills/skills/` path that does not exist in this repo

**Severity:** Inconsistent
**Location:** `skills/draft-review.md:54`, `skills/draft-review.md:96-97`
**Move:** Trace the consumer contract (Move 3)
**Confidence:** High

The draft-review orchestrator instructs agents to "List all folders in `.skills/skills/`" and to "Read the full contents of `.skills/skills/fact-check/SKILL.md`". This path convention (`.skills/skills/{name}/SKILL.md`) does not match the actual repository structure, where skills are flat files at `skills/{name}.md`. This appears to be a reference to a different project's file layout (possibly the Claude Code internal `.skills` directory structure). An agent following these instructions in this repository would fail to discover any skills.

**Recommendation:** Update draft-review to reference `skills/` directory and `skills/{name}.md` file pattern, or document that draft-review's discovery instructions assume a specific deployment context where skills are installed differently.

---

#### 5. Inconsistent `requires` block format between code-review critics and prose critics

**Severity:** Inconsistent
**Location:** `skills/code-fact-check.md:11-12`, `skills/security-reviewer.md:14-20`, `skills/cowen-critique.md:17-22`
**Move:** Establish baseline conventions (Move 1), Verify error consistency (Move 4)
**Confidence:** High

The `requires` blocks use two different formats. The code-review critics (security-reviewer, performance-reviewer, api-consistency-reviewer) and the prose critics (cowen-critique, yglesias-critique) use a structured format with `name` and `description` fields:

```yaml
requires:
  - name: code-fact-check
    description: >
      A code fact-check report...
```

But code-fact-check uses a plain string format:

```yaml
requires:
  - A codebase with comments, docstrings, or documentation to verify
```

The structured format with `name` and `description` enables programmatic dependency resolution (an orchestrator can match the `name` field to a skill). The plain string format is human-readable but not machine-parseable for dependency wiring. This inconsistency means any tooling that reads `requires` blocks would need to handle both formats.

**Recommendation:** Standardize on the structured `name`/`description` format. For code-fact-check, the `requires` is a precondition (not a skill dependency), so either reformat it as a structured entry or introduce a distinct field (e.g., `preconditions`) to separate "needs another skill's output" from "needs this to exist."

---

#### 6. `fact-check` and `code-fact-check` have no `requires` field referencing each other but are assumed to be independent

**Severity:** Informational
**Location:** `skills/fact-check.md` (no `requires` block), `skills/code-fact-check.md:11-12`
**Move:** Trace the consumer contract (Move 3)
**Confidence:** Medium

The `fact-check` skill has no `requires` block at all, while `code-fact-check` has a plain-text requires entry. The prose critics require `fact-check` by name, and the code-review critics require `code-fact-check` by name. This is consistent in practice -- the two fact-check variants serve different pipelines (prose review vs. code review). However, the absence of any frontmatter `requires` on `fact-check.md` is a minor structural gap since every other skill that has dependencies declares them.

**Recommendation:** Add a `requires` block to `fact-check.md` documenting its precondition (a draft/document to fact-check, and web search capability), consistent with the pattern established by other skills.

---

#### 7. Output filename convention divergence: `code-fact-check-report.md` vs `fact-check-report.md`

**Severity:** Minor
**Location:** `skills/code-fact-check.md:179`, `skills/fact-check.md:114-115`
**Move:** Check naming against the grain (Move 2)
**Confidence:** High

The output filenames follow slightly different patterns: `fact-check-report.md` (fact-check skill), `code-fact-check-report.md` (code-fact-check skill), `security-review.md` (security-reviewer), `performance-review.md` (performance-reviewer), `api-consistency-review.md` (api-consistency-reviewer), `cowen-critique.md` (cowen-critique), `yglesias-critique.md` (yglesias-critique), `verification-rubric.md` (draft-review), `matrix-analysis.md` (matrix-analysis). The pattern is: fact-check variants append `-report`, code-review critics use `-review`, prose critics use `-critique`, orchestrators use their own names. This is actually fairly consistent once the implicit convention is understood, but it is not documented anywhere.

**Recommendation:** Document the output naming convention explicitly, either in CLAUDE.md's "Review Artifacts" section or in a shared conventions file. The implicit pattern (skill-type determines suffix: `-report` for verification, `-review` for code critique, `-critique` for prose critique) is reasonable but should be stated.

---

#### 8. matrix-analysis uses `Agent` tool while draft-review uses `Task` tool

**Severity:** Inconsistent
**Location:** `skills/matrix-analysis.md:29`, `skills/draft-review.md:28`
**Move:** Establish baseline conventions (Move 1)
**Confidence:** High

The two orchestrator skills reference different sub-agent dispatch mechanisms. Draft-review instructs "You MUST use the Task tool to spawn sub-agents" while matrix-analysis instructs "You MUST use the Agent tool to spawn subagents." The orchestrated-review pattern document (`patterns/orchestrated-review.md:31`) notes "Use 'sub-agent' consistently for the parallel execution mechanism, regardless of whether the underlying implementation uses the Task tool, Agent tool, or manual sequential processing." However, the actual skills diverge on which tool to reference. An agent implementing these skills needs to know which tool is available in its environment; the inconsistency may cause confusion or failures if only one tool is available.

**Recommendation:** Either standardize on one tool name across orchestrators, or add a note to each orchestrator that the tool name may vary by environment and the agent should use whichever parallel dispatch mechanism is available. The orchestrated-review pattern document already acknowledges this variance but the skills themselves do not.

---

#### 9. Decision document title format inconsistency

**Severity:** Minor
**Location:** `docs/decisions/001-code-fact-checking.md:1`, `docs/decisions/002-critic-style-code-review.md:1`, `docs/decisions/003-critic-moves-in-divergent-design.md:1`
**Move:** Check naming against the grain (Move 2)
**Confidence:** High

The three decision documents use slightly different H1 title formats. Decision 001 uses "Decision 001: Code Fact-Checking Skill Design." Decision 002 uses "002: Critic-Style Code Review" (no "Decision" prefix). Decision 003 uses "003: Critic Cognitive Moves as DD Evaluation Lenses" (no "Decision" prefix). This is a minor inconsistency in the document headers.

**Recommendation:** Standardize on one format. Either all include the "Decision" prefix or none do. The format with the prefix ("Decision NNN: Title") is more self-documenting when the file is viewed outside its directory context.

---

#### 10. Decision document section structure inconsistency

**Severity:** Minor
**Location:** `docs/decisions/001-code-fact-checking.md`, `docs/decisions/002-critic-style-code-review.md`, `docs/decisions/003-critic-moves-in-divergent-design.md`
**Move:** Establish baseline conventions (Move 1)
**Confidence:** High

The three decision documents follow the same general structure (Context, Options, Decision, Rationale, Consequences) but with variations. Decision 001 has an additional "Key design decisions for implementation" section at the end. Decision 001 uses "Options considered" while 002 uses "Options Considered" (different capitalization). Decision 003 has a "Moves adapted vs. omitted" subsection under Rationale. The Consequences sections use different formats: 001 uses `**Makes easier:**` / `**Makes harder:**` while 002 uses `**Easier:**` / `**Harder:**`.

**Recommendation:** Establish a decision document template with the canonical section names and formatting. Minor variations in subsections are fine (domain-specific sections like "Key design decisions for implementation" add value), but the shared sections should use consistent naming and formatting.

---

#### 11. `sub-agent` vs `subagent` terminology inconsistency

**Severity:** Minor
**Location:** `skills/matrix-analysis.md` (uses "subagent" throughout), `skills/draft-review.md` (uses "sub-agent" throughout), `patterns/orchestrated-review.md:31` (uses "sub-agent")
**Move:** Check naming against the grain (Move 2)
**Confidence:** High

The orchestrated-review pattern document uses "sub-agent" (hyphenated) and explicitly states to "Use 'sub-agent' consistently." Draft-review follows this convention. However, matrix-analysis uses "subagent" (unhyphenated) throughout. Task-decomposition also uses "sub-agent" (hyphenated), consistent with the pattern document.

**Recommendation:** Standardize on "sub-agent" (hyphenated) per the orchestrated-review pattern's stated convention. Update matrix-analysis.md to use the hyphenated form.

---

#### 12. CLAUDE.md "Review Artifacts" section references skills by bare names without paths

**Severity:** Informational
**Location:** `CLAUDE.md:39-41`
**Move:** Trace the consumer contract (Move 3)
**Confidence:** Medium

The "Review Artifacts" section in CLAUDE.md references skills by display name (e.g., "the `fact-check` skill", "the `draft-review` orchestrator") without paths or links. This is consistent with how CLAUDE.md references workflows (by name in the "Cross-project Workflows" section), but those workflow references include the filename in bold (e.g., "**research-plan-implement.md**"). The review artifacts section does not include filenames, making it slightly harder for an agent to locate the referenced skills.

**Recommendation:** Add filenames or relative paths for the referenced skills, consistent with how workflows are referenced in the same file.

---

## What Looks Good

1. **Structural consistency across the three code-review critics.** Security-reviewer, performance-reviewer, and api-consistency-reviewer follow a highly consistent section order: frontmatter, H1 title, intro paragraph, Scoping section, "Using the Code Fact-Check Report" section (with identical structure and warning format), "The Cognitive Moves" section, "How to Structure the Critique" section, Output Location, Tone, Important. This is clearly a deliberate pattern and well-executed.

2. **Fact-check dependency pattern.** All six critic-style skills (three prose, three code) correctly declare their respective fact-check skill as a soft dependency via `requires`, with well-written descriptions explaining what happens without the dependency. The warning messages are structurally identical across all six skills.

3. **Cognitive moves pattern.** The 7-9 numbered cognitive moves per critic skill are consistently structured: numbered H3 headings, 1-3 paragraphs of explanation, concrete examples. The move count (9 for security, 9 for performance, 9 for API consistency) matches the prose critic precedent (9 for cowen, 9 for yglesias).

4. **Output location instructions.** All skills include both standalone and orchestrator-invoked output path instructions, using the same two-paragraph pattern. This enables composition without breaking standalone use.

5. **Cross-references from workflows.** The new cross-references added to workflows (divergent-design, pr-prep, user-testing, spike, task-decomposition) use consistent relative link syntax and are placed in contextually appropriate locations.

6. **Orchestrated review pattern extraction.** The `patterns/orchestrated-review.md` document correctly identifies the shared structure across workflows and provides useful extension points. The cross-references from task-decomposition, pr-prep, and divergent-design back to this pattern are consistent.

7. **Decision documents capture the right information.** Despite minor formatting inconsistencies, all three decision documents include the essential content: context, multiple options considered (with good breadth), a clear decision, rationale, and consequences analysis.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Severity/Impact field name inconsistency across code-review critics | Inconsistent | `skills/performance-reviewer.md:202` | High |
| 2 | Summary table column name inconsistency | Inconsistent | `skills/performance-reviewer.md:229` | High |
| 3 | Context-framing section name varies across code-review critics | Minor | `skills/security-reviewer.md:193` | High |
| 4 | draft-review references `.skills/skills/` path that does not exist | Inconsistent | `skills/draft-review.md:54` | High |
| 5 | `requires` block uses two different formats | Inconsistent | `skills/code-fact-check.md:11` | High |
| 6 | `fact-check` skill has no `requires` block | Informational | `skills/fact-check.md` | Medium |
| 7 | Output filename convention undocumented | Minor | Multiple files | High |
| 8 | Orchestrators reference different dispatch tools (Task vs Agent) | Inconsistent | `skills/matrix-analysis.md:29` | High |
| 9 | Decision document title format varies | Minor | `docs/decisions/` | High |
| 10 | Decision document section naming/formatting varies | Minor | `docs/decisions/` | High |
| 11 | `sub-agent` vs `subagent` terminology | Minor | `skills/matrix-analysis.md` | High |
| 12 | CLAUDE.md references skills without paths | Informational | `CLAUDE.md:39-41` | Medium |

---

## Overall Assessment

The changes across these 10 commits are structurally well-designed. The three new code-review critics (security-reviewer, performance-reviewer, api-consistency-reviewer) follow a remarkably consistent internal pattern -- section order, cognitive move structure, fact-check integration, and output instructions are clearly templated from each other. The main consistency issues are at the seams: the field name divergence between `Severity` and `Impact` (finding #1), the different severity scales, and the `.skills/skills/` path reference in draft-review (finding #4) are the most impactful because they would cause real integration problems when a code-review orchestrator is built. The terminology inconsistency (finding #11) and `requires` format inconsistency (finding #5) are friction points for any tooling that tries to parse skill metadata programmatically. The decision document inconsistencies (findings #9-10) are cosmetic but worth addressing while the format is young and only three documents exist. None of these issues indicate the author missed existing conventions -- rather, these are cases where conventions are being established for the first time (code-review critics, decision documents) and minor drift occurred across multiple commits. All issues are fixable in place.
