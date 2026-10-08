Commit: cebfed35

# Performance Review — feat/build-loop-u2a3c (main_imports' checkout phase, loop iteration 1)

**Scope:** `git diff 5e51b58b..HEAD` (commit cebfed35 only): `scripts/lib/dev-cycle-read.sh` checkout_md (:524), main_checkout (:529-535), main_imports (:565-632); helpers read in full: blocker (:110-120), rawfile/plaindir (:99, :102), inrepo_here (:127), nul_list (:521), import_targets (:497-511).
**Date:** 2026-10-06
**Based on:** the Stage 1 summary (`code-fact-check-report-build-loop-u2a3c.md`, k=1, 33 claims), shared context, and the settled cost rows in `docs/reviews/override-log.md` (:378, :384, :386, :394, :401; B6, B12).

## Data Flow and Hot Paths

main_imports runs once per merge-gate check (nothing calls it until U2a4) and caches per `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`. **Path temperature: cold** — once per merge, blocks no latency-sensitive operation. Its inputs in phase 2 are checkout files, which an agent in the build loop can write, so the cost questions are "what does a realistic checkout cost" and "how far can an agent-writable checkout stretch the gate" (availability only; nothing below fails open).

This commit adds three cost sources:
- **main_checkout per checkout path** (every untracked/ignored/index-only start, every import main lacks): an ancestor loop of builtin `[[ -d ]]`/`-x` stats (no forks), then `inrepo_here` → `$(blocker "$1" file)`: one subshell plus one `realpath` fork per existing ancestor component (plaindir) plus one for the file (rawfile); for a plain directory, a second `$(blocker "$1" dir)`.
- **phase-2 reads**: `import_targets "$d" < "$f"` on the checkout file (no `git cat-file`).
- **checkout_md**: the merged listing now captures git's stderr in a `$(...)`.

All measurements on this host (WSL2, 16 cores, bash 5.2.15, git 2.39.5, `LC_ALL=C`), scratch dir `/tmp/u2a3c-perf-G4xf`, comparing `old` = 5e51b58b's lib and `new` = cebfed35's lib (probe scripts p2-p6 in that dir):
- **This worktree** (1,498 checkout .md files, no untracked starts): walk ok, old 452-491 ms, new 463-506 ms (3 runs each). No measurable change at real-repo scale.
- **checkout_md vs the old inline listing** here: 13-14 ms vs 14 ms (3 runs), same 1,498 names.

Settled rows not re-filed (this commit does not change their order of growth): B6 per-record parse, the ancestor pass (:401), listing cost (:394, B12), per-symlink cost (:378), process substitution (:384), and the parent loop's O(L × depth) string cost (:386) — main_checkout's ancestor loop has the same shape plus a builtin stat per prefix; at depth 30 the mutant below, which keeps that loop, walks in 556 ms against old's 529-530 ms.

## Findings

#### F1. main_checkout forks one realpath per ancestor for an absent path, whose answer (2) blocker cannot change: each absent import main lacks went from 0 forks to depth+1

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:532-533` (excerpt is the whole of main_checkout :529-535; callee chain inrepo_here :127 → blocker :110-120 → plaindir :102 / rawfile :99, all read; caller :628-629 and :589-590)
**Evidence:**
```
  if inrepo_here "$1"; then [[ -r "$1" ]]; return; fi
  if [[ -d "$1" && ! -L "$1" && -z "$(blocker "$1" dir)" ]] || [[ ! -e "$1" && ! -L "$1" ]]; then return 2; fi
```
and blocker's walk (:112-115):
```
  while [[ "$rest" == */* ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"; p="${p:+$p/}$c"
    [[ -e "$p" || -L "$p" ]] || return 0
    plaindir "$p" || { printf '%s/' "$p"; return 0; }
```
The pre-commit code for the same path (removed lines) forked nothing when `$p` was absent:
```
      [[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }
```
**Move:** 1 (hidden multiplication), 3 (work moved to the wrong place)
**Classification:** Macro-ish (per absent path O(1) → O(depth) forks; total O(imports × depth)) / Cold path (once per merge gate)
**Confidence:** High (measured, and the equivalence is decidable from the read lines)
**Baseline:** Measured in /tmp/u2a3c-perf-G4xf/p3.sh and p4.sh, 2026-10-06: a tracked CLAUDE.md with 200 imports of absent files under an existing tracked directory of depth D. Walk ok in every run.

| D | old | new | new + hoist mutant |
|---|---|---|---|
| 2 | 467 ms | 1,016-1,044 ms | — |
| 10 | 574-597 ms | 2,810-5,525 ms | 567 ms |
| 30 | 529-530 ms | 7,555-10,240 ms | 556 ms |

**Legibility-target:** for-author

For an absent path (`! -e && ! -L`), `inrepo_here` is false whatever blocker prints (its `-f` fails), `-d` is false, and the second test returns 2 — so blocker's D realpath forks plus one subshell decide nothing. They cost ~1.1 ms per fork here: +11 ms per absent import at depth 10, +35-48 ms at depth 30. Absent imports are rare in a healthy repo (a broken `@` link), but they are the common case for imports *from* ignored checkout files (F2 measures 3 absent imports per ignored start roughly doubling its cost), and an agent-written checkout file can hold many distinct absent tokens under one deep existing directory: 1,000 such tokens at depth 30 is ~40 s of gate time. Never fail-open; only slow.

**Recommendation:** Hoist the absent test above the blocker call, after the ancestor loop: `[[ -e "$1" || -L "$1" ]] || return 2`. A scratch mutant with exactly that line (p4.sh) restores old's timings (table) and passes the full suite, 18/18 (`bats test/scripts/build-loop-check.bats` against the mutant lib in a copied tree). It is semantics-preserving by the reading above [read: scripts/lib/dev-cycle-read.sh:99-127, :529-535]; have the fact-check stage confirm before relying on it.

#### F2. Each ignored or untracked start now costs a walk (~10 ms at depth 5 with no imports, ~40-70 ms with three absent imports), where the old walk failed in 6 ms

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:586-593` and `:595-600` (start loop and phase-2 read; excerpt ends :600; the enclosing main_imports() continues to :632 — read, including the edge loop :622-630)
**Evidence:**
```
      f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout "$f" || c=$?
      [[ $c -ne 1 ]] || return 1; [[ $c -eq 0 ]] || continue
      seen[$f]=1; if [[ -n "${ent[$f]+set}" ]]; then queue+=("$f"); else tq+=("$f"); fi
```
```
      checkout) out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; } ;;
```
**Move:** 2 (size of N), 1 (hidden multiplication)
**Classification:** Micro per start (depth+2 forks in main_checkout, plus import_targets' grep and per-token realpath) × a population that grows with the checkout's ignored tree / Cold path
**Confidence:** High (measured)
**Baseline:** Measured in /tmp/u2a3c-perf-G4xf/p2.sh, 2026-10-06: S empty-or-small `CLAUDE.md` starts under a gitignored `nm/` at depth D, each importing K absent files. Old fails the walk in 5-12 ms in every case (fail closed, by design); new walks ok:

| S, D, K | new | new + F1 mutant |
|---|---|---|
| 100, 5, 0 | 1,046-1,069 ms | 1,074 ms |
| 100, 5, 3 | 4,262-7,050 ms | 2,157 ms |
| 400, 5, 3 | 18,056-20,939 ms | — |
| 100, 15, 3 | 8,998-9,055 ms | — |

**Legibility-target:** for-author

`git ls-files --others` without `--exclude-standard` lists ignored files, including those under `node_modules/`, `.venv/` and the like, and every instruction-named one (CLAUDE.md, AGENTS.md, GEMINI.md, `.claude/rules/**/*.md`) becomes a start that this commit walks rather than refuses. That is the unit's purpose, and the per-start cost is the blocker check the admission rule requires, so this is not a defect. The concern is the population: B12 (:221) priced *listing* ignored .md files; this adds a *walk* per ignored instruction file, linear in their count and depth. Realistic counts are small (the globally installed node_modules on this host hold 163 .md files and 0 instruction-named ones — verify data size on a real dependency tree), so the realistic cost is tens of ms; an agent-planted 4,000 ignored starts would hold the gate ~3-4 minutes. F1's hoist halves the K>0 case.

**Recommendation:** Apply F1. Otherwise no action; add this per-start term to B12's deferred row so the U2c `--check` budget trigger (over 1 s at 10k+ entries) covers it, and consider a cap on phase-2 starts (fail closed past N) if U2b's fresh-worktree gate ever runs on agent-populated ignored trees.

#### F3. A phase-2 read of a path swapped for a FIFO after admission blocks the walk with no timeout

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:600` (admission at :532 via rawfile's `-f` at :99)
**Evidence:**
```
      checkout) out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; } ;;
```
**Move:** 4 (resource lifecycle)
**Classification:** Micro / Cold path
**Confidence:** Low (derived; the race was not executed)
**Baseline:** no baseline available — flagged as speculative

main_checkout admits a regular file, then the file is opened later, after every earlier queue entry is walked. A concurrent writer in the checkout that replaces it with a FIFO between the two makes `< "$f"` block until a writer appears — the gate hangs rather than fails. It requires a process racing the gate in the gate's own checkout, which U2b's planned fresh worktree excludes; it is never fail-open. Route to security for the TOCTOU judgement.

**Recommendation:** None needed now; if the gate ever runs in a shared checkout, run the walk under the caller's `timeout` (as the bats harness does) or open with a non-blocking check. Record as a U2b note rather than a code change.

## Endorsements

- checkout_md's stderr capture costs nothing measurable over the old inline `nul_list ... env git ls-files` listing (13-14 ms vs 14 ms, 1,498 names, p5.sh), and it does not deadlock: with a 142,890-byte stdout listing it returned all 3,000 names in 28 ms, and with 188,890 bytes of git warnings (2,000 mode-000 directories) it failed closed (rc 1, empty list) in 53 ms, both under `timeout 60` (p6.sh) — stdout goes to fd 3 drained by mapfile while the `$(...)` drains stderr concurrently. [unverified — submitted as claim]
- The phase-2 read redirects the checkout file straight into import_targets, one process fewer than main's `git cat-file blob | import_targets` arm. [unverified — submitted as claim]
- main_checkout's builtin ancestor loop (`-d`/`-x` per prefix) is negligible beside blocker's forks: with only the F1 hoist added, a depth-30, 200-import walk takes 556 ms against old's 529-530 ms. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Absent path forks depth+1 realpaths that cannot change its answer (0 → depth+1 forks per absent import; 200 imports at depth 30: 0.53 s → 7.6-10.2 s) | Low | `scripts/lib/dev-cycle-read.sh:532-533` | High |
| 2 | Each ignored/untracked start now costs a walk (~10 ms each at depth 5; 400 starts × 3 imports ≈ 18-21 s) | Informational | `scripts/lib/dev-cycle-read.sh:586-600` | High |
| 3 | FIFO swapped in after admission hangs the phase-2 read | Informational | `scripts/lib/dev-cycle-read.sh:600` | Low |

## Overall Assessment

At real-repo scale the commit costs nothing measurable (this worktree: 452-491 ms old vs 463-506 ms new; listing 14 ms both). The one real change in order of growth is F1: main_checkout routes every absent path through blocker's per-component realpath forks, though for an absent path the answer is decided without them. A one-line hoist (`[[ -e "$1" || -L "$1" ]] || return 2` after the ancestor loop) removes it, passes 18/18, and restores the old timings — fixable in place, no structural problem. F2 is the intended price of walking checkout starts and belongs with B12's deferred trigger. Nothing here fails open; every cost is gate latency on agent-writable input.

## Goal-Alignment Note

The goal is to land U2a3c with a checkout phase that can only add imports and fails closed. No finding here touches that property: every probe walked ok with the expected result or failed closed (old lib), and the F1 mutant preserves main_checkout's return codes by construction and passed the full suite. The review's value to the goal is F1, a cheap fix that keeps the new admission check from making ordinary broken-import cases 10-20x slower; F2 and F3 are availability notes for U2b/U2c's budget and worktree decisions, not blockers for this merge. Scratch: `/tmp/u2a3c-perf-G4xf` (left in place for reproduction; fixture chmods restored; no processes left running).
