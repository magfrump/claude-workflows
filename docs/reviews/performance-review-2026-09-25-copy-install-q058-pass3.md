Commit: 516124d

# Performance Review: copy-install Q-058, pass 3 (fix commits f8d3f78..516124d)

**Scope:** the 8 fix commits `99656a2`..`516124d` on skill-fixtures. They answer the pass-2 reviews, including this reviewer's `docs/reviews/performance-review-2026-09-25-copy-install-q058-pass2.md` (P2-C2 `path_without`, P2-C3 sleeps). Code read at 516124d in `/workspace/.claude/wt-q058p2`. The earlier history is context only.
**Date:** 2026-09-25
**Based on:** no code-fact-check report for this pass. This reviewer's timings are in `docs/reviews/execution-logs/q058p3-perf-516124d-suite-timing.log`. They are baseline measurements only, not verdicts on behaviour.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

`install.sh` runs once per install, with a human at a terminal. **Every path in it is cold.** Two stretches are latency-sensitive: the wait before the review appears, and the wait between the `y` and the writes. At 516124d the host stage is 108 files and 2,088,252 bytes.

What the fix commits change at run time, measured on a scratch clone of 516124d (`micro.sh`, 5 runs each, page cache warm):

| Change | Where | Measured cost |
|---|---|---|
| Host stage extracted under `$dest/.cw-stage.*` instead of `$TMPDIR` (P2-R3, P2-A1) | `install.sh:805-813` | `git archive \| tar` 18–20 ms. The location changes, the work does not. |
| Stage copied into `$dest/.cw-new.*` (unchanged work, now within one filesystem) | `:817-825` | `cp -Rp`, 7 names: 17–19 ms |
| The review's view of the current destination, now in `$dest/.cw-stage.*/installed` | `:896-922` | `cp -RH` + `find -delete` + `chmod -R`: 22–27 ms for a destination the size of the payload |
| `links_in` before each hash (P2-R2) | `:650-654`; called at `:494`, `:563`, `:833` | 6–7 ms per call (8 `find`s). 3 calls on a y/y run. |
| `repo_git` on every checkout git call (P2-R1) | `:169-171` | `rev-parse` 1–2 ms, the same as plain `git`. `status` 13–17 ms, against 32–40 ms for plain `git status`. |
| `dc_unwind` (P2-A2) | `:434-445` | failure path only |

Everything the diff adds costs about 40–50 ms per run: three `links_in` calls, and a view build that moved rather than grew. That is under the run-to-run noise of a single `tree_hash` (23–28 ms).

**Tests:** 9 new tests, T75–T83. T72 and `FEED_TAMPER` were rewritten, and `path_without` lost its per-entry loop.

## Findings

#### 1. `script` waits a fixed 2 s whenever install.sh exits with piped answers unread; 10 tests (T77 is new) pay it, about 20 s of the 103 s suite

**Severity:** Low
**Location:** `test/install-host.bats:148-152` (`run_pty`); 10 tests call it with more answers than install.sh reads, among them T12, T16, T21, T22, T39, T46, T50, T61, T74 and T77 (new, `:1385`)
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed per-call wait) / Cold (test suite, but it runs in every slow-suite and `health-check.sh` run)
**Confidence:** High for the 2 s and the list of tests (measured). Medium that unread input is the whole cause: a bare reproduction shows it, but `script`'s internals were not read.
**Baseline:** `printf 'n\ny\n' | script -qec true /dev/null` takes 2,012 / 2,013 / 2,016 ms. With empty input it takes 21 / 24 / 23 ms. In `bats --timing` run fix-1, those 10 tests each took 2,076–2,190 ms. Measured 2026-09-25 in this sandbox (log above).
**Legibility-target:** the author of `install-host.bats`, and whoever owns slow-suite runtime

**Evidence:**
```bash
run_pty() {
  local input="$1"; shift
  run bash -c 'set -o pipefail; printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$input" "$*"
}
```
T77 (`:1385`):
```bash
  run_pty 'n\ny\n' bash "$INSTALL"
```

Pass 2 saw this only on T16 and could not explain its extra 1.5 s. The cause is `script`: when its child exits with input still unread, it waits about 2 s before it exits. Each of these tests is a refusal that exits before it reads the host `y`, so each pays about 2 s of a run that is otherwise around 100 ms. T77 adds one more such test.

This does not affect `install.sh`.

**Recommendation:** In tests that expect a refusal before the host prompt, feed only the answers install.sh reads (`'n\n'`, or `''` when it exits before the devcontainer prompt). Then check T77's timing drops to about 0.1 s. Across the 10 tests that saves about 19 s, roughly 19% of the suite. Not a merge blocker.

#### 2. T72 waits on a signal, but that signal comes before the pgrep stub reads `agent-down`, leaving a narrow window for a flake

**Severity:** Low
**Location:** `test/install-host.bats:1196-1206` (T72), with `stub_pgrep` at `:46-49`
**Move:** Find the contention point (ordering between two processes)
**Classification:** Micro / Cold (test)
**Confidence:** Medium. The ordering is read from the code. How often the window is hit was not measured, and it passed in 2 of 2 runs.
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** the author of `install-host.bats`

**Evidence:**
```bash
  stub_pgrep "[ -e '$S/agent-up' ] && [ ! -e '$S/agent-down' ] || exit 1; echo '779 claude'; exit 0"
```
```bash
stub_pgrep() {
  printf '#!/bin/bash\necho "pgrep $*" >> "%s/probe.log"\n%s\n' "$S" "$1" > "$STUB/pgrep"
```
```bash
    for _i in \$(seq 200); do [ \"\$(grep -c '^pgrep' '$S/probe.log')\" -ge 2 ] && break; sleep 0.05; done
    touch '$S/agent-down'; printf 'y\n'"
```

P2-C3 is answered. T72 went from 6,622 / 4,145 ms at feba07d to 193 / 193 ms: its fixed `sleep 1` and `sleep 3` are gone.

The stub, however, logs its call before it tests `agent-down`. Suppose the feed's `grep` sees the second log line and its `touch` finishes before the stub runs its next line. Then the pre-stage gate sees no agent, the host target stages, and the test fails. Winning that race takes a `grep` fork plus a `touch` fork inside the stub's gap of a few microseconds between two builtins, so the stub would have to be descheduled for more than a millisecond. That is rare, but on a loaded host it is possible. The old `sleep 3` hid this window.

**Recommendation:** Have the stub mark that it has answered, after it tests the files (for example, append `; touch '$S/pgrep-answered'` on the refusal branch, or log a second line after the test), and have the feed wait on that marker. The test stays sleep-free.

#### 3. T67's (and T28's) stage swap no longer reaches anything the review or install reads, so the race these tests order is gone; their fixed waits (3.5 s in T67) now buy nothing

**Severity:** Informational
**Location:** `test/install-host.bats:519-553` (T67), `:507-518` (T28), `FEED_TAMPER` at `:166-168`; `install.sh:817-843`, `:896`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (fixed waits) / Cold (test)
**Confidence:** High that the swap lands after the copies are made and hashed (read). Medium that no later step reads the stage (every `$stage` use at `:812-825` was read).
**Baseline:** T67 took 5,985 / 4,476 ms at 516124d and 6,758 / 4,361 ms at feba07d. T28 took 3,444 / 2,459 ms against 2,329 / 2,327 ms. (log above)
**Legibility-target:** the author of `install-host.bats`; the test-strategy and security reviewers for the coverage question

**Evidence:**
```bash
      d=$(compgen -G "$CLAUDE_HOME_DIR/.cw-stage.*/installed" | head -1) || true; sleep 0.005
    ...
    st="${d%/installed}/payload"
```
```bash
  local view="$HOST_TMP/installed" diffnames=() n lines src
  local ADD_MAX_LINES=200
  mkdir -p "$view"
```

The helper now waits for `installed/`. That directory is created at `:898`, after the stage has been copied into `.cw-new.*` (`:817-825`) and those copies hashed (`:843`). The stage is not read after that. So swapping `payload/hooks/h.sh` and swapping it back changes nothing the review shows or the install writes, whatever the timing. T28's `TAMPER` also edits the stage.

**On timing fragility,** which the brief asked about: T67 is not fragile in the way that would make it fail wrongly. Its one timing dependency is `helper.done`. The helper's restore, 1.5 s after it sees `installed/`, must land before the EXIT trap removes `$HOST_TMP`. The `y` arrives at least 3.5 s after `installed/` appears (`sleep 2` plus `TAMPER="sleep 1.5"`), which leaves about a 2 s margin, plus the post-`y` gate and hash. The fragility is the opposite kind: the test passes without exercising the race it names.

**Recommendation:** For the test author, not a performance change: either point T67 and T28 at a moment the stage is still read (between `git archive` and the copy, the way T81 does with `stub_cp_then`), or restate them as regression tests that the stage is not read after the copy. After either change, T67's 3.5 s of fixed waits can be reassessed.

#### 4. The host stage, the copies and the destination view now all sit under `$dest` during the review: about 6 MB there instead of 2 MB; a stale stage is now cleared, a stale lock still is not

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:793-813` (lock, then stage), `:896-922` (view), `:685-697` (`host_cleanup`)
**Move:** Trace the memory (resource) lifecycle
**Classification:** Micro / Cold
**Confidence:** High for the placement and sizes (read and measured). Size of the view is the size of the current install, assumed to be about the payload's.
**Baseline:** stage 2,088,252 bytes; `cp -a` + `rm -rf` of stage and view 18–20 ms (`micro.sh`, log above)
**Legibility-target:** the maintainer of `install_claude_home`

**Evidence:**
```bash
  rm -rf "$dest"/.cw-stage.*
  if ! HOST_TMP="$(mktemp -d "$dest/.cw-stage.XXXXXX")"; then
```

Pass-2 Finding 4 still applies. While the prompt is open, `~/.claude` now holds the stage (2.1 MB), the copies (2.1 MB) and the view, which is the size of the current install. Before, it held only the copies. On WSL2, `$TMPDIR` and `~/.claude` are normally on the same ext4 disk, so the work moves but does not grow.

After a SIGKILL, the next run clears the stale stage (`:807`, T82): an improvement. However, that run first refuses on the stale lock (`:773-775`) until the user removes it. The lock message already says how.

**Recommendation:** None required. Because the stage and the copies are now on one filesystem under the same protection, the stage-to-`.cw-new.*` `cp -Rp` (17–19 ms, one extra 2 MB write) could become a `mv` of each name. That is a security-reviewer call, not a performance need.

#### 5. `repo_git`, `links_in` and the new copy-failure unwind cost nothing measurable

**Severity:** Informational
**Location:** `install.sh:169-171` (`repo_git`), `:650-654` (`links_in`), `:434-445` (`dc_unwind`)
**Move:** Check the asymptotic behavior
**Classification:** Micro / Cold
**Confidence:** High (measured on the 516124d payload)
**Baseline:**
- `repo_git rev-parse` 1–2 ms (plain `git`: 1 ms).
- `repo_git status` over `CLAUDE_HOME_SRC`: 13–17 ms on a clean index, and 15–16 ms with all 123 payload files stat-dirty and the index never refreshed. Plain `git status`: 32–40 ms.
- `links_in`: 6–7 ms per call.

Measured 2026-09-25 with `micro.sh`; log above.
**Legibility-target:** the maintainer of `install.sh`

**Evidence:**
```bash
repo_git() {
  git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
}
```
```bash
links_in() {
  local dir="$1" pfx="$2" name
  shift 2
  for name in "$@"; do find "$dir/$pfx$name" -type l; done
}
```

**`repo_git`**
- It adds only `-c` flags, no forks.
- `--no-optional-locks` means `status` never writes a refreshed index back. On a stat-dirty checkout, each of the 4 `status` calls in a y/y run re-hashes those files again, but the pathspec bounds that to the 2 MB payload, and it measured 15 ms.

**`links_in`**
- It makes one `find` per name, 8 per call, and 3 calls on a y/y run: about 20 ms.
- It repeats a walk `tree_hash` already makes, since `tree_hash`'s `%y` records the type. Merging the two would save about 6 ms per site, which is not worth the coupling.

**`dc_unwind`**
- It runs only on failure.

**Recommendation:** None.

## Endorsements

- **P2-C2 answered: `path_without` is now one `ln` per PATH directory with no per-entry loop. T53, which is `path_without` plus a refusal, went from 934 / 959 ms to 91 / 82 ms, the same as T51 without `path_without` (77–87 ms in pass 2). T52 + T53 + T57 went from 4,089 ms to 698 ms (mean of 2).** `[unverified — submitted as claim]` (measured by this reviewer, not a fact-check stage)
- **P2-C3 answered for T72: 5,384 ms → 193 ms (mean of 2), with no fixed sleep left in its feed.** `[read: test/install-host.bats:1196-1206]` (see Finding 2 for the ordering caveat)
- **The host target still hashes the copies twice per y run. The view build moved from `$TMPDIR` to `$dest` without extra reads: one `cp -RH` per existing entry, as before.** `[read: devcontainer-config/install.sh:817-843,896-922,955]`
- **`repo_git status` is no slower than plain `git status` (13–17 ms against 32–40 ms), and repeated stat-dirty calls stay at 15 ms.** `[unverified — submitted as claim]` (measured, `micro.sh`)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `script` waits 2 s when answers are left unread: 10 refusal tests (T77 new) pay it, about 20 s of 103 s | Low | `test/install-host.bats:148-152`, `:1385` + 9 others | High (timing) / Medium (mechanism) |
| 2 | T72's signal precedes the stub's `agent-down` test: a narrow flake window | Low | `test/install-host.bats:1196-1206`, `:46-49` | Medium |
| 3 | T67 and T28 swap the stage after it is no longer read: no race left, and T67's 3.5 s of waits buy nothing | Informational | `test/install-host.bats:507-553`, `install.sh:817-843,896` | High / Medium |
| 4 | About 6 MB under `$dest` during the review; stale stage cleared, stale lock not | Informational | `install.sh:793-813,896-922` | High |
| 5 | `repo_git`, `links_in`, `dc_unwind`: each 0–7 ms | Informational | `install.sh:169-171,650-654,434-445` | High |

## Overall Assessment

The fix commits leave `install.sh`'s performance where it was: a once-per-install CLI whose new work (three link scans, a relocated view build, and `-c` flags on git) costs about 40–50 ms a run, all bounded by the 2 MB payload. Moving the host stage under `$dest` changes where the bytes go, not how many are written.

On the suite, two alternated `bats --timing` runs per commit give:
- 516124d: 104.7 / 100.6 s, mean 102.6 s, 83 tests.
- feba07d, re-measured alongside: 108.8 / 95.7 s, mean 102.3 s. Pass 2 measured it at 99.7 s.

The suite is flat (+0.4 s, well inside the ±6.5 s run-to-run noise). The 9 new tests add 11.0 s. The P2-C2 and P2-C3 fixes and noise take 10.7 s off the 74 common tests: T72 −5.2 s, and the three `path_without` tests −3.4 s.

The biggest remaining cost is Finding 1. About a fifth of the suite is `script` waiting on answers nobody reads, and fixing the feeds is cheap.

Nothing here blocks the merge. Findings 2 and 3 concern test ordering and coverage, not cost.

## Goal-Alignment Note
- Success criterion (restated verbatim): "a markdown report saved to /workspace/docs/reviews/performance-review-2026-09-25-copy-install-q058-pass3.md, per the skill."
- Answered:
  - **Host staging under `$dest`.** `git archive | tar` takes 18–20 ms, the copy to `.cw-new.*` 17–19 ms and the view build 22–27 ms. That is the same work as before in a new place, about 6 MB of transient disk in `~/.claude` (Finding 4).
  - **`repo_git` overhead.** None: `rev-parse` 1–2 ms, `status` 13–17 ms (Finding 5).
  - **Link checks.** 6–7 ms per call, 3 per y/y run (Finding 5).
  - **Suite runtime.** 102.6 s at 516124d, against 102.3 s for feba07d re-measured today (pass 2: 99.7 s). T75–T83 add 11.0 s. P2-C2 and P2-C3 recovered about the same.
  - **Timing fragility.** T67 has about a 2 s margin, but it no longer exercises its race (Finding 3). T72 has a narrow ordering window (Finding 2). T80 and T81 are deterministic now, because nothing of the host target is in `$TMPDIR`, and their writer exits on `$S/stop` or after 20 s. T82 was bimodal (2,944 / 592 ms), like T37 in pass 2: noise, not fragility.
- Out of scope:
  - whether P2-R1, P2-R2 and P2-R3 close their security gaps;
  - the correctness of the new tests, beyond Finding 3's coverage note;
  - the docs changes.
- Hermeticity: every measurement ran on a scratch clone, on a `git archive` extract of feba07d, or in the worktree under bats's own `$BATS_TEST_TMPDIR`, with `TMPDIR` pointed at scratch. The worktree was not modified.
- Escalate:
  - **To the fact-check stage:** the two `[unverified — submitted as claim]` endorsements, and Finding 1's mechanism (a `script` drain wait on unread input).
  - **To the test author and the test-strategy reviewer:** Finding 3. T67 and T28 no longer test a reachable race.
  - **To the user (`you: terminal`), still open from pass 1:** the real-host `docker ps --filter label=cc-project` timing, and C6, the `timeout` pipe bound.
