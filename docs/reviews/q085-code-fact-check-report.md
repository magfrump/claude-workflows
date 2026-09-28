# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q085`)
**Scope:** branch diff `review/q085` vs `main` (`git diff main...HEAD`: `workflows/pr-prep.md`, `docs/decisions/log.md` row 62, `docs/working/proposal-2026-09-27-smaller-review-units.md`), plus the commit message and every other file that states a PR/review-unit size rule or depends on pr-prep step 1a
**Commit:** 49a3dbb
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-28
**Total claims checked:** 20
**Summary:** 13 verified, 3 mostly accurate, 4 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim matches a logged pattern.

Execution logs are written to the scratch directory `/home/node/.claude/jobs/9f431b13/tmp/q085-fc/`, not to `docs/reviews/execution-logs/`, because this pass may modify only this report. They are not committed.

---

## Claim 1: "Replaces step 1a's advisory \"~500 lines, consider splitting\"."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the old step 1a was advisory and ~500-line. Does not establish that the quoted string is verbatim.
**Legibility-target:** for-author

The old text on `main` was advisory and used ~500. The quoted phrase itself is not in it:

```
# main:workflows/pr-prep.md:86
**a. Size check.** Use the line count from Step 0's diff stat. If the PR exceeds ~500 lines changed, consider whether it can be split before doing any other prep work. Look for:
```

The quotation marks suggest a verbatim string. A precise version would drop the quotation marks or quote `If the PR exceeds ~500 lines changed, consider whether it can be split`.

**Evidence:** `main:workflows/pr-prep.md:86`, `docs/decisions/log.md:85`

---

## Claim 2: "User answer to Q-085 ([3]), over the proposal's ~600 and over an enforcement-files-only scope"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the proposal's ~600 figure, the Q-085 options and the recorded answer on branch `answers-2026-09-28`. Does not establish that the answer is recorded on this branch or on `main`: in both, Q-085 still reads `Status: OPEN`.
**Legibility-target:** for-orchestrator-synthesis

The proposal's A4 figure is ~600:

```
# docs/working/proposal-2026-09-27-smaller-review-units.md:34
**A4 · A size budget per unit.** At loop entry, a unit over ~600 changed code lines (reviews excluded) must split into stacked units, unless the user waives it. … (excerpt ends mid-paragraph; the rest describes the Q-076 stack and step-0 — read)
```

Q-085 offered an enforcement-files-only option, and the archive on `answers-2026-09-28` records answer [3]:

```
# answers-2026-09-28:docs/working/questions-archive.md:1591,1600,1602
**Answered 2026-09-28: [3] ~400 code lines, every unit.** Done in 6e9fa45: …
| **[1] ~600 code lines, enforcement files only** | Cap applies when the diff touches a file the live-verify gate covers; …
| **[3] ~400 code lines, every unit** | Closer to the usual human-review guidance | More stacks | Split overhead dominates on small features |
```

"Closer to the usual human-review guidance" in row 62 repeats option [3]'s text. Side note: the archive cites commit `6e9fa45`, while this branch's commit is `49a3dbb`. That archive is on another branch and outside this diff.

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:34`, `answers-2026-09-28:docs/working/questions-archive.md:1588-1606`, `docs/working/questions.md:191-207`

---

## Claim 3: "Q-076 grew from +476 to +3,613 code lines under review"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the Q-076 first commit and the final Q-076 branch, both measured outside `docs/`. Does not establish at which point +3,613 was measured. The figure is inherited from row 61 and the proposal, which say "lines", not "code lines".
**Legibility-target:** for-author

Commands, run in `/workspace/.claude/wt-q085` at 2026-09-28T14:25:01-07:00, exit 0:

- `git show --shortstat 37cae85 -- . ':(exclude)docs/'` returned `3 files changed, 476 insertions(+), 8 deletions(-)`. The +476 figure holds.
- `git diff --shortstat 86b094d...5479529 -- . ':(exclude)docs/'` returned `11 files changed, 3593 insertions(+), 35 deletions(-)`. That is the final Q-076 head, the second parent of merge `7387d8f`.
- Piping the same range's numstat through the new gate's awk returned `3628`.

Neither measure gives 3,613 exactly: insertions are +3,593, and the gate's own count is 3,628. Both are within 0.6%, so the claim's point holds. Row 62 re-labels the inherited figure as "code lines", and its own counting rule does not reproduce it exactly. A precise version would say "+476 to ~+3,600".

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q085-fc/exec-q076-size.log`, `docs/working/proposal-2026-09-27-smaller-review-units.md:8`, `docs/decisions/log.md:84`

---

## Claim 4: "the early split trigger (row 61) reacts only after an iteration has run, while the cap acts before the first"

**Location:** `docs/decisions/log.md:85`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers when the early split trigger and the new gate fire. Does not establish that the gate cannot be skipped in practice: nothing enforces it mechanically.
**Legibility-target:** for-orchestrator-synthesis

```
# workflows/review-fix-loop.md:50
Do not wait for the cap to split. After triaging any iteration, count its Must Fix findings and fact-check Incorrect verdicts. … (excerpt ends mid-paragraph; the rest gives the 3-finding / 75% condition — read)
```

```
# workflows/pr-prep.md:86
**a. Size gate (hard cap: ~400 code lines per review unit).** Before the review-fix loop starts, count the unit's changed code lines, …
```

**Evidence:** `workflows/review-fix-loop.md:48-52`, `workflows/pr-prep.md:86-92`

---

## Claim 5: "~~A4's size budget: ~600 lines, enforcement files only?~~ Answered 2026-09-28 (Q-085 [3]): ~400 code lines, every unit (decision log 62, pr-prep step 1a)."

**Location:** `docs/working/proposal-2026-09-27-smaller-review-units.md:104`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the answer recorded on `answers-2026-09-28` and the existence of log row 62 and pr-prep step 1a on this branch. Does not establish that the answer is recorded on this branch: Q-085 in this branch's `docs/working/questions.md:192` is still `Status: OPEN`.
**Legibility-target:** for-orchestrator-synthesis

The recorded answer is quoted under Claim 2: "[3] ~400 code lines, every unit". Log row 62 is at `docs/decisions/log.md:85`, and step 1a is the new size gate at `workflows/pr-prep.md:86`. The struck-through text shortens the original question, which read "is ~600 changed code lines per unit the right number, and should the budget apply only to enforcement files?". That is fine for a closed item.

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:104`, `answers-2026-09-28:docs/working/questions-archive.md:1591`, `docs/decisions/log.md:85`

---

## Claim 6: "If the PR exceeds ~500 lines, have you considered splitting it or documented why not?"

**Location:** `guides/completion-signals.md:82`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers this checklist line against the new pr-prep step 1a. Does not establish how widely this guide is used.
**Legibility-target:** for-author

```
# guides/completion-signals.md:82
- [ ] If the PR exceeds ~500 lines, have you considered splitting it or documented why not?
```

pr-prep now requires a split above ~400 code lines outside `docs/`, and only the user can waive it (`workflows/pr-prep.md:92`: "Over ~400, the unit **must split** … Only the user can waive it."). "Documented why not" is no longer a valid way out. A precise version: "If the unit exceeds ~400 changed code lines outside `docs/`, was it split, or did the user waive the cap?"

**Evidence:** `guides/completion-signals.md:82`, `workflows/pr-prep.md:92`

---

## Claim 7: "**Size check** — PR ≤ ~500 lines? If not, consider splitting before doing any other prep. If unsplittable, note in PR description and suggest file review order"

**Location:** `guides/pr-prep-quick-ref.md:11`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quick reference's step-1 size line. Does not establish whether other quick-ref lines drifted.
**Legibility-target:** for-author

The quick reference calls itself the "Actionable checklist for [workflows/pr-prep.md]" (`guides/pr-prep-quick-ref.md:3`). It still states the old advisory ~500-line rule, with self-certified "unsplittable" as a way out. pr-prep step 1a is now a ~400 code-line gate that only the user can waive (`workflows/pr-prep.md:92`). In 2026-04, a stale quick ref after a pr-prep restructure was a Must Fix (`docs/reviews/draft-review-two-phase-pr-prep.md:9`, F1).

**Evidence:** `guides/pr-prep-quick-ref.md:3,11`, `workflows/pr-prep.md:86-92`

---

## Claim 8: "**What it checks:** Total lines changed (insertions + deletions) does not exceed 500."

**Location:** `guides/validation-gates.md:48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the self-improvement loop's Gate 1b as a separate mechanism from pr-prep. Does not establish whether the SI loop should adopt the new ~400 cap. That is a policy question, not a factual drift.
**Legibility-target:** for-orchestrator-synthesis

This gate belongs to the self-improvement loop ("The self-improvement loop validates every implementation branch before merging to main", `guides/validation-gates.md:3`), and it matches its script:

```
# scripts/self-improvement.sh:1180
    MAX_DIFF_LINES=500
```

It does not restate pr-prep step 1a, so the new cap does not make it stale. The two numbers now differ, which may be worth noting because the SI loop "dogfoods" pr-prep (`guides/validation-gates.md:207`).

**Evidence:** `guides/validation-gates.md:3,46-52`, `scripts/self-improvement.sh:1180,1207`

---

## Claim 9: code-review's size thresholds: "`tech-debt-triage.md` — triggered on large diffs (>10 files or >500 lines)" and "Large diff triage (~1000+ lines)"

**Location:** `skills/code-review/SKILL.md:35`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether these thresholds contradict the new cap. Does not establish that they still serve their purpose under it: under the cap, the ~1000-line triage is reached only on a waived unit.
**Legibility-target:** for-orchestrator-synthesis

Both thresholds govern review mechanics, not whether the unit must split. `:227` selects a contextual critic ("Large diff: >10 files changed OR >500 added/removed lines … `tech-debt-triage`"). `:142-153` splits the *review* into passes ("split the review into multiple passes by subsystem or file group … propose the split to the user before launching Stage 1"). Neither conflicts with a pre-loop unit cap. Both count all lines, `docs/` included, so they measure something different from step 1a.

**Evidence:** `skills/code-review/SKILL.md:35,142-153,227`

---

## Claim 10: "**split PR** — Total diff is >500 changed lines (added + removed per `git diff --stat`) AND ≥1 🔴 item exists"

**Location:** `skills/code-review/references/chat-synthesis.md:140`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers rule 2 of the next-action derivation against the new step 1a counting rule. Does not establish how often rule 2 fires in practice.
**Legibility-target:** for-author

```
# skills/code-review/references/chat-synthesis.md:140-143
2. **split PR** — Total diff is >500 changed lines (added + removed per
   `git diff --stat`) AND ≥1 🔴 item exists (and rule 1 did not match). Large
   diffs combined with red findings multiply review risk per iteration; split
   before iterating on fixes.
```

The rule's size input is the whole diff. pr-prep now sets the unit size rule as ~400 lines outside `docs/`, and the loop commits its review artifacts to the branch under `docs/reviews/` (`workflows/pr-prep.md`, step 3 completion criteria: "Review artifacts committed to the branch"). So a 100-code-line unit that has gathered 400+ lines of review artifacts and has one red row gets `split PR`, which contradicts step 1a's "leaving out `docs/`". A waived unit of 400–500 code lines with a red row does not. A precise version would count the way step 1a does and point to the ~400 cap.

**Evidence:** `skills/code-review/references/chat-synthesis.md:128,140-143,175`, `workflows/pr-prep.md:86-92`

---

## Claim 11: "# Show total lines changed (for the size check in step 1a)"

**Location:** `workflows/pr-prep.md:43`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Step 0 comment's claim that step 1a uses this number. Does not establish anything else about Step 0.
**Legibility-target:** for-author

```
# workflows/pr-prep.md:43-44
# Show total lines changed (for the size check in step 1a)
git diff --stat main...HEAD | tail -1
```

Step 1a no longer reads Step 0's number. It runs its own `git diff --numstat … ':(exclude)docs/' | awk …` (`:89`), and the old "Use the line count from Step 0's diff stat" sentence was removed. Step 0's `--stat` total includes `docs/`, so it disagrees with the gate's count: on this branch it reports 15 changed lines, the gate reports 12. Step 0's completion criterion ("total files and lines changed are known", `:73`) doesn't depend on step 1a, so only the comment is stale. Proposal A4 (`docs/working/proposal-2026-09-27-smaller-review-units.md:34`) makes the same outdated link ("The pr-prep step-0 size check already computes the number"), but that line is outside this diff.

**Evidence:** `workflows/pr-prep.md:43-44,73,86-89`

---

## Claim 12: The gate command counts "the unit's changed code lines, leaving out `docs/`"

**Location:** `workflows/pr-prep.md:86-89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added+removed text lines outside the top-level `docs/` directory, when run from the repo root against `main...HEAD`. Does not establish four edge cases, each observed: binary files count 0 (numstat prints `-\t-`, and awk reads `"-"` as 0); a rename counts only the lines that changed, not the whole moved file; nested `*/docs/` directories (e.g. `pkg/docs/`) are counted, not excluded; run from a subdirectory, `.` and `docs/` resolve relative to that directory. It also does not establish the right base for an upper stacked unit: the command hard-codes `main...HEAD`, which is right only once lower units have merged, as the prose says they should.
**Legibility-target:** for-orchestrator-synthesis

```
# workflows/pr-prep.md:89
git diff --numstat main...HEAD -- . ':(exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'
```

Runs, all exit 0:

1. In `/workspace/.claude/wt-q085` at 2026-09-28T14:22:51-07:00 it printed `12`. The branch numstat is `docs/decisions/log.md` 1/0, the proposal 1/1 and `workflows/pr-prep.md` 9/3. Only `pr-prep.md` (9+3=12) survives the exclude, which matches a manual count.
2. In a scratch repo at 2026-09-28T14:25:01-07:00 (100-line file renamed with +1 line, a binary file, `docs/e.md` +30, `docsx.txt` +20, `pkg/docs/x.md` +7) it printed `28` = 20 + 7 + 1 + 0. So `docs/` was excluded, `docsx.txt` was not (the exclude matches the directory, not the prefix), the binary counted 0 and the rename counted 1.
3. From `workflows/` inside the worktree, the pathspec was scoped to that directory (only `workflows/pr-prep.md` was listed).

These edges match the prose's "changed code lines". None makes the gate under-count normal text code in this repo, which has no nested `docs/` of note.

**Evidence:** `/home/node/.claude/jobs/9f431b13/tmp/q085-fc/exec-gate.log`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc/exec-edgecases.log`, `workflows/pr-prep.md:86-92`

---

## Claim 13: "The cap applies to every unit, not only to enforcement files (decision log 62, Q-085 [3]). Only the user can waive it."

**Location:** `workflows/pr-prep.md:92`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cross-references and the "every unit" and "only the user" wording against log row 62 and the recorded answer. Does not establish that the answer is recorded on this branch (see Claim 5).
**Legibility-target:** for-orchestrator-synthesis

Row 62 says: "**Every review unit has a hard size cap of ~400 changed code lines, counted outside `docs/` … only the user can waive the cap.**" (`docs/decisions/log.md:85`). The recorded answer is "[3] ~400 code lines, every unit" (see Claim 2).

**Evidence:** `workflows/pr-prep.md:92`, `docs/decisions/log.md:85`, `answers-2026-09-28:docs/working/questions-archive.md:1591`

---

## Claim 14: "In /away mode, split without asking and record the split as an interim in `docs/working/questions.md`" (also log row 62, and the commit Notes: "matching row 61's early-split rule")

**Location:** `workflows/pr-prep.md:92`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the recording rule matches row 61 and `review-fix-loop.md`. Does not establish whether the omission was deliberate.
**Legibility-target:** for-author

The rule matches row 61's text ("In /away mode splitting is the default, recorded as an interim in `questions.md`", `docs/decisions/log.md:84`). It leaves out half of the rule that owns early splits:

```
# workflows/review-fix-loop.md:52
In /away mode and autonomous loops, split without asking. Record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line. … (excerpt ends mid-paragraph; the rest is the Q-076 timeline — read)
```

The global running-questions rule also requires the interim choice "in the entry AND in the commit body" (`global-instructions/CLAUDE.md`, Running questions document). The same omission is in log row 62 (`docs/decisions/log.md:85`). A precise version: "record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line."

**Evidence:** `workflows/pr-prep.md:92`, `workflows/review-fix-loop.md:52`, `docs/decisions/log.md:84-85`

---

## Claim 15: "for an oversized PR, expand that section … so a 1000-line change still has a named place to start" and "the PR likely needs splitting (see Phase 1, step 1a)"

**Location:** `workflows/pr-prep.md:97`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the reviewer's-path guidance and the step-6 cross-reference still fit the new gate. Does not establish that the "1000-line" example is typical under the cap.
**Legibility-target:** for-orchestrator-synthesis

`:97` now opens "If the user waives the cap, note the waiver in the PR description (step 6)", so "oversized PR" means a waived unit, and the 1000-line example is a coherent case. Step 6's pointer `(see Phase 1, step 1a) — that's a signal, not a reason to leave this blank.` (`:412`) still lands on the size gate.

**Evidence:** `workflows/pr-prep.md:97,412`

---

## Claim 16: Pre-mortem fallback: `LOC_TOTAL … -gt 500` (all lines) alongside the ~400 code-line cap

**Location:** `workflows/pr-prep.md:134-137`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the absence of a contradiction between the two thresholds. Does not establish that 500 is still the right pre-mortem trigger when units are capped lower.
**Legibility-target:** for-orchestrator-synthesis

```
# workflows/pr-prep.md:134,137
LOC_TOTAL=$(git diff --numstat main...HEAD | awk '{ i+=$1; d+=$2 } END { print i+d+0 }')
if [[ -z "$PREMORTEM_EXISTS" ]] && { [[ "${LOC_TOTAL:-0}" -gt 500 ]] || [[ -n "$HIGH_RISK_PATHS" ]]; }; then
```

This is a separate trigger with a separate purpose, and it counts `docs/` too. A capped unit can still exceed 500 through docs, and a waived unit exceeds it anyway. Neither statement claims to be the unit size rule.

**Evidence:** `workflows/pr-prep.md:130-146`

---

## Claim 17: "The unit is at most ~400 changed code lines (outside `docs/`), OR it was split into stacked units, OR the user waived the cap and the PR description records the waiver and an expanded \"Reviewer's path — start here\" section"

**Location:** `workflows/pr-prep.md:151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the completion criterion and the step 1a prose. Does not establish that "it was split" is checkable for the remaining unit's own size.
**Legibility-target:** for-orchestrator-synthesis

The three branches match `:92` (the cap and the split) and `:97` (the waiver, noted in the PR description, with the expanded reviewer's path).

**Evidence:** `workflows/pr-prep.md:92,97,151`

---

## Claim 18: No other always-loaded or workflow file states a PR/unit size rule that the change leaves stale

**Location:** `workflows/review-fix-loop.md:48`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers `workflows/review-fix-loop.md`, `workflows/parallel-worktrees.md`, `AGENTS.md`, `GEMINI.md`, `global-instructions/CLAUDE.md` and the `test/`, `scripts/` and `hooks/` trees for a line-count rule tied to pr-prep. Does not cover `archive/`, `docs/reviews/` history, or the stale statements already reported in Claims 6, 7, 10 and 11.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim covers absence of code (no matching grep results). `rg -i '500|400|size check|step 1a|oversized'` over these files finds no unit size threshold. The early split trigger is count- and share-based ("at least 3 and one item or one file group holds about 75%", `workflows/review-fix-loop.md:50`), with no line count. No test pins step 1a's wording: `test/workflow-required-sections.bats` passed 4/4 at 2026-09-28 (`timeout 300 bats test/workflow-required-sections.bats`, cwd the worktree, exit 0).

**Evidence:** `workflows/review-fix-loop.md:48-52`, `workflows/parallel-worktrees.md:58`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc/exec-bats.log`

---

## Claim 19: "Step 1a's advisory 500-line check becomes a gate: over ~400 changed lines outside docs/, the unit splits into stacked units unless the user waives it. Decision log 62."

**Location:** commit `49a3dbb` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit summary against the diff. Does not cover the unverifiable `Confidence: medium` line.
**Legibility-target:** for-orchestrator-synthesis

The diff replaces `**a. Size check.** … ~500 lines changed, consider whether it can be split` with `**a. Size gate (hard cap: ~400 code lines per review unit).**` and adds row 62 (`docs/decisions/log.md:85`).

**Evidence:** `workflows/pr-prep.md:86-97`, `docs/decisions/log.md:85`

---

## Claim 20: "\"code lines\" is read as everything outside docs/, so skills/ and workflows/ markdown counts; the proposal said only \"reviews excluded\"."

**Location:** commit `49a3dbb` message (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers proposal A4's wording and the gate's inclusion of `skills/` and `workflows/`. Does not establish the user's intent: Q-085 option [1] said "reviews and docs excluded from the count", while option [3], the one chosen, did not say.
**Legibility-target:** for-orchestrator-synthesis

A4: "a unit over ~600 changed code lines (reviews excluded)" (`docs/working/proposal-2026-09-27-smaller-review-units.md:34`). The gate's pathspec leaves out only `docs/`, so `workflows/pr-prep.md` counted on this branch (Claim 12, count 12).

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:34`, `docs/working/questions.md:201,203`, `workflows/pr-prep.md:89`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 6** (`guides/completion-signals.md:82`): still says ~500 lines with "documented why not" as a way out. Update it to ~400 code lines outside `docs/`, with split or user waiver.
- **Claim 7** (`guides/pr-prep-quick-ref.md:11`): the quick-ref size line still states the old advisory ~500 rule and self-certified "unsplittable". Mirror the new step 1a gate.
- **Claim 10** (`skills/code-review/references/chat-synthesis.md:140`): rule 2 "split PR" counts the whole diff, review artifacts included, at >500. Align it with step 1a's count and the ~400 cap.
- **Claim 11** (`workflows/pr-prep.md:43`): the Step 0 comment says its total feeds step 1a, but step 1a now runs its own command, and the two counts differ (15 vs 12 on this branch).

### Mostly Accurate
- **Claim 1** (`docs/decisions/log.md:85`): the quoted "~500 lines, consider splitting" is not verbatim. Drop the quotation marks or quote the real text.
- **Claim 3** (`docs/decisions/log.md:85`): +3,613 does not reproduce under the stated counting rule (+3,593 insertions, 3,628 ins+del outside `docs/`). Say ~+3,600.
- **Claim 14** (`workflows/pr-prep.md:92`, also log row 62): the /away split record leaves out the commit body `Notes:` line that `review-fix-loop.md:52` and the global running-questions rule require.

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Answered:** All seven brief items. (1) I ran the gate command and probed binary, rename, nested-docs and subdirectory cases (Claim 12). (2) Internal pr-prep consistency: Claims 11 and 15–17. (3) Other files: Claims 6–10 and 18. (4) Row 62 facts: Claims 1–4. (5) The /away recording rule: Claim 14. (6) The proposal note and the Q-085 answer: Claims 2 and 5. (7) The commit message: Claims 14, 19 and 20. No Incorrect verdicts. Four Stale and three Mostly accurate are for the author.
- **Out of scope:** Whether the SI loop's Gate 1b (500) or the pre-mortem's 500 should move to 400 is policy, not drift (Claims 8 and 16). The `6e9fa45` vs `49a3dbb` hash in the answers-branch archive belongs to another branch. Proposal A4's "step-0 size check already computes the number" (`:34`) is outside this diff and repeats the outdated link from Claim 11.
- **Escalate:** On this branch and on `main`, Q-085 is still `Status: OPEN` in `docs/working/questions.md`. The ANSWERED record exists only on `answers-2026-09-28`, so the proposal note (Claim 5) and row 62 rely on that branch merging too. Execution logs are in the scratch directory, not committed, per this pass's write restriction.
