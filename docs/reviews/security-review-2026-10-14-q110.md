Commit: f84a9dfa
# Security Review — fix/q110-not-run-undercount

**Scope:** `git diff main...HEAD` (70aa3a78, f84a9dfa): scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report-q110.md (merged k=3, Commit f84a9dfa; 20 Verified, 2 Mostly accurate)

No HALT patterns matched. The diff has no credentials, auth, TLS or crypto material, and it adds no injection sink.

## Trust Boundary Map

```
B1 (narrowed): [caller env: RUN_TESTS_NOT_RUN_FILE] → [run-tests.sh :359-360 write, then :368 unset] → [file at caller-named path]
B2 (removed):  [runner process env]                 → [exec bats :452 / bats --count :441]         → [suite processes, nested runners]
B3:            [file at caller-named path]          → [health-check.sh _not_run_count :455-460]    → [gate pass/warn lines]
B4:            [test-local $T (mktemp -d)]          → [printf-generated stub bats, eval-helpers-gating.bats:80] → [stub executed via PATH]
```

Input-source classification:

```
S1: RUN_TESTS_NOT_RUN_FILE (env)      — invocation-time (set by the caller: health-check.sh :431/:439, or a test)
                                        — trusted for the file-write sink as the caller's own choice (same uid,
                                          same checkout; a writer of this env already runs code as the user);
                                          the diff stops it reaching less-trusted-to-be-correct consumers
                                          (suite code, nested runners), which is the integrity defect fixed
S2: count file contents               — runtime file written by the runner, read by health-check
                                        — untrusted for the arithmetic sink; health-check validates ^[0-9]+$ (:458)
S3: $T from mktemp -d                 — request-time per test, mode 0700 dir under $TMPDIR
                                        — trusted for the printf-into-script sink (the user's own TMPDIR)
S4: not_run array length              — code-derived integer — trusted (all sinks)
```

The diff touches one real boundary (B1/B2): an output-path environment variable that previously leaked from the runner into every process bats started. It now ends at the runner. That narrows the set of processes that can write the caller's result file from "every suite and any runner they start" to "the runner itself". No new input is accepted and no new sink is introduced; the write at :360 and the reader at health-check.sh :455 predate the diff.

## Findings

No findings.

Candidates considered and dispositioned. None meets the reachable-environment bar for a security finding:

- **Fail-open read of the count (B3).** `_not_run_count` maps a missing or non-numeric file to 0, so a runner that exits before :360 writes nothing and the health check's NOT RUN warning disappears (fact-check Escalation 2). Traced: every runner exit before :360 is non-zero (:150, :163, :172, :196-207, :235, :240, :250-268, :307, :356), and health-check.sh treats a non-zero runner as `fail` (:431-434 fast, :439-444 slow). So the zeroed count only ever comes with a failed gate and never hides gated-out suites behind a pass. The exception is `-h|--help` (exit 0 at :157), which health-check never passes. Pre-existing and out of scope. Cleared.
- **Env-named write target (B1, S1).** `echo … > "$RUN_TESTS_NOT_RUN_FILE"` follows symlinks and truncates whatever path the caller names. The caller is the same user. health-check's path is inside its own `mktemp -d` (:429), and the test's path is inside `$T` (0700). No lower-privileged party controls S1. Pre-existing. Cleared.
- **Nested writers still possible under bare `bats` (B2).** When a user runs a suite with bare `bats` and the variable exported by hand, the runner is bypassed, so eval-helpers-gating.bats tests 4-6 (which start the runner with no override) inherit the variable. Even then the nested runner does its own write-then-unset, so the user's file is overwritten with the fixture's count. This is the integrity issue the fix addresses, not a security one, and the fact-check (r2 annotation, cluster 22) records it as out of the claim's scope. Informational only. Not filed.

## Endorsement Claims

- **Claim:** After the diff, no process bats starts (via `bats --count` at :441 or `exec bats` at :452, serial or `--jobs N`) has `RUN_TESTS_NOT_RUN_FILE` in its environment, even when the caller exported it rather than env-prefixing it.
  **Location:** `scripts/run-tests.sh:359-368`, `:441`, `:452`
  **Evidence:** executed
  **Verified:** Throwaway layout under the job tmp dir, with a stub `bats` that counts `RUN_TESTS_NOT_RUN_FILE=` lines in `env` and writes 99 to the inherited path if it has one. Run with the variable `export`ed, for `--fast` and for `--fast --jobs 2`. HEAD's runner: count file = 1 (correct), stub saw the variable 0 times. main's runner: count file = 99, stub saw it once. Same result on both paths. The probe dir was removed afterwards.
  **Not verified:** a run where GNU parallel is actually on PATH and bats fans out through it. The stub replaces bats, so parallel's own env propagation was not exercised. The unset happens in the runner before exec, so this hop cannot reintroduce the variable unless parallel's config injects it, which was not checked.
  **route: code-fact-check**

- **Claim:** The diff does not remove the variable before its only consumer in the runner. The single read and write is at :359-360, and lines :369-452 have no other reference.
  **Location:** `scripts/run-tests.sh:359-452`
  **Evidence:** read-static
  **Verified:** read the whole script (lines 1-452). `RUN_TESTS_NOT_RUN_FILE` appears only in the header (:19-22), the gating comment (:320) and :359-368.
  **Not verified:** test/lib/hermetic-env.bash and test/skills/runner-contract.bash, which are sourced before :359. They were not read for references to the variable. Any such reference runs before the unset, so it would be unaffected.

- **Claim:** The regression test fails on main's runner and is not vacuous: its stub writes 99 to any inherited path, and the test asserts the caller's file reads 4 and the stub saw `unset`.
  **Location:** `test/skills/eval-helpers-gating.bats:74-86`
  **Evidence:** read-static (my probe reproduces the mechanism; the fact-check's k=3 executed the test itself against both runners, clusters 13-14)
  **Verified:** read the test, setup (:9-30) and the stub printf. `$T` is interpolated as a `%s` argument into a double-quoted path in the generated script. `$T` comes from `mktemp -d`, so the generated script carries only the user's own TMPDIR.
  **Not verified:** behaviour when TMPDIR contains `"` or `$`, which would break the generated stub's quoting. Only the user can set that, so it is not a security boundary.

## Primitive sweep

Primitive: file write via shell redirection to an environment-named path

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/run-tests.sh:360` | S1 | `-n` check only | cleared — S1 is set by a same-uid caller; pre-existing |
| `test/skills/eval-helpers-gating.bats:80` (generated stub, `echo 99 > "$RUN_TESTS_NOT_RUN_FILE"`) | S1 (test's own `$T/nr`) | `-z` check | cleared — test-local path; the runner never hands it the variable after the fix |
| `test/scripts/health-check.bats:488` (stub runner, `echo 47 > "$RUN_TESTS_NOT_RUN_FILE"`) | S1 (set by health-check.sh to its own mktemp dir) | none | cleared — not in the diff; health-check sets the path |

Primitive: process exec via PATH lookup

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/run-tests.sh:441` `bats --count` | PATH (caller env) | none | cleared — pre-existing; runs after the unset, so the variable no longer reaches it |
| `scripts/run-tests.sh:452` `exec bats` | PATH (caller env) | none | cleared — pre-existing; the same |
| `test/skills/eval-helpers-gating.bats:80-82` stub via `PATH="$T/bin:$PATH"` | S3 | 0700 mktemp dir | cleared — test-local |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

From a security standpoint the change makes the trust boundary smaller. An output path that the runner leaked to every suite process (B2) now stops at the runner (B1). The probe shows this both for an exported variable and on the `--jobs` path. The diff adds no new input, sink or guardrail. The one fail-open reader (`_not_run_count` mapping a missing file to 0) is pre-existing and only applies on paths where the gate already fails. No findings within the code paths read. The executed endorsement is pending code-fact-check routing, and the read-static endorsements name their unread hops (the sourced helper files, GNU parallel's own env handling).

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path given in your tail, structured per your skill.
- **Answered:** yes. The report is saved at docs/reviews/security-review-2026-10-14-q110.md with the boundary map, source table, primitive sweep and endorsements. The core behaviour was probed with an exported variable, serial and `--jobs 2`, against both main's and HEAD's runner.
- **Out of scope:** the wording accuracy of the commit message and comments (fact-check Claims 1-2, Mostly accurate; no security bearing). Whether the fix belongs runner-side or suite-side (architecture critics).
- **Escalate:** none from security. Fact-check Escalation 2 (early exits leave the file unwritten) is cleared above as not hiding anything behind a pass. Fact-check Escalation 1 (the Q-110 entry's stale line citation and OPEN status) stays with the orchestrator.
