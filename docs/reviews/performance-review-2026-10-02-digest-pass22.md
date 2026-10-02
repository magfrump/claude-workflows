Commit: bc98571 (A) / 6c8ae91 (B)

# Performance Review — dev-cycle pass 22 (pass-21 fix round, k=1 delta)

**Scope:** Partial. A: `git diff d5d9121..bc98571 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff fbc7101..6c8ae91 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` in `/workspace/.claude/wt-devcycle`. Focus: re-measure `--check-path` on a large repo after the plain-path `grep -zxF` filter, the directory skip reason and the `env LC_ALL=C` grep change, and confirm that stderr stays bounded under an uninstalled locale. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass21.md`. Its verdicts are on d5d9121/fbc7101, so it has no execution verdict on this round's lines. Claims 6 and 8 there describe the two behaviours this round replaces. Also `performance-review-2026-10-02-digest-pass21.md` (findings 1–3), which this round answers.

> ⚠️ **No code fact-check report covers bc98571 / 6c8ae91.** Performance claims in this round's comments have not been independently verified by a fact-check stage. The numbers below are my own executions. Runtime endorsements are submitted as claims.

**Measurements.** All are mine, taken 2026-10-02 in this sandbox: bash 5.2.15, git 2.39.5, env `LC_ALL=en_US.UTF-8`. That locale is **not installed** here (`locale -a`: C, C.utf8, POSIX).
- Scripts: `git show bc98571:scripts/dev-cycle.sh` (identical to the worktree file), plus `git show d5d9121:…` for comparison.
- Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf22/` (`perf22/` below).
- Every process ran under `timeout`. The throwaway repo is under a `mktemp -d` dir in `perf22/`. Nothing was written to either worktree except this file.

- **R2** was rebuilt with pass 21's generator (`perf22/gen.py`, `perf22/mkrepo.sh`, copied from `perf21/`). It has 50,003 tracked files (`src/dNNN/sN/fN.md`) and 200,020 ignored files (200k under `node_modules/`, plus 20 ignored `docs/working/round-*.md`).
- **R3** is R2 plus 50,000 ignored files under `docs/working/scratch/dNNN/` and one ignored non-UTF-8 name `docs/working/caf\xe9.md`, both via `.git/info/exclude`. `git ls-files -o -i --exclude-standard -- docs/working` lists 50,021.
- Wall time per `--check-path` call, two runs each (`perf22/times-bc9.log`, `perf22/times-d5d.log`, `perf22/times-r3.log`). stderr is the call's own stderr:

| Arg | Repo | bc98571 (run 1 / run 2) | Output | stderr | d5d9121, same session |
|---|---|---|---|---|---|
| `README.md` | R2 | 14 / 14 ms | ok | 2 lines / 138 B | 14 ms, 4 lines / 486 B |
| `src` (plain dir, 50k tracked under it) | R2 | **17 / 17 ms** | `skip src: a directory, not a file` | 2 / 138 B | **350 / 351 ms**, 3 / 312 B |
| `src/d000` | R2 | 15 / 15 ms | a directory | 2 / 138 B | 20 ms |
| `nope/missing.md` | R2 | 12 / 12 ms | no tracked file | 2 / 138 B | 11–12 ms |
| `docs/working/round-3.md` (ignored) | R2 | 18 / 19 ms | ok | 2 / 138 B | — |
| `docs/working/*.md` | R2 | 88 / 92 ms | 21 ok | 2 / 138 B | — (pass 21: 92–113) |
| `*` | R2 | 94 / 92 ms | 1 ok / 1 skip | 2 / 138 B | — (pass 21: 91–92) |
| `src/d000/*/*.md` (1,000 matches) | R2 | 247 / 307 ms | 50 ok + cap | 2 / 138 B | `src/d000/s0/*`: 254 ms, **53 lines / 9,012 B** |
| `**/*.md` (50k matches) | R2 | 229 / 224 ms | 50 ok + cap | 2 / 138 B | — (pass 21: 219–221) |
| `**/s0/f1*.md` | R2 | 257 / 251 ms | 50 ok + cap | 2 / 138 B | — (pass 21: 267) |
| `*/working/x` | R2 | 94 / 95 ms | no match | 2 / 138 B | — (pass 21: 92–94) |
| `docs/working` (plain dir, 50,021 ignored under it) | R3 | **481 / 478 ms** | a directory | 2 / 138 B | 504 / 501 ms |
| `docs` | R3 | 466–488 ms (6 runs, one outlier at 1,811 ms) | a directory | 2 / 138 B | 486 / 486 ms |
| `docs/working/scratch` | R3 | 510 / 501 ms | a directory | 2 / 138 B | — |
| `docs/working/scratch/d000` (1,000 ignored) | R3 | 31 / 30 ms | a directory | 2 / 138 B | — |

- **R3 cost split for the plain `docs/working` case** (`perf22/r3-components.log`, three runs each):
  - the raw ignored `ls-files` takes 26–27 ms;
  - the same listing piped through `env LC_ALL=C grep -z '^docs/working/'` into a bash `read -d ''` loop that only `continue`s takes **410–425 ms**;
  - piping the listing through `env LC_ALL=C grep -zxF -- docs/working` instead takes **26 ms**.
- **Batch:** 120 arguments in one call (40 literal files, 40 plain directories, 40 copies of `docs/working/*.md`) took **4,149 ms**, printed 920 stdout lines, and wrote **2 stderr lines / 138 B** (`perf22/batch.log`).
- **Locale matrix** for one call with `'docs/working/*' 'docs/working/c*' docs/working '**/*.md'` on R3 (`perf22/locale-matrix.log`):

  | `LC_ALL` | stderr | stdout | non-UTF-8 name |
  |---|---|---|---|
  | `C.UTF-8` (installed) | 0 lines | 75 lines | `skip docs/working/caf\351.md: not an allowed path form` printed |
  | `en_US.UTF-8` (uninstalled) | 2 lines (bash start-up only) | 75 lines | same skip line printed |
  | `tr_TR.UTF-8` (uninstalled) | 2 lines (bash start-up only) | 75 lines | same skip line printed |

  `grep: (standard input): binary file matches` does not appear in any of the three.
- **`--check-brief` / `--check-branch`:** 13–14 ms and 10–12 ms per call.
- **Symlink probe:** after committing `lnk -> src` and `outside -> /etc`, `lnk/d000` and `outside/ssl` print `no tracked file …`, not `a directory`. `lnk` and `outside` print `reached through a symlink`. The commit was reverted afterwards (the repo is throwaway).
- **Tests:** `bats test/scripts/dev-cycle.bats` on `git archive bc98571` gave **30/30 ok, rc 0, 8.1 s** (`perf22/bats.log`). Pass 21 measured 7.65 s for 26 tests.

Legibility-target values used below: **maintainer** (someone editing the script) and **agent** (the model running the skill and reading the check's output).

## Data Flow and Hot Paths

The check modes (`scripts/dev-cycle.sh:230-240`) exit before any digest work. The skill calls them from repo text, once per batch of values: B `SKILL.md:64-75` and `:287`. This round (B) adds two gates per roadmap brief: `--check-brief` plus `--check-path` on its path, and `--check-branch` on its branch. Each mode takes many arguments (`SKILL.md:64` shows `'<path or glob>' …`), so N briefs cost at most three extra Bash calls. Each call takes about 10–15 ms of CPU and runs no git listing, apart from `--check-path`'s literal lookup and `check-ref-format`.

Every call is a **cold path**: one agent tool call. The standing escalation conditions are the agent's 120 s Bash timeout and the agent's context, which receives both stdout and stderr.

Cost model for `--check-path` per argument after this round, from reading `:112-146` and `:164-203` with every callee opened:
- **Plain path, tracked side** (`:177-178`): `git ls-files` (O(entries under the path)) then `env LC_ALL=C grep -zxF`. The bash loop now sees at most one record from this side. That is the `src` drop from 350 ms to 17 ms.
- **Plain path, ignored side** (`:182-186`): this side runs only when the fixed prefix is prefix-compatible with `docs/working/`, and it is filtered only by `^docs/working/`, not by `-xF`. A plain directory at or above `docs/working/` therefore still streams every ignored file under it through the loop at `:192-193` (finding 1).
- **No-match fallback** (`:200-202`): for a plain argument, `dirok` runs one `blocker` subshell, then one `realpath` per existing component. On R2 that costs about 3 ms (`src` 17 ms against `README.md` 14 ms). The walk stops at the first absent or non-plain component (`:128-131`).
- **Globs:** unchanged. At most 50 matches × about 4 ms, plus the listing, gives 0.2–0.3 s on R2.
- **stderr:** `pathform` no longer assigns `LC_ALL` (`:163-167`). The two greps get C through `env` (`:178`, `:184`), which is an external program, so bash's own locale is never re-set. The only stderr left is the interpreter's start-up warning pair. It is a constant 138 B per call, whatever the argument count or match count.

## Findings

#### 1. A plain directory argument at or above `docs/working/` still drains every ignored file under it through the bash loop, because the new `grep -zxF` filter covers only the tracked listing

**Severity:** Informational. Preconditions: repo text names `docs`, `docs/working` or a subdirectory of it as a plain path (not a glob), and the project keeps a large gitignored tree under `docs/working/`. That tree is the cycle's own scratch area, so it is normally tens of files. Confidence that the cost exists is High. Confidence that it matters in practice is Low.
**Location:** `scripts/dev-cycle.sh:182-186` (the ignored branch of `matches()`, consumed at `:192-193`) (A, bc98571)
**Evidence (verbatim):**
```bash
  if [[ "$fixed" == docs/working/* || docs/working/ == "$fixed"* ]]; then
    GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- "$1" \
      | { env LC_ALL=C grep -z '^docs/working/' || true; }  # C (set through env, which bash does not apply
      # to its own locale): a name that is not UTF-8 still passes, to be skipped below
  fi
```
(The excerpt is `:182-186`. `matches()` closes at `:187`. The tracked branch at `:176-179` applies `grep -zxF -- "$2"` for plain paths. The output feeds `check_path`'s loop at `:192-199`, where `:193` discards every record not equal to the argument. After the loop, `:200-202` prints the directory reason. I read `matches()` and `check_path()` whole.)
**Move:** Ask "what's the size of N?"
**Classification:** Micro (about 8 µs per discarded record in the byte-at-a-time `read -d ''`) / Cold path (one agent tool call)
**Confidence:** High (measured, with the cost split)
**Baseline:** R3, `perf22/times-r3.log` and `perf22/r3-components.log`, 2026-10-02. `--check-path docs/working` takes **478–481 ms**. Of that, the loop over 50,021 ignored records is **410–425 ms**. The same listing filtered with `grep -zxF` takes **26 ms**. d5d9121 took 501–504 ms, so this case is essentially unchanged by the round.
**Legibility-target:** maintainer

The round's comment at `:177` ("a plain path names one file: drop a directory's contents here, not one by one") holds for the tracked side only. The ignored side for the same plain argument still yields one record per ignored file under the directory. `:193` then discards them one at a time before the directory reason is printed. That scales at about 8 s per million ignored files under `docs/working/`, which is far from the 120 s cliff, and the output stays one line. This is the residual of pass-21 finding 2, moved from the tracked side to the ignored side.

**Recommendation:** Optional. For a plain argument, also pipe the ignored listing through `env LC_ALL=C grep -zxF -- "$2"` after the `^docs/working/` filter (keep both, so an ignored file named exactly `docs` is still dropped). Measured, that brings this case to about 26 ms of listing. Alternatively, leave it, and update the `:177` comment to say the filter is for tracked entries.

#### 2. (Carried, unchanged) A leading-wildcard glob still walks the whole ignored tree, and the walk can outlive the cap's `break`

**Severity:** Informational. Preconditions: as in pass-21 finding 3, a large ignored tree and an argument with an empty or `d…` fixed prefix.
**Location:** `scripts/dev-cycle.sh:174-187` (A, bc98571)
**Evidence (verbatim):**
```bash
matches() {  # $1 pathspec, $2 the argument; NUL-separated tracked files, then ignored ones under docs/working/
  local fixed="${2%%[*?]*}"
```
(The excerpt is `:174-175`. The rest of the function, `:176-187`, is quoted in finding 1 and at `:176-179`. Only the grep's environment changed in this round, and the walk is git's.)
**Move:** Find the work that moved to the wrong place
**Classification:** Macro (O(ignored files walked)) / Cold path
**Confidence:** High (re-measured)
**Baseline:** R2, `perf22/times-bc9.log`. `*/working/x` takes **94–95 ms** (pass 21: 92–94 ms) and `**/s0/f1*.md` takes **251–257 ms** (pass 21: 267 ms). On R3, with 50k more ignored files, `*/working/x` takes 115–137 ms.
**Legibility-target:** maintainer

No regression. Switching `grep` to `env LC_ALL=C grep` added no measurable cost. Recorded so the carried residual stays visible. No action is needed.

**Recommendation:** None required.

## Endorsements

- Pass-21 finding 1 is fixed. On an uninstalled `LC_ALL` (`en_US.UTF-8` or `tr_TR.UTF-8`), every check call wrote exactly the interpreter's two start-up lines (138 B). That held for one literal path, a 50-match capped glob, a 4-argument mixed call, and a 120-argument batch with 920 stdout lines. d5d9121 wrote 53 lines / 9,012 B for one capped glob. With an installed `LC_ALL=C.UTF-8`, stderr was 0 lines. Bats test 29 pins this with `≤ 2` stderr lines under `LC_ALL=xx_XX.UTF-8`. `[unverified — submitted as claim]` (my execution, not a fact-check verdict)
- Pass-21 finding 2 is fixed for tracked entries. On R2, a plain directory with 50,000 tracked files under it (`src`) went from **350 ms to 17 ms**, and its output is now the specific `a directory, not a file`. The `dirok` fallback adds about 3 ms and only runs once nothing matched. `[unverified — submitted as claim]` (my execution)
- Fact-check pass 21, Claim 8's divergence is closed. Under an installed UTF-8 locale (`C.UTF-8`), an ignored non-UTF-8 `docs/working/` name now reaches `check_path` and prints its `not an allowed path form` skip line, and `grep: … binary file matches` does not appear on stderr. Bats test 30 pins it. `[unverified — submitted as claim]` (my execution)
- Claim for the fact-check stage: `dirok` (`:143`) never calls `realpath` or `-d` on a path below a symlinked component, because `blocker` (`:126-136`) returns at the first non-plain part. Observed behaviour supports this: with `lnk -> src` committed, `lnk/d000` prints `no tracked file …` rather than `a directory`. The claim is categorical and needs an execution verdict, for example under `strace -f -e trace=stat,newfstatat,readlink`. `[unverified — submitted as claim]`
- The glob cap still bounds a glob's cost at 0.2–0.3 s per argument on R2. `**/*.md` takes 224–229 ms and 1,000 matches take 247–307 ms. The cap message's added "(narrow the glob)" costs nothing. `[unverified — submitted as claim]` (my execution)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A plain dir at or above `docs/working/` drains its ignored files through the bash loop; `-zxF` covers only the tracked side (R3: 478–481 ms, of which the loop is 410–425 ms) | Informational | `scripts/dev-cycle.sh:182-186` | High |
| 2 | (Carried) A leading-wildcard glob walks the whole ignored tree and can outlive the cap's `break` (94–95 ms / 251–257 ms, unchanged) | Informational | `scripts/dev-cycle.sh:174-187` | High |

## Overall Assessment

The round fixes both pass-21 performance findings that called for code changes.
- **stderr:** it is now a constant 138 B per call under an uninstalled locale. Previously it was one warning per argument and per match, about 9 KB for a capped glob. The bound holds for a 120-argument batch.
- **Plain directories:** a plain directory with a large tracked subtree now costs a listing plus one `grep`: 17 ms instead of 350 ms on 50k entries.

The new modes cost 10–15 ms per call, and B can batch them per mode. No path in this delta comes near the 120 s tool timeout at realistic sizes. The only new observation is Informational. The plain-path filter was applied to the tracked listing but not to the ignored one, so a plain `docs` or `docs/working` argument still pays about 8 µs per ignored file under `docs/working/`. That is 0.4 s for 50k files, and normally negligible because the directory holds the cycle's own scratch. It is fixable in place with one more `grep -zxF`, or by narrowing the `:177` comment. No further benchmarking is needed before merge.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."
- **Path:** this report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass22.md`, with the first line `Commit: bc98571 (A) / 6c8ae91 (B)`.
- **Structure:** it follows the performance-reviewer structure: header, the no-fact-check warning, data flow and hot paths, findings, evidence-tagged endorsements, summary table and overall assessment. Each finding carries Severity (with preconditions and confidence), Location, verbatim Evidence with truncation notes, Move, Classification, Confidence, Baseline and Legibility-target. Unverified endorsements are marked `[unverified — submitted as claim]`.
- **Coverage:** it covers the brief's assigned scope. `--check-path` was re-measured on a 50k-tracked / 200k-ignored repo, and on a variant with 50k ignored files under `docs/working/`, after the plain-path grep filter, the directory reason and the env-grep change. stderr was confirmed bounded under two uninstalled locales.
- **Not committed**, per instructions.
