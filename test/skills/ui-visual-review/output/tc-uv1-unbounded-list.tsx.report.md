# UI Visual Review: `subject.tsx` (ItemList)

**Scope:** `subject.tsx` (whole file, 31 lines)
**Date:** 2026-11-20
**Based on:** Code analysis only. No code-fact-check report was provided, and no project UI guidelines exist (`docs/` has no `.md` files).

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet/laptop), 1366×768, 1920px+
- **Target browsers / platforms:** Modern evergreen browsers and mobile Safari (default)
- **Review mode:** Full audit (items 1–8 and 10; items 9 and 11 don't apply because there is no 3D or spatial layering content)

> Note: The file's header comment (lines 1–5) says what the expected finding is. I treated it as an unverified claim and checked the code myself. It turns out to be accurate.

## Findings

#### 1. List grows without limit and pushes the "Add Item" button off-screen

**Severity:** Critical
**Location:** `subject.tsx:16-28`
**Issue type:** Overflow
**Viewport:** All. It shows up soonest at 320–768px and at 1366×768.
**Move:** Step 2 item 1 (unbounded content) and item 2 (primary control placed after growing content)
**Confidence:** High

The list container on line 19 (`flex flex-col gap-4`) has no `max-h-*` and no `overflow-*`. The root on line 16 has no height limit either. Each item is about 58px tall (`p-4` plus a 24px line) with a 16px gap, so it costs about 74px. On a 768px-tall laptop, about 8 items push "Add Item" below the fold. On a 568px phone, about 5 items do. The page can still scroll, but the primary action disappears as the list grows, so users can't see how to add an item. The skill rates this Critical even though scrolling would reach it. Under the docked-footer pattern, the content area should scroll while the controls stay pinned.

**Recommendation:** Give the component a height limit, make the list the only scrolling region, and pin the header and button with `shrink-0`.

```tsx
// Before
<div className="flex flex-col p-6">
  <h2 className="text-lg font-bold shrink-0">Items</h2>
  <div className="flex flex-col gap-4">
    {items.map(...)}
  </div>
  <button className="mt-4 py-2 px-4 ...">Add Item</button>
</div>

// After
<div className="flex max-h-[85vh] min-h-0 flex-col p-4">
  <h2 className="shrink-0 text-lg font-bold">Items</h2>
  <ul className="flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto [scrollbar-gutter:stable]">
    {items.map((item) => (
      <li key={item.id} className="rounded border p-3 break-words">{item.name}</li>
    ))}
  </ul>
  <div className="shrink-0 border-t pt-3 mt-3">
    <button type="button" className="...">Add Item</button>
  </div>
</div>
```

If the parent already gives this component a fixed height (for example a full-height panel), use `h-full` instead of `max-h-[85vh]`.

**Tradeoff:** A visible scrollbar takes about 15px of width on desktop. `scrollbar-gutter: stable` reserves that space so the layout doesn't jump when the scrollbar appears. It works in Chromium and Firefox, and in Safari 17+ (older Safari ignores it harmlessly).

#### 2. Button text contrast fails WCAG AA (white on `bg-blue-500`)

**Severity:** Major
**Location:** `subject.tsx:26`
**Issue type:** Affordance
**Viewport:** All
**Move:** Step 2 item 6 (visibility and affordance) and item 8 (default state)
**Confidence:** High

White text on Tailwind `blue-500` has a contrast ratio of about 3.7:1 (v3 `#3b82f6`). The v4 oklch value is about 3.9:1. The button label is normal-weight body text, which needs 4.5:1 under WCAG 1.4.3 (Contrast, Minimum).

**Recommendation:** Use `bg-blue-600` (about 5.2:1) or `bg-blue-700`.

```tsx
// Before
className="mt-4 py-2 px-4 bg-blue-500 text-white rounded"
// After
className="py-2 px-4 bg-blue-600 text-white rounded"
```

#### 3. "Add Item" button styles only the default state

**Severity:** Major
**Location:** `subject.tsx:26-28`
**Issue type:** State coverage
**Viewport:** All
**Move:** Step 2 item 8 (interactive element state matrix)
**Confidence:** High

Only the default state has styling. There's no hover or active feedback, so clicks feel "dead." There's no explicit focus indicator, so the button relies on the browser's default outline. That outline may not reach 3:1 against the blue (WCAG 2.4.7 and 2.4.13), and any CSS reset that strips it would leave no focus indicator at all. There's also no disabled styling, which matters if adding is ever blocked (for example, while a save is in progress).

**Recommendation:**

```tsx
<button
  type="button"
  className="py-2 px-4 rounded bg-blue-600 text-white
             hover:bg-blue-700 active:bg-blue-800
             focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-600 focus-visible:ring-offset-2
             disabled:opacity-50 disabled:cursor-not-allowed"
>
  Add Item
</button>
```

#### 4. Long item names can overflow sideways on narrow screens

**Severity:** Minor
**Location:** `subject.tsx:21-23`
**Issue type:** Responsive
**Viewport:** 320–480px
**Move:** Step 2 item 7 (text reflow)
**Confidence:** Medium

`item.name` comes from data. A long unbroken string (URL, file name, ID) won't wrap. It will spill out of the bordered card and cause horizontal scrolling, which breaks WCAG 1.4.10 (Reflow) at 320px.

**Recommendation:** Add `break-words` (`overflow-wrap: break-word`) to the item element, as in the fix for Finding 1. If one line per item is preferred, use `min-w-0 truncate` together with a `title={item.name}`.

#### 5. Too much vertical spacing

**Severity:** Minor
**Location:** `subject.tsx:16, 19, 21, 26`
**Issue type:** Sizing
**Viewport:** 320–768px tall, 1366×768
**Move:** Step 2 item 5 (excessive vertical spacing)
**Confidence:** High

`p-6` on the root, `gap-4` between items and `p-4` inside each item add up to about 74px per row. That shrinks how many items fit before the fold and makes Finding 1 show up sooner.

**Recommendation:** Use `p-4` on the root, `gap-3` on the list and `p-3` on items. That brings rows to about 60px (shown in the fix for Finding 1).

#### 6. The list isn't marked up as a list

**Severity:** Minor
**Location:** `subject.tsx:19-25`
**Issue type:** Accessibility serialization
**Viewport:** All
**Move:** Step 2 item 10 (accessibility serialization)
**Confidence:** High

The items are plain nested `<div>`s. Screen readers won't announce "list, N items," and users can't jump between items with list navigation. The visual structure (a list of cards) doesn't match what assistive technology is told.

**Recommendation:** Use `<ul>` and `<li>`, as in the fix for Finding 1. Tailwind's base styles already remove the bullets.

#### 7. Button has no `onClick` and no `type`; empty list shows nothing

**Severity:** Informational
**Location:** `subject.tsx:26`, `subject.tsx:20`
**Issue type:** Other
**Viewport:** All
**Move:** Step 2 items 6 and 8
**Confidence:** High

- The button has no click handler, so it does nothing. That may be intentional because this is a fixture.
- It has no `type="button"`. If it's ever placed inside a `<form>`, it will submit the form.
- When `items` is empty, the list area renders nothing. Users get no "No items yet" message to explain the blank space.

**Recommendation:** Add an `onAdd` prop wired to `onClick`, add `type="button"`, and render an empty-state message when `items.length === 0`.

#### 8. Touch target meets AA but not AAA

**Severity:** Informational
**Location:** `subject.tsx:26`
**Issue type:** Affordance
**Viewport:** 320–768px (touch)
**Move:** Step 2 item 6 (touch targets)
**Confidence:** Medium

`py-2` plus a 24px line height makes the button about 40px tall. That passes WCAG 2.5.8 (24×24px) but falls short of 2.5.5's 44px.

**Recommendation:** Use `py-2.5` or `min-h-11` if AAA or Apple's 44pt guidance is a goal.

## What Looks Good

- The heading correctly uses `shrink-0`, so it sizes to its content. It just needs to work together with a `flex-1 min-h-0` scroll region.
- Each item uses `item.id` as its key, which is stable, not the array index.
- Items have visible borders and rounded corners, so the cards are clearly separate.
- The button has a solid background, so it's clearly a button and not plain text.
- The button is always shown and doesn't disappear based on state.

## Best Practices Applied

| Principle | Source | How Applied |
|---|---|---|
| Keep primary actions visible; only the content scrolls | Skill item 2; NNGroup (visible scroll affordances) | Button moved to a `shrink-0` footer; list gets `flex-1 min-h-0 overflow-y-auto` |
| Stable scrollbar space | MDN `scrollbar-gutter` | `[scrollbar-gutter:stable]` on the list |
| Text contrast of 4.5:1 | WCAG 1.4.3 | `bg-blue-500` → `bg-blue-600` |
| Visible focus indicator | WCAG 2.4.7 / 2.4.13 | `focus-visible:ring-2 ring-offset-2` |
| Content reflows at 320px | WCAG 1.4.10 | `break-words` on items |
| Structure exposed to screen readers | WCAG 1.3.1 | `<ul>` / `<li>` |
| Target size | WCAG 2.5.8 / 2.5.5 | Checked against AA; noted AAA option |

## Keyboard Navigation

**Focus order.** There is one focusable element: `<button>` at `subject.tsx:26`. The heading and items aren't focusable. Tab order follows the DOM, which matches the visual order, and there's no `order`, `row-reverse` or absolute positioning. One caveat: until Finding 1 is fixed, the button can scroll out of view. Tabbing will scroll it back into view, so WCAG 2.4.11 isn't violated, but mouse and touch users lose sight of it. After the fix, the scrollable `<ul>` may need `tabIndex={0}` so keyboard users can scroll it. Chromium 130+ makes scroll containers focusable on its own, but Safari doesn't.

**Escape-key behavior.** N/A. There are no modals or overlays in this diff.

**Skip-link presence.** N/A. The diff doesn't change page-level structure.

**Focus-trap risks.** None identified.

## Viewport Verification Checklist

- [ ] 360px mobile: **Fails** with about 5+ items (button pushed off-screen, Finding 1), and long names overflow sideways (Finding 4). Touch target is AA-adequate.
- [ ] 1366×768 (common laptop): **Fails** with about 8+ items (Finding 1).
- [x] 1920×1080 (standard desktop): Works for short lists, but has the same unbounded-growth problem at about 12+ items.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---|---|---|---|---|
| 1 | List grows without limit and pushes "Add Item" off-screen | Critical | Overflow | `subject.tsx:16-28` | High |
| 2 | White on `blue-500` fails 4.5:1 contrast | Major | Affordance | `subject.tsx:26` | High |
| 3 | Button has no hover, active, focus or disabled styles | Major | State coverage | `subject.tsx:26-28` | High |
| 4 | Long names overflow sideways at 320px | Minor | Responsive | `subject.tsx:21-23` | Medium |
| 5 | Too much vertical spacing | Minor | Sizing | `subject.tsx:16,19,21,26` | High |
| 6 | List built from `<div>`s instead of `<ul>`/`<li>` | Minor | Accessibility serialization | `subject.tsx:19-25` | High |
| 7 | No `onClick`, no `type="button"`, no empty state | Informational | Other | `subject.tsx:20,26` | High |
| 8 | Touch target about 40px (AA pass, AAA miss) | Informational | Affordance | `subject.tsx:26` | Medium |

## Overall Assessment

The component is small and its problems can be fixed in place. Nothing here needs a redesign. The main defect is structural but simple: the list grows without limit and sits in the same flow as the only action, so the more items users add, the harder it gets to find "Add Item." The most important fix is the docked-footer layout from Finding 1:
- a height-limited root,
- a `flex-1 min-h-0 overflow-y-auto` list,
- a `shrink-0` footer holding the button.

That fix also resolves Findings 5 and 6. The contrast and state-coverage fixes (Findings 2 and 3) are a one-line class change on the button.
