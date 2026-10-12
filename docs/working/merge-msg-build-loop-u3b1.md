Merge branch 'feat/build-loop-u3b1': --state checks the gate's state and the caller's git settings; --marker quotes a blocked or stopped marker's body safely

## What this does

U3b1 of the build-loop handoff (plan step 9's U3b split note and its as-built note), in `scripts/build-loop.sh` and the new suite `test/scripts/build-loop-orchestrator.bats`:
- **`--state`**: the gate's state half alone (`state_start`, which `gate_start` now calls first): `ok`, or `--check`'s `refuse state WHAT: WHY` lines and exit 2. First, read only here, a snapshot of the caller's git settings (`caller_gate`): a repo-local git variable but the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX (`stray_vars`, shared with checkout_gate), and a caller pair for a key the state gate refuses or one `HARDEN` sets, whatever its value. A caller git setting that stops git or the script first (a non-decimal GIT_CONFIG_COUNT, which harden now refuses in every mode; a GIT_DIR naming no repository) exits 1 with stderr only. default_gate also refuses a default branch whose ref names an annotated tag (row 656), testing the ref itself, so land's re-run leaves a concurrently moved main to the compare-and-swap.
- **`--marker BRIEF`** (ungated, as `--status`): `ok BRIEF SHA` and the blocked or stopped marker's body, scrubbed, cut to 100 lines of 300 bytes (a character never split) with a quoted note, every line `> `-led. It skips a marker commit over 64 KiB (its body not processed), a body line that starts like questions-entry grammar after blanks, quotes and list markers (any case), holds `<!--` (questions.sh's index markers) or is not strict UTF-8 (as questions.sh check decodes it), a line FENCE_AWK refuses in the body as printed, bare or quoted, and an empty blocked body. `BODY_RULE` is one string the loop prompt and the skip line share (row 689).

**Workflow provenance:** RPI (plan revision 4, step 9; U3b split before code at d1091eb8) → pr-prep, three iterations (the third the final confirming pass).
← carried from RPI: D11 (the orchestrator heads every entry; a loop body is quoted data), D13 (`--state` at each iteration's start, F51), pre-mortem E2/E3 (both questions readers on the orchestrator's own lines: T34's quoted-body case); rows 247-311, 493, 494, 517, 525, 656, 666, 689, 690 as the plan note settles them.

**Corrections to branch commit bodies:** ec9ba0c7 says GIT_GRAFT_FILE and the object directories "name files the state gate never reads": GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY move info/grafts and objects/info/alternates, which it reads (the code comment is right since 8f99a919); its "anything but a commit" means an annotated tag (a tree or blob is not found by name). 8f99a919 says the cap skips a marker "unread" (marker_kind has read the commit; the body is not processed), "valid UTF-8" (Perl's decoder, replaced by a strict match in 8367359f) and that land's re-run leaves a moved branch to "the compare-and-swap" (or W's fast-forward).

## Reviewer's path — start here

1. `caller_gate`, `stray_vars` and `HARDEN` near the top of `scripts/build-loop.sh`, then the startup lines (`GATED`, the `--state` call before `state_gate`) and `state_start`.
2. `marker` and `BODY_RULE` (the perl rule and cut, then the two FENCE_AWK passes).
3. `test/scripts/build-loop-orchestrator.bats` (8 tests), and the one added case in `build-loop-merge.bats` (B4).

## How to test

- `bats test/scripts/build-loop-orchestrator.bats` (8); serially with the other build-loop suites: dispatch 4, merge 12, read 20, check 146; dev-cycle 79; hermeticity 2, git-env 2; shellcheck clean. `scripts/health-check.sh` passed on the branch tip ee8edc7f (All checks passed).
- Mutation-checked: each new rule removed turns its test red (the `<!--` rule, strict UTF-8 against Perl's decoder, the size cap, the quoted FENCE pass, the HARDEN key match, the tag check, the old MAIN_SHA compare in land's re-run, caller_gate in every mode, the T34 body unquoted). The strict UTF-8 match agreed with Python's strict decode on about 1.27 M fuzzed inputs (three replicates).

## Areas of uncertainty

- **U4 owes** (rows dated 2026-10-12): start each iteration with `--state` from an environment without U3b3's git_harden pairs exported, and read any exit but 0 or 2 as stop-and-quote-stderr; run the orchestrator's own git through the script or a hardened wrapper (`--state` is a snapshot of what this script's hardened reads trust); route `--marker` skips by their fixed WHY; write its own one-line question under the Needs line before pasting the body (index summary), and paste the body as data.
- **Deferred with rows**: questions.sh's own marker anchoring (`<!--` refused here closes the loop path), scrub's 4096-byte cut splitting a character in a long non-ASCII line (fails closed), rows 281/311/666 to U3b3, row 696 (git upgrade).
- Pre-existing, outside this unit: `/workspace/.git/config` sets `core.hooksPath`, so every gated mode, `--state` included, refuses in the main checkout itself (filed as a question).

Review converged in 3 iterations; 1 Must Fix resolved (C1, a non-strict UTF-8 rule, from the iteration-2 short-circuit), 8 Must Address resolved and 1 acknowledged with a revisit trigger (B9, refusal by key whatever the value: U3b3/U4). Iteration 1 k=1 full panel; iteration 2 k=1 fix range, short-circuited at fact-check; iteration 3 the final confirming pass (k=3 fact-check, full panel): 0 red, 0 amber, text fixes after it lite-checked. Rubric `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b1.md`. 18 override rows dated 2026-10-12 for this branch. 399 changed code lines. Single-sample review; absence of findings is not an attestation.

Confidence: high
Notes: merged on the recommendation (Q-137 standing instruction); the split, --marker ungated and caller_gate in --state only are interim /away calls recorded in the plan note.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QjZ5sDNnJpnupxpYdLDCnr
