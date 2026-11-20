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


**The session transcripts give the rate and the mechanism.** These are the build-loop subagent
transcripts under the home `.claude/projects/-workspace/` (2026-10-26 to 2026-11-20). For each
loop, the first recorded `cwd` was read and the refusal text "no longer exists, so this command
was not run" was looked for. The review's recount from each first user message agrees on the WT
row and finds 35, not 41, on the `/workspace` row:

| Loop's first cwd | Loops | Refused at least once |
|---|---|---|
| the orchestrator's WT | 69 | 31 (about 45%) |
| `/workspace` (MAIN_WT) | 35 to 41 | 2 |

Both `/workspace` refusals are real tool errors (`is_error` true), in session 42e4626f. Their
per-record `cwd` shows what happened:
- agent-a08c3a90: `/workspace` at 01:14Z, then `wt-dev-cycle-2026-11-20-0121` at 01:22, a WT
  that a later iteration made after this loop was dispatched. Refused at 01:29 when that WT was
  removed. Afterwards it moved to `…-0128`, `/workspace`, `…-0215` and `/workspace` again.
- agent-a6a84b1a: `/workspace` at 03:20Z, then `wt-dev-cycle-2026-11-20-0331` at 03:37.
  Refused at 03:38.

The three loops the orchestrator parked by hand (loops-wait-foreground,
subagent-report-files-listing, steal-wait-research) started in `/workspace` and were never
refused. The herald triage loop, dispatched without a park, was refused once.

## The probe (acceptance 3)

**The full probe cannot run hermetically.** The question is how Claude Code picks a
subagent's working directory. Answering it needs a live main session and the Agent tool, and
CLAUDE.md and H3 rule out a live `claude` in tests. It cannot run from inside a subagent
either: a subagent's `cd` does not carry over between calls, so it cannot set itself up the way a
main session would. So the decision rests on four things: the platform's own statement, what
happened in this dispatch, the transcripts above, and one hermetic shell probe.

**This dispatch, observed.** This loop's environment named its working directory as
`/workspace/.worktrees/wt-dev-cycle-2026-11-20-2107` ("a git worktree"), the orchestrator's WT.
The first two Bash calls, each starting `cd /workspace/.worktrees/wt-2026-11-20-loop-start-dir-research && ...`,
ran. The third, written the same way, was refused at about 2026-11-20T21:10Z with this message:
"Working directory "/workspace/.worktrees/wt-dev-cycle-2026-11-20-2107" no longer exists, so
this command was not run. Shell cwd recovered to "/workspace"". Main had just moved to
1e88e0d9, the orchestrator's land, and WT was gone from `git worktree list`.

Four facts follow:
1. **A subagent's Bash call runs in the main session's cwd at the moment of the call.** It is
   not fixed at dispatch. The two traces above show a running loop following the orchestrator
   into each new iteration's WT and back out. A subagent's own `cd` lasts one call.
2. **Why that cwd is WT, despite D13.** The Bash tool's own description for a main session
   says: "`cd` carries to the next call only in the main session, if the command succeeds and
   ends inside the working directories. Outside them the shell returns to the start folder".
   So the shell cannot "stay" in a temp directory outside the working directories. Every
   `cd WT && …` in the D6 form the Rules give (`cd WT && bash /opt/claude-workflows/scripts/d6.sh …`,
   SKILL.md lines 52-55) leaves the orchestrator's shell in WT. The D13 bullet's premise ("not a
   git checkout", "fails with 'not a git repository'") does not hold as written, and neither
   does the prompt's "Your shell starts outside any checkout".
3. **The loss happens when WT is removed while the main shell still sits in it.** Step 0.3's
   removal (`git -C MAIN_WT worktree remove WT`) names its target with `-C`. If it runs while
   the shell is in WT, the shell is left in a removed directory. Then every subagent's next call
   is refused once, and so is the orchestrator's. The harness moves the shell to `/workspace`,
   and later calls run. The refused call is whichever comes first after the removal: here the
   third, in the triage the sixth, in herald the first.
4. **No wording in the prompt can prevent it.** The refusal is Claude Code's check, made
   before the command runs ("so this command was not run"), so the loop's `cd` never runs.

**Hermetic shell probe.** It ran in a temp dir under this session's scratchpad, created and
entered in the same script, aborting on failure and cleaned with `rmdir`. A subshell `cd`s into
`wt` and removes it. Then builtin `pwd` prints the stale path, `/bin/pwd` fails ("couldn't find
directory entry in '..'"), `ls .` lists nothing, and `cd` to an existing absolute path works.
So a removed cwd stops nothing in bash: the lost call comes from the harness's check.

Why the three parked loops were never refused: an inference, not checked against the
orchestrator transcript. Their orchestrator's later commands must have left its shell outside WT
when WT was removed. A park only at dispatch would not ensure that, because the land after
dispatch runs `cd WT && …` again (fact 1).

## Divergent design (acceptance 4)

The options are seeded with the brief's constraints and `docs/constraints.md`. Fact 1 changes
group F's framing. What matters is where the main shell sits when a WT is removed, not where it
sits at dispatch. So one option is added: R, remove from a parked shell.

| Option | What it changes | Paths | Owner reading | Removes the loss? |
|---|---|---|---|---|
| **R. Remove from a park** | each WT/HC/GT removal runs `cd WTB && git -C MAIN_WT worktree remove …` | `skills/dev-cycle/SKILL.md` | one merge entry | yes, for every loop |
| **1/1b. Park at dispatch** | one `cd MAIN_WT` (or `cd WTB`) call before the Agent calls | same | one merge entry | no: the land's `cd WT` undoes it |
| **2. Defer WT removal** | step 0.3 removes the previous WT next iteration | same | one merge entry | mostly; leaves a WT at session end |
| **3. Warn in the prompt** | `--prompt` says a call may be refused | `scripts/build-loop.sh` | one merge entry | no |
| **4. Status quo** | nothing | none | none | no |

`skills/dev-cycle/` and `scripts/build-loop.sh` are GATE_CODE, the paths whose change needs a
review merge (`scripts/lib/dev-cycle-read.sh` line 1037). Neither is an enforcement file.

One option was dropped: adding the temp dir as a working directory at launch (`--add-dir`), so
that D13 holds. It means growing `cc-isolated.sh`, which is over 500 lines (S8), and a host step
(S10), to keep a property R gives at no host cost.

Notes per option:
- **R.** WTB, the `.worktrees` directory, exists for the whole session: step 0.3's
  `--worktree-base` makes it, and nothing removes it. A `cd WTB && …` removal leaves the main
  shell in WTB, which outlives every WT. No loop or orchestrator call then starts in a removed
  directory. There are three removal sites: SKILL.md line 338 (step 0.3; step 10's "Then remove
  WT" at line 1065 points there), the stop path's `worktree remove --force` (line 76), and HC
  and GT (lines 401 and 749, "removed as step 0.3 removes WT"). If line 338 names the form, the
  others follow it. The D13 bullet is corrected to say what the shell does. The prompt line
  becomes "Your shell runs where the orchestrator's does, a checkout that is not yours: start
  every command with cd DIR &&".
  Exposure is unchanged in kind. A loop command that forgets its `cd` runs in the orchestrator's
  current directory under every option (fact 1), and R adds only time spent in WTB, an ignored
  directory. A forgotten-`cd` git command in the orchestrator, in the window between a removal
  and its next `cd WT`, would run against MAIN_WT's repository. That is the checkout the cycle
  "reads but never commits in" (SKILL.md lines 234-235). Every orchestrator command already names
  its checkout.
  For H3, a bats pin on the removal form and the corrected sentences, as other skill lines are
  pinned. The cwd mechanism itself cannot be tested hermetically. Its S6 observable is in
  transcripts and can come out negative.
- **1/1b.** These are dominated by R. Under fact 1 the park lasts only until the orchestrator's
  next `cd WT && …`, which is step 10's land. A loop that outlives the removal is refused as
  before, unless the removal itself runs from a park, and then the park is R.
- **2.** WT is removed while the shell is in WT2, so running loops are not hurt. But a session
  that ends leaves its last WT behind (S10: nothing left to clean up), and a stop path still
  removes from inside WT. Dominated by R.
- **3.** It names the cost and does not remove it, and loops already resend on their own. It adds
  a line to every prompt for no saving. Dominated by R.
- **4.** Valid on cost alone: one call per affected loop, about 45% of loops. It leaves two
  false sentences, and one of them states a safety property ("fails with 'not a git
  repository'") that the platform does not give.

**Pick (Path A): R, remove every worktree from a shell parked in WTB, and correct the D13
bullet and the prompt line.** It dominates 1/1b, 2 and 3. It beats 4 because, for one review, it
removes a loss seen in about 45% of WT-started loops and in the orchestrator's own next call,
and it corrects a stated safety property that does not hold. Its cost is one review merge.

Other choices, one line each:
- A live Agent-tool probe from this loop: not run. It is not hermetic, a subagent cannot set up
  a main-session cwd, and the transcripts answered the question.
- Decision log row 72 and plan D13's wording: left as they are. They are records on the
  self-merge floor, and the brief below changes only the live sentences.

## For the dev cycle

Suggested brief: **Remove the cycle's worktrees from a parked shell (herald F-008).**
- Goal: step 0.3's removal runs as `cd WTB && git -C MAIN_WT worktree remove WT`, so the main
  shell (which every subagent call runs in) is never left in a removed directory. Step 10's
  "Then remove WT", the stop path's `--force` removal, and HC and GT "as step 0.3 removes WT"
  inherit the form. The Rules' D13 bullet says what the shell does: it ends in the checkout its
  last `cd` named, and subagents run there. The build-loop prompt's "Your shell starts outside
  any checkout" becomes "Your shell runs where the orchestrator's does, a checkout that is not
  yours".
- Paths: `skills/dev-cycle/SKILL.md`, `scripts/build-loop.sh` (the prompt line only), `test/`
  (pins).
- Policy: review (gate code).
- Tests: bats pins on the removal form, the D13 wording and the prompt line, and the existing
  `--prompt` tests updated. Observable (S6): over the next iterations' build-loop transcripts,
  no "no longer exists, so this command was not run" refusal in a loop that spans a WT removal.
  It is negative if any appears with the orchestrator in WTB.
