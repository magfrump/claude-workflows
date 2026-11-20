# UI Visual Review: subject.tsx (`TwoSectionLayout`)

**Scope:** `subject.tsx` (the whole file)
**Date:** 2026-11-20
**Based on:** reading the code only. There was no code-fact-check report and no project UI guidelines file (no `docs/UI_LAYOUT_GUIDELINES.md` or other `.md` files in the repo).

## Environment

- **Files reviewed:** `subject.tsx`
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet/laptop), 1920px+ (desktop)
- **Target browsers / platforms:** current evergreen browsers and mobile Safari. I assumed Tailwind CSS with Preflight.
- **Review mode:** Full audit (checklist items 1–8, plus 10 and 11 because their content is present)

## Findings

#### 1. The floating action bar is anchored to the outer wrapper, so it sits on top of Section B

**Severity:** Major
**Location:** `subject.tsx:33-38`
**Issue type:** Positioning / Occlusion / z-order
**Viewport:** all; worst at 320–480px
**Move:** Step 2 item 4 (absolute element anchored to the wrong parent); Step 2 item 11 (unintended occlusion)
**Confidence:** High

The bar is `absolute bottom-6 right-6`. Its nearest positioned ancestor is the outer `<div className="relative">`, which wraps both sections. So it gets placed 24px from the bottom-right corner of the combined block, which is inside **Section B**. Section B is short: about 84px tall (`p-4` padding plus an `h3` and a `p`). The bar is about 40px tall and starts 24px above the bottom, so it covers the vertical band where Section B's text sits. Absolute elements are taken out of normal layout, so Section B reserves no space for it. At 320px the content area is about 288px wide. The bar (about 120px plus a 24px inset) and the line "Content for section B" (about 165px) are likely to collide, with the white bar painted over the text.

The code shows the bar was meant for Section A. `SectionA` accepts and renders `children` (`subject.tsx:10,15`), but nothing is ever passed in, so that slot looks like where the bar should go. The comment at `:31-32` says the same thing, and the code structure backs it up. This breaks the containing-block rule for absolute positioning (MDN, *Containing block*). If the bar covers content the user needs, it also runs against WCAG 1.4.10 Reflow.

**Recommendation:** Make Section A the containing block, render the bar through its `children` slot, and add bottom padding to Section A so the bar can't cover its own content.

```tsx
// Before
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

// After
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
        <div className="absolute bottom-4 right-4 bg-white shadow-lg rounded">
          <QuickActionButton />
        </div>
      </SectionA>
      <SectionB />
    </div>
  );
}
```

**Tradeoff:** `pb-16` adds about 48px of height to Section A. If space is tight, a simpler option is to drop absolute positioning and put the button in normal flow (`<div className="mt-3 flex justify-end">`). Then no overlap is possible at any width.

#### 2. The "Quick Action" button has no hover, active or focus styling, and its clickable area is smaller than its visible box

**Severity:** Major
**Location:** `subject.tsx:36-37`
**Issue type:** State coverage / Affordance
**Viewport:** all; touch target matters most on 320–768px touch devices
**Move:** Step 2 item 8 (state matrix); Step 2 item 6 (affordance and target size)
**Confidence:** Medium. How the button looks by default depends on the Tailwind Preflight version (v3 sets `cursor: pointer` on buttons, v4 does not).

The button has no classes. Preflight removes the native button background and border, so the only visual cue is the wrapper's white, shadowed box. The padding (`p-2`) is on the wrapper, not the button. The visible chip is about 40px tall, but the area that responds to clicks and taps is only the text line, about 24px tall. That barely meets WCAG 2.5.8 (24×24px, Level AA) and is well short of 2.5.5 (44×44px, AAA). Taps on the chip's padding do nothing, which feels broken. Nothing changes on hover or press, and the focus indicator is just the browser default, partly hidden by the wrapper's shadow.

```
- [ ] <button>Quick Action</button> (subject.tsx:37)
  - [~] default — wrapper `bg-white shadow-lg rounded` gives a chip look; the button itself has no styling
  - [ ] hover — no hover style; cursor depends on the Preflight version
  - [ ] focus — no `focus-visible` style; only the browser default outline
  - [ ] active — no `active:` style, so presses give no visual feedback
  - [N/A] disabled — no disabled state in this code
  - [N/A] error — buttons can't be invalid
```

**Recommendation:** Put the padding and all the state styles on the button itself.

```tsx
// Before
<div className="absolute bottom-6 right-6 bg-white shadow-lg p-2 rounded">
  <button>Quick Action</button>
</div>

// After
<div className="absolute bottom-4 right-4 shadow-lg rounded">
  <button
    type="button"
    className="min-h-[44px] px-3 py-2 rounded bg-white border border-gray-300
               cursor-pointer hover:bg-gray-100 active:bg-gray-200
               focus-visible:outline focus-visible:outline-2
               focus-visible:outline-offset-2 focus-visible:outline-blue-600"
  >
    Quick Action
  </button>
</div>
```

**Tradeoff:** The 44px minimum height makes the chip a little taller. You could drop to `min-h-[24px]` if AA is the only target, but 44px is the better choice for touch.

#### 3. The floating bar's place in the tab order doesn't match the section it belongs to

**Severity:** Minor
**Location:** `subject.tsx:34-37`
**Issue type:** Focus
**Viewport:** all
**Move:** Step 2 item 10 (tab traversal)
**Confidence:** Medium

The bar comes after `<SectionB />` in the DOM, so keyboard and screen-reader users reach Section A's action only after reading all of Section B. The visual position (bottom-right of Section B) matches the DOM order, so this isn't strictly a WCAG 2.4.3 failure. But if the action belongs to Section A, the connection between them is lost. The fix for Finding 1 also fixes this, because the bar moves inside Section A in the DOM.

**Recommendation:** Covered by the fix for Finding 1.

#### 4. `<button>` has no `type`, and headings start at `h3`

**Severity:** Informational
**Location:** `subject.tsx:13,23,37`
**Issue type:** Accessibility serialization
**Viewport:** all
**Move:** Step 2 item 10
**Confidence:** Low. Both points depend on where the component is used.

- If this component is ever rendered inside a `<form>`, a button with no `type` defaults to `type="submit"` and will submit the form. Adding `type="button"` prevents that.
- The section headings are `<h3>`. That's only correct if the parent page provides `h1` and `h2` above them. Otherwise screen-reader users see a skipped heading level. Check this where the component is used.

## What Looks Good

- Spacing is compact (`p-4`) with no wasted vertical space (item 5).
- No fixed widths or heights, so text wraps freely at every width (item 7).
- No content that can grow without limit and no `overflow: hidden` clipping (item 1).
- No controls trapped inside scroll containers (item 2), and no `flex` sizing to get wrong (item 3).
- `SectionA` already has a `children` slot, so the main fix needs no API change.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Absolute elements are positioned against their nearest positioned ancestor | MDN, *Containing block* | Moved `relative` to Section A and rendered the bar inside it |
| Content must not be covered at narrow widths | WCAG 1.4.10 Reflow | Added `pb-16` space for the bar, or the alternative of keeping it in normal flow |
| Minimum target size | WCAG 2.5.8 (AA, 24px), 2.5.5 (AAA, 44px) | Moved padding onto the `<button>` and added `min-h-[44px]` |
| Visible focus indicator | WCAG 2.4.7, 2.4.13 | Added an offset `focus-visible:outline` |
| Clear interactive states | NNGroup, *Flat UI and weak signifiers* | Added `hover:` and `active:` states and a border |
| Meaningful order | WCAG 1.3.2, 2.4.3 | The bar now sits in Section A in the DOM |

## Keyboard Navigation

**Focus order.** There is one focusable element. Current order: (1) `<button>Quick Action</button>` at `subject.tsx:37`. It's reached after all of Section B's content and sits visually over Section B. Visual and DOM order agree, but the button is grouped with the wrong section (Finding 3). After the fix it will sit in Section A's DOM and in Section A's bottom-right corner, so everything matches.

**Escape-key behavior.** N/A: no modals or overlays in this diff. The floating bar is always visible and doesn't manage focus.

**Skip-link presence.** N/A: the diff doesn't change page-level structure (no landmarks added).

**Focus-trap risks.** None found.

## Viewport Verification Checklist

- [ ] 360px mobile: **currently fails.** The bar likely covers "Content for section B", and the tap area is about 24px tall. Both pass after Findings 1 and 2 are fixed.
- [x] 1366×768 (common laptop): the action button is visible without scrolling. It still covers part of Section B's text line until Finding 1 is fixed.
- [x] 1920×1080 (standard desktop): no excess whitespace. Overlap is less likely with the wider line, but the bar is still attached to the wrong section.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Floating bar anchored to the outer wrapper, covers Section B | Major | Positioning / Occlusion | `subject.tsx:33-38` | High |
| 2 | Button has no hover/active/focus styles; tap area smaller than visible chip | Major | State coverage / Affordance | `subject.tsx:36-37` | Medium |
| 3 | Tab order puts Section A's action after Section B | Minor | Focus | `subject.tsx:34-37` | Medium |
| 4 | No `type="button"`; headings may skip a level | Informational | Accessibility serialization | `subject.tsx:13,23,37` | Low |

## Overall Assessment

The layout is simple and mostly sound. The one structural mistake is that `relative` is on the outer wrapper instead of on `SectionA`. That makes the Quick Action bar sit over Section B instead of its own section, and it covers Section B's text on narrow screens. Every issue here can be fixed without restructuring: move `relative` (and the bar) into Section A's existing `children` slot, add bottom padding so the bar can't cover Section A's content, and put the padding and state styles on the `<button>` so its tap area and feedback match its look. Fix the anchoring first, since that also fixes the tab-order mismatch.
