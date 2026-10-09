Commit: 3908e37e

# Security Review: feat/build-loop-u2b3b1 (U2b3b1, the reader settings), iteration 3 confirming pass

**Scope:** `git diff f56ba3f5..3908e37e` (the final pass's fix commit). Code: scripts/lib/dev-cycle-read.sh (import_readers' two-way G8 loop, the reader_settings no-main WHY, the floor text, comments), scripts/dev-cycle.sh (check_fix text, header), docs/dev-cycle.md (both spellings), three bats files, plan line 301. Earlier commits are context only.
**Date:** 2026-10-09
**Role:** sec-confirm. Threat model: main's commit is the trust anchor; a hostile same-uid loop writing refs or the worktree registry is a Q-103 residual (override rows already settle it).
**Based on:** the iteration-2 security report (docs/reviews/security-review-2026-10-09-u2b3b1-final.md: F1 and F2 are what 3908e37e fixes) and the iteration-2 rubric. No fact-check of 3908e37e was supplied, so the claims below rest on my own reading and probes.

## Trust Boundary Map

```
B1: [main's docs/dev-cycle.md "Reader roots:/Reader homes:"] -> [main_file + SETTINGS_AWK -> reader_settings -> readerform] -> [IMPORT_READER_ROOTS/HOMES or IMPORT_READER_WHY]
B3: [worktree registry (git worktree list), written by container AND host sessions] -> [import_readers: rs_m = first record + every caller root; two-way re-spelling] -> [IMPORT_ROOTS -> parser projection]
B4: [the host the walk runs on (ROOT_REAL, HOME)] -> [which spellings of the repository count as readers]
```
S1 (main's reader lines): deploy-time, trusted for reader modelling, restricted to NAMECHARS with no empty, `.` or `..` part, and not `/` alone (readerform, lib:578-582). S3 (registry): runtime-mutable, untrusted for choosing roots. Every registry path goes only into string-prefix tests, which are quoted (literal), and into `realpath -mz` as an argv element. No registry path reaches eval, a glob or a pattern.

## Did 3908e37e fix iteration 2's F1 and F2?

- **F1 (a walk run on the host drops `@/workspace/...`).** Fixed in data. docs/dev-cycle.md:24 now reads `Reader roots: /home/magfrump/claude-workflows /workspace` and :26 reads `Reader homes: /home/magfrump /home/node`. On either side, the other side's spelling is now a caller root. The read test expects `readers 2-roots 2-homes set` (build-loop-read.bats:78), and it passes.
- **F2 (a host-registered worktree beneath a caller root is not re-spelled under main).** Fixed. lib:1027-1031:
  ```
    [[ ${#rs_w[@]} -eq 0 ]] || rs_m=("${rs_w[0]}")
    [[ -z "$IMPORT_READER_ROOTS" ]] || mapfile -t rs_c <<<"$IMPORT_READER_ROOTS"
    rs_r=("$ROOT_REAL" "${rs_w[@]}")
    for rs_cr in "${rs_c[@]}"; do [[ -z "$rs_cr" ]] || { rs_r+=("$rs_cr"); rs_m+=("$rs_cr"); }; done
    for p in "${rs_w[@]}"; do for rs_cr in "${rs_m[@]}"; do [[ "$p" != "$rs_cr"/* ]] || for t in "${rs_m[@]}"; do rs_r+=("$t${p#"$rs_cr"}"); done; done; done
  ```
  I read import_readers whole (lib:1010-1061). Executed, probe `sec-confirm/p1.sh`: the new test at build-loop-check.bats:1896-1901 passes on the tip, and fails on a mutant that restores the one-way loop. The failure line is `want: docs/n.md: imported` / `docs/n.md: -` at line 1900. The test therefore guards the fix.

## Two-way loop edge cases (executed, probe `sec-confirm/p2.sh`)

The probe used a repo at `$T/repo`, worktrees `.claude/wt-a` (beneath main), `$T/host/cw/.claude/wt-h` (beneath a caller root) and `$T/host/cw/sub/wt-n`. It called import_readers directly.

| Case | Result | Reading |
|---|---|---|
| One caller root `$T/host/cw` | rc=0, 8 roots; wt-a is spelled under host/cw and wt-h under repo | both directions present |
| Caller root equal to the main record (plus host/cw) | rc=0, the same 8 roots | duplicate spellings are deduped by rs_seen; the only cost is extra realpath argv |
| Empty line in the caller list | rc=0, the same 8 roots | blank skipped at lib:1030 as before |
| Caller root `/` (bypassing readerform) | rc=1 | fails closed (lib:1037 `-n "${p//\//}"`); readerform refuses `/` earlier anyway |
| Nested aliases `$T/host/cw` and `$T/host/cw/sub` | rc=0, 14 roots, including `T/repo/wt-n`, `T/host/cw/wt-n`, `T/host/cw/sub/sub/wt-n` | spurious roots that no reader uses; see I1 |

Every result is a superset of the old loop's roots: each pair the old loop added (`s` = main record, `t` = a caller root) is one of the pairs the new loop adds. Within the paths I read, no edge case gives a fail-open.

**Can a registry entry now add a root that hides names, dotnest aside?** Not that I found. The new loop re-spells a registry entry only beneath another spelling of the main worktree, and the result is just another root. The parser drops a name relative to an outer root only through dotnest, and only when the path from the outer root down to the nested root has a dot component. Such a name, read relative to the outer root, carries that dot component, which truthrule's dot word already refuses. Under my reading, the new roots (including the spurious nested-alias ones) can only add names. Not verified: I did not re-read the parser's dotnest code in this pass. This relies on iteration 2's reading and the import_readers comment at lib:986-987 ("a root can add names and hide only dot paths").

**Does a reader go under-modelled?** On the container: main record `/workspace`, caller roots `/home/magfrump/claude-workflows /workspace`. On the host: main record `/home/magfrump/claude-workflows`, caller roots the same two paths. In both cases the two-way loop spells every registered worktree beneath both checkout spellings, and both HOMEs are listed. Two gaps remain, and both sit outside this commit: readers outside every root (user memory, managed policy, and other roots' checkout-only starts) belong to U2b3b2 by the plan split, and a hostile registry rewrite is a Q-103 residual (settled rows).

## Findings

#### I1. Nested reader roots make the two-way loop add cross-nested roots that no reader uses

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1031`
**Boundary:** B1, B3
**Move:** 5 (invert the model), 6 (edge cases)
**Confidence:** High (executed: p2.sh "nested aliases")
**Legibility-target:** the import_readers comment (lib:975-978) or readerform's rule list (docs/dev-cycle.md:24-31)

Evidence (lib:1031):
```
  for p in "${rs_w[@]}"; do for rs_cr in "${rs_m[@]}"; do [[ "$p" != "$rs_cr"/* ]] || for t in "${rs_m[@]}"; do rs_r+=("$t${p#"$rs_cr"}"); done; done; done
```
Suppose main names two caller roots and one lies beneath the other (`/h/cw` and `/h/cw/sub`). A worktree under the inner root matches both spellings. The loop then also yields roots such as `<main>/wt-n` and `/h/cw/sub/sub/wt-n`, which no reader spells. The probe went from 8 roots to 14. These roots only add names (an over-refusal), so nothing fails open. They do spend the work bound faster, which the settled no-cap override row already covers. readerform does not refuse nested reader roots, and the two roots in this repo's settings are not nested, so nothing here is reachable today. Recommendation: none required. If wanted, the readerform rules could refuse a root beneath another listed root, but that adds lines against the 400-line cap.

#### I2. Contract item 9's new clause "or after it" has no clear referent

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:90-92`
**Boundary:** Internal, no boundary (caller-contract text)
**Move:** 2 (implicit assumption)
**Confidence:** Medium
**Legibility-target:** contract item 9

Evidence:
```
#     which fails both walks; both scripts call it. Never set these from the
#     environment or after it, nor
#     IMPORT_ROOTS or IMPORT_HOMES: they are import_readers' results.
```
"it" could mean the environment or reader_settings. The intended rule is probably "set these only through reader_settings, never from the environment and never after reader_settings runs", and the text does not say that clearly. This is not exploitable: sourcing the lib clears the lists, and the memo key covers both lists, so a late change is seen rather than hidden. Recommendation: "Never set these yourself (from the environment or after reader_settings), nor IMPORT_ROOTS ...".

### Endorsement Claims

- **Claim:** The two-way loop's root set is a superset of the one-way loop's on every input that the old loop accepted.
  **Location:** `scripts/lib/dev-cycle-read.sh:1027-1031`
  **Evidence:** read-static, plus executed on 5 cases (p2.sh)
  **Verified:** I compared the two loops' text. The old pairs (main record to caller root) are the subset of the new pairs where s is the main record. The probe covered 5 caller-list shapes.
  **Not verified:** caller lists with more than two entries combined with a main record that is itself beneath a caller root.
  **route: code-fact-check**
- **Claim:** The new G8 test detects a revert to the one-way loop.
  **Location:** `test/scripts/build-loop-check.bats:1896-1901`
  **Evidence:** executed (p1.sh: passes on the tip, fails on the mutant)
  **Verified:** I ran the test against both libs on a copy of the branch.
  **Not verified:** the `main` walk mode's failure on the mutant: the run stopped at the first failing `want` (tree mode, line 1900).
- **Claim:** The suites pass at the tip.
  **Evidence:** executed (p3.sh on a copy of the branch): build-loop-check 117/117, build-loop-read 20/20, dev-cycle 79/79 (216 tests; the commit body's 220 presumably counts other files).
  **Verified:** those three files only.
  **Not verified:** the other suites under test/.
- **Claim:** The new walk-failure texts interpolate only IMPORT_READER_WHY, whose texts are fixed strings plus line and entry numbers. Path content does not appear in them.
  **Location:** `scripts/lib/dev-cycle-read.sh:599,1415`; `scripts/dev-cycle.sh:186`
  **Evidence:** read-static, plus the existing no-echo test (build-loop-read.bats, the `caf`, `/a`, `~/x`, `rel` loop, which passes)
  **Verified:** reader_settings' no-main WHY and the two consumers.
  **Not verified:** every WHY branch that main_file can produce (FENCE_AWK texts).

Primitive sweep: no dangerous primitives in scope. The registry paths and the caller roots reach only quoted `[[ != "$x"/* ]]`, `${p#"$x"}` and `realpath -mz --` argv.

### Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| I1 | Nested reader roots add cross-nested roots that no reader uses (over-refusal only) | Informational | B1, B3 | `scripts/lib/dev-cycle-read.sh:1031` | High |
| I2 | Contract item 9's "or after it" has no clear referent | Informational | Internal | `scripts/lib/dev-cycle-read.sh:90-92` | Medium |

### Overall Assessment
3908e37e fixes iteration 2's F1 (both spellings are named in main's settings) and F2 (the re-spelling now runs both ways). An executed mutation shows the new test catches a revert. In the code paths I read and the cases I probed, the two-way loop only adds roots, refuses `/`, skips blank entries and dedupes repeated spellings. No new setting or text opens a fail-open path, and no registry entry gains a way to hide a non-dot name. I found no findings above Informational within the code paths read. Endorsement claims are pending execution verification, apart from the two that were executed.

## Goal-Alignment Note
The unit's goal is to make both walks model the host readers that main names, failing closed on bad settings. 3908e37e serves that goal directly: it closes the host-side direction that iteration 2 left open, and it does so without adding a cap-sensitive mechanism (399 of 400 code lines). Neither Informational item calls for a change before landing.
