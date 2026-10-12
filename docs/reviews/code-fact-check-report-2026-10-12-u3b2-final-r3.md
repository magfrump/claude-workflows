Commit: 4afdd68b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b2 (branch `feat/build-loop-u3b2`, HEAD 4afdd68b)
**Scope:** full branch diff `main...HEAD` (main b5f21758): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-orchestrator.bats, docs/working/plan-build-loop-handoff.md (U3b2 bullet), docs/reviews/override-log.md (rows 718-728), the rubric's Fixed claims, and the commit messages 1d829fee, cca66dc2, 4afdd68b. Final confirming pass, replicate r3 of k=3.
**Checked:** 2026-10-12
**Total claims checked:** 42
**Summary:** 36 verified, 4 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log read first (`docs/reviews/hallucination-patterns.md`). Its recurring pattern is a count or measured number quoted in prose that the artifact no longer bears out; claims 16a and 18a (counts about this repo's history) match that family. No fabricated symbol, option or API was found.

Execution provenance, all under the scratchpad directory `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r3/`. Each probe made its own `mktemp -d /tmp/u3b2rv-fcf-XXXX` directory, ran with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, and ran on 2026-10-12 between 16:05 and 16:22 -0700:
- `p1.sh` / `p1.log`: `git clone --no-local --single-branch -b main /workspace repo`, then three HEAD runs of `bash scripts/build-loop.sh --main-log <root>` in the clone; `git count-objects -v` after each run. The script exited 0; each `--main-log` run exited 2. (Its timing column failed because `bc` is not installed. The timings are in p5.log.)
- `p2.sh` / `p2.log`: `bats -f main-log test/scripts/build-loop-orchestrator.bats` from HEAD's tree with `scripts/build-loop.sh` set to HEAD, cca66dc2 and 1d829fee in turn. The script exited 0.
- `p3.sh` / `p3.log`: six mutants of HEAD's script (M1-M6), each run under the same two tests. M3 ran twice, under HEAD's test file and under cca66dc2's. The script exited 0.
- `p4.sh` / `p4.log`: a throwaway fixture repo holding chore, gate and answers edge cases, with one `--main-log` run, which exited 2.
- `p5.log`: timed root-SINCE runs on the clone, HEAD then cca66dc2 then HEAD, at 2026-10-12T16:21:22-07:00. Each run exited 2.

---

## Claim 1: "Status (iteration 1): no 🔴 · 🟡 3 · 🟢 10. D1-D7 and D9 fixed in the iteration-1 fix commit (cca66dc2); D8 and D10-D13 carry override rows dated 2026-10-12." and "report ... (31 claims: 24 Verified, 7 Mostly Accurate, 0 Incorrect)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:5-7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tier counts in the rubric's own tables, the i1 report's header and verdict lines, and the rows that exist for D8 and D10-D13. It does not establish that each finding was tiered correctly.

The 🟡 table holds D1-D3 and the 🟢 table holds D4-D13 (paraphrased — no quote available because the claim is a count of table rows at `:17-34`). The i1 report reads `**Summary:** 24 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable` (`docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md:10`), and `grep '^\*\*Verdict:'` counts 24 and 7. The rows exist: D8 is `override-log.md:724`, D10 is `:725` (with the hand-off in `:719`), D11 is `:722`, D12 is `:723` and D13 is `:726`.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:5-34`, `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md:9-10`, `docs/reviews/override-log.md:719-726`

---

## Claim 2: "D1 ... Fixed (tree must equal merge-tree's clean merge of the parents; test; mutant killed)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clean_merge guard on both two-parent branches, and test 2 failing both on 1d829fee and on a HEAD mutant without the guard. It does not establish which of test 2's assertions kills the chore-amend case on its own, because the gate-amend assertion fails first.

At HEAD the guard sits after each subject match. On the gate branch it reads `clean_merge || return 0` (`scripts/build-loop.sh:1659`), and the chore branch repeats it at `:1667`. Under HEAD's test file, 1d829fee's script fails test 2: the commit "over another tree" reads `gate d3c4f653... Merge branch 'feat/x' (build-loop self-merge)` (p2.log). Mutant M1, which adds `return 0` at the top of clean_merge, also fails test 2 (p3.log).

**Evidence:** `scripts/build-loop.sh:1644-1648`, `scripts/build-loop.sh:1657-1667`, `test/scripts/build-loop-orchestrator.bats:195-206`; `.../u3b2-fcf-r3/p2.log` (command `bats -f main-log test/scripts/build-loop-orchestrator.bats`, cwd a HEAD-tree copy under /tmp/u3b2rv-fcf-*, bats exit 1 for 1d829fee), `.../u3b2-fcf-r3/p3.log` (M1: not ok 2)

---

## Claim 3: "D2 ... Fixed (at least one added answer line; the deleted-answer test killed the mutant; the Status-flip test was empty until E1; ...)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `n` counter (added answer lines only), the deleted-answer and Status-flip assertions killing their mutants under HEAD's test file, and the Status-flip assertion surviving its mutant under cca66dc2's test file. It does not establish the revert clause beyond reading the code.

`if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }` and `END { flush(); exit !(n > 0 && !bad) }` (`scripts/build-loop.sh:1627`, `:1631`). Mutant M6, which counts a removed answer (`n++` for either sign), fails test 2. M2, which drops `n > 0`, fails test 2. M3 makes an added header line count as an answer, so a Status flip alone passes. M3 fails HEAD's test 2 but passes cca66dc2's test 2. That confirms the flip assertion pinned nothing before E1 (p3.log).

**Evidence:** `scripts/build-loop.sh:1612-1631`, `test/scripts/build-loop-orchestrator.bats:215-218`; `.../u3b2-fcf-r3/p3.log` (M2, M3_flipcounts_head, M6: not ok 2; M3_flipcounts_cca: ok 2)

---

## Claim 4: "D4 ... Fixed (`main MAIN -` first)" and "D9 | Empty subject printed as a trailing space | ... | Fixed (`-`)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:25`, `:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both refusal paths printing the main line first, and an empty subject printing `-`. It does not establish what U4 does with either line.

`|| { echo "main $MAIN_SHA -"; echo "refuse main-log: $1 is not on the default branch's first-parent history at $MAIN_SHA"; return 1; }` (`scripts/build-loop.sh:1697`); the rev-list failure path at `:1694` is the same. `SUBJ="${m[0]-}"; [[ -n "$SUBJ" ]] || SUBJ=-` (`:1656`). Mutant M4 removes the main line and M5 removes `SUBJ=-`; both fail test 2 (p3.log).

**Evidence:** `scripts/build-loop.sh:1690-1703`, `scripts/build-loop.sh:1656`, `test/scripts/build-loop-orchestrator.bats:218-223`; `.../u3b2-fcf-r3/p3.log`

---

## Claim 5: "E1 ... Fixed (flip before the route change; each near-miss commit asserted non-empty)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:44`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reorder and the non-empty assertion over the four answers near-misses. It does not establish a non-empty assertion for the chore near-misses, and it notes that the empty-commit near-miss is empty on purpose.

The reorder is real and now pins the flip: `q 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/'; q 's/you: judgment/agent/'; q '' ''; q '/^Q-001: \[1\]$/d'` (`test/scripts/build-loop-orchestrator.bats:216`), and mutant M3 is killed (claim 3). The assertion, however, is `for i in 4 3 2 1; do [ -n "$(git diff "main~$i" "main~$((i - 1))")" ] ...` (`:217`). That covers only the four answers commits. The near-miss `tip main ''; E=...` (`:214`) is an empty commit by design, so "each near-miss commit" is too broad. The precise wording would be "each answers near-miss commit".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:208-219`; `.../u3b2-fcf-r3/p3.log`

---

## Claim 6: "E4 | merge-tree ran on every merge before the subject could match ... | Fixed (clean_merge after the subject)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:47`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering at HEAD, output identical to cca66dc2's on a clone of /workspace's main, and no store writes at HEAD. It does not establish the exact seconds saved (see claim 40).

HEAD tests the subject regex first (`if [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(.+)\'\ \(build-loop\ (self-merge|approved merge)\)$ ]]; then ... clean_merge || return 0`, `scripts/build-loop.sh:1657-1659`). On the clone, three HEAD runs left `count: 0 size: 0` (p1.log). A cca66dc2 run afterwards wrote `count: 87 size: 616`, and its output was byte-identical to HEAD's (`cmp` said identical; p5.log shows the same class tallies).

**Evidence:** `scripts/build-loop.sh:1657-1667`; `.../u3b2-fcf-r3/p1.log`, `.../u3b2-fcf-r3/p5.log`

---

## Claim 7: "Fact-check ...: 36 claims, 29 Verified, 5 Mostly Accurate, 2 Incorrect (rubric text; a test fixture), none behavioural"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:40`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts against the i2 report. It does not re-judge the i2 verdicts.

The i2 report reads `**Summary:** 29 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable` with `**Total claims checked:** 36` (`docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md:9-10`), and the verdict lines count 29, 5 and 2.

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md:9-10`

---

## Claim 8: "Row 662 discharged: `gate_msg` is the one definition ... land and log_class both call gate_msg; the reader compares the commit's message byte for byte with gate_msg's output."

**Location:** `docs/reviews/override-log.md:718`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both call sites and the byte compare. It does not establish whether gate commits already on main before this change still match (none exist on main; see claim 30).

land: `gate_msg "${VERDICT[branch]}" "$what" "${VERDICT[stem]}" "${2-}" > "$GATE_TMP/msg"` (`scripts/build-loop.sh:1461`). Reader: `gate_msg "$b" "$x" "$p" "$q" > "$GATE_TMP/want" && cmp -s "$GATE_TMP/want" "$GATE_TMP/m" && CLASS=gate` (`:1664`). Test 1 classifies a real `--merge` as `gate` (`test/scripts/build-loop-orchestrator.bats:174-182`; p2 HEAD ok 1). A hand-built approved message with a `Build-loop-approved: Q-007` trailer read `gate` (p4.log).

**Evidence:** `scripts/build-loop.sh:1374-1377`, `scripts/build-loop.sh:1461`, `scripts/build-loop.sh:1657-1664`; `.../u3b2-fcf-r3/p2.log`, `.../u3b2-fcf-r3/p4.log`

---

## Claim 9: Row 719, the chore hand-off: `--no-ff` (a fast-forward reads other), git's default merge, no hand-resolved conflict, the subject tail, a `cycle-*.md` record with mode 100644 holding "Branch: B", and any of several Branch: lines counting

**Location:** `docs/reviews/override-log.md:719`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each reader rule the row names. It does not establish the row's "as an unfenced line near the top", which is a requirement for U4's writer: the reader accepts the line anywhere, fenced or not (p4: a fenced CRLF line read `chore`).

The subject regex is `^Merge\ branch\ \'(chore/dev-cycle-[0123456789]{4}-[0123456789]{2}-[0123456789]{2}(-[0123456789]{4})?)\'($|\ into\ |:)` (`scripts/build-loop.sh:1665`). The record test is `[[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && "$meta" =~ ^:[01234567]{6}\ 100644\ ...\ [AM]$ ]]`, then an awk that drops a trailing CR and matches `$0 == w` (`:1670-1672`). In p4, `' into main'` with the line in a fenced CRLF record read chore. A tail `x` read other, mode 100755 read other, a trailing blank read other, an indented line read other, and `: t` on a record whose line had a trailing blank read other. A fast-forward lands the record commit as a one-parent commit that touches `docs/working/cycles/`, so the answers loop's `|| return 0` (`:1678`) makes it other.

**Evidence:** `scripts/build-loop.sh:1665-1673`, `scripts/build-loop.sh:1674-1678`; `.../u3b2-fcf-r3/p4.log`

---

## Claim 10: "--main-log's answers class is strict: a multi-line answer, a note under the answer, or the user's archive move reads as other"

**Location:** `docs/reviews/override-log.md:720`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the awk falling through to `bad = 1` for any changed line that is neither blank, nor an answer label, nor a `**Needs:**` line. It does not establish that every real archive move changes such a line (it does, because it moves `### Q-` headings).

Any other changed line reaches `bad = 1` (`scripts/build-loop.sh:1629`). A continuation line, a note or a moved `### Q-NNN` heading is none of the three kinds tested at `:1625-1628`. In p4, an indented answer and a line that gained a CR both read other.

**Evidence:** `scripts/build-loop.sh:1619-1631`; `.../u3b2-fcf-r3/p4.log`

---

## Claim 11: "--main-log reads history commits without store_check (only main's own commit and tree are re-hashed, by state_start), and classes are read from each commit's own text"

**Location:** `docs/reviews/override-log.md:721`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the single `store_check --main "$MAIN_SHA"` call. "tree" here means the whole tree below MAIN, which is what store_check walks. It does not establish what a forger could do (outside the threat model).

`store_check --main "$MAIN_SHA"` (`scripts/build-loop.sh:1224`) is the mode's only store_check. log_class and main_log read through `gate_git` with no further store_check (paraphrased — no quote available because the claim covers the absence of a call: grep finds no store_check in `:1602-1703`).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1602-1703`, `scripts/build-loop.sh:1714-1717`

---

## Claim 12: "A chore merge's other paths are not read"

**Location:** `docs/reviews/override-log.md:722`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the chore loop. It does not establish whether U3c will add a path list.

`[[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && ... ]] || continue` (`scripts/build-loop.sh:1670`) skips every other path without judging it.

**Evidence:** `scripts/build-loop.sh:1668-1673`

---

## Claim 13: "--main-log runs with the caller's git -c pairs unchecked (only --state reads them)"

**Location:** `docs/reviews/override-log.md:723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers caller_gate being --state's only. It does not establish what a given pair changes in the reads.

`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`scripts/build-loop.sh:631`).

**Evidence:** `scripts/build-loop.sh:631-632`

---

## Claim 14: "Three readers of `diff-tree --raw -z` (check_line, log_class's chore and answers loops) with different strictness ... Each fails closed today (the chore loop skips an unparsed record: no record, other)."

**Location:** `docs/reviews/override-log.md:724`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three call sites and the chore loop's skip. It does not establish check_line's own strictness.

The three call sites are `gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree"` (`scripts/build-loop.sh:1276`), plus `:1668` and `:1675` in log_class. The chore loop continues past an unmatched record (`:1670`) and leaves `CLASS=other`. The answers loop returns on one (`:1678`) and checks the NUL count (`:1682`).

**Evidence:** `scripts/build-loop.sh:1276`, `scripts/build-loop.sh:1668-1682`

---

## Claim 15: "The cycle-record name is cycle-*.md here but cycle-YYYY-MM-DD.md in the lib's writable and dev-cycle.sh"

**Location:** `docs/reviews/override-log.md:725`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three patterns. It does not establish which one U4 will use.

The lib's writable uses `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` (`scripts/lib/dev-cycle-read.sh:245`). dev-cycle.sh uses `docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:217`). Here it is `cycle-[^/]+\.md$` (`scripts/build-loop.sh:1670`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:245`, `scripts/dev-cycle.sh:217`, `scripts/build-loop.sh:1670`

---

## Claim 16a: "Every commit on this repo's main today reads other (hand merges, checkpoint commits)"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a root-SINCE run of HEAD's script on a clone of /workspace's main (MAIN 34cf382f, which includes b5f21758). It does not establish the classes of commits landed after the clone.

The run printed `main 34cf382f... 1118`, then 1117 `other` lines and one `answers dfe4c0df99c4fb27991355c6632f936a3d8fe1ee docs(questions): answer Q-093 [1] and Q-094 [1]` (p5.log). That commit is an honest answers commit with two Status flips and two `**Answer (2026-09-28): [1].**` lines, which the rule accepts. The precise version is "every commit but one answers commit (dfe4c0df) reads other". The row's conclusion, that a human landing stops dispatch, holds.

**Evidence:** `scripts/build-loop.sh:1674-1685`; `.../u3b2-fcf-r3/p5.log`, `.../u3b2-fcf-r3/p1.log`

---

## Claim 16b: "per-commit cost ~6-9 ms, ~7-10 s for a SINCE at this repo's root (1,119 commits, 422 merges); --state and --main-log each re-hash main's tree"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one machine (16 cores, load average about 2-2.8) and one clone. It does not establish timings under other loads.

`git rev-list --first-parent --count main` gives 1119 and `--first-parent --merges --count` gives 422. HEAD's root-SINCE runs took 7323, 7106, 6983, 7092, 7820, 8113 and 8056 ms over 1118 commits, about 6.2-7.3 ms per commit (p5.log; the earlier runs are in this session's shell output). Both modes call `state_start`, which runs `store_check --main` (`scripts/build-loop.sh:1224`, `:1711`, `:1715`).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1710-1717`; `.../u3b2-fcf-r3/p5.log`

---

## Claim 16c: "bootstrap by running --main-log with any full id off main's history, which prints "main MAIN -" before its refusal"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers any lowercase 40- or 64-hex string, which awk compares as text. It does not establish that such a string must name an object (it need not).

`LC_ALL=C awk -v s="$1" '$0 == s { f = 1; exit } ...' ... || { echo "main $MAIN_SHA -"; ...` (`scripts/build-loop.sh:1696-1697`). The test asserts `main $T -` and then the refusal (`test/scripts/build-loop-orchestrator.bats:221-222`; p2 HEAD ok 2).

**Evidence:** `scripts/build-loop.sh:1690-1703`; `.../u3b2-fcf-r3/p2.log`

*(Claims 16a-16c count as three claims in the total.)*

---

## Claim 17: "The answers class counts any added answer label in any entry, from anyone"

**Location:** `docs/reviews/override-log.md:727`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the awk, which never reads an entry ID or heading. It does not establish U4's digest.

`if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }` (`scripts/build-loop.sh:1627`) matches any Q- number in any hunk.

**Evidence:** `scripts/build-loop.sh:1612-1631`

---

## Claim 18a: "a hand-resolved or conflicting merge adds unreachable ones once: 87 objects, 616 KiB over this repo's history; idempotent after"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Performance
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the object count of a root-SINCE run on a clone of /workspace's main, at HEAD and at cca66dc2. It does not establish counts for other repositories.

The figure is cca66dc2's. That commit ran merge-tree on every two-parent commit, and on the clone a cca66dc2 run wrote `count: 87 size: 616` (p5 session; p1.log shows 0 before). The row was written in 4afdd68b, the same commit that moved clean_merge after the subject (`scripts/build-loop.sh:1657-1659`, `:1665-1667`). At HEAD only a gate- or chore-subject merge reaches merge-tree, and this history has one such merge (cac2ba0c, whose tree equals merge-tree's: `71374d6e...` both). Three HEAD runs wrote `count: 0 size: 0` (p1.log). Now accurate: "a hand-resolved or conflicting merge with a gate or chore subject adds them once; none on this repo's history at HEAD (cca66dc2 wrote 87 objects, 616 KiB)". The row's own commit message says the same ("saving ... every store write on this repo's history"). Matches the logged pattern family "a count quoted in prose that the artifact no longer bears out".

**Evidence:** `scripts/build-loop.sh:1641-1667`; `.../u3b2-fcf-r3/p1.log`, `.../u3b2-fcf-r3/p5.log`

---

## Claim 18b: "a constructed merge with thousands of modified renames costs ~5 s per run ... the rename case fails closed past git's limit"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the source of the figure. It does not establish the timing, which this pass did not reproduce.

The figure comes from the i2 performance review's probe (`merge-tree alone 5.47 s`, `docs/reviews/performance-review-2026-10-12-u3b2-i2.md:26`). Rebuilding a 100,001-file fixture with 5,000 inexact renames was out of this pass's budget. Execution is required to verify it.

**Evidence:** `docs/reviews/performance-review-2026-10-12-u3b2-i2.md:26-27`, `scripts/build-loop.sh:1644-1648`

---

## Claim 19: The plan's U3b2 "As built" note (gated after state_start; reads in the gate repository; SINCE rules; output; the clean-merge rule after the subject; bootstrap; gate, chore and answers rules; "Anything unread is other")

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against the code, the two tests and the p4 probes. It does not establish U4's side of the hand-off.

The mode arm is `main-log) state_start; main_log "${ARGS[0]}" || exit 2` (`scripts/build-loop.sh:1714-1717`). GATED holds for any mode but settings, status and marker (`:629`). The rev-list, cat-file and diff-tree calls all go through `gate_git` (`:1660-1696`). The usage regex is `^([0123456789abcdef]{40}|[0123456789abcdef]{64})$` (`:453`). Each class clause is checked in claims 20-27, and both tests pass at HEAD (p2.log).

**Evidence:** `scripts/build-loop.sh:450-453`, `scripts/build-loop.sh:629`, `scripts/build-loop.sh:1649-1717`; `.../u3b2-fcf-r3/p2.log`, `.../u3b2-fcf-r3/p4.log`

---

## Claim 20: "after --state's gate but its caller check"

**Location:** `scripts/build-loop.sh:138-141`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers state_gate, resolve_main, main_by_name and state_start running for main-log, with caller_gate skipped. It does not establish the order U4 calls modes in.

`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` / `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:631-632`), then `main-log) state_start` (`:1714-1715`).

**Evidence:** `scripts/build-loop.sh:629-634`, `scripts/build-loop.sh:1714-1717`

---

## Claim 21: "Prints main MAIN N ... oldest first ("-" before a refusal): gate|chore|answers|other SHA SUBJECT ... ("-" when empty, so "-" may also be the text "-")"

**Location:** `scripts/build-loop.sh:143-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line shapes, the count, the order and the empty subject. It does not establish behaviour for a commit whose first message line holds a CR (that line is printed as is, through scrub).

The code is `echo "main $MAIN_SHA $(wc -l < "$GATE_TMP/after")"`, then `log_class "$c"; echo "$CLASS $c $SUBJ"` over `tac "$GATE_TMP/after"` (`scripts/build-loop.sh:1698-1701`). Test 1 asserts the full output in order and test 2 asserts `other $E -` (p2 HEAD ok 1, ok 2).

**Evidence:** `scripts/build-loop.sh:1690-1703`, `test/scripts/build-loop-orchestrator.bats:180-190`, `:218`; `.../u3b2-fcf-r3/p2.log`

---

## Claim 22: "A two-parent commit is gate or chore only when its tree is the clean merge of its parents (merge-tree, which writes the merged objects as --check's does), as --merge and a git merge with git's defaults write it ...; an amended or hand-resolved merge is other."

**Location:** `scripts/build-loop.sh:150-155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers clean_merge's tree compare, a conflict's non-zero exit failing it, and the amended gate and amended chore cases. It does not establish equality with a git merge run under non-default rename settings (the header excludes those).

The function is `t="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" && [[ "$t" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]]` (`scripts/build-loop.sh:1646-1647`). merge-tree exits 1 on a conflict, so the assignment fails. The gate repository reads no global or system config (`export ... GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `:518`). Real `--merge` and `git merge --no-ff` results read gate and chore (test 1). Amended ones read other (test 2; mutant M1 killed).

**Evidence:** `scripts/build-loop.sh:518`, `scripts/build-loop.sh:1644-1648`; `.../u3b2-fcf-r3/p2.log`, `.../u3b2-fcf-r3/p3.log`

---

## Claim 23: "gate: two parents and the message --merge writes, byte for byte."

**Location:** `scripts/build-loop.sh:155-156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the self-merge and approved shapes, an extra line, a missing trailer and one parent. It does not establish messages over the 5 lines mapfile reads (cmp compares the whole file, so they fail).

The reader regenerates the message with `gate_msg "$b" "$x" "$p" "$q" > "$GATE_TMP/want" && cmp -s "$GATE_TMP/want" "$GATE_TMP/m"` (`scripts/build-loop.sh:1664`). The message is taken by `perl -0777 -ne 's/\A.*?\n\n//s and print'` (`:1655`). In test 2, a line more, one parent and a missing approved trailer each read other. In p4, the approved shape with `Build-loop-approved: Q-007` read gate.

**Evidence:** `scripts/build-loop.sh:1649-1664`, `test/scripts/build-loop-orchestrator.bats:195-206`; `.../u3b2-fcf-r3/p4.log`

---

## Claim 24: "chore: two parents, a subject "Merge branch 'B'" then the end, " into " or ":" (any other text after the quote is other), B being chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM ..., and a cycle record the merge adds or changes (docs/working/cycles/cycle-*.md, mode 100644) holding the line "Branch: B", anywhere in it (a trailing CR dropped)."

**Location:** `scripts/build-loop.sh:156-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause through p4 and test 2. It does not establish that DATE is a valid calendar date (only the digit shape is checked).

The subject regex and the record test are quoted in claim 9 (`scripts/build-loop.sh:1665`, `:1670-1672`). In p4, `chore 9372cd70 Merge branch 'chore/dev-cycle-2026-10-12' into main` came from an added CRLF record with the line inside a fence, and a tail `x` and mode 100755 each read other. In test 2, a record naming another branch, a branch outside the pattern, and an amended chore merge each read other.

**Evidence:** `scripts/build-loop.sh:1665-1673`; `.../u3b2-fcf-r3/p4.log`, `.../u3b2-fcf-r3/p2.log`

---

## Claim 25: "answers: one parent, and only docs/working/questions.md or questions-archive.md change, mode 100644 on both sides, in lines that are blank, answer lines (...) or header lines ("**Needs:**") whose Status field alone changed (in each hunk the removed and the added header lines, Status values set aside, match in order); at least one answer line added (any entry's ...)"

**Location:** `scripts/build-loop.sh:162-171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the raw-record gate, the per-hunk header compare and the labels. It does not establish anything about content beyond the line kinds (by design, F19).

The raw-record gate is `[[ "$meta" =~ ^:100644\ 100644\ [0123456789abcdef]+\ [0123456789abcdef]+\ M$ && ( "$p" == docs/working/questions.md || "$p" == docs/working/questions-archive.md ) ]] || return 0` (`scripts/build-loop.sh:1678`). The awk tests `substr(l, 1, 10) == "**Needs:**"`, with needs() replacing the field that starts `**Status:** ` (`:1615-1617`, `:1628`), and compares per hunk with `flush()` at each `@@` (`:1618-1620`). In p4, a lowercase `**answer (later):**` line read answers, and a `- Q-001: [1]` line with a Status flip read answers. A reordered header, an indented answer and a mode change each read other.

**Evidence:** `scripts/build-loop.sh:1612-1631`, `scripts/build-loop.sh:1674-1685`; `.../u3b2-fcf-r3/p4.log`

---

## Claim 26: "The class is read from the commit's own text (and commits before MAIN, and objects not in MAIN's tree, are not re-hashed)"

**Location:** `scripts/build-loop.sh:173-176`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers store_check's single `--main` call. It does not establish that the reads of history objects are safe from a same-uid writer (stated as not covered).

`store_check --main "$MAIN_SHA"` (`scripts/build-loop.sh:1224`) re-hashes MAIN, its tree and everything below it, per its comment ("Each REV (a commit or a tree), its root tree, and every tree and blob below it", `:948-950`). There is no other store_check in the mode (claim 11).

**Evidence:** `scripts/build-loop.sh:946-972`, `scripts/build-loop.sh:1220-1226`

---

## Claim 27: "or "main MAIN -" and refuse main-log: WHY, when SINCE (a full id; a short one is a usage error, exit 1) is not on that history ... or it cannot be listed."

**Location:** `scripts/build-loop.sh:177-180`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both refusal paths and the usage exit. It does not establish an uppercase hex id (usage refuses it, also exit 1).

The usage check is `[[ $# -eq 2 && "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage ...` (`scripts/build-loop.sh:453`); usage exits 1 (`:444`). The two refusals are at `:1693-1697`. The test asserts exit 1 and the usage text for `${X:0:12}` (`test/scripts/build-loop-orchestrator.bats:223`).

**Evidence:** `scripts/build-loop.sh:444-453`, `scripts/build-loop.sh:1690-1697`; `.../u3b2-fcf-r3/p2.log`

---

## Claim 28: "Writes nothing but --check's and --main-log's merge objects (merge-tree writes the merged trees and blobs into the object store), ... and its own temporary directory, removed at exit."

**Location:** `scripts/build-loop.sh:410-416`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers --main-log's writes: merge-tree's objects and GATE_TMP. It does not establish mtime freshening of an existing pack by merge-tree, which the i2 performance review reported and which this list does not name.

`GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT` (`scripts/build-loop.sh:1222`). The only object writer in the mode is clean_merge's `merge-tree --write-tree` (`:1646`); the other calls are `cat-file`, `diff-tree` and `rev-list` (`:1652-1694`). The cca66dc2 run wrote 87 loose objects on the clone and HEAD runs wrote 0 (claim 18a).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1644-1703`; `.../u3b2-fcf-r3/p1.log`

---

## Claim 29: Exit section: "0 ... for --main-log no other line ...; 2 ... --main-log's other or refuse line, or the state gate ... not ok ... 1 ... a failed mktemp (--state, --main-log, ...; no line printed)"

**Location:** `scripts/build-loop.sh:419-429`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0, exit 2 and the mktemp exit 1 path read from code. It does not establish exit codes under signals.

The mode arm runs `main_log "${ARGS[0]}" || exit 2` (`scripts/build-loop.sh:1716`). main_log returns `"$o"`, which is 1 once any line is other (`:1700-1702`). state_start's mktemp runs under `set -e` in a function not called in a condition (`:1222`), so a failure exits with mktemp's status, 1. The tests observe exits 0 and 2 (p2.log).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1690-1717`; `.../u3b2-fcf-r3/p2.log`

---

## Claim 30: gate_msg's comment: "the message of the merge --merge writes (land) and --main-log reads as gate, its one definition (row 662). ... log_class parses the fields back out by the same shape (subject, line 3, line 4) and compares bytes"

**Location:** `scripts/build-loop.sh:1368-1373`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two callers and the line indices. It does not establish the "old shape" clause, which is conditional on a future change.

The parser reads `m[2]` (`^Build-loop-gate: (.+)$`) and `m[3]` (`^Build-loop-approved: (Q-[0123456789]+)$`), lines 3 and 4 (`scripts/build-loop.sh:1660-1663`). Callers are at `:1461` and `:1664` only (grep `gate_msg "`).

**Evidence:** `scripts/build-loop.sh:1368-1377`, `scripts/build-loop.sh:1461`, `scripts/build-loop.sh:1657-1664`

---

## Claim 31: land's call `gate_msg ... "${2-}"` writes the same message as the removed inline printf

**Location:** `scripts/build-loop.sh:1461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the self-merge and approved callers. It does not establish a land called with a non-empty `$2` under self-merge (the merge arm never does this).

The old line was `[[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"`. The new gate_msg line is `[[ -z "${4-}" ]] || printf 'Build-loop-approved: %s\n' "$4"` (`scripts/build-loop.sh:1376`). The only caller is `land "$AUTH" "$APPROVED"`, where APPROVED is empty for self-merge (`:1738`, `:1746`). A real `--merge` reads gate in test 1.

**Evidence:** `scripts/build-loop.sh:1374-1377`, `scripts/build-loop.sh:1737-1749`; `.../u3b2-fcf-r3/p2.log`

---

## Claim 32: ANSWERS_AWK's comment: every changed line blank, answer or header; header lines matched per hunk with Status set aside; at least one answer added ("a Status flip or a deleted answer alone adds none"); "Any added answer label counts, in any entry and from anyone"; "The labels are --check-answer's (the lib's ANSWER_AWK, which points back here)"

**Location:** `scripts/build-loop.sh:1602-1610`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk at `:1612-1631` and the lib's labels. It does not establish that the lib's per-entry ID match (`id ":"`) is the same rule: ANSWERS_AWK accepts any `Q-` number.

The lib uses `line = $0; sub(/^- /, "", line)`, `index(line, id ":") == 1` and `low !~ /^\*\*answer(:|ed| \()/` (`scripts/lib/dev-cycle-read.sh:2055-2058`). These are the same labels, with the optional `- `, as `:1626-1627` here. Mutants M2, M3 and M6 were killed (claim 3).

**Evidence:** `scripts/build-loop.sh:1612-1631`, `scripts/lib/dev-cycle-read.sh:2005-2058`; `.../u3b2-fcf-r3/p3.log`

---

## Claim 33: log_class's comment: "C, its changes and the record it adds are read in the gate repository ...; any failed read makes C other. A gate or chore subject counts only when the commit's tree is the clean merge of its parents ... Checked after the subject, so other merges cost no merge-tree run"

**Location:** `scripts/build-loop.sh:1632-1640`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each read path (cat-file, perl, diff-tree, the blob read under pipefail, awk) leaving `CLASS=other`. It does not establish "the record it adds" as the whole rule: a changed record (status M) counts too, as the header says.

`CLASS=other; SUBJ=-` comes first, and every read ends `|| return 0` (`scripts/build-loop.sh:1651-1683`). The blob read is `gate_git cat-file blob ... | LC_ALL=C awk ... && { CLASS=chore; return 0; }` under pipefail (`:1671-1672`). On the clone, 421 non-matching merges ran no merge-tree at HEAD, so no objects were written (claim 6).

**Evidence:** `scripts/build-loop.sh:1649-1686`; `.../u3b2-fcf-r3/p1.log`

---

## Claim 34: clean_merge's comment: "merge-tree writes the merged trees and blobs into the object store, as --check's does (only a conflicting or hand-resolved merge adds new ones)."

**Location:** `scripts/build-loop.sh:1641-1643`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers when merge-tree's result is already in the store. It does not establish the full set of merges that add objects.

New objects appear whenever merge-tree's clean result is not already stored. That covers a conflict and a hand resolution. It also covers a merge made with `-s`/`-X`, merge config or merge attributes, or a merge whose original tree was replaced and later pruned. An amended merge usually adds none, because the pre-amend tree is still in the store (paraphrased — no quote available because this follows from git's write-if-absent object store, not from a line in this file). The header's own list (`:153-155`: "no -s or -X, no merge.* config, no merge attribute") is the precise set. A fuller version would read: "only a merge whose committed tree is not merge-tree's clean result (conflicting, hand-resolved, or made with other merge options) adds new ones".

**Evidence:** `scripts/build-loop.sh:1641-1648`, `scripts/build-loop.sh:150-155`

---

## Claim 35: main_log's comments: "Returns 1 when SINCE is refused or any commit is other." / "Main's commit first, even before a refusal" / "The commits above SINCE (rev-list lists newest first)."

**Location:** `scripts/build-loop.sh:1688-1695`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body through `return "$o"`. It does not establish what happens if `tac` fails (the loop then reads nothing and returns 0 with N lines promised; an untested edge).

The newest-first list is read up to SINCE by `'$0 == s { f = 1; exit } { print } END { exit !f }'` and reversed by `tac` (`scripts/build-loop.sh:1696`, `:1701`). The return is `[[ "$CLASS" != other ]] || o=1` ... `return "$o"` (`:1700-1702`).

**Evidence:** `scripts/build-loop.sh:1688-1703`; `.../u3b2-fcf-r3/p2.log`

---

## Claim 36: "build-loop.sh's ANSWERS_AWK (--main-log's answers class) copies these labels and the header line's Status field: change both together."

**Location:** `scripts/lib/dev-cycle-read.sh:2019-2020`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the labels and the Status-field test (`substr(f, 1, 12) == "**Status:** "` after trimming leading blanks) in both. It does not establish the lib's last-Status-wins rule, which ANSWERS_AWK has no need of.

Lib: `f = fld[i]; sub(/^[ \t]+/, "", f); if (substr(f, 1, 12) == "**Status:** ") v = substr(f, 13)` (`scripts/lib/dev-cycle-read.sh:2050`). Here: `t = f; sub(/^[ \t]+/, "", t); if (substr(t, 1, 12) == "**Status:** ") f = "**Status:**"` (`scripts/build-loop.sh:1615`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2019-2058`, `scripts/build-loop.sh:1612-1617`

---

## Claim 37: The test comments: ml, q, qs and chore helpers; "The gate message on two parents with their clean merge is gate; with a line more, on one parent, approved without its trailer, or over another tree ..., other"; "A chore merge whose record names another branch, a branch outside the pattern, or amended with another file; an empty commit (subject printed as -); ..."; "The Status flip first ... (a real diff each ...)"

**Location:** `test/scripts/build-loop-orchestrator.bats:162-216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each fixture doing what its comment names, and both tests passing at HEAD. It does not establish isolation of each near-miss: test 2 checks only that the class column is all `other`, so one near-miss turning gate would be caught, but the per-line mapping is not asserted.

`chore()` makes `docs/working/cycles/cycle-2026-10-12.md` and runs `git merge -q --no-ff` (`:168-169`). The over-another-tree tip uses `merge-tree main feat/x` after the slip but takes parents `main` and `$X` (`:200-201`). Test 2 asserts nine lines with `lines[4] = "other $E -"` and a single `other` class (`:218-219`). p2 HEAD: ok 1, ok 2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:162-224`; `.../u3b2-fcf-r3/p2.log`

---

## Claim 38: Commit 1d829fee message (gate, chore, answers, other; exit 2 on any other; gate_msg the one definition; gated, reads in the gate repository)

**Location:** `1d829fee` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message against 1d829fee's own code (test 1 passes there). It does not establish the later fixes, which the message does not claim.

`git show 1d829fee:scripts/build-loop.sh` passes HEAD's test 1 (p2.log: `ok 1`). It fails test 2 only on cases that the later fixes added (D1, D2).

**Evidence:** `.../u3b2-fcf-r3/p2.log`

---

## Claim 39: Commit cca66dc2 message (D1 clean-merge rule, D2 an added answer required, D4 main line first, D9 "-", text fixes; "a hand-resolved chore merge now reads as other")

**Location:** `cca66dc2` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour at cca66dc2 under HEAD's tests (both pass). It does not establish the Status-flip clause of D2 being pinned by a test at cca66dc2 (it was not; see claim 3).

cca66dc2's script passes HEAD's tests 1 and 2 (p2.log). Its output on the /workspace clone is byte-identical to HEAD's (claim 6).

**Evidence:** `.../u3b2-fcf-r3/p2.log`, `.../u3b2-fcf-r3/p5.log`

---

## Claim 40: Commit 4afdd68b message: "every near-miss commit is asserted non-empty" and "E4: merge-tree runs only once a gate or chore subject matches (clean_merge), saving ~1.5 s and every store write on this repo's history"

**Location:** `4afdd68b` (commit message)
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the ordering, the store writes (0 at HEAD against 87 at cca66dc2) and the measured saving. It does not establish timing on another machine.

"Every store write" holds: HEAD wrote 0 objects and cca66dc2 wrote 87 (p1.log, p5.log). Two parts are imprecise. First, the non-empty assertion covers only the four answers near-misses (`for i in 4 3 2 1`, `test/scripts/build-loop-orchestrator.bats:217`), and the empty-commit near-miss is empty on purpose; this is the same point as claim 5. Second, the saving measured here was 1.8-2.6 s (cca66dc2 9393, 9698 and 9913 ms against HEAD 7092-8113 ms, p5.log and session runs), more than "~1.5 s". Its direction is right.

**Evidence:** `scripts/build-loop.sh:1657-1667`, `test/scripts/build-loop-orchestrator.bats:217`; `.../u3b2-fcf-r3/p5.log`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 18a** (`docs/reviews/override-log.md:728`): "87 objects, 616 KiB over this repo's history" is cca66dc2's figure. At HEAD (4afdd68b, where the row was written) only gate- or chore-subject merges run merge-tree, and a root-SINCE run on a clone of main writes 0 objects. Reword to "only a gate- or chore-subject merge; none on this repo's history at HEAD (87 objects at cca66dc2)". This is text, not code.

### Mostly Accurate
- **Claim 5** (`docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:44`): "each near-miss commit asserted non-empty" covers only the four answers near-misses; the empty-commit near-miss is empty on purpose. This is text.
- **Claim 16a** (`docs/reviews/override-log.md:726`): "Every commit on this repo's main today reads other" is false for one commit: dfe4c0df ("answer Q-093 [1] and Q-094 [1]") reads answers. This is text.
- **Claim 34** (`scripts/build-loop.sh:1641-1643`): "only a conflicting or hand-resolved merge adds new ones" omits merges made with other merge options or config, which the header lists. This is a comment.
- **Claim 40** (`4afdd68b` commit message): it shares claim 5's "every near-miss" overreach, and the measured saving here was 1.8-2.6 s, not ~1.5 s. This is text.

### Unverifiable
- **Claim 18b** (`docs/reviews/override-log.md:728`): the ~5 s for a constructed rename-heavy merge was not reproduced. Verifying it needs the i2 performance review's 100,001-file, 5,000-rename fixture.

## Legibility target

Every claim above is written for a reader who has the diff open but not the review history. Each verdict names the file and line it rests on and quotes the deciding code or text. Each executed verdict names the probe log that a reader can open under the scratchpad path above. Behavioural against text: no claim on this branch is a behavioural mismatch. The one Stale and the four Mostly-accurate verdicts are all in prose (an override row, the rubric, a commit message and one code comment), and the code they describe behaves as the header, the plan note and the tests state.

## Goal-Alignment Note

Success criterion: "A code-fact-check replicate report saved at the given path in the worktree, per the code-fact-check skill." It is met: this report is at `docs/reviews/code-fact-check-report-2026-10-12-u3b2-final-r3.md` in the worktree, with first line `Commit: 4afdd68b`, the skill's header fields, the seven mandatory per-claim fields and the attention summary. The brief's six claim groups are covered: the --main-log header rules (claims 20-27), the Writes, Exit and mktemp text (28-29), the comments (30-36), the plan note and the 2026-10-12 rows (8-19), the rubric's Fixed claims tested on pre-fix code and mutants (1-7), and the three commit messages (38-40). The deviations are these. Claim 18b was left Unverifiable rather than rebuilding a 100k-file fixture. Probe logs live in the session scratchpad rather than `docs/reviews/execution-logs/`, because the brief allows writing only this report. Some `/tmp/u3b2rv-fcf-*` bats TMPDIRs from probes p2-p4 remain, because other replicates may share the `fcf` prefix and a glob delete could remove theirs. No worktree file other than this report was written, and no process started by this pass is still running.
