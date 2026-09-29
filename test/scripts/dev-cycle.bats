#!/usr/bin/env bats
# @category fast
# Contract tests for scripts/dev-cycle.sh, the dev-cycle skill's digest. Each
# test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched.

bats_require_minimum_version 1.5.0

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    DC="$REPO_ROOT/scripts/dev-cycle.sh"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
    # HOME in the temp dir: the ~/.claude/scripts fallback can't reach the real one.
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    R="$BATS_TEST_TMPDIR/repo"
    make_repo "$R" main
    cd "$R" || return 1
}

make_repo() {
    mkdir -p "$1"
    (
        cd "$1" || exit 1
        git init -q -b "$2"
        git commit -q --allow-empty -m "initial"
        for n in 1 2 3; do
            git checkout -q -b "f$n"
            git commit -q --allow-empty -m "feature $n"
            git checkout -q "$2"
            git merge -q --no-ff "f$n" -m "merge: feature $n"
        done
    )
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
    [[ "$output" == *"no cycle record found"* ]]
}

@test "lists a decision record's revisit triggers and a log row's whole revisit clause" {
    mkdir -p docs/decisions
    printf '# 001\n\n## Revisit triggers\nif the widget count exceeds 7.\033]52;c;eA==\a\n\n## Other\nnot a trigger\n' \
        > docs/decisions/001-widgets.md
    long=$(printf 'x%.0s' $(seq 1 500))
    printf '| 9 | 2026-01-01 | **x**: revisit-trigger verdicts | Because. Revisit if gizmos appear %s end. | ref |\n' "$long" > docs/decisions/log.md
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    [[ "$output" == *"### docs/decisions/001-widgets.md"* ]]
    [[ "$output" == *"if the widget count exceeds 7."* ]]
    [[ "$output" != *"not a trigger"* && "$output" != *$'\033'* ]]
    [[ "$output" == *"log row 9 (2026-01-01): > Revisit if gizmos appear"*" end. "* ]]
}

@test "after a cycle record, unchanged triggers carry forward and changed ones print" {
    mkdir -p docs/decisions docs/working/cycles
    printf '# 001\n\n## Revisit triggers\nif old thing.\n' > docs/decisions/001-old.md
    printf '| 8 | 2020-01-01 | **x** | Revisit if ancient. | r |\n| 9 | 2099-01-01 | **y** | Revisit if future. | r |\n' > docs/decisions/log.md
    git add -A && GIT_COMMITTER_DATE="2020-01-02T12:00:00" git commit -q --date="2020-01-02T12:00:00" -m "old record"
    start=$(git rev-parse HEAD)
    printf '# 002\n\n## Revisit triggers\nif new thing.\n' > docs/decisions/002-new.md
    git add -A && git commit -q -m "new record"
    # Committed on a branch before the window, fast-forwarded into main inside it.
    git checkout -q -b late && printf '# 003\n\n## Revisit triggers\nif late thing.\n' > docs/decisions/003-late.md
    git add -A && GIT_COMMITTER_DATE="2020-01-03T12:00:00" git commit -q --date="2020-01-03T12:00:00" -m late
    git checkout -q main && git merge -q --ff-only late
    printf '\n## Other\nbulk edit\n' >> docs/decisions/001-old.md && git commit -qam "edit outside triggers"
    printf '# 004\n\n## Revisit triggers\nif uncommitted thing.\n' > docs/decisions/004-wip.md
    printf '| 7 | %s | **z** | Revisit if boundary. | r |\n' "$(date -d yesterday +%F)" >> docs/decisions/log.md
    echo "Main at: $start" > "docs/working/cycles/cycle-$(date -d yesterday +%F).md"
    run --separate-stderr bash "$DC"
    for t in "if new thing." "if late thing." "if uncommitted thing." "Revisit if boundary."; do
        [[ "$output" == *"$t"* ]] || { echo "not printed in full: $t"; return 1; }
    done
    [[ "$output" != *"if old thing."* ]]
    [[ "$output" == *"Carried forward (2): 001-old.md log row 8"* ]] || { echo "$output" | sed -n '/## 2/,/## 3/p'; return 1; }
    [[ "$output" == *"log row 9 (2099-01-01): > Revisit if future."* ]]
}

@test "the window defaults to the newest cycle record's date and says so" {
    mkdir -p docs/working/cycles
    touch docs/working/cycles/cycle-2026-01-05.md docs/working/cycles/cycle-2026-02-10.md docs/working/cycles/cycle-9999-12-31.md
    run --separate-stderr bash "$DC"
    [[ "$output" == *"Window: since 2026-02-10 (from the last cycle record"* ]]
    run --separate-stderr bash "$DC" --since=2026-03-01
    [[ "$output" == *"An explicit --since was given, so every trigger"* ]]
}

@test "--since counts from midnight, not from the current time of day" {
    GIT_COMMITTER_DATE="$(date +%F)T00:00:30" git commit -q --allow-empty --date="$(date +%F)T00:00:30" -m "just after midnight"
    # All commits here are from today, before "now": a midnight window counts all.
    total=$(git rev-list --count HEAD)
    run --separate-stderr bash "$DC" --since="$(date +%F)"
    [[ "$output" == *"; $total commit(s)"* ]] || { echo "expected $total"; echo "$output" | sed -n '/## 1/,/## 2/p'; return 1; }
}

@test "--sample N lists N merges, the same ones on a rerun" {
    run --separate-stderr bash "$DC" --sample=2
    first=$(echo "$output" | sed -n '/## 4/,/## 5/p' | grep -c '^- ')
    [ "$first" -eq 2 ]
    a=$(echo "$output" | sed -n '/## 4/,/## 5/p')
    run --separate-stderr bash "$DC" --sample 2
    b=$(echo "$output" | sed -n '/## 4/,/## 5/p')
    [ "$a" = "$b" ]
}

@test "different days sample different merges" {
    for n in $(seq 4 20); do
        git checkout -q -b "g$n"; git commit -q --allow-empty -m "g $n"
        git checkout -q main; git merge -q --no-ff "g$n" -m "merge: g $n"
    done
    samples=()
    for d in 2026-01-01 2026-01-15 2026-02-01 2026-03-01; do
        # One line per sample: the sorted merge lines joined with ";".
        out=$(DEV_CYCLE_TODAY=$d bash "$DC" --since=2000-01-01 --sample=3 | sed -n '/## 4/,/## 5/p' | grep '^- ' | sort | tr '\n' ';')
        samples+=("$out")
    done
    distinct=$(printf '%s\n' "${samples[@]}" | sort -u | wc -l)
    [ "$distinct" -ge 2 ] || { echo "all four dates sampled the same merges"; printf '%s\n' "${samples[0]}"; return 1; }
}

@test "runs from a subdirectory with a relative script path" {
    mkdir -p "$R/sub/dir"
    cp -r "$REPO_ROOT/scripts" "$BATS_TEST_TMPDIR/tools"
    cd "$R/sub/dir" || return 1
    rel=$(realpath --relative-to=. "$BATS_TEST_TMPDIR/tools/dev-cycle.sh")
    run --separate-stderr bash "$rel"
    # shellcheck disable=SC2154  # bats sets $stderr under --separate-stderr
    [ "$status" -eq 0 ] || { echo "$stderr"; return 1; }
    [[ "$output" == *"## 5. Roadmap"* ]]
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

@test "a questions.sh failure is reported, never shown as 'None open.'" {
    mkdir -p docs/working
    printf '# Running questions\n\n## Open\n\n### Q-001 · x\n**Needs:** trigger · **Opened:** 2026-09-17 · **Status:** OPEN\n' > docs/working/questions.md
    # No questions-archive.md: questions.sh open exits non-zero.
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    section=$(echo "$output" | sed -n '/## 3/,/## 4/p')
    [[ "$section" == *"questions.sh open failed"* ]] || { echo "$section"; return 1; }
    [[ "$section" != *"None open."* ]]
}

@test "a repo whose only branch is master works" {
    M="$BATS_TEST_TMPDIR/mrepo"
    make_repo "$M" master
    cd "$M" || return 1
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    [[ "$output" == *"on \`master\`"* ]]
    [[ "$output" == *"3 merge(s)"* ]]
}

@test "an origin/HEAD naming an option-like branch cannot make git write a file" {
    victim="$BATS_TEST_TMPDIR/victim.txt"
    echo keep > "$victim"
    git update-ref "refs/heads/--output=$victim" HEAD
    git update-ref refs/remotes/origin/main HEAD
    git symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/--output=$victim" 2>/dev/null \
        || git symbolic-ref refs/remotes/origin/HEAD "refs/heads/--output=$victim"
    run --separate-stderr bash "$DC"
    [ "$(cat "$victim")" = "keep" ] || { echo "victim file was modified"; return 1; }
    [ "$status" -eq 0 ]
}

@test "rejects a malformed --since and an unknown option" {
    run --separate-stderr bash "$DC" --since 2026/01/01
    [ "$status" -eq 1 ]
    run --separate-stderr bash "$DC" --since=2026-13-45
    [ "$status" -eq 1 ]
    run --separate-stderr bash "$DC" --bogus
    [ "$status" -eq 1 ]
}
