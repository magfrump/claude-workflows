#!/usr/bin/env bats
# @category fast
# Contract tests for the orchestrator's own reads in build-loop.sh: --state
# (U3b1, T42) and --marker (U3b1, T32, T34's --marker case), each in a
# throwaway repo under $BATS_TEST_TMPDIR (test/lib/build-loop-fixtures.bash).

bats_require_minimum_version 1.5.0
load ../lib/build-loop-fixtures

setup() { bl_setup; }

bl() { run --separate-stderr bash "$BL" "$@"; }
show() { echo "status $status"; echo "$output"; echo "$stderr"; }
# state_is WANT: --state printed exactly WANT, with exit 0 for "ok" and 2 otherwise.
state_is() { bl --state; local s=2; [[ "$1" != ok ]] || s=0; [ "$status" -eq "$s" ] && [ "$output" = "$1" ] && [ -z "$stderr" ] || { echo "want: $1"; show; return 1; }; }
# marked MESSAGE: brief x (open, feat/x) with one work commit and a marker
# commit with MESSAGE at its tip; T is the tip.
marked() { brief x "Status: open" "Branch: feat/x"; work feat/x; tip feat/x "$1"; T="$(git rev-parse feat/x)"; }
# marker_is WANT: --marker printed exactly WANT (lines joined by newlines), exit 0.
marker_is() { bl --marker "$B"; [ "$status" -eq 0 ] && [ "$output" = "$1" ] && [ -z "$stderr" ] || { echo "want: $1"; show; return 1; }; }
RULE='no line that starts, after blanks, ">" and list markers ("-", "*", "+", "1." or "1)" and a blank), with "#", **Needs:**, **Status:**, **Answer, or Q- and a digit, in any case; no line holding "<!--"; strict UTF-8'

@test "--state prints ok for a clean repository and refuses each planted state, exit 2 (T42, U3b1)" {
    state_is ok
    S="it can make the gate's git run a command or change its merge"
    for k in core.fsmonitor filter.lfs.clean hook.pre.command; do
        git config "$k" x; state_is "refuse state $k: set in config, $S"; git config --unset "$k"; done
    git replace "$(git rev-parse main)" "$(git commit-tree "$(git rev-parse 'main^{tree}')" -m other)"
    state_is "refuse state refs/replace: 1 replace ref(s)"; git replace -d "$(git rev-parse main)"
    printf '* filter=x\n' > .git/info/attributes; state_is "refuse state info/attributes: present and not an empty file"; rm .git/info/attributes
    # default_gate's half, once main is found: both names, and a default branch that names a tag (row 656).
    git branch -q master; state_is "refuse state default-branch: both main and master exist"; git branch -q -D master
    # git's update-ref refuses a branch at a non-commit: write the ref file.
    git tag -a -m t t1 main; git rev-parse t1 > .git/refs/heads/main
    state_is "refuse state default-branch: refs/heads/main names an object that is not a commit"; git rev-parse 't1^{commit}' > .git/refs/heads/main; state_is ok
}

@test "--state refuses a caller's repo-local git variable or a config pair for a state-gate or hardening key (rows 276, 281, 666, U3b1)" {
    V="set in the caller's environment, so git can read another repository, object store, index, config, graft, shallow or replace-ref file"
    for v in GIT_REPLACE_REF_BASE=refs/x/ GIT_GRAFT_FILE=/dev/null GIT_SHALLOW_FILE=/dev/null "GIT_ALTERNATE_OBJECT_DIRECTORIES=$PWD" GIT_INDEX_FILE=/dev/null; do
        run --separate-stderr env "$v" bash "$BL" --state
        [ "$status" -eq 2 ] && [ "$output" = "refuse state ${v%%=*}: $V" ] || { echo "$v"; show; return 1; }
    done
    K="set by the caller's git -c or GIT_CONFIG_COUNT pairs, a key the state gate refuses or one the gate's own hardening sets (a git -c pair wins over it)"
    run --separate-stderr env GIT_CONFIG_PARAMETERS="'core.useReplaceRefs'='true' 'merge.x.driver'='true' 'user.name'='caller'" bash "$BL" --state
    [ "$status" -eq 2 ] && [ "$output" = "refuse state core.usereplacerefs: $K
refuse state merge.x.driver: $K" ] || { show; return 1; }
    run --separate-stderr env GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller GIT_CONFIG_KEY_1=core.hooksPath GIT_CONFIG_VALUE_1=/x bash "$BL" --state
    [ "$status" -eq 2 ] && [ "$output" = "refuse state core.hookspath: $K" ] || { show; return 1; }
    # A plain caller pair passes; a count git_harden would misread stops every mode (row 276).
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller state_is ok
    for c in 010 08 1x " 1"; do
        run --separate-stderr env GIT_CONFIG_COUNT="$c" GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller bash "$BL" --settings
        [ "$status" -eq 1 ] && [ -z "$output" ] && [ "$stderr" = "build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count" ] || { echo "count [$c]"; show; return 1; }
    done
    # Only --state reads the caller's environment: neither --settings nor the gated --check refuses for it.
    run --separate-stderr env GIT_REPLACE_REF_BASE=refs/x/ bash "$BL" --settings; [ "$status" -eq 0 ] || { show; return 1; }
    brief x "Status: open" "Branch: feat/x"; work feat/x
    run --separate-stderr env GIT_REPLACE_REF_BASE=refs/x/ GIT_CONFIG_PARAMETERS="'merge.x.driver'='true'" bash "$BL" --check "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "ok $B "* ]] || { show; return 1; }
}

@test "--marker quotes a blocked marker's plain body, every line prefixed (T32, U3b1)" {
    marked $'handoff: blocked\n\nWhich export format?\n\n| Option | What it means |\n|---|---|\n| **[1] CSV** | one file |\n\n- a list item\n1. a numbered one\n\n'
    marker_is "ok $B $T
> Which export format?
>
> | Option | What it means |
> |---|---|
> | **[1] CSV** | one file |
>
> - a list item
> 1. a numbered one"
    # A stopped marker's body is quoted too, and may be empty.
    tip feat/x $'handoff: stopped: adds a dependency\n\nneeds jq'; T="$(git rev-parse feat/x)"
    marker_is "ok $B $T
> needs jq"
    tip feat/x 'handoff: stopped: adds a dependency'; T="$(git rev-parse feat/x)"
    marker_is "ok $B $T"
}

@test "--marker skips a body line in entry grammar, after blanks, quotes and list markers (T32 E2/E3, D11, U3b1)" {
    marked $'handoff: blocked\n\nplain'
    W="skip $B: a line of its marker's body breaks the blocked-body rule ($RULE): line"
    for l in '**Needs:** you: judgment · **Status:** OPEN' '**Answer:** [1]' '**Status:** ANSWERED' '### Q-001 · x' '# Heading' \
        'Q-1: [1]' '  > - Q-2: [2]' '1. **answer (recommended):** [1]' '> > **needs:** agent' 'see <!-- index:start --> here'; do
        tip feat/x "$(printf 'handoff: blocked\n\nfirst\n%s' "$l")"; marker_is "$W 2" || { echo "line: $l"; return 1; }; done
    # Not strict UTF-8 as questions.sh check (Python) reads it: a stray byte, a surrogate Perl's own
    # decoder takes, past U+10FFFF (i2 fact-check 7b). Written raw: git commit-tree re-encodes a message.
    for b in '\377' '\355\240\200' '\364\220\200\200'; do
        c="$(printf "tree %s\nparent %s\nauthor t <t@x> 1 +0000\ncommitter t <t@x> 1 +0000\n\nhandoff: blocked\n\nfirst\nbad $b byte\n" \
            "$(git rev-parse 'feat/x^{tree}')" "$(git rev-parse feat/x)" | git hash-object -t commit -w --stdin)"
        git update-ref refs/heads/feat/x "$c"; marker_is "$W 2" || { echo "bytes: $b"; return 1; }; done
    # E2's whole body (rev 3 pre-mortem): skipped at its first grammar line.
    tip feat/x $'handoff: blocked\n\n**Needs:** you: judgment · **Opened:** 2026-10-04 · **Status:** OPEN\n\n| Option | x |\n|---|---|\n\n**Answer:** [1]'; marker_is "$W 1"
    # Prose that only mentions the grammar mid-line is quoted.
    tip feat/x $'handoff: blocked\n\nthe entry gets a **Needs:** line and a Q-1 ID from you'; T="$(git rev-parse feat/x)"
    marker_is "ok $B $T
> the entry gets a **Needs:** line and a Q-1 ID from you"
}

@test "--marker skips a body FENCE_AWK refuses, raw or quoted, and an empty blocked body (T32, U3b1)" {
    marked $'handoff: blocked\n\nplain\n```\ncode'
    marker_is "skip $B: the code fence opened at line 2 of its marker's body is never closed"
    tip feat/x $'handoff: blocked\n\nplain\n[a]: https://example.invalid'
    marker_is "skip $B: line 2 of its marker's body starts like a link reference definition (its label or title can span lines)"
    tip feat/x $'handoff: blocked\n\n<div>x</div>'; marker_is "skip $B: line 1 of its marker's body starts with < after any blanks (a possible raw HTML block; only a complete one-line <!-- comment --> is read)"
    tip feat/x $'handoff: blocked\n\n- [x]: y'; marker_is "skip $B: line 1 of its marker's body starts like a link reference definition (its label or title can span lines)"
    for m in $'handoff: blocked\n\n\n  \n' 'handoff: blocked'; do tip feat/x "$m"; marker_is "skip $B: its blocked marker holds no question (the body is empty)"; done
    # Inside a balanced fence the raw pass reads nothing; quoted, the line is a link reference definition.
    tip feat/x $'handoff: blocked\n\n```\n[a]: b\n```'; marker_is "skip $B: line 2 of its marker's body starts like a link reference definition (its label or title can span lines)"
    # A marker commit over the cap is skipped before its body is processed (performance i1 F1).
    tip feat/x "$(printf 'handoff: blocked\n\n'; head -c 70000 /dev/zero | tr '\0' 'x')"
    bl --marker "$B"; [ "$status" -eq 0 ] && [[ "$output" =~ ^"skip $B: its marker is "[0-9]+" bytes, over the 65536-byte cap"$ ]] || { show; return 1; }
}

@test "--marker scrubs controls and bidi and caps the body at 100 lines of 300 bytes, with a quoted note (T32, U3b1)" {
    marked "$(printf 'handoff: blocked\n\na\001b\342\200\256c\r\nd\302\233e')"
    marker_is "ok $B $T
> abc
> de"
    long="$(printf 'x%.0s' $(seq 299))"
    tip feat/x "$(printf 'handoff: blocked\n\n%s\n%s\n%s\303\251z' "${long}y" "${long}yz" "$long")"; T="$(git rev-parse feat/x)"
    # 300 bytes kept; a two-byte character that would end past byte 300 is dropped whole.
    marker_is "ok $B $T
> ${long}y
> ${long}y
> ${long}
> (build-loop.sh --marker cut this body: 3 of 3 lines shown, 2 cut at 300 bytes)"
    tip feat/x "$(printf 'handoff: blocked\n\n'; seq 101)"; T="$(git rev-parse feat/x)"
    bl --marker "$B"
    [ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 102 ] && [ "${lines[0]}" = "ok $B $T" ] && [ "${lines[100]}" = "> 100" ] \
        && [ "${lines[101]}" = "> (build-loop.sh --marker cut this body: 100 of 101 lines shown, 0 cut at 300 bytes)" ] || { show; return 1; }
}

@test "--marker skips a tip that is no blocked or stopped marker, and takes one brief (T32, U3b1)" {
    brief x "Status: open" "Branch: feat/x"
    marker_is "skip $B: the tip of feat/x is not a blocked or stopped marker (absent)"
    work feat/x; marker_is "skip $B: the tip of feat/x is not a blocked or stopped marker (working)"
    tip feat/x 'handoff: ready'; marker_is "skip $B: the tip of feat/x is not a blocked or stopped marker (ready)"
    tip feat/x 'handoff: sideways'; bl --marker "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "skip $B: the tip of feat/x starts \"handoff:\" but is not a marker: "* ]] || { show; return 1; }
    bl --marker; [ "$status" -eq 1 ] && [[ "$stderr" == "--marker takes one brief path"* ]] || { show; return 1; }
    bl --marker "$B" "$B"; [ "$status" -eq 1 ] || { show; return 1; }
}

@test "a body --marker quoted leaves both questions readers on the orchestrator's own lines (T34 E2, U3b1)" {
    QS="$REPO_ROOT/scripts/questions.sh"
    bash "$QS" init > /dev/null
    # E2: the loop's grammar lines, quoted as --marker quotes a body (which it would refuse); the user's answer is [2].
    { printf '\n### Q-120 · export-format\n**Needs:** you: judgment · **Opened:** 2026-10-04 · **Status:** ANSWERED\n\n'
      printf '> %s\n' '**Needs:** you: judgment · **Opened:** 2026-10-04 · **Status:** OPEN' '' '| Option | x |' '|---|---|' '' '**Answer:** [1]'
      printf '\nQ-120: [2]\n'; } >> docs/working/questions.md
    commit_all questions
    run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-answer Q-120
    [ "$output" = "drop Q-120" ] || { show; return 1; }
    # questions.sh reads the orchestrator's ANSWERED (the last Needs line won in E2): archive moves the entry out.
    run --separate-stderr bash "$QS" archive
    [ "$status" -eq 0 ] && grep -q '^### Q-120 ' docs/working/questions-archive.md && ! grep -q '^### Q-120 ' docs/working/questions.md || { show; cat docs/working/questions.md; return 1; }
}

# ml SINCE STATUS WANT: --main-log SINCE printed exactly WANT with exit STATUS. qs: docs/working/questions.md
# with entry Q-001 (OPEN, an options table), committed. q SED [LINE...]: edit it by sed, append LINEs, commit.
ml() { bl --main-log "$1"; [ "$status" -eq "$2" ] && [ "$output" = "$3" ] && [ -z "$stderr" ] || { echo "want $2: $3"; show; return 1; }; }
q() { sed -i "$1" docs/working/questions.md; shift; [[ $# -eq 0 ]] || printf '%s\n' "$@" >> docs/working/questions.md; commit_all answer; }
qs() { mkdir -p docs/working; printf '%s\n' '# Questions' '' '### Q-001 · x' '**Needs:** you: judgment · **Opened:** 2026-10-12 · **Status:** OPEN' '' 'Which?' '' '| Option | x |' '|---|---|' '| **[1] a** | b |' > docs/working/questions.md; commit_all questions; }
# chore B RECORD-LINE: B with a cycle record holding RECORD-LINE, merged into main with --no-ff.
chore() { git checkout -q -b "$1" main && mkdir -p docs/working/cycles && printf '# Cycle\n%s\n' "$2" > docs/working/cycles/cycle-2026-10-12.md \
    && commit_all record && git checkout -q main && git merge -q --no-ff -m "Merge branch '$1': cycle" "$1"; }

@test "--main-log classifies each first-parent commit after SINCE, oldest first: gate, chore, answers, other (T39, U3b2)" {
    settings "Build-loop policy: self-merge" "Self-merge never: none"
    brief x "Status: open" "Branch: feat/x" "Policy: self-merge" "Paths: work-feat-x.txt"; work feat/x; qs; S="$(git rev-parse main)"
    ml "$S" 0 "main $S 0"
    git checkout -q --detach main; bash "$BL" --merge "$B" --expect "$(git rev-parse feat/x)" > /dev/null; git checkout -q main; G="$(git rev-parse main)"
    chore chore/dev-cycle-2026-10-12-1430 "Branch: chore/dev-cycle-2026-10-12-1430"; C="$(git rev-parse main)"
    q 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/' '' '- **Answer:** [1]' 'Q-001: [1]'; A="$(git rev-parse main)"
    mkdir -p docs; echo x > docs/x.md; commit_all "docs: x"; O="$(git rev-parse main)"
    # Answer-shaped, but the options table changes too (T39).
    q 's/| b |/| c |/' 'Q-001: [2]'; T="$(git rev-parse main)"
    ml "$S" 2 "main $T 5
gate $G Merge branch 'feat/x' (build-loop self-merge)
chore $C Merge branch 'chore/dev-cycle-2026-10-12-1430': cycle
answers $A answer
other $O docs: x
other $T answer"
    ml "$A" 2 "main $T 2
other $O docs: x
other $T answer"
}

@test "--main-log reads other for a near miss of each class, and refuses a SINCE off main's first-parent history (T39, U3b2)" {
    qs; S="$(git rev-parse main)"; work feat/x; X="$(git rev-parse feat/x)"
    M="Merge branch 'feat/x' (build-loop self-merge)"$'\n\n'"Build-loop-gate: 2026-10-01-x"
    # The gate message on two parents with their clean merge is gate; with a line more, on one parent,
    # approved without its trailer, or over another tree (an amended merge: i1 security F1), other.
    tip main "$M" "$(git merge-tree --write-tree main "$X")" "$S" "$X"; G="$(git rev-parse main)"
    tip main "$M"$'\nmore' "$(git merge-tree --write-tree main "$X")" "$G" "$X"; tip main "$M"
    tip main "Merge branch 'feat/x' (build-loop approved merge)"$'\n\n'"Build-loop-gate: 2026-10-01-x" "$(git merge-tree --write-tree main "$X")" "$(git rev-parse main)" "$X"
    git checkout -q feat/x; echo slip > slip.txt; commit_all slip; git checkout -q main
    tip main "$M" "$(git merge-tree --write-tree main feat/x)" "$(git rev-parse main)" "$X"; T="$(git rev-parse main)"
    ml "$S" 2 "main $T 5
gate $G Merge branch 'feat/x' (build-loop self-merge)
other $(git rev-parse main~3) Merge branch 'feat/x' (build-loop self-merge)
other $(git rev-parse main~2) Merge branch 'feat/x' (build-loop self-merge)
other $(git rev-parse main~1) Merge branch 'feat/x' (build-loop approved merge)
other $T Merge branch 'feat/x' (build-loop self-merge)"
    # A chore merge whose record names another branch, a branch outside the pattern, or amended with
    # another file; an empty commit (subject printed as -); a header line whose route changes too; a
    # blank line alone; a Status flip alone; deleting an answer (i1 security F2).
    q 's/x/x/' 'Q-001: [1]'; S="$(git rev-parse main)"
    chore chore/dev-cycle-2026-10-12 "Branch: chore/dev-cycle-2026-10-13"; chore chore/dev-cycle-x "Branch: chore/dev-cycle-x"
    chore chore/dev-cycle-2026-10-14 "Branch: chore/dev-cycle-2026-10-14"; echo slip > slip2.txt; git add slip2.txt; git commit -q --amend --no-edit
    tip main ''; E="$(git rev-parse main)"
    # The Status flip first: once it is ANSWERED, only the route can change (a real diff each: i2 fact-check 2).
    # The route change adds an answer line, so only the header rule makes it other (final fact-check 43).
    q 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/'; q 's/you: judgment/agent/' 'Q-001: [3]'; q '' ''; q '/^Q-001: \[1\]$/d'
    for i in 4 3 2 1; do [ -n "$(git diff "main~$i" "main~$((i - 1))")" ] || { echo "empty: main~$i"; return 1; }; done
    bl --main-log "$S"; [ "$status" -eq 2 ] && [ "${#lines[@]}" -eq 9 ] && [ "${lines[4]}" = "other $E -" ] \
        && [ "$(printf '%s\n' "${lines[@]:1}" | cut -d' ' -f1 | sort -u)" = other ] || { show; return 1; }
    # SINCE: the merged branch's tip is no first-parent commit of main (main's line still comes first); a short id is usage.
    T="$(git rev-parse main)"; ml "$X" 2 "main $T -
refuse main-log: $X is not on the default branch's first-parent history at $T"
    bl --main-log "${X:0:12}"; [ "$status" -eq 1 ] && [[ "$stderr" == "--main-log takes one full 40- or 64-hex commit id"* ]] || { show; return 1; }
}

# The D6 snippet (U3b3). d6_copy ROOT OPT: D6, a copy of test/lib/d6-snippet.bash
# with D6_ROOT and D6_OPT replaced. d6_setup: main holds this branch's four
# scripts, and D6 takes this fixture's root commit as claude-workflows' own.
d6_copy() { D6="$BATS_TEST_TMPDIR/d6.bash"; sed "s|^  D6_ROOT=.*; D6_OPT=.*|  D6_ROOT=$1; D6_OPT=$2|" "$REPO_ROOT/test/lib/d6-snippet.bash" > "$D6"; grep -qxF "  D6_ROOT=$1; D6_OPT=$2" "$D6"; }
d6_setup() {
    mkdir -p scripts/lib && cp "$REPO_ROOT"/scripts/{build-loop,dev-cycle,questions}.sh scripts/ && cp "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" scripts/lib/
    commit_all scripts && d6_copy "$(git rev-list --max-parents=0 main)" /opt/claude-workflows
}
d6() { run --separate-stderr bash "$D6" "$@"; }
# d6_is WANT: the snippet refused with exactly WANT, exit 2, before running anything.
d6_is() { d6 build-loop.sh --settings; [ "$status" -eq 2 ] && [ "$output" = "$1" ] && [ -z "$stderr" ] || { echo "want: $1"; show; return 1; }; }
# shim: a git ahead of the real one on PATH that logs each call's config pairs and environment (T26's).
shim() {
    S="$BATS_TEST_TMPDIR/shim"; mkdir -p "$S"
    printf '#!/bin/bash\nl=""; for ((i = 0; i < ${GIT_CONFIG_COUNT:-0}; i++)); do k="GIT_CONFIG_KEY_$i"; v="GIT_CONFIG_VALUE_$i"; l+=" ${!k}=${!v}"; done\necho "$l G=$GIT_CONFIG_GLOBAL P=$GIT_ALLOW_PROTOCOL S=$GIT_CONFIG_NOSYSTEM" >> "%s/calls"\nexec "%s" "$@"\n' "$BATS_TEST_TMPDIR" "$(command -v git)" > "$S/git"
    chmod +x "$S/git"
}

@test "the D6 snippet runs main's four scripts from a fresh temp dir, each with its own lib and questions.sh, never the working tree's, and removes the dir (T33, U3b3)" {
    d6_setup
    # main's lib says where it was sourced from; main's questions.sh answers open with one watched entry.
    echo 'echo "lib at ${BASH_SOURCE[0]}" >&2' >> scripts/lib/dev-cycle-read.sh
    sed -i '2i [[ "${1:-}" != open ]] || { echo "Q-001  trigger  from-main"; exit 0; }' scripts/questions.sh
    mkdir -p docs/working && printf '# Questions\n' > docs/working/questions.md && printf '# Archive\n' > docs/working/questions-archive.md
    commit_all "marked copies"
    for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do echo 'exit 9' > "scripts/$f"; done
    export TMPDIR="$BATS_TEST_TMPDIR/t"; mkdir "$TMPDIR"
    d6 build-loop.sh --settings
    [ "$status" -eq 0 ] && [[ "$output" == *"slots 3 default: "* ]] && [ -n "$stderr" ] || { show; return 1; }
    while IFS= read -r l; do [[ "$l" == "lib at $TMPDIR/"*/scripts/lib/dev-cycle-read.sh ]] || { echo "[$l]"; show; return 1; }; done <<<"$stderr"
    # The snippet exports no config pair, so --state run through it passes caller_gate (row 702).
    d6 build-loop.sh --state; [ "$status" -eq 0 ] && [ "$output" = ok ] || { show; return 1; }
    d6 dev-cycle.sh
    [ "$status" -eq 0 ] && [[ "$output" == *$'\n- Q-001  trigger  from-main\n'* ]] || { show; return 1; }
    [ -z "$(ls -A "$TMPDIR")" ] || { ls -A "$TMPDIR"; return 1; }
    # A byte the reader did not hash is never used: a git whose cat-file --batch alters one word of the blobs it prints.
    git checkout -q -- scripts; S="$BATS_TEST_TMPDIR/tamper"; mkdir -p "$S"
    printf '#!/bin/bash\nif [[ " $* " == *" --batch "* ]]; then "%s" "$@" | sed -u s/pipefail/PIPEFAIL/; else exec "%s" "$@"; fi\n' "$(command -v git)" "$(command -v git)" > "$S/git"; chmod +x "$S/git"
    PATH="$S:$PATH" d6 build-loop.sh --settings
    [ "$status" -eq 2 ] && [ "$output" = "$A1" ] && [[ "$stderr" == *" does not hash to its id" ]] || { show; return 1; }
    [ -z "$(ls -A "$TMPDIR")" ] || { ls -A "$TMPDIR"; return 1; }
    # The SKILL.md block and test/lib/d6-snippet.bash are byte-equal (T33): pending until U4 writes the block.
}

@test "the D6 snippet refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master (T36, U3b3)" {
    d6_setup
    R="refuse d6: a replace ref exists (F38)"
    id="$(git rev-parse main:scripts/build-loop.sh)"; git replace "$id" "$(printf 'echo replaced\n' | git hash-object -w --stdin)"; d6_is "$R"; git replace -d "$id"
    c="$(git rev-parse main)"; git replace "$c" "$(git commit-tree "$(git rev-parse 'main^{tree}')" -m other)"; d6_is "$R"; git replace -d "$c"
    git rev-parse main > .git/info/grafts; d6_is "refuse d6: info/grafts exists (F38)"; rm .git/info/grafts
    git branch -q master; d6_is "refuse d6: the default branch is not exactly one of main and master"; git branch -q -D master
    git branch -q feat/y; git symbolic-ref refs/heads/main refs/heads/feat/y; d6_is "refuse d6: refs/heads/main is a symbolic ref"
    # git refuses to update-ref a branch to a tag: write the ref file (row 656's case).
    git update-ref --no-deref refs/heads/main "$c"; git tag -a -m t t1 main; git rev-parse t1 > .git/refs/heads/main
    d6_is "refuse d6: refs/heads/main names no commit"; echo "$c" > .git/refs/heads/main
    d6 build-loop.sh --settings; [ "$status" -eq 0 ] || { show; return 1; }
    run --separate-stderr bash "$D6" x; [ "$status" -eq 1 ] && [ -z "$output" ] && [ "$stderr" = "d6: the first argument is build-loop.sh or dev-cycle.sh" ] || { show; return 1; }
}

# inplace ID FROM: the loose object file for ID now holds FROM's object, as a same-uid writer could leave it.
inplace() { local o=".git/objects/${1:0:2}/${1:2}" f=".git/objects/${2:0:2}/${2:2}"; chmod u+w "$o"; cp "$f" "$o"; }
A1="refuse d6: main's first-parent history, the trees down to scripts/lib/ or the four files could not be read whole, or an object does not hash to its id"

@test "the D6 snippet refuses the scripts/ tree rewritten in place, and runs no planted bytes (T36, U3b3 i1 A1, i2 B1)" {
    d6_setup
    # A scripts tree whose build-loop.sh says replaced, written over main's real scripts tree.
    x="$(git rev-parse main:scripts)"; e="$(printf 'echo replaced\n' | git hash-object -w --stdin)"
    y="$(git ls-tree main:scripts | sed "s/ [0-9a-f]*\tbuild-loop.sh$/ $e\tbuild-loop.sh/" | git mktree)"
    inplace "$x" "$y"; [ "$(git ls-tree --format="%(objectname)" main -- scripts/build-loop.sh)" = "$e" ]
    d6 build-loop.sh --settings
    [ "$status" -eq 2 ] && [ "$output" = "$A1" ] || { show; return 1; }
}

@test "the D6 snippet refuses a first-parent commit rewritten in place to end main's history at D6_ROOT (T36, U3b3 i1 A1)" {
    d6_setup
    r="$(git commit-tree "$(git rev-parse 'main^{tree}')" -m root)"; t="$(git rev-parse main)"
    f="$(printf 'tree %s\nparent %s\nauthor t <t@e> 1 +0000\ncommitter t <t@e> 1 +0000\n\nforged\n' "$(git rev-parse 'main^{tree}')" "$r" | git hash-object -t commit -w --stdin)"
    inplace "$t" "$f"; [ "$(git rev-list --first-parent --max-parents=0 main)" = "$r" ]
    d6_copy "$r" /opt/claude-workflows; d6 build-loop.sh --settings
    # The verified reader names the mismatch on stderr; the one stdout line is the snippet's.
    [ "$status" -eq 2 ] && [ "$output" = "$A1" ] || { show; return 1; }
}

@test "the D6 snippet refuses, never falls to the image copy, when main's first-parent history cannot be read whole: a missing commit, a shallow clone (T36, U3b3 i2 B2)" {
    d6_setup; c="$(git rev-parse main~1)"; rm -f ".git/objects/${c:0:2}/${c:2}"
    d6 build-loop.sh --settings; [ "$status" -eq 2 ] && [ "$output" = "$A1" ] || { show; return 1; }
    git clone -q --depth 1 "file://$BATS_TEST_TMPDIR/repo" "$BATS_TEST_TMPDIR/shallow"
    cd "$BATS_TEST_TMPDIR/shallow"; d6 build-loop.sh --settings; [ "$status" -eq 2 ] && [ "$output" = "$A1" ] || { show; return 1; }
}

@test "the D6 snippet reads a first parent only directly after the tree line, as git does: a late parent line is no parent (T37, U3b3 final security F1 b)" {
    d6_setup; r="$(git commit-tree "$(git rev-parse 'main^{tree}')" -m root)"
    c="$(printf 'tree %s\nauthor t <t@e> 1 +0000\ncommitter t <t@e> 1 +0000\nparent %s\n\nlate\n' "$(git rev-parse 'main^{tree}')" "$r" | git hash-object -t commit -w --stdin)"
    git update-ref refs/heads/main "$c"; [ "$(git rev-list --max-parents=0 main)" = "$c" ]
    # D6_ROOT names the commit only the late line points at: the snippet must take the image copy (a uid-owned stub here, so refused).
    U="$BATS_TEST_TMPDIR/opt"; mkdir -p "$U/scripts/lib"; d6_copy "$r" "$U"
    d6_is "refuse d6: $U/scripts/build-loop.sh is not root-owned, a plain path and unwritable here"
}

@test "a gate copy patched in the loop's worktree prints ok for its tip; the D6 snippet's copy from main refuses the same tip (T27, U3b3)" {
    d6_setup; brief x "Status: open" "Branch: feat/x"
    W="$BATS_TEST_TMPDIR/wt"; git worktree add -q -b feat/x "$W" main; cd "$W"
    # The loop drops the mode rule from its own copy and adds a symlink.
    sed -i 's/elif \[\[ ! "\$2 \$3" =~/elif false \&\& [[ ! "$2 $3" =~/' scripts/build-loop.sh; grep -q 'elif false && ' scripts/build-loop.sh
    ln -s x link; commit_all loop
    run --separate-stderr bash scripts/build-loop.sh --check "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "ok $B "* ]] || { show; return 1; }
    d6 build-loop.sh --check "$B"
    [ "$status" -eq 2 ] && [[ "$output" == "refuse $B: 1 of 2 changed paths refused in the merge of $(git rev-parse feat/x) "* ]] \
        && [[ "$output" == *$'\n'"deny $B A link: a symlink, gitlink or other non-file entry on one side "* ]] || { show; return 1; }
}

@test "outside claude-workflows the D6 snippet runs the image copy by absolute path, not main's copy (T37, U3b3)" {
    O=/opt/claude-workflows
    [[ -f "$O/scripts/build-loop.sh" && "$(stat -c %u "$O/scripts")" == 0 ]] || skip "no root-owned image copy at $O here"
    mkdir -p scripts; printf 'echo main copy\n' > scripts/build-loop.sh; commit_all scripts
    run --separate-stderr bash "$REPO_ROOT/test/lib/d6-snippet.bash" build-loop.sh --help
    [ "$status" -eq 0 ] && [ "$output" = "$(bash "$O/scripts/build-loop.sh" --help)" ] || { show; return 1; }
}

@test "outside claude-workflows the D6 snippet refuses an image copy the uid owns, and never runs main's (T37, U3b3)" {
    mkdir -p scripts; printf 'echo main copy\n' > scripts/build-loop.sh; commit_all scripts
    U="$BATS_TEST_TMPDIR/opt"; mkdir -p "$U/scripts/lib"
    cp "$REPO_ROOT"/scripts/{build-loop,dev-cycle,questions}.sh "$U/scripts/"; cp "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" "$U/scripts/lib/"
    d6_copy 640cf00735754d4253819a0354fb8ca9b71a8ea7 "$U"
    d6_is "refuse d6: $U/scripts/build-loop.sh is not root-owned, a plain path and unwritable here"
}

@test "git_harden exports HARDEN's pairs after the caller's and a fixed environment, once however often it is called; the D6 snippet's git carries the same (rows 281, 311, 495, U3b3)" {
    L="$REPO_ROOT/scripts/lib/dev-cycle-read.sh"
    run env -i PATH="$PATH" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=c bash -c 'source "$1"; git_harden; git_harden; echo "caller $CALLER_COUNT"; printf "pair %s\n" "${HARDEN[@]}"; env | grep "^GIT_" | sort' _ "$L"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    H="core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false log.date=default log.showSignature=false"
    E="GIT_ALLOW_PROTOCOL=none GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0"
    want="caller 1"; for kv in $H; do want+=$'\n'"pair $kv"; done
    k=0; keys="GIT_CONFIG_KEY_0=user.name"; vals="GIT_CONFIG_VALUE_0=c"
    for kv in $H; do k=$((k + 1)); keys+=$'\n'"GIT_CONFIG_KEY_$k=${kv%%=*}"; vals+=$'\n'"GIT_CONFIG_VALUE_$k=${kv#*=}"; done
    want+=$'\n'"$(printf '%s\n' $E "GIT_CONFIG_COUNT=9" "$keys" "$vals" | LC_ALL=C sort)"
    [ "$output" = "$want" ] || { diff <(echo "$want") <(echo "$output"); return 1; }
    # The snippet cannot source the lib (it runs before anything is checked): its one git array repeats both lists.
    g="$(grep '^  G=(env ' "$REPO_ROOT/test/lib/d6-snippet.bash")"
    [ "$(grep -o -- '-c [^ )]*' <<<"$g" | cut -c4- | tr '\n' ' ')" = "$H " ] || { echo "$g"; return 1; }
    [ "$(grep -o 'GIT_[A-Z_]*=[^ ]*' <<<"$g" | LC_ALL=C sort | tr '\n' ' ')" = "$E " ] || { echo "$g"; return 1; }
}

@test "every git call dev-cycle.sh makes carries git_harden's pairs: a bogus log.date stops nothing, log.showSignature runs no gpg.program (rows 495, 505, U3b3)" {
    brief x "Status: open"
    # A signed-looking commit on main: git log under log.showSignature runs gpg.program for it.
    c="$(printf 'tree %s\nparent %s\nauthor t <t@e> 1700000000 +0000\ncommitter t <t@e> 1700000000 +0000\ngpgsig -----BEGIN PGP SIGNATURE-----\n \n x\n -----END PGP SIGNATURE-----\n\nsigned\n' "$(git rev-parse 'main^{tree}')" "$(git rev-parse main)" | git hash-object -t commit -w --stdin)"
    git update-ref refs/heads/main "$c"; git reset -q --hard main
    printf '#!/bin/sh\ntouch "%s/gpg-ran"\nexit 1\n' "$BATS_TEST_TMPDIR" > "$BATS_TEST_TMPDIR/gpg"; chmod +x "$BATS_TEST_TMPDIR/gpg"
    git config log.date bogus; git config log.showSignature true; git config gpg.program "$BATS_TEST_TMPDIR/gpg"; shim
    PATH="$S:$PATH" run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-brief "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "ok $B open "* ]] || { show; return 1; }
    PATH="$S:$PATH" run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --since=2020-01-01
    [ "$status" -eq 0 ] && [[ "$output" == *"## 3. Watched questions"* ]] || { show; return 1; }
    [ ! -e "$BATS_TEST_TMPDIR/gpg-ran" ] || { echo "gpg.program ran"; return 1; }
    n="$(wc -l < "$BATS_TEST_TMPDIR/calls")"; [ "$n" -gt 10 ] || { echo "only $n calls logged"; return 1; }
    # HARDEN from the lib itself, so a key added there is checked here too.
    for kv in $(bash -c 'source "$1"; echo "${HARDEN[*]}"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh") G=/dev/null P=none S=1; do
        ! grep -v -- " $kv" "$BATS_TEST_TMPDIR/calls" || { echo "a call without $kv"; return 1; }
    done
}

# cd_is WANT [ARG...]: --cycle-diff ARG... printed exactly WANT, exit 0 for "ok" and 2 otherwise. onmain PATH TEXT:
# main moves by one commit setting PATH to TEXT, the checkout untouched. qa: the questions files on main, then a chore branch.
cd_is() { local w="$1"; shift; bl --cycle-diff "$@"; local s=2; [[ "$w" != ok ]] || s=0; [ "$status" -eq "$s" ] && [ "$output" = "$w" ] && [ -z "$stderr" ] || { echo "want: $w"; show; return 1; }; }
onmain() { local x="$BATS_TEST_TMPDIR/ix" b; b="$(printf '%s\n' "$2" | git hash-object -w --stdin)"; GIT_INDEX_FILE="$x" git read-tree main
    GIT_INDEX_FILE="$x" git update-index --add --cacheinfo "100644,$b,$1"; git update-ref refs/heads/main "$(git commit-tree "$(GIT_INDEX_FILE="$x" git write-tree)" -p main -m moved)"; }
N='**Needs:** you: judgment · **Opened:** 2026-10-12 · **Status:**'
qa() { mkdir -p docs/working; printf '%s\n' '# Questions' '### Q-001 · x' "$N OPEN" '' 'Which?' '| **[1] a** | b |' '### Q-003 · z' "$N ANSWERED" 'Q-003: [1]' > docs/working/questions.md
    printf '%s\n' '# Archive' '### Q-000 · old' "$N ANSWERED" '- **Answer:** [2]' 'Q-000: [1]' > docs/working/questions-archive.md; commit_all questions; git checkout -q -b chore/dev-cycle-2026-10-12; }

@test "--cycle-diff refuses an entry's header or answer changed or gone without --answered, and passes body edits, an open new entry and an archive move (T38, U3c)" {
    qa; cd_is ok
    W="refuse docs/working/questions.md: Q-001's heading, Needs or answer lines changed or are gone, and Q-001 is not in --answered"
    # A planted ANSWERED flip (T38), alone and with an answer line; the same with the ID listed passes.
    sed -i 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/' docs/working/questions.md; git add -A; cd_is "$W"
    sed -i '/^Which/a Q-001: [1]' docs/working/questions.md; git add -A; cd_is "$W"; cd_is ok --answered Q-003 --answered Q-001
    git reset -q --hard
    # A deleted entry, two answer lines swapped (--check-answer reads the first: i1 A1), a route change, a removed answer line, a deleted archive.
    sed -i '/^### Q-001/,/^| \*\*\[1\]/d' docs/working/questions.md; git add -A; cd_is "$W"; git reset -q --hard
    sed -i '/^- \*\*Answer/{h;d}; /^Q-000/G' docs/working/questions-archive.md; git add -A; W0="${W//Q-001/Q-000}"; cd_is "${W0/questions.md/questions-archive.md}"; git reset -q --hard
    sed -i 's/you: judgment/agent/' docs/working/questions.md; git add -A; cd_is "$W
${W//Q-001/Q-003}"; git reset -q --hard
    sed -i '/^Q-003/d' docs/working/questions.md; git add -A; cd_is "${W//Q-001/Q-003}"; git reset -q --hard
    git rm -q docs/working/questions-archive.md; cd_is "${W0/questions.md/questions-archive.md}"; git reset -q --hard
    # Free: body lines, an appended open entry, Q-003 archived (moved whole between the files).
    sed -i 's/| b |/| c |/' docs/working/questions.md
    sed -n '/^### Q-003/,$p' docs/working/questions.md >> docs/working/questions-archive.md; sed -i '/^### Q-003/,$d' docs/working/questions.md
    printf '%s\n' '### Q-002 · y' "$N OPEN" 'Why?' >> docs/working/questions.md; git add -A; cd_is ok
    # A new entry filed answered is the user's only with its ID listed (F33: a pre-answered merge entry).
    printf '%s\n' '### Q-004 · merge-x-0123456789ab' "$N ANSWERED" >> docs/working/questions.md; git add -A
    cd_is "refuse docs/working/questions.md: Q-004 is a new entry filed answered (Status ANSWERED or an answer line), and Q-004 is not in --answered"
    cd_is ok --answered Q-004
    # A copy --check-answer refuses whole: FENCE_AWK's, or a fenced question heading (removing one would make its answers readable: final fact-check claim 42).
    printf '%s\n' '```' >> docs/working/questions.md; git add -A; cd_is "refuse docs/working/questions.md: --check-answer refuses its index copy whole (unbalanced 12)"
    printf '%s\n' '### Q-005 · q' '```' >> docs/working/questions.md; git add -A; cd_is "refuse docs/working/questions.md: --check-answer refuses its index copy whole (quoted 13)"
    # Main moves meanwhile (step 7's merges): the base stays the fork point, so main's new roadmap is not the cycle's deletion.
    git reset -q --hard; sed -i '/^Which/a Q-001: [1]' docs/working/questions.md; git add -A
    onmain docs/roadmap.md "# R"; cd_is ok --answered Q-001
    # A questions change on main meanwhile (a user's answer): the merge could fence it off (i2 security F1), so main is merged first.
    onmain docs/working/questions.md "# Q"; cd_is "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $(git rev-parse HEAD); merge it into HEAD, then stage again" --answered Q-001
    git reset -q --hard; git merge -q --no-edit main; printf '%s\n' '### Q-009 · n' "$N OPEN" >> docs/working/questions.md; git add -A; cd_is ok
    # The bypass itself: main's copy holds a fenced question heading, and the index drops it.
    git reset -q --hard; onmain docs/working/questions.md "$(printf '%s\n' '```' '### Q-006 · f' '```')"; git merge -q --no-edit main
    sed -i '/^### Q-006/d' docs/working/questions.md; git add -A; cd_is "refuse docs/working/questions.md: --check-answer refuses its base copy whole (quoted 2)"
    # A criss-cross history (each side merged the other's older tip): the land would merge through a virtual base (final security F1).
    git reset -q --hard; git commit -q --allow-empty -m c1; onmain x.md x; M="$(git rev-parse main)"
    git update-ref refs/heads/main "$(git commit-tree 'main^{tree}' -p main -p HEAD -m m2)"; git merge -q --no-edit "$M"
    cd_is "refuse HEAD: it has more than one merge base with the default branch's $(git rev-parse main); merge the default branch into HEAD first"
}

@test "the answer label regex is the same in the lib's ANSWER_AWK, ANSWERS_AWK and QKEYS_AWK (U3c i2 architecture 1)" {
    r='/^\*\*answer(:|ed| \()/'
    [ "$(grep -cF "$r" "$REPO_ROOT/scripts/lib/dev-cycle-read.sh")" -eq 1 ] && [ "$(grep -cF "$r" "$BL")" -eq 2 ]
}

@test "--cycle-diff refuses a roadmap preamble, heading or dropped brief line and an idea log edited, not appended; passes the cycle's own rewrites (T38, U3c)" {
    mkdir -p docs/working; I='- **X**: Brief: `docs/working/briefs/2026-10-01-x.md`'
    printf '%s\n' '# Roadmap' 'Intro.' '## Now' '- a' '## In flight' "$I" '## Next' '1. n' '## Ideas' '## Done (last cycle)' '- y: `docs/working/briefs/closed/2026-09-01-y.md`' > docs/roadmap.md
    printf '%s\n' '# Idea log' '- i1 (signal: s)' > docs/working/idea-log.md; commit_all roadmap; git checkout -q -b chore/dev-cycle-2026-10-12
    # Step 6's rewrites: Next reworded, Done trimmed, X moved to Done at closed/, an idea appended, any other path.
    sed -i 's/^1\. n/1. m/; /2026-09-01-y/d; /2026-10-01-x/d' docs/roadmap.md; echo '- X done: `docs/working/briefs/closed/2026-10-01-x.md`' >> docs/roadmap.md
    echo '- i2 (signal: t)' >> docs/working/idea-log.md; echo x > other.md; git add -A; cd_is ok
    git reset -q --hard; sed -i '/2026-10-01-x/d' docs/roadmap.md; git add -A
    cd_is "refuse docs/roadmap.md: the brief 2026-10-01-x.md, named outside Done on the base, is named on no line"; git reset -q --hard
    sed -i 's/^Intro\./Intro!/; s/^## Next/## Later/' docs/roadmap.md; sed -i 's/i1/i0/' docs/working/idea-log.md; git add -A
    cd_is "refuse docs/roadmap.md: its lines above the first ## heading changed
refuse docs/roadmap.md: its ## headings changed
refuse docs/working/idea-log.md: edited other than by appending"; git reset -q --hard
    git rm -q docs/roadmap.md; rm docs/working/idea-log.md; ln -s x docs/working/idea-log.md; git add -A
    cd_is "refuse docs/roadmap.md: it is deleted
refuse docs/working/idea-log.md: a side is not a regular file (mode 100644), or could not be read"; git reset -q --hard
    # No merge base; usage.
    git checkout -q --orphan lone; cd_is "refuse HEAD: it shares no commit with the default branch's $(git rev-parse main), or could not be read"
    for a in "--answered" "--answered 7" "x"; do bl --cycle-diff $a; [ "$status" -eq 1 ] && [ -z "$output" ] || { echo "[$a]"; show; return 1; }; done
}

@test "--cycle-diff refuses the gate's own code and a brief's Asked: line other than extended, matched by name across a move to closed/ (row 745, U4a)" {
    F=docs/working/briefs/2026-10-01-x.md; C=docs/working/briefs/closed/2026-10-01-x.md; mkdir -p docs/working/briefs/closed scripts/lib
    printf '%s\n' 'Status: open' 'Asked: Q-001@abc' > "$F"; echo s > scripts/lib/a.sh; commit_all briefs; git checkout -q -b chore/dev-cycle-2026-10-12
    W="its first Asked: line drops or changes an ID it held; the cycle only appends one"
    sed -i 's/^Asked: .*/&, Q-002@def/' "$F"; git add -A; cd_is ok; git reset -q --hard
    git mv "$F" "$C"; cd_is ok; sed -i 's/^Asked: .*/Asked: Q-002@def/' "$C"; git add -A; cd_is "refuse $C: $W"; git reset -q --hard
    sed -i 's/Q-001@abc/Q-009@abc/' "$F"; git add -A; cd_is "refuse $F: $W"; git reset -q --hard
    mkdir -p SKILLS/dev-cycle; echo s > SKILLS/dev-cycle/x.md; echo t >> scripts/lib/a.sh; git add -A
    G="the gate's own code; an in-cycle fix edits only docs --check-fix allows"; cd_is "refuse SKILLS/dev-cycle/x.md: $G
refuse scripts/lib/a.sh: $G"
}

# lc_is WANT ARG...: --land-cycle ARG... refused with exactly WANT, exit 2. rec LINE...: the day's cycle record gains LINEs, committed.
lc_is() { local w="$1"; shift; bl --land-cycle "$@"; [ "$status" -eq 2 ] && [ "$output" = "$w" ] && [ -z "$stderr" ] || { echo "want: $w"; show; return 1; }; }
rec() { mkdir -p docs/working/cycles && printf '%s\n' "$@" >> docs/working/cycles/cycle-2026-10-12.md && commit_all record; }

@test "--land-cycle lands HEAD's chore branch as the merge --main-log reads as chore, by compare-and-swap or a fast-forward where main is checked out (D13, rows 719, 749, 752, U4a)" {
    qa; B=chore/dev-cycle-2026-10-12; M="$(git rev-parse main)"
    lc_is "refuse HEAD: it has no commit the default branch lacks, or its history could not be read" --expect "$M"
    rec "Branch: chore/dev-cycle-2026-10-13"
    lc_is "refuse HEAD: the merge adds or changes no cycle record (docs/working/cycles/cycle-YYYY-MM-DD.md) holding the line \"Branch: $B\", so --main-log would read it as other" --expect "$M"
    rec "Branch: $B"; echo x > o.md; git add o.md; lc_is "refuse HEAD: the index holds changes its commit lacks, or could not be read; commit them first" --expect "$M"
    git rm -q --cached o.md; rm o.md
    sed -i '/^Which/a Q-001: [1]' docs/working/questions.md; commit_all answer
    lc_is "refuse docs/working/questions.md: Q-001's heading, Needs or answer lines changed or are gone, and Q-001 is not in --answered" --expect "$M"
    onmain x.md x; N2="$(git rev-parse main)"
    lc_is "refuse HEAD: the default branch is at $N2, not the expected $M; merge it into HEAD, run --cycle-diff again and land with that commit" --expect "$M" --answered Q-001
    git checkout -q -b feat/y; lc_is "refuse HEAD: it is not on a branch chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM" --expect "$N2"; git checkout -q "$B"
    H="$(git rev-parse HEAD)"; T="$(git merge-tree --write-tree main HEAD)"
    bl --land-cycle --expect "$N2" --answered Q-001
    [ "$status" -eq 0 ] && [ "$output" = "landed $B $H $T $(git rev-parse main)" ] && [ "$(git rev-parse main^1 main^2 'main^{tree}')" = "$N2"$'\n'"$H"$'\n'"$T" ] \
        && [ "$(git log -1 --format=%B main)" = "Merge branch '$B'" ] || { show; return 1; }
    bl --main-log "$N2"; [ "$status" -eq 0 ] && [ "${lines[1]}" = "chore $(git rev-parse main) Merge branch '$B'" ] || { show; return 1; }
    # Main checked out in the first worktree: the land fast-forwards it there; HEAD in a linked worktree.
    git checkout -q main; git worktree add -q -b chore/dev-cycle-2026-10-13-0900 "$BATS_TEST_TMPDIR/wt" main; cd "$BATS_TEST_TMPDIR/wt"
    rec "Branch: chore/dev-cycle-2026-10-13-0900"; M="$(git rev-parse main)"; bl --land-cycle --expect "$M"
    [ "$status" -eq 0 ] && [[ "$output" == "landed chore/dev-cycle-2026-10-13-0900 $(git rev-parse HEAD) "* ]] && [ "$(git -C "$R" rev-parse HEAD^1)" = "$M" ] \
        && [ -z "$(git -C "$R" status --porcelain --untracked-files=no)" ] || { show; return 1; }
}

@test "--land-cycle judges the merge, not the index: a rename git pairs into a new questions file carries main's answer, and a conflict refuses (row 753, U4a)" {
    mkdir -p docs/working; printf '%s\n' '# Draft' '### Q-001 · x' "$N OPEN" '' 'Which?' '| **[1] a** | b |' '| **[2] c** | d |' 'Notes.' > docs/working/draft.md
    echo base > x.md; commit_all draft; git checkout -q -b chore/dev-cycle-2026-10-12; git mv docs/working/draft.md docs/working/questions.md; cd_is ok; commit_all move
    rec "Branch: chore/dev-cycle-2026-10-12"; onmain docs/working/draft.md "$(sed 's/OPEN/ANSWERED/; /^Which/a Q-001: [1]' docs/working/questions.md)"
    # --cycle-diff's guard compares the questions files' listings, which neither side has on the base (U3c's confirming pass).
    cd_is ok; git show "$(git merge-tree --write-tree main HEAD):docs/working/questions.md" | grep -qxF 'Q-001: [1]'
    lc_is "refuse docs/working/questions.md: Q-001 is a new entry filed answered (Status ANSWERED or an answer line), and Q-001 is not in --answered" --expect "$(git rev-parse main)"
    git merge -q --no-edit main; echo chore > x.md; commit_all x; onmain x.md main
    lc_is "refuse HEAD: it conflicts with the default branch; merge the default branch into HEAD first" --expect "$(git rev-parse main)"
}
