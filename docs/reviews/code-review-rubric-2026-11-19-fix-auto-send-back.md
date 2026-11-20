# Code review rubric: fix/auto-send-back (2026-11-19)

Brief: `docs/working/briefs/2026-11-19-auto-send-back.md`. Range: `a0ef9528..HEAD`. Diff: prose in `skills/dev-cycle/SKILL.md` steps 7 and 10, one `sect` text pin in `test/scripts/build-loop-orchestrator.bats`, research doc `docs/working/research-2026-11-19-auto-send-back.md`.

Critics: none dispatched in any round (prose plus a text pin, no enforcement file, no script reads `Applied:`). This is a coverage gap: no security, performance or API-consistency critic looked at the branch.

## Rounds

| Round | Range | Fact-check | Must-fix | Should-fix | Nits | Verdict |
|---|---|---|---|---|---|---|
| 1 | a0ef9528..244ca278 | k=1 | 0 | 5 (A1-A5) | 7 | fix and re-review |
| 2 | a0ef9528..ace29e75 | k=3 | 0 | 3 (S1-S3) | 8 | fix and re-review |
| 3 | a0ef9528..ecde92f1 (scoped to ecde92f1) | k=1 | 0 | 0 | 3 (Consider) | clean: merge |

## Final rubric

| Area | Rating | Evidence |
|---|---|---|
| Spec and brief coverage | green | All "What to write" bullets and acceptance criteria on all three gate routes (self-merge `--merge`, review `--check`, `--merge --approved`) |
| Consistency with build-loop.sh output | green | Conflict text (build-loop.sh:1582), `refuse ... failure-pattern gaps` (:1608), gap texts in `fp_gaps` (:1511-1564) |
| Tests | green | `build-loop-orchestrator.bats` 52/52; `convention-migrations`, `build-loop-free`, `build-loop-check`, `questions-doc`, `hermeticity-lint` pass; every pinned phrase fails the test when deleted |
| Research doc claims | green | Round 1 and 2 false or stale claims corrected |

## Open items (Consider, not blocking)

- C2: two phrases still unpinned ("(an approved merge's: its `Q-NNN=redispatch`)" and the library-path phrase).
- N-f: the migration gap is labelled the owner's, as the spec says, though its gate text also offers a skip line.
- N-g (pre-existing): a refused approved merge outside this route records no `Applied:` action, so `--check-answer` can read that ID again. A follow-up for a later cycle.
