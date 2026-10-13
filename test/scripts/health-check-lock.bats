#!/usr/bin/env bats
# @category fast
# T43 (plan D14, U3c): scripts/health-check.sh runs one at a time per
# repository, on a flock in the common git dir. Each test copies the script and
# the libs it sources into a throwaway repo under $BATS_TEST_TMPDIR, with check
# 5's runner stubbed, so no real suite runs.

setup() {
    W="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    R="$BATS_TEST_TMPDIR/r"; L="$BATS_TEST_TMPDIR/log"
    mkdir -p "$R/scripts/lib" && cd "$R" && git init -q || return 1
    cp "$W/scripts/health-check.sh" scripts/ && cp "$W"/scripts/lib/{log-format,md-utils,skill-paths}.sh scripts/lib/
    # The stub runner: --fast logs its run's start and end a second apart.
    printf '#!/bin/sh\n[ "$1" = --fast ] || exit 0\necho "in $RUN" >> "%s"; sleep 1; echo "out $RUN" >> "%s"\n' "$L" "$L" > "$BATS_TEST_TMPDIR/stub"
    chmod +x "$BATS_TEST_TMPDIR/stub"
    export HEALTH_CHECK_RUN_TESTS="$BATS_TEST_TMPDIR/stub"; unset HEALTH_CHECK_SKIP_BATS HEALTH_CHECK_LOCK_HELD
}

@test "two concurrent health checks serialize on the lock: the second starts after the first ends, and says it waits (T43)" {
    RUN=a bash scripts/health-check.sh > "$BATS_TEST_TMPDIR/a" 2>&1 &
    RUN=b bash scripts/health-check.sh > "$BATS_TEST_TMPDIR/b" 2>&1 &
    wait
    run cat "$L"
    [[ "$output" == $'in a\nout a\nin b\nout b' || "$output" == $'in b\nout b\nin a\nout a' ]] || { echo "$output"; return 1; }
    cat "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/b" | grep -q "waiting for another health check in this repository" || { cat "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/b"; return 1; }
    [ -f .git/health-check.lock ]
}

@test "a run inside a run takes no lock; a lock path that is not a plain file stops the run (T43)" {
    : > .git/health-check.lock
    flock .git/health-check.lock sleep 4 &
    sleep 0.5
    RUN=n HEALTH_CHECK_LOCK_HELD=1 run bash scripts/health-check.sh
    [[ "$output" != *waiting* ]] && grep -qx "out n" "$L" || { echo "$output"; return 1; }
    wait
    rm .git/health-check.lock; mkfifo .git/health-check.lock
    run bash scripts/health-check.sh
    [ "$status" -eq 1 ] && [[ "$output" == *"health-check.lock in $R/.git is not a plain file or cannot be opened"* ]] && [ "$(grep -c "^in " "$L")" -eq 1 ] || { echo "$output"; return 1; }
}
