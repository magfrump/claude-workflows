#!/bin/bash
# Standalone hypothesis evaluation script.
# Evaluates hypotheses from prior self-improvement rounds whose evaluation
# windows have elapsed. This allows on-demand evaluation of hypotheses
# created in the final round of a run, which would otherwise never be
# evaluated because step 0 only runs at the start of a new round.
#
# Usage:
#   scripts/evaluate-hypotheses.sh [--round N] [--dry-run] [--dashboard]
#
# Options:
#   --round N     Treat evaluation as happening at round N. Default: auto-detect
#                 from the highest-numbered tasks-round-N.json file + 1.
#   --dry-run     Skip Claude calls; record all verdicts as INCONCLUSIVE.
#   --dashboard   After evaluation, print the hypothesis summary dashboard.
#
# Prerequisites:
#   - jq
#   - claude CLI (unless --dry-run)
#
# Outputs:
#   - Appends verdicts to docs/working/hypothesis-log.md
#   - Logs invocation to docs/working/standalone-eval-log.md (for usage tracking)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKING_DIR="$REPO_DIR/docs/working"

# Source shared library
# shellcheck source=lib/si-functions.sh
source "$SCRIPT_DIR/lib/si-functions.sh"

# Parse arguments
ROUND=""
DRY_RUN=0
DASHBOARD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --round)
            ROUND="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --dashboard)
            DASHBOARD=1
            shift
            ;;
        -h|--help)
            sed -n '2,/^$/{ s/^# //; s/^#$//; p }' "$0"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Auto-detect round from highest tasks-round-N.json + 1
if [[ -z "$ROUND" ]]; then
    HIGHEST=0
    for f in "$WORKING_DIR"/tasks-round-*.json; do
        [ -f "$f" ] || continue
        N=$(basename "$f" | sed 's/tasks-round-//;s/\.json//')
        if [[ "$N" =~ ^[0-9]+$ ]] && [ "$N" -gt "$HIGHEST" ]; then
            HIGHEST=$N
        fi
    done
    if [ "$HIGHEST" -eq 0 ]; then
        echo "No tasks-round-N.json files found in $WORKING_DIR" >&2
        echo "Use --round N to specify the evaluation round explicitly." >&2
        exit 1
    fi
    # Evaluate as if we're one round past the last completed round
    ROUND=$((HIGHEST + 1))
    echo "Auto-detected evaluation round: $ROUND (based on tasks-round-$HIGHEST.json)"
fi

if [[ "$DRY_RUN" == "1" ]]; then
    export EVALUATE_HYPOTHESES_DRY_RUN=1
    echo "Dry-run mode: skipping Claude calls"
fi

echo "=== Standalone Hypothesis Evaluation (round $ROUND) ==="

# Run evaluation
evaluate_hypotheses "$ROUND" "$WORKING_DIR"

# Log this invocation for usage tracking (supports hypothesis about standalone usage)
EVAL_LOG="$WORKING_DIR/standalone-eval-log.md"
if [ ! -f "$EVAL_LOG" ]; then
    cat > "$EVAL_LOG" <<'HEADER'
# Standalone Evaluation Log

Tracks invocations of scripts/evaluate-hypotheses.sh for usage analysis.

| Date | Round | Mode | Invoker |
|------|-------|------|---------|
HEADER
fi
MODE="live"
[[ "$DRY_RUN" == "1" ]] && MODE="dry-run"
echo "| $(date -u +%Y-%m-%d) | $ROUND | $MODE | standalone |" >> "$EVAL_LOG"

# Optional dashboard
if [[ "$DASHBOARD" == "1" ]]; then
    print_hypothesis_summary "$ROUND"
fi
