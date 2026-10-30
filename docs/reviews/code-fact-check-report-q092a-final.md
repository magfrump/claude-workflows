Commit: 5ba83a3a

# Code Fact-Check Report

**Repository:** claude-workflows (worktree of fix/q092a-drop-deny-option)
**Scope:** `00a27a2f..5ba83a3a` excluding docs/reviews, plus commit messages (final confirming pass, full unit)
**Checked:** 2026-10-15
**Total claims checked:** 32-45 per replicate; merged clusters below cover every non-Verified verdict
**Summary:** 0 behavioural defects; 1 Incorrect (commit message), 2 Stale and 4 Mostly accurate (plan, test title, test comment), 2 Unverifiable (Claude Code host behaviour)
**Commit:** 5ba83a3a
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-q092a-final-r1.md`, `-r2.md`, `-r3.md`. Verified claims are listed in the replicate reports; only clusters with a non-Verified verdict are carried here.

## Claim 1: commit 1a831ffe says the de-quoted match was among "the parts nothing outside the tests used"
**Location:** commit 1a831ffe message, paragraph 1
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Evidence:** With settings-file deny rules only, 00a27a2f falls through on `.cred""entials.json`, `.c\redentials.json`, `git "push"`, `cat "secret"`; 5ba83a3a approves all four. The de-quoted match ran on every production call with a Bash deny rule.
**Scope:** Covers the commit-message wording; the unit's header RESIDUALS states the behaviour correctly.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=—
**Replicate annotations:** r1+r2: "commit message; record in the rubric rather than rewrite"
**Legibility-target:** for-author

## Claim 2: plan Split section "each under 400, ~365 / ~373"
**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:79-88`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Evidence:** Now U1 407, U2 436 against U1, 697 total; within decision 62's ~800 loop tolerance.
**Scope:** size figures only.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 3: plan F6 "U2 makes each ... an array of NUL-free strings"
**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:41`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Evidence:** Since unit 2's 0444b1ac non-string entries are skipped (`deny:[1]`, `allow:[1]`, `ask:[1]` approve).
**Scope:** plan wording.
**Replicate verdicts:** r1=Mostly accurate · r2=Stale · r3=Mostly accurate
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 4: test title "...; only * is a wildcard"
**Location:** `test/auto-approve-allowed-commands.bats:213`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** A mutant leaving extglob characters live (`Bash(cat +(a))` then denies `cat aa`) passed 43/43.
**Scope:** test coverage, not hook behaviour.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 5: plan F5 "pinned"
**Location:** `docs/working/plan-q092-drop-hook-deny-reader.md:40`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Evidence:** Only `.c*` and `$F` are pinned by tests.
**Scope:** plan wording.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 6: stdout test comment "No allow rules, a malformed settings file, input with no command"
**Location:** `test/auto-approve-allowed-commands.bats:162`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Evidence:** Lists one exit as two and omits the non-JSON input case.
**Scope:** comment.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 7: Claude Code's matcher lets `.c*` through; CC allow rules are operator-aware
**Location:** plan `:39`, `:48-51`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Evidence:** Needs a host run or Claude Code docs; no network.
**Scope:** the hook half is verified.
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

## Escalations

None beyond the accepted F3/F4 residual.

## Verdict stability

7 non-Verified clusters; all three replicates agreed on 2 (claims 2 and 7 by the two that saw it); verdicts differed in severity on 2 (claims 3, 4); 3 were single- or two-replicate detections. All replicates: 0 behavioural Incorrect, suite 43/43, every targeted mutant killed except the extglob one.
