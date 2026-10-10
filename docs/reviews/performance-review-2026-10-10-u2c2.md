Commit: 3111ee9d

# Performance Review — feat/build-loop-u2c2 (U2c2, the walk side)

**Scope:** `git diff main...HEAD` (one commit, 3111ee9d): `scripts/build-loop.sh` srules, `scripts/lib/dev-cycle-read.sh` (floor, truthwalk, main_imports, imported_names, import_readers, import_readers_key, prompt_marks, outside_seeds, c1_seeds), `test/scripts/build-loop-check.bats`
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report.md` (Stage 1, k=1; Claims 16, 17, 19, 20, 28 escalated or relevant)
**Environment for every timing below:** this container, 16 cores, load average 0.2 to 1.8; this repository has **11 registered worktrees** (10 present, 1 prunable host path, `/home/magfrump/cw-egress-verify`), so IMPORT_OTHER holds 9 roots; `CLAUDE_CONFIG_DIR=/home/node/.claude`; `~/.claude/skills` is a symlink to `/opt/claude-workflows/skills`. Probes (`perf1-probe-real.sh`, `perf1-probe-real2.sh`, `perf1-probe-micro.sh`, `perf1-probe-check.sh`, `perf1-probe-key.sh`, `perf1-probe-ab.sh`) are in `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/`. Each made and removed its own `perf1-XXXX` dir. "Old" means `git show main:` of the same file.

## Data Flow and Hot Paths

`build-loop.sh --check` runs `check_line` once per brief. check_line runs `import_reset`, lowers every changed path in one `lower_all`, and then calls `srules` per changed path. srules calls `floor PATH STEM STATUS LOWERED`. The first floor call that reaches `truthwalk main` walks main (about 3 to 4 s over this repository). Every later call should be a cache hit. So the **per-path** part of floor is the hot loop: N is the number of paths a self-merge branch changes, with no upper bound. The walk itself is cold, at once per decision. `--check-fix` (dev-cycle.sh check_fix) calls `truthwalk tree` once per argument. It is a cold path, with a handful of arguments.

Measured sizes for this repository: the main walk list `IMPORTED_MAIN` is 80,855 bytes (1,811 lines). That is 2% of `IMPORT_OUT_MAX=4000000`. `IMPORTED_MAIN_DONE` is 1,156 bytes (1,077 on main), and `IMPORT_READERS_KEY` is 180 bytes (137 on main).

Headline measurements:

| What | This branch | main's code | Source |
|---|---|---|---|
| `--check`, fixture, 1 self-merge brief, 400 added paths at depth 5, 1 worktree | 0.68 s, 0.66 s | 2.72 s, 2.84 s | perf1-probe-check.sh |
| cached floor, this repository (11 worktrees), 400 paths at depth 6, `$4` passed | 0.98 ms/path, 1.04 ms/path | 13.1 ms/path, 15.5 ms/path | perf1-probe-real.sh / real2 |
| cached `main_imports` call, this repository | 0.357 ms | 1.201 ms | perf1-probe-key.sh |
| main walk, this repository, 3 interleaved runs each | 3.40 / 3.85 / 4.16 s | 3.25 / 3.65 / 3.88 s | perf1-probe-real2.sh |
| main walk, live prompt marks on vs off (same lib), 4 pairs | 3.16 / 3.21 / 4.52 / 3.38 s | off: 2.95 / 3.10 / 3.14 / 3.19 s | perf1-probe-ab.sh |

The unit's per-path goal is met. In the fixture, end-to-end `--check` is about 4x faster at 400 paths. Over this repository the cached floor is about 13x faster. Per path, the cost that remains over this repository is mostly the walk-list glob (Finding 2), not forks.

## Findings

#### 1. Live prompt marks re-read 109 names per walk here, and none of them adds a name: every symlinked config prompt now pays the F3 over-read

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1352-1363` (prompt_marks), called at `:1615` (imported_names) and `:1751` (main_imports)
**Move:** Find the work that moved to the wrong place / Question the cache (hit rate of a mark)
**Classification:** Macro (re-reads scale with the names each symlinked prompt imports, times the distinct link directories) / Cold path (once per walk, so once per decision), but it runs over a config tree of any size
**Confidence:** High (measured)
**Baseline:** 109 re-queued names per walk, both walks, measured with a counting wrapper over this repository on 2026-10-10 (perf1-probe-real2.sh). Main walk 3.16 to 3.38 s with the live marks against 2.95 to 3.19 s without them (perf1-probe-ab.sh, 4 interleaved pairs, one 4.52 s outlier excluded).
**Legibility-target:** maintainer of prompt_marks; security reviewer weighing F3's cost

Evidence (`:1353-1355`; prompt_marks continues to `:1363`, which was read: each repo name in OUT whose marks change is appended to RQ, and the walk re-queues it):
```bash
  local -n pm_p="$1" pm_x="$2" pm_o="$3" pm_r="$5"; local p l="$4" lp="${pm_p[$4]}" b pm_b=()
  if [[ "$l" == //* ]]; then l="${l#/}"; lp="${lp#/}"; else b="$(realpath -e -- "$l")" || return 1; [[ "$b" != "$l" ]] || return 0; fi
  prompt_bases pm_b "$lp" "$l"
```
The branch's own doc names this cost: "OUT also holds the target's own names, marked too, an over-read only". The test is `realpath(F) != F`. That holds for a prompt that is itself a link, and also for any prompt under a symlinked directory. In this container `~/.claude/skills -> /opt/claude-workflows/skills`. Probe output (main walk, each live entry, its real path and the names it re-queued):
```
  live /home/node/.claude/skills/ui-visual-review/references/accessibility-serialization.md -> /opt/claude-workflows/skills/... rq+36
  live /home/node/.claude/skills/ui-visual-review/references/3d-viewport.md -> /opt/claude-workflows/skills/... rq+33
  live /home/node/.claude/skills/dependency-upgrade/SKILL.md -> /opt/claude-workflows/skills/... rq+19
  live /home/node/.claude/skills/code-fact-check/SKILL.md -> ... rq+12
  live /home/node/.claude/skills/test-strategy/SKILL.md -> ... rq+7
  live /home/node/.claude/skills/dev-cycle/SKILL.md -> ... rq+2
  (3 more live entries with equal real paths: rq+0)
dev-cycle-read.sh main walk=ok ... listbytes=80855 names=1811 prompt_marks: live=9 dangling=0 requeued=109
old-lib.sh main walk=ok ... listbytes=80855 names=1811 prompt_marks: live=0 dangling=0 requeued=0
```
`/opt/claude-workflows` is not a reader root, so no projection into the repository exists. All 109 re-reads therefore fall on the target's own names (the over-read the doc mentions). The walk list is byte-identical with and without them (80,855 bytes, 1,811 lines). The price is about 0.15 to 0.2 s per walk (5 to 7%). This review measured only the main walk with marks on and off. The tree walk calls the same code at `:1615`, and its runs here measured 3.53 to 4.30 s on main against 3.70 to 4.56 s on this branch. So each decision that runs both walks probably pays about 0.3 to 0.4 s. The cost grows with every skill or command installed through a symlinked config directory, which is the standard install shape in this container. It also grows with each distinct link directory that imports the same name, because each adds a new mark and a new re-read.

**Recommendation:** Mark only when the real path lies below a reader root, the only case in which F3's projection can add a repo name. Otherwise return 0, as for a plain entry. outside_seeds already holds every seed's `realpath -m` (`rl[i]`, `:1448-1452`) and tests it against `rs` there, so the walk can reuse that answer. Keep the over-read for a target inside a root if splitting the target's own names from the projection's is not worth the code. Either way, record the 109-re-read baseline in the override row so later growth is visible.

#### 2. The walk-list glob is now floor's dominant per-path cost, and it is linear in the list: 18.5 ms per path near IMPORT_OUT_MAX (rows 470, 611)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1827-1833` (truthwalk), reached from floor `:1884`
**Move:** Ask "what's the size of N?" / Check the asymptotic behavior
**Classification:** Macro (O(list bytes) per path, so O(paths × list) per decision) / Hot path (per changed path in `--check`)
**Confidence:** High (measured)
**Baseline:** 0.330 ms/path on an 80,856-byte list (this repository's size). 4.218 ms/path at 1 MB, 18.490 ms/path at 4,000,001 bytes (400 paths 7.40 s). Measured by perf1-probe-micro.sh with main_imports stubbed as a cache hit, 400 misses each, on 2026-10-10.
**Legibility-target:** floor / truthwalk maintainer; whoever revisits override rows 470 and 611

Evidence (`:1829-1832`; the function ends at `:1833` with `}`):
```bash
  case "$1" in main) main_imports || return 0; local -n tw_l=IMPORTED_MAIN ;; tree) imported_names || return 0; local -n tw_l=IMPORTED ;; *) return 0 ;; esac
  TRUTH_WHY=imported
  [[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* && "$tw_l" != *$'\n'"$2"$'\n'* ]] || return 0
```
This is not a regression. Main's `isimported` ran the same glob, plus two forks. What changes is the ranking. With the forks gone, a cached floor costs 0.13 ms at depth 1 with an empty list (micro B). At this repository's 80 KB list the glob is about a third of the 0.98 ms per path measured here. Above roughly 30 KB the glob outweighs all of floor's other work, and at the cap 400 paths spend 7.4 s in it. The per-path list size in Row 611 ("0.12 ms per path on a 28 KB walk list, 43 ms only near IMPORT_OUT_MAX") reproduces: 0.121 ms at 28 KB. The near-cap figure is 18.5 ms here rather than 43 ms. Both say "linear, and it bites only near the cap". Today this repository is at 2% of the cap. The list's size is not under the brief author's control alone, though: it grows with config-dir and other-worktree imports (Finding 1's skills are part of it).

**Recommendation:** Keep row 470's deferral, but make its trigger a number the gate can see: for example, build the associative set once per walk when `${#IMPORTED_MAIN}` passes about 500 KB (about 2 ms per path). The set costs one pass over the list, and the cache key already marks when it must be rebuilt. No change is needed for this unit.

#### 3. A cached floor still forks when import_readers' memo misses but main's cache hits (fact-check Claim 20)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1654-1656` (main_imports' head), floor's doc `:1863-1864`
**Move:** Count the hidden multiplications
**Classification:** Micro (3 to 4 forks, once per key change) / Cold in the gate (no caller changes the key within a decision)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative. The fork count is the fact-check's (Claim 20, fc1-floor.log section E: `getent` 1, `git` 1, `realpath` 2 after HOME is unset). This review measured no latency for that path.
**Legibility-target:** performance critic; floor's doc reader

Evidence (`:1654-1656`; main_imports continues to `:1784`, which was read):
```bash
  import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_WHY=readers; return 1; }
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  # Below the cache check: a hit reads nothing here, so floor's cached calls fork no root check (U2c1 final performance 1).
```
check_line (`build-loop.sh:777-847`) changes none of HOME, CLAUDE_CONFIG_DIR, IMPORT_READER_* or IMPORT_MANAGED_DIR between srules calls. So in `--check` the miss happens at most once per decision, which is the walk's own first call. A caller that toggled one of these per path would pay about 4 forks per path, but no such caller exists. This is a doc-precision item: the fact-check's wording "a call that both import_readers' memo and main_imports' cache answer forks nothing" is exact.

**Recommendation:** Adopt the fact-check's wording in floor's doc. No code change.

#### 4. truthwalk tree still forks need_root on every call (fact-check Claim 17)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1576-1582` (imported_names' head), truthwalk doc `:1819-1826`; caller `scripts/dev-cycle.sh:185`
**Move:** Count the hidden multiplications
**Classification:** Micro (one `pwd -P` fork per call) / Cold (`--check-fix`, one call per argument)
**Confidence:** High
**Baseline:** 1.101 ms per cached `imported_names` call on this branch against 1.099 ms on main's code, over this repository (perf1-probe-key.sh, 400 calls). The change neither helps nor hurts the tree walk's cached call.
**Legibility-target:** check_fix maintainer

Evidence (`:1579-1582`; imported_names continues to `:1632`, which was read):
```bash
  need_root
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  # The roots never hold an empty line, so the blank line ends them.
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && { [[ "$IMPORTED" != error ]]; return; }
```
`--check-fix` per argument now forks `lower` (check_fix's own) and imported_names' need_root, against 4 forks before (isimported's lower and need_root were dropped). The doc's "with no fork" and "exits through need_root when it walks" are true for `main` only. The price is sub-millisecond on a cold path.

**Recommendation:** Either move imported_names' need_root below its cache check, as main_imports now does (symmetry, about 0.5 ms per `--check-fix` argument), or correct truthwalk's doc to say the tree walk's root check runs on every call. Either is fine for performance.

#### 5. prompt_marks forks a realpath that outside_seeds already computed

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1354` (prompt_marks), compare `:1448` (outside_seeds' batched `realpath -mz`)
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (one fork per live absolute prompt entry per walk) / Cold (per walk)
**Confidence:** High
**Baseline:** 9 live absolute prompt entries per walk over this repository and its config dirs. That gives 27 extra `realpath -e` forks over 3 walks (349 against 322 `-e` calls, perf1-probe-real.sh). At about 1 to 2 ms per fork, that is roughly 10 to 20 ms per walk. The per-fork figure was not measured in this pass.
**Legibility-target:** maintainer of prompt_marks / outside_seeds

Evidence: the realpath fork is the `else` arm of `:1354` (quoted in Finding 1). outside_seeds runs `nul_list rl xargs -0r -a <(printf '%s\0' "${cx[@]}") realpath -mz --` over every config seed (`:1448`). root_copies' entries get one in its batched realpath too (`:1323`). C1 seeds get none. Over this repository, the 9 entries are the 6 symlinked skills, 2 plugin READMEs and one prompt under `/workspace/external/SWRBench2/repos/pydata__xarray/.claude/skills/`. The forks are about 0.5% of a 3.4 s walk.

**Recommendation:** None needed now. If Finding 1's fix records "real path below a root" per seed, carry that in a map, and both the fork and the over-read go away together.

## Endorsements

- Passing check_line's lowered path as floor's `$4`, and moving main_imports' `need_root` below its cache check, takes the cached per-path floor cost over this repository (11 worktrees) from 13.1 to 15.5 ms to 0.98 to 1.04 ms. It takes `--check` over 400 fixture paths from about 2.8 s to about 0.67 s. The cached `main_imports` call goes from 1.20 ms to 0.36 ms. These numbers are this reviewer's probes, and fact-check Claims 16, 19 and 28 cover the mechanism by execution. [unverified — submitted as claim]
- floor's new ancestor `isstart` loop costs about 0.017 ms per path component: 0.132 ms/path at depth 1, 0.233 at depth 6 and 0.330 at depth 12 with a stubbed walk (perf1-probe-micro.sh B). It is negligible next to the glob in Finding 2. [unverified — submitted as claim]
- IMPORT_CONFIGS adds 79 bytes to main's cache key (1,077 to 1,156) and 43 bytes to import_readers' key (137 to 180) over this repository. That is too little to measure in a string comparison. Moving the config-dir computation into import_readers runs it once per decision instead of once per walk. [unverified — submitted as claim]
- The c1_seeds split moves code without changing the work: the same `root_starts`, `lower_all` and `with_at` calls, once per walk. Both walks' lists over this repository are byte-identical with main's code (80,855 bytes, 1,811 lines). [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Live prompt marks re-read 109 names per walk here, all over-read (symlinked `~/.claude/skills`), about 0.15 to 0.2 s per walk | Low | `dev-cycle-read.sh:1352-1363` | High |
| 2 | Walk-list glob is now floor's dominant per-path cost; 18.5 ms/path near IMPORT_OUT_MAX (rows 470, 611) | Low | `dev-cycle-read.sh:1827-1833` | High |
| 3 | Cached floor still forks on an import_readers memo miss (Claim 20) | Informational | `dev-cycle-read.sh:1654-1656`, `:1863-1864` | High |
| 4 | truthwalk tree forks need_root per call (Claim 17) | Informational | `dev-cycle-read.sh:1576-1582`, `:1819-1826` | High |
| 5 | prompt_marks re-forks a realpath outside_seeds already has | Informational | `dev-cycle-read.sh:1354`, `:1448` | High |

## Overall Assessment

This change does what it was built to do. floor's per-path cost drops by an order of magnitude, measured end to end through `build-loop.sh --check` and over this repository's 11 registered worktrees. No new per-path fork or quadratic term appears. The per-path cost that remains is the walk-list glob. That glob is linear in the list, and the list is at 2% of its cap here. It belongs to rows 470 and 611's existing deferral, and its trigger could now be stated as a size. The one new cost is per walk, not per path: the F3 fix's live-link marking also fires for every prompt under a symlinked directory. In this container's standard layout (`~/.claude/skills` is a link out of every reader root) that is 109 re-reads per walk that add nothing, about 5 to 7% of a walk. The fix is local: mark only when the real path is below a reader root. Nothing here blocks landing. Finding 1's per-walk cost is the one to raise if a decision's walk time ever matters.

## Goal-Alignment Note

The user's goal is to land U2c2 after a clean review-fix loop. This review measured the unit's stated performance aim, floor's per-path cost, end to end and over the real repository. The aim holds (about 4x end to end in the fixture, about 13x per cached path over this repository). The review found no regression on the hot path, so nothing here gates the merge. Findings 1 and 2 are Low, and Findings 3 to 5 are Informational doc or symmetry items, two of which repeat fact-check escalations with a measured price attached. Finding 1 is a real cost the commit's own words ("an over-read only") understate in this container, and it is cheap to fix in this unit or to route with its baseline. One gap: `--check` could not be timed against this repository itself, because that needs a self-merge brief committed on main. The real-repository numbers are therefore per-path and per-walk lib timings, not a full `--check` run.
