Commit: 71e618d (A) / 8286c2b (B)

# Performance Review — dev-cycle loop pass 12 (pass-11 fix round)

**Scope:** A: `git diff c034a75..71e618d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (e08d526, 5dd5377, 71e618d), worktree `/workspace/.claude/wt-digest`. B: `git diff a218ad8..8286c2b -- skills/dev-cycle/SKILL.md docs/working/questions.md`, worktree `/workspace/.claude/wt-devcycle`. Partial scope: the rest of both branches is context only.
**Date:** 2026-10-01
**Based on:** `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass11.md` (loop pass 11's k=1 fact-check, the Stage-1 context the brief names). That report covers the code as it was before this round, so it gives no verdict on the new `skipped()` walk. Every runtime statement below comes from my own probe, which I describe where I use it.

Both worktree HEADs (be7cc4e, 99c03fc) have no diff from 71e618d / 8286c2b on the files in scope (`git diff --stat` empty), so the review applies to the stated commits.

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` is a CLI digest. A person or agent runs it about once per dev cycle (step 0 of the skill), plus at most one rerun with `--since` when step 0 calls for it. It is a **cold path**: nothing serves requests, nothing runs in a loop at scale, and its output is read by an agent. The changes in this round:

- `skipped()` (`scripts/dev-cycle.sh:104-113`) now walks each parent of the path top down. For every parent it does `[[ -e || -L ]]` and then `plaindir`, which forks `realpath -e` once. After the walk it runs the old existence and `inrepo` check (one more `realpath` fork). Call sites: the cycles glob (`:143-147`, only for items that fail `inrepo`), the decisions glob (`:197`, only for items that fail `inrepo`), and the fixed names `docs/decisions/log.md` (`:218`), `docs/working/questions.md` (`:246`), `docs/roadmap.md` (`:268`, `:318`) and `$LOG` (`:337`), each reached only when `inrepo` already failed.
- The cycles loop (`:140-153`) now tracks `skipped_record`, a string compare per skipped item. `n_before_triggers` (`:193`) moved above the decisions check. That is a reorder with no cost.
- Section 8's wording changed. Text only.
- B is skill prose. The new stale-brief rule asks each cycle to check "no commit beyond the default branch" for each In-flight brief. The slot cap bounds that to a few `git rev-list` calls (3 items in flight, per Q-103's own text). The skipped-record clause can cause one extra digest run.

Data sizes: N is the number of decision records and cycle records. That is tens, growing by about one per cycle. Skipped items are symlinks or non-regular files, which a healthy repo has none of. In this repo today, N_skipped = 0.

**Probe** (under `timeout`, throwaway repos made with `mktemp -d` under `scratchpad/perf12/`, removed afterwards; I ran `old.sh` = `c034a75:scripts/dev-cycle.sh` against `new.sh` = `71e618d:scripts/dev-cycle.sh`, wall clock from `date +%s%N`, 3 runs each):
- Repo with 400 **plain** decision records: old 1637 / 1643 / 1620 ms, new 1643 / 1608 / 1754 ms. No regression on the normal path. `skipped()` is never reached there, because `inrepo` succeeds first.
- Repo with 400 **symlinked** decision records plus 84 symlinked cycle records (484 skipped items): old 1031 / 1006 / 933 ms, new 1999 / 2005 / 2000 ms. That is about +1.0 s per 484 skipped items, about 2 ms per skipped item, which is consistent with the 2-3 extra `realpath` forks per item from the parent walk.
- `bats test/scripts/dev-cycle.bats` at 71e618d: 22/22 ok, 5.56 s wall.

## Findings

#### 1. Parent walk re-checks parents the glob caller already proved plain (redundant `realpath` forks per skipped glob item)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:104-113` (called from `:146` and `:197`)
**Move:** Count the hidden multiplications
**Classification:** Micro (2-3 extra process forks per skipped item, linear in the number of skipped items) / Cold path (a CLI digest run once per cycle)
**Confidence:** High (cost measured. The redundancy is decidable from the lines: both glob loops are entered only under `plaindir docs/working/cycles` (`:140`) or `plaindir docs/decisions` (`:195`))
**Legibility-target:** maintainer reading `skipped()`'s cost model
**Baseline:** a 2026-10-01 probe on a throwaway repo with 484 symlinked records took 1999 ms at 71e618d against 1031 ms at c034a75 (about 2 ms per skipped item). Production baseline: no baseline available — flagged as speculative (real repos have about 0 skipped items).

Evidence (the whole function, `:104-113`):
```
skipped() {
  local p="" c rest="$1"
  while [[ "$rest" == */* ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"; p="${p:+$p/}$c"
    [[ -e "$p" || -L "$p" ]] || return 1
    plaindir "$p" || { SKIPPED+=("$p/"); return 0; }
  done
  if [[ -e "$1" || -L "$1" ]] && ! inrepo "$1"; then SKIPPED+=("${1//$'\n'/ }"); return 0; fi
  return 1
}
```
For each glob item that fails `inrepo`, the walk runs `plaindir` on `docs`, then `docs/decisions` (or `docs`, `docs/working`, `docs/working/cycles`). The caller has already shown these are plain. `plaindir` of a deeper directory implies that every ancestor is plain, because its realpath must equal `$ROOT_REAL/<path>`. Then `inrepo` runs a second time on an item the caller already saw fail. So a skipped glob item costs 3-4 `realpath` forks where 1 was needed. The cost grows only with skipped items, which are pathological (symlinks or FIFOs among records). In the worst realistic case (a handful), the added cost is a few ms on a run that already takes about 1-2 s. This is not worth changing for performance. I report it so the cost model is on record, and because a cheaper form (start the walk below a known-plain prefix) would also make the "already known plain" case that the brief asks about explicit in the code, not implicit.

**Recommendation:** Leave it as it is. If anyone changes `skipped()` again, optionally pass the known-plain prefix so the walk starts below it. Doing that per item is not justified at realistic N.

#### 2. An unmatched glob now pays a full parent walk once

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:141-147` and `:195-197` (whole loops read through `:153` / the decisions loop body)
**Move:** Find the work that moved to the wrong place
**Classification:** Micro / Cold path
**Confidence:** Medium (decidable from the lines: without `nullglob`, an empty directory leaves the literal pattern as the one item. It fails `inrepo`, so `skipped` walks 2-3 existing plain parents, forks `realpath` on each, then finds that the literal name does not exist and returns 1. I did not time this separately)
**Legibility-target:** maintainer
**Baseline:** no baseline available — flagged as speculative

Evidence: `for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do` … `if ! inrepo "$f"; then` … `skipped "$f" && [[ "$d" > "$skipped_record" && ! "$d" > "$TODAY" ]] && skipped_record="$d"` … `continue` (loop continues to `done` at `:148`). Before this round, `skipped` on the literal pattern was one `[[ -e ]]` test. Now it is 2-3 forks, once per empty directory per run. That is at most about 6 ms per run. The result is correct: no false skip is recorded, because the walk ends at the missing leaf with `return 1`.

**Recommendation:** None needed. `shopt -s nullglob` around the two globs would remove the case entirely if the script is ever touched for another reason.

No other findings. Section 2's count reorder (`:193`), the Window-line note (`:159-161`) and the section 8 text are constant-cost. B's stale-brief rule adds at most one `git rev-list <default>..<branch>` per In-flight brief per cycle, and Q-103's text bounds that to 3. The skipped-record rerun clause adds at most one extra digest run per cycle (about 1-2 s in the probe). Neither adds up to anything: the cost is fixed per cycle and does not grow with the data.

## Endorsements

- On a repo with no skipped inputs (the normal case), the new `skipped()` adds no work. Every call site reaches it only after `inrepo` fails, and a timed probe with 400 plain decision records showed no change (old about 1.63 s, new about 1.67 s mean). `[read: scripts/dev-cycle.sh:143-147, 197, 206-218, 228-246, 263-268, 313-318, 324-337; inrepo/plaindir :92-96]`. The timing is my own probe, not a fact-check execution verdict.
- The parent walk is bounded by path depth, with at most 3 `/` separators for any name the script passes. So the cost per call is O(depth) forks, not O(N). `[read: scripts/dev-cycle.sh:104-113, 92-96]`
- The extra cost when items are skipped is linear in the number of skipped items, about 2 ms each, with no quadratic term. `skipped_record` is a running max, and `SKIPPED` is printed once through `sort -u` in section 8. `[unverified — submitted as claim]`: the 2 ms/item figure comes from one 484-item probe on this host, and linearity was not tested across several N.
- B's stale-brief rule terminates: "keep" writes a `Kept:` date that restarts the 14-day clock, and "drop" closes the brief. So each brief costs at most one open `you: judgment` entry at a time ("unless one is already open"), and the per-cycle check is bounded by the In-flight cap. `[read: /workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:216-223]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Parent walk re-checks known-plain parents and re-runs `inrepo` (about 2 ms per skipped item) | Informational | `scripts/dev-cycle.sh:104-113` | High |
| 2 | Unmatched glob now pays a 2-3-fork parent walk once | Informational | `scripts/dev-cycle.sh:141-147, 195-197` | Medium |

## Overall Assessment

From a performance standpoint, this fix round is clean for its purpose. The script is a once-per-cycle cold CLI. The only new work, the top-down parent walk in `skipped()`, runs only on inputs that are already pathological (symlinked or non-regular records). The probe shows it costs about 2 ms per such input and nothing on the normal path. Both findings are Informational (Micro × Cold) and need no change before merging. B's skill and question changes add a fixed, small number of git calls per cycle, bounded by the In-flight cap, and at most one digest rerun. No profiling beyond the probe above is needed.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."
This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass12.md`, first line `Commit: 71e618d (A) / 8286c2b (B)`, and follows the performance-reviewer structure: header, Data Flow and Hot Paths, Findings with Baseline and Classification, evidence-tagged Endorsements, Summary Table and Overall Assessment. It serves the user goal of a clean k=1 pass: it finds no performance issue that blocks merging either branch. Not committed, per instructions.
