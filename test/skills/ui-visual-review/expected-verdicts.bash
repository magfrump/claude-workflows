#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for ui-visual-review evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# Unlike fact-check skills which produce verdicts per claim, ui-visual-review
# produces severity-grouped findings per file. The "verdict" here is the expected
# severity tier (checked by finding_match against the **Severity:** lines), and
# KEY_CHECK patterns verify the fix recommendation.
# finding_match:<tiers>=<ERE>[&&<ERE>...] needs ONE finding (a "####" block or a
# summary-table row) carrying both a tier from EXPECTED_VERDICT and a line
# matching each ERE outside lines copied from the fixture, so an unrelated
# finding with the right tier cannot pass (2026-09-26 audit T5).

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Checklist items 1-5: Mechanical bug-finding ---

EXPECTED_VERDICT["tc-uv1-unbounded-list.tsx"]="Critical"
CLAIM_ACCURACY["tc-uv1-unbounded-list.tsx"]="bug"  # Unbounded list without scroll cap
KEY_CHECK["tc-uv1-unbounded-list.tsx"]="finding_match:Critical=max-h-?[0-9[]|max-height&&overflow-(y-)?auto|overflow(-y)?: ?auto"

EXPECTED_VERDICT["tc-uv2-trapped-controls.tsx"]="Critical"
CLAIM_ACCURACY["tc-uv2-trapped-controls.tsx"]="bug"  # Submit button trapped inside scroll container
KEY_CHECK["tc-uv2-trapped-controls.tsx"]="finding_match:Critical=dock(ed)?|footer|(outside|out of|below|after) (the )?scroll(able|ing)? ?(container|area|region|content|list)?|sticky"

EXPECTED_VERDICT["tc-uv3-wrong-positioning.tsx"]="Major"
CLAIM_ACCURACY["tc-uv3-wrong-positioning.tsx"]="bug"  # Absolute positioning anchored to wrong parent
KEY_CHECK["tc-uv3-wrong-positioning.tsx"]="finding_match:Major=relative[^.]{0,80}(SectionA|section a|its (own )?(section|parent|container))|(SectionA|section a)[^.]{0,80}relative|positioned ancestor|containing block|nearest (positioned|relative)"

EXPECTED_VERDICT["tc-uv4-flex-sizing-error.tsx"]="Major"
CLAIM_ACCURACY["tc-uv4-flex-sizing-error.tsx"]="bug"  # shrink-0 on content area instead of flex-1 min-h-0
KEY_CHECK["tc-uv4-flex-sizing-error.tsx"]="finding_match:Major=flex-1|min-h-0|flex-grow|min-height: ?0"

EXPECTED_VERDICT["tc-uv5-hidden-overflow.tsx"]="Major"
CLAIM_ACCURACY["tc-uv5-hidden-overflow.tsx"]="bug"  # overflow-hidden silently clips error list
KEY_CHECK["tc-uv5-hidden-overflow.tsx"]="finding_match:Major=overflow-(y-)?(auto|scroll)|overflow(-y)?: ?(auto|scroll)"

# --- Checklist items 6-7: Affordance / responsive (full audit mode) ---

EXPECTED_VERDICT["tc-uv6-disappearing-controls.tsx"]="Minor"
CLAIM_ACCURACY["tc-uv6-disappearing-controls.tsx"]="bug"  # Button disappears on completion instead of relabeling
KEY_CHECK["tc-uv6-disappearing-controls.tsx"]="finding_match:Minor=re-?run|(update|change|swap|switch)[a-z]* (the |its )?(button.s )?label|keep (the )?button (visible|rendered|mounted|in place)|instead of (disappear|hid|remov|unmount)"

EXPECTED_VERDICT["tc-uv7-weak-affordance.tsx"]="Minor"
CLAIM_ACCURACY["tc-uv7-weak-affordance.tsx"]="bug"  # Interactive div looks like static text
KEY_CHECK["tc-uv7-weak-affordance.tsx"]="finding_match:Minor=<button|role=.?button|cursor-pointer|cursor: ?pointer|hover:[a-z]|\bborder(-[a-z0-9]+)+\b|\bbg-[a-z]+-[0-9]+|underline"

# --- Cross-framework: Unity/C# ---

EXPECTED_VERDICT["tc-uv8-unity-layout.cs"]="Critical"
CLAIM_ACCURACY["tc-uv8-unity-layout.cs"]="bug"  # Fixed pixel sizing + button trapped in ScrollRect content
KEY_CHECK["tc-uv8-unity-layout.cs"]="finding_match:Critical=anchorM(in|ax)|anchor(s|ing|ed)? |CanvasScaler|scale with screen size|LayoutElement|ContentSizeFitter|(outside|out of|sibling of|move[sd]? (it )?out of|reparent[a-z]* (it )?(outside|to)) (the )?(ScrollRect|scroll ?view|scroll content|content|viewport)"
