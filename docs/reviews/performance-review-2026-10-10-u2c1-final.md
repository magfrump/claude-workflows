Commit: 9e7c61c5

# Performance Review — feat/build-loop-u2c1 (U2c1, final confirming pass, full branch)

**Scope:** `git diff main...HEAD` at 9e7c61c5 (eddfd5f9, d435100e, cf7dd447, 9e7c61c5): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md, the 2026-10-10 override-log rows
**Date:** 2026-10-10
**Based on:** the final-pass fact-check summary (replicates code-fact-check-report-build-loop-u2c1-final-r1/-r2/-r3.md), my iteration-1 report (performance-review-2026-10-10-u2c1.md), override rows 610 and 611

Measurements (scratch dir `S=/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-final-perf`; fixtures under `mktemp -d /tmp/u2c1-fperf-XXXX`, removed on exit; load average 0.23-0.50):
- `$S/probe.sh N`: the iteration-1 fixture (3,000 files, CLAUDE.md importing two files, a self-merge brief with `Paths: src/`, a branch adding N files under src/), with main's build-loop.sh ("base") and 9e7c61c5's ("head") timed on the same fixture, twice each. Output is in `$S/run-flat.txt`.
- `$S/micro.sh`: 9e7c61c5's lib sourced. It times 400 calls each of `need_root` and `floor`, counts the `need_root` calls in one cached `floor` call, and times `floor` again with `need_root` stubbed. Output is in `$S/run-micro.txt`.

| N changed paths | base (main) | head (9e7c61c5) |
|---|---|---|
| 1 | 0.25 s, 0.26 s | 0.58 s, 0.59 s |
| 150 | 0.29 s, 0.29 s | 1.60 s, 2.76 s (second sample is an outlier; i1 gave 1.50/1.56) |
| 400 | 0.34 s, 0.34 s | 3.29 s, 3.25 s |

That is about 6.7 ms per path ((3.27 − 0.585) / 399), against 6.4 ms at eddfd5f9. The fact-check replicates measured 0.47/1.42/3.03 s. The basis of row 610's deferral has not changed.

## Data Flow and Hot Paths

`--check` is a CLI gate that runs once per merge decision, so it is a cold path. It has two multipliers. The first is the briefs passed to one run: each self-merge brief costs one `checkout_gate` (about 0.3 s), one `brief_fields` re-read (`scripts/build-loop.sh:817`) and, once a path reaches `truthwalk`, one full import walk after `import_reset` (`:773`). That walk is 0.33 s on the fixture and 2 to 3.5 s on /workspace per the plan. Main's `--check` never walked, so this per-brief walk is new with U2c1. Contract item 4 requires it, and it is skipped when no path reaches the walk or when `co` is set. The second multiplier is the changed paths per brief: `nrules`, its prefix loop, then `srules` (`:658`), which runs `floor`, a loop over `NEVER_RES`, `ownfile`, and a loop over `PATHS`. Changes since iteration 1 add no per-path work: `list_entries` (`:364`) runs once per brief, and so does the re-read. `never_res` (`:850`) runs once per run. Output now goes to `$GATE_TMP/line`, then through `cat` and `head` (`:858`), which is two forks per brief. `local -x LC_ALL=C` (`:771`) only changes the locale of children.

## Findings

#### Row 610 undercounts need_root: one cached floor call runs it 4 times, about 2.2 ms of floor's 6.0 ms per path, not twice

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:610`, `scripts/lib/dev-cycle-read.sh:1829`, `scripts/lib/dev-cycle-read.sh:1630`, `scripts/lib/dev-cycle-read.sh:1756`
**Move:** Count the hidden multiplications
**Classification:** Micro (a `$(pwd -P)` fork per call) / Cold path (a CLI gate per merge decision), multiplied by the changed-path count
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** `floor` 6,007 µs per call and `need_root` 476 µs per call. With `need_root` stubbed, `floor` drops to 3,834 µs. One cached `floor` call runs `need_root` 4 times. Source: `$S/run-micro.txt`, 9e7c61c5, 2026-10-10.

Evidence (verbatim):
```
# docs/reviews/override-log.md:610
| floor forks twice per path to lower-case it and runs need_root twice, ~5.7 ms of the S rules' ~6.4 ms per path; ...
# scripts/lib/dev-cycle-read.sh:1827-1830 (floor; continues to :1849, where truthwalk main is reached at :1844)
floor() {
  local lp
  need_root
# scripts/lib/dev-cycle-read.sh:1630 (main_imports; runs before its cache check at :1632)
  need_root
# scripts/lib/dev-cycle-read.sh:1754-1759 (isimported; continues to :1763)
isimported() {
  local lp
  need_root
  lp="$(lower "$2")" || return 0
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
```
The path for a passing changed path is `floor` → `need_root` (1), then `truthwalk main` → `main_imports` → `need_root` (2, before the cache hit), then `isimported` → `need_root` (3) → `main_imports` → `need_root` (4). Fact-check r1 reports the same count. Stubbing `need_root` removes 2.17 ms of 6.0 ms, about 36 %. Row 610 (and my iteration-1 finding, which it copied) says twice, which halves this share. The deferral and its revisit trigger are still right: "one root check per decision" removes all four calls. But a U2c2 fix that hoists only floor's own `need_root`, or only feeds floor the lowered path, would leave about 1.4 ms per path in `main_imports` and `isimported`.

**Recommendation:** When U2c2 picks up row 610, size the root-check part at four calls (about 2 ms per path here). Move `main_imports`' `need_root` below its cache check, or give the per-path entry no root check at all, so a cache hit costs no fork. Row 610 can be corrected in place or noted in U2c2's brief.

## Endorsements

- U2c1's additions since iteration 1 add no per-path forks. `list_entries` and the `brief_fields` re-read run once per self-merge brief, before the path loop. `never_res` runs once per run, after `read_settings`. The new output plumbing forks `cat` and `head` once per brief. [read: scripts/build-loop.sh:364-378, scripts/build-loop.sh:815-818, scripts/build-loop.sh:850, scripts/build-loop.sh:858-859]
- Per-path cost is unchanged from iteration 1 within noise (6.7 ms against 6.4 ms per path at 400 paths) and still linear in changed paths. [unverified — submitted as claim; evidence: `$S/run-flat.txt` against the i1 `run-flat.txt`; fact-check replicates 0.47/1.42/3.03 s]
- check_line in the parent shell keeps one walk per self-merge brief: `import_reset` resets it, and the cache serves that brief's paths. Fact-check reports the import_reset mutant as caught. [unverified — submitted as claim; evidence: final fc summary "mutants for import_reset … each caught"; the i1 fact-check's executed Claims 12/16]
- srules' never-glob loop is O(globs) regex tests per path with no forks, and the globs are bounded by one settings line. [read: scripts/build-loop.sh:658-669, scripts/build-loop.sh:637-649]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Row 610 says need_root runs twice per path. It runs 4 times, about 2.2 ms of floor's 6.0 ms, so a U2c2 fix must cover main_imports' and isimported's calls too | Informational | `docs/reviews/override-log.md:610`, `scripts/lib/dev-cycle-read.sh:1630,1756,1829` | High |

## Overall Assessment

The branch's performance posture is the same as at iteration 1. The S rules are linear in changed paths, and the walk is cached per decision. All per-brief and per-run work (list_entries, the re-read, NEVER_RES) sits outside the path loop. The roughly 6.5 ms per path for a self-merge brief is fork overhead in `floor`, already deferred to U2c2 by rows 610 and 611 with the trigger recorded in the plan. The only new point is a sizing correction to row 610: the root check accounts for about a third of floor's per-path cost, not a sixth, and it sits in three functions. Nothing blocks the merge. `--check` is a cold, per-merge path, and 400 paths cost about 2.7 s more than on main on this fixture.

## Goal-Alignment Note

- Success criterion (restated): a markdown report saved at the output path the dispatch names, structured per the skill, with every finding carrying verbatim Evidence and a path:line.
- Answered: yes. One Informational finding, with verbatim evidence, path:line and a measured baseline. Floor's per-path cost was not re-raised, because its basis is unchanged (re-measured at 6.7 ms per path). The finding only corrects row 610's attribution.
- Out of scope: the ownfile case issue (fact-check r3 Incorrect) is a correctness and security matter, not performance. /workspace-scale walk timing was not measured, since the fixture has no extra worktrees. No bats suites were run, because the fact-check reports them green.
- Escalate: none. Finding 1 feeds U2c2's sizing.
- Decisions I made: I reused the iteration-1 synthetic fixture so the base-vs-head deltas are comparable across passes. I treated the 2.76 s sample at 150 paths as an outlier, because its pair and the fact-check's run both sit near 1.5 s.
