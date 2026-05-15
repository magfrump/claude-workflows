#!/usr/bin/env bats
# @category fast
# Unit tests for parse_si_priority_hypotheses() from lib/si-input.sh
# (decision 012 pillar 3 — pre-commitment hypotheses sourced from si-input.md)

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-input.sh"
}

@test "returns [] for empty input" {
  result=$(parse_si_priority_hypotheses "")
  [ "$result" = "[]" ]
}

@test "returns [] for prose without bullets" {
  result=$(parse_si_priority_hypotheses "Free-form prose. No bullets here.")
  [ "$result" = "[]" ]
}

@test "returns [] for bullets without hypothesis sub-bullets" {
  result=$(parse_si_priority_hypotheses "$(printf -- '- A priority\n- Another priority\n')")
  [ "$result" = "[]" ]
}

@test "single bullet with hypothesis yields one pair" {
  local input
  input=$(cat <<'P'
- Build failure-driven design workflow
  - hypothesis: Most likely failure is that I never reach for it during a real debugging session.
P
)
  result=$(parse_si_priority_hypotheses "$input")
  count=$(echo "$result" | jq 'length')
  [ "$count" -eq 1 ]
  priority=$(echo "$result" | jq -r '.[0].priority')
  hypothesis=$(echo "$result" | jq -r '.[0].hypothesis')
  [ "$priority" = "Build failure-driven design workflow" ]
  [[ "$hypothesis" == *"Most likely failure"* ]]
}

@test "multiple priorities with hypotheses are all captured" {
  local input
  input=$(cat <<'P'
- First priority
  - hypothesis: failure mode A.
- Second priority
  - hypothesis: failure mode B.
P
)
  result=$(parse_si_priority_hypotheses "$input")
  [ "$(echo "$result" | jq 'length')" -eq 2 ]
  [ "$(echo "$result" | jq -r '.[0].hypothesis')" = "failure mode A." ]
  [ "$(echo "$result" | jq -r '.[1].hypothesis')" = "failure mode B." ]
}

@test "mixed bullets — only those with hypothesis sub-bullets are emitted" {
  local input
  input=$(cat <<'P'
- Priority without hypothesis
- Priority with hypothesis
  - hypothesis: the predicted failure.
- Another priority without hypothesis
P
)
  result=$(parse_si_priority_hypotheses "$input")
  [ "$(echo "$result" | jq 'length')" -eq 1 ]
  [ "$(echo "$result" | jq -r '.[0].priority')" = "Priority with hypothesis" ]
}

@test "hypothesis continuation lines are joined" {
  local input
  input=$(cat <<'P'
- The priority
  - hypothesis: first line of the hypothesis
    second line continues it
    and a third line too
P
)
  result=$(parse_si_priority_hypotheses "$input")
  hyp=$(echo "$result" | jq -r '.[0].hypothesis')
  [[ "$hyp" == *"first line"* ]]
  [[ "$hyp" == *"second line"* ]]
  [[ "$hyp" == *"third line"* ]]
}

@test "Hypothesis: capitalisation is accepted" {
  local input
  input=$(cat <<'P'
- The priority
  - Hypothesis: the predicted failure.
P
)
  result=$(parse_si_priority_hypotheses "$input")
  [ "$(echo "$result" | jq 'length')" -eq 1 ]
}

@test "quotes and special chars in text are preserved as JSON strings" {
  local input
  input=$(cat <<'P'
- Add "X" support; fix bug
  - hypothesis: Failure: parser breaks on quotes/punctuation.
P
)
  result=$(parse_si_priority_hypotheses "$input")
  [ "$(echo "$result" | jq -r '.[0].priority')" = 'Add "X" support; fix bug' ]
  [ "$(echo "$result" | jq -r '.[0].hypothesis')" = "Failure: parser breaks on quotes/punctuation." ]
}

@test "reads from \$SI_PRIORITIES when no argument is given" {
  local pri
  pri=$(cat <<'P'
- A priority
  - hypothesis: the failure.
P
)
  export SI_PRIORITIES="$pri"
  result=$(parse_si_priority_hypotheses)
  [ "$(echo "$result" | jq 'length')" -eq 1 ]
  unset SI_PRIORITIES
}
