#!/usr/bin/env bats
# @category fast
# Contract tests for scripts/dev-cycle.sh, the dev-cycle skill's signal digest.
# Each test builds a throwaway git repo under $BATS_TEST_TMPDIR, so nothing
# reads or writes this repo's own docs/.

bats_require_minimum_version 1.5.0

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    DC="$REPO_ROOT/scripts/dev-cycle.sh"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
    # HOME points at the temp dir so the ~/.claude/scripts fallback can't reach
    # the real installed questions.sh.
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    R="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$R"
    cd "$R" || return 1
    git init -q -b main
    git commit -q --allow-empty -m "initial"
    for n in 1 2 3; do
        git checkout -q -b "f$n"
        git commit -q --allow-empty -m "feature $n"
        git checkout -q main
        git merge -q --no-ff "f$n" -m "merge: feature $n"
    done
}

@test "prints all five sections in a repo with no docs" {
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    for h in "## 1. Activity" "## 2. Revisit triggers" "## 3. Watched questions" \
             "## 4. Spot-check sample" "## 5. Roadmap"; do
        [[ "$output" == *"$h"* ]] || { echo "missing: $h"; echo "$output"; return 1; }
    done
    [[ "$output" == *"3 merge(s)"* ]]
    [[ "$output" == *"No revisit triggers recorded."* ]]
    [[ "$output" == *"No docs/roadmap.md yet"* ]]
}

@test "lists a decision record's revisit triggers and a log row's revisit clause" {
    mkdir -p docs/decisions
    printf '# 001\n\n## Revisit triggers\nif the widget count exceeds 7.\n\n## Other\nnot a trigger\n' \
        > docs/decisions/001-widgets.md
    printf '| 9 | 2026-01-01 | **x** | Because. Revisit if gizmos appear. | ref |\n' > docs/decisions/log.md
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    [[ "$output" == *"### docs/decisions/001-widgets.md"* ]]
    [[ "$output" == *"if the widget count exceeds 7."* ]]
    [[ "$output" != *"not a trigger"* ]]
    [[ "$output" == *"row 9: Revisit if gizmos appear."* ]]
}

@test "the window defaults to the newest cycle record's date" {
    mkdir -p docs/working/cycles
    touch docs/working/cycles/cycle-2026-01-05.md docs/working/cycles/cycle-2026-02-10.md
    run --separate-stderr bash "$DC"
    [[ "$output" == *"Window: since 2026-02-10"* ]]
}

@test "--sample N lists N merges, the same ones on a rerun" {
    run --separate-stderr bash "$DC" --sample 2
    first=$(echo "$output" | sed -n '/## 4/,/## 5/p' | grep -c '^- ')
    [ "$first" -eq 2 ]
    a=$(echo "$output" | sed -n '/## 4/,/## 5/p')
    run --separate-stderr bash "$DC" --sample 2
    b=$(echo "$output" | sed -n '/## 4/,/## 5/p')
    [ "$a" = "$b" ]
}

@test "watched questions list only trigger and deferred routes, by route column" {
    mkdir -p docs/working
    cat > docs/working/questions.md <<'EOF'
# Running questions

## Index

<!-- index:start -->
<!-- index:end -->

## Open

### Q-001 · a-trigger-in-the-slug
**Needs:** agent · **Opened:** 2026-09-17 · **Status:** OPEN

Mechanical.

### Q-002 · watched-thing
**Needs:** trigger · **Opened:** 2026-09-17 · **Status:** OPEN

Watch it.
EOF
    : > docs/working/questions-archive.md
    run --separate-stderr bash "$DC"
    section=$(echo "$output" | sed -n '/## 3/,/## 4/p')
    [[ "$section" == *"Q-002"* ]]
    [[ "$section" != *"- Q-001"* ]] || { echo "$section"; return 1; }
    [[ "$section" == *"agent=1, trigger=1"* ]] || { echo "$section"; return 1; }
}

@test "rejects a malformed --since and an unknown option" {
    run --separate-stderr bash "$DC" --since 2026/01/01
    [ "$status" -eq 1 ]
    run --separate-stderr bash "$DC" --bogus
    [ "$status" -eq 1 ]
}
