Commit: 182d143

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q087 (branch `review/q087`)
**Scope:** Full branch `git diff main...HEAD` at 182d143 — `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `docs/decisions/log.md` (rows 60, 63), `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`, `docs/reviews/override-log.md`, and the bodies of commits 27d483b, 21d4eb8, 182d143. The `docs/reviews/q087-*` review outputs are excluded (read only as advisory context).
**Checked:** 2026-09-28
**Total claims checked:** 23
**Summary:** 19 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Claim 20b (a test-suite count in a commit body) resembles the logged "specific measured test-count" class ("All 85 tests", "mode1-equiv 33"); here the 292 figure is real and only the suite count is loose, so it is not a fabrication.

Repo-wide sweep for leftover "final pass runs k=1" wording (`rg -n "k=1"` over the repo excluding `docs/reviews/`, `archive/`, `runs/`, `external/`, filtered for final/terminal/loop wording): the only hits that still describe the final pass at k=1 are the Q-087 question text itself (`docs/working/questions.md:224-235`, the question and its [1] option, which are historical by nature, and the Interim line already covered by the A3 override row) and 031's own body (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:134-135`, now carrying the Amended-in-part note). No normative text in `skills/`, `workflows/`, `scripts/` or `test/` still says the final pass runs k=1.

---

## Claim 1: "C2's k=1 now applies only to `--loop-pass` passes. A loop's final confirming pass runs the fact-check at k=3, because loop passes review only the delta, so untouched code gets fewer draws than the N≥3 argument below assumes (decision log #63, Q-087 [2])."

**Location:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the note matches C2 and the N≥3 argument in 031's body and matches row 63 and SKILL.md Stage 1; does not establish that 031's Task-status line (":19-26", "K/C SKILL edits remain follow-up", pre-existing) is current.
**Legibility-target:** for-orchestrator-synthesis

C2 is the k=1 configuration, `031:88`:

```
| **C2** | **on** | **1** | **2-clean** | **fix-drift** | k=1 savings fund a second attestation draw; **chosen** |
```

The N≥3 argument is conditional on re-draws, `031:117-121`:

```
  one k=3 pass at 1−(1−p)³; across N k=1 passes at 1−(1−p)ᴺ. **These are equal at N=3 and
  the loop favors k=1 for N≥3** — *provided the defect survives to be re-drawn*, i.e.
  provided we require more than one clean pass.
```

(excerpt ends :121; the "Why k=1 is now defensible" section continues to :125 — read.) Under the delta default, untouched code gets two k=1-equivalent draws (first and final pass), fewer than 3, which is what the note says. SKILL.md Stage 1 now reads "Every `--loop-pass` of a review-fix loop … runs **k=1**" (`skills/code-review/SKILL.md:444-445`), and row 63 exists at `docs/decisions/log.md:85`.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`, `:88`, `:108-125`; `skills/code-review/SKILL.md:443-456`; `docs/decisions/log.md:85`

---

## Claim 2: Row 60 — "the mitigation is that the final confirming pass reviews the full branch (then at 031's k=1); raising it to k=3 was left open as Q-087. **Amended 2026-09-28 (Q-087 [2]):** the final confirming pass now runs the fact-check at k=3 (row 63)."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the amended clause's accuracy against row 63 and SKILL.md, and the bold marker's form against row 53; does not establish the rest of row 60 (unchanged by this branch).
**Legibility-target:** for-orchestrator-synthesis

Row 63 states the new rule: "**A review-fix loop's final confirming pass runs the fact-check at k=3 (merged most-severe-wins), not decision 031's k=1.**" (`docs/decisions/log.md:85`). The marker form matches row 53's `**Amended 2026-09-27 (Q-070 [1], Q-077):**` (`docs/decisions/log.md`, row 53, found by `rg -n '^\| 53 \|'`). SKILL.md Stage 1 applies the k=3 protocol "to every run without `--loop-pass`" (`skills/code-review/SKILL.md:451`).

**Evidence:** `docs/decisions/log.md:83`, `docs/decisions/log.md:85`, `skills/code-review/SKILL.md:451-453`

---

## Claim 3: Row 63 decision — "`--loop-pass` passes stay k=1. The final pass is the one run without `--loop-pass`; the flag alone sets k, since standalone reviews also run k=3 (`skills/code-review/SKILL.md` Stage 1). Amends 031 C2, which priced both clean passes at k=1."

**Location:** `docs/decisions/log.md:85`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with SKILL.md Stage 1, Step 1, pr-prep 3d and 031's cost check; does not establish that Step 6's `--loop-pass` flag description lists k among the flag's effects (it does not — pre-existing, see Claim 15).
**Legibility-target:** for-orchestrator-synthesis

SKILL.md Stage 1: "The flag alone sets k, so no rubric check is needed to tell the two apart." (`skills/code-review/SKILL.md:453-454`). Step 1: "Only the final confirming pass (the one run to declare the branch clean) runs without `--loop-pass`" (`skills/code-review/SKILL.md:126-127`). pr-prep 3d: "`--loop-pass` also sets the fact-check replicate count and the short-circuit" (`workflows/pr-prep.md:246`). 031 priced the second clean pass at k=1: "the second clean pass at k=1 costs ~0.7M" (`031:134-135`).

**Evidence:** `docs/decisions/log.md:85`, `skills/code-review/SKILL.md:126-127`, `:443-456`, `workflows/pr-prep.md:246`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:134-135`

---

## Claim 4: Row 63 — "accepting ~+300k tokens per loop"

**Location:** `docs/decisions/log.md:85`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with 031's measured per-pass k=1 saving and Q-087's own stated cost; does not establish a measured cost for a k=3 final pass (none exists yet).
**Legibility-target:** for-orchestrator-synthesis

031 records "k=1 saves ~250–370k *per pass*" (`031:50`) and "k=1 saves ~30% of every pass (~300k)" (`031:134`); reversing that on one pass per loop costs the same ~300k. Q-087's option [2] states "~+300k tokens per loop" (`docs/working/questions.md:232`). Medium because the figure is an estimate carried over from E1, not a measurement of this pass.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:48-50`, `:134`; `docs/working/questions.md:232`

---

## Claim 5: Row 63 revisit trigger — "if final-pass replicate agreement on untouched code stays ≥90% over ≥20 claims (the state doc §1.1 k-reduction falsifier behind log row 27, `docs/thoughts/code-review-evaluation-state.md`, applied to this pass)"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution to §1.1 and row 27 and the thresholds; does not establish that the agreement rate can be measured for "untouched code" specifically (the Verdict stability section reports a whole-report rate).
**Legibility-target:** for-orchestrator-synthesis

State doc §1.1: "**Falsifier worth checking first:** if k=3 fact-check verdicts agree ≥90% of the time on a 20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2." (`docs/thoughts/code-review-evaluation-state.md:78-79`). Row 27: "§1.1's falsifier stands: ≥90% agreement on a ≥20-claim cumulative sample drops k to 2" (`docs/decisions/log.md:50`). Thresholds and attribution match.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:78-79`, `docs/decisions/log.md:50`, `docs/decisions/log.md:85`

---

## Claim 6: Row 63 — "Pinned in `test/skills/code-review-factcheck-replication.bats`."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the named suite asserts the new rule and fails on main's SKILL.md; does not establish negative pinning (no assertion that final-pass-k=1 text is absent; declined as C4 in the override log).
**Legibility-target:** for-orchestrator-synthesis

The test asserts `'k=3 protocol below applies to every run without .--loop-pass.'` (`test/skills/code-review-factcheck-replication.bats:154`). Executed; see Claim 18 for provenance.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:141-161`; `/home/node/.claude/jobs/9f431b13/tmp/q087-final-fc-r1-tests.log`; `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r1/main-mirror.log`

---

## Claim 7: B4 override row — "commit 21d4eb8's body says 'the 11 suites … 292/292 ok'; 10 suites ran (`code-fact-check-format.bats` NOT RUN, no generated reports) — fact-check iter2 claim 16"

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote, the suite count and the iter2 citation; does not establish the Won't-Fix judgment.
**Legibility-target:** for-orchestrator-synthesis

The iteration-1 test log shows one suite not run and ten run:

```
=== NOT RUN: 1 report-dependent suite(s) — no generated reports for their skill ===
  skills/code-fact-check-format.bats [code-fact-check]
```

(`/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-4`), followed by ten listed suites and `1..292` with 292 `ok` lines and 0 `not ok`. The HEAD version of `docs/reviews/q087-code-fact-check-report.md` (iteration 2, committed 9016e19) has `## Claim 16: Commit 21d4eb8 "Tests: the 11 suites that read these files, 292/292 ok."` at `:276`.

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-16`, `docs/reviews/q087-code-fact-check-report.md:276`, `docs/reviews/override-log.md:80`

---

## Claim 8: C5 override row — "Step 3.5 match rules (`skills/code-review/SKILL.md:177-179`) do not say whether a struck override-log row still matches, and `references/override-log.md` omits the strikethrough convention of SKILL.md:1260"

**Location:** `docs/reviews/override-log.md:81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two line citations and the absence claim; does not establish whether the gap has practical effect.
**Legibility-target:** for-orchestrator-synthesis

`skills/code-review/SKILL.md:177-179` are the three match rules ("1. **Location match.** …", "2. **Category match.** …", "3. **Substantive match.** …"), none mentioning strikethrough. `SKILL.md:1260`: "mark them with a `~` strikethrough in the `Finding` cell if a reviewer judges them no longer applicable, but keep the row for audit purposes". `grep -n 'strikethrough\|~~' skills/code-review/references/override-log.md` returns nothing (paraphrased — no quote available because the claim covers absence of text).

**Evidence:** `skills/code-review/SKILL.md:177-179`, `skills/code-review/SKILL.md:1260`, `skills/code-review/references/override-log.md`

---

## Claim 9: A3 override row — "Q-087 still `Status: OPEN` / `Interim: [1]` on this branch while it implements [2] (`docs/working/questions.md:222`, `:235`) — fact-check claim 8 … The answer is already archived on `answers-2026-09-28` (48bca90)"

**Location:** `docs/reviews/override-log.md:82`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the questions.md line citations, the branch and commit, and the report-claim citation; does not establish the Defer judgment.
**Legibility-target:** for-author

Line citations hold: `docs/working/questions.md:222` is `**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** OPEN` and `:235` is `- **Interim:** [1]. U4 (feat/u4-code-review-skill) keeps 031's k=1 and cites this entry.` Branch `answers-2026-09-28` exists and 48bca90 ("docs(questions): record the 2026-09-28 answers") archives Q-087 as `**Status:** ANSWERED` with "**Answered 2026-09-28: [2] k=3 on the final pass.**" (`git show 48bca90`, diff lines 165-168). The imprecision: "fact-check claim 8" resolves only against the iteration-1 report (09d62ad, `## Claim 8: Q-087 entry — "**Status:** OPEN" …` at `:131`). At HEAD the same file is the iteration-2 report, whose Claim 8 is about row 60 (`docs/reviews/q087-code-fact-check-report.md:128`). The B4 row in the same log qualifies its citation as "iter2"; this row should say "iter1".

**Evidence:** `docs/working/questions.md:222`, `:235`; `git show 09d62ad:docs/reviews/q087-code-fact-check-report.md` `:131`; `docs/reviews/q087-code-fact-check-report.md:128`; `git show 48bca90`

---

## Claim 10: C4 override row — "the replication test pins the new final-pass k=3 phrase but not the absence of stale final-pass k=1 wording, nor the Dependencies bullet (`test/skills/code-review-factcheck-replication.bats:141-161`) — fact-check claim 15 note"

**Location:** `docs/reviews/override-log.md:83`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line range, the substance, and the report-claim citation; does not establish the Won't-Fix judgment.
**Legibility-target:** for-author

The test spans `:141` (`@test "replication is loop-aware: …"`) to `:161` (`}`), and no grep in it covers the Dependencies bullet or asserts absence (paraphrased — no quote available because the claim covers absence of assertions). Same citation ambiguity as Claim 9: "claim 15 note" matches the iteration-1 report (09d62ad, Claim 15's Scope: "does not establish negative pinning … and the Dependencies bullet is not grepped"), while HEAD's report Claim 15 is about commit 21d4eb8's message (`docs/reviews/q087-code-fact-check-report.md:260`).

**Evidence:** `test/skills/code-review-factcheck-replication.bats:141-161`; `git show 09d62ad:docs/reviews/q087-code-fact-check-report.md` `:259`; `docs/reviews/q087-code-fact-check-report.md:260`

---

## Claim 11: Struck u4 row — "~~A second standalone review … runs k=1 instead of k=3 …~~ (moot since decision log 63: every run without `--loop-pass` is k=3)"

**Location:** `docs/reviews/override-log.md:131`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the strikethrough form against SKILL.md:1260 and the moot reason against Stage 1; does not establish whether struck rows still match at Step 3.5 (the open C5 gap).
**Legibility-target:** for-orchestrator-synthesis

The Finding cell is wrapped in `~~…~~`, the row is kept, and the other cells are unchanged, as SKILL.md:1260 requires ("mark them with a `~` strikethrough in the `Finding` cell … but keep the row"). The moot reason matches Stage 1: "The **k=3 protocol below applies to every run without `--loop-pass`**" and "The flag alone sets k, so no rubric check is needed" (`skills/code-review/SKILL.md:451-454`). The old rubric-based recognition ("recognized by the branch's canonical rubric existing without a `Loop closed at` line", main's Stage 1) is gone: `rg -n 'recognized by|open loop rubric'` over `skills workflows docs/decisions test scripts` returns nothing (paraphrased — no quote available because the claim covers absence).

**Evidence:** `docs/reviews/override-log.md:131`, `skills/code-review/SKILL.md:1260`, `skills/code-review/SKILL.md:451-454`

---

## Claim 12: Dependencies — "Runs as **k=3 parallel replicates** merged most-severe-wins (k=1 on `--loop-pass` passes, decision 031; the loop's final confirming pass runs k=3, decision log 63)"

**Location:** `skills/code-review/SKILL.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1 and Important Reminders; does not establish Stage 2.5's separate k=1 (a distinct dispatch, `:1033`).
**Legibility-target:** for-orchestrator-synthesis

Stage 1: "Every `--loop-pass` of a review-fix loop … runs **k=1**" (`:444-445`) and "k=3 protocol below applies to every run without `--loop-pass`: standalone single-pass reviews and a loop's final confirming pass" (`:451-452`).

**Evidence:** `skills/code-review/SKILL.md:20`, `:443-456`, `:1278-1282`

---

## Claim 13: Step 1 — "Cost to recall: code no fix touches is redrawn only on each loop's first and final passes, which weakens decision 031's N≥3 resampling argument for k=1 on that code; the mitigation is that the final confirming pass reviews the full branch at k=3 (decision log 63, Q-087 [2])."

**Location:** `skills/code-review/SKILL.md:131-133`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default loop path (first pass full-branch because no rubric exists; later `--loop-pass` passes delta; final pass full-branch without the flag); does not establish the sanctioned deviations — pr-prep 3d's "fall back to a full re-review" when fixes are broad (`workflows/pr-prep.md:252`) and `--full` — which add draws.
**Legibility-target:** for-orchestrator-synthesis

Step 1: "If there is no such file … use full-branch scope" (`:120-121`), "Every earlier pass in the loop, including the first of 2-clean's two clean passes, takes the delta range" (`:128-129`), and "Only the final confirming pass … runs without `--loop-pass`, and it keeps the full-branch default" (`:126-127`). With the Stage 1 rule (`:451-452`), the final pass is k=3.

**Evidence:** `skills/code-review/SKILL.md:111-135`, `:451-452`, `workflows/pr-prep.md:244-254`

---

## Claim 14: Stage 1 — "Every `--loop-pass` of a review-fix loop (which requires **2 consecutive clean passes** before merge) runs **k=1**. … The **k=3 protocol below applies to every run without `--loop-pass`**: standalone single-pass reviews and a loop's final confirming pass, which runs without the flag per Step 1. The flag alone sets k, so no rubric check is needed to tell the two apart."

**Location:** `skills/code-review/SKILL.md:443-454`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Step 1 (`:126-127`), short-circuit mechanic 6 (`:739`, "The run still implies `--no-gate` and k=1" for a `--loop-pass`), the merged-report header (`:607-613`, `**Replication:** k=3`), Important Reminders (`:1278-1284`), pr-prep 3d (`workflows/pr-prep.md:246`, `:256-259`), `review-fix-loop.md` (no k statements; defers `--loop-pass` to the skill at `:7`), and Gate 1h (`scripts/self-improvement.sh`, `k=3*) : ;;` treats the final pass's k=3 as full replication); does not establish that Step 6's `--loop-pass` entry (`:246-251`) or Step 7's "3 fact-check replicates" agent count (`:259`) mention k=1 — neither does, both pre-existing on main.
**Legibility-target:** for-orchestrator-synthesis

Mechanic 6: "Run Stage 2 in full despite the red … The run still implies `--no-gate` and k=1." (`:737-739`; excerpt ends :739, mechanic 6 continues to :744 — read) — a `--loop-pass`-only path, consistent. Merged header: "a bolded `**Replication:** k=3` field (or `**Replication:** k=2 (one replicate failed)` on the degraded path)" (`:609-610`), which the final pass now produces, and which Gate 1h accepts without a note. pr-prep: "run that final confirmation pass **without** it and without `--range`" (`workflows/pr-prep.md:257-258`).

**Evidence:** `skills/code-review/SKILL.md:126-127`, `:246-251`, `:259`, `:443-456`, `:607-613`, `:735-744`, `:1278-1284`; `workflows/pr-prep.md:244-259`; `workflows/review-fix-loop.md:7`; `scripts/self-improvement.sh:1570-1617`

---

## Claim 15: Stage 1 — "Loop passes review only the delta since the last stamp, so code no fix touched is drawn only on the loop's first and final passes; the final pass's k=3 restores the within-pass redundancy on that code (decision log 63, Q-087 [2]; decision 031 priced both clean passes at k=1)."

**Location:** `skills/code-review/SKILL.md:454-456`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the same default-path reasoning as Claim 13 and the 031 pricing; does not establish that "restores" is quantitatively sufficient (untouched code gets 1 + 3 = 4 draws, which meets 031's N≥3 by count but mixes k=1 and k=3 draws).
**Legibility-target:** for-orchestrator-synthesis

Same Step 1 evidence as Claim 13. 031: "the second clean pass at k=1 costs ~0.7M" (`031:134-135`). The first pass is a `--loop-pass` (pr-prep: "Pass `--loop-pass` … on any pass you expect to be followed by a fix", `workflows/pr-prep.md:256-257`), so k=1 at full scope.

**Evidence:** `skills/code-review/SKILL.md:120-133`, `:454-456`; `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:134-135`; `workflows/pr-prep.md:256-259`

---

## Claim 16: Important Reminders — "k=1 per `--loop-pass` inside the review-fix loop (paired with the 2-consecutive-clean rule); k=3 for standalone single-pass reviews and the loop's final confirming pass (decision log 63)"

**Location:** `skills/code-review/SKILL.md:1278-1284`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1; does not establish anything beyond the replication bullet.
**Legibility-target:** for-orchestrator-synthesis

Matches Stage 1 `:444-452` verbatim in substance.

**Evidence:** `skills/code-review/SKILL.md:1278-1284`, `:443-456`

---

## Claim 17: Test comment — "Decision log 63 narrows that k=1 to --loop-pass passes (asserted below)." and "Decision log 63 (Q-087 [2]): every run without --loop-pass takes k=3 -- the standalone review and also the loop's final confirming pass, since loop passes see only the delta."

**Location:** `test/skills/code-review-factcheck-replication.bats:144`, `:151-153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the comments describe the greps that follow; does not establish a direct grep of "Every `--loop-pass` … runs k=1" — the narrowing is asserted through its complement (the k=3-for-every-run-without-the-flag greps at `:154-157`) plus the `k=1 \(loop pass, decision 031\)` vocabulary grep (`:147`).
**Legibility-target:** for-orchestrator-synthesis

```
  stage1_flat | grep -qiE 'k=3 protocol below applies to every run without .--loop-pass.' \
    || fail "k=3 is not scoped to every run without --loop-pass (decision log 63)"
  stage1_flat | grep -qiE 'standalone single-pass reviews and a loop.s final confirming pass' \
    || fail "k=3 does not name both standalone reviews and the loop's final confirming pass"
```

(`test/skills/code-review-factcheck-replication.bats:154-157`; excerpt ends :157, the test continues to :161 — read.)

**Evidence:** `test/skills/code-review-factcheck-replication.bats:141-161`, `:29-36`

---

## Claim 18: The "replication is loop-aware…" test passes on HEAD's SKILL.md and fails on main's

**Location:** `test/skills/code-review-factcheck-replication.bats:141-161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the greps matching the flattened Stage 1 text (`stage1_flat` = sed from `### Stage 1: Code Fact-Check` to `### Fact-Check Gate`, newlines to spaces, squeezed) and the red on main; does not establish negative pinning (see Claim 10).
**Legibility-target:** for-orchestrator-synthesis

Run 1: `timeout 300 scripts/run-tests.sh test/skills/code-review-factcheck-replication.bats`, cwd `/workspace/.claude/wt-q087`, exit 0, 2026-09-28T22:06:26Z — `1..17`, all ok including `ok 13 replication is loop-aware: …`. Run 2 (mirror with `git show main:skills/code-review/SKILL.md` and HEAD's test): `timeout 120 bats -f 'loop-aware' test/skills/code-review-factcheck-replication.bats`, cwd `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r1`, exit 1, ~2026-09-28T22:07Z — `not ok 1 …` at the `:155` fail "k=3 is not scoped to every run without --loop-pass (decision log 63)". The `.` wildcards match the backticks and apostrophe in the flattened text.

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q087-final-fc-r1-tests.log`, `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r1/main-mirror.log`, `test/skills/code-review-factcheck-replication.bats:29-36`, `:141-161`

---

## Claim 19: Commit 27d483b body — "Loop passes review only the delta since the last rubric stamp, so untouched code is drawn only on a loop's first and final passes. The final pass now uses the k=3 protocol; --loop-pass stays k=1. Decision log 63 amends 031 C2. The replication suite pins the rule."

**Location:** `27d483b` (commit message)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each sentence against HEAD's text and 27d483b's stat (log.md, SKILL.md, the bats file); does not establish the commit's intermediate wording, which later fixes revised.
**Legibility-target:** for-orchestrator-synthesis

Supported by Claims 3, 6, 13-15; `git show --stat 27d483b` lists `docs/decisions/log.md`, `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`.

**Evidence:** `git log -1 27d483b`; `docs/decisions/log.md:85`; `skills/code-review/SKILL.md:443-456`

---

## Claim 20a: Commit 21d4eb8 per-finding items (A1, A2, A4, C1-C3; "Row 60 was edited in place, following the row-43 precedent of marking superseded rows"; A3 deferred, C4 declined "each with an override-log row")

**Location:** `21d4eb8` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each item against the files at HEAD; does not establish the wording at 21d4eb8 itself for items later touched by 182d143.
**Legibility-target:** for-orchestrator-synthesis

A1: row 63 now cites "the state doc §1.1 k-reduction falsifier behind log row 27" (Claim 5). A2: row 60 points to row 63 (Claim 2). A4: no rubric-based recognition remains (Claim 11). C1: Dependencies says "runs k=3" (Claim 12). C2: 031 note exists (Claim 1). C3: u4 row struck (Claim 11). Row 43 is marked in place: `| 43 | 2026-09-09 | **SUPERSEDED BY #44 — recorded as a refuted attempt, not a decision.**` (`docs/decisions/log.md:66`). A3/C4 rows exist at `docs/reviews/override-log.md:82-83`.

**Evidence:** `git log -1 21d4eb8`; `docs/decisions/log.md:66`, `:83`, `:85`; `docs/reviews/override-log.md:82-83`, `:131`

---

## Claim 20b: Commit 21d4eb8 — "Tests: the 11 suites that read these files, 292/292 ok."

**Location:** `21d4eb8` (commit message)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count against the iteration-1 log; does not establish which log the author ran (the log's mtime 14:41:49 precedes the commit's 14:42:07).
**Legibility-target:** for-author

Eleven suites were selected, but one was NOT RUN (`skills/code-fact-check-format.bats [code-fact-check]`, `q087-tests-iter1.log:3-4`); ten ran, 292 ok, 0 not ok. Already recorded as B4 (Won't-Fix, `docs/reviews/override-log.md:80`) and corrected in 182d143's body.

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-16`; `docs/reviews/override-log.md:80`

---

## Claim 21a: Commit 182d143 B1 — "log row 60's in-place amendment now uses the log's bold `**Amended 2026-09-28 (Q-087 [2]):**` marker (rows 43, 48, 53)"

**Location:** `182d143` (commit message)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the precedent rows' marker forms; does not establish that the log documents one marker convention.
**Legibility-target:** for-author

Only row 53 uses the `**Amended <date> (…):**` form (`**Amended 2026-09-27 (Q-070 [1], Q-077):**`). Row 43 uses `**SUPERSEDED BY #44 — recorded as a refuted attempt, not a decision.**` (`docs/decisions/log.md:66`) and row 48 `**Superseded in part by row 49**`. All three are bold in-place markers, so the precedent holds in kind; the parenthetical reads as if all three used the Amended form. The past-tense "(then at 031's k=1)" half of B1 is true (`docs/decisions/log.md:83`).

**Evidence:** `docs/decisions/log.md:66`, rows 48 and 53 (`rg -n '^\| (48|53) \|' docs/decisions/log.md`), `:83`

---

## Claim 21b: Commit 182d143 B2-B4, C5 — "the override-log A3 row cites the Q-087 Interim line at questions.md:235, not :232"; "the replication test comment no longer credits the any-run-without---loop-pass scope to decision 031; it names log 63"; "11 were selected but 10 ran … Same 10 suites here: 292/292 ok"; "C5 deferred with an override-log row"

**Location:** `182d143` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each item against HEAD and the iteration-2 log; does not establish that the iteration-2 log was produced from exactly 182d143's tree (its mtime 14:59:40 precedes the commit at 14:59:49).
**Legibility-target:** for-orchestrator-synthesis

B2: `docs/working/questions.md:235` is the Interim line (Claim 9). B3: test comments at `:144` and `:151-153` name log 63 (Claim 17). B4: `q087-tests-iter2.log` lists the same ten suites and `1..292`, 292 ok, 0 not ok. C5: row at `docs/reviews/override-log.md:81`.

**Evidence:** `git log -1 182d143`; `docs/working/questions.md:235`; `test/skills/code-review-factcheck-replication.bats:144-153`; `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter2.log:3-16`; `docs/reviews/override-log.md:81`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`docs/reviews/override-log.md:82`): "fact-check claim 8" resolves only to the iteration-1 report (09d62ad); HEAD's file is iteration 2, where Claim 8 is about row 60 — add "iter1".
- **Claim 10** (`docs/reviews/override-log.md:83`): same for "fact-check claim 15 note" — add "iter1".
- **Claim 20b** (commit `21d4eb8`): "11 suites" — 10 ran; already Won't-Fix as B4 and corrected in 182d143.
- **Claim 21a** (commit `182d143`): "(rows 43, 48, 53)" — only row 53 uses the `**Amended …:**` form; 43 and 48 use bold Superseded markers. Commit message; no fix needed beyond noting it.

### Unverifiable
(none)

## Escalations
- **Merge conflict with current `main`** (orchestrator): `git merge-tree --write-tree --name-only main HEAD` (cwd `/workspace/.claude/wt-q087`, exit 1, 2026-09-28T22:08:26Z, main at 6a370cb) reports `CONFLICT (content)` in `docs/decisions/log.md` and `docs/reviews/override-log.md`. `main` added log row 62 (`| 62 | 2026-09-28 | **Every review unit has a hard size cap …`) after the branch point, at the same insertion point as this branch's row 63. pr-prep 4.3 requires merging the target into the item branch before the final gate. Output: `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r1/merge-tree.log`. Raised by r1.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes — all seven brief items verified; no Incorrect or Stale; four Mostly accurate (two override-row iteration citations, two commit-message precisions).
- Out of scope: `docs/reviews/q087-*` outputs (read only to resolve override-row citations); Step 6/Step 7 omissions of k (pre-existing on main, named in Claim 14's Scope).
- Escalate: merge conflict with main in `docs/decisions/log.md` (row 62 vs 63) and `docs/reviews/override-log.md` — resolve before the final gate.
- Decisions I made: Split 21d4eb8 and 182d143 message claims where parts diverged in verdict; treated "drawn only on first and final passes" as a default-path claim (Verified), with pr-prep's full-re-review fallback named as residue.
