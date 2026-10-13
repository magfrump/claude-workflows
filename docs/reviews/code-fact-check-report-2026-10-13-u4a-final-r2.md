Commit: c4e36d1d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4a (claude-workflows), branch `feat/build-loop-u4a`
**Scope:** whole diff `main...HEAD` (HEAD c4e36d1d): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`, the plan's script-interface bullets and U4a as-built note (`docs/working/plan-build-loop-handoff.md`), and the commit messages on main..HEAD. Final confirming pass, replicate r2 of k=3.
**Checked:** 2026-10-13
**Total claims checked:** 35
**Summary:** 28 verified, 4 mostly accurate, 2 stale, 1 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read first. None of its five patterns (measured values quoted from artifact sets, file-to-symbol associations) matches a claim here. No claim cites a test count or a measured statistic.

**Execution provenance (shared by every `executed` claim).** The brief allows writing only this report, so captured output lives outside the repo, under `/tmp/u4a-fcf-r2-logs/`. Probe scripts are under `/tmp/u4a-fcf-r2-scripts/`. Each probe runs `set -eu`, creates its own `mktemp -d /tmp/u4a-fcf-r2-p-XXXX` dir in the same script, and refuses to run unless `pwd` is under that dir. It uses the fixtures' hermetic env (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, fixed identity, `HOME` in the temp dir), and every script call runs under `timeout 120`. git 2.39.5.
- E0: `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u4a-fcf-r2-bats-XXXX) timeout 900 bats test/scripts/build-loop-orchestrator.bats`. cwd: the worktree. Run 2026-10-13T20:57:11Z, exit 0, 27/27 ok. Output: `/tmp/u4a-fcf-r2-logs/bats.txt`
- E1: `bash /tmp/u4a-fcf-r2-scripts/p1.sh`, which lands by CAS and by FF with hooks planted, then checks reflog, message bytes, argument parsing and --main-log. cwd: its temp repo. Run 2026-10-13T20:59:11Z, exit 0. Output: `/tmp/u4a-fcf-r2-logs/p1.txt`
- E2: `bash /tmp/u4a-fcf-r2-scripts/p2.sh`, covering the edges of the Asked: rule and the questions guard printed alone. Run 2026-10-13T20:59:42Z, exit 0. Output: `/tmp/u4a-fcf-r2-logs/p2.txt`
- E3: `bash /tmp/u4a-fcf-r2-scripts/p3.sh`, the truth rule over 28 single-path changes. Run 2026-10-13T20:59:43Z, exit 0. Output: `/tmp/u4a-fcf-r2-logs/p3.txt`
- E4: `bash /tmp/u4a-fcf-r2-scripts/p4.sh`, which tests whether log_class's chore class covers record names and git merge's subject forms. Run 2026-10-13T20:59:46Z, exit 0. Output: `/tmp/u4a-fcf-r2-logs/p4.txt`

---

## Claim 1: "U4a adds rules every path meets: no gate code, no truthrule file but the cycle's own, and a brief's Asked: line only extended by entries the change files."

**Location:** `docs/working/plan-build-loop-handoff.md:209`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4b author writing the skill text against the plan's script interface
**Scope:** Covers the three rule classes the bullet names. It does not establish completeness: the bullet leaves out four rules the code enforces.

All three named rules hold (E3: `scripts/build-loop.sh` refuses as "the gate's own code"; `AGENTS.md`, dot paths, `docs/dev-cycle.md`, `docs/constraints.md`, `docs/decisions/` and `docs/human-author/` are refused; cycle files pass). The bullet omits four refusals, all added in iteration 2:
- an added item that is not exactly `Q-NNN` or `Q-NNN@SHA`
- an ID added by more than one brief
- two brief paths with one file name on a side
- a cycle file spelled in another case (`scripts/build-loop.sh:1918-1920`, `:1972-1976`)

It also omits the refusal of a brief deleted or renamed with its Asked: line. A precise bullet would add "exact Q-NNN[@SHA] items, one brief per new ID, no brief deleted or renamed with an Asked: line, no case-spelled cycle file".

**Evidence:** `docs/working/plan-build-loop-handoff.md:209`, `scripts/build-loop.sh:1918-1920`, `scripts/build-loop.sh:1966-1979`, `/tmp/u4a-fcf-r2-logs/p3.txt`, `/tmp/u4a-fcf-r2-logs/p2.txt`

---

## Claim 2: "`--land-cycle --main SHA [--answered Q-…]` (U4a; gated) → `landed B HEAD TREE NEW`, or `refuse HEAD: why` / `refuse PATH: why` (exit 2): lands … from SHA, main's commit `--cycle-diff` checked, judging merge-tree's merge against main by `--cycle-diff`'s rules and requiring a cycle record holding `Branch: B`; commit-tree with `Merge branch 'B'`, then `--merge`'s move"

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4b author; the orchestrator skill's step 9
**Scope:** Covers the argument form, the output line, exit 2 on refusal, merge-tree, cycle_rules, chore_record, the message and land()'s move. It does not establish the "replaces pr-prep's hand merge" sentence, which is skill text for U4b (override row, i1 architecture 7).

`land_cycle` calls `merge_result "$h"` (merge-tree), then `cycle_rules "$MAIN_SHA" merge`, `chore_record "$b"` and `land cycle` (`scripts/build-loop.sh:2036-2058`). The mode's dispatch is `land_cycle || exit 2` (`:2088`). E1 printed `landed chore/dev-cycle-2026-10-12 <H> <TREE> <NEW>`, and the message bytes are exactly `Merge branch 'chore/dev-cycle-2026-10-12'\n`. Argument parsing refuses a missing `--main`, a repeated `--main` and a 7-hex `--main`. `--cycle-diff` refuses `--main` (E1).

**Evidence:** `scripts/build-loop.sh:534-547`, `scripts/build-loop.sh:2022-2058`, `/tmp/u4a-fcf-r2-logs/p1.txt`

---

## Claim 3: "**As built (2026-10-13):** `--land-cycle` takes `--main SHA` …; `cycle_rules BASE SIDE` also refuses truthrule's files but the cycle's own …, every Asked: item added must name an entry the questions files gain, and a brief deleted or renamed with an Asked: line refuses …; the questions guard stays `--cycle-diff`'s. Row 674's `entry` line and rows 680/683 moved to U4b"

**Location:** `docs/working/plan-build-loop-handoff.md:339`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** later sessions reading the plan as the record of what U4a built
**Scope:** Covers each stated as-built fact. It does not establish completeness: the note was written at iteration 1 (c0cafb66) and was not extended for iteration 2's rules.

Each stated fact holds:
- the parser takes `--main` (`scripts/build-loop.sh:539`)
- truthrule's non-cycle words refuse (`:1919-1922`)
- items must name a new entry (`grep -qxF -- "$id" "$t.new"`, `:1974`)
- a deleted or renamed brief with an Asked: line refuses (`:1961-1963`)
- the guard is in `cycle_diff` (`:1883-1894`), not in `cycle_rules`
- no `entry` line is printed by `--check` (paraphrased: no quote available because the claim is an absence; `grep -n '"entry '` over `scripts/build-loop.sh` finds no hits)

The note omits iteration 2's exact-item, one-brief-per-ID, duplicate-name and case-spelled rules. The bullet the note amends still reads `--land-cycle --expect MAIN_SHA`, so a reader must take the note's correction over it. Precise version: append "i2: items exactly Q-NNN or Q-NNN@SHA, one brief per new ID, one brief path per file name and side, no case-spelled cycle file".

**Evidence:** `docs/working/plan-build-loop-handoff.md:339`, `scripts/build-loop.sh:534-547`, `scripts/build-loop.sh:1883-1894`, `scripts/build-loop.sh:1907-1979`

---

## Claim 4: "a cycle record the merge adds or changes (docs/working/cycles/cycle-YYYY-MM-DD.md, mode 100644) holding the line "Branch: B", anywhere in it (a trailing CR dropped)"

**Location:** `scripts/build-loop.sh:163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** operator or skill author reading `--help` for `--main-log`'s chore class
**Scope:** Covers the record-name narrowing (isrecord), the mode, status and CR rule in chore_record as log_class now calls it. It does not establish how dev-cycle.sh's own window glob tracks the name (override row, i1 architecture 5).

`chore_record` tests `isrecord "${RAW_P[i]}" && [[ "${RAW_NM[i]}" == 100644 && "${RAW_S[i]}" =~ ^[AM]$ ]]` and awk `sub(/\r$/, "")` (`scripts/build-loop.sh:1736-1745`). `isrecord` is `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` (`scripts/lib/dev-cycle-read.sh:246`). In E4, a merge whose only record is `cycle-2026-10-12-0900.md` read `other`, while a record written with `Branch: B\r\n` read `chore`.

**Evidence:** `scripts/build-loop.sh:1732-1745`, `scripts/lib/dev-cycle-read.sh:243-246`, `/tmp/u4a-fcf-r2-logs/p4.txt`

---

## Claim 5: "A questions change while main has changed those files since BASE refuses … merge main into HEAD first. That refusal is printed alone."

**Location:** `scripts/build-loop.sh:202-205`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator reading `--cycle-diff`'s output
**Scope:** Covers `--cycle-diff`'s guard and its early return. It does not establish `--land-cycle`, which has no such guard by design and judges the merge instead.

The guard's refusal is `{ echo "refuse docs/working/questions.md: the default branch changed …"; return 1; }`, and it returns before `cycle_rules "$base" index` (`scripts/build-loop.sh:1891-1895`). In E2 case i, a staged `scripts/lib/z.sh` (gate code) and a staged questions change printed only the guard line, exit 2.

**Evidence:** `scripts/build-loop.sh:1883-1895`, `/tmp/u4a-fcf-r2-logs/p2.txt`

---

## Claim 6: "A path of the gate's own code (GATE_CODE) refuses, and so does one the lib's truthrule reads as truth (an instruction or prompt file, a dot path, docs/dev-cycle.md, docs/constraints.md, docs/decisions/, docs/human-author/; --check-fix refuses them too), both compared lower-cased, and a cycle file spelled in another case."

**Location:** `scripts/build-loop.sh:216-222`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4b author naming the rules and their remedies in step 6/9
**Scope:** Covers the GATE_CODE test, the truthrule words and the case-spelled cycle file over the 28 paths in E3. It does not establish files that instruction files @-import, which truthrule does not cover (settled override row, i2 security F-e).

The code: `if [[ "$lp" =~ $GATE_CODE ]]`, then `if truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]`, then `if [[ "$TRUTH_WHY" == cycle && "$p" != "$lp" ]]` (`scripts/build-loop.sh:1918-1920`). `truthrule` resets `TRUTH_WHY=""` on entry (`scripts/lib/dev-cycle-read.sh:1915`), so no stale word carries between paths.

E3 results:
- Refused: `Scripts/Lib/x.sh` and `skills/dev-cycle/SKILL.md` (gate code); `AGENTS.md`, `sub/AGENTS.md` and `skills/other/SKILL.md` (instr); `.github/…` and `docs/.hidden.md` (dot); `Docs/Dev-Cycle.md` (settings); `Docs/Decisions/x.md` (record); `docs/Roadmap.md`, `Cycle-2026-10-12.md`, `2026-10-01-X.md` and `Briefs/closed/…` (case-spelled cycle files).
- Passed: the record, briefs, a new brief, the idea log, `docs/thoughts/x.md`, `docs/guide.md`, `README.md`, `docs/working/research-x.md` and `docs/working/cycles/notes.md`.

On "--check-fix refuses them too": `check_fix` skips anything with a truthrule word or outside `^docs/.*\.md$|^readme\.md$` (`scripts/dev-cycle.sh:190-191`), which also covers GATE_CODE.

**Evidence:** `scripts/build-loop.sh:1911-1920`, `scripts/lib/dev-cycle-read.sh:1914-1925`, `scripts/dev-cycle.sh:184-196`, `/tmp/u4a-fcf-r2-logs/p3.txt`

---

## Claim 7a: "A brief's first unfenced "Asked:" line, matched by file name (a move to closed/ under its name too; two changed paths with one name on a side refuse), must be as on BASE, or BASE's line followed by ", " and more (no line on BASE: every item is added). Each item added … must be exactly Q-NNN or Q-NNN@SHA (7-64 hex), name an entry the questions files gain (a "### Q-NNN" heading BASE lacks) … A brief with an Asked: line deleted, or renamed to another file name, refuses."

**Location:** `scripts/build-loop.sh:222-231`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4b author; orchestrator acting on a refusal
**Scope:** Covers the extend-only rule, the item grammar (lower-case hex, 7-64), the new-entry test over both questions files, a move to closed/, the duplicate-name refusal and deletion/rename. It does not establish the "no other brief" clause (Claim 7b).

The code:
- extend-only: `elif [[ "$n" == "$o, "* ]]; then a="${n#"$o, "}"` (`scripts/build-loop.sh:1967`)
- item grammar: `^(Q-[0123456789]+)(@[0123456789abcdef]{7,64})?$` (`:1972`)
- new-entry test: `grep -qxF -- "$id" "$t.new"` (`:1974`), where `$t.new` is built from headings present in the new side and absent from the old (`:2017`)

Test 25 passes in E0. E2 confirms:
- an entry filed in the archive counts as new (case b)
- a brief with no Asked: line on BASE may add `Asked:Q-002, Q-004` (case c)
- a rename to another name refuses (case d)
- a removed Asked: line refuses as "drops or changes" (case e)
- a fenced earlier `Asked:` is skipped (case f)
- an existing entry's ID refuses (case g)
- 6-hex and upper-case hex refuse (case h)

**Evidence:** `scripts/build-loop.sh:1925-1937`, `scripts/build-loop.sh:1954-1979`, `scripts/build-loop.sh:2017-2018`, `/tmp/u4a-fcf-r2-logs/p2.txt`, `/tmp/u4a-fcf-r2-logs/bats.txt`

---

## Claim 7b: "… and be added by no other brief."

**Location:** `scripts/build-loop.sh:229-230`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** U4b author
**Scope:** Covers the `used[]` map across all briefs in one listing. It does not establish wording for the same-brief case, which is Claim 19.

The rule is stricter than stated. `used[$id]` is one map across every brief and every item: `elif [[ -n "${used[$id]-}" ]]; then … bad=1 … else used[$id]=1; fi` (`scripts/build-loop.sh:1975-1976`). An ID added twice by the same brief therefore refuses too (E2 case a). Precise version: "and be added once in the change (by one brief, once)".

**Evidence:** `scripts/build-loop.sh:1975-1976`, `/tmp/u4a-fcf-r2-logs/p2.txt`

---

## Claim 8a: "--land-cycle lands the orchestrator's chore branch … after --state's gate but its caller check: HEAD must be on chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM, the index as its commit, and --main the default branch's commit … The merge of HEAD into main, as --check's (merge-tree, no repo config), is judged against main by --cycle-diff's rules with these --answered IDs … and must add or change a cycle record holding "Branch: B" … Then it writes the merge with the message "Merge branch 'B'" and moves the default branch as --merge does (a compare-and-swap from that commit, or a fast-forward in the worktree that has it checked out; no hooks run). Prints landed B HEAD TREE NEW"

**Location:** `scripts/build-loop.sh:234-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** operator reading `--help`; U4b's step 9
**Scope:** Covers the startup (state_gate, default_gate and store_check of main; no caller_gate), each precondition, that the tree written is merge_result's R, the parents (MAIN_SHA, HEAD's commit), the message bytes, the CAS and FF routes, and that no hooks run in the repo's default hook directory. It does not establish behaviour under a concurrent writer between the check and update-ref (Q-103 residual).

Startup:
- `if [[ "$MODE" == state ]]; then caller_gate …` and `if [[ -n "$GATED" ]]; then state_gate …` (`scripts/build-loop.sh:702-703`)
- `state_start` runs `default_gate`, `gate_repo` and `store_check --main` (`:1310-1316`)

The land:
- `VERDICT=([tip]="$h" [tree]="$r" …)` (`:2054`) feeds `commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}"` with `chore_msg` (`:1548-1550`), run in the gate repository
- hooks are off process-wide via HARDEN's `core.hooksPath=/dev/null` (`scripts/lib/dev-cycle-read.sh:352`)

In E1, `post-merge`, `post-commit`, `pre-commit`, `reference-transaction` and `post-checkout` hooks were planted in the repo's hook dir. Neither the CAS nor the FF route ran any of them. Parents and tree matched. In the FF route, R's checked-out main moved to NEW with a clean status. Test 26 also asserts parents, tree and message (E0).

**Evidence:** `scripts/build-loop.sh:699-703`, `scripts/build-loop.sh:1310-1316`, `scripts/build-loop.sh:1479-1569`, `scripts/build-loop.sh:2022-2058`, `/tmp/u4a-fcf-r2-logs/p1.txt`

---

## Claim 8b: "NEW: the merge commit, now the default branch's (its reflog entry reads "build-loop: cycle land of B")."

**Location:** `scripts/build-loop.sh:251-254`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** operator auditing the branch reflog
**Scope:** Covers both move routes' reflog subject. It does not establish W's HEAD reflog.

On the CAS route the reflog reads exactly `build-loop: cycle land of chore/dev-cycle-2026-10-12`. On the FF route, `GIT_REFLOG_ACTION="$msg" git … merge --ff-only` (`scripts/build-loop.sh:1563`) makes git append its own suffix: E1 read `build-loop: cycle land of chore/dev-cycle-2026-10-13-0900: Fast-forward`. Precise version: "reads 'build-loop: cycle land of B' (with git's ': Fast-forward' after it on the fast-forward route)". --merge's pre-existing header (`:396`) has the same imprecision.

**Evidence:** `scripts/build-loop.sh:1483`, `scripts/build-loop.sh:1555-1567`, `/tmp/u4a-fcf-r2-logs/p1.txt`

---

## Claim 9: "or refuse lines and exit 2: --cycle-diff's rules' (PATH a file; a copy of the merge is "its merge copy"), or refuse HEAD: WHY — Not on such a branch; the default branch moved …; staged changes; nothing the default branch lacks; a conflict; an object that does not hash or has two copies; no such record; --merge's own refusals of the move; or a read that fails"

**Location:** `scripts/build-loop.sh:255-263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator mapping a refusal to its remedy
**Scope:** Covers each `refuse HEAD:` echo in land_cycle against the list, and the "merge" side word in questions_rules. It does not establish each wording of land()'s MERGE_WHY refusals, which are --merge's and unchanged.

Each listed refusal is an `echo "refuse HEAD: …"` in `land_cycle` (`scripts/build-loop.sh:2028-2058`). `land cycle || { echo "refuse HEAD: $MERGE_WHY"; …}` carries --merge's refusals. `k="$side"` gives "its merge copy" (`:2009`). Test 26 exercised these refusals: branch, moved main, staged changes, nothing to land, no record, and a questions-rule refusal on the merge. Test 27 exercised the conflict refusal (E0).

**Evidence:** `scripts/build-loop.sh:2022-2058`, `scripts/build-loop.sh:2009-2010`, `/tmp/u4a-fcf-r2-logs/bats.txt`

---

## Claim 10: "and --land-cycle's (AUTHORITY cycle, VERDICT and CHANGED set by land_cycle; the message git merge writes, "Merge branch 'B'", which --main-log reads as chore)"

**Location:** `scripts/build-loop.sh:1464-1466`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of land()
**Scope:** Covers land()'s two branches on `cycle`, the reflog word and the message, and the caller setting VERDICT and CHANGED. It does not establish the "one table" refactor declined in the override row.

Two branches on the authority: `[[ "$1" != cycle ]] || what="cycle land"` (`scripts/build-loop.sh:1482`), and `if [[ "$1" == cycle ]]; then chore_msg …` (`:1548`). E1's --main-log read both lands as `chore`.

**Evidence:** `scripts/build-loop.sh:1462-1484`, `scripts/build-loop.sh:1548`, `scripts/build-loop.sh:2054-2056`, `/tmp/u4a-fcf-r2-logs/p1.txt`

---

## Claim 11: "chore_msg B: the message of a chore merge, as git merge writes it and --land-cycle writes it (land); log_class reads it back by its subject regex."

**Location:** `scripts/build-loop.sh:1729-1731`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer keeping chore_msg and log_class's regex in step
**Scope:** Covers `git merge --no-edit` of B into a branch named main on git 2.39.5, which writes no " into main". It does not establish other git versions, or other default-branch names under merge.suppressDest.

`chore_msg() { printf "Merge branch '%s'\n" "$1"; }` (`scripts/build-loop.sh:1731`). In E4, `git merge -q --no-ff --no-edit` on main wrote the subject `Merge branch 'chore/dev-cycle-2026-10-12'`. Confidence is Medium because git's suppression of " into X" depends on the branch name and on config.

**Evidence:** `scripts/build-loop.sh:1729-1731`, `scripts/build-loop.sh:1772`, `/tmp/u4a-fcf-r2-logs/p4.txt`

---

## Claim 12: "chore_record B: a cycle record among RAW_* (isrecord, added or changed, mode 100644) holds the line "Branch: B" (a trailing CR dropped) … Returns 1 when none does or a read fails."

**Location:** `scripts/build-loop.sh:1732-1745`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of --main-log and --land-cycle
**Scope:** Covers the match and the failure path under pipefail. It does not establish callers' handling of RAW_* staleness, which is Claim 21.

`gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0` (`scripts/build-loop.sh:1741`). A failed cat-file fails the pipeline under pipefail and falls through to `return 1`. E4 and tests 26-27 confirm the match, including the CR and the wrong-branch record.

**Evidence:** `scripts/build-loop.sh:1736-1745`, `/tmp/u4a-fcf-r2-logs/p4.txt`, `/tmp/u4a-fcf-r2-logs/bats.txt`

---

## Claim 13: "chore_msg's subject, or git merge's with " into X" or ": ..." after it."

**Location:** `scripts/build-loop.sh:1771`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of log_class
**Scope:** Covers the regex `\'($|\ into\ |:)`. It does not establish other git merge subject forms (for example a remote-tracking "Merge remote-tracking branch").

In E4, `Merge branch 'B' into main` and `Merge branch 'B': note` read `chore`, while `Merge branch 'B' extra` read `other`.

**Evidence:** `scripts/build-loop.sh:1771-1776`, `/tmp/u4a-fcf-r2-logs/p4.txt`

---

## Claim 14: "So a staged questions change needs the questions files as on main: merge the default branch into HEAD first. (--land-cycle judges the merge itself.)"

**Location:** `scripts/build-loop.sh:1883-1887`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of cycle_diff
**Scope:** Covers the guard firing only when a questions path is staged, and land_cycle's lack of the guard. It does not establish the guard's coverage of a questions file absent on the base (row 753's case, which only the land catches).

The guard loops `for p in "${RAW_P[@]}"` and continues unless the path is a questions file (`scripts/build-loop.sh:1888-1889`). `land_cycle` has no such guard and runs `cycle_rules "$MAIN_SHA" merge` instead (`:2051`). Test 27's first `cd_is ok`, followed by the land's refusal, demonstrates the split (E0).

**Evidence:** `scripts/build-loop.sh:1883-1895`, `scripts/build-loop.sh:2051`, `/tmp/u4a-fcf-r2-logs/bats.txt`

---

## Claim 15: "asked FILE: a brief's first "Asked:" line outside a fence, a trailing CR dropped, or nothing"

**Location:** `scripts/build-loop.sh:1897-1901`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of cycle_rules
**Scope:** Covers the fence skip and the first-match exit. It does not establish the brief_fields divergence the comment names, which is a settled override row.

`asked() { LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } /^Asked:/ { print; exit }' "$1"; }` (`scripts/build-loop.sh:1901`). In E2 case f, a fenced `Asked: Q-777` before the real line was skipped (ok).

**Evidence:** `scripts/build-loop.sh:1897-1901`, `/tmp/u4a-fcf-r2-logs/p2.txt`

---

## Claim 16: "cycle_rules BASE SIDE: … --cycle-diff's (BASE the merge base, SIDE "index") and --land-cycle's (BASE main's commit, SIDE "merge", the merge it writes) … Prints "refuse PATH: WHY" per finding; returns 1 on any."

**Location:** `scripts/build-loop.sh:1902-1906`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the two call sites and the return value. It does not establish that every printed line is a PATH refusal, since questions_rules can print `refuse docs/working/questions.md:` for a comparison failure.

The two call sites are `cycle_rules "$base" index` (`scripts/build-loop.sh:1895`) and `cycle_rules "$MAIN_SHA" merge` (`:2051`). The function ends `return "$bad"` (`:1979`).

**Evidence:** `scripts/build-loop.sh:1895`, `scripts/build-loop.sh:1907-1979`, `scripts/build-loop.sh:2051`

---

## Claim 17: "An in-cycle fix never edits the gate's code … nor a file sessions or later cycles read as truth, other than the cycle's own (the lib's truthrule …). --check-fix refuses both, and more (its import walk). A cycle file spelled in another case is not one these rules read"

**Location:** `scripts/build-loop.sh:1912-1917`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers check_fix's coverage of GATE_CODE and truthrule paths, and its truthwalk. It does not establish that the orchestrator runs --check-fix before staging (U4b's text; override row).

`check_fix` skips truthrule words and anything outside `^docs/.*\.md$|^readme\.md$`, then calls `truthwalk tree "$lp"` (`scripts/dev-cycle.sh:190-193`). The case-sensitive `case "$p" in docs/working/questions.md|…` dispatch (`scripts/build-loop.sh:1938-1942`) is why a case-spelled file would go unread.

**Evidence:** `scripts/dev-cycle.sh:184-196`, `scripts/build-loop.sh:1912-1942`

---

## Claim 18: "Step 6 only appends IDs to a brief's first Asked: line, each a Q-NNN or Q-NNN@SHA (D4) naming an entry this change files ($t.new) and no other brief takes … A brief deleted, or renamed to another file name, with an Asked: line refuses too."

**Location:** `scripts/build-loop.sh:1954-1959`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the loop that follows. As in Claim 7b, "no other brief" understates the once-only map; that residue is carried by Claims 7b and 19.

The loop matches the comment (`scripts/build-loop.sh:1960-1978`), confirmed by E2 cases a-h and test 25.

**Evidence:** `scripts/build-loop.sh:1954-1979`, `/tmp/u4a-fcf-r2-logs/p2.txt`

---

## Claim 19: refusal text "its first Asked: line adds $x, which another brief's Asked: line adds too"

**Location:** `scripts/build-loop.sh:1975`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator acting on the refusal
**Scope:** Covers the refusal's wording when one brief adds the same new ID twice. It does not establish any wrong verdict: the refusal itself is correct and exits 2.

`used[$id]` is set by the first item of the same brief too. With `Asked: Q-001@abc, Q-002, Q-002` and Q-002 a new entry, E2 case a printed `refuse docs/working/briefs/2026-10-01-x.md: its first Asked: line adds Q-002, which another brief's Asked: line adds too`, but no other brief changed. A reader acting on the line would look for a second brief that does not exist. Precise wording: "which is added more than once (by this or another brief's Asked: line)". The defect is user-facing message text only, not code or contract behaviour.

**Evidence:** `scripts/build-loop.sh:1975-1976`, `/tmp/u4a-fcf-r2-logs/p2.txt`

---

## Claim 20: "questions_rules BASE SIDE I...: … also writes $GATE_TMP/cy.new, the IDs of the entries the listing files (a "### Q-NNN" heading BASE lacks), one per line: empty when no questions file changed or a read failed."

**Location:** `scripts/build-loop.sh:1981-1985`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer of cycle_rules' Asked: loop
**Scope:** Covers the truncation at entry, the early return with no indices, and every read-failure return before the final awk. It does not establish behaviour on a QDIFF refusal, where cy.new is still written; that is intended.

`: > "$t.new"` then `[[ $# -gt 0 ]] || return 0` (`scripts/build-loop.sh:1988-1990`). Each read failure returns before line `:2017`, so the file stays empty. The final awk's failure path also runs `: > "$t.new"` (`:2018`).

**Evidence:** `scripts/build-loop.sh:1986-2020`

---

## Claim 21: land_cycle's comments: "store_check reads every blob of R, so a blob the store lacks refuses here"; "cycle_rules reads RAW_* and leaves it as raw_records filled it, for chore_record and CHANGED"; "Every key check_line sets, so land reads none unset"

**Location:** `scripts/build-loop.sh:2043-2053`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers store_check's listing (`ls-tree -r -t` of each REV, with a missing object failing the perl reader), the absence of RAW_* writes in cycle_rules, questions_rules, asked, cyc_blob and truthrule, and the key set. It does not establish gitlink targets, which store_check skips by design.

The three comments hold:
- store_check lists `git ls-tree -r -t … "$r" | awk '$1 != "commit"'` and fails on `NAME missing` (`scripts/build-loop.sh:1077-1084`).
- No assignment to `RAW_` appears outside `raw_records` (paraphrased: no quote available because the claim is an absence; grep over both scripts finds `RAW_*=` only in `raw_records`).
- check_line's `VERDICT=([tip] [tree] [policy] [branch] [stem] [gate])` (`:1396`) has the same keys as land_cycle's (`:2054`).

**Evidence:** `scripts/build-loop.sh:1062-1099`, `scripts/build-loop.sh:1026-1036`, `scripts/build-loop.sh:1396`, `scripts/build-loop.sh:2054`

---

## Claim 22: "A cycle record: one per day, updated in place by each iteration (dev-cycle.sh reads the window from these names; build-loop.sh's --main-log and --land-cycle read its Branch: lines)."

**Location:** `scripts/lib/dev-cycle-read.sh:243-246`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer of the record name
**Scope:** Covers the parenthetical's callers. It does not establish "one per day, updated in place", which is orchestrator behaviour, settled as Defer in the override row (i1 claim 19b).

dev-cycle.sh's window reader is `for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:225`). build-loop.sh's `chore_record` calls `isrecord`, and both log_class (`:1776`) and land_cycle (`:2052`) call `chore_record`.

**Evidence:** `scripts/dev-cycle.sh:225`, `scripts/build-loop.sh:1739`, `scripts/build-loop.sh:1776`, `scripts/build-loop.sh:2052`

---

## Claim 23: "The read-as-truth rule --check-fix, floor and build-loop.sh's cycle_rules share (cycle_rules refuses every word but cycle, so a cycle file must never take an earlier word …"

**Location:** `scripts/lib/dev-cycle-read.sh:1899-1901`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer editing truthrule's word order
**Scope:** Covers the three callers and cycle_rules' "!= cycle" test. It does not establish that no current cycle path takes an earlier word beyond E3's sample; by reading, the writable() paths hold no upper case, no `.`-component and no instruction-file name.

The callers are `check_fix` (`scripts/dev-cycle.sh:190`), `floor` (`scripts/lib/dev-cycle-read.sh:1998`) and `cycle_rules` (`scripts/build-loop.sh:1919`). The words tested before `cycle` are case, instr and dot (`:1916-1918`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1914-1925`, `scripts/build-loop.sh:1919`, `scripts/dev-cycle.sh:190`

---

## Claim 24: test name "--cycle-diff refuses the gate's code, truth files and a brief's Asked: line other than extended by entries the change files, matched by name across a move to closed/ (row 745, U4a, i1 security F1-F3, i2 F-a to F-d)"

**Location:** `test/scripts/build-loop-orchestrator.bats:466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer reading the suite as the contract
**Scope:** Covers each named case. It does not establish the rename-to-another-name refusal, which the test covers only by `git rm` (E2 case d covers the rename), nor the same-brief duplicate (Claim 19).

The test asserts:
- an ID appended for a new entry passes; one naming an old entry or no entry refuses
- the exact-item refusal (`Q-002@Q-003`, an empty item)
- one brief per ID (x/y)
- a move to closed/ passes, and changing the Asked: line there refuses
- the same name in briefs/ and closed/ refuses
- a changed and a deleted Asked: line refuse
- GATE_CODE (`SKILLS/dev-cycle/x.md`, `scripts/lib/a.sh`), instr (`AGENTS.md`), settings and case-spelled `docs/working/Questions.md` refuse

Passes in E0.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:466-492`, `/tmp/u4a-fcf-r2-logs/bats.txt`

---

## Claim 25: test name "--land-cycle lands HEAD's chore branch as the merge --main-log reads as chore, by compare-and-swap or a fast-forward where main is checked out (D13, rows 719, 749, 752, U4a)"

**Location:** `test/scripts/build-loop-orchestrator.bats:498`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the update-ref route (main checked out nowhere, since R is on the chore branch), the FF route (main in R, HEAD in a linked worktree), the moved-main precheck, `--main-log` reading `chore`, and the parents, tree and message. It does not establish update-ref's old-value refusal under a race, the reflog text (E1 covers it) or the no-hooks property (E1 covers it).

The test asserts output, `main^1 main^2 main^{tree}`, `git log -1 --format=%B main` and `--main-log`'s line. On the FF route it asserts `git -C "$R" rev-parse HEAD^1` and a clean status. Passes in E0.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:494-520`, `/tmp/u4a-fcf-r2-logs/bats.txt`, `/tmp/u4a-fcf-r2-logs/p1.txt`

---

## Claim 26: test name "--land-cycle judges the merge, not the index: a rename git pairs into a new questions file carries main's answer, and a conflict refuses (row 753, U4a)"

**Location:** `test/scripts/build-loop-orchestrator.bats:522`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers `--cycle-diff` passing the index, merge-tree carrying `Q-001: [1]` into questions.md, the land refusing it as a new entry filed answered, and a conflict refusing. It does not establish the fence-pair capture variant named in the header.

The test asserts `cd_is ok`, then ``git show "$(git merge-tree --write-tree main HEAD):docs/working/questions.md" | grep -qxF 'Q-001: [1]'``, then the land's refusal, then the conflict refusal. Passes in E0.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:522-531`, `/tmp/u4a-fcf-r2-logs/bats.txt`

---

## Claim 27a: 722c2e10 body "--land-cycle --expect MAIN [--answered Q-NNN]... lands the orchestrator's chore/dev-cycle-DATE[-HHMM] branch"

**Location:** commit `722c2e10` (message body, paragraph 1)
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reader of `git log` on main after merge
**Scope:** Covers the flag name at HEAD. It does not establish anything about 722c2e10's own tree, where the flag was `--expect`.

At HEAD the flag is `--main`, and `--expect` is refused (E1 usage text; `scripts/build-loop.sh:539-541`). 70d24331's body records the change: "--land-cycle takes --main SHA, not --expect". The flag-name drift is not covered by the override rows. The row-749 drift in this same body is a settled override row.

**Evidence:** `scripts/build-loop.sh:536-547`, commit `70d24331`, `/tmp/u4a-fcf-r2-logs/p1.txt`

---

## Claim 27b: 722c2e10 body, remainder: "from the main commit --cycle-diff checked (a moved main refuses), HEAD's commit only (staged changes refuse), merge-tree's clean merge judged against main by --cycle-diff's rules …, a cycle record holding "Branch: B" required, then commit-tree with "Merge branch 'B'" …; chore_record is --main-log's chore test, shared with the land; isrecord is the one record-name predicate …; A deleted roadmap now reads "it is deleted""

**Location:** commit `722c2e10` (message body)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reader of `git log`
**Scope:** Covers each listed behaviour at HEAD. It does not establish the row-749 attribution (settled override row, i1 claim 24b), or "the one record-name predicate" for dev-cycle.sh (settled override row, i1 architecture 5).

Each behaviour holds per Claims 2, 4, 8a and 12. The roadmap refusal reads `echo "refuse $p: it is deleted"` (`scripts/build-loop.sh:1945`), and test 24's expectation matches.

**Evidence:** `scripts/build-loop.sh:1945`, `scripts/build-loop.sh:2022-2058`, `/tmp/u4a-fcf-r2-logs/bats.txt`

---

## Claim 28a: 70d24331 body "(asked_rule; i1 security F1, F3)"

**Location:** commit `70d24331` (message body, bullet 1)
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** reader of `git log`
**Scope:** Covers the function name. It does not establish anything about the rule, which holds at HEAD inline in cycle_rules.

`asked_rule` no longer exists. 4df6ec58 inlined it ("The Asked: rule is inline in cycle_rules (no dynamic scope)"), which the later commit states. The claim is paraphrased: no quote available because the claim is an absence; grep for `asked_rule` over `scripts/` finds no hits.

**Evidence:** `scripts/build-loop.sh:1954-1979`, commit `4df6ec58`

---

## Claim 28b: 70d24331 body, remainder (truth files refused; `--main` not `--expect`; the guard moved into cycle_diff; SIDE; chore_msg the one message definition; every VERDICT key; "Correction to 722c2e10's body: the land answers row 749 by judging HEAD's commit")

**Location:** commit `70d24331` (message body)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reader of `git log`
**Scope:** Covers each bullet at HEAD. It does not establish the "but the cycle's own" wording, which is a settled override row (i2 claims 2, 21b).

Each bullet holds per Claims 2, 6, 10, 14, 16 and 21. `chore_msg` is the one definition: `log_class` compares by regex, and `land` calls `chore_msg` (`scripts/build-loop.sh:1548`).

**Evidence:** `scripts/build-loop.sh:1548`, `scripts/build-loop.sh:1883-1895`, `scripts/build-loop.sh:2054`

---

## Claim 29: 4e14d1cc "U4a fix-drift: "other than a cycle file", not "but" … wording only"

**Location:** commit `4e14d1cc`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** reader of `git log`
**Scope:** Covers the commit's diff. It does not establish anything further.

`git show 4e14d1cc` changes two comment lines in `scripts/build-loop.sh` (header and cycle_rules comment), "but" → ", other than". No code changes.

**Evidence:** commit `4e14d1cc` (`scripts/build-loop.sh`, 2 insertions, 2 deletions)

---

## Claim 30: 4df6ec58 body (exact items, the old check read only the item's start, one brief per ID, duplicate names, case-spelled cycle files, inline Asked: rule, questions_rules called once, floor_why prose, header updates)

**Location:** commit `4df6ec58`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reader of `git log`
**Scope:** Covers each bullet at HEAD, plus the "old check" claim against 70d24331's tree. It does not establish the "interim reading of row 745" note, which is design rationale.

70d24331's tree had `[[ "$x" =~ ^(Q-[0123456789]+)(@|$) ]]` (`git show 70d24331:scripts/build-loop.sh:1995`), which reads only the item's start. HEAD anchors the whole item (`scripts/build-loop.sh:1972`). `questions_rules` is called once (`:1953`). Refusals use `floor_why "$TRUTH_WHY"` except the settings word (`:1920`). The remaining bullets hold per Claims 5, 6 and 7a, E2 and test 25.

**Evidence:** `scripts/build-loop.sh:1918-1979`, commit `70d24331` `scripts/build-loop.sh:1995`, `/tmp/u4a-fcf-r2-logs/p2.txt`

---

## Claim 31: c0cafb66 and c4e36d1d bodies ("no red; three ambers fixed in the previous commit"; "plan interface placement"; "no red; four security ambers and the fact-check's Incorrect fixed in the previous commit")

**Location:** commits `c0cafb66`, `c4e36d1d`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** reader of `git log`
**Scope:** Covers c4e36d1d's plan diff, which moves the `--land-cycle` bullet under "Gate:" and adds U4a's rules to `--cycle-diff`'s bullet. It does not establish the rubric's red/amber tallies, which were not recounted.

`git show c4e36d1d -- docs/working/plan-build-loop-handoff.md` moves the `--land-cycle` line from "Read modes" to "Gate:" and extends line 209.

**Evidence:** commit `c4e36d1d` (`docs/working/plan-build-loop-handoff.md:209-212`)

---

## Claims Requiring Attention

### Incorrect
- **Claim 19** (`scripts/build-loop.sh:1975`): the refusal says "another brief's Asked: line adds too" when one brief adds the same new ID twice (E2 case a). The verdict is correct; the message is wrong. Reword to "is added more than once". This is message text only, not behavioural.

### Stale
- **Claim 27a** (commit `722c2e10`): body names `--land-cycle --expect MAIN`; at HEAD the flag is `--main` (70d24331's body corrects it).
- **Claim 28a** (commit `70d24331`): body names `asked_rule`, inlined into cycle_rules by 4df6ec58.

### Mostly Accurate
- **Claim 1** (`docs/working/plan-build-loop-handoff.md:209`): the interface bullet omits iteration 2's rules (exact items, one brief per ID, duplicate names, case-spelled cycle files) and the deleted/renamed-brief refusal.
- **Claim 3** (`docs/working/plan-build-loop-handoff.md:339`): the as-built note stops at iteration 1; add iteration 2's rules.
- **Claim 7b** (`scripts/build-loop.sh:229-230`): "added by no other brief" should say "added once in the change"; a same-brief duplicate refuses too.
- **Claim 8b** (`scripts/build-loop.sh:253-254`): the reflog reads "build-loop: cycle land of B: Fast-forward" on the FF route.

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion: a markdown report saved at the exact path your own prompt names, structured per your skill.

This report is saved at `/workspace/.claude/wt-build-loop-u4a/docs/reviews/code-fact-check-report-2026-10-13-u4a-final-r2.md`. Its first line is `Commit: c4e36d1d`, and it carries the skill's header and per-claim fields, plus a Legibility-target on every claim. No other file in the worktree or /workspace was written; probe output lives under `/tmp/u4a-fcf-r2-*`. The one Incorrect (Claim 19) affects only the wording of a refusal, not a verdict. The gate's land contract is confirmed by execution: the tree, parents and message that land are exactly what was judged, no hooks run, and the CAS and FF routes both work. The truth rule, the Asked: rule and log_class's chore class are also confirmed by execution.
