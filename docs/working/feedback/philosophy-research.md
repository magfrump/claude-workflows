# Harness feedback

Project: philosophy-research

### F-001 · digest-misses-watching-file
**Feature:** dev-cycle digest (questions.sh open) · **Date:** 2026-10-29 · **Verdict:** fails

- **Context:** the first dev-cycle iteration after migration `questions-owner-routes-040` had moved every `deferred` entry out of `docs/working/questions.md` into `docs/working/watching.md` (`64c8e850`).
- **Expected:** the digest's section 3, "Watched questions (trigger and deferred routes)", lists the open `deferred` and `trigger` watches, which now live in `watching.md`.
- **Observed:** section 3 printed "None open" while `watching.md` held three OPEN `deferred` entries (Q-058, Q-079, Q-091). The image's `cmd_open` runs `parse_entries "$LIVE"` only, and `dev-cycle.sh` filters that output for the two watch routes, so the watches the migration moved are never seen. Step 3 was done by hand from `watching.md`.
- **Evidence:** `/opt/claude-workflows/scripts/questions.sh` `cmd_open`; `/opt/claude-workflows/scripts/dev-cycle.sh` lines 408–415; the image's manifest commit is `fe57e35`; the record is `docs/working/cycles/cycle-2026-10-29.md`, iteration 2026-10-30-0050, step 3.

### F-002 · cycle-cannot-create-feedback-file
**Feature:** dev-cycle path rules vs. the global harness-feedback instruction · **Date:** 2026-10-29 · **Verdict:** friction

- **Context:** the same iteration found F-001 and went to file it here, as the global instructions' "Harness feedback" section asks, but the project had no `docs/harness-feedback.md` yet.
- **Expected:** a harness failure found during a cycle can be recorded in the project's feedback file within that cycle.
- **Observed:** the dev-cycle skill lets an in-cycle fix edit only a file that `--check-fix` prints `ok` for, and `--check-fix` refuses every new file. So the cycle could not create the file. The finding went to the roadmap's Ideas and the idea log instead, and the owner created the file by hand (`72e3e6ea`).
- **Evidence:** the dev-cycle skill's "Paths from repo text" rule; `docs/roadmap.md` Ideas ("Report to claude-workflows that the digest's watched-questions section misses `watching.md`"); `72e3e6ea`.

### F-003 · brainstorm-refires-same-trigger
**Feature:** dev-cycle step 5 (brainstorm) · **Date:** 2026-10-29 · **Verdict:** friction

- **Context:** two iterations ran 10 minutes apart (2026-10-30-0040 and -0050 UTC), and Now held no item ready for a brief in either.
- **Expected:** a brainstorm runs when it can produce new ideas.
- **Observed:** "Roadmap Now holds 0–1 items ready for a build brief" fired again in the second iteration with Now unchanged, so the brainstorm ran twice on one day for one signal. The second added one idea, and that idea came from that iteration's own finding (F-001), not from the trigger.
- **Evidence:** `docs/working/cycles/cycle-2026-10-29.md`, both iterations' `5.` lines; `docs/working/idea-log.md`, the two `## Brainstorm 2026-10-29` headings.
