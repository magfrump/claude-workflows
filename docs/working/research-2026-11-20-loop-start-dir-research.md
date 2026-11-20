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
1. **A subagent's Bash call runs in the main session's cwd, which can lag by a command.** It is
   not fixed at dispatch: the two traces above show a running loop following the orchestrator
   into each new iteration's WT and back out. A subagent's own `cd` lasts one call. The
   lag shows at 23:29:50Z (below): a loop call made seconds after a removal that ended in
   `/workspace` still ran in the removed WT.
2. **Why that cwd is WT, despite D13.** The Bash tool's own description for a main session
   says: "`cd` carries to the next call only in the main session, if the command succeeds and
   ends inside the working directories. Outside them the shell returns to the start folder".
   So the shell cannot "stay" in a temp directory outside the working directories. Every
   `cd WT && …` in the D6 form the Rules give (`cd WT && bash /opt/claude-workflows/scripts/d6.sh …`,
   SKILL.md lines 52-55) leaves the orchestrator's shell in WT. The D13 bullet's premise ("not a
   git checkout", "fails with 'not a git repository'") does not hold as written, and neither
   does the prompt's "Your shell starts outside any checkout".
3. **The loss happens when WT is removed while subagents' cwd is still WT.** Step 0.3's
   removal (`git -C MAIN_WT worktree remove WT`) names its target with `-C`, so nothing makes
   the shell leave WT first. Then every subagent's next call is refused once, and often the
   orchestrator's next call is too (01:10:41Z and 03:09:43Z, but not 01:28:40Z). The harness
   moves the shell to `/workspace`, and later calls run. The refused call is whichever comes
   first after the removal: here the third, in the triage the sixth, in herald the first.
4. **No wording in the prompt can prevent it.** The refusal is Claude Code's check, made
   before the command runs ("so this command was not run"), so the loop's `cd` never runs.

**Hermetic shell probe.** It ran in a temp dir under this session's scratchpad, created and
entered in the same script, aborting on failure and cleaned with `rmdir`. A subshell `cd`s into
`wt` and removes it. Then builtin `pwd` prints the stale path, `/bin/pwd` fails ("couldn't find
directory entry in '..'"), `ls .` lists nothing, and `cd` to an existing absolute path works.
So a removed cwd stops nothing in bash: the lost call comes from the harness's check.

**Which removal forms were followed by a refusal.** The orchestrator transcript (session
42e4626f, 2026-11-19 23:00Z to 2026-11-20 19:20Z) has 37 commands that remove a `wt-dev-cycle-`
worktree. Its loops' transcripts hold 18 refusal records: 17 distinct refusals plus one
undated duplicate. Every one follows one of these removals by seconds to minutes. Three cases settle the form:
- **Its own command, ending in `/workspace`, still refused.** At 23:29:50Z,
  `cd /workspace && git -C /workspace worktree remove …/wt-dev-cycle-2026-11-19-2316 && echo removed`
  succeeded. The command started in WT, since the previous command had `cd`'d there. Two loops
  (agent-aefda26c at 23:29:52Z and agent-a644aeb8, the herald triage loop, at 23:29:54Z)
  were refused for that WT. The same form at 23:43:48Z (2338) and 00:04:40Z (2351) was
  followed by no refusal, but few loop calls may have fallen in those windows.
- **Inside a land chain** that starts `cd WT && …`, the dominant form: 15 of the 17 refusals
  follow one. Examples: 01:28:32Z (wt-0121, 3 refusals), 05:42:55Z (wt-0532, 4 loops),
  17:52:44Z (wt-1748, 3 loops), and 0128, 0331, 0720, 1904 and 1917.
- **Inside a chain that failed after the removal.** At 01:10:35Z,
  `cd /workspace && git -C /workspace worktree remove …-0056 && bash …d6.sh build-loop.sh --state && …`
  removed WT, but a later step failed. The Bash tool keeps a `cd` only when the whole command
  succeeds, so the orchestrator's shell stayed in the removed WT, and its next call (01:10:41Z)
  was refused.

So no form tried so far is shown safe. A removal that runs in a command starting in WT can be
followed by refused loop calls even when it ends elsewhere. That fits a cwd lag of one command.
What no transcript shows is a removal whose command starts outside WT, after a separate
earlier call that moved the shell. The record's per-line `cwd` field does not say reliably where
a command started (at 05:42:55Z it reads `/workspace` right after a `cd WT` call), so the
transcripts cannot sort the other 34 removals by start directory.

## Divergent design (acceptance 4)

The options are seeded with the brief's constraints and `docs/constraints.md`. Fact 1 changes
group F's framing. What matters is where subagents' cwd points when a WT is removed, not where
it pointed at dispatch. So two options are added: R1, remove in the same command after parking,
and R2, park in its own call and then remove.

| Option | What it changes | Owner reading | Removes the loss? |
|---|---|---|---|
| **R1. Park and remove in one command** | `cd WTB && git -C MAIN_WT worktree remove X` | one merge entry | no: refused at 23:29:50Z |
| **R2. Park, then remove** | one `cd WTB` call, then the removal in a later call | one merge entry | predicted, not observed |
| **1/1b. Park at dispatch** | one `cd MAIN_WT` (or WTB) call before the Agent calls | one merge entry | no: the land's `cd WT` undoes it |
| **2. Defer WT removal** | the next iteration's step 0.3 removes the previous WT | one merge entry | yes, structurally |
| **3. Warn in the prompt** | `--prompt` says a call may be refused | one merge entry | no |
| **4. Status quo** | nothing | none | no |

Paths: every option but 3 and 4 is `skills/dev-cycle/SKILL.md`, and 3 is
`scripts/build-loop.sh`. Both are GATE_CODE, the paths whose change needs a review merge
(`scripts/lib/dev-cycle-read.sh` line 1037). Neither is an enforcement file.

One option was dropped: adding the temp dir as a working directory at launch (`--add-dir`). It
grows `cc-isolated.sh`, which is over 500 lines (S8), and needs a host step (S10). It also
would not fix the lag.

Notes per option:
- **R2.** WTB, the `.worktrees` directory, exists for the whole session: step 0.3's
  `--worktree-base` makes it, and nothing removes it. A bare `cd WTB` call cannot fail after
  the `cd`, so the shell stays in WTB. The removal then starts in WTB, and even a subagent
  lagging by one command sees WTB. The removal commands it covers are listed below.
  - WT: line 338, and step 10's "Then remove WT" at line 1065, which points to it.
  - WT on a stop, with `--force`: line 76.
  - HC: lines 398-399. HC on a stop, with `--force`: line 401. An HC left by an earlier
    iteration: lines 402-403.
  - GT: line 749.

  Separately, `--free-worktrees` (lines 426-428) needs nothing after it in its command. Its
  cost is one extra orchestrator call per removal. Its risk is the lag: it has never been
  watched, and it fails if the lag is ever longer than one command.
- **2.** Under 2, WT is removed while the main shell has run many commands in WT2, so no
  subagent's cwd can still be WT, whatever the lag. Its costs:
  - It keeps one WT on disk between iterations, and a session that ends leaves its last WT
    until the next session's step 0.3. That needs a leftover-removal rule like HC's (lines
    402-403), so nothing is left for the user to clean up (S10).
  - It changes step 0.3's logic, not just a command's form.
  - The stop paths still remove from inside WT. A stop's `--force` removal would also defer, or
    use R2.
  - GT and HC are made and removed within one iteration, so they still need R2's form or a
    deferral of their own.
- **R1** is refuted by the 23:29:50Z case. **1/1b**: the park lasts only until the next
  `cd WT && …`. **3** names the cost and does not remove it. **4** costs about one call in
  45% of loops, and leaves two false sentences, one of them a safety property ("fails with
  'not a git repository'") that the platform does not give.

Every live option corrects the D13 bullet (what the shell does: it ends in the checkout its
last successful `cd` named, and subagents run there) and the prompt line ("Your shell runs where
the orchestrator's does, a checkout that is not yours: start every command with cd DIR &&").

**Pick (Path A): R2, park in its own call and then remove, with option 2 as the recorded
fallback.**
- R2 dominates R1, 1/1b, 3 and 4. R1 is refuted, 1/1b is undone by the land, and 3 and 4
  remove nothing.
- Against 2, R2 is smaller: a form for six removal commands, and no new state across
  iterations. 2 would still need R2's form for GT and HC.
- What remains between them is a fact, not a preference: whether the lag is ever longer than one
  command. The next iterations' transcripts settle that at no cost (the observable below).
  If they show R2 failing, option 2 replaces it. So no owner call is needed. Routing this as
  `you: judgment` would spend the owner's attention (S10) on a question the records will
  answer.

Other choices, one line each:
- A live Agent-tool probe from this loop: not run. It is not hermetic, and a subagent cannot set
  up a main-session cwd. The transcripts answered more than a single probe would.
- Decision log row 72 and plan D13's wording: left as they are. They are records on the
  self-merge floor, and the brief below changes only the live sentences.

## For the dev cycle

Suggested brief: **Remove the cycle's worktrees from a shell parked
in its own call (herald F-008).**
- Goal: before each worktree removal (WT, HC, GT, the stop paths' `--force` removals and the
  leftover HC), the orchestrator sends a bare `cd WTB` call, then the removal in a later call
  (`git -C MAIN_WT worktree remove X`, nothing after it in that command). Step 0.3 (line 338)
  states the form and why: subagents run in the main shell's cwd, which can lag by a command,
  and a `cd` holds only when the whole command succeeds. The others point to it. The D13
  bullet and the build-loop prompt line are corrected as above.
- Paths: `skills/dev-cycle/SKILL.md`, `scripts/build-loop.sh` (the prompt line only), `test/`
  (pins).
- Policy: review (gate code).
- Tests: bats pins on the removal form, the D13 wording and the prompt line, and the existing
  `--prompt` tests updated.
- Observable (S6): pair each WT removal in the next sessions' orchestrator transcripts with the
  loops' refusals, as this doc did. Count "no longer exists, so this command was not run"
  within minutes of a removal made from WTB. It is negative if any appears, and then option 2
  replaces R2.
