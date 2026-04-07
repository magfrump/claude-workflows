# Plan: Simplification Audit of 3 Longest Workflows

**Scope:** Same as research-simplification-audit.md  
**Approach:** Cut verbose examples, consolidate redundant sections, compress reference tables. Preserve all Done-when checklists and actionable structure.

## Steps

### Step 1: Simplify user-testing-workflow.md (345→≤276, cut ≥69 lines)

Cuts:
1. **Moderator script template** (lines 70-135): Remove example warm-up questions and verbose intro dialogue. Keep structural skeleton with brief guidance per section. ~30 lines saved.
2. **Severity rating** (lines 192-217): Merge Travis flowchart and Nielsen table into one compact severity scale. ~10 lines saved.
3. **Step 3.5 Stress-Test** (lines 223-235): Condense 3 verbose paragraphs to 3 terse bullets. ~8 lines saved.
4. **Prioritization matrix** (lines 239-253): Replace ASCII art with a brief description. ~8 lines saved.
5. **Appendix A SUS** (lines 278-318): Compress interpretation table rows and scoring instructions. ~10 lines saved.
6. **Appendix C** (lines 335-341): Compress to 2 lines per testing mode. ~3 lines saved.
7. **Task construction** examples: Trim bad/good table. ~3 lines saved.

### Step 2: Simplify research-plan-implement.md (241→≤192, cut ≥49 lines)

Cuts:
1. **When to pivot** (lines 11-18): Condense each bullet to 1-2 sentences. ~12 lines saved.
2. **Working documents** (lines 22-39): Cut gitattributes explanation and freshness tracking paragraph. ~10 lines saved.
3. **Test specification** (lines 96-114): Condense test level descriptions to a brief list. Remove diagnostic expectations paragraph. ~10 lines saved.
4. **Session handoff** (lines 187-216): Trim surrounding prose, keep template. ~8 lines saved.
5. **Human checkpoint paragraphs** in steps 2 and 5: Tighten. ~5 lines saved.
6. **Refactoring variant** (lines 225-241): Condense. ~5 lines saved.

### Step 3: Simplify codebase-onboarding.md (180→≤144, cut ≥36 lines)

Cuts:
1. **Step 6 orientation template** (lines 116-141): Reduce to a brief section list without the full markdown template. ~15 lines saved.
2. **When to re-run + freshness check** (lines 166-181): Condense and reference guides/doc-freshness.md instead of repeating. ~10 lines saved.
3. **Relationship to other workflows** (lines 159-163): Fold into "When to pivot". ~4 lines saved.
4. **Step 2 and 4 prose**: Tighten explanatory text. ~4 lines saved.
5. **Step 5 explanations**: Trim category descriptions. ~4 lines saved.

### Step 4: Verify line counts and commit

## Risks
- Over-cutting could remove genuinely useful reference material (especially SUS, moderator script)
- Mitigation: preserve structural skeletons and all Done-when checklists
