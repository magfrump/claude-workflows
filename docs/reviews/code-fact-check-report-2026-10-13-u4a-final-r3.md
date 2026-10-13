Commit: c4e36d1d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4a (claude-workflows, branch feat/build-loop-u4a)
**Scope:** `git diff main...HEAD` (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-orchestrator.bats, docs/working/plan-build-loop-handoff.md U4a notes) and the commit messages 722c2e10, 70d24331, 4e14d1cc, 4df6ec58. Final confirming pass, replicate r3.
**Checked:** 2026-10-13
**Total claims checked:** 31
**Summary:** 27 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no claim here matches a logged pattern. The one measured figure ("about 15" tests, Claim 4) is the closest to the "measured value from an artifact set" class; see that claim.

Execution provenance (all runs under `/tmp/u4a-fcf-r3-*` temp dirs, git 2.39.5; each probe script starts `set -eu`, makes its own temp dir with mktemp, checks that `pwd` is under it before `git init`, and runs every script call under `timeout`):
- E1: `LC_ALL=C TMPDIR=/tmp/u4a-fcf-r3-bats-rxef timeout 600 bats -f "land-cycle|refuses the gate's code" test/scripts/build-loop-orchestrator.bats`, cwd the worktree, exit 0, 2026-10-13T20:58:30Z, output `/tmp/u4a-fcf-r3-bats-rxef/out.txt` (3 of 3 ok).
- E2: `bash scratchpad/r3/p1.sh <worktree>/scripts/build-loop.sh` (land by CAS and by FF with six marker hooks planted; reflog; `git merge` message bytes), exit 0, 2026-10-13T20:59:16Z, output `/tmp/claude-1000/-workspace/8681a912-a74a-4649-a416-551a1bfd4a4f/scratchpad/r3/p1.out`.
- E3: `bash scratchpad/r3/p2.sh ...` (usage, caller-env check, truth classes in the merge, a new brief with Asked:), exit 0, 2026-10-13T20:59:42Z, output `.../scratchpad/r3/p2.out`.
- E4: `bash scratchpad/r3/p3.sh ...` (Asked: item forms, the same ID twice, "its merge copy", Asked: with no questions change in land mode), exit 0, 2026-10-13T20:59:56Z, output `.../scratchpad/r3/p3.out`.
- E5: `bash scratchpad/r3/p4.sh ...` (--main-log over chore merges whose record is cycle-2026-10-12-x.md and cycle-2026-10-12.md), exit 0, 2026-10-13T21:00:17Z, output `.../scratchpad/r3/p4.out`.

---

## Claim 1: "U4a adds rules every path meets: no gate code, no truthrule file but the cycle's own, and a brief's Asked: line only extended by entries the change files."

**Location:** `docs/working/plan-build-loop-handoff.md:209`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named rules in `cycle_rules` as `--cycle-diff` runs them. It does not establish the i2 refinements the bullet leaves unnamed (exact items, one brief per ID, two paths with one name, case-spelled cycle files). Those are Claims 7-8b.

`cycle_rules` runs the checks in this order: `if [[ "$lp" =~ $GATE_CODE ]]; then echo "refuse $p: the gate's own code; ..."` (`scripts/build-loop.sh:1915`), then `if truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]` (`:1916`), and finally the Asked: append loop (`:1960-1978`). E1 test 1 passed. E3 shows the merge refusing `.github/x.md`, `docs/constraints.md`, `docs/decisions/x.md` and `docs/human-author/x.md`, while `docs/thoughts/t.md`, `docs/foo.md` and `README.md` are not refused.

**Evidence:** `scripts/build-loop.sh:1907-1979`, E1, E3
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "`--land-cycle --main SHA [--answered Q-…]` (U4a; gated) → `landed B HEAD TREE NEW`, or `refuse HEAD: why` / `refuse PATH: why` (exit 2): lands the orchestrator's committed `chore/dev-cycle-DATE[-HHMM]` HEAD from SHA, main's commit `--cycle-diff` checked, judging merge-tree's merge against main by `--cycle-diff`'s rules and requiring a cycle record holding `Branch: B`; commit-tree with `Merge branch 'B'`, then `--merge`'s move"

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output forms, the preconditions, judging the merge, the record requirement, the commit message and the move. It does not establish "It replaces pr-prep's hand merge", which is U4b's skill text and not yet wired.

`land_cycle` (`scripts/build-loop.sh:2025-2058`) ends with `echo "landed $b $h $r $NEW"`. It calls `cycle_rules "$MAIN_SHA" merge || return 1` and then `chore_record "$b" || { echo "refuse HEAD: the merge adds or changes no cycle record ...`. `land` writes the commit with `chore_msg "${VERDICT[branch]}"` and `commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}"` (`:1548-1549`). In E2 the merge's parents are main and HEAD, and the message is `Merge branch 'chore/dev-cycle-2026-10-12'`. E1 test 2 asserts `main^1 main^2 main^{tree}` = N2, H, T.

**Evidence:** `scripts/build-loop.sh:1548-1549`, `scripts/build-loop.sh:2025-2058`, E1, E2
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "As built (2026-10-13): `--land-cycle` takes `--main SHA` (not `--expect` ...); `cycle_rules BASE SIDE` also refuses truthrule's files but the cycle's own ..., every Asked: item added must name an entry the questions files gain, and a brief deleted or renamed with an Asked: line refuses ...; the questions guard stays `--cycle-diff`'s."

**Location:** `docs/working/plan-build-loop-handoff.md:339`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four as-built statements. It does not establish that the note lists every i2 change; it predates them and makes no claim to completeness.

The argument parser accepts only `--main` for this mode: `if [[ "$1" == --main && "$MODE" == land-cycle ...` (`scripts/build-loop.sh:540`). E3 shows `--land-cycle` without `--main` exiting 1 with "needs --main SHA". The questions guard sits only in `cycle_diff` (`:1888-1895`) and comes before `cycle_rules "$base" index`; `land_cycle` calls `cycle_rules` directly. For the deletion/rename rule, `[[ -z "${ao[$f]}" || -n "${an[$f]+set}" ]] || { echo "refuse ${aop[$f]}: deleted or renamed with its Asked: line; ...` is at `:1960-1962`. E1 test 1 runs `git rm` of the brief and gets this refusal.

**Evidence:** `scripts/build-loop.sh:536-547`, `scripts/build-loop.sh:1873-1896`, `scripts/build-loop.sh:1960-1962`, E1, E3
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "an `entry` line would change every `--check` line-count test (about 15)"

**Location:** `docs/working/plan-build-loop-handoff.md:339`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers the count of explicit `${#lines[@]}` assertions in the `--check` and `--merge` suites. It does not establish how many whole-output equality assertions a new line would also break, which a reader would need to make "about 15" exact.

`rg -c '#lines\[@\]\}" -eq'` finds 10 explicit line-count assertions in `test/scripts/build-loop-check.bats` (for example `:1780 [ "${#lines[@]}" -eq 17 ]` and `:2109 ... -eq 13`) and none in `build-loop-merge.bats`. Exact multi-line `"$output" = ...` comparisons would add to that number. Counting them needs per-case judgement (paraphrased: no quote available because the remaining count depends on which multi-line equality assertions an ok verdict with path lines reaches). The order of magnitude is right. The exact figure is an estimate.

**Evidence:** `test/scripts/build-loop-check.bats:1319`, `:1636`, `:1780`, `:1790`, `:1799`, `:1846`, `:2078`, `:2109`, `:2156`
**Legibility-target:** for-author

---

## Claim 5: "a cycle record the merge adds or changes (docs/working/cycles/cycle-YYYY-MM-DD.md, mode 100644) holding the line "Branch: B""

**Location:** `scripts/build-loop.sh:163-165`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the narrowing of --main-log's chore class to `isrecord` names. It does not establish anything about records that main already holds before SINCE.

`chore_record` filters with `isrecord "${RAW_P[i]}" && [[ "${RAW_NM[i]}" == 100644 && "${RAW_S[i]}" =~ ^[AM]$ ]]` (`:1739`), and `isrecord` is `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` (`scripts/lib/dev-cycle-read.sh:246`). In E5, a merge whose record is `cycle-2026-10-12-x.md` reads `other` and one whose record is `cycle-2026-10-12.md` reads `chore`.

**Evidence:** `scripts/build-loop.sh:1736-1744`, `scripts/lib/dev-cycle-read.sh:246`, E5
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "A questions change while main has changed those files since BASE refuses ...: merge main into HEAD first. That refusal is printed alone."

**Location:** `scripts/build-loop.sh:202-205`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--cycle-diff`'s guard and that its output is a single line. It does not establish anything for `--land-cycle`, which never runs the guard (by design, Claim 3).

The guard's refusal path is `cmp -s "$t.lb" "$t.lm" || { echo "refuse docs/working/questions.md: the default branch changed ...; return 1; }` (`:1894`). It runs before `cycle_rules` (`:1897`), and every earlier echo in `cycle_diff` is also followed by `return 1`. In E3 (the "6-hex sha" step, after an earlier land moved main) three runs each printed only that one refusal, even though the brief's Asked: line was also bad.

**Evidence:** `scripts/build-loop.sh:1873-1897`, E3
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "A path of the gate's own code (GATE_CODE) refuses, and so does one the lib's truthrule reads as truth (an instruction or prompt file, a dot path, docs/dev-cycle.md, docs/constraints.md, docs/decisions/, docs/human-author/; --check-fix refuses them too), both compared lower-cased, and a cycle file spelled in another case."

**Location:** `scripts/build-loop.sh:216-222`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed class, case folding, and the case-spelled cycle refusal, in both modes. It does not establish truthwalk's @-import class, which cycle_rules does not run (70d24331's Notes say so; Claim 28).

The code is `lp="$(lower "$p")"`, then `[[ "$lp" =~ $GATE_CODE ]]`, then `truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]`, then `[[ "$TRUTH_WHY" == cycle && "$p" != "$lp" ]]` (`:1908-1920`). `check_fix` refuses the same classes: `elif [[ -n "$TRUTH_WHY" || ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ ...` (`scripts/dev-cycle.sh:191`). E1 test 1 covers AGENTS.md, SKILLS/dev-cycle/x.md, docs/dev-cycle.md, docs/working/Questions.md and scripts/lib/a.sh. E3 covers the rest in merge mode: dot, constraints, decisions, human-author, `Docs/Roadmap.md`, and `DOCS/working/cycles/cycle-2026-10-12.md`.

**Evidence:** `scripts/build-loop.sh:1907-1920`, `scripts/lib/dev-cycle-read.sh:1914-1924`, `scripts/dev-cycle.sh:184-197`, E1, E3
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8a: "A brief's first unfenced "Asked:" line, matched by file name (a move to closed/ under its name too; two changed paths with one name on a side refuse), must be as on BASE, or BASE's line followed by ", " and more (no line on BASE: every item is added). Each item added ... must be exactly Q-NNN or Q-NNN@SHA (7-64 hex), name an entry the questions files gain (a "### Q-NNN" heading BASE lacks) ... A brief with an Asked: line deleted, or renamed to another file name, refuses."

**Location:** `scripts/build-loop.sh:222-231`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers name matching, the extension rule, exact item form, new-entry naming (both files, both sides, ID-keyed so an archive move is not new), and deletion/rename. It does not establish the "no other brief" clause, which is Claim 8b.

`asked` skips fenced lines (`fence($0) { next } /^Asked:/ { print; exit }`, `:1901`). The extension test is `elif [[ "$n" == "$o, "* ]]; then a="${n#"$o, "}"` (`:1967`), and an item must match `^(Q-[0123456789]+)(@[0123456789abcdef]{7,64})?$` (`:1972`). New entries come from `awk -F '\t' 'FILENAME == ARGV[1] { if ($3 == "h") o[$1]; next } $3 == "h" && !($1 in o) { print $1 }' "$t.qo" "$t.qn"` (`:2018`), and `t.qo`/`t.qn` gather both questions files (`:1993-2010`). E4 refuses `Q-002@abcdef` (6 hex) and `Q-002@ABCDEF1`, and accepts `Q-002@abcdef1`. E3 accepts a new brief whose `Asked: Q-002@abcdef1` names an entry the change files, in both `--cycle-diff` and `--land-cycle`. E3 also passes a fenced `Asked: Q-777`. E4 refuses an Asked: line whose entry was not filed in this change ("names no question entry this change files").

**Evidence:** `scripts/build-loop.sh:1901`, `scripts/build-loop.sh:1924-1935`, `scripts/build-loop.sh:1960-1978`, `scripts/build-loop.sh:1986-2021`, E1, E3, E4
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8b: "[Each item added ...] and be added by no other brief."

**Location:** `scripts/build-loop.sh:229-230` (also the refusal text at `:1975`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-add-per-ID check across briefs and within one brief. It does not establish anything about IDs on lines that did not change.

The check is `elif [[ -n "${used[$id]-}" ]]; then echo "refuse ${ap[$f]}: its first Asked: line adds $x, which another brief's Asked: line adds too"` (`:1975`). `used` is shared across all briefs and all items, so an ID can be added only once in the whole change, including twice by the same brief. In E4, `Asked: Q-001, Q-002, Q-002` on one brief refuses with "which another brief's Asked: line adds too", although no other brief adds it. The rule is stricter than the header says, and in that case the refusal names the wrong cause. A more precise header line would be "added once in the change (by one brief, once)".

**Evidence:** `scripts/build-loop.sh:1970-1978`, E4
**Legibility-target:** for-author

---

## Claim 9: "--land-cycle lands the orchestrator's chore branch ...: HEAD must be on chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM, the index as its commit, and --main the default branch's commit ... The merge of HEAD into main, as --check's (merge-tree, no repo config), is judged against main by --cycle-diff's rules with these --answered IDs ... and must add or change a cycle record holding "Branch: B" ... Then it writes the merge with the message "Merge branch 'B'" and moves the default branch as --merge does (a compare-and-swap from that commit, or a fast-forward in the worktree that has it checked out ...)"

**Location:** `scripts/build-loop.sh:234-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each precondition, the judged object being the written tree, and both move paths. It does not establish behavior under a concurrent writer between the check and the move (Q-103's residual class).

The branch check is the regex `^refs/heads/(chore/dev-cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}(-$DIGIT{4})?)$` (`:2027`); the main check is `[[ "$LAND_MAIN" == "$MAIN_SHA" ]]` (`:2029`); the index check is `git diff-index --cached --quiet ... "$h"` (`:2033`). Next comes `r="$(merge_result "$h")"`, which runs `gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1"` (`:1101-1112`). Then come `diff-tree ... "$MAIN_SHA" "$r"` and `cycle_rules "$MAIN_SHA" merge`, and the same `r` is passed as `VERDICT[tree]` to `land` (`:2054`). For the move, `land` runs `git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` or `merge --ff-only -q "$NEW"` in W (`:1553-1563`). E1 test 2 pins the not-a-chore-branch, moved main, staged-change, no-record and answered-without---answered refusals, and both moves. E1 test 3 pins rename pairing.

**Evidence:** `scripts/build-loop.sh:1101-1112`, `scripts/build-loop.sh:1479-1565`, `scripts/build-loop.sh:2025-2058`, E1, E2
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "after --state's gate but its caller check"

**Location:** `scripts/build-loop.sh:236`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `--land-cycle` runs `state_start` and does not read the caller's environment. It does not establish the contents of state_start beyond default_gate, gate_repo and store_check --main.

The mode's dispatch is `land-cycle) state_start; land_cycle || exit 2 ;;` (`:2078-2081`). In E3, `GIT_REPLACE_REF_BASE=refs/x/` was not refused; the run went on to the `--main` mismatch refusal. `--state` refuses that same variable (test at `test/scripts/build-loop-orchestrator.bats:42-46`).

**Evidence:** `scripts/build-loop.sh:1310-1316`, `scripts/build-loop.sh:2078-2081`, E3
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "no hooks run"

**Location:** `scripts/build-loop.sh:249-250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the land's own git commands (commit-tree in the gate repository, update-ref, and merge --ff-only in W) with standard hooks planted in the common hooks dir. It does not establish the orchestrator's earlier chore commit, which is U4b's (70d24331's correction).

E2 planted executable `post-merge`, `reference-transaction`, `pre-commit`, `commit-msg`, `post-commit` and `pre-merge-commit` hooks that touch marker files. Neither the CAS land nor the FF land created a marker ("no hooks ran (CAS)", "no hooks ran (FF)"). `HARDEN` holds `core.hooksPath=/dev/null` (`scripts/lib/dev-cycle-read.sh:352`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:352`, `scripts/build-loop.sh:1548-1563`, E2
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "NEW: the merge commit, now the default branch's (its reflog entry reads "build-loop: cycle land of B")."

**Location:** `scripts/build-loop.sh:252-254`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reflog text on both move paths. It does not establish the HEAD reflog in W beyond the one entry read.

`land` sets `msg="build-loop: $what of ${VERDICT[stem]}"` with `what="cycle land"` (`:1482-1483`). On the CAS path the reflog reads exactly `build-loop: cycle land of chore/dev-cycle-2026-10-12` (E2). On the fast-forward path it is `GIT_REFLOG_ACTION="$msg" git -C "$w" ... merge --ff-only` (`:1560`), and git appends a suffix: E2 shows `build-loop: cycle land of chore/dev-cycle-2026-10-13-0900: Fast-forward`. `--merge`'s header states this qualifier ("git adds ": Fast-forward" when W moves it", `:396-398`); `--land-cycle`'s omits it. The header should add the same parenthetical.

**Evidence:** `scripts/build-loop.sh:252-254`, `scripts/build-loop.sh:396-398`, `scripts/build-loop.sh:1482-1483`, `scripts/build-loop.sh:1553-1563`, E2
**Legibility-target:** for-author

---

## Claim 13: "or refuse lines and exit 2: --cycle-diff's rules' (PATH a file; a copy of the merge is "its merge copy"), or refuse HEAD: WHY — Not on such a branch; the default branch moved ...; staged changes; nothing the default branch lacks; a conflict; an object that does not hash or has two copies; no such record; --merge's own refusals of the move; or a read that fails (HEAD's commit, the merge, its paths)."

**Location:** `scripts/build-loop.sh:255-263`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every `refuse HEAD:` echo in `land_cycle` maps to a listed reason, and the "its merge copy" wording. It does not establish each of land's MERGE_WHY texts individually (those are --merge's, pre-existing).

Each `echo "refuse HEAD: ..."` in `land_cycle` (`:2027-2056`) matches one listed reason. The questions reader words its side as `k=base; [[ "$p" == o ]] || k="$side"` (`:2006`). E4 prints `refuse docs/working/questions.md: --check-answer refuses its merge copy whole (unbalanced 6)`. E1 test 3 pins the conflict refusal and test 2 pins the "nothing lacks" refusal.

**Evidence:** `scripts/build-loop.sh:2005-2008`, `scripts/build-loop.sh:2025-2058`, E1, E4
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "and --land-cycle's (AUTHORITY cycle, VERDICT and CHANGED set by land_cycle; the message git merge writes, "Merge branch 'B'", which --main-log reads as chore)"

**Location:** `scripts/build-loop.sh:1465-1466`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the authority branch inside `land` and that the written message reads as chore. It does not establish the parts of `land` that are unchanged from --merge.

`land` contains `[[ "$1" != cycle ]] || what="cycle land"` and `if [[ "$1" == cycle ]]; then chore_msg ...` (`:1482`, `:1548`). `land_cycle` sets `VERDICT=(...)` and `CHANGED` before `land cycle` (`:2054-2056`). E1 test 2 reads `chore $(git rev-parse main) Merge branch '$B'` from `--main-log`.

**Evidence:** `scripts/build-loop.sh:1479-1565`, `scripts/build-loop.sh:2054-2056`, E1
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "chore_msg B: the message of a chore merge, as git merge writes it and --land-cycle writes it (land); log_class reads it back by its subject regex."

**Location:** `scripts/build-loop.sh:1729-1731`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality with `git merge --no-ff --no-edit` of a chore branch into a branch named main, on git 2.39.5. It does not establish other git versions or a default branch whose name git does not suppress (that message gains " into X", which log_class also accepts).

The definition is `chore_msg() { printf "Merge branch '%s'\n" "$1"; }`. In E2, the message body of a `git merge --no-ff --no-edit chore/dev-cycle-2026-10-14` into main is `Merge branch 'chore/dev-cycle-2026-10-14'\n` (od dump), byte-identical in form to the land's own commit (`... '2026-10-13-0900'\n`). The read side is the regex at `:1772`, `^Merge\ branch\ \'(chore/dev-cycle-...)\'($|\ into\ |:)`.

**Evidence:** `scripts/build-loop.sh:1731`, `scripts/build-loop.sh:1771-1772`, E2
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "chore_record B: a cycle record among RAW_* (isrecord, added or changed, mode 100644) holds the line "Branch: B" (a trailing CR dropped) ... Returns 1 when none does or a read fails."

**Location:** `scripts/build-loop.sh:1732-1744`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the filter and the line match, and that a failed read counts as no record (under the script's `set -euo pipefail`, `:514`). It does not establish the narrower reading of "a read fails → 1": with two record paths, one unreadable and one matching, it returns 0.

The match is `gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0` (`:1741`), inside a loop that falls through to `return 1` (`:1743`). E1 test 2 refuses a record holding only another branch's line. E5 classes the narrowed name.

**Evidence:** `scripts/build-loop.sh:514`, `scripts/build-loop.sh:1736-1744`, E1, E5
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "# chore_msg's subject, or git merge's with " into X" or ": ..." after it." (and log_class's chore class through `! chore_record "$b" || CLASS=chore`)

**Location:** `scripts/build-loop.sh:1771-1776`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the refactor kept log_class's behavior apart from the isrecord narrowing. It does not establish clean_merge's own behavior, which this diff does not change.

The branch is `elif [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(...)\'($|\ into\ |:) ]]`. Its body runs clean_merge, then diff-tree from the first parent, `raw_records`, and `! chore_record "$b" || CLASS=chore`. The removed inline loop is the same body as chore_record except for the record-name regex. E5 shows both outcomes.

**Evidence:** `scripts/build-loop.sh:1771-1776`, E5
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "So a staged questions change needs the questions files as on main: merge the default branch into HEAD first. (--land-cycle judges the merge itself.)"

**Location:** `scripts/build-loop.sh:1883-1887`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the guard fires only when a questions path is in the index listing and both ls-tree listings are compared. It does not establish anything about the fence-capture hazard itself (U3c's).

The loop `for p in "${RAW_P[@]}"; do [[ "$p" == docs/working/questions.md || ... ]] || continue` lists both trees with `gate_git ls-tree -z "$base"` and `"$MAIN_SHA"`, compares them with `cmp -s`, and stops at `break` (`:1888-1895`). `land_cycle` never calls `cycle_diff`.

**Evidence:** `scripts/build-loop.sh:1888-1896`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "asked FILE: a brief's first "Asked:" line outside a fence, a trailing CR dropped, or nothing: brief_fields' reading, but for a brief FENCE_AWK refuses after that line, which brief_fields does not read at all."

**Location:** `scripts/build-loop.sh:1897-1901`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match with brief_fields' per-key first-unfenced-line rule. It does not establish behavior for a brief FENCE_AWK refuses before its Asked: line.

`asked` is `awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } /^Asked:/ { print; exit }'`, and brief_fields has `fence($0) { next } match($0, /^(Status|...|Asked|Dispatched):/) { ... if (!(k in got)) ...` with an END that prints nothing but `odd`/`unbalanced` when the whole file is refused (`scripts/lib/dev-cycle-read.sh:444-449`).

**Evidence:** `scripts/build-loop.sh:1901`, `scripts/lib/dev-cycle-read.sh:435-458`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "cycle_rules BASE SIDE: the cycle's rules over RAW_* ...: --cycle-diff's (BASE the merge base, SIDE "index") and --land-cycle's (BASE main's commit, SIDE "merge", the merge it writes), SIDE naming the listing's side in refusals. Prints "refuse PATH: WHY" per finding; returns 1 on any."

**Location:** `scripts/build-loop.sh:1902-1906`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both call sites and the SIDE wording. It does not establish that every refusal names a path; a few use "refuse index:", but those are in cycle_diff and not in cycle_rules.

The two calls are `cycle_rules "$base" index` (`:1897`) and `cycle_rules "$MAIN_SHA" merge` (`:2051`). SIDE is used only in `k="$side"` (`:2006`). E4 shows "its merge copy".

**Evidence:** `scripts/build-loop.sh:1897`, `scripts/build-loop.sh:2006`, `scripts/build-loop.sh:2051`, E4
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: inline comments in cycle_rules: "An in-cycle fix never edits the gate's code ..., nor a file sessions or later cycles read as truth, other than the cycle's own ... A cycle file spelled in another case is not one these rules read" and "Step 6 only appends IDs ... A brief deleted, or renamed to another file name, with an Asked: line refuses too."

**Location:** `scripts/build-loop.sh:1909-1914`, `scripts/build-loop.sh:1954-1959`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comments against the code they introduce. The "no other brief takes" clause carries Claim 8b's imprecision (the same brief twice also refuses).

The comments match the code verified in Claims 7 and 8a. The case rule is `[[ "$TRUTH_WHY" == cycle && "$p" != "$lp" ]]` (`:1920`). The questions file switch `docs/working/questions.md|docs/working/questions-archive.md) qi+=("$i")` (`:1937`) matches exact spellings only, which is why a case-spelled copy would otherwise go unread.

**Evidence:** `scripts/build-loop.sh:1907-1979`, E1, E3
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "questions_rules BASE SIDE I...: ... also writes $GATE_TMP/cy.new, the IDs of the entries the listing files (a "### Q-NNN" heading BASE lacks), one per line: empty when no questions file changed or a read failed. Prints refusals; returns 1 on any."

**Location:** `scripts/build-loop.sh:1981-1985`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the emptying at entry, the early return, every read-failure return, and the final write. It does not establish QKEYS_AWK's heading reader, which this diff does not change.

The function starts with `: > "$t.new"` and `[[ $# -gt 0 ]] || return 0` (`:1989-1990`). Every read-failure `return 1` comes before the final write, and the write's own failure branch is `|| { : > "$t.new"; echo ...; return 1; }` (`:2018-2019`). In E4, with no questions file changed, an appended `Q-001` refuses as "names no question entry this change files".

**Evidence:** `scripts/build-loop.sh:1986-2021`, E4
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: land_cycle comments: "The land takes HEAD's commit, never the index"; "store_check reads every blob of R, so a blob the store lacks refuses here"; "cycle_rules reads RAW_* and leaves it as raw_records filled it, for chore_record and CHANGED"; "Every key check_line sets, so land reads none unset"

**Location:** `scripts/build-loop.sh:2032`, `:2043-2044`, `:2050`, `:2053`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four comments. "every blob of R" excludes ids already in `$GATE_TMP/main`, which `state_start`'s `store_check --main` re-hashed; this does not establish re-hashing of main's ids a second time.

- store_check lists `git ls-tree -r -t --full-tree ... "$r"`, drops only `commit` entries and ids already in `$GATE_TMP/main`, and fails on `missing` (`:1066-1084`).
- No function reached from `cycle_rules` (asked, cyc_blob, truthrule, floor_why, questions_rules) calls `raw_records` (paraphrased: no quote available because the claim covers absence of code; `rg -n raw_records` hits only `cycle_diff`, `land_cycle`, `log_class` and its definition).
- check_line sets `VERDICT=([tip]=... [tree]=... [policy]=... [branch]=... [stem]=... [gate]=...)` (`:1396`), and land_cycle sets the same six keys (`:2054`).

**Evidence:** `scripts/build-loop.sh:1062-1095`, `scripts/build-loop.sh:1396`, `scripts/build-loop.sh:2025-2058`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: "A cycle record: one per day, updated in place by each iteration (dev-cycle.sh reads the window from these names; build-loop.sh's --main-log and --land-cycle read its Branch: lines)." and `writable` now `|| isrecord "$1"`

**Location:** `scripts/lib/dev-cycle-read.sh:243-248`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the named readers and the refactor of writable, which matches the same name set as before. "one per day, updated in place" is the plan's design and not code behavior.

dev-cycle.sh globs `docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:225`). The old writable alternative `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` is now isrecord's regex unchanged. `chore_record` (shared by log_class and land_cycle) calls isrecord.

**Evidence:** `scripts/lib/dev-cycle-read.sh:243-248`, `scripts/dev-cycle.sh:225`, `scripts/build-loop.sh:1739`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: "The read-as-truth rule --check-fix, floor and build-loop.sh's cycle_rules share (cycle_rules refuses every word but cycle, so a cycle file must never take an earlier word ..."

**Location:** `scripts/lib/dev-cycle-read.sh:1899-1901`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three callers and that no lower-cased writable path currently matches the case, instr or dot words tested before cycle. It does not establish that future INSTRUCTION_FILE edits keep this property (the comment is the guard).

The callers are `check_fix` (`scripts/dev-cycle.sh:190`), `floor` (`:2000`) and cycle_rules (`scripts/build-loop.sh:1916`). The writable names (`docs/roadmap.md`, `docs/working/{questions,questions-archive,idea-log}.md`, `cycle-DATE.md`, and briefs `DATE-slug.md`) cannot match `INSTRUCTION_FILE='^(claude|agents?|gemini)(\..+)?\.md$|^skill\.md$'` on their basename. They also have no dot component and no `.claude/` part.

**Evidence:** `scripts/lib/dev-cycle-read.sh:699`, `scripts/lib/dev-cycle-read.sh:712`, `scripts/lib/dev-cycle-read.sh:1914-1924`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: the three U4a test names: "--cycle-diff refuses the gate's code, truth files and a brief's Asked: line other than extended by entries the change files, matched by name across a move to closed/ ..."; "--land-cycle lands HEAD's chore branch as the merge --main-log reads as chore, by compare-and-swap or a fast-forward where main is checked out ..."; "--land-cycle judges the merge, not the index: a rename git pairs into a new questions file carries main's answer, and a conflict refuses ..."

**Location:** `test/scripts/build-loop-orchestrator.bats:466`, `:498`, `:522`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test passes and asserts the behavior its name gives. It does not establish full class coverage: test 1 covers only the instr and settings truth classes (E3 covers the rest), and test 2 pins the FF path by a clean status in R rather than by reading the reflog.

All three passed (E1).
- Test 1 asserts exact refusal text for an append naming no new entry, an inexact item, an empty item, a shared ID, a move to closed/ then an edit, two paths with one name, a deletion, and the gate, truth and case classes.
- Test 2 lands first with main not checked out (R is on the chore branch, so CAS) and asserts parents, tree, message and the `--main-log` chore line. It then lands with main checked out in R and asserts `HEAD^1` and a clean `git status`, which an update-ref under a checked-out branch would leave dirty.
- Test 3 asserts `--cycle-diff` ok while merge-tree's questions.md holds `Q-001: [1]`, then the land's refusal, then a conflict.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:466-531`, E1
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: commit 722c2e10: "--land-cycle --expect MAIN [--answered Q-NNN]... lands ...; then commit-tree with "Merge branch 'B'" and land's compare-and-swap or fast-forward (no hooks run: rows 719, 749, 752)."

**Location:** commit `722c2e10` message body
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against the code at 722c2e10. It does not establish later behavior; the flag name and the row 749 attribution were superseded by 70d24331, which says so.

At 722c2e10 the header reads `scripts/build-loop.sh --land-cycle --expect SHA [--answered Q-NNN]...` (`git show 722c2e10:scripts/build-loop.sh:12`), so the flag name was true then. "no hooks run" is true (Claim 11). Override-log row 749 is about the orchestrator's own chore commit's hooks ("commit with core.hooksPath=/dev/null ... and check the new commit's tree against the index", `docs/reviews/override-log.md:749`), not the land. 70d24331's body corrects this: "the land answers row 749 by judging HEAD's commit, not by running no hooks". The other claims match: "A deleted roadmap now reads "it is deleted"" is at `:1943`, and isrecord and chore_record are shared.

**Evidence:** `git show 722c2e10:scripts/build-loop.sh:12`, `docs/reviews/override-log.md:749`, `scripts/build-loop.sh:1943`
**Legibility-target:** for-author

---

## Claim 28: commit 70d24331: Asked: items name new entries (asked_rule); truth files refused; --main not --expect; guard moves into cycle_diff and SIDE added; chore_msg the one definition; every VERDICT key; correction of row 749; Notes: "truthrule does not cover files instruction files @-import ...; an in-cycle fix that edits one lands."

**Location:** commit `70d24331` message body
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the code at 70d24331 and at HEAD. It does not establish the release-gate claim in Notes ("left to U4b's text and the release gate"), which is future work.

At 70d24331, `asked_rule()` exists (`git show 70d24331:scripts/build-loop.sh:1980`) and is called at `:1939` and `:1970`. The rest matches HEAD (Claims 3, 7, 14, 15, 23). The Notes gap is real: cycle_rules calls `truthrule` but never `truthwalk`, and `check_fix` runs `truthwalk tree "$lp"` (`scripts/dev-cycle.sh:193`).

**Evidence:** `git show 70d24331:scripts/build-loop.sh:1939-1995`, `scripts/build-loop.sh:1916`, `scripts/dev-cycle.sh:193`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: commit 4e14d1cc: "U4a fix-drift: "other than a cycle file", not "but"" (wording only)

**Location:** commit `4e14d1cc`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the commit changes two comment or header lines only. It does not establish anything else.

`git show --stat 4e14d1cc` shows `scripts/build-loop.sh | 4 ++--`, and HEAD's text reads "other than the cycle's own" (`:1911`) and "other than a cycle file" in the header lineage.

**Evidence:** `git show --stat 4e14d1cc`, `scripts/build-loop.sh:1911`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: commit 4df6ec58: "the old check read only the item's start, so ", Q-002@Q-003" carried an old answered ID"; exact items; one brief per ID; two paths with one name refuse; case-spelled cycle files refuse; Asked: inline (no dynamic scope); questions_rules called once; floor_why prose; header updates

**Location:** commit `4df6ec58` message body
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet. "One brief per new ID" carries Claim 8b's nuance (an ID added twice by one brief also refuses).

At 70d24331 the item test was `[[ "$x" =~ ^(Q-[0123456789]+)(@|$) ]]` (`git show 70d24331:scripts/build-loop.sh:1995`), which matches only the start of the item. HEAD anchors the whole item (`:1972`), and E4 and E1 confirm it. `questions_rules` has one caller (`:1953`). The Asked: loop is inline in cycle_rules with `local -A ... used=()` (`:1908`). The refusal text uses `floor_why "$TRUTH_WHY"` (`:1917`).

**Evidence:** `git show 70d24331:scripts/build-loop.sh:1995`, `scripts/build-loop.sh:1907-1979`, E1, E4
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:339`): "about 15" `--check` line-count tests. There are 10 explicit `${#lines[@]}` assertions, plus whole-output equalities; it is an estimate.
- **Claim 8b** (`scripts/build-loop.sh:229-230`, `:1975`): "added by no other brief". The code refuses any second add of an ID, including by the same brief, and then says "another brief's Asked: line adds too". This affects comment and message text only.
- **Claim 12** (`scripts/build-loop.sh:252-254`): the reflog text omits that git appends ": Fast-forward" on the W path. `--merge`'s header states that qualifier.
- **Claim 27** (commit 722c2e10): its row 749 attribution for "no hooks run" was wrong. 70d24331 already corrects it.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): Success criterion: a markdown report saved at the exact path your own prompt names, structured per your skill.
- Answered: yes. All seven brief items were checked; 30 of 31 verdicts were executed or read in full; there were no Incorrect verdicts.
- Out of scope: the docs/reviews files in the diff (review records, not claims about code); commits c0cafb66 and c4e36d1d (review-record commits outside the brief's list); the hallucination log was not updated (the brief allows writing only this file, and there was no fabrication).
- Escalate: nothing. The four Mostly-accurate items are wording only.
- Decisions I made: I read override-log "row N" as the file line number (it matches each cited topic: 719, 725, 745, 749, 752, 753), not a table row index.
