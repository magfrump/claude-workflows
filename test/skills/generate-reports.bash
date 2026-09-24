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
#   FIXTURE_TOOLS   — the --tools allowlist for claude -p, or "none" for no
#                     tools at all (skills that must not fact-check on their
#                     own, like the critique skills)
#   FIXTURE_MODE    — "inline" (fixture content appended to the prompt),
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
#
# Fixture filenames describe the planted defect or the expected verdict
# (tc-sec1-sql-injection.py, tc-c2.4-incorrect.js). The model must never see
# them: in "repo" mode the fixture is copied in as subject.<ext>, and that
# neutral name is what fixture_prompt receives in both modes.
#
# tree mode, for skills that read repo context (self-eval reads the rubric and
# sibling skills; the divergent-design router reads its workflow):
#   - fixture_base <dest> <fixture-dir> (optional runner function) runs first and
#     copies shared files into the temp repo — usually live files from
#     $REPO_ROOT, so fixtures test the current rubric/workflow rather than a
#     vendored copy. It may inspect <fixture-dir> to vary the base per fixture.
#   - the fixture directory's contents are copied on top, then committed.
#   - REQUEST.md, if present, is appended to the prompt and not copied.
#   - top-level files named .fixture-* are control markers for fixture_base;
#     they are removed before the model runs, so their names never reach it.
#   - fixture_prompt receives "." (there is no single subject file). The
#     directory's descriptive name never reaches the model.
#
# Cheat prevention: the tool allowlist never includes Write, and in "repo" mode
# the working directory holds only the fixture, so the model cannot reach
# expected-verdicts.bash or eval-criteria.md. "inline" skills should omit Read.
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

FIXTURE_TOOLS=""
FIXTURE_MODE=""
FIXTURE_TRANSCRIPT=""
# shellcheck source=/dev/null  # Path is per-skill
source "$RUNNER_FILE"

if [ -z "$FIXTURE_TOOLS" ] || ! declare -F fixture_prompt >/dev/null; then
  echo "Error: $RUNNER_FILE must set FIXTURE_TOOLS and define fixture_prompt" >&2
  exit 1
fi
case ",$FIXTURE_TOOLS," in
  *,Write,*|*,Edit,*)
    echo "Error: $RUNNER_FILE: FIXTURE_TOOLS must not include Write or Edit" >&2
    exit 1
    ;;
esac
case "$FIXTURE_MODE" in
  inline|repo|tree) ;;
  *)
    echo "Error: $RUNNER_FILE: FIXTURE_MODE must be inline, repo or tree, got '$FIXTURE_MODE'" >&2
    exit 1
    ;;
esac

case "$FIXTURE_TRANSCRIPT" in
  ""|0) FIXTURE_TRANSCRIPT=0 ;;
  1)
    if ! command -v jq >/dev/null 2>&1; then
      echo "Error: $RUNNER_FILE sets FIXTURE_TRANSCRIPT=1, which needs jq" >&2
      exit 1
    fi
    ;;
  *)
    echo "Error: $RUNNER_FILE: FIXTURE_TRANSCRIPT must be 0 or 1, got '$FIXTURE_TRANSCRIPT'" >&2
    exit 1
    ;;
esac

# --strict-mcp-config on every run: without it the account's claude.ai MCP
# connectors (e.g. Claude Docs create/update/delete) are exposed even under
# --tools "", in sub-agents too — a write-capable, outward-facing tool the
# no-Write rule above assumes is absent. Not --bare: it breaks subscription
# auth (FP-097).
#
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
  # A stale transcript must never pair with a fresh report.
  rm -f "$transcript_path"

  echo "--- Generating: $fixture_name ---"

  local model_flag=""
  if [ -n "${CLAUDE_MODEL:-}" ]; then
    model_flag="--model $CLAUDE_MODEL"
  fi

  # Keep the extension (it tells the model the language); drop the name.
  local subject_name="subject"
  if [ "$FIXTURE_MODE" = "tree" ]; then
    subject_name="."
  elif [[ "$fixture_name" == *.* ]]; then
    subject_name="subject.${fixture_name##*.}"
  fi

  local prompt
  prompt="$(fixture_prompt "$subject_name")"

  # --tools stays last before the model/extra flags: an empty value must not
  # swallow the next flag.
  local -a claude_args=(-p --system-prompt-file "$SKILL_FILE" --strict-mcp-config)
  local out_path="$report_path"
  if [ "$FIXTURE_TRANSCRIPT" = 1 ]; then
    claude_args+=(--output-format stream-json --verbose)
    out_path="$transcript_path"
  fi
  claude_args+=(--tools "$TOOLS_ARG")

  if [ "$FIXTURE_MODE" = "repo" ] || [ "$FIXTURE_MODE" = "tree" ]; then
    # The fixture as a file (repo) or a directory tree (tree) in a minimal repo,
    # so the model can read it without access to the eval criteria or expected
    # verdicts.
    local temp_dir
    temp_dir=$(mktemp -d)
    # shellcheck disable=SC2064  # Intentional: expand $temp_dir now at trap-set time
    trap "rm -rf '$temp_dir'" RETURN

    if [ "$FIXTURE_MODE" = "tree" ]; then
      if declare -F fixture_base >/dev/null; then
        fixture_base "$temp_dir" "$fixture_path"
      fi
      cp -R "$fixture_path"/. "$temp_dir"/
      if [ -f "$temp_dir/REQUEST.md" ]; then
        prompt="$prompt"$'\n\n'"$(cat "$temp_dir/REQUEST.md")"
        rm "$temp_dir/REQUEST.md"
      fi
      rm -rf "$temp_dir"/.fixture-*
    else
      cp "$fixture_path" "$temp_dir/$subject_name"
    fi
    # Initialize a git repo so skills that scope by git diff/log don't fail
    git -C "$temp_dir" init -q
    git -C "$temp_dir" add .
    git -C "$temp_dir" -c user.name=fixture -c user.email=fixture@localhost \
      commit -q -m "fixture" --allow-empty

    # Pipe prompt via stdin to avoid shell argument parsing issues
    # shellcheck disable=SC2086
    (cd "$temp_dir" && printf '%s' "$prompt" \
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
    ) > "$out_path" 2>/dev/null || true
  else
    local fixture_content
    fixture_content="$(cat "$fixture_path")"

    # Pipe prompt via stdin to avoid multiline shell argument issues
    # shellcheck disable=SC2086
    printf '%s\n\n%s' "$prompt" "$fixture_content" \
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
      > "$out_path" 2>/dev/null || true
  fi

  if [ "$FIXTURE_TRANSCRIPT" = 1 ]; then
    # The report is what the model finally said: the result event's text. A
    # run that died before emitting one leaves an empty report (warned below).
    jq -r 'select(.type == "result") | .result // empty' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
  fi

  if [ -s "$report_path" ]; then
    local claim_count finding_count
    # code-fact-check heads claims "## Claim N"; fact-check heads "## Verdict for CN:".
    claim_count=$(grep -cE '^## (Claim [0-9]+|Verdict for C[0-9]+)' "$report_path" || true)
    finding_count=$(grep -cE '^\*\*Severity:\*\*' "$report_path" || true)
    echo "  Done: $claim_count claims, $finding_count severity-tagged findings in report"
  else
    echo "  WARNING: empty report generated"
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
