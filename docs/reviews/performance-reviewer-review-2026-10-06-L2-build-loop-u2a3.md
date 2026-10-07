Commit: 5c57d367

# Performance Review — feat/build-loop-u2a3 after the split (loop 2, iteration 1)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 5c57d367). The code that matters for performance is in `scripts/lib/dev-cycle-read.sh`: nul_list (:517), main_imports (:546-609) and isimported (:615). The review concentrates on what the split (2b22a082) changed: the `${c%/*}` parent loop (:605), the checkout probe (:606), the `mapfile -d /` split of link text (:588) and the early return on an untracked start file (:569).
**Date:** 2026-10-06
**Based on:** the shared review context (shared-L2), the Stage 1 summary (factcheck-summary-L2i1; report `docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md`), the loop-1 final performance review (`docs/reviews/performance-reviewer-review-2026-10-06-final-build-loop-u2a3.md`) and the settled override rows (`docs/reviews/override-log.md` :365-385).

## Data Flow and Hot Paths

main_imports runs once per merge-gate check, and nothing calls it until U2a4. Its result is cached per `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`. **Path temperature: cold.** It runs once per merge and blocks no latency-sensitive operation.

The split removed the checkout read path, so the walk now reads only main's committed blobs. The checkout is touched in two ways only:
- `untracked_md` is listed so the walk can fail on an untracked start (:569, an early `return 1`).
- For each distinct imported path that main lacks, `-d`/`-L`/`-e` tests run, plus `blocker "$p" dir` when that path is a plain directory (:606).

Every measurement below was taken on this host (WSL2, bash 5.2.15) in `/tmp/u2a3-perf2-i1-nk19`. They compare `old` (lib at cc1aa864, the loop-1 final state) with `new` (lib at 5c57d367), both extracted with `git show`. The harness sources the lib under `set -euo pipefail`, sets ROOT_REAL, runs `resolve_main` and times `main_imports`. Note that the host's en_US.UTF-8 locale is not installed, so the default runs execute in the C locale. Runs labelled "UTF-8" set `LC_ALL=C.UTF-8`.

- **This worktree** (2,966 tree entries, 3 imports): old 407/413/407 ms against new 445/405/400 ms. There is no measurable change at real-repo scale.
- **200 imported paths main lacks** (`@d1/d2/d3/d4/pN`), 3 runs each:

  | case | old | new |
  |---|---|---|
  | absent | 570-588 ms | 465-483 ms |
  | each one a plain checkout directory | 2.8-5.6 s | 1.62-1.70 s |

  The split removes the pre-split `t:` queue entry and its `inrepo_here` and `blocker` probes.
- **50 symlinked `.claude/rules/rN.md -> ../../docs/aN.md`**: old 709/752/879 ms against new 743/837/933 ms. That is about 1 ms per link at most for the process-substituted `mapfile -d /` split, within run-to-run noise and small next to the settled ~12-15 ms per link (row 378).

These settled rows are not re-filed, because the split does not change them:
- row 365/B6: cost per tree record
- row 355: queue pop and the `lower` fork per edge, both still at :575 and :601
- row 346: one cat-file per blob
- row 377: listing ignored .md files. The listing is still needed to detect an ignored CLAUDE.local.md start.
- row 378: per-symlink cost
- row 384: process substitution per queued file

## Findings

#### F1. The parent-link loop is still O(L x depth): a deep `a/a/.../x.md` token costs 9.4 s (C) or 15.8 s (UTF-8) at 64 KB. The single-segment case from loop-1 F1 is fixed.

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:605`. The excerpt ends at :605. The rest of main_imports() (:606-609: the checkout probe, the edge loop's `done < <(printf '%s\n' "$out")`, and the closing of the queue loop and the function) was read.
**Evidence:**
```
      c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done
```
Loop-1 F1's recommended mutant is in place: it steps over `/` positions only. Each step still copies `c` (O(L)) and hashes a key up to L long, so the cost is O(L x depth). Measured end to end, with one tracked AGENTS.md holding one token that main lacks; every run returned rc=0 with one line:

| token shape, L | old C | new C | old UTF-8 | new UTF-8 |
|---|---|---|---|---|
| one segment `aaa.../x.md`, 64,000 | 5,759 ms | 267 ms | 22,250 ms | 1,033 ms |
| `a/a/.../x.md`, 4,000 | 57 ms | 51 ms | — | — |
| `a/a/.../x.md`, 16,000 | 527 ms | 512 ms | — | — |
| `a/a/.../x.md`, 64,000 | 10,134 ms | 9,414 ms | 32,088 ms | 15,779 ms |

Timing the loop on its own (`loop.sh`, C locale) gave:
- one segment: 0.1 ms at L=1,000 and 1.3 ms at L=64,000
- many segments: 4.2 ms at 1,000, 38 ms at 4,000, 470 ms at 16,000 and 8.7 s at 64,000

**Move:** 9 (asymptotic behaviour), 2 (size of N)
**Classification:** Macro (O(L x depth) per distinct path, quadratic when depth is about L/2) / Cold path (once per merge gate)
**Confidence:** High (measured)
**Baseline:** 9,414 ms for one 64,000-character `a/a/.../x.md` import (C locale), measured in /tmp/u2a3-perf2-i1-nk19 on 2026-10-06
**Legibility-target:** for-author

At realistic lengths (under 250 characters, depth under 30) the loop costs well under 0.1 ms per path, so normal repos do not pay for it. A path the filesystem could hold (L ≤ PATH_MAX 4,096) costs at most about 40 ms. Only a token longer than PATH_MAX, which `realpath -ms` passes without touching the disk, reaches the multi-second range. The split narrows who can supply that token: untracked starts now fail the walk at :569, so only text already committed to main feeds the loop. Loop-1 F1's "ten tokens in an untracked CLAUDE.local.md" route is closed. A token that lands on main through one merge still slows every later gate by about 9-16 s per token. The walk is slow, never fail-open, and the path is cold, so the severity is Low.

**Recommendation:**
- Linear option: while the record loop at :554-560 runs, collect the names main stores as 120000 or 160000 into a small array. Then replace :605 with `for k in "${links[@]}"; do [[ "$p" != "$k"/* ]] || fail; done`. At L=64,000 this measured 0.45 ms against 8.9 s for two links (`loop2.sh`, C locale). It costs O(#links x L) and is usually 0-10 links. This was a perf-only mutant, not run against the suite.
- Simpler option: fail closed on any imported path longer than 4,096 bytes before :605. Claude Code cannot open such a path either. With that cap, the current loop costs at most about 40 ms.

Either change must re-run test 9 and the e7b5d7ed and 2b22a082 gitlink parent mutants. If you defer, record it as an override row whose trigger is a cap on token length or U2a3b's parser rework.

## Endorsements

- The split makes an absent path that main lacks cheaper. It no longer queues a `t:` item that pays `inrepo_here` (a `blocker` subshell plus a realpath fork per component). :606 now runs only `-d`/`-L`/`-e` tests on it and forks `blocker` only when the path is a plain directory, because `&&` short-circuits. On 200 depth-5 paths this measured 465-483 ms against 570-588 ms when absent, and 1.6-1.7 s against 2.8-5.6 s as plain directories, run in this pass. `[read: scripts/lib/dev-cycle-read.sh:606, :110-122, :127]`
- An untracked start file now ends the walk at :569, before any blob is read. That is a fail-fast that also removes the pre-split checkout read and parse per untracked start. `[read: scripts/lib/dev-cycle-read.sh:546-572]`
- The `mapfile -t -d / parts < <(printf '%s' "$out")` split at :588 adds about 1 ms per followed symlink against the here-string. I measured 50 links: 743-933 ms new against 709-879 ms old, which overlap. It runs once per symlink, so no per-edge cost is added. `[unverified — submitted as claim]` (measured in this pass only; Stage 1 did not execute a timing)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Parent-link loop O(L x depth): 9.4 s at a 64 KB deep token (the single-segment case of loop-1 F1 is fixed; only main's committed text reaches it now) | Low | `scripts/lib/dev-cycle-read.sh:605` | High |

## Overall Assessment

The split is a net performance gain. At real-repo scale the cost is unchanged (about 0.4 s on this worktree). It is cheaper for imported paths that main lacks: 20% faster when they are absent, and 1.7-3.3x faster when they are plain checkout directories. The link-text split adds noise-level cost. The one remaining concern is the loop-1 F1 shape in a new form. The parent loop no longer goes quadratic on a long single segment, which went from 5.8 s to 0.27 s, but it still does on a deep token longer than PATH_MAX. That is a cold, slow-not-open path, now reachable only from main's committed text. Either a length cap or a link-prefix check fixes it in one line. No profiling is needed beyond the measurements above; the fixes should be re-measured with `loop.sh` and `walk.sh` in the scratch dir.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/performance-reviewer-review-2026-10-06-L2-build-loop-u2a3.md, structured per the performance-reviewer skill."
- **Answered:** I measured all three things the split changed, plus the early untracked return. The `${c%/*}` loop fixed the single-segment case and is still quadratic for deep tokens (F1, Low). The checkout probe and its `blocker` call are cheaper than before the split. The mapfile split costs noise.
- **Out of scope:** the settled rows listed in Data Flow (365, 346, 355, 377, 378, 384). Fail-closed correctness of the checkout probe belongs to Stage 1 and the security critic. The parser (`import_targets`) belongs to U2a3b (stacked).
- **Escalate:** none at Medium or above. F1 goes to the author as Fix or Defer-with-trigger (a token-length cap, or U2a3b's parser rework).
