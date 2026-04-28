# Scope exception: r1-round-history-json-deprecation

**Date:** 2026-04-28
**Task:** Complete soft deprecation of `docs/working/round-history.json` (superseded by `round-changelog.md` per R12).
**File scope:** `docs/working/round-history.json` and other files under `docs/working/`.

## Discovery

The task assumed two paths:
1. If zero references exist → delete the file.
2. If references exist → update them to point at `round-changelog.md`, or add a top-of-file pointer note.

Neither path is executable within scope as written.

### State of the file

`docs/working/round-history.json` is **not present in the repo** and has **never been tracked in git** (`git log --all -- docs/working/round-history.json` returns nothing). It is a runtime artifact: `scripts/self-improvement.sh:186-189` initializes it with `echo '[]' > "$ROUND_HISTORY"` on each run, and SI tooling reads/writes it during a round. There is nothing to delete and nothing to annotate — the file only exists transiently in working trees that have run the SI loop.

### State of the references

`grep round-history.json` across the repo turns up references in three categories:

**Active runtime consumers** (would break if file is renamed/removed without code changes):
- `scripts/self-improvement.sh` — initializes, writes, and reads the file each round.
- `scripts/lib/si-functions.sh` — `record_gate()` and history accessors default to this path.
- `scripts/flag-removal-candidates.sh` — auto-detects round number from this file.
- `scripts/failure-analysis.sh` — reads it to summarize failures for DD preambles.
- `scripts/lib/si-morning-summary.sh` — reads it for the morning summary.

**Tests guarding the data contract:**
- `test/round-report-schema.bats` — schema guard for `round-history.json` (skips if not present).
- `test/round-log-functions.bats` — exercises `finalize_round_log` writing to it.
- `test/scripts/self-improvement-smoke.bats`, `test/scripts/failure-analysis.bats` — smoke and analysis tests.

**Historical doc references** (mention the file by name, not actionable):
- `guides/validation-gates.md`
- `docs/reviews/code-review-r2-convergence.md`, `docs/reviews/code-review-round2-context.md`, `docs/reviews/draft-review-round2-context.md`
- `docs/working/round-changelog.md` (already notes that it replaces `round-history.json`)

All of these files sit outside the granted scope (`docs/working/`).

## Why this is blocked

Completing the deprecation requires one of:

1. **Migrate active consumers** to write `round-changelog.md` (or a successor structured artifact) instead of `round-history.json`. This is a non-trivial refactor of the SI tooling: the JSON file is structured/queryable (jq is used heavily); the changelog is human-prose markdown. They are not drop-in substitutes. This touches `scripts/`, `scripts/lib/`, and several `.bats` tests.

2. **Update historical doc references** to use past tense or point readers at `round-changelog.md`. Plausible within a doc-only scope, but those files (`guides/`, `docs/reviews/`) are outside this task's grant.

3. **Add a top-of-file pointer note** to the JSON itself. Not possible: JSON has no comments, and the file is overwritten on every SI run, so any marker would be transient.

## Recommendation

The "soft deprecation" framing in the task description treats this as trivial cleanup, but the JSON file is still load-bearing for the current SI loop. Real deprecation needs a follow-up task with broader scope:

- **R-next (SI rewrite track):** Per `feedback_si_noninteractive.md` and `project_si_rewrite_needed.md`, the SI system is slated for a ground-up rewrite. The deprecation of `round-history.json` should ride along with that rewrite, not precede it as standalone churn. Until then, the file is *named* deprecated (R12 declared `round-changelog.md` the primary record) but functionally still required.
- **Doc-only follow-up (in scope of a guides/docs PR):** A smaller task could update `guides/validation-gates.md` and the `docs/reviews/` mentions to clarify that `round-history.json` is a transient SI artifact and `round-changelog.md` is the canonical history. That work should be scoped to those files explicitly.

No edits made under `docs/working/` other than this scope-exception record and the summary file.
