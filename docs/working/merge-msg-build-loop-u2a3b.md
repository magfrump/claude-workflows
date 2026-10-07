Merge branch 'feat/build-loop-u2a3b': import_targets, the shared @-import parser that reads a superset of Claude Code's import grammar

## What this does
Adds `import_targets` to `scripts/lib/dev-cycle-read.sh`: one name parser shared by both import walks, `imported_names` (the tree walk behind `--check-fix`: an in-cycle fix never edits a file an instruction file imports) and `main_imports` (main's commit, for the self-merge gate's floor in U2a4). It reads a SUPERSET of the names Claude Code 2.1.292 can import, failing toward "imported": every `@` starts a candidate and every prefix of the run up to the first blank is a name, with escaped spaces, a comment splice, the U+FFFD spelling of invalid UTF-8 (python3, only when the text is ill-formed), `~/` against HOME as Bun reads it, and lexical resolution with `..` stopping at `/`. The claim and its five named exceptions are stated once, in the comment above `import_targets`. The parser has a per-file work bound, and each walk has an IMPORT_OUT_MAX output budget, so a pathological file fails the walk instead of stalling it. `--check-fix` now words the skip as "an instruction file names it after an @".

**Workflow provenance:** RPI (plan `docs/working/plan-build-loop-handoff.md`, step 5) → pr-prep: loop 1 hit the cap → over-approximate (the user's iteration-4 decision) → loop 2: iterations 1-3, an iteration-4 gate (Q-120 [1]: one more confirming pass under a size waiver), the confirming pass, Q-122 [1]: merge with the last fix commit unreviewed.

**Failures prevented:** an in-cycle fix or a self-merge editing a doc that Claude Code imports through a name shape the old finder missed (a code span, a link, an HTML comment, a `~/` or absolute path, invalid UTF-8, a Unicode space), which would then load unreviewed.

## Reviewer's path — start here
1. `scripts/lib/dev-cycle-read.sh`, the comment above `import_targets`: the superset claim, its rules, its exceptions, its failure list.
2. The two walk headers above `IMPORTED=`: what each walk starts from, skips and fails on.
3. `docs/working/known-issues-dev-cycle.md` A5, and plan step 5's U2a3c, U2a4 and U2b bullets: what is routed onward.
4. `test/scripts/build-loop-check.bats`: the parser and walk tests (50).

## Status
- **Done:** the shared parser, both walks on it, the bounds, the `--check-fix` wording.
- **Next:** U2a3c (`feat/build-loop-u2a3c`) rebases above this and applies its iteration-1 fixes; then U2a4 (floor, with one start predicate for both walks) and U2b (the reader model).
- **Blocked-on:** nothing.

## How to test
`TMPDIR=$(mktemp -d) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`: 151 ok (50 + 19 + 78 + 2 + 2). `test/hermeticity-lint.bats`: 53 ok. `scripts/health-check.sh` at the merge: see the merge commit's check.

Checked against Claude Code 2.1.292 itself: a 7,000-document fuzz with its extracted lexer (0 misses of 3,236 names), the binary run headless on 19 shapes, and in the last pass on HOME handling, nested `.git` files, invalid UTF-8 and outside-repo instruction files. `--check-fix` output is byte-identical to main over 957 paths, about 0.2 s slower per walk.

## Areas of uncertainty
- **Unreviewed:** c4b34dcf (the confirming pass's fixes). Its only code is the main walk's top-level `.git` rule: skip it only as a plain directory or a gitfile holding no `@`, otherwise fail. Nothing calls `main_imports` until U2a4, and U2a3c's loop reviews that code again. The rest is two tests, comments and plan routing. The user chose to merge (Q-122 [1]).
- **Size:** 841 changed code lines against main, past decision log row 62 / Q-104 [2]'s ~800, under the user's waiver (Q-120 [1]).
- **Routed, with override rows and revisit triggers:**
  - U2b's reader model: instruction files outside the repo (a parent directory's CLAUDE.md, the memory file); relative names re-entering another checkout; nested-root projection; the host checkout `/home/magfrump/claude-workflows` as the root's host spelling (Q-121, Q-123); walk cache keys.
  - U2a4's one start predicate: `.claude/rules/`, `.claude/commands/*.md`, outside-repo starts.
  - U2a3c: a capped, drained reader for main's blobs; prefix-safe phase-2 fail rules; a blocker memo; a walk-wide work bound.
- **Known exceptions to the superset** (in the lib comment and A5): another home, another checkout, case-insensitive names, approved external includes, decoding beyond UTF-8's U+FFFD.
- **Revisit trigger:** a Claude Code upgrade that changes its import grammar, how its runtime reads an empty or unset HOME, or how it decodes invalid UTF-8.

Reviews: `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md` (every iteration) and its reports.

Confidence: medium
Notes: merged at the user's answer Q-122 [1], with c4b34dcf unreviewed.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01WEtozsannL4Sx8FUSKRWHx
