Commit: 8786f8fc

# Performance Review — feat/build-loop-u2c2 (U2c2 final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` (3111ee9d, 07af69c0, 2be3db37): `scripts/build-loop.sh` srules; `scripts/lib/dev-cycle-read.sh` floor, walk_why, walk_has, truthwalk, isimported, readers_root, main_imports, imported_names, import_readers(_key), prompt_marks, outside_seeds/config_seeds/c1_seeds
**Date:** 2026-10-10
**Based on:** Stage-1 summary `fc-final-summary.md` (k=3 replicates r1-r3), rubric `code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (A1-A17, B1-B7), iteration-1 report `performance-review-2026-10-10-u2c2.md`
**Environment for every timing:** this container, 16 cores, load average 0.22 to 1.12. This repository: **11 registered worktrees** (stated by `git worktree list | wc -l` at the top of every probe), `CLAUDE_CONFIG_DIR=/home/node/.claude`, `~/.claude/skills` a link into `/opt`. The `--check` fixture: **1 worktree**. "Main's lib" is `git show main:` of the same file. Probes: `perff-probe-real.sh`, `perff-probe-fail.sh`, `perff-probe-check.sh`, `perff-probe-tree.sh`, with logs `perff-probe-*.log`, in `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/`. Each made and removed its own `perff-XXXX` dir. No `perff-*` dir or probe process remains.

## Data Flow and Hot Paths

`build-loop.sh --check` runs check_line once per brief. check_line lowers every changed path in one `lower_all`, then srules calls `floor PATH STEM STATUS LOWERED` per path (`build-loop.sh:671`). The first floor call that reaches `truthwalk main` walks main, which takes about 3 s here. That is the cold part. Every later call is a cache hit, so the hot loop is the cached per-path cost. N is the number of paths a self-merge brief changes, and nothing bounds it. `--check-fix` calls `truthwalk tree` once per argument (cold, a few arguments).

| Measurement (re-measured at 8786f8fc) | This branch | main's lib | Worktrees |
|---|---|---|---|
| `--check`, fixture, 1 self-merge brief, 400 added paths at depth 5, 3 interleaved pairs | 0.70 / 0.70 / 0.71 s | 2.84 / 2.85 / 2.91 s | 1 |
| cached floor, 400 paths depth 6, `$4` passed (2 runs) | 1.029 / 1.017 ms/path | 14.566 / 11.298 ms/path | 11 |
| cached floor, same paths, no `$4` | 2.859 / 2.867 ms/path | 8.634 / 11.736 ms/path | 11 |
| cached `main_imports` call | 0.407 / 0.421 ms | 1.226 / 1.204 ms | 11 |
| `readers_root`, memo hit (1,000 calls) | 0.029 / 0.029 ms | (absent) | 11 |
| `import_home` + `import_readers_key`, hit | 0.018 / 0.019 ms | n/a | 11 |
| `need_root` | 0.540 / 0.555 ms | same code | 11 |
| main walk, 3 interleaved pairs | 2.99 / 3.05 / 3.02 s | 2.96 / 3.00 / 3.04 s | 11 |
| cached `imported_names` call (1,000) | 0.418 / 0.414 ms | 0.998 / 1.037 ms | 11 |
| cached `truthwalk tree`, lowered path (400) | 0.859 / 0.812 ms | 4.415 / 4.706 ms | 11 |
| cached floor, path with 3 `.md` ancestors (`src/aN.md/b.md/c.md/x.txt`) | 2.035 / 2.082 ms/path | 9.249 / 8.705 ms/path | 11 |
| cached floor, path with 3 plain ancestors (`src/aN/b/c/x.txt`) | 1.040 / 1.048 ms/path | 8.497 / 8.374 ms/path | 11 |
| failed walk (budget: `IMPORT_OUT_MAX=1000`), floor per path | 1.555 / 1.606 ms | 4.314 / 4.336 ms | 11 |
| failed walk (readers refusal), floor per path | 2.046 / 2.028 ms | 3.309 / 3.217 ms | 11 |
| `walk_why` inside `$(...)` | 0.608 / 0.565 ms | (absent) | 11 |

Both walks still give a list of 80,855 bytes and 1,811 lines, the same as main's lib.

**Asked items, answered.**

- **readers_root per call.** On a memo hit it is string work, not a fork. It takes 0.029 ms. An xtrace of one call (`PS4` showing `$BASH_SUBSHELL`) prints 41 lines, none at subshell depth above 0, and no `++` lines. import_home's hit is a key compare (`:1088-1090`), and import_readers_key builds strings only.
- **Cached floor and cached main_imports.** Their xtraces show no subshell (3,872 and 1,986 lines, none above depth 0; the counts are high because the trace expands the 80 KB list). This confirms "a call both caches answer forks nothing" when `$4` is passed.
- **prompt_marks after B1.** Each walk here makes 9 live calls. 3 have the same real path and return early. 6 have a different real path that lies outside every root: the `~/.claude/skills` links into `/opt`. **0 are marked, and 0 names are re-queued, against 109 per walk in iteration 1.** The main walk's time now matches main's lib to within noise (2.99-3.05 s against 2.96-3.04 s). The extra cost iteration 1 measured (3.16-3.38 s against 2.95-3.19 s) is gone. The B1 loop over `IMPORT_ROOTS` runs only for those 6 entries and forks nothing. The 9 `realpath -e` forks per walk (iteration-1 Finding 5) remain. They cost about 5 ms in a 3 s walk, and I do not re-file them.
- **walk_why's subshell on failed walks.** It costs 0.57-0.61 ms per path, and only once the walk has failed. Finding 3 covers it.
- **The .md ancestor rule.** It adds one `walk_has` per ancestor whose name ends in `.md`. Over this list that is about 0.33 ms per ancestor. Finding 1 covers it.

## Findings

#### 1. The .md ancestor rule runs one walk-list glob per `.md`-named ancestor (row 470/611's linear cost, multiplied by depth)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1947-1948` (floor), `:1844-1847` (walk_has)
**Move:** Count the hidden multiplications / Ask "what's the size of N?"
**Classification:** Macro (O(list bytes) per `.md` ancestor) / Hot path (per changed path), but it is reached only by paths that have a directory whose name ends in `.md`
**Confidence:** High (measured)
**Baseline:** 2.035-2.082 ms/path with 3 `.md` ancestors, against 1.040-1.048 ms/path with 3 plain ancestors, on an 80,855-byte list with 11 worktrees (perff-probe-real.sh, 2026-10-10). That is about 0.33 ms per `.md` ancestor, the same as one membership glob (iteration 1: 0.330 ms at 80 KB, 18.5 ms at 4 MB).
**Legibility-target:** floor maintainer; whoever revisits rows 470/611 (rubric A10)

Evidence (`:1947-1948`; floor's else arm ends with `return 1` at `:1950`, read):
```bash
    d="$lp"; while [[ "$d" == */* ]]; do
      d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY="a path below the name of an instruction or prompt file, or of a .md file one imports with @"; return 0; }
```
The `*.md` test short-circuits, so a path with no `.md` directory pays no glob here, and that is every real path in this repository. A crafted path such as `a.md/b.md/.../x` pays one glob per component. Near IMPORT_OUT_MAX, at the 18.5 ms per glob iteration 1 measured, a depth-10 path would cost about 0.19 s. This is the cost A10 deferred, now multiplied by depth, and the brief author controls that depth. It is not a regression: main's lib is slower on these paths (8.7-9.2 ms).

**Recommendation:** No change for this unit. When rows 470/611's trigger fires (a list past about 500 KB), the associative set fixes this loop too. Name the loop in that row so the fix covers both call sites.

#### 2. A floor caller that omits `$4` pays 1.8 ms per path for lower's pipeline

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1928` (floor); contract item 8 (header, `:65-70`)
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (one `printf | tr` pipeline per call) / Hot path (per changed path) for any future per-path caller
**Confidence:** High (measured)
**Baseline:** cached floor with no `$4` costs 2.859-2.867 ms/path, against 1.017-1.029 ms/path with it. That is 400 paths at depth 6 with 11 worktrees (perff-probe-real.sh).
**Legibility-target:** U3 author, or anyone adding a floor caller (fact-check escalation, Performance)

Evidence (`:1928`):
```bash
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
```
build-loop.sh passes the lowered path (`:671`), so the gate pays nothing. A caller that omits `$4` gets nearly three times the cached cost. That is still below main's lib, which forked lower every time (8.6-11.7 ms/path here). Contract item 8 says floor lowers first unless its caller passes the lowered path. It does not say that a per-path loop should lower in one batch (`lower_all`) and pass `$4`.

**Recommendation:** When U3 adds a floor caller, have it batch-lower as check_line does. Optionally, add a clause to contract item 5 or 8: "a caller that asks about many paths lowers them with lower_all and passes each as `$4`".

#### 3. After a failed walk, every floor call forks walk_why's subshell, and a readers refusal also forks need_root per path

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1943` (floor), `:833` (readers_root)
**Move:** Count the hidden multiplications
**Classification:** Micro (1 or 2 forks per path) / Hot loop, but only in a decision whose walk already failed and whose every path is refused
**Confidence:** High (measured)
**Baseline:** 1.555-1.606 ms/path after a budget failure and 2.028-2.046 ms/path after a readers refusal, against main's 4.31-4.34 and 3.22-3.31 ms/path. `walk_why` in `$(...)` costs 0.565-0.608 ms (perff-probe-fail.sh, 11 worktrees).
**Legibility-target:** floor's doc reader

Evidence (`:1943`, and readers_root at `:833`, both read whole):
```bash
    if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"
```
```bash
readers_root() { { [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root; }
```
After a refusal, IMPORT_ROOTS is empty, so readers_root falls through to need_root, which forks `pwd -P`, on every path. This is B3's intended check. The sentence is the same for every path in a decision. floor's doc already states the walk_why part (B4). The need_root part on a readers refusal is not stated: the doc's "a call both of main_imports' caches answer" excludes it only by implication. Both costs are below main's, and they arise only on a decision that refuses every path anyway.

**Recommendation:** None needed. If it ever matters, memoize the walk sentence per `IMPORTED_MAIN_WHY` value. No doc change is required.

#### 4. A cached walk call builds import_readers' key twice

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:833` (readers_root), `:1151-1152` (import_readers), called at `:1626` and `:1702`
**Move:** Count the hidden multiplications
**Classification:** Micro (string work, no fork) / Hot (per path, through floor → truthwalk → main_imports)
**Confidence:** High (measured)
**Baseline:** 0.018-0.019 ms per `import_home` + `import_readers_key` pair, out of a 1.02-1.03 ms cached floor (perff-probe-real.sh, 11 worktrees). That is under 2% of the per-path cost.
**Legibility-target:** performance critic (asked item)

Evidence: readers_root (quoted in Finding 3) runs `import_home && import_readers_key`. Then each walk calls import_readers, whose first lines repeat both:
```bash
  import_home || return 1
  import_readers_key
```
Neither call forks on a hit. An xtrace of readers_root shows 0 subshell lines. This is the price of B3's check that the memo holds a result before skipping need_root, and it is negligible.

**Recommendation:** None.

## Endorsements

- At 8786f8fc, `--check` over a 400-path fixture with 1 worktree takes 0.70-0.71 s, against 2.84-2.91 s on main's lib (3 interleaved pairs). Cached floor over this repository with 11 worktrees takes 1.02-1.03 ms/path, against 11.3-14.6 ms/path on main. The per-path goal holds on the final code. [unverified — submitted as claim]
- After the B1 fix, prompt_marks marks 0 of the 9 live entries per walk over this repository, and re-queues 0 names (iteration 1: 109). The main walk's time matches main's lib (2.99-3.05 s against 2.96-3.04 s, 11 worktrees). [unverified — submitted as claim]
- readers_root on a memo hit forks nothing: 0.029 ms per call, with no xtrace line at `$BASH_SUBSHELL` above 0. A cached floor call with `$4` likewise shows no subshell in its xtrace. [unverified — submitted as claim]
- A1's need_root move made the tree walk's cached call fork-free too. Cached `imported_names` takes 0.41-0.42 ms, against 1.00-1.04 ms on main, and cached `truthwalk tree` takes 0.81-0.86 ms, against 4.4-4.7 ms. This resolves iteration-1 Finding 4. [unverified — submitted as claim]
- The new failure-reason path costs less than main's lib on every measured failure (budget: 1.56-1.61 against 4.31-4.34 ms/path; readers: 2.03-2.05 against 3.22-3.31 ms/path). [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The .md ancestor rule adds one walk-list glob per `.md`-named ancestor (about 0.33 ms each at 80 KB; scales with A10's deferral) | Informational | `dev-cycle-read.sh:1947-1948` | High |
| 2 | A floor caller that omits `$4` pays 1.8 ms/path for lower (future U3 caller) | Informational | `dev-cycle-read.sh:1928` | High |
| 3 | After a failed walk: walk_why subshell per path, plus need_root per path on a readers refusal | Informational | `dev-cycle-read.sh:1943`, `:833` | High |
| 4 | A cached walk call builds import_readers' key twice (0.018 ms, string only) | Informational | `dev-cycle-read.sh:833`, `:1151-1152` | High |

Settled and not re-filed: the walk-list glob's linear cost (A10, rows 470/611), and prompt_marks' extra realpath (9 forks per walk, about 5 ms; folded into A9).

## Overall Assessment

The final code keeps the unit's performance gains and adds no regression against main on any path measured. `--check` over 400 fixture paths is about 4x faster. Cached floor over this repository is 11-14x faster, the tree walk's cached call is about 2.5x faster, and failed-walk paths are faster too. The B1 fix removed the only per-walk cost iteration 1 found (109 re-reads). The walk now times the same as main's. All four findings are Informational. Two are costs that only a crafted path or a decision already refusing everything can reach (Findings 1 and 3). One is guidance for the next floor caller (Finding 2). One is a negligible string duplicate (Finding 4). Nothing here needs profiling beyond what was run, and nothing gates the merge.

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop. This pass re-measured every item the brief named on the final commit 8786f8fc, with the worktree count recorded for each timing (11 for this repository, 1 for the fixture):

- floor's per-path cost through `build-loop.sh --check`
- readers_root, which is string work and not a fork
- prompt_marks after B1: 0 entries marked here, and no walk-time difference against main
- walk_why's failed-walk subshell
- the .md ancestor rule

The review found no regression and no new finding above Informational, so performance raises no blocker to the merge. One gap is unchanged from iteration 1: `--check` was not timed end to end against this repository itself, because that needs a self-merge brief committed on main. The real-repository numbers are lib-level per-path and per-walk timings.
