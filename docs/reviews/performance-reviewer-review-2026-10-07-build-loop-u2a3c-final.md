Commit: 3a35c8b9

# Performance Review — feat/build-loop-u2a3c (final confirming pass, iteration 3)

**Scope:** `git diff main...HEAD` at 3a35c8b9, focused on `scripts/lib/dev-cycle-read.sh` (main_checkout, capped_read, import_work, IMPORT_WORK_MAX, the symlink arm) and the tests that pin its cost
**Date:** 2026-10-07
**Based on:** Stage-1 summary `u2a3c-i3-stage1.md`, and the `## Escalations` sections of `docs/reviews/code-fact-check-report-build-loop-u2a3c-r{1,2,3}.md`

Measurement provenance: every figure below was measured on 2026-10-07 under bash 5.2.15, git 2.39 and 16 cores (WSL2), in the scratch dir `/tmp/u2a3c-i2-perf3-HfYE`. The libraries used there are `git show` copies: `lib-head.sh` (3a35c8b9), `lib-old.sh` (21b35ebf, iteration 2's base), `lib-main.sh` (main) and `lib-patched.sh`. `lib-patched.sh` is HEAD with one line changed, the `@a` guard at `:736` (see F1). The harness `h.sh LIB REPO` runs `resolve_main` and one `main_imports` in a throwaway hermetic repo built by `mk.sh`, under `timeout`, with a realpath-counting shim on PATH. Each figure comes from a single run, so treat it as ±10%. The worktree was never written except for this report. Line numbers are HEAD's. The worktree now holds uncommitted edits, which this review does not cover. They do not change the `:736` guard.

## Data Flow and Hot Paths

`main_imports` is the gate's @-import walk. It lists main's tree into `ent` (one entry per blob, link and gitlink; no directories) and lists the checkout's `.md` files. It walks main's start files to a fixpoint, and then (phase 2) walks the checkout files main lacks. The parser prints every prefix candidate of every token. Each printed name that `ent` lacks goes through `main_checkout ent pok "$p"` (`:870`); that includes every directory prefix, since `ent` holds no directories. Start candidates main lacks also go through it (`:825`). Calls per walk therefore scale with the distinct candidates main lacks, not with files. On /workspace that is 163 calls and 128 printed names. The walk is a cold path: it runs once per gate run, and nothing calls `main_imports` until U2a4/U2b. However, every input is attacker-shaped by a branch (its files are in the checkout), and the walk iterates over main's whole tree. So the hot-path gate's large-data and adversarial escalation applies to anything that is quadratic per call.

## Findings

#### F1. main_checkout's associative-array guard costs O(|ENT| + |MEMO|) per call, so the walk is quadratic in the candidates main lacks: 4,000 absent import tokens take 85 s (21b35ebf 4.4 s), and 8,000 take over 500 s

**Severity:** High
**Location:** `scripts/lib/dev-cycle-read.sh:736` (called per candidate from `:825` and `:870`)
**Move:** Count the hidden multiplications; check the asymptotic behaviour
**Classification:** Macro (per-call cost linear in two growing collections, so the walk is quadratic) / Cold path, escalated: it iterates over main's whole tree, the candidates come from branch-controlled files, and IMPORT_WORK_MAX does not charge this cost
**Confidence:** High (measured, then isolated by a one-line patch)
**Legibility-target:** code (and a test)
**Baseline:** 85.45 s for one main walk over a CLAUDE.md of 4,000 lines `@t<i>/b/c/d/e/f/g/h/x.md`, absent from the checkout, at HEAD. The same walk takes 4.35 s at 21b35ebf, 1.27 s on main's lib, and 3.15 s with the guard made O(1). Measured 2026-10-07 with `h.sh`, `r-tk4000`.

Evidence (verbatim, `:736`): `  set +u; [[ "${mc_e@a}" == *A* && "${mc_m@a}" == *A* ]] || return 1`

On an associative array, bash's unsubscripted `${name@a}` costs time linear in the array's size. A microbenchmark through a nameref, as main_checkout uses, measured 97.8 µs per call at 1,000 entries, 907.7 µs at 8,000, 4,221 µs at 32,000 and 398 µs at /workspace's 3,064 (`mb.sh`). A key lookup stays at about 5 µs. main_checkout pays this for ENT (main's whole tree) and for MEMO on every call. Both terms grow:

- **MEMO (regression in 2fbd929b).** The bottom-up rewrite memoizes every absent ancestor as `2` (`mc_m[$c]="$st"`, `:747`). Before it, 21b35ebf memoized only directories. MEMO now grows by about one entry per distinct absent prefix, so N absent tokens cost O(N²). Measured at HEAD: 1,000 tokens 5.43 s, 4,000 tokens 85.45 s, 8,000 tokens still running at the 500 s timeout. With the guard rewritten as `${mc_e[0]@a}` / `${mc_m[0]@a}`, which returns the array's attributes in O(1) (1.8 µs at 32,000 entries), the same walks take 0.79 s, 3.15 s and 6.07 s, which is linear. At 21b35ebf they took 1.10 s and 4.35 s.
- **ENT (in-branch since the iteration-1 A1 fix, not on main).** On a 50,000-entry main tree with 1,000 one-level absent imports, the walk takes 33.39 s at HEAD, against 3.22 s patched and 3.08 s on main's lib (`big.sh`, `r-big50000`). With no adversary, a monorepo of 50k files whose walk has a few hundred directory-prefix candidates pays about 6.5 ms per call, roughly 2 s. /workspace pays about 0.4 ms per call over 163 calls, roughly 65 ms of a 1.5 s walk.

An 8,000-line file is about 200 KB, far inside IMPORT_OUT_MAX (4,000,000 printed bytes), and the parser charges it under 1% of IMPORT_WORK_MAX. Up to the print budget, the quadratic is bounded only by IMPORT_OUT_MAX: about 400k short candidates, which extrapolates to hours. No test pins it. The deep-token test (`build-loop-check.bats:932`) uses one token, whose MEMO stays at about 1,000 entries (2.49 s at HEAD against 2.37 s patched at D=1990). T1 times nothing. The Stage-1 differential (about 45,000 random-order calls, 0 mismatches) checked return codes, not cost.

**Recommendation:** Test the attribute in O(1): `[[ "${mc_e[0]@a}" == *A* && "${mc_m[0]@a}" == *A* ]]`. An element of an associative array reports the array's attributes even when unset, and a declared-indexed array still reports `a`. This was checked here: `A:[A] a:[a]`, nameref `[A]`. Keep `set +u`. The key must be a literal, so an indexed array's arithmetic subscript evaluates nothing. Alternatively, drop the per-call check and have main_imports assert it once, since it declares both arrays `local -A` itself. Pin the fix with a many-token walk, for example 4,000 absent tokens under a timeout with about 10× headroom (0.8 s patched at 1,000 tokens), or a host-independent count. A timing test alone carries the host-speed caveat the fact-check raised for `timeout 6`.

#### F2. A deep token through directories the checkout holds still costs O(D³) in realpath: 1,991 realpath calls take 168 s at D=1990

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:744`, `:751-753` (rawfile and plaindir at `:103`, `:106`)
**Move:** Check the asymptotic behaviour, not just the constant
**Classification:** Macro (per-call cost grows with depth) / Cold path. The depth is bounded by PATH_MAX (at most about 2,048 levels) and needs a branch to commit the deep directories.
**Confidence:** High (measured)
**Legibility-target:** code
**Baseline:** 168.24 s and 1,991 realpath calls for one main walk over `@a/a/…/x.md` at D=1990, every directory present in the checkout and absent from main, at HEAD. The same shape at D=1000 takes 14.28 s at HEAD, 33.72 s at 21b35ebf and over 120 s on main's lib (timeout). Measured 2026-10-07 with `h.sh`, `r-dp*`.

Evidence (verbatim): `rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }` (`:103`), reached once per prefix through `if rawfile "$c"; then [[ -r "$c" ]]; return; fi` / `plaindir "$c" || return 1` (`:751-752`).

The memo did its job on the count: 1,001 forks at D=1000, against 2,001 at 21b35ebf. But each fork's own cost grows with depth. `realpath -e` takes 0.83 ms per call at depth 100, 6.99 ms at 500, 36.8 ms at 1000 and 231 ms at 1990, because it canonicalizes component by component. Summed over D prefixes, the walk grows cubically: 0.24 s at D=100, 0.97 s at 300, 14.28 s at 1000, 168 s at 1990. A bash `[[ -d && ! -L ]]` on the same path costs 0.5 ms at depth 1990. With the `@a` guard made O(1), the time is unchanged (14.95 s at D=1000), so this cost is realpath's alone. This is a large improvement on main and on 21b35ebf, so it is not a regression. It is the residual of the L2-C6 class. Iteration 2 attributed D=1000's 33.5 s to F1's string cost. At HEAD the remainder is realpath.

**Recommendation:** Defer with an override row if the loop prefers. If not: once every ancestor is memoized `d`, each one already passed `realpath == ROOT_REAL/ancestor`, so PATH is plain if and only if `[[ ! -L "$c" ]]` with `-f` or `-d`. realpath is then needed only for a top-level component (no `/`). That makes the walk about 0.5 ms × D at most.

#### F3. The work unit charges ROOT_REAL in every resolved spelling, so IMPORT_WORK_MAX trips earlier, in names and in seconds, under a long checkout path. It errs safe, and "about 5 s" is an upper figure.

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:581`, `:584` (comment `:504-510`)
**Move:** Price the deployment environment (checkout path length)
**Classification:** Micro (calibration of a bound) / Cold path
**Confidence:** Medium (the measured figures are High; the headroom at long roots is an estimate from 128 printed names)
**Legibility-target:** comment
**Baseline:** 31,938,660 work units and 2.29 s for 475,255 names (every 1-4 letter `@` name, one 2.8 MB line) with a 10-character ROOT_REAL. With a 200-character root the parser fails at 50,000,192 units after 65,206 names in 0.48 s. With a 2,000-character root it fails at 50,000,150 after 8,552 names in 0.23 s. Measured 2026-10-07 with `rootlen.sh`.

Evidence (verbatim): `  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` (`:581`), then `  work += length(c); if (work > wmax) exit 3` (`:584`).

This confirms the Stage-1 note, and it errs in the safe direction: a long root makes the bound fail sooner, not stall longer. Per charged unit, the root's characters cost less time than a name's (0.23 s per 50M units at a 2,000-character root, against about 3.6 s per 50M at 10), so "about 5 s" is the ceiling, not the typical cost. Real headroom stays large. /workspace's main walk prints 128 names and spends about 8,100 units at a 10-character root. At a 4,000-character root that becomes about 1.2M units on an estimate of 300 resolved spellings, roughly 40× under the bound. The worktree's uncommitted comment edit already names the root dependence.

**Recommendation:** None beyond the comment. If U2b ever runs walks from very deep checkouts, reconsider charging `length(c) - length(root)`.

## Fixes re-measured (iteration 2)

- Deep absent token (B2): at HEAD D=500 takes 0.18 s, D=1000 0.66 s and D=1990 2.49 s; 21b35ebf took 2.06 s and 10.83 s. HEAD's cost is linear in printed bytes (D² bytes of prefixes), and IMPORT_OUT_MAX caps it: D=2000 prints past 4,000,000 bytes and fails in 1.17 s. The `timeout 6` test passes with about 9× headroom. Its kill side (10.8 s old) holds only on hosts less than about 1.8× faster than this one, as the fact-check found.
- Many siblings: 20,000 absent `@d/x<i>.md` under one present directory take 4.20 s at HEAD (3.67 s at 21b35ebf), which is linear. MEMO gains no entries, because absent leaves are not memoized.
- Many tokens: quadratic, see F1.
- Link text cap (B3): a 64 MiB 120000 blob fails the walk in 0.02 s, against 16.34 s at 21b35ebf.
- Explicit drain: a 512 MiB CLAUDE.md blob walks ok in 0.96 s. Main's lib, which feeds the whole blob to the parser, timed out at 120 s.
- import_work: stripping and charging a 5.1 MB output takes 0.17 s (1.2 MB: 0.036 s), which is linear.
- Phase 2 over many checkout files: 300 imported untracked files take 2.58 s and 1,200 take 12.74 s, about 10 ms per file in forks. The `queue=("${queue[@]:1}")` shift is quadratic in principle, but forks dominate at these sizes. This is the settled per-start cost row.

## Endorsements

- At HEAD, a deep token whose ancestors the checkout lacks costs time linear in printed bytes: 0.66 s at D=1000 against 10.83 s at 21b35ebf, and 2.49 s at D=1990, the deepest that fits IMPORT_OUT_MAX [unverified — submitted as claim]
- The 4096-byte `git cat-file -s` check fails a 64 MiB link blob in 0.02 s, against 16.34 s at 21b35ebf, before either whole read [unverified — submitted as claim]
- `capped_read drain` keeps a 512 MiB blob's walk at 0.96 s and passing, where main's lib took over 120 s [unverified — submitted as claim]
- main_checkout's memo cuts the realpath forks of a D=1000 present-directory token from 2,001 (21b35ebf) to 1,001, one per prefix [unverified — submitted as claim]
- `import_work` is linear in the parser's output: 0.17 s for 5.1 MB [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `${mc_e@a}`/`${mc_m@a}` per call is O(\|ENT\|+\|MEMO\|): 4,000 absent tokens 85 s (21b35ebf 4.4 s; O(1) guard 3.2 s), 8,000 > 500 s; 50k-file main tree × 1,000 tokens 33 s (main 3.1 s) | High | `dev-cycle-read.sh:736` | High |
| F2 | Deep token through present checkout directories: realpath per prefix grows with depth, 168 s at D=1990 (improved from 21b35ebf/main, residual) | Low | `:744`, `:751-753`, `:103/:106` | High |
| F3 | Work unit charges ROOT_REAL: the bound trips sooner under a long root (safe side); "about 5 s" is a ceiling | Informational | `:581`, `:584`, comment `:504-510` | Medium |

## Overall Assessment

Iteration 2's fixes hold on the shapes they targeted: deep absent tokens, link text, drain and per-file work. But the bottom-up memo exposed a cost that was already in the iteration-1 guard. `${array@a}` is linear in the array's size, and once MEMO memoizes every absent ancestor, the walk is quadratic in absent tokens. A ~200 KB branch file now stalls the walk for more than 8 minutes, where 21b35ebf took seconds. The ENT half makes every call cost proportionally to main's tree on large repositories. The fix is a one-line, in-place change (subscripted `@a`) plus a many-token test, and needs no structural rework. F2 is a bounded residual worth a deferral row, and F3 needs at most a comment. No further profiling is needed to confirm F1: the one-line patch isolates it. A host-independent pin (a count, or a token count large enough that the regression costs over 30 s) would make its test robust.

## Goal-Alignment Note

The goal is to land `feat/build-loop-u2a3c` once its loop is clean. F1 is the one item here that should block that. It is new in this branch's fix commit (2fbd929b memoizes absent ancestors, on top of the iteration-1 guard), it costs real time on large main trees even without an adversary, and it is cheap to fix now while main_checkout has two call sites and the loop is open. Deferring it would leave U2a4/U2b to inherit a gate that a branch can stall for minutes with an ordinary-sized file. F2 and F3 do not block: F2 improves on both main and 21b35ebf and is bounded by PATH_MAX, and F3 errs safe. Both fit the existing deferral pattern (override rows with a revisit trigger at the first caller of `main_imports`). Nothing here re-files a settled row. The drain, the @-less scan and the two-walk bound stay as decided.
