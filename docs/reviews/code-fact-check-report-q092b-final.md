Commit: 73698a91

# Code Fact-Check Report

**Repository:** claude-workflows (worktree of fix/q092-drop-hook-deny-reader)
**Scope:** `fix/q092a-drop-deny-option..73698a91` excluding docs/reviews, plus non-merge commit messages (final confirming pass, full unit)
**Checked:** 2026-10-15
**Total claims checked:** 35-38 per replicate; merged clusters below cover every non-Verified verdict
**Summary:** 0 Incorrect; 1 Stale and 5 Mostly accurate (log row 53, guide, header parenthetical, a historical commit message), 1 untested mechanism, 4 Unverifiable (Claude Code host behaviour)
**Commit:** 73698a91
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-q092b-final-r1.md`, `-r2.md`, `-r3.md`. Verified claims are in the replicate reports.

## Claim 1: log row 53 "open as a follow-up question (Q-081)"
**Location:** `docs/decisions/log.md:76`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Evidence:** Q-081 was answered 2026-09-28; the open sandbox work is Q-125 (built, unmerged).
**Scope:** older text moved under the new amendment.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=—
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 2: log row 53 "now also" list
**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** Only `permissions: null`, allow/deny null or false, and any malformed `ask` are new; the rest already failed closed.
**Scope:** wording.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 3: guide "DENY RULES ARE CLAUDE CODE'S and RULE SYNTAX sections say what is left"
**Location:** `guides/bare-host-hook-wiring.md:160-161`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Evidence:** RULE SYNTAX is allow-only now.
**Scope:** wording.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=—
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 4: ROLE "(exit 0 with no output ...)"
**Location:** `hooks/auto-approve-allowed-commands.sh:51`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** Non-JSON stdin exits 4, non-object `tool_input` exits 5; stdout empty, never 2.
**Scope:** malformed input only.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 5: ed06dec1 message "a permissions.deny that is not an array of strings" fails closed
**Location:** commit ed06dec1 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** At that commit deny null/false were accepted; later commits changed it.
**Scope:** historical commit message.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 6: load_rules "On failure no rule is kept, not even the records jq printed before its error"
**Location:** `hooks/auto-approve-allowed-commands.sh:230-231`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Evidence:** True when run; but removing the `return 0` passed all 35 tests (every fail-closed test put the bad file first).
**Scope:** behaviour verified; test coverage missing.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "no test pins it; mutant survives"
**Legibility-target:** for-author

## Claim 7: Claude Code behaviours (#39344; glob gets past CC's matcher; CC drops non-string entries with a warning; which values make CC drop a whole file)
**Location:** hook `:53-54`, `:70-72`, `:78-85`, `:148`; log row 53; guide; wiring.json `_comment`; test title `:220`; commit 0444b1ac
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Evidence:** Host behaviour; no network, Claude Code not run. The hook halves are verified.
**Scope:** accepted residuals (plan F3-F6b, rubric C7, C10).
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1: "could not reproduce the binary reading of the warning-and-drop path"
**Legibility-target:** for-orchestrator-synthesis

## Escalations

None beyond accepted residuals. Out of diff (r3): a dangling symlink at a settings path counts as absent, not unreadable (pre-existing).

## Verdict stability

7 clusters; all reporting replicates agreed on verdict for all 7 (claims 2, 3, 5 and claim 1 seen by two of three). 0 Incorrect in every replicate; suites 35/35 and 16/16; 12-19 mutants per replicate, all killed except the load_rules partial-output mutant (claim 6).
