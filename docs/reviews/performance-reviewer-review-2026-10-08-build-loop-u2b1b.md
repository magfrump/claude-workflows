Commit: 809df345

# Performance Review — feat/build-loop-u2b1b (U2b1b, iteration 1)

**Scope:** `git diff main...HEAD` (0e4596ce...809df345): `scripts/build-loop.sh` (gate_git, merge_result, own_blob, nrules, check_line), tests and docs read for context
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check summary (k=1, 809df345; full report `docs/reviews/code-fact-check-report-build-loop-u2b1b.md`, 43 claims, 0 Incorrect/Stale); prior rubric row A18 (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:28`)

All timings below are mine, measured on this host (WSL2, 16 cores, git 2.39.5) with probe scripts in `/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i1/perf/` (`probe1.sh` changed-path count, `probe1v.sh` same with one line changed in a scratch copy of the script, `probe2.sh` history depth, `probe1b.sh` own-brief cost). Single runs unless stated; run-to-run noise at the ~150 ms floor is about ±40 ms.

## Data Flow and Hot Paths

`--check BRIEF...` runs once per merge attempt, per brief. U2b1b adds, after merge_result's tree: one `merge-base --all` plus one `cat-file -e` per tree (main, tip, each base) in merge_result (`scripts/build-loop.sh:514-517`); one `diff-tree -r --raw -z` of MAIN→TREE into `$GATE_TMP/diff` (`:578`); a per-record bash loop calling `nrules` (`:581-589`); one `tr | wc` NUL count over the file (`:591`); and the buffered `rows` array printed after the verdict line (`:593`).

N, the number of records, is the paths the **branch's own** changes touch in the merge (diff-tree runs MAIN_SHA→merged tree, so main's later commits do not count; `--no-renames` makes each rename two records). For a normal brief N is tens. It is bounded by nothing but the branch: a loop that commits generated output, a vendored tree, or a mass rename reaches thousands.

Path temperature: **cold** (one CLI invocation per merge attempt, advisory until U3), but a cold path whose cost scales with the data (the hot-path gate's "runs over large data" exception), and in U3 it becomes the work done between `--expect`'s read and `--merge`'s CAS.

Per-record cost in `nrules` (`:541-554`, read whole): `pathform` (pure bash, lib `:182-191`), one mode regex, the own-brief compare, then `lp="$(lower "$6")"` (`:548`), then `writable`/`anybrief`/`isbrief`/`isclosed` (pure bash regexes, lib `:199-205`). `lower` is `printf '%s' "$1" | tr 'A-Z…' 'a-z…'` (lib `:624`): a command-substitution subshell, a pipeline fork and a `tr` exec per path. `own_blob` (`:527-534`) runs at most once per brief (only for the record whose path equals the brief), not per path.

Measured totals for one brief, changed brief included (`probe1.sh`):

| N changed paths | `--check` wall ms (as built) | with `:548` as `lp="${6,,}"` (`probe1v.sh`) |
|---|---|---|
| 1 (+brief) | 201 | — |
| 10 | 215 | — |
| 100 | 360 | — |
| 1,000 | 2,453 | 324 |
| 5,000 | 13,460 | 1,163 |

## Findings

#### F1. `lower` forks a subshell and execs `tr` for every changed path: ~2.5 ms per path, 92% of `--check`'s time at 5,000 paths

**Severity:** Low
**Location:** `scripts/build-loop.sh:548` (in `nrules`, `:541-554`; called per record from `check_line`'s loop `:581-589`); callee `scripts/lib/dev-cycle-read.sh:624`
**Move:** 1, Count the hidden multiplications
**Classification:** Micro (per-call fork/exec, linear in N) / Cold path over large data (one CLI run per merge attempt; N unbounded by the code)
**Confidence:** High (measured; the variant changes only this line and produces the same merged tree id `fbbe1faa…` and the same 5,002 output lines)
**Baseline:** `--check` on one brief with 5,000 changed paths: 13,460 ms wall; 1,163 ms with only `:548` replaced by an in-shell lower-case (measured 2026-10-08, `perf/probe1.sh` vs `perf/probe1v.sh`)
**Legibility-target:** implementer (one-line fix) and, if kept, the override log (a stated price per changed path)

Evidence (verbatim):

```
  elif ! lp="$(lower "$6")"; then DENY="the path could not be lower-cased"
```
```
lower() { printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
```

Excerpt `:548` ends inside `nrules`, which continues to `:554` (two pure-bash regex branches on `lp`); `lp`'s first use is `:549`. Every record whose path passes `pathform` and the mode rule and is not the brief reaches `:548`, so on an honest branch every record pays it. Cost is linear (≈2.2 ms/path at 1,000, ≈2.6 ms/path at 5,000; the rest of the loop is ≈0.2 ms/path). At 5,000 paths the gate takes 13 s instead of about 1 s; at 50,000 (a committed `node_modules`) it extrapolates to about 2 minutes — no baseline at that size, speculative. This is not a correctness or DoS issue (advisory gate, linear, a loop slowing its own merge check), hence Low; it matters once U3's `--merge` runs the same loop between reading TIP and the CAS, where a longer window raises the chance main moves and the CAS refuses.

**Recommendation:** at `:548`, lower-case in the shell. `pathform` has already passed (`:546`), so the path is ASCII from `NAMECHARS`; use `lp="${6,,}"` with the script's locale pinned for that expansion (bash's `,,` follows `LC_CTYPE`, and a Turkish locale maps `I` to dotless ı, unlike `tr`), e.g. a `local LC_ALL=C` in `nrules` before it. The lib's `lower` is used elsewhere (6 call sites, all per-brief, not per-path); leave it or switch it the same way in U3b's lib pass.

#### F2. The added `merge-base --all` repeats the walk merge-tree already does, under commitGraph=false (A18's class, now one more walk per brief)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:514` (in `merge_result`, `:512-522`)
**Move:** 3, Find the work that moved to the wrong place (duplicated, not moved)
**Classification:** Macro (walk is O(commits main gained since the branch point)) / Cold path (once per brief)
**Confidence:** High (measured)
**Baseline:** `git -c core.commitGraph=false merge-base --all` with main 20,000 commits past the branch point: 50 ms (7 ms with a commit-graph); `merge-tree --write-tree` on the same pair: 56 ms; whole `--check`: 791 ms (measured 2026-10-08, `perf/probe2.sh 20000`). At 1,000 commits: 3 ms; at 100,000: 306 ms of 3,151 ms.
**Legibility-target:** override log row 511 (A18's price line), so the "no new history walk but merge-base --all" note carries a number

Evidence (verbatim):

```
  bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 ]] || return 2
  # shellcheck disable=SC2086  # one commit id per word
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
  rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?
```

Excerpt `:514-518` ends inside `merge_result`, which continues to `:522` (tree-id check, conflict return, echo). merge-tree computes the same merge bases internally, so the R6 guard doubles the base walk; git 2.39 has no `merge-tree --merge-base` to hand the bases over (that arrived in 2.40). The walk is a fixed fraction of `--check` (≈6-10% in the deep-history runs; the rest is the pre-existing walks A18 already prices), and it only bites on a branch that fell tens of thousands of commits behind main. The override row's own note ("A18 not changed (no new history walk but merge-base --all, one per brief)") is accurate; it just has no price attached.

**Recommendation:** keep it (it is the R6 fix and cheap at realistic depth). Add the measured price to override row 511's A18 note. Optional, sub-10 ms: replace the per-tree `cat-file -e` loop (`:517`, one `env`+`git` spawn per tree, 3+ spawns) with one `cat-file --batch-check` over the list, if the stderr-is-failure rule of `gate_git` still holds for it.

#### F3. `own_blob` reads main's copy of the brief twice and spawns five processes; cost is below measurement noise

**Severity:** Informational
**Location:** `scripts/build-loop.sh:531-533` (in `own_blob`, `:527-534`); called from `nrules:547` only when the record's path is the brief
**Move:** 1, Count the hidden multiplications (checked: multiplier is 1)
**Classification:** Micro / Cold (at most once per brief)
**Confidence:** Medium (the difference is inside run-to-run noise)
**Baseline:** one changed path with the brief unchanged vs changed, five paired runs: 129/141, 199/169, 207/182, 193/146, 142/149 ms (measured 2026-10-08, `perf/probe1b.sh`); no consistent difference
**Legibility-target:** none needed beyond this report

Evidence (verbatim):

```
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }')" || return 1
  [[ "$n" -gt 0 ]] || return 1
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin
```

`own_blob` is the whole function to `:534`. The double read is deliberate-looking (awk finds the line number with the fence model; perl rewrites it) and the blob is a brief (kilobytes). Nothing to do; recorded so the per-path concern in the brief is closed: own_blob is per brief, not per path. It is not on F1's path either (the brief's record never reaches `:548`).

**Recommendation:** none.

## Endorsements

- The changed-path list is streamed from one `diff-tree -z` file and parsed in one bash loop with no per-record git call (`:578-589`); the completeness check is one `tr | wc` pass over the same file (`:591`), so git work is O(1) processes per brief regardless of N `[read: scripts/build-loop.sh:578-593]`.
- The `rows` array holds one short line per changed path and is printed once after the verdict (`:588`, `:593`); its size is O(N) and bounded by the diff, measured at 5,000 rows with no visible memory or time cost beyond F1 (variant total 1,163 ms) `[unverified — submitted as claim]` (memory not measured; buffering is required by the verdict-first output order).
- `nrules`' branch order sends pathform and mode failures out before `lower`, so a denied odd path pays no fork `[read: scripts/build-loop.sh:541-554]`.
- `gate_git` adds no process over the pre-existing `(cd …; env … git)` shape; it only redirects stderr to a file and tests its size `[read: scripts/build-loop.sh:502-507]`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `lower` fork+exec per changed path: 13.5 s vs 1.2 s at 5,000 paths | Low | `scripts/build-loop.sh:548` | High |
| F2 | `merge-base --all` repeats merge-tree's base walk under commitGraph=false; unpriced in row 511 | Informational | `scripts/build-loop.sh:514` | High |
| F3 | `own_blob` double read: once per brief, below noise | Informational | `scripts/build-loop.sh:531-533` | Medium |

## Overall Assessment

The change is linear in the number of changed paths and does no per-path git work, so its posture is sound; the only real cost is one process-spawning helper in the per-path loop. F1 is a one-line fix that cuts a 5,000-path check from 13.5 s to 1.2 s (measured) and should be taken now, since U3's `--merge` will run this loop inside its read-to-CAS window. F2 is the R6 fix paying a second base walk that is negligible at realistic branch age; price it in the override row rather than change it. No profiling beyond the probes above is needed. Nothing here is a Q-103 residual or a correctness red; F1 and F2 are honest-path costs. R8 (the GATE_TMP race) has no performance dimension I can assess and is left to the security reviewer.

## Goal-Alignment Note

User goal: land U2b1b after a clean review-fix loop. This review found no blocking (red) performance issue: one Low finding (F1, a measured 10x slowdown on large diffs from a per-path `tr` fork, fixable in one line at `scripts/build-loop.sh:548`) and two Informational notes (F2 wants a price added to override row 511's A18 note; F3 needs nothing). None blocks the merge; F1 is worth fixing in this loop because it is cheap and U3 inherits the loop.
