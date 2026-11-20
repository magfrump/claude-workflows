# UI Visual Review: `subject.tsx` (`ItemList`)

**Scope:** `subject.tsx` (whole file, 31 lines)
**Date:** 2026-11-20
**Based on:** Code analysis only. No code-fact-check report was provided, and no project-local UI guidelines were found (no `docs/**/*.md`).

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** small mobile (320–480px), tablet/small laptop (768–1024px; 1366×768 checked), large desktop (1920px+)
- **Target browsers / platforms:** modern evergreen browsers + mobile Safari (default)
- **Review mode:** Full audit (items 1–8, plus item 10 because the file has a focusable element and list semantics; items 9 and 11 don't apply: no 3D or stacked/spatial layout)

## Findings

#### 1. The item list has no height limit, so a long list pushes the "Add Item" button below the fold

**Severity:** Major
**Location:** `subject.tsx:16-28`
**Issue type:** Overflow
**Viewport:** All. It shows up first on short screens: about 7 items at 360×640, about 9 items at 1366×768.
**Move:** Step 2 item 1 (unbounded content), together with item 5 (vertical spacing)
**Confidence:** High

The `flex flex-col gap-4` list (line 19) grows with `items.length` and has no `max-h-*` or `overflow-y-auto`. The primary action (line 26) comes after the list in normal flow, so every new item pushes it further down. Each row takes about 74px (16px + 24px line height + 16px padding, a 2px border, and a 16px gap). Adding the outer `p-6` and the heading, the button leaves a 768px-tall viewport after about 9 items. On a 640px phone it leaves after about 7. To add another item, the user has to scroll past the whole list. That gets worse as the list grows, and it's the action this component exists for.

**Severity note:** The file's own header comment says this should be **Critical**. I rated it **Major** based on the code. Nothing in this file clips content: there is no `overflow-hidden` and no fixed height. So unless a parent you haven't shown sets `overflow-hidden` or a fixed height, the page still scrolls and the button stays reachable, just hard to find. That fits "Major: accessible but hard to discover or use". If the parent *does* clip (for example an `h-screen overflow-hidden` app shell), the button becomes unreachable and this should be **Critical**.

**Recommendation:** Put the list in its own capped scroll region and keep the button outside it, pinned below. The button already sits outside the list, so item 2 (controls trapped inside scroll containers) is satisfied as long as the fix keeps it there. Also tighten the spacing (item 5).

```tsx
// BEFORE
<div className="flex flex-col p-6">
  <h2 className="text-lg font-bold shrink-0">Items</h2>
  <div className="flex flex-col gap-4">
    {items.map((item) => (
      <div key={item.id} className="border p-4 rounded">{item.name}</div>
    ))}
  </div>
  <button className="mt-4 py-2 px-4 bg-blue-500 text-white rounded">Add Item</button>
</div>

// AFTER
<section className="flex flex-col min-h-0 p-4" aria-labelledby="items-heading">
  <h2 id="items-heading" className="text-lg font-bold shrink-0">Items</h2>
  <ul
    className="flex flex-col gap-3 max-h-[60vh] min-h-0 overflow-y-auto [scrollbar-gutter:stable]
               focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
    tabIndex={0}
    aria-label="Items"
  >
    {items.map((item) => (
      <li key={item.id} className="border p-3 rounded break-words">{item.name}</li>
    ))}
  </ul>
  <button type="button" className="shrink-0 mt-3 ...">Add Item</button>
</section>
```

If a parent gives this component a fixed height (for example a sidebar panel), use `flex-1 min-h-0` on the `<ul>` instead of `max-h-[60vh]`.

**Tradeoffs:**
- An always-visible scrollbar gutter takes about 15px of width on desktop browsers. `scrollbar-gutter` is supported in Chrome/Edge 94+ and Firefox 97+, and in Safari only from 18.2. Older Safari ignores it, which is harmless.
- `tabIndex={0}` on the scroller adds one tab stop. Chrome 130+ and Firefox already make scrollable regions keyboard-focusable on their own. Safari does not, so the explicit `tabIndex` is needed there (WCAG 2.1.1).

#### 2. White text on `bg-blue-500` fails minimum text contrast

**Severity:** Major
**Location:** `subject.tsx:26`
**Issue type:** Affordance
**Viewport:** All
**Move:** Step 2 item 6 (visibility and affordance)
**Confidence:** High (the exact ratio depends on the Tailwind version)

The button label is normal weight, 16px, white on Tailwind `blue-500`. That's about 3.7:1 with v3's `#3b82f6`, and only slightly better with v4's oklch value. Both are below the **4.5:1** that WCAG 1.4.3 (Contrast, Minimum, AA) requires for normal-size text. This is the only action in the component, so low-vision users are most affected.

**Recommendation:**

```tsx
// BEFORE
className="mt-4 py-2 px-4 bg-blue-500 text-white rounded"
// AFTER
className="mt-4 py-2 px-4 bg-blue-600 text-white rounded"   // ~5.2:1 (v3 #2563eb)
```

#### 3. The "Add Item" button only styles its default state

**Severity:** Major
**Location:** `subject.tsx:26-28`
**Issue type:** State coverage
**Viewport:** All
**Move:** Step 2 item 8 (interactive element state matrix)
**Confidence:** High

Only the default appearance is defined. There's no hover feedback and no pressed feedback, so clicks feel "dead". There's no disabled style, which will matter if adding is ever blocked (for example while saving). Focus relies on the browser's default ring. Tailwind's preflight does *not* remove button outlines, so a ring does appear, but it isn't controlled, and Chrome's blue ring on a blue button has weak contrast.

- [ ] `<button>Add Item` (`subject.tsx:26`)
  - [x] default: `bg-blue-500 text-white rounded`. It's visually distinct from the bordered list rows (but see finding 2 for contrast).
  - [ ] hover: none
  - [~] focus: browser default only. There's no `focus-visible` ring, and the contrast against `blue-500` isn't guaranteed (WCAG 2.4.7 is met, 2.4.13 is not).
  - [ ] active: none
  - [ ] disabled: no `disabled:` styles
  - [N/A] error: a button is not a validatable control

**Recommendation:**

```tsx
<button
  type="button"
  className="shrink-0 mt-3 py-2 px-4 rounded bg-blue-600 text-white
             hover:bg-blue-700 active:bg-blue-800
             focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-800
             disabled:bg-gray-400 disabled:cursor-not-allowed"
>
  Add Item
</button>
```

#### 4. The "Add Item" button does nothing when clicked

**Severity:** Minor
**Location:** `subject.tsx:26`
**Issue type:** Other
**Viewport:** All
**Move:** Step 2 item 6 (affordance: a control that looks interactive but isn't)
**Confidence:** Medium (the handler may simply not be written yet in this fixture)

The button has no `onClick`, the component takes no `onAdd` prop, and the button isn't inside a `<form>`. It looks like a primary action, gets focus, and does nothing when pressed. Also, with no `type`, a button defaults to `type="submit"`, so if `ItemList` is ever placed inside a form it would submit that form by accident.

**Recommendation:** Add an `onAdd: () => void` prop, wire it to `onClick`, and set `type="button"`.

#### 5. Long item names without spaces overflow sideways on narrow screens

**Severity:** Minor
**Location:** `subject.tsx:21-23`
**Issue type:** Responsive
**Viewport:** 320–480px
**Move:** Step 2 item 7 (responsive and cross-browser concerns)
**Confidence:** Medium

`item.name` is rendered without `break-words` / `overflow-wrap`. A long name with no spaces (a URL, a filename, an ID) will push past the bordered card and cause horizontal page scroll at 320px. At that width only about 240px is left for text after the `p-6` + `p-4` padding. This fails WCAG 1.4.10 (Reflow).

**Recommendation:** Add `break-words` (and `min-w-0` if the row ever becomes a flex child) to the item element, as in the AFTER block in finding 1.

#### 6. The list is built from `<div>`s, so screen readers don't announce it as a list

**Severity:** Minor
**Location:** `subject.tsx:19-25`
**Issue type:** Accessibility serialization
**Viewport:** All
**Move:** Step 2 item 10 (accessibility serialization)
**Confidence:** High

Visually this is a list of items, but it's made of `<div>`s. Screen readers therefore don't announce "list, N items" and don't offer list navigation (WCAG 1.3.1 Info and Relationships). The heading is also not linked to its region.

**Recommendation:** Use `<ul>`/`<li>` and wrap the component in a `<section aria-labelledby>`, as in finding 1.

#### 7. An empty list shows nothing

**Severity:** Informational
**Location:** `subject.tsx:20`
**Issue type:** Affordance
**Viewport:** All
**Move:** Step 2 item 6
**Confidence:** Medium

When `items` is empty, the user sees the "Items" heading directly above the button with no explanation. A short message like "No items yet" tells users the list loaded correctly and is simply empty.

#### 8. The button is shorter than the AAA touch-target size

**Severity:** Informational
**Location:** `subject.tsx:26`
**Issue type:** Affordance
**Viewport:** 320–768px (touch)
**Move:** Step 2 item 6
**Confidence:** High

The button is about 40px tall: `py-2` plus a 24px line height. It also stretches to full width, because the flex column's default `align-items: stretch` widens it. That passes WCAG 2.5.8 (24×24, AA) but not 2.5.5 (44×44, AAA). If you want to meet AAA, use `py-2.5` or `min-h-11`.

## What Looks Good

- **The button is outside the list.** The primary action is a sibling of the list, not a child, so capping the list won't trap the button inside the scroll area. It's the correct base for the docked-footer pattern.
- **The heading uses `shrink-0`.** It does nothing today because nothing limits the height, but it's the correct size rule once the list becomes the flexible, scrolling part.
- **List rows have borders.** `border rounded` gives each row a clear edge, and they're easy to tell apart from the filled primary button.
- **Keys are stable.** `key={item.id}` rather than the index avoids rendering glitches when items are inserted.
- **The heading is a real `<h2>`.** Screen-reader users can navigate to it.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Visible, capped scroll regions for unbounded content | NNGroup (visible scroll affordances); WCAG 1.4.10 | `max-h-[60vh] overflow-y-auto` + `scrollbar-gutter: stable` on the list |
| Keep primary actions visible | Skill item 2 (docked footer); NNGroup | Button stays outside the scroll region with `shrink-0` |
| Scrollable regions must be keyboard-operable | WCAG 2.1.1 | `tabIndex={0}` + `aria-label` + focus ring on the scroller |
| Text contrast of at least 4.5:1 | WCAG 1.4.3 | `bg-blue-500` → `bg-blue-600` |
| Visible, controlled focus indicator | WCAG 2.4.7, 2.4.13 | `focus-visible:outline-2 outline-offset-2` |
| Full state coverage | Skill item 8 | Added hover / active / disabled |
| Content reflows at narrow widths | WCAG 1.4.10 | `break-words` on item rows |
| Semantic structure | WCAG 1.3.1 | `<ul>/<li>`, `<section aria-labelledby>` |

## Keyboard Navigation

**Focus order.**
1. `<button>Add Item` (`subject.tsx:26`): this is currently the only focusable element. It's reachable, but only after scrolling past the full list (finding 1).

After the recommended fix, the order becomes: list scroll region (`<ul tabIndex={0}>`) → "Add Item" button. That matches the top-to-bottom visual order. Nothing reorders things visually (`order`, `row-reverse`, absolute positioning), so there's no WCAG 2.4.3 mismatch.

**Escape-key behavior.** N/A: no modals or overlays in this diff.

**Skip-link presence.** N/A: the file doesn't change page-level structure. It's a component, not a page shell.

**Focus-trap risks.** No focus-trap risks identified. Two related notes:
- Today a keyboard user can always Tab to the button. The cost is the long scroll, not a trap.
- After the fix, the scroll region needs to be focusable so keyboard users can scroll it in Safari. The `tabIndex={0}` covers this.

## Viewport Verification Checklist

- [ ] **360px mobile:** fails today. The button leaves the screen after about 7 items, and long names can overflow sideways. Touch target height is 40px, which passes AA. Fixed by findings 1 and 5.
- [ ] **1366×768 (common laptop):** fails today. The button leaves the screen after about 9 items. Fixed by finding 1.
- [x] **1920×1080 (standard desktop):** acceptable for short lists. The full-width button may look stretched in a wide container, which is cosmetic.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | List has no height limit; pushes "Add Item" below the fold | Major (Critical if parent clips) | Overflow | `subject.tsx:16-28` | High |
| 2 | White on `blue-500` fails 4.5:1 contrast | Major | Affordance | `subject.tsx:26` | High |
| 3 | Button only styles its default state | Major | State coverage | `subject.tsx:26-28` | High |
| 4 | Button has no click handler and defaults to `type="submit"` | Minor | Other | `subject.tsx:26` | Medium |
| 5 | Long names without spaces overflow on narrow screens | Minor | Responsive | `subject.tsx:21-23` | Medium |
| 6 | `<div>`s instead of `<ul>/<li>` | Minor | Accessibility serialization | `subject.tsx:19-25` | High |
| 7 | No empty-list message | Informational | Affordance | `subject.tsx:20` | Medium |
| 8 | Button height 40px (below 44px AAA) | Informational | Affordance | `subject.tsx:26` | High |

## Overall Assessment

The problems are small and can be fixed in place; the overall structure is fine. The component already has the right shape: heading, list, and an action that sits outside the list. It's missing a height limit on the list and has only default styling on the button. The most important fix is finding 1. Give the list `max-h-*`/`flex-1 min-h-0` with `overflow-y-auto` and keep the button pinned below it, so "Add Item" stays visible however many items there are. I rated this Major rather than the Critical the fixture's comment expects, because nothing in this file clips content. Raise it to Critical if the parent layout sets `overflow-hidden` or a fixed height. After that, fix the button's contrast and add its hover, active and disabled styles in one change to `subject.tsx:26`.
