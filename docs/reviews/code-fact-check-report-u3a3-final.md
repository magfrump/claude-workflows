# Code Fact-Check Report

**Commit:** 01a2935f
**Replication:** k=3
**Repository:** claude-workflows (worktree .claude/wt-build-loop-u3a3)
**Scope:** `git diff main...HEAD` on feat/build-loop-u3a3 (final confirming pass, iteration 3 of 3)
**Checked:** 2026-10-10
**Total claims checked:** 28 clusters (r1 28, r2 28, r3 27 claims; replicate reports `code-fact-check-report-u3a3-final-r{1,2,3}.md`)
**Summary:** 0 behavioral Incorrect; 1 Incorrect (test-helper comment), 1 Stale (comment), 4 Mostly accurate (comments, commit messages); the rest Verified. Merged most-severe-wins; annotations by union. Clusters needing attention follow in full; Verified clusters are listed in the replicate reports, which this merge does not restate.

## Claim 1: `rv` helper comment says feat/x has one commit that also adds FILE
**Location:** `test/scripts/build-loop-merge.bats:184`
**Verdict:** Incorrect
**Confidence:** high
**Evidence:** With FILE given, rv makes a second commit (`commit_all gate`, :189) on top of work's.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Incorrect
**Replicate annotations:** r1+r3: "no assertion depends on it"
**Verification mode:** static
**Scope:** covers the helper comment against its body; does not establish any test outcome change (none).
**Legibility-target:** for-author

## Claim 2: ANSWER_AWK's comment says it prints one word or nothing
**Location:** `scripts/lib/dev-cycle-read.sh:1991-1994`
**Verdict:** Stale
**Confidence:** high
**Evidence:** Since a7a4f784 the END block also prints the entry's heading as a second line (`print head`), which check_answer splits off.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=—
**Replicate annotations:** r2: "nothing is misled today: check_answer is the only consumer"
**Verification mode:** static
**Scope:** covers ANSWER_AWK's output shape; check_answer's handling verified separately (Verified).
**Legibility-target:** for-author

## Claim 3: lib header: the ANSWER_HEADING caller runs check_answer "its output to a file under set -e"
**Location:** `scripts/lib/dev-cycle-read.sh:35-38`
**Verdict:** Mostly accurate
**Confidence:** high
**Evidence:** The one caller, approval, runs inside `elif ... && ! approval` (`scripts/build-loop.sh:1226`), where set -e is off (probed by r1, r3).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "harmless: nothing in check_answer exits; a failed write ends in a refusal"
**Verification mode:** executed
**Scope:** covers the set -e statement; does not establish a failure path (none found).
**Legibility-target:** for-author

## Claim 4: check_answer's comment: "With an answer line it sets ANSWER_HEADING ... ("Q-NNN · SLUG")"
**Location:** `scripts/lib/dev-cycle-read.sh:2076`
**Verdict:** Mostly accurate
**Confidence:** high
**Evidence:** It is set for every non-skip result, open with no answer line included, and holds the raw heading text.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "'CR dropped' and 'emptied otherwise' confirmed"
**Verification mode:** executed
**Scope:** covers when the value is set; approval refuses open before reading it.
**Legibility-target:** for-author

## Claim 5: GATE_CODE's comment and e25a6e89's message: skills/dev-cycle/ "carries the D6 snippet"
**Location:** `scripts/lib/dev-cycle-read.sh:1920-1921`; commit e25a6e89
**Verdict:** Mostly accurate
**Confidence:** medium
**Evidence:** The repo's skills/dev-cycle/SKILL.md has no snippet yet; plan D6 puts it there and U4 adds it.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Verification mode:** static
**Scope:** tense of the comment; the gate rule itself is Verified.
**Legibility-target:** for-author

## Claim 6: a7a4f784's message: "TRUTH_WHERE for both walks' failures"
**Location:** commit a7a4f784
**Verdict:** Mostly accurate
**Confidence:** high
**Evidence:** The tree walk sets it only when import_readers fails (rubric C5, settled: corrected in the merge message).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Verification mode:** static
**Scope:** commit body (immutable on the branch).
**Legibility-target:** for-orchestrator-synthesis

## Escalations
- `scripts/build-loop.sh` header, --merge paragraph (r2 → orchestrator): an approved merge with main checked out in a worktree has reflog "build-loop: approved merge of STEM: Fast-forward"; the header names ": Fast-forward" only in the self-merge sentence.
- `scripts/dev-cycle.sh:186` (r1 → orchestrator): check_fix now prints the registry/root sentence when import_readers fails without IMPORT_READER_WHY; fail-closed, untested.
- Flake (r1, r2): serial runs failed 4 and 2 tests with the known config_seeds `find` vanish; one (r1, check test 144) without the message; all passed on rerun.

## Verdict stability
Clusters needing attention: 6. Agreement: claims 3 and 6 (3/3), claim 2 (2 reporting, agree); disagreement: claim 1 (Mostly accurate vs Incorrect); single-replicate: claims 4, 5. Verified clusters: replicates agreed on all they shared. Agreement rate on attention clusters: 3/4 multi-replicate clusters agreed.

## Goal-Alignment Note
- Success criterion (restated verbatim): a merged report of the three replicates, most-severe-wins.
- Answered: yes
- Out of scope: none
- Escalate: the two orchestrator escalations above
