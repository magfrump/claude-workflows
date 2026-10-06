Commit: 83cdb005

# Code Fact-Check Report

**Commit:** 83cdb005
**Replication:** k=3
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u1d, branch feat/build-loop-u1d)
**Scope:** branch diff (Claims 26-29: Stage 2.5 submitted claims, k=1, from `code-fact-check-submitted-claims-build-loop-u1d.md`) `git diff main...HEAD` (one commit, 83cdb005): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, and the commit message. Merged by the orchestrator, most severe verdict wins, from `code-fact-check-report-build-loop-u1d-r{1,2,3}.md` (all `Commit: 83cdb005`). Evidence and logs are in each replicate's report and under `.../scratchpad/review-u1d/fc{1,2,3}/logs/`.
**Checked:** 2026-10-06
**Total claims checked:** 29
**Summary:** 18 verified, 9 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Merge notes: the claims are clustered at the finest granularity any replicate used. Where a replicate gave its verdict on a compound claim, it is recorded on each sub-claim row and marked `(compound)`. Every replicate ran the baseline (92/92) and probes on mutant copies. In scratch copies, test 4 (T3) fails only because the copy has no `docs/`. That failure is environmental.

---

## Claim 1: "Self-merge also needs a valid never line, so a never list hidden in markup, with no exact never line beside it, turns it off."

**Location:** `scripts/build-loop.sh:16-18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a never list hidden from the copy count (a task box, or inside a fence), with and without an exact line beside it, and one in letter-preserving markup (`**...**`, `- `), with and without an exact line. It does not establish markup shapes no replicate probed.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "an exact never line beside the list keeps self-merge on only when the copy count misses the hidden copy. A copy the count does see (`**Self-merge never:** a/`, `- Self-merge never: b/`) plus an exact line makes two copies, so the never line is malformed and self-merge stays off (fails closed; wording only)." · r2: suggested wording "a never list in markup turns it off, unless the markup hides it from the copy count and an exact never line stands beside it."

The executed probes (r2 `p12.sh`, r3, r1): `- [x] Self-merge never: a/` alone gives `never none` and review. With `Self-merge never: none` beside it, the result is `policy self-merge set`. `**Self-merge never:** a/` with an exact line beside it gives `never malformed: more than one line starts "Self-merge never:"`, and self-merge is off. The sentence implies the second case keeps self-merge on.

**Evidence:** `scripts/build-loop.sh:16-18`, `:150-157`, `:222-251`; r2 `$L/probe-p12.log`

---

## Claim 2: "A tip on a branch level with main, or whose subject does not start "handoff:", is working." (re-wrapped lines)

**Location:** `scripts/build-loop.sh:61-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 0-ahead tips with a `handoff:` subject (working) and non-handoff subjects. It does not establish the wording for a branch behind main, which is also 0 ahead and also reads working.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r2: "a branch behind main is also 0 ahead" (Scope note on its Claim 2) · r1: "A tip with 0 commits ahead (level with main or behind it) reads `working`"

**Evidence:** `scripts/build-loop.sh:61-63`, `:346-352`

---

## Claim 3: help skip list: "... names the same branch (ignoring case) or the open briefs on main could not be listed, or on a branch ahead of main the tip's subject ... starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:68-72`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "could not be listed" skip (open briefs only) and the ahead>0 gate on the marker skip. It also covers a done brief on a branch ahead of main, which hits the marker skip too.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r3: "the marker skip applies to done briefs too (probe: a done brief skipped). Joined to 'for an open brief, ...' by ', or', it can read as open-only." · r3 (outside the diff): "under a broken git config (`grep.patternType bogus`), check_branch's ahead count comes back empty, so a done brief on a branch one commit ahead printed `ok ... working` with an empty DATE instead of the marker skip."

**Evidence:** `scripts/build-loop.sh:68-72`, `:338`, `:346-352`; r2 `$L/probe-claim3.log`

---

## Claim 4: "# the header, to the first non-empty line not starting with #"

**Location:** `scripts/build-loop.sh:99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU sed's `2,/^[^#]/{/^#/p}`: an empty line does not end the range, and a whitespace-only line does. It does not establish a non-comment line 2, which cannot end the range; both scripts have a comment on line 2.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "a non-comment line 2 cannot end the range (range starts at 2, end regex checked from line 3); both scripts have a comment on line 2."

**Evidence:** `scripts/build-loop.sh:99`; r2 `$L/probe-p4.log`

---

## Claim 5: "whether the next line outside a fence after the first is blank or the end of the file (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:143-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fence skipping, space- or tab-only lines as blank, and end of file with or without a final newline.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "a line holding only `\v`, or a one-line `<!-- -->`, counts as non-blank" · r2: "a form feed counts as non-blank" · r3: "mutants M7a/M7b fail the test"

**Evidence:** `scripts/build-loop.sh:143-151`

---

## Claim 6: "Exit 1 is "none"; an exit above 1 fails closed (SHARED_BRANCHES=error: every open brief skips)."

**Location:** `scripts/build-loop.sh:307-308`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bad config, a bad revision and a corrupt object (exit 128) and no match (exit 1).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:307-311`

---

## Claim 7: "A brief git grep cannot read is not counted (row 293)."

**Location:** `scripts/build-loop.sh:309`
**Type:** Error-handling / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing blob (git grep warns, exits 0 or 1, and leaves the brief out) and a corrupt blob (exit 128, fail closed for every open brief).
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r2: "true only for a missing object; a corrupt one makes git grep exit 128, which fails closed for every open brief. Precise version: 'A brief whose object is missing (git grep warns and exits 0 or 1) is not counted (row 293).'" · r1+r3: "row 293's reasoning holds: the unreadable brief skips on its own --status line."

**Evidence:** `scripts/build-loop.sh:309-316`; `docs/reviews/override-log.md:293`; r2 `$L/probe-p5.log`

---

## Claim 8: commit: "--status' "could not be listed" skip drops "(git grep failed)", matching the other reasons (U1c C38)."

**Location:** `scripts/build-loop.sh:338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip text and the updated T28 assertion.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:338`; `test/scripts/build-loop-read.bats:388`

---

## Claim 9: "an answer only in the working tree is not seen: it reads what main's copy says until it lands there"

**Location:** `scripts/dev-cycle.sh:58-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer reading only `$MAIN_SHA`'s blobs; T34 asserts the working-tree, side-branch and merged cases.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-577`; `test/scripts/dev-cycle.bats:1164-1180`

---

## Claim 10: "# The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale)."

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the range end at `set -euo pipefail` (line 83), skipping the empty line 82.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/dev-cycle.sh:111-112`

---

## Claim 11: "The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves),"

**Location:** `scripts/lib/dev-cycle-read.sh:13-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `set -o pipefail` in the lib: only brief_fields (`:294`) and check_answer (`:550`). The list is complete.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/lib/dev-cycle-read.sh:294`, `:550`

---

## Claim 12: "It checks main_by_name and the path's form itself (pathform, so ls-tree prints it unquoted): either failing is error." (and the PR intent: no other behaviour change)

**Location:** `scripts/lib/dev-cycle-read.sh:257-263`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every caller: brief_fields and check_brief check pathform first, check_answer and main_file pass fixed names that pathform accepts, and dev-cycle.sh has no direct caller. No caller's output changes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "the comment's earlier list of `error` causes (`lib:252-255`) still names only three (no default branch, ls-tree failed, a duplicate name) and does not name pathform; the new sentence adds the fourth."

**Evidence:** `scripts/lib/dev-cycle-read.sh:248-276`, `:296`, `:327-334`, `:554`; `scripts/build-loop.sh:124`

---

## Claim 13: --settings U1d test: the exact glob-form and "twice" reasons, review with a malformed never line, the next-line rule, an absent file

**Location:** `test/scripts/build-loop-read.bats:402-419`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion matching exactly and the next-line mutants failing. The caller's-config half is Claim 14, and the unread-file slots case is Claim 24.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound verdict driven by the caller's-config comment (Claim 14)

**Evidence:** `test/scripts/build-loop-read.bats:402-419`; `scripts/build-loop.sh:205-258`

---

## Claim 14: "# A caller's own GIT_CONFIG_COUNT pairs stay, and the guard still applies after them." (commit: "a caller's own GIT_CONFIG_COUNT pairs with a replace ref")

**Location:** `test/scripts/build-loop-read.bats:420-425`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test failing with the guard pair removed or not counted (m4, M3, M4c), and passing when the caller's pair is overwritten (m4b, M4, `cfg=0`).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "'pairs stay' is not asserted: a mutant that hard-codes index 0 and overwrites the caller's pair passes the full suite. The code does keep the pairs (`cfg="${GIT_CONFIG_COUNT:-0}"`)." · r2: precise version "A caller's GIT_CONFIG_COUNT does not stop the guard."

**Evidence:** `test/scripts/build-loop-read.bats:420-425`; `scripts/build-loop.sh:108-113`; r2 `$L/mutant-m4b.log`

---

## Claim 15: test "build-loop.sh --help prints the whole header, through its last line (U1d)"

**Location:** `test/scripts/build-loop-read.bats:428-432`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers status 0 and the first and last lines. Interior lines are not asserted.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: "'the whole header': it checks only the first and last lines" · r2: "a range that skipped interior lines would still pass" · r3: "the --help test uses `--help`, not the `-h` row 246 named"

**Evidence:** `test/scripts/build-loop-read.bats:428-432`; `scripts/build-loop.sh:2`, `:79`

---

## Claim 16: test step "No open brief on main at all (git grep exits 1): a done brief reads normally" (title: "no open brief")

**Location:** `test/scripts/build-loop-read.bats:436-439`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted `ok` line. It does not establish that the exit-1 arm is tested: treating exit 1 as an error (`-gt 1` → `-ge 1`) survives the suite.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "a mutant treating exit 1 as an error passes, because done briefs never consult SHARED_BRANCHES" · r2: "unobservable through --status: with exit 1 there is no open brief on main to query"

**Evidence:** `test/scripts/build-loop-read.bats:436-439`; `scripts/build-loop.sh:310-311`, `:338`; r2 `$L/mutant-m8.log`

---

## Claim 17: test title "F31's open-only filter" and comment "A done brief sharing an open brief's branch does not make the open one skip." (offered for U1c C17/C18)

**Location:** `test/scripts/build-loop-read.bats:434`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the step exercises the loop's open-only filter (`scripts/build-loop.sh:315`). It does not dispute that the asserted output is correct.
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r2: "the done brief has no 'Status: open' line, so git grep never lists it and `:315` is never reached; mutant m7 (status term dropped) passes the whole suite. The filter is observable only for a brief whose first Status line is `Status: done` and a later line reads `Status: open`: real script prints ok, m7 skips o." · r1+r3: "two filters (git grep's regex and the loop's Status check); removing either alone survives, only removing both fails."

**Evidence:** `test/scripts/build-loop-read.bats:434-443`; `scripts/build-loop.sh:303-320`; r2 `$L/mutant-m7.log`, `$L/probe-m7-filter.log`

---

## Claim 18: "# Another open brief (CRLF line endings) on the same branch counts; the queried brief keeps its own Dispatched value whatever F31 read."

**Location:** `test/scripts/build-loop-read.bats:444-445`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the second clause at this step. The CRLF clause is Verified (Claim 19).
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Verified (compound)
**Replicate annotations:** r1+r2: "at this step o is skipped (no Dispatched field in a skip line) and p's Dispatched line was overwritten by the CRLF printf; the property is asserted only at `:454-457` (brief q). Mutant m1b passes `:448` and first fails at `:457`."

**Evidence:** `test/scripts/build-loop-read.bats:444-457`; r2 `$L/mutant-m1b.log`

---

## Claim 19: --status U1d test cases: CRLF counts, a directory containing "closed" is not closed/, BRIEF kept while F31 reads q, a NUL byte refuses the brief

**Location:** `test/scripts/build-loop-read.bats:444-461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case failing on its regression: m3 (CRLF) at `:448`, m2 (unanchored closed) at `:453`, m1b (BRIEF) at `:457`, m9 (NUL) at `:461`.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound verdict driven by Claims 16-18

**Evidence:** `test/scripts/build-loop-read.bats:444-461`; r2 `$L/mutant-m{1b,2,3,9}.log`

---

## Claim 20: test "--check-brief, --check-branch and --check-answer need a default branch found by name; the others do not" (loop extended to `--check-answer feat/x`)

**Location:** `test/scripts/dev-cycle.bats:813-823`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test failing (on exit status) when --check-answer is removed from dev-cycle.sh's gate. "The others do not" is asserted only for --check-path, which is pre-existing.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "without the gate the reason would be 'not a question ID', so check_answer's own default-branch check is never reached" · r1: "older test 66 already covered this"

**Evidence:** `test/scripts/dev-cycle.bats:813-823`; `scripts/dev-cycle.sh:193-194`; r2 `$L/mutant-m6.log`

---

## Claim 21: test title "main_entry refuses a path pathform refuses, before any read (U1d)"

**Location:** `test/scripts/dev-cycle.bats:1328-1335`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four `error` answers and the test failing with the guard removed (3 of 4 paths; `../x` already errors via ls-tree). "Before any read" is not asserted.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "a mutant running pathform after the ls-tree read passes" · r2: precise title "main_entry answers error for a path pathform refuses"

**Evidence:** `test/scripts/dev-cycle.bats:1328-1335`; `scripts/lib/dev-cycle-read.sh:263-265`; r2 `$L/mutant-m5b.log`

---

## Claim 22: commit: "Mutants that drop the local BRIEF (moving the call), or un-anchor the closed/ prefix, fail the new --status test."

**Location:** commit message 83cdb005
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both named mutants (they fail at `:457` and `:453`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "'(moving the call)' carries weight: dropping only the local BRIEF survives the full suite, because the existing call order already protects BRIEF" · r1+r2: "removing only the `#` anchor survives (equivalent on these inputs)"

**Evidence:** `scripts/build-loop.sh:303-328`; r2 `$L/mutant-m1a.log`, `$L/mutant-m1b.log`, `$L/mutant-m2.log`

---

## Claim 23: commit Notes: "118 changed code lines."

**Location:** commit message 83cdb005
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep step 1a's count (97 + 21, including test and comment lines).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `workflows/pr-prep.md:86-92`

---

## Claim 24: commit Tests bullet lists C26 (row 246's gaps) as resolved: "the slots line for an absent file"

**Location:** commit message 83cdb005
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absent half (asserted exactly) and the unread half (not asserted for slots anywhere). Row 246 also names `-h`, which the new --help test does not use.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "a mutant that changes the slots line for an unread file survives the whole suite" · r3: "the --help test uses `--help`, not `-h`"

**Evidence:** `test/scripts/build-loop-read.bats:48-62`, `:419`; `scripts/build-loop.sh:210-214`; `docs/reviews/override-log.md:246`

---

## Claim 25: commit Wording bullets: U1a A19-A22, C19; U1b A25-A27; U1c A24, A25, C37 land as worded

**Location:** commit message 83cdb005
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every deferred wording item landing. Two of them carry the imprecisions in Claims 1 and 3.
**Replicate verdicts:** r1=Verified · r2=— · r3=Mostly accurate
**Replicate annotations:** r3: "every deferred item lands, but two carry the problems in Claims 1 and 3"

**Evidence:** `scripts/build-loop.sh:17-18`, `:68-72`

---

## Submitted Claims

## Claim 26: "main_entry's new pathform guard leaves every current caller's output unchanged (brief_fields, check_brief, check_answer, build-loop.sh main_file)."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:263`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every non-test call site of main_entry at 83cdb005 (dev-cycle-read.sh:296, :334, :554; build-loop.sh:124 by way of main_file's two callers at :210 and :260) and the existing test call at dev-cycle.bats:1234. It does not establish anything about future callers that pass unvetted paths, such as U2's floor on changed paths, where the new guard does change the answer from absent to error.

The new guard is `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` (`scripts/lib/dev-cycle-read.sh:263`). It can change output only for a path that pathform refuses. Every caller either refuses such a path itself before calling, or passes a fixed name that pathform accepts:
- brief_fields: `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`scripts/lib/dev-cycle-read.sh:296`). The `||` short-circuits, so main_entry never sees a refused path.
- check_brief: `if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi` (`scripts/lib/dev-cycle-read.sh:327`) comes before `e="$(main_entry "$a")"` (`:334`). Read from the signature at :323 through the main_entry case at :335-341 and the brief_fields call at :342.
- check_answer: `for f in docs/working/questions.md docs/working/questions-archive.md; do e="$(main_entry "$f")"` (`scripts/lib/dev-cycle-read.sh:553-554`). These are fixed names.
- main_file: `e="$(main_entry "$f")"` (`scripts/build-loop.sh:124`), where f is `local f=docs/dev-cycle.md` (`:206`) or `f=docs/constraints.md` (`:259`). Again fixed names.

Execution shows pathform accepts all four fixed names. Command: `LC_ALL=C bash -c 'source base/scripts/lib/dev-cycle-read.sh; for p in ...; do pathform "$p" && echo "pass $p" || echo "FAIL $p"; done'`, cwd `$S`, exit 0, 2026-10-06T04:55:45Z. Output: `pass` for all four (`$S/pathform-fixed.log`). The grep for callers (`grep -rn -e main_file -e brief_fields -e main_entry scripts test`) finds no other call site, and dev-cycle.sh does not call main_entry directly. On the suites, the s1 variant (main's pre-U1d guard) and base fail the same tests apart from test 92, which is the new U1d test aimed at the guard itself. No caller-level assertion in either suite tells the two apart.

**Evidence:** `scripts/lib/dev-cycle-read.sh:260-275`, `scripts/lib/dev-cycle-read.sh:291-315`, `scripts/lib/dev-cycle-read.sh:323-342`, `scripts/lib/dev-cycle-read.sh:549-570`, `scripts/build-loop.sh:121-136`, `scripts/build-loop.sh:205-210`, `scripts/build-loop.sh:259-260`; logs `$S/pathform-fixed.log`, `$S/base.log`, `$S/s1.log`

---

## Claim 27: "the U1d dev-cycle.bats test 'main_entry refuses a path pathform refuses' fails when the guard is removed."

**Submitted by:** security-reviewer
**Location:** `test/scripts/dev-cycle.bats:1328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removing the pathform half of the guard (reverting to main's line). It does not establish that each of the four paths would catch the removal alone: `../x` still answers error without the guard, because ls-tree refuses it, so only the other three paths carry the test.

Mutant s1 replaces `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` with main's `main_by_name || { echo error; return; }`. Under it, test 92 fails at `test/scripts/dev-cycle.bats, line 1334` and prints `absent / error / absent / absent` for `"a\"b.md" "../x" "-x" "docs//x.md"` instead of four `error` lines (`$S/s1.log`). Command: the suite command in the setup note, cwd `$S/s1`, exit 1, 2026-10-06T04:54:56Z. The test asserts all four lines in one string comparison, `[ "$output" = "error\nerror\nerror\nerror" ]` (`test/scripts/dev-cycle.bats:1331-1334`), so any one path changing fails it. The base copy passes test 92.

**Evidence:** `test/scripts/dev-cycle.bats:1328-1335`, `scripts/lib/dev-cycle-read.sh:263`; logs `$S/s1.log`, `$S/base.log`

---

## Claim 28: "the U1d --settings test's GIT_CONFIG_COUNT step fails when build-loop.sh's replace-ref guard pair is lost."

**Submitted by:** security-reviewer
**Location:** `test/scripts/build-loop-read.bats:420-425`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three ways the pair at `scripts/build-loop.sh:112` could be lost: deleted, skipped when the caller sets a count, and exported without the count bump. The step fails at its own assertion (:425) in all three. It does not establish coverage of `GIT_NO_REPLACE_OBJECTS=1` (:113). Dropping that line alone fails no test, and with core.useReplaceRefs=true in the repo it does not protect anything without the pair.

The pair is `cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))` (`scripts/build-loop.sh:112`). The step sets up a replace ref with `git config core.useReplaceRefs true` and runs `env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller bash "$BL" --settings` (`test/scripts/build-loop-read.bats:423-424`). It then asserts `[[ "$(line policy)" == "policy review set:"* ]]` (`:425`). Results for the variants (suite command, cwd `$S/<variant>`, each exit 1, 2026-10-06T04:54:56Z):
- s3a (pair deleted): test 17 fails `in test file test/scripts/build-loop-read.bats, line 425` and prints `policy self-merge set: line 1 of docs/dev-cycle.md on the default branch`, which is the replacement blob. Test 5 also fails.
- s3b (pair added only when the caller set no count): only test 17 fails, at line 425, with the same output. The new step is the only test that catches this mutant.
- s3c (pair exported, count not bumped): test 17 fails at line 425. Test 5 also fails.
- s3d (control, `GIT_NO_REPLACE_OBJECTS=1` dropped): no test fails beyond env test 4.

**Evidence:** `test/scripts/build-loop-read.bats:420-425`, `scripts/build-loop.sh:107-114`; logs `$S/s3a.log`, `$S/s3b.log`, `$S/s3c.log`, `$S/s3d.log`

---

## Claim 29: "dropping brief_fields' own pathform check (`! pathform "$1" ||` at :296) changes no behaviour now that main_entry checks pathform. BRIEF_ODD, BRIEF contents and every output path checked, including whether anything between :296 and the main_entry call reads the path first."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers brief_fields' return code, BRIEF_ODD and BRIEF, and the two suites, for refused paths, an accepted brief and a missing default branch, while main_entry keeps its :263 guard. It does not establish that the redundancy stays harmless if main_entry's guard is later removed or weakened. brief_fields would then depend on main_entry alone.

brief_fields reads `local - out l; set -o pipefail` / `BRIEF=(); BRIEF_ODD=""` / `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`scripts/lib/dev-cycle-read.sh:294-296`). The function was read through its end at :315. Within this line, nothing reads `$1` before main_entry. The first read of `$1` after the check is `git cat-file blob "$MAIN_SHA:$1"` (`:299`), which runs only once the check has passed. In main_entry, `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` (`:263`) is the first statement after the locals. A refused path therefore yields `error`, and that is `!= blob`. The mutant takes the same branch and sets the same `BRIEF_ODD=error; return 1`, with BRIEF already emptied at :295. The only difference is the order of checks inside main_entry (main_by_name before pathform), and both failures produce the same `error`.

Executed probe: in a scratch repo `$S/probe` holding one brief, `brief_fields` ran on `"a\"b.md" "../x" "-x" "docs//x.md" ".git/HEAD"`, then on the real brief, then on `../x` with `MAIN_SHA=""`, against base and s4. Command: `LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ...' _ ../<variant>/scripts/lib/dev-cycle-read.sh`, cwd `$S/probe`, exit 0 for both, 2026-10-06T04:55:53Z. `diff` of the two outputs: IDENTICAL. Each refused path gives `rc=1 odd=[error] n=0`, the brief gives `rc=0 odd=[] n=2 status=[Status: open]`, and the no-main case gives `rc=1 odd=[error]` (`$S/s4probe-base.log`, `$S/s4probe-s4.log`). On the suites, s4 fails nothing beyond env test 4 (`$S/s4.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:260-275`, `scripts/lib/dev-cycle-read.sh:291-315`; logs `$S/s4probe-base.log`, `$S/s4probe-s4.log`, `$S/s4.log`

---

---

## Escalations

- `scripts/build-loop.sh` check_branch / status_line (outside the diff), raised by r3, addressee: security-reviewer. Under a broken git config (`grep.patternType bogus`), a done brief on a branch one commit ahead printed `ok ... working` with an empty DATE instead of the marker skip, because the ahead count came back empty. Is this fail-open?

## Claims Requiring Attention

### Incorrect
- **Claim 17** (`test/scripts/build-loop-read.bats:434`, `:440-443`): the "done brief sharing a branch" step never reaches F31's open-only filter (git grep already drops it). The mutant without the filter passes. C17/C18's gap stays open; it needs a brief whose first Status line is done and a later line reads `Status: open`.
- **Claim 18** (`test/scripts/build-loop-read.bats:444-445`): "the queried brief keeps its own Dispatched value" is not asserted at this step; it is asserted at `:454-457`.

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:17-18`): an exact line rescues self-merge only when the markup hides the copy from the count.
- **Claim 3** (`scripts/build-loop.sh:68-72`): the marker skip also applies to done briefs; ", or" reads as open-only.
- **Claim 7** (`scripts/build-loop.sh:309`): true for a missing object; a corrupt one exits 128 and fails closed.
- **Claim 14** (`test/scripts/build-loop-read.bats:420`): "pairs stay" is not asserted.
- **Claim 15** (`test/scripts/build-loop-read.bats:428`): "whole header" is first and last lines only.
- **Claim 16** (`test/scripts/build-loop-read.bats:436`): the exit-1 arm is unobservable through this step.
- **Claim 21** (`test/scripts/dev-cycle.bats:1328`): "before any read" is not asserted.
- **Claim 24** (commit): C26's unread-file slots case and `-h` remain untested.
- **Claim 25** (commit): see Claims 1 and 3.

## Verdict stability

- Clusters: 25. Claim 2 was surfaced by one replicate, so 24 can be compared.
- All reporting replicates agreed on 15 of 24: Claims 1, 4, 5, 6, 9, 10, 11, 12, 14, 20, 21, 22, 23, 24, and 8 (r1 and r3).
- They disagreed on 9 of 24:
  - Claim 3: V / V / MA
  - Claim 7: V(c) / MA / V(c)
  - Claim 13: MA(c) / V / V
  - Claim 15: MA / V / V
  - Claim 16: MA / V / MA
  - Claim 17: MA / **I** / MA
  - Claim 18: MA / **I** / V(c)
  - Claim 19: MA(c) / V / V
  - Claim 25: V / — / MA
- Agreement rate: 62.5%. Most disagreements are one replicate splitting a compound claim. The two Incorrect verdicts both come from r2 alone, and r1 and r3 rated the same defects Mostly accurate with the same mutant evidence. This is the severity flip §1.1 describes.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u1d-r<N>.md with a `Commit: 83cdb005` first line, structured per the code-fact-check skill.
- Answered: yes (merged from 3 of 3 replicates)
- Out of scope: none
- Escalate: r3's broken-config ahead-count observation (Escalations above), to security-reviewer
