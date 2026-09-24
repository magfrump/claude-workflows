# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Fact-check: fixture content goes inline in the prompt. Web search only — no
# Read means no reaching the verdicts; no Write means the report goes to stdout.
FIXTURE_TOOLS="WebSearch,WebFetch"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Fact-check the following draft:"
}
