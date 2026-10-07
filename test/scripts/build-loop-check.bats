#!/usr/bin/env bats
# @category fast
# Contract tests for the build-loop gate: the reader lib's import walks
# (scripts/lib/dev-cycle-read.sh isimported, import_targets, main_imports) and, from U2a4 and U2b, the self-merge floor and build-loop.sh --check.
# Each test builds a throwaway repo under $BATS_TEST_TMPDIR
# (test/lib/build-loop-fixtures.bash); this repo is untouched.

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() { bl_setup; LIB="$REPO_ROOT/scripts/lib/dev-cycle-read.sh"; }

# imps WALK PATH...: in the fixture repo with main resolved and ROOT_REAL set,
# "walk: ok" or "walk: failed" (main_imports' return; tree always reads ok),
# then "PATH: imported" or "PATH: -" from isimported WALK for each path.
imps() {
    # timeout: a walk that never ends (an import cycle it does not stop) fails the test.
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
        resolve_main || true; ROOT_REAL="$(pwd -P)"; w="$1"; shift
        if [[ "$w" != main ]] || main_imports; then echo "walk: ok"; else echo "walk: failed"; fi
        for p in "$@"; do if isimported "$w" "$p"; then echo "$p: imported"; else echo "$p: -"; fi; done' _ "$LIB" "$@"
}
# want PATH WORD: the imps output holds exactly "PATH: WORD" (want walk ok|failed).
want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2"; echo "$output $stderr"; return 1; }; }

@test "tree walk shares the token rules: Unicode spaces end a token, punctuation is read kept and stripped, a ..x name is followed, a NUL hides no import, a cycle ends (U2a2)" {
    mkdir -p docs
    printf 'See @docs/nb.md\xc2\xa0for, @docs/bom.md\xef\xbb\xbfnow, @docs/st.md. @..x.md and @docs/a.md\0 then @docs/b.md\n' > CLAUDE.md
    printf 'hid @docs/hid.md\n' > ..x.md
    printf 'back @../CLAUDE.md, @c.md and @b.md\n' > docs/c.md
    printf 'see @docs/c.md\n' > AGENTS.md
    commit_all tree
    ps=(docs/nb.md docs/bom.md docs/st.md docs/st.md. ..x.md docs/hid.md docs/b.md docs/c.md claude.md)
    imps tree "${ps[@]}" docs/other.md docs/nb.md.
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    for p in "${ps[@]}"; do want "$p" imported; done
    want docs/other.md -; want docs/nb.md. -
}

@test "isimported answers imported under if for a walk name it does not know (U2a2)" {
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        if isimported bogus docs/z.md; then echo "bogus: imported"; fi' _ "$LIB"
    [ "$output" = "bogus: imported" ] || { echo "$output $stderr"; return 1; }
}

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
    # The blob is back: the walk reads again, so the next failure is the name alone.
    printf 'Rules: @docs/a.md\n' | git hash-object -w --stdin >/dev/null
    imps main scripts/other.sh; want walk ok; want scripts/other.sh -
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

@test "main walk follows what Claude Code loads: symlinks, any name main stores, the checkout's files, .claude/rules/ at any depth, a token ended by a Unicode space (U2a2, U2a3)" {
    mkdir -p docs .github .claude/rules pkg/.claude/rules
    printf 'imports @docs/b.md\n' > real.md
    ln -s real.md CLAUDE.md
    printf 'See @.github/instr.md and @docs/a+b.md and @docs/nb.md\xc2\xa0for and @docs/link.md\n' > AGENTS.md
    printf 'More: @../docs/g.md\n' > .github/instr.md
    printf 'More: @deep.md\n' > docs/a+b.md
    printf 'tgt @t2.md\n' > docs/target.md
    ln -s target.md docs/link.md
    printf 'Style: @../../docs/r.md\n' > .claude/rules/style.md
    printf 'Nested: @../../../docs/nested.md and @docs/bom.md\xef\xbb\xbfnow\n' > pkg/.claude/rules/style.md
    printf 'tracked\n' > docs/t.md
    # An executable instruction file and import (100755), and a chain of two links on main.
    chmod +x real.md docs/a+b.md && printf 'c @c3.md\n' > docs/c2.md && ln -s docs/c1.md GEMINI.md && ln -s c2.md docs/c1.md
    commit_all walks
    # Untracked .claude/rules starts, top level and nested; a checkout edit of a tracked import does not count.
    printf 'U: @../../docs/u.md\n' > .claude/rules/mine.md && printf 'U: @../../u2.md\n' > pkg/.claude/rules/x.md && printf 'gone\n' > docs/a+b.md
    # Untracked: a local instruction file importing an untracked note, which imports a tracked file.
    printf 'Mine: @docs/local-notes.md\n' > CLAUDE.local.md
    printf 'Notes: @t.md\n' > docs/local-notes.md
    ps=(docs/c3.md docs/u.md pkg/u2.md real.md docs/b.md docs/g.md docs/deep.md docs/nb.md docs/target.md docs/t2.md docs/r.md docs/local-notes.md docs/t.md docs/nested.md pkg/.claude/rules/docs/bom.md)
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
    # Symlink text with a trailing newline, an absolute one, none, or one leaving the repo: the walk fails.
    for text in $'notes.md\n' /etc/hosts '' ../outside/AGENTS.md; do
        a="$(printf 'x\n' | git hash-object -w --stdin)"
        l="$(printf '%s' "$text" | git hash-object -w --stdin)"
        t="$(printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tnotes.md\n' "$l" "$a" | git mktree)"
        git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m "link $text")"
        imps main docs/x.md; want walk failed; want docs/x.md imported
    done
}

@test "isimported answers imported under if when the walk fails; a NUL in an instruction file hides no import (U2a3)" {
    mkdir -p docs
    printf 'see @docs/a.md\0 and @docs/b.md\n' > AGENTS.md
    commit_all nul
    imps main docs/b.md
    want walk ok; want docs/b.md imported
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        o="$(git rev-parse main:AGENTS.md)"; rm ".git/objects/${o:0:2}/${o:2}"
        if isimported main docs/z.md; then echo "failed walk: imported"; fi' _ "$LIB"
    [ "$output" = "failed walk: imported" ] || { echo "$output $stderr"; return 1; }
}

@test "main walk fails on symlink text holding a NUL, and on a checkout symlink it would read (U2a2 iteration 1 A1)" {
    mkdir -p docs real
    printf 'r\n' > docs/rules.md && printf 'x @docs/y.md\n' > real/x.md
    printf 'see @docs/lt.md and @docs-link/x.md\n' > CLAUDE.md
    ln -s real docs-link
    commit_all base
    # A tracked directory symlink, present in the checkout, that an import passes through.
    imps main docs/rules.md; want walk failed
    git rm -q docs-link && printf 'see @docs/lt.md\n' > CLAUDE.md && commit_all nolink
    imps main docs/rules.md; want walk ok
    # An untracked symlink at a target main lacks; then an untracked symlinked start file.
    ln -s rules.md docs/lt.md
    imps main docs/rules.md; want walk failed; want docs/rules.md imported
    rm docs/lt.md && ln -s docs/rules.md CLAUDE.local.md
    imps main docs/x.md; want walk failed
    # An untracked start file the walk cannot read.
    rm CLAUDE.local.md && printf 'Mine: @docs/x.md\n' > CLAUDE.local.md && chmod 000 CLAUDE.local.md
    imps main docs/x.md; want walk failed; want docs/x.md imported
    # An import of a plain directory reads nothing and is no failure.
    rm -f CLAUDE.local.md && mkdir docs/lt.md
    imps main docs/x.md; want walk ok; want docs/x.md -; rmdir docs/lt.md
    # Symlink text holding a NUL: $(...) would drop it and follow another name.
    l="$(printf 'docs/rules.md\0zzz' | git hash-object -w --stdin)"
    t="$(printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tdocs-rules.md\n' "$l" "$(git rev-parse main:docs/rules.md)" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m nul-link)"
    imps main docs/rules.md; want walk failed; want docs/rules.md imported
}

@test "main walk returns, not exits, when main's tree or the untracked list cannot be listed (U2a2 iteration 1 A2); reads a list past 64 KiB under ulimit -f 0" {
    mkdir -p docs && printf 'see @a.md\n' > docs/CLAUDE.md && commit_all base
    imps main docs/a.md; want walk ok; want docs/a.md imported
    # The docs/ tree object is missing: ls-tree -r fails part-way.
    o="$(git rev-parse main:docs)"; rm ".git/objects/${o:0:2}/${o:2}"
    imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
    # A corrupt index: git ls-files --others fails.
    git update-ref refs/heads/main "$(git commit-tree "$(printf '' | git mktree)" -m empty)"
    printf 'junk' > .git/index
    imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
    # A tr that fails (docs/CLAUDE.md is now an untracked start): the lower-cased list comes back short.
    rm .git/index
    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/tr" && chmod +x "$BATS_TEST_TMPDIR/bin/tr"
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed
    # An import list past 64 KiB with no room for a temp file is read whole (U2a3b I2-C4).
    { for i in $(seq 320); do printf '@docs/%0200d.md\n' "$i"; done; printf '@docs/last.md\n'; } > AGENTS.md && commit_all big
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; ulimit -f 0; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        main_imports && isimported main docs/last.md && echo ok' _ "$LIB"
    [ "$output" = ok ] || { echo "$status $output $stderr"; return 1; }
}

@test "main walk: an upper-case .MD instruction file starts it, tracked or untracked (U2a3)" {
    mkdir -p docs
    printf 'Rules: @docs/up.md\n' > CLAUDE.MD
    commit_all upper
    printf 'Mine: @mine.md\n' > docs/AGENTS.MD
    imps main docs/up.md docs/mine.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/up.md imported; want docs/mine.md imported; want docs/other.md -
}

@test "main walk fails on a dangling checkout link at a target, a directory under a checkout link, and empty link text below the top level (U2a3)" {
    mkdir -p docs sub real/sub.md
    printf 'see @docs/gone.md and @lnk/sub.md\n' > CLAUDE.md
    commit_all base
    imps main docs/x.md; want walk ok; want docs/x.md -
    ln -s missing.md docs/gone.md
    imps main docs/x.md; want walk failed; want docs/x.md imported
    rm docs/gone.md && ln -s real lnk
    imps main docs/x.md; want walk failed; want docs/x.md imported
    rm lnk
    # Empty symlink text in sub/ would name sub/ itself, a plain directory here.
    e="$(printf '' | git hash-object -w --stdin)"
    s="$(printf '120000 blob %s\tAGENTS.md\n' "$e" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$(printf '040000 tree %s\tsub\n' "$s" | git mktree)" -p main -m empty-link)"
    imps main docs/x.md; want walk failed; want docs/x.md imported
}

@test "main walk ends on an import cycle, a self-import and a cycle through an untracked file (U2a3)" {
    mkdir -p docs
    printf 'see @docs/a.md and @CLAUDE.md\n' > CLAUDE.md
    printf 'back @../CLAUDE.md, @a.md and @b.md\n' > docs/a.md
    printf 'again @a.md\n' > docs/b.md
    commit_all cycle
    printf 'Mine: @docs/u.md\n' > CLAUDE.local.md
    printf 'loop @../CLAUDE.local.md and @w.md\n' > docs/u.md
    printf 'last @u.md\n' > docs/w.md
    imps main docs/a.md docs/b.md docs/u.md docs/w.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$status $output $stderr"; return 1; }
    want walk ok; for p in docs/a.md docs/b.md docs/u.md docs/w.md; do want "$p" imported; done; want docs/other.md -
}

@test "main walk fails on an unreadable blob when the caller did not set pipefail (U2a3)" {
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
    o="$(git rev-parse main:CLAUDE.md)"; rm ".git/objects/${o:0:2}/${o:2}"
    run --separate-stderr env LC_ALL=C bash -c 'set -eu; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        if main_imports; then echo "walk: ok"; else echo "walk: failed"; fi
        if isimported main scripts/x.sh; then echo "scripts/x.sh: imported"; fi' _ "$LIB"
    [ "$status" -eq 0 ] && [ "$output" = "walk: failed
scripts/x.sh: imported" ] || { echo "$output $stderr"; return 1; }
}

@test "main walk fails on link text with a .. after a symlink on main or only in the checkout, and on a path main lacks under a link main stores (U2a3 i1 fact-check 11b, i2 security F1)" {
    mkdir -p deep/inner docs
    printf 'evil @secret.md\n' > deep/evil.md && printf 'top\n' > evil.md && printf 'i\n' > deep/inner/i.md
    printf 'see @../hid.md\n' > docs/n.md && printf 'h\n' > hid.md
    ln -s deep/inner ld && ln -s ld/../evil.md CLAUDE.md && ln -s docs/../docs/n.md AGENTS.md
    commit_all dotdot-link
    # The kernel reads deep/evil.md through ld; realpath -s would read evil.md.
    imps main deep/secret.md; want walk failed; want deep/secret.md imported
    rm ld; imps main deep/secret.md; want walk failed; want deep/secret.md imported
    # Link text, then an @ token, through main's ld when the checkout lacks it.
    for how in link token; do
        rm CLAUDE.md && ln -s deep/inner ld
        if [ "$how" = link ]; then ln -s ld/i.md CLAUDE.md; else printf 'see @ld/i.md\n' > CLAUDE.md; fi
        commit_all "$how" && rm ld
        imps main deep/inner/i.md; want walk failed
    done
    # A .. after a plain directory is followed; then a link only the checkout has.
    rm CLAUDE.md && ln -s ld/../evil.md CLAUDE.md && commit_all no-ld
    imps main hid.md docs/n.md deep/secret.md; want walk ok; want hid.md imported; want docs/n.md imported; want deep/secret.md -
    ln -s deep/inner ld; imps main deep/secret.md; want walk failed; want deep/secret.md imported
}

@test "main walk cache: a new main commit or main not found by name walks again; a failed walk stays failed (U2a3 i2 test-strategy G6, G9)" {
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all one
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        w() { if isimported main "$1"; then echo "$1"; else echo -; fi; }
        w docs/b.md; printf "Rules: @docs/b.md\n" > CLAUDE.md; git commit -qam two; resolve_main; w docs/b.md; g="$MAIN_SHA"
        a="$(printf "x\n" | git hash-object -w --stdin)"; t="$(printf "100644 blob %s\tA.md\n100644 blob %s\tA.md\n" "$a" "$a" | git mktree)"
        git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup)"; resolve_main; w x.sh; w x.sh
        git update-ref refs/heads/main "$g"; resolve_main; w x.sh; MAIN_BY_NAME=""; w y.sh' _ "$LIB"
    [ "$status" -eq 0 ] && [ "$output" = "$(printf '%s\n' - docs/b.md x.sh x.sh - y.sh)" ] || { echo "$output $stderr"; return 1; }
}
