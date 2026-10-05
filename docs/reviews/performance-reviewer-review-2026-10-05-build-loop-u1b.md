Commit: 1d79ffef

# Performance Review: feat/build-loop-u1b (U1b, review-fix loop iteration 3, final)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 1d79ffef (scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats). The docs/reviews/ files are review records and are not reviewed here.
**Date:** 2026-10-05
**Based on:** the shared Stage-2 context (review-u1b-i3/shared-stage2.md) and the merged Stage-1 fact-check summary (docs/reviews/code-fact-check-report-build-loop-u1b.md at 1d79ffef). No fact-check claim is about performance, and nothing here contradicts one.

## Data Flow and Hot Paths

`build-loop.sh --settings` is a one-shot CLI read. It runs one `scrub_reexec` (a child bash plus two perl filters), `git rev-parse`, `resolve_main`, one `main_entry` (its ls-tree cost is settled for u1a), and one `git cat-file blob | awk "$FENCE_AWK$SETTINGS_AWK"` pass over docs/dev-cycle.md. Bash then parses at most three result lines. When the never line has the right shape, `read_settings` splits it and calls `globform` once per entry. **Path temperature: cold.** The dev cycle's orchestrator runs it once before dispatch, and nothing loops over it. The input is docs/dev-cycle.md on main's commit, about 36 lines today.

What changed at 1d79ffef, and what it costs:
- **Letters-only SETTINGS_AWK (`build-loop.sh:101`).** It replaces the iteration-2 marker strip with `tolower` plus `gsub(/[^a-z]/, "")` per unfenced line. Both are linear in line length.
- **NEXT tracking (`:100`, `:105`).** One flag and one anchored blank-line regex on the line after the first copy. The cost is O(1) per line.
- **Array NEVER (`:155`, `:164`).** `NEVER=("${parts[@]}")` copies an array that already exists. That is one more copy of the list, linear and without forks.
- **Extra export `GIT_NO_REPLACE_OBJECTS=1` (`:63`).** It is an environment variable only. It adds no git call and, if anything, skips replace-ref lookups.

Measurements: this machine, mawk 1.3.4, bash 5.2.15, `LC_ALL=C`, probe repos under the performance scratch dir, wall time of the whole script including the re-exec.

| Input | Wall time |
|---|---|
| tiny file (one policy line) | 16 ms |
| test 4 (this repo's own docs/dev-cycle.md, inside bats) | 48 ms |
| 100,000 ordinary prose lines (5 MB) | 105 ms |
| one 10 MB line of `.` (gsub deletes every byte) | 388 ms |
| one 10 MB line of `a` | 307 ms |
| `Self-merge never:` with 2,000 / 20,000 short entries | 63 / 464 ms |
| bash ERE `^[^\ ]+(\ [^\ ]+)*$` (`:150`) on a 128,000-byte line of 1-character entries | 13 ms |
| **one never entry of 5,000 / 10,000 / 20,000 / 40,000 `/`-separated parts (10 / 20 / 40 / 80 KB)** | **196 / 635 / 3,054 / 11,197 ms** |
| test/scripts/build-loop-read.bats, 9 tests | 2,767 ms total; slowest is T45 at 1,006 ms |

Everything is linear except the bolded row: the per-part loop in `globform` is quadratic in one entry's length (Finding 1).

## Findings

#### 1. globform's per-part loop is quadratic in one entry's length

**Severity:** Low
**Location:** `scripts/build-loop.sh:114-121` (called from `:156-161`)
**Move:** Check the asymptotic behaviour, not just the constant
**Classification:** Macro (O(parts × length) string re-slicing) / Cold path (one-shot CLI read, once per process)
**Confidence:** High (measured; the growth ratio is about 4x per doubling)
**Legibility-target:** for-author
**Baseline:** 11,197 ms wall time for `--settings` on a single 80 KB never entry of 40,000 parts (3,054 ms at 40 KB, 635 ms at 20 KB). Measured 2026-10-05 with the probe in the performance scratch dir.

Evidence:
```
globform() {
  local rest="$1/" c
  [[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1
  while [[ -n "$rest" ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"
    [[ -n "$c" && "$c" != "." && "$c" != ".." ]] || return 1
  done
}
```
(This is the full function, `:114-121`. The caller loop at `:156-161` calls it once per entry, with `"${g%/}"`.)

Every iteration runs `${rest%%/*}` and `${rest#*/}` over the whole remaining string, which is O(remaining length). So one entry with k parts and length L costs O(k·L). Doubling the entry multiplies the time by about 4: 0.2 s, 0.6 s, 3.1 s and 11.2 s for 10, 20, 40 and 80 KB. Extrapolated, a 320 KB entry takes about 3 minutes. I isolated the cost in a standalone loop: at 20,000 parts the `%%`/`#` loop takes 2.8 s, while `IFS=/ read -ra` over the same string takes 29 ms. All of this time is spent before anything is printed, so the scrub's 4,096-byte cut (C2) does not bound it. This is not settled row C1. C1 covers the entry *count*, and that cost is linear at about 24 µs per entry. This finding is about a single entry's *part count* within one entry, which no row covers. Impact is low: the input is the never line on main's own commit (a loop can only propose it), a realistic glob has a handful of parts and costs microseconds, and a run only gets slow when a pathological line has landed on main. Even then it stalls the orchestrator's one read; it does not fail open. The validation still finishes and fails closed.

**Recommendation:** Optional, and acceptable to defer under C4 (globform moves to the lib in U2). To fix it, split once with `IFS=/ read -ra comps <<<"$1/"`, or keep a scan index instead of re-slicing `rest`, then check each part. That makes the loop linear and keeps the same rules (the trailing `/` still yields the empty sentinel, which needs care). The lib's `pathform` (`dev-cycle-read.sh:144-148`) has the same loop shape. Its inputs are brief paths and roadmap paths, short by construction, and it is out of this unit's diff.

## Endorsements

- The letters-only key match is one `tolower` and one `gsub` per unfenced line in a single awk pass. A 10 MB line of characters gsub removes ran in 388 ms end to end, and 5 MB of ordinary lines in 105 ms. [read: scripts/build-loop.sh:96-111] (linearity measured on mawk for these inputs; not proven for every awk)
- NEXT tracking adds O(1) work per line. After the first copy of a key, only the following line is tested against `^[ \t]*$`, and `pk` is cleared on that line. [read: scripts/build-loop.sh:100, :105]
- The single-space shape check at `:150` behaved linearly on glibc's ERE: 13 ms on a 128,000-byte line of 1-character entries, and no blow-up on a long line that fails to match. [read: scripts/build-loop.sh:150] (measured on bash 5.2.15 with glibc; other regex engines not tried)
- The array NEVER (`:155`, `:164`) adds one in-process array copy and no fork. Per-entry validation stays builtin-only. [read: scripts/build-loop.sh:154-164, :114-121]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | globform's per-part loop is quadratic in one entry's length (80 KB entry takes 11.2 s) | Low | `scripts/build-loop.sh:114-121` | High |

## Overall Assessment

The changes at 1d79ffef have no performance cost that matters. The letters-only matcher, the NEXT flag, the array NEVER and the extra export are all linear or constant, and the real settings file reads in tens of milliseconds. The one finding comes from re-measuring the unit in full. `globform`, unchanged since 224dd52d, re-slices its string once per path part, so it is quadratic in one entry's length. This is a cold path and needs a pathological line on main's commit, so it is Low and does not block the merge. It can be deferred alongside C4 or fixed with a one-time split. No profiling is needed beyond the probes recorded above. The bats suite takes 2.8 s, and T45 is the slowest test at about 1 s because it makes about 25 commits and script runs.

## Goal-Alignment Note

**Success criterion:** a markdown report saved to /workspace/.claude/wt-build-loop-u1b/docs/reviews/performance-reviewer-review-2026-10-05-build-loop-u1b.md, structured per the performance-reviewer skill, first line `Commit: 1d79ffef`.

**Answered:** The performance posture of U1b at 1d79ffef. The new letters-only SETTINGS_AWK, NEXT tracking, array NEVER and GIT_NO_REPLACE_OBJECTS export are linear or constant, as measured. There is one new Low finding: globform is quadratic in a single entry's part count. It is cold-path and fails closed. There are no red or amber performance findings.

**Out of scope:** E1/E3 (letter-bearing markup and homoglyph copies; security and orchestrator), E2/E4 (test gaps; test-strategy), correctness of the never-glob rules, and U1c/U2 code. The settled rows C1, C2, u1a's main_entry cost and the need_root forks are not re-raised.

**Escalate:**
- For orchestrator synthesis (for-orchestrator-synthesis): Finding 1 is not covered by C1, which is about entry count. If it is deferred, it fits C4's revisit trigger (U2 moves globform into the lib). The lib's `pathform` has the same loop shape, but it is u1a's code and its inputs are short.

**Questions / Decisions:** None.
