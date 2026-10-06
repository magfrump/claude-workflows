#!/usr/bin/env bats
# @category fast
# Contract tests for the build-loop gate: the reader lib's import walks
# (scripts/lib/dev-cycle-read.sh isimported, import_targets; main_imports from
# U2a3) and, from U2a4 and U2b, the self-merge floor and build-loop.sh --check.
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
