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

# Latent gap fixed 2026-08-21: tests called fail() but no helper existed, so a failing
# assertion died with status 127 instead of a readable message (still red, but opaque).
fail() { echo "$1" >&2; return 1; }

setup() {
  [ -f "$FIXTURE" ] || fail "Golden fixture missing at $FIXTURE"
  FIXTURE_CONTENT=$(tr -d '\r' < "$FIXTURE")
  SKILL="skills/code-review/SKILL.md"
  [ -f "$SKILL" ] || skip "code-review SKILL.md not found at $SKILL"
  SKILL_CONTENT=$(tr -d '\r' < "$SKILL")
}

# Extract one "## <heading>" section, excluding the next heading line.
section() {
  echo "$FIXTURE_CONTENT" | sed -n "/^## .*$1/,/^## /p" | sed '$d'
}

# --- Sections the older suite already covers, re-asserted on the fixture ---

@test "fixture has all nine rubric sections" {
  local h
  for h in 'Must Fix' 'Must Address' 'Consider' 'Considered Overrides' \
           'Confirmed Good' 'Unverified Findings' 'Skipped Core Critics' \
           'Composition check'; do
    echo "$FIXTURE_CONTENT" | grep -qiE "^## .*$h" || fail "missing section: $h"
  done
}

@test "the Fragment-Composition cross-check is a required Stage-3 pass with capped authority" {
  echo "$SKILL_CONTENT" | grep -qE '^#### Fragment-Composition cross-check \(required before producing deliverables\)' \
    || fail "no required Fragment-Composition cross-check in Stage 3"
  local flat
  flat=$(echo "$SKILL_CONTENT" | sed -n '/^#### Fragment-Composition cross-check/,/^#### Contrastive note/p' | tr '\n' ' ' | tr -s ' ')
  echo "$flat" | grep -qiE 'no single.{0,10}fragment states' \
    || fail "the forced composition question is missing"
  echo "$flat" | grep -qiE 'maximum of the fragment tiers.*inherit-only, never a lift' \
    || fail "composed rows do not inherit max fragment tier / are liftable"
  echo "$flat" | grep -qiE 'never counts as corroboration' \
    || fail "composition is not excluded from escalation corroboration"
  echo "$flat" | grep -qiE 'traceable to a fragment.s own quoted evidence' \
    || fail "the entailment discipline (false-composition guard) is missing"
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

# --- Confirmed Good carries evidence (thoughts doc §1.3) ---
#
# Confirmed Good is the highest-assurance row the rubric emits, and on the MD1 diff two of
# three model tiers filed the branch's actual blocking defect under it — one of them with
# the disconfirming observation sitting in that same run's own fact-check report. The
# Evidence column is what makes the row checkable at all.

@test "Confirmed Good table has an Evidence column" {
  section 'Confirmed Good' | grep -qE '^\|[[:space:]]*Item[[:space:]]*\|.*\|[[:space:]]*Evidence[[:space:]]*\|'
}

@test "every Confirmed Good row cites evidence" {
  local row n=0
  while IFS= read -r row; do
    n=$((n + 1))
    # Either a grounded `path:line` citation or the enumeration that establishes a
    # universally quantified claim. An instance-shaped citation for an "all/none"
    # claim is the exact move that produced the observed miss.
    echo "$row" | grep -qE '(`[^`]+:[0-9]+`|[Ee]numeration|rg -n)' \
      || fail "Confirmed Good row lacks evidence: $row"
  done < <(section 'Confirmed Good' | grep -E '^\|.*✅ Confirmed')
  [ "$n" -gt 0 ] || fail "fixture has no Confirmed Good rows"
}

@test "a contested confirmation lands in Must Address, not Confirmed Good" {
  # The fixed behaviour on a Confirmed-Good/fact-check contradiction: the row is
  # neither dropped silently nor promoted past amber.
  section 'Must Address' | grep -qE '^\| A[0-9]+ \|.*Confirmed-Good cross-check' \
    || fail "golden does not demonstrate the contested-confirmation row"
  section 'Must Address' | grep -E 'Confirmed-Good cross-check' | grep -qE '\|[[:space:]]*Contested[[:space:]]*\|' \
    || fail "contested row does not carry the Contested severity"
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

# --- Golden ↔ SKILL.md template sync ---
#
# The skill says "changes to the template must be mirrored in the golden in the same
# commit". This repo's own standing evidence (the override log that went unwritten for
# nine runs because only prose asked for it) is that an unenforced instruction does not
# execute. These two tests are the enforcement: they extract the structure of the rubric
# template embedded in skills/code-review/SKILL.md and require the golden to match it, so
# the mirroring either happens or the suite goes red.

SKILL_MD="skills/code-review/SKILL.md"

# Emit the fenced markdown rubric template from the skill.
skill_template() {
  awk '/\*\*Use this exact format/ { f = 1 }
       f && /^```markdown/         { c = 1; next }
       c && /^```$/                { exit }
       c' "$SKILL_MD"
}

# Emit each table header row (a "|" line immediately followed by a "|---" separator).
table_headers() {
  awk '/^\|/ { prev = $0; getline nxt
              if (nxt ~ /^\|[- |]+\|$/) print prev
              # re-examine the line we consumed, it may itself start a table
              if (nxt ~ /^\|/) { prev = nxt } }'
}

@test "golden's table headers match the skill's rubric template" {
  [ -f "$SKILL_MD" ] || skip "not running from repo root"
  local from_skill from_golden
  from_skill=$(skill_template | table_headers)
  from_golden=$(echo "$FIXTURE_CONTENT" | table_headers)
  [ -n "$from_skill" ] || fail "could not extract the rubric template from $SKILL_MD"
  if [ "$from_skill" != "$from_golden" ]; then
    printf 'template headers:\n%s\n\ngolden headers:\n%s\n' "$from_skill" "$from_golden" >&2
    fail "golden is out of sync with the rubric template in $SKILL_MD"
  fi
}

@test "golden's section headings match the skill's rubric template" {
  [ -f "$SKILL_MD" ] || skip "not running from repo root"
  local from_skill from_golden
  from_skill=$(skill_template | grep -E '^## ')
  from_golden=$(echo "$FIXTURE_CONTENT" | grep -E '^## ')
  [ "$from_skill" = "$from_golden" ] \
    || fail "section headings differ:\n$(diff <(echo "$from_skill") <(echo "$from_golden") || true)"
}

# --- Guard against draft-review vocabulary leakage ---

@test "fixture does not contain draft-review verdict vocabulary" {
  ! echo "$FIXTURE_CONTENT" | grep -qiE '(PASSES VERIFICATION|Draft Verification Rubric)'
}
