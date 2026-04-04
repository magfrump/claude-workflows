#!/usr/bin/env bash
# Summarize failure patterns from round-history.json for use in DD preambles.
#
# Reads docs/working/round-history.json and outputs:
#   1. Which validation gates reject most often
#   2. Which task types (by id prefix) fail most
#   3. Whether re-attempts of previously failed tasks succeed at a higher rate
#
# Environment variable override (for testing):
#   ROUND_HISTORY — path to the JSON file (default: docs/working/round-history.json)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ROUND_HISTORY="${ROUND_HISTORY:-$REPO_ROOT/docs/working/round-history.json}"

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required" >&2; exit 1; }

if [ ! -f "$ROUND_HISTORY" ]; then
  echo "No round history found"
  exit 0
fi

num_rounds=$(jq 'length' "$ROUND_HISTORY")

if [ "$num_rounds" -eq 0 ]; then
  echo "No round history found"
  exit 0
fi

# --- Section 1: Gate rejection frequency ---
echo "=== Gate Rejection Frequency ==="
echo ""

# Count how many times each gate had value "fail" across all tasks/rounds
# Excludes the "verdict" key which is not a gate
gate_counts=$(jq -r '
  [.[] | .validation | to_entries[] | .value |
   to_entries[] | select(.value == "fail" and .key != "verdict") | .key
  ] | group_by(.) | map({gate: .[0], count: length}) |
  sort_by(-.count) | .[]  |
  "\(.gate)\t\(.count)"
' "$ROUND_HISTORY")

if [ -z "$gate_counts" ]; then
  echo "(no gate failures recorded)"
else
  printf "%-20s %s\n" "GATE" "FAILURES"
  while IFS=$'\t' read -r gate count; do
    printf "%-20s %s\n" "$gate" "$count"
  done <<< "$gate_counts"
fi

echo ""

# --- Section 2: Failure by task type (id prefix) ---
echo "=== Failure by Task Type ==="
echo ""

# Extract the prefix before the first hyphen as the "type"
# Count rejected tasks per type
type_counts=$(jq -r '
  [.[] | .validation | to_entries[] |
   select(.value.verdict == "rejected") |
   (.key | split("-")[0])
  ] | group_by(.) | map({type: .[0], count: length}) |
  sort_by(-.count) | .[] |
  "\(.type)\t\(.count)"
' "$ROUND_HISTORY")

if [ -z "$type_counts" ]; then
  echo "(no task rejections recorded)"
else
  printf "%-20s %s\n" "TASK PREFIX" "REJECTIONS"
  while IFS=$'\t' read -r ttype count; do
    printf "%-20s %s\n" "$ttype" "$count"
  done <<< "$type_counts"
fi

echo ""

# --- Section 3: Re-attempt success rate ---
echo "=== Re-attempt Success Rate ==="
echo ""

# A "re-attempt" is when a task ID appears in a later round after being rejected.
# Compare: first-attempt pass rate vs re-attempt pass rate.
reattempt_stats=$(jq -r '
  # Build a list of (task_id, round, verdict) tuples sorted by round
  [
    . as $rounds |
    $rounds[] | .round as $r |
    .validation | to_entries[] |
    {id: .key, round: $r, verdict: .value.verdict}
  ] | sort_by(.round) |

  # Group by task id
  group_by(.id) | map(
    {id: .[0].id, attempts: .}
  ) |

  # Classify each attempt
  reduce .[] as $task (
    {first_total: 0, first_pass: 0, re_total: 0, re_pass: 0};
    # First attempt
    ($task.attempts[0].verdict == "approved") as $first_ok |
    .first_total += 1 |
    (if $first_ok then .first_pass += 1 else . end) |
    # Re-attempts (index 1+)
    reduce ($task.attempts[1:][]) as $a (.;
      .re_total += 1 |
      if $a.verdict == "approved" then .re_pass += 1 else . end
    )
  ) |

  if .re_total == 0 then
    "no_reattempts"
  else
    "\(.first_total)\t\(.first_pass)\t\(.re_total)\t\(.re_pass)"
  end
' "$ROUND_HISTORY")

if [ "$reattempt_stats" = "no_reattempts" ]; then
  echo "(no re-attempts recorded)"
else
  IFS=$'\t' read -r first_total first_pass re_total re_pass <<< "$reattempt_stats"

  if [ "$first_total" -gt 0 ]; then
    first_rate=$(( (first_pass * 100) / first_total ))
  else
    first_rate=0
  fi

  if [ "$re_total" -gt 0 ]; then
    re_rate=$(( (re_pass * 100) / re_total ))
  else
    re_rate=0
  fi

  echo "First-attempt pass rate:  ${first_rate}% (${first_pass}/${first_total})"
  echo "Re-attempt pass rate:     ${re_rate}% (${re_pass}/${re_total})"

  if [ "$re_rate" -gt "$first_rate" ]; then
    echo "Re-attempts succeed at a HIGHER rate (+$(( re_rate - first_rate ))pp)"
  elif [ "$re_rate" -lt "$first_rate" ]; then
    echo "Re-attempts succeed at a LOWER rate ($(( re_rate - first_rate ))pp)"
  else
    echo "Re-attempt and first-attempt rates are EQUAL"
  fi
fi

echo ""
echo "---"
echo "Source: $ROUND_HISTORY ($num_rounds rounds)"
