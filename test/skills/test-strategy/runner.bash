# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Test strategy: the fixture is one file holding a module and, below a
# "--- tests (...) ---" marker, its existing tests, copied alone into a
# throwaway repo with one commit. There is no branch diff, so the prompt names
# the file as the scope (SKILL.md scoping rule 1). SKILL.md also asks for tests
# of adjacent code and the test configuration; neither exists here, and the
# prompt says so. Read/Grep/Glob only, so the plan goes to stdout rather than
# docs/working/.
FIXTURE_TOOLS="Read,Grep,Glob"
FIXTURE_MODE="repo"

fixture_prompt() {
  local f="$1"
  printf '%s' "Write a test strategy for ${f}. Scope: ${f}, the whole file (there is no branch diff). The file holds the module followed by its existing tests, below the tests marker comment, which names where those tests live in the real project. There are no other source files, adjacent tests or test configuration in this repository, so everything you need is in ${f}. Print the plan to stdout; do not save it to docs/working/."
}
