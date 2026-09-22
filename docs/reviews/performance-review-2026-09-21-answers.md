Commit: 654c0ed

# Performance Review — branch `answers-2026-09-20`

**Scope:** `git -C /workspace diff e8d5fa1..answers-2026-09-20` (32 commits, 50 files). Code focus: `scripts/health-check.sh` gate 5, `scripts/lib/si-morning-summary.sh` run-scoped lookups, `scripts/lib/si-functions.sh` Run-column migration and append, `scripts/questions.sh`, `hooks/guard-trusted-writes.py`, plus the review-loop doc edits (`workflows/pr-prep.md`, `workflows/review-fix-loop.md`, `skills/code-review/**`).
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report.md` (merged Stage-1 report). Also cites per-suite wall-clock timings the orchestrator recorded in the session scratchpad (`timing2.tsv`, 19:42, sequential `bats <file>` per suite at HEAD; `fast.time` and `slow.time`, earlier `run-tests.sh` runs). All timings were taken while other review agents were running, so read them as order-of-magnitude figures.

## Data Flow and Hot Paths

- **`health-check.sh` gate 5 (cold, but heavily used).** Someone runs this by hand before committing. The global instructions name it as the gate for `questions.sh check` in this repo. Nothing in `scripts/`, `hooks/` or the SI loop calls it. The SI loop's own `tests` gate still runs `bats test/` directly (`scripts/self-improvement.sh:544,1273`), and this diff does not touch that gate. Before the diff, gate 5 ran only `test/skills/*.bats` and `test/hooks/*.bats`. It now runs `run-tests.sh --fast` (76 suites) and, only if that passes, `run-tests.sh --slow` (12 suites), with `HEALTH_CHECK_SKIP_BATS=1` set so nested health-checks skip gate 5. Its cost is wall-clock, and the price is what the user named in Q-023 option [2]: "You stop running it because it's slow".
- **`si-morning-summary.sh` (cold).** Runs once per morning summary. For each open deferred script-evaluator row (tens of rows, growing with rounds × runs), it calls `_resolve_hypothesis_target` → `_find_tasks_file` and `_days_since_round`. Each candidate file costs one `jq` fork, and the number of archived copies per round number grows linearly with the number of SI runs.
- **`si-functions.sh` append/migration (cold).** Runs once per SI round: one `awk` header probe over the hypothesis log, plus a one-time rewrite of the log.
- **`guard-trusted-writes.py` (hot, per tool call).** A PreToolUse hook on `Edit|Write|MultiEdit|Bash` (`hooks/wiring.json`), so it pays a fresh `python3` start on every matched tool call. The diff adds two `Path.resolve()` calls at import time (`_global_dirs`) and one more alternation in `HARD_FRAG`/`SOFT_FRAG`.
- **`questions.sh` (cold).** Adds one `git rev-parse` fork per invocation.

## Findings

#### 1. Gate 5's slow set re-runs the whole non-bats health-check three times, so one top-level health-check does the other 13 gates' work four times

**Severity:** Medium
**Location:** `scripts/health-check.sh:380-391` (check_bats; enclosing function runs :365-391 — read); `test/scripts/health-check.bats:24-33,118-140` (`_run_and_cache` in `setup_file`, plus two negative tests that each `run bash "$SCRIPT"`)
**Move:** Count the hidden multiplications
**Classification:** Macro (work multiplied by the suite graph, not by data) / Cold path (a manual pre-commit gate, but its latency decides whether it gets run at all)
**Confidence:** High on the structure, Medium on the per-run split
**Legibility-target:** the gate-5 comment block at `scripts/health-check.sh:343-363` and the header of `test/scripts/health-check.bats`
**Baseline:** `test/scripts/health-check.bats` took 405.3 s of the slow set's 441.4 s total, and the fast set took 102.9 s total, measured per-suite at HEAD (`timing2.tsv`, orchestrator scratchpad, 2026-09-21 19:42, under concurrent load).

Evidence, verbatim:

```
    if ! HEALTH_CHECK_SKIP_BATS=1 "$runner" --fast; then
        fail "Fast BATS suites failed — slow suites not run (fix fast first)"
        return
    fi
    pass "Fast BATS suites passed"

    if HEALTH_CHECK_SKIP_BATS=1 "$runner" --slow; then
```
(excerpt ends :387; check_bats continues to :391 — read.) And in the test file:

```
setup_file() {
  _run_and_cache
}
...
  HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"
...
  HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"
```

`health-check.bats` is tagged `@category slow`, so the new `--slow` call runs it. It then runs `health-check.sh` three times in full: once to cache output, and once for each of the two negative frontmatter tests. The recursion guard skips gate 5 in those runs but not gates 1–4 or 6–14, which include the shellcheck sweep over every `.sh`/`.bats` file. The four gate-5 stub tests are sub-second. That puts roughly 135 s on each nested run (405 s ÷ 3, inferred), and it is about 92% of the slow set. A top-level health-check now costs about one non-bats pass, plus ~103 s fast, plus ~441 s slow, which is about 11 minutes, and roughly 400 s of that repeats checks the outer run is already doing. The recursion guard was a correct fix for an infinite loop. It stops the recursion without removing the repeated work.

**Recommendation:** Pick one. (a) Stop running `health-check.bats` from inside gate 5, either by excluding it (the outer run *is* the health-check integration test) or by having `run-tests.sh` honour a skip list. (b) Better: the diff's new `BASH_SOURCE` guard (`:1064-1066`) now lets tests source the file, so the two negative tests can call `check_skill_frontmatter` directly instead of the full script. Either change cuts ~270–400 s. Re-measure against the 405.3 s baseline.

#### 2. The "fast" blocking pre-gate is half one 51 s suite, so "fails in the fast-suite time" is ~100–150 s, not the <1 s-per-suite the tag promises

**Severity:** Low
**Location:** `scripts/health-check.sh:343-347` (the claim), `scripts/run-tests.sh:14-15` (the tag contract), `test/init-firewall-rules.bats` (`@category fast`)
**Move:** Find the work that moved to the wrong place
**Classification:** Micro-to-macro (one mis-tagged suite) / Cold path
**Confidence:** Medium
**Legibility-target:** the `--fast` flag description in `scripts/run-tests.sh`
**Baseline:** `scripts/run-tests.sh --fast` took 2:34 total wall clock (`fast.time`, orchestrator scratchpad, 2026-09-21), and `test/init-firewall-rules.bats` alone took 51.4 s (`per-suite.txt`).

Evidence, verbatim: `#   --fast  Run only fast tests (pure function tests, <1s each)` and `# set is a blocking pre-gate: if it is red, the slow ... so a broken tree fails in the fast-suite time rather than after the multi-minute slow set.` The diff did not create the mis-tag. It does make the fast set load-bearing as a blocking pre-gate, and one suite is about half of that set's cost (`cc-isolated-functions` 11 s, `hermeticity-lint` 10 s and `fixture-hermeticity` 10 s make up most of the rest).

**Recommendation:** Retag `init-firewall-rules.bats` as slow, or add a middle tier. Whichever you choose, make the gate-5 comment's "fast-suite time" claim match what was measured.

#### 3. `_find_tasks_file` emits the same candidate paths twice when a run id is given, and `_days_since_round` repeats the lookup without the run id

**Severity:** Informational
**Location:** `scripts/lib/si-morning-summary.sh:1170-1190` (`_find_tasks_file`, read in full), `:1349` (`_days_since_round` fallback; enclosing function :1329-1377 — read)
**Move:** Count the hidden multiplications
**Classification:** Micro (≤2 extra `jq`/`head` forks per row) / Cold path (morning summary, once per run)
**Confidence:** High
**Legibility-target:** the `_find_tasks_file` header comment
**Baseline:** no baseline available — flagged as speculative

Evidence, verbatim:

```
    done < <(if [ -n "$run" ]; then
                 printf '%s\n' "$working_dir/archive/${run}-tasks-round-$round.json"
                 _live_run_matches "$working_dir" "$run" \
                     && printf '%s\n' "$working_dir/tasks-round-$round.json"
             fi
             printf '%s\n' "$working_dir/tasks-round-$round.json"
             _archived_newest_first "$working_dir/archive" "tasks-round-$round.json")
```

When the run's copy does not contain the task id, the live file and `archive/<run>-tasks-round-N.json` each get `jq` twice: once from the run-scoped prefix and once from the fallback scan, which also matches `*tasks-round-N.json`. Separately, `_days_since_round` (:1349) calls `_find_tasks_file "$round" "$tid" "$working_dir"` without `$run`, so it re-runs the newest-first scan, costing O(archived copies) `jq` forks, for a row whose file `_resolve_hypothesis_target` already found. That second scan predates this diff. What is new is that the diff passes `$run` to one call site and not the other, which is inconsistent. At tens of rows it is not a problem. Cost grows as rows × archived runs.

**Recommendation:** Pass `"$run"` at `:1349`. If it is cheap to do, skip fallback candidates that the run-scoped prefix already tried. Both are one-line changes, and the second call also returns a more accurate run.

#### 4. Pre-existing: `WRITE_PRIMITIVE`'s inline-interpreter alternative scales quadratically in the number of interpreter words on a line (not introduced by this diff)

**Severity:** Informational
**Location:** `hooks/guard-trusted-writes.py:118-119` (unchanged by the diff; `bash_targets` and `main` read to :200)
**Move:** Check the asymptotic behavior
**Classification:** Macro (O(k·L) backtracking) / Hot path (every Bash call), but the adversarial-only input is written by the agent itself
**Confidence:** High
**Legibility-target:** the `WRITE_PRIMITIVE` definition
**Baseline:** a 40 KB command made of 5,000 `python3 ` words took a median of 795.5 ms per hook invocation, against 20.6 ms for a short command (15-run medians, `scratchpad/perf_hook_time.py`, 2026-09-21, under concurrent load). The pre-diff hook measured 783.9 ms and 18.8 ms on the same inputs.

Evidence, verbatim: `r"|\b(python[0-9.]*|node|perl|ruby)\b[^\n]*\s-[ce]\b"  # inline interpreters`. Each interpreter-word start scans to end of line and then backtracks. This is recorded because the requested focus was regex cost on the per-call path. The diff's own regex additions are linear alternations and cost nothing measurable (see Endorsements). Realistic commands contain one or two interpreter words, so this does not bite in practice.

**Recommendation:** No action is needed for this branch. If it matters later, anchor it with `[^\n]*?` or split the command on newlines and test `-c`/`-e` separately.

## Endorsements

- The fast set gates the slow set: when fast is red, `check_bats` returns before starting `--slow`, so a broken tree never pays the ~441 s slow set. `[read: scripts/health-check.sh:380-391]`
- The Run-column migration check on every append is a single `awk` pass that `exit`s at the first header row, so its per-round cost does not grow with log length. The full rewrite runs only once, when the header lacks `Run`. `[read: scripts/lib/si-functions.sh:547-567]`
- When a row carries a Run cell, `_find_tasks_file` tries the exact `archive/<run>-tasks-round-N.json` path first and returns on the first hit, skipping the newest-first scan whose cost grows with the number of archived runs. `[read: scripts/lib/si-morning-summary.sh:1170-1190]`
- The hook's per-call cost changed very little: `_global_dirs()` (two `resolve()` calls) and the regex compiles happen once per process, and the measured median on short Bash/Edit inputs rose from ~18.8–20.4 ms to ~20.6–21.9 ms. Python start-up dominates. `[unverified — submitted as claim]` (measured with `scratchpad/perf_hook_time.py` under concurrent load; the fact-check report did not cover it)
- `pr-prep.md` step 3 now links to rules owned by `review-fix-loop.md` and code-review's SKILL.md instead of restating them, which reduces how much text each review-fix iteration loads. `[read: workflows/pr-prep.md diff hunks for steps 3b, 3d, 3e]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Gate 5 slow set re-runs non-bats health-check 3× (~400 s of an ~11 min gate) | Medium | `scripts/health-check.sh:380-391`, `test/scripts/health-check.bats:24-140` | High |
| 2 | "Fast" pre-gate is ~50% one 51 s mis-tagged suite | Low | `test/init-firewall-rules.bats`, `scripts/run-tests.sh:14-15` | Medium |
| 3 | Duplicate candidates, plus a run-less second `_find_tasks_file` scan | Informational | `scripts/lib/si-morning-summary.sh:1170-1190,1349` | High |
| 4 | Pre-existing quadratic `WRITE_PRIMITIVE` on many-interpreter lines | Informational | `hooks/guard-trusted-writes.py:118-119` | High |

## Overall Assessment

The hot-path code is sound. The hook change adds about 1–2 ms on top of a ~20 ms Python start, and the morning-summary and migration changes are cold and bounded. The doc changes do not add review passes. The stricter "qualifying author note" rule could keep a few more 🟡 rows open for an extra iteration, but that trades attention for correctness and is not a performance cost. The finding that matters is structural and easy to fix. The Q-023 change turns health-check into a roughly 11-minute gate, and most of that time is `health-check.bats` re-running health-check itself three times. This is the "you stop running it because it's slow" outcome the user named in Q-023. Fix it on this branch with Finding 1(b), which is small: source the script and call the one check, which the new `BASH_SOURCE` guard already allows. Then re-time `run-tests.sh --slow` against the 441 s baseline. Once that is done, a single uncontended timing run of the whole health-check would confirm the per-run split, which this review inferred (≈135 s per nested run).

## Goal-Alignment Note

- **Answered:** all six requested focus areas. Gate 5 wall-clock is quantified from the orchestrator's timing files. The `_find_tasks_file` family's fork counts were traced through every caller. The si-functions migration and append, the `questions.sh` `$PWD` resolution (one extra `git` fork, too small to file), and the hook's import-time `resolve` and regex cost were measured by a 15-run subprocess benchmark against the pre-diff hook. The review-loop doc edits were checked.
- **Out of scope:** security behaviour of the new hook tiers (security-reviewer's), and correctness of the SI_RUN_ID / `questions.sh` resolution. I did not re-run health-check or the full suite, per the brief. The ≈135 s per nested health-check run is inferred from 405 s ÷ 3, not measured. One side observation for the orchestrator: `docs/working/questions.md:54` still lists Q-023 as `Status: OPEN` although commit 0ccbdb8 implements it.
- **Escalate:** none. Finding 1 is the only one worth acting on before merge, and it is the user's call because it trades gate latency against the Q-023 coverage decision.
