Commit: 723c242 (A) / 1f36885 (B)

# Performance Review — dev-cycle pass 17 (full-review fix round, k=1 delta)

**Scope:** Partial. A: `git diff 09f6fe7..723c242 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats`, in `/workspace/.claude/wt-digest`. B: `git diff 074164b..1f36885 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/working/seed-build-loop-handoff.md`, in `/workspace/.claude/wt-devcycle`. Everything else is context only.
**Date:** 2026-10-02
**Based on:** `/workspace/.claude/wt-devcycle/docs/reviews/code-fact-check-report-dev-cycle-full.md` (Stage-1 context; it covers bc5dc76, so it has no execution verdict on this round's lines) and `performance-review-2026-10-02-dev-cycle-full.md` finding 1, which this round fixes. That finding warned: "Check that its dates match the per-file ones on this repo before switching; history simplification at merges differs between pathspecs."

**Measurements** (all mine, 2026-10-02, this sandbox, git 2.39.5, mawk). Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf17/` (`perf17/` below). Scripts come from `git show 723c242:` (new) and `git show 09f6fe7:` (old), each with its own `questions.sh`.

The synthetic repo was built by `perf17/gen2.py` through `git fast-import` (2 min 11 s). It has 220,001 commits: 200,000 on the first-parent line, 20,000 of them merges, with dates spread over 9 years. It has 300 decision records with `## Revisit triggers`, created in the root commit, plus a 500-row log. Over history:
- about 198 direct edits to records on main;
- about 99 edits on merged side branches;
- 3 renames;
- **D1**: record 010 changed on both sides of a merge. The side's change is the newer one (`lb edit`, 2023-03-02), but the merge keeps main's older version (2023-02-26), so the merge is TREESAME to its first parent for that file.
- **E1**: an evil merge (2024-12-13) changes record 020 to content found in neither parent.

One record (`900-new.md`) was left uncommitted in the working tree. Skill files sit under `skills/sN/SKILL.md` and `skills/sN/ref/aK.md`.

| Run | Result |
|---|---|
| Isolated, 301 records: old per-record `git log -1` vs new one-walk map (`perf17/iso.sh`) | **no commit-graph: 167,734 ms vs 892 ms**; default graph (no Bloom): 83,509 vs 493 ms; Bloom (`--changed-paths`): 27,015 vs 199 ms (`perf17/iso-nograph.log`, `iso-graphnobloom.log`, `iso-bloom.log`) |
| Same, comparing dates (`%ad`) and exact commits (`%H`) for all 301 records | **2 differ, in every graph state**: 010 (D1) old 2023-02-26, new 2023-03-02; 020 (E1) old 2024-12-13, new 2017-10-04. Renamed (3), side-branch-only and uncommitted records match. |
| Full digest, `DEV_CYCLE_TODAY=2026-10-02`, old vs new (`perf17/full.sh`) | no graph: **177.5 s → 10.2 s**; Bloom: 32.2 s → 6.2 s. Both exit 0 (`perf17/full-nograph.log`, `full-bloom.log`) |
| `diff old new` of the full digests (`perf17/full-nograph.diff`, identical to `full-bloom.diff`) | 29 lines: section 2's new heading sentence, the two date lines above, and section 7's skill count 9 → 17 (8 `skills/sN/ref/*.md` added, list capped at 20) |
| New script per section, no graph, under `bash -x` (`perf17/sections-nograph-new.log`, 2 runs) | s1 2.97–3.07 s, **s2 3.38–3.54 s**, s5 0.84–0.89 s, s6 0.20–0.22 s, s7 1.02–1.08 s, total 8.5–8.8 s |
| Map variants (`perf17/map-variants.log`, `cc-compare.log`) | as shipped 997 ms; with `--cc` 968 ms, E1 then matches the old date (only D1 differs); with `-m` 1,060 ms, D1 and E1 both still wrong |
| Small repo, names containing `\`, `"`, TAB, LF, `é`, plus an uncommitted record (`perf17/names.diff`) | old and new agree except **`001-a\b.md` and `002-q"x.md`: old 2026-01-05, new "never, uncommitted"** |
| `timeout 600 bats test/scripts/dev-cycle.bats` at 723c242 (`perf17/bats.log`) | **24/24 ok**, 6.93 s wall. The brief says 23: the suite has 24 tests. |

The synthetic and small repos were made under `mktemp -d` and deleted. No probe processes remain (`pgrep` empty). Nothing was written to either worktree except this file.

Legibility-target values: **maintainer** (someone editing the script or tests), **agent** (the model running the skill), **user** (the human reading the digest).

## Data Flow and Hot Paths

A: `dev-cycle.sh` runs once per cycle as skill step 0, and at most once more with `--since`. Every path in it is **cold**. The escalation case from the full review still applies: the agent's Bash tool has a 120 s default timeout, and step 0 stops the cycle when the digest fails. Section 2 used to run one history walk per record, R × H. It now runs one path-limited walk, `scripts/dev-cycle.sh:211-216`, which costs O(H + R). The per-record loop at `:217-227` then does only fixed-cost forks (`realpath`, `grep`, `awk`, `sed`). On the 200k-commit repo, section 2 drops from about 167 s to about 3.4 s, and most of the 3.4 s is the 500-row log loop and per-record forks. The whole digest goes from 177.5 s to 10.2 s with no commit-graph. That removes the timeout cliff the full review measured (about 141 records at 200k commits). What remains scales with H in sections 1, 5 and 7 (about 5 s here; the full review's C2/C3, unchanged).

Section 7 (`:340-352`) runs the same git walk as before. Only the `grep` that picks skill files changed, and the list stays capped at 20 lines.

B adds no executable code. The path rule adds string checks per path the agent takes from repo text. Step 1 now runs `questions.sh archive` without a separate `index` (`archive` calls `cmd_index` itself, `scripts/questions.sh:393` at 1f36885), which saves one questions.sh run per cycle.

## Findings

#### 1. The one-walk map gives a different date from the per-record walk when a merge resolves a record

**Severity:** Low (correctness, outside the performance scale; graded by its consequence). Preconditions: a merge on the walked history that either (a) changes a decision record to content in neither parent (an evil merge, or a conflict resolved by hand, which is the same thing for that file), or (b) keeps one side's version of a record that the other side changed more recently.
**Location:** `scripts/dev-cycle.sh:211-216` (A, 723c242)
**Evidence (verbatim):** `git -c core.quotePath=false log --format='@%ad' --date=short --name-only -- docs/decisions \` / `| awk '/^@/ { d = substr($0, 2); next } NF && !seen[$0]++ { print $0 "\t" d }')`. The unit continues: `fi`, then the loop. `last_date` is first read at `:222` (`d="${last_date[$f]-}"`) and printed at `:225` (`echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"`). The comment at `:207-210` says the walk gives each record's last commit date: "the first date seen per path wins".
**Move:** Work that moved to the wrong place (from a per-file walk to a per-directory walk)
**Classification:** Macro fix with a semantic side effect / Cold path
**Confidence:** High (executed)
**Baseline:** 2 of 301 records differ on the 220,001-commit synthetic repo, in all three graph states, measured 2026-10-02 (`perf17/iso-*.log`, `perf17/full-nograph.diff`)
**Legibility-target:** user

`git log --name-only` lists no files for merge commits by default, so (a) an evil or hand-resolved merge never enters the map. E1's record shows its previous change (2017-10-04, the root) rather than the merge (2024-12-13). In this case the printed date is seven years stale for content that changed this cycle. With pathspec `docs/decisions`, history simplification keeps both parents of a merge whenever any record differs from each parent. So (b) a side-branch change the merge discarded is still seen, and it wins if it is newer. D1 shows 2023-03-02, the date of `lb edit`, whose content is not on main. The per-file walk follows only the TREESAME parent and gives 2023-02-26. In the case most likely here (two worktree branches edit one record, with a hand-resolved conflict), the error is usually a few days. The triggers are still printed in full. Only the date context is wrong. The commit message's "Output identical on this repo" is true as written. The brief's claim that the map gives "exactly what per-file `git log -1 -- f` gave … including … merge-only … names" is refuted by execution. No test covers the map.

**Recommendation:** Add `--cc` to the walk. It lists a merge's files that differ from every parent. It measured 968 ms against 997 ms, and it makes E1, and so every hand-resolved conflict, match the old date (`perf17/cc-compare.log`). Then either accept and comment the remaining case (b), or drop the claim of exact equivalence. Add one bats case with a conflicted merge on a record.

#### 2. Records whose names contain `\` or `"` print "never, uncommitted"

**Severity:** Low (correctness, outside the performance scale). Precondition: a decision record name containing a backslash or a double quote.
**Location:** `scripts/dev-cycle.sh:209-210`, `:223` (A, 723c242)
**Evidence (verbatim):** `# the map and falls back to its own lookup.` (the comment opens at `:209` with `A name git still quotes (a control character) misses`) and `[[ -n "$d" || "$f" != *[[:cntrl:]]* ]] || d="$(git log -1 --format=%ad --date=short -- "$f")"`. The unit continues to `:225`, where `d` is printed.
**Move:** Check the asymptotic behavior (a fallback that bounds the cheap path)
**Classification:** Micro / Cold
**Confidence:** High (executed)
**Baseline:** 2 of 7 names wrong in the small repo, measured 2026-10-02 (`perf17/names.diff`): `### docs/decisions/001-a\b.md (last committed on this branch: never, uncommitted)` and the same for `002-q"x.md`. The old script gives 2026-01-05 for both.
**Legibility-target:** maintainer

With `core.quotePath=false`, git still quotes names that contain `"` or `\`, not only control characters. Those names miss the map, and the fallback guard tests only `[[:cntrl:]]`, so it does not run for them. The TAB, LF and `é` names are handled correctly.

**Recommendation:** Widen the guard to `*[[:cntrl:]\\\"]*` and fix the comment. A fallback on every miss would also be correct, but it costs one full walk per never-committed record (about 0.55 s each at 200k commits with no graph). So widening the pattern is the cheaper fix.

#### 3. Section 7 now lists every file under skills/ and workflows/

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:342` (A, 723c242)
**Evidence (verbatim):** `skills_changed="$(printf '%s\n' "$changed" | grep -E '^"?(skills|workflows)/' || true)"`. The unit continues to `:345-352`, where the count is printed and the list capped by `sed -n '1,20s/^/    - /p'` plus `… N more`.
**Move:** Ask "what's the size of N?"
**Classification:** Micro / Cold
**Confidence:** High
**Baseline:** section 7 took 1.02–1.08 s on the 220,001-commit repo, and its skill count went from 9 to 17 for the same window (`perf17/sections-nograph-new.log`, `perf17/full-nograph.diff`)
**Legibility-target:** agent

The git walk (`:340-341`) is unchanged: its pathspec already covered `skills workflows`. Only the grep is wider. N is the number of distinct paths changed in the window, and the output stays capped at 20 lines. A cycle that touches a skill with many reference files reports a larger count. Step 4b's agent reads the count, not the full list, so its work does not grow with it.

**Recommendation:** None.

#### 4. The option parser and the two new skip checks

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:74-84`, `:387-388` (A, 723c242)
**Evidence (verbatim):** `need() { [[ -n "$2" ]] || { echo "$1 needs a value" >&2; exit 1; }; }` and `skipped docs/dev-cycle.md || true` / `skipdir docs/working/briefs || true`
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold (once per run, fixed depth)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** maintainer

`need` is a shell function and forks nothing. The two skip checks are each one fixed-depth `blocker` walk: a subshell plus up to 3 `realpath` forks. That is far below 1 ms against a 10 s (synthetic) or roughly 0.4 s (this repo, full review) digest.

**Recommendation:** None.

No finding at Medium or above.

## Endorsements (evidence-gated)

- A, section 2: the map removes the R × H cost. Isolated, 301 records take 167.7 s vs 0.89 s with no graph, and 27.0 s vs 0.20 s with Bloom. The full digest drops from 177.5 s to 10.2 s. This closes full-review finding 1 (the 120 s cliff at about 141 records). [read: /workspace/.claude/wt-digest/scripts/dev-cycle.sh:211-227] (timings: `perf17/iso-*.log`, `perf17/full-*.log`)
- A, section 2: the map holds one entry per distinct path ever under `docs/decisions` (304 here), so memory grows with records, not history. [read: /workspace/.claude/wt-digest/scripts/dev-cycle.sh:211-216]
- A, section 2: renamed, side-branch-only, never-committed, TAB, LF and non-ASCII names get the same date as the old per-file walk. [unverified — submitted as claim] (executed on the synthetic and small repos, `perf17/cc-compare.log`, `perf17/names.diff`; not a fact-check verdict)
- B, step 1: `questions.sh archive` reindexes by itself (`cmd_index` at the end of `cmd_archive`), so dropping the separate `index` run loses nothing. [read: /workspace/.claude/wt-devcycle/scripts/questions.sh:374-395]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Map date differs from the per-file walk at evil/hand-resolved merges and at merges that discard a newer side change (2/301 on the synthetic repo); `--cc` fixes the first at no cost | Low (correctness) | `scripts/dev-cycle.sh:211-216` | High |
| 2 | Names with `\` or `"` miss the map and the control-character-only fallback: "never, uncommitted" | Low (correctness) | `scripts/dev-cycle.sh:223` | High |
| 3 | Section 7 counts every skills/workflows file (9 → 17 here); same walk, output capped | Informational | `scripts/dev-cycle.sh:342` | High |
| 4 | Option parser and two new skip checks: fixed, negligible cost | Informational | `scripts/dev-cycle.sh:74-84, 387-388` | High |

## Overall Assessment

On performance, this round does what it set out to do. Section 2 is now O(H + R), measured at 0.9 s instead of 168 s for 301 records at 220k commits. The digest no longer comes near the 120 s tool timeout at that size: 10.2 s with no commit-graph, 6.2 s with Bloom. The section 7 change and the option and skip changes are fixed-cost. What the rewrite did not keep is exact output equivalence, which the brief claims and the full-review recommendation asked to check. Execution shows two date errors. One comes from merge handling, and `--cc` fixes most of it for free. The other comes from `\` and `"` names, which a one-pattern guard fixes. Both are Low and need preconditions this repo does not meet, but claim 1 as written is refuted, and the map has no test. I checked the map for hidden multiplication, memory growth and fallback cost, the section 7 grep for output growth, and B's archive/index change. Within this lens they are correct and complete. No further profiling is needed.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass17.md`, and its first line is `Commit: 723c242 (A) / 1f36885 (B)`. It follows the skill's structure: header, Data Flow, Findings with Baseline and Classification, evidence-tagged Endorsements, Summary Table and Overall Assessment. Each finding also carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. It serves the user goal (merge once a clean pass is reached) as follows. It adds no performance blocker. It reports two Low correctness divergences, each measured by execution with a one-line fix, which the loop should decide before it calls this pass clean.
