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
    git branch feat/x-1
    run --separate-stderr bash "$DC" --check-branch feat/x-1 chore/dev-cycle-2026-01-01 main '--output=x' -x \
        'a..b' x.lock 'a b' 'a/' 'a;b' 'HEAD@{1}' HEAD refs/heads/x
    [ "$status" -eq 0 ]
    for want in "ok feat/x-1 $(git rev-parse feat/x-1)" "absent chore/dev-cycle-2026-01-01" "skip main: the default branch" \
                "skip --output=x: not an allowed branch name" \
                "skip -x: not an allowed" "skip a..b: not a valid branch name" "skip x.lock: not a valid" \
                "skip a b: not an allowed" "skip a/: not a valid" "skip a;b: not an allowed" "skip HEAD@{1}: not an allowed" \
                "skip HEAD: not a valid" "skip refs/heads/x: not a valid"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
    [ "$(grep -c '^ok ' <<<"$output")" -eq 1 ]
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
    [[ "$output" == *"absent feat/ghost"* ]] || { echo "$output"; return 1; }
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
    for want in "skip docs/decisions/log.md: in-cycle fixes edit only" "ok README.md" "skip hooks/x.sh: in-cycle fixes edit only" \
                "skip egress/x.txt: in-cycle fixes edit only" "skip AGENTS.md: in-cycle fixes edit only" \
                "skip docs/new.md: no tracked file" "skip docs/*.md: --check-fix takes one file" "skip docs: in-cycle fixes edit only"; do
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

@test "--check-answer: notes cannot flip an answer; line-start labels only, fences, duplicates, CR, the archive" {
    mkdir -p docs/working
    q() { printf '### %s · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\nkeep or drop?\n\n%s\n\n' "$1" "$2"; }
    {
        echo '# Questions'; echo
        q Q-1 '- **Answer (2026-10-01, in chat):** drop. Option [1] would cost more.'
        q Q-2 'Q-2: keep, not [2]'
        q Q-3 '**Answer:** drop — [1] was the interim'
        q Q-4 'Keep or drop? **Answered 2026-09-27: [1] supply the backstops.** Notes [2].'
        q Q-5 '**Answered 2026-09-27 10:30: [2].**'
        # shellcheck disable=SC2016  # literal ``` fence, not a command substitution
        printf '### Q-6 · x\n**Status:** OPEN\n\n```\n**Answer:** [2]\n```\n\n'
        q Q-8 "$(printf '**Answer:** [1].\r')"
        q Q-9 '**Answer:** [1].'
        q Q-9 '**Answer:** [2].'
        q Q-10 '**Answer:** [2].'
    } > docs/working/questions.md
    { echo '# Archive'; echo; q Q-100 '**Answer:** [1].'; q Q-10 '**Answer:** [1].'; } > docs/working/questions-archive.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-1 Q-2 Q-3 Q-4 Q-5 Q-6 Q-7 Q-8 Q-9 Q-10 Q-100
    [ "$status" -eq 0 ]
    for want in "drop Q-1" "keep Q-2" "drop Q-3" "unrecognized Q-4" "drop Q-5" "open Q-6" "skip Q-7: no such entry" \
                "keep Q-8" "skip Q-9: more than one entry" "skip Q-10: an entry with this heading in both" "keep Q-100"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
    # A questions.md that is not plain is reported, not passed over to the archive.
    git mv docs/working/questions.md docs/working/q-real.md && ln -s q-real.md docs/working/questions.md
    run --separate-stderr bash "$DC" --check-answer Q-100
    [[ "$output" == "skip Q-100: docs/working/questions.md is not a plain file or directory"* ]] || { echo "$output"; return 1; }
}

@test "--check-fix refuses code, the user's own files and ignored scratch under docs/" {
    mkdir -p docs/reviews/execution-logs docs/human-author docs/working docs/guides
    echo 'docs/working/round-*' > .gitignore
    echo s > docs/reviews/execution-logs/x.sh && echo a > docs/human-author/answers.txt && echo h > docs/human-author/notes.md
    echo g > docs/guides/g.md && echo w > docs/working/plan.md && echo r > docs/roadmap.md
    git add -A && git commit -qm files
    echo i > docs/working/round-3.md
    run --separate-stderr bash "$DC" --check-fix docs/guides/g.md docs/reviews/execution-logs/x.sh docs/human-author/answers.txt \
        docs/human-author/notes.md docs/working/round-3.md docs/working/plan.md docs/roadmap.md
    [ "$status" -eq 0 ]
    [ "$(grep -c '^ok ' <<<"$output")" -eq 1 ] && [[ "$output" == *"ok docs/guides/g.md"* ]] || { echo "$output"; return 1; }
    [ "$(grep -c '^skip .*: in-cycle fixes edit only' <<<"$output")" -eq 5 ] || { echo "$output"; return 1; }
    [[ "$output" == *"skip docs/roadmap.md: one of the cycle's own files"* ]] || { echo "$output"; return 1; }
}

@test "closed briefs move out of the glob, so open ones are listed past 50 briefs" {
    mkdir -p docs/working/briefs/closed
    for i in $(seq 10 64); do echo c > "docs/working/briefs/closed/2026-01-$((i % 28 + 1))-b$i.md"; done
    echo o > docs/working/briefs/2026-03-01-open-a.md && echo o > docs/working/briefs/2026-03-02-open-b.md
    git add -A && git commit -qm briefs
    run --separate-stderr bash "$DC" --check-path 'docs/working/briefs/*.md'
    [ "$(grep -c '^ok ' <<<"$output")" -eq 2 ] || { echo "$output"; return 1; }
    run --separate-stderr bash "$DC" --check-write docs/working/briefs/closed/2026-03-01-open-a.md
    [[ "$output" == "ok docs/working/briefs/closed/2026-03-01-open-a.md" ]] || { echo "$output"; return 1; }
    # A closed/ path is read for its state (not landed there yet: new); it never holds a slot.
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/closed/2026-03-01-open-a.md
    [[ "$output" == "ok docs/working/briefs/closed/2026-03-01-open-a.md new" ]] || { echo "$output"; return 1; }
}

@test "--check-answer reads nothing from an entry not marked ANSWERED, and reads done" {
    mkdir -p docs/working
    o() { printf '### %s · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** OPEN\n\nkeep or drop?\n\n%s\n\n' "$1" "$2"; }
    a() { printf '### %s · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\nkeep or drop?\n\n%s\n\n' "$1" "$2"; }
    {
        echo '# Questions'; echo
        o Q-1 'Last time: **Answered 2026-09-01: [2].** was not read.'
        o Q-2 '> **Answer:** [2]'
        # shellcheck disable=SC2016  # literal backticks in the entry text
        o Q-3 'Reply like `**Answer:** [2]`.'
        o Q-4 '**Answer:** [2]'
        a Q-5 '**Answer:** [3] it shipped in abc123.'
        a Q-6 '**Answer:** done.'
        a Q-7 '**Answer:** not [2]; keep it'
        a Q-8 '**Answer format:** [2] means drop.'
        a Q-9 '| **Answer:** [1] | x |'
        a Q-11 '**Answer:** drop because [1] costs more'
        a Q-12 '    **Answer:** [2]'
    } > docs/working/questions.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-1 Q-2 Q-3 Q-4 Q-5 Q-6 Q-7 Q-8 Q-9 Q-11 Q-12
    [ "$status" -eq 0 ]
    for want in "open Q-1" "open Q-2" "open Q-3" "open Q-4" "done Q-5" "done Q-6" "unrecognized Q-7" \
                "unrecognized Q-8" "unrecognized Q-9" "unrecognized Q-11" "unrecognized Q-12"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
}

@test "--check-brief reads the status line from the default branch only" {
    mkdir -p docs/working/briefs
    printf '# Brief\nStatus: open\n\n- set this brief to Status: done in the merge\n' > docs/working/briefs/2026-01-01-a.md
    printf '# Brief\nStatus: done\n' > docs/working/briefs/2026-01-02-b.md
    printf '# Brief\nStatus: closed\n' > docs/working/briefs/2026-01-03-c.md
    git add -A && git commit -qm briefs
    c=$(git rev-parse HEAD)
    printf '# Brief\nStatus: done\n' > docs/working/briefs/2026-01-01-a.md   # working tree only: not read
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/2026-01-01-a.md docs/working/briefs/2026-01-02-b.md \
        docs/working/briefs/2026-01-03-c.md docs/working/briefs/2026-01-04-new.md docs/roadmap.md
    [ "$status" -eq 0 ]
    for want in "ok docs/working/briefs/2026-01-01-a.md open $c" "ok docs/working/briefs/2026-01-02-b.md done $c" \
                "skip docs/working/briefs/2026-01-03-c.md: its first Status: line is not exactly" "ok docs/working/briefs/2026-01-04-new.md new" \
                "skip docs/roadmap.md: not a build brief"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
}

@test "--check-branch counts the branch's own commits; --check-fix refuses instruction files" {
    git checkout -q -b feat/w && git commit -q --allow-empty -m one && git commit -q --allow-empty -m two
    git checkout -q main && git branch feat/idle
    mkdir -p docs/sub docs/.agents/skills/x docs/guides
    for f in docs/GEMINI.md docs/sub/agents.md docs/sub/AGENTS.override.md docs/sub/gemini.local.md \
             docs/.agents/skills/x/SKILL.md docs/dev-cycle.md docs/guides/g.md; do echo x > "$f"; done
    git add -A && git commit -qm docs
    run --separate-stderr bash "$DC" --check-branch feat/w feat/idle
    [[ "$output" == *"ok feat/w $(git rev-parse feat/w) 2 $(git log -1 --format=%cs feat/w)"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"ok feat/idle $(git rev-parse feat/idle) 0 "* ]] || { echo "$output"; return 1; }
    run --separate-stderr bash "$DC" --check-fix docs/GEMINI.md docs/sub/agents.md docs/sub/AGENTS.override.md \
        docs/sub/gemini.local.md docs/.agents/skills/x/SKILL.md docs/dev-cycle.md docs/guides/g.md
    [ "$(grep -c '^ok ' <<<"$output")" -eq 1 ] && [[ "$output" == *"ok docs/guides/g.md"* ]] || { echo "$output"; return 1; }
}

@test "the ANSWERED gate reads only the header line; a fenced Status line in a brief is not its status" {
    local f=$'\x60\x60\x60'  # a ``` fence line
    mkdir -p docs/working/briefs
    {
        echo '# Questions'; echo
        printf '### Q-1 · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** OPEN\n\n'
        printf '(Q-0 was **Status:** ANSWERED earlier.)\n\n- Q-1: [2]\n\n'
        printf '### Q-2 · keep-or-drop-x-2\n**Needs:** you: judgment · **Status:** ANSWERED\n\n'
        printf '%s\n# a comment, not a heading\n%s\n**Answer:** [2]\n\n' "$f" "$f"
    } > docs/working/questions.md
    printf '# Brief\n\n%s\nStatus: done\n%s\nStatus: open\n' "$f" "$f" > docs/working/briefs/2026-01-01-a.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-1 Q-2
    # Inside a fence only a "### Q-NNN " heading ends the entry, so a shell
    # comment in a pasted block does not cut it short.
    [[ "$output" == *"open Q-1"* && "$output" == *"drop Q-2"* ]] || { echo "$output"; return 1; }
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/2026-01-01-a.md
    [[ "$output" == "ok docs/working/briefs/2026-01-01-a.md open "* ]] || { echo "$output"; return 1; }
}

@test "--check-brief and --check-branch need a default branch found by name; the others do not" {
    echo r > README.md && git add README.md && git commit -qm readme
    git checkout -q -b trunk && git branch -q -D main
    for m in --check-branch --check-brief; do
        run --separate-stderr bash "$DC" "$m" feat/x
        [ "$status" -eq 1 ]
        # shellcheck disable=SC2154  # bats sets $stderr under --separate-stderr
        [[ "$stderr" == *"needs a default branch"* ]] || { echo "$stderr"; return 1; }
    done
    run --separate-stderr bash "$DC" --check-path README.md
    [ "$status" -eq 0 ] && [[ "$output" == "ok README.md" ]] || { echo "$output"; return 1; }
}

@test "a closed fence hides its lines; fences close only with their own kind; the gate is anchored" {
    mkdir -p docs/working
    local f=$'\x60\x60\x60'  # a ``` fence line
    {
        echo '# Questions'; echo
        printf '### Q-3 · keep-or-drop-x-3\n**Needs:** you: judgment · **Status:** ANSWERED\n\n~~~\n%s\n**Answer:** [2]\n~~~\n**Answer:** [1]\n\n' "$f"
        printf '### Q-4 · keep-or-drop-x-4\n**Needs:** you: judgment · **Status:** OPEN (was **Status:** ANSWERED)\n\n**Answer:** [2]\n\n'
        printf '### Q-1 · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\n%s\nfenced, then closed\n%s\n\n' "$f" "$f"
        printf '### Q-2 · other\n**Needs:** you: judgment · **Status:** OPEN\n\n%s\n**Answer:** [2] drop\n%s\n\n' "$f" "$f"
    } > docs/working/questions.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-1 Q-2 Q-3 Q-4
    for want in "unrecognized Q-1" "open Q-2" "keep Q-3" "open Q-4"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
}

@test "--check-brief reads a large brief whole and names the commit that set its status" {
    mkdir -p docs/working/briefs
    b=docs/working/briefs/2026-01-01-big.md
    { printf '# Brief\nStatus: open\n'; head -c 200000 /dev/zero | tr '\0' 'x'; echo; } > "$b"
    git add -A && git commit -qm brief
    sed -i 's/^Status: open$/Status: done/' "$b" && git commit -qam "status done" && c=$(git rev-parse HEAD)
    printf 'Asked: Q-1\n' >> "$b" && git commit -qam asked
    run --separate-stderr bash "$DC" --check-brief "$b"
    [ "$status" -eq 0 ]
    [[ "$output" == "ok $b done $c" ]] || { echo "$output"; return 1; }
}

@test "a question heading inside a fence refuses the whole file, never answers" {
    mkdir -p docs/working
    local f=$'\x60\x60\x60'  # a ``` fence line
    {
        echo '# Questions'; echo
        printf '### Q-10 · notes\n**Needs:** you: judgment · **Status:** ANSWERED\n\n**Answer:** [1]\n\nOriginal:\n%s\n' "$f"
        printf '### Q-11 · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\n**Answer:** [2]\n%s\n\n' "$f"
        printf '### Q-11 · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** OPEN\n\nkeep or drop?\n\n'
    } > docs/working/questions.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-11 Q-10
    [[ "$output" == *"skip Q-11: line 10 of docs/working/questions.md is a question heading inside a code fence"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"skip Q-10: line 10 of"* ]] || { echo "$output"; return 1; }   # the whole file is refused
}

@test "plain column-0 fences: longer fences and info strings; the status field is read whole" {
    mkdir -p docs/working/briefs
    local f3=$'\x60\x60\x60' f4=$'\x60\x60\x60\x60'
    {
        echo '# Questions'; echo
        printf '### Q-1 · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\n%s\n%s\nQ-1: [1]\n%s\n%s\nQ-1: [2]\n\n' "$f4" "$f3" "$f3" "$f4"
        printf '### Q-2 · keep-or-drop-x-2\n**Needs:** you: judgment · **Status:** ANSWERED\n\n%s\n%sbash\n**Answer:** [2]\n%s\n**Answer:** [1]\n\n' "$f3" "$f3" "$f3"
        printf '### Q-4 · keep-or-drop-x-4\n**Needs:** you: judgment · **Status:** OPEN · was set by **Status:** ANSWERED\n\n**Answer:** [2]\n\n'
    } > docs/working/questions.md
    printf '# Brief\n%s\n%s\nStatus: done\n%s\n%s\nStatus: open\n' "$f4" "$f3" "$f3" "$f4" > docs/working/briefs/2026-01-01-n.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-1 Q-2 Q-3 Q-4
    for want in "drop Q-1" "keep Q-2" "open Q-4"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/2026-01-01-n.md
    [[ "$output" == "ok docs/working/briefs/2026-01-01-n.md open "* ]] || { echo "$output"; return 1; }
}

@test "--check-brief names the merge that brought a status change in, and reads closed/ briefs" {
    mkdir -p docs/working/briefs/closed
    b=docs/working/briefs/2026-01-01-m.md
    printf '# Brief\nStatus: open\n\ngoal\nmotive\ncriteria\nbranch\n\n' > "$b" && git add -A && git commit -qm brief
    git checkout -q -b feat/m && sed -i 's/^Status: open$/Status: done/' "$b" && git commit -qam "status done"
    git checkout -q main && printf 'Asked: Q-1\n' >> "$b" && git commit -qam asked
    git merge -q --no-ff -m "merge feat/m" feat/m && m=$(git rev-parse HEAD)
    run --separate-stderr bash "$DC" --check-brief "$b"
    [[ "$output" == "ok $b done $m" ]] || { echo "$output"; return 1; }
    git mv "$b" docs/working/briefs/closed/ && git commit -qm close
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/closed/2026-01-01-m.md "$b"
    [[ "$output" == *"ok docs/working/briefs/closed/2026-01-01-m.md done "* && "$output" == *"ok $b new"* ]] || { echo "$output"; return 1; }
}

@test "header status fields, a second answer line, a list-item fence refusing a brief, a section after an open fence" {
    mkdir -p docs/working/briefs
    local f=$'\x60\x60\x60'  # a ``` fence line
    {
        echo '# Questions'; echo
        printf '### Q-1 · notes\n**Needs:** you: judgment · **Status:** ANSWERED\n\n**Answer:** [1]\n\n%sbash\nls\n%s\n\n' "$f" "$f"
        printf '### Q-20 · keep-or-drop-x-3\n**Needs:** you: judgment · **Status:** ANSWERED · **Note:** x\n\n**Answer:** maybe later\n**Answer:** [1]\n\n'
        printf '### Q-22 · keep-or-drop-x-4\n**Needs:** you: judgment · **Status:** ANSWERED (by user)\n\n**Answer:** [2]\n\n'
        printf '### Q-23 · keep-or-drop-x-5\n**Needs:** (was **Status:** ANSWERED) · **Status:** OPEN\n\n**Answer:** [2]\n\n'
    } > docs/working/questions.md
    printf '# Brief\n- %s\n  Status: done\n  %s\nStatus: open\n' "$f" "$f" > docs/working/briefs/2026-01-01-l.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-18 Q-15 Q-20 Q-22 Q-23
    for want in "skip Q-18: no such entry" "unrecognized Q-20" \
                "open Q-22" "open Q-23"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/2026-01-01-l.md
    [[ "$output" == "skip docs/working/briefs/2026-01-01-l.md: line 2 is a fence-like line that is not a plain column-0 fence"* ]] || { echo "$output"; return 1; }
    # A fence left open before a later section: the whole file is a skip.
    printf '### Q-21 · keep-or-drop-x-6\n**Needs:** you: judgment · **Status:** ANSWERED\n\n%s\nopen\n\n## Archive\n\n**Answer:** [2]\n' "$f" >> docs/working/questions.md
    git commit -qam q21
    run --separate-stderr bash "$DC" --check-answer Q-21 Q-15
    [[ "$output" == *"skip Q-21: the code fence opened at line "* \
       && "$output" == *"skip Q-15: the code fence opened at line "* ]] || { echo "$output"; return 1; }
}

@test "an indented or list-marker fence line anywhere refuses the whole file, naming the line" {
    mkdir -p docs/working/briefs
    local f=$'\x60\x60\x60'  # a ``` fence line
    {
        echo '# Questions'; echo
        printf '### Q-1 · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\n%s\n    %s\n**Answer:** [2]\n%s\n**Answer:** [1]\n\n' "$f" "$f" "$f"
        printf '### Q-2 · keep-or-drop-x-2\n**Needs:** you: judgment · **Status:** ANSWERED\n\n%s\n- %s\n**Answer:** [2]\n%s\n**Answer:** [1]\n\n' "$f" "$f" "$f"
        printf '### Q-3 · keep-or-drop-x-3\n**Needs:** you: judgment · **Status:** ANSWERED\n\n    %s\n**Answer:** [1]\n\n' "$f"
    } > docs/working/questions.md
    printf '# Brief\n%s\n    %s\nStatus: done\n%s\nStatus: open\n' "$f" "$f" "$f" > docs/working/briefs/2026-01-01-i.md
    printf '# Brief\n%s\n1. %s\nStatus: done\n%s\nStatus: open\n' "$f" "$f" "$f" > docs/working/briefs/2026-01-02-l.md
    git add -A && git commit -qm q
    run --separate-stderr bash "$DC" --check-answer Q-1 Q-2 Q-3
    for want in "skip Q-1: line 7 of docs/working/questions.md is a fence-like line" "skip Q-3: line 7"; do
        [[ "$output" == *"$want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/2026-01-01-i.md docs/working/briefs/2026-01-02-l.md
    [[ "$output" == *"skip docs/working/briefs/2026-01-01-i.md: line 3 is a fence-like line"* && "$output" == *"skip docs/working/briefs/2026-01-02-l.md: line 3 is a fence-like line"* ]] || { echo "$output"; return 1; }
}

@test "lines starting with <, open comments, reference definitions, stray CRs and a BOM refuse the file; one-line comments and code spans are read" {
    mkdir -p docs/working/briefs
    local f=$'\x60\x60\x60'  # a ``` fence line
    q() { printf '### %s · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\n%s\n\n' "$1" "$2"; }
    { echo '# Questions'; echo '<!-- index:start -->'; echo '<!-- index:end -->'; echo; q Q-1 '**Answer:** [1]'; } > docs/working/questions.md
    git add -A && git commit -qm ok
    run --separate-stderr bash "$DC" --check-answer Q-1
    [[ "$output" == "keep Q-1" ]] || { echo "$output"; return 1; }
    { echo '# Questions'; echo; printf '<details>\n%s\n' "$f"; q Q-1 'Q-1: [1]'; printf '%s\n**Answer:** [2]\n</details>\n' "$f"; } > docs/working/questions.md
    git commit -qam details
    run --separate-stderr bash "$DC" --check-answer Q-1
    [[ "$output" == "skip Q-1: line 3 of docs/working/questions.md starts with <"* ]] || { echo "$output"; return 1; }
    { echo '# Questions'; echo; printf '<!--\n%s\n-->\n' "$f"; q Q-1 'Q-1: [1]'; } > docs/working/questions.md
    git commit -qam comment
    run --separate-stderr bash "$DC" --check-answer Q-1
    [[ "$output" == "skip Q-1: line 3 of docs/working/questions.md starts with <"* ]] || { echo "$output"; return 1; }
    { echo '# Questions'; printf 'x\r%s\n' "$f"; q Q-1 'Q-1: [1]'; printf '%s\n' "$f"; } > docs/working/questions.md
    git commit -qam cr
    run --separate-stderr bash "$DC" --check-answer Q-1
    [[ "$output" == "skip Q-1: line 2 of docs/working/questions.md holds a carriage return"* ]] || { echo "$output"; return 1; }
    { printf '\357\273\277%s\n' "$f"; q Q-1 'Q-1: [1]'; printf '%s\n' "$f"; } > docs/working/questions.md
    git commit -qam bom
    run --separate-stderr bash "$DC" --check-answer Q-1
    [[ "$output" == "skip Q-1: line 1 of docs/working/questions.md starts with a byte-order mark"* ]] || { echo "$output"; return 1; }
    # An inline comment left open, and a link reference definition, refuse too;
    # a < inside a code span mid-line (as the real files have) does not.
    local bt=$'\x60'
    { echo '# Questions'; echo; echo "Answer as ${bt}Q-0NN: <your answer>${bt}."; q Q-1 'Q-1: [1]'; } > docs/working/questions.md
    git commit -qam codespan
    run --separate-stderr bash "$DC" --check-answer Q-1
    [[ "$output" == "keep Q-1" ]] || { echo "$output"; return 1; }
    { echo '# Questions'; echo 'Note <!--'; q Q-1 'Q-1: [2]'; echo '-->'; } > docs/working/questions.md
    git commit -qam inline
    run --separate-stderr bash "$DC" --check-answer Q-1
    [[ "$output" == "skip Q-1: line 2 of docs/working/questions.md opens an HTML comment"* ]] || { echo "$output"; return 1; }
    { echo '# Questions'; echo "[x]: /u 'title"; q Q-1 'Q-1: [2]'; } > docs/working/questions.md
    git commit -qam refdef
    run --separate-stderr bash "$DC" --check-answer Q-1
    [[ "$output" == "skip Q-1: line 2 of docs/working/questions.md is a link reference definition"* ]] || { echo "$output"; return 1; }
    printf '# Brief\n<div>\n%s\nStatus: done\n%s\n</div>\nStatus: open\n' "$f" "$f" > docs/working/briefs/2026-01-01-h.md
    printf '# Brief\n%s\nStatus: open\n' "$f" > docs/working/briefs/2026-01-02-u.md
    git add -A && git commit -qm briefs
    run --separate-stderr bash "$DC" --check-brief docs/working/briefs/2026-01-01-h.md docs/working/briefs/2026-01-02-u.md
    [[ "$output" == *"skip docs/working/briefs/2026-01-01-h.md: line 2 starts with <"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"skip docs/working/briefs/2026-01-02-u.md: the code fence opened at line 2 is never closed"* ]] || { echo "$output"; return 1; }
}

