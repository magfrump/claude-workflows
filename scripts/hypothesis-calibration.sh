#!/usr/bin/env bash
# Parse docs/working/hypothesis-log.md and compute accuracy metrics for
# resolved hypotheses (CONFIRMED, REFUTED, INCONCLUSIVE).
#
# Usage:
#   scripts/hypothesis-calibration.sh
#
# Outputs a plain-text calibration report to stdout.
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

# --- Helper: trim leading/trailing whitespace ---
trim() {
  local s="$1"
  # Remove leading whitespace
  s="${s#"${s%%[![:space:]]*}"}"
  # Remove trailing whitespace
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# --- Helper: compute accuracy percentage (rounded) ---
pct() {
  local num="$1" denom="$2"
  if [ "$denom" -eq 0 ]; then
    printf 'N/A'
  else
    printf '%s%%' "$(( (num * 100 + denom / 2) / denom ))"
  fi
}

# --- Validate header ---
header=$(grep -m1 '^|.*Round.*Task ID' "$HYPOTHESIS_LOG" || true)
if [ -z "$header" ]; then
  echo "Error: could not find expected table header in $HYPOTHESIS_LOG" >&2
  exit 1
fi

# --- Read data rows into an array ---
# Filter: lines starting with |, exclude header and separator lines
mapfile -t data_lines < <(grep '^|' "$HYPOTHESIS_LOG" | grep -v '^|[-—]' | grep -v 'Round.*Task ID')

total=${#data_lines[@]}

if [ "$total" -eq 0 ]; then
  echo "No hypotheses found in $HYPOTHESIS_LOG" >&2
  exit 0
fi

# --- Parse and accumulate metrics ---
confirmed=0
refuted=0
inconclusive=0
pending=0

# By-round: store as delimited strings since associative array init is verbose
# We'll use associative arrays but initialize carefully
declare -A round_confirmed
declare -A round_refuted
declare -A round_inconclusive
declare -A round_pending

# By-cohort
prospective_confirmed=0
prospective_refuted=0
prospective_inconclusive=0
retroactive_confirmed=0
retroactive_refuted=0
retroactive_inconclusive=0

# Pending detail list
declare -a pending_list=()
# Track which rounds we've seen, for sorted output
declare -a seen_rounds=()

for line in "${data_lines[@]}"; do
  # Split on | — fields: empty, round, task_id, hypothesis, window, checked, outcome, date, evidence, empty
  IFS='|' read -r -a fields <<< "$line"

  # fields[0] is empty (before first |), data starts at index 1
  local_round="$(trim "${fields[1]:-}")"
  local_task_id="$(trim "${fields[2]:-}")"
  local_window="$(trim "${fields[4]:-}")"
  local_outcome="$(trim "${fields[6]:-}")"

  # Determine cohort: window <= 1 is retroactive, > 1 is prospective
  local_cohort="prospective"
  if [ -n "$local_window" ] && [ "$local_window" -le 1 ] 2>/dev/null; then
    local_cohort="retroactive"
  fi

  # Initialize round buckets on first sight
  if [ -z "${round_confirmed[$local_round]+x}" ]; then
    round_confirmed[$local_round]=0
    round_refuted[$local_round]=0
    round_inconclusive[$local_round]=0
    round_pending[$local_round]=0
    seen_rounds+=("$local_round")
  fi

  case "$local_outcome" in
    CONFIRMED)
      confirmed=$((confirmed + 1))
      round_confirmed[$local_round]=$(( ${round_confirmed[$local_round]} + 1 ))
      if [ "$local_cohort" = "prospective" ]; then
        prospective_confirmed=$((prospective_confirmed + 1))
      else
        retroactive_confirmed=$((retroactive_confirmed + 1))
      fi
      ;;
    REFUTED)
      refuted=$((refuted + 1))
      round_refuted[$local_round]=$(( ${round_refuted[$local_round]} + 1 ))
      if [ "$local_cohort" = "prospective" ]; then
        prospective_refuted=$((prospective_refuted + 1))
      else
        retroactive_refuted=$((retroactive_refuted + 1))
      fi
      ;;
    INCONCLUSIVE*)
      inconclusive=$((inconclusive + 1))
      round_inconclusive[$local_round]=$(( ${round_inconclusive[$local_round]} + 1 ))
      if [ "$local_cohort" = "prospective" ]; then
        prospective_inconclusive=$((prospective_inconclusive + 1))
      else
        retroactive_inconclusive=$((retroactive_inconclusive + 1))
      fi
      ;;
    "")
      pending=$((pending + 1))
      round_pending[$local_round]=$(( ${round_pending[$local_round]} + 1 ))
      pending_list+=("$local_task_id (round $local_round, window $local_window)")
      ;;
    *)
      echo "Warning: unknown outcome '$local_outcome' for $local_task_id" >&2
      ;;
  esac
done

resolved=$((confirmed + refuted + inconclusive))
decidable=$((confirmed + refuted))

# --- Output report ---
echo "=== Hypothesis Calibration Report ==="
echo "Generated: $(date -u +%Y-%m-%d)"
echo ""
echo "--- Overall ---"
echo "Total hypotheses: $total"
echo "Resolved: $resolved ($confirmed confirmed, $refuted refuted, $inconclusive inconclusive)"
echo "Pending: $pending"
echo "Hit rate (confirmed / resolved): $(pct "$confirmed" "$resolved") ($confirmed/$resolved)"
echo "Accuracy (confirmed / decidable): $(pct "$confirmed" "$decidable") ($confirmed/$decidable)"
echo ""

echo "--- By Round Created ---"
# Sort seen_rounds numerically
mapfile -t sorted_rounds < <(printf '%s\n' "${seen_rounds[@]}" | sort -n)
for round in "${sorted_rounds[@]}"; do
  rc="${round_confirmed[$round]}"
  rr="${round_refuted[$round]}"
  ri="${round_inconclusive[$round]}"
  rp="${round_pending[$round]}"
  r_resolved=$((rc + rr + ri))
  r_decidable=$((rc + rr))
  echo "Round $round: $(pct "$rc" "$r_decidable") accuracy ($r_resolved resolved, $rp pending)"
done
echo ""

echo "--- By Cohort ---"
p_resolved=$((prospective_confirmed + prospective_refuted + prospective_inconclusive))
p_decidable=$((prospective_confirmed + prospective_refuted))
r_resolved=$((retroactive_confirmed + retroactive_refuted + retroactive_inconclusive))
r_decidable=$((retroactive_confirmed + retroactive_refuted))

echo "Prospective (window > 1): $(pct "$prospective_confirmed" "$p_decidable") accuracy ($p_resolved resolved, $p_decidable decidable)"
echo "Retroactive (window <= 1): $(pct "$retroactive_confirmed" "$r_decidable") accuracy ($r_resolved resolved, $r_decidable decidable)"

if [ "$p_decidable" -gt 0 ] && [ "$r_decidable" -gt 0 ]; then
  p_acc=$(( (prospective_confirmed * 100 + p_decidable / 2) / p_decidable ))
  r_acc=$(( (retroactive_confirmed * 100 + r_decidable / 2) / r_decidable ))
  delta=$((p_acc - r_acc))
  abs_delta="${delta#-}"
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

if [ "${#pending_list[@]}" -gt 0 ]; then
  echo "--- Pending ---"
  for entry in "${pending_list[@]}"; do
    echo "  $entry"
  done
  echo ""
fi
