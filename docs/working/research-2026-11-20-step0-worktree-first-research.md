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
- **Skill, Rules on stops** (`SKILL.md:69-79`). "Each stop ends the iteration there … and
  is filed once: in the `you: judgment` entry the step names, if it names one (step 0's
  `--state` refusals and its lost `Main at:` line), else … one agent work item …; either
  way also in the final message." Both the entry and the agent item are written in WT. So
  for **every** stop before WT exists (0.1, 0.2 and 0.3), the text names a home that cannot
  be written. Only the final message is left. A `--state` refusal also opens that message
  with `⚠ SECURITY` and is sent as a push notification (`SKILL.md:1067`).
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
- **Its cause was removed the same evening, and row 88 keeps it removed.** F-018's branch
  name is 2026-11-13 00:37 UTC. The Q-125 sandbox rollback, 7caea26d ("agents cannot create
  worktrees under it"), was committed at 2026-11-12 17:16 -0800, which is 01:16 UTC, about
  40 minutes later. So F-018 ran under the sandbox that was being withdrawn for exactly
  this reason. (Assumed: philosophy-research launches through cc-isolated, so the rollback
  reaches it at its next release. Not checked from here.)
- **A related near-miss, in this repo: one.** `cycle-2026-11-19.md:1144`, iteration
  2026-11-20-0237. A first try reused the minute just used (0236), and `worktree add`
  refused. "The commands after it ran in the main checkout": the digest and
  `questions.sh archive`, which moved two entries in MAIN_WT's working tree. They were
  restored by hand. That is a failed `worktree add` that the iteration went past instead
  of stopping. Nothing in step 0.3's text says such a failure is a stop.
- **Earlier step-0 stops** (`cycle-2026-10-15.md`, `cycle-2026-10-17.md`: "stopped: step
  0.2") ran under an older step order that made WT first and filed entries from it. They
  do not bear on this question.
- **No `--state` refusal has ever been recorded.** So the gap in the Rules (a judgment
  entry named for a 0.1 stop that has no WT to be written in) has not yet cost anything
  either.

**Reading.** The motive for *detecting* a read-only `.git/worktrees` early is weak. It
happened once, under a sandbox that was rolled back for this very reason, and row 88 rules
out bringing it back without a revisit. The motive for *saying what a pre-WT stop does* is
real but small. The skill names homes that cannot exist before WT, and 0237 shows that a
failed `worktree add` with no stated rule let the iteration run on in the main checkout.
Neither of those needs new code.

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
  at MAIN, so step 1's cleanup deletes it as merged, and the next iteration takes a new
  minute's name anyway. The cost: gate code in a 2661-line script, a new bats case (H2,
  H3), a review merge and an image release, all to guard a cause that row 88 removed. A
  write test is also a guess at git's own failure modes. `git worktree add` is the real
  test, and it already fails loudly. B could still earn its place if the read-only mount
  returns (row 88's revisit trigger).
- **C, state it.** A few lines in `SKILL.md`, step 0.3 and the Rules' stop list:
  1. A failed `worktree add` at 0.3, other than a taken name, is a stop. This covers the
     0237 near-miss.
  2. A stop before WT exists is reported in the final message only. It writes no file and
     makes no worktree to file it. The next iteration meets the same condition again, so
     nothing is lost: the stop rebuilds its own record.
  3. A branch that a failed `worktree add -b` left at MAIN is removed with `git branch -d`
     (it is merged), or left for step 1's cleanup when git refuses.
  4. The `--state`/`Main at:` judgment-entry clause either becomes "once a WT exists" or
     is dropped for stops before 0.3.
  No code, no new owner chore (S10), and no new dispatch (S2).
- **D, no change.** Free. The Rules already put every stop in the final message, so
  F-018's stop did reach the owner. But the text still names homes that cannot be written
  before WT, and it does not call a failed `worktree add` a stop. The 0237 iteration ran
  on past exactly that gap and changed files in the main checkout.

**Pick: C (Path A, one option dominates).** C closes the two gaps that showed up in real
use (0237's run-on, and the unwritable homes) at the cost of a few lines. B's extra gain,
the half-made branch, is already cleaned up by step 1, and its cause is retired by row 88.
A is dominated by B. D leaves a gap that has already let an iteration write in the main
checkout. Runner-up: D. If the follow-up review finds that step 0.3's existing "every
command names its checkout" rule (`cd WT && …`) should already have stopped 0237, so that
the slip was the orchestrator's and not the text's, then D is an equally valid outcome.

One-line notes on the smaller choices (each has fewer than 3 viable options):
- **Where a 0.1 `--state` refusal goes:** final message only (plus its existing
  `⚠ SECURITY` push), not a worktree made in a state `--state` just refused. A judgment
  entry with nowhere to be written is dropped from the pre-WT case.
- **Whether to make `--state` refuse a read-only `.git/worktrees`, as F-018 suggests:**
  no. `--state` writes nothing by design (it is the read-only first call), and B is the
  better place should that test ever be wanted.

## For the dev cycle

Suggested brief (an Agent item could replace the Now item "Step 0 tests worktree creation
first"):

- **Goal:** `skills/dev-cycle/SKILL.md` says that a failed `worktree add` at step 0.3
  (other than a taken name) is a stop, and that any stop before WT exists is reported in
  the final message only, with no file and no worktree made to file it. It says how the
  half-made branch is removed. The Rules' "filed once" sentence no longer names a judgment
  entry for a stop that has no WT. Option C above.
- **Paths:** `skills/dev-cycle/SKILL.md` only.
- **Policy:** review (`skills/dev-cycle/` is GATE_CODE; the change reaches the gate at the
  next image release, through step 0.1's `image-lag` entry).
- **Tests:** none new (prose only, H3 is met by the existing suite). Run the suites that
  read `SKILL.md`: `test/scripts/build-loop-orchestrator.bats`,
  `test/scripts/build-loop-free.bats`, `test/scripts/build-loop-check.bats`,
  `test/scripts/convention-migrations.bats` and `test/questions-doc.bats`. If any of them
  pins the changed lines, update them in the same change.
- **Doc change:** the skill text is the doc. Answer F-018 in
  `docs/working/feedback/philosophy-research.md` through the cycle's usual feedback
  handling.
- **Not in it:** a writability probe or a change to `--worktree-base` (option B). Note B as
  the follow-up only if row 88's revisit trigger fires, that is, if a sandbox that mounts
  `.git/worktrees` read-only comes back.
