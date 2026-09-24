# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# divergent-design is a router: SKILL.md says to run a trigger test, then read and
# follow workflows/divergent-design.md. The fixtures check the routing itself, so
# tree mode puts the LIVE workflow into the temp repo (fixture_base) and each
# fixture is only a REQUEST.md. The transcript shows whether the model read the
# workflow (tool_called:Read=...).
#
# Read/Grep/Glob only: no Write, so the workflow's docs/working/ and
# docs/decisions/ writes cannot happen; the prompt says to print that content
# instead. No AskUserQuestion either; the prompt says no human is present, which
# the workflow's Path C covers. The prompt names neither the workflow nor the
# routing, so the negatives test the trigger test rather than obedience.
FIXTURE_TOOLS="Read,Grep,Glob"
FIXTURE_MODE="tree"
FIXTURE_TRANSCRIPT=1

fixture_base() {
  mkdir -p "$1/workflows"
  cp "$REPO_ROOT/workflows/divergent-design.md" "$1/workflows/"
}

fixture_prompt() {
  printf '%s' "Handle the request below. This is a non-interactive run: no human will answer questions, so where a process you follow asks a person to choose, record a tentative pick and continue. You cannot write files; if a process you follow says to write a file, print that content to stdout instead. The request:"
}
