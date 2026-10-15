# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q160 (claude-workflows)
**Scope:** branch diff `main...HEAD` on `fix/q160-iteration-cap` (7 files, markdown only) plus the commit message of a94e01c7; restatements of the old rule grepped repo-wide outside `docs/reviews`, `docs/working`, `archive`, `runs`
**Commit:** a94e01c7
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-15
**Total claims checked:** 22
**Summary:** 15 verified, 5 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Hallucination pattern log read (`docs/reviews/hallucination-patterns.md`); no claim below matches a logged pattern, and every figure reproduced, so no entry is added.

Execution logs (both under `docs/reviews/execution-logs/`, cwd `/workspace/.claude/wt-q160`):
- `q160-i1-factcheck-growth.log` — growth recompute with step 1a's count, `git diff --numstat <merge-base> <commit> -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n+0}'`, per commit of each merged branch (`git log --reverse <mb>..<merge>^2`), plus Q-104's two endpoints; exit 0; 2026-10-15T07:24:17Z.
- `q160-i1-factcheck-bats.log` — `timeout 300 bats test/cross-reference-integrity.bats test/workflow-required-sections.bats test/skills/code-review-assurance-contract.bats`; exit 0, 0 `not ok`; 2026-10-15T07:22:38Z.

---

## Claim 1: "After each iteration's fix commits and before merge, the loop re-runs step 1a's count against the same base; growth up to ~800 lines is tolerated, and past 800 the loop stops until the user answers a waiver entry, in /away mode too (`workflows/review-fix-loop.md` § Size re-check)."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between row 62's amendment and the new review-fix-loop section; does not establish that the content came from Q-104 (Claim 9) or that the section heading anchor is linked from the row (it is cited by name, not link).

The target section says: `After each iteration's fix commits, and again before the unit merges, re-run step 1a's command with the same BASE. Growth up to ~800 lines (twice the entry cap) is tolerated. The check fires above 800` (`workflows/review-fix-loop.md:57`) and `Past 800, the loop stops on this unit ... until the user answers a waiver entry ... This holds in /away mode too` (`workflows/review-fix-loop.md:59`). The section exists as `### Size re-check (after any iteration)` (`workflows/review-fix-loop.md:55`).

**Evidence:** `docs/decisions/log.md:85`, `workflows/review-fix-loop.md:55-61`

---

## Claim 2: "The second trigger ... fired twice (Q-104: 396 to 1861 lines; Q-160: 102 to 842, 217 to 538)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four numbers, recomputed with step 1a's count from each branch's merge base, and that Q-104/Q-160 report them; does not establish that Q-160 is readable on main (it is not; see note).

Recompute (log): `== 581d41d8 mb=f6fdda68 final=842`, first commit `43b9edb6 102`; `== dfa75374 mb=e5d0f838 final=538`, first commit `3e58eb9c 217`; `4225753a..de530691 396; 4225753a..5652d33f 1861`. Q-104 states `396 code lines outside docs/ at its first rubric (de530691, against 4225753a). It landed at 1861 (5652d33f)` (`docs/working/questions-archive.md:2015`).

Note: the entry `### Q-160 · implement-q104-per-iteration-cap` exists only on `chore/dev-cycle-2026-10-15-0357` (commit 63af3551, `docs/working/questions.md:68`), not on main or this branch; its merge waits on Q-162. Row 62, review-fix-loop.md:61 and the plan cite an ID a reader of main cannot yet resolve (paraphrased — no quote available because the claim covers absence: `git grep Q-160 main` returns no hits).

**Evidence:** `docs/reviews/execution-logs/q160-i1-factcheck-growth.log`, `docs/working/questions-archive.md:2015`, `chore/dev-cycle-2026-10-15-0357:docs/working/questions.md:68-74`

---

## Claim 3: "**Branch:** `fix/q160-iteration-cap` (from main b279a2ba)"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch's merge base with main; does not establish anything about main's later commits.

`git merge-base main HEAD` prints `b279a2ba` (paraphrased — no quote available because this is command output, not file text).

**Evidence:** `git merge-base main HEAD`

---

## Claim 4: Q-104 quote: "pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver. Follow-up: a pr-prep / review-fix-loop change plus an amendment to log row 62."

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote's wording and the answer date/option; does not establish that the implemented section adds nothing beyond it (Claim 9).

Archive: `**Answered 2026-10-06: [2], re-check per iteration, waiver past 2×.** pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver. Follow-up: a pr-prep / review-fix-loop change plus an amendment to log row 62, for the next cycle's roadmap.` (`docs/working/questions-archive.md:2011`). The plan's quote stops before ", for the next cycle's roadmap" without an ellipsis; the omission changes nothing.

**Evidence:** `docs/working/questions-archive.md:2008-2025`

---

## Claim 5: Growth table (581d41d8 102 (43b9edb6) → 842; 73589cd7 157 (d861183d) → 603; dfa75374 217 (3e58eb9c) → 538; 626dc300 392 (f2533b33) → 570) and "All four match Q-160"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:11-18`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every figure and first-commit hash, recomputed from each merge's merge base with step 1a's count; does not establish which commits were review fixes versus feature work (Claim 6).

Log lines: `43b9edb6 102` … `final=842`; `d861183d 157` … `final=603`; `3e58eb9c 217` … `final=538`; `f2533b33 392` … `final=570`. Q-160 lists the same four pairs: `from 102 to 842 code lines (581d41d8), 157 to 603 (73589cd7), 217 to 538 (dfa75374) and 392 to 570 (626dc300)` (`chore/dev-cycle-2026-10-15-0357:docs/working/questions.md:71`).

**Evidence:** `docs/reviews/execution-logs/q160-i1-factcheck-growth.log`

---

## Claim 6: "73589cd7's and 626dc300's first commits are not the whole unit (U2a4's feature commit and Q-089's A2 came after), so 'grew during review' overstates part of each figure; the trigger still fires on 581d41d8 and dfa75374."

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit sequence on the two named branches; does not establish that 581d41d8's and dfa75374's growth was all review-fix work (U2a3b's loop 2 includes a `feat(...)` commit be94c871, made inside the review loop).

Log: `d861183d 157 test(build-loop-check): U2a4 floor ... (red)` then `c934adbc 381 feat(dev-cycle-read): the self-merge floor ...`; `f2533b33 392 feat(cc-isolated): ... (Q-089 unit A1)` then `4be0445d 511 feat(cc-push): ... (Q-089 unit A2)`.

**Evidence:** `docs/reviews/execution-logs/q160-i1-factcheck-growth.log`

---

## Claim 7: "Q-120 [1] (U2a3b at 794) cited 'Q-104 [2]'s ~800' and waived it; `docs/working/merge-msg-build-loop-u2a3b.md` records 841 lines under that waiver. Q-131 (U2a4, 540) asked for a waiver 'against the 400 cap'"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:20`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three cited texts; does not establish whether the U2a4 waiver was needed under Q-104 [2] (540 < 800, so it was not).

`the unit sits at 794 changed code lines, at Q-104 [2]'s ~800 tolerance` and `The waiver lets U2a3b pass Q-104 [2]'s ~800 lines` (`docs/working/questions-archive.md:2069-2071`); `**Size:** 841 changed code lines against main, past decision log row 62 / Q-104 [2]'s ~800, under the user's waiver (Q-120 [1]).` (`docs/working/merge-msg-build-loop-u2a3b.md:28`); `the unit is 540 code lines against the 400 cap` (`docs/working/questions-archive.md:2256`).

**Evidence:** `docs/working/questions-archive.md:2066-2078`, `docs/working/questions-archive.md:2253-2258`, `docs/working/merge-msg-build-loop-u2a3b.md:28`

---

## Claim 8: "Q-113 (U1b, 417) was an entry-gate waiver, opened before Q-104 was answered, so it is not an application of Q-104 [2]." (repeated in the commit message's Notes)

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:20`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers Q-113's dates and what it waived; does not establish how the U1b loop's count evolved commit by commit.

Dates hold: Q-113 `**Opened:** 2026-10-05` (`docs/working/questions-archive.md:1932`), Q-104 `Answered 2026-10-06` (`docs/working/questions-archive.md:2011`), so the conclusion holds. But "entry-gate" is imprecise: Q-113 asks about U1b being `~417 changed code lines after the Q-112 fixes, over the 400-line review cap` (`docs/working/questions-archive.md:1934`), and Q-112 was filed when `U1b's review loop hit its 3-iteration cap` (`docs/working/questions-archive.md:1895`). It waived step 1a's 400 cap after review fixes grew the unit, i.e. in-loop growth, not a check at entry. Precise version: "Q-113 waived the 400 cap after U1b's review fixes, before Q-104 was answered". (Q-114, U1c at 426 "after its review fixes", `docs/working/questions-archive.md:1949`, is the same shape and goes uncited.)

**Evidence:** `docs/working/questions-archive.md:1888-1896`, `docs/working/questions-archive.md:1931-1949`

---

## Claim 9: "This gate checks the unit once, at entry; the review-fix loop re-runs the same count after each iteration and before merge, and tolerates growth to ~800 lines ([size re-check](...), Q-104 [2])." (same attribution pattern in row 62's "Amended 2026-10-15 (Q-104 [2], Q-160):")

**Location:** `workflows/pr-prep.md:96`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which parts of the rule as now written appear in Q-104 [2]'s text; does not judge whether the additions are good.

Q-104 [2] says only `pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver.` (`docs/working/questions-archive.md:2011`). The pieces "before merge" (pr-prep.md:96, log.md:85, review-fix-loop.md:57), "in /away mode too" (log.md:85, review-fix-loop.md:59), "a waiver granted for the entry count does not lift this check" and "Record the count in that iteration's review artifact" (review-fix-loop.md:57,59) are not in Q-104's text. The commit body discloses most of them (`Choices not in Q-104's text: the re-check also runs before merge ...; an entry waiver does not lift the re-check ...; the count is recorded in each iteration's review artifact`), but the docs themselves cite them under "Q-104 [2]" without marking them as agent additions. The commit's disclosure list omits "/away too" (see Claim 18).

**Evidence:** `workflows/pr-prep.md:96`, `docs/decisions/log.md:85`, `workflows/review-fix-loop.md:57-59`, `docs/working/questions-archive.md:2011`

---

## Claim 10: Restatements to update include "`workflows/pr-prep.md` step 1a, step 1 and step 3 completion criteria, step 3e"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:26`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether each listed spot changed in the diff; does not establish that the step 1 criterion is now wrong (it is still correct as an entry criterion).

Step 1a, step 3e and the step 3 criterion changed (`workflows/pr-prep.md:96`, `:272`, `:285`). The step 1 criterion is unchanged: `The unit is at most 400 changed code lines ... OR the user waived the cap` (`workflows/pr-prep.md:155`). Plan step 2 (`:38`) lists only "step 3 completion criterion", so the research list overstates what the plan updates.

**Evidence:** `workflows/pr-prep.md:96`, `workflows/pr-prep.md:155`, `workflows/pr-prep.md:272`, `workflows/pr-prep.md:285`

---

## Claim 11: "`skills/dev-cycle/SKILL.md:701` names 'log row 62' only as a template example of a trigger verdict"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line's content; does not verify the "it is gate code" aside.

`- log row 62: cannot tell — <what would tell>` under `### Trigger verdicts` in a template block (`skills/dev-cycle/SKILL.md:699-701`).

**Evidence:** `skills/dev-cycle/SKILL.md:695-705`

---

## Claim 12: "Tests that pin this text: none found that grep pr-prep's size gate, review-fix-loop's sections or chat-synthesis rule 2. ... run them"

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a grep of `test/` for the size-gate phrases and a pass of the three named suites at a94e01c7; does not establish that `cross-reference-integrity.bats` checks anchor fragments (it strips them: `local path="${target%%#*}"`, `test/cross-reference-integrity.bats:39`).

`rg -ln "Size gate|size gate|split PR|Early split|early split|hard cap: ~400|>400" test/` returned nothing (paraphrased — no quote available because the claim covers absence of matches). The three suites ran green (log: exit 0, 0 `not ok`).

**Evidence:** `docs/reviews/execution-logs/q160-i1-factcheck-bats.log`, `test/cross-reference-integrity.bats:38-39`

---

## Claim 13: "Did it stay within the review-fix loop's size re-check (≤ 800 lines after review fixes), or does the description cite the user's waiver?"

**Location:** `guides/completion-signals.md:82`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the owned rule's threshold and waiver recording; does not cover the "before merge" timing, which the line does not state.

Owned rule: `The check fires above 800` and `Record a granted waiver as step 1a records one, in the PR description` (`workflows/review-fix-loop.md:57-59`).

**Evidence:** `guides/completion-signals.md:82`, `workflows/review-fix-loop.md:57-59`

---

## Claim 14: "**Size re-check** — after each iteration and before merge, re-run step 1a's count: growth to 800 lines is tolerated; past it, stop and ask the user for a waiver (a `Q-NNN` entry), in /away mode too"

**Location:** `guides/pr-prep-quick-ref.md:53`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with review-fix-loop.md's section; does not establish that the rule traces to Q-104 (Claim 9).

Matches `After each iteration's fix commits, and again before the unit merges, re-run step 1a's command` and `This holds in /away mode too` (`workflows/review-fix-loop.md:57-59`).

**Evidence:** `guides/pr-prep-quick-ref.md:53`, `workflows/review-fix-loop.md:57-59`

---

## Claim 15: Rule 2 "**split PR** — The unit is over its size limit ...: >400 on its first review (step 1a's gate), or >800 on a later pass of the review-fix loop (its size re-check, which tolerates growth during review). The user has not waived that limit for this unit, AND ≥1 🔴 item exists"

**Location:** `skills/code-review/references/chat-synthesis.md:140-147`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the >800 branch of rule 2 against review-fix-loop.md's size re-check; does not cover the >400 first-review branch, which matches step 1a's must-split rule.

The owned rule says past 800 the agent does not split; it stops and asks: `Past 800, the loop stops on this unit: no further fix commits, re-review or merge until the user answers a waiver entry (Needs: you: judgment) ... The entry's options can include splitting the unit. This holds in /away mode too: unlike the early split trigger, the agent does not decide this one` (`workflows/review-fix-loop.md:59`). Rule 2 instead derives `split PR` for a >800 unit with a red, which an /away agent acts on without asking. Two further mismatches follow from the ladder (paraphrased — no quote available because they follow from rule order across `chat-synthesis.md:128-157`): a >800 unit with 0 🔴 skips rule 2 and can derive `merge` (rule 5), where the loop forbids merge; and the ladder has no value for "stop for waiver". A reader acting on rule 2 is misled about who decides past 800. The commit message's description of the change ("split PR: >400 on the first review, >800 on a later pass") is accurate as a description; it is the rule's consistency with the owned section that fails.

**Evidence:** `skills/code-review/references/chat-synthesis.md:128-157`, `workflows/review-fix-loop.md:59`

---

## Claim 16: Worked example "1 🔴 in security, 800-line diff → rule 2 → `Recommended next action: split PR.`"

**Location:** `skills/code-review/references/chat-synthesis.md:179`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the example against the amended rule 2; does not depend on Claim 15's outcome.

Under amended rule 2 an 800-line unit fires only on its first review; on a later pass the limit is `>800` (`chat-synthesis.md:142-143`), so 800 lines does not trigger rule 2 and the example would fall through to rule 4 (`≥1 🔴 item exists (and rules 1–3 did not match)`, `chat-synthesis.md:153`). The example needs "on its first review" (or a figure above 800 for a later pass).

**Evidence:** `skills/code-review/references/chat-synthesis.md:140-153`, `skills/code-review/references/chat-synthesis.md:179`

---

## Claim 17: Step 3e: "the [early split trigger](...) and the [size re-check](review-fix-loop.md#size-re-check-after-any-iteration) (both checked after every iteration; the size re-check again before merge) ... are owned by [review-fix-loop.md § Hard cap](review-fix-loop.md#hard-cap-3-iterations)"; step 1a links the same anchor.

**Location:** `workflows/pr-prep.md:272`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the anchor resolving to a heading and the section sitting under `## Hard cap`; does not establish anchor validity by test (the cross-reference suite strips fragments).

`## Hard cap (3 iterations)` at `workflows/review-fix-loop.md:24`, `### Early split trigger (after any iteration)` at `:49`, `### Size re-check (after any iteration)` at `:55`, next `##` at `:91`. GitHub slugging of "Size re-check (after any iteration)" gives `size-re-check-after-any-iteration` (paraphrased — no quote available because slug derivation is a rendering rule, not file text).

**Evidence:** `workflows/review-fix-loop.md:24`, `workflows/review-fix-loop.md:49-61`, `workflows/pr-prep.md:96`, `workflows/pr-prep.md:272`

---

## Claim 18: "The size re-check ran after each iteration and before merge: the unit is at most 800 changed code lines (step 1a's command, same `BASE`), OR the user waived it and the PR description records the waiver with its `Q-NNN` entry"

**Location:** `workflows/pr-prep.md:285`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with review-fix-loop.md:57-59; does not cover the "answer quoted" requirement, which the criterion omits but the owned section and step 1a carry.

Owned rule: `re-run step 1a's command with the same BASE` and `The check fires above 800` (`workflows/review-fix-loop.md:57`).

**Evidence:** `workflows/pr-prep.md:285`, `workflows/review-fix-loop.md:57-59`

---

## Claim 19: Intro: "This document owns the review-fix loop's control rules: the iteration cap and its exit conditions, the early split trigger, the size re-check, the fix-drift check, and the two re-fire filters (divergence detection and re-flagged settled decisions)."

**Location:** `workflows/review-fix-loop.md:8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each listed rule has a section here; does not establish that no other file restates them (Claims 15-16 are restatements in chat-synthesis).

Headings: `## Hard cap (3 iterations)` `:24`, `### Exit conditions (iterations 1–3)` `:40`, `### Early split trigger (after any iteration)` `:49`, `### Size re-check (after any iteration)` `:55`, `## Fix-commit drift check (lite)` `:91`, `## Divergence detection (stuck-loop signal)` `:115`, `## Re-flagged settled decisions (override-log filter)` `:159`.

**Evidence:** `workflows/review-fix-loop.md:8-222`

---

## Claim 20: "[pr-prep step 1a](pr-prep.md#1-gate-checks) caps a unit at ~400 code lines before the loop starts"

**Location:** `workflows/review-fix-loop.md:57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the anchor and the cap; does not establish anchor validity by test.

`#### 1. Gate checks` (`workflows/pr-prep.md:82`, slug `1-gate-checks`) followed by `**a. Size gate (hard cap: ~400 code lines per review unit).** Before the review-fix loop starts` (`workflows/pr-prep.md:86`). Pre-existing links already use this anchor form, e.g. `pr-prep.md#3-review-fix-loop` in the intro.

**Evidence:** `workflows/pr-prep.md:82-96`

---

## Claim 21: "This holds in /away mode too: unlike the early split trigger, the agent does not decide this one (decision log 62, Q-104 [2])." and "Record a granted waiver as step 1a records one, in the PR description ..., citing the `Q-NNN` entry with the user's answer quoted."

**Location:** `workflows/review-fix-loop.md:59`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the /away attribution and the waiver-recording cross-reference; does not cover the other additions (Claim 9).

Waiver recording matches step 1a: `note the waiver in the PR description (step 6), citing by ID the answered Q-NNN entry ... with the user's answer quoted verbatim` (`workflows/pr-prep.md:101`). The /away part is an inference: Q-104 [2] says `the loop stops and asks you for a waiver` (`docs/working/questions-archive.md:2020`), while option [1] says `(in /away mode, automatically)` (`:2019`), so "asks you" with no /away carve-out supports the reading, but Q-104 does not say "in /away mode too". The commit body's list of "Choices not in Q-104's text" omits it. Precise version: cite it as the agent's reading of Q-104 [2]. Decision log 62 supports it only through this same branch's amendment.

**Evidence:** `workflows/review-fix-loop.md:59`, `workflows/pr-prep.md:101`, `docs/working/questions-archive.md:2019-2020`

---

## Claim 22: Commit message: "units then grew during review (102 to 842, 157 to 603, 217 to 538, 392 to 570 code lines; Q-160). ... That rule lived only in an answered question and was applied by hand."

**Location:** `git log main..HEAD` (a94e01c7 body)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures, the "during review" framing and where Q-104 [2] was written down on main; does not cover the Notes paragraph (Q-113 is Claim 8).

The figures reproduce (log, see Claim 5), but "grew during review" overstates two of them: the 157 and 392 starts precede feature commits (`c934adbc 381 feat(...)`, `4be0445d 511 feat(cc-push) ... (Q-089 unit A2)`), as the branch's own plan says (`docs/working/plan-2026-10-15-q160-size-recheck.md:18`); review-fix-loop.md:61 and row 62 correctly cite only the two clean cases. "Lived only in an answered question": `git grep Q-104 main` finds the rule only in the archive entry and in citations of it (the merge message, Q-120) (paraphrased — no quote available because the claim is about absence across the tree). "Applied by hand" holds for Q-120, but Q-131 measured U2a4 `against the 400 cap` (`docs/working/questions-archive.md:2256`), so it was applied inconsistently, as the plan says.

**Evidence:** `docs/reviews/execution-logs/q160-i1-factcheck-growth.log`, `docs/working/questions-archive.md:2011`, `docs/working/questions-archive.md:2256`

---

## Other restatements of the old rule (repo-wide grep)

Grep for `400 | size gate | size cap | row 62 | log 62` outside `docs/reviews`, `docs/working`, `archive`, `runs`. Besides Claims 15-16, nothing contradicts the change. `workflows/pr-prep.md:155` (step 1 criterion, ≤400 at entry) and `guides/pr-prep-quick-ref.md:11` (entry size gate) stay accurate as entry checks. `guides/validation-gates.md:46-50` (Gate 1b, 500-line cap) belongs to the tasks.json pipeline, not pr-prep, and predates this change. `skills/dev-cycle/SKILL.md:701` is a template (Claim 11). No instruction file (CLAUDE.md / AGENTS.md / GEMINI.md) restates the cap.

## Goal-Alignment Note

The diff does what the PR describes: Q-104 [2] is now written into review-fix-loop.md and linked from pr-prep, the guides and row 62. Two things work against the goal of one consistent rule. First, code-review's next-action ladder (chat-synthesis rule 2 and its worked example) disagrees with the owned section about what happens past 800. Second, the docs attribute agent-chosen additions to Q-104 [2] without marking them.

## Claims Requiring Attention

### Incorrect
- **Claim 15** (`skills/code-review/references/chat-synthesis.md:140-147`) `[for-author]`: rule 2 derives `split PR` for >800 on a later pass, but review-fix-loop.md:59 says past 800 the loop stops for a user waiver and the agent does not decide, even in /away mode. A >800 unit with 0 🔴 can also derive `merge`. Align rule 2 with the size re-check, e.g. a "stop for waiver" outcome or a carve-out.

### Stale
- **Claim 16** (`skills/code-review/references/chat-synthesis.md:179`) `[for-author]`: the "800-line diff → rule 2 → split PR" example is now true only on a first review. Qualify it or use a later-pass figure above 800.

### Mostly Accurate
- **Claim 8** (`docs/working/plan-2026-10-15-q160-size-recheck.md:20`, also commit Notes) `[for-author]`: Q-113 waived the 400 cap after U1b's review fixes (in-loop growth), so it was not an entry-gate waiver. The conclusion (not an application of Q-104 [2]) holds.
- **Claim 9** (`workflows/pr-prep.md:96`; `docs/decisions/log.md:85`; `workflows/review-fix-loop.md:57-59`) `[for-author]`: "before merge", "/away too", "entry waiver does not lift" and "record the count" are cited under Q-104 [2] but are not in its text. Only the commit body discloses them.
- **Claim 10** (`docs/working/plan-2026-10-15-q160-size-recheck.md:26`) `[for-orchestrator-synthesis]`: the research list names the step 1 completion criterion as a restatement to update, but the diff leaves it unchanged. That is fine, since it is still correct for entry.
- **Claim 21** (`workflows/review-fix-loop.md:59`) `[for-author]`: "in /away mode too" is a reasonable reading of Q-104 [2] but is not stated there, and the commit's list of additions omits it.
- **Claim 22** (commit a94e01c7 body) `[for-orchestrator-synthesis]`: two of the four growth pairs include post-start feature commits, so "grew during review" overstates them. "Applied by hand" was inconsistent (Q-131 used 400).
- **Claim 2 note** (verdict Verified; listed for visibility) `[for-orchestrator-synthesis]`: Q-160 is cited from main-bound docs but exists only on `chore/dev-cycle-2026-10-15-0357` until Q-162's merge.

### Unverifiable
- None.
