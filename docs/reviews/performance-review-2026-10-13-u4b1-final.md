Commit: ea59b0c3

# Performance Review — feat/build-loop-u4b1, final confirming pass

**Scope:** `git diff main...HEAD` at ea59b0c3 (`skills/dev-cycle/SKILL.md`, `workflows/pr-prep.md`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`, `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`, `docs/`)
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b1-final-r{1,2,3}.md`, `docs/reviews/performance-review-2026-10-13-u4b1-i2.md`

## Data Flow and Hot Paths

The product is skill text an orchestrator runs once per `/loop` iteration, so the hot unit is one iteration. The cost of the frame as written is unchanged since iteration 2 (the measurements there still apply; the script changes since then are one `-c commit.gpgSign=false` pair in HARDEN, G and `hg`, and they cost nothing measurable). Step 0 makes four D6-wrapped calls: `--state` 0.44 s, `--main-log` bootstrap 0.47 s, `worktree add` 0.42 s and 79 MB, and the digest 0.67 s. That is about 2 s and 79 MB per iteration. Steps 2-6 add one `--check-path` (about 0.13 s) per repo-text path and `--check-fix` (5 s, plus 0.13 s per registered worktree) twice per fixed path. There is also a second `--state` before the commits. The health check (over 10 minutes, behind `health-check.lock`) dominates everything else, and the frame now waits for it before steps 2-4b. The per-iteration cost is a few tens of seconds of script time plus the health check. That is proportionate for a loop that runs about every 30 minutes.

Probes for this pass are `scratchpad/u4b1-i3/perff-probe1.sh` and `perff-probe2.sh`, run on this host under the probe-safety rule. Their temp dirs were removed.

## Confirmation of iteration 2's findings

- **i2 F1 (iteration worktree never removed): holds on the land path.** Evidence, `skills/dev-cycle/SKILL.md:239-240`: "WT is removed (`hg -C MAIN_WT worktree remove WT`) once the iteration's land is verified: every registered worktree costs disk and joins the import walks' reader set." Override row 777 carries the step itself to U4b2. The stop paths are not covered; see F1 below.
- **i2 F2 (abandoned health-check waiter runs later): holds when the PID is the group leader.** Evidence, `skills/dev-cycle/SKILL.md:269-275`: "in the background as its own process group (`setsid scripts/health-check.sh > LOG 2>&1`) ... the run's whole process group is stopped (`kill -- -PGID`, PGID from `ps -o pgid= -p PID`: stopping its PID alone leaves the waiting `flock` child...)". `take_lock` (`scripts/health-check.sh:1105-1120`) runs `flock -o "$lk" bash ...` as a child, which inherits the group. In probe 1 case C, a `setsid` flock waiter queued behind a held lock was stopped with `kill -- -PGID`, and once the holder released, nothing ran ("C: no late run"). Case A: in a shell without job control, `$!` of `setsid CMD &` is the PGID, and the group stop worked. So no late run can overlap steps 2-4b, provided the orchestrator holds the right PID. See F2 below.

## Findings

#### F1. A stop after step 0.3 leaves the iteration's worktree behind, and a fault that persists adds one per iteration

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:216-217`, `:237-240`, `:259-261`, `:284-290`
**Move:** Trace the memory lifecycle / what's the size of N
**Classification:** Macro (a registry every import walk reads grows) / Cold (only on stopped iterations)
**Confidence:** Medium
**Legibility-target:** step 0.3's removal sentence, or step 1's `worktree list` bullet
**Baseline:** no baseline available — flagged as speculative (per-worktree costs measured in i2: 79 MB, +0.13 s per `--check-fix`; how often stops happen is not measured)

Evidence: removal is tied to the land only: "WT is removed ... once the iteration's land is verified". A stop ends the iteration with nothing else said: "a stop below ends the iteration with no record, so the next one starts from the same `Main at:`". The digest's failure comes after the worktree exists: "If the digest fails (non-zero exit or a missing section), stop the cycle". Step 1 lists and prunes but never removes: "`hg -C MAIN_WT worktree list` and `hg -C MAIN_WT worktree prune`". Prune drops only entries whose directory is gone. Every stop after 0.3 (a failed digest, a D6 refusal, an exit other than 0 or 2, or a timeout in steps 1-6) leaves a 79 MB worktree and its `chore/dev-cycle-*` branch. The next iteration takes a new minute-stamped name, so a cause that persists, such as a digest that fails every time, adds one per iteration. At a 30-minute interval that is 48 a day, roughly 3.8 GB and about 6 s more on every import walk, the loops' gates included. Its `agent` entry is filed once, so nobody is prompted to clean up. Override row 777 defers only the land path's `worktree remove` to U4b2.

**Recommendation:** Add one clause to the stop rule or to 0.3, "on a stop after this step, WT is removed too (or step 1 lists leftover `wt-dev-cycle-*` worktrees as one entry)", or extend row 777's U4b2 hand-off to name the stop path.

#### F2. The process-group recipe gives no way to capture PID, and the group stop misses when `setsid` itself leads a group

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:268-275`
**Move:** Find the contention point / resource lifecycle
**Classification:** Macro (an orphaned lock holder) / Cold (only when a wait exceeds an hour)
**Confidence:** Medium
**Legibility-target:** step 1, the health-check sentence
**Baseline:** no baseline available — flagged as speculative

Evidence: "`setsid scripts/health-check.sh > LOG 2>&1`), ... (`kill -- -PGID`, PGID from `ps -o pgid= -p PID`". The skill never says where PID comes from. `setsid` forks only when its caller already leads a process group, and then the PID the caller sees exits at once. Probe 1 case B (job control on, `setsid sleep 7 &`): `$!` had already exited, `ps -o pgid= -p $!` printed nothing ("B: PID=1612882 pgid=[]"), and the real group 1612884 kept running. Probe 2 case E: a `zsh -c` that leads its own group and runs `setsid CMD` as its last command execs `setsid`, and the job runs under a different PID (shell 1613223, job 1613224, whose parent is 1). This is the shape of a Bash-tool `run_in_background` call. In either case the stop the skill prescribes does nothing (`kill -- -` with an empty PGID fails), and the late run F2 of iteration 2 described comes back. Case A, the plain `cmd &` in a shell without job control (the Bash tool's default `zsh -c`), works, so this applies only to some invocations.

**Recommendation:** Have the leader record its own PGID: `setsid bash -c 'echo $$ > PGFILE; exec scripts/health-check.sh' > LOG 2>&1 &`. In probe 2 case F the PGID read from the file matched, and the group stopped even with job control on. Or add "an empty PGID is a stop, recorded" so the gap fails loudly.

## Endorsements

- `take_lock`'s waiting `flock` and its child stay in the health check's process group, so `kill -- -PGID` with the right PGID stops the waiter before it takes the lock `[read: scripts/health-check.sh:1105-1120]` (execution in probe 1 case C, a minimal model of the same `flock -o` shape, not the script itself).
- The `commit.gpgSign=false` pair adds one `-c` argument per hardened git call, a negligible constant `[read: skills/dev-cycle/SKILL.md:69]`.
- The orchestrator now waits for the health check before steps 2-4b start their tests and subagents, so the iteration's own suites no longer compete with it for CPU `[unverified — submitted as claim]`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A stopped iteration leaves its worktree; a persistent fault adds one per iteration | Low | `skills/dev-cycle/SKILL.md:237-240` | Medium |
| 2 | The group-stop recipe gives no PID source; when `setsid` leads a group the PID is gone and the stop misses | Low | `skills/dev-cycle/SKILL.md:268-275` | Medium |

## Overall Assessment

Both fixes from iteration 2 hold on their main path. Removal is stated for the land, and the process-group stop works when the orchestrator's PID is the group leader. The per-iteration cost is proportionate: about 2 s and 79 MB for step 0, a few seconds per checked path, and the health check dominating. The two residual findings are each a one-clause tightening: removal on the stop path, and a PGID source that is reliable. Neither needs profiling. Until the D6 block lands (Q-140), the loop does not run unattended, so neither is incurred yet.

## Goal-Alignment Note

The goal is a clean landing of U4b1. Neither finding blocks it. Both are Low and fit under row 777's U4b2 hand-off (F1) or a one-clause edit to step 1 (F2). F2 is the one to fix first if anything is fixed now: it is the same late run that iteration 2's F2 named, and it still happens when the run is launched the way a Bash-tool background call would launch it.
