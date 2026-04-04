# Self-Evaluation: ui-visual-review

**Target:** `skills/ui-visual-review.md` | **Type:** Skill | **Evaluated:** 2026-04-04
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | Output is structured (severity-grouped findings, viewport checklist, best-practices table) with mechanically checkable properties. However, assessing whether the skill correctly identifies layout bugs from code alone — without a browser — requires CSS expertise to validate. You could construct test inputs (a React component with known overflow bugs) and check that findings mention them, but quality of the analysis remains judgment-dependent. |
| Trigger clarity | Strong | Triggers are specific and concrete: "fix the layout", "make this responsive", "review the UI", "check visual elements", "audit the CSS", plus the general case of reported visual breakage. These are clearly distinct from all other skills in the repo — no other skill covers CSS/layout review. No ambiguity about when to reach for this vs. security-reviewer, performance-reviewer, etc. |
| Overlap and redundancy | Strong | No substantive overlap with any other skill or workflow in the repo. The code-review orchestrator covers security, performance, and API consistency but does not include a visual/layout critic. The built-in `code-simplifier` focuses on code quality/readability, not CSS layout correctness. This skill provides a unique analytical lens. |
| Test coverage | Weak | No automated tests exist in `test/`. No git history references to the skill (zero commits mentioning "ui-visual-review"). No example output artifacts demonstrating real usage. The only artifacts in `docs/reviews/` are from the draft-review pipeline evaluating the skill *definition itself* (fact-check, Cowen/Yglesias critiques, verification rubric) — not from the skill being *used* to review actual UI code. Probationary state per rubric. |
| Pipeline readiness | Adequate | The skill is standalone viable — it can be invoked directly when a user reports visual issues, and it produces a complete report without needing upstream/downstream tools. However, it is NOT referenced by the code-review orchestrator (not in its known critic roles list) and no other orchestrator references it. It could logically be a contextual critic in the code-review pipeline (auto-selected when the diff touches CSS/SCSS/Tailwind files), but that integration doesn't exist yet. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Provides a structured 7-category checklist for analyzing CSS/layout code for visual bugs (unbounded content, trapped controls, flex sizing errors, positioning ancestry, spacing waste, affordance/discoverability, and responsive concerns). It mandates reasoning at three viewport widths and grounds recommendations in WCAG 2.2, NNGroup research, and platform UI guidelines. It produces a severity-grouped report with fix code, tradeoff notes, and a viewport verification checklist.

**What generic prompting achieves:** Asking Claude "review this CSS for layout bugs" would likely catch obvious issues (overflow: hidden, fixed widths) but would miss the systematic checklist approach. Key elements likely missing without the skill:
- The specific ordering of checks by bug frequency (unbounded content first, responsive concerns last)
- The mandatory three-viewport reasoning requirement
- The "controls trapped inside scroll containers" pattern (a subtle, specific bug pattern)
- The affordance principles reference section (grounding in WCAG 2.2 specific success criteria)
- The structured report format with severity grouping and tradeoff documentation
- The `shrink-0` vs `flex-1 min-h-0` diagnostic question ("should this size to content or fill space?")

**What built-in tools cover:** The built-in `code-simplifier` does not cover layout correctness. No built-in Claude Code capability targets CSS/layout review specifically.

**Questions for the reviewer:**
- How much of the skill's value comes from the checklist structure/consistency vs. the specific CSS bug patterns it encodes?
- Is the gap "the skill adds moves the user wouldn't think of" (e.g., the trapped-controls pattern) or "the skill ensures consistency the user would otherwise forget" (e.g., always checking three viewports)?
- Under what conditions is the gap largest — general audits of unfamiliar UI code, or targeted fixes of reported bugs?

> **Human input (2026-04-04):** The skill's checklist items were derived from real UI bugs encountered and fixed in the aisc_lct project. The companion `docs/UI_LAYOUT_GUIDELINES.md` in that project captures the same patterns. This grounds the counterfactual gap in actual bug-finding — the patterns are ones that were missed without the skill and caused real breakage.

### User-Specific Fit

**Triggering situations:**
- User reports a visual element that is cut off, overlapping, or invisible at certain resolutions
- User asks to "fix the layout", "make this responsive", "review the UI"
- User is building or maintaining a web application with CSS/Tailwind styling
- User wants a pre-merge audit of UI changes

**Questions for the reviewer:**
- How often do you work on web UI code with CSS/layout concerns?
- Is this frequency increasing or decreasing? (e.g., are you building more web apps, or shifting to other domains?)
- Does this serve a goal you're actively pursuing (e.g., shipping a web app, improving a dashboard)?
- Would you actually remember to reach for this tool when you encounter a layout bug, or would you just fix it ad-hoc?
- The board game digitization project noted in memory — does it involve web UI that would benefit from this skill?

> **Human input (2026-04-04):** The skill came from active web UI work in the aisc_lct project — real commits fixing visual bugs. The triggering situation arises regularly. The user also has a Unity project where visual layout principles apply (C# UI elements), broadening the applicability beyond web-only.

### Condition for Value

**Stated or inferred conditions:**
1. The user must be working on web UI code (HTML/CSS/JSX/TSX/Vue/Svelte)
2. The code must have layout complexity worth auditing (not trivial static pages)
3. For maximum value: the skill should be integrated into the code-review pipeline as a contextual critic

**Automated findings:**
- Code-review orchestrator integration: DOES NOT EXIST (not listed in known critic roles)
- No `requires` block in the skill — it has no pipeline dependencies
- No other skill references ui-visual-review in its `requires` block
- The skill is standalone viable today without pipeline integration

**Questions for the reviewer:**
- Are you currently working on web apps with layout complexity that would trigger this skill?
- Is code-review pipeline integration worth pursuing? If so, should ui-visual-review be a core critic (always runs when CSS is touched) or a contextual critic (advisory only)?
- Without pipeline integration, will you remember to invoke this standalone when reviewing UI changes?

> **Human input (2026-04-04):** Conditions are met — active web UI work exists. User wants pipeline integration into code-review as a contextual critic, triggered by the presence of any visible UI elements (not just CSS file changes). TSX files with Tailwind classes, C#/Unity UI components, etc. should all trigger the skill.

### Failure Mode Gracefulness

**Output structure:** The skill produces severity-grouped findings (Critical/Major/Minor), each with problem description, evidence/best-practice citation, exact fix code, and tradeoff notes. A viewport verification checklist at the end provides a manual check layer. The best-practices table documents which guidelines were applied.

**Potential silent failures:**
- **Misreading CSS cascade/specificity:** The skill analyzes code statically. It could miss that a parent component overrides a child's styles, producing a fix that addresses the wrong layer. The fix would look correct in isolation.
- **Framework-specific behavior:** Tailwind utility classes, CSS modules, styled-components, and CSS-in-JS all have different scoping and cascade behaviors. The skill could recommend a fix that's correct for vanilla CSS but breaks in the framework context.
- **False confidence about viewport behavior:** The skill reasons about viewports from code, not from rendering. It could confidently state "this will overflow at 320px" when browser rendering handles it differently due to flex wrapping, min-content sizing, or other computed behaviors.
- **Outdated browser compatibility claims:** If the skill recommends a CSS property with limited support, the web search step should catch this — but if the skill skips the search (Step 3 says "not for every issue"), it may recommend unsupported features.

**Pipeline mitigations:** None currently — the skill is not part of any pipeline. If integrated into code-review, the fact-check stage would not help (it checks code comments, not CSS behavior). The main mitigation is the viewport verification checklist, which prompts the user to manually test.

**Questions for the reviewer:**
- Based on your experience with CSS, which failure modes above are most likely in the codebases you work on?
- Have you observed any silent failures in CSS review (by Claude or by humans) where the analysis looked correct but the browser behaved differently?
- Is the detectable-to-silent failure ratio acceptable given that the skill explicitly notes it's analyzing code, not running a browser?

---

## Key Questions

1. ~~**Is this skill an investment or inventory?**~~ **RESOLVED:** Investment — derived from real bug fixes in an active project, with a companion guidelines doc proving the patterns are validated.

2. ~~**Should this become a code-review contextual critic?**~~ **RESOLVED:** Yes. User wants it integrated into the code-review pipeline, triggered by presence of any visible UI elements (not just CSS file changes). This includes TSX with Tailwind, C#/Unity UI, etc.

3. **How reliable is static CSS analysis without a browser?** The skill is honest about this limitation (Step 3 notes it's "reviewing code, not running a browser"), but the structured report format may convey more confidence than the analysis warrants. Is the viewport verification checklist sufficient mitigation, or does the skill need stronger caveats about its static-analysis limitations?

## Action Items (from human review)

- [ ] **Add test coverage** — construct test inputs using patterns from `aisc_lct/docs/UI_LAYOUT_GUIDELINES.md` (real bugs that were actually encountered)
- [ ] **Integrate into code-review pipeline** — add as a contextual critic in `skills/code-review.md`, auto-selected when diff touches UI elements (JSX/TSX rendering, Tailwind classes, C#/Unity UI, not just `.css` files)
- [ ] **Broaden skill scope beyond web** — the skill currently says "web app UI code" but should also cover Unity/C# UI elements where the same layout principles apply
