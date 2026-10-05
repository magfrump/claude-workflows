Commit: 497c8cb5
# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** feat/build-loop-handoff..feat/build-loop-u0a (final confirming pass, full unit range)
**Checked:** 2026-10-05
**Total claims checked:** 62 (r1=21, r2=15, r3=26; clustered below for the claims needing attention; Verified claims are in the replicate files)
**Summary:** 2 Incorrect clusters (comment, commit message), 1 Incorrect-by-one-replicate cluster on the header (Mostly accurate in r1), the rest Verified. No behavioral claim is wrong: tests (55/56/56), byte-identical output vs main, verbatim moves and guard mutations all verified by execution.
**Commit:** 497c8cb5
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-build-loop-u0a-r1.md`, `-r2.md`, `-r3.md` (all at Commit 497c8cb5). This merge carries every non-Verified cluster with per-replicate verdicts and the union of annotations; clean Verified clusters are listed by subject only.

## Claim 1: need_root's comment: "(set -u fires there, but its error, like an exit, ends only the subshell)"

**Location:** `scripts/lib/dev-cycle-read.sh:69-70`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** Since the guards, rawfile/plaindir expand `${ROOT_REAL:-}`, so set -u never fires inside `$(blocker …)`; with ROOT_REAL unset it returns 0 and prints the path (blocked). It fired only in the pre-guard lib at 4ef450da. The bats comment at :1054 states the opposite of this comment.
**Verification mode:** executed
**Scope:** covers the wording of this claim against the code at 497c8cb5; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2: "comment only; no behaviour effect" · r1+r3: "the comment's conclusion (callers must stop outside the substitution) still holds"

## Claim 2: Lib header: "rawfile, plaindir and blocker then read nothing as plain"

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Evidence:** True when ROOT_REAL is unset. When ROOT_REAL is set to another tree and the current directory holds a symlink resolving to `$ROOT_REAL/<same path>`, rawfile/plaindir report it plain and blocker blocks nothing (reproduced). need_root stops the exiting callers in that case; the three helpers themselves do not.
**Verification mode:** executed
**Scope:** covers the wording of this claim against the code at 497c8cb5; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Incorrect
**Replicate annotations:** r1: "exact wording: nothing outside ROOT_REAL" · r3: "dev-cycle.sh never calls them that way; limit the sentence to the unset case"

## Claim 3: Commit 497c8cb5 message: "need_root's comment says set -u fires in the subshell rather than not at all"

**Location:** `commit 497c8cb5`
**Type:** Commit message
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** Presents the inverted comment (claim above) as a fact-check correction.
**Verification mode:** executed
**Scope:** covers the wording of this claim against the code at 497c8cb5; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Incorrect
**Replicate annotations:** none

## Claim 4: Commit 32b9ae0e: pre-fix skipped behaviour

**Location:** `commit 32b9ae0e`
**Type:** Commit message
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** Settled: override-log row for 32b9ae0e (Won't-Fix).
**Verification mode:** executed
**Scope:** covers the wording of this claim against the code at 497c8cb5; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

## Verified clusters (by subject)

move verbatim (scrub_reexec the declared rewrite); behaviour unchanged (digest and all --check-* byte-identical vs main); test counts; T29/T30 and the ROOT_REAL test names vs assertions; mutation coverage of need_root (unset and wrong root) and the rawfile/plaindir `${ROOT_REAL:-}` guards; header Exit line; scrub_reexec comment; DEV_CYCLE_SCRUBBED sharing; source-line comment.

## Escalations

None raised by any replicate beyond the claims above.

## Verdict stability

Non-Verified clusters: 4. Clusters where every reporting replicate agreed: 3. Disagreements are listed in each claim's Replicate verdicts line (U0a/U0b header sentence: Mostly accurate vs Incorrect). Verified clusters agreed across all reporting replicates.
