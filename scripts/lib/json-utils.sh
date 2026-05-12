#!/bin/bash
# Shared helpers for JSON manipulation via jq.

# Apply jq to FILE atomically: read from FILE, write the transformed
# output back to the same path. Pass jq arguments and expression as you
# would normally; the input file is supplied implicitly.
#
# Example:
#   jq_update_inplace "$ROUND_LOG_FILE" --arg tid "$TID" --arg s "$STATUS" \
#       '.validation[$tid].verdict = $s'
jq_update_inplace() {
    local file=$1
    shift
    local tmp
    tmp=$(mktemp)
    jq "$@" "$file" > "$tmp" && mv "$tmp" "$file"
}
