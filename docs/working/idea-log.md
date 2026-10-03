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
