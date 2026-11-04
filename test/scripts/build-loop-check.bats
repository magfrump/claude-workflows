#!/usr/bin/env bats
# @category fast
# Contract tests for the build-loop gate: the reader lib's import walks
# (scripts/lib/dev-cycle-read.sh isimported, import_targets, main_imports,
# imported_names: plain @path imports since brief 2026-11-03-import-walk-plain)
# and, from U2a4 and U2b, the self-merge floor and build-loop.sh --check.
# Each test builds a throwaway repo under $BATS_TEST_TMPDIR
# (test/lib/build-loop-fixtures.bash); this repo is untouched.

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() { bl_setup; LIB="$REPO_ROOT/scripts/lib/dev-cycle-read.sh"; }

# imps WALK PATH...: in the fixture repo with main resolved and ROOT_REAL set,
# "walk: ok" or "walk: failed" (main_imports' or imported_names' return) and
# "why: WORD" (the walk's IMPORTED_MAIN_WHY or IMPORTED_WHY), then
# "PATH: imported" or "PATH: -" from isimported WALK for each path.
imps() {
    # timeout: a walk that never ends (an import cycle it does not stop) fails the test.
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
        resolve_main || true; ROOT_REAL="$(pwd -P)"; w="$1"; shift
        if { [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }; then echo "walk: ok"; else echo "walk: failed"; fi
        if [[ "$w" == main ]]; then echo "why: $IMPORTED_MAIN_WHY"; else echo "why: $IMPORTED_WHY"; fi
        for p in "$@"; do if isimported "$w" "$p"; then echo "$p: imported"; else echo "$p: -"; fi; done' _ "$LIB" "$@"
}
# want PATH WORD: the imps output holds exactly "PATH: WORD" (want walk ok|failed, want why WORD).
want() { printf '%s\n' "$output" | grep -qxF "$1: $2" || { echo "want: $1: $2"; echo "$output $stderr"; return 1; }; }
# floors STEM STATUS PATH...: the lib's floor for each path, as imps runs the
# walks; one "PATH: WHY" or "PATH: -" line each, read with want.
floors() {
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
        resolve_main || true; ROOT_REAL="$(pwd -P)"; s="$1"; st="$2"; shift 2
        for p in "$@"; do if floor "$p" "$s" "$st"; then echo "$p: $(floor_why "$FLOOR_WHY")"; else echo "$p: -"; fi; done' _ "$LIB" "$@"
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
READWHY="could not be read, is larger than 4 MiB or not valid UTF-8, or names ~/ while HOME is not an absolute path"
LINKWHY="is a symlink or lies below one, which the walk does not follow"

@test "both walks read plain @path imports, direct and transitive: a token ends at a blank, trailing punctuation is also stripped, and .. or absolute names that land in the repo count; a name outside it is dropped (brief 2026-11-03-import-walk-plain)" {
    mkdir -p docs/sub
    printf 'Rules: @docs/a.md, and (see @docs/sub/b.md).\nmail t@example.invalid\n' > CLAUDE.md
    printf 'Next:\t@c.md\r\n' > docs/a.md
    printf 'Up: @../../docs/d.md and @%s/docs/e.md and @/etc/passwd and @../../../outside.md\n' "$(pwd -P)" > docs/sub/b.md
    for f in c d e other; do printf 'leaf\n' > "docs/$f.md"; done
    commit_all imports
    for w in main tree; do
        imps "$w" docs/a.md docs/sub/b.md docs/c.md docs/d.md docs/e.md example.invalid DOCS/A.MD docs/other.md CLAUDE.md outside.md
        want walk ok; want why ""
        for p in docs/a.md docs/sub/b.md docs/c.md docs/d.md docs/e.md example.invalid DOCS/A.MD; do want "$p" imported; done
        # A start answers imported only when an import reaches it; ../../../outside.md lands outside the repo.
        want docs/other.md -; want CLAUDE.md -; want outside.md -
    done
}

@test "main walk: main's start files decide, untracked and ignored start files at any depth add imports, and the checkout is read only where main lacks a path (brief 2026-11-03-import-walk-plain; G55, G56)" {
    mkdir -p docs sub
    printf '@docs/a.md @docs/new.md\n' > CLAUDE.md
    printf '@b.md\n' > docs/a.md
    printf 'CLAUDE.local.md\n' > .gitignore
    commit_all base
    # Working-tree edits of files main stores do not count; untracked files do.
    printf '@docs/wt.md\n' > CLAUDE.md; printf '@wt2.md\n' > docs/a.md
    printf '@docs/local.md\n' > CLAUDE.local.md; printf '@deep.md\n' > sub/AGENTS.md
    printf '@more.md\n' > docs/new.md
    imps main docs/a.md docs/b.md docs/new.md docs/more.md docs/local.md sub/deep.md docs/wt.md docs/wt2.md
    want walk ok
    for p in docs/a.md docs/b.md docs/new.md docs/more.md docs/local.md sub/deep.md; do want "$p" imported; done
    want docs/wt.md -; want docs/wt2.md -
    # The tree walk reads the checkout as it is.
    imps tree docs/wt.md docs/wt2.md docs/a.md docs/local.md sub/deep.md
    want walk ok
    for p in docs/wt.md docs/local.md sub/deep.md; do want "$p" imported; done
    want docs/wt2.md -; want docs/a.md -
}

@test "both walks fail closed, so every path reads as imported, on an imported file that is not valid UTF-8, holds a NUL, is larger than 4 MiB or cannot be read; a file of exactly 4 MiB is read (brief 2026-11-03-import-walk-plain; G59, G60; H2)" {
    mkdir -p docs
    printf '@docs/a.md\n' > CLAUDE.md; printf 'ok\n' > docs/a.md; commit_all base
    for c in latin nul big; do
        case "$c" in
            latin) printf 'caf\xe9 @docs/z.md\n' > docs/a.md ;;
            nul) printf 'a\0b\n' > docs/a.md ;;
            big) yes aaaaaaaaa | head -c 4194305 > docs/a.md ;;
        esac
        commit_all "$c"
        for w in main tree; do imps "$w" docs/other.md; want walk failed; want why "read docs/a.md"; want docs/other.md imported; done
    done
    yes aaaaaaaaa | head -c 4194304 > docs/a.md; commit_all exact
    for w in main tree; do imps "$w" docs/other.md; want walk ok; want docs/other.md -; done
    # Well-formed UTF-8 beyond ASCII is read.
    printf 'caf\xc3\xa9 @z.md\n' > docs/a.md; commit_all utf8
    for w in main tree; do imps "$w" docs/z.md; want walk ok; want docs/z.md imported; done
    if [ "$(id -u)" -ne 0 ]; then
        # A file the walk reads from the checkout but cannot open: the tree walk's import, the main walk's untracked one.
        chmod 000 docs/a.md; imps tree docs/other.md; chmod 644 docs/a.md
        want walk failed; want why "read docs/a.md"; want docs/other.md imported
        printf '@docs/u.md\n' > CLAUDE.local.md; printf 'x\n' > docs/u.md; chmod 000 docs/u.md
        imps main docs/other.md; chmod 644 docs/u.md
        want walk failed; want why "read docs/u.md"; want docs/other.md imported
    fi
}

@test "no symlink is followed: a start or an import main stores as a symlink, a checkout link at a name main lacks and a name below a linked directory fail the walk; an untracked start that is a link is skipped (brief 2026-11-03-import-walk-plain; G61; H2)" {
    mkdir -p docs real
    printf 'x\n' > docs/t.md; printf '@docs/a.md\n' > CLAUDE.md; ln -s t.md docs/a.md; commit_all link-target
    for w in main tree; do imps "$w" docs/x.md; want walk failed; want why "link docs/a.md"; want docs/x.md imported; done
    rm docs/a.md && printf 'ok\n' > docs/a.md && ln -s docs/t.md AGENTS.md && commit_all link-start
    for w in main tree; do imps "$w" docs/x.md; want walk failed; want why "link AGENTS.md"; want docs/x.md imported; done
    git rm -q AGENTS.md && printf '@docs/a.md @docs/n.md @lnk/f.md\n' > CLAUDE.md && commit_all names
    imps main docs/x.md; want walk ok; want docs/x.md -
    ln -s t.md docs/n.md
    imps main docs/x.md; want walk failed; want why "link docs/n.md"; want docs/x.md imported
    rm docs/n.md && ln -s real lnk && printf 'y\n' > real/f.md
    imps main docs/x.md; want walk failed; want why "link lnk/f.md"; want docs/x.md imported
    rm lnk
    # An untracked start that is a link is skipped, not refused (G56: other shapes skipped).
    ln -s docs/t.md CLAUDE.local.md
    for w in main tree; do imps "$w" docs/x.md; want walk ok; want docs/x.md -; done
}

@test "both walks start at instruction files (SKILL.md, GEMINI.md, an upper-case .MD) and at .md files under .claude/rules/, commands/, agents/, output-styles/ and skills/ at any depth, tracked or not; a prompt's names also resolve against the repo root, and its imports' only against their own directory (U2a4; brief 2026-11-03-import-walk-plain; G62)" {
    mkdir -p a/.claude/commands docs/.claude/rules/deep x/y .claude/skills/s .claude/agents .claude/output-styles docs
    printf '@p.md @docs/p2.md\n' > a/.claude/commands/c.md
    printf '@q.md\n' > p.md; printf '@q2.md\n' > docs/p2.md
    printf '@r.md\n' > docs/.claude/rules/deep/m.md
    printf '@g.md\n' > x/y/GEMINI.md; printf '@k.md\n' > x/SKILL.MD
    printf '@s2.md\n' > .claude/skills/s/SKILL.md; printf '@o.md\n' > .claude/output-styles/o1.md
    commit_all prompts
    printf '@u2.md\n' > .claude/agents/u.md
    for w in main tree; do
        imps "$w" a/.claude/commands/p.md p.md q.md docs/p2.md docs/q2.md q2.md docs/.claude/rules/deep/r.md r.md \
            x/y/g.md x/k.md s2.md .claude/skills/s/s2.md o.md u2.md .claude/agents/u2.md
        want walk ok
        for p in a/.claude/commands/p.md p.md q.md docs/p2.md docs/q2.md docs/.claude/rules/deep/r.md x/y/g.md x/k.md \
                 s2.md .claude/skills/s/s2.md o.md u2.md .claude/agents/u2.md; do want "$p" imported; done
        want q2.md -; want r.md -
    done
}

@test "both walks skip a gitlink, a directory or nothing at a name, and end on an import cycle and a self-import (brief 2026-11-03-import-walk-plain)" {
    mkdir -p docs/dir
    printf '@docs/a.md @docs/dir @docs/none.md @CLAUDE.md @docs/gl.md\n' > CLAUDE.md
    printf '@../CLAUDE.md @a.md\n' > docs/a.md; printf 'x\n' > docs/dir/f.txt
    git add -A && git update-index --add --cacheinfo "160000,$(git rev-parse HEAD),docs/gl.md" && git commit -qm gitlink
    for w in main tree; do
        imps "$w" docs/a.md docs/dir docs/none.md CLAUDE.md docs/gl.md docs/dir/f.txt
        want walk ok
        for p in docs/a.md docs/dir docs/none.md CLAUDE.md docs/gl.md; do want "$p" imported; done
        want docs/dir/f.txt -
    done
}

@test "a failed walk answers imported for every path and says where: main not found by name, main's tree unreadable, a ~/ name while HOME is not absolute; a ~/ name into the repo is read; an unknown walk name answers imported (brief 2026-11-03-import-walk-plain; H2)" {
    mkdir -p docs
    printf '@~/repo/docs/n.md\n' > CLAUDE.md && commit_all home
    for w in main tree; do
        HOME="$BATS_TEST_TMPDIR" imps "$w" docs/n.md docs/x.md; want walk ok; want docs/n.md imported; want docs/x.md -
        HOME=rel imps "$w" docs/x.md; want walk failed; want why "read CLAUDE.md"; want docs/x.md imported
        HOME="" imps "$w" docs/x.md; want walk failed; want why "read CLAUDE.md"
    done
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        if isimported other docs/x.md; then echo imported; else echo -; fi' _ "$LIB"
    [ "$output" = imported ] || { echo "$output $stderr"; return 1; }
    t="$(git rev-parse 'main^{tree}')"; mv ".git/objects/${t:0:2}/${t:2}" "$BATS_TEST_TMPDIR/tree"
    imps main docs/x.md; want walk failed; want why tree; want docs/x.md imported
    mv "$BATS_TEST_TMPDIR/tree" ".git/objects/${t:0:2}/${t:2}"
    git checkout -q -b trunk && git branch -q -D main
    imps main docs/x.md; want walk failed; want why main; want docs/x.md imported
}

@test "the walks read no instruction file outside the checkout, and an unreadable directory skips only what lies below it: the user's ~/.claude, an ancestor's CLAUDE.md and another worktree's start files import nothing (restriction audit G57, G58; S1)" {
    mkdir -p docs "$HOME/.claude/rules"
    printf '@%s/docs/a.md\n' "$(pwd -P)" > "$HOME/.claude/CLAUDE.md"; cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/rules/r.md"
    printf '@repo/docs/b.md\n' > ../CLAUDE.md
    printf 'x\n' > docs/x.md && commit_all base
    git worktree add -q ../wt -b other && printf '@docs/c.md\n' > ../wt/CLAUDE.md && mkdir ../wt/locked && chmod 000 ../wt/locked
    mkdir locked && printf '@docs/d.md\n' > locked/CLAUDE.md && chmod 000 locked
    for w in main tree; do
        imps "$w" docs/a.md docs/b.md docs/c.md docs/d.md
        want walk ok
        for p in docs/a.md docs/b.md docs/c.md; do want "$p" -; done
        # As root, a mode-000 directory is still read; elsewhere its untracked start is skipped.
        [ "$(id -u)" -eq 0 ] || want docs/d.md -
    done
    chmod 755 locked ../wt/locked
}

@test "each walk caches its result, a failure included, until import_reset or a new main commit (contract item 4; brief 2026-11-03-import-walk-plain)" {
    mkdir -p docs
    printf '@docs/a.md\n' > CLAUDE.md && commit_all base
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        for w in main tree; do
            import_reset; rm -f GEMINI.md
            isimported "$w" docs/a.md && echo "$w a: imported"
            printf "@docs/b.md\n" > GEMINI.md
            isimported "$w" docs/b.md || echo "$w b cached: -"
            import_reset; isimported "$w" docs/b.md && echo "$w b: imported"
            ln -sf x.md docs/b.md; import_reset; if [[ $w == main ]]; then main_imports || echo "main failed"; else imported_names || echo "tree failed"; fi
            rm docs/b.md; if [[ $w == main ]]; then main_imports || echo "main still failed"; else imported_names || echo "tree still failed"; fi
        done' _ "$LIB"
    [ "$output" = "main a: imported
main b cached: -
main b: imported
main failed
main still failed
tree a: imported
tree b cached: -
tree b: imported
tree failed
tree still failed" ] || { echo "$output $stderr"; return 1; }
    # A new main commit walks again without import_reset.
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        isimported main docs/c.md || echo "c: -"
        printf "@docs/c.md\n" > CLAUDE.md; git add CLAUDE.md; git commit -qm c; resolve_main
        isimported main docs/c.md && echo "c: imported"' _ "$LIB"
    [ "$output" = $'c: -\nc: imported' ] || { echo "$output $stderr"; return 1; }
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
        skills/dev-cycle/references/x.md "$GATE" Skills/Dev-Cycle/x.sh "$GATE" skills/dev-cycle/SKILL.md "$INSTR"
        docs/imported.md "$IMP" Docs/Imported.md "$IMP" docs/deep.md "$IMP" skills/x/ref.md "$IMP" docs/new.md "$IMP" docs/private.md "$IMP"
        docs/constraints.md "$USER" docs/dev-cycle.md "$OWN" docs/roadmap.md "$OWN" Docs/Roadmap.md "$OWN"
        docs/working/questions.md "$OWN" docs/working/briefs/2026-10-02-y.md "$OWN" docs/working/briefs/closed/2026-10-01-x.md "$OWN"
        docs/decisions/001-x.md "$REC" docs/failure-patterns.md "$REC" Docs/Failure-Patterns.md "$REC" docs/thoughts/failure-patterns.md "$REC" docs/human-author/x.md "$REC"
        docs/working/checkpoint-2026-10-02-y.md "$WORK" docs/working/plan-x.md "$WORK" docs/working/notes.md "$WORK"
        docs/working/plan-2026-10-01-xy.md "$WORK" docs/working/scratch/plan-2026-10-01-x.md "$WORK"
        docs/reviews/r-2026-10-01-x.md "$REV")
    pass=(scripts/other.sh skills/x/helper.md skills/dev-cycle-x/a.md hooks/x.sh install.sh test/x.bats docs/guide.md docs/wt-only.md docs/thoughts/x.md
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

@test "floor fails closed when main's walk fails, saying where, when main is not found by name, or a path cannot be lower-cased (U2a4; override rows 376, 424, 467)" {
    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all claude
    floors 2026-10-01-x M scripts/other.sh
    want scripts/other.sh -
    # IMPORTED_MAIN_WHY, worded: a checkout link at a name main lacks; a checkout file it cannot read.
    mkdir docs && ln -s ../CLAUDE.md docs/a.md; floors 2026-10-01-x M scripts/other.sh; rm docs/a.md
    want scripts/other.sh "$WALKFAIL: docs/a.md $LINKWHY"
    if [ "$(id -u)" -ne 0 ]; then
        echo x > docs/a.md && chmod 000 docs/a.md; floors 2026-10-01-x M scripts/other.sh; chmod 644 docs/a.md
        want scripts/other.sh "$WALKFAIL: docs/a.md $READWHY"
    fi
    rm -r docs
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
    for p in scripts/other.sh docs/b.md; do want "$p" "$WALKFAIL: CLAUDE.md $READWHY"; done
    # A name outside pathform's characters prints as ? (i1 security 1): a start whose blob is missing.
    git hash-object -w CLAUDE.md > /dev/null; mkdir 'a b' && printf 'y\n' > 'a b/CLAUDE.md' && commit_all crafted
    o="$(git rev-parse 'main:a b/CLAUDE.md')"; rm ".git/objects/${o:0:2}/${o:2}"
    floors 2026-10-01-x M scripts/other.sh
    want scripts/other.sh "$WALKFAIL: ? $READWHY"
    # No default branch found by name: nothing is read, everything refuses.
    git checkout -q -b trunk && git branch -q -D main
    floors 2026-10-01-x M scripts/other.sh
    want scripts/other.sh "$WALKFAIL: the default branch was not found by name"
    # An unset ROOT_REAL exits 1 before any read (i1 A1).
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; floor docs/x.md x M docs/x.md; echo reached' _ "$LIB"
    [ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"ROOT_REAL is not set"* ]] || { echo "$status $output $stderr"; return 1; }
}

@test "floor refuses a path below a start file's name or an imported .md name, as a directory there keeps the file from being created (U2c1 i1 security 1, U2c2 i1 security 3)" {
    printf 'see @docs/new.md\n' > AGENTS.md && commit_all imp
    floors 2026-10-01-x A src/CLAUDE.md/n.txt docs/Agents.local.md/a/b skills/x/skill.md/y src/claude.mdx/n.txt docs/new.md/n.txt docs/x.txt docs/ne/x.txt
    for p in src/CLAUDE.md/n.txt docs/Agents.local.md/a/b skills/x/skill.md/y docs/new.md/n.txt; do want "$p" "a path below the name of an instruction or prompt file, or of a .md file one imports with @"; done
    # A path below an imported name that is no .md name is not refused (docs/x.txt, docs/ne/x.txt).
    for p in src/claude.mdx/n.txt docs/x.txt docs/ne/x.txt; do want "$p" -; done
}

@test "floor given the lowered path forks no lower, and a cached walk no root check (U2c1 final performance 1)" {
    S="$BATS_TEST_TMPDIR/shim"; mkdir -p "$S"
    for b in tr pwd; do printf '#!/bin/sh\necho %s >> "%s/calls"\nexit 1\n' "$b" "$BATS_TEST_TMPDIR" > "$S/$b"; chmod +x "$S/$b"; done
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        floor docs/a.md x M docs/a.md || echo "a: -"; PATH="$2:$PATH"; enable -n pwd
        floor docs/b.md x M docs/b.md || echo "b: -"; floor Docs/C.md x M Docs/C.md && echo "C: $(floor_why "$FLOOR_WHY")"' _ "$LIB" "$S"
    [ "$output" = "a: -
b: -
C: the path could not be lower-cased" ] && [ ! -e "$BATS_TEST_TMPDIR/calls" ] || { echo "$output $stderr"; cat "$BATS_TEST_TMPDIR/calls"; return 1; }
}

@test "check_fix, floor and --cycle-diff share one read-as-truth rule: all refuse docs/failure-patterns.md and its old path, and pass other docs/thoughts/ notes (U2a4; override rows 204, 322, 348; brief 2026-10-31-failure-patterns-out-of-thoughts)" {
    run --separate-stderr env LC_ALL=C bash -c 'source "$1"; shift
        for p in "$@"; do if truthrule "$p"; then echo "$p: $TRUTH_WHY"; else echo "$p: -"; fi; done' _ "$LIB" \
        claude.md docs/x/skill.md .claude/commands/c.md .envrc docs/x/.y docs/roadmap.md docs/dev-cycle.md docs/constraints.md \
        docs/decisions/1.md docs/human-author/a.md docs/failure-patterns.md docs/thoughts/failure-patterns.md docs/thoughts/t.md docs/guide.md Docs/Constraints.md
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
docs/failure-patterns.md: record
docs/thoughts/failure-patterns.md: record
docs/thoughts/t.md: -
docs/guide.md: -
Docs/Constraints.md: case" ] || { echo "$output $stderr"; return 1; }
    mkdir -p docs/thoughts && printf 'x\n' > docs/thoughts/t.md && commit_all thoughts
    run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-fix docs/thoughts/t.md
    [ "$output" = "ok docs/thoughts/t.md" ] || { echo "$output $stderr"; return 1; }
    printf 'x\n' > docs/failure-patterns.md && commit_all library
    run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-fix docs/failure-patterns.md
    [[ "$output" == "skip docs/failure-patterns.md: in-cycle fixes edit only"*"failure-patterns.md"* ]] || { echo "$output $stderr"; return 1; }
    floors 2026-10-01-x M docs/thoughts/t.md docs/failure-patterns.md
    want docs/thoughts/t.md -; want docs/failure-patterns.md "$REC"
}


@test "floor sets a word, which floor_why words; a failed walk's TRUTH_WHERE says where, for both walks (rows 472, 630, 634, U3a3)" {
    ln -s missing.md AGENTS.md && commit_all link-start
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        floor scripts/build-loop.sh x M && echo "[$FLOOR_WHY] $(floor_why "$FLOOR_WHY")"
        floor docs/a.md x M && echo "[$FLOOR_WHY] $(floor_why "$FLOOR_WHY")"
        truthwalk tree docs/a.md && echo "tree [$TRUTH_WHY] $TRUTH_WHERE"' _ "$LIB"
    R="AGENTS.md $LINKWHY"
    [ "$output" = "[gate] $GATE
[walk] $WALKFAIL: $R
tree [walk] $R" ] || { echo "$output $stderr"; return 1; }
}

@test "truthwalk empties TRUTH_WHY when it does not refuse; import_reset makes the next floor walk again (U2a4 i1 api-consistency 1, architecture F1)" {
    printf 'see @docs/a.md\n' > CLAUDE.md && commit_all claude
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
        truthwalk main docs/b.md || echo "b: [$TRUTH_WHY]"
        truthwalk main docs/a.md && echo "a: [$TRUTH_WHY]"
        printf "see @docs/c.md\n" > CLAUDE.local.md
        floor docs/c.md x M || echo "c cached: -"
        import_reset; floor docs/c.md x M && echo "c: $(floor_why "$FLOOR_WHY")"' _ "$LIB"
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

@test "--check's state gate refuses a shallow clone, before reading any brief; other planted-looking state passes (T26, U2b1a; brief 2026-11-01-relax-gate-git-state)" {
    gated feat/x
    printf '* merge=union\n' > .git/info/attributes
    git rev-parse main > .git/info/grafts
    echo "$BATS_TEST_TMPDIR/elsewhere" > .git/objects/info/alternates; mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
    git replace "$(git rev-parse main)" "$(git rev-parse feat/x)"
    git config merge.x.driver true; git config diff.x.textconv cat; git config hook.x.command true
    chk "$B"
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $B "* ]] || { show; return 1; }
    git rev-parse main > .git/shallow
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state shallow: a shallow clone, whose history the gate cannot read whole" ] || { show; return 1; }
    # A shallow file that is empty is no shallow clone.
    : > .git/shallow; chk "$B"; [ "$status" -eq 0 ] || { show; return 1; }
}

@test "under a broken log.* config the brief and branch reads skip instead of reading LOOP or DATE wrong (row 307, U2b1a1)" {
    gated feat/x; tip feat/x "handoff: ready"
    # Not log.date: git_harden's log.date pair overrides it (row 505); a bad boolean still stops git log.
    git config log.abbrevCommit bogus
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
    [ "$status" -eq 2 ] && [ "$output" = "refuse state remote.origin.promisor: set in config, a partial clone, whose missing objects the gate cannot read
refuse state extensions.partialclone: set in config, a partial clone, whose missing objects the gate cannot read" ] || { echo "$status $output $stderr"; return 1; }
    [ ! -e "$BATS_TEST_TMPDIR/fetched" ] || { echo "upload-pack ran"; return 1; }
    # A promisor key in this worktree's config.worktree refuses too.
    git config --unset remote.origin.promisor; git config --unset extensions.partialClone
    git config extensions.worktreeConfig true && git config --worktree remote.origin.promisor true
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state remote.origin.promisor: set in config.worktree, a partial clone, whose missing objects the gate cannot read" ] || { echo "$status $output $stderr"; return 1; }
}

@test "every git call --check makes carries git_harden's config pairs (core.hooksPath=/dev/null among them), no global or system config and no transport (T26, A4, U2b1a i1, i2, A17)" {
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
    # HARDEN from the lib itself, so a key added there is checked here too.
    for kv in $(bash -c 'source "$1"; echo "${HARDEN[*]}"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh") G=/dev/null P=none S=1; do
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
    git repack -adq; chk "$B"; [ "$status" -eq 0 ] || { show; return 1; }
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
NFORM="not an allowed path form for a self-merge (letters, digits and . _ - / only; no leading - or /; no empty, . or .. part; no part starting .git)"
NMODE="a symlink, gitlink or other non-file entry on one side (a self-merge lands only modes 100644 and 100755)"
NANY="not a path a checkout can hold (a control character, an empty, . or .. part, or a .git part)"
# nref K N: the verdict line refusing K of N changed paths in the merge of feat/x into main.
nref() { echo "refuse $B: $1 of $2 changed paths refused in the merge of $(git rev-parse feat/x) (tree $(git merge-tree --write-tree main feat/x))"; }
NBRIEF="this brief: only its first Status: line outside a fence may change, from open to done"

@test "--check lists every changed path and refuses the dev cycle's own files, other briefs and the constraints doc in any case; other paths pass (T14, F2, F12, F54, U2b1b)" {
    brief other "Status: open" "Branch: feat/o"; o="$B"
    mkdir -p docs/working && echo r > docs/roadmap.md && commit_all roadmap
    gated feat/x
    fs=(docs/roadmap.md docs/working/questions.md docs/working/questions-archive.md docs/working/idea-log.md
        docs/working/cycles/cycle-2026-10-01.md docs/working/cycles/notes.md docs/dev-cycle.md "$o"
        docs/working/briefs/2026-10-02-new.md docs/working/briefs/closed/x Docs/Roadmap.md docs/Dev-Cycle.md docs/working/Questions.md
        docs/working/watching.md docs/working/roadmap-from-questions.md)
    onx 'mkdir -p docs/working/briefs/closed docs/working/cycles Docs; for f in "${fs[@]}" docs/constraints.md docs/CONSTRAINTS.md docs/ok.md; do echo x > "$f"; done'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 17 18)" ] && [ "${#lines[@]}" -eq 19 ] || { show; return 1; }
    has "deny $B M docs/roadmap.md: $NOWN"
    for f in "${fs[@]:1}"; do [[ "$f" == "$o" ]] && m=M || m=A; has "deny $B $m $f: $NOWN"; done
    has "deny $B A docs/constraints.md: $NUSER"; has "deny $B A docs/CONSTRAINTS.md: $NUSER"
    has "path $B A docs/ok.md"
    # The paths come in diff-tree order, after the verdict.
    [ "${lines[1]}" = "deny $B A Docs/Roadmap.md: $NOWN" ] && [ "${lines[18]}" = "deny $B A docs/working/watching.md: $NOWN" ] || { show; return 1; }
    # A branch whose changes main already holds merges to main's own tree: ok, no path line.
    onx 'echo x > docs/ok.md'; git checkout -q -B main feat/x; git checkout -q -B feat/x main; git commit -q --allow-empty -m e; git checkout -q main
    chk "$B"
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 1 ] && [[ "${lines[0]}" == "ok $B "* ]] || { show; return 1; }
}

@test "--check: the brief's own file may change only its first Status: line outside a fence, open to done (T15, F13, U2b1b)" {
    brief x '```' 'Status: open' '```' 'Status: open' 'Branch: feat/x'
    printf 'Status: open\r\nBranch: feat/c\n' > docs/working/briefs/2026-10-01-crlf.md && cp "$RD" docs/working/research-2026-10-01-crlf.md && commit_all crlf
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

@test "--check refuses a self-merge's symlink or gitlink on either side, though submodule ignore=all is set, and passes an exec bit; a review brief's pass (T12, F7, A16, U2b1b; brief 2026-11-02-relax-grammar-and-loop-prompt G40)" {
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
    # Review: the owner reviews the branch, so the mode rule is off.
    chk "$B"
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $B "* ]] && [ "${#lines[@]}" -eq 8 ] || { show; return 1; }
    for p in "T g.txt (symlink)" "A gl (gitlink)" "A link (symlink)" "T og" "T was-link" "A scripts/n.sh" "M scripts/x.sh"; do has "path $B $p"; done
    # Self-merge: the mode rule holds (the two plain files fall to the allowlist).
    smb "Paths: scripts/"
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 5 7)" ] || { show; return 1; }
    for p in "T g.txt (symlink)" "A gl (gitlink)" "A link (symlink)" "T og" "T was-link"; do has "deny $B $p: $NMODE"; done
    has "path $B A scripts/n.sh"; has "path $B M scripts/x.sh"
}

@test "--check refuses a self-merge's changed path pathform refuses; a review brief's only a control character; it prints only a name in pathform's set (T13, F17, U2b1b; brief 2026-11-02-relax-grammar-and-loop-prompt G39)" {
    gated feat/x
    onx 'mkdir -p .github; echo x > .github/w.yml; echo x > .gitignore; echo x > "a b.md"; echo x > "$(printf "caf\xc3\xa9.md")"; echo x > "$(printf "n\nl.md")"; echo x > "$(printf "t\tb.md")"; echo x > "$(printf "d\177l.md")"; echo x > ./-x.md'
    # Review: .git* parts and other characters pass; a newline, tab or DEL is refused.
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 3 8)" ] && [ "${#lines[@]}" -eq 9 ] || { show; return 1; }
    has "path $B A -x.md"; has "path $B A .github/w.yml"; has "path $B A .gitignore"
    [ "$(printf '%s\n' "$output" | grep -cxF "path $B A ?")" -eq 2 ] && [ "$(printf '%s\n' "$output" | grep -cxF "deny $B A ?: $NANY")" -eq 3 ] || { show; return 1; }
    # Self-merge: pathform's rule holds.
    smb "Paths: none"
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 8 8)" ] && [ "${#lines[@]}" -eq 9 ] || { show; return 1; }
    has "deny $B A -x.md: $NFORM"; has "deny $B A .github/w.yml: $NFORM"; has "deny $B A .gitignore: $NFORM"
    [ "$(printf '%s\n' "$output" | grep -cxF "deny $B A ?: $NFORM")" -eq 5 ] || { show; return 1; }
    # A .git part in any case, at any depth, refuses under review too (built as a tree: git's index refuses one).
    brief x "Status: open" "Branch: feat/x"
    b="$(printf 'x\n' | git hash-object -w --stdin)"; t="$(printf '100644 blob %s\tx\n' "$b" | git mktree)"
    t="$(printf '040000 tree %s\t.GIT\n' "$t" | git mktree)"; t="$(printf '040000 tree %s\tsub\n' "$t" | git mktree)"
    t="$(git ls-tree main | cat - <(printf '040000 tree %s\tdeep\n' "$t") | git mktree)"
    git update-ref refs/heads/feat/x "$(git commit-tree "$t" -p main -m dotgit)"
    chk "$B"
    [ "$status" -eq 2 ] && has "deny $B A deep/sub/.GIT/x: $NANY" || { show; return 1; }
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
    # A symlink's blob too (blobs_present; brief 2026-11-01-relax-gate-git-state review i1).
    git update-ref refs/heads/feat/x "$(git rev-parse feat/x~1)"
    tip feat/x "link" "$( (git ls-tree main; printf '120000 blob %s\tlink\n' "$b") | git mktree --missing)" "$(git rev-parse main)"
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse $B: the merge of feat/x names a blob the object store lacks" ] || { show; return 1; }
}

# loose ID: a loose copy of packed blob ID, beside the packed one (git itself writes none for an object it has).
loose() {
    mkdir -p ".git/objects/${1:0:2}" && git cat-file blob "$1" | perl -MCompress::Zlib -0777 -ne 'print compress("blob " . length($_) . "\0" . $_)' > ".git/objects/${1:0:2}/${1:2}"
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
    # origin/HEAD naming a branch that exists here: resolve_main takes it, and the gate names it (research D2).
    git branch -q develop master; git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state default-branch: the default branch taken is develop, not main or master" ] || { show; return 1; }
    # An origin/HEAD git cannot read (symbolic-ref exits 128) refuses, though resolve_main takes master without it (H2).
    git branch -q -D develop; echo garbage > .git/refs/remotes/origin/HEAD
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state default-branch: origin/HEAD could not be read" ] || { show; return 1; }
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

@test "--check runs its state gate before resolve_main reads an object: every commit read follows the gate's last call (A15, U2b1b)" {
    gated feat/x
    # A shim logs each git call in order; resolve_main's first object read is a rev-parse of SHA^{commit}.
    S="$BATS_TEST_TMPDIR/shim"; mkdir -p "$S"; real="$(command -v git)"
    printf '#!/bin/bash\necho "$*" >> "%s/calls"\nexec "%s" "$@"\n' "$BATS_TEST_TMPDIR" "$real" > "$S/git"; chmod +x "$S/git"
    PATH="$S:$PATH" chk "$B"
    [ "$status" -eq 0 ] || { show; return 1; }
    g="$(grep -n -m1 -F -- '--git-path shallow' "$BATS_TEST_TMPDIR/calls" | cut -d: -f1)"
    r="$(grep -n -m1 -F '^{commit}' "$BATS_TEST_TMPDIR/calls" | cut -d: -f1)"
    [ -n "$g" ] && [ -n "$r" ] && [ "$g" -lt "$r" ] || { echo "gate call at line $g, first commit read at line $r"; cat "$BATS_TEST_TMPDIR/calls"; return 1; }
}

# sm: self-merge on, brief x (self-merge, naming feat/x) and feat/x with one commit; B is its path.
sm() { settings "Build-loop policy: self-merge" "Self-merge never: none"; brief x "Status: open" "Branch: feat/x" "Policy: self-merge" "Paths: work-feat-x.txt"; work feat/x; }
CO="a self-merge brief needs --check run from a clean checkout of the default branch's commit"
# coref WHY: --check refused brief x for its checkout, with WHY, and still listed
# feat/x's one changed path. cook: --check passed it.
coref() {
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: $CO; $1" ] && [ "${lines[1]}" = "path $B A work-feat-x.txt" ] && [ "${#lines[@]}" -eq 2 ] \
        && [ -z "$stderr" ] || { echo "want: $1"; show; return 1; }
}
cook() { chk "$B"; [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $B "* ]] && [ -z "$stderr" ] || { show; return 1; }; }
STAT="the checkout's index or tracked files differ from that commit (git status)"
ENVS="is set, so git can read another repository, work tree, index or object store"

@test "--check refuses a self-merge brief unless it runs from a clean checkout of main: HEAD, env, status, an unmerged path (contract item 2, U2b2)" {
    sm; echo a > docs/a.md && commit_all a
    # Untracked and ignored files are allowed: the walk reads them as they are.
    echo '*.local.md' > .git/info/exclude; echo x > CLAUDE.local.md; echo y > untracked.md
    cook
    git checkout -q --detach HEAD~1
    coref "the checkout's HEAD is $(git rev-parse HEAD), not the default branch's commit $(git rev-parse main)"; git checkout -q main
    echo b >> docs/a.md; coref "$STAT"; git checkout -q -- docs/a.md
    echo n > new.md; git add new.md; coref "$STAT"; git rm -q --cached new.md
    # An unmerged path (a conflicted merge, aborted by hand) shows in git status.
    git checkout -q -b side main~1 && echo s > docs/a.md && git add docs/a.md && git commit -q -m side && git checkout -q main
    git merge -q side >/dev/null 2>&1 || true; [ -n "$(git ls-files -u)" ]; rm -f .git/MERGE_HEAD .git/MERGE_MSG .git/MERGE_MODE .git/AUTO_MERGE
    coref "$STAT"; git reset -q --hard main
    cook
    # A variable that points git elsewhere refuses; the caller's config pairs and the rest of git's do not.
    GIT_INDEX_FILE="$PWD/.git/index" coref "GIT_INDEX_FILE $ENVS"
    GIT_WORK_TREE="$PWD" coref "GIT_WORK_TREE $ENVS"
    GIT_DIR="$PWD/.git" coref "GIT_DIR $ENVS"
    GIT_OBJECT_DIRECTORY="$PWD/.git/objects" coref "GIT_OBJECT_DIRECTORY $ENVS"
    GIT_COMMON_DIR="$PWD/.git" coref "GIT_COMMON_DIR $ENVS"
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=x cook
    GIT_REPLACE_REF_BASE=refs/x/ cook
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

# honest: --state prints ok, and --check passes self-merge brief x (sm) from
# this checkout, its checkout rule included. Each setup below is an ordinary
# one the gate refused before brief 2026-11-01-relax-gate-git-state.
honest() {
    run --separate-stderr bash "$BL" --state
    [ "$status" -eq 0 ] && [ "$output" = ok ] && [ -z "$stderr" ] || { echo "--state"; show; return 1; }
    cook
}

@test "an honest setup passes every gated mode: git-lfs's local filter config (brief 2026-11-01-relax-gate-git-state)" {
    # A tracked file the filter applies to, touched so git status runs the clean filter (cat stands in for git-lfs).
    sm; echo '*.bin filter=lfs' > .gitattributes; echo data > a.bin; commit_all lfs
    git config filter.lfs.clean "touch '$BATS_TEST_TMPDIR/clean-ran'; cat"; git config filter.lfs.smudge cat; git config filter.lfs.required true
    touch -d '2000-01-01' a.bin
    honest
    [ -e "$BATS_TEST_TMPDIR/clean-ran" ] || { echo "the clean filter never ran, so the setup was not in effect"; return 1; }
}

@test "an honest setup passes every gated mode: merge.conflictStyle and a diff setting (brief 2026-11-01-relax-gate-git-state)" {
    sm; git config merge.conflictStyle diff3; git config diff.algorithm histogram; honest
}

@test "an honest setup passes every gated mode: include.path (brief 2026-11-01-relax-gate-git-state)" {
    sm; printf '[user]\n\tname = t\n' > "$BATS_TEST_TMPDIR/inc"; git config include.path "$BATS_TEST_TMPDIR/inc"; honest
}

@test "an honest setup passes every gated mode: core.fsmonitor on (brief 2026-11-01-relax-gate-git-state)" {
    sm; git config core.fsmonitor true; honest
}

@test "an honest setup passes every gated mode: SSH commit signing (brief 2026-11-01-relax-gate-git-state)" {
    sm; git config gpg.format ssh; git config gpg.ssh.program "$BATS_TEST_TMPDIR/nowhere"; git config user.signingkey "$BATS_TEST_TMPDIR/key.pub"
    git config commit.gpgSign true; git config log.showSignature true; honest
}

@test "an honest setup passes every gated mode: a husky core.hooksPath, whose hooks the gate does not run (brief 2026-11-01-relax-gate-git-state)" {
    # Whether a hook runs is the --merge test's to check (these modes write no ref).
    sm; mkdir -p .husky; printf '#!/bin/sh\nexit 0\n' > .husky/pre-commit; chmod +x .husky/pre-commit
    echo '.husky/' >> .git/info/exclude; git config core.hooksPath .husky
    honest
}

@test "an honest setup passes every gated mode: an object both packed and loose, and in two packs (brief 2026-11-01-relax-gate-git-state)" {
    sm; git repack -adq; o="$(git rev-parse "main:$B")"
    loose "$o"; honest
    echo "$o" | git pack-objects -q .git/objects/pack/pack >/dev/null; honest
}

@test "an honest setup passes every gated mode: core.autocrlf, so checked-out bytes differ from main's blobs (brief 2026-11-01-relax-gate-git-state)" {
    sm; git config core.autocrlf true; rm "$B"; git checkout -q -- "$B"
    grep -q $'\r$' "$B" && [ -z "$(git status --porcelain --untracked-files=no)" ] || { cat -A "$B"; git status; return 1; }
    honest
}

@test "an honest setup passes every gated mode: a sparse checkout (brief 2026-11-01-relax-gate-git-state)" {
    sm; echo top > top.txt && commit_all top
    git sparse-checkout set --no-cone /docs/
    [ ! -e top.txt ] && [ "$(git ls-files -t | grep -c '^S ')" -gt 0 ] && [ -z "$(git status --porcelain --untracked-files=no)" ] || { git ls-files -t; git status; return 1; }
    honest
}

@test "an honest setup passes every gated mode: a case-insensitive checkout, and an untracked nested repository (brief 2026-11-01-relax-gate-git-state)" {
    sm; git config core.ignoreCase true; honest
    git init -q nested; honest
}

# U2c1, the S rules (plan D5): a self-merge brief lands only what its Paths:
# lists or its own files, never what the floor or a Self-merge never: glob refuses.

# smb LINE...: self-merge on (never line $NEV, default none) and brief x, self-merge on feat/x, with these lines.
smb() { settings "Build-loop policy: self-merge" "${NEV:-Self-merge never: none}"; brief x "Status: open" "Branch: feat/x" "Policy: self-merge" "$@"; }
NLIST="neither listed in the brief's Paths: line nor one of its own files"

@test "--check self-merges listed paths (exec bit, a directory entry), the brief's own working docs and added reviews, and its Status line (T9, U2c1)" {
    smb "Paths: scripts/other.sh skills/x/ hooks/x.sh install.sh test/"
    fs=(scripts/other.sh skills/x/helper.md skills/x/y/z.md hooks/x.sh install.sh test/x.bats
        docs/working/plan-2026-10-01-x.md docs/working/checkpoint-2026-10-01-x.md docs/reviews/2026-10-01-x.md docs/reviews/code-review-2026-10-01-x.md)
    # The research doc is on main (the fixture's); the branch changes it, keeping its grep line.
    onx 'mkdir -p scripts skills/x/y hooks test docs/reviews; for f in "${fs[@]}"; do echo x > "$f"; done; echo x >> "$RD"; chmod +x scripts/other.sh; sed -i "s/^Status: open/Status: done/" "$B"'
    chk "$B"
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $B "* ]] && [ "${#lines[@]}" -eq 13 ] && [ -z "$stderr" ] || { show; return 1; }
    has "path $B M $B"; has "path $B M $RD"; for f in "${fs[@]}"; do has "path $B A $f"; done
}

@test "--check refuses a self-merge path the floor names though Paths: lists it, a symlink at a listed path, and a path Paths: does not list exactly (T10, rows 349, 474, U2c1)" {
    mkdir -p docs/reviews && printf 'see @docs/imp.md\n' > CLAUDE.md && echo r > docs/reviews/old.md && commit_all floor
    fl=(CLAUDE.md skills/x/SKILL.md docs/imp.md .claude/settings.json .envrc docs/x/.y scripts/build-loop.sh scripts/lib/dev-cycle-read.sh
        docs/decisions/001-x.md docs/failure-patterns.md docs/working/checkpoint-2026-10-02-y.md docs/reviews/r-2026-10-02-y.md docs/reviews/old.md)
    smb "Paths: ${fl[*]:0:11} docs/reviews/ docs/a scripts/link.sh hooks/x.sh"
    onx 'mkdir -p skills/x .claude docs/x scripts/lib docs/decisions docs/working Hooks
        for f in "${fl[@]}" docs/a docs/ab.md Hooks/x.sh scripts/x.sh; do echo x > "$f"; done; ln -s x.sh scripts/link.sh'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 17 18)" ] && [ -z "$stderr" ] || { show; return 1; }
    has "deny $B M CLAUDE.md: $INSTR"; has "deny $B A skills/x/SKILL.md: $INSTR"; has "deny $B A docs/imp.md: $IMP"
    for f in .claude/settings.json .envrc docs/x/.y; do has "deny $B A $f: $DOT"; done
    has "deny $B A scripts/build-loop.sh: $GATE"; has "deny $B A scripts/lib/dev-cycle-read.sh: $GATE"
    has "deny $B A docs/decisions/001-x.md: $REC"; has "deny $B A docs/failure-patterns.md: $REC"
    has "deny $B A docs/working/checkpoint-2026-10-02-y.md: $WORK"
    has "deny $B A docs/reviews/r-2026-10-02-y.md: $REV"; has "deny $B M docs/reviews/old.md: $REV"
    has "path $B A docs/a"; has "deny $B A scripts/link.sh (symlink): $NMODE"
    for f in docs/ab.md Hooks/x.sh scripts/x.sh; do has "deny $B A $f: $NLIST"; done
}

@test "--check: a malformed Paths: line lands only the brief's own files, spelled in lower case; Paths: none or no line lists nothing (T10, U2c1 i1)" {
    for l in "Paths: docs/a docs/a/|lists entry 2 twice" "Paths:  docs/a|is not exactly \"Paths: PATH ...\" with single spaces" \
             "Paths: docs/../x|lists entry 1, which is not an allowed path form" "Paths: /docs/a|lists entry 1, which is not an allowed path form" \
             "Paths:|is not exactly \"Paths: PATH ...\" with single spaces" "Paths: none|" "-|"; do
        if [[ "${l%|*}" == - ]]; then smb; else smb "${l%|*}"; fi
        onx 'mkdir -p docs/working Docs/Working; echo x > docs/a; echo x > docs/working/plan-2026-10-01-x.md; echo x > Docs/Working/Plan-2026-10-01-x.md; mkdir -p docs/reviews; echo x > docs/reviews/Code-Review-2026-10-01-x.md'
        chk "$B"
        w="${l#*|}"; [[ -n "$w" ]] && w="the brief's Paths: line $w, so only its own files land" || w="$NLIST"
        [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 3 4)" ] && has "deny $B A docs/a: $w" && has "deny $B A Docs/Working/Plan-2026-10-01-x.md: $w" \
            && has "deny $B A docs/reviews/Code-Review-2026-10-01-x.md: $w" \
            && has "path $B A docs/working/plan-2026-10-01-x.md" || { echo "line: $l"; return 1; }
    done
}

@test "--check: a Self-merge never: glob refuses a listed path under self-merge, by part and in any case; review ignores it (T45, U2c1)" {
    NEV="Self-merge never: workflows/ docs/*.txt" smb "Paths: workflows/ Workflows/ docs/ workflowsx.md"
    onx 'mkdir -p workflows/sub Workflows docs/sub; for f in workflows/x.md workflows/sub/y.md Workflows/Z.md docs/n.txt docs/sub/n.txt workflowsx.md; do echo x > "$f"; done'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 4 6)" ] || { show; return 1; }
    for f in workflows/x.md workflows/sub/y.md Workflows/Z.md; do has "deny $B A $f: matched by workflows/ in the Self-merge never: line of docs/dev-cycle.md"; done
    has "deny $B A docs/n.txt: matched by docs/*.txt in the Self-merge never: line of docs/dev-cycle.md"
    has "path $B A docs/sub/n.txt"; has "path $B A workflowsx.md"
    settings "Build-loop policy: review" "Self-merge never: workflows/ docs/*.txt"
    chk "$B"
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 7 ] || { show; return 1; }
}

@test "--check refuses a path below a cycle file's or the constraints doc's name, and cycles/ as a file (an N rule; row 523, U2c1)" {
    gated feat/x
    onx 'mkdir -p docs/roadmap.md docs/constraints.md Docs/Dev-Cycle.md docs/working/questions.md/a; for f in docs/roadmap.md/f docs/constraints.md/f Docs/Dev-Cycle.md/x docs/working/questions.md/a/b docs/working/cycles; do echo x > "$f"; done'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 5 5)" ] || { show; return 1; }
    for f in docs/roadmap.md/f docs/constraints.md/f Docs/Dev-Cycle.md/x docs/working/questions.md/a/b; do
        has "deny $B A $f: a path below the name of one of the dev cycle's own files or the constraints doc"
    done
    has "deny $B A docs/working/cycles: $NOWN"
}

@test "--check walks once per self-merge decision (check_line's import_reset, in the parent shell) and under the C locale (contract items 1, 4; row 532, U2c1)" {
    smb "Paths: work-feat-x.txt"; work feat/x; x="$B"
    brief y "Status: open" "Branch: feat/y" "Policy: self-merge" "Paths: work-feat-y.txt"; work feat/y
    S="$BATS_TEST_TMPDIR/shim"; mkdir -p "$S"; real="$(command -v git)"
    printf '#!/bin/bash\necho "$*" >> "%s/calls"\nexec "%s" "$@"\n' "$BATS_TEST_TMPDIR" "$real" > "$S/git"; chmod +x "$S/git"
    PATH="$S:$PATH" chk "$x" "$B"
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $x "* && "${lines[2]}" == "ok $B "* ]] || { show; return 1; }
    [ "$(grep -c '^ls-tree -r -z --full-tree' "$BATS_TEST_TMPDIR/calls")" -eq 2 ] || { cat "$BATS_TEST_TMPDIR/calls"; return 1; }
    # A name that is not UTF-8 on main fails a walk run under a UTF-8 locale; the gate walks under C.
    printf 'x\n' > $'docs/\xff.md'; commit_all latin
    LC_ALL=C.utf8 chk "$x"
    [ "$status" -eq 0 ] && [ "${lines[1]}" = "path $x A work-feat-x.txt" ] && [ -z "$stderr" ] || { show; return 1; }
}
# The failure-pattern steps (Q-226 [5]). fpref K WHY...: --check refused brief x
# for K gaps, then printed exactly the gap lines WHY..., then no other gap line.
# fpok: --check passed it with no gap line. onb SHELL: SHELL run on feat/x as it
# is (onx starts from main each time), then committed.
GREPGAP="has no line starting \"Failure-pattern grep:\" with a value after the colon (research-plan-implement's failure-pattern lookup)"
FPL=docs/failure-patterns.md
fixgap() { echo "$1 fix(...) commits on feat/x add no new FP-NNN entry to $FPL, and its research doc has no line starting \"Failure-pattern skip:\" with a reason (pr-prep's failure-pattern advisory)"; }
fpref() {
    local k="$1" i g; shift
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: $k failure-pattern gaps on feat/x (gap lines follow)" ] && [ -z "$stderr" ] || { show; return 1; }
    i=1
    for g in "$@"; do [ "${lines[$i]}" = "gap $B: $g" ] || { echo "want line $i: gap $B: $g"; show; return 1; }; i=$((i + 1)); done
    [[ "${lines[$i]:-}" != gap* ]] || { echo "an extra gap line"; show; return 1; }
}
fpok() { chk "$B"; [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $B "* ]] && ! printf '%s\n' "$output" | grep -q '^gap ' && [ -z "$stderr" ] || { show; return 1; }; }
onb() { git checkout -q feat/x && eval "$1" && commit_all onb && git checkout -q main; }
# entry N: a library entry line for number N (as written, so 0002 keeps its zeros).
entry() { echo "- **FP-$1** 2026-10-01 symptom:s$1 cause:c fix:f ref:r"; }

@test "--check refuses a branch whose research doc is absent, not a file or lacks a valued Failure-pattern grep: line; a bullet, a star, an indent or a CR passes (Q-226 [5])" {
    gated feat/x
    fpok   # the fixture's research doc, committed on main with the brief, carries the line
    onx 'git rm -q "$RD"'; fpref 1 "its research doc $RD is not in the tip of feat/x"
    onx 'git rm -q "$RD"; mkdir -p "$RD" && echo x > "$RD/f"'; fpref 1 "its research doc $RD is not a regular file in the tip of feat/x"
    # A symbolic link (mode 120000) to a file holding the line is no research doc either.
    onx 'mv "$RD" docs/working/real.md && ln -s real.md "$RD"'; fpref 1 "its research doc $RD is not a regular file in the tip of feat/x"
    for body in 'Failure-pattern grep:' 'Failure-pattern grep:   ' '- Failure-pattern grep:' 'Failure-pattern greps: FP-001' 'x Failure-pattern grep: FP-001' '- - Failure-pattern grep: FP-001' '**Failure-pattern grep:** FP-001'; do
        onx 'printf "# R\n\n%s\n" "$body" > "$RD"'; fpref 1 "its research doc $RD $GREPGAP" || { echo "body: $body"; return 1; }
    done
    for body in 'Failure-pattern grep: no matches found' '- Failure-pattern grep: FP-001' '* Failure-pattern grep: x' '   - Failure-pattern grep: x' $'Failure-pattern grep: x\r'; do
        onx 'printf "# R\n\n%s\n" "$body" > "$RD"'; fpok || { echo "body: $body"; return 1; }
    done
}

@test "--check: a fix(...) commit the branch adds needs a new library entry or a Failure-pattern skip: line; other subjects and fixes merged in from main need neither (Q-226 [5])" {
    mkdir -p docs && entry 001 > "$FPL" && commit_all library
    gated feat/x
    # FP-024: the pass beside the refusal, in one fixture. Subjects that are not fixes.
    onb 'git commit -q --allow-empty -m "fixture: data"; git commit -q --allow-empty -m "feat: fix it"; git commit -q --allow-empty -m "docs: x" -m "fix: in the body"'; fpok
    # A fix on main, merged into the branch, is main's.
    git commit -q --allow-empty -m "fix(main): on main"; git checkout -q feat/x && git merge -q --no-edit main && git checkout -q main; fpok
    for s in "fix(x): y" "fix: y" "fix!: y" "Fix(X): y" "FIX: y"; do
        git checkout -q feat/x && git commit -q --allow-empty -m "$s" && git checkout -q main
        fpref 1 "$(fixgap 1)" || { echo "subject: $s"; return 1; }
        git branch -q -f feat/x feat/x~1
    done
    git checkout -q feat/x && git commit -q --allow-empty -m "fix(a): one" && git commit -q --allow-empty -m "fix(b): two" && git checkout -q main
    fpref 1 "$(fixgap 2)"; fixes="$(git rev-parse feat/x)"
    # The skip line, valued, clears it; empty, it does not.
    onb 'echo "Failure-pattern skip:" >> "$RD"'; fpref 1 "$(fixgap 2)"
    onb 'echo "- Failure-pattern skip: review-iteration fixes to code first written here" >> "$RD"'; fpok
    # Or a new entry, without the skip line.
    git branch -q -f feat/x "$fixes"; onb 'entry 002 >> "$FPL"'; fpok
    # An indented or code-quoted entry is no entry.
    git branch -q -f feat/x "$fixes"; onb 'printf "    - **FP-002** x\n\`- **FP-003**\`\n" >> "$FPL"'; fpref 1 "$(fixgap 2)"
}

@test "--check refuses a duplicate entry number the merge adds, compared as a number, but not one main already holds; the library unreadable is a gap (Q-226 [5])" {
    mkdir -p docs && { entry 001; echo; entry 002; } > "$FPL" && commit_all library
    gated feat/x
    onx 'entry 001 >> "$FPL"'; fpref 1 "the merge of feat/x holds FP-001 2 times in $FPL (renumber the branch's entry)"
    onx 'entry 0002 >> "$FPL"'; fpref 1 "the merge of feat/x holds FP-002 2 times in $FPL (renumber the branch's entry)"
    # Two branches that picked one number at different places merge clean; the merge holds it twice.
    onx 'entry 003 >> "$FPL"'
    { entry 003; cat "$FPL"; } > "$FPL.n" && mv "$FPL.n" "$FPL" && commit_all "main's FP-003"
    fpref 1 "the merge of feat/x holds FP-003 2 times in $FPL (renumber the branch's entry)"
    # A duplicate main already holds is main's: a new entry beside it passes.
    entry 002 >> "$FPL" && commit_all "main's own duplicate"
    onx 'entry 004 >> "$FPL"'; fpok
    # Not a regular file in the merge, or on main (then in the merge too, as feat/x keeps it).
    onx 'git rm -q "$FPL" && mkdir -p "$FPL" && echo x > "$FPL/f"'
    fpref 1 "$FPL in the merge of feat/x is not a regular file"
    git rm -q "$FPL" && mkdir -p "$FPL" && echo x > "$FPL/f" && commit_all "main's library a directory"
    onx 'echo y > other.txt'
    fpref 2 "$FPL in the merge of feat/x is not a regular file" "$FPL on the default branch is not a regular file"
}

# The library's path before the move; MIGGAP: the gap while main still holds it.
FPO=docs/thoughts/failure-patterns.md
miggap() { echo "$1 fix(...) commits on feat/x need a failure-pattern entry, but the default branch still keeps the library at $FPO, which the gate no longer reads: the owner runs migration failure-patterns-out-of-thoughts from the repo root and commits (git mv $FPO $FPL; if $FPL exists too, merge the two and remove the old one), or its research doc gets a line starting \"Failure-pattern skip:\" with a reason"; }

@test "--check in a repo that has not migrated the library: a fix(...) branch gets a gap naming the remedy, whatever entry it adds; a skip line or no fix passes; after the move the new path counts (brief 2026-10-31-failure-patterns-out-of-thoughts)" {
    mkdir -p docs/thoughts && entry 001 > "$FPO" && commit_all "old library"
    gated feat/x
    onb 'git commit -q --allow-empty -m "fix(a): one"'; fixes="$(git rev-parse feat/x)"
    fpref 1 "$(miggap 1)"
    # An entry at the old path is one the gate no longer reads; one at the new path would split the library.
    onb 'entry 002 >> "$FPO"'; fpref 1 "$(miggap 1)"
    git branch -q -f feat/x "$fixes"; onb 'entry 002 > "$FPL"'; fpref 1 "$(miggap 1)"
    # A skip line clears it; a branch with no fix(...) commit never reads the library.
    git branch -q -f feat/x "$fixes"; onb 'echo "Failure-pattern skip: a reason" >> "$RD"'; fpok
    git branch -q -f feat/x main; onb 'echo y > other.txt'; fpok
    # The remedy, run on main: the old path is gone and an entry at the new path counts.
    git mv "$FPO" "$FPL" && commit_all migrate
    git branch -q -f feat/x main; onb 'git commit -q --allow-empty -m "fix(a): one"'; fpref 1 "$(fixgap 1)"
    onb 'entry 002 >> "$FPL"'; fpok
}

@test "the gate's remedy for an unmigrated library is the registry's (scripts/lib/migrations.sh), and the registry's old path is the gate's FP_OLD" {
    run --separate-stderr bash -c 'source "$1"; for i in "${!MIG_ID[@]}"; do [[ "${MIG_ID[$i]}" != failure-patterns-out-of-thoughts ]] || printf "%s\n%s\n" "${MIG_PATH[$i]}" "${MIG_REMEDY[$i]}"; done' _ "$REPO_ROOT/scripts/lib/migrations.sh"
    [ "${lines[0]}" = "$FPO" ] && [ "${lines[1]}" = "git mv $FPO $FPL" ] || { echo "$output $stderr"; return 1; }
    grep -qxF "FP_OLD=$FPO" "$REPO_ROOT/scripts/build-loop.sh" || { echo "FP_OLD is not $FPO"; return 1; }
    grep -qxF "FP_LIB=$FPL" "$REPO_ROOT/scripts/build-loop.sh" || { echo "FP_LIB is not $FPL"; return 1; }
    grep -qxF 'FP_REMEDY="git mv $FP_OLD $FP_LIB"' "$REPO_ROOT/scripts/build-loop.sh"
}

@test "--check self-merges a docs/thoughts/ note its Paths: line lists, but never docs/failure-patterns.md or its old path (brief 2026-10-31-failure-patterns-out-of-thoughts)" {
    smb "Paths: docs/thoughts/ docs/failure-patterns.md"
    onx 'mkdir -p docs/thoughts && echo x > docs/thoughts/x.md'
    chk "$B"
    [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $B "* ]] && [ -z "$stderr" ] || { show; return 1; }
    has "path $B A docs/thoughts/x.md"
    onx 'entry 001 > "$FPL"'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 1 1)" ] || { show; return 1; }
    has "deny $B A docs/failure-patterns.md: $REC"
    # In a repo not yet migrated, the old path stays on the floor: no self-merge edits or deletes it.
    mkdir -p docs/thoughts && entry 001 > "$FPO" && commit_all "old library"
    onx 'entry 002 >> "$FPO"'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 1 1)" ] || { show; return 1; }
    has "deny $B M $FPO: $REC"
    onx 'git rm -q "$FPO"'
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "$(nref 1 1)" ] || { show; return 1; }
    has "deny $B D $FPO: $REC"
}

@test "--check over two briefs: one's failure-pattern gaps and files do not carry into the next (Q-226 [5])" {
    mkdir -p docs && entry 001 > "$FPL" && commit_all library
    brief y "Status: open" "Branch: feat/y"; y="$B"; work feat/y
    git checkout -q feat/y && git rm -q docs/working/research-2026-10-01-y.md && git commit -q -m "fix: y" && git checkout -q main
    gated feat/x; x="$B"
    chk "$y" "$x"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $y: 2 failure-pattern gaps on feat/y (gap lines follow)" ] || { show; return 1; }
    has "ok $x $(git rev-parse feat/x) $(git merge-tree --write-tree main feat/x)"
    [ "$(printf '%s\n' "$output" | grep -c "^gap $x")" -eq 0 ] || { show; return 1; }
}

@test "--check's failure-pattern gaps: one line each, after the checkout refusal and before denied paths in precedence, printed under either; a failed commit listing is a gap, not zero fixes (Q-226 [5])" {
    gated feat/x
    onb 'git rm -q "$RD"; git commit -q -m "fix: y"; mkdir -p docs && echo x > docs/roadmap.md'
    fpref 2 "its research doc $RD is not in the tip of feat/x" "$(fixgap 1)"
    has "deny $B A docs/roadmap.md: $NOWN"; has "path $B A work-feat-x.txt"
    # A git that fails the listing: the gate names it, never reads it as no fix commits.
    S="$BATS_TEST_TMPDIR/bin"; mkdir -p "$S"
    printf '#!/usr/bin/env bash\n[[ "$1" == rev-list && "$*" == *--no-commit-header* ]] && { echo boom >&2; exit 1; }\nexec %q "$@"\n' "$(command -v git)" > "$S/git"; chmod +x "$S/git"
    git branch -q -f feat/x main; onb 'git commit -q --allow-empty -m "fix: y"; echo "Failure-pattern skip: a reason" >> "$RD"'
    PATH="$S:$PATH" chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: 1 failure-pattern gaps on feat/x (gap lines follow)" ] \
        && [ "${lines[1]}" = "gap $B: the commits on feat/x could not be listed, so its fix(...) commits are unknown" ] || { show; return 1; }
    fpok
    # A research doc that cannot be read: one read gap (the environment's), and no fix gap
    # on top, though the branch has a fix commit (the skip line it holds is unseen).
    printf '#!/usr/bin/env bash\n[[ "$1" == ls-tree && "$*" == *research-* ]] && { echo boom >&2; exit 1; }\nexec %q "$@"\n' "$(command -v git)" > "$S/git"
    PATH="$S:$PATH" fpref 1 "its research doc $RD in the tip of feat/x could not be read"
}

@test "--check from a self-merge loop's own branch: the checkout refusal stays the verdict and the gap lines still print (Q-226 [5])" {
    sm; git checkout -q feat/x && git rm -q "$RD" && commit_all "drop the research doc"
    chk "$B"
    [ "$status" -eq 2 ] && [[ "${lines[0]}" == "refuse $B: $CO; "* ]] && [ "${lines[1]}" = "gap $B: its research doc $RD is not in the tip of feat/x" ] || { show; return 1; }
}
