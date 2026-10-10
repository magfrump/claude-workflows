Commit: 8f99fcaf

# Performance Review: feat/build-loop-u2b3b2b (U2b3b2b, outside seeds), final confirming pass

**Scope:** `git diff main...HEAD -- scripts test` at 8f99fcaf, mainly `scripts/lib/dev-cycle-read.sh`: `with_at`, `root_starts`, `outside_seeds`, `outside_proj`, `import_outside`, and the seed loops in `imported_names` and `main_imports`
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2b-final/shared.md`; merged fact-check `code-fact-check-report-build-loop-u2b3b2b-final.md` (Claims 10, 21, 40 bear on cost); my iteration-1 and iteration-2 reports; override rows 579-586.

## Measurement setup

The real-repo runs were read-only:
- They ran from `/workspace/.claude/wt-build-loop-u2b3b2b` with `resolve_main; reader_settings; ROOT_REAL=$(pwd -P)`, `LC_ALL=C` and the real `HOME=/home/node`.
- Each lib was extracted with `git show <rev>:scripts/lib/dev-cycle-read.sh` into a temp dir.
- Load average was 0.4-1.1 on 16 CPUs, with a warm cache.
- `import_readers` gave 15 roots and 2 homes.

The scaling runs were hermetic:
- Each used a temp repo, a temp `HOME` and `IMPORT_MANAGED_DIR=/nonexistent/managed`, with `CLAUDE_CONFIG_DIR` unset.

Probes `u2b3b2b-fperf-probe{1,2,3}.sh` are in the session scratchpad. Every temp dir (`/tmp/u2b3b2b-fperf-*`) was removed, and no process outlived its probe.

| Measure (real repo) | main (07fe578b) | 39f64d62 (i2) | 8f99fcaf (HEAD) |
|---|---|---|---|
| `imported_names` wall | 531, 548 ms | 2818, 2896 ms | 1872-3425 ms over 7 runs (median 2340) |
| `main_imports` wall | 735, 849 ms | 3518, 3696 ms | 2257-2486 ms over 7 runs |
| seeds | n/a | 85 (35 without `@`) | 50 (41 `f`, 9 `p`; 0 without `@`) |
| files read by the tree walk | 45 | 172 | 102 |
| `outside_seeds` | n/a | 512-525 ms | 509-531 ms |
| `root_starts /workspace` | n/a | 447 ms (i2) | 410 ms |
| `with_at` (config phase, C1 phase) | n/a | n/a | 3 ms over 58 paths, 8 ms over 351 |
| names, `//` dropped | 64 / 64 | 1177 / 1177 | 1177 / 1177, byte-identical to 39f64d62 |
| `//` lines in IMPORTED | none | n/a | 601 lines, 27,785 bytes (IMPORTED 80,855 bytes) |
| `isimported`, 100 lookups | n/a | n/a | 389 ms (tree), 462 ms (main) |

What the scaling runs measured (`probe2`; tree walk / main walk / `outside_seeds`):

| Case | N | `outside_seeds` | tree | main |
|---|---|---|---|---|
| `@`-free `.md` in `~/.claude/skills` | 0 / 2,000 / 20,000 | 8 / 86 / 775 ms (0 seeds) | 27 / 108 / 820 ms | 24 / 114 / 807 ms |
| `.md` holding `@nxK.md` in `~/.claude/skills` | 25 / 100 / 400 | 12 / 16 / 36 ms | 318 / 1188 / 5064 ms | 354 / 1188 / 6174 ms |
| `~/.claude/skills` linked to an `@`-free dir in ROOT_REAL | 25 / 100 | 12 / 18 ms | 502 / 2077 ms | 441 / 1869 ms |
| extra worktrees, each with a `CLAUDE.local.md` holding `@` | 2 / 8 / 32 | 19 / 39 / 136 ms | 56 / 121 / 402 ms | 54 / 116 / 406 ms |
| 3 worktrees, 20,000 untracked `.txt` each | 20,000 | 60 ms | 91 ms | 89 ms |

## Data Flow and Hot Paths

Nothing has changed since iteration 1:
- Both walks are cold CLI gate paths, memoized per decision (`IMPORTED_DONE`, `IMPORTED_MAIN_DONE`).
- `floor` pays one main walk per self-merge brief per `--check`. `--check-fix` pays one tree walk per process.
- `outside_seeds` runs once per walk (override row 583 covers the recompute).

Iteration 2's commit changed three things:
- `with_at` adds one in-process `outside_ok` test per path and one `xargs`-batched `grep -lZF`. It replaces two inline greps.
- The config seeds' `realpath -mz` now runs under `xargs`.
- A link-reached `@`-free config seed is kept only when its real path lies below a reader root. The test is a pure-bash loop over the roots.

The per-seed cost is one `import_file`: a `$(...)` subshell, `realpath -ez`, `capped_read`, `sed`, `awk`, a second projection when the path is a link, then `outside_proj` and a `lower` fork. It measures about 12-15 ms per `@`-bearing seed and about 20 ms per link-reached seed.

## Findings

#### F1. Each seed holding an `@` costs one file read per walk (12-15 ms), and nothing caps how many there are

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1304-1311` (config keep rule), `:1330-1337` (C1 keep rule), `:1453-1456` and `:1534-1537` (seed queuing), `:1171-1178` (`import_outside`)
**Move:** What's the size of N? / Count the hidden multiplications
**Classification:** Macro (linear in the `@`-bearing `.md` files under config dirs, installed plugin versions and other roots' starts) / Cold path (one walk per gate decision, multiplied by briefs per `--check`)
**Confidence:** High for the measurement; Medium for how many `@`-bearing files a real config holds
**Baseline:** 400 seeds that each hold `@nxK.md`: tree walk 5064 ms and main walk 6174 ms, against 27 ms and 24 ms with no seeds. Measured 2026-10-09 with `u2b3b2b-fperf-probe2.sh` on a hermetic temp repo.
**Legibility-target:** the walk header's cost line (`:759-761`)

**Evidence:**
- Keep rule: `isstart "${lo[i]}" && [[ -n "${os_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue`
- Filter: `with_at() { ... sh -c 'grep -lZF -e @ -- "$@"; [ $? -le 1 ]' sh`
- Probe 2: `at N=25 ... imported_names rc=0 318 ms`; `at N=100 ... 1188 ms`; `at N=400 ... imported_names rc=0 5064 ms` and `main_imports rc=0 6174 ms`
- Probe 3 on the real repo: `seeds=50 yielding no repo-relative name directly: 9`

The `@` filter fixed iteration 1's main cost. Its test is a single byte, though, and `.md` files often hold an `@` that is not an import: an email address, an npm scope, a decorator, an @-mention. In the real repo, 9 of the 50 seeds that pass the filter yield no repo-relative name.

The cost is linear, at 12-15 ms per seed per walk. The only cap is the walk's work and output budgets (`IMPORT_WORK_MAX`, `IMPORT_OUT_MAX`), and those cap bytes parsed, not file count. A user who installs a documentation-heavy plugin, or keeps a large skills tree, pays about 1 s per walk for every 70 such files. A `--check` over several self-merge briefs pays it once per brief.

Today's configuration costs about 0.7 s per walk (50 seeds). That is within the header's stated range, and the cost is proportional and fail-safe. This is a residual of the design, not a defect.

**Recommendation:** No code change in this unit. Record it in the override log as a cold-path residual with a revisit trigger: seeds over about 200, or a walk over 5 s. If that trigger fires, tighten the filter to the parser's own start condition (an `@` followed by a non-blank) or cache seed reads across briefs within one `--check`. Optionally add "about 12-15 ms per seed" to the header's cost line, so a reader can price a larger config.

#### F2. The header's timing line reads 2 to 2.5 s; the tree walk measures 1.9 to 3.4 s

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:759-761`
**Move:** Check the asymptotic behavior (stated cost)
**Classification:** Micro (stated constant) / Cold path
**Confidence:** High
**Baseline:** 7 tree-walk runs at HEAD measured 1872-3425 ms (median 2340 ms), and 7 main-walk runs measured 2257-2486 ms. Load was 0.7-1.1 on 16 CPUs. Measured 2026-10-09 with `u2b3b2b-fperf-probe1.sh` and `-probe3.sh`.
**Legibility-target:** for-author: the header's timing line

**Evidence:**
- Header: `# this repository's 8 registered worktrees, about 50 seeds and 2 to 2.5 s per` / `# walk, against 0.6 s without (2026-10-09; i1, i2 performance).`
- Probe 3: `run 1 tree=1872 ms main=2257 ms` ... `run 5 tree=3425 ms main=2486 ms`

The seed count (50) and the 0.6 s baseline (main's lib: 531-548 ms) are exact. The main walk sits inside the stated range. The tree walk has a tail up to 3.4 s under modest load, which matches fact-check Claim 10 (Mostly accurate, 2.1 to 3.1 s).

**Recommendation:** Optional: change the line to "2 to 3 s". There is no performance action.

#### F3. A config tree linked into a reader root keeps every `@`-free file as a seed, at about 20 ms each

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1308-1311` (the link exception), `:1175-1176` (`import_outside` reads the content, then projects the real path)
**Move:** Count the hidden multiplications
**Classification:** Macro (linear in the `.md` files of the linked tree) / Cold path
**Confidence:** High for the measurement; Low for how often it occurs (it depends on the host's link layout)
**Baseline:** with `~/.claude/skills` linked to an `@`-free directory in ROOT_REAL, 100 files cost 2077 ms (tree walk) and 1869 ms (main walk), and 25 files cost 502 ms and 441 ms. Measured 2026-10-09 with `u2b3b2b-fperf-probe2.sh`.
**Legibility-target:** none needed

**Evidence:**
- `[[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done`
- `a="$(capped_read < "$1" | import_targets "${d:-/}" "${@:2}")" && import_work a w || return 1`

The keep rule is correct: the projection turns the link into the repo path, which a session loads as a skill. It is iteration 2's L1, applied as intended.

Reading the `@`-free content under the link spelling yields nothing, however. The walk then reads the projected repo file a second time as a checkout file. In this container `~/.claude/skills` links into `/opt`, which lies below no root, so the case does not arise. A host whose `~/.claude/skills` links into a checkout of this repository that is also a reader root would keep all 41 `skills/**/*.md` files (35 of them `@`-free), at about 0.8 s per walk.

**Recommendation:** None now. If that host layout is the user's, `import_outside` could skip the content read for a seed that `with_at` already found `@`-free and only project it. The walks do not carry that bit today, so this is not worth adding before U2b3b2c reshapes the seeds.

## Endorsements

- L1 (the narrowed link exception) removed exactly the 35 `@`-free `/opt` seeds: from 85 seeds to 50, and from 172 files read to 102. Both walks' repo-name sets are unchanged (1177 / 1177, byte-identical between 39f64d62 and 8f99fcaf in my runs). [fact-check: claim 40 — Mostly accurate]
- `with_at` makes one in-process `outside_ok` test per path, then one `xargs`-batched `grep -lZF` per phase. The `xargs` batching removes the `E2BIG` cliff, and `-l` stops at a file's first `@`. [read: scripts/lib/dev-cycle-read.sh:1219-1225]
- Claim: the batched config `realpath -mz` (B2) and `with_at` together scale at about 39 µs per `@`-free config file. 20,000 such files cost 775 ms in `outside_seeds`, with rc=0 and no `E2BIG`. [unverified — submitted as claim]
- Claim: override row 575's revisit trigger has not fired. The `//` lines in IMPORTED total 27,785 bytes (601 lines), against the 2.6 MB that row priced at about 14 ms per lookup. `isimported` measures about 4 ms per lookup, mostly its `lower` fork. [unverified — submitted as claim]
- Claim: adding worktrees costs about 12 ms per walk each when every worktree holds one `@`-bearing start (32 worktrees: 402 ms). Untracked bulk outside `.md` names adds only `find` traversal (60,000 `.txt` files: 60 ms). [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Each `@`-bearing seed costs 12-15 ms per walk with no count cap: 400 seeds take 5-6 s; 9 of the 50 real seeds yield no repo name | Low | `scripts/lib/dev-cycle-read.sh:1304-1311`, `:1330-1337`, `:1453-1456`, `:1534-1537`, `:1171-1178` | High (measured) / Medium (real-config N) |
| F2 | The header says 2 to 2.5 s; the tree walk measures 1.9-3.4 s (median 2.3) | Informational | `scripts/lib/dev-cycle-read.sh:759-761` | High |
| F3 | A config tree linked into a reader root keeps every `@`-free file (about 20 ms each, by design) | Informational | `scripts/lib/dev-cycle-read.sh:1308-1311`, `:1175-1176` | High / Low (frequency) |

## Overall Assessment

The branch's cost posture is sound for a cold gate path:
- Walks cost about 2.3 s against 0.55-0.85 s on main.
- `outside_seeds` costs about 0.5 s, most of it the `find -P /workspace` traversal, which is inherent (override row 586).
- Iteration 2's changes (`with_at`, batched `realpath`, the narrowed link exception) cut 35 seeds and about 0.6-1.2 s per walk with no name change. They added no measurable cost: `with_at` takes 3 ms and 8 ms per phase.
- Every per-file stage I scaled is linear, and the `@`-free stages are cheap (about 39 µs per file).

The one cost that grows with configuration is the per-seed read (F1), at 12-15 ms for each `@`-bearing file. It is fail-safe and proportional, and today it totals about 0.7 s. It needs an override row with a revisit trigger, not a fix. No profiling is needed beyond re-running probe 1 if the seed count grows.

## Goal-Alignment Note

- **Success criterion, restated:** a markdown report saved at the path the dispatch names, structured per the skill, with a Goal-Alignment Note.
- **Answered:** yes. It reviews the whole branch's cost, measured read-only against the real repo, and checks scaling with worktrees, config-dir size and linked homes.
- **Blocks landing U2b3b2b:** nothing. F1 (Low) should get one override-log row (cold-path residual, trigger: more than about 200 seeds or a walk over 5 s). F2 and F3 need no action. F2 is an optional one-word header edit.
- **Out of scope:** fact-check Claim 21 (the C1 byte skip under nested worktrees) is correctness, not cost, and is routed to security and the orchestrator. I did not probe it.
- **Hygiene:** I wrote no repo file other than this report. My temp dirs (`/tmp/u2b3b2b-fperf-*`) were removed, and no processes remain.
