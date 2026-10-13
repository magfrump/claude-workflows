#!/usr/bin/env bats
# @category fast
# T43 (plan D14, U3c): health-check.sh runs one at a time per repository (a flock in the common git dir);
# each test copies it and its libs into a throwaway repo, check 5's runner stubbed.

setup() {
    W="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    R="$BATS_TEST_TMPDIR/r"; L="$BATS_TEST_TMPDIR/log"
    mkdir -p "$R/scripts/lib" && cd "$R" && git init -q || return 1
    cp "$W/scripts/health-check.sh" scripts/ && cp "$W"/scripts/lib/{log-format,md-utils,skill-paths}.sh scripts/lib/
    # The stub runner: --fast logs its run's start and end a second apart; --slow under LEAVE leaves a process running.
    printf '#!/bin/sh\nif [ "$1" != --fast ]; then [ -z "$LEAVE" ] || { sleep 5 >/dev/null 2>&1 3>&- & }; exit 0; fi\necho "in $RUN" >> "%s"; sleep 1; echo "out $RUN" >> "%s"\n' "$L" "$L" > "$BATS_TEST_TMPDIR/stub"
    chmod +x "$BATS_TEST_TMPDIR/stub"; export HEALTH_CHECK_RUN_TESTS="$BATS_TEST_TMPDIR/stub"; unset HEALTH_CHECK_SKIP_BATS HEALTH_CHECK_LOCK_HELD
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

@test "a run inside a run takes no lock, nor does a process a run leaves behind; a lock path that is not a plain file stops the run (T43)" {
    : > .git/health-check.lock
    flock .git/health-check.lock sleep 4 &
    sleep 0.5
    RUN=n HEALTH_CHECK_LOCK_HELD=1 run bash scripts/health-check.sh
    [[ "$output" != *waiting* ]] && grep -qx "out n" "$L" || { echo "$output"; return 1; }
    wait
    # A process a run leaves behind holds no lock: the next run does not wait for it.
    RUN=p LEAVE=1 bash scripts/health-check.sh > /dev/null 2>&1 || true; RUN=q run bash scripts/health-check.sh
    [[ "$output" != *waiting* ]] && grep -qx "out q" "$L" || { echo "$output"; return 1; }
    rm .git/health-check.lock; mkfifo .git/health-check.lock
    run bash scripts/health-check.sh
    [ "$status" -eq 1 ] && [[ "$output" == *"health-check.lock in $R/.git is not a plain file"* ]] && [ "$(grep -c "^in " "$L")" -eq 3 ] || { echo "$output"; return 1; }
}

@test "HEALTH_CHECK_LOCK_WAIT bounds the wait: past it the run exits 75 having run nothing; a value that is not a number stops the run (row 750, U4b1)" {
    : > .git/health-check.lock
    flock .git/health-check.lock sleep 4 &
    sleep 0.5
    RUN=w HEALTH_CHECK_LOCK_WAIT=1 run bash scripts/health-check.sh
    [ "$status" -eq 75 ] && [[ "$output" == *"gave up waiting for health-check.lock after 1s: nothing was checked"* ]] && [ ! -e "$L" ] || { echo "$status $output"; return 1; }
    RUN=x HEALTH_CHECK_LOCK_WAIT=1s run bash scripts/health-check.sh
    [ "$status" -eq 1 ] && [[ "$output" == *"HEALTH_CHECK_LOCK_WAIT is not a plain number of seconds"* ]] && [ ! -e "$L" ] || { echo "$status $output"; return 1; }
    wait
    RUN=y HEALTH_CHECK_LOCK_WAIT=30 run bash scripts/health-check.sh
    [ "$status" -ne 75 ] && [[ "$output" != *waiting* ]] && grep -qx "out y" "$L" || { echo "$status $output"; return 1; }
}
