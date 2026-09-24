# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Architecture review: the fixture sits alone in a throwaway repo; Read/Grep/Glob
# only, so the report goes to stdout instead of docs/reviews/. Fixtures are either
# a multi-module source file (labelled per-file sections) or a patch; the prompt
# names the file as the change under review, since the repo has no main branch
# to diff against.
FIXTURE_TOOLS="Read,Grep,Glob"
FIXTURE_MODE="repo"

fixture_prompt() {
  local f="$1"
  printf '%s' "Run an architecture review of ${f}, treating it as the change under review (a patch file is the diff itself). User goal: judge whether this change keeps the codebase structurally sound. Do not ask clarifying questions. Print the report to stdout. Scope: ${f}"
}
