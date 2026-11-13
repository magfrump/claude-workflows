#!/usr/bin/env bats
# @category slow
# scripts/board.sh, the cross-project board's listing (unit 1): fixture repos
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
    [[ "$output" == *"answering from the board is not built yet"* ]]
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
    board "$BOARD" answer
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"takes no arguments yet"* ]]
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
