# UI Visual Review: subject.tsx (`ErrorDisplay`)

**Scope:** `subject.tsx` (whole file, 22 lines)
**Date:** 2026-11-20
**Based on:** No fact-check report was provided, so this review is based on reading the code only.

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** Small mobile (320–480px), tablet/small laptop (768–1024px), large desktop (1920px+)
- **Target browsers / platforms:** Modern evergreen browsers + mobile Safari (default)
- **Review mode:** Full audit
- **Project guidelines:** None found (no `docs/**/*.md`, no `UI_LAYOUT_GUIDELINES.md`). No suppression comments and no earlier reviews to skip.

Note: the file's header comments call it a test case and name an expected finding. I treated those comments as claims to check, not as conclusions. The analysis below comes from the code itself.

## Findings

#### 1. `overflow-hidden` on a fixed-height box silently hides errors

**Severity:** Major
**Location:** `subject.tsx:15`
**Issue type:** Overflow
**Viewport:** All
**Move:** Step 2 item 1: unbounded content without scroll caps
**Confidence:** High

The error list comes from `errors: string[]` and has no length limit. The box is fixed at `h-32` (128px) and set to `overflow-hidden`. After the `p-2` padding, there are about 112px for content. At `text-sm` (20px line height), that fits roughly 5 single-line errors. Anything after that is cut off, with no scrollbar, no fade and no "+N more" count, so users can't tell errors are missing. On narrow screens long messages wrap onto more lines, so the limit drops to 2–3 errors at 320px. This breaks the rule that overflow should be visible and scrollable, never clipped. For an error panel it's especially bad: a user can fix every error they can see and still fail to submit. If this panel blocks a key task like submitting a form, treat it as Critical.

**Recommendation:** Let the box shrink to fit its content up to a cap (`max-h-32`, not `h-32`) and scroll past that. Make the scroll area keyboard-reachable (see Finding 3).

```tsx
// Before
<div className="h-32 overflow-hidden bg-red-50 border border-red-200 rounded p-2">

// After
<div
  className="max-h-32 overflow-y-auto bg-red-50 border border-red-200 rounded p-2"
  tabIndex={0}
  role="region"
  aria-label={`Errors (${errors.length})`}
>
```

**Tradeoff:** Classic (always-visible) scrollbars take about 15px of width on Windows and Linux. macOS and iOS use overlay scrollbars that only show while scrolling, so it's also worth showing the error count in the heading (Finding 4).

#### 2. Long unbroken error strings overflow sideways and get clipped

**Severity:** Minor
**Location:** `subject.tsx:17`
**Issue type:** Responsive
**Viewport:** 320px–480px mainly; any width for very long tokens
**Move:** Step 2 item 7: text that doesn't reflow
**Confidence:** High

Error messages often contain file paths, URLs, stack frames or IDs with no spaces. Without `overflow-wrap`, these strings stick out past the box. With today's `overflow-hidden` they are cut off on the right. After the Finding 1 fix (`overflow-y-auto`), CSS turns the horizontal overflow into `auto` too, so you'd get a sideways scrollbar instead. Either way, part of the message is hard to read. WCAG 1.4.10 (Reflow) says content should fit at 320px without scrolling in two directions.

**Recommendation:**

```tsx
// Before
<p key={i} className="text-red-700 text-sm">{err}</p>

// After
<li key={i} className="text-red-700 text-sm break-words">{err}</li>
```

(`break-words` = `overflow-wrap: break-word`. It's supported everywhere without vendor prefixes. The switch to `<li>` is covered in Finding 5.)

#### 3. Once it scrolls, the error region can't be scrolled by keyboard in some browsers

**Severity:** Minor (only appears after the Finding 1 fix)
**Location:** `subject.tsx:15`
**Issue type:** Focus
**Viewport:** All
**Move:** Step 2 item 10 / Keyboard Navigation
**Confidence:** Medium

The region holds only plain text. In browsers that don't automatically make scroll containers focusable (Safari in particular; Chrome 130+ and Firefox do), a keyboard user can't reach it to scroll. That conflicts with WCAG 2.1.1 (Keyboard). Adding `tabIndex={0}` fixes it. Give the region a role and an accessible name so screen readers announce something useful when it gets focus. Make sure the focus ring is visible: the `border-red-200` border is too faint to count as a focus indicator.

**Recommendation:** Add `tabIndex={0} role="region" aria-label="…"` (shown in Finding 1) plus a visible focus style:

```tsx
className="... focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-700"
```

#### 4. An empty 128px box still shows when there are no errors, and the error count is never shown

**Severity:** Minor
**Location:** `subject.tsx:12-20`
**Issue type:** Sizing
**Viewport:** All; most noticeable at 1366×768 and smaller
**Move:** Step 2 item 5 (excessive vertical spacing) and item 6 (affordance)
**Confidence:** High

When `errors` is `[]`, the component still draws the "Errors" heading and a 128px red box. That takes up vertical space and looks like something went wrong when nothing did. When there are errors, the heading gives no count, so users have no hint that more errors may be hidden below. This matters most on platforms where scrollbars only appear during scrolling.

**Recommendation:**

```tsx
if (errors.length === 0) return null;
// ...
<h3 className="font-bold mb-2">Errors ({errors.length})</h3>
```

Switching to `max-h-32` (Finding 1) also stops a single error from sitting in a mostly empty 128px box.

#### 5. Errors aren't marked up as a list and aren't announced to screen readers

**Severity:** Minor
**Location:** `subject.tsx:15-18`
**Issue type:** Accessibility serialization
**Viewport:** N/A
**Move:** Step 2 item 10: accessibility serialization
**Confidence:** Medium

Each error is a `<p>` with nothing grouping them, so screen readers don't announce "list, N items". Also, when errors appear or change, there's no live region, so screen-reader users get no notice (WCAG 4.1.3 Status Messages). Whether the panel should interrupt (`role="alert"`) or wait (`aria-live="polite"`) depends on where it's used, which isn't visible in this file.

**Recommendation:**

```tsx
<div className="max-h-32 overflow-y-auto ..." tabIndex={0} role="region" aria-label={`Errors (${errors.length})`}>
  <ul aria-live="polite" className="space-y-1">
    {errors.map((err, i) => (
      <li key={i} className="text-red-700 text-sm break-words">{err}</li>
    ))}
  </ul>
</div>
```

#### 6. Error meaning relies partly on color (informational)

**Severity:** Informational
**Location:** `subject.tsx:13-17`
**Issue type:** Accessibility serialization
**Viewport:** N/A
**Move:** Step 2 item 6: affordance
**Confidence:** Low

The "Errors" heading text means this mostly passes WCAG 1.4.1 (Use of Color). Adding an icon next to each item would make it more robust if this panel is ever shown without the heading. The text contrast is fine: `red-700` on `red-50` is about 5.9:1.

## What Looks Good

- **Text contrast:** `text-red-700` on `bg-red-50` meets WCAG AA for small text.
- **Compact spacing:** `p-4` / `p-2` / `mb-2` already match the compact defaults the checklist prefers.
- **Clear heading:** "Errors" makes the purpose of the panel obvious instead of leaving it to color alone.
- **No conflicting flex or absolute layout:** The structure is simple block layout, so there's no `shrink-0`/`flex-1` or anchoring risk.
- **State matrix (item 8):** Not applicable. The component has no interactive elements (no buttons, inputs or handlers).
- **Item 9 (3D) / Item 11 (overlap/z-order):** Not applicable. There's no 3D or layered layout.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Visible, scrollable overflow instead of silent clipping | Skill execution rule 2; NNGroup on scroll affordances | `h-32 overflow-hidden` → `max-h-32 overflow-y-auto` |
| Content reflows at 320px | WCAG 1.4.10 Reflow | Added `break-words` to error items |
| Scrollable regions reachable by keyboard | WCAG 2.1.1 Keyboard; WCAG 2.4.7 Focus Visible | `tabIndex={0}`, `role="region"`, `aria-label`, `focus-visible` outline |
| Status messages can be detected programmatically | WCAG 4.1.3 Status Messages | `aria-live="polite"` on the error list |
| Correct semantic structure | WCAG 1.3.1 Info and Relationships | `<p>` siblings → `<ul>/<li>` |
| Users shouldn't have to guess whether content is hidden | NNGroup on discoverability | Error count shown in the heading |

## Keyboard Navigation

As written, the file has **no focusable elements**. The items below cover the recommended version, which adds `tabIndex={0}` to the scroll region.

**Focus order.** After the fix there's one focusable element: the error region (`subject.tsx:15`). Its place in the DOM matches its visual place, and there's no `order`, `row-reverse` or absolute positioning. Where it lands in the page-wide tab order depends on the parent component, which wasn't provided.

**Escape-key behavior.** N/A: this file has no modals or overlays.

**Skip-link presence.** N/A: the file doesn't change page-level structure.

**Focus-trap risks.** None found. The region holds no focusable children, and Tab moves past it normally.

## Viewport Verification Checklist

- [ ] **360px mobile:** **Fails now.** Wrapped messages lower the visible limit to about 2–3 errors, and long tokens get cut off on the right. Passes after Findings 1 and 2.
- [ ] **1366×768 (common laptop):** **Fails now** if there are more than about 5 errors (the rest are hidden). The empty-state box wastes 128px. Passes after Findings 1 and 4.
- [x] **1920×1080 (standard desktop):** The layout itself is fine, but the clipping bug from Finding 1 happens at every width.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | `overflow-hidden` + fixed `h-32` silently hides errors | Major | Overflow | `subject.tsx:15` | High |
| 2 | Long unbroken strings overflow sideways | Minor | Responsive | `subject.tsx:17` | High |
| 3 | Scroll region can't be reached by keyboard (after fix) | Minor | Focus | `subject.tsx:15` | Medium |
| 4 | Empty box when there are no errors; no error count | Minor | Sizing | `subject.tsx:12-20` | High |
| 5 | Not a list; no live region | Minor | Accessibility serialization | `subject.tsx:15-18` | Medium |
| 6 | Some reliance on color | Informational | Accessibility serialization | `subject.tsx:13-17` | Low |

## Overall Assessment

The component is small and its structure is sound, but it has one real bug: a fixed-height `overflow-hidden` box cuts off every error after about the fifth, with no sign that anything is missing. That's the worst failure an error display can have, because users think they've seen all their errors when they haven't. Everything can be fixed in place, and nothing here points to a bigger structural problem. The most important change is replacing `h-32 overflow-hidden` with `max-h-32 overflow-y-auto`. Then make the region keyboard-focusable, show the error count, and add `break-words` so the panel works at 320px.
