# UI Visual Review — Evaluation Criteria

Test fixtures derived from real bugs in `aisc_lct/docs/UI_LAYOUT_GUIDELINES.md`.

## Fixture → Expected Finding Map

| Fixture | Bug Pattern | Expected Severity | Must Mention |
|---|---|---|---|
| tc-uv1-unbounded-list.tsx | Unbounded content without scroll cap | Critical | `max-h-*`, `overflow-auto` |
| tc-uv2-trapped-controls.tsx | Controls inside scroll container | Critical | button outside scroll, docked footer pattern |
| tc-uv3-wrong-positioning.tsx | Absolute positioning wrong parent | Major | `relative` ancestor, positioning ancestry |
| tc-uv4-flex-sizing-error.tsx | shrink-0 on content area | Major | `flex-1 min-h-0`, content vs. fixed sizing |
| tc-uv5-hidden-overflow.tsx | overflow-hidden clips content | Major | `overflow-auto`, silent clipping |
| tc-uv6-disappearing-controls.tsx | Button disappears on completion | Major | label update, conditional rendering |
| tc-uv7-weak-affordance.tsx | Interactive element looks like text | Major | border/background, WCAG 2.5.8 or NNGroup |
| tc-uv8-unity-layout.cs | Unity fixed sizing + trapped button | Critical | resolution independence, ScrollRect content |

## How to Use

1. Run the skill on one or more fixtures
2. Check that the report identifies the expected bug pattern
3. Check that the suggested fix addresses the right concern
4. Use `ui-visual-review-format.bats` to validate report structure

## Notes

- tc-uv8 tests cross-framework applicability (Unity/C#, not web)
- tc-uv6 and tc-uv7 expect Major, not Minor: SKILL.md's severity guidelines put
  "affordance is weak" and "hard to discover or use" at Major, and Minor is for
  cosmetic issues that work. Both fresh runs of each on 2026-11-20 gave Major
  (docs/working/research-2026-11-20-skill-verdict-drift.md).
- tc-uv1 and tc-uv2 expect Critical because SKILL.md's Critical tier covers a
  primary action that content growth pushes out of view at common viewport
  sizes, which is what both fixtures plant.
- Fixtures are deliberately simple — one bug per file for clear signal
- Real-world bugs often combine multiple patterns (e.g., unbounded list + trapped controls)
