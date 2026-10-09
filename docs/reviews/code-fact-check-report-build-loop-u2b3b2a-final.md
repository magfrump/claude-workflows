# Code Fact-Check Report

**Commit:** 82bb5281
**Replication:** k=3
**Repository:** claude-workflows, worktree `.claude/wt-build-loop-u2b3b2a`
**Scope:** `git diff main...HEAD` (U2b3b2a, all code commits), final confirming pass
**Total claims checked:** 48 / 38 / 40 per replicate (r1 / r2 / r3), merged by most-severe-wins below
**Summary:** 0 Incorrect, 1 Stale, 4 Mostly accurate, 1 Unverifiable; the rest Verified (most by execution). Two of the clusters carry a narrow fail-open the replicates executed (Claims 1 and 2).

Per-replicate reports: `code-fact-check-report-build-loop-u2b3b2a-final-r1.md`, `-r2.md`, `-r3.md` (all `Commit: 82bb5281`). Only the clusters that are not Verified are restated here; every Verified claim is in the replicates.

## Claim 1: the parser's "no file a walk admits has" a name holding a newline
**Location:** `scripts/lib/dev-cycle-read.sh:880-882`
**Verdict:** Stale
**Confidence:** High
**Evidence:** outside_ok now admits outside files, and one may have a newline in its name: an `@"<o>/a` / `b.md"` quoted mention across two lines names it, the parser drops the spelling at `index(out, "\n")`, and both walks answer ok with its import `docs/q.md: -` (r1 probe2.log). Not a regression (main dropped every outside name).
**Verification mode:** executed
**Scope:** covers a below-no-root spelling; does not establish anything about repo names holding a newline, which the walks' listings refuse.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "the opposite of the A2 fix: a spelled newline is dropped silently; fail the walk on a below-no-root spelling holding a newline, or correct the comment"

## Claim 2: the walk header's exception list is complete
**Location:** `scripts/lib/dev-cycle-read.sh:724-733`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** an outside symlink into a reader root whose target that checkout lacks while main has it is skipped by outside_ok as missing, so the main walk answers ok and `docs/t.md: -` for a main file sessions load through the link once the checkout has it (r2, executed with the gate's checkout deleting docs/t.md). The caller contract's clean checkout at MAIN_SHA covers the gate's own root; another root's checkout is not covered.
**Verification mode:** executed
**Scope:** covers a dangling link at the name itself; does not establish the case of a dangling directory component.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** r2: "a narrow fail-open; a link into the main worktree still resolves; route to the security critic"

## Claim 3: import_outside's returns-1 list
**Location:** `scripts/lib/dev-cycle-read.sh:1135-1139`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** it also returns 1 when the two calls' summed work passes IMPORT_WORK_MAX (r3, executed); "a read fails" holds only under pipefail (without it a mode-000 file returns 0 and prints `/0`: r2, executed; both walks set pipefail); "a file that changed after the walk admitted it fails the walk" holds for removed, unreadable or directory-swapped files, while edited text is read and a FIFO stalls (r1, r3).
**Verification mode:** executed
**Scope:** covers import_outside and import_file's "never as a file to skip"; does not establish a caller outside the walks (none exists).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "the pipefail qualifier applies to import_file's header too, once U2b3b2b adds a non-walk caller" · r3: "commit 82bb5281's 'the list is complete' is one reason short"

## Claim 4: commit 82bb5281 "H1: import_outside's returns-1 list is complete"
**Location:** commit 82bb5281 message
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** one reason short (Claim 3).
**Verification mode:** executed
**Scope:** the commit message only.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** none

## Claim 5: commit 55490d15's Notes call the `|| true` mutant equivalent
**Location:** commit 55490d15 message
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** carried from override row 566 (Accepted-immutable); not re-raised.
**Verification mode:** static
**Scope:** the commit message only.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

## Claim 6: outside_ok's "a session in this container cannot load it either"
**Location:** `scripts/lib/dev-cycle-read.sh:1157`
**Verdict:** Unverifiable
**Confidence:** Medium
**Evidence:** needs a probe inside a Claude Code session; carried from override row 567.
**Verification mode:** static
**Scope:** the FIFO and other non-regular cases.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=—
**Replicate annotations:** none

## Escalations

- `scripts/lib/dev-cycle-read.sh:724-733` and the walks' `//` arms (r2): the dangling-link fail-open (Claim 2) → security-reviewer.
- `scripts/lib/dev-cycle-read.sh:880-882` (r1): the newline-spelling fail-open (Claim 1) → security-reviewer.
- r3: a bind-mount alias of a reader root, which realpath does not resolve, was not tested (no such alias here) → orchestrator.

## Verdict stability

Clusters not Verified: 6. All reporting replicates agreed on 4 (Claims 3, 5, 6 where reported); Claims 1, 2 and 4 were single-replicate detections. Every commit-count, red-on-main, mutant and line-count claim was Verified by every replicate that checked it (all three ran the suites: 120/20/79/2/2).

## Goal-Alignment Note
- Success criterion (restated verbatim): your report saved at the path your own tail names, structured per your skill file, with a `Commit: 82bb5281` line at the top.
- Answered: yes (merged from three replicates).
- Out of scope: none.
- Escalate: Claims 1 and 2 to the security critic.
