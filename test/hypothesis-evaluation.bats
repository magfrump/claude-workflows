#!/usr/bin/env bats
# Unit tests for get_eligible_hypotheses from self-improvement.sh
#
# Tests the hypothesis window tracking logic (Step 0):
#   (a) hypothesis within window is not yet eligible
#   (b) hypothesis past window triggers evaluation eligibility
#   (c) malformed hypothesis entries are handled gracefully
#
# Usage: bats test/hypothesis-evaluation.bats

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
}

# --- (a) Hypothesis within window is NOT eligible ---

@test "hypothesis within default 3-round window is not eligible" {
  # Task from round 2, current round 4 → elapsed 2, window 3 → not eligible
  local tasks='[{"id":"task-a","hypothesis":"things improve","description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 4 2"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "hypothesis within custom window is not eligible" {
  # Task from round 1, current round 3 → elapsed 2, window 5 → not eligible
  local tasks='[{"id":"task-b","hypothesis":"perf improves","hypothesis_window":5,"description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 3 1"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- (b) Hypothesis past window triggers eligibility ---

@test "hypothesis at exact window boundary is eligible" {
  # Task from round 1, current round 4 → elapsed 3, default window 3 → eligible
  local tasks='[{"id":"task-c","hypothesis":"coverage goes up","description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 4 1"
  [ "$status" -eq 0 ]
  [ "$output" = "task-c" ]
}

@test "hypothesis well past window is eligible" {
  # Task from round 1, current round 10 → elapsed 9, default window 3 → eligible
  local tasks='[{"id":"task-d","hypothesis":"bugs decrease","description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 10 1"
  [ "$status" -eq 0 ]
  [ "$output" = "task-d" ]
}

@test "hypothesis past custom window is eligible" {
  # Task from round 2, current round 9 → elapsed 7, window 5 → eligible
  local tasks='[{"id":"task-e","hypothesis":"latency drops","hypothesis_window":5,"description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 9 2"
  [ "$status" -eq 0 ]
  [ "$output" = "task-e" ]
}

@test "multiple eligible tasks are all returned" {
  local tasks='[
    {"id":"t1","hypothesis":"h1","description":"d","files_touched":["f"],"independent":true},
    {"id":"t2","hypothesis":"h2","description":"d","files_touched":["f"],"independent":true}
  ]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 5 1"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "t1"
  echo "$output" | grep -q "t2"
}

@test "retroactive tasks are excluded from eligibility" {
  local tasks='[{"id":"task-retro","hypothesis":"h","retroactive":true,"description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 10 1"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "task with null hypothesis is not eligible" {
  local tasks='[{"id":"task-null","hypothesis":null,"description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 10 1"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "task with empty hypothesis is not eligible" {
  local tasks='[{"id":"task-empty","hypothesis":"","description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 10 1"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- (c) Malformed input handled gracefully ---

@test "missing arguments returns error" {
  run get_eligible_hypotheses
  [ "$status" -eq 1 ]
}

@test "missing prior_round returns error" {
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '[]' | get_eligible_hypotheses 5"
  [ "$status" -eq 1 ]
}

@test "non-numeric current_round returns error" {
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '[]' | get_eligible_hypotheses abc 1"
  [ "$status" -eq 1 ]
}

@test "non-numeric prior_round returns error" {
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '[]' | get_eligible_hypotheses 5 xyz"
  [ "$status" -eq 1 ]
}

@test "malformed JSON input returns error" {
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo 'not-json' | get_eligible_hypotheses 5 1"
  [ "$status" -eq 1 ]
}

@test "empty JSON array returns no eligible tasks" {
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '[]' | get_eligible_hypotheses 5 1"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "task missing hypothesis field entirely returns no eligible" {
  local tasks='[{"id":"no-hyp","description":"d","files_touched":["f"],"independent":true}]'
  run bash -c "source '$BATS_TEST_DIRNAME/../scripts/self-improvement.sh'; echo '$tasks' | get_eligible_hypotheses 10 1"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
