# Performance Review — feat/build-loop-u4b2 (iteration 3, final pass, full branch)

**Scope:** `git diff main...HEAD` at b88e418a (`skills/dev-cycle/SKILL.md` steps 0-10, Flow, Rules, wait rule; `test/scripts/build-loop-orchestrator.bats`), read with the script contracts it drives (`scripts/build-loop.sh` header and dispatch code, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh` `check_branch`, `scripts/health-check.sh` section 14)
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b2-final-r{1,2,3}.md` (the k=3 final fact-check at c39a9692; rubric rows C1-C10), the prior pass `docs/reviews/performance-review-2026-10-13-u4b2-i2.md` and its measurements, the deferred override rows dated 2026-10-13 for `feat/build-loop-u4b2`, and one new probe (below).

## Data Flow and Hot Paths

`/loop /dev-cycle` runs steps 0-10 once per iteration. Plan D12 (C5's answer) makes every iteration a full cycle. The iteration body is the hot path: with a loop running it wakes on each loop completion plus a 1800 s fallback, and with none every 1200-1800 s when something changed. That is up to about 48-72 iterations a day.

Per iteration, the script work is fixed and small. Counting the calls as now written:
- three `--main-log` runs (step 0.2, step 7 before answers, step 10 before dispatch);
- three or more `--state` runs (step 0.1, step 9.2, step 10's land), plus one per self-merge and one per merge-in;
- two `--cycle-diff` and two `--land-cycle` runs (steps 9 and 10);
- one digest, one `--status`, one `--check-answer`, and one batched `--check-branch` over every merged branch (step 1).

The per-brief work is bounded by slots (1-9, default 3): `--merge`/`--check`/`--marker` in step 7, `--start`/`--prompt` in step 10, and one gate worktree (GT) per self-merge.

The prior pass measured these calls at adc8a176 on local clones:
- `--state`: 0.34-0.36 s
- `--cycle-diff`: 0.33-0.35 s
- `--land-cycle`: 0.47 s warm
- `--main-log` over 5-9 commits: 0.39-0.43 s
- GT `worktree add --detach`: 0.33-0.40 s; `worktree remove --force`: 0.04 s
- digest: 0.48 s

That puts the fixed script time per iteration at roughly 5 s. Three costs dominate instead:
- the health check: about 140 s with `--jobs 8`, and 216 s on a merged tip (`docs/reviews/q090-final-performance-review-2026-09-30.md`, `docs/reviews/code-fact-check-report-iter3-r2.md`);
- the four or more subagents of steps 2-4b;
- what grows with the iteration count: branches, the per-day record, and chore merges on main.

New probe, `/tmp/claude-1000/-workspace/3f9d7e3a-3058-4f14-a27e-9ecde97197ee/scratchpad/u4b2-i3c/perf/probe-branches.sh`: a clone at b88e418a under `/tmp/u4b2rv-perf-9e6N`, N branch refs `chore/dev-cycle-*`, then one batched `scripts/dev-cycle.sh --check-branch` call naming all N.

| Branches named | `--check-branch` wall time | Per name |
|---|---|---|
| 48 (one day of iterations) | 0.42 s | 8.7 ms |
| 336 (one week) | 2.72 s | 8.1 ms |
| 1440 (thirty days) | 11.85 s | 8.2 ms |

All names printed `ok`. `check_branch` spawns about six git processes per name (`check-ref-format` twice, `show-ref`, `rev-parse`, `rev-list --count`, `log -1`; `scripts/lib/dev-cycle-read.sh:523-539`).

## Findings

#### F1. The health-check skip either never fires twice in a row or skips code no check passed: "an earlier iteration's" pass is not tied to the window step 0.2 lists

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:290-299` (step 1), `:593` (record template's `1.` line), `:579-581` (what of earlier blocks is read)
**Move:** 3 (work in the wrong place: a repeated 140-216 s check) / 8 (question the cache: a skip is a cached "passed" with an invalidation rule)
**Classification:** Macro (cost per wakeup, not per change) / Hot path (once per iteration, about 48-72 a day)
**Confidence:** Medium. Both readings follow from the text. Which one an orchestrator takes is not decidable from it.
**Legibility-target:** the orchestrator executing step 1, and the step 9 template's author
**Baseline:** full health check about 140 s with `--jobs 8` (142-145 s over five runs, `docs/reviews/q090-final-performance-review-2026-09-30.md`) and 216 s on a merged tip (`docs/reviews/code-fact-check-report-iter3-r2.md`). The skip rate is speculative.

Evidence, verbatim:
> skipped when step 0.2 read an `other` line, whose unreviewed test code it would run (row 776; step 4 then runs no repo test either), or when an earlier iteration's health check passed and step 0.2 listed only `chore` lines since (cycle lands carry no code)

> `1. health and cleanup: <done / skipped: reason>`

> (nor reading them, but for their `1.` and `7.` lines and the last `Main at:`: the file grows all day)

Step 0.2 lists only the commits after SINCE, which is the previous iteration's `Main at:`. So "only `chore` lines since" can be checked against one iteration back, not against "an earlier iteration" further back. The record keeps no 0.2 listing, so the commits between an older pass and SINCE cannot be re-read. That leaves two readings.

- **Strict reading** (the pass must be the immediately previous iteration): a skipped iteration is not a pass, so the next one runs the check again. Checks alternate run, skip, run, and the skip saves only about half of the 140-216 s per iteration that C4 meant to save.
- **Loose reading** (any earlier pass): the skip fires over windows nobody checked. Example: iteration j sees a `gate` line, a loop's merged code. Its check gives up with exit 75 after `HEALTH_CHECK_LOCK_WAIT=3600` ("record that and skip the step's check"), or fails, or is skipped for an `other` line. Iteration j+1 sees only j's two chore lands, finds iteration j-1's pass, and skips. Nothing checks that gate merge's code until a non-chore commit lands.

The template's `1.` line also has no "passed" value: `done` covers a run with triaged failures too. So the input the skip reads is not one the record is told to hold.

**Recommendation:** Make the cached state explicit and chained. Have the `1.` line read `passed at MAIN`, `failed`, `gave up (75)`, or `skipped: no change since pass at SHA`. Skip only when the previous iteration's `1.` line is `passed` or such a skip, and this iteration's 0.2 lists only `chore` lines. That gives a skip on every unchanged iteration, with no hole after a failed, given-up or `other`-skipped check.

#### F2. The merged-branch entry is now updated in place, but it and the per-iteration `--check-branch` call still grow by one name per iteration, without bound

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:308-315` (step 1), with `:64-65` (Rules: "its branch stays") and `:258-263` (step 0.3)
**Move:** 4 (memory lifecycle: a collection that grows without bound) / 1 (hidden multiplication: a per-name check run every iteration over a growing list)
**Classification:** Macro (linear per iteration, quadratic in total) / Hot path (every iteration)
**Confidence:** High for the growth and the measured cost. Medium for how fast the user clears the list.
**Legibility-target:** the orchestrator (step 1), and the user, who reads the paste block
**Baseline:** batched `--check-branch` measured at 0.42 s for 48 names, 2.72 s for 336, and 11.85 s for 1440 (8.1-8.7 ms per name; probe above, clone at b88e418a).

Evidence, verbatim:
> List merged branches; deleting them needs the user's approval, so put the list in one `you: terminal` entry rather than deleting (an open one is updated in place, not filed again: every iteration adds a branch). Only a name that `--check-branch` prints `ok` for goes into that entry's paste block

B12 fixed the repeated filing of the prior F1. It did not fix the growth, and the text names it ("every iteration adds a branch").

At about 48 iterations a day, the entry's paste block gains about 48 lines a day. After thirty days it holds about 1,440 names, about 63 KB in `docs/working/questions.md`, which is 38 KB today. Every reader of that file pays for this every iteration: `--check-answer`, `--cycle-diff`'s and `--land-cycle`'s questions rules, the digest's `questions.sh open`, and health-check section 14.

Step 1 re-checks the whole list each iteration. Measured, that is 12 s per iteration at a month, and about 2.4 h of total script time over that month (8.2 ms × 1440 × 1441 / 2).

Each update also makes every iteration a questions change. So every user answer that lands between MAIN and step 9 takes the merge-in path of step 9.3 (one more `--state` and merge commit).

The attention cost is the real one. The prior pass's recommendation was to leave out `chore/dev-cycle-*` branches that a landed record names, or to delete the iteration's own branch once its land is verified. Neither was applied, and no override row defers it.

**Recommendation:** Do not list a `chore/dev-cycle-*` branch whose `Branch:` line sits in a record on main. `--land-cycle`'s `is-ancestor` check already proves it merged. Better: ask the user once for a standing approval to `branch -d` the iteration's own just-merged branch right after step 10's verified land. The entry then holds only unexpected branches.

#### F3. The second land runs on every iteration, including the many that dispatch nothing; the deferral of the prior F3 covers only the digest half

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:687-692` (step 10's second land), `:599-601` (the record's `8.`-`10.` lines)
**Move:** 1 (hidden multiplication: a land per iteration whose only payload may be one record line)
**Classification:** Macro (2 merges per iteration on main, feeding the per-iteration digest sample) / Hot path
**Confidence:** Medium. That most iterations dispatch nothing is an estimate: loops run for hours, and completions mostly produce ready or blocked results that wait on the user.
**Legibility-target:** the orchestrator (step 10), and the author weighing the deferred row for the prior F3
**Baseline:** one land measured at about 1.15 s warm (`--state` 0.34 + `--cycle-diff` 0.34 + `--land-cycle` 0.47 s, prior pass, adc8a176). Probe3 of the prior pass measured that two iterations add 4 first-parent chore merges to main. The share of no-dispatch iterations is speculative.

Evidence, verbatim:
> Then land again as step 9 does (1 to 4): the briefs' `Dispatched:` lines and the record's `10.` line.

Override row (2026-10-13, `feat/build-loop-u4b2`):
> Two chore merges per iteration crowd the digest's spot-check sample and activity list once the window is today (`scripts/dev-cycle.sh`; i2 performance 3) | 🟢 Consider (Low) | Defer | A dev-cycle.sh change (gate code).

The second land is unconditional. When step 10 dispatches nothing, its only payload is the `10.` line, but it still adds a chore merge to main. That doubles the chore pool that the deferred digest finding says crowds step 4's sample. It also doubles the record blobs and costs about 1.2 s of script time.

The deferral's reason (gate code) holds for the digest filter. It does not hold for this half. Skipping the land is skill text in this unit.

When steps 7-8 already show nothing to dispatch (no absent or sent-back brief, or no free slot), the `10.` line is known before step 9. The same holds when step 0.2 blocked dispatch.

**Recommendation:** When steps 0.2, 7 and 8 leave no dispatch candidate, write `10. dispatch: none: <why>` in step 9 and skip step 10's land. Land again only when a `Dispatched:` line changed, or when step 10's own `--main-log MAIN` or `--settings` turned up a block to record.

#### F4. "moved since this iteration's land" can be read as step 9's land, which step 10's own land always moves past

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:703-707` (wait, D12)
**Move:** 3 (work in the wrong place: a no-op wakeup promoted to a full iteration)
**Classification:** Macro (if misread, every idle wakeup becomes a full iteration that lands twice, which arms the next wakeup) / Hot path (idle wakeups, 48-72 a day)
**Confidence:** Low. A careful reader takes "the land" as the iteration's last, but the step has two lands and calls step 9 "Record and land".
**Legibility-target:** the orchestrator deciding whether a wakeup does anything
**Baseline:** no baseline available — flagged as speculative

Evidence, verbatim:
> with none, every 1200-1800 s, and only when the default branch moved since this iteration's land, a retry's wait ran out, or the user wrote, run a full iteration (an answer lands as a move of main); otherwise the wakeup does nothing.

Steps 9 and 10 each land. If "this iteration's land" is taken to be step 9's (the step named "land"), then step 10's land has always moved main since. Every idle wakeup would then run a full iteration, with its subagents. That iteration lands twice again, so the condition never goes false.

F1's skip spares the health check here (only `chore` lines). The step 2-4b subagents still run, about 48-72 times a day with nothing changed.

**Recommendation:** Name the commit. For example: "main is no longer the NEW of this iteration's last `landed` line (step 10's, or step 9's when step 10 did not land)".

#### F5. With a loop running, the 1800 s fallback runs a full iteration whether or not anything changed (plan-sanctioned; priced for C5's revisit)

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:703-704`; plan `docs/working/plan-build-loop-handoff.md:94-96` (D12)
**Move:** 10 (price the deployment: a per-hour cost while loops run)
**Classification:** Macro (cost scales with wall time while any loop runs) / Hot path
**Confidence:** Medium
**Legibility-target:** the user, at C5's revisit (D12: "revisit the light pass once costs are visible")
**Baseline:** no baseline available — flagged as speculative. The land time (about 1.15 s each) and health-check time (140-216 s) are measured as above. The subagent token cost per iteration is not measured.

Evidence, verbatim:
> Wait (D12): with a loop running, the next iteration starts when one finishes (its task notification), with a 1800 s fallback wakeup;

The "only when" condition attaches to the "with none" clause, so the fallback with loops running is unconditional. That matches plan D12 ("a 1800 s fallback wakeup"; C5: "a full cycle every iteration for now"). So it is not a defect.

The price is worth recording. Build loops run for hours. While any loop runs, each hour has at least two full iterations, with four or more subagents each, and four chore merges, even when no loop state changed. F1's skip, if chained, removes the health check from these iterations. The fallback is still needed for step 7's two-hour stall rule, which reads the `7.` lines of iterations.

**Recommendation:** When C5 is revisited (U5's roadmap item), use the fallback-with-no-change iterations as the first candidate for D12's light pass (steps 7, 8 and 10). Measure tokens per iteration over one day of loop operation first.

## Endorsements

- The fixed script work per iteration is about 5 s: three `--main-log` (about 0.4 s each), three or more `--state` (about 0.35 s), two `--cycle-diff` (about 0.34 s), two `--land-cycle` (about 0.47 s), a 0.48 s digest and a 0.33-0.40 s worktree add. The extra `--main-log MAIN` runs in steps 7 and 10 cover only the commits since MAIN, so they stay at the one-iteration window's cost. [unverified — submitted as claim: summed from the prior pass's probe timings at adc8a176, not re-measured at b88e418a; route: code-fact-check, `skills/dev-cycle/SKILL.md:524-527,663-665`]
- A self-merge's gate checkout adds about 0.4 s per ready self-merge brief (`--state`, then `worktree add --detach`, measured 0.33-0.40 s, and `remove --force`, 0.04 s), bounded by slots. An approved merge needs no GT, because `--merge --approved` drops the checkout rule. [read: scripts/build-loop.sh:393-427; skills/dev-cycle/SKILL.md:478-489,535-536]
- The answer read is bounded by unanswered items, not by history. `--check-answer` gets each brief's `Asked:` items and merge entries "less those on its `Applied:` line", and an applied ID is never read again. [read: skills/dev-cycle/SKILL.md:519-521,540-541]
- `Asked:`/`Applied:` lines grow only per dispatch outcome: at most one item per TIP (the "already asked about at TIP" rule), one capped entry per brief, and `Dispatched:` is replaced, not appended. D1's cap of 4 dispatches therefore bounds each brief's lines at a small constant. [unverified — submitted as claim; route: code-fact-check, `skills/dev-cycle/SKILL.md:466-470,515-517,678,682-685`]
- `--check-branch` is one batched call per iteration, at about 8 ms per name, so its cost is linear in the list it is given (see F2 for that list's growth). [unverified — submitted as claim: measured by this pass's probe on a clone; route: code-fact-check, `scripts/lib/dev-cycle-read.sh:523-539`]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The health-check skip's "earlier iteration's pass" is not tied to 0.2's one-iteration window: it alternates (strict) or skips unchecked gate code (loose); the `1.` line has no "passed" value | Medium | `skills/dev-cycle/SKILL.md:290-299,593` | Medium |
| 2 | The merged-branch entry and its per-iteration `--check-branch` grow by one name per iteration (12 s and about 1,440 paste lines at 30 days) | Medium | `skills/dev-cycle/SKILL.md:308-315` | High |
| 3 | The second land is unconditional; on no-dispatch iterations it lands one record line as a chore merge (the deferral covers only the digest half) | Low | `skills/dev-cycle/SKILL.md:687-692` | Medium |
| 4 | "moved since this iteration's land" can be read as step 9's land, which makes every idle wakeup a full iteration | Low | `skills/dev-cycle/SKILL.md:703-707` | Low |
| 5 | The 1800 s fallback with loops running is an unconditional full iteration (per D12/C5), priced for the revisit | Informational | `skills/dev-cycle/SKILL.md:703-704` | Medium |

## Overall Assessment

The scripts this branch calls stay cheap, at about 5 s of fixed work per iteration. The second land, the extra `--main-log MAIN` runs and the per-self-merge worktree each cost about a second or less.

The cost structure is the one the prior pass named: per-iteration outputs multiplied by a self-paced loop. The iteration-2 fixes (B12, B13 and C4's skip) each addressed half of that.

F1 matters most. The health check is the single largest per-iteration cost the orchestrator controls. As written, its skip rule either saves only half of what C4 meant to save, or lets a gate merge go unchecked after a given-up or failed run. A chained `1.` line fixes both.

F2 is the prior F1's remaining half. The list no longer multiplies entries, but it still grows by a name every iteration, in the user's paste block and in every questions-file read.

F3 and F4 are small, skill-text-only fixes. F5 is the plan's accepted price, and it should be measured before C5 is revisited.

None of these needs profiling to confirm the mechanism. The skip rate, the share of no-dispatch iterations and the tokens per iteration need one day of real loop operation to price.

## Goal-Alignment Note

Success criterion: "A performance review saved at the given path, structured per the performance-reviewer skill." Met.

The review is saved at `docs/reviews/performance-review-2026-10-13-u4b2-final.md` in the U4b2 worktree. It has the skill's header, data flow, findings (each with Severity, Location, Move, Classification, Confidence, Baseline, plus the brief's verbatim Evidence and Legibility-target), evidence-tagged endorsements (submitted claims marked `route: code-fact-check`), summary table and overall assessment.

Measured in this pass: the batched `--check-branch` cost at 48, 336 and 1440 names. Reused from the prior pass, with attribution: the land, `--main-log`, worktree and digest timings at adc8a176.

Not measured, and flagged speculative: the real wakeup rate, the skip rate, the share of no-dispatch iterations, and tokens per iteration.

Deferred items (the prior F3's digest half, F4 in part, the arch-11 stall timer, the F5 residual) are not re-reported, except F3's skill-text half, whose deferral reason does not cover it.

Out of scope: correctness of step texts beyond where cost depends on them. F1's loose-reading hole is a correctness consequence of the skip rule and is reported because the rule is a performance rule.
