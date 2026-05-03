- **Goal**: Add a "Contrastive note" subsection to each round in the morning summary that pairs one approved + one rejected task addressing a similar problem and uses a tiny LLM call to record what differed; skip when no clear shared-problem pair exists.
- **Project state**: r3 SI task on `feat/r3-r3-si-contrastive-pairs-note`; only `scripts/lib/si-morning-summary.sh` may be modified (plus this plan doc). No prior contrastive-pair logic exists in the SI loop.
- **Task status**: in-progress (planning)

## Design

Mirror the existing two-stage pattern used by `_score_task_legibility` (cache + claude) and `_summary_task_legibility` (render):

1. **Compute (per round, idempotent)**: `_compute_contrastive_pair <round> <working_dir>`
   - Cache file: `docs/working/contrastive-note-round-N.json`. Skip if the file exists and parses (so re-runs don't re-invoke claude).
   - Read approved + rejected ids from `round-N-report.json`. Read task descriptions, files_touched, and category from `tasks-round-N.json`. Annotate rejected tasks with their first failing gate.
   - Skip cache (`{"skip":true,"reason":...}`) if either verdict list empty, claude CLI absent, or report/tasks files absent.
   - Otherwise call `claude -p` once with both lists and a strict JSON output contract:
       - Pair found → `{"approved_id":..., "rejected_id":..., "note":"<1-2 sentences>"}`
       - No clear pair → `{"skip":true,"reason":"<short>"}`
   - On unparseable response → write skip cache.

2. **Render (per round)**: `_emit_contrastive_note <round> <working_dir>`
   - Read cache; emit `**Contrastive note** (approved **<id>** vs rejected **<id>**): <note>` line.
   - Skip silently when cache says skip / cache missing / fields blank.

3. **Wiring**: at the end of each round's block in `_summary_whats_new` (after the rejected list loop), call compute then emit. Both no-ops gracefully when prerequisites are missing, so existing fixtures keep working.

## Why this placement
- The morning summary IS the priorities-handoff surface (planner reads `docs/working/` artifacts in subsequent rounds; the per-round section is the natural place for an observation specific to that round).
- Putting compute + render side-by-side per round mirrors how task-legibility is structured.
- Cache JSON file lives alongside other per-round artifacts (`round-N-claim.json`, `task-legibility-${tid}.json`) so a future planner-read enhancement can ingest it directly without parsing markdown.

## Risk / fallbacks
- Claude unreachable / unparseable: skip silently. No risk of breaking the morning summary.
- Tasks file missing (legacy rounds): skip silently.
- Single-verdict rounds: skip silently.
- Idempotent cache prevents repeat token spend on re-generation.
