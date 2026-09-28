Commit: 27d483b

# API Consistency Review — review/q087 (Q-087 [2])

**Scope:** `git -C /workspace/.claude/wt-q087 diff main...HEAD` (one commit, 27d483b; full branch, no partial-scope label)
**Date:** 2026-09-28
**Based on:** `docs/reviews/q087-code-fact-check-report.md` (Stage-1 merged fact-check, k=1 loop pass)

## Baseline Conventions

The consumer-facing surface is the `code-review` skill's contract and the documents that invoke or parse it:

- **Flag semantics** (`skills/code-review/SKILL.md:103-109`, `:246-251`): `--loop-pass` marks a non-final pass. It enables the short-circuit and the delta default range, and implies `--no-gate`. `--full` and `--range` override scope only. On main, k was chosen by two conditions: the flag, and whether the branch had an open loop rubric. The final confirming pass ran k=1.
- **Replication header vocabulary**: `**Replication:** k=1 (loop pass, decision 031)` (`SKILL.md:448`) versus `**Replication:** k=3` / `k=2 (one replicate failed)` (`SKILL.md:609`). Gate 1h (`scripts/self-improvement.sh:1581`, `:1604-1618`) parses this field. It treats `k=3*` as silent and anything else as an advisory "degraded" note.
- **Rubric markers** (`references/rubric.md:18-28`, `SKILL.md:111-129`): `Commit:` stamp, `Loop-pass short-circuit: used at <sha>`, `Loop closed at <sha>`.
- **Invokers**: `workflows/pr-prep.md:244` says "`--loop-pass` also sets the fact-check replicate count … code-review's SKILL.md owns both", and `:250-253` says to run the final confirmation pass "**without** it and without `--range`". `workflows/review-fix-loop.md:7` defers `--loop-pass` ownership to the skill.
- **Decision conventions**: log rows that amend a full record say so inline. For example, row 60 amends 032 #4, and 032 carries no back-reference to row 60. Full-record-to-full-record amendments use `**Amends:**` / `Superseded by` notes (`023:10`, `022:72`). A log row that a later row replaces is marked inline in its decision cell (`log.md:66`, row 43 "SUPERSEDED BY #44"). Prose cites log rows as "decision log NN" (`workflows/review-fix-loop.md:50`, "decision log 59").

## Name-Pattern Audit

The diff introduces no new public names: no new flags, header values, marker lines or fields. It changes only which existing value (`k=3` vs `k=1`) a run without `--loop-pass` produces. The one new citation form is checked below.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| "decision log 63" (citation form) | doc cross-reference | "decision log 59", "decision-log row 29", "log row 27" | `workflows/review-fix-loop.md:50`; `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:9`; `docs/thoughts/code-review-evaluation-state.md:225` | Consistent: matches the "decision log NN" form already used in workflows |
| Log row number 63 | decision-log key | rows 60, 61 on this branch; row 62 on `answers-2026-09-28` | `docs/decisions/log.md:83-85` | Consistent once row 62 lands. The gap on this branch alone was already escalated by the fact-check, so it is not re-filed here |

## Findings

#### A1. Row 60 still states the superseded k=1 final-pass rule, with no inline supersession marker

**Severity:** Minor
**Location:** `docs/decisions/log.md:83`
**Move:** 3 (consumer contract — documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`docs/decisions/log.md:83`, excerpt from the Rationale cell; the row continues to the Full Record cell, read):
> the mitigation is that the final confirming pass reviews the full branch (at 031's k=1, unchanged); raising it to k=3 is open as Q-087

Row 63 (`docs/decisions/log.md:85`) now says the opposite: "**A review-fix loop's final confirming pass runs the fact-check at k=3 …**". A reader who greps the log for the final-pass rule finds two rows that contradict each other, and only the newer one points at the other ("log 60"). The log already has a convention for this: row 43's decision cell opens with "**SUPERSEDED BY #44 …**" (`docs/decisions/log.md:66`). This corroborates fact-check Stale Claim 1.

**Recommendation:** Add a short inline pointer to row 60, such as "(k=3 since row 63)" after "unchanged", or a trailing "Final-pass k amended by #63." Row 60 is only partly superseded, so do not add a whole-row SUPERSEDED banner.

#### A2. Row 63's revisit trigger names the wrong source for its falsifier and gives no action

**Severity:** Minor
**Location:** `docs/decisions/log.md:85`
**Move:** 3 (consumer contract — documentation drift against the cited decision)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`docs/decisions/log.md:85`, excerpt from the Rationale cell; the row continues to the Full Record cell, read):
> Revisit if final-pass replicate agreement on untouched code stays ≥90% over ≥20 claims (031's k-reduction falsifier, applied to this pass).

The source of the ≥90%/≥20 falsifier is `docs/thoughts/code-review-evaluation-state.md:78`: "**Falsifier worth checking first:** if k=3 fact-check verdicts agree ≥90% of the time on a". Its action is k=2, per `:225`: "(≥90% on a ≥20-claim *cumulative* sample → k=2)". Decision 031's own falsifier points the other way (`031-review-loop-tier-and-factcheck-policy.md:196`): "if a behavioral or security red is merged that a k=3 pass would have caught and k=1 across the actual number of passes did not — k=1 is under-sampling; restore k=2+". Every other trigger that follows the log's revisit convention names both a threshold and a source a future reader can check. This one names the wrong source and leaves open whether the fallback is k=1 or k=2. This corroborates fact-check Incorrect Claim 7.

**Recommendation:** Re-attribute the trigger to "the §1.1 falsifier, `docs/thoughts/code-review-evaluation-state.md:78`". State the action, for example "→ drop the final pass to k=2" (the §1.1 action) or "→ back to k=1".

#### A3. The k-selection rule keeps a rubric-state recognition clause that no longer decides k

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:451-454`; `docs/decisions/log.md:85`
**Move:** 3 (consumer contract — the flag's contract should be stated once and simply)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence (`skills/code-review/SKILL.md:451-454`; the paragraph continues to :456, read):
> 1−(1−p)³ for N≥3 draws). The **k=3 protocol below applies to standalone single-pass reviews and
> to a loop's final confirming pass** — the pass that runs without `--loop-pass` per
> [Step 1](#step-1-determine-scope), recognized by the branch's canonical rubric existing without a
> `Loop closed at` line. Loop passes review only the delta since the last stamp, so code no fix

On main, rubric state decided k: standalone meant "no `--loop-pass` and no open loop rubric", and the final pass ran k=1. After this change, every run without `--loop-pass` is k=3. So the effective contract is simply `--loop-pass` ⇔ k=1, which is what Important Reminders (`SKILL.md:1279-1281`) and pr-prep 3d (`workflows/pr-prep.md:244`, "`--loop-pass` also sets the fact-check replicate count") already say. Consider a reader who takes the "recognized by …" clause as a test: a final pass run after the rubric is already closed fails it. That pass still ends up k=3 as a "standalone" run, so behaviour does not diverge. The clause adds a second, redundant decision path for a reader to evaluate. Row 63 repeats it and drops "canonical". This corroborates fact-check Mostly-Accurate Claims 3 and 12b. No consumer breaks.

**Recommendation:** Optionally rewrite the rule as "every run without `--loop-pass` runs the k=3 protocol", and keep the recognition clause only as a description of which pass is the final one.

#### A4. "stays k=3" in the sub-skill summary reads as though the final pass was already k=3

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:20`
**Move:** 3 (documentation drift)
**Confidence:** Low
**Legibility-target:** for-author

Evidence (`skills/code-review/SKILL.md:20`; the bullet continues to :23, read):
> Runs as **k=3 parallel replicates** merged most-severe-wins (k=1 on `--loop-pass` passes, decision 031; the final confirming pass stays k=3, decision log 63); the rationale lives in one

Under decision 031, as in effect on main, the final pass ran k=1, so "stays" describes the change as no change. It is defensible if read as "stays at the default k=3", but the other three edited sites say "runs"/"takes".

**Recommendation:** Optionally change "stays" to "runs".

## What Looks Good

- **Replication header vocabulary is unchanged, and Gate 1h's reading improves.** The final pass now takes the k=3 protocol, which writes `**Replication:** k=3` (`SKILL.md:609`). Gate 1h's `k=3*) : ;;` arm (`scripts/self-improvement.sh:1605`) treats that as silent. No new header value was introduced, so the parser needs no change. `route: code-fact-check`
- **All four SKILL.md sites agree**: the summary (:20), the Step 1 cost-to-recall note (:131-133), the Stage 1 loop-aware paragraph (:443-456) and Important Reminders (:1279-1281) each state "k=1 on `--loop-pass`, k=3 on standalone and on the final confirming pass". This matches pr-prep 3d's delegation of k to the flag (`workflows/pr-prep.md:244`), and the invocation rules for `--loop-pass` / `--range` / `--full` are untouched. The short-circuit's "still implies `--no-gate` and k=1" (`SKILL.md:739`) applies only to `--loop-pass` runs, so it is still correct. `route: code-fact-check`
- **The amendment follows the nearest precedent.** Row 63 says "Amends 031 C2" inline and cites `[031](031-…md)` in the link form that 24 other rows use. Adding no back-reference in 031 matches row 60 amending 032 #4 with no note in 032. The fact-check escalated the missing amended-by note on 031. Under current convention that note is optional, not an inconsistency. `route: code-fact-check`
- **The test pins the new contract and keeps the old assertions.** `test/skills/code-review-factcheck-replication.bats:153-156` adds the final-pass assertion, and the existing `k=3 protocol below applies to standalone` check still passes. I ran `bats -f "replication is loop-aware"` on the branch: `ok 1`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| A1 | Row 60 still states the superseded k=1 final-pass rule, with no inline marker | Minor | `docs/decisions/log.md:83` | High |
| A2 | Row 63's revisit trigger names the wrong falsifier source and gives no action | Minor | `docs/decisions/log.md:85` | High |
| A3 | Vestigial rubric-state recognition clause in the k rule | Informational | `skills/code-review/SKILL.md:451-454` | Medium |
| A4 | "stays k=3" wording | Informational | `skills/code-review/SKILL.md:20` | Low |

## Overall Assessment

The change keeps the skill's consumer contract consistent. It adds no flag, header value or marker, and every consumer (pr-prep 3d, review-fix-loop, Gate 1h, rubric.md) already delegates the replicate count to `--loop-pass` as the skill defines it. The new rule, "no `--loop-pass` ⇒ k=3", is simpler than the one it replaces. The four SKILL.md sites and the test agree with it. The findings are about the decision log's internal consistency: the older row 60 is not marked, and row 63's revisit trigger names the wrong source. One clause is also vestigial. All can be fixed in place with one-line edits. None affects any consumer.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes
- Out of scope: the Step 7 agent count ("3 fact-check replicates", `SKILL.md:259-260`). It predates this diff and is wrong only for `--loop-pass` runs; this diff makes it right for the final pass.
- Escalate: nothing new. The row-62 gap and the 27d483b/65e51b7 duplicate are already escalated by the fact-check. Confirmed: `git diff 27d483b answers-2026-09-28 -- skills/code-review/SKILL.md test/skills/code-review-factcheck-replication.bats` is empty, so both branches carry identical changes to these files.
- Decisions I made: I filed A1 and A2 as convention findings that corroborate fact-check claims 1 and 7, not as new discoveries. I treated the missing amended-by note on 031 as consistent with the row-60→032 precedent, so it is not a finding.
