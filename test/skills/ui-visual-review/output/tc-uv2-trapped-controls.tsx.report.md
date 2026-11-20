# UI Visual Review: `subject.tsx` (FormPanel)

**Scope:** `subject.tsx`
**Date:** 2026-11-20

## Environment

- **Files reviewed:** `subject.tsx`
- **Project guidelines:** None found (`docs/` has no UI layout guidelines), so the skill's defaults apply.
- **Target viewports:** Small mobile (320–480px), tablet/small laptop (768–1024px, plus 1366×768), large desktop (1920px+)
- **Target browsers / platforms:** Modern evergreen browsers and mobile Safari
- **Review mode:** Full audit
- **Note:** Tailwind version is not pinned in scope. Where it matters (default border color), the finding says which version it assumes.

## Findings

#### 1. Submit button is trapped inside the scroll container

**Severity:** Critical
**Location:** `subject.tsx:13-24`
**Issue type:** Overflow
**Viewport:** All. Worst at 320–1366px heights at or below 768px.
**Move:** Step 2 item 2: controls trapped inside scroll containers
**Confidence:** High

The only action button (`Submit`, line 21) sits inside `<div className="overflow-auto h-full p-6">` (line 13), after `{children}` and three textareas. When the content is taller than the panel, the button scrolls away with it. The user sees no primary action and has to guess that it's down there. This matches the skill's Critical rule: a primary action that growing content pushes out of view is Critical even if scrolling would reach it. It also goes against the NNGroup principle of putting controls in a consistent, predictable place.

**Recommendation:** Use the docked-footer pattern. Make the outer element a flex column, give the content area `flex-1 min-h-0 overflow-y-auto`, and pin the button in a `shrink-0` footer outside the scroll region.

```tsx
// BEFORE
<div className="h-full">
  <div className="overflow-auto h-full p-6">
    <h2 className="text-lg font-bold">Form</h2>
    {children}
    <div className="mt-8 space-y-4">{/* textareas */}</div>
    <button className="mt-4 py-3 px-6 ...">Submit</button>
  </div>
</div>

// AFTER
<div className="flex h-full min-h-0 flex-col overflow-hidden">
  <div className="shrink-0 border-b px-4 py-3">
    <h2 className="text-lg font-bold">Form</h2>
  </div>
  <div className="flex-1 min-h-0 overflow-y-auto p-4">
    {children}
    <div className="mt-4 space-y-3">{/* textareas */}</div>
  </div>
  <div className="shrink-0 border-t px-4 py-3">
    <button type="submit" className="...">Submit</button>
  </div>
</div>
```

**Tradeoff:** The footer takes about 60–70px of vertical space all the time. Pinning the heading is optional and costs about 50px more. If vertical space is very tight on mobile, keep the heading inside the scroll region.

---

#### 2. Textareas have no accessible name or visible label

**Severity:** Major
**Location:** `subject.tsx:17-19`
**Issue type:** Accessibility serialization
**Viewport:** All
**Move:** Step 2 item 10: accessibility serialization; item 6: affordance
**Confidence:** High

None of the three `<textarea>` elements has a `<label>`, `aria-label`, `aria-labelledby`, or even a `placeholder`. Screen readers announce each one as just "edit text", and sighted users can't tell what to type in which box. This fails WCAG 1.3.1 (Info and Relationships), 3.3.2 (Labels or Instructions) and 4.1.2 (Name, Role, Value).

**Recommendation:** Add a visible `<label>` linked by `htmlFor`/`id` to each field.

```tsx
// BEFORE
<textarea className="w-full border p-2" rows={8} />

// AFTER
<label htmlFor="field-a" className="block text-sm font-medium">Description</label>
<textarea id="field-a" className="mt-1 w-full border border-gray-400 p-2" rows={3} />
```

---

#### 3. Textarea borders may fail non-text contrast

**Severity:** Major
**Location:** `subject.tsx:17-19`
**Issue type:** Affordance
**Viewport:** All
**Move:** Step 2 item 6: form inputs without visible borders
**Confidence:** Medium (depends on the Tailwind version)

The textareas use a bare `border` with no color. In Tailwind v3, preflight sets the default border color to `gray-200` (`#e5e7eb`), which has about 1.2:1 contrast against white. WCAG 1.4.11 requires 3:1 for the edges of UI components. Combined with the missing labels, the fields are hard to tell apart from the background. In Tailwind v4 the default is `currentColor`, which would pass.

**Recommendation:** Set an explicit border color with at least 3:1 contrast, for example `border-gray-500` (`#6b7280`, about 4.8:1 on white).

---

#### 4. Submit button has no hover, active, disabled or focus styles

**Severity:** Major
**Location:** `subject.tsx:21-23`
**Issue type:** State coverage
**Viewport:** All
**Move:** Step 2 item 8: interactive element state matrix
**Confidence:** High

The button only has default styling. Hovering doesn't change it, clicking gives no visual feedback, and it has no disabled styling for when a submit is in progress or the form is invalid. Focus falls back to the browser's default outline. That's visible, but nothing guarantees it meets 2.4.13 (focus appearance) against the blue fill. The button also has no `type`, so its behavior depends on whether a `<form>` wraps it from outside. Inside one it submits by default; outside one it does nothing.

**Recommendation:**

```tsx
<button
  type="submit"
  className="py-3 px-6 bg-blue-600 text-white font-semibold rounded
             hover:bg-blue-700 active:bg-blue-800
             focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600
             disabled:bg-gray-400 disabled:cursor-not-allowed"
>
  Submit
</button>
```

---

#### 5. Textareas have no hover, focus or error states

**Severity:** Minor
**Location:** `subject.tsx:17-19`
**Issue type:** State coverage
**Viewport:** All
**Move:** Step 2 item 8: interactive element state matrix
**Confidence:** High

The textareas rely on the browser's default focus outline and have no error state at all: no `aria-invalid`, no linked message via `aria-describedby`, no icon or text. This doesn't break anything yet because no validation exists. But if validation is added later, it will probably end up as a red border alone, which fails WCAG 1.4.1 (use of color).

**Recommendation:** Add `focus-visible:ring-2 focus-visible:ring-blue-600`. When validation is added, set `aria-invalid` and point `aria-describedby` at a text error message.

---

#### 6. Scrolling depends on an ancestor having a fixed height

**Severity:** Minor
**Location:** `subject.tsx:11,13`
**Issue type:** Sizing
**Viewport:** All
**Move:** Step 2 item 3: `shrink-0` vs `flex-1 min-h-0`; item 1: unbounded content
**Confidence:** Medium

Both wrappers use `h-full`, which only works if some ancestor has a definite height. If FormPanel is placed in an auto-height parent, `h-full` collapses to `auto` and `overflow-auto` never kicks in. The panel then grows to fit its content, the whole page scrolls instead, and `children` has no upper limit. If the parent is a flex child, `h-full` can also overflow it unless that parent has `min-h-0`.

**Recommendation:** Write down that FormPanel needs a bounded parent, or add a fallback cap such as `max-h-[85vh]` on the outer container. The fix for finding 1 (`flex h-full min-h-0 flex-col`) behaves correctly inside a flex parent.

---

#### 7. Too much vertical spacing pushes the action below the fold

**Severity:** Minor
**Location:** `subject.tsx:13,16-21`
**Issue type:** Sizing
**Viewport:** Heights at or below 900px. Clearly fails at 1366×768 and on all mobile screens.
**Move:** Step 2 item 5: excessive vertical spacing
**Confidence:** High

Adding up the spacing:

- **Padding and margins:** `p-6` (48px vertically), `mt-8` (32px), `space-y-4` (32px) and `mt-4` (16px).
- **Textareas:** three at `rows={8}`, roughly 210px each.

That comes to about 750px of fixed layout before `children` adds anything. At 1366×768, after browser chrome, the Submit button is below the fold even with empty `children`.

**Recommendation:** Use `p-4`, `mt-4`, `space-y-3` and `rows={3}`, and let users resize the textareas with `resize-y`. Finding 1's fix keeps the action visible either way. This change cuts down how much scrolling is needed.

---

#### 8. The section heading isn't tied to a landmark

**Severity:** Informational
**Location:** `subject.tsx:11,14`
**Issue type:** Accessibility serialization
**Viewport:** All
**Move:** Step 2 item 10
**Confidence:** Medium

The generic "Form" heading sits in a plain `<div>`. Using a `<form>` or `<section aria-labelledby>` would let screen-reader users jump straight to the region and give the Submit button a real form to submit.

**Recommendation:** Wrap the content in `<form aria-labelledby="formpanel-title" onSubmit={...}>` and give the `h2` `id="formpanel-title"`.

## What Looks Good

- The `w-full` textareas reflow cleanly at 320px. With `p-6` they still get about 272px of width, and nothing overflows horizontally.
- The button (`py-3`, about 48px tall) is well above the 24×24px minimum in WCAG 2.5.8 and meets the 44px AAA target in 2.5.5.
- White text on `bg-blue-600` has about 5.2:1 contrast, which passes WCAG 1.4.3 AA.
- It uses a real `<button>` and native `<textarea>`s rather than `div`s with click handlers, so keyboard support and roles come for free.
- `overflow-auto` was used rather than `overflow-hidden`, so content scrolls instead of being cut off silently.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Primary actions stay reachable | NNGroup (consistent placement); skill's docked-footer pattern | Moved Submit into a `shrink-0` footer outside the scroll region |
| Inputs need programmatic labels | WCAG 1.3.1, 3.3.2, 4.1.2 | Added `<label htmlFor>` for each textarea |
| Component edges need 3:1 contrast | WCAG 1.4.11 | Explicit `border-gray-500` on textareas |
| Visible focus indicator | WCAG 2.4.7, 2.4.13 | `focus-visible` outline or ring on the button and textareas |
| Errors not conveyed by color alone | WCAG 1.4.1 | `aria-invalid` + `aria-describedby` text error once validation exists |
| Compact vertical rhythm | Skill item 5 | `p-4`, `space-y-3`, `rows={3}` |

## Keyboard Navigation

**Focus order.** Tab order, which matches visual order:
1. Any focusable elements inside `{children}` (line 15). These are unknown and outside this file.
2. `<textarea>` at `subject.tsx:17`
3. `<textarea>` at `subject.tsx:18`
4. `<textarea>` at `subject.tsx:19`
5. `<button>` Submit at `subject.tsx:21`

DOM order matches visual order, with no `order`, `row-reverse` or absolute positioning, so WCAG 2.4.3 is met. Focusing the button scrolls the container to show it, so keyboard users can reach it. Mouse and touch users get no such hint (finding 1). After the docked-footer fix the order stays the same.

**Escape-key behavior.** N/A: this diff has no modals or overlays.

**Skip-link presence.** N/A: the diff doesn't change page-level structure.

**Focus-trap risks.** None found. Every element is native and focusable, and Tab exits the panel normally.

## Viewport Verification Checklist

- [ ] **360px mobile:** No horizontal overflow and touch targets are fine, but Submit sits about 750px or more down inside the scroller (findings 1 and 7).
- [ ] **1366×768 (common laptop):** Submit is not visible without scrolling (findings 1 and 7).
- [x] **1920×1080 (standard desktop):** Submit is visible when `children` is short, but still scrolls away once `children` grows (finding 1).

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Submit button trapped inside the scroll container | Critical | Overflow | `subject.tsx:13-24` | High |
| 2 | Textareas have no accessible name or visible label | Major | Accessibility serialization | `subject.tsx:17-19` | High |
| 4 | Button has no hover, active, disabled or focus styles | Major | State coverage | `subject.tsx:21-23` | High |
| 3 | Textarea borders may fail 3:1 contrast | Major | Affordance | `subject.tsx:17-19` | Medium |
| 7 | Too much vertical spacing pushes Submit below the fold | Minor | Sizing | `subject.tsx:13,16-21` | High |
| 5 | Textareas have no focus or error states | Minor | State coverage | `subject.tsx:17-19` | High |
| 6 | Scrolling depends on a fixed-height ancestor | Minor | Sizing | `subject.tsx:11,13` | Medium |
| 8 | Heading isn't tied to a landmark | Informational | Accessibility serialization | `subject.tsx:11,14` | Medium |

## Overall Assessment

The layout problem is structural but small: the primary action shares a scroll region with content that can grow without limit. On any laptop-sized or smaller screen, Submit starts out below the fold, and it scrolls further away as `children` grows. The fix is the docked-footer pattern, which fits in the same component. The other issues are local edits: the textareas need labels and stronger borders, the button needs all its interaction states, and the spacing should be tighter. The most important single change is moving Submit into a `shrink-0` footer outside the `overflow-auto` region (finding 1).
