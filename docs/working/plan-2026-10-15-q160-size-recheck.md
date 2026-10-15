# Q-160: re-check the unit size inside the review-fix loop (research and plan)

**Branch:** `fix/q160-iteration-cap` (from main b279a2ba) · **Date:** 2026-10-15 · **Source:** Q-160 (dev cycle 2026-10-14), carrying out Q-104 [2]

## Research

**The rule to write in.** Q-104 (questions-archive, answered 2026-10-06, [2]): "pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver. Follow-up: a pr-prep / review-fix-loop change plus an amendment to log row 62."

**Why now (verified against the repo).** Per-commit counts with step 1a's command, from each branch's merge base:

| Merge | First commit | At merge |
|---|---|---|
| 581d41d8 (U2a3b) | 102 (43b9edb6) | 842 |
| 73589cd7 (U2a4) | 157 (d861183d) | 603 |
| dfa75374 (U2a3c) | 217 (3e58eb9c) | 538 |
| 626dc300 (Q-089 A1+A2) | 392 (f2533b33) | 570 |

All four match Q-160. Note: 73589cd7's and 626dc300's first commits are not the whole unit (U2a4's feature commit and Q-089's A2 came after), so "grew during review" overstates part of each figure; the trigger still fires on 581d41d8 and dfa75374.

**Interim practice.** Q-120 [1] (U2a3b at 794) cited "Q-104 [2]'s ~800" and waived it; `docs/working/merge-msg-build-loop-u2a3b.md` records 841 lines under that waiver. Q-131 (U2a4, 540) asked for a waiver "against the 400 cap": the rule was read inconsistently because it existed only in an answered question. Q-113 (U1b, 417 after its Q-112 review fixes) and Q-114 (U1c, 426) were opened 2026-10-05, before Q-104 was answered (10-06), so they are not applications of Q-104 [2]; they were measured against the 400 cap.

**Where the rule goes.** `workflows/review-fix-loop.md` owns the loop's control rules (its intro says each rule is stated in one place, others link). The re-check runs between iterations, so it belongs there, beside the early split trigger. pr-prep step 1a (entry gate) and step 3e (loop summary) link to it.

**Restatements to update** (grep for 400 / size gate / row 62 outside `docs/working`, `docs/reviews`, `archive`, `runs`):
- `workflows/pr-prep.md` step 1a, step 3c, step 3e, step 3 completion criteria, step 6c (step 1's criterion stays: it is the entry check)
- `guides/pr-prep-quick-ref.md` (size gate line; loop exit criteria)
- `guides/completion-signals.md` (PR description size line)
- `skills/code-review/references/chat-synthesis.md` next-action rule 2 ("split PR" when over 400 with a red; after the first iteration the limit is ~800)
- `docs/decisions/log.md` row 62 (amendment, and its "units under the cap still balloon" revisit trigger, which this change answers)
- `skills/dev-cycle/SKILL.md:701` names "log row 62" only as a template example of a trigger verdict; it stays (and it is gate code).

**Tests that pin this text:** none found that grep pr-prep's size gate, review-fix-loop's sections or chat-synthesis rule 2. `test/workflow-required-sections.bats`, `test/cross-reference-integrity.bats` and `test/skills/code-review-assurance-contract.bats` read these files; run them, plus the full gate at step 5a.

## Plan

1. `review-fix-loop.md`: new `### Size re-check (after any iteration)` after the early split trigger. After each iteration's fix commits and before merge, re-run step 1a's command with the same `BASE`; tolerate up to 800 (fires above, "~" as in step 1a); past it, stop (no fix commits, re-review or merge) and file a `you: judgment` waiver entry, in /away mode too; the waiver is recorded as step 1a's is; an entry waiver does not lift it unless its answer says so; record the count in the iteration's review artifact. Add it to the intro's list of owned rules.
2. `pr-prep.md`: step 1a one sentence linking the re-check; step 3e lists it; step 3 completion criterion.
3. Guides and chat-synthesis rule 2 as listed.
4. Log row 62: `**Amended 2026-10-15 (Q-104 [2], Q-160):**` sentence pointing at the new section; replace the balloon trigger with one on waivers past ~800.
5. Run the pinning suites, then pr-prep with code-review and self-eval on review-fix-loop.

**Not doing:** no script enforcement (the entry gate is also by hand); no change to `scripts/` or `skills/dev-cycle/`.
