# UI Visual Review: `ActionList` (subject.tsx)

**Scope:** `subject.tsx` (single-file review)
**Date:** 2026-11-20
**Based on:** No code-fact-check report was provided, so this review is based on reading the code only. The header comment's claims are checked inline under Finding 2.

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet/laptop), 1920px+ (desktop)
- **Target browsers / platforms:** Modern evergreen browsers and mobile Safari (default; the project doesn't specify)
- **Review mode:** Full audit (all checklist items 1–11; items 9 and 11 don't apply because there is no 3D or spatial content)
- **Project-local guidelines:** None found (`docs/` doesn't exist)

## Findings

#### 1. Action items can't be reached or used with a keyboard

**Severity:** Critical
**Location:** `subject.tsx:21-23`
**Issue type:** Focus / Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 8 (state matrix) and item 10 (accessibility serialization / tab traversal)
**Confidence:** High

Each action is a plain `<div onClick>`. It has no `role`, no `tabIndex` and no key handler. As a result:

- **Keyboard users:** the actions are never in the tab order, so they can't run any action (WCAG 2.1.1 Keyboard, Level A).
- **Screen-reader users:** the item is announced as static text with no button role (WCAG 4.1.2 Name, Role, Value, Level A).
- **Switch and voice-control users:** these depend on the button role being exposed, so they are also locked out.

This shuts out a whole class of users from the component's only job, which is why it's rated Critical.

**Recommendation:** Use a native `<button type="button">`. It brings focusability, Enter/Space activation and the button role for free. Don't patch the `<div>` with `role` + `tabIndex` + `onKeyDown`.

```tsx
// Before
<div key={i} onClick={action.onClick} className="text-sm text-gray-600 py-1">
  {action.label}
</div>

// After
<li key={action.label}>
  <button
    type="button"
    onClick={action.onClick}
    className="w-full text-left text-sm text-gray-700 px-3 py-2 min-h-[44px]
               rounded border border-gray-300 bg-white cursor-pointer
               hover:bg-gray-50 hover:border-gray-400
               active:bg-gray-100
               focus-visible:outline-none focus-visible:ring-2
               focus-visible:ring-blue-600 focus-visible:ring-offset-2
               disabled:opacity-50 disabled:cursor-not-allowed
               break-words"
  >
    {action.label}
  </button>
</li>
```

(Wrap the mapped items in a `<ul className="space-y-2">`; see Finding 5.)

**Tradeoff:** `key={action.label}` assumes labels are unique. If they aren't, use a stable ID on the `Action` type. Either is better than `key={i}` if the list can be reordered.

#### 2. Clickable items look exactly like static text

**Severity:** Major
**Location:** `subject.tsx:21`
**Issue type:** Affordance
**Viewport:** all; worst on touch devices, where there is no hover to explore
**Move:** Step 2 item 6 (visibility and affordance)
**Confidence:** High

`text-sm text-gray-600 py-1` gives the item no border, no background, no `cursor-pointer` and no hover change. Nothing tells a user it can be clicked, and it looks just like the body text around it. NNGroup research on flat UI shows that elements with weak signifiers cost users more effort and get missed. WCAG 1.4.11 (Non-text Contrast) also expects UI component boundaries to be perceivable when they're needed to identify the control.

The skill's severity guidelines put "affordance is weak" at Major.

**Corrections to the file's header comment:**
- It expects **Minor** severity. This review rates it **Major**.
- It cites **WCAG 2.5.8** for this problem, but 2.5.8 is about *target size*, not affordance. The target actually passes 2.5.8 (see Finding 3). The right references here are NNGroup's signifier research and WCAG 1.4.11.

**Recommendation:** Add a visible border, a background, `cursor-pointer` and a hover change, as in the Finding 1 fix. If the design calls for a lighter look, a link-style treatment (underline plus a chevron) is an acceptable minimum. Don't leave it as bare text.

**Tradeoff:** Bordered buttons add visual weight to a list. A borderless "menu-item" style with hover/focus fills is a reasonable middle ground, but the default state still needs something that signals it can be clicked, such as a chevron or an underline.

#### 3. Target height meets AA but not AAA

**Severity:** Minor
**Location:** `subject.tsx:21`
**Issue type:** Sizing
**Viewport:** 320–1024px (touch)
**Move:** Step 2 item 6 (touch target sizes)
**Confidence:** High

- **Height:** `text-sm` (20px line height) plus `py-1` (4px top and bottom) makes each item about 28px tall.
- **Width:** a block `<div>` stretches to the container's full width.

That passes WCAG 2.5.8's 24×24px (AA) but falls short of 2.5.5's 44×44px (AAA) and Apple HIG's 44pt recommendation. The `space-y-2` gap (8px) also puts neighbouring targets close together, which raises the chance of mis-taps on mobile.

**Recommendation:** Use `py-2` plus `min-h-[44px]`, as in the Finding 1 fix.

**Tradeoff:** A list of N actions grows by about 16px × N in height.

#### 4. No hover, focus, active or disabled states

**Severity:** Major
**Location:** `subject.tsx:21`
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 8 (interactive element state matrix)
**Confidence:** High

Only the default state is styled, and that default doesn't look interactive. See the state matrix below. The Finding 1 fix covers every state.

#### 5. Long unbroken labels can overflow; the list has no list semantics

**Severity:** Informational
**Location:** `subject.tsx:17-24`
**Issue type:** Responsive / Accessibility serialization
**Viewport:** 320–480px
**Move:** Step 2 item 7 (text reflow) and item 10
**Confidence:** Medium

- **Overflow at 320px:** a label with no spaces, such as a long filename or URL, will overflow horizontally because there is no `break-words` / `overflow-wrap: anywhere`. This breaks WCAG 1.4.10 Reflow.
- **List semantics:** the actions are a list but are rendered as sibling `<div>`s. With `<ul>`/`<li>`, screen readers announce "list, N items", which helps orientation.
- **Unbounded length:** `actions` can be any length and there is no cap. Whether that matters depends on the parent layout, which isn't visible here. In a sidebar or popover, consider `max-h-* overflow-y-auto` with the heading kept outside the scroll area (Step 2 item 2).
- **Heading level:** the `<h3>` assumes an h2 above it. That can't be checked from this file, so it's low confidence.

**Recommendation:** Add `break-words`, wrap the items in `<ul className="space-y-2">`/`<li>`, and give the heading an `id` with `aria-labelledby` on the `<ul>`.

### State matrix (item 8)

- [ ] Action item `<div onClick>` (`subject.tsx:21`)
  - [ ] default: `text-sm text-gray-600 py-1` looks the same as static text; no border, background or cursor
  - [ ] hover: no `hover:` styles, no `cursor-pointer`
  - [ ] focus: the element can't receive focus at all
  - [ ] active: no `active:` style; clicks give no feedback
  - [ ] disabled: `Action` has no `disabled` field, so there's no way to disable an action. Mark this N/A if actions are never disabled; otherwise add `disabled?: boolean` and pass it to `<button disabled>`
  - [N/A] error: not a control that gets validated

## What Looks Good

- `text-gray-600` (#4b5563) on white has a contrast ratio of about 7.5:1, which passes WCAG 1.4.3 AA and AAA for text.
- The block-level items span the full width, so the targets are wide and easy to hit horizontally.
- `p-4 space-y-2` is compact spacing, so nothing wastes vertical space (item 5 is clean).
- There's no `overflow: hidden` clipping, no misanchored absolute positioning, and no `shrink-0`/`flex-1` misuse (items 1–4 are clean, apart from the unbounded-list note in Finding 5).
- The `<h3>` heading gives the list a visible label.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Interactive controls must work from the keyboard | WCAG 2.1.1, 4.1.2 | Replaced `<div onClick>` with native `<button type="button">` |
| Interactive elements must look distinct | NNGroup (flat UI signifiers), WCAG 1.4.11 | Added border, background, `cursor-pointer` and hover fill |
| Visible focus indicator | WCAG 2.4.7, 2.4.13 | `focus-visible:ring-2 ring-offset-2` |
| Adequate target size | WCAG 2.5.8 (AA, met), 2.5.5 (AAA) | `min-h-[44px] py-2` |
| Text reflow | WCAG 1.4.10 | `break-words` |
| Semantic structure | WCAG 1.3.1 | `<ul>`/`<li>` list markup |

## Keyboard Navigation

**Focus order:** This currently **fails**. The action items have no tab stops, so Tab skips the whole component. After the fix, the order is: each `<button>` (`subject.tsx:21`), from top to bottom in `actions` array order. That matches the visual order because there is no `order`, `row-reverse` or absolute positioning.

**Escape-key behavior:** N/A. There are no modals or overlays in this diff.

**Skip-link presence:** N/A. The diff doesn't change page-level structure.

**Focus-trap risks:** None found. (The opposite problem applies: the controls can't be focused at all. See Finding 1.)

## Viewport Verification Checklist

- [ ] 360px mobile: items are reachable by touch, but the ~28px targets are below the 44px AAA size, nothing marks them as tappable, and long unbroken labels may overflow
- [x] 1366x768 (common laptop): visible without scrolling for typical list lengths (depends on the parent layout)
- [x] 1920x1080 (standard desktop): full-width rows fill the container; no excess whitespace

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Actions can't be reached or used by keyboard / AT (`<div onClick>`) | Critical | Focus / A11y serialization | `subject.tsx:21-23` | High |
| 2 | Clickable items look like static text | Major | Affordance | `subject.tsx:21` | High |
| 4 | No hover, focus, active or disabled states | Major | State coverage | `subject.tsx:21` | High |
| 3 | ~28px target height (meets AA, not AAA) | Minor | Sizing | `subject.tsx:21` | High |
| 5 | Long labels may overflow; no list semantics | Informational | Responsive / A11y | `subject.tsx:17-24` | Medium |

## Overall Assessment

The layout is sound: spacing, sizing and overflow behaviour are fine. The problem is the interaction element. Using a `<div>` with only a click handler makes the component impossible to use without a mouse or touch screen. The header comment's expectation of a Minor affordance issue understates it: there's a Critical keyboard-access failure underneath, and the affordance issue itself is Major. One change fixes everything in place: swap the `<div onClick>` for a styled native `<button type="button">` inside a `<ul>`/`<li>`. That one swap resolves Findings 1–4 and most of 5, with no structural redesign needed.
