Commit: e25a6e89

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a3 (branch feat/build-loop-u3a3)
**Scope:** `git diff a7a4f784..HEAD` (the iteration-1 fix commit e25a6e89 only): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-merge.bats`, and e25a6e89's commit message. PARTIAL SCOPE: 18f32952 (tests) and a7a4f784 (code) are on the branch, were reviewed in iteration 1, and are read here as context only. Review artifacts added by e25a6e89 (docs/reviews/*-i1.md, the rubric) are checked only where the commit message counts them (override rows).
**Checked:** 2026-10-10
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 14
**Summary:** 13 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries, all measured-count or file-association fabrications). No claim here matches a logged pattern. The one count claim (Claim 14, "9 override-log rows") was recounted from the diff.

## Execution log

All runs used cwd `/workspace/.claude/wt-build-loop-u3a3` unless noted. Every run was under `timeout`, and no process was left running (`ps` showed no bats afterwards). Captured output is in `$FC` = `/tmp/claude-1000/-workspace/675070f9-0197-40a3-bd3c-520157521989/scratchpad/u3a3-i2/fc/` (the brief allows writes only there and to this report, so the logs are not under docs/reviews/execution-logs/).

| ID | Command | Timestamp (UTC) | Exit | Output |
|---|---|---|---|---|
| E1 | `timeout 900 bats test/scripts/build-loop-merge.bats` (serial) | 2026-10-10T23:37:06Z | 0 (12/12 ok) | `$FC/merge-bats.out` |
| E2 | `timeout 600 bats -f floor test/scripts/build-loop-check.bats` | 2026-10-10T23:37:26Z | 0 (9/9 ok) | `$FC/check-floor-bats.out` |
| E3 | `timeout 590 bats test/scripts/build-loop-check.bats` (serial, full suite) | 2026-10-10T23:39:33Z | 0 (146 ok, 0 not ok) | `$FC/check-bats.out` |
| E4 | `timeout 590 bats -f answer test/scripts/dev-cycle.bats` | 2026-10-10T23:40:41Z | 0 (13/13 ok) | `$FC/dc-answer-bats.out` |
| P1 | cwd `$FC/repo` (fresh one-commit repo): `timeout 60 env LC_ALL=C bash $FC/floorprobe.sh <worktree>/scripts/lib/dev-cycle-read.sh skills/dev-cycle/references/x.md skills/dev-cycle/SKILL.md Skills/Dev-Cycle/x.md skills/dev-cycle-x/a.md skills/x/helper.md` (sources the lib, runs `floor PATH 2026-10-01-x M` and prints FLOOR_WHY plus floor_why) | 2026-10-10T23:37:01Z | 0 | `$FC/floorprobe.out` |
| P2 | cwd `$FC/arepo` (fixture questions.md on main: Q-001 ANSWERED `[1]`, Q-002 ANSWERED with no answer line, Q-003 OPEN): `timeout 60 env TMPF=$FC/ans.tmp LC_ALL=C bash $FC/answerprobe.sh <worktree>/scripts/lib/dev-cycle-read.sh` (under `set -euo pipefail`, ROOT_REAL unset; check_answer to a file, then prints ANSWER_HEADING; ends `echo reached-end`) | 2026-10-10T23:38:40Z | 0 | `$FC/answerprobe.out` |

P1 output: `skills/dev-cycle/references/x.md: gate`, `skills/dev-cycle/SKILL.md: instr`, `Skills/Dev-Cycle/x.md: gate`, `skills/dev-cycle-x/a.md: -`, `skills/x/helper.md: -`.
P2 output: `keep Q-001 | HEADING=[Q-001 · merge-x-abc]`, `unrecognized Q-002 | HEADING=[Q-002 · merge-y]`, `open Q-003 | HEADING=[Q-003 · merge-z]`, `skip Q-009: no such entry ... | HEADING=[]`, `reached-end`.

---

## Claim 1: "--merge lands a self-merge brief (D7), or with --approved a brief of either policy: --check's lines for BRIEF at --expect's tip (under --approved, the N rules' lines only)"

**Location:** `scripts/build-loop.sh:213-216`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which check_line output lines appear under --approved: no S-rule deny lines and no checkout refusal. Does not establish that only N-rule lines print: check_line's refusals before the per-path loop (brief not open, branch absent or not ahead, tip not the expected one, conflicts, unreadable diff, object-store checks) print under --approved as they do under --check.
**Legibility-target:** for-author

Under --approved, check_line leaves `sm` empty, so neither the checkout gate nor srules runs:

```bash
# scripts/build-loop.sh:988
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
# scripts/build-loop.sh:1029
  co=""; if [[ -n "$sm" ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs ..."; fi
# scripts/build-loop.sh:1046-1048
    nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"
    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
    [[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"
```

The refusals that come before the loop do not depend on AUTH, for example `if [[ "$st" != open ]]; then echo "refuse $a: the brief is $st on the default branch; only an open brief merges"; return; fi` (`scripts/build-loop.sh:989`) and the --expect mismatch at `:992`. The header defines "the N rules" as the deny rules for a path (`:176`, "The N rules, under either policy: a path pathform refuses ..."), so "the N rules' lines only", read literally, leaves those refusals out, but they still print. A more precise version: "(under --approved, without the S rules or the checkout refusal)". The header's later sentence, "under the N rules alone (no S rules, no checkout rule)" (`:225-226`), already says it that way. Executed: E1's test "--merge --approved lands ... the questions archive" checks that under --approved, N-rule deny lines replace the verdict (`deny $B A docs/roadmap.md: one of the dev cycle's own files`, `deny $B A docs/working/questions-archive.md: ...`) and that no S-rule refusal appears. All 12 tests pass.

**Evidence:** `scripts/build-loop.sh:176`, `scripts/build-loop.sh:213-226`, `scripts/build-loop.sh:978-1052`, `test/scripts/build-loop-merge.bats:213-226`, `$FC/merge-bats.out`

---

## Claim 2: "... is the gate's own code (scripts/build-loop.sh, dev-cycle.sh, questions.sh, anything under scripts/lib/ or skills/dev-cycle/)"

**Location:** `scripts/build-loop.sh:231-233`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header's list against GATE_CODE and its lower-cased use in check_line to set VERDICT[gate]. Does not establish that the list matches every file D6's snippet copies (U3b's), or what other docs in the repo say about the gate list.
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:1923
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'
```

check_line tests the lower-cased path: `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`scripts/build-loop.sh:1047`), and verdict_ok stores it as `[gate]="$gc"` (`:1036`). Each alternative is anchored with `^`, and `skills/dev-cycle/` ends in a slash, so `skills/dev-cycle-x/a.md` does not match (P1 printed `-` for it under floor, which uses the same regex). Executed: E1 test 11 runs `scripts/build-loop.sh`, `Scripts/Lib/x.sh` and `skills/dev-cycle/references/x.md`, and each refuses with `its heading must read "Q-001 · merge-gate-..." (the merge changes the gate's own code)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1923`, `scripts/build-loop.sh:1036`, `scripts/build-loop.sh:1047`, `test/scripts/build-loop-merge.bats:241-250`, `$FC/merge-bats.out`, `$FC/floorprobe.out`

---

## Claim 3: "The heading pins only TIP's prefix: --expect binds the full tip, so the caller passes the full TIP it filed the entry for, never the branch's live tip"

**Location:** `scripts/build-loop.sh:233-235`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that --merge requires --expect, that --expect accepts only a full 40- or 64-hex id, that check_line refuses unless the tip equals it, and that approval compares only `${VERDICT[tip]:0:12}`. Does not establish that a caller does pass the TIP it filed the entry for, which is caller discipline deferred to U4 (override row, i1 security M1).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:316 and :324
        [[ "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage "--expect takes a full 40- or 64-hex commit id"
    [[ "$MODE" == check || ( -n "$EXPECT" && ${#ARGS[@]} -eq 1 ) ]] || usage "--merge takes one brief path and --expect SHA"
# scripts/build-loop.sh:992
  if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi
# scripts/build-loop.sh:1079
  s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"
```

VERDICT[tip] is `$sha`, which equals EXPECT by the time verdict_ok runs. The heading itself carries only 12 hex digits. The sentence is a correct description plus an instruction to the caller.

**Evidence:** `scripts/build-loop.sh:306-326`, `scripts/build-loop.sh:992`, `scripts/build-loop.sh:1036`, `scripts/build-loop.sh:1076-1091`

---

## Claim 4: "with it, Q-NNN is open, skipped (WHY quotes the skip) or answered with another option or an answer not read (WHY names which), or its heading is not the one above"

**Location:** `scripts/build-loop.sh:247-249`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers approval's case arms against every line check_answer can print (keep/drop/done/open/unrecognized followed by the ID, or `skip ID: ...`) and the heading comparison. Does not establish the wording of the skip reasons themselves (check_answer's, unchanged here). "An answer not read" also covers an ANSWERED entry that has no answer line at all (P2's Q-002 reads `unrecognized`).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:1082-1090
  case "$r" in
    "keep $1") ;;
    "open $1") MERGE_WHY="$1 does not approve this merge: it is not answered on the default branch"; return 1 ;;
    "skip $1: "*) MERGE_WHY="$1 does not approve this merge: ${r#"skip $1: "}"; return 1 ;;
    "drop $1") MERGE_WHY="$1 does not approve this merge: its answer on the default branch is option 2"; return 1 ;;
    "done $1") MERGE_WHY="$1 does not approve this merge: its answer on the default branch is option 3"; return 1 ;;
    *) MERGE_WHY="$1 does not approve this merge: its answer on the default branch is not read as an option ([1], 1 or keep approve)"; return 1 ;;
  esac
  [[ "$ANSWER_HEADING" == "$1 · $s" ]] \
```

check_answer prints `skip ...` lines or `echo "$hit $a"` (`scripts/lib/dev-cycle-read.sh:2105`), where `$hit` comes from ANSWER_AWK's END block: `print (!answered ? "open" : done ? result : "unrecognized")` (`:2059`). `result` is keep, drop, done or unrecognized (`option()`, `:2017-2032`). So the catch-all arm is reached only by `unrecognized ID`. Executed: E1 test 10 checks "option 2" for `Q-001: [2]`, "option 3" for `Q-001: [3]`, the not-read wording for `Q-001: merge`, the open wording, and the heading refusals. P2 shows that an ANSWERED entry without an answer line yields `unrecognized`.

**Evidence:** `scripts/build-loop.sh:1076-1091`, `scripts/lib/dev-cycle-read.sh:2017-2060`, `scripts/lib/dev-cycle-read.sh:2081-2107`, `test/scripts/build-loop-merge.bats:228-239`, `$FC/merge-bats.out`, `$FC/answerprobe.out`

---

## Claim 5: approval's not-read refusal names the options that approve: "([1], 1 or keep approve)"

**Location:** `scripts/build-loop.sh:1088`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the leading tokens that option() maps to keep. Does not establish the finer rules (case-insensitive, leading blanks and `*` stripped, and a word followed by the end, punctuation or a dash), which the message omits but which do not contradict it.
**Legibility-target:** for-author

```awk
# scripts/lib/dev-cycle-read.sh:2018-2020, 2026-2030
  s = tolower(span); sub(/^[ \t*]+/, "", s)
  if (substr(s, 1, 3) == "[1]") return "keep"
  ...
  if (w == "1" || w == "keep") return "keep"
```

Only `[1]`, `1` and `keep` lead to `keep`, and only `keep $1` passes approval's case.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2017-2032`, `scripts/build-loop.sh:1082-1089`

---

## Claim 6: "In this shell, to a file: ANSWER_HEADING would not leave a $(...)." and `r="$(< "$GATE_TMP/answer")"`

**Location:** `scripts/build-loop.sh:1080-1081`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that check_answer runs in approval's shell (redirected to a file, not in a command substitution), so ANSWER_HEADING is visible afterwards, and that `$(< FILE)` reads the same line `$(cat FILE)` did. Does not establish anything about GATE_TMP's creation (gate_start's, unchanged).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:1081
  check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"
```

Assignments made inside a `$(...)` subshell do not reach the parent. The redirect form keeps check_answer in the current shell. Both `$(< f)` and `$(cat f)` strip trailing newlines, so `r` is the same single line. Executed: P2 uses the same pattern (`check_answer "$q" > "$TMPF"; echo "$(< "$TMPF") ... $ANSWER_HEADING"`) and prints each entry's heading. E1 tests 8, 10 and 11 pass through this code.

**Evidence:** `scripts/build-loop.sh:1076-1091`, `$FC/answerprobe.out`, `$FC/merge-bats.out`

---

## Claim 7: land's comment "Decide (the header's refusals but the policy's, approval's and --check's: an ignored file at an added path counts, ...)"

**Location:** `scripts/build-loop.sh:1095-1097`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the review-policy refusal and approval's refusals are made by the merge case before land, and --check's by check_line, while land makes the rest (identity, worktrees, state, W checks, commit, move). Does not re-verify each refusal inside land, which was covered in iteration 1 and is unchanged here.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:1223-1225
    if [[ "$AUTH" == self-merge && "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; --merge lands it only with --approved Q-NNN"
    elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"; then v="refuse $a: $MERGE_WHY"
    elif land "$AUTH" "$APPROVED"; then v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"; else v="refuse $a: $MERGE_WHY"; fi
```

land itself contains no policy or approval test (paraphrased — no quote available because the claim is about the absence of code across land's body, `scripts/build-loop.sh:1108-1194`, which was read in full).

**Evidence:** `scripts/build-loop.sh:1093-1194`, `scripts/build-loop.sh:1216-1228`

---

## Claim 8: land keys the "Build-loop-approved" trailer on the authority, as it does the message (`[[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"`)

**Location:** `scripts/build-loop.sh:1176-1177`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the trailer, the message's "(build-loop approved merge)" and the reflog's "approved merge" all depend on `$1 == approved`, and that the merge case passes AUTH=approved exactly when APPROVED is set. Does not establish behavior for a direct call `land approved` with an empty `$2`, which no caller makes.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:1109-1111
  local x w="" ... what="$1" msg
  [[ "$1" != approved ]] || what="approved merge"
  msg="build-loop: $what of ${VERDICT[stem]}"
# scripts/build-loop.sh:1217
    AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved
```

Executed: E1 test 1 checks that the self-merge message ends at `Build-loop-gate: 2026-10-01-x` with no approved trailer (`test/scripts/build-loop-merge.bats:46-47`). Test 8 checks the approved message with both trailers and the reflog `build-loop: approved merge of 2026-10-01-x` (`:200-204`).

**Evidence:** `scripts/build-loop.sh:1108-1111`, `scripts/build-loop.sh:1176-1179`, `scripts/build-loop.sh:1217-1225`, `test/scripts/build-loop-merge.bats:46-49`, `test/scripts/build-loop-merge.bats:194-204`, `$FC/merge-bats.out`

---

## Claim 9: "A caller that also reads ANSWER_HEADING ... runs check_answer in its own shell, its output to a file under set -e, since a $(...) would drop the value; check_answer reaches no need_root (it reads only git objects), so nothing exits there."

**Location:** `scripts/lib/dev-cycle-read.sh:35-38`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's call graph (main_by_name, main_entry, pathform, entry_why, oddwhy, git cat-file, awk): none calls need_root, readers_root or a walk. Under `set -euo pipefail` with ROOT_REAL unset, it returns normally for keep, unrecognized, open and missing entries. Does not establish behavior when git itself is killed or missing (the guarded `|| { echo "skip ..." }` covers a failed read).
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:2081-2084
check_answer() {
  local - a="$1" f e r hit="" where="" n why head=""; set -o pipefail  # as brief_fields
  ANSWER_HEADING=""
  if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then echo "skip ...: not a question ID (Q- and digits)"; return; fi
# scripts/lib/dev-cycle-read.sh:330
main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }
```

main_entry runs only `main_by_name`, `pathform` and `git ls-tree` (`:346-364`), and every path ends in an `echo`. The need_root callers are inrepo, dirok, skipped, check_brief, readers_root and the walks (`:200-207`, `:429`, `:842`, `:1640`, `:1716`, `:1846`). None is reached from check_answer (paraphrased — no quote available because the claim covers absence of code: grep `need_root` hits none of check_answer's callees). Executed: P2 ran four IDs under `set -euo pipefail` with ROOT_REAL unset, outside any condition, and printed `reached-end`, exit 0. E4 test 12 ("check_answer reads git only: no ROOT_REAL needed") passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:14-38`, `scripts/lib/dev-cycle-read.sh:169-207`, `scripts/lib/dev-cycle-read.sh:330-381`, `scripts/lib/dev-cycle-read.sh:2081-2107`, `$FC/answerprobe.out`, `$FC/dc-answer-bats.out`

---

## Claim 10: "walk_why WHY: the sentence for an IMPORTED_MAIN_WHY word (or the tree walk's IMPORTED_WHY, which is only ever readers)"

**Location:** `scripts/lib/dev-cycle-read.sh:811-812`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every assignment to IMPORTED_WHY and walk_why's one call with it. Does not establish IMPORTED_MAIN_WHY's word set (unchanged here).
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:1637, 1641
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; IMPORTED_WHY=readers; return 1; }
  IMPORTED_DONE="..."; IMPORTED=error; IMPORTED_WHY=""
# scripts/lib/dev-cycle-read.sh:1898
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
```

The only other assignment is the initializer `IMPORTED_WHY=""` (`:810`). walk_why receives it only when it is non-empty, so only as `readers`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-834`, `scripts/lib/dev-cycle-read.sh:1633-1642`, `scripts/lib/dev-cycle-read.sh:1893-1902`

---

## Claim 11: "The dev-cycle skill counts too (plan D4, F52): it carries the D6 snippet that copies and runs the gate. One list for floor and build-loop.sh's --approved, which tests it on its own (floor does not run there)."

**Location:** `scripts/lib/dev-cycle-read.sh:1920-1923`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plan references (D4 line 61 lists `skills/dev-cycle/` as a gate file and cites F52; D6 says the snippet is inline in the installed SKILL.md), GATE_CODE's two consumers, and that floor does not run under --approved. Does not establish that U3b's snippet exists yet: D6's snippet is planned, not landed.
**Legibility-target:** for-author

Plan: "A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52)." (`docs/working/plan-build-loop-handoff.md:61`). "The snippet is inline in the installed SKILL.md" (`:77`). The only code that reads GATE_CODE is `elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate` (`scripts/lib/dev-cycle-read.sh:1955`) and `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`scripts/build-loop.sh:1047`); grep shows no other code hit. floor is reached only through srules (`scripts/build-loop.sh:837`), and srules runs only when `sm` is set, which --approved leaves empty (`:988`, `:1048`). check_line tests GATE_CODE on every run, but only approval reads VERDICT[gate]. So "on its own" means separately from floor, not only under --approved. Executed: E1 test 11 (skills/dev-cycle path needs merge-gate- under --approved). E2 and E3 confirm T10's floor lists still pass, since the pass list holds `skills/x/helper.md`, not a dev-cycle path.

**Evidence:** `docs/working/plan-build-loop-handoff.md:61`, `docs/working/plan-build-loop-handoff.md:77`, `docs/working/plan-build-loop-handoff.md:170`, `scripts/lib/dev-cycle-read.sh:1918-1923`, `scripts/lib/dev-cycle-read.sh:1950-1967`, `scripts/build-loop.sh:834-837`, `scripts/build-loop.sh:988`, `scripts/build-loop.sh:1046-1048`, `$FC/merge-bats.out`, `$FC/check-floor-bats.out`, `$FC/check-bats.out`

---

## Claim 12: floor's reworded comment: "Returns 0 with FLOOR_WHY set to a word when the floor refuses (floor_why words it: row 472), else 1. Its gate word is no test of whether a merge touches gate code (floor runs after the rules before it, and not at all under --approved): test GATE_CODE for that."

**Location:** `scripts/lib/dev-cycle-read.sh:1932-1935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's rule order (truthrule's words come before `gate`), the S-rule ordering in build-loop.sh (N rules and the brief's own file first, no floor under a checkout refusal), and that --approved never calls floor. Does not establish floor's non-gate words (unchanged, iteration 1).
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:1954-1955
  if truthrule "$lp"; then FLOOR_WHY="$TRUTH_WHY"; [[ "$FLOOR_WHY" != settings ]] || FLOOR_WHY=cycle
  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate
# scripts/build-loop.sh:837
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$(floor_why "$FLOOR_WHY")"; return 0; fi
```

Executed: in P1, `skills/dev-cycle/SKILL.md`, a gate-code path by GATE_CODE, got `instr`, not `gate`, because isstart's `^skill\.md$` (`:659`) runs first in truthrule. `skills/dev-cycle/references/x.md` got `gate`. The FLOOR_WHY word therefore undercounts gate code, as the comment warns.

**Evidence:** `scripts/lib/dev-cycle-read.sh:659`, `scripts/lib/dev-cycle-read.sh:1872-1883`, `scripts/lib/dev-cycle-read.sh:1925-1967`, `scripts/build-loop.sh:834-847`, `$FC/floorprobe.out`

---

## Claim 13: "ANSWER_HEADING" rename is complete (lib comment at :2075 "sets ANSWER_HEADING ...", the `shellcheck` note, approval's read)

**Location:** `scripts/lib/dev-cycle-read.sh:2075-2079`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no `ANSWER_HEAD` (old name) reference remains in code, tests or working docs. Does not re-verdict the comment's "With an answer line" wording, which is iteration 1's Claim 21 (Verified narrowly: an OPEN entry also sets the heading). That is unchanged here, and P2 reconfirms it (`open Q-003 | HEADING=[Q-003 · merge-z]`).
**Legibility-target:** for-author

`grep -rn -e GATE_CODE -e ANSWER_HEAD .` outside `docs/reviews/` and `.git/` finds no `ANSWER_HEAD` that is not `ANSWER_HEADING` (paraphrased — no quote available because the claim covers absence of code: zero grep hits). The remaining old-name hits are in the iteration-1 review artifacts, which are records.

**Evidence:** `scripts/lib/dev-cycle-read.sh:35`, `scripts/lib/dev-cycle-read.sh:2075-2084`, `scripts/lib/dev-cycle-read.sh:2105`, `scripts/build-loop.sh:1080`, `scripts/build-loop.sh:1090`, `$FC/answerprobe.out`

---

## Claim 14: commit e25a6e89's message: R1 "GATE_CODE gains ^skills/dev-cycle/ (plan D4, F52), so a change to the skill that carries the D6 snippet needs a merge-gate- slug under --approved; the floor refuses it under self-merge too (stricter than plan D5 item 3, which lists the scripts alone)"; A1, A2/A3, C2 and the comment-fix list; "Tests: option 2/3/unread, a skills/dev-cycle/ gate path, the questions archive N-denied under --approved"; "9 override-log rows (8 declined findings, 1 pre-existing flake)"

**Location:** commit e25a6e89 message (`git show e25a6e89`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change against the diff, the plan lines cited, the rubric's IDs, and the override-log rows added. Does not establish that the floor's new refusal of skills/dev-cycle/ under self-merge is pinned by a floor test: no build-loop-check.bats case names a skills/dev-cycle/ path (P1 shows the behavior). The skill's SKILL.md was already refused as `instr` before this commit, so the change is new only for its other files.
**Legibility-target:** for-author

Plan D5 item 3 lists "the gate's own code (`scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh`, `scripts/lib/dev-cycle-read.sh`)" (`docs/working/plan-build-loop-handoff.md:71`), the scripts alone, so "stricter" holds. Floor's refusal is shown by P1 (`skills/dev-cycle/references/x.md: gate`). A1: the header sentence at `scripts/build-loop.sh:233-235` (Claim 3), with an override row whose revisit trigger is U4. A2: the lib header sentence (Claim 9), plus the rename. A3: the trailer keyed on `$1` (Claim 8). C2: the option 2 / option 3 / not-read arms (Claim 4). Rubric C5 maps "fact-check 1, 11, 15" to the --merge opening line, land's Decide list and walk_why's comment, which are Claims 1, 7 and 10 here. Architecture F4 is floor's comment (Claim 12). The tests in the diff: `Q-001: [2]`, `[3]` and `merge` cases (`test/scripts/build-loop-merge.bats:229-231`), `skills/dev-cycle/references/x.md` in the gate loop (`:242`), and `docs/working/questions-archive.md` denied under --approved (`:218-225`). The override-log diff adds exactly 9 `+|` rows: i1 security M1, architecture F1/api F2, performance F1, api F4, api F5, api F7/architecture F6, architecture F7, security 3 (8 findings), and the config_seeds flake (1). Executed: E1 (12/12), E3 (146/146).

**Evidence:** `docs/working/plan-build-loop-handoff.md:61`, `docs/working/plan-build-loop-handoff.md:71`, `docs/reviews/override-log.md` (rows added in e25a6e89), `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a3.md`, `test/scripts/build-loop-merge.bats:213-250`, `$FC/merge-bats.out`, `$FC/check-bats.out`, `$FC/floorprobe.out`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:215`): "(under --approved, the N rules' lines only)" leaves out check_line's refusals that come before the per-path rules (brief not open, tip not expected, conflicts...), which still print under --approved. Precise version: "(under --approved, without the S rules or the checkout refusal)". Legibility-target: for-author.

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/code-fact-check-report-u3a3-i2.md in the code-fact-check skill's format, with `Commit: e25a6e89` and `**Replication:** k=1 (loop pass, decision 031)` in its header."

This report is saved at that path, opens with `Commit: e25a6e89`, carries the replication line in its header, and follows the skill's header, per-claim fields and attention-summary format. It covers all six claim groups the brief named (GATE_CODE and the floor; the header's --merge paragraph and refusal list; approval's refusals and `$(< FILE)`; land's trailer and Decide comment; the lib header, floor and walk_why comments; e25a6e89's message). Deviation: execution logs are in the scratch dir rather than docs/reviews/execution-logs/, as the brief restricts writes. No Incorrect verdict, so the hallucination-pattern log is unchanged. Nothing was committed.
