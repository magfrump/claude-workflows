# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# What-if analysis: the proposal goes inline in the prompt. No Read (inline
# mode grants no file tools, runner-contract.bash); no Write, so the analysis goes to stdout instead of
# docs/reviews/. The skill needs no tools: SKILL.md's Prior Art Check greps
# docs/decisions/ and docs/working/, which this harness cannot offer (and the
# real repo's would be the wrong project's). SKILL.md allows "note that briefly
# and proceed" when those directories are absent, so the prompt says plainly
# that no repository is available and the proposal is the whole input.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Run a what-if analysis of the proposal below. No upstream critique is provided. No repository is available, so the Prior Art Check cannot search docs/decisions/ or docs/working/: note that briefly and proceed. Everything you need is in the proposal. Print the analysis to stdout instead of writing docs/reviews/what-if-analysis.md. The proposal:"
}
