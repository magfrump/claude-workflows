#!/usr/bin/env bats
# Validates that every guide in guides/ is listed in guides/README.md.
# Prevents drift when new guides are added without updating the index.
#
# Usage: bats test/guide-index-sync.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  GUIDES_DIR="$REPO_ROOT/guides"
  INDEX="$GUIDES_DIR/README.md"
}

@test "every guide in guides/ is linked from guides/README.md" {
  local missing=""
  local checked=0

  for file in "$GUIDES_DIR"/*.md; do
    local basename
    basename=$(basename "$file")

    # Skip the index itself
    [ "$basename" = "README.md" ] && continue

    checked=$((checked + 1))

    # Check that the filename appears as a markdown link in the index
    if ! grep -q "($basename)" "$INDEX"; then
      missing+="  $basename"$'\n'
    fi
  done

  # Guard: ensure we actually found guides to check
  [ "$checked" -gt 0 ] || {
    echo "No guide files found — check test setup"
    return 1
  }

  if [ -n "$missing" ]; then
    echo "Guides not linked in guides/README.md ($checked checked):"
    echo "$missing"
    return 1
  fi
}
