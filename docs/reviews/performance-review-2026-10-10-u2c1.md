Commit: eddfd5f9

# Performance Review — feat/build-loop-u2c1 (U2c1, iteration 1)

**Scope:** `git diff main...HEAD` (eddfd5f9): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2c1.md (21 claims; Claims 8, 12, 16 used below), override-log rows 345 and 470

Measurements (scratch dir `S=/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-i1-perf`, fixtures under their own `mktemp -d /tmp/u2c1-perf-XXXX`, removed on exit; load average 0.15-0.54):
- `$S/probe.sh N [deep]`: a 3,000-file repo, CLAUDE.md importing two files, a self-merge brief with `Paths: src/`, a branch adding N files under src/. `--check` timed with main's build-loop.sh ("base") and eddfd5f9's ("head") on the same fixture, twice each. Output: `$S/run-flat.txt`, `$S/run-deep.txt`.
- `$S/micro.sh`, `$S/micro2.sh`: eddfd5f9's lib sourced, 400 calls per piece srules runs per path. Output: `$S/run-micro.txt`, `$S/run-micro2.txt`.

| N changed paths | base (main) | head (eddfd5f9) |
|---|---|---|
| 1 | 0.24 s, 0.25 s | 0.57 s, 0.59 s |
| 150 | 0.27 s, 0.26 s | 1.50 s, 1.56 s |
| 400 | 0.33 s, 0.33 s | 3.16 s, 3.13 s |
| 400, 8 directories deep | 0.34 s, 0.34 s | 4.65 s, 3.44 s |

## Data Flow and Hot Paths

`--check` is a CLI gate run once per merge decision (by a loop or by hand), so it is a cold path in the skill's sense. Inside one run, two loops are the multipliers: briefs passed to `--check` (each self-merge brief re-runs the import walk after `import_reset`: 0.33 s on the fixture, 2 to 3.5 s on /workspace per the lib's comment at `scripts/lib/dev-cycle-read.sh:780-786`), and changed paths per brief (`for i in "${!ps[@]}"`, `scripts/build-loop.sh:812-817`). U2c1 adds per path: nrules' prefix loop (both policies) and, for a self-merge brief, `srules`: `floor` (only when `co` is empty), a loop over `NEVER_RES`, `ownfile`, and a loop over `PATHS`. Per-brief additions: one `brief_fields` re-read and `paths_read` (`:800`). N is the merge's changed-path count: unbounded in principle, tens to a few hundred in practice (the author's runs went to 400).

On the fixture, main's N rules cost about 0.2 ms per path (0.24 s → 0.33 s over 399 paths). eddfd5f9 adds about 6.4 ms per path ((3.13 − 0.57) / 399), almost all of it inside `floor`.

## Findings

#### floor re-lowers each path with two forks and checks the root twice: about 5.7 ms per path, the cost check_line's batched lower was built to avoid; row 345's revisit trigger has fired

**Severity:** Low
**Location:** `scripts/build-loop.sh:654`, `scripts/lib/dev-cycle-read.sh:1828-1830`, `scripts/lib/dev-cycle-read.sh:1756-1757`, `scripts/lib/dev-cycle-read.sh:160-163`
**Move:** Find the work that moved to the wrong place; count the hidden multiplications
**Classification:** Micro (per-call fork and exec overhead) / Cold path (a CLI gate run per merge decision), multiplied by the changed-path count
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** 3.13 s for `--check` over 400 changed paths against 0.57 s for 1 (eddfd5f9, `$S/run-flat.txt`, 2026-10-10); `floor` alone 5,628-5,768 µs per call (`$S/run-micro.txt`, `$S/run-micro2.txt`)

Evidence (verbatim):
```bash
# scripts/build-loop.sh:810-811
  # One lower-casing pass for every path (a tr per path cost 1 to 2.5 ms each).
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: the paths the merge of $br changes could not be lower-cased"; return; fi
# scripts/build-loop.sh:654 (srules; $2 is the path as spelled, $3 its lower-cased spelling from lps)
  if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then DENY="$FLOOR_WHY"; return 0; fi
# scripts/lib/dev-cycle-read.sh:1828-1830 (floor; continues to :1849)
  need_root
  FLOOR_WHY=""
  lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
# scripts/lib/dev-cycle-read.sh:1756-1757 (isimported, reached through truthwalk main at :1844; continues to :1763)
  need_root
  lp="$(lower "$2")" || return 0
```
check_line already lower-cases every path in one pass, and its comment says why: a `tr` per path costs 1 to 2.5 ms. srules hands `floor` the original spelling (`$2`), so each passing path pays the per-path cost again, twice: `floor` lowers it (a `$(...)` subshell plus a `tr` exec) and `isimported` lowers the result again. `need_root` also runs twice, and each run forks for `$(pwd -P)`. Measured per call: `need_root` 404 µs, `lower` 1,162 µs, `isimported main` 2,605 µs, `floor` 5,768 µs (`$S/run-micro.txt`). With `lower` and `need_root` stubbed to no-ops, `floor` drops to 2,156 µs (`$S/run-micro2.txt`), and the remainder is mostly the two `$(lower …)` subshells still forking at the call sites. Membership itself costs 118 µs (next finding). So fork overhead is roughly 60 to 95 % of the S rules' per-path cost. It scales linearly with the changed paths: about +2.6 s at 400 paths here, which matches the author's +4.0 s from 1 to 400 paths on the 3,284-file clone. Row 345 deferred exactly this ("floor lower-cases the path and isimported lower-cases it again") with the revisit trigger "U2c measures --check over 100+ paths above 1 s". The author's own numbers (3.6 s → 6.1 s from 1 to 150 paths) and these (0.57 s → 1.50 s) both trip it. The plan routes the fix to U2c2 "if U2c1's measurement asks for it" (`docs/working/plan-build-loop-handoff.md:312`), but the commit message gives the timings without saying whether it does.

**Recommendation:** Record the answer: the trigger fired, so U2c2 takes it. In U2c2 the cheaper fix is fewer forks, not a membership set. For example, give floor and isimported a path-already-lower entry, which srules feeds from `${lps[$i]}` (truthrule's `case` word already refuses an upper-case letter, so a wrong caller fails closed). Also run need_root once per decision rather than per call, or compare `$PWD` before falling back to `pwd -P`. Keep the public `floor` lowering for other callers, as row 345 wanted. Expected saving: about 3.5 ms of the 5.7 ms per path.

#### Row 470's per-walk membership set is not what this measurement asks for at present list sizes

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1759`, `docs/working/plan-build-loop-handoff.md:312`
**Move:** Question the cache; ask "what's the size of N?"
**Classification:** Macro in list size (a glob scan per path) / Cold path
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** 118 µs per membership test against the fixture's 28,737-byte IMPORTED_MAIN; 42,792 µs per test against a 6,000,001-byte list (`$S/run-micro.txt`, `$S/run-micro2.txt`, 2026-10-10)

Evidence (verbatim):
```bash
# scripts/lib/dev-cycle-read.sh:1759
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
```
Plan line 312: "floor's per-path membership set (row 470) if U2c1's measurement asks for it". At a realistic walk list (the lib says /workspace's walks print about 6 KB, `:797`; the fixture's list is 28 KB with its second-channel names), the glob costs about 2 % of `floor`'s per-path time, so an associative set would save about 0.1 ms per path. It matters only for lists in the megabytes: 43 ms per path at 6 MB, as in row 470's 98 ms against 4.4 MB on that machine. IMPORT_OUT_MAX caps the list at 4,000,000 characters (`:798`), so the worst case is bounded at roughly 30 to 100 ms per path.

**Recommendation:** When U2c2 decides row 470, cite these two numbers. The set pays off only near the IMPORT_OUT_MAX cap, which a hostile or huge instruction tree reaches. Prioritise the fork removal above.

#### The commit's timings cannot separate the S rules' per-path cost from walk noise

**Severity:** Informational
**Location:** commit eddfd5f9 message ("Timing on a 3,284-file clone: 3.6 s for 1 path, 6.1 s for 150, 7.6 s for 400.")
**Move:** Check the asymptotic behavior, not just the constant
**Classification:** Measurement method / Cold path
**Confidence:** Medium
**Legibility-target:** for-author
**Baseline:** 3.6 s for 1 path on the 3,284-file clone (commit eddfd5f9 message; Unverifiable per fact-check Claim 19)

Evidence (verbatim): "3.6 s for 1 path, 6.1 s for 150, 7.6 s for 400." These imply 16.8 ms per path for the first 149 paths and 6.0 ms per path for the next 250. The cost is linear on the fixture (6.2 ms and 6.5 ms per path for the same two spans, `$S/run-flat.txt`), so the clone's first span probably carries walk variance: the lib's comment gives 2 to 3.5 s per walk on /workspace (`scripts/lib/dev-cycle-read.sh:780-781`), a spread larger than the path cost being measured. The 8-deep run also varied by 1.2 s between its two head samples (`$S/run-deep.txt`). With no base-version run on the same clone, a reader cannot tell what U2c1 added.

**Recommendation:** When U2c2 re-measures, time main's build-loop.sh and the branch's on the same clone and path set, with at least two samples each. Report the per-path delta (here 0.2 ms → 6.4 ms) rather than totals that include one walk.

## Endorsements

- The import walk runs once per self-merge decision, not once per path. check_line's `import_reset` at the top, now observable in the parent shell, resets the cache per brief, and floor's walk is cached across that brief's paths. [fact-check: Claim 12 and Claim 16 — Verified (executed: two worktree listings for two briefs; one when import_reset is deleted)]
- `NEVER_RES` is built once per run after `read_settings`, not per path or per brief. [fact-check: Claim 8 — Verified]
- nrules' new prefix loop forks nothing: each step is a parameter expansion plus `truthrule`, which calls only `isstart` (two regex tests) and `writable`/`anybrief` (regex tests). Measured at 56 µs per truthrule call (`$S/run-micro.txt`), so a review brief's added cost is about 0.06 ms per directory level per path. [read: scripts/build-loop.sh:601-604, scripts/lib/dev-cycle-read.sh:1777-1787, scripts/lib/dev-cycle-read.sh:663, scripts/lib/dev-cycle-read.sh:229-236]
- `brief_fields` and `paths_read` run once per self-merge brief, before the path loop, and the `PATHS` comparison in srules is O(entries) string tests with no forks. [read: scripts/build-loop.sh:800, scripts/build-loop.sh:612-628, scripts/build-loop.sh:660-662]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | floor re-lowers each path with two forks plus two `pwd -P` forks, about 5.7 ms per path; row 345's trigger fired | Low | `scripts/build-loop.sh:654`, `scripts/lib/dev-cycle-read.sh:1828-1830` | High |
| 2 | Row 470's membership set saves about 0.1 ms per path at present list sizes; it matters only near IMPORT_OUT_MAX | Informational | `scripts/lib/dev-cycle-read.sh:1759` | High |
| 3 | The commit's timings mix walk variance with path cost; no base comparison | Informational | commit eddfd5f9 message | Medium |

## Overall Assessment

The S rules' algorithm is fine. Everything is linear in changed paths, the walk is cached per decision, and the only per-run work (NEVER_RES, PATHS) is hoisted. The cost is a constant factor, about 6 ms per changed path for a self-merge brief, and nearly all of it is fork and exec overhead from `floor` re-lowering a path check_line already lowered and re-checking the root. That was row 345's deferred concern, and both the author's measurement and this one now trip its revisit trigger. No change is needed in U2c1. Only a recorded answer to the plan's "if U2c1's measurement asks for it" is missing. The measurement asks for fork removal in U2c2 (about 3.5 ms per path saved) more than for row 470's membership set (about 0.1 ms per path at realistic sizes). Nothing here blocks the merge: --check is a cold, per-merge CLI path, and 400 paths cost about 2.6 s extra.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. Three findings, each with a verbatim quote, a path:line and a measured baseline. Rows 345 and 470 were addressed with measurements: the base-vs-head end-to-end timing and per-component micro-timings.
- Out of scope: the 3,284-file clone itself (not available); /workspace-scale walk timings (the fixture has no extra worktrees or reader roots); the full bats suites.
- Escalate: Finding 1's "did the measurement ask for it" is a routing decision for U2c2. My recommendation is yes, as fork removal.
- Decisions I made: I measured on a synthetic 3,000-file fixture, not a clone of this repo, so the walk's absolute cost is lower than on /workspace. The per-path deltas are the comparable numbers.
