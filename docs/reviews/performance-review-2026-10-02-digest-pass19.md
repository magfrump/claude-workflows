Commit: 1b0c4ff (A) / 462e561 (B)

# Performance Review — dev-cycle pass 19 (pass-18 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 36417f5..1b0c4ff -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff db24c74..462e561 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` in `/workspace/.claude/wt-devcycle`. Everything else is context only.
**Date:** 2026-10-02
**Based on:** `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass18.md` (Stage-1 context; it verdicts 36417f5/db24c74, so it has no execution verdict on this round's lines) and `performance-review-2026-10-02-digest-pass18.md` (finding 1, which this round's fallback change answers).

**Measurements.** All mine, 2026-10-02, this sandbox, git 2.39.5. Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf19/` (`perf19/` below). Scripts from `git show 1b0c4ff:scripts/{dev-cycle,questions}.sh`. Every process ran under `timeout`; throwaway repos are under `mktemp -d` dirs inside `perf19/`; nothing was written to either worktree except this file.

- **R1**: rebuilt with pass 18's generator (`perf18/gen2.py 200000 300 500 10` into `git fast-import`): 220,001 commits, 301 records, 2,706 index entries, **no commit-graph**. Full digest via `perf19/full.sh` (adds k records with `## Revisit triggers`, optionally `git add`s them, runs the digest with `GIT_TRACE2_EVENT` to count git calls, then resets and removes them) → `perf19/full.log`:

| Run (R1, no graph) | Wall | `git log -1` calls | `ls-files --error-unmatch` calls | "never, uncommitted" lines |
|---|---|---|---|---|
| k=0 (two runs) | 8,471 / 8,530 ms | 1 (the roadmap line, `:320`) | 0 | 0 |
| k=150 **untracked** (two runs) | 10,411 / 10,306 ms | 1 | 150 | 150 |
| k=20 **staged, never committed** | 26,252 ms | 21 | 20 | 20 |
| k=50 **staged, never committed** | 55,111 ms | 51 | 50 | 50 |

- Pass 18 measured the same R1 shape at k=150 untracked on 36417f5: **142.1 s** (`perf18/full-nograph.log`). This round: 10.4 s.
- Derived (python3): per staged miss 888–932 ms; the 120 s Bash-tool default is crossed at about **120 staged never-committed records**; per untracked record +12.4 ms of whole-digest time (trace on).
- `git ls-files --error-unmatch -- <absent path>`, 100 calls × 3 (`perf19/lsfiles-cost.log`): **~1.0 ms/call on R1's 2.7k-entry index, ~5.7 ms/call on a synthetic 100k-entry index**.
- `bats test/scripts/dev-cycle.bats` on `git archive 1b0c4ff`: **24/24 ok, rc 0, 6.9 s** (`perf19/bats.log`; 6.9 s at 36417f5 in pass 18).
- Side probe (`perf19/deleted-index.log`): records committed, then `git rm --cached` and committed (on disk, untracked). Per-file `git log -1` says 2026-02-05 for both; the digest prints `001-a"b.md (... never, uncommitted)` and `002-plain.md (... 2026-02-05)`.

Legibility-target values: **maintainer** (someone editing the script or tests), **agent** (the model running the skill), **user** (the human reading the digest).

## Data Flow and Hot Paths

A: `dev-cycle.sh` runs once per cycle as skill step 0; every path in it is **cold**. The standing escalation case is the agent's 120 s Bash-tool default: step 0 stops the cycle when the digest fails, so a cold path that can cross 120 s is graded with the hot-path gate's exception (as rubric C1 and pass-18 finding 1 were).

This round's A changes:
- **Fallback guard** (`:231-236`): a record missing from the one-walk date map now runs `git ls-files --error-unmatch` (an index lookup, O(index) per call, ~1–6 ms) and only on success its own `git log -1 -- "$f"` (O(H) when the path has no commit). Cost is O(misses × index) + O(tracked misses × H).
- **Skipped-record date check** (`:157-158`): one `date -d` fork, only after `skipped "$f"` and the string comparisons succeed, i.e. at most once per non-plain record name that would become the newest skipped date. Negligible.
- Comment and test changes: no runtime cost; the test adds one uncommitted record (bats time unchanged).

B adds no executable code. Its performance surface is agent work per path: the mechanical rule runs check 2 (`git ls-files --error-unmatch`) and check 3 (`test -L` per component) on every path taken from repo text in steps 2–6. Step 1's new skip removes two short processes when it fires. Answer parsing and the `-<n>` slug read one `Asked:` line; constant work.

## Findings

#### 1. A record that is staged but never committed still takes the full-history fallback walk

**Severity:** Informational (Macro × Cold). Preconditions for any visible cost: a large history with no changed-path Bloom filters, and records added to the index but not committed on the checkout the digest runs on. For the 120 s cliff: about 120 such records. Step 0 runs "from the root of an up-to-date checkout of the default branch, before the cycle branch is created", where staged-but-uncommitted records are unusual and a batch of 120 is not realistic, so the exception that escalated pass-18 finding 1 does not apply.
**Location:** `scripts/dev-cycle.sh:231-236` (A, 1b0c4ff)
**Evidence (verbatim):**
```bash
  # Fall back only for a tracked record (an index lookup, no history walk): an
  # untracked one was never committed here, and a full walk to prove it cost
  # ~1 s per record on a 220k-commit repo.
  if [[ -z "${last_date[$f]+set}" ]] && git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    d="$(git log -1 --format=%ad --date=short -- "$f")"
  fi
```
(excerpt ends `:236`; the enclosing `for f in "${decisions_glob[@]}"; do` loop runs `:225-240`, read in full; `d` is first used at `:238`, `echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"`.)
**Move:** Count the hidden multiplications; Check the asymptotic behavior
**Classification:** Macro (O(staged misses × H)) / Cold path (once per cycle)
**Confidence:** High (executed)
**Baseline:** Full digest on R1 (220,001 commits, no commit-graph) with 50 staged never-committed records: **55.1 s, against 8.5 s with none** (`perf19/full.log`, 2026-10-02); 51 `git log -1` calls in the trace.
**Legibility-target:** maintainer

"Tracked" here means "in the index", which is wider than "committed on this branch": a `git add`ed new record passes `ls-files` and then walks all 220k commits to print "never, uncommitted", about 0.9 s each on R1. The comment's "an untracked one was never committed here" is true, but the converse it leans on (a tracked miss has history) is not; the cost note covers only the untracked side. The fix does close pass-18 finding 1 for its main cases (untracked records, an untracked or ignored `docs/decisions`, a branch that never had the records: 150 untracked now cost 10.4 s against 142.1 s). The new test pins only the untracked path, not a staged one.

**Recommendation:** Either accept and say "tracked (in the index)" in the comment, or tighten the guard to the only committed names the map can miss — names git quotes — e.g. `[[ -z "${last_date[$f]+set}" && "$f" == *[[:cntrl:]\\\"]* ]]` (no fork at all for the common miss; it rests on the submitted claim below), or `git cat-file -e "HEAD:$f"` (one fork; excludes staged-only records but also excludes the deleted-from-HEAD case in the side probe). No change is needed for performance at realistic counts.

#### 2. B: the per-path checks, if run as one command per path, cost agent round trips rather than CPU

**Severity:** Informational (Micro × Cold)
**Location:** `skills/dev-cycle/SKILL.md:65-72` (B, 462e561)
**Evidence (verbatim):** "opened only if all of these hold, checked in this order:" … "2. `git ls-files --error-unmatch -- '<path>'` accepts it, so it is a tracked file (expand a glob first, with the same check on each match);" "3. no part of it below the repo root is a symlink (`test -L '<part>'` on each component)." (excerpt ends at `:72`; the rule's paragraph continues to `:81`, read.)
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed per-path overhead) / Cold path (once per cycle, per path read)
**Confidence:** Medium (the per-path count and the agent's batching behavior are not observable statically)
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** agent

The CPU cost is trivial (~1 ms per `ls-files` call on R1's index, ~5.7 ms at 100k entries, measured). The real cost is the agent's: steps 2–6 and step 4's per-merge subagents may read tens of paths per cycle (sampled-merge claims, glob matches of idea sources, files questions name), and the text's per-path, per-component wording invites one tool call per check, i.e. 2 + (components) round trips per path, each costing seconds of latency and context tokens. "Expand a glob first" also leaves the expander open: a shell glob returns untracked matches that check 2 then rejects one at a time, while `git ls-files -- '<glob>'` returns only tracked matches in one call.

**Recommendation:** Add one sentence allowing a batch: run check 2 once over all candidate paths (`git ls-files -- 'a' 'b' …` and keep only the paths it prints, or expand a glob with `git ls-files -- '<glob>'`), and check 3 for all of them in one shell loop. Same semantics, one or two tool calls per step instead of one per path.

## Endorsements

- Untracked records no longer walk history: on R1 (no graph) 150 untracked records add about 1.9 s to the digest, 150 `ls-files` calls and no extra `git log -1` calls, against 142.1 s in pass 18. `[unverified — submitted as claim]` (my execution, `perf19/full.log`; not a fact-check verdict)
- An unquoted, committed name always has a map entry, so the only committed records that reach the fallback are names git quotes (the basis for finding 1's no-fork guard). `[unverified — submitted as claim]`
- The skipped-record `date -d` fork runs only after `skipped "$f"` and the three string tests succeed, so it adds no fork for plain records. `[read: scripts/dev-cycle.sh:157-158]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Staged-but-never-committed records still pass the `ls-files` guard and walk all history (0.9 s each on R1; 50 → 55.1 s; ~120 to cross 120 s) | Informational | `scripts/dev-cycle.sh:231-236` | High |
| 2 | B: per-path, per-component checks invite one agent tool call each; batch them | Informational | `skills/dev-cycle/SKILL.md:65-72` | Medium |

## Overall Assessment

The fix round resolves pass-18 finding 1 as intended: the cliff for untracked records is gone (142.1 s → 10.4 s at 150 records on a 220k-commit repo with no commit-graph), at a cost of one index lookup per miss (~1–6 ms). What remains is a narrow residue (records staged but never committed still walk history) that needs an unusual checkout to matter; it is fixable in place with a one-line guard change and needs no further measurement. B adds no executable code; its only performance effect is agent round trips per checked path, addressable by allowing batched checks. Nothing here blocks the loop on performance grounds.

**Outside this lane (for the fact-check / API stages, not graded here):**
- Brief claim 1's "a file deleted from the index but present in history": a quoted name removed from the index (`git rm --cached`, committed) and left on disk prints "never, uncommitted" while per-file `git log -1` gives 2026-02-05; the unquoted twin gets the right date (`perf19/deleted-index.log`). The new guard skips the fallback for it. Low, informational date only.
- Check 1's character set excludes `*`, yet the only idea-source row is the glob `docs/working/feature-ideas*.md` (`docs/dev-cycle.md:33`), and check 2 says to expand a glob only after check 1. Read literally, the rule rejects the repo's own idea source before expansion; it should say check 1 applies to each expanded match (or allow `*` in a settings-row glob).

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass19.md` with the required first line, and follows the performance-reviewer structure (header, data flow and hot paths, findings with Severity, Location, verbatim Evidence, Confidence, Baseline and Legibility-target, evidence-tagged endorsements, summary table, overall assessment). It covers the brief's scope: the pass-18 fix round in A (1b0c4ff) and B (462e561), with brief claims 1 and 2 addressed from the performance side and two out-of-lane observations handed on. Not committed, per instructions.
