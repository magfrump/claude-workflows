Commit: 317ec3e

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `u4-code-review-skill`, branch `feat/u4-code-review-skill`)
**Scope:** iteration-2 delta `77a4ca5..317ec3e` (docs/decisions/log.md row 60, skills/code-review/SKILL.md, skills/code-review/references/rubric.md, test/skills/code-review-format-contract.bats, test/skills/code-review/rubric-current-format.md) plus the commit message of 317ec3e; the committed iteration-1 report is excluded. Regression spot-checks read the whole enclosing sections of SKILL.md (Step 1, the `--loop-pass` flag, the Stage 1 replication paragraph, the whole "First-red short-circuit" section, the Key-principles rubric bullet) and rubric.md's Deliverable 2 preamble.
**Checked:** 2026-09-28
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 19
**Summary:** 12 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim matches a logged pattern.

## Iteration-1 carry-forward: the 9 Mostly-accurate claims

| Iter-1 claim | Status | Evidence |
|---|---|---|
| 7 (one rubric per loop; multi-day loops fall into "multiple matches") | **Resolved** | SKILL now takes "the **newest** file (by the date in its name, then mtime)" and says "Several dated files for one slug are normal" (`SKILL.md:112-115`); `grep -n 'more than one\|unambiguously'` over SKILL.md and rubric.md returns nothing, so the multi-match branch is gone. Residue: see Claims 7 and 15 (vacuous mtime tiebreak; rubric.md:15-17 still calls a new-date file "a genuinely different review"). |
| 8 (stamp not in fixture, no test) | **Resolved** | Fixture line 1 is `Commit: 1a2b3c4` (`test/skills/code-review/rubric-current-format.md:1`); new assertion at `test/skills/code-review-format-contract.bats:37-40` passes and fails when the line is removed (Claim 17). |
| 10 (confirming pass vs `:434`'s "confirmation pass" wording) | **Resolved** | `SKILL.md:123-125` and `:440-442` now both say only the final confirming pass runs without `--loop-pass`. Consequence for replication: see Claim 6. |
| 11 (delta default weakens 031's N≥3 argument, unrecorded) | **Resolved** (acknowledged) | `SKILL.md:127-129` and `log.md:83` both state the weakening. The stated mitigation ("final pass at k=3") is itself only partly supported: see Claims 5 and 6. |
| 14 (pre-amendment absolutes left unqualified) | **Still open (partial)** | Mechanics 2 and 4 now carry the exception (`SKILL.md:686-687`, `:703-704`). The section's lead rule at `SKILL.md:674-675` ("do not launch the remaining review work") was quoted in iteration 1 and is still unqualified (Claim 12). |
| 17 (hook said to own the enforcement list) | **Resolved** | `SKILL.md:736-738` and `log.md:83` now name `cc-isolated.sh`'s `enforcement_files()` as owner; matches the hook comment `hooks/live-verify-gate.sh:70-72` (Claim 1). |
| 20 (ad-hoc names "fall back to full scope") | **Resolved** (commit message immutable; SKILL now explicit) | `SKILL.md:115-117`: "Ad-hoc suffixes (`-iter2`, `-final`) never count: rubrics must use the canonical name" — the marker-miss risk is now covered by a naming requirement plus rubric.md:24-25. |
| 21 ("cannot be identified" vs first pass) | **Resolved** | `SKILL.md:730-733`: "If no canonical rubric exists yet (the first pass of a loop), there is no marker, so the short-circuit is allowed. If rubrics for this branch exist but none has the canonical name, or HEAD is detached, … do not short-circuit." (Loop-identity residue: Claim 5.) |
| 22 (B3 narrowed without saying so) | **Resolved** | `SKILL.md:719-722` and `log.md:83` both say B3 was narrowed; citation `032:90-91` verified (Claim 3). The stated cost reason slightly misdescribes B3 (Claim 2). |

Tally: **8 resolved, 1 still open (Claim 14, partial).**

---

## Claim 1: "its regex mirrors `cc-isolated.sh`'s `enforcement_files()`, which owns the list, plus `install.sh`"

**Location:** `docs/decisions/log.md:83`; also `skills/code-review/SKILL.md:735-738`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership statement and the install.sh addition; does not establish that the hook's regex is currently in sync entry-for-entry with `enforcement_files()` (e.g. the function's `projects/`/`claude-home/` globs vs the regex's `egress/`), which the hook itself only promises to "keep in step".

The hook says so itself:

```bash
# hooks/live-verify-gate.sh:70-72
# The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo
# paths. Keep in step with that function. Plus install.sh, which is not hashed but
# runs on the host and chooses the diff the human reviews (decision 035).
```

and `enforcement_files()` is defined at `devcontainer-config/cc-isolated.sh:126` (`enforcement_files() {`).

**Evidence:** `hooks/live-verify-gate.sh:70-73`, `devcontainer-config/cc-isolated.sh:126-140`, `skills/code-review/SKILL.md:735-741`

---

## Claim 2: "This narrows proposal B3 … on enforcement diffs only security is forced, because running the full panel on every early pass costs a whole critic block per round"

**Location:** `docs/decisions/log.md:83`; `skills/code-review/SKILL.md:719-722`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium — the imprecision is in a rationale's framing of the proposal, not in mechanics.
**Verification mode:** static
**Scope:** Covers the description of B3 and the narrowing; does not judge whether security-only is the better design.

The narrowing is described correctly: B3 reads "**B3 · Run the critic panel in iteration 1 alongside fact-check** (with `--loop-pass`) for any unit that touches an enforcement file." (`docs/working/proposal-2026-09-27-smaller-review-units.md:42`). The stated reason, however, argues against a cost B3 did not propose: B3 asks for the panel in **iteration 1** only, not on "every early pass". With the once-per-loop bound, iteration 2 already runs the full panel on any red, so B3's marginal cost over the adopted design is one critic block (iteration 1, enforcement units only), not one per round. Precise version: "because B3's full panel in iteration 1 costs a whole critic block on top of the fact-check pass, and security is the critic the Q-076 evidence names".

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:42`, `skills/code-review/SKILL.md:712-734`, `docs/decisions/log.md:83`

---

## Claim 3: "It trips 032's falsifier for #4 (032:90-91)" / "032's own falsifier, `docs/decisions/032-review-loop-token-reduction-levers.md:90-91`, named this failure"

**Location:** `docs/decisions/log.md:83`; `skills/code-review/SKILL.md:723-725`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the cited lines are 032's #4 falsifier and describe the Q-076 failure class; does not establish that the Q-076 security Highs would have "changed the fix" (the falsifier's exact condition), nor note that the falsifier's prescribed remedy ("collect reds panel-wide before short-circuiting") differs from the bound adopted.

```
docs/decisions/032-review-loop-token-reduction-levers.md:90-91
  - Falsifier for #4: a red-gated pass whose skipped critics would have found an *independent*
    red that changes the fix → collect reds panel-wide before short-circuiting.
```

**Evidence:** `docs/decisions/032-review-loop-token-reduction-levers.md:84-91`

---

## Claim 4: "the stamp is the `Commit:` line of the loop's rubric (the newest canonically named dated file for the branch; the marker is copied forward to a new day's file)"

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement of row 60 with SKILL Step 1 and mechanic 6 and rubric.md; does not establish the soundness of the rules (see Claims 5, 7, 15).

Matches `SKILL.md:112-117` ("the **newest** file … whose name is exactly `code-review-rubric-<YYYY-MM-DD>-<branch-slug>.md`"), `SKILL.md:733-734` ("the pass that creates it copies any marker line from the previous dated file") and `references/rubric.md:22-23`.

**Evidence:** `skills/code-review/SKILL.md:111-126`, `skills/code-review/SKILL.md:726-734`, `skills/code-review/references/rubric.md:20-26`

---

## Claim 5: "code no fix touches is redrawn only on the first and final passes" / "If no canonical rubric exists yet (the first pass of a loop)"

**Location:** `skills/code-review/SKILL.md:127-128`, `:730-731`; `docs/decisions/log.md:83`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium — a reading of how the rules compose; no second-loop case was executed.
**Verification mode:** static
**Scope:** Covers the equation "no canonical rubric for the slug = first pass of a loop = full-branch first pass"; does not establish how often a branch sees a second loop.

True for a branch's first loop. The rules identify "the loop's rubric" only by slug and date (`SKILL.md:112-114`), not by loop, so on a **second** loop on the same branch (a later day, after more commits) the newest canonical file is the previous loop's rubric. Its stamp is normally still an ancestor of HEAD, so Step 1 gives `<old-stamp>..HEAD` rather than full scope ("If that file exists, its stamp is an ancestor of HEAD … the scope is `<sha>..HEAD`", `SKILL.md:117-119`), and the new loop's first pass is a delta, not a full draw. Likewise any marker left by the previous loop is copied forward (`SKILL.md:733-734`), so the new loop may never short-circuit. Both errors are in the safe direction for the bound; the first reduces the redraw count the recall sentence relies on. Precise version: "…redrawn only on the branch's first pass and on each final pass".

**Evidence:** `skills/code-review/SKILL.md:111-129`, `skills/code-review/SKILL.md:726-734`, `skills/code-review/references/rubric.md:14-17`

---

## Claim 6: "the full-branch final pass at k=3 is the mitigation" (with "On a `--loop-pass` (any pass inside the review-fix loop … except the final confirming pass, which runs without the flag …), run **k=1**")

**Location:** `skills/code-review/SKILL.md:128-129`, `:439-449`; `docs/decisions/log.md:83`
**Type:** Configuration / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what k the SKILL now gives the final confirming pass and whether decision 031 sanctions it; does not measure the recall or cost effect.

Within SKILL the final pass is k=3 only by elimination: k=1 applies "On a `--loop-pass` … except the final confirming pass" (`SKILL.md:440-442`), and the k=3 paragraph describes its own domain as "**standalone single-pass reviews** — no loop, no second draw" (`SKILL.md:448-449`), which the final pass of a loop is not. So the SKILL never states the final pass's k directly. More importantly, decision 031's chosen configuration C2 is "T-on + k1 + 2-clean" (`031:84`) and its cost argument prices **both** clean passes at k=1: "the second clean pass at k=1 costs ~0.7M" (`031:129-130`). Before this delta, SKILL matched that ("an intermediate or confirmation pass … run **k=1**", old `:434`). The delta's edit to `:440-442` therefore moves the final confirming pass from 031's k=1 to k=3 (031 prices k=3 at ~300k extra per pass, `031:128`), and neither row 60 nor 031 records the change. The only source for a k=3 final pass is proposal B2 ("The final confirming pass stays k=3, full diff", `proposal-2026-09-27-smaller-review-units.md:40`), which row 60 does not cite (it cites B1, B3, C6). The mitigation holds if k=3 is intended; the precise version must say it departs from 031 C2 (or cite B2) and fix `:448-449`'s "standalone … no loop" description.

**Evidence:** `skills/code-review/SKILL.md:439-449`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:84`, `:115-130`, `docs/working/proposal-2026-09-27-smaller-review-units.md:40`, `docs/decisions/log.md:83`

---

## Claim 7: "the **newest** file (by the date in its name, then mtime)"

**Location:** `skills/code-review/SKILL.md:112-113`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering rule; does not affect any outcome.

The same sentence requires the name to be "exactly `code-review-rubric-<YYYY-MM-DD>-<branch-slug>.md`" (`SKILL.md:113`). For a fixed slug, two files with the same date have the same name, so the mtime tiebreak can never fire. Harmless, but it implies same-date duplicates are possible. Precise version: "the file with the latest date in its name".

**Evidence:** `skills/code-review/SKILL.md:112-117`

---

## Claim 8: "Several dated files for one slug are normal, since a new file starts on each new date."

**Location:** `skills/code-review/SKILL.md:114-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the naming rule and real history; does not establish that multi-date files belong to one loop (see Claim 15).

rubric.md: "A *new* file is created only when the date or the branch changes" (`references/rubric.md:15-16`). Real history: counting canonical names per slug gives `2 feat-crb-direction1-harness.md` and `2 exp-cross-model-openrouter-sweep.md`, all others 1.

**Evidence:** `skills/code-review/references/rubric.md:14-17`. Command: `ls docs/reviews | grep -E '^code-review-rubric-' | sed -E 's/^code-review-rubric-[0-9-]{10}-//' | sort | uniq -c | sort -rn`, cwd worktree root, exit 0, 2026-09-28T18:38Z; output reproduced verbatim in this claim (reproducible from the committed `docs/reviews/`).

---

## Claim 9: "Ad-hoc suffixes (`-iter2`, `-final`) never count"

**Location:** `skills/code-review/SKILL.md:115-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the exact-name rule excludes suffixed files; does not establish that a suffixed name can be told apart from a branch whose slug itself ends in such a token (e.g. `skill-fixtures-q062-q063` exists in history) — resolution depends on the agent knowing the slug exactly, which it does from the branch name.

The exact-name clause (`SKILL.md:113`) excludes any extra suffix; rubric.md reinforces it: "Keep the canonical name (no `-iter2` or `-final` suffixes), or neither rule can find the file" (`references/rubric.md:23-24`).

**Evidence:** `skills/code-review/SKILL.md:112-117`, `skills/code-review/references/rubric.md:20-26`

---

## Claim 10: "is not an ancestor (including a git error on the stamp) … use full-branch scope"

**Location:** `skills/code-review/SKILL.md:119-121`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the classification rule (git error → full scope, the conservative direction); does not re-execute git's error behavior, which iteration 1 Claim 9 executed (`--is-ancestor` exits non-zero on an ambiguous short SHA).

The text closes iteration 1's edge case in the safe direction: any non-zero outcome falls to full-branch scope.

**Evidence:** `skills/code-review/SKILL.md:117-121`; iteration-1 report Claim 9 (`docs/reviews/u4-code-fact-check-report.md:154-168`)

---

## Claim 11: "Only the final confirming pass (the one run to declare the branch clean) runs without `--loop-pass` … every earlier pass in the loop, including the first of 2-clean's two clean passes, takes the delta range."

**Location:** `skills/code-review/SKILL.md:123-125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the `--loop-pass` flag text, mechanic 5, the replication paragraph and pr-prep; the replication consequence is Claim 6.

Consistent with the flag ("set by `pr-prep`'s loop for every pass except the terminal clean check", `SKILL.md:242-243`), mechanic 5 ("`pr-prep` runs the final, otherwise-clean pass **without** `--loop-pass`", `:706-707`), the replication paragraph (`:440-442`) and pr-prep ("run that final confirmation pass **without** it", `workflows/pr-prep.md:252`).

**Evidence:** `skills/code-review/SKILL.md:242-247`, `:440-442`, `:706-710`, `workflows/pr-prep.md:250-254`

---

## Claim 12: "The rule: **once a behavioral 🔴 is confirmed on a `--loop-pass` run, stop the pass and hand back to the loop for the fix — do not launch the remaining review work.**"

**Location:** `skills/code-review/SKILL.md:674-675`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section's internal consistency after the delta; the line predates the delta but was quoted in iteration-1 Claim 14.

The lead rule is still absolute, while mechanic 6 now requires Stage 2 "in full despite the red" once the marker exists (`:728-729`) and mechanic 7 requires the security critic "even on a pass that short-circuits" (`:739`). Mechanics 2 and 4 were qualified; this sentence was not. An agent reading the bold rule as the definition will skip work the bound requires. Precise version: append "(subject to the bound below: at most once per loop, and never past security on an enforcement file)".

**Evidence:** `skills/code-review/SKILL.md:668-749`

---

## Claim 13: mechanic 2 "(all of it, except the security critic when mechanic 7 applies)" and mechanic 4 "except the security critic's under mechanic 7"

**Location:** `skills/code-review/SKILL.md:685-687`, `:703-704`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement among mechanics 2, 4, 7 and the closing paragraph; does not cover the lead rule (Claim 12).

Mechanic 7: "run the security critic even on a pass that short-circuits … Its findings enter the rubric at their mapped tier, amber included. Only the other critics are skipped." (`:739-741`); closing paragraph: "write the rubric with only the confirmed red(s) (plus the security critic's findings under mechanic 7)" (`:745-746`). All four places agree.

**Evidence:** `skills/code-review/SKILL.md:684-749`

---

## Claim 14: mechanic 6 — no rubric → short-circuit allowed; non-canonical-only or detached → do not short-circuit; new day's file copies the marker forward

**Location:** `skills/code-review/SKILL.md:730-734`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Step 1 and rubric.md (Step 1 gives full-branch scope where mechanic 6 refuses to short-circuit on non-canonical-only history — different, compatible outcomes; both require a flag on detached HEAD); loop identity across loops is Claim 5.

Step 1 detached-HEAD rule "require an explicit `--range` or `--full`" (`:121-122`) matches mechanic 6's detached case; the copy-forward rule matches `references/rubric.md:22-23` ("a pass that starts a new dated file copies any marker line from the previous one") and the closing paragraph's "keep it there for the rest of the loop" (`:747`).

**Evidence:** `skills/code-review/SKILL.md:111-126`, `:726-749`, `skills/code-review/references/rubric.md:20-26`

---

## Claim 15: "A *new* file is created only when the date or the branch changes, i.e. when it is a genuinely different review."

**Location:** `skills/code-review/references/rubric.md:15-17`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency of this pre-existing sentence with the delta's new model; the sentence was not edited in the delta.

The delta now treats a new day's file as a continuation of the **same** loop: its range comes from the previous file's stamp (`SKILL.md:112-119`) and it inherits the marker (`SKILL.md:733-734`, `references/rubric.md:22-23`). The "i.e. when it is a genuinely different review" gloss says the opposite, and the Key-principles bullet repeats the "new date … means a new file" framing (`SKILL.md:1292-1295`). The date part is right; the gloss is now wrong for a loop that crosses midnight. Precise version: drop "i.e. when it is a genuinely different review", or say a new date starts a new file even mid-loop.

**Evidence:** `skills/code-review/references/rubric.md:14-26`, `skills/code-review/SKILL.md:112-119`, `:733-734`, `:1291-1295`

---

## Claim 16: "a pass that starts a new dated file copies any marker line from the previous one. Keep the canonical name (no `-iter2` or `-final` suffixes), or neither rule can find the file."

**Location:** `skills/code-review/references/rubric.md:22-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with SKILL Step 1 and mechanic 6; does not re-verify ownership wording (unchanged, iteration-1 Claim 18).

Matches `SKILL.md:115-117` and `:733-734`.

**Evidence:** `skills/code-review/references/rubric.md:20-26`, `skills/code-review/SKILL.md:111-117`, `:726-734`

---

## Claim 17: test "fixture's first line is the Commit: stamp the loop-pass default range reads"

**Location:** `test/skills/code-review-format-contract.bats:37-40`; `test/skills/code-review/rubric-current-format.md:1`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the assertion passes on the fixture and fails without the stamp, and that the other 20 tests still pass with the new first line; does not establish that real rubrics carry the stamp (the fixture is a spec, not a real rubric).

```bash
# test/skills/code-review-format-contract.bats:37-40
@test "fixture's first line is the Commit: stamp the loop-pass default range reads" {
  echo "$FIXTURE_CONTENT" | head -1 | grep -qE '^Commit: [0-9a-f]{7,40}$' \
    || fail "fixture line 1 is not 'Commit: <sha>' (references/rubric.md)"
}
```

Full suite: 21 `ok`, 0 `not ok`, exit 0 (the new test is one of the 21). Mutation: the same grep over the fixture with its first two lines stripped exited 1.

**Evidence:** Command 1: `LC_ALL=C.UTF-8 timeout 300 bats test/skills/code-review-format-contract.bats`, cwd worktree root, exit 0, 2026-09-28T18:38:07Z, output `/tmp/claude-1000/u4iter2/bats.log`. Command 2: `C=$(tr -d '\r' < test/skills/code-review/rubric-current-format.md | tail -n +3); echo "$C" | head -1 | grep -qE '^Commit: [0-9a-f]{7,40}$'`, same cwd and time, exit 1 (no output by design). `test/skills/code-review/rubric-current-format.md:1-3`

---

## Claim 18: "Fixes the 9 'Mostly accurate' claims in docs/reviews/u4-code-fact-check-report.md"

**Location:** commit message of 317ec3e (first paragraph)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the resolution table above; does not assess the new issues in Claims 2, 5, 6, 7, 15.

Eight of nine are resolved. Claim 14 is partly fixed: the message's "14: mechanics 2 and 4 carry mechanic 7's security exception" is accurate, but iteration-1 Claim 14 also quoted the lead rule "do not launch the remaining review work", which is unchanged (Claim 12).

**Evidence:** `skills/code-review/SKILL.md:674-675`, `:684-704`; `docs/reviews/u4-code-fact-check-report.md:234-248`

---

## Claim 19: "The 'multiple matches -> require --range/--full' branch is gone", "10: … the Stage 1 replication paragraph now says the same", "A git error on the stamp is classed as 'not an ancestor'"

**Location:** commit message of 317ec3e
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these three statements; "11: … the full-branch k=3 final pass mitigates" is Claim 6.

`grep -n 'more than one\|unambiguously'` over SKILL.md and rubric.md returns no lines (paraphrased — no quote available because the claim covers absence of text); `SKILL.md:440-442` carries the confirming-pass exception; `SKILL.md:120` reads "is not an ancestor (including a git error on the stamp)".

**Evidence:** `skills/code-review/SKILL.md:111-126`, `:439-442`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`log.md:83`, `SKILL.md:719-722`): the reason for narrowing B3 ("full panel on every early pass … per round") misdescribes B3, which asked for iteration 1 only.
- **Claim 5** (`SKILL.md:127-128`, `:730-731`, `log.md:83`): "first pass of a loop" = "no canonical rubric" holds only for a branch's first loop; a later loop inherits the old stamp (delta, not full, first pass) and the old marker.
- **Claim 6** (`SKILL.md:128-129`, `:439-449`, `log.md:83`): the k=3 final pass is implied only by elimination, contradicts 031 C2 (k=1 on both clean passes, `031:84`, `:129-130`), is unrecorded in row 60 (source is un-cited proposal B2), and `:448-449` still scopes k=3 to "standalone … no loop" reviews.
- **Claim 7** (`SKILL.md:112-113`): the mtime tiebreak can never fire; same date + slug is one filename.
- **Claim 12** (`SKILL.md:674-675`): the lead rule "do not launch the remaining review work" is still unqualified by the bound (iteration-1 Claim 14 residue).
- **Claim 15** (`references/rubric.md:15-17`): "a new date … i.e. a genuinely different review" now contradicts the delta's treatment of a new day's file as the same loop.
- **Claim 18** (commit 317ec3e): "Fixes the 9" — 8 fully, Claim 14 partially.

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Answered:** (a) All 9 iteration-1 Mostly-accurate claims are dispositioned with evidence: 8 resolved, 1 still open (14, partial). (b) Every new factual claim in the delta (row 60 additions, SKILL Step 1, replication paragraph, mechanics 2/4/6/7, bound paragraph, rubric.md, bats test, fix commit message) has a verdict. (c) Spot-checks: I grepped SKILL.md for every mention of loop-pass, short-circuit, marker, canonical, confirm, enforcement and `Commit:`, and read Step 1, the flag text, the replication paragraph, the whole First-red short-circuit section and the Key-principles rubric bullet, plus rubric.md's Deliverable 2 preamble. Rubric identification, default range, marker carry-forward and the security exception are consistent inside SKILL.md, except the lead rule (Claim 12). Confirming-pass *scope* is consistent; confirming-pass *replication* is not settled (Claim 6). The new bats assertion passes (21/21) and fails when the stamp is removed.
- **Out of scope:** I did not judge whether k=3 on the final pass or security-only on enforcement diffs is the better design. I did not check the hook regex entry-by-entry against `enforcement_files()`. Nothing was edited except this report; the bats log is at `/tmp/claude-1000/u4iter2/bats.log` (outside the worktree, per the edit-nothing instruction).
- **Escalate:** Claim 6 is a policy question, not a wording fix: either the final confirming pass is k=3 (then row 60 or 031 must record the departure from C2 and its ~300k/loop cost, and `SKILL.md:448-449` must stop calling k=3 "standalone … no loop"), or it is k=1 per 031 (then the "k=3 mitigation" in `SKILL.md:128-129` and row 60 is wrong). The user should pick. No silent guesses.
