#!/usr/bin/env bats
# @category fast
# Hermeticity gate for THIS repo.
#
# The rule and the detector now live in scripts/hermeticity-lint (a polyglot,
# cross-project CLI — decision 017). This suite is the thin caller that wires it
# into run-tests.sh, so the gate keeps firing on every `run-tests.sh --all`.
#
# Detector unit tests live in test/hermeticity-lint.bats.
# The rule, the stub pattern, and the annotation grammar: guides/test-hermeticity.md
#
# NOTE ON SCOPE: a green run here means no test file can *spawn* a network
# binary unstubbed. It is triage, not proof of hermeticity — in-process HTTP is
# deliberately out of scope (017, finding 3). Ground truth is the network
# namespace: scripts/confine-tests.sh -- scripts/run-tests.sh --all

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "no test file can spawn a network-capable binary without a stub or opt-out" {
  run "$REPO_ROOT/scripts/hermeticity-lint" --root "$REPO_ROOT"
  [ "$status" -eq 0 ] || {
    echo "$output"
    return 1
  }
}

@test "the gate actually scanned this repo's suites (a zero-file scan is not a pass)" {
  # An exit-0 alone cannot tell "checked 64 files, all clean" from "discovered
  # nothing, so nothing was wrong" — and a broken glob or a moved directory
  # produces the second while looking exactly like the first. Assert the count.
  run "$REPO_ROOT/scripts/hermeticity-lint" --root "$REPO_ROOT" --json
  [ "$status" -eq 0 ]
  [[ "$output" =~ \"bash\":[[:space:]]*[1-9] ]]
}
