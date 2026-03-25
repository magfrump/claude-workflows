#!/usr/bin/env bash
# Generate fact-check reports by running claude -p against evaluation fixtures.
#
# Usage:
#   ./generate-reports.bash fact-check                    # all fact-check fixtures
#   ./generate-reports.bash fact-check tc-2.4-inaccurate  # single fixture (prefix match)
#   ./generate-reports.bash code-fact-check               # all code-fact-check fixtures
#
# Output:
#   test/skills/<skill>/output/<fixture>.report.md   — the generated report
#
# Cheat prevention: --tools restricts available tools (no Read for fact-check,
# no Write for either). The model cannot access expected-verdicts.bash or
# eval-criteria.md because Read is not in the allowed tool set.
#
# Environment:
#   CLAUDE_MODEL   — model to use (default: inherits from claude config)
#   CLAUDE_FLAGS   — additional flags to pass to claude -p

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL="${1:?Usage: generate-reports.bash <fact-check|code-fact-check> [fixture-prefix]}"
FIXTURE_PREFIX="${2:-}"

SKILL_FILE="$SCRIPT_DIR/../../skills/${SKILL}.md"
FIXTURE_DIR="$SCRIPT_DIR/${SKILL}/fixtures"
OUTPUT_DIR="$SCRIPT_DIR/${SKILL}/output"

if [ ! -f "$SKILL_FILE" ]; then
  echo "Error: skill file not found: $SKILL_FILE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Tool restrictions per skill:
# - fact-check: only WebSearch/WebFetch (no Read = no cheating, no Write = output to stdout)
# - code-fact-check: only Read/Grep/Glob (needs file access, runs in isolated temp dir)
# Restricting tools also prevents the model from using Write, forcing the report to stdout.
if [ "$SKILL" = "code-fact-check" ]; then
  ALLOWED_TOOLS="Read,Grep,Glob"
else
  ALLOWED_TOOLS="WebSearch,WebFetch"
fi

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

  if [ "$SKILL" = "code-fact-check" ]; then
    # Code fact-check needs the fixture as a file in a minimal repo context.
    # Create a temp directory with just the fixture, so the model can read it
    # without having access to eval criteria or expected verdicts.
    local temp_dir
    temp_dir=$(mktemp -d)
    # shellcheck disable=SC2064  # Intentional: expand $temp_dir now at trap-set time
    trap "rm -rf '$temp_dir'" RETURN

    cp "$fixture_path" "$temp_dir/"
    # Initialize a bare git repo so the skill's scoping logic doesn't fail
    git -C "$temp_dir" init -q
    git -C "$temp_dir" add .
    git -C "$temp_dir" commit -q -m "fixture" --allow-empty

    # Pipe prompt via stdin to avoid shell argument parsing issues
    # shellcheck disable=SC2086
    (cd "$temp_dir" && printf '%s' "Code fact-check the file ${fixture_name}. Check all claims in comments and docstrings against actual code behavior. Scope: ${fixture_name}" \
      | claude -p \
        --system-prompt-file "$SKILL_FILE" \
        --tools "$ALLOWED_TOOLS" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
    ) > "$report_path" 2>/dev/null || true
  else
    # Fact-check: pass fixture content in the prompt so the model doesn't need
    # file access to the fixtures directory.
    local fixture_content
    fixture_content="$(cat "$fixture_path")"

    # --tools: restrict to web search only (no file read = no cheating, no write = report to stdout)
    # Pipe prompt via stdin to avoid multiline shell argument issues
    # shellcheck disable=SC2086
    printf '%s\n\n%s' "Fact-check the following draft:" "$fixture_content" \
      | claude -p \
        --system-prompt-file "$SKILL_FILE" \
        --tools "$ALLOWED_TOOLS" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
      > "$report_path" 2>/dev/null || true
  fi

  if [ -s "$report_path" ]; then
    local claim_count
    claim_count=$(grep -cE '^## Claim [0-9]+' "$report_path" || true)
    echo "  Done: $claim_count claims in report"
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
