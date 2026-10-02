Commit: d5d9121 (A) / fbc7101 (B)

# Performance Review — dev-cycle pass 21 (pass-20 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 546b86e..d5d9121 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff 46d3423..fbc7101 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle`. Focus: re-measure `--check-path` on a large repo after the 50-match cap and the narrowed ignored-file query (pass-20 findings 1–3). Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass20.md` (verdicts on 546b86e/46d3423, so it has no execution verdict on this round's lines). Also `performance-review-2026-10-02-digest-pass20.md`, whose findings this round answers.

> ⚠️ **No code fact-check report covers d5d9121 / fbc7101.** Performance claims in this round's comments have not been independently verified by a fact-check stage. The numbers below are my own executions. Runtime endorsements are submitted as claims.

**Measurements.** All mine, 2026-10-02, this sandbox (bash 5.2.15, git 2.39.5, env `LC_ALL=en_US.UTF-8`, a locale that is **not installed** here: `locale -a` lists only C, C.utf8, POSIX). Scripts are from `git show d5d9121:scripts/dev-cycle.sh` and `git show 546b86e:…` (for comparison). Scratch is `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf21/` (`perf21/` below). Every process ran under `timeout`. The throwaway repo is under a `mktemp -d` dir in `perf21/`. Nothing was written to either worktree except this file.

- **R2** was rebuilt with pass 20's generator (`perf21/gen.py`, `perf21/mkrepo.sh`). It has 50,003 tracked files (`src/dNNN/sN/fN.md`, depth 4) and 200,020 ignored files (200k under `node_modules/`, plus 20 ignored `docs/working/round-*.md`). `docs/working/feature-ideas.md` is tracked.
- `--check-path` wall time per call, two runs each (`perf21/check-path-times.log`), with pass 20's number for the same argument:

| Arg | d5d9121 (run 1 / run 2) | ok / skip | Pass 20 (546b86e) |
|---|---|---|---|
| `README.md` | 13 / 13 ms | 1 / 0 | 17 ms |
| `docs/working/feature-ideas*.md` | 14 / 14 ms | 1 / 0 | 14 ms |
| `docs/working/*.md` | 92 / 113 ms | 21 / 0 | 91–94 ms |
| `*` | 91 / 92 ms | 1 / 1 | 93–99 ms |
| `node_modules/*` | 11 / 12 ms | 0 / 1 | 64–68 ms |
| `src` (plain directory) | 337 / 329 ms | 0 / 1 | 345–346 ms |
| `.` | 7 / 7 ms (refused by form) | 0 / 1 | 1,870–1,939 ms |
| `src/d000/*/*.md` (1,000 matches) | 261 / 247 ms | 50 / 1 (cap) | 4,763–5,358 ms |
| `src/d00*/*/*.md` (10,000 matches) | 215 / 207 ms | 50 / 1 (cap) | 45,625 ms |
| `**/*.md` (50,022 matches) | **219 / 221 ms** | 50 / 1 (cap) | **231,060 ms** |
| `**` | 206 / 209 ms | 49 / 2 (`.gitignore` refused by form, then cap) | — |
| `src/**` | 213 / 208 ms | 50 / 1 (cap) | — |
| `*/working/x` | 92 / 94 ms | 0 / 1 | — |

- Which git commands ran (GIT_TRACE2_PERF, `perf21/trace-summary.log`):
  - `**/*.md` and `**`: the tracked `ls-files` was killed by **SIGPIPE (signo 13) at 0.224 / 0.228 s**, and the ignored query never started.
  - `src/**/s0/f1*.md`: the ignored query was skipped by the prefix test.
  - `**/s0/f1*.md` and `*`: the ignored query ran for 98 / 82 ms.
- The ignored listing over all 200,020 ignored paths, piped through the new `grep -z '^docs/working/'`, took **137–150 ms** (raw listing 125–158 ms), down from 1,481 ms for the old bash loop (`perf21/extra.log`).
- Loop for a plain directory (`git ls-files -z -- ':(literal)src'` into a bash `read -d ''` loop that only runs `continue`): **279–286 ms** for 50,000 entries.
- stderr per call (`perf21/extra.log`, and the env matrix in the session log) in this sandbox's default env:
  - 546b86e: **2 lines / 138 B** for every argument (bash's own startup warnings).
  - d5d9121: `README.md` **4 / 478 B**, `docs/working/*.md` **24 / 3,878 B**, `src/d000/s0/*` **53 / 8,808 B**.
  - With `LC_ALL=C.UTF-8` (installed): 0 lines. With `LC_ALL` unset (LANG or LC_CTYPE set to the missing locale): 0 lines.
- `bats test/scripts/dev-cycle.bats` on `git archive d5d9121`: **26/26 ok, rc 0, 7.65 s** (`perf21/bats.log`; 7.6 s at 546b86e).

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model running the skill and reading the check's output).

## Data Flow and Hot Paths

`--check-path` / `--check-write` are a separate mode (`:203-208`) that exits before any digest work. The skill (B `:61-76`) calls them from steps 2–6 and from step 4's per-merge subagents, once per batch of paths from repo text. B now also sends each roadmap brief path through `--check-write` before treating it as a brief. That adds one more call (no git, O(depth) forks) per brief path, or zero if it is batched with the other writes. Each call is a **cold path**: one agent Bash tool call. The standing escalation case is the agent's 120 s Bash timeout, and the agent's context, which receives the call's stdout **and stderr**.

Cost model for `--check-path` per argument, from reading `:105-137` and `:152-187` with every callee opened:
- `pathform` (pure bash, now with `local LC_ALL=C`, `:152-163`).
- `matches()` (`:164-173`): `git ls-files` (O(index)), then, only if the argument's fixed prefix (`${a%%[*?]*}`) is prefix-compatible with `docs/working/`, the ignored listing piped through one `grep -z`.
- Per match, up to `max=50` (`:175`, `:181`): `pathform "$m"` plus `inrepo "$m"`. That is one subshell and depth+1 `realpath` forks, about **4 ms per match** on R2 ((215 − 13) ms / 50).
- Per-argument ceiling for a glob: ≈ 13 ms fixed + listing + 50 × 4 ms ≈ **0.2–0.27 s on R2**, whatever the match count. A batch would need ~450+ broad globs to approach 120 s.
- The cap does **not** bound a plain argument that names a directory. `:179`'s `continue` runs before `n++` (`:180`), so every listed entry is still read through the bash loop (finding 2).

## Findings

#### 1. `local LC_ALL=C` emits a setlocale warning on every `pathform` return when `LC_ALL` names an uninstalled locale: one stderr line per argument plus one per match, about 64× the stderr of 546b86e for a capped glob

**Severity:** Low. Preconditions: `LC_ALL` is set to a locale that is not installed. That is this sandbox's default (`LC_ALL=en_US.UTF-8`, `locale -a` = C, C.utf8, POSIX), so it is the environment where the agent actually runs the skill. With an installed locale, or with `LC_ALL` unset, there are no extra lines.
**Location:** `scripts/dev-cycle.sh:152-163` (called at `:176` and `:182`, and from `check_write` `:198`) (A, d5d9121)
**Evidence (verbatim):**
```bash
pathform() {  # $1 path, $2 "glob" to allow * and ?
  # C locale: ranges and case folding must not depend on the user's locale (a
  # Turkish one can fold .GIT to something other than .git).
  local LC_ALL=C p="$1" rest c set='^[A-Za-z0-9._/-]+$'
```
(The excerpt is `:152-155`. The function continues through `:163` (the glob charset, the regex test, and the per-component loop). I read all of it.) Observed stderr, `--check-path 'src/d000/s0/*'` on R2:
```
      1 …/dev-cycle.sh: line 176: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
     50 …/dev-cycle.sh: line 182: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
      2 bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
```
**Move:** Count the hidden multiplications (a per-call side effect multiplied by matches)
**Classification:** Micro (one stderr line per `pathform` call) / Cold path (one agent tool call per batch), graded up from Informational because it goes into the agent's context and undoes half of what the cap bounds
**Confidence:** High (measured, with an env matrix isolating the cause: 53 lines with `LC_ALL=en_US.UTF-8`, 0 with `LC_ALL=C.UTF-8`, 0 with `LC_ALL` unset)
**Baseline:** `perf21/extra.log`, 2026-10-02: stderr per call **138 B (546b86e) → 8,808 B (d5d9121)** for a 50-match glob, and 138 → 478 B for one literal path
**Legibility-target:** agent

When `pathform` returns, bash restores the caller's `LC_ALL`, and calls `setlocale` on the missing locale. Bash warns on each restore, so the warnings come once per argument (`:176`) and once per match (`:182`). The skill's Bash tool merges stderr into the agent's output. A capped glob then yields 50 `ok` lines interleaved with 50 warnings (about 8.8 KB instead of about 2 KB). A batch of k broad globs adds about 8.7 KB of noise per glob. The warnings sit between the `ok`/`skip` lines, so a parser that reads them (or an agent skimming them) has to skip non-answer lines. Wall time is unaffected (246 ms vs 270 ms with C.UTF-8, which is noise).

**Recommendation:** Set the locale once and do not restore it. For example, put `export LC_ALL=C` just before the check loop at `:203-204`. That covers `pathform`, `writable` and the children, and git and realpath are fine in C. Alternatively, spell the classes out (`[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._/-]`) and drop the `local`. A test that runs a check with `LC_ALL` set to an uninstalled locale and asserts empty stderr (beyond bash's startup lines) would pin it.

#### 2. A plain argument naming a directory is not bounded by the cap: every tracked entry under it goes through the bash `read -d ''` loop before the skip

**Severity:** Informational. Preconditions: repo text names a directory (not a glob), for example `src` or `packages/foo`, in a repo with a large tracked subtree.
**Location:** `scripts/dev-cycle.sh:178-181` (A, d5d9121)
**Evidence (verbatim):**
```bash
  while IFS= read -r -d '' m; do
    [[ "$a" == *[*?]* || "$m" == "$a" ]] || continue  # a plain path names one file, not a directory
    n=$((n + 1))
    if [[ $n -gt $max ]]; then echo "skip $a: matches more than $max files; the rest are not listed"; break; fi
```
(The excerpt is `:178-181`. The loop continues to `:185`, `done < <(matches "$spec" "$a")`, and `:186` prints the no-match skip. I read `check_path` `:174-187` whole.)
**Move:** Ask "what's the size of N?"
**Classification:** Micro (about 6 µs per discarded entry, from the byte-at-a-time read) / Cold path
**Confidence:** High (measured)
**Baseline:** R2: `--check-path src` **329–337 ms**, of which the listing plus the bash loop is **279–286 ms** for 50,000 entries (`perf21/extra.log`). A literal file takes 13 ms. It was 345 ms at 546b86e, so this is unchanged.
**Legibility-target:** maintainer

This is pass-20 finding 3's residual. The round fixed `.` (refused by form, 1.9 s → 7 ms), but not a named directory. Because `continue` comes before `n++`, the cap never trips, and the loop drains the whole listing to print one `skip`. That scales at about 6 s per million tracked files under the directory, which is far from the 120 s cliff, so it is Informational. If the fixed prefix is compatible with `docs/working/` (for example `docs`), the ignored walk under it also runs.

**Recommendation:** Optional. For a plain argument, filter git's output with one `grep -zxF -- "$a"` instead of the bash loop. Or test `[[ -d "$a" && ! -L "$a" ]]` up front and skip with the existing reason.

#### 3. A leading-wildcard argument still walks the whole ignored tree, and that walk can outlive the cap's `break`

**Severity:** Informational. Preconditions: a large ignored tree, and an argument whose fixed prefix is empty or `d…` (`*`, `**/…`, `*/working/x`, `?ocs/…`).
**Location:** `scripts/dev-cycle.sh:164-173` (A, d5d9121)
**Evidence (verbatim):**
```bash
  if [[ "$fixed" == docs/working/* || docs/working/ == "$fixed"* ]]; then
    GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- "$1" \
      | { grep -z '^docs/working/' || true; }
  fi
```
(The excerpt is `:169-172`. The remaining line `:173` closes `matches()`, and its output feeds `check_path`'s loop at `:178-185`. I read the whole function.)
**Move:** Find the work that moved to the wrong place
**Classification:** Macro (O(ignored files in the walked tree)) / Cold path
**Confidence:** High (measured)
**Baseline:** R2, trace2: the ignored `ls-files` ran **82 ms** for `*` and **98 ms** for `**/s0/f1*.md`. `*/working/x` totals 92–94 ms against 13 ms for a literal path.
**Legibility-target:** maintainer

An empty fixed prefix is prefix-compatible with `docs/working/`, so the query must run, and git walks the whole ignored tree to find out. That is correct, not a regression. With `grep` as the filter, the cost is git's walk alone, about 0.7–0.8 s per million ignored files. For `**/s0/f1*.md` (550 tracked matches, about 12 KB, small enough to fit the 64 KB pipe buffer), the tracked `ls-files` exits normally. `matches()` then starts the ignored walk even though the loop has already broken at 50. The walk runs to completion, because `grep` writes nothing and so never meets the closed pipe. The call's wall time includes it, since the wrapper waits on the subshell's stderr. When tracked output exceeds the pipe buffer (`**/*.md`, `**`), SIGPIPE ends the subshell first and the ignored walk never starts (trace2 signo 13). The extra time is bounded by the ignored-walk time above. No action is needed. This is noted so the 0.2 s ceiling above is not read as including this case's cost.

**Recommendation:** None required. If wanted, have the loop's `break` path stop the producer explicitly, or run the ignored query first only for arguments whose fixed prefix already starts `docs/working/`.

## Endorsements

- The cap removes pass-20 finding 1's 120 s cliff. On R2, `**/*.md` went from **231,060 ms to 219–221 ms** and 10,000 matches from **45,625 ms to 207–215 ms**. A glob's per-argument cost is now bounded at about 50 × 4 ms plus the listing, whatever the match count, and its stdout is bounded at 51 lines. `[unverified — submitted as claim]` (my execution, not a fact-check verdict)
- On the cap's `break`, when tracked output exceeds the pipe buffer, the tracked `ls-files` dies by SIGPIPE at about 0.22 s and the ignored query never starts. trace2 shows `signal signo:13` and no second `ls-files` for `**/*.md` and `**`. `[unverified — submitted as claim]` (my execution)
- The ignored filter is now one `grep -z`. Filtering 200,020 ignored paths costs 137–150 ms in total (essentially git's own walk), down from 1,481 ms for the bash loop alone. Arguments whose fixed prefix is incompatible with `docs/working/` skip the query: `node_modules/*` went from 64–68 ms to 11–12 ms, and `src/**` ran no ignored `ls-files` (trace2). `[unverified — submitted as claim]` (my execution)
- Claim for the fact-check stage: the prefix test at `:169` skips the ignored query only when the argument's fixed prefix and `docs/working/` are prefix-incompatible. Since `pathform` admits no `[`, `\` or magic other than `*`/`?`, every match of the glob starts with the fixed prefix, so no ignored file under `docs/working/` is lost by the skip (for example `*/working/x`, `d*/working/*` and `docs/*/idea.md` all still run the query). `[unverified — submitted as claim]`
- Refusing `.` components takes `--check-path .` from 1.9 s to 7 ms. B's added `--check-write` gate on roadmap brief paths is cheap: `check_write` does no git call and no listing. `[read: scripts/dev-cycle.sh:196-202, :191-195, :119-129, :108-111]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `local LC_ALL=C` restore warns once per `pathform` call when `LC_ALL` names an uninstalled locale (this sandbox): 53 stderr lines / 8.8 KB per capped glob vs 2 / 138 B before | Low | `scripts/dev-cycle.sh:152-163` | High |
| 2 | A plain directory argument bypasses the cap: the whole tracked subtree is drained through the bash loop (`src` 329–337 ms, about 6 s per million) | Informational | `scripts/dev-cycle.sh:178-181` | High |
| 3 | Leading-wildcard args still walk the whole ignored tree (82–98 ms on 200k), and the walk can run past the cap's `break` | Informational | `scripts/dev-cycle.sh:164-173` | High |

## Overall Assessment

The round fixes pass-20's real scaling hazard. A glob's `--check-path` cost is now capped at about 0.2–0.27 s per argument on a 50k-tracked / 200k-ignored repo, independent of the match count (it was 231 s for `**/*.md`). The ignored-file filter is now git's walk plus one `grep`, and it is skipped entirely for arguments that cannot reach `docs/working/`. No path in this delta can approach the 120 s tool timeout at realistic sizes. The one new cost is finding 1. The C-locale change, scoped with `local`, makes bash re-set the caller's locale on every `pathform` return. In this sandbox's environment (`LC_ALL` naming an uninstalled locale), that adds a warning per argument and per match to the agent's output. It is fixable in place: set `LC_ALL=C` once for the check modes. Findings 2 and 3 are Informational residuals and need no action before merge. No further benchmarking is needed. For finding 1, a test that runs with `LC_ALL` set to an uninstalled locale would pin the fix.

**Outside this lane (for the fact-check / API stages, not graded here):**
- The cap counts tracked matches before ignored ones (`matches()` prints tracked first). A glob with more than 50 tracked matches therefore never lists the ignored `docs/working/` files it also matches: `**/*.md` on R2 shows no `round-*.md`.
- The cut is deterministic for a given index: tracked in index order, then ignored in walk order.
- A path refused by form (`.gitignore` under `**`) counts toward the 50.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass21.md` with the first line `Commit: d5d9121 (A) / fbc7101 (B)`. It follows the performance-reviewer structure: a header, the no-fact-check warning, data flow and hot paths, findings with Severity, Location, verbatim Evidence (with truncation markers), Move, Classification, Confidence, Baseline and Legibility-target, then evidence-tagged endorsements (unverified ones marked `[unverified — submitted as claim]`), a summary table and an overall assessment. It covers the brief's assigned scope: `--check-path` re-measured on a large repo after the cap and the narrowed ignored query. It is not committed, per instructions.
