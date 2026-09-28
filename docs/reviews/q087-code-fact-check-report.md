Commit: 182d143

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q087 (branch `review/q087`)
**Scope:** full branch `main...182d143` — final confirming pass (no `--loop-pass`); `docs/reviews/q087-*` outputs excluded
**Checked:** 2026-09-28
**Commit:** 182d143
**Replication:** k=3
**Total claims checked:** 27
**Summary:** 19 verified, 7 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Merged by the orchestrator from `q087-code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` (all `Commit: 182d143`), most-severe-wins, annotations by union. Prefixed equivalent of the canonical `docs/reviews/code-fact-check-report.md`.

## Claim 1: 031 "Amended in part (noted 2026-09-28)" note: C2's k=1 now applies only to `--loop-pass`; the final pass runs k=3

**Location:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the note against 031's C2 row and its N≥3 argument; does not establish anything beyond the note.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

All three replicates match the note to C2 (`031:88`) and the N≥3 argument below it (`031:118-121`) and to log row 63.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:28-31`, `:88`, `:118-121`

---

## Claim 2: Row 60's `**Amended 2026-09-28 (Q-087 [2]):**` clause and "(then at 031's k=1)"

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the clause's content and marker form; does not establish row-convention policy.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Past tense and the bold marker match row 53's form (`log.md:76`).

**Evidence:** `docs/decisions/log.md:76`, `:83`, `:85`

---

## Claim 3: Row 63 decision: `--loop-pass` stays k=1; the flag alone sets k; amends 031 C2 (which priced both clean passes at k=1)

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the decision cell against SKILL.md Stage 1 and 031; does not establish token cost.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Agrees with `skills/code-review/SKILL.md:443-456` and `031:84`, `:130-131`.

**Evidence:** `docs/decisions/log.md:85`, `skills/code-review/SKILL.md:443-456`

---

## Claim 4: Row 63: "accepting ~+300k tokens per loop"

**Location:** `docs/decisions/log.md:85`
**Type:** Quantitative
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Q-087's option [2] and 031's per-pass k=1 saving; does not establish a measured cost.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (Medium) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "a restated estimate, not a measurement"

Q-087 option [2] states `~+300k tokens per loop`; 031 gives k=1 saving ~300k per pass (`031:46`, `:130`).

**Evidence:** `docs/working/questions.md:232`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:46`, `:130`

---

## Claim 5: Row 63: delta loop passes, so untouched code is drawn only on the loop's first and final passes

**Location:** `docs/decisions/log.md:85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default loop path; does not establish draws on Step 1's full-scope fallbacks.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Row 63 repeats the same phrase" as the Mostly-accurate SKILL.md wording (see claims 14, 17)

Same wording as claims 14/17; see there.

**Evidence:** `docs/decisions/log.md:85`

---

## Claim 6: Row 63 revisit trigger: ≥90% over ≥20 claims, the state doc §1.1 k-reduction falsifier behind log row 27

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution; does not judge the trigger's merit.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

`docs/thoughts/code-review-evaluation-state.md:78-79` and row 27 (`log.md:50`) carry it.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:78-79`, `docs/decisions/log.md:50`

---

## Claim 7: Row 63: "Pinned in `test/skills/code-review-factcheck-replication.bats`"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's presence and its failure on main's SKILL.md (executed); does not establish absence-of-old-wording checks (override C4).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

All replicates ran the suite (17/17 ok) and a mirror with main's SKILL.md (fails at `:155`).

**Evidence:** `test/skills/code-review-factcheck-replication.bats:141-161`; logs `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r{1,2,3}/main-mirror.log`

---

## Claim 8: Override-log B4 row (10 of 11 suites ran)

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's citations.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Matches `q087-tests-iter1.log:3-5`.

**Evidence:** `docs/reviews/override-log.md:80`

---

## Claim 9: Override-log C5 row (SKILL.md:177-179; reference omits strikethrough)

**Location:** `docs/reviews/override-log.md:81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's citations.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Citations resolve.

**Evidence:** `docs/reviews/override-log.md:81`, `skills/code-review/SKILL.md:177-179`, `:1260`

---

## Claim 10: Override-log A3 row: citations `questions.md:222`, `:235`, 48bca90, "fact-check claim 8"

**Location:** `docs/reviews/override-log.md:82`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's citations; does not establish which report a future reader opens.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: "'fact-check claim 8' only matches the iteration-1 report (09d62ad); at HEAD, Claim 8 is about row 60. Needs 'iter1'"

Line and commit citations are right; the claim-number reference is iteration-ambiguous because `q087-code-fact-check-report.md` is overwritten per pass.

**Evidence:** `docs/reviews/override-log.md:82`

---

## Claim 11: Override-log C4 row: test `:141-161`, "fact-check claim 15 note"

**Location:** `docs/reviews/override-log.md:83`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's citations.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: same iteration ambiguity as claim 10

Range is right; claim reference needs "iter1".

**Evidence:** `docs/reviews/override-log.md:83`

---

## Claim 12: Struck u4 override row, "moot since decision log 63"

**Location:** `docs/reviews/override-log.md:131`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers strike form and the moot reason.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Follows `skills/code-review/SKILL.md:1260`.

**Evidence:** `docs/reviews/override-log.md:131`, `skills/code-review/SKILL.md:1260`

---

## Claim 13: Dependencies bullet: k=1 on `--loop-pass`, final pass k=3

**Location:** `skills/code-review/SKILL.md:20`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Agrees with `:443-456`.

**Evidence:** `skills/code-review/SKILL.md:20`

---

## Claim 14: Step 1 "Cost to recall: code no fix touches is redrawn only on each loop's first and final passes"

**Location:** `skills/code-review/SKILL.md:131`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the default loop path; does not establish draws on Step 1's full-scope fallbacks (stamp missing / not an ancestor / equals HEAD) or pr-prep 3d's broad-fix fallback.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "does not establish the sanctioned deviations — pr-prep 3d's full re-review fallback and `--full` — which add draws" · r3: "holds on the default loop path; fallback only adds draws"

Winning (r2): the same section sends a `--loop-pass` to full scope when the stamp `is missing, is not an ancestor … or equals HEAD` (`:117-118`), and pr-prep 3d falls back to a full re-review (`workflows/pr-prep.md:248`). "Only" is the default, not an invariant; precise: "by default, only on the first and final passes".

**Evidence:** `skills/code-review/SKILL.md:106-133`, `workflows/pr-prep.md:244-248`

---

## Claim 15: Step 1: the final confirming pass reviews the full branch at k=3

**Location:** `skills/code-review/SKILL.md:132-133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Consistent with `:126-127`, `:451-453`.

**Evidence:** `skills/code-review/SKILL.md:126-133`

---

## Claim 16: Stage 1: k=1 only on `--loop-pass`; k=3 for every run without it; the flag alone sets k

**Location:** `skills/code-review/SKILL.md:443-454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Step 1, mechanic 6, merged header, Reminders, pr-prep 3d, review-fix-loop, Gate 1h.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Step 6's `--loop-pass` entry and Step 7's agent count don't mention k (pre-existing)"

No normative text anywhere still says the final pass runs k=1 (all three swept the repo).

**Evidence:** `skills/code-review/SKILL.md:443-454`, `:735-744`, `scripts/self-improvement.sh:1605-1617`

---

## Claim 17: Stage 1: "Loop passes review only the delta since the last stamp, so code no fix touched is drawn only on the loop's first and final passes"

**Location:** `skills/code-review/SKILL.md:454-455`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the default loop path; does not establish the fallback draws.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r3: "true on the default path; fallbacks only add draws" · r3: "untouched code now gets 4 fact-check draws but only 2 critic-panel draws"

Same as claim 14.

**Evidence:** `skills/code-review/SKILL.md:117-118`, `:454-455`

---

## Claim 18: Stage 1: "decision 031 priced both clean passes at k=1"

**Location:** `skills/code-review/SKILL.md:456`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the 031 citation.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

`031:84`, `:130-131`.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:84`, `:130-131`

---

## Claim 19: Important Reminders replication bullet

**Location:** `skills/code-review/SKILL.md:1278-1284`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Stage 1.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Matches.

**Evidence:** `skills/code-review/SKILL.md:1278-1284`

---

## Claim 20: Step 7 "Total agent count (3 fact-check replicates + N critics …)"

**Location:** `skills/code-review/SKILL.md:259-260`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count against Stage 1's loop-aware rule; pre-existing text unchanged by this branch.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** r1: noted as pre-existing in claim 14 · r3: "Pre-existing, not introduced here" (Goal-Alignment)

A `--loop-pass` runs 1 fact-check agent, not 3.

**Evidence:** `skills/code-review/SKILL.md:259-260`, `:443-445`

---

## Claim 21: Replication test comments match assertions and the flattened Stage 1 text

**Location:** `test/skills/code-review-factcheck-replication.bats:142-157`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers comments vs greps.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "the k=1 narrowing is asserted through the k=3 greps, not directly"

Matches.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:142-157`

---

## Claim 22: The loop-aware test passes on HEAD and fails on main's SKILL.md

**Location:** `test/skills/code-review-factcheck-replication.bats:141-161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Executed in three mirrors.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Fails at `:155` on main.

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q087-final-fc-r{1,2,3}-tests.log`

---

## Claim 23: Commit 27d483b body: "untouched code is drawn only on a loop's first and final passes"

**Location:** commit `27d483b`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the default path; same caveat as claim 14.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r3: default path

Immutable-ish (unpushed but already reviewed); wording carries the same "only" imprecision.

**Evidence:** `git log -1 27d483b`

---

## Claim 24: Commit 21d4eb8 A1–C3 bullets

**Location:** commit `21d4eb8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullets vs the tree.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Match the tree.

**Evidence:** `git log -1 21d4eb8`

---

## Claim 25: Commit 21d4eb8: "Tests: the 11 suites that read these files, 292/292 ok"

**Location:** commit `21d4eb8`
**Type:** Quantitative
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the suite count; 292/292 is right.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** none beyond: settled as override-log B4 (Won't-Fix)

10 suites ran; `code-fact-check-format.bats` NOT RUN (`q087-tests-iter1.log:3-5`).

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-19`

---

## Claim 26: Commit 182d143 B1: row 60 "uses the log's bold `**Amended …**` marker (rows 43, 48, 53)"

**Location:** commit `182d143`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the precedent citation.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

Only row 53 (`log.md:76`) uses `**Amended …:**`; rows 43 (`:66`) and 48 (`:71`) use bold Superseded markers.

**Evidence:** `docs/decisions/log.md:66`, `:71`, `:76`

---

## Claim 27: Commit 182d143 B2–B4, C5 items

**Location:** commit `182d143`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullets vs the tree.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Match.

**Evidence:** `git log -1 182d143`

---

## Submitted Claims

## Claim 28: "In the Stage 1 replication paragraph, the only condition that selects k=1 is the `--loop-pass` flag. No rubric-file check remains in that paragraph."

**Submitted by:** security-reviewer
**Location:** `skills/code-review/SKILL.md:443-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the whole Stage 1 "Replication is loop-aware" paragraph (`:443-456`, read to its end; the next unit starts at `:458` "For each of the three replicate agents:"); does not establish that every other k-mentioning passage in SKILL.md is consistent with it — the Step 7 plan text at `:259-260` still says "3 fact-check replicates" unconditionally (pre-existing on `main`, not a rubric check, but it does not mention k=1 on loop passes).

The paragraph's only k=1 selector is the flag:

```
skills/code-review/SKILL.md:444-445
031 overrules the earlier blanket k=3 mandate).** Every `--loop-pass` of a review-fix loop
(which requires **2 consecutive clean passes** before merge) runs **k=1**. Run a
```

and the k=3 side is defined as the complement of the flag, with an explicit statement that no rubric check is used:

```
skills/code-review/SKILL.md:451-454
1−(1−p)³ for N≥3 draws). The **k=3 protocol below applies to every run without `--loop-pass`**:
standalone single-pass reviews and a loop's final confirming pass, which runs without the flag per
[Step 1](#step-1-determine-scope). The flag alone sets k, so no rubric check is needed to tell the
two apart. Loop passes review only the delta since the last stamp, so code no fix touched is drawn
```
(excerpt ends :454; paragraph continues to :456 — read; :455-456 are rationale citing decision log 63, no condition.)

The diff removes the former rubric test from this paragraph: `main` had "is recognized by the branch's canonical rubric existing without a `Loop closed at` line" and "(no `--loop-pass` and no open loop rubric for the branch)"; both lines are `-` lines in `git diff main...HEAD -- skills/code-review/SKILL.md` and no rubric/`Loop closed at` reference remains in `:443-456` (paraphrased — no quote available because the claim is about absence; `grep -n "Loop closed at"` on the file hits only `:121`, `:128`, `:739`, `:744`, all outside the paragraph).

On the critic's stated gap: mechanic 6 does read the rubric (`:735-744`), but only to decide the once-per-loop short-circuit; its k statement is `:739` "The run still implies `--no-gate` and k=1", which applies to a run that is already a `--loop-pass` run (the short-circuit is enabled only by the flag: `:247-248` "`--loop-pass` — mark this run as a **non-final pass** … Enables the [first-red short-circuit]"). So rubric state gates the short-circuit, not k. Step 7 (`:259-260`) reads "Total agent count (3 fact-check replicates + N critics, …" — no rubric check, but unconditional; this line is identical on `main` (`git show main:… | grep` hits `:260`), so it is a pre-existing count imprecision, not a residue of the removed check.

**Evidence:** `skills/code-review/SKILL.md:443-456`, `skills/code-review/SKILL.md:247-250`, `skills/code-review/SKILL.md:259-260`, `skills/code-review/SKILL.md:735-744`

---

## Claim 29: "A rubric gets `Loop closed at` only from a run without `--loop-pass`, so every closed loop's final pass is one that the new rule assigns k=3."

**Submitted by:** security-reviewer
**Location:** `skills/code-review/SKILL.md:126-128`, `skills/code-review/SKILL.md:450-453`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every written instruction in the repo (excluding `docs/reviews/` artifacts and `archive/`) that adds a `Loop closed at` line — SKILL.md Step 1, `references/rubric.md`, decision log row 60 — and the k rule that maps flagless runs to k=3; does not establish that an orchestrator actually omits `--loop-pass` on the final pass at run time (a procedural-compliance question, covered only by the instructions at SKILL.md `:249-250` and pr-prep 3d), nor what a clean *standalone* run writes (irrelevant to k, since it too is flagless and k=3).

The sole writer in SKILL.md is the final confirming pass, defined as the flagless run:

```
skills/code-review/SKILL.md:126-128
summary (Step 7). Only the final confirming pass (the one run to declare the branch clean) runs
without `--loop-pass`, and it keeps the full-branch default; when it is clean, it adds
`Loop closed at <reviewed HEAD sha>` under the rubric's `Commit:` line. Every earlier pass in the loop,
```
(excerpt ends :128; paragraph continues to :136 — read; remainder covers delta-range passes and the recall rationale, no other writer.)

The rubric reference agrees and adds no other writer:

```
skills/code-review/references/rubric.md:24-26
`-final` suffixes), or neither rule can find the file. When the final confirming pass is
clean it adds `Loop closed at <sha>` under the `Commit:` line; a later loop pass that finds it
starts a new loop with full-branch scope and removes both marker lines (same dated file) or leaves them out (new file); this is the one case where a prior loop's rubric is updated in place. Both rules
```

Loop passes only remove it (`:121-125` "remove both marker lines … or leave them out"), and mechanic 6's copy-forward copies the short-circuit marker "unless that file is closed (`Loop closed at`)" (`:743-744`), so no loop pass carries a `Loop closed at` line forward. Decision log row 60 (`docs/decisions/log.md:83`) says the same: "only the final confirming pass, run without `--loop-pass`, is full-branch, and when clean it writes `Loop closed at <sha>`". The flag definition forbids the flag on that pass: `:249-250` "Never pass it on the terminal pass". The k rule then maps it to k=3: `:451` "The **k=3 protocol below applies to every run without `--loop-pass`**". A repo-wide `grep -rn "Loop closed at"` (excluding `docs/reviews/`, `archive/`, `.git/`) returned only the five locations above (paraphrased — no quote available because the claim covers absence of any other writer; the grep result is a location list).

**Evidence:** `skills/code-review/SKILL.md:119-128`, `skills/code-review/SKILL.md:247-250`, `skills/code-review/SKILL.md:450-453`, `skills/code-review/SKILL.md:739-744`, `skills/code-review/references/rubric.md:21-28`, `docs/decisions/log.md:83`

---

## Claim 30: "k keys on one explicit input (the flag), not on inferred rubric state. This removes the ambiguity the u4 override row recorded"

**Submitted by:** api-consistency-reviewer
**Location:** `skills/code-review/SKILL.md:453-454`; `docs/reviews/override-log.md:131`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Stage 1 k rule, the two other places that restate it (`:20`, `:1279-1281`), and the u4 row's scenario (flagless second standalone review of a branch with an open canonical rubric); does not establish uniform k-wording elsewhere — Step 7's "3 fact-check replicates" (`:259-260`, pre-existing) is unconditional, and Stage 2.5's submitted-claims pass is a fixed k=1 keyed on the stage (`:1032-1035`), neither of which reads rubric state.

The rule is keyed on the flag alone:

```
skills/code-review/SKILL.md:453-454
[Step 1](#step-1-determine-scope). The flag alone sets k, so no rubric check is needed to tell the
two apart. Loop passes review only the delta since the last stamp, so code no fix touched is drawn
```
(excerpt ends :454; paragraph continues to :456 — read.)

Restatements match: `:20` "(k=1 on `--loop-pass` passes, decision 031; the loop's final confirming pass runs k=3, decision log 63)" and `:1279-1281` "k=1 per `--loop-pass` inside the review-fix loop …; k=3 for standalone single-pass reviews and the loop's final confirming pass (decision log 63)".

The u4 row's ambiguity was the rubric-state test:

```
docs/reviews/override-log.md:131
| 2026-09-28 | `feat/u4-code-review-skill` | ~~A second standalone review of a branch finds a canonical rubric with no `Loop closed at` line and is classed as a loop final pass, so it runs k=1 instead of k=3 (`skills/code-review/SKILL.md` Stage 1 replication) — fact-check iter3 claim 10~~ (moot since decision log 63: every run without `--loop-pass` is k=3) | …
```
(excerpt ends inside the row; remainder is the verdict/reason cells "🟢 Consider | Defer | … Revisit if Q-087 raises the final pass to k=3." — read.)

Under the new rule that second standalone review is flagless, hence k=3 by `:451`, whether or not a rubric exists; the misclassification cannot change k any more. The only remaining rubric-state reader near k is mechanic 6 (`:735-744`), which gates the short-circuit on an already-`--loop-pass` run, not k (see Claim 28).

**Evidence:** `skills/code-review/SKILL.md:20`, `skills/code-review/SKILL.md:443-456`, `skills/code-review/SKILL.md:1032-1035`, `skills/code-review/SKILL.md:1279-1281`, `docs/reviews/override-log.md:131`

---

## Claims Requiring Attention

None. (Scope notes on Claims 28 and 30 name one pre-existing adjacent imprecision: Step 7's plan text, `skills/code-review/SKILL.md:259-260`, says "3 fact-check replicates" unconditionally although loop passes run k=1. Unchanged from `main`; not a rubric check.)

---

---

## Claims Requiring Attention

### Incorrect
- **Claim 25** (commit 21d4eb8): "11 suites"; 10 ran. Settled: override-log B4 Won't-Fix.

### Mostly Accurate
- **Claims 14, 17, 23** (`skills/code-review/SKILL.md:131`, `:454-455`, commit 27d483b; row 63 repeats it, claim 5): "drawn only on the first and final passes" holds by default; Step 1's full-scope fallbacks and pr-prep 3d's broad-fix fallback add draws. Say "by default".
- **Claim 20** (`skills/code-review/SKILL.md:259-260`): Step 7 always counts 3 fact-check replicates; a `--loop-pass` runs 1. Pre-existing.
- **Claims 10, 11** (`docs/reviews/override-log.md:82-83`): "fact-check claim 8" / "claim 15 note" need "iter1"; the report is overwritten per pass.
- **Claim 26** (commit 182d143): precedent "rows 43, 48, 53"; only row 53 uses the `**Amended …:**` form.

## Escalations

- `orchestrator` (r1): the branch conflicts with current `main` (6a370cb) in `docs/decisions/log.md` (main's row 62 at the same spot as row 63) and `docs/reviews/override-log.md`; pr-prep 4.3 requires merging main into the branch before the final gate. `git merge-tree` output: `/home/node/.claude/jobs/9f431b13/tmp/q087-final-r1/merge-tree.log`.
- `orchestrator` (r2, r3): `answers-2026-09-28` archives Q-087 as "Done in 65e51b7", a duplicate of this branch's 27d483b.

## Verdict stability

- Total clusters: 27 (one single-replicate: claim 20)
- Clusters where all reporting replicates agreed: 20
- Disagreed: claim 10 (MA/V/V), 11 (MA/V/V), 14 (V/MA/V), 17 (V/MA/V), 23 (V/MA/V), 25 (MA/MA/Inc)
- Agreement rate: 20/27 ≈ 74% (all disagreements are Verified vs Mostly accurate, or Mostly accurate vs Incorrect on an already-settled claim)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes (merge of three replicates)
- Out of scope: none
- Escalate: see ## Escalations
