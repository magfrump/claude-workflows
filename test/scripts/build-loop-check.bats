#!/usr/bin/env bats
# @category fast
# Contract tests for the build-loop gate: the reader lib's commit-reading
# import walk (scripts/lib/dev-cycle-read.sh main_imports, isimported) and,
# from U2a3 and U2b, the self-merge floor and scripts/build-loop.sh --check.
# Each test builds a throwaway repo under $BATS_TEST_TMPDIR
# (test/lib/build-loop-fixtures.bash); this repo is untouched.

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() { bl_setup; LIB="$REPO_ROOT/scripts/lib/dev-cycle-read.sh"; }

# imps WALK PATH...: in the fixture repo with main resolved and ROOT_REAL set,
# "walk: ok" or "walk: failed" (main_imports' return; tree always reads ok),
# then "PATH: imported" or "PATH: -" from isimported WALK for each path.
imps() {
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
        resolve_main || true; ROOT_REAL="$(pwd -P)"; w="$1"; shift
        if [[ "$w" != main ]] || main_imports; then echo "walk: ok"; else echo "walk: failed"; fi
        for p in "$@"; do if isimported "$w" "$p"; then echo "$p: imported"; else echo "$p: -"; fi; done' _ "$LIB" "$@"
}
# want PATH WORD: the imps output holds exactly "PATH: WORD" (want walk ok|failed).
want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2"; echo "$output $stderr"; return 1; }; }

@test "main walk: main's instruction files and the checkout's untracked ones start it; a working-tree edit of a tracked one does not count (U2a2)" {
    mkdir -p docs skills/x
    printf 'Rules: @docs/imported.md and @docs/new.md\n' > CLAUDE.md
    printf 'More: @deep.md.\n' > docs/imported.md
    printf 'deep\n' > docs/deep.md
    printf 'See **@ref.md**\n' > skills/x/SKILL.md
    commit_all imports
    printf 'Mine: @docs/private.md\n' > CLAUDE.local.md
    printf 'Rules: @docs/wt-only.md\n' > CLAUDE.md
    imps main docs/imported.md Docs/Imported.md docs/deep.md skills/x/ref.md docs/new.md docs/private.md \
        docs/wt-only.md CLAUDE.md docs/guide.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok
    for p in docs/imported.md Docs/Imported.md docs/deep.md skills/x/ref.md docs/new.md docs/private.md; do want "$p" imported; done
    for p in docs/wt-only.md CLAUDE.md docs/guide.md; do want "$p" -; done
}

@test "main walk fails closed when an instruction blob cannot be read or main is not found by name (U2a2)" {
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
    imps main docs/a.md scripts/other.sh
    want walk ok; want docs/a.md imported; want scripts/other.sh -
    # The instruction file's blob is missing from the object store.
    o="$(git rev-parse main:CLAUDE.md)"
    rm ".git/objects/${o:0:2}/${o:2}"
    imps main scripts/other.sh
    want walk failed; want scripts/other.sh imported
    # No default branch found by name: nothing is read, every path is imported.
    git checkout -q -b trunk && git branch -q -D main
    imps main scripts/other.sh
    want walk failed; want scripts/other.sh imported
}

@test "main walk: a name the tree lists twice, or any name holding a newline, fails the walk (U2a2)" {
    # CLAUDE.md imports docs/a.md, and main's docs/ tree lists a.md twice.
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
    a="$(printf 'a\n' | git hash-object -w --stdin)"
    d="$(printf '100644 blob %s\ta.md\n100644 blob %s\ta.md\n' "$a" "$a" | git mktree)"
    t="$(printf '100644 blob %s\tCLAUDE.md\n040000 tree %s\tdocs\n' "$(git rev-parse main:CLAUDE.md)" "$d" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup)"
    imps main scripts/other.sh
    want walk failed; want scripts/other.sh imported
    # A start file listed twice (a symlink first, which git reads), and a plain
    # file listed twice: each fails the walk rather than reading one copy.
    l="$(printf 'x' | git hash-object -w --stdin)" && b="$(printf '@docs/b.md\n' | git hash-object -w --stdin)"
    t="$(printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tAGENTS.md\n' "$l" "$b" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-start)"
    imps main docs/b.md
    want walk failed; want docs/b.md imported
    t="$(printf '100644 blob %s\tAGENTS.md\n100644 blob %s\tz.txt\n100644 blob %s\tz.txt\n' "$a" "$a" "$a" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-other)"
    imps main scripts/other.sh
    want walk failed; want scripts/other.sh imported
    # A name holding a newline is not modelled, so it fails the walk: a plain one,
    # and one shaped so each half looks like an ls-tree record (a forged symlink line).
    n="$(printf '@../docs/d.md\n' | git hash-object -w --stdin)"
    q="$(printf '@../docs/p.md\n' | git hash-object -w --stdin)"
    w="$(printf '100644 blob %s\tAGENTS.md\0' "$n" | git mktree -z)"
    v="$(printf '100644 blob %s\tAGENTS.md\0' "$q" | git mktree -z)"
    t="$({ printf '040000 tree %s\twe\nird\0' "$w"; printf '040000 tree %s\tx\n120000 blob %s\tdocs\0' "$v" "$a"; } | git mktree -z)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m newline)"
    [ "$(git ls-tree -r -z --name-only main | tr -cd '\0' | wc -c)" -eq 2 ]
    imps main docs/d.md docs/p.md
    want walk failed; want docs/d.md imported; want docs/p.md imported
}

@test "main walk follows what Claude Code loads: symlinks, any name main stores, the checkout's files, .claude/rules/, a token ended by a Unicode space (U2a2)" {
    mkdir -p docs .github .claude/rules
    printf 'imports @docs/b.md\n' > real.md
    ln -s real.md CLAUDE.md
    printf 'See @.github/instr.md and @docs/a+b.md and @docs/nb.md\xc2\xa0for and @docs/link.md\n' > AGENTS.md
    printf 'More: @../docs/g.md\n' > .github/instr.md
    printf 'More: @deep.md\n' > docs/a+b.md
    printf 'tgt @t2.md\n' > docs/target.md
    ln -s target.md docs/link.md
    printf 'Style: @../../docs/r.md\n' > .claude/rules/style.md
    printf 'tracked\n' > docs/t.md
    commit_all walks
    # Untracked: a local instruction file importing an untracked note, which imports a tracked file.
    printf 'Mine: @docs/local-notes.md\n' > CLAUDE.local.md
    printf 'Notes: @t.md\n' > docs/local-notes.md
    ps=(real.md docs/b.md docs/g.md docs/deep.md docs/nb.md docs/target.md docs/t2.md docs/r.md docs/local-notes.md docs/t.md)
    imps main "${ps[@]}" docs/other.md
    want walk ok
    for p in "${ps[@]}"; do want "$p" imported; done
    want docs/other.md -
}

@test "main walk refuses the link and name shapes it does not model; a ..x name is followed (U2a2)" {
    mkdir -p docs
    printf 'see @..x.md\n' > AGENTS.md
    printf 'hid @hid.md\n' > ..x.md
    commit_all dotdot
    imps main hid.md ..x.md
    want walk ok; want hid.md imported
    want ..x.md imported
    # An untracked name holding a newline fails the walk.
    mkdir -p .claude/rules && printf 'x\n' > ".claude/rules/zz"$'\n'"docs.md"
    imps main docs/x.md
    want walk failed; want docs/x.md imported
    rm -r .claude
    imps main docs/x.md; want docs/x.md -
    # Symlink text with a trailing newline, an absolute one, or none: the walk fails.
    for text in $'notes.md\n' /etc/hosts ''; do
        a="$(printf 'x\n' | git hash-object -w --stdin)"
        l="$(printf '%s' "$text" | git hash-object -w --stdin)"
        t="$(printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tnotes.md\n' "$l" "$a" | git mktree)"
        git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m "link $text")"
        imps main docs/x.md; want walk failed; want docs/x.md imported
    done
}

@test "isimported answers imported under if when the walk fails or the walk name is unknown; a NUL in an instruction file hides no import (U2a2)" {
    mkdir -p docs
    printf 'see @docs/a.md\0 and @docs/b.md\n' > AGENTS.md
    commit_all nul
    imps main docs/b.md
    want docs/b.md imported
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        if isimported bogus docs/z.md; then echo "bogus: imported"; fi
        o="$(git rev-parse main:AGENTS.md)"; rm ".git/objects/${o:0:2}/${o:2}"
        if isimported main docs/z.md; then echo "failed walk: imported"; fi' _ "$LIB"
    [ "$output" = "bogus: imported
failed walk: imported" ] || { echo "$output $stderr"; return 1; }
}

@test "tree walk shares the token rules: a Unicode space ends a token, a ..x name is followed, a NUL hides no import (U2a2)" {
    mkdir -p docs
    printf 'See @docs/nb.md\xc2\xa0for, @..x.md and @docs/a.md\0 then @docs/b.md\n' > CLAUDE.md
    printf 'hid @docs/hid.md\n' > ..x.md
    commit_all tree
    imps tree docs/nb.md ..x.md docs/hid.md docs/b.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    for p in docs/nb.md ..x.md docs/hid.md docs/b.md; do want "$p" imported; done
    want docs/other.md -
}
