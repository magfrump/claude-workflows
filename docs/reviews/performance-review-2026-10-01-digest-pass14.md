Commit: 096042b (A) / 374d559 (B)

# Performance Review: dev-cycle pass 14 (k=1 loop pass, partial scope: the pass-13 fix round)

**Scope:** A: `git diff 591f098..096042b -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff 44d06b7..374d559 -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`). Everything else is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass13.md` (Stage-1 context; it covers 591f098/44d06b7, the code before this round, so it holds no verdicts on the new lines), plus my own probes.

Scratch (not committed), all under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf14/`:
- `probe.sh` / `probe.log`: `timeout 300 bash probe.sh`, exit 0. It builds one throwaway repo under `mktemp -d` (removed on exit) with 40 decision records, a log, questions.md, questions-archive.md, one cycle record, roadmap and idea log, all plain. Then it runs `pinOld/dev-cycle.sh` (591f098) and `pinA/dev-cycle.sh` (096042b), both taken with `git show`, three times each, timing the runs. It also counts the `realpath -e` calls in a `bash -x` trace.
- `bats.log`: `timeout 300 bats test/scripts/dev-cycle.bats` in the A worktree (HEAD dd1548a; `git diff --stat 096042b HEAD -- scripts test` is empty). Result: 23 ok, 0 not ok.

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` is a CLI digest. It runs about once per development cycle (days to weeks apart) and only when someone starts it. Every path in it is **cold**. This round changes four things. (1) The two glob-directory gates now call `dirok`, which runs a `blocker` walk and then `-d`, where they used to call `plaindir`. (2) `inrepo` now runs the walk and then `-f`, dropping the second leaf `realpath`. (3) Section 2 gains one `printf | sort -u | while read` pipeline, which runs only when some decision input was skipped. (4) Section 3 now runs `skipped questions.md`, then `skipped questions-archive.md`, then `inrepo questions.md`, then questions.sh. The data sizes are small. A walk covers at most three path components (`docs/`, `docs/working/`, the leaf). `SKIPPED` grows by at most one entry per decision record plus a few fixed names. In B, the stale-brief rule runs once per In-flight brief per cycle. It now searches `questions-archive.md` (179,592 bytes in this repo, `wc -c`) and no longer reads it whole.

Measured: 591f098 makes 61 `realpath -e` calls and 096042b makes 65 in the probe repo, so the net change is **+4 forks**. Wall times were 209/255/214 ms (old) and 314/222/209 ms (new). The variation between runs is larger than the difference between versions.

## Findings

#### 1. Section 3 walks `docs/working/questions.md` twice when nothing blocks it

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:247-252` (at 096042b)
**Evidence:** `if skipped docs/working/questions.md; then` … `elif skipped "$QA"; then` … `elif inrepo docs/working/questions.md && [[ -f "$QS" ]]; then` (excerpt of the branch heads. The unit continues to line 272: the questions.sh run, its failure branch and the absent branch.)
**Move:** Hidden multiplication
**Classification:** Micro (a duplicate path walk: about 3 subshell + `realpath` forks) / Cold path (once per digest run)
**Confidence:** High (`probe.log`: `docs/working` resolves 5 times at 096042b against 2 at 591f098; `docs/working/questions.md` resolves twice)
**Baseline:** 591f098 makes 61 `realpath -e` calls and 096042b makes 65 per digest run, measured in the probe repo (`perf14/probe.log`, 2026-10-01). There is no latency baseline above run-to-run noise (209–314 ms).
**Legibility-target:** maintainer

When `skipped docs/working/questions.md` returns 1, `blocker` has already shown that no part of the path blocks it. `inrepo` then runs the same walk again only to reach `-f`. The archive check adds a third walk through `docs/` and `docs/working/`. Together with the `dirok` walks for the two glob directories, that makes the net +4 forks. At about 1 ms per fork on a once-per-cycle CLI, the cost is invisible. It is filed only because the pass-13 review counted forks at this exact site (its finding #1), and this round removed some forks there and added others.

**Recommendation:** No change is needed for a clean pass. If anyone touches the block again, the third branch could test `[[ -f docs/working/questions.md && -f "$QS" ]]`, because the walk has already run. Keep it as is if the uniform `inrepo` call reads better.

## Rules checked and found correct and complete (performance lens)

- **Section 2 skip lines.** The pipeline runs at most once per digest and only when `${#SKIPPED[@]} -gt $n_before_triggers`. Its input is bounded by the number of decision records plus `docs/decisions` or `log.md`. The `sort -u` handles the dedup, so the cost stays linear in the skipped count. No loop multiplies it.
- **`dirok`.** It replaces one `plaindir` (2 forks) with a walk (2–3 forks) plus `-d`. Its cost is constant per digest, does not depend on the number of records, and is cold.
- **`inrepo`.** Dropping the duplicate leaf `realpath` removes one fork at each fixed-name site that is not skipped. This fixes pass-13 performance finding #1 in part. Section 3's extra walks (finding 1 above) offset the savings.
- **B stale-brief rule.** Each answer applies once: only answers newer than the last `Kept:` date count, and `Kept:` becomes the answer's date. So no answer re-fires, and one question is filed per brief per 14-day lapse, at most. The search costs one scan of the archive per In-flight brief per cycle, which is O(archive bytes) for a tool like `rg` and stays small in tokens. This fixes pass-13 performance finding #2 (which asked for "search, not read").

## Endorsements

- At 096042b, `inrepo` makes no second `realpath` on the leaf: `docs/decisions/log.md` and `docs/roadmap.md` each resolve fewer times than at 591f098 (log.md 2→1, roadmap.md 4→2 in the trace). [read: scripts/dev-cycle.sh:117 at 096042b; `perf14/probe.log`]
- The section-2 skip listing is O(skipped inputs) and runs at most once per digest. [read: scripts/dev-cycle.sh:229-235 at 096042b]
- Under step 6 as written at 374d559, an agent following the stale-brief rule scans `questions-archive.md` by search rather than loading all 179,592 bytes into context, and never re-applies an answer it has already applied. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Section 3 walks questions.md twice when nothing blocks it (net +4 forks per run) | Informational | `scripts/dev-cycle.sh:247-252` | High |

## Overall Assessment

This round has no measurable performance effect. All of A runs on a cold, once-per-cycle CLI path: the extra walks add 4 `realpath` forks per run, and run-to-run variance hides them. The new section-2 output is linear in the number of skipped inputs and runs once. B fixes the one real cost concern from pass 13, reading an unbounded archive whole, by switching to search, and its answer rule terminates and applies each answer once. The single Informational finding does not block the clean pass. No profiling is needed.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass14.md`, with first line `Commit: 096042b (A) / 374d559 (B)`. It has the skill's header, Data Flow, Findings (with Severity, Location, Evidence, Move, Classification, Confidence, Baseline and Legibility-target), evidence-tagged Endorsements, a Summary Table and an Overall Assessment. It serves the user goal of merging both branches once a clean pass is reached: no performance finding blocks this pass.
