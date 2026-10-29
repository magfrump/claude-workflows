#!/usr/bin/env bats
# @category fast
# Contract tests for scripts/harness-feedback.py: the per-project feedback
# file's checker (grammar in guides/harness-feedback.md) and this repo's ingest.
# Each refusal is a one-line mutation of a file that passes, so no assertion
# about `check` holds vacuously. The script runs python3 and git only.

bats_require_minimum_version 1.5.0

load ../lib/hermetic-env

setup() {
    pin_hermetic_locale
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    HF="$REPO_ROOT/scripts/harness-feedback.py"
    W="$BATS_TEST_TMPDIR/work"
    mkdir -p "$W"
    cd "$W" || return 1
    GOOD="$W/good.md"
    cat > "$GOOD" <<'EOF'
# Harness feedback

Free text before the first entry is allowed.

Project: example-app

### F-001 · review-loop-skipped-rubric
**Feature:** pr-prep · **Date:** 2026-10-29 · **Verdict:** fails

- **Context:** opening a PR for the export feature
- **Expected:** amber findings fixed before merge
- **Observed:** the rubric with two amber rows was committed and merged
  (a continuation line is fine)
- **Evidence:** docs/reviews/code-review-rubric-export.md:12

### F-002 · questions-check-caught-dup
**Feature:** questions.sh · **Date:** 2026-10-30 · **Verdict:** works

- **Context:** two sessions filed questions at once
- **Expected:** a duplicate ID is refused
- **Observed:** check refused Q-014 twice (signal: should be neutralised)
- **Evidence:** commit abc1234
EOF
}

# mutate SED-EXPR: write good.md with one edit to bad.md
mutate() {
    sed -e "$1" "$GOOD" > "$W/bad.md"
}

refuses() {
    run -1 python3 "$HF" check "$W/bad.md"
    [[ "$output" == *"$1"* ]] || { echo "expected '$1' in: $output"; return 1; }
}

@test "check: the good file passes and names its project and entry count" {
    run -0 python3 "$HF" check "$GOOD"
    [[ "$output" == "ok $GOOD: project example-app, 2 entries" ]]
}

@test "check: the guide's own example passes" {
    awk '/^```markdown$/{f=1;next} /^```$/{f=0} f' "$REPO_ROOT/guides/harness-feedback.md" > "$W/guide.md"
    [ -s "$W/guide.md" ]
    run -0 python3 "$HF" check "$W/guide.md"
}

@test "check: defaults to docs/harness-feedback.md in the git toplevel" {
    git init -q "$W/proj"
    mkdir -p "$W/proj/docs" "$W/proj/sub"
    cp "$GOOD" "$W/proj/docs/harness-feedback.md"
    cd "$W/proj/sub"
    run -0 python3 "$HF" check
    [[ "$output" == *"/proj/docs/harness-feedback.md: project example-app"* ]]
}

@test "check refuses: no Project line" {
    mutate '/^Project:/d'; refuses "no 'Project: NAME' line"
}

@test "check refuses: a second Project line" {
    mutate 's/^Free text.*/Project: other/'; refuses "second Project line"
}

@test "check refuses: a malformed Project name" {
    mutate 's/^Project: .*/Project: .hidden/'; refuses "Project line must be"
}

@test "check refuses: a heading without the middle-dot separator" {
    mutate 's/^### F-002 · /### F-002 - /'; refuses "line 18: heading after the first entry"
}

@test "check refuses: an ID of fewer than three digits" {
    mutate 's/^### F-002/### F-02/'; refuses "heading after the first entry"
}

@test "check refuses: an uppercase slug" {
    mutate 's/questions-check-caught-dup/Questions/'; refuses "heading after the first entry"
}

@test "check refuses: a repeated ID, by value" {
    mutate 's/^### F-002/### F-0001/'; refuses "F-0001 repeats the ID on line 7"
}

@test "check refuses: another heading after the first entry" {
    mutate 's/^- \*\*Evidence:\*\* commit abc1234/## Notes/'; refuses "line 23: heading after the first entry"
}

@test "check refuses: a missing meta line" {
    mutate '/Date:\*\* 2026-10-30/d'; refuses "F-002 needs the meta line"
}

@test "check refuses: a heading at the end of the file with no meta line" {
    cp "$GOOD" "$W/bad.md"; printf '\n### F-003 · last\n' >> "$W/bad.md"
    refuses "F-003 has no meta line"
}

@test "check refuses: a date that is not a calendar date" {
    mutate 's/2026-10-30/2026-02-30/'; refuses "date 2026-02-30 is not a calendar date"
}

@test "check refuses: an unknown verdict" {
    mutate 's/Verdict:\*\* works/Verdict:** great/'; refuses "verdict 'great' is not one of"
}

@test "check refuses: an empty feature" {
    mutate 's/Feature:\*\* questions.sh/Feature:** /'; refuses "F-002 needs the meta line"
}

@test "check refuses: a missing bullet" {
    mutate '/Expected:\*\* a duplicate/d'; refuses "F-002 is missing **Expected:**"
}

@test "check refuses: a repeated bullet" {
    mutate 's/^- \*\*Evidence:\*\* commit abc1234/- **Context:** again/'; refuses "F-002 repeats **Context:**"
}

@test "check refuses: an empty bullet" {
    mutate 's/^- \*\*Context:\*\* two sessions.*/- **Context:**/'; refuses "F-002 **Context:** needs text"
}

@test "check refuses: a CR line ending" {
    mutate 's/^Project: example-app$/Project: example-app\r/'; refuses "CR byte"
}

@test "check refuses: a control character" {
    mutate "s/two sessions/two $(printf '\001')sessions/"; refuses "control character"
}

@test "check refuses: an HTML comment opener" {
    mutate 's/commit abc1234/commit <!-- x/'; refuses "'<!--' is not allowed"
}

@test "check refuses: bytes that are not UTF-8, with exit 2" {
    cp "$GOOD" "$W/bad.md"; printf '\377\n' >> "$W/bad.md"
    run -2 python3 "$HF" check "$W/bad.md"
    [[ "$output" == *"not UTF-8"* ]]
}

@test "check refuses: a symbolic link and a missing file, with exit 2" {
    ln -s "$GOOD" "$W/link.md"
    run -2 python3 "$HF" check "$W/link.md"
    [[ "$output" == *"not a regular file"* ]]
    run -2 python3 "$HF" check "$W/absent.md"
    [[ "$output" == *"no such file (init creates it)"* ]]
}

@test "check refuses: an unknown command, with usage and exit 2" {
    run -2 python3 "$HF" frobnicate
    [[ "$output" == *"harness-feedback.py check [FILE]"* ]]
}

@test "next-id: one past the highest ID; refuses a file that fails check" {
    run -0 python3 "$HF" next-id "$GOOD"
    [ "$output" = "F-003" ]
    mutate '/^Project:/d'
    run -1 python3 "$HF" next-id "$W/bad.md"
}

@test "init: creates a file that passes and has F-001 next; leaves an existing one" {
    git init -q "$W/my.proj"
    cd "$W/my.proj"
    run -0 python3 "$HF" init
    [[ "$output" == "created "*"/my.proj/docs/harness-feedback.md" ]]
    grep -qx 'Project: my.proj' docs/harness-feedback.md
    run -0 python3 "$HF" next-id
    [ "$output" = "F-001" ]
    echo extra >> docs/harness-feedback.md
    run -0 python3 "$HF" init
    [[ "$output" == "exists "* ]]
    grep -qx extra docs/harness-feedback.md
}

@test "init: refuses to write through a symlinked docs directory" {
    git init -q "$W/proj"
    mkdir "$W/elsewhere"
    ln -s "$W/elsewhere" "$W/proj/docs"
    cd "$W/proj"
    run -2 python3 "$HF" init
    [[ "$output" == *"a symbolic link; refusing to write through it"* ]]
    [ -z "$(ls -A "$W/elsewhere")" ]
}

# ingest: tried on the sample file in a stand-in claude-workflows checkout.
make_repo() {
    git init -q "$W/cw"
    mkdir -p "$W/cw/docs/working"
    printf '# Idea log\n\n- an existing idea (signal: earlier)\n' > "$W/cw/docs/working/idea-log.md"
    cd "$W/cw"
}

@test "ingest: copies the file and appends one seed per entry, in the seed shape" {
    make_repo
    run -0 python3 "$HF" ingest "$GOOD"
    [ "$output" = "ingested example-app: 2 new seeds, 0 already seeded; copy at docs/working/feedback/example-app.md" ]
    cmp "$GOOD" docs/working/feedback/example-app.md
    run grep -c '^- .*(signal: ' docs/working/idea-log.md
    [ "$output" = "3" ]
    grep -qxF -- '- harness feedback, pr-prep (fails): review-loop-skipped-rubric: the rubric with two amber rows was committed and merged (signal: harness feedback example-app F-001, docs/working/feedback/example-app.md)' docs/working/idea-log.md
    grep -qF -- '(signal - should be neutralised)' docs/working/idea-log.md
    run -0 python3 "$HF" check docs/working/feedback/example-app.md
}

@test "ingest: a rerun on a newer copy adds only the new entries" {
    make_repo
    run -0 python3 "$HF" ingest "$GOOD"
    run -0 python3 "$HF" ingest "$GOOD"
    [[ "$output" == "ingested example-app: 0 new seeds, 2 already seeded;"* ]]
    printf '\n### F-003 · new-one\n**Feature:** spike · **Date:** 2026-10-31 · **Verdict:** friction\n\n- **Context:** c\n- **Expected:** e\n- **Observed:** o\n- **Evidence:** v\n' >> "$GOOD"
    run -0 python3 "$HF" ingest "$GOOD"
    [[ "$output" == "ingested example-app: 1 new seeds, 2 already seeded;"* ]]
    [ "$(grep -c 'signal: harness feedback example-app' docs/working/idea-log.md)" = 3 ]
    cmp "$GOOD" docs/working/feedback/example-app.md
}

@test "ingest: a file already under docs/working/feedback is seeded in place" {
    make_repo
    mkdir -p docs/working/feedback
    cp "$GOOD" docs/working/feedback/copied-by-hand.md
    run -0 python3 "$HF" ingest docs/working/feedback/copied-by-hand.md
    [[ "$output" == *"copy at docs/working/feedback/copied-by-hand.md" ]]
    [ ! -e docs/working/feedback/example-app.md ]
}

@test "ingest: creates the idea log when there is none" {
    make_repo
    rm docs/working/idea-log.md
    run -0 python3 "$HF" ingest "$GOOD"
    [ "$(head -1 docs/working/idea-log.md)" = "# Idea log" ]
    [ "$(grep -c '(signal: harness feedback' docs/working/idea-log.md)" = 2 ]
}

@test "ingest: a file that fails check is refused whole, nothing written" {
    make_repo
    mutate '/Expected:\*\* a duplicate/d'
    before="$(cat docs/working/idea-log.md)"
    run -1 python3 "$HF" ingest "$W/bad.md"
    [[ "$output" == *"is missing **Expected:**"* ]]
    [[ "$output" == *"refused: nothing written"* ]]
    [ "$(cat docs/working/idea-log.md)" = "$before" ]
    [ ! -e docs/working/feedback ]
}

@test "ingest: refuses a symlinked idea log or feedback dir, nothing written" {
    make_repo
    mkdir "$W/out"
    mv docs/working/idea-log.md "$W/out/idea-log.md"
    ln -s "$W/out/idea-log.md" docs/working/idea-log.md
    run -2 python3 "$HF" ingest "$GOOD"
    [[ "$output" == *"symbolic link; refusing to write through it"* ]]
    [ ! -e docs/working/feedback ]
    rm docs/working/idea-log.md; mv "$W/out/idea-log.md" docs/working/
    ln -s "$W/out" docs/working/feedback
    run -2 python3 "$HF" ingest "$GOOD"
    [[ "$output" == *"symbolic link; refusing to write through it"* ]]
    [ -z "$(ls -A "$W/out")" ]
}

@test "ingest: takes exactly one file" {
    run -2 python3 "$HF" ingest
    [[ "$output" == *"ingest takes exactly one FILE"* ]]
}
