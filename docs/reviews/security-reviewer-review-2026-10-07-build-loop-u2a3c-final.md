Commit: 3a35c8b9

# Security Review — feat/build-loop-u2a3c (final confirming pass, iteration 3)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-build-loop-u2a3c` (code: `scripts/lib/dev-cycle-read.sh`; tests and docs as listed in the shared context)
**Date:** 2026-10-07
**Based on:** Stage-1 summary `u2a3c-i3-stage1.md` and the `## Escalations` sections of `docs/reviews/code-fact-check-report-build-loop-u2a3c-r{1,2,3}.md`
**Class weighed:** fail-open, meaning an import a session would load that the walk answers as not imported while the walk returns ok.

## Trust Boundary Map

```
B1:         [main's commit: ls-tree records, blobs, link blobs]  → [record regex, dup/dir checks, 4096 link cap, capped_read drain] → [ent, queue]
B2:         [checkout listing: ls-files --cached --others + stderr] → [checkout_md (stderr empty), lower_all under nul_list]        → [start candidates]
B3:         [parser output: names derived from S1/S2 text]         → [ent lookup, else main_checkout ENT MEMO PATH]                 → [seen, tq, IMPORTED_MAIN]
B4:         [checkout file bytes at an admitted path]              → [capped_read < f, import_targets work/print bounds, import_work] → [parser output]
B5 (new):   [a future caller of main_checkout (U2a4/U2b)]          → [written contract: fresh MEMO per walk and ENT]                → [admission decision]
B6 (moved): [the gate checkout U2b names]                          → [U2b bullet's caller duties]                                   → [main_imports' view of the checkout]
```

| Label | Source | Mutability | Trust per sink class |
|---|---|---|---|
| S1 | main's commit (tree, blobs, link blobs) | runtime-mutable (a self-merge lands loop-written content) | UNTRUSTED for path, read-size and parse sinks; trusted as the definition of what main stores |
| S2 | checkout files and directory shapes (untracked, ignored, index-only, `.git`) | runtime-mutable (any loop with the uid writes them) | UNTRUSTED for path, read and admission sinks |
| S3 | parser output names (from S1/S2 text) | request-time per walk | UNTRUSTED for path and admission sinks |
| S4 | caller globals: IMPORT_WORK_MAX, IMPORT_OUT_MAX, ROOT_REAL, HOME, MEMO/ENT arrays passed by name | deploy-time / caller code | trusted for availability; ENT/MEMO trusted only as far as the written contract holds (B5) |
| S5 | git's exit codes and stderr | deploy-time binary | trusted for availability; stderr treated as a failure signal |

What crosses: S1 and S2 text becomes S3 names, which reach the filesystem as paths admitted by main_checkout (B3) and are read by capped_read (B4). The diff adds B5: main_checkout is now a reusable predicate whose correctness for another caller rests on contract text. B6 moves because the U2b bullet's description of the gate checkout changed.

## Findings

#### F1. main_checkout memoizes PATH as `d` without reading ENT[PATH]; a caller that passes a path main stores as a link or gitlink makes every later path below it skip the link refusal

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:753` (memo write); contract text at `:717-723` and plan U2b bullet (`docs/working/plan-build-loop-handoff.md`, "A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT")
**Boundary:** B5 (and B3 for the current caller)
**Move:** 11 (bypass enumeration on the admission guard), 5 (invert the model: what the memo lets through)
**Confidence:** High (executed)
**Legibility-target:** the lib comment at `:717-723` (states "set only once its own and every higher ancestor's main mode passed", which the PATH arm contradicts) and the U2b bullet's main_checkout contract

Evidence, verbatim:

```
  plaindir "$c" || return 1
  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through
  return 2
```

The ancestor loop checks `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1` before every memo write it makes (`:742`), but the PATH arm writes `d` for PATH itself with no such read, and a later MEMO hit (`:739`) skips the mode check for that ancestor. Executed repro in scratch (functions extracted from 21b35ebf and HEAD; checkout has a plain directory `a/` holding `a/f.md`; `ENT=([a]=120000)`; calls `a` then `a/f.md` on one MEMO):

```
old: a=2 a/f.md=1
new: a=2 a/f.md=0
fix: a=2 a/f.md=1
```

Random differential (400 random checkouts with directories, files, absent nodes, symlinks and unsearchable directories at depth 3; random ENT with 120000/160000/100644; 12 random-order calls each on one MEMO): with PATH allowed in ENT, 4,800 calls, 110 mismatches against 21b35ebf, all in the fail-open direction (94 old=1 new=2, 16 old=1 new=0). With PATH restricted to paths ENT lacks, 2,944 calls, 0 mismatches.

**Reachability today:** none. `main_imports` passes main_checkout a path only when `ent` holds no entry for it: the start seeds are `t:` candidates built at `:819` (`[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")`) and `:825` skips main_checkout for `m:`; the import arm at `:870` is `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"`. ls-tree -r lists no tree entries, so an ent hit always means main stores a blob, link or gitlink there. The floor rule's reachable-environment bar is not met in this branch, hence Low; it becomes a live fail-open the day U2a4 or U2b calls main_checkout on a name main stores (for example, U2b running main_checkout on fixed start names directly, which override row 440's revisit trigger proposes).

**Recommendation (code guard, not contract text):** make the PATH memo write conditional on ENT, which restores exact equivalence with 21b35ebf for every ENT and costs nothing for main_imports:

```
[[ ! -x "$c" || -n "${mc_e[$c]+set}" ]] || mc_m[$c]=d
```

Executed: with this one change, 4,800 calls with PATH allowed in ENT gave 0 mismatches against 21b35ebf, and `test/scripts/build-loop-check.bats` passed 63/63 against the patched lib (copy in scratch). A contract sentence ("PATH must not be a name ENT holds") would be a duty no code checks, on a caller that does not exist yet; the guard makes the comment's "set only once its own and every higher ancestor's main mode passed" true as written. Add a T1 row: `ENT=([a]=120000)`, call `a` then `a/f.md`, expect 1 (kills the current code). If the author prefers contract text instead, it must go in both the lib comment and the U2b bullet, and a test should still pin the precondition's consequence.

#### F2. The U2b bullet no longer requires the gate checkout to match MAIN_SHA; the walk reads main's blob for a path main stores, so an edited tracked instruction file in the gate checkout carries imports the walk answers as not imported

**Severity:** Low
**Location:** `docs/working/plan-build-loop-handoff.md`, U2b bullet (the diff replaces "a fresh worktree at MAIN_SHA" with "It names the checkout `--check` runs from (the walk reads its untracked, ignored and index-only start files and the imported files main lacks there) and owes the walk three things"); behaviour at `scripts/lib/dev-cycle-read.sh:836-840` (`case "${ent[$f]-checkout}"`, main's blob arm for any path ent holds)
**Boundary:** B6
**Move:** 2 (implicit assumption: a checkout whose tracked files equal main's)
**Confidence:** Medium (behaviour executed; whether U2b would pick a dirty checkout is a design question one hop away)
**Legibility-target:** the U2b bullet's list of caller duties

Evidence, verbatim (main's text the diff removes): "It names the checkout `--check` runs from: a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks". HEAD's three duties are: the checkout final or `IMPORTED_MAIN_DONE` cleared, empty `ls-files` stderr, and the git environment. None of the three says tracked files equal main's. Executed in scratch: main commits `AGENTS.md` ("hi") and `x.md`; the checkout edits `AGENTS.md` to `Rules: @x.md` and adds an untracked `AGENTS.local.md` with `Rules: @y.md`:

```
walk=ok
x.md -
y.md imported
```

This is by design for main_imports (test 77 pins "a working-tree edit does not count"), and the old fresh-worktree duty is what made it harmless: a session in that checkout loads the edited `AGENTS.md`, so a gate run from a checkout with an edited tracked instruction file (or an edited tracked import target) returns ok and answers `-` for what that session loads. The dropped sentence's stated reason was U2a3c's absence, so removing it reads as housekeeping, but it also carried the clean-tracked-files duty. No caller exists yet (U2b is unbuilt), hence Low.

**Recommendation:** keep a fourth duty in the U2b bullet: the gate checkout's tracked files equal MAIN_SHA's (a fresh worktree at MAIN_SHA, or refuse when `git diff --quiet MAIN_SHA --` fails or the index differs). Docs only in this branch.

## Iteration 2 fixes re-checked for new fail-opens

- **Bottom-up memo (2fbd929b):** for paths ENT lacks, 0 mismatches against 21b35ebf over 2,944 random-order executed calls (this pass) on shapes including symlinked ancestors, unsearchable directories and memo hits at a `2` entry followed by a deeper link ancestor (the loop at `:740-748` still runs the ENT test at `:742` for every ancestor below the hit, whatever `st` holds). The one divergence is F1, outside main_imports' calls.
- **4096-byte link-text cap (`:843`):** `git cat-file -s` runs and is compared before either whole read at `:846-847`; a failed size read or a size over 4096 sets `IMPORTED_MAIN=error` and returns 1, the fail-closed direction. A link over PATH_MAX names nothing the kernel resolves, so refusing it drops no load. Test 63 passes.
- **`capped_read drain` (`:709`, `:839`):** the drain is passed at the blob arm and nowhere else. `head` failing returns 1; `cat` failing makes capped_read's status nonzero; under the walk's `set -o pipefail` a `git cat-file` failure fails the `$(...)`. The checkout arm reads `< "$f"`, so an unopenable file fails the pipeline's first stage, which pipefail reports. No path leaves `out` empty with status 0 on a read failure that I could construct. Bytes past 4 MiB + 1 are unread by design (Claude Code skips files over 4 MiB; settled in U2a3b).
- **Work trailer (`import_work`, IMPORT_AWK END):** an awk `exit 3` inside a rule still runs END (so a trailer prints), but the exit status stays 3 and import_targets returns 1, so a spent bound fails the walk. A printed name starts after `ROOT_REAL/` and put drops empty segments, so no name line can start with `/` and impersonate the trailer.
- **A1, A3, C1 from iteration 1:** the `${x@a} == *A*` test on both arrays is at `:736`; admission at `:870` precedes `seen[$p]=1` at `:872`; `[[ -e "$c" || -L "$c" ]] || return 2` at `:750` and the `! -e && ! -L` test at `:744` precede any `rawfile`/`plaindir` fork.
- **`.git` read as a checkout file:** a gitfile at the top level is admitted as a plain readable file and parsed (test 411); a path below a gitfile hits the rawfile ancestor arm (`2`, nothing loads below a file); a path under a gitlink main stores fails at `:742`. A socket or FIFO under `.git` named by an import fails the walk (anything else at PATH), the closed direction.

## Untested bypass candidates

- Case-variant spellings of a link main stores on a case-insensitive checkout (`A` in ENT, an import of `a/f.md`): not tested; Linux scratch is case-sensitive, and this is A5's settled "other names one file has on a case-insensitive checkout".
- A checkout node swapped between admission and read: not tested; settled TOCTOU/snapshot row.

Because F1 is an open bypass of main_checkout for a contract-violating caller, main_checkout as a reusable guard does not appear in Endorsement Claims below; the claims are scoped to main_imports' calls.

## Endorsement Claims

- **Claim:** For every call whose PATH has no entry in ENT, HEAD's main_checkout returns the same code as 21b35ebf's, under any call order on one MEMO.
  **Location:** `scripts/lib/dev-cycle-read.sh:732-755`
  **Evidence:** executed
  **Verified:** 400 random checkouts × 12 random-order calls, 2,944 calls with PATH absent from ENT, 0 mismatches (shapes: plain directories, files, absent nodes, symlinks, unsearchable directories; ENT holding 120000, 160000 and 100644 at random ancestors).
  **Not verified:** depths above 3 and names with more than two characters per segment; case-insensitive file systems.
  **route: code-fact-check**

- **Claim:** main_imports passes main_checkout a path when `ent` holds no entry for it, at both call sites (start seeds at `:819`/`:825`, imports at `:870`).
  **Location:** `scripts/lib/dev-cycle-read.sh:819`, `:825`, `:870`
  **Evidence:** read-static
  **Verified:** read main_imports in full (`:801-876`): `t:` candidates are appended under `[[ -n "${ent[$f]+set}" ]] ||`, `:825` skips main_checkout for `m:` candidates, `:870` calls it under `[[ -n "${ent[$p]+set}" ]] ||`.
  **Not verified:** U2a4's and U2b's future calls, which do not exist yet.
  **route: code-fact-check**

- **Claim:** Making the PATH memo write `[[ ! -x "$c" || -n "${mc_e[$c]+set}" ]] || mc_m[$c]=d` restores 21b35ebf's return code for every call including PATHs ENT holds, and keeps build-loop-check.bats at 63/63.
  **Location:** `scripts/lib/dev-cycle-read.sh:753`
  **Evidence:** executed
  **Verified:** 4,800 random-order calls with PATH allowed in ENT, 0 mismatches against 21b35ebf (110 on unpatched HEAD); the full build-loop-check.bats suite against a scratch copy with the change, 63 ok.
  **Not verified:** dev-cycle.bats and build-loop-read.bats against the patched copy.
  **route: code-fact-check**

- **Claim:** The symlink arm compares the link blob's size against 4096 before either whole read of the blob, and a failed size read fails the walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:843-847`
  **Evidence:** read-static
  **Verified:** line order `:843` (cat-file -s, `-le 4096`, else `IMPORTED_MAIN=error; return 1`) before `:846-847`; test 63 passes at HEAD.
  **Not verified:** a git shim counting `cat-file blob` calls to observe the order at run time (r2's suggestion).
  **route: code-fact-check**

- **Claim:** A read failure in either capped_read arm (unopenable checkout file, `head` failure, `git cat-file` failure, drain failure) sets IMPORTED_MAIN to error and returns 1, given main_imports' own `set -o pipefail`.
  **Location:** `scripts/lib/dev-cycle-read.sh:709`, `:802`, `:837-840`
  **Evidence:** read-static
  **Verified:** capped_read's body; main_imports sets pipefail locally (`local - ...; set -o pipefail`); both arms end in `|| { IMPORTED_MAIN=error; return 1; }`.
  **Not verified:** a `head` that exits 0 after a short read on an I/O error (kernel/coreutils behaviour, not exercised).
  **route: code-fact-check**

- **Claim:** build-loop-check.bats passes 63/63 at 3a35c8b9 under `TMPDIR=/tmp/u2a3c-i2-sec3-2uoz LC_ALL=C`.
  **Location:** `test/scripts/build-loop-check.bats`
  **Evidence:** executed
  **Verified:** `bats test/scripts/build-loop-check.bats`, 63 lines `ok`, no `not ok`.
  **Not verified:** longer TMPDIR roots (r1 reports test 59 fails at a 56-character fixture root).

## Primitive sweep

Primitive: file read and path admission (path traversal / fail-open read set)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:775` imported_names `capped_read < "$f"` | S2, S3 | `inrepo_here` (blocker + `-f`) at `:766`/`:783` | cleared: unchanged guard; only the reader changed |
| `dev-cycle-read.sh:837` main_imports checkout arm `capped_read < "$f"` | S2, S3 | main_checkout returned 0 (`:825`/`:870`) | cleared for main_imports' calls; F1 for other callers |
| `dev-cycle-read.sh:839` blob arm `git cat-file blob "$MAIN_SHA:$f" \| capped_read drain` | S1 | path is an ent key (from ls-tree) | cleared: object lookup, not a filesystem path |
| `dev-cycle-read.sh:843` `git cat-file -s` | S1 | ent key | cleared: fail-closed size cap |
| `dev-cycle-read.sh:846-847` link blob reads | S1 | size ≤ 4096 at `:843` | cleared |
| `dev-cycle-read.sh:855`, `:858` `realpath -ms` on link text | S1 | NUL/newline/absolute/`..`-after-link refusals `:846-859` | cleared: unchanged by this diff apart from the cap |
| `dev-cycle-read.sh:744-745`, `:750-752` rawfile/plaindir/`-r`/`-x` | S3 | ENT link test `:742`; MEMO | F1 (PATH memo) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | main_checkout memoizes PATH as `d` without ENT[PATH]; a later path under a link main stores passes (unreachable from main_imports) | Low | B5, B3 | `scripts/lib/dev-cycle-read.sh:753` | High |
| F2 | U2b bullet dropped the gate checkout = MAIN_SHA duty; an edited tracked instruction file's imports answer `-` with walk ok | Low | B6 | plan U2b bullet; `dev-cycle-read.sh:836-840` | Medium |

## Overall Assessment

No fail-open is reachable through main_imports at 3a35c8b9 within the code paths read. Iteration 2's three fixes (bottom-up memo, 4096-byte link cap, explicit drain) fail closed on every failure path read, and the memo matches 21b35ebf's top-down version exactly on in-contract calls (executed). The Stage-1 Incorrect is real but latent: it is a hole in main_checkout as a reusable guard, and U2a4/U2b are its first other callers. The single most important thing is to close it in code, with the one-condition guard at `:753` and a T1 row, rather than in contract text: the guard is executed-equivalent to 21b35ebf for every ENT, keeps the suite green, and makes the existing comment true. F2 is a one-sentence restoration in the U2b bullet. Both are fixable in place; neither indicates an architectural problem. Endorsement claims marked `route: code-fact-check` are pending Stage 2.5.

## Goal-Alignment Note

The goal is to land feat/build-loop-u2a3c once its loop is clean. Neither finding blocks the walk's current behaviour. F1's guard is a one-line code change plus a test, and F2 is a one-sentence doc change. Both fit this final pass without reopening design. If the loop is at its cap, deferring F1 to U2a4 with an override row naming "main_checkout's first caller other than main_imports" as the trigger is defensible, because no current path reaches it. The fix is cheap enough that landing it now saves U2a4 from rediscovering the precondition.
