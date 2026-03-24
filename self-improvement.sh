#!/bin/bash
set -euo pipefail

# Configuration
REPO_DIR=~/claude-workflows
WORKTREE_BASE=~/wt
MAX_ROUNDS=5
WORKING_DIR="$REPO_DIR/docs/working"

mkdir -p "$WORKING_DIR"
touch "$WORKING_DIR/completed-tasks.md"

cd "$REPO_DIR"

for ROUND in $(seq 1 $MAX_ROUNDS); do
    echo "=== Round $ROUND ==="

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

        # Get tasks that have a hypothesis and whose window has elapsed
        ELIGIBLE=$(jq -r --argjson current "$ROUND" --argjson prior "$PRIOR_ROUND" \
            '[.[] | select(.hypothesis != null and .hypothesis != "") |
              select(($current - $prior) >= (.hypothesis_window // 3))] | .[]? | .id' \
            "$PRIOR_TASKS" 2>/dev/null) || true

        for TASK_ID in $ELIGIBLE; do
            # Skip if already recorded in the log
            if grep -qF "| $TASK_ID |" "$HYPOTHESIS_LOG" 2>/dev/null; then
                continue
            fi

            # Check if the task was actually completed (approved and merged)
            if ! grep -qF "**$TASK_ID**" "$WORKING_DIR/completed-tasks.md" 2>/dev/null; then
                continue
            fi

            HYPOTHESIS=$(jq -r ".[] | select(.id==\"$TASK_ID\") | .hypothesis" "$PRIOR_TASKS")
            WINDOW=$(jq -r ".[] | select(.id==\"$TASK_ID\") | .hypothesis_window // 3" "$PRIOR_TASKS")

            echo "  Evaluating hypothesis for: $TASK_ID"
            EVAL_RESULT=$(claude -p "Evaluate this hypothesis from round $PRIOR_ROUND (now round $ROUND):

Task: $TASK_ID
Hypothesis: $HYPOTHESIS
Window: $WINDOW rounds

Review the repo state, git log, completed-tasks.md, and validation logs to
determine whether the hypothesis was CONFIRMED, REFUTED, or INCONCLUSIVE.

Output exactly one line in this format:
HYPOTHESIS_VERDICT: <CONFIRMED|REFUTED|INCONCLUSIVE> | <one-sentence evidence summary>" 2>&1) || true

            VERDICT_LINE=$(echo "$EVAL_RESULT" | grep -oP 'HYPOTHESIS_VERDICT: \K.*' || echo "INCONCLUSIVE | evaluation failed to parse")
            OUTCOME=$(echo "$VERDICT_LINE" | cut -d'|' -f1 | xargs)
            EVIDENCE=$(echo "$VERDICT_LINE" | cut -d'|' -f2- | xargs)

            # Append to hypothesis log
            echo "| $PRIOR_ROUND | $TASK_ID | $HYPOTHESIS | $WINDOW | $ROUND | $OUTCOME | $EVIDENCE |" >> "$HYPOTHESIS_LOG"
            echo "    $TASK_ID: $OUTCOME"
        done
    done

    # -------------------------------------------------------
    # Step 1: Generate ideas
    # -------------------------------------------------------
    echo "Generating ideas (round $ROUND)..."
    claude -p "Follow the divergent-design workflow in ~/.claude/workflows/divergent-design.md.

Generate feature improvement ideas for the workflows in this repo.
Review docs/working/completed-tasks.md for what has already been done.

If you cannot generate at least 3 genuinely new and valuable ideas that
are not already completed or in progress, write only the word DONE on the
first line of your output and stop.

Otherwise, write the full divergent design output to
docs/working/feature-ideas-round-$ROUND.md" 

    # Check for termination
    IDEAS_FILE="$WORKING_DIR/feature-ideas-round-$ROUND.md"
    if [ ! -f "$IDEAS_FILE" ] || head -1 "$IDEAS_FILE" | grep -qi "DONE"; then
        echo "No more good ideas. Stopping after $((ROUND - 1)) rounds."
        break
    fi

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
        continue
    fi

    TASK_IDS=$(jq -r '.[].id' "$TASKS_FILE")
    if [ -z "$TASK_IDS" ]; then
        echo "No independent tasks found. Skipping round."
        continue
    fi

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
            fi
        fi

        # --- Gate 1d: Critical file protection ---
        if [ -z "$REJECT_REASON" ]; then
            for FILE in $DELETED_FILES; do
                case "$FILE" in
                    self-improvement.sh|docs/evaluation-rubric.md|CLAUDE.md)
                        REJECT_REASON="deleted critical file: $FILE"
                        break
                        ;;
                esac
            done
        fi

        # --- Gate 1e: Run tests if available ---
        if [ -z "$REJECT_REASON" ] && [ -d "$WT_DIR/test" ]; then
            if command -v bats &>/dev/null; then
                if ! (cd "$WT_DIR" && bats test/ 2>&1); then
                    REJECT_REASON="bats tests failed"
                fi
            fi
        fi

        # --- Gate 1f: Shellcheck on changed .sh files ---
        if [ -z "$REJECT_REASON" ] && command -v shellcheck &>/dev/null; then
            CHANGED_SH=$(echo "$CHANGED_FILES" | grep '\.sh$' || true)
            for SH_FILE in $CHANGED_SH; do
                if [ -f "$WT_DIR/$SH_FILE" ]; then
                    if ! shellcheck "$WT_DIR/$SH_FILE" 2>&1; then
                        REJECT_REASON="shellcheck failed: $SH_FILE"
                        break
                    fi
                fi
            done
        fi

        # --- Gate 1g: Self-eval on changed skills/workflows ---
        if [ -z "$REJECT_REASON" ]; then
            CHANGED_SKILLS=$(echo "$CHANGED_FILES" | grep -E '^(skills|workflows)/.+\.md$' || true)
            if [ -n "$CHANGED_SKILLS" ]; then
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
                        break
                    else
                        echo "    self-eval OK: $SKILL_FILE ($WEAK_COUNT Weak scores)"
                    fi
                done
            fi
        fi

        # --- Verdict ---
        if [ -n "$REJECT_REASON" ]; then
            echo "    REJECTED: $REJECT_REASON"
            echo "[$TASK_ID] REJECTED: $REJECT_REASON" >> "$WORKING_DIR/validation-round-$ROUND.log"
            # Clean up rejected worktree and branch
            git worktree remove "$WT_DIR" 2>/dev/null || true
            git branch -D "$BRANCH" 2>/dev/null || true
        else
            echo "    APPROVED"
            echo "[$TASK_ID] APPROVED" >> "$WORKING_DIR/validation-round-$ROUND.log"
            APPROVED_TASKS="${APPROVED_TASKS:+$APPROVED_TASKS }$TASK_ID"
        fi
    done

    if [ -z "$APPROVED_TASKS" ]; then
        echo "No tasks passed validation. Skipping merge."
        continue
    fi
    echo "Approved tasks: $APPROVED_TASKS"

    # -------------------------------------------------------
    # Step 5: Merge approved features
    # -------------------------------------------------------
    echo "Merging approved features..."
    for TASK_ID in $APPROVED_TASKS; do
        BRANCH="feat/r${ROUND}-${TASK_ID}"
        WT_DIR="$WORKTREE_BASE-$TASK_ID"

        echo "  Merging: $BRANCH"
        git merge "$BRANCH" --no-edit || {
            echo "  Conflict in $BRANCH, attempting auto-resolve..."
            # Hand conflicts to Claude for resolution
            claude -p "There are merge conflicts in the current repo.
Run git status to see conflicted files.
Resolve each conflict by preserving the intent of both sides.
Then git add the resolved files and git commit to complete the merge."
        }

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

    echo "Round $ROUND complete."
    echo ""
done

echo "=== All rounds complete ==="
echo "Completed tasks log: $WORKING_DIR/completed-tasks.md"