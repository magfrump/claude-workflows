Commit: 8834b1a1

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q160`, branch `fix/q160-iteration-cap`)
**Scope:** fix commit only: `git diff 1a118c80..8834b1a1` (workflows/pr-prep.md, workflows/review-fix-loop.md, guides/completion-signals.md, skills/code-review/references/chat-synthesis.md, docs/reviews/override-log.md, the rubric's "Narrow check" section) and the commit message of 8834b1a1; `code-fact-check-report-q160-narrow.md` is context
**Checked:** 2026-10-15
**Total claims checked:** 11
**Summary:** 7 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable
**Replication:** k=1 (narrow check 2)

Partial-scope label: commits before 1a118c80 are context only, not under review. Execution evidence is quoted inline because the brief said not to write execution-log files. Items the rubric or override log already record as Won't-Fix or immutable (N8, the override rows) are not re-filed.

---

## Claim 1: N2: step 1a "tolerates growth to ~800 lines, or the limit a waiver sets"

**Location:** `workflows/pr-prep.md:96`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement of step 1a's tolerance wording with the loop doc's limit rule; does not establish the waiver-recording details.

Step 1a now reads "tolerates growth to ~800 lines, or the limit a waiver sets" (`workflows/pr-prep.md:96`). The loop doc says "The unit's limit is ~800 lines (twice the entry cap) until a waiver sets another." (`workflows/review-fix-loop.md:57`). They agree.

**Evidence:** `workflows/pr-prep.md:96`, `workflows/review-fix-loop.md:57`

---

## Claim 2: N1: step 1a "In /away mode, split without asking (unless the unit grew past that limit under an earlier loop, where the size re-check's stop applies)"

**Location:** `workflows/pr-prep.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the qualifier's agreement with the loop doc's precedence paragraph; does not establish how step 1a's reader tells that a loop has run (step 1a only links; the rubric test lives in the loop doc).

"that limit" refers back to "~800 lines, or the limit a waiver sets" in the same paragraph. The loop doc: "Step 1a's /away split does not reach a unit that grew past its limit under review: when such a unit re-enters pr-prep ... it stays under this stop" (`workflows/review-fix-loop.md:63`). The early split trigger (`:53`) and the iteration-4 gate (`:84`) use the same "past the limit, the user decides" carve-out. Consistent.

**Evidence:** `workflows/pr-prep.md:96`, `workflows/review-fix-loop.md:53`, `workflows/review-fix-loop.md:63`, `workflows/review-fix-loop.md:84`

---

## Claim 3: N3: step 3 criterion "at most 800 changed code lines (...), OR the user waived it, the unit is within the waiver's limit, and the PR description records the waiver with its `Q-NNN` entry and the limit it grants"

**Location:** `workflows/pr-prep.md:287`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the N3 fixes (waived branch now requires the description record; stray comma gone); does not establish that the listed record fields match the loop doc's full list.

N3 is fixed: the waiver's limit now sits inside the OR branch with the record, and the comma is gone. But the record the criterion checks is shorter than the one the loop doc requires: "citing the `Q-NNN` entry with the user's answer quoted verbatim, the limit it grants, and whether it waives the entry gate or this re-check" (`workflows/review-fix-loop.md:61`). The criterion checks only the `Q-NNN` entry and the limit, so a description missing the verbatim answer and which gate is waived passes it. Precise version: "...records the waiver as the size re-check requires (its `Q-NNN` entry, the answer quoted, the limit, and which check it waives)".

**Evidence:** `workflows/pr-prep.md:287`, `workflows/review-fix-loop.md:61`

---

## Claim 4: N1: "Every other unit goes through step 1a as written, including one that grew under review but stays within the limit, and one past 800 before any loop has run on it."

**Location:** `workflows/review-fix-loop.md:63`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the sentence's agreement with step 1a and the precedence rule for a new loop; does not establish what the authors intend for a resumed session of the same loop.

The fix answers the earlier gap (a re-entering unit between 400 and 800 had no /away action) by sending it through step 1a, which splits in /away above 400. For a new loop that is a coherent reading. But the same paragraph names "in a resumed session" as a re-entry case, and a session resumed mid-loop on a unit that grew to, say, 600 lines would now split under step 1a, while the same loop continuing in the original session tolerates it to ~800 ("tolerates growth to ~800 lines", `workflows/pr-prep.md:96`; "This gate checks the unit once, at entry", same line). Whether the loop continues or splits then depends on whether the session was resumed. Precise version: limit the step 1a route to a unit starting a new loop, or say that a resumed session continuing an open loop (open rubric) skips step 1a and stays under the size re-check.

**Evidence:** `workflows/review-fix-loop.md:63`, `workflows/pr-prep.md:96`

---

## Claim 5: N6: completion-signals "with any waiver cited by its `Q-NNN` entry"

**Location:** `guides/completion-signals.md:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "any waiver" wording and the ≤ 800 / waiver-limit restatement; does not establish the other checklist items.

The line reads "(≤ 800 changed code lines outside `docs/` after each iteration and before merge, or within a waiver's limit), with any waiver cited by its `Q-NNN` entry" (`guides/completion-signals.md:82`). It no longer implies a waiver always exists and matches the loop doc's limit rule (`workflows/review-fix-loop.md:57`).

**Evidence:** `guides/completion-signals.md:82`, `workflows/review-fix-loop.md:57`

---

## Claim 6: N4: "On every later pass of the review-fix loop (the first review falls under rule 2 and pr-prep step 1a), the loop's size re-check ... comes before this ladder"

**Location:** `skills/code-review/references/chat-synthesis.md:128`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the loop doc's after-iteration re-check; does not establish the before-merge (6c) case for a loop that ends on its first pass.

The after-iteration part is right: the re-check runs "after each iteration's fix commits and tests" (`workflows/review-fix-loop.md:57`), so it precedes passes 2+. But the loop doc also runs it "once more at pr-prep 6c, before the description is published (on the local-merge path, before the merge)" (same line), whatever the pass number. The parenthetical hands the first review to rule 2 and step 1a, and neither covers a unit whose entry gate the user waived at a size above 800: rule 2 needs a 🔴 and needs "the user has waived neither the cap nor the size re-check" (`chat-synthesis.md:143-145`), and "A waiver of the entry gate does not lift this check unless its answer says so" (`workflows/review-fix-loop.md:61`). Such a unit with 0 🔴 derives `merge` on its first pass with no stated stop in this file, although 6c would stop it. Precise version: "before this ladder on every later pass, and before any `merge` (pr-prep 6c)", or keep "no next action below, `merge` included, overrides that stop" outside the later-pass qualifier.

**Evidence:** `skills/code-review/references/chat-synthesis.md:128`, `skills/code-review/references/chat-synthesis.md:140-148`, `workflows/review-fix-loop.md:57`, `workflows/review-fix-loop.md:61`, `workflows/pr-prep.md:458`

---

## Claim 7: N5: rule 2 "no canonical rubric for the branch before this pass, or the newest one is closed: the first-pass test of code-review's SKILL.md first-red short-circuit, mechanic 6"

**Location:** `skills/code-review/references/chat-synthesis.md:140-142`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation's target and wording match; does not establish rule 2's behavior when the loop history cannot be read.

The citation now points at the right place. Mechanic 6 says:

```
// skills/code-review/SKILL.md:739-742
   The run still implies `--no-gate` and k=1. If no canonical rubric exists yet, or the newest one is closed (`Loop closed at`; the first
   pass of a loop), there is no marker, so the short-circuit is allowed. If rubrics for this
   branch exist but none has the canonical name, or HEAD is detached, the loop's history cannot
   be read, so do not short-circuit.
```
(excerpt ends :742; enclosing mechanic 6 continues to :745 — read)

The wording matches. The residue from the previous narrow check's Claim 13 ("the unreadable-history case is still missing") was not addressed and is not recorded in the rubric: N5's row reads only "Fixed: cites mechanic 6". Mechanic 6 treats unreadable history (non-canonical rubrics, detached HEAD) as a third case. Rule 2's test does not mention it, so a pass with only non-canonical rubrics reads as "no canonical rubric", meaning a first review, while mechanic 6, the test it cites, says the history cannot be read. Precise version: add the unreadable case (for example "if the history cannot be read, as mechanic 6 defines, treat the pass as not first"), or record the residue as Won't-Fix.

**Evidence:** `skills/code-review/references/chat-synthesis.md:140-142`, `skills/code-review/SKILL.md:735-745`, `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:112`

---

## Claim 8: chat-synthesis's ladder keeps five actions

**Location:** `skills/code-review/references/chat-synthesis.md:130-163`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and names of ladder rules after the edit; does not establish other files' copies of the ladder.

The ladder still lists rules 1-5: "block on architectural review", "split PR", "escalate to /pre-mortem", "fix red items then re-review", "merge" (`chat-synthesis.md:130,140,151,156,160`). The commit changes only the pre-ladder sentence and rule 2's citation (paraphrased — no quote available because this is a claim about absence of other changes, confirmed by the 6-line chat-synthesis hunk in `git diff 1a118c80..8834b1a1`).

**Evidence:** `skills/code-review/references/chat-synthesis.md:128-163`

---

## Claim 9: N7: override row "the agent's reading of \"code lines\" recorded in row 62 when Q-085 [3] was applied (override row 144)"

**Location:** `docs/reviews/override-log.md:832`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution against decision log row 62 and override row 144; does not re-verdict the Won't-Fix itself.

Row 62's rationale says "User answer to Q-085 ([3])" and "`docs/` is left out so review artifacts and working notes don't count, while `skills/` and `workflows/` markdown, this repo's product, do (agent's reading of \"code lines\")" (`docs/decisions/log.md:85`). Override row 144 is the 2026-09-28 `review/q085` Won't-Fix on excluding all of `docs/` (`docs/reviews/override-log.md:144`). The attribution is accurate.

**Evidence:** `docs/reviews/override-log.md:832`, `docs/reviews/override-log.md:144`, `docs/decisions/log.md:85`

---

## Claim 10: Rubric narrow-check section: "20 claims; 12 Verified, 8 Mostly accurate, 0 Incorrect", range 7d61c39b..1a118c80, N1-N8 rows

**Location:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:102-115`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers counts, range and the N-row to claim mapping; does not establish that each "Fixed" status fully clears its claim (see Claims 4, 6, 7).

The narrow report's header reads "**Total claims checked:** 20" and "**Summary:** 12 verified, 8 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable", with scope "`git diff 7d61c39b..1a118c80`" (`code-fact-check-report-q160-narrow.md:6-8`). Its Mostly-accurate claims 6, 8, 10, 11, 12, 13, 17 and 20 map to N1, N2, N3, N6, N4, N5, N7 and N8 (paraphrased — no quote available because the mapping is drawn from eight separate rows of the report's attention section).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-15-fix-q160-iteration-cap.md:102-115`, `docs/reviews/code-fact-check-report-q160-narrow.md:6-8`, `docs/reviews/code-fact-check-report-q160-narrow.md:320-330`

---

## Claim 11: Commit body "Size: 50 code lines against main."

**Location:** commit 8834b1a1 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers step 1a's count at 8834b1a1 against current main; does not establish other commits' `Size:` lines.

Command (cwd `/workspace/.claude/wt-q160`, 2026-10-15, exit 0): `git diff --numstat main...8834b1a1 -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'`. Output: `50`. HEAD is 8834b1a1, and the merge-base with main is `b279a2ba`, main's tip. Output is quoted inline in place of a log file because the brief said not to write execution-log files.

**Evidence:** `workflows/pr-prep.md:91` (the command), inline output above

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 3** (`workflows/pr-prep.md:287`): the waived branch checks only the `Q-NNN` entry and the limit; the loop doc's record also requires the answer quoted verbatim and which check is waived.
- **Claim 4** (`workflows/review-fix-loop.md:63`): "including one that grew under review but stays within the limit" sends a session resumed mid-loop at 400-800 lines through step 1a's /away split, while the same loop in its original session tolerates the size to ~800. Restrict this to a new loop, or exempt a resumed open loop.
- **Claim 6** (`chat-synthesis.md:128`): "every later pass" drops the 6c before-merge stop for a loop that ends on its first pass. Neither rule 2 nor step 1a covers an entry-waived unit above 800 with 0 🔴, which derives `merge`. Keep the "no next action, `merge` included, overrides" clause unqualified, or name 6c.
- **Claim 7** (`chat-synthesis.md:140-142`): the citation is now right, but the unreadable-history case in mechanic 6 (non-canonical rubrics, detached HEAD) is still missing from rule 2's first-pass test, and the rubric's N5 row does not record it.
