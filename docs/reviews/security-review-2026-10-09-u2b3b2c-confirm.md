Commit: 80a1720d

# Security Review — feat/build-loop-u2b3b2c (confirming pass of the final-pass fix range)

**Scope:** `git diff 007e867f..HEAD` (HEAD 80a1720d; commits 8da3dfd3, the fix batch C1-C3 and D1, and 80a1720d, a comment). Read whole in `scripts/lib/dev-cycle-read.sh`: root_copies, prompt_marks, outside_seeds, imported_names, main_imports, main_checkout, outside_proj, import_outside, prompt_bases, prompt_dir, import_readers, plus the walk doc block (`:700-786`). Also read: the changed tests in `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`, and the override-log rows the range adds. The rest of the branch is context only.
**Date:** 2026-10-09
**Based on:** my final-pass report `docs/reviews/security-review-2026-10-09-u2b3b2c-final.md` (Commit 007e867f) and the orchestrator's brief of what the batch claims. No code-fact-check report was supplied for this range.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

All probes ran in a scratch copy of the worktree (`cp -a` of `scripts/` and `test/`) under `/tmp/secc-u2c-*`. Each fixture was a throwaway repo under `$BATS_TEST_TMPDIR`, driven by a probe `.bats` file that uses the suite's fixtures and its `imps` helper. For before/after rows, the 007e867f lib (`git show 007e867f:scripts/lib/dev-cycle-read.sh`) was swapped in through a `PROBE_LIB` variable. The 16 `U2b3b2` tests in `build-loop-check.bats` pass serially on the scratch copy at HEAD.

## Trust Boundary Map

```
B1: [other reader root's file tree (a loop's own worktree)] → [root_copies: outside_ok / -L / ! -e, realpath -m, sha1sum, rx skip] → [walk queue: ROOT/NAME or //ROOT/NAME]
B2: [dangling prompt link, or a missing copy below a linked directory] → [//PATH entry → outside_proj realpath -m → prompt_marks → RQ] → [repo names re-read with pdir/pext]
B3: [live prompt link (C1 or config seed)] → [import_outside; IMPORT_WHOLE projection] → [projected repo name, read plain] (unchanged; final F3 deferred)
B4: [ROOT_REAL checkout (clean at MAIN_SHA, contract item 2)] → [rawfile test + sha1sum] → [equal-bytes skip of a copy]
B5: [worktree registry + caller roots] → [import_readers: spelled and real paths] → [IMPORT_ROOTS, IMPORT_OTHER (real paths)] → [rx parent test (new)]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | another registered worktree's files, links and directory links | runtime-mutable (a loop writes its own worktree at any time) | UNTRUSTED for import-set decisions (path, kind, skip) and for availability |
| S2 | dangling or live prompt links, and the projected `//ROOT/NAME` entries | runtime-mutable | UNTRUSTED for path and kind decisions |
| S3 | ROOT_REAL's file bytes | deploy-time per decision (item 2) | trusted for the byte-equal comparison under item 2 only |
| S4 | worktree registry and IMPORT_READER_ROOTS | runtime-mutable (registry) / caller-supplied | UNTRUSTED for root completeness; trusted as the reader-root set for the rx parent test |
| S5 | parser output names (repo-relative, `//`) | derived from S1/S3 text | UNTRUSTED for path construction; repo-relative join only |

**What the range changes at the boundaries.** C1 adds a feedback edge on B2: names prompt_marks re-marks go back onto the queue being walked. C2 widens B1's fallback from final-component links to any missing copy whose real path differs. C3 narrows B1 with a per-root skip keyed on IMPORT_ROOTS (S4).

## Findings

#### 1. The C1 re-read turns one more hostile-worktree layout into a failed main walk (fail-closed; within final F4's named class)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1723-1727` (re-read loop), `:1690-1692` (the 120000 arm)
**Boundary:** B2
**Move:** 3, 8; executed
**Confidence:** High

**Evidence:**
```
    for p in "${rq[@]}"; do
      [[ -n "${seen[$p]+set}" ]] || continue
      c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?
      [[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }; [[ $c -ne 0 ]] || queue+=("$p")
    done
```
```
        [[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }
```

Probe PE2 has two parts:
- Main stores `docs/l.md -> t.md`, and AGENTS.md imports `docs/l.md`.
- Side removes `docs/l.md` and plants a dangling `.claude/commands/k.md -> ../../docs/l.md`.

| Lib | Tree walk | Main walk |
|---|---|---|
| 007e867f | ok, `docs/t.md: -`, `top.md: -` | ok, `top.md: -` (fail-open) |
| HEAD | ok, `docs/t.md: -`, `top.md: -` | **failed** |

The re-read gives the already-read link name prompt bases, and the 120000 arm refuses it. The walk doc names this exception (`:756-757`: "one main stores as a symlink fails the main walk"), and final F4 predicted it. It is the accepted class in which one loop's worktree can hold every self-merge back (i1 F3). The change trades a fail-open answer for a fail-closed one. The tree walk's `-` answer predates this range (its inrepo_here does not follow the link), and the gate does not rely on it.

**Recommendation:** None. Keep the named exception.

#### 2. Final F3 (a live prompt link's projected name read plain) is still open, as deferred

**Severity:** Medium (not a regression; carried from final F3)
**Location:** `scripts/lib/dev-cycle-read.sh:1205` (import_outside's projection), `:1588`, `:1718` (prompt_marks gated on `//`)
**Boundary:** B3
**Move:** 11; executed
**Confidence:** High for the mechanism

**Evidence:**
```
  if [[ "$r" != "$1" ]]; then b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" && import_work b w || return 1; fi
```

Probe PC re-run at HEAD:
- Main's `docs/t.md` holds `@top.md`, and side (at the older commit) holds `docs/t.md` = `old` with a live `.claude/commands/k.md -> ../../docs/t.md`.
- Both walks answer `top.md: -` and `docs/top.md: imported`.

The range does not touch this path. The deferral is recorded in the override log ("Defer (routed to U2c)", the row the range adds) and named in the walk header (`:767-769`). It is listed here so the confirming pass does not read as an all-clear for B3.

**Recommendation:** Keep the U2c routing. The fix shape in final F3 is unchanged: run prompt_marks over the IMPORT_WHOLE projection of an absolute `pdir` entry whose real path differs, then apply this range's re-read.

## Untested bypass candidates

- **A missing copy whose `realpath -m` errors** (for example, a projected path past PATH_MAX built through a link with very long target text). The error fails the walk (fail-closed). My attempt to plant such a link failed with ENAMETOOLONG at `ln`. Other variants returned normally with rc 0: a 45-link chain, a `docs -> docs` loop, a two-link loop, a mode-000 directory, and a plain file used as a directory component.
- **A copy swapped between root_copies' `-e`/`-L` tests and its realpath batch**, or between the batch and outside_proj's second realpath. This is the documented point-in-time class. Traced, not run.
- **A worktree spelled below `.claude/commands/` through a link whose real path has no `.claude`** (C3-linkrev). git recorded the real path. The equal-bytes prompt copy was skipped (no rx), but `docs/z2.md` was still imported through outside_seeds' ancestor `.claude` config dir. I did not isolate whether some other spelling, one that git or a caller root keeps spelled, could lose the base. Both rx and the read use the real path (`$r/$p` with `r` from IMPORT_OTHER), so the skip and a read agree. Any loss would predate C3.

## Endorsement Claims

- **Claim:** Final F1 is fixed. A name a dangling prompt link projects is re-read with the link's bases in both walks, whether the walk first read it plain (PA), as a start (PB), or as a prompt with other bases (PG).
  **Location:** `scripts/lib/dev-cycle-read.sh:1329-1339`, `:1588-1590`, `:1718-1727`
  **Evidence:** executed
  **Verified:** PA, PB and PG give `imported` for all three names in both walks at HEAD, and `-` for most of them on the 007e867f lib (tree walk: `topc.md` and `sub/top2.md`; main walk: all three). The new test at `build-loop-check.bats:801` is green. Variant PB-untracked: a checkout start main lacks, read in phase 2 before the `//` entry, gives `top.md: imported` in both walks (`-` on 007e867f), which exercises the main_checkout 0 arm of the re-read.
  **Not verified:** a name whose main_checkout answer changes between its first admission and the re-read (a checkout edited mid-walk; the point-in-time class).
  **route: code-fact-check**
- **Claim:** The re-read is bounded. prompt_marks appends a name to RQ only when PDIR lacks it or its PEXT entry lacks this link's base string. Each `//` entry is popped once (seen), and prompt_marks skips absolute names, so no `//` entry is re-queued.
  **Location:** `scripts/lib/dev-cycle-read.sh:1335-1337`, `:1590`, `:1726`
  **Evidence:** executed
  **Verified:** In probe PM, 60 dangling prompt links in distinct nested `.claude/` directories all point at one name. Both walks end `ok` in about 2 s, with `top.md`, `n7/top.md` and `n60/top.md` imported. Re-reads go through the normal read path, so they are charged to `used`/`work`.
  **Not verified:** the walk time with thousands of such links (bounded by links × names, and by IMPORT_WORK_MAX, fail-closed).
- **Claim:** A re-read name main lacks that main_checkout answers 2 for is skipped without failing the walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:1724-1726`
  **Evidence:** executed
  **Verified:** In probe PN, a dangling prompt link names `docs/none.md`, which no tree holds: both walks end `ok`.
  **Not verified:** a main_checkout 1 at the re-read for a name that answered 0 or 2 at first admission (it would fail the walk, fail-closed).
- **Claim:** Final F2 is fixed. A missing copy below a live or dangling linked directory, including a dangling link on a deeper component, is projected to the repo path its real path names.
  **Location:** `scripts/lib/dev-cycle-read.sh:1297-1308`
  **Evidence:** executed
  **Verified:**
  - The extended test at `build-loop-check.bats:777` is green.
  - PD-deep: side holds `docs -> real` and `real/sub -> ../gone`, and both walks import `gone/a.md` and its import `gone/gz.md`.
  - PC2: a prompt copy missing below `.claude/commands -> ../cmds2` is projected and read as a prompt, so `cmds2/k.md` and its `@top2.md` are imported in both walks. Both were `-` on 007e867f.
  **Not verified:** a missing copy below a directory link whose real path leaves every reader root and lands under a reader home (traced: projected as `//PATH`, then outside_ok).
  **route: code-fact-check**
- **Claim:** C2 adds no walk failure for a planted link loop, an unsearchable directory, or a root lacking every reached name.
  **Location:** `scripts/lib/dev-cycle-read.sh:1299`, `:1304`
  **Evidence:** executed
  **Verified:**
  - **Link loops.** PD-loop (`docs -> docs`, and a two-link loop) gives `walk: ok` in both walks. GNU `realpath -m` returns the spelled path, so nothing is projected.
  - **Unsearchable directory.** PD-priv (a mode-000 directory) fails both walks, but at c1_seeds' `find` ("Permission denied"), the named fail-closed class (walk doc `:772-774`). It does not fail at the new realpath, which returns rc 0 there.
  - **Root lacking every name.** PD-big (400 names, 3 roots lacking `docs/`) costs 4.0-4.2 s against 3.2-3.3 s on 007e867f for the tree walk, and about 3.1 s against 2.5-3.8 s for the main walk, with both walks `ok`.
  - **Refused projection.** PD-refuse (side `docs -> ml`, a plain directory where main stores `ml` as a symlink) fails the main walk at HEAD through main_checkout's refusal of the projected `ml/a.md`. The same layout fails on 007e867f too, at the 120000 arm for the prefix name `ml`. The dangling-file-link route (PD-refuse-filelink) fails at both commits. So C2 opens no new fail-closed class.
  **Not verified:** a realpath error other than these (Untested candidates).
- **Claim:** C3's skip drops an equal-bytes prompt copy only for a root whose every `.claude` ancestor component (case-folded) has a reader root as its parent. In the layouts probed, that parent's top level is one the parser already resolves against.
  **Location:** `scripts/lib/dev-cycle-read.sh:1289-1293`, `:1306`
  **Evidence:** executed
  **Verified:**
  - C3-case: a worktree below `$h/.CLAUDE/wt` has an upper-case component, `${c,,}` matches it, and prompt_bases sees it through the lower-cased pdir value. Both walks import `docs/z2.md`.
  - C3-link: a worktree registered through `$h/alias -> .claude`; git records the real path, rx sees `.claude`, and both walks import it.
  - C3-rootparent: a worktree at `ROOT_REAL/.claude/wt` is skipped, with `z.md: imported`. The `.claude/wt/z.md` answer is the same (`-`) on 007e867f, so the skip loses nothing there.
  - IMPORT_ROOTS holds both spelled and real forms of every root (`import_readers:1135-1137`), and IMPORT_OTHER holds real paths only (`:1134`), so the parent prefix is compared in canonical form against a list that contains it.
  **Not verified:** a parent that is a reader home but no reader root (it gets rx, so it is read: an over-read); and the C3-linkrev spelling question under Untested.
  **route: code-fact-check**
- **Claim:** The reverted `outside_seeds` has the same body as f7e1bea2's, which i1 reviewed.
  **Location:** `scripts/lib/dev-cycle-read.sh:1376-1462`
  **Evidence:** executed
  **Verified:** `diff` of the awk-extracted function bodies at f7e1bea2 and HEAD is empty. Only the comment above the function differs. `dev-cycle.bats` drops `config_seeds` and `c1_seeds` from its function list to match.
  **Not verified:** callers of the removed helper names outside `scripts/lib` and the two suites (none found in the diff).

## Primitive sweep

Primitive: path construction plus file read, hash and realpath over paths built from S1, S2 and S5. The table covers the call sites in the range.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1291-1292` rx: `read -a` split of each IMPORT_OTHER root, `${c,,}` | S4 | real paths, newline-free (import_readers) | cleared (Endorsement 6) |
| `:1297` `outside_ok "$r/$p"` | S1, S5 | `p` not absolute or `//` | cleared |
| `:1298` `-L "$r/$p"` → `//` queue | S1 | final-component test | cleared (unchanged) |
| `:1299` `! -e "$r/$p"` → ms | S1 | none needed (the realpath decides) | cleared (Endorsement 4, 5) |
| `:1304` `xargs realpath -mz` over ps, cs, ms | S1, S5 | `--`, batching, count check `2n+m` | cleared; error is fail-closed |
| `:1308` `//ROOT/NAME` for a differing real path | S1 | realpath comparison | cleared; refused projections fail closed (Endorsement 5) |
| `:1306` C3 skip test | S1, S3, S4 | rawfile both sides, sha1sum, rx | cleared (Endorsement 6) |
| `:1311` `xargs sha1sum -z` | S1, S3 | `--`, batching, count check | cleared; point-in-time (Untested) |
| `:1315` `lower` of a `//ROOT/NAME` pdir key | S1 | none needed | cleared |
| `:1331-1337` prompt_marks: `prompt_bases` on the link path, RQ append | S2 | skips absolute names; dedupe on PEXT | cleared (Endorsements 1, 2) |
| `:1590` tree re-read `queue+=` | S2 | seen | cleared |
| `:1723-1727` main re-read: main_checkout, `queue+=` | S2 | seen, main_checkout 0/1/2 | cleared; 120000 arm Finding 1 |
| `:1205` import_outside projection (unchanged) | S2 | none for kind | Finding 2 (deferred F3) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Re-read of an already-read name main stores as a symlink fails the main walk (PE2; fail-closed, named) | Informational | B2 | `dev-cycle-read.sh:1723-1727,1692` | High |
| 2 | Final F3, a live prompt link's projected name read plain, still open as deferred (PC) | Medium (not a regression) | B3 | `dev-cycle-read.sh:1205,1588,1718` | High |

## Overall Assessment

The fix batch closes the two Medium findings it targeted:
- **Final F1** is fixed in both walks. PA, PB, PG and a phase-2 variant all turn from `-` to `imported`. The re-read is bounded by per-link deduplication and the walk budgets, and it handles main_checkout's 0, 1 and 2 answers as the first admission does.
- **Final F2** is fixed. A missing copy below a live or dangling linked directory, including a deeper dangling component and a prompt copy, is projected. Link loops and an unsearchable directory do not fail the walk through the new realpath, and the added cost is linear and modest.

C3's skip held against the probed spellings: an upper-case `.CLAUDE`, a root registered through a link, and a parent that is ROOT_REAL. It compares canonical prefixes against a root list that holds canonical forms. The outside_seeds revert is byte-identical to the reviewed body. Two items remain:
- **Finding 1** is the predicted fail-closed widening of final F4. It is named in the walk doc.
- **Finding 2** is final F3, carried and deferred to U2c with an override row and a named exception.

No new fail-open edge was found in the range. Outside these findings: no findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/security-review-2026-10-09-u2b3b2c-confirm.md, structured per the security-reviewer skill, with `Commit: 80a1720d` as its first line."
- **Answered:**
  - PA, PB and PG were re-run against HEAD: all imported in both walks (Endorsement 1).
  - PD was re-run with deep, loop, refuse, unsearchable-directory and big variants (Endorsements 4, 5).
  - PG passed, and PC (deferred) is still open (Finding 2).
  - F1 and F2 are confirmed fixed.
  - **C1 completeness:** the re-read covers both walks, names never seen (handled by the normal name loop), main_checkout 1 and 2, and termination (Endorsements 1-3).
  - **C2 bypass and failure modes:** probed (Endorsements 4, 5; Untested).
  - **C3 skip spellings:** probed (Endorsement 6).
  - **The outside_seeds revert:** verified identical (Endorsement 7).
- **Out of scope:** comment and test-title drift the fact-check owns; the four review-report files the range adds.
- **Escalate:** none.
- **Decisions:** none new. Finding 2's deferral to U2c stands as the orchestrator recorded it.
