#!/bin/bash
set -euo pipefail

# Configuration
REPO_DIR=~/claude-workflows
WORKTREE_BASE=~/wt
MAX_ROUNDS=5
WORKING_DIR="$REPO_DIR/docs/working"
ROUND_HISTORY="$WORKING_DIR/round-history.json"

# Check required dependencies
command -v jq &>/dev/null || { echo "Error: jq is required but not found"; exit 1; }

CONVERGENCE_THRESHOLD=${CONVERGENCE_THRESHOLD:-70}  # percent overlap to trigger convergence
HISTORY_FILE="$REPO_DIR/docs/working/problem-history.json"

mkdir -p "$WORKING_DIR"
touch "$WORKING_DIR/completed-tasks.md"

# Initialize round-history.json if it doesn't exist
if [ ! -f "$ROUND_HISTORY" ]; then
    echo '[]' > "$ROUND_HISTORY"
fi

if [ ! -f "$HISTORY_FILE" ]; then
    echo '{}' > "$HISTORY_FILE"
fi

# --- JSON logging helpers ---

# Clean up temp files on early exit
ROUND_LOG_FILE=""
cleanup() {
    if [ -n "$ROUND_LOG_FILE" ] && [ -f "$ROUND_LOG_FILE" ]; then
        rm -f "$ROUND_LOG_FILE"
    fi
}
trap cleanup EXIT ERR

# Initialize a round log object as a temp file; sets ROUND_LOG_FILE
init_round_log() {
    local round=$1
    ROUND_LOG_FILE=$(mktemp)
    jq -n --argjson round "$round" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{round: $round, timestamp: $ts, ideas: {}, tasks: {}, validation: {}, merges: {}, outcome: "incomplete"}' \
        > "$ROUND_LOG_FILE"
}

# Update a top-level field in the round log
update_round_log() {
    local path=$1 value=$2
    local tmp
    tmp=$(mktemp)
    jq --argjson v "$value" "$path = \$v" "$ROUND_LOG_FILE" > "$tmp" && mv "$tmp" "$ROUND_LOG_FILE"
}

# Record a gate result for a task
record_gate() {
    local task_id=$1 gate=$2 status=$3
    local tmp
    tmp=$(mktemp)
    jq --arg tid "$task_id" --arg g "$gate" --arg s "$status" \
        '.validation[$tid][$g] = $s' "$ROUND_LOG_FILE" > "$tmp" && mv "$tmp" "$ROUND_LOG_FILE"
}

# Write per-round report and append to round-history.json
finalize_round_log() {
    local round=$1
    # Write per-round report
    cp "$ROUND_LOG_FILE" "$WORKING_DIR/round-${round}-report.json"

    # Append to round-history.json
    local tmp
    tmp=$(mktemp)
    jq --slurpfile entry "$ROUND_LOG_FILE" '. += $entry' "$ROUND_HISTORY" > "$tmp" && mv "$tmp" "$ROUND_HISTORY"

    rm -f "$ROUND_LOG_FILE"
}


cd "$REPO_DIR"

for ROUND in $(seq 1 $MAX_ROUNDS); do
    echo "=== Round $ROUND ==="
    init_round_log "$ROUND"

    # -------------------------------------------------------
    # Step 0: Check hypothesis windows from prior rounds
    # -------------------------------------------------------
    HYPOTHESIS_LOG="$WORKING_DIR/hypothesis-log.md"
    if [ ! -f "$HYPOTHESIS_LOG" ]; then
        cat > "$HYPOTHESIS_LOG" <<'HEADER'
# Hypothesis Log

Tracks falsifiable predictions made at task creation time and their outcomes.

| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Evidence |
|-------|---------|------------|--------|------------------|---------|----------|
HEADER
    fi

    for PRIOR_ROUND in $(seq 1 $((ROUND - 1))); do
        PRIOR_TASKS="$WORKING_DIR/tasks-round-$PRIOR_ROUND.json"
        [ -f "$PRIOR_TASKS" ] || continue

        # Get tasks that have a hypothesis, are not retroactive, and whose window has elapsed
        ELIGIBLE=$(jq -r --argjson current "$ROUND" --argjson prior "$PRIOR_ROUND" \
            '[.[] | select(.hypothesis != null and .hypothesis != "") |
              select(.retroactive != true) |
              select(($current - $prior) >= (.hypothesis_window // 3))] | .[]? | .id' \
            "$PRIOR_TASKS" 2>/dev/null) || true

        while IFS= read -r TASK_ID; do
            [ -z "$TASK_ID" ] && continue
            # Skip if already recorded in the log
            if grep -qF "| $TASK_ID |" "$HYPOTHESIS_LOG" 2>/dev/null; then
                continue
            fi

            # Check if the task was actually completed (approved and merged)
            if ! grep -qF "**$TASK_ID**" "$WORKING_DIR/completed-tasks.md" 2>/dev/null; then
                continue
            fi

            HYPOTHESIS=$(jq -r --arg tid "$TASK_ID" '.[] | select(.id==$tid) | .hypothesis' "$PRIOR_TASKS")
            WINDOW=$(jq -r --arg tid "$TASK_ID" '.[] | select(.id==$tid) | .hypothesis_window // 3' "$PRIOR_TASKS")

            echo "  Evaluating hypothesis for: $TASK_ID"
            # Build the prompt with printf to avoid shell expansion of untrusted
            # hypothesis text (which could contain $(...) or backticks).
            EVAL_PROMPT=$(printf 'Evaluate this hypothesis from round %s (now round %s):

Task: %s
Hypothesis: %s
Window: %s rounds

Review the repo state, git log, completed-tasks.md, and validation logs to
determine whether the hypothesis was CONFIRMED, REFUTED, or INCONCLUSIVE.

Output exactly one line in this format:
HYPOTHESIS_VERDICT: <CONFIRMED|REFUTED|INCONCLUSIVE> | <one-sentence evidence summary>' \
                "$PRIOR_ROUND" "$ROUND" "$TASK_ID" "$HYPOTHESIS" "$WINDOW")
            EVAL_RESULT=$(claude -p "$EVAL_PROMPT" 2>/dev/null) || true

            VERDICT_LINE=$(echo "$EVAL_RESULT" | sed -n 's/.*HYPOTHESIS_VERDICT: //p' | head -1)
            if [ -z "$VERDICT_LINE" ]; then
                VERDICT_LINE="INCONCLUSIVE | evaluation failed to parse"
            fi
            OUTCOME=$(echo "$VERDICT_LINE" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            EVIDENCE=$(echo "$VERDICT_LINE" | cut -d'|' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Escape pipe characters to prevent breaking the markdown table
            HYPOTHESIS_ESCAPED="${HYPOTHESIS//|/\\|}"
            EVIDENCE_ESCAPED="${EVIDENCE//|/\\|}"

            # Append to hypothesis log
            echo "| $PRIOR_ROUND | $TASK_ID | $HYPOTHESIS_ESCAPED | $WINDOW | $ROUND | $OUTCOME | $EVIDENCE_ESCAPED |" >> "$HYPOTHESIS_LOG"
            echo "    $TASK_ID: $OUTCOME"
        done <<< "$ELIGIBLE"
    done

    # -------------------------------------------------------
    # Step 0b: Build prior-round context for idea generation
    # -------------------------------------------------------
    PRIOR_CONTEXT=""
    if [ "$ROUND" -gt 1 ]; then
        PREV=$((ROUND - 1))
        PREV_TASKS_FILE="$WORKING_DIR/tasks-round-$PREV.json"
        PREV_IDEAS_FILE="$WORKING_DIR/feature-ideas-round-$PREV.md"

        # Categorize prior-round tasks by validation verdict
        APPROVED_LIST=""
        REJECTED_LIST=""
        if [ -f "$PREV_TASKS_FILE" ]; then
            while IFS= read -r TID; do
                [ -z "$TID" ] && continue
                VERDICT=$(jq -r --arg r "$PREV" --arg tid "$TID" \
                    '.[] | select(.round == ($r | tonumber)) | .validation[$tid].verdict // "unknown"' \
                    "$ROUND_HISTORY" 2>/dev/null) || VERDICT="unknown"

                TDESC=$(jq -r --arg tid "$TID" '.[] | select(.id==$tid) | .description' "$PREV_TASKS_FILE" 2>/dev/null) || TDESC=""

                if [ "$VERDICT" = "approved" ]; then
                    APPROVED_LIST="${APPROVED_LIST}
  - ${TID}: ${TDESC}"
                elif [ "$VERDICT" = "rejected" ]; then
                    FAIL_GATE=$(jq -r --arg r "$PREV" --arg tid "$TID" \
                        '[.[] | select(.round == ($r | tonumber)) | .validation[$tid] | to_entries[] | select(.value == "fail") | .key] | join(", ")' \
                        "$ROUND_HISTORY" 2>/dev/null) || FAIL_GATE="unknown"
                    REJECTED_LIST="${REJECTED_LIST}
  - ${TID} (failed: ${FAIL_GATE}): ${TDESC}"
                fi
                # Skip tasks with "unknown" verdict — they were never validated
            done < <(jq -r '.[].id' "$PREV_TASKS_FILE" 2>/dev/null)
        fi

        # Unattempted survivors: extract deterministically from the DD output.
        # The Survivors section uses "- **#N Name** — description" format.
        # Compare against task IDs by converting survivor names to kebab-case.
        UNATTEMPTED=""
        if [ -f "$PREV_IDEAS_FILE" ] && [ -f "$PREV_TASKS_FILE" ]; then
            TASK_IDS_LIST=$(jq -r '.[].id' "$PREV_TASKS_FILE" 2>/dev/null) || TASK_IDS_LIST=""

            # Extract lines between "### Survivors" and the next "###" heading
            SURVIVOR_LINES=$(sed -n '/^### Survivors$/,/^### /{/^### Survivors$/d;/^### /d;p}' "$PREV_IDEAS_FILE" \
                | grep -E '^\- \*\*#[0-9]' || true)

            while IFS= read -r LINE; do
                [ -z "$LINE" ] && continue
                # Extract the name part: "- **#N Name** — desc" → "Name"
                SURVIVOR_NAME=$(echo "$LINE" | sed 's/^- \*\*#[0-9]* //' | sed 's/\*\*.*//')
                # Convert to kebab-case for matching against task IDs
                SURVIVOR_KEBAB=$(echo "$SURVIVOR_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]/-/g' | sed 's/[^a-z0-9-]//g')

                # Check if any task ID contains this kebab name (or vice versa)
                MATCHED=false
                while IFS= read -r EXISTING_TID; do
                    [ -z "$EXISTING_TID" ] && continue
                    if [[ "$EXISTING_TID" == *"$SURVIVOR_KEBAB"* ]] || [[ "$SURVIVOR_KEBAB" == *"$EXISTING_TID"* ]]; then
                        MATCHED=true
                        break
                    fi
                done <<< "$TASK_IDS_LIST"

                if [ "$MATCHED" = false ]; then
                    UNATTEMPTED="${UNATTEMPTED}
  - ${LINE#- }"
                fi
            done <<< "$SURVIVOR_LINES"
        fi

        # Assemble context block — only include sections that have content
        PRIOR_CONTEXT=""
        CONTEXT_SECTIONS=""
        if [ -n "$APPROVED_LIST" ]; then
            CONTEXT_SECTIONS="${CONTEXT_SECTIONS}
APPROVED (already implemented, do not re-propose):${APPROVED_LIST}
"
        fi
        if [ -n "$REJECTED_LIST" ]; then
            CONTEXT_SECTIONS="${CONTEXT_SECTIONS}
REJECTED (failed validation — consider re-proposing with improvements):${REJECTED_LIST}
"
        fi
        if [ -n "$UNATTEMPTED" ]; then
            CONTEXT_SECTIONS="${CONTEXT_SECTIONS}
UNATTEMPTED SURVIVORS (validated but never implemented — strong candidates):${UNATTEMPTED}
"
        fi
        if [ -n "$CONTEXT_SECTIONS" ]; then
            PRIOR_CONTEXT="
## Prior round ($PREV) results — use this to guide your ideas

Note: This covers only the most recent round. See docs/working/completed-tasks.md
for the complete history of all approved work across all rounds.
${CONTEXT_SECTIONS}
Focus on: (1) re-attempting rejected ideas with fixes for their failure reasons,
(2) proposing unattempted survivors, or (3) identifying genuinely new problems.
Re-attempts and unattempted survivors count as valid ideas — do not dismiss them
as 'already proposed'. Only ideas listed as APPROVED are off-limits."
        fi
    fi

    # -------------------------------------------------------
    # Step 1: Generate ideas
    # -------------------------------------------------------
    echo "Generating ideas (round $ROUND)..."
    claude -p "Follow the divergent-design workflow in ~/.claude/workflows/divergent-design.md.

Generate feature improvement ideas for the workflows in this repo.
Review docs/working/completed-tasks.md for what has already been done.
${PRIOR_CONTEXT}

If you cannot generate at least 3 genuinely new and valuable ideas that
are not already completed or in progress, write only the word DONE on the
first line of your output and stop. Note: re-attempts of rejected ideas
and previously unattempted survivors count as genuinely new ideas.

Otherwise, write the full divergent design output to
docs/working/feature-ideas-round-$ROUND.md"

    # Check for termination
    IDEAS_FILE="$WORKING_DIR/feature-ideas-round-$ROUND.md"
    if [ ! -f "$IDEAS_FILE" ] || head -1 "$IDEAS_FILE" | grep -qi "DONE"; then
        echo "No more good ideas. Stopping after $((ROUND - 1)) rounds."
        update_round_log '.ideas' '{"generated": false, "count": 0}'
        update_round_log '.outcome' '"exhausted"'
        finalize_round_log "$ROUND"
        break
    fi

    # Count ideas from the ideas file (lines starting with a numbered list pattern)
    IDEA_COUNT=$(grep -cE '^\s*[0-9]+\.' "$IDEAS_FILE" 2>/dev/null || echo 0)
    IDEAS_JSON=$(jq -n --argjson count "$IDEA_COUNT" --arg file "feature-ideas-round-$ROUND.md" \
        '{generated: true, count: $count, file: $file}')
    update_round_log '.ideas' "$IDEAS_JSON"

    # -------------------------------------------------------
    # Step 1b: Convergence detection
    # -------------------------------------------------------
    # Extract diagnosed problems from the DD output and compare against
    # prior rounds. If >= CONVERGENCE_THRESHOLD% of problems overlap, stop.
    echo "Checking for convergence (round $ROUND)..."

    # Extract problem summaries as a JSON array of short descriptions
    PROBLEMS_JSON=$(claude -p "Read docs/working/feature-ideas-round-$ROUND.md.

Find the Diagnose section (usually '## 2. Diagnose' or similar).
Extract each diagnosed problem into a short one-line summary (just the core issue, no elaboration).

Output ONLY a JSON array of strings, nothing else. Example:
[\"Session continuity is fragile\", \"No feedback loop from usage\"]

If there is no Diagnose section, output an empty array: []" 2>/dev/null | sed 's/^[[:space:]]*//' | grep -E '^\[' | head -1) || true

    # Validate we got a JSON array; default to empty if extraction failed
    if ! echo "$PROBLEMS_JSON" | jq empty 2>/dev/null; then
        echo "  Warning: could not extract problems, skipping convergence check"
        PROBLEMS_JSON="[]"
    fi

    PROBLEM_COUNT=$(echo "$PROBLEMS_JSON" | jq 'length')

    # Check convergence against prior rounds if we have history and problems.
    # problem-history.json only contains problems that were addressed by approved
    # tasks, so all prior problems are valid convergence baselines.
    PRIOR_PROBLEMS=$(jq -r '[.[]] | add // [] | .[]' "$HISTORY_FILE" 2>/dev/null | sort -u) || true
    if [ "$PROBLEM_COUNT" -gt 0 ] && [ -n "$PRIOR_PROBLEMS" ]; then
        echo "  Comparing $PROBLEM_COUNT problems against prior rounds..."

        # Use Claude to assess semantic overlap between current and prior problems
        # R2 fix: use heredoc to safely pass PRIOR_PROBLEMS (may contain special chars)
        # Variable parts are assigned first, then a quoted heredoc provides the
        # static instruction text — preventing accidental shell expansion.
        OVERLAP_PROMPT="You are comparing two sets of problem descriptions to detect convergence.

CURRENT ROUND PROBLEMS:
${PROBLEMS_JSON}

ALL PRIOR ROUND PROBLEMS:
${PRIOR_PROBLEMS}

"
        read -r -d '' _CONVERGENCE_BODY <<'CONVERGENCE_EOF' || true
For each current problem, determine if it is semantically equivalent to (or a minor restatement of) any prior problem. Two problems overlap if they describe the same underlying issue, even if worded differently.

Output ONLY a single integer: the percentage of current problems that overlap with prior problems (0-100). Nothing else.
CONVERGENCE_EOF
        OVERLAP_PROMPT+="$_CONVERGENCE_BODY"
        OVERLAP_RESULT=$(claude -p "$OVERLAP_PROMPT" 2>/dev/null | grep -oP '\d+' | head -1) || true

        if [ -n "$OVERLAP_RESULT" ] && [ "$OVERLAP_RESULT" -ge "$CONVERGENCE_THRESHOLD" ]; then
            echo "Convergence detected: ${OVERLAP_RESULT}% of problems overlap with prior rounds (threshold: ${CONVERGENCE_THRESHOLD}%)."
            echo "Stopping before round $ROUND implementation ($((ROUND - 1)) rounds completed)."
            echo "[round-$ROUND] CONVERGED: ${OVERLAP_RESULT}% problem overlap" >> "$WORKING_DIR/validation-round-$ROUND.log"
            break
        elif [ -n "$OVERLAP_RESULT" ]; then
            echo "  Overlap: ${OVERLAP_RESULT}% (threshold: ${CONVERGENCE_THRESHOLD}%), continuing."
        fi
    fi

    # Problem history is updated after validation (step 4b) so that only
    # problems addressed by approved tasks are recorded.

    # -------------------------------------------------------
    # Step 2: Filter into independent tasks
    # -------------------------------------------------------
    echo "Filtering ideas into tasks..."
    claude -p "Read docs/working/feature-ideas-round-$ROUND.md.

For each surviving idea from the tradeoff matrix, assess whether it can be
implemented independently in a single Claude Code session (~10-15 minutes
of autonomous work).

Output a JSON array to docs/working/tasks-round-$ROUND.json with fields:
{\"id\": \"short-kebab-case\", \"description\": \"one paragraph task description\",
\"files_touched\": [\"list of files\"], \"independent\": true/false,
\"hypothesis\": \"a falsifiable prediction about the impact of this task\",
\"hypothesis_window\": 3}

The hypothesis field must state a concrete, falsifiable prediction about what
this change will achieve (e.g. 'Adding schema validation will catch at least
1 regression in the next 3 rounds'). The hypothesis_window is the number of
rounds after which the hypothesis should be evaluated (default 3).

Only include tasks where independent is true. Discard tasks that depend on
other tasks in this round."

    TASKS_FILE="$WORKING_DIR/tasks-round-$ROUND.json"
    if [ ! -f "$TASKS_FILE" ]; then
        echo "No tasks file generated. Skipping round."
        update_round_log '.tasks' '{"count": 0, "ids": []}'
        update_round_log '.outcome' '"no_tasks"'
        finalize_round_log "$ROUND"
        continue
    fi

    TASK_IDS=$(jq -r '.[].id' "$TASKS_FILE")
    if [ -z "$TASK_IDS" ]; then
        echo "No independent tasks found. Skipping round."
        update_round_log '.tasks' '{"count": 0, "ids": []}'
        update_round_log '.outcome' '"no_tasks"'
        finalize_round_log "$ROUND"
        continue
    fi

    TASK_COUNT=$(jq 'length' "$TASKS_FILE")
    TASK_IDS_JSON=$(jq '[.[].id]' "$TASKS_FILE")
    TASKS_JSON=$(jq -n --argjson count "$TASK_COUNT" --argjson ids "$TASK_IDS_JSON" \
        '{count: $count, ids: $ids}')
    update_round_log '.tasks' "$TASKS_JSON"

    # -------------------------------------------------------
    # Step 3: Implement in parallel worktrees
    # -------------------------------------------------------
    echo "Launching parallel implementation..."
    PIDS=()
    LAUNCHED_TASKS=""
    for TASK_ID in $TASK_IDS; do
        DESC=$(jq -r ".[] | select(.id==\"$TASK_ID\") | .description" "$TASKS_FILE")
        WT_DIR="$WORKTREE_BASE-$TASK_ID"

        git worktree add "$WT_DIR" -b "feat/r${ROUND}-${TASK_ID}" main 2>/dev/null || {
            echo "Warning: could not create worktree for $TASK_ID, skipping"
            continue
        }

        LAUNCHED_TASKS="${LAUNCHED_TASKS:+$LAUNCHED_TASKS }$TASK_ID"
        echo "  Started: $TASK_ID"
        (
            cd "$WT_DIR"
            claude -p "You are in /away mode. Commit and push when done.

Task: $DESC

Follow the research-plan-implement workflow in ~/.claude/workflows/.
Proceed through research and plan without waiting for human review.
Implement the plan, commit with descriptive messages, and push.

When finished, write a one-line summary of what you did to
docs/working/summary-${TASK_ID}.md"
        ) &
        PIDS+=($!)
    done

    # Wait for all parallel tasks to finish
    echo "Waiting for ${#PIDS[@]} tasks to complete..."
    for PID in "${PIDS[@]}"; do
        wait "$PID" || echo "Warning: task $PID exited with non-zero status"
    done
    echo "All tasks complete."

    # -------------------------------------------------------
    # Step 4: Validate implemented features
    # -------------------------------------------------------
    # Tiered validation pipeline (see docs/decisions/005-validation-step-self-improvement.md)
    #   Phase 1: Structural checks (deterministic, fast)
    #   Phase 2: Claude judge with rubric (TODO)
    #   Phase 3: Self-eval for skill changes (implemented)

    MAX_DIFF_LINES=500
    APPROVED_TASKS=""
    echo "Validating implemented features..."

    for TASK_ID in $LAUNCHED_TASKS; do
        BRANCH="feat/r${ROUND}-${TASK_ID}"
        WT_DIR="$WORKTREE_BASE-$TASK_ID"
        REJECT_REASON=""

        echo "  Checking: $TASK_ID"

        # --- Gate 1a: Did the branch get any commits? ---
        COMMIT_COUNT=$(git rev-list --count "main..$BRANCH" 2>/dev/null || echo 0)
        if [ "$COMMIT_COUNT" -eq 0 ]; then
            REJECT_REASON="no commits on branch"
            record_gate "$TASK_ID" "commits" "fail"
        else
            record_gate "$TASK_ID" "commits" "pass"
        fi

        # Collect diff metadata once for use across gates 1b-1f
        if [ -z "$REJECT_REASON" ]; then
            SHORTSTAT=$(git diff --shortstat "main..$BRANCH")
            CHANGED_FILES=$(git diff --name-only "main..$BRANCH")
            DELETED_FILES=$(git diff --name-only --diff-filter=D "main..$BRANCH")
        fi

        # --- Gate 1b: Diff size cap ---
        if [ -z "$REJECT_REASON" ]; then
            INS=$(echo "$SHORTSTAT" | grep -oP '\d+(?= insertion)' || echo 0)
            DEL=$(echo "$SHORTSTAT" | grep -oP '\d+(?= deletion)' || echo 0)
            TOTAL_CHANGED=$(( INS + DEL ))
            if [ "$TOTAL_CHANGED" -gt "$MAX_DIFF_LINES" ]; then
                REJECT_REASON="diff too large (${TOTAL_CHANGED} lines, max ${MAX_DIFF_LINES})"
                record_gate "$TASK_ID" "diff_size" "fail"
            else
                record_gate "$TASK_ID" "diff_size" "pass"
            fi
        fi

        # --- Gate 1c: File scope enforcement ---
        if [ -z "$REJECT_REASON" ]; then
            DECLARED_FILES=$(jq -r ".[] | select(.id==\"$TASK_ID\") | .files_touched[]" "$TASKS_FILE" 2>/dev/null)

            # Check each actual file is either declared or in docs/working/
            SCOPE_VIOLATIONS=""
            for FILE in $CHANGED_FILES; do
                case "$FILE" in
                    docs/working/*) continue ;;  # always allowed
                esac
                if ! echo "$DECLARED_FILES" | grep -qF "$FILE"; then
                    SCOPE_VIOLATIONS="${SCOPE_VIOLATIONS}  ${FILE}\n"
                fi
            done
            if [ -n "$SCOPE_VIOLATIONS" ]; then
                REJECT_REASON="files outside declared scope:\n${SCOPE_VIOLATIONS}"
                record_gate "$TASK_ID" "file_scope" "fail"
            else
                record_gate "$TASK_ID" "file_scope" "pass"
            fi
        fi

        # --- Gate 1d: Critical file protection ---
        if [ -z "$REJECT_REASON" ]; then
            for FILE in $DELETED_FILES; do
                case "$FILE" in
                    self-improvement.sh|docs/evaluation-rubric.md|CLAUDE.md)
                        REJECT_REASON="deleted critical file: $FILE"
                        record_gate "$TASK_ID" "critical_files" "fail"
                        break
                        ;;
                esac
            done
            if [ -z "$REJECT_REASON" ]; then
                record_gate "$TASK_ID" "critical_files" "pass"
            fi
        fi

        # --- Gate 1e: Run tests if available ---
        if [ -z "$REJECT_REASON" ]; then
            if [ -d "$WT_DIR/test" ]; then
                if command -v bats &>/dev/null; then
                    if ! (cd "$WT_DIR" && bats test/ 2>&1); then
                        REJECT_REASON="bats tests failed"
                        record_gate "$TASK_ID" "tests" "fail"
                    else
                        record_gate "$TASK_ID" "tests" "pass"
                    fi
                else
                    record_gate "$TASK_ID" "tests" "skip"
                fi
            else
                record_gate "$TASK_ID" "tests" "skip"
            fi
        fi

        # --- Gate 1f: Shellcheck on changed .sh files ---
        if [ -z "$REJECT_REASON" ]; then
            if command -v shellcheck &>/dev/null; then
                CHANGED_SH=$(echo "$CHANGED_FILES" | grep '\.sh$' || true)
                if [ -n "$CHANGED_SH" ]; then
                    SHELLCHECK_PASSED=true
                    for SH_FILE in $CHANGED_SH; do
                        if [ -f "$WT_DIR/$SH_FILE" ]; then
                            if ! shellcheck "$WT_DIR/$SH_FILE" 2>&1; then
                                REJECT_REASON="shellcheck failed: $SH_FILE"
                                SHELLCHECK_PASSED=false
                                break
                            fi
                        fi
                    done
                    if $SHELLCHECK_PASSED; then
                        record_gate "$TASK_ID" "shellcheck" "pass"
                    else
                        record_gate "$TASK_ID" "shellcheck" "fail"
                    fi
                else
                    record_gate "$TASK_ID" "shellcheck" "skip"
                fi
            else
                record_gate "$TASK_ID" "shellcheck" "skip"
            fi
        fi

        # --- Gate 1g: Self-eval on changed skills/workflows ---
        if [ -z "$REJECT_REASON" ]; then
            CHANGED_SKILLS=$(echo "$CHANGED_FILES" | grep -E '^(skills|workflows)/.+\.md$' || true)
            if [ -n "$CHANGED_SKILLS" ]; then
                SELF_EVAL_PASSED=true
                for SKILL_FILE in $CHANGED_SKILLS; do
                    if [ ! -f "$WT_DIR/$SKILL_FILE" ]; then
                        continue  # file was deleted, not added/modified
                    fi
                    echo "    Running self-eval on: $SKILL_FILE"
                    EVAL_OUTPUT=$(cd "$WT_DIR" && claude -p "Use the self-eval skill defined in skills/self-eval.md to evaluate $SKILL_FILE.

After writing the report, output exactly one line in this format:
SELF_EVAL_RESULT: <number of Weak scores>

Count only the automated assessment scores (Testability investment, Trigger clarity, Overlap and redundancy, Test coverage, Pipeline readiness). Do not count human-review dimensions." 2>&1) || true

                    WEAK_COUNT=$(echo "$EVAL_OUTPUT" | grep -oP 'SELF_EVAL_RESULT: \K\d+' || echo "")
                    if [ -z "$WEAK_COUNT" ]; then
                        echo "    Warning: self-eval did not produce a parseable result for $SKILL_FILE"
                        echo "[$TASK_ID] WARNING: self-eval unparseable for $SKILL_FILE" >> "$WORKING_DIR/validation-round-$ROUND.log"
                    elif [ "$WEAK_COUNT" -ge 2 ]; then
                        REJECT_REASON="self-eval: $SKILL_FILE has $WEAK_COUNT Weak automated scores"
                        SELF_EVAL_PASSED=false
                        break
                    else
                        echo "    self-eval OK: $SKILL_FILE ($WEAK_COUNT Weak scores)"
                    fi
                done
                if $SELF_EVAL_PASSED; then
                    record_gate "$TASK_ID" "self_eval" "pass"
                else
                    record_gate "$TASK_ID" "self_eval" "fail"
                fi
            else
                record_gate "$TASK_ID" "self_eval" "skip"
            fi
        fi

        # --- Verdict ---
        if [ -n "$REJECT_REASON" ]; then
            echo "    REJECTED: $REJECT_REASON"
            echo "[$TASK_ID] REJECTED: $REJECT_REASON" >> "$WORKING_DIR/validation-round-$ROUND.log"
            record_gate "$TASK_ID" "verdict" "rejected"
            # Clean up rejected worktree and branch
            git worktree remove "$WT_DIR" 2>/dev/null || true
            git branch -D "$BRANCH" 2>/dev/null || true
        else
            echo "    APPROVED"
            echo "[$TASK_ID] APPROVED" >> "$WORKING_DIR/validation-round-$ROUND.log"
            record_gate "$TASK_ID" "verdict" "approved"
            APPROVED_TASKS="${APPROVED_TASKS:+$APPROVED_TASKS }$TASK_ID"
        fi
    done

    if [ -z "$APPROVED_TASKS" ]; then
        echo "No tasks passed validation. Skipping merge."
        update_round_log '.outcome' '"all_rejected"'
        finalize_round_log "$ROUND"
        continue
    fi
    echo "Approved tasks: $APPROVED_TASKS"

    # -------------------------------------------------------
    # Step 4b: Update problem history with solved problems only
    # -------------------------------------------------------
    # Use Claude to identify which diagnosed problems were addressed by the
    # approved tasks. Only those go into problem-history.json — unsolved
    # problems should recur in future rounds without triggering convergence.
    # Note: PROBLEMS_JSON and PROBLEM_COUNT were set in step 1b (problem extraction).
    echo "Updating problem history (solved problems only)..."
    TASK_DESCS=$(jq -r '.[] | "\(.id): \(.description)"' "$TASKS_FILE" 2>/dev/null) || true
    _SOLVED_PROMPT="You are given a list of diagnosed problems and a list of approved task IDs.

DIAGNOSED PROBLEMS (from this round's divergent design):
${PROBLEMS_JSON}

APPROVED TASK IDS:
${APPROVED_TASKS}

TASK DESCRIPTIONS (from docs/working/tasks-round-${ROUND}.json):
${TASK_DESCS}

FEATURE IDEAS FILE: docs/working/feature-ideas-round-${ROUND}.md

"
    read -r -d '' _SOLVED_BODY <<'SOLVED_EOF' || true
Determine which of the diagnosed problems are addressed by at least one approved task.
A problem is 'addressed' if an approved task was designed to solve it (check the match/prune table or tradeoff matrix in the feature ideas file if needed).

Output ONLY a JSON array of the problem strings that were addressed. Include only problems from the DIAGNOSED PROBLEMS list above, using their exact text. If no problems were addressed, output: []
SOLVED_EOF
    _SOLVED_PROMPT+="$_SOLVED_BODY"
    SOLVED_PROBLEMS_JSON=$(claude -p "$_SOLVED_PROMPT" 2>/dev/null | sed 's/^[[:space:]]*//' | grep -E '^\[' | head -1) || true

    # Validate JSON; fall back to empty array
    if ! echo "$SOLVED_PROBLEMS_JSON" | jq empty 2>/dev/null; then
        echo "  Warning: could not determine solved problems, storing none"
        SOLVED_PROBLEMS_JSON="[]"
    fi

    SOLVED_COUNT=$(echo "$SOLVED_PROBLEMS_JSON" | jq 'length')
    echo "  $SOLVED_COUNT of $PROBLEM_COUNT problems addressed by approved tasks"

    if [ "$SOLVED_COUNT" -gt 0 ]; then
        jq --argjson problems "$SOLVED_PROBLEMS_JSON" \
           --arg round "$ROUND" \
           '. + {($round): $problems}' "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" \
           && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
    fi

    # -------------------------------------------------------
    # Step 5: Merge approved features
    # -------------------------------------------------------
    echo "Merging approved features..."
    for TASK_ID in $APPROVED_TASKS; do
        BRANCH="feat/r${ROUND}-${TASK_ID}"
        WT_DIR="$WORKTREE_BASE-$TASK_ID"

        echo "  Merging: $BRANCH"
        MERGE_STATUS="clean"
        git merge "$BRANCH" --no-edit || {
            echo "  Conflict in $BRANCH, attempting auto-resolve..."
            # Hand conflicts to Claude for resolution
            claude -p "There are merge conflicts in the current repo.
Run git status to see conflicted files.
Resolve each conflict by preserving the intent of both sides.
Then git add the resolved files and git commit to complete the merge."
            # Verify the merge actually completed
            # Check for unresolved conflicts (unmerged files)
            if ! git diff --name-only --diff-filter=U | grep -q .; then
                MERGE_STATUS="conflict_resolved"
            else
                MERGE_STATUS="conflict_unresolved"
                echo "  WARNING: Merge conflicts remain unresolved for $BRANCH"
            fi
        }

        # Record merge outcome
        MERGE_TMP=$(mktemp)
        jq --arg tid "$TASK_ID" --arg s "$MERGE_STATUS" \
            '.merges[$tid] = $s' "$ROUND_LOG_FILE" > "$MERGE_TMP" && mv "$MERGE_TMP" "$ROUND_LOG_FILE"

        # Clean up worktree
        git worktree remove "$WT_DIR" 2>/dev/null || true
        git branch -d "$BRANCH" 2>/dev/null || true
    done

    # -------------------------------------------------------
    # Step 6: Update completed tasks log
    # -------------------------------------------------------
    echo "Updating completed tasks log..."
    {
        echo ""
        echo "## Round $ROUND"
        echo ""
        for TASK_ID in $APPROVED_TASKS; do
            SUMMARY_FILE="$WORKING_DIR/summary-${TASK_ID}.md"
            if [ -f "$SUMMARY_FILE" ]; then
                echo "- **$TASK_ID**: $(cat "$SUMMARY_FILE")"
            else
                echo "- **$TASK_ID**: (no summary generated)"
            fi
        done
    } >> "$WORKING_DIR/completed-tasks.md"

    # Finalize round log
    APPROVED_COUNT=0
    for _ in $APPROVED_TASKS; do APPROVED_COUNT=$((APPROVED_COUNT + 1)); done
    LAUNCHED_COUNT=0
    for _ in $LAUNCHED_TASKS; do LAUNCHED_COUNT=$((LAUNCHED_COUNT + 1)); done
    update_round_log '.outcome' '"completed"'
    SUMMARY_JSON=$(jq -n --argjson launched "$LAUNCHED_COUNT" --argjson approved "$APPROVED_COUNT" \
        --argjson rejected "$((LAUNCHED_COUNT - APPROVED_COUNT))" \
        '{launched: $launched, approved: $approved, rejected: $rejected}')
    update_round_log '.summary' "$SUMMARY_JSON"
    finalize_round_log "$ROUND"

    echo "Round $ROUND complete. Report: $WORKING_DIR/round-${ROUND}-report.json"
    echo ""
done

echo "=== All rounds complete ==="
echo "Completed tasks log: $WORKING_DIR/completed-tasks.md"
echo "Round history: $ROUND_HISTORY"
