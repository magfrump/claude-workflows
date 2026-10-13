Merge branch 'feat/build-loop-u3c': --cycle-diff checks the orchestrator's chore index before it commits, one raw_records reader, and a health-check lock

## What this does

U3c of the build-loop handoff (plan step 9's U3c bullet and its As-built note), in `scripts/build-loop.sh`, `scripts/health-check.sh`, a pointer comment in `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats` (T38) and `test/scripts/health-check-lock.bats` (T43, new):
- **`--cycle-diff [--answered Q-NNN]...`** (gated; `state_start`): the orchestrator's staged index against BASE, the single merge base of HEAD and main (none or several refuse: `refuse HEAD`; a criss-cross history would land through a virtual base). Prints `ok`, or `refuse PATH: WHY` lines and exit 2:
  - **Questions files**, read together, so an archive move is no change: an entry on BASE whose heading, `**Needs:**` or answer lines differ in the index (compared in file order, since `--check-answer` reads the first Needs and the first answer line) or are gone, and a new entry filed answered, unless its ID is in `--answered`. A copy `--check-answer` skips whole refuses; the verdict comes from the lib's own ANSWER_AWK, run with id `Q-`. A questions change refuses while main's questions files differ from BASE's: the land is a merge and `--check-answer` reads the merged file, where a free fence pair could capture main's newer answer. The orchestrator merges main into HEAD first.
  - **Idea log**: only appended to. **Roadmap**: the preamble and `## ` headings stay, and no brief named outside Done disappears. This is an interim reading of "the cycle's own moves", since SKILL.md step 6 rewrites Now, Next and Ideas.
  - Every other path is not judged (row 722, re-keyed to U4 with two named duties).
- **`raw_records`**: one fork-free reader for every `--raw -z` listing (check_line, log_class's chore and answers loops, `--cycle-diff`). This discharges row 724.
- **`health-check.sh`**: one run per repository. flock(1) holds `health-check.lock` in the common git dir and re-runs the script as its child with the descriptor closed (`-o`). Nothing a suite leaves running keeps the lock, and a nested run (`HEALTH_CHECK_LOCK_HELD=1`) takes none (D14, F46).

**Workflow provenance:** RPI (plan revision 4, step 9; U3c bullet written before code at 6f347256) → pr-prep: three iterations, then the iteration-4 gate's escalate to a confirming pass (Q-137 precedent).
← carried from RPI: D8, D13 and D14; F28, F33, F42 and F46; rows 722 and 724.

**Corrections to branch commit bodies:**
- f34fceb0's "re-keyed to U4" landed in d77dae74.
- 3021d0a4's "deleted entry" case came in d77dae74, and its no-exemption mutant hangs T43 rather than failing it.
- d77dae74's "A6 fails safe" was wrong (fixed in 4aad0f9c).
- ec9dace7's reason for ls-tree was wrong: the diff-tree call lacked `-r`, and its 4.3 s figure was not re-measured.
- 0f0c7e1c's "names no entry" is false for a bare `### Q-` heading, which only refuses.

## Reviewer's path — start here

1. The `--cycle-diff` block in the header of `scripts/build-loop.sh`. This is the contract U4 parses.
2. `cycle_diff`, `cyc_blob`, `QKEYS_AWK`, `QDIFF_AWK` and `ROADMAP_AWK` just above the mode dispatch, then the `cycle-diff` arm.
3. `raw_records` beside `gate_git`, and its three older callers.
4. `take_lock` in `scripts/health-check.sh`.
5. T38 (three tests near the end of `build-loop-orchestrator.bats`) and `health-check-lock.bats`.

## How to test

- Suites, run serially, 291 in all: orchestrator 24, read 20, merge 12, dispatch 4, health-check-lock 2, check 146, dev-cycle 79, fixtures 2+2. shellcheck is clean, and `scripts/health-check.sh` passes on the branch tip.
- Each mutant turns a test red:
  - base = MAIN_SHA, or sorting key lines;
  - no main-changed rule, no several-bases refusal, or no whole-copy refusal (index or base side);
  - no take_lock, or `exec 8>>` in place of `flock -o` (no exemption hangs T43).
- `--cycle-diff` on this repo's real files costs about what `--state` does (~0.8 s). `--main-log` over 1,099 commits is within noise of main.

## Areas of uncertainty

- **U4 owes** (override rows dated 2026-10-12 on this branch):
  - Commit exactly the index `--cycle-diff` read: no `-a`, no hooks, compare the trees.
  - Land only from the MAIN_SHA it checked; on the main-changed refusal, merge main into HEAD and re-run.
  - List the `--answered` IDs for the user.
  - Refuse or list GATE_CODE changes and retargeted `Asked:` lines in a chore commit.
  - Bound or read a waiting health check.
  - Point SKILL.md step 6 at the roadmap rule, and keep dated text out of the preamble.
  - Judge the land's merge-tree result. Rename pairing can carry main's edit into a questions file the index creates: Medium, Low confidence, executed, not a regression.
- **Interim /away calls** in the plan bullet: the fork-point base, and the roadmap reading.

Review converged as follows:
- **Iteration 1** (k=1): short-circuited at the fact-check. Sorting lost key-line order, and a swapped answer turned drop into keep (fixed).
- **Iteration 2** (k=1, full panel, full branch): 2 Must Address, both fixed. The land's merge could fence off a user's newer answer (executed), and the answer grammar was copied without guards.
- **Iteration 3**, the final pass (k=3 at 78% agreement, full panel): it found a behavioral Incorrect, a fenced question heading's whole-file skip (executed by two replicates). The Fact-Check Gate's "fix first" fixed it before the critics ran. The critics then found a criss-cross bypass (reproduced) and a fourth copied rule; both were fixed.
- **Confirming pass** (k=1 fact-check with 6 submitted claims, all Verified; security): no Must Fix.
- Rubric: `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3c.md`. About 14 override rows for this branch. 396 changed code lines.

Single-sample review; absence of findings is not an attestation.

Confidence: high
Notes: merged on the recommendation (Q-137 standing instruction). The confirming pass after the third iteration follows the U3a1/U3a2 precedent; D2 (rename pairing) is routed to U4 by override row.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QjZ5sDNnJpnupxpYdLDCnr
