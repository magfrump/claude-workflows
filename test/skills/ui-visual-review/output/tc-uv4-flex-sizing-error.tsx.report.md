# UI Visual Review: `subject.tsx` (AppLayout)

**Scope:** `subject.tsx` (the whole file, 30 lines)
**Date:** 2026-11-20
**Based on:** Code analysis only. No code-fact-check report was provided.

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** Small mobile (320–480px), tablet/laptop (768–1366px, including 1366×768), large desktop (1920px+)
- **Target browsers / platforms:** Modern evergreen browsers and iOS Safari (the default; no project config says otherwise)
- **Review mode:** Full audit (checklist items 1–8, plus item 10 because the file adds page landmarks; items 9 and 11 don't apply because there is no 3D or spatial/stacked content)
- **Project guidelines:** None found (no `docs/UI_LAYOUT_GUIDELINES.md` and no `docs/` directory). `references/accessibility-serialization.md` isn't in the workspace either, so item 10 was checked from the inline checklist in the skill.

## Findings

#### 1. Content area uses `shrink-0`, so the Save button gets pushed off-screen

**Severity:** Major
**Location:** `subject.tsx:17`
**Issue type:** Sizing
**Viewport:** All. It shows up first and worst at 320–768px wide and at 1366×768.
**Move:** Step 2 item 3 (wrong `shrink-0` vs `flex-1 min-h-0`), also item 2 (controls must stay reachable)
**Confidence:** High

The root is a fixed-height column (`flex flex-col h-screen`). `<main>` is set to `shrink-0`, which means "size to content and never shrink." It should fill the space between the header and footer. When the content gets taller than `100vh` minus the header and footer, `<main>` keeps its full height. It spills out of the `h-screen` container and pushes the `<footer>` and its **Save** button below the fold. The user then has to scroll the whole document to reach the main action, and the header scrolls away too. When content is short, `<main>` doesn't grow, so the footer sits right under the content instead of at the bottom of the screen. That gives an uneven layout on 1920px screens. `shrink-0` is meant for headers, footers and control bars. Content regions should use `flex-1 min-h-0`.

**Recommendation:** Make `<main>` fill the remaining space and do its own scrolling. The header and footer stay pinned. This is the docked-footer pattern.

```tsx
// Before
<main className="shrink-0 p-6">

// After
<main className="flex-1 min-h-0 overflow-y-auto p-4">
```

---

#### 2. The inner `overflow-auto` list never scrolls because nothing limits its height

**Severity:** Major
**Location:** `subject.tsx:18-22`
**Issue type:** Overflow
**Viewport:** All
**Move:** Step 2 item 1 (unbounded content without scroll caps)
**Confidence:** High

The list container has `overflow-auto` but no `max-h-*` and no flex-fill height. Its parent (`space-y-4`, a block element) doesn't limit it either. A block element with no height limit grows to fit its children, so `overflow-auto` never kicks in. The list just grows without limit, which feeds Finding 1. Only the page scrollbar appears, so the list never shows its own scroll affordance.

**Recommendation:** Choose one scroll owner. **Option A (simplest):** let `<main>` scroll, as in Finding 1, and remove the useless `overflow-auto` from the inner div. **Option B:** if the intro text should stay visible while only the list scrolls, turn the chain into a flex column so the list gets a bounded height:

```tsx
// Option B
<main className="flex-1 min-h-0 flex flex-col p-4">
  <div className="flex-1 min-h-0 flex flex-col gap-3">
    <p className="shrink-0">This content area …</p>
    <div className="flex-1 min-h-0 overflow-y-auto" tabIndex={0} aria-label="Items">
      {/* long list */}
    </div>
  </div>
</main>
```

**Tradeoff:** Option B creates a nested scroll region. Trackpad users scrolling over the paragraph won't move the list. Option A avoids that.

---

#### 3. `h-screen` (100vh) puts the footer under the browser toolbar on mobile

**Severity:** Major
**Location:** `subject.tsx:12`
**Issue type:** Responsive
**Viewport:** 320–480px on iOS Safari and Android Chrome when the URL bar or toolbar is visible
**Move:** Step 2 item 7 (responsive and cross-browser)
**Confidence:** Medium

On mobile browsers, `100vh` is the *largest* viewport size, measured as if the browser toolbars were hidden. While the toolbars are showing, the bottom ~50–100px of an `h-screen` container sits behind them. That is exactly where the Save footer is. Even after fixing Findings 1 and 2, the main action can start out partly hidden. MDN recommends dynamic viewport units (`dvh`) for this case.

**Recommendation:**
```tsx
// Before
<div className="flex flex-col h-screen">
// After (Tailwind ≥ 3.4)
<div className="flex flex-col h-screen h-dvh">
```
List `h-dvh` second so it wins where supported (Safari 15.4+, Chrome/Edge 108+, Firefox 101+). Older browsers fall back to `h-screen`. No vendor prefixes are needed. Note that both classes set `height`, so the one Tailwind generates later wins. If your Tailwind version orders them differently, use `h-[100vh] supports-[height:100dvh]:h-dvh`.

**Tradeoff:** With `dvh`, the layout resizes as the toolbar shows and hides, which can cause a small reflow while scrolling. Here the root doesn't scroll once Finding 1 is fixed, so the effect is minimal.

---

#### 4. Save button is missing hover and active states, and its focus style is only inherited

**Severity:** Major
**Location:** `subject.tsx:26`
**Issue type:** State coverage
**Viewport:** All
**Move:** Step 2 item 8 (state matrix), also item 6
**Confidence:** High

The button only has default-state styles. Nothing changes on hover or press, so clicks feel "dead." Keyboard focus relies on the browser's default outline. Tailwind Preflight doesn't remove it, so it should be visible (WCAG 2.4.7 passes). But the design never sets it, so how visible it is varies by browser, and it may not meet 2.4.13 (AAA) for size and contrast.

- [ ] `<button>Save</button>` (`subject.tsx:26`)
  - [x] default: `bg-gray-800 text-white rounded`. Clearly distinct from surrounding content ✓
  - [ ] hover: no `hover:` style
  - [~] focus: browser default outline only. No explicit `focus-visible:` ring
  - [ ] active: no `active:` style
  - [N/A] disabled: no disabled path in this code. If Save can be disabled (e.g. nothing to save, or a save in progress), add `disabled:` styles too
  - [N/A] error: a button isn't a validatable control

Target size: `py-2` plus a 24px line height gives about 40px height. That meets WCAG 2.5.8 AA (24×24) but falls short of 2.5.5 AAA (44×44).

**Recommendation:**
```tsx
// Before
<button className="py-2 px-4 bg-gray-800 text-white rounded">Save</button>
// After
<button
  type="button"
  className="min-h-11 py-2 px-4 bg-gray-800 text-white rounded
             hover:bg-gray-700 active:bg-gray-900
             focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-blue-600
             disabled:opacity-50 disabled:cursor-not-allowed"
>
  Save
</button>
```
`min-h-11` (44px) is optional. Add it if you're aiming for AAA or a comfortable touch size.

---

#### 5. Content padding (`p-6`) is larger than needed

**Severity:** Minor
**Location:** `subject.tsx:17`
**Issue type:** Sizing
**Viewport:** 320–480px, 1366×768
**Move:** Step 2 item 5 (excessive vertical spacing)
**Confidence:** Medium

On a 320px-wide phone, `p-6` uses 48px of horizontal space (15% of the width) and 48px of vertical space. The header and footer already use `p-4`. Matching them keeps the spacing consistent and gives the content more room. The "After" snippet in Finding 1 already makes this change (`p-4`).

---

#### 6. New scroll region can't be reached by keyboard in some browsers

**Severity:** Informational
**Location:** `subject.tsx:20`, or `<main>` after the Finding 1 fix
**Issue type:** Focus
**Viewport:** All
**Move:** Step 2 item 10 (tab traversal)
**Confidence:** Medium

If the scrolling list has no focusable children, keyboard users in browsers that don't make scroll containers focusable automatically (notably Safari) can't scroll it. Chrome 130+ does make them focusable. Add `tabIndex={0}` and an `aria-label` to whichever element ends up scrolling (shown in Finding 2, Option B).

## What Looks Good

- The header and footer correctly use `shrink-0`. They are fixed chrome and should size to their content.
- It uses semantic landmarks (`<header>`, `<main>`, `<footer>`) and a single `<h1>`, which gives screen readers a sensible outline.
- The Save button is a real `<button>`, not a `<div onClick>`, so it gets keyboard activation and its role for free.
- The default button has strong contrast (white on gray-800, about 12.6:1) and a clear filled appearance.
- The `border-b` and `border-t` dividers clearly separate the chrome from the content.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Fill-space regions use `flex-1 min-h-0`; chrome uses `shrink-0` | Skill item 3; MDN "Flexbox: min-height auto" | `<main>` changed from `shrink-0` to `flex-1 min-h-0` |
| Main controls stay pinned outside scroll regions | Skill item 2 (docked footer) | Footer stays put; `<main>` owns the scrolling |
| A scroll container needs a bounded height | MDN `overflow` | Removed the inert `overflow-auto` or gave it a flex-bounded height |
| Account for mobile browser toolbars in viewport height | MDN viewport units (`dvh`) | `h-screen` → `h-dvh` with fallback |
| Visible focus, hover and active feedback | WCAG 2.4.7 / 2.4.13; NNGroup signifiers | Added `focus-visible` ring, `hover:` and `active:` states |
| Target size | WCAG 2.5.8 (AA) / 2.5.5 (AAA) | Optional `min-h-11` for 44px |
| Scrollable regions are keyboard reachable | WCAG 2.1.1 | `tabIndex={0}` plus `aria-label` on the scroll region |

## Keyboard Navigation

**Focus order.** There is one focusable element, `<button>Save</button>` (`subject.tsx:26`). It's reachable by Tab, and it's last in both DOM and visual order. No `order`, `row-reverse` or absolute positioning changes the order, so WCAG 2.4.3 passes. If the list region gets `tabIndex={0}` (Finding 6), the order becomes list → Save, which matches top-to-bottom reading order.

**Escape-key behavior.** N/A because the diff has no modals or overlays.

**Skip-link presence.** No skip link exists. The page-level landmarks are new, but the `<header>` only holds an `<h1>` with no navigation or focusables. So Tab already lands on content and Save right away, and WCAG 2.4.1 is effectively met through the landmarks. If you later add `<nav>` links to the header, add a "Skip to main content" link as the first focusable element, shown on focus, pointing to an `id` on `<main>`.

**Focus-trap risks.** None found. There are no overlays, off-screen drawers or `aria-disabled` focusables.

## Viewport Verification Checklist

- [ ] 360px mobile: **fails today.** Long content pushes Save off-screen (F1, F2), and the toolbar can cover the footer (F3). Touch target is about 40px (passes AA).
- [ ] 1366×768 (common laptop): **fails with long content.** Save drops below the fold (F1).
- [ ] 1920×1080 (standard desktop): **partial.** With short content, the footer floats mid-screen instead of sitting at the bottom (F1).

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | `<main>` uses `shrink-0` instead of `flex-1 min-h-0`, so the footer/Save is pushed off-screen | Major | Sizing | `subject.tsx:17` | High |
| 2 | Inner `overflow-auto` has no height limit and never scrolls | Major | Overflow | `subject.tsx:18-22` | High |
| 3 | Button missing hover/active; focus only from browser default | Major | State coverage | `subject.tsx:26` | High |
| 4 | `h-screen` (100vh) footer hidden behind mobile toolbar | Major | Responsive | `subject.tsx:12` | Medium |
| 5 | `p-6` content padding larger than needed | Minor | Sizing | `subject.tsx:17` | Medium |
| 6 | Scroll region not keyboard-focusable in some browsers | Informational | Focus | `subject.tsx:20` | Medium |

## Overall Assessment

The overall structure is right: a full-height column with fixed header and footer and a content area in between. The bugs come from a few wrong class choices, and all of them can be fixed where they are. The most important fix is changing `<main>` from `shrink-0` to `flex-1 min-h-0 overflow-y-auto`. Right now, any long content pushes the Save button out of view at common laptop and phone sizes. That one change also fixes the inert inner scroll container (or makes it unnecessary). After that, switch `h-screen` to `h-dvh` so the footer isn't hidden by mobile toolbars, and give the Save button hover, active and explicit focus-visible states.
