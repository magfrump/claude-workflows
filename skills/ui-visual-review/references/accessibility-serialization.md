# Accessibility Serialization and Tab Traversal

Reference for the `ui-visual-review` skill. Load this file when the diff touches
HTML/JSX semantic structure, ARIA attributes, focusable elements, or AI-generated
content rendering.

## Activation Triggers

Run this checklist when the diff touches HTML/JSX semantic structure (headings `h1`–`h6`,
landmarks like `<nav>`/`<main>`/`<aside>`/`<header>`/`<footer>`), ARIA attributes
(`aria-label`, `aria-labelledby`, `aria-describedby`, `role`), `alt` text on images, or
any code that extracts visible content for non-visual consumers (screen readers, AI
agents, summarization pipelines, RSS/Atom serializers).

## Equivalence Check

The visible UI and the serialized accessibility tree are two views of the same content
and must agree. Check that:

- **ARIA labels reflect visible text.** A button labeled "Submit" with
  `aria-label="Cancel"` lies to screen readers and to any consumer reading the
  accessibility tree.
- **Every non-decorative image needs descriptive `alt` text.** Purely decorative images
  use `alt=""` (empty, not missing — a missing `alt` makes screen readers fall back to
  the filename).
- **Semantic structure is preserved through changes.** Don't swap `<h2>` for a styled
  `<div>`, don't drop landmark elements, and keep heading levels sequential (no jumping
  `<h2>` to `<h4>` for visual sizing).
- **Tab/focus order matches visible reading order.** See Tab traversal below.
- **Color must never be the sole signal.** Error states need icons or text; required
  fields need asterisks or "(required)"; status changes need labels — not just a red
  border, green check, or color swap.

This is a lightweight equivalence check, not a full accessibility audit; for WCAG
conformance review use a dedicated accessibility skill.

## Tab Traversal (Diff-Scoped Reachability and Order)

### Activation Trigger

Run this sub-check when the diff adds or modifies any of:

- An interactive element (buttons, links, inputs, custom widgets with `role` + handlers,
  Unity `Selectable` subclasses, etc.)
- A meaningful informative landmark or live region (`<nav>`, `<main>`, `<aside>`,
  `role="status"`, `role="alert"`, `aria-live` regions, headings used as navigation
  anchors)
- A `tabindex` attribute (any value), `contenteditable`, or an element whose
  `display`/`visibility`/`inert` state changes
- Any structural change that reorders siblings of focusable elements (insertion,
  removal, `flex-direction: row-reverse`, `order`, absolute positioning shifts) — these
  affect tab order even if the focusables themselves weren't edited

### Scope

Diff-scoped: verify reachability and order for elements the diff *adds or modifies*,
plus any sibling focusables whose tab position would shift as a consequence. Do not
enumerate the entire page. Cross-references: focus *styling* (what focus looks like when
it lands) belongs to the state matrix in the main SKILL — do not re-verify it here.

### What to Verify

- Every meaningful interactive element in scope is reachable by `Tab` (and
  reverse-reachable by `Shift+Tab`). Custom widgets built on non-focusable elements
  (e.g., `<div role="button">`) need `tabindex="0"` and keyboard handlers for
  `Enter`/`Space` (or `role`-appropriate keys). (WCAG 2.1.1 Keyboard.)
- Tab order matches visible reading order. Flex `order`, `flex-direction: row-reverse`,
  CSS grid placement, and absolute positioning can desynchronize DOM order from visual
  order; verify by reasoning about the DOM sequence against the rendered layout.
  (WCAG 2.4.3 Focus Order.)
- No positive `tabindex` values (`tabindex="1"`, `tabindex="2"`, …). Positive tabindex
  overrides DOM order and is an anti-pattern. Allowed values: `0` (focusable in DOM
  order) and `-1` (programmatically focusable, skipped by Tab).
- No keyboard traps. Modals, dropdowns, and overlays must allow focus to leave —
  typically via `Escape`, a visible close control, or focus-trap logic that releases on
  dismiss. (WCAG 2.1.2 No Keyboard Trap.)
- Hidden focusables: elements removed visually via `display: none`, `visibility: hidden`,
  or `inert` should also leave the tab order. Off-screen-but-visible elements (e.g.,
  `left: -9999px`, `transform: translateX(-100%)`) remain focusable unless `inert` or
  `tabindex="-1"` is set — flag these unless the off-screen position is intentional
  (e.g., a skip-link revealed on focus).
- Informative landmarks and live regions are exposed even though they may not be in the
  tab path: confirm they have appropriate `role` / `aria-label` / heading structure so
  assistive tech can reach them via landmark navigation.

### Output Format

Produce one ordered list per touched component, with elements listed in their actual tab
order. Each row carries: tab index, element reference, file:line, and a brief
reachability note (✓ for reachable in expected position, or a specific problem). Include
unreachable-but-should-be elements at the end of the list under an "Unreachable"
sub-heading so they are not silently dropped.

```
### Tab order — <ComponentName> (src/components/ComponentName.tsx)

1. <button>Open menu</button> — src/components/ComponentName.tsx:18 — ✓
2. <input name="search"> — src/components/ComponentName.tsx:24 — ✓
3. <a href="/help"> — src/components/ComponentName.tsx:31 — ✓ (verify visual order:
   appears after Submit visually due to `flex-direction: row-reverse` — DOM order is
   correct, but visible order disagrees — flag as WCAG 2.4.3 violation)
4. <button>Submit</button> — src/components/ComponentName.tsx:29 — ✓

Unreachable:
- <div role="button" onClick={…}>Edit</div> — src/components/ComponentName.tsx:42 —
  missing `tabindex="0"` and key handler; not reachable by keyboard
- <SettingsPanel> trigger — src/components/ComponentName.tsx:55 — focus trap on open
  (no Escape handler, no close button receives focus)

Informative landmarks (not in tab path, verified exposed):
- <nav aria-label="Primary"> — src/components/ComponentName.tsx:12 — ✓
- <div role="status" aria-live="polite"> — src/components/ComponentName.tsx:60 — ✓
```

For non-web frameworks, adapt the format: Unity uses `Selectable.navigation` and
explicit `Navigation.Mode` values — list selectables in their `Navigation.selectOnDown` /
`selectOnRight` chain order; SwiftUI uses `.focusable()` and `@FocusState` — list
focusable views in their declared order within the focus scope.

### Common Failure Modes

- **Custom `<div>` / `<span>` widgets without `tabindex`.** Looks interactive (has
  `onClick`, has hover state), but `Tab` skips it entirely. Fix: use a real `<button>`,
  or add `tabindex="0"` plus `role` plus `Enter`/`Space` key handlers.
- **Positive `tabindex` overriding DOM order.** Encountered in legacy form code;
  invariably produces a tab path that's inconsistent with the rendered order and doubly
  broken once new fields are added.
- **Visually-reordered focusables.** `flex-direction: row-reverse`, `order: -1`, or
  absolute positioning rearranges what the user sees but leaves DOM order — and
  therefore tab order — unchanged. The user tabs to what looks like the second control
  and lands on the third.
- **Modal without focus management.** Modal opens but focus stays behind it; or modal
  traps focus with no `Escape` handler and no focusable close button.
- **Off-screen-but-focusable.** A drawer or panel hidden via `translateX(-100%)` remains
  in the tab path; pressing `Tab` lands on an invisible button. Use `inert` on the
  hidden container or set `tabindex="-1"` on every focusable inside it.
- **Disabled control still in tab order.** `aria-disabled="true"` does not remove an
  element from the tab path; only the real `disabled` attribute or `tabindex="-1"` does.
- **Tab order changed by a structural edit without re-checking siblings.** Inserting a
  new button between two existing controls silently re-routes the keyboard path — flag
  this and walk the order even when the surrounding siblings weren't otherwise modified.

## Epistemic Transparency for AI-Generated Content

When the diff renders LLM/AI-generated content alongside human-authored content, the AI
section must carry a *persistent, legible* signal of its origin — a visible text label
("AI-generated", "Generated by AI", "AI"), an icon paired with an accessible name
(visible caption or `aria-label`), or a labelled frame/badge that remains rendered
without user interaction.

The following do **not** satisfy this requirement: hover-only tooltips, `title`
attributes, fine print well below the content, and color-only differentiation (which
also fails WCAG 1.4.1). Tooltips and `title` are invisible on touch, inconsistent across
assistive tech, and easy to miss in passing; fine print and color-only signals fail for
low-vision and colorblind users.

### Activation Trigger

Run this check **only** when the diff contains explicit markers that the rendered
content is LLM output. The skill flags missing labels on content the diff itself tags as
AI — it does **not** read arbitrary prose and classify it as AI vs. human (that
determination is the author's responsibility, not the reviewer's). Triggering markers
include:

- Component, element, or class names: `AIResponse`, `AIMessage`, `AssistantMessage`,
  `GeneratedContent`, `LLMOutput`, `ModelResponse`, `Completion`, `AIGenerated`,
  `GeneratedText`, or similar
- Props, state, or template variables: `aiGenerated`, `isAI`, `fromAI`, `aiContent`,
  `llmResponse`, `generated`, `modelResponse`, or a discriminator like
  `role === "assistant"` / `author === "ai"`
- LLM SDK imports adjacent to render code: `@ai-sdk/*`, `@anthropic-ai/sdk`, `openai`,
  `useChat`, `useCompletion`, or framework-specific equivalents

### Severity

When AI content renders adjacent to human-authored content (mixed conversation,
human-edited drafts annotated with AI suggestions, search results blending human and AI
summaries), missing label is **Critical** — the user cannot tell which content carries
which provenance. When the surface renders only AI content with no adjacent
human-authored content (a standalone chat-only view), missing label is **Major**: still
recommended for informed use, but the immediate confusion risk is lower.
