#!/usr/bin/env bats
# @category fast
# Contract tests for build-loop.sh --free-worktrees, each in a throwaway repo
# under $BATS_TEST_TMPDIR (test/lib/build-loop-fixtures.bash). Brief
# 2026-11-06-free-merged-loop-worktrees.

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() {
    bl_setup
    echo '.claude/' > .gitignore
    constraints "H1: keep it small" "success: under 400 lines"
}

fr() { run --separate-stderr bash "$BL" --free-worktrees; }
show() { echo "status $status"; echo "$output"; echo "$stderr"; git worktree list --porcelain; git log --oneline --graph --all; }
# said LINE...: the run exited 0 and printed exactly these lines.
said() { [ "$status" -eq 0 ] && [ "$output" = "$(printf '%s\n' "$@")" ] || { echo "want: $*"; show; return 1; }; }
# lock_of WT: the worktree's lock line in git's list, empty when not locked.
lock_of() { git worktree list --porcelain | awk -v w="worktree $1" '$0 == w { on = 1; next } /^$/ { on = 0 } on && /^locked/'; }
# gone WT: git no longer lists WT and its directory is removed.
gone() { [ ! -e "$1" ] && ! git worktree list --porcelain | grep -qxF "worktree $1" || { show; return 1; }; }
# stays WT: git lists WT and its directory exists.
stays() { [ -d "$1" ] && git worktree list --porcelain | grep -qxF "worktree $1" || { show; return 1; }; }

# dispatched SLUG: brief SLUG (open, feat/SLUG), started as --start starts it;
# W its worktree.
dispatched() {
    brief "$1" "Status: open" "Branch: feat/$1"
    W="$R/.claude/wt-2026-10-01-$1"
    bash "$BL" --start "$B" > /dev/null || { echo "--start failed"; return 1; }
}
# finished SLUG: a dispatched loop that committed, closed its brief and left a
# ready marker, on its branch; not merged.
finished() {
    dispatched "$1"
    sed -i 's/^Status: open/Status: done/' "$W/$B"
    git -C "$W" add -A && git -C "$W" commit -q -m "work on $1"
    git -C "$W" commit -q --allow-empty -m "handoff: ready"
}
# merged SLUG: a finished loop whose branch main has merged.
merged() { finished "$1" && git merge -q --no-ff -m "merge $1" "feat/$1"; }

@test "merged and clean: the worktree goes, the branch stays and git branch -d now takes it" {
    merged x
    git branch -d feat/x 2>/dev/null && { echo "-d should refuse a checked-out branch"; return 1; }
    fr; said "freed feat/x $W"; gone "$W"
    git rev-parse -q --verify refs/heads/feat/x > /dev/null
    git branch -q -d feat/x
    fr; said ""
}

@test "merged and dirty: kept, reported and still locked, with the file there" {
    merged x; L="$(lock_of "$W")"
    echo new > "$W/untracked.txt"
    fr; [ "$status" -eq 0 ] && [[ "$output" == "kept feat/x $W: git refused (fatal: "*"contains modified or untracked files"* ]] || { show; return 1; }
    stays "$W"; [ "$(lock_of "$W")" = "$L" ] && [ -f "$W/untracked.txt" ]
    rm "$W/untracked.txt"; echo edit >> "$W/$B"
    fr; [[ "$output" == "kept feat/x $W: git refused"* ]] || { show; return 1; }
    stays "$W"; [ "$(lock_of "$W")" = "$L" ]
}

@test "unmerged: hold, whether the brief is open, or dropped with its branch unmerged" {
    finished x; L="$(lock_of "$W")"
    fr; said "hold feat/x $W: its brief is open"; stays "$W"; [ "$(lock_of "$W")" = "$L" ]
    sed -i 's/^Status: open/Status: dropped/' "$B"; commit_all dropped
    fr; said "hold feat/x $W: its branch has not merged"; stays "$W"; [ "$(lock_of "$W")" = "$L" ]
}

@test "a lock with another reason, or none, stays out of it: nothing printed, nothing touched" {
    merged x
    for why in "held by hand" "build-loop dispatch of 2026-10-01-x at $(git rev-parse HEAD), UTC 2026-10-01T00:00:00Z and more"; do
        git worktree unlock "$W"; git worktree lock --reason "$why" "$W"
        fr; said ""; stays "$W"; [ "$(lock_of "$W")" = "locked $why" ]
    done
    git worktree unlock "$W"
    fr; said ""; stays "$W"; [ -z "$(lock_of "$W")" ]
}

@test "a loop just dispatched is an ancestor of main, clean, and stays" {
    dispatched x; L="$(lock_of "$W")"
    git merge-base --is-ancestor feat/x main
    fr; said "hold feat/x $W: its brief is open"; stays "$W"
    commit_all "main moves on"
    fr; said "hold feat/x $W: its brief is open"; stays "$W"
    # Closed by hand under it: nothing says the loop ran.
    sed -i 's/^Status: open/Status: dropped/' "$B"; commit_all dropped
    fr; said "kept feat/x $W: its tip is not past the commit its lock names, so a live loop may hold it"; stays "$W"
    [ "$(lock_of "$W")" = "$L" ]
}

@test "a closed brief reads the same once its worktree and branch are gone" {
    merged x
    mkdir -p docs/working/briefs/closed; git mv "$B" "docs/working/briefs/closed/${B##*/}"; commit_all close
    C="docs/working/briefs/closed/${B##*/}"; DC="$REPO_ROOT/scripts/dev-cycle.sh"
    before="$(bash "$DC" --check-brief "$C")"
    [ "$(bash "$BL" --status "$C" | cut -d' ' -f1-5)" = "ok $C done review feat/x" ]
    fr; said "freed feat/x $W"; gone "$W"
    # Step 1's branch cleanup, as the skill runs it.
    [ "$(bash "$DC" --check-branch feat/x | cut -d' ' -f1-2)" = "ok feat/x" ]
    [[ "$(git for-each-ref --merged refs/heads/main --format='%(refname:short)' refs/heads/)" == *feat/x* ]]
    git branch -q -d feat/x
    [ "$(bash "$DC" --check-brief "$C")" = "$before" ]
    [ "$(bash "$DC" --check-branch feat/x)" = "absent feat/x" ]
    [ "$(bash "$BL" --status "$C")" = "ok $C done review feat/x absent - - 0" ]
}

@test "kept when the brief cannot back the removal: none on main, another branch, a skip" {
    merged x
    S="$(lock_of "$W")"; n="docs/working/briefs/2026-10-01-y.md"
    git mv "$B" "$n"; commit_all moved
    fr; said "kept feat/x $W: the default branch has no brief 2026-10-01-x"; stays "$W"
    git mv "$n" "$B"; sed -i 's|^Branch: feat/x|Branch: feat/other|' "$B"; commit_all other
    fr; said "kept feat/x $W: its brief $B names the branch feat/other"; stays "$W"
    sed -i 's|^Branch: feat/other|Branch: two words|' "$B"; commit_all skip
    fr; [[ "$output" == "kept feat/x $W: its brief is not read (skip $B: "* ]] || { show; return 1; }
    stays "$W"; [ "$(lock_of "$W")" = "$S" ]
}

@test "kept when the worktree is on no branch, or its directory is missing" {
    merged x
    git -C "$W" checkout -q --detach
    fr; said "kept - $W: it is on no branch"; stays "$W"
    git -C "$W" checkout -q feat/x
    mv "$W" "$W.away"
    fr; said "kept feat/x $W: it is missing or a symbolic link"
    [ -n "$(lock_of "$W")" ]
}

@test "an ignored file goes with the worktree: git does not call it dirty" {
    echo 'scratch.txt' >> .gitignore; commit_all ignore
    merged x
    echo notes > "$W/scratch.txt"
    fr; said "freed feat/x $W"; gone "$W"
}

@test "a brief still open keeps another's removal going: one line per worktree" {
    merged x; A="$W"; dispatched y; Y="$W"
    fr; said "freed feat/x $A" "hold feat/y $Y: its brief is open"; gone "$A"; stays "$Y"
}

@test "refuses, removing nothing, under another run's dispatch lock or a lock file that is not plain" {
    merged x
    lf="$(git rev-parse --path-format=absolute --git-common-dir)/build-loop-dispatch.lock"
    exec 8>> "$lf"; flock -n 8
    fr; exec 8>&-
    [ "$status" -eq 2 ] && [ "$output" = "refuse worktrees: another --start, --prompt or --free-worktrees is running in this repository; retry once it ends" ] || { show; return 1; }
    stays "$W"
    rm "$lf"; mkdir "$lf"
    fr; [ "$status" -eq 2 ] && [ "$output" = "refuse worktrees: the dispatch lock file (build-loop-dispatch.lock in the git directory) is not a plain file or cannot be opened" ] || { show; return 1; }
    stays "$W"
}

# shim WORDS: a git on PATH that fails on "git worktree WORDS..." and is the real one otherwise.
shim() {
    mkdir -p "$BATS_TEST_TMPDIR/bin"; real="$(command -v git)"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<SH
#!/usr/bin/env bash
a=" \$* "
[[ "\$a" != *" worktree $1 "* ]] || { echo "fatal: shim refuses" >&2; exit 128; }
exec "$real" "\$@"
SH
    chmod +x "$BATS_TEST_TMPDIR/bin/git"
}

@test "git's failures are named: the list, the unlock, and a lock not put back" {
    merged x; echo new > "$W/untracked.txt"
    shim list
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" fr
    [ "$status" -eq 2 ] && [ "$output" = "refuse worktrees: the worktrees could not be listed" ] || { show; return 1; }
    shim unlock
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" fr; said "kept feat/x $W: it could not be unlocked (fatal: shim refuses)"
    [ -n "$(lock_of "$W")" ]
    shim lock
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" fr
    [ "$status" -eq 0 ] && [[ "$output" == "kept feat/x $W: git refused (fatal: "*"; its lock could not be put back)" ]] || { show; return 1; }
    stays "$W"; [ -z "$(lock_of "$W")" ]
}

@test "--free-worktrees takes no arguments, and step 1 of the skill calls it before it deletes branches" {
    run --separate-stderr bash "$BL" --free-worktrees x
    [ "$status" -eq 1 ] && [[ "$stderr" == "--free-worktrees takes no arguments"* ]] || { show; return 1; }
    s="$(awk '/^### 1\. /{ on = 1; next } /^### /{ on = 0 } on' "$REPO_ROOT/skills/dev-cycle/SKILL.md")"
    [[ "$s" == *'--free-worktrees'*'Delete merged branches'* ]]
}
