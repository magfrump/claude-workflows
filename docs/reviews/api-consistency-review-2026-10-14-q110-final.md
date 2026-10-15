Commit: 16ce27bf
# API Consistency Review — fix/q110-not-run-undercount (iteration 2, final)

**Scope:** `git diff main...HEAD -- scripts test docs/thoughts` (scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md); docs/reviews artifacts read as context
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report-q110-final.md (k=3 merged, 21 Verified, 4 Mostly accurate, 1 Stale, 0 Incorrect)

## Baseline Conventions

The public surface is run-tests.sh's environment-variable contract: the header `Environment:` block, which `--help` prints verbatim (`sed -n '2,/^$/{ s/^# //; s/^#$//; p }' "$0"`, scripts/run-tests.sh:157, so the header is the help text). Siblings surveyed:

- **scripts/health-check.sh:11-46** (`Environment:` block, six `HEALTH_CHECK_*` variables). Each entry is `NAME` in a fixed column, then prose giving: what it controls, its default, whether it is a test-only seam, and **who sets it and how far it reaches** — e.g. `HEALTH_CHECK_SKIP_BATS ... Set by check 5 itself for the runner it launches, so the health-check.bats suite cannot recurse into the full suite` (:20-24) and `HEALTH_CHECK_LOCK_HELD ... Not only a test seam: any caller setting it skips the lock` (:36-41). Scope across process boundaries is part of the documented contract.
- **scripts/self-improvement.sh:17-21** (`Environment variables:` block, one variable, name + meaning + default). Older, terser shape.
- **scripts/run-tests.sh:424-430**: the runner already unsets inherited variables before `exec bats` (`BATS_NUMBER_OF_PARALLEL_JOBS BATS_NO_PARALLELIZE_ACROSS_FILES`, `PARALLEL PARALLEL_CSH`), each with a body comment giving the reason, and documents none of them in the header (they are not its inputs).
- **Variable naming:** `<SCRIPT>_<NOUN...>` upper snake case (`HEALTH_CHECK_*`, `RUN_TESTS_NOT_RUN_FILE`).
- **Output-file contract consumer:** scripts/health-check.sh:431,439 sets the variable per invocation (`RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" ...`) and reads it with `_not_run_count` (:453-460), which treats a missing or non-numeric file as 0.

## Name-Pattern Audit

The diff introduces no new public names: `RUN_TESTS_NOT_RUN_FILE` existed on main and keeps its name, meaning and write semantics. The only new names are a bats test title and a failure-pattern log entry (internal, but audited because they follow repo conventions readers grep by).

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `the suites do not inherit RUN_TESTS_NOT_RUN_FILE, so a nested run cannot overwrite the caller's count` | bats test title | `a tag naming no skill is an error, not a suite that never runs`, `a stamp or .failed marker alone is not a report`, `one skill's reports run only that skill's suites` | `test/skills/eval-helpers-gating.bats:49-110` | Consistent — lower-case declarative sentence stating the guaranteed behaviour, as its siblings |
| `FP-173` entry tokens `cause:boundary-too-wide`, `fix:remove-the-path` | failure-pattern log tokens | `FP-043 ... cause:boundary-too-wide fix:remove-the-path`, `FP-008 ... fix:remove-the-path` | `docs/thoughts/failure-patterns.md:64,99,150,185` | Consistent — reuses table vocabulary; no new token coined (fact-check cluster 2 Verified) |
| `FP-173` `ref:70aa3a78` | failure-pattern log ref | `ref:a2972bf` (FP-172), `ref:e96912d` (FP-170/171), `ref:0386fa0` (FP-008) | `docs/thoughts/failure-patterns.md:150-314` | Minor deviation — only 8-hex ref among 166 SHA refs (165 are 7-hex); see Finding 1 |

## Findings

#### 1. FP-173's ref is the only 8-character SHA in a log of 7-character ones

**Severity:** Informational
**Location:** `docs/thoughts/failure-patterns.md:315`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** for-author

Precedent: 7-hex-character commit refs (`ref:<7 hex>`) used in `docs/thoughts/failure-patterns.md:150-314` (165 of the 166 SHA refs; `rg -o 'ref:[0-9a-f]+' | awk '{print length($0)-4}' | sort | uniq -c` gives 165 x 7, 1 x 8, 1 x 1)

**Evidence:**
```
315: - **FP-173** 2026-10-14 symptom:output-file-env-var-inherited-by-nested-runner-overwrites-caller-count cause:boundary-too-wide fix:remove-the-path ref:70aa3a78
314: - **FP-172** 2026-09-24 symptom:failed-generation-leaves-empty-report-and-absence-only-checks-pass-every-negative-control cause:vacuous-assertion fix:fail-closed-on-empty-input ref:a2972bf
 30: | `ref:<path-or-sha>` | `ref:docs/working/diagnosis-date-parsing.md` | Diagnosis log path or fix commit SHA — where the full reasoning lives. |
```

The grammar (`ref:<path-or-sha>`, :30) allows any length, `70aa3a7` is unambiguous in this repo (`git rev-parse --short=7 70aa3a78` returns it), and a reader grepping `ref:70aa3a7` still matches as a prefix, so nothing breaks. The 8 characters come from this repo's own `git log --oneline` abbreviation, so later entries will probably drift the same way. Severity is Informational, not Minor: the log has a precedent but no stated length rule, and no consumer parses the length.

**Recommendation:** Optional. Either trim to `ref:70aa3a7` to match the log, or leave it. Do not reword anything else for it.

## What Looks Good

- **The Environment entry follows the sibling contract shape.** scripts/run-tests.sh:19-23 now states how far the variable reaches (`It is unset before bats runs, so the suites (and any runner a suite starts) do not inherit the caller's value.`). That is the same kind of statement health-check.sh makes for `HEALTH_CHECK_SKIP_BATS` (:20-24) and `HEALTH_CHECK_LOCK_HELD` (:36-41). Because `--help` prints the header, the new scoping reaches users with no separate doc to keep in step (checked: `bash scripts/run-tests.sh --help` prints the five-line entry).
- **The wording matches the real guarantee.** "do not inherit the caller's value" (rather than iteration 1's "never see it") leaves room for the two cases that still work and are tested. A suite can set its own value (eval-helpers-gating.bats:50,63 run nested runners with `env RUN_TESTS_NOT_RUN_FILE="$T/nr"`), and a caller can inject one through PARALLEL_ENV. Fact-check clusters 3, 15 and 16 are Verified on every path from the write (:360-361) through `bats --count` (:442) to `exec bats` (:453).
- **Not a breaking change.** The write semantics are unchanged: written once, before any suite runs, only when the variable is set. The one consumer (health-check.sh:431,439) sets it per invocation and reads it back after the runner exits. Nothing reads it after :369 (fact-check cluster 3). The only suite that touches it, test/scripts/health-check.bats:488 (`[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"`), is a stub *runner* that health-check.sh hands the variable to directly, so the unset does not affect it (fact-check clusters 4 and 13 under 4b775841's correction).
- **The unset follows existing practice.** It sits right after the variable's last use, with a body comment giving the reason (:363-369). That matches how the runner already unsets `BATS_*` and `PARALLEL*` before `exec bats` (:424-430). Like those, the reasoning is in the body and the header gives only the consumer-visible effect.
- **The new and unchanged variables are scoped in opposite directions, on purpose, and both are documented.** `HEALTH_CHECK_SKIP_BATS` is passed on to nested runs by design: it is the recursion guard. `RUN_TESTS_NOT_RUN_FILE` is now withheld from nested runs by design: it is a per-run answer. Each entry says which applies, so a reader comparing the two siblings is not left guessing.
- **The test title and FP-173 vocabulary match their neighbours** (Name-Pattern Audit rows 1-2).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | FP-173 ref is the only 8-char SHA among 165 7-char refs | Informational | `docs/thoughts/failure-patterns.md:315` | High |

## Overall Assessment

The change fits the codebase's conventions for documented environment variables. It narrows how far an existing output variable reaches without changing its name, its write semantics or its one consumer's contract. The `--help`-visible header now states that scope the way health-check.sh's entries state theirs. The unset is placed and commented the way the runner's existing unsets are. Nobody who wrote code against the previous version breaks: the health check still gets its count, and suites that want a count set their own variable, as the existing tests already do. The only finding is an optional cosmetic SHA-length deviation in the failure-pattern log. No consistency issue needs a fix before landing.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path given in your tail, structured per your skill.
- **Answered:** yes. Saved at docs/reviews/api-consistency-review-2026-10-14-q110-final.md with the skill's sections: Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Built on the merged fact-check report rather than re-verifying behaviour.
- **Out of scope:** The runner's early exits before the write (lock held, no matched files, bad tag; :304-308, :355-357) leave the caller's file unwritten, which the health check reads as 0. The Environment entry's "When set" does not say so. This was already the case on main, untouched by this diff, and covered by fact-check Escalation 3 (every such exit fails the gate). The `docs/reviews/` rubric line cites (fact-check Claim 1, Stale) are context artifacts, not public surface.
- **Escalate:** `docs/working/questions.md:73` (Q-110) is still OPEN and cites `scripts/run-tests.sh:356-357` (at HEAD the write is at :360-361 and the unset at :369). It needs its citation updated and to be closed when this lands. Addressee: orchestrator, as fact-check Escalation 1 already says.
