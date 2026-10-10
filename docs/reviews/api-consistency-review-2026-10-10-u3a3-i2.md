Commit: e25a6e89

# API Consistency Review: feat/build-loop-u3a3 (U3a3, iteration 2, loop pass)

**Scope:** `git diff a7a4f784..HEAD` (fix commit e25a6e89 only; partial scope, with 18f32952 and a7a4f784 read as context). Surfaces: GATE_CODE's widened set as seen by `--merge --approved` and the self-merge floor; the four reworded approval refusals; the `--help` header's --merge paragraph and refusal list; land's trailer; the lib rename ANSWER_HEAD → ANSWER_HEADING.
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a3-i2.md (14 claims: 13 verified, 1 mostly accurate, the header's ":215 '(under --approved, the N rules' lines only)'"). Iteration-1 rubric docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a3.md: deferred and Won't-Fix rows (C1, C6, C8, C9, C10, C12, C13, A1) are not re-raised.
**Runs:** none of my own; behaviour read statically or taken from the fact-check's E1–E3 runs.

## Baseline Conventions

Unchanged from iteration 1 (docs/reviews/api-consistency-review-2026-10-10-u3a3-i1.md, Baseline Conventions). The ones this delta touches:

- **Refusal WHY.** A lower-case clause after `refuse BRIEF: `. A parenthetical names the accepted forms where there is a fixed set. Examples: "not a question ID (Q- and digits)" (scripts/lib/dev-cycle-read.sh:2101) and "no default branch found by name (origin/HEAD, main or master)" (:2102).
- **Answer words.** check_answer prints `keep|drop|done|open|unrecognized ID` or `skip ID: WHY`. A dup is turned into a skip inside check_answer (:2096). The lib's comment names the forms "[1], 1 or keep; [2], 2 or drop; [3], 3 or done" (:2010-2011). The plan numbers the merge entry's options [1] merge, [2] drop, [3] changes needed (plan:60).
- **Gate-file set.** This is one regex, GATE_CODE, used by floor (:1955) and check_line (scripts/build-loop.sh:1047). The plan states it at plan:61 (D4) and at plan:71 (D5 item 3, scripts only).
- **Lib side values.** These are UPPER_SNAKE globals named for what they hold. "heading" is the lib's word for a questions entry line (awk `heading()`, "dup (the heading appears more than once)").

## Iteration-1 findings: status in the delta

| i1 finding | Status at e25a6e89 | Evidence |
|---|---|---|
| F1 gate list vs plan | **Resolved** for D4. GATE_CODE now has `^skills/dev-cycle/`. The header list adds `skills/dev-cycle/`. T35's gate test includes `skills/dev-cycle/references/x.md`. Plan:61 and the code now agree. Plan:71 (D5 item 3) still lists only scripts. That is rubric C11 ("plan D5 note at merge"), still to do at merge time, and is not re-raised. | `scripts/lib/dev-cycle-read.sh:1923` `GATE_CODE='^scripts/(build-loop\|dev-cycle\|questions)\.sh$\|^scripts/lib/\|^skills/dev-cycle/'`; `scripts/build-loop.sh:232-233` "anything under scripts/lib/ or skills/dev-cycle/)"; `test/scripts/build-loop-merge.bats:242` |
| F3 refusal names the option read | **Resolved.** drop → "option 2", done → "option 3", and unrecognized (the only other word reaching the catch-all, since dup is already a skip) → "not read as an option ([1], 1 or keep approve)". The header's refusal list was updated to match ("WHY names which"). The tests assert all three. | `scripts/build-loop.sh:1086-1088`; `:248-249`; `test/scripts/build-loop-merge.bats:229-231` |
| F6 ANSWER_HEAD → ANSWER_HEADING | **Resolved everywhere.** `rg -n 'ANSWER_HEAD\b'` outside docs/reviews/ has no hits, in code, comments, tests or working docs. All six sites use the new name: the declaration, the shellcheck comment, the reset, the assignment, the lib header sentence, and approval's comment and read. | `scripts/lib/dev-cycle-read.sh:35, 2075, 2078-2079, 2082, 2105`; `scripts/build-loop.sh:1080, 1090` |

## Name-Pattern Audit

The delta introduces one renamed public name and no new ones.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `ANSWER_HEADING` | lib global (side value) | awk `heading()`; "dup (the heading appears more than once)"; refusal "its heading must read" | `scripts/lib/dev-cycle-read.sh:2021, 1990`; `scripts/build-loop.sh:1091` | Consistent. It uses the lib's word for the entry line and no longer collides with git's HEAD |
| refusal texts "… is option 2" / "… is option 3" / "… is not read as an option ([1], 1 or keep approve)" | verdict WHY | lib skips with an accepted-forms parenthetical; plan's numbered options | `scripts/lib/dev-cycle-read.sh:2101-2102`; `docs/working/plan-build-loop-handoff.md:60` | Consistent. They use the plan's option numbers, not the lib's internal words, and the parenthetical copies the lib comment's "[1], 1 or keep" |
| `^skills/dev-cycle/` (GATE_CODE alternative) | regex alternative | `^scripts/lib/` | `scripts/lib/dev-cycle-read.sh:1923` | Consistent. Anchored, ends in `/` so `skills/dev-cycle-x/` does not match (fact-check P1) |

## Findings

#### 1. The floor's widening changes `--check`'s self-merge output for `skills/dev-cycle/` paths, and no floor-side test pins it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1923, 1955`; missing from `test/scripts/build-loop-check.bats:1302-1303` (floor refuse list) and `:2121`
**Move:** 3 (consumer contract: test drift)
**Confidence:** High (static: truthrule returns 1 for `skills/dev-cycle/references/x.md`, since PROMPT_DIR needs `.claude/` and INSTRUCTION_FILE needs a SKILL.md basename. floor then reaches its GATE_CODE arm)
**Legibility-target:** for-author

Evidence:
```
scripts/lib/dev-cycle-read.sh:1955:  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate
test/scripts/build-loop-check.bats:1302:        scripts/build-loop.sh "$GATE" scripts/dev-cycle.sh "$GATE" scripts/questions.sh "$GATE"
test/scripts/build-loop-check.bats:1303:        scripts/lib/dev-cycle-read.sh "$GATE" scripts/lib/new.sh "$GATE" Scripts/Build-Loop.sh "$GATE"
e25a6e89 body: "it also makes the self-merge floor refuse any skills/dev-cycle/ path."
```

GATE_CODE is "one list for floor and build-loop.sh's --approved" (:1921-1922). Widening it therefore also changes a second public surface. Under self-merge, `--check` and `--merge` now print `deny BRIEF A skills/dev-cycle/<non-instr path>: the gate's own code, which lands only through a merge-gate- review entry` where they used to print a path line. The commit body says so, and plan D5's "Scripts and skills are self-mergeable within `Paths:`" (plan:23) is now narrower in practice (C11's merge-time note covers the plan side). The tests pin only the --approved side (merge bats :242). The floor's GATE rows in check bats list scripts paths only, so nothing pins the new floor refusal. A later change that splits the list into an approval-only regex, which the commit body calls an "interim choice", would silently reverse the floor behaviour. The fact-check's E2/E3 show that T10's pass list still passes. That is because no skills/dev-cycle/ path is in it, not because the new refusal is asserted.

**Recommendation:** Add `skills/dev-cycle/references/x.md "$GATE"` (and `Skills/Dev-Cycle/x.md "$GATE"` for case) to the floor refuse list at build-loop-check.bats:1302-1303. Optionally add `skills/dev-cycle-x/a.md` to `pass` so the anchoring is pinned too.

#### 2. The header's --merge paragraph gives the --approved rule set two phrasings, and the inserted caller sentence detaches the following "then"

**Severity:** Informational
**Location:** `scripts/build-loop.sh:213-215`, `:224-226`, `:233-236`
**Move:** 3 (documentation of the consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
scripts/build-loop.sh:214-215:  either policy: --check's lines for BRIEF at --expect's tip
                                (under --approved, the N rules' lines only), but an ok
scripts/build-loop.sh:225-226:  either policy under the N rules alone (no S rules, no
                                checkout rule) when the questions entry Q-NNN, ...
scripts/build-loop.sh:233-236:  skills/dev-cycle/). The heading pins only TIP's prefix:
                                --expect binds the full tip, so the caller passes the full
                                TIP it filed the entry for, never the branch's live tip;
                                then the message reads "(build-loop approved merge)" with
```

This is the fact-check's one Mostly-accurate claim (:215), and I do not re-verify it. The consumer angle is that one `--help` paragraph names the same rule set two ways. "The N rules' lines only" read literally drops the pre-loop refusals (brief not open, --expect mismatch), which still print. :225-226 gives the precise form. Separately, the A1 sentence was inserted between the heading rule and "then the message reads …". The "then" used to continue "it lands … when … heading …". It now follows a caller instruction, so a reader can take the message and trailer as conditional on the caller's discipline.

**Recommendation:** At :215, use :225's wording ("under --approved, without the S rules or the checkout refusal"). Move the "The heading pins only TIP's prefix …" sentence after the reflog clause, or start the following clause with "Approved, the message reads …".

## What Looks Good

- **Refusal vocabulary.** The new WHYs use the plan's option numbers (what the user sees in the entry), not check_answer's internal keep/drop/done. The unreadable case is now told apart from a no, which was the substance of i1 F3. The accepted-forms parenthetical follows the lib's skip style. It names "keep", the lib's alias, alongside [1] and 1, which matches the lib comment at :2010-2011.
- **Catch-all reach.** Only `unrecognized` reaches the `*)` arm now. `dup` and the file-level odd/unbalanced/quoted words become skips inside check_answer (:2096-2101), so they keep their own quoted reason and never get the "not read as an option" sentence.
- **Header refusal list.** "answered with another option or an answer not read (WHY names which)" (:248-249) matches the code arms one for one.
- **land's authority.** The trailer is now keyed on `$1 == approved` (:1177), the same value as the message's `what`, so authority travels one way (rubric A3, row 653). The documented signature `land AUTHORITY [Q-NNN]` still holds, because the only approved caller passes APPROVED.
- **Floor's gate sentence still true.** "the gate's own code, which lands only through a merge-gate- review entry" (:1980) holds for every GATE_CODE path, `skills/dev-cycle/` included: --approved requires `merge-gate-` for it (merge bats :242). The reworded floor comment (:1933-1935) correctly says the gate word is no test of gate code and points callers to GATE_CODE. That matters here, because `skills/dev-cycle/SKILL.md`, the one file there today, gets floor's `instr` word (truthrule runs first), not `gate`.
- **Lib header contract.** The new ANSWER_HEADING sentence (:35-38) states the capture exception next to the `out="$(…)"` rule it qualifies (rubric A2).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Floor-side `skills/dev-cycle/` refusal (new `--check` deny line) is untested | Minor | `scripts/lib/dev-cycle-read.sh:1923`; `test/scripts/build-loop-check.bats:1302-1303` | High |
| 2 | Header: two phrasings of the --approved rule set; inserted A1 sentence detaches "then" | Informational | `scripts/build-loop.sh:215, 233-236` | High |

## Overall Assessment

The delta resolves the three iteration-1 api findings it took on. F1: GATE_CODE and the header now include `skills/dev-cycle/`, matching plan D4, with a T35 case. F3: each non-approving answer is named. F6: the rename is complete, comments included. The new refusal texts follow the existing WHY conventions. The widened GATE_CODE is consistent with floor's "gate" sentence, which stays true for the new paths. What remains is small. The widening's second consumer, the self-merge floor's `--check` output, has no assertion (Finding 1, Minor, a two-row test addition). The `--help` paragraph has a wording wrinkle that overlaps the fact-check's one Mostly-accurate claim (Finding 2, Informational). One context note, not a finding: because SKILL.md gets floor's `instr` word, a self-merge refusal of the dev-cycle skill does not hint that the approval needs `merge-gate-`. That is more evidence for rubric C1's deferred U4 trigger (expose the expected heading before filing), not a new defect. Nothing here breaks an existing consumer.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/api-consistency-review-2026-10-10-u3a3-i2.md, structured per the api-consistency-reviewer skill, with `Commit: e25a6e89` at the top."

This report is at that path and opens with `Commit: e25a6e89`. It follows the skill's structure: header with Based on, Baseline Conventions, Name-Pattern Audit, Findings with Severity, Location, verbatim Evidence, Confidence and Legibility-target, What Looks Good, Summary Table and Overall Assessment. It adds an iteration-1 status table for the three findings the brief named. It serves the user goal (U3a3 through its review-fix loop and merged locally): no Breaking or Inconsistent finding, one Minor test gap that is cheap to fix in place, and one Informational wording note. No deferred rubric row was re-raised. Nothing was committed.
