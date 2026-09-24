# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Code fact-check: the fixture sits alone in a throwaway repo; Read/Grep/Glob
# only, so the report goes to stdout.
FIXTURE_TOOLS="Read,Grep,Glob"
FIXTURE_MODE="repo"

fixture_prompt() {
  local f="$1"
  printf '%s' "Code fact-check the file ${f}. Check all claims in comments and docstrings against actual code behavior. Scope: ${f}"
}
