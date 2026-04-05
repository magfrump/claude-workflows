---
name: ui-visual-review
description: >
  Review and fix visual/layout issues in UI code (web or native), with a focus on cross-resolution
  compatibility, scrollability, overflow handling, and robust sizing. Validates recommendations
  against accessibility standards (WCAG 2.2), usability research (NNGroup), and platform UI
  guidance. Use this skill when the user reports visual elements that are cut off,
  overlapping, invisible at certain resolutions, or otherwise broken across screen sizes. Also
  trigger when the user asks to "fix the layout", "make this responsive", "review the UI",
  "check visual elements", or "audit the CSS". Applies to any framework with visual elements:
  React/JSX/TSX with Tailwind or CSS-in-JS, Unity/C# UI, Vue, Svelte, etc. Produces concrete
  code fixes plus a structured report of findings. NOTE: This skill can be invoked standalone
  or by a code-review orchestrator. If a code-fact-check report is provided, use it as your
  foundation for understanding what the code actually does and do not re-verify documented
  behavior.
when: User asks to review, audit, or fix visual/layout issues in UI code, or diff touches UI rendering code
requires:
  - name: code-fact-check
    description: >
      A code fact-check report covering claims in comments, docstrings, and documentation
      against actual code behavior. Typically produced by the code-fact-check skill. Without
      this input, the UI visual review proceeds on code analysis only — comments about layout
      behavior are not independently verified.
---

> On bad output, see guides/skill-recovery.md

# UI Visual Review

You review UI code for visual and layout problems — elements that disappear, overflow,
overlap, or become unusable at different screen sizes. You produce concrete fixes grounded in
accessibility standards and usability research. The core principles (overflow handling, control
placement, sizing, affordance) apply across frameworks — React/JSX/TSX, Unity/C#, Vue, Svelte,
native mobile, etc. — though most examples below use web/Tailwind conventions. For non-web
frameworks, adapt the patterns to the equivalent layout system (e.g., Unity's RectTransform
and LayoutGroup, SwiftUI's GeometryReader).

Your primary job is **mechanical bug-finding**: catching CSS and layout patterns that break at
different viewport sizes. This is objective work — does this layout break? — and it is the
core value of this skill. The checklist in Step 2 is your main tool.

Your secondary job, when relevant, is **affordance review**: checking that interactive elements
are discoverable and distinguishable. This work is grounded in:

- **WCAG 2.2** — visible focus indicators (2.4.7), focus not obscured (2.4.11),
  focus appearance (2.4.13, Level AAA), minimum target sizes (2.5.8),
  content reflow (1.4.10)
- **NNGroup research** — flat UI elements with weak signifiers require more user effort;
  interactive elements must be visually distinguishable from static content
- **European Accessibility Act (2025)** — EU law requiring digital accessibility via
  EN 301 549 / WCAG 2.1 AA, covering perceivable, operable, and understandable interfaces

The guiding principle: **users should never have to guess** whether they can scroll, click,
or interact with an element. When minimalist aesthetics conflict with discoverability, prefer
discoverability — especially in tool-like web applications where task completion matters more
than first impressions.

---

## Mandatory Execution Rules

1. **Project-local guidelines are your primary authority.** Before doing anything else, check
   for a project-local UI guidelines document (e.g., `docs/UI_LAYOUT_GUIDELINES.md`). If one
   exists, it captures patterns already validated in this codebase — follow it. Everything
   below fills gaps where the project has no guidance.

2. You MUST NOT recommend solutions that hide content or affordances. If content overflows,
   make the overflow visible and scrollable — do not clip it silently.

3. You MUST reason about your recommendations at three viewport widths:
   - Small mobile (320px–480px)
   - Tablet/small laptop (768px–1024px)
   - Large desktop (1920px+)

   Note: you are reviewing code, not running a browser. "Reason about" means analyzing the
   CSS to determine what will happen at each width, not visually testing.

4. You MUST NOT introduce CSS that requires vendor prefixes without noting which browsers
   need them.

5. **Search the web when uncertain** — not for every issue. For well-understood CSS patterns
   (flex overflow, scroll containers, positioning), your training data is sufficient. Search
   when you encounter unfamiliar properties, need to check browser compatibility for newer
   CSS features, or when the project lacks local guidelines. When you do search, prioritize:
   - MDN Web Docs (CSS property behavior and browser compatibility)
   - WCAG 2.2 guidelines (accessibility requirements)
   - Apple Human Interface Guidelines / Google Material Design (layout and sizing)
   - NNGroup articles (usability research)

---

## Step 1: Determine Scope

Ask the user or infer from context:
- Which files contain the UI code to review? (HTML, CSS, JSX/TSX, Vue, Svelte, C#/Unity, etc.)
- Is there a specific visual problem reported, or is this a general audit?
- What is the target platform? (Default for web: modern evergreen browsers + mobile Safari.
  For Unity: target resolutions from player settings. For native: platform design guidelines.)

If the user points to a specific problem (e.g., "the sidebar disappears on small screens"),
focus there first, then scan for related issues in the same component tree.

If this is a general audit, read all relevant layout and styling files.

---

## Review Modes

This skill operates in two modes. The mode determines which checklist items to run.

**Mechanical review (default)** — Runs checklist items 1-5 only. These are objective layout
bug checks with clear right/wrong answers. This is the default when triggered by the
code-review orchestrator or when reviewing a specific diff. No web search unless genuinely
uncertain about a CSS property. Fast and low-noise.

**Full audit** — Runs all checklist items (1-7), including affordance review and responsive/
cross-browser checks. Use this mode when the user explicitly asks for a "UI audit", "review
the UI", "check accessibility", or "audit the CSS". Also use when the user reports a
discoverability or affordance problem specifically.

The mode split exists because items 1-5 are mechanical pattern-matching where AI agents are
reliably accurate, while items 6-7 involve subjective judgment that can generate false
positives in projects using modern component libraries. Bundling both by default risks noise
that causes developers to disable the tool entirely.

---

## Step 2: Read the Code

Read the relevant files completely. Look for the following issues, ordered by how frequently
they cause real bugs:

### 1. Unbounded content without scroll caps (most common)
- Containers whose children can grow without limit (lists, error output, file uploads) but
  lack a `max-h-*` constraint + `overflow-auto`
- `overflow: hidden` that silently clips content — should usually be `overflow: auto` or
  `overflow-y: auto` with visible scroll indicators
- Missing `max-width` or `max-height` constraints on images or media

Example fix pattern:
```tsx
// Modal or overlay — cap at viewport percentage
<div className="max-h-[85vh] flex flex-col">
  <div className="shrink-0">Header</div>
  <div className="overflow-y-auto">Scrollable content</div>
</div>
```

### 2. Controls trapped inside scroll containers
- Buttons, toggles, or action bars inside an `overflow-auto` container — they scroll away
  and become inaccessible
- Fix: use a two-layer structure with controls pinned outside the scroll region

```tsx
// WRONG: button scrolls away
<div className="overflow-auto">
  {longContent}
  <button>Submit</button>
</div>

// CORRECT: docked footer pattern
<div className="flex flex-1 min-h-0 flex-col overflow-hidden">
  <div className="flex-1 min-h-0 overflow-auto p-6">{longContent}</div>
  <div className="shrink-0 border-t px-4 py-3">
    <button>Submit</button>
  </div>
</div>
```

### 3. Wrong `shrink-0` vs `flex-1 min-h-0` usage
- **`shrink-0`** — sizes to content, never shrinks. For: headers, footers, control bars, buttons.
- **`flex-1 min-h-0`** — fills remaining space. For: content areas, editors, scrollable regions.
- Mixing these up causes layout stretch (content area given `shrink-0`) or collapse
  (header given `flex-1`)

Ask for each element: "Should this size to its content or fill available space?"

### 4. Absolute positioning anchored to wrong parent
- An `absolute`-positioned element attaches to its nearest `relative` ancestor
- When multiple sections exist side-by-side, verify the element is inside the correct section
- Common bug: floating bar in outer div overlaps all sections instead of just its target
- Unity equivalent: a RectTransform anchored to the wrong parent Canvas or Panel, causing
  elements to scale or position relative to the full screen instead of their intended container

### 5. Excessive vertical spacing
- Padding and gaps that waste vertical space, pushing controls below the fold on small viewports
- Prefer compact defaults: `p-4` over `p-6`, `gap-3` over `gap-4`, `rows={3}` over `rows={8}`
- Test: at `1366x768` viewport, are action buttons visible without scrolling?

### 6. Visibility and affordance *(full audit mode only)*
- Interactive elements that look like static text (missing cursor, border, or background)
- Controls that disappear after completion (`{status !== "done" && <button>}`) — should
  update label instead (`status === "done" ? "Re-run" : "Run"`)
- Scroll indicators that only appear on hover (not discoverable on touch devices)
- Form inputs without visible borders (indistinguishable from labels)
- Disabled states that are invisible or insufficiently dimmed
- Missing focus indicators for keyboard navigation (WCAG 2.4.7; 2.4.13 Level AAA)
- Touch targets smaller than minimum sizes (WCAG 2.5.8: 24x24px minimum Level AA;
  WCAG 2.5.5: 44x44px Level AAA)

Note: discoverability is not only about making elements visible. Also consider:
- **Progressive disclosure** — showing controls in context when relevant, rather than
  displaying everything at once (which creates its own discoverability problem through clutter)
- **Consistent placement** — controls that appear in predictable locations are more
  discoverable than prominently styled controls in unexpected places
- **Redesigning to avoid overflow** — the best scroll bar is one you don't need. Before
  adding scroll indicators, ask whether the layout can be restructured to fit the content

### 7. Responsive and cross-browser concerns *(full audit mode only)*
- Fixed dimensions (`width: 500px`) that won't adapt to viewport changes
- Missing viewport meta tag
- Media queries that leave gaps between breakpoints
- Text that doesn't reflow on narrow viewports (missing `overflow-wrap: break-word`)
- CSS properties with incomplete browser support (check via web search when relevant)

---

## Step 3: Research When Uncertain

You do not need to search for every issue. For well-understood CSS patterns (flex overflow,
scroll containers, positioning ancestry), apply your knowledge directly.

**Search the web when:**
- You encounter a CSS property or browser behavior you're unsure about
- You need to verify browser compatibility for newer features (e.g., `scrollbar-gutter`,
  container queries, `dvh` units)
- The project lacks local guidelines and you need to determine current best practices for
  a specific pattern
- You're unsure whether a recommendation aligns with WCAG 2.2 requirements

**When you do search, prioritize:**
1. **MDN Web Docs** — CSS property behavior, browser compatibility tables
2. **WCAG 2.2 specification** — accessibility requirements
3. **Can I Use** — browser support data
4. **NNGroup articles** — usability research on specific patterns

When you find conflicting guidance (e.g., "always show scroll bars" vs. "auto-hide"), note
both perspectives and recommend the more discoverable option, citing the accessibility or
usability rationale.

---

## Step 4: Produce Fixes

For each issue found, provide:

1. **The problem** — what's wrong and when it manifests (which viewport sizes, which browsers)
2. **The evidence** — what best practice or guideline supports the fix (cite the source)
3. **The fix** — exact code changes, using Edit-style before/after blocks
4. **The tradeoff** — if the fix has any downsides (e.g., "always-visible scrollbars take up
   ~15px of horizontal space"), state them honestly

Group fixes by severity:
- **Critical** — Content is inaccessible or invisible at common viewport sizes
- **Major** — Content is accessible but hard to discover or use
- **Minor** — Cosmetic issues or suboptimal patterns that work but could be better

---

## Step 5: Produce the Report

Write a structured Markdown report:

```
# UI Visual Review: [Component/Page Name]

## Summary

[1-3 sentence overview: what was reviewed, how many issues found, overall assessment]

## Environment

- **Files reviewed:** [list]
- **Target viewports:** [small/medium/large or specific breakpoints]
- **Target browsers:** [list]

## Critical Issues

### [Issue title]

**Problem:** [description]
**Viewport:** [which sizes are affected]
**Best practice:** [source and recommendation]
**Fix:**
\`\`\`css
/* Before */
[old code]

/* After */
[new code]
\`\`\`
**Tradeoff:** [any downsides]

## Major Issues

[same format]

## Minor Issues

[same format]

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| [e.g., Visible scroll affordances] | [e.g., NNGroup, WCAG 1.4.10] | [e.g., Changed overflow:hidden to overflow:auto with visible scrollbar] |

## Viewport Verification Checklist

- [ ] 360px mobile: content reachable, no horizontal overflow, touch targets adequate
- [ ] 1366x768 (common laptop): all action buttons visible without scrolling
- [ ] 1920x1080 (standard desktop): layout fills space without excessive whitespace
```

---

## Affordance Principles Reference

These principles are grounded in accessibility standards (WCAG 2.2), NNGroup usability
research, and the enduring lessons of desktop UI design. Use them as defaults when project
guidelines are silent and modern design-system guidance is ambiguous:

1. **Scroll indicators are visible** when content exceeds its container. The user should never
   have to guess whether more content exists. Use `overflow-y: auto` with visible scroll bars;
   consider `scrollbar-gutter: stable` to prevent layout shift when scroll bars appear/disappear.
   (NNGroup recommends visible scroll affordances when content is scrollable.)

2. **Interactive elements are visually distinct.** Buttons have borders, backgrounds, and
   active/pressed states that make them obviously clickable. (NNGroup: flat UI elements with
   weak signifiers require more user effort. WCAG 2.5.8: minimum target size 24x24px
   Level AA; WCAG 2.5.5: 44x44px Level AAA.)

3. **Form inputs have visible borders.** A borderless text field is indistinguishable from a
   label. (WCAG 1.4.11: non-text contrast — UI components must have 3:1 contrast against
   adjacent colors.)

4. **Menus and dropdowns have visible affordances** (arrows, chevrons) indicating they can be
   opened.

5. **Disabled elements are visibly disabled** — grayed out, not just slightly faded.

6. **Loading and progress states are communicated.** Never leave the user staring at a blank
   screen during a load. (WCAG 4.1.3: status messages must be programmatically determinable.)

7. **Focus indicators are obvious.** Keyboard users must always know which element is focused.
   (WCAG 2.4.7: focus visible. WCAG 2.4.13: focus appearance — minimum area and contrast,
   Level AAA.)

8. **Prefer redesigning layout over adding scroll.** If content can be restructured to fit
   without scrolling, that is better than a visible scroll bar. Scroll bars are a fallback,
   not a first choice.

When searching for guidance, include terms like "WCAG", "UI affordance", "visible feedback",
"discoverability" alongside the specific CSS or layout question.

---

## Suppressing Known Findings

When a project intentionally deviates from the checklist (e.g., borderless inputs as a design
choice, auto-hiding scrollbars per design system), findings will recur on every diff. To
prevent noise:

1. **Project-local guidelines** — the primary suppression mechanism. If
   `docs/UI_LAYOUT_GUIDELINES.md` (or equivalent) documents an intentional pattern, the skill
   respects it and does not flag it.
2. **Inline suppression comments** — if a component intentionally uses a pattern the checklist
   would flag, an inline comment like `// ui-review: intentional overflow-hidden` signals that
   this was a deliberate choice. Do not flag code with such comments.
3. **Report deduplication** — if a prior review report exists in `docs/reviews/` and a finding
   matches one already acknowledged by the author (status updated to "acknowledged" or
   "won't fix"), do not re-report it.
