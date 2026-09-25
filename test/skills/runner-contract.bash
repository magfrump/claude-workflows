# The runner.bash contract, shared by generate-reports.bash and the fast test
# that checks every committed runner (test/generate-reports.bats), so a bad
# runner fails before a paid claude run rather than during one.
#
# Load with: source runner-contract.bash
# Then: reset_runner_settings; source <runner.bash>; check_runner_settings <label>

# Tools a fixture run may be granted. Anything else, including a spelling the
# CLI would also accept ("Read, Write", "Write(*)", "Bash"), is refused: this is
# an allowlist, not a Write/Edit denylist. Sub-agents inherit the session's
# --tools (checked by a canary probe on 2026-09-24: a general-purpose sub-agent
# under --tools Agent got "No such tool available: Read ... in subagents as
# well as here"), so Agent adds dispatch, not file access.
RUNNER_ALLOWED_TOOLS=(Read Grep Glob WebSearch WebFetch Agent)

# Clear the settings a runner is expected to set, so a runner that forgets one
# fails check_runner_settings instead of inheriting a previous runner's value.
reset_runner_settings() {
  FIXTURE_TOOLS=""
  FIXTURE_MODE=""
  FIXTURE_TRANSCRIPT=""
  unset -f fixture_prompt fixture_base 2>/dev/null || true
}

# Validate the settings a sourced runner left behind. Prints the first problem
# and returns 1. On success, normalizes FIXTURE_TRANSCRIPT to 0 or 1.
# Args: $1 = label for messages (usually the runner's path)
check_runner_settings() {
  local label="$1"
  if [ -z "$FIXTURE_TOOLS" ] || ! declare -F fixture_prompt >/dev/null; then
    echo "Error: $label must set FIXTURE_TOOLS and define fixture_prompt" >&2
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
    local -a tools
    local tool allowed ok
    IFS=',' read -ra tools <<< "$FIXTURE_TOOLS"
    for tool in "${tools[@]}"; do
      ok=""
      for allowed in "${RUNNER_ALLOWED_TOOLS[@]}"; do
        [ "$tool" = "$allowed" ] && ok=1
      done
      if [ -z "$ok" ]; then
        echo "Error: $label: FIXTURE_TOOLS may only name ${RUNNER_ALLOWED_TOOLS[*]} (comma-separated, no spaces) or be 'none'; got '$tool'" >&2
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
}
