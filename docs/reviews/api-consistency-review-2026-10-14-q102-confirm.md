Commit: 57f37e3

# API Consistency Review: feat/q102-parallel-gates, confirming pass (fix range 65c931e6..57f37e3a)

**Scope:** `git diff 65c931e6..57f37e3a`, excluding `docs/reviews/` artifacts other than `override-log.md`. The surfaces checked are the `HEALTH_CHECK_JOBS` env variable, its default, its documentation, the `@category` tags, and the pr-prep and archive text.
**Date:** 2026-10-14
**Based on:** shared review context `/home/node/.claude/jobs/00bcf178/tmp/shared2.md`; pass-1 report `docs/reviews/api-consistency-review-2026-10-14-q102.md`

> ⚠️ **No code fact-check report provided for this pass.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

## Baseline Conventions

- **health-check.sh environment variables.** Each variable is `HEALTH_CHECK_<NOUN or VERB_NOUN>`, all caps, documented in the header's `Environment:` block (`scripts/health-check.sh:11-45`) in a fixed shape: name, then what it does, then the default (`Defaults to ...`, or `Unset: ...`). On main the set is `HEALTH_CHECK_SKILLS_DIR`, `HEALTH_CHECK_SKIP_BATS`, `HEALTH_CHECK_RUN_TESTS`, `HEALTH_CHECK_LOCK_HELD` and `HEALTH_CHECK_LOCK_WAIT` (`git grep main -- scripts skills workflows hooks guides`). A variable belongs to the script that reads it. run-tests.sh's one variable is `RUN_TESTS_NOT_RUN_FILE` (`scripts/run-tests.sh:19`).
- **Bad env values.** These fail the gate by name, with a `fail` line that quotes the value. `HEALTH_CHECK_LOCK_WAIT` follows the same pattern: a grammar is checked, then the run either exits or fails.
- **Category tags.** `# @category fast|slow` is required in every `.bats` file (`scripts/run-tests.sh:3`). Its meaning is stated only at `scripts/run-tests.sh:23-24`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `HEALTH_CHECK_JOBS` | env var | `HEALTH_CHECK_LOCK_WAIT`, `HEALTH_CHECK_RUN_TESTS`, `HEALTH_CHECK_SKIP_BATS` | `scripts/health-check.sh:12-45` | Consistent. It has the script's prefix and a bare noun like `_LOCK_WAIT`, and it is documented in the same block and shape. The rename from `RUN_TESTS_JOBS` fixes pass 1's ownership finding: run-tests.sh never read that name. |
| `STUB_NPROC` (test helper input) | test env | `STUB_JOBS`, `STUB_FAST_RC`, `STUB_SLOW_RC` | `test/scripts/health-check.bats:187-216` | Consistent. Same `STUB_<THING>` shape as its siblings. |
| Test `--jobs 1 stays serial when bats' own parallel variables are inherited` | test name | `--jobs: a parallel run records a complete log ...`, `--jobs 8 ... needs GNU parallel` | `test/scripts/run-tests.bats:370-500` | Consistent. Same `--jobs ...` lead. |
| `@category slow` on `cc-isolated-functions.bats` and `build-loop-check.bats` | tag value | existing slow-tagged unit files `round-log-functions.bats`, `worktree-cleanup-functions.bats`, `cc-sni-proxy-unittest.bats` | `test/round-log-functions.bats:2`, `test/worktree-cleanup-functions.bats:2`, `test/cc-sni-proxy-unittest.bats:2` | Consistent with how the tag is used. It departs from the header's wording; see Finding 1. |

## Consumer contract trace

**`RUN_TESTS_JOBS`.** Commit 65c931e6 introduced it, and it was never on main. `git grep RUN_TESTS_JOBS main` finds only two prose mentions: `docs/roadmap.md:52`, which this branch deletes, and `docs/working/questions-archive.md:2508`, Q-102's original option row ("a `RUN_TESTS_JOBS`-style variable"). That row is the historical question text that the user answered. It is correctly left alone, and the Applied note at :2516 names `HEALTH_CHECK_JOBS`.

Outside `docs/reviews/`, no skill, workflow, guide or script names `RUN_TESTS_JOBS`. A search (`rg -n RUN_TESTS_JOBS -g '!docs/reviews/**' .`) returns only archive line 2508.

**The old default ("`--jobs 8`", "2.5 min").** Neither survives in `workflows/`, `skills/`, `guides/` or `scripts/`. A search for `7\.5 min|2\.5 min` hits only questions-archive.md:2509 (Q-102's option text, history).

- `workflows/pr-prep.md:331` now reads "`--jobs 8`, or nproc when lower", with the measured 140 s / 451 s figures.
- The test-only consumers strip ambient values with `env -u HEALTH_CHECK_JOBS` (`test/scripts/health-check.bats:212`, `:493`). That second one is new in this range and closes the ambient-leak path for the `RUN_TESTS_NOT_RUN_FILE` test.

## Findings

#### 1. The retag applies a per-file wall-time criterion that run-tests.sh's stated meaning of fast and slow does not contain

**Severity:** Minor
**Location:** `scripts/run-tests.sh:23-24`; `test/cc-isolated-functions.bats:2`; `test/scripts/build-loop-check.bats:2`
**Move:** Trace the consumer contract (documentation drift); establish the baseline
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

From `scripts/run-tests.sh:23-24`:

```
#   --fast    Run only fast tests (pure function tests, <1s each)
#   --slow    Run only slow tests (integration tests, script execution / file I/O)
```

From `test/cc-isolated-functions.bats:1-4` after the fix:

```
#!/usr/bin/env bats
# @category slow
# Unit tests for the central multi-project launcher (decision 016):
# devcontainer-config/cc-isolated.sh + the egress-profile composition in
```

From `docs/reviews/override-log.md:824` (in this range):

```
build-loop-check.bats and cc-isolated-functions.bats (85 s) moved to slow: the fast set is the early-fail pre-gate.
```

**build-loop-check.bats** fits the header's slow wording. Its header says "Each test builds a throwaway repo under $BATS_TEST_TMPDIR", which is file I/O.

**cc-isolated-functions.bats** fits only partly. It calls itself unit tests and averages about 0.49 s per test (84.9 s / 173 tests in pass 1). By the header's "<1s each" it is fast.

The actual reason for both moves is per-file wall time under `--jobs`. That reason appears only in the override log and the archive note, which are places a suite author choosing a tag will not read. The next author tagging a 150-test unit file by the header will tag it fast and recreate pass 1's F1.

Precedent softens this. Unit-style files were already slow-tagged before this branch (`round-log-functions.bats`: "Unit tests for JSON state management functions"; `cc-sni-proxy-unittest.bats`). The header's meaning was already loose. This branch adds a third, unstated criterion; it does not break a strict one.

**Recommendation:** Add one clause to `scripts/run-tests.sh:23`. For example: "fast: the early-fail pre-gate health-check runs first. Pure function tests, <1s each, and no file much over a minute in total; a longer file goes slow even if its tests are unit tests." Running files in parallel is the reason the per-file bound now matters.

#### 2. "nproc" is documented as the cap, but `nproc` also reads `OMP_NUM_THREADS` and `OMP_THREAD_LIMIT`, so an unrelated ambient variable can silently serialize the default gate

**Severity:** Informational
**Location:** `scripts/health-check.sh:27-29` (env doc) and `:413-418` (default)
**Move:** Verify the nullability contract (what "unset" resolves to); trace the consumer contract
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**

From `scripts/health-check.sh:413-418`:

```
    local jobs="${HEALTH_CHECK_JOBS:-}" cores
    if [[ -z "$jobs" ]]; then
        jobs=8
        cores="$(nproc 2>/dev/null || true)"
        [[ "$cores" =~ ^[1-9][0-9]*$ ]] && (( cores < jobs )) && jobs=$cores
    fi
```

Executed in this review on this host (`nproc --all` = 16):

```
$ OMP_NUM_THREADS=2 nproc
2
$ OMP_THREAD_LIMIT=3 nproc
3
```

The documented contract is "Unset or empty: 8, or nproc when that is lower" (:28-29). GNU `nproc` is not the core count. It reports CPUs available to the process: affinity, adjusted by the two OpenMP variables.

So a session that exports `OMP_NUM_THREADS=1`, which is common in numeric tooling, would run gate 5 serially with `HEALTH_CHECK_JOBS` unset. The output would give no sign of it beyond the runner's `--jobs 1` behaviour. Nothing in the repository sets these variables (`rg OMP_ scripts test/lib` is empty), so this is a latent surprise, not a live one.

**Recommendation:** Say "nproc (CPUs available to this process; honours OMP_NUM_THREADS)" in the header and pr-prep. Switching to `nproc --all` would avoid the OpenMP variables but would also ignore CPU affinity, which is the better reason for the cap, so the doc clause is the right fix. Optionally print the chosen N in the gate's pass line, so a serialized default is visible.

#### 3. The checks-list line says "at most nproc" without qualifying it to the default

**Severity:** Informational
**Location:** `scripts/health-check.sh:52-53`
**Move:** Look for the asymmetry (summary against full contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

From `scripts/health-check.sh:52-53`:

```
#   5. BATS tests pass: run-tests.sh --fast, then --slow only if fast is green,
#      both with --jobs $HEALTH_CHECK_JOBS (default 8, at most nproc)
```

From `test/scripts/health-check.bats` (new test in this range):

```
  # An explicit value is not capped.
  STUB_NPROC=4 STUB_JOBS=16 _run_check_bats
```

The parenthetical can be read as a cap on any value. The env block (:28-29) and the test say an explicit value is not capped.

**Recommendation:** "(default 8, or nproc when lower)", matching the env block and pr-prep.md:331 word for word.

## What Looks Good

- The rename to `HEALTH_CHECK_JOBS` gives the variable to the script that reads it. The header adds "Read here only: run-tests.sh run by hand stays serial unless given --jobs". That pre-empts the cross-script confusion pass 1 flagged. `[unverified — submitted as claim]`
- The empty-equals-unset semantics (`${HEALTH_CHECK_JOBS:-}`, tested with `STUB_JOBS=''`) match how the sibling `HEALTH_CHECK_SKIP_BATS` treats an empty value (anything but `1` is off). `[unverified — submitted as claim]`
- The failure message renamed with the variable (`HEALTH_CHECK_JOBS='$bad' is not 1 to 999 ...`) keeps the established "fail by name, quote the value" shape. The paired "keep the two regexes equal" comments in both scripts make the shared grammar a visible contract. `[unverified — submitted as claim]`
- No doc, skill, workflow or script outside history and `docs/reviews/` still names `RUN_TESTS_JOBS` or the old "`--jobs 8`, 2.5 min" default. The search is shown in the Consumer contract trace. `[unverified — submitted as claim]`
- Unsetting `BATS_NUMBER_OF_PARALLEL_JOBS` and `BATS_NO_PARALLELIZE_ACROSS_FILES` in run-tests.sh makes `--jobs` the runner's only parallelism input. The flag is then the whole contract, as its header documents. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Retag uses a per-file wall-time criterion that the fast/slow header (`<1s each`) does not state; cc-isolated-functions fits the header's fast | Minor | `scripts/run-tests.sh:23-24`; `test/cc-isolated-functions.bats:2` | High |
| 2 | `nproc` honours `OMP_NUM_THREADS`/`OMP_THREAD_LIMIT`; the documented "nproc" cap can silently serialize the default | Informational | `scripts/health-check.sh:27-29`, `:413-418` | High |
| 3 | Checks list "(default 8, at most nproc)" reads as a cap on explicit values | Informational | `scripts/health-check.sh:52-53` | High |

## Overall Assessment

The fix range resolves pass 1's API findings cleanly:

- **Rename.** `HEALTH_CHECK_JOBS` matches the `HEALTH_CHECK_*` header convention in name, placement and documentation shape.
- **No stale name left.** No consumer outside history still names `RUN_TESTS_JOBS`, and the variable never reached main, so the rename breaks no one.
- **Default documented consistently.** The nproc default is described the same way in the env block, the comment and pr-prep.

What remains is documentation precision. The fast/slow header has not caught up with the criterion the retag actually used (Finding 1, Minor). The "nproc" wording hides two edge cases (Findings 2 and 3, Informational). Each is a one-line edit with no consumer impact today.

## Goal-Alignment Note

The goal was to land Q-102 [1], parallel gates by default, as one reviewed unit. This range makes the override a correctly owned, correctly documented `HEALTH_CHECK_JOBS` and makes the default host-aware. None of the findings blocks landing.

Finding 1 is the one worth doing inside this unit. The retag is part of this unit, and without the header clause the next tagging decision will undo it. Findings 2 and 3 can ride along as wording edits or go to the next unit that touches health-check.sh's header.
