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
#   test/skills/<skill>/output/<fixture>.stamp       — its provenance (hashes of
#       the skill, its runner and the fixture; see report_stamp in
#       runner-contract.bash); written only for a run that succeeded
#   test/skills/<skill>/output/<fixture>.failed      — present when the run failed
#   (and <fixture>.transcript.jsonl under FIXTURE_TRANSCRIPT=1, below)
# All of these are meant to be committed once generated (Q-071 [1]; .gitignore
# admits them): the suites read every
# one, so a fresh clone grades the same reports, and a report is regenerated
# only when its skill, runner or fixture changes.
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
#                     conditions that void such a run are defined in
#                     transcript.jq (deny_record_failures) and summarized in
#                     the "Transcript checks" comment in generate_one.
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
  # <fixture>.stamp ties the report to the inputs that produced it
  # (runner-contract.bash report_stamp: skills/<skill>/, runner.bash, the
  # fixture; not the shared harness). It is computed now, before the run, so an input
  # edited while claude runs leaves a stamp that no longer matches, and written
  # only after every check passed. eval_fixture and the format suites fail a
  # report whose stamp is missing or differs from the current tree.
  local stamp_path="$OUTPUT_DIR/${fixture_name}.stamp" stamp
  # Nothing from a previous run may survive to be scored as this run's,
  # whichever step below fails.
  rm -f "$report_path" "$transcript_path" "$failed_path" "$stamp_path"
  stamp="$(report_stamp "$SCRIPT_DIR" "$SKILL" "$fixture_name")"
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
    # The report is what the model finally said: the last result event's text,
    # read through transcript.jq like everything else (review iteration 5,
    # C36). A run that died before emitting one leaves an empty report (warned
    # below); a malformed transcript is voided by the checks that follow.
    jq -rR -n -L "$SCRIPT_DIR" 'import "transcript" as t;
      t::events | [.[] | objects | select(.type == "result")] | last | .result // empty
      | if type == "string" then . else tojson end' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
    if [ -z "$failure" ]; then
      local result_state
      result_state=$(jq -rR -n -L "$SCRIPT_DIR" 'import "transcript" as t;
        t::events | [.[] | objects | select(.type == "result")] | last
        | if . == null then "none" elif .is_error == true then "error" else "ok" end' \
        "$transcript_path" 2>/dev/null)
      case "$result_state" in
        ok) ;;
        error) failure="the result event is an error" ;;
        *) failure="no result event in the stream" ;;
      esac
    fi
    # Transcript checks: transcript.jq decides the verdict, in one place, for
    # the generator and the eval checks alike (review iterations 4-5, R2-R4).
    # Every transcript run gets transcript_failures: the stream must be well
    # formed by the module's rules and hold an init event. Its call census
    # finds every tool_use object at any depth, so a call cannot sit anywhere
    # it is not both checked and counted. A FIXTURE_BASH=deny-record run gets
    # deny_record_failures instead, which adds (see the module for each rule):
    # every init event's tools exactly ["Bash"]; every call a Bash call; every
    # call denied (tripwire); every Bash denial and every tool_result answering
    # a call in the census (parser canaries); no denial of another tool. These
    # run also when the run already failed, so an executed call is never hidden
    # behind "claude exited N". The verdict ends with a sentinel line: without
    # it (jq failed, output cut short) the run is void, so a verdict that did
    # not finish can never read as a pass. These checks catch accidental
    # breaches, not concealed ones: a command that did run could rewrite the
    # transcript before this reads it.
    local verdict_def=transcript_failures verdict_lines=() v
    [ "$FIXTURE_BASH" = "deny-record" ] && verdict_def=deny_record_failures
    if [ -r "$transcript_path" ]; then
      mapfile -t verdict_lines < <(jq -rR -n -L "$SCRIPT_DIR" \
        "import \"transcript\" as t; t::events | t::$verdict_def | t::print_verdict" \
        "$transcript_path" 2>/dev/null)
    fi
    if [ "${#verdict_lines[@]}" -eq 0 ] || [ "${verdict_lines[${#verdict_lines[@]}-1]}" != "__VERDICT_COMPLETE__" ]; then
      failure="${failure:+$failure; }transcript: could not be read in full, so no check could complete"
    else
      for v in "${verdict_lines[@]:0:${#verdict_lines[@]}-1}"; do
        failure="${failure:+$failure; }$v"
      done
    fi
  fi

  if [ -n "$failure" ]; then
    printf '%s\n' "$failure" > "$failed_path"
    echo "  FAILED: $failure (recorded in $(basename "$failed_path"); eval_fixture will fail it)"
    return 0
  fi
  # Every check passed: only now is the fail-closed marker removed and the
  # provenance stamp written.
  printf '%s\n' "$stamp" > "$stamp_path"
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
