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

@test "prints all seven sections in a repo with no docs" {
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    for h in "## 1. Activity" "## 2. Revisit triggers" "## 3. Watched questions" \
             "## 4. Spot-check sample" "## 5. Roadmap" "## 6. Merges with code but no docs" \
             "## 7. Inputs for steps 4b and 5"; do
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

@test "after a cycle record, every trigger still prints in full and nothing is carried" {
    mkdir -p docs/decisions docs/working/cycles
    printf '# 001\n\n## Revisit triggers\nif old thing.\n' > docs/decisions/001-old.md
    printf '| 8 | 2020-01-01 | **x** | Revisit if ancient. | r |\n| 9 | 2099-01-01 | **y** | Revisit if future. | r |\n' > docs/decisions/log.md
    git add -A && GIT_COMMITTER_DATE="2020-01-02T12:00:00" git commit -q --date="2020-01-02T12:00:00" -m "old record"
    printf '# 002\n\n## Revisit triggers\nif uncommitted thing.\n' > docs/decisions/002-wip.md
    echo "Main at: $(git rev-parse HEAD)" > "docs/working/cycles/cycle-$(date -d yesterday +%F).md"
    run --separate-stderr bash "$DC"
    for t in "if old thing." "if uncommitted thing." "log row 8 (2020-01-01): > Revisit if ancient." \
             "log row 9 (2099-01-01): > Revisit if future."; do
        [[ "$output" == *"$t"* ]] || { echo "not printed in full: $t"; echo "$output" | sed -n '/## 2/,/## 3/p'; return 1; }
    done
    [[ "$output" != *"Carried forward"* && "$output" != *"Main at:"* ]]
}

@test "an old-dated commit on main does not hide the merges behind it" {
    # Fast-forward a 2020-dated commit onto main, then merge today: --since used
    # to stop its walk at the old commit, so it counted only the newest merge and
    # hid the three older ones behind the old commit.
    git checkout -q -b old && GIT_COMMITTER_DATE="2020-01-02T12:00:00" git commit -q --allow-empty --date="2020-01-02T12:00:00" -m old
    git checkout -q main && git merge -q --ff-only old
    git checkout -q -b f4 && git commit -q --allow-empty -m "feature 4" && git checkout -q main
    git merge -q --no-ff f4 -m "merge: feature 4"
    run --separate-stderr bash "$DC" --since="$(date +%F)"
    [[ "$output" == *"4 merge(s)"* ]] || { echo "$output" | sed -n '/## 1/,/## 2/p'; return 1; }
    [[ "$output" == *"merge: feature 4"* ]]
    [[ "$output" != *"No merges in the window"* ]]
}

@test "the scrub strips C0, C1, bidi and tag characters from stdout and stderr" {
    mkdir -p docs/decisions
    # C1 CSI (U+009B), RLO (U+202E), a tag character (U+E0041), ESC, CR.
    printf '# 001\n\n## Revisit triggers\nif a\xc2\x9bb\xe2\x80\xaec\xf3\xa0\x81\x81d\033e\rf.\n' > docs/decisions/001-x.md
    # Split by a C0 byte, and nested: neither may reassemble a sequence.
    printf '# 002\n\n## Revisit triggers\nif g\xc2\x01\x9bh\xe2\x80\x01\xaei\xc2\xc2\x9b\x9bj\xe2\x80\xe2\x80\xae\xaek\xf3\xa0\xf3\xa0\x81\x81\x81\x81l.\n' > docs/decisions/002-y.md
    for env in "" PERL_UNICODE=SDA PERL5OPT=-CSD; do
        run --separate-stderr env $env bash "$DC"
        [[ "$output" == *"if abcdef."* && "$output" == *"if ghijkl."* ]] || { echo "env: $env"; echo "$output" | sed -n '/## 2/,/## 3/p' | od -c | head -20; return 1; }
    done
    # An unknown-option error carrying an ESC reaches stderr scrubbed.
    run --separate-stderr bash "$DC" $'--bo\033gus'
    [ "$status" -eq 1 ]
    # shellcheck disable=SC2154  # bats sets $stderr under --separate-stderr
    [[ "$stderr" == *"Unknown option: --bogus"* ]] || { printf '%s' "$stderr" | od -c | head; return 1; }
}

@test "a symlink out of the repo is not followed" {
    mkdir -p docs/decisions "$BATS_TEST_TMPDIR/outside"
    printf '# 9\n\n## Revisit triggers\nSECRET line.\n' > "$BATS_TEST_TMPDIR/outside/x.md"
    printf '## Next\n- SECRET next\n' > "$BATS_TEST_TMPDIR/outside/roadmap.md"
    ln -s "$BATS_TEST_TMPDIR/outside/x.md" docs/decisions/002-link.md
    ln -s "$BATS_TEST_TMPDIR/outside/roadmap.md" docs/roadmap.md
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    [[ "$output" != *SECRET* ]] || { echo "$output"; return 1; }
}

@test "the exit status and the whole digest survive a redirect to a file" {
    bash "$DC" > "$BATS_TEST_TMPDIR/out.md" 2> "$BATS_TEST_TMPDIR/err.txt"
    grep -q '^## 7. Inputs for steps 4b and 5' "$BATS_TEST_TMPDIR/out.md"
    tail -1 "$BATS_TEST_TMPDIR/out.md" | grep -q 'idea-log'
    run bash "$DC" --since=nope
    [ "$status" -eq 1 ]
}

@test "a newline in a decision record's name cannot print a line of its own" {
    mkdir -p docs/decisions
    printf '# 002\n\n## Revisit triggers\nif x.\n' > "docs/decisions/002-a"$'\n'"## 3. Fake.md"
    run --separate-stderr bash "$DC"
    [[ "$output" != *$'\n'"## 3. Fake"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"### docs/decisions/002-a ## 3. Fake.md"* ]]
}

@test "the window defaults to the newest cycle record's date and says so" {
    mkdir -p docs/working/cycles
    touch docs/working/cycles/cycle-2026-01-05.md docs/working/cycles/cycle-2026-02-10.md docs/working/cycles/cycle-9999-12-31.md
    run --separate-stderr bash "$DC"
    [[ "$output" == *"Window: since 2026-02-10 (from the last cycle record"* ]]
    run --separate-stderr bash "$DC" --since=2026-03-01
    [[ "$output" == *"Window: since 2026-03-01 (from --since)"* ]]
}

@test "--since includes commits from the start date itself" {
    GIT_COMMITTER_DATE="$(date +%F)T00:00:30" git commit -q --allow-empty --date="$(date +%F)T00:00:30" -m "just after midnight"
    # All commits here are from today: a window starting today counts all of them.
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

@test "flags a merge that changed code with no doc change, not one that did both" {
    git checkout -q -b code && echo x > tool.sh && git add tool.sh && git commit -q -m code
    git checkout -q main && git merge -q --no-ff code -m "merge: code only"
    git checkout -q -b both && echo y >> tool.sh && mkdir -p docs && echo d > docs/tool.md
    git add -A && git commit -q -m both && git checkout -q main && git merge -q --no-ff both -m "merge: code and docs"
    run --separate-stderr bash "$DC"
    section=$(echo "$output" | sed -n '/## 6/,/## 7/p')
    [[ "$section" == *"merge: code only (1 file(s), no doc change)"* ]] || { echo "$section"; return 1; }
    [[ "$section" != *"code and docs"* && "$section" != *"feature 1"* ]] || { echo "$section"; return 1; }
    # README_gen.sh is code; a README.txt or docs/ alone is a doc.
    for spec in "readme-like:src/README_gen.sh:flag" "readme-txt:x.sh lib/README.txt:ok" "docs-only:docs/a.txt y.sh:ok" "md-only:notes.md z.sh:ok"; do
        IFS=: read -r br files want <<< "$spec"
        git checkout -q -b "$br"
        for f in $files; do mkdir -p "$(dirname "$f")"; echo "$br" >> "$f"; done
        git add -A && git commit -q -m "$br" && git checkout -q main && git merge -q --no-ff "$br" -m "merge: $br"
    done
    run --separate-stderr bash "$DC"
    section=$(echo "$output" | sed -n '/## 6/,/## 7/p')
    [[ "$section" == *"merge: readme-like"* ]] || { echo "$section"; return 1; }
    for br in readme-txt docs-only md-only; do
        [[ "$section" != *"merge: $br"* ]] || { echo "$br flagged"; echo "$section"; return 1; }
    done
}

@test "prints the step 4b and step 5 inputs" {
    mkdir -p skills/demo docs/decisions docs/working
    echo s > skills/demo/SKILL.md && echo r > docs/decisions/001-big.md
    git add -A && git commit -q -m "skill and record"
    # Changed and reverted inside the window: still a change.
    echo t > skills/demo/tmp.md && git add -A && git commit -q -m tmp && git rm -q skills/demo/tmp.md && git commit -q -m untmp
    git checkout -q -b wf && mkdir -p workflows && echo w > workflows/flow.md && git add -A && git commit -q -m wf
    git checkout -q main && git merge -q --no-ff wf -m "merge: wf" && git rm -q workflows/flow.md && git commit -q -m "drop wf"
    printf '# Roadmap\n\n## Now\n- a\n\n## In flight\n- b\n- c\n\n## Next\n1. d\n' > docs/roadmap.md
    printf '# Ideas\n- old\n\n## Brainstorm 2026-01-01\n- one\n- two\n' > docs/working/idea-log.md
    DEV_CYCLE_TODAY=2026-01-08 run --separate-stderr bash "$DC" --since=2000-01-01
    section=$(echo "$output" | sed -n '/## 7/,$p')
    for t in "in the window: 2" "    - skills/demo/SKILL.md" "    - workflows/flow.md" "    - docs/decisions/001-big.md" \
             "Roadmap Now: 1 item(s)" "Roadmap In flight: 2 item(s)" "Roadmap Next: 1 item(s)" \
             "Last brainstorm: 2026-01-01 (7 day(s) ago)" "Ideas seeded since: 2"; do
        [[ "$section" == *"$t"* ]] || { echo "missing: $t"; echo "$section"; return 1; }
    done
}
