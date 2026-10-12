# Code Fact-Check Report

**Commit:** 5e816c5b
**Replication:** k=3
**Repository:** /workspace/.claude/wt-build-loop-u3b1 (feat/build-loop-u3b1)
**Scope:** `main...5e816c5b`, full branch (final confirming pass)
**Checked:** 2026-10-12
**Total claims checked:** 103 replicate claims (r1 31, r2 40, r3 32), merged below into the clusters that carry a non-Verified verdict in any replicate; every other claim was Verified by each replicate that surfaced it (see the replicate reports `code-fact-check-report-u3b1-final-r{1,2,3}.md`).
**Summary:** 0 behavioural Incorrect. 1 Incorrect cluster (commit-body text), 4 Mostly-accurate clusters (help/plan text), 2 Unverifiable.

## Claim 1: ec9ba0c7's body says GIT_GRAFT_FILE and the object directories name files the state gate never reads
**Location:** commit ec9ba0c7 body (code comment `scripts/build-loop.sh:522-525` already corrected in 8f99a919)
**Verdict:** Incorrect
**Confidence:** High
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Evidence:** `git rev-parse --git-path info/grafts` prints GIT_GRAFT_FILE's path; GIT_OBJECT_DIRECTORY moves `objects/info/alternates`; state_gate reads both (`scripts/build-loop.sh:496-497`).
**Verification mode:** executed
**Scope:** covers the commit text; does not establish any behaviour change (the variables are refused).
**Replicate annotations:** r1+r2+r3: "not on the rubric's list of commit-body corrections owed in the merge message"
**Legibility-target:** for-author

## Claim 2: 8f99a919's body: "skipped unread", "valid UTF-8", "the compare-and-swap's own refusal"
**Location:** commit 8f99a919 body
**Verdict:** Incorrect
**Confidence:** High
**Replicate verdicts:** r1=Verified (compound, notes the first two are on the owed list) · r2=Incorrect (first two) / Mostly accurate (third, claim 36) · r3=Incorrect
**Evidence:** the cap is tested after marker_kind's reads; Perl's decoder was not strict UTF-8 (fixed in 8367359f); land's re-run also leaves a moved main to W's fast-forward.
**Verification mode:** executed
**Scope:** commit text only.
**Replicate annotations:** r2: "the third phrase (CAS only, W's ff omitted) is not on the owed list"
**Legibility-target:** for-author

## Claim 3: --state's exit-1 list is complete
**Location:** `scripts/build-loop.sh:124-126`; `docs/working/plan-build-loop-handoff.md:324`
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate
**Evidence:** also exit 1 with stderr only: a GIT_CONFIG_COUNT naming an unset key or a huge count, a malformed GIT_CONFIG_PARAMETERS, GIT_WORK_TREE naming a missing directory (bash's cd error), GIT_COMMON_DIR or GIT_OBJECT_DIRECTORY naming nothing.
**Verification mode:** executed
**Scope:** text; every case fails closed (no ok).
**Replicate annotations:** r1+r3: "all fail closed"
**Legibility-target:** for-author

## Claim 4: the header says FENCE_AWK reads the body "as written"
**Location:** `scripts/build-loop.sh:115-117` (comment `:833` is right)
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Evidence:** FENCE_AWK runs over the printed lines (scrubbed, first 100, cut at 300 bytes); a fence left open past line 100, or a refused line 101, does not skip (executed).
**Verification mode:** executed
**Scope:** text; those lines are never printed.
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 5: default_gate refuses a default branch naming anything but a commit
**Location:** `docs/working/plan-build-loop-handoff.md:324`, ec9ba0c7 body
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=Verified (notes only a tag reaches it) · r2=Mostly accurate · r3=Verified
**Evidence:** a tree or blob is skipped by resolve_main's `^{commit}` peel first (no default branch found: exit 1, or "both main and master"); only an annotated tag (loose, packed, nested) reaches the new check.
**Verification mode:** executed
**Scope:** text.
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 6: rows 493/494/517 close on the flow
**Location:** plan `:324`, ec9ba0c7 Notes, `scripts/build-loop.sh:579-580`
**Verdict:** Unverifiable
**Confidence:** n/a
**Replicate verdicts:** r1=Unverifiable · r2=— · r3=Unverifiable
**Evidence:** nothing calls --state until U4's SKILL.md (the plan note now says "once U4 ...").
**Verification mode:** static
**Scope:** future flow.
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

## Claim 7: override row's "~145 MB" for a 16 MB marker
**Location:** `docs/reviews/override-log.md:711`
**Verdict:** Unverifiable
**Confidence:** n/a
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=—
**Evidence:** no /usr/bin/time in the sandbox; the time (~1 s) reproduced.
**Verification mode:** executed (time only)
**Scope:** memory figure from i2's fact-check.
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

## Escalations

- r3: `scripts/questions.sh:184` (index summary) takes a quoted line as summary text: not column-0 anchored, text only (addressee: security-reviewer).

## Verdict stability

Clusters with a non-Verified verdict: 7. Agreement among reporting replicates: claim 1 (3/3), 6 (2/2), 7 (1/1) agree; claims 2, 3, 4, 5 disagree on Verified vs Mostly accurate / Incorrect (text scope). Mutants: r1 3, r2 6, r3 9, all killed. Strict UTF-8 regex vs Python strict decode: 0 mismatches over 232,768 + 837,930 + 199,979 inputs.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the path below, structured per the code-fact-check skill.
- Answered: yes (merged from three replicates)
- Out of scope: none
- Escalate: questions.sh:184 summary line to security-reviewer
