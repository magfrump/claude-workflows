Commit: 7d61c39b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q160 (claude-workflows)
**Scope:** full branch diff `main...HEAD` on `fix/q160-iteration-cap` (13 files) plus the commit messages of a94e01c7, 57f4c871 and 7d61c39b; restatements of the old rule grepped repo-wide outside `docs/reviews`, `docs/working`, `archive`, `runs`
**Replication:** k=3 final confirming pass, replicate r2 (decision log 63)
**Checked:** 2026-10-15
**Total claims checked:** 33
**Summary:** 25 verified, 7 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim matches a logged pattern. Claim 9 (self-eval counts) is close to the logged class "a specific measured value quoted from a checked-in artifact set": here the numbers do exist in the set but are given the wrong label.

Execution provenance (executed claims): every command ran with `cwd=/workspace` (the shared checkout, whose object store holds every SHA cited) or `/workspace/.claude/wt-q160`, between 2026-10-15T07:40Z and 07:48Z. Each exited 0. Output is quoted inline, as the brief asks (no execution-log files). `cnt` is pr-prep step 1a's command with explicit endpoints: `git diff --numstat "$1" "$2" -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'`.

---

## Claim 1: Row 61: "In /away mode splitting is the default, recorded as an interim in `questions.md`, and it is also the /away default at the iteration-4 gate when the unit is separable"

**Location:** `docs/decisions/log.md:84`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether row 61, which this branch leaves unchanged, now contradicts the loop doc. Does not establish whether it should be amended: that is settled by override-log row 830 (Won't-Fix), so this claim re-flags a settled decision.

The loop doc now qualifies both defaults. `workflows/review-fix-loop.md:53`: "split without asking, unless the unit has grown past the [size re-check]'s ~800 lines, where the user decides". `:84`: "`split` is the default when the unit has separable parts and has not grown past the [size re-check]'s ~800 lines". Row 61 states the defaults without that qualifier. So it is right except past 800, which is a missing qualifier, not a wrong mechanism. Row 62's amendment carries the precedence (`docs/decisions/log.md:85`: "precedence over the agent's own splits are Q-160's reading"). The override row accepts exactly this gap (`docs/reviews/override-log.md:830`: "Decision log row 61 (early split trigger) does not mention the size re-check's precedence past ~800 ... Won't-Fix").

**Evidence:** `docs/decisions/log.md:84-85`, `workflows/review-fix-loop.md:53,84`, `docs/reviews/override-log.md:830`

---

## Claim 2: Row 62 amendment: "After each iteration's fix commits and before merge, the loop re-runs step 1a's count; growth up to ~800 lines is tolerated, and past 800 the loop stops until the user answers a waiver entry (Q-104 [2]). The before-merge point, the /away reading (no exception, since [2] has none and [1] did), and precedence over the agent's own splits are Q-160's reading"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with Q-104's option [2] text and with `review-fix-loop.md` § Size re-check. Does not establish that the amendment lists every Q-160 addition: waiver limits and where the count is recorded are named only in the loop doc (see Claim 29).

Q-104 option [2], `docs/working/questions-archive.md:2020`: "Same as [1], but growth up to ~800 lines is tolerated. Past that, the loop stops and asks you for a waiver." Option [1], `:2019`: "Past 400 lines, the loop stops and the growth is split into a stacked unit (in /away mode, automatically)". That supports "[1] did" have an /away clause and "[2] has none". The loop doc matches the amendment: re-run "after each iteration's fix commits and tests ... and once more at pr-prep 6c" (`workflows/review-fix-loop.md:57`).

**Evidence:** `docs/working/questions-archive.md:2008-2025`, `docs/decisions/log.md:85`, `workflows/review-fix-loop.md:57-65`

---

## Claim 3: Row 62: "The second trigger, 'if units under the cap still balloon during review', fired twice (Q-104: 396 to 1861 lines; Q-160: 102 to 842, 217 to 538)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers recomputing all three figure pairs with step 1a's command, plus the two trigger firings recorded in cycle records. Does not establish that no third firing went unrecorded.

The command was `cnt 4225753a de530691; cnt 4225753a 5652d33f` and, for each merge M, `cnt $(git merge-base M^1 M^2) <first commit>` and `... M^2` (cwd /workspace, exit 0). Output:

```
396
1861
581d41d8 mb=f6fdda68 first=43b9edb6: first=102 atmerge=842
dfa75374 mb=e5d0f838 first=3e58eb9c: first=217 atmerge=538
```

The quoted trigger text matches main's row 62 (`git diff main...HEAD -- docs/decisions/log.md`, removed line: "or if units under the cap still balloon during review"). There were two firings: Q-104 (cycle 2026-10-02), and cycle 2026-10-14's record on `chore/dev-cycle-2026-10-15-0357` (commit 63af3551: "log row 62: fired (second clause) ... → Q-160").

**Evidence:** `docs/decisions/log.md:85`, `docs/working/questions-archive.md:2015`, commit 63af3551 `docs/working/cycles/cycle-2026-10-14.md`

---

## Claim 4: Row 62's amendment and its replacement revisit trigger sit in the Context / Why column (7d61c39b: "row 62's amendment moved to the Rationale column")

**Location:** `docs/decisions/log.md:85`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the column of the amendment and of the revisit-trigger sentence, and the precedent set by row 60. Does not establish anything about the commit's label "Rationale": the header names the column "Context / Why".

The table header is `docs/decisions/log.md:23` "| # | Date | Decision | Context / Why | Full Record |". Splitting row 62 on ` | ` (`awk -F' \\| '`, exit 0) shows that field 4 starts "User answer to Q-085 ([3])", and the `**Amended 2026-10-15` text and "it is replaced by: revisit if two or more units need a waiver" both fall inside it. Field 5 is "log 59, 61; ...; Q-085". Row 60 puts its own amendment in the same column (`:83`, "**Amended 2026-09-28 (Q-087 [2]):**", in the context field).

**Evidence:** `docs/decisions/log.md:23,83,85`

---

## Claim 5: Rubric sizes: "Size after iteration 0 (entry, step 1a): 28 code lines against main" and "Size after iteration 1: 41 code lines against main"; 7d61c39b body: "Size: 50 code lines against main."

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:9`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers step 1a's count at the three branch commits against main. Does not establish where the count should be recorded: the rubric line follows the iteration-1 rule, which iteration 2 (I1) replaced with commit bodies.

The command was `git diff --numstat main...$c -- ':(top)' ':(top,exclude)docs/' | awk ...` for each commit (cwd wt-q160, exit 0):

```
a94e01c7 28
57f4c871 41
7d61c39b 50
```

**Evidence:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:9,56`, commit 7d61c39b body

---

## Claim 6: Rubric: "Rows 144-145 (`review/q085`: the size gate excludes all of `docs/`; deletions count) ... Rows 479, 486, 488 (`feat/build-loop-u2a4`: unit grew 381→443→540→599 during review, routed to the user)"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:44`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rows read as file line numbers in `override-log.md`. Does not establish that they are table-row ordinals: counting table rows gives different, unrelated rows.

`docs/reviews/override-log.md:144`: "Excluding all of `docs/` from the size gate also drops non-markdown files there". `:145`: "Commit b516af2 message: 'Deletions still count'". `:479`: "The unit measured 381 code lines at pr-prep step 1a and 443 after iteration 1's fixes". `:486`: "540 code lines ... Routed (questions.md)". `:488`: "599 code lines ... (540 at Q-131) ... Routed (questions.md)".

**Evidence:** `docs/reviews/override-log.md:144-145,479,486,488`

---

## Claim 7: Rubric tallies: i1 "22 claims; 15 Verified, 5 Mostly accurate, 1 Stale, 1 Incorrect"; i2 "18 claims; 14 Verified, 4 Mostly accurate, 0 Incorrect"; api-consistency "1 Inconsistent, 5 Minor, 2 Informational"; "anchors updated (pr-prep x4, loop x2)"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:13,56,64`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts against the cited reports and the anchor count at HEAD. Does not establish that the reports' verdicts are themselves right.

`grep "^\*\*Verdict" ... | sort | uniq -c` (exit 0) gives 15 Verified, 5 Mostly accurate, 1 Stale, 1 Incorrect for i1, and 14 Verified, 4 Mostly accurate for i2. The api review's severities are F1 "Inconsistent", F2-F6 "Minor" and F7-F8 "Informational" (`docs/reviews/api-consistency-review-2026-10-15-fix-q160-iteration-cap.md:186-193`). The `#size-re-check-after-any-iteration-and-before-merge` links appear at `workflows/pr-prep.md:96,244,274,458` (4) and `workflows/review-fix-loop.md:53,84` (2).

**Evidence:** `docs/reviews/code-fact-check-report-q160-i1.md:9`, `docs/reviews/code-fact-check-report-q160-i2.md:9`, `docs/reviews/api-consistency-review-2026-10-15-fix-q160-iteration-cap.md:186-193`

---

## Claim 8: New override rows: "(fact-check Claims 8, 22, Mostly accurate)", "(self-eval, testability Weak)", "(fact-check i2 Claim 16)", "(fact-check i2 Claim 9)" and "Matches the practice of the rows above them (2026-10-14)"

**Location:** `docs/reviews/override-log.md:828-831`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cited claim numbers, verdicts and the convention claims. Does not establish whether the Won't-Fix verdicts are wise.

The i1 report has both Claim 8 and Claim 22 at "**Verdict:** Mostly accurate". The self-eval's `:18` reads "| Testability investment | Weak |". The i2 report's Claim 16 is the precedence finding and its Claim 9 reads "The two new override-log rows follow the table's format ... Mostly accurate". The file says "Add new entries at the top" (`docs/reviews/override-log.md:72`), while the 2026-10-14 rows sit at the bottom and use "Corrected in the fix commit" (`:827`), which supports row 831.

The factual content of row 828 also checks out. Q-113 reads "~417 changed code lines after the Q-112 fixes" (archive `:1935`). The 157→603 and 392→570 units had feature commits after the first commit: `git log mb..M^2` shows c934adbc "feat(...) (U2a4)" after d861183d "(red)", and 4be0445d "feat(cc-push) ... (Q-089 unit A2)" after f2533b33.

**Evidence:** `docs/reviews/override-log.md:72,827-831`, `docs/reviews/code-fact-check-report-q160-i1.md:130,337`, `docs/reviews/self-eval-review-fix-loop-2026-10-15-fix-q160-iteration-cap.md:18`

---

## Claim 9: Self-eval: "91 code-review rubric artifacts in `docs/reviews/`, 31 carrying `Iteration N of 3` headers" and "`bats test/workflow-required-sections.bats` (5/5 ok)"

**Location:** `docs/reviews/self-eval-review-fix-loop-2026-10-15-fix-q160-iteration-cap.md:21`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the counts at a94e01c7 (the self-eval's commit). Does not establish the self-eval's Adequate rating, which the counts support either way.

Run at a94e01c7 (cwd /workspace/.claude/wt-q160, exit 0):

- `git ls-tree --name-only a94e01c7 docs/reviews/ | grep -c "code-review"` gives 91.
- `... | grep -c "^docs/reviews/code-review-rubric"` gives 76.
- `git grep -l "Iteration [0-9] of 3" a94e01c7 -- docs/reviews | wc -l` gives 31.
- The same grep limited to rubric files gives 19.

So 91 counts every file whose name contains "code-review" (fact-check reports included), not rubrics, and 31 counts all review files, not rubrics. The precise wording is "76 rubrics, 19 of them with the header". Also, `grep -c "^@test" test/workflow-required-sections.bats` gives 4, and with `cross-reference-integrity.bats` the two files hold 5. So "5/5" is the two suites together, not workflow-required-sections alone.

**Evidence:** `docs/reviews/self-eval-review-fix-loop-2026-10-15-fix-q160-iteration-cap.md:11,21`, `test/workflow-required-sections.bats`, `test/cross-reference-integrity.bats`

---

## Claim 10: Plan growth table: "581d41d8 (U2a3b) 102 (43b9edb6) → 842; 73589cd7 (U2a4) 157 (d861183d) → 603; dfa75374 (U2a3c) 217 (3e58eb9c) → 538; 626dc300 (Q-089 A1+A2) 392 (f2533b33) → 570"; "All four match Q-160"; caveat on 73589cd7 and 626dc300

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:11-18`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each count from the merge's merge-base with step 1a's command, each first commit's parent being the merge-base, and the Q-160 text. Does not establish "at merge" as the merge commit's own tree: it is the branch tip (M^2).

The command ran for each merge M (cwd /workspace, exit 0). Output:

```
581d41d8 mb=f6fdda68 first=43b9edb6: first=102 atmerge=842 ... parent-of-first=f6fdda68
73589cd7 mb=7afdb8d2 first=d861183d: first=157 atmerge=603 ... parent-of-first=7afdb8d2
dfa75374 mb=e5d0f838 first=3e58eb9c: first=217 atmerge=538 ... parent-of-first=e5d0f838
626dc300 mb=4ab9a51f first=f2533b33: first=392 atmerge=570 ... parent-of-first=4ab9a51f
```

Q-160 (`chore/dev-cycle-2026-10-15-0357:docs/working/questions.md:132`): "102 to 842 code lines (581d41d8), 157 to 603 (73589cd7), 217 to 538 (dfa75374) and 392 to 570 (626dc300)". The caveat holds: c934adbc (U2a4 feat) follows d861183d, and 4be0445d (Q-089 A2) follows f2533b33.

**Evidence:** `docs/working/plan-2026-10-15-q160-size-recheck.md:11-18`; Q-160 on `chore/dev-cycle-2026-10-15-0357`

---

## Claim 11: Plan interim practice: "Q-120 [1] (U2a3b at 794) cited 'Q-104 [2]'s ~800' ... merge-msg ... records 841 lines ... Q-131 (U2a4, 540) asked for a waiver 'against the 400 cap' ... Q-113 (U1b, 417 after its Q-112 review fixes) and Q-114 (U1c, 426) were opened 2026-10-05, before Q-104 was answered (10-06)"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:20`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the Q-entries in the archive on `chore/dev-cycle-2026-10-15-0357` and main's merge message file. Does not establish 841 as the true count: step 1a's command gives 842 at the U2a3b tip (Claim 10), and the plan only reports what the file says.

The archive has these entries:

- Q-120: "the unit sits at 794 changed code lines, at Q-104 [2]'s ~800 tolerance".
- Q-131: "the unit is 540 code lines against the 400 cap".
- Q-113: "**Opened:** 2026-10-05 ... ~417 changed code lines after the Q-112 fixes".
- Q-114: "**Opened:** 2026-10-05 ... 426 changed code lines after its review fixes".
- Q-104: "**Answered 2026-10-06**".

`docs/working/merge-msg-build-loop-u2a3b.md:28` reads "841 changed code lines against main, past decision log row 62 / Q-104 [2]'s ~800, under the user's waiver (Q-120 [1])".

**Evidence:** `docs/working/questions-archive.md:1932-1951,2011,2067-2072,2254-2257` (chore branch), `docs/working/merge-msg-build-loop-u2a3b.md:28`

---

## Claim 12: Plan step 1: "new `### Size re-check (after any iteration)` ... record the count in the iteration's review artifact"; step 2: "step 1a one sentence linking the re-check; step 3e lists it; step 3 completion criterion"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:36-37`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the plan's step list against the shipped text at HEAD. Does not establish that the "Restatements to update" list (`:25`, which already names 3c and 6c) is stale: it is current.

These steps matched a94e01c7, but iteration 2 changed the text. The heading is now `### Size re-check (after any iteration and before merge)` (`workflows/review-fix-loop.md:55`). The count is now "Note[d] ... in the body of the commit that follows it (`Size: <count> code lines against <BASE>`)" (`:57`), not in a review artifact. pr-prep also gained 3c and 6c pointers and a 6c criterion (`workflows/pr-prep.md:244,458,467`), which step 2 does not list. The plan was updated in 57f4c871 for C2/C3, but not after I1/I3/I5.

**Evidence:** `docs/working/plan-2026-10-15-q160-size-recheck.md:36-37`, `workflows/review-fix-loop.md:55,57`, `workflows/pr-prep.md:244,458,467`

---

## Claim 13: Plan: "`skills/dev-cycle/SKILL.md:701` names 'log row 62' only as a template example of a trigger verdict"; "Tests that pin this text: none found"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:30-32`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the dev-cycle line and a grep of `test/` for the re-check, rule 2 and step 1a text. Does not establish whether `skills/dev-cycle/SKILL.md` is "gate code".

`skills/dev-cycle/SKILL.md:701` reads "- log row 62: cannot tell — <what would tell>". `rg -l "Size re-check|size re-check|split PR|step 1a" test/` matches only `test/skills/design-space-situating/expected-verdicts.bash`, which is unrelated. I ran the three suites the plan names: `timeout 600 bats test/workflow-required-sections.bats test/cross-reference-integrity.bats test/skills/code-review-assurance-contract.bats` (cwd wt-q160, 2026-10-15T07:45:09Z, exit 0) printed "1..26" with no "not ok" lines.

**Evidence:** `skills/dev-cycle/SKILL.md:701`, `test/workflow-required-sections.bats`, `test/cross-reference-integrity.bats`, `test/skills/code-review-assurance-contract.bats`

---

## Claim 14: "Did it stay within the review-fix loop's size re-check (≤ 800 changed code lines outside `docs/` after review fixes), or does the description cite the user's waiver by its `Q-NNN` entry?"

**Location:** `guides/completion-signals.md:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the loop doc's threshold and recording rule. Does not establish anything about a waiver's limit: the guide asks only whether a waiver is cited.

This matches `workflows/review-fix-loop.md:57` ("Growth up to ~800 lines ... The check fires above 800") and `:61` ("in the PR description ... citing the `Q-NNN` entry").

**Evidence:** `guides/completion-signals.md:82`, `workflows/review-fix-loop.md:57-61`

---

## Claim 15: "**Size re-check** — after each iteration and before merge, re-run step 1a's count: growth to 800 lines is tolerated; past it, stop and ask the user for a waiver (a `Q-NNN` entry), in /away mode too; note a granted waiver in the PR description, citing that `Q-NNN`"

**Location:** `guides/pr-prep-quick-ref.md:53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the loop doc. Does not establish that the summary carries the waiver-limit rule or the verbatim quote, which it leaves to the owner doc.

This matches `workflows/review-fix-loop.md:57,59,61`: the re-check runs after each iteration and at 6c, there is no /away exception ("This holds in /away mode too"), and the waiver goes in the PR description with its `Q-NNN`.

**Evidence:** `guides/pr-prep-quick-ref.md:53`, `workflows/review-fix-loop.md:57-61`

---

## Claim 16: Rule 2: "On the unit's first review (no rubric for the branch yet, or only a closed one: the first-pass test code-review's SKILL.md uses for the short-circuit)"

**Location:** `skills/code-review/references/chat-synthesis.md:140-142`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the paraphrase of SKILL.md short-circuit mechanic 6. Does not establish how existing rubrics behave at derivation time beyond the text, since no test or script derives the next action.

SKILL.md's test, `skills/code-review/SKILL.md:739-742`, reads: "If no canonical rubric exists yet, or the newest one is closed (`Loop closed at`; the first pass of a loop), there is no marker ... If rubrics for this branch exist but none has the canonical name ... do not short-circuit."

Rule 2's paraphrase differs from it in three ways:

- "Only a closed one" for "the newest one is closed".
- It drops "canonical", so with only non-canonical rubrics SKILL.md treats the history as unreadable, while rule 2 reads "not first review".
- Timing. Mechanic 6 runs before the pass writes its rubric. The ladder's inputs are "the rubric the synthesis just produced" (`chat-synthesis.md:128`), so read literally, at derivation time a rubric for this pass always exists. "No rubric for the branch yet" needs a "before this pass" qualifier.

The intent (rule 2 only on a loop's first pass) is clear, and the precise wording is "no canonical rubric for the branch before this pass, or the newest one is closed".

**Evidence:** `skills/code-review/references/chat-synthesis.md:128,140-151`, `skills/code-review/SKILL.md:121-129,734-744`

---

## Claim 17: Rule 2: "Rule 2 does not apply on later passes ... Growth during review falls under the loop's own size re-check (`workflows/review-fix-loop.md` § Size re-check): it tolerates up to ~800 lines, and past that the loop stops for the user's waiver. No next action here, `merge` included, overrides that stop."

**Location:** `skills/code-review/references/chat-synthesis.md:146-150`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers consistency with the five-action ladder and the loop doc. Does not establish that code-review computes or shows the size on later passes: it does not, and the loop owns the stop.

The ladder still lists five actions, `chat-synthesis.md:111`: "[merge | fix red items then re-review | split PR | escalate to /pre-mortem | block on architectural review]", and rules 3-5 are unchanged (`:153-166`). The loop doc stops the merge past 800 (`workflows/review-fix-loop.md:59`: "no further fix commits, drift check, re-review or merge until the user answers a waiver entry"). Rule 1 still precedes rule 2, and "A waived unit with a 🔴 falls through" is kept (`:150-151`).

**Evidence:** `skills/code-review/references/chat-synthesis.md:111,137-166`, `workflows/review-fix-loop.md:59`

---

## Claim 18: Worked example: "1 🔴 in security, 800-line diff, first review → rule 2 → `Recommended next action: split PR.`"

**Location:** `skills/code-review/references/chat-synthesis.md:184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers derivation under rules 1-2 for an unwaived unit with no architecture trigger. Does not establish the outcome for a waived unit, which the example leaves out.

Rule 2's conditions all hold: first review, 800 > 400, 1 🔴, and rule 1 does not match (no architecture finding). Rule 3 needs 3+ domains or ≥3 reds, and it is lower in the ladder anyway.

**Evidence:** `skills/code-review/references/chat-synthesis.md:140-155,184`

---

## Claim 19: Step 1a: "This gate checks the unit once, at entry; the review-fix loop re-runs the same count after each iteration and before merge, and tolerates growth to ~800 lines ([size re-check](review-fix-loop.md#size-re-check-after-any-iteration-and-before-merge), Q-104 [2])."

**Location:** `workflows/pr-prep.md:96`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the statement, the anchor's resolution and the Q-104 [2] attribution of the re-measure and the tolerance. Does not establish that the anchor renders the same on non-GitHub renderers.

I slugged every heading with the GitHub rule (lowercase, strip punctuation, spaces to `-`; exit 0). It gave "ok size-re-check-after-any-iteration-and-before-merge", "ok early-split-trigger-after-any-iteration", "ok hard-cap-3-iterations", "ok 1-gate-checks" and "ok 3-review-fix-loop". Every anchor on a changed line in the diff is one of these. The shorter anchor `#size-re-check-after-any-iteration)` appears only in the historical i1 and api review artifacts. Q-104 [2] supplies "re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated" (archive `:2011`).

**Evidence:** `workflows/pr-prep.md:96`, `workflows/review-fix-loop.md:55`, `docs/working/questions-archive.md:2011`

---

## Claim 20: 3c: "**Size re-check.** After the tests, before the drift check below and the re-review, re-run step 1a's count. Past ~800 lines, stop and ask the user for a waiver"

**Location:** `workflows/pr-prep.md:244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of checks in 3c against the loop doc. Does not establish whether the drift check section mentions the re-check: it does not, but nothing there contradicts the order.

The loop doc says "after each iteration's fix commits and tests (pr-prep 3c), before the fix-commit drift check" (`workflows/review-fix-loop.md:57`) and "Past 800, ... no further fix commits, drift check, re-review" (`:59`). The drift-check section's "after each fix batch (pr-prep Step 3c), run ... before starting the next full pass" (`:99-101`) is compatible.

**Evidence:** `workflows/pr-prep.md:244-246`, `workflows/review-fix-loop.md:57-59,97-101`

---

## Claim 21: 3e: "the [early split trigger] and the [size re-check] (both checked after every iteration; the size re-check again before merge) ... are owned by [review-fix-loop.md § Hard cap]"

**Location:** `workflows/pr-prep.md:274`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ownership and timing. Does not establish whether "after every iteration" is the same moment for both checks: the split trigger runs at triage (3b) and the re-check after tests (3c).

The early split trigger runs "After triaging any iteration" (`workflows/review-fix-loop.md:51`). The re-check runs after 3c and again at 6c (`:57`). Both sections sit under `## Hard cap (3 iterations)` (`:24,49,55`).

**Evidence:** `workflows/pr-prep.md:274`, `workflows/review-fix-loop.md:24,49-57`

---

## Claim 22: Step 3 criterion: "The size re-check ran after each iteration and before merge: the unit is at most 800 changed code lines (step 1a's command, `BASE` as in step 1a), OR the user waived it and the PR description records the waiver with its `Q-NNN` entry and the limit it grants"

**Location:** `workflows/pr-prep.md:287`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the criterion's timing and content against the loop doc and 6c. Does not establish whether step 3's criteria are meant to be re-checked at step 6, since pr-prep does not say.

The content matches the loop doc (`workflows/review-fix-loop.md:57,61`). But the loop doc puts the "before merge" run "at pr-prep 6c, before the description is published" (`:57`), and 6c has its own criterion (`workflows/pr-prep.md:467`: "The final size re-check ran before publishing (or merging)"). When step 3's completion criteria are checked at the end of step 3, the before-merge run has not happened yet, so "and before merge" cannot be satisfied at that point. The precise version is "ran after each iteration (the before-merge run is 6c's criterion)". Other step 3 criteria also point forward to the PR description, so this is a timing imprecision, not a contradiction.

**Evidence:** `workflows/pr-prep.md:281-292,458,467`, `workflows/review-fix-loop.md:57`

---

## Claim 23: 6c: "First, run the [size re-check] one last time: past ~800 lines with no waiver from the user, do not publish or merge." and criterion "The final size re-check ran before publishing (or merging): at most 800 code lines, or within a cited waiver's limit"

**Location:** `workflows/pr-prep.md:458`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 6c against the loop doc on both delivery paths. Does not establish a re-check of commits added after publication on the GitHub path, which no doc covers.

6c's trigger covers both paths: "Before publishing the description (marking the draft PR ready for review, opening the PR if no draft was made, or, on the local-merge path, running the merge)". The loop doc agrees: "once more at pr-prep 6c, before the description is published (on the local-merge path, before the merge)" (`workflows/review-fix-loop.md:57`). "Within a cited waiver's limit" matches `:61`. The local-merge path runs step 6 (`workflows/pr-prep.md:24`: "Step 6's template becomes the body of the `--no-ff` merge commit").

**Evidence:** `workflows/pr-prep.md:24,458,467`, `workflows/review-fix-loop.md:57,61`

---

## Claim 24: Intro: "This document owns the review-fix loop's control rules: the iteration cap and its exit conditions, the early split trigger, the size re-check, the fix-drift check, and the two re-fire filters"

**Location:** `workflows/review-fix-loop.md:8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the presence of each owned section. Does not establish that no other doc restates the rule in full: the guides and pr-prep summarize it and link back.

Each named rule has a section: `## Hard cap` (`:24`), `### Early split trigger` (`:49`), `### Size re-check` (`:55`), `## Fix-commit drift check` (`:97`), `## Divergence detection` (`:121`), and the re-flagged settled decisions filter, linked from pr-prep 3b.

**Evidence:** `workflows/review-fix-loop.md:8,24,49,55,97,121`

---

## Claim 25: Early split trigger: "In /away mode and autonomous loops, split without asking, unless the unit has grown past the [size re-check]'s ~800 lines, where the user decides."

**Location:** `workflows/review-fix-loop.md:53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the precedence paragraph. Does not establish what happens under a granted waiver (for example, a waiver to 900 with the unit at 850): both passages use the fixed 800, so the agent still may not split on its own there.

This agrees with `:63`: "When the unit has grown past 800 during review, the agent does not split on its own to get back under: not by the early split trigger".

**Evidence:** `workflows/review-fix-loop.md:53,63`

---

## Claim 26: "Re-run step 1a's command after each iteration's fix commits and tests (pr-prep 3c), before the fix-commit drift check, and once more at pr-prep 6c ... `BASE` is set as in step 1a: the branch directly below this unit, or `main` once that branch has merged. Growth up to ~800 lines (twice the entry cap) is tolerated. The check fires above 800, and as in step 1a the '~' marks a round number"

**Location:** `workflows/review-fix-loop.md:57`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers BASE, the check points and the threshold semantics against step 1a, 3c and 6c. Does not establish BASE validation, which step 1a explicitly declines to do.

Step 1a sets `BASE=main   # a stacked unit whose lower unit has not merged yet: that unit's branch, the one directly below` (`workflows/pr-prep.md:89`) and says "The gate fires above 400: the '~' marks a round number, not a tolerance band" (`:96`). The 3c and 6c pointers are Claims 20 and 23.

**Evidence:** `workflows/pr-prep.md:89,96,244,458`, `workflows/review-fix-loop.md:57`

---

## Claim 27: "This holds in /away mode too: unlike the early split trigger, the agent does not decide this one. Q-104 [2] says the loop 'asks you for a waiver' and, unlike its option [1], makes no /away exception (decision log 62)."

**Location:** `workflows/review-fix-loop.md:59`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the quote and the absence of an /away clause in [2]'s text. Does not establish that the user meant no exception: [2] opens "Same as [1], but", and [1] carries "(in /away mode, automatically)". [1]'s clause governs its split past 400, which [2] replaces, so reading it as inherited is unlikely but not excluded. Line 65 labels the /away reading as Q-160's.

Option [2], archive `:2020`, reads: "Past that, the loop stops and asks you for a waiver." The quoted phrase is exact. Option [1], `:2019`, has "(in /away mode, automatically)". Row 62 carries the reading (`docs/decisions/log.md:85`: "the /away reading (no exception, since [2] has none and [1] did)").

**Evidence:** `docs/working/questions-archive.md:2019-2020`, `workflows/review-fix-loop.md:59,65`, `docs/decisions/log.md:85`

---

## Claim 28: "Record it as step 1a records its waiver, in the PR description (the merge commit message on the local-merge path), citing the `Q-NNN` entry with the user's answer quoted verbatim ... A waiver of the entry gate does not lift this check unless its answer says so." and the precedence paragraph's "(A unit already past 800 at entry falls under step 1a, which splits it in /away mode.)"

**Location:** `workflows/review-fix-loop.md:61-63`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with step 1a's waiver recording and /away split. Does not establish what happens when an entry-gate waiver's answer names a limit above 800, which neither doc states.

Step 1a, `workflows/pr-prep.md:101`, says: "note the waiver in the PR description (step 6), citing by ID the answered `Q-NNN` entry ... with the user's answer quoted verbatim". At `:96` it says: "In /away mode, split without asking".

**Evidence:** `workflows/pr-prep.md:96,101`, `workflows/review-fix-loop.md:61-63`

---

## Claim 29: "Q-104 [2] gives the re-measure, the ~800 tolerance and the waiver. The other details here are Q-160's reading of it: the before-merge point, /away mode, precedence over splits, waiver limits, entry waivers, and where the count is noted."

**Location:** `workflows/review-fix-loop.md:65`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the attribution split against Q-104's text. Does not establish whether the unlisted details need labelling.

The three items given to Q-104 [2] are in its text (archive `:2011`, `:2020`). Every listed Q-160 item is absent from Q-104, which is correct. The colon list reads as exhaustive, but the section adds other details Q-104 does not contain and the list does not name:

- "The entry's options can include splitting the unit, and it proposes the new limit" (`:59`). The limit is arguably under "waiver limits"; the split option is not.
- The `Needs: you: judgment` routing.
- "Work on other units goes on".

The general sentence ("The other details here are Q-160's reading") is true. The enumeration is incomplete.

**Evidence:** `workflows/review-fix-loop.md:57-65`, `docs/working/questions-archive.md:2011,2020`

---

## Claim 30: "Why: ... `feat/dev-cycle-digest` went from 396 to 1861 lines over 37 passes (Q-104); U2a3b went from 102 to 842 and U2a3c from 217 to 538 (Q-160)."

**Location:** `workflows/review-fix-loop.md:67`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the figures recomputed in Claims 3 and 10 and the pass count from Q-104. Does not establish the pass count independently of Q-104's text.

Recomputed (Claim 3 output): 396 and 1861 against 4225753a, 102→842 for U2a3b, and 217→538 for U2a3c. Q-104 (`:2015`): "landed at 1861 (5652d33f) after 37 review passes (pass 38 reviewed the merged result)". The merge-commit subjects confirm the unit names (581d41d8 U2a3b, dfa75374 U2a3c, from the plan table and `git log`).

**Evidence:** `workflows/review-fix-loop.md:67`, `docs/working/questions-archive.md:2015`

---

## Claim 31: Iteration-4 gate: "In /away mode and autonomous loops, `split` is the default when the unit has separable parts and has not grown past the [size re-check]'s ~800 lines ...; when it has none, the default is `escalate`."

**Location:** `workflows/review-fix-loop.md:84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the default's coverage of cases. Does not establish whether the uncovered case is reachable without a waiver: without one, the loop has already stopped at the re-check (`:59`).

The new conjunct leaves a gap. "When it has none" refers to separable parts, so a unit with separable parts that has grown past 800 gets no stated /away default. That case is reachable once a waiver above 800 has been granted (`:61`) and iteration 3 ends unclean. The precedence paragraph forbids `split` there (`:63`), so `escalate` is presumably meant. The precise version is "otherwise (no separable parts, or past ~800), the default is `escalate`".

**Evidence:** `workflows/review-fix-loop.md:59-63,84`

---

## Claim 32: Commit messages: a94e01c7 "units then grew during review (102 to 842, 157 to 603, 217 to 538, 392 to 570 ...)", "Q-113 is an entry-gate waiver"; 57f4c871 "Q-113/Q-114 were in-loop growth before Q-104 was answered, not entry waivers", "the shipped text cites only 102->842 and 217->538"

**Location:** commits a94e01c7, 57f4c871
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a94e01c7's growth and Q-113 claims (most severe part) and 57f4c871's corrections. Does not reopen these: override-log row 828 settles a94e01c7's imprecision as corrected in 57f4c871.

The figures are right (Claim 10). "Grew during review" overstates 157→603 and 392→570, because feature commits followed each first commit. Q-113's 417 is the count "after the Q-112 fixes" (archive `:1935`), so it is in-loop growth, not an entry-gate count. 57f4c871's corrections are accurate. `rg "157|392" workflows/review-fix-loop.md docs/decisions/log.md` finds neither figure, which confirms that the shipped text (`review-fix-loop.md:67`, row 62) cites only 102→842 and 217→538. The other 57f4c871 items (R1, A1-A3, C1-C6) match the HEAD text or were superseded by 7d61c39b, for example C5's rubric line by I1.

**Evidence:** commit a94e01c7 body, commit 57f4c871 body, `docs/working/questions-archive.md:1935,1949`, `docs/reviews/override-log.md:828`

---

## Claim 33: Commit 7d61c39b: I1-I11 items (count in the following commit's body; waiver sets the next limit; 6c "before merge" with a criterion; heading renamed, anchors updated; 3c order; BASE as in step 1a; rule 2 uses SKILL.md's test; early split trigger and gate link the precedence; row 62 moved; completion-signals counts "code lines outside docs/"; two Won't-Fix rows); "Size: 50 code lines against main"; and no remaining doc outside the excluded directories states the entry-only rule

**Location:** commit 7d61c39b
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each item's presence at HEAD, the size figure, and a repo-wide grep for stale restatements. Does not establish the quality of the I10 wording (Claim 16) or the gap in the I11 gate wording (Claim 31). "Rationale column" is the commit's name for the "Context / Why" column (Claim 4).

Each item is present at HEAD: I1 at `workflows/review-fix-loop.md:57`, I2 at `:61`, I3 at `workflows/pr-prep.md:458,467`, I5 at `review-fix-loop.md:55` (anchors per Claim 19), I8 at `pr-prep.md:244`, I9 at `pr-prep.md:287`, I10 at `chat-synthesis.md:140-142`, I11 at `review-fix-loop.md:53,84`, I6 per Claim 4, I7 at `guides/completion-signals.md:82`, and the override rows at `override-log.md:830-831`. Size 50 is from Claim 5.

The stale-restatement grep was `rg -n "split PR|400 changed|~400|size gate|size cap|row 62|log 62|balloon" -g '!docs/reviews/**' -g '!docs/working/**' -g '!archive/**' -g '!runs/**'` (cwd wt-q160, exit 0). Apart from the changed files, it matched only:

- the entry-gate lines `pr-prep.md:86,96,155` and `guides/pr-prep-quick-ref.md:11` (entry checks, still correct);
- unrelated "size cap" uses (`scripts/self-improvement.sh`, `guides/validation-gates.md`, `devcontainer-config/cc-exit-scan.sh`);
- `skills/dev-cycle/SKILL.md:701`.

Row 61 is the one qualifier gap (Claim 1).

**Evidence:** commit 7d61c39b body; files above

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 12** (`docs/working/plan-2026-10-15-q160-size-recheck.md:36-37`): the plan's step list still names the old heading, records the count in a review artifact, and leaves out the 3c/6c pointers; update it to match HEAD or mark it superseded by iteration 2.

### Mostly Accurate
- **Claim 1** (`docs/decisions/log.md:84`): row 61's /away split defaults lack the past-800 qualifier. Settled Won't-Fix (override row 830).
- **Claim 9** (`docs/reviews/self-eval-review-fix-loop-2026-10-15-fix-q160-iteration-cap.md:21,11`): "91 code-review rubric artifacts, 31 carrying" should be 76 rubrics, 19 with the header (91 and 31 are all code-review-named files and all review files); "5/5" counts two suites, not workflow-required-sections' 4 tests.
- **Claim 16** (`skills/code-review/references/chat-synthesis.md:140-142`): the first-pass test drops "canonical", says "only a closed one" for "newest is closed", and lacks "before this pass", although the ladder's input is the rubric this synthesis just produced.
- **Claim 22** (`workflows/pr-prep.md:287`): step 3's criterion says "and before merge", but that run happens later, at 6c, which has its own criterion.
- **Claim 29** (`workflows/review-fix-loop.md:65`): the Q-160-reading list leaves out the waiver entry's split option, the `you: judgment` routing and "work on other units goes on".
- **Claim 31** (`workflows/review-fix-loop.md:84`): the gate's /away default does not cover "separable parts but past ~800" (reachable under a waiver above 800); say `escalate` for it.
- **Claim 32** (commits a94e01c7/57f4c871): a94e01c7's growth and Q-113 wording is imprecise, corrected in 57f4c871 and settled by override row 828.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the OUTPUT PATH given at the end, per the code-fact-check skill, with `Commit: 7d61c39b` at the top.
- Answered: yes. All eight listed focus areas checked, and growth figures recomputed from merge-bases.
- Out of scope: the historical i1/i2/api review reports' own per-claim content (only their tallies and citations used by the rubric and override rows); the self-eval's other ratings.
- Escalate: Claim 31 (gate default gap under a waiver) and Claim 16 (rule 2's first-pass timing) are the only text issues with behavioural reach; neither blocks.
- Decisions I made: read the rubric's "Rows 144-145 ..." as file line numbers, not table ordinals (line numbers match; ordinals do not). Rated Claim 22 Mostly accurate rather than Incorrect, because other step 3 criteria also point forward to step 6.
