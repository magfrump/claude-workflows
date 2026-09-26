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

# report_stamp <skills_test_dir> <skill> <fixture>: the provenance stamp of a
# report generated now for <fixture>, one "<input> <sha256>" line per input:
#   skill    skills/<skill>/ (every file: SKILL.md, references/, scripts)
#   runner   test/skills/<skill>/runner.bash
#   contract test/skills/runner-contract.bash (this file)
#   fixture  test/skills/<skill>/fixtures/<fixture> (a file, or a tree fixture)
# generate-reports.bash writes it as <fixture>.stamp beside the report;
# check_report_stamp recomputes it and compares. Not covered: live repo files a
# tree-mode runner's fixture_base copies in (self-eval's rubric,
# divergent-design's workflow).
report_stamp() {
  local sk="$1" skill="$2" fixture="$3"
  printf 'skill %s\n' "$(_stamp_hash_path "$sk/../../skills/$skill")"
  printf 'runner %s\n' "$(_stamp_hash_path "$sk/$skill/runner.bash")"
  printf 'contract %s\n' "$(_stamp_hash_path "$sk/runner-contract.bash")"
  printf 'fixture %s\n' "$(_stamp_hash_path "$sk/$skill/fixtures/$fixture")"
}

# check_report_stamp <skills_test_dir> <skill> <fixture>: fail, with a message
# naming the changed inputs and the regeneration command, unless
# <skill>/output/<fixture>.stamp exists and matches report_stamp for the
# current tree. A report whose skill, runner, contract or fixture changed since
# it was generated grades a program that no longer exists.
check_report_stamp() {
  local sk="$1" skill="$2" fixture="$3"
  local stamp="$sk/$skill/output/$fixture.stamp" now changed=""
  local regen="bash test/skills/generate-reports.bash $skill $fixture"
  if [ ! -f "$stamp" ]; then
    echo "No provenance stamp for $skill/$fixture ($stamp): the report cannot be tied to the current skill, runner and fixture. Regenerate: $regen"
    return 1
  fi
  now="$(report_stamp "$sk" "$skill" "$fixture")"
  if [ "$now" != "$(cat "$stamp")" ]; then
    changed="$(diff <(printf '%s\n' "$now") "$stamp" | sed -nE 's/^< ([a-z]+) .*/\1/p' | tr '\n' ' ')"
    changed="${changed% }"
    echo "Stale report for $skill/$fixture: changed since generation: ${changed:-stamp format}. Regenerate: $regen"
    return 1
  fi
}
