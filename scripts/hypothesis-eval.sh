#!/usr/bin/env bash
set -euo pipefail

# Hypothesis evaluation for the self-improvement loop.
# Sourceable script — provides evaluate_hypothesis_windows() for use by
# self-improvement.sh.  Kept separate to isolate shellcheck surface area
# away from the 1,200+ line orchestrator.

# evaluate_hypothesis_windows ROUND WORKING_DIR
#
# For each prior round, checks whether any hypothesis evaluation windows have
# elapsed and, if so, prompts Claude for a verdict (CONFIRMED / REFUTED /
# INCONCLUSIVE).  Results are appended to the hypothesis log.
#
# Requires:
#   - get_eligible_hypotheses() already defined (from self-improvement.sh)
#   - jq, claude, grep, sed, cut on PATH
#
# Args:
#   $1  current round number (positive integer)
#   $2  path to the working directory (must exist)
evaluate_hypothesis_windows() {
    local round="${1:?evaluate_hypothesis_windows: missing ROUND argument}"
    local working_dir="${2:?evaluate_hypothesis_windows: missing WORKING_DIR argument}"

    local hypothesis_log="$working_dir/hypothesis-log.md"

    # Create the log with header if it does not yet exist.
    if [ ! -f "$hypothesis_log" ]; then
        cat > "$hypothesis_log" <<'HEADER'
# Hypothesis Log

Tracks falsifiable predictions made at task creation time and their outcomes.

| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|------------------|---------|-------------|----------|
HEADER
    fi

    local prior_round
    for prior_round in $(seq 1 "$((round - 1))"); do
        local prior_tasks="$working_dir/tasks-round-$prior_round.json"
        [ -f "$prior_tasks" ] || continue

        local eligible
        eligible=$(get_eligible_hypotheses "$round" "$prior_round" < "$prior_tasks") || true

        local task_id
        while IFS= read -r task_id; do
            [ -z "$task_id" ] && continue

            # Skip if already recorded in the log
            if grep -qF "| $task_id |" "$hypothesis_log" 2>/dev/null; then
                continue
            fi

            # Only evaluate completed (approved + merged) tasks
            if ! grep -qF "**$task_id**" "$working_dir/completed-tasks.md" 2>/dev/null; then
                continue
            fi

            local hypothesis
            hypothesis=$(jq -r --arg tid "$task_id" \
                '.[] | select(.id==$tid) | .hypothesis' "$prior_tasks")
            local window
            window=$(jq -r --arg tid "$task_id" \
                '.[] | select(.id==$tid) | .hypothesis_window // 3' "$prior_tasks")

            echo "  Evaluating hypothesis for: $task_id"

            # Build prompt with printf to avoid shell expansion of untrusted
            # hypothesis text (which could contain $(...) or backticks).
            local eval_prompt
            eval_prompt=$(printf 'Evaluate this hypothesis from round %s (now round %s):

Task: %s
Hypothesis: %s
Window: %s rounds

Review the repo state, git log, completed-tasks.md, and validation logs to
determine whether the hypothesis was CONFIRMED, REFUTED, or INCONCLUSIVE.

Output exactly one line in this format:
HYPOTHESIS_VERDICT: <CONFIRMED|REFUTED|INCONCLUSIVE> | <one-sentence evidence summary>' \
                "$prior_round" "$round" "$task_id" "$hypothesis" "$window")

            local eval_result
            eval_result=$(claude -p "$eval_prompt" 2>/dev/null) || true

            local verdict_line
            verdict_line=$(echo "$eval_result" | sed -n 's/.*HYPOTHESIS_VERDICT: //p' | head -1)
            if [ -z "$verdict_line" ]; then
                verdict_line="INCONCLUSIVE | evaluation failed to parse"
            fi

            local outcome
            outcome=$(echo "$verdict_line" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            local evidence
            evidence=$(echo "$verdict_line" | cut -d'|' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Escape pipe characters to prevent breaking the markdown table
            local hypothesis_escaped="${hypothesis//|/\\|}"
            local evidence_escaped="${evidence//|/\\|}"

            # Append to hypothesis log (includes Status Date column)
            echo "| $prior_round | $task_id | $hypothesis_escaped | $window | $round | $outcome | | $evidence_escaped |" >> "$hypothesis_log"
            echo "    $task_id: $outcome"
        done <<< "$eligible"
    done
}
