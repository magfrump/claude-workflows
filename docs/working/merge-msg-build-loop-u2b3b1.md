Merge branch 'feat/build-loop-u2b3b1': both import walks model the host readers main's settings name

## What this does

U2b3b1 of the build-loop handoff (plan step 5, the U2b3b1 sub-bullet). Sessions
read this repository from the container (`/workspace`) and, when the image
breaks, from the host (`/home/magfrump/claude-workflows`, Q-121, Q-123). U2b3a
gave both instruction-file import walks (the self-merge floor's main walk and
`--check-fix`'s tree walk) caller reader lists but no source for them. This unit
adds that source: two keys in the default branch's `docs/dev-cycle.md`,
`Reader roots: PATH ...` (spellings of the main worktree) and
`Reader homes: PATH ...`, read by one lib function both scripts call.

**Workflow provenance:** RPI (plan revision 4, step 5) → split before code (U2b3b → U2b3b1, U2b3b2) → pr-prep.
← carried from RPI: the reader model's part (c) host alias and HOME (Q-121, Q-123), fail-closed on anything the walk cannot model, settings read from main's commit only, contract item 9, and the carried items G8, H4, D6, D7.

**Failures prevented:** a floor that lets a self-merge change a doc a host session imports as `@/home/magfrump/claude-workflows/docs/x.md` (or a container session as `@/workspace/...` when the gate runs on the host); `--check-fix` letting an in-cycle fix edit such a doc.

## Reviewer's path — start here

1. `scripts/lib/dev-cycle-read.sh` reader_settings (and readerform): the settings rules, and why every failure (a malformed line, a second copy, an unread file, no main by name) fails both walks closed.
2. `scripts/lib/dev-cycle-read.sh` import_readers: the refusal memo (D7) and the two-way re-spelling (G8) that spells every registered worktree beneath every spelling of the main worktree.
3. `docs/dev-cycle.md`: this repo's two lines, naming both sides' spellings.

## How it works

- `reader_settings` reads `docs/dev-cycle.md` from main through `main_file` and `SETTINGS_AWK`, which moved into the lib from build-loop.sh. It sets IMPORT_READER_ROOTS and IMPORT_READER_HOMES, or IMPORT_READER_WHY, and READERS_LINE.
- Each key is one exact line, as `Self-merge never:` is. Each path is absolute NAMECHARS with no empty, `.` or `..` part, so no control byte passes (D6).
- `build-loop.sh` calls it after its state gates; `--settings` prints a fifth line, `readers N-roots M-homes set|none|malformed: WHY`. `dev-cycle.sh` calls it after resolve_main (H4).
- `import_readers` refuses while IMPORT_READER_WHY is set and memoizes a refusal (D7). It re-spells the worktrees both ways (G8). `import_targets` also refuses on refused settings outside a walk.
- When the settings fail a walk, the floor and `--check-fix` say why.

## How to test

- `test/scripts/build-loop-read.bats`: "--settings: Reader roots and Reader homes give the readers line; any other form is malformed and never echoed (U2b3b1)", the five-line test, and this repo's own settings (2-roots 2-homes).
- `test/scripts/build-loop-check.bats`: "both walks take the reader lists from main's docs/dev-cycle.md, never the working tree, and a malformed line fails them" (with the floor's text and import_targets' refusal), "a caller root re-spells the worktrees registered beneath the main worktree" (both directions; fails on the one-way lib), "a refused reader set is memoized..." (fails on main's lib).
- `test/scripts/dev-cycle.bats`: "--check-fix models the host readers main's docs/dev-cycle.md names, and refuses every path on a malformed line or with no main by name".
- Suites 220/220; `scripts/health-check.sh` passed at f5d8e3ff. Over /workspace both walks give main's 128 names at 49 roots (25 before), about 1.3-1.7 s per walk.

## Areas of uncertainty

Review converged in 3 iterations; 0 Must Fix; Must Address: 3 fixed, 2 acknowledged with revisit triggers.
- Two parsers read docs/dev-cycle.md (read_settings, reader_settings) with the list-line rule written twice (override row; revisit at the next settings key or U2c).
- dev-cycle.sh runs no default_gate, so a loop that points origin/HEAD at its own branch picks the settings `--check-fix` reads (Q-103 residual, override row; the gate's `--check` runs default_gate).
- A caller that never calls reader_settings models no host reader (override row; revisit at a third walking script).
- No cap on reader roots; one alias about doubles the root count, and the work bound fails closed near 285 worktrees (override row).
- 399 code lines against the 400 cap: tests were compressed to fit.
- Deferred to U2b3b2 by the plan split: outside starts (H5, H2, C1, G9).

## Decisions made

Two keys rather than one `Reader roots:` line (so a path never needs a tag); a caller root is a spelling of the main worktree (the anchor G8 needs); no main by name fails closed.

Decisions referenced: none — change is independent of recorded decisions (plan D5/D6 and Q-121, Q-123 govern it).

## Review evidence

- `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b1.md` (iterations 1-3; loop closed at 3908e37e)
- `docs/reviews/code-fact-check-report-build-loop-u2b3b1.md` (i1), `-final.md` with `-final-r1/-r2/-r3.md` (i2), `-confirm.md` (i3)
- `docs/reviews/{security,performance,api-consistency,architecture}-review-2026-10-09-u2b3b1.md` (i1) and `-final.md` (i2); `security-review-2026-10-09-u2b3b1-confirm.md` (i3)
- 12 override-log rows dated 2026-10-09 for `feat/build-loop-u2b3b1`

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01WXq2z7f7uQu97mRuecPKLC
