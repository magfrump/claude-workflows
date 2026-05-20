#!/bin/bash
# Shared utility functions for the self-improvement loop.
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   validate_task_json   — Schema-validate a tasks JSON file
#   check_convergence_threshold — Compare overlap % against a threshold
#   print_gate_stats     — Print per-gate pass/fail/skip rates from round history
#   find_task_lineage    — Grep round-changelog.md for prior tasks that touched given files
#   prepend_lineage_to_plan — Prepend a Lineage section to a task's plan doc
#   remove_worktree_and_branch — Force-remove a worktree and delete its branch
#   append_approved_hypotheses — Append approved-task hypotheses to hypothesis-log.md
#
# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: this file should be sourced, not executed directly" >&2
    exit 1
fi

# Allowed values for the per-task category field. Kept as a single-source-of-
# truth string so the planner prompt, validator, and morning summary agree.
# Why three values only: avoids bikeshedding while still surfacing when feature
# work is crowding out maintenance and data-pipeline repairs.
TASK_CATEGORIES_ALLOWED="feature maintenance data-pipeline"

# Allowed values for the per-task hypothesis evaluator (decision 012 pillar 1).
# "script" = morning summary can check preconditions against the invocation
# logger; "user" = only a human observation can decide the outcome. Either is
# first-class; the field declares who is responsible for evaluation.
HYPOTHESIS_EVALUATORS_ALLOWED="script user"

# Allowed values for the per-task hypothesis source (decision 012 pillar 3).
# "user" = hypothesis inherited verbatim from a si-input.md priority; "planner"
# = planner authored it under the pillar-2 adversarial framing. The morning
# summary tags planner-authored open hypotheses so the user can review framing.
HYPOTHESIS_SOURCES_ALLOWED="user planner"

# Allowed keys for the per-task `requires` precondition object (decision 012
# pillar 1). Centralised here because the validator's jq filter and its human-
# readable error message both need them; the morning-summary parser still has
# per-key handling (each key has its own type and comparison semantics).
HYPOTHESIS_REQUIRES_KEYS_ALLOWED="metric_logged, invocations, days_elapsed"
HYPOTHESIS_REQUIRES_KEYS_ALLOWED_JSON='["metric_logged","invocations","days_elapsed"]'

# --- Task lineage from round changelog ---
# Walks docs/working/round-changelog.md and emits "Round N: task-id" for each
# prior task whose entry mentions any of the given files. Files are matched by
# full path OR basename — the changelog mixes both styles, so we accept either.
# Dedupes (round, task) pairs. No-ops when the changelog is missing or no files
# are supplied.
# Args: $1 = changelog path, $2.. = files to search for
# Stdout: zero or more "Round N: task-id" lines
find_task_lineage() {
    local changelog="$1"
    shift
    [ -f "$changelog" ] || return 0
    [ "$#" -eq 0 ] && return 0

    # Build a |-delimited list of needles (full path + basename for each file).
    # Using literal substring matching via awk's index() avoids regex-escape bugs
    # on paths containing dots, slashes, etc.
    local needles=""
    for f in "$@"; do
        needles+="${f}|$(basename "$f")|"
    done
    needles="${needles%|}"

    awk -v needles="$needles" '
        BEGIN { n = split(needles, ns, "|") }
        /^## Round / {
            current_round = $0
            sub(/^## /, "", current_round)
            next
        }
        /^- \*\*[a-zA-Z0-9_-]+\*\*/ {
            for (i = 1; i <= n; i++) {
                if (length(ns[i]) > 0 && index($0, ns[i]) > 0) {
                    if (match($0, /\*\*[a-zA-Z0-9_-]+\*\*/)) {
                        tid = substr($0, RSTART+2, RLENGTH-4)
                        key = current_round "||" tid
                        if (!(key in seen)) {
                            seen[key] = 1
                            print current_round ": " tid
                        }
                    }
                    break
                }
            }
        }
    ' "$changelog"
}

# --- Prepend lineage section to a task plan doc ---
# Computes lineage via find_task_lineage; if any prior tasks are found, writes
# a "## Lineage" section to the top of plan_path (creating the file as a stub
# if it does not yet exist, prepending if it does). When the existing plan
# already has a Lineage section at the top, leaves it alone (idempotent).
# When no prior lineage is found, does nothing.
# Args: $1 = changelog path, $2 = plan_path, $3.. = files
prepend_lineage_to_plan() {
    local changelog="$1"
    local plan_path="$2"
    shift 2

    local lineage
    lineage=$(find_task_lineage "$changelog" "$@")
    [ -z "$lineage" ] && return 0

    # Idempotency: if the plan already starts with "## Lineage", skip.
    if [ -f "$plan_path" ] && head -n 1 "$plan_path" 2>/dev/null | grep -q '^## Lineage'; then
        return 0
    fi

    local header
    header=$'## Lineage\n\nPrior rounds that touched these files:\n'
    while IFS= read -r line; do
        header+="- ${line}"$'\n'
    done <<< "$lineage"
    header+=$'\n'

    mkdir -p "$(dirname "$plan_path")"
    if [ -f "$plan_path" ]; then
        local tmp
        tmp=$(mktemp)
        printf '%s' "$header" > "$tmp"
        cat "$plan_path" >> "$tmp"
        mv "$tmp" "$plan_path"
    else
        printf '%s' "$header" > "$plan_path"
    fi
}

# --- Worktree cleanup ---
# Force-remove a worktree and delete its branch. --force on worktree remove
# handles validation leftovers (untracked files from self-eval etc.) that
# would otherwise leave orphan directories.
# Args: $1 = worktree dir, $2 = branch name, $3 = -d (safe) or -D (force) — default -d
remove_worktree_and_branch() {
    local wt=$1 br=$2 delete_mode=${3:--d}
    git worktree remove --force "$wt" 2>/dev/null || true
    git branch "$delete_mode" "$br" 2>/dev/null || true
}

# --- Task JSON schema validation ---
# Validates each task in a tasks JSON file against the expected schema.
# Outputs a filtered JSON array (valid tasks only) to stdout.
# Prints rejection reasons to stderr.
# Args: $1 = path to tasks JSON file
validate_task_json() {
    local tasks_file=$1
    local valid_tasks="[]"
    local task_count
    task_count=$(jq 'length' "$tasks_file")

    # Derive round number and working dir from the conventional path
    # "<working_dir>/tasks-round-<N>.json". When the path does not match
    # (e.g. unit tests passing /tmp/tasks.json), lineage seeding is skipped.
    local seed_round="" seed_dir="" seed_changelog=""
    local tasks_basename
    tasks_basename=$(basename "$tasks_file")
    if [[ "$tasks_basename" =~ ^tasks-round-([0-9]+)\.json$ ]]; then
        seed_round="${BASH_REMATCH[1]}"
        seed_dir=$(dirname "$tasks_file")
        seed_changelog="$seed_dir/round-changelog.md"
    fi

    for i in $(seq 0 $((task_count - 1))); do
        local task
        task=$(jq ".[$i]" "$tasks_file")
        local tid
        tid=$(echo "$task" | jq -r '.id // empty')

        # Check required fields and types
        local schema_err=""
        schema_err=$(echo "$task" | jq -r '
            def check:
                if (.id | type) != "string" or (.id | length) == 0 then "id must be a non-empty string"
                elif (.description | type) != "string" or (.description | length) == 0 then "description must be a non-empty string"
                elif (.files_touched | type) != "array" or (.files_touched | length) == 0 then "files_touched must be a non-empty array"
                elif (.independent | type) != "boolean" then "independent must be a boolean"
                else empty
                end;
            check
        ')

        if [ -n "$schema_err" ]; then
            echo "  SCHEMA REJECT [${tid:-task-$i}]: $schema_err" >&2
            continue
        fi

        # Check category field. Strict-when-present: invalid values reject;
        # absence is a lint warning so the loop keeps running while the
        # planner prompt is still being tuned to emit categories reliably.
        local category
        category=$(echo "$task" | jq -r '.category // ""')
        if [ -z "$category" ]; then
            echo "  LINT WARNING [$tid]: category missing — planner should assign one of: $TASK_CATEGORIES_ALLOWED" >&2
        elif ! echo " $TASK_CATEGORIES_ALLOWED " | grep -q " $category "; then
            echo "  SCHEMA REJECT [$tid]: category must be one of: $TASK_CATEGORIES_ALLOWED (got: $category)" >&2
            continue
        fi

        # Check evaluator field (decision 012 pillar 1). Soft-introduce as a
        # LINT WARNING when absent — old planner output predates this field, so
        # rejecting on absence would block the loop. Strict-when-present.
        local evaluator
        evaluator=$(echo "$task" | jq -r '.evaluator // ""')
        if [ -z "$evaluator" ]; then
            echo "  LINT WARNING [$tid]: evaluator missing — planner should assign one of: $HYPOTHESIS_EVALUATORS_ALLOWED" >&2
        elif ! echo " $HYPOTHESIS_EVALUATORS_ALLOWED " | grep -q " $evaluator "; then
            echo "  SCHEMA REJECT [$tid]: evaluator must be one of: $HYPOTHESIS_EVALUATORS_ALLOWED (got: $evaluator)" >&2
            continue
        fi

        # Check requires field (decision 012 pillar 1). Optional, but when
        # present must be an object with only the allowed keys and the right
        # value types. Unknown keys would silently make a hypothesis
        # uneval­uable, so they reject.
        local requires_err
        requires_err=$(echo "$task" | jq -r \
            --argjson allowed "$HYPOTHESIS_REQUIRES_KEYS_ALLOWED_JSON" \
            --arg allowed_human "$HYPOTHESIS_REQUIRES_KEYS_ALLOWED" '
            if (has("requires") | not) then empty
            elif (.requires | type) != "object" then "requires must be an object"
            else
                ([.requires | keys[] | select(. as $k |
                    $allowed | index($k) | not)] | first // null) as $bad_key |
                if $bad_key != null then "requires has unknown key: \($bad_key); allowed: \($allowed_human)"
                elif (.requires | has("metric_logged")) and (.requires.metric_logged | type) != "string" then "requires.metric_logged must be a string"
                elif (.requires | has("invocations"))   and ((.requires.invocations   | type) != "number" or (.requires.invocations   | floor) != .requires.invocations) then "requires.invocations must be an integer"
                elif (.requires | has("days_elapsed"))  and ((.requires.days_elapsed  | type) != "number" or (.requires.days_elapsed  | floor) != .requires.days_elapsed)  then "requires.days_elapsed must be an integer"
                else empty
                end
            end
        ')
        if [ -n "$requires_err" ]; then
            echo "  SCHEMA REJECT [$tid]: $requires_err" >&2
            continue
        fi

        # Check hypothesis_source field (decision 012 pillar 3). Soft-introduce
        # like evaluator — absence is a LINT WARNING, an invalid value rejects.
        local hyp_source
        hyp_source=$(echo "$task" | jq -r '.hypothesis_source // ""')
        if [ -z "$hyp_source" ]; then
            echo "  LINT WARNING [$tid]: hypothesis_source missing — planner should assign one of: $HYPOTHESIS_SOURCES_ALLOWED" >&2
        elif ! echo " $HYPOTHESIS_SOURCES_ALLOWED " | grep -q " $hyp_source "; then
            echo "  SCHEMA REJECT [$tid]: hypothesis_source must be one of: $HYPOTHESIS_SOURCES_ALLOWED (got: $hyp_source)" >&2
            continue
        fi

        # Check files_touched entries for glob patterns and valid parent directories
        local ft_errors=""
        local ft_count
        ft_count=$(echo "$task" | jq '.files_touched | length')
        for j in $(seq 0 $((ft_count - 1))); do
            local fpath
            fpath=$(echo "$task" | jq -r ".files_touched[$j]")

            # Reject glob patterns (*, ?, [)
            if echo "$fpath" | grep -qE '[*?[]'; then
                ft_errors="${ft_errors}glob pattern in files_touched: $fpath; "
                continue
            fi

            # Check parent directory exists in the repo
            local parent_dir grandparent_dir
            parent_dir=$(dirname "$fpath")
            grandparent_dir=$(dirname "$parent_dir")
            if [ "$parent_dir" != "." ] && [ ! -d "$parent_dir" ]; then
                if [ "$grandparent_dir" = "." ] || [ -d "$grandparent_dir" ]; then
                    # Single-level missing dir: warn but allow (unblocks .gitkeep creation)
                    echo "  LINT WARNING [$tid]: parent directory does not exist: $parent_dir (for $fpath)" >&2
                else
                    ft_errors="${ft_errors}parent directory does not exist: $parent_dir (for $fpath); "
                fi
            fi
        done

        if [ -n "$ft_errors" ]; then
            echo "  SCHEMA REJECT [$tid]: $ft_errors" >&2
            continue
        fi

        # Task passed validation — add to valid list
        valid_tasks=$(echo "$valid_tasks" | jq --argjson t "$task" '. += [$t]')

        # Seed plan stub with lineage from prior rounds. Only runs when the
        # tasks file follows the conventional path (round number recoverable).
        if [ -n "$seed_round" ] && [ -n "$tid" ]; then
            local plan_path="$seed_dir/r${seed_round}-${tid}-plan.md"
            local files_array=()
            while IFS= read -r f; do
                [ -n "$f" ] && files_array+=("$f")
            done < <(echo "$task" | jq -r '.files_touched[]')
            if [ "${#files_array[@]}" -gt 0 ]; then
                prepend_lineage_to_plan "$seed_changelog" "$plan_path" "${files_array[@]}"
            fi
        fi
    done

    echo "$valid_tasks"
}

# --- Convergence threshold check ---
# Pure function: compares an overlap percentage against a threshold.
# Args: $1 = overlap percentage (integer 0-100), $2 = threshold (integer 0-100)
# Returns: 0 if overlap >= threshold (at-or-above), 1 if below.
# Returns 1 (below) for empty or non-integer input.
check_convergence_threshold() {
    local overlap="${1:-}"
    local threshold="${2:-}"

    # Validate both inputs are non-empty integers
    if [[ -z "$overlap" || -z "$threshold" ]]; then
        return 1
    fi
    if ! [[ "$overlap" =~ ^[0-9]+$ && "$threshold" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if [ "$overlap" -ge "$threshold" ]; then
        return 0
    else
        return 1
    fi
}

# --- Gate stats dashboard ---
# Reads round-history.json (or a provided path) and prints per-gate pass/fail/skip
# rates aggregated across all rounds.
# Args: $1 = round_history path (optional — defaults to docs/working/round-history.json)
# Stdout: formatted gate stats table
# Returns 1 if the file is missing, empty, or not valid JSON.
print_gate_stats() {
    local repo_root
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    local history_file="${1:-$repo_root/docs/working/round-history.json}"

    if [ ! -f "$history_file" ]; then
        echo "No round history found at $history_file" >&2
        return 1
    fi

    # Validate JSON and extract gate stats in one jq call.
    # For each validation entry, iterate over keys that are not "verdict",
    # and count pass/fail/skip per gate name.
    local stats
    stats=$(jq -r '
        if type != "array" then error("not an array") else . end |
        [ .[] | .validation // {} | to_entries[] | .value | to_entries[] |
          select(.key != "verdict") ] |
        if length == 0 then error("no gate data") else . end |
        group_by(.key) |
        map({
            gate: .[0].key,
            pass: ([.[] | select(.value == "pass")] | length),
            fail: ([.[] | select(.value == "fail")] | length),
            skip: ([.[] | select(.value == "skip")] | length),
            total: length
        }) |
        sort_by(.gate) |
        .[] |
        "\(.gate)\t\(.pass)\t\(.fail)\t\(.skip)\t\(.total)"
    ' "$history_file" 2>/dev/null)

    if [ -z "$stats" ]; then
        echo "No gate evaluation data found." >&2
        return 1
    fi

    echo ""
    echo "=== Gate Stats (all rounds) ==="
    echo ""
    printf "%-25s %s\n" "GATE" "PASS RATE"
    printf "%-25s %s\n" "-------------------------" "-------------------"

    while IFS=$'\t' read -r gate pass fail skip total; do
        if [ "$total" -gt 0 ]; then
            local pct=$(( (pass * 100) / total ))
            local detail="${pass}/${total} pass (${pct}%)"
            if [ "$fail" -gt 0 ]; then
                detail="${detail}, ${fail} fail"
            fi
            if [ "$skip" -gt 0 ]; then
                detail="${detail}, ${skip} skip"
            fi
            printf "%-25s %s\n" "$gate" "$detail"
        fi
    done <<< "$stats"

    echo ""
}

# --- Append approved-task hypotheses to hypothesis-log.md ---
# Reads tasks-round-N.json, picks rows whose IDs appear in the approved list,
# and appends one markdown table row per task to hypothesis-log.md. Outcome
# columns are left empty — the user fills them in via the morning summary.
#
# Header columns expected (created if file is absent):
#   Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence
#
# Why approved-only: rejected tasks never landed, so their hypotheses describe
# code that doesn't exist. Logging them would clutter the open-hypothesis list
# with rows that can never resolve.
#
# Args: $1 = round number
#       $2 = tasks JSON file path
#       $3 = hypothesis log path
#       $4 = space-separated list of approved task IDs
append_approved_hypotheses() {
    local round="$1" tasks_file="$2" log_file="$3" approved_ids="$4"
    [ -f "$tasks_file" ] || return 0
    [ -n "$approved_ids" ] || return 0

    if [ ! -f "$log_file" ]; then
        cat > "$log_file" <<'HEADER'
# Hypothesis Log

Tracks falsifiable predictions made at task creation time and their outcomes.

| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|--------|-----------|----------|------------------|---------|-------------|----------|
HEADER
    fi

    # Guarantee a trailing newline so the first appended row doesn't glom onto
    # the last existing line.
    if [ -s "$log_file" ] && [ "$(tail -c1 "$log_file" | wc -l)" -eq 0 ]; then
        printf '\n' >> "$log_file"
    fi

    local tid fields hyp hyp_source window evaluator requires
    for tid in $approved_ids; do
        # Single jq pass per task — emit the five fields joined by the ASCII
        # Unit Separator so a stale task file isn't reparsed once per column.
        # Tab won't work as a delimiter for `read` because it's IFS-whitespace
        # and runs of whitespace coalesce, eating empty fields. `requires` is
        # flattened to key=value;key=value so it fits in a single markdown cell.
        fields=$(jq -r --arg id "$tid" '
            .[] | select(.id == $id) | [
                .hypothesis // "",
                .hypothesis_source // "",
                (.hypothesis_window // "" | tostring),
                .evaluator // "",
                ((.requires // {}) | to_entries | map("\(.key)=\(.value)") | join(";"))
            ] | join("")
        ' "$tasks_file" 2>/dev/null)
        IFS=$'\037' read -r hyp hyp_source window evaluator requires <<< "$fields"

        if [ -z "$hyp" ]; then
            echo "  Warning: no hypothesis recorded for approved task: $tid" >&2
            continue
        fi
        [[ "$window" =~ ^[0-9]+$ ]] || window="3"

        # Escape pipe chars so they don't break the markdown table.
        hyp="${hyp//|/\\|}"

        printf '| %s | %s | %s | %s | %s | %s | %s | %d | | | |\n' \
            "$round" "$tid" "$hyp" "$hyp_source" "$window" "$evaluator" "$requires" "$((round + window))" >> "$log_file"
    done
}

# --- Test-gate baseline helpers (failure-isolation) ---
# The `tests` gate runs the whole bats suite inside each task's worktree. A
# single pre-existing failure on the base commit (e.g. a deleted file still
# referenced by a test) would otherwise reject EVERY task in the run, even
# though none of them touched the failing test. These helpers let the gate
# charge a task only for failures it INTRODUCES, by diffing the worktree's
# failing tests against a baseline captured on the base commit at run start.
#
# Match on test NAME, not TAP number: bats renumbers tests across worktrees
# (suite ordering differs), so "not ok 43 foo" and "not ok 55 foo" are the
# same failure. Names are stable; numbers are not.

# tap_failing_names — read TAP on stdin, print sorted-unique failing test names.
# Strips the leading "not ok <N> " and any trailing " # ..." TAP directive.
# Stdout: zero or more test-description lines, sorted and de-duplicated.
tap_failing_names() {
    grep -E '^not ok ' \
        | sed -E 's/^not ok [0-9]+ //; s/ # .*$//' \
        | LC_ALL=C sort -u
}

# tap_new_failures — read TAP on stdin, print failing test names that are NOT
# present in the baseline file. These are the failures a task introduced.
# Args: $1 = baseline file (one failing test name per line; missing/empty = no
#            baseline, so every current failure is "new").
# Stdout: zero or more new-failure names, sorted; empty output = no new failures.
tap_new_failures() {
    local baseline_file=$1
    local current
    current=$(tap_failing_names)
    [ -z "$current" ] && return 0
    if [ -n "$baseline_file" ] && [ -f "$baseline_file" ]; then
        # Lines in current that are not in baseline.
        LC_ALL=C comm -23 \
            <(printf '%s\n' "$current") \
            <(LC_ALL=C sort -u "$baseline_file")
    else
        printf '%s\n' "$current"
    fi
}
