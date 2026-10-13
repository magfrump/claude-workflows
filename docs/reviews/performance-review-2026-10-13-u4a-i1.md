Commit: 722c2e10

# Performance Review — feat/build-loop-u4a (U4a, review-fix loop i1)

**Scope:** `git diff main...HEAD` at 722c2e10: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-i1.md` (no Incorrect claims), shared brief `u4a-i1-brief.md`

## Data Flow and Hot Paths

- **`--land-cycle`** runs once per orchestrator iteration. Its steps:
  - It checks the branch, `EXPECT` and the index (`diff-index --cached`).
  - It runs `merge-base --is-ancestor`, then one `merge_result` (merge-tree), then one `store_check "$h" "$r"`.
  - It lists the merge with one `diff-tree MAIN_SHA R`, then runs `cycle_rules "$MAIN_SHA"` and `chore_record`.
  - It ends with `land cycle` (worktree scan, `commit-tree`, then a CAS or fast-forward).
  - **Path temperature: cold.** It runs once per iteration, with no latency-sensitive caller.
- **`--cycle-diff`** runs once per iteration. It is unchanged except that its rules are now `cycle_rules BASE`, which adds two rules:
  - a `lower` fork on every changed path;
  - for each changed brief, a blob read and an `asked` awk on each side. Before this diff, briefs fell through `*) continue` and were never read.
  - **Path temperature: cold.**
- **`--main-log`** runs `log_class` once per first-parent commit. That makes it the only per-item loop in the diff. Its chore branch now calls `chore_record`, which is the same loop and pipeline moved into a function.
- **Data sizes:** N is the number of paths the chore branch changes against BASE: the record, the roadmap, the idea log, the questions files and the briefs that step 6 touches.
  - The live repo has 3 briefs, 0 closed briefs and 1 cycle record (`ls /workspace/docs/working/{briefs,briefs/closed,cycles}`, 2026-10-13).
  - Under `--land-cycle`, `diff-tree MAIN_SHA R` lists only what HEAD brings that main lacks, so N stays near the chore's own set.
  - Every new per-item cost is linear in N. No new step is superlinear.

Measurements, all probes run 2026-10-13 under `/tmp/u4a-perf1-*` and removed afterwards:

- **M1:** `lower` vs `${p,,}` over 1000 paths, matched against `GATE_CODE`: 1270 ms vs 16 ms.
- **M2:** end to end on a single-branch clone of `/workspace` main (3485 tracked files), with one changed cycle record:
  - `--cycle-diff`: 345 ms
  - `--land-cycle`: 430 ms (landed)
  - `--state`: 351 ms
- **M3:** the same clone with NB briefs, each with its `Asked:` line extended:

| NB | `--cycle-diff` | `--land-cycle` | `--state` |
|---|---|---|---|
| 20 | 478 ms | 521 ms | 333 ms |
| 200 | 1800 ms | 2245 ms | 426 ms |

In M3, the land refused at `chore_record`, because the probe's seed had already put the record on main. That refusal comes after `cycle_rules` has run in full, so the timing still covers the rules.

## Findings

#### 1. `cycle_rules` forks `lower` (a subshell, a pipe and `tr`) for every changed path

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1878`
**Move:** Count the hidden multiplications
**Classification:** Micro (constant per-path fork overhead) / Cold path (once per orchestrator iteration)
**Confidence:** High
**Baseline:** 1.27 ms per path: 1270 ms for 1000 paths vs 16 ms with `${p,,}`, measured by probe M1 on 2026-10-13
**Legibility-target:** for-author

Evidence (verbatim):
```bash
    if [[ "$(lower "$p")" =~ $GATE_CODE ]]; then echo "refuse $p: the gate's own code; an in-cycle fix edits only docs --check-fix allows"; bad=1; continue; fi
```
`lower() { printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }` (`scripts/lib/dev-cycle-read.sh:917`).

The fork runs before every other branch of the loop body, so it costs about 1.3 ms for every listed path, briefs and ignored paths included. A realistic chore changes 1 to 10 paths, about 13 ms on a run whose fixed cost is about 350 ms (M2). It becomes visible only if a chore branch slips in a large unrelated change: 1000 paths would cost about 1.3 s, and the run would still be correct. The prior art in this file uses the same `lower` fork per item (`:884`, `:1163`), and its ASCII-only `tr` mapping is locale-independent by construction. Keeping it is therefore consistent.

**Recommendation:** No change needed at current N. If `--cycle-diff` ever runs per commit or per path at scale, note that the script already runs under `LC_ALL=C`, where `${p,,}` lower-cases only ASCII. That builtin would remove the fork, but only after confirming it matches `tr`'s mapping under every locale the script admits.

#### 2. Each changed brief now costs two `gate_git` blob reads and two `asked` awk subshells in `cycle_rules`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1879-1885`, `scripts/build-loop.sh:1867`
**Move:** Find the work that moved to the wrong place (newly added per-item reads)
**Classification:** Micro (fixed forks per brief) / Cold path (once per orchestrator iteration)
**Confidence:** High
**Baseline:** about 7.3 ms per changed brief under `--cycle-diff` ((1800 − 345) ms / 200) and about 9 ms per brief under `--land-cycle` ((2245 − 430) ms / 200), measured by probes M2 and M3 on 2026-10-13
**Legibility-target:** for-author

Evidence (verbatim):
```bash
      if ! cyc_blob "${RAW_OM[i]}" "${RAW_OO[i]}" "$t.o" || ! cyc_blob "${RAW_NM[i]}" "${RAW_NO[i]}" "$t.n"; then echo "refuse $p: a side is not a regular file (mode 100644), or could not be read"; bad=1; continue; fi
      [[ "${RAW_OM[i]}" == 000000 ]] || ao[${p##*/}]="$(asked "$t.o")"
      [[ "${RAW_NM[i]}" == 000000 ]] || { an[${p##*/}]="$(asked "$t.n")"; ap[${p##*/}]="$p"; }
```

Before this diff, briefs fell through `*) continue` and cost nothing. Now each changed brief costs:

- up to two `gate_git cat-file blob` calls, each a subshell, `cd`, `env` and git;
- up to two `$(asked ...)` command substitutions, each running awk with `FENCE_AWK`.

The cost is linear in the number of changed briefs: about 20 briefs add about 130 ms, and 200 add about 1.5 s. The live repo holds 3 briefs, and step 6 touches only those with a new `Asked:` ID. At realistic N this is noise. The two arrays `ao`/`an` are keyed by base name and are bounded by N.

**Recommendation:** No change needed. If brief counts grow by orders of magnitude, a single `cat-file --batch` over every brief side, with one awk keyed by file, would replace the 4N forks. That is not worth the complexity at present sizes.

## Endorsements

- `land_cycle` computes the merge once: the tree that `merge_result` returns is the tree `cycle_rules` judges and the tree `commit-tree` writes, through `VERDICT[tree]="$r"`. No second merge-tree call is made. [fact-check: claim 14 — Verified]
- The `log_class` refactor adds no fork per `--main-log` commit. `chore_record` is an in-shell function call with the same `gate_git cat-file blob | awk` pipeline per candidate record that the inline loop ran. The name test is the fork-free bash regex `isrecord`. [read: scripts/build-loop.sh:1716-1726, scripts/build-loop.sh:1751-1754, scripts/lib/dev-cycle-read.sh:246]
- The `--land-cycle` run's total overhead over `--state`, including `store_check "$h" "$r"`, is about 80 ms on a repo of about 3.5k files. That is because `store_check` skips main's already re-hashed ids in `$GATE_TMP/main`. [unverified — submitted as claim: M2 measured 430 ms vs 351 ms on one run of one clone; the attribution to the skip list is from reading `store_check`, `scripts/build-loop.sh:1045-1082`, and was not isolated by a separate timing]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `lower` fork per changed path in `cycle_rules` | Informational | `scripts/build-loop.sh:1878` | High |
| 2 | Two blob reads and two `asked` awks per changed brief | Informational | `scripts/build-loop.sh:1879-1885` | High |

## Overall Assessment

The performance posture is sound. Both new modes, and the new rules in `--cycle-diff`, run once per orchestrator iteration on a chore diff of a handful of paths. All new per-item work is linear in that N, with fixed costs of about 1.3 ms per path and about 7 to 9 ms per brief (measured). End to end, `--land-cycle` took 430 ms on a clone of the real repo, against 351 ms for `--state` alone. The only per-commit loop, `--main-log`'s `log_class`, gains no fork from the refactor. Neither finding needs action before landing. Both are recorded so a future change that moves `cycle_rules` onto a per-commit or large-N path starts from the measured numbers.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** performance-review the diff of `feat/build-loop-u4a` against `main` (commit 722c2e10).
- **Success criterion (verbatim):** "a markdown report saved at the exact path your own prompt names, structured per your skill."
- **Alignment:** saved at `docs/reviews/performance-review-2026-10-13-u4a-i1.md` with first line `Commit: 722c2e10`, structured per `skills/performance-reviewer/SKILL.md`. Each finding gives a severity, location, verbatim evidence, confidence, measured baseline and legibility target. Endorsements carry evidence tags, and the one that is not verified is tagged `[unverified — submitted as claim]`. Probes ran only under `/tmp/u4a-perf1-*` and were removed afterwards; no build-loop process is left running. Nothing else in `/workspace` or the worktree was written.
