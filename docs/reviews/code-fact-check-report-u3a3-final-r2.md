Commit: 01a2935f

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a3 (branch feat/build-loop-u3a3)
**Scope:** `git diff main...HEAD`, the full branch (18f32952, a7a4f784, e25a6e89, 01a2935f): `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-merge.bats`, and the four commit messages. Review artifacts under docs/reviews/ are read only where a commit message counts them (override rows). Final confirming pass, replicate 2 of 3.
**Checked:** 2026-10-11
**Replication:** k=3 (final confirming pass; this is replicate r2)
**Total claims checked:** 28
**Summary:** 25 verified, 2 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries, all of them measured-count or file-association fabrications). No claim here matches a logged pattern. The one count claim (Claim 26, "9 override-log rows (8 declined findings, 1 pre-existing flake)") was recounted from the diff. The sibling replicates' reports (r1, r3, untracked in the worktree) were not read.

Reading rule: every enclosing function cited below (check_line, approval, land, the merge arm, check_fix, truthwalk, imported_names' head, floor, floor_why, walk_why, ANSWER_AWK, check_answer, main_entry, truthrule) was read from signature to final line.

## Execution log

All runs used cwd `/workspace/.claude/wt-build-loop-u3a3` unless noted. Every run was under `timeout`, bats ran serially (no `-j`), and no process outlived its run. `$FC` = `/tmp/claude-1000/-workspace/675070f9-0197-40a3-bd3c-520157521989/scratchpad/u3a3-final/fc2/`. The brief allows writes only there, so captured output is not under docs/reviews/execution-logs/.

| ID | Command | Timestamp (UTC) | Exit | Output |
|---|---|---|---|---|
| E1 | `timeout 900 bats test/scripts/build-loop-merge.bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` | 2026-10-10T23:55:03Z | 1 (235 ok, 2 not ok) | `$FC/bats.log` |
| E2 | `timeout 600 bats -f 'fast-forwards the worktree' test/scripts/build-loop-merge.bats` (E1's merge test 4, rerun) | 2026-10-10T23:59:45Z | 0 (1/1 ok) | `$FC/rerun-merge4.log` |
| E3 | `timeout 600 bats -f 'main walk fails closed when an instruction blob' test/scripts/build-loop-check.bats` (E1's check test 17, rerun) | 2026-10-10T23:59:45Z | 0 (1/1 ok) | `$FC/rerun-check17.log` |
| P1 | `timeout 300 bats $FC/probe/probe.bats`: fixtures loaded from the worktree's `test/lib/build-loop-fixtures.bash`, BL = the worktree's build-loop.sh. (A) an approved merge with main checked out (W); (B) `dev-cycle.sh --check-answer Q-001 Q-002`; (C) an approved merge whose questions.md on main is CRLF | 2026-10-11T00:00:46Z | 0 (3/3) | `$FC/probe.out` |
| P2 | cwd `$FC/at18` (`git archive 18f32952 scripts test`, extracted there): `timeout 600 bats $FC/at18/test/scripts/build-loop-merge.bats` | 2026-10-11T00:00:54Z | 1 (tests 3, 8-12 not ok) | `$FC/at18.out` |

E1's two failures are the known pre-existing flake the brief names, not this unit. Both failures show `find: '/tmp/tmp.…': No such file or directory` from config_seeds, a walk that failed closed when a /tmp sibling vanished (`$FC/bats.log`), and both pass when rerun alone (E2, E3).

P1 output: (A) `reflog=build-loop: approved merge of 2026-10-01-x: Fast-forward`, `msg=Merge branch 'feat/x' (build-loop approved merge)||Build-loop-gate: 2026-10-01-x|Build-loop-approved: Q-001||`. (B) `status=0 lines=2`, `line:[keep Q-001]`, `line:[skip Q-002: no such entry …]`. (C) `crlf status=0 first=merged …`.

---

## Claim 1: "scripts/build-loop.sh --merge BRIEF --expect SHA [--approved Q-NNN]" (usage), and --approved goes only with --merge

**Location:** `scripts/build-loop.sh:9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the usage line, `usage()`'s text and the argument loop's --approved arm. It does not establish argument orders beyond those the tests run.

```bash
# scripts/build-loop.sh:319-322
      elif [[ "$1" == --approved ]]; then
        [[ "$MODE" == merge ]] || usage "--approved goes with --merge"
        [[ $# -ge 2 && -z "$APPROVED" && "$2" =~ ^Q-[0123456789]+$ ]] || usage "--approved takes one question ID (Q- and digits), given once"
        APPROVED="$2"; shift 2
```

E1's merge test 12 rejects `--check … --approved`, `q-1`, a doubled --approved and a missing ID, each with exit 1 and main unmoved.

**Evidence:** `scripts/build-loop.sh:9`, `scripts/build-loop.sh:307-325`, `test/scripts/build-loop-merge.bats:632-638`, `$FC/bats.log`

---

## Claim 2: "--merge lands a self-merge brief (D7), or with --approved a brief of either policy: --check's lines for BRIEF at --expect's tip (under --approved, without the S rules or the checkout refusal; --expect still binds the tip)"

**Location:** `scripts/build-loop.sh:213-216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that `sm` (which gates the checkout gate, read_paths and srules) is empty under AUTH=approved for either policy, and that every other refusal in check_line (state, branch, ahead, expect, conflicts, diff, store) still runs. It does not establish anything about --check's output under --approved, because --approved is refused with --check.

```bash
# scripts/build-loop.sh:990
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
# scripts/build-loop.sh:993
  if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi
# scripts/build-loop.sh:1032, 1035, 1050
  co=""; if [[ -n "$sm" ]] && ! checkout_gate; then co="refuse $a: …"; fi
  [[ -z "$sm" ]] || read_paths
    [[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"
```

(These excerpts are from check_line, `:981-1055`, which I read in full.) E1's merge test 9 lands a self-merge brief past its never glob, its `Paths: none` and a checkout on feat/x under --approved. The same brief refuses on the checkout without --approved. Test 10 refuses a mismatched --expect under --approved.

**Evidence:** `scripts/build-loop.sh:981-1055`, `test/scripts/build-loop-merge.bats:583-613`, `$FC/bats.log`

---

## Claim 3: "With --approved Q-NNN it lands a brief of either policy under the N rules alone (no S rules, no checkout rule) when the questions entry Q-NNN, read from the default branch's commit as --check-answer reads it, is answered with option 1 under the heading exactly "### Q-NNN · merge-STEM-SHA12" (SHA12: TIP's first 12 hex digits), or "merge-gate-STEM-SHA12" when a changed path, lower-cased, is the gate's own code"

**Location:** `scripts/build-loop.sh:225-232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers approval's use of check_answer (the function dev-cycle.sh --check-answer calls), the keep-only arm, the literal heading comparison, the 12-hex prefix and the gate bit computed from the lower-cased paths of a --no-renames diff. It does not establish "exactly" byte for byte: a trailing CR on the heading line is dropped before the comparison (P1 C lands a CRLF questions file), as the lib comment says.

```bash
# scripts/build-loop.sh:1080-1093
  [[ -z "${VERDICT[gate]}" ]] || { s="merge-gate-"; g=" (the merge changes the gate's own code)"; }
  s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"
  …
  check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"
  case "$r" in
    "keep $1") ;;
  …
  [[ "$ANSWER_HEADING" == "$1 · $s" ]] \
```

(excerpt ends :1093; enclosing approval() ends at :1094 — read)

`gc` is set from the lower-cased path: `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`scripts/build-loop.sh:1049`). The diff is `diff-tree -r --no-renames` (`:1003`), so a renamed-away gate file counts too. `dev-cycle.sh:209` runs `--check-answer) check_answer "$a" ;;`. E1's tests 8, 10 and 11 cover landing, refusals and merge-gate- for `scripts/build-loop.sh`, `Scripts/Lib/x.sh` and `skills/dev-cycle/references/x.md`.

**Evidence:** `scripts/build-loop.sh:1003`, `scripts/build-loop.sh:1049`, `scripts/build-loop.sh:1078-1094`, `scripts/dev-cycle.sh:209`, `$FC/bats.log`, `$FC/probe.out`

---

## Claim 4: "(the lib's GATE_CODE: scripts/build-loop.sh, dev-cycle.sh, questions.sh, anything under scripts/lib/ or skills/dev-cycle/)"

**Location:** `scripts/build-loop.sh:232-234`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that the header's list matches the regex member for member ("dev-cycle.sh" and "questions.sh" are under scripts/). It does not establish anything about paths the floor refuses for other reasons.

```bash
# scripts/lib/dev-cycle-read.sh:1925
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'
```

**Evidence:** `scripts/build-loop.sh:232-234`, `scripts/lib/dev-cycle-read.sh:1925`

---

## Claim 5: "then the message reads "(build-loop approved merge)" with a second trailer "Build-loop-approved: Q-NNN", and the reflog "build-loop: approved merge of STEM""

**Location:** `scripts/build-loop.sh:234-237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the message, both trailers and the compare-and-swap reflog (test 8), plus the W path (P1 A). It does not establish that the sentence says ": Fast-forward" for W. It does not: git appends it under --approved too (P1 A: `build-loop: approved merge of 2026-10-01-x: Fast-forward`), as the earlier self-merge parenthetical says only for self-merge.

```bash
# scripts/build-loop.sh:1111-1112, 1178-1179
  [[ "$1" != approved ]] || what="approved merge"
  msg="build-loop: $what of ${VERDICT[stem]}"
  { printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "$what" "${VERDICT[stem]}"
    [[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"; } > "$GATE_TMP/msg" \
```

(excerpt from land(), `:1110-1194`, read in full)

**Evidence:** `scripts/build-loop.sh:1110-1194`, `test/scripts/build-loop-merge.bats:570-581`, `$FC/probe.out`

---

## Claim 6: "The heading pins only TIP's prefix: --expect binds the full tip, so the caller passes the full TIP it filed the entry for, never the branch's live tip."

**Location:** `scripts/build-loop.sh:237-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that approval compares only `${VERDICT[tip]:0:12}`, and that check_line refuses any tip other than the full 40/64-hex --expect, which --merge requires. It does not establish the caller-side discipline (U4, override row A1).

```bash
# scripts/build-loop.sh:325
    [[ "$MODE" == check || ( -n "$EXPECT" && ${#ARGS[@]} -eq 1 ) ]] || usage "--merge takes one brief path and --expect SHA"
```

The tip comparison is quoted in Claim 2 (`:993`). E1's test 10 runs `--expect "$M" --approved Q-001` and gets `refuse …: the tip of feat/x is $T, not the expected $M`.

**Evidence:** `scripts/build-loop.sh:325`, `scripts/build-loop.sh:993`, `scripts/build-loop.sh:1081`, `test/scripts/build-loop-merge.bats:611-613`, `$FC/bats.log`

---

## Claim 7: "when: without --approved, the policy --status reads is review; with it, Q-NNN is open, skipped (WHY quotes the skip) or answered with another option or an answer not read (WHY names which), or its heading is not the one above"

**Location:** `scripts/build-loop.sh:248-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the merge arm's policy refusal (reworded per row 661) and approval's case arms against every line check_answer prints (keep, drop, done, open or unrecognized plus the ID, or `skip ID: …`). It does not establish the skip reasons' own wording (check_answer's, unchanged).

```bash
# scripts/build-loop.sh:1225-1227
    if [[ "$AUTH" == self-merge && "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; --merge lands it only with --approved Q-NNN"
    elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"; then v="refuse $a: $MERGE_WHY"
    elif land "$AUTH" "$APPROVED"; then v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"; else v="refuse $a: $MERGE_WHY"; fi
# scripts/build-loop.sh:1085-1090
    "open $1") MERGE_WHY="$1 does not approve this merge: it is not answered on the default branch"; return 1 ;;
    "skip $1: "*) MERGE_WHY="$1 does not approve this merge: ${r#"skip $1: "}"; return 1 ;;
    "drop $1") … option 2 …   "done $1") … option 3 …
    *) MERGE_WHY="$1 does not approve this merge: its answer on the default branch is not read as an option ([1], 1 or keep approve)"; return 1 ;;
```

ANSWER_AWK's END prints `(!answered ? "open" : done ? result : "unrecognized")` (`scripts/lib/dev-cycle-read.sh:2069`), so the catch-all arm is reached only by `unrecognized`. E1's tests 3 and 10 check every wording.

**Evidence:** `scripts/build-loop.sh:1078-1094`, `scripts/build-loop.sh:1215-1230`, `scripts/lib/dev-cycle-read.sh:2069`, `$FC/bats.log`

---

## Claim 8: "VERDICT holds tip, tree, policy, branch, stem and gate (1 when a changed path, lower-cased, is the gate's own code, GATE_CODE; else empty) … AUTH … empty for --check and self-merge for --merge, where a brief --status reads as self-merge gets the S rules and its checkout checked; approved (--merge --approved) runs the N rules alone, whatever the policy."

**Location:** `scripts/build-loop.sh:971-978`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers verdict_ok's map, AUTH's three values (the global default `AUTH=""`, set only in the merge arm) and the `sm` rule, which leaves --check and plain --merge as they were. It does not establish anything about --status, which never runs check_line.

```bash
# scripts/build-loop.sh:980, 1038, 1216
AUTH=""
    VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem" [gate]="$gc")
    AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved
```

The `sm` line is quoted in Claim 2. The whole of build-loop-check.bats passes (E1, with the flake rerun in E3), which shows --check unchanged. Merge tests 1-7 show plain --merge unchanged.

**Evidence:** `scripts/build-loop.sh:971-1055`, `scripts/build-loop.sh:1216`, `$FC/bats.log`, `$FC/rerun-check17.log`

---

## Claim 9: approval's comment ("read from main's commit by check_answer … answered with option 1 under the heading … exactly, so an answer for another brief, an older tip or a merge without the gate's code does not carry. Sets MERGE_WHY and returns 1 when it does not.") and "In this shell, to a file: ANSWER_HEADING would not leave a $(...)."

**Location:** `scripts/build-loop.sh:1071-1077`, `scripts/build-loop.sh:1082`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the quoted (literal) comparison, the five refusal arms plus the heading arm, the implicit return 0 on a match, and that a `$(...)` subshell's assignment would be lost. It does not establish D8 beyond check_answer reading `$MAIN_SHA:$f` blobs.

The comparison `[[ "$ANSWER_HEADING" == "$1 · $s" ]]` (`:1092`) quotes its right side, so it is literal, not a glob. check_answer reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:2095`). E1's test 10 refuses another stem, an older tip prefix, merge-gate- on a non-gate merge, a trailing space and a suffix, and a working-tree-only answer.

**Evidence:** `scripts/build-loop.sh:1071-1094`, `scripts/lib/dev-cycle-read.sh:2082-2109`, `test/scripts/build-loop-merge.bats:603-618`, `$FC/bats.log`

---

## Claim 10: "land AUTHORITY [Q-NNN]: … under the authority the caller checked and names (self-merge, or approved with its question), which the message and reflog carry. Decide (the header's refusals but the policy's, approval's and --check's: …"

**Location:** `scripts/build-loop.sh:1095-1098`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that land checks none of the policy, approval or check_line refusals (the merge arm does those first) and puts `$1` in both message and reflog, and `$2` in the trailer only. It does not establish the reflog naming the question: it names only the authority.

land's body (`:1110-1194`, read in full) never reads VERDICT[policy], ANSWER_HEADING or EXPECT (paraphrased — no quote available because the claim is about the absence of those reads across an 85-line function; checked by reading it end to end). Its message and reflog both come from `what` (Claim 5's excerpt).

**Evidence:** `scripts/build-loop.sh:1095-1194`

---

## Claim 11: land keys its trailer on the authority, as its message (A3; e25a6e89)

**Location:** `scripts/build-loop.sh:1179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that the trailer prints iff `$1 == approved`, and that self-merge's group still exits 0, so the `&&` chain goes on. It does not establish land's behavior when it is called with approved and an empty `$2` (no caller does that: the merge arm sets AUTH=approved only when APPROVED is non-empty).

```bash
# scripts/build-loop.sh:1179
    [[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"; } > "$GATE_TMP/msg" \
```

E1's test 1 (self-merge message with no second trailer) and test 8 (approved) both pass.

**Evidence:** `scripts/build-loop.sh:1178-1181`, `scripts/build-loop.sh:1216`, `$FC/bats.log`

---

## Claim 12: check_fix's walk text: "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out${TRUTH_WHERE:+: $TRUTH_WHERE}; file it instead" replaces the duplicated reader-settings sentence (rows 630, 634)

**Location:** `scripts/dev-cycle.sh:186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that the old reader-settings wording is reproduced exactly when IMPORT_READER_WHY is set (import_readers fails whenever it is set, `:1170`). The bare form covers other failures. It does not establish wording parity when import_readers fails for another reason: there the line now adds walk_why's generic readers sentence, which the old code omitted (a widening, not a loss).

```bash
# scripts/lib/dev-cycle-read.sh:1170
  [[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1
# scripts/lib/dev-cycle-read.sh:821
    readers) [[ -n "$IMPORT_READER_WHY" ]] && echo "the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY" \
```

E1: dev-cycle.bats passes in full (237 tests), and the new floor test asserts `tree [walk] the reader settings of docs/dev-cycle.md cannot be used: planted`.

**Evidence:** `scripts/dev-cycle.sh:176-189`, `scripts/lib/dev-cycle-read.sh:816-834`, `scripts/lib/dev-cycle-read.sh:1159-1170`, `test/scripts/build-loop-check.bats:1533-1543`, `$FC/bats.log`

---

## Claim 13: "A caller that also reads ANSWER_HEADING … runs check_answer in its own shell, its output to a file under set -e, since a $(...) would drop the value; check_answer reaches no need_root (it reads only git objects), so nothing exits there."

**Location:** `scripts/lib/dev-cycle-read.sh:35-38`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that check_answer and its helpers (main_by_name, main_entry, pathform, entry_why, oddwhy, git cat-file, awk) call no need_root, and that build-loop.sh's one caller writes the output to a file in its own shell. It does not establish the "under set -e" part for that caller: approval runs inside an `elif … && ! approval` condition, where bash suspends errexit for the whole call. This is the part that sets the verdict.

```bash
# scripts/build-loop.sh:1226
    elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"; then v="refuse $a: $MERGE_WHY"
```

The mechanism (own shell, to a file) and the conclusion (no exit) both hold. The statement that it runs under set -e is imprecise for the actual caller, though harmless: every helper check_answer calls returns 0 (main_entry ends each branch with `echo …; return`, `:346-366`), and a failed redirect falls to the catch-all refusal. A precise version: "…its output to a file (under set -e, or in a condition: nothing in check_answer exits or fails)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:35-38`, `scripts/lib/dev-cycle-read.sh:330-382`, `scripts/lib/dev-cycle-read.sh:2082-2109`, `scripts/build-loop.sh:294`, `scripts/build-loop.sh:1226`

---

## Claim 14: "The tree walk's IMPORTED_WHY is readers when import_readers fails, else empty (its other failures are not told apart)."

**Location:** `scripts/lib/dev-cycle-read.sh:808-809`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the two assignments and cache hits. A readers failure empties IMPORTED_DONE, so it is never served from cache. A cached non-readers failure keeps the `""` its walk set. It does not establish IMPORTED_WHY after import_reset with no walk since (stale but unread: truthwalk reads it only after imported_names returns 1, which always passes one of the two assignments or a cache hit following one).

```bash
# scripts/lib/dev-cycle-read.sh:1637, 1641
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; IMPORTED_WHY=readers; return 1; }
  IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"; IMPORTED=error; IMPORTED_WHY=""
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:1634-1642`, `scripts/lib/dev-cycle-read.sh:844`

---

## Claim 15: "walk_why WHY: the sentence for an IMPORTED_MAIN_WHY word (or the tree walk's IMPORTED_WHY, which is only ever readers)"

**Location:** `scripts/lib/dev-cycle-read.sh:811-812`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers truthwalk's tree arm, the only place walk_why gets IMPORTED_WHY, and only when it is non-empty. It does not establish walk_why's other callers' words (unchanged).

```bash
# scripts/lib/dev-cycle-read.sh:1898
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:811-834`, `scripts/lib/dev-cycle-read.sh:1894-1904`

---

## Claim 16: "Returns 0 when the walk fails (TRUTH_WHY=walk, with TRUTH_WHERE walk_why's sentence for where, or empty when the walk does not say: rows 630, 634)"

**Location:** `scripts/lib/dev-cycle-read.sh:1888-1889`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers both arms. Main always sets a sentence (walk_why never prints empty: an empty word gives "the walk failed (no reason recorded)"). Tree sets one only for readers. An unknown WALK leaves it empty, and every call resets it first. It does not establish walk_why's per-word wording.

```bash
# scripts/lib/dev-cycle-read.sh:1894-1900
truthwalk() {
  TRUTH_WHY=walk; TRUTH_WHERE=""
  case "$1" in
    main) main_imports || { TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"; return 0; } ;;
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
    *) return 0 ;;
  esac
```

(excerpt ends :1900; enclosing truthwalk() continues to :1904 — read)

E1's new test "floor sets a word … for both walks" passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1883-1904`, `test/scripts/build-loop-check.bats:1533-1543`, `$FC/bats.log`

---

## Claim 17: GATE_CODE's comment: "a change to them lands only through a merge-gate- review entry, never a self-merge. The scripts because main's copy runs the next merge (plan D6, D5 item 3); skills/dev-cycle/ because it carries the D6 snippet that copies and runs the gate (plan D4, F52), though sessions load the skill only from a release, so here the floor is stricter than D5. One list for floor and build-loop.sh's --approved, which tests it on its own (floor does not run there); build-loop.sh's header repeats it."

**Location:** `scripts/lib/dev-cycle-read.sh:1918-1924`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the plan references (D4 line 61 lists `skills/dev-cycle/` and F52; D5 item 3 lists only the scripts; D5 "In this repo" says skills reach sessions through a release; D6 says the snippet is inline in the installed SKILL.md), the self-merge refusal (srules' floor, gate or an earlier word), the --approved merge-gate- requirement (check_line's own test, Claim 3), and the header copy (Claim 4). It does not establish coverage of gate-adjacent files outside the list (health-check.sh, sibling skills: override rows, deferred).

Plan, quoted: "A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52)." (`docs/working/plan-build-loop-handoff.md:61`). Also: "3. the gate's own code (`scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh`, `scripts/lib/dev-cycle-read.sh`)" (`:71`), and "The snippet is inline in the installed SKILL.md" (`:77`). E1's T10 refuses `skills/dev-cycle/references/x.md` and `Skills/Dev-Cycle/x.sh` as gate, and `skills/dev-cycle/SKILL.md` as instr.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1918-1925`, `docs/working/plan-build-loop-handoff.md:61`, `docs/working/plan-build-loop-handoff.md:66-76`, `docs/working/plan-build-loop-handoff.md:77`, `test/scripts/build-loop-check.bats:1287-1312`, `$FC/bats.log`

---

## Claim 18: "Returns 0 with FLOOR_WHY set to a word when the floor refuses (floor_why words it: row 472), else 1. Its gate word is no test of whether a merge touches gate code (floor runs after the rules before it, and not at all under --approved): test GATE_CODE for that."

**Location:** `scripts/lib/dev-cycle-read.sh:1934-1937`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that every refusal branch sets a word (case, a truthrule word with settings mapped to cycle, gate, record, working, review, walk, imported, below), that truthrule runs before the gate test (so `skills/dev-cycle/SKILL.md` answers instr), and that srules (floor's only caller) never runs under --approved (`sm` empty). It does not establish floor's behavior outside build-loop.sh (no other caller: grep).

```bash
# scripts/lib/dev-cycle-read.sh:1955-1957
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY=case; return 0; }
  if truthrule "$lp"; then FLOOR_WHY="$TRUTH_WHY"; [[ "$FLOOR_WHY" != settings ]] || FLOOR_WHY=cycle
  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate
```

(excerpt ends :1957; enclosing floor() continues to :1970 — read)

truthrule's words are case, instr, dot, cycle, settings, user and record (`:1872-1882`). E1's test prints `[gate] …` for scripts/build-loop.sh.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1872-1882`, `scripts/lib/dev-cycle-read.sh:1952-1970`, `scripts/build-loop.sh:839`, `scripts/build-loop.sh:1050`, `$FC/bats.log`

---

## Claim 19: "a call given $4 that both of main_imports' caches answer … forks nothing but walk_why's subshell (truthwalk's) after a failed walk"

**Location:** `scripts/lib/dev-cycle-read.sh:1944-1947`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the move of the walk_why fork from floor into truthwalk's main arm (Claim 16's excerpt). floor itself now only assigns words, and floor_why's fork is in the caller (srules), outside floor. It does not establish the fork-freedom of truthrule's helpers (isstart, writable, ownfile), which this diff does not change.

floor's branches assign literals or `$TRUTH_WHY` with no `$(...)` except the `lower` fork when `$4` is absent (`:1955`, quoted in Claim 18). srules forks floor_why afterwards: `DENY="$(floor_why "$FLOOR_WHY")"` (`scripts/build-loop.sh:839`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1952-1970`, `scripts/lib/dev-cycle-read.sh:1894-1904`, `scripts/build-loop.sh:839`

---

## Claim 20: "floor_why WORD: the sentence for a FLOOR_WHY word, as walk_why words IMPORTED_MAIN_WHY's; walk reads TRUTH_WHERE, so word it before the next truthwalk." (and its words match the old FLOOR_WHY sentences)

**Location:** `scripts/lib/dev-cycle-read.sh:1971-1991`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that each of floor's 12 words maps to the sentence the old floor assigned (diffed line by line: the old `*)` default "one of the dev cycle's own files" is now `cycle`), that `walk` reads TRUTH_WHERE, and that srules words it right after floor. It does not establish the default arm's wording for words floor never sets.

```bash
# scripts/lib/dev-cycle-read.sh:1985
    walk) echo "the default branch's instruction files could not be walked for @ imports: $TRUTH_WHERE" ;;
```

E1's T10 floor test (every refusal sentence) and its lower-case test (`C: the path could not be lower-cased`) pass through floor_why.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1971-1990`, `git diff main...HEAD -- scripts/lib/dev-cycle-read.sh` (old floor lines), `scripts/build-loop.sh:839`, `$FC/bats.log`

---

## Claim 21: "The keep-or-drop answer rule, for one entry of a questions file. Prints keep, drop, done, open, unrecognized, dup (the heading appears more than once), "odd N WHY", "unbalanced N" or "quoted N" (…), or nothing when the file has no such entry."

**Location:** `scripts/lib/dev-cycle-read.sh:1991-1994`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers ANSWER_AWK's output contract after a7a4f784. It does not establish any harm today: check_answer, the only consumer (grep: `scripts/lib/dev-cycle-read.sh:2095`, plus a non-empty test in `test/scripts/dev-cycle.bats:1114`), splits off the second line.

After keep/drop/done/open/unrecognized, the awk now prints a second line, the entry's heading:

```awk
# scripts/lib/dev-cycle-read.sh:2069
  else if (count) { print (!answered ? "open" : done ? result : "unrecognized"); print head }
```

The comment (unchanged from main, where it was accurate) still describes a one-line output. A new consumer reading `r` whole, as check_answer did before this diff, would get a two-line value. The precise version adds: "…unrecognized (each followed by a second line, the entry's heading after "### ")…".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1991-1994`, `scripts/lib/dev-cycle-read.sh:2063-2070`, `scripts/lib/dev-cycle-read.sh:2095-2105`

---

## Claim 22: ANSWER_AWK prints the heading as a second line only in the single-entry case, and dev-cycle.sh --check-answer output is unchanged

**Location:** `scripts/lib/dev-cycle-read.sh:2040`, `scripts/lib/dev-cycle-read.sh:2069`, `scripts/lib/dev-cycle-read.sh:2105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the END branches (odd, unbalanced, quoted and dup print one line, and only count == 1 prints head), head captured at the first matching heading after the CR strip, and check_answer printing only the first line. It does not establish anything about scrub-wrapped output in other dev-cycle.sh modes.

```bash
# scripts/lib/dev-cycle-read.sh:2105, 2107
    hit="${r%%$'\n'*}"; head="${r#*$'\n'}"; where="$f"
  if [[ -n "$hit" ]]; then ANSWER_HEADING="$head"; echo "$hit $a"
```

P1 B: `dev-cycle.sh --check-answer Q-001 Q-002` printed exactly two lines, `keep Q-001` and the Q-002 skip. E1's dev-cycle.bats answer tests pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2036-2070`, `scripts/lib/dev-cycle-read.sh:2082-2109`, `$FC/probe.out`, `$FC/bats.log`

---

## Claim 23: "With an answer line it sets ANSWER_HEADING to the entry's heading after "### " ("Q-NNN · SLUG", CR dropped), else empties it; a caller that reads it (build-loop.sh --approved) calls check_answer in its own shell, its output to a file."

**Location:** `scripts/lib/dev-cycle-read.sh:2076-2079`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers "answer line" read as check_answer's printed keep/drop/done/open/unrecognized line, the emptying at entry (so every skip leaves it empty) and the CR strip (P1 C lands from a CRLF file). It does not establish the reading "an entry that holds a Q-NNN: answer line": an OPEN entry with no answer also sets it (harmless, since approval refuses open first; iteration 1, Claim 21).

```bash
# scripts/lib/dev-cycle-read.sh:2084
  ANSWER_HEADING=""
```

`{ sub(/\r$/, "") }` runs before the heading rule (`:2037`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2037-2040`, `scripts/lib/dev-cycle-read.sh:2082-2109`, `scripts/build-loop.sh:1083`, `$FC/probe.out`

---

## Claim 24: 18f32952: "Red until the --approved code lands."

**Location:** commit 18f32952 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers build-loop-merge.bats at 18f32952 against that commit's own scripts: the five --approved tests (8-12) and the reworded policy refusal (3) fail, and 1, 2 and 4-7 pass. It does not establish red for build-loop-check.bats at that commit (not run).

P2 output: `not ok 3 …`, `not ok 8 …` through `not ok 12 …`, all others `ok` (`$FC/at18.out`; paraphrased — no quote available because the evidence is the captured run's 12 result lines, summarized here).

**Evidence:** `$FC/at18.out`

---

## Claim 25a: a7a4f784: "truthwalk sets TRUTH_WHERE for both walks' failures"

**Location:** commit a7a4f784 (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both walks can set TRUTH_WHERE. It does not establish "for both walks' failures" in full: the tree walk sets it only when import_readers fails (Claim 16).

Precise version: "for the main walk's failures and the tree walk's readers failure". This is the rubric's C5 item 23, already recorded: the body is in an unmerged commit and is to be corrected in the merge message. Settled, not a regression.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1897-1898`, `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a3.md` (C5)

---

## Claim 25b: a7a4f784's other statements: --approved lands either policy under the N rules alone; the exact heading or merge-gate-; one AUTH value (row 653); the refusal names --approved (row 661); the trailer and reflog; floor words (row 472); check_fix no longer repeats the reader-settings sentence; --approved refused with --check

**Location:** commit a7a4f784 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each statement against the code at HEAD (Claims 1-3, 5, 7, 8, 12, 18) and E1. It does not re-verdict the name ANSWER_HEAD, which e25a6e89 renames to ANSWER_HEADING and says so.

Each statement is backed by a claim above (paraphrased — no quote available because this claim aggregates Claims 1-3, 5, 7, 8, 12 and 18, whose quotes carry the evidence).

**Evidence:** `scripts/build-loop.sh:319-322`, `scripts/build-loop.sh:1216-1227`, `scripts/dev-cycle.sh:186`, `$FC/bats.log`

---

## Claim 26: e25a6e89: GATE_CODE gains ^skills/dev-cycle/ (the floor refuses it under self-merge too); header, A2/A3, C2 wording; tests; "9 override-log rows (8 declined findings, 1 pre-existing flake)"

**Location:** commit e25a6e89 (message body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the GATE_CODE change and its floor effect (T10), land's trailer keyed on the authority (Claim 11), the option 2/3/not-read refusals (Claim 7), the added tests (merge tests 9-11), and the override-row count (9 `+|` rows in that commit's override-log diff: 8 review findings, 1 config_seeds flake). It does not establish anything about the rows' dispositions.

`git show e25a6e89 -- docs/reviews/override-log.md | grep -c '^+|'` printed `9`. The ninth row begins "config_seeds' `find -H ANCESTOR -maxdepth 1 -xtype f` fails when an entry vanishes".

**Evidence:** `docs/reviews/override-log.md` (e25a6e89 diff), `scripts/lib/dev-cycle-read.sh:1925`, `$FC/bats.log`

---

## Claim 27: 01a2935f: GATE_CODE's comment gives both reasons and says the floor is stricter than D5; "T10 refuses skills/dev-cycle/ paths (any case) and passes skills/dev-cycle-x/"; the header says --expect still binds the tip, points at GATE_CODE, prefix sentence after the landing rule; "T35 adds a mismatched --expect under --approved"; "2 override rows"

**Location:** commit 01a2935f (message body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each statement against the diff and E1. T10 is `@test "floor: … (T10, U2a4)"` at `test/scripts/build-loop-check.bats:1287`, and its lists gain `skills/dev-cycle/references/x.md`, `Skills/Dev-Cycle/x.sh` (refuse) and `skills/dev-cycle-x/a.md` (pass). The commit's override-log diff adds 2 rows (health-check.sh; sibling skills). It does not establish those rows' dispositions.

```bash
# test/scripts/build-loop-merge.bats:612
    mrg "$B" --expect "$M" --approved Q-001
```

**Evidence:** `test/scripts/build-loop-check.bats:1287-1312`, `test/scripts/build-loop-merge.bats:611-613`, `scripts/build-loop.sh:213-240`, `scripts/lib/dev-cycle-read.sh:1918-1924`, `docs/reviews/override-log.md` (01a2935f diff), `$FC/bats.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:1991-1994`): ANSWER_AWK's contract comment still says it prints one word, but since a7a4f784 it prints a second line (the entry's heading) after keep/drop/done/open/unrecognized. Add that to the comment. No consumer is misled today, because check_answer splits the lines. Legibility-target: for-author. This is a new finding: iterations 1 and 2 checked the END block (iteration 1, Claim 20) but not this comment.

### Mostly Accurate
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:35-38`): "its output to a file under set -e". build-loop.sh's one caller runs check_answer inside an `elif … && ! approval` condition, where errexit is suspended. It is harmless, since nothing in check_answer exits or fails. Tighten to "under set -e or in a condition". Legibility-target: for-author.
- **Claim 25a** (commit a7a4f784): "TRUTH_WHERE for both walks' failures": the tree walk sets it only on a readers failure. This is already rubric C5 (item 23), to be corrected in the merge message, so it is settled. Legibility-target: for-orchestrator-synthesis.

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to the output path below in the code-fact-check skill's format, with `Commit: 01a2935f` at the top."

This report is saved at `/workspace/.claude/wt-build-loop-u3a3/docs/reviews/code-fact-check-report-u3a3-final-r2.md` and opens with `Commit: 01a2935f`. It follows the skill's header, the seven per-claim fields (plus Legibility-target, as the task asked) and the attention summary. It covers all seven claim groups the brief named (the header's --merge paragraph and refusals; check_line's AUTH/VERDICT comment; approval and land; the lib's ANSWER_HEADING header, comment and ANSWER_AWK; truthwalk, walk_why and IMPORTED_WHY with check_fix; GATE_CODE, floor and floor_why; the four commit messages). It found one new Stale comment (Claim 21) and no Incorrect verdict, so the hallucination-pattern log is unchanged. One deviation: execution logs are in the scratch dir `fc2/`, not docs/reviews/execution-logs/, as the brief restricts writes. Nothing was committed.
