# Code Fact-Check Report

**Commit:** f56ba3f5
**Replication:** k=3
**Repository:** claude-workflows, worktree `.claude/wt-build-loop-u2b3b1`
**Scope:** `git diff main...HEAD` (U2b3b1, all three commits), final confirming pass
**Total claims checked:** 32 / 34 / 24 per replicate (r1 / r2 / r3), merged by most-severe-wins below
**Summary:** 1 Incorrect, 2 Stale, 6 Mostly accurate, 2 Unverifiable; the rest Verified (most by execution). Nothing Incorrect or Stale in a line the branch changed but the import_targets superset comment, which the G8 change made incomplete.

Per-replicate reports: `code-fact-check-report-build-loop-u2b3b1-final-r1.md`, `-r2.md`, `-r3.md` (all `Commit: f56ba3f5`). Only the clusters that are not Verified are restated here; every Verified claim is in the replicates.

## Claim 1: plan line 301 says import_readers "refuses a control byte in a caller path"
**Location:** `docs/working/plan-build-loop-handoff.md:301`
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** import_readers refuses only a newline (lib:1038); readerform in reader_settings keeps control bytes out (lib:579).
**Verification mode:** executed
**Scope:** covers the import_readers checks; does not establish anything about the parser.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

## Claim 2: plan line 301 says without main by name "the lists stay empty"
**Location:** `docs/working/plan-build-loop-handoff.md:301`
**Verdict:** Stale
**Confidence:** High
**Evidence:** since 1ece139d reader_settings sets IMPORT_READER_WHY when main is not found by name (lib:597-600), so both walks fail.
**Verification mode:** executed
**Scope:** covers the no-main path of reader_settings.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=— · r3=Stale
**Replicate annotations:** r3: "8ed86432's commit note said the same and was accurate at that commit"

## Claim 3: the import_targets superset comment lists the reader roots
**Location:** `scripts/lib/dev-cycle-read.sh:794-796`
**Verdict:** Stale
**Confidence:** High
**Evidence:** the list omits the worktrees G8 re-spells under each caller root (lib:1031); a probe printed `/host/cw/.wt/a`.
**Verification mode:** executed
**Scope:** covers the root list only.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Stale · single-replicate detection
**Replicate annotations:** architecture-final A2 found the same.

## Claim 4: dev-cycle.sh's --check-fix header names the walk's failure causes
**Location:** `scripts/dev-cycle.sh:56-60`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** a docs/dev-cycle.md the fence reader refuses (an unclosed fence, a stray CR) also sets IMPORT_READER_WHY (lib:603).
**Verification mode:** executed
**Scope:** covers reader_settings' refusal paths.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

## Claim 5: IMPORT_WORK_MAX comment: "870,000 over 49"
**Location:** `scripts/lib/dev-cycle-read.sh:740`
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** r1, r2, r3 measured 899,730 at 49 roots; performance-final measured 868,530. 347,710 at 25 roots and 8,240 with one hold.
**Verification mode:** executed
**Scope:** depends on the registry at the time of measurement.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

## Claim 6: "49 roots here: 1.5 s per walk"
**Location:** `scripts/lib/dev-cycle-read.sh:746`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** the main walk takes 1.4-1.7 s; the tree walk about 1.7 s, at 25 roots as at 49.
**Verification mode:** executed
**Scope:** load average 2-2.5.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

## Claim 7: docs/dev-cycle.md "one line of absolute paths"
**Location:** `docs/dev-cycle.md:31-33`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** the path character rule (readerform) is not stated; a host path with another character fails both walks.
**Verification mode:** executed
**Scope:** covers readerform.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=—
**Replicate annotations:** none

## Claim 8: H4 test name "every path ... with no main by name"
**Location:** `test/scripts/dev-cycle.bats:1407`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** the no-main step passed one path.
**Verification mode:** static
**Scope:** test body.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate
**Replicate annotations:** none

## Claim 9: 8ed86432's commit message "(was 1.3 s)"
**Location:** commit 8ed86432
**Verdict:** Unverifiable
**Confidence:** Medium
**Evidence:** the main walk takes 1.45-1.5 s at 25 roots now; the alias costs no measurable time.
**Verification mode:** executed
**Scope:** load varies; the 1.3 s was measured once earlier in the session.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Mostly accurate · r3=—
**Replicate annotations:** none

## Claim 10: 1ece139d's "~30 test call sites" for the reverted sentinel
**Location:** commit 1ece139d
**Verdict:** Unverifiable
**Confidence:** Low
**Evidence:** the reverted code is in no commit.
**Verification mode:** static
**Scope:** none.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable
**Replicate annotations:** r1: f56ba3f5's "lite fix-drift: no findings" has no report on the branch (Unverifiable; the run's findings.json is in the session scratchpad).

## Escalations

None routed beyond the critics, which all ran.

## Verdict stability

10 non-Verified clusters: 3 agreed across every replicate that surfaced them (claims 4, 5, 2 where surfaced), 2 disagreed (claim 9: Unverifiable vs Mostly accurate; claim 6 surfaced by two). Single-replicate detections: claims 1, 3, 7, 8, 10. Agreement on the Verified claims was complete where replicates overlapped.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path your role names, structured per your skill, every finding with a verbatim Evidence quote and path:line.
- Answered: yes (merged by the orchestrator from three replicates)
- Out of scope: none
- Escalate: nothing
