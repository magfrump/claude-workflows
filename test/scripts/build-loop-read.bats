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
        settings '# Settings' '' "Build-loop policy: $v" '' 'Self-merge never: none'
        run --separate-stderr bash "$BL" --settings
        [ "$status" -eq 0 ] && [ "$(line policy)" = "policy $v set: line 3 of docs/dev-cycle.md on the default branch" ] \
            || { echo "$output $stderr"; return 1; }
        printf 'Build-loop policy: %s\r\n\nSelf-merge never: none\n' "$v" > docs/dev-cycle.md && commit_all cr
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
    [ "$(line slots)" = "slots 3 default: the code fence opened at line 1 of docs/dev-cycle.md is never closed, so the file is not read" ] || { echo "$output"; return 1; }
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

@test "--settings on this repo's own docs/dev-cycle.md: self-merge, set by Q-103 [2] (T3, G19)" {
    mkdir -p docs && cp "$REPO_ROOT/docs/dev-cycle.md" docs/ && commit_all real
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] || { echo "$output $stderr"; return 1; }
    [[ "$(line policy)" == "policy self-merge set: line "*" of docs/dev-cycle.md on the default branch" ]] \
        || { echo "$output"; return 1; }
    # Both spellings of the checkout and both HOMEs (Q-121, Q-123), and no prose line read as a copy.
    [ "$(line readers)" = "readers 2-roots 2-homes set: docs/dev-cycle.md on the default branch" ] || { echo "$output"; return 1; }
    # The interim never line (every directory that takes effect here without a release: plan D5, F57, Q-149) and the slots line (U5).
    [[ "$(line never)" == "never workflows/ scripts/ test/ hooks/ devcontainer-config/ skills/ guides/ patterns/ templates/ global-instructions/ set: line "*" of docs/dev-cycle.md on the default branch" ]] || { echo "$output"; return 1; }
    [[ "$(line slots)" == "slots 3 set: line "*" of docs/dev-cycle.md on the default branch" ]] || { echo "$output"; return 1; }
}

@test "--settings reads main's commit: the working tree and other branches never decide (T4)" {
    settings 'Build-loop policy: review'
    printf 'Build-loop policy: self-merge\nBuild-loop slots: 7\n\nSelf-merge never: none\n' > docs/dev-cycle.md
    settings_like policy "policy review set:"; settings_like slots "slots 3 default:"
    # A replace ref for main's blob, even with core.useReplaceRefs set, is not followed.
    git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w docs/dev-cycle.md)" && git config core.useReplaceRefs true
    settings_like policy "policy review set:"; git replace -d "$(git rev-parse main:docs/dev-cycle.md)"
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
    no='policy review unset: line 1 reads self-merge, but there is no valid Self-merge never: line ("Self-merge never: none" for an empty list), so self-merge is off'
    settings_is policy "$no"
    settings 'Build-loop policy: self-merge' 'Self-merge never: none'
    settings_is never "never none: line 2 of docs/dev-cycle.md on the default branch lists none"; settings_like policy "policy self-merge set:"
    # A never list the copy count misses (a checked task box) is skipped; with no
    # exact never line beside it, self-merge is off.
    settings 'Build-loop policy: self-merge' '- [x] Self-merge never: b/'; settings_is policy "$no"
    for v in 'Self-merge never:' 'Self-merge never: ' 'Self-merge never: a  b' 'Self-merge never: ../x' 'Self-merge never: a/../b' \
             'Self-merge never: /etc' 'Self-merge never: -x' 'Self-merge never: a b a' 'Self-merge never: a a/' $'Self-merge never: caf\xc3\xa9/' \
             $'Self-merge never: a\tb' $'Self-merge never: \ta' $'Self-merge never: a\t' $'Self-merge never: a \tb' 'Self-merge never: a ./b'; do
        settings 'Build-loop policy: self-merge' "$v"
        settings_like never "never malformed: line 2 "
        [ "$(line policy)" = "$no" ] || { echo "[$v] $output"; return 1; }
        [[ "$output" != *$'\xc3'* && "$output" != *../x* && "$output" != */etc* && "$output" != *-x* && "$output" != *./b* && "$output" != *$'\t'* ]] \
            || { echo "echoed a malformed entry: $output"; return 1; }
    done
    settings 'Build-loop policy: self-merge' 'Self-merge never: a/' '  self-merge never: b/'
    settings_is never 'never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)'; settings_is policy "$no"
    # Copies in some markup, a table, a link label or with a misplaced colon count as second lines too.
    for c in '**Self-merge never:** b/' '**Self-merge never**: b/' '## Self-merge never: b/' '_self-merge never: b/_' \
             '`Self-merge never: b/`' '| Self-merge never: | b/ |' '[Self-merge never](x): b/' 'Self-merge never : b/'; do
        settings 'Build-loop policy: self-merge' 'Self-merge never: a/' "$c"
        settings_like never 'never malformed: more than one line starts "Self-merge never:"'
    done
    # A part starting .git is allowed: the list only adds refusals.
    settings 'Build-loop policy: self-merge' 'Self-merge never: .github/ .gitignore'
    settings_like never "never .github/ .gitignore set:"; settings_like policy "policy self-merge set:"
    # A never line the next unfenced line may continue is malformed.
    settings 'Build-loop policy: self-merge' 'Self-merge never: a/' 'b/'
    settings_is never 'never malformed: line 2 is followed by a non-blank line outside a fence (it may continue the list)'
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
    [ "$(line constraints)" = "constraints none-hard: docs/constraints.md on the default branch has 2 soft constraint(s) and no hard one (H1: with a success: line)" ] \
        || { echo "$output"; return 1; }
    constraints '# Constraints' '- H1: never lose a row' '  success: the reconciliation query in test/x.bats shows equal counts' \
        '- S1: prefer small diffs' 'H2: no new dependency' '- success: package.json is unchanged in the merge'
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints ok 2-hard 1-soft: docs/constraints.md on the default branch" ] || { echo "$output"; return 1; }
    constraints '- H1: never lose a row' '- S1: small' '  success: a test'
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: hard constraint H1 (line 1) has no success: line before the next constraint or \"#\" heading" ] || { echo "$output"; return 1; }
    constraints '- H1: a' '  success: b' '- H1: c' '  success: d'
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: constraint H1 is listed twice (lines 1 and 3)" ] || { echo "$output"; return 1; }
    constraints '- H1: a' '  success: b' '[x]: http://e.invalid'
    run --separate-stderr bash "$BL" --settings
    [[ "$(line constraints)" == "constraints unreadable: line 3 of docs/constraints.md starts like a link reference definition"*", so the file is not read" ]] \
        || { echo "$output"; return 1; }
    # A line that looks like a constraint ID but is not exact: unreadable, never skipped (Q-112 [1]).
    for c in '- [x] H2: x' '* H2: x' '1. H2: x' $'H2:\tx' '  H2: x' 'h2: x' '**H2:** x' '> H2: x' 'H10 : x' '| H2 | x |' 'H01: x'; do
        constraints '- H1: a' '  success: b' "$c"; run --separate-stderr bash "$BL" --settings
        [ "$(line constraints)" = 'constraints unreadable: line 3 looks like a constraint but is not exactly "H<n>: text" or "S<n>: text" (optionally after "- ", n without a leading 0)' ] \
            || { echo "[$c] $output"; return 1; }
    done
    constraints '- S1: a' '- H1: b' '  success:'; run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: hard constraint H1 (line 2) has no success: line before the next constraint or \"#\" heading" ] || { echo "$output"; return 1; }
    constraints '- H1: a' '## Other' '  success: b'; run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: hard constraint H1 (line 1) has no success: line before the next constraint or \"#\" heading" ] || { echo "$output"; return 1; }
    constraints '- H1: a' '  success: b' '```' 'H2: hidden' '```'; run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints ok 1-hard 0-soft: docs/constraints.md on the default branch" ] || { echo "$output"; return 1; }
    git rm -q docs/constraints.md && ln -s dev-cycle.md docs/constraints.md && commit_all link
    run --separate-stderr bash "$BL" --settings
    [ "$(line constraints)" = "constraints unreadable: docs/constraints.md is not a regular file on the default branch" ] || { echo "$output"; return 1; }
}

@test "--settings prints its five lines in order and exits 0; usage errors and a missing default branch exit 1" {
    run --separate-stderr bash "$BL" --settings
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 5 ] || { echo "$output"; return 1; }
    [[ "${lines[0]}" == policy\ * && "${lines[1]}" == slots\ * && "${lines[2]}" == never\ * && "${lines[3]}" == constraints\ * && "${lines[4]}" == readers\ * ]] \
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
    settings 'Build-loop policy: self-merge' 'Self-merge never: none'
    git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub
    for d in . "$BATS_TEST_TMPDIR/wt"; do printf 'Build-loop policy: review\n' > "$d/docs/dev-cycle.md"; done; git -C "$BATS_TEST_TMPDIR/wt" commit -qam wt
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
    git update-ref refs/heads/feat/a feat/a~1 && tip feat/a "handoff: stopped: x"
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "ok $B open review feat/a stopped "*" 2 x" ]] || { echo "$output"; return 1; }
    git update-ref refs/heads/feat/a feat/a~1 && tip feat/a "handoff: stopped: ${r120}r"
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "skip $B: the tip of feat/a starts \"handoff:\" but is not a marker: its subject is not exactly"* ]] || { echo "$output"; return 1; }
    # A ready marker's body is not read here (the planned --marker reads blocked and stopped bodies).
    git update-ref refs/heads/feat/a feat/a~1 && tip feat/a "$(printf 'handoff: ready\n\nAll green.')"
    run --separate-stderr bash "$BL" --status "$B"
    [[ "$output" == "ok $B open review feat/a ready "* ]] || { echo "$output"; return 1; }
}

@test "--status: spoofed markers are skips or read as working, and a bad reason is not echoed (T7)" {
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
    # A hand-made object with two tree lines, the parent's last: git stops at the
    # second and sees no parent; a reader taking the last tree would say ready.
    o="$(printf 'tree %s\ntree %s\nparent %s\nauthor t <t> 0 +0000\ncommitter t <t> 0 +0000\n\nhandoff: ready\n' \
        "$(git rev-parse "main^{tree}")" "$(git rev-parse "$base^{tree}")" "$base" | git hash-object -t commit --literally -w --stdin)"
    git update-ref refs/heads/feat/a "$o"
    check "skip $B: $n: it has no parent" two-trees
    # A marker whose message body holds a NUL byte (one commit on top of base, with its tree).
    o="$(printf 'tree %s\nparent %s\nauthor t <t> 0 +0000\ncommitter t <t> 0 +0000\n\nhandoff: ready\n\n\0x\n' "$(git rev-parse "$base^{tree}")" "$base" \
        | git hash-object -t commit --literally -w --stdin)"
    git update-ref refs/heads/feat/a "$o"
    check "skip $B: $n: it holds a NUL byte" nul
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
            settings "Build-loop policy: $s" "" "Self-merge never: none"
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
    # Colour config on, or a git grep that fails, never empties the check: the first
    # still finds the pair, the second skips every open brief.
    git config color.ui always && git config color.grep always
    run --separate-stderr bash "$BL" --status "$a"
    [ "$output" = "skip $a: another open brief on the default branch names the same branch (compared ignoring case)" ] || { echo "$output"; return 1; }
    git config grep.patternType bogus
    run --separate-stderr bash "$BL" --status "$d" "$c"
    [ "${lines[0]}" = "skip $d: the open briefs on the default branch could not be listed" ] \
        && [[ "${lines[1]}" == "ok $c done "* ]] || { echo "$output"; return 1; }
    git config --unset grep.patternType && git config --unset color.ui && git config --unset color.grep
    # An open brief left in closed/ counts too.
    mkdir -p docs/working/briefs/closed && printf 'Status: open\nBranch: feat/d\n' > docs/working/briefs/closed/2026-10-01-old.md && commit_all closed
    run --separate-stderr bash "$BL" --status "$d"
    [[ "$output" == "skip $d: another open brief"* ]] || { echo "$output"; return 1; }
    git rm -q docs/working/briefs/closed/2026-10-01-old.md && commit_all reopen
    # An open brief only in the working tree does not count.
    printf 'Status: open\nBranch: feat/d\n' > docs/working/briefs/2026-10-01-wt.md
    run --separate-stderr bash "$BL" --status "$d"
    [ "$output" = "ok $d open review feat/d absent - - 0" ] || { echo "$output"; return 1; }
}

@test "--settings: deferred cases: reasons, review with a malformed never line, the next-line rule, an absent file, a caller's config (U1d)" {
    local f=$'\x60\x60\x60'
    settings 'Build-loop policy: self-merge' 'Self-merge never: a ../b'
    settings_is never "never malformed: line 2 lists entry 2, which is not an allowed glob form"
    settings 'Build-loop policy: self-merge' 'Self-merge never: a b a'
    settings_is never "never malformed: line 2 lists entry 3 twice"
    # Under review a malformed never line leaves the policy as written.
    settings 'Build-loop policy: review' 'Self-merge never: ../x'
    settings_is policy "policy review set: line 1 of docs/dev-cycle.md on the default branch"
    # The next line outside a fence decides; a whitespace-only line is blank.
    settings 'Build-loop policy: self-merge' 'Self-merge never: a/' "$f" 'x' "$f" ''
    settings_like never "never a/ set:"
    settings 'Build-loop policy: self-merge' 'Self-merge never: a/' "$f" 'x' "$f" 'b/'
    settings_like never "never malformed: line 2 is followed by a non-blank line"
    settings 'Build-loop policy: self-merge' 'Self-merge never: a/' $' \t '
    settings_like never "never a/ set:"
    git rm -q docs/dev-cycle.md && commit_all rm
    settings_is slots "slots 3 default: no docs/dev-cycle.md on the default branch"
    # A caller's own GIT_CONFIG_COUNT does not stop the guard (that the caller's pairs
    # still reach git is asserted in the --status deferred-cases test).
    settings 'Build-loop policy: review' '' 'Self-merge never: none'
    printf 'Build-loop policy: self-merge\n\nSelf-merge never: none\n' > x.md
    git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w x.md)"
    git config core.useReplaceRefs true
    run --separate-stderr env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller bash "$BL" --settings
    [[ "$(line policy)" == "policy review set:"* ]] || { echo "$output $stderr"; return 1; }
    git replace -d "$(git rev-parse main:docs/dev-cycle.md)"
}

@test "build-loop.sh -h and --help print the header from its first line through its last (U1d)" {
    for h in -h --help; do
        run --separate-stderr bash "$BL" "$h"
        [ "$status" -eq 0 ] && [[ "${lines[0]}" == "The build-loop handoff's state and checks"* ]] \
            && [[ "${lines[${#lines[@]}-1]}" == *"or no default branch found by name." ]] || { echo "$h: $output"; return 1; }
    done
}

@test "--status: deferred cases: no open brief, F31's open-only filter, CRLF, an unanchored closed, BRIEF kept, a caller's config pair, a NUL in a brief (U1d)" {
    settings 'Build-loop policy: review'
    # No open brief on main at all (git grep exits 1): a done brief reads normally.
    # (A done brief never reads F31's answer, so this cannot tell exit 1 from a failure.)
    brief d 'Status: done' 'Branch: feat/x' 'Dispatched: 0' && d="$B"
    run --separate-stderr bash "$BL" --status "$d"
    [ "$output" = "ok $d done review feat/x absent - - 0" ] || { echo "$output"; return 1; }
    # A done brief sharing an open brief's branch does not make the open one skip,
    # even with a later "Status: open" line that git grep lists (F31's own filter).
    printf 'Status: done\nBranch: feat/x\nStatus: open\n' > "$d"
    commit_all d-later-open
    brief o 'Status: open' 'Branch: feat/x' 'Dispatched: 99' && o="$B"
    run --separate-stderr bash "$BL" --status "$o"
    [ "$output" = "ok $o open review feat/x absent - - 99" ] || { echo "$output"; return 1; }
    # Another open brief (CRLF line endings) on the same branch counts.
    brief p 'Status: open' 'Branch: feat/x' 'Dispatched: 3'
    printf 'Status: open\r\nBranch: feat/x\r\n' > "$B"
    commit_all crlf
    run --separate-stderr bash "$BL" --status "$o"
    [[ "$output" == "skip $o: another open brief"* ]] || { echo "$output"; return 1; }
    git rm -q "$B" && commit_all rm-p
    # A directory whose name merely contains "closed" is not closed/.
    mkdir -p docs/working/briefs/2026-10-0closed
    printf 'Status: open\nBranch: feat/x\n' > docs/working/briefs/2026-10-0closed/1-x.md
    commit_all odd-dir
    run --separate-stderr bash "$BL" --status "$o"
    [ "$output" = "ok $o open review feat/x absent - - 99" ] || { echo "$output"; return 1; }
    # Another open brief on another branch, read by F31 after o, leaves o's fields alone.
    brief q 'Status: open' 'Branch: feat/q' 'Dispatched: 3'
    run --separate-stderr bash "$BL" --status "$o"
    [ "$output" = "ok $o open review feat/x absent - - 99" ] || { echo "$output"; return 1; }
    # A caller's own GIT_CONFIG_COUNT pair still reaches git beside the guard pair.
    run --separate-stderr env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=grep.patternType GIT_CONFIG_VALUE_0=bogus bash "$BL" --status "$o"
    [ "$output" = "skip $o: the open briefs on the default branch could not be listed" ] || { echo "$output"; return 1; }
    # A NUL byte refuses the brief, naming the line.
    brief n 'Status: open' $'Branch: feat/\x01n' && printf 'Status: open\nBranch: feat/n\0x\n' > "$B" && commit_all nul
    run --separate-stderr bash "$BL" --status "$B"
    [ "$output" = "skip $B: line 2 holds a NUL byte, so the brief is not read" ] || { echo "$output"; return 1; }
}

@test "--settings: Reader roots and Reader homes give the readers line; any other form is malformed and never echoed (U2b3b1)" {
    W='docs/dev-cycle.md on the default branch'
    settings 'Build-loop policy: review'
    settings_is readers 'readers none: no line starts "Reader roots:" or "Reader homes:"'
    git rm -q docs/dev-cycle.md && commit_all gone
    settings_is readers "readers none: no docs/dev-cycle.md on the default branch"
    settings 'Reader roots: /host/cw /host/cw-2' '' 'Reader homes: none'; settings_is readers "readers 2-roots 0-homes set: $W"
    settings 'Reader homes: /home/u_1/x.y'; settings_is readers "readers 0-roots 1-homes set: $W"
    # One trailing CR is dropped, as on the policy line; a fenced copy is not read.
    printf 'Reader roots: /host/cw\r\n\n```\nReader roots: rel\n```\n' > docs/dev-cycle.md && commit_all cr
    settings_is readers "readers 1-roots 0-homes set: $W"
    M='readers malformed: line 1 lists entry 1, which is not an absolute path of letters, digits and . _ - / with no empty, . or .. part; both import walks fail'
    for v in 'Reader roots: rel' 'Reader roots: /' 'Reader roots: //a' 'Reader roots: /a/' 'Reader roots: /a//b' 'Reader roots: /a/../b' \
             'Reader roots: /a/./b' 'Reader roots: /..' 'Reader homes: ~/x' 'Reader roots: none /a' $'Reader roots: /caf\xc3\xa9' 'Reader roots: /a*b' \
             'Reader roots: /a:b' $'Reader roots: /a\t/b'; do
        settings "$v"; settings_is readers "$M"
        [[ "$output" != *caf* && "$output" != *'/a'* && "$output" != *'~/x'* && "$output" != *rel* ]] || { echo "echoed [$v]: $output"; return 1; }
    done
    settings 'Reader roots: /a /b /a'; settings_is readers 'readers malformed: line 1 lists entry 3 twice; both import walks fail'
    N='readers malformed: line 1 is not exactly "Reader roots: PATH ..." with single spaces; both import walks fail'
    for v in 'Reader roots:' 'Reader roots: ' 'Reader roots: /a  /b' 'Reader roots:  /a' 'Reader roots: /a ' \
             'Reader roots : /a' 'reader roots: /a'; do
        settings "$v"; settings_is readers "$N"
    done
    # A copy in markup, a continued line, or a file FENCE_AWK refuses: malformed too.
    settings 'Reader homes: /h' '' '- **Reader homes:** /g'
    settings_is readers 'readers malformed: more than one line starts "Reader homes:" (lines 1 and 3); both import walks fail'
    settings 'Reader roots: /a' '/b'; settings_is readers 'readers malformed: line 1 is followed by a non-blank line outside a fence (it may continue the list); both import walks fail'
    settings 'Reader roots: /a' '' $'\x60\x60\x60'
    settings_is readers 'readers malformed: the code fence opened at line 3 of docs/dev-cycle.md is never closed, so the file is not read; both import walks fail'
    # Only main's commit decides: a loop's branch and the working tree are ignored.
    settings 'Reader roots: /host/cw'
    git checkout -q -b loop && printf 'Reader roots: rel\n' > docs/dev-cycle.md && commit_all loop
    printf 'Reader roots: /a /b\n' > docs/dev-cycle.md
    settings_is readers "readers 1-roots 0-homes set: $W"
}
