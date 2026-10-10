Commit: f7e1bea2

# Performance Review — feat/build-loop-u2b3b2c (iteration 1)

**Scope:** `git diff main...HEAD` (main 8e550626, HEAD f7e1bea2): `scripts/lib/dev-cycle-read.sh` (import_readers, root_copies, outside_seeds, imported_names, main_imports), `test/scripts/build-loop-check.bats`
**Date:** 2026-10-09
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-i1.md` (26 claims, 18 Verified), with the shared critic brief's overrides (rows 579-589)

## Data Flow and Hot Paths

Both import walks (`imported_names`, the tree walk; `main_imports`, the main walk) feed the self-merge floor. Each runs once per gate decision, memoized by root set (contract item 4). Neither is a request path. A decision's latency is still the wall time of one or both walks. The branch adds `root_copies`, which runs once over the seed queue and then once per file the walk reads, over that file's parser candidates (`nm`, a superset of real names). For each new candidate and each `IMPORT_OTHER` root, it does three bash file tests (`-f`, `-r`, `-L`) and no forks. Per call it then makes one `realpath -mz` fork for the copies admitted as files, and one `xargs sha1sum` batch for copies whose name ROOT_REAL holds as a plain file. Prompt-named copies also fork `lower` once each. Every copy it returns joins the queue and is read in full by the walk: `import_outside` forks realpath, capped_read, the env+awk parser and `lower`, and then calls `root_copies` again on that copy's names.

Measurements in this review were taken on this container on 2026-10-09 (load average 1.0-2.7). The setup was `cd /workspace; source <lib>; ROOT_REAL=$(pwd -P); resolve_main || true; reader_settings; import_reset`, then one walk, with main's lib from `git show main:scripts/lib/dev-cycle-read.sh`:

- **/workspace's real registry:** 9 registered worktrees, `IMPORT_OTHER` = 7 roots, `IMPORT_ROOTS` = 17 lines.
  - Tree walk: 1.73-1.80 s on main's lib against 1.77-1.88 s on the branch (5 interleaved runs each).
  - Main walk: 2.10-2.25 s against 2.03-2.26 s, with one 3.2 s outlier.
  - Both libs produced identical output: 820 lines, work 479,227, 106 files read, the same `lower` count.
  - `root_copies`: 31 calls, 362 candidates, 4 copies returned. The 4 are other roots' differing `skills/dev-cycle/SKILL.md`, which main's lib already seeded through C1. Its own time was 66 ms of a 1.79 s tree walk.
- **Synthetic worst case:** a throwaway repo under `/tmp/perf-u2c-i1-*`. CLAUDE.md imports 50 files. W worktrees are detached at an older commit where every one of the 50 files differs, and each imports `old-gN.md`, which imports `old-hN.md` (both exist only in the old commit). Results:

| W (other roots) | lib | tree walk | main walk | files read | work | IMPORTED bytes |
|---|---|---|---|---|---|---|
| 0 | main / branch | 0.73 / 0.73 s | 0.67 / 0.67 s | 73 / 73 | 71,394 / 71,394 | — |
| 4 | main / branch | 0.83-0.99 / 6.7 s | 0.79 / 6.2-7.9 s | 77 / 677 | 295,510 / 506,974 | — / 83,962 |
| 8 | main / branch | 0.88-0.91 / 12.7-13.4 s | 0.78-0.86 / 13.0-13.9 s | 81 / 1,281 | 537,354 / 991,706 | — / 137,150 |
| 16 | main / branch | 0.97-1.11 / 26.5-69 s | 0.92-0.98 / 29.3-29.4 s | 89 / 2,489 | 1,103,421 / 2,160,407 | — / 243,526 |

The extra reads are exactly 3 × 50 × W: every differing copy, plus every old-only name it reaches, read in every root that holds it. Each extra read costs about 10-12 ms. At W=16, `root_copies` itself took 627 ms of 26.5 s (1,634 calls, 19,344 candidates), so the cost is in reading the copies, not in finding them.

## Findings

#### F1. Identical copies are read once per worktree, so a walk's cost scales with worktrees × differing files, without a cap

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1256-1272` (root_copies), `:1529-1530` and `:1655-1656` (the per-file calls in both walks)
**Move:** Hidden multiplication; asymptotic behavior (what's the size of N)
**Classification:** Macro (reads multiply with worktree count × differing reached files, transitively) / Cold path. The walks run once per gate decision, but they block the decision, and with this growth a 5 s walk can be reached through the registry alone.
**Confidence:** High (measured)
**Baseline:** Tree walk 0.97 s on main's lib against 26.5 s on the branch, measured 2026-10-09 in this review over a synthetic repo with 16 worktrees at one older commit and 50 differing imported files (2,489 against 89 files read). The same build measured 1.79 s on /workspace's 9-worktree registry, where 4 copies are returned.
**Legibility target:** for-orchestrator-synthesis
**Evidence:**
```
      if outside_ok "$r/$p"; then
        [[ -z "${rc_p[$p]+set}" ]] || rc_p[$r/$p]="$(lower "$r/$p")" || return 1
        if [[ -L "$r/$p" ]]; then rc_q+=("$r/$p"); else ps+=("$p"); cs+=("$r/$p"); fi
```
```
    if [[ -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" ]]; then sp+=("${cs[i]}"); hs+=("${cs[i]}" "${ps[i]}"); else rc_q+=("${cs[i]}"); fi
```
(root_copies, :1259-1261 and :1268; the remainder hashes `hs` and queues the differing copies, :1269-1272)

Every copy that differs from ROOT_REAL's, or that ROOT_REAL lacks, joins the queue under its own absolute path, one per root. Copies whose bytes are identical to each other are therefore each read and parsed once per worktree. This is the common case, because several old worktrees usually sit at one shared stale base. Each read copy's names are then fanned out over every root again. The extra reads are D × W, where D is the number of reached names whose old version differs or is old-only, including names only the old versions import, and W is the number of other roots. Each costs about 11 ms, and both walks pay it. The seeds already cost 2-3.5 s per walk (header :764-767; override row 588's revisit trigger is a 5 s walk). With 4 stale worktrees, 50 differing reached files were enough to pass 5 s (6.2-7.9 s). On /workspace today the cost is about +0.05 s, because only 4 copies differ. The cost would grow as long-lived build-loop worktrees drift from main's skills and docs.

**Recommendation:** Dedupe copies by content before queueing. Hash every non-link copy, not just those ROOT_REAL holds (one more batch in the same `xargs sha1sum`). Queue one copy per distinct (NAME, hash), because equal bytes at the same repo path yield the same repo-relative names. Cost then scales with distinct versions, not worktrees: here, 150 extra reads at any W against 2,400 at W=16. Verify that the walks' output is unchanged before relying on it. Alternatively, document the D × W × ~11 ms cost in the header's cost paragraph (:764-767) with a revisit trigger like row 588's.

#### F2. Budgets do not fail closed before wall time grows; the cost paragraph does not mention root_copies

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:764-767`, `:779`, `:799`
**Move:** Asymptotic behavior (does it cliff)
**Classification:** Macro / Cold
**Confidence:** Medium (extrapolated from 3 measured points)
**Baseline:** At W=16 with 50 differing files, the tree walk printed 243,526 bytes (6.1% of IMPORT_OUT_MAX 4,000,000) and charged 2,160,407 work (4.3% of IMPORT_WORK_MAX 50,000,000), measured 2026-10-09 in this review.
**Legibility target:** for-author
**Evidence:**
```
# swapped for a FIFO stalls it, as a checkout file can. The seeds cost: over
# this repository's 8 registered worktrees, 50 seeds and 2 to 3.5 s per walk,
# against 0.5 to 0.85 s without; each seed holding an @ costs 12 to 15 ms, and
# their number is not capped (2026-10-09; final performance F1, override row).
```
The extra reads cost about 90 output bytes and about 900 work units each at W=16. Work per read rises with the root count, because each relative name is joined per root. The output budget therefore runs out after roughly 40,000 extra reads, and the work budget, at this root count, after roughly 50,000. At about 11 ms each, that is around 7-9 minutes of walk time. Legitimate extra reads will therefore not trip IMPORT_OUT_MAX or IMPORT_WORK_MAX at any registry size where the walk is still usable, so there is no new fail-closed hazard. The binding resource is unbudgeted wall time (F1). The header's cost paragraph prices the seeds but not `root_copies`. A reader sizing the registry cannot see that stale worktrees, not only seeds, now set walk time.

**Recommendation:** Extend the cost paragraph with the measured per-copy price (about 11 ms per differing copy per root, about 1.8 s at /workspace's 9 worktrees, and the W=4/50-file figure). Note that the out and work budgets are not reached first.

#### F3. Prompt copies fork `lower` before the byte-equal skip; ROOT_REAL's file is hashed once per root

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1260`, `:1268-1271`
**Move:** Hidden multiplication (micro)
**Classification:** Micro / Cold
**Confidence:** High (read; the prompt branch was not exercised by /workspace's walks, where the `lower` count was equal on both libs)
**Baseline:** no baseline available — flagged as speculative
**Legibility target:** for-author
**Evidence:**
```
        [[ -z "${rc_p[$p]+set}" ]] || rc_p[$r/$p]="$(lower "$r/$p")" || return 1
```
```
  nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z -- && [[ ${#rl[@]} -eq ${#hs[@]} ]] || return 1
  for i in "${!sp[@]}"; do [[ "${rl[2*i]:0:40}" == "${rl[2*i+1]:0:40}" ]] || rc_q+=("${sp[i]}"); done
```
Two small redundancies in root_copies:

- The `lower` fork for a prompt name runs once per admitting root before the byte comparison, so copies equal to ROOT_REAL's still pay a fork. The PDIR entry they leave is never read.
- `hs` pairs each copy with ROOT_REAL's `ps[i]`, so ROOT_REAL's file is hashed W times, and `realpath` gets the same `p` W times.

Both cost a few milliseconds per prompt start at today's 7 roots.

**Recommendation:** Compute the lower-cased prompt path after the decision, only for queued copies. Optionally hash each distinct ROOT_REAL name once. Do this only if F1's change is touching these lines anyway.

## Endorsements

- `root_copies`' discovery cost is small next to the walk: 66 ms of 1.79 s on /workspace (31 calls, 362 candidates, 7 roots), and 627 ms of 26.5 s at W=16 with 19,344 candidates. The per-candidate per-root step is bash tests with no fork. `[read: scripts/lib/dev-cycle-read.sh:1202,1256-1262]`
- Over /workspace's registry, the branch's walks produce the same 820 lines, 479,227 work and 106 file reads as main's lib, with no measurable time change beyond noise. `[fact-check: "242 names per walk identical to main's lib; extra cost within 0.05 s per walk" — Verified (executed)]`
- `CMP` memoizes each candidate name once per walk, so a name the parser emits from many files is checked against the roots once. `[read: scripts/lib/dev-cycle-read.sh:1257-1258]`
- The tree walk's newline-string `seen` did not become a hot spot at about 2,500 queued entries: the tree walk (string `seen`) and the main walk (associative `seen`) took the same 26.5-29.4 s at W=16. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Identical copies read once per worktree; walk time scales with worktrees × differing files, without a cap | Medium | `scripts/lib/dev-cycle-read.sh:1256-1272, 1529, 1655` | High |
| F2 | Budgets are not reached before wall time; the cost paragraph omits root_copies | Low | `scripts/lib/dev-cycle-read.sh:764-767` | Medium |
| F3 | `lower` forked before the skip; ROOT_REAL's file hashed per root | Informational | `scripts/lib/dev-cycle-read.sh:1260, 1268-1271` | High |

## Overall Assessment

On /workspace today the change costs essentially nothing: about 0.05 s per walk, with identical output. `root_copies`' own lookup is cheap. The structural cost is in what it enqueues. Every root holding a differing or old-only copy of a reached name gets that copy read, transitively, and copies identical across worktrees are not deduplicated. A registry with a few worktrees at a stale base, where many instruction-reached files differ, multiplies walk time roughly linearly: about 11 ms × differing files × worktrees. Four such worktrees and 50 files already exceed the 5 s revisit line. The out and work budgets are not at risk: they would be reached only after many minutes of walking. The fix fits in place (F1: dedupe by name and hash, or at least document the price with a revisit trigger), and none of the findings blocks correctness. Profiling against a real stale-worktree registry would confirm how much drift D accumulates in practice.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md, structured per the performance-reviewer skill, with `Commit: f7e1bea2` as its first line."
- **Answered:**
  - root_copies' per-call cost: three file tests per candidate per root; one realpath and one sha1sum batch per call; `lower` per prompt copy.
  - Scaling with worktrees and candidates: F1, with a measured table.
  - The far-commit worst case: F1.
  - The newline-string `seen`: an endorsement, submitted as a claim.
  - Budget interaction (IMPORT_OUT_MAX and IMPORT_WORK_MAX do not fail closed first): F2.
  - Real-registry timing with worktree count: 9 worktrees, 7 other roots, 17 roots.
- **Out of scope:** security of reading other roots' copies, and correctness of the dangling `//` path. The fact-check owns those.
- **Escalate:** F1's dedupe changes what the walks enqueue. Confirm with the security reviewer that one copy per (name, hash) cannot miss an import. Relative names resolve to the same repo names; links are excluded from the dedupe.
