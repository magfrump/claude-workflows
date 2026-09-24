# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# matrix-analysis dispatches one sub-agent per criterion (Agent tool), then
# synthesizes. Items, criteria and facts all go inline, so no Read: inline mode
# runs claude in the real repo, where Read could reach expected-verdicts.bash.
# Sub-agents inherit the same tool list, so they cannot read the repo either;
# SKILL.md already says to paste context into their prompts.
#
# FIXTURE_TRANSCRIPT=1 so subagents_min can check the one-per-criterion
# dispatch SKILL.md requires. No Write: the prompt says to print both
# deliverables (chat synthesis and the matrix document) to stdout. Every fixture
# gives items and criteria, so Stage 1 has nothing to ask; the prompt says the
# run is non-interactive anyway.
FIXTURE_TOOLS="Agent"
FIXTURE_MODE="inline"
FIXTURE_TRANSCRIPT=1

fixture_prompt() {
  printf '%s' "This is a non-interactive run: no one will answer questions, and the items and criteria below are final. Print both deliverables to stdout: the chat synthesis, then the full matrix document, instead of saving it to docs/reviews/matrix-analysis.md. The request:"
}
