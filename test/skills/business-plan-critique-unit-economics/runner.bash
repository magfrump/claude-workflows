# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Unit-economics critique: the draft goes inline in the prompt. Inline mode
# grants no file tools (runner-contract.bash). No tools at all: SKILL.md tells the critic not to
# fact-check on its own. No Write, so the critique goes to stdout instead of
# docs/reviews/.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Critique the unit economics of the following business plan. Run standalone, with no fact-check report. Print the critique to stdout instead of writing docs/reviews/:"
}
