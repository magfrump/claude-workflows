# Skill Format Audit: Top 5 Skills vs. Anthropic Guidelines

**Date:** 2026-04-09
**Skills audited:** code-review.md, security-reviewer.md, ui-visual-review.md, fact-check.md, draft-review.md
**Guidelines sources:**
- [Anthropic skill-creator SKILL.md](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) (official skill authoring reference)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) (official product docs)

**Hypothesis under test:** A read-only audit will identify at least 2 concrete format deviations across the 5 skills that, if fixed in a future round, would improve skill discoverability or consistency.

---

## Summary of Findings

**7 actionable divergences identified** across the 5 audited skills. The most impactful are the non-standard frontmatter fields (`when`, `requires`) that Claude Code ignores, and the flat-file structure that prevents use of supporting files. All 5 skills share the structural divergences; individual skills have additional issues around description length and line count.

---

## Finding 1: Non-Standard Frontmatter Field `when`

**Severity:** High
**Affects:** All 5 skills
**Guideline:** The [frontmatter reference](https://code.claude.com/docs/en/skills) lists these fields: `name`, `description`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, `shell`, `argument-hint`. There is no `when` field.

**Current state:** All 5 skills include a `when:` field in frontmatter:
- `code-review.md`: `when: User requests a full code review or PR review`
- `security-reviewer.md`: `when: Code touches auth, input handling, crypto, or trust boundaries`
- `ui-visual-review.md`: `when: User asks to review, audit, or fix visual/layout issues...`
- `fact-check.md`: `when: User asks to fact-check or verify claims in a draft`
- `draft-review.md`: `when: User wants a thorough multi-perspective review of a written draft`

**Impact:** Claude Code's skill loader does not recognize `when` as a frontmatter field. The triggering information in `when` is invisible to the skill activation system. Claude only uses `description` to decide when to load a skill. The `when` field is dead weight in frontmatter.

**Recommendation:** Merge `when` content into the `description` field (which Claude actually reads for triggering), then remove `when`. The skill-creator guidelines specifically state: "All 'when to use' info belongs in the description, not body."

---

## Finding 2: Non-Standard Frontmatter Field `requires`

**Severity:** Medium
**Affects:** security-reviewer.md, ui-visual-review.md

**Current state:** Both skills declare a `requires` block:
```yaml
requires:
  - name: code-fact-check
    description: >
      A code fact-check report covering claims in comments...
```

**Impact:** `requires` is not a recognized frontmatter field. Claude Code does not enforce or consume dependency declarations in skill frontmatter. The dependency information is inert metadata.

**Recommendation:** Move dependency documentation into the markdown body (as code-review.md and draft-review.md already do in their "Dependencies" sections). This makes the information visible to Claude when the skill is loaded without pretending it's machine-readable config.

---

## Finding 3: Flat File Structure Instead of Directory-Based Skills

**Severity:** High
**Affects:** All 5 skills (and all 19 skills in the project)

**Guideline:** The official structure is:
```
skill-name/
  SKILL.md        # required entrypoint
  scripts/        # optional
  references/     # optional
  examples/       # optional
```

**Current state:** All skills are flat `.md` files at `~/.claude/skills/code-review.md`, etc. There are no `SKILL.md` entrypoints and no supporting file directories.

**Impact:** The flat-file approach works (Claude Code's docs confirm `.claude/commands/` style files still function), but it prevents:
- Bundling scripts, templates, or reference docs with skills
- Using `${CLAUDE_SKILL_DIR}` to reference bundled assets
- Progressive disclosure (keeping SKILL.md lean, deferring detail to supporting files)

The skill-creator guidelines emphasize a three-level loading system: metadata (~100 words) always in context, SKILL.md body (<500 lines) loaded on trigger, bundled resources loaded as needed. The flat-file approach collapses all content into a single layer.

**Recommendation:** Migrate to directory structure (e.g., `~/.claude/skills/code-review/SKILL.md`). For the larger skills (ui-visual-review at 582 lines, code-review at 391 lines), move reference material into supporting files. This is a non-breaking change -- Claude Code discovers both formats.

---

## Finding 4: Description Length Exceeds 250-Character Truncation Threshold

**Severity:** Medium
**Affects:** All 5 skills

**Guideline:** "Front-load the key use case: descriptions longer than 250 characters are truncated in the skill listing to reduce context usage."

**Current state (approximate character counts of description field):**
| Skill | Description chars |
|-------|------------------|
| code-review.md | ~720 |
| security-reviewer.md | ~650 |
| ui-visual-review.md | ~750 |
| fact-check.md | ~480 |
| draft-review.md | ~520 |

All 5 exceed the 250-character threshold significantly. The descriptions are multi-sentence paragraphs that include trigger phrases, use-case lists, and scope clarifications.

**Impact:** When displayed in the skill listing, descriptions are truncated to 250 characters. Content beyond that point (including trigger phrases like "Also trigger when...") may be cut off, reducing Claude's ability to match the skill to user requests. The skill-creator guidelines note that descriptions should be "pushy" to combat model undertriggering, but this must be front-loaded within the 250-char window.

**Recommendation:** Restructure each description to put the primary trigger and capability in the first 250 characters. Move secondary triggers and scope notes to the markdown body. Example restructure for fact-check.md:

**Before (~480 chars):**
> Perform rigorous journalistic fact-checking on a draft (blog post, essay, article, or policy piece). This is not a critique or review -- it's a neutral verification pass, like a newspaper's fact-checking desk. For every checkable claim in the draft, search for evidence, assess accuracy, and report findings with calibrated confidence. Produces a structured Markdown report that can be consumed by human readers or passed to downstream critic agents. Use this skill whenever the user asks to "fact-check"...

**After (~230 chars):**
> Fact-check a draft's claims with web search and evidence assessment. Use when asked to "fact-check", "verify the numbers", "check the claims", or "source-check". Produces a structured report with verdicts and sources.

---

## Finding 5: ui-visual-review.md Exceeds 500-Line Limit

**Severity:** Medium
**Affects:** ui-visual-review.md (582 lines)

**Guideline:** "Keep SKILL.md under 500 lines. Move detailed reference material to separate files."

**Impact:** The full 582-line skill loads into context when triggered. The runtime verification section (Step 6, lines 329-523, ~195 lines) is optional and only applies to web apps with dev servers. This material could be deferred to a supporting file, keeping the main SKILL.md under 400 lines and loading runtime verification only when needed.

**Recommendation:** Extract Step 6 (Runtime Verification) and the Affordance Principles Reference into supporting files:
```
ui-visual-review/
  SKILL.md                    # ~350 lines (Steps 1-5, core checklist)
  runtime-verification.md     # Step 6 (~195 lines)
  affordance-principles.md    # Reference section (~50 lines)
```
Reference them from SKILL.md: "For runtime browser verification, see [runtime-verification.md](runtime-verification.md)."

---

## Finding 6: Orchestrator Skills Lack `context` and `agent` Configuration

**Severity:** Low
**Affects:** code-review.md, draft-review.md

**Guideline:** Skills can set `context: fork` to run in an isolated subagent, and `agent` to specify the execution environment. Orchestrator skills that spawn sub-agents are candidates for forked execution.

**Current state:** Neither orchestrator sets `context` or `agent` in frontmatter. Both rely on the main conversation context and spawn sub-agents manually via Agent/Task tool calls.

**Impact:** Running orchestrators inline means they consume main conversation context with coordination logic, checkpoints, and synthesis. A forked context would isolate this. However, the current approach works and gives the orchestrator access to conversation history (useful for scope determination). This is a tradeoff, not a bug.

**Recommendation:** Consider but don't require. If context budget becomes an issue during long reviews, adding `context: fork` to orchestrators would help. Document the tradeoff in a decision record.

---

## Finding 7: draft-review.md References `Task` Tool Instead of `Agent` Tool

**Severity:** Low
**Affects:** draft-review.md

**Current state:** draft-review.md instructs: "You MUST use the Task tool to spawn sub-agents" and "Launch via the Task tool with `subagent_type: general-purpose`" (lines 41, 103, 114, etc.). The actual tool in Claude Code is called `Agent`, not `Task`.

code-review.md correctly references the `Agent` tool throughout.

**Impact:** Claude can typically resolve this (both names are close enough and the intent is clear), but it adds friction and could cause confusion or retry loops. Instructions should use the actual tool name.

**Recommendation:** Replace all references to "Task tool" with "Agent tool" in draft-review.md to match the actual tool name and be consistent with code-review.md.

---

## Cross-Cutting Observations

### What the skills do well

1. **Rich trigger phrases in descriptions** -- all 5 skills include specific user phrases that trigger activation ("review this code", "check for vulnerabilities", "fact-check this"). This aligns with the skill-creator guidance to make descriptions "pushy."

2. **Clear role boundaries** -- orchestrators (code-review, draft-review) explicitly prohibit themselves from doing analytical work. Leaf skills (security-reviewer, fact-check) have focused scopes.

3. **Structured output formats** -- all 5 define explicit output templates with severity tiers and status tracking, making outputs consistent and machine-parseable.

4. **Skill recovery pointers** -- 4 of 5 skills include `> On bad output, see guides/skill-recovery.md`, providing a recovery path.

### Compatibility note

The flat `.md` file format and non-standard frontmatter fields work today because Claude Code is backward-compatible with the `.claude/commands/` pattern and ignores unrecognized frontmatter. However, future Claude Code updates may add validation or change behavior around frontmatter parsing. Migrating to the standard format is defensive.

---

## Prioritized Action Items

| Priority | Finding | Effort | Impact |
|----------|---------|--------|--------|
| 1 | F1: Remove `when`, merge into `description` | Low | Activates dead trigger content |
| 2 | F4: Front-load descriptions within 250 chars | Medium | Prevents trigger-phrase truncation |
| 3 | F3: Migrate to directory-based skill structure | Medium | Enables progressive disclosure, supporting files |
| 4 | F5: Extract ui-visual-review runtime sections | Low | Gets below 500-line limit |
| 5 | F2: Move `requires` to markdown body | Low | Removes inert frontmatter |
| 6 | F7: Fix Task->Agent tool name in draft-review | Low | Correctness |
| 7 | F6: Consider `context: fork` for orchestrators | Low | Optional context optimization |

---

## Hypothesis Evaluation Data

This audit identified **7 actionable divergences** (threshold was 2), confirming the hypothesis. The most impactful findings (F1: dead `when` field, F4: truncated descriptions) directly affect skill discoverability. Fixing these in a future round would make trigger content visible to Claude's skill activation system (F1) and ensure trigger phrases survive the 250-char truncation window (F4).
