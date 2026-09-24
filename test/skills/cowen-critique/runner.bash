# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Cowen critique: the draft goes inline in the prompt. No Read (inline mode runs
# in the real repo, where Read could reach expected-verdicts.bash) and no Write,
# so the critique goes to stdout instead of docs/reviews/cowen-critique.md.
# SKILL.md tells the critic not to fact-check, so it gets no tools at all. No
# fact-check report is supplied, so a full critique opens with SKILL.md's
# no-fact-check warning.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Give me a Cowen-style critique of the following draft. Print the critique to stdout instead of writing docs/reviews/cowen-critique.md. The draft:"
}
