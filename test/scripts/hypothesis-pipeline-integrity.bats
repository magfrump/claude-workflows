#!/usr/bin/env bats
# @category fast
# Positive test for check_hypothesis_pipeline_integrity in scripts/health-check.sh.
#
# Sources health-check.sh (the script no longer auto-runs main when sourced),
# points the HC_* env vars at the known-good fixture under
# test/scripts/fixtures/hypothesis-pipeline/good/, and asserts that the
# integrity function passes without setting FAIL.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
FIXTURE_DIR="$REPO_ROOT/test/scripts/fixtures/hypothesis-pipeline/good"

setup() {
    export HC_HYPOTHESIS_LOG="$FIXTURE_DIR/hypothesis-log.md"
    export HC_MORNING_SUMMARY="$FIXTURE_DIR/morning-summary.md"
    export HC_COMPLETED_TASKS="$FIXTURE_DIR/completed-tasks.md"
    # Use a copy of the baseline so the function's auto-update doesn't
    # mutate the fixture between test runs.
    BASELINE_TMP="$(mktemp)"
    cp "$FIXTURE_DIR/baseline" "$BASELINE_TMP"
    export HC_HYPOTHESIS_BASELINE="$BASELINE_TMP"
}

teardown() {
    rm -f "$BASELINE_TMP"
}

@test "integrity check passes on known-good fixture" {
    run bash -c "source '$REPO_ROOT/scripts/health-check.sh'; check_hypothesis_pipeline_integrity; echo \"FAIL=\$FAIL\""
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Hypothesis pipeline integrity"* ]]
    [[ "$output" == *"3 rows verified"* ]]
    [[ "$output" == *"latest round=2"* ]]
    [[ "$output" == *"FAIL=0"* ]]
    [[ "$output" != *"✗"* ]]
}

@test "fixture maps task-alpha hypothesis row to morning-summary approved task" {
    # Sanity-check the fixture itself: the hypothesis row exists and the
    # morning-summary lists the same task as approved.
    grep -qE '^\| 2 \| task-alpha \|' "$FIXTURE_DIR/hypothesis-log.md"
    grep -qF '- **task-alpha**:' "$FIXTURE_DIR/morning-summary.md"
}

@test "fixture maps task-gamma TRACKING row to morning-summary deferred line" {
    # Sanity-check the open-window mapping: the TRACKING row in
    # hypothesis-log appears in the deferred-questions section.
    grep -qE '^\| 1 \| task-gamma \|.*\|[[:space:]]*\|[[:space:]]*\|[[:space:]]*\|[[:space:]]*$' "$FIXTURE_DIR/hypothesis-log.md"
    grep -qF '**task-gamma** (round 1):' "$FIXTURE_DIR/morning-summary.md"
}
