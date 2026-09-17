#!/usr/bin/env bats
# @category fast
# Contract tests for scripts/questions.sh — the running-questions index,
# archive and validator.
#
# Every assertion about `check` here is paired with a mutation that must make it
# fail. This repo has now shipped the same defect class three times (vacuous
# `! grep` assertions in test/init-firewall-rules.bats and a sibling suite, then
# a `check` that passed on an invalid-UTF-8 file because grep silently reported
# it as binary), so a test that only asserts the green path is not accepted here.

bats_require_minimum_version 1.5.0

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    QS="$REPO_ROOT/scripts/questions.sh"
    export QUESTIONS_LIVE="$BATS_TEST_TMPDIR/questions.md"
    export QUESTIONS_ARCHIVE="$BATS_TEST_TMPDIR/questions-archive.md"

    cat > "$QUESTIONS_LIVE" <<'EOF'
# Running questions

## Index

<!-- index:start -->
<!-- index:end -->

## Open

### Q-001 · first-open-thing
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** OPEN

Should the first thing happen?

- **Interim:** it did not happen

### Q-003 · a-watched-condition
**Needs:** trigger · **Opened:** 2026-09-17 · **Status:** OPEN

Watch whether the condition fires.
EOF

    cat > "$QUESTIONS_ARCHIVE" <<'EOF'
# Running questions — archive

## Index

<!-- index:start -->
<!-- index:end -->

## Answered

### Q-002 · an-answered-thing
**Needs:** agent · **Opened:** 2026-09-16 · **Status:** ANSWERED

It was answered.
EOF
}

# --- check: green path ---

@test "check passes on a well-formed pair of files" {
    run bash "$QS" index
    [ "$status" -eq 0 ]
    run bash "$QS" check
    [ "$status" -eq 0 ]
}

# --- check: each rule must be able to fail ---

@test "check rejects an invalid route" {
    bash "$QS" index
    sed -i 's/\*\*Needs:\*\* trigger/**Needs:** whenever/' "$QUESTIONS_LIVE"
    run bash "$QS" check
    [ "$status" -eq 1 ]
    [[ "$output" == *"invalid route"* ]]
}

@test "check rejects a duplicate id" {
    bash "$QS" index
    sed -i 's/### Q-003 ·/### Q-001 ·/' "$QUESTIONS_LIVE"
    run bash "$QS" check
    [ "$status" -eq 1 ]
    [[ "$output" == *"duplicate id"* ]]
}

@test "check rejects a malformed entry heading" {
    bash "$QS" index
    sed -i 's/### Q-003 · a-watched-condition/### Q-3 a watched condition/' "$QUESTIONS_LIVE"
    run bash "$QS" check
    [ "$status" -eq 1 ]
    [[ "$output" == *"malformed entry heading"* ]]
}

@test "check rejects a bad Opened date" {
    bash "$QS" index
    sed -i 's/\*\*Opened:\*\* 2026-09-17 · \*\*Status:\*\* OPEN/**Opened:** last tuesday · **Status:** OPEN/' "$QUESTIONS_LIVE"
    run bash "$QS" check
    [ "$status" -eq 1 ]
    [[ "$output" == *"invalid Opened date"* ]]
}

@test "check rejects an OPEN entry living in the archive" {
    bash "$QS" index
    sed -i 's/\*\*Status:\*\* ANSWERED/**Status:** OPEN/' "$QUESTIONS_ARCHIVE"
    run bash "$QS" check
    [ "$status" -eq 1 ]
    [[ "$output" == *"OPEN but lives in the archive"* ]]
}

@test "check reports a stale index rather than trusting it" {
    bash "$QS" index
    # A new entry appended without reindexing is the everyday drift case.
    cat >> "$QUESTIONS_LIVE" <<'EOF'

### Q-004 · added-without-reindexing
**Needs:** agent · **Opened:** 2026-09-17 · **Status:** OPEN

Appended by hand.
EOF
    run bash "$QS" check
    [ "$status" -eq 1 ]
    [[ "$output" == *"index is stale"* ]]
}

@test "check fails on invalid UTF-8 instead of passing vacuously" {
    # The regression that motivated this suite: under a broken locale grep
    # reports such a file as binary and emits nothing, so every grep-based
    # assertion downstream succeeds without examining anything.
    bash "$QS" index
    printf 'trailing \xe2\x80 partial\n' >> "$QUESTIONS_ARCHIVE"
    run bash "$QS" check
    [ "$status" -eq 1 ]
    [[ "$output" == *"not valid UTF-8"* ]]
}

# --- index ---

@test "index lists every entry and orders the user's items first" {
    run bash "$QS" index
    [ "$status" -eq 0 ]
    run cat "$QUESTIONS_LIVE"
    [[ "$output" == *"Q-001"* ]]
    [[ "$output" == *"Q-003"* ]]
    # you: judgment must sort above trigger; alphabetical would invert this.
    judgment_line="$(grep -an 'Q-001.*you: judgment' "$QUESTIONS_LIVE" | head -1 | cut -d: -f1)"
    trigger_line="$(grep -an 'Q-003.*trigger' "$QUESTIONS_LIVE" | head -1 | cut -d: -f1)"
    [ "$judgment_line" -lt "$trigger_line" ]
}

@test "index is idempotent" {
    bash "$QS" index
    first="$(cat "$QUESTIONS_LIVE")"
    bash "$QS" index
    [ "$first" = "$(cat "$QUESTIONS_LIVE")" ]
}

@test "index writes valid UTF-8 when a summary is truncated mid-character" {
    # An em dash straddling the truncation boundary is exactly what corrupted
    # the real archive; the summary cut is byte-oriented under LC_ALL=C.
    local long
    long="$(printf 'x%.0s' {1..104})"
    cat >> "$QUESTIONS_LIVE" <<EOF

### Q-005 · long-summary-with-em-dash
**Needs:** agent · **Opened:** 2026-09-17 · **Status:** OPEN

${long}—tail that runs past the truncation point and keeps going for a while.
EOF
    run bash "$QS" index
    [ "$status" -eq 0 ]
    run python3 -c 'import sys; open(sys.argv[1],"rb").read().decode("utf-8")' "$QUESTIONS_LIVE"
    [ "$status" -eq 0 ]
}

# --- archive ---

@test "archive moves ANSWERED entries out of the live file" {
    bash "$QS" index
    sed -i 's/### Q-003 · a-watched-condition/### Q-003 · a-watched-condition/' "$QUESTIONS_LIVE"
    # Mark Q-003 answered, then archive it.
    sed -i '/### Q-003/,/^$/s/\*\*Status:\*\* OPEN/**Status:** ANSWERED/' "$QUESTIONS_LIVE"
    run bash "$QS" archive
    [ "$status" -eq 0 ]
    run grep -ac 'Q-003' "$QUESTIONS_LIVE"
    [ "$output" -eq 0 ]
    run grep -ac '### Q-003' "$QUESTIONS_ARCHIVE"
    [ "$output" -eq 1 ]
    run bash "$QS" check
    [ "$status" -eq 0 ]
}

@test "archive leaves OPEN entries in place" {
    bash "$QS" index
    bash "$QS" archive
    run grep -ac '### Q-001' "$QUESTIONS_LIVE"
    [ "$output" -eq 1 ]
}

# --- next-id ---

# `run --separate-stderr` throughout: this container has no usable UTF-8
# locale, so every bash subshell prints a setlocale warning on stderr, and a
# combined-output assertion would be matching that noise rather than the result.
@test "next-id returns one past the highest id across both files" {
    run --separate-stderr bash "$QS" next-id
    [ "$status" -eq 0 ]
    [ "$output" = "Q-004" ]
}

@test "next-id reads zero-padded ids as decimal, not octal" {
    # $((021 + 1)) is 18 in bash, not 22 — a silent collision with a live id.
    sed -i 's/### Q-003 · a-watched-condition/### Q-021 · a-watched-condition/' "$QUESTIONS_LIVE"
    bash "$QS" index
    run --separate-stderr bash "$QS" next-id
    [ "$status" -eq 0 ]
    [ "$output" = "Q-022" ]
}

# --- open ---

@test "open lists only live entries, most costly route first" {
    run --separate-stderr bash "$QS" open
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == *"Q-001"* ]]
    [[ "${lines[0]}" == *"you: judgment"* ]]
    [[ "$output" != *"Q-002"* ]]
}
