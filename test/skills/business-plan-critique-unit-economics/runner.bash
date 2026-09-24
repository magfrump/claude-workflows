# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Unit-economics critique: the draft goes inline in the prompt. Inline mode runs
# claude in the real repo, so Read is left out (it could reach
# expected-verdicts.bash). WebSearch only: SKILL.md tells the critic not to
# fact-check on its own, but leaves it available for comp-set context. No Write,
# so the critique goes to stdout instead of docs/reviews/.
FIXTURE_TOOLS="WebSearch"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Critique the unit economics of the following business plan. Run standalone, with no fact-check report. Print the critique to stdout instead of writing docs/reviews/:"
}
