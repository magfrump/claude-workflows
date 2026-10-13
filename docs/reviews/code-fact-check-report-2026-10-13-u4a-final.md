Commit: c4e36d1d

# Code Fact-Check Report

**Commit:** c4e36d1d
**Replication:** k=3
**Scope:** full branch `git diff main...HEAD` of `feat/build-loop-u4a` (code, header, plan U4a notes, commit messages on main..HEAD); final confirming pass.
**Total claims checked:** 31 clusters (r1 31, r2 35, r3 31 claims; clustered by file, line range and substance)
**Summary:** 1 Incorrect, 1 Stale, 5 Mostly accurate, 24 Verified (incl. 1 Unverifiable reduced to an existing override row)
**Merge:** most-severe-wins over `code-fact-check-report-2026-10-13-u4a-final-r{1,2,3}.md` (orchestrator collation; no verdicts added).

## Claim 1: refusal text "which another brief's Asked: line adds too" (`scripts/build-loop.sh:1975`) and header "be added by no other brief" (:228-230)

**Verdict:** Incorrect
**Confidence:** high
**Verification mode:** executed
**Evidence:** `used[$id]` is keyed by ID alone, so one brief adding the same new ID twice (`Asked: Q-001@abc, Q-002, Q-002`, only that brief changed) refuses with "another brief's Asked: line adds too" though no other brief adds it.
**Scope:** covers the message and header wording; the refusal itself (exit 2) is correct: fails closed. Comment/message-only, not behavioral.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r2: "Suggested wording: which is added more than once (by this or another brief's Asked: line)" · r3: "Any second add of an ID refuses, even by the same brief"

## Claim 2: commit 722c2e10 "--land-cycle --expect MAIN" and "(no hooks run: rows 719, 749, 752)"

**Verdict:** Stale
**Confidence:** high
**Verification mode:** static
**Evidence:** 70d24331 renamed the flag to `--main`; row 749 concerns the chore commit's hooks (70d24331's body corrects this).
**Scope:** immutable branch history; later commits record both changes.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Mostly accurate
**Replicate annotations:** r3: "Its --expect was accurate at that commit"

## Claim 3: commit 70d24331 names `asked_rule`

**Verdict:** Stale
**Confidence:** high
**Verification mode:** static
**Evidence:** 4df6ec58 folded asked_rule into cycle_rules.
**Scope:** immutable branch history.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Verified
**Replicate annotations:** r3: "asked_rule existed then"

## Claim 4: header "its reflog entry reads 'build-loop: cycle land of B'" (:252-254)

**Verdict:** Mostly accurate
**Confidence:** high
**Verification mode:** executed
**Evidence:** on the fast-forward path git appends ": Fast-forward"; --merge's header states this, --land-cycle's does not.
**Scope:** wording.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

## Claim 5: plan :209 and :339 (U4a rules bullet, as-built note)

**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** static
**Evidence:** both stop at iteration 1's rules (no exact items, one brief per ID, duplicate names, case-spelled cycle files).
**Scope:** plan text.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "The bullets leave out some rules but state nothing wrong"

## Claim 6: plan :339 "about 15" --check line-count tests

**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** static
**Evidence:** 10 explicit `${#lines[@]}` checks plus whole-output comparisons.
**Scope:** an estimate.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (annotated) · r2=— · r3=Mostly accurate
**Replicate annotations:** r1: "an estimate (10 explicit #lines checks)"

## Claim 7: commit 4df6ec58 "Refusals word truthrule's classes by floor_why's prose"

**Verdict:** Mostly accurate
**Confidence:** medium
**Verification mode:** static
**Evidence:** the settings class is worded by cycle_rules' own string (floor_why has no settings word).
**Scope:** commit message.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** none

## Claim 8: isrecord "one per day, updated in place by each iteration"

**Verdict:** Unverifiable
**Confidence:** medium
**Verification mode:** static
**Evidence:** orchestrator behaviour (U4b); settled by override row (2026-10-13, claim 19b).
**Scope:** none in this diff.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Verified
**Replicate annotations:** none

## Verified (23 clusters, all three replicates agree unless noted)

Synopsis, usage and `--main`/`--answered` parsing; the record name narrowed to cycle-YYYY-MM-DD.md (executed: a `-HHMM` or `-x` record reads other); "That refusal is printed alone"; gate code, truth classes and case-spelled cycle files refused in both modes (executed: 28 single-path cases, real cycle paths and docs/thoughts pass); the Asked: rule's extension, exact items, new entries from both files, name matching across closed/, duplicate names, deletion/rename (executed); --land-cycle preconditions (state gate, not the caller check; executed); the merge judged against main with --answered, rename caught; tree R, parents MAIN_SHA and HEAD, chore_msg, CAS or ff-only in W, **no hooks run** (executed: up to six planted hooks, none fired on either path); landed fields; the refusal list and "its merge copy"; land's, chore_msg's ("as git merge writes it", git 2.39.5), chore_record's, log_class's, cycle_diff's, asked()'s, cycle_rules', questions_rules', land_cycle's and the lib's isrecord/truthrule comments; the three U4a test names (each pins its behaviour; reflog and hooks covered by probes, not tests); 4e14d1cc wording-only; the remaining claims of 722c2e10, 70d24331 and 4df6ec58; c0cafb66 and c4e36d1d (r2, medium).

## Escalations

- `test/scripts/build-loop-orchestrator.bats` U4a tests: no test asserts the reflog text or hook absence (r1, r3) → orchestrator: probes executed both; consider in a later unit.

## Verdict stability

31 clusters; all reporting replicates agreed on 23; disagreed on 8 (claims 1-8 above, per-replicate verdicts listed). Agreement 23/31 = 74%. Every disagreement is between adjacent wording verdicts (Incorrect/Mostly accurate, Stale/Verified, Mostly accurate/Verified); none is on a behavioral claim.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the exact path your own prompt names, structured per your skill.
- Answered: yes (merged from three replicates)
- Out of scope: none
- Escalate: test coverage of reflog text and hook absence (see Escalations)
