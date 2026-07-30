#!/usr/bin/env bats
# @category fast
# Enforces the *current* code-review rubric format contract against a golden fixture.
#
# Why this exists separately from code-review-format.bats: that suite validates whatever
# rubric happens to be newest in docs/reviews/, so it can only assert the subset of the
# format that the newest real artifact already satisfies. When the skill's format changes,
# the newest artifact predates the change and every test for the new structure would go
# red until someone happens to run a full review. The contract therefore had no way to be
# tested at the moment it was written — exactly when a regression is most likely.
#
# The fixture is the format spec in executable form. When
# skills/code-review/SKILL.md's rubric template changes, update
# test/skills/code-review/rubric-current-format.md in the same commit.

load helpers

FIXTURE="test/skills/code-review/rubric-current-format.md"

setup() {
  [ -f "$FIXTURE" ] || fail "Golden fixture missing at $FIXTURE"
  FIXTURE_CONTENT=$(tr -d '\r' < "$FIXTURE")
}

# Extract one "## <heading>" section, excluding the next heading line.
section() {
  echo "$FIXTURE_CONTENT" | sed -n "/^## .*$1/,/^## /p" | sed '$d'
}

# --- Sections the older suite already covers, re-asserted on the fixture ---

@test "fixture has all eight rubric sections" {
  local h
  for h in 'Must Fix' 'Must Address' 'Consider' 'Considered Overrides' \
           'Confirmed Good' 'Unverified Findings' 'Skipped Core Critics'; do
    echo "$FIXTURE_CONTENT" | grep -qiE "^## .*$h" || fail "missing section: $h"
  done
}

@test "fixture status line carries a verdict and an emoji" {
  echo "$FIXTURE_CONTENT" | grep -qE '\*\*Status:.*(🔴|🟡|✅)'
  echo "$FIXTURE_CONTENT" | grep -qiE '(DOES NOT PASS|CONDITIONAL PASS|PASSES REVIEW)'
}

# --- Evidence-grounding section (added 5f17729) ---

@test "Unverified Findings section is present and auditable" {
  local s
  s=$(section 'Unverified Findings')
  # Either a table or the explicit empty-state sentinel; the heading is mandatory
  # either way so the check is auditable across runs.
  echo "$s" | grep -qE "(\|.*\||All findings' evidence resolved\.)"
}

@test "Unverified Findings table records why each finding is unverified" {
  local s
  s=$(section 'Unverified Findings')
  echo "$s" | grep -qiE '\|.*Why unverified.*\|'
}

# --- Critic-native severity preservation (candidate 7 enabler) ---

@test "Must Fix table has a Severity column" {
  section 'Must Fix' | grep -qE '^\|[^|]*#[^|]*\|.*\|[[:space:]]*Severity[[:space:]]*\|'
}

@test "Must Address table has a Severity column" {
  section 'Must Address' | grep -qE '^\|[^|]*#[^|]*\|.*\|[[:space:]]*Severity[[:space:]]*\|'
}

@test "Consider table has a Severity column" {
  section 'Consider' | grep -qE '^\|[^|]*#[^|]*\|.*\|[[:space:]]*Severity[[:space:]]*\|'
}

@test "severity values are critic-native levels, not rubric tier emoji" {
  # The whole point of the column is that it survives the lossy tier mapping.
  # A row whose Severity cell is a tier emoji has flattened the signal away.
  local body
  body=$(echo "$FIXTURE_CONTENT" | grep -E '^\| (R|A|C)[0-9]+ \|')
  [ -n "$body" ] || fail "fixture has no finding rows"
  echo "$body" | grep -qiE '\|[[:space:]]*(Critical|High|Medium|Low|Informational|Breaking|Inconsistent|Structural|Coupling|Minor|Incorrect|Stale)[[:space:]]*\|' \
    || fail "no row carries a recognizable critic-native severity"
}

# --- Status columns (the calibration instrument added 5f17729) ---

@test "every finding row carries a Status value" {
  local row n=0
  while IFS= read -r row; do
    n=$((n + 1))
    echo "$row" | grep -qE '(🔴|🟡|🟢)[[:space:]]*(Unresolved|Open|Fixed|Won.t-Fix|Deferred)' \
      || fail "finding row lacks a Status value: $row"
  done < <(echo "$FIXTURE_CONTENT" | grep -E '^\| (R|A|C)[0-9]+ \|')
  [ "$n" -gt 0 ] || fail "fixture has no finding rows"
}

@test "Consider rows use the green status vocabulary" {
  # 🟢 is ~70% of pipeline output and was the tier with no disposition recorded,
  # which is why advisory-band precision could not be estimated after the fact.
  section 'Consider' | grep -E '^\| C[0-9]+ \|' \
    | grep -qE '🟢[[:space:]]*(Open|Fixed|Won.t-Fix|Deferred)'
}

# --- Location / evidence citation ---

@test "Must Fix rows cite a location" {
  section 'Must Fix' | grep -E '^\| R[0-9]+ \|' | grep -qE '`[^`]+:[0-9]+`'
}

# --- Guard against draft-review vocabulary leakage ---

@test "fixture does not contain draft-review verdict vocabulary" {
  ! echo "$FIXTURE_CONTENT" | grep -qiE '(PASSES VERIFICATION|Draft Verification Rubric)'
}
