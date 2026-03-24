# Performance Code Review

**Scope:** Branch `feat/r1-skill-output-schema-validation` vs `main` (15 files, 1027 lines added)
**Date:** 2026-03-24
**Fact-check input:** Stage 1 report (5 verified, 1 mostly accurate, 1 incorrect, 1 unverifiable)

## Data Flow and Hot Paths

This change adds BATS test files that validate Markdown report structure. The execution profile is:
- **Call frequency:** On-demand by developers running `bats test/skills/`. Not in production hot paths.
- **Data size:** Reports are typically 50-300 lines of Markdown. Helpers process these via shell pipes.
- **Execution environment:** Local developer machine or CI. Each test file runs independently.

The `setup()` function runs before every `@test` in a file, meaning `load_generic_report` (file read + `tr`) and `count_findings` (multiple `grep` + `sed` passes) execute repeatedly per test file.

## Findings

#### 1. Redundant file reads in setup()

**Severity:** Low
**Location:** `test/skills/helpers.bash:35-43, 50-53`
**Move:** #3 — Find the work that moved to the wrong place
**Confidence:** High

BATS calls `setup()` before every `@test`, which means `load_generic_report` reads the file and runs `tr -d '\r'` for each individual test. For a file with 15 tests, this is 15 file reads of the same report. Similarly, `count_findings` runs `grep` and `sed` against the full report content on each setup call.

In practice, the reports are small (<300 lines) and BATS test suites have <20 tests each, so the absolute cost is negligible (milliseconds). This is not a real performance problem at current scale.

**Recommendation:** No action needed at current scale. If test suites grow significantly, consider using `setup_file()` (BATS 1.5+) to load the report once per file instead of once per test. This is a minor optimization opportunity, not a bug.

#### 2. Multiple grep/sed passes over report content

**Severity:** Informational
**Location:** `test/skills/self-eval-format.bats:53-70`
**Move:** #1 — Count the hidden multiplications
**Confidence:** High

The self-eval format test has the most complex assertion logic, including `awk -F'|'` extraction, multiple `grep -E` passes, and `sed -n` section extraction. Each test runs independently, re-parsing the report. The self-eval test file has 17 tests, meaning ~17 parsing passes.

Again, the data is small enough that this is not a measurable issue. Noting for completeness.

**Recommendation:** No action needed. This is normal for BATS test structure.

## What Looks Good

- The `skip` early-exit in `load_generic_report` and `load_report` avoids all downstream processing when the report doesn't exist, preventing wasted work.
- `tr -d '\r'` is a single-pass stream filter, not a multi-pass regex operation. Appropriate for the task.
- No unbounded loops, no recursive operations, no quadratic patterns.
- The `|| true` pattern on `grep -c` calls prevents pipeline failures from triggering unnecessary error handling.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Redundant file reads in setup() | Low | `helpers.bash:35-43` | High |
| 2 | Multiple grep/sed passes per test | Informational | `self-eval-format.bats:53-70` | High |

## Overall Assessment

This change has no meaningful performance concerns. The code is test infrastructure that processes small Markdown files. The repeated file reads and grep passes are structurally inherent to BATS's per-test `setup()` pattern and do not warrant optimization at current scale. If the test suite grows to hundreds of tests per file or reports grow to thousands of lines, `setup_file()` would be the appropriate mitigation. No performance changes needed for merge.
