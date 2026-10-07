Commit: 0bb98f27

# Performance Review — feat/build-loop-u2a3, loop 2 iteration 3 (final confirming pass)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 0bb98f27). This pass concentrates on the two code changes since 1898d21c (99cce51b): the memoised ancestor pass (`scripts/lib/dev-cycle-read.sh:565`, with `dir` declared at :552) and the merged checkout listing (`git ls-files --cached --others`, :566-567).
**Date:** 2026-10-06
**Based on:** shared-L2, factcheck-summary-L3 (replicates `docs/reviews/code-fact-check-report-build-loop-u2a3-L3-r1..r3.md`), the iteration 2 performance review (`docs/reviews/performance-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md`) and override-log rows 365, 377, 378, 384, 386 and 394.

## Data Flow and Hot Paths

main_imports runs once per merge-gate check. It has no caller until U2a4, and its result is cached per `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`. **Path temperature: cold.** It runs once per merge and blocks no latency-sensitive operation.

99cce51b made two changes to the code:
- **Ancestor pass (:565).** It runs after the record loop and before `IMPORTED_MAIN=$'\n'` (:578), so a hit returns 1 while IMPORTED_MAIN is still `error`. For each key of `ent`, it walks the key's parent directories with `${c%/*}`. It stops at the first directory already in the local `dir` memo, and it returns 1 if a parent is itself a listed name. This is variant A' from the iteration 2 review (F2), placed where that review recommended.
- **Merged listing (:566-567).** One `ls-files -z --cached --others` call replaces the old pair (`untracked_md`, then `--cached`), and the copy `low=("${recs[@]}")` is gone. `untracked_md` is still used by `imported_names` (:528).

**How the measurements were taken.** All runs were on this host (WSL2), in scratch `/tmp/u2a3-perf3-i3-zTBI`, under `LC_ALL=C` with TMPDIR set to the scratch dir, using git 2.39.5. `old` is the lib at 1898d21c and `new` is the lib at 0bb98f27, both extracted with `git show`. The harness sources the lib, runs `resolve_main`, sets ROOT_REAL and times one `main_imports`. The segment probe copies the HEAD code for the pass and the listings. The scripts are `scratchpad/u2a3/perf3-i3-run.sh` and `perf3-i3-seg.sh`. Three repos were used:
- **clone:** a fresh clone of this repo at main 62d366a7. It has 2,966 records, 1,452 `.md` files and 368 distinct directories.
- **wide:** a synthetic repo with 20,001 tracked `.md` files (`d1..d200/e/f1..f100.md` plus CLAUDE.md), so 400 directories.
- **deep (adversarial):** a synthetic repo with 20,001 tracked `.md` files, each at the end of its own chain of 10 unique directories (`q{i}_0/.../q{i}_9/x.md`), so 200,000 distinct directories.

| Repo | old end to end (ms) | new end to end (ms) | ancestor pass alone | merged listing vs. the old pair |
|---|---|---|---|---|
| clone | 421-459 (5 runs) | 439-466 (5 runs) | 21-22 ms (3,312 lookups) | 14-15 ms vs 16 ms |
| wide | 1,660-4,922 (3 runs, noisy host) | 1,686-2,694 | 121 ms (20,200 lookups) | 44 ms vs 45 ms |
| deep | 3,006-3,519 (6 runs) | 4,373-4,645 (5 of 6 runs; one outlier at 6,925-7,176) | 1,395 ms (200,000 lookups) | 1,113 ms vs 1,242 ms |

Every walk returned rc=0, so neither pass refused a real or synthetic canonical tree.

## Findings

#### F1. The ancestor pass is linear in records plus main's distinct directories: noise on this repo, +~1.3 s on a 200k-directory adversarial tree

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:565`
**Move:** Check the asymptotic behavior / what's the size of N
**Classification:** Macro-shaped but bounded (one lookup per record plus one per distinct directory) / Cold path (once per merge gate)
**Confidence:** High (measured; the linearity holds across three repo shapes)
**Baseline:** main_imports took 421-459 ms before this change (lib 1898d21c, fresh clone of this repo, 5 runs, this host, 2026-10-06).
**Evidence:** The segment probe counted lookups equal to records plus distinct directories: 3,312 on the clone (2,966 + 368, less the root-level names), 20,200 on wide (20,001 + 400, less the root-level names) and 200,000 on deep. The cost per lookup was steady at ~6-7 µs: 21 ms, 121 ms and 1,395 ms. End to end, the clone did not move beyond run-to-run noise (old 421-459 ms, new 439-466 ms). Deep added ~1.3 s (old 3.0-3.5 s, new 4.4-4.6 s). The memo is what keeps this linear. Without the `break`, a pass over wide would cost records × depth, as variant A did in iteration 2 (40,000 lookups at 20k). A fact-check finding agrees: the `break` mutant is equivalent in result, so it changes cost only.
**Legibility-target:** rubric author (the row 365 revisit trigger)

The number of distinct directories cannot exceed the number of tree objects in main's commit. The pass therefore scales with the size of the tree that ls-tree has already listed and the record loop has already parsed at a higher cost per entry: row 365 prices that parse at ~2.1 s per 30k entries. The memo is a local associative array, freed when the call returns. On a realistic repo at 80k files and ~5k directories, the measured per-lookup rate implies ~0.5 s for this pass, against several seconds of record parse. This is an estimate, not a run. Only a pathological tree with one unique directory chain per file, such as deep, makes the pass comparable to the parse, and there the pass is still linear and fails nothing open.

**Recommendation:** No change. Fold this pass into the one-pass awk rework when row 365's trigger fires (U2c's --check over 1 s at 10k+ tracked entries). If that rework adds a prefix check in awk, it must not rely on sort adjacency, because C collation puts `-` before `/` (iteration 2 review, F2). If the rubric wants this pass on record, it can share row 365's Defer and trigger.

#### F2. On a deep tree, the merged listing's cost is the untracked-directory scan, not the merge itself

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:566`
**Move:** Find the work that moved to the wrong place / what's the size of N
**Classification:** Micro (one git process fewer) / Cold path (once per merge gate)
**Confidence:** High (measured)
**Baseline:** The old pair of listings took 1,242 ms on the deep repo (lib 1898d21c listings, 20,001 files in 200,000 directories, this host, 2026-10-06).
**Evidence:** On deep, the merged listing ran in 1,113 ms against 1,242 ms for the pair. Separate runs (3 each, `bash` `time`) took 24-26 ms for `ls-files --cached` with no pathspec, 28-30 ms for `--cached` with the icase glob, 809-827 ms for `--others` with the glob, and 773-838 ms for `--others` with no pathspec. The `--others` scan is git reading every directory of the checkout, and the `:(glob,icase)` pathspec adds nothing to it. That scan was already in `untracked_md` before this change. The merge saves one fork and the array copy, which comes to ~1-2 ms on the clone and on wide.
**Legibility-target:** rubric author (rows 377 and 394)

The merged listing returned the same number of names as the pair on all three repos: 1,452, 20,001 and 20,001. It costs no more than the pair, and the cost that scales is directory count in the checkout, which rows 377/394 already defer. This finding adds one data point to those rows: directory count drives `--others` (~0.8 s at 200k directories), separately from the `.md` count that row 377 measured.

**Recommendation:** No change in this unit. If row 377's revisit fires, note that the cost of `--others` scales with checkout directories as well as `.md` files. The rework would need `--directory`/pruning or a separate listing of ignored files, and a `grep -z` prefilter would not help.

## Endorsements

- The ancestor pass runs before `IMPORTED_MAIN=$'\n'`, so its `return 1` leaves IMPORTED_MAIN as `error`, and it forks nothing per record. `[read: scripts/lib/dev-cycle-read.sh:552-578]`
- The memo `break` keeps the pass at O(records + distinct directories). The measured lookup counts on all three repos equal records plus directories. Fact-check also found the memo-`break` mutant equivalent in result. `[fact-check: factcheck-summary-L3, "only the unreachable `*)` arm and an equivalent memo-`break` mutant survive" — Verified]`
- Claim: on a fresh clone of main, `--cached --others` returns the same set of names as the old pair of listings, so the merge changes cost only and not behaviour. The counts matched (1,452 = 1,452), but only the counts were compared, not the sets. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Ancestor pass: linear in records plus directories; ~21 ms here, +~1.3 s on a 200k-directory adversarial tree | Informational | `scripts/lib/dev-cycle-read.sh:565` | High |
| 2 | Merged listing is no slower than the pair; on deep trees the cost is the `--others` directory scan, which predates this change | Informational | `scripts/lib/dev-cycle-read.sh:566` | High |

## Overall Assessment

The two code changes since iteration 2 do not regress performance. The ancestor pass is the memoised variant (A') that the iteration 2 review recommended, placed where it recommended. Its measured cost on this repo is 21 ms and does not show end to end above noise. It is linear in records plus distinct directories, which bounds it by the tree that the record loop already parses at a higher cost per entry. The merged listing is equal to or slightly faster than the pair it replaced. The only cost that scales and is not already priced is the `--others` directory scan at very high directory counts. It predates this change and belongs to rows 377/394. Neither finding blocks a merge, and nothing needs more profiling before the row 365 trigger fires. From a performance standpoint, the branch is merge-ready.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/performance-reviewer-review-2026-10-06-L3-build-loop-u2a3.md, structured per the performance-reviewer skill."
- **Answered:** I measured the ancestor pass and the merged listing end to end and by segment on three repos: a fresh clone, a 20k-file wide tree and a 20k-file, 200k-directory adversarial tree (F1, F2). I confirmed that the pass's lookup count is linear in records plus directories. I did not re-file the settled rows (365, 377, 378, 384, 386, 394). F2 only adds a data point to rows 377/394.
- **Out of scope:** The `ident` attribute gap, test 10's masked tree-listing refusal and the LC_ALL=C caller note from the fact-check summary. These go to the author, U2b and test-strategy. Wording items are also out of scope.
- **Escalate:** None that blocks the merge. For the rubric author: optionally attach F1's pass to row 365's Defer and trigger, and F2's directory-count note to row 377.
