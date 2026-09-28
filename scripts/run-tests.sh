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
#   scripts/run-tests.sh [--fast|--slow|--all] [--failed] [FILE...]
#
# Environment:
#   RUN_TESTS_NOT_RUN_FILE  When set, the number of report-dependent suites
#                           gated out is written to this file.
#
# Flags:
#   --fast    Run only fast tests (pure function tests, <1s each)
#   --slow    Run only slow tests (integration tests, script execution / file I/O)
#   --all     Run all tests (default)
#   --failed  Re-run only the tests that failed in the last completed run
#             (bats --filter-status failed). Combines with the category flags
#             and FILE... to narrow further. Exits 1 when no run is recorded,
#             0 with a message when the last run had no failures in scope.
#   FILE...   Run only these .bats files (absolute, or relative to the repo
#             root; each must be under test/). The category flags filter them;
#             the tag check and report gating apply as in a full run.
#
# Run logs: every run records per-test results in .bats/ at the repo root
# (gitignored), which is what --failed reads. bats 1.8.2 puts its run-log
# directory next to the FIRST file it is handed, and records nothing when that
# directory is missing, so the runner always hands bats an empty anchor file,
# .bats/run-log-anchor, first: the log then lands in .bats/.bats/run-logs/
# whatever the selection. An interrupted (Ctrl-C) run is not recorded.
#
# Locale: when the ambient locale (LC_ALL, else LANG) is not installed, every
# bash subprocess prints a setlocale warning to stderr, and bats' `run` folds
# that into the $output a test asserts on. The runner then exports
# LC_ALL=C.UTF-8 (C when that is missing too) and says so; a working locale
# is left alone. "Installed" is locale_installed in test/lib/hermetic-env.bash.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$REPO_ROOT/test"
RUN_LOG_ANCHOR="$REPO_ROOT/.bats/run-log-anchor"
RUN_LOG_DIR="$REPO_ROOT/.bats/.bats/run-logs"

usage() {
  echo "Usage: $0 [--fast|--slow|--all] [--failed] [FILE...]" >&2
}

category="all"
failed_only=false
requested=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast)   category="fast"; shift ;;
    --slow)   category="slow"; shift ;;
    --all)    category="all";  shift ;;
    --failed) failed_only=true; shift ;;
    -h|--help)
      sed -n '2,/^$/{ s/^# //; s/^#$//; p }' "$0"
      exit 0
      ;;
    --) shift; requested+=("$@"); break ;;
    -*)
      echo "Unknown flag: $1" >&2
      usage
      exit 1
      ;;
    *) requested+=("$1"); shift ;;
  esac
done

# --- Locale pin -------------------------------------------------------------
# shellcheck source=../test/lib/hermetic-env.bash
source "$TEST_DIR/lib/hermetic-env.bash"
ambient_locale="${LC_ALL:-${LANG:-}}"
if ! locale_installed "$ambient_locale"; then
  pinned=C
  locale_installed C.UTF-8 && pinned=C.UTF-8
  export LC_ALL="$pinned"
  echo "Locale $ambient_locale is not installed; running with LC_ALL=$pinned"
fi

# --- Candidate files --------------------------------------------------------
# FILE... when given, else every .bats under test/.
candidates=()
if [[ ${#requested[@]} -gt 0 ]]; then
  for arg in "${requested[@]}"; do
    path="$arg"
    [[ "$path" == /* ]] || path="$REPO_ROOT/$path"
    if [[ ! -f "$path" || "$path" != *.bats ]]; then
      echo "ERROR: no such test file: $arg" >&2
      exit 1
    fi
    path="$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    if [[ "$path" != "$TEST_DIR"/* ]]; then
      echo "ERROR: not under test/: $arg" >&2
      exit 1
    fi
    candidates+=("$path")
  done
else
  while IFS= read -r -d '' file; do
    candidates+=("$file")
  done < <(find "$TEST_DIR" -name '*.bats' -print0 | sort -z)
fi

# Keep the candidates matching the requested category.
collect_tests() {
  local wanted="$1"
  local files=() untagged=() file

  for file in "${candidates[@]}"; do
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
  done

  if [[ ${#untagged[@]} -gt 0 ]]; then
    printf 'ERROR: no "# @category fast|slow" tag in %s\n' "${untagged[@]}" >&2
    return 1
  fi

  [[ ${#files[@]} -eq 0 ]] || printf '%s\n' "${files[@]}"
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
# (reports are trackable once generated; Q-071 [1]).
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

# --failed: keep only the files with a failure in the last recorded run. bats
# picks the previous log as the first of `ls -1r` in the log directory; the
# same pick here, so the file selection and bats' test filter read one log.
if [[ "$failed_only" == true && -n "$matched" ]]; then
  last_log=""
  if [[ -d "$RUN_LOG_DIR" ]]; then
    last_log="$(find "$RUN_LOG_DIR" -maxdepth 1 -type f -name '*.log' -printf '%f\n' | sort -r | head -n1)"
  fi
  if [[ -z "$last_log" ]]; then
    echo "--failed: no recorded run in ${RUN_LOG_DIR#"$REPO_ROOT"/}; run the tests without --failed first" >&2
    exit 1
  fi
  # Log lines are "failed <absolute file>\t<test id>".
  failed_files="$(grep '^failed ' "$RUN_LOG_DIR/$last_log" | cut -f1 | sed 's/^failed //' | sort -u || true)"
  kept=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qxF "$f" <<< "$failed_files"; then
      kept+="$f"$'\n'
    fi
  done <<< "$matched"
  matched="${kept%$'\n'}"
  if [[ -z "$matched" ]]; then
    echo "--failed: no failed tests in the last recorded run ($last_log) among the selected files; nothing to re-run"
    exit 0
  fi
fi

if [[ -z "$matched" ]]; then
  echo "No runnable test files after report-gating for category: $category"
  exit 0
fi

if [[ "$failed_only" == true ]]; then
  echo "=== Re-running failed $category tests ==="
else
  echo "=== Running $category tests ==="
fi
echo "$matched" | while read -r f; do
  echo "  $(basename "$f")"
done
echo ""

mkdir -p "$RUN_LOG_DIR"
: > "$RUN_LOG_ANCHOR"
bats_args=()
[[ "$failed_only" == true ]] && bats_args+=(--filter-status failed)
mapfile -t files <<< "$matched"

# Pass all matched files to bats in a single invocation for proper TAP output,
# the (test-free) run-log anchor first — see "Run logs" in the header.
exec bats "${bats_args[@]}" "$RUN_LOG_ANCHOR" "${files[@]}"
