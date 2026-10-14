# Performance Review — feat/build-loop-u4b2 (iteration 2, full branch)

**Scope:** `git diff main...HEAD` at adc8a176 (`skills/dev-cycle/SKILL.md` steps 6-10, Flow, wait rule; `test/scripts/build-loop-orchestrator.bats`), read with the script contracts it drives (`scripts/build-loop.sh`, `scripts/dev-cycle.sh`)
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b2-i1.md` (fix-range fact-check, iteration 1; it raises no performance claim) and the measurements in `docs/working/checkpoint-build-loop-handoff.md` / `docs/working/plan-build-loop-handoff.md`, plus the probes below.

## Data Flow and Hot Paths

The change turns the dev cycle into a loop. With `/loop /dev-cycle`, each iteration runs steps 0-10. The wait rule (D12, SKILL.md:670-674) wakes it on every loop completion, on a 1800 s fallback while any loop runs, and every 1200-1800 s otherwise. So the iteration body is the hot path: it runs about 48 times a day while loops run. Inside an iteration, the per-brief work (step 7's `--marker`/`--check`/`--merge`, step 10's `--start`/`--prompt`) is bounded by the open briefs (slots: 1-9, default 3). The per-iteration fixed work is: `--state`, `--main-log`, a worktree add, the digest, the health check, 4+ subagents (steps 2, 3, 4 per sampled merge, 4b), and two lands. Each land is stage, `--state`, `--cycle-diff`, commit and `--land-cycle`.

Measured on this host (probes in `/tmp/claude-1000/-workspace/3f9d7e3a-3058-4f14-a27e-9ecde97197ee/scratchpad/u4b2-i2/perf/`, run against local clones under `/tmp/u4b2rv-perf-*`, branch scripts at adc8a176):

| Call | Wall time |
|---|---|
| `--state` | 0.34-0.36 s |
| `--cycle-diff` (record only staged) | 0.33-0.35 s |
| `--land-cycle` | 0.47 s warm (1.33 s first call) |
| one full land (the three above) | about 1.15 s |
| `--main-log` over 5 / 9 first-parent commits | 0.39 / 0.43 s |
| `--status` over 3 briefs | 0.14 s |
| `--settings` | 0.03 s |
| `worktree add --detach` of main (3,544 files) | 0.33-0.40 s (5 runs) |
| `worktree remove --force` | 0.04 s |
| digest (`dev-cycle.sh`) | 0.48 s, 28 KB output, 11 decision records plus 12 log rows of triggers |

Recorded elsewhere: the full health check takes about 140 s with `--jobs 8` (142-145 s over five runs) and measured 216 s on a merged tip (`docs/reviews/q090-final-performance-review-2026-09-30.md`, `docs/reviews/code-fact-check-report-iter3-r2.md`). `--check-answer` with 41 IDs takes 313 ms (u1a fact-check). The one existing cycle record, `docs/working/cycles/cycle-2026-10-02.md`, is 177 lines and 16,209 bytes.

Conclusion on the script side: a second land, a gate worktree per self-merge and the `--main-log` window are all about a second or less each. The costs that matter are (a) what the loop repeats (the health check, the subagents) and (b) what grows with the number of iterations (branches, the per-day record, chore merges on main).

## Findings

#### F1. Every iteration leaves a merged chore branch, and step 1 files a new `you: terminal` entry listing all of them

**Severity:** High
**Location:** `skills/dev-cycle/SKILL.md:306-312` (step 1), with `:64-65` (Rules: "its branch stays"), `:258-263` (step 0.3), `:99-101` (Rules: machine-only chores)
**Move:** 4 (memory lifecycle: a collection that grows without bound) / 2 (size of N)
**Classification:** Macro (unbounded growth, quadratic total) / Hot path (once per iteration, about 48 a day)
**Confidence:** Medium. The growth of branches is certain. That a new entry is filed every iteration is the text's plain reading, but an orchestrator could choose to update one entry instead.
**Legibility-target:** the orchestrator reading step 1, and the user, who pays for each entry in attention
**Baseline:** no baseline available — flagged as speculative. The probe confirms that the branches are kept and listed as merged: after two iterations, `git branch --merged main` listed `chore/dev-cycle-2026-10-13-1200` and `chore/dev-cycle-2026-10-13-1230`.

Evidence, verbatim:
> `hg -C MAIN_WT worktree list` and `hg -C MAIN_WT worktree prune` (a locked worktree, a live loop's, is never pruned). List merged branches; deleting them needs the user's approval, so put the list in one `you: terminal` entry rather than deleting.

> A stop after step 0.3 removes WT as step 0.3 does (with `--force`, which discards WT's uncommitted edits; its branch stays).

Each iteration creates a branch `chore/dev-cycle-DATE-HHMM` (step 0.3) and lands it. Its worktree is removed, but the branch is not deleted, and deleting branches needs the user. So every iteration adds one merged branch, and step 1 of the next iteration lists all of them, each through `--check-branch`, in "one `you: terminal` entry". Neither step 1 nor the Rules say "unless an open one does", the guard that steps 0.1, 0.2 and 10 put on their entries. At about 48 iterations a day, after a week that is about 336 branch names. Unless an entry is reused, it also means 336 entries, which together hold about 56,000 names, so questions.md grows quadratically. Every iteration then pays to read that growth again: `questions.sh archive`, the digest's `questions.sh open`, `--check-answer` and `--cycle-diff`'s questions rules all read both files. The worst cost is attention: the user is shown an ever-longer paste block every iteration. This is the cost the Rules call the binding budget. The step 1 text predates this branch. This branch makes it a hot-path problem, because it is the change that runs the cycle as a self-paced loop with a branch per iteration.

**Recommendation:** Do not list `chore/dev-cycle-*` branches whose `Branch:` line sits in a landed record. Either delete them after the verified land (a single `branch -d` of the iteration's own just-merged branch; the user's approval could be given once as a standing rule), or keep a single `you: terminal` entry that each iteration updates ("unless an open one does", as the other steps say), excluding names an earlier entry already listed.

#### F2. The wait rule (D12) runs a full iteration, health check included, on every wakeup that has work, and on fallback wakeups that have none

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:670-674` (wait), `:288-297` (step 1's health check), `:638-648` (step 10's retry refusals)
**Move:** 3 (work in the wrong place: fixed per-iteration work repeated by a retry) / 7 (contention point: the health-check flock)
**Classification:** Macro (cost scales with wakeups, not with change) / Hot path (the loop body)
**Confidence:** Medium. The health check's cost is measured, but the number of wakeups depends on how loops behave.
**Legibility-target:** the orchestrator (when to run a full iteration), and the user (C5's revisit)
**Baseline:** full health check about 140 s with `--jobs 8` (142-145 s over five runs), 216 s on a merged tip, per `docs/reviews/q090-final-performance-review-2026-09-30.md` (142-145 s, five runs), `docs/reviews/pre-mortem-dev-cycle.md` (about 140 s) and `docs/reviews/code-fact-check-report-iter3-r2.md` (216 s). The wakeup counts below are speculative.

Evidence, verbatim:
> Wait (D12): with a loop running, the next iteration starts when one finishes (its task notification), with a 1800 s fallback wakeup; with none, every 1200-1800 s, and only when the default branch moved since this iteration's land, a dispatch waits for a retry, or the user wrote, run a full iteration (an answer lands as a move of main); otherwise the wakeup does nothing.

> One whose tip is no marker (step 7's working ones, and a stalled loop stopped there): `--prompt BRIEF --steal`, which takes the lock only once both it and the tip are over two hours old and refuses "under 2 hours old" until then.

There are three cases.

1. While a loop runs, the 1800 s fallback runs a full iteration whether or not anything changed. The "only when" condition attaches only to the "with none" clause.
2. With no loop running, "a dispatch waits for a retry" is enough to start a full iteration. The `--steal` retry cannot succeed for up to two hours, so up to about 6 full iterations (at 1200 s) re-run steps 0-9 only to be refused again at step 10.
3. Every completed loop starts a full iteration, so with 3-9 slots, completions add up.

Each full iteration runs the health check, about 140-216 s of `--jobs 8` CPU on the machine the loops share (D14). It also takes the flock in the git common directory that each loop's own pr-prep gate waits on, and the orchestrator itself may wait up to `HEALTH_CHECK_LOCK_WAIT=3600` for a loop's check. On top of that come four or more subagents (about 23 triggers re-decided, 2 sampled merges) and two lands, which add 2 merge commits to main (F3). Plan D12 recorded C5's answer ("a full cycle every iteration for now"), so the full iteration is by design. But the retry case and the idle fallback are wakeups where the plan's own "light pass of steps 7, 8 and 10" is all that can change anything.

**Recommendation:** Make a wakeup whose only reason is a pending retry, and the 1800 s fallback when no loop notification arrived, run only steps 7 and 10 (the D12 light pass). At the least, skip step 1's health check when main has not moved since the last iteration's green check. If that is out of scope until C5 is revisited, file it as the roadmap Next item that D12 says U5 adds, and cite these numbers.

#### F3. Two lands per iteration put 2 chore merges on main per iteration, and these crowd the digest's spot-check sample and activity list

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:655-659` (step 10's second land), `:589-591` (window from the newest record's date); consumed by `scripts/dev-cycle.sh:265-273` (merges in the window, list cut at 30) and `:427-433` (sample)
**Move:** 1 (hidden multiplication: per-iteration commits feed a per-iteration sampler) / 2 (size of N)
**Classification:** Macro (the sample's pool grows with iterations) / Hot path (each iteration's step 4)
**Confidence:** Medium. The commits are measured. The dilution follows from the digest code, which this branch does not change.
**Legibility-target:** the orchestrator (step 4 and the drift check), and the next plan unit that touches the digest
**Baseline:** measured with probe3: two iterations, each landing twice as steps 9 and 10 say, added 4 first-parent merges to main (`Merge branch 'chore/dev-cycle-2026-10-13-1200'` ×2, `...-1230` ×2). The impact on sampling is speculative.

Evidence, verbatim:
> Then land again as step 9 does (1 to 5): the briefs' `Dispatched:` lines and the record's `10.` line.

> The next digest starts its window from the newest record's date (only the file name is read)

`dev-cycle.sh:268,432`: `merges_full="$(git log "$MAIN_SHA" --first-parent --merges ...` ... `printf '%s\n' "$merges" | shuf -n "$SAMPLE" --random-source=<(yes "$seed")` (no class filter).

From the second iteration of a day on, the window is "today". Every land is a `Merge branch 'B'` commit, so after k iterations the pool holds 2k chore merges against the day's few gate merges. Step 4 starts one subagent per sampled merge. Those subagents then mostly spot-check cycle-record merges, and the drift check (which runs only "for each sampled merge a build loop made") rarely runs at all. The activity list prints 30 merges, so after 15 iterations the day's gate merges fall under "… N more". The second land also doubles the record and briefs blobs written per iteration (F4).

**Recommendation:** Have the digest leave `--main-log`'s `chore` class (or `Merge branch 'chore/dev-cycle-*'` merges) out of the sample and the activity list, or always sample the `gate` merges first. Separately, consider folding the second land into the first. `--status` already prints DISPATCHED, so N (DISPATCHED+1) is known before step 9. The cost is that a refused dispatch must then be landed as a correction, so this is a trade to weigh, not a clear win.

#### F4. The per-day record grows by about one cycle record (16 KB) per iteration, and the orchestrator reads and appends to it every iteration

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:553-591` (one file per day, a block appended per iteration), read at `:235-238` (step 0.2), `:331` (step 2: the previous verdicts), `:467-469` (step 7: the record's `7.` lines), and `:655-656` (the second land rewrites it)
**Move:** 4 (a collection that grows without bound inside its period) / 9 (quadratic total)
**Classification:** Macro (O(i) per iteration, O(n²) per day in tokens and blob bytes) / Hot path
**Confidence:** Medium. The block size is estimated from the one existing record, whose template has since gained sections.
**Legibility-target:** the orchestrator (what it must read each iteration) and the step 9 template's author
**Baseline:** `docs/working/cycles/cycle-2026-10-02.md`, a single cycle's record, is 177 lines and 16,209 bytes (measured with `wc -lc`). Per-day totals are speculative.

Evidence, verbatim:
> Write the record `docs/working/cycles/cycle-YYYY-MM-DD.md`, dated as the digest dates (`date +%F`, local time; the branch name's DATE-HHMM is UTC): one file per day, each iteration appending its own block below the earlier ones and never editing them:

Each block carries a verdict for every trigger (about 23 today) plus the roadmap diff, so it is about the size of the existing record. At about 48 iterations a day the file reaches about 780 KB, or about 200k tokens, by evening. The orchestrator reads it every iteration: it takes the last `Main at:` line, the previous verdicts as context, and the `7.` lines for the two-hour stall rule. It also appends to it twice per iteration, which with the Edit tool means reading it first. Over a day, the tokens spent on the record are therefore quadratic in the number of iterations. Each of the two lands also writes a new full blob of the growing file: about 2 × 16 KB × i per iteration before packing, or about 37 MB of loose blob bytes per day before compression and gc. The scripts' own reads, `--main-log`'s chore class and `--land-cycle`'s record rule, are a linear grep of one blob and stay cheap.

**Recommendation:** Write one record file per iteration (`cycle-YYYY-MM-DD-HHMM.md`; the digest already picks the newest file by date, and `--main-log`'s chore class would need to accept the name), or keep only the latest iteration's trigger verdicts in full and put a one-line "unchanged since HHMM" on repeats. Have step 0.2 and step 7 read only the last block (or the last two hours' `7.` lines) by line search, not the whole file.

#### F5. A lost `Dispatched:` line lets the dispatch cap admit one extra build-loop run

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:655-659`
**Move:** 10 (pricing the deployment: what an unlanded count costs)
**Classification:** Micro (one extra run per lost line) / Cold path (it needs a session to end between a dispatch and the second land)
**Confidence:** Medium
**Legibility-target:** the user (the Q-103 residual list)
**Baseline:** no baseline available — flagged as speculative

Evidence, verbatim:
> a session that ends first loses them, and the brief's count on main then reads one low per lost line (a Q-103 residual).

The text states this residual correctly. The price is worth naming: the cap of 4 (D1) is the only bound on how many times one brief is run, and each lost line buys one more full build-loop run (hours of agent time). The window in which it can happen is small: step 10's land follows the dispatch directly.

**Recommendation:** When the residual goes into Q-103's list, include the price (one extra loop run per lost line).

## Endorsements

- The second land itself is cheap: `--state` + `--cycle-diff` + `--land-cycle` measured about 1.15 s per land warm (0.34 + 0.34 + 0.47 s), so its cost is what it adds to history (F3, F4), not runtime. [unverified — submitted as claim: measured by probe3 on a clone, not by the fact-check stage]
- The per-self-merge gate checkout is cheap. `worktree add --detach` of main (3,544 files) measured 0.33-0.40 s over 5 runs, and `worktree remove --force` 0.04 s. Removing it after each call also keeps it out of the import walks' reader set. [unverified — submitted as claim: measured by probe2 on a clone]
- Step 7 reads loop state with one `--status` call and answers with one `--check-answer` call per iteration (SKILL.md:459-460, 503-505). It does not re-run `--check`/`--marker` for a brief already asked about at TIP (SKILL.md:463-464), so the per-brief gate work is not repeated across iterations. [read: skills/dev-cycle/SKILL.md:459-506]
- `--main-log`'s window is one iteration: SINCE is the previous iteration's `Main at:` (SKILL.md:585-588), so the merge-tree classifications it runs are bounded by one iteration's activity. Measured 0.39-0.43 s. [unverified — submitted as claim: bounded only while iterations keep landing records]
- `Asked:`/`Applied:` lines are bounded per brief. Each item comes from a marker, a merge entry or a cap entry tied to a dispatch, and D1's cap of 4 dispatches bounds those (SKILL.md:650-653). [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Merged chore branches accumulate, and step 1 files a new `you: terminal` entry listing all of them every iteration | High | `skills/dev-cycle/SKILL.md:306-312` | Medium |
| 2 | Full iteration (health check about 140-216 s, holding the shared flock) on fallback and retry-only wakeups | Medium | `skills/dev-cycle/SKILL.md:670-674` | Medium |
| 3 | Two chore merges per iteration crowd the digest's spot-check sample and activity list | Medium | `skills/dev-cycle/SKILL.md:655-659`; `scripts/dev-cycle.sh:265-273,427-433` | Medium |
| 4 | Per-day record grows about 16 KB per iteration and is read and appended every iteration (quadratic per day) | Medium | `skills/dev-cycle/SKILL.md:553-591` | Medium |
| 5 | A lost `Dispatched:` line buys one extra loop run (price the residual) | Informational | `skills/dev-cycle/SKILL.md:655-659` | Medium |

## Overall Assessment

The scripts this change calls are fast, and the new per-iteration mechanics cost about a second each: the second land, the gate worktree and the one-iteration `--main-log` window. The performance problem is structural, not in any call. Turning the cycle into a self-paced loop multiplies per-iteration outputs that were designed for a cycle that ran a few times a month: a branch that is never deleted, a record block about 16 KB long, two merges on main, a full health check. All four findings come from that multiplication. F1 matters most, because it grows without bound in the one budget the skill names as binding (the user's attention) and in the questions files every iteration reads. F2 and F4 are fixable in place: a light pass for retry and fallback wakeups, and per-iteration record files or a shortened block. F3 needs a one-line class filter in the digest. Before choosing between a light pass and a full iteration (C5's revisit), measure the real wakeup rate and the token cost per iteration over one day of loop operation.

## Goal-Alignment Note

Success criterion: "A performance review saved at the given path, structured per the performance-reviewer skill." Met. The review is saved at `docs/reviews/performance-review-2026-10-13-u4b2-i2.md` in the U4b2 worktree, with the skill's header, data flow, findings (each with Severity, Location, Move, Classification, Confidence, Baseline, plus the brief's verbatim Evidence and Legibility-target), evidence-tagged endorsements, summary table and overall assessment. Measured: the land, gate-worktree, `--main-log`, `--status`, `--settings` and digest timings on local clones. Not measured, and flagged speculative: the real wakeup rate, the token cost per iteration, and the per-day record size under the new template. No D6 block exists yet (Q-140), so its per-call cost (an object hash per script call) is not priced. The fact-check report covered only the fix range and raised no performance claims, so no endorsement is keyed to an execution verdict. Out of scope: correctness of the step texts, except where the cost depends on them.
