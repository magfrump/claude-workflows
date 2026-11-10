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
RULE='no line holding "<!--"; strict UTF-8'

@test "--state prints ok for a clean repository and refuses a shallow or partial clone and an ambiguous default branch, exit 2 (T42, U3b1; brief 2026-11-01-relax-gate-git-state)" {
    state_is ok
    # The owner's own config and state pass: the gate's merge reads none of it.
    for k in core.fsmonitor filter.lfs.clean hook.pre.command merge.conflictStyle; do git config "$k" x; done
    git replace "$(git rev-parse main)" "$(git commit-tree "$(git rev-parse 'main^{tree}')" -m other)"
    printf '* filter=x\n' > .git/info/attributes
    state_is ok
    git config extensions.partialClone origin
    state_is "refuse state extensions.partialclone: set in config, a partial clone, whose missing objects the gate cannot read"; git config --unset extensions.partialClone
    git rev-parse main > .git/shallow; state_is "refuse state shallow: a shallow clone, whose history the gate cannot read whole"; rm .git/shallow
    # default_gate's half, once main is found: both names, and a default branch that names a tag (row 656).
    git branch -q master; state_is "refuse state default-branch: both main and master exist"; git branch -q -D master
    # git's update-ref refuses a branch at a non-commit: write the ref file.
    git tag -a -m t t1 main; git rev-parse t1 > .git/refs/heads/main
    state_is "refuse state default-branch: refs/heads/main names an object that is not a commit"; git rev-parse 't1^{commit}' > .git/refs/heads/main; state_is ok
}

@test "--state refuses a caller's variable that points git at another repository, work tree, index or object store; other variables and config pairs pass (rows 276, 281, 666, U3b1; brief 2026-11-01-relax-gate-git-state)" {
    V="set in the caller's environment, so git can read another repository, work tree, index or object store"
    for v in "GIT_DIR=$PWD/.git" "GIT_WORK_TREE=$PWD" "GIT_INDEX_FILE=$PWD/.git/index" "GIT_OBJECT_DIRECTORY=$PWD/.git/objects" "GIT_COMMON_DIR=$PWD/.git"; do
        run --separate-stderr env "$v" bash "$BL" --state
        [ "$status" -eq 2 ] && [ "$output" = "refuse state ${v%%=*}: $V" ] || { echo "$v"; show; return 1; }
    done
    for v in GIT_REPLACE_REF_BASE=refs/x/ GIT_GRAFT_FILE=/dev/null GIT_SHALLOW_FILE=/dev/null "GIT_ALTERNATE_OBJECT_DIRECTORIES=$PWD/.git/objects"; do
        run --separate-stderr env "$v" bash "$BL" --state
        [ "$status" -eq 0 ] && [ "$output" = ok ] || { echo "$v"; show; return 1; }
    done
    run --separate-stderr env GIT_CONFIG_PARAMETERS="'core.useReplaceRefs'='true' 'merge.x.driver'='true' 'user.name'='caller'" bash "$BL" --state
    [ "$status" -eq 0 ] && [ "$output" = ok ] || { show; return 1; }
    # A plain caller pair passes; a count git_harden would misread stops every mode (row 276).
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller state_is ok
    for c in 010 08 1x " 1"; do
        run --separate-stderr env GIT_CONFIG_COUNT="$c" GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller bash "$BL" --settings
        [ "$status" -eq 1 ] && [ -z "$output" ] && [ "$stderr" = "build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count" ] || { echo "count [$c]"; show; return 1; }
    done
    # Only --state reads the caller's environment: neither --settings nor the gated --check refuses for it.
    run --separate-stderr env GIT_INDEX_FILE="$PWD/.git/index" bash "$BL" --settings; [ "$status" -eq 0 ] || { show; return 1; }
    brief x "Status: open" "Branch: feat/x"; work feat/x
    run --separate-stderr env GIT_INDEX_FILE="$PWD/.git/index" bash "$BL" --check "$B"
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

@test "--marker quotes a body's headings, Needs, Status and answer lines and Q- IDs, and skips only an HTML comment opener or bytes that are not UTF-8 (T32 E2/E3, D11, U3b1; brief 2026-11-02-relax-grammar-and-loop-prompt G31)" {
    marked $'handoff: blocked\n\nplain'
    # The entry grammar an honest loop writes is quoted, not refused: the readers anchor at column 0.
    for l in '**Needs:** you: judgment · **Status:** OPEN' '**Answer:** [1]' '**Status:** ANSWERED' '### Q-001 · x' '## Options' \
        'Q-12 is related' '  > - Q-2: [2]' '1. **answer (recommended):** [1]' '> > **needs:** agent'; do
        tip feat/x "$(printf 'handoff: blocked\n\nfirst\n%s' "$l")"; T="$(git rev-parse feat/x)"
        marker_is "ok $B $T
> first
> $l" || { echo "line: $l"; return 1; }; done
    W="skip $B: a line of its marker's body breaks the marker-body rule ($RULE): line"
    # Kept (H2): an HTML comment opener anywhere (questions.sh finds its index markers anywhere in a line).
    for l in 'see <!-- index:start --> here' '<!-- open'; do
        tip feat/x "$(printf 'handoff: blocked\n\nfirst\n%s' "$l")"; marker_is "$W 2" || { echo "line: $l"; return 1; }; done
    # Not strict UTF-8 as questions.sh check (Python) reads it: a stray byte, a surrogate Perl's own
    # decoder takes, past U+10FFFF (i2 fact-check 7b). Written raw: git commit-tree re-encodes a message.
    for b in '\377' '\355\240\200' '\364\220\200\200'; do
        c="$(printf "tree %s\nparent %s\nauthor t <t@x> 1 +0000\ncommitter t <t@x> 1 +0000\n\nhandoff: blocked\n\nfirst\nbad $b byte\n" \
            "$(git rev-parse 'feat/x^{tree}')" "$(git rev-parse feat/x)" | git hash-object -t commit -w --stdin)"
        git update-ref refs/heads/feat/x "$c"; marker_is "$W 2" || { echo "bytes: $b"; return 1; }; done
}

@test "--marker skips a body FENCE_AWK refuses, raw or quoted, and an empty blocked body (T32, U3b1)" {
    marked $'handoff: blocked\n\nplain\n```\ncode'
    marker_is "skip $B: the code fence opened at line 2 of its marker's body is never closed"
    tip feat/x $'handoff: blocked\n\n  ```\ncode\n```'
    marker_is "skip $B: line 1 of its marker's body is a fence-like line that is not a plain column-0 fence"
    # HTML lines and link-reference-like lines are text (G22): quoted as written.
    tip feat/x $'handoff: blocked\n\nplain\n[a]: https://example.invalid\n<details>\n- [x]: y\n```\n[a]: b\n```'; T="$(git rev-parse feat/x)"
    marker_is "ok $B $T
> plain
> [a]: https://example.invalid
> <details>
> - [x]: y
> \`\`\`
> [a]: b
> \`\`\`"
    for m in $'handoff: blocked\n\n\n  \n' 'handoff: blocked'; do tip feat/x "$m"; marker_is "skip $B: its blocked marker holds no question (the body is empty)"; done
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

@test "--marker skips a tip that is no blocked, stopped or ready marker, and takes one brief; a ready marker's body is quoted, and may be empty (T32, U3b1; brief 2026-11-02-relax-grammar-and-loop-prompt K24)" {
    brief x "Status: open" "Branch: feat/x"
    marker_is "skip $B: the tip of feat/x is not a blocked, stopped or ready marker (absent)"
    work feat/x; marker_is "skip $B: the tip of feat/x is not a blocked, stopped or ready marker (working)"
    tip feat/x 'handoff: ready'; T="$(git rev-parse feat/x)"; marker_is "ok $B $T"
    tip feat/x $'handoff: ready\n\nTentative pick: [1] CSV, by the smaller diff.\n\n## Options\n| **[1] CSV** | one file |'; T="$(git rev-parse feat/x)"
    marker_is "ok $B $T
> Tentative pick: [1] CSV, by the smaller diff.
>
> ## Options
> | **[1] CSV** | one file |"
    # A ready body under the same rule: an HTML comment opener skips it.
    tip feat/x $'handoff: ready\n\nsee <!-- here'
    marker_is "skip $B: a line of its marker's body breaks the marker-body rule ($RULE): line 1"
    tip feat/x 'handoff: sideways'; bl --marker "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "skip $B: the tip of feat/x starts \"handoff:\" but is not a marker: "* ]] || { show; return 1; }
    bl --marker; [ "$status" -eq 1 ] && [[ "$stderr" == "--marker takes one brief path"* ]] || { show; return 1; }
    bl --marker "$B" "$B"; [ "$status" -eq 1 ] || { show; return 1; }
}

@test "a body --marker quoted leaves both questions readers on the orchestrator's own lines (T34 E2, U3b1)" {
    QS="$REPO_ROOT/scripts/questions.sh"
    bash "$QS" init > /dev/null
    # E2: the loop's grammar lines, quoted as --marker quotes a body (it now passes them: G31); the user's answer is [2].
    { printf '\n### Q-120 · export-format\n**Needs:** you: judgment · **Opened:** 2026-10-04 · **Status:** ANSWERED\n\n'
      printf '> %s\n' '**Needs:** you: judgment · **Opened:** 2026-10-04 · **Status:** OPEN' '' '### Q-121 · fake' '## Options' '| Option | x |' '|---|---|' '' '**Answer:** [1]'
      printf '\nQ-120: [2]\n'; } >> docs/working/questions.md
    commit_all questions
    run --separate-stderr bash "$REPO_ROOT/scripts/dev-cycle.sh" --check-answer Q-120
    [ "$output" = "drop Q-120" ] || { show; return 1; }
    # questions.sh reads the orchestrator's ANSWERED (the last Needs line won in E2): archive moves the entry out.
    run --separate-stderr bash "$QS" archive
    [ "$status" -eq 0 ] && grep -q '^### Q-120 ' docs/working/questions-archive.md && ! grep -q '^### Q-120 ' docs/working/questions.md \
        && grep -q '^> ### Q-121 · fake' docs/working/questions-archive.md && ! grep -q 'Q-121' docs/working/questions.md || { show; cat docs/working/questions.md; return 1; }
    run --separate-stderr bash "$QS" next-id; [ "$output" = Q-121 ] || { show; return 1; }
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

# d6.sh (U3b3; U4c, Q-140 [1]; brief 2026-11-05-d6-block-into-image): the file
# itself, with one literal changed, runs in these tests.
# d6_copy OPT: D6, a copy of scripts/d6.sh with D6_OPT set to OPT; a uid-owned
# OPT stands in for the root-owned image, as d6.sh checks presence, not owner.
# d6_setup: main holds this branch's four scripts, and so does a stand-in at $U.
d6_copy() {
    # In its real place beside the scripts, where the stand-in can hold it.
    D6="$BATS_TEST_TMPDIR/d6.bash"; [[ "$1" == /opt/claude-workflows ]] || D6="$1/scripts/d6.sh"
    cp "$REPO_ROOT/scripts/d6.sh" "$D6"
    grep -qxF 'D6_OPT=/opt/claude-workflows' "$D6" && sed -i "s|^D6_OPT=/opt/claude-workflows\$|D6_OPT=$1|" "$D6" && grep -qxF "D6_OPT=$1" "$D6" || return 1
}
opt_copy() { mkdir -p "$1/scripts/lib" && cp "$REPO_ROOT"/scripts/{build-loop,dev-cycle,questions}.sh "$1/scripts/" && cp "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" "$1/scripts/lib/"; }
d6_setup() {
    mkdir -p scripts/lib && cp "$REPO_ROOT"/scripts/{build-loop,dev-cycle,questions}.sh scripts/ && cp "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" scripts/lib/
    commit_all scripts && U="$BATS_TEST_TMPDIR/opt" && opt_copy "$U" && d6_copy "$U"
}
d6() { run --separate-stderr bash "$D6" "$@"; }
# d6_is WANT: d6.sh refused with exactly WANT, exit 2, before running anything.
d6_is() { d6 build-loop.sh --settings; [ "$status" -eq 2 ] && [ "$output" = "$1" ] && { [ -z "$stderr" ] || [[ "$1" == *"could not be read" ]]; } || { echo "want: $1"; show; return 1; }; }
# shim: a git ahead of the real one on PATH that logs each call's config pairs and environment (T26's).
shim() {
    S="$BATS_TEST_TMPDIR/shim"; mkdir -p "$S"
    printf '#!/bin/bash\nl=""; for ((i = 0; i < ${GIT_CONFIG_COUNT:-0}; i++)); do k="GIT_CONFIG_KEY_$i"; v="GIT_CONFIG_VALUE_$i"; l+=" ${!k}=${!v}"; done\necho "$l G=$GIT_CONFIG_GLOBAL P=$GIT_ALLOW_PROTOCOL S=$GIT_CONFIG_NOSYSTEM" >> "%s/calls"\nexec "%s" "$@"\n' "$BATS_TEST_TMPDIR" "$(command -v git)" > "$S/git"
    chmod +x "$S/git"
}

@test "SKILL.md states d6.sh's one-line call once, by absolute path, with no pasted block; d6.sh names no other copy to run: no root test, no read of main's scripts (T33, U4c, brief 2026-11-05-d6-block-into-image)" {
    K="$REPO_ROOT/skills/dev-cycle/SKILL.md"; q=$'\x60'
    [ "$(grep -cxF "  ${q}cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...$q" "$K")" -eq 1 ] || { grep -n 'd6\.sh' "$K"; return 1; }
    ! grep -nE "bash -s -- |<<'D6'|^D6$|byte for byte|D6 block|D6_OPT" "$K" || return 1
    # Where the image copy is comes from one literal, never the environment or the file's own path.
    S="$REPO_ROOT/scripts/d6.sh"
    [ "$(grep -c '^D6_OPT=' "$S")" -eq 1 ] && grep -qxF 'D6_OPT=/opt/claude-workflows' "$S" || return 1
    ! grep -v '^ *#' "$S" | grep -nE 'D6_ROOT|cat-file (blob|--batch)|ls-tree|mktemp|\$HOME|~/|BASH_SOURCE|\$0|dirname' || return 1
    [ ! -e "$REPO_ROOT/test/lib/d6-snippet.bash" ]
}

@test "d6.sh reaches the image with no installer or Dockerfile change: scripts/ is a payload item, and a .sh file is made 0555 (brief 2026-11-05-d6-block-into-image)" {
    C="$REPO_ROOT/devcontainer-config"
    [ -f "$REPO_ROOT/scripts/d6.sh" ] && [ -x "$REPO_ROOT/scripts/d6.sh" ] || return 1
    grep -qE '^CLAUDE_HOME_SRC=\(.* scripts\)$' "$C/install.sh" && grep -qE '^CLAUDE_HOME_SRC=\(.* skills ' "$C/install.sh" || { grep -n '^CLAUDE_HOME_SRC' "$C/install.sh"; return 1; }
    grep -qF "find /opt/claude-workflows -type f \\( -name '*.sh' -o -name '*.py' \\) -exec chmod 0555" "$C/Dockerfile" || return 1
}

@test "the skill's d6 call on an image with no d6.sh (an image older than the skill): exit 127, bash names the path, nothing runs, and the Rules read it as a refusal (brief 2026-11-05-d6-block-into-image)" {
    K="$REPO_ROOT/skills/dev-cycle/SKILL.md"; q=$'\x60'
    l="$(grep -oF "bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG..." "$K" | head -n 1)"
    [ -n "$l" ] || return 1
    U="$BATS_TEST_TMPDIR/opt"; opt_copy "$U"; printf 'touch "%s/ran"\n' "$BATS_TEST_TMPDIR" >> "$U/scripts/build-loop.sh"
    l="${l//\/opt\/claude-workflows/$U}"; l="${l/SCRIPT ARG.../build-loop.sh --settings}"
    read -r -a w <<<"$l"; run -127 --separate-stderr "${w[@]}"
    [ -z "$output" ] && [[ "$stderr" == *"$U/scripts/d6.sh: No such file or directory"* ]] && [ ! -e "$BATS_TEST_TMPDIR/ran" ] || { show; return 1; }
    s="$(tr '\n' ' ' < "$K" | tr -s ' ')"
    for f in "So does exit 127 with ${q}bash${q}'s ${q}No such file or directory${q} line naming d6.sh" "a ${q}refuse d6:${q} line or that exit 127, are stops too" \
        "the exit 127 above means an image older than this skill, and a ${q}refuse d6:${q} naming a missing image file a partial image" "a ${q}refuse d6:${q} line, its exit 127 or a timed-out call is still a stop"; do
        [[ "$s" == *"$f"* ]] || { echo "missing: $f"; return 1; }
    done
}

@test "d6.sh scrubs the caller's variables and closes stdin before it runs the image's script; a caller's stdin never reaches it (R6f, brief 2026-11-05-d6-block-into-image)" {
    d6_setup
    sed -i '2i [[ "${1:-}" != --probe ]] || { echo "live=${QUESTIONS_LIVE-unset} arch=${QUESTIONS_ARCHIVE-unset} watch=${QUESTIONS_WATCHING-unset} scrub=${DEV_CYCLE_SCRUBBED-unset} env=${ENV-unset} benv=${BASH_ENV-unset} in=$(cat)"; exit 7; }' "$U/scripts/questions.sh"
    run --separate-stderr bash -c 'echo piped | QUESTIONS_LIVE=x QUESTIONS_ARCHIVE=x QUESTIONS_WATCHING=x DEV_CYCLE_SCRUBBED=1 ENV=x BASH_ENV=/dev/null bash "$1" questions.sh --probe' _ "$D6"
    [ "$status" -eq 7 ] && [ "$output" = "live=unset arch=unset watch=unset scrub=unset env=unset benv=unset in=" ] || { show; return 1; }
}

@test "d6.sh runs the image copy's scripts by absolute path, with the image's own lib and questions.sh, never main's or the working tree's (T33, U3b3, U4c)" {
    d6_setup
    # main and the working tree each hold scripts that say where they ran; the image copy's lib says where it was sourced from.
    for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do echo 'echo main copy; exit 9' > "scripts/$f"; done
    mkdir -p docs/working && printf '# Questions\n' > docs/working/questions.md && printf '# Archive\n' > docs/working/questions-archive.md
    commit_all "main copies"
    for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do echo 'echo working copy; exit 9' > "scripts/$f"; done
    echo 'echo "lib at ${BASH_SOURCE[0]}" >&2' >> "$U/scripts/lib/dev-cycle-read.sh"
    sed -i '2i [[ "${1:-}" != open ]] || { echo "Q-001  trigger           from-opt"; exit 0; }' "$U/scripts/questions.sh"
    d6 build-loop.sh --settings
    [ "$status" -eq 0 ] && [[ "$output" == *"slots 3 default: "* ]] && [ -n "$stderr" ] || { show; return 1; }
    while IFS= read -r l; do [ "$l" = "lib at $U/scripts/lib/dev-cycle-read.sh" ] || { echo "[$l]"; show; return 1; }; done <<<"$stderr"
    # --state through d6.sh passes.
    d6 build-loop.sh --state; [ "$status" -eq 0 ] && [ "$output" = ok ] || { show; return 1; }
    d6 dev-cycle.sh
    [ "$status" -eq 0 ] && [[ "$output" == *$'\n- Q-001  trigger           from-opt (legacy, in questions.md: step 1b\'s `questions.sh migrate` moves it)\n'* ]] || { show; return 1; }
    d6 questions.sh open; [ "$status" -eq 0 ] && [ "$output" = "Q-001  trigger           from-opt" ] || { show; return 1; }
}

@test "d6.sh refuses before running anything: not exactly one of main and master, a repository git cannot read, an image file missing or not a regular file, a lib that does not load, another first argument (T36, U3b3, brief 2026-11-05-d6-block-into-image)" {
    d6_setup
    git branch -q master; d6_is "refuse d6: the default branch is not exactly one of main and master"; git branch -q -D master
    git branch -q -m main trunk; d6_is "refuse d6: the default branch is not exactly one of main and master"; git branch -q -m trunk main
    d6 build-loop.sh --settings; [ "$status" -eq 0 ] || { show; return 1; }
    N="$BATS_TEST_TMPDIR/not-a-repo"; mkdir "$N"
    cd "$N"; GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR" d6_is "refuse d6: refs/heads/main could not be read"; cd - >/dev/null
    rm "$U/scripts/questions.sh"; d6_is "refuse d6: $U/scripts/questions.sh is missing"; cp "$REPO_ROOT/scripts/questions.sh" "$U/scripts/"
    mv "$U/scripts/lib/dev-cycle-read.sh" "$U/x"; mkdir "$U/scripts/lib/dev-cycle-read.sh"; d6_is "refuse d6: $U/scripts/lib/dev-cycle-read.sh is not a regular file"
    rmdir "$U/scripts/lib/dev-cycle-read.sh"; ln -s "$U/gone" "$U/scripts/lib/dev-cycle-read.sh"; d6_is "refuse d6: $U/scripts/lib/dev-cycle-read.sh is not a regular file"
    rm "$U/scripts/lib/dev-cycle-read.sh"; ln -s "$U/x" "$U/scripts/lib/dev-cycle-read.sh"; d6_is "refuse d6: $U/scripts/lib/dev-cycle-read.sh is not a regular file"
    rm "$U/scripts/lib/dev-cycle-read.sh"; mv "$U/x" "$U/scripts/lib/dev-cycle-read.sh"
    # A lib that does not load, or a git_harden that refuses, is named as that, never as an absent branch.
    L="refuse d6: $U/scripts/lib/dev-cycle-read.sh did not load, or its git_harden refused this environment"
    cp "$U/scripts/lib/dev-cycle-read.sh" "$U/keep"; echo 'return 1' >> "$U/scripts/lib/dev-cycle-read.sh"; d6_is "$L"; cp "$U/keep" "$U/scripts/lib/dev-cycle-read.sh"
    GIT_CONFIG_COUNT=010 d6 build-loop.sh --settings; [ "$status" -eq 2 ] && [ "$output" = "$L" ] || { show; return 1; }
    run --separate-stderr bash "$D6" x; [ "$status" -eq 1 ] && [ -z "$output" ] && [ "$stderr" = "d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh" ] || { show; return 1; }
    run --separate-stderr bash "$D6"; [ "$status" -eq 1 ] && [ -z "$output" ] || { show; return 1; }
}

@test "d6.sh runs the script past what audit rows R6c to R6e dropped: a replace ref, info/grafts, a symbolic or tag default branch, a uid-owned image; --state still refuses the two default-branch shapes (brief 2026-11-05-d6-block-into-image)" {
    d6_setup
    # A replace ref: no refusal, and the image's script runs.
    id="$(git rev-parse main:scripts/build-loop.sh)"; git replace "$id" "$(printf 'echo replaced\n' | git hash-object -w --stdin)"
    d6 build-loop.sh --settings; [ "$status" -eq 0 ] || { show; return 1; }
    git replace -d "$id"
    git rev-parse main > .git/info/grafts; d6 build-loop.sh --settings; [ "$status" -eq 0 ] || { show; return 1; }; rm .git/info/grafts
    c="$(git rev-parse main)"
    git branch -q feat/y; git symbolic-ref refs/heads/main refs/heads/feat/y
    d6 build-loop.sh --state; [ "$status" -eq 2 ] && [[ "$output" == *"refuse state default-branch: refs/heads/main is a symbolic ref"* ]] || { show; return 1; }
    # git refuses to update-ref a branch to a tag: write the ref file (row 656's case).
    git update-ref --no-deref refs/heads/main "$c"; git tag -a -m t t1 main; git rev-parse t1 > .git/refs/heads/main
    d6 build-loop.sh --state; [ "$status" -eq 2 ] && [[ "$output" == *"refuse state default-branch: refs/heads/main names an object that is not a commit"* ]] || { show; return 1; }
    echo "$c" > .git/refs/heads/main
}

@test "d6.sh's own git is hardened by the image lib's git_harden, and no pair reaches the script (T26, brief 2026-11-05-d6-block-into-image)" {
    d6_setup; shim
    sed -i '2i [[ "${1:-}" != --probe ]] || { echo "count=${GIT_CONFIG_COUNT-unset}"; exit 7; }' "$U/scripts/questions.sh"
    PATH="$S:$PATH" d6 questions.sh --probe
    [ "$status" -eq 7 ] && [ "$output" = "count=unset" ] || { show; return 1; }
    [ "$(wc -l < "$BATS_TEST_TMPDIR/calls")" -eq 2 ] || { cat "$BATS_TEST_TMPDIR/calls"; return 1; }
    while IFS= read -r l; do
        for w in core.hooksPath=/dev/null core.fsmonitor=false core.useReplaceRefs=false G=/dev/null P=none S=1; do [[ "$l" == *"$w"* ]] || { echo "missing $w: $l"; return 1; }; done
    done < "$BATS_TEST_TMPDIR/calls"
}

@test "a gate copy patched in the loop's worktree prints ok for its tip; d6.sh's image copy refuses the same tip (T27, U3b3)" {
    d6_setup; brief x "Status: open" "Branch: feat/x"
    W="$BATS_TEST_TMPDIR/wt"; git worktree add -q -b feat/x "$W" main; cd "$W"
    # The loop drops the path rule from its own copy and adds a file whose name holds a tab.
    sed -i 's/&& ! anyform "\$7"; then/\&\& false; then/' scripts/build-loop.sh; grep -q '&& false; then' scripts/build-loop.sh
    : > "$(printf 'a\tb')"; commit_all loop
    run --separate-stderr bash scripts/build-loop.sh --check "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "ok $B "* ]] || { show; return 1; }
    d6 build-loop.sh --check "$B"
    [ "$status" -eq 2 ] && [[ "$output" == "refuse $B: 1 of 2 changed paths refused in the merge of $(git rev-parse feat/x) "* ]] \
        && [[ "$output" == *$'\n'"deny $B A ?: not a path a checkout can hold "* ]] || { show; return 1; }
}

@test "d6.sh runs the root-owned image copy at /opt by absolute path, not main's copy (T37, U3b3)" {
    O=/opt/claude-workflows
    [[ -f "$O/scripts/build-loop.sh" && "$(stat -c %u "$O/scripts")" == 0 ]] || skip "no root-owned image copy at $O here"
    mkdir -p scripts; printf 'echo main copy\n' > scripts/build-loop.sh; commit_all scripts
    d6_copy "$O"; [[ ! -f "$O/scripts/d6.sh" ]] || D6="$O/scripts/d6.sh"; d6 build-loop.sh --help
    [ "$status" -eq 0 ] && [ "$output" = "$(bash "$O/scripts/build-loop.sh" --help)" ] || { show; return 1; }
}

@test "d6.sh refuses an image copy missing a file (a partial image), and never runs main's (T37, U3b3, U4c)" {
    mkdir -p scripts; printf 'echo main copy\n' > scripts/build-loop.sh; commit_all scripts
    U="$BATS_TEST_TMPDIR/opt"; opt_copy "$U"; d6_copy "$U"
    rm "$U/scripts/build-loop.sh"; d6_is "refuse d6: $U/scripts/build-loop.sh is missing"
}

@test "git_harden exports HARDEN's pairs after the caller's and a fixed environment, once however often it is called (rows 281, 311, 495, 704, 736, U3b3, U4b1)" {
    L="$REPO_ROOT/scripts/lib/dev-cycle-read.sh"
    run env -i PATH="$PATH" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=c bash -c 'source "$1"; git_harden; git_harden; echo "caller $CALLER_COUNT"; printf "pair %s\n" "${HARDEN[@]}"; env | grep "^GIT_" | sort' _ "$L"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    H="core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null log.date=default log.showSignature=false commit.gpgSign=false"
    E="GIT_ALLOW_PROTOCOL=none GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0"
    want="caller 1"; for kv in $H; do want+=$'\n'"pair $kv"; done
    k=0; keys="GIT_CONFIG_KEY_0=user.name"; vals="GIT_CONFIG_VALUE_0=c"
    for kv in $H; do k=$((k + 1)); keys+=$'\n'"GIT_CONFIG_KEY_$k=${kv%%=*}"; vals+=$'\n'"GIT_CONFIG_VALUE_$k=${kv#*=}"; done
    want+=$'\n'"$(printf '%s\n' $E "GIT_CONFIG_COUNT=8" "$keys" "$vals" | LC_ALL=C sort)"
    [ "$output" = "$want" ] || { diff <(echo "$want") <(echo "$output"); return 1; }
    # d6.sh repeats neither list: it runs the lib's git_harden (its own test above).
    ! grep -nE '^[^#]*(GIT_NO_REPLACE_OBJECTS|core\.hooksPath)' "$REPO_ROOT/scripts/d6.sh" || return 1
}

@test "the first trial set's practices stay in SKILL.md at the steps that write them (brief 2026-11-06-codify-trial-practices)" {
    K="$REPO_ROOT/skills/dev-cycle/SKILL.md"; q=$'\x60'
    # sect HEADING: that section, joined to one line, as the wrapped prose reads.
    sect() { awk -v h="$1" '$0 == h { on = 1; next } on && /^### / { exit } on' "$K" | tr '\n' ' ' | tr -s ' '; }
    want() { [[ "$1" == *"$2"* ]] || { echo "missing: $2"; return 1; }; }
    s="$(tr '\n' ' ' < "$K" | tr -s ' ')"
    # T1: notes, not the commit list; the unreviewed part and the paths stay whole, as docs/dev-cycle.md relies on.
    a="$(sect '### 0. Start and digest')"
    for f in "never from the old entry's text" "**Merged without your review:** every line of THE LOG" "**What changes for you:**" "as a count" \
        "every path changed from C to M outside ${q}docs/${q} on one line" "and the one paste"; do want "$a" "$f" || return 1; done
    # T2: the jargon half is the global rule, pointed at and not restated; the attacker line never names the author.
    want "$s" "with a line ${q}**If you say no:** WHAT${q}" || return 1
    a="$(sect '### 7. Collect')"
    for f in "${q}**What an attacker would want here:** WHAT${q}" "naming outside parties only" "never the code's own author"; do want "$a" "$f" || return 1; done
    # T3: a batch counts with IDs or a block, and an option; "yes" never does. Step 9's record template holds ### lines, so sect stops short of this rule.
    for f in "or is a batched answer: an unconditional instruction with an option" "own last final message listed" "The batch answers only merge entries that block listed, never a later one" "never text that message quotes" 'never inferred from "yes"'; do want "$s" "$f" || return 1; done
    # T4 and T5: the digest's path and sections, at step 9's head; the cycle never closes an owner's entry.
    a="$(sect '### 9. Record and land')"
    for f in "${q}docs/working/weekly/${q} holds no ${q}YYYY-MM-DD.md${q} dated under 7 days" "(none yet: the last 7 days)" "entries and agent items quoting ${q}refuse state${q}" "the ask counter" "open 21 days or more" "only the owner's answer closes it" "one self-merge picked at random"; do
        want "$a" "$f" || return 1; done
    # T6: reserved to three triggers, ahead of everything. T7: a bug, in step 1.
    for f in "${q}⚠ SECURITY${q} is reserved: it opens the message" "for only three things" "a High finding from a security review" "A refusal that repeats fires once" "It is never used for anything else"; do want "$s" "$f" || return 1; done
    want "$(sect '### 1. Health and cleanup')" "A warning printed on every run" || return 1
    # Nothing leans on the trial doc, which a new set replaces.
    ! grep -n 'friction-engagement' "$K"
}

@test "SKILL.md's orchestrator runs plain git, with no hg wrapper, identity ritual, --state re-runs, pre-write --check-write, tree-equality check or main-log refuse stop (brief 2026-11-01-relax-dev-cycle-skill-prose)" {
    K="$REPO_ROOT/skills/dev-cycle/SKILL.md"
    # The removed rituals stay removed.
    ! grep -nE '(^|[^a-z])hg( |\(\))|GIT_AUTHOR_NAME|write-tree|HEAD\^\{tree\}|main-log-refused-|refuse stop|--check-write' "$K" || return 1
    # The orchestrator's git keeps the honest-slip pins: literal pathspecs for path commands, no signing for commits.
    grep -qF 'git --literal-pathspecs -C PATH add -- FILE' "$K" && grep -qF -- '-c commit.gpgSign=false commit -q --no-verify -F' "$K" || return 1
    # Merging main in keeps rerere off, the default strategy and abort on conflict.
    grep -qF -- '-c rerere.enabled=false -c commit.gpgSign=false merge' "$K" && grep -qF 'no `-s` or' "$K" && grep -qF 'merge --abort`, then a stop' "$K" || return 1
    # --state runs once, at step 0.1: not before GT's add, the chore commit or the merge of main into WT.
    ! grep -nE '`--state` \(from MAIN_WT|`--state` first|`--state` \(the Rules' "$K" || return 1
    # R39: a main-log refusal is a report that re-anchors, not a stop; R26: a checked branch may reach git as a full ref.
    grep -qF 'is a report, not a stop' "$K" && grep -qF 'may reach git as the full ref `refs/heads/<name>`' "$K" || return 1
    # --force only where the edits are meant to be discarded: a stopped WT and a stopped or crashed HC.
    [ "$(grep -c -- '--force' "$K")" -eq 2 ] || { grep -n -- '--force' "$K"; return 1; }
}

@test "SKILL.md step 0.1's image-lag paths are GATE_CODE's, on one line of their own: a GATE_CODE change fails here until this test's literal is updated, and a listed path that is not gate code fails (U4c i2 architecture 1)" {
    g="$(bash -c 'source "$1"; printf %s "$GATE_CODE"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh")"
    P="scripts/build-loop.sh scripts/d6.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/"
    [ "$g" = '^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/' ] || { echo "GATE_CODE changed: update step 0.1's PATHS line and this test: $g"; return 1; }
    q=$'\x60'
    [ "$(grep -cxF "   $q$P$q" "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ] || { grep -n 'scripts/build-loop.sh scripts/' "$REPO_ROOT/skills/dev-cycle/SKILL.md"; return 1; }
    for p in $P; do [[ "$p" =~ $g || "${p}x" =~ $g ]] || { echo "not GATE_CODE: $p"; return 1; }; done
}

@test "SKILL.md's identity check asks git var under user.useConfigOnly, as the gate's merge does: an identity from git config or from the environment passes, none is a stop (brief 2026-11-10-dev-cycle-skill-held-fixes)" {
    K="$REPO_ROOT/skills/dev-cycle/SKILL.md"; q=$'\x60'
    c="git -C WT -c user.useConfigOnly=true var GIT_AUTHOR_IDENT"
    s="$(tr '\n' ' ' < "$K" | tr -s ' ')"
    [[ "$s" == *"$q$c$q and the same for ${q}GIT_COMMITTER_IDENT$q must each exit 0 and print one"* ]] || { grep -n 'IDENT\|user\.email' "$K"; return 1; }
    # The config-only read is gone: it printed nothing for an identity the environment holds.
    ! grep -nE 'config user\.(email|name)' "$K" || return 1
    # ident PREFIX...: the skill's command for both roles, on this fixture's repository, run under PREFIX.
    read -r -a w <<<"${c/ WT / $R }"
    ident() { local r; for r in AUTHOR COMMITTER; do "$@" "${w[@]/GIT_AUTHOR_IDENT/GIT_${r}_IDENT}" || return 1; done; }
    none=(env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL -u EMAIL)
    # Neither source: a stop, where plain git would take EMAIL or make an identity up from the account and host.
    run --separate-stderr ident "${none[@]}"; [ "$status" -ne 0 ] && [ -z "$output" ] && [[ "$stderr" == *"auto-detection is disabled"* ]] || { show; return 1; }
    run --separate-stderr ident "${none[@]}" EMAIL=e@example.invalid; [ "$status" -ne 0 ] && [ -z "$output" ] || { show; return 1; }
    # An author with no committer: the second call stops it.
    run --separate-stderr ident "${none[@]}" GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@example.invalid
    [ "$status" -ne 0 ] && [ "${#lines[@]}" -eq 1 ] && [[ "${lines[0]}" == "a <a@example.invalid> "* ]] || { show; return 1; }
    # The environment's identity (bl_setup's), with no user.* in any config: the case the old read reported as none.
    [ -z "$(git config user.email)" ] || return 1
    run --separate-stderr ident env; [ "$status" -eq 0 ] && [[ "${lines[0]}" == "t <t@example.invalid> "* && "${lines[1]}" == "t <t@example.invalid> "* ]] || { show; return 1; }
    # Git config's identity, with nothing in the environment.
    git config user.name c; git config user.email c@example.invalid
    run --separate-stderr ident "${none[@]}"; [ "$status" -eq 0 ] && [[ "${lines[0]}" == "c <c@example.invalid> "* && "${lines[1]}" == "c <c@example.invalid> "* ]] || { show; return 1; }
}

@test "SKILL.md step 0.1's release paste runs the installer from a checkout at main's tip and refuses, before the installer and saying why, a checkout off the tip, gate code that is not M's and a read that fails; its only git command, rev-parse in a command substitution, runs no planted hook or fsmonitor (brief 2026-11-10-dev-cycle-skill-held-fixes)" {
    K="$REPO_ROOT/skills/dev-cycle/SKILL.md"; q=$'\x60'
    # Step 0.1's PATHS line (the test above holds it to GATE_CODE) and the paste, each alone on its line.
    P="$(grep -xE "   ${q}scripts/build-loop\.sh [^$q]*$q" "$K" || true)"; P="${P#"   $q"}"; P="${P%"$q"}"
    t="$(grep -xE "   ${q}cd A && \(.*\) && \./devcontainer-config/install\.sh$q" "$K" || true)"
    [ -n "$P" ] && [ "$(grep -c . <<<"$t")" -eq 1 ] || { echo "PATHS: $P"; grep -n 'install\.sh' "$K"; return 1; }
    t="${t#"   $q"}"; t="${t%"$q"}"
    # Every git call is rev-parse inside $( ): it reads no index, moves no ref, and has no terminal to page to.
    [ "$(grep -o 'git ' <<<"$t" | grep -c .)" -eq "$(grep -oF '$(git rev-parse ' <<<"$t" | grep -c .)" ] || { echo "$t"; return 1; }
    # A PATHS entry this repository lacks would make the paste refuse every release.
    for p in $P; do [ -e "$REPO_ROOT/$p" ] || { echo "PATHS names nothing here: $p"; return 1; }; done
    # The paste with its placeholders made arguments: $1 for A, $2 for M, PATHS written out.
    c="$t"; sub() { [[ "$c" == *"$1"* ]] || { echo "the paste lacks: $1"; return 1; }; c="${c//"$1"/"$2"}"; }
    sub 'cd A ' 'cd "$1" ' && sub 'for p in PATHS;' "for p in $P;" && sub '"M:$p"' '"$2:$p"' && sub 'as at M;' 'as at $2;' || return 1
    # The fixture: the gate-code paths, a stub installer that records its run, and one docs file; M is that commit.
    I="$BATS_TEST_TMPDIR/installed"; mkdir -p docs devcontainer-config
    for p in $P; do if [[ "$p" == */ ]]; then mkdir -p "$p" && echo a > "${p}x"; else mkdir -p "${p%/*}" && echo a > "$p"; fi; done
    printf '#!/bin/sh\necho ran >> "%s"\n' "$I" > devcontainer-config/install.sh; chmod +x devcontainer-config/install.sh
    echo d > docs/d.md; commit_all gate; M="$(git rev-parse HEAD)"
    # both DIR SHA CHECK...: the paste under bash, and under zsh where there is one (the owner's shell may be either), then CHECK.
    shs=(bash); ! command -v zsh > /dev/null || shs+=(zsh)
    both() { local sh; for sh in "${shs[@]}"; do rm -f "$I"; run --separate-stderr "$sh" -c "$c" paste "$1" "$2"; "${@:3}" || { echo "under $sh"; show; return 1; }; done; }
    ran() { [ "$status" -eq 0 ] && [ -z "$output" ] && [ "$(cat "$I")" = ran ]; }
    nope() { [ "$status" -eq 1 ] && [ "$output" = "release refused: $1" ] && [ ! -e "$I" ]; }
    both "$R" "$M" ran
    # Main's tip, moved past M by a commit that holds no gate code, as every cycle land does.
    echo e > docs/d.md; commit_all land; both "$R" "$M" ran
    # Off main's tip: a branch left checked out, and a checkout still at M.
    git checkout -q -b feat; echo x > other.txt; commit_all work; both "$R" "$M" nope "this checkout is not at main's tip"
    git checkout -q --detach "$M"; both "$R" "$M" nope "this checkout is not at main's tip"
    # Main's tip with gate code the entry did not describe.
    git checkout -q main; echo b > scripts/lib/x; commit_all "gate code"
    both "$R" "$M" nope "scripts/lib/ is not as at $M; the next dev-cycle iteration rewrites this paste"
    # Reads that fail refuse: a gate file gone, an M this clone lacks, a directory that is no repository.
    git rm -q scripts/d6.sh; commit_all gone; both "$R" "$M" nope "scripts/d6.sh is not as at $M; the next dev-cycle iteration rewrites this paste"
    git reset -q --hard HEAD~2
    z=0123456789012345678901234567890123456789; both "$R" "$z" nope "scripts/build-loop.sh is not as at $z; the next dev-cycle iteration rewrites this paste"
    mkdir -p "$BATS_TEST_TMPDIR/plain" && cp -r devcontainer-config "$BATS_TEST_TMPDIR/plain/"
    export GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR"; both "$BATS_TEST_TMPDIR/plain" "$M" nope "this checkout is not at main's tip"; unset GIT_CEILING_DIRECTORIES
    # Planted state, as a sandbox session could leave in the host checkout's .git: the paste runs none of it. The same
    # state is live: git status starts the fsmonitor, and a checkout (what the pinned paste asked for) runs the hooks.
    F="$BATS_TEST_TMPDIR/fired"; H="$BATS_TEST_TMPDIR/planted"; mkdir -p "$H"
    for h in post-checkout reference-transaction post-index-change fsmonitor; do printf '#!/bin/sh\necho %s >> "%s"\n' "$h" "$F" > "$H/$h"; chmod +x "$H/$h"; done
    git config core.hooksPath "$H"; git config core.fsmonitor "$H/fsmonitor"
    both "$R" "$M" ran; [ ! -e "$F" ] || { echo "the paste ran:"; sort -u "$F"; return 1; }
    git status --porcelain > /dev/null 2>&1; git checkout -q --detach "$M" 2> /dev/null
    grep -qx fsmonitor "$F" && grep -qx post-checkout "$F" || { echo "the planted state never ran:"; cat "$F"; return 1; }
}

@test "SKILL.md says where the release paste runs and what it refuses, reruns the image check after a step 7 merge, and asks for a free slot's reason in step 8 and on the record's line 8 (brief 2026-11-10-dev-cycle-skill-held-fixes)" {
    K="$REPO_ROOT/skills/dev-cycle/SKILL.md"; q=$'\x60'
    sect() { awk -v h="$1" '$0 == h { on = 1; next } on && /^### / { exit } on' "$K" | tr '\n' ' ' | tr -s ' '; }
    a="$(sect '### 0. Start and digest')"
    for f in "which refuses until the host checkout is at main's tip" "It runs from a checkout at main's tip" \
        "A step 7 merge moves main: run the ${q}diff --quiet$q check again with main's new commit as M" \
        "is ${q}rev-parse$q inside ${q}\$( )$q, which runs no hook, fsmonitor or pager" "a checkout to reach main's tip included"; do
        [[ "$a" == *"$f"* ]] || { echo "missing: $f"; return 1; }
    done
    # The pin on M is gone: the cycle's own land moves main past M, so a paste that tested for M never passed there.
    [[ "$a" != *'= M &&'* && "$a" != *"checkout is at M)"* && "$a" != *"a checkout to reach M included"* ]] || { echo "the paste still pins M"; return 1; }
    # One clause, in the step that leaves the slot free and on the line that records it.
    [[ "$(sect '### 8. Build briefs')" == *"why each free slot stayed free"* ]] || { echo "step 8 is silent"; return 1; }
    grep -qxF '8. briefs: <written this iteration, or none>; queue <k>/<slots> (<full: no new briefs / under: why each free slot stayed free>)' "$K"
}

@test "SKILL.md step 1 runs the health check from HC, a detached checkout of WT's commit that it removes, not from WT, which the iteration edits while the check runs (brief 2026-10-30-health-check-clean-checkout)" {
    s="$(awk '/^### 1\. Health and cleanup$/ { on = 1; next } on && /^### / { exit } on' "$REPO_ROOT/skills/dev-cycle/SKILL.md" | tr '\n' ' ' | tr -s ' ')"
    [ -n "$s" ] || { echo "step 1 not found"; return 1; }
    q=$'\x60'
    for f in "It runs from a health checkout HC, not WT" "${q}git -C MAIN_WT worktree add --detach HC W${q}, W being WT's HEAD commit" \
        "${q}.claude/wt-dev-cycle-health-DATE-HHMM${q}" "removed as step 0.3 removes WT once the check exits" "${q}skipped: HC not made${q}"; do
        [[ "$s" == *"$f"* ]] || { echo "missing: $f"; echo "$s"; return 1; }
    done
    [[ "$s" != *"health check from WT"* ]] || { echo "$s"; return 1; }
}

@test "SKILL.md's merge-entry slug rule quotes the lib's GATE_CODE, which --approved's heading reads, on one line of its own (row 674, U4b2)" {
    g="$(bash -c 'source "$1"; printf %s "$GATE_CODE"' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh")"
    [[ "$g" == *dev-cycle/* ]] || { echo "GATE_CODE: $g"; return 1; }
    q=$'\x60'
    [ "$(grep -cxF "  $q$g$q" "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ] || { grep -n 'scripts/lib/' "$REPO_ROOT/skills/dev-cycle/SKILL.md"; return 1; }
    # A path line's mode suffix is not part of PATH, or a gate-code symlink would get merge- (brief 2026-11-02-relax-grammar-and-loop-prompt, review i2).
    grep -qF "line's PATH (without a trailing $q (symlink)$q or" "$REPO_ROOT/skills/dev-cycle/SKILL.md" || return 1
    # Step 10 also names the dispatch cap and the steal age (i2 architecture 8).
    c="$(grep -o '^DISPATCH_CAP=[0-9]*; STEAL_AGE=[0-9]*$' "$REPO_ROOT/scripts/build-loop.sh")"
    [[ "$c" =~ ^DISPATCH_CAP=([0-9]+)\;\ STEAL_AGE=([0-9]+)$ ]] || { echo "$c"; return 1; }
    cap="${BASH_REMATCH[1]}"; h=$(( BASH_REMATCH[2] / 3600 ))
    grep -qF "with DISPATCHED $cap (the cap" "$REPO_ROOT/skills/dev-cycle/SKILL.md" && grep -qF "\"under $h hours old\"" "$REPO_ROOT/skills/dev-cycle/SKILL.md"
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

@test "a you: fyi acknowledged seen: --cycle-diff takes it only with --answered, --main-log reads it as answers, and a range line as other (decision 040)" {
    F='**Needs:** you: fyi · **Opened:** 2026-10-28 · **Status:**'
    mkdir -p docs/working
    printf '%s\n' '# Questions' '### Q-001 · read-this' "$F OPEN" '' 'Read this.' '### Q-002 · and-this' "$F OPEN" '' 'And this.' > docs/working/questions.md
    printf '%s\n' '# Archive' > docs/working/questions-archive.md; commit_all questions; S="$(git rev-parse main)"
    git checkout -q -b chore/dev-cycle-2026-10-28
    W="refuse docs/working/questions.md: Q-001's heading, Needs or answer lines changed or are gone, and Q-001 is not in --answered"
    # Recorded one line per entry: the anti-forgery rule holds for an fyi as for any route.
    sed -i '0,/\*\*Status:\*\* OPEN/s//**Status:** ANSWERED/' docs/working/questions.md; sed -i '/^Read this/a Q-001: seen' docs/working/questions.md
    git add -A; cd_is "$W"; cd_is ok --answered Q-001
    # The bold label form, the same.
    git reset -q --hard; sed -i '0,/\*\*Status:\*\* OPEN/s//**Status:** ANSWERED/' docs/working/questions.md; sed -i '/^Read this/a **Answer:** seen' docs/working/questions.md
    git add -A; cd_is "$W"; cd_is ok --answered Q-001
    # The owner's batch pasted as a range: the Status flip alone still refuses.
    git reset -q --hard; sed -i 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/' docs/working/questions.md
    sed -i '/^Read this/a Q-001\xe2\x80\x93Q-002: seen' docs/working/questions.md; grep -qx $'Q-001–Q-002: seen' docs/working/questions.md; git add -A
    cd_is "$W
${W//Q-001/Q-002}"
    cd_is ok --answered Q-001 --answered Q-002
    # On main: a per-entry seen line is the answers class; a range line is not an answer line, so other.
    git reset -q --hard; git checkout -q main
    sed -i '0,/\*\*Status:\*\* OPEN/s//**Status:** ANSWERED/' docs/working/questions.md; sed -i '/^Read this/a Q-001: seen' docs/working/questions.md
    commit_all seen; A="$(git rev-parse main)"
    sed -i '/^Q-001: seen/a **Answer:** seen' docs/working/questions.md; commit_all bold; B2="$(git rev-parse main)"
    sed -i 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/' docs/working/questions.md; sed -i '/^And this/a Q-002\xe2\x80\x93Q-003: seen' docs/working/questions.md
    grep -qx $'Q-002–Q-003: seen' docs/working/questions.md; commit_all range; R="$(git rev-parse main)"
    ml "$S" 2 "main $R 3
answers $A seen
answers $B2 bold
other $R range"
}

@test "--cycle-diff lets the cycle close its own watch in watching.md, refuses a watch dropped and an owner entry moved there (decision 040 unit 3)" {
    T='**Needs:** trigger · **Opened:** 2026-10-30 · **Status:**'
    qa; git checkout -q main; mkdir -p docs/working
    printf '%s\n' '# Watching' '## Open' '' '### Q-010 · w' "$T OPEN" '' 'Watch for x.' '' '### Q-011 · v' "$T OPEN" '' 'Watch for y.' '' '## Closed' > docs/working/watching.md
    commit_all watching; git checkout -q chore/dev-cycle-2026-10-12; git merge -q --ff-only main
    # Closed by the cycle: Status flipped, an observation line, moved under ## Closed; no --answered needed.
    sed -i '/^### Q-010/,/^Watch for x\./d' docs/working/watching.md
    printf '%s\n' '### Q-010 · w' "$T ANSWERED" '' 'Watch for x.' 'Q-010: met, seen in run 12' >> docs/working/watching.md; git add -A; cd_is ok
    # A new watch filed, and one filed closed, pass too: the file is the cycle's own.
    printf '%s\n' '### Q-012 · u' "$T ANSWERED" >> docs/working/watching.md; git add -A; cd_is ok
    # A watch dropped, or its heading renamed, refuses; so does deleting the file.
    git reset -q --hard; sed -i '/^### Q-011/,/^Watch for y\./d; s/^### Q-010 · w$/### Q-010 · renamed/' docs/working/watching.md; git add -A
    cd_is "refuse docs/working/watching.md: Q-010's heading changed or is gone; a watch closes by moving under ## Closed, never by deletion
refuse docs/working/watching.md: Q-011's heading changed or is gone; a watch closes by moving under ## Closed, never by deletion"
    git reset -q --hard; git rm -q docs/working/watching.md; cd_is "refuse docs/working/watching.md: it is deleted"
    # An owner entry moved out of questions.md into watching.md is still an owner entry gone.
    git reset -q --hard; sed -n '/^### Q-001/,/^| \*\*\[1\]/p' docs/working/questions.md >> docs/working/watching.md
    sed -i '/^### Q-001/,/^| \*\*\[1\]/d' docs/working/questions.md; git add -A
    cd_is "refuse docs/working/questions.md: Q-001's heading, Needs or answer lines changed or are gone, and Q-001 is not in --answered"
}

# legacy: the questions files questions.sh init writes, plus an owner entry (Q-001) and three legacy
# routes registry line questions-owner-routes-040 matches (Q-002 an open watch, Q-003 a closed one with
# its answer, Q-004 agent work), on main; then a chore branch. GONE ID: the gone refusal for ID.
legacy() {
    QS="$REPO_ROOT/scripts/questions.sh"; local o='**Opened:** 2026-10-12 · **Status:**'
    bash "$QS" init > /dev/null
    printf '%s\n' '' '### Q-001 · own' "**Needs:** you: judgment · $o OPEN" '' 'Which?' '' '### Q-002 · old-watch' "**Needs:** trigger · $o OPEN" '' 'Watch x.' \
        '' '### Q-003 · done-watch' "**Needs:** deferred · $o ANSWERED" '' 'Q-003: met, seen in run 4' '' '### Q-004 · chore' "**Needs:** agent · $o OPEN" '' 'Do y.' >> docs/working/questions.md
    bash "$QS" index > /dev/null; commit_all questions; git checkout -q -b chore/dev-cycle-2026-10-12
}
GONE() { echo "refuse docs/working/questions.md: $1's heading, Needs or answer lines changed or are gone, and $1 is not in --answered"; }
MIG=questions-owner-routes-040

@test "--cycle-diff --migrated takes a registry remedy's own output: questions.sh migrate's moves to watching.md and the roadmap listing land, and --land-cycle lands them (brief 2026-11-02-cycle-runs-migrations)" {
    legacy; bash "$QS" migrate > /dev/null; git add -A
    grep -q '^### Q-002' docs/working/watching.md && grep -q '^### Q-004' docs/working/roadmap-from-questions.md && ! grep -q '^### Q-00[234]' docs/working/questions.md
    # Without the mode the moves are entries gone; with it they pass, a repeat ID too.
    cd_is "$(GONE Q-002)
$(GONE Q-003)
$(GONE Q-004)"
    cd_is ok --migrated "$MIG"; cd_is ok --migrated "$MIG" --migrated "$MIG" --answered Q-009
    # The owner entry, which no pattern matched, keeps the ordinary rule.
    sed -i 's/^### Q-001 · own$/### Q-001 · renamed/' docs/working/questions.md; git add -A; cd_is "$(GONE Q-001)" --migrated "$MIG"
    git checkout -q HEAD -- docs/working/questions.md; bash "$QS" migrate > /dev/null; git add -A
    # The land judges the merge with the same mode.
    commit_all migrate; rec "Branch: chore/dev-cycle-2026-10-12"; M="$(git rev-parse main)"
    lc_is "$(GONE Q-002)
$(GONE Q-003)
$(GONE Q-004)" --main "$M"
    bl --land-cycle --main "$M" --migrated "$MIG"
    [ "$status" -eq 0 ] && [[ "$output" == "landed chore/dev-cycle-2026-10-12 "* ]] && git show main:docs/working/watching.md | grep -q '^Q-003: met, seen in run 4$' || { show; return 1; }
    for a in "--migrated" "--migrated Bad" "--migrated -x"; do bl --cycle-diff $a; [ "$status" -eq 1 ] && [ -z "$output" ] || { echo "[$a]"; show; return 1; }; done
}

@test "--cycle-diff --migrated refuses a remedy run that also changes an answer or Status line, an unfinished or not pending one, and an ID the rules do not relax (brief 2026-11-02-cycle-runs-migrations)" {
    legacy; bash "$QS" migrate > /dev/null
    # A moved entry's answer line or Status changed on the way, or one dropped instead of moved.
    sed -i 's/^Q-003: met, seen in run 4$/Q-003: [1]/' docs/working/watching.md; git add -A; cd_is "$(GONE Q-003)" --migrated "$MIG"
    git checkout -q HEAD -- docs/working; bash "$QS" migrate > /dev/null
    sed -i '/^### Q-002/,/^Watch x\./s/\*\*Status:\*\* OPEN/**Status:** ANSWERED/' docs/working/watching.md; git add -A; cd_is "$(GONE Q-002)" --migrated "$MIG"
    git checkout -q HEAD -- docs/working; bash "$QS" migrate > /dev/null
    printf '%s\n' '- Q-004: [2]' >> docs/working/roadmap-from-questions.md; git add -A; cd_is "$(GONE Q-004)" --migrated "$MIG"
    git checkout -q HEAD -- docs/working; bash "$QS" migrate > /dev/null
    sed -i '/^### Q-004/,$d' docs/working/roadmap-from-questions.md; git add -A; cd_is "$(GONE Q-004)" --migrated "$MIG"
    # Unfinished: one legacy line left behind.
    git checkout -q HEAD -- docs/working; rm -f docs/working/roadmap-from-questions.md
    sed -n '/^### Q-002/,/^Watch x\./p' docs/working/questions.md >> docs/working/watching.md; sed -i '/^### Q-002/,/^Watch x\./d' docs/working/questions.md; git add -A
    cd_is "refuse docs/working/questions.md: --migrated $MIG: a line of its index copy still matches its pattern, so the remedy did not finish
$(GONE Q-002)" --migrated "$MIG"
    # An ID the registry lacks, one with no file, one whose file is a record (truth), and none pending on the base.
    git checkout -q HEAD -- docs/working; bash "$QS" migrate > /dev/null; git add -A
    cd_is "refuse HEAD: --migrated baseline-roadmap: its remedy changes no file, which these rules do not relax for a migration (the owner runs it)
refuse HEAD: --migrated failure-patterns-out-of-thoughts: its remedy changes docs/thoughts/failure-patterns.md, which these rules do not relax for a migration (the owner runs it)
refuse HEAD: --migrated no-such-id names no migration in the gate's registry
$(GONE Q-002)
$(GONE Q-003)
$(GONE Q-004)" --migrated no-such-id --migrated failure-patterns-out-of-thoughts --migrated baseline-roadmap
    commit_all migrated; git checkout -q -b chore/dev-cycle-2026-10-13 HEAD; echo x >> docs/working/watching.md; git add -A
    git update-ref refs/heads/main HEAD~0; git reset -q --soft HEAD
    cd_is "refuse docs/working/questions.md: --migrated $MIG: no line on the base matches its pattern, so the migration was not pending" --migrated "$MIG"
}

@test "--cycle-diff --migrated holds every copy of a moved entry and every Status field to the base, and refuses a registry it cannot trust (brief 2026-11-02-cycle-runs-migrations, i1 review)" {
    legacy
    # A Status in a second field of the Needs line, and a copy left behind as well as moved with its answer changed.
    bash "$QS" migrate > /dev/null; sed -i '/^### Q-002/,/^Watch x\./s/\*\*Status:\*\* OPEN$/**Status:** OPEN · **Status:** ANSWERED/' docs/working/watching.md; git add -A
    cd_is "$(GONE Q-002)" --migrated "$MIG"; git checkout -q HEAD -- docs/working; rm -f docs/working/roadmap-from-questions.md
    sed -i 's/^\*\*Needs:\*\* agent ·/**Needs:** you: judgment ·/' docs/working/questions.md
    sed -n '/^### Q-004/,/^Do y\./p' docs/working/questions.md > docs/working/roadmap-from-questions.md; echo 'Q-004: [1]' >> docs/working/roadmap-from-questions.md
    bash "$QS" migrate > /dev/null; git add -A; grep -q '^### Q-004' docs/working/questions.md; cd_is "$(GONE Q-004)" --migrated "$MIG"
    # A registry with a malformed line, or a symlinked one, beside a copied gate.
    git checkout -q HEAD -- docs/working; rm -f docs/working/roadmap-from-questions.md; bash "$QS" migrate > /dev/null; git add -A
    O="$BATS_TEST_TMPDIR/opt"; mkdir -p "$O/scripts/lib"; cp "$REPO_ROOT/scripts/build-loop.sh" "$O/scripts/"; cp "$REPO_ROOT"/scripts/lib/{dev-cycle-read,migrations}.sh "$O/scripts/lib/"
    run --separate-stderr bash "$O/scripts/build-loop.sh" --cycle-diff --migrated "$MIG"; [ "$status" -eq 0 ] && [ "$output" = ok ] || { show; return 1; }
    perl -0pi -e 's/^(if \[\[ "\$\{BASH_SOURCE)/mig bad-line\n$1/m' "$O/scripts/lib/migrations.sh"
    run --separate-stderr bash "$O/scripts/build-loop.sh" --cycle-diff --migrated "$MIG"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse HEAD: --migrated needs the registry lib/migrations.sh, which has malformed lines" ] || { show; return 1; }
    mv "$O/scripts/lib/migrations.sh" "$O/m.sh"; cp "$REPO_ROOT/scripts/lib/migrations.sh" "$O/m.sh"; ln -s "$O/m.sh" "$O/scripts/lib/migrations.sh"
    run --separate-stderr bash "$O/scripts/build-loop.sh" --cycle-diff --migrated "$MIG"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse HEAD: --migrated needs the registry lib/migrations.sh beside build-loop.sh, which is missing, not a regular file or does not parse" ] || { show; return 1; }
}

@test "--cycle-diff --migrated relaxes a roadmap's headings only for a registry line whose file is the roadmap, read from the registry beside the gate (brief 2026-11-02-cycle-runs-migrations)" {
    O="$BATS_TEST_TMPDIR/opt"; mkdir -p "$O/scripts/lib"; cp "$REPO_ROOT/scripts/build-loop.sh" "$O/scripts/"; cp "$REPO_ROOT"/scripts/lib/{dev-cycle-read,migrations}.sh "$O/scripts/lib/"
    perl -0pi -e 's/^(if \[\[ "\$\{BASH_SOURCE)/mig roadmap-later roadmap 0123456789abcdef docs\/roadmap.md '"'"'^## Later\$'"'"' '"'"'~\/.claude\/scripts\/x.sh'"'"'\n$1/m' "$O/scripts/lib/migrations.sh"
    grep -q '^mig roadmap-later ' "$O/scripts/lib/migrations.sh"
    mkdir -p docs; printf '%s\n' '# Roadmap' 'Intro.' '## Now' '## Later' '- `docs/working/briefs/2026-10-01-x.md`' '## Done' > docs/roadmap.md; commit_all roadmap
    git checkout -q -b chore/dev-cycle-2026-10-12; sed -i 's/^## Later$/## Next/' docs/roadmap.md; git add -A
    run --separate-stderr bash "$O/scripts/build-loop.sh" --cycle-diff
    [ "$status" -eq 2 ] && [ "$output" = "refuse docs/roadmap.md: its ## headings changed" ] || { show; return 1; }
    run --separate-stderr bash "$O/scripts/build-loop.sh" --cycle-diff --migrated roadmap-later
    [ "$status" -eq 0 ] && [ "$output" = ok ] || { show; return 1; }
    # The brief-line rule still holds; the repo's own gate, whose registry lacks the line, refuses the ID.
    sed -i '/2026-10-01-x/d' docs/roadmap.md; git add -A
    run --separate-stderr bash "$O/scripts/build-loop.sh" --cycle-diff --migrated roadmap-later
    [ "$status" -eq 2 ] && [ "$output" = "refuse docs/roadmap.md: the brief 2026-10-01-x.md, named outside Done on the base, is named on no line" ] || { show; return 1; }
    # A remedy that empties the file is not a migration.
    : > docs/roadmap.md; git add -A
    run --separate-stderr bash "$O/scripts/build-loop.sh" --cycle-diff --migrated roadmap-later
    [ "$status" -eq 2 ] && [ "$output" = "refuse docs/roadmap.md: --migrated roadmap-later: the index side is empty, not a regular file, or could not be read
refuse docs/roadmap.md: its lines above the first ## heading changed
refuse docs/roadmap.md: its ## headings changed
refuse docs/roadmap.md: the brief 2026-10-01-x.md, named outside Done on the base, is named on no line" ] || { show; return 1; }
    git checkout -q HEAD -- docs/roadmap.md; sed -i 's/^## Later$/## Next/' docs/roadmap.md; git add -A
    cd_is "refuse HEAD: --migrated roadmap-later names no migration in the gate's registry
refuse docs/roadmap.md: its ## headings changed" --migrated roadmap-later
    # A registry the gate cannot read refuses the mode, never passes it.
    echo 'mig (' >> "$O/scripts/lib/migrations.sh"
    run --separate-stderr bash "$O/scripts/build-loop.sh" --cycle-diff --migrated roadmap-later
    [ "$status" -eq 2 ] && [ "$output" = "refuse HEAD: --migrated needs the registry lib/migrations.sh beside build-loop.sh, which is missing, not a regular file or does not parse
refuse docs/roadmap.md: its ## headings changed" ] || { show; return 1; }
}

# img: the questions files on main with an open image-lag (Q-005), image-off-main-C12 (Q-006) and merge
# entry (Q-001), then a chore branch. C and MM are full commit ids; MET ID: step 0.1's closing line for ID.
img() {
    mkdir -p docs/working; local t='**Needs:** you: terminal · **Opened:** 2026-10-12 · **Status:**'
    printf '%s\n' '# Questions' '### Q-001 · merge-x-0123456789ab' "$N OPEN" '' 'Merge?' '### Q-005 · image-lag' "$t OPEN" '' 'Release.' \
        '### Q-006 · image-off-main-0123456789ab' "$N OPEN" '' 'Rebuild?' '### Q-007 · image-lag' "$t ANSWERED" 'Q-007: [1]' > docs/working/questions.md
    printf '%s\n' '# Archive' > docs/working/questions-archive.md; commit_all questions; git checkout -q -b chore/dev-cycle-2026-10-12
    C="$(git rev-parse HEAD)"; MM="$(git rev-parse HEAD~1)"
}
MET() { echo "$1: met — image $C holds the gate code of main $MM"; }
# close ID LINE: ID's Status OPEN becomes ANSWERED and LINE follows its Needs line, staged.
close() { sed -i "/^### $1 /,/^###/{s/\*\*Status:\*\* OPEN/**Status:** ANSWERED/; /^\*\*Needs:/a $2
}" docs/working/questions.md; git add -A; }

@test "--cycle-diff takes step 0.1's close of an open image-lag or image-off-main entry, and an archive move after it (brief 2026-11-02-cycle-runs-migrations)" {
    img; close Q-005 "$(MET Q-005)"; cd_is ok
    close Q-006 "$(MET Q-006)"; cd_is ok
    # questions.sh archive then moves the closed entries whole.
    sed -n '/^### Q-005/,/^Release\./p; /^### Q-006/,/^Rebuild?/p' docs/working/questions.md >> docs/working/questions-archive.md
    sed -i '/^### Q-005/,/^Release\./d; /^### Q-006/,/^Rebuild?/d' docs/working/questions.md; git add -A; cd_is ok
    # The gate checks the line against the repository: both ids commits, no gate-code path differing between them.
    git reset -q --hard; R0="refuse docs/working/questions.md: Q-005's closing line"
    C="$(printf 'a%.0s' $(seq 64))"; close Q-005 "$(MET Q-005)"; cd_is "$R0 names $C and $MM, which are not both commits here"; git reset -q --hard
    git checkout -q main; mkdir -p scripts/lib; echo g > scripts/lib/g.sh; echo d > docs/d.md; commit_all gate; G="$(git rev-parse HEAD)"; git checkout -q chore/dev-cycle-2026-10-12
    C="$G"; close Q-005 "$(MET Q-005)"; cd_is "$R0 says $G holds the gate code of $MM, but scripts/lib/g.sh differs"; git reset -q --hard
    # Only docs/ moved since: still the same gate code.
    MM="$G"; git checkout -q main; echo e > docs/d.md; commit_all docs; C="$(git rev-parse HEAD)"; git checkout -q chore/dev-cycle-2026-10-12
    close Q-005 "$(MET Q-005)"; cd_is ok
}

@test "--cycle-diff refuses an image-lag close other than step 0.1's, and the closing line written on any other entry (brief 2026-11-02-cycle-runs-migrations)" {
    img
    # On a merge entry, an answered image-lag entry, or a slug that only starts like one.
    close Q-001 "$(MET Q-001)"; cd_is "$(GONE Q-001)"; git reset -q --hard
    sed -i '/^Q-007: \[1\]$/a '"$(MET Q-007)" docs/working/questions.md; git add -A; cd_is "$(GONE Q-007)"; git reset -q --hard
    sed -i 's/^### Q-006 · image-off-main-0123456789ab$/### Q-006 · image-off-main-0123456789abc/' docs/working/questions.md; commit_all slug
    git update-ref refs/heads/main HEAD; close Q-006 "$(MET Q-006)"; cd_is "$(GONE Q-006)"; git reset -q --hard HEAD~1; git update-ref refs/heads/main HEAD
    # The Status flip alone, the line alone, two lines, a short id, another ID's line, a changed route, a dropped body line is free.
    close Q-005 x; sed -i '/^x$/d' docs/working/questions.md; git add -A; cd_is "$(GONE Q-005)"; git reset -q --hard
    sed -i '/^### Q-005/,/^Release/{/^\*\*Needs:/a '"$(MET Q-005)"'
}' docs/working/questions.md; git add -A; cd_is "$(GONE Q-005)"; git reset -q --hard
    close Q-005 "$(MET Q-005)"; sed -i '/^Release\./a '"$(MET Q-005)" docs/working/questions.md; git add -A; cd_is "$(GONE Q-005)"; git reset -q --hard
    close Q-005 "Q-005: met — image ${C:0:12} holds the gate code of main $MM"; cd_is "$(GONE Q-005)"; git reset -q --hard
    close Q-005 "$(MET Q-006)"; cd_is "$(GONE Q-005)"; git reset -q --hard
    close Q-005 "$(MET Q-005)"; sed -i '/^### Q-005/,/^Release/s/you: terminal/you: fyi/' docs/working/questions.md
    git add -A; cd_is "$(GONE Q-005)"; git reset -q --hard
    close Q-005 "$(MET Q-005)"; sed -i '/^Release\./d' docs/working/questions.md; git add -A; cd_is ok
}

@test "the answer label regex is the same in the lib's ANSWER_AWK, ANSWERS_AWK and QKEYS_AWK (U3c i2 architecture 1)" {
    r='/^\*\*answer(:|ed| \()/'
    [ "$(grep -cF "$r" "$REPO_ROOT/scripts/lib/dev-cycle-read.sh")" -eq 1 ] && [ "$(grep -cF "$r" "$BL")" -eq 2 ]
}

@test "--cycle-diff refuses a roadmap preamble, heading or dropped brief line and an idea log edited, not appended; passes the cycle's own rewrites (T38, U3c)" {
    mkdir -p docs/working; I='- **X**: Brief: `docs/working/briefs/2026-10-01-x.md`'
    printf '%s\n' '# Roadmap' 'Intro.' '## Now' '- a' '## In flight' "$I" '## Next' '1. n' '## Ideas' '## Done (last cycle)' '- y: `docs/working/briefs/closed/2026-09-01-y.md`' > docs/roadmap.md
    printf '%s\n' '# Idea log' '- i1 (signal: s)' > docs/working/idea-log.md; commit_all roadmap; git checkout -q -b chore/dev-cycle-2026-10-12
    # Step 6's rewrites: Next reworded, Done trimmed, X moved to Done at closed/, an idea appended, any other allowed path.
    sed -i 's/^1\. n/1. m/; /2026-09-01-y/d; /2026-10-01-x/d' docs/roadmap.md; echo '- X done: `docs/working/briefs/closed/2026-10-01-x.md`' >> docs/roadmap.md
    echo '- i2 (signal: t)' >> docs/working/idea-log.md; echo x > docs/other.md; git add -A; cd_is ok
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

@test "--cycle-diff refuses the gate's code, truth files and a brief's Asked: line other than extended by entries the change files, matched by name across a move to closed/ (row 745, U4a, i1 security F1-F3, i2 F-a to F-d, final F1-F4)" {
    F=docs/working/briefs/2026-10-01-x.md; C=docs/working/briefs/closed/2026-10-01-x.md; Y=docs/working/briefs/2026-10-01-y.md; mkdir -p docs/working/briefs/closed scripts/lib
    printf '%s\n' 'Status: open' 'Asked: Q-001@abc' > "$F"; printf '%s\n' 'Status: open' > "$Y"; echo s > scripts/lib/a.sh; echo d > docs/dev-cycle.md; commit_all briefs; qa
    W="its first Asked: line drops or changes an ID it held; the cycle only appends one"; A="its first Asked: line adds"; E='### Q-002 · keep-or-drop-2026-10-01-x-1'
    # An ID appended for an entry this change files passes; one naming no new entry (another question's, or none) refuses (F1).
    sed -i 's/^Asked: .*/&, Q-002@def1234/' "$F"; printf '%s\n' "$E" "$N OPEN" >> docs/working/questions.md; git add -A; cd_is ok
    git checkout -q HEAD -- docs/working/questions.md; cd_is "refuse $F: $A Q-002@def1234, which names no question entry this change files"; git reset -q --hard
    sed -i 's/^Asked: .*/&, Q-003/' "$F"; git add -A; cd_is "refuse $F: $A Q-003, which names no question entry this change files"; git reset -q --hard
    # Only exact items (i2 F-b), added once (i2 F-a), for the entry's own brief (final F2).
    printf '%s\n' "$E" "$N OPEN" >> docs/working/questions.md; sed -i 's/^Asked: .*/&, Q-002@Q-003/' "$F"; git add -A; cd_is "refuse $F: $A \"Q-002@Q-003\", which is not Q-NNN or Q-NNN@SHA"
    sed -i 's/^Asked: .*/Asked: Q-001@abc, /' "$F"; git add -A; cd_is "refuse $F: $A \"\", which is not Q-NNN or Q-NNN@SHA"
    sed -i 's/^Asked: .*/Asked: Q-001@abc, Q-002, Q-002/' "$F"; git add -A; cd_is "refuse $F: $A Q-002, which is added more than once (by this or another brief's Asked: line)"
    sed -i 's/^Asked: .*/Asked: Q-001@abc/' "$F"; echo 'Asked: Q-002' >> "$Y"; git add -A; cd_is "refuse $Y: $A Q-002, whose entry's heading is not WORDS-2026-10-01-y-N (an entry filed for this brief)"
    # An entry for a brief whose name ends in this one's does not fit (confirming F-A).
    sed -i '/^Asked: Q-002$/d' "$Y"; sed -i 's/^### Q-002 · .*/### Q-002 · keep-or-drop-2026-10-02-foo-2026-10-01-x-1/' docs/working/questions.md; sed -i 's/^Asked: .*/&, Q-002/' "$F"; git add -A
    cd_is "refuse $F: $A Q-002, whose entry's heading is not WORDS-2026-10-01-x-N (an entry filed for this brief)"; git reset -q --hard; printf '%s\n' "$E" "$N OPEN" >> docs/working/questions.md; git add -A
    # A questions file refused whole: only that refusal, not "names no entry" for a correct item (final architecture 1).
    sed -i '/^Asked: Q-002$/d' "$Y"; sed -i 's/^Asked: .*/&, Q-002/' "$F"; printf '%s\n' '```' >> docs/working/questions.md; git add -A
    cd_is "refuse docs/working/questions.md: --check-answer refuses its index copy whole (unbalanced 12)"; git reset -q --hard
    git mv "$F" "$C"; cd_is ok; sed -i 's/^Asked: .*/Asked: Q-002@def1234/' "$C"; git add -A; cd_is "refuse $C: $W"; git reset -q --hard
    # The same name changed in briefs/ and closed/ at once (i2 F-c).
    mkdir -p "${C%/*}"; cp "$F" "$C"; sed -i 's/Q-001@abc/Q-009@abc/' "$F"; git add -A; cd_is "refuse $C: another brief path with its file name changes too, and the Asked: rule matches briefs by file name
refuse $F: $W"; git reset -q --hard; rm -f "$C"
    sed -i 's/Q-001@abc/Q-009@abc/' "$F"; git add -A; cd_is "refuse $F: $W"; git reset -q --hard
    git rm -q "$F"; cd_is "refuse $F: deleted or renamed with its Asked: line; the cycle only moves a brief to closed/ under its name"; git reset -q --hard
    # The gate's code and truth files but the cycle's own (F2), compared lower-cased; a cycle file in another case (i2 F-d).
    mkdir -p SKILLS/dev-cycle; echo s > SKILLS/dev-cycle/x.md; echo t >> scripts/lib/a.sh; echo t >> docs/dev-cycle.md; echo a > AGENTS.md; echo q > docs/working/Questions.md; git add -A
    G="an in-cycle fix never edits it"; cd_is "refuse AGENTS.md: an instruction or prompt file, which sessions load from the checkout; $G (--check-fix refuses it too)
refuse SKILLS/dev-cycle/x.md: the gate's own code; $G
refuse docs/dev-cycle.md: the dev cycle's settings file; $G (--check-fix refuses it too)
refuse docs/working/Questions.md: one of the dev cycle's own files, spelled in another case, which these rules do not read
refuse scripts/lib/a.sh: the gate's own code; $G"; git reset -q --hard
    # The failure-pattern library and its old path are records; another docs/thoughts/ note is a fixable doc.
    mkdir -p docs/thoughts; echo f > docs/failure-patterns.md; echo f > docs/thoughts/failure-patterns.md; echo n > docs/thoughts/n.md; git add -A
    R="a record later runs read as truth; $G (--check-fix refuses it too)"; cd_is "refuse docs/failure-patterns.md: $R
refuse docs/thoughts/failure-patterns.md: $R"; git reset -q --hard; rm -rf docs/thoughts docs/failure-patterns.md
    mkdir -p docs/thoughts; echo n > docs/thoughts/n.md; git add -A; cd_is ok; git reset -q --hard; rm -rf docs/thoughts
    # Only the cycle's files, a .md under docs/ or README.md: a loop's commit carried on the chore branch refuses (final F1, F3, F4).
    mkdir -p src docs/x; echo s > src/app.sh; echo m > docs/x/y.md; echo r > README.md; echo k > "AGENTS.md$(printf '\u212a')"; git add -A
    O="not a file the cycle changes (its own files, a .md under docs/ or README.md)"; cd_is "refuse AGENTS.md$(printf '\u212a'): $O
refuse src/app.sh: $O"; git reset -q --hard
    # Compared lower-cased, as --check-fix compares (confirming F-B).
    echo r > readme.md; mkdir -p Docs; echo d > Docs/x.md; git add -A; cd_is ok
}

@test "a weekly digest lands with the cycle's record, as a chore merge; a copy in another case refuses (brief 2026-11-06-codify-trial-practices)" {
    qa; B=chore/dev-cycle-2026-10-12; M="$(git rev-parse main)"; F=docs/working/weekly/2026-10-12.md
    mkdir -p docs/working/weekly; echo w > docs/working/weekly/2026-10-12.MD; git add -A
    cd_is "refuse docs/working/weekly/2026-10-12.MD: one of the dev cycle's own files, spelled in another case, which these rules do not read"; git reset -q --hard; rm -rf docs/working/weekly
    mkdir -p docs/working/weekly docs/working/cycles; echo w > "$F"; printf '%s\n' "Branch: $B" > docs/working/cycles/cycle-2026-10-12.md; git add -A; cd_is ok
    commit_all land; bl --land-cycle --main "$M"
    [ "$status" -eq 0 ] && [[ "$output" == "landed $B "* ]] && git cat-file -e "main:$F" || { show; return 1; }
    bl --main-log "$M"; [ "$status" -eq 0 ] && [ "${lines[1]}" = "chore $(git rev-parse main) Merge branch '$B'" ] || { show; return 1; }
}

# lc_is WANT ARG...: --land-cycle ARG... refused with exactly WANT, exit 2. rec LINE...: the day's cycle record gains LINEs, committed.
lc_is() { local w="$1"; shift; bl --land-cycle "$@"; [ "$status" -eq 2 ] && [ "$output" = "$w" ] && [ -z "$stderr" ] || { echo "want: $w"; show; return 1; }; }
rec() { mkdir -p docs/working/cycles && printf '%s\n' "$@" >> docs/working/cycles/cycle-2026-10-12.md && commit_all record; }

@test "--land-cycle lands HEAD's chore branch as the merge --main-log reads as chore, by compare-and-swap or a fast-forward where main is checked out (D13, rows 719, 749, 752, U4a)" {
    qa; B=chore/dev-cycle-2026-10-12; M="$(git rev-parse main)"
    lc_is "refuse HEAD: it has no commit the default branch lacks, or its history could not be read" --main "$M"
    rec "Branch: chore/dev-cycle-2026-10-13"
    lc_is "refuse HEAD: the merge adds or changes no cycle record (docs/working/cycles/cycle-YYYY-MM-DD.md) holding the line \"Branch: $B\", so --main-log would read it as other" --main "$M"
    rec "Branch: $B"; echo x > o.md; git add o.md; lc_is "refuse HEAD: the index holds changes its commit lacks, or could not be read; commit them first" --main "$M"
    git rm -q --cached o.md; rm o.md
    sed -i '/^Which/a Q-001: [1]' docs/working/questions.md; commit_all answer
    lc_is "refuse docs/working/questions.md: Q-001's heading, Needs or answer lines changed or are gone, and Q-001 is not in --answered" --main "$M"
    onmain x.md x; N2="$(git rev-parse main)"
    lc_is "refuse HEAD: the default branch is at $N2, not --main's $M; merge it into HEAD, run --cycle-diff again and land with --main $N2" --main "$M" --answered Q-001
    git checkout -q -b feat/y; lc_is "refuse HEAD: it is not on a branch chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM" --main "$N2"; git checkout -q "$B"
    H="$(git rev-parse HEAD)"; T="$(git merge-tree --write-tree main HEAD)"
    bl --land-cycle --main "$N2" --answered Q-001
    [ "$status" -eq 0 ] && [ "$output" = "landed $B $H $T $(git rev-parse main)" ] && [ "$(git rev-parse main^1 main^2 'main^{tree}')" = "$N2"$'\n'"$H"$'\n'"$T" ] \
        && [ "$(git log -1 --format=%B main)" = "Merge branch '$B'" ] || { show; return 1; }
    bl --main-log "$N2"; [ "$status" -eq 0 ] && [ "${lines[1]}" = "chore $(git rev-parse main) Merge branch '$B'" ] || { show; return 1; }
    # Main checked out in the first worktree: the land fast-forwards it there; HEAD in a linked worktree.
    git checkout -q main; git worktree add -q -b chore/dev-cycle-2026-10-13-0900 "$BATS_TEST_TMPDIR/wt" main; cd "$BATS_TEST_TMPDIR/wt"
    rec "Branch: chore/dev-cycle-2026-10-13-0900"; M="$(git rev-parse main)"; bl --land-cycle --main "$M"
    [ "$status" -eq 0 ] && [[ "$output" == "landed chore/dev-cycle-2026-10-13-0900 $(git rev-parse HEAD) "* ]] && [ "$(git -C "$R" rev-parse HEAD^1)" = "$M" ] \
        && [ -z "$(git -C "$R" status --porcelain --untracked-files=no)" ] || { show; return 1; }
}

@test "--land-cycle refuses a merge that names a blob the object store lacks, which merge-tree passes by id unread (i1 architecture 1; brief 2026-11-01-relax-gate-git-state)" {
    qa; B=chore/dev-cycle-2026-10-12; rec "Branch: $B"; M="$(git rev-parse main)"
    b="$(echo absent | git hash-object --stdin)"
    t="$( (git ls-tree HEAD; printf '100644 blob %s\tnew.md\n' "$b") | git mktree --missing)"
    git update-ref "refs/heads/$B" "$(git commit-tree "$t" -p HEAD -m missing)" && git read-tree "$B"
    lc_is "refuse HEAD: its merge names a blob the object store lacks" --main "$M"
}

# plant_hooks: every hook name git knows, executable in the hooks directory, each appending its name to $FIRED.
FIRED="$BATS_TEST_TMPDIR/fired"
plant_hooks() { local h d; d="$(git rev-parse --path-format=absolute --git-common-dir)/hooks"; mkdir -p "$d"
    for h in applypatch-msg pre-applypatch post-applypatch pre-commit pre-merge-commit prepare-commit-msg commit-msg post-commit pre-rebase post-checkout post-merge pre-push pre-receive update proc-receive post-receive post-update reference-transaction push-to-checkout pre-auto-gc post-rewrite sendemail-validate fsmonitor-watchman post-index-change; do
        printf '#!/bin/sh\necho %s >> "%s"\n' "$h" "$FIRED" > "$d/$h"; chmod +x "$d/$h"; done; }

@test "--land-cycle runs no hook planted in the hooks directory, by compare-and-swap or by the fast-forward where main is checked out (C9, T2, Q-141)" {
    qa; B=chore/dev-cycle-2026-10-12; plant_hooks
    # The control: the fixture's own plain git runs them (so an empty $FIRED below is not a dead hook).
    git update-ref refs/heads/probe HEAD; grep -qx reference-transaction "$FIRED" || { cat "$FIRED"; return 1; }
    rec "Branch: $B"; M="$(git rev-parse main)"; rm -f "$FIRED"
    bl --land-cycle --main "$M"
    [ "$status" -eq 0 ] && [[ "$output" == "landed $B "* ]] && [ "$(git rev-parse main^1)" = "$M" ] && [ ! -e "$FIRED" ] || { show; cat "$FIRED"; return 1; }
    # Main checked out in the first worktree: the land fast-forwards it there.
    git checkout -q main; git worktree add -q -b chore/dev-cycle-2026-10-13-0900 "$BATS_TEST_TMPDIR/wt" main; cd "$BATS_TEST_TMPDIR/wt"
    rec "Branch: chore/dev-cycle-2026-10-13-0900"; M="$(git rev-parse main)"; rm -f "$FIRED"
    bl --land-cycle --main "$M"
    [ "$status" -eq 0 ] && [ "$(git -C "$R" rev-parse HEAD^1)" = "$M" ] && [ ! -e "$FIRED" ] || { show; cat "$FIRED"; return 1; }
}

@test "--land-cycle judges the merge, not the index: a rename git pairs into a new questions file carries main's answer, and a conflict refuses (row 753, U4a)" {
    mkdir -p docs/working; printf '%s\n' '# Draft' '### Q-001 · x' "$N OPEN" '' 'Which?' '| **[1] a** | b |' '| **[2] c** | d |' 'Notes.' > docs/working/draft.md
    echo base > x.md; commit_all draft; git checkout -q -b chore/dev-cycle-2026-10-12; git mv docs/working/draft.md docs/working/questions.md; cd_is ok; commit_all move
    rec "Branch: chore/dev-cycle-2026-10-12"; onmain docs/working/draft.md "$(sed 's/OPEN/ANSWERED/; /^Which/a Q-001: [1]' docs/working/questions.md)"
    # --cycle-diff's guard compares the questions files' listings, which neither side has on the base (U3c's confirming pass).
    cd_is ok; git show "$(git merge-tree --write-tree main HEAD):docs/working/questions.md" | grep -qxF 'Q-001: [1]'
    lc_is "refuse docs/working/questions.md: Q-001 is a new entry filed answered (Status ANSWERED or an answer line), and Q-001 is not in --answered" --main "$(git rev-parse main)"
    git merge -q --no-edit main; echo chore > x.md; commit_all x; onmain x.md main
    lc_is "refuse HEAD: it conflicts with the default branch; merge the default branch into HEAD first" --main "$(git rev-parse main)"
}
