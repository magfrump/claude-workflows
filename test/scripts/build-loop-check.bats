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
# "walk: ok" or "walk: failed" (main_imports' or imported_names' return),
# then "PATH: imported" or "PATH: -" from isimported WALK for each path.
imps() {
    # timeout: a walk that never ends (an import cycle it does not stop) fails the test.
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
        resolve_main || true; ROOT_REAL="$(pwd -P)"; w="$1"; shift
        if { [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }; then echo "walk: ok"; else echo "walk: failed"; fi
        for p in "$@"; do if isimported "$w" "$p"; then echo "$p: imported"; else echo "$p: -"; fi; done' _ "$LIB" "$@"
}
# want PATH WORD: the imps output holds exactly "PATH: WORD" (want walk ok|failed).
want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2"; echo "$output $stderr"; return 1; }; }

@test "tree walk shares the token rules: Unicode spaces end a token, punctuation is read kept and stripped, a ..x name is followed, a NUL hides no import, a cycle ends (U2a2)" {
    mkdir -p docs
    # Two NBSPs in one run: the token ends at the first. docs/z.md is imported only after the NUL;
    # gone/ does not exist, and the path is still resolved as written.
    printf 'See @docs/nb.md\xc2\xa0for\xc2\xa0you, @docs/bom.md\xef\xbb\xbfnow, @docs/st.md. @..x.md @gone/../docs/m.md and @docs/a.md\0 then @docs/z.md\n' > CLAUDE.md
    printf 'hid @docs/hid.md\n' > ..x.md
    printf 'back @../CLAUDE.md, @c.md and @b.md\n' > docs/c.md
    printf 'see @docs/c.md\n' > AGENTS.md
    commit_all tree
    # Docs/NB.MD and CLAUDE.md: isimported takes a path in any case.
    ps=(docs/nb.md docs/bom.md docs/st.md docs/st.md. ..x.md docs/hid.md docs/b.md docs/c.md claude.md docs/z.md docs/m.md Docs/NB.MD CLAUDE.md)
    imps tree "${ps[@]}" docs/other.md docs/nb.md. $'docs/nb.md\xc2\xa0for'
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    for p in "${ps[@]}"; do want "$p" imported; done
    # The NBSP ends the token: no name runs on past it (precision; a superset may over-read it).
    want docs/other.md -; want docs/nb.md. -; want $'docs/nb.md\xc2\xa0for' -
}

@test "isimported answers imported under if for a walk name it does not know (U2a2)" {
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        if isimported bogus docs/z.md; then echo "bogus: imported"; fi' _ "$LIB"
    [ "$output" = "bogus: imported" ] || { echo "$output $stderr"; return 1; }
    # Without ROOT_REAL it stops (need_root) for any walk name, before answering.
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main
        if isimported bogus docs/z.md; then echo "bogus: imported"; fi' _ "$LIB"
    [ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"ROOT_REAL is not set"* ]] || { echo "$status $output $stderr"; return 1; }
}

@test "both walks: every Unicode space JavaScript's \\s holds ends a token; SKILL.md starts them; an untracked upper-case .MD starts the tree walk (U2a3b)" {
    mkdir -p docs sub
    # U+00A0, U+1680, U+2000-200A, U+2028, U+2029, U+202F, U+205F, U+3000, U+FEFF as UTF-8.
    sp=('\xc2\xa0' '\xe1\x9a\x80' '\xe2\x80\x80' '\xe2\x80\x81' '\xe2\x80\x82' '\xe2\x80\x83' '\xe2\x80\x84'
        '\xe2\x80\x85' '\xe2\x80\x86' '\xe2\x80\x87' '\xe2\x80\x88' '\xe2\x80\x89' '\xe2\x80\x8a' '\xe2\x80\xa8'
        '\xe2\x80\xa9' '\xe2\x80\xaf' '\xe2\x81\x9f' '\xe3\x80\x80' '\xef\xbb\xbf')
    ps=() ns=()
    for i in "${!sp[@]}"; do printf "@../docs/u$i.md${sp[$i]}x\\n"; ps+=("docs/u$i.md"); ns+=("docs/u$i.md$(printf "${sp[$i]}")x"); done > sub/SKILL.md
    commit_all spaces
    # ns: the names run on past each space. Neither walk reads one (precision, as the
    # title states; a parser that is still a superset may over-read them on purpose).
    imps main "${ps[@]}" docs/other.md "${ns[@]}"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "main: $output $stderr"; return 1; }
    want walk ok; for p in "${ps[@]}"; do want "$p" imported; done; want docs/other.md -
    for p in "${ns[@]}"; do want "$p" -; done
    # An untracked start: the tree walk reads it (the main walk fails closed on it until U2a3c).
    printf 'See @k.md\n' > docs/AGENTS.MD
    imps tree "${ps[@]}" docs/k.md docs/other.md "${ns[@]}"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "tree: $output $stderr"; return 1; }
    want walk ok; for p in "${ps[@]}" docs/k.md; do want "$p" imported; done; want docs/other.md -
    for p in "${ns[@]}"; do want "$p" -; done
}

@test "main walk: main's instruction files start it; a working-tree edit does not count; an untracked start or a checkout file at a path main lacks fails it until U2a3c (U2a2, U2a3 split)" {
    mkdir -p docs skills/x
    printf 'Rules: @docs/imported.md and @docs/new.md\n' > CLAUDE.md
    printf 'More: @deep.md.\n' > docs/imported.md
    printf 'deep\n' > docs/deep.md
    printf 'See **@ref.md**\n' > skills/x/SKILL.md
    commit_all imports
    printf 'Rules: @docs/wt-only.md\n' > CLAUDE.md
    imps main docs/imported.md Docs/Imported.md docs/deep.md skills/x/ref.md docs/new.md docs/wt-only.md CLAUDE.md docs/guide.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok
    for p in docs/imported.md Docs/Imported.md docs/deep.md skills/x/ref.md docs/new.md; do want "$p" imported; done
    for p in docs/wt-only.md CLAUDE.md docs/guide.md; do want "$p" -; done
    printf 'x\n' > docs/new.md; imps main docs/guide.md; want walk failed; want docs/guide.md imported; rm docs/new.md
    printf 'Mine: @docs/private.md\n' > CLAUDE.local.md; imps main docs/guide.md; want walk failed; want docs/guide.md imported
    git add -f CLAUDE.local.md; imps main docs/guide.md; want walk failed; want docs/guide.md imported
}

@test "main walk fails closed when an instruction blob cannot be read or main is not found by name (U2a2)" {
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
    imps main docs/a.md scripts/other.sh; want walk ok; want docs/a.md imported; want scripts/other.sh -
    # The instruction file's blob is missing from the object store.
    o="$(git rev-parse main:CLAUDE.md)"
    rm ".git/objects/${o:0:2}/${o:2}"
    imps main scripts/other.sh; want walk failed; want scripts/other.sh imported
    # The blob is back: the walk reads again, so the next failure is the name alone.
    printf 'Rules: @docs/a.md\n' | git hash-object -w --stdin >/dev/null
    imps main scripts/other.sh; want walk ok; want scripts/other.sh -
    # No default branch found by name: nothing is read, every path is imported.
    git checkout -q -b trunk && git branch -q -D main
    imps main scripts/other.sh; want walk failed; want scripts/other.sh imported
}

@test "main walk: a name the tree lists twice, or any name holding a newline, fails the walk (U2a2)" {
    # CLAUDE.md imports docs/a.md, and main's docs/ tree lists a.md twice.
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
    a="$(printf 'a\n' | git hash-object -w --stdin)"
    d="$(printf '100644 blob %s\ta.md\n100644 blob %s\ta.md\n' "$a" "$a" | git mktree)"
    t="$(printf '100644 blob %s\tCLAUDE.md\n040000 tree %s\tdocs\n' "$(git rev-parse main:CLAUDE.md)" "$d" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup)"
    imps main scripts/other.sh; want walk failed; want scripts/other.sh imported
    # A start file listed twice (a symlink first, which git reads), and a plain
    # file listed twice: each fails the walk rather than reading one copy.
    l="$(printf 'x' | git hash-object -w --stdin)" && b="$(printf '@docs/b.md\n' | git hash-object -w --stdin)"
    t="$(printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tAGENTS.md\n' "$l" "$b" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-start)"; git rm -qf CLAUDE.md  # no index-only start masks the refusals below
    imps main docs/b.md; want walk failed; want docs/b.md imported
    t="$(printf '100644 blob %s\tAGENTS.md\n100644 blob %s\tz.txt\n100644 blob %s\tz.txt\n' "$a" "$a" "$a" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-other)"
    imps main scripts/other.sh; want walk failed; want scripts/other.sh imported
    # A name holding a newline is not modelled, so it fails the walk: a plain one,
    # and one shaped so each half looks like an ls-tree record (a forged symlink line).
    n="$(printf '@../docs/d.md\n' | git hash-object -w --stdin)"
    q="$(printf '@../docs/p.md\n' | git hash-object -w --stdin)"
    w="$(printf '100644 blob %s\tAGENTS.md\0' "$n" | git mktree -z)"
    v="$(printf '100644 blob %s\tAGENTS.md\0' "$q" | git mktree -z)"
    t="$({ printf '040000 tree %s\twe\nird\0' "$w"; printf '040000 tree %s\tx\n120000 blob %s\tdocs\0' "$v" "$a"; } | git mktree -z)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m newline)"
    [ "$(git ls-tree -r -z --name-only main | tr -cd '\0' | wc -c)" -eq 2 ]
    imps main docs/d.md docs/p.md; want walk failed; want docs/d.md imported; want docs/p.md imported
}

@test "main walk follows what Claude Code loads: symlinks, any name main stores, .claude/rules/ at any depth, a token ended by a Unicode space (U2a2, U2a3)" {
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
    # A checkout edit of a tracked import does not count.
    printf 'gone\n' > docs/a+b.md
    ps=(docs/c3.md real.md docs/b.md docs/g.md docs/deep.md docs/nb.md docs/target.md docs/t2.md docs/r.md docs/nested.md pkg/.claude/rules/docs/bom.md)
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
    imps main hid.md ..x.md; want walk ok; want hid.md imported
    want ..x.md imported
    # An untracked name holding a newline fails the walk.
    printf 'x\n' > "zz"$'\n'"CLAUDE.md"
    imps main docs/x.md; want walk failed; want docs/x.md imported
    rm "zz"$'\n'"CLAUDE.md"
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
    imps main docs/b.md; want walk ok; want docs/b.md imported
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        o="$(git rev-parse main:AGENTS.md)"; rm ".git/objects/${o:0:2}/${o:2}"
        if isimported main docs/z.md; then echo "failed walk: imported"; fi' _ "$LIB"
    [ "$output" = "failed walk: imported" ] || { echo "$output $stderr"; return 1; }
}

@test "main walk fails on symlink text holding a NUL, on a checkout symlink at a path main lacks, and on an untracked start (U2a2 iteration 1 A1)" {
    mkdir -p docs real
    printf 'r\n' > docs/rules.md && printf 'x @docs/y.md\n' > real/x.md
    printf 'see @docs/lt.md and @docs-link/x.md\n' > CLAUDE.md
    ln -s real docs-link
    commit_all base
    # An import through a directory link main stores (the parent-link refusal).
    imps main docs/rules.md; want walk failed
    git rm -q docs-link && printf 'see @docs/lt.md\n' > CLAUDE.md && commit_all nolink
    imps main docs/rules.md; want walk ok
    # An untracked symlink at a target main lacks; then an untracked symlinked start file.
    ln -s rules.md docs/lt.md
    imps main docs/rules.md; want walk failed; want docs/rules.md imported
    rm docs/lt.md && ln -s docs/rules.md CLAUDE.local.md
    imps main docs/x.md; want walk failed
    # An untracked start file, unreadable too.
    rm CLAUDE.local.md && printf 'Mine: @docs/x.md\n' > CLAUDE.local.md && chmod 000 CLAUDE.local.md
    imps main docs/x.md; want walk failed; want docs/x.md imported
    # An import of a plain directory reads nothing and is no failure.
    rm -f CLAUDE.local.md && mkdir docs/lt.md
    imps main docs/x.md; want walk ok; want docs/x.md -; rmdir docs/lt.md
    # Symlink text holding a NUL: $(...) would drop it and follow another name.
    l="$(printf 'docs/rules.md\0zzz' | git hash-object -w --stdin)"
    t="$(printf '120000 blob %s\tAGENTS.md\n100644 blob %s\tdocs-rules.md\n' "$l" "$(git rev-parse main:docs/rules.md)" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m nul-link)"; git rm -qf CLAUDE.md  # no index-only start masks the NUL count
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
    # A tr that fails (docs/CLAUDE.md is a tracked start again): the lower-cased list comes back short.
    rm .git/index && commit_all again
    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/tr" && chmod +x "$BATS_TEST_TMPDIR/bin/tr"
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; rm "$BATS_TEST_TMPDIR/bin/tr" && printf '#!/bin/sh\ncase " $* " in *" --cached "*) exit 1;; esac\nexec %s "$@"\n' "$(command -v git)" > "$BATS_TEST_TMPDIR/bin/git" && chmod +x "$BATS_TEST_TMPDIR/bin/git"; PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; rm "$BATS_TEST_TMPDIR/bin/git"  # and a git whose ls-files --cached fails
    # An import list past 64 KiB with no room for a temp file is read whole (U2a3b I2-C4).
    { for i in $(seq 320); do printf '@docs/%0200d.md\n' "$i"; done; printf '@docs/last.md\n'; } > AGENTS.md && commit_all big
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; ulimit -f 0; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        main_imports && isimported main docs/last.md && echo ok' _ "$LIB"
    [ "$output" = ok ] || { echo "$status $output $stderr"; return 1; }
    # Link text past 64 KiB with a .. after main's link l, under ulimit -f 0: the .. check reads it whole (loop 1 C4; XFSZ ignored, so a failed temp write returns, as a full disk does).
    x="$(for i in $(seq 270); do printf '%0250d/../' 0; done)l/../t.md"
    t="$(printf '120000 blob %s\tAGENTS.md\n120000 blob %s\tl\n' "$(printf '%s' "$x" | git hash-object -w --stdin)" "$(printf docs | git hash-object -w --stdin)" | git mktree)"; git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m big-link)"; rm -r docs; git read-tree main
    run --separate-stderr env LC_ALL=C bash -c 'trap "" XFSZ; ulimit -f 0; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"; main_imports || echo failed' _ "$LIB"
    [ "$output" = failed ] || { echo "$status $output $stderr"; return 1; }
}

@test "main walk: an upper-case .MD instruction file starts it; an untracked one fails the walk until U2a3c (U2a3)" {
    mkdir -p docs
    printf 'Rules: @docs/up.md\n' > CLAUDE.MD
    commit_all upper
    imps main docs/up.md docs/other.md; [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/up.md imported; want docs/other.md -
    printf 'Mine: @mine.md\n' > docs/AGENTS.MD
    imps main docs/other.md; want walk failed; want docs/other.md imported
}

@test "main walk fails on a dangling checkout link at a target, a directory under a checkout link, empty link text below the top level, and a path under a gitlink; a gitlink at a start name is skipped (U2a3)" {
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
    git update-ref refs/heads/main "$(git commit-tree "$(printf '040000 tree %s\tsub\n' "$s" | git mktree)" -p main -m empty-link)"; git rm -qf CLAUDE.md  # no index-only start masks the empty-text check
    imps main docs/x.md; want walk failed; want docs/x.md imported
    # An import into a path main stores as a gitlink (sub/ is an empty directory here).
    t="$(printf '100644 blob %s\tCLAUDE.md\n160000 commit %s\tsub\n' "$(printf 'see @sub/x.md\n' | git hash-object -w --stdin)" "$(git rev-parse main)" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink)"; imps main docs/x.md; want walk failed; want docs/x.md imported; t="$(printf '160000 commit %s\tCLAUDE.md\n100644 blob %s\tAGENTS.md\n' "$(git rev-parse main)" "$(printf 'see @docs/x.md\n' | git hash-object -w --stdin)" | git mktree)"; git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink-start)"; imps main docs/x.md; want walk ok; want docs/x.md imported
}

@test "main walk ends on an import cycle and a self-import (U2a3)" {
    mkdir -p docs
    printf 'see @docs/a.md and @CLAUDE.md\n' > CLAUDE.md
    printf 'back @../CLAUDE.md, @a.md and @b.md\n' > docs/a.md
    printf 'again @a.md\n' > docs/b.md
    commit_all cycle
    imps main docs/a.md docs/b.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$status $output $stderr"; return 1; }
    want walk ok; want docs/a.md imported; want docs/b.md imported; want docs/other.md -
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
        imps main deep/inner/i.md; want walk failed; want deep/inner/i.md imported
    done
    # Two levels below a one-letter link main stores.
    rm CLAUDE.md && ln -s deep l && printf 'see @l/inner/i.md\n' > CLAUDE.md && commit_all one-letter && rm l
    imps main deep/inner/i.md; want walk failed; want deep/inner/i.md imported
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

@test "main walk fails on a name main stores as both a directory and a link (U2a3 L2 final fact-check r3 13b)" {
    commit_all base && x() { printf '%s' "$1" | sed 's/../\\x&/g'; }; c="$(printf 'see @l/x.md\n' | git hash-object -w --stdin)"; k="$(printf docs | git hash-object -w --stdin)"
    lt="$(printf '100644 blob %s\tx.md\n' "$(printf 'plain\n' | git hash-object -w --stdin)" | git mktree)"; dt="$(printf '100644 blob %s\tx.md\n' "$(printf '@secret.md\n' | git hash-object -w --stdin)" | git mktree)"
    t="$(printf "100644 CLAUDE.md\0$(x "$c")40000 docs\0$(x "$dt")40000 l\0$(x "$lt")120000 l\0$(x "$k")" | git hash-object -t tree -w --literally --stdin)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m tree-and-link)"; git checkout -qf main; imps main docs/secret.md; want walk failed; want docs/secret.md imported
}

@test "both walks read everything Claude Code reads (a superset): an @ after a Unicode space, Markdown and a code span around a token, ( ) in a name; ~x is over-read, a ~/ name outside the repo dropped; an @ after a link or code span starts another import; a stray <!-- elsewhere does not shift a splice (U2a3b)" {
    mkdir -p docs
    # \x60: a backtick (a code span that closes right after the name). A name
    # holding _ before a code span, <br> or emphasis is still read (my_notes); two
    # NBSPs on a line both become blanks; an HTML block's comment splices a name
    # (sec+ret); an escaped space and an absolute path inside the repo are imports.
    { printf 'See @docs/a.md\xc2\xa0@docs/b.md, | @docs/c.md<br> |, **@docs/d.md**x, @docs/e(f).md, @~g.md and @docs/h.md\0@docs/i.md, @docs/j.md\x60x\x60 and @~/x.md\n'
      printf 'More: @docs/my_notes.md\x60c\x60, | @docs/s_g.md<br> |, @docs/k_l.md**b**, @docs/p.md\xc2\xa0@docs/q.md\xc2\xa0@docs/r.md\n'
      printf '<!-- note --> See @docs/sec<!-- x -->ret.md\n'
      # A link or code span between two @s does not hide the second (Claude Code reads both).
      printf 'Read [@docs/la.md](u)/[@docs/lb.md](v) and @docs/ca.md\x60x\x60@docs/cb.md\n'
      # A stray <!-- in a fence earlier must not pair with a later comment.
      printf '\x60\x60\x60html\nx<!--\n\x60\x60\x60\n<!-- n -->@docs/hid<!-- y -->den.md\n'
      printf 'See @docs/my\\ notes.md and @%s/docs/abs.md\n' "$(pwd -P)"; } > AGENTS.md
    printf 'x\n' > 'docs/my notes.md' && printf 'x\n' > docs/abs.md
    commit_all parser
    ps=(docs/a.md docs/b.md docs/c.md docs/d.md 'docs/e(f).md' '~g.md' docs/h.md docs/i.md docs/j.md
        docs/my_notes.md docs/s_g.md docs/k_l.md docs/p.md docs/q.md docs/r.md docs/secret.md
        docs/la.md docs/lb.md docs/ca.md docs/cb.md docs/hidden.md 'docs/my notes.md' docs/abs.md)
    for w in tree main; do
        imps "$w" "${ps[@]}" docs/other.md '~/x.md'
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; for p in "${ps[@]}"; do want "$p" imported; done; want docs/other.md -; want '~/x.md' -
    done
}

@test "the superset over-reads, pinned: an @ after a letter, a prefix that is a file, a name led by an escaped space; a run that prints past IMPORT_OUT_MAX fails the parser (U2a3b)" {
    # These record the 2026-10-06 over-approximation decision (U2a3b iteration-4
    # gate): Claude Code 2.1.292 reads none of docs/mail.md, docs/pre.md and
    # docs/lead.md (its path filter rejects a name led by a space; emit's trim
    # reads it, L2-i2 fact-check Claim 31b). A parser that is more precise and
    # still a superset may delete these lines on purpose.
    # The code-span and fence cases were already read before the decision.
    mkdir -p docs
    { printf 'Code \x60@docs/span.md\x60 and user@docs/mail.md and @docs/pre.md.bak\n'
      printf '\x60\x60\x60\n@docs/fence.md\n\x60\x60\x60\n'; printf 'See @\\ docs/lead.md\n'; } > AGENTS.md
    for f in span mail pre fence lead; do printf 'x\n' > "docs/$f.md"; done
    commit_all superset
    ps=(docs/span.md docs/mail.md docs/pre.md docs/fence.md docs/lead.md)
    for w in tree main; do
        imps "$w" "${ps[@]}" docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; for p in "${ps[@]}"; do want "$p" imported; done; want docs/other.md -
    done
    # Seven 4200-byte runs after an @: the first run's prefixes alone print past
    # IMPORT_OUT_MAX, so the parser returns 1 (the candidate-work bound, which
    # prints nothing, has its own test).
    for i in 1 2 3 4 5 6 7; do printf '@'; head -c 4200 /dev/zero | tr '\0' x; printf '\n'; done > "$BATS_TEST_TMPDIR/heavy.txt"
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        import_targets "" < "$2" >/dev/null && echo rc=0 || echo "rc=$?"' _ "$LIB" "$BATS_TEST_TMPDIR/heavy.txt"
    [ "$output" = rc=1 ] || { echo "$output $stderr"; return 1; }
}

@test "the main walk reads a linked worktree whose instruction file names @.gitignore: a .git prefix candidate is skipped (U2a3b L2 architecture 1)" {
    mkdir -p notes && printf 'See @.gitignore and @notes/x.md\n' > GEMINI.md && printf 'x\n' > .gitignore && printf 'x\n' > notes/x.md
    commit_all gitprefix
    git worktree add -q --detach "$BATS_TEST_TMPDIR/wt" main && cd "$BATS_TEST_TMPDIR/wt"
    imps main notes/x.md .gitignore docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want notes/x.md imported; want .gitignore imported; want docs/other.md -
}

@test "the main walk fails on a linked worktree whose gitfile holds an @, which Claude Code reads when an instruction file names @.git (U2a3b L2-confirm security F1)" {
    mkdir -p docs && printf 'see @.git\n' > CLAUDE.md && printf 'x\n' > docs/x.md && commit_all gitfile
    # The gitfile names the main checkout's path, so a checkout path holding
    # " @docs/x.md " puts that import in it.
    m="$BATS_TEST_TMPDIR/a @docs/x.md /m"; mkdir -p "${m%/m}" && mv "$PWD" "$m" && cd "$m"
    git worktree add -q --detach "$BATS_TEST_TMPDIR/wt" main && cd "$BATS_TEST_TMPDIR/wt"
    imps main docs/x.md docs/other.md; want walk failed; want docs/x.md imported
    # A gitfile with no @ is skipped, as before.
    cd "$m" && git worktree remove "$BATS_TEST_TMPDIR/wt" && cd .. && mv "$m" "$BATS_TEST_TMPDIR/m2" && cd "$BATS_TEST_TMPDIR/m2"
    git worktree add -q --detach "$BATS_TEST_TMPDIR/wt2" main && cd "$BATS_TEST_TMPDIR/wt2"
    imps main docs/x.md docs/other.md; want walk ok; want docs/x.md -; want docs/other.md -
}

@test "both walks fail once the parser has printed more than IMPORT_OUT_MAX characters in all (U2a3b L2 performance F2)" {
    mkdir -p docs && printf 'see @docs/a.md\n' > AGENTS.md && commit_all base
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
        IMPORT_OUT_MAX=10; imported_names && echo tree ok || echo tree failed; main_imports && echo main ok || echo main failed
        IMPORT_OUT_MAX=4000000; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; imported_names && echo tree ok || echo tree failed; main_imports && echo main ok || echo main failed' _ "$LIB"
    [ "$output" = $'tree failed\nmain failed\ntree ok\nmain ok' ] || { echo "$output $stderr"; return 1; }
}

@test "both walks fail closed when tr fails; the tree walk fails closed when its start listing fails or a start name holds a newline; the parser returns 1 when it cannot read its input (U2a3b)" {
    mkdir -p docs && printf 'see @docs/a.md\n' > AGENTS.md && commit_all base
    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/tr" && chmod +x "$BATS_TEST_TMPDIR/bin/tr"
    for w in tree main; do
        PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps "$w" docs/z.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/z.md imported
    done
    # A grep that fails on the start listing (instruction_names, grep -z) only.
    g="$(command -v grep)" && mkdir -p "$BATS_TEST_TMPDIR/gbin"
    # The shim drains its input first, so the writer never sees a closed pipe (a race that hid a mutant).
    printf '#!/bin/sh\ncase "$1" in -z*) cat >/dev/null; exit 2 ;; esac\nexec %s "$@"\n' "$g" > "$BATS_TEST_TMPDIR/gbin/grep" && chmod +x "$BATS_TEST_TMPDIR/gbin/grep"
    PATH="$BATS_TEST_TMPDIR/gbin:$PATH" imps tree docs/a.md docs/z.md; want walk failed; want docs/z.md imported
    imps tree docs/a.md docs/z.md; want walk ok; want docs/z.md -
    # An untracked start under a directory whose name holds a newline: b/X.md would read as seen.
    s=CLAUDE.md; mkdir -p "a"$'\n'"b" b && printf 'x\n' > "a"$'\n'"b/$s" && printf 'see @../docs/z.md\n' > "b/$s"
    imps tree docs/z.md; want walk failed; want docs/z.md imported
    rm -r "a"$'\n'"b" b
    # The tree walk itself, called twice: the second call returns its cached error.
    # The second call runs with a working tr, so only the cache can fail it.
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"; p="$PATH"
        if import_targets "" < docs; then echo read; else echo failed; fi
        PATH="$2:$p"; if imported_names; then echo walked; else echo "walk failed"; fi
        PATH="$p"; if imported_names; then echo walked; else echo "walk failed"; fi' _ "$LIB" "$BATS_TEST_TMPDIR/bin"
    [ "$output" = "failed
walk failed
walk failed" ] || { echo "$output $stderr"; return 1; }
    # A file past bash's here-string pipe size (64 KiB) with no room for a temp file
    # (ulimit -f 0): the import at its end is still read.
    { head -c 70000 /dev/zero | tr '\0' x; printf '\nsee @docs/big.md\n'; } > "$BATS_TEST_TMPDIR/big.txt"
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; ulimit -f 0; source "$1"; ROOT_REAL="$(pwd -P)"
        import_targets "" < "$2"' _ "$LIB" "$BATS_TEST_TMPDIR/big.txt"
    [ "$status" -eq 0 ] && printf '%s\n' "$output" | grep -qxF docs/big.md || { echo "$status $output $stderr"; return 1; }
    # A corrupt index: git ls-files fails, so the tree walk has no start list.
    printf 'junk' > .git/index
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        if imported_names; then echo walked; else echo "walk failed"; fi
        if isimported tree docs/z.md; then echo "docs/z.md: imported"; fi' _ "$LIB"
    [ "$output" = "walk failed
docs/z.md: imported" ] || { echo "$output $stderr"; return 1; }
}

@test "the walks fail closed past the start list: a parser failure on a file read, a failed lower of an imported or asked path, a failed tracked listing alone (U2a3b)" {
    mkdir -p docs && printf 'see @docs/a.md\n' > AGENTS.md && printf 'x\n' > docs/a.md && commit_all base
    tb="$BATS_TEST_TMPDIR/tb" sb="$BATS_TEST_TMPDIR/sb" gb="$BATS_TEST_TMPDIR/gb" && mkdir -p "$tb" "$sb" "$gb"
    # A tr that fails only when its input holds "trfail", so the start names still lower;
    # a sed that always fails; a git whose bare "ls-files -z" (the tracked half) fails.
    t="$(command -v tr)" && printf '#!/bin/sh\nf="$(mktemp)" || exit 1\ncat > "$f"\nif grep -qa trfail "$f"; then rm -f "$f"; exit 1; fi\n%s "$@" < "$f"; r=$?; rm -f "$f"; exit $r\n' "$t" > "$tb/tr"
    printf '#!/bin/sh\nexit 1\n' > "$sb/sed"
    g="$(command -v git)" && printf '#!/bin/sh\n[ "$#" -eq 2 ] && [ "$1 $2" = "ls-files -z" ] && exit 128\nexec %s "$@"\n' "$g" > "$gb/git"
    chmod +x "$tb/tr" "$sb/sed" "$gb/git"
    # The asked path does not lower: either walk answers imported.
    for w in tree main; do
        PATH="$tb:$PATH" imps "$w" docs/trfail.md docs/z.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/trfail.md imported; want docs/z.md -
    done
    # An imported path does not lower: both walks fail (isimported's second call reads the cache).
    printf 'see @docs/trfail.md and @docs/a.md\n' > AGENTS.md && commit_all trfail
    for w in tree main; do
        PATH="$tb:$PATH" imps "$w" docs/z.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/z.md imported
    done
    # The parser fails on a file the tree walk reads; the error stays cached.
    run --separate-stderr env PATH="$sb:$PATH" LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        if imported_names; then echo walked; else echo "walk failed"; fi
        if imported_names; then echo walked; else echo "walk failed"; fi
        if isimported tree docs/z.md; then echo "docs/z.md: imported"; fi' _ "$LIB"
    [ "$output" = "walk failed
walk failed
docs/z.md: imported" ] || { echo "$output $stderr"; return 1; }
    # The tracked listing fails while the untracked listing works.
    PATH="$gb:$PATH" imps tree docs/a.md docs/z.md; want walk failed; want docs/a.md imported; want docs/z.md imported
}

# The four superset holes the L2 fact-check executed against the Claude Code 2.1.292
# harness (Claim 1). Each FAILS at be94c871 and passes once its hole is closed; a
# deferred hole gets `skip "<its row>"` as its first line, not a deleted assertion.
@test "both walks read an import that leaves the repo and re-enters it through its parent (FAILS at be94c871: L2 fact-check Claim 1 class 1)" {
    mkdir -p docs sub && n="$(basename "$(pwd -P)")"
    # A sibling whose path is as long as the repo's: its docs/sib.md is not the repo's.
    s="${n%?}x"; [[ "$s" != "$n" ]] || s="${n%?}y"
    printf 'See @../%s/docs/re.md and @../%s/docs/sib.md\n' "$n" "$s" > AGENTS.md
    printf 'See @../../%s/docs/sub.md\n' "$n" > sub/CLAUDE.md
    commit_all reentry
    for w in tree main; do
        imps "$w" docs/re.md docs/sub.md docs/other.md docs/sib.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/re.md imported; want docs/sub.md imported; want docs/other.md -; want docs/sib.md -
    done
}

@test "both walks read an absolute import into the repo however it is spelled: //root, /./root, root/../<name> (FAILS at be94c871: L2 fact-check Claim 1 class 2)" {
    mkdir -p docs && r="$(pwd -P)"
    printf 'See @/%s/docs/a1.md, @/.%s/docs/a2.md and @%s/../%s/docs/a3.md\n' "$r" "$r" "$r" "${r##*/}" > AGENTS.md
    commit_all abs
    for w in tree main; do
        imps "$w" docs/a1.md docs/a2.md docs/a3.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; for p in docs/a1.md docs/a2.md docs/a3.md; do want "$p" imported; done; want docs/other.md -
    done
}

@test "both walks resolve an import against a directory whose name holds a backslash, taken literally (FAILS at be94c871: L2 fact-check Claim 1 class 3)" {
    # mawk reads escape sequences in a -v value: dir a\tb became a<TAB>b.
    d='docs/a\tb' && mkdir -p "$d" && printf 'See @z.md\n' > "$d/AGENTS.md"
    commit_all backslash
    for w in tree main; do
        imps "$w" "$d/z.md" docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want "$d/z.md" imported; want docs/other.md -
    done
}

@test "both walks read a name over 4096 bytes that resolves to a short path (FAILS at be94c871: L2 fact-check Claim 1 class 4)" {
    mkdir -p docs
    { printf 'See @'; for i in $(seq 2100); do printf './'; done; printf 'docs/long.md\n'; } > AGENTS.md
    commit_all long
    for w in tree main; do
        imps "$w" docs/long.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/long.md imported; want docs/other.md -
    done
}

@test "both walks read a name an HTML comment block splices from three pieces, an @ between code spans that hold <!-- and -->, and an @./ name; a blank ends every name (U2a3b L2 test-strategy)" {
    # Claude Code 2.1.292 (harness) reads docs/abc.md (HTML block, comments removed),
    # docs/cs.md (text between two code spans) and docs/dot.md; it never reads "docs/a.md x".
    mkdir -p docs
    { printf '<!-- 0 --> @docs/a<!-- 1 -->b<!-- 2 -->c.md\n'; printf 'See \x60<!--\x60 @docs/cs.md \x60-->\x60\n'
      printf 'See @./docs/dot.md and @docs/a.md x, @docs/t.md\tx and @docs/r.md\r\n'; } > AGENTS.md
    printf 'x\n' > 'docs/a.md x'
    commit_all splice3
    for w in tree main; do
        imps "$w" docs/abc.md docs/cs.md docs/dot.md docs/a.md docs/t.md docs/r.md docs/other.md 'docs/a.md x' $'docs/t.md\tx' $'docs/r.md\r'
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; for p in docs/abc.md docs/cs.md docs/dot.md docs/a.md docs/t.md docs/r.md; do want "$p" imported; done
        # Precision, not superset: the false-positive cost the design states (to the first
        # blank; a tab and a CR are blanks too, as in JavaScript's \s).
        want docs/other.md -; want 'docs/a.md x' -; want $'docs/t.md\tx' -; want $'docs/r.md\r' -
    done
}

@test "the parser fails, not stalls, on one line of many HTML comments (FAILS at be94c871: L2 fact-check Claim 18b; a 10 s timeout)" {
    # 320,000 comments in one 2.24 MB line took 27 s with status 0 at be94c871: splice's
    # copying is quadratic and outside the work bound. 124 is timeout's status, not a failure the parser chose.
    { head -c 320000 /dev/zero | sed 's/\x0/<!---->/g'; printf '\n'; } > "$BATS_TEST_TMPDIR/comments.txt"
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        timeout 10 bash -c "source \"\$1\"; ROOT_REAL=\"\$2\"; import_targets \"\" < \"\$3\" >/dev/null" _ "$1" "$ROOT_REAL" "$2"; echo "rc=$?"' _ "$LIB" "$BATS_TEST_TMPDIR/comments.txt"
    [[ "$output" == rc=* && "$output" != rc=0 && "$output" != rc=124 ]] || { echo "$output $stderr"; return 1; }
}

@test "both walks read a name as Claude Code decodes it: an invalid UTF-8 byte is U+FFFD (U2a3b L2 security F1)" {
    mkdir -p docs && printf 'See @docs/\xff.md\n' > AGENTS.md && printf 'see @c.md\n' > docs/$'\xef\xbf\xbd'.md
    commit_all fffd
    for w in tree main; do
        imps "$w" docs/$'\xef\xbf\xbd'.md docs/c.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/$'\xef\xbf\xbd'.md imported; want docs/c.md imported; want docs/other.md -
    done
}

@test "the tree walk reads only the first 4 MiB of a file a candidate names, as Claude Code skips larger files (U2a3b L2 security F2)" {
    mkdir -p docs && printf 'See @big/x.md\n' > AGENTS.md && commit_all base
    # An untracked sparse 300 MB file at the prefix "big": read whole, the walk stalls.
    printf '@docs/early.md\n' > big && truncate -s 300M big
    run --separate-stderr timeout 20 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        imported_names && echo ok || echo failed; isimported tree docs/early.md && echo early' _ "$LIB"
    [ "$output" = $'ok\nearly' ] || { echo "$status $output $stderr"; return 1; }
}

@test "both walks fail closed when python3 fails on text holding a byte above 0x7f (U2a3b L2-i2 test-strategy)" {
    mkdir -p docs && printf 'See @docs/\xff.md and @docs/a.md\n' > AGENTS.md && commit_all py
    S="$BATS_TEST_TMPDIR/py" && mkdir -p "$S" && printf '#!/bin/sh\nexit 1\n' > "$S/python3" && chmod +x "$S/python3"
    for w in tree main; do
        PATH="$S:$PATH" imps "$w" docs/a.md docs/other.md
        want walk failed; want docs/a.md imported; want docs/other.md imported
    done
}

@test "the parser keeps every path below ROOT_REAL /, and returns 1 for an empty ROOT_REAL (U2a3b L2-i2 test-strategy)" {
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL=/
        printf "See @/etc/x.md and @docs/a.md and @../b.md\n" | import_targets sub; echo "rc=$?"
        ROOT_REAL=""; printf "See @docs/a.md\n" | import_targets "" >/dev/null; echo "rc=$?"' _ "$LIB"
    for l in etc/x.md sub/docs/a.md b.md rc=0 rc=1; do printf '%s\n' "$output" | grep -qxF "$l" || { echo "missing $l: $output $stderr"; return 1; }; done
}

@test "both walks read an import whose .. runs past / and re-enters the repo, as Node's path.resolve stops at / (U2a3b L2-i2 test-strategy)" {
    mkdir -p docs && r="$(pwd -P)"
    { printf 'See @'; for i in $(seq 40); do printf '../'; done; printf '%s/docs/up.md\n' "${r#/}"; } > AGENTS.md
    commit_all clamp
    for w in tree main; do
        imps "$w" docs/up.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/up.md imported; want docs/other.md -
    done
}

@test "IMPORT_OUT_MAX bounds what the whole walk prints, not each file, and a walk that prints exactly the limit passes (U2a3b L2-i2 test-strategy)" {
    # import_targets prints 13 bytes for each file (a, a., a.m, a.md; 39 in all). Three
    # files, not two: the parser gets what is left (IMPORT_LEFT), and a budget that
    # restarted at each file would look walk-wide until the third.
    printf 'see @a.md\n' > AGENTS.md && printf 'see @b.md\n' > GEMINI.md && printf 'see @c.md\n' > CLAUDE.md && commit_all three
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
        for m in 20 38 39; do IMPORT_OUT_MAX=$m; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""
            imported_names && echo "$m tree ok" || echo "$m tree failed"; main_imports && echo "$m main ok" || echo "$m main failed"; done' _ "$LIB"
    [ "$output" = $'20 tree failed\n20 main failed\n38 tree failed\n38 main failed\n39 tree ok\n39 main ok' ] || { echo "$output $stderr"; return 1; }
}

@test "the tree walk reads a file of exactly 4 MiB to its last byte, as Claude Code loads it (U2a3b L2-i2 test-strategy)" {
    mkdir -p docs && printf 'See @big/x.md\n' > AGENTS.md && commit_all base
    # 4194304 bytes in all, the last 14 an import with no newline after it.
    truncate -s $((4194304 - 14)) big && printf '\n@docs/late.md' >> big && [ "$(wc -c < big)" -eq 4194304 ]
    run --separate-stderr timeout 20 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        imported_names && echo ok || echo failed; isimported tree docs/late.md && echo late' _ "$LIB"
    [ "$output" = $'ok\nlate' ] || { echo "$status $output $stderr"; return 1; }
}

@test "both walks read an @~/ import into a repo under HOME, as Claude Code joins ~/ to the home directory (FAILS at 98e3b1df: L2-i2 fact-check Claim 9)" {
    mkdir -p docs && printf 'See @~/%s/docs/home.md\n' "$(basename "$(pwd -P)")" > AGENTS.md && commit_all home
    h="$(cd .. && pwd -P)"
    for w in tree main; do
        HOME="$h" imps "$w" docs/home.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/home.md imported; want docs/other.md -
    done
}

@test "the main walk fails closed on an import of a file under .git, whose own imports it cannot read (U2a3b L2-i2 security F2)" {
    # Only a bare .git component is skipped: .git/notes.md is a checkout file main lacks, so the walk fails
    # rather than drop docs/t.md, which .git/notes.md imports.
    mkdir -p docs && printf 'See @.git/notes.md and @sub/../.git/info/n.md\n' > CLAUDE.md && commit_all gitdir
    printf 'see @../docs/t.md\n' > .git/notes.md
    imps main docs/t.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk failed; want docs/t.md imported
}

@test "both walks read an @~/ import when HOME is a symlink to the repo's parent: its real spelling is read too (U2a3b L2-i2 security F1)" {
    mkdir -p docs && printf 'See @~/%s/docs/home.md\n' "$(basename "$(pwd -P)")" > AGENTS.md && commit_all home
    ln -s "$(cd .. && pwd -P)" "$BATS_TEST_TMPDIR/homelink"
    for w in tree main; do
        HOME="$BATS_TEST_TMPDIR/homelink" imps "$w" docs/home.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/home.md imported; want docs/other.md -
    done
}

@test "the parser fails on a ~/ name when the home is relative, and reads other names without one (U2a3b L2-i2 security F1)" {
    run --separate-stderr env LC_ALL=C HOME=rel bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        printf "see @docs/a.md\n" | import_targets "" >/dev/null && echo plain=0 || echo "plain=$?"
        printf "see @~/x/docs/a.md\n" | import_targets "" >/dev/null && echo tilde=0 || echo "tilde=$?"' _ "$LIB"
    [ "$output" = $'plain=0\ntilde=1' ] || { echo "$output $stderr"; return 1; }
}

@test "the parser itself stops once it has printed more than IMPORT_LEFT allows (U2a3b L2-i2 performance F2)" {
    # see @a.md prints a, a., a.m, a.md: 13 with the newlines between them.
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        for n in 12 13; do printf "see @a.md\n" | IMPORT_LEFT=$n import_targets "" >/dev/null && echo "$n=0" || echo "$n=$?"; done' _ "$LIB"
    [ "$output" = $'12=1\n13=0' ] || { echo "$output $stderr"; return 1; }
}

@test "the parser fails, not stalls, when one name's candidates pass its work bound though it prints nothing (U2a3b L2-final test-strategy)" {
    # 10,100 escaped spaces after one @: every candidate trims to nothing, so the
    # print budget (IMPORT_LEFT) never runs, while the candidates' lengths sum to
    # about 51 million. About 0.5 s.
    { printf 'See @'; for i in $(seq 10100); do printf '\\ '; done; printf '\n'; } > "$BATS_TEST_TMPDIR/blank.txt"
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        import_targets "" < "$2"; echo "rc=$?"' _ "$LIB" "$BATS_TEST_TMPDIR/blank.txt"
    [ "$output" = rc=1 ] || { echo "$output $stderr"; return 1; }
}

@test "the main walk passes a nested .git directory as a plain directory, but fails closed on a nested .git file, which Claude Code reads (U2a3b L2-final security F2, test-strategy F2)" {
    # A nested repository's .git directory names no file: a prefix of @n/.github/x.md passes the plain-directory check.
    mkdir -p notes n && printf 'See @n/.github/x.md and @notes/x.md\n' > GEMINI.md && printf 'x\n' > notes/x.md && printf 'x\n' > n/keep
    commit_all nested
    mkdir n/.git
    imps main notes/x.md n/.github/x.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want notes/x.md imported; want n/.github/x.md imported; want docs/other.md -
    # A .git file (a nested worktree's gitfile, or any file so named) is a file main lacks:
    # Claude Code follows its imports, so the walk fails rather than drop docs/e.md.
    rmdir n/.git && printf 'see @../docs/e.md\n' > n/.git
    imps main docs/e.md; want walk failed; want docs/e.md imported
    # The tree walk reads that file as Claude Code does, and follows its import.
    imps tree docs/e.md docs/other.md; want walk ok; want docs/e.md imported; want docs/other.md -
}

@test "both walks read ~/ against the passwd entry's home when HOME is empty or unset (U2a3b L2-final test-strategy)" {
    # Claude Code's runtime (Bun) falls back to the passwd entry for an empty HOME as
    # for an unset one (L2-final fact-check r1 22a). A getent shim makes the repo's
    # parent that entry's home.
    mkdir -p docs && printf 'See @~/%s/docs/home.md\n' "$(basename "$(pwd -P)")" > AGENTS.md && commit_all home
    G="$BATS_TEST_TMPDIR/getent" && mkdir -p "$G" && printf '#!/bin/sh\necho "u:x:0:0::%s:/bin/sh"\n' "$(cd .. && pwd -P)" > "$G/getent" && chmod +x "$G/getent"
    oh="$HOME"
    for w in tree main; do
        HOME="" PATH="$G:$PATH" imps "$w" docs/home.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w empty: $output $stderr"; return 1; }
        want walk ok; want docs/home.md imported; want docs/other.md -
        unset HOME; PATH="$G:$PATH" imps "$w" docs/home.md docs/other.md; export HOME="$oh"
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w unset: $output $stderr"; return 1; }
        want walk ok; want docs/home.md imported; want docs/other.md -
    done
}

@test "both walks read well-formed UTF-8 without python3, which only text holding an invalid sequence needs (U2a3b L2-final test-strategy)" {
    mkdir -p docs && printf 'Voil\xc3\xa0: @docs/caf\xc3\xa9.md and @docs/a.md\n' > AGENTS.md && commit_all utf8
    S="$BATS_TEST_TMPDIR/py" && mkdir -p "$S" && printf '#!/bin/sh\nexit 1\n' > "$S/python3" && chmod +x "$S/python3"
    for w in tree main; do
        PATH="$S:$PATH" imps "$w" $'docs/caf\xc3\xa9.md' docs/a.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want $'docs/caf\xc3\xa9.md' imported; want docs/a.md imported; want docs/other.md -
    done
}

@test "the tree walk fails closed on an imported file it cannot read, when the caller did not set pipefail (U2a3b L2-final test-strategy)" {
    # As the main walk's unreadable-blob test: head fails, and the walk must not read that as no imports.
    mkdir -p docs && printf 'see @docs/a.md\n' > AGENTS.md && printf 'see @b.md\n' > docs/a.md && commit_all base
    chmod 000 docs/a.md
    run --separate-stderr env LC_ALL=C bash -c 'set -eu; source "$1"; ROOT_REAL="$(pwd -P)"
        if imported_names; then echo "walk: ok"; else echo "walk: failed"; fi
        if isimported tree docs/b.md; then echo "docs/b.md: imported"; fi' _ "$LIB"
    chmod 644 docs/a.md
    [ "$status" -eq 0 ] && [ "$output" = $'walk: failed\ndocs/b.md: imported' ] || { echo "$status $output $stderr"; return 1; }
}

@test "the parser charges each resolved spelling to its work bound, so a deep file of many short names fails, not stalls (U2a3b L2-final performance F1)" {
    # 400,000 copies of @a, from a file 50 directories down: each resolves to a path of
    # about 135 characters under bats' temp root (more under a longer one), past the
    # 50,000,000 bound in all, though the name itself is one character (performance
    # L2-final F1 measured 22 s and success on a 4 MiB file of @a before the charge).
    d="$(printf 'd/%.0s' $(seq 50))" && d="${d%/}"
    { head -c 400000 /dev/zero | sed 's/\x0/@a /g'; printf '\n'; } > "$BATS_TEST_TMPDIR/many.txt"
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        timeout 60 bash -c "source \"\$1\"; ROOT_REAL=\"\$2\"; import_targets \"\$3\" < \"\$4\" >/dev/null" _ "$1" "$ROOT_REAL" "$2" "$3"; echo "rc=$?"' _ "$LIB" "$d" "$BATS_TEST_TMPDIR/many.txt"
    [ "$output" = rc=1 ] || { echo "$output $stderr"; return 1; }
}

@test "the parser reads the U+FFFD spelling of each ill-formed class the UTF-8 gate must send to python3: overlongs, a surrogate, past U+10FFFF (U2a3b L2-confirm test-strategy)" {
    # One line per call: the gate forks python3 for the whole text when any line is
    # ill-formed, so each class must be the only one in its text to pin UTF8_WELL_FORMED's
    # range for it. Counts are python3's "replace" decoding (one U+FFFD per maximal
    # subpart, as WHATWG decoders also do).
    seqs=($'\xc0\x80' $'\xc1\xbf' $'\xe0\x80\x80' $'\xed\xa0\x80' $'\xf0\x80\x80\x80' $'\xf4\x90\x80\x80') ns=(2 2 3 3 4 4)
    for i in "${!seqs[@]}"; do printf '@d%s%s.md\n' "$i" "${seqs[$i]}"; done > "$BATS_TEST_TMPDIR/ill.txt"
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        while IFS= read -r l; do printf "%s\n" "$l" | import_targets ""; done < "$2"' _ "$LIB" "$BATS_TEST_TMPDIR/ill.txt"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$status $stderr"; return 1; }
    for i in "${!seqs[@]}"; do
        w="d$i"; for ((k = 0; k < ns[i]; k++)); do w+=$'\xef\xbf\xbd'; done
        printf '%s\n' "$output" | grep -qxF "$w.md" || { echo "missing: $w.md"; return 1; }
    done
}
