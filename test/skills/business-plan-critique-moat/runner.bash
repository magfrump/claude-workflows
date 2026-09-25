# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Moat critique: the plan goes inline in the prompt. No Read (inline mode
# grants no file tools, runner-contract.bash); no Write, so the critique goes to stdout instead of
# docs/reviews/. SKILL.md forbids ad-hoc fact-checking, so it gets no tools at
# all.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Run a moat-and-distribution critique of the business plan below. No fact-check report is provided. Print the critique to stdout instead of writing docs/reviews/business-plan-critique-moat.md. The plan:"
}
