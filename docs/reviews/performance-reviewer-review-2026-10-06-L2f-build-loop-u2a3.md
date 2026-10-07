Commit: 1898d21c

# Performance Review — feat/build-loop-u2a3, loop 2 final confirming pass

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 1898d21c). This pass concentrates on what changed since loop 2 iteration 1 (5c57d367 to 1898d21c): the extra `git ls-files --cached` listing and its loop over each entry (`scripts/lib/dev-cycle-read.sh:561-563`), and the record-type arms (:597-598). It also prices the fix that the fact-check suggests for r3 Claim 13b.
**Date:** 2026-10-06
**Based on:** shared-L2, factcheck-summary-L2f (replicates `docs/reviews/code-fact-check-report-build-loop-u2a3-L2f-r1..r3.md`), the loop 2 iteration 1 performance review (`docs/reviews/performance-reviewer-review-2026-10-06-L2-build-loop-u2a3.md`) and the override-log rows 346, 355, 365, 377, 378, 384 and 386.

## Data Flow and Hot Paths

main_imports runs once per merge-gate check. It has no caller until U2a4, and its result is cached per `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`. **Path temperature: cold.** It runs once per merge and blocks no latency-sensitive operation.

Since iteration 1, dfeeb85d added three things:
- After `untracked_md`, a second listing: `git ls-files -z --cached -- ':(glob,icase)**/*.md'`.
- One loop over both lists. For each entry it does a newline test and one `ent` hash lookup, and it adds a `t:` candidate only when main lacks the entry.
- The record-type case now has a `160000) continue` arm and a failing `*)` arm. Neither arm reads anything.

Both listings are linear in the checkout's `.md` entries, and both are bounded by the tree-record parse that precedes them (row 365).

**How the measurements were taken.** All runs were on this host (WSL2), in scratch `/tmp/u2a3-perf2f-i2-tgW4`, under `LC_ALL=C`. `old` is the lib at 5c57d367 and `new` is the lib at 1898d21c, both extracted with `git show`. The harness sources the lib, runs `resolve_main`, sets ROOT_REAL and times `main_imports`. The probe scripts are `scratchpad/u2a3/perf2f-probe{,2,3}.sh`.
- **Fresh clone of this repo at main 62d366a7:** 2,994 records, 1,452 cached `.md` files, 0 symlink or gitlink records. Over 5 runs each, old took 397-411 ms and new took 415-463 ms.
- **Synthetic repo with 20,001 tracked `.md` files** (`d1..d200/e/f1..f100.md` plus CLAUDE.md): old took 1.298-1.351 s over 4 runs and new took 1.442-1.498 s.

## Findings

#### F1. The index listing adds a linear 4-11% to the walk; this is not a new cost class

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:561-563`
**Move:** Count the hidden multiplications / what's the size of N
**Classification:** Micro (one extra listing plus one hash lookup per cached `.md` entry) / Cold path (once per merge gate)
**Confidence:** High (measured)
**Baseline:** main_imports took 397-411 ms before this change (lib 5c57d367, fresh clone of this repo, 5 runs, this host, 2026-10-06).
**Evidence:** In the fresh clone, the segment probes measured 12 ms for `ls-files --cached` and 5 ms for the loop over 1,452 entries. End to end, new ran 415-463 ms against old's 397-411 ms. At 20,001 tracked `.md` files, the listing took 35 ms and the loop 48-49 ms, and end to end the change added ~150 ms (+11%). The ls-tree record parse in the same run took 1.01-1.05 s (row 365).
**Legibility-target:** rubric author (the row 365 revisit trigger)

The listing and its loop are O(cached `.md` entries), with one hash lookup per entry. A repo's cached `.md` entries are at most its tree records, so this cost always trails the per-record parse that row 365 already defers. Nothing is quadratic and nothing is held past the call: `recs` and `low` are locals, and `low` is overwritten by the `tr` pass.

**Recommendation:** No change. When row 365's trigger fires (U2c's --check over 1 s on 10k+ tracked entries), fold this listing into the same awk/one-pass rework. The synthetic 20k run is already over 1 s with or without this change.

#### F2. Price of the fact-check's suggested fix for r3 Claim 13b: a memoised ancestor walk costs ~20 ms here; the cheapest-looking sort pass is wrong

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:553-559` (the record loop, where the fix would follow) and :557 (the doubled-name check)
**Move:** Check the asymptotic behavior / count the hidden multiplications
**Classification:** Micro (one check pass after the parse) / Cold path (once per merge gate)
**Confidence:** High for the timings (measured). Medium that the sketched fix is complete (its fail-closed behaviour was probed only on a hand-built `ent` map, not through a non-canonical tree).
**Baseline:** The ls-tree record parse took 181-187 ms (fresh clone, 2,994 records, 3 runs, this host, 2026-10-06).
**Evidence:** Three candidate fixes ran over the full `ent` map, after the parse loop:

| Candidate | Fresh clone (2,994 records) | 20,001 records | Catches `l` + `l/x.md` with `l-a.md` between? |
|---|---|---|---|
| A: walk every record's ancestors with `${c%/*}`, lookups in `ent` | 40-41 ms (9,177 lookups) | 161-172 ms (40,000 lookups) | yes |
| A': A plus a visited-directory memo, `break` at the first directory already seen | 20-23 ms (368 lookups) | 94 ms (400 lookups) | yes (probe3: `fixA-memo HIT l`) |
| B: `printf | LC_ALL=C sort -z | awk`, comparing adjacent names | 6 ms | 22-24 ms | **no**: C order puts `-` (0x2d) before `/` (0x2f), so the sort gives `l l-a.md l/x.md` and the adjacent comparison misses the collision |

Neither A nor A' reported a hit on this repo's main or on the 20k repo, so neither refuses a real tree. `ls-tree -r` without `-t` lists no tree records, so any ancestor found in `ent` is a proper-prefix collision.
**Legibility-target:** author (security + author escalation on lib :557, override row :379)

Candidate A costs O(records × depth): about +10% on today's walk, and the same proportion at 20k. A' costs O(records + distinct directories), about +5%. Both are order-independent only if they run after the record loop. An inline check made while parsing misses the case where the tree comes first, which is the order r3 found failing open, unless it also scans forward. B is the cheapest but fails open on a sibling whose name sorts between the link and its subtree. A correct sort-based check would need a prefix stack, which makes it no simpler than A'.

**Recommendation:** If the fix lands, use A' as a separate pass after the loop at :553-559. A sketch: `for f in "${!ent[@]}"; do c="$f"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${memo[$c]+set}" ]] || break; memo[$c]=1; [[ -z "${ent[$c]+set}" ]] || return 1; done; done`. It needs `local -A memo=()`, and the pass must run before `IMPORTED_MAIN=$'\n'` so that the walk returns with IMPORTED_MAIN=error. Do not use the adjacency sort. Pin the fix with the non-canonical tree-first fixture from r3 13b plus a sibling such as `l-a.md`.

## Endorsements

- The new candidate loop costs one `[[ ]]` newline test and one `ent` associative lookup per listed entry, and forks nothing inside the loop. The one `tr` pass after it still lower-cases every candidate in a single fork. `[read: scripts/lib/dev-cycle-read.sh:561-565]`
- The `160000) continue` and `*)` arms leave the case before any `cat-file`, so a gitlink costs no blob read. `[read: scripts/lib/dev-cycle-read.sh:589-598]`
- Claim: on a clean checkout, the index listing never adds a `t:` candidate, because every cached `.md` file is also in main's tree. The fresh clone measured `cand 0` after the loop, which supports this, but no fact-check verdict covers it. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The index listing adds a linear 4-11% (+~35 ms here, +~150 ms at 20k `.md`) | Informational | `scripts/lib/dev-cycle-read.sh:561-563` | High |
| 2 | Price of the 13b fix: A' ~20 ms here / 94 ms at 20k; the sort-adjacency variant fails open | Informational | `scripts/lib/dev-cycle-read.sh:553-559` | High (timings) / Medium (completeness) |

## Overall Assessment

Since iteration 1, the change's performance has not regressed in class. The index listing is one linear pass, and it is dominated by the record parse that row 365 already defers. Its measured cost is +35 ms on this repo and +150 ms at 20k tracked `.md` files, on a cold path that runs once per merge. The fix the fact-check suggests is affordable. A memoised ancestor walk run as a separate pass costs ~20 ms here and ~94 ms at 20k, which is about 5% of the walk. The fork-light sort-and-compare variant must not be used, because it is wrong in C collation. No finding blocks a merge, and none needs more profiling. The 1 s revisit trigger in row 365 remains the right point to batch the record checks into one pass.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/performance-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md, structured per the performance-reviewer skill."
- **Answered:** The iteration-1-to-HEAD delta was measured end to end and by segment, on this repo and on a 20k-file synthetic repo (F1). The suggested fix for 13b was priced across three variants, and the cheapest variant was shown to fail open (F2). The settled rows (346, 355, 365, 377, 378, 384, 386) were not re-filed.
- **Out of scope:** Whether the tree/symlink doubled name is a security finding (security + author). The masked refusal tests (test-strategy). The wording items in the fact-check summary.
- **Escalate:** To the author and security, if the 13b fix lands: use the memoised ancestor pass, not a sort-adjacency check (F2).
