Commit: 1d829fee

# Performance Review: feat/build-loop-u3b2 (`--main-log SINCE`), iteration 1

**Scope:** `git diff main...HEAD` (main b5f21758, HEAD 1d829fee). The perf-relevant code is `scripts/build-loop.sh:1358-1364` (gate_msg), `:1594-1654` (ANSWERS_AWK, log_class), `:1657-1669` (main_log), `:1679-1682` (dispatch)
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md` (Stage 1)

## Data Flow and Hot Paths

`--main-log SINCE` runs once at the start of each orchestrator iteration (plan line 247: `start: --state, --main-log → 0 digest ...`). It first runs `state_start` (default_gate, gate repo setup, `store_check --main` re-hashing main's tip commit and full tree). It then lists main's entire first-parent history into a file with one `gate_git rev-list` (`:1659`) and cuts it at SINCE with awk (`:1661`). Then, for each commit above SINCE, oldest first, it calls `log_class` (`:1665`). log_class reads the commit with `gate_git cat-file commit`, then runs one awk and one perl. By class it then does one more step:
- **gate:** gate_msg plus `cmp`.
- **chore:** a raw `diff-tree`, plus one `cat-file blob | awk` per changed cycle record.
- **answers:** a raw `diff-tree`, then `tr|wc`, a patch `diff-tree`, and awk.

Every `gate_git` call is a subshell plus a git process. So a commit costs about 4 to 7 process spawns.

N, the number of commits since the last cycle record, is normally small. It counts the merges and answer commits of one iteration, likely under 20. The path is warm, not hot: it runs once per iteration, and a model-driven iteration lasts minutes. /workspace today has 1,118 first-parent commits on main (2,505 in total) and a 3,426-path tree.

**Measurements** (my probes, fixture repos under `/tmp/u3b2rv-perf-*`, all removed; wall-clock from `$EPOCHREALTIME` around `bash scripts/build-loop.sh --main-log ...`; WSL2 host):

| Fixture | Case | Wall time |
|---|---|---|
| 20,201 first-parent commits (fast-import, empty) | SINCE = tip (N=0) | 0.12 s |
| same | SINCE not on first-parent history (random id) | 0.15 s |
| same | SINCE 200 commits back (100 answers + 100 other) | 1.90 s (about 9 ms/commit) |
| same | SINCE = root (N=20,200, all other) | 141.65 s (about 7 ms/commit) |
| 200 gate-message two-parent merges | N=200 | 1.14 s (about 5.7 ms/commit) |
| 100 real `--no-ff` chore merges | N=100 | 0.87 s (about 8.7 ms/commit) |
| one answers commit adding 500,000 answer lines (questions.md 5.5 MB) | N=1 | 0.26 s |
| chore merge whose record is 64 MB, `Branch:` line last | N=1 | 0.44 s |
| one commit with a 32 MB single-line message | N=1 | 1.68 s; output line cut to 4,096 bytes by scrub |
| copy of /workspace main's tree (3,360 files), N=0 | `--state` ×3 / `--main-log` ×3 | 0.40-0.42 s / 0.41-0.45 s |

## Findings

#### 1. Per-commit fork cost makes a far-back SINCE linear at about 7 ms/commit (141.65 s at N=20,200)

**Severity:** Low
**Location:** `scripts/build-loop.sh:1664-1666` (loop), `:1618-1654` (log_class)
**Move:** Count the hidden multiplications; what's the size of N?
**Classification:** Micro (a constant number of process spawns per commit) / Cold-to-warm path (once per iteration; N is normally small)
**Confidence:** High
**Baseline:** 141.65 s for N=20,200 empty first-parent commits (all `other`); 1.90 s for N=200 mixed answers/other; measured by this review's probe 2026-10-12 (fixture described above)
**Legibility-target:** U4 implementer (the orchestrator's choice of SINCE when no cycle record exists yet)

Evidence (`:1664-1666`):
```
  while IFS= read -r c; do
    log_class "$c"; echo "$CLASS $c $SUBJ"; [[ "$CLASS" != other ]] || o=1
  done < <(tac "$GATE_TMP/after")
```
Evidence (`:1620-1621`, log_class's first read, before the per-class branch): `CLASS=other; SUBJ=""` / `gate_git cat-file commit "$c" > "$GATE_TMP/c" || return 0`

Each commit pays a subshell and git spawn for each `gate_git` call, plus awk and perl. The loop does not stop at the first `other`, because the design prints every line. The work is linear and the per-commit constant is fine for the expected N of one iteration (well under 1 s). It matters only if SINCE is far back. That can happen on a first cycle with no record, if the caller passes the root or an old `Main at:`, or after the loop has been idle for a long time. At /workspace's 1,118 first-parent commits, a root SINCE would take about 8 s by the measured rate. That figure is extrapolated, not run, because /workspace refuses gated modes (Q-139). This is not a correctness issue, and the cost stays bounded by history length.

**Recommendation:** No change needed in U3b2. U4 should not pass the root (or anything that old) as a bootstrap SINCE. It should take the first record's `Main at:` instead. If a batch speedup is ever wanted, one `git cat-file --batch` over all N commits would replace N `cat-file commit` spawns.

#### 2. `--state` and `--main-log` each run state_start at iteration start, so main's full re-hash runs twice

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1675-1682` (dispatch); `:1210-1216` (state_start); plan `docs/working/plan-build-loop-handoff.md:247`
**Move:** Find the work that moved to the wrong place (duplicated startup)
**Classification:** Macro-in-tree-size (store_check is linear in main's tree) / Cold path (once per iteration)
**Confidence:** High
**Baseline:** 0.40-0.42 s per `--state` and 0.41-0.45 s per `--main-log` with N=0, on a 3,360-file copy of /workspace main's tree; measured by this review's probe 2026-10-12
**Legibility-target:** U4 implementer and the orchestrator design (plan line 247; earlier U3b1 performance review Finding 4)

Evidence (`:1675-1681`):
```
  state)
    state_start
    echo ok
    ;;
  main-log)
    state_start
    main_log "${ARGS[0]}" || exit 2
```
Evidence (plan `:247`): `start: --state, --main-log → 0 digest (from main) → 1 health → { 2 triggers | 3 questions | 4 spot-check | 4b audit check }`

`--main-log` already runs the whole of `--state`'s `state_start`, including the gated-mode `state_gate` that every gated mode runs. The planned start sequence then pays the default_gate and `store_check --main` re-hash of main twice. N=0 `--main-log` adds almost nothing on top of state_start (0.41-0.45 s against 0.40-0.42 s), so nearly all of each call's time is this shared setup. The duplicate is about 0.4 s per iteration at today's tree size and grows linearly with the tree. That is negligible next to a model iteration.

**Recommendation:** When U4 wires the start sequence, consider running `--main-log` alone, since its refusals include `--state`'s. If the two are kept separate for clearer refusal routing, record that the cost is accepted. No change in this diff.

## Endorsements

- **SINCE-not-found costs one first-parent listing.** On 20,201 commits it took 0.15 s against 0.12 s at N=0 (measured). That holds even with the commit-graph off (fact-check Claim 4 scope). rev-list writes to a file and awk stops at SINCE, so the full listing adds about 30 ms and no per-commit work happens before the refusal. `[read: scripts/build-loop.sh:1659-1662]`
- **The record check streams the blob and does not exit awk early, which is the right trade.** An early `exit` would SIGPIPE `gate_git`'s git and fail the pipefail pipeline into "no record". A 64 MB record classified in 0.44 s (measured). `[fact-check: claim 25 — Verified]`
- **A giant commit message is bounded on the line count.** `mapfile -t -n 5` reads at most 5 lines, so a many-short-lines message does not cost what `--marker`'s did (U3b1 i1 Finding 1). A 32 MB one-line subject took 1.68 s and printed a 4,096-byte line through scrub (measured). The perl `-0777` slurp still holds the whole message once. `[read: scripts/build-loop.sh:1624-1625]`
- **The answers rule is single-pass and memory-bounded per hunk.** ANSWERS_AWK keeps only the current hunk's header lines (`r[]`, `a[]`, reset in `flush`), so a 500,000-line answers diff classified in 0.26 s (measured). Non-question paths return at the first raw record, before any patch is produced. `[read: scripts/build-loop.sh:1594-1612, 1642-1651]`
- **gate classification reads no diff.** It costs only the commit read, gate_msg and `cmp`: about 5.7 ms/commit, measured on 200 merges. `[read: scripts/build-loop.sh:1626-1632, 1358-1364]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-commit fork cost: about 7 ms/commit, 141.65 s at N=20,200; matters only for a far-back SINCE | Low | `scripts/build-loop.sh:1664-1666`, `:1618-1654` | High |
| 2 | `--state` + `--main-log` at iteration start re-hash main twice (about 0.4 s each) | Informational | `scripts/build-loop.sh:1675-1682`; plan `:247` | High |

## Overall Assessment

`--main-log` is performance-sound for its use: one call per iteration over the few commits since the last cycle record. Every pathological input I built finished in under 2 s at N=1: a 5.5 MB answers diff, a 64 MB record and a 32 MB message. None blew up memory the way U3b1's `--marker` body did, because the readers stream or cap. The one scaling dimension is N. The work is linear at about 5-9 ms of process spawns per commit, so only a bootstrap SINCE far back in history costs real time, and that choice belongs to U4. The rest of the time is the existing `store_check` of main, which the planned start sequence pays twice. Both items are fixable in U4's wiring and need no change here. All numbers are measured, except the about 8 s /workspace extrapolation in Finding 1.

## Goal-Alignment Note

Success criterion: "A performance review saved to docs/reviews/performance-review-2026-10-12-u3b2-i1.md in the worktree, per the performance-reviewer skill." This report is saved at that path, starts with the `Commit: 1d829fee` line, and follows the skill's structure: baseline on every finding, classification × path tags, evidence-gated endorsements. It covers the four focus areas the brief asked for:
- per-commit gate_git forks (Finding 1);
- the full first-parent rev-list (Endorsement 1);
- large diffs, blobs and messages (Endorsements 2-4);
- the SINCE-not-found path (Endorsement 1).

The measured commit counts and timings are in the table above. No finding argues against landing U3b2. Both findings are inputs to U4's wiring of the iteration start.
