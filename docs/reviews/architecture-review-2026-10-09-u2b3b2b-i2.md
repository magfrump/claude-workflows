Commit: 39f64d62

# Architecture Review — feat/build-loop-u2b3b2b (U2b3b2b, iteration 2)

**Scope:** `git diff 1c820663..39f64d62`, the iteration-1 fix commit. It touches `scripts/lib/dev-cycle-read.sh` (new `root_starts`, `outside_seeds`' @ filter and C1 phase, the seed loops' `pdir`, `IMPORT_MANAGED_DIR`, contract item 4, the lib, walk, `import_outside` and `outside_ok` headers), two test files, the plan and the override log. Commit 1c820663 is context only.
**Date:** 2026-10-09
**Based on:** shared brief u2b3b2b-i2/shared.md; iteration-1 rubric and reports (`*-2026-10-09-u2b3b2b.md`, `code-fact-check-report-build-loop-u2b3b2b.md`). No iteration-2 fact-check was supplied. Behaviour cited below was probed (prefix `/tmp/u2b3b2b-aa2-`, removed) or read in full.

Scope check: in scope. The commit adds a lib function (`root_starts`), renames a module global (`IMPORT_MANAGED_DIR`), changes `outside_seeds`' contract (a new return-1 case, the @ filter), and edits the caller contract (item 4).

Trust-boundary cross-reference: the most recent security review is `docs/reviews/security-review-2026-10-09-u2b3b2b.md` (Commit: `1c820663`, the review base of this fix range). Its `B1` is "[other reader roots' working trees (find -P)] → [isstart + same-bytes skip + outside_ok] → [walk seeds (C1)]". Its `B2` is "[config dirs ...] → [find -L / find -H -xtype f + isstart] → [walk seeds]". The fix commit adds the @ filter at both transition points, and Findings 1 and 2 sit on them.

## Iteration-1 findings: verification

| i1 finding | Rubric | Verdict |
|---|---|---|
| 1: the C1 skip re-derived the walks' start admission (A1) | Fixed | **Fixed to the minimum recommendation.** The skip now needs `! -L` on the seed and `rawfile` on ROOT_REAL's copy (line 1314), and the header names contract item 2 as the main walk's precondition (lines 1229-1231). `rawfile` (line 160) needs ROOT_REAL's copy to be its own real path, which is no weaker than the tree walk's `inrepo_here`. The structural part (a third copy of "what the walk starts at", in a shared function) remains, as iteration 1 rated it. It is now documented and not shown to change an answer. The C1 test's symlinked `CLAUDE.md` → `docs/v.md imported` passes for both walks. |
| 2: "outside" now covers peer-root files (K13) | Fixed | **Fixed.** The `import_outside` (lines 1153-1154) and `outside_ok` (1184-1185) headers now name an outside_seeds start "which may lie in another root". Per the cross-reference rule: `B1`'s source set already lists other roots' trees, so the security map has caught up. |
| 3: config dirs outside the cache keys and item 4 (A5) | Fixed in part; rest deferred | **Item 4 fixed** (lines 68-74, accurate). Folding config dirs into `import_readers` is deferred by an override row. The row's basis is unchanged. |
| 4: outside_seeds' size and index-coupled arrays (K12) | Defer (override row: "Line cap; behaviour is covered by tests") | **Basis weakened**: see Finding 2. The `rel`/`abs`/`nt` index coupling is gone (replaced by `cx`/`kx`, which is better). But the function grew to 78 lines (1244-1321), and the phase-shared state now hides a skipped invariant that the tests do not see. |
| 5: admission repeated; spelled LP (A4/K12) | LP Fixed; rest deferred | **LP fixed** (lines 1432, 1513). Both loops lower the path and fail the walk on a failed `lower`, as the checkout loop does (1423). |
| 6, 7 | none / deferred | Unchanged. |

## Dependency Map

- `imported_names` / `main_imports` → `import_readers` → `outside_seeds` → {`root_starts` (new) → `find -P`, `instruction_names`}, `isstart`, `rawfile`, `lower_all`, `nul_list`, `outside_ok`, and external `find`, `xargs`/`sh`/`grep`, `realpath`, `sha1sum`, `python3`.
- `root_starts` is a leaf with the same shape as `tree_starts` (a listing piped into `instruction_names`). That puts the "listing plus start-name prefilter" pattern in one place for each source: git for the checkout, the file system for peer roots. Dependencies still point from the walks down to the leaves. Nothing new depends upward.
- New lateral dependency: `outside_seeds`' @ filter depends on a property of `IMPORT_AWK` (`scan` yields a candidate only after an `@` byte, line 941), and on `import_outside` being the only other path that can yield a name from a seed (projection of its real path when that differs). Finding 1 covers this.

## Findings

#### 1. The @ filter encodes a parser invariant (names arise only after an @ byte) in the seed producer, with no cross-reference or test tying the two

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1286-1291` (config phase), `:1308-1311` (C1 phase), `:1234-1236` (header); invariant source `:941` (`scan`)
**Move:** 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** outside_seeds' header and the comment above `scan` in IMPORT_AWK

Evidence:
```
# (core.fsmonitor runs a command). Only a seed holding an @ byte or reached
# through a link (import_outside projects its real path) can yield a name, so
# the rest are dropped (i1 performance F1); an unreadable file is skipped, as
```
```
    if (substr(line, i, 1) != "@") continue
```

The filter is correct today. Under LC_ALL=C (contract item 1), `scan` starts a candidate only at an `@` byte. The UNI_SPACES rewrite produces blanks, never `@`. Projection of a link's real path is covered by the link test (realpath differs in the config phase, `-L` in C1). But the rule now lives in two modules: the parser, and a seed producer three calls away that drops files on the strength of it. `instruction_names` has the same shape, a prefilter mirroring an authority, and it says so in its header: "It matches isstart's names; isstart stays the authority". `IMPORT_AWK` has no matching note that a seed filter relies on its `@` trigger. Suppose a later parser change starts yielding names without an `@` byte: a decoded full-width ＠, a new mention syntax, or a front-matter key. That change would silently drop seeds, and no test would see it. A seed with no `@` passes vacuously.

**Recommendation:** Add one line above `scan` ("a candidate starts only at an @ byte: outside_seeds' @ filter depends on it"). Add a test that a seed with no `@` but a link on the way still yields its projected name, which pins the link half of the rule. That half is pinned today only through the C1 symlinked-CLAUDE.md case.

#### 2. outside_seeds' phase-shared state now skips a documented invariant: the early C1 return bypasses the final newline check, and `os_at`/`fl` carry over between phases

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1244-1321`, specifically `:1288-1289`, `:1303`, `:1308-1309`, `:1320`
**Move:** 2 (responsibility boundaries), 7 (coupling inside the function)
**Confidence:** High (the newline path was probed; the carry-over was read)
**Legibility-target:** outside_seeds, and the override row for i1 architecture 4/5

Evidence:
```
  [[ ${#cx[@]} -eq 0 ]] || nul_list fl xargs -0r -a <(printf '%s\0' "${cx[@]}") sh -c 'grep -lsZF -e @ -- "$@"; [ $? -le 2 ]' sh || return 1
  for d in "${fl[@]}"; do os_at[$d]=1; done
```
```
  [[ ${#cx[@]} -gt 0 ]] || return 0
```
```
  for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done
}
```

Two seed sources now go through one pipeline (`cx` → @ filter → `os_at` → admission), run twice with state shared between the runs:

- **Early return.** The `return 0` added for "no C1 candidate" exits before the newline check, which guards the config seeds too. Probe: a home rule file named `a\nb.md` holding `@x`, single repo, gives `outside_seeds` → `rc=0` with the newline seed. Add a sibling worktree holding an @ start and the result is `rc=1`. The walks still fail, because `import_outside` refuses a newline real path (line 1171). So this is not fail-open, but the test "both walks fail closed when ... a seed's name holds a newline" now passes through a different module's guard.
- **Carry-over.** When the config phase finds no candidate, `[[ ${#cx[@]} -eq 0 ]] || nul_list fl ...` leaves `fl` holding the previous listing (the `find -H` top-level files, or the plugin install paths). The next line still loads that into `os_at`. `os_at` is not cleared before the C1 phase, so a C1 file whose path equalled one of those entries would be admitted as "holds an @". That cannot happen today, because C1 files lie below roots and those entries do not. Even if it did, the result would be a superset. But it is the same index and array-reuse coupling iteration-1 Finding 4 described, now spread across `fl`, `rl`, `lo` and `os_at`.

The override row deferring the split rests on "behaviour is covered by tests". The early-return case shows a documented return-1 condition that the tests no longer reach. That weakens the row's basis, though it does not overturn the deferral.

**Recommendation:** In this unit, move the newline check to just after the config phase's `os_a` loop (line 1291), or turn the early return into a skip of the C1 block. Clear `os_at` (or guard its fill with the same `cx` test) between phases. Keep the split deferred, but amend the override row's rationale to say that the phase boundary is where defects land, so U2c or U2b3b2c should split `config_seeds` from `peer_root_seeds` first.

#### 3. The @ filter's xargs/grep wrapper is inlined twice beside the new `root_starts` helper

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1288`, `:1308`
**Move:** 8 (extension points)
**Confidence:** High
**Legibility-target:** a named helper beside `root_starts` / `instruction_names`

Evidence (both lines): `nul_list fl xargs -0r -a <(printf '%s\0' "${cx[@]}") sh -c 'grep -lsZF -e @ -- "$@"; [ $? -le 2 ]' sh || return 1`

The fix commit extracted the listing half of the C1 phase into `root_starts`, but left the other new primitive inlined at both of its uses. That primitive is "which of these files hold an @", with its grep exit-status policy. Its error policy (status 2 is a skip) is the part reviewers questioned (shared brief claim 2; API i2 F1). As things stand, a change to that policy must be made twice, identically.

**Recommendation:** Extract `at_files` (NUL in, NUL out), with a header stating its status rule, and call it from both phases. This costs about two lines and fits the line cap.

## What Looks Good

- `root_starts` is the right cut. It copies `tree_starts`' shape (`local -; set -o pipefail; listing | instruction_names`), so the two start sources, git and the file system, differ only in their listing. It moves the prefilter ahead of `isstart`, which is the performance fix, without a new authority: isstart still decides, on the innermost-root path.
- `rel`/`abs`/`nt` (index-coupled by position) have been replaced by `cx`/`kx` (parallel arrays built together) and a per-candidate `ir`. This removes the `$i -lt $nt` guard that iteration 1 flagged as reorder-fragile.
- The `IMPORT_MANAGED_DIR` rename puts the global in the `IMPORT_*` family of walk inputs that contract item 4 governs. Item 4 now names every uncached walk input. The reader model still has two homes (`import_readers` and `outside_seeds`), but the contract now states that.
- The prompt-seed fix keeps the `p` tag as the single prompt decision for seeds. That is necessary for `plugins/cache`, which `PROMPT_DIR` does not match. It also applies contract item 8 at the one point where the path enters `pdir`.
- U2b3b2c was split out by name, with its mechanism and evidence (6,720 seeds) recorded, rather than bolted onto this unit.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | @ filter relies on IMPORT_AWK's @-byte trigger with no cross-reference or test tying the two | Minor | `scripts/lib/dev-cycle-read.sh:1286-1291, 1308-1311, 941` | Medium |
| 2 | Early C1 `return 0` bypasses the newline invariant; `fl`/`os_at` carry over between phases; weakens the split deferral's "covered by tests" basis | Minor | `scripts/lib/dev-cycle-read.sh:1288-1289, 1303, 1320` | High |
| 3 | The @-filter wrapper is inlined twice beside the new `root_starts` helper | Informational | `scripts/lib/dev-cycle-read.sh:1288, 1308` | High |

## Overall Assessment

The fix commit keeps the lib's structure sound and improves it in two places. `root_starts` mirrors `tree_starts`, and the positional `rel`/`abs` split is gone. Every iteration-1 architecture finding marked Fixed is fixed. The deferred ones keep their basis, except Finding 4's, which the new early return weakens. No finding is Structural or Coupling. The most important structural point is Finding 2. `outside_seeds` now runs the same filter pipeline twice over shared arrays, and the fix commit's own early return slipped past a tail invariant. The walks are backstopped by `import_outside`, so nothing fails open. But this is the kind of defect the deferred split is meant to prevent, and a two-line reorder fixes it in place. I have no disagreement with the security review's boundary placement.

## Goal-Alignment Note

The user goal is to land U2b3b2b after a clean review-fix loop. Nothing here blocks the unit: both walks still start at every seed class and fail closed in every probe I ran. Finding 2's reorder and Finding 3's helper are small edits that fit the line cap. Finding 1 is a comment plus an optional test. The override row for the function split can stay deferred with an amended rationale. Timings and suite counts (claim 6) are the fact-check's to verify.
