# Plan: UI tab-traversal check

**Goal**: Add a diff-scoped tab-traversal check item under §9 of `skills/ui-visual-review.md`, with a specified ordered-list output format.

**Project state**: Standalone skill enhancement · not blocked.

**Task status**: in-progress (plan drafted, ready to implement)

Research: `docs/working/r1-ui-tab-traversal-check-research.md`

## Approach

Insert a new sub-section "**Tab traversal**" *under* §9 (Accessibility serialization), keeping §9's existing lead paragraph as the equivalence framing. The new sub-section follows the same structural template as items 9 and 10: an activation trigger, what to verify (with focus on reachability and order), a fenced output-format example showing an ordered list of interactive/informative elements in tab order, and common failure modes. Trim the one tab-order sentence in §9's lead paragraph to a brief pointer ("see Tab traversal below"), avoiding duplication.

## Steps

1. **Edit `skills/ui-visual-review.md`** — under §9 (Accessibility serialization):
   - Trim the one-sentence mention of tab/focus order in §9's lead paragraph and replace it with a forward pointer to the new sub-section.
   - Add a new sub-section titled **Tab traversal** containing:
     - Activation trigger: diff adds/modifies interactive elements, custom widgets with role attributes, elements with `tabindex`, or visible/informative landmarks.
     - Scope statement: diff-scoped (only elements the diff touches, plus any siblings whose order would be affected by the change).
     - What to verify: every meaningful interactive element is keyboard-reachable; tab order matches visible reading order; no positive `tabindex` values; no keyboard traps; custom widgets have `tabindex="0"` and appropriate role/key handlers; skip-link or landmark navigation present where appropriate.
     - Output format: a fenced markdown example showing an ordered list of interactive elements with tab index, element reference, file:line, and a brief reachability note. Include at least one "unreachable" example row to show what failure looks like.
     - Common failure modes: custom div-buttons without `tabindex`, positive tabindex reordering, hidden-but-focusable elements (display:none parent + tabindex), focus traps in modals without close-on-escape, off-screen elements that remain focusable.
   - Keep WCAG references (2.1.1 Keyboard, 2.1.2 No Keyboard Trap, 2.4.3 Focus Order) inline.
   - Cross-link to item 10 (state matrix) for the "what does focus look like once it lands" question, to avoid duplicating focus-styling guidance.

Size: ~50 lines added to `skills/ui-visual-review.md`. No other files touched.

## Test specification

This is a documentation/skill edit; no runnable tests. Verification is by inspection:

| Test case | Expected behavior | Level | Diagnostic expectation |
|-----------|------------------|-------|----------------------|
| New sub-section is present under §9 | `Tab traversal` heading appears between §9's lead paragraph and §10 | manual | grep for the heading string |
| Output format example is fenced and shows an ordered list with tab index, element, file:line, reachability note | rendering the markdown shows a numbered/ordered list with the four fields | manual | visual inspection |
| Existing §9 prose no longer duplicates tab-order coverage | the original "Tab/focus order must match visible reading order…" sentence is replaced by a brief pointer | manual | diff inspection |
| No other files modified | only `skills/ui-visual-review.md` and `docs/working/*` changed | manual | `git status` clean except for those paths |

## Risks

- **Over-scoping**: the temptation is to expand into full keyboard-accessibility review (escape keys, arrow-key navigation patterns for composite widgets, roving tabindex). The check must stay narrow: reachability + order, with the output being the ordered list. Composite-widget keyboard patterns are noted briefly in failure modes, not turned into their own checklist.
- **Duplication with item 10**: state matrix already covers focus *styling*. The new check covers focus *reachability and order*. Keep the cross-link explicit to prevent reviewers from running both and producing overlapping reports.
- **Diff-scope drift**: the check has to verify siblings whose order is *affected by* the diff (e.g., inserting a new button between two existing ones changes the tab path), not just elements literally changed. State this explicitly in the scope wording.
