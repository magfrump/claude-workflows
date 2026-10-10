# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a3 (branch feat/build-loop-u3a3)
**Scope:** `git diff main...HEAD` (18f32952 tests, a7a4f784 code): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/build-loop-merge.bats, and both commit messages
**Commit:** a7a4f784
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-10
**Total claims checked:** 26
**Summary:** 22 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries): no claim here matches or resembles a logged pattern.

Execution logs (scratch, outside the repo per the brief's write rule): `LOGS=/tmp/claude-1000/-workspace/675070f9-0197-40a3-bd3c-520157521989/scratchpad/u3a3-i1/fc/logs/`. The runs, all from cwd `/workspace/.claude/wt-build-loop-u3a3` unless noted, each under `timeout`:

| Run | Command | Started | Exit | Output |
|---|---|---|---|---|
| R1 | `timeout 600 bats test/scripts/build-loop-merge.bats` | 2026-10-10T16:15:41-07:00 | 0 (12/12 ok) | `$LOGS/merge-bats.log` |
| R2 | `timeout 900 bats test/scripts/build-loop-check.bats` | 2026-10-10T16:16:00-07:00 | 0 (146 ok, 0 not ok) | `$LOGS/check-bats.log` |
| R3 | `timeout 900 bats test/scripts/dev-cycle.bats` | 2026-10-10T16:17:13-07:00 | 0 (79 ok) | `$LOGS/devcycle-bats.log` |
| R4 | `timeout 120 fc/probe-answer.sh fc` (main's vs a7a4f784's dev-cycle.sh `--check-answer` on one fixture repo; then `ANSWER_HEAD` per ID) | 2026-10-10T16:17:52-07:00 | 0 | `$LOGS/probe-answer.log` |
| R5 | `timeout 200 fc/probe-fix.sh fc` (main's vs a7a4f784's `--check-fix docs/a.md` with `CLAUDE_CONFIG_DIR=relative`) | 2026-10-10T16:18:05-07:00 | 0 | `$LOGS/probe-fix.log` |
| R6 | `git archive 18f32952 scripts test` into `fc/at18`, then from `fc/at18`: `timeout 300 bats -f 'U3a3\|review; --merge' test/scripts/build-loop-merge.bats` | 2026-10-10T16:18:21-07:00 | 1 (5/5 not ok) | `$LOGS/at18-merge.log` |

---

## Claim 1: "--merge lands a self-merge brief (D7): --check's lines for BRIEF at --expect's tip"

**Location:** `scripts/build-loop.sh:213-214`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the --merge paragraph's opening sentence against the new --approved arm; does not establish anything about the --check paragraph, which is unchanged and still accurate for --check.
**Legibility-target:** for-author

The opening sentence was true before U3a3. The same paragraph now says --approved lands "a brief of either policy under the N rules alone" (`scripts/build-loop.sh:222-224`). So "lands a self-merge brief" is now too narrow. And for a self-merge brief under --approved, the path lines are not --check's lines: check_line drops the S rules when AUTH is approved:

```bash
# scripts/build-loop.sh:982
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
# scripts/build-loop.sh:1042
    [[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"
```

A path that `--check` would print as `deny` (never glob, Paths:, floor) prints as `path` under `--merge --approved` (the R1 test at `test/scripts/build-loop-merge.bats` "runs the N rules only" relies on this). A precise version would read something like "lands a self-merge brief, or with --approved a brief of either policy (D7): --check's lines for BRIEF at --expect's tip (the N rules' alone under --approved)".

**Evidence:** `scripts/build-loop.sh:213-235`, `scripts/build-loop.sh:982`, `scripts/build-loop.sh:1042`

---

## Claim 2: "With --approved Q-NNN it lands a brief of either policy under the N rules alone (no S rules, no checkout rule)"

**Location:** `scripts/build-loop.sh:222-224`
**Type:** Behavioral
**Verification mode:** executed
**Verdict:** Verified
**Confidence:** High
**Scope:** Covers that, with AUTH=approved, check_line skips checkout_gate, read_paths and srules for a self-merge brief, runs nrules for every path, and that the merge arm skips the policy refusal; does not establish that the N rules themselves are complete (unchanged code), and does not cover --check, which never sets AUTH=approved.

The `sm` flag gates all three S-side steps, and it stays empty under approved:

```bash
# scripts/build-loop.sh:1024
  co=""; if [[ -n "$sm" ]] && ! checkout_gate; then co="refuse $a: ..."; fi
# scripts/build-loop.sh:1027
  [[ -z "$sm" ]] || read_paths
# scripts/build-loop.sh:1040-1042
    nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"
    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
    [[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules ...
```

The merge arm's policy refusal fires only for `AUTH == self-merge` (`scripts/build-loop.sh:1215`). Executed: R1's test 9 lands a self-merge brief past its `Self-merge never: work-*` glob, `Paths: none` and a checkout on feat/x, which a plain --merge refuses. It then refuses `docs/roadmap.md` with "one of the dev cycle's own files" (an N rule). R1's test 8 lands a review-policy brief. Both ok.

**Evidence:** `scripts/build-loop.sh:982`, `scripts/build-loop.sh:1024-1042`, `scripts/build-loop.sh:1209-1220`, `test/scripts/build-loop-merge.bats:194-221`, `$LOGS/merge-bats.log`

---

## Claim 3: "the questions entry Q-NNN, read from the default branch's commit as --check-answer reads it"

**Location:** `scripts/build-loop.sh:225-226`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that approval() calls the lib's check_answer, the same function dev-cycle.sh --check-answer calls, which reads `$MAIN_SHA:$f` blobs, and that a working-tree-only answer is refused; does not establish anything about the Q-103 planted-git-state residuals (routed elsewhere).

```bash
# scripts/build-loop.sh:1075
  check_answer "$1" > "$GATE_TMP/answer"; r="$(cat "$GATE_TMP/answer")"
# scripts/dev-cycle.sh:209
      --check-answer) check_answer "$a" ;;
# scripts/lib/dev-cycle-read.sh:2083
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
```

Executed: R1's test 10 edits OPEN to ANSWERED in the working tree only (`sed -i ... docs/working/questions.md`) and gets "it is not answered on the default branch". ok.

**Evidence:** `scripts/build-loop.sh:1070-1084`, `scripts/lib/dev-cycle-read.sh:2070-2097`, `test/scripts/build-loop-merge.bats:223-235`, `$LOGS/merge-bats.log`

---

## Claim 4: "answered with option 1 under the heading exactly "### Q-NNN · merge-STEM-SHA12" (SHA12: TIP's first 12 hex digits), or "merge-gate-STEM-SHA12" when a changed path, lower-cased, is the gate's own code (scripts/build-loop.sh, dev-cycle.sh, questions.sh, anything under scripts/lib/)"

**Location:** `scripts/build-loop.sh:226-231`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exact-match comparison, the 12-digit prefix, gate detection on lower-cased paths against GATE_CODE, and the requirement that the slug be merge-gate- exactly when gate code changes; does not establish anything about a heading with a tab after the ID (ANSWER_AWK's heading() matches it, and the exact compare would then refuse it, which errs toward refusal).

```bash
# scripts/build-loop.sh:1072-1073
  [[ -z "${VERDICT[gate]}" ]] || { s="merge-gate-"; g=" (the merge changes the gate's own code)"; }
  s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"
# scripts/build-loop.sh:1082
  [[ "$ANSWER_HEAD" == "$1 · $s" ]] \
# scripts/lib/dev-cycle-read.sh:1915
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'
```

`gc` is set from `lps` (the lower-cased paths, `scripts/build-loop.sh:1041`). Executed: R1's test 10 refuses another stem, main's SHA, merge-gate- without gate code, a trailing space and a suffix. R1's test 11 requires merge-gate- for `scripts/build-loop.sh` and `Scripts/Lib/x.sh`. All ok.

**Evidence:** `scripts/build-loop.sh:1041`, `scripts/build-loop.sh:1070-1084`, `scripts/lib/dev-cycle-read.sh:1915`, `test/scripts/build-loop-merge.bats:223-247`, `$LOGS/merge-bats.log`

---

## Claim 5: "then the message reads "(build-loop approved merge)" with a second trailer "Build-loop-approved: Q-NNN", and the reflog "build-loop: approved merge of STEM""

**Location:** `scripts/build-loop.sh:232-234`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit message, both trailers and the update-ref reflog on the compare-and-swap path; does not establish the reflog text on the merge --ff-only-in-W path by execution (static: the same `msg` is passed as GIT_REFLOG_ACTION, to which git appends ": Fast-forward" as the header already says).

```bash
# scripts/build-loop.sh:1101-1103
  local ... what="$1" msg
  [[ "$1" != approved ]] || what="approved merge"
  msg="build-loop: $what of ${VERDICT[stem]}"
# scripts/build-loop.sh:1168-1169
  { printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "$what" "${VERDICT[stem]}"
    [[ -z "${2-}" ]] || printf 'Build-loop-approved: %s\n' "$2"; } > "$GATE_TMP/msg" \
```

Under self-merge the merge arm passes `"$APPROVED"`, which is empty, so no second trailer is written (`scripts/build-loop.sh:1217`). Executed: R1's test 8 asserts the exact `%B` and `%gs` texts. ok.

**Evidence:** `scripts/build-loop.sh:1100-1104`, `scripts/build-loop.sh:1168-1178`, `scripts/build-loop.sh:1217`, `test/scripts/build-loop-merge.bats:194-206`, `$LOGS/merge-bats.log`

---

## Claim 6: "or refuse BRIEF: WHY ... when: without --approved, the policy --status reads is review; with it, Q-NNN is open, skipped (WHY quotes the skip) or not answered with option 1, or its heading is not the one above"

**Location:** `scripts/build-loop.sh:240-243`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mapping from check_answer's output (open, skip, keep, and the other words drop/done/unrecognized) to approval()'s refusals and the policy refusal's condition; does not establish the ordering against land's later refusals (approval runs first, which the list does not claim either way).

```bash
# scripts/build-loop.sh:1076-1081
  case "$r" in
    "keep $1") ;;
    "open $1") MERGE_WHY="$1 does not approve this merge: it is not answered on the default branch"; return 1 ;;
    "skip $1: "*) MERGE_WHY="$1 does not approve this merge: ${r#"skip $1: "}"; return 1 ;;
    *) MERGE_WHY="$1 does not approve this merge: its answer on the default branch is not option 1"; return 1 ;;
  esac
```

Executed: R1's test 10 covers [2], [3], OPEN, a working-tree-only answer, a missing entry (the skip text quoted: "no such entry in docs/working/questions.md or questions-archive.md on the default branch") and five wrong headings. ok.

**Evidence:** `scripts/build-loop.sh:1070-1084`, `scripts/build-loop.sh:1215-1217`, `test/scripts/build-loop-merge.bats:223-235`, `$LOGS/merge-bats.log`

---

## Claim 7: "VERDICT holds tip, tree, policy, branch, stem and gate (1 when a changed path, lower-cased, is the gate's own code, GATE_CODE; else empty) ... only after an ok line (both empty otherwise)"

**Location:** `scripts/build-loop.sh:963-966`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how gc is set and copied into VERDICT only in verdict_ok, and that VERDICT is reset at check_line's start; does not establish that gc is meaningful on a refused verdict (it is never exposed there).

```bash
# scripts/build-loop.sh:976-977
  local a="$1" ... gc="" sm="" ...
  VERDICT=(); CHANGED=()
# scripts/build-loop.sh:1031
    VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem" [gate]="$gc")
```

gc is set at `:1041` from `lps`, which is lower-cased. On the no-changed-path branch (`:1035`), gc stays empty.

**Evidence:** `scripts/build-loop.sh:974-1046`

---

## Claim 8: "AUTH ... decides the rules: empty for --check and self-merge for --merge, where a brief --status reads as self-merge gets the S rules and its checkout checked; approved (--merge --approved) runs the N rules alone, whatever the policy" (and: --check behaves as before)

**Location:** `scripts/build-loop.sh:967-970`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that sm equals the old `pol == self-merge` test whenever AUTH is not approved, so --check (AUTH empty) and plain --merge decide as before; does not establish that the "where" clause is meant for --merge alone (the code gives the S rules to self-merge briefs under --check too, the natural reading).

```bash
# scripts/build-loop.sh:968-970 (comment), :971, :982, :1209
AUTH=""
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
    AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved
```

The three old `"$pol" == self-merge` tests became `-n "$sm"` / `-z "$sm"` (`:1024`, `:1027`, `:1042`). Executed: R2's full build-loop-check.bats (146 tests, the --check contract) passed, and R1's pre-existing U3a2 tests 1-7 passed.

**Evidence:** `scripts/build-loop.sh:960-1046`, `scripts/build-loop.sh:1208-1220`, `$LOGS/check-bats.log`, `$LOGS/merge-bats.log`

---

## Claim 9: "approval Q-NNN: whether the questions entry Q-NNN, read from main's commit by check_answer ... approves landing VERDICT: answered with option 1 under the heading ... exactly, so an answer for another brief, an older tip or a merge without the gate's code does not carry. Sets MERGE_WHY and returns 1 when it does not."

**Location:** `scripts/build-loop.sh:1063-1069`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers approval()'s whole body (signature to final line) and its return values; does not establish that MERGE_WHY is cleared on success (it is not touched; land clears it on entry, `:1104`).

The full function is at `scripts/build-loop.sh:1070-1084`, quoted in Claims 4 and 6. Its final statement `[[ "$ANSWER_HEAD" == "$1 · $s" ]] || { MERGE_WHY=...; return 1; }` returns 0 on a match. Executed: R1's tests 8, 10 and 11.

**Evidence:** `scripts/build-loop.sh:1063-1084`, `$LOGS/merge-bats.log`

---

## Claim 10: "In this shell, to a file: ANSWER_HEAD would not leave a $(...)."

**Location:** `scripts/build-loop.sh:1074`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bash semantics (a command substitution runs in a subshell, so its variable assignments are lost) and that GATE_TMP exists in merge mode; does not establish anything about the file's cleanup beyond gate_start's EXIT trap.

```bash
# scripts/build-loop.sh:1075
  check_answer "$1" > "$GATE_TMP/answer"; r="$(cat "$GATE_TMP/answer")"
# scripts/build-loop.sh:944
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
```

gate_start runs before approval in the merge arm (`:1210`).

**Evidence:** `scripts/build-loop.sh:942-949`, `scripts/build-loop.sh:1074-1075`, `scripts/build-loop.sh:1210`

---

## Claim 11: "land AUTHORITY [Q-NNN]: ... once check_line printed ok (VERDICT) under the authority the caller checked and names ... Decide (the header's refusals but policy and --check's ..."

**Location:** `scripts/build-loop.sh:1085-1088`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what land decides compared with the header's refusal list as it now reads; does not establish any behavior change (none: the comment's scope is the only issue).

The header's refusal list now opens with "without --approved, the policy --status reads is review; with it, Q-NNN is open, skipped ... or its heading is not the one above" (`scripts/build-loop.sh:241-243`). land does not decide the Q-NNN refusals; approval() does, before land is called:

```bash
# scripts/build-loop.sh:1216-1217
    elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"; then v="refuse $a: $MERGE_WHY"
    elif land "$AUTH" "$APPROVED"; then ...
```

"but policy" is accurate only if "policy" is read as covering the whole new clause. A precise version would read "the header's refusals but the policy or approval ones and --check's".

**Evidence:** `scripts/build-loop.sh:241-243`, `scripts/build-loop.sh:1085-1099`, `scripts/build-loop.sh:1215-1217`

---

## Claim 12: "the review-policy refusal now names --approved (row 661)" (commit a7a4f784; code text)

**Location:** `scripts/build-loop.sh:1215`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal text and its condition; does not establish anything about other refusals' wording.

```bash
# scripts/build-loop.sh:1215
    if [[ "$AUTH" == self-merge && "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; --merge lands it only with --approved Q-NNN"
```

Executed: R1's U3a2 test asserting the new text (`test/scripts/build-loop-merge.bats:82`) passed.

**Evidence:** `scripts/build-loop.sh:1215`, `test/scripts/build-loop-merge.bats:82`, `$LOGS/merge-bats.log`

---

## Claim 13: "truthwalk sets TRUTH_WHERE ..., so check_fix no longer repeats the reader-settings sentence (rows 630, 634)" (commit a7a4f784; dev-cycle.sh check_fix)

**Location:** `scripts/dev-cycle.sh:186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that check_fix's reader-settings sentence now comes only from walk_why through TRUTH_WHERE, so the text is identical when IMPORT_READER_WHY is set; does not establish that output is otherwise unchanged. It is not: a readers failure without IMPORT_READER_WHY now adds walk_why's registry sentence, which the old code omitted (a deliberate widening per rows 630/634, not claimed either way).

```bash
# scripts/dev-cycle.sh:186
    if [[ "$TRUTH_WHY" == walk ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out${TRUTH_WHERE:+: $TRUTH_WHERE}; file it instead"
```

Executed: the new build-loop-check.bats test (R2) asserts `tree [walk] the reader settings of docs/dev-cycle.md cannot be used: planted`. R5, with `CLAUDE_CONFIG_DIR=relative`: main's script printed "...cannot be ruled out; file it instead". a7a4f784's printed "...cannot be ruled out: the worktree registry could not be read, or a reader root, home or CLAUDE_CONFIG_DIR is not a usable absolute path; file it instead". R3 (dev-cycle.bats, 79 tests) passed.

**Evidence:** `scripts/dev-cycle.sh:174-189`, `test/scripts/build-loop-check.bats:1532-1542`, `$LOGS/check-bats.log`, `$LOGS/probe-fix.log`, `$LOGS/devcycle-bats.log`

---

## Claim 14: "The tree walk's IMPORTED_WHY is readers when import_readers fails, else empty (its other failures are not told apart)" (including the cached-failure path)

**Location:** `scripts/lib/dev-cycle-read.sh:804-805`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every assignment of IMPORTED_WHY in imported_names (read in full, `:1628-1700`) and the cache-hit path; does not establish its value before the first walk in a process (the global initializer sets it empty, `:806`).

```bash
# scripts/lib/dev-cycle-read.sh:1632
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; IMPORTED_WHY=readers; return 1; }
# scripts/lib/dev-cycle-read.sh:1634
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && { [[ "$IMPORTED" != error ]]; return; }
# scripts/lib/dev-cycle-read.sh:1636
  IMPORTED_DONE="..."; IMPORTED=error; IMPORTED_WHY=""
```

A readers failure clears IMPORTED_DONE, so the next call never takes the cache hit. It reruns import_readers, whose memoized refusal returns 1 again (`:1162`), and sets readers again. A later-stage failure leaves IMPORTED_WHY empty from `:1636`, and a cache hit on that failure keeps it. grep shows no other assignment.

**Evidence:** `scripts/lib/dev-cycle-read.sh:806`, `scripts/lib/dev-cycle-read.sh:1154-1163`, `scripts/lib/dev-cycle-read.sh:1628-1700`

---

## Claim 15: "walk_why WHY: the sentence for an IMPORTED_MAIN_WHY word"

**Location:** `scripts/lib/dev-cycle-read.sh:807`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers walk_why's documented input against its callers after this diff; does not establish any output difference (the readers word produces the same sentence for either walk).

This diff adds a second input. truthwalk now passes the tree walk's word too:

```bash
# scripts/lib/dev-cycle-read.sh:1893
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
```

A precise version would read "the sentence for an IMPORTED_MAIN_WHY or IMPORTED_WHY word". The line itself is unchanged by the diff, but the new caller makes it narrower than its use.

**Evidence:** `scripts/lib/dev-cycle-read.sh:807-830`, `scripts/lib/dev-cycle-read.sh:1893`

---

## Claim 16: "Returns 0 when the walk fails (TRUTH_WHY=walk, with TRUTH_WHERE walk_why's sentence for where, or empty when the walk does not say: rows 630, 634)"

**Location:** `scripts/lib/dev-cycle-read.sh:1883-1884`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truthwalk's whole body: both walks' failure arms, TRUTH_WHERE emptied at entry, and the unknown-WALK arm (empty TRUTH_WHERE); does not establish that IMPORTED_MAIN_WHY is non-empty on every main failure (the main walk sets its KIND before each stage, per its own comment, which was not re-audited here).

```bash
# scripts/lib/dev-cycle-read.sh:1889-1899
truthwalk() {
  TRUTH_WHY=walk; TRUTH_WHERE=""
  case "$1" in
    main) main_imports || { TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"; return 0; } ;;
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
    *) return 0 ;;
  esac
  TRUTH_WHY=imported
  [[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]] && ! walk_has "$1" "$2" || return 0
  TRUTH_WHY=""; return 1
}
```

Executed: the new test "floor sets a word ... for both walks" (R2) passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1878-1899`, `test/scripts/build-loop-check.bats:1532-1542`, `$LOGS/check-bats.log`

---

## Claim 17: "Returns 0 with FLOOR_WHY set to a word when the floor refuses (floor_why words it: row 472; gate is the gate's own code, which a caller can test), else 1"

**Location:** `scripts/lib/dev-cycle-read.sh:1924-1925`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every FLOOR_WHY assignment in floor (read in full, `:1940-1958`), each having a floor_why arm, and that the words reproduce the old sentences (settings maps to cycle, as the old `*` arm did); does not establish that any caller currently tests the gate word (none does: check_line tests GATE_CODE directly; the comment claims only that one can).

```bash
# scripts/lib/dev-cycle-read.sh:1943-1949
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY=case; return 0; }
  if truthrule "$lp"; then FLOOR_WHY="$TRUTH_WHY"; [[ "$FLOOR_WHY" != settings ]] || FLOOR_WHY=cycle
  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate
  ...
  elif truthwalk main "$lp"; then FLOOR_WHY="$TRUTH_WHY"  # walk (TRUTH_WHERE says where) or imported
```

truthrule's words are case, instr, dot, cycle, settings, user, record (`:1869-1876`). The words set here are case, instr, dot, cycle, user, record, gate, working, review, walk, imported and below. floor_why has an arm for each (`:1962-1978`). Executed: R2's floor tests, rewritten to print `$(floor_why "$FLOOR_WHY")` against the old expected sentences, passed. The new test prints `[gate]`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1867-1878`, `scripts/lib/dev-cycle-read.sh:1938-1979`, `$LOGS/check-bats.log`

---

## Claim 18: "a call given $4 that both of main_imports' caches answer ... forks nothing but walk_why's subshell (truthwalk's) after a failed walk"

**Location:** `scripts/lib/dev-cycle-read.sh:1932-1935`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the only `$(...)` inside floor's call tree on a cached path is truthwalk's walk_why on a failed main walk (floor's own lower runs only without $4); does not establish the fork-freedom of the unchanged helpers (isstart, writable, ownfile, walk_has) beyond reading them for `$(`, and floor_why's subshell in srules is the caller's, outside floor.

The walk_why fork moved from floor's old `$(walk_why "$IMPORTED_MAIN_WHY")` into truthwalk (`:1892`, quoted in Claim 16), and only on main_imports failure. floor's remaining `$(...)` is `lp="$(lower "$1")"`, reached only when `$4` is empty (`:1943`). The existing no-fork test (`test/scripts/build-loop-check.bats:1390-1398`, shims for tr and pwd) passed in R2. It covers the success path, not the failed-walk path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1889-1899`, `scripts/lib/dev-cycle-read.sh:1932-1958`, `$LOGS/check-bats.log`

---

## Claim 19: "floor_why WORD: the sentence for a FLOOR_WHY word ...; walk reads TRUTH_WHERE, so word it before the next truthwalk."

**Location:** `scripts/lib/dev-cycle-read.sh:1959-1961`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers floor_why's walk arm reading the global TRUTH_WHERE and the only production caller wording it right after floor; does not establish anything about callers outside build-loop.sh srules and the tests.

```bash
# scripts/lib/dev-cycle-read.sh:1973
    walk) echo "the default branch's instruction files could not be walked for @ imports: $TRUTH_WHERE" ;;
# scripts/build-loop.sh:831
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$(floor_why "$FLOOR_WHY")"; return 0; fi
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:1959-1979`, `scripts/build-loop.sh:828-842`

---

## Claim 20: ANSWER_AWK prints the heading as a second line only in the single-entry case

**Location:** `scripts/lib/dev-cycle-read.sh:2028`, `scripts/lib/dev-cycle-read.sh:2057`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the END block's branches (odd, unbalanced, quoted, dup print one line; only `count` == 1 prints head) and head captured from the first matching heading after the CR strip; does not establish anything about other ANSWER_AWK consumers (grep: check_answer is the only one).

```awk
# scripts/lib/dev-cycle-read.sh:2026-2028
{ sub(/\r$/, "") }
...
heading($0) { count++; inside = (count == 1); header = 0; if (inside) head = substr($0, 5); next }
# scripts/lib/dev-cycle-read.sh:2053-2057
  if (odd) print "odd " odd " " oddwhy
  ...
  else if (count > 1) print "dup"
  else if (count) { print (...); print head }
```

Executed: R4's Q-005 (two headings) gave `skip ...: more than one entry` and ANSWER_HEAD empty.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2005-2058`, `$LOGS/probe-answer.log`

---

## Claim 21: "With an answer line it sets ANSWER_HEAD to the entry's heading after "### " ("Q-NNN · SLUG", CR dropped), else empties it; a caller that reads it (build-loop.sh --approved) calls check_answer in its own shell, its output to a file."

**Location:** `scripts/lib/dev-cycle-read.sh:2064-2067`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that ANSWER_HEAD is set whenever check_answer prints a keep/drop/done/open/unrecognized line, emptied at entry so every skip leaves it empty, and that CR is stripped; does not establish the reading "an entry holding an answer line": an OPEN entry with no answer also sets it (harmless for approval, which refuses open first).

```bash
# scripts/lib/dev-cycle-read.sh:2072
  ANSWER_HEAD=""
# scripts/lib/dev-cycle-read.sh:2093-2095
    hit="${r%%$'\n'*}"; head="${r#*$'\n'}"; where="$f"
  done
  if [[ -n "$hit" ]]; then ANSWER_HEAD="$head"; echo "$hit $a"
```

Executed (R4): Q-001 with CRLF line endings gave `ANSWER_HEAD=$'Q-001 \302\267 merge-a'` (no CR). Q-002 OPEN gave its heading. Q-003 (bare `### Q-003`) gave `Q-003`. Q-006 from the archive kept its trailing blanks. Q-005 dup and Q-007 missing gave empty. A skip after a keep gave empty.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2059-2097`, `$LOGS/probe-answer.log`

---

## Claim 22: dev-cycle.sh --check-answer output is unchanged

**Location:** `scripts/lib/dev-cycle-read.sh:2095`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identical stdout for keep, open, drop, unrecognized, dup, an archive entry (done), a missing entry and a non-ID, CRLF included; does not establish the odd/unbalanced/quoted file-level skips by execution (static: those return before `hit` is set, unchanged).

`hit` takes only the first line of the awk output (`:2093`), so the printed `"$hit $a"` matches the old single-line `"$r $a"`. R4 ran main's and a7a4f784's dev-cycle.sh on the same fixture with `--check-answer Q-001 ... Q-007 bad`: diff reported `SAME`. R3 (dev-cycle.bats) passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2076-2097`, `$LOGS/probe-answer.log`, `$LOGS/devcycle-bats.log`

---

## Claim 23: "truthwalk sets TRUTH_WHERE for both walks' failures" (commit a7a4f784)

**Location:** `scripts/lib/dev-cycle-read.sh:1893` (commit a7a4f784 message, "Lib:" paragraph)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree arm's condition; does not establish anything wrong with the code, whose own comment ("or empty when the walk does not say") is precise.

For the tree walk, TRUTH_WHERE is set only when IMPORTED_WHY is non-empty, which is only on an import_readers failure (Claim 14):

```bash
# scripts/lib/dev-cycle-read.sh:1893
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
```

Every other tree-walk failure (list, seeds, budget and the rest) leaves TRUTH_WHERE empty. A precise version would read "for the main walk's failures and the tree walk's reader-settings failure".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1628-1636`, `scripts/lib/dev-cycle-read.sh:1889-1899`

---

## Claim 24: "--approved is refused with --check (plan names it only for --merge)" (commit a7a4f784 Notes)

**Location:** `scripts/build-loop.sh:312-315` (commit a7a4f784 message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's usage exit (status 1) for --approved under --check, a lower-case ID, a repeat and a missing value; does not establish anything about --approved placed before the mode (the first argument must be the mode, so it hits "Unknown option").

```bash
# scripts/build-loop.sh:312-315
      elif [[ "$1" == --approved ]]; then
        [[ "$MODE" == merge ]] || usage "--approved goes with --merge"
        [[ $# -ge 2 && -z "$APPROVED" && "$2" =~ ^Q-[0123456789]+$ ]] || usage "--approved takes one question ID (Q- and digits), given once"
        APPROVED="$2"; shift 2
```

Executed: R1's test 12 passed.

**Evidence:** `scripts/build-loop.sh:299-322`, `test/scripts/build-loop-merge.bats:249-255`, `$LOGS/merge-bats.log`

---

## Claim 25: "exact-slug match (merge-gate- on a merge without gate code refuses)" (commit a7a4f784 Notes)

**Location:** `scripts/build-loop.sh:1072-1083` (commit a7a4f784 message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge-gate- slug refused when VERDICT[gate] is empty; does not establish anything beyond Claim 4.

The expected slug is merge- unless VERDICT[gate] is set, and the compare is exact (quoted in Claim 4). Executed: R1's test 10 loops over `merge-gate-2026-10-01-x-${T:0:12}` on a gate-free merge and gets "approves no merge of this tip". ok.

**Evidence:** `scripts/build-loop.sh:1070-1084`, `test/scripts/build-loop-merge.bats:232-234`, `$LOGS/merge-bats.log`

---

## Claim 26: "Red until the --approved code lands." (commit 18f32952)

**Location:** `test/scripts/build-loop-merge.bats:175-255` (commit 18f32952 message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five new U3a3 tests at 18f32952 (all fail) and at a7a4f784 (all pass); does not establish anything about the build-loop-check.bats test, which a7a4f784 added and 18f32952 does not contain.

R6 ran the U3a3 tests from 18f32952's tree (`git archive 18f32952 scripts test`): `not ok 1` through `not ok 5`, exit 1. R1 at a7a4f784: all 12 ok.

**Evidence:** `test/scripts/build-loop-merge.bats:175-255`, `$LOGS/at18-merge.log`, `$LOGS/merge-bats.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:213-214`): the --merge paragraph still opens "lands a self-merge brief ... --check's lines". With --approved it lands either policy, and a self-merge brief's path lines lack the S denies --check would print.
- **Claim 11** (`scripts/build-loop.sh:1087-1088`): land's "Decide (the header's refusals but policy and --check's" should also exclude the new Q-NNN approval refusals, which approval() decides before land.
- **Claim 15** (`scripts/lib/dev-cycle-read.sh:807`): walk_why's comment names only IMPORTED_MAIN_WHY. truthwalk now also passes the tree walk's IMPORTED_WHY.
- **Claim 23** (commit a7a4f784, "Lib:" paragraph): "TRUTH_WHERE for both walks' failures" holds for the tree walk only on an import_readers failure. Its other failures leave TRUTH_WHERE empty.

### Unverifiable
(none)

---

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/code-fact-check-report-u3a3-i1.md in the code-fact-check skill's format, with `Commit: a7a4f784` and `**Replication:** k=1 (loop pass, decision 031)` in its header."

This report is at that path and in the skill's format. Its header carries `**Commit:** a7a4f784` and `**Replication:** k=1 (loop pass, decision 031)`. The report covers the brief's eight focus claims: claim group 1 → Claims 2-5; group 2 → 6; group 3 → 7-8; group 4 → 9-10; group 5 → 20-22; group 6 → 14, 16; group 7 → 17-19; group 8 → 12, 13, 23-26. It adds three adjacent comments that the diff made narrower (Claims 1, 11, 15). No code or behavior defect was found. All four findings are comment or commit-text precision issues. Execution logs are in the scratch dir, not docs/reviews/execution-logs/, because the brief forbids writing elsewhere. No hallucination-pattern entry was added: there are no Incorrect verdicts.
