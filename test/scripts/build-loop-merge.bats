#!/usr/bin/env bats
# @category fast
# Contract tests for build-loop.sh --merge (U3a2) and --merge --approved (U3a3), each in a throwaway repo
# under $BATS_TEST_TMPDIR (test/lib/build-loop-fixtures.bash).

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() { bl_setup; }

# mrg ARG...: run build-loop.sh --merge. show: what a failed test prints, the history included.
mrg() { run --separate-stderr bash "$BL" --merge "$@"; }
show() { echo "status $status"; echo "$output"; echo "$stderr"; git -c log.date=default log --oneline --graph --all; }
# sm [PATHS]: self-merge on, brief x (self-merge, feat/x, Paths: PATHS or feat/x's file) and feat/x
# with one commit; B is the brief's path, T the tip, M main's commit, TR the merged tree.
sm() {
    settings "Build-loop policy: self-merge" "Self-merge never: none"
    brief x "Status: open" "Branch: feat/x" "Policy: self-merge" "Paths: ${1:-work-feat-x.txt}"; work feat/x
    T="$(git rev-parse feat/x)"; M="$(git rev-parse main)"; TR="$(git merge-tree --write-tree main feat/x)"
}
# orch: a worktree detached at main, as the orchestrator's own; the test moves into it.
orch() { git worktree add -q --detach "$BATS_TEST_TMPDIR/o" main && cd "$BATS_TEST_TMPDIR/o" || return 1; }
# shim WHEN ACTION: a git (used as PATH="$SHIM:$PATH" mrg ...) that runs ACTION (shell; REAL is
# the real git) once, before the first call whose arguments hold WHEN.
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
    mrg "$B" --expect "$T"; n="$(git rev-parse main)"
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
    PATH="$SHIM:$PATH" mrg "$B" --expect "$T"; M="$o" refused "the default branch moved after the check, or could not be updated; it was left as it is"
    git update-ref refs/heads/main "$M"
    shim commit-tree "\"\$REAL\" config --file '$R/.git/config' filter.x.clean cat"  # commit-tree runs in the gate repository
    PATH="$SHIM:$PATH" mrg "$B" --expect "$T"; refused "the git state changed after the check (refuse state filter.x.clean: set in config, it can make the gate's git run a command or change its merge)"
    # A symbolic default branch refuses before any brief (final security F3).
    git config --unset filter.x.clean; git update-ref refs/heads/trunk "$M" && git symbolic-ref refs/heads/main refs/heads/trunk
    mrg "$B" --expect "$T"; [ "$status" -eq 2 ] && [ "$output" = "refuse state default-branch: refs/heads/main is a symbolic ref" ] && [ "$(git rev-parse trunk)" = "$M" ] || { show; return 1; }
}

@test "--merge refuses a review brief and a caller git knows no identity for, takes the identity from the caller's global config, and needs one brief and --expect (U3a2)" {
    sm; git checkout -q --detach main
    noid=(env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL)
    run --separate-stderr "${noid[@]}" bash "$BL" --merge "$B" --expect "$T"; refused "git knows no author or committer identity (GIT_AUTHOR_NAME and the like, or user.name and user.email in git config)"
    # Names set but the email only in EMAIL: git would take it (and on other hosts guess from the domain); user.useConfigOnly refuses.
    run --separate-stderr "${noid[@]}" GIT_AUTHOR_NAME=n GIT_COMMITTER_NAME=n EMAIL=e@example.invalid bash "$BL" --merge "$B" --expect "$T"; refused "git knows no author or committer identity (GIT_AUTHOR_NAME and the like, or user.name and user.email in git config)"
    printf '[user]\n\tname = g\n\temail = g@example.invalid\n' > "$BATS_TEST_TMPDIR/gc"
    run --separate-stderr "${noid[@]}" GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gc" bash "$BL" --merge "$B" --expect "$T"
    [ "$status" -eq 0 ] && [ "$(git log -1 --format='%an %ae %cn %ce' main)" = "g g@example.invalid g g@example.invalid" ] || { show; return 1; }
    git update-ref refs/heads/main "$M"
    # A name with only committer.email set: the author's email would be empty (final fact-check 5).
    printf '[user]\n\tname = g\n[committer]\n\temail = c@example.invalid\n' > "$BATS_TEST_TMPDIR/gc2"
    run --separate-stderr "${noid[@]}" GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gc2" bash "$BL" --merge "$B" --expect "$T"; refused "git knows no author or committer identity (GIT_AUTHOR_NAME and the like, or user.name and user.email in git config)"
    git checkout -q main && settings "Build-loop policy: review" "Self-merge never: none" && git checkout -q --detach main
    M="$(git rev-parse main)"
    mrg "$B" --expect "$T"; refused "the brief's policy is review; --merge lands it only with --approved Q-NNN"
    for args in "$B" "--expect $T" "$B $B --expect $T"; do
        read -ra av <<<"$args"; mrg "${av[@]}"
        [ "$status" -eq 1 ] && [[ "$stderr" == "--merge takes one brief path and --expect SHA "* ]] || { show; return 1; }
    done
}

@test "--merge fast-forwards the worktree that has main checked out, from it or from another, keeping an unrelated untracked file; a worktree on another branch is left alone (T23, F50, U3a2)" {
    sm; echo u > unrelated.txt
    mrg "$B" --expect "$T"; n="$(git rev-parse main)"
    [ "$status" -eq 0 ] && [ "${lines[0]}" = "merged $B $T $TR $n" ] && [ -z "$stderr" ] || { show; return 1; }
    [ "$(git rev-parse HEAD)" = "$n" ] && [ "$(cat work-feat-x.txt)" = feat/x ] && [ -f unrelated.txt ] && [ -z "$(git status --porcelain --untracked-files=no)" ]
    git reset -q --hard "$M"; orch
    mrg "$B" --expect "$T"; [ "$status" -eq 0 ] && [ "$(git -C "$R" rev-parse HEAD)" = "$(git rev-parse main)" ] && [ "$(cat "$R/work-feat-x.txt")" = feat/x ] || { show; return 1; }
    [ "$(git reflog -1 --format=%gs main)" = "build-loop: self-merge of 2026-10-01-x: Fast-forward" ]
    # No maintenance repack of the store store_check read (i2 performance F1); then a --squash mergeOptions is cleared (i1 security F1).
    git -C "$R" reset -q --hard "$M" && git config maintenance.auto true && git config maintenance.loose-objects.enabled true && git config maintenance.loose-objects.auto 1
    np="$(find "$R/.git/objects/pack" -type f | wc -l)"
    mrg "$B" --expect "$T"; [ "$status" -eq 0 ] && [ "$(find "$R/.git/objects/pack" -type f | wc -l)" = "$np" ] || { show; return 1; }
    git -C "$R" reset -q --hard "$M" && git config branch.main.mergeOptions --squash
    mrg "$B" --expect "$T"; [ "$status" -eq 0 ] && [ "$(git -C "$R" rev-parse HEAD)" = "$(git rev-parse main)" ] && [ -z "$(git -C "$R" status --porcelain --untracked-files=no)" ] || { show; return 1; }
    git -C "$R" reset -q --hard "$M" && git -C "$R" checkout -q -b feat/y
    mrg "$B" --expect "$T"; [ "$status" -eq 0 ] && [ "$(git -C "$R" symbolic-ref HEAD)" = refs/heads/feat/y ] && [ "$(git -C "$R" rev-parse HEAD)" = "$M" ] || { show; return 1; }
}

@test "--merge refuses when the worktree with main checked out has a tracked change, is mid an operation, or holds a file at a path the merge adds; or a worktree rebases or bisects main (T23, F29, F50, U3a2)" {
    sm; orch
    in="the worktree with the default branch checked out"; echo d >> "$R/docs/dev-cycle.md"; mrg "$B" --expect "$T"; refused "$in has a tracked change, or git status failed or warned there"
    git -C "$R" checkout -q -- docs/dev-cycle.md
    echo u > "$R/work-feat-x.txt"; mrg "$B" --expect "$T"; refused "$in holds an untracked or ignored work-feat-x.txt, a path the merge adds"
    echo work-feat-x.txt > "$R/.git/info/exclude"; mrg "$B" --expect "$T"; refused "$in holds an untracked or ignored work-feat-x.txt, a path the merge adds"
    rm "$R/work-feat-x.txt"; for f in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_START; do
        echo "$M" > "$R/.git/$f"; mrg "$B" --expect "$T"; refused "$in is in the middle of a merge, cherry-pick, revert, rebase or bisect ($f)"; rm "$R/.git/$f"
    done
    for f in rebase-merge rebase-apply sequencer; do
        mkdir "$R/.git/$f"; mrg "$B" --expect "$T"; refused "$in is in the middle of a merge, cherry-pick, revert, rebase or bisect ($f)"; rmdir "$R/.git/$f"
    done
    a="$R/.git/worktrees/o"
    mkdir "$a/rebase-merge" && echo refs/heads/main > "$a/rebase-merge/head-name"
    mrg "$B" --expect "$T"; refused "a worktree is rebasing the default branch"
    # A CR git's rebase --abort strips (final security F2).
    printf 'refs/heads/main\r\n' > "$a/rebase-merge/head-name"; mrg "$B" --expect "$T"; refused "a worktree is rebasing the default branch"
    # A paused rebase --update-refs of another branch that will move main (i2 security F2).
    printf 'refs/heads/feat/z\n' > "$a/rebase-merge/head-name"; printf 'refs/heads/main\n%s\n%s\n' "$M" "$M" > "$a/rebase-merge/update-refs"
    mrg "$B" --expect "$T"; refused "a worktree is rebasing the default branch"
    # State that exists but cannot be read as a plain file refuses (final fact-check 8, 9; security F2).
    hn="a worktree's git state (rebase-merge/head-name) cannot be read"; rm "$a/rebase-merge/update-refs"
    chmod 000 "$a/rebase-merge/head-name"; mrg "$B" --expect "$T"; refused "$hn"; rm -f "$a/rebase-merge/head-name"
    mkdir "$a/rebase-merge/head-name"; mrg "$B" --expect "$T"; refused "$hn"
    chmod 000 "$a/rebase-merge"; mrg "$B" --expect "$T"; refused "a worktree's git directory or rebase state cannot be read"; chmod 755 "$a/rebase-merge"; rm -r "$a/rebase-merge"
    echo x > "$a/BISECT_START"; chmod 000 "$a/BISECT_START"; mrg "$B" --expect "$T"; refused "a worktree's git state (BISECT_START) cannot be read"; rm -f "$a/BISECT_START"
    x="$R/.git/worktrees/.x"; mkdir -p "$x/rebase-merge" && echo refs/heads/main > "$x/rebase-merge/head-name" && echo "$M" > "$x/HEAD" && echo ../.. > "$x/commondir"
    mrg "$B" --expect "$T"; refused "a worktree is rebasing the default branch"
    chmod 000 "$x/rebase-merge"; mrg "$B" --expect "$T"; refused "a worktree's git directory or rebase state cannot be read"; chmod 755 "$x/rebase-merge"; rm -r "$x"
    echo main > "$a/BISECT_START"; mrg "$B" --expect "$T"; refused "a worktree is bisecting from the default branch"
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
    mrg "$B" --expect "$T"; nref "$in is missing, not its own top level, not the one whose git directory names the branch, or not on it at $M"; git -C "$R" config --unset core.worktree
    # W's own config.worktree is gated before git status runs there: its clean filter never runs (i2 security F1).
    git config extensions.worktreeConfig true && git -C "$R" config --worktree filter.x.clean "touch '$BATS_TEST_TMPDIR/ran'; cat"
    echo '* filter=x' > "$R/.gitattributes"; touch -d '2000-01-01' "$R/docs/dev-cycle.md"
    mrg "$B" --expect "$T"; nref "$in fails the state gate (refuse state filter.x.clean: set in config.worktree, it can make the gate's git run a command or change its merge)"
    [ ! -e "$BATS_TEST_TMPDIR/ran" ]; rm "$R/.gitattributes"; git -C "$R" config --worktree --unset filter.x.clean; git config --unset extensions.worktreeConfig
    git -C "$R" checkout -q --detach && git worktree add -q "$BATS_TEST_TMPDIR/w2" main
    # w2's .git names a copy of its admin dir outside worktrees/: on main at M, but not the git dir that counted (rubric G6).
    cp -r "$R/.git/worktrees/w2" "$BATS_TEST_TMPDIR/rogue" && echo "$R/.git" > "$BATS_TEST_TMPDIR/rogue/commondir" && echo "gitdir: $BATS_TEST_TMPDIR/rogue" > "$BATS_TEST_TMPDIR/w2/.git"; mrg "$B" --expect "$T"; nref "$in is missing, not its own top level, not the one whose git directory names the branch, or not on it at $M"; echo "gitdir: $R/.git/worktrees/w2" > "$BATS_TEST_TMPDIR/w2/.git"
    # Its gitdir file gone, git worktree list drops w2, which still has main checked out (final security F1).
    mv "$R/.git/worktrees/w2/gitdir" "$BATS_TEST_TMPDIR/gd"; mrg "$B" --expect "$T"; nref "a worktree has the default branch checked out that git worktree list does not show"
    # Its HEAD as git reads it (confirming security 1, 2): "ref:" then a newline; on a symbolic alias of main.
    printf 'ref:\nrefs/heads/main\n' > "$R/.git/worktrees/w2/HEAD"; mrg "$B" --expect "$T"; nref "a worktree has the default branch checked out that git worktree list does not show"
    git symbolic-ref refs/heads/alias refs/heads/main && echo 'ref: refs/heads/alias' > "$R/.git/worktrees/w2/HEAD"; mrg "$B" --expect "$T"; nref "a worktree has the default branch checked out that git worktree list does not show"
    echo 'ref: refs/heads/main' > "$R/.git/worktrees/w2/HEAD"; git update-ref -d --no-deref refs/heads/alias; mv "$BATS_TEST_TMPDIR/gd" "$R/.git/worktrees/w2/gitdir"; rm -rf "$BATS_TEST_TMPDIR/w2"
    mrg "$B" --expect "$T"; nref "$in is missing"
}

@test "--merge lands in a bare repository whose worktree is detached or on main, and refuses one listed bare with an index (U3a2 confirming security 4)" {
    sm; git clone -q --bare "$R" "$BATS_TEST_TMPDIR/b.git" && cd "$BATS_TEST_TMPDIR/b.git" && git worktree add -q --detach ../bo main && cd ../bo || return 1
    mrg "$B" --expect "$T"; [ "$status" -eq 0 ] && [[ "${lines[0]}" == "merged $B "* ]] || { show; return 1; }
    git -C ../b.git update-ref refs/heads/main "$M"; git -C ../b.git worktree add -q ../bw main
    mrg "$B" --expect "$T"; [ "$status" -eq 0 ] && [ "$(git -C ../bw rev-parse HEAD)" = "$(git rev-parse main)" ] || { show; return 1; }
    git -C ../b.git update-ref refs/heads/main "$M"; git -C ../bw reset -q --hard "$M"; : > ../b.git/index
    mrg "$B" --expect "$T"; [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: the repository lists as bare but has an index" ] || { show; return 1; }
}

# approve ID SLUG [STATUS [ANSWER]]: docs/working/questions.md holding one entry "### ID · SLUG" with
# that Status (ANSWERED) and answer line ("ID: [1]"), committed on main; the checkout is left
# detached at main, and M is main's commit.
approve() {
    git checkout -q main && mkdir -p docs/working \
        && printf '### %s \302\267 %s\n**Needs:** you: judgment \302\267 **Opened:** 2026-10-01 \302\267 **Status:** %s\n\nMerge it?\n\n%s\n' \
            "$1" "$2" "${3:-ANSWERED}" "${4:-$1: [1]}" > docs/working/questions.md \
        && commit_all "answer $1" && git checkout -q --detach main && M="$(git rev-parse main)"
}
# rv [FILE]: review policy, brief x (no Policy: line, so review) and feat/x with one commit (and a
# second adding FILE, when given), then Q-001 answered [1] as merge-2026-10-01-x-SHA12 (S); T the tip,
# TR the merged tree.
rv() {
    settings "Build-loop policy: review"; brief x "Status: open" "Branch: feat/x"; work feat/x
    [[ -z "${1:-}" ]] || { git checkout -q feat/x && mkdir -p "$(dirname "$1")" && echo g > "$1" && commit_all gate && git checkout -q main; }
    T="$(git rev-parse feat/x)"; S="merge-2026-10-01-x-${T:0:12}"; approve Q-001 "$S"
    TR="$(git merge-tree --write-tree main feat/x)"
}

@test "--merge --approved lands a review brief on Q-NNN answered [1] under merge-STEM-SHA12: message, trailers, reflog (T35, U3a3)" {
    rv
    mrg "$B" --expect "$T" --approved Q-001; n="$(git rev-parse main)"
    [ "$status" -eq 0 ] && [ "$output" = "merged $B $T $TR $n
path $B A work-feat-x.txt" ] && [ -z "$stderr" ] || { show; return 1; }
    [ "$(git rev-parse "$n^1") $(git rev-parse "$n^2") $(git rev-parse "$n^{tree}")" = "$M $T $TR" ]
    [ "$(git log -1 --format=%B "$n")" = "Merge branch 'feat/x' (build-loop approved merge)

Build-loop-gate: 2026-10-01-x
Build-loop-approved: Q-001" ]
    [ "$(git reflog -1 --format=%gs main)" = "build-loop: approved merge of 2026-10-01-x" ]
}

@test "--merge --approved runs the N rules only: a self-merge brief lands past its never glob, its Paths: line and the checkout rule; a cycle file still refuses (T35, row 653, U3a3)" {
    settings "Build-loop policy: self-merge" "Self-merge never: work-*"
    brief x "Status: open" "Branch: feat/x" "Policy: self-merge" "Paths: none"; work feat/x
    T="$(git rev-parse feat/x)"; approve Q-001 "merge-2026-10-01-x-${T:0:12}"
    git checkout -q feat/x  # the checkout is not at main's commit: a self-merge --check refuses it
    mrg "$B" --expect "$T"
    [ "$status" -eq 2 ] && [[ "${lines[0]}" == "refuse $B: a self-merge brief needs --check run from a clean checkout"* ]] && [ "$(git rev-parse main)" = "$M" ] || { show; return 1; }
    mrg "$B" --expect "$T" --approved Q-001
    [ "$status" -eq 0 ] && [ "${lines[0]}" = "merged $B $T $(git merge-tree --write-tree "$M" "$T") $(git rev-parse main)" ] \
        && [ "${lines[1]}" = "path $B A work-feat-x.txt" ] || { show; return 1; }
    # A cycle file still refuses: the roadmap, and the questions file an approval is read from (i1 security).
    git update-ref refs/heads/main "$M"; git checkout -q feat/x && mkdir -p docs/working && echo r > docs/roadmap.md && echo q > docs/working/questions-archive.md && commit_all cycle
    T="$(git rev-parse feat/x)"; approve Q-001 "merge-2026-10-01-x-${T:0:12}"
    mrg "$B" --expect "$T" --approved Q-001
    [ "$status" -eq 2 ] && [[ "${lines[0]}" == "refuse $B: 2 of 3 changed paths refused in the merge of $T "* ]] \
        && printf '%s\n' "$output" | grep -qxF "deny $B A docs/roadmap.md: one of the dev cycle's own files" \
        && printf '%s\n' "$output" | grep -qxF "deny $B A docs/working/questions-archive.md: one of the dev cycle's own files" \
        && [ "$(git rev-parse main)" = "$M" ] || { show; return 1; }
}

@test "--merge --approved refuses an answer other than [1], an open entry, an answer only in the working tree, no entry, and a slug naming another brief, an older tip or the gate (T35, U3a3)" {
    rv; no="Q-001 does not approve this merge"
    approve Q-001 "$S" ANSWERED "Q-001: [2]"; mrg "$B" --expect "$T" --approved Q-001; refused "$no: its answer on the default branch is option 2"
    approve Q-001 "$S" ANSWERED "Q-001: [3]"; mrg "$B" --expect "$T" --approved Q-001; refused "$no: its answer on the default branch is option 3"
    approve Q-001 "$S" ANSWERED "Q-001: merge"; mrg "$B" --expect "$T" --approved Q-001; refused "$no: its answer on the default branch is not read as an option ([1], 1 or keep approve)"
    approve Q-001 "$S" OPEN; mrg "$B" --expect "$T" --approved Q-001; refused "$no: it is not answered on the default branch"
    sed -i 's/OPEN/ANSWERED/' docs/working/questions.md; mrg "$B" --expect "$T" --approved Q-001; refused "$no: it is not answered on the default branch"
    git checkout -q -- docs/working/questions.md
    # The approval binds the heading's prefix; --expect still binds the full tip (i2 security 3).
    mrg "$B" --expect "$M" --approved Q-001
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: the tip of feat/x is $T, not the expected $M" ] && [ "$(git rev-parse main)" = "$M" ] || { show; return 1; }
    mrg "$B" --expect "$T" --approved Q-002; refused "Q-002 does not approve this merge: no such entry in docs/working/questions.md or questions-archive.md on the default branch"
    for s in "merge-2026-10-01-y-${T:0:12}" "merge-2026-10-01-x-${M:0:12}" "merge-gate-2026-10-01-x-${T:0:12}" "merge-2026-10-01-x-${T:0:12} " "$S-x"; do
        approve Q-001 "$s"; mrg "$B" --expect "$T" --approved Q-001; refused "Q-001 approves no merge of this tip: its heading must read \"Q-001 · $S\""
    done
}

@test "--merge --approved needs merge-gate-STEM-SHA12 when a changed path is the gate's own code, the dev-cycle skill included, compared lower-cased (T35, F52, U3a3)" {
    for g in scripts/build-loop.sh Scripts/Lib/x.sh skills/dev-cycle/references/x.md; do
        rv "$g"; G="merge-gate-2026-10-01-x-${T:0:12}"
        mrg "$B" --expect "$T" --approved Q-001
        [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: Q-001 approves no merge of this tip: its heading must read \"Q-001 · $G\" (the merge changes the gate's own code)" ] \
            && [ "$(git rev-parse main)" = "$M" ] || { show; return 1; }
        approve Q-001 "$G"; mrg "$B" --expect "$T" --approved Q-001
        [ "$status" -eq 0 ] && [[ "${lines[0]}" == "merged $B $T "* ]] || { show; return 1; }
        cd "$BATS_TEST_TMPDIR" && rm -rf "$R" && mkdir "$R" && cd "$R" && git init -q -b main && git commit -q --allow-empty -m initial
    done
}

@test "--approved goes with --merge only and takes one question ID (U3a3)" {
    rv
    for args in "--check $B --approved Q-001" "--merge $B --expect $T --approved q-1" "--merge $B --expect $T --approved Q-001 --approved Q-001" "--merge $B --expect $T --approved"; do
        read -ra av <<<"$args"; run --separate-stderr bash "$BL" "${av[@]}"
        [ "$status" -eq 1 ] && [[ "$stderr" == "--approved "* ]] && [ "$(git rev-parse main)" = "$M" ] || { echo "$args"; show; return 1; }
    done
}
