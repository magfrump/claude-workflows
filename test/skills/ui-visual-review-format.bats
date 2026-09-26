#!/usr/bin/env bats
# @category fast
# @needs-reports ui-visual-review
# Validates the output format of ui-visual-review reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/ui-visual-review.md bats test/skills/ui-visual-review-format.bats

load helpers

setup() {
  resolve_skill_report ui-visual-review tc-uv1-unbounded-list.tsx
  load_generic_report "$REPORT_PATH"
  count_findings
}

# SKILL.md (Step 5) lists the report's sections under its own "###" headings and
# shows each finding as "#### [Finding title]", but only the Environment block
# fixes a level ("## Environment"). A report may therefore render the other
# sections at "##" or "###"; both follow the skill.
ui_section_exists() {
  echo "$REPORT_CONTENT" | grep -qE "^#{2,3} $1"
}

# Print one section: from its "##"/"###" heading up to the next heading of the
# same or a higher level.
ui_section() {
  echo "$REPORT_CONTENT" | awk -v title="$1" '
    match($0, /^#+ /) {
      level = RLENGTH - 1
      if (inside && level <= start) exit
      if (!inside && level >= 2 && level <= 3 && substr($0, RLENGTH + 1) ~ ("^" title)) {
        inside = 1; start = level
      }
    }
    inside { print }
  '
}

# --- Header section ---

@test "report has a title header with UI Visual Review" {
  assert_title_matches '^# .*UI Visual Review'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Scope:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Date:\*\*'
}

# --- Environment section ---

@test "report has an Environment section" {
  # The one section whose level SKILL.md's template fixes.
  assert_section_exists "Environment"
}

@test "environment lists files reviewed" {
  ui_section "Environment" | grep -qiE 'files reviewed'
}

@test "environment lists target viewports" {
  ui_section "Environment" | grep -qiE 'viewport'
}

# --- Findings section ---

@test "report has a Findings section" {
  ui_section_exists "Findings"
}

@test "report has at least one finding or states none" {
  [ "$FINDING_COUNT" -gt 0 ] || ui_section "Findings" | grep -qxE 'No findings\.'
}

@test "each finding has a Severity line" {
  assert_field_per_finding "Severity"
}

@test "severity values use only the allowed values" {
  assert_field_values "Severity" "Critical|Major|Minor|Informational"
}

@test "each finding has a Location line" {
  assert_field_per_finding "Location"
}

@test "each finding has an Issue type line" {
  assert_field_per_finding "Issue type"
}

@test "each finding has a Move line" {
  assert_field_per_finding "Move"
}

@test "each finding has a Confidence line" {
  assert_field_per_finding "Confidence"
}

@test "confidence levels use only the allowed values" {
  assert_field_values "Confidence" "High|Medium|Low"
}

@test "each finding has a Recommendation line" {
  assert_field_per_finding "Recommendation"
}

# --- Best Practices table ---

@test "report has Best Practices Applied section" {
  ui_section_exists "Best Practices Applied"
}

@test "best practices section contains a table" {
  ui_section "Best Practices Applied" | grep -qE '^\|.*\|'
}

# --- Keyboard Navigation (SKILL.md: "required in every report") ---

@test "report has Keyboard Navigation section" {
  ui_section_exists "Keyboard Navigation"
}

@test "keyboard navigation states no focusables, or addresses all four items" {
  # SKILL.md: write exactly "No new focusable elements in this diff." when the
  # diff adds no focusable element; otherwise address Focus order, Escape-key
  # behavior, Skip-link presence and Focus-trap risks, each (N/A with a reason
  # when it does not apply).
  local body
  body="$(ui_section "Keyboard Navigation" | sed 1d)"
  [ -n "$body" ] || return 1
  if echo "$body" | grep -qE '^(> )?No new focusable elements in this diff\.'; then
    return 0
  fi
  local item
  for item in 'focus order' 'escape' 'skip.?link' 'focus.?trap'; do
    echo "$body" | grep -qiE "$item" || { echo "Keyboard Navigation does not address: $item"; return 1; }
  done
}

# --- Viewport Verification Checklist ---

@test "report has Viewport Verification Checklist section" {
  ui_section_exists "Viewport Verification Checklist"
}

@test "viewport checklist has mobile entry" {
  ui_section "Viewport Verification" | grep -qiE '(mobile|360|320)'
}

@test "viewport checklist has desktop entry" {
  ui_section "Viewport Verification" | grep -qiE '(desktop|1920|1366)'
}

# --- Ending sections ---

@test "report has What Looks Good section" {
  ui_section_exists "What Looks Good"
}

@test "report has Summary Table section" {
  ui_section_exists "Summary Table"
}

@test "report has Overall Assessment section" {
  ui_section_exists "Overall Assessment"
}

# --- No leakage from sibling code critics ---

@test "report does not contain fact-check verdicts" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}

@test "report does not contain security-style trust boundary map" {
  ! echo "$REPORT_CONTENT" | grep -qE '^#{2,3} Trust Boundary Map'
}

@test "report does not contain performance-style data flow section" {
  ! echo "$REPORT_CONTENT" | grep -qE '^#{2,3} Data Flow and Hot Paths'
}
