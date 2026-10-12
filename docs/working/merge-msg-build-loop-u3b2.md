Merge branch 'feat/build-loop-u3b2': --main-log SINCE classifies each commit that moved main as gate, chore, answers or other

## What this does

U3b2 of the build-loop handoff (plan step 9's U3b2 bullet and its as-built note), in `scripts/build-loop.sh` and `test/scripts/build-loop-orchestrator.bats` (T39):
- **`--main-log SINCE`** (gated; runs `state_start`; every read in the gate repository, so no repo config or checkout attribute changes a diff): `main MAIN N`, then one `gate|chore|answers|other SHA SUBJECT` line per first-parent commit after SINCE, oldest first; exit 2 on any other. SINCE is a full id on main's first-parent history; otherwise `main MAIN -` and `refuse main-log: WHY` (a short id is a usage error, exit 1).
  - **gate**: two parents, the exact message `--merge` writes, and a tree equal to merge-tree's clean merge of the parents (`clean_merge`; an amended merge keeps message and parents).
  - **chore**: two parents, a subject `Merge branch 'chore/dev-cycle-DATE[-HHMM]'` then the end, ` into ` or `:`, a clean-merge tree, and a changed `docs/working/cycles/cycle-*.md` (mode 100644) holding `Branch: B`. The record names its branch from inside the merge, so no caller input and no live branch are needed.
  - **answers**: one parent; only the questions files change (mode 100644); every changed line is blank, an answer line (`--check-answer`'s labels) or a header line whose Status field alone changed (matched per hunk); at least one answer line added.
- **`gate_msg`**: the one definition of the merge message, written by land and read back by `log_class` (row 662).

**Workflow provenance:** RPI (plan revision 4, step 9; U3b split before code at d1091eb8) → pr-prep, three iterations (the third the final confirming pass).
← carried from RPI: D13 (`--main-log` at each iteration's start; any other stops dispatch, F43), F19 (detects an honest slip, not a forger), row 662.

**Corrections to branch commit bodies:** 1d829fee's "only answer and Status lines" omits blank lines, which are allowed. 4afdd68b's "every near-miss commit is asserted non-empty" covers the four answers near-misses only, and its "~1.5 s" saving measured 1.6-2.6 s.

## Reviewer's path — start here

1. `gate_msg` beside `land` in `scripts/build-loop.sh`, and land's call to it.
2. `ANSWERS_AWK`, `clean_merge`, `log_class` and `main_log` just above the mode dispatch, then the `main-log` arm.
3. The `--main-log` block in the header (the contract U4 parses).
4. `test/scripts/build-loop-orchestrator.bats`, tests 9-10.

## How to test

- `bats test/scripts/build-loop-orchestrator.bats` (10). Run serially with the other suites: dispatch 4, merge 12, read 20, check 146, dev-cycle 79, hermeticity 2, git-env 2. shellcheck is clean.
- Mutation-checked: each rule removed turns test 10 red:
  - the gate message compare
  - the chore record line
  - clean_merge, in each branch
  - the added-answer requirement
  - the header-match rule
  - `main MAIN -`
  - `-` for an empty subject
- Run over a clone of this repo's main from its root: 1,119 first-parent commits, 7 s, 0 objects written. One commit, dfe4c0df, reads answers and the rest read other, which is today's hand practice.

## Areas of uncertainty

- **U4 owes** (rows dated 2026-10-12):
  - Land the chore branch with git's default `--no-ff` merge (no -s or -X, no merge config or attribute) and no hand-resolved conflict.
  - Write `Branch: B` as an unfenced line in the record.
  - Take SINCE from the newest `Main at:` line of the newest record. For the first iteration, bootstrap from the `main MAIN -` line of a refused run.
  - File other lines as one entry per iteration or per SHA.
  - List every answers commit for the user: the class trusts content (F19), so a loop's or a revert's answer line reads answers.
  - Parse class and SHA by position; SUBJECT is display only.
- **Deferred with rows:**
  - a chore merge's other paths (U3c's `--cycle-diff`);
  - three `diff-tree --raw` readers (U3c);
  - the record name pattern (U4);
  - the answer labels in two copies;
  - clean_merge beside merge_result;
  - per-commit cost and the double `state_start`.

Review converged in 3 iterations:
- 2 Must Address security fail-opens from iteration 1 were fixed: an amended merge kept its class, and an answers commit could add no answer.
- Iteration 1 was k=1 with the full panel. Iteration 2 was k=1 over the fix range, and its fact-check found a test that pinned nothing (fixed).
- Iteration 3 was the final confirming pass: k=3 fact-check, full panel, Stage 2.5. It had 0 red. Its 2 amber findings were override-row text and one test gap, both fixed after the pass, and that batch's lite check found nothing.
- Rubric: `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md`.
- Override rows: about 16 dated 2026-10-12 for this branch.
- 247 changed code lines.

Single-sample review; absence of findings is not an attestation.

Confidence: high
Notes: merged on the recommendation (Q-137 standing instruction). Two interim /away calls are recorded in the plan note: chore learned from the merge's own record, and --main-log gated.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QjZ5sDNnJpnupxpYdLDCnr
