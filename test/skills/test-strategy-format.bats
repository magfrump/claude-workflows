#!/usr/bin/env bats
# Validates the output format of test-strategy reports.
#
# Note: No example report ships in the repo — tests will skip via
# load_generic_report when REPORT_PATH does not point at a generated report.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/working/test-strategy.md bats test/skills/test-strategy-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/working/test-strategy.md}"
}

# --- Header section ---

@test "report has a title header with Test Strategy" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^#{1,2} .*Test Strategy'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Scope:\*\*'
}

@test "report has a Reviewed or Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*(Reviewed|Date):\*\*'
}

# --- Required sections ---

@test "report has Test Conventions section" {
  assert_heading_exists "Test Conventions"
}

@test "report has Untested Paths Touched by the Change section" {
  assert_heading_exists "Untested Paths"
}

@test "untested paths section has at least one numbered gap entry" {
  # Gap entries take the form: **G1** ... or - **G1** ...
  echo "$REPORT_CONTENT" | grep -qE '\*\*G[0-9]+\*\*'
}

@test "report has Recommended Tests section" {
  assert_heading_exists "Recommended Tests"
}

@test "report has What NOT to Test section" {
  assert_heading_exists "What NOT to Test"
}

@test "report has Summary or Overall section" {
  assert_heading_exists "(Summary|Overall)"
}

# --- Per-recommendation fields ---
#
# Recommended tests are written as #### headings inside Recommended Tests.
# Each must declare Type, Priority, File, What it verifies, and Closes gaps.

@test "at least one recommended test has a Type field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Type:\*\*'
}

@test "Type values are from the allowed taxonomy" {
  # Allowed: unit / integration / e2e / end-to-end / property / snapshot / golden / contract
  ! echo "$REPORT_CONTENT" | grep -E '^\*\*Type:\*\*' \
    | grep -viE '\b(unit|integration|e2e|end-to-end|property|snapshot|golden|contract)\b' \
    | grep -q .
}

@test "at least one recommended test has a Priority field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Priority:\*\*'
}

@test "Priority values are high/medium/low" {
  ! echo "$REPORT_CONTENT" | grep -E '^\*\*Priority:\*\*' \
    | grep -viE '\b(high|medium|low)\b' \
    | grep -q .
}

@test "at least one recommended test has a File field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*File:\*\*'
}

@test "at least one recommended test has a What it verifies field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*What it verifies:\*\*'
}

@test "at least one recommended test has a Closes gaps field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Closes gaps:\*\*'
}

# --- Structural requirements ---

@test "report has at least 4 H2 sections" {
  local section_count
  section_count=$(echo "$REPORT_CONTENT" | grep -cE '^## ' || true)
  [ "$section_count" -ge 4 ]
}

# --- No leakage from sibling skills ---

@test "report does not contain fact-check verdict language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}

@test "report does not contain tech-debt-triage recommendation verbs" {
  # Tech-debt-triage uses a fixed set of recommendation verbs. Test-strategy
  # should not borrow them — its currency is test recommendations, not
  # carry/fix/defer decisions on a single debt item.
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Recommendation:\*\* (Fix now|Fix opportunistically|Carry intentionally|Defer and monitor)\b'
}

@test "report does not contain dependency-upgrade verdicts" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Recommendation:\*\* (Upgrade now|Upgrade soon|Don.t upgrade)\b'
}

@test "report does not contain reviewer severity vocabulary" {
  # Reviewer skills (security/performance/api-consistency) use Severity fields.
  # Test-strategy uses Priority. A leaked Severity field signals confusion
  # between "this test is important" and "this finding is severe."
  ! echo "$REPORT_CONTENT" | grep -qE '^\*\*Severity:\*\*'
}
