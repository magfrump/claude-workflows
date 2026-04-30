#!/bin/bash
# Token-usage tracking for self-improvement implementer agents.
#
# After an implementer agent finishes in its worktree, locates the
# claude CLI session log it produced and records tokens_in/tokens_out
# into the per-round JSON log.
#
# Sourced by scripts/self-improvement.sh — do not execute directly.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: this file should be sourced, not executed directly" >&2
    exit 1
fi

# Encode an absolute filesystem path into the form the claude CLI uses
# for its per-project session-log directory under ~/.claude/projects/:
# every "/" becomes "-".
_si_encode_project_dir() {
    local path="$1"
    printf '%s' "${path//\//-}"
}

# Sum input/output tokens from a single session log .jsonl file.
# Why include cache_read + cache_creation in tokens_in: input_tokens by
# itself reports only the non-cached delta, which understates context
# size. The sum reflects the total context the model processed — the
# number an operator wants when judging "did this task run hot".
_si_sum_session_tokens() {
    local jsonl_path="$1"
    jq -s '
        [.[] | select(.type == "assistant") | .message.usage // empty] as $u |
        {
            tokens_in:  ([$u[] | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)] | add // 0),
            tokens_out: ([$u[] | (.output_tokens // 0)] | add // 0)
        }
    ' "$jsonl_path"
}

# Locate the most-recently-modified .jsonl in the worktree's project dir.
# Echoes the path or empty if absent.
_si_latest_session_log() {
    local wt_dir="$1"
    local encoded
    encoded=$(_si_encode_project_dir "$wt_dir")
    local proj_dir="$HOME/.claude/projects/$encoded"
    [ -d "$proj_dir" ] || return 0
    # -t sorts by mtime desc; head -1 picks the freshest. Glob may match
    # nothing — guard with the directory check above.
    find "$proj_dir" -maxdepth 1 -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn | head -1 | awk '{print $2}'
}

# Public: record tokens for a task into the round log.
# Args: $1 = task_id, $2 = worktree dir, $3 = path to round log JSON file
# On success writes .validation[task_id].tokens_in and .tokens_out.
# If the session log is missing, writes zeros and source="missing" so
# downstream consumers can distinguish "no agent ran" from "agent used 0".
record_implementer_tokens() {
    local task_id="$1" wt_dir="$2" round_log_file="$3"

    if [ -z "$task_id" ] || [ -z "$wt_dir" ] || [ -z "$round_log_file" ]; then
        echo "Usage: record_implementer_tokens <task_id> <wt_dir> <round_log_file>" >&2
        return 1
    fi
    [ -f "$round_log_file" ] || return 1

    local log_path tokens_json source="session_log"
    log_path=$(_si_latest_session_log "$wt_dir")

    if [ -z "$log_path" ] || [ ! -f "$log_path" ]; then
        tokens_json='{"tokens_in":0,"tokens_out":0}'
        source="missing"
    else
        tokens_json=$(_si_sum_session_tokens "$log_path" 2>/dev/null) || tokens_json='{"tokens_in":0,"tokens_out":0}'
    fi

    local tmp
    tmp=$(mktemp)
    jq --arg tid "$task_id" --arg src "$source" --argjson t "$tokens_json" '
        .validation[$tid].tokens_in  = ($t.tokens_in  // 0) |
        .validation[$tid].tokens_out = ($t.tokens_out // 0) |
        .validation[$tid].tokens_source = $src
    ' "$round_log_file" > "$tmp" && mv "$tmp" "$round_log_file"
}

# Public: compute mean tokens_in/tokens_out across launched tasks in a
# round report. Echoes "mean_in mean_out launched_with_tokens" or
# empty if no usable data.
round_mean_tokens() {
    local report="$1"
    [ -f "$report" ] || return 0
    jq -r '
        [.validation // {} | to_entries[]
         | select(.value.tokens_in != null or .value.tokens_out != null)
         | .value] as $rows |
        ($rows | length) as $n |
        if $n == 0 then ""
        else
            (([$rows[].tokens_in  // 0] | add) / $n | floor) as $mi |
            (([$rows[].tokens_out // 0] | add) / $n | floor) as $mo |
            "\($mi) \($mo) \($n)"
        end
    ' "$report" 2>/dev/null
}
