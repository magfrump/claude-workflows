# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# API consistency review: the fixture sits alone in a throwaway repo, so the
# file carries its own baseline — pre-existing sibling surfaces plus the new
# surface, fenced by BEGIN/END CHANGE UNDER REVIEW comment lines that stand in
# for the diff. Read/Grep/Glob only, so the report goes to stdout instead of
# docs/reviews/.
FIXTURE_TOOLS="Read,Grep,Glob"
FIXTURE_MODE="repo"

fixture_prompt() {
  local f="$1"
  printf '%s' "Run an API consistency review of ${f}. The change under review is every block between a 'BEGIN CHANGE UNDER REVIEW' comment line and the matching 'END CHANGE UNDER REVIEW' line; treat those blocks as the diff. Everything else in the file is pre-existing code that existing consumers already depend on — use it as the baseline. Print the report to stdout. Scope: ${f}"
}
