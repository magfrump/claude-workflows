#!/usr/bin/env bats
# @category fast
# @needs-reports what-if-analysis
# Validates the output format of what-if-analysis reports.
#
# Note: No example report is committed — tests will skip via load_generic_report
# if REPORT_PATH (or the default path) does not exist.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/what-if-analysis.md bats test/skills/what-if-analysis-format.bats

load helpers

setup() {
  resolve_skill_report what-if-analysis tc-wi1-order-events-queue.md
  load_generic_report "$REPORT_PATH"
}

# Print one section: from a "##"/"###" heading matching $1 (ERE) up to the next
# heading at the same or a higher level. skills/what-if-analysis/SKILL.md lists the
# sections under its own ### headings without fixing the report's level, and
# reports nest subsections (e.g. "### Must address before proceeding") inside them.
section_body() {
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

@test "report has a title header with What-If Analysis" {
  # 12, not 5: SKILL.md puts the 3-line no-upstream-critique note, and the
  # Prior Art Check's "nothing found" note, above the title.
  assert_title_matches '^# .*What.?If Analysis' 12
}

@test "report has a Proposal field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Proposal:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Date:\*\*'
}

@test "report names upstream critiques used (or 'none')" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Upstream critiques:\*\*'
}

# --- Required sections (the cognitive moves) ---

@test "report has an Assumptions Examined section" {
  assert_heading_exists "Assumptions Examined"
}

@test "report has a Consequence Chains section (second-order effects)" {
  assert_heading_exists "Consequence Chains"
}

@test "report has a Coupling Analysis section (hidden couplings)" {
  assert_heading_exists "Coupling Analysis"
}

@test "report has a Confidence Inversions section" {
  assert_heading_exists "Confidence Inversions?"
}

@test "report has an Adversarial Scenarios section" {
  assert_heading_exists "Adversarial Scenarios?"
}

@test "report has a Reversibility Map section" {
  assert_heading_exists "Reversibility"
}

@test "report has a Cost of Success section" {
  assert_heading_exists "Cost of Success"
}

@test "report has a Findings Summary section" {
  assert_heading_exists "Findings Summary"
}

@test "report has a Recommendations section" {
  # SKILL.md's section names only (the Consequence Chains, Coupling Analysis
  # and Recommendations aliases were dropped): the grouping check below reads
  # "Recommendations", so an "Overall Assessment" alias passed here and failed
  # there.
  assert_heading_exists "Recommendations"
}

# --- Per-assumption fields ---

@test "every assumption carries an If wrong field with an allowed value" {
  # SKILL.md: "For each [assumption], use these fields: ... If wrong: tweak /
  # redesign / full retreat".
  local body n_a n_w
  body="$(section_body "Assumptions Examined")"
  n_a=$(echo "$body" | grep -ciE '^[[:space:]]*([-*+][[:space:]]+)?\*\*Assumption:\*\*' || true)
  n_w=$(echo "$body" | grep -ciE '^[[:space:]]*([-*+][[:space:]]+)?\*\*If wrong:\*\*[[:space:]]*\**(tweak|redesign|full retreat)\b' || true)
  [ "$n_a" -ge 1 ] || { echo "No **Assumption:** entries in Assumptions Examined"; return 1; }
  [ "$n_a" -eq "$n_w" ] || { echo "$n_a assumptions but $n_w If wrong fields with tweak/redesign/full retreat"; return 1; }
}

# --- Findings tagging ---

@test "every finding in the summary carries a prescribed tag" {
  # SKILL.md: "A consolidated list of all findings, each tagged" with one of
  # six tags. [NOVEL] is an Assumptions Examined tag and [NOVEL FAILURE MODE]
  # belonged to the pre-mortem half that moved to the pre-mortem skill
  # (2aad1e1); neither counts here. Top-level list items are the findings.
  local items untagged
  items=$(section_body "Findings Summary" | grep -E '^([-*+]|[0-9]+[.)])[[:space:]]' || true)
  [ -n "$items" ] || { echo "Findings Summary has no list items"; return 1; }
  untagged=$(echo "$items" | grep -vE '\[(UNEXAMINED ASSUMPTION|SECOND-ORDER EFFECT|HIDDEN COUPLING|REVERSIBILITY CLIFF|SUCCESS COST|PRIOR CONSIDERATION)\]' || true)
  [ -z "$untagged" ] || { echo "Untagged findings: $untagged"; return 1; }
}

# --- Recommendations structure ---

@test "recommendations distinguish blockers from acknowledged risks" {
  section_body "Recommendations" | grep -qiE '(must address|worth mitigating|acknowledged risks?)'
}

# --- No leakage from sibling skills ---

@test "report does not contain fact-check verdict language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}

@test "report does not contain cowen-critique Argument Decomposed framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*Argument Decomposed'
}

@test "report does not contain yglesias-critique Goal vs Mechanism framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*Goal vs\.? Mechanism'
}

@test "report does not contain matrix-analysis Comparison Matrix framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Comparison Matrix'
}

@test "report does not contain tech-debt-triage Carrying Cost framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*Carrying Cost'
}

@test "report does not contain design-space-situating dimensions framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*(Locus of Authority|Orientation in Time|Reversibility Dimension)'
}
