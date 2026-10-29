#!/usr/bin/env bats
# @category fast
# Convention migrations (scripts/lib/migrations.sh): the merge check that a
# change to a covered convention carries its registry line, the registry's
# grammar, and the digest's section 7b that reports a migration a repo still
# needs. Every repo and copy is under $BATS_TEST_TMPDIR; this repo is untouched.

bats_require_minimum_version 1.5.0

setup() {
    W="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    LIB="$W/scripts/lib/migrations.sh"
    # shellcheck disable=SC2046  # one name per line
    unset $(git rev-parse --local-env-vars)
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
    export HOME="$BATS_TEST_TMPDIR/home"; unset CLAUDE_CONFIG_DIR QUESTIONS_LIVE QUESTIONS_ARCHIVE QUESTIONS_WATCHING
    mkdir -p "$HOME"
}

# A copy of the sources the check fingerprints, plus the lib, under $1.
copy_sources() {
    mkdir -p "$1/scripts/lib" "$1/skills/dev-cycle"
    cp "$W/scripts/questions.sh" "$1/scripts/"
    cp "$LIB" "$1/scripts/lib/"
    cp "$W/skills/dev-cycle/SKILL.md" "$1/skills/dev-cycle/"
}

# Add registry lines ($2...) to the copy's lib $1, where an author adds them:
# at the registry's end, above the run-directly block.
add_mig() {
    local f="$1"; shift
    printf '%s\n' "$@" > "$BATS_TEST_TMPDIR/add"
    perl -i -pe 'BEGIN { local $/; open my $h, "<", $ENV{BATS_TEST_TMPDIR} . "/add" or die; $a = <$h> } print $a if /^if \[\[ "\$\{BASH_SOURCE\[0\]\}" == "\$0" \]\]; then$/' "$f"
    grep -qF -- "$1" "$f"
}

@test "merge check: every covered convention's source matches its newest registry line in this checkout" {
    run --separate-stderr bash "$LIB" check
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [ -z "$output" ]
}

@test "a changed roadmap template fails the check, naming the convention, its new fingerprint and the line to add; adding that line passes" {
    T="$BATS_TEST_TMPDIR/c"; copy_sources "$T"
    perl -0pi -e 's/^## Done$/## Blocked\n## Done/m' "$T/skills/dev-cycle/SKILL.md"
    run --separate-stderr bash "$T/scripts/lib/migrations.sh" check "$T"
    [ "$status" -eq 1 ]
    [[ "$output" == "refuse roadmap: its source's fingerprint is "* ]] || { echo "$output"; return 1; }
    [[ "$output" != *"refuse questions"* && "$output" != *"refuse record"* && "$output" != *"refuse brief"* ]]
    fp="$(sed -n 's/^refuse roadmap: its source.s fingerprint is \([0-9a-f]\{16\}\),.*/\1/p' <<< "$output")"
    [ -n "$fp" ]
    [[ "$output" == *"mig ID roadmap $fp - - 'none: WHY'"* ]]
    add_mig "$T/scripts/lib/migrations.sh" "mig roadmap-blocked roadmap $fp - - 'none: a new empty section'"
    run --separate-stderr bash "$T/scripts/lib/migrations.sh" check "$T"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "each convention's source is found, and each changes its own fingerprint only" {
    T="$BATS_TEST_TMPDIR/c"; copy_sources "$T"
    run --separate-stderr bash "$T/scripts/lib/migrations.sh" fingerprint "$T"
    [ "$status" -eq 0 ]
    [[ "$output" != *"not found"* ]] || { echo "$output"; return 1; }
    before="$output"
    # questions: a route added to the header block; record: a new step line; brief: a new rule line.
    perl -0pi -e 's/^# Routes: /# Routes (new): /m' "$T/scripts/questions.sh"
    perl -0pi -e 's/^1\. health and cleanup: /1. health: /m' "$T/skills/dev-cycle/SKILL.md"
    perl -0pi -e 's/^(For each, write `docs\/working\/briefs\/)/$1 (x) /m' "$T/skills/dev-cycle/SKILL.md"
    run --separate-stderr bash "$T/scripts/lib/migrations.sh" fingerprint "$T"
    for c in questions record brief; do
        [ "$(grep "^$c " <<< "$before")" != "$(grep "^$c " <<< "$output")" ] || { echo "$c unchanged"; return 1; }
    done
    [ "$(grep '^roadmap ' <<< "$before")" = "$(grep '^roadmap ' <<< "$output")" ]
}

@test "a convention whose source anchor is gone fails the check loudly, not as unchanged" {
    T="$BATS_TEST_TMPDIR/c"; copy_sources "$T"
    perl -0pi -e 's/^### 9\. Record and land$/### 9. Record/m' "$T/skills/dev-cycle/SKILL.md"
    run --separate-stderr bash "$T/scripts/lib/migrations.sh" check "$T"
    [ "$status" -eq 1 ]
    [[ "$output" == *"refuse record: its source was not found"* ]] || { echo "$output"; return 1; }
}

@test "a malformed registry line is refused by the check, naming the line and why" {
    T="$BATS_TEST_TMPDIR/c"; copy_sources "$T"
    L="$T/scripts/lib/migrations.sh"
    add_mig "$L" "$(cat <<'EOF'
mig Bad-ID questions 0123456789abcdef - - 'none: x'
mig m1 nosuch 0123456789abcdef - - 'none: x'
mig m2 questions 0123 - - 'none: x'
mig m3 questions 0123456789abcdef docs/working/questions.md '(' 'run it'
mig m4 questions 0123456789abcdef ../x.md 'a' 'run it'
mig m5 questions 0123456789abcdef - - 'run it'
mig m6 questions 0123456789abcdef docs/a.md 'a' 'none: x'
mig baseline-questions questions 0123456789abcdef - - 'none: x'
mig m7 questions 0123456789abcdef - -
EOF
)"
    run --separate-stderr bash "$L" check "$T"
    [ "$status" -eq 1 ]
    for want in "mig Bad-ID: the ID is not" "mig m1: no convention named 'nosuch'" "mig m2: the FP is not 16 hex" \
                "mig m3: the ERE does not compile" "mig m4: PATH is not a plain relative" \
                "mig m5: with PATH '-'" "mig m6: a migration needs an ERE and a command" \
                "mig baseline-questions: the ID is used twice" "mig m7: takes 6 fields, not 5"; do
        [[ "$output" == *"refuse registry: $want"* ]] || { echo "missing: $want"; echo "$output"; return 1; }
    done
}

# The digest, run from a copy of scripts/ whose registry is $1's lines.
digest_with() {
    S="$BATS_TEST_TMPDIR/s"; mkdir -p "$S/lib"
    cp "$W/scripts/dev-cycle.sh" "$W/scripts/questions.sh" "$S/"
    cp "$W"/scripts/lib/*.sh "$S/lib/"
    { echo mig_reset; printf '%s\n' "$1"; } >> "$S/lib/migrations.sh"
    R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R"; cd "$R" || return 1
    git init -q -b main . && git commit -q --allow-empty -m initial
}
section() { sed -n '/^## 7b\. Pending migrations/,/^## 8\./p' <<< "$output"; }

@test "digest: a file still in the old shape is a pending migration, named with its line number and remedy, never its text" {
    digest_with "mig q-old questions 0123456789abcdef docs/working/questions.md '^\*\*Needs:\*\* agent( |\$)' 'questions.sh migrate'"
    mkdir -p docs/working
    printf '# Q\n\n### Q-001 · x\n**Needs:** agent · **Opened:** 2026-10-01 · **Status:** OPEN SECRET-TEXT\n' > docs/working/questions.md
    git add -A && git commit -q -m q
    run --separate-stderr bash "$S/dev-cycle.sh"
    [ "$status" -eq 0 ] || { echo "$stderr"; return 1; }
    sec="$(section)"
    [[ "$sec" == *"- pending q-old (questions): docs/working/questions.md line 4; remedy: questions.sh migrate"* ]] || { echo "$sec"; return 1; }
    [[ "$output" != *SECRET-TEXT* ]]
}

@test "digest: no matching line, or no such file, is no pending migration" {
    digest_with "mig q-old questions 0123456789abcdef docs/working/questions.md '^OLD' 'fix it'
mig r-old roadmap 0123456789abcdef docs/roadmap.md '^## Later\$' 'fix it'"
    mkdir -p docs/working; printf 'NEW\n' > docs/working/questions.md
    run --separate-stderr bash "$S/dev-cycle.sh"
    [ "$status" -eq 0 ]
    [[ "$(section)" == *"None: no file holds a line in a shape a convention change replaced."* ]] || { section; return 1; }
}

@test "digest: a symlinked migration path is not checked, and listed in section 8" {
    digest_with "mig q-old questions 0123456789abcdef docs/working/questions.md '^OLD' 'fix it'"
    mkdir -p docs/working "$BATS_TEST_TMPDIR/out"; printf 'OLD\n' > "$BATS_TEST_TMPDIR/out/q.md"
    ln -s "$BATS_TEST_TMPDIR/out/q.md" docs/working/questions.md
    run --separate-stderr bash "$S/dev-cycle.sh"
    [ "$status" -eq 0 ]
    [[ "$(section)" == *"- not checked q-old: docs/working/questions.md is not read"* ]] || { section; return 1; }
    [[ "$(section)" != *"pending"* ]]
    [[ "$(sed -n '/^## 8\./,$p' <<< "$output")" == *"- docs/working/questions.md"* ]]
}

@test "digest: a missing or malformed registry says migrations were NOT checked" {
    digest_with "mig q-old questions 0123 - - 'none: x'"
    run --separate-stderr bash "$S/dev-cycle.sh"
    [ "$status" -eq 0 ]
    [[ "$(section)" == *"**Migrations were NOT checked** — its registry has malformed lines:"*"- mig q-old: the FP is not 16 hex digits"* ]] || { section; return 1; }
    rm "$S/lib/migrations.sh"
    run --separate-stderr bash "$S/dev-cycle.sh"
    [ "$status" -eq 0 ]
    [[ "$(section)" == *"**Migrations were NOT checked** — lib/migrations.sh is missing beside this script"* ]] || { section; return 1; }
}

@test "digest: this checkout's own registry reads cleanly (no malformed line)" {
    run --separate-stderr bash -c 'source "$1"; printf "%s\n" "${MIG_BAD[@]}"' _ "$LIB"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
