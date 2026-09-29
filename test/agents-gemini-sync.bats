#!/usr/bin/env bats
# @category fast
# Validates that AGENTS.md and GEMINI.md stay in sync.
# Strips the first 3 lines (tool-specific headers) from each file, then diffs.
# Any difference means an edit was made to one file but not the other.
#
# Usage: bats test/agents-gemini-sync.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  AGENTS="$REPO_ROOT/AGENTS.md"
  GEMINI="$REPO_ROOT/GEMINI.md"
}

@test "AGENTS.md and GEMINI.md content is in sync (ignoring headers)" {
  [ -f "$AGENTS" ] || { echo "AGENTS.md not found"; return 1; }
  [ -f "$GEMINI" ] || { echo "GEMINI.md not found"; return 1; }

  local agents_body gemini_body
  agents_body=$(tail -n +4 "$AGENTS")
  gemini_body=$(tail -n +4 "$GEMINI")

  if ! diff_output=$(diff <(echo "$agents_body") <(echo "$gemini_body")); then
    echo "AGENTS.md and GEMINI.md have drifted (after stripping headers):"
    echo "$diff_output"
    return 1
  fi
}

# Claude Code loads AGENTS.md as this repo's project instructions (the root
# CLAUDE.md moved to global-instructions/, decision log row 47) and expands
# `@path` imports inline. The old `@./workflows/*.md` list pulled ~85K tokens
# of workflow text into every session here, invisible to the usage hook.
@test "AGENTS.md has no @-imports" {
  if matches=$(grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"); then
    echo "AGENTS.md contains @-imports, which Claude Code expands into every session:"
    echo "$matches"
    return 1
  fi
}
