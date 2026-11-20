# UI Visual Review — `subject.tsx` (TwoSectionLayout)

**Scope:** `subject.tsx` (single file, full audit)
**Date:** 2026-11-20
**Based on:** No code-fact-check report was provided. I checked the file's own comments against the code myself (see Note on in-file comments).

## Environment

- **Files reviewed:** `subject.tsx`
- **Project guidelines:** None found. There is no `docs/` directory and no `UI_LAYOUT_GUIDELINES.md`.
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet/laptop), 1920px+ (desktop)
- **Target browsers / platforms:** Modern evergreen browsers and mobile Safari. I assumed Tailwind CSS with its default Preflight reset.
- **Review mode:** Full audit (Step 2 items 1–8; items 9–11 checked for triggers)

## Note on in-file comments

Lines 1–6 and 31–32 say the floating bar is anchored to the outer wrapper and floats over both sections. **This is accurate.** The only element with `relative` is the outer `<div>` (line 33), so the `absolute` bar (line 36) is positioned against the whole two-section block.

One correction to line 6 ("should be inside SectionA with relative"): `SectionA` does not currently have `relative` (line 12). Moving the bar into `SectionA`'s `children` slot alone won't fix it. `SectionA` also needs `relative`.

## Findings

#### 1. Floating action bar anchored to the outer wrapper, so it sits over Section B

**Severity:** Major
**Location:** `subject.tsx:33-38` (also `subject.tsx:12`)
**Issue type:** Positioning
**Viewport:** All. The overlap is worst at 320–480px, where section text wraps and fills the full width.
**Move:** Step 2 item 4 (absolute positioning anchored to wrong parent); also item 11 (occlusion)
**Confidence:** High

`absolute bottom-6 right-6` resolves against the nearest positioned ancestor. That is the outer `relative` div wrapping both sections. So the bar lands 24px above the bottom of the whole layout, which is inside `SectionB`. It is not attached to `SectionA`, the section it belongs to.

`SectionB` is short: about 80px, made of 32px padding plus a heading and one line of text. The bar is about 40px tall and starts 24px from the bottom, so it covers the right-hand side of `SectionB`'s heading and paragraph rows. With the placeholder copy, the text may stay to the left of the bar at wide widths. With real content, or at narrow widths where text wraps across the full width, `SectionB` content will sit under the bar.

`SectionA` already accepts `children` (line 15), but nothing is passed to it. The slot was clearly meant for this bar. If `SectionB` later grows or more sections are added, the bar will keep drifting toward whichever section is last.

Under item 11's test, this counts as an unintended overlap, not deliberate layering. The bar is meant to belong to Section A, but it sits on top of Section B's content.

**Recommendation:** Make `SectionA` the positioning context and render the bar through its `children` slot. Reserve space at the bottom of `SectionA` so the bar doesn't cover Section A's own content either.

```tsx
// BEFORE
function SectionA({ children }: { children?: React.ReactNode }) {
  return (
    <div className="p-4 border-b">
      ...
      {children}
    </div>
  );
}

export function TwoSectionLayout() {
  return (
    <div className="relative">
      <SectionA />
      <SectionB />
      <div className="absolute bottom-6 right-6 bg-white shadow-lg p-2 rounded">
        <button>Quick Action</button>
      </div>
    </div>
  );
}
```

```tsx
// AFTER
function SectionA({ children }: { children?: React.ReactNode }) {
  return (
    <div className="relative p-4 pb-16 border-b">
      <h3 className="font-bold">Section A</h3>
      <p>Content for section A</p>
      {children}
    </div>
  );
}

export function TwoSectionLayout() {
  return (
    <div>
      <SectionA>
        <div className="absolute bottom-3 right-3 bg-white shadow-lg p-2 rounded">
          <button type="button">Quick Action</button>
        </div>
      </SectionA>
      <SectionB />
    </div>
  );
}
```

**Tradeoff:** `pb-16` adds 48px of extra vertical space to Section A. If the action doesn't need to float, a simpler option is to keep it in normal flow, e.g. a `flex justify-end mt-3` row at the end of Section A. That removes the overlap risk entirely and is preferred per Affordance Principle 8.

#### 2. "Quick Action" button has no styling of its own, so it reads as plain text

**Severity:** Major
**Location:** `subject.tsx:37`
**Issue type:** Affordance / State coverage
**Viewport:** All
**Move:** Step 2 item 6 (visibility and affordance) and item 8 (state matrix)
**Confidence:** High (assuming Tailwind Preflight)

Tailwind Preflight removes the browser's default button look: background is set to transparent and borders are reset. That leaves `<button>Quick Action</button>` as bare text. The wrapper's white background and shadow suggest a card, not a pressable control. There is also no hover, active or disabled styling, and no `cursor-pointer` (Preflight in Tailwind v4 uses `cursor: default` on buttons).

NNGroup's research says interactive elements with weak signifiers take more effort to find and use. WCAG 1.4.11 asks for a 3:1 contrast boundary on UI components.

The button's hit area is also just its text line box, about 24px tall, because the `p-2` padding is on the wrapper rather than the button. That meets WCAG 2.5.8 AA (24×24) with no margin to spare, and is well under the 44×44 AAA target (2.5.5) on touch devices.

**Recommendation:** Put the padding and visual treatment on the button itself, and either drop the wrapper or make it purely positional.

```tsx
<div className="absolute bottom-3 right-3">
  <button
    type="button"
    className="min-h-11 px-4 rounded border border-gray-300 bg-white shadow-lg cursor-pointer
               hover:bg-gray-50 active:bg-gray-100
               focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600
               disabled:opacity-50 disabled:cursor-not-allowed"
  >
    Quick Action
  </button>
</div>
```

**Tradeoff:** `min-h-11` (44px) makes the button visually larger than the current compact pill. That is acceptable for a floating action and recommended for touch.

#### 3. Button has no `type` and no handler

**Severity:** Informational
**Location:** `subject.tsx:37`
**Issue type:** Other
**Viewport:** All
**Move:** Step 2 item 8 (state matrix, default state)
**Confidence:** Medium

A `<button>` without a `type` defaults to `type="submit"`. If this layout is ever placed inside a `<form>`, clicking it would submit the form. The button also has no `onClick`, so right now it does nothing. That is probably expected for a fixture, but worth confirming before shipping.

**Recommendation:** Add `type="button"` and wire up the intended handler, as shown in Finding 2's fix.

### State matrix (Step 2 item 8)

- [ ] `<button>Quick Action</button>` (`subject.tsx:37`)
  - [ ] **default:** no border or background on the button; Preflight makes it look like text. The wrapper card provides only weak affordance.
  - [ ] **hover:** no `hover:` styles
  - [x] **focus:** Preflight keeps the browser's default focus outline, so it is visible (WCAG 2.4.7). It isn't customized, and the `rounded` wrapper does not clip it because the wrapper has no `overflow-hidden`.
  - [ ] **active:** no `active:` styles
  - [ ] **disabled:** no disabled styles. The element is never disabled today, so this only matters if a disabled state is added.
  - [N/A] **error:** not a validatable control

### Items with no findings

- **Item 1 (unbounded content):** content is static and short; there are no lists or growing regions.
- **Item 2 (controls in scroll containers):** there are no scroll containers.
- **Item 3 (`shrink-0` vs `flex-1`):** no flex layouts are used.
- **Item 5 (spacing):** `p-4` is compact. The bar's offset is the only spacing concern, and Finding 1 covers it.
- **Item 7 (responsive):** there are no fixed widths. Short text wraps normally. The floating bar is about 106px wide plus a 24px offset, so it fits at 320px.
- **Items 9–10:** no 3D content, no ARIA, and no AI-generated content.

## What Looks Good

- `SectionA` already has a `children` slot, which is the right extension point for a section-scoped action. The structural fix is small.
- No `overflow-hidden` is used anywhere, so nothing gets silently clipped, including the focus ring.
- No fixed pixel widths, so both sections reflow at every viewport tested.
- Headings use `<h3>` with consistent `font-bold`, so the visual and semantic hierarchy match.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Positioned elements anchor to the nearest positioned ancestor | MDN, `position: absolute` | Moved `relative` to `SectionA` and rendered the bar inside it |
| Prefer in-flow layout over overlays | Affordance Principle 8 | Suggested an in-flow action row as the simpler option |
| Interactive elements are visually distinct | NNGroup (weak signifiers); WCAG 1.4.11 | Added border, background and cursor to the button itself |
| Target size | WCAG 2.5.8 (AA), 2.5.5 (AAA) | Moved padding onto the button; `min-h-11` |
| Visible focus indicator | WCAG 2.4.7 / 2.4.13 | Explicit `focus-visible:` outline |

## Keyboard Navigation

**Focus order.** There is one focusable element.

1. `subject.tsx:37`, the "Quick Action" button, reachable by Tab.

Currently its place in the code (after `SectionB`) matches where it appears on screen (bottom-right of the block, inside Section B's area), so there is no WCAG 2.4.3 mismatch today. After the Finding 1 fix, it will come after Section A's content and before Section B, both in code and on screen. Order stays consistent.

**Escape-key behavior.** N/A — no modals or overlays in this file.

**Skip-link presence.** N/A — the file does not change page-level structure.

**Focus-trap risks.** No focus-trap risks identified.

## Viewport Verification Checklist

- [ ] **360px mobile:** content is reachable, but the bar covers Section B content (Finding 1). The touch target is at the AA minimum only (Finding 2).
- [x] **1366×768:** the action button is visible without scrolling (short layout).
- [x] **1920×1080:** the layout fills the width with no fixed-width gaps.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Floating bar anchored to outer wrapper and covers Section B | Major | Positioning | `subject.tsx:33-38` | High |
| 2 | Button has no visible affordance, hover or active states; minimal hit area | Major | Affordance / State coverage | `subject.tsx:37` | High |
| 3 | Button has no `type` or handler | Informational | Other | `subject.tsx:37` | Medium |

## Overall Assessment

The layout is simple and mostly fine. Both problems can be fixed in place; neither points to a deeper structural issue.

**Most important:** fix Finding 1. The bar is positioned against the outer wrapper, so it ends up over whichever section comes last instead of staying with Section A. Two ways to fix it:
- Add `relative` to `SectionA` and pass the bar through its existing `children` slot.
- Better: render the action as a normal in-flow row and avoid the overlap altogether.

**Second:** give the button its own visible styling and states (Finding 2), so it looks clickable once Tailwind's reset is applied.
