#!/usr/bin/env bash
# Print a human-readable table of task verdicts from round-history.json.
#
# Usage:
#   scripts/print-round-summary.sh
#
# No arguments or options. Reads docs/working/round-history.json and prints
# a per-round table of task ID, verdict, and first-failing gate to stdout.
#
# Environment variable override (for testing):
#   ROUND_HISTORY — path to the JSON file (default: docs/working/round-history.json)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ROUND_HISTORY="${ROUND_HISTORY:-$REPO_ROOT/docs/working/round-history.json}"

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required" >&2; exit 1; }

if [ ! -f "$ROUND_HISTORY" ]; then
  echo "No round history found at $ROUND_HISTORY" >&2
  exit 1
fi

num_rounds=$(jq 'length' "$ROUND_HISTORY")

if [ "$num_rounds" -eq 0 ]; then
  echo "No rounds recorded."
  exit 0
fi

# For each round, print a header and a table of task verdicts.
# jq does the heavy lifting: extracts task ID, verdict, and first failing gate.
jq -r '
  .[] |
  "=== Round \(.round) ===",
  "TASK ID                  VERDICT     FIRST FAILING GATE",
  (
    if (.validation | length) == 0 then
      "(no tasks)"
    else
      .validation | to_entries[] |
      .key as $id |
      .value.verdict as $verdict |
      (
        # First failing gate: first key (alphabetical) with value "fail", excluding "verdict"
        [ .value | to_entries[] | select(.value == "fail" and .key != "verdict") | .key ] |
        sort | if length > 0 then .[0] else "—" end
      ) as $gate |
      "\($id | . + " " * (25 - (. | length)))  \($verdict | . + " " * (12 - (. | length)))\($gate)"
    end
  ),
  ""
' "$ROUND_HISTORY"
