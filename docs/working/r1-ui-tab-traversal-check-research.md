# Research: UI tab-traversal check

**Goal**: Add a diff-scoped tab-traversal check to `skills/ui-visual-review.md` so every interactive/informative element in the diff is verified reachable by keyboard tab, with an ordered tab-order listing as the output format.

**Project state**: Standalone enhancement to ui-visual-review · part of ongoing skill refinement round · not blocked.

**Task status**: in-progress (research drafted, plan next)

## What exists

`skills/ui-visual-review.md` is structured as a checklist of numbered review items inside Step 2 ("Read the Code"):

1. Unbounded content without scroll caps
2. Controls trapped inside scroll containers
3. Wrong `shrink-0` vs `flex-1 min-h-0` usage
4. Absolute positioning anchored to wrong parent
5. Excessive vertical spacing
6. Visibility and affordance (full audit mode only)
7. Responsive and cross-browser concerns (full audit mode only)
8. 3D viewport rendering
9. **Accessibility serialization** *(when HTML structure, ARIA, or content extraction changes)* — this is the "accessibility/disclosure subsection" referenced in the task
10. Interactive element state matrix (when diff touches interactive elements)

Item 9 currently bundles several concerns into one prose paragraph: ARIA-label/visible-text agreement, alt text, semantic structure (heading levels, landmarks), tab/focus order matching reading order, and color-not-sole-signal. Tab order is mentioned in a single sentence — "Tab/focus order must match visible reading order — flex `order`, `flex-direction: row-reverse`, and absolute positioning can desynchronize them; verify by tabbing through the modified component." — but there is no structured check and no specified output format.

Item 10 (the state matrix) is diff-scoped and uses a per-element checklist format (one element with rows per state). It is the closest existing pattern for what the new check needs to produce.

## Invariants

- The skill is read by both standalone invocation and the `code-review` orchestrator. New checks must be self-describing — no implicit dependencies on orchestrator state.
- Checks under items 9 and 10 are **diff-scoped** by design (verify only what the diff adds/modifies). The new check must preserve this scope so the signal stays high.
- Item 9's framing is "lightweight equivalence check, not a full accessibility audit" — the new check should fit that framing rather than expand into a WCAG conformance review.
- Markdown structure: existing items use `### N. Title` headers, *italic activation triggers*, optional `**Activation trigger.**` bold callouts, and inline tables / code blocks for output format examples. The new item should match this style.
- Per the file-scope constraint, only `skills/ui-visual-review.md` and `docs/working/*` may be modified.

## Prior art

Item 10 (Interactive element state matrix) is the closest pattern:
- Diff-scoped activation trigger
- Defines "interactive element" with concrete framework examples (HTML/JSX, Unity/C#, other frameworks)
- Provides a per-element checklist output format with a code-fenced example
- Lists common failure modes

The new tab-traversal check should follow the same structural template: scope, activation trigger, what to verify, output format example, failure modes.

The state matrix already covers the *focus* state (whether a visible focus indicator exists). Tab traversal is a complementary concern: does focus *reach* the element at all, and in what order? They overlap but don't duplicate — state matrix verifies the styling once focused; tab traversal verifies reachability and order.

WCAG references already in the file:
- 2.4.7 (focus visible) — referenced in items 6 and 10
- 2.4.11 (focus not obscured) — item header intro
- 2.4.13 (focus appearance) — items 6, 10
- 2.5.8 (target size) — items 6, 10
- 1.4.10 (reflow) — header intro

The relevant new WCAG references for tab traversal:
- **2.1.1 Keyboard** — all functionality available from a keyboard
- **2.1.2 No Keyboard Trap** — focus can move away from any component
- **2.4.3 Focus Order** — focus order preserves meaning and operability

## Gotchas

- Item 9's existing tab-order sentence should be left in place (it's part of the broader equivalence framing) or trimmed and pointed at the new check. The task says "add a Tab-Traversal check item *under* the existing accessibility/disclosure subsection" — so the new item lives inside §9, as a sub-section, with §9's lead paragraph still summarizing the equivalence concept.
- "Interactive or informative element" — informative goes slightly beyond focusable. The task wording suggests including elements that *should* be reachable for assistive tech (e.g., status messages, live regions, headings used as landmarks), not just standard focusables. The check should mention this explicitly.
- `tabindex="-1"` and `tabindex="0"` semantics: `-1` removes from tab order but keeps focusable programmatically; positive `tabindex` values (1, 2, ...) override DOM order and are an anti-pattern. The check should flag positive tabindex.
- Disabled elements correctly drop out of tab order; the check should not flag intentional disabled exclusions.
- Custom widgets (role="button" on a `<div>` without `tabindex="0"`) are a very common bug — these *look* interactive but are unreachable.
