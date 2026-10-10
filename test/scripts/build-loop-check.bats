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
# T_READER_ROOTS and T_READER_HOMES, when set, become the caller's
# IMPORT_READER_ROOTS and IMPORT_READER_HOMES after the lib is sourced (it clears them);
# T_SETTINGS=1 sets them as the scripts do, with reader_settings. T_MANAGED
# becomes IMPORT_MANAGED_DIR (by default a path that does not exist).
imps() {
    # timeout: a walk that never ends (an import cycle it does not stop) fails the test.
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
        [[ -z "${T_READER_ROOTS+set}" ]] || IMPORT_READER_ROOTS="$T_READER_ROOTS"
        [[ -z "${T_READER_HOMES+set}" ]] || IMPORT_READER_HOMES="$T_READER_HOMES"
        IMPORT_MANAGED_DIR="${T_MANAGED:-/nonexistent/managed}"  # the real /etc/claude-code stays out
        resolve_main || true; [[ -z "${T_SETTINGS:-}" ]] || reader_settings; ROOT_REAL="$(pwd -P)"; w="$1"; shift
        if { [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }; then echo "walk: ok"; else echo "walk: failed"; fi
        for p in "$@"; do if isimported "$w" "$p"; then echo "$p: imported"; else echo "$p: -"; fi; done' _ "$LIB" "$@"
}
# want PATH WORD: the imps output holds exactly "PATH: WORD" (want walk ok|failed).
want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2"; echo "$output $stderr"; return 1; }; }
# floors STEM STATUS PATH...: the lib's floor for each path, as imps runs the
# walks; one "PATH: WHY" or "PATH: -" line each, read with want.
floors() {
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
        resolve_main || true; [[ -z "${T_SETTINGS:-}" ]] || reader_settings; ROOT_REAL="$(pwd -P)"; s="$1"; st="$2"; shift 2
        for p in "$@"; do if floor "$p" "$s" "$st"; then echo "$p: $FLOOR_WHY"; else echo "$p: -"; fi; done' _ "$LIB" "$@"
}
INSTR="an instruction or prompt file, which sessions load from the checkout"
DOT="a dotfile or a path under a dot-directory"
GATE="the gate's own code, which lands only through a merge-gate- review entry"
IMP="an instruction or prompt file (on the default branch, or only in the checkout) imports it with @ (directly or through another import)"
WALKFAIL="the default branch's instruction files could not be walked for @ imports"
OWN="one of the dev cycle's own files"
USER="the user's constraints doc, which every loop prompt carries"
REC="a record later runs read as truth"
WORK="a working file that is not this brief's own (they carry its full stem)"
REV="a review record (only an added review named STEM.md or NAME-STEM.md lands)"

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
    # An untracked start: the tree walk reads it (the main walk's checkout phase does too; the next test pins it).
    printf 'See @k.md\n' > docs/AGENTS.MD
    imps tree "${ps[@]}" docs/k.md docs/other.md "${ns[@]}"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "tree: $output $stderr"; return 1; }
    want walk ok; for p in "${ps[@]}" docs/k.md; do want "$p" imported; done; want docs/other.md -
    for p in "${ns[@]}"; do want "$p" -; done
}

@test "main walk: main's instruction files start it; a working-tree edit does not count; phase 2 walks an untracked, ignored or index-only start and a checkout file at a path main lacks (U2a2, U2a3, U2a3c)" {
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
    printf 'see @guide.md\n' > docs/new.md; imps main docs/guide.md docs/other.md; want walk ok; want docs/guide.md imported; want docs/other.md -; rm docs/new.md
    printf 'Mine: @docs/private.md\n' > CLAUDE.local.md; imps main docs/private.md docs/guide.md; want walk ok; want docs/private.md imported; want docs/guide.md -
    printf 'CLAUDE.local.md\n' > .gitignore; imps main docs/private.md; want walk ok; want docs/private.md imported
    git add -f CLAUDE.local.md; imps main docs/private.md; want walk ok; want docs/private.md imported
    rm CLAUDE.local.md; imps main docs/private.md; want walk ok; want docs/private.md -  # an index-only start deleted from the checkout loads nothing
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
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-start)"
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

@test "main walk follows what Claude Code loads: symlinks, any name main stores, the checkout's files, .claude/rules/ at any depth, a token ended by a Unicode space (U2a2, U2a3, U2a3c)" {
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
    # Untracked .claude/rules starts, top level and nested; a local instruction file importing an untracked note, which imports a tracked file; a checkout edit of a tracked import does not count.
    printf 'U: @../../docs/u.md\n' > .claude/rules/mine.md && printf 'U: @../../u2.md\n' > pkg/.claude/rules/x.md && printf 'gone\n' > docs/a+b.md
    printf 'Mine: @docs/local-notes.md\n' > CLAUDE.local.md && printf 'Notes: @t.md\n' > docs/local-notes.md
    ps=(docs/u.md pkg/u2.md docs/local-notes.md docs/t.md docs/c3.md real.md docs/b.md docs/g.md docs/deep.md docs/nb.md docs/target.md docs/t2.md docs/r.md docs/nested.md pkg/.claude/rules/docs/bom.md)
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

@test "main walk fails on symlink text holding a NUL, on a checkout symlink at a path main lacks, and on an untracked start that is a symlink or unreadable (U2a2 iteration 1 A1, U2a3c)" {
    mkdir -p docs real
    printf 'r\n' > docs/rules.md && printf 'x @docs/y.md\n' > real/x.md
    printf 'see @docs/lt.md and @docs-link/x.md\n' > CLAUDE.md
    ln -s real docs-link
    commit_all base
    # An import through a directory link main stores: the parent-link refusal, and the checkout's docs-link fails the plain-directory check too; tests 12 and 15 pin each alone.
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
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m nul-link)"
    imps main docs/rules.md; want walk failed; want docs/rules.md imported
}

@test "main walk returns, not exits, when main's tree or the checkout's .md list cannot be listed (U2a2 iteration 1 A2); reads a list past 64 KiB under ulimit -f 0" {
    mkdir -p docs && printf 'see @a.md\n' > docs/CLAUDE.md && commit_all base
    imps main docs/a.md; want walk ok; want docs/a.md imported
    # The docs/ tree object is missing: ls-tree -r fails part-way.
    o="$(git rev-parse main:docs)"; rm ".git/objects/${o:0:2}/${o:2}"
    imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
    # A corrupt index: git ls-files --cached --others fails.
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

@test "main walk: an upper-case .MD instruction file starts it, tracked or untracked; an upper-case token matches any case (U2a3, U2a3c)" {
    mkdir -p docs
    printf 'Rules: @docs/up.md and @Docs/Mixed.md\n' > CLAUDE.MD
    commit_all upper
    imps main docs/up.md docs/other.md docs/mixed.md; [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/up.md imported; want docs/mixed.md imported; want docs/other.md -
    printf 'Mine: @mine.md\n' > docs/AGENTS.MD
    imps main docs/mine.md docs/other.md; want walk ok; want docs/mine.md imported; want docs/other.md -
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
    git update-ref refs/heads/main "$(git commit-tree "$(printf '040000 tree %s\tsub\n' "$s" | git mktree)" -p main -m empty-link)"
    imps main docs/x.md; want walk failed; want docs/x.md imported
    # An import into a path main stores as a gitlink (sub/ is an empty directory here).
    t="$(printf '100644 blob %s\tCLAUDE.md\n160000 commit %s\tsub\n' "$(printf 'see @sub/x.md\n' | git hash-object -w --stdin)" "$(git rev-parse main)" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink)"; imps main docs/x.md; want walk failed; want docs/x.md imported; t="$(printf '160000 commit %s\tCLAUDE.md\n100644 blob %s\tAGENTS.md\n' "$(git rev-parse main)" "$(printf 'see @docs/x.md\n' | git hash-object -w --stdin)" | git mktree)"; git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink-start)"; imps main docs/x.md; want walk ok; want docs/x.md imported
}

@test "main walk ends on an import cycle, a self-import and a cycle through an untracked file (U2a3, U2a3c)" {
    mkdir -p docs
    printf 'see @docs/a.md and @CLAUDE.md\n' > CLAUDE.md
    printf 'back @../CLAUDE.md, @a.md and @b.md\n' > docs/a.md
    printf 'again @a.md\n' > docs/b.md
    commit_all cycle
    printf 'Mine: @docs/u.md\n' > CLAUDE.local.md && printf 'loop @../CLAUDE.local.md and @w.md\n' > docs/u.md && printf 'last @u.md\n' > docs/w.md
    imps main docs/a.md docs/b.md docs/u.md docs/w.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$status $output $stderr"; return 1; }
    want walk ok; for p in docs/a.md docs/b.md docs/u.md docs/w.md; do want "$p" imported; done; want docs/other.md -
}

@test "main walk fails on an unreadable blob when the caller did not set pipefail; a main and checkout with no .md file walk ok (U2a3)" {
    imps main docs/a.md; want walk ok; want docs/a.md -; printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude  # first, with no .md on main or in the checkout: an empty start list is no failure
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

@test "main walk cache: a new main commit or main not found by name walks again; a failed walk stays failed; a checkout change is not seen until IMPORTED_MAIN_DONE is cleared (U2a3 i2 test-strategy G6, G9)" {
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all one
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        w() { if isimported main "$1"; then echo "$1"; else echo -; fi; }
        w docs/b.md; printf "Rules: @docs/b.md\n" > CLAUDE.md; git commit -qam two; resolve_main; w docs/b.md; g="$MAIN_SHA"
        a="$(printf "x\n" | git hash-object -w --stdin)"; t="$(printf "100644 blob %s\tA.md\n100644 blob %s\tA.md\n" "$a" "$a" | git mktree)"
        git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup)"; resolve_main; w x.sh; w x.sh
        git update-ref refs/heads/main "$g"; resolve_main; w x.sh; MAIN_BY_NAME=""; w y.sh; resolve_main; w z.sh; printf "Mine: @z.sh\n" > CLAUDE.local.md; w z.sh; IMPORTED_MAIN_DONE=""; w z.sh' _ "$LIB"
    [ "$status" -eq 0 ] && [ "$output" = "$(printf '%s\n' - docs/b.md x.sh x.sh - y.sh - - z.sh)" ] || { echo "$output $stderr"; return 1; }
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
    # shellcheck disable=SC2088  # '~/x.md' is a literal path name, not the home
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

@test "the main walk reads a linked worktree's gitfile as a checkout file, and follows an @ its gitdir path holds, as Claude Code does when an instruction file names @.git (U2a3b L2-confirm security F1, U2a3c)" {
    mkdir -p docs && printf 'see @.git\n' > CLAUDE.md && printf 'x\n' > docs/x.md && commit_all gitfile
    # The gitfile names the main checkout's path, so a checkout path holding
    # " @docs/x.md " puts that import in it.
    m="$BATS_TEST_TMPDIR/a @docs/x.md /m"; mkdir -p "${m%/m}" && mv "$PWD" "$m" && cd "$m"
    git worktree add -q --detach "$BATS_TEST_TMPDIR/wt" main && cd "$BATS_TEST_TMPDIR/wt"
    imps main docs/x.md docs/other.md; want walk ok; want docs/x.md imported; want docs/other.md -
    # A gitfile with no @ imports nothing.
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

@test "the parser prints a name below no reader root as //PATH, joins a relative name to an absolute directory alone, reads IMPORT_WHOLE lines whole, takes import_readers' roots outside a walk, and fails for a ROOT_REAL of / or empty (U2a3b L2-i2 test-strategy, U2b3b2a)" {
    git worktree add -q --detach ../side && git worktree add -q --detach .claude/wt-b
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"; s="$(cd ../side && pwd -P)"
        printf "See @/etc/x.md and @a.md and @%s/docs/in.md and @%s/docs/w.md and @%s/.claude/wt-b/n.md\n" "$ROOT_REAL" "$s" "$ROOT_REAL" | import_targets /opt/d; echo "rc=$?"
        printf "%s\n" "$ROOT_REAL/docs/a b.md" "/etc/x y" | IMPORT_WHOLE=1 import_targets / | sed "s/^/whole /"
        for ROOT_REAL in / ""; do printf "See @docs/a.md\n" | import_targets "" >/dev/null; echo "rc=$?"; done' _ "$LIB"
    for l in //etc/x.md //opt/d/a.md docs/in.md docs/w.md n.md rc=0 'whole docs/a b.md' 'whole //etc/x y'; do printf '%s\n' "$output" | grep -qxF "$l" || { echo "missing $l: $output $stderr"; return 1; }; done
    [ "$(printf '%s\n' "$output" | grep -c '^whole ')" -eq 2 ] && [ "$(printf '%s\n' "$output" | grep -c '^rc=1$')" -eq 2 ] || { echo "$output"; return 1; }
    # A relative name stays in its absolute directory; a dot-nested root's outer spelling is not printed (import_readers' IMPORT_DOTNEST).
    ! printf '%s\n' "$output" | grep -qxE 'a\.md|docs/a\.md|\.claude/wt-b/n\.md' || { echo "$output"; return 1; }
}

@test "both walks follow an import below no reader root, read where it lies against its own directory, through outside chains and back into the repo; a cycle ends (U2b3b2a; U2b3a i1 architecture F5)" {
    o="$BATS_TEST_TMPDIR/out" && mkdir -p docs "$o/sub" && r="$(pwd -P)"
    printf 'See @%s/o1.md and @~/h.md\n' "$o" > AGENTS.md
    printf 'o1: @sub/o2.md\n' > "$o/o1.md"
    # Back in by an absolute and a relative name, and a cycle to o1.
    printf 'o2: @%s/docs/x.md, @../o1.md and @../../repo/docs/y.md\n' "$r" > "$o/sub/o2.md"
    printf 'h: @docs/z.md\n' > "$HOME/h.md"  # against the home's directory, not the repo
    echo x > docs/x.md; echo y > docs/y.md; echo z > docs/z.md; mkdir sub && echo s > sub/o2.md; commit_all out
    for w in tree main; do
        imps "$w" docs/x.md docs/y.md docs/z.md sub/o2.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/x.md imported; want docs/y.md imported; want docs/z.md -; want sub/o2.md -; want docs/other.md -
        # An inherited IMPORT_WHOLE is cleared when the lib is sourced, so text is still read as text (i1 architecture A1).
        IMPORT_WHOLE=1 imps "$w" docs/x.md; want walk ok; want docs/x.md imported
    done
}

@test "an outside link whose real path holds a newline fails the tree walk (the main walk already fails on the newline-named checkout file); import_file reads an outside file against its own directory and the DIRS it is given (U2b3b2a i1 fact-check, architecture A2)" {
    o="$BATS_TEST_TMPDIR/out" && mkdir -p docs "$o" && r="$(pwd -P)"
    printf 'See @%s/nl.md\n' "$o" > AGENTS.md; commit_all nl
    printf 'q: @docs/q.md\n' > "$r/docs/a"$'\n'"b.md" && ln -s "$r/docs/a"$'\n'"b.md" "$o/nl.md"
    for w in tree main; do imps "$w" docs/q.md; want walk failed; want docs/q.md imported; done
    printf 'p: @docs/n.md\n' > "$o/p.md"
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        IMPORT_WORK_LEFT=100000 import_file "$2" ignored ""' _ "$LIB" "$o/p.md"
    for l in docs/n.md "/$o/docs/n.md"; do printf '%s\n' "$output" | grep -qxF "$l" || { echo "missing $l: $output $stderr"; return 1; }; done
}

@test "an outside name whose real path lies in the repo reads as that repo path; an unreadable, missing or non-regular outside name is skipped, as a session cannot load it (U2b3b2a)" {
    [ "$(id -u)" -ne 0 ] || skip "root reads a mode-000 file"
    o="$BATS_TEST_TMPDIR/out" && mkdir -p docs "$o/dir" && r="$(pwd -P)"
    ln -s "$r/docs" "$o/dl" && ln -s "$r/docs/t.md" "$o/tl.md"
    printf 'See @%s/dl/s.md, @%s/tl.md, @%s/no.md, @%s/dir and @%s/locked.md\n' "$o" "$o" "$o" "$o" "$o" > AGENTS.md
    # Read as the repo's docs/t.md, so @u.md resolves against docs/.
    printf 't: @u.md\n' > docs/t.md; echo s > docs/s.md; echo u > docs/u.md; commit_all links
    printf 'l: @docs/q.md\n' > "$o/locked.md" && chmod 000 "$o/locked.md"
    for w in tree main; do
        imps "$w" docs/s.md docs/t.md docs/u.md docs/q.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/s.md imported; want docs/t.md imported; want docs/u.md imported; want docs/q.md -
    done
}

@test "both walks start at each config dir's memory, rules, prompts, auto memory and installed plugins, and at the managed policy (U2b3b2b)" {
    r="$(pwd -P)" && c="$HOME/.claude" && g="$BATS_TEST_TMPDIR/cfg" && m="$BATS_TEST_TMPDIR/managed" && pc="$c/plugins/cache/mk/pl"
    mkdir -p docs "$c/rules/sub" "$c/commands" "$c/projects/p/memory" "$g" "$m" "$pc/1/skills/s" "$pc/0/skills/s"
    printf 'm: @%s/docs/a.md\n' "$r" > "$c/CLAUDE.md"; printf 'r: @%s/docs/b.md and @docs/h.md\n' "$r" > "$c/rules/sub/r.md"
    printf 'c: @docs/c.md\n' > "$c/commands/c.md"  # a prompt: its names also resolve against the session's top level
    printf 'a: @%s/docs/d.md\n' "$r" > "$c/projects/p/memory/MEMORY.md"; printf 'n: @%s/docs/n.md\n' "$r" > "$c/projects/p/memory/other.md"
    printf 'g: @%s/docs/e.md\n' "$r" > "$g/AGENTS.md"; printf 'p: @%s/docs/p.md\n' "$r" > "$m/CLAUDE.md"
    printf 'f: @docs/f.md\n' > "$pc/1/skills/s/SKILL.md"; printf 'o: @docs/o.md\n' > "$pc/0/skills/s/SKILL.md"
    j="$(printf '{"version": 2, "plugins": {"pl@mk": [{"scope": "user", "installPath": "%s/1"}]}}' "$pc")" && echo "$j" > "$c/plugins/installed_plugins.json"
    for f in a b c d e f h n o p; do echo "$f" > "docs/$f.md"; done; commit_all seeds
    for w in tree main; do
        CLAUDE_CONFIG_DIR="$g" T_MANAGED="$m" imps "$w" docs/{a,b,c,d,e,f,p,h,n,o}.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; for f in a b c d e f p; do want "docs/$f.md" imported; done
        # A rule's relative name stays in its directory; other memory files and uninstalled plugin versions are not loaded.
        for f in h n o; do want "docs/$f.md" -; done
        # An installed list python3 cannot read gives every cached version.
        echo '{' > "$c/plugins/installed_plugins.json"; imps "$w" docs/o.md; want walk ok; want docs/o.md imported; [ -z "$stderr" ] || return 1
        # A relative CLAUDE_CONFIG_DIR is not modelled: the walk fails (i1 api F5).
        CLAUDE_CONFIG_DIR=rel imps "$w" docs/o.md; want walk failed
        echo "$j" > "$c/plugins/installed_plugins.json"
    done
}

@test "both walks start at the instruction files of an ancestor below no reader root and at its .claude (U2b3b2b)" {
    mkdir -p docs "$BATS_TEST_TMPDIR/.claude/rules" && r="$(pwd -P)"
    printf 'x: @repo/docs/a.md\n' > "$BATS_TEST_TMPDIR/CLAUDE.local.md"  # against the ancestor's own directory
    printf 'y: @%s/docs/b.md\n' "$r" > "$BATS_TEST_TMPDIR/.claude/rules/y.md"
    echo a > docs/a.md; echo b > docs/b.md; commit_all anc
    for w in tree main; do
        imps "$w" docs/a.md docs/b.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/a.md imported; want docs/b.md imported; want docs/other.md -
    done
}

@test "C1: both walks start at the start files another worktree holds, listed from the file system, skipping one whose bytes match this checkout's plain copy or that holds no @ (U2b3b2b; U2b3a final security 1; i1 fact-check 19b, api F1, performance F1)" {
    mkdir -p docs && printf 'same @docs/s.md\n' > AGENTS.md; printf 'l: @docs/v.md\n' > docs/l.md; ln -s docs/l.md CLAUDE.md
    for f in s u k t v; do echo "$f" > "docs/$f.md"; done; commit_all c1
    git worktree add -q --detach ../side && sd="$(cd ../side && pwd -P)" && mkdir -p "$sd/.claude/commands" "$sd/sub/.CLAUDE/commands"
    printf 'u: @docs/u.md\n' > "$sd/CLAUDE.local.md"; printf 'k: @docs/k.md\n' > "$sd/.claude/commands/k.md"; echo none > "$sd/GEMINI.md"
    # A prompt under .CLAUDE also resolves against the directory holding it (contract item 8's lower-cased path).
    printf 'p: @docs/up.md\n' > "$sd/sub/.CLAUDE/commands/p.md"
    printf 't: @../docs/t.md\n' > "$sd/sub/CLAUDE.md"; printf 'x: @docs/x.md\n' > "$sd/sub/notes.md"
    # git is never run in another root: its .git file is the loop's to write.
    S="$BATS_TEST_TMPDIR/gitlog" && mkdir -p "$S" && printf '#!/bin/sh\necho "$PWD $*" >> "%s/log"\nexec %s "$@"\n' "$S" "$(command -v git)" > "$S/git" && chmod +x "$S/git"
    for w in tree main; do
        PATH="$S:$PATH" T_READER_ROOTS=/nonexistent/host imps "$w" docs/u.md docs/k.md docs/t.md docs/x.md docs/s.md docs/v.md sub/docs/up.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; for f in u k t s v; do want "docs/$f.md" imported; done; want docs/x.md -; want sub/docs/up.md imported
    done
    ! grep -e "^$sd" -e ' -C ' "$S/log" || return 1
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; IMPORT_MANAGED_DIR=/nonexistent; ROOT_REAL="$(pwd -P)"; import_readers; outside_seeds a; printf "%s\n" "${a[@]}"' _ "$LIB"
    for l in "f$sd/CLAUDE.local.md" "p$sd/.claude/commands/k.md" "f$sd/sub/CLAUDE.md"; do printf '%s\n' "$output" | grep -qxF "$l" || { echo "missing $l: $output $stderr"; return 1; }; done
    ! printf '%s\n' "$output" | grep -qF -e "$sd/AGENTS.md" -e "$sd/GEMINI.md" || { echo "$output"; return 1; }
}

@test "a // name outside_ok rejects is projected through its realpath -m: a dangling link, or a linked directory, into another worktree reads as the repo path (U2b3b2b; U2b3b2a final security F1)" {
    git worktree add -q --detach ../side && sd="$(cd ../side && pwd -P)" && o="$BATS_TEST_TMPDIR/out" && mkdir -p docs "$o"
    ln -s "$sd/docs/n.md" "$o/l.md" && ln -s "$sd/docs" "$o/dl"  # side lacks docs/ (it is at the first commit)
    printf 'See @%s/l.md and @%s/dl/m.md\n' "$o" "$o" > AGENTS.md; printf 'n: @deep.md\n' > docs/n.md; echo m > docs/m.md; echo d > docs/deep.md; commit_all proj
    for w in tree main; do
        imps "$w" docs/n.md docs/m.md docs/deep.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/n.md imported; want docs/m.md imported; want docs/deep.md imported; want docs/other.md -
    done
}

@test "both walks fail closed when a seed directory cannot be listed or a seed's name holds a newline (U2b3b2b)" {
    [ "$(id -u)" -ne 0 ] || skip "root lists a mode-000 directory"
    printf 'x\n' > AGENTS.md && commit_all f && mkdir -p "$HOME/.claude/rules/locked"
    chmod 000 "$HOME/.claude/rules/locked"
    for w in tree main; do imps "$w" docs/a.md; want walk failed; want docs/a.md imported; done
    chmod 755 "$HOME/.claude/rules/locked" && printf '@x\n' > "$HOME/.claude/rules/a"$'\n'"b.md"
    for w in tree main; do imps "$w" docs/a.md; want walk failed; want docs/a.md imported; done
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

@test "the main walk reads an imported file under .git as a checkout file and follows its imports (U2a3b L2-i2 security F2, U2a3c)" {
    # .git/notes.md is a checkout file main lacks: phase 2 reads it, so docs/t.md, which it imports, counts.
    mkdir -p docs && printf 'See @.git/notes.md and @sub/../.git/info/n.md\n' > CLAUDE.md && commit_all gitdir
    printf 'see @../docs/t.md\n' > .git/notes.md
    imps main docs/t.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/t.md imported; want docs/other.md -
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

@test "the main walk passes a nested .git directory as a plain directory, and reads a nested .git file, as Claude Code does (U2a3b L2-final security F2, test-strategy F2, U2a3c)" {
    # A nested repository's .git directory names no file: a prefix of @n/.github/x.md passes the plain-directory check.
    mkdir -p notes n && printf 'See @n/.github/x.md and @notes/x.md\n' > GEMINI.md && printf 'x\n' > notes/x.md && printf 'x\n' > n/keep
    commit_all nested
    mkdir n/.git
    imps main notes/x.md n/.github/x.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want notes/x.md imported; want n/.github/x.md imported; want docs/other.md -
    # A .git file (a nested worktree's gitfile, or any file so named) is a checkout file main lacks:
    # Claude Code follows its imports, and so does phase 2.
    rmdir n/.git && printf 'see @../docs/e.md\n' > n/.git
    imps main docs/e.md docs/other.md; want walk ok; want docs/e.md imported; want docs/other.md -
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

@test "checkout phase: a start or import main lacks under a directory main stores as a link, or under an unsearchable checkout directory, fails the walk (U2a3c; U2a3 loop 1 C1, C3)" {
    mkdir -p deep docs && printf 'evil @secret.md\n' > deep/CLAUDE.md && ln -s deep ld && printf 'see @ld/CLAUDE.md\n' > CLAUDE.md && commit_all link
    imps main deep/secret.md; want walk failed; want deep/secret.md imported
    # The checkout makes ld a plain directory holding an untracked start: still failed, as main alone.
    rm ld && mkdir ld && cp deep/CLAUDE.md ld/; imps main deep/secret.md x.sh; want walk failed; want x.sh imported
    # main stores .claude/rules as a link; the checkout holds a plain directory with an untracked rule that imports nothing (the start's own check, fact-check 22a).
    rm -r ld && git rm -q CLAUDE.md; mkdir -p .claude && ln -s ../docs .claude/rules && printf 'see @bar.md\n' > docs/foo.md && commit_all rules-link
    rm .claude/rules && mkdir .claude/rules && printf 'harmless\n' > .claude/rules/foo.md; imps main docs/bar.md; want walk failed; want docs/bar.md imported
    # A readable but unsearchable directory holding an import main lacks, then a start; then an unreadable one only git's listing meets.
    rm -r .claude && git rm -q -r --cached .claude && printf 'see @priv/x.md\n' > AGENTS.md && commit_all priv && mkdir priv && printf 'p @q.md\n' > priv/x.md && chmod 644 priv
    imps main docs/q.md; chmod 755 priv; want walk failed; want docs/q.md imported
    mkdir pv && printf 'harmless\n' > pv/CLAUDE.md && chmod 644 pv; imps main docs/q.md; chmod 755 pv; want walk failed; want docs/q.md imported; rm -r pv
    rm -r priv && mkdir hid && printf 'h @q.md\n' > hid/CLAUDE.md && chmod 000 hid; imps main docs/q.md; chmod 755 hid; want walk failed; want docs/q.md imported
    # main stores sm as a gitlink; the checkout holds a plain directory with an untracked start that imports nothing.
    t="$(printf '100644 blob %s\tAGENTS.md\n160000 commit %s\tsm\n' "$(git rev-parse main:AGENTS.md)" "$(git rev-parse main)" | git mktree)"; git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink)"
    mkdir sm && printf 'harmless\n' > sm/CLAUDE.md; imps main docs/q.md; want walk failed; want docs/q.md imported
}

@test "main walk fails when the batch tr dies after a partial flush, rather than truncating the last start's name (U2a3b final N1, U2a3c)" {
    # The untracked AGENTS.md is the last candidate; a tr that drops the last
    # three bytes ("md" and the NUL) and exits 1 would leave the count whole and
    # the name "agents.", which is no start. Only input holding a NUL (the batch)
    # is cut, so the per-file lower still works.
    mkdir -p docs && printf 'x\n' > docs/keep.md && commit_all base && printf 'see @docs/x.md\n' > AGENTS.md
    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/bash\nt="$(mktemp)"; %s "$@" > "$t"; if grep -qaP "\\\\x00" "$t"; then head -c $(( $(wc -c < "$t") - 3 )) "$t"; rm -f "$t"; exit 1; fi; cat "$t"; rm -f "$t"\n' "$(command -v tr)" > "$BATS_TEST_TMPDIR/bin/tr" && chmod +x "$BATS_TEST_TMPDIR/bin/tr"
    imps main docs/x.md; want walk ok; want docs/x.md imported
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/x.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/x.md imported
}

@test "main walk reads only the first 4 MiB + 1 of a blob or checkout file over 4 MiB, and a blob that long does not fail the walk under pipefail (U2a3b L2-C5, U2a3c)" {
    # Main's CLAUDE.md and the untracked AGENTS.md: 5 MiB each, an import in the first line and another past 4 MiB.
    mkdir -p docs
    for f in CLAUDE.md AGENTS.md; do n="${f%%.*}"; { printf 'see @docs/%s-early.md\n' "$n"; head -c $((5 * 1048576)) /dev/zero | tr '\0' x; printf '\n@docs/%s-late.md\n' "$n"; } > "$f"; done
    git add CLAUDE.md && git commit -qm big
    imps main docs/CLAUDE-early.md docs/AGENTS-early.md docs/CLAUDE-late.md docs/AGENTS-late.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/CLAUDE-early.md imported; want docs/AGENTS-early.md imported; want docs/CLAUDE-late.md -; want docs/AGENTS-late.md -
}

@test "the checkout phase checks each directory an import passes through once per walk, not once per prefix candidate (U2a3b L2-C6, U2a3c)" {
    # @a/b/c/d/e/f/g/h/x.md yields about 20 prefix candidates through eight plain
    # directories main lacks; a realpath shim counts the checks. Unmemoized, each
    # candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized,
    # each directory once, plus each candidate's own check (10 at 2fbd929b; 18
    # without its memo of a prefix candidate's own directory).
    mkdir -p a/b/c/d/e/f/g/h && printf 'x @y.md\n' > a/b/c/d/e/f/g/h/x.md && printf 'see @a/b/c/d/e/f/g/h/x.md\n' > CLAUDE.md && git add CLAUDE.md && git commit -qm base
    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\necho x >> "%s/calls"\nexec %s "$@"\n' "$BATS_TEST_TMPDIR" "$(command -v realpath)" > "$BATS_TEST_TMPDIR/bin/realpath" && chmod +x "$BATS_TEST_TMPDIR/bin/realpath"
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main a/b/c/d/e/f/g/h/y.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want a/b/c/d/e/f/g/h/y.md imported
    n="$(wc -l < "$BATS_TEST_TMPDIR/calls")"; [ "$n" -le 14 ] || { echo "realpath calls: $n"; return 1; }
}

@test "the checkout phase walks an untracked start when main's tree is empty (U2a3c)" {
    git update-ref refs/heads/main "$(git commit-tree "$(printf '' | git mktree)" -m empty)" && git checkout -qf main
    mkdir -p docs && printf 'see @docs/x.md\n' > CLAUDE.md
    imps main docs/x.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$status $output $stderr"; return 1; }
    want walk ok; want docs/x.md imported; want docs/other.md -
}

@test "import_work strips the parser's work trailer and charges it; a missing trailer or a spent IMPORT_WORK_MAX fails (U2a3c)" {
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"; t=5
        o=$'"'"'a.md\n/12'"'"'; import_work o t && echo "1 ok [$o] $t" || echo "1 failed"
        o=/7; import_work o t && echo "2 ok [$o] $t" || echo "2 failed"
        o=$'"'"'docs/12'"'"'; import_work o t && echo "3 ok" || echo "3 failed"
        o=$'"'"'a.md\nb/12x'"'"'; import_work o t && echo "4 ok" || echo "4 failed"
        IMPORT_WORK_MAX=30; o=/7; import_work o t && echo "5 ok $t" || echo "5 failed $t"
        out="$(printf "no imports here\n" | IMPORT_WORK_LEFT=10 import_targets "")"; echo "6 [$out]"' _ "$LIB"
    [ "$output" = $'1 ok [a.md] 17\n2 ok [] 24\n3 failed\n4 failed\n5 failed 31\n6 [/0]' ] || { echo "$output $stderr"; return 1; }
}

@test "main_checkout answers each checkout shape: 0 for a readable plain file, 2 where nothing loads, 1 for anything it does not model, and memoizes plain searchable directories as d and absent or plain-file ancestors as 2 (U2a3c)" {
    mkdir -p d u sdt && printf 'r\n' > d/r.md && printf 'n\n' > d/n.md && printf 'f\n' > f.md && chmod 000 d/n.md && chmod 644 u
    ln -s d/r.md sf.md && ln -s missing.md dg.md && ln -s missing dgd && ln -s sdt sd && mkfifo ff.md
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        declare -A E=([lnk]=120000 [gl]=160000 [nd2/m/l]=120000 [f.md]=100644) M=()
        for p in d/r.md nx.md nd/x.md f.md/x.md d u d/n.md sf.md dg.md sd ff.md u/x.md sd/nx.md dgd/x.md lnk/x.md gl/x.md nd2/m/l/x.md; do
            c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done
        echo "memo $(for k in "${!M[@]}"; do echo "$k=${M[$k]}"; done | sort | tr "\n" " ")"; declare -a A=(); c=0; main_checkout A M d/r.md || c=$?; echo "ent-indexed $c"; c=0; main_checkout E A d/r.md || c=$?; echo "memo-indexed $c"' _ "$LIB"
    chmod 755 u && chmod 644 d/n.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = "d/r.md 0
nx.md 2
nd/x.md 2
f.md/x.md 2
d 2
u 2
d/n.md 1
sf.md 1
dg.md 1
sd 1
ff.md 1
u/x.md 1
sd/nx.md 1
dgd/x.md 1
lnk/x.md 1
gl/x.md 1
nd2/m/l/x.md 1
memo d=d f.md=2 nd2/m=2 nd2=2 nd=2 
ent-indexed 1
memo-indexed 1" ] || { echo "$status $output $stderr"; return 1; }
}

@test "main walk fails on a path under a link main stores below a directory the checkout lacks, and walks a path under a plain file (U2a3c)" {
    mkdir -p a/b real docs && ln -s ../../real a/b/l && printf 'evil @../docs/s.md\n' > real/x.md && printf 'n\n' > docs/n.md
    printf 'see @a/b/l/x.md and @docs/n.md/x.md\n' > CLAUDE.md && commit_all deep-link
    # The checkout keeps a/b/l: the parent-link refusal.
    imps main docs/s.md; want walk failed; want docs/s.md imported
    # The checkout lacks a: main still stores a/b/l as a link, two levels below it, which the walk does not follow.
    rm -r a; imps main docs/s.md; want walk failed; want docs/s.md imported
    # A path under a plain file loads nothing and is no failure.
    git rm -q -r a && printf 'see @docs/n.md/x.md\n' > CLAUDE.md && commit_all under-file
    imps main docs/s.md docs/n.md; [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/n.md imported; want docs/s.md -
}

@test "each walk caps every file's parser at what IMPORT_WORK_MAX has left, in every arm, and charges every arm (U2a3b L2-confirm performance P2, U2a3c)" {
    # Four top-level files alike but for one letter cost w each: two on main, two
    # only in the checkout, so each main_imports arm runs twice. An awk shim logs
    # the cap each parser call is given (IT_WORK).
    printf 'see @a.md\n' > AGENTS.md && printf 'see @b.md\n' > GEMINI.md && commit_all two && printf 'see @c.md\n' > CLAUDE.md && printf 'see @d.md\n' > CLAUDE.local.md
    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\n[ -z "${IT_WORK+x}" ] || echo "$IT_WORK" >> "%s/cap"\nexec %s "$@"\n' "$BATS_TEST_TMPDIR" "$(command -v awk)" > "$BATS_TEST_TMPDIR/bin/awk" && chmod +x "$BATS_TEST_TMPDIR/bin/awk"
    run --separate-stderr timeout 60 env LC_ALL=C PATH="$BATS_TEST_TMPDIR/bin:$PATH" C="$BATS_TEST_TMPDIR/cap" bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
        out="$(printf "see @a.md\n" | IMPORT_WORK_LEFT=1000000 import_targets "")"; w=0; import_work out w
        for m in $((4 * w - 1)) $((4 * w)); do IMPORT_WORK_MAX=$m; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""
            imported_names && echo "$((m - 4 * w)) tree ok" || echo "$((m - 4 * w)) tree failed"; main_imports && echo "$((m - 4 * w)) main ok" || echo "$((m - 4 * w)) main failed"; done
        # The caps derive from w: each candidate is charged its resolved spelling, so w grows with the fixture root.
        m=$((10 * w)); IMPORT_WORK_MAX=$m; want="$(printf "%s\n" $m $((m - w)) $((m - 2 * w)) $((m - 3 * w)) | sort -n | tr "\n" " ")"
        for k in tree main; do IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; rm -f "$C"
            if [[ $k == tree ]]; then imported_names; else main_imports; fi
            got="$(sort -n "$C" | tr "\n" " ")"; [[ "$got" == "$want" ]] && echo "$k caps ok" || echo "$k caps [$got] want [$want]"; done' _ "$LIB"
    [ "$output" = $'-1 tree failed\n-1 main failed\n0 tree ok\n0 main ok\ntree caps ok\nmain caps ok' ] || { echo "$output $stderr"; return 1; }
}

@test "the parser stops once its work passes IMPORT_WORK_LEFT, below its per-file bound (U2a3c)" {
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        out="$(printf "see @abcdefgh.md\n" | IMPORT_WORK_LEFT=1000000 import_targets "")"; w=0; import_work out w
        for l in $((w - 1)) $w; do out="$(printf "see @abcdefgh.md\n" | IMPORT_WORK_LEFT=$l import_targets "")" && echo "$((l - w)) ok" || echo "$((l - w)) failed"; done' _ "$LIB"
    [ "$output" = $'-1 failed\n0 ok' ] || { echo "$output $stderr"; return 1; }
}

@test "main walk reads an untracked start that a main file also imports once, through the checkout (U2a3c; override row 446)" {
    mkdir -p docs && printf 'see @docs/AGENTS.md\n' > CLAUDE.md && commit_all base
    printf 'see @x.md\n' > docs/AGENTS.md
    imps main docs/AGENTS.md docs/x.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/AGENTS.md imported; want docs/x.md imported; want docs/other.md -
    # The same path as a checkout symlink: refused at the start, before the import meets it.
    rm docs/AGENTS.md && printf 'see @x.md\n' > docs/real.md && ln -s real.md docs/AGENTS.md
    imps main docs/x.md; want walk failed; want docs/x.md imported
}

@test "the checkout phase stays linear in a deep import token whose ancestors the checkout lacks (U2a3c i2 performance F1)" {
    # @a/a/.../x.md, 1,000 levels deep, none in the checkout: about 0.6 s; 21b35ebf's
    # top-down loop rescanned every absent ancestor per prefix candidate (10.7 s).
    p=""; for ((i = 0; i < 1000; i++)); do p+="a/"; done
    printf 'see @%sx.md\n' "$p" > CLAUDE.md && commit_all deep
    run --separate-stderr timeout 6 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
        main_imports && echo ok || echo failed' _ "$LIB"
    [ "$output" = ok ] || { echo "$status $output $stderr"; return 1; }
}

@test "main walk fails on link text main stores longer than 4096 bytes before reading it whole (U2a3c i2 performance F2)" {
    printf 'r\n' > r.md && commit_all base
    l="$(head -c 4097 /dev/zero | tr '\0' a | git hash-object -w --stdin)"; k="$(printf 'r.md' | git hash-object -w --stdin)"
    # A git shim logs each `git cat-file blob` object name: the long link must fail with no read of its blob.
    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\n[ "$1 $2" != "cat-file blob" ] || echo "$3" >> "%s/blobs"\nexec %s "$@"\n' "$BATS_TEST_TMPDIR" "$(command -v git)" > "$BATS_TEST_TMPDIR/bin/git" && chmod +x "$BATS_TEST_TMPDIR/bin/git"
    for b in "$l" "$k"; do
        t="$(printf '100644 blob %s\tr.md\n120000 blob %s\tCLAUDE.md\n' "$(git rev-parse main:r.md)" "$b" | git mktree)"
        git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m link)"; rm -f "$BATS_TEST_TMPDIR/blobs"
        PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main r.md; echo "$output" | head -1
        if grep -q ':CLAUDE\.md$' "$BATS_TEST_TMPDIR/blobs" 2>/dev/null; then echo "link blob read"; else echo "link blob unread"; fi
    done > "$BATS_TEST_TMPDIR/got"
    [ "$(cat "$BATS_TEST_TMPDIR/got")" = $'walk: failed\nlink blob unread\nwalk: ok\nlink blob read' ] || { cat "$BATS_TEST_TMPDIR/got"; return 1; }
}

@test "main_checkout's work over a deep token's prefix candidates grows linearly with depth, counted, not timed (U2a3c i2 performance F1)" {
    # xtrace counts the commands main_checkout runs for every prefix of a token
    # 100 and 400 levels deep, none in the checkout. Linear work gives a ratio of
    # about 4 (4.0 at 3a35c8b9); 21b35ebf's top-down rescan of every absent
    # ancestor gives about 16 (15.6). A count, so no host is fast enough to hide it.
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"; t="$2"
        for n in 100 400; do unset E M; declare -A E=() M=(); p=""
            exec 3> "$t"; BASH_XTRACEFD=3; set -x
            for ((i = 0; i < n; i++)); do p+="a/"; main_checkout E M "${p%/}" || true; main_checkout E M "${p}x.md" || true; done
            set +x; exec 3>&-; echo "$(wc -l < "$t")"; done' _ "$LIB" "$BATS_TEST_TMPDIR/xtrace"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$status $output $stderr"; return 1; }
    a="$(sed -n 1p <<< "$output")"; b="$(sed -n 2p <<< "$output")"
    [ "$a" -gt 0 ] && [ "$b" -le $((6 * a)) ] || { echo "commands at 100: $a, at 400: $b"; return 1; }
}

@test "main_checkout refuses a PATH main stores as a link or gitlink, so a plain checkout directory there never passes a path below it (U2a3c final)" {
    # The checkout holds plain searchable directories where main stores a link and a gitlink;
    # lx and gx, a link and a gitlink main stores, are absent there and answer 1 too.
    mkdir -p l g && printf 'x\n' > l/f.md && printf 'x\n' > g/f.md
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        declare -A E=([l]=120000 [g]=160000 [lx]=120000 [gx]=160000) M=()
        for p in l l/f.md g g/f.md lx gx; do c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done' _ "$LIB"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = $'l 1\nl/f.md 1\ng 1\ng/f.md 1\nlx 1\ngx 1' ] || { echo "$status $output $stderr"; return 1; }
}

@test "the checkout phase stays near linear in the number of import tokens main lacks (U2a3c final performance F1)" {
    # 4,000 tokens @nI/a/b/c/d/x.md, none in the checkout: about 2.5 s here (6.5 s
    # with the CPUs oversubscribed 1.5x). A hang guard only: the ${x@a} cost class
    # (44.6 s at 3a35c8b9) is pinned host-independently by the ratio test below.
    { printf 'see'; for ((i = 0; i < 4000; i++)); do printf ' @n%d/a/b/c/d/x.md' "$i"; done; printf '\n'; } > CLAUDE.md && commit_all many
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
        main_imports && echo ok || echo failed' _ "$LIB"
    [ "$output" = ok ] || { echo "$status $output $stderr"; return 1; }
}

@test "main_checkout's cost per call does not grow with ENT's or MEMO's size, a ratio of two timings in one process so no host is fast or slow enough to hide it (U2a3c final performance F1)" {
    # 400 calls with ENT and MEMO of 30,000 entries each, against 400 with both
    # empty, timed in the same shell. Constant-time type checks give a ratio near
    # 1 (0.4-1.0 here, idle or with 24 busy loops on 16 CPUs); a check linear in
    # either array (${x@a}, as at 3a35c8b9) gives 59-141. Best of three rounds
    # against a bound of 10, so a stall in one round cannot fail it.
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        declare -A E=() M=() BE=() BM=(); for ((i = 0; i < 30000; i++)); do BE["z$i"]=100644; BM["y$i"]=2; done
        t() { local s=$EPOCHREALTIME e k; for ((k = 0; k < 400; k++)); do main_checkout "$1" "$2" "q$k/x.md" || true; done; e=$EPOCHREALTIME; echo $(( ${e/./} - ${s/./} )); }
        best=""; for r in 1 2 3; do a=$(t E M); b=$(t BE BM); x=$(( b * 100 / a )); [[ -n "$best" && $best -le $x ]] || best=$x; done; echo "$best"' _ "$LIB"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" -le 1000 ] || { echo "ratio x100: $status $output $stderr"; return 1; }
}

@test "main_checkout answers a PATH main stores as a blob by the checkout's plain file there, pinned though U2b's precondition passes only paths main lacks (U2a3c final)" {
    printf 'x\n' > b.md && printf 'x\n' > e.md
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        declare -A E=([b.md]=100644 [e.md]=100755) M=()
        for p in b.md e.md; do c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done' _ "$LIB"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = $'b.md 0\ne.md 0' ] || { echo "$status $output $stderr"; return 1; }
}

@test "floor: instruction and prompt files, dotfiles, gate code, imports, cycle files, records and other briefs' files refuse; the rest pass (T10, U2a4)" {
    mkdir -p docs skills/x
    printf 'Rules: @docs/imported.md and @docs/new.md\n' > CLAUDE.md
    printf 'More: @deep.md.\n' > docs/imported.md
    printf 'deep\n' > docs/deep.md
    printf 'See **@ref.md**\n' > skills/x/SKILL.md
    commit_all imports
    # An untracked local instruction file adds imports; a working-tree edit of a
    # tracked one does not (main's copy decides).
    printf 'Mine: @docs/private.md\n' > CLAUDE.local.md
    printf 'Rules: @docs/wt-only.md\n' > CLAUDE.md
    s=2026-10-01-x
    refuse=(CLAUDE.md "$INSTR" docs/sub/SKILL.md "$INSTR" Agents.MD "$INSTR" docs/working/CLAUDE.md "$INSTR"
        .claude/rules/x.md "$INSTR" .claude/commands/c.md "$INSTR" scripts/lib/CLAUDE.md "$INSTR"
        .claude/settings.json "$DOT" .envrc "$DOT" .gitattributes "$DOT" docs/x/.y "$DOT" .github/x.yml "$DOT"
        scripts/build-loop.sh "$GATE" scripts/dev-cycle.sh "$GATE" scripts/questions.sh "$GATE"
        scripts/lib/dev-cycle-read.sh "$GATE" scripts/lib/new.sh "$GATE" Scripts/Build-Loop.sh "$GATE"
        docs/imported.md "$IMP" Docs/Imported.md "$IMP" docs/deep.md "$IMP" skills/x/ref.md "$IMP" docs/new.md "$IMP" docs/private.md "$IMP"
        docs/constraints.md "$USER" docs/dev-cycle.md "$OWN" docs/roadmap.md "$OWN" Docs/Roadmap.md "$OWN"
        docs/working/questions.md "$OWN" docs/working/briefs/2026-10-02-y.md "$OWN" docs/working/briefs/closed/2026-10-01-x.md "$OWN"
        docs/decisions/001-x.md "$REC" docs/thoughts/x.md "$REC" docs/human-author/x.md "$REC"
        docs/working/checkpoint-2026-10-02-y.md "$WORK" docs/working/plan-x.md "$WORK" docs/working/notes.md "$WORK"
        docs/working/plan-2026-10-01-xy.md "$WORK" docs/working/scratch/plan-2026-10-01-x.md "$WORK"
        docs/reviews/r-2026-10-01-x.md "$REV")
    pass=(scripts/other.sh skills/x/helper.md hooks/x.sh install.sh test/x.bats docs/guide.md docs/wt-only.md
        workflows/x.md docs/working/plan-2026-10-01-x.md docs/working/Research-2026-10-01-x.md docs/working/test-strategy-2026-10-01-x.md)
    paths=(); for ((i = 0; i < ${#refuse[@]}; i += 2)); do paths+=("${refuse[i]}"); done
    floors "$s" M "${paths[@]}" "${pass[@]}"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    for ((i = 0; i < ${#refuse[@]}; i += 2)); do want "${refuse[i]}" "${refuse[i+1]}"; done
    for p in "${pass[@]}"; do want "$p" -; done
    [ "${#lines[@]}" -eq $(( ${#paths[@]} + ${#pass[@]} )) ] || { echo "$output"; return 1; }
}

@test "floor: only an added review whose name ends with the full stem is the brief's own (T10, F23, F27, U2a4)" {
    s=2026-10-01-x
    floors "$s" A docs/reviews/code-review-2026-10-01-x.md docs/reviews/2026-10-01-x.md docs/reviews/r-2026-10-02-y.md \
        docs/reviews/r-2026-10-01-xy.md docs/reviews/2026-10-01-x-notes.md docs/reviews/sub/r-2026-10-01-x.md docs/reviews/x.md
    want docs/reviews/code-review-2026-10-01-x.md -
    want docs/reviews/2026-10-01-x.md -
    for p in docs/reviews/r-2026-10-02-y.md docs/reviews/r-2026-10-01-xy.md docs/reviews/2026-10-01-x-notes.md \
             docs/reviews/sub/r-2026-10-01-x.md docs/reviews/x.md; do want "$p" "$REV"; done
    # Modified or deleted, even its own name is a record; an empty stem owns nothing.
    floors "$s" D docs/reviews/code-review-2026-10-01-x.md
    want docs/reviews/code-review-2026-10-01-x.md "$REV"
    floors "" A docs/reviews/-.md docs/working/plan-.md
    want docs/reviews/-.md "$REV"
    want docs/working/plan-.md "$WORK"
}

@test "floor fails closed when main's walk fails, main is not found by name, or a path cannot be lower-cased (U2a4; override row 424)" {
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
    floors 2026-10-01-x M scripts/other.sh
    want scripts/other.sh -
    # A failing tr: floor and --check-fix each refuse, and say why.
    mkdir -p "$BATS_TEST_TMPDIR/bin" docs && printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/tr" && chmod +x "$BATS_TEST_TMPDIR/bin/tr"
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" floors 2026-10-01-x M scripts/other.sh
    want scripts/other.sh "the path could not be lower-cased"
    printf 'x\n' > docs/b.md && commit_all doc
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-fix docs/b.md
    [ "$output" = "skip docs/b.md: the path could not be lower-cased; file it instead" ] || { echo "$output $stderr"; return 1; }
    # The instruction file's blob is missing from the object store.
    o="$(git rev-parse main:CLAUDE.md)"
    rm ".git/objects/${o:0:2}/${o:2}"
    floors 2026-10-01-x M scripts/other.sh docs/b.md
    want scripts/other.sh "$WALKFAIL"
    want docs/b.md "$WALKFAIL"
    # No default branch found by name: nothing is read, everything refuses.
    git checkout -q -b trunk && git branch -q -D main
    floors 2026-10-01-x M scripts/other.sh
    want scripts/other.sh "$WALKFAIL"
}

@test "check_fix and floor share one read-as-truth rule; docs/thoughts/ differs on purpose (U2a4; override rows 204, 322, 348)" {
    run --separate-stderr env LC_ALL=C bash -c 'source "$1"; shift
        for p in "$@"; do if truthrule "$p"; then echo "$p: $TRUTH_WHY"; else echo "$p: -"; fi; done' _ "$LIB" \
        claude.md docs/x/skill.md .claude/commands/c.md .envrc docs/x/.y docs/roadmap.md docs/dev-cycle.md docs/constraints.md \
        docs/decisions/1.md docs/human-author/a.md docs/thoughts/t.md docs/guide.md Docs/Constraints.md
    [ "$output" = "claude.md: instr
docs/x/skill.md: instr
.claude/commands/c.md: instr
.envrc: dot
docs/x/.y: dot
docs/roadmap.md: cycle
docs/dev-cycle.md: settings
docs/constraints.md: user
docs/decisions/1.md: record
docs/human-author/a.md: record
docs/thoughts/t.md: -
docs/guide.md: -
Docs/Constraints.md: case" ] || { echo "$output $stderr"; return 1; }
    mkdir -p docs/thoughts && printf 'x\n' > docs/thoughts/t.md && commit_all thoughts
    run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-fix docs/thoughts/t.md
    [ "$output" = "ok docs/thoughts/t.md" ] || { echo "$output $stderr"; return 1; }
    floors 2026-10-01-x M docs/thoughts/t.md
    want docs/thoughts/t.md "$REC"
}

@test "both walks start at .md files under .claude/rules/, commands/, agents/ and output-styles/ at any depth, tracked or not; a prompt's names also resolve against its .claude/'s directory and the top level (U2a4; override rows 370, 435)" {
    mkdir -p .claude/commands/ns .claude/agents .claude/output-styles .claude/rules/a sub/.claude/commands docs
    printf 'run @docs/c1.md\n' > .claude/commands/ns/go.md
    printf 'as @docs/a1.md\n' > .claude/agents/rev.md
    printf 'as @docs/o1.md\n' > .claude/output-styles/terse.md
    printf 'rule @r1.md\n' > .claude/rules/a/r.md
    printf 'run @docs/s1.md\n' > sub/.claude/commands/x.md
    printf 'not a start @docs/n1.md\n' > .claude/notes.md
    printf 'x\n' > docs/c1.md
    commit_all prompts
    printf 'run @docs/u1.md\n' > .claude/commands/u.md
    for w in tree main; do
        imps "$w" docs/c1.md docs/a1.md docs/o1.md .claude/rules/a/r1.md sub/docs/s1.md docs/s1.md \
            sub/.claude/commands/docs/s1.md docs/u1.md docs/n1.md .claude/rules/a/docs/r1.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
        want walk ok
        for p in docs/c1.md docs/a1.md docs/o1.md .claude/rules/a/r1.md sub/docs/s1.md docs/s1.md sub/.claude/commands/docs/s1.md docs/u1.md; do
            want "$p" imported
        done
        want docs/n1.md -; want .claude/rules/a/docs/r1.md -
    done
    # Override row 435's case: a doc a command names is refused by both callers.
    floors 2026-10-01-x M docs/c1.md
    want docs/c1.md "$IMP"
    run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-fix docs/c1.md
    [[ "$output" == "skip docs/c1.md: an instruction file names it after an @"* ]] || { echo "$output $stderr"; return 1; }
}

@test "main walk fails on a prompt start main stores as a symlink, since its names resolve against the session, not the link's target (U2a4)" {
    mkdir -p .claude/commands .claude/rules docs && printf 'see @x.md\n' > docs/t.md
    ln -s ../../docs/t.md .claude/rules/t.md && commit_all rule-link
    imps main docs/x.md; want walk ok; want docs/x.md imported
    ln -s ../../docs/t.md .claude/commands/t.md && commit_all command-link
    imps main docs/x.md; want walk failed; want docs/x.md imported
    # A start directory, or .claude itself, stored as a link lists its prompts under
    # the target's path, which isstart does not know: the walk fails (U2a4 final security F1).
    git rm -rq .claude && mkdir -p prompts && printf 'run @docs/q.md\n' > prompts/c.md && commit_all unlink
    imps main docs/q.md; want walk ok; want docs/q.md -
    for l in .claude/commands .claude/Skills .claude; do
        mkdir -p "$(dirname "$l")" && ln -s "$(realpath -m --relative-to="$(dirname "$l")" prompts)" "$l" && commit_all "link $l"
        imps main docs/q.md; want walk failed; want docs/q.md imported
        git rm -rq "${l%%/*}" && commit_all "unlink $l"
    done
    # A start-named link to a directory, and a gitlink start, fail too (confirming security F3).
    mkdir -p .claude/rules && ln -s ../../prompts .claude/rules/r.md && commit_all dir-link
    imps main docs/q.md; want walk failed; want docs/q.md imported
    git rm -rq .claude && commit_all unlink-dir
    t="$(printf '160000 commit %s\tg.md\n' "$(git rev-parse main)" | git mktree)"; t="$(printf '040000 tree %s\trules\n' "$t" | git mktree)"
    t="$(printf '040000 tree %s\t.claude\n040000 tree %s\tprompts\n' "$t" "$(git rev-parse main:prompts)" | git mktree)"
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink-rule)"
    imps main docs/q.md; want walk failed; want docs/q.md imported
}

@test "the parser resolves each relative name against every directory it is given (U2a4)" {
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        printf "@a.md @/x/b.md\n" | import_targets docs sub/ ""' _ "$LIB"
    [ "$status" -eq 0 ] || { echo "$output $stderr"; return 1; }
    for p in docs/a.md sub/a.md a.md; do printf '%s\n' "$output" | grep -qxF "$p" || { echo "want $p: $output"; return 1; }; done
}

@test "instruction_names, the tree walk's prefilter, keeps exactly the names isstart accepts (U2a4 i1 architecture F6)" {
    run --separate-stderr env LC_ALL=C bash -c 'source "$1"; ps=()
        for d in "" a/ a/b/; do for n in CLAUDE.md claude.local.md Agents.MD agent.md GEMINI.md SKILL.md skills.md x.md x.txt claude.md.bak; do ps+=("$d$n"); done
            for c in rules commands agents output-styles skills notes; do for t in x.md sub/X.MD x.txt; do ps+=("$d.claude/$c/$t" "$d.Claude/$c/$t"); done; done; done
        want=$(for p in "${ps[@]}"; do l=$(lower "$p"); isstart "$l" && printf "%s\n" "$p"; done)
        got=$(printf "%s\0" "${ps[@]}" | instruction_names | tr "\0" "\n")
        [[ "$want" == "$got" ]] && echo same || { echo "isstart:"; echo "$want"; echo "prefilter:"; echo "$got"; }' _ "$LIB"
    [ "$output" = same ] || { echo "$output $stderr"; return 1; }
}

@test "both walks read a quoted prompt mention (blanks included), a skill's names against the session, and the directory holding every enclosing .claude/ (U2a4 i1 security F1-F3, i2 fact-check 1, 19b, 27)" {
    mkdir -p .claude/commands .claude/skills/k a/.claude/commands/b/.claude/commands c/.claude/.claude/commands docs
    printf 'run @"docs/q.md" and @"docs/a b.md"\n' > .claude/commands/q.md
    printf 'use @docs/k.md\n' > .claude/skills/k/SKILL.md
    printf 'run @docs/n.md\n' > a/.claude/commands/b/.claude/commands/x.md
    printf 'run @d.md\n' > c/.claude/.claude/commands/y.md
    # A quoted text that spans lines resolves across the break (U2a4 final security F2); a
    # .claudex component is no session base (final fact-check 31).
    printf 'run @"x\n/../docs/m.md" now\n' > .claude/commands/m.md
    mkdir -p e/.claudex/.claude/commands && printf 'run @f.md\n' > e/.claudex/.claude/commands/z.md
    # Claude Code drops a #L5 or #section suffix, and an @" may end its line or open in a
    # spliced comment; a quoted name is also read untrimmed (confirming security F1, F2, notes).
    printf 'review @"docs/h b.md#L5" and @"docs/s.md#sec"\nrun @"\n/../docs/e.md" now\n' > .claude/commands/h.md
    printf 'run @<!-- c -->"x\n/../docs/c.md" and @"docs/z.md "\n' > .claude/commands/c.md
    # Lines of 2,000 quotes after an @, and an unclosed @" before 3 KB of prose, in an
    # instruction file and a prompt, stay within the work bound (the quote line costs about
    # 8M of its 50M per read): the walk passes (final performance F1).
    { printf 'see @'; for ((i = 0; i < 2000; i++)); do printf '"'; done; printf '\n'; } > CLAUDE.md
    { printf 'say @"'; for ((i = 0; i < 600; i++)); do printf 'word '; done; printf '\n'; } | tee -a CLAUDE.md >> .claude/commands/q.md
    commit_all prompts
    imps main e/f.md; want e/f.md -
    ps=(docs/q.md "docs/a b.md" docs/k.md docs/n.md a/docs/n.md a/.claude/commands/b/docs/n.md c/d.md c/.claude/d.md docs/m.md e/.claudex/f.md
        "docs/h b.md" docs/s.md docs/e.md docs/c.md "docs/z.md ")
    for w in tree main; do
        imps "$w" "${ps[@]}"
        want walk ok; for p in "${ps[@]}"; do want "$p" imported; done
    done
}

@test "a quote left open over many lines fails both walks within the work bound, not after quadratic time (U2a4 confirming fact-check 15a, security F4)" {
    mkdir -p .claude/commands
    { printf 'run @"x\n'; for ((i = 0; i < 20000; i++)); do printf 'word word\n'; done; } > .claude/commands/o.md
    commit_all open-quote
    for w in tree main; do imps "$w" docs/x.md; want walk failed; want docs/x.md imported; done
}

@test "truthwalk empties TRUTH_WHY when it does not refuse; import_reset makes the next floor walk again (U2a4 i1 api-consistency 1, architecture F1)" {
    printf 'see @docs/a.md\n' > CLAUDE.md && commit_all claude
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        truthwalk main docs/b.md || echo "b: [$TRUTH_WHY]"
        truthwalk main docs/a.md && echo "a: [$TRUTH_WHY]"
        printf "see @docs/c.md\n" > CLAUDE.local.md
        floor docs/c.md x M || echo "c cached: -"
        import_reset; floor docs/c.md x M && echo "c: $FLOOR_WHY"' _ "$LIB"
    [ "$output" = "b: []
a: [imported]
c cached: -
c: $IMP" ] || { echo "$output $stderr"; return 1; }
}

# chk ARG...: run build-loop.sh --check. show: what a failed --check test prints,
# the history included (the plan's test spec; row 223).
chk() { run --separate-stderr bash "$BL" --check "$@"; }
show() { echo "status $status"; echo "$output"; echo "$stderr"; git -c log.date=default log --oneline --graph --all; }
# gated BRANCH: brief x, open and naming BRANCH (B is its path), and BRANCH with one commit.
gated() { brief x "Status: open" "Branch: $1"; work "$1"; }

@test "--check: a clean merge is ok with the tip and the merged tree; main's later commits are merged, not judged; a conflict refuses (T16, U2b1a)" {
    gated feat/x; t="$(git rev-parse feat/x)"
    echo m > main.txt && commit_all "main moves on"
    chk "$B"
    [ "$status" -eq 0 ] && [ "$output" = "ok $B $t $(git merge-tree --write-tree main feat/x)
path $B A work-feat-x.txt" ] && [ -z "$stderr" ] || { show; return 1; }
    echo clash > work-feat-x.txt && commit_all clash
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: feat/x conflicts with the default branch" ] || { show; return 1; }
}

@test "--check's merge reads no checkout attributes: an untracked .gitattributes, or one planted in .git, cannot turn a conflict into a union merge (U2b1a)" {
    gated feat/x
    echo clash > work-feat-x.txt && commit_all clash
    printf '* merge=union\n' > .gitattributes
    printf '* merge=union\n' > .git/.gitattributes
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: feat/x conflicts with the default branch" ] || { show; return 1; }
}

@test "--check --expect: the tip's full id passes in either order; a stale id refuses; a short id, a name, HEAD, upper case, no value, a second --expect or two briefs are usage errors (T17, U2b1a)" {
    gated feat/x; t="$(git rev-parse feat/x)"; m="$(git rev-parse main)"
    for args in "$B --expect $t" "--expect $t $B"; do
        # shellcheck disable=SC2086  # split on purpose: two argument orders
        chk $args
        [ "$status" -eq 0 ] && [[ "$output" == "ok $B $t "* ]] || { show; return 1; }
    done
    chk "$B" --expect "$m"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: the tip of feat/x is $t, not the expected $m" ] || { show; return 1; }
    for e in "${t:0:12}" feat/x HEAD "$(printf '%s' "$t" | tr abcdef ABCDEF)"; do
        chk "$B" --expect "$e"
        [ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"full 40- or 64-hex commit id"* ]] || { show; return 1; }
    done
    for args in "$B --expect" "$B --expect $t --expect $t" "$B $B --expect $t" "--expect $t"; do
        # shellcheck disable=SC2086
        chk $args
        [ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"usage:"* ]] || { echo "args: $args"; show; return 1; }
    done
}

@test "--check refuses a brief done, dropped or new on main, a branch absent or not ahead; skips what --status skips; answers each brief and exits 2 on any refusal (T18, F31, U2b1a)" {
    for st in 'done' dropped; do
        brief "$st" "Status: $st" "Branch: feat/$st"; work "feat/$st"
        chk "$B"
        [ "$status" -eq 2 ] && [ "$output" = "refuse $B: the brief is $st on the default branch; only an open brief merges" ] || { show; return 1; }
    done
    chk docs/working/briefs/2026-10-01-new.md
    [ "$status" -eq 2 ] && [ "$output" = "refuse docs/working/briefs/2026-10-01-new.md: the brief is new on the default branch; only an open brief merges" ] || { show; return 1; }
    brief gone "Status: open" "Branch: feat/gone"; gone="$B"
    brief level "Status: open" "Branch: feat/level"; level="$B"; git branch feat/level main
    gated feat/x; x="$B"
    chk "$gone" "$level" "$x"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $gone: its branch feat/gone does not exist
refuse $level: its branch feat/level has no commit the default branch lacks
ok $x $(git rev-parse feat/x) $(git merge-tree --write-tree main feat/x)
path $x A work-feat-x.txt" ] || { show; return 1; }
    brief twin "Status: open" "Branch: Feat/X"
    chk "$x"
    [ "$status" -eq 2 ] && [ "$output" = "skip $x: another open brief on the default branch names the same branch (compared ignoring case)" ] || { show; return 1; }
}

@test "--check's state gate refuses each planted git state that can run a command or change the merge, before reading any brief (T26, U2b1a)" {
    gated feat/x
    for kv in filter.x.clean=true filter.x.smudge=true include.path=/dev/null includeIf.gitdir:/x/.path=/dev/null \
              hook.x.command=true merge.x.driver=true merge.renormalize=true diff.ignoreSubmodules=all diff.x.textconv=true \
              core.fsmonitor=true core.attributesFile=/dev/null core.hooksPath=/dev/null gpg.program=true log.showSignature=true \
              extensions.partialClone=origin remote.origin.promisor=true; do
        git config "${kv%%=*}" "${kv#*=}"
        chk "$B"
        [ "$status" -eq 2 ] && [[ "$output" == "refuse state "*": set in config, it can make the gate's git run a command or change its merge" ]] \
            && [ "${#lines[@]}" -eq 1 ] || { echo "key: $kv"; show; return 1; }
        git config --unset "${kv%%=*}"
    done
    git config extensions.worktreeConfig true && git config --worktree merge.y.driver true
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state merge.y.driver: set in config.worktree, it can make the gate's git run a command or change its merge" ] || { show; return 1; }
    git config --worktree --unset merge.y.driver
    printf '* merge=union\n' > .git/info/attributes
    git rev-parse main > .git/info/grafts
    git rev-parse main > .git/shallow
    git replace "$(git rev-parse main)" "$(git rev-parse feat/x)"
    git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/feat/x
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state info/attributes: present and not an empty file
refuse state info/grafts: present and not an empty file
refuse state shallow: present and not an empty file
refuse state refs/replace: 1 replace ref(s)
refuse state origin/HEAD: it names a branch other than origin/main or origin/master" ] || { show; return 1; }
}

@test "under a broken log.* config the brief and branch reads skip instead of reading LOOP or DATE wrong (row 307, U2b1a1)" {
    gated feat/x; tip feat/x "handoff: ready"
    git config log.date bogus
    run --separate-stderr bash "$BL" --status "$B"
    [ "$status" -eq 0 ] && [ "$output" = "skip $B: Branch: its commit count or date could not be read" ] || { show; return 1; }
    run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-branch feat/x
    [ "$status" -eq 0 ] && [ "$output" = "skip feat/x: its commit count or date could not be read" ] || { show; return 1; }
}

@test "build-loop.sh and the reader lib never push (T20, U2b1a)" {
    run grep -nwi push "$BL" "$LIB"
    [ "$status" -eq 1 ] || { echo "$output"; return 1; }
}

@test "--check refuses a partial clone before any object is read: a promisor remote's upload-pack never runs for a missing object (R1, U2b1a i1)" {
    gated feat/x
    # A lazy fetch of a missing blob would run the promisor remote's upload-pack, so it leaves a mark.
    git config remote.origin.url "$BATS_TEST_TMPDIR/nowhere"
    git config remote.origin.uploadpack "touch $BATS_TEST_TMPDIR/fetched; git-upload-pack"
    git config remote.origin.promisor true
    git config extensions.partialClone origin
    # main's tip commit: resolve_main reads it, so the gate must run before resolve_main.
    o="$(git rev-parse main)"; rm ".git/objects/${o:0:2}/${o:2}"
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state remote.origin.promisor: set in config, it can make the gate's git run a command or change its merge
refuse state extensions.partialclone: set in config, it can make the gate's git run a command or change its merge" ] || { echo "$status $output $stderr"; return 1; }
    [ ! -e "$BATS_TEST_TMPDIR/fetched" ] || { echo "upload-pack ran"; return 1; }
}

@test "every git call --check makes carries harden's config pairs (core.hooksPath=/dev/null among them), no global or system config and no transport (T26, A4, U2b1a i1, i2, A17)" {
    gated feat/x
    # A shim ahead of git logs each call's config pairs, then runs the real git.
    S="$BATS_TEST_TMPDIR/shim"; mkdir -p "$S"; real="$(command -v git)"
    printf '#!/bin/bash\nl=""; for ((i = 0; i < ${GIT_CONFIG_COUNT:-0}; i++)); do k="GIT_CONFIG_KEY_$i"; v="GIT_CONFIG_VALUE_$i"; l+=" ${!k}=${!v}"; done\necho "$l G=$GIT_CONFIG_GLOBAL P=$GIT_ALLOW_PROTOCOL S=$GIT_CONFIG_NOSYSTEM" >> "%s/calls"\nexec "%s" "$@"\n' "$BATS_TEST_TMPDIR" "$real" > "$S/git"
    chmod +x "$S/git"
    # The fixture sets GIT_CONFIG_NOSYSTEM; unset, so the script's own setting is what the log shows (A17).
    unset GIT_CONFIG_NOSYSTEM
    PATH="$S:$PATH" chk "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "ok $B "* ]] || { show; return 1; }
    n="$(wc -l < "$BATS_TEST_TMPDIR/calls")"; [ "$n" -gt 10 ] || { echo "only $n calls logged"; return 1; }
    for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false G=/dev/null P=none S=1; do
        ! grep -v -- " $kv" "$BATS_TEST_TMPDIR/calls" || { echo "a call without $kv"; return 1; }
    done
}

@test "--status runs no repo-local textconv driver while it finds a brief's Status commit (C3, U2b1a i1)" {
    gated feat/x
    git config diff.x.textconv "touch $BATS_TEST_TMPDIR/textconv-ran; cat"
    printf '*.md diff=x\n' > .gitattributes
    run --separate-stderr bash "$BL" --status "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "ok $B open "* ]] || { show; return 1; }
    [ ! -e "$BATS_TEST_TMPDIR/textconv-ran" ] || { echo "textconv ran"; return 1; }
}

@test "--check's merge opens no submodule repository: a promisor one under .git/modules never fetches, and the moved gitlink is a conflict (U2b1a i2)" {
    gated feat/x
    s1="$(printf '%040d' 0 | tr 0 a)"; s2="${s1//a/b}"; s3="${s1//a/c}"
    printf '[submodule "sm"]\n\tpath = sub\n\turl = ./nowhere\n' > .gitmodules
    # Not commit_all: add -A would drop the gitlink, which has no directory (R9).
    git add .gitmodules; git update-index --add --cacheinfo "160000,$s1,sub"; git commit -q -m sub1
    git checkout -q feat/x; git merge -q main -m m1; git update-index --add --cacheinfo "160000,$s2,sub"; git commit -q -m sub2; git checkout -q main
    git update-index --add --cacheinfo "160000,$s3,sub"; git commit -q -m sub3
    git init -q --bare .git/modules/sm
    git -C .git/modules/sm config remote.origin.url "$BATS_TEST_TMPDIR/nowhere"
    git -C .git/modules/sm config remote.origin.uploadpack "touch $BATS_TEST_TMPDIR/fetched; git-upload-pack"
    git -C .git/modules/sm config remote.origin.promisor true
    git -C .git/modules/sm config extensions.partialClone origin
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: feat/x conflicts with the default branch" ] || { show; return 1; }
    [ ! -e "$BATS_TEST_TMPDIR/fetched" ] || { echo "upload-pack ran"; return 1; }
}

@test "--check merges in a SHA-256 repository: TIP and TREE are 64-hex (U2b1a i2)" {
    rm -rf .git && git init -q -b main --object-format=sha256 && git commit -q --allow-empty -m initial
    gated feat/x; t="$(git rev-parse feat/x)"
    chk "$B" --expect "$t"
    [ "$status" -eq 0 ] && [ "$output" = "ok $B $t $(git merge-tree --write-tree main feat/x)
path $B A work-feat-x.txt" ] && [ "${#t}" -eq 64 ] || { show; return 1; }
}

@test "--status runs no gpg.program for a signed brief commit and prints only a full commit id (U2b1a1 final security F1)" {
    brief x "Status: open" "Branch: feat/x"
    # main's tip, re-signed: a gpgsig header makes log.showSignature call gpg.program.
    c="$(git cat-file commit main | awk 'NR == 1 { print; print "gpgsig -----BEGIN PGP SIGNATURE-----"; print " x"; print " -----END PGP SIGNATURE-----"; next } { print }' | git hash-object -t commit -w --stdin)"
    git update-ref refs/heads/main "$c"
    printf '#!/bin/sh\ntouch "%s/gpg-ran"; echo INJECTED\n' "$BATS_TEST_TMPDIR" > "$BATS_TEST_TMPDIR/gpg"; chmod +x "$BATS_TEST_TMPDIR/gpg"
    git config log.showSignature true; git config gpg.program "$BATS_TEST_TMPDIR/gpg"
    run --separate-stderr bash "$BL" --status "$B"
    [ "$status" -eq 0 ] && [ "$output" = "ok $B open review feat/x absent - - 0" ] || { show; return 1; }
    run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-brief "$B"
    [ "$output" = "ok $B open $c" ] || { show; return 1; }
    [ ! -e "$BATS_TEST_TMPDIR/gpg-ran" ] || { echo "gpg.program ran"; return 1; }
}

# onx SNIPPET: feat/x rebuilt from main with one commit holding what SNIPPET
# (shell code, run on feat/x) changes.
onx() { git checkout -q -B feat/x main && eval "$1" && commit_all onx && git checkout -q main; }
# has LINE: the --check output holds exactly LINE.
has() { printf '%s\n' "$output" | grep -qxF -- "$1" || { echo "want: $1"; show; return 1; }; }
NOWN="one of the dev cycle's own files"
NUSER="the user's constraints doc, which every loop prompt carries"
NFORM="not an allowed path form (letters, digits and . _ - / only; no leading - or /; no empty, . or .. part; no part starting .git)"
NMODE="a symlink, gitlink or other non-file entry on one side (only modes 100644 and 100755 land)"
# nref K N: the verdict line refusing K of N changed paths in the merge of feat/x into main.
nref() { echo "refuse $B: $1 of $2 changed paths refused in the merge of $(git rev-parse feat/x) (tree $(git merge-tree --write-tree main feat/x))"; }
NBRIEF="this brief: only its first Status: line outside a fence may change, from open to done"

@test "--check lists every changed path and refuses the dev cycle's own files, other briefs and the constraints doc in any case; other paths pass (T14, F2, F12, F54, U2b1b)" {
    brief other "Status: open" "Branch: feat/o"; o="$B"
    mkdir -p docs/working && echo r > docs/roadmap.md && commit_all roadmap
    gated feat/x
    fs=(docs/roadmap.md docs/working/questions.md docs/working/questions-archive.md docs/working/idea-log.md
        docs/working/cycles/cycle-2026-10-01.md docs/working/cycles/notes.md docs/dev-cycle.md "$o"
        docs/working/briefs/2026-10-02-new.md docs/working/briefs/closed/x Docs/Roadmap.md docs/Dev-Cycle.md docs/working/Questions.md)
    onx 'mkdir -p docs/working/briefs/closed docs/working/cycles Docs; for f in "${fs[@]}" docs/constraints.md docs/CONSTRAINTS.md docs/ok.md; do echo x > "$f"; done'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 15 16)" ] && [ "${#lines[@]}" -eq 17 ] || { show; return 1; }
    has "deny $B M docs/roadmap.md: $NOWN"
    for f in "${fs[@]:1}"; do [[ "$f" == "$o" ]] && m=M || m=A; has "deny $B $m $f: $NOWN"; done
    has "deny $B A docs/constraints.md: $NUSER"; has "deny $B A docs/CONSTRAINTS.md: $NUSER"
    has "path $B A docs/ok.md"
    # The paths come in diff-tree order, after the verdict.
    [ "${lines[1]}" = "deny $B A Docs/Roadmap.md: $NOWN" ] && [ "${lines[16]}" = "deny $B A docs/working/questions.md: $NOWN" ] || { show; return 1; }
    # A branch whose changes main already holds merges to main's own tree: ok, no path line.
    onx 'echo x > docs/ok.md'; git checkout -q -B main feat/x; git checkout -q -B feat/x main; git commit -q --allow-empty -m e; git checkout -q main
    chk "$B"
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 1 ] && [[ "${lines[0]}" == "ok $B "* ]] || { show; return 1; }
}

@test "--check: the brief's own file may change only its first Status: line outside a fence, open to done (T15, F13, U2b1b)" {
    brief x '```' 'Status: open' '```' 'Status: open' 'Branch: feat/x'
    printf 'Status: open\r\nBranch: feat/c\n' > docs/working/briefs/2026-10-01-crlf.md && commit_all crlf
    # Lines: 1 title, 2 blank, 3-5 a fence holding a Status line, 6 the Status line, 7 Branch.
    onx 'sed -i "6s/open/done/" "$B"'
    chk "$B"
    [ "$status" -eq 0 ] && [ "${lines[1]}" = "path $B M $B" ] && [ "${#lines[@]}" -eq 2 ] || { show; return 1; }
    for s in 'sed -i "4s/open/done/" "$B"' 'sed -i "6s/open/dropped/" "$B"' 'sed -i "6s/open/done/" "$B"; echo "Paths: docs/" >> "$B"' \
             'sed -i "6s/open/done/" "$B"; chmod +x "$B"' 'sed -i "6s/open/done/" "$B"; echo "" >> "$B"'; do
        onx "$s"
        chk "$B"
        [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 1 1)" ] && has "deny $B M $B: $NBRIEF" || { echo "snippet: $s"; return 1; }
    done
    onx 'mkdir -p docs/working/briefs/closed; git mv "$B" docs/working/briefs/closed/'
    chk "$B"
    [ "$status" -eq 2 ] && has "deny $B D $B: $NBRIEF" && has "deny $B A docs/working/briefs/closed/2026-10-01-x.md: $NOWN" || return 1
    # A CRLF brief keeps its CR: only "Status: done\r" matches.
    c=docs/working/briefs/2026-10-01-crlf.md
    git checkout -q -B feat/c main; printf 'Status: done\r\nBranch: feat/c\n' > "$c"; commit_all c; git checkout -q main
    chk "$c"
    [ "$status" -eq 0 ] && [ "${lines[1]}" = "path $c M $c" ] || { show; return 1; }
}

@test "--check: a rename is its two sides, so moving a cycle file out refuses its old path (T11, F6, U2b1b)" {
    mkdir -p docs && echo r > docs/roadmap.md && commit_all roadmap
    gated feat/x
    onx 'git mv docs/roadmap.md docs/x.md'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 1 2)" ] || { show; return 1; }
    has "deny $B D docs/roadmap.md: $NOWN"; has "path $B A docs/x.md"
}

@test "--check refuses a symlink or gitlink on either side, though submodule ignore=all is set, and passes an exec bit (T12, F7, A16, U2b1b)" {
    mkdir -p scripts && echo a > f.txt && echo b > g.txt && echo s > scripts/x.sh
    # ignore = all in .gitmodules and the repo config: diff-tree in the real repository without
    # --ignore-submodules=none would hide gl (A16). The gate repository and the flag each suffice, so this pins them together.
    printf '[submodule "gl"]\n\tpath = gl\n\turl = ./x\n\tignore = all\n[submodule "og"]\n\tpath = og\n\turl = ./x\n\tignore = all\n' > .gitmodules
    commit_all files; git config submodule.gl.ignore all; git config submodule.og.ignore all
    ln -s f.txt was-link && commit_all link
    gated feat/x
    git update-index --add --cacheinfo "160000,$(git rev-parse main),og"; git commit -q -m old-gitlink
    onx 'git rm -q --cached og; rmdir og 2>/dev/null || true; echo f > og; ln -s f.txt link; rm g.txt; ln -s f.txt g.txt; rm was-link; echo w > was-link; chmod +x scripts/x.sh; echo n > scripts/n.sh; chmod +x scripts/n.sh'
    git checkout -q feat/x; git update-index --add --cacheinfo "160000,$(git rev-parse main),gl"; git commit -q -m gitlink; git checkout -q main
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 5 7)" ] || { show; return 1; }
    for p in "T g.txt" "A gl" "A link" "T og" "T was-link"; do has "deny $B $p: $NMODE"; done
    has "path $B A scripts/n.sh"; has "path $B M scripts/x.sh"
}

@test "--check refuses a changed path pathform refuses, and prints only a name in its character set (T13, F17, U2b1b)" {
    gated feat/x
    onx 'mkdir -p .github; echo x > .github/w.yml; echo x > "a b.md"; echo x > "$(printf "caf\xc3\xa9.md")"; echo x > "$(printf "n\nl.md")"; echo x > ./-x.md'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 5 5)" ] && [ "${#lines[@]}" -eq 6 ] || { show; return 1; }
    has "deny $B A -x.md: $NFORM"; has "deny $B A .github/w.yml: $NFORM"
    [ "$(printf '%s\n' "$output" | grep -cxF "deny $B A ?: $NFORM")" -eq 3 ] || { show; return 1; }
}

@test "--check refuses a merge git warned about or that names a missing object: a missing tip or merge-base tree is not read as empty, a missing blob does not land (R6, U2b1b)" {
    echo base > f.txt && commit_all f
    gated feat/x
    o="$(git rev-parse "feat/x^{tree}")"; mv ".git/objects/${o:0:2}/${o:2}" "$BATS_TEST_TMPDIR/tree"
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: the merge of feat/x could not be computed" ] || { show; return 1; }
    mv "$BATS_TEST_TMPDIR/tree" ".git/objects/${o:0:2}/${o:2}"
    # merge-tree reads a missing top-level tree as empty and warns, exiting 0 when that merge is otherwise
    # clean (a missing subtree or blob it must read is fatal; one it passes by id is silent: the case below).
    onx 'echo b > b.txt'; echo m > m.txt && commit_all m
    o="$(git rev-parse "main~1^{tree}")"; rm ".git/objects/${o:0:2}/${o:2}"
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: the merge of feat/x could not be computed" ] || { show; return 1; }
    # A blob the store lacks, which merge-tree passes by id without reading (security F2).
    rm -rf .git && git init -q -b main && git commit -q --allow-empty -m initial && gated feat/x
    b="$(echo absent | git hash-object --stdin)"
    tip feat/x "add" "$( (git ls-tree main; printf '100644 blob %s\tnew.txt\n' "$b") | git mktree --missing)" "$(git rev-parse main)"
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: the merge of feat/x names a blob the object store lacks" ] || { show; return 1; }
}

@test "--check refuses an ambiguous default branch: both main and master, or origin/HEAD naming a branch the gate did not take (R7, U2b1b)" {
    gated feat/x
    git branch master feat/x; git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state default-branch: both main and master exist" ] || { show; return 1; }
    git symbolic-ref --delete refs/remotes/origin/HEAD
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state default-branch: both main and master exist" ] || { show; return 1; }
    # Both findings at once: a master ref that names no commit is not taken, so origin/HEAD disagrees too.
    git rev-parse "main^{tree}" > .git/refs/heads/master; git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master  # git refuses to write it
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state default-branch: both main and master exist
refuse state default-branch: origin/HEAD names origin/master, but the default branch taken is main" ] || { show; return 1; }
    rm .git/refs/heads/master
    git branch -m main master; git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state default-branch: origin/HEAD names origin/main, but the default branch taken is master" ] || { show; return 1; }
}

@test "--check's merge reads no submodule repository: a gitlink fast-forward the real repository would merge is a conflict (R9, U2b1b)" {
    git init -q --bare .git/modules/sm; e="$(git -C .git/modules/sm hash-object -t tree -w --stdin < /dev/null)"
    w="$(git -C .git/modules/sm commit-tree "$e" -m w)"; x="$(git -C .git/modules/sm commit-tree "$e" -p "$w" -m x)"; y="$(git -C .git/modules/sm commit-tree "$e" -p "$x" -m y)"
    # The brief first: commit_all's add -A would drop a gitlink that has no directory.
    brief x "Status: open" "Branch: feat/x"
    printf '[submodule "sm"]\n\tpath = sub\n\turl = ./nowhere\n' > .gitmodules
    git add .gitmodules; git update-index --add --cacheinfo "160000,$w,sub"; git commit -q -m base
    git branch feat/x main
    git update-index --cacheinfo "160000,$x,sub"; git commit -q -m main-x
    git checkout -q feat/x; git update-index --cacheinfo "160000,$y,sub"; git commit -q -m branch-y; git checkout -q main
    # The real repository opens .git/modules/sm and fast-forwards x to y: the case gate_repo must not reach.
    git merge-tree --write-tree main feat/x > /dev/null || { echo "fixture: the real repository did not merge"; return 1; }
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: feat/x conflicts with the default branch" ] || { show; return 1; }
}

@test "--check runs its state gate before resolve_main reads an object: every commit read follows the gate's last call, and a planted key refuses even with main's commit missing (A15, U2b1b)" {
    gated feat/x
    # A shim logs each git call in order; resolve_main's first object read is a rev-parse of SHA^{commit}.
    S="$BATS_TEST_TMPDIR/shim"; mkdir -p "$S"; real="$(command -v git)"
    printf '#!/bin/bash\necho "$*" >> "%s/calls"\nexec "%s" "$@"\n' "$BATS_TEST_TMPDIR" "$real" > "$S/git"; chmod +x "$S/git"
    PATH="$S:$PATH" chk "$B"
    [ "$status" -eq 0 ] || { show; return 1; }
    g="$(grep -n -m1 -F 'for-each-ref --format=%(refname) refs/replace/' "$BATS_TEST_TMPDIR/calls" | cut -d: -f1)"
    r="$(grep -n -m1 -F '^{commit}' "$BATS_TEST_TMPDIR/calls" | cut -d: -f1)"
    [ -n "$g" ] && [ -n "$r" ] && [ "$g" -lt "$r" ] || { echo "gate call at line $g, first commit read at line $r"; cat "$BATS_TEST_TMPDIR/calls"; return 1; }
    git config merge.x.driver true
    o="$(git rev-parse main)"; rm ".git/objects/${o:0:2}/${o:2}"
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state merge.x.driver: set in config, it can make the gate's git run a command or change its merge" ] || { show; return 1; }
}

# sm: self-merge on, brief x (self-merge, naming feat/x) and feat/x with one commit; B is its path.
sm() { settings "Build-loop policy: self-merge" "Self-merge never: none"; brief x "Status: open" "Branch: feat/x" "Policy: self-merge"; work feat/x; }
CO="a self-merge brief needs --check run from a clean checkout of the default branch's commit"
# coref WHY: --check refused brief x for its checkout, with WHY, and still listed
# feat/x's one changed path. cook: --check passed it.
coref() {
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: $CO; $1" ] && [ "${lines[1]}" = "path $B A work-feat-x.txt" ] && [ "${#lines[@]}" -eq 2 ] \
        && [ -z "$stderr" ] || { echo "want: $1"; show; return 1; }
}
cook() { chk "$B"; [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $B "* ]] && [ -z "$stderr" ] || { show; return 1; }; }
IDX="the checkout's index marks entries skip-worktree, assume-unchanged or unmerged"
STAT="the checkout's index or tracked files differ from that commit (git status)"
ENVS="is set, so git can read another work tree, index, object store or config file"

@test "--check refuses a self-merge brief unless it runs from a clean checkout of main: HEAD, env, config, index bits, status, nested repositories (contract item 2, U2b2)" {
    sm; echo a > docs/a.md && commit_all a
    # Untracked and ignored files are allowed: the walk reads them as they are.
    echo '*.local.md' > .git/info/exclude; echo x > CLAUDE.local.md; echo y > untracked.md
    cook
    git checkout -q --detach HEAD~1
    coref "the checkout's HEAD is $(git rev-parse HEAD), not the default branch's commit $(git rev-parse main)"; git checkout -q main
    echo b >> docs/a.md; coref "$STAT"; git checkout -q -- docs/a.md
    echo n > new.md; git add new.md; coref "$STAT"; git rm -q --cached new.md
    # Each index flag hides the change from git status.
    echo c >> docs/a.md; git update-index --assume-unchanged docs/a.md
    [ -z "$(git status --porcelain --untracked-files=no)" ]; coref "$IDX"
    git update-index --no-assume-unchanged docs/a.md; git checkout -q -- docs/a.md
    git update-index --skip-worktree docs/a.md; echo d >> docs/a.md
    [ -z "$(git status --porcelain --untracked-files=no)" ]; coref "$IDX"
    git update-index --no-skip-worktree docs/a.md; git checkout -q -- docs/a.md
    cook
    git config core.symlinks false; coref "core.symlinks is false: a symlink is checked out as a file holding its text"; git config --unset core.symlinks
    git config core.ignoreCase true; coref "core.ignoreCase is true: a case-insensitive checkout"; git config core.ignoreCase false
    git config core.sparseCheckout true; coref "core.sparseCheckout is true: a sparse checkout"; git config --unset core.sparseCheckout
    cook
    # A repo-local variable refuses, GIT_CONFIG (a whole config file) too; the caller's config pairs do not.
    GIT_INDEX_FILE="$PWD/.git/index" coref "GIT_INDEX_FILE $ENVS"
    GIT_WORK_TREE="$PWD" coref "GIT_WORK_TREE $ENVS"
    printf '[core]\n\tsymlinks = true\n' > "$BATS_TEST_TMPDIR/cfg"; GIT_CONFIG="$BATS_TEST_TMPDIR/cfg" coref "GIT_CONFIG $ENVS"
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=x cook
    git init -q nested; coref "the checkout holds an untracked nested repository, whose instruction files the walk does not read"; rm -rf nested
    cook
}

@test "--check refuses a self-merge brief whose checked-out bytes are not main's blob though git status is clean: ident and eol attributes, a non-UTF-8 name under a UTF-8 locale (contract item 3, row 397, U2b2 i1 security 2)" {
    sm; mkdir -p docs
    WHY="a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)"
    printf 'see @docs/x$Id$\n' > docs/i.md; printf 'docs/i.md ident\n' > .gitattributes; commit_all ident
    rm docs/i.md; git checkout -q -- docs/i.md
    grep -q 'Id: ' docs/i.md && [ -z "$(git status --porcelain)" ] || { cat docs/i.md; git status; return 1; }
    coref "$WHY"
    printf 'docs/i.md eol=crlf\n' > .gitattributes; commit_all crlf
    rm docs/i.md; git checkout -q -- docs/i.md
    [ -z "$(git status --porcelain)" ] || { git status; return 1; }
    coref "$WHY"
    git rm -q .gitattributes; commit_all plain; rm docs/i.md; git checkout -q -- docs/i.md
    cook
    # A name that is not UTF-8, read under a UTF-8 locale: the record is still compared.
    n=$'docs/\xff.md'; printf 'see @docs/x$Id$\n' > "$n"; printf 'docs/*.md ident\n' > .gitattributes; commit_all latin
    rm "$n"; git checkout -q -- "$n"
    [ -z "$(git status --porcelain)" ] || { git status; return 1; }
    LC_ALL=C.utf8 coref "$WHY"
}

@test "--check refuses a self-merge brief when main holds a file name hash-object reads as another: a leading quote, a trailing CR (U2b2 i1 security 1)" {
    sm
    NAME="a file on the default branch has a name the byte comparison cannot read (a newline, a leading quote or a trailing CR)"
    echo q > '"q"'; commit_all quote; coref "$NAME"
    git rm -q '"q"'; commit_all unquote; cook
    echo r > $'r\r'; commit_all cr; coref "$NAME"
    git rm -q $'r\r'; commit_all uncr; cook
    # A newline in a name is read as one index entry, so the name rule names it (final fact-check claim 14).
    echo n > $'n\nl'; commit_all nl; coref "$NAME"
}

@test "--check judges a review brief without its checkout, and a self-merge brief's checkout after its paths, so a loop's advisory run from its branch still lists them (U2b2 i1 api F1, architecture F2)" {
    sm; settings "Build-loop policy: review"
    echo d > dirty.txt; git add dirty.txt; git checkout -q --detach HEAD~1
    cook
    git checkout -q main; git rm -q --cached dirty.txt; rm dirty.txt
    settings "Build-loop policy: self-merge" "Self-merge never: none"
    cook
    # On feat/x itself, as a loop runs it: the refusal, then every path line, a deny among them.
    git checkout -q feat/x; mkdir -p docs; echo r > docs/roadmap.md; commit_all roadmap
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: $CO; the checkout's HEAD is $(git rev-parse feat/x), not the default branch's commit $(git rev-parse main)" ] \
        && [ "${#lines[@]}" -eq 3 ] || { show; return 1; }
    has "deny $B A docs/roadmap.md: $NOWN"; has "path $B A work-feat-x.txt"
}

@test "--check refuses a self-merge brief when a gitlink's path holds files, is a symlink or cannot be listed (rows 366, 373, U2b2 i1 security 3)" {
    sm; settings "Build-loop policy: self-merge" "Self-merge never: none"
    # A gitlink on main: an empty directory there passes (git status reports an absent one).
    git update-index --add --cacheinfo "160000,$(git rev-parse HEAD),sub"; git commit -q -m gitlink
    mkdir sub; cook
    echo '@../docs/x.md' > sub/CLAUDE.md
    coref "a gitlink is checked out with files, whose instruction files the walk does not read"
    LINK="a gitlink's path in the checkout is a symlink or cannot be listed"
    chmod 111 sub; coref "$LINK"; chmod 755 sub
    rm -rf sub; mkdir "$BATS_TEST_TMPDIR/elsewhere"; ln -s "$BATS_TEST_TMPDIR/elsewhere" sub
    # git status already fails on a symlink there (exit 128), before the gitlink rule reads it.
    coref "git status failed or warned in the checkout"
}

# U2b3a, the reader model's roots and homes (plan step 5): a session reading the
# repo from another checkout or HOME resolves names the gate's own root does not.

@test "both walks read an absolute name into another worktree of the repo as that repo path, as the gate runs from its own worktree (U2b3a)" {
    mkdir -p docs && r="$(pwd -P)"
    printf 'See @%s/docs/abs.md\n' "$r" > AGENTS.md; echo x > docs/abs.md; commit_all abs
    git worktree add -q --detach ../gate && cd ../gate
    for w in tree main; do
        imps "$w" docs/abs.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/abs.md imported; want docs/other.md -
    done
}

@test "both walks resolve a relative name against every worktree's directory, so it can re-enter a nested or sibling worktree (U2b3a; rows 425, 432)" {
    mkdir -p docs && echo n > docs/n.md && echo s > docs/s.md
    # From the main checkout, .claude/wt-b/ is a nested worktree; from wt-b, ../side/ is its sibling.
    printf 'See @.claude/wt-b/docs/n.md and @../side/docs/s.md\n' > AGENTS.md; commit_all rel
    git worktree add -q --detach .claude/wt-b; git worktree add -q --detach .claude/side
    git worktree add -q --detach ../gate && cd ../gate
    for w in tree main; do
        imps "$w" docs/n.md docs/s.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/n.md imported; want docs/s.md imported; want docs/other.md -
    done
}

@test "the caller's reader roots and homes add the host checkout's spellings, and the environment does not set them (U2b3a; rows 425, 437; Q-121, Q-123; i1 architecture F2)" {
    mkdir -p docs
    printf 'See @~/cw/docs/h.md and @/host/cw/docs/a.md\n' > AGENTS.md; commit_all host
    for w in tree main; do
        imps "$w" docs/h.md docs/a.md
        want walk ok; want docs/h.md -; want docs/a.md -
        T_READER_ROOTS=/host/cw T_READER_HOMES=/host imps "$w" docs/h.md docs/a.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/h.md imported; want docs/a.md imported
        # Inherited, they are cleared when the lib is sourced (contract item 9).
        IMPORT_READER_ROOTS=/host/cw IMPORT_READER_HOMES=/host imps "$w" docs/h.md docs/a.md
        want walk ok; want docs/h.md -; want docs/a.md -
    done
}

@test "a root nested in another at a non-dot path keeps the outer path's names: a stale registry entry or a caller root inside the repo (U2b3a i1 security 1, architecture F1)" {
    mkdir -p docs && r="$(pwd -P)"
    printf 'See @%s/sub/x.md\n' "$r" > AGENTS.md; commit_all nest
    # A worktree at sub/ whose directory was then removed: git lists it as prunable.
    git worktree add -q --detach sub && rm -rf sub
    git worktree list --porcelain | grep -qxF "worktree $r/sub" || { git worktree list --porcelain; return 1; }
    for w in tree main; do
        imps "$w" sub/x.md x.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want sub/x.md imported; want x.md imported; want docs/other.md -
    done
    # The same nesting from a caller root, as written and through a symlink, with the stale entry pruned.
    git worktree prune; ! git worktree list --porcelain | grep -qxF "worktree $r/sub" || return 1
    ln -s "$r/sub" "$BATS_TEST_TMPDIR/lnk"
    for w in tree main; do
        imps "$w" sub/x.md x.md; want walk ok; want sub/x.md imported; want x.md -
        for c in "$r/sub" "$BATS_TEST_TMPDIR/lnk"; do
            T_READER_ROOTS="$c" imps "$w" sub/x.md x.md
            want walk ok; want sub/x.md imported; want x.md imported
        done
    done
    # dotnest omits only paths truthrule refuses as dot paths (security i2 2): a dot-nested spelling is one.
    run --separate-stderr bash -c 'source "$1"; for p in .claude/wt-a/sub/y.md docs/.wt/a/q.md; do truthrule "$p"; echo "$p $TRUTH_WHY"; done' _ "$LIB"
    [ "${lines[0]}" = ".claude/wt-a/sub/y.md dot" ] && [ "${lines[1]}" = "docs/.wt/a/q.md dot" ] || { echo "$output $stderr"; return 1; }
}

@test "both walks fail closed on a reader root or home they cannot model, and when git worktree list fails (U2b3a; i1 fact-check 18)" {
    mkdir -p docs && printf 'See @docs/a.md\n' > AGENTS.md && commit_all bad
    for w in tree main; do
        for v in "T_READER_ROOTS=rel/cw" "T_READER_ROOTS=/" "T_READER_ROOTS=//" "T_READER_ROOTS=/x/.." "T_READER_HOMES=rel" \
                 "T_READER_HOMES=/x/.." "T_READER_ROOTS=/a"$'\n'"rel" "T_READER_HOMES=/h"$'\n'"rel"; do
            export "${v?}"; imps "$w" docs/a.md docs/other.md; unset T_READER_ROOTS T_READER_HOMES
            want walk failed; want docs/other.md imported
        done
        # Blank lines between entries are skipped, not refused.
        T_READER_ROOTS=$'/a\n\n/b\n' imps "$w" docs/a.md; want walk ok
    done
    # An empty ROOT_REAL is refused, not skipped, so a registered worktree never leads the roots (final fact-check 1).
    run --separate-stderr bash -c 'source "$1"; ROOT_REAL=""; import_readers; echo "rc=$? [$IMPORT_ROOTS]"' _ "$LIB"
    [ "$output" = "rc=1 []" ] || { echo "$output $stderr"; return 1; }
    S="$BATS_TEST_TMPDIR/wt" && mkdir -p "$S"
    printf '#!/bin/sh\n[ "$1" = worktree ] && exit 1\nexec %s "$@"\n' "$(command -v git)" > "$S/git" && chmod +x "$S/git"
    for w in tree main; do
        PATH="$S:$PATH" imps "$w" docs/a.md docs/other.md
        want walk failed; want docs/other.md imported
    done
}

@test "a HOME holding a newline fails a walk only when a ~/ name needs it, as a relative HOME does (U2b3a i1 fact-check E1, api F3)" {
    mkdir -p docs && printf 'See @docs/a.md\n' > AGENTS.md && commit_all plain
    for w in tree main; do
        HOME="$BATS_TEST_TMPDIR/h"$'\n'"x" imps "$w" docs/a.md docs/other.md
        want walk ok; want docs/a.md imported; want docs/other.md -
    done
    printf 'See @~/x.md and @docs/a.md\n' > AGENTS.md && commit_all tilde
    # The walk fails, and a failed walk answers imported for every path (fail closed).
    for w in tree main; do
        HOME="$BATS_TEST_TMPDIR/h"$'\n'"x" imps "$w" docs/a.md docs/other.md
        want walk failed; want docs/other.md imported
    done
}

@test "a worktree path holding a newline fails both walks (U2b3a)" {
    mkdir -p docs && printf 'See @docs/a.md\n' > AGENTS.md && commit_all nl
    git worktree add -q --detach "$BATS_TEST_TMPDIR/a"$'\n'"b" || skip "git refused a worktree path holding a newline"
    for w in tree main; do
        imps "$w" docs/a.md docs/other.md
        want walk failed; want docs/other.md imported
    done
}

@test "both walk caches key on the reader set, which is read once until import_reset (U2b3a; row 437; i1 performance F1, architecture F6)" {
    mkdir -p docs && printf 'See @/host/cw/docs/a.md and @~/cw/docs/h.md and @%s/docs/w.md\n' "$BATS_TEST_TMPDIR/late" > AGENTS.md && commit_all key
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"
        resolve_main || true; ROOT_REAL="$(pwd -P)"
        for w in tree main; do
            import_reset; IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""
            isimported "$w" docs/a.md && echo "$w a0: imported" || echo "$w a0: -"
            IMPORT_READER_ROOTS=/host/cw
            isimported "$w" docs/a.md && echo "$w a1: imported" || echo "$w a1: -"
            isimported "$w" docs/h.md && echo "$w h1: imported" || echo "$w h1: -"
            IMPORT_READER_HOMES=/host
            isimported "$w" docs/h.md && echo "$w h2: imported" || echo "$w h2: -"
            # A worktree added mid-decision is seen only after import_reset.
            [[ $w == main ]] || git worktree add -q --detach "$2/late"
            isimported "$w" docs/w.md && echo "$w w1: imported" || echo "$w w1: -"
            import_reset
            isimported "$w" docs/w.md && echo "$w w2: imported" || echo "$w w2: -"
        done' _ "$LIB" "$BATS_TEST_TMPDIR"
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    for w in tree main; do want "$w a0" -; want "$w a1" imported; want "$w h1" -; want "$w h2" imported; want "$w w2" imported; done
    want "tree w1" -
}

# U2b3b1, the reader settings (plan step 5): main's docs/dev-cycle.md names the
# host readers, and both walks take them through reader_settings.

@test "both walks take the reader lists from main's docs/dev-cycle.md, never the working tree, and a malformed line fails them (U2b3b1; H4)" {
    mkdir -p docs
    printf 'See @~/cw/docs/h.md and @/host/cw/docs/a.md and @/wt/docs/w.md\n' > AGENTS.md; commit_all host
    for w in tree main; do
        T_SETTINGS=1 imps "$w" docs/h.md docs/a.md; want walk ok; want docs/h.md -; want docs/a.md -
    done
    settings 'Reader roots: /host/cw' '' 'Reader homes: /host'
    # A root only the working tree's copy names is not read.
    printf 'Reader roots: /host/cw /wt\n\nReader homes: /host\n' > docs/dev-cycle.md
    for w in tree main; do
        T_SETTINGS=1 imps "$w" docs/h.md docs/a.md docs/w.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/h.md imported; want docs/a.md imported; want docs/w.md -; want docs/other.md -
    done
    git checkout -q docs/dev-cycle.md
    # A malformed line (or a second copy) fails both walks, which then answer imported for every path.
    for v in 'Reader roots: host/cw' $'Reader roots: /host/cw\n\n**Reader roots:** /wt'; do
        settings "$v"
        for w in tree main; do
            T_SETTINGS=1 imps "$w" docs/a.md docs/other.md
            want walk failed; want docs/other.md imported
        done
    done
    # The floor names the cause (U2b3b1 i1 api-consistency F1).
    T_SETTINGS=1 floors 2026-10-01-x A docs/other.md
    want docs/other.md "the default branch's instruction files could not be walked for @ imports: the reader settings of docs/dev-cycle.md cannot be used: more than one line starts \"Reader roots:\" (lines 1 and 3)"
    # Refused settings fail import_targets outside a walk too, which reads no memo (i1 security F2).
    run --separate-stderr bash -c 'source "$1"; ROOT_REAL="$(pwd -P)"; IMPORT_READER_WHY=x; printf "@docs/a.md\n" | import_targets ""; echo "rc=$?"' _ "$LIB"
    [ "$output" = "rc=1" ] || { echo "$output $stderr"; return 1; }
}

@test "a caller root re-spells the worktrees registered beneath the main worktree (U2b3b1; U2b3a i1 architecture F4)" {
    mkdir -p docs && echo n > docs/n.md
    printf 'See @/host/cw/.claude/wt-b/docs/n.md\n' > AGENTS.md; commit_all respell
    git worktree add -q --detach .claude/wt-b
    git worktree add -q --detach ../gate && cd ../gate
    for w in tree main; do
        imps "$w" docs/n.md; want walk ok; want docs/n.md -
        T_READER_ROOTS=/host/cw imps "$w" docs/n.md docs/other.md
        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
        want walk ok; want docs/n.md imported; want docs/other.md -
    done
    # The other way: a worktree registered beneath a caller root (a host session's) is spelled beneath main's (final security F2).
    m="$(cd ../repo && pwd -P)"; printf 'See @%s/.claude/wt-h/docs/n.md\n' "$m" > ../repo/AGENTS.md
    git -C ../repo commit -qam back && git worktree add -q --detach "$BATS_TEST_TMPDIR/host/cw/.claude/wt-h" && git checkout -q --detach main
    for w in tree main; do
        T_READER_ROOTS="$BATS_TEST_TMPDIR/host/cw" imps "$w" docs/n.md; want walk ok; want docs/n.md imported
    done
}

@test "a refused reader set is memoized, so a decision lists the worktree registry once (U2b3b1; U2b3a final performance F1)" {
    mkdir -p docs && printf 'See @docs/a.md\n' > AGENTS.md && commit_all memo
    S="$BATS_TEST_TMPDIR/stub" && mkdir -p "$S"
    printf '#!/bin/sh\n[ "$1" = worktree ] && echo x >> %s/log\nexec %s "$@"\n' "$S" "$(command -v git)" > "$S/git" && chmod +x "$S/git"
    for w in tree main; do
        : > "$S/log"
        # The walk, then isimported for each path: three calls of the walk in one decision.
        PATH="$S:$PATH" T_READER_ROOTS=rel imps "$w" docs/a.md docs/other.md
        want walk failed; want docs/other.md imported
        [ "$(wc -l < "$S/log")" -eq 1 ] || { echo "$w: $(wc -l < "$S/log") listings"; return 1; }
    done
}
