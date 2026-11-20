# UI Visual Review: subject.tsx (`FormPanel`)

**Scope:** `subject.tsx` (whole file)
**Date:** 2026-11-20
**Based on:** code analysis only. No code-fact-check report was provided.

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet / small laptop), 1366×768 (common laptop), 1920px+ (desktop)
- **Target browsers / platforms:** current evergreen browsers plus mobile Safari (default; none was specified)
- **Review mode:** Full audit
- **Project guidelines:** none found (no `docs/UI_LAYOUT_GUIDELINES.md` or other `docs/**/*.md`)

## Findings

#### 1. Submit button is inside the scroll container and scrolls out of view

**Severity:** Major
**Location:** `subject.tsx:13-24`
**Issue type:** Positioning
**Viewport:** Any viewport where the content is taller than the panel. That's very likely at 1366×768 and below, and it depends on `children` at 1920×1080.
**Move:** Step 2 item 2 (controls trapped inside scroll containers)
**Confidence:** High

The `<button>` is a child of the `overflow-auto h-full` div, so it sits at the bottom of the scrolling content. Without any `children`, the content is already about 750px tall: 48px of padding, a 28px heading, a 32px top margin, three 8-row textareas (about 210px each) with gaps, a 16px margin and a 48px button. Any `children` make it taller. So the button is below the bottom edge of the panel on most laptop and mobile screens. Users can still reach it by scrolling, so it isn't completely inaccessible. But the main action is hidden until they scroll, and nothing on screen shows that it exists. Pinning the main action in a docked footer is the standard fix.

On severity: the file's header comment (line 5) expects this to be **Critical**. I rated it **Major** because, by this skill's definitions, Critical means the user can't reach the content or finish the task. Here they can, by scrolling. If the panel is embedded where scrolling is hard to notice (for example, scrollbars hidden by the OS on macOS or touch devices), raising it to Critical is defensible.

**Recommendation:** Split the panel into a scrolling body and a fixed footer.

```tsx
// Before
<div className="h-full">
  <div className="overflow-auto h-full p-6">
    …
    <button className="mt-4 …">Submit</button>
  </div>
</div>

// After
<div className="flex h-full min-h-0 flex-col overflow-hidden">
  <div className="flex-1 min-h-0 overflow-y-auto p-4">
    <h2 className="text-lg font-bold">Form</h2>
    {children}
    <div className="mt-6 space-y-3">{/* textareas */}</div>
  </div>
  <div className="shrink-0 border-t px-4 py-3">
    <button type="submit" className="…">Submit</button>
  </div>
</div>
```

**Tradeoff:** The footer takes about 70px of permanent vertical space, which leaves less room for the scrolling area on short screens.

---

#### 2. Textareas have no accessible name

**Severity:** Major
**Location:** `subject.tsx:17-19`
**Issue type:** Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 10 (accessibility serialization)
**Confidence:** High

None of the three `<textarea>`s has a `<label>`, `aria-label`, `aria-labelledby` or even a `placeholder`. Screen readers announce each one only as "edit text", and sighted users can't tell the three fields apart. This fails WCAG 1.3.1 (Info and Relationships), 3.3.2 (Labels or Instructions) and 4.1.2 (Name, Role, Value).

**Recommendation:** Give each field a visible label linked to it.

```tsx
<label htmlFor="field-1" className="block text-sm font-medium">Field 1</label>
<textarea id="field-1" className="w-full border p-2" rows={4} />
```

---

#### 3. Submit button handles only the default state (no hover, focus, active or disabled styling)

**Severity:** Minor
**Location:** `subject.tsx:21`
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 8 (interactive element state matrix); Step 2 item 6
**Confidence:** High

The button has only base styles. Hovering and pressing it give no visual feedback. Keyboard focus falls back to the browser's default outline, which still shows (Tailwind's preflight doesn't remove it), but it can have weak contrast against `bg-blue-600`. There's no disabled styling, so if a disabled state is added later it won't look different. See the state matrix below.

**Recommendation:**
```tsx
<button
  type="submit"
  className="py-3 px-6 rounded font-semibold text-white bg-blue-600
             hover:bg-blue-700 active:bg-blue-800
             focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600
             disabled:opacity-50 disabled:cursor-not-allowed"
>
  Submit
</button>
```

---

#### 4. Textareas have no explicit focus or error state

**Severity:** Minor
**Location:** `subject.tsx:17-19`
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 8
**Confidence:** Medium

The fields rely on the browser's default focus outline, and their gray `border` is light. If the default border color contrasts with the background at less than 3:1, it fails WCAG 1.4.11 (Non-text Contrast). There's also no error-state wiring (`aria-invalid` or `aria-describedby`) in case these fields get validation.

**Recommendation:** Add `focus-visible:ring-2 focus-visible:ring-blue-600` and a border color with enough contrast (for example `border-gray-500`). If you add validation, show errors with a border, an icon, and text linked through `aria-describedby`, not with color alone.

---

#### 5. Too much vertical space pushes content below the fold

**Severity:** Minor
**Location:** `subject.tsx:13, 16-19`
**Issue type:** Sizing
**Viewport:** 320px–1366×768
**Move:** Step 2 item 5 (excessive vertical spacing)
**Confidence:** High

Three textareas at `rows={8}`, plus `p-6`, `mt-8` and `space-y-4`, use about 750px before any `children` are added. At 1366×768 (less the browser chrome, so about 650px of usable height) the form doesn't fit. At 320–480px the user has to scroll a long way through mostly empty fields.

**Recommendation:** Use `rows={3}` or `rows={4}` and rely on the browser's default vertical resize so users can make fields bigger. Use `p-4`, `mt-6` and `space-y-3`. The first three fields then fit in about 450px.

---

#### 6. The `h-full` chain needs a parent with a set height, or the panel won't scroll

**Severity:** Informational
**Location:** `subject.tsx:11, 13`
**Issue type:** Sizing
**Viewport:** all
**Move:** Step 2 item 3 (`shrink-0` vs `flex-1 min-h-0`)
**Confidence:** Medium

A percentage height (`h-full`) only works if the parent has a definite height. If whatever renders `FormPanel` doesn't set one, both divs grow to fit their content, `overflow-auto` never kicks in, and the whole page scrolls instead. That isn't broken in itself, but it means the panel's own scroll design silently does nothing. I can't check this from this file alone.

**Recommendation:** Document the requirement (for example, "must be rendered inside a flex column with `min-h-0` or a fixed height"), or use the `flex-1 min-h-0` pattern from finding 1 inside a flex parent.

---

#### 7. Button has no `type` and isn't connected to any form or handler

**Severity:** Informational
**Location:** `subject.tsx:21`
**Issue type:** Other
**Viewport:** all
**Move:** Step 2 item 6 (affordance)
**Confidence:** High

There's no `<form>` element and no `onClick`, so "Submit" looks like a working control but does nothing. A user who clicks it gets no feedback. This may just be a stub.

**Recommendation:** Wrap the fields in `<form onSubmit={…}>` and set `type="submit"`. Also show a loading or success status through a live region (WCAG 4.1.3).

## Interactive Element State Matrix

- [ ] `<button>` Submit (`subject.tsx:21`)
  - [x] default: `bg-blue-600 text-white rounded` gives a clear filled-button look ✓
  - [ ] hover: no `hover:` style
  - [ ] focus: only the browser default outline; no `focus-visible` style that's guaranteed to have enough contrast
  - [ ] active: no `active:` style
  - [ ] disabled: no `disabled:` style
  - [N/A] error: a button isn't a field that can be validated
- [ ] `<textarea>` ×3 (`subject.tsx:17-19`)
  - [x] default: `border` makes the fields distinct from the text around them ✓ (border contrast unverified)
  - [N/A] hover: no hover change is expected for text fields; the browser shows the text cursor
  - [ ] focus: only the browser default outline
  - [N/A] active: not meaningful for text fields
  - [ ] disabled: no style, though the fields are never disabled today
  - [ ] error: no `aria-invalid` or `aria-describedby` wiring

## What Looks Good

- The textareas use `w-full` with `p-2` and `border`. Tailwind's preflight sets `box-sizing: border-box`, so they don't overflow sideways at 320px.
- The button's touch target (`py-3 px-6`, about 48px tall) is above both WCAG 2.5.8 (24px, AA) and 2.5.5 (44px, AAA).
- `overflow-auto` was used, not `overflow-hidden`, so long content can be scrolled to rather than silently cut off.
- The source order (heading, `children`, fields, button) matches the visual order, so keyboard order and reading order agree.
- There are no fixed pixel widths, so the layout reflows down to 320px (WCAG 1.4.10).

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Keep the main action reachable without scrolling | NNGroup (visibility of the main action); skill item 2 | Moved the button into a `shrink-0` docked footer |
| Fill space vs. size to content | CSS Flexbox (MDN) | Body `flex-1 min-h-0 overflow-y-auto`, footer `shrink-0` |
| Fields have accessible names | WCAG 1.3.1, 3.3.2, 4.1.2 | Added a `<label htmlFor>` to each textarea |
| Visible focus indicator | WCAG 2.4.7, 2.4.13 | Added `focus-visible` outline/ring styles |
| Non-text contrast for field borders | WCAG 1.4.11 | Recommended `border-gray-500` or darker |
| Compact spacing for short screens | Skill item 5 | `rows` 8→3–4, `p-6`→`p-4`, `mt-8`→`mt-6` |
| Status messages are announced | WCAG 4.1.3 | Recommended a live region for the submit result |

## Keyboard Navigation

**Focus order.** These are the elements that receive focus, in tab order:
1. Any focusable elements inside `{children}` (`subject.tsx:15`). The order depends on what the caller passes in.
2. `<textarea>` 1 (`subject.tsx:17`)
3. `<textarea>` 2 (`subject.tsx:18`)
4. `<textarea>` 3 (`subject.tsx:19`)
5. `<button>` Submit (`subject.tsx:21`)

The source order matches the visual order. There's no `order`, `row-reverse` or absolute positioning, so WCAG 2.4.3 is met. When focus reaches the button, the browser scrolls it into view inside the container. After the finding 1 fix, the button sits in the footer and stays last in both source and visual order.

**Escape-key behavior.** N/A: this diff has no modals or overlays.

**Skip-link presence.** N/A: the diff doesn't change the page-level structure. (`<h2>` isn't a landmark.)

**Focus-trap risks.** None found. Nothing is hidden off-screen while still focusable, and there's no focus-managing region.

## Viewport Verification Checklist

- [ ] **360px mobile:** no sideways overflow ✓. The button is about 800px or more down the content, so heavy scrolling is needed (findings 1 and 5). The touch target is fine ✓.
- [ ] **1366×768 laptop:** the Submit button isn't visible without scrolling (finding 1).
- [x] **1920×1080 desktop:** with small `children` the form probably fits, although large `children` would push the button off screen again. The panel fills its parent's width without odd spacing ✓.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Submit button inside the scroll container | Major | Positioning | `subject.tsx:13-24` | High |
| 2 | Textareas have no accessible name | Major | Accessibility serialization | `subject.tsx:17-19` | High |
| 3 | Button handles only the default state | Minor | State coverage | `subject.tsx:21` | High |
| 4 | Textareas have no explicit focus or error state | Minor | State coverage | `subject.tsx:17-19` | Medium |
| 5 | Too much vertical space | Minor | Sizing | `subject.tsx:13,16-19` | High |
| 6 | `h-full` needs a parent with a set height | Informational | Sizing | `subject.tsx:11,13` | Medium |
| 7 | Button has no `type` or handler | Informational | Other | `subject.tsx:21` | High |

## Overall Assessment

This is a small, structural problem that can be fixed in place. The panel puts its main action inside the scrolling content when it should pin it in a footer. Large textareas and generous padding make it worse, pushing Submit below the fold at common laptop and mobile sizes. The one change that matters most is the two-part layout from finding 1: a `flex-1 min-h-0 overflow-y-auto` body with a `shrink-0` footer holding the button. That fixes the reachability problem whatever `children` contains. Next, label the textareas (finding 2), which is a real accessibility failure separate from the layout. The remaining items are styling polish and documentation.
