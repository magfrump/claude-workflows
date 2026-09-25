# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Security review: the fixture sits alone in a throwaway repo (one "fixture"
# commit, so no branch diff to scope to); Read/Grep/Glob only, so the report
# goes to stdout instead of docs/reviews/.
FIXTURE_TOOLS="Read,Grep,Glob"
FIXTURE_MODE="repo"

fixture_prompt() {
  local f="$1"
  printf '%s' "Run a security review of ${f}. Print the report to stdout. Scope: ${f}"
}
