# The runner.bash contract, shared by generate-reports.bash and the fast test
# that checks every committed runner (test/generate-reports.bats), so a bad
# runner fails before a paid claude run rather than during one.
#
# Load with: source runner-contract.bash
# Then: reset_runner_settings; source <runner.bash>; check_runner_settings <label>
# REPO_ROOT must be set before a runner is sourced: some runners read it at
# source time (ai-personas-critique's persona catalog path).

# Tools a fixture run may be granted. Anything else, including a spelling the
# CLI would also accept ("Read, Write", "Write(*)", "Bash"), is refused: this is
# an allowlist, not a Write/Edit denylist. Sub-agents inherit the session's
# --tools (checked by a canary probe on 2026-09-24: a general-purpose sub-agent
# under --tools Agent got "No such tool available: Read ... in subagents as
# well as here"), so Agent adds dispatch, not file access.
RUNNER_ALLOWED_TOOLS=(Read Grep Glob WebSearch WebFetch Agent)

# Bash is the one exception, and only as FIXTURE_BASH=deny-record (Q-063 [1]):
# the model is offered Bash, generate-reports.bash pins every call to be
# denied (its DENY_RECORD_FLAGS), and the kept transcript records the command
# it tried, which eval checks compare with a reference. Any other Bash grant,
# and any Bash(<pattern>) spelling, is still refused.

# Clear the settings a runner is expected to set, so a runner that forgets a
# required one fails check_runner_settings instead of inheriting a previous
# runner's value, and optional ones fall back to their defaults.
reset_runner_settings() {
  FIXTURE_TOOLS=""
  FIXTURE_MODE=""
  FIXTURE_TRANSCRIPT=""
  FIXTURE_BASH=""
  unset -f fixture_prompt fixture_base 2>/dev/null || true
}

# Validate the settings a sourced runner left behind. Prints the first problem
# and returns 1. On success, normalizes FIXTURE_TRANSCRIPT to 0 or 1.
# Args: $1 = label for messages (usually the runner's path)
check_runner_settings() {
  local label="$1"
  if [ -z "$FIXTURE_TOOLS" ] || ! declare -F fixture_prompt >/dev/null; then
    echo "Error: $label: must set FIXTURE_TOOLS and define fixture_prompt" >&2
    return 1
  fi

  case "$FIXTURE_MODE" in
    inline|repo|tree) ;;
    *)
      echo "Error: $label: FIXTURE_MODE must be inline, repo or tree, got '$FIXTURE_MODE'" >&2
      return 1
      ;;
  esac

  # Checked before the tools loop, which reads it, so a misspelling such as
  # deny_record is reported as itself (review iteration 2, C19), and so every
  # wrong FIXTURE_TOOLS under deny-record gets the one message below (C26).
  case "$FIXTURE_BASH" in
    "") ;;
    deny-record)
      # Exactly Bash: the pinned dontAsk mode applies to every tool, and only
      # Bash's denial is probed and tripwired (review C9).
      if [ "$FIXTURE_TOOLS" != "Bash" ]; then
        echo "Error: $label: FIXTURE_BASH=deny-record needs FIXTURE_TOOLS=Bash exactly, got '$FIXTURE_TOOLS'" >&2
        return 1
      fi
      ;;
    *)
      echo "Error: $label: FIXTURE_BASH must be empty or deny-record, got '$FIXTURE_BASH'" >&2
      return 1
      ;;
  esac

  if [ "$FIXTURE_TOOLS" != "none" ]; then
    # Tool names joined by single commas: no spaces, no empty entries.
    if ! [[ "$FIXTURE_TOOLS" =~ ^[A-Za-z]+(,[A-Za-z]+)*$ ]]; then
      echo "Error: $label: FIXTURE_TOOLS may only name ${RUNNER_ALLOWED_TOOLS[*]}, joined by commas with no spaces (e.g. Read,Grep,Glob), or be 'none' (Bash only with FIXTURE_BASH=deny-record); got '$FIXTURE_TOOLS'" >&2
      return 1
    fi
    local -a tools
    local tool allowed ok
    IFS=',' read -ra tools <<< "$FIXTURE_TOOLS"
    for tool in "${tools[@]}"; do
      ok=""
      for allowed in "${RUNNER_ALLOWED_TOOLS[@]}"; do
        [ "$tool" = "$allowed" ] && ok=1
      done
      if [ "$tool" = "Bash" ] && [ "$FIXTURE_BASH" = "deny-record" ]; then
        ok=1
      fi
      if [ -z "$ok" ]; then
        echo "Error: $label: FIXTURE_TOOLS may only name ${RUNNER_ALLOWED_TOOLS[*]}, joined by commas with no spaces (e.g. Read,Grep,Glob), or be 'none' (Bash only with FIXTURE_BASH=deny-record); got '$tool'" >&2
        return 1
      fi
      # Inline fixtures arrive in the prompt, and the run's working directory is
      # empty, so a file tool can only be a mistake.
      if [ "$FIXTURE_MODE" = "inline" ]; then
        case "$tool" in
          Read|Grep|Glob)
            echo "Error: $label: inline mode must not grant file tools; got '$tool'" >&2
            return 1
            ;;
        esac
      fi
    done
  fi

  case "$FIXTURE_TRANSCRIPT" in
    ""|0) FIXTURE_TRANSCRIPT=0 ;;
    1) ;;
    *)
      echo "Error: $label: FIXTURE_TRANSCRIPT must be 0 or 1, got '$FIXTURE_TRANSCRIPT'" >&2
      return 1
      ;;
  esac

  case "$FIXTURE_BASH" in
    "") ;;
    deny-record)
      # The recorded command is the whole point, and it lives in the transcript.
      if [ "$FIXTURE_TRANSCRIPT" != 1 ]; then
        echo "Error: $label: FIXTURE_BASH=deny-record needs FIXTURE_TRANSCRIPT=1" >&2
        return 1
      fi
      ;;
  esac
}

# --- Generated reports: which skills have them, and their provenance stamps ---
#
# Shared by generate-reports.bash (the writer), eval-helpers.bash and
# helpers.bash (the checkers) and scripts/run-tests.sh (the per-skill gate), so
# the three can never disagree about what "has reports" or "fresh" means.
#
# Every function takes <skills_test_dir>: the test/skills directory holding
# <skill>/output/, <skill>/fixtures/, <skill>/runner.bash and this file. The
# skill itself is read from <skills_test_dir>/../../skills/<skill>/.

# skill_has_reports <skills_test_dir> <skill>: true when the skill's output
# directory holds at least one generated <fixture>.report.md. This is the one
# definition of "the skill has reports": run-tests.sh runs a skill's
# report-dependent suites only then, and once it is true a missing report for
# one of that skill's fixtures is a failure, never a skip.
skill_has_reports() {
  local f
  for f in "$1/$2/output/"*.report.md; do
    [ -f "$f" ] && return 0
  done
  return 1
}

# _stamp_sha256: sha256 of stdin as bare hex (sha256sum, or shasum on macOS).
_stamp_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | cut -d' ' -f1
  else
    shasum -a 256 | cut -d' ' -f1
  fi
}

# _stamp_hash_path <path>: a content hash of a file, or of a directory tree
# (every regular file's relative path and content, in a locale-independent
# order), or the word "absent". Python bytecode caches are left out: running a
# skill's tests writes them, and they are not an input to generation.
_stamp_hash_path() {
  local p="$1" f
  if [ -d "$p" ]; then
    (
      cd "$p" || exit 1
      find . -type f ! -path '*/__pycache__/*' ! -name '*.pyc' -print0 \
        | LC_ALL=C sort -z \
        | while IFS= read -r -d '' f; do
            printf '%s %s\n' "$(_stamp_sha256 < "$f")" "$f"
          done
    ) | _stamp_sha256
  elif [ -f "$p" ]; then
    _stamp_sha256 < "$p"
  else
    echo absent
  fi
}

# _stamp_harness_hash <skills_test_dir>: one hash of the shared harness code
# that shapes a generated report: generate-reports.bash and transcript.jq with
# comment and blank lines dropped, plus this file's runner-settings part as
# bash prints it back (declare -f drops comments). Not the stamp functions
# themselves, so editing the freshness check does not flag every report.
_stamp_harness_hash() {
  local f
  {
    for f in "$1/generate-reports.bash" "$1/transcript.jq"; do
      printf '== %s\n' "${f##*/}"
      if [ -f "$f" ]; then grep -vE '^[[:space:]]*(#|$)' "$f" || true; else echo absent; fi
    done
    declare -p RUNNER_ALLOWED_TOOLS 2>/dev/null || true
    declare -f reset_runner_settings check_runner_settings 2>/dev/null || true
  } | _stamp_sha256
}

# The stamp's first line. Bump it whenever the set or meaning of the lines
# changes, so every older stamp reads as stale ("stamp format") rather than as
# a changed input.
REPORT_STAMP_FORMAT="format 2"

# report_stamp <skills_test_dir> <skill> <fixture>: the provenance stamp of a
# report generated now for <fixture>: the format line, then one
# "<input> <sha256>" line per input:
#   skill    skills/<skill>/ (every file: SKILL.md, references/, scripts)
#   runner   test/skills/<skill>/runner.bash
#   fixture  test/skills/<skill>/fixtures/<fixture> (a file, or a tree fixture)
#   harness  the shared harness code (_stamp_harness_hash); informational only
# generate-reports.bash writes it as <fixture>.stamp beside the report;
# check_report_stamp recomputes it and compares.
#
# Only the skill's own inputs gate freshness (Q-071 [1]): runner.bash is the
# one file that sets this skill's prompt, tools and mode, so it counts as the
# skill's own. The shared harness (this file, generate-reports.bash,
# transcript.jq) is deliberately not a gating input: gating on this file made
# every edit to it stale every skill's reports, which kept the committed
# reports red under this repo's editing rate. Its harness line only produces a
# warning when it differs, so a harness change that may alter generated output
# is visible without failing anything. Not covered at all: live repo files a
# tree-mode runner's fixture_base copies in (self-eval's rubric,
# divergent-design's workflow).
report_stamp() {
  local sk="$1" skill="$2" fixture="$3"
  printf '%s\n' "$REPORT_STAMP_FORMAT"
  printf 'skill %s\n' "$(_stamp_hash_path "$sk/../../skills/$skill")"
  printf 'runner %s\n' "$(_stamp_hash_path "$sk/$skill/runner.bash")"
  printf 'fixture %s\n' "$(_stamp_hash_path "$sk/$skill/fixtures/$fixture")"
  printf 'harness %s\n' "$(_stamp_harness_hash "$sk")"
}

# _stamp_warn <message>: a non-failing note. Under bats it goes to fd 3, which
# bats prints even for a passing test; elsewhere to stderr.
_stamp_warn() {
  if { true >&3; } 2>/dev/null; then
    printf '# WARNING: %s\n' "$1" >&3
  else
    printf 'WARNING: %s\n' "$1" >&2
  fi
}

# check_report_stamp <skills_test_dir> <skill> <fixture>: fail, with a message
# naming the changed inputs and the regeneration command, unless
# <skill>/output/<fixture>.stamp exists, is in the current format, and its
# skill, runner and fixture lines match report_stamp for the current tree. A
# report whose skill, runner or fixture changed since it was generated grades a
# program that no longer exists. A stamp whose first line is not
# REPORT_STAMP_FORMAT reads as stale with the reason "stamp format". A changed
# harness line only warns (see report_stamp).
check_report_stamp() {
  local sk="$1" skill="$2" fixture="$3"
  local stamp="$sk/$skill/output/$fixture.stamp" now old changed=""
  local regen="bash test/skills/generate-reports.bash $skill $fixture, then commit test/skills/$skill/output/"
  if [ ! -f "$stamp" ]; then
    echo "No provenance stamp for $skill/$fixture ($stamp): the report cannot be tied to the current skill, runner and fixture. Regenerate: $regen"
    return 1
  fi
  old="$(cat "$stamp")"
  if [ "${old%%$'\n'*}" != "$REPORT_STAMP_FORMAT" ]; then
    echo "Stale report for $skill/$fixture: changed since generation: stamp format. Regenerate: $regen"
    return 1
  fi
  now="$(report_stamp "$sk" "$skill" "$fixture")"
  changed="$(diff <(grep -E '^(skill|runner|fixture) ' <<< "$now") \
    <(grep -E '^(skill|runner|fixture) ' <<< "$old") \
    | sed -nE 's/^< ([a-z]+) .*/\1/p' | tr '\n' ' ')"
  changed="${changed% }"
  if [ -n "$changed" ]; then
    echo "Stale report for $skill/$fixture: changed since generation: $changed. Regenerate: $regen"
    return 1
  fi
  if [ "$(grep '^harness ' <<< "$now")" != "$(grep '^harness ' <<< "$old")" ]; then
    _stamp_warn "$skill/$fixture: the shared harness (generate-reports.bash, transcript.jq, runner settings) changed since generation; not a failure. If the change alters generated output, regenerate: $regen"
  fi
}
