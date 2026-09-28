Commit: 182d143

# Code Fact-Check Report

**Repository:** claude-workflows (`/workspace/.claude/wt-q087`, branch `review/q087`)
**Scope:** full branch `git diff main...HEAD` at 182d143 — `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `docs/decisions/log.md` (rows 60, 63), `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`, `docs/reviews/override-log.md`, and the messages of commits 27d483b, 21d4eb8, 182d143 (replicate r3 of k=3, final confirming pass; `docs/reviews/q087-*` excluded)
**Checked:** 2026-09-28
**Total claims checked:** 22
**Summary:** 20 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Claim 21a matches the class of three logged entries ("All 85 tests…", "mode1-equiv 33…": a specific measured count quoted from a test run that does not contain it), but it is a miscount, not a fabricated symbol, so no new log entry.

---

## Claim 1: "C2's k=1 now applies only to `--loop-pass` passes. A loop's final confirming pass runs the fact-check at k=3, because loop passes review only the delta, so untouched code gets fewer draws than the N≥3 argument below assumes (decision log #63, Q-087 [2])."

**Location:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that 031's C2 is k=1 per pass, that the "N≥3 argument below" exists and assumes N k=1 draws, and that the SKILL and row 63 now restrict k=1 to `--loop-pass`; does not establish anything about 031's T/L knobs or the 1-clean opt-down, which the note does not touch.

031's C2 row is `| **C2** | **on** | **1** | **2-clean** | **fix-drift** |` (`031…:88`), and the argument the note cites is "across N k=1 passes at 1−(1−p)ᴺ. **These are equal at N=3 and the loop favors k=1 for N≥3**" (`031…:118-119`, excerpt ends :119; bullet continues to :120 — read: "provided the defect survives to be re-drawn"). The SKILL now says "Every `--loop-pass` of a review-fix loop … runs **k=1**" and "The **k=3 protocol below applies to every run without `--loop-pass`**" (`skills/code-review/SKILL.md:444-452`). Row 63 exists at `docs/decisions/log.md:85`. Under the delta default, untouched code gets two draws (claim 14), which is fewer than 3 — so "fewer draws than the N≥3 argument assumes" holds.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`, `:88`, `:116-120`; `skills/code-review/SKILL.md:444-457`; `docs/decisions/log.md:85`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: Row 60 amendment — "the mitigation is that the final confirming pass reviews the full branch (then at 031's k=1); raising it to k=3 was left open as Q-087. **Amended 2026-09-28 (Q-087 [2]):** the final confirming pass now runs the fact-check at k=3 (row 63)."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the amended clause's consistency with row 63, SKILL Stage 1 and Q-087; does not establish that the bold-marker form matches every precedent row (see claim 22a).

Row 63 states "**A review-fix loop's final confirming pass runs the fact-check at k=3 (merged most-severe-wins), not decision 031's k=1.**" (`docs/decisions/log.md:85`), and Q-087 option [2] is "k=3 on the final pass" (`docs/working/questions.md:232`). The "then at 031's k=1" is past-tense and correct for the pre-branch state: main's Stage 1 said "Decision 031 prices both clean passes at k=1; raising the final one to k=3 is open as Q-087" (paraphrased — no quote available because the text exists only on `main`; seen as a removed line in `git diff main...HEAD -- skills/code-review/SKILL.md`).

**Evidence:** `docs/decisions/log.md:83`, `docs/decisions/log.md:85`, `docs/working/questions.md:221-236`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: Row 63 decision cell — "`--loop-pass` passes stay k=1. The final pass is the one run without `--loop-pass`; the flag alone sets k, since standalone reviews also run k=3 (`skills/code-review/SKILL.md` Stage 1). Amends 031 C2, which priced both clean passes at k=1."

**Location:** `docs/decisions/log.md:85`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row 63 vs Stage 1, Step 1, Step 6 and 031's cost check; does not establish that pr-prep actually invokes the final pass without the flag at runtime (that is prose in `workflows/pr-prep.md`, confirmed consistent but not executed).

Stage 1: "The flag alone sets k, so no rubric check is needed to tell the two apart" (`skills/code-review/SKILL.md:453-454`). Step 1: "Only the final confirming pass (the one run to declare the branch clean) runs without `--loop-pass`" (`skills/code-review/SKILL.md:126-127`). pr-prep: "run that final confirmation pass **without** it and without `--range`" (`workflows/pr-prep.md:252-253`). 031 prices both clean passes at k=1: "the second clean pass at k=1 costs ~0.7M" (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:135`) and C2 is k=1 with 2-clean (`031…:88`).

**Evidence:** `docs/decisions/log.md:85`; `skills/code-review/SKILL.md:126-127`, `:444-457`; `workflows/pr-prep.md:250-254`; `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:88`, `:133-137`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: Row 63 — "User answer to Q-087 ([2]), accepting ~+300k tokens per loop."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the figure is the one Q-087 put to the user and is consistent with 031's measured k=1 saving; does not establish an independent measurement of a k=3 final pass's cost.

Q-087: "it trades about +300k tokens per loop against recall" (`docs/working/questions.md:226`) and option [2]'s cost cell "~+300k tokens per loop" (`docs/working/questions.md:232`). 031: "k=1 saves ~250–370k *per pass*" (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:50`); one pass per loop moves to k=3, so ~300k per loop is inside that range. The answer [2] itself is recorded on `answers-2026-09-28` (48bca90), not on this branch (see claim 10).

**Evidence:** `docs/working/questions.md:226`, `:232`; `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:48-50`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: Row 63 — "Since row 60, loop passes review only the delta since the last rubric stamp, so code no fix touched is drawn only on the loop's first and final passes, which weakens 031's N≥3 across-pass resampling argument for that code."

**Location:** `docs/decisions/log.md:85`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default path (row 60's delta default, full-branch first and final passes); does not establish behaviour when pr-prep 3d's "fall back to a full re-review" is taken or a loop pass lacks a usable stamp — both add draws, so they strengthen rather than refute the claim's "only".

Row 60: "a `--loop-pass` with no scope flag defaults to `<stamp>..HEAD` … only the final confirming pass, run without `--loop-pass`, is full-branch" (`docs/decisions/log.md:83`, excerpt from mid-cell; cell continues — read). The same reasoning as claim 14 applies.

**Evidence:** `docs/decisions/log.md:83`, `:85`; `skills/code-review/SKILL.md:111-133`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: Row 63 revisit trigger — "if final-pass replicate agreement on untouched code stays ≥90% over ≥20 claims (the state doc §1.1 k-reduction falsifier behind log row 27, `docs/thoughts/code-review-evaluation-state.md`, applied to this pass)."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution (state doc §1.1 → row 27) and the threshold numbers; does not establish that the Verdict-stability section distinguishes "untouched code" claims (it reports one agreement rate per run — tallying by untouched code would be manual).

State doc §1.1: "**Falsifier worth checking first:** if k=3 fact-check verdicts agree ≥90% of the time on a 20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2." (`docs/thoughts/code-review-evaluation-state.md:78-79`). Row 27: "§1.1's falsifier stands: ≥90% agreement on a ≥20-claim cumulative sample drops k to 2" (`docs/decisions/log.md:50`, excerpt from mid-cell; cell continues — read). The earlier misattribution to 031 was fixed in 21d4eb8 (A1).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:78-79`, `:225`; `docs/decisions/log.md:50`, `:85`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: Row 63 — "Pinned in `test/skills/code-review-factcheck-replication.bats`."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the suite passes on the branch and its loop-aware test fails on main's SKILL.md; does not establish that it pins the Dependencies bullet or absence of stale k=1 wording (override-log C4 declines that).

Command `timeout 300 scripts/run-tests.sh test/skills/code-review-factcheck-replication.bats`, cwd `/workspace/.claude/wt-q087`, exit 0, 2026-09-28T15:07:05-07:00; output shows `ok 13 replication is loop-aware: k=1 on loop passes per decision 031, k=3 standalone and on the final pass`. See claim 20 for the mirror check against main.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:141-161`; `/home/node/.claude/jobs/9f431b13/tmp/q087-final-fc-r3-tests.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: Override-log B4 row — "commit 21d4eb8's body says 'the 11 suites … 292/292 ok'; 10 suites ran (`code-fact-check-format.bats` NOT RUN, no generated reports) — fact-check iter2 claim 16 … Correct count stated in the next fix commit's body".

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit-body quote, the iter1 test log, and 182d143's correction; does not establish that "fact-check iter2 claim 16" numbering is correct (that report is this review's own artifact and was not read).

21d4eb8 body: "Tests: the 11 suites that read these files, 292/292 ok." (`git show 21d4eb8`). Iter1 log: "=== NOT RUN: 1 report-dependent suite(s) — no generated reports for their skill === / skills/code-fact-check-format.bats [code-fact-check]" then ten suites under "=== Running all tests ===" and `1..292` (`q087-tests-iter1.log:3-19`). 182d143 body: "11 were selected but 10 ran … Same 10 suites here: 292/292 ok." (`git show 182d143`).

**Evidence:** `docs/reviews/override-log.md:80`; `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-19`; git:21d4eb8; git:182d143
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: Override-log C5 row — "Step 3.5 match rules (`skills/code-review/SKILL.md:177-179`) do not say whether a struck override-log row still matches, and `references/override-log.md` omits the strikethrough convention of SKILL.md:1260".

**Location:** `docs/reviews/override-log.md:81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two line citations and the absence claim; does not establish whether the gap has any practical effect.

`SKILL.md:177-179` are the three rules "1. **Location match.** … 2. **Category match.** … 3. **Substantive match.**" (`skills/code-review/SKILL.md:177-179`), and none mentions strikethrough. `SKILL.md:1260` is the paragraph containing "mark them with a `~` strikethrough in the `Finding` cell if a reviewer judges them no longer applicable, but keep the row for audit purposes". `rg -ni strike skills/code-review/references/override-log.md` returns nothing (paraphrased — no quote available because claim covers absence of text).

**Evidence:** `skills/code-review/SKILL.md:177-179`, `:1260`; `skills/code-review/references/override-log.md`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: Override-log A3 row — "Q-087 still `Status: OPEN` / `Interim: [1]` on this branch while it implements [2] (`docs/working/questions.md:222`, `:235`) … The answer is already archived on `answers-2026-09-28` (48bca90)".

**Location:** `docs/reviews/override-log.md:82`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line citations and the commit/branch; does not establish the merge-conflict prediction.

`docs/working/questions.md:222`: "**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** OPEN"; `:235`: "- **Interim:** [1]. U4 (feat/u4-code-review-skill) keeps 031's k=1 and cites this entry." `git show 48bca90`: "docs(questions): record the 2026-09-28 answers … Q-086 and Q-087 are answered and archived", and `git branch --contains 48bca90` lists only `answers-2026-09-28`.

**Evidence:** `docs/working/questions.md:222`, `:235`; git:48bca90
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: Override-log C4 row — "the replication test pins the new final-pass k=3 phrase but not the absence of stale final-pass k=1 wording, nor the Dependencies bullet (`test/skills/code-review-factcheck-replication.bats:141-161`) … (the Stage 1 text legitimately says 031 priced both clean passes at k=1)".

**Location:** `docs/reviews/override-log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line range and what the test asserts; does not judge the Won't-Fix rationale.

`:141` is the `@test "replication is loop-aware…"` line and `:161` its closing brace; the assertions are all positive `grep -q` checks on `stage1_flat` and Important Reminders (`test/skills/code-review-factcheck-replication.bats:145-160`), none reads line 20. Stage 1 says "decision 031 priced both clean passes at k=1" (`skills/code-review/SKILL.md:456-457`).

**Evidence:** `test/skills/code-review-factcheck-replication.bats:141-161`; `skills/code-review/SKILL.md:456`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: Struck u4 row — "~~A second standalone review … runs k=1 instead of k=3 …~~ (moot since decision log 63: every run without `--loop-pass` is k=3)".

**Location:** `docs/reviews/override-log.md:131`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the strikethrough form against SKILL.md:1260 and the "moot" reason; does not establish how Step 3.5 treats a struck row (claim 9's open gap).

The struck text sits in the `Finding` cell, and the row is kept, as SKILL.md:1260 requires ("mark them with a `~` strikethrough in the `Finding` cell … but keep the row"). "Moot" holds: the rubric-based final-pass classification it described is gone; Stage 1 now says "The flag alone sets k, so no rubric check is needed" (`skills/code-review/SKILL.md:453-454`).

**Evidence:** `docs/reviews/override-log.md:131`; `skills/code-review/SKILL.md:453-454`, `:1260`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: Dependencies bullet — "Runs as **k=3 parallel replicates** merged most-severe-wins (k=1 on `--loop-pass` passes, decision 031; the loop's final confirming pass runs k=3, decision log 63)".

**Location:** `skills/code-review/SKILL.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1; does not establish test coverage of this line (none, per claim 11).

Matches Stage 1 at `skills/code-review/SKILL.md:444-452` quoted in claims 1 and 3.

**Evidence:** `skills/code-review/SKILL.md:20`, `:444-457`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: Step 1 — "Cost to recall: code no fix touches is redrawn only on each loop's first and final passes, which weakens decision 031's N≥3 resampling argument for k=1 on that code; the mitigation is that the final confirming pass reviews the full branch at k=3 (decision log 63, Q-087 [2])."

**Location:** `skills/code-review/SKILL.md:131-133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default loop path under Step 1 and pr-prep 3d; does not establish draw counts when pr-prep's broad-fix fallback to full re-review is taken, or on a new loop started mid-branch after `Loop closed at` (both give more full-branch draws).

First pass: no canonical rubric or a closed one → "use full-branch scope" (`skills/code-review/SKILL.md:118-121`); pr-prep: "On the first iteration, run full review skills against the complete diff vs main" (`workflows/pr-prep.md:242`). Middle passes: "Every earlier pass in the loop, including the first of 2-clean's two clean passes, takes the delta range" (`skills/code-review/SKILL.md:128-129`). Final: "runs without `--loop-pass`, and it keeps the full-branch default" (`:126-127`) and, per Stage 1, k=3 (`:451-452`).

**Evidence:** `skills/code-review/SKILL.md:111-133`, `:451-452`; `workflows/pr-prep.md:242-254`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: Stage 1 — "Every `--loop-pass` … runs **k=1** … The **k=3 protocol below applies to every run without `--loop-pass`**: standalone single-pass reviews and a loop's final confirming pass … The flag alone sets k" — and no text anywhere still says the final pass runs k=1.

**Location:** `skills/code-review/SKILL.md:444-457`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Step 1, Step 6 `--loop-pass`, short-circuit mechanics 5-6, merged-header vocabulary, Dependencies, Important Reminders, `references/rubric.md`, pr-prep 3d, review-fix-loop.md and Gate 1h, plus a repo-wide search; does not establish Step 7's agent count, which says "3 fact-check replicates" for every run including k=1 loop passes (pre-existing, untouched by this branch, overstates only loop passes).

Step 6: "`--loop-pass` — mark this run as a **non-final pass** … Never pass it on the terminal pass" (`skills/code-review/SKILL.md:246-251`). Mechanic 6 concerns only `--loop-pass` runs: "The run still implies `--no-gate` and k=1" (`:739`). The k=1 header "`**Replication:** k=1 (loop pass, decision 031)`" (`:448`) is scoped to loop passes; the merged header "`**Replication:** k=3`" (`:609`) is what a final pass now writes, and Gate 1h treats `k=3*` as "full replication — nothing to report" (`scripts/self-improvement.sh:1606`) — so the change also clears a false "degraded" note the old k=1 final pass would have produced. `rg` for final/terminal-pass text mentioning k=1 outside `docs/reviews/` and `archive/` finds only the updated lines, Q-087 itself, and row 60's past-tense clause (paraphrased — no quote available because claim covers absence of matches). `workflows/review-fix-loop.md` and `references/rubric.md:15-32` state no k.

**Evidence:** `skills/code-review/SKILL.md:20`, `:124-133`, `:246-251`, `:259`, `:444-457`, `:607-613`, `:735-744`, `:1278-1284`; `workflows/pr-prep.md:244-254`; `scripts/self-improvement.sh:1570-1617`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: Stage 1 — "Loop passes review only the delta since the last stamp, so code no fix touched is drawn only on the loop's first and final passes; the final pass's k=3 restores the within-pass redundancy on that code".

**Location:** `skills/code-review/SKILL.md:454-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same narrow reading as claim 14 (default loop path); does not establish that k=3 on one pass restores 031's full N≥3 parity — untouched code gets k=1 + k=3 = 4 fact-check draws, but only two draws of the critic panel, which 031 also counted ("2-clean counts every stage's second draw").

Same mechanics as claim 14. "Within-pass redundancy" is exactly what k=3 supplies per 031: "k=3 duplicates within-pass what 2-clean already provides across-pass" (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:161`, excerpt from mid-line; line continues — read).

**Evidence:** `skills/code-review/SKILL.md:454-456`, `:111-133`; `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:161`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: Stage 1 parenthetical — "decision 031 priced both clean passes at k=1".

**Location:** `skills/code-review/SKILL.md:456-457`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers 031's C2 cost check; does not establish anything about 1-clean opt-down branches.

031: "the second clean pass at k=1 costs ~0.7M" and C2 = k=1 + 2-clean (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:88`, `:135`).

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:88`, `:133-137`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: Important Reminders — "k=1 per `--loop-pass` inside the review-fix loop (paired with the 2-consecutive-clean rule); k=3 for standalone single-pass reviews and the loop's final confirming pass (decision log 63)".

**Location:** `skills/code-review/SKILL.md:1278-1281`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1; does not establish more.

Matches `skills/code-review/SKILL.md:444-451` (claims 1, 3, 15).

**Evidence:** `skills/code-review/SKILL.md:1278-1284`, `:444-457`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: Test comment — "Decision log 63 narrows that k=1 to --loop-pass passes (asserted below)" and "every run without --loop-pass takes k=3 -- the standalone review and also the loop's final confirming pass, since loop passes see only the delta."

**Location:** `test/skills/code-review-factcheck-replication.bats:142-157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers comment-to-assertion agreement and that the regexes match flattened Stage 1 text; does not establish runtime pass/fail (claims 7, 20).

`stage1_flat` is `stage1 | tr '\n' ' ' | tr -s ' '`, where `stage1` extracts `/^### Stage 1: Code Fact-Check/,/^### Fact-Check Gate/p` (`test/skills/code-review-factcheck-replication.bats:29-36`). The regex `k=3 protocol below applies to every run without .--loop-pass.` (`:154`) matches "The **k=3 protocol below applies to every run without `--loop-pass`**" once wraps collapse (the `**` precede "k=3" and the backticks fill the two `.`); `standalone single-pass reviews and a loop.s final confirming pass` (`:156`) matches "standalone single-pass reviews and a loop's final confirming pass" across the `:451`→`:452` wrap. The B3 fix (182d143) removed the attribution to 031 from the comment.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:29-36`, `:141-161`; `skills/code-review/SKILL.md:451-452`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: The loop-aware test fails on main's SKILL.md (the pin is live).

**Location:** `test/skills/code-review-factcheck-replication.bats:154-155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the single test against main's and the branch's SKILL.md in a mirror tree; does not establish the other 16 tests' behaviour on main.

Mirror at `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r3/` (branch bats file + `git show main:skills/code-review/SKILL.md`). Command `timeout 120 bats -f 'replication is loop-aware' test/skills/code-review-factcheck-replication.bats`, cwd the mirror, exit 1, ~2026-09-28T15:07-07:00: "not ok 1 … `|| fail "k=3 is not scoped to every run without --loop-pass (decision log 63)"' failed". Control with the branch SKILL.md in the same mirror: exit 0, "ok 1".

**Evidence:** `test/skills/code-review-factcheck-replication.bats:154-155`; `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r3/main-mirror.log`; `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r3/branch-mirror.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21a: Commit 21d4eb8 — "Tests: the 11 suites that read these files, 292/292 ok."

**Location:** git:21d4eb8
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the suite count against the iter1 log; does not dispute 292/292, which the log confirms.

Ten suites ran; the eleventh was NOT RUN: "=== NOT RUN: 1 report-dependent suite(s) … skills/code-fact-check-format.bats" and ten names under "=== Running all tests ===", `1..292` with 292 `ok` lines and 0 `not ok` (`q087-tests-iter1.log:3-19`). Already recorded as override-log B4 (Won't-Fix, corrected in 182d143's body) — claim 8. Commit-message claim in (unpushed) history: routes to the override log, which already holds it.

**Evidence:** git:21d4eb8; `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-19`; `docs/reviews/override-log.md:80`
**Legibility-target:** for-author

---

## Claim 21b: Commit 21d4eb8's A1–C3 bullets and 27d483b's body ("untouched code is drawn only on a loop's first and final passes … The final pass now uses the k=3 protocol; --loop-pass stays k=1. Decision log 63 amends 031 C2. The replication suite pins the rule.")

**Location:** git:27d483b
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the tree at 182d143 (A1 re-attribution, A2 row 60 pointer, A4 flag-alone rule, C1 Dependencies, C2 031 note, C3 struck row, A3/C4 override rows); does not re-verify the prior-state wording each bullet says was wrong beyond the diff.

A1 → claim 6; A2 → claim 2; A4 → `skills/code-review/SKILL.md:453-454`; C1 → claim 13; C2 → claim 1; C3 → claim 12; A3/C4 rows → claims 10-11. 27d483b's claims → claims 3, 5, 7, 14.

**Evidence:** git:27d483b; git:21d4eb8; `skills/code-review/SKILL.md:20`, `:444-457`; `docs/decisions/log.md:83`, `:85`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22a: Commit 182d143 B1 — "log row 60's in-place amendment now uses the log's bold `**Amended 2026-09-28 (Q-087 [2]):**` marker (rows 43, 48, 53)".

**Location:** git:182d143
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three cited precedent rows; does not establish a written convention for the marker (none found).

Only row 53 uses that form: "**Amended 2026-09-27 (Q-070 [1], Q-077):**" (`docs/decisions/log.md:76`). Row 43's bold marker is "**SUPERSEDED BY #44 — recorded as a refuted attempt, not a decision.**" (`docs/decisions/log.md:66`) and row 48's is "**Superseded in part by row 49**" (`docs/decisions/log.md:71`). All three are bold in-place change markers, so the precedent holds; the precise version is "the log's bold in-place marker (row 53's `**Amended <date> (…):**` form; rows 43, 48 use Superseded)".

**Evidence:** `docs/decisions/log.md:66`, `:71`, `:76`, `:83`
**Legibility-target:** for-author

---

## Claim 22b: Commit 182d143 B2–B4 — "B2: the override-log A3 row cites the Q-087 Interim line at questions.md:235, not :232 … B3: the replication test comment no longer credits … to decision 031; it names log 63 … 11 were selected but 10 ran … Same 10 suites here: 292/292 ok."

**Location:** git:182d143
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers B2/B3 against the tree and the "10 suites, 292/292" against `q087-tests-iter2.log`; does not establish that iter2 log was produced at exactly 182d143 (log carries no commit).

`:235` is the Interim line (claim 10); test comment `:144`, `:151` names "Decision log 63" (claim 19); iter2 log lists ten suites under "=== Running all tests ===" and `1..292`, 292 `ok`, 0 `not ok` (`q087-tests-iter2.log:3-15`).

**Evidence:** git:182d143; `docs/working/questions.md:235`; `test/skills/code-review-factcheck-replication.bats:144`, `:151`; `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter2.log:3-15`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 21a** (git:21d4eb8): "the 11 suites" — 10 ran (`code-fact-check-format.bats` NOT RUN). Already handled by override-log B4 (`docs/reviews/override-log.md:80`); no further action.

### Stale
- none

### Mostly Accurate
- **Claim 22a** (git:182d143): "(rows 43, 48, 53)" — only row 53 uses the `**Amended <date> (…):**` form; 43 and 48 use bold Superseded markers. Commit-message only; nothing to fix in the tree.

### Unverifiable
- none

Note outside the claim set (pre-existing, not introduced by this branch): Step 7 says "Total agent count (3 fact-check replicates + N critics …)" (`skills/code-review/SKILL.md:259`) for every run, which overstates `--loop-pass` runs (k=1). It does not assert k=1 for the final pass.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes — all seven brief items checked; no text still says the final pass runs k=1; test pins the rule and fails on main.
- Out of scope: `docs/reviews/q087-*` (this review's own outputs); Step 7's pre-existing agent-count wording (noted, not verdicted).
- Escalate: nothing
- Decisions I made: verdicted 21d4eb8's "11 suites" as Incorrect although it is already an override-log Won't-Fix row, so the merged report records it rather than dropping it; split 21d4eb8 and 182d143 into count vs other claims because their verdicts diverge.
