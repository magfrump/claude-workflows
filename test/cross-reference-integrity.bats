#!/usr/bin/env bats
# Validates that cross-references between workflow, skill, guide, and pattern
# markdown files point to files that actually exist.
#
# Catches silent breakage when files are renamed or moved — a gap not covered
# by health-check which only validates CLAUDE.md/AGENTS.md references.
#
# Usage: bats test/cross-reference-integrity.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  # Directories whose markdown files we scan for cross-references
  CONTENT_DIRS=("workflows" "skills" "guides" "patterns")
}

# Collect all .md files in the content directories
collect_markdown_files() {
  for dir in "${CONTENT_DIRS[@]}"; do
    local full="$REPO_ROOT/$dir"
    [ -d "$full" ] && find "$full" -name '*.md' -type f
  done
}

# --- (a) Explicit markdown links [text](path) ---

@test "all explicit markdown links resolve to existing files" {
  local failures=""
  local count=0

  while IFS= read -r file; do
    # Extract markdown link targets: [anything](target)
    # Skip URLs (http:// https://) and anchor-only links (#...)
    while IFS= read -r link; do
      [ -z "$link" ] && continue

      # Resolve relative to the source file's directory
      local source_dir
      source_dir=$(dirname "$file")
      local resolved="$source_dir/$link"

      # Strip any anchor fragment (path.md#section → path.md)
      resolved="${resolved%%#*}"

      # Normalize the path
      resolved=$(cd "$source_dir" && realpath -m "$link" 2>/dev/null) || resolved="$source_dir/$link"
      resolved="${resolved%%#*}"

      if [ ! -f "$resolved" ]; then
        failures+="  $file -> $link (resolved: $resolved)\n"
      fi
      count=$((count + 1))
    done < <(grep -oE '\[[^]]*\]\([^)]+\)' "$file" \
             | grep -oE '\(([^)]+)\)' \
             | sed 's/^(//;s/)$//' \
             | grep -vE '^https?://' \
             | grep -vE '^#')
  done < <(collect_markdown_files)

  # Ensure we actually checked something (guard against broken collection)
  [ "$count" -gt 0 ] || { echo "No markdown links found — check test setup"; return 1; }

  if [ -n "$failures" ]; then
    echo "Broken explicit markdown links:"
    echo -e "$failures"
    return 1
  fi
}

# --- (b) Bare path references matching known directory prefixes ---

@test "all bare path references resolve to existing files" {
  local failures=""
  local count=0

  while IFS= read -r file; do
    # Extract bare path references like workflows/foo.md, skills/bar.md etc.
    # These appear in prose text, backtick-quoted, or in markdown link targets.
    # We match from repo root since these are written as root-relative paths.
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue

      local resolved="$REPO_ROOT/$ref"

      if [ ! -f "$resolved" ]; then
        failures+="  $file -> $ref\n"
      fi
      count=$((count + 1))
    done < <(grep -oE '(workflows|skills|guides|patterns)/[a-zA-Z0-9._-]+\.md' "$file" \
             | sort -u)
  done < <(collect_markdown_files)

  # Ensure we actually checked something
  [ "$count" -gt 0 ] || { echo "No bare path references found — check test setup"; return 1; }

  if [ -n "$failures" ]; then
    echo "Broken bare path references:"
    echo -e "$failures"
    return 1
  fi
}
