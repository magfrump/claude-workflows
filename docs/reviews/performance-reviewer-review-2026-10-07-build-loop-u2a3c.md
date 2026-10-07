Commit: 21b35ebf

# Performance Review — feat/build-loop-u2a3c (iteration 2)

**Scope:** `git diff main...HEAD` (main e5d0f838, HEAD 21b35ebf): `scripts/lib/dev-cycle-read.sh` (`capped_read`, `lower_all`, `main_checkout`, `import_work`, `IMPORT_WORK_MAX`, both walks), with the override-log closing rows for U2a3b L2-C5, L2-C6 and P2.
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md` (Commit 21b35ebf), especially its `## Escalations` (performance).

Measurement provenance: every timing below was run on 2026-10-07 under bash 5.2.15, mawk, git 2.39, 16 cores (WSL2), with copies of the libraries in the scratch dir `/tmp/u2a3c-i2-perf-SWbX` (`lib.sh` = HEAD, `lib-main.sh` = main e5d0f838, `lib-3e58.sh` = 3e58eb9c). The repos were throwaway repos in the same dir, and the worktree was never written except for this report. The harness is `walk.sh LIB main|tree`: it sources the lib, runs `resolve_main` and sets `ROOT_REAL`, then times one walk with `$EPOCHREALTIME`. `deep.sh LIB D absent|dirs` builds a repo whose main `AGENTS.md` holds `@a/a/…/a/x.md` (D components), puts a realpath-counting shim on PATH, and runs `walk.sh`. `rss.py` reports children's peak RSS. Each figure is a single run, so treat it as ±10%.

## Data Flow and Hot Paths

The two walks are `imported_names` (the tree walk) and `main_imports` (the main walk, now with a checkout phase). Each runs once per gate invocation and caches its result, which makes the path **cold**: one CLI check, not a request loop. However, each walk runs over **adversarial input**: the checkout is written by the agent the gate checks, and main's tree by whatever has merged. That puts these findings in the "cold path over large or adversarial data" exception, and I escalate them on that basis.

Today only the tree walk has a caller (`scripts/dev-cycle.sh:181-183`: `elif ! imported_names; then` / `elif isimported tree "$lp"; then`). The main walk's first callers are U2a4/U2b, so its costs are prospective.

On a real repo the walks are cheap. The fact-check measured /workspace at work=8,110, with the tree walk at 1.08 s and the main walk at 1.31 s (its Claim 33). Under that load nothing below matters. The findings concern adversarial shapes that the three closed rows exist to bound.

## Findings

#### F1. main_checkout's top-down ancestor loop is cubic in token depth: a deep token absent from the checkout costs 64 s where main's lib took 2.1 s

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:721-740` (`main_checkout`), called per import name at `:852`
**Move:** Check the asymptotic behavior (also: hidden multiplication)
**Classification:** Macro (O(D³) bash string work per token) / Cold path, but over adversarial checkout or main content, so escalated
**Confidence:** High
**Legibility-target:** code
**Baseline:** main walk on `@` + D×`a/` + `x.md` with every ancestor absent from the checkout. At D=1950, HEAD took **64,398 ms** and main e5d0f838's lib took 2,113 ms. At D=1000, HEAD took 11,614 ms, 3e58eb9c 8,454 ms and main 500 ms. At D=500, HEAD took 2,152 ms, 3e58eb9c 1,548 ms and main 151 ms. All runs used `deep.sh … absent` in `/tmp/u2a3c-i2-perf-SWbX` on 2026-10-07.

Evidence (verbatim; the loop body, which runs for every import name main lacks, and the lines after it):

```
  while [[ "$r" == */* ]]; do
    c="${c:+$c/}${r%%/*}"; r="${r#*/}"
    [[ -z "${mc_m[$c]+set}" ]] || continue
    [[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1
    [[ -z "$st" ]] || continue  # below an absent ancestor or a file: only main's modes are left
    if [[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"; then st=2
    elif plaindir "$c" && [[ -x "$c" ]]; then mc_m[$c]=1
    else return 1; fi
  done
  [[ -z "$st" ]] || return 2
```
(the function continues to `:740` with the PATH checks, which the absent case never reaches past `[[ -e "$c" || -L "$c" ]] || return 2`)

The superset parser prints every prefix of a token, so a token of D components yields about D names main lacks. For each one, the loop visits every ancestor from the top: the memo only skips the fork, not the iteration. Each iteration also copies `c` and `r`, which are O(D) strings. That is O(D²) per name and O(D³) per token, and doubling D multiplies the time by about 5. An absent ancestor is never memoized, so the `mc_e` regex runs on every component below it for every name. U2a3b's loop on main walked bottom-up and stopped at the first parent already in `pok` (`[[ -z "${pok[$c]+set}" ]] || break`), which made it about linear per name. The rewrite that closes L2-C6 (realpath forks) therefore traded forks for bash string work. That trade wins when the ancestors exist and loses when they do not.

Neither budget stops this cost early. At D=1950 the parser charged 15,370,048 work (31% of IMPORT_WORK_MAX) and printed 3,820,074 characters (95% of IMPORT_OUT_MAX). IMPORT_OUT_MAX is what caps D near 2,000, so one walk tops out at about a minute on this path. That is about 13× the "one bound ≈ 5 s" figure the P2 closing row (`override-log.md:451`) treats as the walk's worst case. The tree walk has no such loop: the same D=1000 file took 536 ms there.

**Recommendation:** Walk the ancestors bottom-up and stop at the first one already memoized, as U2a3b did. Memoize every result the loop reaches: plain searchable directory, absent, and plain file, each with the main-mode check already passed. The next prefix's parent is then always a hit, so the cost per name is O(D) and per token O(D²). Pin it with the existing realpath test plus a timed absent-ancestor case (for example D=1000 under 2 s).

#### F2. The symlink arm still reads a 120000 blob whole, twice, uncapped: a 1.3 MB repo object costs 58 s and 2 GiB RSS, and the L2-C5 closing row overstates its reach

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:826-840` (the `120000)` arm of `main_imports`); `docs/reviews/override-log.md:449`
**Move:** Trace the memory lifecycle
**Classification:** Macro (memory and time linear in blob size, and the blob is zlib-compressible) / Cold path over adversarial main content, so escalated
**Confidence:** High
**Legibility-target:** code + docs (override row)
**Baseline:** a main tree whose `AGENTS.md` imports `@lnk`, a 120000 entry whose blob is 256 MiB of `a`, stored in 1.3 MB of `.git`. The HEAD lib took **58,433 ms** with **2,051 MiB** children peak RSS, and the walk failed. main's lib was the same: 60,886 ms and 2,051 MiB. At 64 MiB, HEAD took 16,083 ms and 516 MiB. Measured with `rss.py bash walk.sh lib.sh main` in `/tmp/u2a3c-i2-perf-SWbX/repoB` and `repoC`, 2026-10-07.

Evidence (verbatim):

```
        if ! i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" || [[ "$i" -ne 0 ]] \
           || ! out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; then IMPORTED_MAIN=error; return 1; fi
```
(the arm continues to `:840`, where `realpath` on a component longer than 128 KiB fails with E2BIG, `p=..`, and the walk then fails)

Closing row, verbatim: `27364085: capped_read is the one reader for checkout files and main's blobs, and drains a pipe so git cat-file never dies of SIGPIPE under pipefail`.

The cost is pre-existing: main's lib behaves identically, so this branch adds nothing here. But the branch closes L2-C5 ("main's blobs read whole, no 4 MiB cap") as Fixed, and this residue is exactly that defect for one blob mode. The cost scales at about 0.23 s and 8 bytes of RSS per byte of link text. A 1 GiB link blob, about 1 MB in the repo, would extrapolate to about 4 minutes and about 8 GiB RSS, likely an OOM. The walk fails on the first such link, so the cost is once per walk, but nothing bounds its size. A valid symlink target is at most 4,095 bytes (PATH_MAX − 1), so any longer text can only end in failure.

**Recommendation:** Before either read, fail a link blob over 4,096 bytes (`git cat-file -s "$MAIN_SHA:$f"`: one fork, about 2 ms). Or read it through `head -c 4097` and fail when 4,097 bytes come back. Then reword the L2-C5 row (or add a row) so it names the 120000 arm, rather than saying `capped_read` covers "main's blobs".

#### F3. capped_read's drain inflates a whole blob, and neither work bound charges it or the @-less scan, so "N adversarial files cost one bound" holds only for charged work

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:703` (`capped_read`), `:823` (blob arm); `:503-508` (IMPORT_WORK_MAX comment); `docs/reviews/override-log.md:451`
**Move:** Count the hidden multiplications
**Classification:** Macro (cost ∝ inflated blob size × names, uncharged) / Cold path over adversarial main content
**Confidence:** High
**Legibility-target:** code comment + docs (override row)
**Baseline:** the main walk importing K names that share one 256 MiB blob of `x\n` (1.3 MB `.git`) took **1,061 ms** at K=1, 4,237 ms at K=4 and 8,550 ms at K=8. Per blob, the drain was 177 ms (`git cat-file blob | cat`) and the 4 MiB parse 882 ms, which charged **work /0**. A 1 GiB zero blob (4,685,484-byte loose object) drained through `capped_read` in 753 ms. Measured in `/tmp/u2a3c-i2-perf-SWbX/repoA` (`walk.sh`, `split.sh`, `drain.sh`), 2026-10-07.

Evidence (verbatim):

```
capped_read() { head -c 4194305 || return 1; [[ ! -p /dev/stdin ]] || cat > /dev/null; }
```
and the IMPORT_WORK_MAX comment: `passes this in all, so N adversarial files cost one bound, not N (U2a3b`.

The drain is correct: the fact-check verified that it stops the SIGPIPE false failure (its Claim 17). It is also far cheaper than main's lib, which sent the whole blob through sed and awk. But it makes git inflate the whole blob, at about 0.7 s per GiB. Git stores one copy of identical content, so a single compressible blob can sit behind thousands of tree names. Each name costs about 0.2-0.75 s of drain plus about 0.9 s of @-less awk scan (the deferred L2-C7) and charges zero work. The `IMPORT_WORK_MAX` comment and the P2 closing row describe a walk-wide bound on the parser's charged work, and that part is accurate (fact-check Claims 12 and 33). The walk's wall time is a different matter: it is bounded only by IMPORT_OUT_MAX's name budget, which allows on the order of 10⁵ names. Of the three uncharged costs, F1 and L2-C7 are the larger ones. The drain is the one this branch added.

**Recommendation:** Charge each file's bytes read (at most 4,194,305) to the walk's work total, for example by having `import_targets` add `length($0)+1` per line to `work`. That bounds the drain and the deferred L2-C7 scan together: about 12 maximal files per walk. Optionally skip the drain for blobs over the cap by taking sizes from `git ls-tree -r -l` in the existing listing call, accepting status 141 only when the size exceeds the cap. At minimum, the comment and row 451 should say the bound covers charged parser work, not walk time.

#### F4. IMPORT_WORK_MAX is per walk: a caller that runs both walks over the same files spends up to two bounds

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:503-508`; both walks' `work=0` locals (`:742`, `:787`)
**Move:** Count the hidden multiplications
**Classification:** Micro (constant factor of 2) / Cold path, with no current caller of both
**Confidence:** High
**Legibility-target:** code comment
**Baseline:** fact-check Claim 5 measured one bound (a 3,600-component token) failing after 4.04 s, and a token just under it (work 47,823,900) passing after 3.73 s. Two walks give about 8 s. This is the fact-check's measurement, not mine.

Evidence (verbatim): `# Each walk also fails once the parser's work … passes this in all, so N adversarial files cost one bound, not N`.

Each walk starts at `work=0`, and the starts largely overlap: both read the checkout's instruction files. A gate that runs `imported_names` and `main_imports` therefore pays the adversarial bound twice. Today only `dev-cycle.sh` calls a walk, and only the tree walk. The cost becomes real at U2a4/U2b.

**Recommendation:** Either say "per walk; a caller running both pays up to twice" in the comment (and in the U2b bullet, which owns the caller contract), or keep a shared remaining-work global that both walks draw from. I would take the comment now and decide at U2a4.

#### F5. main_checkout re-forks plaindir for a directory it just checked as PATH: two realpath forks per prefix directory, not one

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:735-739`
**Move:** Question the cache
**Classification:** Micro (one fork per directory) / Cold path
**Confidence:** High
**Legibility-target:** code
**Baseline:** with every ancestor present as a plain directory, the realpath count was **1,001** at D=500 (6,490 ms) and 2,001 at D=1000 (33,547 ms) at HEAD. 3e58eb9c timed out at 300 s and main's lib at 200 s, both at D=500. Measured with `deep.sh … dirs`, 2026-10-07.

Evidence (verbatim): `  plaindir "$c" && return 2` (`:738`). PATH's own result is not put in MEMO, so the next prefix (`…/a/a`) re-checks `…/a` as an ancestor with a fresh `plaindir`. The count is 2D+1 rather than D+1. The test comment's "each directory once, plus each candidate's own check" describes exactly this, so it is accurate. It just leaves half the forks on the table. The dirs case is still a large improvement over both older libs (endorsement below), and F1's string cost dominates its time (33.5 s at D=1000).

**Recommendation:** When PATH is a plain searchable directory and main stores no link or gitlink there, set `mc_m[$PATH]=1` before returning 2. Fold this into F1's rewrite.

## Endorsements

- `capped_read` reads at most 4,194,305 bytes for every parsed input (checkout files in both walks and 100644/100755 blobs), and the drain stops the pipefail 141 false failure [fact-check: claim 17 — Verified]
- The memo cuts realpath forks in the test's walk from 102 (unmemoized) and 74 (3e58eb9c) to 18 [fact-check: claim 32 — Verified]
- With existing ancestor directories at D=500, the main walk takes about 6.5 s at HEAD, against over 300 s at 3e58eb9c and over 200 s on main's lib. The memo therefore closes L2-C6's fork cost for the present-directory case [unverified — submitted as claim]
- IMPORT_WORK_MAX is charged walk-wide in both walks and both main_imports parse arms, and a per-file mutant fails the test [fact-check: claim 33 — Verified]
- `lower_all` lower-cases the whole candidate batch in one `tr` under `nul_list`, so N1's fix adds no per-candidate fork [fact-check: claim 16 — Verified]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | main_checkout's top-down loop is O(D³) per token: 64 s at D=1950 vs 2.1 s on main | Medium | `scripts/lib/dev-cycle-read.sh:721-740,852` | High |
| F2 | 120000 arm reads link blob whole, twice: 58 s / 2 GiB RSS from 1.3 MB; L2-C5 row overstates | Medium | `scripts/lib/dev-cycle-read.sh:826-840`; `override-log.md:449` | High |
| F3 | capped_read drain and @-less scan are uncharged; the walk-time bound holds only for charged work | Low | `scripts/lib/dev-cycle-read.sh:703,823,503-508`; `override-log.md:451` | High |
| F4 | IMPORT_WORK_MAX is per walk; both walks pay up to two bounds (~8 s) | Informational | `scripts/lib/dev-cycle-read.sh:503-508,742,787` | High |
| F5 | PATH's plain-dir result not memoized: 2 forks per prefix dir | Informational | `scripts/lib/dev-cycle-read.sh:735-739` | High |

## Overall Assessment

The three carried items close what they were scoped to close. The reader is capped and drained for parsed blobs. The memo removes the per-prefix fork storm: in the present-directory case it beats both main and 3e58eb9c by more than 30×. The work bound is walk-wide. All of this is verified, and on a real repo (8,110 work units, 1.1-1.3 s) the branch costs nothing.

The closures cost something on two adversarial shapes. F1 is a regression the memo rewrite introduced: the top-down loop with absent ancestors unmemoized turns a deep token into an O(D³) bash loop. That loop is about 30× slower than main's lib, and no work budget stops it before about a minute. F2 is a pre-existing uncapped read that the L2-C5 closing row now claims is covered. Both are fixable in place, and neither indicates a structural problem. F1 is the most important, because its fix (bottom-up with full memoization) also absorbs F5. F3 suggests charging bytes read to IMPORT_WORK_MAX, which would also bound the deferred L2-C7 scan. None of this needs profiling beyond the timings here. A timed absent-ancestor test would pin F1's fix.

## Goal-Alignment Note

The goal is to land `feat/build-loop-u2a3c` once its loop is clean, and this review finds nothing that blocks that on real repositories. The two Medium findings are adversarial-input costs, and the main walk has no caller until U2a4/U2b. F1 is new in this branch and cheap to fix now: the fix is local to `main_checkout`, with the realpath test already in place. F2 and F3 mainly need the closing rows (override-log 449 and 451) to state the residue truthfully, so that U2a4/U2b do not inherit a "Fixed" that does not cover the 120000 arm or walk time. If the loop prefers not to change code in iteration 3, the minimal alignment-preserving move is to fix F1 and record F2/F3 as deferred rows with a revisit trigger of "first caller of main_imports (U2a4)".
