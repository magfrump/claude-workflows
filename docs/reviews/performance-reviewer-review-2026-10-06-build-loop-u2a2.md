Commit: 7f295cdb

# Performance Review — feat/build-loop-u2a2 (U2a2, iteration 2)

**Scope:** full branch diff `git diff main...HEAD` (main 20347279, HEAD 7f295cdb): `scripts/lib/dev-cycle-read.sh` (import_targets, instruction_names, untracked_md, imported_names, main_imports, isimported), `scripts/dev-cycle.sh` check_fix
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a2.md` (iteration 1), `docs/reviews/code-fact-check-report-build-loop-u2a2-i2.md` (iteration 2); override-log rows 212, 214, 345, 346, 351
**Legibility-target:** for-orchestrator-synthesis

Measurements were taken on this worktree (2,936 entries in main's tree, 1,425 of them `.md`, 45 start files, 2 untracked `.md`). They used bash, timings from `$EPOCHREALTIME`, the lib sourced with `ROOT_REAL` set after `resolve_main`, and 3-5 runs each. Scripts are in `/tmp/u2a2-perf-6iAL/` (`walk.sh`, `parts.sh`, `alt.sh`, `q.sh`). The baselines come from these copies: U2a's lib at 36b79f72 and main's scripts at 20347279, both `git archive` copies under that directory. The synthetic repo `big/` has 30,001 tracked files, 300 directories × 100 empty `.md` files plus an `AGENTS.md` that imports one of them. It also has 20,200 ignored files under `node_modules/`. Every process ran under `timeout`, and none remains. This host is about 1.2-1.4× slower than the host the U2a review measured on: `imported_names` took 400-508 ms here against 331-345 ms there.

## Data Flow and Hot Paths

- **`main_imports`** (`scripts/lib/dev-cycle-read.sh:527-587`) has no caller in this branch outside the tests. Its consumer is U2a3's `floor`, which `--check` calls once per changed path, once per merge. The walk runs once per process and caches its result (`:531`). **Path temperature: cold** (once per merge). Its phases:
  1. One `git ls-tree -r -z` of main is read into `recs`.
  2. A **bash loop over every tree record** (`:537-543`) regex-parses each record, checks for doubled names in the associative array `ent`, stores every entry's mode and collects every `.md` path into `cand`.
  3. `untracked_md` runs once. One `tr` lower-cases all candidates, then a bash regex loop over `cand` picks the start files (`:550-555`).
  4. A queue walk (`:557-586`) runs one `git cat-file blob | import_targets` pipeline per regular start or target file, and two `cat-file` calls plus `tr`/`wc` per symlink. Each import token costs one `realpath` fork inside `import_targets` (`:485`), and each import edge costs one `lower` fork (`:582`).
- **`imported_names`** (`:498-512`) is the tree walk. Its logic is unchanged apart from the extracted helpers. It runs once per `--check-fix` process. **Cold.**
- **`check_fix`** (`scripts/dev-cycle.sh:170-184`) now reaches the walk only through `isimported tree` at `:181`, after the cheap arms.

Measured numbers:

| What | This repo (2,936 entries) | Synthetic (30,001 entries) |
|---|---|---|
| `main_imports`, whole walk, branch 7f295cdb | 399-504 ms | 2,067-2,146 ms |
| `main_imports`, U2a lib 36b79f72 (grep-filtered design) | 196-231 ms | 31-35 ms |
| ls-tree + `mapfile` into `recs` | 45-46 ms | 233-247 ms |
| record loop `:537-543` (regex + `ent` + `cand`) | 141-161 ms | 1,371-1,410 ms |
| `tr` lower of `cand` | 13-14 ms | 75 ms |
| start filter loop `:550-555` | 19-24 ms | 314-330 ms |
| `untracked_md` | 5-6 ms | 13-93 ms (20,200 ignored files under node_modules) |
| Same validation done in one `awk` pass (format, newline, doubles), bash only assigning `ent`/`cand` (`alt.sh`, prototype) | 40-44 ms (in place of ~190 ms for ls-tree + record loop) | 236-261 ms (in place of ~1,630 ms) |
| `cat-file blob \| import_targets`, per file | 4.5-4.9 ms | |
| `import_targets` per extra token (one token minus zero tokens) | ~1.8 ms | |
| `lower` in `$(...)` | 2.6-3.0 ms | |
| `isimported main`, cached | 7-8.5 ms/call (two `need_root` `pwd -P` forks + one `lower`; rows 212, 345) | |
| queue shift `queue=("${queue[@]:1}")` drained from n items (`q.sh`) | n=100: 2 ms; n=1,000: 289 ms; n=3,000: 2,800 ms | |
| `dev-cycle.sh --check-fix scripts/foo.sh` (early skip) | branch 18-19 ms; main 407-456 ms | |
| `dev-cycle.sh --check-fix docs/thoughts/x.md` (reaches the walk) | branch 427-462 ms; main 422-502 ms | |
| `bats test/scripts/build-loop-check.bats` (9 tests) | 1.35 s, 9 ok | |

## Findings

#### main_imports now parses every tree record in a bash loop; the walk doubled here and grows about 69 µs per tracked entry

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:534-543`, `scripts/lib/dev-cycle-read.sh:549-555`
**Move:** Find the work that moved to the wrong place; ask "what's the size of N?"
**Classification:** Macro (linear in the size of main's whole tree, not in the instruction-file count) / Cold path (once per `--check` process, once per merge, in the U2a3 consumer)
**Confidence:** High
**Baseline:** `main_imports` 399-504 ms on this repo at 7f295cdb, against 196-231 ms for U2a's 36b79f72 lib on the same host and checkout. 2,067-2,146 ms against 31-35 ms on a 30,001-entry synthetic repo (`/tmp/u2a2-perf-6iAL/parts.sh`, `walk.sh`, 2026-10-06).

**Evidence:**
```
  for rec in "${recs[@]}"; do
    [[ "$rec" =~ ^([01234567]{6})\ [abcdefghijklmnopqrstuvwxyz]+\ [0123456789abcdef]{40,64}$'\t'(.+)$ ]] || return 1
    f="${BASH_REMATCH[2]}"
    [[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1
    ent[$f]="${BASH_REMATCH[1]}"
    [[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")
  done
```

U2a's walk filtered `ls-tree -r` through one `grep -z` (`instruction_names`) before any bash work, and its review endorsed that order. This branch drops the filter in the main walk. It `mapfile`s the whole listing, then runs a per-record `=~` match, a doubled-name lookup and an `ent` assignment for **every** tracked entry (`:537-543`). After that, a second bash regex loop runs over every `.md` path (`:550-555`). On this repo the two loops plus `mapfile` cost about 210 ms of the 400-500 ms walk, roughly double U2a's walk. On a 30k-entry tree they cost about 1.9 s, about 60× U2a's walk. A 100k-entry monorepo would extrapolate to about 6-7 s per merge (speculative). The whole-tree pass is required by the design: the doubled-name refusal and the `m:`/`t:` lookup need every name. What makes it expensive is running that pass as a bash loop. A single `awk` pass that validates the record shape, rejects a newline in a name and detects doubles, with bash only assigning `ent` and `cand` from its NUL output, did the same work in 40-44 ms here (vs ~190 ms) and 236-261 ms at 30k (vs ~1,630 ms) in `alt.sh`. That prototype was not checked against the walk's fail-closed tests. This is not row 346 (per-blob `cat-file`, keyed on instruction-file count) and not row 220 (main_entry's `ls-tree -t`). The cost here scales with every tracked file, including those that are not `.md`.

**Recommendation:** Move record validation and the doubled-name check into one `env LC_ALL=C awk` pass over the NUL listing, failing the walk on any rejection or a non-zero status. Leave only the `ent[$f]=mode` and `cand` assignment in bash, and re-run `build-loop-check.bats` tests 1-9 (fail-closed shapes) against it. Alternatively, accept it with a row whose revisit trigger is U2c's `--check` going over 1 s on a repo of 10k+ entries. At this repo's size, about 0.2 s once per merge is not blocking.

#### The queue shift is quadratic in the number of queued files

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:558` (also `:508` in `imported_names`, which predates this branch)
**Move:** Check the asymptotic behavior
**Classification:** Macro (O(q²) array copies, where q = start files + distinct import targets) / Cold path (once per process)
**Confidence:** High
**Baseline:** draining a bash array with `queue=("${queue[@]:1}")`: 2 ms at n=100, 289 ms at n=1,000, 2,800 ms at n=3,000 (`/tmp/u2a2-perf-6iAL/q.sh`, 2026-10-06). q is 45-48 on this repo, so the cost is negligible here.

**Evidence:** `    src="${queue[0]:0:1}"; f="${queue[0]:2}"; queue=("${queue[@]:1}")` (:558)

Each pop copies the rest of the queue, so a walk over q files does about q²/2 element copies. Starts include every `SKILL.md` and every `.md` under `.claude/rules/`. At row 346's own trigger (hundreds of instruction files), the shift adds about 0.3 s at 1,000 files on top of that row's ~4 s of `cat-file`. It overtakes the `cat-file` term at roughly 3,000 files. I am raising it only so that the row-346 rework covers it too.

**Recommendation:** When row 346's trigger fires, replace the shift with a head index (`for ((h=0; h<${#queue[@]}; h++))`, appending as now). The change is one line per walk and changes no behavior.

#### Each import edge forks `lower`, even for a target already seen

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:580-583`, `scripts/lib/dev-cycle-read.sh:485`
**Move:** Count the hidden multiplications
**Classification:** Micro (one `$(lower)` subshell + `tr` per edge, plus one `realpath` per token) / Cold path (once per process)
**Confidence:** High
**Baseline:** `lower` 2.6-3.0 ms per call, `realpath` about 1.8 ms per token (`parts.sh`, 2026-10-06). This repo has 3 import edges, so about 15 ms in total.

**Evidence:**
```
      IMPORTED_MAIN+="$(lower "$p")"$'\n'
      [[ -z "${seen[$p]+set}" ]] || continue
```

`IMPORTED_MAIN+="$(lower "$p")"` runs before the `seen` check, so every edge pays a fork. That includes repeated imports of one target, which also append duplicate lines to the string `isimported` scans. The cost grows with the number of import edges, about 4.5 ms per edge, not with the number of files. That is far below the first finding at any realistic count, but it is the one per-edge fork the walk still has after the candidate lowering was batched into one `tr` at `:549`.

**Recommendation:** None now. If edges grow, append raw paths and lower `IMPORTED_MAIN` once with a single `tr` after the queue drains. The same applies to `IMPORTED` in `imported_names`.

## Endorsements

- `check_fix` runs the tree walk only when a path reaches the import arm. On this host, `--check-fix scripts/foo.sh` took 18-19 ms on the branch against 407-456 ms on main, and a path that reaches the walk is unchanged (427-462 ms against 422-502 ms). [read: scripts/dev-cycle.sh:170-184, scripts/lib/dev-cycle-read.sh:498-512, :594-603]
- `main_imports` lower-cases all candidates through one `tr` (13-14 ms for 1,427 paths here) instead of one `lower` fork each, which at 2.6-3.0 ms per fork would have cost about 4 s here. [read: scripts/lib/dev-cycle-read.sh:549]
- `main_imports` caches its result and its error under the key `"$MAIN_SHA $ROOT_REAL"`, so a cached `isimported main` costs 7-8.5 ms per call, all of it `need_root` and `lower` forks (rows 212, 345), with no repeat of the walk. [unverified — submitted as claim]
- `untracked_md` stayed cheap with 20,200 ignored files under `node_modules/` (13-93 ms on the synthetic repo), so listing ignored files is not a material cost of either walk. [unverified — submitted as claim]
- Extracting `import_targets` and `inrepo_here` did not change the tree walk's cost: `imported_names` took 400-508 ms here, and `--check-fix docs/thoughts/x.md` timed the same on the branch and main. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | main_imports parses every tree record in bash: 2× U2a's walk here (~0.45 s vs ~0.21 s), about 60× at 30k entries (2.1 s vs 0.03 s) | Low | `scripts/lib/dev-cycle-read.sh:534-555` | High |
| 2 | Queue shift is O(q²); 0.29 s at 1,000 queued files | Informational | `scripts/lib/dev-cycle-read.sh:558` | High |
| 3 | One `lower` fork per import edge, duplicate edges included | Informational | `scripts/lib/dev-cycle-read.sh:582` | High |

## Overall Assessment

The branch is acceptable to merge on performance at this repo's size. The main walk runs once per merge, takes about 0.45 s here, and has no caller until U2a3. `check_fix` keeps U2a's 20× speedup for early-refused paths. The one structural change worth acting on is finding 1. Dropping the grep-first filter, which the fail-closed doubled-name check requires, moved a whole-tree pass into a bash loop. The cost now scales with every tracked file instead of with instruction files: it doubled the walk here and makes it about 2 s on a 30k-entry repo. An awk pass prototype cut that phase 4-6×. It should be checked against the fail-closed tests in U2a3, where `floor` first pays the cost, or the cost should be recorded with a size trigger. Findings 2 and 3 are small and belong with row 346's rework. No further profiling is needed before merge. If finding 1 is fixed, re-run `parts.sh` on the 30k fixture.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7f295cdb` as its first line."
- **Answered:** a performance review of the full branch diff covering main_imports, import_targets, isimported, the tree walk and check_fix's call, measured on this repo and on a 30k-entry synthetic repo against U2a's lib and main's scripts.
- **Out of scope:** correctness of the fail-closed shapes (fact-check E1/E2 and security own those); prior U2a review artifacts; settled rows 212, 214, 345 and 346, which are cited, not re-filed.
- **Escalate:** none. Finding 1 is Low, a decision between fixing and recording with a trigger.
- **Decisions:** whether to fix finding 1 in U2a2 or in U2a3, where `floor` first pays the cost.
