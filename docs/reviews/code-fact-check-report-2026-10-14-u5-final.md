Commit: b5eaedf6

# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** feat/build-loop-u5 vs main (b279a2ba), full branch, final confirming pass
**Checked:** 2026-10-14
**Total claims checked:** 50 clusters (r1 44, r2 47, r3 50 claims; Verified clusters are recorded in the replicate reports)
**Summary:** 2 Incorrect, 11 Mostly accurate, 37 Verified, 0 Stale, 0 Unverifiable
**Commit:** b5eaedf6
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-2026-10-14-u5-final-r1.md`, `-r2.md` and `-r3.md` (all stamped `Commit: b5eaedf6`). This merge lists every cluster that is not Verified by all replicates; each Verified cluster's evidence is in the replicates. Every replicate executed `build-loop.sh --settings` on the branch's settings file, the real-settings bats test, `questions.sh check`, and Q-156's paste (with install.sh stubbed) in a throwaway clone.

## Claim 1: Q-156: "`git archive` in install.sh would honor either" a replace ref or a graft file
**Location:** `docs/working/questions.md:491`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** r3 ran `git archive` with a graft: same blob; with a replace ref: changed. A graft changes only parents.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Incorrect · 
**Replicate annotations:** r1+r3: "refusing grafts is still harmless; only the stated reason is wrong"
**Verification mode:** executed
**Scope:** covers what `git archive <commit>` writes under a graft vs a replace ref; does not establish any other graft effect on install.sh.
**Legibility-target:** for-author

## Claim 2: Commit b5eaedf6's body: "three override rows"
**Location:** commit b5eaedf6
**Type:** Documentation
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** the commit adds two override-log rows (r1: rows 830, 831).
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "immutable history; record as an override row"
**Verification mode:** static
**Scope:** covers the commit's diff of `docs/reviews/override-log.md`.
**Legibility-target:** for-author

## Claim 3: Settings lines: "A line counts only when it is the one line ... that starts with its key"
**Location:** `docs/dev-cycle.md:16-17`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** SETTINGS_AWK counts copies by letters alone, case folded; never/reader lines also need a blank next line.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: "fail-closed: the gap only makes more files read as unset"
**Verification mode:** executed
**Scope:** covers read_settings and SETTINGS_AWK.
**Legibility-target:** for-author

## Claim 4: Slots bullet: dispatch into free slots; not-counted list
**Location:** `docs/dev-cycle.md:39-42`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** step 10 subtracts "the loops this session runs"; step 8 also leaves capped and held-stalled briefs uncounted.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Verification mode:** static
**Scope:** covers SKILL.md steps 8 and 10.
**Legibility-target:** for-author

## Claim 5: "self-merge can land only ... docs, README.md, runs/ and archive/" (also Q-103 [2], Q-149 [1])
**Location:** `docs/dev-cycle.md:54-55`; `docs/working/questions.md:122`, `:373`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** a path under a new top-level name is refused by neither the never line nor the floor.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** none
**Verification mode:** static
**Scope:** covers floor() and the never line.
**Legibility-target:** for-author

## Claim 6: Q-103 [2]: what lands and "anything else falls to [1]'s entry"
**Location:** `docs/working/questions.md:122`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** own files land unlisted; conflicts end stopped and environment refusals retry (SKILL.md step 7).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** none
**Verification mode:** static
**Scope:** covers SKILL.md step 7 and srules.
**Legibility-target:** for-author

## Claim 7: Q-149: "a one-line edit"
**Location:** `docs/working/questions.md:379`
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** the Never-line prose and Q-103 [2] also state the width.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** none
**Verification mode:** static
**Scope:** covers the files that state the never line.
**Legibility-target:** for-author

## Claim 8: Q-151 [2] remedy names step 10 only
**Location:** `docs/working/questions.md:410`
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** step 8's queue count would change too.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** none
**Verification mode:** static
**Scope:** covers SKILL.md steps 8 and 10.
**Legibility-target:** for-author

## Claim 9: Q-156 "If the paste refuses" names one cause
**Location:** `docs/working/questions.md:498`
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** the paste also refuses for HEAD not main, replace refs and grafts.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Verification mode:** executed
**Scope:** covers the paste's refusal branches.
**Legibility-target:** for-author

## Claim 10: Q-103 F11 gap list
**Location:** `docs/working/questions.md:95`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** checkout_gate closes conversions, nested repos and case for the gate (known issue A5); A5's still-open FIFO start and check-to-read swap are omitted.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "overstates the risk"
**Verification mode:** static
**Scope:** covers checkout_gate and known issue A5.
**Legibility-target:** for-author

## Claim 11: Q-103 "also routed" header: all items are override-log rows
**Location:** `docs/working/questions.md:104`
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** the U2b3a item comes from the plan, the U4c item from SKILL.md's D6 Rule.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** none
**Verification mode:** static
**Scope:** covers the override-log rows cited.
**Legibility-target:** for-author

## Claim 12: Rubric status: iteration 2's Must Address rows fixed
**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:5`
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** A10 is deferred (override row).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** none
**Verification mode:** static
**Scope:** covers the rubric's iteration-2 table.
**Legibility-target:** for-author

## Claim 13: Commit 659a1c61's body lists api-consistency F5; earlier recorded commit bodies
**Location:** commits 659a1c61, 2846f9fa, 771a5d02, c63da94d
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** F5's fix is in b5eaedf6; the others are already Won't-Fix override rows.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** none
**Verification mode:** static
**Scope:** covers the commits' diffs.
**Legibility-target:** for-author

## Escalations

- `docs/working/questions.md:491` (r1, r2, r3; addressee: security-reviewer): the paste binds tree names, so anything else that shapes `git archive` matters. Routed: the final security pass ran and found `core.attributesFile` (security final F1).
- `docs/dev-cycle.md:54-55` (r1; addressee: orchestrator): new top-level names can self-merge; bears on Q-103 and Q-149. Actioned in the narrow fix batch.

## Verdict stability

50 clusters. All reporting replicates agreed on 38 (the 37 Verified-by-all clusters and claim 4). Disagreed on 12: claims 1-3 and 5-13 above. Agreement rate 76%.
