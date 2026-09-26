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
- `docs/2026-0[3-9]-*` (33 documents, rescued 2026-09-26) — handoffs, DD
  records and experiment results that `archive-working-docs.sh` had swept
  into the gitignored `docs/working/archive/` while tracked files still cited
  them as evidence: decisions 014–033, `skills/code-review/SKILL.md`, the
  Gate 1h comments, the triage doc's parent handoff, and the SWRBench fork
  handoff. Each keeps its sweep-date prefix. Citations from `docs/reviews/`
  and `runs/` were left as written, because those are records of their day.
- `docs/2026-09-26-workflow-selection.md` and
  `docs/2026-09-26-workflow-dependency-graph.md`, formerly in `docs/`. These were a
  third and fourth copy of the routing tree, with no live reader. The first
  ordered rows differently from `global-instructions/CLAUDE.md` and lacked
  rows 2, 4 and 5. The second said "18 skills" and claimed that most workflows
  invoke no skills. The live tree is in the global instructions, expanded by
  `guides/workflow-selection.md`.
- `failure-analysis/` — `scripts/failure-analysis.sh` and its test, archived
  2026-09-21 (Q-046): no callers, and its re-attempt pass rate disagreed with
  the documented definition. Its README records the fix if it is ever revived.
- `docs/2026-09-21-claude-api.md` — a flat-file "supplement" to the bundled
  `claude-api` skill, formerly `skills/claude-api.md`. Archived by Q-033: as a
  flat file the harness never loaded it as a skill (skills load from
  `skills/<name>/SKILL.md`), and its body carried none of the reference
  material its description promised. The bundled `claude-api` skill covers the
  topic; if a real supplement is wanted, build it as
  `skills/<name>/SKILL.md` under a name that does not shadow the bundled one.
