Commit: 43b8d7ed

# Performance Review: feat/build-loop-u4c (final confirming pass)

**Scope:** `git diff main...feat/build-loop-u4c` (HEAD 43b8d7ed), delta since i1 (`1bc823ea..43b8d7ed`: `skills/dev-cycle/SKILL.md` +64/-30 in total with `test/scripts/build-loop-orchestrator.bats`); i1's snippet measurements stand for the unchanged parts
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-final.md` (merged k=3); `docs/reviews/performance-review-2026-10-13-u4c-i1.md`

## Data Flow and Hot Paths

Since i1, the changes with any runtime cost are these:

1. **Step 0.1's image checks** (`SKILL.md:283-299`). These run once per iteration, after `--state`, from MAIN_WT. The sequence is `hg cat-file -e 'C^{commit}'`, then `hg merge-base --is-ancestor C M`, then `hg diff --quiet C M -- PATHS`. Only when that diff exits 1 does `hg diff --name-only` run as well. That makes 3-4 hardened git processes per cycle. Each is one Bash tool turn or part of one, so the path is cold.
2. **`own()`** (`SKILL.md:228`) now tests that the file exists first (`[[ -e "$1" || -L "$1" ]] || no "$1 is missing"`). That test is a bash builtin, and an existing path still gets exactly one `$(stat ...)`. Fork count per call is unchanged at 9 (i1 Finding 1).
3. **The exec line** adds `-u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE` to the existing `env`. It adds no process.

**Measured here** (2026-10-13, /workspace, main at 2aaf97b4 with 2593 commits reachable, load average ~8.4-10.9, each git call run 3 times with the `hg` function copied verbatim from `SKILL.md:68`):

| Call | real C (774a0eef, 44 commits behind M) | C not on main (43b8d7ed) | C = root commit (2593 behind) |
|---|---|---|---|
| `cat-file -e` | 2-5 ms | 3-5 ms | 3 ms |
| `merge-base --is-ancestor` | 4-7 ms (rc 0) | 2-3 ms (rc 1) | 39 ms (rc 0) |
| `diff --quiet -- PATHS` | 2-5 ms (rc 1) | 3 ms | 4 ms |
| `diff --name-only -- PATHS` | 3-4 ms | 5 ms | 5 ms |

Step 0.1 therefore costs about 15 ms per cycle in the realistic case. The real image is 44 commits behind main and the diff exits 1, so in the current state all four calls run. **Test suite:** `bats test/scripts/build-loop-orchestrator.bats` gave 26/26 ok in 25 s, against i1's 42 s under heavier load. The one added test (`:347`) sources the lib and runs one grep.

## Findings

#### `merge-base --is-ancestor` walks C..M without the commit-graph

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:288`
**Move:** Ask "what's the size of N?"
**Classification:** Macro (linear in commits between C and M) / Cold path (once per cycle)
**Confidence:** High
**Baseline:** 39 ms for a 2593-commit gap (C = root commit), 4-7 ms for the real 44-commit gap, measured in this review on 2026-10-13 under load ~9

Evidence: "Else, if `hg -C MAIN_WT merge-base --is-ancestor C M` exits 1," with `hg` carrying `-c core.commitGraph=false`. With the commit-graph off, git walks commits from M back to C's generation, about 15 µs per commit here. The gap is C..M, not main's whole history. It grows only while the image goes unrebuilt, and the image-lag entry exists to keep the image rebuilt. A non-ancestor C stopped in 2-3 ms in the measured case. Even a 100k-commit gap would cost about 1.5 s once per cycle. This is not row 740's per-call walk: it runs once per iteration, not on every D6 call.

**Recommendation:** None. Turning `core.commitGraph=false` off would break the hardening that `hg` exists for. The cost is bounded by the image-lag gap and is paid once per cycle.

## Prior rows and findings rechecked

- **i1 Finding 1** (`own()` makes 9 `stat` forks): unchanged. The new missing-file test is a builtin and adds no forks.
- **Row 740** (history walk per D6 call): still resolved. Step 0.1's `merge-base` is the only new history-dependent read. It runs once per cycle, outside the D6 block, and scales with the C..M gap, not with main's full history.
- **Fact-check Claims 1 and 6** (the order of step 0.1's skip conditions): correctness and wording issues with no performance effect. Whichever condition skips, at most the 3-4 calls above run.

## Endorsements

- Step 0.1 runs `diff --name-only` only after `diff --quiet` exits 1, so a clean image pays three git calls, not four. [read: skills/dev-cycle/SKILL.md:290-295]
- The D6 block's per-call process count is unchanged since i1. `own()`'s added existence check is a `[[ ]]` builtin, and the exec line's extra `-u` flags go to the same `env`. [read: skills/dev-cycle/SKILL.md:228, 247]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `merge-base --is-ancestor` walks C..M without the commit-graph | Informational | `skills/dev-cycle/SKILL.md:288` | High |

## Overall Assessment

The delta since i1 adds about 15 ms of git work per cycle, measured in step 0.1, and leaves the D6 block's per-call cost where i1 measured it (about 48 ms, flat in history). The only part that grows with anything is the ancestry check, which is linear in the image's lag behind main and runs once per cycle. It measured 39 ms even at the full 2593-commit history. Nothing needs fixing before merge. No further profiling is needed.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/performance-review-2026-10-13-u4c-final.md (first line `Commit: 43b8d7ed`), per the skill.
- Answered: the cost of step 0.1's per-iteration git calls (measured for three C cases), the D6 block delta since i1 (no added forks), bats runtime (26/26, 25 s), and i1 Finding 1 and row 740 rechecked.
- Out of scope: the wording and order of step 0.1's conditions (fact-check Claims 1 and 6), security of the image trust model, and anything that needs root or the host.
- Escalate: none.
