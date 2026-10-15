Commit: 57f4c871

# API Consistency Review — fix/q160-iteration-cap

**Scope:** `git diff main...HEAD` (HEAD 57f4c871): `workflows/review-fix-loop.md`, `workflows/pr-prep.md`, `guides/pr-prep-quick-ref.md`, `guides/completion-signals.md`, `skills/code-review/references/chat-synthesis.md`, `docs/decisions/log.md` row 62, `docs/reviews/override-log.md`
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report-q160-i2.md` (its four findings are not re-filed here: step 3's "same `BASE`", the override-row verdict and position, chat-synthesis's undefined "first review", and the precedence exception being stated in one place only)

## Baseline Conventions

In this repo the public surface is the rule text that agents follow. The conventions this diff should match are:

- **One owner per rule; the other docs link to it.** `review-fix-loop.md` opens with "Each rule is stated in one place; the others link to it." pr-prep owns the step sequence, review-fix-loop owns the control rules, and code-review's `references/rubric.md` owns the rubric file's format ("**Use this exact format.**", pinned by `test/skills/code-review-format-contract.bats`).
- **Thresholds are written as a round number with a "~", and the gate is strict.** Step 1a has "hard cap: ~400", "The gate fires above 400: the '~' marks a round number, not a tolerance band", and its checklists use "≤ 400" / "at most 400".
- **Control-rule headings carry a parenthetical saying when the rule runs.** The existing one is `### Early split trigger (after any iteration)`.
- **A waiver is cited by ID.** Step 1a says: "citing by ID the answered `Q-NNN` entry … with the user's answer quoted verbatim; a waiver with no such entry is not a waiver."
- **Iterations are numbered 1–3.** The per-iteration header is `Iteration N of 3`, "where `N` is `1`, `2`, or `3`".
- **Decision-log amendments go in the Rationale column.** Rows 53 and 60 (log lines 76 and 83) put `**Amended YYYY-MM-DD (Q-NNN …):**` in column 4, Rationale.
- **Rubric lines under the header:** the `Commit:` line comes first, then marker lines (`Loop-pass short-circuit: used at <sha>`, `Loop closed at <sha>`) directly under it. A new dated file copies them forward.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| "Size re-check" (rule name / heading `### Size re-check (after any iteration)`) | rule heading | "Early split trigger (after any iteration)", "Size gate" (step 1a), "Iteration 4: cap-exceeded decision gate" | `workflows/review-fix-loop.md:49,67`; `workflows/pr-prep.md:84` | Mostly consistent. The name is used the same way in all six docs. The parenthetical leaves out the before-merge run, which 6c links to by this anchor (F5). |
| `Size after iteration N: <count> code lines against <BASE>` | rubric line | `Commit: <sha>`, `Loop-pass short-circuit: used at <sha>`, `Loop closed at <sha>` | `skills/code-review/references/rubric.md:17-27` | Inconsistent. The format owner (rubric.md) does not define it, and the branch's own use does not match it (F1). |
| `~800` / "above 800" / "Past 800" | threshold | `~400` / "above 400" / "≤ 400" | `workflows/pr-prep.md:84,96,155` | Consistent with step 1a's pattern (F7, informational). |
| `Needs: you: judgment` waiver entry | questions.md route | the routes in the global CLAUDE.md | `docs/working/questions.md` grammar | Consistent. |
| `**Amended 2026-10-15 (Q-104 [2], Q-160):**` | decision-log amendment | the Amended notes in rows 53 and 60 | `docs/decisions/log.md:76,83` | Inconsistent placement: it is in the Decision column, not Rationale (F6). |
| "Size re-check" quick-ref bullet | checklist item | "Size gate" bullet | `guides/pr-prep-quick-ref.md:11` | The name is consistent, but the bullet leaves out the PR-description citation that the sibling bullet has (F4). |

## Findings

#### F1. The rubric line `Size after iteration N` is not in the rubric format, and the branch's own first use does not match its spec

**Severity:** Inconsistent
**Location:** `workflows/review-fix-loop.md:57`; `skills/code-review/references/rubric.md:14-27`; `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:9`
**Move:** 2 (naming against the grain), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Precedent: rubric header/marker lines are defined in `skills/code-review/references/rubric.md:17-27` (`Commit:`, `Loop-pass short-circuit: used at <sha>`, `Loop closed at <sha>`), with format pinned by `test/skills/code-review-format-contract.bats`

Evidence:
- review-fix-loop.md:57: "Add each count to the loop's rubric as its own line (`Size after iteration N: <count> code lines against <BASE>`), kept when the rubric is updated in place"
- rubric.md:41: "**Use this exact format.** … changes to the template here must be mirrored there in the same commit."
- rubric.md:16-17: "A new date mid-loop is a continuation, not a new review: the new file copies the `Commit:` stamp and any marker line from the previous one."
- branch rubric line 9: "Size after iteration 0 (entry, step 1a): 28 code lines against main."

review-fix-loop gives the rubric file a new line, but rubric.md owns that file's format. rubric.md does not mention the line, says nothing about where it goes, and does not include it in what a new dated file copies forward. Under rubric.md's own continuation rule, the size history would therefore be lost at a date rollover, although the reason given for the line is "so later passes and the audit trail can see the growth". The spec also does not say what `N` to write for the before-merge run, which is not an iteration. The branch's first use already differs from the spec: it uses an `iteration 0`, while `Iteration N of 3` defines N as 1–3; it adds a `(entry, step 1a)` qualifier; and it ends with a trailing period. An agent grepping for the spec'd shape gets inconsistent hits.

**Recommendation:** Define the line in rubric.md, next to the marker-line rules. State where it goes (for example, after the marker lines), that a new dated file copies it forward, and the labels for the entry count and the before-merge count (for example `Size at entry:` and `Size before merge:`, or name `iteration 0` explicitly). Then make the branch rubric match. Check whether `rubric-current-format.md` and its bats contract need the line too.

#### F2. After a waiver past 800, nothing says what bound applies

**Severity:** Minor
**Location:** `workflows/review-fix-loop.md:59-61`
**Move:** 3 (consumer contract), 8 (nullability: an undefined state)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
- review-fix-loop.md:59: "Past 800, the loop stops on this unit: no further fix commits, re-review or merge until the user answers a waiver entry"
- review-fix-loop.md:61: "A waiver granted for the entry count does not lift this check unless its answer says so."

The text covers one direction: an entry waiver does not carry over to the re-check. It does not cover what happens after a re-check waiver is granted at, say, 842 lines, when the loop goes on and the unit reaches 1,500. If the waiver is open-ended, the bound is gone again, and that is the Q-104 failure this branch exists to prevent (396 to 1861). If it is not open-ended, the agent re-runs the check "after each iteration" and has no stated ceiling to compare against, so it will either stop on every iteration or never stop. Each count after a waiver will meet this case.

**Recommendation:** Add one sentence. One option: "A waiver sets the unit's new ceiling at the count it was granted for, plus the 400-line tolerance, unless its answer names another number." Another: the waiver entry's options must state a number.

#### F3. "Before merge" (review-fix-loop) and "before publishing" (6c) are different moments on the GitHub path, and 6c's own checklist does not include the check

**Severity:** Minor
**Location:** `workflows/review-fix-loop.md:57`; `workflows/pr-prep.md:458`, `:474`
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
- review-fix-loop.md:57: "and again before the unit merges (pr-prep 6c)"
- pr-prep.md:458: "Before publishing the description (marking the draft PR ready for review, opening the PR if no draft was made, or, on the local-merge path, running the merge), answer these three questions about the description as written. First, run the size re-check one last time"
- pr-prep.md:474: "- [ ] Description gate (6c) passed: why is stated, specific tests listed, uncertainty flagged — or description was revised until all three are yes"

6c runs at merge time only on the local-merge path. On the GitHub path it runs when the PR is published, and commits that answer human review can come after that and before the actual merge. So "before the unit merges (pr-prep 6c)" names a point that 6c does not guarantee on that path. Separately, 6c is still introduced as "three questions" though it now has a precondition in front of them, and step 6's completion criterion for 6c lists only the three questions. A checklist reader can mark 6c passed without having run the size re-check.

**Recommendation:** Add "size re-check passed or waived" to the 6c completion criterion. Then either reword review-fix-loop to "before the PR is published, or before the merge on the local-merge path", or add the re-check to the GitHub merge step. Since this repo uses the local-merge path, the cheap fix is the wording.

#### F4. Waiver citations are worded differently across the docs

**Severity:** Minor
**Location:** `guides/pr-prep-quick-ref.md:53`; `guides/completion-signals.md:82`; `workflows/review-fix-loop.md:61`; `workflows/pr-prep.md:101`, `:287`
**Move:** 2/3 (terminology and contract drift)
**Confidence:** High
**Legibility-target:** for-author

Precedent: step 1a's citation rule, `workflows/pr-prep.md:101` ("citing by ID the answered `Q-NNN` entry … with the user's answer quoted verbatim; a waiver with no such entry is not a waiver"), mirrored by the quick-ref size-gate bullet at `guides/pr-prep-quick-ref.md:11` ("note the waiver in the PR description, citing that `Q-NNN`")

Evidence:
- quick-ref:53: "past it, stop and ask the user for a waiver (a `Q-NNN` entry), in /away mode too" (it never says the waiver is recorded in the PR description)
- completion-signals:82: "or does the description cite the user's waiver?" (no `Q-NNN`, unlike the first sentence of the same item)
- review-fix-loop.md:61: "citing the `Q-NNN` entry with the user's answer quoted" (drops "verbatim")

The rule says "as step 1a records one", but none of the three restatements carries step 1a's wording in full. None of them says how to tell a re-check waiver from an entry waiver in the description either, although line 61 makes that difference matter: "A waiver granted for the entry count does not lift this check". Two waivers on one unit will look the same.

**Recommendation:** In the quick-ref bullet, add "note it in the PR description, citing that `Q-NNN`", to match line 11. In completion-signals, write "cite the user's waiver by its `Q-NNN` entry". Keep "verbatim" in review-fix-loop. Optionally, ask for a label such as "Size re-check waiver: Q-NNN" so the two kinds of waiver can be told apart.

#### F5. The heading says "(after any iteration)", but the rule also runs before merge, and 6c links to it by that anchor

**Severity:** Minor
**Location:** `workflows/review-fix-loop.md:55`; `workflows/pr-prep.md:458`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `### Early split trigger (after any iteration)` in `workflows/review-fix-loop.md:49`, where the parenthetical gives the rule's full timing

Evidence:
- review-fix-loop.md:55: "### Size re-check (after any iteration)"
- pr-prep.md:458: "run the [size re-check](review-fix-loop.md#size-re-check-after-any-iteration) one last time"

The sibling heading's parenthetical describes its rule fully. This one leaves out the merge-time run, so the 6c link reads as "after any iteration" at a point where no iteration is running. Readers who skim headings will miss the before-merge obligation. Changing the heading also changes the anchor, which is used in five places (pr-prep 1a, 3c, 3e and 6c, plus chat-synthesis), so this is cheap to fix now and more expensive later.

**Recommendation:** Rename the heading to `### Size re-check (after any iteration and before merge)` and update the five links. Or leave it, if keeping the anchor stable matters more.

#### F6. Row 62's amendment is in the Decision column; earlier amendments are in Rationale

**Severity:** Minor
**Location:** `docs/decisions/log.md:85`
**Move:** 1/2 (convention placement)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `**Amended …:**` notes in the Rationale column (column 4) of rows 53 and 60, `docs/decisions/log.md:76,83`

Evidence:
- log.md:85 (Decision column): "… both by user decision after the review loop, 2026-09-28. **Amended 2026-10-15 (Q-104 [2], Q-160):** the cap is re-checked inside the review-fix loop too."

Both earlier amendments went in the Rationale column. This one is in the Decision column. The branch also rewrites a Rationale sentence in place: the revisit trigger "if units under the cap still balloon during review" is replaced. Both changes are defensible, since the amendment changes the decision itself. But a reader who scans the Rationale column for "Amended" (the existing practice) will miss it.

**Recommendation:** Either move the amendment into Rationale to match rows 53 and 60, or keep it in Decision and put a one-line "Amended 2026-10-15: see Decision" pointer in Rationale. Not blocking.

#### F7. Thresholds are written as "~800", "800", "to 800", "above" and "past"; the meaning is consistent

**Severity:** Informational
**Location:** review-fix-loop.md:57,59; pr-prep.md:96,244,287,458; quick-ref:53; completion-signals:82; chat-synthesis.md:146-147; log row 62
**Move:** 2
**Confidence:** High
**Legibility-target:** for-author

Precedent: step 1a's "~400" in the rule, "above 400" for the trigger and "≤ 400" / "at most 400" in checklists, `workflows/pr-prep.md:84,96,155`

Evidence: "Growth up to ~800 lines … The check fires above 800" (review-fix-loop); "growth to 800 lines is tolerated; past it" (quick-ref); "≤ 800 lines after review fixes" (completion-signals); "Past ~800 lines, stop" (pr-prep 3c).

Every occurrence describes the same strict bound, with 800 allowed and 801 not, which matches step 1a's 400 pattern. Only one small mismatch: completion-signals' "≤ 800 lines after review fixes" drops "code lines outside `docs/`", which the first sentence of the same item keeps, and "after review fixes" reads as if only the fixes are counted. The count is the whole unit.

**Recommendation:** In completion-signals, write "≤ 800 changed code lines outside `docs/`, re-counted after each iteration". Nothing else needs to change.

#### F8. pr-prep 3c puts both the size re-check and the drift check at the same point

**Severity:** Informational
**Location:** `workflows/pr-prep.md:244`, `:246`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
- pr-prep.md:244: "**Size re-check.** After the tests and before the re-review, re-run step 1a's count."
- pr-prep.md:246: "**Fix-commit drift check (decision 031, L=fix-drift).** After fixes and tests, before the re-review pass, run the lite reviewer"

Both checks are placed in the same slot. Text order suggests the size check runs first, which is the right order: past 800, the drift reviewer should not run either, because review-fix-loop forbids further "re-review". But the text does not say this.

**Recommendation:** Add "run it before the drift check; past 800, skip the drift check too" to the size re-check paragraph, or leave it to text order.

## What Looks Good

- **The name "size re-check" is used the same way everywhere:** the heading, the pr-prep 3c paragraph, the 3e and 6c links, the quick-ref bullet, the completion-signals item, chat-synthesis rule 2 and log row 62 ("in-loop ~800 re-check"). I found no "size cap"/"size gate" confusion: "size gate" stays the entry check and "re-check" is the in-loop one.
- **Single ownership is kept.** review-fix-loop's ownership paragraph adds the size re-check to its list, and pr-prep 3c, 3e and 6c, the quick-ref and chat-synthesis link to it rather than restating it, which matches the early split trigger's pattern.
- **The threshold follows step 1a's convention:** "~" means a round number, "above N" is the trigger, and "≤ N" is used in checklists. The text says this explicitly ("as in step 1a the '~' marks a round number").
- **The waiver uses existing questions.md machinery** (`Needs: you: judgment`, a cited `Q-NNN`) rather than a new channel.
- **chat-synthesis rule 2's worked example was updated in the same change** ("800-line diff, first review → rule 2"), so the example table still matches the rule.
- **The amendment format in row 62** (`**Amended YYYY-MM-DD (Q-NNN [n], …):**`) matches rows 53 and 60, apart from the column (F6).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | The `Size after iteration N` rubric line is not in rubric.md's format, is not copied to a new dated file, and the branch's use (`iteration 0 (entry, step 1a)`, trailing period) differs from the spec | Inconsistent | `workflows/review-fix-loop.md:57`; `skills/code-review/references/rubric.md:14-27` | High |
| F2 | No bound is stated after a re-check waiver is granted | Minor | `workflows/review-fix-loop.md:59-61` | Medium |
| F3 | "Before merge" (pr-prep 6c) is publish time on the GitHub path; the 6c completion criterion does not include the size check | Minor | `workflows/pr-prep.md:458,474` | Medium |
| F4 | Waiver-citation wording drifts (quick-ref leaves out the PR description, completion-signals leaves out `Q-NNN`, "verbatim" is dropped); entry and re-check waivers cannot be told apart | Minor | quick-ref:53; completion-signals:82; review-fix-loop.md:61 | High |
| F5 | Heading/anchor "(after any iteration)" leaves out the before-merge run that 6c links to | Minor | `workflows/review-fix-loop.md:55` | Medium |
| F6 | Row 62's amendment is in the Decision column; earlier amendments are in Rationale | Minor | `docs/decisions/log.md:85` | High |
| F7 | Threshold wordings differ but mean the same; completion-signals drops "code lines outside `docs/`" | Informational | completion-signals:82 | High |
| F8 | pr-prep 3c puts the size re-check and the drift check at the same point | Informational | `workflows/pr-prep.md:244-246` | Medium |

## Overall Assessment

The branch is consistent with the repo's conventions where it matters most. "Size re-check" is used the same way in every doc, the rule has one owner that the others link to, and the 800 threshold follows step 1a's "~N / above N / ≤ N" pattern exactly. The one Inconsistent finding (F1) is a contract gap between docs. review-fix-loop defines a new rubric line, but rubric.md, which owns that file's format, is not updated. As a result the line is not copied forward when a new dated rubric file is started, and the branch's own first use already departs from the spec. That is fixable in place in about two sentences in rubric.md plus a one-line correction in the branch rubric. The Minor findings (F2 to F6) are wording gaps that an agent will hit only in edge states: after a waiver, on the GitHub path, or when two waivers exist on one unit. F2, the missing bound after a waiver, is the one most worth closing before merge, because without it the Q-104 failure can come back through a waiver. Nothing here breaks an existing consumer.
