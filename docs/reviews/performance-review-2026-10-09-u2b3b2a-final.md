Commit: 82bb5281

# Performance Review: feat/build-loop-u2b3b2a (U2b3b2a, final confirming pass)

**Scope:** the whole branch, `git diff main...HEAD -- scripts test` (HEAD 82bb5281; code commits 55490d15, 18fba03d, f7a96eed, 82bb5281)
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2a-i3/shared.md`; Stage-1 fact-check summary `u2b3b2a-i3/factcheck-summary.md` (k=3 merged: 0 Incorrect, 1 Stale, 4 Mostly accurate, 1 Unverifiable); earlier reports `performance-review-2026-10-09-u2b3b2a.md` and `-i2.md` with their override rows (override-log.md rows 559, 561-564, 571-572). None of those is re-raised: their substance has not changed.

## Data Flow and Hot Paths

Both walks run once per gate decision, which is a **cold path** that the gate blocks on. Once a walk has run and its result is cached, `floor` calls `truthwalk main` → `isimported main` for each changed path of a self-merge. `--check-fix` calls `truthwalk tree` once per path it was asked about. Each of those calls makes one lookup over the cached list, `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`dev-cycle-read.sh:1405`). The lookup is linear in the size of the list. Comments are the only change commit 82bb5281 makes since iteration 2, so the runtime posture measured in i1 and i2 still holds. The real /workspace walks match main's in time and output, with 0 `//` lines.

What this pass looked at that the earlier passes did not: what happens after the walk, meaning the size of the cached lists and what each per-path lookup costs.

Probe: `u2b3b2a-i3/performance/glob.sh`, run once under `timeout 120` with LC_ALL=C. It is a pure-bash loop with no fixture repository and no load generator. It times a missing-path lookup (the worst case, a full scan) over a list of `//` lines like the ones i1's 2,000-line absolute fixture produced.

| List size | Per lookup (miss) |
|---|---|
| 1,000 lines, 48,781 B | 0.0002 s |
| 10,000 lines, 507,781 B | 0.0023 s |
| 50,000 lines, 2,627,781 B | 0.0136 s |

## Findings

#### F1. The walks' cached lists keep the second channel's `//` names, which no lookup can match, so every per-path floor lookup scans them

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1382` (main walk append), `:1275` (tree walk append), `:1405-1406` (isimported's lookup), `:737-738` (the comment that states it)
**Move:** Trace the memory lifecycle / count the hidden multiplications
**Classification:** Micro (linear dead weight per lookup, no complexity change) / Cold path (once per changed path per decision)
**Confidence:** High (executed for the lookup cost; the list contents are read from code and the comment)
**Baseline:** measured on 2026-10-09 (glob.sh, this host). A miss over a 2,627,781 B list of `//` lines costs 0.0136 s per lookup. At 10,000 lines (507,781 B) it costs 0.0023 s. i1 measured the heaviest honest-shaped absolute fixture at 50,904 `//` lines (1,854,151 B printed). /workspace prints 0 `//` lines.

Evidence (verbatim):
```
    i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      # Below no root: read from the file system in phase 2, as the checkout is.
      [[ "$p" != //* ]] || { p="${p#/}"; [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" && seen[$p]=1 && tq+=("$p"); continue; }
```
(The excerpt ends at `:1385`. The enclosing main_imports read loop continues past it and was read, as were imported_names' twin at `:1275-1281` and isimported at `:1400-1408`.) The comment at `:737-738` already says it: "The walks' lists (IMPORTED, IMPORTED_MAIN) also hold the second channel's lower-cased // names, which no repo path isimported asks for can match." Those bytes are dead weight. They also go through the `tr` in `lower` for each file. Every `isimported` call then scans them, because the leading-`*` glob is linear in the list. A floor over P changed paths costs about P × 0.0136 s at 2.6 MB, for example 1.4 s for 100 paths. On main, those names were dropped by the parser, so they cost nothing after the walk. This is parity in kind with relative names, which can also fill the list up to IMPORT_OUT_MAX. It is not a new complexity class, and IMPORT_OUT_MAX (4,000,000 B) still caps the list, so the worst case is about 20 ms per lookup. Correctness is unaffected, and so is the fail-closed direction.

**Recommendation:** None required. If a later unit's outside seeds (U2b3b2b) make `//` volume common, append only the non-`//` lines to IMPORTED/IMPORTED_MAIN. The read loop already branches on `//*`, so the filter can live there at no extra cost. The `:737-738` comment then becomes unnecessary. The `//` bytes must still be charged to `used`, so the IMPORT_OUT_MAX bound keeps its meaning.
**Legibility-target:** the walk-header comment at `:737-738`.

No other finding. I checked these areas and found nothing new:

- The `import_readers` call in `import_targets` (a memo hit inside walks).
- import_outside's second, IMPORT_WHOLE parser pass. This is the i1 F3 double parse, declined in row 563.
- The phase-2 `tq` path for outside files. Their relative names resolve against an absolute directory, so they come back on the second channel and never reach `main_checkout`.
- Self-import and symlink cycles. `seen` stops a self-import. For a symlink loop, `realpath -e` fails, and that fails the walk closed.
- The cost of the fact-check's two escalated security shapes (the newline-named outside file and the dangling link into another root). Both are skips, which cost less than reads.

## Endorsements (evidence-gated)

- Commit 82bb5281 changes only comments in `scripts/` relative to f7a96eed, so i2's measured costs (F1 1.4 µs per `//` line, F2 0.2 ms per outside file) still apply unchanged. `[read: git diff f7a96eed 82bb5281 -- scripts — every changed line is a comment]`
- Within a walk, the `import_readers` call in `import_targets` is a memo hit that forks nothing. On a hit, `import_home` returns on its key check, and `import_readers_key` does only parameter expansion. `[read: scripts/lib/dev-cycle-read.sh:992-998, :1039-1049]`
- An outside file's relative imports resolve against its absolute directory alone, without being joined under every reader root, so they add no R-fold output. `[read: scripts/lib/dev-cycle-read.sh:865]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `//` names stay in IMPORTED/IMPORTED_MAIN and are scanned by every isimported lookup (0.0136 s per lookup at 2.6 MB; 0 B on /workspace) | Informational | `dev-cycle-read.sh:1275,1382,1405` | High |

## Overall Assessment

The branch's performance posture is unchanged from iteration 2. On the real repository it is neutral, and every new cost is bounded by IMPORT_OUT_MAX and IMPORT_WORK_MAX and fails closed. The one new observation is after the walk: the second channel's unmatchable `//` names are stored in the cached lists. Each per-path floor lookup then pays a linear scan over them, about 14 ms at 2.6 MB of `//` lines, where /workspace has none. It is a one-line filter if U2b3b2b's seeds ever make it matter. Nothing here needs profiling or blocks the merge.

## Goal-Alignment Note

The goal is to land U2b3b2a through its review-fix loop, and this pass is the final confirmation. I found nothing that changes a merge decision. There is one Informational finding, measured, that costs nothing on /workspace. The earlier declined rows (559, 561-564, 571-572) still describe the branch accurately. U2b3b2b's brief could carry F1 next to i2's note on the per-directory multiplier, since its outside seeds are what would raise `//` volume.
