# Skill Format Audit: Top 5 Skills vs. Anthropic Skill-Creator Guidelines

**Audited:** 2026-04-09
**Reference:** `skill-creator-original.md` from the official `plugin-dev` plugin
**Skills audited:** code-review, security-reviewer, ui-visual-review, fact-check, draft-review

## Hypothesis Under Test

> Auditing skills against vendor guidelines will surface at least 2 actionable format divergences that, once fixed, improve skill activation reliability in the next 3 rounds.

**Measurement plan:** Track skill activation failures and misfires in rounds R16–R18. Compare against baseline from R11–R15. Divergences fixed in this round are tagged below; unfixed divergences are documented for future rounds.

---

## Summary of Divergences

| # | Divergence | Severity | Skills Affected | Fixed? |
|---|-----------|----------|----------------|--------|
| D1 | Flat file structure instead of `skill-name/SKILL.md` directory | Low | All 5 | No — see notes |
| D2 | Second-person voice ("You are...") instead of imperative/infinitive | Medium | All 5 | No — see notes |
| D3 | Non-standard frontmatter fields (`when:`, `requires:`) | Low | 3 of 5 | No — see notes |
| D4 | Outdated tool name: "Task tool" instead of "Agent tool" | **High** | draft-review | **Yes** |
| D5 | Body exceeds recommended size (<5k words guideline) | Informational | ui-visual-review (3,907 words) | No — under limit |

---

## Detailed Findings

### D1: Flat file structure vs. directory-based SKILL.md

**Guideline:** Skills should use `skill-name/SKILL.md` directory structure with optional `scripts/`, `references/`, `assets/` subdirectories.

**Current state:** All 5 skills are flat files (`skills/code-review.md`) rather than directories (`skills/code-review/SKILL.md`).

**Impact assessment: Low.** These skills are loaded by orchestrators that `Read` the file path directly and paste contents into sub-agent prompts. The directory structure matters for Claude Code's built-in skill discovery (`.claude/skills/`), but these project-level skills are manually referenced. The flat structure is a deliberate project convention — all skill references in `code-review.md`, `draft-review.md`, and `CLAUDE.md` use the `skills/*.md` pattern.

**Recommendation:** Do not change. Migrating to directory structure would require updating every cross-reference and orchestrator instruction. The benefit (progressive disclosure via `references/` subdirectories) would only matter if any skill exceeds the 5k word body limit, which none currently do.

### D2: Second-person voice vs. imperative/infinitive

**Guideline:** "Write the entire skill using imperative/infinitive form (verb-first instructions), not second person. Use objective, instructional language (e.g., 'To accomplish X, do Y' rather than 'You should do X')."

**Current state:**
- `code-review.md`: "You are an orchestrator. You coordinate..."
- `security-reviewer.md`: "You are reviewing code changes..."
- `ui-visual-review.md`: "You review UI code for visual and layout problems..."
- `fact-check.md`: "You are a fact-checker. Your job is to verify..."
- `draft-review.md`: "You are an orchestrator. You coordinate..."

**Impact assessment: Medium.** The guideline exists because imperative form is clearer for AI consumption. However, the second-person "role assignment" pattern is widely used in effective prompts and the current skills work well. Changing voice throughout all 5 skills risks introducing regressions for unclear gain.

**Recommendation:** Do not change in this round. If skill activation reliability issues are observed in R16–R18, revisit this as a potential contributing factor. The voice pattern is consistent across all skills, which reduces confusion even if it diverges from the guideline.

### D3: Non-standard frontmatter fields

**Guideline:** Official frontmatter fields are: `name`, `description`, `version`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `context`, `agent`.

**Current state:**
- `code-review.md` has `when:` field
- `security-reviewer.md` has `when:` and `requires:` fields
- `ui-visual-review.md` has `when:` and `requires:` fields

**Impact assessment: Low.** These fields are not recognized by the Claude Code runtime and are silently ignored. The `when:` content duplicates information already in the `description:` field. The `requires:` field documents optional dependencies, which is useful documentation but not parsed by any system.

**Recommendation:** Do not remove — they serve as inline documentation and cause no harm. If a future Claude Code version validates frontmatter strictly, these would need removal. The `when:` content is already captured in the `description:` field, so no information would be lost.

### D4: Outdated tool name in draft-review.md — FIXED

**Guideline:** The correct tool for spawning sub-agents is the "Agent tool" (with `subagent_type` parameter).

**Current state:** `draft-review.md` references "Task tool" in 5 locations (lines 43, 103, 108, 146, 147). This is an outdated name. The sister skill `code-review.md` correctly uses "Agent tool" throughout.

**Impact assessment: High.** When Claude reads this skill and follows instructions to "use the Task tool to spawn sub-agents," it may fail to find the correct tool or use an incorrect invocation pattern. This is a direct execution reliability issue.

**Fix applied:** All "Task tool" references in `draft-review.md` replaced with "Agent tool".

### D5: Body size relative to 5k word guideline

**Guideline:** SKILL.md body should be <5k words; move detailed content to `references/`.

**Word counts:**
| Skill | Words | Status |
|-------|-------|--------|
| fact-check.md | 924 | Well within limit |
| security-reviewer.md | 2,055 | Within limit |
| draft-review.md | 2,090 | Within limit |
| code-review.md | 2,342 | Within limit |
| ui-visual-review.md | 3,907 | Within limit but largest |

**Impact assessment: Informational.** All skills are within the 5k word guideline. `ui-visual-review.md` is the largest at ~3.9k words. If it grows further (e.g., adding more checklist items or framework-specific patterns), consider extracting Step 6 (Runtime Verification, ~1,500 words) into a `references/` file.

**Recommendation:** No action needed. Monitor `ui-visual-review.md` size if future changes are made.

---

## Divergences NOT Found (Positive Compliance)

These guideline requirements are met by all 5 skills:

- **Required frontmatter present:** All have `name:` and `description:` fields
- **Description includes trigger phrases:** All descriptions list specific phrases that should trigger the skill (e.g., "review this code", "check for vulnerabilities")
- **Description uses third-person:** Descriptions appropriately use "This skill..." or "Use this skill when..." patterns
- **Body within size limit:** All under 5k words
- **No information duplication:** Skills don't duplicate content across sections

---

## Actionable Fixes Applied

1. **D4 fixed:** `draft-review.md` — replaced all "Task tool" references with "Agent tool" (5 occurrences)

## Recommendations for Future Rounds

1. **Monitor D2 (voice):** If skill execution quality degrades, test imperative voice rewrite on one skill as an A/B comparison
2. **Monitor D5 (size):** If `ui-visual-review.md` grows past 4.5k words, extract runtime verification to `references/`
3. **Consider D3 cleanup:** If Claude Code adds strict frontmatter validation, remove `when:` and `requires:` fields

## Evaluation Criteria for Hypothesis

To confirm or refute the hypothesis after R16–R18:
- **Confirm if:** The D4 fix (Task→Agent tool name) resolves at least one observed draft-review execution failure, AND at least one other divergence fix (if applied later) shows measurable improvement
- **Refute if:** No skill activation failures are observed that correlate with the documented divergences, suggesting the current format works despite guideline deviations
- **Partial confirm if:** D4 fix helps but no other divergence proves actionable — suggests only 1 actionable divergence, not 2+
