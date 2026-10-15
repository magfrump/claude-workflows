Commit: 7d61c39b

# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** `main...HEAD` on `fix/q160-iteration-cap` (full branch, final confirming pass) and its three commit messages
**Checked:** 2026-10-15
**Total claims checked:** 14 merged clusters with a non-Verified verdict in some replicate (replicates checked 38, 33 and 24 claims; all other clusters Verified in every replicate that surfaced them)
**Summary:** 0 Incorrect, 3 Stale, 10 Mostly accurate, 1 Unverifiable; every growth figure, size count, anchor, tally and Q-104 quote Verified
**Commit:** 7d61c39b
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-q160-final-r1.md`, `-r2.md`, `-r3.md` (all stamped `Commit: 7d61c39b`). Verified clusters common to all replicates: growth figures 102→842, 157→603, 217→538, 392→570 and Q-104's 396→1861 (recomputed with step 1a's command from each merge base); branch sizes 28/41/50; the Q-104 [2] quote "asks you for a waiver"; rubric tallies and override-log citations; row 62's amendment column; every anchor in changed lines; the three pinning suites pass; no other doc still states the entry-only rule.

## Claim 1: Row 62 and review-fix-loop state the /away reading as a fact about Q-104

**Location:** `docs/decisions/log.md:85`, `workflows/review-fix-loop.md:59`
**Verdict:** Mostly accurate
**Confidence:** high
**Verification mode:** static
**Scope:** covers Q-104's options table; does not establish what the user meant by "Same as [1]"
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "[2] opens with 'Same as [1], but', so [1]'s /away split could be read as inherited; the reading is labelled Q-160's"
**Legibility-target:** for-author

## Claim 2: chat-synthesis rule 2's first-review test matches code-review SKILL.md's

**Location:** `skills/code-review/references/chat-synthesis.md:140-142`
**Verdict:** Mostly accurate
**Confidence:** high
**Verification mode:** static
**Scope:** compared with SKILL.md Step 1 and short-circuit mechanic 6
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "drops 'canonical' and 'the newest one is closed'" · r2: "lacks 'before this pass'; the ladder's input is the rubric just produced, so a rubric always exists" · r3: "omits SKILL's unreadable-history case"
**Legibility-target:** for-author

## Claim 3: pr-prep step 3 criterion: the re-check ran "after each iteration and before merge"

**Location:** `workflows/pr-prep.md:287`
**Verdict:** Mostly accurate
**Confidence:** high
**Verification mode:** static
**Scope:** step 3 and step 6c text
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "the before-merge run is at 6c, which has its own criterion" · r3: "the waiver-record contents differ from the loop section's list"
**Legibility-target:** for-author

## Claim 4: "Before merge" shorthand

**Location:** pr-prep 1a, 3e, step 3 criterion; quick-ref; row 62; heading
**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** static
**Scope:** both delivery paths
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate
**Replicate annotations:** r1+r3: "exact only on the local path; on the GitHub path 6c runs at publish and later pushes are not re-checked"
**Legibility-target:** for-author

## Claim 5: "so the growth stays in `git log`"

**Location:** `workflows/review-fix-loop.md:57`
**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** static
**Scope:** pr-prep step 4 squash
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "holds only if step 4's squash keeps the commits carrying `Size:` lines"
**Legibility-target:** for-author

## Claim 6: Iteration-4 gate and precedence cover a unit past 800 under a waiver

**Location:** `workflows/review-fix-loop.md:61-63`, `:84`
**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** static
**Scope:** gate and precedence text
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "no /away default for separable parts past ~800 under a waiver" · r3: "precedence says 'past 800', not 'past the current limit'"
**Legibility-target:** for-author

## Claim 7: "Q-160's reading" list is complete

**Location:** `workflows/review-fix-loop.md:65`
**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** static
**Scope:** section text vs Q-104
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** r2: "omits the split option in the waiver entry, the `you: judgment` route, 'work on other units goes on'"
**Legibility-target:** for-author

## Claim 8: Plan step list

**Location:** `docs/working/plan-2026-10-15-q160-size-recheck.md:36-37`
**Verdict:** Stale
**Confidence:** high
**Verification mode:** static
**Scope:** plan vs HEAD
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "old heading, count in review artifact, same BASE, no 3c/6c pointers"
**Legibility-target:** for-author

## Claim 9: Plan side claims

**Location:** plan :17, :28
**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** static
**Scope:** Q-113 text; live-verify-gate regexes
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "'Q-112 review fixes' is the plan's label (Q-112 is a design question); skills/dev-cycle/SKILL.md is not in the enforcement regex (the brief's gate-code list names it, the regex does not)"
**Legibility-target:** for-author

## Claim 10: Override-log row names the `Size after iteration N` rubric line

**Location:** `docs/reviews/override-log.md:829`
**Verdict:** Stale
**Confidence:** high
**Verification mode:** static
**Scope:** row vs 7d61c39b
**Replicate verdicts:** r1=— · r2=— · r3=Stale · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-author

## Claim 11: Commit bodies of a94e01c7 and 57f4c871

**Location:** commit messages
**Verdict:** Stale
**Confidence:** high
**Verification mode:** static
**Scope:** bodies vs HEAD
**Replicate verdicts:** r1=Stale · r2=— · r3=—
**Replicate annotations:** r1: "a94e01c7's '>800 on a later pass', 'same BASE', per-artifact count; 57f4c871's rubric line, all superseded; immutable history"
**Legibility-target:** for-author

## Claim 12: Q-160 citations resolve on main

**Location:** loop doc, row 62, plan
**Verdict:** Mostly accurate
**Confidence:** high
**Verification mode:** executed
**Scope:** `git log --all`
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=—
**Replicate annotations:** r1: "Q-160 exists only on chore/dev-cycle-2026-10-15-0357 (63af3551) until that branch lands"
**Legibility-target:** for-author

## Claim 13: Self-eval artifact counts

**Location:** `docs/reviews/self-eval-review-fix-loop-2026-10-15-fix-q160-iteration-cap.md:21`
**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** executed
**Scope:** `ls docs/reviews`
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=—
**Replicate annotations:** r2: "76 rubrics, 19 with the iteration header, not 91/31"
**Legibility-target:** for-author

## Claim 14: Plan: cross-reference-integrity reads the changed files

**Location:** plan :30
**Verdict:** Unverifiable
**Confidence:** low
**Verification mode:** static
**Scope:** grep only
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Verified
**Replicate annotations:** r1: "grep found no file names; the test globs workflows/"
**Legibility-target:** for-orchestrator-synthesis

## Escalations

None routed to a critic; Claims 4 and 6 are in the critics' brief.

## Verdict stability

14 clusters listed; 6 surfaced by more than one replicate. Disagreements: Claim 8 (Stale/Stale/Mostly accurate), Claim 14 (Unverifiable/Verified/Verified). Agreement on multi-replicate clusters: 4/6.
