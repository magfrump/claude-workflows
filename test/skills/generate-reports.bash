#!/usr/bin/env bash
# Generate skill reports by running claude -p against evaluation fixtures.
#
# Usage:
#   ./generate-reports.bash fact-check                    # all fact-check fixtures
#   ./generate-reports.bash fact-check tc-2.4-inaccurate  # single fixture (prefix match)
#   ./generate-reports.bash code-fact-check               # all code-fact-check fixtures
#   ./generate-reports.bash <skill>                       # any skill with a runner.bash
#
# Output:
#   test/skills/<skill>/output/<fixture>.report.md   — the generated report
#
# Per-skill configuration lives in test/skills/<skill>/runner.bash, which sets:
#   FIXTURE_TOOLS   — the --tools list for claude -p, comma-separated, from the
#                     allowlist in runner-contract.bash; or "none" for no tools
#                     at all (skills that must not fact-check on their own,
#                     like the critique skills)
#   FIXTURE_MODE    — "inline" (fixture content appended to the prompt; claude
#                     runs in an empty temp directory),
#                     "repo" (fixture copied into a throwaway git repo that
#                     becomes claude's working directory), or "tree" (each
#                     fixture is a DIRECTORY whose contents become that repo;
#                     see "tree mode" below)
#   fixture_prompt  — a function; given the filename the model will see, prints
#                     the prompt
#   FIXTURE_TRANSCRIPT (optional) — "1" runs claude with stream-json output and
#                     keeps the event stream as <fixture>.transcript.jsonl next
#                     to the report, so eval checks can see tool calls and
#                     sub-agent dispatches (tool_called:, subagents_min:). The
#                     report is still plain text: the final result event's text.
#   FIXTURE_BASH (optional) — "deny-record" lets FIXTURE_TOOLS name Bash, and
#                     pins --disallowedTools 'Bash(**)' --permission-mode dontAsk
#                     --permission-prompts none so every Bash call is denied and
#                     only recorded (Q-063 [1]). dontAsk alone is not enough: it
#                     still auto-approves commands the CLI deems read-only (pwd,
#                     ls and echo ran, probed 2026-09-25). 'Bash(**)' is a deny
#                     rule matching every command, multi-line included, while
#                     keeping Bash visible to the model; plain 'Bash(*)' removes
#                     the tool instead.
#                     Needs FIXTURE_TRANSCRIPT=1. A run in which any Bash call
#                     is missing from the result's permission_denials, i.e. may
#                     have executed, is recorded as failed.
#
# Fixture filenames describe the planted defect or the expected verdict
# (tc-sec1-sql-injection.py, tc-c2.4-incorrect.js). The model must never see
# them. In "inline" and "repo" mode fixture_prompt receives subject.<ext> (the
# extension alone tells the model the language; "subject" when the name has no
# plain extension), and in "repo" mode that is the file's name in the temp repo.
# In "tree" mode it receives ".".
#
# tree mode, for skills that read repo context (self-eval reads the rubric and
# sibling skills; the divergent-design router reads its workflow):
#   - fixture_base <dest> <fixture-dir> (optional runner function) runs first and
#     copies shared files into the temp repo — usually live files from
#     $REPO_ROOT, so fixtures test the current rubric/workflow rather than a
#     vendored copy. It may inspect <fixture-dir> to vary the base per fixture.
#   - the fixture directory's contents are copied on top, then committed.
#   - REQUEST.md, if present, is appended to the prompt and removed from the
#     repo before the commit.
#   - top-level entries (files or directories) named .fixture-* are control
#     markers for fixture_base; they are removed before the model runs, so their
#     names never reach it.
#   - fixture_prompt receives "." (there is no single subject file). The
#     directory's descriptive name never reaches the model.
#
# Cheat prevention and hermeticity. Every mode runs claude in a fresh temp
# directory, never in this repo, with:
#   --restricted        file tools confined to that directory, whatever the
#                       user's permission settings allow; user and project
#                       settings files (and so the user's hooks) are ignored
#   --safe-mode         no memory files, user skills, plugins, hooks or custom
#                       agents
#   --strict-mcp-config no account MCP connectors (Claude Docs create/update/
#                       delete leaked into every run without it, even under
#                       --tools ""; not --bare, which breaks subscription auth,
#                       FP-097)
#   --tools             the runner's list, never a write-capable tool
#                       (runner-contract.bash); sub-agents inherit it.
# So the model cannot reach expected-verdicts.bash or eval-criteria.md.
#
# Environment:
#   CLAUDE_MODEL   — model to use (default: inherits from claude config)
#   CLAUDE_FLAGS   — additional flags to pass to claude -p

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Repo root, for runners' fixture_base to copy live files from.
# shellcheck disable=SC2034  # Used by the sourced runner.bash files
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="${1:?Usage: generate-reports.bash <skill> [fixture-prefix]}"
FIXTURE_PREFIX="${2:-}"

SKILL_FILE="$SCRIPT_DIR/../../skills/${SKILL}/SKILL.md"
FIXTURE_DIR="$SCRIPT_DIR/${SKILL}/fixtures"
OUTPUT_DIR="$SCRIPT_DIR/${SKILL}/output"
RUNNER_FILE="$SCRIPT_DIR/${SKILL}/runner.bash"

if [ ! -f "$SKILL_FILE" ]; then
  echo "Error: skill file not found: $SKILL_FILE" >&2
  exit 1
fi
if [ ! -f "$RUNNER_FILE" ]; then
  echo "Error: no runner for $SKILL: $RUNNER_FILE" >&2
  exit 1
fi

# shellcheck source=runner-contract.bash
source "$SCRIPT_DIR/runner-contract.bash"
reset_runner_settings
# shellcheck source=/dev/null  # Path is per-skill
source "$RUNNER_FILE"
check_runner_settings "$RUNNER_FILE" || exit 1

if [ "$FIXTURE_TRANSCRIPT" = 1 ] && ! command -v jq >/dev/null 2>&1; then
  echo "Error: $RUNNER_FILE sets FIXTURE_TRANSCRIPT=1, which needs jq" >&2
  exit 1
fi

# Under deny-record, the operator's CLAUDE_FLAGS must not loosen what the pinned
# permission flags deny (a later --permission-mode would win). Any whitespace
# separates words when CLAUDE_FLAGS is expanded, so tabs and newlines are
# folded to spaces before matching.
if [ "$FIXTURE_BASH" = "deny-record" ]; then
  flags_words=" ${CLAUDE_FLAGS:-} "
  flags_words="${flags_words//[[:space:]]/ }"
  case "$flags_words" in
    *" --permission-mode"*|*" --permission-prompt"*|*" --allowedTools"*|*" --allowed-tools"*|\
    *" --dangerously-skip-permissions"*|*" --allow-dangerously-skip-permissions"*|*" --settings"*)
      echo "Error: $RUNNER_FILE sets FIXTURE_BASH=deny-record; CLAUDE_FLAGS may not change permissions: ${CLAUDE_FLAGS}" >&2
      exit 1
      ;;
  esac
fi

# "none" is explicit so a runner that forgets FIXTURE_TOOLS still errors above;
# claude -p reads --tools "" as "no tools".
TOOLS_ARG="$FIXTURE_TOOLS"
[ "$FIXTURE_TOOLS" = "none" ] && TOOLS_ARG=""

mkdir -p "$OUTPUT_DIR"

generate_one() {
  local fixture_path="$1"
  local fixture_name
  fixture_name="$(basename "$fixture_path")"
  local report_path="$OUTPUT_DIR/${fixture_name}.report.md"
  local transcript_path="$OUTPUT_DIR/${fixture_name}.transcript.jsonl"
  # <fixture>.failed records that the run itself failed (claude exited non-zero,
  # or the stream's result event is an error or missing). eval_fixture fails any
  # fixture that has one, because a failed run's report can still hold text (an
  # auth error, whitespace) that the absence-only checks would pass.
  local failed_path="$OUTPUT_DIR/${fixture_name}.failed"
  # Nothing from a previous run may survive to be scored as this run's,
  # whichever step below fails.
  rm -f "$report_path" "$transcript_path" "$failed_path"

  echo "--- Generating: $fixture_name ---"

  local model_flag=""
  if [ -n "${CLAUDE_MODEL:-}" ]; then
    model_flag="--model $CLAUDE_MODEL"
  fi

  # Keep a known file-type extension (it tells the model the language); drop
  # the name. Anything else gets no suffix, so neither a dotted name's tail
  # (tc-2.4-inaccurate) nor a descriptive suffix (.vuln, .safe) reaches the model.
  local subject_name="subject" ext="${fixture_name##*.}"
  if [ "$FIXTURE_MODE" = "tree" ]; then
    subject_name="."
  elif [ "$ext" != "$fixture_name" ]; then
    case "$ext" in
      md|txt|patch|diff|py|js|jsx|ts|tsx|go|cs|rb|rs|java|kt|swift|php|c|h|cpp|sh|sql|json|yaml|yml|toml|html|css|scss|vue|svelte)
        subject_name="subject.$ext" ;;
    esac
  fi

  local prompt
  prompt="$(fixture_prompt "$subject_name")"

  local -a claude_args=(-p --system-prompt-file "$SKILL_FILE"
    --strict-mcp-config --restricted --safe-mode)
  local out_path="$report_path"
  if [ "$FIXTURE_TRANSCRIPT" = 1 ]; then
    claude_args+=(--output-format stream-json --verbose)
    out_path="$transcript_path"
  fi
  # An empty --tools value is its own argv element; the CLI reads it as "no
  # tools" and does not consume the flag after it.
  claude_args+=(--tools "$TOOLS_ARG")
  if [ "$FIXTURE_BASH" = "deny-record" ]; then
    claude_args+=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)
  fi

  # Every mode runs in a fresh temp directory: empty for inline, a minimal git
  # repo holding the fixture for repo and tree.
  local temp_dir
  temp_dir=$(mktemp -d)
  # shellcheck disable=SC2064  # Intentional: expand $temp_dir now at trap-set time
  trap "rm -rf '$temp_dir'" RETURN

  local stdin_text="$prompt"
  if [ "$FIXTURE_MODE" = "inline" ]; then
    # Read first, as its own assignment, so an unreadable fixture stops the
    # script under set -e instead of sending the prompt alone.
    local fixture_content
    fixture_content="$(cat "$fixture_path")"
    stdin_text="$(printf '%s\n\n%s' "$prompt" "$fixture_content")"
  else
    if [ "$FIXTURE_MODE" = "tree" ]; then
      if declare -F fixture_base >/dev/null; then
        fixture_base "$temp_dir" "$fixture_path"
      fi
      cp -R "$fixture_path"/. "$temp_dir"/
      if [ -f "$temp_dir/REQUEST.md" ]; then
        stdin_text="$prompt"$'\n\n'"$(cat "$temp_dir/REQUEST.md")"
        rm "$temp_dir/REQUEST.md"
      fi
      rm -rf "$temp_dir"/.fixture-*
    else
      cp "$fixture_path" "$temp_dir/$subject_name"
    fi
    # A git repo so skills that scope by git diff/log don't fail
    git -C "$temp_dir" init -q
    git -C "$temp_dir" add .
    git -C "$temp_dir" -c user.name=fixture -c user.email=fixture@localhost \
      commit -q -m "fixture" --allow-empty
  fi

  # Pipe the prompt via stdin to avoid shell argument parsing issues. pipefail
  # makes the subshell's status claude's.
  local rc=0
  # shellcheck disable=SC2086
  (cd "$temp_dir" && printf '%s' "$stdin_text" \
    | claude "${claude_args[@]}" \
      $model_flag \
      ${CLAUDE_FLAGS:-} \
  ) > "$out_path" 2>/dev/null || rc=$?
  local failure=""
  [ "$rc" -eq 0 ] || failure="claude exited $rc"

  if [ "$FIXTURE_TRANSCRIPT" = 1 ]; then
    # The report is what the model finally said: the result event's text. A
    # run that died before emitting one leaves an empty report (warned below).
    # -R + fromjson? parses line by line and skips non-JSON lines (a stray
    # warning on stdout), which would otherwise abort jq and lose the report.
    jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
    if [ -z "$failure" ]; then
      local result_state
      result_state=$(jq -rR 'fromjson? | select(.type == "result") | if .is_error then "error" else "ok" end' \
        "$transcript_path" 2>/dev/null | tail -n 1)
      case "$result_state" in
        ok) ;;
        error) failure="the result event is an error" ;;
        *) failure="no result event in the stream" ;;
      esac
    fi
    # Tripwire (deny-record): every Bash tool_use must be listed as denied. One
    # that is not may have run, so the whole run is void. It runs even when the
    # run already failed, so an executed call is never hidden behind "claude
    # exited N" (review C10).
    if [ "$FIXTURE_BASH" = "deny-record" ]; then
      local undenied
      undenied=$(jq -rRn '[inputs | fromjson?] as $ev
        | ([$ev[] | select(.type == "result") | .permission_denials[]?.tool_use_id]) as $denied
        | [$ev[] | select(.type == "assistant") | .message.content[]?
           | select(.type == "tool_use" and .name == "Bash") | .id]
        | map(select(. as $id | $denied | index($id) | not)) | length' \
        "$transcript_path" 2>/dev/null) || undenied="unreadable"
      local trip=""
      case "$undenied" in
        0) ;;
        unreadable) trip="Bash tripwire: the transcript could not be read, so denials are unverified" ;;
        *) trip="Bash tripwire: $undenied Bash call(s) not in permission_denials (may have executed)" ;;
      esac
      [ -z "$trip" ] || failure="${failure:+$failure; }$trip"
    fi
  fi

  if [ -n "$failure" ]; then
    printf '%s\n' "$failure" > "$failed_path"
    echo "  FAILED: $failure (recorded in $(basename "$failed_path"); eval_fixture will fail it)"
  elif [ -s "$report_path" ]; then
    echo "  Done: $(grep -c '' "$report_path") lines in report"
  else
    echo "  WARNING: claude succeeded but printed an empty report"
  fi
}

# Find matching fixtures
fixtures=()
for f in "$FIXTURE_DIR"/*; do
  # tree fixtures are directories; the other modes take files.
  if [ "$FIXTURE_MODE" = "tree" ]; then
    [ -d "$f" ] || continue
  else
    [ -f "$f" ] || continue
  fi
  if [ -n "$FIXTURE_PREFIX" ]; then
    [[ "$(basename "$f")" == ${FIXTURE_PREFIX}* ]] || continue
  fi
  fixtures+=("$f")
done

if [ ${#fixtures[@]} -eq 0 ]; then
  echo "No fixtures found matching '${FIXTURE_PREFIX:-*}' in $FIXTURE_DIR" >&2
  exit 1
fi

echo "Generating reports for ${#fixtures[@]} fixture(s) using skill: $SKILL"
echo "Output: $OUTPUT_DIR"
echo ""

for fixture in "${fixtures[@]}"; do
  generate_one "$fixture"
done

echo ""
echo "Done. Run eval tests with:"
echo "  bats test/skills/${SKILL}-eval.bats"
