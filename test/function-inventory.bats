#!/usr/bin/env bats
# Regression guard: asserts all 8 exported functions from self-improvement.sh
# exist and are callable. Catches accidental removal or rename.
#
# Usage: bats test/function-inventory.bats

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
}

@test "check_convergence_threshold is a function" {
  [ "$(type -t check_convergence_threshold)" = "function" ]
}

@test "validate_task_json is a function" {
  [ "$(type -t validate_task_json)" = "function" ]
}

@test "get_eligible_hypotheses is a function" {
  [ "$(type -t get_eligible_hypotheses)" = "function" ]
}

@test "init_round_log is a function" {
  [ "$(type -t init_round_log)" = "function" ]
}

@test "update_round_log is a function" {
  [ "$(type -t update_round_log)" = "function" ]
}

@test "record_gate is a function" {
  [ "$(type -t record_gate)" = "function" ]
}

@test "finalize_round_log is a function" {
  [ "$(type -t finalize_round_log)" = "function" ]
}

@test "print_round_summary is a function" {
  [ "$(type -t print_round_summary)" = "function" ]
}

@test "all 8 expected functions are present" {
  local expected=(
    check_convergence_threshold
    validate_task_json
    get_eligible_hypotheses
    init_round_log
    update_round_log
    record_gate
    finalize_round_log
    print_round_summary
  )
  local missing=()
  for fn in "${expected[@]}"; do
    if [ "$(type -t "$fn")" != "function" ]; then
      missing+=("$fn")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing functions: ${missing[*]}" >&2
    return 1
  fi
  [ ${#expected[@]} -eq 8 ]
}
