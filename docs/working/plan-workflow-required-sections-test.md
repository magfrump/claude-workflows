# Plan: Workflow Required Sections Test

## Context
- 9 workflow .md files in `workflows/`
- Existing BATS tests use `grep -qE` for assertions and `$BATS_TEST_DIRNAME` for paths
- Current state of required sections:
  - 7/9 files have `## When to use` (missing: review-fix-loop.md, user-testing-workflow.md)
  - 7/9 files have `## Process` (missing: review-fix-loop.md, user-testing-workflow.md)
  - user-testing-workflow.md has `## Phase N:` numbered sections (counts as process)
  - review-fix-loop.md is reference material, lacks both sections

## Design
Single BATS test file: `test/workflow-required-sections.bats`

**File discovery:** `find` all `*.md` files in `workflows/` directory (resolved relative to `$BATS_TEST_DIRNAME`).

**Two checks per file, implemented as a single test that iterates:**
1. `## When to use` — `grep -q '^## When to use'`
2. Process section — `grep -qE '^## (Process|Phase [0-9]|Step [0-9])'` to match literal `## Process` or numbered phase/step headings

**Output:** On failure, print which file(s) are missing which section(s) for easy diagnosis.

**Structure:** One `@test` per check type, each iterating over all discovered files. This gives clear BATS output showing exactly which requirement failed. Alternatively, one test per file (dynamic) — but BATS doesn't support dynamic test generation cleanly. Best approach: two tests, each looping over files and collecting failures, then asserting no failures.

## Expected behavior
- Test will flag `review-fix-loop.md` as missing `## When to use` (legitimate finding)
- Test will flag `review-fix-loop.md` as missing process section (legitimate finding)
- All other files should pass
