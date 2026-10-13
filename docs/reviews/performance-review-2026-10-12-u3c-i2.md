Commit: 74deb04e

# Performance Review — feat/build-loop-u3c, iteration 2

**Scope:** full branch, `git diff main...HEAD` (main = dafc0e74, HEAD = 74deb04e): `scripts/build-loop.sh` (raw_records, check_line and log_class on raw_records, `--cycle-diff`), `scripts/health-check.sh` (take_lock)
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-i2.md` (33 claims, 0 Incorrect, 4 Mostly accurate)

Measurement provenance. Scratch dir P = `/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/perf-u3c-i2`. Every run used a `--no-hardlinks` clone of the worktree (`P/p-s4J0/repo`, local `main` = dafc0e74), with main's `scripts/` (`P/p-s4J0/old`) and HEAD's (`P/p-s4J0/new`) from `git archive`. Nothing ran in /workspace or the worktree. The machine was loaded during every run (load average 8 to 16 on 16 CPUs), so absolute times are high; the old/new runs were interleaved, so the difference between them is the usable number.

| Run | What | Result |
|---|---|---|
| M1 | `P/mainlog.sh`: `--main-log 183b1a93…` (1,100 first-parent commits: 679 single-parent, 4,219 raw records among them), old and new interleaved, 3 rounds | old 18.0 / 20.3 / 21.1 s; new 22.6 / 24.5 / 25.2 s; outputs byte-identical (1,098 other, 1 answers) |
| M2 | `P/micro.sh`: 679 calls of each reader on a one-record diff file | main's answers loop 0.078 s; raw_records 3.30 s; `tr -cd '\000' \| wc -c` alone 3.39 s |
| M3 | `P/cyc.sh`: HEAD's `--cycle-diff` on the real files (questions.md 32,640 B / 277 lines, questions-archive.md 267,762 B / 2,581 lines, roadmap 6,398 B, idea log 2,742 B), base dafc0e74 | clean index 0.91 / 0.93 s; questions.md changed 0.82 / 0.98 s; both questions files changed 0.88 / 0.98 s; plus roadmap and idea log 0.85 / 0.93 s; all `ok` |
| M4 | `bash -n scripts/health-check.sh` + `git rev-parse --git-common-dir` + a `flock` exec, ×10 | 7.4 ms per round |

## Data Flow and Hot Paths

- **`--cycle-diff`** runs once per dev-cycle iteration, before the chore commit. It is cold. M3 shows it costs the same with a clean index as with all four files changed (about 0.9 s). So the time goes to state_start (`store_check --main` over main's tree), not to the new questions, roadmap or idea-log work. QKEYS_AWK reads at most four blobs of about 300 KB in total. QDIFF_AWK builds one string per entry ID from a few key lines. Both are linear.
- **raw_records** has three callers:
  - check_line: once per brief per `--check`/`--merge`. Cold.
  - cycle_diff: once. Cold.
  - log_class: once per first-parent commit in `--main-log`. This is the only multiplied site. Its N is the commits since SINCE: in U4, roughly the commits since the last cycle, and 1,100 in the full-history measurement.
- **take_lock** runs once per health check. It adds a re-exec of the script (M4: about 7 ms with the rev-parse) to a run of 3 to 9 minutes. The repo's own notes give "health check measured 216s" and "7–9 min each". The lock is held for the whole run by design (D14, F46).

## Findings

#### raw_records forks a `tr | wc` pipeline per commit in --main-log, where the old answers loop returned at the first record

**Severity:** Low
**Location:** `scripts/build-loop.sh:973-980` (raw_records; its final line `:980`), called from `scripts/build-loop.sh:1709` (log_class's single-parent branch)
**Move:** Hidden multiplication / work moved to the wrong place
**Classification:** Micro (a constant per-call fork) / warm path (per-commit loop body of a CLI mode run once per cycle)
**Confidence:** High
**Baseline:** `--main-log` over 1,100 first-parent commits: 18.0–21.1 s before vs 22.6–25.2 s after, about +4.3 s (+21%), measured M1, 2026-10-12, on a loaded host (load average 8–14)
**Legibility-target:** raw_records' last line: `[[ "$(tr -cd '\000' < "$1" | wc -c)" -eq $((2 * ${#RAW_P[@]})) ]]`

Main's answers loop took two cheap exits. It returned at the first record that was not a questions-file M, which is almost every commit. It reached the NUL count only when every record passed. Now each of the 679 single-parent commits:

1. parses every record with the bash regex, and
2. always runs raw_records' NUL count. That is a command substitution plus a two-process pipeline, about 5 ms each under this load (M2: 3.39 s over 679 calls).

That accounts for most of M1's +4.3 s. The rest is the extra records parsed. The chore branch gains the same pipeline, once per chore merge. Output is unchanged (M1 diff), and the cost is linear in commits. In normal use SINCE is the previous cycle's main, so N is tens of commits and the cost is well under a second. This finding matters only for a long --main-log.

**Recommendation:** Make the count fork-free with the same acceptance. Read the second field inside the loop body and return 1 if that read fails: `while IFS= read -r -d '' meta; do IFS= read -r -d '' p || return 1; …; done < "$1"`.
- A loop that ends at the meta read means the NULs are exactly two per record.
- A meta read that fails on trailing bytes still ignores them, as the current comment says.

Then drop the `tr | wc` line. If the change is not worth it here, the cost is acceptable as is; record it as a known constant.

#### health-check.lock waits with no bound and holds the lock across the whole gate

**Severity:** Low
**Location:** `scripts/health-check.sh:1106-1121` (take_lock, whole; the unbounded wait is `:1118`)
**Move:** Contention point
**Classification:** Macro (queueing: wait grows with the number of concurrent gates) / cold path (once per gate), but it blocks the orchestrator's and loops' gates, which are latency-sensitive to the loop
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative (the repo's notes give single-run times of 216 s and 7–9 min, but no measurement of concurrent gates waiting on the lock exists)
**Legibility-target:** `rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?`

Serializing is the point of D14, so the cost is intended. With K build loops and the orchestrator gating at once, the last waits about K × (3–9 min). The second `flock` has no `-w`, so a run that hangs blocks every later gate in the repository indefinitely. The fact-check's mutant m5 showed this script can hang: it ran until `timeout 300` killed it. The waiter prints one "waiting" line and then nothing. That is a liveness and throughput risk in the unattended loop, not a cost per run. M4's re-exec overhead (about 7 ms) is negligible.

**Recommendation:** Consider `flock -w SECONDS` on the waiting call, set well above one run's time (for example 30 min), and exit with a distinct status and message. Then a hung holder becomes a refusal U4 can route instead of a silent stall. Otherwise, record the unbounded wait as accepted in the plan's D14 text.

## Endorsements

- `--cycle-diff`'s questions work on the real files (about 300 KB, 2,858 lines) should be a small fraction of the mode's run time. With a clean index the mode takes the same 0.9 s as with all four files staged (M3). This claim is phrased for checking: a profile should show state_start dominating. `[unverified — submitted as claim]`
- raw_records leaves --main-log's output unchanged over 1,100 real commits: main's and HEAD's outputs were byte-identical in M1. This holds for this history only, not as a general equivalence. `[unverified — submitted as claim]`
- take_lock's added per-run cost (one git rev-parse and a re-exec of the script under flock) is in the milliseconds, against a 3–9 minute run (M4: 7.4 ms per round). `[unverified — submitted as claim]`
- check_line's and cycle_diff's single raw_records calls add no multiplied work. Each runs once per decision. The array copies in check_line (`:1317-1318`) are linear in the merge's changed paths. `[read: scripts/build-loop.sh:973-980, 1313-1318, 1806-1813]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | raw_records' `tr \| wc` fork per commit in --main-log (+4.3 s / +21% over 1,100 commits) | Low | `scripts/build-loop.sh:973-980`, `:1709` | High |
| 2 | health-check.lock: unbounded wait, held across the whole gate | Low | `scripts/health-check.sh:1106-1121` | Medium |

## Overall Assessment

The branch is sound on performance. `--cycle-diff` is linear over files of about 300 KB, and its cost is dominated by the state checks it shares with `--main-log` (about 0.9 s total on the real repo). The lock adds milliseconds per run. The one measured regression is raw_records' NUL-count fork, now paid on every single-parent commit `--main-log` reads. It is +21% on a full-history 1,100-commit log, and small in normal per-cycle use. A fork-free count with the same acceptance fixes it in place. The lock's unbounded wait is a design question for D14 and U4, not a defect in this unit. Neither finding blocks.

**Goal-Alignment Note.** The goal is to land U3c's `--cycle-diff`, the shared raw_records reader (row 724) and the health-check flock (D14) through the review-fix loop. Nothing here works against it. Finding 1 is a constant-factor cost of the row-724 consolidation, and can be fixed without giving up the single reader. Finding 2 concerns how the D14 serialization behaves when a holder hangs, which U4's unattended loop will meet first.
