Commit: 2e711a7b

# Performance Review — feat/build-loop-u1b (U1b, iteration 4 of 4, final confirming pass)

**Scope:** `feat/build-loop-u1a...2e711a7b`: scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, override-log rows; focus on the iteration-4 fix diff 1d79ffef..2e711a7b
**Date:** 2026-10-05
**Based on:** Stage-1 fact-check summary in the shared context (replicates docs/reviews/code-fact-check-report-build-loop-u1b-r{1,2,3}.md, all Commit: 2e711a7b)

## Data Flow and Hot Paths

`build-loop.sh --settings` runs once per orchestrator decision (cold path: a CLI read, not a request handler or per-item loop). One run is: a scrub re-exec (`scrub_reexec`: child bash plus two perl filters), then `resolve_main` and `main_file`, which together make a fixed set of git calls, then one awk pass (FENCE_AWK + SETTINGS_AWK) over docs/dev-cycle.md read from main's commit, then a bash loop over at most three result lines and, for the never key, over the never list's entries.

Measured in my scratch repo (`/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/performance/repo`, git 2.39, this repo's own docs/dev-cycle.md committed on main, 36 lines / 2,007 bytes):

- Wall time per run: 17, 20, 21, 20, 26 ms (5 runs, `date +%s%N` around the call).
- Git processes per run (GIT_TRACE): 6, constant: `rev-parse --show-toplevel`, `symbolic-ref ... origin/HEAD`, `show-ref --verify`, `rev-parse --verify ...^{commit}`, one `ls-tree -t --full-tree` for `docs` and `docs/dev-cycle.md`, one `cat-file blob`.
- Scaling with file size (one awk pass, linear): 1.27 MB file → 39 ms; 5.11 MB file → 102 ms.

What iteration 4 changed on the run path, read in full (`scripts/build-loop.sh` header to :195, `read_settings` :133–:187, and the lib's `scrub`, `scrub_reexec`, `FENCE_AWK`, `main_entry`, `resolve_main`):

- `:68` exports one `GIT_CONFIG_KEY_n/VALUE_n` pair and bumps `GIT_CONFIG_COUNT` once per run, before any git call. Each of the 6 git processes reads one more config pair; no new process.
- `never_ok` now defaults empty and is set only in the two valid arms (`:171`, `:172`); a new `none` arm (`:160`) sets `parts=()` and skips the per-entry `globform` loop. No new loop, fork or git call.
- `-h` now uses `sed -n '2,/^[^#]/{/^#/p}'`: help only, reads the script file once.
- The lib's `local -; set -o pipefail` in `brief_fields`/`check_answer` arrived via U1a and is not on `--settings`'s path.

## Findings

No findings.

Settled rows re-checked for a changed premise at 2e711a7b, none changed:
- Row 236 (never list has no entry limit, ~24 µs per entry): the per-entry loop (`:162–:168`) is unchanged; the new `none` arm only removes work.
- Row 237 (4,096-byte scrub cut): `scrub` in the lib is unchanged and not in this unit.
- Row 258 (globform quadratic per entry): `globform` (`:120–:127`) is unchanged by 1d79ffef..2e711a7b. The fact-check's UNVERIFIABLE note on row 258's rationale ("a scrub-cut line is at most 4 KB": the cut is output-only, globform reads the full line) is a wording point on the row's reason, not a new cost; the row's own cost claim (~11 s on an 80 KB entry, fact-check r1 10.3 s, r3 22.2 s) still stands as recorded, and the entry is still the user's own committed settings line read once per run.

Caller-environment `GIT_CONFIG_COUNT` values (fact-check E1/E2: octal, non-numeric) are correctness/security matters, not cost: with `GIT_CONFIG_COUNT=5000` the run exited 1 ("Not inside a git repository") in 10 ms, so no amplification. Not raised here; owned by the security and api critics.

## Endorsements

- The `--settings` run makes a fixed 6 git process calls, independent of file size and never-list length (GIT_TRACE count on 2e711a7b in the scratch repo above). [unverified — submitted as claim]
- The settings file is read in one awk pass and the run scales linearly with file size (2 KB ≈ 20 ms, 1.27 MB ≈ 39 ms, 5.11 MB ≈ 102 ms, measured in the scratch repo). [unverified — submitted as claim]
- The `Self-merge never: none` arm (`:160`) sets an empty list without entering the globform loop. [read: scripts/build-loop.sh:155-173]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

Iteration 4 adds no performance cost that matters: one exported config pair and a fail-closed default flip, with no new process, loop or read. The command stays a cold-path CLI read at ~20 ms, with a constant 6 git calls and a single linear awk pass. The only super-linear path is still globform per entry (row 258), and its premise is unchanged. No profiling is needed before landing.

## Goal-Alignment Note

Success criterion (verbatim): "A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b."

This report is saved at `docs/reviews/performance-reviewer-review-2026-10-05-build-loop-u1b.md` with `Commit: 2e711a7b` first. It follows the performance-reviewer skill's structure (header, data flow, findings, endorsements, summary table, assessment). It covers the whole unit diff's run path and the iteration-4 fix diff, and re-checks settled rows 236, 237 and 258. The test files are not on any run path; they only set fixtures.
