# Archive

Things retired from active use and kept anyway, because something still cites
them or because the schema is worth more than the space.

**This is the tracked archive.** `docs/working/archive/` is a different thing
entirely — it is gitignored scratch that `scripts/archive-working-docs.sh`
sweeps self-improvement-run output into, so moving something there removes it
from the repo. When the triage router's ARCHIVE route
(`docs/working/triage-2026-09-17-backlog.md` §3.1, amended 2026-09-17 by Q-021)
says archive, it means here.

Layout: one directory per retired thing, each with its own README saying when
and why it was archived and what replaced it. Single documents live under
`docs/` with a `YYYY-MM-DD-` prefix.

- `benchmark/` — the Code Review Bench pipeline, archived 2026-08-20 when the
  project refocused on the production review-fix loop. See its README; the
  living home for benchmark work is the SWRBench fork.
- `docs/2026-09-17-incident-journal.md` — the failure incident journal, 0
  entries against its own "≥3 entries within 3 rounds" criterion. Dormant
  because unfed, not wrong: its only input is Tier-3 skill recovery during
  loop rounds, and the loop is dormant. `guides/skill-recovery.md` step 4 tells
  its next writer to copy this file back to `docs/working/incident-journal.md`
  rather than starting over, which is the whole reason it was archived instead
  of deleted.
