Commit: 366efd7 (A) / b73069e (B)

# Performance Review: dev-cycle pass 28 (pass-27 fix round, k=1 delta)

**Scope:** Partial. A: `git diff b00c057..366efd7 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff 7f3e392..b73069e -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle`, merged as d535260. The brief asks for three measurements: the first-parent `-G` lookup with `--diff-merges` on long merge-heavy histories, the per-line `FENCE_AWK` functions on large briefs and archives, and `--check-answer` after the shared fence reader. Everything else is context only.
**Date:** 2026-10-02
**Based on:** The Stage-1 context is `code-fact-check-report-digest-pass27.md`, plus pass 27's numbers and generators in `scratchpad/perf27/`. This round's `code-fact-check-report-digest-pass28.md` (on 366efd7 / b73069e) was already in the worktree when I finished. Two endorsements below cite its verdicts, and none contradicts it.

**Measurements.** I took every measurement myself on 2026-10-02 in this sandbox (git 2.39.5, mawk 1.3.4; `awk` and `nawk` both resolve to mawk, and gawk and busybox are not installed). "new" is `git show 366efd7:scripts/dev-cycle.sh` and "old" is `b00c057:…`. Both ran in the same loop. Scratch is in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf28/` (`perf28/` below). Each probe is one `set -eu` script that creates its own `mktemp -d -p perf28` directory in that same script and checks `case "$PWD"` before any `git init`, commit, write or `rm`. Every process ran under `timeout`. None is still running (`pgrep` is empty). Nothing was written to either worktree except this file. `/workspace` is still on `main` with an unchanged status. wt-devcycle's `git status --short` is empty. In wt-digest it shows only the three sibling pass-28 reports, which other critics wrote.

- **Q1, history** (`perf28/q1-history.sh`, `q1.log`, generator `perf28/gen28.py`). Four history shapes:
  - 100k linear commits.
  - 10k and 50k first-parent `--no-ff` merges of 1-commit side branches (20k and 100k commits).
  - 20k merges of 5-commit side branches (120k commits).

  In the merge shapes, brief edits are made on the side branch, so only a merge's first-parent diff carries them. There are four briefs:
  - **old**: Status set at commit 1, never edited.
  - **edited**: Status set at commit 1, `Kept:` edited every 10th step.
  - **sidestatus**: added on a side branch halfway, then edited every 10th step.
  - **late**: Status changed at step N−1.

  Each shape ran without and with a `--changed-paths` commit-graph, two runs each. Raw `git log` variants were also timed: with and without `-s`, without `--diff-merges`, and b00c057's form.
- **Q2, fence cost on briefs** (`perf28/q2-fence.sh`, `q2.log` contended, `q2b.log` rerun alone; the numbers below are from `q2b.log`). Seven briefs of 16–64 MiB: plain text with Status last; 64 MiB of short fence pairs; a ```` ``` ```` fence left open over `   ~~~…` lines; two 16 MiB backtick-run lines; a 16 MiB info string; a 16 MiB run whose info string holds a backtick; 4M lines of `   ~~`. Three runs each. The same script reruns pass 27's fence probes.
- **Q3, `--check-answer`** (`perf28/q3-answer.sh`, `q3.log`). This is pass 27's P3 adapted to new/old. It covers readings over every real ID, the header shapes, cost on the 1×/10×/100× archives and a 17.5 MB all-fenced archive.
- **Q4, semantics and a dense entry** (`perf28/q4-semantics.sh`, `q4.log`). It checks which commit is printed for a `--no-ff` merge, a squash, a move into `closed/` and a conflict-resolving merge. It counts the lines `$c` gets with and without `-s`. It times `--check-answer` on a 16 MiB target entry of fence pairs.
- **Q5–Q7, scaling** (`q5-scaling.sh`/`q5.log`, `q6-run.sh`/`q6.log`, `q7.log`). These run the check_brief awk program alone (`:256-268` + `:288-292` cut verbatim from 366efd7) at 4/16/64 MiB. They also time `run()`, `match()`, `lead()` and plain `length($0)` on a single long line, 1–64 MiB.
- **Q8, gates** (on `git archive 366efd7`). `bats test/scripts/dev-cycle.bats` gives **46/46 ok, rc 0, 12 s**. `python3 scripts/hermeticity-lint --root .` gives **rc 0**. `shellcheck scripts/dev-cycle.sh` is clean (`perf28/q8-bats.out`, `q8-lint.out`).

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle. N is about 3 briefs (the slot cap), plus any In flight lines being resolved through `closed/`. Severity can still rise for three reasons: the agent's 120 s Bash timeout, a non-zero exit (which stops the step for the whole batch), or a cost that grows without bound.

- **`--check-brief`** (`scripts/dev-cycle.sh:276-301`).
  - The awk at `:287-292` now runs `opens($0)` on every line before the first unfenced `Status:` line, and `closes($0)` on every fenced line. Both come from `FENCE_AWK` (`:255-269`). Each call copies the line once in `lead()` and counts the run in `run()`, so the cost is linear in line length. After `seen`, lines are drained by `seen { next }` as before.
  - The skip return at `:293` now comes **before** the commit lookup, so a brief with no valid Status line runs no `git log` (pass 27 Informational 2 is closed).
  - The lookup at `:298` is `git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: '`. It walks first-parent history only and diffs each first-parent commit that touches the path against its first parent, until one adds or removes a matching line. The fallback is at `:299`.
- **`--check-answer`** (`:365-433`). The program is `"$FENCE_AWK$ANSWER_AWK"` (`:425`). On every line of both files, the work outside the target entry is still `heading($0)` plus the `/^(#|##|###) /` test (`:386`, `:392-393`). The fence functions run only inside the target entry: `opens()` at `:394`, and `closes()` plus the `### Q-` regex at `:387-391`.
- **B** adds no unbounded loop. A stale In flight line costs one more `--check-path` on `briefs/closed/<same name>` and one `--check-brief` there. Check 1 then moves the line to Done or Ideas. A brief already under `closed/` "stays" (`SKILL.md:277-278`), so nothing is moved twice and the line leaves In flight in that same cycle. In flight is now bounded by the slot rule (`:83-86`, `:266-267`). The final message gains the `unrecognized` IDs, at most one per brief per cycle.

**Pass 27's fence probes, rerun** (Q2). Every probe now gives the CommonMark reading:

| Probe | old (b00c057) | new (366efd7) |
|---|---|---|
| api N1: ```` ```` ```` / ```` ``` ```` / `Q-001: [1]` / ```` ``` ```` / ```` ```` ```` / `Q-001: [2]` | `keep Q-001` | `drop Q-001` |
| security Q-022 (four-backtick around `**Answer:** [2]`) | `drop` | `keep` |
| security Q-023 (info-string line inside a fence) | `unrecognized` | `keep` |
| two-space-indented fence around `**Answer:** [2]` | `drop` | `keep` |
| header `**Status:** ANSWERED · **Opened:** …` | `open` | `done` |
| `### Q-027` heading inside Q-026's fence | `unrecognized` / dup skip | same |
| briefs N2, `four`, `info`, `indent` (fenced `Status: done`, then `Status: open`) | `done` ×4 | `open` ×4 |
| brief with 4-space-indented ```` ``` ```` (not a fence) | `open` | `open` |
| brief whose 16 MiB backtick run has a `` ` `` in its info string (not a fence) | skip | `ok open` |

## Findings

#### 1. `FENCE_AWK`'s per-line function calls cost 2.5–3× the old regex on fence-dense input (linear, no cliff)

**Severity:** Informational. Precondition: a brief, or a target questions entry, of many MiB made almost entirely of fence-shaped lines or indented `~`/`` ` `` lines. Real briefs are KiB, and the largest real questions file is 186 KB. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:256-268` (A, 366efd7). Call sites: `:290-291` (check_brief) and `:387-394` (ANSWER_AWK, target entry only).
**Evidence (verbatim):**
```awk
function lead(l,   i) { i = 1; while (i <= 3 && substr(l, i, 1) == " ") i++; return substr(l, i) }
function run(l, ch,   n) { n = 0; while (substr(l, n + 1, 1) == ch) n++; return n }
function opens(l,   s, ch, n) {
  s = lead(l); ch = substr(s, 1, 1)
  if (ch != "`" && ch != "~") return 0
  n = run(s, ch); if (n < 3) return 0
  if (ch == "`" && index(substr(s, n + 1), "`")) return 0
  fch = ch; flen = n; return 1
}
function closes(l,   s, n) {
  s = lead(l); n = run(s, fch)
  return n >= flen && substr(s, n + 1) ~ /^[ \t]*$/
}
```
(This is `:256-268`, the whole body of the `FENCE_AWK` string. `:269` closes the string. `fch`/`flen` are set only in `opens()`, read only in `closes()`, and first used at `:290` and `:389`.)
**Move:** Count the hidden multiplications (two or three user-function calls and a line copy per line, where there used to be one anchored regex)
**Classification:** Micro (constant factor per line) / Cold path (≤ about 3 briefs and a few IDs per cycle)
**Confidence:** High
**Baseline:** Measured 2026-10-02, old → new, `--check-brief` end to end (Q2, `q2b.log`):
- 64 MiB of fence pairs: 3.27–3.52 → 8.42–9.75 s.
- 24 MiB of `   ~~` lines: 0.73–0.74 → 2.25–3.62 s.
- 64 MiB plain text with Status last: 0.36–0.38 → 0.54–0.55 s.
- 16 MiB info string: 0.71–1.15 → 0.90–1.12 s.

`--check-answer` on a 16 MiB fence-pair target entry: 0.76 → 1.97–2.03 s. The 16 MiB plain entry in the same file costs 0.58–0.60 → 0.64–0.66 s, and a missing ID costs 0.54–0.55 → 0.58–0.59 s (Q4).
**Legibility-target:** maintainer

The cost is linear. The awk alone on fence pairs takes 413 / 1,632 / 6,511 ms at 4 / 16 / 64 MiB (Q5). At real sizes the change does not register: `--check-answer` on 102 real IDs takes 1.03 → 1.05 s, 100 IDs on the 17 MB archive 3.38 → 3.49 s, and the 17.5 MB all-fenced archive 87–92 → 94–109 ms (Q3). Outside the target entry no fence function runs, which is why the archive cost barely moves. A brief would need to be roughly 1 GiB of fence lines before it neared the 120 s timeout. I'm recording this to write the cost model down. It is not a fix request.

**Recommendation:** None at current scale. If it ever matters, a cheap pre-test in front of the function calls (`/^ {0,3}[`~]/` before `opens($0)`) would skip the calls on ordinary lines. Do not trade it for correctness.

#### 2. mawk's cost for one very long line is superlinear (pre-existing), and the fence reader roughly doubles it on such lines

**Severity:** Informational. Preconditions: a landed brief, or a questions entry, containing a single line of tens of MiB. No real file comes close. The superlinear part comes from mawk itself and predates this diff. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:287-292` (A, 366efd7; the awk reading the blob)
**Evidence (verbatim):**
```bash
  st="$(git cat-file blob "$MAIN_SHA:$a" | env LC_ALL=C awk "$FENCE_AWK"'
    { sub(/\r$/, "") }
    seen { next }
    infence { if (closes($0)) infence = 0; next }
    opens($0) { infence = 1; next }
    /^Status:/ { seen = 1; if ($0 ~ /^Status: (open|done|dropped)$/) print }')"
```
(This is `:287-292`. `st` is first used at `:293`, which skips when it is empty, and then printed at `:300`. The function ends at `:301`.)
**Move:** Ask "what's the size of N?" (N here is the length of one line, not the line count)
**Classification:** Macro (superlinear in line length) / Cold path, pathological input
**Confidence:** High
**Baseline:** Measured 2026-10-02 (Q7). mawk `{ print length($0) }` on one backtick line takes 189 ms / 2,067 ms / 4,465 ms / 29,559 ms at 8 / 16 / 32 / 64 MiB, and the old regex `$0 ~ /^(```|~~~)/` behaves the same (176 / 771 / 3,763 / 26,694 ms). With the new program, a 4 / 16 / 64 MiB run line followed by another of the same length takes 305 / 2,010 / 38,510 ms (Q5). End to end, the 32 MiB two-line brief takes 0.82–1.00 s old and 1.92–2.08 s new (Q2).
**Legibility-target:** maintainer

The growth is in mawk's handling of a huge record. A bare `length($0)` shows it, so neither version of the script causes it. The new reader adds about one more pass per long line (`lead()` copies the line, and `run()` counts it). Two 64 MiB single lines in one brief would come near the agent's 120 s timeout. That requires a brief written to be pathological, so it is not a realistic risk.

**Recommendation:** None needed. If briefs ever come from untrusted bulk text, a size guard before the awk (`git cat-file -s`, skip above some MiB) would bound it for both the old and new readers.

## Cross-lane observations (not graded here)

- **Which commit the lookup prints** (Q1, Q4). The output now names the main-branch merge (or squash) commit rather than the side-branch commit. On merge histories, new prints `merge 5000` / `merge 9999` where old printed `side 5000.0` / `side 9999.0`. A squash prints the squash commit, as before. A conflicting Status line resolved inside a merge is now attributed to that merge (`m: merge fk (resolved to done)`; b00c057 printed `fk: set k done`), which closes pass 27's conflict case. For a brief moved into `closed/` after its status was set, the **move** commit is printed (`m: move c to closed`), not the commit that set the status. The api (finding 3) and security (F5) reviews have already filed this. Corroborating: `[unverified — submitted as claim]` (my execution, Q4).
- On git 2.39.5, `--first-parent` without `--diff-merges=first-parent` picks the same commit in every Q1 case, so the explicit flag is redundant here but harmless. `--diff-merges` needs git ≥ 2.31. Security already lists the older-git case as not run. `[unverified — submitted as claim]` (my execution, Q1)

## Endorsements

- The first-parent `-G` lookup costs the same as b00c057's all-history `-G`, or less, on every shape measured. Raw lookup times, old → new:

  | History (commits) | Brief | No commit-graph | With commit-graph |
  |---|---|---|---|
  | 100k linear | edited | 650 → 690 ms | 296 → 269 ms |
  | 100k (50k merges) | edited | 381 → 353 ms | 181 → 158 ms |
  | 100k (50k merges) | sidestatus | 183 → 176 ms | 89 → 70 ms |
  | 120k (20k merges of 5 commits) | edited | 202 → 159 ms | 84 → 71 ms |

  End to end, `--check-brief` on the 120k-commit history takes 208–212 → 162–166 ms (edited, no commit-graph). The walk visits only first-parent commits, and the per-merge first-parent diff is limited to the path. The cost is still linear in the brief's edits since its status was set (pass 27 Informational 1, unchanged), and it stays under 1 s at 100k commits. `[unverified — submitted as claim]` (my execution, Q1)
- Pass 27 Informational 2 is fixed: the skip at `:293` returns before either `git log` runs, so a brief with no valid Status line costs one `cat-file` and one awk. `[read: scripts/dev-cycle.sh:287-300]`
- `-s` is what keeps `$c` a single hash. Without it, `--diff-merges=first-parent` prints the patch after the hash: 10 lines against 1 (Q4). `-s` does not disable the `-G` filter. `[fact-check: claim 8 — Mostly accurate (the -s sub-point executed and verified)]`
- `--check-answer` readings are unchanged and its cost is within noise. All 102 IDs in wt-devcycle's files and all 99 in `/workspace`'s read identically (`(no difference)`, 0 stderr), and every header shape is unchanged (Q3). Costs are in finding 1's note. `[fact-check: claim 24 — Verified]`
- B adds attention cost only within existing bounds. A stale line resolves in one cycle through one `--check-path` and one `--check-brief` on `closed/`. A brief already under `closed/` stays put, so nothing is moved twice. In flight is bounded by the slots. The final message gains at most one `unrecognized` ID per brief per cycle. `[read: skills/dev-cycle/SKILL.md:83-92,266-278,289-293,364-366]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `FENCE_AWK` per-line calls cost 2.5–3× the old regex on fence-dense input (64 MiB: 3.3 → 8.4 s; 16 MiB answer entry: 0.76 → 2.0 s). Linear, and nothing at real sizes | Informational | `scripts/dev-cycle.sh:256-268` (A) | High |
| 2 | mawk is superlinear on a single huge line (pre-existing: `length($0)` takes 30 s at 64 MiB). The new reader roughly doubles the cost for such lines | Informational | `scripts/dev-cycle.sh:287-292` (A) | High |

## Overall Assessment

The round's fixes cost nothing that matters. The first-parent `-G` lookup is as fast as b00c057's form or faster on long merge-heavy histories (up to 120k commits, 20k merges), because it walks only the first-parent chain. The skip path no longer runs any lookup. The shared CommonMark fence reader gives the correct reading on every pass-27 probe. Its user-function calls cost 2.5–3× per fence-shaped line, but the growth is linear, it runs only inside the target entry for answers, and it does not register at real sizes: 102 real IDs take 1.03 → 1.05 s, and the 17 MB archive is unchanged within noise. The only superlinear behavior is mawk's own handling of one multi-MiB line, which predates the diff and needs a pathological brief. B adds no unbounded loop. Both findings are Informational and cold-path, and neither needs a fix or more benchmarking. Nothing in the performance lane blocks the clean pass.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."
- **Path:** saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass28.md`, first line `Commit: 366efd7 (A) / b73069e (B)`. Not committed.
- **Structure:** follows the performance-reviewer layout: header, data flow and hot paths (including the rerun probe table), findings, cross-lane observations, evidence-tagged endorsements (≤5), summary table and overall assessment. Each finding carries Severity (with preconditions and confidence), Location, verbatim Evidence with a note naming the rest of its unit and the flow of its value, Move, Classification, Confidence, Baseline and Legibility-target. Endorsements I verified only by my own runs are tagged `[unverified — submitted as claim]`.
