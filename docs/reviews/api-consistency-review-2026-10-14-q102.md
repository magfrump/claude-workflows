Commit: 65c931e

# API Consistency Review — feat/q102-parallel-gates (Q-102 [1])

**Scope:** `git diff main...HEAD` at 65c931e6. The public surface is one new environment variable, `RUN_TESTS_JOBS`, which only `scripts/health-check.sh` reads. Also reviewed: its header entry, the check-5 failure message, and every doc that describes the gate.
**Date:** 2026-10-14
**Based on:** Stage-1 merged code-fact-check (shared review context); `docs/reviews/code-fact-check-report-r2-q102.md`

## Baseline Conventions

- **The prefix names the script that reads the variable.** health-check.sh reads `HEALTH_CHECK_SKILLS_DIR`, `HEALTH_CHECK_SKIP_BATS`, `HEALTH_CHECK_RUN_TESTS`, `HEALTH_CHECK_LOCK_HELD` and `HEALTH_CHECK_LOCK_WAIT`, all documented in its `# Environment:` header block (`scripts/health-check.sh:11-44`). run-tests.sh reads `RUN_TESTS_NOT_RUN_FILE`, documented in its own header (`scripts/run-tests.sh:18-20`), and health-check.sh only *sets* it for the runner (`:420`, `:428`). questions.sh reads `QUESTIONS_LIVE`/`QUESTIONS_ARCHIVE` (`scripts/questions.sh:40,85`). health-check.sh passes those through, but questions.sh honours them when run alone too. dev-cycle.sh reads `DEV_CYCLE_TODAY` (`scripts/dev-cycle.sh:139`). In each case, a variable carrying another script's prefix is one that script itself reads.
- **Empty means unset.** Every sibling either defaults with `${VAR:-default}` (`HEALTH_CHECK_SKILLS_DIR`, `HEALTH_CHECK_RUN_TESTS`) or tests with `-n "${VAR:-}"` (`HEALTH_CHECK_LOCK_WAIT` at `:1139`, `RUN_TESTS_NOT_RUN_FILE`). None of their header entries says so explicitly.
- **Bad values are rejected with a red line naming the variable, and the run fails non-zero.** `HEALTH_CHECK_LOCK_WAIT` uses `[[ … =~ ^[0123456789]{1,7}$ ]] || { red "HEALTH_CHECK_LOCK_WAIT is not a plain number of seconds (…)"; exit 1; }` (`:1140`). It aborts the whole run because it is read before any check starts. run-tests.sh rejects a bad `--jobs` with `--jobs takes a number from 1 to 999, got: X` plus the usage text, and exits 2 (`scripts/run-tests.sh:141-150`). A failure that belongs to one check uses `fail` (`:83`). That marks the check ✗, sets FAIL=1 and lets the other checks run.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `RUN_TESTS_JOBS` | env var | `HEALTH_CHECK_LOCK_WAIT`, `HEALTH_CHECK_RUN_TESTS` (read by health-check.sh); `RUN_TESTS_NOT_RUN_FILE` (read by run-tests.sh) | `scripts/health-check.sh:11-44`, `scripts/run-tests.sh:18-20` | Inconsistent: it carries run-tests.sh's prefix, but only health-check.sh reads it (Finding 1) |
| `STUB_JOBS` | test-local env (bats helper) | `STUB_FAST_RC`, `STUB_SLOW_RC`, `STUB_LOG` | `test/scripts/health-check.bats:182-215` | Consistent: matches the helper's `STUB_*` family. Private to the suite |

## Findings

#### 1. `RUN_TESTS_JOBS` has the runner's prefix, but the runner ignores it

**Severity:** Inconsistent
**Location:** `scripts/health-check.sh:27-33`, `:408`; `workflows/pr-prep.md:331`
**Move:** 2 (naming against the grain), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Precedent: the env-var prefix names the script that reads it. `HEALTH_CHECK_*` is used in `scripts/health-check.sh:11-44`, `RUN_TESTS_NOT_RUN_FILE` in `scripts/run-tests.sh:18-20` (read at the runner's write), and `QUESTIONS_LIVE` in `scripts/questions.sh:40,85`.

Evidence: `local jobs="${RUN_TESTS_JOBS:-8}"` (`scripts/health-check.sh:408`). run-tests.sh sets its own default with `jobs=1` (`scripts/run-tests.sh:132`), and only the `--jobs)` case changes it (`:141-150`). Per fact-check claim 15, `rg RUN_TESTS_JOBS` finds no match in run-tests.sh. pr-prep says "`RUN_TESTS_JOBS=N` picks another N, and `RUN_TESTS_JOBS=1` runs serially" (`workflows/pr-prep.md:331`). The same diff then has to add "`scripts/run-tests.sh --failed`, which runs serially" (`:345`).

Every other `RUN_TESTS_*` and `HEALTH_CHECK_*` variable is honoured by the script whose prefix it carries. A reader who sees `RUN_TESTS_JOBS` in pr-prep will reasonably run `RUN_TESTS_JOBS=8 scripts/run-tests.sh --failed` or `RUN_TESTS_JOBS=8 scripts/run-tests.sh <files>` (the pr-prep 3c re-runs). Those runs are silently serial: no error and no warning. The variable also sits in health-check.sh's header block between `HEALTH_CHECK_RUN_TESTS` and `HEALTH_CHECK_LOCK_HELD`, which breaks the block's single-prefix grouping. The roadmap brief asked for "a `RUN_TESTS_JOBS`-style variable" (roadmap item 6, removed in this diff). That suggests where the name came from, but it does not require the exact name.

**Recommendation:** Rename it to `HEALTH_CHECK_JOBS` while the branch is unmerged. Nothing outside this diff reads it, so the rename costs nothing now. Update the header entry, the check-5 comment and message, the bats tests, pr-prep 5a and the archive's Applied note. The other option is to keep the name and make run-tests.sh read `RUN_TESTS_JOBS` as its `--jobs` default. That widens the change: an ambient value would then make every bare runner call, `--failed` included, parallel, so it is the larger contract change. Prefer the rename.

#### 2. The header does not say that an empty value means the default

**Severity:** Minor
**Location:** `scripts/health-check.sh:27-33`; `docs/working/questions-archive.md:2516`
**Move:** 8 (nullability contract)
**Confidence:** High
**Legibility-target:** for-reader

Evidence: the header says "Default 8; 1 runs serially. Same grammar as run-tests.sh's --jobs (1 to 999, digits only, no leading zero); any other value fails check 5 before it runs a test." The code reads it with `${RUN_TESTS_JOBS:-8}` (`:408`), so `RUN_TESTS_JOBS=` runs with 8. run-tests.sh would reject `--jobs ""` (fact-check claim 3, executed). The *behaviour* matches every sibling: empty is treated as unset (`HEALTH_CHECK_LOCK_WAIT`'s `-n "${…:-}"` at `:1139`, `HEALTH_CHECK_SKILLS_DIR`'s `:-`). The fault is in the text: "any other value" includes the empty string, and the header says that value fails the gate. The archive's Applied note says the same.

**Recommendation:** Change the header to "Unset or empty: 8", and the failure clause to "any other non-empty value". Make the same change in the Applied note. The behaviour itself needs no change.

#### 3. health-check.sh keeps a second copy of run-tests.sh's `--jobs` grammar

**Severity:** Minor
**Location:** `scripts/health-check.sh:409-412` against `scripts/run-tests.sh:141-150`
**Move:** 7 (asymmetry), 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: health-check.sh has `[[ ! "$jobs" =~ ^[1-9][0-9]{0,2}$ ]]` with `fail "RUN_TESTS_JOBS='$jobs' is not 1 to 999 (digits only, no leading zero; 1 = serial) — BATS suites not run"`. run-tests.sh has `[[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]` with `echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}"`. The comment says the value "is checked here with run-tests.sh's own grammar", but it is a copy, not a shared definition.

The pre-check is a sound choice: it fails by name before any suite runs. Handling it with `fail` + `return` instead of `HEALTH_CHECK_LOCK_WAIT`'s `exit 1` is also correct. The variable governs only check 5, and the other checks are still worth running. This matches how check-scoped problems are reported elsewhere in the script. The problem is maintenance. If run-tests.sh's bound changes, the two copies drift and nothing catches it. The bats test pins only health-check's side (`test/scripts/health-check.bats:234-243`). The message style also differs from both siblings in small ways. It quotes the value as `'X'`. run-tests.sh writes `got: X`. `HEALTH_CHECK_LOCK_WAIT` does not echo the value at all. This is harmless, but it is a third style.

**Recommendation:** Add a cross-reference comment at run-tests.sh's `--jobs` case ("health-check.sh check 5 copies this grammar"). Alternatively, add one bats case that feeds the same bad values to the real runner's `--jobs` and asserts exit 2, so the two copies cannot drift unnoticed. Optional.

#### 4. pr-prep's timing claim is not the gate's measured time

**Severity:** Minor
**Location:** `workflows/pr-prep.md:331`; `scripts/health-check.sh:386-388`
**Move:** 3 (documentation drift)
**Confidence:** Medium (inherits Stage-1 claims 1 and 4)
**Legibility-target:** for-reader

Evidence: pr-prep says "each with `--jobs 8` (Q-102 [1]: about 2.5 min against 7.5 min serial)". The health-check.sh comment says "140 s against 451 s on 16 cores; see the "Parallel runs" section of run-tests.sh". Stage-1 found both figures come from Q-090's single full-suite run, not from the two-run gate (`questions-archive.md:1878`). run-tests.sh's "Parallel runs" section holds only the jobs-16-against-8 figure. This is the consumer-facing description of the gate, so a wrong figure there misleads anyone planning around the gate's duration. No other caller documents a gate duration: dev-cycle step 1 (`skills/dev-cycle/SKILL.md:372-385`) bounds only the lock wait, at `HEALTH_CHECK_LOCK_WAIT=3600`.

**Recommendation:** Follow the fact-check fix. Say "one full-suite run" and point to Q-090, not to run-tests.sh. No API change.

## Caller documentation sweep

- `workflows/pr-prep.md` 5a (`:331`) and 3c/re-run (`:345`) are updated. Both stay accurate after Findings 1, 2 and 4 are addressed. If the variable is renamed, `:345`'s "which runs serially" stays true and becomes less surprising.
- `skills/dev-cycle/SKILL.md:372-385` runs `scripts/health-check.sh` with `HEALTH_CHECK_LOCK_WAIT=3600` and triages failures "as pr-prep step 5a does". It makes no serial or timing claim and is still accurate. A bad value makes the gate exit 1, not 75, with the message "BATS suites not run". Step 1 would triage that as a red gate, which is correct, because it is a configuration error on the caller's side.
- `scripts/build-loop.sh`'s "gate" is its merge gate. It never invokes health-check.sh, so it is not affected.
- `global-instructions/CLAUDE.md:284` names health-check.sh only as the questions-doc gate (check 14). `AGENTS.md` and `GEMINI.md` do not describe check 5. All still accurate.
- `guides/validation-gates.md` and `guides/cross-project-setup.md` mention health-check.sh without describing check 5's mode. Still accurate.
- Test drift: Stage-1 escalation. The sibling gate-5 test at `test/scripts/health-check.bats:466-480` calls `check_bats` without `-u RUN_TESTS_JOBS`, so an ambient bad value breaks it. It is noted here only because a rename (Finding 1) would touch the same lines. The orchestrator owns that fix.

## What Looks Good

- The default is backward-compatible in the way that matters. Unset gives `--jobs 8`, `1` gives exactly the old serial behaviour, and run-tests.sh's no-GNU-parallel fallback is left to the runner, so there is no second fallback path.
- A bad value fails *by name and before any suite runs*. It does not show up as a runner usage error (exit 2) halfway through the gate, and the bats test pins that the stub runner is never called (`[ ! -s "$STUB_LOG" ]`).
- Check-scoped `fail` + `return` is the right handling. It matches how health-check.sh reports problems that belong to one check, and `HEALTH_CHECK_LOCK_WAIT`'s `exit 1` is the exception only because that variable is read before any check starts.
- Treating empty as unset matches every sibling variable.
- The recursion guard is untouched. `HEALTH_CHECK_SKIP_BATS` is tested before `RUN_TESTS_JOBS` is read, so nested runs neither validate nor use it.
- The documentation is in the conventional place: the header `# Environment:` block, the check list (item 5) and the check's own comment block.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `RUN_TESTS_JOBS` has the runner's prefix, but only health-check.sh reads it; a bare runner call with it set is silently serial | Inconsistent | `scripts/health-check.sh:27-33,408`; `workflows/pr-prep.md:331` | High |
| 2 | Header and Applied note say any non-grammar value fails, but empty means 8 | Minor | `scripts/health-check.sh:27-33`; `questions-archive.md:2516` | High |
| 3 | A second copy of the `--jobs` grammar, with nothing to stop drift; a third error-message style | Minor | `scripts/health-check.sh:409-412`; `scripts/run-tests.sh:141-150` | Medium |
| 4 | Gate timing in pr-prep and the comment is a full-run figure, not the gate's | Minor | `workflows/pr-prep.md:331`; `scripts/health-check.sh:386-388` | Medium |

## Overall Assessment

The surface is one environment variable. Its behaviour matches the repo's conventions: empty means the default, a bad value fails check 5 by name before anything runs, and the rejection is check-scoped like other check failures. The one real inconsistency is the name. Every `RUN_TESTS_*` and `HEALTH_CHECK_*` variable is read by the script whose prefix it carries, and this one is not, so `RUN_TESTS_JOBS=N scripts/run-tests.sh …` silently ignores it. Nothing breaks (no existing consumer), and the fix is a rename on an unmerged branch (`HEALTH_CHECK_JOBS`). The other three findings are wording or drift guards that can be fixed in place. Every other document that describes the gate is still accurate.

## Goal-Alignment Note

The goal is to land Q-102 [1], parallel test gates by default with an env override, as one reviewed unit. The diff does that. Gate 5 runs both suites at `--jobs 8`, `=1` restores serial, and bad input fails safely. None of these findings blocks the goal or calls for a design change. Finding 1 is the only one worth resolving before merge, because merging fixes the name in place: pr-prep, the archive and any user's shell habits will then carry it. A rename now costs one small fix commit. All four findings are confined to this unit and need no split.
