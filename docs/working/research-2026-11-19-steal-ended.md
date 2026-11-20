# Research: build `--prompt --steal --ended` (the dispatching session takes back its own dead loop's worktree)

- **Goal**: build the pick of `docs/working/research-2026-11-19-steal-wait-research.md` (merged 012b20f9), its `## For the dev cycle` section being the specification.
- **Task status**: built; review-fix loop below.

Brief: `docs/working/briefs/2026-11-19-steal-ended.md` at 04bf7b11. Branch: `fix/steal-ended`. Policy: review (`scripts/build-loop.sh`, `scripts/lib/` and `skills/dev-cycle/` are GATE_CODE in `scripts/lib/dev-cycle-read.sh`).

Failure-pattern grep: FP-148

(`rg -n -i 'steal|stale lock|lock time|re-dispatch|notification|task id' docs/failure-patterns.md`: no matches; `lock` alone: FP-148, "a timed-out lock waiter forces a drop over the holder's boundary", the prior art for taking a held lock on a timer alone. This change adds no timer: `--ended` keys on the exact lock time the caller's own dispatch printed and on the tip's commit time, so FP-148's shape is not repeated. The branch has no `fix(...)` commits, so no skip line is needed.)

## Inputs read

The research doc whole (its pick B, the accepted residual, the weak-spot note on pairing a lock time with a task ID); `docs/constraints.md` at 04bf7b11; in `scripts/build-loop.sh` at 04bf7b11 the synopsis (:17), the `--start`/`--prompt` header (:525-575), `usage()` and the `--start|--prompt` parse (:723-775), `steal()`, `ended()`, `lock_behind()` and `dispatch()` (:1781-1862), `LOCK_RE` and `LOCK_TIME` (:1759-1760); `skills/dev-cycle/SKILL.md` step 7's working bullet (:707-711), the record template (:890-910) and step 10 (:977-1015); `test/scripts/build-loop-dispatch.bats` whole; the pin in `test/scripts/build-loop-orchestrator.bats` (:700-703); `guides/convention-changes.md` and the registry in `scripts/lib/migrations.sh`.

## What was built

- `dispatch()` keeps the lock reason's time in `now` and prints `lock UTC TIME` between `ok BRIEF BRANCH DIR` and `dispatched N`. The loop prompt (every line after `dispatched N`) is unchanged.
- `--ended LOCKTIME ENDTIME`, parsed with `--start|--prompt`'s flags. Usage errors, each naming its gap (H2): with `--start` or given twice ("--ended goes with --prompt, given once"), fewer than two values, a LOCKTIME or ENDTIME not exactly `YYYY-MM-DDTHH:MM:SSZ` or not a real time (`utc_epoch` round-trips through `date`, so 02-30 refuses), ENDTIME in the future, ENDTIME before LOCKTIME, and no `--steal`.
- `steal STEM`: with `--ended`, takes the lock at any age when it matches `LOCK_RE$LOCK_TIME` for this brief's STEM, its time equals LOCKTIME, and the tip's committer time is before ENDTIME. Otherwise it falls through to the two-hour rule unchanged; a refusal keeps "under 2 hours old" (step 10's retry and the orchestrator pin read it) and adds "; --ended did not take it: WHY" (not this brief's dispatch lock, a lock from another time, an unreadable tip time, or a tip committed at or after ENDTIME).
- Header, synopsis and usage text updated; `dispatch()`'s comment names the new line.
- SKILL step 7 (working bullet): on this session's own task notification with no marker, the `7.` line records the task ID and the notification time, and step 10 passes `--ended` with the LOCKTIME from that task ID's `10.` line; it names the slip (a lock time from another task ID's line, such as the latest `10.` line for the brief, perhaps another session's) and gives an ended or other session's loop no `--ended`. Step 10: the `--ended` form, the new printed line, and "STEM dispatched N, task ID, lock UTC LOCKTIME" on the `10.` line. Record template `7.` and `10.` lines carry the fields.
- The record template is a fingerprinted convention (`test/scripts/convention-migrations.bats`), so `scripts/lib/migrations.sh` gains `mig record-7-10-ended record b6f99c918b38b686 - - 'none: ...'` (older records stay valid; no script parses these lines). The research doc's path list did not foresee this; it is the convention's own mechanism (S3).

## Choices (fewer than three viable options each)

- **The printed line's shape**: `lock UTC TIME`, so the `10.` line's "lock UTC LOCKTIME" is a copy of it. Placed as line 2, as the research specified ("before `dispatched N`").
- **Two checks beyond the spec, both narrowing**: the lock must be a dispatch lock of this brief (a hand lock or another brief's lock ending with the same time is not taken), and ENDTIME before LOCKTIME is a usage error (a loop cannot end before its dispatch; it would otherwise make the tip check trivially true for a `--prompt` re-dispatch whose tip predates the lock).
- **Strict "before"**: a tip committed in the same second as ENDTIME refuses (an at-ENDTIME commit is a live one by the research's reading); the cost is a fall-through to two hours in a same-second edge.
- **`--ended` with a failed check still lets the two-hour rule take the lock**: the brief's "otherwise the two-hour rule decides as now".

## Pre-mortem (gate code): how `--ended` could take a live loop, and what bounds each

1. **Wrong lock time, another session's** (the honest slip: the orchestrator copies the latest `10.` line for the brief, written by another session's re-dispatch). Bound: none in code beyond the exact match; the SKILL step 7 text pairs LOCKTIME with the notification's own task ID and names this slip. If the other session's re-dispatch relocked after ours, its time differs and the code refuses; the slip only bites if the orchestrator copies the *current* lock's time, which it reads only from another task's line.
2. **Misattributed notification** (task ID mixed up between two of this session's briefs). Bound: the lock must be a dispatch lock of this brief's STEM, and the time must equal the one that brief's dispatch printed; task IDs map one to one to briefs. Residual (accepted in the research, S1): a notification attributed to the wrong task of the same brief takes a live loop of this session if it has not committed since.
3. **Loop alive after the notification** (a leftover `run_in_background` job, or a mistaken notification). Bound: a commit at or after ENDTIME refuses. Residual: an uncommitting writer; same as today's `--steal`.
4. **Clock or ENDTIME manipulation by slip** (ENDTIME set later than the real notification, so a commit made after it slips through). Bound: ENDTIME may not be in the future; it is the caller's claim, so a late ENDTIME widens the window only back to the notification. Residual: honest-slip only (S1, hostile author out of scope).
5. **Same-second relock** (two locks of one brief in one second share a time). Bound: dispatches run one at a time under the dispatch flock; the research accepts it as not a credible slip.
6. **A lock written by hand to match** (`git worktree lock --reason` with the copied format). Out of scope: deliberate, not an honest slip (S1; the research's last note).

## Verification

- `bats test/scripts/build-loop-dispatch.bats`: 12/12, including the new case (the printed lock time matches the porcelain lock reason; a fresh own lock taken with an ENDTIME after the tip; refusals naming the gap for another lock time, a non-dispatch or other-brief lock, a tip committed at and after ENDTIME; every usage error; a failed `--ended` still lets an old lock go by the two-hour rule) and the updated `${lines[...]}` readers.
- The orchestrator pin (`test/scripts/build-loop-orchestrator.bats` :700-703) passes: its "under 2 hours old" wording did not move, so that file is unchanged.
- `bats test/scripts/convention-migrations.bats` passes with the registry line; `scripts/hermeticity-lint --root .` passes; the full suite result is in the review section.

## S6 observable (from the research doc)

Over the next 20 re-dispatches under `--ended`, the cycle records' step 7 lines: a second task notification from the old dispatch's task after the re-dispatch, or the new loop's research doc or marker naming a commit on its branch after its own lock that it did not make, means the old loop was live; **one such case means revert**. The waits on own known-dead loops should drop from about two hours to one iteration (the `10.` lines' times).

## Review

Rubric: `docs/reviews/steal-ended-code-review-rubric-2026-11-19.md`.

- Round 1 (fresh read-only reviewer, f0df51ba): 0 red, 3 amber (the not-started dispatch had no `10.` line form or step 10 route; the `lock UTC TIME` header said "end unseen"; the take test's commit predated the lock), greens on `steal()`'s correctness, every other reader of line 2, coverage and security. All three fixed in e2d917cc; the record template's registry line took the new fingerprint (the line is not on main yet, so append-only holds).
- Round 2 (same reviewer, e2d917cc): all three closed, nothing new. The loop ends clean.
