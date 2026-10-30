Merge branch 'feat/build-loop-u5': the build-loop handoff's docs as built, Q-103 re-routed with its residuals, the U5 entries and the release entry

## What this does

U5, the last unit of the build-loop handoff (plan steps 11-13), makes the docs describe what was built and files what the user decides next:
- **`docs/dev-cycle.md`** describes the settings as `build-loop.sh --settings` reads them: the policy (still `review (interim; Q-103)`, read as unset), `Build-loop slots: 3`, and an interim `Self-merge never:` line wider than the plan's `workflows/`. Review found that sessions here also read `skills/`, `guides/` and `patterns/` from the checkout, that the orchestrator's health check executes `scripts/`, `test/`, `hooks/` and `devcontainer-config/`, and that the release paste runs install.sh before showing its diff (override row 682). "Not built yet" is gone. No `Review handoff:` line: nothing reads one. Test: `test/scripts/build-loop-read.bats` "--settings on this repo's own docs/dev-cycle.md" asserts the never and slots lines.
- **`workflows/codebase-onboarding.md` step 13** drops "a planned unit". It says self-merge needs a never line, and asks for `docs/constraints.md`.
- **Decision log row 72** records D1-D14, what the gate cannot do, and the D10 override with the user's answers 1, 5, 8 and 9. It is row 72 because rows 70 and 71 were taken after the plan was written. The seed is superseded, and two research gotchas are corrected.
- **`skills/dev-cycle/SKILL.md`**: step 0.1's `image-lag` entry is the release entry. It lists every first-parent commit and changed path since the image's commit, flags self-merge subjects (F58), and withholds unsafe subjects and paths. Step 10 names the constraints entry's slug and files it once.
- **Questions**:
  - Q-103 goes to `you: judgment` with "what the gate can and cannot do" and the residuals F11, F19, F21, F29, F35, F37, F58, F59, R8 (with `answer`), plus eleven more the override log routed to it.
  - New entries: Q-149 (how wide the never line is), Q-150 to Q-152 (C1-C3; the built defaults are the interims), Q-153 (C4) and Q-155 (no constraints doc, so no dispatch here).
  - Q-154 (C5) is filed answered and archived.
  - Q-156 `image-lag` is the `you: terminal` release paste. It pins M=8cff4877 and refuses replace refs, grafts, a non-global `core.attributesFile`, or any released tree that differs from M.
- **Roadmap**: items (a) to (g), with (f) in Next and the rest in Ideas (Next holds five). An idea for install.sh's archive gaps. The handoff moves to Done. The brief's Status is `done`.

**Workflow provenance:** RPI (plan revision 4, steps 11-13) → pr-prep: three review iterations, the last a full confirming pass, then a narrow k=1 check of its fix batch.
← carried from RPI: D2, D5 (the never line), D10 (row 72), D12 (C5), F58 (release entry), Q-140 [1] (the image is the gate), and the plan's list of Q-103 residuals.

## Reviewer's path — start here
1. `docs/working/questions.md`, Q-103 and Q-149: the two policy choices this unit hands the user, and what the gate leaves open.
2. `docs/dev-cycle.md`: the settings as the scripts read them, and why the never line is this wide.
3. `docs/working/questions.md`, Q-156: the release paste to run on the host once this merges.

## How to test
- `bats -f "own docs/dev-cycle.md" test/scripts/build-loop-read.bats`
- `scripts/build-loop.sh --settings` in a throwaway repo with this `docs/dev-cycle.md` on main. It reads `policy review unset`, `slots 3 set` and the never line set, and with the policy flipped, `policy self-merge set`. Run by me and by every fact-check replicate.
- `scripts/questions.sh check`.
- Q-156's checks with install.sh stubbed, in throwaway clones. Run by three replicates and two security passes. Cases: the merged main, a docs-only change, another branch, a replace ref, grafts, `.gitattributes` or released-tree drift, and `core.attributesFile` in the local, worktree and include scopes.

## Areas of uncertainty
- **The loop ended at `escalate`.** The narrow check after the final pass found one more Medium in Q-156's paste: a `core.attributesFile` in `config.worktree`. It is fixed in 3718bcd0 with the reviewer's executed form, but that fix has not been re-reviewed.
- **install.sh's own archive gaps are deferred** (security i2 F2, final F1, narrow F1; override rows; roadmap Ideas). It follows replace refs and a repository-scope `core.attributesFile`, and its state gate misses both. This is a decision-035 boundary change. The payload diff is the backstop.
- **Q-156's M is a branch commit**, not the merge, so the paste works after the merge. Step 0.1's own rewrite uses main's commit.
- **The never line is the fail-closed interim**: self-merge here can land only unprotected docs, `README.md`, `runs/`, `archive/` and new top-level names. Q-149 asks for the width.
- **Q-IDs 149-156 came from main b279a2ba.** A concurrent dev-cycle branch may mint the same IDs; renumber on merge if it does.
- **Health check**: each full run failed one fast test in `build-loop-check.bats` (931, then 951), and both pass alone. This is the Q-145 `/tmp` race: the log shows `find: '/tmp/tmp…': No such file or directory`. The slow suites ran directly: 300/300.
- Commit bodies 2846f9fa, 771a5d02, c63da94d, 659a1c61, b5eaedf6 and 1a3d432a carry wording the next commits corrected (override rows; history not rewritten).

## Decisions made
Decision log row 72. Decisions referenced: 035 (install.sh's trust model), log rows 62, 68, 70 (renumbered to 72), 71.

## Review evidence
- Rubric: `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md`
- Fact-check: `code-fact-check-report-2026-10-14-u5-i1.md`, `-i2.md`, `-final.md` (merged k=3), `-final-r1/r2/r3.md`, `-narrow.md`
- Security: `security-review-2026-10-14-u5-i1.md`, `-i2.md`, `-final.md`, `-narrow.md`
- API consistency: `api-consistency-review-2026-10-14-u5-i1.md`, `-i2.md`, `-final.md`
- Override log: 7 rows dated 2026-10-14 for `feat/build-loop-u5`

Review: 3 iterations plus a narrow check. 1 Must Fix (i1) resolved; the Must Address items were fixed, except two deferred install.sh items and the commit-body rows. Loop decision: escalate (the merge is the orchestrator's call). The performance critic was skipped as copy-only.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01VZuSDQi7wutN9sUY4jH4vA
