Commit: 7d61c39b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q160 (claude-workflows, branch `fix/q160-iteration-cap`)
**Scope:** branch diff `main...HEAD` (main b279a2ba, HEAD 7d61c39b; 13 files) and commit messages `main..HEAD` (a94e01c7, 57f4c871, 7d61c39b). Final confirming pass, replicate r3 of k=3.
**Checked:** 2026-10-15
**Total claims checked:** 24
**Summary:** 15 verified, 8 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). The relevant class is "count claimed in a commit or artifact that does not reproduce" (lines 28, 30). Every count below was recomputed; none matches that pattern.

Shared provenance for the `executed` claims. cwd `/workspace/.claude/wt-q160`, run 2026-10-15T07:43Z–07:46Z. All exited 0. Per the brief, output is inline here and no log file was written. Counting helper (step 1a's command, `workflows/pr-prep.md:91`):

```
cnt(){ git diff --numstat "$1"..."$2" -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'; }
for m in 581d41d8 73589cd7 dfa75374 626dc300; do b=$(git merge-base $m^1 $m^2); ... cnt $b $m^2; per-commit cnt $b <c>; done
== 581d41d8 base=f6fdda68 atmerge=842   first 43b9edb6 102 (then 822aa6ed 155, d894b3f0 225 — all fix commits)
== 73589cd7 base=7afdb8d2 atmerge=603   first d861183d 157 (test, red); c934adbc 381 feat(...) (U2a4) — feature commit second
== dfa75374 base=e5d0f838 atmerge=538   first 3e58eb9c 217; then 27364085 259 fix, 80cc6224 292 perf
== 626dc300 base=4ab9a51f atmerge=570   first f2533b33 392 (A1); 4be0445d 511 feat(cc-push) (Q-089 unit A2) — feature commit third
Q-104: cnt 4225753a de530691 = 396 ; cnt 4225753a 5652d33f = 1861
branch: a94e01c7 28 ; 57f4c871 41 ; 7d61c39b 50   (main == merge-base == b279a2ba)
bats test/cross-reference-integrity.bats test/workflow-required-sections.bats test/skills/code-review-assurance-contract.bats → 1..26, no "not ok", exit 0
```

---

## Claim 1: Row 62 amendment: "re-checked inside the review-fix loop too ... past 800 the loop stops until the user answers a waiver entry (Q-104 [2])"; "The before-merge point, the /away reading (no exception, since [2] has none and [1] did), and precedence ... are Q-160's reading"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the amendment's attribution split against the Q-104 entry text. It does not establish that "Same as [1]" in option [2] cannot be read as inheriting [1]'s /away clause; that question is the residue.

Q-104's answer reads: "pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver" (`docs/working/questions-archive.md:2011`). That backs the parts attributed to [2]. Option [1] says "Past 400 lines, the loop stops and the growth is split into a stacked unit (in /away mode, automatically)" (`:2019`). Option [2] says "Same as [1], but growth up to ~800 lines is tolerated. Past that, the loop stops and asks you for a waiver." (`:2020`). "[2] has none" is literally true of [2]'s own sentence. But [2] opens with "Same as [1]", and [1] carries the /away clause, so "no /away exception" is an inference. The amendment correctly labels it Q-160's reading. Precise version: "[2] replaces [1]'s automatic split past the limit with a waiver ask, so [1]'s /away auto-split does not carry over (Q-160's reading)".

**Evidence:** `docs/decisions/log.md:85`, `docs/working/questions-archive.md:2008-2025`

---

## Claim 2: Row 62: "The second trigger, 'if units under the cap still balloon during review', fired twice (Q-104: 396 to 1861 lines; Q-160: 102 to 842, 217 to 538)"; replacement trigger and column placement

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quoted old trigger text, the four numbers, both firings and the column the amendment sits in. It does not establish whether the replacement "two or more ... within any 14 days" threshold is a good one, which is design rationale.

The old row reads "Revisit if stacking overhead dominates small features, or if units under the cap still balloon during review" (main `docs/decisions/log.md:85`, diff `-` line). Q-104 opens "Decision log row 62's revisit trigger fired" (`questions-archive.md:2011`). Q-160 opens "Log row 62's trigger fired again" (`chore/dev-cycle-2026-10-15-0357:docs/working/questions.md:132`). Recomputed counts: 396/1861, 102→842 and 217→538 (shared provenance block). Splitting the row on ` | ` gives 5 fields. Field 4 (header "Context / Why", `log.md:23`) holds both `**Amended 2026-10-15 ...**` and the replacement revisit trigger. That matches row 60's amendment placement, as 7d61c39b's body says.

**Evidence:** `docs/decisions/log.md:23,83,85`; shared provenance block

---

## Claim 3: Rubric counts: "Size after iteration 0 ... 28", "Size after iteration 1: 41"; "Fact-check: 22 claims; 15 Verified, 5 Mostly accurate, 1 Stale, 1 Incorrect"; i2 "18 claims; 14 Verified, 4 Mostly accurate"; api "1 Inconsistent, 5 Minor, 2 Informational"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:7,11,56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size counts at a94e01c7 and 57f4c871 and the verdict tallies of the three cited reports. It does not establish each finding's tier assignment.

The step 1a count gives 28 at a94e01c7 and 41 at 57f4c871. `grep '^\*\*Verdict:\*\*' | sort | uniq -c` gives i1: 1 Incorrect, 5 Mostly accurate, 1 Stale, 15 Verified. It gives i2: 4 Mostly accurate, 14 Verified. The api report's summary table (`api-consistency-review-...md:186-193`) lists F1 "Inconsistent", F2–F6 "Minor" and F7–F8 "Informational".

**Evidence:** `docs/reviews/code-fact-check-report-q160-i1.md:8-9`, `docs/reviews/code-fact-check-report-q160-i2.md:8-9`, `docs/reviews/api-consistency-review-2026-10-15-fix-q160-iteration-cap.md:184-193`

---

## Claim 4: Rubric "Rows 144-145 (`review/q085`...)" and "Rows 479, 486, 488 (`feat/build-loop-u2a4`: unit grew 381→443→540→599 ...)"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:39`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the override-log line numbers and figures. It does not establish that "still hold" is the right judgment.

`override-log.md:144-145` are `review/q085` rows (size gate excludes `docs/`; deletions count). `:479` reads "381 code lines at pr-prep step 1a and 443 after iteration 1's fixes". `:486` reads "540 code lines against main after the final pass's fixes". `:488` reads "599 code lines against main after the confirming pass's fixes". The branch appends rows only after line 825, so these line numbers are the same on main.

**Evidence:** `docs/reviews/override-log.md:144-145,479,486,488`

---

## Claim 5: Rubric I5 "Fixed: renamed, anchors updated (pr-prep x4, loop x2)"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:64`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of links to the renamed anchor in shipped docs. It does not cover `docs/reviews` artifacts, which keep the old anchor as history.

`#size-re-check-after-any-iteration-and-before-merge` appears in pr-prep 1a (`:96`), 3c (`:244`), 3e (`:254`) and 6c (`:458`), which is 4. In review-fix-loop it appears in the early split trigger (`:51`) and the iteration-4 gate (`:84`), which is 2. Searching for the old slug without `-and-before-merge` finds it only in `docs/reviews/*` (i1, i2, api and self-eval reports).

**Evidence:** `workflows/pr-prep.md:96,244,254,458`, `workflows/review-fix-loop.md:51,84`

---

## Claim 6: Override row: "The size re-check is done by hand; no script or test checks the `Size after iteration N` line or the waiver citation"

**Location:** `docs/reviews/override-log.md:829`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the name of the record the row says goes unchecked. It does not dispute the "done by hand / no test" substance, which still holds (no hits under `test/` for "Size re-check", "split PR" or "size gate").

7d61c39b (I1) moved the record out of the rubric. The loop doc now says "Note each count in the body of the commit that follows it (`Size: <count> code lines against <BASE>`)" (`workflows/review-fix-loop.md:57`). No `Size after iteration N` line remains in the rule. The row names a format the shipped rule no longer uses. It should name the commit-body `Size:` line. The rubric itself still carries `Size after iteration 0/1` lines (`rubric:7,56`). That is history, but it is a format the final rule dropped.

**Evidence:** `docs/reviews/override-log.md:829`, `workflows/review-fix-loop.md:57`

---

## Claim 7: Override rows: "Row 62's 2026-10-15 amendment and `workflows/review-fix-loop.md` (the early split trigger's own text now links the exception) carry it" and "Matches the practice of the rows above them (2026-10-14)"

**Location:** `docs/reviews/override-log.md:830-831`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the links and the placement and verdict wording of the 2026-10-14 rows. It does not establish whether the Won't-Fix is warranted.

`review-fix-loop.md:51` says "split without asking, unless the unit has grown past the [size re-check](#size-re-check-after-any-iteration-and-before-merge)'s ~800 lines, where the user decides". The 2026-10-14 row at `override-log.md:827` uses "Corrected in the fix commit" and sits at the bottom of the file.

**Evidence:** `docs/reviews/override-log.md:825-831`, `workflows/review-fix-loop.md:51`

---

## Claim 8: Plan growth table (102/842, 157/603, 217/538, 392/570, first commits 43b9edb6, d861183d, 3e58eb9c, f2533b33) and "73589cd7's and 626dc300's first commits are not the whole unit"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:8-15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every number and SHA in the table and the note about which units had feature commits after the first. It does not establish when each unit's first review ran.

All eight numbers and four SHAs reproduce (shared provenance block). c934adbc `feat(...)(U2a4)` follows d861183d (157), and 4be0445d `feat(cc-push) ... (Q-089 unit A2)` follows f2533b33 (392), as the note says.

**Evidence:** shared provenance block

---

## Claim 9: Plan: Q-120 "(U2a3b at 794) cited 'Q-104 [2]'s ~800'"; merge-msg "records 841 lines"; Q-131 "(U2a4, 540) asked ... 'against the 400 cap'"; Q-113 "(U1b, 417 after its Q-112 review fixes)" and Q-114 "(U1c, 426) were opened 2026-10-05, before Q-104 was answered (10-06)"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:17`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the quotes, numbers and dates against the archive entries. It does not establish that Q-113's 417 was growth during review rather than pre-review work; the "review fixes" label is the residue.

Q-120: "the unit sits at 794 changed code lines, at Q-104 [2]'s ~800 tolerance" (`questions-archive.md:2071`). merge-msg: "841 changed code lines against main, past ... Q-104 [2]'s ~800, under the user's waiver (Q-120 [1])" (`merge-msg-build-loop-u2a3b.md:28`). The recomputed at-merge count is 842, so the merge message is off by one from the plan table, but the plan only says what the message records. Q-131: "540 code lines against the 400 cap" (`:2256`). Q-114: "426 changed code lines after its review fixes" (`:1948`), opened 2026-10-05. Q-113: "~417 changed code lines after the Q-112 fixes" (`:1934`), opened 2026-10-05. Q-112 is "build-loop-settings-copy-rule", a design question answered in chat (`:1888-1891`), not a review. So "Q-112 review fixes" is the plan's characterization, which the archive does not establish. Precise version: "417 after the Q-112 fixes".

**Evidence:** `docs/working/questions-archive.md:1888-1891,1931-1948,2066-2071,2253-2256`, `docs/working/merge-msg-build-loop-u2a3b.md:28`

---

## Claim 10: Plan: "`skills/dev-cycle/SKILL.md:701` names 'log row 62' only as a template example ... (and it is gate code)"; "Tests that pin this text: none found"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:28-30`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the line reference and the absence of pinning tests. It does not establish what "gate code" means, which the plan leaves undefined.

`skills/dev-cycle/SKILL.md:701` reads `- log row 62: cannot tell — <what would tell>` under `### Trigger verdicts`, which is a template example. Searching `test/` for "split PR", "rule 2", "size gate" and "Size re-check" gives no hits (paraphrased — no quote available because the claim covers absence of code). "It is gate code": the file is in neither the `enforcement` nor the `host_tools` regex (`hooks/live-verify-gate.sh:83,91`), and no script or test greps "Trigger verdicts". The parenthetical cannot be confirmed as stated. This is minor and does not affect the plan.

**Evidence:** `skills/dev-cycle/SKILL.md:701`, `hooks/live-verify-gate.sh:83,91`

---

## Claim 11: Plan step 1: "new `### Size re-check (after any iteration)` ... record the count in the iteration's review artifact"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:36`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the plan's step list matches the shipped text. It does not treat the plan as normative.

The shipped heading is `### Size re-check (after any iteration and before merge)` (`review-fix-loop.md:55`). The record is "the body of the commit that follows it" (`:57`), not the review artifact. The plan's research section was updated in 57f4c871. Its step 1 still describes the a94e01c7 design, so it reads as plan-time intent, not current state.

**Evidence:** `docs/working/plan-2026-10-15-q160-size-recheck.md:36`, `workflows/review-fix-loop.md:55-57`

---

## Claim 12: completion-signals: "Did it stay within the review-fix loop's size re-check (≤ 800 changed code lines outside `docs/` after review fixes), or does the description cite the user's waiver by its `Q-NNN` entry?"

**Location:** `guides/completion-signals.md:82`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the threshold, the counting basis and the waiver citation against the owner section. It does not cover the waiver-limit nuance (a granted waiver can set a limit above 800), which the "or ... waiver" branch covers loosely.

The owner says "The check fires above 800" and "Record it ... in the PR description ... citing the `Q-NNN` entry" (`review-fix-loop.md:57,61`).

**Evidence:** `guides/completion-signals.md:82`, `workflows/review-fix-loop.md:57-61`

---

## Claim 13: quick-ref: "after each iteration and before merge, re-run step 1a's count: growth to 800 lines is tolerated; past it, stop and ask the user for a waiver (a `Q-NNN` entry), in /away mode too"

**Location:** `guides/pr-prep-quick-ref.md:53`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the owner's threshold and /away rule. "Before merge" is imprecise on the GitHub path; Claim 20 covers that.

Owner: "This holds in /away mode too" (`review-fix-loop.md:59`).

**Evidence:** `guides/pr-prep-quick-ref.md:53`, `workflows/review-fix-loop.md:57-59`

---

## Claim 14: chat-synthesis rule 2: "On the unit's first review (no rubric for the branch yet, or only a closed one: the first-pass test code-review's SKILL.md uses for the short-circuit)"

**Location:** `skills/code-review/references/chat-synthesis.md:140-142`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the paraphrase of SKILL.md's test. It does not establish rule 2's behavior when non-canonical rubrics exist or when several dated rubrics exist and only the newest is closed.

SKILL.md mechanic 6 reads: "If no canonical rubric exists yet, or the newest one is closed (`Loop closed at`; the first pass of a loop), there is no marker ... If rubrics for this branch exist but none has the canonical name, or HEAD is detached, the loop's history cannot be read" (`skills/code-review/SKILL.md:739-741`). Rule 2's "only a closed one" is narrower than SKILL's "the newest one is closed". Several dated rubric files per slug are normal (`SKILL.md:115`), and older ones are open, so with a closed newest file the literal "only a closed one" fails where SKILL's test passes. Rule 2 also leaves out the "canonical" qualifier and SKILL's third case (non-canonical rubrics: history unreadable). Precise version: "no canonical rubric for the branch yet, or the newest canonical one is closed".

**Evidence:** `skills/code-review/references/chat-synthesis.md:140-154`, `skills/code-review/SKILL.md:112-130,734-744`

---

## Claim 15: chat-synthesis rule 2: "Rule 2 does not apply on later passes ... Growth during review falls under the loop's own size re-check ... tolerates up to ~800 lines, and past that the loop stops for the user's waiver. No next action here, `merge` included, overrides that stop."

**Location:** `skills/code-review/references/chat-synthesis.md:146-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between rule 2's text and the loop's re-check, and the worked example's qualifier. It does not establish that a synthesizer emitting `merge` on a stopped unit will in practice defer to the loop; the ladder itself has no size input past rule 2.

Owner: "Past 800, the loop stops on this unit: no further fix commits, drift check, re-review or merge until the user answers" (`review-fix-loop.md:59`). The worked example now reads "1 🔴 in security, 800-line diff, first review → rule 2" (`chat-synthesis.md:184`), which agrees with the first-review restriction. Rules 3–5 have no size condition (`:154-167`). So on a later pass a unit over 800 reaches one of them, and the closing sentence is what defers to the loop. The text is consistent.

**Evidence:** `skills/code-review/references/chat-synthesis.md:140-184`, `workflows/review-fix-loop.md:59`

---

## Claim 16: pr-prep 1a: "This gate checks the unit once, at entry; the review-fix loop re-runs the same count after each iteration and before merge, and tolerates growth to ~800 lines (size re-check, Q-104 [2])"

**Location:** `workflows/pr-prep.md:96`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the link target and its agreement with the owner. "Before merge" on the GitHub path is covered in Claim 20.

The anchor resolves to `### Size re-check (after any iteration and before merge)` (`review-fix-loop.md:55`). `#1-gate-checks`, `#3-review-fix-loop`, `#hard-cap-3-iterations` and `#early-split-trigger-after-any-iteration` also resolve (`pr-prep.md:82,174`; `review-fix-loop.md:24,49`). `bats test/cross-reference-integrity.bats` passes (shared block).

**Evidence:** `workflows/pr-prep.md:96`, `workflows/review-fix-loop.md:24,49,55`

---

## Claim 17: pr-prep 3c: "After the tests, before the drift check below and the re-review, re-run step 1a's count. Past ~800 lines, stop"

**Location:** `workflows/pr-prep.md:244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering against the owner and the drift-check paragraph. It does not establish that drift-check fixes, which are committed after the re-check, get counted before the re-review. They are counted at the next re-check or at 6c.

Owner: "Re-run step 1a's command after each iteration's fix commits and tests (pr-prep 3c), before the fix-commit drift check" (`review-fix-loop.md:57`). The drift-check paragraph follows at `pr-prep.md:246`, and its findings are "Fix[ed] immediately as part of the fix batch" (`:252`; `review-fix-loop.md:116`). Those lines land after the size re-check, as the Scope notes.

**Evidence:** `workflows/pr-prep.md:242-252`, `workflows/review-fix-loop.md:57,97-116`

---

## Claim 18: pr-prep step 3 criterion: "The size re-check ran after each iteration and before merge: the unit is at most 800 ... (step 1a's command, `BASE` as in step 1a), OR the user waived it and the PR description records the waiver with its `Q-NNN` entry and the limit it grants"

**Location:** `workflows/pr-prep.md:287`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the criterion's agreement with the owner and the step order. It does not establish how an agent should tick a step 3 box that depends on a later step.

The criterion sits in step 3's completion list (`pr-prep.md:281-293`). The "before merge" run happens at 6c (`review-fix-loop.md:57`: "once more at pr-prep 6c"), three steps later (`pr-prep.md:361` `#### 6.`), and 6c has its own criterion (`:467`). At step 3's exit only the "after each iteration" half can be true. Precise version: "ran after each iteration" here, with the final run left to 6c's criterion. The record content also differs. The owner requires the record to cite "the `Q-NNN` entry with the user's answer quoted verbatim and saying whether it waives the entry gate or this re-check" (`review-fix-loop.md:61`), while this criterion asks for the entry "and the limit it grants". The two lists overlap without matching.

**Evidence:** `workflows/pr-prep.md:281-293,361,458,467`, `workflows/review-fix-loop.md:57,61`

---

## Claim 19: pr-prep 3e: "the early split trigger and the size re-check (both checked after every iteration; the size re-check again before merge) ... are owned by review-fix-loop.md § Hard cap"

**Location:** `workflows/pr-prep.md:254`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that both sections sit under `## Hard cap (3 iterations)`. Timing on the GitHub path is covered in Claim 20.

`## Hard cap (3 iterations)` is at `review-fix-loop.md:24`. `### Early split trigger` (`:49`) and `### Size re-check` (`:55`) come before the next `##` at `:97`.

**Evidence:** `workflows/review-fix-loop.md:24,49,55,69,97`

---

## Claim 20: "before merge" as the second re-check point (pr-prep 1a, 3e, step 3 criterion; quick-ref; row 62) vs the owner's "at pr-prep 6c, before the description is published (on the local-merge path, before the merge)"

**Location:** `workflows/pr-prep.md:458`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether "before merge" names the same moment as the owner's 6c point on both delivery paths. It does not establish anything about the GitHub path in practice, since this repo merges locally.

6c reads "Before publishing the description (marking the draft PR ready for review, opening the PR if no draft was made, or, on the local-merge path, running the merge) ... First, run the size re-check one last time: past ~800 lines with no waiver from the user, do not publish or merge" (`pr-prep.md:458`). This matches the owner (`review-fix-loop.md:57`). On the local path, "before merge" is exact. On the GitHub path, the run happens at publish time, and anything pushed between publishing and merge goes unchecked. The shorthand "before merge" in `pr-prep.md:96,254,287`, `guides/pr-prep-quick-ref.md:53` and `log.md:85` is right for this repo's local path but imprecise on the GitHub path. The owner's wording is the precise one.

**Evidence:** `workflows/pr-prep.md:96,254,287,458,467`, `workflows/review-fix-loop.md:57`

---

## Claim 21: review-fix-loop early split trigger: "split without asking, unless the unit has grown past the size re-check's ~800 lines, where the user decides"; iteration-4 gate: "`split` is the default when the unit has separable parts and has not grown past the size re-check's ~800 lines"

**Location:** `workflows/review-fix-loop.md:51,84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement among the two qualifiers and the precedence paragraph at the fixed 800. It does not establish behavior after a waiver has raised the limit: the precedence paragraph says "past 800", not "past the current limit", so a unit at 900 under a 1000 waiver is barred from agent splits although the loop is not stopped. This is consistent but unstated.

Precedence paragraph: "When the unit has grown past 800 during review, the agent does not split on its own ... not by the early split trigger, and not by the iteration-4 gate's /away default `split`. ... At or under 800, both splits work as written" (`:63`). Waiver paragraph: "A granted waiver sets the limit the re-check uses from then on" (`:61`).

**Evidence:** `workflows/review-fix-loop.md:51,59-65,84`

---

## Claim 22: review-fix-loop Size re-check: "`BASE` is set as in step 1a: the branch directly below this unit, or `main` once that branch has merged"; "Growth up to ~800 lines (twice the entry cap)"; "Note each count in the body of the commit that follows it ..., so the growth stays in `git log`"; "(A unit already past 800 at entry falls under step 1a, which splits it in /away mode.)"

**Location:** `workflows/review-fix-loop.md:57,63`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers BASE, the 2× arithmetic, the entry-case pointer, and the claim that commit bodies preserve the record. It does not establish what step 4 does to those bodies in a given run.

Step 1a: "`BASE=main   # a stacked unit whose lower unit has not merged yet: that unit's branch, the one directly below`" (`pr-prep.md:89`), which matches. 800 = 2 × 400. Step 1a: "In /away mode, split without asking" (`:96`), which matches the entry-case pointer. "So the growth stays in `git log`" depends on fix commits surviving. pr-prep step 4 runs `git rebase -i origin/main` and says "Squash WIP commits into logical chunks" (`pr-prep.md:298-302`), which comes after the loop and can fold the `Size:` bodies away. Precise version: the record stays in `git log` unless step 4 squashes the fix commits.

**Evidence:** `workflows/review-fix-loop.md:57,63`, `workflows/pr-prep.md:89,96,296-313`

---

## Claim 23: review-fix-loop: "Q-104 [2] says the loop 'asks you for a waiver' and, unlike its option [1], makes no /away exception"; "Q-104 [2] gives the re-measure, the ~800 tolerance and the waiver. The other details here are Q-160's reading"; "`feat/dev-cycle-digest` went from 396 to 1861 lines over 37 passes (Q-104); U2a3b went from 102 to 842 and U2a3c from 217 to 538 (Q-160)"

**Location:** `workflows/review-fix-loop.md:59,65,67`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the verbatim quote, the attribution split, and the four figures (recomputed) plus "37 passes". The "Same as [1]" inheritance reading is covered in Claim 1, and the same caveat applies here; it is labelled as Q-160's reading at `:65`.

Option [2] contains "the loop stops and asks you for a waiver" (`questions-archive.md:2020`). Q-104 evidence: "It landed at 1861 (5652d33f) after 37 review passes" (`:2015`). Counts reproduce (shared block). The list of Q-160 readings at `:65` (before-merge point, /away, precedence, waiver limits, entry waivers, count location) covers every detail in the section that is not in Q-104's text.

**Evidence:** `workflows/review-fix-loop.md:55-67`, `docs/working/questions-archive.md:2011-2020`; shared provenance block

---

## Claim 24: Commit messages: a94e01c7 "units then grew during review (102 to 842, 157 to 603, 217 to 538, 392 to 570 ...)" and "Q-113 is an entry-gate waiver"; 57f4c871 "a94e01c7's body overstates 157->603 and 392->570 ... the shipped text cites only 102->842 and 217->538"; 7d61c39b item list and "Size: 50 code lines against main"

**Location:** `docs/reviews/override-log.md:828`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the later commits' corrections and 7d61c39b's itemized claims (I1–I11, size 50). The a94e01c7 overstatement and Q-113 label are already corrected by 57f4c871's body and override row 828, so this verdict covers that the correction is accurate, not a defense of a94e01c7's original wording.

Recomputed: c934adbc and 4be0445d are feature commits that follow the first commit (shared block), so 57f4c871's correction holds. 50 at 7d61c39b reproduces. Each item in 7d61c39b's list is present in the diff: the commit-body `Size:` line (`review-fix-loop.md:57`), the waiver limit (`:61`), 6c's criterion (`pr-prep.md:467`), the renamed heading (`review-fix-loop.md:55`), the re-check before the drift check (`pr-prep.md:244`), "`BASE` as in step 1a" (`:287`), the first-pass test (`chat-synthesis.md:140-142`), both split qualifiers (`review-fix-loop.md:51,84`), the amendment in the Rationale column (Claim 2), "code lines outside `docs/`" (`completion-signals.md:82`), and two Won't-Fix rows (`override-log.md:830-831`). Override row 828 already records the Q-113 label (see Claim 9 on whether Q-113 was growth during review).

**Evidence:** `docs/reviews/override-log.md:828-831`, `workflows/review-fix-loop.md:51-84`, `workflows/pr-prep.md:244,287,467`; shared provenance block

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 6** (`docs/reviews/override-log.md:829`): the testability row names the `Size after iteration N` rubric line, which 7d61c39b replaced with the commit-body `Size:` line. Update the row's wording.

### Mostly Accurate
- **Claim 1** (`docs/decisions/log.md:85`): "[2] has none and [1] did" skips [2]'s "Same as [1]". The reading is defensible and labelled, but the inheritance question is unaddressed.
- **Claim 9** (`docs/working/plan-2026-10-15-q160-size-recheck.md:17`): "Q-112 review fixes" is the plan's label. Q-112 is a design question, and Q-113 says only "after the Q-112 fixes".
- **Claim 10** (`plan:28`): "(and it is gate code)" for `skills/dev-cycle/SKILL.md:701` is not supported: the file is in neither gate regex and no script reads that template.
- **Claim 11** (`plan:36`): plan step 1 still names the old heading and the review-artifact record.
- **Claim 14** (`chat-synthesis.md:140-142`): "only a closed one" is narrower than SKILL.md's "the newest one is closed", and it leaves out "canonical" and the unreadable-history case.
- **Claim 18** (`workflows/pr-prep.md:287`): step 3's criterion asserts the 6c (before-merge) run, which happens later. Its "limit it grants" record list also differs from the owner's "answer quoted verbatim / which gate" list.
- **Claim 20** (`workflows/pr-prep.md:458` and restatements): the "before merge" shorthand is exact only on the local path. On the GitHub path the owner's point is publish time.
- **Claim 22** (`workflows/review-fix-loop.md:57`): "stays in `git log`" holds unless pr-prep step 4's squash folds the fix commits.


### Unverifiable
(none)

## Goal-Alignment Note

The branch's goal is to write Q-104 [2] into the process, and it achieves that. The rule has one owner, every restatement links to it, all anchors resolve, the pinning suites pass, and every growth figure reproduces exactly with step 1a's command. No doc outside the excluded directories still states an entry-only rule that contradicts it. The remaining items are wording-level and none is blocking. Most of the substance is in four of them: the step 3 criterion's timing (Claim 18), the narrower first-pass test (Claim 14), the stale override-row wording (Claim 6), and the squash caveat (Claim 22). One edge the text leaves implicit: after a waiver raises the limit, the precedence paragraph still bars agent splits from 801 upward (Claim 21 Scope).
