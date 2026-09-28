Commit: 49a3dbb

# API Consistency Review: review/q085 (Q-085 [3], pr-prep step 1a size gate)

**Scope:** `git diff main...HEAD` on `review/q085` in `/workspace/.claude/wt-q085` (`workflows/pr-prep.md`, `docs/decisions/log.md` row 62, `docs/working/proposal-2026-09-27-smaller-review-units.md`), plus every doc that restates or depends on the pr-prep size rule
**Date:** 2026-09-28
**Based on:** `docs/reviews/q085-code-fact-check-report.md` (k=1, commit 49a3dbb)
**Pass:** loop pass, iteration 1, self-read delivery

In this repo the public surface is the workflow and skill docs: their rules, commands, thresholds, cross-references and the decision-log row format. The "consumers" are agents and the user following those docs, and the sibling docs that mirror pr-prep (the quick-reference, completion signals, code-review's next-action ladder).

## Baseline Conventions

- **Where each rule lives.** `workflows/review-fix-loop.md:7` states the convention: "Each rule is stated in one place; the others link to it." Mirrors are allowed but have to track the source. `guides/pr-prep-quick-ref.md:3` calls itself the "Actionable checklist for [workflows/pr-prep.md]". Earlier reviews treated a stale quick-ref as Must Fix (fact-check Claim 7).
- **The "hard cap" idiom.** The only existing "hard cap" is `review-fix-loop.md:23-25`, "bounded at **3 iterations**. This is a hard cap, not a soft ceiling". That cap is an exact integer, and the gate's exit is a named, written decision (`escalate | split | abandon`).
- **Line counting.** Existing size counts add insertions and deletions and include `docs/`: the pre-mortem `LOC_TOTAL` (`pr-prep.md:134`), code-review's next-action rule 2 (`chat-synthesis.md:140-141`, "added + removed per `git diff --stat`"), and the SI loop's Gate 1b. Step 1a on this branch is the first count that excludes a directory.
- **Split vocabulary.** Existing split rules say "split that part off … its own branch and loop with a fresh counter" (`review-fix-loop.md:50`) and "open per-piece branches, and start a new loop (with a fresh counter) on each piece" (`:69`). "Stacked PR" appears only in step 1b (`pr-prep.md:99`), as one of three options for unmerged dependencies.
- **/away split recording.** `review-fix-loop.md:52` records a split "as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line". `:69` points the iteration-4 split back to that rule.
- **"Review unit" and "unit".** `parallel-worktrees.md:50` defines "The review unit is the item (or the shared-state group from step 1)". `review-fix-loop.md:50,69` uses "the unit". The rest of pr-prep says "PR" and "branch", and the local-merge path reads "PR description" as the merge commit message (`pr-prep.md:24`).
- **Decision-log rows.** Five columns (# | Date | Decision | Rationale | Full record), numbered in sequence, with the bold decision sentence first. A row that replaces an earlier one is marked in the replaced row (`log.md:66`, "SUPERSEDED BY #44").

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Size gate` (step 1a heading) | step name | `Size check` (old 1a), `Dependent PR check` (1b), `Pre-mortem fallback check` (1c), parent `Gate checks` | `workflows/pr-prep.md:82,99,103`; `main:workflows/pr-prep.md:86` | Inconsistent (minor): siblings are "X check", and two references still say "size check" (`pr-prep.md:43`, `guides/pr-prep-quick-ref.md:11`). The rename itself is defensible because 1a now blocks. Folded into Findings 1 and 4. |
| `hard cap: ~400 code lines` | threshold term | `hard cap (3 iterations)` | `workflows/review-fix-loop.md:23-25` | Inconsistent: the existing "hard cap" is an exact number. See Finding 5. |
| `review unit` / `unit` | term | "review unit" = item or shared-state group; "the unit" in split rules | `workflows/parallel-worktrees.md:50`; `workflows/review-fix-loop.md:50,69` | Consistent: matches the term the per-item rule (log 59) introduced. |
| `stacked units` | term | `stacked PR` (1b), `per-piece branches` (iteration-4 split), `its own branch and loop` (early split) | `workflows/pr-prep.md:99`; `workflows/review-fix-loop.md:50,69` | Consistent in wording, inconsistent in how it composes with 1b. See Finding 3. |
| `waive the cap` / `waiver` | term | none. The earlier escape was "If it genuinely can't be split, note this in the PR description" | `main:workflows/pr-prep.md:91` | New convention, used the same way in 1a, the completion criterion and log 62. Consistent within the diff. |
| `code lines` (count definition) | contract term | "lines changed" (old 1a), `LOC_TOTAL` (all lines), "changed lines (added + removed per `git diff --stat`)" | `workflows/pr-prep.md:134`; `skills/code-review/references/chat-synthesis.md:140-141` | New counting rule (excludes `docs/`). The definition is explicit and the command matches it (fact-check Claim 12). Sibling counts now differ. See Findings 2 and Q1. |
| Decision log row `62` | log entry | rows 59–61 | `docs/decisions/log.md:82-84` | Consistent: next number, five cells, bold lead sentence, Full-record column cites sources. See Finding 6 on row 61. |

## Findings

#### 1. The pr-prep quick reference and completion signals still state the old advisory ~500-line rule with a self-declared escape

**Severity:** Inconsistent
**Location:** `guides/pr-prep-quick-ref.md:11`; `guides/completion-signals.md:82`
**Move:** 3 (trace the consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Precedent: pr-prep mirrors restate step 1a in `guides/pr-prep-quick-ref.md` (self-described as "Actionable checklist for [workflows/pr-prep.md]", `:3`)

Evidence:

```
# guides/pr-prep-quick-ref.md:11
- [ ] **Size check** — PR ≤ ~500 lines? If not, consider splitting before doing any other prep. If unsplittable, note in PR description and suggest file review order
```

```
# guides/completion-signals.md:82
- [ ] If the PR exceeds ~500 lines, have you considered splitting it or documented why not?
```

```
# workflows/pr-prep.md:92 (excerpt; the paragraph continues with the /away rule and split points — read)
Over ~400, the unit **must split** into stacked units that merge in order: … Only the user can waive it.
```

An agent working from either checklist applies a different threshold (500, not 400), a different count (all lines, not code lines outside `docs/`) and a different exit (it can declare the unit unsplittable itself; only the user can waive now). The quick-ref is the doc agents are meant to act from, so this is the contract drift most likely to undo the change. Fact-check Claims 6 and 7 have the same finding as Stale.

**Recommendation:** Rewrite both lines to the new contract, e.g. quick-ref: "**Size gate** — ≤ ~400 changed code lines outside `docs/` (command in pr-prep 1a)? If not, split into stacked units; only the user can waive". Completion signals: "If the unit exceeds ~400 code lines outside `docs/`, was it split, or did the user waive the cap?"

#### 2. code-review's "split PR" next action uses a different size contract from step 1a

**Severity:** Inconsistent
**Location:** `skills/code-review/references/chat-synthesis.md:140-143`
**Move:** 1 / 3 (baseline and consumer contract: two rules that give split advice on different counts)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:

```
# skills/code-review/references/chat-synthesis.md:140-143
2. **split PR** — Total diff is >500 changed lines (added + removed per
   `git diff --stat`) AND ≥1 🔴 item exists (and rule 1 did not match). Large
   diffs combined with red findings multiply review risk per iteration; split
   before iterating on fixes.
```

Step 1a now defines unit size as ~400 lines outside `docs/`, and the loop commits its review artifacts under `docs/reviews/`. A unit that passed 1a (say 150 code lines) and has gathered 400+ lines of review artifacts, with one red, gets `split PR` from code-review. That contradicts the rule 1a just applied. A waived 450-line unit with a red does not get it. The two rules give opposite advice on split timing for the same unit. Fact-check Claim 10 reports this as Stale.

**Recommendation:** Point rule 2 at step 1a's count and cap (for example "the unit exceeds step 1a's cap, counted the same way, AND ≥1 🔴"), or say that rule 2 fires only on a waived unit. Update the "800-line diff" worked example to match.

#### 3. The gate's `main...HEAD` count doesn't fit step 1b's stacked-PR option for upper units

**Severity:** Minor
**Location:** `workflows/pr-prep.md:89,92,99`
**Move:** 3 (consumer contract: a documented path that the gate blocks)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:

```
# workflows/pr-prep.md:89
git diff --numstat main...HEAD -- . ':(exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'
```

```
# workflows/pr-prep.md:92 (excerpt)
each lower unit runs its own review-fix loop and merges once green, so the units above it review against a settled base.
```

```
# workflows/pr-prep.md:99
**b. Dependent PR check.** If this branch builds on other unmerged PRs, verify they've been merged or that this PR's base is set correctly. If dependencies haven't landed, decide whether to wait, rebase onto a dev integration branch, or open as a stacked PR with a clear note. Skip this check for standalone branches.
```

1a implies the units run in sequence: an upper unit starts after the lower one merges. Step 1b, which runs concurrently ("Run these concurrently", `:84`), still offers "open as a stacked PR" before the dependency lands. If an upper unit takes that path, the hard-coded `main...HEAD` count includes the unmerged lower unit's lines, so the upper unit fails 1a again and would be split again. Fact-check Claim 12 notes the hard-coded base in its Scope. The prose is internally consistent. The problem is the combination with 1b.

**Recommendation:** Add one clause to 1a, e.g. "an upper unit starts step 1a only after the unit below it merges (step 1b's 'wait' option); do not use 1b's stacked-PR path for units split by this gate". Alternatively, parameterize the base (`<base>...HEAD`, where the base is the lower unit's branch while it is unmerged).

#### 4. Step 0's comment still says its total feeds "the size check in step 1a"

**Severity:** Minor
**Location:** `workflows/pr-prep.md:43-44`
**Move:** 2 / 3 (a name and cross-reference left over after the rename; documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Precedent: step 1a was named "Size check" in `main:workflows/pr-prep.md:86`

Evidence:

```
# workflows/pr-prep.md:43-44
# Show total lines changed (for the size check in step 1a)
git diff --stat main...HEAD | tail -1
```

Step 1a no longer reads this number. It runs its own `docs/`-excluding count (`:89`), and the two disagree (15 vs 12 on this branch, fact-check Claim 11). The comment still uses the old name "size check", and a reader could compare 15 against the ~400 cap.

**Recommendation:** Change the comment to "(all files, docs/ included; step 1a's size gate counts separately)" or remove the step-1a reference.

#### 5. "Hard cap: ~400" pairs the repo's exact-bound idiom with an approximate number

**Severity:** Informational
**Location:** `workflows/pr-prep.md:86,92,151`; `docs/decisions/log.md:85`
**Move:** 2 (naming against the grain: the "hard cap" term)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: "hard cap" with an exact bound used in `workflows/review-fix-loop.md:23-25`

Evidence:

```
# workflows/pr-prep.md:86 (excerpt)
**a. Size gate (hard cap: ~400 code lines per review unit).** Before the review-fix loop starts, count the unit's changed code lines, …
```

```
# workflows/review-fix-loop.md:25 (excerpt)
The review→fix→re-review loop is bounded at **3 iterations**. This is a hard cap, not a soft ceiling: …
```

The gate command prints an exact integer, but the rule and the completion criterion (`:151`, "at most ~400") don't say whether 410 or 450 is over. The only other "hard cap" in the repo is exact. An agent in /away mode, which must "split without asking", has no threshold to compare against, so one run splits at 405 and another doesn't. The "~" does match the user's answer text ("~400 code lines"), so this finding is about usability, not fidelity to the answer.

**Recommendation:** Keep "~400" as the stated intent and give a mechanical trigger, e.g. "the gate fires when the command prints more than 400". Alternatively, name a tolerance band. Either choice is the author's; it is not a rule change.

#### 6. The /away split record leaves out the commit-body `Notes:` line that the owning split rule requires

**Severity:** Minor
**Location:** `workflows/pr-prep.md:92`; `docs/decisions/log.md:85`
**Move:** 1 (baseline: the recording convention for /away splits)
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```
# workflows/pr-prep.md:92 (excerpt)
In /away mode, split without asking and record the split as an interim in `docs/working/questions.md`; a split is cheap to undo, a blocked loop is not.
```

```
# workflows/review-fix-loop.md:52 (excerpt; the paragraph continues with the Q-076 timeline — read)
In /away mode and autonomous loops, split without asking. Record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line.
```

The commit message says it matches "row 61's early-split rule", but the rule that owns early splits records in two places. The global running-questions rule also asks for the interim "in the entry AND in the commit body". The two split paths now record differently. Fact-check Claim 14 has this as Mostly accurate.

**Recommendation:** Add "and in the commit body's `Notes:` line" to 1a and to row 62, or link to `review-fix-loop.md#early-split-trigger-after-any-iteration` for the recording rule instead of restating it.

#### 7. Row 61 still says A4 "awaits the user's number" and has no forward pointer to row 62

**Severity:** Informational
**Location:** `docs/decisions/log.md:84`
**Move:** 3 (documentation drift in the decision log)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:

```
# docs/decisions/log.md:84 (excerpt from the Rationale cell)
A4 (size budget) is not adopted; it awaits the user's number.
```

The log's convention for replaced rows is an in-row marker (`log.md:66`, "SUPERSEDED BY #44"). Row 61 isn't superseded as a whole, because only this clause is now out of date. A reader who greps row 61 for A4 isn't sent to row 62. The log is otherwise append-only history, so this is optional.

**Recommendation:** Optionally add "(adopted in #62)" after the clause.

## Questions for the user (not findings)

- **Q1: Should deletions count toward the cap?** The gate adds insertions and deletions (`awk '{ n += $1 + $2 }'`). That matches every existing count in the repo (`pr-prep.md:134`, `chat-synthesis.md:140-141`). But a pure dead-code deletion of 450 lines, which is cheap to review, would have to split, while "~400 code lines" in Q-085 could be read as lines to read. Is counting deletions what you intended, or should the gate count insertions only, or deletions at a discount? Reported as a question per the brief. No rule change is proposed.

## What Looks Good

- The count definition is explicit and runnable, and the fact-check confirmed it does what the prose says (12 on this branch, matching a hand count; binaries 0; only top-level `docs/` excluded). route: code-fact-check
- The completion criterion (`pr-prep.md:151`) lists the same three outcomes as the prose (under cap / split / user waiver), and the waiver ties into the existing step-6 "Reviewer's path" requirement without a new mechanism. route: code-fact-check
- "Review unit" reuses the term log 59 introduced in `parallel-worktrees.md:50`, so the per-item unit and the size-gate unit are the same object. Each item runs pr-prep, so each item passes through 1a. route: code-fact-check
- The gate sits before the loop and doesn't overlap the early split trigger. The early trigger counts findings (`review-fix-loop.md:50`), the gate counts lines, and log 62 says why both exist. route: code-fact-check
- Row 62 follows the log's format: next number, five cells, bold lead sentence, sources cited, a revisit trigger. route: code-fact-check
- The pre-mortem `LOC_TOTAL > 500` trigger and code-review's tech-debt / large-diff thresholds are separate mechanisms and were correctly left alone (fact-check Claims 9, 16).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Quick-ref and completion signals keep the ~500 advisory with a self-declared escape | Inconsistent | `guides/pr-prep-quick-ref.md:11`; `guides/completion-signals.md:82` | High |
| 2 | code-review next-action rule 2 counts size differently from 1a | Inconsistent | `skills/code-review/references/chat-synthesis.md:140-143` | Medium |
| 3 | Hard-coded `main...HEAD` doesn't fit 1b's stacked-PR option for upper units | Minor | `workflows/pr-prep.md:89,92,99` | Medium |
| 4 | Step 0 comment still feeds "the size check in step 1a" | Minor | `workflows/pr-prep.md:43-44` | High |
| 6 | /away split record omits the commit-body `Notes:` line | Minor | `workflows/pr-prep.md:92`; `docs/decisions/log.md:85` | High |
| 5 | "Hard cap: ~400" has no mechanical threshold | Informational | `workflows/pr-prep.md:86,92,151` | Medium |
| 7 | Row 61 has no pointer to row 62 | Informational | `docs/decisions/log.md:84` | Medium |

## Overall Assessment

Within step 1a the change is consistent: the prose, the command, the completion criterion and log row 62 agree, and the term "review unit" reuses the per-item definition. The inconsistencies are at the edges. Two mirrors that agents act from (the quick-ref and completion signals) and code-review's "split PR" rule still carry the old 500-line, all-lines, self-waivable contract, so an agent following those docs would apply a different rule from the one this branch adds (Findings 1–2). The gate also doesn't yet compose with step 1b's stacked-PR path (Finding 3). All of these are fixable in place with one-line edits and need no redesign. Q1 (whether deletions count) is the user's call.

## Goal-Alignment Note

- **Answered:** API/contract consistency of branch `review/q085` against pr-prep's siblings, mirrors and the decision log, covering every consistency angle the brief listed (terminology, early split / iteration-4 split composition, parallel-worktrees step 4, stacked merge order vs 1b, "~400" as a hard cap, deletion counting as a question). Report is at the requested path with `Commit: 49a3dbb` on line 1.
- **Out of scope:** the SI loop's Gate 1b (500, `guides/validation-gates.md:48,274`), which is a policy question about whether that loop should adopt 400, not contract drift. `research-plan-implement.md`'s 500-line file-size rule, which is a different quantity. Commit history and packaging.
- **Escalate:** Q-085 is still `Status: OPEN` in this branch's `docs/working/questions.md`, and ANSWERED only on `answers-2026-09-28`. Check the merge order so the answer and the gate land together. Also pass Q1 (deletion counting) and the Finding 5 threshold choice to the user.
