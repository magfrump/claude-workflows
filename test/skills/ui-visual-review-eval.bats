#!/usr/bin/env bats
# @category fast
# @needs-reports ui-visual-review
# Evaluates ui-visual-review skill output against expected severities and the
# fix patterns each fixture's planted bug calls for.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash ui-visual-review
#
# Then run:
#   bats test/skills/ui-visual-review-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="ui-visual-review"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Checklist items 1-5: Mechanical bug-finding ---

@test "tc-uv1: unbounded list — Critical, caps height with overflow" {
  eval_fixture "$SKILL" "tc-uv1-unbounded-list.tsx"
}

@test "tc-uv2: trapped controls — Critical, docks the button outside the scroll" {
  eval_fixture "$SKILL" "tc-uv2-trapped-controls.tsx"
}

@test "tc-uv3: wrong positioning — Major, names the relative ancestor" {
  eval_fixture "$SKILL" "tc-uv3-wrong-positioning.tsx"
}

@test "tc-uv4: flex sizing — Major, flex-1 min-h-0 on the content area" {
  eval_fixture "$SKILL" "tc-uv4-flex-sizing-error.tsx"
}

@test "tc-uv5: hidden overflow — Major, overflow-auto instead of silent clip" {
  eval_fixture "$SKILL" "tc-uv5-hidden-overflow.tsx"
}

# --- Checklist items 6-7: Affordance / responsive ---

@test "tc-uv6: disappearing controls — Minor, relabel instead of hide" {
  eval_fixture "$SKILL" "tc-uv6-disappearing-controls.tsx"
}

@test "tc-uv7: weak affordance — Minor, border/background or WCAG/NNGroup" {
  eval_fixture "$SKILL" "tc-uv7-weak-affordance.tsx"
}

# --- Cross-framework: Unity/C# ---

@test "tc-uv8: Unity layout — Critical, resolution independence and ScrollRect" {
  eval_fixture "$SKILL" "tc-uv8-unity-layout.cs"
}
