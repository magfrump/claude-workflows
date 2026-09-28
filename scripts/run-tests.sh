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
#   --failed  Re-run, in the files the last recorded run covered, only the
#             tests that did not pass in it (bats --filter-status failed).
#             Combines with the category flags and FILE... to narrow further.
#             Exits 1 when no run is recorded or the last run did not
#             complete; 0 with a message naming the last run's scope when it
#             had no failures among the selected files.
#   FILE...   Run only these .bats files (absolute, or relative to the repo
#             root, NOT the current directory; each must be under test/, after
#             resolving symlinks). A file named twice runs once. The category
#             flags filter them; the tag check and report gating apply as in a
#             full run.
#
# Run logs: every run records per-test results in .bats/ at the repo root
# (gitignored), which is what --failed reads. bats 1.8.2 puts its run-log
# directory next to the FIRST file it is handed, and records nothing when that
# directory is missing, so the runner always hands bats an empty anchor file,
# .bats/run-log-anchor, first: the log then lands in .bats/.bats/run-logs/
# whatever the selection. When bats exits on its own (pass or fail), the
# runner appends "# run-tests: complete files=<n>" to the log it wrote (bats
# skips "#" lines); a log without that last line is from a run that was killed
# or is still going, and --failed refuses it. bats deletes the log of a Ctrl-C
# run itself. bats names logs by the UTC second: runs started in the same
# second share one log, or (with --failed) get "<time>-1.log", which both bats
# and the runner rank below "<time>.log", so sub-second reruns can read the
# older log. When .bats/ cannot be written the runner warns and runs without
# recording (--failed then exits 1).
#
# Locale: when the ambient locale (LC_ALL, else LANG) is not installed, every
# bash subprocess prints a setlocale warning to stderr, and bats' `run` folds
# that into the $output a test asserts on. The runner then exports
# LC_ALL=C.UTF-8 (C when that is missing too) and says so; a working locale
# is left alone. "Installed" is locale_installed in test/lib/hermetic-env.bash.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TEST_DIR="$REPO_ROOT/test"
RUN_LOG_ANCHOR="$REPO_ROOT/.bats/run-log-anchor"
RUN_LOG_DIR="$REPO_ROOT/.bats/.bats/run-logs"
COMPLETE_MARK="# run-tests: complete files="

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
  declare -A seen=()
  for arg in "${requested[@]}"; do
    path="$arg"
    [[ "$path" == /* ]] || path="$REPO_ROOT/$path"
    if [[ ! -f "$path" ]]; then
      echo "ERROR: no such test file: $arg" >&2
      exit 1
    fi
    if [[ "$path" != *.bats ]]; then
      echo "ERROR: not a .bats file: $arg" >&2
      exit 1
    fi
    # Physical path, so a symlink cannot lead out of test/ and an alias path
    # to a real suite is accepted.
    path="$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")"
    if [[ "$path" != "$TEST_DIR"/* ]]; then
      echo "ERROR: not under test/: $arg" >&2
      exit 1
    fi
    [[ -n "${seen[$path]:-}" ]] && continue
    seen[$path]=1
    candidates+=("$path")
  done
else
  while IFS= read -r -d '' file; do
    candidates+=("$file")
  done < <(find "$TEST_DIR" -name '*.bats' -print0 | sort -z)
fi

# --failed needs a completed recorded run, whatever the selection and gating
# below leave. bats picks the previous log as the first of `ls -1r` in the log
# directory; the same pick here, so the file selection and bats' test filter
# read one log.
if [[ "$failed_only" == true ]]; then
  last_log=""
  if [[ -d "$RUN_LOG_DIR" ]]; then
    last_log="$(find "$RUN_LOG_DIR" -maxdepth 1 -type f -name '*.log' -printf '%f\n' | sort -r | head -n1)"
  fi
  if [[ -z "$last_log" ]]; then
    echo "--failed: no recorded run in ${RUN_LOG_DIR#"$REPO_ROOT"/}; run the tests without --failed first" >&2
    exit 1
  fi
  last_line="$(tail -n1 "$RUN_LOG_DIR/$last_log")"
  if [[ "$last_line" != "$COMPLETE_MARK"* ]]; then
    echo "--failed: the last run ($last_log) did not complete (killed, or still running); run the full selection without --failed" >&2
    exit 1
  fi
  last_scope="${last_line#"$COMPLETE_MARK"}"
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

# --failed: keep the files with a failure in the last run. That run completed
# (checked above), so each test of each file it covered has a line: passed,
# failed, or status-filtered (skipped by an earlier --failed because it had
# passed). So "has a failed line" is exactly bats' "did not pass". Files the
# last run did not cover are out of its scope and left out.
if [[ "$failed_only" == true && -n "$matched" ]]; then
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
    echo "--failed: no failed tests among the selected files in the last recorded run ($last_log, $last_scope file(s)); nothing to re-run"
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

mapfile -t files <<< "$matched"
bats_args=()
[[ "$failed_only" == true ]] && bats_args+=(--filter-status failed)

# Set up recording: the log directory, the anchor, and a start stamp that
# tells this run's log apart from older ones afterwards.
start_stamp=""
if mkdir -p "$RUN_LOG_DIR" 2>/dev/null && { : > "$RUN_LOG_ANCHOR"; } 2>/dev/null &&
   start_stamp="$(mktemp "$REPO_ROOT/.bats/run-start.XXXXXX" 2>/dev/null)"; then
  bats_args+=("$RUN_LOG_ANCHOR")
else
  if [[ "$failed_only" == true ]]; then
    echo "ERROR: --failed: cannot write the run log under ${RUN_LOG_DIR#"$REPO_ROOT"/}" >&2
    exit 1
  fi
  echo "WARNING: cannot write ${RUN_LOG_DIR#"$REPO_ROOT"/}; running without recording (--failed will not see this run)" >&2
fi

# Pass all matched files to bats in a single invocation for proper TAP output,
# the (test-free) run-log anchor first — see "Run logs" in the header.
#
# bats runs as a child, not via exec, so the runner can mark the log complete
# afterwards. A background child lets the traps below run at once (a trap
# waits for a foreground child to finish): the runner forwards INT/TERM/HUP to
# bats, so `timeout` or a kill of the runner still stops bats as it did under
# exec. Without job control a background command ignores SIGINT, so env
# restores the default before bats sets its own Ctrl-C handler; `<&0` keeps
# the runner's stdin (a background command otherwise reads /dev/null).
# Ctrl-C at a terminal reaches bats twice (directly and forwarded); its
# handler only sets a flag, so that is harmless.
signalled=""
env --default-signal=INT,QUIT bats "${bats_args[@]}" "${files[@]}" <&0 &
bats_pid=$!
# shellcheck disable=SC2317  # invoked from the traps below
forward() {
  signalled="$1"
  kill -s "$1" "$bats_pid" 2>/dev/null || true
}
trap 'forward INT' INT
trap 'forward TERM' TERM
trap 'forward HUP' HUP
status=0
while :; do
  interrupted="$signalled"
  status=0
  wait "$bats_pid" || status=$?
  # A trap cuts `wait` short while bats is still running; wait again.
  [[ "$signalled" != "$interrupted" ]] || break
done
trap - INT TERM HUP

if [[ -n "$start_stamp" ]]; then
  # bats exited on its own (a status above 128 means a signal ended it):
  # mark the log it wrote. No log newer than the stamp means bats recorded
  # nothing (e.g. it deleted the log of a Ctrl-C run).
  if [[ -z "$signalled" && "$status" -lt 128 ]]; then
    log="$(find "$RUN_LOG_DIR" -maxdepth 1 -type f -name '*.log' -newer "$start_stamp" -printf '%T@ %p\n' |
      sort -rn | head -n1 | cut -d' ' -f2-)"
    [[ -z "$log" ]] || echo "$COMPLETE_MARK${#files[@]}" >> "$log"
  fi
  rm -f "$start_stamp"
fi
exit "$status"
