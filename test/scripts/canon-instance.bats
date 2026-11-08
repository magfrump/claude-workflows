#!/usr/bin/env bats
# @category fast
# Contract tests for scripts/canon-instance.py (spec: section 10 of
# docs/working/research-2026-11-05-canon-proposal-filter.md). Each refusal case
# asserts exit 1 and the named reason, so a case fails if its check is removed.
# The fixture is a local git repo; the script runs python3 and git only.

bats_require_minimum_version 1.5.0

load ../lib/hermetic-env

setup() {
    pin_hermetic_locale
    # shellcheck disable=SC2046  # word splitting is wanted: one name per line
    unset $(git rev-parse --local-env-vars)
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    CI="$REPO_ROOT/scripts/canon-instance.py"
    R="$BATS_TEST_TMPDIR/repo"
    git init -q -b main "$R"
    printf 'echo one\n' > "$R/a.sh"
    git -C "$R" add a.sh && git -C "$R" commit -q -m base
    BASE=$(git -C "$R" rev-parse HEAD)
    printf 'echo one\necho two\n' > "$R/a.sh"
    printf 'x\n' > "$R/b.py"
    git -C "$R" add a.sh b.py && git -C "$R" commit -q -m change
    HEAD_SHA=$(git -C "$R" rev-parse HEAD)
    # The fix commit after review: the answer key a clone must not hold.
    printf 'echo fixed\n' > "$R/a.sh"
    git -C "$R" commit -q -am fix
    FIX=$(git -C "$R" rev-parse HEAD)
    RUB="$BATS_TEST_TMPDIR/rubric.md"
    cat > "$RUB" <<'EOF'
# Code Review Rubric

## 🔴 Must Fix

| # | Finding | Source | Status |
|---|---|---|---|
| R1 | Option-like name reaches `git log` | security | fixed |

## 🟡 Must Address

| # | Source | Finding | Status |
|---|---|---|---|
| A1 | fact-check | Window drops the record day, a \| b | fixed |
| A2 | api | Failure shown as success | fixed |

## 🟢 Consider

| # | Finding | Status |
|---|---|---|
| C1 | Wording | fixed |
EOF
    LEDGER="$BATS_TEST_TMPDIR/ledger.csv"
    printf 'issue ID,issue summary,repo,commit ID,E2 raised,fix status (including commit ID if fixed)\n' > "$LEDGER"
    cd "$BATS_TEST_TMPDIR" || return 1
}

ci() { run python3 "$CI" --repo "$R" --id fx --rubric "$RUB" "$@"; }

refused() { # $1: the reason text the refusal must name
    [ "$status" -eq 1 ] || { echo "status $status: $output"; return 1; }
    [[ "$output" == *"refused: "*"$1"* ]] || { echo "$output"; return 1; }
}

@test "a good range prints the canon row and one ledger row per red or amber" {
    ci --base "$BASE" --head "$HEAD_SHA" --ledger-csv "$LEDGER" --repo-name fixture
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "${lines[0]}" == "| fx | \`${BASE:0:8}..${HEAD_SHA:0:8}\` | 2f +2/−0 | \`$RUB\` | 🔴 DOES NOT PASS | 1/2/1 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"fx-R1,Option-like name reaches git log,fixture,${HEAD_SHA:0:8},not run,TODO: fix commit"* ]]
    # parsed by header name: Finding is the third column in the amber table
    [[ "$output" == *'fx-A1,"Window drops the record day, a | b",fixture'* ]]
    [[ "$output" == *"fx-A2,Failure shown as success"* ]]
    [[ "$output" != *"fx-C1"* ]]
}

@test "it writes neither canon file" {
    cp "$LEDGER" "$BATS_TEST_TMPDIR/ledger.before"
    ls -A "$BATS_TEST_TMPDIR" > "$BATS_TEST_TMPDIR/ls.before"
    ci --base "$BASE" --head "$HEAD_SHA" --ledger-csv "$LEDGER"
    [ "$status" -eq 0 ]
    cmp "$LEDGER" "$BATS_TEST_TMPDIR/ledger.before"
    ls -A "$BATS_TEST_TMPDIR" | diff - "$BATS_TEST_TMPDIR/ls.before"
    [ -z "$(git -C "$R" status --porcelain)" ]
}

@test "refuses a base that does not resolve" {
    ci --base 0123456789abcdef0123 --head "$HEAD_SHA"
    refused "base 0123456789abcdef0123 does not resolve"
}

@test "refuses a revision spelled like an option" {
    ci --base "$BASE" --head=--output=x
    refused "is empty or spelled like an option"
    [ ! -e "$BATS_TEST_TMPDIR/x" ]
}

@test "refuses base equal to head as an empty range" {
    ci --base "$HEAD_SHA" --head "$HEAD_SHA"
    refused "empty range: base and head are the same commit"
}

@test "refuses a base that is not an ancestor of head" {
    ci --base "$FIX" --head "$HEAD_SHA"
    refused "is not an ancestor of head"
}

@test "refuses a range that changes no file" {
    git -C "$R" commit -q --allow-empty -m empty
    ci --base "$FIX" --head HEAD
    refused "changes no file"
}

@test "refuses a range that changes only docs/" {
    mkdir -p "$R/docs" && printf 'n\n' > "$R/docs/n.md"
    git -C "$R" add docs && git -C "$R" commit -q -m docs
    ci --base "$FIX" --head HEAD
    refused "changes only docs/"
}

@test "refuses more than 10 files outside docs/" {
    for i in $(seq 1 11); do printf '%s\n' "$i" > "$R/f$i.sh"; done
    git -C "$R" add . && git -C "$R" commit -q -m many
    ci --base "$FIX" --head HEAD
    refused "over the size limit: 11 files outside docs/ (limit 10)"
}

@test "refuses more than 500 changed lines outside docs/, but not docs/ lines" {
    mkdir -p "$R/docs" && seq 1 900 > "$R/docs/big.md" && seq 1 400 > "$R/c.sh"
    git -C "$R" add . && git -C "$R" commit -q -m docs-heavy
    ci --base "$FIX" --head HEAD
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    seq 1 501 > "$R/c.sh" && git -C "$R" commit -q -am big
    ci --base "$FIX" --head HEAD
    refused "over the size limit: 501 changed lines outside docs/ (limit 500)"
}

@test "refuses a rubric with no Finding column" {
    printf '| # | Issue | Status |\n|---|---|---|\n| R1 | x | y |\n' > "$RUB"
    ci --base "$BASE" --head "$HEAD_SHA"
    refused "rubric has no table with a Finding column"
}

@test "refuses a rubric row with no severity rather than passing it" {
    printf '## Findings\n\n| # | Finding |\n|---|---|\n| 1 | real bug |\n' > "$RUB"
    ci --base "$BASE" --head "$HEAD_SHA"
    refused "rubric row '1' has no severity"
}

@test "refuses a rubric that is not UTF-8 with a named reason" {
    printf '| # | Finding |\n|---|---|\n| R1 | caf\xe9 |\n' > "$RUB"
    ci --base "$BASE" --head "$HEAD_SHA"
    refused "input is not UTF-8"
    [[ "$output" != *Traceback* ]]
}

@test "refuses a repo that is not a git repository" {
    mkdir "$BATS_TEST_TMPDIR/plain"
    run python3 "$CI" --repo "$BATS_TEST_TMPDIR/plain" --id fx --rubric "$RUB" --base "$BASE" --head "$HEAD_SHA"
    refused "is not a git repository"
}

@test "the default repo name is the repository's, even from a linked worktree" {
    git -C "$R" worktree add -q "$BATS_TEST_TMPDIR/wt-other" "$HEAD_SHA"
    run python3 "$CI" --repo "$BATS_TEST_TMPDIR/wt-other" --id fx --rubric "$RUB" --base "$BASE" --head "$HEAD_SHA"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "$output" == *"fx-R1,Option-like name reaches git log,repo,"* ]]
}

@test "refuses a ledger header missing a named column" {
    printf 'issue ID,summary,repo,commit ID,fix status\n' > "$LEDGER"
    ci --base "$BASE" --head "$HEAD_SHA" --ledger-csv "$LEDGER"
    refused "ledger header has no column starting 'issue summary'"
}

@test "--rubric-commit reads the rubric pinned at that commit, not the working file" {
    mkdir -p "$R/docs/reviews" && cp "$RUB" "$R/docs/reviews/r.md"
    git -C "$R" add docs && git -C "$R" commit -q -m rubric
    PIN=$(git -C "$R" rev-parse HEAD)
    printf '| # | Finding |\n|---|---|\n' > "$R/docs/reviews/r.md"
    run python3 "$CI" --repo "$R" --id fx --rubric docs/reviews/r.md --rubric-commit "$PIN" --base "$BASE" --head "$HEAD_SHA"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "${lines[0]}" == *"docs/reviews/r.md@${PIN:0:8}"*"| 1/2/1 |"* ]]
    run python3 "$CI" --repo "$R" --id fx --rubric docs/reviews/none.md --rubric-commit "$PIN" --base "$BASE" --head "$HEAD_SHA"
    refused "rubric docs/reviews/none.md is not in commit"
}

@test "an inherited GIT_DIR does not redirect the script to another repository" {
    V="$BATS_TEST_TMPDIR/victim"
    git init -q -b main "$V" && git -C "$V" commit -q --allow-empty -m v
    GIT_DIR="$V/.git" run python3 "$CI" --repo "$R" --id fx --rubric "$RUB" --base "$BASE" --head "$HEAD_SHA"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "${lines[0]}" == *"${HEAD_SHA:0:8}"* ]]
}

@test "--clone builds a scrubbed clone with no answer key" {
    ci --base "$BASE" --head "$HEAD_SHA" --clone "$BATS_TEST_TMPDIR/cl"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "$output" == *"clone $BATS_TEST_TMPDIR/cl: ok, 1 commit(s) under review"* ]]
    [ "$(git -C "$BATS_TEST_TMPDIR/cl" rev-parse review)" = "$HEAD_SHA" ]
    [ "$(git -C "$BATS_TEST_TMPDIR/cl" rev-parse main)" = "$BASE" ]
    [ -z "$(git -C "$BATS_TEST_TMPDIR/cl" remote)" ]
    run git -C "$BATS_TEST_TMPDIR/cl" cat-file -e "$FIX"
    [ "$status" -ne 0 ]
}

@test "--clone refuses an existing destination" {
    mkdir "$BATS_TEST_TMPDIR/cl"
    ci --base "$BASE" --head "$HEAD_SHA" --clone "$BATS_TEST_TMPDIR/cl"
    refused "clone destination $BATS_TEST_TMPDIR/cl already exists"
}

@test "--clone notes a review inside the range that names a commit of the range" {
    MID=$(git -C "$R" rev-parse HEAD)
    mkdir -p "$R/docs/reviews" && printf 'Commit: %s\n' "${MID:0:7}" > "$R/docs/reviews/pass1.md"
    printf 'y\n' > "$R/c.sh"
    git -C "$R" add . && git -C "$R" commit -q -m pass1-review
    ci --base "$BASE" --head HEAD --clone "$BATS_TEST_TMPDIR/cl"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "$output" == *"clone note: docs/reviews/pass1.md names a commit inside the range"* ]]
}

# Guard (b)'s own case cannot be built honestly: a commit's tree cannot name
# the commit's own hash. So its detector is tested directly on a clone, and the
# refusal's wiring by the source line that calls it.
@test "guard (b): reviews_naming finds the docs/reviews file naming a hash prefix" {
    mkdir -p "$R/docs/reviews" "$R/other" && printf 'Commit: abc1234\n' > "$R/docs/reviews/own.md"
    printf 'abc1234\n' > "$R/other/x.md"
    git -C "$R" add . && git -C "$R" commit -q -m reviews
    run python3 -I -c 'import importlib.util,sys
spec = importlib.util.spec_from_file_location("ci", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
print(m.reviews_naming(sys.argv[2], ["abc1234"])); print(m.reviews_naming(sys.argv[2], ["fff0000"]))' "$CI" "$R"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [ "${lines[0]}" = "['docs/reviews/own.md']" ]
    [ "${lines[1]}" = "[]" ]
    grep -q 'own = reviews_naming(dest, \[head\[:7\]\])' "$CI"
    grep -q 'raise Refusal("guard (b): the tree has its own review' "$CI"
}
