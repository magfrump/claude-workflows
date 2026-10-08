Commit: 4ce2c6bf

# Test Strategy: U2a3c lite fix-drift check (Q-129 [1])

**Scope:** `git diff 83c69b48..4ce2c6bf -- test` (tests 65-68 in `test/scripts/build-loop-check.bats`), checked against the patch in `docs/reviews/test-strategy-review-2026-10-07-build-loop-u2a3c-confirm.md` Appendices A and B, including the hand edits (test 66's comment and timeout, test 68's title).
**Reviewed:** 2026-10-07
**Verdict:** no findings. Every new or changed test kills the mutant it targets, passes on HEAD under a 23- and an 83-character TMPDIR, and stays far inside its bound under CPU load. The hand edits introduced no regression.

Execution provenance: scratch copy `/tmp/u2a3c-lite-ts-rFSO` (`git archive 4ce2c6bf`), mutant libs `m_*.sh` beside it, and the load script `/tmp/u2a3c-lite-ts-rFSO-scripts/load66.sh`. TMPDIRs were `/tmp/u2a3c-lite-ts-t-XXXX` (23 characters) and `/tmp/u2a3c-lite-ts-long-aaaa…-XXXX` (83 characters), with `LC_ALL=C`. Load came from N `while :; do :; done` loops on 16 CPUs, killed by PID. The host was also busy with other sessions (load average 66 at the end). The worktree was not modified apart from this report.

## Test Conventions

The tests use bats ≥ 1.5 with a throwaway repo per test (`bl_setup`, `test/lib/build-loop-fixtures.bash`). A unit test of `main_checkout` runs in a child `bash -c` that sources `$LIB`, echoes `PATH CODE` lines and compares them with a literal. Cost guards are counted (xtrace, test 64), timed in one process as a ratio (test 67), or capped by `timeout` as hang guards (test 66, now 60 s).

## Results

### Mutation (all against the 4 "U2a3c final" tests, tests 65-68)

| Mutant | Change in scratch lib | Targeted by | Result |
|---|---|---|---|
| m_ea | `${mc_e@a}` (linear type check on ENT) | 67 | killed: ratio ×100 = 9911 against a bound of 1000. 65, 66 and 68 pass. |
| m_ma | `${mc_m@a}` (linear type check on MEMO) | 67 | killed: ratio ×100 = 7283. Test 66 passes at 60 s, as its new comment says (a hang guard only). |
| m_guard_below | PATH link/gitlink guard moved below `[[ -e "$c" \|\| -L "$c" ]] \|\| return 2` | 65 (new lx/gx rows) | killed: test 65 fails. 66-68 pass. |
| m_refuse_ent | refuse any PATH in ENT | 68 | killed: test 68 fails (b.md). 65-67 pass. |
| m_refuse_not644 | refuse every ENT mode but 100644 at PATH | 68 | killed: test 68 fails (the e.md 100755 row). 65-67 pass. |
| (HEAD lib) | none | all | 4/4 pass |

### TMPDIR length

On the HEAD lib, tests 65-68 pass 4/4 under the 23-character and the 83-character TMPDIR. Each set took 4.1 s wall time with the host near idle.

### Load

- **Test 67** (ratio ×100, best of 3, bound 1000): 95, 75, 62, 98 and 98 under 24 loops, and 57, 75 and 57 under 48 loops. That is 8/8 passes, with the worst value about 10× inside the bound. The comment's "0.4-1.0 here" agrees with these figures.
- **Test 66**, the timed region only (`timeout 60`): 8.6-11.3 s with no loops of mine (the host was busy with other sessions), 19.6 s under 24 loops and 23.5 s under 48. That leaves at least 2.5× headroom at the worst load measured. The old 20 s timeout would have gone red at 24 loops on today's host, so the hand edit to 60 s removes a flake. The whole bats test, setup included, took 47-55 s under 48 loops, but setup is outside the `timeout`.

### Hand edits against the original patch

- **Test 66:** the comment and timeout match Appendix B word for word.
- **Test 68:** the title changed from "as U2b's caller precondition allows" to "pinned though U2b's precondition passes only paths main lacks". It agrees with the narrowed U2b bullet in `docs/working/plan-build-loop-handoff.md` ("only a PATH main lacks …; a blob is answered by the checkout's shape, which only the clean-worktree duty makes safe"). The body is unchanged and still asserts `b.md 0` and `e.md 0`.
- **Test 65:** the added comment ("lx and gx … are absent there and answer 1 too") matches the assertion.

## Untested Paths Touched by the Change

None. The commit's lib diff (`scripts/lib/dev-cycle-read.sh`) changes only comment lines, so it adds no branch. The test diff closes G1-G3 of the confirming pass (the ENT/MEMO linear type check, the blob-PATH answer and its 100755 arm, and the guard's position for an absent link/gitlink PATH). This pass confirms each of those closures by mutation.

## Recommended Tests

None.

## What NOT to Test

- A directory at a PATH main stores as a blob. The confirming pass left this to the security/API decision, and the U2b bullet now records it as safe only under the clean-worktree duty. Pinning it would bless one answer before that decision is made.
- Tightening test 66's timeout back down. Test 67 is the host-independent pin for the `${x@a}` cost class, so 66 only needs to catch hangs.

## Coverage Gaps Beyond Current Scope

None new. The equivalent survivors from the confirming pass (A01, A13, A14, A16) touch lines this commit did not change.

## Summary

The three test changes from the earlier patch landed with their intent intact. Test 67 kills both linear type-check mutants with ratios of 73-99× against a bound of 10×, while HEAD stays at 0.57-0.98× under 1.5-3× CPU oversubscription. Test 65's new rows kill the guard-moved-below-existence mutant. Test 68 kills both the refuse-any-ENT-PATH and the refuse-all-but-100644 mutants. The hand edits (test 66's 60 s timeout and comment, test 68's title) match the patch or the narrowed U2b text and introduce no regression. The residual risk is test 66's headroom on a very loaded host: about 2.5× at the worst load measured. It is now only a hang guard.

## Goal-Alignment Note

- **Asked:** confirm that tests 65-68 still kill their target mutants, pass on HEAD under a short and a ≥ 70-character TMPDIR, and are not flaky under load, and report any regression from the hand edits.
- **Answered:** yes on all four. There are 5 mutants, each killed by exactly its target test. Both TMPDIRs pass 4/4. Test 67 passes 8/8 under 24 and 48 loops, and test 66 passes with at least 2.5× headroom. No regression was found.
- **Out of scope:** comment and doc wording beyond the test titles and comments (fact-check), and the directory-at-blob-PATH policy (security/API).
