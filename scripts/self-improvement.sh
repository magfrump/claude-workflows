#!/bin/bash
# Automated self-improvement loop for the claude-workflows repo.
# Runs multiple rounds of: generate ideas → select tasks → implement in
# worktrees → validate → merge approved changes. Stops when ideas are
# exhausted or problem convergence is detected.
#
# Usage:
#   scripts/self-improvement.sh [--seed-file FILE]
#
# Options:
#   --seed-file FILE   Provide a file of seed ideas for the first round's
#                      divergent-design brainstorm. The file contents are
#                      injected into the idea-generation prompt as starting
#                      points (they count toward the idea total). Only used
#                      in round 1; subsequent rounds build on prior results.
#
# Environment variables:
#   CONVERGENCE_THRESHOLD  Percent overlap (0-100) of diagnosed problems
#                          with prior rounds that triggers early stop
#                          (default: 70)
#
# Configuration (hardcoded near top of main block):
#   MAX_ROUNDS=5           Maximum number of improvement rounds
#   WORKTREE_BASE=~/wt     Prefix for git worktree directories
#
# Prerequisites:
#   - jq
#   - claude CLI
#   - git worktree support
#
# Outputs:
#   docs/working/feature-ideas-round-N.md   DD output per round
#   docs/working/tasks-round-N.json         Selected tasks per round
#   docs/working/round-N-report.json        Structured log per round
#   docs/working/round-history.json         Cumulative round history
#   docs/working/completed-tasks.md         Running list of approved work
#   docs/working/hypothesis-log.md          Hypothesis tracking table

set -euo pipefail

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
    # Truncate per-round validation log so re-runs of the same round don't
    # accumulate stale entries from prior runs.
    : > "$WORKING_DIR/validation-round-${round}.log"
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

# Record structured failure details for a gate
# Args: $1 = task_id, $2 = gate name, $3 = JSON object with detail fields
record_gate_detail() {
    local task_id=$1 gate=$2 detail_json=$3
    local detail_key="${gate}_detail"
    local tmp
    tmp=$(mktemp)
    jq --arg tid "$task_id" --arg dk "$detail_key" --argjson detail "$detail_json" \
        '.validation[$tid][$dk] = $detail' "$ROUND_LOG_FILE" > "$tmp" && mv "$tmp" "$ROUND_LOG_FILE"
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

    # Refresh the morning summary after every round so canceled or crashed
    # runs still leave a partial summary on disk.
    if declare -f generate_morning_summary >/dev/null 2>&1; then
        generate_morning_summary "${START_ROUND:-1}" "$round" \
            "$WORKING_DIR/morning-summary.md" "$WORKING_DIR" >/dev/null 2>&1 || true
    fi
}

# --- Shared utility functions (sourced from lib) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/si-functions.sh
source "$SCRIPT_DIR/lib/si-functions.sh"
# shellcheck source=lib/si-input.sh
source "$SCRIPT_DIR/lib/si-input.sh"
# shellcheck source=lib/si-morning-summary.sh
source "$SCRIPT_DIR/lib/si-morning-summary.sh"

# --- Round summary printer ---
# Reads the current ROUND_LOG_FILE to print a one-line human-readable summary.
# Args: $1 = round number, $2 = validation log path
# Output format: Round N: X launched, Y approved, Z rejected (failure modes: ...)
print_round_summary() {
    local round=$1
    local validation_log=$2

    local launched approved rejected failure_modes summary_line
    launched=$(jq '[.validation | to_entries[] | select(.value.verdict != null)] | length' "$ROUND_LOG_FILE")
    approved=$(jq '[.validation | to_entries[] | select(.value.verdict == "approved")] | length' "$ROUND_LOG_FILE")
    rejected=$(jq '[.validation | to_entries[] | select(.value.verdict == "rejected")] | length' "$ROUND_LOG_FILE")

    # Extract failure modes: for each rejected task, find gates that failed
    failure_modes=$(jq -r '
        [.validation | to_entries[] | select(.value.verdict == "rejected") |
         .value | to_entries[] | select(.value == "fail" and .key != "verdict") | .key
        ] | unique | join(", ")' "$ROUND_LOG_FILE")

    if [ -z "$failure_modes" ]; then
        summary_line="Round ${round}: ${launched} launched, ${approved} approved, ${rejected} rejected"
    else
        summary_line="Round ${round}: ${launched} launched, ${approved} approved, ${rejected} rejected (failure modes: ${failure_modes})"
    fi

    echo "$summary_line"
    echo "$summary_line" >> "$validation_log"
}

# --- Main execution guard ---
# Allows sourcing this file for its functions (e.g., in tests) without
# running the top-level loop.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

# Parse arguments
SEED_FILE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --seed-file)
            if [ -z "${2:-}" ]; then
                echo "Error: --seed-file requires a file path argument" >&2
                exit 1
            fi
            SEED_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

if [ -n "$SEED_FILE" ] && [ ! -f "$SEED_FILE" ]; then
    echo "Error: seed file not found: $SEED_FILE" >&2
    exit 1
fi

# Configuration
REPO_DIR=~/claude-workflows
WORKTREE_BASE=~/wt
MAX_ROUNDS=15
WORKING_DIR="$REPO_DIR/docs/working"
ROUND_HISTORY="$WORKING_DIR/round-history.json"

# Check required dependencies
command -v jq &>/dev/null || { echo "Error: jq is required but not found"; exit 1; }

CONVERGENCE_THRESHOLD=${CONVERGENCE_THRESHOLD:-90}  # percent overlap to trigger convergence
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

cd "$REPO_DIR"

# --- Pre-run input ---
# Parse user feedback, priorities, and constraints from si-input.md.
# Variables SI_FEEDBACK, SI_PRIORITIES, SI_OFF_LIMITS, SI_CONTEXT are set
# (empty strings if file is missing or sections are blank).
parse_si_input "$WORKING_DIR/si-input.md" || true

# Build user input context for injection into prompts
USER_INPUT_CONTEXT=""
if [ -n "$SI_FEEDBACK" ]; then
    USER_INPUT_CONTEXT+="
## User feedback

${SI_FEEDBACK}
"
fi
if [ -n "$SI_PRIORITIES" ]; then
    USER_INPUT_CONTEXT+="
## User priorities

${SI_PRIORITIES}
"
fi
if [ -n "$SI_OFF_LIMITS" ]; then
    USER_INPUT_CONTEXT+="
## Off-limits — do not propose ideas touching these topics or files

${SI_OFF_LIMITS}
"
fi
if [ -n "$SI_CONTEXT" ]; then
    USER_INPUT_CONTEXT+="
## User context

${SI_CONTEXT}
"
fi

# Track which round we start at (for morning summary)
START_ROUND=1

for ROUND in $(seq 1 $MAX_ROUNDS); do
    echo "=== Round $ROUND ==="
    init_round_log "$ROUND"

    # -------------------------------------------------------
    # Step 0a: Pre-round health gate
    # -------------------------------------------------------
    # Run scripts/health-check.sh against current main before generating
    # ideas. If gates fail, halt the SI run so a broken main doesn't waste
    # idea-generation and validation effort. The halt is logged to
    # validation-round-N.log and prepended to the morning summary so the
    # next-morning review surfaces the issue immediately.
    echo "Running pre-round health check..."
    HEALTH_LOG=$(mktemp)
    if ! run_pre_round_health_check "$REPO_DIR" "$HEALTH_LOG"; then
        HEALTH_FAILURES=$(summarize_health_check_failures "$HEALTH_LOG")

        echo ""
        echo "=== Pre-round health check FAILED for round $ROUND ==="
        echo "$HEALTH_FAILURES"
        echo ""
        echo "Full health-check output:"
        cat "$HEALTH_LOG"
        echo ""

        {
            echo "[round-$ROUND] HEALTH CHECK FAILED — halting SI run"
            echo ""
            echo "Failed gates and responsible items:"
            echo "$HEALTH_FAILURES"
            echo ""
            echo "Full health-check output:"
            cat "$HEALTH_LOG"
        } >> "$WORKING_DIR/validation-round-$ROUND.log"

        HEALTH_DETAIL=$(jq -n --arg failures "$HEALTH_FAILURES" \
            '{failed_gates: $failures}')
        update_round_log '.health_check' "$HEALTH_DETAIL"
        update_round_log '.outcome' '"health_check_failed"'
        finalize_round_log "$ROUND"

        # Prepend a halt notice to the morning summary so the failure is the
        # first thing the user sees in next-morning review. finalize_round_log
        # just regenerated morning-summary.md, so we read+rewrite it here.
        SUMMARY_PATH="$WORKING_DIR/morning-summary.md"
        if [ -f "$SUMMARY_PATH" ]; then
            HALT_TMP=$(mktemp)
            {
                echo "# SI RUN HALTED — pre-round health check failed (round $ROUND)"
                echo ""
                echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
                echo ""
                echo "## Failed gates and responsible items"
                echo ""
                echo '```'
                echo "$HEALTH_FAILURES"
                echo '```'
                echo ""
                echo "## Full health-check output"
                echo ""
                echo '```'
                cat "$HEALTH_LOG"
                echo '```'
                echo ""
                echo "## Next steps"
                echo ""
                echo "1. Fix the failing gates on \`main\`."
                echo "2. Re-run \`scripts/self-improvement.sh\`."
                echo ""
                echo "Validation log: \`docs/working/validation-round-$ROUND.log\`"
                echo "Round report: \`docs/working/round-$ROUND-report.json\`"
                echo ""
                echo "---"
                echo ""
                cat "$SUMMARY_PATH"
            } > "$HALT_TMP"
            mv "$HALT_TMP" "$SUMMARY_PATH"
        fi

        rm -f "$HEALTH_LOG"

        echo ""
        echo "SI run halted. See:"
        echo "  - $WORKING_DIR/validation-round-$ROUND.log"
        echo "  - $WORKING_DIR/morning-summary.md"
        exit 1
    fi
    echo "[round-$ROUND] HEALTH CHECK PASSED" >> "$WORKING_DIR/validation-round-$ROUND.log"
    rm -f "$HEALTH_LOG"

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

        # --- DD Output Format Contract: Survivors Section ---
        # Parses the "### Survivors" heading from the DD output file
        # (docs/working/feature-ideas-round-N.md).
        #
        # Expected DD output structure (from divergent-design.md step 4):
        #   ### Survivors
        #   - **#1 Some Idea Name** — one-line description
        #   - **#2 Another Idea** — one-line description
        #   ### <next heading>
        #
        # Extraction logic:
        #   1. sed grabs lines between "### Survivors" and the next "### " heading
        #   2. grep filters to lines matching: ^- \*\*#[0-9]
        #   3. For each line, the name is extracted by stripping the "- **#N " prefix
        #      and the "**..." suffix, then converted to kebab-case for fuzzy matching
        #      against existing task IDs.
        #
        # If the DD output changes the Survivors heading level, numbering format
        # (e.g., "#1" prefix), or bullet style, this extraction will silently
        # return no results — causing all survivors to be treated as unattempted.
        # ---
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
                [ -z "$SURVIVOR_KEBAB" ] && continue

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

    # Build seed context (only for round 1)
    SEED_CONTEXT=""
    if [ "$ROUND" -eq 1 ] && [ -n "$SEED_FILE" ]; then
        SEED_CONTENT=$(cat "$SEED_FILE")
        SEED_CONTEXT="
## Seed ideas — use these as starting points

The following ideas have been provided as seeds. Include them in your
brainstorm (they count toward your idea total) and expand on them, but
also generate additional ideas beyond these seeds.

${SEED_CONTENT}
"
    fi

    echo "Generating ideas (round $ROUND)..."
    claude -p "Follow the divergent-design workflow in ~/.claude/workflows/divergent-design.md.

Generate feature improvement ideas for the workflows in this repo.
Review docs/working/completed-tasks.md for what has already been done.
${PRIOR_CONTEXT}${SEED_CONTEXT}${USER_INPUT_CONTEXT}

IMPORTANT — External-impact requirement:
At least 3 of your generated ideas MUST directly improve a workflow or
skill that is used in external projects. Examples of external-facing
artifacts include: divergent-design, research-plan-implement, pr-prep,
user-testing-workflow, bug-diagnosis, codebase-onboarding, and skills
like fact-check, ui-visual-review, cowen-critique, yglesias-critique,
and claude-api. Remaining idea slots may target internal SI
infrastructure. Mark each idea with [EXTERNAL] or [INTERNAL] so this
constraint is verifiable.

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

    # --- DD Output Format Contract: Diagnose Section ---
    # Asks Claude to extract diagnosed problems from the DD output file.
    #
    # Expected DD output structure (from divergent-design.md step 2):
    #   ## 2. Diagnose
    #   <prose listing concrete problems, requirements, and constraints>
    #
    # The prompt instructs Claude to find a heading like "## 2. Diagnose"
    # (or similar) and extract each problem as a one-line summary, returning
    # a JSON array of strings. Example:
    #   ["Session continuity is fragile", "No feedback loop from usage"]
    #
    # Post-processing:
    #   - Leading whitespace is stripped (sed)
    #   - Only the first line matching a JSON array (^\[) is kept
    #   - Result is validated with jq; falls back to [] on parse failure
    #
    # The extracted PROBLEMS_JSON is used in two places:
    #   1. Convergence detection (immediately below) — compared against
    #      problem-history.json to detect repeated problem sets
    #   2. Problem history update (step 4b) — approved tasks' problems are
    #      recorded so future rounds can detect convergence
    #
    # If the DD output omits the Diagnose section or changes its heading
    # format, Claude may return [], skipping convergence detection for
    # that round.
    # ---
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

    # --- DD Output Format Contract: Convergence Detection ---
    # Uses the PROBLEMS_JSON extracted above (a JSON array of problem strings)
    # to detect whether this round's diagnosed problems overlap with prior
    # rounds' problems beyond a threshold (CONVERGENCE_THRESHOLD, default 70%).
    #
    # Data flow:
    #   1. PROBLEMS_JSON (current round) — extracted from DD's Diagnose section
    #   2. PRIOR_PROBLEMS — flattened from problem-history.json, which stores
    #      per-round arrays keyed by round number: {"1": [...], "2": [...]}
    #      Only problems addressed by approved tasks are in the history.
    #   3. Claude compares current vs prior problems for semantic overlap,
    #      returning a single integer (0-100) representing overlap percentage
    #   4. If overlap >= CONVERGENCE_THRESHOLD, the loop breaks (no more rounds)
    #
    # This means convergence is only triggered by re-diagnosing problems that
    # were already solved, not by recurring unsolved problems.
    # ---
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

        if [ -n "$OVERLAP_RESULT" ] && check_convergence_threshold "$OVERLAP_RESULT" "$CONVERGENCE_THRESHOLD"; then
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
    # Build off-limits constraint for task filtering
    TASK_OFF_LIMITS=""
    if [ -n "$SI_OFF_LIMITS" ]; then
        TASK_OFF_LIMITS="

Do not create tasks that touch these topics or files:
${SI_OFF_LIMITS}"
    fi

    claude -p "Read docs/working/feature-ideas-round-$ROUND.md.

For each surviving idea from the tradeoff matrix, assess whether it can be
implemented independently in a single Claude Code session (~10-15 minutes
of autonomous work).

Output a JSON array to docs/working/tasks-round-$ROUND.json with fields:
{\"id\": \"short-kebab-case\", \"description\": \"one paragraph task description\",
\"files_touched\": [\"list of files\"], \"independent\": true/false}

Only include tasks where independent is true. Discard tasks that depend on
other tasks in this round.${TASK_OFF_LIMITS}"

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
    # Step 2b: Validate task JSON schema
    # -------------------------------------------------------
    echo "Validating task JSON schema..."
    SCHEMA_STDERR=$(mktemp)
    VALID_TASKS_JSON=$(validate_task_json "$TASKS_FILE" 2>"$SCHEMA_STDERR")
    VALID_COUNT=$(echo "$VALID_TASKS_JSON" | jq 'length')
    REJECTED_SCHEMA_COUNT=$((TASK_COUNT - VALID_COUNT))

    if [ "$REJECTED_SCHEMA_COUNT" -gt 0 ]; then
        echo "  Schema validation: $REJECTED_SCHEMA_COUNT of $TASK_COUNT tasks rejected"
        echo "[round-$ROUND] SCHEMA: $REJECTED_SCHEMA_COUNT rejected, $VALID_COUNT valid" >> "$WORKING_DIR/validation-round-$ROUND.log"

        # Record schema gate results with failure details
        for TASK_ID in $TASK_IDS; do
            if echo "$VALID_TASKS_JSON" | jq -e ".[] | select(.id == \"$TASK_ID\")" >/dev/null 2>&1; then
                record_gate "$TASK_ID" "schema" "pass"
            else
                record_gate "$TASK_ID" "schema" "fail"
                # Extract the specific schema error from captured stderr
                SCHEMA_ERR=$(grep -F "[$TASK_ID]" "$SCHEMA_STDERR" | sed 's/.*SCHEMA REJECT \[[^]]*\]: //' || echo "unknown schema error")
                record_gate_detail "$TASK_ID" "schema" "$(jq -n --arg err "$SCHEMA_ERR" '{error: $err}')"
            fi
        done
        rm -f "$SCHEMA_STDERR"

        # Overwrite tasks file with valid tasks only
        echo "$VALID_TASKS_JSON" > "$TASKS_FILE"

        # Rebuild task variables
        TASK_IDS=$(jq -r '.[].id' "$TASKS_FILE")
        TASK_COUNT=$(jq 'length' "$TASKS_FILE")
        TASK_IDS_JSON=$(jq '[.[].id]' "$TASKS_FILE")

        if [ "$VALID_COUNT" -eq 0 ]; then
            echo "No tasks passed schema validation. Skipping round."
            update_round_log '.outcome' '"all_schema_rejected"'
            finalize_round_log "$ROUND"
            continue
        fi
    else
        rm -f "$SCHEMA_STDERR"
        echo "  All $TASK_COUNT tasks passed schema validation"
        for TASK_ID in $TASK_IDS; do
            record_gate "$TASK_ID" "schema" "pass"
        done
    fi

    # -------------------------------------------------------
    # Step 3: Implement in parallel worktrees
    # -------------------------------------------------------
    echo "Launching parallel implementation..."
    PIDS=()
    LAUNCHED_TASKS=""
    for TASK_ID in $TASK_IDS; do
        DESC=$(jq -r ".[] | select(.id==\"$TASK_ID\") | .description" "$TASKS_FILE")
        FILES_TOUCHED=$(jq -r ".[] | select(.id==\"$TASK_ID\") | .files_touched[]" "$TASKS_FILE" | paste -sd', ')
        WT_DIR="$WORKTREE_BASE-$TASK_ID"

        git worktree add "$WT_DIR" -b "feat/r${ROUND}-${TASK_ID}" main 2>/dev/null || {
            echo "Warning: could not create worktree for $TASK_ID, skipping"
            continue
        }

        LAUNCHED_TASKS="${LAUNCHED_TASKS:+$LAUNCHED_TASKS }$TASK_ID"

        # Check prior round reports for failed attempts of the same task ID
        PRIOR_FAILURE_BLOCK=""
        for PRIOR_REPORT in "$WORKING_DIR"/round-*-report.json; do
            [ -f "$PRIOR_REPORT" ] || continue
            # Skip the current round's report (it doesn't exist yet, but guard anyway)
            PRIOR_FAILURE_REASON=$(jq -r --arg tid "$TASK_ID" '
                .validation[$tid] // empty |
                select(.verdict == "rejected") |
                # Prefer verdict_detail.reject_reason, fall back to gate-level details
                (.verdict_detail.reject_reason // "") as $reason |
                # Collect structured detail from any failed gate
                ([to_entries[] | select(.key | endswith("_detail")) | .value |
                  to_entries[] | "\(.key): \(.value)"] | join("; ")) as $details |
                if $reason != "" then
                    if $details != "" then "\($reason) [details: \($details)]"
                    else $reason end
                elif $details != "" then $details
                else "unknown failure reason" end
            ' "$PRIOR_REPORT" 2>/dev/null) || continue
            if [ -n "$PRIOR_FAILURE_REASON" ]; then
                PRIOR_ROUND_NUM=$(jq -r '.round' "$PRIOR_REPORT" 2>/dev/null) || PRIOR_ROUND_NUM="?"
                PRIOR_FAILURE_BLOCK="
PRIOR ATTEMPT FAILED — READ THIS BEFORE STARTING:
This task was attempted in round ${PRIOR_ROUND_NUM} and rejected.
Prior attempt failed because: ${PRIOR_FAILURE_REASON}
Address this specifically in your implementation to avoid the same failure.

"
                # Use the most recent failure (last file in glob order)
            fi
        done

        echo "  Started: $TASK_ID"
        (
            cd "$WT_DIR"
            claude -p "You are in /away mode. Commit and push when done.

Task: $DESC
${PRIOR_FAILURE_BLOCK}
FILE SCOPE CONSTRAINT — READ THIS BEFORE STARTING:
You may ONLY create or modify the following files: $FILES_TOUCHED
Files under docs/working/ are also allowed (e.g., research docs, plan docs, summaries).
You MUST NOT create or modify any other files. If during implementation you
discover a need to touch an unlisted file, STOP and document the reason in
docs/working/scope-exception-${TASK_ID}.md instead of making the change.

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
                record_gate_detail "$TASK_ID" "diff_size" "$(jq -n \
                    --argjson total "$TOTAL_CHANGED" --argjson max "$MAX_DIFF_LINES" \
                    '{total_changed: $total, max_allowed: $max}')"
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
                    scripts/self-improvement.sh|docs/evaluation-rubric.md|CLAUDE.md)
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

                    # --- Baseline comparison: evaluate HEAD version first ---
                    BASELINE_WEAK=0
                    if git show "main:$SKILL_FILE" >/dev/null 2>&1; then
                        BASELINE_TMP=$(mktemp -d)
                        # Recreate directory structure so self-eval can find the file
                        mkdir -p "$BASELINE_TMP/$(dirname "$SKILL_FILE")"
                        git show "main:$SKILL_FILE" > "$BASELINE_TMP/$SKILL_FILE"
                        # Copy self-eval skill into temp dir so claude can find it
                        if [ -d "$WT_DIR/skills" ]; then
                            cp -r "$WT_DIR/skills" "$BASELINE_TMP/skills" 2>/dev/null || true
                        fi
                        echo "    Running baseline self-eval on main version of: $SKILL_FILE"
                        BASELINE_OUTPUT=$(cd "$BASELINE_TMP" && claude -p "Use the self-eval skill defined in skills/self-eval.md to evaluate $SKILL_FILE.

After writing the report, output exactly one line in this format:
SELF_EVAL_RESULT: <number of Weak scores>

Count only the automated assessment scores (Testability investment, Trigger clarity, Overlap and redundancy, Test coverage, Pipeline readiness). Do not count human-review dimensions." 2>&1) || true
                        BASELINE_WEAK=$(echo "$BASELINE_OUTPUT" | grep -oP 'SELF_EVAL_RESULT: \K\d+' || echo "0")
                        if [ -z "$BASELINE_WEAK" ]; then
                            BASELINE_WEAK=0
                        fi
                        rm -rf "$BASELINE_TMP"
                        echo "    Baseline: $BASELINE_WEAK Weak scores on main"
                    else
                        echo "    New file (no baseline on main)"
                    fi

                    # --- Evaluate branch version ---
                    EVAL_OUTPUT=$(cd "$WT_DIR" && claude -p "Use the self-eval skill defined in skills/self-eval.md to evaluate $SKILL_FILE.

After writing the report, output exactly one line in this format:
SELF_EVAL_RESULT: <number of Weak scores>

Count only the automated assessment scores (Testability investment, Trigger clarity, Overlap and redundancy, Test coverage, Pipeline readiness). Do not count human-review dimensions." 2>&1) || true

                    WEAK_COUNT=$(echo "$EVAL_OUTPUT" | grep -oP 'SELF_EVAL_RESULT: \K\d+' || echo "")
                    if [ -z "$WEAK_COUNT" ]; then
                        echo "    Warning: self-eval did not produce a parseable result for $SKILL_FILE"
                        echo "[$TASK_ID] WARNING: self-eval unparseable for $SKILL_FILE" >> "$WORKING_DIR/validation-round-$ROUND.log"
                    elif [ "$WEAK_COUNT" -ge 2 ] && [ "$WEAK_COUNT" -gt "$BASELINE_WEAK" ]; then
                        REJECT_REASON="self-eval: $SKILL_FILE has $WEAK_COUNT Weak automated scores (baseline: $BASELINE_WEAK)"
                        # Parse which dimensions scored Weak from the eval table output
                        WEAK_DIMS=$(echo "$EVAL_OUTPUT" | grep -iP '^\|.*\|\s*Weak\s*\|' | sed 's/^|\s*//' | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | paste -sd',' || echo "")
                        SELF_EVAL_DETAIL=$(jq -n \
                            --arg file "$SKILL_FILE" \
                            --argjson weak_count "$WEAK_COUNT" \
                            --arg weak_dimensions "$WEAK_DIMS" \
                            --argjson baseline_weak "$BASELINE_WEAK" \
                            '{file: $file, weak_count: $weak_count, baseline_weak: $baseline_weak, weak_dimensions: ($weak_dimensions | split(",") | map(select(length > 0)))}')
                        SELF_EVAL_PASSED=false
                        break
                    else
                        echo "    self-eval OK: $SKILL_FILE ($WEAK_COUNT Weak, baseline: $BASELINE_WEAK)"
                    fi
                done
                if $SELF_EVAL_PASSED; then
                    record_gate "$TASK_ID" "self_eval" "pass"
                else
                    record_gate "$TASK_ID" "self_eval" "fail"
                    if [ -n "${SELF_EVAL_DETAIL:-}" ]; then
                        record_gate_detail "$TASK_ID" "self_eval" "$SELF_EVAL_DETAIL"
                    fi
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
            record_gate_detail "$TASK_ID" "verdict" "$(jq -n --arg reason "$REJECT_REASON" '{reject_reason: $reason}')"
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

    # Print human-readable round summary after merges
    print_round_summary "$ROUND" "$WORKING_DIR/validation-round-$ROUND.log"

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

# Morning summary is refreshed inside finalize_round_log after every round,
# so the file at $WORKING_DIR/morning-summary.md is already current.
echo "Completed tasks log: $WORKING_DIR/completed-tasks.md"
echo "Round history: $ROUND_HISTORY"
echo "Morning summary: $WORKING_DIR/morning-summary.md"

fi  # end main-execution guard
