# Archived: failure-analysis.sh

Archived 2026-09-21 per Q-046 (answered 2026-09-20: "[2] Delete it and its
test"; moved here rather than deleted per the Q-021 archive-over-delete
convention).

`scripts/failure-analysis.sh` summarized `docs/working/round-history.json`
(most-rejecting gates, most-failing task-id prefixes, re-attempt pass rate) and
said it was "for use in DD preambles", but nothing ever called it except its
own test.

Why it was retired rather than fixed: its re-attempt pass rate used its own
definition, not the documented one — it counted attempts after approvals and
after null verdicts, and ordered attempts by a round number that restarts every
self-improvement run. It reported 16% where the documented definition gives
39%. With no consumer, fixing the semantics would mean maintaining a script
nothing reads.

If a DD preamble ever wants the number, the fix is: count only attempts that
follow a rejection, skip null verdicts, and order by timestamp (or by the
hypothesis-log Run column) instead of round number.

Contents:
- `scripts/failure-analysis.sh` — the script. It sources
  `$SCRIPT_DIR/lib/preflight.sh`, which does not exist here; copy the script
  back to `scripts/` before running it.
- `test/failure-analysis.bats` — its bats suite. Outside `test/`, so
  `scripts/run-tests.sh` no longer collects it.
