#!/usr/bin/env bats
# @category fast
# Regression guard: asserts all exported functions from self-improvement.sh
# and its library files exist and are callable.
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

@test "parse_si_input is a function" {
  [ "$(type -t parse_si_input)" = "function" ]
}

@test "generate_morning_summary is a function" {
  [ "$(type -t generate_morning_summary)" = "function" ]
}

@test "all 9 expected functions are present" {
  local expected=(
    check_convergence_threshold
    validate_task_json
    init_round_log
    update_round_log
    record_gate
    finalize_round_log
    print_round_summary
    parse_si_input
    generate_morning_summary
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
  [ ${#expected[@]} -eq 9 ]
}
