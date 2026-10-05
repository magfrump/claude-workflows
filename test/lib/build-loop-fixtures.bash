#!/usr/bin/env bash
# Shared setup for test/scripts/build-loop-*.bats: a throwaway repo under
# $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as
# test/scripts/dev-cycle.bats, and helpers that write the files the script
# reads from main's commit. Load with `load ../lib/build-loop-fixtures`.

bl_setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    # shellcheck disable=SC2034  # read by the suites that load this file
    BL="$REPO_ROOT/scripts/build-loop.sh"
    # shellcheck disable=SC2034  # read by the suites that load this file
    LIB="$REPO_ROOT/scripts/lib/dev-cycle-read.sh"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
    export HOME="$BATS_TEST_TMPDIR/home" LC_ALL=C
    mkdir -p "$HOME"
    R="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$R" && cd "$R" || return 1
    git init -q -b main && git commit -q --allow-empty -m initial
}

# commit_all [MSG]: stage everything and commit it on the current branch.
commit_all() { git add -A && git commit -qm "${1:-fixture}"; }

# settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each),
# committed. Pass no lines for an empty file.
settings() { mkdir -p docs && printf '%s\n' "$@" > docs/dev-cycle.md && commit_all settings; }

# settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line
# must equal WANT, or start with PREFIX. On a mismatch, print the whole output.
# shellcheck disable=SC2154  # bats' run sets $output and $stderr
settings_is() { run --separate-stderr bash "$BL" --settings; [ "$(line "$1")" = "$2" ] || { echo "want: $2"; echo "$output $stderr"; return 1; }; }
settings_like() { run --separate-stderr bash "$BL" --settings; [[ "$(line "$1")" == "$2"* ]] || { echo "want: $2..."; echo "$output $stderr"; return 1; }; }

# line KEY: the --settings output line that starts with KEY.
# shellcheck disable=SC2154  # bats sets $output in the calling test
line() { printf '%s\n' "$output" | grep -m1 "^$1 " || true; }
