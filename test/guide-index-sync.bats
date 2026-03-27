#!/usr/bin/env bats
# Validates that every *.md file in guides/ (except README.md) appears as a
# markdown link in guides/README.md.  Catches drift when a new guide is added
# to the directory but not to the index.
#
# Usage: bats test/guide-index-sync.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  GUIDES_DIR="$REPO_ROOT/guides"
  INDEX="$GUIDES_DIR/README.md"
}

@test "guides/README.md exists" {
  [ -f "$INDEX" ]
}

@test "every guide file is linked in guides/README.md" {
  local missing=""
  local checked=0

  for file in "$GUIDES_DIR"/*.md; do
    local name
    name=$(basename "$file")
    [ "$name" = "README.md" ] && continue

    checked=$((checked + 1))

    # Check for a markdown link containing the filename, e.g. (filename.md)
    if ! grep -qF "($name)" "$INDEX"; then
      missing+="  $name"$'\n'
    fi
  done

  # Guard: ensure we actually found guide files to check
  [ "$checked" -gt 0 ] || {
    echo "No guide files found in $GUIDES_DIR — check test setup"
    return 1
  }

  if [ -n "$missing" ]; then
    echo "Guide files not linked in guides/README.md ($checked checked):"
    echo "$missing"
    return 1
  fi
}
