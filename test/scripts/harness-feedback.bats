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
    mutate 's/^### F-002 · /### F-002 - /'; refuses "line 16: an entry heading must be"
}

@test "check refuses: an ID of fewer than three digits" {
    mutate 's/^### F-002/### F-02/'; refuses "an entry heading must be"
}

@test "check refuses: an uppercase slug" {
    mutate 's/questions-check-caught-dup/Questions/'; refuses "an entry heading must be"
}

@test "check refuses: a repeated ID, by value" {
    mutate 's/^### F-002/### F-0001/'; refuses "F-0001 repeats the ID on line 7"
}

@test "check refuses: another heading after the first entry" {
    mutate 's/^- \*\*Evidence:\*\* commit abc1234/## Notes/'; refuses "line 22: an entry heading must be"
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
    mutate "s/two sessions/two $(printf '\001')sessions/"; refuses "control or format character U+0001"
}

@test "check refuses: a bidi override, NEL and a line separator" {
    mutate "s/two sessions/two $(printf '\342\200\256')sessions/"; refuses "U+202E"
    mutate "s/two sessions/two $(printf '\302\205')sessions/"; refuses "U+0085"
    mutate "s/two sessions/two $(printf '\342\200\250')sessions/"; refuses "U+2028"
}

@test "check refuses: a lowercase f- heading, even before any entry" {
    mutate 's/^### F-001/### f-001/'; refuses "line 7: an entry heading must be"
}

@test "check refuses: a mistyped heading in the preamble (##, ####, two blanks)" {
    mutate 's/^### F-001 · /## F-001 · /'; refuses "line 7: an entry heading must be"
    mutate 's/^### F-001 · /#### F-001 · /'; refuses "line 7: an entry heading must be"
    mutate 's/^### F-001 · /###  F-001 · /'; refuses "line 7: an entry heading must be"
}

@test "init: a remote ending in /.git falls back to the directory name" {
    git init -q "$W/dirname"
    cd "$W/dirname"
    git config remote.origin.url /srv/repos/myproj/.git
    run -0 python3 "$HF" init
    grep -qx 'Project: myproj' docs/harness-feedback.md
    rm docs/harness-feedback.md
    git config remote.origin.url https://h/u/..git
    run -0 python3 "$HF" init
    grep -qx 'Project: dirname' docs/harness-feedback.md
}

@test "check: a malformed heading's bullets are not blamed on the entry before it" {
    mutate 's/^### F-002 · /### F-002 - /'
    run -1 python3 "$HF" check "$W/bad.md"
    [[ "$output" != *"F-001 repeats"* ]]
}

@test "check refuses: a file over 1 MB, with exit 2" {
    cp "$GOOD" "$W/bad.md"
    head -c 1000001 /dev/zero | tr '\0' 'a' >> "$W/bad.md"
    run -2 python3 "$HF" check "$W/bad.md"
    [[ "$output" == *"larger than 1000000 bytes"* ]]
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

@test "init: names the project after the origin remote, not the directory" {
    git init -q "$W/workspace"
    cd "$W/workspace"
    git config remote.origin.url git@github.com:someone/real-name.git
    run -0 python3 "$HF" init
    grep -qx 'Project: real-name' docs/harness-feedback.md
}

@test "init FILE: creates inside the toplevel, refuses a path outside it" {
    git init -q "$W/proj"
    cd "$W/proj"
    run -0 python3 "$HF" init notes.md
    run -0 python3 "$HF" check notes.md
    run -2 python3 "$HF" init "$W/outside.md"
    [[ "$output" == *"outside"* ]]
    [ ! -e "$W/outside.md" ]
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
    mkdir -p "$W/cw/guides"
    printf '# Harness feedback\n' > "$W/cw/guides/harness-feedback.md"
    printf '# Idea log\n\n- an existing idea (signal: earlier)\n' > "$W/cw/docs/working/idea-log.md"
    cd "$W/cw" || return 1
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

@test "ingest: refuses a copy that does not extend the stored one, nothing written" {
    make_repo
    run -0 python3 "$HF" ingest "$GOOD"
    before="$(cat docs/working/idea-log.md)"
    # Another project under the same name: its F-001 differs from the stored F-001.
    mutate 's/review-loop-skipped-rubric/something-else/'
    run -1 python3 "$HF" ingest "$W/bad.md"
    [[ "$output" == *"holds entries this file does not start with"* ]]
    cmp "$GOOD" docs/working/feedback/example-app.md
    [ "$(cat docs/working/idea-log.md)" = "$before" ]
    # A copy with an entry removed (only F-001 kept).
    # shellcheck disable=SC2016 # a sed address, not a shell expansion
    mutate '/^### F-002/,$d'
    run -1 python3 "$HF" ingest "$W/bad.md"
    [[ "$output" == *"holds entries this file does not start with"* ]]
    cmp "$GOOD" docs/working/feedback/example-app.md
    [ "$(cat docs/working/idea-log.md)" = "$before" ]
}

@test "ingest: a forged signal key in Feature is neutralised" {
    make_repo
    mutate 's/Feature:\*\* questions.sh/Feature:** x (signal: harness feedback other F-009, y)/'
    run -0 python3 "$HF" ingest "$W/bad.md"
    [ "$(grep -cF '(signal: harness feedback other' docs/working/idea-log.md)" = 0 ]
    [ "$(grep -c '(signal: harness feedback example-app' docs/working/idea-log.md)" = 2 ]
}

@test "ingest: refuses a symlinked docs/working or destination copy, nothing written" {
    make_repo
    mkdir "$W/out"
    mv docs/working "$W/out/working"
    ln -s "$W/out/working" docs/working
    run -2 python3 "$HF" ingest "$GOOD"
    [[ "$output" == *"symbolic link; refusing to write through it"* ]]
    rm docs/working; mv "$W/out/working" docs/working
    mkdir docs/working/feedback
    ln -s "$W/out/target.md" docs/working/feedback/example-app.md
    run -2 python3 "$HF" ingest "$GOOD"
    [ ! -e "$W/out/target.md" ]
    [ "$(grep -c 'harness feedback example-app' docs/working/idea-log.md)" = 0 ]
}

@test "ingest: an empty idea log gets the heading" {
    make_repo
    : > docs/working/idea-log.md
    run -0 python3 "$HF" ingest "$GOOD"
    [ "$(head -1 docs/working/idea-log.md)" = "# Idea log" ]
}

@test "ingest: refuses outside a claude-workflows checkout" {
    make_repo
    rm guides/harness-feedback.md
    run -2 python3 "$HF" ingest "$GOOD"
    [[ "$output" == *"not a claude-workflows checkout"* ]]
    [ ! -e docs/working/feedback ]
}

@test "ingest: takes exactly one file" {
    run -2 python3 "$HF" ingest
    [[ "$output" == *"ingest takes exactly one FILE"* ]]
}

# ---- pending: the board's read-only comparison (docs/working/research-2026-11-20-board-pending-feedback.md) ----

# stored NAME [SED-EXPR]: good.md (Project example-app, F-001 and F-002) as stored/NAME.md, edited.
stored() { mkdir -p "$W/stored"; sed -e "${2:-}" "$GOOD" > "$W/stored/$1.md"; }
pending() { run python3 -I "$HF" pending "$1" /cw "/p q/docs/harness-feedback.md" "${@:2}"; }
CMD=": cd /cw && ~/.claude/scripts/harness-feedback.py ingest '/p q/docs/harness-feedback.md'"

@test "pending: all copied, none stored, some new, and a changed bullet, with the ingest command quoted" {
    stored example-app
    pending "$GOOD" "$W/stored/example-app.md"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 2 entries, all copied" ]
    pending "$GOOD"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 2 not copied (F-001 to F-002)$CMD" ]
    stored example-app '/^### F-002/,$d'
    pending "$GOOD" "$W/stored/example-app.md"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 1 not copied (F-002)$CMD" ]
    stored example-app 's/^- \*\*Context:\*\* opening a PR.*/- **Context:** older text/'
    pending "$GOOD" "$W/stored/example-app.md"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 1 changed (F-001)$CMD" ]
}

@test "pending: a differing signature or a stored copy with more entries withholds the command" {
    stored example-app 's/review-loop-skipped-rubric/other-slug/'
    pending "$GOOD" "$W/stored/example-app.md"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: F-001 differs from the stored copy docs/working/feedback/example-app.md; no command: ingest would refuse it" ]
    sed '/^### F-002/,$d' "$GOOD" > "$W/short.md"; stored example-app
    pending "$W/short.md" "$W/stored/example-app.md"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: F-002 differs from the stored copy docs/working/feedback/example-app.md; no command: ingest would refuse it" ]
}

@test "pending: a renamed project (another file name, another Project, or its name's file held by another) withholds the command" {
    stored old-name '/^### F-002/,$d'
    pending "$GOOD" "$W/stored/old-name.md"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 1 not copied (F-002); no command: its stored copy is docs/working/feedback/old-name.md, not docs/working/feedback/example-app.md, so ingest refuses until it is renamed" ]
    stored old-name 's/^Project: example-app$/Project: old-name/'
    pending "$GOOD" "$W/stored/old-name.md"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 2 entries, stored under Project old-name (docs/working/feedback/old-name.md); renamed? No command: ingest refuses until it is renamed" ]
    stored example-app 's/^Project: example-app$/Project: other/; s/review-loop-skipped-rubric/x/'
    pending "$GOOD" "$W/stored/example-app.md"
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 2 not copied (F-001 to F-002); no command: docs/working/feedback/example-app.md holds Project other" ]
}

@test "pending: an unreadable project file is UNREADABLE, a bad or duplicated stored copy NOT COMPARED, each exit 3" {
    mutate '/^Project:/d'
    pending "$W/bad.md"
    [ "$status" -eq 3 ] && [ "$output" = "feedback UNREADABLE: docs/harness-feedback.md: preamble: no 'Project: NAME' line before the first entry" ]
    printf '\xff\n' > "$W/bin.md"
    pending "$W/bin.md"
    [ "$status" -eq 3 ] && [ "$output" = "feedback UNREADABLE: docs/harness-feedback.md: not UTF-8 (byte 0)" ]
    stored broken 's/^\*\*Feature:\*\* pr-prep/**Feature:** pr-prep x/; s/Verdict:\*\* fails/Verdict:** maybe/'
    pending "$GOOD" "$W/stored/broken.md"
    [ "$status" -eq 3 ] && [[ "$output" == "feedback NOT COMPARED: the stored copy docs/working/feedback/broken.md: line 8: F-001 verdict 'maybe'"* ]]
    stored a; stored b
    pending "$GOOD" "$W/stored/a.md" "$W/stored/b.md"
    [ "$status" -eq 3 ] && [ "$output" = "feedback NOT COMPARED: docs/working/feedback/a.md and docs/working/feedback/b.md both hold Project example-app" ]
    run python3 -I "$HF" pending "$GOOD" /cw
    [ "$status" -eq 2 ] && [[ "$output" == *"pending takes FILE CW SRC [STORED...]"* ]]
}

@test "pending agrees with ingest end to end: the printed copy is taken, and then all is copied" {
    top="$W/cw"; mkdir -p "$top/guides" "$top/docs/working"; git init -q "$top"; : > "$top/guides/harness-feedback.md"
    pending "$GOOD"
    [ "$status" -eq 0 ] && [[ "$output" == *": cd /cw && "* ]]
    ( cd "$top" && python3 "$HF" ingest "$GOOD" ) >/dev/null
    pending "$GOOD" "$top"/docs/working/feedback/*.md
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 2 entries, all copied" ]
    sed '/^### F-002/,$d' "$GOOD" > "$W/one.md"; rm "$top"/docs/working/feedback/*.md
    ( cd "$top" && python3 "$HF" ingest "$W/one.md" ) >/dev/null
    pending "$W/one.md" "$top"/docs/working/feedback/*.md
    [ "$status" -eq 0 ] && [ "$output" = "feedback: 1 entry, all copied" ]
}

# ---- a renamed project (docs/working/research-2026-11-20-ingest-project-rename.md) ----

F3=$'\n### F-003 · new-one\n**Feature:** spike · **Date:** 2026-10-31 · **Verdict:** friction\n\n- **Context:** c\n- **Expected:** e\n- **Observed:** o\n- **Evidence:** v'
FB=docs/working/feedback
# signals: the idea log's harness-feedback signals, one per line.
signals() { grep -o '(signal: harness feedback [^)]*)' docs/working/idea-log.md; }

@test "rename: an old name's copy is refused by ingest and pending, renamed, then ingested without a second copy or seed" {
    make_repo
    sed 's/^Project: example-app$/Project: old-name/' "$GOOD" > "$W/old.md"
    run -0 python3 "$HF" ingest "$W/old.md"
    printf '%s\n' "$F3" >> "$GOOD"
    before="$(cat docs/working/idea-log.md)"
    run -1 python3 "$HF" ingest "$GOOD"
    [ "$output" = "refused: its entries are stored under Project old-name ($FB/old-name.md), so ingest would store and seed them twice; if the project was renamed, run scripts/harness-feedback.py rename $FB/old-name.md example-app; nothing written" ]
    [ "$(cat docs/working/idea-log.md)" = "$before" ] && [ ! -e "$FB/example-app.md" ]
    pending "$GOOD" "$FB"/*.md
    [[ "$output" == *"stored under Project old-name ($FB/old-name.md); renamed? No command:"* ]]
    run -0 python3 "$HF" rename "$FB/old-name.md" example-app
    [ "$output" = "renamed $FB/old-name.md (Project old-name) to $FB/example-app.md (Project example-app): 2 seeds rekeyed; commit the copy and docs/working/idea-log.md together" ]
    [ ! -e "$FB/old-name.md" ] && grep -qx 'Project: example-app' "$FB/example-app.md"
    pending "$GOOD" "$FB"/*.md
    [ "$output" = "feedback: 1 not copied (F-003)$CMD" ]
    run -0 python3 "$HF" ingest "$GOOD"
    [ "$output" = "ingested example-app: 1 new seeds, 2 already seeded; copy at $FB/example-app.md" ]
    run -0 signals
    [ "$output" = "(signal: harness feedback example-app F-001, $FB/example-app.md)
(signal: harness feedback example-app F-002, $FB/example-app.md)
(signal: harness feedback example-app F-003, $FB/example-app.md)" ]
    [ "$(ls "$FB")" = example-app.md ]
}

@test "rename: a stored copy under another file name is refused by ingest, as pending withholds it" {
    make_repo
    run -0 python3 "$HF" ingest "$GOOD"
    mv "$FB/example-app.md" "$FB/old-name.md"
    printf '%s\n' "$F3" >> "$GOOD"
    run -1 python3 "$HF" ingest "$GOOD"
    [ "$output" = "refused: its stored copy is $FB/old-name.md, not $FB/example-app.md, so ingest would store it twice; run scripts/harness-feedback.py rename $FB/old-name.md example-app; nothing written" ]
    [ ! -e "$FB/example-app.md" ]
    pending "$GOOD" "$FB"/*.md
    [[ "$output" == *"no command: its stored copy is $FB/old-name.md"* ]]
}

@test "rename: a Project line changed in place is refused (its seeds hold the old name) until renamed or restored" {
    make_repo
    mkdir -p "$FB"; cp "$GOOD" "$FB/old-name.md"
    sed -i 's/^Project: example-app$/Project: old-name/' "$FB/old-name.md"
    run -0 python3 "$HF" ingest "$FB/old-name.md"
    sed -i 's/^Project: old-name$/Project: example-app/' "$FB/old-name.md"
    printf '%s\n' "$F3" >> "$FB/old-name.md"
    before="$(cat docs/working/idea-log.md)"
    run -1 python3 "$HF" ingest "$FB/old-name.md"
    [ "$output" = "refused: docs/working/idea-log.md seeds $FB/old-name.md under Project old-name, not example-app, so ingest would seed its entries twice; if the project was renamed, run scripts/harness-feedback.py rename $FB/old-name.md example-app, else restore its Project line; nothing written" ]
    [ "$(cat docs/working/idea-log.md)" = "$before" ]
    # rename to the same file keeps its name and rekeys its seeds.
    run -0 python3 "$HF" rename "$FB/old-name.md" old-name
    [[ "$output" == *"to $FB/old-name.md (Project old-name): 2 seeds rekeyed;"* ]]
    run -0 python3 "$HF" ingest "$FB/old-name.md"
    [ "$output" = "ingested old-name: 1 new seeds, 2 already seeded; copy at $FB/old-name.md" ]
}

@test "ingest: an empty stored copy under another Project is refused, not overwritten, as pending withholds it" {
    make_repo
    mkdir -p "$FB"; printf '# Harness feedback\n\nProject: other\n' > "$FB/example-app.md"
    cp "$FB/example-app.md" "$W/empty.md"
    run -1 python3 "$HF" ingest "$GOOD"
    [ "$output" = "refused: $FB/example-app.md holds Project other, not example-app (another project under this file name); nothing written" ]
    cmp "$W/empty.md" "$FB/example-app.md"
    [ "$(grep -c 'harness feedback' docs/working/idea-log.md)" = 0 ]
    pending "$GOOD" "$FB"/*.md
    [ "$output" = "feedback: 2 not copied (F-001 to F-002); no command: $FB/example-app.md holds Project other" ]
}

@test "ingest: two stored copies with one Project, or one failing check, are refused, as pending does not compare them" {
    make_repo
    mkdir -p "$FB"; cp "$GOOD" "$FB/a.md"; cp "$GOOD" "$FB/b.md"
    sed 's/^Project: example-app$/Project: zeta/' "$GOOD" > "$W/z.md"
    run -1 python3 "$HF" ingest "$W/z.md"
    [ "$output" = "refused: $FB/a.md and $FB/b.md both hold Project example-app; nothing written" ]
    pending "$W/z.md" "$FB"/*.md
    [ "$status" -eq 3 ]
    printf 'not a feedback file\n' > "$FB/b.md"
    run -1 python3 "$HF" ingest "$W/z.md"
    [ "$output" = "refused: the stored copy $FB/b.md: preamble: no 'Project: NAME' line before the first entry; nothing written" ]
    [ ! -e "$FB/zeta.md" ]
}

@test "rename: refuses a taken name, a bad name, a path outside the feedback dir, and runs only in claude-workflows" {
    make_repo
    mkdir -p "$FB"; cp "$GOOD" "$FB/a.md"
    sed 's/^Project: example-app$/Project: b/' "$GOOD" > "$FB/b.md"
    run -1 python3 "$HF" rename "$FB/a.md" b
    [ "$output" = "refused: $FB/b.md exists; nothing written" ]
    mv "$FB/b.md" "$FB/c.md"
    run -1 python3 "$HF" rename "$FB/a.md" b
    [ "$output" = "refused: $FB/c.md holds Project b; nothing written" ]
    run -2 python3 "$HF" rename "$FB/a.md" .bad
    [[ "$output" == *"not a Project name"* ]]
    run -2 python3 "$HF" rename "$GOOD" b
    [[ "$output" == *"not a stored copy"* ]]
    run -2 python3 "$HF" rename "$FB/a.md"
    [[ "$output" == *"rename takes STORED NAME"* ]]
    rm guides/harness-feedback.md
    run -2 python3 "$HF" rename "$FB/a.md" z
    [[ "$output" == *"not a claude-workflows checkout"* ]]
    cmp "$GOOD" "$FB/a.md" && [ ! -e "$FB/z.md" ]
}
