# Idea log

Seeds from any step of the dev cycle (`skills/dev-cycle/SKILL.md`, "Seeding is always on"),
one line each, unranked. Each `## Brainstorm` heading marks where a brainstorm read up to.

- Record host vs container in the usage log, so "sessions drift back to the host" and per-session denial counts become countable (signal: cycle 2026-10-02, decision 015 T4 and 014 T1 both "cannot tell" for lack of the field)
- Tune or act on the doc-freshness check: 7 of 7 tracked docs are stale, 0 fresh, one by 67 commits (signal: cycle 2026-10-02 health check, check 11)
- Fixtures for the skills that have none, dev-cycle first (signal: cycle 2026-10-02 health check, check 9 lists 10 skills)
- Replace or retire the dev-cycle idea source `docs/working/feature-ideas*.md`: its only file is a March 2026 DD whose survivors have mostly shipped (signal: cycle 2026-10-02 step 5, file last committed 2026-03-23)
- Bare `bats` in this container shows 5 false reds from the unset locale; `run-tests.sh` pins it, but subagents reach for `bats` directly (signal: cycle 2026-10-02 step 4, spot-check of 7387d8f1)
- Ask the author to adjudicate the ~6 Contested-Soundness rubric rows, the only way 028's precision-guard trigger can be decided (signal: cycle 2026-10-02 step 2, 028 T3 near threshold, "cannot tell")
- `guides/README.md` index line for cc-isolated-usage.md omits cc-push and the exit scan (signal: cycle 2026-10-02 step 4, spot-check of 7387d8f1)

## Brainstorm 2026-10-02

First brainstorm (none recorded before). Signals read: this cycle's steps 1–4, the seeds above,
the idea source `docs/working/feature-ideas.md` (nothing new: its survivors are built or
already on the roadmap), and the roadmap's existing Ideas. Surviving ideas, as filed in the
roadmap's Ideas:

1. Usage log records host vs container (seed 1). Changes: three decision triggers become decidable.
2. Freshness check: refresh the 7 stale docs or loosen the heuristic (seed 2). Flag for `divergent-design` if both are viable: refresh, tune threshold, or per-doc path narrowing.
3. Fixtures for dev-cycle and the other 9 unfixtured skills (seed 3). Waits behind Q-067 (report regeneration) for the report-dependent half.
4. Retire the stale idea-source row in `docs/dev-cycle.md` (seed 4). Changes: step 5 stops reading a finished DD.
5. Author adjudication of Contested-Soundness rows (seed 6). Changes: 028 T3 becomes decidable.
6. Do nothing on direction: Next already holds five user-ranked items and the open judgments; this brainstorm adds no re-ranking.

Dropped: seed 5 (bare-bats locale) as an idea on its own — the remedy is "use `run-tests.sh`", already the documented runner; noted in the cycle record instead. Seed 7 folded into the doc-drift brief.
- Give the three 2026-10-02 briefs `Branch:` lines or close them, so `--status` stops skipping them (signal: all three skipped as "no Branch: line"; they hold every slot)
- List unmerged `chore/dev-cycle-*` branches and the entry IDs they add in the digest (signal: Q-162 to Q-177 lived only on `chore/dev-cycle-2026-10-15-0357`; `next-id` printed Q-149, which is in use)
- Prune worktrees whose branch is merged (signal: 35 registered worktrees, 12 on merged branches)
- Set a locale the image has, so the scripts stop printing setlocale warnings (signal: three `LC_ALL` warnings on every D6 call)

## Brainstorm 2026-10-15

Triggers: roadmap Now holds 0 items ready for a brief; 13 days since the last brainstorm.

1. Close or migrate the pre-handoff briefs (seed 1). Changes: frees the 3 slots for dispatch once U5 lands.
2. Show unlanded cycle branches in the digest (seed 2). Changes: no parallel stream of asks goes unseen; next-id stops colliding.
3. Prune worktrees on merged branches (seed 3). Changes: smaller reader set for the import walks, less disk.
4. Fix the image locale (seed 4). Changes: cleaner gate output.
5. Do nothing on direction: Next keeps the user's order. Q-178 (land the 0357 stream) is the step that unblocks the most.
