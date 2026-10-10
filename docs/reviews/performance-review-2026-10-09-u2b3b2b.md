Commit: 1c820663

# Performance Review: feat/build-loop-u2b3b2b (U2b3b2b, outside seeds), iteration 1

**Scope:** `git diff main...HEAD` (mainly `scripts/lib/dev-cycle-read.sh`: `outside_seeds`, `outside_proj`, the seed hooks in `imported_names` and `main_imports`)
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2b-i1/shared.md`. The fact-check is running in parallel and was not available, so this review rests on reading the code and on read-only measurements against /workspace.

> **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Measurement setup (read-only)

- I ran the probes from `/workspace/.claude/wt-build-loop-u2b3b2b` with `resolve_main; reader_settings; ROOT_REAL=$(pwd -P)` and `LC_ALL=C`, using the real `HOME=/home/node`.
- I timed with `EPOCHREALTIME` and wrapped `outside_proj` and `import_file` to count and time each call.
- Load average was 0.4–0.6 on 16 CPUs and the cache was warm.
- `import_readers` produced 15 roots: ROOT_REAL, /workspace, 6 worktrees under `/workspace/.claude/`, and 7 `/home/magfrump/...` spellings that are absent here. It produced 2 homes: `/home/node` and `/home/magfrump`.
- For the baseline I extracted main's lib (07fe578b) with `git show` to the scratchpad and sourced it the same way.

| Measure | main's lib | branch lib |
|---|---|---|
| `imported_names` wall | 609 ms | 7356 ms; 7793 ms in a second run |
| `main_imports` wall | (not run) | 6734 ms |
| files read by the walk (`import_file` calls) | 45 | 230 |
| summed `import_file` time (inside its subshell) | 281 ms | 3004 ms |
| `outside_seeds` | n/a | 1924 ms, 143 seeds (85 `f`, 58 `p`) |
| `outside_proj` | n/a | 230 calls, 395 ms per walk |

These numbers confirm the header's claims of "about 140 seed files and 7 s per walk, against 0.7 s". The claim that "the file-system listing of other roots is about 1.9 s" holds only for `outside_seeds` as a whole. `find` is about 0.5 s of that time (finding P2).

Where the branch's ~7.4 s goes (tree walk):
- **About 5.4 s, per-file reads.** The walk reads 230 files instead of 45, at about 23 ms each all-in. That covers the `$(...)` subshell, `import_outside`'s realpath, `capped_read`, `env sed`, `env awk`, `lower`, `outside_proj`, and the per-line loop.
  - 45 are repo files (9 ms average inside `import_file`).
  - 58 are under `/home/node/.claude` (17.7 ms average).
  - 42 are `/opt/...` re-reads, which are real-path projections of `~/.claude/skills`. That directory is a symlink to `/opt/claude-workflows/skills`.
  - 85 are other absolute paths (12.1 ms average): `devcontainer-config/claude-home`, `runs/review-arms`, and `external/*`.
- **About 1.9 s, `outside_seeds`.**
  - `find -P /workspace`: 522 ms. It walks about 410k entries, 381k of them under `/workspace/external`.
  - `lower_all` over 24,663 names: 394 ms.
  - The `isstart` bash loop over those names: 683 ms, for 351 hits.
  - The ROOT_REAL drop loop: about 109 ms.
- **About 0.4 s, `outside_proj`.**

## Data Flow and Hot Paths

- Both walks are memoized per decision (`IMPORTED_DONE` and `IMPORTED_MAIN_DONE`). `import_reset` clears them.
- The gate's `check_line` calls `import_reset` for each brief (`scripts/build-loop.sh:675`), and `--check` loops over briefs (`scripts/build-loop.sh:750`). `floor` therefore pays one main walk per self-merge brief per `--check`. `--check-fix` pays one tree walk per `dev-cycle.sh` process.
- Neither path serves requests. Both are **cold**: CLI gate decisions, one walk each, at one or a few per loop iteration.
- The cost does multiply: about 7 s × the number of briefs in one `--check`. It also runs on the path of a build loop that is waiting for a merge decision.
- Following the skill's matrix, every finding below starts at Low or Informational. I raise one finding to Medium because of a 10× regression and an input with no bound.

## Findings

#### F1. Most of the added time reads files that can yield no import name

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1160-1167` (`import_outside`), `:1393-1396` and `:1474-1477` (seed queuing), `:1248` (every `.md` under prompt dirs and the plugin cache seeded as `p`)
**Move:** Count the hidden multiplications / find the work that moved to the wrong place
**Classification:** Macro (read count grows with the number of `.md` files under config dirs and other roots) / Cold path (one walk per gate decision, multiplied by briefs per `--check`)
**Confidence:** Medium (the measurement is High; the estimated saving is Medium)
**Baseline:** 7356 ms per `imported_names` walk over /workspace, with 230 files read against 45 on main's lib (609 ms). Measured 2026-10-09, read-only probe `u2b3b2b-perf-probe3.sh`.
**Legibility-target:** the walk header's cost sentence (`:749-752`) and the `outside_seeds` comment (`:1197-1215`)

**Evidence:**
- Seeding `p` files: `if [[ ${#pr[@]} -gt 0 ]]; then nul_list fl find -L "${pr[@]}" -type f -iname '*.md' -print0 || return 1; for d in "${fl[@]}"; do os_a+=("p$d"); done; fi`
- The parser fires only on an `@` byte (`IMPORT_AWK` `scan`): `if (substr(line, i, 1) != "@") continue`
- Measured: 168 of the 230 files the walk read hold no `@` byte (128 of them outside files). Their reads alone cost 2199 ms inside `import_file`, before the per-file subshell, `lower` and `outside_proj` overhead. 93 of the 143 seeds hold no `@`.

`IMPORT_AWK` emits a name only after an `@` byte. UTF-8 repair replaces bytes with U+FFFD and never adds an `@`, and `IT_WHOLE` is not used for a file's own text. So a file with no `@` contributes only one thing: `import_outside`'s real-path projection (`:1165`). Even so, the walk spends the full per-file pipeline on it, and spends it twice for each `~/.claude/skills` file, once under the link spelling and once at its `/opt` real path. Neither `IMPORT_OUT_MAX` nor `IMPORT_WORK_MAX` charges an `@`-free read, because its work and output are 0. As a result, time grows with no bound as the number of `.md` files under config dirs and other roots grows, which is not the fail-closed bound the budgets give elsewhere. Some examples:
- every `.md` in an installed plugin version (READMEs included: `.../frontend-design/ac996c0dde7f/README.md` is a seed);
- a skill's reference docs;
- a parse failure of `installed_plugins.json`, which falls back to the whole cache.

At about 23 ms per file, 1,000 such files add about 23 s per walk. That estimate is extrapolated, not measured.

**Recommendation:** Two cheap changes keep the superset and fail closed:
1. In `outside_seeds`, after the seed list is built, run one `grep -LZF @ -- <seed paths>` call. Exit 2 fails the walk. Then run one `realpath -ez` over the `@`-free seeds. Drop any `@`-free seed whose real path is below no reader root. Its only output would be its own `//` real-path line, which the walk would re-read and which also holds no `@`. Keep the rest.
2. In `import_outside`, short-circuit the `capped_read | import_targets` pipeline for an `@`-free file, still projecting the real path. This catches imported files too.

On these figures the two changes should save roughly 3 of the 7.4 s. Ask the fact-check to confirm the claim "no `@` byte, no name" against `IMPORT_AWK` before relying on it.

#### F2. `outside_seeds` runs `lower_all` and a bash `isstart` loop over every `.md` name instead of prefiltering with `instruction_names`

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1264-1270`
**Move:** Check the asymptotic behavior / prior art in the codebase
**Classification:** Micro per name, but O(all `.md` files under listed roots) / Cold path
**Confidence:** High
**Baseline:** `outside_seeds` 1924 ms per walk. Within it: `lower_all` over 24,663 names 394 ms, the `isstart` loop 683 ms, `find` 522 ms, and the ROOT_REAL drop loop about 109 ms. Measured 2026-10-09, probe `u2b3b2b-perf-probe2.sh`.
**Legibility-target:** `outside_seeds` C1 block, and the header phrase "the file-system listing of other roots is about 1.9 s of it" (`:751-752`)

**Evidence:**
- `nul_list fl find -P "$r" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -printf '%P\0' || return 1`
- `for d in "${fl[@]}"; do [[ "$r/$d" == "$ROOT_REAL"/* && "$r" != "$ROOT_REAL"/* ]] || { rel+=("$d"); abs+=("$r/$d"); }; done`
- `[[ ${#rel[@]} -eq 0 ]] || nul_list lo lower_all "${rel[@]}" && [[ ${#lo[@]} -eq ${#rel[@]} ]] || return 1`
- `isstart "${lo[i]}" || continue`
- Prior art, `:1295-1300`: "Start names among NUL-separated paths on stdin: one grep, before the tree walk forks lower and a plain check per path (forking for every tracked file took seconds). It matches isstart's names; isstart stays the authority."

Of 24,663 listed names, only 351 pass `isstart`. Running `instruction_names` over the same list returned the same 351 in 80 ms. Piping the `find -P` output through `instruction_names` (under pipefail, as `tree_starts` does) before the ROOT_REAL loop, `lower_all` and `isstart` keeps `isstart` as the authority and keeps the superset. It should cut about 1.1 s, bringing `outside_seeds` to about 0.7 s, mostly `find`. This also bounds the bash-side cost per worktree: without the filter, each worktree under /workspace adds about 1.7k names, roughly 80 ms. The header attributes 1.9 s to "the file-system listing". The listing itself (`find`) is about 0.5 s, and the rest is bash per-name processing.

**Recommendation:** Filter the C1 `find` output through `instruction_names` before the per-name loops, and reword the header's cost attribution.

#### F3. `outside_proj` forks a process substitution for every file read, even when there is nothing to project

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1187-1195`, called at `:1403` and `:1517`
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold path, called once per file read
**Confidence:** High
**Baseline:** 230 calls, 395 ms per tree walk and 399 ms per main walk. About 1 ms per call, even on an empty `OUT`. Measured 2026-10-09, probes 1–2.
**Legibility-target:** `outside_proj` comment

**Evidence:**
- `while IFS= read -r p; do [[ "$p" != //* ]] || outside_ok "${p#/}" || rj+=("${p#/}"); done < <(printf '%s\n' "$op_o")`
- `nul_list rl realpath -mz -- "${rj[@]}" && [[ ${#rl[@]} -eq ${#rj[@]} ]] || return 1`

Every file read pays for the `< <(printf ...)` subshell. Any file whose output holds a rejected `//` name also pays for a `realpath` fork. A pure-bash guard costs no fork and no change in semantics: `[[ "$op_o" == //* || "$op_o" == *$'\n//'* ]] || return 0`. It skips most calls, since 168 of 230 files yield no name at all. On the remaining calls, a here-string or a `${op_o//...}` split would also avoid the fork, though the lib avoids long here-strings on purpose (`:1135-1136`), so keep the process substitution there. The saving is about 0.2–0.3 s per walk. After F1 most such calls disappear anyway.

**Recommendation:** Add the guard to `outside_proj`.

#### F4. Scaling across worktrees, host aliases and reader homes

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1222-1235` (ancestors and config dirs), `:1259-1266` (C1 roots), `:1278-1281` (`sha1sum`)
**Move:** What's the size of N?
**Classification:** Macro / Cold path
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative (beyond the single 15-root, 2-home measurement above)
**Legibility-target:** walk header cost sentence

**Evidence:**
- `in=""; [[ "$r" == "$ROOT_REAL"/* ]] || for q in "${cr[@]}"; do [[ "$r" != "$q"/* ]] || in=1; done`
- `nul_list lo sha1sum -z -- "${hs[@]}" && [[ ${#lo[@]} -eq ${#hs[@]} ]] || return 1`

How the cost scales with each input:
- **Worktrees nested under the main root**, as all of them are here, add no `find` traversal, because `/workspace` already covers them. They do add about 1.7k names each to the bash loops (removed by F2). Each also adds a read of about 25 ms, plus its imports, for every start file whose bytes differ from ROOT_REAL's. A worktree outside the main root adds its own `find` walk.
- **Host-alias spellings** that are absent in the container cost nothing (`-d` fails). The ancestor loop is O(roots² × depth) in bash, which is trivial at 15 roots.
- **Each reader home** adds one `find -L` over its `.claude` prompt dirs and plugin versions, and every `.md` there is read. That linear term is the one F1 bounds.
- **`sha1sum` argument size.** It is one `exec` whose argument list is 2 × the C1 same-path candidates. At very large worktree counts (thousands of candidates) it could reach `E2BIG`. That fails closed: the walk refuses rather than answering wrong.
- **`outside_seeds` runs once per walk.** A process that ran both walks in one decision would list twice (about 1.9 s). No caller does that today: `floor` uses only `main` and `--check-fix` only `tree`.

**Recommendation:** None needed now. After F1 and F2, restate the header's cost line with the dominant term, the number of files read.

## Endorsements

- `outside_seeds` lists other roots with one `find -P` per non-nested root, skipping roots nested inside another listed root. With 15 roots it ran exactly one `find -P` (/workspace). [read: scripts/lib/dev-cycle-read.sh:1259-1266]
- The C1 same-bytes check hashes every candidate pair in one `sha1sum` call rather than forking per file. [read: scripts/lib/dev-cycle-read.sh:1271-1281]
- Plugin versions come from one `python3 -I` parse over every `installed_plugins.json`, not one call per file. [read: scripts/lib/dev-cycle-read.sh:1238-1246]
- The walks remain memoized per decision, so `outside_seeds` runs once per walk rather than once per `isimported` query. [read: scripts/lib/dev-cycle-read.sh:1374-1392, 1431-1473]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | 168 of 230 reads are `@`-free files that can yield no name; time has no bound as config-dir `.md` count grows | Medium | `scripts/lib/dev-cycle-read.sh:1160-1167, 1248, 1393-1396, 1474-1477` | Medium |
| F2 | `lower_all` and `isstart` over 24.6k names instead of the `instruction_names` prefilter (about 1.1 s) | Low | `scripts/lib/dev-cycle-read.sh:1264-1270` | High |
| F3 | `outside_proj` forks on every file, even with no `//` name | Low | `scripts/lib/dev-cycle-read.sh:1187-1195` | High |
| F4 | Scaling across worktrees, aliases and homes; `sha1sum` `E2BIG` cliff fails closed | Informational | `scripts/lib/dev-cycle-read.sh:1222-1281` | Medium |

## Overall Assessment

The 10× cost (0.6 s to 7.4 s per walk) is real and matches the header. For a cold, fail-closed gate path it is acceptable to land as it stands. Nothing here is a correctness risk.

The cost is not in the file-system listing, though:
- **About 73% is per-file reading**: 230 files instead of 45, three quarters of which hold no `@` byte and therefore cannot yield a name.
- **About 26% is `outside_seeds`**, mostly bash processing of 24.6k `.md` names, of which only 351 are start files. `find` itself is about 0.5 s.

Both fixes stay inside the design (superset, `isstart` as the authority, fail closed) and reuse patterns the lib already has (`instruction_names`, batched `nul_list` calls):
- the `@`-free short-circuit and drop (F1);
- the `instruction_names` prefilter (F2).

Together they should bring a walk to roughly 3 s. F1 matters most, because it is also the only input whose time no budget bounds.

## Goal-Alignment Note

The goal is to land U2b3b2b after a clean review-fix loop. Nothing here blocks it:
- **F1 (Medium)** is a fixable proportionality and scaling issue on a cold path. It can be fixed in this unit, using about 15 lines and the existing `nul_list` and `realpath` patterns, or routed to the override log as a follow-up. Either way, the header's cost sentence should name the real dominant term.
- **F2 and F3** are small edits that do not change behavior.
- **F4** needs no action.

All my probes read only and used the real repo and `HOME`. They were timed under `timeout`. My temp dirs carry the prefix `/tmp/u2b3b2b-perf-`, and I wrote no repo file other than this report.
