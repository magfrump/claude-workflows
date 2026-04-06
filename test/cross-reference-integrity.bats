#!/usr/bin/env bats
# @category fast
# Validates that markdown cross-references between content directories
# (workflows/, skills/, guides/, patterns/) point to files that exist.
#
# Simplified approach: only checks explicit markdown links [text](path)
# where the link target contains a known content directory prefix.
#
# Usage: bats test/cross-reference-integrity.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  CONTENT_DIRS=(workflows skills guides patterns)
}

@test "explicit markdown links to content directories resolve to existing files" {
  local failures=""
  local checked=0

  for dir in "${CONTENT_DIRS[@]}"; do
    local full="$REPO_ROOT/$dir"
    [ -d "$full" ] || continue

    while IFS= read -r file; do
      # Extract link targets from [text](target) — one per line
      # grep -o gives each match; sed strips the markdown wrapper
      local targets
      targets=$(grep -o '\[[^]]*\]([^)]*)' "$file" \
                | sed 's/.*](//' | sed 's/)$//' \
                | grep -v '^https\{0,1\}://' \
                | grep -v '^#' \
                | grep -E '(workflows|skills|guides|patterns)/' \
                || true)

      [ -z "$targets" ] && continue

      while IFS= read -r target; do
        # Strip anchor fragment
        local path="${target%%#*}"
        [ -z "$path" ] && continue

        # Resolve relative to source file's directory
        local source_dir
        source_dir=$(dirname "$file")
        local resolved
        resolved=$(cd "$source_dir" && realpath -m "$path" 2>/dev/null)

        if [ ! -f "$resolved" ]; then
          failures+="  $file -> $target (resolved: $resolved)"$'\n'
        fi
        checked=$((checked + 1))
      done <<< "$targets"
    done < <(find "$full" -name '*.md' -type f)
  done

  # Guard: ensure we actually found links to check
  [ "$checked" -gt 0 ] || {
    echo "No content-directory links found — check test setup"
    return 1
  }

  if [ -n "$failures" ]; then
    echo "Broken markdown links ($checked checked):"
    echo "$failures"
    return 1
  fi
}
