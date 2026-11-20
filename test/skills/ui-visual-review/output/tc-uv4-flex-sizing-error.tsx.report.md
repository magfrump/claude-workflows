# UI Visual Review: subject.tsx (`AppLayout`)

**Scope:** `subject.tsx` (single file, whole-file review)
**Date:** 2026-11-20
**Based on:** Code analysis only. There was no code-fact-check report, so I checked the file's comments against the code myself (see Finding 1).

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** Small mobile (320–480px), tablet/small laptop (768–1366px), large desktop (1920px+)
- **Target browsers / platforms:** Modern evergreen browsers plus mobile Safari (the default; no project target was stated)
- **Review mode:** Full audit
- **Project guidelines:** None found. There is no `docs/` directory and no `UI_LAYOUT_GUIDELINES.md`, so the skill's default rules apply.

## Findings

#### 1. Content area uses `shrink-0` instead of `flex-1 min-h-0`, so growing content pushes the Save footer off-screen

**Severity:** Critical
**Location:** `subject.tsx:17`
**Issue type:** Sizing
**Viewport:** All. It shows up sooner on short viewports (1366×768 and below, and every mobile size).
**Move:** Step 2 item 3 (wrong `shrink-0` vs `flex-1 min-h-0`), with the same effect as items 1–2 (primary action pushed out of view)
**Confidence:** High

The root is a fixed-height column (`flex flex-col h-screen`). `<main>` has `shrink-0`, so it sizes to its content and never shrinks. Nothing gives it the leftover space, and nothing caps it. Once the content is taller than `100vh` minus the header and footer, the flex children spill past the root. The root has no `overflow` set, so the spill is visible and the page body starts scrolling. The `<footer>` with the **Save** button, the only action on the screen, ends up below the fold. The user can reach it by scrolling, but nothing tells them it's there. The skill rates this Critical: "a primary action that growing content pushes out of view is Critical even when scrolling would reach it."

*Fact-check note:* The comment on lines 1–4 and 16 describes the behaviour correctly. Line 6 says "Expected finding: Major". I rated it Critical because the skill's severity rules say a primary action pushed out of view by growing content is Critical.

**Recommendation:** Make `<main>` fill the remaining space and let it shrink below its content height (`min-h-0`). Then put the scrolling inside it, so the header and footer stay pinned (the docked-footer pattern).

```tsx
// Before
<main className="shrink-0 p-6">
  <div className="space-y-4">
    <p>…</p>
    <div className="overflow-auto">{/* long list */}</div>
  </div>
</main>

// After
<main className="flex flex-1 min-h-0 flex-col p-4">
  <div className="flex flex-1 min-h-0 flex-col gap-4">
    <p className="shrink-0">…</p>
    <div className="flex-1 min-h-0 overflow-y-auto">{/* long list */}</div>
  </div>
</main>
```

*Tradeoff:* None worth noting. If the intro text should scroll along with the list, use `<main className="flex-1 min-h-0 overflow-y-auto p-4">` and drop the inner scroll container. That's simpler, but the `<p>` scrolls away.

---

#### 2. The inner `overflow-auto` list container can never scroll (unbounded content)

**Severity:** Major
**Location:** `subject.tsx:20-22`
**Issue type:** Overflow
**Viewport:** All
**Move:** Step 2 item 1 (unbounded content without scroll caps)
**Confidence:** High

`overflow-auto` only works when the element has a bounded height. This `<div>` has no `max-h-*`, no `h-*`, and no flex sizing. Its parent `space-y-4` block sits inside an unbounded `shrink-0` `<main>`, so the div just grows with its children. The scroll container looks like it's there but does nothing, and the growth feeds Finding 1. Fixing Finding 1 alone doesn't fix this one: the `space-y-4` wrapper is a block, not a flex column, so the list still has no bound.

**Recommendation:** Give the list a bounded flex slot (`flex-1 min-h-0`) inside a flex-column parent, as in the "After" block of Finding 1. If the list should stay compact, use a viewport cap such as `max-h-[60vh] overflow-y-auto` instead.

---

#### 3. `h-screen` (`100vh`) can hide the footer behind mobile Safari's toolbar

**Severity:** Major
**Location:** `subject.tsx:12`
**Issue type:** Responsive
**Viewport:** 320–480px on iOS Safari, and other mobile browsers with toolbars that collapse
**Move:** Step 2 item 7 (responsive / cross-browser)
**Confidence:** Medium

`100vh` on mobile Safari equals the *largest* viewport, measured with the toolbars collapsed. While the bottom toolbar is showing, the bottom ~50–80px of an `h-screen` layout sits under the browser UI. Even after Finding 1 is fixed, the pinned Save footer would be partly or fully hidden on first load. This works against WCAG 2.4.11 (Focus Not Obscured), and the main action becomes hard to find (MDN: `dvh` / dynamic viewport units).

**Recommendation:** Use dynamic viewport height, with a fallback for older browsers.

```tsx
// Before
<div className="flex flex-col h-screen">
// After (Tailwind ≥ 3.4)
<div className="flex flex-col h-screen h-dvh">
```

Tailwind sorts utilities by its own order, not by class order. If both classes end up on the same property, put the fallback in CSS instead: `height: 100vh; height: 100dvh;`. No vendor prefix is needed; `dvh` works in Safari 15.4+, Chrome 108+ and Firefox 101+.
*Tradeoff:* With `dvh`, the layout resizes as the toolbar shows and hides, which can cause a small reflow while scrolling. That doesn't matter much here, because the page itself no longer scrolls once Finding 1 is fixed.

---

#### 4. Save button has no hover, active or custom focus styling

**Severity:** Minor
**Location:** `subject.tsx:26`
**Issue type:** State coverage
**Viewport:** All
**Move:** Step 2 item 8 (interactive element state matrix) and item 6 (affordance)
**Confidence:** High

The button only defines its default state. Hovering and pressing give no visual feedback, so clicks feel "dead". Keyboard focus falls back to the browser's default ring. That passes WCAG 2.4.7, but its look varies by browser and isn't tuned to this button. The touch target is about 40px tall (`py-2` plus a 24px line height). That meets WCAG 2.5.8 AA (24×24) but not 2.5.5 AAA (44×44). Contrast is fine: white on `gray-800` is about 14.7:1.

**Recommendation:**

```tsx
// Before
<button className="py-2 px-4 bg-gray-800 text-white rounded">Save</button>
// After
<button
  type="button"
  className="min-h-11 py-2 px-4 bg-gray-800 text-white rounded
             hover:bg-gray-700 active:bg-gray-900
             focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-gray-800
             disabled:opacity-50 disabled:cursor-not-allowed"
>
  Save
</button>
```

`type="button"` stops the button from submitting a form by accident if this layout is ever wrapped in a `<form>`. Leave it out if a submit is what you want.

---

#### 5. `p-6` on the content area uses up space on small viewports

**Severity:** Minor
**Location:** `subject.tsx:17`
**Issue type:** Sizing
**Viewport:** 320–480px, 1366×768
**Move:** Step 2 item 5 (excessive vertical spacing)
**Confidence:** Medium

`p-6` adds 48px of vertical and 48px of horizontal padding. On a 320px screen that's 15% of the width, and it makes the content area shorter on short laptop screens. The header and footer already use `p-4`.

**Recommendation:** Use `p-4`, or make it responsive with `p-4 md:p-6`. This is already in Finding 1's "After" block.

---

#### 6. The scroll region should be reachable by keyboard and named for screen readers

**Severity:** Informational
**Location:** `subject.tsx:20`
**Issue type:** Accessibility serialization
**Viewport:** All
**Move:** Step 2 item 10 (accessibility serialization / tab traversal)
**Confidence:** Medium

Once the list actually scrolls (after Findings 1–2 are fixed), keyboard users need to be able to focus it if it has no focusable children. Chrome 130+ and Firefox do this automatically; Safari doesn't.

**Recommendation:** `<div role="region" aria-label="Items" tabIndex={0} className="flex-1 min-h-0 overflow-y-auto focus-visible:ring-2">`. Skip this if the list items will be focusable themselves.

## What Looks Good

- The header and footer correctly use `shrink-0`. They size to their content and won't collapse, so only `<main>` is wrong.
- The page uses proper landmarks (`<header>`, `<main>`, `<footer>`) and one `<h1>`, so screen-reader users can jump between regions.
- The Save button is a real `<button>`, not a `div` with a click handler, so it gets keyboard activation and its role for free.
- The button has strong contrast (about 14.7:1) and a clear filled-button look.
- The borders between header, content and footer (`border-b` / `border-t`) separate the regions clearly.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Fill-space regions use `flex-1 min-h-0` | Skill item 3 / MDN flexbox `min-height: auto` | `<main>` changed from `shrink-0` to `flex-1 min-h-0` |
| Controls stay outside the scroll region (docked footer) | Skill item 2 / NNGroup visibility of system status | Footer stays pinned and only the list scrolls |
| Scroll containers need a bounded height | MDN `overflow` | Gave the `overflow-auto` list a bounded flex slot |
| Dynamic viewport units on mobile | MDN viewport units, WCAG 2.4.11 | `h-screen` → `h-dvh` with a fallback |
| Visible interaction states | WCAG 2.4.7, NNGroup signifiers | Added hover, active and focus-visible styles |
| Target size | WCAG 2.5.8 (AA) / 2.5.5 (AAA) | Optional `min-h-11` brings the button to 44px |

## Keyboard Navigation

**Focus order.** There is one focusable element, in this tab order:
1. `<button>Save</button>` (`subject.tsx:26`). It can be reached with Tab. With the current bug, it can sit below the fold, and browsers scroll it into view when it gets focus. DOM order matches visual order, and nothing uses `order`, `row-reverse` or absolute positioning.
After the fix, the scroll region (Finding 6) may come before the button in tab order, which matches visual order.

**Escape-key behavior.** N/A: there are no modals or overlays in this file.

**Skip-link presence.** This file introduces page-level landmarks. There is no skip link, but the header currently has no focusable elements, so there's nothing to skip. Landmarks also satisfy WCAG 2.4.1 (ARIA11). If navigation is added to `<header>`, add a skip link to `<main id="main">` as the first focusable element, visible on focus.

**Focus-trap risks.** No focus-trap risks identified.

## Viewport Verification Checklist

- [ ] **360px mobile.** Currently fails: long content pushes Save off-screen, and on iOS Safari `100vh` puts the footer under the toolbar. `p-6` is tight. Passes after Findings 1–3 and 5.
- [ ] **1366×768 laptop.** Currently fails once the content is taller than about 640px: Save is below the fold. Passes after Finding 1.
- [ ] **1920×1080 desktop.** Same failure with tall content. With little content it looks fine, and after the fix the empty space sits in `<main>`, which is the right place.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | `shrink-0` on `<main>` pushes the Save footer off-screen | Critical | Sizing | `subject.tsx:17` | High |
| 2 | Inner `overflow-auto` has no height bound and never scrolls | Major | Overflow | `subject.tsx:20-22` | High |
| 3 | `h-screen` hides the footer under the mobile Safari toolbar | Major | Responsive | `subject.tsx:12` | Medium |
| 4 | Save button lacks hover, active and custom focus states | Minor | State coverage | `subject.tsx:26` | High |
| 5 | `p-6` wastes space on small viewports | Minor | Sizing | `subject.tsx:17` | Medium |
| 6 | Scroll region not keyboard-focusable or named | Informational | Accessibility serialization | `subject.tsx:20` | Medium |

## Overall Assessment

The layout's structure is sound: a full-height column with a fixed header, a content area and a docked footer. It breaks because of one wrong class. `<main>` is `shrink-0` when it should be `flex-1 min-h-0`. That one class causes the main problem, which is the Save button being pushed out of view whenever the content grows. It also leaves the inner `overflow-auto` with nothing to scroll against. Everything can be fixed in place without restructuring. **The most important fix is changing `<main>` to `flex flex-1 min-h-0 flex-col` and giving the list `flex-1 min-h-0 overflow-y-auto`.** After that, switch `h-screen` to `h-dvh` so the pinned footer isn't hidden on mobile Safari. The button-state and padding fixes are small polish.
