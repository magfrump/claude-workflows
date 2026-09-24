# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Moat critique: the plan goes inline in the prompt. No Read, because inline
# mode runs claude in the real repo, where Read could reach
# expected-verdicts.bash; no Write, so the critique goes to stdout instead of
# docs/reviews/. SKILL.md forbids ad-hoc fact-checking and every company in the
# fixtures is invented, so WebSearch is only here because FIXTURE_TOOLS must be
# non-empty; a report that leans on search results is itself a finding.
FIXTURE_TOOLS="WebSearch"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Run a moat-and-distribution critique of the business plan below. No fact-check report is provided. Print the critique to stdout instead of writing docs/reviews/business-plan-critique-moat.md. The plan:"
}
