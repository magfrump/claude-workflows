Commit: 007e867f

# Performance Review — feat/build-loop-u2b3b2c (final confirming pass)

**Scope:** `git diff main...HEAD` (main 8e550626, HEAD 007e867f): `scripts/lib/dev-cycle-read.sh` (import_readers, root_copies, prompt_marks, outside_seeds, config_seeds, c1_seeds, both walks), with the tests as context
**Date:** 2026-10-09
**Based on:** Stage 1 code fact-check at 007e867f (replicates r1-r3: no behavioural Incorrect; 242 names per walk identical to main's lib), my i1 report (`performance-review-2026-10-09-u2b3b2c-i1.md`), and override-log rows 594-601

## Data Flow and Hot Paths

Both walks (`imported_names`, the tree walk, and `main_imports`, the main walk) run once per gate decision. Each is memoized by root set. Neither is a request path, but each walk blocks the self-merge decision, and the override log's revisit line is a 5 s walk (rows 588, 594). Since i1, the following changed:

- **root_copies (:1272-1298):**
  - It now takes one batched `realpath -mz` over names and copies together (2n arguments, one xargs per call with n > 0).
  - It never skips a prompt copy on equal bytes (:1288). Every other root's copy of every prompt-dir name is queued.
  - It forks `lower` once per queued prompt copy (:1296).
- **prompt_marks (:1308-1317):** runs once per dangling prompt-link `//` entry. Per projected name it may fork `lower` once (:1314), and it appends the link's bases to a `pext` string (:1315). Each later read of that name expands the string with `mapfile` (:1573, :1670).
- **The split:** `outside_seeds` became `config_seeds` + `c1_seeds`. C1's sha1sum pass moved to root_copies. main's `outside_seeds` already ran two `with_at` batches, so the fork count is unchanged.

**Measurements** were taken in this container on 2026-10-09 (16 CPUs, load average 2.0-5.0 from concurrent agents). The interleaved runs compared main's lib (8e550626), the i1-fix lib (8976fbdf) and HEAD. A wrapper counted root_copies calls, candidates, returned copies and their own time in µs.

- **/workspace's real registry:** `git worktree list` gives 9 entries (one prunable), so IMPORT_OTHER has 7 roots. /workspace tracks **no** prompt-dir files (0 matches for `.claude/(commands|agents|output-styles|skills)/*.md`).
  - Tree walk, 5 rounds:
    - main: 1.69-1.75 s
    - i1: 1.73-1.83 s
    - HEAD: 1.73-1.85 s, plus one 2.96 s outlier
  - Main walk, 5 rounds:
    - main: 2.13-2.49 s, plus one 3.36 s outlier
    - i1: 2.34-2.95 s
    - HEAD: 2.18-2.70 s
  - All three libs gave 820 list lines with identical content (hash c37c761f).
  - root_copies on both branch libs: 31 calls, 362 candidates, 4 copies returned, 50-69 ms of its own time.
  - The i2 changes therefore cost nothing measurable here.
- **Synthetic, throwaway repos under /tmp/perff-u2c-\*:**
  - CLAUDE.md, plus 50 files `.claude/commands/cN.md`, each holding `@docs/cN.md`.
  - W worktrees, all at the **same commit**: every copy has equal bytes and there is no drift.

| W (other roots) | lib | tree walk | main walk | copies returned | root_copies own time |
|---|---|---|---|---|---|
| 0 | main / i1 / HEAD | 1.85-1.90 / 1.98-1.99 / 1.88-1.91 s | — | — / 0 / 0 | — / 8 ms / 8 ms |
| 4 | main / i1 / HEAD | 2.30-3.59 / 2.60-2.89 / **5.66-6.01 s** | 2.00 / 2.33 / **5.96 s** | — / 0 / 200 | — / 0.35 s / 0.73-0.78 s |
| 8 | main / i1 / HEAD | 2.67-3.00 / 3.04-3.50 / **9.62-11.85 s** | 2.85 / 2.65 / **10.31 s** | — / 0 / 400 | — / 0.37-0.39 s / 1.25-1.38 s |
| 16 | main / i1 / HEAD | 3.57-4.17 / 5.53-5.90 / **20.3-20.6 s** | — | — / 0 / 800 | — / 0.5-1.0 s / 2.4-3.1 s |

Main walk cells marked "—" were not measured.

At W=4, the sorted unique list from the i1 lib and from HEAD was identical: 940 lines, 526 repo-relative. I checked this for both layouts:

- worktrees beside the repo;
- worktrees nested under the repo's `.claude/` (`r/.claude/wt-N`, /workspace's layout): 936 lines each, with the HEAD tree walk at 5.46 s against 2.43 s on i1.

## Findings

#### F1. Equal-bytes prompt copies are read in every other root: walk time scales with prompt files × worktrees on a registry with no drift

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1288` (the `-z "${rc_p[${ps[i]}]+set}"` guard on the equal-bytes skip), `:1296` (`lower` per queued prompt copy); called from `:1567`, `:1590`, `:1663`, `:1721`
**Move:** Hidden multiplication; work that moved to the wrong place
**Classification:** Macro (reads = prompt-dir files × other roots, no drift needed) / Cold path. It runs once per gate decision, but it blocks that decision and crosses the 5 s revisit line at small sizes.
**Confidence:** High (measured)
**Baseline:** The tree walk took 2.60-2.89 s on the i1 lib against 5.66-6.01 s at HEAD, measured 2026-10-09 in this review: 50 `.claude/commands` files, 4 worktrees at the same commit, 200 extra copies read. It was 20.3-20.6 s at HEAD against 5.5-5.9 s on i1 at W=16.
**Legibility target:** for-orchestrator-synthesis
**Evidence:**
```
      if [[ -z "${rc_p[${ps[i]}]+set}" && -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}" ]]; then sp+=("$i"); hs+=("${cs[i]}" "${ps[i]}"); else qs+=("${cs[i]}"); qn+=("${ps[i]}"); fi
```
```
    [[ -z "${rc_p[${qn[i]}]+set}" ]] || rc_p[${qs[i]}]="$(lower "${qs[i]}")" || return 1
```
(root_copies, :1288 and :1296. The remainder of the function is the sha1sum pass for non-prompt copies, :1291-1294, and `rc_q+=` at :1297.)

i1 F1 and override row 594 cover copies that **differ**. Their cost needs drift, and the row was deferred on the grounds that today's registry shows 66 ms. i2 changed the basis. A prompt-dir name (every `.md` under `.claude/commands|agents|output-styles|skills/`, at any depth) now has its copy read in every other root even when the bytes are equal. Each read also forks `lower` and calls root_copies again over the copy's names. That makes the cost P × W reads, about 13-18 ms each under this load, and it needs no stale worktree at all. A repository with 50 prompt files and 4 build-loop worktrees passes 5 s, and one with 16 worktrees takes 20 s per walk; both walks pay it.

In both measured layouts the extra reads added **no** name: the unique lists were identical at W=4, including with worktrees nested under `.claude/`. So in the common case this is pure cost. The `lower` forks alone took about 2 ms per copy: root_copies' own time rose from 0.35 s to 0.75 s at W=4 and to 2.4-3.1 s at W=16.

/workspace pays nothing today only because it tracks no prompt-dir files (this repo's skills live in top-level `skills/`, not `.claude/skills/`). A project whose `.claude/skills/` holds reference files reaches P = 50-200 easily.

**Recommendation:** Keep the equal-bytes skip for prompt copies too, and supply the absolute-path prompt bases that i2 fact-check 16 needed without a read. The extra bases come only from a `.claude` component in the other root's own path (`prompt_bases` over `ROOT/NAME` against `NAME`). Compute them once per root and attach them to ROOT_REAL's (or main's) read of NAME through `pext`. That gives one read per name instead of W. Failing that, skip the read when the root's path has no `.claude` component, where the bases are exactly the per-root joins of ROOT_REAL's. Either way, batch the `lower` calls with `lower_all`.

If neither is taken, file an override row with this measured price and a P × W revisit trigger. Row 594's "66 ms today" basis does not cover this.

The fact-check or security reviewer should confirm that the derived bases equal what the read yields. `[unverified — submitted as claim]` for the equivalence.

#### F2. Escalated prompt_marks residual: the planned re-queue fix is cheap but, as described, insufficient in two cases

**Severity:** Informational (performance); the correctness gap belongs to security and the orchestrator
**Location:** `scripts/lib/dev-cycle-read.sh:1308-1317` (prompt_marks), `:1578`, `:1706`
**Move:** Find the work that moved to the wrong place (ordering); asymptotic behavior of the fix
**Classification:** Micro / Cold
**Confidence:** Medium (read; not executed)
**Baseline:** no baseline available — flagged as speculative
**Legibility target:** for-orchestrator-synthesis
**Evidence:**
```
  while IFS= read -r p; do
    [[ -n "$p" && "$p" != /* ]] || continue
    [[ -n "${pm_p[$p]+set}" ]] || pm_p[$p]="$(lower "$p")" || return 1
    pm_x[$p]="${pm_x[$p]:+${pm_x[$p]}$'\n'}$b"
  done < <(printf '%s\n' "$pm_o")
```
(prompt_marks' loop, :1312-1316; the function ends at :1317)

I assessed the escalated fix shape: "re-queue an already-read name when prompt_marks marks it".

**Cost.** A re-queue adds at most one read per projected name per dangling prompt link. The projection is `IMPORT_WHOLE` over one real path, so a few names per link. That is bounded by the link count and negligible next to F1.

**Sufficiency.** I see two gaps, `[unverified — submitted as claim]`:

1. **Trigger condition.** `pm_x[$p]` is appended on every mark, but `pm_p[$p]` only on the first. Take a name already read **as a prompt** with its own bases, which a later link then gives new bases (the link's directory and its `.claude` holders). That name is "marked" without being newly put in PDIR. It needs a re-read too. The trigger should be "pext[p] gained bases after p was read", not "PDIR newly set".
2. **Other roots' copies.** The re-read name's copies in other roots were already passed through root_copies while it was plain, and `CMP` memoizes the name. They are not re-queued as prompts, and they do not receive the bases. Under the current rule a prompt copy is always read, but here the copy stays a plain read.

In the tree walk, the newline `seen` string also blocks a re-queue, so the fix needs its own path there. In the main walk, the re-read should join `tq` (phase 2).

**Recommendation:** Re-queue on any `pext` growth for a name already popped. Clear the name's `CMP` entry, or re-run root_copies for it, so its copies are re-marked. Keep a per-name "bases applied" count so each name is re-read at most once per new base set.

#### F3. pext strings grow per dangling prompt link and are re-split on every read of the name

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1315`, `:1573`, `:1670`
**Move:** Trace the memory lifecycle
**Classification:** Micro / Cold
**Confidence:** High (read)
**Baseline:** no baseline available — flagged as speculative
**Legibility target:** for-author
**Evidence:**
```
    [[ -z "${pext[$f]+set}" ]] || mapfile -t -O "${#xs[@]}" xs <<<"${pext[$f]}"  # a dangling prompt link's bases (prompt_marks)
```
Each `//` prompt entry is popped once, because `seen` dedupes it. `pext[p]` therefore grows by one base list per distinct dangling prompt link that projects `p`. Lists from links in different roots carry distinct absolute directories, so there are no exact duplicates across roots. Each base multiplies the parser's per-name joins for `p`, and that work is charged to IMPORT_WORK_MAX, so it fails closed. The growth is links × names, and links come from other roots' trees, so they are bounded by the registry. No action needed. If F2's fix re-reads on growth, dedupe the bases before appending.

## Endorsements

- The batched `realpath -mz` over names and copies costs one fork per root_copies call that admits a copy, and none for a call whose names are all memoized in `CMP`. On /workspace, root_copies' own time stayed at 50-69 ms (31 calls, 362 candidates) at HEAD, the same as on the i1 lib. `[read: scripts/lib/dev-cycle-read.sh:1272-1298]`
- Over /workspace's real registry (7 other roots, 820 lines), both walks at HEAD produce the same list as main's lib, with times inside run-to-run noise. `[fact-check: Stage 1 at 007e867f — 242 names per walk identical to main's lib (executed)]`
- The outside_seeds split adds no fork batch. main's `outside_seeds` already ran two `with_at` passes, and the C1 sha1sum pass moved into root_copies rather than being duplicated. The synthetic W=0 walk took 1.85-1.90 s on main against 1.88-1.91 s at HEAD. `[unverified — submitted as claim]`
- prompt_marks forks `lower` at most once per projected name per walk, because PDIR memoizes it. `[read: scripts/lib/dev-cycle-read.sh:1308-1317]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Equal-bytes prompt copies read in every root: P × W reads with no drift; 5.7-6.0 s at 50 prompts × 4 worktrees, 20 s at 16; no name added in the measured layouts | Medium | `scripts/lib/dev-cycle-read.sh:1288, 1296` | High |
| F2 | Escalated prompt_marks fix: cheap, but needs to trigger on pext growth and to re-mark other roots' copies | Informational (perf) | `scripts/lib/dev-cycle-read.sh:1308-1317, 1578, 1706` | Medium |
| F3 | pext grows per dangling prompt link and is re-split per read; charged to the work budget | Informational | `scripts/lib/dev-cycle-read.sh:1315, 1573, 1670` | High |

## Overall Assessment

On /workspace the final branch costs nothing measurable over main: same output, and walks within noise at about 1.7-1.9 s (tree) and 2.2-2.7 s (main) with 7 other roots. The split and the batched realpath are cost-neutral.

The i2 change "a prompt copy is always read" adds a multiplication that i1 F1 and row 594 do not cover. Reads scale with prompt-dir files × worktrees even when every worktree is at main's commit. In the layouts measured, those reads added no name. /workspace avoids the cost only because it tracks no `.claude/` prompt files; a typical project with a populated `.claude/skills/` and a handful of worktrees crosses the 5 s revisit line.

The fix fits in place: derive the root-prefix prompt bases instead of re-reading equal bytes. If it is not taken, it at least needs its own override row with this price. The escalated prompt_marks fix is cheap but should trigger on pext growth and re-mark copies (F2). Profiling against a real project with `.claude/skills/` would confirm the P that matters.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/performance-review-2026-10-09-u2b3b2c-final.md, structured per the performance-reviewer skill, with `Commit: 007e867f` as its first line."
- **Answered:**
  - Cost of prompt copies always read, per prompt name × roots: F1, measured.
  - The batched realpath: an endorsement.
  - prompt_marks' `lower` per projected name and `pext` growth: F3 and an endorsement.
  - The split's cost: an endorsement, submitted as a claim.
  - Interleaved real-registry timings against main's lib, with load and worktree count: Data Flow section.
  - The escalated prompt_marks fix shape: F2.
- **Out of scope:** whether the bases derived in F1 are exactly equivalent to reading the copy, and the correctness of the prompt_marks residual. Fact-check and security own those.
- **Escalate:**
  - F1, to the orchestrator: it changes override row 594's basis (equal-bytes prompt copies, no drift needed). Decide fix or a new override row before merge.
  - F2's two sufficiency gaps, to whoever implements the post-pass fix.
