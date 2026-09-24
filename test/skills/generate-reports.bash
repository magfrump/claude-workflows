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
#   FIXTURE_TOOLS   — the --tools allowlist for claude -p
#   FIXTURE_MODE    — "inline" (fixture content appended to the prompt) or
#                     "repo" (fixture copied into a throwaway git repo that
#                     becomes claude's working directory)
#   fixture_prompt  — a function; given the filename the model will see, prints
#                     the prompt
#
# Fixture filenames describe the planted defect or the expected verdict
# (tc-sec1-sql-injection.py, tc-c2.4-incorrect.js). The model must never see
# them: in "repo" mode the fixture is copied in as subject.<ext>, and that
# neutral name is what fixture_prompt receives in both modes.
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
  inline|repo) ;;
  *)
    echo "Error: $RUNNER_FILE: FIXTURE_MODE must be inline or repo, got '$FIXTURE_MODE'" >&2
    exit 1
    ;;
esac

mkdir -p "$OUTPUT_DIR"

generate_one() {
  local fixture_path="$1"
  local fixture_name
  fixture_name="$(basename "$fixture_path")"
  local report_path="$OUTPUT_DIR/${fixture_name}.report.md"

  echo "--- Generating: $fixture_name ---"

  local model_flag=""
  if [ -n "${CLAUDE_MODEL:-}" ]; then
    model_flag="--model $CLAUDE_MODEL"
  fi

  # Keep the extension (it tells the model the language); drop the name.
  local subject_name="subject"
  if [[ "$fixture_name" == *.* ]]; then
    subject_name="subject.${fixture_name##*.}"
  fi

  local prompt
  prompt="$(fixture_prompt "$subject_name")"

  if [ "$FIXTURE_MODE" = "repo" ]; then
    # The fixture as a file in a minimal repo, so the model can read it without
    # access to the eval criteria or expected verdicts.
    local temp_dir
    temp_dir=$(mktemp -d)
    # shellcheck disable=SC2064  # Intentional: expand $temp_dir now at trap-set time
    trap "rm -rf '$temp_dir'" RETURN

    cp "$fixture_path" "$temp_dir/$subject_name"
    # Initialize a git repo so skills that scope by git diff/log don't fail
    git -C "$temp_dir" init -q
    git -C "$temp_dir" add .
    git -C "$temp_dir" -c user.name=fixture -c user.email=fixture@localhost \
      commit -q -m "fixture" --allow-empty

    # Pipe prompt via stdin to avoid shell argument parsing issues
    # shellcheck disable=SC2086
    (cd "$temp_dir" && printf '%s' "$prompt" \
      | claude -p \
        --system-prompt-file "$SKILL_FILE" \
        --tools "$FIXTURE_TOOLS" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
    ) > "$report_path" 2>/dev/null || true
  else
    local fixture_content
    fixture_content="$(cat "$fixture_path")"

    # Pipe prompt via stdin to avoid multiline shell argument issues
    # shellcheck disable=SC2086
    printf '%s\n\n%s' "$prompt" "$fixture_content" \
      | claude -p \
        --system-prompt-file "$SKILL_FILE" \
        --tools "$FIXTURE_TOOLS" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
      > "$report_path" 2>/dev/null || true
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
  [ -f "$f" ] || continue
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
