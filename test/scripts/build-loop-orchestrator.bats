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
    # A plain caller pair passes; a count harden would misread stops every mode (row 276).
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
