# Research: the loop wait rule and return-as-text clause in `loop_prompt`

- **Goal**: land change A (a wait-inside-your-turn rule, and "background agents" reworded to "agents that outlive your run") and change B (research and review subagents return their reports as text) in `loop_prompt`, with `test/scripts/build-loop-dispatch.bats` pinning both.
- **Task status**: complete pending review (see Review below).

Brief: `docs/working/briefs/2026-11-19-loop-wait-rule.md` at 5e335ef8. Branch: `fix/loop-wait-rule`. Policy: review.

Inputs read whole: `docs/working/research-2026-11-19-loops-wait-foreground.md` (wait research, "Drafted wording"), `docs/working/research-2026-11-19-subagent-report-files-listing.md` ("Proposed wording for B"), `docs/constraints.md`, `loop_prompt` in `scripts/build-loop.sh` (1951-1984), `test/scripts/build-loop-dispatch.bats`.

Failure-pattern grep: FP-124

(`rg -n '^\s*- \*\*FP-' docs/failure-patterns.md | rg -i 'wait|idle|handback|background|subagent|report file'`: FP-124, a headless top-level run's background-wait ceiling, the prior art the wait research cites as E5; FP-148 is a lock waiter, unrelated.)

Failure-pattern skip: the cause (a subagent's turn end ending its run, inference I1 in the wait research) is an unconfirmed harness behaviour (its L3); an entry should wait until the S6 count below shows the rule holds.

## Live checks (acceptance criterion 2)

Run in this dispatched build loop, 2026-11-20 about 00:04-00:06 UTC, one Claude Code version.

- **L1 (does a subagent's report arrive between a loop's tool calls?): positive.** I started one read-only general-purpose reviewer (it read `loop_prompt` and the bats file and returned text), then did not end my turn: I made two Bash calls, the L2 probes below (about 11 s and 33 s). The report arrived as a message right after the second call returned; the harness's own notification put the reviewer's run at 21 s. So the report is delivered between tool calls while the loop keeps making them, and a long Bash call also serves as a wait: the report waits for the call to end, it does not interrupt it. This is the second positive after the wait research's E6, and the first in a dispatched build loop.
- **L2 (is the drafted bounded `until` command allowed?): positive.** In `$SCRATCHPAD/2026-11-19-loop-wait-rule/l2`: `timeout 540 sh -c 'until test -e "$1"; do sleep 2; done' _ ./FILE` with a background `touch` at 6 s returned exit 0 after 6 s; the same with `sleep 15` and the file at 20 s returned 0 after 33 s; a `timeout 5` wait on a file that never appears returned 124 after 5 s. None was refused by the harness's "foreground sleep is blocked" steer, which here fires on a bare `sleep`, not on one inside `sh -c`. The file-wait half of the rule stays.
- Round count (the wait research's last gotcha): this reviewer took 21 s and two tool calls. Not measured for a full code-review round.

## Design

Constraints that bind: S3 (one source per rule: the rule says how to wait; when to wait stays with pr-prep and code-review), S4, S6 (an observable that can come out negative), H3 (hermetic bats), S8 (one revert).

Placement was settled by the wait research (Path A, one rule in `loop_prompt`); not reopened. Change B's wording is as proposed, unchanged. Other choices, each with fewer than three viable options:

- **The wait's exit**: `handoff: stopped: REASON` naming what did not finish, over the drafted `handoff: blocked`. `ready` is out (no clean review-fix loop), and `blocked` is for a question or fact only the owner has, with an options table the loop could not honestly fill; a reviewer that never reported is a stop the orchestrator re-dispatches, which `stopped` with a short reason (1 to 120 characters) already carries.
- **The bound: 30 minutes, kept.** It rests on: observed review subagents of 21 s (L1), 49 s and 76 s (wait research E6); one Bash file wait of 9 minutes (the 540 s inside a 600000 ms call) fitting three times; and the two-hour re-dispatch rule (decision D1 in `docs/working/plan-build-loop-handoff.md`), which 30 minutes stays a quarter of. A full code-review with replicates and Stage 2 critics has no measured duration here, so 30 minutes is a guess for that case; the S6 count below catches it if loops start stopping on it.
- **Placement within the prompt**: the wait rule is its own heredoc line after the "Start subagents only" line, so the existing grep of that line (test 2) is untouched; B's clause goes inside that line, keeping both pinned substrings ("under $s/ in your scratchpad directory", the merge clauses).
- **Pausing between reads**: L1 shows a Bash call holds the report until it returns, so a bounded pause would also work as a subagent wait. Left out: the rule stays as drafted (short reads), and naming a `sleep` inside `sh -c` as a way round the harness's sleep steer is not something to write into a prompt.
- **`\$1`**: the heredoc is unquoted, so the line has `"\$1"`; test 3 asserts the printed `"$1"` and that the brief's path is not on the line, and dropping the backslash fails it (checked by mutation).

## S6 success measure

Count early hand-backs (a loop ending with no marker, "ended with no marker" in the cycle records' step-7 lines under `docs/working/cycles/`) over the next 20 dispatches after this lands. The base rate is about two in ten (2026-11-19), so about four would be expected without the rule. Zero to two supports it; **three or more means revert** (one `git revert` of the fix commit). Count loops that end `handoff: stopped` on the 30-minute bound separately: several of those say the bound is too short, not that the rule fails.

## Verification

- `bats test/scripts/build-loop-dispatch.bats`: 11 of 11 pass (new test 3; test 1's pinned "Never start build loops ..." substring updated).
- `scripts/hermeticity-lint --root .`: passes (145 files).
- Mutation: removing the `\` before `$1` makes test 3 fail.

## Review

(Filled in by the review-fix loop below.)
