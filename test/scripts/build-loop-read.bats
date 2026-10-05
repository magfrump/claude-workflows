#!/usr/bin/env bats
# @category fast
# Contract tests for scripts/build-loop.sh's read modes. Each test builds a
# throwaway repo under $BATS_TEST_TMPDIR (test/lib/build-loop-fixtures.bash);
# this repo is untouched. The lib it sources (scripts/lib/dev-cycle-read.sh)
# is also tested from dev-cycle.sh's side, in test/scripts/dev-cycle.bats.

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() { bl_setup; }

@test "--settings: an exact policy line is set, a trailing CR included (T1)" {
    for v in self-merge review; do
        settings '# Settings' '' "Build-loop policy: $v"
        run --separate-stderr bash "$BL" --settings
        [ "$status" -eq 0 ] && [ "$(line policy)" = "policy $v set: line 3 of docs/dev-cycle.md on the default branch" ] \
            || { echo "$output $stderr"; return 1; }
        printf 'Build-loop policy: %s\r\n' "$v" > docs/dev-cycle.md && commit_all cr
        run --separate-stderr bash "$BL" --settings
        [ "$(line policy)" = "policy $v set: line 1 of docs/dev-cycle.md on the default branch" ] || { echo "$output"; return 1; }
    done
}

@test "--settings: policy variants are unset, so review, and say why (T2)" {
    n='is not exactly "Build-loop policy: self-merge" or "Build-loop policy: review"'
    for v in 'Build-loop policy: self-merge (interim; Q-103)' 'Build-loop policy: Self-merge' \
             'build-loop policy: self-merge' 'Build-loop policy: self-merge ' 'Build-loop policy:  self-merge'; do
        settings x "$v"
        run --separate-stderr bash "$BL" --settings
        [ "$(line policy)" = "policy review unset: line 2 $n" ] || { echo "[$v] $output"; return 1; }
    done
    settings 'Build-loop policy: self-merge' '' '> Build-loop policy: self-merge'
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = 'policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 3)' ] || { echo "$output"; return 1; }
    for c in '- Build-loop policy: review' '**Build-loop policy:** review' '# Build-loop policy: review' $'\xef\xbb\xbfBuild-loop policy: review'; do
        settings 'Build-loop policy: self-merge' "$c"
        run --separate-stderr bash "$BL" --settings
        [ "$(line policy)" = 'policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 2)' ] || { echo "[$c] $output"; return 1; }
    done
    # shellcheck disable=SC2016  # literal backticks in the prose line
    settings '# none here' 'The policy is `Build-loop policy: self-merge` in prose.' '<!-- Build-loop policy: self-merge -->'
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = 'policy review unset: no line starts "Build-loop policy:"' ] || { echo "$output"; return 1; }
}

@test "--settings: a fenced line, an open comment, a BOM or a file that is not plain on main reads review (T3)" {
    local f=$'\x60\x60\x60'
    settings "$f" 'Build-loop policy: self-merge' "$f"
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = 'policy review unset: no line starts "Build-loop policy:"' ] || { echo "$output"; return 1; }
    settings 'text <!-- open' 'Build-loop policy: self-merge'
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = "policy review unset: line 1 of docs/dev-cycle.md opens an HTML comment that does not close on the same line, so the file is not read" ] \
        || { echo "$output"; return 1; }
    [ "$(line never)" = "never malformed: line 1 of docs/dev-cycle.md opens an HTML comment that does not close on the same line, so the file is not read" ] \
        || { echo "$output"; return 1; }
    settings $'\xef\xbb\xbfBuild-loop policy: self-merge'
    run --separate-stderr bash "$BL" --settings
    [[ "$(line policy)" == "policy review unset: line 1 of docs/dev-cycle.md starts with a byte-order mark"* ]] || { echo "$output"; return 1; }
    settings "$f" 'Build-loop policy: self-merge'
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = "policy review unset: the code fence opened at line 1 of docs/dev-cycle.md is never closed, so the file is not read" ] \
        || { echo "$output"; return 1; }
    # Missing, a symlink, a directory, and a file only in the working tree.
    git rm -q docs/dev-cycle.md && commit_all rm
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = "policy review unset: no docs/dev-cycle.md on the default branch" ] \
        && [ "$(line never)" = "never none: no docs/dev-cycle.md on the default branch" ] || { echo "$output"; return 1; }
    mkdir -p docs && printf 'Build-loop policy: self-merge\n' > real.md && ln -s ../real.md docs/dev-cycle.md && commit_all link
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = "policy review unset: docs/dev-cycle.md is not a regular file on the default branch" ] || { echo "$output"; return 1; }
    git rm -q docs/dev-cycle.md && mkdir -p docs/dev-cycle.md && echo x > docs/dev-cycle.md/y && commit_all dir
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = "policy review unset: docs/dev-cycle.md is not a regular file on the default branch" ] || { echo "$output"; return 1; }
    git rm -rq docs && rm -rf docs && mkdir real-docs && printf 'Build-loop policy: self-merge\n' > real-docs/dev-cycle.md
    ln -s real-docs docs && commit_all dirlink
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = "policy review unset: docs is not a directory on the default branch" ] || { echo "$output"; return 1; }
    git rm -q docs && commit_all unlink && mkdir docs && printf 'Build-loop policy: self-merge\n' > docs/dev-cycle.md
    run --separate-stderr bash "$BL" --settings
    [ "$(line policy)" = "policy review unset: no docs/dev-cycle.md on the default branch" ] || { echo "$output"; return 1; }
}

@test "--settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)" {
    mkdir -p docs && cp "$REPO_ROOT/docs/dev-cycle.md" docs/ && commit_all real
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] || { echo "$output $stderr"; return 1; }
    [[ "$(line policy)" == "policy review unset: line "*' is not exactly "Build-loop policy: self-merge" or "Build-loop policy: review"' ]] \
        || { echo "$output"; return 1; }
}

@test "--settings reads main's commit: the working tree and other branches never decide (T4)" {
    settings 'Build-loop policy: review'
    printf 'Build-loop policy: self-merge\nBuild-loop slots: 7\n' > docs/dev-cycle.md
    run --separate-stderr bash "$BL" --settings
    [[ "$(line policy)" == "policy review set:"* && "$(line slots)" == "slots 3 default:"* ]] || { echo "$output"; return 1; }
    git checkout -q -b loop && commit_all raise && git checkout -q main
    run --separate-stderr bash "$BL" --settings
    [[ "$(line policy)" == "policy review set:"* ]] || { echo "$output"; return 1; }
    git merge -q loop && git checkout -q -b lower && printf 'Build-loop policy: review\n' > docs/dev-cycle.md
    run --separate-stderr bash "$BL" --settings
    [[ "$(line policy)" == "policy self-merge set:"* && "$(line slots)" == "slots 7 set: line 2 of docs/dev-cycle.md on the default branch" ]] \
        || { echo "$output"; return 1; }
}

@test "--settings: slots are 1 to 9 on one exact line, else 3 (T1-T3 slots)" {
    settings 'Build-loop slots: 5'
    run --separate-stderr bash "$BL" --settings
    [ "$(line slots)" = "slots 5 set: line 1 of docs/dev-cycle.md on the default branch" ] || { echo "$output"; return 1; }
    for v in 'Build-loop slots: 0' 'Build-loop slots: 10' 'Build-loop slots: 3 ' 'Build-loop slots: 05' 'Build-loop slots: three'; do
        settings "$v"
        run --separate-stderr bash "$BL" --settings
        [ "$(line slots)" = 'slots 3 default: line 1 is not exactly "Build-loop slots: N" with N from 1 to 9' ] || { echo "[$v] $output"; return 1; }
    done
    settings 'Build-loop slots: 4' 'Build-loop slots: 4'
    run --separate-stderr bash "$BL" --settings
    [ "$(line slots)" = 'slots 3 default: more than one line starts "Build-loop slots:" (lines 1 and 2)' ] || { echo "$output"; return 1; }
    settings $'\x60\x60\x60' 'Build-loop slots: 4' $'\x60\x60\x60'
    run --separate-stderr bash "$BL" --settings
    [ "$(line slots)" = 'slots 3 default: no line starts "Build-loop slots:"' ] || { echo "$output"; return 1; }
}

@test "--settings: Self-merge never: is one line of allowed globs; anything else is malformed and turns self-merge off (T45)" {
    settings 'Build-loop policy: self-merge' 'Self-merge never: workflows/ hooks/*.sh docs/x?.md'
    run --separate-stderr bash "$BL" --settings
    [ "$(line never)" = "never workflows/ hooks/*.sh docs/x?.md set: line 2 of docs/dev-cycle.md on the default branch" ] \
        && [[ "$(line policy)" == "policy self-merge set:"* ]] || { echo "$output"; return 1; }
    settings 'Build-loop policy: self-merge'
    run --separate-stderr bash "$BL" --settings
    [ "$(line never)" = 'never none: no line starts "Self-merge never:"' ] || { echo "$output"; return 1; }
    for v in 'Self-merge never:' 'Self-merge never: ' 'Self-merge never: a  b' 'Self-merge never: ../x' 'Self-merge never: a/../b' \
             'Self-merge never: /etc' 'Self-merge never: -x' 'Self-merge never: a b a' 'Self-merge never: a a/' $'Self-merge never: caf\xc3\xa9/' \
             $'Self-merge never: a\tb' $'Self-merge never: \ta' $'Self-merge never: a\t' $'Self-merge never: a \tb' 'Self-merge never: a ./b'; do
        settings 'Build-loop policy: self-merge' "$v"
        run --separate-stderr bash "$BL" --settings
        [[ "$(line never)" == "never malformed: line 2 "* ]] || { echo "[$v] $output"; return 1; }
        [ "$(line policy)" = "policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off" ] \
            || { echo "[$v] $output"; return 1; }
        [[ "$output" != *$'\xc3'* && "$output" != *../x* && "$output" != */etc* && "$output" != *-x* && "$output" != *./b* ]] \
            || { echo "echoed a malformed entry: $output"; return 1; }
    done
    settings 'Build-loop policy: self-merge' 'Self-merge never: a/' '  self-merge never: b/'
    run --separate-stderr bash "$BL" --settings
    [ "$(line never)" = 'never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)' ] || { echo "$output"; return 1; }
    # Bold, heading and emphasis copies count as second lines too.
    for c in '**Self-merge never:** b/' '## Self-merge never: b/' '_self-merge never: b/_' '`Self-merge never: b/`'; do
        settings 'Build-loop policy: self-merge' 'Self-merge never: a/' "$c"
        run --separate-stderr bash "$BL" --settings
        [[ "$(line never)" == 'never malformed: more than one line starts "Self-merge never:"'* ]] || { echo "[$c] $output"; return 1; }
    done
    # A part starting .git is allowed: the list only adds refusals.
    settings 'Build-loop policy: self-merge' 'Self-merge never: .github/ .gitignore'
    run --separate-stderr bash "$BL" --settings
    [[ "$(line never)" == "never .github/ .gitignore set:"* && "$(line policy)" == "policy self-merge set:"* ]] || { echo "$output"; return 1; }
    # Raised only on a loop's branch or in the working tree: ignored.
    settings 'Build-loop policy: self-merge' 'Self-merge never: workflows/'
    git checkout -q -b loop && printf 'Build-loop policy: self-merge\nSelf-merge never: x/ ../y\n' > docs/dev-cycle.md && commit_all loop
    git checkout -q main && printf 'Build-loop policy: self-merge\n' > docs/dev-cycle.md
    run --separate-stderr bash "$BL" --settings
    [[ "$(line never)" == "never workflows/ set:"* ]] || { echo "$output"; return 1; }
}

@test "--settings prints its three lines in order and exits 0; usage errors and a missing default branch exit 1" {
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 3 ] || { echo "$output"; return 1; }
    [[ "${lines[0]}" == policy\ * && "${lines[1]}" == slots\ * && "${lines[2]}" == never\ * ]] \
        || { echo "$output"; return 1; }
    for args in "" "--bogus" "--settings extra" "--status"; do
        # shellcheck disable=SC2086  # split the argument list on purpose
        run --separate-stderr bash "$BL" $args
        [ "$status" -eq 1 ] && [ -z "$output" ] && [ -n "$stderr" ] || { echo "[$args] $status $output $stderr"; return 1; }
    done
    git branch -m main trunk
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 1 ] && [[ "$stderr" == *"needs a default branch"* ]] || { echo "$output $stderr"; return 1; }
    cd "$BATS_TEST_TMPDIR"
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 1 ] && [[ "$stderr" == *"Not inside a git repository"* ]] || { echo "$output $stderr"; return 1; }
}

@test "build-loop.sh sources the lib from its own directory, never the target repo's; without it, exit 1" {
    mkdir -p scripts/lib && printf 'echo PLANTED\n' > scripts/lib/dev-cycle-read.sh && commit_all plant
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] && [[ "$output$stderr" != *PLANTED* ]] || { echo "$output $stderr"; return 1; }
    mkdir -p "$BATS_TEST_TMPDIR/bare" && cp "$BL" "$BATS_TEST_TMPDIR/bare/build-loop.sh"
    run --separate-stderr bash "$BATS_TEST_TMPDIR/bare/build-loop.sh" --settings
    [ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"needs $BATS_TEST_TMPDIR/bare/lib/dev-cycle-read.sh"* ]] \
        || { echo "$output $stderr"; return 1; }
    # From a subdirectory and from a linked worktree, it reads the same main.
    settings 'Build-loop policy: self-merge'
    git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub
    for d in sub "$BATS_TEST_TMPDIR/wt"; do
        # shellcheck disable=SC2016  # $1 and $2 belong to the inner shell
        run --separate-stderr bash -c 'cd "$1" && bash "$2" --settings' _ "$d" "$BL"
        [[ "$(line policy)" == "policy self-merge set:"* ]] || { echo "[$d] $output $stderr"; return 1; }
    done
}
