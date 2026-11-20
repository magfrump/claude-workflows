# UI Visual Review: `subject.tsx` (TaskRunner)

**Scope:** `subject.tsx` (single file, full audit)
**Date:** 2026-11-20

I didn't have a code-fact-check report, so this review is based on reading the code. The comments in the file ("BUG: Button disappears when done", "Expected finding: Major") were checked against the code, not taken as true. They're right about the design, but see Finding 7: as written, nothing ever sets the status to `"done"`.

## Environment

- **Files reviewed:** `subject.tsx`
- **Project guidelines:** none found (no `docs/UI_LAYOUT_GUIDELINES.md` or other `.md` files in the repo)
- **Target viewports:** 320–480px, 768–1024px, 1366×768, 1920px+
- **Target browsers / platforms:** modern evergreen browsers and mobile Safari (default; Tailwind assumed)
- **Review mode:** Full audit (items 1–8 and 10; items 9 and 11 don't apply because there's no 3D or spatial/stacked layout)

## Findings

#### 1. The Run button disappears on completion, so the task can't be re-run and keyboard focus is lost

**Severity:** Major
**Location:** `subject.tsx:19-29`
**Issue type:** Affordance
**Viewport:** all
**Move:** Step 2 item 6: controls that disappear after completion
**Confidence:** High

When `status === "done"`, the `<button>` is unmounted and a static "Complete!" `<p>` replaces it. There's no control left to run the task again, so the user's only option is to reload the page. A user who clicked the button with the keyboard also loses focus when it unmounts: focus falls back to `<body>`, and they have to Tab again from the top of the page (this harms focus order, WCAG 2.4.3). Changing the button's label keeps both the control and the focus in place.

**Recommendation:** Always render the button and change its label based on status. Show the completion message as a separate status line (see Finding 4).

```tsx
// Before
{status !== "done" && (
  <button onClick={() => setStatus("running")} className="...">
    {status === "running" ? "Running..." : "Run Task"}
  </button>
)}
{status === "done" && <p className="text-green-600">Complete!</p>}

// After
<button type="button" onClick={run} className="...">
  {status === "running" ? "Running…" : status === "done" ? "Re-run Task" : "Run Task"}
</button>
```

#### 2. The button has no disabled or busy state while running

**Severity:** Major
**Location:** `subject.tsx:20-25`
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 8: interactive element state matrix
**Confidence:** High

While the status is `"running"`, the button still looks and behaves like an active control. It's clickable, it calls `setStatus("running")` again, and it doesn't tell assistive technology that work is in progress. Users get no signal that clicking again does nothing, and if the real task logic replaces the placeholder, repeated clicks could start the task twice.

**Recommendation:** Disable the button and mark it busy while running, and make the disabled state clearly visible.

```tsx
<button
  type="button"
  onClick={run}
  disabled={status === "running"}
  aria-busy={status === "running"}
  className="... disabled:bg-gray-400 disabled:cursor-not-allowed"
>
```

#### 3. White text on `bg-blue-500` fails text contrast

**Severity:** Major
**Location:** `subject.tsx:22`
**Issue type:** Affordance
**Viewport:** all
**Move:** Step 2 item 6: visibility and affordance
**Confidence:** High

White on Tailwind `blue-500` (#3b82f6) has a contrast ratio of about 3.7:1. The label is normal-weight text at the default size, so it needs 4.5:1 (WCAG 1.4.3 AA). `blue-600` (#2563eb) gives about 5.2:1.

**Recommendation:** Use `bg-blue-600` as the default, `hover:bg-blue-700` for hover and `active:bg-blue-800` for active (see Finding 5).

#### 4. "Complete!" isn't announced to screen readers and fails contrast

**Severity:** Major
**Location:** `subject.tsx:27-29`
**Issue type:** Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 6 (Affordance Principle 6) and item 10
**Confidence:** High

The completion message is added to the page with no live region, so screen-reader users get no notice that the task finished (WCAG 4.1.3 Status Messages). Also, `text-green-600` (#16a34a) on white is about 3.3:1, below the 4.5:1 required by WCAG 1.4.3. The message is just the word "Complete!" with no icon, but that's acceptable because the wording carries the meaning, not the color alone.

**Recommendation:** Render a `role="status"` container all the time and change only its text, so screen readers reliably announce updates. Use `text-green-700` (#15803d, about 5.0:1).

```tsx
<p role="status" className="text-green-700 min-h-[1.5rem]">
  {status === "done" ? "Complete!" : status === "running" ? "Running…" : ""}
</p>
```

`min-h` reserves the line's height so the layout doesn't jump when the text appears.

#### 5. Button only has default styling, with no hover, active or custom focus styles

**Severity:** Minor
**Location:** `subject.tsx:22`
**Issue type:** State coverage
**Viewport:** all (hover only matters for pointer devices)
**Move:** Step 2 item 8: interactive element state matrix
**Confidence:** High

Only default styles are defined, so the button gives no feedback on hover or press. Tailwind's Preflight doesn't remove the browser's own focus ring, so a focus indicator does exist. But the default ring on a saturated blue background can be hard to see, and nothing guarantees it meets WCAG 2.4.13.

**Recommendation:**

```tsx
className="py-2 px-4 rounded bg-blue-600 text-white
  hover:bg-blue-700 active:bg-blue-800
  focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-700
  disabled:bg-gray-400 disabled:cursor-not-allowed"
```

**Tradeoff:** The class string gets longer. If the project has a shared `<Button>` component, use that instead.

#### 6. The output panel has no height cap, so long output could push the Run button out of view

**Severity:** Minor
**Location:** `subject.tsx:15-17`
**Issue type:** Overflow
**Viewport:** 320–768px and 1366×768 most affected
**Move:** Step 2 items 1–2: unbounded content and controls pushed away
**Confidence:** Low

Right now the panel holds static placeholder text, so nothing breaks today. But it's labeled as the place where task output appears, and the primary button sits below it with no height limit on the panel. Once real output (logs, results) is rendered there, the button will be pushed below the fold. Under this checklist, that becomes Critical once output is real. I rated it Low confidence only because the content isn't dynamic yet.

**Recommendation:** Cap the panel's height, let it scroll, and keep the button outside the scroll region (it already is).

```tsx
<div className="border p-4 rounded max-h-[50vh] overflow-y-auto" tabIndex={0} aria-label="Task output">
```

`tabIndex={0}` lets keyboard users focus the scroll region to scroll it.

#### 7. The status never reaches `"done"`, so the button stays on "Running..." forever

**Severity:** Informational
**Location:** `subject.tsx:21`
**Issue type:** Other
**Viewport:** all
**Move:** Step 2 item 8 (state coverage)
**Confidence:** High

The only state update in the file is `setStatus("running")`. No code ever sets the status to `"done"`, so the branches at lines 19 and 27 never run. The file's comments describe what would happen once completion is wired up. As the code stands, users see a permanent "Running..." with no way to finish or cancel. This is a logic gap rather than a layout bug, but it decides which UI states users can actually see.

**Recommendation:** Wire up completion (and ideally an error state), for example `const run = async () => { setStatus("running"); await doTask(); setStatus("done"); };`.

#### 8. The button is missing `type="button"`

**Severity:** Informational
**Location:** `subject.tsx:20`
**Issue type:** Other
**Viewport:** all
**Move:** Step 2 item 8
**Confidence:** Medium

If this component is ever placed inside a `<form>`, a button with no `type` defaults to submitting the form. Adding `type="button"` prevents that.

**Recommendation:** Add `type="button"` (already included in the fixes above).

## What Looks Good

- The button sits **outside** the output container, so it isn't stuck inside a scroll region (item 2 passes as structured).
- The touch target is about 40px tall (`py-2` plus a 24px line height) and wider than its label, well above the WCAG 2.5.8 AA minimum of 24×24.
- It's a real `<button>`, so it's focusable and works with Enter and Space without extra code.
- `p-4` and `space-y-4` are compact; there's no excessive vertical spacing (item 5 passes).
- No fixed widths: the layout reflows at 320px (item 7 passes).
- The output panel has a visible border, so it's clearly separated from the surrounding content.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Update the label instead of removing the control | Skill item 6; WCAG 2.4.3 | "Run" → "Running…" → "Re-run Task" on one persistent button |
| Status messages are programmatically determinable | WCAG 4.1.3 | Always-present `role="status"` region |
| Text contrast ≥ 4.5:1 | WCAG 1.4.3 | `blue-500` → `blue-600`, `green-600` → `green-700` |
| Visible, sufficient focus indicator | WCAG 2.4.7 / 2.4.13 | Explicit `focus-visible:outline` ring |
| Visibly disabled while busy | Affordance Principle 5; ARIA | `disabled`, `aria-busy`, `disabled:bg-gray-400` |
| Cap unbounded content | Skill item 1 | `max-h-[50vh] overflow-y-auto` on the output panel |

## Keyboard Navigation

**Focus order.** The in-scope focusable elements, in tab order:
1. `<button>` at `subject.tsx:20`, reachable in the idle and running states.

There's no mismatch between DOM order and visual order (no `order`, `row-reverse` or absolute positioning). However, once the status becomes `"done"`, the button is removed and **the component has no focusable elements left**. A user who had focus on the button is sent back to `<body>` (Finding 1). The fix for Finding 1 resolves this. If the output panel becomes scrollable (Finding 6), it should join the tab order after the heading and before the button.

**Escape-key behavior.** N/A: there are no modals or overlays in this file.

**Skip-link presence.** N/A: the file doesn't change page-level structure. The `<h3>` assumes a parent that supplies `h1`/`h2`; check the heading hierarchy wherever the component is used.

**Focus-trap risks.** No focus-trap risks found. The actual risk is the opposite: focus is *lost* when the button unmounts (Finding 1).

## Viewport Verification Checklist

- [x] 360px mobile: content reachable, no horizontal overflow, touch targets adequate (about 40px tall)
- [ ] 1366×768 laptop: the action button is visible today, but it isn't protected against output growth (Finding 6)
- [x] 1920×1080 desktop: the layout fills the space reasonably; there's no fixed-width whitespace issue

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Button disappears on completion; no re-run; focus lost | Major | Affordance | `subject.tsx:19-29` | High |
| 2 | No disabled or busy state while running | Major | State coverage | `subject.tsx:20-25` | High |
| 3 | White on blue-500 is about 3.7:1 (fails 1.4.3) | Major | Affordance | `subject.tsx:22` | High |
| 4 | "Complete!" not announced; green-600 is about 3.3:1 | Major | Accessibility serialization | `subject.tsx:27-29` | High |
| 5 | Missing hover, active and explicit focus styles | Minor | State coverage | `subject.tsx:22` | High |
| 6 | Output panel uncapped; can push the button off-screen | Minor | Overflow | `subject.tsx:15-17` | Low |
| 7 | Status never set to "done"; stuck on "Running..." | Informational | Other | `subject.tsx:21` | High |
| 8 | Missing `type="button"` | Informational | Other | `subject.tsx:20` | Medium |

### State matrix: `<button>` (`subject.tsx:20`)

- [x] default: `bg-blue-500 text-white rounded`; visually distinct, but contrast fails (Finding 3)
- [ ] hover: no `hover:` style
- [~] focus: browser default ring only; no explicit `focus-visible` style
- [ ] active: no `active:` style
- [ ] disabled: never disabled, even while running (Finding 2)
- [N/A] error: a button isn't a validatable control. Note there's no task-failure state at all (Finding 7).

## Overall Assessment

This is a small component with a sound structure: the button already sits outside the content area, spacing is compact, and nothing is fixed-width. All the problems can be fixed in place. The most important fix is to keep a single, always-rendered button whose label changes ("Run Task" → "Running…" (disabled) → "Re-run Task"), paired with an always-present `role="status"` line. That one change covers Findings 1, 2 and 4 and the lost-focus problem. After that, raise the contrast (`blue-600`, `green-700`), add hover, active and focus styles, and cap the output panel's height before it shows real output.
