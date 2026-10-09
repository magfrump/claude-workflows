Commit: f7a96eed

# Performance Review: feat/build-loop-u2b3b2a (U2b3b2a, iteration 2)

**Scope:** fix range `55490d15..HEAD` (18fba03d, f7a96eed; 261ecd96 is context): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2a-i2/shared.md`; Stage-1 fact-check `docs/reviews/code-fact-check-report-build-loop-u2b3b2a-i2.md` (summary: 30 claims, 27 Verified, 2 Mostly accurate, 1 Incorrect); iteration-1 report `performance-review-2026-10-09-u2b3b2a.md` and its override rows (G10, G12-G15), not re-raised.

## Data Flow and Hot Paths

The walks run once per gate decision, which is a **cold path** that the gate blocks on (see the iteration-1 report). The fix range changes four things that matter for performance:

1. **import_outside's real-path read.** `r="$(realpath -e -- "$1")"` becomes `nul_list rl realpath -ez -- "$1"` plus a one-record, no-newline check. This runs once per outside file a walk reads.
2. **outside_ok.** The inline `[[ -f "$p" && -r "$p" ]]` in both walks' `//` arms moves into a function. It runs once per `//` line that is not already seen (main walk) or once per `//` line (tree walk).
3. **DIRS forwarded to import_outside** (`import_file`: `import_outside "$1" "${@:3}"`). Each further directory would multiply the parser's prefix output.
4. **The rename, and IMPORT_DOTNEST's stripped trailing newline.** These have no runtime cost.

Measurements were taken on this host on 2026-10-09. Probes are in `u2b3b2a-i2/performance/`: `rp.sh` for the realpath capture and `ok.sh` for outside_ok. Each probe ran under `timeout` with a mktemp fixture, and no load generators were used.

| Probe | Old form | New form |
|---|---|---|
| Real path of a symlink, 500 calls (rp.sh) | `$(realpath -e)`: 0.316 s | `nul_list … realpath -ez`: 0.416 s (about 0.2 ms more per call) |
| Admission test on missing paths, 50,904 calls (ok.sh; iteration 1's worst `//` fixture count) | inline `[[ -f && -r ]]`: 0.142 s | `outside_ok`: 0.213 s (about 1.4 µs more per call) |

## Findings

#### F1. outside_ok's function call adds about 1.4 µs per `//` line, about 0.07 s on the heaviest iteration-1 fixture

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1152` (definition), `:1272` (tree walk arm), `:1380` (main walk arm)
**Move:** Count the hidden multiplications
**Classification:** Micro (one bash function call, no fork) / Cold path
**Confidence:** High (executed)
**Baseline:** measured on 2026-10-09 (ok.sh). 50,904 admission tests took 0.142 s inline and 0.213 s through `outside_ok`. Iteration 1 measured the 2,000-line absolute fixture that prints 50,904 `//` lines at 1.0-1.06 s per walk.

Evidence (verbatim):
```
      [[ "$p" != //* ]] || { p="${p#/}"; outside_ok "$p" && [[ "$seen" != *$'\n'"$p"$'\n'* ]] && seen+="$p"$'\n' && queue+=("$p"); continue; }
```
(This excerpt is one line of imported_names' read loop, which continues to `:1275`. The loop and main_imports' twin at `:1380` were both read.) The arms keep 55490d15's order, which the fact-check verified by execution. The tree walk still stats before it checks `seen`. The main walk checks `seen` first. So the only added cost is the call itself, about 7% on a fixture that real repos do not produce: /workspace prints 0 `//` lines. This is a reasonable price for having one admission rule (G1).

**Recommendation:** None.
**Legibility-target:** none needed (outside_ok's header names it as the one rule).

#### F2. import_outside's NUL-delimited real-path read adds about 0.2 ms per outside file

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1138-1139`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (process substitution plus mapfile in place of a command substitution; the same single realpath fork) / Cold path
**Confidence:** High (executed)
**Baseline:** measured on 2026-10-09 (rp.sh). 500 calls took 0.316 s in the old form and 0.416 s in the new form. Iteration 1 measured a 20-file outside chain at 0.21-0.23 s per walk, so the new form adds about 4 ms (under 2%) to that walk.

Evidence (verbatim):
```
  nul_list rl realpath -ez -- "$1" && [[ ${#rl[@]} -eq 1 && "${rl[0]}" != *$'\n'* ]] || return 1
  r="${rl[0]}"
```
(The excerpt ends at `:1139`. The enclosing import_outside continues to `:1143` and was read, as was nul_list at `:1175`.) The added cost is the `printf rc=` sentinel and the mapfile over a process substitution, not another external fork. rp.sh also confirmed that `realpath -ez` prints exactly one record for one operand, including for a name that ends in a newline (count 1, newline kept), so the newline refusal fires there too.

**Recommendation:** None. The cost buys the A2 correctness fix.
**Legibility-target:** none needed.

No performance finding comes from the DIRS forwarding (A4). In both walks `xs` is non-empty only for a file with a `pdir` entry, and `prompt_dir` writes `pdir` only for start files (`:1257`, `:1329`). An outside file never has one, so every walk call of import_outside passes zero further directories, and its output volume is unchanged from 55490d15. Only a direct caller of import_file pays the per-directory multiplier, such as the new bats test or U2b3b2b's seeds if they pass DIRS. That cost is the same one repo files already pay per prompt base.

## Endorsements (evidence-gated)

- The rewritten `//` arms keep 55490d15's order: main walk `seen` before the stat, tree walk the stat before `seen`. So the fix adds no stats per `//` line. `[fact-check: rewritten // arms keep 55490d15's order — Verified (executed)]`
- Within a walk, import_outside never receives further directories, because `pdir` is keyed only on start files. `[read: scripts/lib/dev-cycle-read.sh:657, :1257, :1262, :1329, :1338, :1148]`
- IMPORT_DOTNEST without its trailing newline still parses, and the table is still built once per reader set. `[fact-check: IMPORT_DOTNEST without a trailing newline still parses — Verified (executed)]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | outside_ok call adds about 1.4 µs per `//` line (about 0.07 s at 50,904 lines) | Informational | `dev-cycle-read.sh:1152,1272,1380` | High |
| 2 | NUL-delimited realpath read adds about 0.2 ms per outside file | Informational | `dev-cycle-read.sh:1138-1139` | High |

## Overall Assessment

The fix range changes nothing about performance. The two measured costs are per-call constants of microseconds and sub-milliseconds on a cold path. They are invisible on the real repository and under 10% on synthetic worst cases. The DIRS forwarding does not reach any walk. Iteration 1's Low findings (F1 large outside file, F2 long absolute token, F4 FIFO stall) are now named in the walk header's exception list, as their override rows say. Their substance did not change, so they are not re-raised. No profiling is needed.

## Goal-Alignment Note

The goal is to land U2b3b2a through its review-fix loop. On performance, the fixes (A1, A2, A4, G1-G8) add no cost that would change a merge decision, and they leave the iteration-1 posture intact: the walks run once per decision, fail closed on the budget, and build the dotnest table once. Nothing here blocks the merge. U2b3b2b's brief should note that it pays the per-directory output multiplier if its seeds call import_file with DIRS.
