Commit: 36417f5 (A) / db24c74 (B)

# Performance Review — dev-cycle pass 18 (pass-17 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 723c242..36417f5 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (cf18055, 36417f5), in `/workspace/.claude/wt-digest`. B: `git diff 1f36885..db24c74 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md`, in `/workspace/.claude/wt-devcycle`. Everything else is context only. The brief's focus: what `--diff-merges=combined` costs on the path-limited walk in a large repo with many merges, and what the fallback costs when many names miss.
**Date:** 2026-10-02
**Based on:** `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass17.md` (Stage-1 context). It verdicts 723c242 and says it "does not verdict the uncommitted edits" that became cf18055, so it has no execution verdict on this round's lines. Also based on `performance-review-2026-10-02-digest-pass17.md`, which predicted this round's fallback cost: "about 0.55 s each at 200k commits with no graph".

**Measurements.** All are mine, taken 2026-10-02 in this sandbox with git 2.39.5 and 16 cores. Scratch is under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf18/` (`perf18/` below). The scripts come from `git show 36417f5:` (new) and `git show 723c242:` (old), each with its own `questions.sh`.

I built two throwaway repos under `mktemp -d` with `git fast-import`. Both are deleted, and no probe processes remain.
- **R1** (`perf18/gen2.py 200000 300 500 10`, the same generator as pass 17). It has 220,001 commits and 20,000 merges, but only 20 merges survive history simplification under `docs/decisions`. It is the realistic shape: side branches fork just before they merge.
- **R2** (`perf18/gen3.py 200000 300 500 10 30 50`). It is the stress shape for combined diffs: 219,999 commits and 19,999 merges. Each side branch forks 30 steps back and edits a record, while main edits a record every third commit. So **all 19,999 merges differ from every parent under `docs/decisions`**. That means git keeps every one and computes its combined diff. 399 of them are evil merges.

| Run | Result |
|---|---|
| Map pipeline alone, as shipped (`--diff-merges=combined`) vs without it, 7 alternating reps, sorted (`perf18/reps-*.log`) | **R2 with Bloom: median 4,627 → 5,526 ms (+0.90 s, +19%, about 45 µs per kept merge)**. R2 with no graph: 4,837 → 5,786 ms (+0.95 s). R1 with Bloom: 144 → 144 ms (no difference). |
| Merges kept vs merges listing files, R2 (direct count) | 19,999 kept with or without the option. With no option, 0 list files. With combined, 399 list files (the evil merges). |
| `--cc` vs combined (`perf18/map-*.log`) | Within noise in every graph state (R2: about 5.5–6.0 s for both) |
| One fallback `git log -1 -- <never-committed path>` (`perf18/miss.log`) | R1: **~840 ms with no graph**, 108–144 ms with Bloom. R2: **~2,310 ms with no graph**, 114–1,745 ms with Bloom (it varies by name). This repo: 7 ms. |
| Full digest, new script, k untracked records with `## Revisit triggers`, `DEV_CYCLE_TODAY=2026-10-02` (`perf18/full-*.log`) | **R1 with no graph: k=0 8.1 s, k=50 53.5 s, k=150 142.1 s** (exit 0, 150 "never, uncommitted" lines). The old script (723c242) at k=150 took **8.6 s**. **R2 with no graph: k=0 16.6 s, k=50 140.0 s.** R1 with Bloom: k=0 5.9 s, k=150 26.2 s. |
| Derived (`arithmetic`, python3) | Per miss: R1 with no graph 893 ms, R2 with no graph 2,469 ms, R1 with Bloom 136 ms. The 120 s Bash-tool default is crossed at about **125 misses (R1), 42 (R2)** and 842 (R1 with Bloom). |
| One batched walk over 152 miss paths, no graph (`perf18/batch.log`) | R1 2.5 s; R2 34.7 s, because pathspec matching is O(patterns) per tree entry |
| This repo at 36417f5 (1,926 commits, 435 merges, 32 records) | Map 12–13 ms with or without combined, identical output (7 merges kept). A miss costs 7 ms. |
| `bats test/scripts/dev-cycle.bats` on `git archive 36417f5` (`perf18/bats.log`) | **24/24 ok**, 6.9 s (6.93 s at 723c242 in pass 17) |

Legibility-target values: **maintainer** (someone editing the script or tests), **agent** (the model running the skill), **user** (the human reading the digest).

## Data Flow and Hot Paths

A: `dev-cycle.sh` runs once per cycle as skill step 0. Every path in it is **cold**. The escalation case from earlier rounds still holds: the agent's Bash tool has a 120 s default timeout, and step 0 stops the cycle when the digest fails. That cliff was the reason for 723c242's one-walk map, which made section 2 O(H + R).

This round changes two things in section 2:
- **(1)** The walk gains `--diff-merges=combined` (`:219`). git already computes TREESAME for each merge to simplify history. The option adds a combined diff (a pathspec-limited tree diff against each parent) for each merge the walk keeps. Cost is O(kept merges × subtree size), paid once.
- **(2)** The fallback guard (`:228`) widens from "missed and has a control character" to "missed". Every record that has a `## Revisit triggers` section and no entry in the map now runs its own `git log -1 -- "$f"`. For a name that was never committed on HEAD, that call cannot stop early and walks all of history. Cost is O(misses × H), which brings back the R × H shape that 723c242 removed, now for the subset of records that miss.

The impossible-date guard (`:160`) adds one `date` fork per cycle record. B adds no executable code. Step 1 now always runs `questions.sh init` before `archive`, which is one extra short process per cycle.

## Findings

#### 1. The fallback on any miss makes every never-committed record a full history walk, which brings back the timeout cliff for uncommitted records

**Severity:** Low (Macro × Cold, escalated by the hot-path gate's exception because the cold path blocks the cycle at the 120 s tool timeout; consistent with how the full review's R × H finding, rubric C1, was graded). Preconditions: a large history (about 200k commits) and no commit-graph with changed-path Bloom filters (git's default; plain `gc` writes a graph without Bloom). It also needs about 40–125 records that have a `## Revisit triggers` section and were never committed on HEAD. Realistic cases: a batch of new records written before they are committed; adopting the digest in a repo whose `docs/decisions` is untracked or gitignored, where every record misses; a checkout whose HEAD is a branch that never had the records.
**Location:** `scripts/dev-cycle.sh:228` (A, 36417f5); the comment at `:208-215`
**Evidence (verbatim):** `[[ -n "${last_date[$f]+set}" ]] || d="$(git log -1 --format=%ad --date=short -- "$f")"`. It runs inside `for f in "${decisions_glob[@]}"; do` (`:222`), after `rawfile` (`:223`) and `grep -q '^## Revisit triggers' "$f" || continue` (`:224`). The unit continues to `:232` (`done`); `d` is first used at `:230`, `echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"`. The comment says: "instead of one `git log` per record, which / cost records x history." and "misses the map and falls back to its own lookup".
**Move:** Count the hidden multiplications; Check the asymptotic behavior
**Classification:** Macro (O(misses × H)) / Cold path (once per cycle, but a timeout stops the cycle)
**Confidence:** High (executed)
**Baseline:** Full digest on R1 (220,001 commits, no commit-graph) with 150 untracked records: **142.1 s, against 8.1 s with none and 8.6 s for 723c242 with the same 150**. Measured 2026-10-02 (`perf18/full-nograph.log`).
**Legibility-target:** maintainer

A miss is either a name git quotes (`"`, `\`, control characters) or a record never committed on HEAD's history. The first kind is rare, and its fallback stops at the record's last commit. The second kind is the common miss, and git cannot stop early for it: it diffs every commit and then prints "never, uncommitted", which is what 723c242 printed for free. Each such record costs about 0.9 s on R1 and about 2.5 s on R2 with no commit-graph, and about 0.14 s with Bloom filters. So the digest passes 120 s at about 125 untracked records on R1 and about 42 on R2. Before this round the cost was zero at any count. On this repo a miss costs 7 ms, so the regression needs a large history. The comment still presents the map as having removed "records x history", and it does not name the fallback's cost. The new test does not cover an uncommitted record, so neither the cost nor the "never, uncommitted" path is pinned.

**Recommendation:** Run the fallback only for names git would quote: `[[ -n "${last_date[$f]+set}" || "$f" != *[[:cntrl:]\\\"]* ]] || d=…`, the guard pass 17 recommended. A never-committed name then costs nothing again. A quoted name still costs one walk that stops early. This rests on the claim that an unquoted name missing from the directory walk has no per-file `git log -1` result either (see Endorsements: submitted as a claim). If the loop wants no such reliance, use `git log -z` for the map and a NUL-delimited reader, so that no name is quoted and the fallback can be deleted. Do not batch the misses into one multi-pathspec walk: it measured 34.7 s on R2. Add one uncommitted record to the dates test.

#### 2. `--diff-merges=combined` adds about 45 µs per kept merge, which is about 19% of the walk in a merge-heavy worst case and nothing in the realistic shape

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:219` (A, 36417f5)
**Evidence (verbatim):** `git -c core.quotePath=false log --diff-merges=combined --format='@%ad' --date=short --name-only -- docs/decisions \`. The unit continues at `:220`, `| awk '/^@/ { d = substr($0, 2); next } NF && !seen[$0]++ { print $0 "\t" d }')`, and then `fi`. The result is read into `last_date` and first used at `:227`.
**Move:** Count the hidden multiplications; Ask "what's the size of N?"
**Classification:** Micro (fixed cost per kept merge) / Cold
**Confidence:** High (executed)
**Baseline:** Map median **4,627 ms → 5,526 ms** on R2 (19,999 kept merges, Bloom graph, 7 reps) and 4,837 → 5,786 ms with no graph. 144 → 144 ms on R1. 12–13 ms both ways on this repo. Measured 2026-10-02 (`perf18/reps-*.log`).
**Legibility-target:** maintainer

N is the number of merges that history simplification keeps under `docs/decisions`. A merge is kept only when the directory differs from every parent. Merges that take one side's version of the directory, which is most merges, are skipped before any combined diff runs. That is why R1's 20,000 merges cost nothing. R2 is built so that every merge is kept, and even there the option adds under 1 s to a walk that runs once per cycle. The cost per merge also grows with the size of the `docs/decisions` tree, since each parent's subtree is compared. At 300 records that is about 45 µs, and I did not measure larger trees (verify data size if a repo has thousands of records). `--cc` costs the same within noise, so the choice between them should rest on output, not cost. Memory does not change: the map still holds one entry per distinct path (301–304 here).

**Recommendation:** None.

#### 3. The impossible-date guard forks `date` once per cycle record

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:160` (A, 36417f5)
**Evidence (verbatim):** `date -d "$d" >/dev/null 2>&1 || continue  # a name that is not a real date`. It sits inside `for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do` (`:152`), after the `rawfile` branch. The unit continues at `:161` (`[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"`) and ends at `done`.
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** maintainer

There is one fork per plain cycle record, and records grow by one per cycle (tens per year). The loop already pays one `rawfile` subshell with `realpath` forks per record, so the guard at most doubles a cost that is milliseconds at realistic counts.

**Recommendation:** None.

#### 4. B: step 1 runs `init` every cycle; an unapplied keep-or-drop answer is re-read and re-noted every cycle

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md` step 1 and step 6's keep-or-drop matching (B, db24c74)
**Evidence (verbatim):** "On the cycle branch, run `~/.claude/scripts/questions.sh init` (it creates only what is missing) and then `~/.claude/scripts/questions.sh archive` (it also reindexes)". `cmd_init` (`scripts/questions.sh:419-447`) runs `assert_write_targets` and then `[[ -e "$file" ]] && { echo "  = exists: $file"; continue; }` for each of the two files, so it writes nothing when both exist.
**Move:** Find the work that moved to the wrong place
**Classification:** Micro / Cold (once per cycle)
**Confidence:** Medium (init read in full; the per-cycle re-noting is the agent's attention, not compute)
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** agent

When both files exist, `init` costs one short shell process plus `assert_write_targets`. An answer that matches neither `[1]`/`1`/`keep` nor `[2]`/`2`/`drop` stays off `Applied:`, so each cycle reads it again and notes it again. That is fixed agent work per stale answer, bounded by the number of briefs. It is not a compute cost, and correctness belongs to the API and fact-check critics.

**Recommendation:** None for performance.

## Endorsements (evidence-gated)

- A: `--diff-merges=combined` costs a combined diff only for merges that simplification keeps under `docs/decisions` (19,999 of 19,999 on R2, 20 of 20,000 on R1), and the full digest stays far below the 120 s timeout at 0 misses (8.1 s on R1, 16.6 s on R2, with no graph). [read: /workspace/.claude/wt-digest/scripts/dev-cycle.sh:216-221] (timings: `perf18/reps-*.log`, `perf18/full-nograph.log`)
- A: Claim: a record name without `"`, `\` or control characters that is missing from the combined directory walk also gets no result from per-file `git log -1 -- f` on HEAD. If so, Finding 1's narrowed guard is exact. [unverified — submitted as claim]
- A: on this repo the combined map equals the map without the option (34 entries, identical file), and the walk takes 12–13 ms. [read: /workspace/.claude/wt-digest/scripts/dev-cycle.sh:219-220] (`perf18/real-*.tsv`)
- B: `questions.sh init` writes nothing when both files exist, so running it every cycle is idempotent. [read: /workspace/.claude/wt-devcycle/scripts/questions.sh:419-447]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The fallback on any miss: each never-committed record is a full history walk (0.9 s on R1, 2.5 s on R2, no graph). 150 untracked records: 142 s vs 8.6 s before; the 120 s cliff returns at about 42–125 misses | Low (cold; blocks the cycle at the timeout) | `scripts/dev-cycle.sh:228` | High |
| 2 | `--diff-merges=combined`: about 45 µs per kept merge, +0.9 s (+19%) when all 20k merges are kept, 0 in the realistic shape | Informational | `scripts/dev-cycle.sh:219` | High |
| 3 | Impossible-date guard: one `date` fork per cycle record | Informational | `scripts/dev-cycle.sh:160` | High |
| 4 | B: `init` every cycle (idempotent); unapplied answers re-noted each cycle | Informational | `skills/dev-cycle/SKILL.md` step 1, step 6 | Medium |

## Overall Assessment

`--diff-merges=combined` is cheap. Simplification already skips merges that take one side's version of `docs/decisions`. Even when all 19,999 merges are kept, it adds under 1 s once per cycle, and `--cc` would cost the same. The fallback is the one real cost, and pass 17 had priced it. Falling back on any miss turns each never-committed record into a full history walk. That brings back the records × history cliff that 723c242 removed, now for uncommitted records: 150 of them on a 220k-commit repo with no commit-graph take the digest from 8.6 s to 142 s, past the tool timeout. It needs a large history and many uncommitted or untracked records, so it is Low, and this repo is unaffected (7 ms per miss). The fix stays in place and costs nothing: narrow the guard to names git quotes, or remove the need for the fallback with `-z`. Then add an uncommitted record to the dates test. I checked the combined-diff cost, map memory, the impossible-date guard, the new tests' runtime (24/24, 6.9 s) and B's init/archive change. Within this lens they are correct and complete. No further profiling is needed.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass18.md`, and its first line is `Commit: 36417f5 (A) / db24c74 (B)`. It follows the performance-reviewer structure: header, Data Flow, Findings with Baseline and Classification, evidence-tagged Endorsements, Summary Table and Overall Assessment. Each finding also carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. Toward the user goal (merge once a clean pass is reached), it reports one Low finding (Finding 1), measured by execution, with a one-line fix. The loop should resolve or accept it before calling a pass clean. The combined-diff change the brief asked about adds no blocker.
