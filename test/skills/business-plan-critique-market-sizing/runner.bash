# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Market-sizing critique: the plan goes inline in the prompt. No Read — inline
# mode runs claude in the real repo, where Read could reach
# expected-verdicts.bash. No fact-check report is supplied, so SKILL.md has the
# model emit its no-fact-check warning and critique internal consistency only.
# SKILL.md tells the model not to spot-check facts, so it gets no tools at all.
# No Write, so the critique goes to stdout instead of docs/reviews/.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Critique the market sizing in the following business plan. No fact-check report is provided. Print the critique to stdout; do not write it to docs/reviews/."
}
