Commit: 16ce27bf

# Security Review: fix/q110-not-run-undercount (iteration 2, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test docs/thoughts` (scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md); docs/reviews artifacts read as context
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report-q110-final.md (k=3 merged, Commit 16ce27bf)

No HALT escalation: none of the five patterns match. The diff adds no credentials, endpoints, injection sinks, TLS settings or keys.

## Trust Boundary Map

```
B1: [caller env: RUN_TESTS_NOT_RUN_FILE (health-check.sh, a test, a user)] → [run-tests.sh :360-361 write] → [caller-owned count file]
B2: [run-tests.sh process env] → [unset :369, then `bats --count` :442 / `exec bats` :453] → [bats, every suite, any runner a suite starts] (moved: the variable no longer crosses here)
B3: [count file contents] → [health-check.sh _not_run_count (digits-only regex, else 0)] → [gate 5 warning and pass-line note]
B4: [caller-supplied PARALLEL_ENV code, --jobs N > 1] → [GNU parallel, started by bats] → [per-file bats workers' env]
```

Input-source classification:

```
S1: RUN_TESTS_NOT_RUN_FILE (caller env)   — request-time (per invocation) — trusted toward the write sink
                                             (same uid as the runner; health-check passes a path in
                                             its own mktemp -d dir); UNTRUSTED as a value to hand on to
                                             suites (the bug: a nested runner treated it as its own)
S2: count file contents                    — request-time — untrusted toward arithmetic; the reader
                                             gates it to ^[0-9]+$ (health-check.sh _not_run_count)
S3: suites under test/ (repo code)         — deploy-time (checked-in) — trusted for exec; NOT trusted
                                             to leave the caller's count alone (the Q-110 failure)
S4: PARALLEL_ENV (caller env)              — request-time — trusted (same uid, caller's own code);
                                             can set any variable in workers, this one included
S5: test fixture paths ($T from mktemp -d) — code-constant shape — trusted (embedded via printf %s
                                             into the stub; mktemp names hold no shell metacharacters)
```

What crosses: the caller hands the runner an output path (S1); before the fix that path was also exported across B2 to every suite, so a nested runner (eval-helpers-gating.bats's tests 1, 2) wrote its fixture's count into the caller's file, an integrity fault in a signal that health-check uses to warn about unrun suites (a fail-open of a warning: 50 unrun suites reported as 4). The diff moves the boundary: S1 now ends at the runner's own write. Every party involved runs as the same uid from the same checkout, so this is integrity of a self-reported metric, not an attacker-reachable boundary.

## Findings

#### Residual: caller-supplied PARALLEL_ENV can re-introduce the variable under --jobs

**Severity:** Informational
**Location:** `scripts/run-tests.sh:369`, `scripts/run-tests.sh:429-436`
**Boundary:** B4
**Move:** #11 (bypass enumeration for the new guard), #1
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
369	unset RUN_TESTS_NOT_RUN_FILE
...
429	if [[ "$jobs" -gt 1 ]]; then
430	  unset PARALLEL PARALLEL_CSH
431	  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
432	    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
```
(excerpt; the block ends at :436 with the serial-fallback warning, and the file at `exec bats` :453)

The unset removes inheritance, but GNU parallel evaluates `PARALLEL_ENV` in each worker, so a caller who exports `PARALLEL_ENV='export RUN_TESTS_NOT_RUN_FILE=...'` can set the variable inside suites again. That caller already controls the environment and the uid, so nothing is gained; the commit 4b775841 body says so explicitly and the header was reworded to "do not inherit the caller's value" (fact-check clusters 15, 16, 18: Verified). Recorded so the guarantee's edge is visible, not as a defect.

**Recommendation:** None required. If an unintended PARALLEL_ENV ever shows up in health-check runs, unsetting it alongside `PARALLEL PARALLEL_CSH` at :430 is the one-line extension; it is not worth doing speculatively.

## Untested bypass candidates

The new guard is the `unset` at :369. Candidates enumerated, all dispositioned:

1. A path from the write to bats that skips the unset (`--failed`, the `exit 0` at :396 and :402, `--jobs`, `bats --count` :442). **Tested (read + executed):** the unset is top-level, unconditional, after the only write and before every later branch; every later exit either is `exit 0` without starting bats or reaches `exec bats`. Fact-check cluster 3 (Verified, all paths) and my run of the new test (7/7 at HEAD).
2. An exit before the write that the health check reads as 0 unrun. **Tested (read):** exits before :360 are the usage/flag errors (:151, :164, :173), missing/out-of-tree files (:197-208), lock held (:236), `--failed` refusals, untagged (:304) and no match (:308), bad tags (:357): every one exits non-zero, so gate 5 fails rather than passing with a 0 note. `-h` exits 0 but health-check never passes it. Pre-existing, unchanged by the diff (fact-check escalation 3).
3. A failed write (unwritable path). **Tested (read):** `set -euo pipefail` (:119) makes the redirection failure abort the runner non-zero, so the gate fails closed.
4. Re-injection via PARALLEL_ENV. Listed as the Informational finding above (same-trust caller only).
5. A suite reaching the caller's path another way (e.g. /proc/<pid>/environ of the runner). **Tested (reasoning):** `exec` replaces the runner's image and builds bats' environ from bash's exported set after the unset; health-check sets the variable only as a command prefix, so its own environ never holds it. Not executed.

No candidate is left untested; none yields a bypass by a less-trusted party.

## Endorsement Claims

- **Claim:** After the count is written, `RUN_TESTS_NOT_RUN_FILE` is absent from the environment of the bats process the runner starts, on the serial path.
  **Location:** `scripts/run-tests.sh:360-369`, `test/skills/eval-helpers-gating.bats:74-86`
  **Evidence:** executed
  **Verified:** `bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats` at 16ce27bf: test 3 passes (stub bats records `unset`, caller file reads 4); fact-check replicates ran the same test against main's runner and it fails at :84 (99), and repeated the stub scenario with `--jobs 2`.
  **Not verified:** an end-to-end `--jobs N` run through real GNU parallel workers with the real suites (only the stub stands in for bats).
  **route: code-fact-check**

- **Claim:** The diff adds no new sink for S1: the only use of the path remains the single `echo ... >` at :361, and the count is read back through a digits-only regex.
  **Location:** `scripts/run-tests.sh:360-361`, `scripts/health-check.sh` `_not_run_count`
  **Evidence:** read-static
  **Verified:** `grep -rn RUN_TESTS_NOT_RUN_FILE scripts test` at HEAD: run-tests.sh (doc, write, unset), health-check.sh :431/:439 (prefix assignments to its own mktemp dir), test stubs only.
  **Not verified:** callers outside this repo that might set the variable (none known).
  **route: code-fact-check**

- **Claim:** The new test's stub is confined to the fixture dir: it writes only to `$T/bats-env` and, on the old runner, `$T/nr`.
  **Location:** `test/skills/eval-helpers-gating.bats:80-82`
  **Evidence:** read-static
  **Verified:** the printf template embeds `$T` via `%s`; the inherited path in the test is `$T/nr`.
  **Not verified:** setup's unguarded `T=$(mktemp -d)` (:10, pre-existing, outside the diff) failing and leaving `$T` empty.

## Primitive sweep

Primitive: file write via shell redirection to a caller-named path (path construction)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/run-tests.sh:361` `echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"` | S1 | none (follows symlinks) | cleared: unchanged by the diff; path chosen by a same-uid caller (health-check: inside its own `mktemp -d`), so symlink-following grants nothing |
| `test/skills/eval-helpers-gating.bats:80` stub `echo 99 > "$RUN_TESTS_NOT_RUN_FILE"` | S1 (test: `$T/nr`) | `[ -z ... ] \|\|` | cleared: test fixture, mktemp dir |
| `test/skills/eval-helpers-gating.bats:80` stub `> "%s/bats-env"` | S5 | none | cleared: fixture path |

Primitive: process exec (`exec bats`, `bats --count`, stub creation). Arguments are the runner's own validated file list (realpath-confined to test/, :205-208, pre-existing); the diff changes only the environment passed, by removing a variable. Cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | PARALLEL_ENV can re-introduce the variable under --jobs (same-trust caller) | Informational | B4 | `scripts/run-tests.sh:369,429-436` | High |

## Overall Assessment

The change narrows a boundary: an output path meant for the runner's caller no longer leaks to the suites, which closes the integrity fault behind Q-110 (a nested runner overwriting the health check's unrun-suite count, so the warning under-reported). Every party is same-uid repo code, so there is no attacker-reachable surface; the one residual (PARALLEL_ENV) requires the caller to opt in and is already documented in 4b775841. The fail-closed behaviour around the count (non-zero exits before the write, set -e on a failed write, digits-only read-back) is pre-existing and unchanged. No findings above Informational within the code paths read; the serial-path endorsement is execution-backed, and the claims marked `route: code-fact-check` remain pending execution verification for the real `--jobs` path.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path given in your tail, structured per your skill.
- **Answered:** yes. Security lens applied to the full branch diff at 16ce27bf; the new test executed at HEAD (7/7).
- **Out of scope:** pre-existing early-exit paths (all fail the gate); the iteration-1 rubric's stale line cites (fact-check Claim 1, docs/reviews only); setup's unguarded `mktemp -d` in eval-helpers-gating.bats (outside the diff).
- **Escalate:** none from this review. Carried from the fact-check report for the orchestrator: Q-110's entry in docs/working/questions.md is still OPEN and cites `scripts/run-tests.sh:356-357`.
