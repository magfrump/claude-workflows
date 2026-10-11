Commit: 01a2935f

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a3 (claude-workflows, branch feat/build-loop-u3a3)
**Scope:** `git diff main...HEAD` at 01a2935f (18f32952, a7a4f784, e25a6e89, 01a2935f): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-merge.bats, test/scripts/build-loop-check.bats, the four commit messages; plan docs/working/plan-build-loop-handoff.md D4-D6 read for citations. Final confirming pass, replicate 3 (k=3), delivery self-read.
**Checked:** 2026-10-10
**Total claims checked:** 27
**Summary:** 23 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Its logged pattern class nearest this diff is count claims in commit messages (test tallies). The two count claims here (e25a6e89's "9 override-log rows (8 declined findings, 1 pre-existing flake)", 01a2935f's "2 override rows") were counted against the commits' own diffs and hold (Claims 26, 27). No claim matched a logged fabrication.

## Execution provenance

All probes ran under `timeout`, in the scratch dir `FC=/tmp/claude-1000/-workspace/675070f9-0197-40a3-bd3c-520157521989/scratchpad/u3a3-final/fc3`. Nothing was written in the worktree but this report.

| ID | Command | cwd | Started (UTC) | Exit | Output |
|---|---|---|---|---|---|
| E1 | `timeout 1500 bats test/scripts/build-loop-merge.bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` (serial, no -j) | worktree | 2026-10-10T23:54:57Z | 0 (1..237, 237 ok) | `$FC/bats.log` |
| E2 | `timeout 120 bash $FC/probe1.sh $FC <worktree>`: a fixture repo whose main holds a CRLF Q-001 entry answered `[1]`, open Q-002, Q-003 `drop` under the heading "Q-003  two spaces"; runs dev-cycle.sh --check-answer, the lib's check_answer to a file with ANSWER_HEADING printed after it, and a bash `set -e` probe inside an `elif` condition | `$FC` | 2026-10-10T23:57:13Z | 0 | `$FC/probe1.out` |
| E3 | main's scripts (`git archive main scripts`) and HEAD's dev-cycle.sh, each running `--check-answer Q-001 Q-002 Q-003 Q-009` on E2's repo, then `cmp` | `$FC/repo1` | 2026-10-10T23:57:20Z | 0, 0; `IDENTICAL` | `$FC/probe2.out`, `$FC/main-ca.out`, `$FC/head-ca.out` |
| E4 | `git archive 18f32952 scripts test` into `$FC/at18`, then `timeout 600 bats -f approved test/scripts/build-loop-merge.bats` | `$FC/at18` | 2026-10-10T23:57:47Z | 1 (5 of 5 not ok) | `$FC/at18-bats.log` |

---

## Claim 1: "--merge lands a self-merge brief (D7), or with --approved a brief of either policy: --check's lines for BRIEF at --expect's tip (under --approved, without the S rules or the checkout refusal; --expect still binds the tip)"

**Location:** `scripts/build-loop.sh:213-216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the S-rule and checkout gating through `sm` in check_line, and the --expect comparison running before either for every AUTH; does not establish the N rules' own coverage (unchanged here) or any path the floor would refuse under self-merge (by design it does not run under --approved).
**Legibility-target:** for-author

check_line sets `sm` only for a self-merge brief outside --approved, and both the checkout gate and srules hang on it:

```bash
# scripts/build-loop.sh:990
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
# scripts/build-loop.sh:994
  if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi
# scripts/build-loop.sh:1032
  co=""; if [[ -n "$sm" ]] && ! checkout_gate; then co="refuse $a: ..."; fi
# scripts/build-loop.sh:1050
    [[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"
```
(excerpts; enclosing check_line() runs :981-1054, read in full.) The --expect check sits above every AUTH-dependent line. E1's T35 test "runs the N rules only" lands a self-merge brief past its never glob, `Paths: none` and a checkout at feat/x, and the test "refuses an answer other than [1] ..." refuses `--expect "$M" --approved Q-001` with "the tip of feat/x is $T, not the expected $M" (`test/scripts/build-loop-merge.bats:236-237`).

**Evidence:** `scripts/build-loop.sh:981-1054`, `test/scripts/build-loop-merge.bats:207-225,236-237`, `$FC/bats.log`

---

## Claim 2: "With --approved Q-NNN it lands a brief of either policy under the N rules alone (no S rules, no checkout rule) when the questions entry Q-NNN, read from the default branch's commit as --check-answer reads it, is answered with option 1 under the heading exactly "### Q-NNN · merge-STEM-SHA12" (SHA12: TIP's first 12 hex digits), or "merge-gate-STEM-SHA12" when a changed path, lower-cased, is the gate's own code (the lib's GATE_CODE: scripts/build-loop.sh, dev-cycle.sh, questions.sh, anything under scripts/lib/ or skills/dev-cycle/); then the message reads "(build-loop approved merge)" with a second trailer "Build-loop-approved: Q-NNN", and the reflog "build-loop: approved merge of STEM"."

**Location:** `scripts/build-loop.sh:225-236`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers approval's slug construction and exact comparison, GATE_CODE's list against the header's, the lower-cased test, and land's message, trailer and reflog for both move paths (CAS and W); does not establish what the U4 entry filer writes (not built) or that the heading's 12 hex digits bind the full tip (Claim 3).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:1080-1081, 1092
  [[ -z "${VERDICT[gate]}" ]] || { s="merge-gate-"; g=" (the merge changes the gate's own code)"; }
  s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"
  [[ "$ANSWER_HEADING" == "$1 · $s" ]] \
```
```bash
# scripts/lib/dev-cycle-read.sh:1925
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'
# scripts/build-loop.sh:1049
    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
```
`lps` is the lower_all batch of the paths (`:1045`). check_answer is the same function dev-cycle.sh's `--check-answer` calls (`scripts/dev-cycle.sh:209: --check-answer) check_answer "$a" ;;`). land sets `what="approved merge"` and builds `msg="build-loop: $what of ${VERDICT[stem]}"` (`:1112-1113`). It uses msg for both `update-ref -m "$msg"` and `GIT_REFLOG_ACTION="$msg"` (`:1186`, `:1192`) and prints the trailer at `:1179`. E1's T35 test 1 asserts the full message and `git reflog -1 --format=%gs main` = "build-loop: approved merge of 2026-10-01-x"; the gate test covers scripts/build-loop.sh, Scripts/Lib/x.sh and skills/dev-cycle/references/x.md.

**Evidence:** `scripts/build-loop.sh:1071-1093`, `scripts/build-loop.sh:1110-1196`, `scripts/lib/dev-cycle-read.sh:1925`, `test/scripts/build-loop-merge.bats:194-205,244-254`, `$FC/bats.log`

---

## Claim 3: "The heading pins only TIP's prefix: --expect binds the full tip, so the caller passes the full TIP it filed the entry for, never the branch's live tip."

**Location:** `scripts/build-loop.sh:236-239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that approval compares only `${VERDICT[tip]:0:12}` and that check_line compares sha to EXPECT in full; does not establish the caller's discipline (U4, override row A1).
**Legibility-target:** for-author

`s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"` (`scripts/build-loop.sh:1081`) uses 12 characters. `[[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]` (`:994`) compares the whole id, and the parser accepts only `^([0123456789abcdef]{40}|[0123456789abcdef]{64})$` (`:317`).

**Evidence:** `scripts/build-loop.sh:317`, `scripts/build-loop.sh:994`, `scripts/build-loop.sh:1081`

---

## Claim 4: "or refuse BRIEF: WHY ... when: without --approved, the policy --status reads is review; with it, Q-NNN is open, skipped (WHY quotes the skip) or answered with another option or an answer not read (WHY names which), or its heading is not the one above"

**Location:** `scripts/build-loop.sh:247-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge arm's policy refusal (AUTH self-merge only) and approval's five refusal arms plus its heading refusal; does not establish wording of the further refusals land adds (unchanged).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:1225-1226
    if [[ "$AUTH" == self-merge && "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; --merge lands it only with --approved Q-NNN"
    elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"; then v="refuse $a: $MERGE_WHY"
```
approval's arms: `"open $1"` → "it is not answered on the default branch"; `"skip $1: "*` → `${r#"skip $1: "}` (the skip's own reason); `drop` → "option 2"; `done` → "option 3"; `*` → "not read as an option ([1], 1 or keep approve)" (`:1084-1091`). E1's T35 test 3 asserts each, plus the no-entry skip and five heading mismatches.

**Evidence:** `scripts/build-loop.sh:1079-1093`, `scripts/build-loop.sh:1218-1230`, `test/scripts/build-loop-merge.bats:227-242`, `$FC/bats.log`

---

## Claim 5: "VERDICT holds tip, tree, policy, branch, stem and gate (1 when a changed path, lower-cased, is the gate's own code, GATE_CODE; else empty), and CHANGED each changed path's status letter, only after an ok line (both empty otherwise)."

**Location:** `scripts/build-loop.sh:971-974`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers verdict_ok's assignment, gc's init and its one setter; does not establish CHANGED's later readers beyond land.
**Legibility-target:** for-author

`gc=""` is a check_line local (`:984`). It is set only at `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`:1049`), and `VERDICT=(... [stem]="$stem" [gate]="$gc")` is assigned only in verdict_ok (`:1039`). With zero paths gc stays empty (`:1043`), and `VERDICT=(); CHANGED=()` runs on entry (`:985`).

**Evidence:** `scripts/build-loop.sh:981-1054`

---

## Claim 6: "AUTH, the authority the run lands under (row 653), decides the rules: empty for --check and self-merge for --merge, where a brief --status reads as self-merge gets the S rules and its checkout checked; approved (--merge --approved) runs the N rules alone, whatever the policy." (and the merge arm's "The authority's own check, then land")

**Location:** `scripts/build-loop.sh:975-978`, `scripts/build-loop.sh:1223`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers AUTH's only assignment and its one reader in check_line. For AUTH in {"", self-merge}, `sm` is set exactly when `pol == self-merge`, as main's `[[ "$pol" == self-merge ]]` tests were, so --check and plain --merge are unchanged. Does not establish --check's output beyond E1's suites.
**Legibility-target:** for-author

`AUTH=""` is global (`:980`). The merge arm sets `AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved` (`:1219`), and check_line reads it only at `:990` (quoted in Claim 1). Main's three `"$pol" == self-merge` tests (the diff's three `-` lines in check_line) became `-n "$sm"` / `-z "$sm"`. The merge arm checks the authority (policy or approval) before land (`:1225-1227`). E1: every build-loop-check.bats and pre-U3a3 build-loop-merge.bats test passes.

**Evidence:** `scripts/build-loop.sh:980`, `scripts/build-loop.sh:990`, `scripts/build-loop.sh:1218-1230`, `$FC/bats.log`

---

## Claim 7: "approval Q-NNN: whether the questions entry Q-NNN, read from main's commit by check_answer (D8 ...), approves landing VERDICT: answered with option 1 under the heading ... exactly, so an answer for another brief, an older tip or a merge without the gate's code does not carry. Sets MERGE_WHY and returns 1 when it does not."

**Location:** `scripts/build-loop.sh:1071-1077`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers approval's body (:1078-1093) and check_answer reading `$MAIN_SHA:$f` blobs; does not establish that MAIN_SHA cannot be moved by a same-uid writer between gate_start and the CAS (Q-103 residuals).
**Legibility-target:** for-author

check_answer reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:2095`). approval's last statement is the heading test with `|| { MERGE_WHY=...; return 1; }` (`:1092-1093`), so it returns 0 only on `keep` plus an exact heading. E1's T35 test 3 refuses slugs for brief y, main's SHA12, merge-gate- without gate code, a trailing space and a suffix; the working-tree-only answer (`sed -i 's/OPEN/ANSWERED/'`) refuses as not answered.

**Evidence:** `scripts/build-loop.sh:1078-1093`, `scripts/lib/dev-cycle-read.sh:2082-2107`, `test/scripts/build-loop-merge.bats:227-242`, `$FC/bats.log`

---

## Claim 8: "In this shell, to a file: ANSWER_HEADING would not leave a $(...)."

**Location:** `scripts/build-loop.sh:1082`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"` setting ANSWER_HEADING in the gate's shell; does not establish set -e coverage of that call (Claim 14).
**Legibility-target:** for-author

`check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"` (`:1083`) runs check_answer as a plain command with a redirect, with no subshell. E2 ran the same form and printed `keep Q-001 | [Q-001 · merge-x-abc]`: the heading survives. A `$(...)` assignment would set it only in the subshell (standard bash semantics; paraphrased — no quote available because the claim is about bash's subshell rule, not repo code).

**Evidence:** `scripts/build-loop.sh:1083`, `$FC/probe1.out`

---

## Claim 9: approval's refusal words track check_answer's lines: keep approves; open, skip, drop, done, and anything else (unrecognized) refuse, the last naming "([1], 1 or keep approve)"

**Location:** `scripts/build-loop.sh:1084-1091`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's output vocabulary (`$hit $a` with hit from ANSWER_AWK's keep/drop/done/open/unrecognized, or a skip line) and ANSWER_AWK's option() mapping; does not establish wording for a hypothetical new check_answer word (it falls to `*`, refusing).
**Legibility-target:** for-author

option() maps `[1]`, `1` and `keep` to keep (`scripts/lib/dev-cycle-read.sh:2019-2028`: `if (substr(s, 1, 3) == "[1]") return "keep"` ... `if (w == "1" || w == "keep") return "keep"`). An answered entry with no answer line prints `unrecognized` (`:2069`). The dup/odd/unbalanced/quoted cases become skip lines in check_answer (`:2098-2103`), which hit approval's skip arm. E1 covers option 2, option 3, "merge" (unrecognized), open and no entry.

**Evidence:** `scripts/build-loop.sh:1084-1091`, `scripts/lib/dev-cycle-read.sh:2017-2107`, `$FC/bats.log`

---

## Claim 10: "land AUTHORITY [Q-NNN]: ... under the authority the caller checked and names (self-merge, or approved with its question), which the message and reflog carry. Decide (the header's refusals but the policy's, approval's and --check's: ...)"

**Location:** `scripts/build-loop.sh:1095-1099`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers land's body (:1110-1196): it reads `$1` for message, reflog and trailer and `$2` only for the trailer, and runs none of the policy test, approval or check_line; does not establish the refusal coverage of land's own decisions (unchanged from U3a2).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:1112-1113
  [[ "$1" != approved ]] || what="approved merge"
  msg="build-loop: $what of ${VERDICT[stem]}"
```
(excerpt; land() continues to :1196 — read.) No call to approval, check_line or a policy test appears in land (paraphrased — no quote available because the claim covers absence of code: those names do not occur between `:1110` and `:1196`).

**Evidence:** `scripts/build-loop.sh:1095-1196`

---

## Claim 11: land keys the "Build-loop-approved" trailer on the authority, as it does the message

**Location:** `scripts/build-loop.sh:1178-1179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printf group writing `$GATE_TMP/msg`; does not establish that `$2` is non-empty when `$1 == approved` beyond the merge arm's one call (`land "$AUTH" "$APPROVED"`, with AUTH approved only when APPROVED is set).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:1178-1179
  { printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "$what" "${VERDICT[stem]}"
    [[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"; } > "$GATE_TMP/msg" \
```
E1's T35 test 1 asserts the exact three-paragraph message. U3a2's self-merge message tests still pass, so self-merge gets no second trailer.

**Evidence:** `scripts/build-loop.sh:1178-1181`, `scripts/build-loop.sh:1218-1230`, `test/scripts/build-loop-merge.bats:194-205`, `$FC/bats.log`

---

## Claim 12: check_fix prints "the instruction-file import walk failed, so an import of it cannot be ruled out${TRUTH_WHERE:+: $TRUTH_WHERE}" — one branch, no repeated reader-settings sentence

**Location:** `scripts/dev-cycle.sh:186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk branch's text for a readers failure (sentence appended once) and for other tree-walk failures (bare); does not establish wording on the main walk, which check_fix does not call.
**Legibility-target:** for-author

`if [[ "$TRUTH_WHY" == walk ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out${TRUTH_WHERE:+: $TRUTH_WHERE}; file it instead"` (`scripts/dev-cycle.sh:186`). E1 passes dev-cycle.bats in full and the new build-loop-check test "floor sets a word ...", whose `truthwalk tree` line yields `tree [walk] the reader settings of docs/dev-cycle.md cannot be used: planted`. Previously, with IMPORT_READER_WHY empty but readers failing, the text was bare; now it carries walk_why's registry sentence. The change is additive.

**Evidence:** `scripts/dev-cycle.sh:174-189`, `test/scripts/build-loop-check.bats:1533-1543`, `$FC/bats.log`

---

## Claim 13: "A caller that also reads ANSWER_HEADING ... runs check_answer in its own shell, its output to a file under set -e, since a $(...) would drop the value; check_answer reaches no need_root (it reads only git objects), so nothing exits there."

**Location:** `scripts/lib/dev-cycle-read.sh:35-38`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one caller's form (approval) and check_answer's call graph (main_by_name, main_entry, pathform, entry_why, oddwhy, git cat-file, awk; no need_root); does not establish behavior under a failed redirect beyond the fail-closed reading below.
**Legibility-target:** for-author

The own-shell, to-a-file and no-need_root parts hold: `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:330`), and main_entry only runs pathform and `git ls-tree` (`:346-364`). "Under set -e" is not how the one caller runs it. approval is called as `elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"` (`scripts/build-loop.sh:1226`), a condition context, where bash suspends set -e for the whole function body. E2's probe (`set -e; f() { false; echo "after-false-in-f"; }; ... elif ! f; ...`) printed `after-false-in-f`. It is harmless: check_answer always returns 0 with a line, and a failed redirect would leave `r` stale or empty and hit approval's `*` refusal. The precise version: "runs check_answer in its own shell, its output to a file (set -e or not: nothing in it exits or fails)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:35-38`, `scripts/lib/dev-cycle-read.sh:330`, `scripts/lib/dev-cycle-read.sh:346-364`, `scripts/build-loop.sh:1226`, `$FC/probe1.out`

---

## Claim 14: "The tree walk's IMPORTED_WHY is readers when import_readers fails, else empty (its other failures are not told apart)."

**Location:** `scripts/lib/dev-cycle-read.sh:808-809`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers imported_names' two writers of IMPORTED_WHY and the cache path, including a cached failure (the readers branch empties IMPORTED_DONE, so its value never meets a cache hit); does not establish callers other than truthwalk.
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:1637, 1639, 1641
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; IMPORTED_WHY=readers; return 1; }
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && { [[ "$IMPORTED" != error ]]; return; }
  IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"; IMPORTED=error; IMPORTED_WHY=""
```
(excerpt; imported_names() continues past :1700 — its later lines do not assign IMPORTED_WHY, grep-confirmed.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-810`, `scripts/lib/dev-cycle-read.sh:1633-1641`

---

## Claim 15: "walk_why WHY: the sentence for an IMPORTED_MAIN_WHY word (or the tree walk's IMPORTED_WHY, which is only ever readers)"

**Location:** `scripts/lib/dev-cycle-read.sh:811-812`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers truthwalk passing IMPORTED_WHY to walk_why only when non-empty, so walk_why sees only `readers` from the tree walk; does not establish walk_why's sentence for each main-walk word (unchanged).
**Legibility-target:** for-author

`tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;` (`:1898`). walk_why's `readers)` arm prints the reader-settings sentence when IMPORT_READER_WHY is set and the registry sentence otherwise (`:820-821`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:816-834`, `scripts/lib/dev-cycle-read.sh:1898`

---

## Claim 16: "Returns 0 when the walk fails (TRUTH_WHY=walk, with TRUTH_WHERE walk_why's sentence for where, or empty when the walk does not say: rows 630, 634) ..."

**Location:** `scripts/lib/dev-cycle-read.sh:1888-1889`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truthwalk (:1894-1904). The main walk always yields a sentence (walk_why words an empty IMPORTED_MAIN_WHY as "the walk failed (no reason recorded)"). The tree walk yields one only for readers, and an unknown WALK yields none. Does not establish IMPORTED_MAIN_WHY's per-stage values (unchanged).
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:1895-1899
  TRUTH_WHY=walk; TRUTH_WHERE=""
  case "$1" in
    main) main_imports || { TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"; return 0; } ;;
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
    *) return 0 ;;
```
(excerpt; truthwalk() continues to :1904 — read.) E1's "floor sets a word ..." test exercises both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1894-1904`, `test/scripts/build-loop-check.bats:1533-1543`, `$FC/bats.log`

---

## Claim 17: "The gate's own files: a change to them lands only through a merge-gate- review entry, never a self-merge. The scripts because main's copy runs the next merge (plan D6, D5 item 3); skills/dev-cycle/ because it carries the D6 snippet that copies and runs the gate (plan D4, F52), though sessions load the skill only from a release, so here the floor is stricter than D5. One list for floor and build-loop.sh's --approved, which tests it on its own (floor does not run there); build-loop.sh's header repeats it."

**Location:** `scripts/lib/dev-cycle-read.sh:1918-1924`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan citations (D4 line 61 lists skills/dev-cycle/ as a gate file; D5 item 3 gives the next-merge reason; D6 says the snippet is inline in the installed SKILL.md; D5 "In this repo" says skills reach sessions through a release), GATE_CODE's two readers, and the header's copy. Does not establish that D5 item 3's list (it names `scripts/lib/dev-cycle-read.sh`, not all of `scripts/lib/`) matches GATE_CODE's wider `^scripts/lib/`. The comment's reason does not depend on that.
**Legibility-target:** for-author

Plan D5 item 3: "D6 runs main's copy, so it is live at the next merge" (`docs/working/plan-build-loop-handoff.md:71`). D6: "The snippet is inline in the installed SKILL.md, which is the root-owned image copy" (`:77`). D4: "A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`" (`:61`). The readers are floor at `elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate` (`scripts/lib/dev-cycle-read.sh:1957`) and check_line at `scripts/build-loop.sh:1049`. Floor runs only from srules, which is gated on `sm` (Claim 1). The header lists the same five entries (`scripts/build-loop.sh:232-234`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1918-1925`, `scripts/lib/dev-cycle-read.sh:1957`, `scripts/build-loop.sh:232-234`, `scripts/build-loop.sh:1049`, `docs/working/plan-build-loop-handoff.md:61,66-77`

---

## Claim 18: "Returns 0 with FLOOR_WHY set to a word when the floor refuses (floor_why words it: row 472), else 1. Its gate word is no test of whether a merge touches gate code (floor runs after the rules before it, and not at all under --approved): test GATE_CODE for that."

**Location:** `scripts/lib/dev-cycle-read.sh:1934-1937`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's body (:1952-1969): every refusal branch assigns a word, and the truthrule words precede the gate test (skills/dev-cycle/SKILL.md refuses as instr, not gate). Also covers check_line skipping srules when an N rule already denied. Does not establish floor's behavior on paths beyond T10's list.
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:1955-1957
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY=case; return 0; }
  if truthrule "$lp"; then FLOOR_WHY="$TRUTH_WHY"; [[ "$FLOOR_WHY" != settings ]] || FLOOR_WHY=cycle
  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate
```
(excerpt; floor() continues to :1969 — read; the remaining branches assign record, working, review, TRUTH_WHY (walk/imported) and below.) E1's T10 expects `skills/dev-cycle/SKILL.md "$INSTR"` (`test/scripts/build-loop-check.bats:1304`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1952-1969`, `scripts/build-loop.sh:1048-1050`, `test/scripts/build-loop-check.bats:1287-1316`, `$FC/bats.log`

---

## Claim 19: "a call given $4 that both of main_imports' caches answer ... forks nothing but walk_why's subshell (truthwalk's) after a failed walk"

**Location:** `scripts/lib/dev-cycle-read.sh:1944-1947`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers floor's own forks: with `$4` given, no `$(lower ...)`, and truthwalk's `$(walk_why ...)` only on the failed main walk. Does not count srules' `$(floor_why ...)`, which is the caller's fork (override row, i1 performance F1). Does not re-audit the cache-hit paths of main_imports (unchanged).
**Legibility-target:** for-author

`[[ -n "$lp" ]] || lp="$(lower "$1")"` (`:1955`) skips the fork when `$4` is set. `main) main_imports || { TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"; return 0; }` (`:1897`) is the only command substitution reachable from floor after a failed walk. The other branches (truthrule, ownfile, isstart, walk_has) are bash tests with no `$(...)` (paraphrased — no quote available because the claim covers absence of forks across five helpers).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1872-1882`, `scripts/lib/dev-cycle-read.sh:1894-1904`, `scripts/lib/dev-cycle-read.sh:1952-1969`

---

## Claim 20: "floor_why WORD: the sentence for a FLOOR_WHY word, as walk_why words IMPORTED_MAIN_WHY's; walk reads TRUTH_WHERE, so word it before the next truthwalk." (and its sentences equal the old FLOOR_WHY strings)

**Location:** `scripts/lib/dev-cycle-read.sh:1971-1990`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every word floor can assign (case, instr, dot, cycle, user, record, gate, working, review, walk, imported, below) mapping to the same sentence main's floor set. Covers srules wording it immediately after floor, with no truthwalk between. Does not establish the `*` fallback's reach (no current floor word hits it).
**Legibility-target:** for-author

`walk) echo "the default branch's instruction files could not be walked for @ imports: $TRUTH_WHERE" ;;` (`:1985`) replaces main's `FLOOR_WHY="... for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"`, the same text, since TRUTH_WHERE is that walk_why output (`:1897`). Main's `*) "one of the dev cycle's own files"` covered truthrule's cycle and settings; the new code maps `settings` to `cycle` (`:1956`). srules: `floor "$2" "$1" "$4" "$3"; then DENY="$(floor_why "$FLOOR_WHY")"` (`scripts/build-loop.sh:839`). E1's T10 and the U3a2 deny-line tests pass unchanged.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1952-1990`, `scripts/build-loop.sh:839`, `$FC/bats.log`

---

## Claim 21: ANSWER_AWK prints the heading as a second line only in the single-entry case, and dev-cycle.sh --check-answer output is unchanged

**Location:** `scripts/lib/dev-cycle-read.sh:2069`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the END block (odd, unbalanced, quoted and dup print one line; only `count` alone adds `print head`), check_answer splitting `r` on its first newline, and main-vs-HEAD output on E3's fixture (keep, open, drop, missing). Does not establish identity on the odd/unbalanced/quoted/dup skips (their paths are unchanged code).
**Legibility-target:** for-author

```
# scripts/lib/dev-cycle-read.sh:2064-2069
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else if (qline) print "quoted " qline
  else if (count > 1) print "dup"
  else if (count) { print (!answered ? "open" : done ? result : "unrecognized"); print head }
```
`hit="${r%%$'\n'*}"; head="${r#*$'\n'}"` (`:2105`); `echo "$hit $a"` (`:2107`). E3: main's and HEAD's `--check-answer` outputs are byte-identical (`IDENTICAL`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2017-2107`, `$FC/probe2.out`, `$FC/main-ca.out`, `$FC/head-ca.out`

---

## Claim 22: "With an answer line it sets ANSWER_HEADING to the entry's heading after "### " ("Q-NNN · SLUG", CR dropped), else empties it; a caller that reads it (build-loop.sh --approved) calls check_answer in its own shell, its output to a file."

**Location:** `scripts/lib/dev-cycle-read.sh:2076-2079`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ANSWER_HEADING's set and empty points, CR removal and blank preservation. Does not establish the heading's form: it is the raw heading text, not necessarily "Q-NNN · SLUG". `### Q-003  two spaces` yields `Q-003  two spaces`, which approval's exact compare then refuses.
**Legibility-target:** for-author

The CR-dropped and emptied-otherwise parts hold. E2 printed `keep Q-001 | [Q-001 · merge-x-abc]` for a CRLF entry, with no `\r` in the od check, and `[]` for the missing and malformed IDs. `ANSWER_HEADING=""` runs on entry (`:2084`), and `ANSWER_HEADING="$head"` runs only with a hit (`:2107`). "With an answer line" is imprecise. In this file's own vocabulary, the ANSWER_AWK comment above (`:2006-2010`) uses "answer" for the entry's `Q-NNN:` or `**Answer` line. But ANSWER_HEADING is also set for an open entry, or an answered one with no such line: E2's `open Q-002 | [Q-002 · merge-y]`. The precise version: "With any line but a skip (keep, drop, done, open, unrecognized) it sets ANSWER_HEADING ...; on a skip it empties it."

**Evidence:** `scripts/lib/dev-cycle-read.sh:2061-2107`, `$FC/probe1.out`

---

## Claim 23: "rv [FILE]: review policy, brief x (no Policy: line, so review) and feat/x with one commit (that also adds FILE, when given), then Q-001 answered [1] as merge-2026-10-01-x-SHA12 (S); T the tip, TR the merged tree." (and approve()'s comment)

**Location:** `test/scripts/build-loop-merge.bats:184-186`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rv's and approve()'s bodies and the fixture `work`; the approve() comment (`:175-177`) is accurate. Does not establish any effect on assertions: the gate test checks only `lines[0]` and the tip, so the second commit changes no outcome.
**Legibility-target:** for-author

With FILE given, feat/x gets two commits, not one commit that also adds FILE. `work feat/x` commits first (`work() { ... echo "$1" > "work-${1//\//-}.txt" && commit_all "work on $1" ...}`, `test/lib/build-loop-fixtures.bash:58-61`). rv then adds a second one: `git checkout -q feat/x && mkdir -p "$(dirname "$1")" && echo g > "$1" && commit_all gate` (`test/scripts/build-loop-merge.bats:189`). A reader who relies on `feat/x^` being main, or on a one-commit branch, is misled. The precise version: "feat/x with one commit (and a second adding FILE, when given)". Test-helper comment only.

**Evidence:** `test/scripts/build-loop-merge.bats:175-192`, `test/lib/build-loop-fixtures.bash:58-61`

---

## Claim 24: Commit 18f32952: "test(build-loop): U3a3 --merge --approved contract tests (T35, rows 221, 653, 661). Red until the --approved code lands." Notes: refusal text, message and trailer wording chosen here.

**Location:** `18f32952` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five --approved tests failing at 18f32952 and passing at HEAD (E1). Does not establish which refusal strings later changed (e25a6e89 reworded option 2/3, as its message says).
**Legibility-target:** for-author

E4: at 18f32952, `bats -f approved` gives `1..5` with five `not ok`. The commit touches only `test/scripts/build-loop-merge.bats` (`git show --stat`: 84 insertions, 2 deletions), including the row 661 refusal text change (diff line `-... --merge lands only a self-merge brief` / `+... lands it only with --approved Q-NNN`).

**Evidence:** `test/scripts/build-loop-merge.bats` at 18f32952, `$FC/at18-bats.log`

---

## Claim 25: Commit a7a4f784: the --approved summary, AUTH (row 653), refusal (row 661), trailer, reflog; "Lib: check_answer sets ANSWER_HEAD ...; floor sets a word in FLOOR_WHY and floor_why words it (row 472); truthwalk sets TRUTH_WHERE for both walks' failures, so check_fix no longer repeats the reader-settings sentence (rows 630, 634)."

**Location:** `a7a4f784` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each sentence against a7a4f784's diff. Does not re-verdict ANSWER_HEAD, which was accurate at that commit and renamed in e25a6e89. The "both walks" wording is rubric C5 / i1 claim 23, settled as corrected in the merge message.
**Legibility-target:** for-orchestrator-synthesis

Every part holds but one. "TRUTH_WHERE for both walks' failures" overstates the tree walk. truthwalk sets TRUTH_WHERE there only for a readers failure: `[[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"` (`scripts/lib/dev-cycle-read.sh:1898`), and the tree walk's other failures leave it empty (Claim 14). The precise version: "for the main walk's failures and the tree walk's readers failure". Already settled (C5); listed for completeness.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1894-1904`, `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a3.md` (C5)

---

## Claim 26: Commit e25a6e89: R1 GATE_CODE gains ^skills/dev-cycle/ (plan D4, F52) ... "stricter than plan D5 item 3, which lists the scripts alone"; A1, A2/A3, C2, comment fixes; "Tests: option 2/3/unread, a skills/dev-cycle/ gate path, the questions archive N-denied under --approved"; "9 override-log rows (8 declined findings, 1 pre-existing flake)"

**Location:** `e25a6e89` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's diff to the scripts, the tests and override-log.md (nine `+|` rows: A1, C1, C6, C8, C9, C10, C12 and C13 findings plus the config_seeds flake). Does not establish the review artifacts' contents.
**Legibility-target:** for-author

The override-log diff adds nine table rows: eight cite i1 findings, and the ninth is "config_seeds' `find -H ANCESTOR -maxdepth 1 -xtype f` fails when an entry vanishes ...". The test diff adds `"Q-001: [2]"`/`[3]`/`merge` cases, `skills/dev-cycle/references/x.md` in the gate loop, and `docs/working/questions-archive.md` denied under --approved. Plan D5 item 3 names the four scripts only (`docs/working/plan-build-loop-handoff.md:71`).

**Evidence:** `git show e25a6e89 -- docs/reviews/override-log.md test/scripts/build-loop-merge.bats`, `docs/working/plan-build-loop-handoff.md:71`

---

## Claim 27: Commit 01a2935f: GATE_CODE's comment gives both reasons and says the floor is stricter than D5; "T10 refuses skills/dev-cycle/ paths (any case) and passes skills/dev-cycle-x/"; header says --expect still binds the tip, points the gate list at GATE_CODE, puts the prefix sentence after the landing rule; "T35 adds a mismatched --expect under --approved"; "2 override rows (health-check.sh, routed to Q-103/U5; sibling skills, U4)"

**Location:** `01a2935f` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit's diff and E1's pass of the named tests. Does not establish the rubric's or the iteration-2 reviews' contents.
**Legibility-target:** for-author

T10 (`@test "floor: ... (T10, U2a4)"`) gains `skills/dev-cycle/references/x.md "$GATE" Skills/Dev-Cycle/x.sh "$GATE" skills/dev-cycle/SKILL.md "$INSTR"` and passes `skills/dev-cycle-x/a.md` (`test/scripts/build-loop-check.bats:1304,1312`). T35 gains `mrg "$B" --expect "$M" --approved Q-001` (`test/scripts/build-loop-merge.bats:236`). The override-log diff adds two rows: health-check.sh ("Defer (routed) ... U5's Q-103 re-route") and sibling skills ("Defer ... U4's merge-entry body"). Header order: the "pins only TIP's prefix" sentence follows "approved merge of STEM" (`scripts/build-loop.sh:236`).

**Evidence:** `git show 01a2935f`, `test/scripts/build-loop-check.bats:1287-1316`, `test/scripts/build-loop-merge.bats:227-242`, `scripts/build-loop.sh:225-239`, `$FC/bats.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 23** (`test/scripts/build-loop-merge.bats:184`): rv's comment says feat/x has "one commit (that also adds FILE, when given)". With FILE given, rv makes a second commit (`commit_all gate`) on top of work's. Say "one commit (and a second adding FILE, when given)". Test-helper comment; no assertion depends on it.

### Stale
- None.

### Mostly Accurate
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:35-38`): "its output to a file under set -e". The one caller (approval) runs inside an `elif` condition (`scripts/build-loop.sh:1226`), where set -e is off. It is harmless because nothing in check_answer exits or fails. Drop "under set -e" or say it does not matter.
- **Claim 22** (`scripts/lib/dev-cycle-read.sh:2076`): "With an answer line it sets ANSWER_HEADING": it is set for any non-skip line, open included (an entry with no answer line). The value is the raw heading, not necessarily "Q-NNN · SLUG".
- **Claim 25** (`a7a4f784` message): "TRUTH_WHERE for both walks' failures": the tree walk sets it only for a readers failure. Already settled as rubric C5 (corrected in the merge message).

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to the output path below in the code-fact-check skill's format, with `Commit: 01a2935f` at the top."

This report sits at `docs/reviews/code-fact-check-report-u3a3-final-r3.md` with `Commit: 01a2935f` as its first line, in the skill's format. Every claim from brief items 1-7 was checked against callers and tests. The serial bats run (E1) passed all 237 tests. No behavioral defect in the gate was found. The one Incorrect is a test-helper comment, and the three Mostly accurate are comment/commit wordings; none weakens a refusal. Nothing was committed.
