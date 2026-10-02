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

@test "prints all eight sections in a repo with no docs" {
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    for h in "## 1. Activity" "## 2. Revisit triggers" "## 3. Watched questions" \
             "## 4. Spot-check sample" "## 5. Roadmap" "## 6. Merges with code but no docs" \
             "## 7. Inputs for steps 4b and 5" "## 8. Skipped inputs"; do
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
    for env in "" PERL_UNICODE=SDA PERL5OPT=-CSD PERLIO=:utf8 PERLIO=:raw:utf8; do
        run --separate-stderr env $env bash "$DC"
        [[ "$output" == *"if abcdef."* && "$output" == *"if ghijkl."* ]] || { echo "env: $env"; echo "$output" | sed -n '/## 2/,/## 3/p' | od -c | head -20; return 1; }
    done
    # 1000 nested layers inside the cut are removed entirely; a 80 KB line is cut
    # (which is what bounds the scrub's work) and the run stays fast.
    perl -e 'print "# 003\n\n## Revisit triggers\nif m", "\xC2" x 1000, "\x9B" x 1000, "n.\n- ", "x" x 80000, "\n"' > docs/decisions/003-z.md
    run --separate-stderr timeout 20 bash "$DC"
    [ "$status" -eq 0 ] || { echo "status $status (124 = timed out)"; return 1; }
    [[ "$output" == *"if mn."* && "$output" == *"[line cut at 4096 bytes]"* ]] || { echo "$output" | sed -n '/## 2/,/## 3/p' | cut -c1-120; return 1; }
    # Many nested lines stay fast: restarting each line per layer took ~35 s on
    # the authoring host for these 1200 lines, against about 1 s with the resume.
    perl -e 'print "# 004\n\n## Revisit triggers\n"; print "if ", "\xC2" x 1300, "\x9B" x 1300, ".\n" for 1 .. 1200' > docs/decisions/004-many.md
    run --separate-stderr timeout 10 bash "$DC"
    [ "$status" -eq 0 ] || { echo "status $status (124 = timed out)"; return 1; }
    # U+2028 / U+2029 are removed too.
    printf '# 005\n\n## Revisit triggers\nif p\xe2\x80\xa8q\xe2\x80\xa9r.\n' > docs/decisions/005-sep.md
    run --separate-stderr bash "$DC"
    [[ "$output" == *"if pqr."* ]]
    # An unknown-option error carrying an ESC reaches stderr scrubbed.
    run --separate-stderr bash "$DC" $'--bo\033gus'
    [ "$status" -eq 1 ]
    # shellcheck disable=SC2154  # bats sets $stderr under --separate-stderr
    [[ "$stderr" == *"Unknown option: --bogus"* ]] || { printf '%s' "$stderr" | od -c | head; return 1; }
}

@test "no input is read through a symlink, inside or outside the repo" {
    mkdir -p docs/decisions "$BATS_TEST_TMPDIR/outside"
    printf '# 9\n\n## Revisit triggers\nSECRET line.\n' > "$BATS_TEST_TMPDIR/outside/x.md"
    printf '## Next\n- SECRET next\n' > "$BATS_TEST_TMPDIR/outside/roadmap.md"
    ln -s "$BATS_TEST_TMPDIR/outside/x.md" docs/decisions/002-link.md
    ln -s "$BATS_TEST_TMPDIR/outside/roadmap.md" docs/roadmap.md
    # An in-repo symlink (here into .git) is skipped too.
    printf '# 8\n\n## Revisit triggers\nSECRET in git.\n' > .git/x.md
    ln -s ../../.git/x.md docs/decisions/003-git.md
    # The log, questions, idea log and a cycle record through symlinks, too.
    mkdir -p docs/working/cycles
    printf '| 1 | 2026-01-01 | x | SECRET Revisit if y. | r |\n' > "$BATS_TEST_TMPDIR/outside/log.md"
    ln -s "$BATS_TEST_TMPDIR/outside/log.md" docs/decisions/log.md
    ln -s "$BATS_TEST_TMPDIR/outside/x.md" docs/working/questions.md
    ln -s "$BATS_TEST_TMPDIR/outside/x.md" docs/working/idea-log.md
    ln -s "$BATS_TEST_TMPDIR/outside/x.md" docs/working/cycles/cycle-2026-02-01.md
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    [[ "$output" != *SECRET* ]] || { echo "$output"; return 1; }
    # Each is reported as skipped, not as absent.
    [[ "$output" == *"docs/roadmap.md is not read: docs/roadmap.md is not a plain file or directory"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"docs/working/questions.md is not read: docs/working/questions.md is not"* ]]
    [[ "$output" == *"no readable cycle record (records, or a directory above them, were skipped"* ]]
    [[ "$output" == *"No revisit triggers in the decision inputs that were read"* ]]
    skipped=$(echo "$output" | sed -n '/## 8/,$p')
    for f in docs/decisions/002-link.md docs/decisions/003-git.md docs/decisions/log.md docs/roadmap.md \
             docs/working/questions.md docs/working/idea-log.md docs/working/cycles/cycle-2026-02-01.md; do
        [[ "$skipped" == *"- $f"* ]] || { echo "not listed: $f"; echo "$skipped"; return 1; }
    done
}

@test "a symlinked directory is listed and nothing below it is read or probed; a newline in a skipped name stays on one line" {
    mkdir -p "$BATS_TEST_TMPDIR/outside/dec" "$BATS_TEST_TMPDIR/outside/cyc" docs/working
    printf '# 1\n\n## Revisit triggers\nSECRET.\n' > "$BATS_TEST_TMPDIR/outside/dec/001-private-plan.md"
    touch "$BATS_TEST_TMPDIR/outside/cyc/cycle-2026-02-01.md"
    ln -s "$BATS_TEST_TMPDIR/outside/dec" docs/decisions
    ln -s "$BATS_TEST_TMPDIR/outside/cyc" docs/working/cycles
    run --separate-stderr bash "$DC"
    [ "$status" -eq 0 ]
    [[ "$output" != *private-plan* && "$output" != *SECRET* && "$output" != *cycle-2026-02-01* ]] || { echo "$output"; return 1; }
    # A fixed name below a skipped directory is not probed: whether log.md
    # exists out there must not show.
    touch "$BATS_TEST_TMPDIR/outside/dec/log.md"
    run --separate-stderr bash "$DC"
    [[ "$output" != *"docs/decisions/log.md"* ]] || { echo "$output" | sed -n '/## 8/,$p'; return 1; }
    skipped=$(echo "$output" | sed -n '/## 8/,$p')
    [[ "$skipped" == *"- docs/decisions/"* && "$skipped" == *"- docs/working/cycles/"* ]] || { echo "$skipped"; return 1; }
    [[ "$output" == *"No revisit triggers in the decision inputs that were read"* ]] || { echo "$output" | sed -n '/## 2/,/## 3/p'; return 1; }
    rm docs/decisions && mkdir -p docs/decisions
    ln -s "$BATS_TEST_TMPDIR/outside/dec/001-private-plan.md" "docs/decisions/002-a"$'\n'"- FORGED.md"
    run --separate-stderr bash "$DC"
    skipped=$(echo "$output" | sed -n '/## 8/,$p')
    [[ "$skipped" == *"- docs/decisions/002-a - FORGED.md"* ]] || { echo "$skipped"; return 1; }
    [[ "$skipped" != *$'\n'"- - FORGED"* ]]
    # docs/working itself a symlink: only it is listed (nothing below it is
    # probed), the window says records were skipped, and notes name it.
    mkdir -p "$BATS_TEST_TMPDIR/outside/work/cycles"
    rm -rf docs/working && ln -s "$BATS_TEST_TMPDIR/outside/work" docs/working
    run --separate-stderr bash "$DC"
    skipped=$(echo "$output" | sed -n '/## 8/,$p')
    [[ "$skipped" == *"- docs/working/"* && "$skipped" != *"docs/working/cycles"* && "$skipped" != *"questions.md"* ]] || { echo "$skipped"; return 1; }
    [[ "$output" == *"no readable cycle record (records, or a directory above them, were skipped"* ]] || { echo "$output" | sed -n 3p; return 1; }
    [[ "$output" == *"docs/working/questions.md is not read: docs/working/ is not a plain file or directory"* ]] || { echo "$output"; return 1; }
}

@test "the exit status and the whole digest survive a redirect to a file" {
    bash "$DC" > "$BATS_TEST_TMPDIR/out.md" 2> "$BATS_TEST_TMPDIR/err.txt"
    grep -q '^## 7. Inputs for steps 4b and 5' "$BATS_TEST_TMPDIR/out.md"
    tail -1 "$BATS_TEST_TMPDIR/out.md" | grep -q 'None: no input was skipped'
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

@test "section 2 names a skipped log even when other triggers print; a symlinked archive stops section 3" {
    mkdir -p docs/decisions docs/working "$BATS_TEST_TMPDIR/outside"
    printf '# 001\n\n## Revisit triggers\nif plain.\n' > docs/decisions/001-plain.md
    printf '| 1 | 2026-01-01 | x | Revisit if y. | r |\n' > "$BATS_TEST_TMPDIR/outside/log.md"
    ln -s "$BATS_TEST_TMPDIR/outside/log.md" docs/decisions/log.md
    printf '# Running questions\n\n## Open\n' > docs/working/questions.md
    ln -s "$BATS_TEST_TMPDIR/outside/no-such-file" docs/working/questions-archive.md
    run --separate-stderr bash "$DC"
    section2=$(echo "$output" | sed -n '/## 2/,/## 3/p')
    [[ "$section2" == *"if plain."* && "$section2" == *"Not read: docs/decisions/log.md is not a plain file or directory"* ]] || { echo "$section2"; return 1; }
    section3=$(echo "$output" | sed -n '/## 3/,/## 4/p')
    [[ "$section3" == *"**Watched questions were NOT checked** — docs/working/questions-archive.md is not read"* ]] || { echo "$section3"; return 1; }
    [[ "$section3" != *"questions.sh open failed"* && "$section3" != *"no-such-file"* ]] || { echo "$section3"; return 1; }
    # The settings file and the briefs directory are checked like any input.
    ln -s "$BATS_TEST_TMPDIR/outside/log.md" docs/dev-cycle.md
    mkdir -p docs/working && ln -s "$BATS_TEST_TMPDIR/outside" docs/working/briefs
    run --separate-stderr bash "$DC"
    sec8=$(echo "$output" | sed -n '/## 8/,$p')
    [[ "$sec8" == *"- docs/dev-cycle.md"* && "$sec8" == *"- docs/working/briefs/"* ]] || { echo "$sec8"; return 1; }
    rm docs/dev-cycle.md docs/working/briefs
    # No questions.md: reported as absent, and the symlinked archive is still
    # listed in section 8.
    rm docs/working/questions.md
    run --separate-stderr bash "$DC"
    [[ "$output" == *"No docs/working/questions.md in this repo."* ]] || { echo "$output" | sed -n '/## 3/,/## 4/p'; return 1; }
    [[ "$(echo "$output" | sed -n '/## 8/,$p')" == *"- docs/working/questions-archive.md"* ]] || { echo "$output" | sed -n '/## 8/,$p'; return 1; }
    printf '# Running questions\n\n## Open\n' > docs/working/questions.md
    # A plain record with no triggers beside a skipped log: the summary must
    # not claim every input was skipped.
    printf '# 002\n\nno triggers here\n' > docs/decisions/002-none.md
    rm docs/decisions/001-plain.md
    run --separate-stderr bash "$DC"
    section2=$(echo "$output" | sed -n '/## 2/,/## 3/p')
    [[ "$section2" == *"No revisit triggers in the decision inputs that were read; the skipped ones above were not read."* ]] || { echo "$section2"; return 1; }
}

@test "record dates match per-file git log for quoted names and a merge-resolution change" {
    mkdir -p docs/decisions
    for n in '001-a"b' '002-a\b' 003-plain 004-merge; do
        printf '# x\n\n## Revisit triggers\nif y.\n' > "docs/decisions/$n.md"
    done
    git add -A && GIT_COMMITTER_DATE=2026-01-01T12:00 git commit -q --date=2026-01-01T12:00 -m records
    git checkout -q -b side && echo s >> docs/decisions/004-merge.md
    GIT_COMMITTER_DATE=2026-02-01T12:00 git commit -qam s --date=2026-02-01T12:00
    git checkout -q main && echo m >> docs/decisions/004-merge.md
    GIT_COMMITTER_DATE=2026-02-02T12:00 git commit -qam m --date=2026-02-02T12:00
    git merge -q side -m mg 2>/dev/null || true
    printf '# x\n\n## Revisit triggers\nif y.\nresolved\n' > docs/decisions/004-merge.md
    git add -A && GIT_COMMITTER_DATE=2026-03-01T12:00 GIT_AUTHOR_DATE=2026-03-01T12:00 git commit -qm mg
    printf '# x\n\n## Revisit triggers\nif y.\n' > docs/decisions/005-uncommitted.md
    run --separate-stderr bash "$DC" --since=2000-01-01
    [[ "$output" == *"005-uncommitted.md (last committed on this branch: never, uncommitted)"* ]] || { echo "$output" | grep '^###'; return 1; }
    for f in docs/decisions/00[1-4]*.md; do
        want="$(git log -1 --format=%ad --date=short -- "$f")"
        [[ "$output" == *"### $f (last committed on this branch: $want)"* ]] || { echo "$f: want $want"; echo "$output" | grep '^###'; return 1; }
    done
    [[ "$output" == *"004-merge.md (last committed on this branch: 2026-03-01)"* ]]
    # A staged, never-committed record with a quoted name: no date, no walk.
    printf '# x\n\n## Revisit triggers\nif y.\n' > 'docs/decisions/006-s"t.md'
    git add 'docs/decisions/006-s"t.md'
    run --separate-stderr bash "$DC" --since=2000-01-01
    [[ "$output" == *'006-s"t.md (last committed on this branch: never, uncommitted)'* ]] || { echo "$output" | grep '^###'; return 1; }
}

@test "a skipped newer cycle record is named in the window line" {
    mkdir -p docs/working/cycles
    touch docs/working/cycles/cycle-2026-01-01.md "$BATS_TEST_TMPDIR/c.md"
    ln -s "$BATS_TEST_TMPDIR/c.md" docs/working/cycles/cycle-2026-02-20.md
    DEV_CYCLE_TODAY=2026-03-01 run --separate-stderr bash "$DC"
    [[ "$output" == *"Window: since 2026-01-01 (from the last cycle record"*"a newer record, docs/working/cycles/cycle-2026-02-20.md, was skipped"* ]] || { echo "$output" | sed -n 3p; return 1; }
}

@test "the window defaults to the newest cycle record's date and says so" {
    mkdir -p docs/working/cycles
    touch docs/working/cycles/cycle-2026-01-05.md docs/working/cycles/cycle-2026-02-10.md docs/working/cycles/cycle-9999-12-31.md \
          docs/working/cycles/cycle-2026-02-30.md
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
    # No open entries: the route line says none.
    printf '# Running questions\n\n## Index\n\n<!-- index:start -->\n<!-- index:end -->\n\n## Open\n' > docs/working/questions.md
    run --separate-stderr bash "$DC"
    [[ "$output" == *"Open by route: none"* ]] || { echo "$output" | sed -n '/## 3/,/## 4/p'; return 1; }
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
    # An empty value is an error, not "no flag", and the message is plain.
    run --separate-stderr bash "$DC" --since=
    [ "$status" -eq 1 ]
    # shellcheck disable=SC2154  # bats sets $stderr under --separate-stderr
    [[ "$stderr" == *"--since needs a value"* && "$stderr" != *"line "* ]] || { echo "$stderr"; return 1; }
    run --separate-stderr bash "$DC" --sample
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
    for spec in "readme-like:src/README_gen.sh:flag" "readme-txt:x.sh lib/README.txt:ok" "docs-only:docs/a.txt y.sh:ok" "md-only:notes.md z.sh:ok" "md-upper:NOTES.MD w.sh:ok"; do
        IFS=: read -r br files _ <<< "$spec"
        git checkout -q -b "$br"
        for f in $files; do mkdir -p "$(dirname "$f")"; echo "$br" >> "$f"; done
        git add -A && git commit -q -m "$br" && git checkout -q main && git merge -q --no-ff "$br" -m "merge: $br"
    done
    run --separate-stderr bash "$DC"
    section=$(echo "$output" | sed -n '/## 6/,/## 7/p')
    for spec in readme-like:flag readme-txt:ok docs-only:ok md-only:ok md-upper:ok; do
        IFS=: read -r br want <<< "$spec"
        if [[ "$want" == flag ]]; then [[ "$section" == *"merge: $br "* ]]; else [[ "$section" != *"merge: $br "* ]]; fi \
            || { echo "$br: expected $want"; echo "$section"; return 1; }
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
    # A non-ASCII skill name still counts.
    mkdir -p "skills/café" && echo c > "skills/café/SKILL.md" && git add -A && git commit -q -m cafe
    # Heading case and suffixes do not hide items.
    printf '# Roadmap\r\n\r\n## Now (current)\r\n- a\r\n\r\n## In Flight\r\n- b\r\n- c\r\n\r\n## Next\r\n1. d\r\n\r\n## Nextgen ideas\r\n- not next\r\n' > docs/roadmap.md
    printf '# Ideas\n- old (signal: x)\n\n## Brainstorm 2026-01-01\n- one (signal: a)\n- a format example, not a seed\n- (signal: unclosed\n- two (signal: b)\n' > docs/working/idea-log.md
    DEV_CYCLE_TODAY=2026-01-08 run --separate-stderr bash "$DC" --since=2000-01-01
    # Section 5 uses the same heading rule: CRLF on a bare heading here, then a
    # suffix below; "## Nextgen" is not Next.
    first="$output"
    roadmap=$(echo "$first" | sed -n '/## 5/,/## 6/p')
    [[ "$roadmap" == *"> 1. d"* && "$roadmap" != *"not next"* ]] || { echo "$roadmap"; return 1; }
    printf '## NEXT (ranked)\n1. e\n## Nextgen\n- not next\n' > "$BATS_TEST_TMPDIR/r2.md"
    cp "$BATS_TEST_TMPDIR/r2.md" docs/roadmap.md
    run --separate-stderr bash "$DC" --since=2000-01-01
    roadmap2=$(echo "$output" | sed -n '/## 5/,/## 6/p')
    [[ "$roadmap2" == *"> 1. e"* && "$roadmap2" != *"not next"* ]] || { echo "$roadmap2"; return 1; }
    section=$(echo "$first" | sed -n '/## 7/,/## 8/p')
    for t in "in the window: 4" "    - skills/café/SKILL.md" "    - skills/demo/SKILL.md" "    - skills/demo/tmp.md" "    - workflows/flow.md" "    - docs/decisions/001-big.md" \
             "Roadmap Now: 1 item(s)" "Roadmap In flight: 2 item(s)" "Roadmap Next: 1 item(s)" \
             "Last brainstorm: 2026-01-01 (7 day(s) ago)" "Ideas seeded since: 2"; do
        [[ "$section" == *"$t"* ]] || { echo "missing: $t"; echo "$section"; return 1; }
    done
}

@test "--check-path allows tracked files and ignored docs/working files, and nothing else" {
    mkdir -p docs/working docs/decisions "$BATS_TEST_TMPDIR/outside"
    printf 'docs/working/round-*.md\n.env\n' > .gitignore
    echo i > docs/working/ideas.md && echo d > docs/decisions/001-x.md && echo g > .gitignore-like.md
    git add -A && git commit -qm files
    echo r > docs/working/round-1.md      # ignored, under docs/working: allowed
    echo s > .env                          # ignored elsewhere: never
    echo u > docs/untracked.md             # untracked: never
    echo o > "$BATS_TEST_TMPDIR/outside/x.md"
    ln -s "$BATS_TEST_TMPDIR/outside/x.md" docs/working/round-2.md
    run --separate-stderr bash "$DC" --check-path 'docs/working/*.md' docs/decisions/001-x.md docs .env \
        docs/untracked.md .git/config .GIT/config '../x' /etc/passwd -x "a'b" '.g*' docs/working/round-2.md
    [ "$status" -eq 0 ]
    for want in "ok docs/working/ideas.md" "ok docs/working/round-1.md" "ok docs/decisions/001-x.md" \
                "skip docs: a directory, not a file" "skip .env: no tracked file" "skip docs/untracked.md: no tracked file" \
                "skip .git/config: not an allowed path form" "skip .GIT/config: not an allowed path form" \
                "skip ../x: not an allowed path form" "skip /etc/passwd: not an allowed path form" \
                "skip -x: not an allowed path form" "skip a'b: not an allowed path form" \
                "skip .gitignore: not an allowed path form" \
                "skip docs/working/round-2.md: reached through a symlink"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
    [[ "$output" != *"ok docs/working/round-2.md"* && "$output" != *"ok .env"* ]]
    run --separate-stderr bash "$DC" --check-path
    [ "$status" -eq 1 ]
    # A symlinked parent directory (git tracks the link itself and lists nothing
    # through it), ** across directories, a case variant, a glob over too many files.
    mkdir -p "$BATS_TEST_TMPDIR/outside/d" && echo x > "$BATS_TEST_TMPDIR/outside/d/f.md"
    ln -s "$BATS_TEST_TMPDIR/outside/d" docs/working/linkdir
    for i in $(seq 1 55); do echo "$i" > "docs/decisions/m$i.md"; done
    git add -A && git commit -qm many
    run --separate-stderr bash "$DC" --check-path 'docs/working/linkdir/f.md' 'docs/**' '.Git/x' 'docs/decisions/*.md'
    [[ "$output" == *"skip docs/working/linkdir/f.md: no tracked file"* || "$output" == *"skip docs/working/linkdir/f.md: reached through a symlink"* ]] || { echo "$output"; return 1; }
    [[ "$output" != *"ok docs/working/linkdir"* ]]
    [[ "$output" == *"ok docs/decisions/001-x.md"* && "$output" == *"skip docs/**: matches more than 50"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"skip .Git/x: not an allowed path form"* ]]
    [[ "$output" == *"skip docs/decisions/*.md: matches more than 50 files"* ]] || { echo "$output" | tail -3; return 1; }
}

@test "--check-write allows a new file under plain directories and refuses symlinks" {
    mkdir -p docs/working "$BATS_TEST_TMPDIR/outside"
    ln -s "$BATS_TEST_TMPDIR/outside" docs/working/briefs
    ln -s "$BATS_TEST_TMPDIR/outside/r.md" docs/roadmap.md
    run --separate-stderr bash "$DC" --check-write docs/working/cycles/cycle-2026-01-01.md \
        docs/working/briefs/2026-01-01-x.md docs/roadmap.md ../out AGENTS.md scripts/x.sh .env \
        docs/working/idea-log.md docs/working/briefs/x.md
    [ "$status" -eq 0 ]
    for want in "ok docs/working/cycles/cycle-2026-01-01.md" "skip docs/working/briefs/2026-01-01-x.md: reached through a symlink" \
                "skip docs/roadmap.md: reached through a symlink" "skip ../out: not an allowed path form" \
                "skip AGENTS.md: not one of the dev cycle's own files" "skip scripts/x.sh: not one of" \
                "skip .env: not one of" "ok docs/working/idea-log.md" "skip docs/working/briefs/x.md: not one of"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
}

@test "--check-brief allows only a dated build brief" {
    mkdir -p docs/working
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/2026-01-01-x-2.md docs/roadmap.md \
        docs/working/idea-log.md docs/working/cycles/cycle-2026-01-01.md docs/working/briefs/2026-1-01-x.md \
        docs/working/briefs/2026-01-01-X.md AGENTS.md
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok docs/working/briefs/2026-01-01-x-2.md"* ]] || { echo "$output"; return 1; }
    [ "$(grep -c '^skip .*: not a build brief' <<<"$output")" -eq 6 ] || { echo "$output"; return 1; }
}

@test "--check-branch allows only a plain, valid branch name" {
    run --separate-stderr bash "$DC" --check-branch feat/x-1 chore/dev-cycle-2026-01-01 '--output=x' -x \
        'a..b' x.lock 'a b' 'a/' 'a;b' 'HEAD@{1}' HEAD refs/heads/x
    [ "$status" -eq 0 ]
    for want in "ok feat/x-1" "ok chore/dev-cycle-2026-01-01" "skip --output=x: not an allowed branch name" \
                "skip -x: not an allowed" "skip a..b: not a valid branch name" "skip x.lock: not a valid" \
                "skip a b: not an allowed" "skip a/: not a valid" "skip a;b: not an allowed" "skip HEAD@{1}: not an allowed" \
                "skip HEAD: not a valid" "skip refs/heads/x: not a valid"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
    [ "$(grep -c '^ok ' <<<"$output")" -eq 2 ]
}

@test "--check-path does not warn per match under an uninstalled locale" {
    mkdir -p docs/decisions
    for i in 1 2 3 4 5 6; do echo "$i" > "docs/decisions/m$i.md"; done
    git add -A && git commit -qm files
    run --separate-stderr env LC_ALL=xx_XX.UTF-8 bash "$DC" --check-path 'docs/decisions/*.md' docs/decisions/m1.md
    [ "$status" -eq 0 ]
    [ "$(grep -c '^ok ' <<<"$output")" -eq 7 ]
    # At most bash's own start-up warnings (one per bash process), none per match.
    # shellcheck disable=SC2154  # bats sets $stderr under --separate-stderr
    [ "$(grep -c . <<<"$stderr")" -le 2 ] || { echo "$stderr"; return 1; }
}

@test "--check-path reports an ignored docs/working name that is not UTF-8" {
    mkdir -p docs/working && echo 'docs/working/r*' > .gitignore
    git add -A && git commit -qm ignore
    echo x > "docs/working/r$(printf '\xff').md"
    run --separate-stderr env LC_ALL=C.UTF-8 bash "$DC" --check-path 'docs/working/*'
    [ "$status" -eq 0 ]
    [[ "$output" == "skip docs/working/r"*".md: not an allowed path form" ]] || { echo "$output"; return 1; }
}

@test "--check-branch gives the branch's own hash, never a tag's" {
    git branch feat/real
    git tag refs/heads/feat/ghost 2>/dev/null || git tag "refs/heads/feat/ghost"
    run --separate-stderr bash "$DC" --check-branch feat/real feat/ghost
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok feat/real $(git rev-parse feat/real)"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"ok feat/ghost absent"* ]] || { echo "$output"; return 1; }
    run --separate-stderr bash "$DC" --check-branch
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"needs at least one argument"* ]]
}

@test "--check-fix allows only existing docs/ and README.md files" {
    mkdir -p docs/decisions hooks egress
    echo d > docs/decisions/log.md && echo r > README.md && echo h > hooks/x.sh && echo e > egress/x.txt && echo a > AGENTS.md
    git add -A && git commit -qm files
    run --separate-stderr bash "$DC" --check-fix docs/decisions/log.md README.md hooks/x.sh egress/x.txt AGENTS.md \
        docs/new.md 'docs/*.md' docs
    [ "$status" -eq 0 ]
    for want in "ok docs/decisions/log.md" "ok README.md" "skip hooks/x.sh: in-cycle fixes edit only" \
                "skip egress/x.txt: in-cycle fixes edit only" "skip AGENTS.md: in-cycle fixes edit only" \
                "skip docs/new.md: no tracked file" "skip docs/*.md: not an allowed path form" "skip docs: in-cycle fixes edit only"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
}

@test "--check-answer reads keep-or-drop answers in the archive's real shapes" {
    mkdir -p docs/working
    q() { printf '### %s · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\nkeep or drop?\n\n%s\n\n' "$1" "$2"; }
    {
        echo '# Questions'; echo; echo '## Open'; echo
        q Q-001 '**Answer (2026-09-28): [1].** The user ran it; reopen with [2] if needed.'
        q Q-002 '- **Answer (2026-10-01, in chat):** [2]. Dropped.'
        q Q-003 '**Answered 2026-09-17: between [1] and [2].**'
        q Q-004 '**Answered 2026-09-17: keep. Still wanted.**'
        q Q-005 '**Answered 2026-09-17: keep both — neither is wrong.**'
        q Q-006 'Q-006: DROP'
        q Q-007 '**Answering this later:** [2]'
        q Q-008 '**ANSWERED 2026-09-20, run 3: [2] drop it.** Notes [1].'
        q Q-009 '- **If the answer differs:** nothing.'
        printf '### Q-010 · keep-or-drop-x-2\n**Needs:** you: judgment · **Status:** OPEN\n\nkeep or drop?\n'
    } > docs/working/questions.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-001 Q-002 Q-003 Q-004 Q-005 Q-006 Q-007 Q-008 Q-009 Q-010 Q-999 'Q-1;x'
    [ "$status" -eq 0 ]
    for want in "keep Q-001" "drop Q-002" "unrecognized Q-003" "keep Q-004" "unrecognized Q-005" "drop Q-006" \
                "unrecognized Q-007" "drop Q-008" "unrecognized Q-009" "open Q-010" "skip Q-999: no such entry" "skip Q-1;x: not a question ID"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
}
