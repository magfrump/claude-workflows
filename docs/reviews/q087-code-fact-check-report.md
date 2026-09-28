Commit: 27d483b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q087 (branch `review/q087`)
**Scope:** full branch `main...27d483b` (one commit): `docs/decisions/log.md` (+row 63), `skills/code-review/SKILL.md` (four places), `test/skills/code-review-factcheck-replication.bats`, plus the 27d483b commit message and the sibling statements the brief named (`docs/decisions/log.md` row 60, `docs/working/questions.md` Q-087, decision 031, pr-prep 3d, review-fix-loop.md, proposal B2, `scripts/self-improvement.sh` Gate 1h, `references/rubric.md`)
**Checked:** 2026-09-28
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 17
**Summary:** 12 verified, 2 mostly accurate, 2 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim matches a logged pattern. Claim 7 is a misattribution (the falsifier exists, in a different document), not a fabrication, so no log entry is added.

---

## Claim 1: "the mitigation is that the final confirming pass reviews the full branch (at 031's k=1, unchanged); raising it to k=3 is open as Q-087"

**Location:** `docs/decisions/log.md:83` (row 60, Rationale cell)
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether row 60's statement about the final pass's k still describes the rule after this branch; does not establish whether the repo's convention permits editing historical log rows (row 63 may be the intended superseding record).
**Legibility-target:** for-author

Row 60 still reads `the final confirming pass reviews the full branch (at 031's k=1, unchanged); raising it to k=3 is open as Q-087` (`docs/decisions/log.md:83`). This branch changes that rule: row 63 says `A review-fix loop's final confirming pass runs the fact-check at k=3 (merged most-severe-wins), not decision 031's k=1.` (`docs/decisions/log.md:85`), and SKILL.md Step 1 now says `the final confirming pass reviews the full branch at k=3 (decision log 63, Q-087 [2])` (`skills/code-review/SKILL.md:133`). Row 60 carries no forward pointer to row 63, so a reader of row 60 alone gets the old k=1 rule and an "open" question that is answered.

**Evidence:** `docs/decisions/log.md:83`, `docs/decisions/log.md:85`, `skills/code-review/SKILL.md:130-133`

---

## Claim 2: "accepting ~+300k tokens per loop"

**Location:** `docs/decisions/log.md:85`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Q-087's stated cost and 031's per-pass k=1 savings figure; does not establish a measured token cost for a k=3 final pass (no measurement exists on this branch).
**Legibility-target:** for-orchestrator-synthesis

Q-087 states `it trades about +300k tokens per loop` and option [2] costs `~+300k tokens per loop` (`docs/working/questions.md:226`, `:231`). Decision 031 gives `k=1 saves ~250–370k *per pass*` (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:46`) and `k=1 saves ~30% of every pass (~300k)` (`:130`). One pass per loop moving from k=1 to k=3 is consistent with ~+300k.

**Evidence:** `docs/working/questions.md:221-233`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:44-46`, `:130`

---

## Claim 3: "The final pass is the one run without `--loop-pass`, recognized by the branch's rubric having no `Loop closed at` line (`skills/code-review/SKILL.md` Stage 1)."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the cited Stage 1 text says this and whether the recognition clause still selects k; does not establish how an orchestrator in practice distinguishes the passes.
**Legibility-target:** for-author

The cited Stage 1 text exists: `recognized by the branch's canonical rubric existing without a` / `Loop closed at` line` (`skills/code-review/SKILL.md:453-454`). Two imprecisions. (a) SKILL.md says *canonical* rubric; the row drops the qualifier, and Step 1 excludes ad-hoc names (`Ad-hoc suffixes (-iter2, -final) never count`, `skills/code-review/SKILL.md:115-116`). (b) The clause no longer decides anything for replication. Standalone reviews and the final pass both take k=3 (`skills/code-review/SKILL.md:451-452`), and every `--loop-pass` takes k=1 (`:444-445`), so the flag alone determines k. The rubric check was needed only while standalone (k=3) and final pass (k=1) differed; that difference produced the deferred misclassification in `docs/reviews/override-log.md:127` (`A second standalone review ... is classed as a loop final pass, so it runs k=1 instead of k=3`). The precise version is "any run without `--loop-pass` takes k=3". Claim 12b covers the same clause in SKILL.md.

**Evidence:** `docs/decisions/log.md:85`, `skills/code-review/SKILL.md:115-116`, `:443-456`, `docs/reviews/override-log.md:127`

---

## Claim 4: "Amends 031 C2, which priced both clean passes at k=1."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers 031's C2 configuration and cost reasoning; does not establish that 031's record itself carries an amendment note (it does not; see Goal-Alignment Escalate).
**Legibility-target:** for-orchestrator-synthesis

031's bundle table: `| **C2** | **on** | **1** | **2-clean** | **fix-drift** | k=1 savings fund a second attestation draw; **chosen** |` (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:84`). Its cost check prices the extra clean pass at k=1: `the second clean pass at k=1 costs ~0.7M` (`:130-131`, excerpt ends :131; paragraph continues to :132 — read). K=1 applies per pass, so both clean passes are k=1.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:74-84`, `:126-132`

---

## Claim 5: "Since row 60, loop passes review only the delta since the last rubric stamp, so code no fix touched is drawn only on the loop's first and final passes, which weakens 031's N≥3 across-pass resampling argument for that code."

**Location:** `docs/decisions/log.md:85`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default scope rules in SKILL.md Step 1 and 031's N≥3 argument; does not establish behavior when a stamp fallback or pr-prep's broad-fix fallback forces full scope mid-loop (those passes also redraw untouched code, so "only" is the default-path statement).
**Legibility-target:** for-orchestrator-synthesis

Step 1: `If there is no such file, or its stamp is missing, is not an ancestor ..., or equals HEAD, use full-branch scope` (`skills/code-review/SKILL.md:119-121`), so a loop's first pass is full-branch. Also: `Only the final confirming pass ... runs without --loop-pass, and it keeps the full-branch default` and `Every earlier pass in the loop, including the first of 2-clean's two clean passes, takes the delta range.` (`:126-129`). 031's argument: `**These are equal at N=3 and the loop favors k=1 for N≥3** — *provided the defect survives to be re-drawn*` (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:115-116`).

**Evidence:** `skills/code-review/SKILL.md:103-135`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:111-116`, `workflows/pr-prep.md:250`

---

## Claim 6: "Pinned in `test/skills/code-review-factcheck-replication.bats`."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the suite passes on this branch and that the new assertion fails against main's SKILL.md text; does not establish that the suite pins the absence of residual final-pass-k=1 wording elsewhere, or the Dependencies and Important Reminders final-pass wording (only the Stage 1 phrase is grepped).
**Legibility-target:** for-orchestrator-synthesis

The test adds `stage1_flat | grep -qiE 'standalone single-pass reviews and to a loop.s final confirming pass'` (`test/skills/code-review-factcheck-replication.bats:155-156`). Executed on the branch: 17/17 ok, including `ok 13 replication is loop-aware: k=1 on loop passes per decision 031, k=3 standalone and on the final pass`. Executed with the same test file against `git show main:skills/code-review/SKILL.md` placed in a mirrored temp tree (the test derives `SKILL` from `$BATS_TEST_DIRNAME/../..`, `:20-21`): `not ok 13` with `# k=3 is not extended to the loop's final confirming pass (decision log 63)`. So the assertion distinguishes the new rule from main's. (Test 11 skipped in the temp tree because `scripts/self-improvement.sh` was not copied; unrelated.)

- Run 1: command `timeout 300 scripts/run-tests.sh test/skills/code-review-factcheck-replication.bats`, cwd `/workspace/.claude/wt-q087`, exit 0, 2026-09-28T21:25:56Z.
- Run 2: command `timeout 120 bats test/skills/code-review-factcheck-replication.bats`, cwd `/home/node/.claude/jobs/9f431b13/tmp/q087-fc-mainskill` (copy of the test + main's SKILL.md), exit 1, 2026-09-28T21:26:01Z.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:18-36`, `:141-160`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc-tests.log`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc-tests-mainskill.log`

---

## Claim 7: "Revisit if final-pass replicate agreement on untouched code stays ≥90% over ≥20 claims (031's k-reduction falsifier, applied to this pass)."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution of the ≥90%/≥20-claim falsifier; does not judge whether that falsifier is a good revisit trigger for this pass.
**Legibility-target:** for-author

Decision 031 contains no ≥90% / ≥20-claim falsifier (grep for `90` in `docs/decisions/031-review-loop-tier-and-factcheck-policy.md` hits only the token figure `merge ~90–160k` at `:45`). 031's replication revisit trigger runs the other way, toward *more* k: `if a behavioral or security red is merged that a k=3 pass would have caught ... restore k=2+ (029's recall was real).` (`:196`). The k-reduction falsifier belongs to the state doc §1.1: `**Falsifier worth checking first:** if k=3 fact-check verdicts agree ≥90% of the time on a` / `20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2.` (`docs/thoughts/code-review-evaluation-state.md:78-79`). SKILL.md names it that way: `that is §1.1's stated falsifier` (`skills/code-review/SKILL.md:635`), and the test suite calls it `the k-reduction falsifier is stated (>=90% agreement on >=20 claims -> k=2)` (test 8 in the executed log). Fix: "(state doc §1.1's k-reduction falsifier, log row 27, applied to this pass)". Under tier T this is a doc-only Incorrect.

**Evidence:** `docs/decisions/log.md:85`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:45`, `:194-201`, `docs/thoughts/code-review-evaluation-state.md:78-79`, `skills/code-review/SKILL.md:630-635`

---

## Claim 8: Q-087 entry — "**Status:** OPEN" and "**Interim:** [1]. U4 (feat/u4-code-review-skill) keeps 031's k=1 and cites this entry."

**Location:** `docs/working/questions.md:221-233`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the entry's state on this branch; does not establish which branch's questions.md will win at merge.
**Legibility-target:** for-author

On `review/q087` the entry still reads `**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** OPEN` (`docs/working/questions.md:222`) with `**Interim:** [1].` (`:232`), while this branch implements [2]. The answer is recorded on another branch: `answers-2026-09-28` commit 48bca90 archives it as `**Status:** ANSWERED` / `**Answered 2026-09-28: [2] k=3 on the final pass.** Done in 65e51b7` (from `git show 48bca90`). 65e51b7 is an ancestor of `answers-2026-09-28`; 27d483b is not (it is only on `review/q087`). The two commits carry identical SKILL.md, test and log-row diffs (compared with `git diff`). If `review/q087` merges instead of `answers-2026-09-28`, the archive's "Done in 65e51b7" cites a commit that is not in main's history.

**Evidence:** `docs/working/questions.md:221-233`; `git show 48bca90` (answers-2026-09-28); `git merge-base --is-ancestor 65e51b7 answers-2026-09-28` (true)

---

## Claim 9: "Runs as **k=3 parallel replicates** merged most-severe-wins (k=1 on `--loop-pass` passes, decision 031; the final confirming pass stays k=3, decision log 63)"

**Location:** `skills/code-review/SKILL.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Stage 1 and Step 6; does not establish that "stays" is historically accurate (on main the final pass was k=1; "stays" reads correctly only relative to this bullet's k=3 headline).
**Legibility-target:** for-orchestrator-synthesis

Stage 1: `Every --loop-pass of a review-fix loop ... runs **k=1**` (`skills/code-review/SKILL.md:444-445`) and `The **k=3 protocol below applies to standalone single-pass reviews and` / `to a loop's final confirming pass**` (`:451-452`). Step 6 defines `--loop-pass` as `a **non-final pass of a review-fix loop**` (`:246`).

**Evidence:** `skills/code-review/SKILL.md:17-23`, `:246-251`, `:443-456`

---

## Claim 10: "Cost to recall: code no fix touches is redrawn only on each loop's first and final passes, ... the mitigation is that the final confirming pass reviews the full branch at k=3 (decision log 63, Q-087 [2])."

**Location:** `skills/code-review/SKILL.md:130-133`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default scope rules in the same section and the cited references; does not establish mid-loop full-scope fallbacks (non-ancestor stamp, `--full`, pr-prep's broad-fix fallback), which also redraw untouched code.
**Legibility-target:** for-orchestrator-synthesis

Same section: `Only the final confirming pass ... runs` / `without --loop-pass, and it keeps the full-branch default` (`:126-127`), and first passes fall to full-branch when no usable rubric exists (`:119-121`). k=3 on that pass is stated at `:451-452` and in log row 63 (`docs/decisions/log.md:85`). The Q-087 reference resolves to `docs/working/questions.md:221`.

**Evidence:** `skills/code-review/SKILL.md:103-135`, `docs/decisions/log.md:85`, `docs/working/questions.md:221`

---

## Claim 11: "**Replication is loop-aware (decision 031, configuration C2, amended by decision log 63 — 031 overrules the earlier blanket k=3 mandate).** Every `--loop-pass` of a review-fix loop (which requires **2 consecutive clean passes** before merge) runs **k=1**."

**Location:** `skills/code-review/SKILL.md:443-450`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Step 6, the first-red short-circuit mechanic 6, the k=1 header vocabulary, 031 and pr-prep 3d; does not establish Step 7's agent-count line, which still says "3 fact-check replicates" for every run (pre-existing, unchanged by this branch, and now correct for the final pass).
**Legibility-target:** for-orchestrator-synthesis

Step 6: `--loop-pass` ... `implies --no-gate` (`:246-250`). Short-circuit mechanic 6: `The run still implies --no-gate and k=1.` (`:739`), which is about a `--loop-pass` run (`:677-678`) and so agrees. The k=1 header vocabulary `**Replication:** k=1 (loop pass, decision 031)` (`:448`) still covers only loop passes; the final pass uses the merged header `**Replication:** k=3` (`:607-613`), which Gate 1h accepts without a note (`k=3*) : ;;  # full replication — nothing to report`, `scripts/self-improvement.sh:1606`). pr-prep 3d defers the count to SKILL.md: `--loop-pass also sets the fact-check replicate count` (`workflows/pr-prep.md:244`). Step 7 still says `Total agent count (3 fact-check replicates + N critics` (`skills/code-review/SKILL.md:259-260`).

**Evidence:** `skills/code-review/SKILL.md:246-251`, `:253-262`, `:443-450`, `:607-613`, `:735-745`; `scripts/self-improvement.sh:1570-1617`; `workflows/pr-prep.md:244`

---

## Claim 12a: "The **k=3 protocol below applies to standalone single-pass reviews and to a loop's final confirming pass** — the pass that runs without `--loop-pass` per Step 1"

**Location:** `skills/code-review/SKILL.md:451-453`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Step 1, Step 6, Dependencies, Important Reminders, the merge header contract, `references/rubric.md` and log row 63; does not establish sibling records outside the skill (row 60, Q-087 on this branch, 031's own text).
**Legibility-target:** for-orchestrator-synthesis

Step 1: the final confirming pass `runs` / `without --loop-pass` (`:126-127`); Dependencies `the final confirming pass stays k=3` (`:20`); Important Reminders `k=3 for standalone single-pass reviews and the loop's` / `final confirming pass (decision log 63)` (`:1280-1281`). `references/rubric.md:20-28` says nothing about k (only the `Commit:` stamp and `Loop closed at`), so it has nothing to contradict. A repo-wide grep of skills, workflows, decisions, thoughts, tests and scripts for final-pass k statements finds no remaining text that puts the final pass at k=1, except log row 60 (Claim 1).

**Evidence:** `skills/code-review/SKILL.md:20`, `:126-129`, `:451-453`, `:1278-1284`; `skills/code-review/references/rubric.md:20-28`

---

## Claim 12b: "recognized by the branch's canonical rubric existing without a `Loop closed at` line"

**Location:** `skills/code-review/SKILL.md:453-454`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the clause describes the final pass and whether it still changes k; does not establish orchestrator behavior on ad-hoc-named rubrics (which fall to "standalone", also k=3).
**Legibility-target:** for-author

The description is right: loop passes remove an old `Loop closed at` line when they start a new loop (`skills/code-review/SKILL.md:119-123`), and the final pass adds it only when clean, after reviewing (`:127-128`), so at dispatch the final pass sees an open canonical rubric. But the clause is now vestigial. Both "standalone" and "final pass" take k=3 (`:451-452`), and every `--loop-pass` takes k=1 (`:444-445`), so whether the flag is present is the only thing that sets k. The clause still reads as a check the orchestrator must run. The precise version: "any run without `--loop-pass` uses the k=3 protocol." This also closes the deferred override-log row (`docs/reviews/override-log.md:127`, `Revisit if Q-087 raises the final pass to k=3`): a second standalone review can no longer end up at k=1.

**Evidence:** `skills/code-review/SKILL.md:115-129`, `:443-456`, `docs/reviews/override-log.md:127`

---

## Claim 13: "Loop passes review only the delta since the last stamp, so code no fix touched is drawn only on the loop's first and final passes; the final pass's k=3 restores the within-pass redundancy on that code (Q-087 [2]; decision 031 priced both clean passes at k=1)."

**Location:** `skills/code-review/SKILL.md:454-456`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Step 1 scope rules and 031's C2 pricing (same evidence as Claims 4, 5); does not establish mid-loop full-scope fallbacks, and "restores" means k=3 within one pass, not the N≥3 across-pass draws 031 assumed.
**Legibility-target:** for-orchestrator-synthesis

See Claim 5 for Step 1 (`skills/code-review/SKILL.md:119-121`, `:126-129`) and Claim 4 for 031 (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:84`, `:130-131`). The first pass of a loop is full-branch at k=1 (it is a `--loop-pass`; pr-prep: `Pass --loop-pass ... on any pass you expect to be followed by a fix`, `workflows/pr-prep.md:250-251`). So untouched code gets one k=1 draw and one k=3 draw, i.e. 4 draws in total, which is ≥ 031's N=3 parity point.

**Evidence:** `skills/code-review/SKILL.md:103-135`, `:451-456`; `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:84`, `:109-114`, `:126-132`; `workflows/pr-prep.md:242-256`

---

## Claim 14: "k=1 per `--loop-pass` inside the review-fix loop (paired with the 2-consecutive-clean rule); k=3 for standalone single-pass reviews and the loop's final confirming pass (decision log 63)"

**Location:** `skills/code-review/SKILL.md:1278-1284`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1; does not establish anything beyond this bullet.
**Legibility-target:** for-orchestrator-synthesis

Matches Stage 1 `:444-445` and `:451-452`. The bullet points readers back to `Stage 1's **Why three**, its loop-aware` / `replication paragraph` (`:1283-1284`), which is now the amended paragraph.

**Evidence:** `skills/code-review/SKILL.md:443-456`, `:1276-1284`

---

## Claim 15: test "replication is loop-aware: k=1 on loop passes per decision 031, k=3 standalone and on the final pass" and its comment "the final confirming pass, which runs without --loop-pass, takes the k=3 protocol too, since loop passes see only the delta."

**Location:** `test/skills/code-review-factcheck-replication.bats:141-160`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the grep matches the flattened Stage 1 text, that the test name and comment describe what it asserts, and that it fails on main's text; does not establish negative pinning: nothing asserts that text putting the final pass at k=1 is absent, and the Dependencies bullet is not grepped.
**Legibility-target:** for-orchestrator-synthesis

`stage1()` extracts `/^### Stage 1: Code Fact-Check/,/^### Fact-Check Gate/` (`:29-31`), and `stage1_flat` collapses newlines and repeated spaces (`:34-36`). The source line break `reviews and` / `to a loop's final confirming pass` (`skills/code-review/SKILL.md:451-452`) flattens to `reviews and to a loop's final confirming pass`, and the regex `loop.s` matches the apostrophe. The earlier assertion `'k=3 protocol below applies to standalone'` still matches (same line `:451`). The executed runs are the same as in Claim 6: branch exit 0 with `ok 13`; main's SKILL.md exit 1 with `not ok 13` on exactly the new assertion. The name's "k=3 ... on the final pass" matches the new assertion. The retained comment lines 142-144 (`k=3 remains the standalone single-pass protocol`) are now incomplete on their own, but the added comment at `:153-154` completes them.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:29-36`, `:141-160`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc-tests.log`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc-tests-mainskill.log`

---

## Claim 16: commit 27d483b message — "Loop passes review only the delta since the last rubric stamp, so untouched code is drawn only on a loop's first and final passes. The final pass now uses the k=3 protocol; --loop-pass stays k=1. Decision log 63 amends 031 C2. The replication suite pins the rule."

**Location:** `git log -1 27d483b` (commit message body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each checkable sentence against the diff and the executed suite; does not establish that the message acknowledges 27d483b re-applies the identical content of 65e51b7 (on answers-2026-09-28), which the message does not mention.
**Legibility-target:** for-orchestrator-synthesis

Delta and first/final draws: Claims 5 and 13. k=3 final and k=1 `--loop-pass`: `skills/code-review/SKILL.md:444-445`, `:451-452`. Amends 031 C2: `Amends 031 C2` (`docs/decisions/log.md:85`). Suite pins it: Claim 6 (executed). The `Confidence: high` / `Notes: user answer Q-087 [2].` lines are metadata and not checkable. `git diff` confirms that 65e51b7 and 27d483b have the same subject and body, and identical diffs for SKILL.md, the test, and the log row.

**Evidence:** `git log -1 --format=%B 27d483b`; `docs/decisions/log.md:85`; `skills/code-review/SKILL.md:443-456`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc-tests.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`docs/decisions/log.md:85`): the ≥90%/≥20-claim falsifier comes from the state doc §1.1 (`docs/thoughts/code-review-evaluation-state.md:78-79`, log row 27), not decision 031. 031's replication trigger points toward more k. Re-attribute it.

### Stale
- **Claim 1** (`docs/decisions/log.md:83`): row 60 still says the final pass runs at "031's k=1, unchanged" and that k=3 is "open as Q-087". Add a pointer to row 63, or accept that row 63 supersedes it.
- **Claim 8** (`docs/working/questions.md:221-233`): on this branch Q-087 is still OPEN with Interim [1]. The answer is archived on `answers-2026-09-28` and cites 65e51b7, not 27d483b.

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:85`): the "recognized by ... no `Loop closed at` line" clause drops "canonical", and no longer affects k.
- **Claim 12b** (`skills/code-review/SKILL.md:453-454`): the recognition clause is vestigial, since every run without `--loop-pass` is k=3. Simplify it to the flag rule.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes. All seven brief items were checked, and the test was run on the branch and against main's text.
- Out of scope: pre-existing Step 7 agent count ("3 fact-check replicates" on every run, `skills/code-review/SKILL.md:259-260`, which is wrong for loop passes but unchanged here); proposal B2 (`docs/working/proposal-2026-09-27-smaller-review-units.md:40`) wants k=3 on the first full pass too, and the implemented rule keeps the first pass at k=1. That is a proposal, not a claim this diff makes.
- Escalate: (1) Row numbering: this branch has no row 62. Row 62 (Q-085 size cap, commits 6e9fa45/49a3dbb) exists on `answers-2026-09-28`, so 63 is correct once that lands. Merging `review/q087` alone leaves a gap. (2) 27d483b duplicates 65e51b7, which is already on `answers-2026-09-28`, and that branch's Q-087 archive cites 65e51b7. Pick one to merge, or both will conflict or duplicate. (3) Decision 031's record has no amended-by note pointing to row 63. (4) `docs/reviews/override-log.md:127` has now had its revisit trigger fire. The issue it deferred is moot, so it could get a closing note.
- Decisions I made: I treated the missing "canonical" qualifier and the vestigial recognition clause as Mostly accurate rather than Incorrect, because the clause is still true of the final pass; it just no longer decides k. I ran the main-text comparison in a mirrored temp tree because the test has no override variable.
