Merge branch 'feat/build-loop-u2a3': main_imports, the main-only commit-reading import walk, and isimported main

## What this does
Adds `main_imports` to `scripts/lib/dev-cycle-read.sh`: the `@`-import walk the self-merge gate's floor (plan F11, U2a4) uses to decide which files Claude Code would load as instructions. It reads the default branch's commit, not the working tree, starting at every instruction file main stores (any case) and every `.md` under a `.claude/rules/` directory at any depth. It follows imports into the files main stores, follows symlinks on main to the path their text names, and records an imported path main lacks without reading it. It fails closed (`IMPORTED_MAIN=error`, so `isimported main` answers "imported" for every path) on every shape it does not model. `nul_list` checks that a NUL listing came back whole; U2a3b will reuse it. Nothing calls the walk yet; U2a4's floor is its first consumer.

**Workflow provenance:** RPI (plan `docs/working/plan-build-loop-handoff.md`) → pr-prep: loop 1 hit the cap → split (the user's decision) → loop 2.
← carried from RPI: plan D5/F11's floor item 1 (files sessions load from the checkout, instruction files and their `@`-imports) is read from main's commit only (invariant: briefs, policy and answers come from main's commit), and the walk refuses what it does not model, as FENCE_AWK does.

**Failures prevented:** a loop self-merging a file that main's instruction files import (directly, through symlinks, through `.claude/rules/`), which would then load unreviewed.

## Reviewer's path — start here
1. `scripts/lib/dev-cycle-read.sh`, the block comment above `IMPORTED=` and `main_imports()`: what the walk models, what it refuses and why it fails closed on the checkout until U2a3c.
2. `docs/working/known-issues-dev-cycle.md` A5: what it does not cover (symlinked-directory starts, submodules, case folding, absolute imports, checkout conversions, three shapes untraced against Claude Code).
3. `test/scripts/build-loop-check.bats`: one test per refused shape, including crafted trees (`hash-object --literally`).

## Status
- **Done:** main-only walk, `isimported main`, `nul_list`, U2a2 iteration-2 rows B2-B6, B8, B10-B12, routed U2a3b items I2-C2/C3/C4.
- **In progress:** U2a3c (`feat/build-loop-u2a3c`): the checkout phase (untracked/index-only starts, imported paths main lacks), stacked above U2a3b, carrying test-strategy L3's patch.
- **Blocked-on:** nothing.

## How it works
Loop 1 kept finding shapes where checkout input slipped past a check placed at one producer, and hit the iteration-4 gate. The user chose **split** (2026-10-06, in session). U2a3 became the main-only walk, and the checkout reads moved to U2a3c. Until U2a3c lands the walk fails closed on the checkout: a start file main lacks (untracked, ignored or only in the index), a link in link text followed by `..`, or anything but a plain directory at an imported path main lacks fails the walk. The gate therefore needs a fresh worktree (U2b). Main's tree is checked whole first: a doubled name, a name that is also a directory of another listed name (crafted trees), a newline in a name, and unparsable records all fail it. Link text is checked a component at a time, and a path main lacks under a directory main stores as a symlink or gitlink fails.

## How to test
`TMPDIR=$(mktemp -d /tmp/x-XXXX) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` gives 115 ok. build-loop-check.bats has 17, among them:
- tree+symlink doubled name: test 17
- `..` after a link, and paths under a main link or gitlink: test 15
- untracked/ignored/index-only starts: tests 3, 11
- a 64 KiB import list and a 67 KB link under `ulimit -f 0`: test 10
- cache: test 16

`scripts/health-check.sh` at 96637a20: "All checks passed." (rc 0; output kept at /tmp/u2a3-hc-Svfo/health.txt). Its two advisory divergence warnings (the dev-cycle skill named in global-instructions but not AGENTS.md/GEMINI.md) do not involve this branch's files.

## Areas of uncertainty
- **Review convergence.** Loop 1 (3 iterations) hit the cap, and the iteration-4 decision was **split**. Loop 2: Review converged in 3 iterations; 1 Must Fix resolved, 3 Must Address acknowledged.
- **Acknowledged Must Address (override rows, with revisit triggers):**
  - `ident` and attributes from `$GIT_DIR/info/attributes` / `core.attributesFile` are checkout conversions the walk misses (TODO(U2b) in A5).
  - Test gaps: test 10's masked tree-listing refusal, no mixed-case import, the empty start list, the cache reset. The code is correct; test-strategy L3's checked patch is applied in U2a3c.
  - Wording in comments and test names, left for U2a3c.
- **Deferred to U2b:**
  - `working-tree-encoding`/`filter` attributes and `core.symlinks=false`.
  - Git hardening: replace refs, GIT_INDEX_FILE, fsmonitor, sparse checkout.
  - LC_ALL=C: a non-UTF-8 name fails closed under a UTF-8 locale.
  - The gate's checkout must be a fresh worktree until U2a3c: /workspace's own checkout fails the walk because of its 35 ignored instruction files.
- **Untraced against Claude Code (no host probe):**
  - `.claude/commands` references
  - a symlinked instruction file's base directory
  - an `@` token's `..` after a directory link
- **Cost:** about 0.45 s on this repo's main. Deep or huge trees are deferred to the B6 trigger.
- **Post-review commit:** a docs-only commit after the confirming pass (96637a20) adds the `ident` wording, at the coordinator's request.
- **Pre-mortem fallback (1c):** did not fire. The diff touches no auth/crypto/migration paths, and the code diff is 400 lines; the larger total is review docs.

## Decisions made
- Split at loop 1's gate (user, 2026-10-06), recorded in the rubric.
- Fail-closed interim on the checkout until U2a3c, because nothing calls the walk yet and the floor exists to refuse what it cannot model.

Decisions referenced: none — change is independent of recorded decisions (it implements plan D5/F11 and decision log 62's 400-line cap).

## Review evidence
- `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md`: both loops, the split decision, `Loop closed at 0bb98f27`.
- Fact-check:
  - `docs/reviews/code-fact-check-report-build-loop-u2a3{,-i2,-final,-L2,-L2-final,-L3-final}.md` with replicates `-f-r*`, `-L2f-r*`, `-L3-r*`
  - `docs/reviews/code-fact-check-submitted-claims-build-loop-u2a3.md`
- Critics: `docs/reviews/{security-reviewer,performance-reviewer,api-consistency-reviewer,architecture-review,test-strategy}-review-2026-10-06-{,final-,L2-,L2f-,L3-}build-loop-u2a3.md`
- Fix-drift: `docs/reviews/lite-review-fix-drift-build-loop-u2a3-*.txt`
- Override rows: dated 2026-10-06 for `feat/build-loop-u2a3` in `docs/reviews/override-log.md`.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DGYKgsyLZBthWFjZsfchfq
