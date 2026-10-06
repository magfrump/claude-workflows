Commit: d07cc89c

# Architecture Review: feat/build-loop-u2a1 (iteration 3 of 3, final confirming pass)

**Scope:** `git diff main...HEAD` at d07cc89c (unit 6f624cdf; iteration-1 fixes d48f4645; iteration-2 fixes 91469367; review artifacts 706e0499, d07cc89c). In-scope code: `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`. Test layer read for one cross-cutting point (I1).
**Date:** 2026-10-06
**Based on:** Stage 1 code-fact-check k=3 at d07cc89c (`docs/reviews/code-fact-check-report-build-loop-u2a1-r{1,2,3}.md`), the rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md` (iterations 1-2), override-log rows 204, 228, 292, 306-330

**Scope check.** In scope under "Public APIs": the lib's caller contract gains the `badform` word, plus `entry_why` and `isclosed`, which are called from both scripts. Iteration 2 changed `entry_why`'s documented contract again (each word's use of `$2`) and the reason check_answer prints. The new suite `test/scripts/fixture-git-env.bats` and the two setup `unset` lines are test-only. They come under this lens only as a cross-cutting test-environment rule (I1). The split `&&` chains, the T7 comment and the plan/questions hunks are scoped exclusions.

**Trust-boundary scan.** `ls docs/reviews/security-review-*.md` matches files, but none covers this branch. This branch's security reports are named `security-reviewer-review-*` and fall outside the glob. This pass files no module-boundary finding under move 3, so the cross-reference is a no-op.

**Settled context, not re-filed:** row 322 (the shared read-as-truth subset, Defer to U2a2), row 323 (`anybrief`, Defer to U2b), row 324 (the floor's check order, Defer to U2a2), row 325 (subshell cost, Won't-Fix), row 327 (other suites, Defer), row 328 (setup cost, Won't-Fix), row 329 (untested word folding, Won't-Fix). 91469367 changes none of their premises. I1 below concerns the *mechanism* named in row 327's revisit trigger, not its claim; the argument is given there.

## Dependency Map

Direction is unchanged across all three iterations. `scripts/dev-cycle.sh` and `scripts/build-loop.sh` source `scripts/lib/dev-cycle-read.sh` from their own directory. The lib calls into neither script.

- `main_entry` (lib:263-280) answers `blob` / `absent` / `notfile` / `notdir PART` / `badform` / `error`, with main_by_name checked before pathform (lib:267-268). It has four callers: check_brief (lib:354), check_answer (lib:572), brief_fields (lib:316, which treats anything but `blob` as error) and build-loop.sh's main_file (:129).
- `entry_why` (lib:286-295) is pure: no git, no globals. Three callers send it every word except `blob`/`absent`. check_brief passes `""` (lib:358). check_answer (lib:576) and main_file (build-loop.sh:133) pass `$f`.
- `isclosed` (lib:158) is built on `isbrief`. Its callers are writable (lib:161), check_brief (lib:348) and shared_branches (build-loop.sh:318).
- Test layer: `test/lib/build-loop-fixtures.bash` (bl_setup) and `test/scripts/dev-cycle.bats` setup() each carry their own copy of the hermetic git environment. `test/scripts/fixture-git-env.bats` depends on both suites by test-name filter (`bats -f`). `test/lib/hermetic-env.bash` is an existing shared test-environment lib that neither of these suites loads.

91469367 adds no cycle, module, production function or edge.

## Iteration-2 fixes, checked through this lens

| Fix | Structural effect | Status |
|---|---|---|
| A7 (iteration-2 architecture F1): entry_why's comment states each word's use of `$2`; check_answer ends every refusal "so no entry in `$f` is read" | The fix applies both options from the iteration-2 report. check_answer's `notdir` special case is gone (lib:574-577 now has one catch-all arm), so check_answer no longer needs to know which reason names which path. A new main_entry word now needs one edit, in entry_why. The cost is that `$f` is named twice in the notfile/error lines, which A4 had avoided. That is wording, not structure. | F1 resolved; nothing new |
| A8: `${2-}` | Local to entry_why. | Nothing new |
| A12: main_entry's guard order stated (lib:257-260) and pinned | The contract now says why a refused form answers `error` with no default branch, which rows 308/324's floor can rely on. | Nothing new |
| A10/A11: new tests (fixture-git-env.bats, isclosed's prefix) | Test-only. A11 pins the one guard that keeps `isclosed` from widening `writable`. See I1 for A10's placement. | I1 (Informational) |
| A13: header reflow, "skip messages" | Wording. | Not an architecture concern |

The fact-check's remaining entry_why comment gap (r3: with `$2` = "" the error and default arms also drop "for $2", which is stated only for notfile/badform) is a wording residue in the comment. It does not change the contract's shape, so it is not re-filed here.

## Findings

#### I1. The "clear git's repo-local variables" rule is copied per suite, and the deferral plans five more copies, while a shared test-environment lib already exists

**Severity:** Informational
**Location:** `test/lib/build-loop-fixtures.bash:11-15`, `test/scripts/dev-cycle.bats:11-13`, `test/scripts/fixture-git-env.bats:9-14`; prior art `test/lib/hermetic-env.bash:1-10`
**Move:** 2 (responsibility boundaries), 7 (coupling surface), prior art
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
test/lib/build-loop-fixtures.bash:14-16
    # shellcheck disable=SC2046  # word splitting is wanted: one name per line
    unset $(git rev-parse --local-env-vars)
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
```
```
test/scripts/dev-cycle.bats:11-14
    # As bl_setup: an inherited GIT_DIR would send fixture commits to that repo.
    # shellcheck disable=SC2046  # word splitting is wanted: one name per line
    unset $(git rev-parse --local-env-vars)
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
```
```
test/scripts/fixture-git-env.bats:9-13
setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    V="$BATS_TEST_TMPDIR/victim"
    git init -q -b main "$V"
```
```
test/lib/hermetic-env.bash:1-2
#!/usr/bin/env bash
# Shared test-environment pinning. Load from a suite with:
```
```
docs/reviews/override-log.md:327 (revisit trigger)
the next edit of any of those suites adds `unset $(git rev-parse --local-env-vars)` to its setup, and a test in test/scripts/fixture-git-env.bats.
```

The unit makes "fixtures never write through an inherited GIT_DIR" a rule for the test suite as a whole. It implements the rule by copying one line into each suite's setup. dev-cycle.bats says "As bl_setup", so it is coupled to bl_setup by a comment. Row 327 extends that mechanism: each of five more suites gets its own copy, plus a per-suite test in fixture-git-env.bats that names one of its tests with `-f`. The copy approach has already missed one file. fixture-git-env.bats, the suite written for this rule, does not clear the variables in its own setup, and fact-check r3 executed it with GIT_DIR at a victim: both of its tests fail and the victim goes from 1 to 3 commits. Meanwhile `test/lib/hermetic-env.bash` is the repo's existing "shared test-environment pinning" lib. One of row 327's suites, merge-safety.bats, already loads it (`load lib/hermetic-env`, :12). This is not a re-filing of row 327. That row's claim, that other suites are exposed, still stands and is still deferred. The point here is the revisit trigger's mechanism: spread the line N times, then test each copy. As it stands, the rule ends up with eight or more copies and one test per copy. A shared helper would give it one definition and one test of that definition, plus a cheap check that each suite loads it.

**Recommendation:** No change in this unit. When row 327 next fires, amend its trigger to "add a `pin_hermetic_git` (unset `--local-env-vars`, then the config/identity exports) to test/lib/hermetic-env.bash, and have bl_setup, dev-cycle.bats and fixture-git-env.bats call it". fixture-git-env.bats would then test the helper once rather than one test per suite.

## What Looks Good

Each row is a claim submitted for verification, not a certified result.

| Observation | Location | Status |
|---|---|---|
| After 91469367, check_answer has one catch-all refusal arm for every main_entry word but blob/absent. No caller now branches on a specific refusal word, so a new word needs one edit (entry_why) | lib:574-577; lib:356-359; build-loop.sh:130-134 | [unverified — submitted as claim]; fact-check executed: every caller refuses every word but blob/absent |
| entry_why's comment now states each word's use of `$2` (subject / "for $2" / ignored by notdir), so the special case iteration 2 flagged rests on a stated contract or is gone | lib:281-285 | [unverified — submitted as claim]; fact-check r3: the "" case is stated only for notfile/badform (Mostly accurate) |
| Dependency direction unchanged across all three iterations: no lib-to-script call, and entry_why and isclosed use no git and no globals | lib:158, :286-295 | route: code-fact-check |
| main_entry's contract states the guard order (main_by_name, then pathform) and that every word but blob/absent is a refusal, which gives rows 308/324's floor a stated rule to build on | lib:257-260, :267-268 | [unverified — submitted as claim]; fact-check executed: badform with 0 git calls; guard order pinned by a test line |
| `isclosed` is the single spelling of the closed/ rule across writable, check_brief and shared_branches, and its prefix guard is now pinned (A11) | lib:158, :161, :348; build-loop.sh:318 | [unverified — submitted as claim]; fact-check executed: equal to the three old spellings (22-110 paths) |
| fixture-git-env.bats fails loudly if a filtered test is renamed (it requires `1..1` and `ok 1`), so its name coupling to the two suites cannot pass vacuously | test/scripts/fixture-git-env.bats:17-20 | [unverified — submitted as claim]; fact-check executed: each -f filter matches one test |

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| I1 | The repo-local-variable unset is copied per suite (two copies, plus a third suite that lacks it), and row 327's trigger plans five more, although test/lib/hermetic-env.bash already exists as the shared environment lib | Informational | `test/lib/build-loop-fixtures.bash:11-15`, `test/scripts/dev-cycle.bats:11-13`, `test/scripts/fixture-git-env.bats:9-14` | Medium |

## Overall Assessment

The branch maintains the system's structure and slightly improves it. main_entry has a closed, documented refusal vocabulary. entry_why is the one mapping its three callers share. Since 91469367, no caller special-cases a refusal word, which removes the coupling iteration 2 raised (F1). isclosed is the single closed/ rule. Iteration 2's fixes are correct through this lens and introduce nothing structural in production code. The only new point is Informational and in the test layer: the hermetic-git rule is spread by copying, and the deferred plan in row 327 would multiply the copies even though a shared test-environment lib already exists. 0 Structural, 0 Coupling, 0 Minor, 1 Informational. Nothing blocks the merge.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-i3-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d07cc89c` as its first line.
- **Answered:** Saved as `docs/reviews/architecture-review-review-2026-10-06-i3-build-loop-u2a1.md`. Iteration 2's fixes (91469367) are structurally correct: they resolve iteration-2 F1 (A7) and add nothing new in production code. 0 Structural, 0 Coupling, 0 Minor, 1 Informational (I1, test layer).
- **Out of scope:** security, performance, wording and comment accuracy (fact-check's entry_why "" residue, plan :125, override row C1's line numbers), the split `&&` chains and the T7 comment. Settled rows 322-330 were not re-filed.
- **Escalate:** none.
- **Decisions:** I1 can be logged as an amendment to row 327's revisit trigger (route the unset through test/lib/hermetic-env.bash), or dropped. The orchestrator decides. fixture-git-env.bats's own missing unset is fact-check r3's executed item, and its disposition belongs to the rubric, not to this report.
