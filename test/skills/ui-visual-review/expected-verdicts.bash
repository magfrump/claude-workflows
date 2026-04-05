#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for ui-visual-review evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# Unlike fact-check skills which produce verdicts per claim, ui-visual-review
# produces severity-grouped findings per file. The "verdict" here is the expected
# severity tier, and KEY_CHECK patterns verify the fix recommendation.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Checklist items 1-5: Mechanical bug-finding ---

EXPECTED_VERDICT["tc-uv1-unbounded-list.tsx"]="Critical"
CLAIM_ACCURACY["tc-uv1-unbounded-list.tsx"]="bug"  # Unbounded list without scroll cap
KEY_CHECK["tc-uv1-unbounded-list.tsx"]="verdict_match;;cites_pattern:max-h|overflow.auto"

EXPECTED_VERDICT["tc-uv2-trapped-controls.tsx"]="Critical"
CLAIM_ACCURACY["tc-uv2-trapped-controls.tsx"]="bug"  # Submit button trapped inside scroll container
KEY_CHECK["tc-uv2-trapped-controls.tsx"]="verdict_match;;cites_pattern:docked|footer|outside.scroll"

EXPECTED_VERDICT["tc-uv3-wrong-positioning.tsx"]="Major"
CLAIM_ACCURACY["tc-uv3-wrong-positioning.tsx"]="bug"  # Absolute positioning anchored to wrong parent
KEY_CHECK["tc-uv3-wrong-positioning.tsx"]="verdict_match;;cites_pattern:relative|ancestor|position"

EXPECTED_VERDICT["tc-uv4-flex-sizing-error.tsx"]="Major"
CLAIM_ACCURACY["tc-uv4-flex-sizing-error.tsx"]="bug"  # shrink-0 on content area instead of flex-1 min-h-0
KEY_CHECK["tc-uv4-flex-sizing-error.tsx"]="verdict_match;;cites_pattern:flex-1|min-h-0|shrink"

EXPECTED_VERDICT["tc-uv5-hidden-overflow.tsx"]="Major"
CLAIM_ACCURACY["tc-uv5-hidden-overflow.tsx"]="bug"  # overflow-hidden silently clips error list
KEY_CHECK["tc-uv5-hidden-overflow.tsx"]="verdict_match;;cites_pattern:overflow.auto|clip"

# --- Checklist items 6-7: Affordance / responsive (full audit mode) ---

EXPECTED_VERDICT["tc-uv6-disappearing-controls.tsx"]="Minor"
CLAIM_ACCURACY["tc-uv6-disappearing-controls.tsx"]="bug"  # Button disappears on completion instead of relabeling
KEY_CHECK["tc-uv6-disappearing-controls.tsx"]="verdict_match;;cites_pattern:label|conditional|Re.run"

EXPECTED_VERDICT["tc-uv7-weak-affordance.tsx"]="Minor"
CLAIM_ACCURACY["tc-uv7-weak-affordance.tsx"]="bug"  # Interactive div looks like static text
KEY_CHECK["tc-uv7-weak-affordance.tsx"]="verdict_match;;cites_pattern:border|background|WCAG|NNGroup"

# --- Cross-framework: Unity/C# ---

EXPECTED_VERDICT["tc-uv8-unity-layout.cs"]="Critical"
CLAIM_ACCURACY["tc-uv8-unity-layout.cs"]="bug"  # Fixed pixel sizing + button trapped in ScrollRect content
KEY_CHECK["tc-uv8-unity-layout.cs"]="verdict_match;;cites_pattern:resolution|ScrollRect|fixed"
