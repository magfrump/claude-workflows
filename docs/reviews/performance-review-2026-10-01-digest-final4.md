Commit: db0e5ca

# Performance Review — feat/dev-cycle-digest, final pass 4

**Scope:** `git diff main...HEAD -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (both new on the branch; reviewed HEAD db0e5ca)
**Date:** 2026-10-01
**Based on:** Stage-1 merged fact-check summary (`digest-final4-stage1-dc1aa358.md`; replicates `docs/reviews/code-fact-check-report-r{1,2,3}-digest-final4.md`)

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` is a read-only CLI that prints a markdown digest, run about once per dev cycle (every couple of weeks) by a person or by the dev-cycle skill's agent, which then reads the whole digest into its context. That makes it a **cold path**: nothing calls it per request or per item. Two costs still matter:

- **Wall time on large histories.** Sections 1 and 7 now walk the whole history of the default branch and filter by `%cs` afterwards. Section 2 runs one path-limited `git log -1` per decision record. Section 6 starts processes once per merge in the window.
- **Digest size.** The output goes into an agent's context, so every uncapped list costs tokens on each run.

Data sizes: this repo has 1,892 commits, 385 first-parent merges and 33 decision records. To test scale I built a synthetic repo with `git fast-import`: 219,999 commits, 19,999 first-parent merges, 30 decision records created in the root commit and never touched again (the normal shape for decision records), 2,000 source files and dates spread over 2017-07 to 2026-09. I timed it with and without a commit-graph (`--changed-paths`). All numbers below are my own measurements from 2026-10-01 in this sandbox (git 2.39.5). The generator and timing scripts are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf-final4/`.

| Run (wall time) | baa46e3 | db0e5ca |
|---|---|---|
| This repo, `--since=2026-09-17` | — | 0.32 s |
| This repo, `--since=2000-01-01` | — | 0.92 s |
| Synthetic, 14-day window, no commit-graph | 28.4 s | 34.8 s |
| Synthetic, 14-day window, commit-graph + Bloom | 3.98 s | 9.55 s |
| Synthetic, all-history window, no commit-graph | — | 81.0 s (10,182 output lines) |
| Synthetic, all-history window, commit-graph | — | 61.5 s |

## Findings

#### 1. Full-history walks in sections 1 and 7 cost O(all history) on every run; a date-bounded filter gives the same result in about 4% of the time

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:99`, `:102`, `:199`
**Move:** Work moved to the wrong place / asymptotic behavior
**Classification:** Macro (cost scales with total history, not with the window) / Cold path (run about once per cycle)
**Confidence:** High
**Baseline:** 2.1 s per walk (`:102` and `:199` each) on the 219,999-commit synthetic repo with a commit-graph, measured 2026-10-01. baa46e3's `--since` equivalent took 0.01 s.
**Legibility-target:** for-author

**Evidence:**
```
99:  merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"
102: commits="$(git log "$MAIN_SHA" --format=%cs | awk -v s="$SINCE" '$1 >= s' | wc -l)"
199: oldest="$(git log "$MAIN_SHA" --first-parent --format='%cs %H' | awk -v s="$SINCE" '$1 >= s { h = $2 } END { print h }')"
```

The R3 fix (the fact-check confirms it, and test 4 fails on baa46e3) does three walks of the whole history and formats every commit, only to discard everything older than the window. Most of the cost is formatting, not walking: `git rev-list --count` over the same 220k commits takes 0.07 s with a commit-graph, but `git log --format=%cs` takes 2.1 s because it must parse every commit object.

These three walks account for almost all of the 3.98 s to 9.55 s regression in the synthetic 14-day run:
- `:102`: 2.1 s
- `:199`: 2.2 s
- `:99`: 0.36 s (0.86 s without a commit-graph)

Scaling is linear in history length, so the kernel-sized cost (about 1.3M commits) is roughly 6× these numbers. That figure is extrapolated, not measured: speculative. On this repo the total is 0.3 s, so nothing hurts today.

A precise alternative keeps the exact `%cs` semantics: pre-filter with `--since-as-filter`, which filters without stopping at the first old-dated commit, using a margin of at least one day to absorb timezone offsets of up to ±14 h, then keep the existing awk comparison. On the synthetic repo:
- `git rev-list --count --since-as-filter='<date> 00:00'`: 0.08 s
- `git rev-list --first-parent --since-as-filter=… | tail -1` for `:199`: 0.07 s

On a small fixture with an old-dated commit in the middle, `--since` counted 2 commits while `--since-as-filter` and the awk filter both counted 3. Without the margin, `--since-as-filter` alone gave 937 vs 955 commits for one window, because it uses local midnight instead of the committer's own-zone date. That is the semantic difference the Stage-1 report already flags. The margin plus the awk check avoids it.

**Recommendation:** Add `--since-as-filter="$(date -d "$SINCE - 1 day" +%F) 00:00"` to the three walks and keep the awk `%cs` test as the exact filter. It needs git 2.37 or newer, so note that in the header or fall back to the full walk on older git. Walks `:99` and `:199` cover the same first-parent line and could also share one walk that prints `%P` and derives the merges.

#### 2. Section 2 runs one path-limited history walk per decision record: O(records × history), the largest single cost in the script

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:111-120` (the call is at `:116`)
**Move:** Count the hidden multiplications
**Classification:** Macro (records × commits since each record's last change) / Cold path
**Confidence:** High
**Baseline:** 0.87 s per record, 26 s for 30 records, on the synthetic repo without a commit-graph. 3.56 s for all 30 with a commit-graph with Bloom filters. Measured 2026-10-01.
**Legibility-target:** for-author

**Evidence:**
```
111: for f in docs/decisions/[0-9][0-9][0-9]-*.md; do
112:   [[ -f "$f" ]] || continue
113:   grep -q '^## Revisit triggers' "$f" || continue
114:   found=1
115:   echo
116:   d="$(git log -1 --format=%ad --date=short -- "$f")"
...  (:117-120: heading echo, trig print, done)
```

Decision records are written once and rarely edited, so `git log -1 -- "$f"` usually walks back to the commit that created the record. That makes the loop cost roughly records × history. On the synthetic repo this loop dominates both versions of the script: 26 of baa46e3's 28.4 s without a commit-graph. On this repo it takes 0.09 s for 33 records.

This loop predates d9e4cb9, but the file is new on the branch and so in scope. Every run now prints every trigger, so the loop runs over every record on every run with no early exit. The cost grows with both the record count and the history length.

A single path-limited walk gives the same "last committed" date for all records in 0.12 s on the synthetic repo:

```
git log --format='@%ad' --date=short --name-only -- docs/decisions | awk '/^@/ {d = substr($0, 2); next} NF && !($0 in s) {s[$0] = d; print $0, d}'
```

**Recommendation:** Replace the per-file `git log -1` with that one walk, read into an associative array before the loop. Keep the per-file lookup only if record counts are expected to stay in the tens. If so, document that as the assumption.

#### 3. Section 6 starts processes per merge and has no output cap, so a wide window costs minutes of wall time and thousands of digest lines

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:183-193`
**Move:** Count the hidden multiplications / what's the size of N
**Classification:** Macro (linear in merges in the window, unbounded output) / Cold path, but the output feeds an agent's context
**Confidence:** High
**Baseline:** 25.3 s for the per-merge `git diff` loop alone over 19,999 merges, compared with 0.50 s for one `git log --diff-merges=first-parent --name-only` process, on the synthetic repo. The full all-history digest took 81.0 s and printed 10,182 lines, 10,000 of them section-6 bullets. Measured 2026-10-01.
**Legibility-target:** for-author

**Evidence:**
```
184: while read -r _ full _; do
185:   [[ -n "$full" ]] || continue
186:   counts="$(git diff --name-only -z "$full^1" "$full" | awk -v RS='\0' 'NF { if ($0 ~ /^docs\// || $0 ~ /\.md$/ || $0 ~ /(^|\/)README/) d++; else c++ } END { print c + 0, d + 0 }')"
187:   read -r n_code n_docs <<< "$counts"
188:   if [[ "$n_code" -gt 0 && "$n_docs" -eq 0 ]]; then
189:     flagged=1
190:     echo "- $(git log -1 --format='%h %ad %s' --date=short "$full") ($n_code file(s), no doc change)"
191:   fi
192: done <<< "$merges_full"
193: [[ $flagged -eq 1 ]] || echo "None in the window."
```

Each merge in the window costs a `git diff` plus an awk process, and each flagged merge costs another `git log -1`. In a normal 14-day window this is negligible: about 80 merges on the synthetic repo, about 0.35 s.

The window is not always 14 days. It runs from the newest cycle record (`:80-87`), or from any explicit `--since`, so it grows with every skipped cycle. Section 1 caps its list at 30 lines (`:105`) and section 7 caps its lists at 20 (`:214-215`), but section 6 prints every flagged merge. A wide window therefore puts an unbounded list into the reading agent's context:
- On this repo's full history: 27 lines.
- On the synthetic full history: 10,000 lines.

Separately, `:190` spends a `git log -1` to re-fetch `%h %ad %s`, which line 99 already put into `merges_full`. That line's `read -r _ full _` throws those fields away.

**Recommendation:** Cap the section-6 list the way section 1 does (`… N more`). Read `%h %ad %s` from the `merges_full` line instead of calling `git log -1` again. If wide windows are expected, replace the loop with one `git log "$MAIN_SHA" --first-parent --merges --diff-merges=first-parent --name-only -z` pass. That needs git 2.31 or newer.

#### 4. Per-row process spawns in the decision-log loop

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:121-132`
**Move:** Count the hidden multiplications
**Classification:** Micro (4 to 6 short-lived processes per row) / Cold path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
124:     n="$(awk -F'|' '{ gsub(/ /, "", $2); print $2 }' <<< "$row")"
125:     d="$(awk -F'|' '{ gsub(/ /, "", $3); print $3 }' <<< "$row")"
...
128:     text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"
129:     [[ -n "$text" ]] || text="$(grep -oiE 'revisit[^|]*' <<< "$row" | head -1 || true)"
...  (:130-132: echo, done < <(grep … log.md), fi)
```

There are 9 matching rows today, out of 65 log rows. This only matters if log.md grows into the thousands. A single awk pass over log.md would do the same work. Not worth changing now.

## Endorsements (evidence-gated)

- Section 7's file lists come from one pathspec-limited tree diff (`git diff --name-only -z "$base" "$MAIN_SHA" -- skills workflows docs/decisions`), not from a per-commit walk. Its cost scales with the changed paths under three directories, not with the number of commits in the window. `[read: scripts/dev-cycle.sh:199-205]`
- The two lists in section 1 and section 7 are capped at 30 and 20 printed lines, with a "… N more" line. `[read: scripts/dev-cycle.sh:105, :212-215]`
- `scrub()` is one perl process per stream (stdout and stderr), set up once by `exec`. It is not started per line or per section. `[read: scripts/dev-cycle.sh:28-31]`
- After the cut, the script no longer calls `git merge-base --is-ancestor` or `rev-list --before` to find a base. That removes baa46e3's base-lookup work. `[fact-check: verified highlight — code behind R1, R2, A1, A3, A5, A6, C1, C3 is gone]`
- Adding the `--since-as-filter` pre-filter from finding 1, with a one-day margin, leaves the section-1 counts and the section-7 base unchanged on every repo, because the awk `%cs` test stays the exact filter. `[unverified — submitted as claim]` I checked only equal counts on one fixture, and the reasoning that ±14 h offsets fit within a one-day margin.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Three full-history walks to filter a date window; `--since-as-filter` pre-filter is about 25× faster with the same result | Low | `scripts/dev-cycle.sh:99,102,199` | High |
| 2 | One `git log -1 -- f` per decision record: O(records × history), the biggest cost in the script | Low | `scripts/dev-cycle.sh:116` | High |
| 3 | Section 6 starts processes per merge, re-fetches fields it already has, and has no output cap | Low | `scripts/dev-cycle.sh:183-193` | High |
| 4 | Per-row process spawns in the log.md loop | Informational | `scripts/dev-cycle.sh:121-132` | High |

## Overall Assessment

The script is a cold-path CLI, and at this repo's size everything runs in 0.3–0.9 s. None of these findings blocks the merge.

The new sections did make the cost scale with total history instead of with the window. On a 220k-commit history with a commit-graph, the 14-day digest went from 3.98 s to 9.55 s, almost all of it from the three full walks in sections 1 and 7.

The pre-existing per-record walk in section 2 is the largest absolute cost without a commit-graph (26 s of 35 s).

The one finding with a cost beyond wall time is section 6's uncapped list. A wide window, caused by skipped cycles or an old `--since`, puts every flagged merge into the reading agent's context, while the neighbouring sections cap theirs.

All three fixes are local:
- a date pre-filter on the walks;
- one path-limited walk for the record dates;
- a 30-line cap on section 6, plus reusing the fields `merges_full` already holds.

No further profiling is needed to decide. The numbers above come from a synthetic repo, so check them against a real large repo before relying on the 6× kernel extrapolation.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `docs/reviews/performance-review-2026-10-01-digest-final4.md` in the worktree, with `Commit: db0e5ca` first. It follows the performance-reviewer skill's structure:
- header
- data flow and hot paths
- findings, each with Severity, Location, Evidence, Confidence, Legibility-target, Baseline and Classification
- evidence-gated endorsements
- summary table
- overall assessment

It serves the user's goal of deciding whether `feat/dev-cycle-digest` merges. On performance it finds nothing that should block the merge, and it lists three Low fixes with measured costs.
