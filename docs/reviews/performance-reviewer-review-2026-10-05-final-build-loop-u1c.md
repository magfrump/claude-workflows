Commit: 4dc84ce4

# Performance Review — feat/build-loop-u1c (iteration 3, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1c` at 4dc84ce4, focused on `scripts/build-loop.sh:297-353` (shared_branches, status_line) and the lib callees it runs (`scripts/lib/dev-cycle-read.sh` main_entry :258, brief_fields :289, check_brief :321, check_branch :370, lower :430)
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (Stage-1 merged summary, claims 20b, 22, 28)

## Data Flow and Hot Paths

`build-loop.sh --status BRIEF...` runs once per orchestrator query (planned U4 skill, possibly once per loop iteration). It reads settings, then for each argument runs status_line. The first status_line call runs shared_branches once (`[[ -n "$SHARED_BRANCHES" ]] || shared_branches`, :318; after it runs SHARED_BRANCHES is at least `$'\n'`, so it never runs again). shared_branches now lists candidates with one `git grep -l` over `docs/working/briefs/` on main (:306) and runs brief_fields (≈5 forks: main_entry subshell + ls-tree, cat-file | env awk, lower's tr) only on files that hold a `Status: open` line. Per argument, status_line then runs check_brief (blocker, main_entry, brief_fields, `git log -G`), brief_fields again, check_branch, and marker_kind for a tip ahead of main.

Path temperature: cold-to-warm (a CLI invoked per orchestrator iteration, not a request handler). Data sizes: closed briefs grow without bound over the repo's life; open briefs are bounded in practice by the queue (this repo has 3).

### Measurements (this pass)

Fixture: throwaway repos under my scratch dir (`mk.sh`), 3 open briefs (one with a `handoff: ready` tip), plus N closed or extra open briefs; median of 3 wall-clock runs, `LC_ALL=C.UTF-8`, `GIT_CONFIG_GLOBAL=/dev/null`. "old" is c143b929's build-loop.sh and lib copied into the scratch dir.

| Shape | 4dc84ce4, 1 arg | 4dc84ce4, 3 args | c143b929, 1 arg |
|---|---|---|---|
| 0 closed | 0.085 s | 0.125 s | 0.097 s |
| 50 closed | 0.085 s | 0.153 s | 0.361 s |
| 200 closed | 0.081 s | 0.167 s | 2.191 s |
| 500 closed | 0.131 s | 0.193 s | 10.720 s |
| 2000 closed | 0.184 s | 0.296 s | (not run) |
| 200 closed × 100 KB each (21 MB) | 0.120 s | 0.147 s | — |
| 3 open × 2 MB each | 0.634 s* | 0.293 s | — |
| +10 extra open | 0.236 s | 0.309 s | 0.204 s |
| +50 extra open | 0.629 s | 0.742 s | 0.672 s |
| +200 extra open | 3.248 s | 2.925 s | 2.756 s |
| +500 extra open | 10.778 s | 9.037 s | 8.763 s |

\* single noisy cell; the 3-arg run on the same repo is 0.29 s.

Output was checked at 2000 closed (correct `ok` lines), and with a 2001st closed brief carrying `Status: open\r` and `Branch: FEAT/O1`, open1 was skipped as shared (F31 still sees closed/ open briefs, CRLF and case folded).

**A15/X1 verdict: resolved under default config.** Cost in the closed-brief count went from about 21 ms per closed brief (10.7 s at 500) to about 0.05 ms per closed brief (0.18 s at 2000), which is one git grep. Brief size does not matter either: 21 MB of closed briefs adds nothing measurable. Each extra argument adds about 30–50 ms (check_brief + brief_fields + check_branch), with no dependence on N.

## Findings

#### F1. --status still costs ~15–21 ms per OPEN brief on main, mildly superlinear (residue of row 266, not re-filed)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:307-312`
**Move:** Hidden multiplication / size of N
**Classification:** Macro (per-open-brief subprocess chain, with main_entry's ls-tree growing with the briefs/ tree) / Cold path (CLI per orchestrator iteration)
**Confidence:** High (measured)
**Baseline:** 10.8 s for `--status` with one argument at 503 open briefs, measured in this pass (scratch fixture o500, median of 3)
**Legibility-target:** for-orchestrator-synthesis

**Evidence** (`scripts/build-loop.sh:307-312`; the excerpt ends :312, and shared_branches continues to :315 (read): it builds SHARED_BRANCHES from n):
```
  while IFS= read -r f; do
    f="${f#"$MAIN_SHA":}"
    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
    b="$(lower "${BASH_REMATCH[1]}")"; n[$b]=$(( ${n[$b]-0} + 1 ))
  done <<<"$list"
```
Every grep candidate still goes through brief_fields (pathform, a main_entry subshell with `git ls-tree -t --full-tree`, `git cat-file | env LC_ALL=C awk`) plus a `lower` fork. Per-brief cost rises from about 16 ms at 200 open to about 21 ms at 500, because each ls-tree walks a larger briefs/ tree. That gives 0.63 s at 50 open, 3.2 s at 200 and 10.8 s at 500, the same as c143b929. The fix was never meant to change this shape. It runs once per run, not once per argument. Open briefs are bounded by the queue, so the realistic N is under 10. This is the case row 266 defers, with "more than 50 briefs on main" as its trigger. That trigger is now conservative, because closed briefs no longer count toward the cost.

**Recommendation:** None for U1c. When row 266's trigger fires, replace the per-candidate brief_fields with one `git cat-file --batch` over the grep list plus a single awk pass. That makes the cost one process pair, whatever the open count.

#### F2. The fail-open fix for claim 20b must not reintroduce the full scan

**Severity:** Informational
**Location:** `scripts/build-loop.sh:306`
**Move:** Work moved to the wrong place (guarding a future fix)
**Classification:** Macro (would restore O(closed briefs)) / Cold path
**Confidence:** Medium
**Baseline:** 10.7 s at 500 closed briefs for c143b929's full scan, measured in this pass. Applies only if a fallback is added: no baseline available — flagged as speculative.
**Legibility-target:** for-author

**Evidence** (`scripts/build-loop.sh:306`; the excerpt ends :306, and shared_branches continues to :315 (read)):
```
  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
```
Fact-check claim 20b (Incorrect, 3/3) and its escalation (F31 fails open under forced colour or a failing git grep) belong to the security reviewer and the orchestrator, not to me. I note only the performance constraint on the fix. Adding `--no-color` (or `-c color.grep=false`) and refusing on an exit status other than 0 or 1 keeps today's one-grep cost. A fix that falls back to brief_fields over every file under briefs/ when the grep fails would restore the 10.7 s at 500 closed briefs that A15 removed.

**Recommendation:** Fix 20b by forcing no colour and failing closed on a grep error. Do not add a full-scan fallback.

## Override rows 266 / 267 / 269 (premise check)

- **Row 266** (shared_branches quadratic in the brief count; Defer, trigger: more than 50 briefs on main, or U4 calling --status with every brief). Iteration 2 changed its premise, because closed briefs were scanned. At 4dc84ce4 the premise holds again, and more weakly than the row states. Cost scales with open briefs only (F1), and closed briefs cost one git grep (0.18 s at 2000). **Holds.**
- **Row 267** (each brief parsed several times; one tr per brief; Defer, same trigger). This is still literally true: a queried open brief goes through brief_fields three times (in shared_branches, in check_brief, and at status_line :324), and lower forks tr once per open candidate. The marginal cost per argument is 30–50 ms, measured above, and does not depend on the closed count. **Holds.**
- **Row 269** (U4's skill should call --status once with every brief; Defer to U4's skill text). This still holds and matters a little more now. A run's fixed cost (scrub re-exec, settings, the git grep, shared_branches over open briefs) is about 85 ms. Each extra argument in the same run costs about 30–50 ms. So one call with k briefs beats k calls. **Holds.**

## Endorsements

- shared_branches runs at most once per `--status` run whatever the argument count, because status_line guards it with `[[ -n "$SHARED_BRANCHES" ]]` and shared_branches always leaves it non-empty. [fact-check: claim 22 — Verified executed] (BRIEF holds the queried brief in every call), and see the flat argument scaling above.
- `--status` costs about 0.1 s at 500 closed briefs, down from 8.7–10.4 s. [fact-check: claim 28 — Verified executed]
- At 2000 closed briefs `--status` with one argument takes about 0.18 s, and 21 MB of closed-brief text adds no measurable time. [unverified — submitted as claim] (measured by this critic in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/performance/`, fixtures r2000 and big200)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-open-brief cost ~15–21 ms, 10.8 s at 503 open (row 266's residue; trigger now conservative) | Informational | `scripts/build-loop.sh:307-312` | High |
| 2 | The 20b fail-open fix must not fall back to a full scan | Informational | `scripts/build-loop.sh:306` | Medium |

## Overall Assessment

4dc84ce4 resolves iteration 2's A15/X1 under default config. `--status` no longer depends on the number of closed briefs (0.08–0.18 s at 0–2000 for one argument, 0.13–0.30 s for three), down from c143b929's 10.7 s at 500. Brief size does not matter either. The remaining scaling is linear-plus in the count of open briefs (about 0.6 s at 50, 10.8 s at 500), which row 266 already covers and which is bounded by the queue in practice. Rows 266, 267 and 269 hold again. No performance finding blocks the merge. The open item in this area is correctness, not cost: fact-check 20b's fail-open under forced colour or a git grep error. Its fix should force no colour and fail closed, not fall back to the old full scan.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: 4dc84ce4` first line.
- Answered: yes — A15/X1 measured as resolved; open-brief and large-file scaling measured; rows 266/267/269 hold
- Out of scope: the fail-open of F31 under forced colour or a git grep error (fact-check 20b): correctness and security, already escalated, noted only for its performance constraint (F2). check_brief's per-argument `git log -G` cost against main's history is U1a lib code, not re-measured.
- Escalate: nothing beyond the existing 20b escalation
- Decisions I made: compared against c143b929's scripts copied into my scratch dir; treated row 266 as covering the open-brief residue rather than re-filing it.
