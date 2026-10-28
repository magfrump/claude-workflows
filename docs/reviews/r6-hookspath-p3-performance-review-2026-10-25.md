Commit: 28dfcd3b

# Performance Review — fix/exit-scan-r6-hookspath (R6 pass 3, final confirming pass)

**Scope:** `git diff d40e4bae..28dfcd3b`. The code that matters for performance is in `devcontainer-config/cc-exit-scan.sh`: `_snap_cfg_hooks`, `_snap_cfg_hooks_file`, `_snap_entry_hooks` and the call in `git_exec_snapshot`. The cost claims checked are the "A slow scan" bullet in `guides/cc-isolated-usage.md` and the cost numbers in section 5 of the research doc.
**Date:** 2026-10-25
**Based on:** `docs/reviews/r6-hookspath-p3-code-fact-check-report-r3.md` (Claims 7, 9, 23, 34a, 34b) and r1 (Claims 10, 27, 28), plus `docs/reviews/r6-hookspath-p2-performance-review-2026-10-25.md` (pass-2 baselines).

## Data Flow and Hot Paths

`git_exec_snapshot` runs once at launch and once at exit, and the exit run blocks the return to the shell. The path is cold in call frequency, but the session writes its input. As in pass 2, this review treats it as a cold path that runs over large, adversarial data.

For each `.git` entry the working-tree `find` returns, the change does the following. It calls `_snap_entry_hooks` (`:910`). That runs `gitdir_common` in a command substitution, then calls `_snap_cfg_hooks` on `<common>/config` and on `<gitdir>/config.worktree`. Each of those calls forks `realpath` before it checks the cache (`:659`). A cache miss builds the closure: for each file, one `git config` fork. For each include line, three substitutions plus a `realpath` (`:690`, `:692`). For each value, a linear duplicate scan (`:687`). The entry then calls `_snap_hooks "$(_snap_path …)"` once per cached value (`:718`).

Sizes: N `.git` entries, M include files, E include lines, V `core.hooksPath` values in one closure. The session controls all four.

**Measurement setup.** The harness copies d40e4bae, e1d7d912 (pass 2's HEAD) and 28dfcd3b of `cc-exit-scan.sh`/`cc-gitdir.sh` and runs them on the same freshly built tree. It is a copy of pass 2's `probe.sh`, plus `probe3.sh`/`probe3v.sh` with extra scenarios. Conditions: `GIT_CONFIG_NOSYSTEM=1`, an empty `GIT_CONFIG_GLOBAL`, `LC_ALL` unset, git 2.39.5, bash 5.2, 16-core WSL2, load average 0.2-1.5. Rows marked "shim" count git calls and add about 1 ms per call. Plain-entry rows ran 3 times; the others ran once (k=1), so treat those as indicative. Scratch dir: `/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/perf-p3/` (`run1.txt`-`run3.txt`).

| Scenario (pass-2 set first) | d40e4bae | e1d7d912 (pass 2) | 28dfcd3b |
|---|---|---|---|
| 100 entries × 100 includes (shim) | 2.09 s, 202 git | 52.32 s, 10302 git | **2.74 s, 303 git** |
| 100 entries × 100 lines naming one include (shim) | 1.95 s, 103 git | 23.02 s | **2.25 s, 105 git** |
| 100 plain embedded repos (no shim, 3 runs) | 2.24 / 2.33 / 2.36 s | 2.44 / 2.50 s | 2.66 / 2.78 / 2.85 s |
| 200 plain embedded repos (no shim, 3 runs) | 4.56 / 4.59 / 4.47 s | — | 5.44 / 5.40 / 5.55 s |
| 100 linked worktrees, `git worktree add` (no shim, 3 runs) | 2.22 / 2.25 / 2.25 s | — | 2.66 / 1.36* / 2.64 s |
| 100 entries × 100 hooksPath values (no shim) | 1.27 / 1.26 s | 7.02 / 5.84 s | 11.26 / 10.32 / 11.29 / 11.07 s |
| 1 entry × 1000 distinct values in one config | 1.61 s | — | 4.50 s |
| 1 entry × 3000 distinct values | 5.33 s | 7.12 s | 24.00 / 23.67 s |
| 1 entry × 10000 distinct values | 21.68 s | — | **210.54 s** |
| 1 entry × 1000 include lines naming one file (shim) | 7.11 s | — | 9.61 s |
| 1 entry × 1000 include files (shim) | 8.97 s | — | 14.81 s |
| 100 embedded repos, each including the same 100 files | 73.94 s | — | 112.84 s |
| 100 embedded repos, each with 100 include lines naming one file | 75.13 s | — | 99.17 s |

\* One outlier, with identical output (311 lines). The 50-worktree runs gave the same kind of outlier on d40e4bae (0.10 s). The medians are used throughout.

The per-entry slope for plain entries is about 22.8-23.3 ms on d40e4bae and 26.6-27.8 ms on 28dfcd3b, so about +4.5 ms (+19%).

## Findings

#### Duplicate-value check in `_snap_cfg_hooks_file` is quadratic in the values of one config closure

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:686-688`
**Move:** Check the asymptotic behavior; ask "what's the size of N?"
**Classification:** Macro (O(V²) builtin comparisons where d40e4bae was O(V)) / Cold path that runs over adversarial data and blocks session exit. Escalated from Low under the hot-path gate, the same calibration as pass-2 M1.
**Confidence:** High
**Legibility-target:** maintainer
**Baseline:** 210.54 s per snapshot against 21.68 s on d40e4bae, for one entry whose config holds 10000 distinct relative `core.hooksPath` values (about 200 KB, one file). Harness above, 2026-10-25, k=1. The duplicate loop alone, run in isolation in bash 5.2: 1.46 s at V=1000, 12.73 s at V=3000, 140.13 s at V=10000. That is about 2.8 µs per comparison.

Evidence:

```
devcontainer-config/cc-exit-scan.sh:686-688
      core.hookspath)
        for ((k = _snap_rhs; k < ${#_snap_rhv[@]}; k++)); do [ "${_snap_rhv[k]}" != "$val" ] || continue 2; done
        _snap_rhv+=("$val") ;;
```

Each new value is compared with every value already collected for this closure. Distinct values cost V²/2 comparisons. The loop runs once per closure: the cache bounds it per config, not per entry. Its timings match the scan's growth. From 1000 to 3000 values the scan's added cost grows 6.4× (+2.9 s to +18.7 s), and from 3000 to 10000 it grows 10.1× (to +189 s), which approaches the 11.1× of pure V² scaling. Pass 2 (e1d7d912) had no duplicate check and took 7.12 s at V=3000, against 23.7 s now. Writing one config file is enough to trigger this, and the session can write the checkout's configs. The result is availability only: Ctrl-C exits 4 ("unscanned") and never gives a false clean. Realistic configs hold 0-1 values, so a normal session pays nothing.

**Recommendation:** Key the duplicate check on an associative array local to the closure build, declared beside `_snap_rhseen` in `_snap_cfg_hooks` (for example `local -A _snap_rhdup=()`, then `[ -z "${_snap_rhdup["$val"]:-}" ] || continue; _snap_rhdup["$val"]=1`). Bash 5.2 rejects an empty associative-array subscript, so this relies on `:684` having already skipped empty values. The check becomes O(1), and the cached slice stays the same.

#### Per-(entry, value) `_snap_path` substitution doubles pass 2's N × V cost, and absolute values are re-walked per entry

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:717-719`
**Move:** Count the hidden multiplications; find the work that moved to the wrong place
**Classification:** Micro (one extra subshell per pair) on top of a known Macro O(N×V) term (pass-2 L1, kept) / Cold path over adversarial data
**Confidence:** High
**Legibility-target:** maintainer, reviewer (research doc section 5)
**Baseline:** 100 entries × 100 values: 28dfcd3b 10.32-11.29 s (4 runs) against e1d7d912 5.84 / 7.02 s and d40e4bae 1.26 s (no shim, 2026-10-25). That is about 0.98 ms per pair now, against about 0.47 ms in pass 2.

Evidence:

```
devcontainer-config/cc-exit-scan.sh:717-719
    for ((k = _snap_rhs; k < _snap_rhs + _snap_rhn; k++)); do
      _snap_hooks "$(_snap_path "${_snap_rhv[k]}" "$wt")" || return 1
    done
```

e1d7d912 passed `"$wt/$val"` straight to `_snap_hooks`. 28dfcd3b runs `_snap_path`, a function that only does a `case` and a `printf`, inside a command substitution, which forks a subshell for every (entry, value) pair. That fork is most of the doubling. The change also makes the loop walk absolute and `~/` values once per entry, although they name the same directory for every tree. Only the first walk can recurse, because `_snap_hooks` dedups on `h:<real>` for an existing directory. The `F hooksdir` record is still appended each time and later collapsed by `sort -u`. The pass-2 L1 finding was accepted on the 5.99 s figure, and this commit doubled it without saying so. The research doc lists "11.3 s vs 1.3 s" under "Pass 2 performance L1". That is a 28dfcd3b figure, as fact-check r1 Claim 27 and r3 Claim 34a also note.

**Recommendation:** Resolve the value without forking. Inline the `case` in the loop, or have `_snap_path` set a variable instead of printing. Consider walking absolute and `~/` values once, when the cache entry is filled, rather than once per entry. In the research doc, relabel 11.3 s as a 28dfcd3b re-measure (pass 2 measured 6.0 s on e1d7d912).

#### Include files shared between distinct top-level configs are re-read once per config

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:657-667`, `:689-692`
**Move:** Question the cache (key granularity)
**Classification:** Micro (a constant-factor add to an N×M product d40e4bae already had) / Cold path over adversarial data
**Confidence:** High
**Legibility-target:** maintainer
**Baseline:** 100 embedded repos, each including the same 100 files: 112.84 s against 73.94 s on d40e4bae (no shim, k=1). Each with 100 include lines naming one file: 99.17 s against 75.13 s.

Evidence:

```
devcontainer-config/cc-exit-scan.sh:660-663
  if [ -z "${_snap_rhc["$real"]:-}" ]; then
    local -A _snap_rhseen=()
    _snap_rhs=${#_snap_rhv[@]}
    _snap_cfg_hooks_file "$1" "$real" || return 1
```

The cache is keyed on the top-level config, and `_snap_rhseen` is reset for each fill. An include reached from K distinct configs is therefore parsed K times (fact-check r3 Claim 7, Scope). This does not create a new product: d40e4bae already paid about 7.4 ms per (repo, include) pair on this path, and the new walk adds about 3.9 ms on top (+53%). On a cache hit, the `realpath` at `:659` and at `:692` (per include line) still forks before the lookup.

**Recommendation:** None required for this PR. If the exit scan's include cost is ever addressed as a whole, memoize per file (each file's own values plus its include targets), and do so together with the older path.

#### Guide and research-doc cost figures: they hold, apart from one label

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:439-441`; `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:148-149, 155-161`
**Move:** Find the work that moved to the wrong place (a per-entry step added)
**Classification:** Micro (about 4.5 ms per entry: `gitdir_common` substitution, two `realpath` forks, one `git config` per distinct config) / Cold path
**Confidence:** Medium (3 runs per plain configuration)
**Legibility-target:** user, reviewer
**Baseline:** 26.6-27.8 ms per embedded repository and about 26.5 ms per linked worktree at 28dfcd3b, against 22.8-23.3 ms and about 22.5 ms at d40e4bae (no shim, 3 runs, 2026-10-25).

Evidence:

```
guides/cc-isolated-usage.md:440-441
  snapshot on a ~400k-file repository, and about 30 ms more for each embedded
  repository or linked worktree (the tree walk itself is ~0.05 s per 100k files), paid at launch
```

"About 30 ms more for each embedded repository or linked worktree" holds as a rounded absolute figure. I measured 27-28 ms; fact-check r3 Claim 23 measured 31-33 ms for linked worktrees with a hooksPath. The research doc's section 5 figures reproduce: 2.32→2.85 s against my 2.33→2.78 s (median), 2.06→2.71 s against 2.09→2.74 s, and 1.82→2.23 s against 1.95→2.25 s. Its "about 5 ms more per repo" matches my +4.5 ms. Two points are imprecise. First, "moves from about 29 ms to about 30 ms" reads as +1 ms, but the step is about +20% (fact-check r3 Claim 34b). Second, the "11.3 s vs 1.3 s" label in finding 2. The guide's per-entry figure describes plain entries only. A shared config's value count multiplies it (finding 2), and a large value list costs quadratically until finding 1 is fixed. "A slow scan" covers planted volume only in general terms.

**Recommendation:** In the research doc, write "+~5 ms per entry (~20%); the rounded 30 ms holds" and relabel the 11.3 s figure. The guide needs no change once finding 1 is fixed.

## Endorsements

- The cache removed the entries × includes product that pass-2 M1 measured. At 100 × 100 the scan now makes 303 git calls (d40e4bae's 202 plus one read for each of the 101 configs), against 10302 at e1d7d912, and takes 2.74 s against 52.32 s (measured). The 100 × 100 single-include-line case went from 23.02 s to 2.25 s. `[fact-check: r3 Claim 9 — verified]`
- The cached slice `(start, count)` stays valid because `_snap_rhv` is only appended to, and `_snap_cfg_hooks` is not re-entered while a fill is in progress. `[read: devcontainer-config/cc-exit-scan.sh:657-695]`
- Include-line forks (`dirname`, `_snap_path`, `realpath`) now cost O(E) once per closure, not once per entry. 1000 lines naming one file add 2.5 s at N=1 (about 2.5 ms per line), a linear add-on to d40e4bae's own 7.1 s. `[read: devcontainer-config/cc-exit-scan.sh:689-692]`
- No depth cap is needed for termination: `_snap_rhseen` marks each file before recursing, so an include cycle or diamond is read once per closure. The 2^10-path DAG took 0.45 s against 0.34 s on d40e4bae, with 44 git calls. `[read: devcontainer-config/cc-exit-scan.sh:672-674]`

## Summary Table

| # | Finding | Severity | Location | Confidence | Measured |
|---|---------|----------|----------|------------|----------|
| 1 | Quadratic duplicate-value check per closure | Medium | `cc-exit-scan.sh:686-688` | High | Yes (210.5 s vs 21.7 s at V=10000; loop alone 140 s) |
| 2 | `_snap_path` substitution per (entry, value) doubles N×V; absolute values re-walked per entry | Low | `cc-exit-scan.sh:717-719` | High | Yes (10.3-11.3 s vs 5.8-7.0 s at e1d7d912, 1.3 s at d40e4bae) |
| 3 | Shared includes re-read per top-level config; `realpath` forks before the cache lookup | Informational | `cc-exit-scan.sh:657-667, 689-692` | High | Yes (112.8 s vs 73.9 s, 100 repos × 100 shared includes) |
| 4 | Guide's 30 ms and section 5 figures hold; "29→30 ms" and the "11.3 s" label imprecise | Informational | `guides/cc-isolated-usage.md:439-441`; research doc `:148-149, 155-161` | Medium | Yes (27-28 ms per entry, +4.5 ms) |

## Overall Assessment

The cache did what pass 2 asked. The entries × includes product is gone: 52.3 s became 2.7 s at 100 × 100. Every pass-2 scenario is now within about 0.3-0.7 s of d40e4bae, except the kept N × V case. Realistic setups (a few agent worktrees, a husky config with 0-1 values and 0-1 includes) pay about 4.5 ms per `.git` entry, and the guide's "about 30 ms" figure stays true. The fix brought one new superlinear term: the duplicate check is O(V²) per config, so one large config file can stretch the exit scan by minutes (210 s against 22 s at 10000 values). It is a one-line fix in place, an associative array beside `_snap_rhseen`, and it does not touch coverage. The second regression is a constant factor: one subshell per (entry, value) pair doubled the accepted N × V cost. Both are availability costs only (Ctrl-C exits 4, never a false clean), so neither blocks on correctness. Finding 1 is worth fixing before merge because the fix is trivial. Finding 2 and the doc labels can land with it. No further profiling is needed.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/r6-hookspath-p3-performance-review-2026-10-25.md in the worktree, structured per the performance-reviewer skill, `Commit: 28dfcd3b` first line."
- **Answered:**
  - The cache removed the entries × includes product. The four pass-2 scenarios were re-measured against d40e4bae (table, Endorsement 1).
  - The duplicate-value check is quadratic, measured (finding 1).
  - Forks per include line are now O(E) once per closure (Endorsement 3). The per-pair `_snap_path` fork is finding 2, and the `realpath` before the cache lookup is part of finding 3.
  - The guide's "about 30 ms" figure holds, and the section 5 numbers reproduce apart from one label (finding 4).
- **Out of scope:** A14, R3's remote half, A16, a `core.worktree` elsewhere, and R4, per the shared brief. Coverage correctness belongs to the security and fact-check passes.
- **Escalate:** None. Finding 1 is an availability regression with a one-line fix. Whether it lands before merge is the loop's call.
