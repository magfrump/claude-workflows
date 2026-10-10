#!/usr/bin/env bats
# @category fast
# Contract tests for build-loop.sh --merge (U3a2): a self-merge brief lands by
# compare-and-swap, or by a fast-forward in the worktree that has main checked
# out. Each test builds a throwaway repo under $BATS_TEST_TMPDIR
# (test/lib/build-loop-fixtures.bash); this repo is untouched.

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() { bl_setup; }

# mrg ARG...: run build-loop.sh --merge. show: what a failed test prints, the history included.
mrg() { run --separate-stderr bash "$BL" --merge "$@"; }
show() { echo "status $status"; echo "$output"; echo "$stderr"; git -c log.date=default log --oneline --graph --all; }
# sm [PATHS]: self-merge on, brief x (self-merge, naming feat/x, listing PATHS,
# by default feat/x's file) and feat/x with one commit; B is its path, T its
# tip, M main's commit, TR the merged tree.
sm() {
    settings "Build-loop policy: self-merge" "Self-merge never: none"
    brief x "Status: open" "Branch: feat/x" "Policy: self-merge" "Paths: ${1:-work-feat-x.txt}"; work feat/x
    T="$(git rev-parse feat/x)"; M="$(git rev-parse main)"; TR="$(git merge-tree --write-tree main feat/x)"
}
# orch: a worktree detached at main, as the orchestrator's own; the test moves into it.
orch() { git worktree add -q --detach "$BATS_TEST_TMPDIR/o" main && cd "$BATS_TEST_TMPDIR/o" || return 1; }
# shim WHEN ACTION: a git first on PATH that runs ACTION (shell; REAL is the
# real git) once, before the first call whose arguments hold WHEN. Used as
# PATH="$SHIM:$PATH" mrg ..., so the test's own git calls are the real one.
SHIM_REAL="$(command -v git)"
shim() {
    SHIM="$BATS_TEST_TMPDIR/bin"; mkdir -p "$SHIM"; rm -f "$SHIM/fired"
    { echo '#!/usr/bin/env bash'; echo "REAL='$SHIM_REAL'; D='$SHIM'"
      echo "if [[ \"\$*\" == *'$1'* && ! -e \"\$D/fired\" ]]; then : > \"\$D/fired\"; $2; fi"
      echo 'exec "$REAL" "$@"'; } > "$SHIM/git"
    chmod +x "$SHIM/git"
}
# refused WHY: --merge refused brief x with WHY, listed feat/x's path, and left main at M.
refused() {
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: $1" ] && [ "${lines[1]}" = "path $B A work-feat-x.txt" ] \
        && [ "$(git rev-parse main)" = "$M" ] || { echo "want: $1"; show; return 1; }
}

@test "--merge lands a self-merge brief by compare-and-swap when no worktree has main checked out: parents, tree, message, trailer; a second run refuses (T22, G13, U3a2)" {
    sm; git checkout -q --detach main
    mrg "$B" --expect "$T"
    n="$(git rev-parse main)"
    [ "$status" -eq 0 ] && [ "$output" = "merged $B $T $TR $n
path $B A work-feat-x.txt" ] && [ -z "$stderr" ] || { show; return 1; }
    [ "$(git rev-parse "$n^1") $(git rev-parse "$n^2") $(git rev-parse "$n^{tree}")" = "$M $T $TR" ]
    [ "$(git log -1 --format=%B "$n")" = "Merge branch 'feat/x' (build-loop self-merge)

Build-loop-gate: 2026-10-01-x" ]
    [ "$(git log -1 --format='%an %ae %cn %ce' "$n")" = "t t@example.invalid t t@example.invalid" ]
    [ "$(git rev-parse HEAD)" = "$M" ] && [ "$(git reflog -1 --format=%gs main)" = "build-loop: self-merge of 2026-10-01-x" ]
    mrg "$B" --expect "$T"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: its branch feat/x has no commit the default branch lacks" ] && [ "$(git rev-parse main)" = "$n" ] || { show; return 1; }
}

@test "--merge leaves main where another writer moved it between the check and the swap, and refuses git state planted after the check (T22, G17, row 494, U3a2)" {
    sm; git checkout -q --detach main
    o="$(git commit-tree "$(git rev-parse 'main^{tree}')" -p main -m other)"
    shim update-ref "\"\$REAL\" update-ref refs/heads/main $o"
    PATH="$SHIM:$PATH" mrg "$B" --expect "$T"
    M="$o" refused "the default branch moved after the check, or could not be updated; it was left as it is"
    git update-ref refs/heads/main "$M"
    shim commit-tree "\"\$REAL\" config --file '$R/.git/config' filter.x.clean cat"  # commit-tree runs in the gate repository
    PATH="$SHIM:$PATH" mrg "$B" --expect "$T"
    refused "the git state changed after the check (refuse state filter.x.clean: set in config, it can make the gate's git run a command or change its merge)"
}

@test "--merge refuses a review brief and a caller git knows no identity for, takes the identity from the caller's global config, and needs one brief and --expect (U3a2)" {
    sm; git checkout -q --detach main
    noid=(env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL)
    run --separate-stderr "${noid[@]}" bash "$BL" --merge "$B" --expect "$T"
    refused "git knows no author or committer identity (GIT_AUTHOR_NAME and the like, or user.name and user.email in git config)"
    # Names set but the email only in EMAIL: git would take it (and on other hosts guess from the domain); user.useConfigOnly refuses.
    run --separate-stderr "${noid[@]}" GIT_AUTHOR_NAME=n GIT_COMMITTER_NAME=n EMAIL=e@example.invalid bash "$BL" --merge "$B" --expect "$T"
    refused "git knows no author or committer identity (GIT_AUTHOR_NAME and the like, or user.name and user.email in git config)"
    printf '[user]\n\tname = g\n\temail = g@example.invalid\n' > "$BATS_TEST_TMPDIR/gc"
    run --separate-stderr "${noid[@]}" GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gc" bash "$BL" --merge "$B" --expect "$T"
    [ "$status" -eq 0 ] && [ "$(git log -1 --format='%an %ae %cn %ce' main)" = "g g@example.invalid g g@example.invalid" ] || { show; return 1; }
    git update-ref refs/heads/main "$M"
    git checkout -q main && settings "Build-loop policy: review" "Self-merge never: none" && git checkout -q --detach main
    M="$(git rev-parse main)"
    mrg "$B" --expect "$T"
    refused "the brief's policy is review; --merge lands only a self-merge brief"
    for args in "$B" "--expect $T" "$B $B --expect $T"; do
        read -ra av <<<"$args"; mrg "${av[@]}"
        [ "$status" -eq 1 ] && [[ "$stderr" == "--merge takes one brief path and --expect SHA "* ]] || { show; return 1; }
    done
}

@test "--merge fast-forwards the worktree that has main checked out, from it or from another, keeping an unrelated untracked file; a worktree on another branch is left alone (T23, F50, U3a2)" {
    sm; echo u > unrelated.txt
    mrg "$B" --expect "$T"
    n="$(git rev-parse main)"
    [ "$status" -eq 0 ] && [ "${lines[0]}" = "merged $B $T $TR $n" ] && [ -z "$stderr" ] || { show; return 1; }
    [ "$(git rev-parse HEAD)" = "$n" ] && [ "$(cat work-feat-x.txt)" = feat/x ] && [ -f unrelated.txt ] && [ -z "$(git status --porcelain --untracked-files=no)" ]
    git reset -q --hard "$M"; orch
    mrg "$B" --expect "$T"
    [ "$status" -eq 0 ] && [ "$(git -C "$R" rev-parse HEAD)" = "$(git rev-parse main)" ] && [ "$(cat "$R/work-feat-x.txt")" = feat/x ] || { show; return 1; }
    [ "$(git reflog -1 --format=%gs main)" = "build-loop: self-merge of 2026-10-01-x: Fast-forward" ]
    # The branch's own mergeOptions are cleared: --squash would stage the merge in W and leave main (i1 security F1).
    # No maintenance task repacks the store store_check read (i2 performance F1): loose objects stay loose.
    git -C "$R" reset -q --hard "$M" && git config maintenance.auto true && git config maintenance.loose-objects.enabled true && git config maintenance.loose-objects.auto 1
    np="$(find "$R/.git/objects/pack" -type f | wc -l)"
    mrg "$B" --expect "$T"
    [ "$status" -eq 0 ] && [ "$(find "$R/.git/objects/pack" -type f | wc -l)" = "$np" ] || { show; return 1; }
    git -C "$R" reset -q --hard "$M" && git config branch.main.mergeOptions --squash
    mrg "$B" --expect "$T"
    [ "$status" -eq 0 ] && [ "$(git -C "$R" rev-parse HEAD)" = "$(git rev-parse main)" ] && [ -z "$(git -C "$R" status --porcelain --untracked-files=no)" ] || { show; return 1; }
    git -C "$R" reset -q --hard "$M" && git -C "$R" checkout -q -b feat/y
    mrg "$B" --expect "$T"
    [ "$status" -eq 0 ] && [ "$(git -C "$R" symbolic-ref HEAD)" = refs/heads/feat/y ] && [ "$(git -C "$R" rev-parse HEAD)" = "$M" ] || { show; return 1; }
}

@test "--merge refuses when the worktree with main checked out has a tracked change, is mid an operation, or holds a file at a path the merge adds; or a worktree rebases or bisects main (T23, F29, F50, U3a2)" {
    sm; orch
    in="the worktree with the default branch checked out"
    echo d >> "$R/docs/dev-cycle.md"; mrg "$B" --expect "$T"; refused "$in has a tracked change, or git status failed or warned there"
    git -C "$R" checkout -q -- docs/dev-cycle.md
    echo u > "$R/work-feat-x.txt"; mrg "$B" --expect "$T"; refused "$in holds an untracked or ignored work-feat-x.txt, a path the merge adds"
    echo work-feat-x.txt > "$R/.git/info/exclude"; mrg "$B" --expect "$T"; refused "$in holds an untracked or ignored work-feat-x.txt, a path the merge adds"
    rm "$R/work-feat-x.txt"
    for f in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_START; do
        echo "$M" > "$R/.git/$f"; mrg "$B" --expect "$T"; refused "$in is in the middle of a merge, cherry-pick, revert, rebase or bisect ($f)"; rm "$R/.git/$f"
    done
    for f in rebase-merge rebase-apply sequencer; do
        mkdir "$R/.git/$f"; mrg "$B" --expect "$T"; refused "$in is in the middle of a merge, cherry-pick, revert, rebase or bisect ($f)"; rmdir "$R/.git/$f"
    done
    a="$R/.git/worktrees/o"
    mkdir "$a/rebase-merge" && echo refs/heads/main > "$a/rebase-merge/head-name"
    mrg "$B" --expect "$T"; refused "a worktree is rebasing the default branch, or its rebase state cannot be read"
    # A paused rebase --update-refs of another branch that will move main (i2 security F2); an unreadable head-name.
    printf 'refs/heads/feat/z\n' > "$a/rebase-merge/head-name"; printf 'refs/heads/main\n%s\n%s\n' "$M" "$M" > "$a/rebase-merge/update-refs"
    mrg "$B" --expect "$T"; refused "a worktree is rebasing the default branch, or its rebase state cannot be read"
    rm "$a/rebase-merge/update-refs"; chmod 000 "$a/rebase-merge/head-name"
    mrg "$B" --expect "$T"; refused "a worktree is rebasing the default branch, or its rebase state cannot be read"; rm -r "$a/rebase-merge"
    mkdir -p "$R/.git/worktrees/.x/rebase-merge" && echo refs/heads/main > "$R/.git/worktrees/.x/rebase-merge/head-name"
    mrg "$B" --expect "$T"; refused "a worktree is rebasing the default branch, or its rebase state cannot be read"; rm -r "$R/.git/worktrees/.x"
    echo main > "$a/BISECT_START"; mrg "$B" --expect "$T"; refused "a worktree is bisecting from the default branch, or its bisect state cannot be read"
    echo feat/x > "$a/BISECT_START"; mrg "$B" --expect "$T"; [ "$status" -eq 0 ] || { show; return 1; }
}

@test "--merge refuses a file or link where the merge adds a directory, and a worktree registered on main that is missing or has its work tree elsewhere (T23, U3a2; i1 security)" {
    sm "work-feat-x.txt sub/"; git checkout -q feat/x && mkdir sub && echo f > sub/f.txt && commit_all sub && git checkout -q main
    T="$(git rev-parse feat/x)"; TR="$(git merge-tree --write-tree main feat/x)"; orch
    in="the worktree with the default branch checked out"
    nref() { [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: $1" ] && [ "$(git rev-parse main)" = "$M" ] || { echo "want: $1"; show; return 1; }; }
    echo f > "$R/sub"; mrg "$B" --expect "$T"; nref "$in holds sub, where the merge adds a directory"; rm "$R/sub"
    ln -s "$BATS_TEST_TMPDIR" "$R/sub"; mrg "$B" --expect "$T"; nref "$in holds sub, where the merge adds a directory"; rm "$R/sub"
    mkdir "$BATS_TEST_TMPDIR/elsewhere" && git -C "$R" config core.worktree "$BATS_TEST_TMPDIR/elsewhere"
    mrg "$B" --expect "$T"; nref "$in is missing, not its own top level, or not on it at $M"; git -C "$R" config --unset core.worktree
    # W's own config.worktree is gated before git status runs there: its clean filter never runs (i2 security F1).
    git config extensions.worktreeConfig true && git -C "$R" config --worktree filter.x.clean "touch '$BATS_TEST_TMPDIR/ran'; cat"
    echo '* filter=x' > "$R/.gitattributes"; touch -d '2000-01-01' "$R/docs/dev-cycle.md"
    mrg "$B" --expect "$T"; nref "$in fails the state gate (refuse state filter.x.clean: set in config.worktree, it can make the gate's git run a command or change its merge)"
    [ ! -e "$BATS_TEST_TMPDIR/ran" ]; rm "$R/.gitattributes"; git -C "$R" config --worktree --unset filter.x.clean; git config --unset extensions.worktreeConfig
    git -C "$R" checkout -q --detach && git worktree add -q "$BATS_TEST_TMPDIR/w2" main && rm -rf "$BATS_TEST_TMPDIR/w2"
    mrg "$B" --expect "$T"; nref "$in is missing"
}
