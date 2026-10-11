Merge branch 'feat/build-loop-u3d': --start and --prompt dispatch a build loop on a locked worktree and print its prompt

## What this does

U3d of the build-loop handoff (plan step 7's U3d bullet and its as-built note), in `scripts/build-loop.sh` and the new suite `test/scripts/build-loop-dispatch.bats`:
- **`--start BRIEF [--dir DIR]`**: after the state gate and gate_start, with `--settings`' constraints ok, the brief open, under `DISPATCH_CAP` (4) dispatches and no worktree holding the branch, it creates the branch at main's commit by a create-only `update-ref` and adds a worktree locked at add time (`build-loop dispatch of STEM at TIP, UTC TIME`; default `.claude/wt-STEM` in the main worktree; `--dir` absolute, readerform). It prints `ok BRIEF BRANCH DIR`, `dispatched N`, then the loop prompt; a refusal leaves no branch or worktree it made.
- **`--prompt BRIEF [--dir DIR] [--steal]`**: re-dispatches an existing branch: adds a locked worktree when none has it, else relocks the one that has it. A lock is taken without `--steal` only when its loop has ended: the tip is a handoff marker, past (a descendant of, and not equal to) the tip the lock records. Otherwise only `--steal`, with the lock's time and the tip's commit time both over `STEAL_AGE` (2 hours). A missing or symlinked worktree, or one whose path readerform refuses, refuses.
- **One dispatch at a time**: both modes hold a flock on `build-loop-dispatch.lock` in the git common directory for all of dispatch (children do not inherit it); a second run refuses retryably; a lock path that is not a plain file refuses.
- **The prompt** carries every plan "Prompt content" item: the evidence line, the `cd DIR &&` rule, the brief at main's commit, the policy, the constraints quoted, DD's Path A / blocked rule, the force-added research doc, the three markers and the blocked-body rule (D11), subagent and scratch-dir limits, never sending the branch to a remote (worded so for T20), the own-brief Status rule, no plan-approval gate, `--check` advisory, the floor the orchestrator applies (row 622), and never moving the branch below the dispatch commit.
- **CONSTRAINTS** as a value (row 270). The state gate now runs for every mode but `--settings` and `--status`.

**Workflow provenance:** RPI (plan revision 4, step 7; U3 split before code at d5736445) → pr-prep, three iterations plus a confirming pass on the final fix batch.
← carried from RPI: D1 (orchestrator starts loops, lock and steal, dispatch cap on the brief), D2 (constraints required, Path A / blocked), D3 (markers), D11 (body grammar), D14 (subagent limits); rows 270, 622; T19, T24, T40, T41, T44.

**Corrections to branch commit bodies:** aff39758's Notes say "a lock without a build-loop time is never taken": any lock reason ending " UTC TIME" is read (row, A6), and its "a locked one is taken only with --steal" predates the marker rule and the missing-worktree refusal; 23ba4511's A4 "match the code" missed floor's "below" category (fixed in ad5ff2d5), and its promise that A6 is corrected here is kept by this paragraph; 525f947a's "Mutation-checked" lists no mutants (later commits name theirs); d4d178d9's "a working tip under an old lock" means a current lock taken at an earlier tip.

## Reviewer's path — start here

1. The `start|prompt)` arm at the bottom of `scripts/build-loop.sh` (the flock), then `dispatch`, `ended`, `steal`, `wt_of`.
2. `loop_prompt`'s text against the plan's "Prompt content" list.
3. The `--start` / `--prompt` header paragraphs, then `test/scripts/build-loop-dispatch.bats` test 4 (the lock lifecycle).

## How to test

- `bats test/scripts/build-loop-dispatch.bats` (4 tests); serially with the other build-loop suites: merge 12, read 20, check 146, dev-cycle 79; hermeticity 2 + 53; shellcheck clean. Every behavioural fix was mutation-checked against its test.
- Executed by reviewers: concurrent dispatch (6 rounds, one ok each), lock-file shapes (FIFO, dangling link, directory, links, mode 000), submodule.recurse during worktree add (git 2.39.5 runs nothing), the marker / re-dispatch / rewind sequences.

## Areas of uncertainty

- **Q-103 residuals**: a hostile same-uid loop can edit lock reasons, the worktree registry or its own tip times; the lock makes the honest path safe (two orchestrators, a repeated re-dispatch step), it does not contain a hostile loop.
- **A loop that rebases onto a newer main** keeps its lock until `--steal` after 2 hours (the prompt forbids moving below the dispatch commit; pr-prep merges).
- **U4 owes**: relaying `--start`/`--prompt` output rather than copying the prompt; writing `Dispatched: N`; telling the two retryable refusals apart by their fixed text.
- **Deferred with rows**: wt_of and land's two worktree parsers (row 663's trigger, now U3b), CONSTRAINTS read from its line, gate_start's unneeded steps (~0.26 s), the prompt restating code-owned rules (U3b's `--marker`), untested arms (symlink, readerform on an existing path, `--prompt`'s constraints rule, WT_PRUNE, `9>&-`), submodule configs unread by the state gate.

Review converged in 3 iterations plus a confirming pass; 1 Must Fix resolved (A1, a missing locked worktree dispatched into), 5 Must Address resolved (B1 marker re-dispatch, B2 concurrent dispatch, C1 a second re-dispatch taking a live lock, C2 an unborn checkout, D1 a rewind ending a live loop). Iteration 1 short-circuited at fact-check (k=1); iteration 2 k=1 full panel; iteration 3 the final pass, k=3 full panel with Stage 2.5 routed to the confirming pass (k=1 fact-check + security over the fix batch, 0 Incorrect, S1-S4 Verified). Rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3d.md`. 15 override rows dated 2026-10-10 for this branch. 343 changed code lines. Single-sample review; absence of findings is not an attestation.

Confidence: high
Notes: merged on the recommendation (Q-137 standing instruction); the B1, C1 and D1 lock rules are design calls taken by DD Path A within D1/D3, recorded in the rubric.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018X78L3ajw3rXEbwmifV4wc
