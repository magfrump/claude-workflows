---
name: ui-visual-review
description: >
  Review and fix visual/layout issues in UI code — cross-resolution compatibility,
  scrollability, overflow handling, sizing, affordance, focus order, and 3D viewport
  rendering. Triggers on ANY visible UI element, not just CSS: TSX/JSX, Vue, Svelte,
  Tailwind, CSS-in-JS, Unity/C# UI components (Button, Toggle, Selectable subclasses),
  SwiftUI views, native mobile layouts, and 3D rendering surfaces (three.js,
  react-three-fiber, Babylon, model-viewer, Unity WebGL, Unreal Pixel Streaming,
  .glb/.gltf). Validates recommendations against accessibility standards (WCAG 2.2),
  NNGroup usability research, and platform UI guidance. Use this skill when the user
  reports visual elements that are cut off, overlapping, invisible at certain
  resolutions, or otherwise broken across screen sizes. Also trigger on any of:
  "fix the layout", "make this responsive", "review the UI", "check visual elements",
  "audit the CSS", "review the layout", "check the UI", "fix the styling", "responsive
  design review", "is this responsive", "does this work on mobile", "layout review", or
  when a diff touches any file containing rendered UI — including TSX/JSX, CSS, SCSS,
  Tailwind class strings, Unity C# UI scripts, or 3D scene setup. Produces concrete
  code fixes plus a structured report of findings. NOTE: This skill can be invoked
  standalone or by a code-review orchestrator. If a code-fact-check report is
  provided, use it as your foundation for understanding what the code actually does
  and do not re-verify documented behavior.
when: User asks to review, audit, or fix visual/layout issues in UI code, or diff touches any UI rendering code (TSX/JSX, CSS, Tailwind, Unity C# UI, SwiftUI, 3D rendering)
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

Review UI code for visual/layout problems — elements that disappear, overflow, overlap, or become unusable at different screen sizes. Produce concrete fixes grounded in accessibility standards and usability research.

**Trigger scope.** Activates on **any visible UI element**, not just CSS or stylesheets: TSX/JSX (React, Preact, Solid), Vue templates, Svelte components, Tailwind class strings, CSS-in-JS, Unity C# UI components (`Button`, `Toggle`, `Slider`, `Selectable` subclasses), SwiftUI views, and 3D scene setup (three.js, react-three-fiber, Babylon, model-viewer, Unity WebGL, Unreal Pixel Streaming, `.glb`/`.gltf` asset wiring). If the diff renders something the user can see, it is in scope.

Core principles (overflow handling, control placement, sizing, affordance, focus order) apply across frameworks. Most examples use web/Tailwind; for non-web frameworks, adapt to the equivalent layout system (Unity's `RectTransform` and `LayoutGroup`, SwiftUI's `GeometryReader`, etc.).

**Primary job:** mechanical bug-finding — catching layout patterns that break at different viewport sizes. Objective work; the core value of this skill. The Step 2 checklist is your main tool.

**Secondary job**, when relevant: affordance review — checking interactive elements are discoverable and distinguishable. Grounded in:

- **WCAG 2.2** — visible focus indicators (2.4.7), focus not obscured (2.4.11), focus
  appearance (2.4.13, Level AAA), minimum target sizes (2.5.8), content reflow (1.4.10)
- **NNGroup research** — flat UI elements with weak signifiers require more user effort;
  interactive elements must be visually distinguishable from static content
- **European Accessibility Act (2025)** — EU law requiring digital accessibility via
  EN 301 549 / WCAG 2.1 AA

Guiding principle: **users should never have to guess** whether they can scroll, click, or interact with an element. When minimalist aesthetics conflict with discoverability, prefer discoverability — especially in tool-like web applications where task completion matters more than first impressions.

---

## Mandatory Execution Rules

1. **Project-local guidelines are your primary authority.** Before anything else, check
   for a project-local UI guidelines document (e.g., `docs/UI_LAYOUT_GUIDELINES.md`). If
   one exists, it captures patterns already validated in this codebase — follow it.
   Everything below fills gaps where the project has no guidance.

2. Avoid recommending solutions that hide content or affordances. If content overflows,
   make the overflow visible and scrollable — do not clip it silently.

3. Reason about recommendations at three viewport widths:
   - Small mobile (320px–480px)
   - Tablet/small laptop (768px–1024px)
   - Large desktop (1920px+)

   You are reviewing code, not running a browser. "Reason about" means analyzing the
   CSS or layout setup to determine what will happen at each width, not visually testing.

4. Do not introduce CSS that requires vendor prefixes without noting which browsers
   need them.

5. **Search the web when uncertain** — not for every issue. For well-understood CSS
   patterns (flex overflow, scroll containers, positioning), your training data is
   sufficient. Search when you encounter unfamiliar properties, need to check browser
   compatibility for newer CSS features, or when the project lacks local guidelines.
   When you search, prioritize: MDN Web Docs, WCAG 2.2 guidelines, Apple HIG /
   Material Design, NNGroup articles.

---

## Step 1: Determine Scope

Ask the user or infer from context:

- Which files contain the UI code to review? (HTML, CSS, JSX/TSX, Vue, Svelte, C#/Unity,
  SwiftUI, 3D scene code, etc.)
- Is there a specific visual problem reported, or is this a general audit?
- Target platform? (Default for web: modern evergreen browsers + mobile Safari. Unity:
  target resolutions from player settings. Native: platform design guidelines.)

If the user points to a specific problem (e.g., "the sidebar disappears on small screens"), focus there first, then scan for related issues in the same component tree. If a general audit, read all relevant layout and styling files.

---

## Review Modes

Two modes. The mode determines which checklist items to run.

**Mechanical review (default)** — Runs checklist items 1–5 and 8 only. Objective layout bug checks with clear right/wrong answers. Default when triggered by the code-review orchestrator or reviewing a specific diff. No web search unless genuinely uncertain about a CSS property. Fast and low-noise.

**Full audit** — Runs all checklist items, including affordance review (item 6) and responsive/cross-browser checks (item 7). Use when the user explicitly asks for a "UI audit", "review the UI", "check accessibility", or "audit the CSS". Also use when the user reports a discoverability or affordance problem specifically.

The mode split exists because items 1–5 and 8 are mechanical pattern-matching where AI agents are reliably accurate, while items 6–7 involve subjective judgment that can generate false positives in projects using modern component libraries.

**Runtime verification** is an optional add-on to either mode. When the project is a web application with a runnable dev server and you have browser-automation tooling, runtime checks validate static findings in an actual browser. See `references/runtime-verification.md` for the full procedure. Activate when the user says "test in browser", "check it visually", "run the app and verify", or when the project has Playwright/Puppeteer/Cypress available.

---

## Step 2: Read the Code

Read the relevant files completely. Look for the following, ordered by how frequently they cause real bugs.

### 1. Unbounded content without scroll caps (most common)

- Containers whose children can grow without limit (lists, error output, file uploads)
  but lack a `max-h-*` constraint + `overflow-auto`
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

- Buttons, toggles, or action bars inside an `overflow-auto` container — they scroll
  away and become inaccessible
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

- **`shrink-0`** — sizes to content, never shrinks. For: headers, footers, control
  bars, buttons.
- **`flex-1 min-h-0`** — fills remaining space. For: content areas, editors, scrollable
  regions.
- Mixing these up causes layout stretch (content area given `shrink-0`) or collapse
  (header given `flex-1`).

Ask for each element: "Should this size to its content or fill available space?"

### 4. Absolute positioning anchored to wrong parent

- An `absolute`-positioned element attaches to its nearest `relative` ancestor
- When multiple sections exist side-by-side, verify the element is inside the correct
  section
- Common bug: floating bar in outer div overlaps all sections instead of just its target
- **Unity equivalent**: a `RectTransform` anchored to the wrong parent Canvas or Panel,
  causing elements to scale or position relative to the full screen instead of their
  intended container

### 5. Excessive vertical spacing

- Padding and gaps that waste vertical space, pushing controls below the fold on small
  viewports
- Prefer compact defaults: `p-4` over `p-6`, `gap-3` over `gap-4`, `rows={3}` over
  `rows={8}`
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

For diff-scoped mechanical state-coverage checks on interactive elements actually touched by the diff (default/hover/focus/active/disabled/error), see item 8 — that runs in default mechanical-review mode, while the broader affordance review here remains full-audit only.

Discoverability is not only about making elements visible. Also consider:

- **Progressive disclosure** — showing controls in context when relevant, rather than
  displaying everything at once (which creates its own discoverability problem through
  clutter)
- **Consistent placement** — controls that appear in predictable locations are more
  discoverable than prominently styled controls in unexpected places
- **Redesigning to avoid overflow** — the best scroll bar is one you don't need. Before
  adding scroll indicators, ask whether the layout can be restructured to fit the content
- **Default-Cost-of-Reversal** — when the diff introduces a UI that presents a
  preselected default (radio button, dropdown, toggle, suggested value, prechecked
  checkbox, opt-in modal with a primary action prefocused), confirm two things:
  - **Reversal path is no more than one user action.** The user must be able to undo or
    change the default by flipping the same control or selecting an adjacent
    alternative — not by navigating to a settings page, reopening a modal, or hunting
    through a menu tree.
  - **Default is equally visible as the alternatives.** The default and its alternatives
    must share control size, contrast, and proximity to the commit action so the user
    perceives a choice rather than an unmarked path.

  **Flag silent opt-ins.** A silent opt-in is a default that takes effect without ever
  surfacing the choice in the user's primary flow — a "share with team" checkbox
  prechecked inside a confirmation step the user assumed was just a Save button, an
  analytics toggle defaulted on in a sub-page the user never visits during normal
  onboarding. Silent opt-ins fail both criteria and should be flagged as a critical
  affordance issue, not a minor one.

  **Carve-out for user-confirmed defaults.** When the default reflects a value the user
  previously set explicitly — saved preferences, "remember my choice", account-level
  settings, the last-used value the user selected in a prior session — the rule does
  not apply. The UI is honoring prior input rather than imposing a new one. To make
  this carve-out auditable, the diff should include a nearby comment naming the
  preference source (e.g., `// default from userPrefs.defaultExportFormat — set by user
  in Settings`).

### 7. Responsive and cross-browser concerns *(full audit mode only)*

- Fixed dimensions (`width: 500px`) that won't adapt to viewport changes
- Missing viewport meta tag
- Media queries that leave gaps between breakpoints
- Text that doesn't reflow on narrow viewports (missing `overflow-wrap: break-word`)
- CSS properties with incomplete browser support (check via web search when relevant)

### 8. Interactive element state matrix *(when diff touches interactive elements)*

**Activation trigger.** Run this section when the diff adds or modifies any interactive element. "Interactive element" means anything a user can operate:

- HTML/JSX: `<button>`, `<a href>`, `<input>`, `<textarea>`, `<select>`, `<summary>`,
  elements with `onClick`/`onKeyDown`/`onChange` handlers, elements with `role="button"`
  / `role="link"` / `role="checkbox"` / `role="tab"` / `role="menuitem"` / etc., and
  custom components that wrap any of the above (e.g., `<Button>`, `<TextField>`,
  `<Dropdown>`)
- Unity/C#: `Button`, `Toggle`, `Slider`, `InputField`, `TMP_InputField`, `Dropdown`,
  anything with an `EventTrigger` or `Selectable` subclass
- Other frameworks: equivalent control primitives (Vue/Svelte form inputs, SwiftUI
  `Button`/`Toggle`/`TextField`, etc.)

**Scope.** Strictly diff-scoped. Verify states only for elements the diff *adds or modifies* — not every interactive element on the page.

**The matrix.** For each in-scope element, verify these six states are handled. "Handled" means the state is either explicitly styled, explicitly inherited from a documented design system primitive, or explicitly N/A.

| State | What to verify | Common failure |
|-------|---------------|----------------|
| **Default** | Element is visible and visually distinct from surrounding non-interactive content (border, background, cursor, or other affordance). | Borderless input indistinguishable from a label; "ghost" button with no edge. |
| **Hover** | Pointer hover triggers a perceptible change (background, border, color, cursor). Skip on touch-only contexts but verify pointer contexts still get it. | `:hover` styles missing on a custom `<div role="button">`; hover applied to the wrapper instead of the interactive child. |
| **Focus** | Keyboard focus produces a visible indicator that meets WCAG 2.4.7 (visible) and ideally 2.4.13 (sufficient area + contrast). The indicator must not rely on color alone. | `outline: none` with no replacement; focus ring clipped by an `overflow: hidden` ancestor; focus ring on the wrong element after a custom focus delegation. |
| **Active** | The pressed/clicked state is visually distinguishable (depressed style, color shift, or animation) so the user gets feedback that the action registered. | `:active` style absent — clicks feel "dead"; for custom controls, no `aria-pressed` / `aria-expanded` toggling. |
| **Disabled** | Disabled elements are visibly disabled (sufficiently dimmed, not just slightly faded), do not respond to hover/focus interactivity, and expose `disabled` / `aria-disabled` to assistive tech. | `opacity: 0.9` reads as enabled; element is `aria-disabled` but still receives click handlers. |
| **Error** *(form inputs and validatable controls only)* | Error state is conveyed by more than color (border + icon + text, or border + `aria-invalid` + linked error message via `aria-describedby`). N/A for non-validatable elements like plain buttons or links — mark explicitly. | Red border with no icon or text (fails WCAG 1.4.1 use of color); error message present visually but not associated via `aria-describedby`. |

**Per-element checklist format.** When reporting, list each in-scope interactive element once with a row per state:

```
- [ ] <SubmitButton> (src/components/SubmitButton.tsx:42)
  - [x] default — `bg-blue-600 text-white border` ✓
  - [x] hover — `hover:bg-blue-700` ✓
  - [ ] focus — no `focus-visible` ring; `outline: none` from reset is not replaced
  - [x] active — `active:bg-blue-800` ✓
  - [x] disabled — `disabled:opacity-50 disabled:cursor-not-allowed` ✓
  - [N/A] error — button is not a validatable control
```

Common failure modes: single-state styling (only default defined), hover-only feedback (no focus state), `outline: none` without replacement, disabled-but-clickable (`aria-disabled` set but click handler still fires), color-only error state, state applied to wrapper instead of interactive child, inconsistent coverage across the diff.

### 9. 3D viewport rendering *(when 3D content is present)*

When the diff or scope includes three.js, react-three-fiber, Babylon, `<model-viewer>`, Unity WebGL, Unreal Pixel Streaming, or `.glb`/`.gltf` references, load `references/3d-viewport.md` and run that checklist. It covers camera controls, clipping planes, lighting, transparency/depth ordering, gizmos, asset bounds vs. viewport, and runtime perf indicators. Runtime verification is strongly recommended for 3D content — static analysis cannot predict whether the camera ends up framing the model.

### 10. Accessibility serialization and tab traversal *(when HTML structure, ARIA, focusables, or AI-generated content changes)*

When the diff touches semantic HTML/JSX structure (headings, landmarks), ARIA attributes, `alt` text, focusable elements, `tabindex`, or LLM-generated content rendering, load `references/accessibility-serialization.md`. It covers the ARIA-versus-visible-text equivalence check, diff-scoped tab order verification, and the persistent-label requirement for AI-generated content.

### 11. Element overlap, z-order, and occlusion *(spatial / 3D layouts)*

**Activation trigger.** Run this item when the diff touches a layout where elements are *meant* to share space and stack — not the document-flow layouts items 1–5 cover, but spatial ones: game boards and the pieces on them, draggable/droppable tokens, stacked or floating panels, overlays and HUDs layered over a canvas or viewport, absolutely- or fixed-positioned interactive layers, and 3D scenes (three.js, react-three-fiber, Babylon, Unity) where objects occlude each other. Like items 9 and 10, this triggers on the *presence of that content*, regardless of mechanical-vs-full-audit mode.

**Why this is its own item.** Items 1–5 assume content should *not* overlap (overflow, clipping, and mis-anchored absolute positioning are all "things ended up on top of each other by mistake"). Spatial layouts invert that assumption: overlap is the *medium*. A card deck stacks on purpose; a modal is supposed to cover the board; a held piece floats above the squares. So the bug is never "things overlap" — it is "the *wrong* thing is on top," and an item that flagged every overlap would be pure noise on exactly the layouts it is meant to help.

**Discriminate by construction — confirm intent before flagging.** Enumerate the overlapping/stacked elements in the changed layout, then sort each overlap into one of two buckets. Flag only the first.

| Bucket | What it looks like | Action |
|--------|--------------------|--------|
| **Unintended occlusion** (bug) | An interactive control hidden behind another element (a button under a panel, a draggable handle covered by an overlay so it can't be grabbed); a game piece or token clipped *outside* the board/container bounds or rendered behind the board so it's unreachable; a tooltip/label drawn under the element it describes; a higher-priority layer (active modal, dragged item) painted *below* a lower-priority one because `z-index`/`renderOrder`/sibling order is inverted. | **Flag.** Cite the occluding pair and the inverted stacking source (`z-index`, DOM/sibling order, Unity sibling index / `Canvas.sortingOrder`, three.js `renderOrder`). |
| **Intended layering** (not a bug) | A deliberately stacked card pile, fanned hand, or token stack; a modal/overlay/drawer that is *supposed* to cover what's beneath it; a held/dragged piece floating above the board mid-interaction; a HUD layer pinned over a viewport. | **Do not flag.** If intent is plausible but unconfirmed, ask or note the assumption rather than reporting it as a defect. |

Discriminating question for each overlap: **"Is the element on top supposed to be on top, and can the user still reach everything they need to?"** If yes → intended layering, leave it. If a control the user must operate is unreachable, or a piece has left its legal bounds → unintended occlusion, flag it. When the diff makes intent ambiguous and you can't resolve it from surrounding code, surface it as a question (or an inline-suppression candidate, per *Suppressing Known Findings*), not a Critical finding.

For the *rendering-pipeline* causes of 3D occlusion (transparent meshes drawn in the wrong order, gizmos hidden inside the model, geometry clipped by near/far planes), this item defers to `references/3d-viewport.md` — that file covers `material.transparent`, `renderOrder`, `depthTest`/`depthWrite`, and clipping planes. This item is about layout *intent* (which element should be on top); load the 3D reference for *how* the renderer decides draw order.

---

## Step 3: Research When Uncertain

You do not need to search for every issue. For well-understood CSS patterns, apply your knowledge directly.

**Search the web when:**

- You encounter a CSS property or browser behavior you're unsure about
- You need to verify browser compatibility for newer features (e.g., `scrollbar-gutter`,
  container queries, `dvh` units)
- The project lacks local guidelines and you need to determine current best practices
- You're unsure whether a recommendation aligns with WCAG 2.2 requirements

**When you search, prioritize:** MDN Web Docs, WCAG 2.2 specification, Can I Use, NNGroup articles. When you find conflicting guidance, note both perspectives and recommend the more discoverable option, citing the accessibility or usability rationale.

---

## Step 4: Produce Fixes

For each issue found, provide:

1. **The problem** — what's wrong and when it manifests (which viewport sizes, which
   browsers)
2. **The evidence** — what best practice or guideline supports the fix (cite the source)
3. **The fix** — exact code changes, using before/after blocks
4. **The tradeoff** — if the fix has any downsides (e.g., "always-visible scrollbars
   take up ~15px of horizontal space"), state them honestly

---

## Step 5: Produce the Report

Output your review as a Markdown document at `docs/reviews/ui-visual-review.md`.

The **Keyboard Navigation** subsection (see below) is **required** in every report — even when the diff introduces no focusable elements. In that case, state so explicitly rather than omitting the section.

### Title and Header

Open with a top-level title that includes "UI Visual Review" so the report is discoverable. Follow with these header fields so readers know what was reviewed and when:

```markdown
# UI Visual Review — [short scope label, e.g., PR #347 or component name]

**Scope:** [branch diff / file list / component under review]
**Date:** [YYYY-MM-DD]
```

If you've been given a fact-check report or other upstream artifact, add a `**Based on:**` line naming it. Keep the header to 3–5 lines.

### Environment

Document the review context so readers can reproduce or extend it:

```markdown
## Environment

- **Files reviewed:** [list]
- **Target viewports:** [small/medium/large or specific breakpoints]
- **Target browsers / platforms:** [list]
- **Review mode:** [Mechanical | Full audit]
```

### Findings

For each finding, use this structure:

```markdown
#### [Finding title]

**Severity:** [Critical / Major / Minor / Informational]
**Location:** `path/to/file.ext:42-58`
**Issue type:** [Overflow | Sizing | Positioning | Occlusion / z-order | Affordance | Focus | Responsive | 3D | Accessibility serialization | State coverage | Other]
**Viewport:** [which sizes are affected, e.g., 320px–768px; or "all"]
**Move:** [Which checklist item surfaced this, e.g., "Step 2 item 1: unbounded content"]
**Confidence:** [High / Medium / Low]

[2–5 sentences: what's broken, when it manifests, what best practice it violates
(cite WCAG / NNGroup / MDN where relevant).]

**Recommendation:** [1–3 sentences plus a before/after code block when the fix is
mechanical.]
```

**Severity guidelines:**

- **Critical** — Content is inaccessible or invisible at common viewport sizes; user
  cannot complete the primary task; accessibility violation that locks out a class of
  users (e.g., focus trap, missing labels on AI content adjacent to human content)
- **Major** — Content is accessible but hard to discover or use; affordance is weak;
  tab order disagrees with visible order; touch target below AA minimum
- **Minor** — Cosmetic issues or suboptimal patterns that work but could be better;
  excessive spacing; redundant scroll bars
- **Informational** — Hardening opportunities, defense-in-depth suggestions

Order findings by severity (Critical first), then by confidence.

### What Looks Good

Note layout and affordance patterns in the diff that are correctly implemented. This prevents the review from being purely negative and confirms which parts don't need rework.

### Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| [e.g., Visible scroll affordances] | [e.g., NNGroup, WCAG 1.4.10] | [e.g., Changed `overflow:hidden` to `overflow:auto`] |

### Keyboard Navigation

Required section. The diff is **in scope for keyboard review** if it adds or modifies any focusable element (buttons, links, inputs, custom widgets with `tabindex` or keyboard handlers, Unity `Selectable` subclasses, SwiftUI `.focusable()` views, etc.) or any modal/overlay/dropdown/popover that manages focus. If none of the above are touched, write exactly:

> No new focusable elements in this diff.

…and skip the four items below. Otherwise, address each item explicitly — do not omit an item; if it does not apply, mark it `N/A` with a one-line reason.

**Focus order.** Walk Tab through the changed elements and confirm the keyboard path matches visible reading order. List the in-scope focusables in their actual tab order (file:line + brief reachability note). Flag any DOM-versus-visual mismatch (caused by `flex-direction: row-reverse`, CSS `order`, grid placement, or absolute positioning) as a WCAG 2.4.3 violation. For the full tab traversal procedure and output format, see `references/accessibility-serialization.md`.

**Escape-key behavior.** For every modal, overlay, dropdown, popover, or other focus-managing region added or modified in the diff, confirm that `Escape` dismisses it and returns focus to the element that opened it. Cite the handler location (file:line) or flag its absence. If the diff modifies no such regions, write `N/A — no modals or overlays in this diff.`

**Skip-link presence.** If the diff introduces or restructures page-level landmarks (`<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>`) or top-of-page navigation, verify a skip-link to main content exists, is the first focusable element, and becomes visible on focus (WCAG 2.4.1 Bypass Blocks). If a skip-link already exists in the codebase, verify the diff has not broken it (target ID still present, link still first in tab order). If the diff touches no page-level structure, write `N/A — diff does not change page-level structure.`

**Focus-trap risks.** Identify any modal, overlay, drawer, or off-screen-but-focusable region added or modified that could trap keyboard users without an escape path (WCAG 2.1.2 No Keyboard Trap). Common culprits: modal without `Escape` handler and no focusable close button; drawer hidden via `transform: translateX(-100%)` whose contents remain in the tab path; `aria-disabled="true"` controls still receiving focus. For each risk, cite location and proposed fix. If none, write `No focus-trap risks identified.`

### Viewport Verification Checklist

- [ ] 360px mobile: content reachable, no horizontal overflow, touch targets adequate
- [ ] 1366x768 (common laptop): all action buttons visible without scrolling
- [ ] 1920x1080 (standard desktop): layout fills space without excessive whitespace

### Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | …       | Critical | Overflow   | `f:42`   | High       |

### Overall Assessment

One paragraph: what's the visual/layout posture of this change? Are the issues fixable in place or do they indicate a structural problem? What's the single most important thing to address?

---

## Affordance Principles Reference

These principles are grounded in accessibility standards (WCAG 2.2), NNGroup usability research, and the enduring lessons of desktop UI design. Use them as defaults when project guidelines are silent and modern design-system guidance is ambiguous:

1. **Scroll indicators are visible** when content exceeds its container. Use
   `overflow-y: auto` with visible scroll bars; consider `scrollbar-gutter: stable` to
   prevent layout shift. (NNGroup recommends visible scroll affordances when content is
   scrollable.)

2. **Interactive elements are visually distinct.** Buttons have borders, backgrounds,
   and active/pressed states. (NNGroup: flat UI elements with weak signifiers require
   more user effort. WCAG 2.5.8: minimum target size 24x24px Level AA; WCAG 2.5.5:
   44x44px Level AAA.)

3. **Form inputs have visible borders.** A borderless text field is indistinguishable
   from a label. (WCAG 1.4.11: non-text contrast — UI components must have 3:1 contrast
   against adjacent colors.)

4. **Menus and dropdowns have visible affordances** (arrows, chevrons) indicating they
   can be opened.

5. **Disabled elements are visibly disabled** — grayed out, not just slightly faded.

6. **Loading and progress states are communicated.** (WCAG 4.1.3: status messages must
   be programmatically determinable.)

7. **Focus indicators are obvious.** Keyboard users must always know which element is
   focused. (WCAG 2.4.7; 2.4.13 Level AAA.)

8. **Prefer redesigning layout over adding scroll.** Scroll bars are a fallback, not a
   first choice.

When searching for guidance, include terms like "WCAG", "UI affordance", "visible feedback", "discoverability" alongside the specific CSS or layout question.

---

## Suppressing Known Findings

When a project intentionally deviates from the checklist, findings will recur on every diff. To prevent noise:

1. **Project-local guidelines** — the primary suppression mechanism. If
   `docs/UI_LAYOUT_GUIDELINES.md` (or equivalent) documents an intentional pattern, the
   skill respects it and does not flag it.
2. **Inline suppression comments** — `// ui-review: intentional overflow-hidden` signals
   that this was a deliberate choice. Do not flag code with such comments.
3. **Report deduplication** — if a prior review report exists in `docs/reviews/` and a
   finding matches one already acknowledged by the author (status updated to
   "acknowledged" or "won't fix"), do not re-report it.

---

## References

- `references/3d-viewport.md` — full 3D viewport rendering checklist (camera, clipping,
  lighting, transparency, gizmos, asset bounds, perf overlays). Load when the diff
  touches three.js, react-three-fiber, Babylon, model-viewer, Unity WebGL, Unreal
  Pixel Streaming, or `.glb`/`.gltf` assets.
- `references/accessibility-serialization.md` — ARIA/visible-text equivalence,
  diff-scoped tab traversal, AI-generated content labeling. Load when the diff touches
  HTML/JSX semantics, ARIA, focusable elements, or LLM output rendering.
- `references/runtime-verification.md` — optional runtime verification procedure
  (screenshot capture, cross-resolution checklist, console analysis, visual regression).
  Load when the project has a runnable dev server and browser automation tooling.
