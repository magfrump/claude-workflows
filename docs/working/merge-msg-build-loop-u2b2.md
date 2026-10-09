Merge branch 'feat/build-loop-u2b2': --check refuses a self-merge brief unless it runs from a clean checkout of main's commit (gate caller contract items 2-4)

## What this does
`scripts/build-loop.sh --check` now judges the checkout a self-merge brief's floor walk (U2c) will read. For each brief that `--status` reads as self-merge, `checkout_gate` runs inside `check_line` once the merge's paths are read and before the N rules. When the checkout fails, the verdict line is `refuse BRIEF: a self-merge brief needs --check run from a clean checkout of the default branch's commit; WHY`. The path and deny lines still follow it, so a loop's advisory run from its own branch learns them. A review brief does not read the checkout.

The checkout is refused when:
1. Its HEAD is not MAIN_SHA.
2. A repo-local git variable is set (GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_CONFIG...). The exemptions are the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX. `callervar` is one rule, now shared with `gate_repo`, which no longer keeps GIT_CONFIG.
3. `core.symlinks` is false, or `core.ignoreCase` or `core.sparseCheckout` is true.
4. An index entry is skip-worktree, assume-unchanged or unmerged (git status skips the first two).
5. git status shows a change, fails or warns. Untracked and ignored files are allowed, since the walk reads them as they are.
6. There is an untracked nested repository, or a gitlink path that holds files, is a symlink or cannot be listed (rows 366, 373).
7. Item 3 is checked by its effect, not by `check-attr`. Every regular file main stores must hash, unfiltered, to main's blob, so a filter, working-tree-encoding, ident or eol conversion from any attributes source is refused. That includes the user's global ones, which harden hides from the gate's git. Names `hash-object --stdin-paths` would misread (a newline, a leading quote, a trailing CR) are refused. The check runs under the C locale, and a tree record it cannot parse is refused.

`check_line` calls `import_reset` first (item 4). The lib header's contract now says who owns each part of items 1-3: harden and the state gate, checkout_gate, the walk, and U2c's caller for LC_ALL=C.

**Workflow provenance:** RPI (plan `docs/working/plan-build-loop-handoff.md`, step 5, U2b2 note) → pr-prep's review-fix loop.
← carried from RPI: contract items 2-4 in the lib header; override rows 366, 373, 387, 391, 392, 397 and 439 named U2b as their trigger; a hostile same-uid loop is out of scope (Q-133 [3]).
- Iteration 1 (k=1, full panel, c10b972a): no red, nine ambers, fixed in 639f7b40. Security found three: a non-UTF-8 name skipped under a UTF-8 locale, quote and CR names, an unlistable gitlink. API-consistency and architecture found three: the advisory run lost its path lines, the check was once per run rather than final before the walk, and an empty CHECKOUT_WHY read the same whether it passed or never ran. The other three were the GIT_CONFIG trust rule written twice, docs, and reason wording.
- Iteration 2 (k=1, fix range): no red, and security had no finding. The order was documented wrong (fixed in 368a3194), and U2c's floor must not walk a refused checkout (fixed in 1f4f7a21).
- Iteration 3, the final pass (k=3, full panel, Stage 2.5, 1f4f7a21): no red. Five submitted claims were Verified (four executed: a global sparse checkout, autocrlf and a global-only ident attribute are all refused). The ambers were help and comment text plus one misleading reason: a newline name was refused as index bits. All fixed in a2cbd9c6, which is unreviewed; the lite fix-drift check's one finding was refuted.

Review converged in 3 iterations (at the cap): 0 Must Fix found. Every Must Address was fixed or acknowledged with an override row.

**Failures prevented:** a self-merge decision whose floor reads a checkout other than main's commit, whether through a dirty or detached checkout, an index flag hiding an edit, a sparse or case-insensitive checkout, an environment or config file redirect, a checkout conversion that rewrites what a session reads (an ident or eol attribute, a smudge filter, `core.symlinks=false`), or a nested repository whose instruction files no walk reads.

## Reviewer's path — start here
1. `scripts/build-loop.sh` `checkout_gate` (and `callervar` above `gate_repo`).
2. `check_line`: the `co` block and the verdict line.
3. The `--check` help text's checkout paragraph, and the lib header's contract items 2-3.
4. `test/scripts/build-loop-check.bats`: the five tests tagged U2b2, at the end of the file.

## Status
- **Done:** U2b2 (the gate's checkout).
- **Next:** U2b3 (the reader model), U2c (the S rules, floor's first caller; its bullet carries this unit's hand-off notes).
- **Blocked-on:** nothing.

## How to test
`TMPDIR=$(mktemp -d) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`: 207 ok (106 + 19 + 78 + 2 + 2). `scripts/health-check.sh` passes on the branch.

## Areas of uncertainty
- Decided without a fresh ask:
  - The effect check replaces the contract's check-attr wording. It refuses an eol=crlf checkout, which is benign, and passes an attribute that changes no bytes.
  - core.ignoreCase true is refused, failing closed.
  - The refusal is per self-merge brief, not a state-gate exit.
- The main /workspace checkout refuses every self-merge brief: its agent worktrees are untracked nested repositories. The orchestrator's own worktree (D13) is where --check runs.
- Each self-merge brief pays about 0.3 s here. That cost is linear in the briefs passed and in the tracked bytes (row 528).
- Green mutants are recorded in rows 529 and the new row: the gitlink `-L` check, the unparseable-record refusal, git status's stderr half, the LC_ALL export and import_reset.
- a2cbd9c6's newline-name fix and text were reviewed only by the lite check and the suites.

## Decisions made
Decision-log rows: none new. Override rows dated 2026-10-08 for `feat/build-loop-u2b2`.

Decisions referenced: none — the change builds the lib header's caller contract and the plan's U2b bullet, not a decision record.

## Review evidence
- `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md`: the rubric, all three iterations, loop closed at 1f4f7a21.
- `docs/reviews/code-fact-check-report-build-loop-u2b2{,-i2,-final}.md` (with `-final-r1..r3` and `code-fact-check-submitted-claims-build-loop-u2b2.md`): fact-checks.
- `docs/reviews/{security-reviewer,performance-reviewer,api-consistency-reviewer,architecture-review}-review-2026-10-08-build-loop-u2b2{,-i2,-final}.md`: critics.
- `docs/reviews/lite-review-build-loop-u2b2-final-fixes/`: the lite fix-drift check and its disposition.

Confidence: high
Notes: merged after the user's answer to its questions entry.
