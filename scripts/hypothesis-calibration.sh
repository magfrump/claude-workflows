#!/usr/bin/env bash
# Parse docs/working/hypothesis-log.md and compute accuracy metrics for
# resolved hypotheses (CONFIRMED, REFUTED, INCONCLUSIVE).
#
# Usage:
#   scripts/hypothesis-calibration.sh
#
# Outputs a plain-text calibration report to stdout suitable for inclusion
# in round reports. Status messages go to stderr.
#
# Environment variable overrides (for testing):
#   HYPOTHESIS_LOG — path to hypothesis-log.md
#                    (default: docs/working/hypothesis-log.md)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HYPOTHESIS_LOG="${HYPOTHESIS_LOG:-$REPO_ROOT/docs/working/hypothesis-log.md}"

if [ ! -f "$HYPOTHESIS_LOG" ]; then
  echo "Error: hypothesis log not found at $HYPOTHESIS_LOG" >&2
  exit 1
fi

# --- Parse the markdown table ---
# Extract data rows (skip header and separator lines).
# Expected columns: Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence

# Validate header
header=$(grep -m1 '^|.*Round.*Task ID' "$HYPOTHESIS_LOG" || true)
if [ -z "$header" ]; then
  echo "Error: could not find expected table header in $HYPOTHESIS_LOG" >&2
  exit 1
fi

# Arrays to hold parsed data
declare -a ROUNDS=()
declare -a TASK_IDS=()
declare -a WINDOWS=()
declare -a OUTCOMES=()

# Parse data rows: lines starting with | that aren't header or separator
while IFS='|' read -r _ round task_id _ window _ outcome _ _; do
  round=$(echo "$round" | xargs)
  task_id=$(echo "$task_id" | xargs)
  window=$(echo "$window" | xargs)
  outcome=$(echo "$outcome" | xargs)

  # Skip empty outcome (pending hypotheses stored separately)
  ROUNDS+=("$round")
  TASK_IDS+=("$task_id")
  WINDOWS+=("$window")
  OUTCOMES+=("$outcome")
done < <(grep '^|' "$HYPOTHESIS_LOG" | grep -v '^|[-— ]' | grep -v 'Round.*Task ID')

total=${#OUTCOMES[@]}

if [ "$total" -eq 0 ]; then
  echo "No hypotheses found in $HYPOTHESIS_LOG" >&2
  exit 0
fi

# --- Compute metrics ---
confirmed=0
refuted=0
inconclusive=0
pending=0

# By-round accumulators (associative arrays)
declare -A round_confirmed=()
declare -A round_refuted=()
declare -A round_inconclusive=()
declare -A round_pending=()

# By-cohort accumulators
prospective_confirmed=0
prospective_refuted=0
prospective_inconclusive=0
retroactive_confirmed=0
retroactive_refuted=0
retroactive_inconclusive=0

# Pending list
declare -a pending_list=()

for i in $(seq 0 $((total - 1))); do
  outcome="${OUTCOMES[$i]}"
  round="${ROUNDS[$i]}"
  window="${WINDOWS[$i]}"
  task_id="${TASK_IDS[$i]}"

  # Determine cohort: retroactive if window ≤ 1, prospective if window > 1
  if [ -n "$window" ] && [ "$window" -le 1 ] 2>/dev/null; then
    cohort="retroactive"
  else
    cohort="prospective"
  fi

  # Initialize round buckets if needed
  round_confirmed[$round]=${round_confirmed[$round]:-0}
  round_refuted[$round]=${round_refuted[$round]:-0}
  round_inconclusive[$round]=${round_inconclusive[$round]:-0}
  round_pending[$round]=${round_pending[$round]:-0}

  case "$outcome" in
    CONFIRMED)
      ((confirmed++))
      round_confirmed[$round]=$(( ${round_confirmed[$round]} + 1 ))
      if [ "$cohort" = "prospective" ]; then
        ((prospective_confirmed++))
      else
        ((retroactive_confirmed++))
      fi
      ;;
    REFUTED)
      ((refuted++))
      round_refuted[$round]=$(( ${round_refuted[$round]} + 1 ))
      if [ "$cohort" = "prospective" ]; then
        ((prospective_refuted++))
      else
        ((retroactive_refuted++))
      fi
      ;;
    INCONCLUSIVE*)
      ((inconclusive++))
      round_inconclusive[$round]=$(( ${round_inconclusive[$round]} + 1 ))
      if [ "$cohort" = "prospective" ]; then
        ((prospective_inconclusive++))
      else
        ((retroactive_inconclusive++))
      fi
      ;;
    "")
      ((pending++))
      round_pending[$round]=$(( ${round_pending[$round]} + 1 ))
      pending_list+=("$task_id (round $round, window $window)")
      ;;
    *)
      echo "Warning: unknown outcome '$outcome' for $task_id" >&2
      ;;
  esac
done

resolved=$((confirmed + refuted + inconclusive))
decidable=$((confirmed + refuted))

# --- Helper: compute accuracy percentage ---
pct() {
  local num=$1 denom=$2
  if [ "$denom" -eq 0 ]; then
    echo "N/A"
  else
    # Integer arithmetic: (num * 100 + denom/2) / denom for rounding
    echo "$(( (num * 100 + denom / 2) / denom ))%"
  fi
}

# --- Output report ---
echo "=== Hypothesis Calibration Report ==="
echo "Generated: $(date -u +%Y-%m-%d)"
echo ""
echo "--- Overall ---"
echo "Total hypotheses: $total"
echo "Resolved: $resolved ($confirmed confirmed, $refuted refuted, $inconclusive inconclusive)"
echo "Pending: $pending"
echo "Hit rate (confirmed / resolved): $(pct $confirmed $resolved) ($confirmed/$resolved)"
echo "Accuracy (confirmed / decidable): $(pct $confirmed $decidable) ($confirmed/$decidable)"
echo ""

echo "--- By Round Created ---"
for round in $(echo "${!round_confirmed[@]}" | tr ' ' '\n' | sort -n); do
  rc=${round_confirmed[$round]}
  rr=${round_refuted[$round]}
  ri=${round_inconclusive[$round]}
  rp=${round_pending[$round]}
  r_resolved=$((rc + rr + ri))
  r_decidable=$((rc + rr))
  echo "Round $round: $(pct $rc $r_decidable) accuracy ($r_resolved resolved, $rp pending)"
done
echo ""

echo "--- By Cohort ---"
p_resolved=$((prospective_confirmed + prospective_refuted + prospective_inconclusive))
p_decidable=$((prospective_confirmed + prospective_refuted))
r_resolved=$((retroactive_confirmed + retroactive_refuted + retroactive_inconclusive))
r_decidable=$((retroactive_confirmed + retroactive_refuted))

echo "Prospective (window > 1): $(pct $prospective_confirmed $p_decidable) accuracy ($p_resolved resolved, $p_decidable decidable)"
echo "Retroactive (window <= 1): $(pct $retroactive_confirmed $r_decidable) accuracy ($r_resolved resolved, $r_decidable decidable)"

# Compute delta if both cohorts have decidable hypotheses
if [ "$p_decidable" -gt 0 ] && [ "$r_decidable" -gt 0 ]; then
  p_acc=$(( (prospective_confirmed * 100 + p_decidable / 2) / p_decidable ))
  r_acc=$(( (retroactive_confirmed * 100 + r_decidable / 2) / r_decidable ))
  delta=$((p_acc - r_acc))
  abs_delta=${delta#-}
  echo "Delta: ${abs_delta}pp (hypothesis threshold: >10pp)"
  if [ "$abs_delta" -gt 10 ]; then
    echo "  → Measurable difference detected between cohorts"
  else
    echo "  → No significant difference between cohorts (≤10pp)"
  fi
else
  echo "Delta: N/A (insufficient data in one or both cohorts)"
fi
echo ""

if [ ${#pending_list[@]} -gt 0 ]; then
  echo "--- Pending ---"
  for entry in "${pending_list[@]}"; do
    echo "  $entry"
  done
  echo ""
fi
