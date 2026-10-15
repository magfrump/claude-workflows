# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q160 (branch fix/q160-iteration-cap)
**Scope:** `git diff 3c2d1174..294a7d62` (a8dc5c81, 294a7d62) and both commit messages; earlier branch commits as context only
**Checked:** 2026-10-15
Commit: 294a7d62
**Replication:** k=1 (narrow check, simplification)
**Total claims checked:** 10
**Summary:** 9 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Intent honoured: the precedence and re-entry clauses, waiver-limit fallbacks, GitHub-path re-run, homes for counts with no commit, squash rule, pre-ladder sentence and rule 2's first-pass-test parenthetical were removed on purpose and are not flagged as missing. Hallucination pattern log read (8 entries); none apply to these prose claims.

---

## Claim 1: "Q-104 [2] gives the re-measure, the ~800 tolerance and the waiver" / "(Q-104 [2], Q-160) ... after each iteration ... ~800 ... waiver entry (Q-104 [2])"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution of per-iteration re-measure, ~800 tolerance and waiver to Q-104 [2]; does not establish the Q-160 case figures (102 to 842, 217 to 538), which come from earlier commits.

Q-104's answer: `pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver.` (`docs/working/questions-archive.md:2011`). Row 62 and `workflows/review-fix-loop.md:61` attribute exactly these three to Q-104 [2].

**Evidence:** `docs/working/questions-archive.md:2008-2027`, `docs/decisions/log.md:85`, `workflows/review-fix-loop.md:61`

---

## Claim 2: "the /away reading ([2] has no /away wording, though it opens "Same as [1], but" and [1] split automatically in /away mode)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted wording of Q-104 options [1] and [2]; does not establish whether the reading itself is right (a decision, not a claim).

Option [1]: `Past 400 lines, the loop stops and the growth is split into a stacked unit (in /away mode, automatically).`; option [2]: `Same as [1], but growth up to ~800 lines is tolerated. Past that, the loop stops and asks you for a waiver.` (`docs/working/questions-archive.md:2019-2020`). [2] has no other /away wording.

**Evidence:** `docs/working/questions-archive.md:2019-2020`

---

## Claim 3: "The 6c point, /away mode and the agent not splitting the unit itself are Q-160's reading of it (decision log 62)" (and row 62's matching list)

**Location:** `workflows/review-fix-loop.md:61`, `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the section's attribution sentence accounts for every rule it states; does not establish that the unlisted rules are wrong, only that their source is unstated.

The listed items are correctly not in Q-104 (Claim 1's quote has no before-merge point, no /away wording beyond Claim 2, nothing on who splits). But the section also states `A granted waiver sets the new limit.` (`workflows/review-fix-loop.md:59`) and `Note each count in the body of the commit that follows it (\`Size: <count> code lines against <BASE>\`)` (`workflows/review-fix-loop.md:57`). Neither is in Q-104 [2], which says only that the loop "asks you for a waiver", and neither is in the Q-160 list. The previous text said "Everything else in this section is Q-160's reading", covering them (`git diff 3c2d1174..294a7d62`, removed line: `Everything else in this section is Q-160's reading of it, for example the before-merge point, /away mode, precedence over splits, waiver limits and where the count is noted.`); the new enumerated list drops "waiver limits" and "where the count is noted" while those rules remain. Row 62's list (`The before-merge point, the /away reading (...) and the agent not splitting the unit itself are Q-160's reading`) has the same gap. Precise version: add "the waiver setting the new limit and the `Size:` line" to both lists, or restore "everything else".

**Evidence:** `workflows/review-fix-loop.md:57-61`, `docs/decisions/log.md:85`, `docs/working/questions-archive.md:2011`

---

## Claim 4: Core rule stated consistently: re-measure with step 1a's command after each iteration (3c) and at 6c; past ~800 or the waiver's limit, stop for a waiver entry, /away included; the agent does not split

**Location:** `workflows/review-fix-loop.md:55-59`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wording in review-fix-loop § Size re-check, early split trigger (:53), iteration-4 gate (:80), pr-prep 1a (:96), 3c (:244), 3e (:274), step 3 criterion (:287), 6c (:458, :467), pr-prep-quick-ref.md:53, completion-signals.md:82, chat-synthesis rule 2, row 62; does not establish behaviour on re-entry into pr-prep of a unit past its limit (deliberately removed per intent).

`Re-run step 1a's command after each iteration's fix commits and tests (pr-prep 3c), before the fix-commit drift check, and once more at pr-prep 6c` and `This holds in /away mode too, and the agent does not split the unit itself` (`workflows/review-fix-loop.md:57,59`). pr-prep 3c: `After the tests, before the drift check below and the re-review, re-run step 1a's count. Past ~800 lines (or the limit a waiver set), stop and ask the user for a waiver` (`workflows/pr-prep.md:244`). 6c: `run the size re-check one last time: past ~800 lines, or past the limit a waiver set, do not publish or merge` (`workflows/pr-prep.md:458`). Early split trigger: `split without asking, unless the unit has grown past the size re-check's limit (~800 lines, or a waiver's), where the user decides` (`:53`); iteration-4 gate: `split is the default when ... within the size re-check's limit ...; otherwise (... or past that limit), the default is escalate` (`:80`). Quick-ref: `past it, stop and ask the user for a waiver (a Q-NNN entry), in /away mode too` (`guides/pr-prep-quick-ref.md:53`). completion-signals: `≤ 800 changed code lines outside docs/ after each iteration and before merge, or within a waiver's limit` (`guides/completion-signals.md:82`). No contradictions found.

**Evidence:** files and lines above

---

## Claim 5: "the step 3 criterion records the waiver as step 1a's is" / "step 3 criterion names the waiver record plainly"

**Location:** `workflows/pr-prep.md:287` (commit messages a8dc5c81, 294a7d62)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step 3 criterion's pointer to step 1a's waiver record; does not establish the local-merge mapping beyond pr-prep's "Read PR description as merge commit message" rule (`workflows/pr-prep.md:24`).

Criterion: `the PR description records the waiver with its Q-NNN entry, as step 1a describes`; step 1a: `note the waiver in the PR description (step 6), citing by ID the answered Q-NNN entry ... with the user's answer quoted verbatim` (`workflows/pr-prep.md:101`). The loop's record rule matches (`citing the Q-NNN entry with the user's answer quoted verbatim`, `workflows/review-fix-loop.md:59`).

**Evidence:** `workflows/pr-prep.md:24,101,287`, `workflows/review-fix-loop.md:59`

---

## Claim 6: "rule 2 stays first-review-only and names the loop's stop"

**Location:** `skills/code-review/references/chat-synthesis.md:140-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rule 2's text and its consistency with the loop's stop; does not establish how "first review" is detected (the first-pass-test parenthetical was removed by intent).

`On the unit's first review, ... Rule 2 does not apply on later passes of the review-fix loop: growth during review falls under the loop's size re-check (workflows/review-fix-loop.md § Size re-check), which stops the loop past its limit whatever next action this ladder derives.` Consistent with the loop's `no further fix commits, drift check, re-review or merge` (`workflows/review-fix-loop.md:59`). The ladder still has five actions (rules 1-5, `:130-162`), matching the five bracketed values at `:110`.

**Evidence:** `skills/code-review/references/chat-synthesis.md:110,128-162`

---

## Claim 7: No dangling references to removed clauses

**Location:** `workflows/review-fix-loop.md`, `workflows/pr-prep.md`, `skills/code-review/references/chat-synthesis.md`, `guides/pr-prep-quick-ref.md`, `guides/completion-signals.md`, `docs/decisions/log.md:85`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers grep hits for precedence, headroom, re-enter, "which gate it waives", "before merging on the GitHub path", squash, pre-ladder, first-pass test, "(above)" in the touched files and test/scripts/hooks; does not establish absence in docs/reviews or docs/working artifacts (historical).

paraphrased — no quote available because the claim covers absence of matches: `rg -i "precedence|headroom|re-enter|which gate it waives|before merging on the GitHub|squash|pre-ladder|first-pass test"` over the touched files hits only unrelated text (override-log precedence at `workflows/review-fix-loop.md:209` and `workflows/pr-prep.md:195`; WIP-squash at `workflows/pr-prep.md:302,310` and `guides/pr-prep-quick-ref.md:62`). Rule 2's old "(above)" pointer is replaced by the explicit § link. No test pins removed phrases (`rg` over `test/ scripts/ hooks/` found no Q-160/re-check matches relevant to this text).

**Evidence:** `workflows/review-fix-loop.md:209`, `workflows/pr-prep.md:195,302,310`, `guides/pr-prep-quick-ref.md:62`

---

## Claim 8: Anchors resolve

**Location:** `workflows/pr-prep.md:96,244,274,458`, `workflows/review-fix-loop.md:53,57,80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `#size-re-check-after-any-iteration-and-before-merge`, `#early-split-trigger-after-any-iteration`, `pr-prep.md#1-gate-checks`, `#hard-cap-3-iterations`; does not establish rendering on any particular markdown host.

Headings: `### Early split trigger (after any iteration)` (`workflows/review-fix-loop.md:49`), `### Size re-check (after any iteration and before merge)` (`:55`), `## Hard cap (3 iterations)` (`:24`), `#### 1. Gate checks` (`workflows/pr-prep.md:82`); GitHub-style slugs match each link.

**Evidence:** `workflows/review-fix-loop.md:24,49,55`, `workflows/pr-prep.md:82`

---

## Claim 9: "Size: 43 code lines against main."

**Location:** commit a8dc5c81 body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at a8dc5c81 and HEAD against main (merge-base b279a2ba = main); does not establish counts at other commits.

Command (cwd `/workspace/.claude/wt-q160`, 2026-10-15, exit 0): `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n+0}'` printed `43`; the same against `main...a8dc5c81` printed `43`. Per file: completion-signals 1+1, pr-prep-quick-ref 1+0, chat-synthesis 9+5, pr-prep 7+3, review-fix-loop 13+3. Output quoted inline per the caller's instruction (no execution-log file).

**Evidence:** command output above

---

## Claim 10: Commit a8dc5c81 Notes: "The early split trigger's and iteration-4 gate's one-clause links to the limit stay ... Row 62's revisit trigger (two waivers in 14 days) stays"

**Location:** commit a8dc5c81 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of the two links and the trigger; does not establish Q-A/Q-B coordinator answers (not in repo files checked).

Links at `workflows/review-fix-loop.md:53` and `:80` (quoted in Claim 4). Row 62: `revisit if two or more units need a waiver past the in-loop ~800 re-check within any 14 days` (`docs/decisions/log.md:85`).

**Evidence:** `workflows/review-fix-loop.md:53,80`, `docs/decisions/log.md:85`

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 3** (`workflows/review-fix-loop.md:61`, `docs/decisions/log.md:85`): the enumerated Q-160-reading list no longer covers "a granted waiver sets the new limit" or the `Size:` commit-body line, which Q-104 [2] does not supply either; add them to both lists or restore "everything else in this section".
