Commit: ae08688c

# Performance Review — feat/build-loop-u2b1a1 (final confirming pass)

**Scope:** `git diff main...HEAD` (HEAD ae08688c): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check replicates code-fact-check-report-build-loop-u2b1a1-r{1,2,3}.md (via the shared brief); override-log rows 220, 301, 310

## Data Flow and Hot Paths

`--status` runs once per orchestrator iteration over a handful of briefs (`for a in "${ARGS[@]}"; do status_line "$a"; done`, build-loop.sh:351, in the caller's shell). Each `status_line` call does `open_shared` (memoised), `check_brief`, `check_branch` and, for a branch ahead of main, `marker_kind`. Per-brief cost of about 15-21 ms is settled (rows 220, 301, 310). N is the number of briefs, single digits to tens. Every path here is **cold** by the skill's definition: a CLI run per loop iteration, not a request handler.

Measurements (bench loop of 200 runs, `$(...)` capture, throwaway repo, this WSL2 host, 2026-10-08):
- old `git log -1 --format=%B`: 911 µs; new `git cat-file commit | tr -d '\000'`: 1187 µs; `cat-file` alone: 875 µs
- check_branch's two reads (`rev-list --count` + `log -1 --format=%cs`): 1971 µs. Old and new run the same two git processes; the new code only adds two bash regex tests.
- `log -1 -G` with no driver configured: 1052 µs; with `--no-textconv`: 1026 µs (no difference within noise)

## Findings

#### marker_kind's `tr` stage adds about 0.3 ms per ahead branch

**Severity:** Informational
**Location:** `scripts/build-loop.sh:288`
**Move:** Find the work that moved to the wrong place (constant factor)
**Classification:** Micro (one extra fork per call) / Cold path (once per brief per `--status` run)
**Confidence:** High
**Baseline:** 1187 µs (new `cat-file | tr`) vs 911 µs (old `git log %B`), measured by this review's bench loop, 2026-10-08, WSL2
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
```
  if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then
```
(excerpt from marker_kind, :281-308)

Replacing `git log` with `cat-file | tr` adds one process: about +0.28 ms per branch ahead of main. That is under 2% of the settled 15-21 ms per brief. For a handoff subject the object is still read a second time by the NUL check at :294 (`git cat-file commit "$1" | tr -cd '\000' | wc -c`). That second read was already there on main, so this diff does not add it. Bash cannot hold NULs, so folding the two reads together would mean a different design (count NULs in the same pipeline through a temp file or fd). Not worth it at this N.

**Recommendation:** None. Recorded so the cost of row 307's fix is on file. It is consistent with rows 220/301/310.

No other findings. `open_shared` is memoised in the caller's shell, the same as main's `shared_branches`: one `git grep` plus one `brief_fields` per open brief, once per process. The added `main_by_name` is a pure bash test (lib:290). `check_branch` runs the same git processes as before. `--no-textconv` costs nothing measurable without a driver, and with one it removes the driver's run.

## Endorsements

- `open_shared` runs once per `--status` process: `status_line` is called in the caller's shell (build-loop.sh:351, not in `$(...)`), and the `[[ -z "$OPEN_SHARED" ]] || return 0` guard also caches the `error` result. [read: scripts/build-loop.sh:309-351, scripts/lib/dev-cycle-read.sh:461-477]
- check_branch's switch to reading into locals (`n`, `d`) adds no git process compared with main's inline `$(...)` in echo. Both versions run `rev-list --count` and `log -1 --format=%cs` once. [read: scripts/lib/dev-cycle-read.sh:436-451]
- `--no-textconv` on check_brief's `git log -G` stops any repo-local textconv driver from running during `--status`, and it costs nothing measurable when no driver is configured (1026 vs 1052 µs). [fact-check: shared brief Verified "--no-textconv stops the driver and finds the same commits" — Verified]
- When the full git log -G walk runs per brief, its cost is bounded by main's first-parent history touching that one path (`-1` stops at the first hit). This holds for repos of this size. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | marker_kind's `tr` fork adds ~0.3 ms per ahead branch (<2% of per-brief cost) | Informational | `scripts/build-loop.sh:288` | High |

## Overall Assessment

From a performance standpoint this unit makes no difference. The brief-enumeration move is the same memoised work under a new name. The row-307 hardening of `check_branch` adds no processes, and the hardening of `marker_kind` adds one cheap `tr` fork (~0.3 ms) on the cold `--status` path. `--no-textconv` costs nothing and removes a possible driver run. No profiling is needed, and nothing has to be done before merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: ae08688c` line at the top.
- Answered: yes
- Out of scope: the correctness notes under log.date bogus (check_brief's `git log -G` failing; marker_kind's dependence on pipefail) belong to the fact-check and security reviews.
- Escalate: nothing
