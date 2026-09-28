Commit: 8caeb11

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `u4-code-review-skill`, branch `feat/u4-code-review-skill`)
**Scope:** full branch `main...8caeb11` (77a4ca5, 317ec3e, 8caeb11): `docs/decisions/log.md` row 60, `skills/code-review/SKILL.md`, `skills/code-review/references/rubric.md`, `test/skills/code-review-format-contract.bats`, `test/skills/code-review/rubric-current-format.md`, plus the 8caeb11 commit message; review reports excluded. The iteration-3 delta (`317ec3e..8caeb11`) was checked first. For the consistency sweep I grepped SKILL.md for `loop-pass`, `Loop closed`, `short-circuit`, `Commit:`, `k=1`, `k=3`, `canonical`, `enforcement`, `confirming`, `--full`, `Q-087` and `timeout`, then read each enclosing section whole: Dependencies (:12-24), Step 1 (:95-140), the `--loop-pass` flag (:247-252), the reviewer preamble (:285-305), Stage 1 through the replication paragraph (:415-458), the whole First-red short-circuit section (:676-761), the Stage 2.5 skip (:1015-1018), and Important Reminders (:1278-1306). I also read rubric.md :1-30.
**Checked:** 2026-09-28
**Replication:** k=1 (final confirming pass, decision 031)
**Total claims checked:** 17
**Summary:** 11 verified, 5 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`). No claim matches a logged pattern.

## Iteration-2 carry-forward: the 7 Mostly-accurate claims

| Iter-2 claim | Status | Evidence |
|---|---|---|
| 2 (B3 narrowing reason misdescribed B3) | **Resolved** | SKILL.md:728-732 and log.md:83 now read "B3's full panel in iteration 1 costs a whole critic block on top of the fact-check pass, and security is the critic the Q-076 evidence names". That is iteration 2's precise version word for word, and it matches proposal:42 (Claim 2). |
| 5 (a second loop inherits the old stamp and marker) | **Resolved** (minor residue) | The `Loop closed at <sha>` line (SKILL.md:121-128, :745; rubric.md:24-26; log.md:83) makes a later loop start at full scope with no inherited marker. Residue: mechanic 6 still equates "first pass of a loop" with "no canonical rubric", and a same-day new loop's in-place update does not say to remove the lines (Claims 6 and 7). |
| 6 (final pass k=3, contradicting 031 C2) | **Resolved** | SKILL.md:445-449 now says every loop pass, including the final confirming pass, is k=1. That matches 031 C2 (`031:84`, `:129-130`), row 60, and Important Reminders :1280. The k=3 question is filed as Q-087 (Claims 9 and 11). |
| 7 (mtime tiebreak can never fire) | **Resolved** | SKILL.md:112-114: "the file with the latest date in its name among those whose name is exactly …" (Claim 4). |
| 12 (lead rule unqualified) | **Resolved** | SKILL.md:682-684: "(subject to the bound below: at most once per loop, and never past the security critic on an enforcement file)" (Claim 13). |
| 15 (rubric.md called a new-date file "a genuinely different review") | **Resolved** | rubric.md:16-17: "A new date mid-loop is a continuation, not a new review: the new file copies the `Commit:` stamp and any marker line from the previous one." A separate, pre-existing same-day residue is in Claim 16. |
| 18 (317ec3e "Fixes the 9", really 8 + a partial fix) | **Resolved** (by 8caeb11; 317ec3e's message cannot be changed) | The Claim-14 remainder is fixed by the lead-rule edit above, and 8caeb11 says so ("18: with 12 fixed, iteration-1 claim 14 is now fully fixed"). |

Tally: **7 resolved, 0 open.**

---

## Claim 1: "its regex mirrors `cc-isolated.sh`'s `enforcement_files()`, which owns the list, plus `install.sh`"

**Location:** `docs/decisions/log.md:83`; `skills/code-review/SKILL.md:746-749`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership statement and the `install.sh` addition. It does not establish that the regex matches `enforcement_files()` entry for entry: the function's globs past line 140 were not compared against the regex's `egress/`.

```bash
# hooks/live-verify-gate.sh:70-73
# The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo
# paths. Keep in step with that function. Plus install.sh, which is not hashed but
# runs on the host and chooses the diff the human reviews (decision 035).
enforcement='^devcontainer-config/(Dockerfile|...|cc-push\.sh|install\.sh$|egress/)'
```

`enforcement_files() {` is defined at `devcontainer-config/cc-isolated.sh:126`. "`install.sh`" means `devcontainer-config/install.sh`, since the repo root has no `install.sh` (paraphrased: no quote available because this is an `ls` absence result).

**Evidence:** `hooks/live-verify-gate.sh:70-74`, `devcontainer-config/cc-isolated.sh:126-140`

---

## Claim 2: "This narrows proposal B3, which asked for the critic panel in iteration 1, alongside fact-check, for any unit touching an enforcement file … because B3's full panel in iteration 1 costs a whole critic block on top of the fact-check pass"

**Location:** `skills/code-review/SKILL.md:728-732`; `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the description of B3 and the stated cost. It does not judge whether security-only is the better design.

`docs/working/proposal-2026-09-27-smaller-review-units.md:42`: "**B3 · Run the critic panel in iteration 1 alongside fact-check** (with `--loop-pass`) for any unit that touches an enforcement file." Row 60 uses the same wording.

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:42`, `skills/code-review/SKILL.md:721-734`, `docs/decisions/log.md:83`

---

## Claim 3: "032's own falsifier, `docs/decisions/032-review-loop-token-reduction-levers.md:90-91`, named this failure" / "It trips 032's falsifier for #4 (032:90-91)"

**Location:** `skills/code-review/SKILL.md:733-734`; `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the cited lines are 032's #4 falsifier. It does not establish that the Q-076 Highs would have changed the fix, which is the falsifier's exact condition.

```
docs/decisions/032-review-loop-token-reduction-levers.md:90-91
  - Falsifier for #4: a red-gated pass whose skipped critics would have found an *independent*
    red that changes the fix → collect reds panel-wide before short-circuiting.
```

**Evidence:** `docs/decisions/032-review-loop-token-reduction-levers.md:84-91`

---

## Claim 4: "The loop's rubric is the file with the latest date in its name among those whose name is exactly `code-review-rubric-<YYYY-MM-DD>-<branch-slug>.md` … Ad-hoc suffixes (`-iter2`, `-final`) never count"

**Location:** `skills/code-review/SKILL.md:112-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the rubric naming in rubric.md and with mechanic 6's cross-reference. It does not establish what happens to existing non-canonical rubrics: the repo has some, e.g. `code-review-rubric-2026-09-21-answers-2026-09-20-iter2.md`. For those, mechanic 6 correctly says "do not short-circuit".

The canonical name is defined at rubric.md:10-12 ("where `<branch-slug>` is the branch name with `/` replaced by `-`"). Mechanic 6 identifies the rubric "as in [Step 1]" (`SKILL.md:736-737`). With one name per date and slug, "latest date" is a total order.

**Evidence:** `skills/code-review/SKILL.md:111-117`, `:736-737`, `skills/code-review/references/rubric.md:10-12`

---

## Claim 5: Stamp rules: "If that file exists, its stamp is an ancestor of HEAD … and differs from HEAD, the scope is `<sha>..HEAD` … If there is no such file, or its stamp is missing, is not an ancestor (including a git error on the stamp), or equals HEAD, use full-branch scope"; "`--full` (the default above, stated explicitly …)"

**Location:** `skills/code-review/SKILL.md:108-121`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers internal consistency with rubric.md:20-22 ("each pass rewrites it to the HEAD that pass reviewed. The next loop pass computes its default range from it") and with the partial-scope label list (:140, :469, :883). It does not re-execute the `--is-ancestor` probes from iteration 1.

The loop-pass default range is added to all three partial-scope enumerations: `SKILL.md:140`, `:469`, `:883` ("`--range`, the loop-pass default range, `--staged`, …"). The ancestor behaviour was executed in iteration 1 (`u4-code-fact-check-report.md:164`).

**Evidence:** `skills/code-review/SKILL.md:108-140`, `:469`, `:883`, `skills/code-review/references/rubric.md:20-22`

---

## Claim 6: "If that file carries a `Loop closed at <sha>` line under its `Commit:` line, the previous loop has ended and this pass starts a new one: use full-branch scope, treat the file as having no short-circuit marker, and copy neither marker line into what this pass writes."

**Location:** `skills/code-review/SKILL.md:121-124`; `skills/code-review/references/rubric.md:24-26`; `docs/decisions/log.md:83`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium. This is a reading of how the in-place-update rule and the new-loop rule compose; no multi-loop run was executed.
**Verification mode:** static
**Scope:** Covers the new-day case (fully specified) and the same-day case. It does not establish how often a second loop starts on the same date.

For a new loop on a **new** date the rule is complete: the pass writes a new file and "copy[ies] neither marker line". On the **same** date, rubric.md says to "keep updating the same file" (`rubric.md:14`), and a closed loop's file can hold both lines, because the final pass adds `Loop closed at` and nothing removes the earlier short-circuit marker (`SKILL.md:757-759`: "keep it there for the rest of the loop … must not remove it"). "Copy neither … into what this pass writes" implies that the in-place update drops both lines, but it never says *remove*. If the `Loop closed at` line survives, every later pass of the new loop sees it again. Each such pass would be treated as a first pass: full scope, marker ignored (so the short-circuit is unbounded), and the final pass would be classed as standalone (k=3, per `SKILL.md:455-456`). Read literally, the text gives the correct result. Precise version: "…and remove both marker lines (same-day file) or omit them (new file)". **Non-blocking.**

**Evidence:** `skills/code-review/SKILL.md:121-128`, `:755-759`, `skills/code-review/references/rubric.md:14-17`, `:24-26`

---

## Claim 7: Mechanic 6: "If no canonical rubric exists yet (the first pass of a loop), there is no marker, so the short-circuit is allowed."

**Location:** `skills/code-review/SKILL.md:740-745`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers mechanic 6's own text against Step 1. It does not evaluate the policy.

The parenthetical covers only a branch's first loop. On a later loop the canonical rubric exists and is closed. Mechanic 6 imports rubric *identification* from Step 1 (":736-737 identified as in Step 1's loop-pass default range"), but its marker test is literal: "If it carries the marker line `Loop-pass short-circuit: used at <sha>`, this loop has already skipped once". A closed file can still carry loop 1's marker (Claim 6). The only `Loop closed` exception in mechanic 6 is the new-day sentence at :743-745. Step 1's "treat the file as having no short-circuit marker" (:123) resolves this, but only for a reader who follows the cross-reference past identification. The error runs in the safe direction: loop 2's first pass would refuse a short-circuit it is allowed. Precise version: "(the first pass of a loop, or the file is closed — see Step 1)". **Non-blocking.**

**Evidence:** `skills/code-review/SKILL.md:121-124`, `:736-745`

---

## Claim 8: "Cost to recall: code no fix touches is redrawn only on each loop's first and final passes … the mitigation is that the final confirming pass reviews the full branch (at 031's k=1)"

**Location:** `skills/code-review/SKILL.md:131-133`; `docs/decisions/log.md:83`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers loops that close with `Loop closed at`. It does not establish the claim for a loop that ends at the cap without closing: the next loop inherits a delta first pass, so untouched code is redrawn less, not more.

The first pass is full-branch, either because there is no rubric or because the rubric is closed (`:120-124`). The final pass "keeps the full-branch default" (`:126-127`). Every other pass "takes the delta range" (`:128-129`).

**Evidence:** `skills/code-review/SKILL.md:111-134`

---

## Claim 9: "Every pass of a review-fix loop … runs **k=1**: each `--loop-pass`, and also the final confirming pass, which runs without the flag … and is recognized by the branch's canonical rubric existing without a `Loop closed at` line. Decision 031 prices both clean passes at k=1"; "k=3 protocol below applies to standalone single-pass reviews only (no `--loop-pass` and no open loop rubric for the branch)"

**Location:** `skills/code-review/SKILL.md:444-457`; `docs/decisions/log.md:83`; `skills/code-review/SKILL.md:1279-1281`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with decision 031 C2, row 60, and Important Reminders. It does not establish the classification of a *standalone* run on a branch whose only canonical rubric is open (see Claim 10). It also leaves one wording mismatch: the header label SKILL gives every loop pass is `k=1 (loop pass, decision 031)` (:452), including the final pass, which runs without `--loop-pass`.

```
docs/decisions/031-review-loop-tier-and-factcheck-policy.md:84
| **C2** | **on** | **1** | **2-clean** | **fix-drift** | k=1 savings fund a second attestation draw; **chosen** |
docs/decisions/031-review-loop-tier-and-factcheck-policy.md:129-130
clean pass at k=1 costs ~0.7M; on a ~3-pass loop the savings (~0.9M) roughly fund the extra
pass — a **wash on cost with strictly more resampling**.
```

Important Reminders agree: "k=1 per pass inside the review-fix loop (paired with the 2-consecutive-clean rule); k=3 for standalone single-pass reviews" (`SKILL.md:1280-1281`). Row 60: "the final confirming pass reviews the full branch (at 031's k=1, unchanged)". I ran `test/skills/code-review-factcheck-replication.bats` (17/17 ok, exit 0), which pins the "k=3 protocol below applies to standalone" phrase. The log is at `/tmp/claude-1000/u4iter3/bats-replication.log`.

**Evidence:** `skills/code-review/SKILL.md:444-457`, `:1278-1284`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:84`, `:112-130`, `docs/decisions/log.md:83`

---

## Claim 10: "recognized by the branch's canonical rubric existing without a `Loop closed at` line" (as the way to tell a final confirming pass from a standalone review)

**Location:** `skills/code-review/SKILL.md:447-448`, `:455-456`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium. This is an edge-case composition, not executed.
**Verification mode:** static
**Scope:** Covers the loop and standalone classification. It does not assess how common a repeated standalone review is.

The test works for the loop path: pass 1 is a `--loop-pass` that writes the canonical rubric, and the final pass finds it open, so k=1. It also works for a first standalone review, which finds no rubric and runs at k=3. Standalone reviews also run without `--loop-pass` and write the canonical rubric, but only the "final confirming pass (the one run to declare the branch clean)" is told to add `Loop closed at` (`:126-128`). So a standalone review leaves an open canonical rubric, and any later standalone review of the same branch is classed as a loop's final pass and runs at k=1, not k=3. The risk is recall on repeated standalone reviews. It is not a merge-safety issue. Precise version: have any clean run without `--loop-pass` write `Loop closed at`, or say that a second standalone review of a branch counts as a loop. **Non-blocking.**

**Evidence:** `skills/code-review/SKILL.md:126-128`, `:444-457`

---

## Claim 11: "Raising that pass to k=3 is open as Q-087 in `docs/working/questions.md`"

**Location:** `skills/code-review/SKILL.md:133-134`, `:449`; `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the reference resolves. It does not judge Q-087's content beyond its topic.

Q-087 is on `main` (`d08de11 docs(questions): file Q-087 (k on the final confirming pass)`), where `### Q-087 · final-confirming-pass-replicates` reads "Should the final confirming pass of a review-fix loop run the fact-check at k=3 instead of decision 031's k=1 …". The branch's merge-base is `6fd72c8`, which is before d08de11, and `grep -c Q-087 docs/working/questions.md` in the worktree returns `0`. The reference therefore dangles on the branch and resolves once main is merged in, which parallel-worktrees step 4.3 already requires before the gate. **Non-blocking.**

**Evidence:** `main:docs/working/questions.md` (Q-087 entry), `git merge-base HEAD main` = `6fd72c8`

---

## Claim 12: Dependencies: "`code-fact-check.md` … Runs as **k=3 parallel replicates** merged most-severe-wins"

**Location:** `skills/code-review/SKILL.md:20`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers this one line against the replication paragraph. The line was not edited on this branch (it is identical on `main`), so it is not a regression.

The line is unqualified, but SKILL's own Stage 1 now makes every loop pass k=1 (`:445-446`). The line points to "Stage 1's **Why three**" for the rationale, and that paragraph routes to the loop-aware rule, so a careful reader still ends up correct. Precise version: "k=3 for standalone reviews, k=1 per loop pass (Stage 1)". **Non-blocking** (pre-existing).

**Evidence:** `skills/code-review/SKILL.md:17-22`, `:444-457`; `git show main:skills/code-review/SKILL.md` lines 18-22

---

## Claim 13: "once a behavioral 🔴 is confirmed on a `--loop-pass` run, stop the pass … — do not launch the remaining review work** (subject to the bound below: at most once per loop, and never past the security critic on an enforcement file)"; mechanic 2 "(all of it, except the security critic when mechanic 7 applies)"; mechanic 4 "except the security critic's under mechanic 7"

**Location:** `skills/code-review/SKILL.md:682-684`, `:698-699`, `:712-713`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency of the lead rule and mechanics 2, 4, 6 and 7, and the rubric-writing paragraph. It does not establish that mechanic 5 ("terminal pass never short-circuits") holds under pr-prep beyond pr-prep:250-253.

All the absolute statements now carry the exceptions. Mechanic 6 requires Stage 2 "in full despite the red, with no critic-stage trigger (mechanic 3) and with amber collected" (:738-739). Mechanic 7: "run the security critic even on a pass that short-circuits … Only the other critics are skipped" (:750-752). The writing paragraph: "write the rubric with only the confirmed red(s) (plus the security critic's findings under mechanic 7)" (:756-757). pr-prep agrees: "Pass `--loop-pass` … on any pass you expect to be followed by a fix — i.e., every pass except the one you run to *confirm* the branch is clean" (`workflows/pr-prep.md:250-252`).

**Evidence:** `skills/code-review/SKILL.md:676-761`, `workflows/pr-prep.md:250-254`

---

## Claim 14: "`--loop-pass` … Enables the first-red short-circuit and the loop-pass default range, and implies `--no-gate`"

**Location:** `skills/code-review/SKILL.md:247-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Step 1 (:111) and mechanic 6 (:740). It does not cover Stage 2.5's loop-pass skip, which is pre-existing.

Step 1 begins with "On a `--loop-pass` run with none of the flags above" (:111). Mechanic 6: "The run still implies `--no-gate` and k=1" (:740).

**Evidence:** `skills/code-review/SKILL.md:111`, `:247-252`, `:736-740`

---

## Claim 15: "The preamble MUST also carry the **probe-cleanup rule** … In Q-076, leftover reviewer probes tripped `install.sh`'s no-agent guard and failed `install-host` tests in full runs."

**Location:** `skills/code-review/SKILL.md:299-302`; `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-076 citation and placement in the shared preamble. It does not establish that agents comply.

`docs/working/proposal-2026-09-27-smaller-review-units.md:13`: "Each failed only in full runs and passed alone. Leftover probe processes from review agents (a sleep, a `cc-push` Ctrl-C probe blocked on a FIFO) tripped install.sh's no-agent guard." The rule sits in list item 1, "The goal preamble" (:287).

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:13`, `:72-74`, `skills/code-review/SKILL.md:285-305`

---

## Claim 16: rubric.md "This preserves in-loop status tracking while stopping each loop from destroying the prior loop's findings" / Important Reminders "A new date or branch means a new file — never overwrite a prior review's rubric"

**Location:** `skills/code-review/references/rubric.md:17-18`; `skills/code-review/SKILL.md:1302-1306`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim against the same-day case this branch makes explicit. The weakness predates the branch: a same-day second review always shared the file.

The branch now names a "new loop" that can start on the same date after `Loop closed at` (`SKILL.md:121-124`). Under "keep updating the same file" and one name per date+slug, that new loop updates the closed loop's rubric in place. So a same-day loop does overwrite the prior loop's record, against "never overwrite a prior review's rubric". The different-date case is accurate. Precise version: "a new date, a new branch, or a closed loop means a new file", which would need a naming rule, or say that a same-day new loop overwrites. **Non-blocking** (pre-existing; bookkeeping, not merge safety).

**Evidence:** `skills/code-review/references/rubric.md:14-18`, `skills/code-review/SKILL.md:121-124`, `:1302-1306`

---

## Claim 17: test "fixture's first line is the Commit: stamp the loop-pass default range reads"; 8caeb11 "Fixes the 7 'Mostly accurate' claims"

**Location:** `test/skills/code-review-format-contract.bats:37-40`; `test/skills/code-review/rubric-current-format.md:1`; commit message of 8caeb11
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture assertion, the two requested suites, and the seven per-claim statements in the commit message (checked in the carry-forward table). It does not verify the message's "130/130" total, since only the requested suites plus the replication suite were run.

Fixture line 1 is `Commit: 1a2b3c4` (`test/skills/code-review/rubric-current-format.md:1`), and the assertion is `head -1 | grep -qE '^Commit: [0-9a-f]{7,40}$'` (`code-review-format-contract.bats:38`).

Command: `LC_ALL=C.UTF-8 timeout 300 bats test/skills/code-review-format-contract.bats test/code-review-gate.bats`. It ran in `/tmp/claude-1000/-workspace/fe8d5f41-d34b-4387-9352-6d6b13c2ada9/scratchpad/wt/u4-code-review-skill`, exited 0, and finished at 2026-09-28T19:15:32Z with `1..44`, 44 `ok`, 0 `not ok`.

**Evidence:** `test/skills/code-review-format-contract.bats:37-40`, `test/skills/code-review/rubric-current-format.md:1`, `/tmp/claude-1000/u4iter3/bats.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 12** (`SKILL.md:20`): Dependencies still says fact-check "Runs as k=3 parallel replicates", with no loop qualifier. This is pre-existing and non-blocking.

### Mostly Accurate
- **Claim 6** (`SKILL.md:121-124`, `rubric.md:24-26`): on a same-day new loop, the in-place update is not told to *remove* `Loop closed at` and the old short-circuit marker. Non-blocking.
- **Claim 7** (`SKILL.md:740-745`): mechanic 6 equates "first pass of a loop" with "no canonical rubric", and its marker test does not itself exempt a closed file. The safe direction. Non-blocking.
- **Claim 10** (`SKILL.md:447-448`, `:455-456`): a standalone review never writes `Loop closed at`, so a second standalone review of the branch is classed as a final loop pass and runs at k=1. Non-blocking.
- **Claim 11** (`SKILL.md:133-134`, `:449`): Q-087 is on main but not on the branch, and resolves after merging main. Non-blocking.
- **Claim 16** (`rubric.md:17-18`, `SKILL.md:1302-1306`): "never overwrite a prior review's rubric" fails for a same-day new loop. Pre-existing and non-blocking.

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Answered:** (a) All 7 of iteration 2's Mostly-accurate claims are resolved, with evidence (7/0). (b) Every checkable claim in the full-branch diff has a verdict, delta first: row 60, Step 1 with `--full`, the Loop-closed marker, the replication paragraph, the lead rule, mechanics 2/4/6/7, the probe rule, the rubric.md preamble, the fixture test, and the 8caeb11 message. (c) Consistency sweep: rubric identification, default scope, the short-circuit marker and its once-per-loop bound, the security exception, and the k=1/k=3 split agree across SKILL.md, rubric.md, row 60, decision 031 C2 and pr-prep:250-253. The remaining gaps are edge cases (Claims 6, 7, 10 and 16), and none is merge-blocking. (d) The requested bats suites ran 44/44 with exit 0, and the replication suite ran 17/17.
- **Out of scope:** I did not compare the hook regex against `enforcement_files()` entry by entry, and I did not re-run iteration 1's `--is-ancestor` probes. I edited nothing except this report. The bats logs are outside the worktree, at `/tmp/claude-1000/u4iter3/`. I started no background processes.
- **Escalate:** nothing merge-blocking. Merge main into the branch before the gate so the Q-087 reference resolves (Claim 11). The same-day new-loop behaviour (Claims 6, 7 and 16) could be fixed with one sentence, "remove both marker lines when starting a new loop in the same file", which can be a follow-up.
