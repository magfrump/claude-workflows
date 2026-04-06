#!/usr/bin/env bash
# Test runner that selectively executes BATS tests by category.
# Each .bats file must contain a "# @category fast|slow" tag comment.
#
# Usage:
#   scripts/run-tests.sh [--fast|--slow|--all]
#
# Flags:
#   --fast  Run only fast tests (pure function tests, <1s each)
#   --slow  Run only slow tests (integration tests, script execution / file I/O)
#   --all   Run all tests (default)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$REPO_ROOT/test"

category="all"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast) category="fast"; shift ;;
    --slow) category="slow"; shift ;;
    --all)  category="all";  shift ;;
    -h|--help)
      sed -n '2,/^$/{ s/^# //; s/^#$//; p }' "$0"
      exit 0
      ;;
    *)
      echo "Unknown flag: $1" >&2
      echo "Usage: $0 [--fast|--slow|--all]" >&2
      exit 1
      ;;
  esac
done

# Collect .bats files matching the requested category.
collect_tests() {
  local wanted="$1"
  local files=()

  while IFS= read -r -d '' file; do
    # Extract the @category tag from the file (first match only)
    local tag
    tag=$(grep -m1 '^# @category ' "$file" 2>/dev/null | sed 's/^# @category //' || true)

    if [[ -z "$tag" ]]; then
      echo "WARNING: no @category tag in $file — skipping" >&2
      continue
    fi

    if [[ "$wanted" == "all" || "$tag" == "$wanted" ]]; then
      files+=("$file")
    fi
  done < <(find "$TEST_DIR" -name '*.bats' -print0 | sort -z)

  printf '%s\n' "${files[@]}"
}

files=$(collect_tests "$category")

if [[ -z "$files" ]]; then
  echo "No test files matched category: $category" >&2
  exit 1
fi

echo "=== Running $category tests ==="
echo "$files" | while read -r f; do
  echo "  $(basename "$f")"
done
echo ""

# Pass all matched files to bats in a single invocation for proper TAP output.
# shellcheck disable=SC2086
exec bats $files
