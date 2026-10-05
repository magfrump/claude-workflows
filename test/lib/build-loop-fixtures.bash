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

# commit_all [MSG]: stage everything and commit it on the current branch (an
# empty commit when nothing changed, so rewriting a file as it was still works).
commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }

# settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each),
# committed. Pass no lines for an empty file.
settings() { mkdir -p docs && printf '%s\n' "$@" > docs/dev-cycle.md && commit_all settings; }

# constraints LINE...: docs/constraints.md holding these lines, committed.
constraints() { mkdir -p docs && printf '%s\n' "$@" > docs/constraints.md && commit_all constraints; }

# settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line
# must equal WANT, or start with PREFIX. On a mismatch, print the whole output.
# shellcheck disable=SC2154  # bats' run sets $output and $stderr
settings_is() { run --separate-stderr bash "$BL" --settings; [ "$(line "$1")" = "$2" ] || { echo "want: $2"; echo "$output $stderr"; return 1; }; }
settings_like() { run --separate-stderr bash "$BL" --settings; [[ "$(line "$1")" == "$2"* ]] || { echo "want: $2..."; echo "$output $stderr"; return 1; }; }

# line KEY: the --settings output line that starts with KEY.
# shellcheck disable=SC2154  # bats sets $output in the calling test
line() { printf '%s\n' "$output" | grep -m1 "^$1 " || true; }

# brief SLUG LINE...: docs/working/briefs/2026-10-01-SLUG.md holding a title and
# these lines, committed on the current branch; sets B to its path.
brief() {
    local s="$1"; shift
    B="docs/working/briefs/2026-10-01-$s.md"
    mkdir -p docs/working/briefs && printf '# Brief: %s\n\n' "$s" > "$B" && printf '%s\n' "$@" >> "$B"
    commit_all "brief $s"
}

# work BRANCH: BRANCH from main with one commit that changes a file.
work() {
    git branch -q "$1" main
    git checkout -q "$1" && echo "$1" > "work-${1//\//-}.txt" && commit_all "work on $1" && git checkout -q main
}

# tip BRANCH MESSAGE [TREE [PARENT...]]: a commit with exactly MESSAGE (no
# cleanup: commit-tree takes it as given) on BRANCH's tip. By default it is
# empty (BRANCH's own tree) with BRANCH's tip as its one parent; pass TREE and
# the parents ("" for none) to build anything else.
tip() {
    local b="$1" m="$2" t p=() x
    if [[ $# -ge 3 ]]; then t="$3"; shift 3; for x in "$@"; do [[ -n "$x" ]] && p+=(-p "$x"); done
    else t="$(git rev-parse "$b^{tree}")"; p=(-p "$(git rev-parse "$b")"); fi
    git update-ref "refs/heads/$b" "$(printf '%s\n' "$m" | git commit-tree "$t" "${p[@]}")"
}

# status_of BRIEF: the one --status output line for BRIEF.
# shellcheck disable=SC2154  # bats sets $output in the calling test
status_of() { printf '%s\n' "$output" | grep -m1 -E "^(ok|skip) $1[ :]" || true; }
