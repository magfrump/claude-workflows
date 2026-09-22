Commit: 31f53e8

# Performance Review — answers-2026-09-20, iteration 3 (final confirmation pass)

**Scope:** `git diff 2d93589..answers-2026-09-20` (818c568, a577546, 739cbbb, fd0ad24, b951c4f, 31f53e8). Earlier branch commits are context only.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report-iter3.md` (merged, k=3). Its `## Escalations` section has no entry addressed to the performance reviewer. The si-functions escalation (Claim 26) goes to the orchestrator and concerns correctness, not cost; this review does not action it.

## Data Flow and Hot Paths

- **`hooks/guard-trusted-writes.py`: hot path.** It runs as a PreToolUse hook on every Edit, Write, MultiEdit and Bash call (`hooks/wiring.json:55`). Each call is a fresh `python3` process, so interpreter startup dominates the cost. a577546 changes only the file-tool branch (`classify_path` and `main`). The Bash branch (`bash_targets`) is unchanged by these commits.
  - Before: `classify_path` made one `resolve()` call and 3 `_is_hard` checks.
  - After: it still makes one `resolve()` (`:141`), but runs up to 5 `_is_hard` checks: 2 against `[CONFIG_DIR]` (`:146`) and 3 against `GLOBAL_DIRS` (`:152`).
  - Module-level `resolve()` and `glob` calls are unchanged.
- **`_project_state_open_hypotheses`** (`scripts/lib/si-morning-summary.sh:~400-445`): cold path. It runs once per morning summary, as one awk pass over the hypothesis log. Each row now does one extra `gsub` and a `$0` re-split. The cost stays O(rows × row length).
- **`_migrate_hypothesis_log_run_column`** (`scripts/lib/si-functions.sh:563-590`): cold path. Only the exit-code mapping changed. There is no new work.
- **`archive-working-docs.sh` loop** (`:122-150`): cold path. It runs manually or once per SI run, over `docs/working/*` (21 files today). Each file now gets one extra `[ -e ]` stat. There is also one prefix regex check per run.
- **Tests:** 5 new N1 hook tests, 1 N4 test and 2 A6 tests.

All numbers below come from `bash .../scratchpad/perf-iter3-bench.sh.txt`. The log is at `.../scratchpad/perf-iter3-bench.log`. The runs used a hermetic fake HOME, `CLAUDE_CONFIG_DIR` unset, and a scratch taint dir. They are single runs on a shared sandbox that other agents were also loading.

## Findings

#### 1. Extra `_is_hard` passes add about 5 µs per file-tool call, which is invisible next to process startup

**Severity:** Informational
**Location:** `hooks/guard-trusted-writes.py:141-153`
**Move:** Count the hidden multiplications
**Classification:** Micro (constant factor, lexical `relative_to` checks) / Hot path (every Edit/Write/MultiEdit)
**Confidence:** High
**Baseline:** 16 ms per hook invocation end-to-end, the same for the old and new hook. That is the mean of 50 spawns each, measured in this review's benchmark on 2026-09-21.
**Legibility-target:** for-orchestrator-synthesis

Evidence (the excerpt ends inside `classify_path`; the SOFT loop and `return "none"` follow at `:154-169`):
```python
    rp = _safe_resolve(p)
    cands = (p, norm, rp)
    ...
    for cand in (p, norm):
        if _is_hard(cand, [CONFIG_DIR]):
            return "hard"
    ...
    for cand in cands:
        if _is_hard(cand, GLOBAL_DIRS):
            return "hard-resolved"
```

The common case is a path that is neither HARD nor SOFT, and that path walks every pass. For it, in-process `classify_path` went from 45.1 µs to 50.7 µs per call (+5.6 µs, about 12%). HARD paths cost the same as before: 26 µs and 36 µs in both versions. The number of `resolve()` syscalls did not change; it is still one per call. Against a 16 ms process spawn, the delta is about 0.03%. The end-to-end mean did not move at the resolution measured.

The extra checks are lexical only. `_rel_under` does `relative_to` over at most 2 dirs, so the cost cannot scale with filesystem depth or the size of any directory.

**Recommendation:** None needed. If hook latency ever matters, the lever is the per-call `python3` startup, which the hook's architecture fixes in place. Adding back or removing `_is_hard` passes will not move it.

#### 2. The new archive collision skip runs after the per-file `git grep`, so skipped files still pay for it

**Severity:** Informational
**Location:** `scripts/archive-working-docs.sh:133-143`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro / Cold path (manual or once-per-SI-run archive)
**Confidence:** High
**Baseline:** 26 ms for one `cited_by` `git grep` over this repo, measured in this review on 2026-09-21. `docs/working/` holds 21 files.
**Legibility-target:** for-author

Evidence (the excerpt ends inside the loop body; the dry-run/`mv` branch and `count` increment follow at `:144-150`):
```bash
  dest="$ARCHIVE_DIR/${PREFIX}-${name}"
  cites="$(cited_by "$name")"
  if [ -n "$cites" ]; then
    echo "  warn  $name is still cited by: $cites — add it to PERMANENT if it has graduated" >&2
  fi
  if [ -e "$dest" ]; then
```

A file that will be skipped still pays one full-repo `git grep` first (`cited_by` itself is not new code). At 21 files, the worst case (every file colliding) wastes about 0.5 s in a cold path. The "still cited" warning does have value for a skipped file, since the file stays in `docs/working/`. So the current order is defensible for what the operator sees. Only the cost is at issue.

**Recommendation:** Leave it. If `docs/working/` grows to hundreds of files, batch `cited_by` into one `git grep` over all names. That fixes a pre-existing O(files × repo) pattern, which matters more than the ordering here.

#### 3. The five N1 tests take about a quarter of the hook suite's wall time

**Severity:** Informational
**Location:** `test/hooks/guard-trusted-writes.bats:440-513`
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold path (test suite, but it counts against the health-check time budget in Q-023)
**Confidence:** Medium. These are single runs under shared load.
**Baseline:** `test/hooks/guard-trusted-writes.bats`: 58 tests in 6675 ms. The N1 subset (`bats -f '^N1:'`) took 1718 ms. Both were measured in this review on 2026-09-21.
**Legibility-target:** for-author

Evidence (`:449-450`; the excerpt ends inside the nested loop, and the jq decision assertion follows at `:451-452`):
```bash
    for f in hooks/foo.sh hooks/new.sh CLAUDE.md settings.json; do
      guard "$(file_payload Write "$TEST_TMPDIR/proj/.claude/$f" "$s")"
```

Each N1 test loops over 2 taint states × 4 paths, which is 8 hook spawns plus 16 or more `jq` spawns. The five tests together take about 340 ms each, against a suite average of about 115 ms. That is roughly 26% of this file's time for 9% of its tests. In absolute terms it adds about 1.7 s. The health-check bats budget recorded in Q-023 is 42–60 s (fact-check Claim 5 measured 49–63 s), so this is about 3% of that budget. The matrix gives real coverage: clean and tainted runs across every HARD entry, which is exactly the invariant N1 fixed.

**Recommendation:** Keep it. If the suite budget tightens, keep the matrix and cut the per-assertion `jq` spawn: check the decision with a shell `[[ $output == *'"deny"'* ]]` match. The hook spawn is irreducible.

## Endorsements

- The N4 fix keeps `_project_state_open_hypotheses` a single linear awk pass. It adds one `gsub` and a re-split per row, and no extra subprocess or second pass over the log. `[read: scripts/lib/si-morning-summary.sh:402-445]`
- `_migrate_hypothesis_log_run_column`'s change maps exit codes only. The detection awk still `exit`s on the first header row, so the scan stays O(1) in log length for a well-formed log. `[read: scripts/lib/si-functions.sh:563-590]`
- The archive prefix validation is one bash regex match per run, outside the loop. `[read: scripts/archive-working-docs.sh:50-55]`
- a577546 adds no `resolve()`, `glob` or filesystem call per invocation beyond the single `_safe_resolve(p)` the pre-fix hook already made. `[unverified — submitted as claim]`. This review compared the two `classify_path` bodies by reading them. The timings in Finding 1 are consistent with that, but they are not a syscall trace.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Extra `_is_hard` passes: +5.6 µs/call vs a 16 ms spawn | Informational | `hooks/guard-trusted-writes.py:141-153` | High |
| 2 | Collision skip comes after the per-file `git grep` | Informational | `scripts/archive-working-docs.sh:133-143` | High |
| 3 | N1 tests take ~26% of the hook bats file's time (~1.7 s) | Informational | `test/hooks/guard-trusted-writes.bats:440-513` | Medium |

## Iteration-2 🟡 status (performance lens)

None of these items was a performance item. The table records whether each fix changed cost, and whether it resolved the item as far as this domain can see.

| Item | View | Basis |
|------|------|-------|
| N1 | resolved; perf-neutral | The fix is behavioural. Fact-check Claims 12b, 12c, 13 and 20 verify it. Finding 1 measures a +5.6 µs/call cost. The bare-host deny of `global-instructions/CLAUDE.md` (Claim 15) is outside this domain. |
| N4 | resolved; perf-neutral | Claim 27 verifies it. The awk pass stays linear (Endorsement 1). |
| N5 | still-open; no perf surface | Claim 29b: the ancestor-symlink comment is still Incorrect. |
| N6 | acknowledged / partly resolved; no perf surface | Claim 10 (Mostly accurate): the HARD_FRAG and `CLAUDE_CONFIG_DIR` token triggers are still undescribed. |
| N7 | resolved | Claim 4 (the pin is correct). The "fixed" wording is partial for R1. |
| N8 | resolved | Claim 30. |
| N9 | resolved; perf-neutral | Claims 25, 26 and 28. The exit code 3 change adds no work. The `\x1e` note is Mostly accurate (pass-through). |
| N10 | resolved | Claims 16 and 5. The timings are roughly accurate, and exceeded once under contention (63 s). |
| A6 remainder | resolved (prefix validation, no-overwrite), with residue | Claims 23 and 24. The no-overwrite guarantee does not hold for a dangling-symlink destination. The regex copy count is now 4 (Claim 3, settled Defer; noting only that the recorded count is stale). The perf cost is Finding 2 (Informational). |
| A12 remainder | resolved via N4 | Claim 27: all three readers now split consistently. |

## Overall Assessment

The performance posture is neutral. Nothing in these six commits changes an algorithm's complexity class, adds per-call I/O on the hook's hot path, or adds a pass over any growing data set. The one hot-path change adds lexical `_is_hard` checks. It costs a measured ~5.6 µs per file-tool call, next to a ~16 ms interpreter spawn that dominates hook latency and is unchanged. The remaining items are cold-path or test-time observations. None calls for a change before merge. No profiling is needed to confirm them: the numbers are direct measurements, though single-run and taken under shared load.

## Goal-Alignment Note
- Success criterion (restated verbatim): A performance critique saved to /workspace/docs/reviews/performance-review-2026-09-21-answers-iter3.md with `Commit: 31f53e8` on the first line, structured per the performance-reviewer skill, every finding carrying Evidence and Legibility-target, plus the iteration-2 status table and a Goal-Alignment Note.
- Answered: the hook's per-call cost after a577546 was measured in process and end-to-end, old against new, hermetically. The awk/sed changes in `_project_state_open_hypotheses` and the si-functions migration were read and judged linear or unchanged. The archive loop change was costed. The runtimes of the new bats tests were measured. The iteration-2 status table is included.
- Out of scope: the correctness and security of the hard-resolved deny (Claims 15 and 19), and the si-functions abort-after-merge behaviour (Claim 26, an orchestrator escalation). Also out of scope are the Bash branch (`bash_targets`), which these commits do not touch, and the pre-existing per-file `cited_by` pattern beyond noting it.
- Escalate: none. All timings are single runs on a shared sandbox. If a stricter number is ever needed, Finding 3 and the Q-023 budget should be re-measured on an idle host.
