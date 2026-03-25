#!/bin/bash
# Pure functions for convergence detection logic.
# Sourced by self-improvement.sh and tested by test/convergence-detection.bats.

# check_convergence_threshold OVERLAP_PERCENT THRESHOLD
#   Returns 0 if overlap >= threshold (converged), 1 otherwise.
#   Returns 1 for empty or non-numeric inputs (safe default: no convergence).
check_convergence_threshold() {
    local overlap="$1"
    local threshold="$2"

    # Empty or non-numeric → not converged
    if [ -z "$overlap" ] || [ -z "$threshold" ]; then
        return 1
    fi
    if ! [[ "$overlap" =~ ^[0-9]+$ ]] || ! [[ "$threshold" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    [ "$overlap" -ge "$threshold" ]
}
