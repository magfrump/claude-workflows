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
#                     Every kept transcript is read strictly through
#                     transcript.jq: a malformed event or a missing init event
#                     voids the run (see "Transcript checks" in generate_one).
#   FIXTURE_BASH (optional) — "deny-record" lets FIXTURE_TOOLS be exactly Bash
#                     and pins DENY_RECORD_FLAGS (defined below, with why), so
#                     every Bash call is denied and only recorded (Q-063 [1]).
#                     Needs FIXTURE_TRANSCRIPT=1; refuses CLAUDE_FLAGS. The
#                     conditions that void such a run are listed once, in the
#                     "Transcript checks" comment in generate_one.
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
#   CLAUDE_FLAGS   — additional flags to pass to claude -p (refused under
#                    FIXTURE_BASH=deny-record; see DENY_RECORD_FLAGS)

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

# The flags that make every Bash call denied and recorded under deny-record
# (Q-063 [1]). The one definition: the prose elsewhere points here. Probed
# 2026-09-25 on CLI 2.1.283 (dd-arith-eval-bash-grant.md, "As built"): dontAsk
# alone still ran read-only commands; the 'Bash(**)' deny rule denies every
# call, multi-line included, while keeping Bash visible ('Bash(*)' removes it).
DENY_RECORD_FLAGS=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)

# Under deny-record, CLAUDE_FLAGS is refused outright. A denylist of flag names
# cannot hold: --setting-sources, a repeated --tools, --mcp-config, --add-dir
# or --agents could each change what runs (review iteration 2, C16). The model
# still comes from CLAUDE_MODEL, which is passed as one argv element.
if [ "$FIXTURE_BASH" = "deny-record" ] && [ -n "${CLAUDE_FLAGS:+${CLAUDE_FLAGS//[[:space:]]/}}" ]; then
  echo "Error: $RUNNER_FILE sets FIXTURE_BASH=deny-record, which refuses CLAUDE_FLAGS (got: $(printf '%q' "$CLAUDE_FLAGS")); set the model with CLAUDE_MODEL" >&2
  exit 1
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
  # the stream's result event is an error or missing, or a transcript check
  # below voided it). eval_fixture fails any fixture that has one, because a
  # failed run's report can still hold text (an auth error, whitespace) that
  # the absence-only checks would pass.
  local failed_path="$OUTPUT_DIR/${fixture_name}.failed"
  # Nothing from a previous run may survive to be scored as this run's,
  # whichever step below fails.
  rm -f "$report_path" "$transcript_path" "$failed_path"
  # Fail-closed: the marker exists from here until every check has passed, so
  # a run interrupted or aborted at any step (set -e, a signal) is never graded
  # (review iteration 4, A23).
  printf '%s\n' "generation did not finish" > "$failed_path"

  echo "--- Generating: $fixture_name ---"

  # One argv element for the value, so CLAUDE_MODEL cannot smuggle flags
  # (review iteration 2, C16).
  local -a model_args=()
  if [ -n "${CLAUDE_MODEL:-}" ]; then
    model_args=(--model "$CLAUDE_MODEL")
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
    claude_args+=("${DENY_RECORD_FLAGS[@]}")
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
      "${model_args[@]}" \
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
    # Transcript checks, through the one strict reader, transcript.jq (review
    # iteration 4, R2/A21): the same definitions eval-helpers.bash grades with.
    #  - well-formed: any line or event of a shape the reader does not expect
    #    voids the run, instead of being skipped. Skipping was how a Bash call
    #    could ride past every check inside an unexpected shape.
    #  - init: the stream must contain an init event. A run that died before
    #    one is reported as that, not blamed on a check below (A17).
    # Under deny-record also (definitions in transcript.jq's deny_record_counts):
    #  - tripwire: every Bash tool_use must be named by a Bash denial; one that
    #    is not may have run. Also when the run already failed, so an executed
    #    call is never hidden behind "claude exited N" (C10).
    #  - parser canaries: every Bash denial and every tool_result must answer a
    #    tool_use the reader saw, so a call moved to a place the reader does not
    #    look still voids the run, whether it was denied or ran (A16, A22).
    #  - only Bash may be denied, since only Bash is granted.
    #  - init canary: the init event must list Bash. If a CLI change made
    #    'Bash(**)' remove the tool, as 'Bash(*)' does, every fixture would read
    #    as "the model did not route" (C17). The init event also carries
    #    claude_code_version, so each kept transcript records its CLI.
    # These catch accidental breaches, not concealed ones: a command that did
    # run could rewrite the transcript before this reads it (C29).
    local verdict problems n_problems init_state cli_version counts
    verdict=$(jq -rR -n -L "$SCRIPT_DIR" 'import "transcript" as t;
      t::events | [ (t::problems | length), (t::problems | first // ""),
        (t::init | if . == null then "none" elif ((.tools // []) | type == "array" and index(["Bash"]) != null) then "bash" else "nobash" end),
        (t::init | .claude_code_version // "unknown"),
        (if (t::problems | length) == 0 then (t::deny_record_counts | "\(.undenied) \(.unseen) \(.orphans) \(.foreign)") else "" end)
      ] | join("\u001f")' "$transcript_path" 2>/dev/null) || verdict=""
    if [ -z "$verdict" ]; then
      failure="${failure:+$failure; }transcript: could not be read, so no check could run"
    else
      # \x1f, not a tab: read collapses runs of whitespace separators, so an
      # empty field (no problem text, no counts) would shift the rest.
      IFS=$'\x1f' read -r n_problems problems init_state cli_version counts <<< "$verdict"
      if [ "$n_problems" != 0 ]; then
        failure="${failure:+$failure; }transcript: $n_problems malformed event(s), first: $problems (CLI $cli_version)"
      fi
      if [ "$init_state" = none ]; then
        failure="${failure:+$failure; }no init event in the stream (the run did not start?)"
      fi
      if [ "$FIXTURE_BASH" = "deny-record" ]; then
        [ "$init_state" != nobash ] \
          || failure="${failure:+$failure; }Bash init canary: the init event does not list Bash (CLI $cli_version; did the deny rule remove the tool?)"
        if [ -n "$counts" ]; then
          local undenied unseen orphans foreign
          read -r undenied unseen orphans foreign <<< "$counts"
          [ "$undenied" = 0 ] \
            || failure="${failure:+$failure; }Bash tripwire: $undenied Bash call(s) not in permission_denials (may have executed)"
          [ "$unseen" = 0 ] \
            || failure="${failure:+$failure; }Bash parser canary: $unseen Bash denial(s) name a tool_use the reader did not see (CLI $cli_version; did the event shape change?)"
          [ "$orphans" = 0 ] \
            || failure="${failure:+$failure; }Bash parser canary: $orphans tool_result(s) answer a tool_use the reader did not see (CLI $cli_version; a call may have run unseen)"
          [ "$foreign" = 0 ] \
            || failure="${failure:+$failure; }Bash tripwire: $foreign denial(s) of a tool other than Bash, the only tool granted"
        fi
      fi
    fi
  fi

  if [ -n "$failure" ]; then
    printf '%s\n' "$failure" > "$failed_path"
    echo "  FAILED: $failure (recorded in $(basename "$failed_path"); eval_fixture will fail it)"
    return 0
  fi
  # Every check passed: only now is the fail-closed marker removed.
  rm -f "$failed_path"
  if [ -s "$report_path" ]; then
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
