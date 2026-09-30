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
#   scripts/run-tests.sh [--fast|--slow|--all] [--failed] [--jobs N] [FILE...]
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
#             It takes no category flag and no FILE: a narrowed re-run would
#             record only its own files, and the next --failed would then
#             miss failures outside them. Combining them is a usage error
#             (exit 2).
#             Exits 1 when no run is recorded or the last run's log does not
#             hold a result for every test it selected (see "Run logs"); 0
#             with a message naming the last run's scope when it had no
#             failures among the selected files.
#   --jobs N  Run up to N test files at once (see "Parallel runs"). N is 1
#             to 999, digits only, no leading zero; anything else is a usage
#             error (exit 2). 1, the default, runs serially; N above the
#             number of selected files is lowered to it. Combines with every
#             other flag, --failed included.
#   FILE...   Run only these .bats files (absolute, or relative to the repo
#             root, NOT the current directory; each must be under test/ once
#             every symlink in its path, the file's own included, is
#             resolved). A file named twice runs once. The category flags
#             filter them; the tag check and report gating apply as in a full
#             run.
#
# Run logs: every run records per-test results in .bats/ at the repo root
# (gitignored), which is what --failed reads. bats 1.8.2 puts its run-log
# directory next to the FIRST file it is handed, and records nothing when that
# directory is missing, so the runner always hands bats an empty anchor file,
# .bats/run-log-anchor, first: the log then lands in .bats/.bats/run-logs/
# whatever the selection. The runner then execs bats, so bats' exit status and
# signal handling are the runner's own.
#
# Just before the exec it writes .bats/last-run: the selected files, their
# test count (`bats --count`, which adds about 15 s to a full run) and the
# name of the newest log before the run. bats writes a log line per test as
# the test ends, so --failed accepts the newest log (the one bats' own
# --filter-status reads) only when it is not that previous log and holds a
# result (passed, failed or status-filtered) for exactly that many of the
# selected files' tests. A log falls short when the run was killed, is still
# going, a setup_file failed or a file did not parse (bats writes no line for
# those tests). It is no newer log when the run was killed before any test
# ended, or started in the same UTC second as the run before it (bats names
# logs by the second, and a run in the same second appends to that log or,
# with --failed, writes "<time>-1.log", which ranks below "<time>.log").
# --failed refuses all of these. Known limit: a failing teardown_file leaves
# every test's line in place, so --failed then says there is nothing to
# re-run although the run failed. bats deletes the log of a Ctrl-C run itself.
#
# Only one run at a time records in a checkout: the runner takes an flock on
# .bats/lock before reading or writing any of this, and bats inherits the
# lock's descriptor, so it is held until bats and every process it started
# have exited. A second run meanwhile exits 1. When .bats/ cannot be written
# (or flock is missing), the runner warns and runs without the lock or
# recording, and --failed exits 1.
#
# Locale: when the ambient locale (LC_ALL, else LANG) is not installed, every
# bash subprocess prints a setlocale warning to stderr, and bats' `run` folds
# that into the $output a test asserts on. The runner then exports
# LC_ALL=C.UTF-8 (C when that is missing too) and says so; a working locale
# is left alone. "Installed" is locale_installed in test/lib/hermetic-env.bash.
#
# Parallel runs: --jobs N (N > 1) hands bats `--jobs N
# --no-parallelize-within-files`, so whole files run side by side and the
# tests within a file stay serial, the only way the suites have ever run: no
# suite has been checked for tests that interfere when run at once. The
# slowest file bounds the speedup. Files still share the machine: install.sh's
# agent_gate, which install-host.bats runs, refuses when procs_in_checkout
# cannot read the working directory of a live process of the user (a
# non-dumpable one, say), and under --jobs other files' processes are live
# beside it.
# bats runs files through GNU parallel and aborts without it even for one
# file, so when the first `parallel` on PATH is missing or is not GNU
# parallel (moreutils ships one too), the runner warns and runs serially. It
# unsets $PARALLEL, so the user's parallel options do not reach bats' run.
# parallel's config files (~/.parallel/config, ~/.parallelrc,
# /etc/parallel/config and the like) still apply; one that breaks the run
# fails closed: bats reports fewer tests run than expected and exits 1, and
# --failed refuses that log.
# bats keeps each file's output together (parallel groups output by default)
# and in file order (--keep-order), so a file's results appear once it and
# every file before it have ended. Every test still writes its own run-log
# line, so the run log, the test-count check and --failed work as in a
# serial run. bats folds parallel's stderr into its output; the locale pin
# above keeps perl's setlocale warnings out of it, and upstream parallel
# prints its citation notice only when its stderr is a terminal, which inside
# bats it never is (Debian's build never prints it).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TEST_DIR="$REPO_ROOT/test"
RUN_LOG_ANCHOR="$REPO_ROOT/.bats/run-log-anchor"
RUN_LOG_DIR="$REPO_ROOT/.bats/.bats/run-logs"
RUN_LOCK="$REPO_ROOT/.bats/lock"
LAST_RUN="$REPO_ROOT/.bats/last-run"

usage() {
  echo "Usage: $0 [--fast|--slow|--all] [--failed] [--jobs N] [FILE...]" >&2
}

category="all"
category_set=false
failed_only=false
jobs=1
requested=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast)   category="fast"; category_set=true; shift ;;
    --slow)   category="slow"; category_set=true; shift ;;
    --all)    category="all";  category_set=true; shift ;;
    --failed) failed_only=true; shift ;;
    --jobs)
      # At most 3 digits, so the value never overflows bash arithmetic and
      # parallel never sizes thousands of job slots.
      if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then
        echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}" >&2
        usage
        exit 2
      fi
      jobs="$2"
      shift 2
      ;;
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

if [[ "$failed_only" == true ]] && { [[ "$category_set" == true ]] || [[ ${#requested[@]} -gt 0 ]]; }; then
  echo "--failed re-runs every failure of the last run and takes no --fast/--slow/--all or FILE" >&2
  usage
  exit 2
fi

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
    # Fully resolved (directory and file symlinks alike), so a symlink cannot
    # lead out of test/ and an alias path to a real suite is accepted.
    path="$(realpath -e -- "$path")"
    if [[ "$path" != "$(realpath -e -- "$TEST_DIR")"/* ]]; then
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

# newest_log: the name of the newest run log, as bats picks it (the first of
# `ls -1r`); empty when there is none. `sed -n 1p` reads all of its input, so
# a long listing cannot SIGPIPE sort under pipefail (`head -n1` did).
newest_log() {
  [[ -d "$RUN_LOG_DIR" ]] || return 0
  find "$RUN_LOG_DIR" -maxdepth 1 -type f -name '*.log' -printf '%f\n' | sort -r | sed -n 1p
}

# --- Lock and recording -----------------------------------------------------
# See "Run logs" in the header. The lock is taken before --failed reads the
# log, so it never reads one a concurrent run is still writing.
recording=false
if command -v flock > /dev/null && mkdir -p "$RUN_LOG_DIR" 2>/dev/null &&
   { : > "$RUN_LOG_ANCHOR"; } 2>/dev/null && { exec 9> "$RUN_LOCK"; } 2>/dev/null; then
  if ! flock -n 9; then
    echo "another run-tests.sh run is in progress in this checkout" >&2
    exit 1
  fi
  recording=true
elif [[ "$failed_only" == true ]]; then
  echo "ERROR: --failed: cannot write the run log under ${RUN_LOG_DIR#"$REPO_ROOT"/} (or flock is missing)" >&2
  exit 1
else
  echo "WARNING: cannot write ${RUN_LOG_DIR#"$REPO_ROOT"/} (or flock is missing); running without recording (--failed will not see this run)" >&2
fi

# --failed needs a complete recorded run, whatever the selection and gating
# below leave, and reads the log bats' --filter-status will read.
if [[ "$failed_only" == true ]]; then
  last_log="$(newest_log)"
  if [[ -z "$last_log" || ! -f "$LAST_RUN" ]]; then
    echo "--failed: no recorded run in ${RUN_LOG_DIR#"$REPO_ROOT"/}; run the tests without --failed first" >&2
    exit 1
  fi
  expected="$(sed -n 's/^expected=//p' "$LAST_RUN")"
  prev_log="$(sed -n 's/^prev-log=//p' "$LAST_RUN")"
  if [[ "$last_log" == "$prev_log" ]]; then
    echo "--failed: the last run left no log of its own (killed before any test ended, or started in the same second as the run before it); run the full selection without --failed" >&2
    exit 1
  fi
  # Distinct tests of the last run's files with a result line. Lines are
  # "<state> <absolute file>\t<test id>", <state> being passed, failed or
  # "status-filtered failed"; bats may repeat a status-filtered line, and
  # carries over ones for files outside this run.
  recorded="$(sed -nE 's/^(passed|failed|status-filtered [a-z]+) //p' "$RUN_LOG_DIR/$last_log" |
    awk -F'\t' 'NR == FNR { want[$0] = 1; next } ($1 in want)' <(sed '1,2d' "$LAST_RUN") - |
    sort -u | wc -l)"
  if [[ ! "$expected" =~ ^[0-9]+$ || "$recorded" -ne "$expected" ]]; then
    echo "--failed: the last run ($last_log) recorded $recorded of ${expected:-?} tests: it did not complete, or a setup_file failed or a file did not parse; run the full selection without --failed" >&2
    exit 1
  fi
  last_scope="$(sed '1,2d' "$LAST_RUN" | wc -l)"
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

# --failed: keep the files with a failure in the last run. Its log holds a
# line for every test of every file it covered (checked above): passed,
# failed, or status-filtered (skipped by an earlier --failed because it had
# passed). So "has a failed line" is exactly bats' "did not pass". Files the
# last run did not cover are out of its scope and left out.
if [[ "$failed_only" == true && -n "$matched" ]]; then
  # Log lines are "failed <absolute file>\t<test id>".
  failed_files="$(sed -n 's/^failed //p' "$RUN_LOG_DIR/$last_log" | cut -f1 | sort -u)"
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
# See "Parallel runs" in the header. N is first lowered to the file count,
# so a one-file run needs no parallel. Otherwise bats aborts without GNU
# parallel, so that is what is checked: the first `parallel` on PATH, the one
# bats runs, with --plain so the user's parallel config cannot fail the check.
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
if [[ "$jobs" -gt 1 ]]; then
  unset PARALLEL
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially" >&2
  fi
fi

if [[ "$recording" == true ]]; then
  bats_args+=("$RUN_LOG_ANCHOR")
  # See "Run logs" in the header. A count bats cannot give is recorded as "?",
  # which --failed refuses.
  expected="$(bats --count "${files[@]}" 2>/dev/null)" || expected="?"
  {
    echo "expected=$expected"
    echo "prev-log=$(newest_log)"
    printf '%s\n' "${files[@]}"
  } > "$LAST_RUN"
fi

# Pass all matched files to bats in a single invocation for proper TAP output,
# the (test-free) run-log anchor first — see "Run logs" in the header. fd 9
# (the lock) stays open in bats.
exec bats "${bats_args[@]}" "${files[@]}"
