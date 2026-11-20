#!/usr/bin/env bats
# @category fast
# Contract tests for --settings' copies line and build-loop.sh --health-prep,
# each in a throwaway repo under $BATS_TEST_TMPDIR
# (test/lib/build-loop-fixtures.bash). Brief 2026-11-20-health-checkout-prep.

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() {
    bl_setup
    printf 'cache/\nbuild/\nlinked/\nspecial/\n.worktrees/\nlist.txt\n' > .gitignore
    constraints "H1: keep it small" "success: under 400 lines"
    W='of docs/dev-cycle.md on the default branch'
}

# hc: a detached health checkout HC at main's commit, under .worktrees/.
hc() { HC="$R/.worktrees/wt-dev-cycle-health-x"; git worktree add -q --detach "$HC" main; }
hp() { run --separate-stderr bash "$BL" --health-prep "$1"; }
# shellcheck disable=SC2154  # bats' run sets $output and $stderr
show() { echo "status $status"; echo "$output"; echo "$stderr"; }

@test "--settings: the copies line is the sixth, none when absent, set when well formed" {
    settings 'Build-loop policy: review'
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 6 ] && [[ "${lines[5]}" == copies\ * ]] || { show; return 1; }
    settings_is copies 'copies none: no line starts "Health checkout copies:"'
    git rm -q docs/dev-cycle.md && commit_all gone
    settings_is copies 'copies none: no docs/dev-cycle.md on the default branch'
    settings 'Health checkout copies: none'
    settings_is copies "copies none: line 1 $W lists none"
    settings '# S' '' 'Health checkout copies: cache/ a/.lake build' ''
    settings_is copies "copies cache/ a/.lake build set: line 3 $W"
    # Only main's commit decides.
    git checkout -q -b loop && settings 'Health checkout copies: other'
    settings_is copies "copies cache/ a/.lake build set: line 3 $W"
}

@test "--settings: a malformed copies line, or a file not read, is named as malformed" {
    for v in 'Health checkout copies:' 'Health checkout copies:  cache' 'Health checkout copies: cache  build' \
        'Health checkout copies: /abs' 'Health checkout copies: ../up' 'Health checkout copies: a/./b' \
        'Health checkout copies: .git' 'Health checkout copies: x/.GIT/y' 'Health checkout copies: -x' \
        'Health checkout copies: c*' 'Health checkout copies: a b a' 'Health checkout copies: sp\ ace' \
        'health checkout copies: cache'; do
        settings "$v"; settings_like copies 'copies malformed: line 1 '
    done
    settings 'Health checkout copies: cache' 'build'
    settings_is copies 'copies malformed: line 1 is followed by a non-blank line outside a fence (it may continue the list)'
    settings 'Health checkout copies: cache' '' '- **Health checkout copies:** build'
    settings_is copies 'copies malformed: more than one line starts "Health checkout copies:" (lines 1 and 3)'
    settings 'Health checkout copies: cache' '' $'\x60\x60\x60'
    settings_like copies 'copies malformed: the code fence opened at line 3 '
    # A malformed copies line turns nothing else off.
    settings 'Build-loop policy: self-merge' '' 'Self-merge never: none' '' 'Health checkout copies: /abs'
    settings_like policy 'policy self-merge set'
}

@test "--health-prep copies each listed gitignored path into HC and writes nothing else" {
    mkdir -p cache/sub build && echo a > cache/sub/f && echo b > build/g && echo l > list.txt
    settings 'Health checkout copies: cache/ build/g list.txt' ''
    hc
    hp "$HC"
    [ "$status" -eq 0 ] && [ "$output" = "$(printf 'copied cache\ncopied build/g\ncopied list.txt\nok %s 3' "$HC")" ] || { show; return 1; }
    [ "$(cat "$HC/cache/sub/f")" = a ] && [ "$(cat "$HC/build/g")" = b ] && [ "$(cat "$HC/list.txt")" = l ] || { show; return 1; }
    # The main worktree is unchanged, and HC's tree still reads as W's.
    [ -z "$(git -C "$HC" status --porcelain)" ] && [ "$(cat cache/sub/f)" = a ] || { show; git -C "$HC" status; return 1; }
    # none, or no line: nothing to copy, ok 0.
    settings 'Health checkout copies: none' ''
    git worktree remove --force "$HC" && hc && hp "$HC"
    [ "$status" -eq 0 ] && [ "$output" = "ok $HC 0" ] && [ ! -e "$HC/cache" ] || { show; return 1; }
}

@test "--health-prep refuses every path shape the brief names, and copies nothing when any is refused" {
    mkdir -p cache build linked special && echo a > cache/f && echo b > build/f
    ln -s "$R/cache" linked/l
    ln -s "$R/build" lnk
    mkfifo special/p
    echo t > tracked.txt
    mkdir -p .worktrees
    settings 'Health checkout copies: cache absent lnk/f linked special tracked.txt .worktrees' ''
    hc
    hp "$HC"
    [ "$status" -eq 2 ] || { show; return 1; }
    for want in "refuse health-prep absent: it is absent in the main worktree" \
        "refuse health-prep lnk/f: it is, or is reached through, a symbolic link in the main worktree" \
        "refuse health-prep linked: it holds a symbolic link or special file (or could not be listed whole), which could point outside the health checkout" \
        "refuse health-prep special: it holds a symbolic link or special file (or could not be listed whole), which could point outside the health checkout" \
        "refuse health-prep tracked.txt: git does not ignore it in the main worktree (only gitignored paths are copied; a tracked one is in the checkout already)" \
        "refuse health-prep .worktrees: it holds the health checkout itself"; do
        printf '%s\n' "$output" | grep -qxF -- "$want" || { echo "want: $want"; show; return 1; }
    done
    # cache passed its checks, but one refusal copies nothing.
    ! printf '%s\n' "$output" | grep -q '^copied ' && [ ! -e "$HC/cache" ] || { show; ls -la "$HC"; return 1; }
}

@test "--health-prep refuses a destination that exists or sits below a symlink in HC" {
    mkdir -p cache/in && echo a > cache/in/f
    settings 'Health checkout copies: cache/in' ''
    hc
    ln -s "$BATS_TEST_TMPDIR" "$HC/cache"
    hp "$HC"
    [ "$status" -eq 2 ] && [ "$output" = "refuse health-prep cache/in: cache in the health checkout is a symbolic link or not a directory" ] || { show; return 1; }
    [ ! -e "$BATS_TEST_TMPDIR/in" ] || { echo "wrote through the link"; return 1; }
    rm "$HC/cache" && mkdir -p "$HC/cache/in"
    hp "$HC"
    [ "$status" -eq 2 ] && [ "$output" = "refuse health-prep cache/in: it already exists in the health checkout" ] || { show; return 1; }
}

@test "--health-prep refuses a malformed line, and an HC that is not a detached worktree other than the main one" {
    mkdir -p cache && echo a > cache/f
    settings 'Health checkout copies: /abs' ''
    hc
    hp "$HC"
    [ "$status" -eq 2 ] && [[ "$output" == "refuse health-prep: --settings' copies line is not well formed, so nothing is copied (malformed: line 1 "* ]] || { show; return 1; }
    settings 'Health checkout copies: cache' ''
    hp "$R"
    [ "$status" -eq 2 ] && [ "$output" = "refuse health-prep: $R is the main worktree" ] || { show; return 1; }
    hp "$BATS_TEST_TMPDIR/nowhere"
    [ "$status" -eq 2 ] && [ "$output" = "refuse health-prep: $BATS_TEST_TMPDIR/nowhere is not a worktree of this repository (git worktree list)" ] || { show; return 1; }
    git worktree add -q -b side "$R/.worktrees/onbranch" main
    hp "$R/.worktrees/onbranch"
    [ "$status" -eq 2 ] && [ "$output" = "refuse health-prep: $R/.worktrees/onbranch is on a branch; the health checkout is a detached worktree" ] || { show; return 1; }
    [ ! -e "$R/.worktrees/onbranch/cache" ] || { show; return 1; }
    # Usage: one absolute path of the allowed characters.
    for args in "--health-prep" "--health-prep rel" "--health-prep /a/../b" "--health-prep /a /b"; do
        # shellcheck disable=SC2086  # split the argument list on purpose
        run --separate-stderr bash "$BL" $args
        [ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"--health-prep takes one absolute path"* ]] || { echo "[$args]"; show; return 1; }
    done
}

@test "--health-prep refuses a GIT_DIR-style variable in the caller's environment" {
    settings 'Health checkout copies: none' ''
    hc
    run --separate-stderr env GIT_WORK_TREE="$R" bash "$BL" --health-prep "$HC"
    [ "$status" -eq 2 ] && [[ "$output" == "refuse state GIT_WORK_TREE: "* ]] || { show; return 1; }
}

@test "SKILL.md's step 1 runs --health-prep on HC and names its line in Project settings" {
    S="$REPO_ROOT/skills/dev-cycle/SKILL.md"
    for f in 'build-loop.sh --health-prep HC' 'skipped: HC not prepared' '**Health checkout copies**' 'Health checkout copies: none'; do
        grep -qF -- "$f" "$S" || { echo "missing: $f"; return 1; }
    done
}
