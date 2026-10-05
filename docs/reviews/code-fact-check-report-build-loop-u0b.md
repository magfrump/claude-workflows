Commit: 698348ac
# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** feat/build-loop-u0a..feat/build-loop-u0b (final confirming pass, full unit range)
**Checked:** 2026-10-05
**Total claims checked:** 48 (r1=17, r2=11, r3=20; clustered below for the claims needing attention; Verified claims are in the replicate files)
**Summary:** 1 Incorrect cluster (the header sentence, carried from U0a), 1 Mostly accurate (a commit message superseded within the range), 1 Unverifiable (future build-loop.sh behaviour). No behavioral claim is wrong.
**Commit:** 698348ac
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-build-loop-u0b-r1.md`, `-r2.md`, `-r3.md` (all at Commit 698348ac). This merge carries every non-Verified cluster with per-replicate verdicts and the union of annotations; clean Verified clusters are listed by subject only.

## Claim 1: Lib header: "rawfile, plaindir and blocker then read nothing as plain" (rewritten in this unit)

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Evidence:** Same as U0a's cluster.
**Verification mode:** executed
**Scope:** covers the wording of this claim against the code at 698348ac; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Incorrect
**Replicate annotations:** r3: "each unit rewrote that sentence"

## Claim 2: Commit 0b53fe50: its test checks resolve_main "returns 1"

**Location:** `commit 0b53fe50`
**Type:** Commit message
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** At that commit the test asserted non-zero; fbe3a219 tightened it within the same range.
**Verification mode:** static
**Scope:** covers the wording of this claim against the code at 698348ac; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=—
**Replicate annotations:** r2: "nothing to fix"

## Claim 3: build-loop.sh will report resolve_main's failure its own way

**Location:** `commit 0b53fe50`
**Type:** Commit message
**Verdict:** Unverifiable
**Confidence:** Low
**Evidence:** build-loop.sh does not exist until U1.
**Verification mode:** static
**Scope:** covers the wording of this claim against the code at 698348ac; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=—
**Replicate annotations:** none

## Verified clusters (by subject)

FENCE_AWK/oddwhy/check_brief/check_branch moved verbatim; resolve_main preserves behaviour (incl. no-default-branch refusal, empty repo, not a repo); main_by_name guard and globals; need_root in check_brief; dev-cycle.sh's main_by_name use is the same condition; test names vs assertions with guard mutations; test counts.

## Escalations

None raised by any replicate beyond the claims above.

## Verdict stability

Non-Verified clusters: 3. Clusters where every reporting replicate agreed: 2. Disagreements are listed in each claim's Replicate verdicts line (U0a/U0b header sentence: Mostly accurate vs Incorrect). Verified clusters agreed across all reporting replicates.
