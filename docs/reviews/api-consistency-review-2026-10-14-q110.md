Commit: f84a9dfa
# API Consistency Review — fix/q110-not-run-undercount

**Scope:** `git diff main...HEAD` (70aa3a78, f84a9dfa): scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report-q110.md (k=3 merged; 20 Verified, 2 Mostly accurate, both commit-message wording only)

Public surface under review: run-tests.sh's documented environment-variable contract (`RUN_TESTS_NOT_RUN_FILE` and the header `Environment:` block, which `--help` prints: the header runs unbroken to the first blank line at :117), and how sibling scripts document and scope their env vars.

## Baseline Conventions

Surveyed: scripts/run-tests.sh (whole file, 452 lines), scripts/health-check.sh header `Environment:` block (:11-40+) and check 5 (`check_bats`, :365-452), scripts/self-improvement.sh `Environment variables:` block (:17-20), test/skills/eval-helpers-gating.bats (whole file), test/scripts/health-check.bats:488, docs/thoughts/failure-patterns.md vocabulary tables and entry grammar.

- **Header env blocks are per-variable, with a scoping sentence.** health-check.sh's block states who sets each variable and how far it reaches, e.g. `HEALTH_CHECK_SKIP_BATS ... Set by check 5 itself for the runner it launches` and `HEALTH_CHECK_JOBS ... Read here only: run-tests.sh run by hand stays serial unless given --jobs.` A sentence about reach/inheritance inside the variable's own entry is the established form.
- **run-tests.sh already strips inherited env before handing off to bats, and documents it.** Header "Parallel runs": `It unsets $PARALLEL and $PARALLEL_CSH, so options the user set there do not reach bats' run.` (:100-101); inline at :423-427 for `BATS_NUMBER_OF_PARALLEL_JOBS BATS_NO_PARALLELIZE_ACROSS_FILES`. Each unset carries a "why".
- **Contrasting variable that must propagate:** health-check.sh passes both `HEALTH_CHECK_SKIP_BATS=1` and `RUN_TESTS_NOT_RUN_FILE=...` as env prefixes on the runner (:431, :439). The recursion guard depends on SKIP_BATS being inherited by suites; the runner does not touch it. So "caller-to-runner" variables in this repo are not uniformly scoped; each is scoped by its own documented purpose.
- **failure-patterns.md entry grammar:** `**FP-NNN** YYYY-MM-DD symptom:<keywords> cause:<category> fix:<category> ref:<diagnosis-doc-or-commit>` (:19), with `cause:` and `fix:` from closed tables (:64 `boundary-too-wide`, :99 `remove-the-path`). Commit refs are 7-char in 165 of 166 entries.

## Name-Pattern Audit

The diff introduces no new public names. No env var, flag, function, exit code or output format is added or renamed; `RUN_TESTS_NOT_RUN_FILE` keeps its name, its write timing and its file format (a single integer). The only new identifiers are a test name and a log entry ID, audited below for completeness.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `FP-173` | log entry ID | `FP-170`, `FP-171`, `FP-172` | `docs/thoughts/failure-patterns.md:312-314` | Consistent — next sequential ID, same field order, tokens from the closed tables |
| `ref:70aa3a78` (8-char SHA) | log ref | `ref:a2972bf`, `ref:e96912d` (7-char) | `docs/thoughts/failure-patterns.md:150-314` | Consistent with the grammar (`ref:<path-or-sha>`, :30, sets no length); 7-char is the de facto habit. Not expanded into a finding: the grammar does not require it and the ref resolves |
| test "the suites never see RUN_TESTS_NOT_RUN_FILE, so a nested run cannot overwrite the caller's count" | bats test name | "no reports: every tagged suite is listed NOT RUN on stdout; ...", "a stamp or .failed marker alone is not a report" | `test/skills/eval-helpers-gating.bats:49,88` | Consistent — sentence-form behaviour statement, matching its file |

## Findings

#### "never see it" reads as a ban on the variable rather than on the inherited value

**Severity:** Informational
**Location:** `scripts/run-tests.sh:19-22`
**Move:** 3 (consumer contract: documentation precision)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence** (`scripts/run-tests.sh:19-22`, the variable's whole entry):
```
#   RUN_TESTS_NOT_RUN_FILE  When set, the number of report-dependent suites
#                           gated out is written to this file. It is
#                           unset before bats runs, so the suites (and any
#                           runner a suite starts) never see it.
```

The fact-check verifies the behaviour (cluster 5: no path from the write at :359-360 to `exec bats` at :452 keeps the variable). The wording slightly overreaches as a contract, though. A suite may still set its own value for a runner it starts, and this suite does exactly that: `run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast` (`test/skills/eval-helpers-gating.bats:50,63,82`). What the runner guarantees is that the caller's value is not inherited. A reader of `--help` could take "never see it" to mean a nested runner cannot report a count. That reading would make no difference to any current consumer: the fact-check's Claim 2 shows the only other reader, the stub at test/scripts/health-check.bats:488, gets its value from health-check.sh.

**Recommendation:** Optional rewording, e.g. "...so the suites (and any runner a suite starts) do not inherit the caller's file; a suite that wants a count passes its own." Fine to leave as is.

## What Looks Good

- **No breaking change to the contract.** For the documented consumer (health-check.sh check 5, :431/:439) the input name, the "when set" semantics, the write point (before any suite runs) and the file format are all unchanged. All that changes is that the variable no longer leaks downward, and the fact-check (Claim 2, cluster 9) finds no suite that depended on the leak. `_not_run_count`'s fallback for an unwritten file (`health-check.sh`, "or 0 when it wrote none") is untouched.
- **Scoping is documented the way siblings document it.** The new sentence sits inside the variable's own `Environment:` entry, matching health-check.sh's per-variable scoping sentences ("Set by check 5 itself for the runner it launches", "Read here only"). The unset carries a "why" comment (:362-367), as the PARALLEL/BATS_* unsets do (:100-101, :423-427).
- **Placement is right.** The unset sits on the line after the variable's only read (:359-360), not with the other unsets at :427-429. So none of the early `exit 0` paths (--failed nothing-to-rerun :393-394, no runnable files :398-400) or the `bats --count` subprocess (:437) can see it. Grouping it with the BATS_* unsets would have left it exported during `bats --count`.
- **The fix is runner-side, so every nested runner is covered without changing each suite.** The comment explains why the alternative (refusing an inherited value) cannot work given health-check.sh's env-prefix invocation (fact-check cluster 9).
- **`--help` picks up the change.** The `Environment:` block is in the header range that `-h|--help` prints (`sed -n '2,/^$/...'`, first blank line :117).
- **FP-173** follows the entry grammar and uses closed-table tokens. The fact-check notes `boundary-too-wide` has so far been used only for security/sandbox boundaries; its table definition ("a security or isolation boundary admitted more than intended", :64) does admit an env-inheritance boundary.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "never see it" reads as a ban on the variable rather than on the inherited value | Informational | `scripts/run-tests.sh:19-22` | Medium |

## Overall Assessment

The change fits the repo's env-var conventions. It narrows the variable's reach without changing its name, semantics, timing or format for the one documented consumer, so it breaks nothing. It documents the new scoping in the variable's own header entry, the same way health-check.sh documents reach, and it follows run-tests.sh's own precedent of stripping inherited env before bats, with a reason given each time. The one item is an optional rewording of the header sentence. Nothing here needs another iteration.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path given in your tail, structured per your skill.
- **Answered:** Yes. The env-var contract and sibling env-doc conventions were surveyed (run-tests.sh, health-check.sh, self-improvement.sh), the consumer contract was traced (health-check.sh :431/:439, test/scripts/health-check.bats:488, every `RUN_TESTS_NOT_RUN_FILE` reference in the repo), and the name audit is done (no new public names). One Informational finding.
- **Out of scope:** Re-verifying runtime behaviour (the fact-check executed the reproduction and the new test against both runners). Test quality and whether the test is vacuous (test-strategy / fact-check cluster 14). The commit-message wording items (fact-check Claims 1-2).
- **Escalate:** None new. The fact-check's two escalations stand for the orchestrator: Q-110's stale `scripts/run-tests.sh:356-357` citation (now :359-360) and OPEN status in docs/working/questions.md:73, and the pre-existing early-`exit 1` paths that leave the caller's file unwritten (read as 0 by `_not_run_count`).
