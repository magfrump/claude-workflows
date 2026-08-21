# Archived: Code Review Bench (CRB) machinery

Archived 2026-08-20. This directory holds the benchmark pipeline retired from
active use when the project refocused on the production review-fix loop (see
`docs/decisions/log.md` row 37 and decisions 029–034 for the history).

Why archived rather than deleted: the decision records and measurement docs
cite this code, and the SWRBench fork (a separate standalone project — see
`docs/working/handoff-swrbench-fork.md`) is the living home for benchmark
work. If any of this is needed again, migrate it there rather than reviving
it here.

Contents:
- `scripts/` — the CRB pipeline: canon→benchmark conversion, cell
  orchestration, egress verdicts, artifact harvest, leaderboard subset math,
  and the cross-model `review-arms.py` sweep driver. `crb_common.py` is the
  shared module; scripts import it relative to their own directory, so they
  still run from here.
- `test/` — the bats suites for the above. They are outside `test/`, so
  `scripts/run-tests.sh` no longer collects them. Path caveat: the egress and
  run-host suites reference `runs/review-arms/crb-pipeline/…` paths that now
  live in `crb-pipeline/` below; fix paths before running them from the
  archive.
- `crb-pipeline/` — the containerized sweep host (`run-host.sh`,
  `prepare-sweep.sh`, docker/ with the egress-allowlisted proxy). Formerly at
  `runs/review-arms/crb-pipeline/`. The per-PR result cells that lived
  alongside it were unfinished sweep output and were deleted, not archived.

NOT archived (still live in `scripts/`): `cross-model-review.py` (the
decision-030 Stage-1 harness, still used by the DD cross-model sweep) and
`dd-cross-model-sweep.py`. The production lightweight reviewer is
`scripts/lite-review.py` (subscription-backed; log row 37).
