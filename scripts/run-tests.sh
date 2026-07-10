#!/usr/bin/env bash
# Test runner that selectively executes BATS tests by category.
# Each .bats file must contain a "# @category fast|slow" tag comment.
#
# Hermeticity convention (enforced by test/fixture-hermeticity.bats):
# a suite whose code — including sourced/executed repo scripts — can invoke
# a network-capable binary (claude, curl, wget, gh) must stub it in setup()
# (create the binary under a test-local dir prepended to PATH), or opt out
# with "# @network: allowed — <reason>" in its first 15 lines.
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

matched=$(collect_tests "$category")

if [[ -z "$matched" ]]; then
  echo "No test files matched category: $category" >&2
  exit 1
fi

# Report-gating (mirrors scripts/health-check.sh): the *-format.bats and
# *-eval.bats suites validate skill report output. They only carry signal when
# a freshly generated report exists under test/skills/<skill>/output/; without
# one they would fall back to stale committed docs/reviews/ artifacts and report
# spurious failures. So unless generated reports are present, drop that class
# from the run — exactly as health-check does — rather than asserting against
# out-of-date defaults. Generate reports via test/skills/generate-reports.bash
# to exercise them.
has_reports=false
for output_dir in "$REPO_ROOT"/test/skills/*/output/; do
  if [[ -d "$output_dir" ]] && ls "$output_dir"/*.md &>/dev/null 2>&1; then
    has_reports=true
    break
  fi
done

if ! $has_reports; then
  filtered=""
  skipped=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$(basename "$f")" in
      *-format.bats|*-eval.bats) skipped=$((skipped + 1)) ;;
      *) filtered+="$f"$'\n' ;;
    esac
  done <<< "$matched"
  matched="${filtered%$'\n'}"
  if [[ "$skipped" -gt 0 ]]; then
    echo "Note: skipping $skipped report-dependent suite(s) (*-format/*-eval) —" \
         "no generated reports under test/skills/*/output/." >&2
    echo "      Run test/skills/generate-reports.bash to exercise them." >&2
    echo "" >&2
  fi
  if [[ -z "$matched" ]]; then
    echo "No runnable test files after report-gating for category: $category" >&2
    exit 0
  fi
fi

echo "=== Running $category tests ==="
echo "$matched" | while read -r f; do
  echo "  $(basename "$f")"
done
echo ""

# Pass all matched files to bats in a single invocation for proper TAP output.
# shellcheck disable=SC2086
exec bats $matched
