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
# Report-dependent suites carry "# @needs-reports <skill>" and run only when
# that skill has generated reports; the rest are listed as NOT RUN (see
# "Report gating" below).
#
# Usage:
#   scripts/run-tests.sh [--fast|--slow|--all]
#
# Environment:
#   RUN_TESTS_NOT_RUN_FILE  When set, the number of report-dependent suites
#                           gated out is written to this file.
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
  local files=() untagged=()

  while IFS= read -r -d '' file; do
    # Extract the @category tag from the file (first match only)
    local tag
    tag=$(grep -m1 '^# @category ' "$file" 2>/dev/null | sed 's/^# @category //' || true)

    # An untagged suite used to be skipped with a warning, which left two
    # suites unrun by every runner. Collect them and fail below instead.
    if [[ -z "$tag" ]]; then
      untagged+=("$file")
      continue
    fi

    if [[ "$wanted" == "all" || "$tag" == "$wanted" ]]; then
      files+=("$file")
    fi
  done < <(find "$TEST_DIR" -name '*.bats' -print0 | sort -z)

  if [[ ${#untagged[@]} -gt 0 ]]; then
    printf 'ERROR: no "# @category fast|slow" tag in %s\n' "${untagged[@]}" >&2
    return 1
  fi

  printf '%s\n' "${files[@]}"
}

matched=$(collect_tests "$category") || exit 1

if [[ -z "$matched" ]]; then
  echo "No test files matched category: $category" >&2
  exit 1
fi

# Report gating, per skill. A suite that grades generated skill reports carries
# "# @needs-reports <skill>" in its first 15 lines; it runs only when that skill's
# test/skills/<skill>/output/ holds a generated report (skill_has_reports in
# test/skills/runner-contract.bash, the definition the suites themselves use).
# Gating by tag, not filename: arithmetic-eval-format.bats lints SKILL.md and
# needs no report, so it always runs; and per skill, not globally, so one
# skill's reports never switch on another skill's suites to fail or skip.
#
# A gated-out suite is not a failure (reports are model runs, generated on
# purpose), but it is not a pass either: every one is listed as NOT RUN on
# stdout, and the count is written to $RUN_TESTS_NOT_RUN_FILE when that is set
# (scripts/health-check.sh reads it to warn). Generate reports with
# test/skills/generate-reports.bash <skill> and commit what it writes to output/
# (reports are tracked; Q-071 [1]).
# shellcheck source=../test/skills/runner-contract.bash
source "$TEST_DIR/skills/runner-contract.bash"

filtered=""
not_run=()
bad_tags=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  # Header only (first 15 lines, as for @network), so a suite whose body writes
  # a tagged fake suite in a heredoc is not itself gated.
  needs=$(head -15 "$f" | grep -m1 -E '^# @needs-reports( |$)' || true)
  if [[ -z "$needs" ]]; then
    filtered+="$f"$'\n'
    continue
  fi
  skill="${needs#\# @needs-reports}"
  skill="${skill//[[:space:]]/}"
  # A misspelled skill would keep the suite out of every run for good.
  if [[ -z "$skill" || ! -f "$REPO_ROOT/skills/$skill/SKILL.md" ]]; then
    bad_tags+=("$f")
    continue
  fi
  if skill_has_reports "$TEST_DIR/skills" "$skill"; then
    filtered+="$f"$'\n'
  else
    not_run+=("${f#"$TEST_DIR"/} [$skill]")
  fi
done <<< "$matched"
matched="${filtered%$'\n'}"

if [[ ${#bad_tags[@]} -gt 0 ]]; then
  printf 'ERROR: "# @needs-reports <skill>" must name a skill with skills/<skill>/SKILL.md in %s\n' "${bad_tags[@]}" >&2
  exit 1
fi

if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi

if [[ ${#not_run[@]} -gt 0 ]]; then
  echo "=== NOT RUN: ${#not_run[@]} report-dependent suite(s) — no generated reports for their skill ==="
  printf '  %s\n' "${not_run[@]}"
  echo "  Generate with: bash test/skills/generate-reports.bash <skill>"
  echo ""
fi

if [[ -z "$matched" ]]; then
  echo "No runnable test files after report-gating for category: $category"
  exit 0
fi

echo "=== Running $category tests ==="
echo "$matched" | while read -r f; do
  echo "  $(basename "$f")"
done
echo ""

# Pass all matched files to bats in a single invocation for proper TAP output.
# shellcheck disable=SC2086
exec bats $matched
