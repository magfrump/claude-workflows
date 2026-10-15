Commit: 7d61c39b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q160 (claude-workflows, branch `fix/q160-iteration-cap`)
**Scope:** full branch diff `git diff main...HEAD` (merge base b279a2ba, HEAD 7d61c39b), 13 files, plus the commit messages of a94e01c7, 57f4c871, 7d61c39b. Final confirming pass, replicate r1 of k=3.
**Checked:** 2026-10-15
**Total claims checked:** 38
**Summary:** 27 verified, 7 mostly accurate, 3 stale, 0 incorrect, 1 unverifiable

Legibility target: a reviewer deciding whether to merge locally. Claims are ordered by file path, then line; commit-message claims come last (no file path).

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant pattern class is "count claimed in a commit or artifact that the files do not hold" (e.g. `docs/reviews/hallucination-patterns.md:28`, `:30`). Every count on this branch was recomputed (Claims 3, 7, 10, 30b, 32); none matches the pattern.

Shared execution provenance. Every `executed` claim below ran in cwd `/workspace/.claude/wt-q160`, at HEAD 7d61c39b, between 2026-10-15T00:40 and 00:48 -07:00. Per the orchestrator brief, the output is shown inline and no execution-log file was written. Counting helper used throughout (pr-prep step 1a's command, `workflows/pr-prep.md:91`):

```bash
cnt(){ git diff --numstat "$1"...$2 -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'; }
```

---

## Claim 1: Row 62's amendment and its replacement revisit trigger are in the Rationale column (commit 7d61c39b I6: "row 62's amendment moved to the Rationale column")

**Location:** `docs/decisions/log.md:85`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which pipe-delimited cell holds the `**Amended 2026-10-15**` text and the new revisit trigger. It does not establish that the column is literally named "Rationale": its header is "Context / Why".

Header, `docs/decisions/log.md:23`: `| # | Date | Decision | Context / Why | Full Record |`. Splitting row 85 on ` | ` (command: `awk -F' \\| ' 'NR==85{...}' docs/decisions/log.md`, exit 0) gives five fields. Field 3 (Decision) ends "`...both by user decision after the review loop, 2026-09-28.**`". Field 4 (Context / Why) starts "`User answer to Q-085 ([3])`" and ends "`...wo or more units need a waiver past the in-loop ~800 re-check within any 14 days.`". Field 5 is "`log 59, 61; ...; Q-085`". So the amendment and the trigger are both in field 4. This matches where the earlier amendments sit: row 60's "**Amended 2026-09-28 (Q-087 [2]):**" (`docs/decisions/log.md:83`) and row 63's "Revisit if..." are in the same column.

**Evidence:** `docs/decisions/log.md:23`, `docs/decisions/log.md:83`, `docs/decisions/log.md:85`

---

## Claim 2: "the /away reading (no exception, since [2] has none and [1] did)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the text of Q-104's options [1] and [2]. It does not establish what the user meant by [2]'s opening "Same as [1]". The row does label this "Q-160's reading", which softens it.

The Q-104 option table, `docs/working/questions-archive.md` (### Q-104, the table under the Evidence bullet):

```
| **[1] Re-check per iteration** | pr-prep re-measures the unit at each loop iteration. Past 400 lines, the loop stops and the growth is split into a stacked unit (in /away mode, automatically). | ...
| **[2] Re-check, waiver past 2×** | Same as [1], but growth up to ~800 lines is tolerated. Past that, the loop stops and asks you for a waiver. | ...
```

The textual premise holds: [2]'s own text has no /away clause, and [1]'s has "(in /away mode, automatically)". Two points need tightening:

- [1]'s parenthetical is an /away provision for the automatic split, not an "exception" to stopping.
- [2] opens "Same as [1], but", so whether [1]'s /away clause carries over is a matter of reading. The text does not settle it.

The row puts this in the "Q-160's reading" list, which is correct. But the parenthetical "since [2] has none" presents the reading as a textual fact. The same wording appears at `workflows/review-fix-loop.md:59` (Claim 24b).

**Evidence:** `docs/working/questions-archive.md:2008-2030` (### Q-104), `docs/decisions/log.md:85`

---

## Claim 3: "fired twice (Q-104: 396 to 1861 lines; Q-160: 102 to 842, 217 to 538)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four numbers, recomputed with step 1a's command from each merge's merge-base, and the two firing events. It does not establish that each figure is pure growth during review: see Claim 10 for the overstated cases this row leaves out.

Command (exit 0, 2026-10-15T00:43 -07:00):

```
for m in 581d41d8 73589cd7 dfa75374 626dc300; do p1=$(git rev-parse $m^1); p2=$(git rev-parse $m^2); mb=$(git merge-base $p1 $p2); first=$(git rev-list --reverse $mb..$p2 | head -1); echo "$m mb=${mb:0:8} first=${first:0:8} firstcount=$(cnt $mb $first) atmerge=$(cnt $mb $p2)"; done; echo dd: $(cnt 4225753a de530691) $(cnt 4225753a 5652d33f)
```

Output:

```
581d41d8 mb=f6fdda68 first=43b9edb6 firstcount=102 atmerge=842
73589cd7 mb=7afdb8d2 first=d861183d firstcount=157 atmerge=603
dfa75374 mb=e5d0f838 first=3e58eb9c firstcount=217 atmerge=538
626dc300 mb=4ab9a51f first=f2533b33 firstcount=392 atmerge=570
dd: 396 1861
```

The trigger fired twice:

- Q-104's text: "Decision log row 62's revisit trigger fired: a unit under the ~400-line cap grew during review."
- The 2026-10-14 cycle record (commit 63af3551): "log row 62: fired (second clause) ... → Q-160".

**Evidence:** `docs/decisions/log.md:85`, `docs/working/questions-archive.md:2008-2015`, `git show 63af3551` (cycle-2026-10-14.md line "log row 62: fired (second clause)")

---

## Claim 4: "past 800 the loop stops until the user answers a waiver entry (Q-104 [2])"; "Q-104 [2] gives the re-measure, the ~800 tolerance and the waiver"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution of the re-measure, the ~800 tolerance and the waiver to Q-104 [2]. It does not establish that "a waiver entry in questions.md" is the only form Q-104 allows: Q-104 says "asks you for a waiver" and does not name a medium.

From Q-104's answer line: "**Answered 2026-10-06: [2], re-check per iteration, waiver past 2×.** pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver." The same three elements appear at `workflows/review-fix-loop.md:65`, which correctly labels the remaining details Q-160's reading. None of those details (before merge, /away, precedence over splits, waiver limits, entry waivers, where the count is noted) appears in Q-104's text: paraphrased — no quote available because the claim covers absence of text in the Q-104 entry (read in full, `questions-archive.md:2008-2030`).

**Evidence:** `docs/working/questions-archive.md:2011`, `workflows/review-fix-loop.md:65`, `docs/decisions/log.md:85`

---

## Claim 5: Override row 1: "Commit a94e01c7's body calls Q-113 an entry-gate waiver ... and cites 157→603 and 392→570 as growth during review although feature commits came after each first commit (fact-check Claims 8, 22, Mostly accurate)"

**Location:** `docs/reviews/override-log.md:828`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's description of a94e01c7's body, the commit order in 73589cd7 and 626dc300, and the cited i1 verdicts. It does not establish that "Corrected in the fix commit" is a listed override verdict (Claim 6 covers that).

- a94e01c7's body: "units then grew during review (102 to 842, 157 to 603, 217 to 538, 392 to 570 code lines; Q-160)" and "Q-113 is an entry-gate waiver opened before Q-104 was answered".
- Commit order. `git log --reverse 73589cd7^1..73589cd7^2` starts with `d861183d test(build-loop-check): U2a4 floor ... (red)` and then `c934adbc feat(dev-cycle-read): the self-merge floor`. In 626dc300, `4be0445d feat(cc-push): ... (Q-089 unit A2)` follows the first commit `f2533b33`.
- i1 verdicts. The i1 report's Claims 8 and 22 are Mostly accurate: `grep '^\*\*Verdict:' docs/reviews/code-fact-check-report-q160-i1.md | sort | uniq -c` gives 5 Mostly accurate, and `code-fact-check-report-q160-i2.md:103` lists "Claim 8 Mostly accurate ... 22 Mostly accurate".
- The row says shipped text cites only the clean cases. `workflows/review-fix-loop.md:67` and row 62 cite only 102→842 and 217→538.

**Evidence:** `docs/reviews/override-log.md:828`, `git show a94e01c7`, `docs/reviews/code-fact-check-report-q160-i2.md:103`, `workflows/review-fix-loop.md:67`

---

## Claim 6: Override rows 2-4 (testability Weak, row 61 not amended, override-row conventions)

**Location:** `docs/reviews/override-log.md:829-831`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's citation and its factual premises. It does not establish whether the Won't-Fix judgments are sound (not a fact-check question).

- Row 829 cites the self-eval's testability rating. The self-eval has `| Testability investment | Weak |` (`docs/reviews/self-eval-review-fix-loop-2026-10-15-fix-q160-iteration-cap.md:18`).
- Row 830 cites i2 Claim 16. That claim exists (`code-fact-check-report-q160-i2.md:244`). Row 830 also says "the early split trigger's own text now links the exception", and `workflows/review-fix-loop.md:53` does: "unless the unit has grown past the [size re-check](#size-re-check-after-any-iteration-and-before-merge)'s ~800 lines".
- Row 831 says the file asks for new rows at the top. It does: `docs/reviews/override-log.md:72`, "Add new entries at the top so the most recent decisions are easiest to". Row 831 also says the 2026-10-14 rows sit at the bottom and one uses "Corrected in the fix commit". `docs/reviews/override-log.md:827` reads "`| 🟡 Must Address | Corrected in the fix commit |`".

**Evidence:** `docs/reviews/override-log.md:72`, `:825-831`, `docs/reviews/self-eval-review-fix-loop-2026-10-15-fix-q160-iteration-cap.md:18`, `docs/reviews/code-fact-check-report-q160-i2.md:244`

---

## Claim 7: Rubric figures: sizes 28 and 41, fact-check tallies 22 (15/5/1/1) and 18 (14/4), API 1 Inconsistent / 5 Minor / 2 Informational, diff ~33 KB, anchors updated "pr-prep x4, loop x2", override rows 144-145 and 479/486/488

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:8-70`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every number and line citation in the rubric. It does not establish the correctness of the triage judgments, or the "resolved / partly" statuses for prior findings.

Commands (exit 0, 00:44-00:46 -07:00), with output:

- `cnt main a94e01c7` → `28`; `cnt main 57f4c871` → `41`; `cnt main HEAD` → `50`.
- `grep '^\*\*Verdict:'` on the i1 report → `1 Incorrect, 5 Mostly accurate, 1 Stale, 15 Verified`. The header says "**Total claims checked:** 22".
- The same grep on the i2 report → `4 Mostly accurate, 14 Verified`. The header says 18.
- The API report's summary table (`api-consistency-review-2026-10-15-fix-q160-iteration-cap.md:186-193`) has F1 Inconsistent, F2-F6 Minor and F7-F8 Informational.
- `git diff main...a94e01c7 | wc -c` → `33356` (~33 KB).
- `rg -o '#size-re-check' workflows/` finds pr-prep.md at lines 96, 244, 274, 458 (4) and review-fix-loop.md at 53 and 84 (2).
- `sed -n {144,145,479,486,488}p docs/reviews/override-log.md`:
  - 144-145 are the `review/q085` rows on excluding `docs/` and counting deletions.
  - 479 reads "381 code lines at pr-prep step 1a and 443 after iteration 1".
  - 486 reads "540 ... (381 at step 1a, 443 after iteration 1, 471 after iteration 2)".
  - 488 reads "599 ... (540 at Q-131)".

  This matches the rubric's "381→443→540→599".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:8,12,47-48,52`, `docs/reviews/override-log.md:144-145,479,486,488`, `docs/reviews/api-consistency-review-2026-10-15-fix-q160-iteration-cap.md:186-193`

---

## Claim 8: "**Source:** Q-160 (dev cycle 2026-10-14)" (also the "(Q-160)" citations at `workflows/review-fix-loop.md:65,67` and in row 62)

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:3`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether a reader of `main` after the merge can find the Q-160 entry. It does not establish when the cycle branch that holds Q-160 will merge.

Q-160 exists, and its text matches what the branch says of it: "units grew during review from 102 to 842 code lines (581d41d8), 157 to 603 (73589cd7), 217 to 538 (dfa75374) and 392 to 570 (626dc300). Write Q-104 [2] into the process" (from `git show 63af3551`, `docs/working/questions.md` hunk "### Q-160 · implement-q104-per-iteration-cap"). But it is not on main or on this branch:

- `git grep -n 'Q-160' main -- . ':!docs/reviews'` → no output.
- `git branch -a --contains 63af3551` → `chore/dev-cycle-2026-10-15-0357`, `merge/build-loop-u5-resolved`, `merge/u5-and-q145`.

A shipped workflow doc (`workflows/review-fix-loop.md:65,67`) and decision log row 62 would therefore cite an entry that does not resolve on main until the cycle branch lands. Precise form: Q-160 is in the 2026-10-14 cycle commit 63af3551, not yet merged to main.

**Evidence:** `git show 63af3551` (questions.md "### Q-160"), `docs/working/plan-2026-10-15-q160-size-recheck.md:3`, `workflows/review-fix-loop.md:65,67`, `docs/decisions/log.md:85`

---

## Claim 9: "The rule to write in. Q-104 (questions-archive, answered 2026-10-06, [2]): 'pr-prep re-measures ... for the next cycle's roadmap'" (quoted text)

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote and the date. It does not establish anything beyond the answer line (the option table is checked in Claim 2).

The plan's quote ends at "amendment to log row 62." and the archive continues ", for the next cycle's roadmap". So the quote is a faithful, truncated prefix of the archive line `questions-archive.md:2011`: "pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver. Follow-up: a pr-prep / review-fix-loop change plus an amendment to log row 62, for the next cycle's roadmap." The date "Answered 2026-10-06: [2]" matches.

**Evidence:** `docs/working/questions-archive.md:2011`, `docs/working/plan-2026-10-15-q160-size-recheck.md:7`

---

## Claim 10: The plan's growth table (102/842, 157/603, 217/538, 392/570, first commits 43b9edb6, d861183d, 3e58eb9c, f2533b33) and "73589cd7's and 626dc300's first commits are not the whole unit"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:11-18`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell and the caveat. It does not establish that the 581d41d8 and dfa75374 growth was all review fixes: 581d41d8 includes `be94c871 feat(...)` after its iteration-4 escalate, and 3e58eb9c is a rebase commit.

The Claim 3 command output reproduces every cell, including the first-commit SHAs. The caveat holds because U2a4's first commit is the red test `d861183d` and the feature `c934adbc` follows it, and Q-089's A2 feature `4be0445d` follows A1's `f2533b33`. These are the `git log --reverse <m>^1..<m>^2` listings, run at 00:43, exit 0.

**Evidence:** `docs/working/plan-2026-10-15-q160-size-recheck.md:11-18`, Claim 3 output

---

## Claim 11: Interim practice: "Q-120 [1] (U2a3b at 794) cited 'Q-104 [2]'s ~800' ...; merge-msg records 841 lines under that waiver. Q-131 (U2a4, 540) asked for a waiver 'against the 400 cap' ... Q-113 (U1b, 417 ...) and Q-114 (U1c, 426) were opened 2026-10-05, before Q-104 was answered (10-06)"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:20`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each quoted entry and count. It does not establish the plan's interpretive conclusion that "the rule was read inconsistently".

Each figure checks against its source:

- Q-120: "the unit sits at 794 changed code lines" and "The waiver lets U2a3b pass Q-104 [2]'s ~800 lines". The command `cnt f6fdda68 aa379ee9` → `794`.
- Merge message: `docs/working/merge-msg-build-loop-u2a3b.md:28` reads "**Size:** 841 changed code lines against main, ... under the user's waiver (Q-120 [1])". The command `cnt f6fdda68 c4b34dcf` → `841`. The merged tip is 842 after a later shellcheck commit `13bc0a7d`.
- Q-131: "the unit is 540 code lines against the 400 cap".
- Q-113: "**Opened:** 2026-10-05", "~417 changed code lines after the Q-112 fixes".
- Q-114: "**Opened:** 2026-10-05", "426 changed code lines after its review fixes".

**Evidence:** `docs/working/questions-archive.md` (### Q-113, Q-114, Q-120, Q-131), `docs/working/merge-msg-build-loop-u2a3b.md:28`

---

## Claim 12: "`skills/dev-cycle/SKILL.md:701` names 'log row 62' only as a template example"; "Tests that pin this text: none found that grep pr-prep's size gate, review-fix-loop's sections or chat-synthesis rule 2"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:24-28`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the line reference and the absence of any test that greps the specific rule text. It does not establish that tests reading the files generically still pass for reasons other than those run in Claim 29.

`skills/dev-cycle/SKILL.md:701` reads "`- log row 62: cannot tell — <what would tell>`". `rg -n 'split PR|Size re-check|size gate|Early split' test` gives no output (exit 1, no match).

**Evidence:** `skills/dev-cycle/SKILL.md:701`, rg output above

---

## Claim 13: Plan step 1: "new `### Size re-check (after any iteration)` ... record the count in the iteration's review artifact"; "same `BASE`"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:36`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan's description of the section as shipped. It does not establish that a stale plan matters for the merge, since it is a working doc.

The shipped heading is `### Size re-check (after any iteration and before merge)` (`workflows/review-fix-loop.md:55`). The count now goes in commit bodies: "Note each count in the body of the commit that follows it (`Size: <count> code lines against <BASE>`)" (`workflows/review-fix-loop.md:57`). BASE is "set as in step 1a", not "the same". The plan predates iterations 1 and 2 (I1, I5, C6) and was not updated.

**Evidence:** `docs/working/plan-2026-10-15-q160-size-recheck.md:36`, `workflows/review-fix-loop.md:55,57`

---

## Claim 14: Completion-signals and quick-ref restatements match the owner

**Location:** `guides/completion-signals.md:82`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement on threshold (800), units (code lines outside `docs/`), the /away stop and the waiver citation. It does not establish that the guides mention the waiver-set limit, which they leave to the owner.

- `guides/completion-signals.md:82`: "Did it stay within the review-fix loop's size re-check (≤ 800 changed code lines outside `docs/` after review fixes), or does the description cite the user's waiver by its `Q-NNN` entry?"
- `guides/pr-prep-quick-ref.md:53`: "after each iteration and before merge, re-run step 1a's count: growth to 800 lines is tolerated; past it, stop and ask the user for a waiver (a `Q-NNN` entry), in /away mode too".

Both match `workflows/review-fix-loop.md:57-59` ("fires above 800"; "This holds in /away mode too").

**Evidence:** `guides/completion-signals.md:82`, `guides/pr-prep-quick-ref.md:53`, `workflows/review-fix-loop.md:57-59`

---

## Claim 15: Rule 2: "On the unit's first review (no rubric for the branch yet, or only a closed one: the first-pass test code-review's SKILL.md uses for the short-circuit)"

**Location:** `skills/code-review/references/chat-synthesis.md:140-142`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the correspondence with SKILL.md's short-circuit mechanic 6. It does not establish the rule's behaviour on standalone (non-loop) reviews of a branch with an open rubric.

SKILL.md's test, `skills/code-review/SKILL.md:739-741`: "If no canonical rubric exists yet, or the newest one is closed (`Loop closed at`; the first pass of a loop), there is no marker, so the short-circuit is allowed. If rubrics for this branch exist but none has the canonical name, or HEAD is detached, the loop's history cannot be read, so do not short-circuit." Rule 2's paraphrase differs from this in three small ways:

1. SKILL.md says "no **canonical** rubric" and "the **newest** one is closed". Rule 2 says "no rubric" and "only a closed one", which can be read as requiring that every rubric be closed.
2. SKILL.md has a third case, non-canonical rubrics only (history unreadable). Rule 2 says nothing about it.
3. Rule 2's inputs are "the rubric the synthesis just produced" (`chat-synthesis.md:137`). So "no rubric for the branch yet" has to mean "before this pass", and the rule does not say so.

The mechanism and conclusion are right: the first pass of a loop is the case SKILL.md picks out. Precise form: "no canonical rubric existed before this pass, or the newest one is closed (`Loop closed at`)".

**Evidence:** `skills/code-review/references/chat-synthesis.md:137-152`, `skills/code-review/SKILL.md:111-131`, `skills/code-review/SKILL.md:734-744`

---

## Claim 16: Rule 2: "Rule 2 does not apply on later passes ... No next action here, `merge` included, overrides that stop"; worked example "1 🔴 in security, 800-line diff, first review → rule 2"

**Location:** `skills/code-review/references/chat-synthesis.md:146-151,184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the consistency of rule 2 and its worked example with the five-action ladder and the loop's stop. It does not establish that any tool enforces the "no next action overrides" sentence (nothing mechanical reads it).

The ladder evaluates "top-to-bottom; the first matching rule wins" (`chat-synthesis.md:137`). On a later pass, rule 2 drops out, rules 3-5 derive the line, and the added sentence subordinates even rule 5's `merge` to `review-fix-loop.md:59`'s "no further fix commits, drift check, re-review or merge until the user answers a waiver entry". Rule 2 still requires "over the size gate ... (>400 ...)" with a 🔴, so 800 lines on a first review → rule 2 → `split PR`. That makes the example consistent, and it also matches the iteration-1 R1 fix.

**Evidence:** `skills/code-review/references/chat-synthesis.md:137-161,184`, `workflows/review-fix-loop.md:59`

---

## Claim 17: Step 1a: "This gate checks the unit once, at entry; the review-fix loop re-runs the same count after each iteration and before merge, and tolerates growth to ~800 lines"

**Location:** `workflows/pr-prep.md:96`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hand-off between step 1a and the loop owner. It does not establish what "before merge" means on the GitHub path (Claim 21).

The owner says "Re-run step 1a's command after each iteration's fix commits and tests (pr-prep 3c), ... and once more at pr-prep 6c" (`workflows/review-fix-loop.md:57`). The link target `review-fix-loop.md#size-re-check-after-any-iteration-and-before-merge` is the GitHub slug of `### Size re-check (after any iteration and before merge)` (`:55`).

**Evidence:** `workflows/pr-prep.md:96`, `workflows/review-fix-loop.md:55-57`

---

## Claim 18: 3c: "After the tests, before the drift check below and the re-review, re-run step 1a's count. Past ~800 lines, stop"

**Location:** `workflows/pr-prep.md:244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering against 3c's tests, the drift-check paragraph and 3d. It does not establish the order against the early split trigger, which the owner places "after triaging any iteration" (earlier, at 3b).

The order holds in the file. 3c's tests come first (`pr-prep.md:242`). Then the size re-check (`:244`). Then "**Fix-commit drift check** ... After fixes and tests, before the re-review pass" (`:246`). Then "**d. Re-review.**" (`:254`). The owner agrees: "before the fix-commit drift check" (`review-fix-loop.md:57`), and past 800 "no further ... drift check" (`:59`).

**Evidence:** `workflows/pr-prep.md:242-254`, `workflows/review-fix-loop.md:57-59`

---

## Claim 19: 3e: "the early split trigger and the size re-check (both checked after every iteration; the size re-check again before merge), ... are owned by review-fix-loop.md § Hard cap"

**Location:** `workflows/pr-prep.md:274`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownership and placement. It does not establish link resolution beyond the slugs (Claim 29).

`### Size re-check` (`review-fix-loop.md:55`) sits under `## Hard cap (3 iterations)` (`:24`), between the early split trigger (`:49`) and the iteration-4 gate (`:69`). The heading list from `grep -n '^#' workflows/review-fix-loop.md` confirms this.

**Evidence:** `workflows/pr-prep.md:274`, `workflows/review-fix-loop.md:24,49,55,69`

---

## Claim 20: Step 3 completion criterion: "The size re-check ran after each iteration and before merge: the unit is at most 800 ... (`BASE` as in step 1a), OR the user waived it and the PR description records the waiver with its `Q-NNN` entry and the limit it grants"

**Location:** `workflows/pr-prep.md:287`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the timing of the criterion against where the before-merge run happens. It does not establish whether reviewers will read the criterion as forward-looking.

The owner puts the before-merge run at step 6c: "once more at pr-prep 6c, before the description is published (on the local-merge path, before the merge)" (`review-fix-loop.md:57`). Step 6c's text agrees (`pr-prep.md:458`, "First, run the size re-check one last time"). Step 3's criteria are checked at the end of Phase 1, before Phase 2 (`pr-prep.md:294`) and before step 6. So the "and before merge" half cannot be satisfied when step 3's checklist is completed. Step 6c's own criterion (`pr-prep.md:467`) is the one that covers it. The BASE wording matches step 1a (I9 resolved). The waiver record asks for less than the owner, which also requires "the user's answer quoted verbatim and saying whether it waives the entry gate or this re-check" (`review-fix-loop.md:61`). Precise form: "ran after each iteration (the before-merge run is step 6c's criterion)".

**Evidence:** `workflows/pr-prep.md:287,294,458,467`, `workflows/review-fix-loop.md:57,61`

---

## Claim 21: "before merge" as the name of the last re-check point (heading "Size re-check (after any iteration and before merge)"; pr-prep 1a, 3e, step 3 criterion; quick-ref; row 62)

**Location:** `workflows/review-fix-loop.md:55`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the GitHub-PR delivery path. On the local-merge path "before merge" is exact. It does not establish whether post-publish changes on the PR path are meant to be re-checked.

The section body is exact: "once more at pr-prep 6c, before the description is published (on the local-merge path, before the merge)" (`review-fix-loop.md:57`). On the GitHub path, 6c is "marking the draft PR ready for review, opening the PR if no draft was made" (`pr-prep.md:458`). Merging then happens later, after outside review (`pr-prep.md:29`, "push, open a draft PR, and publish the description on the PR"). Commits pushed between publishing and merging are not re-checked by any stated point. The heading and the cross-references (`pr-prep.md:96`, `:274`, `:287`, `guides/pr-prep-quick-ref.md:53`, `docs/decisions/log.md:85`) call this point "before merge". Precise form: "before the description is published (local path: before the merge)".

**Evidence:** `workflows/review-fix-loop.md:55,57`, `workflows/pr-prep.md:22-31,458`

---

## Claim 22: Early split trigger and iteration-4 gate: /away splits apply "unless the unit has grown past the size re-check's ~800 lines"

**Location:** `workflows/review-fix-loop.md:53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency between `:53`, `:84` and the precedence paragraph `:63`. It does not establish the /active-mode path, which `:53` leaves as "propose the split and wait" in both cases.

Three passages agree:

- `:53`: "In /away mode and autonomous loops, split without asking, unless the unit has grown past the [size re-check]'s ~800 lines, where the user decides."
- `:84`: "`split` is the default when the unit has separable parts and has not grown past the [size re-check]'s ~800 lines".
- `:63`: "When the unit has grown past 800 during review, the agent does not split on its own ...: not by the early split trigger, and not by the iteration-4 gate's /away default `split`."

All three scope the exception to growth (the I11 fix).

**Evidence:** `workflows/review-fix-loop.md:53,63,84`

---

## Claim 23: "`BASE` is set as in step 1a: the branch directly below this unit, or `main` once that branch has merged"

**Location:** `workflows/review-fix-loop.md:57`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 1a's BASE rule. It does not establish validation of BASE: step 1a says none is done.

Step 1a: "`BASE=main   # a stacked unit whose lower unit has not merged yet: that unit's branch, the one directly below`" (`pr-prep.md:89`) and "set it to the branch directly below this unit (or `main`)" (`:94`). Same rule.

**Evidence:** `workflows/pr-prep.md:89,94`, `workflows/review-fix-loop.md:57`

---

## Claim 24a: "Q-104 [2] says the loop 'asks you for a waiver'"

**Location:** `workflows/review-fix-loop.md:59`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted words. It does not establish the /away inference that follows (Claim 24b).

Q-104's option [2] row reads: "Past that, the loop stops and asks you for a waiver."

**Evidence:** `docs/working/questions-archive.md` (### Q-104, option [2] row)

---

## Claim 24b: "and, unlike its option [1], makes no /away exception (decision log 62)"

**Location:** `workflows/review-fix-loop.md:59`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same as Claim 2. It does not establish the user's intent for "Same as [1]".

Same text and finding as Claim 2. [1]'s "(in /away mode, automatically)" is an /away provision for the split, and [2] begins "Same as [1], but". `:65` correctly lists "/away mode" among Q-160's readings, but this sentence attributes the absence to Q-104 [2] as a fact.

**Evidence:** `docs/working/questions-archive.md` (### Q-104 table), `workflows/review-fix-loop.md:59,65`

---

## Claim 25: "Record it as step 1a records its waiver, in the PR description (the merge commit message on the local-merge path), citing the `Q-NNN` entry with the user's answer quoted verbatim"

**Location:** `workflows/review-fix-loop.md:61`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 1a's waiver-recording rule. It does not establish the extra requirements this sentence adds (which gate is waived, the limit), which step 1a does not have.

Step 1a reads: "If the user waives the cap, note the waiver in the PR description (step 6), citing by ID the answered `Q-NNN` entry ... with the user's answer quoted verbatim" (`pr-prep.md:101`). The local-path reading comes from "Read 'PR description' as 'merge commit message' everywhere in this doc" (`pr-prep.md:24`).

**Evidence:** `workflows/pr-prep.md:24,101`, `workflows/review-fix-loop.md:61`

---

## Claim 26: "(A unit already past 800 at entry falls under step 1a, which splits it in /away mode.)"

**Location:** `workflows/review-fix-loop.md:63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers step 1a's /away behaviour above 400, which includes above 800. It does not establish behaviour when step 1a's waiver was already granted.

Step 1a reads: "The gate fires above 400 ... In /away mode, split without asking" (`pr-prep.md:96`).

**Evidence:** `workflows/pr-prep.md:96`

---

## Claim 27: "Q-104 [2] gives the re-measure, the ~800 tolerance and the waiver. The other details here are Q-160's reading of it"

**Location:** `workflows/review-fix-loop.md:65`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the split of attribution against the full Q-104 entry. It does not establish that Q-160's own entry endorses those readings: it asks only for "re-measures ... after each iteration, tolerates up to ~800 lines, and stops for a waiver past that".

See Claim 4. The listed Q-160 readings ("the before-merge point, /away mode, precedence over splits, waiver limits, entry waivers, and where the count is noted") are absent from Q-104's text: paraphrased — no quote available because the claim covers absence of text in the entry, read in full. The commit bodies record the same choices as agent choices: 7d61c39b's "Notes: the waiver-limit rule ... and moving the count from the rubric to commit bodies are agent choices not in Q-104's text".

**Evidence:** `docs/working/questions-archive.md:2008-2030`, `workflows/review-fix-loop.md:65`, `git show 7d61c39b`

---

## Claim 28: "`feat/dev-cycle-digest` went from 396 to 1861 lines over 37 passes (Q-104); U2a3b went from 102 to 842 and U2a3c from 217 to 538 (Q-160)"

**Location:** `workflows/review-fix-loop.md:67`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the numbers and the pass count. It does not establish that all of U2a3b's growth was fix churn: it includes a post-escalate feature commit `be94c871` (Claim 10).

The Claim 3 output gives `dd: 396 1861` and the 102/842 and 217/538 lines. Q-104 reads: "It landed at 1861 (5652d33f) after 37 review passes (pass 38 reviewed the merged result)". 581d41d8 is the U2a3b merge and dfa75374 is the U2a3c merge, per their branch commit subjects ("(U2a3b)", "U2a3c").

**Evidence:** `docs/working/questions-archive.md:2015`, Claim 3 output

---

## Claim 29: All anchors in changed lines resolve; the pinning suites pass

**Location:** `workflows/pr-prep.md:96,244,274,458`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `#size-re-check-after-any-iteration-and-before-merge`, `#early-split-trigger-after-any-iteration`, `#hard-cap-3-iterations` and `#1-gate-checks`, plus the three suites the plan names. It does not establish that the full test gate passes.

Command 1: `rg -n 'size-re-check' --glob '!docs/reviews/**' . | grep -v 'size-re-check-after-any-iteration-and-before-merge'` → no output. No stale anchor remains outside review artifacts. The slugs follow from the headings `### Size re-check (after any iteration and before merge)`, `### Early split trigger (after any iteration)`, `## Hard cap (3 iterations)` and `#### 1. Gate checks`.

Command 2: `timeout 300 bats test/cross-reference-integrity.bats test/workflow-required-sections.bats test/skills/code-review-assurance-contract.bats >/dev/null 2>&1; echo exit=$?`, run at 2026-10-15T00:44:58-07:00 → `exit=0`. The TAP plan line is `1..26`, and the output has no `not ok` lines; its last line is `ok 26 Accepted-immutable is a valid override verdict and is marked machine-written`.

**Evidence:** `workflows/review-fix-loop.md:24,49,55`, `workflows/pr-prep.md:82`, command output above

---

## Claim 30a: a94e01c7 body: "code-review chat-synthesis rule 2 (split PR: >400 on the first review, >800 on a later pass)"; "re-run step 1a's count with the same BASE"; "the count is recorded in each iteration's review artifact"

**Location:** commit a94e01c7 message
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit body against HEAD. It was accurate for a94e01c7's own tree (`git show a94e01c7:skills/code-review/references/chat-synthesis.md` rule 2: ">400 on its first review (step 1a's gate), or >800 on a later pass"). It does not establish that the override log should carry these points: only the Q-113 and growth points have a row (`override-log.md:828`).

All three statements no longer match HEAD. Rule 2 now applies on the first review only (`chat-synthesis.md:140-148`). BASE is "set as in step 1a" (`review-fix-loop.md:57`). The count goes in commit bodies (`:57`). The branch merges with its history, so this body will describe superseded behaviour. Later commits 57f4c871 (R1, C6) and 7d61c39b (I1) record each change.

**Evidence:** `git show a94e01c7`, `skills/code-review/references/chat-synthesis.md:140-148`, `workflows/review-fix-loop.md:57`

---

## Claim 30b: a94e01c7 body: "the re-check also runs before merge (the 842 case grew at confirming-pass fixes)"

**Location:** commit a94e01c7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when U2a3b crossed 800. It does not establish whether a per-iteration check alone would have caught it.

Command (00:44, exit 0): `for c in aa379ee9 4828727d 10f9b6e9 c4b34dcf 922c6bd4 13bc0a7d; do echo $c $(cnt f6fdda68 $c); done` → `aa379ee9 794`, `4828727d 794`, `10f9b6e9 794`, `c4b34dcf 841`, `922c6bd4 841`, `13bc0a7d 842`. The crossing commit is `c4b34dcf fix(dev-cycle-read): ... confirming-pass tests and wording (U2a3b loop 2, pending the user)`.

**Evidence:** command output above, `git log --reverse 581d41d8^1..581d41d8^2`

---

## Claim 30c: a94e01c7 body: "units then grew during review (102 to 842, 157 to 603, 217 to 538, 392 to 570 ...)"; "Q-113 is an entry-gate waiver"

**Location:** commit a94e01c7 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures (all reproduce, Claim 3) and their framing. It does not repeat the override row's handling (Claim 5).

The numbers reproduce exactly, but 157→603 and 392→570 include feature commits after the first commit (Claim 10). Q-113 was a waiver after review fixes ("~417 changed code lines after the Q-112 fixes"), not an entry-gate waiver. Both points are already logged at `docs/reviews/override-log.md:828` and corrected in the plan (`plan-...:18,20`).

**Evidence:** Claim 3 output, `docs/working/questions-archive.md` (### Q-113), `docs/reviews/override-log.md:828`

---

## Claim 31a: 57f4c871 body: R1, A1, A2, A3 descriptions (rule 2 first review only; stop takes precedence over the agent's splits; 3c and 6c mark the re-check points; Q-104 [2] vs Q-160 reading labelled)

**Location:** commit 57f4c871 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four fix descriptions against HEAD. It does not establish the C5/C6 lines (Claim 31b).

Each fix is at HEAD:

- R1: `chat-synthesis.md:146-151`.
- A1: `review-fix-loop.md:63`.
- A2: `pr-prep.md:244` and `:458`.
- A3: `review-fix-loop.md:65` and `log.md:85`, "are Q-160's reading".

**Evidence:** `git show 57f4c871`, the cited lines

---

## Claim 31b: 57f4c871 body: "C5/C6: one kept `Size after iteration N` line per iteration in the rubric"

**Location:** commit 57f4c871 message
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric-line rule only. The C6 half (BASE as in step 1a) holds at HEAD (Claim 23).

7d61c39b's I1 replaced the rubric line with a commit-body line: "the per-iteration count goes in the following commit's body, not a new rubric line". HEAD's `review-fix-loop.md:57` says "Note each count in the body of the commit that follows it". The rubric row C5 reads "Fixed, then moved in iteration 2 (I1)", which acknowledges the change.

**Evidence:** `git show 57f4c871`, `git show 7d61c39b`, `workflows/review-fix-loop.md:57`, `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:37`

---

## Claim 32: 7d61c39b body: I1-I9, I11 descriptions and "Size: 50 code lines against main."

**Location:** commit 7d61c39b message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix against HEAD and the size figure. I10's "uses SKILL.md's first-pass test" is checked in Claim 15 (Mostly accurate) and is not cleared here.

`cnt main HEAD` → `50` (00:45, exit 0). The "Size:" line's format matches the owner's `Size: <count> code lines against <BASE>`. Each fix is at HEAD:

- I1: `review-fix-loop.md:57`.
- I2: `:61`.
- I3/I5: `:57`, `pr-prep.md:458,467`, the heading at `:55`, and 6 anchors (Claim 7).
- I8: `pr-prep.md:244`, `review-fix-loop.md:59`.
- I9: `pr-prep.md:287`.
- I11: `review-fix-loop.md:53,63,84`.
- I4/I6/I7: `review-fix-loop.md:61`, `log.md:85` (Claim 1), `completion-signals.md:82`.

**Evidence:** `git show 7d61c39b`, the cited lines

---

## Claim 33: No doc outside `docs/reviews`, `docs/working`, `archive`, `runs` still states the old rule (entry gate only) in a way that now contradicts

**Location:** `guides/pr-prep-quick-ref.md:11`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers grep hits for `400`, "size gate", "size cap", "row 62"/"log 62" and "entry gate" across the repo, minus those dirs and `test/`. It does not establish that docs phrased without these keywords are free of the old rule.

Command (exit 0): `rg -n '\b400\b|size gate|size cap|log row 62|log 62|row 62|entry gate' --glob '!docs/reviews/**' --glob '!docs/working/**' --glob '!archive/**' --glob '!runs/**' --glob '!test/**' .`. The remaining hits are:

- the entry-gate restatements, which remain true as entry checks: `guides/pr-prep-quick-ref.md:11`, `workflows/pr-prep.md:86,96,155`, `guides/completion-signals.md:82`;
- `guides/validation-gates.md:46` "Gate 1b: Diff size cap ... does not exceed 500", which belongs to `scripts/self-improvement.sh:1207` and is a different gate;
- `skills/dev-cycle/SKILL.md:701`, a template example;
- unrelated 400s (HTTP status codes, the .NET SDK 10.0.400, SVG width, the RPI plan-size warning).

AGENTS.md, GEMINI.md and global-instructions had no hits.

**Evidence:** rg output above, `guides/validation-gates.md:46-50`

---

## Claim 34: "Tests that pin this text: ... `test/workflow-required-sections.bats`, `test/cross-reference-integrity.bats` and `test/skills/code-review-assurance-contract.bats` read these files"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:28`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers whether each named suite reads pr-prep, review-fix-loop or chat-synthesis. It does not establish their pass state, which Claim 29 executed.

`rg -ln 'review-fix-loop|chat-synthesis|pr-prep' test` lists `test/workflow-required-sections.bats` and `test/skills/code-review-assurance-contract.bats`, but not `test/cross-reference-integrity.bats`. That suite may glob the files generically, and its implementation was not read for this pass. To verify: read `test/cross-reference-integrity.bats` and check whether its file set includes `workflows/*.md` and `skills/**/references/*.md`.

**Evidence:** rg output above

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 13** (`docs/working/plan-2026-10-15-q160-size-recheck.md:36`): the plan's step 1 still names the old heading, the review-artifact record and "same BASE". Iterations 1-2 changed all three.
- **Claim 30a** (commit a94e01c7): the body describes rule 2's ">800 on a later pass", "same BASE" and the per-artifact count, all superseded at HEAD. Commit bodies are immutable, so this needs only an override row or a note in the merge message, if wanted.
- **Claim 31b** (commit 57f4c871): "one kept `Size after iteration N` line ... in the rubric" was superseded by 7d61c39b I1 (commit-body line).

### Mostly Accurate
- **Claim 2** (`docs/decisions/log.md:85`) and **Claim 24b** (`workflows/review-fix-loop.md:59`): "[2] has none and [1] did" states as fact what is a reading. [2] opens "Same as [1]", and [1]'s "(in /away mode, automatically)" is a split provision. Reword along the lines of "[2]'s text names no /away case".
- **Claim 8** (`docs/working/plan-...:3`, `workflows/review-fix-loop.md:65,67`, row 62): Q-160 is not on main. It lives in unmerged cycle commit 63af3551, so the citations dangle on main until that branch lands.
- **Claim 15** (`skills/code-review/references/chat-synthesis.md:140-142`): rule 2's first-pass test should read "no canonical rubric before this pass, or the newest one closed", as SKILL.md:739 says.
- **Claim 20** (`workflows/pr-prep.md:287`): step 3's criterion asks for the "before merge" run, which happens later at 6c and is covered by 6c's own criterion.
- **Claim 21** (`workflows/review-fix-loop.md:55` and cross-refs): "before merge" is publish time on the GitHub path. Commits pushed after publishing are not re-checked.
- **Claim 30c** (commit a94e01c7): 157→603 / 392→570 framing and Q-113 as an entry-gate waiver. Already logged at `override-log.md:828`.

### Unverifiable
- **Claim 34** (`docs/working/plan-...:28`): to verify, read `test/cross-reference-integrity.bats` and confirm it reads the changed files.

---

## Goal-Alignment Note

The goal is to merge `fix/q160-iteration-cap` locally. The core rule text is consistent with its sources and with itself:

- Q-104 [2]'s re-measure, ~800 tolerance and waiver are attributed correctly.
- Every growth figure reproduces with step 1a's command.
- The order 3c → size re-check → drift check → 3d agrees in both files.
- The early split trigger, the iteration-4 gate and the precedence paragraph agree.
- Rule 2 no longer contradicts the loop's stop.
- All anchors resolve, and the three pinning suites pass.

There are no Incorrect findings. The open items are wording precision:

- The /away attribution (Claims 2, 24b).
- "Before merge" on the GitHub path, and step 3's criterion timing (Claims 20, 21).
- Rule 2's restatement of SKILL.md's first-pass test (Claim 15).
- The Q-160 citation, which does not resolve on main until the cycle branch merges (Claim 8). If this branch lands first, that is the one item a main-branch reader would notice.
