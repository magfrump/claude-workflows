Commit: d4d178d9

# Security Review — feat/build-loop-u3d (U3d dispatch), confirming pass over the C1-C7 fix batch

**Scope:** `git diff 4b863735..d4d178d9 -- scripts test` (scripts/build-loop.sh, test/scripts/build-loop-dispatch.bats) and commit d4d178d9's message, with the whole of `steal`, `ended`, `dispatch`, `wt_of`, `marker_kind`, `status_fields` and the start|prompt case read as context
**Date:** 2026-10-10
**Based on:** my final-pass report docs/reviews/security-review-2026-10-10-u3d-final.md (Findings 1-4 at 4b863735); shared brief u3d-conf/shared.md
**Suite:** `bats test/scripts/build-loop-dispatch.bats` 4/4 ok at d4d178d9 (once, serially, private TMPDIR). Probes q1-q4 are in the session scratchpad (`u3d-conf/secrev/`). Each ran in its own `/tmp/claude-1000/u3d-rev-secrevconf-*` repo under git 2.39.5, under `timeout`.

## Trust Boundary Map

```
B1: [caller argv: BRIEF, --dir, --steal]                     → [arg parser, readerform, check_brief]          → [dispatch]
B3: [worktree registry: paths, lock reasons, branch lines]  → [wt_of; readerform on WT, now first (C5)]      → [worktree lock/unlock, printed lines, prompt]
B4: [branch tip: marker subject, committer time]            → [marker_kind; ended() vs the reason's TIP (C1); steal] → [lock-replacement decision]
B6: [git common dir: build-loop-dispatch.lock]              → [file-type test, exec 9>>, flock -n (C3); 9>&- (C4)] → [one dispatch at a time]
B7 (new): [lock reason "... at TIP, UTC TIME" written by the previous dispatch] → [ended() regex, steal() regex] → [whether --steal is needed]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | BRIEF argument | request-time (orchestrator) | Caller's own value. Echoed raw in the two lock refusals before check_brief, back to the caller who supplied it. Trusted after pathform for ref/arg/prompt sinks. |
| S5 | `git worktree list --porcelain -z`: WT path, WT_LOCK | runtime-mutable by any same-uid git user | UNTRUSTED for printed-line sinks. WT passes readerform before any arm prints it (C5). WT_LOCK is flattened in STEAL_WHY. |
| S6 | Branch tip: marker kind, sha, committer time | loop-authored | Trusted as "a loop wrote a marker". Since C1 it is trusted as "the loop under this lock has ended" only when the tip differs from S10's TIP. Finding 1 disputes that test. |
| S8 | `build-loop-dispatch.lock` in the common dir | runtime-mutable (any .git writer) | Untrusted for the file-type semantics of open() |
| S10 (new) | TIP inside the lock reason | written by the dispatching run; editable by any same-uid user | Trusted for the "ended" decision only when it parses as full lowercase hex. A hand reason or old-format reason falls back to steal (fail closed). |
| S9 | Clock | environment | trusted |

The batch narrows B4: a marker exempts the lock only when the lock was taken at a different tip. It also adds B7, the recorded tip, as the input to that test. The test is "differs from", not "is an ancestor of". That lets an honest loop that rewinds its branch below its dispatch tip, onto an earlier marker, reopen Finding 1's window (Finding 1 below). B6 now fails closed for every planted file type I tried.

## Final-pass findings: do the fixes hold?

| Final finding | Fix | Probe (at d4d178d9) | Result |
|---|---|---|---|
| 1 (Medium): a second `--prompt` replaces a live re-dispatched loop's lock | C1: reason records `at TIP`; `ended()` (`:1299-1306`) exempts only a marker tip that differs from TIP | q1, the p5 sequence: `--start`, `work`, `handoff: blocked`, `--prompt` (ok, lock `at f60fe152…`), then a second `--prompt` | **Holds** for the p5 sequence: `refuse …: its worktree … is locked (locked build-loop dispatch of 2026-10-01-x at f60fe1525efbfe0fc61c46958480c3fdadeb51fc, UTC 2026-10-11T02:59:31Z): a live loop may hold it; --steal takes it once the lock and the tip are over 2 hours old`, exit 2, lock unchanged. With `--steal`: `… its lock or tip is under 2 hours old`, exit 2. An old-format reason, a hand lock (`by hand`) and an uppercase-hex TIP over a marker tip all refuse without `--steal`. A rewind variant is still open: Finding 1. |
| 2 (Low): `--start` relocks an unborn checkout | C2: `[[ "$MODE" == start && "$WT_N" -gt 0 ]]` refuses (`:1323`) | q1: `--start`, `git update-ref -d refs/heads/feat/x`, `--start` | **Holds**: `refuse …: its branch feat/x does not exist, but a worktree has it checked out (unborn)`, exit 2, lock still the original (`at c8b12083…, UTC …02:59:32Z`), no ref created. Suite test 3 covers it. |
| 3 (Info): FIFO hang, dangling symlink write-through | C3: `[[ -L "$lk" \|\| ( -e "$lk" && ! -f "$lk" ) ]]` before `exec 9>>` (`:1415-1418`) | q2: FIFO, dangling symlink, directory, symlink to a regular file, symlink to a directory, mode-000 plain file; controls: plain file, absent | **Holds**: all six print `refuse …: the dispatch lock file (build-loop-dispatch.lock in the git directory) is not a plain file or cannot be opened`, exit 2, no worktree added. The FIFO returns at once (no timeout). The dangling link's target is not created (`target created: no`). Both controls print `ok`, and the absent case leaves a `regular empty file`. A same-uid swap between the test and `exec` is still possible (Q-103 residual, as before). |
| 4 (Info): WT printed raw before readerform | C5: readerform first in the WT_N=1 arm (`:1327`) | read-static: every later arm that prints `$WT` (`:1328`, `:1330`, STEAL_WHY, `:1332`, the `ok` line) now follows `:1327` | **Holds** (read). Not re-probed with a newline path. The i2/final p2 probe exercised the same readerform on this arm. |

## Requested probes

**Honest crash after an answered re-dispatch (q1).** Loop 1 ends `handoff: blocked`. `--prompt` re-dispatches (lock `at MARKER`), and the orchestrator or loop 2 dies before loop 2 commits.
- A plain `--prompt` refuses with the steal hint (above).
- `--prompt --steal` within 2 hours refuses `… under 2 hours old`.
- I aged the lock reason's time by 3 hours and kept the marker's recent commit time. `--steal` still refused, because steal takes the later of the two times.
- With both the lock time and the marker's commit time 3 hours old, a plain `--prompt` still refused. `--prompt --steal` printed `ok … dispatched 1` and relocked with a new reason at the same tip.

So `--steal`'s 2-hour path is still the way out. The clock starts at the re-dispatch, because the lock time is later than the marker's. The cost is the same 2 hours the `--start`-then-crash path already pays (tip at main, `working`, steal). The header names "… under 2 hours old" as one of the two retryable refusals. This is by design, not a finding. A human can still `git worktree unlock` by hand. The refusal does not say so, which is fine.

**Can the recorded tip be wrong on an honest path?** I read the three arms that write a reason:
- `--start` writes `MAIN_SHA` (`:1313`), and the branch is created at `MAIN_SHA` by the create-only `update-ref` just before `worktree add`.
- `--prompt` with no worktree writes `STATUS[sha]`, read inside `dispatch` under the flock. q2 shows the reason `at b0e0b5ab…` equals `git rev-parse feat/x`.
- `--prompt` on an existing worktree writes `STATUS[sha]` on the ended or steal arm, where the previous holder has ended or is presumed dead.

On these paths the tip can move between `status_fields` and the lock only through another writer: a loop the script treats as ended or dead, or a plumbing write to an unchecked-out branch (the add path). The batch did not change that window, which is a Q-103 residual. The recorded tip is right when written. Finding 1 is about how it is compared later, not about its value.

**Descriptor inheritance (C4) (q3).** A PATH shim around `git worktree add` (`--start`) and `git worktree lock` (`--prompt` on a marker tip) listed its own fds: 0, 1, 2, 3 (a pipe), 10 (the shim's own saved stdout) and 255, and no fd 9. `flock -n` on the lock file from inside the shim failed (`lock HELD during dispatch`). After exit the lock was free. bash keeps its saved copy of fd 9 close-on-exec, so the flock lasts for all of dispatch and no child inherits it.

**New printed values.** See the Primitive sweep. Every value the batch adds to a printed line is a fixed string, `$br` (check_branch), `$WT` after readerform, WT_LOCK flattened, `$(( STEAL_AGE / 3600 ))`, or `${ARGS[0]}`, which is the caller's own argument echoed back to it. The reason's `$stem` and `$tip` go to `git worktree lock --reason` as one argv element. They are printed again only through flattened WT_LOCK. No unvalidated value from B3/B4 reaches a printed line in the new code.

## Findings

#### 1. `ended()` tests "TIP differs", not "TIP is an ancestor": a live loop that rewinds onto an earlier marker loses its lock to a plain `--prompt`

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1299-1306` (ended, read whole), used at `:1331`
**Boundary:** B4, B7
**Move:** #4 (TOCTOU across time), #5 (invert the access model), #11 (bypass enumeration)
**Confidence:** High (executed) on the mechanism. Low-to-medium on honest reach: it needs a loop that moves its branch below its dispatch tip.

Evidence:
```
ended() {
  [[ "${STATUS[loop]}" == ready || "${STATUS[loop]}" == blocked || "${STATUS[loop]}" == stopped ]] || return 1
  [[ "$WT_LOCK" =~ ^locked\ build-loop\ dispatch\ of\ [^\ ]+\ at\ ([0123456789abcdef]{40}|[0123456789abcdef]{64}),\ UTC\  ]] || return 1
  [[ "${BASH_REMATCH[1]}" != "${STATUS[sha]}" ]]
}
```
C1's premise is that a marker other than the recorded tip was written after the dispatch. That holds only while the branch moves forward. Probe q4:
1. Loop 1 ends `M1` (`handoff: blocked`), and `--prompt` re-dispatches at M1.
2. Loop 2 blocks again with no work, writing `M2` on top of M1. `--prompt` re-dispatches loop 3, and the lock reads `at 5d15d014… (M2)`.
3. Loop 3, live, drops its dispatch marker with `git reset --hard HEAD~1`, so the tip is M1 again.
4. A second `--prompt` with no `--steal` then prints:
```
ok docs/working/briefs/2026-10-01-x.md feat/x …/repo/.claude/wt-2026-10-01-x
dispatched 1
locked build-loop dispatch of 2026-10-01-x at 30760080584a0a4b5a0af2cd9962c97c02039778, UTC 2026-10-11T03:00:51Z
```
This is F44 again: a second agent in a live loop's worktree.

The honest path can reach it without two orchestrators. The tip reads `blocked` at M1, whose Asked IDs were already answered (that answer is why loop 2 was dispatched). So the plan's re-dispatch rule (plan line 63) fires on the orchestrator's next iteration. Nothing in the loop prompt forbids rewinding. "End with one marker, an empty commit at your branch tip" invites a loop to drop an earlier empty marker before it continues. A rewind onto an older marker from any earlier dispatch has the same effect. It is one step less likely than the p5 case it replaces, because it needs consecutive markers or a rewind past work. I keep Medium under the floor rule: the mechanism needs no hostile writer, only a loop that rewrites its own branch, which the prompt permits.

**Recommendation:** In `ended()`, also require that the recorded TIP is an ancestor of the current tip: `git merge-base --is-ancestor "${BASH_REMATCH[1]}" "${STATUS[sha]}"` together with the inequality. A missing or unreachable TIP object (gc'd after a rewind) then fails closed into `steal`. Cost: a loop that rebases its branch onto a newer main before writing its marker would need `--steal` and 2 hours. The pr-prep loop merges rather than rebases, so this should be rare; say so in the header. Optionally, also add "never move your branch below the tip you were dispatched at" to the prompt. Add q4's sequence to test 4 as a refusal.

### Untested bypass candidates

- **Upgrade from an old-format lock.** A loop dispatched before d4d178d9 holds `build-loop dispatch of STEM, UTC TIME`. Its marker now needs `--steal` and 2 hours (q1 shows the refusal). This fails closed, not a bypass, and the branch is unmerged, so no such locks are deployed. Listed only for completeness.
- **A same-uid swap of the lock path between the `-L/-e/-f` test and `exec 9>>`.** Not raced. It is a Q-103 residual, as the code comment and the final report's Finding 3 already say.
- **The git 2.39-specific "no submodule recursion on worktree add" result**, carried over from the final pass. This batch did not touch it.

Because of Finding 1, the `ended()`/lock-replacement guard does not appear in the Endorsement Claims.

## Endorsement Claims

- **Claim:** With the dispatch-lock path a FIFO, a dangling symlink, a directory, a symlink to a regular file, a symlink to a directory or a mode-000 file, `--prompt` refuses with the lock-file reason, exit 2, adds no worktree, and does not block.
  **Location:** `scripts/build-loop.sh:1415-1418`
  **Evidence:** executed
  **Verified:** q2, each case under `timeout 10`, plus plain-file and absent controls that print `ok`. The dangling link's target was not created.
  **Not verified:** `--start` with the same plants (same code line, not run), and a concurrent swap of the path between the test and `exec`.
  **route: code-fact-check**
- **Claim:** While `dispatch` runs, the dispatch flock is held, and the git children it starts (`worktree add`, `worktree lock`) have no fd 9.
  **Location:** `scripts/build-loop.sh:1419-1420`
  **Evidence:** executed
  **Verified:** q3: a PATH shim listed `/proc/$$/fd` (no 9) and found `flock -n` failing from inside the child. The lock was free after exit.
  **Not verified:** git's own grandchildren (none were started on these paths; an auto-gc was not triggered).
  **route: code-fact-check**
- **Claim:** `--start` refuses when a worktree holds the absent branch unborn, leaves that worktree's lock as it was, and creates no ref.
  **Location:** `scripts/build-loop.sh:1323`
  **Evidence:** executed
  **Verified:** q1 (the final pass's p4 sequence) and suite test 3.
  **Not verified:** an unborn checkout made by `checkout --orphan` in the main worktree (same wt_of line, not run).
- **Claim:** The tip recorded in a fresh lock reason equals the branch's tip at dispatch on the `--start` path (MAIN_SHA) and on the `--prompt` add path.
  **Location:** `scripts/build-loop.sh:1312-1314`
  **Evidence:** executed
  **Verified:** q1 (`at c8b12083…` = `main`), q2 (`at b0e0b5ab…` = `feat/x`), and suite tests 1 and 4.
  **Not verified:** the steal arm's recorded tip when the branch moves between `status_fields` and the lock (needs a writer the script presumes dead).

## Primitive sweep

Primitive: values reaching printed lines, git arguments built from repo state, and file opens at derived paths (in the batch's changed lines)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:1285` STEAL_WHY `$WT`, `${WT_LOCK//[$'\n\r']/ }`, `$(( STEAL_AGE / 3600 ))` | S5, constant | readerform at `:1327` before `:1331`; newline flattening | cleared |
| `:1294` "under N hours old" | constant | — | cleared |
| `:1299-1306` ended() regex on WT_LOCK and compare with STATUS[sha] | S10, S6 | full-hex regex, start-anchored | Finding 1 (inequality, not ancestry) |
| `:1313-1314` reason `$stem at $tip, UTC $(date)` → `git worktree lock --reason` / `worktree add --reason` | S1 (pathform stem), S6/MAIN_SHA | one argv element | cleared |
| `:1323` unborn refusal `$br` | S3 | check_branch | cleared |
| `:1327-1332` WT_N=1 arm prints `$WT` | S5 | readerform first (C5) | cleared (Final F4 fixed) |
| `:1415` `lk=…--git-common-dir…/build-loop-dispatch.lock` | S8 | `-L`, `-e && ! -f` test | cleared (q2); swap race is Q-103 |
| `:1416-1419` refusals `${ARGS[0]}` | S1 | none: echoed back to its own caller before check_brief | cleared — caller's own value, no crossing |
| `:1420` `dispatch … 9>&-` | — | — | cleared (q3) |
| loop_prompt `$5` (tip) | MAIN_SHA / STATUS[sha] | check_branch full id | cleared (unchanged except its source line moved to `:1313`) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `ended()` exempts any marker tip that differs from the recorded tip, so a live loop that rewinds onto an earlier marker loses its lock to a plain `--prompt` (F44) | Medium | B4, B7 | `scripts/build-loop.sh:1299-1306` | High (executed) / Low-Medium (honest reach) |

## Overall Assessment

The batch closes what it set out to close. The final pass's p5 sequence now refuses, with and without `--steal`. `--start` refuses an unborn checkout and leaves its lock alone. Every planted lock-file type fails closed without blocking. No dispatch child inherits the flock, and the flock is held throughout. readerform now runs before any arm prints the worktree path. The new code prints no unvalidated value. An honest crash after an answered re-dispatch is recoverable by `--steal` 2 hours after the re-dispatch, the same cost as the existing `--start`-crash path. The recorded tip is correct when written on all three arms. One gap remains in C1's design. "The recorded tip differs from the marker tip" stands in for "the marker was written after this dispatch", and that holds only while the branch moves forward. A loop that rewinds onto an earlier marker, which the prompt does not forbid, reopens F44 for the orchestrator's own re-dispatch rule (Finding 1, executed). The fix is one `merge-base --is-ancestor` test in `ended()` plus a test. The suite passes 4/4. Within the code paths read and probed, I found nothing else. The endorsement claims are executed and scoped, and those marked `route: code-fact-check` are pending verification there.

**Goal-Alignment Note:** The goal is to land U3d after a clean review-fix loop. C1-C7 hold against the final pass's findings, the crash-recovery question and the lock-file probes. Finding 1 is a residual of the same F44 property C1 was meant to secure, reachable by an honest-but-history-rewriting loop and a single orchestrator. Either fix it in place (an ancestry test, with q4 as a test) or record an override row that scopes F44's coverage to loops that never move their branch backwards, before merge.
