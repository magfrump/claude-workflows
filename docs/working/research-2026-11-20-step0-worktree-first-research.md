# Research: step 0 with no worktree (F-018)

Brief: `docs/working/briefs/2026-11-20-step0-worktree-first-research.md` (at 8033fed3).
Branch: docs/step0-worktree-first-research. Dispatch 1. Research only: this doc is the
whole output (brief criterion 4); no code, test, skill or workflow changed, and only
`git`, `rg` and reads were run (criterion 5).

Failure-pattern grep: worktree (FP-011 orphaned-worktree-after-partial-add, fix: reorder; FP-013, FP-014, FP-062, FP-068 are other worktree lifecycle and path bugs, not this one)

FP-011 is the one prior that fits: a partial `worktree add` leaves something behind. F-018
shows the same shape: `git worktree add -b` made the branch, then failed on the
directory.

## What the sources say (criterion 1)

- **F-018** (`docs/working/feedback/philosophy-research.md:145`, verdict "fails",
  2026-11-12). A session whose Bash sandbox mounted `.git/worktrees` and `.git/config`
  read-only ran `/loop /dev-cycle`. `--state` printed `ok`. Then
  `git worktree add -b chore/dev-cycle-2026-11-13-0037 …` made the branch and failed with
  `could not create directory of '/workspace/.git/worktrees/…': Read-only file system`.
  Every write the skill allows goes through WT, so the stop could not be filed. The
  iteration ended with no record, and the half-made branch was deleted by hand. The
  suggestion: step 0 tests worktree creation first (a `--state` refusal naming the
  read-only directory), and the skill says where a stop goes when no WT can exist.
- **Skill, step 0** (`skills/dev-cycle/SKILL.md:229-382`). The order is 0.1 `--state`
  (from MAIN_WT, before any other git command), 0.2 `--main-log`, then 0.3
  `--worktree-base` followed by `git -C MAIN_WT worktree add -b chore/dev-cycle-DATE-HHMM WT MAIN`.
  "A stop below ends the iteration with no record." At 0.3 the text names only two
  outcomes: a name already taken (try the next minute) and a merge conflict (a stop). It
  does not name a failed `worktree add` as a stop.
- **Skill, Rules on stops** (`SKILL.md:70-80`). "Each stop ends the iteration there … and
  is filed once: in the `you: judgment` entry the step names, if it names one (step 0's
  `--state` refusals and its lost `Main at:` line), else … one agent work item …; either
  way also in the final message." Both the entry and the agent item are written in WT. So
  for **every** stop before WT exists (0.1, 0.2 and 0.3), the text names a home that cannot
  be written. Only the final message is left. A `--state` refusal also opens that message
  with `⚠ SECURITY`, sent as a push notification when the session has a tool for one
  (`SKILL.md:1067`).
- **`--worktree-base`** (`scripts/build-loop.sh:626-652` header, `wt_base` at 1905-1940,
  mode at 2655-2659). It runs the state gate's caller and default-branch checks. It then
  makes `MAINWT/.worktrees` and its `.gitignore` of `*`, and checks that git ignores what
  is in it. It never tests the place F-018 failed on, the common git dir's `worktrees/`
  directory. So it would have printed `ok` under F-018's mounts. Its refuse line is
  already a stop (`SKILL.md:38-40`). It landed on 2026-11-19, a week after F-018.
- **`--state`** (`state_gate`, `default_gate`, `caller_gate` at `build-loop.sh:860-935`).
  It reads config, the shallow file and the default-branch refs, and writes nothing. It
  tests no writability.
- **Decision-log row 88** (`docs/decisions/log.md:111`, 2026-11-12). cc-isolated keeps no
  Claude Code Bash sandbox. The sandbox's return is not pursued because "worktree usage is
  too important". The research behind it found Claude Code itself makes `.git/worktrees`
  read-only inside its sandbox. Revisit only if that sandbox lets `git worktree add` work,
  or if worktrees stop being how agents work.
- **Constraints.** H2 (fail closed and loudly: a refusal names what went unenforced), S5
  (motive first; the status quo is a valid outcome), S10 (owner attention last: no new
  recurring chore), S2, S3, S4 and S8 (cost, reuse, scripts over prose, small units).

## Motive (criterion 2, S5)

Sources: all 26 records in `docs/working/cycles/` and both feedback files
(`philosophy-research.md`, `belegarth-herald.md`), searched with `rg` for read-only,
`worktree add`, `could not create directory`, `refuse worktree-base`, `before WT` and
stopped step-0 lines.

- **A stop because no worktree could be made: once, F-018 itself.** No cycle record and no
  other feedback entry reports one. Belegarth-herald F-009 is about the Agent tool's own
  worktree isolation, not the cycle's WT.
- **Its cause was removed the same evening, and row 88 keeps it removed.** The branch
  F-018 names (in philosophy-research, not this repo) reads 2026-11-13 00:37 UTC, since
  step 0.3 names branches in UTC (`SKILL.md:332`). The Q-125 sandbox rollback, 7caea26d ("agents cannot create
  worktrees under it"), was committed at 2026-11-12 17:16 -0800, which is 01:16 UTC, about
  40 minutes later. So F-018 ran under the sandbox that was being withdrawn for exactly
  this reason. (Assumed: philosophy-research launches through cc-isolated, so the rollback
  reaches it at its next release. Not checked from here.)
- **A related slip, in this repo: one, and not a gap in the text.** `cycle-2026-11-19.md:1144`,
  iteration 2026-11-20-0237. A first try reused the minute just used (0236), and
  `worktree add` refused. "The commands after it ran in the main checkout": the digest and
  `questions.sh archive`, which moved two entries in MAIN_WT's working tree. They were
  restored by hand. That was a taken name, which step 0.3 already handles ("a name taken:
  the next minute", `SKILL.md:332`). The commands could only run in MAIN_WT because they
  did not name WT, against D13's "every command names its checkout (`cd WT && …`), so one
  run in the wrong place fails" (`SKILL.md:30-32`) and the d6 rule's `cd WT && bash …d6.sh`
  (`SKILL.md:52-55`). The orchestrator slipped against rules that already exist. (A
  review of this doc's first draft caught this. The draft read it as a text gap.)
- **No rule names a failed `worktree add` as a stop** (beyond the taken-name retry). The
  only instance of any other failure is F-018's read-only directory.
- **Earlier step-0 stops** (`cycle-2026-10-15.md`, `cycle-2026-10-17.md`: "stopped: step
  0.2") ran under an older step order that made WT first and filed entries from it. They
  do not bear on this question.
- **No `--state` refusal has ever been recorded.** So the gap in the Rules (a judgment
  entry named for a 0.1 stop that has no WT to be written in) has not yet cost anything
  either.

**Reading.** The motive for *detecting* a read-only `.git/worktrees` early is weak. It
happened once, under a sandbox that was rolled back for this very reason, and row 88 rules
out bringing it back without a revisit. The motive for *saying what a pre-WT stop does* is
latent, not observed. The skill names homes (a judgment entry, an agent item) that cannot
be written before WT. But the Rules already send every stop to the final message, which
is where F-018's stop went, and that ambiguity has cost nothing on record. The skill
already uses a "once WT exists" pattern for step 0.1's non-stop entries (`SKILL.md:290`;
`:250` similarly reads "WT's questions files"). A stop never gets there, because it ends the iteration (`SKILL.md:231`).

## Divergent design (criterion 3)

Seeded with H1-H4, S1-S11 and the brief's own limits: research only; `scripts/build-loop.sh`
and `skills/dev-cycle/` are both GATE_CODE (`scripts/lib/dev-cycle-read.sh:1037`), so any
change to them is a review merge and reaches the gate only at the next image release.

| Option | What it reads | Where the stop is reported | Paths (all review merges) |
|---|---|---|---|
| **A. Probe at step 0** | makes and removes a throwaway worktree before 0.1 | final message (there is still no WT) | `skills/dev-cycle/SKILL.md` |
| **B. `--worktree-base` tests a worktree can be made** | writes into the common dir's `worktrees/` (or adds a detached worktree and removes it) | `refuse worktree-base:` line, then a stop in the final message | `scripts/build-loop.sh`, a bats case, `SKILL.md` text |
| **C. Final message only, stated** | nothing new | final message; the condition recurs every iteration, so each one says it again | `SKILL.md` (a few lines) |
| **D. No change** | nothing | final message, by the Rules' "either way also in the final message" | none |
| E. File outside WT (session temp dir, or a commit on main by hand as F-018 did) | — | a temp file the owner never reads, or MAIN_WT, which the cycle "reads but never commits in" | rejected: breaks D13 and S10 |

How each one fares:

- **A, the probe.** It catches the F-018 mounts before 0.1 and so avoids the half-made
  branch (FP-011's shape). It still has nowhere to file the stop but the final message.
  It adds a write to MAIN_WT's git dir *before* `--state`, which the skill orders "before
  any other git command" so a planted `GIT_DIR`-style variable is caught first: running a
  worktree command ahead of that check inverts the order on purpose. It is prose doing a
  mechanical step (against S4), and it costs every iteration a worktree add and remove
  (against S2's spirit). B dominates it.
- **B, `--worktree-base` tests it.** This reuses the mechanism that already runs at 0.3
  and whose refuse line is already a stop (S3), and it fails loudly, naming the read-only
  directory (H2). Its only gain over C is avoiding the half-made branch. That branch sits
  at MAIN, so step 1's cleanup deletes it as merged in the first later iteration that has
  a WT (under F-018's mounts, `-d` itself hit the config lock), and the next iteration
  takes a new minute's name anyway. The cost: gate code in a 2661-line script, a new bats case (H2,
  H3), a review merge and an image release, all to guard a cause that row 88 removed. A
  write test is also a guess at git's own failure modes. `git worktree add` is the real
  test, and it already fails loudly. B could still earn its place if the read-only mount
  returns (row 88's revisit trigger).
- **C, state it.** A few lines in `SKILL.md`, step 0.3 and the Rules' stop list:
  1. A failed `worktree add` at 0.3, other than a taken name, is a stop. Today that
     covers only F-018's read-only directory. The 0237 slip was a taken name, which the
     text already handles.
  2. A stop before WT exists is reported in the final message only. It writes no file and
     makes no worktree to file it. The next iteration meets the same condition again, so
     nothing is lost: the stop rebuilds its own record.
  3. A branch that a failed `worktree add -b` left at MAIN is removed with `git branch -d`
     (it is merged), or left for step 1's cleanup when git refuses. Under F-018's mounts,
     `-d` also printed "could not lock config file" (`philosophy-research.md:151`).
  4. The `--state`/`Main at:` judgment-entry clause either becomes "once a WT exists",
     reusing the pattern at `SKILL.md:290`, or is dropped for stops before 0.3.
  No code, no new dispatch (S2). But it is a review merge of gate code, and so a release
  entry for the owner (S10). The text it fixes has never misled a run.
- **D, no change.** Free. The Rules already put every stop in the final message, so
  F-018's stop did reach the owner. The only recorded run-on, 0237, broke rules that
  already exist (the taken-name retry and D13's `cd WT &&`); it was not a gap in the text.
  What D leaves is a latent ambiguity: the skill names a judgment entry or an agent item
  for a pre-WT stop, and neither can be written there. A reader who meets that case falls
  back on "either way also in the final message", which is what C would say.

**Pick: D, no change; the roadmap item closes (Path A: D wins on the S5 and S10 weighting; C keeps a small latent benefit, not strict dominance).** The first
draft picked C on the strength of 0237. Review showed 0237 was an orchestrator slip
against existing rules, so C's observed benefit is gone. Its remaining value is clearing up
a latent ambiguity, at the price of a gate-code review merge and an image-release entry
for the owner. S5 (the status quo is a valid outcome) and S10 (spend the owner's attention
last) both favour D. B's only gain over D, the half-made branch, is already cleaned up by
step 1, and row 88 retired B's cause. A is dominated by B. If a brief touches step 0.3 or
the stop Rules for another reason anyway, C's four lines can ride along at no extra
release cost. That is an option for the cycle, not a reason to dispatch.

One-line notes on the smaller choices (each has fewer than 3 viable options):
- **Where a 0.1 `--state` refusal goes, if C is ever written:** final message only (plus
  its existing `⚠ SECURITY` push), not a worktree made in a state `--state` just refused.
- **Whether to make `--state` refuse a read-only `.git/worktrees`, as F-018 suggests:**
  no. `--state` writes nothing by design (it is the read-only first call), and B is the
  better place should that test ever be wanted.

## For the dev cycle

**Item closed: no brief.** The roadmap Now item "Step 0 tests worktree creation first, and
names where a stop goes with no worktree" closes for these reasons:

- Only one stop for lack of a worktree is on record, F-018. It ran under the Q-125 sandbox,
  which was rolled back about 40 minutes later for this very failure (7caea26d). Decision-log
  row 88 keeps that sandbox out.
- The Rules already send every stop to the final message, which is where F-018's stop went.
- The one run-on in this repo (iteration 0237) broke rules that already exist; the text
  had no gap there.
- A skill change would be a gate-code review merge plus an image-release entry for the
  owner, spent on an ambiguity that has never misled a run (S5, S10).

Reopen it as a brief when either of these happens:

- **Row 88's revisit trigger fires:** a sandbox that mounts `.git/worktrees` read-only
  comes back. Then do option B (`--worktree-base` tests that a worktree can be made, with a
  bats refusal case), plus C's lines.
- **A second stop for lack of a worktree, or any pre-WT stop, is recorded in a cycle
  record or a feedback file.** Then do option C (`skills/dev-cycle/SKILL.md` only, review
  merge, run the full bats suite: several suites read every `skills/*/SKILL.md`, for
  example `test/skills/workflow-routers.bats`).

F-018 in `docs/working/feedback/philosophy-research.md` can be answered with this doc
through the cycle's usual feedback handling. Optional, at the cycle's choice: when another
brief changes step 0.3 or the stop Rules anyway, it may carry C's four lines at no extra
release cost.
