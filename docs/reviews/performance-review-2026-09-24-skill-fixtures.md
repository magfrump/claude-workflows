Commit: 04c0746

# Performance Review — skill-fixtures (pass 1: harness code)

**Scope:** `git diff answers-2026-09-20...skill-fixtures` over the 40 harness files listed in the brief (generate-reports.bash, eval-helpers.bash, the new fast bats suites, health-check.sh, runner.bash files, format-suite edits, .gitignore)
**Date:** 2026-09-24
**Based on:** `docs/reviews/code-fact-check-report-skill-fixtures.md` (merged k=3 fact-check)

## Data Flow and Hot Paths

There is no production hot path in this diff. The code falls into three temperature classes:

- **Warm: the `@category fast` gate.** `scripts/health-check.sh` gate 5 runs `scripts/run-tests.sh --fast` on every health check as a *blocking pre-gate* (fast first, slow only if fast is green). run-tests.sh states the fast contract as "pure function tests, <1s each". The diff adds three fast suites: `test/generate-reports.bats` (19 tests), `test/skills/arithmetic-eval-gate.bats` (18), `test/skills/eval-helpers-transcript.bats` (7). It also adds 22 `*-eval.bats` suites tagged `fast` (sibling files), whose runtime depends on report-gating (below).
- **Cold, operator-invoked: `generate-reports.bash`.** One sequential `claude -p` call per fixture. Each call takes minutes of model time. The harness's own per-fixture work (mktemp, cp, `git init`/commit, one `jq` pass over the transcript) is negligible next to that.
- **Cold, per eval fixture: `eval_fixture` check loops.** For each fixture, every `;;`-separated check runs once. Field checks pipe `$REPORT_CONTENT` (one report, KB-scale) through sed/grep. Transcript checks each run one `jq` pass over the sidecar. `format_check` spawns a nested `bats` process.

Measured in this sandbox (cwd `/workspace`, which holds 395,012 non-`.git` files, 388,532 of them under the gitignored `external/`):

| Suite | Wall time |
|---|---|
| `test/generate-reports.bats`, run from `/workspace` | 13,900 ms |
| `test/generate-reports.bats`, run from the scratchpad | 1,276 ms |
| `test/skills/arithmetic-eval-gate.bats` | 995 ms |
| `test/skills/eval-helpers-transcript.bats` | 317 ms |
| whole `scripts/run-tests.sh --fast` (no generated reports present) | 128,527 ms |

## Findings

#### Stub `claude` walks the caller's whole working tree on every inline-mode call, so generate-reports.bats costs ~10× more in a large checkout

**Severity:** Medium
**Location:** `test/generate-reports.bats:21-23` (stub body), exercised by inline-mode tests at `:55`, `:67`, `:92-104`, `:106-119`, `:121-134`, `:136-146`, `:209-217`
**Move:** Count the hidden multiplications / What's the size of N?
**Classification:** Macro (cost is O(files under cwd), not constant) / Warm path (the blocking fast pre-gate of every health check)
**Confidence:** High
**Baseline:** `bats test/generate-reports.bats` takes 13,900 ms from cwd `/workspace` vs 1,276 ms from the scratchpad (measured in this sandbox, 2026-09-24). Per test: "inline mode: prompt then fixture content…" 3,104–5,248 ms from `/workspace` vs 57 ms from the scratchpad.

**Evidence:**
```bash
{ printf 'ARGS: %s\n' "\$*"; printf 'CWD: %s\n' "\$PWD"; printf 'LS: %s\n' "\$(ls)"
  printf 'FILES: %s\n' "\$(find . -path ./.git -prune -o -type f -print | sort | tr '\n' ' ')"
```
(excerpt ends :23; the stub heredoc continues to :33 — read)

In inline mode, generate-reports.bash does not `cd`. The stub therefore inherits bats' cwd, which is wherever `run-tests.sh` or the user ran from, normally the repo root. `find . | sort` then enumerates the entire checkout. That includes gitignored trees: `external/` alone is 388k files here. The stub serializes all of it into a single `FILES:` line (≈37 MB here) in `$CALLS/<n>`. Each test then loads that line with `call="$(cat …)"` and runs several `[[ $call == *"…"* ]]` glob scans over it. Repo- and tree-mode tests `cd` into a small temp repo and take ~50 ms, which isolates the cause. The suite's cost therefore grows with whatever sits under the developer's cwd rather than with the code under test. Here, 7 inline tests account for ~12.6 s of the 128.5 s fast gate, and each blows through the "<1s each" fast contract. The `FILES:` line is only asserted in tree-mode tests, where the temp repo is small, so the inline walk buys no coverage.

**Recommendation:** In `setup()`, `cd "$TEST_TMPDIR"` so inline-mode calls run in a tiny directory. This also makes the inline tests hermetic. Alternatively, have the stub emit `FILES:` only when `$PWD` is not the invoking test's cwd. Re-time against the 13,900 ms baseline; ~1.3 s is expected.
**Legibility-target:** for-author

#### Once any skill has generated reports, the fast gate runs every eval suite, and each `format_check` spawns a nested bats

**Severity:** Low
**Location:** `test/skills/eval-helpers.bash:134-137`
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed per-invocation bats startup) / Warm path (fast gate, conditional on reports existing)
**Confidence:** Medium
**Baseline:** one nested `bats test/skills/matrix-analysis-format.bats` against a minimal report takes 345 ms (measured in this sandbox, 2026-09-24). 58 `format_check` KEY_CHECK entries are grep-counted across `test/skills/*/expected-verdicts.bash`. The total is extrapolated, not measured.

**Evidence:**
```bash
      format_check)
        # Delegate to the format BATS suite (fact-check-format.bats or code-fact-check-format.bats)
        REPORT_PATH="$REPORT_PATH" bats "${BATS_TEST_DIRNAME}/${skill}-format.bats" || failed=1
```
(excerpt ends :137; enclosing `eval_fixture()` continues to :145 — read)

`run-tests.sh` report-gating is all-or-nothing: if *any* `test/skills/*/output/*.md` exists, every `*-eval.bats` and `*-format.bats` joins the run. All 22 new eval suites are tagged `@category fast`. The `.gitignore` change (`test/skills/*/output/`) invites generating reports for all 23 skills. After that, each health check pays roughly 58 × ~0.35 s ≈ 20 s of nested-bats startup (plus the format suites' own work) on top of the eval assertions, all inside the blocking fast pre-gate. The pattern is pre-existing for fact-check/code-fact-check, but this diff multiplies N from a handful to ~58. This is a gate-latency cost, not a correctness problem. The signal is arguably worth it. The report-gating rule itself lives in `scripts/run-tests.sh`, outside this pass's file list.

**Recommendation:** Pick one: tag the `*-eval.bats` suites `slow`, since they validate model output rather than pure functions; or leave them fast and accept the cost knowingly. Also consider running each skill's format suite once per skill (in `setup_file`) rather than once per fixture. Measure a full `--fast` run with all reports present before deciding.
**Legibility-target:** for-orchestrator-synthesis

#### arithmetic-eval-gate.bats re-extracts both heredocs from SKILL.md in per-test `setup`

**Severity:** Informational
**Location:** `test/skills/arithmetic-eval-gate.bats:16-28`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (two awk passes over one file) / Cold-ish (fast suite, 18 tests)
**Confidence:** High
**Baseline:** the whole suite takes 995 ms (measured in this sandbox, 2026-09-24), with python3 startup per `mode1`/`gate` call dominating.

**Evidence:**
```bash
  awk "/timeout 5 python3 -c '\$/ { f=1; next } /^' \\) <<'EXPREOF'\$/ { f=0 } f" \
    "$SKILL" > "$MODE1"
```
(excerpt ends :24; `setup()` continues to :28 — read)

The extraction is identical for all 18 tests and could run once in `setup_file`. The savings would be tens of ms. The suite is already under the fast contract, so this is not worth a change on its own. Noted only because it is the natural place to put the cost if the suite grows.

**Recommendation:** None needed. If the suite grows, move the extraction to `setup_file`.
**Legibility-target:** for-author

## Endorsements

- The transcript-to-report extraction makes one streaming `jq -rR 'fromjson? | select(.type == "result") | .result // empty'` pass per fixture, and a non-JSON line no longer aborts the pass and loses the report. [fact-check: claim 28 — Verified (executed)]
- Stale-sidecar handling costs one `rm -f` per fixture, and on every completed path the transcript and report are rewritten together. The fact-check's caveat (an abort after the `rm` leaves an old report with no transcript) is a correctness edge case, not a performance one. [fact-check: claim 25 — Verified (executed)]
- Tree-mode `fixture_base` copies only named files per fixture: the live rubric plus a small synthetic `base/skills/` for self-eval, and one workflow file for divergent-design. It never copies a directory from `$REPO_ROOT`, so per-fixture setup does not grow with the repo. [read: test/skills/self-eval/runner.bash:20-33, test/skills/divergent-design/runner.bash:15-18]
- The transcript checks (`assert_tool_called`, `assert_subagents_min`) each make one linear jq pass over the sidecar, with no per-line subprocesses. [read: test/skills/eval-helpers.bash:335-371]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Stub `claude` `find`s the whole cwd on inline calls; suite 13.9 s vs 1.3 s | Medium | `test/generate-reports.bats:21-23` | High |
| 2 | All eval suites join the fast gate once any report exists; ~58 nested bats via `format_check` | Low | `test/skills/eval-helpers.bash:134-137` | Medium |
| 3 | Per-test heredoc extraction in arithmetic-eval-gate setup | Informational | `test/skills/arithmetic-eval-gate.bats:16-28` | High |

## Overall Assessment

The runtime harness is performance-neutral. generate-reports.bash does constant, small setup per fixture around a minutes-long model call, and the jq and transcript passes are single and linear. The one real cost is in the tests. `test/generate-reports.bats`' stub walks and serializes the invoking directory's whole file tree on every inline-mode call. In this checkout that turns a ~1.3 s suite into ~14 s and adds ~10% to a blocking health-check gate. A one-line `cd "$TEST_TMPDIR"` in `setup()` fixes it, and the fix also makes the tests hermetic. The secondary concern is structural and belongs to the gate rather than the code: ~22 model-output eval suites are tagged `fast`, and run-tests' all-or-nothing report gating will pull them, with ~58 nested bats spawns, into every health check once reports are generated. A timed `--fast` run with all reports present would settle whether that belongs in `slow`. No profiling is needed for finding 1: the baseline and the fix are both measured.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** a markdown critique saved to /workspace/docs/reviews/performance-review-2026-09-24-skill-fixtures.md with a `Commit: 04c0746` line at the top, structured per the performance-reviewer skill, ending with a Goal-Alignment Note.
- **Answered:** I reviewed test-suite cost (timed each new fast suite and the full `--fast` run), the jq passes over transcripts, per-fixture temp repos and tree-mode base copies, and the `eval_fixture` check loops. There are three findings, and each carries a baseline.
- **Out of scope:** I did not review the fixture data, eval-criteria or expected-verdicts content (pass 2). The run-tests.sh report-gating rule is outside this pass's file list, so finding 2 names it without reviewing it. Model-call cost and latency of `generate-reports.bash` were not measured, since that would mean paid calls. Security of inline mode in a 395k-file cwd is escalated in the fact-check to security-reviewer.
- **Escalate:** Finding 2, to the orchestrator: whether `*-eval.bats` should be `slow` is a gate-policy decision and needs a timed `--fast` run with all reports present, which I did not generate.
- **Decisions I made:** I rated finding 1 Medium rather than Low. The code is test-only, but it sits in the blocking fast pre-gate and its cost is unbounded in cwd size. The 395k-file `external/` directory is specific to this environment, so a clean checkout would show a smaller gap. The gap is still O(files in cwd).
