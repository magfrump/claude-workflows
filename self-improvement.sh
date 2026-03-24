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
\"files_touched\": [\"list of files\"], \"independent\": true/false}

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
    #   Phase 3: Self-eval for skill changes (TODO)

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