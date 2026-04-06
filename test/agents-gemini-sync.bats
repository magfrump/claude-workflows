#!/usr/bin/env bats
# @category fast
# Validates that AGENTS.md and GEMINI.md stay in sync.
# Strips the first 3 lines (tool-specific headers) from each file and
# removes the '@./workflows/' prefix from AGENTS.md, then diffs.
# Any difference means an edit was made to one file but not the other.
#
# Usage: bats test/agents-gemini-sync.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  AGENTS="$REPO_ROOT/AGENTS.md"
  GEMINI="$REPO_ROOT/GEMINI.md"
}

@test "AGENTS.md and GEMINI.md content is in sync (ignoring headers and @./workflows/ prefix)" {
  [ -f "$AGENTS" ] || { echo "AGENTS.md not found"; return 1; }
  [ -f "$GEMINI" ] || { echo "GEMINI.md not found"; return 1; }

  # Strip first 3 lines (header), then remove @./workflows/ prefix from AGENTS.md
  local agents_body
  agents_body=$(tail -n +4 "$AGENTS" | sed 's|@\./workflows/||g')

  local gemini_body
  gemini_body=$(tail -n +4 "$GEMINI")

  if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
    echo "AGENTS.md and GEMINI.md have drifted (after stripping headers and @./workflows/ prefix):"
    echo "$diff_output"
    return 1
  fi
}
