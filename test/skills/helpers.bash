# Shared helpers for skill output BATS tests.
# Load with: load helpers  (from the same directory)
#
# A format suite grades one report: REPORT_PATH when set (eval_fixture's
# format_check passes the fixture's report this way, or point it at any report
# by hand), else its skill's generated report for one full-format fixture,
# resolved by resolve_skill_report below. There is no committed default: the
# docs/reviews/ artifacts the suites used to fall back on are frozen, so a
# format suite graded them whatever the skill said (audit T2). Generate
# reports with test/skills/generate-reports.bash <skill>.

# skill_has_reports, check_report_stamp (shared with generate-reports.bash).
# shellcheck source=runner-contract.bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/runner-contract.bash"

# Call first in a report suite's setup(): sets REPORT_PATH to the report to grade.
#   - REPORT_PATH already set: use it; a missing file there fails (the caller
#     named it). Its provenance is the caller's: eval_fixture checks the stamp
#     before its format_check.
#   - else, with no generated reports for <skill> (or no <fixture> given, for
#     suites whose skill has no generator), skip, saying how to get one. This
#     is the standalone case: scripts/run-tests.sh only runs the suite when the
#     skill has reports.
#   - else the skill has reports, so <fixture>'s must exist, be non-empty,
#     carry no .failed marker, and have a stamp matching the current tree;
#     anything else fails rather than skips (audit T3/T4).
# The skills test dir is SKILL_TESTS_DIR, default BATS_TEST_DIRNAME (suites in
# test/skills/<skill>/ set it to their parent).
# Args: $1 = skill, $2 = fixture whose report to grade by default (optional)
resolve_skill_report() {
  local skill="$1" fixture="${2:-}" sk="${SKILL_TESTS_DIR:-$BATS_TEST_DIRNAME}"
  if [ -n "${REPORT_PATH:-}" ]; then
    if [ ! -f "$REPORT_PATH" ]; then
      echo "REPORT_PATH=$REPORT_PATH does not exist"
      return 1
    fi
    return 0
  fi
  if [ -z "$fixture" ] || ! skill_has_reports "$sk" "$skill"; then
    skip "No report to grade: set REPORT_PATH, or generate ${skill}'s reports (bash test/skills/generate-reports.bash ${skill})"
  fi
  local report="$sk/$skill/output/$fixture.report.md"
  if [ ! -f "$report" ]; then
    echo "No report for $fixture, although $skill has generated reports. Regenerate: bash test/skills/generate-reports.bash $skill $fixture"
    return 1
  fi
  if [ -f "${report%.report.md}.failed" ]; then
    echo "Generation failed for $fixture: $(cat "${report%.report.md}.failed")"
    return 1
  fi
  check_report_stamp "$sk" "$skill" "$fixture" || return 1
  if ! grep -q '[^[:space:]]' "$report"; then
    echo "Empty report for $fixture: nothing to grade"
    return 1
  fi
  REPORT_PATH="$report"
}

# Call in setup() to load a claim-based report and precompute common values.
# Args: $1 = default report path
#       $2 = optional ERE matching a claim heading line (default '^## Claim [0-9]+',
#            the code-fact-check shape). fact-check reports head each verdict
#            '## Verdict for C<N>: "..."' per skills/fact-check/SKILL.md, so its
#            suite passes '^## Verdict for C[0-9]+'.
# Sets CLAIM_HEADING_RE for the helpers below.
load_report() {
  REPORT="${REPORT_PATH:-$1}"
  CLAIM_HEADING_RE="${2:-^## Claim [0-9]+}"
  if [ ! -f "$REPORT" ]; then
    skip "No report found at $REPORT — generate one first"
  fi
  REPORT_CONTENT=$(tr -d '\r' < "$REPORT")
  CLAIM_COUNT=$(echo "$REPORT_CONTENT" | grep -cE "$CLAIM_HEADING_RE" || true)
  if [ "$CLAIM_COUNT" -eq 0 ]; then
    skip "Report has no claims"
  fi
  # Extract only the claims sections (each claim heading up to the next ## heading
  # that is not itself a claim heading) so field-counting helpers aren't thrown
  # off by metadata fields that share the same name (e.g. **Confidence:** in a
  # report header). Capture resumes at every later claim heading, because
  # code-fact-check puts more claims after a `## Submitted Claims` heading.
  CLAIMS_BODY=$(echo "$REPORT_CONTENT" | awk -v re="$CLAIM_HEADING_RE" '
    $0 ~ re { inclaims = 1; print; next }
    /^## / { inclaims = 0 }
    inclaims { print }
  ')
  # shellcheck disable=SC2034  # Used by test files that source this helper
  ATTENTION_SECTION=$(echo "$REPORT_CONTENT" | sed -n '/^## Claims Requiring/,$p')
}

# Call in setup() to load any report without requiring claims.
# Args: $1 = default report path
# Resolve the newest code-review rubric. Rubrics are date-stamped
# (code-review-rubric-YYYY-MM-DD-<branch-slug>.md) so each review's findings survive the
# next review; the ISO date leads the suffix, so lexical glob order is date order and the
# last match is the newest. Falls back to the legacy undated name for artifacts predating
# the date-stamping change.
latest_rubric() {
  local f newest=""
  for f in docs/reviews/code-review-rubric-*.md; do
    [ -e "$f" ] || continue
    newest="$f"
  done
  [ -n "$newest" ] || newest="docs/reviews/code-review-rubric.md"
  printf '%s' "$newest"
}

load_generic_report() {
  REPORT="${REPORT_PATH:-$1}"
  if [ ! -f "$REPORT" ]; then
    skip "No report found at $REPORT — generate one first"
  fi
  REPORT_CONTENT=$(tr -d '\r' < "$REPORT")
  if [ -z "$REPORT_CONTENT" ]; then
    skip "Report is empty"
  fi
}

# Count findings in reviewer-style reports (### N. or #### N. Title).
# Extracts FINDINGS_BODY scoped from the first finding heading to the next
# ## section (e.g., What Looks Good, Summary Table), mirroring how CLAIMS_BODY
# is scoped in load_report. Falls back to first-finding-to-EOF if no trailing
# ## heading follows the findings.
count_findings() {
  # Preferred shape (current skills): a "## Findings" section whose findings are
  # ###/#### headings — numbered or not (security-reviewer mandates unnumbered
  # "#### [Finding title]"). Count headings inside that section.
  FINDINGS_BODY=$(echo "$REPORT_CONTENT" | sed -nE '/^## Findings/,/^## [^#]/p' | sed '1d;$d')
  if [ -n "$FINDINGS_BODY" ]; then
    FINDING_COUNT=$(echo "$FINDINGS_BODY" | grep -cE '^#{3,4} ' || true)
    return
  fi
  # The same section one level down ("### Findings" holding "#### [Finding
  # title]"): the reviewer templates show both at those levels, and
  # ui-visual-review's suite accepts either.
  FINDINGS_BODY=$(echo "$REPORT_CONTENT" | sed -nE '/^### Findings/,/^#{1,3} [^#]/p' | sed '1d;$d')
  if [ -n "$FINDINGS_BODY" ]; then
    FINDING_COUNT=$(echo "$FINDINGS_BODY" | grep -cE '^#### ' || true)
    return
  fi
  # Legacy shape: numbered finding headings with no "## Findings" wrapper.
  FINDING_COUNT=$(echo "$REPORT_CONTENT" | grep -cE '^#{3,4} [0-9]+\.' || true)
  # Extract from first finding to the next ## heading that isn't a finding
  FINDINGS_BODY=$(echo "$REPORT_CONTENT" | sed -nE '/^#{3,4} [0-9]+\./,/^## [^#]/p' | sed '$d')
  if [ -z "$FINDINGS_BODY" ]; then
    # Fallback: findings run to end of file (no trailing ## heading).
    FINDINGS_BODY=$(echo "$REPORT_CONTENT" | sed -nE '/^#{3,4} [0-9]+\./,$p')
  fi
}

# Reviewer skills (security, performance, api-consistency, architecture, ui-visual)
# allow a no-findings report: their Findings template says to keep the section and
# write the single line "No findings." in place of finding entries. Pass when there is
# at least one finding, or when the Findings section carries that marker.
assert_findings_or_none_stated() {
  [ "$FINDING_COUNT" -gt 0 ] && return 0
  echo "$REPORT_CONTENT" | sed -nE '/^## Findings/,/^## [^#]/p' | grep -qxE 'No findings\.'
}

# Assert that every finding has a given field.
# Counts only within FINDINGS_BODY (set by count_findings) to avoid
# false matches from report-level metadata sharing the same field name.
assert_field_per_finding() {
  local field="$1"
  local field_count
  field_count=$(echo "$FINDINGS_BODY" | grep -cE "^\\*\\*${field}:\\*\\*" || true)
  [ "$FINDING_COUNT" -eq "$field_count" ]
}

# Assert a section (## heading) exists in the report.
assert_section_exists() {
  local heading="$1"
  echo "$REPORT_CONTENT" | grep -qE "^## ${heading}"
}

# Assert that REPORT_CONTENT contains a title header matching `pattern`
# (extended regex) within the first `max_lines` lines. Replaces the
# `echo "$REPORT_CONTENT" | head -N | grep -qiE '...'` boilerplate the
# *-format.bats suites all duplicate.
# Args: $1 = pattern, $2 = optional max_lines (default 5),
#       $3 = optional grep flags (default "-qiE")
assert_title_matches() {
  local pattern="$1"
  local max_lines="${2:-5}"
  local flags="${3:--qiE}"
  # shellcheck disable=SC2086  # flags is a deliberately split flag string
  echo "$REPORT_CONTENT" | head -"$max_lines" | grep $flags "$pattern"
}

# Assert a section (any heading level) exists, case-insensitive.
assert_heading_exists() {
  local pattern="$1"
  echo "$REPORT_CONTENT" | grep -qiE "^#{1,4} .*${pattern}"
}

# Assert that every claim section has a given field (e.g., "Verdict", "Confidence").
# Counts only within CLAIMS_BODY (set by load_report) to avoid
# false matches from report-level metadata sharing the same field name.
assert_field_per_claim() {
  local field="$1"
  local field_count
  field_count=$(echo "$CLAIMS_BODY" | grep -cE "^\\*\\*${field}:\\*\\*" || true)
  [ "$CLAIM_COUNT" -eq "$field_count" ]
}

# Assert every value of a field matches an allowed-values regex.
# Uses grep -v to find violations (no -oP dependency).
# Searches FINDINGS_BODY or CLAIMS_BODY when available, falling back to
# REPORT_CONTENT, so field matches stay scoped consistently with the
# per-finding/per-claim counters.
# Args: $1 = field name, $2 = case-insensitive regex of allowed values
assert_field_values() {
  local field="$1" allowed="$2"
  local body values bad
  if [ -n "${FINDINGS_BODY:-}" ]; then
    body="$FINDINGS_BODY"
  elif [ -n "${CLAIMS_BODY:-}" ]; then
    body="$CLAIMS_BODY"
  else
    body="$REPORT_CONTENT"
  fi
  values=$(echo "$body" | sed -n "s/^\\*\\*${field}:\\*\\* //p")
  [ -n "$values" ] || skip "no ${field} values found"
  # The enum value must lead the field; a trailing annotation is allowed — reports
  # legitimately qualify, e.g. "High (executed)", "Minor *(carried)*", "High for
  # the mechanism, Low for reachability". The base value must still be from the
  # enum, and nothing may precede it.
  bad=$(echo "$values" | grep -viE "^(${allowed})([ ,(*].*)?$" || true)
  [ -z "$bad" ]
}

# Load the code-review skill's full CONTENT SURFACE: SKILL.md plus its references/
# files. The deliverable templates, rubric semantics and override-log format were
# extracted out of the skill body 2026-09-11 (prompt audit F8) so they load at the
# stage that needs them, which means any assertion about "the skill" must read all
# four files.
#
# The cat order is DOCUMENT order and it is load-bearing: several suites bound sed
# ranges with end anchors that exist only in a reference file (e.g.
# /^### Rubric Status Line/ in references/rubric.md), so a different order silently
# changes what those ranges capture.
#
# Two cautions for callers, both real bugs found by review on 2026-09-12:
#   - An open-ended range over SKILL_CONTENT ("/^## Heading/,$p") runs past SKILL.md
#     into the references. Anchor on "$SKILL" when the section is last in SKILL.md.
#   - The concatenation contains three duplicated "## " headings (a pointer stub in
#     SKILL.md plus the real section in a reference), so a range keyed on one of
#     those headings can capture the stub instead of the section.
#
# Sets SKILL_DIR, SKILL and SKILL_CONTENT. Args: $1 = repo root (default: cwd).
load_code_review_skill() {
  local root="${1:-.}"
  # shellcheck disable=SC2034  # consumed by the suites that load this helper
  SKILL_DIR="$root/skills/code-review"
  SKILL="$SKILL_DIR/SKILL.md"
  [ -f "$SKILL" ] || skip "code-review SKILL.md not found at $SKILL"
  # shellcheck disable=SC2034  # consumed by the suites that load this helper
  SKILL_CONTENT=$(cat "$SKILL" \
    "$SKILL_DIR/references/chat-synthesis.md" \
    "$SKILL_DIR/references/rubric.md" \
    "$SKILL_DIR/references/override-log.md" | tr -d '\r')
}
