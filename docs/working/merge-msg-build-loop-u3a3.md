Merge branch 'feat/build-loop-u3a3': --merge --approved Q-NNN lands a brief of either policy under the N rules once its merge entry is answered [1] on main

## What this does

U3a3 of the build-loop handoff (plan step 7's U3a3 bullet), in `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh` and their suites:
- **`--merge BRIEF --expect SHA --approved Q-NNN`**: check_line runs the N rules alone (no S rules, no checkout refusal; `--expect` still binds the full tip), then `approval` reads Q-NNN from main's commit through check_answer: it must say `keep` (option 1) under the heading exactly `Q-NNN · merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when a changed path, lower-cased, matches GATE_CODE. Then `land approved Q-NNN`: message "(build-loop approved merge)", trailer `Build-loop-approved: Q-NNN`, reflog "build-loop: approved merge of STEM".
- **One authority value** (`AUTH`: self-merge or approved) decides check_line's rules and land's message, trailer and reflog (row 653); the review-policy refusal names `--approved` (row 661). Refusals say which answer was read (open, option 2, option 3, not read as an option, or the skip's reason) or the heading required.
- **GATE_CODE** gains `^skills/dev-cycle/` (plan D4, F52): the skill will carry the D6 snippet. It is one list for floor and `--approved`, so the self-merge floor now also refuses any `skills/dev-cycle/` path: stricter than plan D5 item 3, which lists the scripts alone.
- **Lib**: check_answer sets `ANSWER_HEADING` (the entry's heading; `--check-answer` output unchanged); floor sets a word in FLOOR_WHY and `floor_why` words it (row 472); truthwalk sets `TRUTH_WHERE` when a walk fails, so check_fix no longer writes the reader-settings sentence itself (rows 630, 634; the tree walk says where only for a refused reader set).

**Workflow provenance:** RPI (plan revision 4, step 7) → U3 split before code (d5736445) → pr-prep, three iterations.
← carried from RPI: D4 (merge entries, the merge-gate- slug for gate files), D8 (answers read from main's commit), T35, F33/F52; rows 221, 472, 630, 634, 653, 661.

**Corrections to branch commit bodies:** a7a4f784's "TRUTH_WHERE for both walks' failures" holds for the tree walk only when the reader set is refused; e25a6e89's "the skill that carries the D6 snippet" means will carry (U4 adds it); 71e5c62d's subject says "review artifacts", which went to 7bb52fcd.

## Reviewer's path — start here

1. `approval()` and the `merge)` case at the bottom of `scripts/build-loop.sh`, then the `--merge` header paragraph and refusal list.
2. check_line's `sm`/gate lines and land's message lines.
3. `test/scripts/build-loop-merge.bats` tests 8-12 (T35), then the lib's floor/floor_why/truthwalk/check_answer hunks.

## How to test

- Suites, serially: build-loop-merge 12, build-loop-read 20, dev-cycle 79, build-loop-check 146; shellcheck clean. Under `bats -j` or beside other /tmp-churning processes, some walk tests flake on the known config_seeds `find` vanish (override row); each passes on rerun.
- Stage 2.5 executed: a deletion-only gate change needs merge-gate-; a main moved to a [2] answer at read time makes the swap refuse; main's and HEAD's --check give identical output on a 19-path self-merge brief but for skills/dev-cycle/.

## Areas of uncertainty

- **The heading pins 48 bits of TIP**; `--expect` binds the full tip, so U4's orchestrator must pass the full TIP it filed the entry for, never the branch's live tip (override row, trigger U4).
- **Approved merges skip the floor** (plan line 213): instruction files, dot paths and sibling skills land under a plain merge- entry; U4's entry body should list them with floor_why reasons (rows). `--check` does not print the heading `--approved` will accept (row, U4).
- **Q-103 residuals**: the answer word read back from a temp file (row); `scripts/health-check.sh`, which the cycle runs from main, is outside GATE_CODE and the floor (pre-existing, routed to U5).
- Plan D5 item 3 still lists only the scripts; the plan's U3a3 bullet records the widening.

Review converged in 3 iterations; 1 Must Fix resolved (skills/dev-cycle/ as gate code), 6 Must Address resolved or acknowledged with revisit triggers (A1 and A4 deferred to U4/U5). Iteration 1 k=1 full panel; iteration 2 k=1 on the fix range; iteration 3 the final confirming pass, k=3 full panel with Stage 2.5. Rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a3.md` (loop closed at 01a2935f; doc-class items fixed after it in 71e5c62d, fix-drift run). 12 override rows dated 2026-10-10 for this branch. 349 changed code lines. Single-sample review; absence of findings is not an attestation.
