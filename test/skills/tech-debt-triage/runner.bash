# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Tech debt triage: each fixture is one debt item written up with its code
# excerpt, history, incidents, change frequency and team context, pasted inline.
# SKILL.md's scoping step reads the code and its git log; neither exists here,
# so the prompt says the write-up is all there is. No tools: Read in inline mode
# could reach expected-verdicts.bash, and SKILL.md's optional save to
# docs/working/ is replaced by printing to stdout.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Triage the tech debt item below as a single debt item. The repository and its git history are not available to you; the write-up below already contains the relevant code excerpt, history, incidents, change frequency and team context, so work from it alone. Print the triage to stdout instead of writing it to docs/working/. The debt item:"
}
