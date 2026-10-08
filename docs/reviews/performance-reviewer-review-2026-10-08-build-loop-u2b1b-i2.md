Commit: a382a3f8

# Performance Review — feat/build-loop-u2b1b (U2b1b, iteration 2)

**Scope:** `git diff 809df345..a382a3f8` (the iteration-1 fix commit): `scripts/build-loop.sh` (nrules, check_line), `scripts/lib/dev-cycle-read.sh` (comment only); lib helpers `nul_list`, `lower_all`, `truthrule`, `isstart`, `writable`, `pathform` read whole as callees
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check summary, iteration 2 (k=1, a382a3f8; full report `docs/reviews/code-fact-check-report-build-loop-u2b1b-i2.md`, 30 claims, 0 Incorrect); iteration-1 performance review F1 (`docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1b.md`)

All timings are mine, on this host (WSL2, 16 cores, bash 5.2.15, git 2.39.5, load average 0.5-0.9), with probes in `/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i2/perf/`: `probe1.sh N [EXT] [SCRIPT]` (iteration 1's fixture: one brief whose Status flips open→done plus N new files under `src/`, three runs each), a phase-timed scratch copy of the script (`variant/`, identical to a382a3f8 except `echo "T <phase> $EPOCHREALTIME" >&2` lines; `diff` against the original with those lines removed is empty), and `micro.sh` / `micro2.sh` (the lib's helpers looped over 5,000 / 200,000 synthetic paths).

## Data Flow and Hot Paths

`--check BRIEF...` runs once per merge attempt per brief: cold, but over data the branch alone bounds (the hot-path gate's "runs over large data" exception; in U3 it sits between `--expect`'s read and `--merge`'s CAS). After a382a3f8, `check_line` (`scripts/build-loop.sh:575-622`) does, per brief: one `diff-tree -z` into `$GATE_TMP/diff` (`:595`); one bash read loop that fills seven parallel arrays and collects new-file blob ids (`:599-603`); one `tr | wc` NUL count (`:605`); one `cat-file --batch-check` over every new regular file's id (`:609-612`); one `nul_list lps lower_all "${ps[@]}"` (`:614`, a single `tr` over all paths); then a per-path loop calling `nrules` (`:615-619`), which now calls `truthrule` (`:561`) instead of forking `lower`.

Re-measurement of iteration 1's F1 (same fixture; the 5,000-path run produces the same merged tree `fbbe1faa…` iteration 1 reported):

| N changed paths | iteration 1 as built (809df345) | iteration 1, `${6,,}` variant | a382a3f8 (3 runs) |
|---|---|---|---|
| 1 (+brief) | 201 ms | — | 107 / 109 / 117 ms |
| 1,000 | 2,453 ms | 324 ms | 371 / 371 / 372 ms |
| 5,000 | 13,460 ms | 1,163 ms | 1,326 / 1,346 / 1,369 ms |
| 5,000 (`.md` files) | — | — | 1,423 / 1,489 / 1,585 ms |
| 20,000 | — | — | 4,697 / 5,149 / 5,352 ms |

**F1 is fixed**: 6.6x faster at 1,000 paths and 10x at 5,000; cost is now linear at ≈0.25 ms per path (1,346 ms / 5,000; ≈5,070 ms mean / 20,000). The iteration-1 baselines were taken under different load (N=1 was 201 ms then, 109 ms now), so the gap to the iteration-1 `${6,,}` variant (≈+0.04 ms/path) is an upper bound on what the fix adds over that variant.

Phase split of one run (`variant/`, ms):

| phase | 5,000 paths | 20,000 paths |
|---|---|---|
| diff-tree (`:595`) | 5 | 18 |
| parse loop into parallel arrays (`:599-603`) | 223 | 912 |
| NUL count (`:605`) | 3 | 4 |
| cat-file --batch-check + grep (`:609-612`) | 109 (105, 114 on two reruns) | 42 |
| nul_list + lower_all (`:614`) | 18 | 74 |
| nrules loop (`:615-619`) | 924 | 3,748 |
| print rows (`:620-621`) | 6 | 39 |

Per-path cost of the parse loop (0.045 ms) and the nrules loop (0.185 ms) is the same at 5,000 and 20,000: linear, no quadratic array access. Helper costs over 5,000 paths in isolation (`micro.sh`, two runs): an empty 7-argument function call 15-25 ms, `pathform` 129-130 ms, the mode regex 71-73 ms, `isstart` 73-79 ms, `writable` 182-232 ms, whole `truthrule` 358-391 ms, `nul_list lower_all` 22-25 ms. `nul_list lower_all` over 200,000 paths of 45 bytes: rc 0, 200,000 entries, 1,792 ms, no argument-length failure (both are shell functions and `printf` is a builtin, so no exec carries the list).

## Findings

#### F1. `truthrule` is now the largest single piece of `nrules`: ≈0.07 ms per path, of which only the docs/ words are used

**Severity:** Informational
**Location:** `scripts/build-loop.sh:561` (in `nrules`, `:552-568`; called per path from `check_line`'s loop `:615-619`); callee `scripts/lib/dev-cycle-read.sh:1087-1098` (`truthrule`), `:529` (`isstart`), `:204-207` (`writable`)
**Move:** 1, Count the hidden multiplications
**Classification:** Micro (per-path regex work, linear in N, constant per call) / Cold path over large data (one CLI run per merge attempt)
**Confidence:** High (measured)
**Baseline:** `truthrule` looped over 5,000 lower-cased paths: 358 ms (391 ms on a rerun), of a measured 924 ms nrules loop and 1,346 ms whole `--check` at 5,000 paths (2026-10-08, `perf/micro.sh`, `perf/variant/`)
**Legibility-target:** implementer (optional prefilter) or the override log (a price per changed path)

Evidence (verbatim):

```
    truthrule "$7" || true  # $7 is lower-cased, so no word hides cycle, settings or user
    case "$TRUTH_WHY" in
      cycle|settings) DENY="one of the dev cycle's own files" ;;
      user) DENY="the user's constraints doc, which every loop prompt carries" ;;
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;
    esac
```
```
  if [[ "$1" == *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]]; then TRUTH_WHY="case"
  elif isstart "$1"; then TRUTH_WHY="instr"
  elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"
  elif writable "$1"; then TRUTH_WHY="cycle"
  elif [[ "$1" == docs/dev-cycle.md ]]; then TRUTH_WHY="settings"
  elif [[ "$1" == docs/constraints.md ]]; then TRUTH_WHY="user"
  elif [[ "$1" =~ ^docs/(decisions|human-author)/ ]]; then TRUTH_WHY="record"
  else return 1; fi
```

The excerpt from `:561-566` ends inside `nrules`, which continues to `:568` (`fi`, `}`); `TRUTH_WHY`'s only use is the `case` quoted. Iteration 1's nrules ran `writable` plus one regex per path; this one runs the whole chain, adding `isstart` (one `=~` on every path, a second for `.md` paths: the `.md` fixture costs ≈+0.02 ms/path) and the trailing tests. bash recompiles each `=~` pattern on every evaluation, so this is fixed regex work per path, not a scaling problem. On an honest branch every non-brief path that passes `pathform` and the mode rule reaches `:561`. The three words nrules acts on (cycle, settings, user) and the `*)` regex all require a `docs/` prefix, so for the typical bulk of a large change (generated output, vendored code outside `docs/`) the call buys nothing; at 5,000 paths that is roughly a quarter of the gate's time, 0.3 s, and ≈1.4 s at 20,000 (extrapolated, speculative at that size). Not worth a change on cost alone: the gate is advisory, linear, and 10x faster than iteration 1.

**Recommendation:** none required. If U3's CAS window ever needs it, guard the `else` branch with `[[ "$7" == docs/* ]]` (all four refusals it can produce need that prefix), at the price of nrules restating knowledge of truthrule's word set, which iteration 1's architecture finding 1 moved it away from; otherwise record ≈0.07 ms/path for `truthrule` beside the F1 row in the override log.

#### F2. The missing-blob check costs ≈0.02 ms per new file while objects are loose, tens of milliseconds per brief at thousands of files

**Severity:** Informational
**Location:** `scripts/build-loop.sh:609-612` (in `check_line`, `:575-622`); ids collected at `:602`
**Move:** 2, Ask "what's the size of N?"
**Classification:** Micro (one process, linear lookups) / Cold path (once per brief)
**Confidence:** Medium (the phase timings are measured; the loose-versus-packed cause of the 5,000 / 20,000 inversion is inferred, not checked)
**Baseline:** `cat-file --batch-check` phase, 5,000 new files: 109 ms (105, 114 ms on reruns); 20,000 new files: 42 ms (2026-10-08, `perf/variant/`)
**Legibility-target:** override log (a stated price beside the C1/F2 security fix)

Evidence (verbatim):

```
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a file the object store lacks"; return
  fi
```

The excerpt `:609-612` is followed by the lower pass `:614`; `out` is reused only here (its earlier value, `check_branch`'s line, was consumed at `:583-584`). It is one batch process per brief, not a process per id, so the shape is right. The 20,000-path run is cheaper than the 5,000-path one, most likely because committing 20,000 files in the fixture tripped `gc.auto` (6,700 loose objects) and packed them, while 5,000 stayed loose, one file open per lookup; a loop's repository between gcs looks like the loose case. Either way it is under a tenth of `--check`'s time at 5,000 paths.

**Recommendation:** keep it (it is the security fix, priced). If a price line is wanted, ≈0.1 s per 5,000 new loose files.

## Endorsements

- The per-path `lower` fork is gone: `check_line` lower-cases every path in one `nul_list lps lower_all "${ps[@]}"` call and passes `${lps[$i]}` to nrules as `$7`; `lower_all` is one `printf` builtin piped to one `tr`, and `nul_list` one `mapfile` over a process substitution. [read: scripts/build-loop.sh:614-617; scripts/lib/dev-cycle-read.sh:852, :857]
- `own_blob` still runs at most once per brief: its only call is in the branch taken when the path equals the brief (`[[ "$6" == "$1" ]]`), and the `&&` chain skips it when the status or modes already fail. [read: scripts/build-loop.sh:557-559]
- Claim: the parallel-array parse loop (`:599-603`, appends plus `${nms[-1]}` reads) is linear in records; measured 223 ms at 5,000 and 912 ms at 20,000 (0.045 ms/record both). [unverified — submitted as claim]
- Claim: `nul_list lower_all` takes 200,000 paths in one call without an argument-length failure and returns all of them; measured rc 0, 200,000 entries, 1,792 ms. [unverified — submitted as claim]
- Claim: a382a3f8 fixes iteration 1's F1 at the measured sizes: `--check` at 1,000 changed paths 371 ms (was 2,453 ms) and at 5,000 paths 1,346 ms (was 13,460 ms), same merged tree. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `truthrule` is ≈0.07 ms of nrules' ≈0.185 ms per path; only its docs/ words are used | Informational | `scripts/build-loop.sh:561` | High |
| 2 | Missing-blob batch-check ≈0.1 s per 5,000 loose new files | Informational | `scripts/build-loop.sh:609-612` | Medium |

## Overall Assessment

Iteration 1's F1 is fixed: `--check` at 5,000 changed paths drops from 13.5 s to 1.35 s, and cost is linear at ≈0.25 ms per path through 20,000 paths. None of the new per-brief work is a scaling problem. The missing-blob `cat-file --batch-check` is one process per brief. The seven parallel arrays and `nul_list`/`lower_all` are linear and need no exec. `truthrule` adds fixed regex work per path. Both findings are Informational price notes, not reds. The per-path bash work in nrules (≈0.185 ms) now dominates and is the floor for a bash implementation. Nothing here needs fixing before merge. If U3's CAS window turns out to need a tighter gate on very large branches, the `docs/*` prefilter (F1) is the one cheap lever.

## Goal-Alignment Note

The user's goal is to land U2b1b after a clean review-fix loop. This pass checked that the fix commit closes iteration 1's only performance item (F1, the per-path fork), measured at the two sizes iteration 1 used, and that the commit's new per-brief work (the missing-blob batch-check, parallel arrays, the one-pass lower, `truthrule` per path) adds no superlinear cost. It does neither, so this pass has no red and nothing to fix before merge. Both findings are price notes for the override log. R8 (the GATE_TMP race) is a security question with no performance side, so it is not addressed here.
