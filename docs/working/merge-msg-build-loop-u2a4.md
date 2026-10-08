Merge branch 'feat/build-loop-u2a4': the self-merge floor, over one read-as-truth rule and one start predicate for both import walks

## What this does
`scripts/lib/dev-cycle-read.sh` gains the floor: `floor PATH STEM STATUS` answers whether a build loop may never self-merge a changed path, and why (`FLOOR_WHY`). It refuses, in order:
1. `truthrule`'s denials, shared with `--check-fix`: an upper-case letter (the path could not be lower-cased), an instruction or prompt file (`isstart`), a dotfile or dot-directory, the dev cycle's own files, `docs/dev-cycle.md`, `docs/constraints.md`, and `docs/decisions/` or `docs/human-author/`.
2. Gate code (`GATE_CODE`: `scripts/build-loop.sh`, `dev-cycle.sh`, `questions.sh`, `scripts/lib/`).
3. `docs/thoughts/`.
4. `docs/working/` and `docs/reviews/` files that are not the brief's own (`ownfile`).
5. Anything main's import walk reaches (`truthwalk main`), or every path when that walk fails.

`check_fix` (`scripts/dev-cycle.sh`) now calls the same `truthrule` and `truthwalk`; its answers are main's on every tracked path.

Both walks share one start rule, `isstart`: instruction files plus `.md` files under `.claude/rules/`, `commands/`, `agents/`, `output-styles/` and `skills/` at any depth (override rows 370, 435). A prompt file's `@` names also resolve against the top level and the directory holding each enclosing `.claude/` (`prompt_dir`, `prompt_bases`), as Claude Code resolves a command's names against the session. The parser reads quoted `@"…"` mentions whole, across lines, untrimmed too and before a `#L5`/`#section` suffix. The main walk fails on a link or gitlink at or below a `.claude/` start directory, at `.claude`, or naming a directory.

The lib header now holds the numbered gate caller contract (items 1-8) U2b and U2c follow, and `import_reset` clears both walk caches. Both walks pop their queue by index (row 461).

**Workflow provenance:** RPI (plan `docs/working/plan-build-loop-handoff.md`, step 5, U2a4 bullet) → pr-prep's review-fix loop.
- Iteration 1 (k=1, full panel, d7cdc1ea): A1-A6 fixed.
- Iteration 2: short-circuited on one red (a doubled `.claude/` lost a base), fixed.
- Iteration 3, the final pass (k=3, full panel, Stage 2.5, 2b6f2f91): no red; two Medium security under-reads and a Low performance regression, fixed in 2f9464d3.
- Q-131 [1]: cap waived; a confirming pass (k=1 fact-check plus security) found one Medium regression in 2f9464d3's quoted reader (`#L5` suffix) and Lows, fixed in 185e92f1.
- Q-132 [1]: a security-only pass over 185e92f1; nothing Medium or above (one fail-closed Low kept with an override row, two Informational), so it lands.

**Failures prevented:** a loop self-merging an edit to a file sessions load as instructions, to gate code, to another brief's records, or to a doc that a `.claude/commands/` or `.claude/rules/` file imports.

## Reviewer's path — start here
1. `scripts/lib/dev-cycle-read.sh` header: the gate caller contract, items 1-8.
2. `isstart`, `START_LINK`, `prompt_dir`, `prompt_bases`: the one start rule and the session bases.
3. The comment above `import_targets`, then `IMPORT_AWK`'s `scan`, `quoted` and main rule: the superset claim and the quoted reader.
4. `truthrule`, `truthwalk`, `ownfile`, `GATE_CODE`, `floor`.
5. `check_fix` in `scripts/dev-cycle.sh`.
6. `test/scripts/build-loop-check.bats`, tests 69 onward.

## Status
- **Done:** the floor, the shared rule, the start predicate, the caller contract.
- **Next:** U2b (`--check`, the reader model, contract items 2-4) and U2c (floor's first caller, contract item 5).
- **Blocked-on:** nothing.

## How to test
`TMPDIR=$(mktemp -d) bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`: 180 ok (79 + 19 + 78 + 2 + 2). `scripts/health-check.sh` passed on the branch; see the merge commit's check.

## Areas of uncertainty
- **Size:** 599 changed code lines against main (lib 342, dev-cycle.sh 22, tests 235), over decision log 62's ~400; waived by Q-131 [1]. Most of the growth is the prompt-file layer the reviews asked for.
- **Untraced against Claude Code:** whether command expansion calls the quoted-mention reader, and whether `agents/`, `output-styles/` and `skills/` expand `@` at all. Both are read as a superset (more refusals, never fewer).
- **Deferred, with override rows:** an unclosed `@"` followed by about 90 KB with no `"` fails the walk (Low, fail-closed: the floor then refuses everything); a quoted name holding an NBSP is read with a blank (Low); about 256 nested `.claude/` levels fail `env` (fail-closed); a blank-free run of about 2,000 characters in a prompt fails closed once per base.
- **Carried to U2b/U2c:** outside-repo starts and sessions started elsewhere (the reader model), the attribute and `core.symlinks` refusal, the clean-worktree check, `FLOOR_WHY` as a word, floor's per-path cost.

Reviews: `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md` (iterations 1-2) and `code-review-rubric-2026-10-08-feat-build-loop-u2a4.md` (final pass and both confirming passes), with their reports.

Confidence: high
Notes: merged at the user's answer Q-132 [1], after a security-only pass over 185e92f1 found nothing Medium or above.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RpCwAjFw1koJKyFEoMFKWY
