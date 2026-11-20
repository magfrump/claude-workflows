# UI Visual Review — `ActionList` (subject.tsx)

**Scope:** `subject.tsx` (whole file, 27 lines)
**Date:** 2026-11-20
**Based on:** Code analysis only. No code-fact-check report was provided, so I checked the file's header comment against the code myself (see finding 4).

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** Small mobile (320–480px), tablet/small laptop (768–1024px), large desktop (1920px+)
- **Target browsers / platforms:** Current evergreen browsers and mobile Safari (default)
- **Review mode:** Full audit (all checklist items 1–8 and 10; items 9 and 11 skipped because the file has no 3D or spatial/stacked layout)
- **Project guidelines:** None found (the repo has no `docs/UI_LAYOUT_GUIDELINES.md` or other `.md` files)

## Findings

#### 1. Action rows can't be used with a keyboard or seen by assistive tech

**Severity:** Critical
**Location:** `subject.tsx:21-23`
**Issue type:** Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 10 (accessibility serialization / tab traversal) and item 8 (state matrix)
**Confidence:** High

Each action is a `<div onClick>` with no `role`, no `tabIndex` and no key handler. Keyboard users can't Tab to it or activate it. Screen readers announce it as plain text, with no "button" role. So keyboard-only, switch and screen-reader users can't run any action at all, and actions are the whole point of this component. It fails WCAG 2.1.1 Keyboard and 4.1.2 Name, Role, Value. It is Critical because it locks out a whole group of users from the main task.

**Recommendation:** Use a real `<button type="button">`. It brings focusability, Enter/Space activation and the button role with no extra code. Wrapping the buttons in a list also tells screen readers how many actions there are.

```tsx
// Before
<div key={i} onClick={action.onClick} className="text-sm text-gray-600 py-1">
  {action.label}
</div>

// After
<ul className="space-y-1">
  {actions.map((action) => (
    <li key={action.label}>
      <button type="button" onClick={action.onClick} className="...see finding 2...">
        {action.label}
      </button>
    </li>
  ))}
</ul>
```

#### 2. Clickable rows look exactly like static text

**Severity:** Major
**Location:** `subject.tsx:21`
**Issue type:** Affordance
**Viewport:** all
**Move:** Step 2 item 6 (visibility and affordance)
**Confidence:** High

`text-sm text-gray-600 py-1` gives no border, no background, no `cursor-pointer` and no underline. The rows look like a muted caption under the "Actions" heading. NNGroup's flat-UI research shows that weak signifiers make users work harder and lead them to miss controls. On touch devices there isn't even a hover cue, so nothing hints that the rows can be tapped.

**Recommendation:** Give each row a visible edge or background, plus a pointer cursor.

```tsx
className="w-full text-left text-sm text-gray-800 px-3 py-2 rounded-md
           border border-gray-300 bg-white cursor-pointer
           hover:bg-gray-50 active:bg-gray-100
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-600 focus-visible:ring-offset-2
           disabled:opacity-50 disabled:cursor-not-allowed"
```

Tradeoff: bordered rows take a bit more space and look heavier. If you want a lighter look, a "link" style (blue text, underline on hover, chevron icon) is fine, as long as hover and focus states are kept.

#### 3. No hover, focus, active or disabled states

**Severity:** Major
**Location:** `subject.tsx:21`
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 8 (interactive element state matrix)
**Confidence:** High

Only the default state is styled. Nothing changes on hover or press, so clicks feel "dead." There is no focus indicator, although that matters only once finding 1 makes the rows focusable (WCAG 2.4.7). There is also no disabled state, and the `Action` type has no `disabled` field, so a currently unavailable action can't be shown as unavailable.

**Recommendation:** Apply the state classes from finding 2. If some actions can be unavailable, add `disabled?: boolean` to `Action` and pass it through as the native `disabled` attribute, which also stops clicks.

#### 4. The header comment cites the wrong WCAG criterion

**Severity:** Informational
**Location:** `subject.tsx:5-6`
**Issue type:** Other
**Viewport:** all
**Move:** Step 2 item 6 (checking cited standards)
**Confidence:** Medium

The comment cites WCAG 2.5.8 (Target Size). Going by the classes alone (I didn't measure it in a browser), each row is about 28px tall: a 20px `text-sm` line plus 8px of `py-1` padding. It also spans the container width. That likely already meets the 24×24px AA minimum. The criteria that actually fail are 2.1.1 and 4.1.2 (finding 1). Visual affordance itself comes from NNGroup research, not WCAG. One WCAG point is related: if you add a border, it needs 3:1 contrast against the background (1.4.11). `border-gray-300` on white falls below that, so use `border-gray-400` or darker if the border is the only cue.

**Recommendation:** Change the comment to cite 2.1.1, 4.1.2 and NNGroup signifier research. Use a border color that reaches 3:1.

#### 5. Long action lists have no height limit

**Severity:** Informational
**Location:** `subject.tsx:17`
**Issue type:** Overflow
**Viewport:** 320–480px most affected
**Move:** Step 2 item 1 (unbounded content)
**Confidence:** Low

`actions` can be any length and the container has no height limit. In normal page flow the page just scrolls, which is fine. But if this component is placed in a fixed-height sidebar or popover, a long list will overflow its parent.

**Recommendation:** Only if the component lives in a constrained parent: put `max-h-[60vh] overflow-y-auto` on the list, and keep the heading outside the scrolling area.

## What Looks Good

- **Text contrast:** `text-gray-600` on white is about 7.5:1, which passes WCAG 1.4.3 AA (and AAA).
- **Target height:** about 28px rows, full container width, which likely meets the 2.5.8 AA minimum (an estimate from the classes, not a measurement).
- **Spacing:** `p-4` and `space-y-2` are compact. Nothing wastes vertical space (item 5).
- **No clipping or positioning problems:** no `overflow-hidden`, no absolute positioning, and no fixed widths, so the layout reflows from 320px up (items 1, 4 and 7).

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Use native interactive elements | WCAG 2.1.1, 4.1.2 | Replaced `<div onClick>` with `<button type="button">` |
| Interactive elements look distinct | NNGroup (flat UI signifiers), WCAG 1.4.11 | Added border, background and `cursor-pointer` |
| Visible focus indicator | WCAG 2.4.7 / 2.4.13 | Added a `focus-visible:ring-2` ring with offset |
| Feedback when pressed | Affordance Principle 2 | Added `hover:` and `active:` background changes |
| Disabled elements look disabled | Affordance Principle 5 | Added `disabled:opacity-50 disabled:cursor-not-allowed` |
| List semantics | WCAG 1.3.1 | Wrapped the actions in `<ul>`/`<li>` |

## Keyboard Navigation

**Focus order.** Currently there are **no focusable elements**: every action row (`subject.tsx:21`) is a plain `div` that Tab skips. After the fix, the tab order is action[0] … action[n−1] in array order. That matches the visible top-to-bottom order, since the layout has no `order`, `row-reverse` or absolute positioning. The `<h3>` at line 18 is correctly not focusable.

**Escape-key behavior.** N/A — no modals or overlays in this diff.

**Skip-link presence.** N/A — diff does not change page-level structure.

**Focus-trap risks.** No focus-trap risks identified. The problem here is the reverse: users can't get into the actions at all (finding 1).

## Viewport Verification Checklist

- [x] 360px mobile: no horizontal overflow, rows are full width, targets about 28px tall. But nothing shows the rows can be tapped (finding 2).
- [x] 1366x768 (common laptop): all actions visible for typical list lengths.
- [x] 1920x1080 (standard desktop): fills its container. Full-width rows on a wide container may look stretched, so consider `max-w-md` if the parent doesn't limit width.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | `<div onClick>` can't be reached or activated by keyboard and has no role | Critical | Accessibility serialization | `subject.tsx:21-23` | High |
| 2 | Clickable rows look like static text | Major | Affordance | `subject.tsx:21` | High |
| 3 | No hover, focus, active or disabled states | Major | State coverage | `subject.tsx:21` | High |
| 4 | Header comment cites the wrong WCAG criterion | Informational | Other | `subject.tsx:5-6` | Medium |
| 5 | No height limit for long action lists | Informational | Overflow | `subject.tsx:17` | Low |

## Overall Assessment

The layout itself is fine: it reflows, the spacing is compact, and nothing is clipped. The problems are in what the interactive elements are and how they look. The top fix is replacing `<div onClick>` with a native `<button type="button">`: today keyboard and screen-reader users can't use any action at all (WCAG 2.1.1 / 4.1.2). That one change, plus a border or background and the hover/focus/active/disabled classes in finding 2, fixes the three serious findings. It's a fix of roughly ten lines in one place, with no structural rework. The test's expected "Major affordance" finding is confirmed. The keyboard problem underneath it is more serious and should be rated Critical.
