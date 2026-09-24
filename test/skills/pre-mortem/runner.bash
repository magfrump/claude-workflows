# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Pre-mortem: the proposal goes inline in the prompt. No tools at all: no Read,
# because inline mode runs claude in the real repo, where Read could reach
# expected-verdicts.bash, and no Write, so the report goes to stdout instead of
# docs/reviews/pre-mortem.md. SKILL.md's Prior Art Check greps docs/decisions/
# and docs/working/; the harness has no repository for that, so the prompt says
# so and that the proposal is the whole input. No upstream what-if analysis is
# provided, so the skill's no-upstream note is expected at the top.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Pre-mortem this proposal: assume it shipped as written and failed, and write the failure narratives. No upstream what-if analysis is provided. No repository is available, so skip the Prior Art Check's search of docs/decisions/ and docs/working/; everything you need is in the proposal below. Print the report to stdout instead of writing docs/reviews/pre-mortem.md. The proposal:"
}
