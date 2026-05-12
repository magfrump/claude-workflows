#!/bin/bash
# Shared preflight helpers for verifying required commands.

# Exit with status 1 if the named command is not on PATH.
# Usage: require_command jq
require_command() {
    local cmd=$1
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is required but not installed." >&2
        exit 1
    fi
}
