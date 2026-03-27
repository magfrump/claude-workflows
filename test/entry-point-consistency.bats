#!/usr/bin/env bats
# Validates that CLAUDE.md, AGENTS.md, and GEMINI.md reference the same
# set of workflow .md files in their "## Cross-project Workflows" sections.
#
# Scoped to workflows only — skills (which only CLAUDE.md references
# indirectly) are excluded by extracting only bullet-point workflow entries.
#
# Usage: bats test/entry-point-consistency.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
  AGENTS_MD="$REPO_ROOT/AGENTS.md"
  GEMINI_MD="$REPO_ROOT/GEMINI.md"
}

# Extract sorted workflow filenames from the "## Cross-project Workflows"
# section of a given file. Only considers bullet-point lines (starting with
# "- **") to avoid matching non-workflow .md references (guides, docs, etc.)
# that may appear in the same section as prose.
extract_workflows() {
  local file="$1"
  # 1. Extract lines between '## Cross-project Workflows' and the next '## '
  # 2. Keep only bullet-point workflow entries (lines starting with '- **')
  # 3. Extract [a-z-]+\.md filenames
  # 4. Sort for stable comparison
  sed -n '/^## Cross-project Workflows/,/^## [^C]/p' "$file" \
    | grep '^- \*\*' \
    | grep -oE '[a-z-]+\.md' \
    | sort
}

@test "all three entry-point files exist" {
  [ -f "$CLAUDE_MD" ]
  [ -f "$AGENTS_MD" ]
  [ -f "$GEMINI_MD" ]
}

@test "each entry-point file lists at least one workflow" {
  local claude_count agents_count gemini_count
  claude_count=$(extract_workflows "$CLAUDE_MD" | wc -l)
  agents_count=$(extract_workflows "$AGENTS_MD" | wc -l)
  gemini_count=$(extract_workflows "$GEMINI_MD" | wc -l)

  [ "$claude_count" -gt 0 ] || { echo "CLAUDE.md: no workflows found"; return 1; }
  [ "$agents_count" -gt 0 ] || { echo "AGENTS.md: no workflows found"; return 1; }
  [ "$gemini_count" -gt 0 ] || { echo "GEMINI.md: no workflows found"; return 1; }
}

@test "CLAUDE.md and AGENTS.md reference the same workflows" {
  local claude_wf agents_wf
  claude_wf=$(extract_workflows "$CLAUDE_MD")
  agents_wf=$(extract_workflows "$AGENTS_MD")

  if ! diff_output=$(diff <(echo "$claude_wf") <(echo "$agents_wf")); then
    echo "Workflow mismatch between CLAUDE.md and AGENTS.md:"
    echo "$diff_output"
    return 1
  fi
}

@test "CLAUDE.md and GEMINI.md reference the same workflows" {
  local claude_wf gemini_wf
  claude_wf=$(extract_workflows "$CLAUDE_MD")
  gemini_wf=$(extract_workflows "$GEMINI_MD")

  if ! diff_output=$(diff <(echo "$claude_wf") <(echo "$gemini_wf")); then
    echo "Workflow mismatch between CLAUDE.md and GEMINI.md:"
    echo "$diff_output"
    return 1
  fi
}
