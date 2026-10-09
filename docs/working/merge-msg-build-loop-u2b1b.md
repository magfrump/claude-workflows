Merge branch 'feat/build-loop-u2b1b': --check lists the merge's changed paths and applies the N rules; U2b1a2's carried reds R6, R7, R9 fixed

## What this does
`scripts/build-loop.sh --check` (the build-loop gate, advisory until U3's `--merge`) now judges the merge result, not only whether it merges. After each brief's verdict line it prints one line per path the merge changes against main (`diff-tree -r --no-renames --raw -z`, run in the gate's own repository): `path BRIEF S PATH` or `deny BRIEF S PATH: WHY`. The verdict is `ok BRIEF TIP TREE` only when nothing is denied, else `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)`.

The N rules, under both policies (plan D5):
1. `pathform` per path (an unprintable name shows as `?`) (F17).
2. Only modes 100644 and 100755 on either side: no symlink or gitlink lands, even under `submodule.<name>.ignore=all` (F7, F8).
3. The brief's own file may change only its first `Status:` line outside a fence, open to done, byte for byte with its mode kept (F13).
4. Compared lower-cased: the dev cycle's own files (truthrule's cycle and settings words, plus anything under `docs/working/briefs/` or `docs/working/cycles/`) and `docs/constraints.md` (F2, F12, F54).

It also fixes U2b1a2's carried known issues (Q-133 [3], override rows 507-511):
- **R6:** `gate_git` refuses any git stderr, and `merge_result` checks that the trees of main, the tip and every merge base exist (merge-tree read a missing top-level tree as an empty side and exited 0). A regular file naming a blob the store lacks is refused too: merge-tree passes it by id unread.
- **R7:** `default_gate` refuses both main and master present, or origin/HEAD naming a branch other than the one taken.
- **R9:** the submodule test keeps its base gitlink, and a new test merges a gitlink fast-forward that the real repository resolves cleanly.
- **A15-A19:** an order test with a git call log, diff-tree in the gate repository (A16), `GIT_CONFIG_NOSYSTEM=1` (A17), and help and comment drift.

R8 (a same-uid writer racing the gate's temp directory) is a Q-103 residual (row 509; plan step 13 lists it for U5).

**Workflow provenance:** RPI (plan `docs/working/plan-build-loop-handoff.md`, step 5, U2b1b note) → pr-prep's review-fix loop.
← carried from RPI: D5's N rules under both policies and D7's merge-tree → diff-tree flow; the gate decides from main's commit and the exact merge result; honest path in scope, hostile same-uid loops to Q-103.
- Iteration 1 (k=1, full panel, 809df345): no red; 5 ambers (the cycle-file rule defined three times, a stale contract item, wording, test gaps) and Lows (own_blob's exit status, missing blobs, a tr per path) fixed in a382a3f8.
- Iteration 2 (k=1, fix range): no red; wording, the truthrule-order invariant and a default_gate test, fixed in e02d056b.
- Iteration 3, the final pass (k=3, full panel, Stage 2.5, e02d056b): no red. Its ambers were test and doc text, fixed in e14773a3 (unreviewed; the lite fix-drift check found nothing). The A15 test now pins its order: the mutant that moves state_gate after resolve_main fails it.

Review converged in 3 iterations (at the cap): 0 Must Fix found; every Must Address was fixed or acknowledged with an override row.

**Failures prevented:**
- a loop editing the roadmap, questions, another brief, its own brief beyond Status, or the constraints doc in a merge that reads ok;
- a symlink or gitlink landing;
- a missing object read as an empty side;
- a loop-made master taken as the default branch.

## Reviewer's path — start here
1. `scripts/build-loop.sh` `check_line`: collect (diff-tree), batch-check, lower, judge.
2. `nrules` and `own_blob`: the N rules and the own brief's Status rule.
3. `gate_git`, `merge_result`, `default_gate`: the R6 and R7 fixes.
4. `test/scripts/build-loop-check.bats`, the tests tagged U2b1b.

## Status
- **Done:** U2b1 (the frame, the changed paths and the N rules).
- **Next:** U2b2 (the gate's checkout: contract items 2-4), U2b3 (the reader model), U2c (the S rules).
- **Blocked-on:** nothing.

## How to test
`TMPDIR=$(mktemp -d) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`: 202 ok (101 + 19 + 78 + 2 + 2). Named cases: T11 (rename), T12 (modes, ignore=all), T13 (path form), T14 (cycle files in any case), T15 (own brief), R6, R7 (both findings), R9, A15 (call order). `scripts/health-check.sh` passes on the branch.

## Areas of uncertainty
- The mode rule is N, so a reviewed symlink or gitlink cannot merge through the gate; pathform as an N rule refuses `.github/` and `.gitattributes` changes under review too. Both follow the plan (rev 2's T12, D3's stop list), decided without a fresh ask.
- The briefs/ and cycles/ subtree denial is wider than plan F12 stated; it fails safe.
- Known and deferred, with rows: a directory planted at a missing cycle file's name prints ok (fails closed; U2c); check_line returns text, not values (U3); the NUL-count check, single R6 guards and A16's single guards are not separately pinned; two refusals name the wrong cause under a git warning.
- e14773a3's test and wording changes were reviewed only by the lite check and the suites.

## Decisions made
Decision-log rows: none new. Override rows dated 2026-10-08 for `feat/build-loop-u2b1b`; R8 decided a Q-103 residual (row 509).

Decisions referenced: none — change is independent of recorded decisions (it builds the plan's D5/D7, not a decision record).

## Review evidence
- `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1b.md`: the rubric, all three iterations, loop closed at e02d056b.
- `docs/reviews/code-fact-check-report-build-loop-u2b1b{,-i2,-final}.md` (with `-final-r1..r3` and the submitted claims): fact-checks.
- `docs/reviews/{security-reviewer,performance-reviewer,api-consistency-reviewer,architecture-review}-review-2026-10-08-build-loop-u2b1b{,-i2,-final}.md`: critics.

Confidence: high
Notes: merged after the user's answer to its questions entry.
