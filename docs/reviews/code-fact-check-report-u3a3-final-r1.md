Commit: 01a2935f

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a3 (feat/build-loop-u3a3)
**Scope:** `git diff main...HEAD` (18f32952, a7a4f784, e25a6e89, 01a2935f): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/build-loop-merge.bats, the four commit messages. Final confirming pass, replicate 1 of 3. Delivery: self-read.
**Checked:** 2026-10-10
**Total claims checked:** 28
**Summary:** 22 verified, 5 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. None of the five logged patterns matches a claim here. All five are measured values quoted from an artifact set, or file-to-symbol associations. The nearest analogue is the "9 override-log rows" and "2 override rows" counts in claims 27-28. Both were recounted and match.

## Execution provenance

All probes ran under `timeout`, in `$FC` = `/tmp/claude-1000/-workspace/675070f9-0197-40a3-bd3c-520157521989/scratchpad/u3a3-final/fc1`. Nothing was written in the worktree except this report.

| ID | Command (cwd) | Timestamp (UTC) | Exit | Output |
|---|---|---|---|---|
| E1 | `timeout 1500 bats test/scripts/build-loop-merge.bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` (worktree; serial, no -j) | 2026-10-10T23:54:56Z | 1 (233 of 237 ok; tests 40, 144, 151, 153 failed) | `$FC/bats.log` |
| E2 | `timeout 600 bats -f '<the 4 failed names>' test/scripts/build-loop-check.bats` (worktree) | 2026-10-10T23:57:14Z | 0 (4 of 4 ok) | `$FC/bats-rerun.log` |
| P1 | `timeout 60 env LC_ALL=C bash <S>/dev-cycle.sh --check-answer Q-001 Q-002 Q-003 Q-004 Q-005 Q-009`, with S = main's scripts (`git show main:` into `$FC/mainsc`) and S = the branch's scripts (cwd `$FC/repo`, a fixture questions.md holding a CRLF entry, open, unrecognized, drop, dup, missing) | 2026-10-10T23:57:44Z | 0, 0 | `$FC/p1-check-answer.out` |
| P2 | `timeout 60 env LC_ALL=C bash $FC/p2.sh <worktree>/scripts/lib/dev-cycle-read.sh $FC` (cwd `$FC/repo`; `set -euo pipefail`; check_answer to a file, then ANSWER_HEADING printed; also via `$(...)`) | 2026-10-10T23:58:07Z | 0 | `$FC/p2-heading.out` |
| P3 | `timeout 10 bash $FC/p3.sh` (a function that runs `false` and then continues, called as `elif [[ ... ]] && ! f` under `set -euo pipefail`) | 2026-10-10T23:58:07Z | 0 | `$FC/p3.out` |
| P4 | `git archive 18f32952 \| tar -x -C $FC/at18f`, then `timeout 600 bats -f approved test/scripts/build-loop-merge.bats` (cwd `$FC/at18f`) | 2026-10-10T23:58:57Z | 1 (5 of 5 not ok) | `$FC/p4-red-at-18f.out` |

E1's failures 40, 151 and 153 print `find: '/tmp/tmp.XXXX': No such file or directory`. That is the brief's known config_seeds flake: a sibling under /tmp vanishes, and other sessions share /tmp. Failure 144 printed `line: Paths:|is not exactly ...` with no find message. All four passed on the serial rerun (E2). Test 144's cause was not isolated. It is a pre-existing U2c1 test whose code this diff does not touch.

---

## Claim 1: "--merge lands a self-merge brief (D7), or with --approved a brief of either policy: --check's lines for BRIEF at --expect's tip (under --approved, without the S rules or the checkout refusal; --expect still binds the tip)"

**Location:** `scripts/build-loop.sh:213-217`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_line's `sm` switch: under AUTH=approved it is never set, so neither checkout_gate, read_paths nor srules runs. Also covers the --expect test, which runs before `sm` is read, and the merge arm's policy refusal, which only AUTH=self-merge reaches. Does not establish that the N rules alone are the right rule set for a review brief (a policy question settled by plan line 213).
**Legibility-target:** for-author

`[[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout` (`scripts/build-loop.sh:990`). The checkout test, read_paths and srules each run only when `sm` is set: `co=""; if [[ -n "$sm" ]] && ! checkout_gate; then` (`:1032`), `[[ -z "$sm" ]] || read_paths` (`:1035`), `[[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules ...` (`:1050`). The --expect test does not depend on AUTH: `if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi` (`:994`). The merge arm refuses a review brief only without --approved: `if [[ "$AUTH" == self-merge && "${VERDICT[policy]}" != self-merge ]]` (`:1225`). Executed in E1: test 9 lands a self-merge brief past its never glob, its `Paths: none` and a checkout at feat/x. Test 10 refuses `--expect $M` under --approved with the tip message.

**Evidence:** `scripts/build-loop.sh:990-994`, `scripts/build-loop.sh:1032-1050`, `scripts/build-loop.sh:1218-1229`, `$FC/bats.log`

---

## Claim 2: "With --approved Q-NNN it lands a brief of either policy under the N rules alone (no S rules, no checkout rule) when the questions entry Q-NNN, read from the default branch's commit as --check-answer reads it, is answered with option 1 under the heading exactly "### Q-NNN · merge-STEM-SHA12" (SHA12: TIP's first 12 hex digits), or "merge-gate-STEM-SHA12" when a changed path, lower-cased, is the gate's own code (the lib's GATE_CODE: scripts/build-loop.sh, dev-cycle.sh, questions.sh, anything under scripts/lib/ or skills/dev-cycle/)"

**Location:** `scripts/build-loop.sh:225-234`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers approval's slug build and its exact heading compare, check_answer as the single reader (the same function --check-answer calls), the gate bit taken from the lower-cased paths, and the GATE_CODE regex matching the header's list. Does not establish what happens on a case-insensitive filesystem beyond lower-casing, or that the merge-entry filer (U4) writes this heading.
**Legibility-target:** for-author

Slug: `local r s="merge-" g=""`, `[[ -z "${VERDICT[gate]}" ]] || { s="merge-gate-"; ...}`, `s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"` (`scripts/build-loop.sh:1079-1081`). Compare: `[[ "$ANSWER_HEADING" == "$1 · $s" ]]` (`:1092`). ANSWER_HEADING is the heading after `### ` (`head = substr($0, 5)`, `scripts/lib/dev-cycle-read.sh:2040`), and only a line starting `### ` counts as a heading: `if (substr(l, 1, 4) != "### ") return 0` (`:2033`). So the full heading must be exactly `### Q-NNN · SLUG`. Gate bit: `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`scripts/build-loop.sh:1049`), where `lps` comes from the single lower_all pass (`:1045`). The regex is `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1925`), which matches the header's list. dev-cycle.sh's --check-answer runs the same function: `--check-answer) check_answer "$a" ;;` (`scripts/dev-cycle.sh:209`). Executed in E1: test 8 lands under `merge-STEM-SHA12`. Test 10 refuses another stem, `${M:0:12}`, a merge-gate- slug on a non-gate merge, a trailing space and a suffix. Test 11 needs merge-gate- for `scripts/build-loop.sh`, `Scripts/Lib/x.sh` and `skills/dev-cycle/references/x.md`.

**Evidence:** `scripts/build-loop.sh:1045-1049`, `scripts/build-loop.sh:1078-1094`, `scripts/lib/dev-cycle-read.sh:1925`, `scripts/lib/dev-cycle-read.sh:2032-2040`, `scripts/dev-cycle.sh:209`, `$FC/bats.log`

---

## Claim 3: "then the message reads "(build-loop approved merge)" with a second trailer "Build-loop-approved: Q-NNN", and the reflog "build-loop: approved merge of STEM""

**Location:** `scripts/build-loop.sh:234-237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit message, both trailers and the reflog subject on the compare-and-swap path. Does not establish the reflog subject on the W (fast-forward) path under --approved. There git appends ": Fast-forward", as the header says for self-merge; no test covers it under --approved.
**Legibility-target:** for-author

`what="$1"`, `[[ "$1" != approved ]] || what="approved merge"`, `msg="build-loop: $what of ${VERDICT[stem]}"` (`scripts/build-loop.sh:1111-1113`). The message: `printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" ... "$what" ...` followed by `[[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"` (`:1178-1179`). The reflog: `git update-ref --no-deref -m "$msg"` (`:1186`), or `GIT_REFLOG_ACTION="$msg"` in W (`:1192`). Executed in E1, test 8: the body equals `Merge branch 'feat/x' (build-loop approved merge)` / blank / `Build-loop-gate: 2026-10-01-x` / `Build-loop-approved: Q-001`, and `git reflog -1 --format=%gs main` equals `build-loop: approved merge of 2026-10-01-x`.

**Evidence:** `scripts/build-loop.sh:1110-1113`, `scripts/build-loop.sh:1178-1194`, `test/scripts/build-loop-merge.bats:194-205`, `$FC/bats.log`

---

## Claim 4: "The heading pins only TIP's prefix: --expect binds the full tip, so the caller passes the full TIP it filed the entry for, never the branch's live tip."

**Location:** `scripts/build-loop.sh:237-240`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that approval reads only `${VERDICT[tip]:0:12}` and that check_line compares the full --expect id to the tip. Does not establish that any caller follows the instruction (U4's filer; override row A1).
**Legibility-target:** for-author

`s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"` (`scripts/build-loop.sh:1081`). The full tip is compared only through EXPECT: `[[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]` (`:994`). EXPECT must be a full 40- or 64-hex id (`:318`), and --merge requires it (`:326`). Executed in E1, test 10: `mrg "$B" --expect "$M" --approved Q-001` refuses with `the tip of feat/x is $T, not the expected $M`.

**Evidence:** `scripts/build-loop.sh:318-326`, `scripts/build-loop.sh:994`, `scripts/build-loop.sh:1081`, `test/scripts/build-loop-merge.bats:235-237`, `$FC/bats.log`

---

## Claim 5: "refuse BRIEF: WHY ... when: without --approved, the policy --status reads is review; with it, Q-NNN is open, skipped (WHY quotes the skip) or answered with another option or an answer not read (WHY names which), or its heading is not the one above"

**Location:** `scripts/build-loop.sh:247-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each approval refusal and the review-policy refusal, plus the path lines that follow the refusal (`tail -n +2`). Does not establish the wording of skip reasons beyond those the tests exercise (open, missing entry); others pass through check_answer's own text unchanged.
**Legibility-target:** for-author

`"open $1") MERGE_WHY="$1 does not approve this merge: it is not answered on the default branch"`, `"skip $1: "*) MERGE_WHY="$1 does not approve this merge: ${r#"skip $1: "}"`, `"drop $1") ... is option 2`, `"done $1") ... is option 3`, `*) ... is not read as an option ([1], 1 or keep approve)` (`scripts/build-loop.sh:1086-1090`). Heading: `MERGE_WHY="$1 approves no merge of this tip: its heading must read \"$1 · $s\"$g"` (`:1093`). Output: `{ echo "$v"; tail -n +2 "$GATE_TMP/line"; }` (`:1228`). Executed in E1: test 10 covers option 2, option 3, `merge` (not read), OPEN, an ANSWERED edit only in the working tree (reads as open), Q-002 (the skip text quoted) and five heading mismatches. Test 3 (U3a2) covers the review-policy refusal text.

**Evidence:** `scripts/build-loop.sh:1083-1093`, `scripts/build-loop.sh:1225-1228`, `test/scripts/build-loop-merge.bats:227-242`, `$FC/bats.log`

---

## Claim 6: check_line's comment: "VERDICT holds tip, tree, policy, branch, stem and gate (1 when a changed path, lower-cased, is the gate's own code, GATE_CODE; else empty) ... AUTH ... empty for --check and self-merge for --merge, where a brief --status reads as self-merge gets the S rules and its checkout checked; approved (--merge --approved) runs the N rules alone, whatever the policy." Also brief item 2: --check and plain --merge are unchanged.

**Location:** `scripts/build-loop.sh:971-978`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers verdict_ok's keys, `gc` set from every lower-cased changed path, AUTH's values (`""` at top level, set only in the merge arm), and that `sm` is set exactly when the old `pol == self-merge` test held whenever AUTH is not approved. Does not establish that --check output reveals the gate bit (it does not: override row C1).
**Legibility-target:** for-author

`VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem" [gate]="$gc")` (`scripts/build-loop.sh:1039`). `gc` starts as `gc=""` (`:984`) and is set by `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`:1049`), which runs for every path, denied ones included. `AUTH=""` (`:980`). Only the merge arm assigns it: `AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved` (`:1219`). For --check and plain --merge, `sm` is set iff `pol == self-merge` (`:990`), the same predicate the old code used at each site (diff: `-  co=""; if [[ "$pol" == self-merge ]] && ...`). Executed in E1: every U3a2 --merge test and every --check test passes (233 of 237; the four flaky failures pass on rerun, E2).

**Evidence:** `scripts/build-loop.sh:979-990`, `scripts/build-loop.sh:1037-1053`, `scripts/build-loop.sh:1219`, `$FC/bats.log`, `$FC/bats-rerun.log`

---

## Claim 7: approval's comment: "whether the questions entry Q-NNN, read from main's commit by check_answer (D8: an answer only in a working tree counts for nothing), approves landing VERDICT: answered with option 1 under the heading ...; exactly, so an answer for another brief, an older tip or a merge without the gate's code does not carry. Sets MERGE_WHY and returns 1 when it does not."

**Location:** `scripts/build-loop.sh:1071-1077`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers approval from its signature to its final line: the single check_answer call (which reads `git cat-file blob "$MAIN_SHA:$f"`), the accept-only-keep case, and the exact-string heading compare. Does not establish that MAIN_SHA cannot move between the answer read and land's compare-and-swap (land's CAS from MAIN_SHA covers the landing; the brief records the security endorsement as pending).
**Legibility-target:** for-author

`check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"`, then `"keep $1") ;;`, with every other case returning 1 (`scripts/build-loop.sh:1083-1091`). check_answer reads main's blob: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...)"` (`scripts/lib/dev-cycle-read.sh:2095`). Executed in E1, test 10: an answer edited only in the working tree is refused as open, and another stem, an older tip and a merge-gate- slug on a non-gate merge are each refused.

**Evidence:** `scripts/build-loop.sh:1078-1094`, `scripts/lib/dev-cycle-read.sh:2082-2109`, `$FC/bats.log`

---

## Claim 8: "In this shell, to a file: ANSWER_HEADING would not leave a $(...)."

**Location:** `scripts/build-loop.sh:1082`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a `$(check_answer ...)` subshell leaves the caller's ANSWER_HEADING unchanged, while a call redirected to a file sets it. Does not establish anything about set -e at this call site (see claim 12).
**Legibility-target:** for-author

Executed in P2: after `ANSWER_HEADING=stale; out="$(check_answer Q-001)"` the probe prints `via $(...): keep Q-001 | [stale]`. The redirected call prints `keep Q-001 | [Q-001 · merge-x-abc]`.

**Evidence:** `scripts/build-loop.sh:1082-1083`, `$FC/p2-heading.out`

---

## Claim 9: approval's refusal words match check_answer's lines: keep approves; open, skip, drop (option 2), done (option 3), and anything else, unrecognized included, "is not read as an option ([1], 1 or keep approve)"

**Location:** `scripts/build-loop.sh:1084-1090`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ANSWER_AWK's option() mapping ([1]/1/keep to keep, [2]/2/drop to drop, [3]/3/done to done) against approval's case arms, and check_answer's complete line set (keep, drop, done, open, unrecognized, or a skip; dup, odd, unbalanced and quoted all become skips). Does not establish the exact skip texts beyond those quoted.
**Legibility-target:** for-author

`if (substr(s, 1, 3) == "[1]") return "keep"` ... `if (w == "1" || w == "keep") return "keep"`, `if (w == "2" || w == "drop") return "drop"`, `return "done"` (`scripts/lib/dev-cycle-read.sh:2020-2030`). check_answer turns dup, odd, unbalanced and quoted into `skip` lines (`:2098-2102`) and prints `"$hit $a"` otherwise (`:2107`). Executed in E1, test 10: [2], [3] and `merge` give the three texts.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2018-2031`, `scripts/lib/dev-cycle-read.sh:2064-2070`, `scripts/lib/dev-cycle-read.sh:2098-2108`, `scripts/build-loop.sh:1084-1090`, `$FC/bats.log`

---

## Claim 10: land's comment: "land AUTHORITY [Q-NNN]: ... under the authority the caller checked and names (self-merge, or approved with its question), which the message and reflog carry. Decide (the header's refusals but the policy's, approval's and --check's: ...)"

**Location:** `scripts/build-loop.sh:1095-1098`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers land from its signature to its final line. It reads neither VERDICT[policy] nor check_answer, so the policy and approval refusals are the merge arm's, and $1 and $2 reach only `what`, `msg` and the trailer. Does not establish the other refusals land owns (worktree and state checks), which this diff does not change.
**Legibility-target:** for-author

Inside land, $1 and $2 are used only at `what="$1"`, `[[ "$1" != approved ]] || what="approved merge"` (`scripts/build-loop.sh:1111-1112`) and `[[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"` (`:1179`). The policy refusal and approval are in the merge arm (`:1225-1226`). land never reads VERDICT[policy] and never calls approval or check_answer (paraphrased — no quote available because the claim covers absence of code: no `policy`, `approval` or `check_answer` token appears in `:1110-1196`).

**Evidence:** `scripts/build-loop.sh:1095-1196`, `scripts/build-loop.sh:1218-1229`

---

## Claim 11: land keys the trailer on the authority, as it does the message (rubric A3)

**Location:** `scripts/build-loop.sh:1178-1179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message, reflog and trailer, all keyed on `$1 == approved`. Does not establish that $2 is non-empty when $1 is approved. The merge arm guarantees it (`AUTH=approved` only when APPROVED is non-empty, `:1219`), but land does not check it.
**Legibility-target:** for-author

`[[ "$1" != approved ]] || what="approved merge"` (`scripts/build-loop.sh:1112`) and `[[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"` (`:1179`).

**Evidence:** `scripts/build-loop.sh:1111-1113`, `scripts/build-loop.sh:1178-1179`, `scripts/build-loop.sh:1219`

---

## Claim 12: "A caller that also reads ANSWER_HEADING (check_answer's side value: the entry's heading) runs check_answer in its own shell, its output to a file under set -e, since a $(...) would drop the value; check_answer reaches no need_root (it reads only git objects), so nothing exits there."

**Location:** `scripts/lib/dev-cycle-read.sh:35-38`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one caller (approval): it calls check_answer in its own shell with output to a file, and check_answer reaches no need_root. Does not hold for "under set -e" at that caller, where set -e is suspended. Does not establish any other caller (grep finds none).
**Legibility-target:** for-author

The own-shell, to-a-file part matches `check_answer "$1" > "$GATE_TMP/answer"` (`scripts/build-loop.sh:1083`). The "nothing exits there" part matches check_answer's body (`scripts/lib/dev-cycle-read.sh:2082-2109`). Its callees (main_by_name, main_entry, entry_why, oddwhy, git, awk) call no need_root (paraphrased — no quote available because the claim covers absence of code: those callees contain no need_root or readers_root call). The "under set -e" part does not hold in effect at that caller. approval is called only as `elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"; then` (`scripts/build-loop.sh:1226`), and bash ignores errexit inside a function called from an `elif` condition or under `!`. Executed in P3: a function in that position runs `false` and prints `continued past false inside f`, exit 0. Nothing depends on it today. If the redirect fails, `r` reads empty and approval refuses through the catch-all arm. A precise version: "...its output to a file (set -e or not: nothing in check_answer exits)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:32-38`, `scripts/build-loop.sh:1083`, `scripts/build-loop.sh:1226`, `$FC/p3.out`, `$FC/p2-heading.out`

---

## Claim 13: "The tree walk's IMPORTED_WHY is readers when import_readers fails, else empty (its other failures are not told apart)."

**Location:** `scripts/lib/dev-cycle-read.sh:808-809`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every assignment of IMPORTED_WHY and imported_names' cache path. A cache hit needs IMPORTED_DONE, which is set only on the line that empties IMPORTED_WHY. A memoized import_readers refusal sets readers again. Does not establish anything about the main walk's IMPORTED_MAIN_WHY.
**Legibility-target:** for-author

The only assignments are the initializer (`:810`), `import_readers || { IMPORTED_DONE=""; IMPORTED=error; IMPORTED_WHY=readers; return 1; }` (`:1637`) and `IMPORTED_DONE="$IMPORT_ROOTS"...; IMPORTED=error; IMPORTED_WHY=""` (`:1641`). A grep of scripts/ for IMPORTED_WHY finds no other writer (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-810`, `scripts/lib/dev-cycle-read.sh:1633-1643`, `scripts/lib/dev-cycle-read.sh:1159-1166`

---

## Claim 14: "walk_why WHY: the sentence for an IMPORTED_MAIN_WHY word (or the tree walk's IMPORTED_WHY, which is only ever readers)"

**Location:** `scripts/lib/dev-cycle-read.sh:811-812`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers walk_why's readers arm and truthwalk tree's call, which runs only when IMPORTED_WHY is non-empty. Does not establish the registry-failure branch's output in a test. With IMPORT_READER_WHY empty, `readers` words as "the worktree registry could not be read, ...". That is new text in check_fix's skip (see claim 23's scope), and no test asserts it.
**Legibility-target:** for-author

`readers) [[ -n "$IMPORT_READER_WHY" ]] && echo "the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY" || echo "the worktree registry could not be read, ..."` (`scripts/lib/dev-cycle-read.sh:821-822`). Caller: `tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;` (`:1898`). Executed in E1, test 111: `tree [walk] the reader settings of docs/dev-cycle.md cannot be used: planted`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:811-834`, `scripts/lib/dev-cycle-read.sh:1898`, `test/scripts/build-loop-check.bats:1533-1543`, `$FC/bats.log`

---

## Claim 15: truthwalk: "Returns 0 when the walk fails (TRUTH_WHY=walk, with TRUTH_WHERE walk_why's sentence for where, or empty when the walk does not say: rows 630, 634) ..."

**Location:** `scripts/lib/dev-cycle-read.sh:1888-1892`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truthwalk from its signature to its final line. TRUTH_WHERE is emptied on entry. A failed main walk always words IMPORTED_MAIN_WHY (walk_why's `*` arm gives a sentence even for an empty word, so the main walk's TRUTH_WHERE is never empty after a failure). The tree walk words it only for readers. An unknown WALK leaves it empty. Does not establish behavior when walk_why's subshell fails (it only echoes).
**Legibility-target:** for-author

`TRUTH_WHY=walk; TRUTH_WHERE=""`, `main) main_imports || { TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"; return 0; } ;;`, `tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE=...; return 0; } ;;`, `*) return 0 ;;` (`scripts/lib/dev-cycle-read.sh:1895-1899`). Executed in E1, test 111: `[walk] <WALKFAIL>: <R>` from floor (main walk) and `tree [walk] <R>`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1883-1904`, `$FC/bats.log`

---

## Claim 16: GATE_CODE's comment: "The gate's own files: a change to them lands only through a merge-gate- review entry, never a self-merge. The scripts because main's copy runs the next merge (plan D6, D5 item 3); skills/dev-cycle/ because it carries the D6 snippet that copies and runs the gate (plan D4, F52), though sessions load the skill only from a release, so here the floor is stricter than D5. One list for floor and build-loop.sh's --approved, which tests it on its own (floor does not run there); build-loop.sh's header repeats it."

**Location:** `scripts/lib/dev-cycle-read.sh:1918-1924`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plan references (D4 line 61 lists skills/dev-cycle/ and cites F52; D5 item 3 lists the scripts alone and says D6 runs main's copy; D5 says a release is the real gate), GATE_CODE's two consumers, floor never running under --approved, and the header copy. Does not hold for "carries the D6 snippet" in the present tense: the repository's skills/dev-cycle/SKILL.md contains no snippet today. Plan D6 and step 10 (U4) put it there.
**Legibility-target:** for-author

Plan: "A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52)." (`docs/working/plan-build-loop-handoff.md:61`). D5 item 3: "the gate's own code (`scripts/build-loop.sh`, ...). D6 runs main's copy, so it is live at the next merge." (`:71`). D6: "The snippet is inline in the installed SKILL.md" (`:77`). U4 adds "the D6 snippet" (`:323`). `grep -n -i 'snippet\|build-loop.sh' skills/dev-cycle/SKILL.md` returns nothing, and the directory holds only SKILL.md (paraphrased — no quote available because the claim covers absence of text). So "carries" describes the planned skill, not HEAD's file. Read as "will carry (plan D6; U4 adds it)", the claim is exact. Consumers: `elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate` (`scripts/lib/dev-cycle-read.sh:1957`) and `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`scripts/build-loop.sh:1049`). floor is reached only through srules (`:839`), which needs `sm`, and --approved never sets it (`:990`). Header copy: `scripts/build-loop.sh:232-234`. Executed in E1: test 11 (merge-gate- for skills/dev-cycle/references/x.md) and T10 (`skills/dev-cycle/references/x.md` and `Skills/Dev-Cycle/x.sh` refuse as gate; `skills/dev-cycle-x/a.md` passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1918-1925`, `docs/working/plan-build-loop-handoff.md:23`, `docs/working/plan-build-loop-handoff.md:61`, `docs/working/plan-build-loop-handoff.md:71`, `docs/working/plan-build-loop-handoff.md:77`, `docs/working/plan-build-loop-handoff.md:323`, `skills/dev-cycle/SKILL.md`, `scripts/build-loop.sh:232-234`, `scripts/build-loop.sh:839`, `scripts/build-loop.sh:990`, `scripts/build-loop.sh:1049`, `$FC/bats.log`

---

## Claim 17: floor: "Returns 0 with FLOOR_WHY set to a word when the floor refuses (floor_why words it: row 472), else 1. Its gate word is no test of whether a merge touches gate code (floor runs after the rules before it, and not at all under --approved): test GATE_CODE for that."

**Location:** `scripts/lib/dev-cycle-read.sh:1934-1937`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor from its signature to its final line. Every refusing branch assigns a bare word. truthrule runs first, so a gate path that is also an instruction file words as instr. floor is never called under --approved. Does not establish how srules is ordered against the never globs (unchanged).
**Legibility-target:** for-author

`FLOOR_WHY=case`, `FLOOR_WHY="$TRUTH_WHY"; [[ "$FLOOR_WHY" != settings ]] || FLOOR_WHY=cycle`, `FLOOR_WHY=gate`, `=record`, `=working`, `=review`, `FLOOR_WHY="$TRUTH_WHY"  # walk ... or imported`, `FLOOR_WHY=below` (`scripts/lib/dev-cycle-read.sh:1955-1966`). Executed in E1, T10: `skills/dev-cycle/SKILL.md` gives `$INSTR`, not `$GATE`. Test 111 prints `[gate] ...` and `[walk] ...`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1952-1970`, `test/scripts/build-loop-check.bats:1287-1313`, `$FC/bats.log`

---

## Claim 18: floor's cost sentence: "a call given $4 that both of main_imports' caches answer ... forks nothing but walk_why's subshell (truthwalk's) after a failed walk"

**Location:** `scripts/lib/dev-cycle-read.sh:1944-1947`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers floor's own body: with $4 set it skips `$(lower ...)`, and its only other fork is truthwalk main's `$(walk_why ...)` on a failed walk. Does not count srules' `$(floor_why ...)`, which sits outside floor (override row C6), or forks inside the cached main_imports path (not re-read here beyond its cache test).
**Legibility-target:** for-author

`[[ -n "$lp" ]] || lp="$(lower "$1")"` (`scripts/lib/dev-cycle-read.sh:1955`). The remaining branches use only `[[ ]]`, truthrule, ownfile, isstart and walk_has (`:1956-1966`). The single `$(...)` reached from floor's call into truthwalk is `TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"` (`:1897`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1944-1970`, `scripts/lib/dev-cycle-read.sh:1894-1904`, `scripts/build-loop.sh:839`

---

## Claim 19: "floor_why WORD: the sentence for a FLOOR_WHY word, as walk_why words IMPORTED_MAIN_WHY's; walk reads TRUTH_WHERE, so word it before the next truthwalk." The words match the old sentences, and srules uses floor_why.

**Location:** `scripts/lib/dev-cycle-read.sh:1971-1990`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every word floor can set (case, instr, dot, cycle, user, record, gate, working, review, walk, imported, below), each sentence compared with the removed text, and srules wording it immediately after floor returns. Does not establish behavior for a caller that runs another truthwalk between floor and floor_why (none exists).
**Legibility-target:** for-author

Each arm's text equals the removed floor sentence (diff `-` lines 357-383 against `+` lines 394-405), and `walk) echo "the default branch's instruction files could not be walked for @ imports: $TRUTH_WHERE"` (`scripts/lib/dev-cycle-read.sh:1985`) replaces `...: $(walk_why "$IMPORTED_MAIN_WHY")`. The old `*)` arm covered cycle and settings; floor now maps settings to cycle (`:1956`). Caller: `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$(floor_why "$FLOOR_WHY")"; return 0; fi` (`scripts/build-loop.sh:839`). Executed in E1: T10's expected sentences (built from INSTR, DOT, GATE and the rest), the case test (`C: the path could not be lower-cased`) and test 111 all pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1952-1990`, `scripts/build-loop.sh:836-849`, `test/scripts/build-loop-check.bats:463-480`, `$FC/bats.log`

---

## Claim 20: ANSWER_AWK's header comment: "Prints keep, drop, done, open, unrecognized, dup (...), "odd N WHY", "unbalanced N" or "quoted N" (...), or nothing when the file has no such entry. A trailing CR is dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:1991-1994`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the END block's output. Since a7a4f784, a single-entry result prints the entry's heading as a second line. The comment, unchanged by this branch, still lists only the one-word results. Does not establish any reader other than check_answer (grep finds no other user of ANSWER_AWK).
**Legibility-target:** for-author

`else if (count) { print (!answered ? "open" : done ? result : "unrecognized"); print head }` (`scripts/lib/dev-cycle-read.sh:2069`), where `head = substr($0, 5)` is captured for the first matching heading (`:2040`). check_answer depends on that second line: `hit="${r%%$'\n'*}"; head="${r#*$'\n'}"` (`:2105`). The comment at `:1991-1994` describes the output as one of the listed words "or nothing". It should add: "...and, after keep, drop, done, open or unrecognized, a second line holding the entry's heading after `### `". Executed in P2: the CRLF entry Q-001 yields heading `Q-001 · merge-x-abc`, carried through to ANSWER_HEADING.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1991-1994`, `scripts/lib/dev-cycle-read.sh:2040`, `scripts/lib/dev-cycle-read.sh:2064-2070`, `scripts/lib/dev-cycle-read.sh:2105`, `$FC/p2-heading.out`

---

## Claim 21: ANSWER_AWK prints the heading as a second line only in the single-entry case, and dev-cycle.sh --check-answer output is unchanged (brief item 4)

**Location:** `scripts/lib/dev-cycle-read.sh:2069`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the END chain (odd, unbalanced, quoted and dup print first and alone; `count` reaches the heading branch only when count is 1) and a side-by-side --check-answer run of main's scripts against the branch's on keep (CRLF), open, unrecognized, drop, dup and missing entries. Does not establish identical output for archive-file and both-files cases beyond the dev-cycle.bats suites (tests 195-199 and 225-228 pass).
**Legibility-target:** for-author

`else if (count > 1) print "dup"` precedes `else if (count) { print (...); print head }` (`scripts/lib/dev-cycle-read.sh:2068-2069`). Executed in P1: both copies print the same six lines (`keep Q-001`, `open Q-002`, `unrecognized Q-003`, `drop Q-004`, `skip Q-005: more than one entry with this heading in docs/working/questions.md`, `skip Q-009: no such entry ...`), each exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2064-2070`, `scripts/dev-cycle.sh:209`, `$FC/p1-check-answer.out`, `$FC/bats.log`

---

## Claim 22: check_answer: "With an answer line it sets ANSWER_HEADING to the entry's heading after "### " ("Q-NNN · SLUG", CR dropped), else empties it; a caller that reads it (build-loop.sh --approved) calls check_answer in its own shell, its output to a file."

**Location:** `scripts/lib/dev-cycle-read.sh:2076-2079`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "answer line" read as check_answer's non-skip output (keep, drop, done, open, unrecognized). An open entry with no `Q-NNN:` line in its body still sets the heading. Also covers CR stripping, emptying on every skip (ANSWER_HEADING is cleared on entry), and the one caller. Does not hold for a reading of "answer line" as the entry's own `Q-NNN:` body line.
**Legibility-target:** for-author

`ANSWER_HEADING=""` on entry (`scripts/lib/dev-cycle-read.sh:2084`). `if [[ -n "$hit" ]]; then ANSWER_HEADING="$head"; echo "$hit $a"` (`:2107`). Every line has its CR stripped before the heading test: `{ sub(/\r$/, "") }` (`:2037`). Executed in P2 (`cat -A`): `keep Q-001 | [Q-001 M-BM-7 merge-x-abc]$` (from a CRLF entry, no `^M`), `open Q-002 | [Q-002 · b]`, `skip Q-005 ... | []`, and `after skip: []` after presetting `stale`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2037`, `scripts/lib/dev-cycle-read.sh:2071-2109`, `scripts/build-loop.sh:1083`, `$FC/p2-heading.out`

---

## Claim 23: check_fix's walk text: "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out${TRUTH_WHERE:+: $TRUTH_WHERE}; file it instead" no longer duplicates the reader-settings sentence (rows 630, 634)

**Location:** `scripts/dev-cycle.sh:186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader-settings case: the output is byte-identical to the removed branch, because walk_why's readers arm produces the same sentence. Also covers the empty-TRUTH_WHERE case (tree-walk failures other than readers), which still prints the bare sentence. Does not establish an unchanged message when import_readers fails with IMPORT_READER_WHY empty (unreadable worktree registry, bad CLAUDE_CONFIG_DIR, import_home failure). There the skip now appends "the worktree registry could not be read, or a reader root, home or CLAUDE_CONFIG_DIR is not a usable absolute path", where the old code printed nothing more. That is an added clause, fail-closed, untested, and no claim says otherwise.
**Legibility-target:** for-author

Old: `"...ruled out: the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY; file it instead"` (diff line 239). New: `...ruled out${TRUTH_WHERE:+: $TRUTH_WHERE}; file it instead` (`scripts/dev-cycle.sh:186`), with TRUTH_WHERE from `walk_why readers` → `"the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY"` (`scripts/lib/dev-cycle-read.sh:821`). Executed in E1: dev-cycle.bats test 237 asserts `W='the instruction-file import walk failed, so an import of it cannot be ruled out: the reader settings of docs/dev-cycle.md cannot be used: '` for a malformed line and for no main by name (`test/scripts/dev-cycle.bats:1417-1423`). Test 1057's prefix check also passes.

**Evidence:** `scripts/dev-cycle.sh:176-189`, `scripts/lib/dev-cycle-read.sh:816-834`, `scripts/lib/dev-cycle-read.sh:1898`, `test/scripts/dev-cycle.bats:1417-1423`, `$FC/bats.log`

---

## Claim 24: rv's comment: "rv [FILE]: review policy, brief x (no Policy: line, so review) and feat/x with one commit (that also adds FILE, when given), then Q-001 answered [1] as merge-2026-10-01-x-SHA12 (S); T the tip, TR the merged tree."

**Location:** `test/scripts/build-loop-merge.bats:184-186`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rv and the fixtures it calls (settings, brief, work, commit_all, approve). Does not affect any assertion: the tests read only T, S and TR.
**Legibility-target:** for-author

`work feat/x` makes the branch's one commit (`git checkout -q "$1" && echo "$1" > "work-${1//\//-}.txt" && commit_all "work on $1"`, `test/lib/build-loop-fixtures.bash:60`). With FILE given, rv then adds a second commit: `git checkout -q feat/x && mkdir -p "$(dirname "$1")" && echo g > "$1" && commit_all gate` (`test/scripts/build-loop-merge.bats:189`). So feat/x has two commits when FILE is given, and FILE is not in the first. Precise version: "feat/x with one commit (and a second adding FILE, when given)".

**Evidence:** `test/scripts/build-loop-merge.bats:184-192`, `test/lib/build-loop-fixtures.bash:29`, `test/lib/build-loop-fixtures.bash:58-61`

---

## Claim 25: commit 18f32952: "Red until the --approved code lands."

**Location:** `18f32952` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five --approved tests at 18f32952's tree: all fail. Does not establish the failure cause for each (usage errors and missing refusals both count as red).
**Legibility-target:** for-author

Executed in P4: `1..5`, then `not ok 1` through `not ok 5`, exit 1. The same tests pass at HEAD (E1 tests 8-12).

**Evidence:** `$FC/p4-red-at-18f.out`, `$FC/bats.log`

---

## Claim 26: commit a7a4f784: the --approved paragraph; "Lib: check_answer sets ANSWER_HEAD (the entry's heading); floor sets a word in FLOOR_WHY and floor_why words it (row 472); truthwalk sets TRUTH_WHERE for both walks' failures, so check_fix no longer repeats the reader-settings sentence (rows 630, 634)."; Notes: exact-slug match, --approved refused with --check

**Location:** `a7a4f784` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each sentence against a7a4f784's tree and HEAD. ANSWER_HEAD is the name at a7a4f784 (`git show a7a4f784:scripts/lib/dev-cycle-read.sh` line 2068: `ANSWER_HEAD=""`). e25a6e89 renamed it to ANSWER_HEADING. Does not hold for "TRUTH_WHERE for both walks' failures": the tree walk sets it only for a readers failure.
**Legibility-target:** for-author

The tree arm sets TRUTH_WHERE only when IMPORTED_WHY is non-empty: `tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE=...` (`scripts/lib/dev-cycle-read.sh:1898`), and IMPORTED_WHY is only ever readers (claim 13). Precise version: "for the main walk's failures and the tree walk's readers failure". This matches rubric C5 (fact-check i1 claim 23, to be corrected in the merge message). The rest checks out. The --approved paragraph matches claims 2-3. Floor words: claim 17. "--approved is refused with --check": `[[ "$MODE" == merge ]] || usage "--approved goes with --merge"` (`scripts/build-loop.sh:321`), E1 test 12. Exact slug: claim 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1894-1904`, `scripts/lib/dev-cycle-read.sh:1637`, `scripts/build-loop.sh:320-323`, `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a3.md:37`

---

## Claim 27: commit e25a6e89: "GATE_CODE gains ^skills/dev-cycle/ (plan D4, F52), so a change to the skill that carries the D6 snippet needs a merge-gate- slug under --approved; the floor refuses it under self-merge too (stricter than plan D5 item 3, which lists the scripts alone)"; A1, A2/A3, C2; "Tests: option 2/3/unread, a skills/dev-cycle/ gate path, the questions archive N-denied under --approved"; "9 override-log rows (8 declined findings, 1 pre-existing flake)"

**Location:** `e25a6e89` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the GATE_CODE change, the floor's refusal of skills/dev-cycle/ paths, the three test additions, the A2/A3/C2 changes and the override-row count (9 rows added). Does not hold for "the skill that carries the D6 snippet" in the present tense, the same imprecision as claim 16.
**Legibility-target:** for-author

The GATE_CODE line at HEAD is in claim 16. The test diff of e25a6e89 adds the option 2, option 3 and `merge` (not read) refusals, `skills/dev-cycle/references/x.md` in test 11's loop, and `docs/working/questions-archive.md` denied as a cycle file under --approved (quoted from `git show e25a6e89 -- test/scripts/build-loop-merge.bats`). `git show e25a6e89 -- docs/reviews/override-log.md | grep -c '^+| 2026'` gives 9. The skill's SKILL.md holds no snippet yet (claim 16). Executed in E1: tests 9-11 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925`, `test/scripts/build-loop-merge.bats:207-254`, `docs/reviews/override-log.md`, `skills/dev-cycle/SKILL.md`, `$FC/bats.log`

---

## Claim 28: commit 01a2935f: GATE_CODE's comment gives both reasons and says the floor is stricter than D5 for the skill; "T10 refuses skills/dev-cycle/ paths (any case) and passes skills/dev-cycle-x/"; the header says --expect still binds the tip under --approved, points the gate list at GATE_CODE, and puts the prefix sentence after the landing rule; "T35 adds a mismatched --expect under --approved"; "2 override rows"

**Location:** `01a2935f` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change against 01a2935f's diff and HEAD, and the override-row count (2 rows). Does not re-verify the substance of the two override rows (deferred findings, settled per the brief).
**Legibility-target:** for-author

T10 is `@test "floor: instruction and prompt files, dotfiles, gate code, imports, cycle files, records and other briefs' files refuse; the rest pass (T10, U2a4)"` (`test/scripts/build-loop-check.bats:1287`). It adds `skills/dev-cycle/references/x.md "$GATE" Skills/Dev-Cycle/x.sh "$GATE"` and `skills/dev-cycle-x/a.md` to the pass list (`:1304`, `:1312`). Header: "(under --approved, without the S rules or the checkout refusal; --expect still binds the tip)" (`scripts/build-loop.sh:215-216`), "(the lib's GATE_CODE: ...)" (`:232`), and "The heading pins only TIP's prefix" placed after "then the message reads ..." (`:234-237`). T35: `mrg "$B" --expect "$M" --approved Q-001` (`test/scripts/build-loop-merge.bats:236`). The override-log diff of 01a2935f adds 2 rows (`grep -c '^+| 2026'`). Executed in E1: T10 and tests 8-12 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1918-1924`, `scripts/build-loop.sh:213-240`, `test/scripts/build-loop-check.bats:1287-1313`, `test/scripts/build-loop-merge.bats:235-237`, `docs/reviews/override-log.md`, `$FC/bats.log`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 20** (`scripts/lib/dev-cycle-read.sh:1991-1994`): ANSWER_AWK's comment still lists only the one-word results. Since this branch, keep/drop/done/open/unrecognized are followed by a second line holding the entry's heading, which check_answer splits off. Add that line to the comment.

### Mostly Accurate
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:35-38`): "its output to a file under set -e". The one caller runs approval as `elif ... && ! approval`, where errexit is suspended (P3). This is harmless, since nothing in check_answer exits and a failed write refuses. Drop "under set -e" or say it does not matter here.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:1920-1921`): "skills/dev-cycle/ because it carries the D6 snippet". The repo's SKILL.md has no snippet yet (plan D6; U4 adds it). Say "will carry" or "carries, per plan D6".
- **Claim 24** (`test/scripts/build-loop-merge.bats:184`): rv's "feat/x with one commit (that also adds FILE, when given)". FILE is added in a second commit.
- **Claim 26** (`a7a4f784`): "TRUTH_WHERE for both walks' failures". The tree walk sets it only for a readers failure (already rubric C5; fix it in the merge message). ANSWER_HEAD was later renamed ANSWER_HEADING.
- **Claim 27** (`e25a6e89`): "the skill that carries the D6 snippet", the same tense issue as claim 16 (fix it in the merge message).

### Unverifiable
None.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to the output path below in the code-fact-check skill's format, with `Commit: 01a2935f` at the top."

This report is saved at `/workspace/.claude/wt-build-loop-u3a3/docs/reviews/code-fact-check-report-u3a3-final-r1.md`, starts with `Commit: 01a2935f`, and follows the skill's header, per-claim and summary format, with a Legibility-target on every claim. No finding is behavioral: the code does what its comments say on every path checked. The one Stale and five Mostly accurate verdicts are wording in comments, a test comment and commit bodies. None of them blocks the merge. Of the six, the claim 20 comment and the merge-message corrections for claims 26-27 are the ones worth a line before landing. Nothing was committed. Probes stayed under `$FC`.
