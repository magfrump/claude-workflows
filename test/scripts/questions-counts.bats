#!/usr/bin/env bats
# @category fast
# `questions.sh counts`, the weekly digest's ask counter, on fixture questions
# files in a fixture git repo whose commit dates are set: the answer date is
# the first commit adding an entry to the archive. Run from inside the repo,
# with no QUESTIONS_* override, as the dev cycle runs it.

bats_require_minimum_version 1.5.0

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    QS="$REPO_ROOT/scripts/questions.sh"
    # shellcheck disable=SC2046  # word splitting is wanted: one name per line
    unset $(git rev-parse --local-env-vars) QUESTIONS_LIVE QUESTIONS_ARCHIVE QUESTIONS_WATCHING
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    P="$BATS_TEST_TMPDIR/proj"
    git init -q -b main "$P"
    mkdir -p "$P/docs/working"
    printf '# Running questions\n\n## Open\n\n' > "$P/docs/working/questions.md"
    printf '# Running questions — archive\n\n## Answered\n\n' > "$P/docs/working/questions-archive.md"
    live Q-010 'you: judgment' 2026-11-03 OPEN merge-still-open 'Q-010 waits.'
    live Q-011 'you: judgment' 2026-11-02 ANSWERED answered-not-archived 'Q-011: [1]'
    commit 2026-10-25 Q-009 'you: judgment' 2026-10-24 merge-early 'Q-009: [1]'
    # One commit, two judgment answers: a batched answer is one sitting.
    commit 2026-11-02 Q-001 'you: judgment' 2026-11-01 merge-a 'Q-001: [1]' \
                      Q-002 'you: judgment' 2026-11-02 stopped-b '**Answered:** [1] (owner, in session)'
    commit 2026-11-04 Q-003 'you: judgment' 2026-11-01 pick-one 'Q-003: [2]' \
                      Q-004 'you: terminal' 2026-11-02 run-it 'Q-004: done' \
                      Q-005 'you: fyi' 2026-11-04 read-it 'Q-005: seen' \
                      Q-006 'you: walkthrough' 2026-11-04 try-it 'Q-006: done' \
                      Q-007 'you: judgment' 2026-11-03 extend 'Q-007: extend a week' \
                      Q-012 'you: judgment' 2026-11-01 blocked-c 'Q-012: [1]'
    # A second sitting on the same day: commits 3, answer dates 2.
    commit 2026-11-04 Q-014 'you: judgment' 2026-11-04 pick-two 'Q-014: [1]'
    commit 2026-11-10 Q-008 'you: judgment' 2026-11-09 merge-late 'Q-008: [1]'
    # Answered and archived, but never committed: undated.
    entry Q-013 'you: judgment' 2026-11-05 ANSWERED merge-uncommitted 'Q-013: [1]' >> "$P/docs/working/questions-archive.md"
}

entry() {  # ID ROUTE OPENED STATUS SLUG ANSWERLINE
    printf '### %s · %s\n**Needs:** %s · **Opened:** %s · **Status:** %s\n%s\n\nThe question.\n\n' "$1" "$5" "$2" "$3" "$4" "$6"
}

live() { entry "$@" >> "$P/docs/working/questions.md"; }

commit() {  # DATE, then groups of ID ROUTE OPENED SLUG ANSWERLINE
    local date="$1"; shift
    while (( $# )); do
        entry "$1" "$2" "$3" ANSWERED "$4" "$5" >> "$P/docs/working/questions-archive.md"
        shift 5
    done
    git -C "$P" add -A
    GIT_AUTHOR_DATE="${date}T12:00:00+0000" GIT_COMMITTER_DATE="${date}T12:00:00+0000" \
        git -C "$P" -c user.name=t -c user.email=t@example.invalid commit -q -m "answers $date"
}

counts() { cd "$P" && run bash "$QS" counts "$@"; }

@test "counts prints every class, waits, sittings and the listed entries for a window" {
    counts --since 2026-11-01 --until 2026-11-08
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "$output" == *"| merge | 3 | 1 | 1 | 1 | 1 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"| re-dispatch | 2 | 2 | 2 | 1.5 | 3 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"| real choice | 4 | 3 | 1 | 1 | 3 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"| walkthrough | 1 | 1 | n/a | 0 | 0 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"| terminal | 1 | 1 | n/a | 2 | 2 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"| fyi | 1 | 1 | n/a | 0 | 0 |"* ]] || { echo "$output"; return 1; }
    # Q-001 and Q-002 share a commit (one sitting); Q-014 is a second sitting the day of Q-003's.
    [[ "$output" == *"Sittings: 3 (distinct commits recording a judgment answer); distinct answer dates: 2"* ]] \
        || { echo "$output"; return 1; }
    [[ "$output" == *"Not counted (answered in the window, not an owner route): none"* ]] || { echo "$output"; return 1; }
}

@test "counts lists an answered entry with no archive commit as undated, by ID" {
    counts --since 2026-11-01
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "$output" == *"Undated (answered, but no commit adds it to the archive): Q-011 Q-013"* ]] || { echo "$output"; return 1; }
}

@test "counts lists a free-text answer as not first option, by ID" {
    counts --since 2026-11-01 --until 2026-11-08
    [[ "$output" == *"Not read as an option (counted as not first option): Q-007"* ]] || { echo "$output"; return 1; }
    # Its mutation: answered [1], it is first option and no longer listed.
    sed -i 's/^Q-007: extend a week$/Q-007: [1]/' "$P/docs/working/questions-archive.md"
    counts --since 2026-11-01 --until 2026-11-08
    [[ "$output" == *"| real choice | 4 | 3 | 2 | 1 | 3 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"Not read as an option (counted as not first option): none"* ]] || { echo "$output"; return 1; }
}

@test "counts takes both window bounds inclusively and nothing outside them" {
    counts --since 2026-11-04 --until 2026-11-04
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "$output" == *"| merge | 0 | 0 | 0 | - | - |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"| re-dispatch | 0 | 1 | 1 | 3 | 3 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"Sittings: 2 "* ]] || { echo "$output"; return 1; }
    counts --since 2026-11-10
    [[ "$output" == *"| merge | 0 | 1 | 1 | 1 | 1 |"* ]] || { echo "$output"; return 1; }
    counts --since 2026-10-01 --until 2026-10-31
    [[ "$output" == *"| merge | 1 | 1 | 1 | 1 | 1 |"* ]] || { echo "$output"; return 1; }
}

@test "counts refuses a malformed Needs line by the entry's ID and counts nothing" {
    counts --since 2026-11-01
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    sed -i 's/^\*\*Needs:\*\* you: terminal · \*\*Opened:\*\* 2026-11-02/**Needs:** you: terminel · **Opened:** 2026-11-02/' \
        "$P/docs/working/questions-archive.md"
    counts --since 2026-11-01
    [ "$status" -eq 1 ] || { echo "$output"; return 1; }
    [[ "$output" == *"Q-004: malformed Needs line (route 'you: terminel'"*"nothing counted"* ]] || { echo "$output"; return 1; }
    [[ "$output" != *"| merge |"* ]] || { echo "$output"; return 1; }
}

@test "counts refuses a missing or malformed --since" {
    counts
    [ "$status" -eq 1 ] && [[ "$output" == *"counts needs --since YYYY-MM-DD"* ]] || { echo "$output"; return 1; }
    counts --since 2026-13-40
    [ "$status" -eq 1 ] && [[ "$output" == *"got '2026-13-40'"* ]] || { echo "$output"; return 1; }
    counts --since 2026-11-01 --until yesterday
    [ "$status" -eq 1 ] && [[ "$output" == *"got 'yesterday'"* ]] || { echo "$output"; return 1; }
}

@test "counts refuses when the archive has no git history to date answers from" {
    D="$BATS_TEST_TMPDIR/nogit"
    mkdir -p "$D"
    cp "$P/docs/working/questions.md" "$P/docs/working/questions-archive.md" "$D/"
    cd "$BATS_TEST_TMPDIR"
    QUESTIONS_LIVE="$D/questions.md" QUESTIONS_ARCHIVE="$D/questions-archive.md" run bash "$QS" counts --since 2026-11-01
    [ "$status" -eq 1 ] || { echo "$output"; return 1; }
    [[ "$output" == *"cannot read the git history of $D/questions-archive.md; nothing counted"* ]] || { echo "$output"; return 1; }
}

@test "counts refuses without the dev cycle's answer reader beside it" {
    mkdir -p "$BATS_TEST_TMPDIR/bare"
    cp "$QS" "$BATS_TEST_TMPDIR/bare/questions.sh"
    cd "$P" && run bash "$BATS_TEST_TMPDIR/bare/questions.sh" counts --since 2026-11-01
    [ "$status" -eq 1 ] || { echo "$output"; return 1; }
    [[ "$output" == *"counts needs $BATS_TEST_TMPDIR/bare/lib/dev-cycle-read.sh"*"nothing counted"* ]] || { echo "$output"; return 1; }
}

@test "counts refuses an unreadable questions file instead of printing an empty table" {
    chmod 000 "$P/docs/working/questions-archive.md"
    counts --since 2026-11-01
    chmod 644 "$P/docs/working/questions-archive.md"
    [ "$status" -eq 1 ] || { echo "$output"; return 1; }
    [[ "$output" == *"nothing counted"* && "$output" != *"| merge |"* ]] || { echo "$output"; return 1; }
}

@test "counts refuses a duplicate ID and an Opened that is not a calendar date, by ID" {
    cp "$P/docs/working/questions.md" "$BATS_TEST_TMPDIR/live.before"
    live Q-003 'you: judgment' 2026-11-01 OPEN pick-again 'Q-003 again.'
    counts --since 2026-11-01
    [ "$status" -eq 1 ] && [[ "$output" == *"Q-003: duplicate id; nothing counted"* ]] || { echo "$output"; return 1; }
    cp "$BATS_TEST_TMPDIR/live.before" "$P/docs/working/questions.md"
    sed -i 's/\*\*Opened:\*\* 2026-11-04 · \*\*Status:\*\* ANSWERED$/**Opened:** 2026-11-99 · **Status:** ANSWERED/' "$P/docs/working/questions-archive.md"
    counts --since 2026-11-01
    [ "$status" -eq 1 ] && [[ "$output" == *"Q-005: malformed Needs line (route 'you: fyi', Opened '2026-11-99'"* ]] || { echo "$output"; return 1; }
}

@test "counts lists an answered entry with no answer line as not read, and a non-owner route as not counted" {
    commit 2026-11-06 Q-015 'you: judgment' 2026-11-06 no-answer-line 'The owner said nothing recordable.' \
                      Q-016 agent 2026-11-06 agent-work 'Done by the loop.'
    counts --since 2026-11-06 --until 2026-11-06
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "$output" == *"| real choice | 1 | 1 | 0 | 0 | 0 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"Not read as an option (counted as not first option): Q-015"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"Not counted (answered in the window, not an owner route): Q-016"* ]] || { echo "$output"; return 1; }
}

@test "counts dates an answer added in a merge's conflict resolution by the merge commit" {
    git -C "$P" checkout -q -b side
    commit 2026-11-06 Q-017 'you: judgment' 2026-11-05 side-one 'Q-017: [1]'
    git -C "$P" checkout -q main
    commit 2026-11-06 Q-018 'you: judgment' 2026-11-05 main-one 'Q-018: [1]'
    GIT_AUTHOR_DATE=2026-11-07T12:00:00+0000 GIT_COMMITTER_DATE=2026-11-07T12:00:00+0000 \
        git -C "$P" -c user.name=t -c user.email=t@example.invalid merge -q --no-edit side 2>/dev/null || true
    # Resolve the append-append conflict by hand, adding Q-019 only here.
    git -C "$P" show main:docs/working/questions-archive.md > "$P/docs/working/questions-archive.md"
    entry Q-017 'you: judgment' 2026-11-05 ANSWERED side-one 'Q-017: [1]' >> "$P/docs/working/questions-archive.md"
    entry Q-019 'you: judgment' 2026-11-05 ANSWERED in-the-merge 'Q-019: [2]' >> "$P/docs/working/questions-archive.md"
    git -C "$P" add -A
    GIT_AUTHOR_DATE=2026-11-07T12:00:00+0000 GIT_COMMITTER_DATE=2026-11-07T12:00:00+0000 \
        git -C "$P" -c user.name=t -c user.email=t@example.invalid commit -q --no-edit
    counts --since 2026-11-07 --until 2026-11-07
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [[ "$output" == *"| real choice | 0 | 1 | 0 | 2 | 2 |"* ]] || { echo "$output"; return 1; }
    [[ "$output" == *"Sittings: 1 "* ]] || { echo "$output"; return 1; }
}
