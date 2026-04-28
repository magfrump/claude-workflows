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

1. **Project-local guidelines are your primary authority.** Before doing anything else, search
   for a project-local UI guidelines document. Check these paths in order, stopping at the
   first match:
   1. `docs/UI_LAYOUT_GUIDELINES.md`
   2. `docs/ui-guidelines.md`
   3. `docs/design-system.md`
   4. `STYLE.md`
   5. Any markdown file in `docs/` referencing UI or layout standards (grep `docs/*.md` for
      terms like "UI guidelines", "layout standards", "design system", "style guide")

   If one exists, it captures patterns already validated in this codebase — follow it.
   Everything below fills gaps where the project has no guidance. Searching beyond the
   canonical path reduces false positives where the skill flags patterns the project
   intentionally uses simply because the guideline doc lives at a different filename.

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

**Runtime verification (Step 6)** — an optional add-on to either mode. When the project is a
web application with a runnable dev server, Step 6 validates static analysis findings in an
actual browser. This catches issues that code analysis alone misses (e.g., font rendering,
actual scrollbar behavior, runtime-injected styles). Activate when the user says "test in
browser", "check it visually", "run the app and verify", or when the project has browser
automation tooling available.

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

## Post-Implementation Visual Fix Tracking

**Issues found after this review that required manual visual fixes:** [count]
**Issues caught by this review before they shipped:** [count]
```

---

## Step 6: Runtime Verification (Web Applications)

Steps 1–5 review code statically — analyzing CSS and layout logic to predict what will happen
at different viewport sizes. This step validates those predictions by running the application
in a browser. **This step is optional** and only applies when: (a) the project is a web
application with a runnable dev server, and (b) you have access to browser automation or
screenshot tools (Puppeteer, Playwright, Cypress, or manual browser access).

Skip this step if the project has no runnable frontend or if you are operating as a sub-critic
within the code-review orchestrator (where runtime access is typically unavailable).

### 6a. Screenshot Capture Procedures

Capture screenshots at each verification breakpoint to create a visual record of the current
state. This serves two purposes: documenting what the UI looks like *now* (for comparison
after future changes) and providing evidence for issues found in the static review.

**Procedure:**

1. Start the dev server (`npm run dev`, `yarn dev`, or project-equivalent)
2. Capture screenshots at each breakpoint defined in the cross-resolution checklist (6b)
3. For each page or component under review, capture:
   - Default state (page load, no interaction)
   - Key interaction states (modal open, dropdown expanded, form with validation errors,
     long content that triggers scroll)
   - Edge cases flagged during the static review (Steps 2–4)
4. Save screenshots to `docs/reviews/screenshots/` with naming convention:
   `{component}-{viewport}-{state}.png` (e.g., `sidebar-360px-collapsed.png`)

**Automation example (Playwright):**
```js
const viewports = [
  { width: 360, height: 800, name: 'mobile' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 1366, height: 768, name: 'laptop' },
  { width: 1920, height: 1080, name: 'desktop' },
];

for (const vp of viewports) {
  await page.setViewportSize({ width: vp.width, height: vp.height });
  await page.screenshot({ path: `docs/reviews/screenshots/${component}-${vp.name}-default.png`, fullPage: true });
}
```

**When doing this manually:** Use browser DevTools device toolbar to set exact viewport
dimensions. Take screenshots with the OS screenshot tool or DevTools capture. The key is
consistency — same viewports, same states, every time.

### 6b. Cross-Resolution Verification Checklist

Run through this checklist at each breakpoint. This is the runtime counterpart to the static
analysis in Step 2 — you are confirming (or refuting) what the code review predicted.

**Breakpoints:**

| Category | Width | Represents | Key concerns |
|----------|-------|-----------|--------------|
| Small mobile | 360px | Typical Android phone | Touch targets, horizontal overflow, text truncation |
| Large mobile | 428px | iPhone Pro Max / large Android | Same as above, catches tight-but-not-broken layouts |
| Tablet portrait | 768px | iPad portrait | Sidebar collapse behavior, grid reflow |
| Small laptop | 1366px | Most common laptop | Action buttons above fold, no dead space |
| Desktop | 1920px | Standard monitor | Layout fills space, no extreme stretching |

**At each breakpoint, verify:**

- [ ] No horizontal scrollbar appears (unless intentional, e.g., data tables)
- [ ] All text is readable without zooming (minimum 16px body text on mobile)
- [ ] Interactive elements are reachable without scrolling past the fold (especially
      submit buttons, primary actions)
- [ ] Touch targets meet minimum size (24x24px AA, 44x44px AAA) on mobile/tablet
- [ ] Images and media scale without overflow or distortion
- [ ] Navigation is accessible (hamburger menu works on mobile, sidebar visible on desktop)
- [ ] Modals and overlays don't overflow the viewport
- [ ] Scroll containers scroll smoothly and have visible scroll affordances
- [ ] No content is clipped by `overflow: hidden` (compare against static review findings)
- [ ] Form inputs are usable (labels visible, fields not too narrow to type in)

**Record each breakpoint result** in the review report (Step 5) under the
"Viewport Verification Checklist" section, converting checkboxes to pass/fail with notes
on any discrepancies from the static analysis predictions.

### 6c. Browser Console Log Analysis

Visual bugs often have corresponding console warnings or errors that point to the root cause.
Check the browser console as part of runtime verification.

**What to look for:**

1. **Layout-related warnings:**
   - `ResizeObserver loop limit exceeded` — often indicates a resize-triggered re-render
     loop; can cause jank or layout instability
   - Image dimension warnings (missing `width`/`height` attributes causing layout shift)
   - Font loading failures (FOUT/FOIT causing text reflow)

2. **React/framework-specific warnings:**
   - `Warning: Each child in a list should have a unique "key" prop` — can cause
     unexpected re-renders that affect visual state
   - Hydration mismatch warnings (SSR) — server and client rendering different layouts
   - `Warning: validateDOMNesting` — invalid HTML nesting that may cause browser layout
     quirks

3. **CSS-related errors:**
   - Failed asset loads (404 for stylesheets, fonts, images) — broken visual elements
   - CORS errors on font or stylesheet loads

4. **Performance indicators visible in console:**
   - Layout thrashing warnings (if using performance monitoring)
   - Long task warnings

**Procedure:**

1. Open DevTools Console before loading the page (to catch warnings during initial render)
2. Clear console, reload the page, note any warnings or errors
3. Perform the key interactions identified in 6a (open modals, submit forms, resize)
4. Note any new console output after each interaction
5. Cross-reference console findings with static review issues — console errors often confirm
   suspected layout problems

Include console findings in the review report under a "Console Analysis" subsection.

### 6d. Visual Regression Detection Workflow

When modifying existing UI (not building new), compare the current state against a baseline
to catch unintended changes. This is most valuable when fixing issues found in Steps 2–4 —
confirming the fix works without breaking adjacent elements.

**Manual workflow (no tooling required):**

1. Before making changes, capture baseline screenshots at all breakpoints (6a)
2. Implement the fixes from Step 4
3. Capture new screenshots at the same breakpoints and states
4. Compare side-by-side: verify the fix resolved the issue and no new regressions appeared
5. Pay special attention to:
   - Adjacent components (did fixing one element shift its neighbors?)
   - Different breakpoints (did a mobile fix break the desktop layout?)
   - Interaction states (did the fix hold up when modals open, content loads, etc.?)

**Automated workflow (when project has visual regression tooling):**

If the project uses a visual regression tool (Playwright visual comparisons, Percy,
Chromatic, BackstopJS), integrate with the existing workflow:

1. Run the baseline snapshot suite before changes
2. Implement fixes
3. Run the snapshot suite again
4. Review the diff report — approve intentional changes, investigate unexpected diffs
5. Update baseline snapshots for approved changes

**When to add visual regression tooling (recommendation, not requirement):**

Consider recommending visual regression setup when:
- The project has >5 pages or >10 distinct components
- UI changes are frequent (multiple PRs per week touching visual code)
- The team has experienced "fix one thing, break another" visual regressions
- The project already uses Playwright or Cypress for E2E tests (low marginal cost to add)

### Runtime Verification and the Review Report

When runtime verification is performed, extend the Step 5 report with:

```
## Runtime Verification Results

**Dev server:** [command used to start]
**Browser:** [browser and version]
**Verification mode:** [manual | automated | hybrid]

### Cross-Resolution Results

| Breakpoint | Status | Issues Found | Static Review Match? |
|-----------|--------|-------------|---------------------|
| 360px mobile | PASS/FAIL | [description] | [confirmed/new/contradicted] |
| 768px tablet | PASS/FAIL | [description] | [confirmed/new/contradicted] |
| 1366px laptop | PASS/FAIL | [description] | [confirmed/new/contradicted] |
| 1920px desktop | PASS/FAIL | [description] | [confirmed/new/contradicted] |

### Console Analysis

[List of console warnings/errors found and their relevance to visual issues]

### Visual Regression Summary

[If applicable: list of before/after comparisons, regressions found, regressions avoided]

### Runtime vs. Static Analysis Reconciliation

- **Confirmed by runtime:** [issues predicted by static analysis and verified in browser]
- **New issues (runtime only):** [issues not caught by static analysis]
- **False positives (static only):** [issues predicted by static analysis but not present]
```

The "Static Review Match?" column and the reconciliation section are important for
calibrating the static analysis. Over time, patterns that consistently produce false
positives or false negatives in static analysis should inform updates to the Step 2 checklist.

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
