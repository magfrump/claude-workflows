#!/usr/bin/env bats
# @category fast
# Contract tests for scripts/build-loop.sh's read modes. Each test builds a
# throwaway repo under $BATS_TEST_TMPDIR (test/lib/build-loop-fixtures.bash);
# this repo is untouched. The lib it sources (scripts/lib/dev-cycle-read.sh)
# is also tested from dev-cycle.sh's side, in test/scripts/dev-cycle.bats.

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() { bl_setup; }

@test "--settings: an exact policy line is set, a trailing CR included (T1)" {
    for v in self-merge review; do
        settings '# Settings' '' "Build-loop policy: $v"
        run --separate-stderr bash "$BL" --settings
        [ "$status" -eq 0 ] && [ "$(line policy)" = "policy $v set: line 3 of docs/dev-cycle.md on the default branch" ] \
            || { echo "$output $stderr"; return 1; }
        printf 'Build-loop policy: %s\r\n' "$v" > docs/dev-cycle.md && commit_all cr
        settings_is policy "policy $v set: line 1 of docs/dev-cycle.md on the default branch"
    done
}

@test "--settings: policy variants are unset, so review, and say why (T2)" {
    n='is not exactly "Build-loop policy: self-merge" or "Build-loop policy: review"'
    for v in 'Build-loop policy: self-merge (interim; Q-103)' 'Build-loop policy: Self-merge' \
             'build-loop policy: self-merge' 'Build-loop policy: self-merge ' 'Build-loop policy:  self-merge'; do
        settings x "$v"
        settings_is policy "policy review unset: line 2 $n"
    done
    settings 'Build-loop policy: self-merge' '' '> Build-loop policy: self-merge'
    settings_is policy 'policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 3)'
    for c in '- Build-loop policy: review' '**Build-loop policy:** review' '# Build-loop policy: review' $'\xef\xbb\xbfBuild-loop policy: review' \
             '**Build-loop policy**: review' '<!-- Build-loop policy: review -->'; do
        settings 'Build-loop policy: self-merge' "$c"
        settings_is policy 'policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 2)'
    done
    # shellcheck disable=SC2016  # literal backticks in the prose line
    settings '# none here' 'The policy is `Build-loop policy: self-merge` in prose.'
    settings_is policy 'policy review unset: no line starts "Build-loop policy:"'
}

@test "--settings: a fenced line, an open comment, a BOM or a file that is not plain on main reads review (T3)" {
    local f=$'\x60\x60\x60'
    settings "$f" 'Build-loop policy: self-merge' "$f"
    settings_is policy 'policy review unset: no line starts "Build-loop policy:"'
    settings 'text <!-- open' 'Build-loop policy: self-merge'
    settings_is policy "policy review unset: line 1 of docs/dev-cycle.md opens an HTML comment that does not close on the same line, so the file is not read"
    [ "$(line never)" = "never malformed: line 1 of docs/dev-cycle.md opens an HTML comment that does not close on the same line, so the file is not read" ] \
        || { echo "$output"; return 1; }
    settings $'\xef\xbb\xbfBuild-loop policy: self-merge'
    settings_like policy "policy review unset: line 1 of docs/dev-cycle.md starts with a byte-order mark"
    settings "$f" 'Build-loop policy: self-merge'
    settings_is policy "policy review unset: the code fence opened at line 1 of docs/dev-cycle.md is never closed, so the file is not read"
    # Missing, a symlink, a directory, and a file only in the working tree.
    git rm -q docs/dev-cycle.md && commit_all rm
    settings_is policy "policy review unset: no docs/dev-cycle.md on the default branch"
    settings_is never "never none: no docs/dev-cycle.md on the default branch"
    mkdir -p docs && printf 'Build-loop policy: self-merge\n' > real.md && ln -s ../real.md docs/dev-cycle.md && commit_all link
    settings_is policy "policy review unset: docs/dev-cycle.md is not a regular file on the default branch"
    git rm -q docs/dev-cycle.md && mkdir -p docs/dev-cycle.md && echo x > docs/dev-cycle.md/y && commit_all dir
    settings_is policy "policy review unset: docs/dev-cycle.md is not a regular file on the default branch"
    git rm -rq docs && rm -rf docs && mkdir real-docs && printf 'Build-loop policy: self-merge\n' > real-docs/dev-cycle.md
    ln -s real-docs docs && commit_all dirlink
    settings_is policy "policy review unset: docs is not a directory on the default branch"
    git rm -q docs && commit_all unlink && mkdir docs && printf 'Build-loop policy: self-merge\n' > docs/dev-cycle.md
    settings_is policy "policy review unset: no docs/dev-cycle.md on the default branch"
}

@test "--settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)" {
    mkdir -p docs && cp "$REPO_ROOT/docs/dev-cycle.md" docs/ && commit_all real
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] || { echo "$output $stderr"; return 1; }
    [[ "$(line policy)" == "policy review unset: line "*' is not exactly "Build-loop policy: self-merge" or "Build-loop policy: review"' ]] \
        || { echo "$output"; return 1; }
}

@test "--settings reads main's commit: the working tree and other branches never decide (T4)" {
    settings 'Build-loop policy: review'
    printf 'Build-loop policy: self-merge\nBuild-loop slots: 7\n' > docs/dev-cycle.md
    settings_like policy "policy review set:"; settings_like slots "slots 3 default:"
    # Committed on a checked-out loop branch: HEAD is not main.
    git checkout -q -b loop && commit_all raise
    settings_like policy "policy review set:"
    git checkout -q main
    git merge -q loop && git checkout -q -b lower && printf 'Build-loop policy: review\n' > docs/dev-cycle.md
    settings_like policy "policy self-merge set:"; settings_is slots "slots 7 set: line 2 of docs/dev-cycle.md on the default branch"
}

@test "--settings: slots are 1 to 9 on one exact line, else 3 (T1-T3 slots)" {
    settings 'Build-loop slots: 5'
    settings_is slots "slots 5 set: line 1 of docs/dev-cycle.md on the default branch"
    for v in 'Build-loop slots: 0' 'Build-loop slots: 10' 'Build-loop slots: 3 ' 'Build-loop slots: 05' 'Build-loop slots: three'; do
        settings "$v"
        settings_is slots 'slots 3 default: line 1 is not exactly "Build-loop slots: N" with N from 1 to 9'
    done
    settings 'Build-loop slots: 4' 'Build-loop slots: 4'
    settings_is slots 'slots 3 default: more than one line starts "Build-loop slots:" (lines 1 and 2)'
    settings $'\x60\x60\x60' 'Build-loop slots: 4' $'\x60\x60\x60'
    settings_is slots 'slots 3 default: no line starts "Build-loop slots:"'
}

@test "--settings: Self-merge never: is one line of allowed globs; anything else is malformed and turns self-merge off (T45)" {
    settings 'Build-loop policy: self-merge' 'Self-merge never: workflows/ hooks/*.sh docs/x?.md'
    run --separate-stderr bash "$BL" --settings
    [ "$(line never)" = "never workflows/ hooks/*.sh docs/x?.md set: line 2 of docs/dev-cycle.md on the default branch" ] \
        && [[ "$(line policy)" == "policy self-merge set:"* ]] || { echo "$output"; return 1; }
    settings 'Build-loop policy: self-merge'
    settings_is never 'never none: no line starts "Self-merge never:"'
    for v in 'Self-merge never:' 'Self-merge never: ' 'Self-merge never: a  b' 'Self-merge never: ../x' 'Self-merge never: a/../b' \
             'Self-merge never: /etc' 'Self-merge never: -x' 'Self-merge never: a b a' 'Self-merge never: a a/' $'Self-merge never: caf\xc3\xa9/' \
             $'Self-merge never: a\tb' $'Self-merge never: \ta' $'Self-merge never: a\t' $'Self-merge never: a \tb' 'Self-merge never: a ./b'; do
        settings 'Build-loop policy: self-merge' "$v"
        settings_like never "never malformed: line 2 "
        [ "$(line policy)" = "policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off" ] \
            || { echo "[$v] $output"; return 1; }
        [[ "$output" != *$'\xc3'* && "$output" != *../x* && "$output" != */etc* && "$output" != *-x* && "$output" != *./b* && "$output" != *$'\t'* ]] \
            || { echo "echoed a malformed entry: $output"; return 1; }
    done
    settings 'Build-loop policy: self-merge' 'Self-merge never: a/' '  self-merge never: b/'
    settings_is never 'never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)'
    # Copies in markup, a table, a link or with a misplaced colon count as second lines too.
    for c in '**Self-merge never:** b/' '**Self-merge never**: b/' '## Self-merge never: b/' '_self-merge never: b/_' \
             '`Self-merge never: b/`' '| Self-merge never: | b/ |' '[Self-merge never](x): b/' 'Self-merge never : b/'; do
        settings 'Build-loop policy: self-merge' 'Self-merge never: a/' "$c"
        settings_like never 'never malformed: more than one line starts "Self-merge never:"'
    done
    # A part starting .git is allowed: the list only adds refusals.
    settings 'Build-loop policy: self-merge' 'Self-merge never: .github/ .gitignore'
    settings_like never "never .github/ .gitignore set:"; settings_like policy "policy self-merge set:"
    # A never line Markdown would continue on the next line is malformed.
    settings 'Build-loop policy: self-merge' 'Self-merge never: a/' 'b/'
    settings_is never 'never malformed: line 2 is followed by a non-blank line (Markdown would join it as more globs)'
    settings 'Self-merge never: a/' '' 'Build-loop policy: self-merge'
    settings_like never "never a/ set:"
    # Raised only on a loop's branch or in the working tree: ignored.
    settings 'Build-loop policy: self-merge' 'Self-merge never: workflows/'
    git checkout -q -b loop && printf 'Build-loop policy: self-merge\nSelf-merge never: x/ ../y\n' > docs/dev-cycle.md && commit_all loop
    printf 'Build-loop policy: self-merge\n' > docs/dev-cycle.md
    settings_like never "never workflows/ set:"
}

@test "--settings: docs/constraints.md from main gives ok, missing, none-hard or unreadable (T44)" {
    settings 'Build-loop policy: review'
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints missing: no docs/constraints.md on the default branch" ] || { echo "$output"; return 1; }
    # Only in the working tree: still missing.
    printf -- '- H1: x\n  success: y\n' > docs/constraints.md
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints missing: no docs/constraints.md on the default branch" ] || { echo "$output"; return 1; }
    constraints '# Constraints' '' '- S1: prefer small diffs' 'S2: keep prose plain'
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints none-hard: docs/constraints.md on the default branch has 2 soft constraints and no hard one (H1: with a success: line)" ] \
        || { echo "$output"; return 1; }
    constraints '# Constraints' '- H1: never lose a row' '  success: the reconciliation query in test/x.bats shows equal counts' \
        '- S1: prefer small diffs' 'H2: no new dependency' '- success: package.json is unchanged in the merge'
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints ok 2-hard 1-soft: docs/constraints.md on the default branch" ] || { echo "$output"; return 1; }
    constraints '- H1: never lose a row' '- S1: small' '  success: a test'
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: hard constraint H1 (line 1) has no success: line before the next constraint" ] || { echo "$output"; return 1; }
    constraints '- H1: a' '  success: b' '- H1: c' '  success: d'
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: constraint H1 is listed twice (lines 1 and 3)" ] || { echo "$output"; return 1; }
    constraints '- H1: a' '  success: b' '[x]: http://e.invalid'
    run --separate-stderr bash "$BL" --settings
    [[ "$(line constraints)" == "constraints unreadable: line 3 of docs/constraints.md starts like a link reference definition"*", so the file is not read" ]] \
        || { echo "$output"; return 1; }
    git rm -q docs/constraints.md && ln -s dev-cycle.md docs/constraints.md && commit_all link
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: docs/constraints.md is not a regular file on the default branch" ] || { echo "$output"; return 1; }
}

@test "--settings prints its four lines in order and exits 0; usage errors and a missing default branch exit 1" {
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 4 ] || { echo "$output"; return 1; }
    [[ "${lines[0]}" == policy\ * && "${lines[1]}" == slots\ * && "${lines[2]}" == never\ * && "${lines[3]}" == constraints\ * ]] \
        || { echo "$output"; return 1; }
    for args in "" "--bogus" "--settings extra" "--status"; do
        # shellcheck disable=SC2086  # split the argument list on purpose
        run --separate-stderr bash "$BL" $args
        [ "$status" -eq 1 ] && [ -z "$output" ] && [ -n "$stderr" ] || { echo "[$args] $status $output $stderr"; return 1; }
    done
    git branch -m main trunk
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 1 ] && [[ "$stderr" == *"needs a default branch"* ]] || { echo "$output $stderr"; return 1; }
    cd "$BATS_TEST_TMPDIR"
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 1 ] && [[ "$stderr" == *"Not inside a git repository"* ]] || { echo "$output $stderr"; return 1; }
}

@test "build-loop.sh sources the lib from its own directory, never the target repo's; without it, exit 1" {
    mkdir -p scripts/lib && printf 'echo PLANTED\n' > scripts/lib/dev-cycle-read.sh && commit_all plant
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] && [[ "$output$stderr" != *PLANTED* ]] || { echo "$output $stderr"; return 1; }
    mkdir -p "$BATS_TEST_TMPDIR/bare" && cp "$BL" "$BATS_TEST_TMPDIR/bare/build-loop.sh"
    run --separate-stderr bash "$BATS_TEST_TMPDIR/bare/build-loop.sh" --settings
    [ "$status" -eq 1 ] && [ -z "$output" ] && [[ "$stderr" == *"needs $BATS_TEST_TMPDIR/bare/lib/dev-cycle-read.sh"* ]] \
        || { echo "$output $stderr"; return 1; }
    # From a subdirectory and from a linked worktree, it reads the same main.
    settings 'Build-loop policy: self-merge'
    git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub
    for d in . "$BATS_TEST_TMPDIR/wt"; do printf 'Build-loop policy: review\n' > "$d/docs/dev-cycle.md"; done
    for d in sub "$BATS_TEST_TMPDIR/wt"; do
        # shellcheck disable=SC2016  # $1 and $2 belong to the inner shell
        run --separate-stderr bash -c 'cd "$1" && bash "$2" --settings' _ "$d" "$BL"
        [[ "$(line policy)" == "policy self-merge set:"* ]] || { echo "[$d] $output $stderr"; return 1; }
    done
}

@test "--status: each loop state with every field (T6)" {
    settings 'Build-loop policy: review'
    brief a 'Status: open' 'Branch: feat/a' 'Dispatched: 2'
    run --separate-stderr bash "$BL" --status "$B"
    [ "$status" -eq 0 ] && [ "$output" = "ok $B open review feat/a absent - - 2" ] || { echo "$output $stderr"; return 1; }
    git branch -q feat/a main
    run --separate-stderr bash "$BL" --status "$B"
    [ "$output" = "ok $B open review feat/a working $(git rev-parse feat/a) $(git log -1 --format=%cs feat/a) 2" ] || { echo "$output"; return 1; }
    git branch -q -D feat/a && work feat/a
    run --separate-stderr bash "$BL" --status "$B"
    [ "$output" = "ok $B open review feat/a working $(git rev-parse feat/a) $(git log -1 --format=%cs feat/a) 2" ] || { echo "$output"; return 1; }
    for m in ready blocked; do
        git branch -q -f feat/a feat/a~0 && tip feat/a "handoff: $m" && t="$(git rev-parse feat/a)"
        run --separate-stderr bash "$BL" --status "$B"
        [ "$output" = "ok $B open review feat/a $m $t $(git log -1 --format=%cs "$t") 2" ] || { echo "$output"; return 1; }
        git update-ref refs/heads/feat/a feat/a~1
    done
    r120="$(printf 'r%.0s' $(seq 120))"
    tip feat/a "handoff: stopped: $r120" && t="$(git rev-parse feat/a)"
    run --separate-stderr bash "$BL" --status "$B"
    [ "$output" = "ok $B open review feat/a stopped $t $(git log -1 --format=%cs "$t") 2 $r120" ] || { echo "$output"; return 1; }
    git update-ref refs/heads/feat/a feat/a~1 && tip feat/a "handoff: stopped: new dependency (left-pad)"
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "ok $B open review feat/a stopped "*" 2 new dependency (left-pad)" ]] || { echo "$output"; return 1; }
    git update-ref refs/heads/feat/a feat/a~1 && tip feat/a "handoff: stopped: ${r120}r"
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "skip $B: the tip of feat/a starts \"handoff:\" but is not a marker: its subject is not exactly"* ]] || { echo "$output"; return 1; }
    # A ready marker's body is not read here (--marker reads blocked and stopped bodies).
    git update-ref refs/heads/feat/a feat/a~1 && tip feat/a "$(printf 'handoff: ready\n\nAll green.')"
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "ok $B open review feat/a ready "* ]] || { echo "$output"; return 1; }
}

@test "--status: spoofed markers read as unreadable or working, and a bad reason is not echoed (T7)" {
    settings 'Build-loop policy: review'
    brief a 'Status: open' 'Branch: feat/a'
    work feat/a && base="$(git rev-parse feat/a)"
    n='the tip of feat/a starts "handoff:" but is not a marker'
    check() {
        run --separate-stderr bash "$BL" --status "$B"
        [[ "$output" == "$1"* ]] || { echo "[$2] $output"; return 1; }
        git update-ref refs/heads/feat/a "$base"
    }
    git checkout -q feat/a && echo more > more.txt && commit_all 'handoff: ready' && git checkout -q main
    check "skip $B: $n: it changes files" content
    tip feat/a 'handoff: ready' "$(git rev-parse "feat/a^{tree}")" "$base" "$(git rev-parse main)"
    check "skip $B: $n: it has 2 parents" merge
    tip feat/a 'handoff: ready' "$(git rev-parse "feat/a^{tree}")" ""
    check "skip $B: $n: it has no parent" orphan
    for s in 'handoff: blocked!' 'handoff: ready ' 'handoff:ready' 'handoff: stopped: ' 'handoff: stopped:  x' 'handoff: Ready' \
             $'handoff: stopped: a\x1b[31mb' $'handoff: stopped: caf\xc3\xa9' $'handoff: stopped: x\xe2\x80\xaey'; do
        tip feat/a "$s"
        check "skip $B: $n: its subject is not exactly" "$s"
        [[ "$output" != *$'\xc3'* && "$output" != *'[31m'* ]] || { echo "echoed: $output"; return 1; }
    done
    tip feat/a "$(printf 'handoff: ready\nmore subject')"
    check "skip $B: $n: its subject runs onto a second line" two-line
    # Not a marker at all: an ordinary commit, even one that mentions a marker.
    tip feat/a 'wip: before handoff: ready'
    check "ok $B open review feat/a working " ordinary
    # A marker at main's tip with the branch 0 commits ahead is main's, not the loop's.
    tip main 'handoff: ready' && git branch -q -f feat/a main
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "ok $B open review feat/a working $(git rev-parse main) "* ]] || { echo "$output"; return 1; }
    # So is a branch that is a symbolic ref to main.
    brief b 'Status: open' 'Branch: alias' && tip main 'handoff: ready' && git symbolic-ref refs/heads/alias refs/heads/main
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "ok $B open review alias working "* ]] || { echo "$output"; return 1; }
}

@test "--status: a brief it cannot read, or whose Branch or Dispatched line is wrong, is a skip with why (T8)" {
    local f=$'\x60\x60\x60'
    settings 'Build-loop policy: review'
    brief a 'Status: open' "  $f" 'Branch: feat/a'
    run --separate-stderr bash "$BL" --status "$B"
    [ "$output" = "skip $B: line 4 is a fence-like line that is not a plain column-0 fence, so the brief is not read" ] || { echo "$output"; return 1; }
    brief b 'Status: open'
    run --separate-stderr bash "$BL" --status "$B"
    [ "$output" = "skip $B: no Branch: line on the default branch" ] || { echo "$output"; return 1; }
    for v in 'Branch:' 'Branch:  feat/x' 'Branch: feat/x ' 'Branch: a b' 'Branch:feat/x'; do
        brief c 'Status: open' "$v"
        run --separate-stderr bash "$BL" --status "$B"
        [ "$output" = "skip $B: its first Branch: line is not exactly \"Branch: NAME\"" ] || { echo "[$v] $output"; return 1; }
    done
    brief d 'Status: open' 'Branch: main'
    run --separate-stderr bash "$BL" --status "$B"
    [ "$output" = "skip $B: Branch: the default branch" ] || { echo "$output"; return 1; }
    for v in HEAD refs/heads/x 'a..b' '-x' $'caf\xc3\xa9'; do
        brief e 'Status: open' "Branch: $v"
        run --separate-stderr bash "$BL" --status "$B"
        [[ "$output" == "skip $B: Branch: not a"*" branch name" ]] || { echo "[$v] $output"; return 1; }
        [[ "$output" != *$'\xc3'* ]] || { echo "echoed: $output"; return 1; }
    done
    for v in 'Dispatched: x' 'Dispatched: 100' 'Dispatched: 01' 'Dispatched: -1' 'Dispatched:'; do
        brief g 'Status: open' 'Branch: feat/g' "$v"
        run --separate-stderr bash "$BL" --status "$B"
        [ "$output" = "skip $B: its first Dispatched: line is not exactly \"Dispatched: N\" with N from 0 to 99" ] || { echo "[$v] $output"; return 1; }
    done
    # Not landed on main: new, with nothing else to read.
    run --separate-stderr bash "$BL" --status docs/working/briefs/2026-10-01-none.md docs/roadmap.md
    [ "${lines[0]}" = "ok docs/working/briefs/2026-10-01-none.md new review - absent - - 0" ] \
        && [[ "${lines[1]}" == "skip docs/roadmap.md: not a build brief"* ]] || { echo "$output"; return 1; }
}

@test "--status: the policy is the stricter of main's settings and the brief's Policy line (T5)" {
    for s in self-merge review; do
        for p in 'Policy: self-merge' 'Policy: review' 'Policy: Self-merge' 'Policy: self-merge ' ''; do
            settings "Build-loop policy: $s"
            brief a 'Status: open' 'Branch: feat/a' ${p:+"$p"}
            run --separate-stderr bash "$BL" --status "$B"
            want=review; [[ "$s" == self-merge && "$p" == 'Policy: self-merge' ]] && want=self-merge
            [ "$output" = "ok $B open $want feat/a absent - - 0" ] || { echo "[$s|$p] $output"; return 1; }
        done
    done
    # A malformed Self-merge never: line turns it off.
    settings 'Build-loop policy: self-merge' 'Self-merge never: ../x'
    brief a 'Status: open' 'Branch: feat/a' 'Policy: self-merge'
    run --separate-stderr bash "$BL" --status "$B"
    [ "$output" = "ok $B open review feat/a absent - - 0" ] || { echo "$output"; return 1; }
}

@test "--status reads main's commit: working-tree and branch edits to a brief's lines are ignored (T21)" {
    settings 'Build-loop policy: self-merge'
    brief a 'Status: open' 'Branch: feat/a' 'Policy: review' 'Dispatched: 1'
    work feat/a
    git checkout -q feat/a && printf '# x\nStatus: done\nBranch: feat/z\nPolicy: self-merge\nDispatched: 0\n' > "$B" && commit_all edit && git checkout -q main
    printf '# x\nStatus: dropped\nBranch: feat/y\nPolicy: self-merge\nDispatched: 0\n' > "$B"
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "ok $B open review feat/a working $(git rev-parse feat/a) "*" 1" ]] || { echo "$output"; return 1; }
}

@test "--status: two open briefs naming one branch both skip; many briefs keep their order (T28)" {
    settings 'Build-loop policy: review'
    brief a 'Status: open' 'Branch: feat/x' && a="$B"
    brief b 'Status: open' 'Branch: Feat/X' && b="$B"
    brief c 'Status: done' 'Branch: feat/x' && c="$B"
    brief d 'Status: open' 'Branch: feat/d' && d="$B"
    brief e 'Status: dropped' 'Branch: feat/e' && e="$B"
    run --separate-stderr bash "$BL" --status "$d" "$a" docs/x.md "$c" "$b" "$e"
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 6 ] || { echo "$output"; return 1; }
    [ "${lines[0]}" = "ok $d open review feat/d absent - - 0" ] || { echo "$output"; return 1; }
    [ "${lines[1]}" = "skip $a: another open brief on the default branch names the same branch (compared ignoring case)" ] || { echo "$output"; return 1; }
    [[ "${lines[2]}" == "skip docs/x.md: not a build brief"* ]] || { echo "$output"; return 1; }
    [ "${lines[3]}" = "ok $c done review feat/x absent - - 0" ] || { echo "$output"; return 1; }
    [ "${lines[4]}" = "skip $b: another open brief on the default branch names the same branch (compared ignoring case)" ] || { echo "$output"; return 1; }
    [ "${lines[5]}" = "ok $e dropped review feat/e absent - - 0" ] || { echo "$output"; return 1; }
    # An open brief only in the working tree does not count.
    printf 'Status: open\nBranch: feat/d\n' > docs/working/briefs/2026-10-01-wt.md
    run --separate-stderr bash "$BL" --status "$d"
    [ "$output" = "ok $d open review feat/d absent - - 0" ] || { echo "$output"; return 1; }
}
