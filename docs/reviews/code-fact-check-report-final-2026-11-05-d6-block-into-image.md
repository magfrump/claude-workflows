# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** `git diff 5b20d4bd..1c5fd04f`, final confirming pass
**Checked:** 2026-11-05
**Commit:** 1c5fd04f
**Replication:** k=3
**Total claims checked:** merged below for those needing attention; every Verified claim stays in its replicate report (r1 52, r2 61, r3 68 claims)

Merged most-severe-wins from `code-fact-check-report-final-r1`, `-r2` and `-r3` (same stem). All findings are prose: no replicate found a behavioural defect. Each was fixed in the commit after 1c5fd04f.

## Claim 1: A planted `info/grafts` reaches `--main-log`

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:105,117`
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** `main_log` and `log_class` read through `gate_git`, whose repository has no `info/` (`scripts/build-loop.sh:1055-1072`, `:1835`, `:1870`). r1 and r2 probes confirm `--main-log` ignores a graft.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Verified
**Replicate annotations:** r1+r2: "a graft does reach `dev-cycle.sh`'s `git log` and real-repo reads such as `merge-base`"
**Legibility-target:** for-author

## Claim 2: "everything then reads consistently" under a graft

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:64`
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** Same root as Claim 1.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=—
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 3: Stale or loose wording

**Location:** plan `:151`, `:406`, `:431`; research `:53`, `:63`, `:87`, `:103`, `:118`; `skills/dev-cycle/SKILL.md:216-218`; `scripts/d6.sh:51`; `scripts/lib/dev-cycle-read.sh:1031`
**Verdict:** Mostly Accurate
**Confidence:** High
**Evidence:** "snippet" left in three plan rows; "it alone" also fits the no-wrapper row; "nothing reads" is too wide (the orchestrator's plain git follows a replace ref); option [2] did not list the plan rows it leaves false; "either entry" had no referent; "dangling" holds only for a symbolic ref; "Both" after three items.
**Replicate verdicts:** r1=Mostly Accurate · r2=Stale (plan rows) · r3=Mostly Accurate
**Replicate annotations:** r3: "`refused a run as root` is unverifiable: removed code, no root in the sandbox"
**Legibility-target:** for-author

## Escalations

- `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:103` repeats Claim 1's sentence (orchestrator; the review stands as a snapshot, the research doc is corrected).

## Verdict stability

Two of the clusters above disagree, on Claim 1 (r3 verified the sentence by the mode answering, as the first pass did; r1 and r2 traced the read path) and on Claim 3's plan rows (Stale against Mostly Accurate). Agreement across the remaining clusters was not tallied, so no rate is reported.
