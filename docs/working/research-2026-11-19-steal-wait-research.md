# Research: re-dispatching an unfinished loop sooner than two hours

- **Goal**: decide what lets `build-loop.sh --prompt --steal` take a dead loop's locked worktree sooner than `STEAL_AGE` (7200 s) without taking a live one, and draft that change as a brief.
- **Task status**: complete (research only; no code, test, skill or workflow changed).

Brief: `docs/working/briefs/2026-11-19-steal-wait-research.md` at 18a43829. Branch: `docs/steal-wait-research`. Policy: self-merge, `Paths: none` (this doc is the whole output).

Inputs read: `steal()`, `ended()`, `lock_behind()` and `dispatch()` in `scripts/build-loop.sh` (1781-1868) and its `--prompt` header (550-571); decision D1 in `docs/working/plan-build-loop-handoff.md` (39-42) and its F44 row (173); `skills/dev-cycle/SKILL.md` step 7's "working" rule (707-711) and step 10 (977-1009); `docs/working/research-2026-11-19-loop-wait-rule.md`; `docs/constraints.md`; the roadmap's Next item; the cycle records under `docs/working/cycles/`, including the full 2026-11-19 record as it stood at c9945512 (iteration 0121 rewrote that file to hold only its own block); the steal tests in `test/scripts/build-loop-dispatch.bats` (134-170) and the pin in `test/scripts/build-loop-orchestrator.bats` (700-703).

Commands run: `git` and `rg` only, with `sed`, `cut`, `awk` and `sort` to slice their output (the brief's criterion 5).

Failure-pattern grep: FP-148

(`rg -n -i 'steal|stale lock|worktree lock|two agents|no marker|hand.?back|STEAL_AGE|lock reason' docs/failure-patterns.md`: no matches; widened to `lock|re-dispatch|worktree`: FP-148, "a timed-out lock waiter forces a drop over the holder's boundary", is the prior art for any rule that takes a held lock on a timer alone. FP-011, FP-013, FP-014, FP-062 and FP-068 are worktree add, prune and path bugs, unrelated to the lock's age.)

## How the rule works today

- `dispatch()` refuses a locked worktree unless `ended()` (the tip is a `ready`, `blocked` or `stopped` marker and the lock names an older tip that is its ancestor) or `steal()` (`--steal` given, the lock reason ends " UTC TIME", and both that time and the tip's committer time are over `STEAL_AGE` ago).
- So a loop that ends **with** a marker is re-dispatched at once; one that ends **without** a marker waits until both its lock and its last commit are two hours old, whoever knows it ended.
- D1's reason: git state alone cannot tell a dead loop from a live one that is not committing, perhaps another session's (F44: two agents in one worktree). D1 also sets the stall rule (a live loop with no new commit in about two hours is stopped), so the two-hour number is shared by the stall rule and the steal age.
- Step 10 runs `--prompt BRIEF --steal` for every sent-back brief and retries "under 2 hours old" each iteration.

## Motive, with numbers (acceptance criterion 2, S5)

`--prompt --steal` re-dispatches the cycle records name with that flag, 2026-10-29 to 2026-11-19: **10** (a lower bound: some records, such as 2026-11-06's "dispatched 2", omit the flag). Seven took the lock at once (the loop under it had left a marker, or no record names a wait). **Three waited on the steal age**, each for a loop this session knew had ended:

| Case | Why no marker | Known dead at | Re-dispatched at | Wait |
|---|---|---|---|---|
| 2026-11-12-sandbox-return-research | the orchestrator never started a subagent (the brief named the wrong doc) | 01:54 UTC (its corrected brief landed) | iteration 0354, land 03:59 UTC | about 2 h 5 min, refused twice |
| F-019 (2026-11-19-worktrees-outside-dot-claude) | handed back before its round-2 review reported | iteration 2008 (tip 20:01 UTC) | 22:03 UTC | about 1 h 55 min, refused once |
| lever #3 correction (2026-11-19-code-review-lever3-correction) | handed back before its round-2 review reported | iteration 2155 (tip 21:47 UTC) | iteration 2351 | about 1 h 56 min, refused twice |

About six hours of latency in three weeks, all on loops whose own dispatching session had the evidence that they were dead (a task notification, or its own choice not to start one). The F-019 wait sat on the release path: the owner said in session that the release waited on F-019's merge (record, iteration 2028). (The brief counts "three loops, the lever #3 correction twice"; the records show two hand-backs on 2026-11-19 and the lever #3 one refused twice; the third wait is the 2026-11-12 case.)

What the merged wait rule (acbff6c6, approved as Q-314: loops wait inside their turn for their reviewers) changes: it targets the hand-back cause, two of the three. It does nothing for the orchestrator's own "dispatched but no subagent started" case, nor for a loop that dies some other way (memory pressure, a crash, the session ending). Its own S6 count (zero or one hand-back in the next 20 dispatches supports it) is still running.

What a live loop's silence looks like, for a shorter age: across the 84 loop merges since 2026-10-15, the longest gap between two commits on a merged loop branch was 41 minutes or less for all but nine branches, and each of those nine was dispatched more than once (gaps of 70 to 4676 min, F-019's 123 and lever #3's 137 among them), so their longest gap may be dead time between dispatches; git alone cannot split it into live and dead. The gap from a dispatch's lock to its first commit, a research phase that commits nothing, is not in git at all and is not measured. So a live loop's longest silent stretch is unknown: the other 75 branches show up to 41 minutes between commits (not checked for a second dispatch), and nothing here bounds it above.

## Divergent design (acceptance criterion 3)

Constraints that bind: S1 (honest slips by a same-uid loop or session, not hostility; proportionate), H2 (fail closed and name the gap), H3 (hermetic bats), S3 (reuse `steal()`, one rule), S4, S5, S6, S8, S10, and D1's case (a live loop in another session must not be taken). Gate code: `scripts/build-loop.sh` and `skills/dev-cycle/` match GATE_CODE in `scripts/lib/dev-cycle-read.sh`, so every option that changes either lands by a review merge (a merge entry the owner answers).

| Option | What it reads | Another session's live loop taken? | Paths | Verdict |
|---|---|---|---|---|
| **A. Shorter `STEAL_AGE`** (say 30-60 min) | lock time, tip commit time (as now) | yes: any loop silent longer than the new age, in any session; gaps of up to 41 min are seen, with no upper bound known | `scripts/build-loop.sh` (one constant), the `--prompt` header, SKILL step 10 and the orchestrator pin, D1's text | out: it trades the D1 case away on a timer alone, the FP-148 shape, and still waits the new age for a loop known dead |
| **B. The dispatching session says its own loop ended** (`--prompt BRIEF --steal --ended TIME`) | the orchestrator's claim plus the lock time and tip commit time, both of which must be before TIME | no, unless that session misattributes a notification; a lock or commit newer than TIME (another dispatch, or a live loop that committed) refuses | `scripts/build-loop.sh` (`steal()`, option parsing, header), `test/scripts/build-loop-dispatch.bats`, SKILL step 7 and step 10 | **pick** |
| **C. Heartbeat the loop refreshes** | a file's mtime (in the worktree or its git dir) or a refreshed lock | yes, when a live loop misses a beat: an LLM loop inside one long tool call or reviewer wait cannot refresh, so the beat needs a background job (the loop prompt forbids them) or a hook | loop prompt, a hook (an enforcement file, Live-verified), `scripts/build-loop.sh`, tests | out: the one option that also covers a dead session, but fails open on a missed beat, needs a Claude-Code-only hook (S11) or prompt compliance, and touches the most paths (S8) |
| **D. No change** (the wait rule merged) | nothing new | no | none | runner-up: valid (S5), but it leaves the orchestrator's own known-dead case (2026-11-12) and other deaths at two hours, and the owner asked for less |

Also weighed and dropped: **B with the claim in the cycle record** (a line on main that `--steal` parses) couples the gate to the record's grammar (S3), and **B as an orchestrator-written `handoff: stopped` marker**, which `ended()` would already accept, needs new ref-writing gate code and a step 7 route that keeps that stop out of the owner's questions (S10). The flag dominates both: one code path inside `steal()`, and the record's existing step 10 line is the audit trail.

**Path A: B.** It is the only option that shortens the known cases to the next iteration while leaving D1's case where it is: a session with no notification (after a restart, or another session's loop) still gets two hours. Against D, it costs one flag of about a dozen lines in `scripts/build-loop.sh` (already 2619 lines; not one of the two files S8 forbids growing), and it lands by review, so the owner sees it before it runs.

### What B checks, and what it cannot

- `--ended TIME` only with `--prompt` and `--steal`, given once, TIME an exact `YYYY-MM-DDTHH:MM:SSZ` UTC time that is not in the future; else a usage error.
- Taken when the lock reason ends " UTC TIME" (the existing parse) and both the lock time and the tip's committer time are earlier than `--ended`'s TIME, at any age. Otherwise the existing two-hour rule decides, and its refusal names both rules ("... under 2 hours old, and its lock or tip is not before --ended's TIME").
- TIME is the time the orchestrator read its subagent's task notification (`date -u` at the start of the iteration it woke), or, for a dispatch it chose not to start, the time it chose; never a time read from git.
- What this protects: a lock taken after the claimed end (another session's re-dispatch) and a loop that committed after it (alive after all) both refuse.
- **Residual, named:** the claim is the orchestrator's. An orchestrator that misattributes a notification to the wrong brief, or passes the current time for a loop still running, takes a live loop of its own (F44's two agents in one worktree). S1 accepts this: the honest form of the slip is rare (task IDs map one to one to briefs), it is recoverable from git history, and today's `--steal` already takes any session's loop on a timer. A process the dead subagent left behind (a `run_in_background` Bash job) can still write in the worktree after the notification; the loop prompt forbids background agents, not jobs, so this stays a residual too.
- Does not cover: a loop whose session ended (no notification reaches anyone): two hours, as now, which is D1's case.

### Other choices (fewer than three viable options each)

- **The name**: `--ended TIME` over `--own`: the flag states the fact it rests on (the end), not an ownership the code cannot check.
- **Strictly before**: a lock or commit at the same second as TIME refuses (fail closed, H2).
- **The stall rule** (D1's two hours without a commit for a live loop) is untouched: it is a different question, a live loop, and shares only the number.

## Review

Round 1: one fresh read-only reviewer, its report returned as text (below).

## For the dev cycle

Suggested brief (review policy: gate code):

- **Goal**: `build-loop.sh --prompt BRIEF --steal --ended TIME` takes a locked worktree at any age when both the lock reason's UTC time and the tip's committer time are before TIME; without `--ended`, or when either is not before it, the two-hour rule decides as now. Step 7's "its subagent ended with no marker" and step 10's re-dispatch pass `--ended` with the time of the task notification (or of the orchestrator's own choice not to start one); a loop with no such notification is re-dispatched as now.
- **Motive**: three re-dispatches waited about two hours each for loops this session knew were dead (2026-11-12, F-019, lever #3; this doc's Motive table), one on the release path; the owner's 2026-11-19 request.
- **Paths**: `scripts/build-loop.sh`, `test/scripts/build-loop-dispatch.bats`, `test/scripts/build-loop-orchestrator.bats` (only if the pinned step 10 wording moves), `skills/dev-cycle/SKILL.md`.
- **Policy**: review (`scripts/build-loop.sh` and `skills/dev-cycle/` are GATE_CODE).
- **Tests** (bats, hermetic): taken under `--ended` with a fresh lock and tip both before TIME; refused when the lock is at or after TIME, when the tip's commit is at or after TIME, and when TIME is in the future or malformed (usage error naming the gap, H2); `--ended` without `--steal` or with `--start` is a usage error; without `--ended` the existing two-hour cases are unchanged; scripts/hermeticity-lint passes.
- **S6 observable**: the cycle records' step 10 lines over the next 20 re-dispatches: a re-dispatch under `--ended` whose loop then turns out to be live (two agents on one branch, interleaved commits from two dispatches) means revert; the waits on own known-dead loops drop from about two hours to one iteration.
- **Out of scope**: `STEAL_AGE`, the stall rule, the dispatch cap, the lock reason's format, heartbeats.
