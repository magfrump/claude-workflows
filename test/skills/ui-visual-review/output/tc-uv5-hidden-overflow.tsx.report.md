# UI Visual Review: `subject.tsx` (`ErrorDisplay`)

**Scope:** `subject.tsx`, the whole file
**Date:** 2026-11-20
**Based on:** code analysis only (no code-fact-check report was provided)

## Environment

- **Files reviewed:** `subject.tsx`
- **Project-local guidelines:** none found (there are no `*.md` files in the repo), so the defaults in this skill apply
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet / small laptop), 1920px+ (desktop)
- **Target browsers / platforms:** current Chrome, Firefox and Edge, plus mobile Safari
- **Review mode:** Full audit

## Findings

#### 1. `overflow-hidden` hides every error past about the 5th line

**Severity:** Critical
**Location:** `subject.tsx:15`
**Issue type:** Overflow
**Viewport:** all, and worst at 320–480px
**Move:** Step 2 item 1: unbounded content without scroll caps
**Confidence:** High

The error list is set to a fixed `h-32` (128px). After the `p-2` padding, about 112px is left for text. `text-sm` lines are 20px tall, so about 5.6 lines fit. The 6th line is cut in half and everything after it can't be seen. No scrollbar appears and nothing tells the user that more errors exist. There is also no way to reach the hidden errors: you can't scroll, focus or expand the box.

On a 320px screen the text area is only about 270px wide, so each message wraps to two or three lines. At that width just two or three errors may be visible. The comment in the file expects **Major**, but the severity rubric says "content is inaccessible or invisible at common viewport sizes" is **Critical**, so this is rated Critical. Error messages are often what the user needs to fix their input, so hiding them can block the main task.

This also fails WCAG 1.4.10 Reflow, which says content must not be lost, and NNGroup's advice to show visible scroll affordances.

**Recommendation:** Swap the fixed height for a maximum height and let the box scroll. Make the box keyboard-focusable and give it a name, so keyboard users can scroll it too (see finding 2).

```tsx
// Before
<div className="h-32 overflow-hidden bg-red-50 border border-red-200 rounded p-2">

// After
<div
  role="region"
  aria-label={`Errors (${errors.length})`}
  tabIndex={0}
  className="max-h-32 overflow-y-auto [scrollbar-gutter:stable] bg-red-50 border border-red-200 rounded p-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-red-700"
>
```

**Tradeoff:** On platforms where scrollbars always show, the scrollbar and `scrollbar-gutter: stable` take up about 15px of width. `scrollbar-gutter` works in Chrome 94+, Firefox 97+ and Safari 18.2+. Older browsers ignore it, which does no harm.

#### 2. If the box becomes scrollable, keyboard users still need a way to scroll it

**Severity:** Major (this is a requirement for the fix in finding 1)
**Location:** `subject.tsx:15`
**Issue type:** Focus
**Viewport:** all
**Move:** Step 2 item 10: accessibility serialization / tab traversal
**Confidence:** Medium

Adding `overflow-y-auto` alone creates a scrolling area with nothing focusable inside it, because the list contains only `<p>` elements. Chrome 130+ makes scrolling areas focusable automatically. Safari, and older versions of Chrome and Firefox, do not. In those browsers keyboard users can't scroll the list (WCAG 2.1.1 Keyboard; axe rule `scrollable-region-focusable`).

**Recommendation:** Add `tabIndex={0}`, `role="region"` and an `aria-label`, as in the "After" code in finding 1. Also give the box a visible `focus-visible` outline (WCAG 2.4.7).

#### 3. Long error messages with no spaces overflow sideways and get cut off

**Severity:** Major
**Location:** `subject.tsx:17`
**Issue type:** Responsive
**Viewport:** 320–768px mainly, and any width if a message is long enough
**Move:** Step 2 item 7: text that doesn't reflow
**Confidence:** High

Error messages often contain long strings with no spaces, such as file paths, URLs, stack frames or IDs. The `<p>` elements have no `break-words` / `overflow-wrap`, so these strings run past the right edge of the box. Right now `overflow-hidden` cuts them off. Once the fix switches to `overflow-y-auto`, the browser will also turn horizontal overflow into scrolling (setting one axis to `auto` makes the other compute to `auto` too), so a sideways scrollbar appears instead.

**Recommendation:**
```tsx
// Before
<p key={i} className="text-red-700 text-sm">{err}</p>

// After
<p key={i} className="text-red-700 text-sm break-words">{err}</p>
```

#### 4. An empty red error box shows when there are no errors

**Severity:** Minor
**Location:** `subject.tsx:10-21`
**Issue type:** Affordance
**Viewport:** all
**Move:** Step 2 item 6: visibility and affordance
**Confidence:** Medium

When `errors` is empty, the component still shows the "Errors" heading and a 128px red box with nothing in it. That looks like a failure state and takes up vertical space that could hold other content (item 5).

**Recommendation:** If the parent doesn't already hide this component when there are no errors, add `if (errors.length === 0) return null;`. Switching to `max-h-32` (finding 1) also lets the box shrink to fit its content.

#### 5. New errors are not announced to screen readers

**Severity:** Minor
**Location:** `subject.tsx:15`
**Issue type:** Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 10
**Confidence:** Medium

Errors that appear after the user does something are status messages. They are not marked up as such (WCAG 4.1.3), so screen-reader users get no signal that anything happened. The red colour is backed by the "Errors" heading, so this does not fail WCAG 1.4.1. The live-region part is still missing.

**Recommendation:** Put a short live summary outside the scrolling area, so the screen reader doesn't read out the whole list on every change:
```tsx
<p className="sr-only" role="status">{errors.length} error{errors.length === 1 ? "" : "s"}</p>
```

#### 6. The `<h3>` heading level is fixed in the code

**Severity:** Informational
**Location:** `subject.tsx:13`
**Issue type:** Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 10
**Confidence:** Low

Wherever this component is used, it inserts an `<h3>`. That can skip heading levels on the page, for example going from `h1` straight to `h3` (WCAG 1.3.1 best practice). Think about letting the parent pass in the heading level, or point the region's `aria-labelledby` at the heading.

## What Looks Good

- The red background and the border make the error area clearly different from the content around it.
- There is a text heading ("Errors"), so the meaning doesn't rely on colour alone.
- The spacing is compact (`p-4`, `mb-2`, `p-2`), so it doesn't waste vertical space.

## Best Practices Applied

| Principle | Source | How Applied |
|---|---|---|
| Visible scroll affordances, no silent clipping | NNGroup; WCAG 1.4.10 | `overflow-hidden` → `overflow-y-auto` |
| Cap the height instead of fixing it | Skill item 1/5 | `h-32` → `max-h-32` |
| Scrolling areas must work with a keyboard | WCAG 2.1.1; axe `scrollable-region-focusable` | `tabIndex={0}`, `role="region"`, `aria-label` |
| Visible focus indicator | WCAG 2.4.7 | `focus-visible:outline-*` |
| Text reflows on narrow screens | WCAG 1.4.10; MDN `overflow-wrap` | `break-words` |
| Status messages are announced | WCAG 4.1.3 | `role="status"` summary |
| Stable layout when the scrollbar appears | MDN `scrollbar-gutter` | `[scrollbar-gutter:stable]` |

## Keyboard Navigation

The current code has no focusable elements. The recommended fix adds one: the scrolling region, which gets `tabIndex={0}`. The checks below apply to the code after that fix.

- **Focus order:** There is one focusable element, the error region (`subject.tsx:15`). It appears in normal DOM order after the heading, and there is no `order`, `row-reverse` or positioning that would change the visual order. No mismatch.
- **Escape-key behavior:** N/A. There are no modals or overlays in this file.
- **Skip-link presence:** N/A. The file doesn't change page-level structure.
- **Focus-trap risks:** No focus-trap risks found. The region is a normal tab stop that Tab moves past.

## Viewport Verification Checklist

- [ ] **360px mobile:** fails now. Only about 2–3 wrapped errors are visible and the rest are hidden. Long strings get cut off on the right. It passes after findings 1 and 3 are fixed.
- [ ] **1366x768:** fails now. Any error past about the 5th line is hidden. It passes after finding 1 is fixed.
- [x] **1920x1080:** the layout fills its container sensibly. The clipping from finding 1 still applies at this size.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---|---|---|---|---|
| 1 | `overflow-hidden` hides errors past about the 5th line | Critical | Overflow | `subject.tsx:15` | High |
| 2 | Scrolling region needs keyboard focus and a name | Major | Focus | `subject.tsx:15` | Medium |
| 3 | Long unbroken strings overflow sideways | Major | Responsive | `subject.tsx:17` | High |
| 4 | Empty error box shows when there are no errors | Minor | Affordance | `subject.tsx:10-21` | Medium |
| 5 | No live-region announcement | Minor | Accessibility serialization | `subject.tsx:15` | Medium |
| 6 | `<h3>` heading level fixed in code | Informational | Accessibility serialization | `subject.tsx:13` | Low |

## Overall Assessment

This is a small component with one serious defect. A fixed height combined with `overflow-hidden` silently hides error messages, and nothing tells the user that more exist. Every problem can be fixed in place; nothing here needs a redesign. The most important change is on line 15: replace `h-32 overflow-hidden` with `max-h-32 overflow-y-auto`. Make that change together with `tabIndex={0}` and an accessible name, so keyboard users can scroll the box, and add `break-words` to the messages so long strings wrap instead of overflowing sideways.
