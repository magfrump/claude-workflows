# R2: Hypothesis Pipeline Integrity Check — Plan

## Goal

Add an integrity check to `scripts/health-check.sh` that verifies four
invariants on the hypothesis pipeline files in `docs/working/`:

- (a) every approved task in the most recent round has a row in
  `hypothesis-log.md`
- (b) every TRACKING / INCONCLUSIVE row whose evaluation window is still
  open surfaces in `morning-summary.md`'s deferred-questions section
- (c) every row's Round / Task ID matches an actual completed task in
  `completed-tasks.md`
- (d) the count of rows in `hypothesis-log.md` is monotonically
  non-decreasing across rounds (catches orphan deletions)

The check fails on any mismatch. A positive test fixture under `test/`
demonstrates a known-good hypothesis row mapped to a known-good summary
line.

## Data formats

`docs/working/hypothesis-log.md` — markdown table starting at line 5:

```
| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|------------------|---------|-------------|----------|
| 1 | research-doc-freshness | ... | 3 | 4 | CONFIRMED | | ... |
| 3 | task-description-linter | ... | 3 | 6 |  |  |  |
```

Outcome values: `CONFIRMED`, `REFUTED`, `INCONCLUSIVE`,
`INCONCLUSIVE-EXPIRED`, or empty (TRACKING).

`docs/working/morning-summary.md` — sections used:
- `Rounds completed: N (rounds X-Y)` line: most recent round = Y
- `### Round Y (...)` section listing approved tasks as
  `- **task-id**: description`. `REJECTED:` lines are excluded.
- `## Deferred Evaluation Questions` section listing open hypotheses
  as `1. **task-id** (round X): "..."`.

`docs/working/completed-tasks.md` — `## Round R` headers followed by
`- **task-id**: description` bullets.

## Implementation

### `check_hypothesis_pipeline_integrity()` in `scripts/health-check.sh`

Inputs (env vars, all default to live paths under `$REPO_ROOT/docs/working`):

- `HC_HYPOTHESIS_LOG`
- `HC_MORNING_SUMMARY`
- `HC_COMPLETED_TASKS`
- `HC_HYPOTHESIS_BASELINE` (single-int file holding the highest row
  count ever observed; default `docs/working/.hypothesis-row-baseline`)

Skips with a warning if any input file is missing.

Sub-checks:

1. **Most recent round**: parse Y from
   `Rounds completed: N (rounds X-Y)`.
2. **(a) approved → log**: collect approved task IDs under `### Round Y`,
   skipping REJECTED. For each, require a row in `hypothesis-log.md`
   with Round = Y and matching Task ID.
3. **(b) open → deferred**: for each row where Outcome is empty
   (TRACKING) or `INCONCLUSIVE` (not the `-EXPIRED` variant), and the
   window is still open (`Checked at Round` empty or > Y), require the
   Task ID to appear in the deferred-questions section.
4. **(c) row → completed task**: for each row, require a `## Round R`
   section in `completed-tasks.md` containing `**Task ID**`.
5. **(d) monotonic count**: read baseline from file (default 0). If
   current count < baseline → FAIL. Else update baseline to
   `max(baseline, current)`. Auto-update is intentional and idempotent.

### Refactor: make `health-check.sh` sourceable

Wrap the bottom-of-file `main "$@"` in a guard so the script can be
sourced without executing `main`:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

This lets tests source the script and call individual check functions.

## Test fixture

`test/scripts/fixtures/hypothesis-pipeline/good/`:
- `hypothesis-log.md` — three rows: round 1 task-gamma TRACKING with
  open window; round 2 task-alpha and task-beta CONFIRMED.
- `morning-summary.md` — most recent round 2; approved task-alpha and
  task-beta; deferred section listing task-gamma.
- `completed-tasks.md` — round 1 lists task-gamma; round 2 lists
  task-alpha and task-beta.
- `baseline` — `3` (matches current row count).

`test/scripts/hypothesis-pipeline-integrity.bats`:
- Sources `scripts/health-check.sh`, sets env vars to fixture paths,
  invokes `check_hypothesis_pipeline_integrity`, asserts no FAIL output
  and that the success line appears.

## Live state and existing health-check.bats

The live `docs/working/` data has known integrity gaps (the most recent
run's approved tasks have no hypothesis-log rows; many existing rows
reference round numbers that don't appear in `completed-tasks.md` for
that ID). The integrity check correctly fails on this state — that is
the point of adding it.

To keep `test/scripts/health-check.bats` green (it asserts exit 0), its
`setup_file` will set the same env vars to the fixture paths, so the
integration test runs the integrity portion against fixtures while the
rest of the script runs against the live repo. Manual invocation of
`scripts/health-check.sh` continues to surface live integrity issues.

## File scope check

- `scripts/health-check.sh` — modify (add function, source-guard main)
- `test/scripts/health-check.bats` — modify (env vars in setup_file,
  add an assertion for the integrity section appearing)
- `test/scripts/hypothesis-pipeline-integrity.bats` — create
- `test/scripts/fixtures/hypothesis-pipeline/good/*` — create
- `docs/working/r2-hypothesis-pipeline-integrity-plan.md` — this doc

All within the declared scope.
