Commit: 182d143

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q087 (claude-workflows, branch `review/q087`)
**Scope:** branch diff `main...HEAD` (reviewed HEAD 182d143): `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `docs/decisions/log.md` (rows 60, 63), `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`, `docs/reviews/override-log.md`, and commit messages 27d483b, 21d4eb8, 182d143. `docs/reviews/q087-*` excluded (this review's own outputs).
**Checked:** 2026-09-28
**Total claims checked:** 23
**Summary:** 18 verified, 5 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Replicate r2 of k=3 (final confirming pass). Hallucination-pattern log read; no claim matches a logged pattern (all logged patterns are fabricated measured values or fabricated symbols; no claim here quotes a number or symbol that fails to exist).

---

## Claim 1: Dependencies bullet — "k=1 on `--loop-pass` passes, decision 031; the loop's final confirming pass runs k=3, decision log 63"

**Location:** `skills/code-review/SKILL.md:20`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement of the Dependencies bullet with Stage 1's replication paragraph and log row 63; does not establish that Step 7's agent count agrees (see Claim 9).
**Legibility-target:** for-orchestrator-synthesis

Stage 1 says `Every \`--loop-pass\` of a review-fix loop ... runs **k=1**` (`skills/code-review/SKILL.md:444-445`) and `The **k=3 protocol below applies to every run without \`--loop-pass\`**: standalone single-pass reviews and a loop's final confirming pass` (`skills/code-review/SKILL.md:450-451`). Row 63: `A review-fix loop's final confirming pass runs the fact-check at k=3 ... \`--loop-pass\` passes stay k=1.` (`docs/decisions/log.md:85`).

**Evidence:** `skills/code-review/SKILL.md:20`, `skills/code-review/SKILL.md:443-456`, `docs/decisions/log.md:85`

---

## Claim 2: Step 1 "Cost to recall: code no fix touches is redrawn only on each loop's first and final passes"

**Location:** `skills/code-review/SKILL.md:131`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the default path of Step 1's scope rules for a loop with a usable rubric stamp; does not establish the draw count on the full-scope fallbacks the same section defines (non-ancestor stamp, stamp missing, stamp == HEAD) or on pr-prep 3d's broad-fix fallback, each of which redraws untouched code on an intermediate pass.
**Legibility-target:** for-author

The default path holds: `On a \`--loop-pass\` run with none of the flags above, review only what changed since this loop's last review` and the scope is `<sha>..HEAD` (`skills/code-review/SKILL.md:106-116`); the first pass has no rubric so `use full-branch scope` (`:117-118`); the final pass `keeps the full-branch default` (`:126-127`). But the same section also sends a `--loop-pass` to full scope when the stamp `is missing, is not an ancestor (including a git error on the stamp), or equals HEAD` (`:117-118`), and pr-prep says `If a fix touched code broadly enough that the narrower diff covers most of the PR, fall back to a full re-review` (`workflows/pr-prep.md:248`). "Only" is therefore the minimum, not an invariant: "at least on the first and final passes, and by default only there" is the precise version. The conclusion it supports (fewer than 031's N≥3 draws on untouched code by default) holds.

**Evidence:** `skills/code-review/SKILL.md:106-133`, `workflows/pr-prep.md:244-248`

---

## Claim 3: Step 1 "the mitigation is that the final confirming pass reviews the full branch at k=3 (decision log 63, Q-087 [2])"

**Location:** `skills/code-review/SKILL.md:132-133`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the final pass is full-branch (Step 1) and k=3 (Stage 1) and that row 63 / Q-087 [2] are the sources; does not establish the final pass is actually run without `--loop-pass` in practice (a workflow-discipline property).

`Only the final confirming pass ... runs without \`--loop-pass\`, and it keeps the full-branch default` (`skills/code-review/SKILL.md:126-127`); Stage 1 applies k=3 to `every run without \`--loop-pass\`` (`:450`). Q-087 option `**[2] k=3 on the final pass**` (`docs/working/questions.md:232`).

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `skills/code-review/SKILL.md:126-133`, `skills/code-review/SKILL.md:450-451`, `docs/working/questions.md:221-236`

---

## Claim 4: Stage 1 "Every `--loop-pass` of a review-fix loop ... runs **k=1**"

**Location:** `skills/code-review/SKILL.md:443-445`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with short-circuit mechanic 6, Step 6's flag description and pr-prep 3d; does not establish Step 7's agent count (Claim 9).
**Legibility-target:** for-orchestrator-synthesis

Mechanic 6: `The run still implies \`--no-gate\` and k=1.` (`skills/code-review/SKILL.md:739`). pr-prep 3d: `\`--loop-pass\` also sets the fact-check replicate count and the short-circuit; code-review's SKILL.md owns both` (`workflows/pr-prep.md:244`). Step 6 marks `--loop-pass` as `a **non-final pass of a review-fix loop**` and says `Never pass it on the terminal pass` (`skills/code-review/SKILL.md:246-251`).

**Evidence:** `skills/code-review/SKILL.md:443-449`, `skills/code-review/SKILL.md:735-744`, `skills/code-review/SKILL.md:246-251`, `workflows/pr-prep.md:244-254`

---

## Claim 5: Stage 1 "The k=3 protocol below applies to every run without `--loop-pass` ... The flag alone sets k, so no rubric check is needed to tell the two apart."

**Location:** `skills/code-review/SKILL.md:450-453`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Stage 1, the merged-report header contract, Gate 1h, the Important Reminders, rubric.md and pr-prep 3d; does not establish review-fix-loop.md content beyond a grep (it states no k at all).
**Legibility-target:** for-orchestrator-synthesis

No remaining text keys k on the rubric: the old `recognized by the branch's canonical rubric existing without a \`Loop closed at\` line` clause is gone from Stage 1 (diff, `skills/code-review/SKILL.md:443-456`). The k=3 path writes `**Replication:** k=3` (`:609`), which Gate 1h accepts silently: `k=3*) : ;;  # full replication — nothing to report` (`scripts/self-improvement.sh:1603`). The final pass now emits k=3 instead of k=1, so Gate 1h no longer flags it as degraded. `references/rubric.md:20-30` discusses only the `Commit:` stamp and markers, not k (paraphrased — no quote available because the claim is about the absence of any k statement in that section). A repo-wide `rg` for final-pass k=1 wording outside `docs/reviews/`, `archive/`, `runs/` returned only `docs/working/questions.md:224,235` (the still-open Q-087 entry, already covered by override-log row A3) and historical text in 031 (paraphrased — no quote available because the claim covers absence of matching grep results).

**Evidence:** `skills/code-review/SKILL.md:450-456`, `skills/code-review/SKILL.md:605-613`, `scripts/self-improvement.sh:1570-1617`, `skills/code-review/references/rubric.md:20-30`, `workflows/review-fix-loop.md:7`

---

## Claim 6: Stage 1 "Loop passes review only the delta since the last stamp, so code no fix touched is drawn only on the loop's first and final passes"

**Location:** `skills/code-review/SKILL.md:453-455`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the default loop-pass scope; does not establish draw counts under Step 1's full-scope fallbacks or pr-prep 3d's full re-review fallback.
**Legibility-target:** for-author

Same finding as Claim 2, restated in Stage 1. `Loop passes review only the delta` is the default (`skills/code-review/SKILL.md:106-116`), but the same Step 1 sends a `--loop-pass` to full-branch scope when the stamp is missing, not an ancestor, or equals HEAD (`:117-118`), and pr-prep 3d falls back to a full re-review on broad fixes (`workflows/pr-prep.md:248`). Precise version: "by default, drawn only on ...". Also, row 63 (`docs/decisions/log.md:85`) and 27d483b's body repeat the same "only" wording.

**Evidence:** `skills/code-review/SKILL.md:106-133`, `skills/code-review/SKILL.md:453-456`, `workflows/pr-prep.md:248`, `docs/decisions/log.md:85`

---

## Claim 7: Stage 1 "decision 031 priced both clean passes at k=1"

**Location:** `skills/code-review/SKILL.md:456`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what 031's C2 configuration and cost check say; does not establish 031's 1-clean opt-down path.
**Legibility-target:** for-orchestrator-synthesis

031: `| **C2** | **on** | **1** | **2-clean** | **fix-drift** | k=1 savings fund a second attestation draw; **chosen** |` (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:88`) and `the second clean pass at k=1 costs ~0.7M` (`:134-135`).

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:88`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:127-136`

---

## Claim 8: Important Reminders "k=1 per `--loop-pass` ...; k=3 for standalone single-pass reviews and the loop's final confirming pass (decision log 63)"

**Location:** `skills/code-review/SKILL.md:1278-1284`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1; does not establish other reminders.
**Legibility-target:** for-orchestrator-synthesis

Matches Stage 1 `:444-451` quoted in Claims 1 and 5.

**Evidence:** `skills/code-review/SKILL.md:1276-1284`, `skills/code-review/SKILL.md:443-456`

---

## Claim 9: Step 7 "Total agent count (3 fact-check replicates + N critics ...)"

**Location:** `skills/code-review/SKILL.md:260`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact-check agent count per run type; does not establish critic counts. Pre-existing text, unchanged by this branch (`git show main:skills/code-review/SKILL.md` line 260 is identical).
**Legibility-target:** for-author

`- Total agent count (3 fact-check replicates + N critics, plus one Stage-2.5` (`skills/code-review/SKILL.md:260`) is now right for every run without `--loop-pass` (including the final pass, after this branch), but a `--loop-pass` runs `a single fact-check agent` (`:445-446`). Precise version: "3 fact-check replicates (1 on `--loop-pass`)". It does not say the final pass is k=1, so it does not contradict this branch; it is a pre-existing gap from 031.

**Evidence:** `skills/code-review/SKILL.md:253-262`, `skills/code-review/SKILL.md:443-449`

---

## Claim 10: Row 63 statement and rationale (k=3 final pass, "the flag alone sets k", "Amends 031 C2, which priced both clean passes at k=1", "~+300k tokens per loop", "Pinned in `test/skills/code-review-factcheck-replication.bats`")

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the decision statement, the cost figure's source, the 031 amendment and the pin; the "drawn only on first and final passes" phrase is covered by Claim 6.
**Legibility-target:** for-orchestrator-synthesis

Q-087: `it trades about +300k tokens per loop` and option [2] `~+300k tokens per loop` (`docs/working/questions.md:226`, `:232`); 031: `k=1 saves ~30% of every pass (~300k)` (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:134`). The pin is the test at `test/skills/code-review-factcheck-replication.bats:141-161` (Claim 20). C2 per Claim 7.

**Evidence:** `docs/decisions/log.md:85`, `docs/working/questions.md:221-236`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:88`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:134`

---

## Claim 11: Row 63 revisit trigger — "if final-pass replicate agreement on untouched code stays ≥90% over ≥20 claims (the state doc §1.1 k-reduction falsifier behind log row 27 ...)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers attribution of the ≥90%/≥20 falsifier; does not establish that final-pass agreement "on untouched code" is separately measurable from the merged report's Verdict stability section (which reports all clusters).
**Legibility-target:** for-orchestrator-synthesis

State doc: `**Falsifier worth checking first:** if k=3 fact-check verdicts agree ≥90% of the time on a 20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2.` (`docs/thoughts/code-review-evaluation-state.md:78-79`). Row 27: `§1.1's falsifier stands: ≥90% agreement on a ≥20-claim cumulative sample drops k to 2` (`docs/decisions/log.md:50`). Row 63 says "lowering this pass's k", consistent with "drop to 2".

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:78-79`, `docs/decisions/log.md:50`, `skills/code-review/SKILL.md:633-635`

---

## Claim 12: Row 60 amendment — "(then at 031's k=1); raising it to k=3 was left open as Q-087. **Amended 2026-09-28 (Q-087 [2]):** the final confirming pass now runs the fact-check at k=3 (row 63)."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the amendment clause and its format precedent (row 53); does not re-verify the rest of row 60.
**Legibility-target:** for-orchestrator-synthesis

Row 53 carries `**Amended 2026-09-27 (Q-070 [1], Q-077):**` (`docs/decisions/log.md:76`), the same form. Row 63 exists and says k=3 (Claim 10).

**Evidence:** `docs/decisions/log.md:83`, `docs/decisions/log.md:76`, `docs/decisions/log.md:85`

---

## Claim 13: Decision 031 "Amended in part (noted 2026-09-28): C2's k=1 now applies only to `--loop-pass` passes ... untouched code gets fewer draws than the N≥3 argument below assumes"

**Location:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the note against 031's C2 and N≥3 argument; does not establish the draw count under fallbacks (Claim 6).
**Legibility-target:** for-orchestrator-synthesis

031's argument: `**These are equal at N=3 and the loop favors k=1 for N≥3** — *provided the defect survives to be re-drawn*` (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:119-120`). Under default delta scoping, untouched code gets two k=1 draws (first and final) instead of N≥3, so the note's "fewer draws" is correct.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:108-126`

---

## Claim 14: Override-log struck u4 row — "~~...~~ (moot since decision log 63: every run without `--loop-pass` is k=3)"

**Location:** `docs/reviews/override-log.md:131`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the strike convention and the moot reason; does not establish how Step 3.5 matching treats struck rows (override row C5's gap).
**Legibility-target:** for-orchestrator-synthesis

SKILL.md: `mark them with a \`~\` strikethrough in the \`Finding\` cell if a reviewer judges them no longer applicable, but keep the row for audit purposes` (`skills/code-review/SKILL.md:1260`). The row keeps its verdict and Reason cells, and the strike is in the Finding cell. The moot reason matches Stage 1 `:450-453` (a second standalone review is now k=3 by the flag alone).

**Evidence:** `docs/reviews/override-log.md:131`, `skills/code-review/SKILL.md:1260`, `skills/code-review/SKILL.md:450-453`

---

## Claim 15: Override-log A3 row — "Q-087 still `Status: OPEN` / `Interim: [1]` ... (`docs/working/questions.md:222`, `:235`) ... already archived on `answers-2026-09-28` (48bca90)"

**Location:** `docs/reviews/override-log.md:82`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line citations, the branch/commit, and the source claim number; does not establish that the answers branch merges cleanly with this one.
**Legibility-target:** for-orchestrator-synthesis

`docs/working/questions.md:222` is `**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** OPEN` and `:235` is `- **Interim:** [1]. U4 ...`. `git branch -v` shows `answers-2026-09-28 48bca90 docs(questions): record the 2026-09-28 answers`, whose archive diff adds `### Q-087 ... **Status:** ANSWERED`. Iteration-1 fact-check (09d62ad) has `## Claim 8: Q-087 entry — "**Status:** OPEN" ...`. Note (not a defect in this row): the archive text says `Done in 65e51b7`, the answers branch's own commit carrying the same SKILL.md change, not this branch's 27d483b (paraphrased — no quote available because the observation compares two commits' trees: `git diff 27d483b 65e51b7 --stat` shows no SKILL.md difference).

**Evidence:** `docs/reviews/override-log.md:82`, `docs/working/questions.md:222`, `docs/working/questions.md:235`

---

## Claim 16: Override-log B4 row — "commit 21d4eb8's body says 'the 11 suites … 292/292 ok'; 10 suites ran (`code-fact-check-format.bats` NOT RUN, no generated reports) — fact-check iter2 claim 16"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit text, the iter1 test log, and the claim number; does not establish that the iter1 log was produced at exactly 21d4eb8's tree (inferred from timing).
**Legibility-target:** for-orchestrator-synthesis

21d4eb8 body: `Tests: the 11 suites that read these files, 292/292 ok.` The iter1 log opens `=== NOT RUN: 1 report-dependent suite(s) — no generated reports for their skill ===` / `skills/code-fact-check-format.bats [code-fact-check]`, then lists 10 suites and `1..292` with 292 `ok` lines. Current report (9016e19) has `## Claim 16: Commit 21d4eb8 "Tests: the 11 suites that read these files, 292/292 ok."` (`docs/reviews/q087-code-fact-check-report.md:276`).

**Evidence:** `docs/reviews/override-log.md:80`, `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-19`, `docs/reviews/q087-code-fact-check-report.md:276`

---

## Claim 17: Override-log C5 row — "Step 3.5 match rules (`skills/code-review/SKILL.md:177-179`) do not say whether a struck override-log row still matches, and `references/override-log.md` omits the strikethrough convention of SKILL.md:1260"

**Location:** `docs/reviews/override-log.md:81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line citation and the absence claim; does not establish the rubric's C5 wording beyond that it exists.
**Legibility-target:** for-orchestrator-synthesis

`:177` `1. **Location match.**`, `:178` `2. **Category match.**`, `:179` `3. **Substantive match.**` — none mentions struck rows. `rg -in 'strike|~~' skills/code-review/references/override-log.md` returns nothing (paraphrased — no quote available because the claim covers absence of matching grep results).

**Evidence:** `skills/code-review/SKILL.md:173-186`, `skills/code-review/SKILL.md:1260`, `skills/code-review/references/override-log.md`

---

## Claim 18: Override-log C4 row — "the replication test pins the new final-pass k=3 phrase but not the absence of stale final-pass k=1 wording, nor the Dependencies bullet (`test/skills/code-review-factcheck-replication.bats:141-161`) — fact-check claim 15 note"

**Location:** `docs/reviews/override-log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line range and the source; does not assess the Won't-Fix reason.
**Legibility-target:** for-orchestrator-synthesis

The test opens at `:141` (`@test "replication is loop-aware: ...`) and closes at `:161` (`}`); its greps target `stage1_flat` and Important Reminders only, not line 20. Iteration-1 report (09d62ad) claim 15's Scope: `does not establish negative pinning: nothing asserts that text putting the final pass at k=1 is absent, and the Dependencies bullet is not grepped.`

**Evidence:** `docs/reviews/override-log.md:83`, `test/skills/code-review-factcheck-replication.bats:141-161`

---

## Claim 19: Replication test comment "Decision log 63 narrows that k=1 to --loop-pass passes (asserted below)" and "every run without --loop-pass takes k=3 -- the standalone review and also the loop's final confirming pass, since loop passes see only the delta"

**Location:** `test/skills/code-review-factcheck-replication.bats:142-151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers comment-to-assertion agreement; does not establish negative pinning (Claim 18).
**Legibility-target:** for-orchestrator-synthesis

The assertions below the comment are `grep -qiE 'k=3 protocol below applies to every run without .--loop-pass.'` and `grep -qiE 'standalone single-pass reviews and a loop.s final confirming pass'` (`test/skills/code-review-factcheck-replication.bats:154-157`), both over `stage1_flat` (`stage1 | tr '\n' ' ' | tr -s ' '`, `:34-36`), which match the flattened `:450-451` text (`.` absorbs the backticks and apostrophe).

**Evidence:** `test/skills/code-review-factcheck-replication.bats:28-36`, `test/skills/code-review-factcheck-replication.bats:141-161`, `skills/code-review/SKILL.md:450-451`

---

## Claim 20: The replication test passes on the branch and fails on main's SKILL.md (row 63 "Pinned in ..."; 27d483b "The replication suite pins the rule")

**Location:** `test/skills/code-review-factcheck-replication.bats:141-161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full replication suite on HEAD 182d143 and the loop-aware test against main's SKILL.md; does not establish the test fails for every possible regression (e.g. Dependencies bullet edits).
**Legibility-target:** for-orchestrator-synthesis

(1) Command `timeout 300 scripts/run-tests.sh test/skills/code-review-factcheck-replication.bats`, cwd `/workspace/.claude/wt-q087`, exit 0, 2026-09-28T22:07Z: `1..17`, all ok, including `ok 13 replication is loop-aware: k=1 on loop passes per decision 031, k=3 standalone and on the final pass`. (2) Mirror: main's `skills/code-review/SKILL.md` + this branch's bats file + `scripts/self-improvement.sh` in `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r2/`; command `timeout 120 bats -f 'loop-aware' test/skills/code-review-factcheck-replication.bats`, exit 1, 2026-09-28T22:07Z: `not ok 1 ...` with `k=3 is not scoped to every run without --loop-pass (decision log 63)`.

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q087-final-fc-r2-tests.log`, `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r2/main-mirror.log`, `test/skills/code-review-factcheck-replication.bats:141-161`

---

## Claim 21: Commit 27d483b — "Loop passes review only the delta since the last rubric stamp, so untouched code is drawn only on a loop's first and final passes. The final pass now uses the k=3 protocol; --loop-pass stays k=1. Decision log 63 amends 031 C2. The replication suite pins the rule."

**Location:** commit `27d483b` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each sentence of the body; the "only" in the first sentence carries the verdict (as Claim 6); the other sentences are Verified per Claims 1, 10, 20.
**Legibility-target:** for-author

Everything except "only" checks out (Claims 4, 5, 10, 20). "Drawn only on a loop's first and final passes" has the same fallback exceptions as Claim 6 (`skills/code-review/SKILL.md:117-118`, `workflows/pr-prep.md:248`). Commit messages are immutable, so this is informational.

**Evidence:** `skills/code-review/SKILL.md:106-133`, `docs/decisions/log.md:85`

---

## Claim 22: Commit 21d4eb8 per-finding claims (A1, A2, A4, C1, C2, C3) and "Tests: the 11 suites that read these files, 292/292 ok."

**Location:** commit `21d4eb8` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-finding claims against the HEAD tree and the test line against the iter1 log; the test-count part carries the verdict and is already recorded as override-log row B4.
**Legibility-target:** for-author

A1 (re-attribution to §1.1 / row 27) matches Claim 11; A2 matches Claim 12; A4 (no rubric recognition) matches Claim 5; C1 (Dependencies no longer "stays") matches Claim 1; C2 matches Claim 13; C3 matches Claim 14. Test line: 11 selected, 10 ran, 292/292 ok (Claim 16).

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-19`, `docs/decisions/log.md:83-85`, `skills/code-review/SKILL.md:20`

---

## Claim 23: Commit 182d143 — B1 "log row 60's in-place amendment now uses the log's bold `**Amended 2026-09-28 (Q-087 [2]):**` marker (rows 43, 48, 53)"; B2 ":235, not :232"; B3; B4 "Same 10 suites here: 292/292 ok."

**Location:** commit `182d143` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers B1's precedent citation, B2's line, B3's comment, and B4's count against the iter2 log; B1's precedent parenthetical carries the verdict.
**Legibility-target:** for-author

Only row 53 uses the `**Amended <date> (...):**` form (`**Amended 2026-09-27 (Q-070 [1], Q-077):**`, `docs/decisions/log.md:76`); row 43's bold marker is `**SUPERSEDED BY #44 — recorded as a refuted attempt, not a decision.**` and row 48's is `**Superseded in part by row 49**` (`docs/decisions/log.md:66`, `:71`). They are bold amendment-type markers, not the same marker. B2: `:235` is the Interim line (Claim 15). B3: the comment names log 63 (Claim 19). B4: iter2 log lists 10 suites under `=== Running all tests ===` and `1..292`, 292 `ok` lines, no `not ok`.

**Evidence:** `docs/decisions/log.md:66`, `docs/decisions/log.md:71`, `docs/decisions/log.md:76`, `docs/reviews/override-log.md:82`, `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter2.log:1-15`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`skills/code-review/SKILL.md:131`): "redrawn only on each loop's first and final passes" is the default; Step 1's own fallbacks (missing/non-ancestor/HEAD-equal stamp) and pr-prep 3d's broad-fix fallback redraw untouched code on intermediate passes. Say "by default".
- **Claim 6** (`skills/code-review/SKILL.md:453-455`): same "only" as Claim 2, restated in Stage 1 (and in row 63 at `docs/decisions/log.md:85`).
- **Claim 9** (`skills/code-review/SKILL.md:260`): Step 7 says "3 fact-check replicates" unconditionally; a `--loop-pass` runs 1. Pre-existing, not introduced here.
- **Claim 21** (commit 27d483b): same "only" as Claim 6; immutable commit text.
- **Claim 22** (commit 21d4eb8): "11 suites" ran as 10; already an override-log row (B4).
- **Claim 23** (commit 182d143): bold-marker precedent "(rows 43, 48, 53)": only row 53 uses the `**Amended <date> (...):**` form; 43/48 use SUPERSEDED/Superseded markers.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes — all seven brief items checked; no text anywhere still puts the final pass at k=1 except the open Q-087 entry (override row A3).
- Out of scope: `docs/reviews/q087-*` reports (this review's own outputs), read only to check citation numbers.
- Escalate: orchestrator — the answers branch archives Q-087 as "Done in 65e51b7", a different commit (same SKILL.md content) from this branch's 27d483b; when both branches merge, the archive's commit reference will not point to the merged change on `review/q087`.
- Decisions I made: verdicted the "drawn only on first and final passes" wording Mostly accurate rather than Verified, since the same Step 1 section defines full-scope fallbacks for `--loop-pass`.
