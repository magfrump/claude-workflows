Commit: 546b86e (A) / 46d3423 (B)

# Performance Review — dev-cycle pass 20 (pass-19 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 1b0c4ff..546b86e -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff 462e561..46d3423 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` in `/workspace/.claude/wt-devcycle`. The focus is the cost of `--check-path` per call and per batch on a large repo with many tracked and ignored files, plus the HEAD-tree fallback. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass19.md`. It gives verdicts on 1b0c4ff/462e561, so it has no execution verdict on this round's lines. Also `performance-review-2026-10-02-digest-pass19.md`, whose findings 1 and 2 this round answers.

> ⚠️ **No code fact-check report covers 546b86e / 46d3423.** Performance claims in this round's comments have not been independently verified by a fact-check stage. The numbers below are my own executions and are tagged as such. Runtime endorsements are submitted as claims.

**Measurements.** All mine, 2026-10-02, this sandbox (16 cores, git 2.39.5). Script from `git show 546b86e:scripts/dev-cycle.sh`. Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf20/` (`perf20/` below). Every process ran under `timeout`. The throwaway repo is under a `mktemp -d` dir in `perf20/`. Nothing was written to either worktree except this file.

- **R2** (`perf20/gen.py`, `perf20/mkrepo.sh`): 50,003 tracked files (`src/dNNN/sN/fN.md`, depth 4), 200,020 ignored files (`node_modules/` with 200k files, plus 20 ignored `docs/working/round-*.md`), and a tracked `docs/working/feature-ideas.md`.
- `--check-path` wall time per call, two runs each (`perf20/check-path-times.log` and the session log):

| Arg(s) | Wall (run 1 / run 2) | ok / skip |
|---|---|---|
| `README.md` | 17 / 17 ms | 1 / 0 |
| `src/d000/s0/f0.md` | 14 / 14 ms | 1 / 0 |
| `docs/working/feature-ideas*.md` (the repo's own row) | 14 / 14 ms | 1 / 0 |
| `docs/working/*.md` | 91 / 94 ms | 21 / 0 |
| `*` | 93 / 99 ms | 1 / 1 |
| `node_modules/*` | 68 / 64 ms | 0 / 1 |
| `src` (plain directory) | 346 / 345 ms | 0 / 1 |
| `.` (plain) | 1,939 / 1,870 ms | 0 / 1 |
| `src/d000/*/*.md` (1,000 matches) | 5,358 / 4,763 ms | 1,000 / 0 |
| `src/d00*/*/*.md` (10,000 matches) | 45,625 ms | 10,000 / 0 |
| `**/*.md` (50,022 matches: 50,002 tracked + 20 ignored under docs/working/) | **231,060 ms** (one run, `perf20/starstar.log`) | 50,022 / 0 |
| 20 literal tracked paths in one call | 181 ms | 20 / 0 |

- Raw git cost of the two `ls-files` calls in `matches()` (`perf20/raw-lsfiles.log`). Tracked listing: 5–13 ms for every spec, including `**` (50k paths). Ignored listing: `:(glob)**` and `:(literal).` 173–178 ms (200,020 paths); `:(glob)*` 86 ms (0 paths, but the whole tree is walked); `:(glob)**/*.md` 105 ms; `:(literal)README.md` and `docs/working/*.md` 4–6 ms.
- The bash `while read -d ''` filter in `matches()` alone, over all 200,020 ignored paths: **1,481 ms** (output: 20 paths).
- HEAD-tree fallback (`perf20/headtree-cost.log`, 100 calls each, 50k index): `git cat-file -e HEAD:<path>` **0.94 ms/call** (present) / **1.43 ms/call** (absent), against `git ls-files --error-unmatch` 4.17 / 3.69 ms/call.
- Staged-never-committed probe (`perf20/staged-probe.log`): a committed record plus a `git add`ed record with no commit. The digest prints `002-staged.md (... never, uncommitted)` after **1 `cat-file` call and 0 `git log -1` calls** (GIT_TRACE2_EVENT).
- `bats test/scripts/dev-cycle.bats` on `git archive 546b86e`: **26/26 ok, rc 0, 7.6 s** (`perf20/bats.log`; 6.9 s with 24 tests at 1b0c4ff in pass 19).
- This repo for scale: 2,653 tracked files (1,178 `*.md`), 48 ignored, 0 ignored under `docs/working/`.

Legibility-target values: **maintainer** (someone editing the script), **agent** (the model running the skill).

## Data Flow and Hot Paths

`--check-path` / `--check-write` run as a separate mode of `dev-cycle.sh` (`:182-187`, before any digest work). The skill (B `:61-73`) calls them from steps 2–6 and from step 4's per-merge subagents, once per batch of paths taken from repo text. A call is a **cold path**: a few calls per cycle, each one agent Bash tool call. The standing escalation case from earlier passes still applies. The agent's Bash tool has a 120 s default timeout, and a call that crosses it loses the output for **every** path in that batch, so a cold call that can cross 120 s is graded with the hot-path gate's exception.

Cost model per call, from reading `:46-75`, `:97-133` and `:148-187` (every callee opened):
- **Fixed:** the scrub wrapper (two `bash` and two `perl` processes) plus `git rev-parse`. About 14 ms in total.
- **Per argument:** `pathform` (pure bash), then `matches()` = `git ls-files` (O(index)) + `git ls-files --others --ignored --exclude-standard` (a worktree walk bounded by the pathspec's fixed prefix) piped through a bash `read -d ''` loop over **every ignored match, wherever it is**. Only after that loop does it keep those under `docs/working/`.
- **Per match:** `check_path`'s loop runs `pathform "$m"` and `inrepo "$m"`. `inrepo` = `$(blocker …)`, a subshell, which inside runs one `$(realpath -e …)` per existing parent component (`plaindir`) and one for the file (`rawfile`). For a depth-d path that is d+1 forks plus the subshell. On R2 (d = 4) that is about **4.5 ms per match**, and it dominates every call with more than a few matches.

`--check-write` runs `pathform` + `blocker` per argument, with no git and no listing. Its cost is O(depth) forks per path. Negligible.

HEAD-tree fallback (`:290-296`): for a record missing from the one-walk date map, one `git cat-file -e HEAD:<path>` (a tree lookup). Only on success does it run `git log -1` (a history walk). The digest runs once per cycle, a cold path.

## Findings

#### 1. A broad glob costs ~4.5 ms per match with no cap, so `**`-style args cross the 120 s tool timeout at ~26k matches and print one line per match

**Severity:** Medium (Macro × Cold, escalated by the hot-path gate's exception). Preconditions: a repo with tens of thousands of tracked files, and a broad glob reaching `--check-path`. Under the skill, any glob that repo text names reaches it: B `:61-64` routes "a settings row or glob … any file a commit message, decision-log row, plan or question names" through the check. Repo text is untrusted here, so a commit message or plan that names `**` or `src/**` is enough. On this repo (1,178 `*.md`), `**/*.md` would cost about 5 s, which is harmless. The cliff needs a large repo.
**Location:** `scripts/dev-cycle.sh:163-175` (with `inrepo`/`blocker` at `:104-129`) (A, 546b86e)
**Evidence (verbatim):**
```bash
  while IFS= read -r -d '' m; do
    [[ "$a" == *[*?]* || "$m" == "$a" ]] || continue  # a plain path names one file, not a directory
    n=$((n + 1))
    if ! pathform "$m"; then echo "skip ${m//$'\n'/ }: not an allowed path form"
    elif ! inrepo "$m"; then echo "skip $m: reached through a symlink, or not a regular file"
    else echo "ok $m"; fi
  done < <(matches "$spec")
```
(The excerpt is `:167-173`. The function `check_path` runs `:163-175`, and the remaining line `:174` prints the no-match skip. I read all of it, plus `inrepo` `:129`, `blocker` `:115-125`, `rawfile`/`plaindir` `:104-107`.)
**Move:** Count the hidden multiplications; Ask "what's the size of N?"
**Classification:** Macro (O(matches × depth) forks, unbounded) / Cold path (one agent tool call per batch), escalated for the 120 s cliff
**Confidence:** High for the cost (measured). Medium for how often a broad glob arrives in practice.
**Baseline:** R2, `perf20/` session log, 2026-10-02: **1,000 matches 4.8–5.4 s; 10,000 matches 45.6 s; `**/*.md` (50,022 matches) 231.1 s**. Git's own listing of all 50k tracked matches takes 13 ms.
**Legibility-target:** maintainer

The git side of a glob is cheap: listing 50k tracked matches takes 13 ms. Nearly all the time goes to the per-match `inrepo`. That is 1 subshell + (depth+1) `realpath` forks for each match. A batch whose output never arrives costs the whole batch, because the skill opens a path only on `ok`. That fails safe, but the step loses all its inputs. The output is also unbounded: 50k `ok` lines (~1.2 MB) go into the agent's tool output, where they are truncated or cost context. `ok` lines for other arguments in the same batch can then be cut too. That last point is speculative, since the tool's truncation rule was not measured.

**Recommendation:** Check matches in one pass instead of forking per match. For example, collect the matches into an array, run one `realpath -e -z -- "${matches[@]}"`, and compare each result to `$ROOT_REAL/$m` plus `[[ -f ]]`. Equality already rules out any symlink component, which is what `rawfile` relies on. That makes the cost O(1) processes per argument. Separately, cap the matches per argument (for example 200, then `skip <arg>: matches more than 200 files`) so the agent's output stays bounded. Either change alone removes the 120 s cliff at realistic sizes.

#### 2. The ignored-file listing is filtered to `docs/working/` by a byte-at-a-time bash loop after git lists every ignored match in the tree

**Severity:** Low (Macro × Cold). Preconditions: a large ignored tree (`node_modules`, `.venv`, build output) and an argument whose fixed prefix does not confine the walk (`*`, `**…`, `.`, or any glob starting with a wildcard).
**Location:** `scripts/dev-cycle.sh:158-162` (A, 546b86e)
**Evidence (verbatim):**
```bash
matches() {  # $1 pathspec; NUL-separated tracked files, then ignored ones under docs/working/
  GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1"
  GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- "$1" \
    | while IFS= read -r -d '' m; do [[ "$m" == docs/working/* ]] && printf '%s\0' "$m"; done
}
```
(This is the whole function. Its output feeds `check_path`'s loop at `:167-173`.)
**Move:** Find the work that moved to the wrong place; Count the hidden multiplications
**Classification:** Macro (O(ignored files in the walked tree), on every argument) / Cold path
**Confidence:** High (measured)
**Baseline:** R2, 200,020 ignored files: git lists them in 173 ms (`perf20/raw-lsfiles.log`). The bash filter over them takes **1,481 ms** and keeps 20. `--check-path .` takes 1.9 s in total.
**Legibility-target:** maintainer

`read -d ''` from a pipe reads one byte per syscall. Every ignored match in the walked part of the tree therefore costs about 7 µs before it is thrown away. The filter runs on every argument, including arguments that cannot match under `docs/working/` (for example `src/**`, or `*`, which walks all of `node_modules/` for 86 ms and lists nothing). The cost is per argument, so a batch of k broad args pays it k times. It stays well under the 120 s cliff at realistic sizes (about 10 s per million ignored files), so this is Low.

**Recommendation:** Skip the ignored query when the argument's fixed prefix (up to the first `*`/`?`) is not compatible with `docs/working/`, that is, when neither one is a prefix of the other. Otherwise replace the bash loop with one `grep -z '^docs/working/'`. Both changes keep the same semantics.

#### 3. A plain path that names a directory (or `.`) lists the whole subtree before it is skipped

**Severity:** Informational (Micro × Cold)
**Location:** `scripts/dev-cycle.sh:166-168` (A, 546b86e)
**Evidence (verbatim):** `if [[ "$a" == *[*?]* ]]; then spec=":(glob)$a"; else spec=":(literal)$a"; fi` … `[[ "$a" == *[*?]* || "$m" == "$a" ]] || continue  # a plain path names one file, not a directory` (from `:166` and `:168`. The function continues to `:175`, read.)
**Move:** Ask "what's the size of N?"
**Classification:** Micro (one wasted listing per such argument) / Cold path
**Confidence:** High (measured)
**Baseline:** R2: `--check-path src` 345 ms, `--check-path .` 1.9 s, against 14–17 ms for a literal file. Both end in `skip …: no tracked file … matches`.
**Legibility-target:** maintainer

`.` passes `pathform`, because only `..` is banned. `:(literal).` then matches every tracked and every ignored file, and each one is read through the bash loop only to be discarded by the `m == a` test. The answer is correct. Only the cost is wasted.

**Recommendation:** Optional. For a plain argument, compare git's output with `grep -zxF -- "$a"` (one process) instead of the bash loop, or reject `.` components in `pathform`, since they never match anyway (`./x` and `x/./y` always end in "no tracked file").

## Endorsements

- The HEAD-tree fallback closes pass-19 finding 1. A record that is staged but never committed now costs one `cat-file` (≈1–1.4 ms on a 50k index, cheaper than the old `ls-files --error-unmatch` at ≈3.7–4.2 ms) and no history walk. Measured: 0 `git log -1` calls for a staged-only record (`perf20/staged-probe.log`). `[unverified — submitted as claim]` (my execution, not a fact-check verdict)
- The check modes exit before any digest work, so a `--check-path` call never pays the history walk or the default-branch lookup. `[read: scripts/dev-cycle.sh:182-188]`
- Batching works and is cheap: 20 literal paths in one call take 181 ms against ~14 ms for one, so each extra literal argument costs ~8 ms. B's `'<path or glob>' …` wording permits batches, which answers pass-19 finding 2 (one agent round trip per path). `[unverified — submitted as claim]` (my execution)
- The repo's own idea-source row `docs/working/feature-ideas*.md` costs 14 ms, because its fixed prefix confines both `ls-files` walks. `[unverified — submitted as claim]` (my execution)
- `--check-write` does no git call and no listing. Its cost is `pathform` plus one `blocker` walk (O(depth) forks) per path. `[read: scripts/dev-cycle.sh:176-181, :115-125, :104-107]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ~4.5 ms per glob match (per-match subshell + realpath forks), no cap: 10k matches 45.6 s, ~26k cross the 120 s tool timeout; unbounded `ok` output | Medium | `scripts/dev-cycle.sh:163-175` | High (cost) / Medium (frequency) |
| 2 | Ignored listing filtered to docs/working/ by a byte-wise bash loop over every ignored match, on every argument (1.5 s per 200k ignored files) | Low | `scripts/dev-cycle.sh:158-162` | High |
| 3 | A plain directory or `.` lists its whole subtree before the skip (`.` 1.9 s on R2) | Informational | `scripts/dev-cycle.sh:166-168` | High |

## Overall Assessment

For what the cycle actually passes (literal paths from commit messages and plans, the one idea-source row, brief paths), `--check-path` is cheap: 14–17 ms per call and about 8 ms per extra literal in a batch. The HEAD-tree fallback is strictly cheaper than the index lookup it replaces and removes pass-19's staged-record walk. The one real scaling hazard is finding 1. The per-match cost comes from forking `realpath` per path component in a bash loop, and nothing caps the match count, so a broad glob from untrusted repo text on a large repo can cross the agent's 120 s Bash timeout and lose the whole batch. It is fixable in place: one batched `realpath` per argument, and/or a match cap. Finding 2 is a cheap win on repos with big ignored trees. No further benchmarking is needed to act. Re-measure finding 1 on R2 after the fix (baseline 45.6 s for 10k matches).

**Outside this lane (for the fact-check / API stages, not graded here):** `pathform` allows `.` components, so `./docs/x.md` passes the form check and then always skips as "no tracked file". This is harmless but surprising. The help range `sed -n '2,28p'` (`:91`) covers the whole header, which ends at `:27`. That is correct.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass20.md` with the first line `Commit: 546b86e (A) / 46d3423 (B)`. It follows the performance-reviewer structure: header, the no-fact-check warning, data flow and hot paths, and findings with Severity, Location, verbatim Evidence, Confidence, Baseline and Legibility-target. Endorsements carry evidence tags, unverified ones marked `[unverified — submitted as claim]`, followed by a summary table and an overall assessment. It covers the brief's assigned scope: the cost of `--check-path` per call and per batch on a large repo with many tracked and ignored files, and the HEAD-tree fallback. It is not committed, per instructions.
