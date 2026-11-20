# Research: where a dispatched build loop's shell starts, and the removed worktree's lost call

Brief: `docs/working/briefs/2026-11-20-loop-start-dir-research.md` (at 1d98447b).
Branch: docs/loop-start-dir-research. Dispatch 1. Research only: this doc is the whole output.

Failure-pattern grep: FP-068, FP-076

(Terms: worktree, cwd, working directory, start dir, removed, subagent. No entry matches.
FP-068, "gate artifacts generated then deleted with the worktree", and FP-076, "headless read
confined to cwd", are the nearest, as the herald triage found; neither bears on the pick.)

## Read (acceptance 1)

- F-008 in `docs/working/feedback/belegarth-herald.md`: 9 refused first Bash calls in build
  loops, 2026-11-02 to 2026-11-07, "working directory ... is gone", each sent again.
- Group F and its recommendation in `docs/working/research-2026-11-19-herald-friction-triage.md`:
  four approaches (cd to MAIN_WT before dispatch, defer WT's removal, warn in the prompt, status
  quo), unpicked; first step a probe of whether a main-session `cd` moves a subagent's start dir.
- `skills/dev-cycle/SKILL.md`: step 0.3 (lines 330-339) removes WT "once step 10's land is
  verified"; step 10 (line 1012 on) starts loops as background subagents with no isolation, then
  lands again from WT and removes it (line 1065). The Rules' D13 bullet (lines 28-35) says
  the orchestrator's shell "stays in `dev-cycle-orchestrator/` under the session's temp
  directory ... not a git checkout", and every command names its checkout (`cd WT && …`).
- `scripts/build-loop.sh` line 2006, the prompt `--start`/`--prompt` print: "Your shell starts
  outside any checkout: start every command with "cd $DIR &&"."
- `docs/constraints.md`: S5 (motive first, status quo valid), S10 (owner attention last),
  H3 (hermetic verification).

## Motive (acceptance 2, S5)

The brief asks how many dispatches lost a first call since the prompt gained its "start every
command with cd" line. That line is not newer than F-008: `git log -S` dates both
"Your shell starts outside any checkout" and "start every command with" to aff397585
(2026-10-10), the commit that created `--start`/`--prompt`. Every loss on record happened with
the line in the prompt, so it was never a fix for F-008.

Known losses, all with the line present:
- 9 in herald (F-008, from transcripts, 2026-11-02 to 2026-11-07).
- 1 in the herald triage's own dispatch (2026-11-19, its sixth call, per its research doc).
- 1 in this dispatch, observed directly (below).

The cycle records (`docs/working/cycles/`) and the other feedback file
(`philosophy-research.md`) do not record a refused call, so the records alone give no rate.
They do record option 1 being tried twice by hand. `cycle-2026-11-19.md` line 751
(iteration 2026-11-19-2338) says "the orchestrator's shell was moved to `/workspace` before
the Agent calls, an informal check on herald F-008". Line 983 (iteration 2026-11-20-0110)
says "the shell was moved to `/workspace` first". Neither records an outcome.

**The session transcripts give the rate and the outcome.** These are the build-loop subagent
transcripts under the home `.claude/projects/-workspace/` (2026-10-26 to 2026-11-20, 110 loops).
Each loop's first recorded `cwd` was read, and the refusal text "no longer exists, so this
command was not run" was counted:

| Loop started in | Loops | With the refusal text | Without |
|---|---|---|---|
| the orchestrator's WT | 69 | 31 | 38 |
| `/workspace` (MAIN_WT) | 41 | 2 | 39 |

The two `/workspace` hits are not tool errors (no `is_error` result carries them). They are
most likely the text being quoted, for example from F-008. The two hand-tried loops
(loops-wait-foreground, subagent-report-files-listing) and steal-wait-research all started
in `/workspace` with no refusal. The herald triage loop, dispatched without the move, started
in WT and was refused once. So about 45% of WT-started loops lose a call, and parking first
removes the loss. Option 1's premise has been watched, not only predicted.

Cost per loss: one Bash call that is not run and is sent again. The harness then moves the
loop's shell to `/workspace` (MAIN_WT), and later calls run. No loss of correctness was
recorded. The status quo is a valid outcome on cost alone.

## The probe (acceptance 3)

**The full probe cannot run hermetically.** The question is how Claude Code's Agent tool picks
a subagent's start directory, which needs a live main session and the Agent tool (CLAUDE.md
and H3: no live `claude` in tests). It also cannot run from inside a subagent: here `cd` does
not carry over between Bash calls, so a subagent cannot set itself up the way a main session
would. So the decision rests on the platform's own statement, on what happened in this
dispatch, and on one hermetic shell probe.

**This dispatch, observed.** This loop's environment named its primary working directory as
`/workspace/.worktrees/wt-dev-cycle-2026-11-20-2107` ("a git worktree"): the orchestrator's
WT, not a temp directory and not `/workspace`. The first two Bash calls, both starting
`cd /workspace/.worktrees/wt-2026-11-20-loop-start-dir-research && ...`, ran. The third,
written the same way, was refused at about 2026-11-20T21:10Z: "Working directory
"/workspace/.worktrees/wt-dev-cycle-2026-11-20-2107" no longer exists, so this command was not
run. Shell cwd recovered to "/workspace"". Main had just moved to 1e88e0d9, the orchestrator's
land, and WT was gone from `git worktree list`. Later calls ran from `/workspace`.

Four facts follow:
1. **The start directory is the main session's cwd at dispatch time, not its start folder.**
   The recovery went to `/workspace`, the session's start folder, so the orchestrator had
   started there and had a persisted cwd of WT when it dispatched.
2. **Why the shell was in WT, despite D13.** The Bash tool's own description for a main
   session says: "`cd` carries to the next call only in the main session, if the command
   succeeds and ends inside the working directories. Outside them the shell returns to the
   start folder". So a shell cannot "stay" in a temp directory outside the working
   directories, and every `cd WT && …` the D13 rule asks for leaves the orchestrator's shell
   in WT. Step 10's `--start BRIEF` (line 1034), run in the D6 form the Rules give
   (`cd WT && bash /opt/claude-workflows/scripts/d6.sh …`, lines 52-55), comes just before
   each Agent call, so every loop starts in WT. The D13 bullet's
   premise ("not a git checkout", "fails with 'not a git repository'") does not hold as
   written, and neither does the prompt's "Your shell starts outside any checkout".
3. **The check runs before any call while the directory is gone, not only the first.** A
   subagent's cwd resets to its start directory before every call, so the refused call is
   whichever comes first after removal: here the third, in the triage the sixth, in herald
   the first. It is refused once; the harness then moves the start directory to `/workspace`.
4. **No wording in the prompt can prevent it.** The refusal is Claude Code's check before
   the command runs ("so this command was not run"), so the `cd` that would have fixed it never
   runs. The hermetic probe below shows bash alone has no such problem.

**Hermetic shell probe** (temp dir under this session's scratchpad, created and entered in the
same script, abort on failure, cleaned with `rmdir`): a subshell `cd`s into `wt`, removes it,
then runs commands. Builtin `pwd` prints the stale path, `/bin/pwd` fails ("couldn't find
directory entry in '..'"), `ls .` lists nothing, and `cd` to an existing absolute path works.
So a removed cwd stops nothing in bash: the lost call is the harness's check.

What the transcripts verified: a main-session `cd /workspace` before the Agent calls gives the
loops that start directory, with no refusal. Not yet watched: `cd WTB` (option 1b). Facts 1
and 2 predict the same result for WTB, since it is inside the working directories just as
`/workspace` is. The suggested brief makes that its observable.

## Divergent design (acceptance 4)

Seeded with the brief's constraints and `docs/constraints.md`. Group F's four, plus one
variant (1b) the probe turned up, plus one dropped:

| Option | What it changes | Paths, gate code? | Owner reading | Removes the loss? |
|---|---|---|---|---|
| **1. Park in MAIN_WT** | step 10: one `cd MAIN_WT` call before the Agent calls | `skills/dev-cycle/SKILL.md`, gate code: review merge | one merge entry | yes, observed (41 loops) |
| **1b. Park in WTB** | the same, with `cd WTB` (`.worktrees`, git-ignored, in MAIN_WT) | same as 1 | one merge entry | yes, predicted |
| **2. Defer WT removal** | step 0.3 removes the previous WT next iteration | `skills/dev-cycle/SKILL.md`, gate code | one merge entry | no, it moves |
| **3. Warn in the prompt** | `--prompt` says the first call may be refused | `scripts/build-loop.sh`, gate code | one merge entry | no |
| **4. Status quo** | nothing | none | none | no |
| dropped: add the temp dir as a working dir | make D13 true at session launch (`--add-dir`) | `cc-isolated.sh`, over 500 lines | host step | yes |

Notes per option:
- **1 / 1b.** One sentence, plus two corrections the same review would carry. The D13
  bullet says what the shell really does: it ends in the checkout its last `cd` named, so
  park it before dispatch. The prompt's "Your shell starts outside any checkout" names the
  parking place (for 1b, the wording under "For the dev cycle"). With several free slots,
  step 10 today runs `--start`, then the Agent call, then the next `--start` (`cd WT && …`
  again). So the order must change: every `--start`/`--prompt` first, then the park in its
  own response, then all the Agent calls together. Otherwise only the first loop is covered.
  Exposure for loops: nothing new. Today a loop that forgets its
  `cd` writes into WT before the removal and into `/workspace` after it. Under 1 it writes into
  `/workspace` from the start. Under 1b a stray relative write lands in the ignored
  `.worktrees/` and not in main's tracked tree, while git commands behave the same as under 1
  (both resolve to MAIN_WT's repository). Exposure for the orchestrator: small but new. From
  the park until its next `cd WT && …`, a git command that forgets its `cd` would run against
  MAIN_WT, the checkout the cycle "reads but never commits in" (SKILL.md lines 234-235). Today
  that same slip hits WT's chore branch. Every orchestrator command already names its checkout,
  and the window is only the Agent calls. WTB exists at dispatch time: step 0.3's
  `--worktree-base` makes it, and nothing removes it. H3: a bats pin
  on the step-10 sentence and on the prompt's new wording, as other skill lines are pinned. The
  start directory itself cannot be tested hermetically. S6's observable is in the next loops'
  environment, and it could come out negative. For option 1 it has already come out positive:
  41 loops started in `/workspace` with no refusal.
- **2.** Loops still running when the next iteration removes the old WT lose a call then. The
  cost moves rather than goes, and a session that ends leaves a WT behind (S10: nothing left to
  clean up). Until then, a stray write lands in a stale chore checkout, which is worse than 1.
  Dominated by 1.
- **3.** Names the cost and does not remove it, and loops already resend on their own (every
  recorded case). A line in every loop's prompt for no saving. Dominated by 1.
- **4.** Valid on cost (one call per loop), but it leaves two false sentences in place, and one
  of them states a safety property (a misplaced orchestrator command "fails with 'not a git
  repository'") that the platform does not give.
- **Dropped:** a host or launcher change (S8: no growth of `cc-isolated.sh`; S10: a host step)
  to keep a property that 1b gives at no host cost.

**Pick (Path A): option 1b, park in WTB before dispatch, carrying the two corrections.** It
dominates 2 and 3 on every axis. It beats 4 because, for one review, it removes a loss seen in
about 45% of WT-started loops and corrects a stated safety property that does not hold. 1b
beats 1 on stray writes and is otherwise the same. Option 1 is the observed fallback: if WTB
does not take as the start directory, use `/workspace`. Its one cost is a review merge, the owner reading one merge entry,
because `skills/dev-cycle/` and `scripts/build-loop.sh` are GATE_CODE
(`scripts/lib/dev-cycle-read.sh` line 1037). Neither is an enforcement file.

Other choices, one line each:
- Whether to run a live Agent-tool probe from this loop: no. It is not hermetic, a subagent
  cannot set up a persisted main-session cwd, and the transcripts already answer it for
  option 1.
- Whether to also fix decision log row 72 or plan D13's wording: no. They are records on the
  self-merge floor; the brief below changes the live sentences only.

## For the dev cycle

Suggested brief: **Park the orchestrator's shell in WTB before step 10's Agent calls.**
- Goal: step 10 runs every `--start`/`--prompt` first, then sends one `cd WTB` Bash call in
  its own response, then all the loops' Agent calls in the next response, with no `cd WT && …`
  call between. That way every loop starts in a directory that outlives WT. The
  Rules' D13 bullet says what the shell does: it ends in the checkout its last `cd` named. The
  build-loop prompt's "Your shell starts outside any checkout" becomes "Your shell starts in
  the main checkout's `.worktrees` directory, not in your worktree".
- Paths: `skills/dev-cycle/SKILL.md`, `scripts/build-loop.sh` (the prompt line only), `test/`
  (pins for both sentences).
- Policy: review (both are gate code).
- Tests: bats pins on the new step-10 sentence, the D13 wording and the prompt line; the
  existing `--prompt` tests updated. Observable (S6): the next dispatch's loop environment
  names WTB as its working directory, and no loop reports "no longer exists" after the land.
  If a loop still starts in WT, WTB did not take: switch the park to `/workspace`, option 1,
  which the transcripts show working.
