Commit: 21d4eb8

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q087 (branch `review/q087`)
**Scope:** `27d483b..21d4eb8` (PARTIAL — iteration-2 delta: fix commit 21d4eb8 over `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `docs/decisions/log.md` rows 60/63, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`, `docs/reviews/override-log.md`, plus the 21d4eb8 commit message; 27d483b is context only)
**Checked:** 2026-09-28
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 17
**Summary:** 13 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read. Claim 16 resembles the logged "specific measured test-count" class (e.g. "mode1-equiv 33", "All 85 tests"), but here the number is real and only the suite count is loose — not a fabrication.

---

## Claim 1: "the loop's final confirming pass runs k=3, decision log 63"

**Location:** `skills/code-review/SKILL.md:20`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Dependencies bullet's k statement against Stage 1's replication paragraph; does not establish that any consumer outside SKILL.md (pr-prep, review-fix-loop) states k.

`skills/code-review/SKILL.md:20`: "Runs as **k=3 parallel replicates** merged most-severe-wins (k=1 on `--loop-pass` passes, decision 031; the loop's final confirming pass runs k=3, decision log 63)". Matches Stage 1 `skills/code-review/SKILL.md:451-452`: "The **k=3 protocol below applies to every run without `--loop-pass`**: standalone single-pass reviews and a loop's final confirming pass". The iteration-1 wording "stays k=3" (C1) is gone. `workflows/pr-prep.md` and `workflows/review-fix-loop.md` contain no k=1/k=3 statements that could contradict it (paraphrased — no quote available because the claim covers absence: `grep -n "k=1\|k=3\|replicate count"` over both files returned only `pr-prep.md:244`, which names `--loop-pass`/`--range` and no k value).

**Evidence:** `skills/code-review/SKILL.md:20`, `skills/code-review/SKILL.md:451-452`, `workflows/pr-prep.md:244`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "The k=3 protocol below applies to every run without `--loop-pass`: standalone single-pass reviews and a loop's final confirming pass, which runs without the flag per Step 1"

**Location:** `skills/code-review/SKILL.md:451-453`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Step 1 (loop-pass default range) and Step 6 (`--loop-pass` flag definition); does not establish that pr-prep actually omits the flag on the final pass at runtime.

Step 1, `skills/code-review/SKILL.md:127-128`: "Only the final confirming pass (the one run to declare the branch clean) runs without `--loop-pass`, and it keeps the full-branch default". Step 6, `skills/code-review/SKILL.md:246-251`: "`--loop-pass` — mark this run as a **non-final pass of a review-fix loop** … Never pass it on the terminal pass". Both agree the final pass is flagless, so "every run without `--loop-pass`" covers exactly standalone + final. Enclosing paragraph read to `:456` (excerpt ends :453; paragraph continues to :456 — read).

**Evidence:** `skills/code-review/SKILL.md:443-456`, `skills/code-review/SKILL.md:127-131`, `skills/code-review/SKILL.md:246-251`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "The flag alone sets k, so no rubric check is needed to tell the two apart."

**Location:** `skills/code-review/SKILL.md:453-454`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every place in SKILL.md that selects k or mentions `Loop closed at`; does not establish orchestrator runtime behavior.

The only remaining `Loop closed at` references are Step 1 scope/marker handling (`:121`, `:128`) and short-circuit mechanic 6 (`:739`, `:744`), which uses the rubric only to decide the short-circuit marker, and states k from the flag: `skills/code-review/SKILL.md:739` "The run still implies `--no-gate` and k=1. If no canonical rubric exists yet, or the newest one is closed (`Loop closed at`; the first" (excerpt ends :739; mechanic 6 continues to :744 — read). Mechanic 6 applies only to `--loop-pass` runs, so k=1 there is flag-determined. No passage keys k on the rubric (paraphrased — no quote available because the claim covers absence: `grep -n "Loop closed at"` returns only :121, :128, :739, :744). The Stage 1 merged-report header vocabulary (`:607-613`, `**Replication:** k=3` / `k=2 (one replicate failed)`) and the k=1 header (`:448`) are both consistent with flag-set k.

**Evidence:** `skills/code-review/SKILL.md:121`, `:128`, `:448`, `:607-613`, `:735-744`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "Loop passes review only the delta since the last stamp, so code no fix touched is drawn only on the loop's first and final passes"

**Location:** `skills/code-review/SKILL.md:454-455`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Step 1's delta-range rule; does not establish the "first pass" is always full-branch when a stale canonical rubric exists without a `Loop closed at` line (Step 1 fallback cases).

Step 1 `skills/code-review/SKILL.md:129-133`: "Every earlier pass in the loop, including the first of 2-clean's two clean passes, takes the delta range. … Cost to recall: code no fix touches is redrawn only on each loop's first and final passes".

**Evidence:** `skills/code-review/SKILL.md:115-133`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: Important Reminders "k=3 for standalone single-pass reviews and the loop's final confirming pass (decision log 63)"

**Location:** `skills/code-review/SKILL.md:1279-1281`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Stage 1 after the fix; does not establish the bullet was touched by 21d4eb8 (it was not — context only).

`skills/code-review/SKILL.md:1279-1281`: "k=1 per `--loop-pass` inside the review-fix loop (paired with the 2-consecutive-clean rule); k=3 for standalone single-pass reviews and the loop's final confirming pass (decision log 63)". Same partition as Claim 2.

**Evidence:** `skills/code-review/SKILL.md:1278-1284`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: Row 63 "The final pass is the one run without `--loop-pass`; the flag alone sets k, since standalone reviews also run k=3 (`skills/code-review/SKILL.md` Stage 1)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row 63's decision cell against SKILL.md Stage 1; does not establish anything about row 63's rationale cell beyond Claim 7.

Matches `skills/code-review/SKILL.md:451-454` quoted in Claims 2–3. The iteration-1 "recognized by the branch's rubric having no `Loop closed at` line" wording (A4) is removed from the row.

**Evidence:** `docs/decisions/log.md:85`, `skills/code-review/SKILL.md:451-454`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: Row 63 "Revisit, lowering this pass's k, if final-pass replicate agreement on untouched code stays ≥90% over ≥20 claims (the state doc §1.1 k-reduction falsifier behind log row 27, `docs/thoughts/code-review-evaluation-state.md`, applied to this pass)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution (A1 fix) and the threshold values; does not establish that the agreement metric is currently measured per pass or on "untouched code" specifically.

Log row 27, `docs/decisions/log.md:50`: "§1.1's falsifier stands: ≥90% agreement on a ≥20-claim cumulative sample drops k to 2." State doc `docs/thoughts/code-review-evaluation-state.md:78-79`: "**Falsifier worth checking first:** if k=3 fact-check verdicts agree ≥90% of the time on a 20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2." Heading `:46` "### 1.1 Run `code-fact-check` k≥3 times and combine … **implemented** (log row 27)". Attribution, ≥90%, ≥20, and "lowering k" all hold.

**Evidence:** `docs/decisions/log.md:50`, `docs/thoughts/code-review-evaluation-state.md:46`, `:78-79`, `:225`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: Row 60 "the mitigation is that the final confirming pass reviews the full branch (at 031's k=1, unchanged); raising it to k=3 was open as Q-087, since answered [2]: the final pass now runs k=3 (row 63)"

**Location:** `docs/decisions/log.md:83`
**Type:** Reference / Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fix's appended clause and the adjacent parenthetical in the same sentence; does not establish whether the repo's convention is to edit log rows in place.

The appended clause is accurate: row 63 (`docs/decisions/log.md:85`) records the [2] answer. But the preceding clause in the same sentence still asserts, in present tense, "the mitigation is that the final confirming pass reviews the full branch (at 031's k=1, unchanged)", which the appended clause immediately contradicts. Precise version: "(then at 031's k=1)" or "(at k=3 since row 63)". Low-stakes: the row now reads self-correcting, not wrong.

**Evidence:** `docs/decisions/log.md:83`, `docs/decisions/log.md:85`
**Legibility-target:** for-author

---

## Claim 9: 031 "Amended in part (noted 2026-09-28): C2's k=1 now applies only to `--loop-pass` passes. A loop's final confirming pass runs the fact-check at k=3, because loop passes review only the delta, so untouched code gets fewer draws than the N≥3 argument below assumes (decision log #63, Q-087 [2])."

**Location:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the note's consistency with 031's own C2 text and with log row 63; does not establish that 031's Project state / Task status lines were updated elsewhere.

The N≥3 argument is below the note: `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:118-121` "across N k=1 passes at 1−(1−p)ᴺ. **These are equal at N=3 and the loop favors k=1 for N≥3** — *provided the defect survives to be re-drawn*". C2 is k=1 (`:88` "| **C2** | **on** | **1** | **2-clean** | **fix-drift** |"). Row 63 says `--loop-pass` passes stay k=1 and the final pass runs k=3 (`docs/decisions/log.md:85`). "#63" vs the log's bare "63" is cosmetic.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`, `:88`, `:117-121`, `docs/decisions/log.md:85`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: Override-log struck row "(moot since decision log 63: every run without `--loop-pass` is k=3)"

**Location:** `docs/reviews/override-log.md:129`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the moot rationale's truth; does not establish that strike-through is a sanctioned way to retire a row or how Step 3.5 matching treats a struck row.

The rationale is true per `skills/code-review/SKILL.md:451-454` (Claims 2–3): a second standalone review is flagless, hence k=3. On the convention the brief asked about: neither `docs/reviews/override-log.md:1-78` nor `skills/code-review/references/override-log.md` defines any strike/retire/moot convention (paraphrased — no quote available because the claim covers absence: `grep -n -i "strik\|~~\|moot\|supersed"` over both returns only the new row at `:129`). The only stated ordering rule is `docs/reviews/override-log.md` comment "Add new entries at the top", which the two new rows follow. So striking is not against a stated convention, but it is a new, undocumented one; the row's `Override verdict` (`Defer`) and `Reason` ("Revisit if Q-087 raises the final pass to k=3.") are left unstruck, and Step 3.5 has no rule saying a struck `Finding` stops matching.

**Evidence:** `docs/reviews/override-log.md:129`, `docs/reviews/override-log.md:1-78`, `skills/code-review/references/override-log.md:1-60`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11a: New A3 row "The answer is already archived on `answers-2026-09-28` (48bca90)"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that 48bca90 is on that branch and archives Q-087; does not establish the merge-conflict prediction.

`git branch -a --contains 48bca90` → `answers-2026-09-28`; commit body: "Q-065, Q-066, Q-081, Q-083, Q-085, Q-086 and Q-087 are answered and archived." `git show 48bca90:docs/working/questions-archive.md` has "### Q-087 · final-confirming-pass-replicates" at its line 1624.

**Evidence:** `docs/reviews/override-log.md:80`; commit `48bca90`; `docs/working/questions-archive.md:1624` at 48bca90
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11b: New A3 row "Q-087 still `Status: OPEN` / `Interim: [1]` on this branch … (`docs/working/questions.md:222`, `:232`)"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two line citations on branch `review/q087`; does not establish anything about the rubric A3 row it copied from beyond noting the same citation.

`docs/working/questions.md:222` is correct: "**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** OPEN". But `:232` is the options-table row "| **[2] k=3 on the final pass** | Final confirming pass runs three replicates, …"; the Interim line is at `docs/working/questions.md:235`: "- **Interim:** [1]. U4 (feat/u4-code-review-skill) keeps 031's k=1 and cites this entry." The wrong line was inherited from the iteration-1 rubric's A3 row (`docs/reviews/q087-code-review-rubric-2026-09-28.md:23`, same `:232`). Fix: `:235`. The override log is matched by `path:line` proximity in Step 3.5, so the wrong line weakens matching slightly (3 lines off — likely still within proximity).

**Evidence:** `docs/working/questions.md:222`, `:232`, `:235`, `docs/reviews/override-log.md:80`
**Legibility-target:** for-author

---

## Claim 12: New C4 row "(`test/skills/code-review-factcheck-replication.bats:141-161`)" and "the Stage 1 text legitimately says 031 priced both clean passes at k=1"

**Location:** `docs/reviews/override-log.md:81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line range and the quoted Stage 1 phrase; does not judge the Won't-Fix rationale.

The test opens at `test/skills/code-review-factcheck-replication.bats:141` (`@test "replication is loop-aware: …"`) and closes with `}` at `:161`. Stage 1 `skills/code-review/SKILL.md:456`: "(decision log 63, Q-087 [2]; decision 031 priced both clean passes at k=1)".

**Evidence:** `test/skills/code-review-factcheck-replication.bats:141-161`, `skills/code-review/SKILL.md:456`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: Test comment "Decision 031 (config C2) overrules the blanket k=3 mandate: … k=3 remains the protocol for any run without --loop-pass."

**Location:** `test/skills/code-review-factcheck-replication.bats:142-144`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers attribution in the comment; does not affect what the assertions test.

The comment sits under the 031 attribution and says k=3 "remains" for any flagless run. Under 031 alone, k=3 remained only for standalone reviews (031 priced both clean loop passes at k=1: `skills/code-review/SKILL.md:456`); "any run without --loop-pass" (including the final pass) is log 63's extension, which the next comment block states correctly at `:151-153`: "Decision log 63 (Q-087 [2]): every run without --loop-pass takes k=3". Precise version: "k=3 remains the standalone protocol (extended by log 63 below)".

**Evidence:** `test/skills/code-review-factcheck-replication.bats:142-144`, `:151-153`
**Legibility-target:** for-author

---

## Claim 14: The two new assertions match the flattened Stage 1 text and fail on the pre-fix SKILL.md

**Location:** `test/skills/code-review-factcheck-replication.bats:154-157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop-aware test passing on 21d4eb8's SKILL.md and failing on main's and 27d483b's; does not establish that the assertions would catch every stale k wording (C4, declined).

`stage1_flat` (`:34-36`) is `stage1 | tr '\n' ' ' | tr -s ' '`, with `stage1` bounded `/^### Stage 1: Code Fact-Check/,/^### Fact-Check Gate/` (`:29-31`). Assertion 1 `'k=3 protocol below applies to every run without .--loop-pass.'` matches `SKILL.md:451` (the `.` wildcards absorb the backticks). Assertion 2 `'standalone single-pass reviews and a loop.s final confirming pass'` matches `SKILL.md:452` on one source line.

Runs (2026-09-28T21:45:49Z):
- `cd /workspace/.claude/wt-q087 && timeout 300 scripts/run-tests.sh test/skills/code-review-factcheck-replication.bats` → exit 0, 17/17 ok (test 13 is this one).
- Mirrored tree `/home/node/.claude/jobs/9f431b13/tmp/q087-fc2-mirror` with the branch test file and main's SKILL.md: `timeout 120 bats -f "loop-aware" …` → exit 1, `not ok 1 … k=3 is not scoped to every run without --loop-pass (decision log 63)` (line 155). Same with 27d483b's SKILL.md → exit 1, same failure. With 21d4eb8's SKILL.md → exit 0.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:29-36`, `:141-161`; `skills/code-review/SKILL.md:451-452`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc2-tests.log`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc2-mirror/main-run.log`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc2-mirror/27d-run.log`; `/home/node/.claude/jobs/9f431b13/tmp/q087-fc2-mirror/branch-run.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: Commit 21d4eb8 message per-finding claims (A1, A2, A4, C1, C2, C3; "Row 60 was edited in place, following the row-43 precedent of marking superseded rows")

**Location:** commit `21d4eb8` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named fix is present in the diff; does not re-verify their correctness (Claims 1–12 do).

`git diff 09d62ad..21d4eb8` shows: A1 row 63 falsifier re-attributed (Claim 7); A2 row 60 appended clause (Claim 8); A4 Stage 1 rubric-recognition clause removed (Claim 3) and row 63 + test updated; C1 Dependencies "stays"→"runs" (Claim 1); C2 031 note (Claim 9); C3 struck row (Claim 10); A3/C4 rows added (Claims 11–12). Row 43 (`docs/decisions/log.md:66`) carries an in-place "**SUPERSEDED BY #44 …**" marker, so in-place annotation of a log row has precedent; row 60 is annotated rather than marked superseded, which the message's "marking superseded rows" describes loosely.

**Evidence:** commit `21d4eb8`; `docs/decisions/log.md:66`, `:83`, `:85`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: Commit 21d4eb8 "Tests: the 11 suites that read these files, 292/292 ok."

**Location:** commit `21d4eb8` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the log's counts; does not establish which tree the log ran on beyond timing (log mtime 14:41:49, commit 14:42:07, 18 s apart).

`/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-4`: "=== NOT RUN: 1 report-dependent suite(s) — no generated reports for their skill === / skills/code-fact-check-format.bats [code-fact-check]"; `:7-17` lists 10 suites under "Running all tests"; `:19` "1..292"; 292 `ok` lines, 0 `not ok`. So 11 suites were selected but 10 ran; 292/292 is the count from those 10. Precise version: "10 of the 11 suites (code-fact-check-format NOT RUN: no generated reports), 292/292 ok". Resembles but does not match the logged test-count fabrication patterns (the number is real).

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:1-19`
**Legibility-target:** for-author

---

## Claim 17: Commit 21d4eb8 "A3 deferred because answers-2026-09-28 already archives Q-087; editing it here would conflict at merge."

**Location:** commit `21d4eb8` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the archive fact (Claim 11a); the conflict prediction is plausible (both branches would edit the Q-087 block in `docs/working/questions.md`) but was not executed as a trial merge.

See Claim 11a. `review/q087` still has the Q-087 block at `docs/working/questions.md:221-236`, which 48bca90 moves to the archive, so an edit here would touch the same hunk (paraphrased — no quote available because this is a prediction about a merge not performed).

**Evidence:** `docs/working/questions.md:221-236`; commit `48bca90`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 11b** (`docs/reviews/override-log.md:80`): cites Q-087's Interim at `docs/working/questions.md:232`; it is at `:235` (`:232` is the [2] options row). Inherited from the iteration-1 rubric A3.

### Stale
- none

### Mostly Accurate
- **Claim 8** (`docs/decisions/log.md:83`): row 60 still says "(at 031's k=1, unchanged)" in the same sentence that now says the final pass runs k=3; make the parenthetical past tense.
- **Claim 13** (`test/skills/code-review-factcheck-replication.bats:142-144`): comment credits "k=3 for any run without --loop-pass" to 031; that scope is log 63's.
- **Claim 16** (commit `21d4eb8`): "the 11 suites … 292/292 ok" — 10 ran; `code-fact-check-format.bats` was NOT RUN.

### Unverifiable
- none

## Escalations
- `docs/reviews/override-log.md:129` — strike-through as a row-retirement form is undocumented in the log header and `skills/code-review/references/override-log.md`; Step 3.5 has no rule for whether a struck `Finding` still matches, and the row's `Defer`/`Reason` cells stay live. Route to api-consistency / author decision (document the convention or drop the strike for a new row).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes — all seven brief items checked; 17 claims verdicted, test behavior executed against branch, 27d483b and main.
- Out of scope: 27d483b's original change and the q087 review artifacts in 09d62ad (context only); Step 7's "3 fact-check replicates" agent count (pre-existing, untouched by this range).
- Escalate: override-log strike-through convention undefined (see Escalations).
- Decisions I made: treated the override-log strike question as a convention gap (Verified rationale + escalation) rather than an Incorrect, since the log states no convention to violate.
