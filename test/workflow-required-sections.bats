#!/usr/bin/env bats

# Validates that every workflow .md file contains required structural sections.
# Catches accidental removal of section headers during refactors or merges.

WORKFLOWS_DIR="$BATS_TEST_DIRNAME/../workflows"

setup() {
  # Dynamically discover all workflow markdown files
  WORKFLOW_FILES=()
  while IFS= read -r -d '' file; do
    WORKFLOW_FILES+=("$file")
  done < <(find "$WORKFLOWS_DIR" -name '*.md' -print0 | sort -z)

  if [ ${#WORKFLOW_FILES[@]} -eq 0 ]; then
    skip "No workflow files found in $WORKFLOWS_DIR"
  fi
}

@test "all workflow files contain '## When to use' section" {
  local failures=()

  for file in "${WORKFLOW_FILES[@]}"; do
    local name
    name="$(basename "$file")"
    if ! grep -q '^## When to use' "$file"; then
      failures+=("$name")
    fi
  done

  if [ ${#failures[@]} -gt 0 ]; then
    echo "Files missing '## When to use' section:"
    printf '  - %s\n' "${failures[@]}"
    return 1
  fi
}

@test "all workflow files contain a process section (## Process or ## Phase/Step N)" {
  local failures=()

  for file in "${WORKFLOW_FILES[@]}"; do
    local name
    name="$(basename "$file")"
    if ! grep -qE '^## (Process|Phase [0-9]|Step [0-9])' "$file"; then
      failures+=("$name")
    fi
  done

  if [ ${#failures[@]} -gt 0 ]; then
    echo "Files missing a process section (## Process, ## Phase N, or ## Step N):"
    printf '  - %s\n' "${failures[@]}"
    return 1
  fi
}

@test "at least one workflow file is discovered" {
  # Guard test: ensures dynamic discovery is working
  [ ${#WORKFLOW_FILES[@]} -gt 0 ]
}
