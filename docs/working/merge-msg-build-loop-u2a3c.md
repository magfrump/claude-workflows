Merge branch 'feat/build-loop-u2a3c': main_imports' checkout phase, so the gate's import walk reads a developer checkout instead of failing closed on it

## What this does
`main_imports` (scripts/lib/dev-cycle-read.sh), the gate's @-import walk, gains its checkout phase. Main's commit is walked to a fixpoint first. Then the checkout's start files main lacks (untracked, ignored, index-only) and the imported files main lacks are walked, and they can only add imports. Every such path passes one admission check, `main_checkout ENT MEMO PATH`, before it is marked seen. The check refuses:
- a path under a link or gitlink main stores;
- a path under a checkout ancestor that is not a plain searchable directory;
- main's link or gitlink at the path itself;
- anything at the path but a readable plain file, a plain directory, or nothing.

A checkout listing that git prints any stderr for also fails the walk. Before this unit the walk failed closed on any start file main lacks, so the gate needed a fresh worktree. /workspace's own checkout now walks: about 8,100 units of parser work and 1.4 s.

It also builds the items U2a3b's loop routed here:
- `capped_read`, one 4 MiB + 1 reader for checkout files and main's blobs. The drain is explicit at the blob arm, so `git cat-file` never dies of SIGPIPE under pipefail.
- `IMPORT_WORK_MAX`, a walk-wide bound on parser work. The parser reports its work in an opt-in `/N` trailer, and `import_work` charges it.
- `main_checkout`'s memo: bottom-up to the nearest decided ancestor, memoizing every result, with an O(1) `${x[0]@a}` type check.
- A top-level `.git` (a linked worktree's gitfile) is read as a checkout file.
- Link text over 4096 bytes fails before it is read.
- N1: `lower_all` runs under `nul_list`, so a `tr` that dies part-way fails the list.

**Workflow provenance:** RPI (plan `docs/working/plan-build-loop-handoff.md`, step 5, U2a3c bullet) → pr-prep's review-fix loop.
- Iteration 1 ran pre-rebase.
- The branch was rebuilt on main above U2a3b as one 3-way resolution (3e58eb9c); the old tip is kept as `backup/u2a3c-pre-rebase-2b1399ab`.
- Iteration 2, then a final pass that was not clean (fixed in 4b7f2357).
- Q-128 [1]: a confirming pass. It found no code defect but some doc and test findings.
- Q-129 [1]: docs and tests applied (4ce2c6bf), then a lite fix-drift check, which was clean (c8bd58c7).

**Failures prevented:** a gate that answers "not imported" for a file an untracked or ignored instruction file (CLAUDE.local.md, `.claude/rules/`) pulls in, so that a self-merge could edit it unreviewed. Also a gate that cannot run in a real checkout at all.

## Reviewer's path — start here
1. `scripts/lib/dev-cycle-read.sh`, the block comment above `IMPORTED=`: what the walk starts from, reads, refuses, and does not cover, and the cache rules.
2. `main_checkout` and its comment: the admission rules, return codes 0/1/2, the MEMO, and the precondition that a caller passes only a path main lacks.
3. `main_imports`: the two seedings, one drain loop, and the `checkout` arm.
4. The plan's U2b bullet: the four duties a caller owes the walk (a clean worktree at MAIN_SHA; a final checkout or a cleared `IMPORTED_MAIN_DONE`; empty `ls-files` stderr; the git environment, with `LC_ALL=C`).
5. `test/scripts/build-loop-check.bats`: 68 tests. The newest ones are a `main_checkout` shape table, a precondition test, a cost-ratio test and a many-token test.

## Status
- **Done:** the checkout phase, the carried U2a3b items, and the restored caller contract.
- **Next:** U2a4 (the floor, and one start predicate and one caller-contract statement for both walks), then U2b (`--check`, the reader model) and U2c.
- **Blocked-on:** nothing.

## How to test
`TMPDIR=$(mktemp -d) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`: 169 ok (68 + 19 + 78 + 2 + 2). This also passes under a TMPDIR over 70 characters. `scripts/health-check.sh` passed on the branch at c8bd58c7; see the merge commit's check.

## Areas of uncertainty
- **Size:** 329 changed code lines against main (lib 86, tests 243), under decision log row 62's ~400.
- **Deferred, with override rows and revisit triggers:**
  - The queue pop copies its array, so it is quadratic in admitted checkout files: 84 s against 41 s at 5,000 files. The same code is on main. Trigger: U2a4, or a walk past 30 s.
  - A deep token through directories the checkout holds costs about D³ in realpath. That is still faster than both older libs.
  - The drain and the scan of @-less lines are uncharged work.
  - The caller contract lives in two places (the lib comment and the U2b bullet), to be unified in U2a4.
  - The parse chain is written three times.
- **Carried to U2b:** the cache key ignores the checkout; a FIFO start is never listed; TOCTOU between admission and read; checkout conversions (attributes, `core.symlinks`); and the reader model.
- **Unverified against Claude Code:** whether it reads a gitfile at `@.git` as the walk does (the Q-126 host probe).
- **Process:**
  - The final pass's Fact-Check Gate was not paused (away mode; override row).
  - One review agent left 48 busy loops running for about 4.7 h. They held load near 50 and failed `install-host.bats` T69 (on main too) until they were killed by PID. T69 passes at normal load.

Reviews: `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3c.md` (iteration 1) and `code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md` (iteration 2, the final pass, the confirming pass, the lite check), with their reports.

Confidence: high
Notes: merged at the user's answer Q-129 [1], after a clean lite fix-drift check.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01WEtozsannL4Sx8FUSKRWHx
