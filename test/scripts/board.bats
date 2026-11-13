#!/usr/bin/env bats
# @category slow
# scripts/board.sh, the cross-project board's listing (unit 1) and answer
# commit (unit 2, docs/working/research-2026-11-12-host-board-answer-commit.md): fixture repos
# under BATS_TEST_TMPDIR, HOME inside it, the registry from BOARD_REGISTRY, and
# a shim for each network tool that leaves a sentinel, which every case checks
# is absent (H3). Design: docs/working/research-2026-11-12-host-board-listing.md.
bats_require_minimum_version 1.5.0

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    # shellcheck disable=SC2046  # one variable name per line
    unset $(git rev-parse --local-env-vars)
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export HOME="$BATS_TEST_TMPDIR/home" BOARD_REGISTRY="$BATS_TEST_TMPDIR/repos"
    mkdir -p "$HOME"
    export TMPDIR="$BATS_TEST_TMPDIR"
    SENTINEL="$BATS_TEST_TMPDIR/network-called"
    S="$BATS_TEST_TMPDIR/shim"; mkdir -p "$S"
    for b in claude curl wget gh; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\nexit 97\n' "$b" "$SENTINEL" > "$S/$b"; chmod +x "$S/$b"
    done
    export PATH="$S:$PATH"
    BOARD="$REPO_ROOT/scripts/board.sh"
    QS="$REPO_ROOT/scripts/questions.sh"
}

board() {
    run bash "${1:-$BOARD}" "${@:2}"
    [ ! -e "$SENTINEL" ] || { echo "a network tool was called:"; cat "$SENTINEL"; return 1; }
}

commit() { git -C "$1" add -A && git -C "$1" -c user.name=t -c user.email=t@example.invalid commit -qm "${2:-c}"; }

# entry ID SLUG ROUTE STATUS
entry() { printf '\n### %s · %s\n**Needs:** %s · **Opened:** 2026-11-01 · **Status:** %s\n\nWhat now?\n' "$@"; }

# A repo on BRANCH (default main) with a questions doc: Q-001 and Q-002 open
# for the owner, Q-003 ANSWERED but not yet archived, one open watch.
mkrepo() {
    local r="$BATS_TEST_TMPDIR/$1"
    git init -q -b "${2:-main}" "$r"
    ( cd "$r" && bash "$QS" init >/dev/null
      { entry Q-001 pick-a-name 'you: judgment' OPEN; entry Q-002 run-the-paste 'you: terminal' OPEN
        entry Q-003 already-done 'you: judgment' ANSWERED; printf '\nQ-003: [1]\n'; } >> docs/working/questions.md
      w=docs/working/watching.md
      { sed '/^## Closed/,$d' "$w"; entry Q-004 wait-for-release trigger OPEN; printf '\n## Closed\n'; } > "$w.new" && mv "$w.new" "$w"
      bash "$QS" index >/dev/null && bash "$QS" check >/dev/null 2>&1 )
    commit "$r"
    echo "$r" >> "$BOARD_REGISTRY"
}

@test "lists main's open you: entries, the watch count and date, a footer and a run-log line" {
    mkrepo alpha
    board
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"== $BATS_TEST_TMPDIR/alpha"* ]]
    [[ "$output" =~ $'\n'"   main "[0-9]{4}-[0-9]{2}-[0-9]{2}" · 1 open watch"$'\n' ]]
    [[ "$output" == *"Q-001  you: judgment     pick-a-name"* ]]
    [[ "$output" == *"Q-002  you: terminal     run-the-paste"* ]]
    [[ "$output" != *Q-003* && "$output" != *Q-004* ]]
    [[ "$output" == *"1 project, 2 open for you, 0 unreadable or refused; exit 0"* ]]
    [[ "$output" == *"To answer: board.sh answer PROJECT Q-NNN TEXT"* ]]
    run cat "$HOME/.local/state/claude-board/runs.log"
    [[ "$output" =~ ^[0-9-]+T[0-9:]+Z\ projects=1\ open=2\ unreadable=0\ exit=0$ ]]
}

@test "reads main's commit, not the checked-out branch or the working tree" {
    mkrepo alpha
    r="$BATS_TEST_TMPDIR/alpha"
    git -C "$r" checkout -qb feat
    entry Q-005 branch-only 'you: judgment' OPEN >> "$r/docs/working/questions.md"
    ( cd "$r" && bash "$QS" index >/dev/null ); commit "$r"
    entry Q-006 tree-only 'you: judgment' OPEN >> "$r/docs/working/questions.md"
    board
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *Q-001* && "$output" != *Q-005* && "$output" != *Q-006* ]]
}

@test "a repo with no questions doc on main is named, the others still list, and the exit is 1" {
    git init -q -b main "$BATS_TEST_TMPDIR/bare"; echo x > "$BATS_TEST_TMPDIR/bare/f"; commit "$BATS_TEST_TMPDIR/bare"
    # A doc only in the working tree is not on main.
    ( cd "$BATS_TEST_TMPDIR/bare" && bash "$QS" init >/dev/null )
    echo "$BATS_TEST_TMPDIR/bare" >> "$BOARD_REGISTRY"
    mkrepo alpha
    board
    [ "$status" -eq 1 ]
    [[ "$output" == *"== $BATS_TEST_TMPDIR/bare"$'\n'"   no questions doc on main: main has no docs/working/questions.md"* ]]
    [[ "$output" == *Q-001* && "$output" == *"2 projects, 2 open for you, 1 unreadable"* ]]
}

@test "questions.sh check failing makes the repo UNREADABLE with its first refusal line" {
    mkrepo alpha
    printf '\n### Q-9 · Bad Heading\n' >> "$BATS_TEST_TMPDIR/alpha/docs/working/questions.md"; commit "$BATS_TEST_TMPDIR/alpha"
    board
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNREADABLE (questions.sh check: ✗ questions.md: malformed entry heading: ### Q-9 · Bad Heading)"* ]]
    [[ "$output" != *Q-001* ]]
}

@test "an unknown route is refused by name" {
    mkrepo alpha
    entry Q-007 odd-route 'you: someday' OPEN >> "$BATS_TEST_TMPDIR/alpha/docs/working/questions.md"
    ( cd "$BATS_TEST_TMPDIR/alpha" && bash "$QS" index >/dev/null ); commit "$BATS_TEST_TMPDIR/alpha"
    board
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNREADABLE (questions.sh check: ✗ Q-007: invalid route 'you: someday'"* ]]
}

@test "a repo with no main or master by name is refused" {
    mkrepo alpha trunk
    board
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNREADABLE: no branch named main or master"* && "$output" != *Q-001* ]]
}

@test "bad registry lines are named by line number; comments and blank lines are skipped" {
    mkdir "$BATS_TEST_TMPDIR/plain"
    printf '# my projects\n\nrelative/path\n%s\n%s\n' "$BATS_TEST_TMPDIR/missing" "$BATS_TEST_TMPDIR/plain" > "$BOARD_REGISTRY"
    board
    [ "$status" -eq 1 ]
    [[ "$output" == *"REGISTRY LINE 3: not an absolute path: relative/path"* ]]
    [[ "$output" == *"REGISTRY LINE 4: not a directory: $BATS_TEST_TMPDIR/missing"* ]]
    [[ "$output" == *"REGISTRY LINE 5: not a git repository (git: "*"): $BATS_TEST_TMPDIR/plain"* ]]
    [[ "$output" == *"the registry $BOARD_REGISTRY lists no project"* && "$output" != *"LINE 1"* ]]
}

@test "no registry, or questions.sh or the lib missing beside the script, refuses the run" {
    board
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"no registry at $BOARD_REGISTRY"* ]]
    mkrepo alpha
    for a in answer "answer alpha Q-001" "list alpha Q-001 x"; do
        # shellcheck disable=SC2086  # one argument per word
        board "$BOARD" $a
        [ "$status" -eq 2 ] && [[ "$output" == *"usage: board.sh, or board.sh answer PROJECT Q-NNN TEXT"* ]] || { echo "$output"; false; }
    done
    board "$BOARD" answer alpha Q1 x
    [ "$status" -eq 2 ] && [[ "$output" == *"not a question ID (Q- and digits): Q1"* ]] || { echo "$output"; false; }
    for gone in questions.sh lib/dev-cycle-read.sh; do
        c="$BATS_TEST_TMPDIR/copy-${gone%%/*}"; mkdir -p "$c/lib"
        cp "$BOARD" "$QS" "$c/"; cp "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" "$c/lib/"; rm "$c/$gone"
        board "$c/board.sh"
        [ "$status" -eq 2 ] && [[ "$output" == *"refusing to run: $c/$gone is missing"* ]] || { echo "$output"; false; }
    done
}

@test "board.sh calls no LLM and no network tool (the no-LLM guard is armed)" {
    run grep -nE -e '^[^#]*(^|[;&|( ])(claude|curl|wget|gh)( |$)' -e 'claude_headless_flags' -- "$BOARD"
    [ "$status" -eq 1 ] && [ -z "$output" ] || { echo "$output"; false; }
    printf 'x=1; curl https://example.invalid\n' > "$BATS_TEST_TMPDIR/armed"
    run grep -nE -e '^[^#]*(^|[;&|( ])(claude|curl|wget|gh)( |$)' -- "$BATS_TEST_TMPDIR/armed"
    [ "$status" -eq 0 ]
    mkrepo alpha
    board
    [ "$status" -eq 0 ]
}

@test "an entry check_answer cannot read makes the repo UNREADABLE, never empty" {
    mkrepo alpha
    printf '\n```\nnever closed\n' >> "$BATS_TEST_TMPDIR/alpha/docs/working/questions.md"; commit "$BATS_TEST_TMPDIR/alpha"
    board
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"UNREADABLE Q-001 (check_answer: skip Q-001: the code fence opened at line"* ]]
}

@test "the run log failing makes the exit 1, and the footer says so" {
    mkrepo alpha
    mkdir -p "$HOME/.local/state"; : > "$HOME/.local/state/claude-board"
    board
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    # Two streams through two scrubs: their order in $output is not fixed.
    [[ "$output" == *"could not append to $HOME/.local/state/claude-board/runs.log"* ]]
    [[ "$output" == *"unreadable or refused; exit 1"* ]]
}

@test "repo config that runs commands never fires, and repo text is scrubbed (installed as executable)" {
    [ -x "$BOARD" ]
    mkrepo alpha
    hit="$BATS_TEST_TMPDIR/config-ran"; printf '#!/bin/sh\ntouch "%s"\n' "$hit" > "$BATS_TEST_TMPDIR/evil"; chmod +x "$BATS_TEST_TMPDIR/evil"
    for k in core.fsmonitor core.pager pager.log gpg.program core.hooksPath; do git -C "$BATS_TEST_TMPDIR/alpha" config "$k" "$BATS_TEST_TMPDIR/evil"; done
    git -C "$BATS_TEST_TMPDIR/alpha" config log.showSignature true
    # Main's tip carries a gpgsig header, so an unhardened `git log` runs gpg.program.
    a="$BATS_TEST_TMPDIR/alpha"; tree="$(git -C "$a" rev-parse 'HEAD^{tree}')"
    sig="$(printf 'tree %s\nparent %s\nauthor t <t@e> 1700000000 +0000\ncommitter t <t@e> 1700000000 +0000\ngpgsig -----BEGIN PGP SIGNATURE-----\n \n abc\n -----END PGP SIGNATURE-----\n\nsigned\n' "$tree" "$(git -C "$a" rev-parse HEAD)" | git -C "$a" hash-object -t commit -w --stdin)"
    git -C "$a" update-ref refs/heads/main "$sig"
    git -C "$a" log -1 --format=%cd >/dev/null 2>&1 || true
    [ -e "$hit" ]; rm -f "$hit"   # the positive control: the planted config does fire unhardened
    mkrepo beta
    printf '\n### Q-8 \033]0;owned\007x\n' >> "$BATS_TEST_TMPDIR/beta/docs/working/questions.md"; commit "$BATS_TEST_TMPDIR/beta"
    run "$BOARD"
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *Q-001* && "$output" == *"malformed entry heading: ### Q-8 ]0;ownedx"* ]]
    [[ "$output" != *$'\e'* && "$output" != *$'\a'* ]]
    [ ! -e "$hit" ] && [ ! -e "$SENTINEL" ]
}

# ---- unit 2: board.sh answer, main not checked out (case c1) ----

# offmain NAME: repo NAME (mkrepo) with main checked out nowhere, and the
# owner's identity in a global config the board reads before it hardens.
offmain() {
    mkrepo "$1"; git -C "$BATS_TEST_TMPDIR/$1" checkout -q -b work
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL EMAIL
    export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig"
    printf '[user]\n\tname = Owner\n\temail = owner@example.invalid\n' > "$GIT_CONFIG_GLOBAL"
}
# ans REPO ARGS...: board.sh answer REPO ARGS..., main's commit kept in BEFORE.
ans() { BEFORE="$(git -C "$BATS_TEST_TMPDIR/$1" rev-parse main)"; board "$BOARD" answer "$@"; }
# refused REPO WHY: not written, the reason and the line printed, main unchanged (H2).
refused() {
    [ "$status" -eq 1 ] && [[ "$output" == *"NOT WRITTEN to $1: $2"*"Paste this into that repo's session instead:"$'\n'"Q-0"* ]] \
        && [ "$(git -C "$BATS_TEST_TMPDIR/$1" rev-parse main)" = "$BEFORE" ] || { echo "want: $2"; echo "$output"; false; }
}

@test "answer writes one answers-class commit on main that the cycle's readers read" {
    offmain alpha; a="$BATS_TEST_TMPDIR/alpha"
    ans alpha Q-001 '[1] — keep it'
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    day="$(date +%Y-%m-%d)"
    [[ "$output" == *"WRITTEN to $a: Q-001 · pick-a-name on main at "*$'\n'"Q-001: [1] — keep it (owner, board $day)"$'\n'"The cycle's reader reads it as keep."* ]]
    [ "$(git -C "$a" rev-parse main~1)" = "$BEFORE" ]
    [ "$(git -C "$a" log -1 --format='%an <%ae>|%cn|%s' main)" = "Owner <owner@example.invalid>|Owner|docs(questions): answer Q-001 from the board" ]
    # Exactly the two lines; the checked-out branch and working tree untouched.
    run git -C "$a" diff -U0 "$BEFORE" main
    [[ "$output" == *$'\n''-**Needs:** you: judgment · **Opened:** 2026-11-01 · **Status:** OPEN'$'\n''+**Needs:** you: judgment · **Opened:** 2026-11-01 · **Status:** ANSWERED'$'\n'"+Q-001: [1] — keep it (owner, board $day)" ]] || { echo "$output"; false; }
    [ "$(git -C "$a" diff --numstat "$BEFORE" main)" = "2	1	docs/working/questions.md" ]
    [ "$(git -C "$a" symbolic-ref HEAD)" = refs/heads/work ] && [ -z "$(git -C "$a" status --porcelain)" ]
    # The cycle's view: check_answer on main, and --main-log's answers class.
    run bash -c 'cd "$1" && source "$2/scripts/lib/dev-cycle-read.sh" && resolve_main && check_answer Q-001' _ "$a" "$REPO_ROOT"
    [ "$output" = "keep Q-001" ] || { echo "$output"; false; }
    run bash -c 'cd "$1" && bash "$2/scripts/build-loop.sh" --main-log "$3"' _ "$a" "$REPO_ROOT" "$BEFORE"
    [[ "$output" == *"answers $(git -C "$a" rev-parse main) docs(questions): answer Q-001 from the board"* ]] || { echo "$output"; false; }
    # The listing no longer shows it; a second answer is refused.
    board
    [[ "$output" != *Q-001* && "$output" == *Q-002* ]] || { echo "$output"; false; }
    ans alpha Q-001 '[2]'; refused alpha "Q-001 is already ANSWERED on main"
    run cat "$HOME/.local/state/claude-board/runs.log"
    [[ "$output" == *" answer Q-001 written"*" answer Q-001 printed"* ]]
}

@test "answer prints the line instead, and moves nothing, for each case it cannot write safely" {
    offmain alpha; a="$BATS_TEST_TMPDIR/alpha"
    ans alpha Q-001 $'two\nlines'; refused alpha "the answer is more than one line"
    ans alpha Q-001 $'bell\a'; refused alpha "the answer is not plain UTF-8 text"
    ans alpha Q-001 '   '; refused alpha "the answer is empty"
    ans alpha Q-099 x; refused alpha "Q-099: no such entry"
    ans alpha Q-003 x; refused alpha "Q-003 is already ANSWERED on main"
    ans alpha Q-004 x; refused alpha "Q-004 is a watch in watching.md"
    board "$BOARD" answer nowhere Q-001 x
    [ "$status" -eq 1 ] && [[ "$output" == *"NOT WRITTEN to nowhere: no registry line is nowhere"* ]] || { echo "$output"; false; }
    GIT_CONFIG_GLOBAL=/dev/null ans alpha Q-001 x; refused alpha "git knows no identity for you"
    # Unit 3's case: main checked out in a worktree.
    git -C "$a" worktree add -q "$BATS_TEST_TMPDIR/wt" main
    ans alpha Q-001 x; refused alpha "main is checked out at $BATS_TEST_TMPDIR/wt, and writing there in place is not built yet (unit 3)"
    git -C "$a" worktree remove "$BATS_TEST_TMPDIR/wt"
    # A worktree rebasing main, or bisecting from it.
    git -C "$a" worktree add -q --detach "$BATS_TEST_TMPDIR/wt2"
    g="$(git -C "$BATS_TEST_TMPDIR/wt2" rev-parse --absolute-git-dir)"
    mkdir "$g/rebase-merge"; echo refs/heads/main > "$g/rebase-merge/head-name"
    ans alpha Q-001 x; refused alpha "a worktree is rebasing main"
    rm -r "$g/rebase-merge"; echo main > "$g/BISECT_START"
    ans alpha Q-001 x; refused alpha "a worktree is bisecting from main"
    rm "$g/BISECT_START"
    # Duplicated and fenced entries, and a CR, each committed to main.
    for k in dup fence cr; do
        git -C "$a" checkout -q main
        case $k in
            dup) entry Q-001 again 'you: judgment' OPEN >> "$a/docs/working/questions.md"; want="UNREADABLE (questions.sh check: ✗ duplicate id: Q-001)" ;;
            fence) printf '\n```\n### Q-005 · fenced\n**Needs:** you: judgment · **Opened:** 2026-11-01 · **Status:** OPEN\n```\n' >> "$a/docs/working/questions.md"; want="Q-005: line 53 of docs/working/questions.md is a question heading inside a code fence" ;;
            cr) printf 'tail\r\n' >> "$a/docs/working/questions.md"; want="docs/working/questions.md holds a carriage return" ;;
        esac
        ( cd "$a" && bash "$QS" index >/dev/null 2>&1 || true ); commit "$a"; git -C "$a" checkout -q work
        ans alpha "$([[ $k == fence ]] && echo Q-005 || echo Q-001)" x; refused alpha "$want"
        git -C "$a" update-ref refs/heads/main main~1
    done
}

@test "a symlink in the git directory refuses the write, and nothing lands through it" {
    for k in reflog heads fanout packed; do
        rm -rf "$BATS_TEST_TMPDIR/alpha" "$BATS_TEST_TMPDIR/out"; : > "$BOARD_REGISTRY"; mkdir "$BATS_TEST_TMPDIR/out"
        offmain alpha; c="$BATS_TEST_TMPDIR/alpha/.git"
        case $k in
            reflog) mv "$c/logs/refs/heads/main" "$BATS_TEST_TMPDIR/out/log"; ln -s "$BATS_TEST_TMPDIR/out/log" "$c/logs/refs/heads/main"; want="logs/refs/heads/main" ;;
            heads) mv "$c/refs/heads" "$BATS_TEST_TMPDIR/out/heads"; ln -s "$BATS_TEST_TMPDIR/out/heads" "$c/refs/heads"; want="refs/heads" ;;
            fanout) mkdir "$BATS_TEST_TMPDIR/out/ab"; ln -s "$BATS_TEST_TMPDIR/out/ab" "$c/objects/ab"; want="objects/ab" ;;
            packed) git -C "$c/.." pack-refs --all; mv "$c/packed-refs" "$BATS_TEST_TMPDIR/out/p"; ln -s "$BATS_TEST_TMPDIR/out/p" "$c/packed-refs"; want="packed-refs" ;;
        esac
        ls -lR "$BATS_TEST_TMPDIR/out" > "$BATS_TEST_TMPDIR/out.before"
        ans alpha Q-001 x; refused alpha "$want in the git directory is a symlink or leaves it"
        ls -lR "$BATS_TEST_TMPDIR/out" | cmp -s - "$BATS_TEST_TMPDIR/out.before" || { echo "$k: a write landed outside"; false; }
    done
}

@test "planted hooks and a local core.hooksPath do not fire on the write" {
    offmain alpha; a="$BATS_TEST_TMPDIR/alpha"; hit="$BATS_TEST_TMPDIR/hook-ran"; hd="$a/.git/hooks"
    mkdir "$BATS_TEST_TMPDIR/hk"
    for h in reference-transaction post-index-change; do
        printf '#!/bin/sh\necho %s >> "%s"\n' "$h" "$hit" > "$hd/$h"; cp "$hd/$h" "$BATS_TEST_TMPDIR/hk/$h"
        chmod +x "$hd/$h" "$BATS_TEST_TMPDIR/hk/$h"
    done
    # The positive controls: unhardened, the board's own plumbing (a ref update,
    # an index write) fires each planted hook, from .git and from core.hooksPath.
    ctl() {
        git -C "$a" update-ref refs/heads/probe main && git -C "$a" update-ref -d refs/heads/probe
        GIT_INDEX_FILE="$BATS_TEST_TMPDIR/ctl-index" git -C "$a" read-tree main
        grep -qx reference-transaction "$hit" && grep -qx post-index-change "$hit" && rm "$hit"
    }
    ctl
    git -C "$a" config core.hooksPath "$BATS_TEST_TMPDIR/hk"; rm "$hd/reference-transaction" "$hd/post-index-change"
    ctl
    ans alpha Q-002 '[1]'
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(git -C "$a" rev-parse main~1)" = "$BEFORE" ] && [ ! -e "$hit" ]
}

@test "a compare-and-swap lost to a racing commit on main refuses and leaves main where the race put it" {
    offmain alpha; a="$BATS_TEST_TMPDIR/alpha"
    # A git shim that moves main just before the board's own update-ref.
    real="$(command -v git)"; g="$BATS_TEST_TMPDIR/gitshim"; mkdir "$g"
    printf '#!/bin/sh\ncase "$*" in *"update-ref -m board: answer"*) "%s" -C "%s" -c user.name=r -c user.email=r@e commit-tree -p main -m race "main^{tree}" | xargs "%s" -C "%s" update-ref refs/heads/main ;; esac\nexec "%s" "$@"\n' \
        "$real" "$a" "$real" "$a" "$real" > "$g/git"; chmod +x "$g/git"
    BEFORE="$(git -C "$a" rev-parse main)"
    PATH="$g:$PATH" board "$BOARD" answer alpha Q-001 '[1]'
    [ "$status" -eq 1 ] && [[ "$output" == *"NOT WRITTEN to alpha: main moved while the board wrote (compare-and-swap lost)"* ]] || { echo "$output"; false; }
    [ "$(git -C "$a" log -1 --format=%s main)" = race ] && [ "$(git -C "$a" rev-parse main~1)" = "$BEFORE" ]
}

@test "repository shapes the checks do not model refuse: a bare HEAD on main, a slash in the branch, a reftable, config hooks" {
    offmain alpha; a="$BATS_TEST_TMPDIR/alpha"
    git -C "$a" config hook.x.command "touch $BATS_TEST_TMPDIR/ran"
    ans alpha Q-001 x; refused alpha "the repository's git config defines hooks (hook.*)"
    git -C "$a" config --unset hook.x.command
    git -C "$a" config extensions.refStorage reftable
    ans alpha Q-001 x; refused alpha "the repository keeps its refs in a reftable"
    git -C "$a" config --unset extensions.refStorage; mkdir "$a/.git/reftable"
    ans alpha Q-001 x; refused alpha "the repository keeps its refs in a reftable"
    rm -r "$a/.git/reftable"
    # origin/HEAD naming dev/main makes that the default branch.
    git -C "$a" branch -q dev/main main; git -C "$a" update-ref refs/remotes/origin/dev/main main
    git -C "$a" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/dev/main
    ans alpha Q-001 x; refused alpha "the branch name dev/main holds a slash"
    : > "$BOARD_REGISTRY"; git clone -q --bare "$a" "$BATS_TEST_TMPDIR/bare.git"; echo "$BATS_TEST_TMPDIR/bare.git" >> "$BOARD_REGISTRY"
    git -C "$BATS_TEST_TMPDIR/bare.git" symbolic-ref HEAD refs/heads/main
    BEFORE="$(git -C "$BATS_TEST_TMPDIR/bare.git" rev-parse main)"; board "$BOARD" answer bare.git Q-001 x; refused bare.git "the bare repository's HEAD names main"
    [ ! -e "$BATS_TEST_TMPDIR/ran" ]
}

@test "an answer with backslashes and quotes is written byte for byte" {
    offmain alpha; a="$BATS_TEST_TMPDIR/alpha"
    ans alpha Q-001 '[2] use C:\temp\n "as is" & $HOME'
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    run git -C "$a" show main:docs/working/questions.md
    [[ "$output" == *$'\n''Q-001: [2] use C:\temp\n "as is" & $HOME (owner, board '* ]] || { echo "$output"; false; }
}
