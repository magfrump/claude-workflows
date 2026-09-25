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
# denied (--permission-mode dontAsk --permission-prompts none), and the kept
# transcript records the command it tried. Nothing runs; eval checks compare
# the recorded command with a reference (arithmetic-eval's mode1_equiv:). A
# denied call is recorded in the stream and in the result event's
# permission_denials (probed 2026-09-25, dd-arith-eval-bash-grant.md). Any
# other Bash grant, and any Bash(<pattern>) spelling, is still refused.

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

  if [ "$FIXTURE_TOOLS" != "none" ]; then
    # Tool names joined by single commas: no spaces, no empty entries.
    if ! [[ "$FIXTURE_TOOLS" =~ ^[A-Za-z]+(,[A-Za-z]+)*$ ]]; then
      echo "Error: $label: FIXTURE_TOOLS may only name ${RUNNER_ALLOWED_TOOLS[*]}, joined by commas with no spaces (e.g. Read,Grep,Glob), or be 'none'; got '$FIXTURE_TOOLS'" >&2
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
      if [[ ",$FIXTURE_TOOLS," != *,Bash,* ]]; then
        echo "Error: $label: FIXTURE_BASH=deny-record is set but FIXTURE_TOOLS does not name Bash" >&2
        return 1
      fi
      ;;
    *)
      echo "Error: $label: FIXTURE_BASH may only be empty or deny-record, got '$FIXTURE_BASH'" >&2
      return 1
      ;;
  esac
}
