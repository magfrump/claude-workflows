#!/usr/bin/env bats
# @category fast
# The dev-cycle and build-loop suites must keep their fixtures out of a repo
# named by an inherited GIT_DIR or GIT_INDEX_FILE (a run from a git hook, say):
# each suite's setup unsets every variable `git rev-parse --local-env-vars`
# lists. One test of each suite runs here with both pointed at a victim repo.
bats_require_minimum_version 1.5.0

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    # This suite's own fixture must stay out of an inherited GIT_DIR too.
    # shellcheck disable=SC2046  # word splitting is wanted: one name per line
    unset $(git rev-parse --local-env-vars)
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    V="$BATS_TEST_TMPDIR/victim"
    git init -q -b main "$V"
    git -C "$V" -c user.name=v -c user.email=v@example.invalid commit -q --allow-empty -m only
    # The inner runs name the victim's index too: it must come out byte for byte.
    cp "$V/.git/index" "$BATS_TEST_TMPDIR/index.before"
}

victim_unchanged() {
    # The inner run must have run one test and passed, or this proves nothing.
    [ "$status" -eq 0 ] && [[ "$output" == *"1..1"*"ok 1 "* ]] || { echo "$output"; return 1; }
    [ "$(git -C "$V" rev-list --all --count)" = 1 ] && [ "$(git -C "$V" for-each-ref --format=x | wc -l)" = 1 ] \
        || { git -C "$V" log --all --oneline | head; git -C "$V" for-each-ref; return 1; }
    cmp -s "$BATS_TEST_TMPDIR/index.before" "$V/.git/index" || { git -C "$V" ls-files -s | head; return 1; }
}

@test "dev-cycle.bats fixtures stay out of an inherited GIT_DIR (U2a1)" {
    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f 'check-answer needs a default branch found by name' "$REPO_ROOT/test/scripts/dev-cycle.bats"
    victim_unchanged
}

@test "build-loop-read.bats fixtures stay out of an inherited GIT_DIR (U2a1)" {
    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f 'exact policy line is set' "$REPO_ROOT/test/scripts/build-loop-read.bats"
    victim_unchanged
}
