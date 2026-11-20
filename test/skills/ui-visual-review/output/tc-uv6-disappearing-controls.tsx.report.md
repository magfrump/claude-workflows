# UI Visual Review: subject.tsx (`TaskRunner`)

**Scope:** `subject.tsx` (the whole file, 32 lines)
**Date:** 2026-11-20
**Based on:** Code analysis only. No code-fact-check report was provided, so I checked the file's own comments against the code by hand (see Finding 2).

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** Small mobile (320–480px), tablet/laptop (768–1366px), desktop (1920px+)
- **Target browsers / platforms:** Current evergreen browsers and mobile Safari (default)
- **Review mode:** Full audit (all checklist items 1–8; items 9–11 don't apply because there is no 3D or spatial-layering content)
- **Project guidelines:** None found. There is no `docs/UI_LAYOUT_GUIDELINES.md` and no `.md` files in the repo, so the skill defaults apply.

## Findings

#### 1. "Run Task" button disappears when the task finishes, so the task can't be run again

**Severity:** Major
**Location:** `subject.tsx:19-29`
**Issue type:** Affordance
**Viewport:** all
**Move:** Step 2 item 6: controls that disappear after completion
**Confidence:** High

The button only renders while `status !== "done"`. When the task finishes it is removed and replaced by a "Complete!" paragraph, so the user can't run the task again without reloading the page. The header comment rates this as Minor. I've rated it Major: re-running isn't just hard to find, it's impossible. Removing the button while it has focus also drops keyboard focus to `<body>`, which disorients keyboard and screen-reader users (WCAG 2.4.3 Focus Order). Changing the button's label instead of unmounting it keeps the control in place, keeps focus where it is, and keeps the action available.

**Recommendation:** Always render the button and change its label based on status.

```tsx
// Before
{status !== "done" && (
  <button onClick={() => setStatus("running")} className="...">
    {status === "running" ? "Running..." : "Run Task"}
  </button>
)}
{status === "done" && <p className="text-green-600">Complete!</p>}

// After
<button
  type="button"
  onClick={runTask}
  disabled={status === "running"}
  aria-busy={status === "running"}
  className="..."
>
  {status === "running" ? "Running..." : status === "done" ? "Re-run Task" : "Run Task"}
</button>
<p role="status" className="text-green-700">
  {status === "done" ? "Complete!" : ""}
</p>
```

**Tradeoff:** None worth mentioning. The button stays in place, so the layout doesn't shift either.

#### 2. Nothing ever sets status to "done", so the button gets stuck on "Running..."

**Severity:** Major
**Location:** `subject.tsx:10, 21`
**Issue type:** Other (state logic that affects what's shown)
**Viewport:** all
**Move:** Checking the file's comments against the code (the "disappears when the task is complete" claim)
**Confidence:** High

`setStatus` is only ever called with `"running"`. No effect, callback or promise moves the status to `"done"`. That means the "Complete!" branch (lines 27–29) never runs, and once clicked the button shows "Running..." forever. The bug described in the header comment only happens once completion logic is added. Until then, what users actually see is a control stuck on "Running...".

**Recommendation:** Connect completion to the real task, for example `const runTask = async () => { setStatus("running"); await doTask(); setStatus("done"); };`. Also handle errors, either with an `"error"` status that shows a message and a retry, or by falling back to idle.

#### 3. Button stays clickable while running and has no hover, focus, active or disabled styles

**Severity:** Major
**Location:** `subject.tsx:20-25`
**Issue type:** State coverage / Focus
**Viewport:** all
**Move:** Step 2 item 8: interactive element state matrix
**Confidence:** High

The button only has default styling. It has no `focus-visible` style, so it relies on the browser's default outline, which Tailwind's Preflight doesn't remove but which many design resets do (WCAG 2.4.7 asks for a visible focus indicator). There's no hover or active feedback, so clicks feel "dead". During `"running"` the button can still be clicked and gives no sign that it's busy. Clicking it again does nothing visible, but in a real implementation it could start the task a second time.

**Recommendation:**

```tsx
className="py-2 px-4 rounded bg-blue-700 text-white
  hover:bg-blue-800 active:bg-blue-900
  focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-700
  disabled:bg-gray-400 disabled:cursor-not-allowed"
disabled={status === "running"}
```

#### 4. Button text and "Complete!" text don't have enough contrast

**Severity:** Major
**Location:** `subject.tsx:22, 28`
**Issue type:** Accessibility
**Viewport:** all
**Move:** Step 2 item 6: visibility and affordance
**Confidence:** High

- White on `bg-blue-500` (#3b82f6) is about **3.7:1**.
- `text-green-600` (#16a34a) on white is about **3.3:1**.

Both are normal-weight body-size text, so both fail WCAG 1.4.3 Contrast (Minimum), which requires 4.5:1. Also, "Complete!" is mostly signalled by its green color, though the word itself carries the meaning, so this isn't a strict 1.4.1 (Use of Color) failure.

**Recommendation:** Use `bg-blue-700` (#1d4ed8, about 6.7:1 with white) and `text-green-700` (#15803d, about 5.0:1 on white). You could also add a ✓ icon to the completion message.

#### 5. Status changes aren't announced to assistive technology

**Severity:** Minor
**Location:** `subject.tsx:24, 27-29`
**Issue type:** Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 10 / Affordance principle 6 (loading and progress states)
**Confidence:** High

When the screen goes from "Running..." to "Complete!", nothing tells a screen reader. The completion `<p>` is newly mounted and has no live region, so it won't be read out (WCAG 4.1.3 Status Messages).

**Recommendation:** Render a `role="status"` (polite live region) container all the time and change only its text, as shown in Finding 1. Add `aria-busy` to the button or the output region while the task runs.

#### 6. Task output box has no height limit, which will push the button below the fold once real output arrives

**Severity:** Minor
**Location:** `subject.tsx:15-17`
**Issue type:** Overflow
**Viewport:** Mostly 320–768px and 1366×768
**Move:** Step 2 item 1: unbounded content without scroll caps
**Confidence:** Medium (the box currently holds only placeholder text)

The output box is labelled as holding task output, which tends to grow without limit (logs, results). It has no `max-h-*` or overflow handling. Long output will push the Run button below the fold, and lines with no break points (long paths, URLs) will cause horizontal overflow on narrow screens.

**Recommendation:**

```tsx
// Before
<div className="border p-4 rounded">

// After
<div className="border p-4 rounded max-h-[50vh] overflow-y-auto break-words"
     role="region" aria-label="Task output" tabIndex={0}>
```

You could also move the button above the output, or dock it in a fixed footer, so it stays reachable at any output length.

**Tradeoff:** `tabIndex={0}` adds one tab stop, but keyboard users need it to scroll the region (axe's `scrollable-region-focusable` rule).

#### 7. `<h3>` with no parent heading, and no `type` on the button

**Severity:** Informational
**Location:** `subject.tsx:14, 20`
**Issue type:** Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 10
**Confidence:** Low (depends on the page that uses this component)

`<h3>` is only correct if an `<h2>` comes before it on the host page (WCAG 1.3.1 Info and Relationships). The button has no `type="button"`, so if the component is ever placed inside a `<form>` it will submit the form.

**Recommendation:** Pass in a heading level, or check how the host page uses it. Add `type="button"`.

#### 8. Touch target meets AA but not AAA

**Severity:** Informational
**Location:** `subject.tsx:22`
**Issue type:** Sizing
**Viewport:** 320–768px (touch)
**Move:** Step 2 item 6
**Confidence:** High

`py-2` with a 24px line height gives a button about 40px tall. That passes WCAG 2.5.8 (24×24 minimum) but not 2.5.5 AAA (44×44).

**Recommendation:** If AAA matters for this project, add `min-h-11`.

## What Looks Good

- The layout is a simple vertical stack (`space-y-4`, `p-4`) with no fixed widths, so it reflows correctly from 320px to 1920px+ (WCAG 1.4.10).
- The trigger is a real `<button>`, not a clickable `<div>`, so keyboard support and the button role come for free.
- The button changes its label for the running state, which is the right idea. It just needs to cover "done" too (Finding 1).
- Spacing is compact and nothing uses absolute positioning, so there are no anchoring or occlusion problems.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Controls stay available after completion | Skill item 6; NNGroup (visibility of system status) | Change the label to "Re-run Task" instead of unmounting the button |
| Visible focus indicator | WCAG 2.4.7 / 2.4.13 | Add a `focus-visible:outline` ring |
| Text contrast | WCAG 1.4.3 | blue-500 → blue-700, green-600 → green-700 |
| Status messages | WCAG 4.1.3 | A `role="status"` live region that is always rendered |
| Keep focus in a logical place | WCAG 2.4.3 | Keep the focused button mounted |
| Scrollable overflow instead of unbounded growth | Skill item 1; WCAG 1.4.10 | `max-h-[50vh] overflow-y-auto` on the output box |

## Keyboard Navigation

**Focus order.** There is one focusable element: the Run button (`subject.tsx:20`). The tab order matches the visual order. After Finding 6's fix the output region becomes a tab stop before the button, which also matches the visual order. Problem: when status becomes `"done"` the button unmounts and focus falls back to `<body>` (Finding 1).

**Escape-key behavior.** N/A: there are no modals or overlays in this diff.

**Skip-link presence.** N/A: the diff doesn't change page-level structure.

**Focus-trap risks.** No focus-trap risks identified. The only related problem is focus loss when the button unmounts, covered by Finding 1.

## Viewport Verification Checklist

- [x] 360px mobile: no horizontal overflow with placeholder content. Long unbreakable output lines would overflow (Finding 6). Touch target about 40px meets AA.
- [ ] 1366×768: the button is visible now, but long output will push it below the fold (Finding 6).
- [x] 1920×1080: the stack fills the width as expected. Nothing has a fixed width.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Button disappears after completion; no re-run; focus is lost | Major | Affordance | `subject.tsx:19-29` | High |
| 2 | Status never reaches "done"; button stuck on "Running..." | Major | Other | `subject.tsx:10,21` | High |
| 3 | No hover/focus/active/disabled states; clickable while running | Major | State coverage | `subject.tsx:20-25` | High |
| 4 | Contrast about 3.7:1 (button) and 3.3:1 ("Complete!") | Major | Accessibility | `subject.tsx:22,28` | High |
| 5 | Status changes not announced | Minor | Accessibility serialization | `subject.tsx:24,27-29` | High |
| 6 | Output box has no height limit | Minor | Overflow | `subject.tsx:15-17` | Medium |
| 7 | `<h3>` hierarchy; button has no `type` | Informational | Accessibility serialization | `subject.tsx:14,20` | Low |
| 8 | Touch target about 40px (meets AA, not AAA) | Informational | Sizing | `subject.tsx:22` | High |

## Overall Assessment

The layout itself is sound: a simple, flexible vertical stack with no responsive or positioning bugs. The problems are in how the control behaves across its states and in accessibility. All of them can be fixed in place, and no restructuring is needed.

The most important change is to always render the button and change its label (Run Task → Running... → Re-run Task), with it disabled while running. That one change fixes the missing re-run, the focus loss and most of the missing state coverage.

On the "Minor" rating in the file's header comment: I rated the disappearing button Major, because it makes re-running impossible rather than just harder to find. Separately, the completion logic is missing entirely (Finding 2), so the bug the comment describes can't actually happen in the code as written. Instead, the button gets stuck on "Running...".
