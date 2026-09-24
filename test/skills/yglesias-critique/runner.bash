# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Yglesias critique: fixture content goes inline in the prompt. No Read, because
# inline mode runs claude in the real repo, where Read could reach
# expected-verdicts.bash. No Write, so the critique goes to stdout instead of
# docs/reviews/. SKILL.md tells the critic not to fact-check on its own, so it
# gets no tools at all. No fact-check report is supplied: the critique should
# open with SKILL.md's no-fact-check warning.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Give me the Yglesias-style pragmatic critique of the following draft. Print the critique to stdout instead of writing docs/reviews/yglesias-critique.md."
}
