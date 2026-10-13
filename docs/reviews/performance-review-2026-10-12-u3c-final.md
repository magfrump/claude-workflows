Commit: 4aad0f9c

# Performance Review — feat/build-loop-u3c, final confirming pass

**Scope:** full branch, `git diff main...HEAD` (main = dafc0e74, HEAD = 4aad0f9c). Code under review: `scripts/build-loop.sh` (raw_records, check_line and log_class on raw_records, `--cycle-diff`: QKEYS_AWK, QDIFF_AWK, ROADMAP_AWK, cyc_blob, cycle_diff) and `scripts/health-check.sh` (take_lock).
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-final-r{1,2,3}.md` (k=3 at ec9dace7; the 4aad0f9c fix followed). The prior pass is `docs/reviews/performance-review-2026-10-12-u3c-i2.md`.

## Measurement provenance

- **Scratch directory.** P = `/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/perf-u3c-final`.
- **Fixture.** `P/setup.sh` made a `--no-hardlinks` clone of the worktree, `P/p-eFby/repo`. In the clone, HEAD is 4aad0f9c and local `main` is dafc0e74. The script trees for main (dafc0e74), i2 (74deb04e) and head (4aad0f9c) came from `git archive`. Nothing ran in /workspace or the worktree.
- **Host load.** The host was loaded throughout, with a load average of 7.6 to 15.7 on 16 CPUs. The variants ran interleaved, so compare the paired differences, not the absolute times.

| Run | What | Result |
|---|---|---|
| M1 | `P/mainlog.sh`: `--main-log 183b1a93…` over 1,099 first-parent commits. Four rounds, main / head / i2 interleaved. | main 22.10 / 15.94 / 18.15 / 14.89 s (mean 17.77)<br>head 21.04 / 15.93 / 17.51 / 17.54 s (mean 18.01)<br>i2 20.03 / 19.38 / 19.49 / 18.92 s (mean 19.46)<br>All outputs are byte-identical to main's: 1,098 other, 1 answers, 1 main. |
| M1b | The same command, four more head / main pairs, with load rising from 11.7 to 15.7 | head 27.64 / 27.05 / 29.85 / 26.95 s<br>main 25.56 / 26.65 / 28.62 / 28.69 s<br>Outputs identical. |
| M2 | `P/micro.sh`: 679 calls of each reader on a one-record `--raw -z` file. The i2 and head `raw_records` bodies were extracted verbatim from their build-loop.sh. Three rounds. | main's answers-loop shape: 0.028–0.052 s<br>i2 raw_records: 2.28–2.44 s<br>head raw_records: 0.094–0.111 s<br>The head body contains no `tr -cd`. |
| M3 | `P/cyc.sh`: `--cycle-diff`, i2 vs head interleaved, three rounds per state, on the real files: questions.md 32,640 B, questions-archive.md 267,762 B, roadmap 6,398 B, idea log 2,742 B. Base is dafc0e74 = main. | clean index: i2 0.73–0.88 s, head 0.74–0.83 s<br>+questions.md: 0.79–0.86 / 0.79–0.81 s<br>+archive: 0.78–0.86 / 0.79–0.81 s<br>+roadmap and idea log: 0.80–0.84 / 0.79–0.87 s<br>Every run printed `ok`.<br>`--state` alone: 0.74–0.82 s. |
| M4 | `P/comp.sh`: head's FENCE_AWK+QKEYS_AWK and QDIFF_AWK on the real archive (×1), and on ten ID-renumbered copies (×10, 2.68 MB / 25,810 lines). Three rounds. | ×1: QKEYS 6–9 ms, QDIFF 3–5 ms (330 key lines)<br>×10: QKEYS 33–49 ms, QDIFF 12–20 ms (3,300 key lines)<br>No `odd`, `unbalanced` or `quoted` line, and no diff output. |

## Data Flow and Hot Paths

- **raw_records (`scripts/build-loop.sh:966-981`)** reads each `--raw -z` listing. Only one of its callers is multiplied: log_class's single-parent branch (`:1709`), which runs once per first-parent commit in `--main-log`. The other callers run once per decision and are cold: check_line (`:1316`, once per brief per `--check`/`--merge`) and cycle_diff (`:1812`).
- **The ec9dace7 fix.** It replaced the per-call `tr -cd '\000' < "$1" | wc -c` command substitution with an in-loop `IFS= read -r -d '' p || return 1`. That removes the fork. The acceptance is unchanged: a half record fails, and trailing bytes after the last NUL are still not read. M2 shows the per-call cost fell by about 22× (from about 3.5 ms to about 0.15 ms under this load). Against main's answers-loop shape, the residual is about 0.05–0.07 s per 679 commits. That is about 0.3% of a full-history `--main-log`, below M1's noise.
- **`--cycle-diff` (`:1806-1873`)** runs once per dev-cycle iteration, before the chore commit, so it is cold. Its cost equals `--state`'s (M3: about 0.8 s in every index state). The time goes to the shared state_start, not to the new work. The iteration-2/3 changes add only constant work, linear in file size:
  - two `ls-tree -z` forks and a `cmp` for the main-moved guard;
  - an `ls-tree` per unchanged questions file, replacing the old `cat-file -e` + `ls-tree | cut` + `cat-file`;
  - one extra awk pattern per line for the `quoted` check.

  QDIFF_AWK concatenates per-ID strings of a few key lines each. M4 shows the questions readers scale linearly: 10× the archive costs about 5× to 6× the time, all under 50 ms.
- **take_lock (`scripts/health-check.sh`)** changed in this round only in its guard (`!= 1` instead of `-z`) and its comment, which has no cost effect. The prior pass's lock finding (unbounded wait, lock held across the whole gate) is deferred to U4 by override row 750 (`docs/reviews/override-log.md:750`). The diff does not change those facts, so it is not re-raised.

## Findings

No findings.

## Endorsements

- The ec9dace7 fix removes raw_records' per-call fork with the same results on this history. Head's `--main-log` over 1,099 commits is not distinguishable from main's: the mean paired difference is +0.36 s over 8 pairs, with spread −1.7 to +2.7 s. i2 averaged +1.69 s over main in the 4 pairs it ran in. Outputs were byte-identical in every run. This is a measurement on this repository's history, not a general equivalence. `[unverified — submitted as claim]`
- On a one-record listing, head's raw_records costs about 0.1 s per 679 calls, against i2's 2.3–2.4 s (M2). The extracted body contains no external command. `[read: scripts/build-loop.sh:966-981]`
- On the real files, `--cycle-diff` costs the same as `--state` (about 0.8 s) whether no file or all four files are staged (M3). The questions readers stay under 50 ms even at 10× the current archive (M4). Phrased for checking: a profile of `--cycle-diff` should show state_start dominating. `[unverified — submitted as claim]`
- The main-moved guard adds a fixed two `ls-tree` calls and one `cmp`, and only when a questions file is staged. It adds no per-entry or per-line work. `[read: scripts/build-loop.sh:1834-1842]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The iteration-2 finding is fixed, and the fix is confirmed by measurement. raw_records no longer forks per call (M2: about 22× cheaper per call), and `--main-log` over the full 1,099-commit history now runs within noise of main with identical output (M1, M1b). The iteration-2 and iteration-3 changes to `--cycle-diff` (the main-moved guard, the base-copy read through `ls-tree`, the `quoted` check) add constant or linear work measured in milliseconds. The mode's run time is the state gate it shares with `--state`. The health-check lock's unbounded wait remains a deliberate deferral (row 750), and nothing in this diff changes it. No profiling is needed before landing.

**Goal-Alignment Note.** The goal is to land U3c through its review-fix loop. This pass confirms the one prior performance finding is discharged and finds nothing new, so nothing here blocks the merge.
