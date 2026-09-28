# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q085`, branch `review/q085`)
**Commit:** b516af2
**Replication:** k=1 (loop pass, decision 031)
**Scope:** Fix delta `49a3dbb..HEAD` (commit b516af2): `workflows/pr-prep.md`, `guides/pr-prep-quick-ref.md`, `guides/completion-signals.md`, `skills/code-review/references/chat-synthesis.md`, `docs/decisions/log.md` row 62, and the b516af2 commit message. `docs/reviews/` files in the range (93f3b4d) are context only. Commit 49a3dbb was checked in iteration 1 (`docs/reviews/q085-code-fact-check-report.md`).
**Checked:** 2026-09-28
**Total claims checked:** 17
**Summary:** 13 verified, 3 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log: `docs/reviews/hallucination-patterns.md` was read. No claim in this delta matches a logged pattern.

Execution logs are under the scratch directory `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/`. They were not copied into the repo, because the brief allows only this report to be written. Every probe ran under `timeout 30`, and none was still running when this report was written. Git version: 2.39.5.

Legibility-target for every claim: **for-author**, unless the claim says otherwise.

---

## Claim 1: "Added and removed lines both count, against the unit's base (`main`, or the branch below it in a stack); the gate fires above 400."

**Location:** `docs/decisions/log.md:85`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's restatement of the counting rule, the base and the threshold against pr-prep step 1a and the executed command. It does not establish how the rule behaves once the lower branch has merged or been rebased (see Claim 11).
**Legibility-target:** for-author

The row matches step 1a, which reads `workflows/pr-prep.md:89-91`:

```bash
BASE=main   # for a stacked unit whose lower unit has not merged yet: that unit's branch
...
git diff --numstat "$BASE"...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'
```

The prose at `workflows/pr-prep.md:94` reads: "Added and removed lines both count; binary files count 0. The gate fires above 400". Claims 10 to 12 show the command's behaviour when run.

**Evidence:** `docs/decisions/log.md:85`, `workflows/pr-prep.md:89-94`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/stack.txt`

---

## Claim 2: "only the user can waive the cap, through an ANSWERED `questions.md` entry. In /away mode the agent splits without asking and records the split as an interim in `questions.md` and the commit body's `Notes:` line."

**Location:** `docs/decisions/log.md:85`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the row and pr-prep 1a / review-fix-loop.md:52. It does not establish where an answered entry lives after `questions.sh archive` (see Claim 15).
**Legibility-target:** for-author

Step 1a reads: "record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line" and "citing the `docs/working/questions.md` entry (`Q-NNN`, ANSWERED)" (`workflows/pr-prep.md:94`, `:101`). The row states the same rule.

**Evidence:** `docs/decisions/log.md:85`, `workflows/pr-prep.md:94`, `workflows/pr-prep.md:99`

---

## Claim 3: "Replaces step 1a's advisory size check (\"If the PR exceeds ~500 lines changed, consider whether it can be split\")."

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted text as a verbatim substring of main's step 1a. It does not establish that no other statement of the rule exists elsewhere (see Claim 17).
**Legibility-target:** for-author

`git show main:workflows/pr-prep.md` line 86: "**a. Size check.** Use the line count from Step 0's diff stat. If the PR exceeds ~500 lines changed, consider whether it can be split before doing any other prep work." The quote is a verbatim prefix of the second sentence and is cut before " before doing any other prep work". The row does not add an ellipsis, but the cut does not change the sense.

**Evidence:** `main:workflows/pr-prep.md:86`

---

## Claim 4: "Q-076 grew from +476 to ~+3,600 code lines under review"

**Location:** `docs/decisions/log.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the rounding of ~+3,600 against the proposal's +3,613 and against iteration 1's re-measurement. It does not re-measure Q-076's diff in this pass, and it does not check the +476 start figure, which this delta did not change.
**Legibility-target:** for-author

The proposal says: "The Q-076 code grew from +476 to +3,613 lines during review" (`docs/working/proposal-2026-09-27-smaller-review-units.md:8`). Iteration 1 re-measured the diff under the new rule at 3,593 insertions (paraphrased — no quote available because the figure comes from the iteration-1 rubric row A6, `docs/reviews/q085-code-review-rubric-2026-09-28.md:29`, which summarizes the fact-check). Both figures round to ~+3,600.

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:8`, `docs/reviews/q085-code-review-rubric-2026-09-28.md:29`

---

## Claim 5: "Is the unit within pr-prep step 1a's size gate (≤ 400 changed code lines outside `docs/`), or split into stacked units, or waived by the user with the `Q-NNN` entry cited?"

**Location:** `guides/completion-signals.md:82`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 1a's threshold, its exclusion and its three outcomes. It does not establish that the check sits in the right section: it is listed under "PR Description", while the gate runs before the review-fix loop.
**Legibility-target:** for-author

"≤ 400" is the complement of "fires above 400" (`workflows/pr-prep.md:94`). The three outcomes match the completion criterion at `workflows/pr-prep.md:153`: "at most 400 changed code lines ... OR it was split into stacked units, OR the user waived the cap ... with its `Q-NNN` entry".

**Evidence:** `guides/completion-signals.md:82`, `workflows/pr-prep.md:94`, `workflows/pr-prep.md:153`

---

## Claim 6: "**Size gate** — unit ≤ 400 changed code lines outside `docs/` (count with pr-prep step 1a's command)? If not, split into stacked units before the review-fix loop. Only the user can waive the cap (via an ANSWERED `questions.md` entry); note the waiver in the PR description and suggest a file review order"

**Location:** `guides/pr-prep-quick-ref.md:11`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with pr-prep step 1a (threshold, timing, waiver authority, waiver record, review order). It does not cover the /away split-recording duty, which the quick-ref omits. That is an omission, not a contradiction.
**Legibility-target:** for-author

Step 1a says "Before the review-fix loop starts" (`workflows/pr-prep.md:86`) and "Only the user can waive it" (`:94`). It also requires expanding "Reviewer's path — start here ... in dependency order" for an oversized PR (`:99`). The quick-ref's "suggest a file review order" is a shorter form of that.

**Evidence:** `guides/pr-prep-quick-ref.md:11`, `workflows/pr-prep.md:86-99`

---

## Claim 7: "Inputs are the rubric the synthesis just produced ... and the diff size from `git diff --stat`."

**Location:** `skills/code-review/references/chat-synthesis.md:128`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ladder's stated input against rule 2, the only rule that uses size. It does not establish whether any other consumer reads line 128's input list.
**Legibility-target:** for-author

The delta did not touch this line, but it is now stale because of the delta. Rule 2 now takes its size from step 1a's command, not from `git diff --stat`:

```
2. **split PR** — The unit is over the size gate in `workflows/pr-prep.md`
   step 1a (>400 changed lines outside `docs/`, counted with that step's
   command, so review artifacts don't count)
```
(`skills/code-review/references/chat-synthesis.md:140-142`; excerpt ends :142; rule 2 continues to :144 — read)

The two counts differ. `git diff --stat main...HEAD | tail -1` gives "11 files changed, 969 insertions(+), 12 deletions(-)" on this branch, while step 1a's command gives 31. A synthesizer that follows line 128 would feed rule 2 the wrong number (981 against a 400 threshold here). Fix: change the input to "the unit's size from pr-prep step 1a's command". The worked example at `:176` ("1 🔴 in security, 800-line diff → rule 2") is still correct under the new rule, because 800 > 400.

**Evidence:** `skills/code-review/references/chat-synthesis.md:128`, `skills/code-review/references/chat-synthesis.md:140-144`, `skills/code-review/references/chat-synthesis.md:176`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/step0.txt`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/root.txt`

---

## Claim 8: "2. **split PR** — The unit is over the size gate in `workflows/pr-prep.md` step 1a (>400 changed lines outside `docs/`, counted with that step's command, so review artifacts don't count) AND ≥1 🔴 item exists (and rule 1 did not match)."

**Location:** `skills/code-review/references/chat-synthesis.md:140-144`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 1a and the ladder's structure: rule numbering, the "rules 1–3" reference at :150, the next-action value list at :111, and the :176 example. It does not settle the input wording at :128 (Claim 7). It also does not establish what the rule should do for a user-waived unit, which is over 400 and so still derives `split PR` whenever a red exists.
**Legibility-target:** for-author

The rule keeps its number, label and position. Rule 4 still reads "(and rules 1–3 did not match)" (`:150`). The value list at `:111` still contains `split PR`. The ">400 ... outside `docs/`" wording matches `workflows/pr-prep.md:86` and `:94`. A grep for "split PR" or "rule 2" under `skills/ workflows/ guides/ hooks/ scripts/` finds only `chat-synthesis.md:111`, `:140` and `:176` (paraphrased — no quote available because the claim covers the absence of other hits). Nothing else references rule 2's old 500 threshold.

**Evidence:** `skills/code-review/references/chat-synthesis.md:111`, `skills/code-review/references/chat-synthesis.md:140-154`, `skills/code-review/references/chat-synthesis.md:176`

---

## Claim 9: "# Show total lines changed, all files (step 1a's size gate runs its own count)"

**Location:** `workflows/pr-prep.md:43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `git diff --stat main...HEAD | tail -1` prints and that step 1a no longer uses it. It does not cover the pre-mortem check's separate `LOC_TOTAL` count at :136, which also counts all files.
**Legibility-target:** for-author

Command: `git diff --stat main...HEAD | tail -1`, cwd `/workspace/.claude/wt-q085`, 2026-09-28T21:40:53Z. Output: " 11 files changed, 969 insertions(+), 12 deletions(-)", which is an all-files total. Step 1a runs its own `git diff --numstat` pipeline (`workflows/pr-prep.md:91`) and does not mention Step 0.

**Evidence:** `workflows/pr-prep.md:43-44`, `workflows/pr-prep.md:91`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/step0.txt`

---

## Claim 10: "':(top)' anchors both pathspecs at the repository root, so the count is the same from any directory."

**Location:** `workflows/pr-prep.md:90`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count from the repo root and from `skills/code-review` and `skills/` at HEAD and at 49a3dbb, on git 2.39.5, plus the validity of the combined `top,exclude` magic. It does not establish that `docs/` directories nested below the root are counted, and they are counted: only the root `docs/` is excluded, which matches "outside `docs/`".
**Legibility-target:** for-author

Commands, run under `timeout 30` with `BASE=main`:
- cwd `/workspace/.claude/wt-q085` at 21:38:52Z: 31, exit 0. numstat listed only `guides/completion-signals.md`, `guides/pr-prep-quick-ref.md`, `skills/code-review/references/chat-synthesis.md` and `workflows/pr-prep.md`.
- cwd `/workspace/.claude/wt-q085/skills/code-review` at 21:38:52Z: 31, exit 0, with the same four files.
- For contrast, the old form `-- . ':(exclude)docs/'` from the same subdirectory: 9.
- At 49a3dbb (21:40:53Z): 12 from the root and 12 from `skills/`. This matches rubric C1's "verified 12 from root and `skills/`".

Git accepted `:(top,exclude)docs/` without error. In a scratch repo, `sub/docs/n.md` (7 lines) was counted and root `docs/r.md` was not (`stack.txt`).

**Evidence:** `workflows/pr-prep.md:89-91`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/root.txt`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/subdir.txt`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/step0.txt`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/stack.txt`

---

## Claim 11: "BASE=main   # for a stacked unit whose lower unit has not merged yet: that unit's branch"

**Location:** `workflows/pr-prep.md:89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a linear three-branch stack (main → lower → upper) with lower unmerged, run from the root and from a subdirectory. It does not establish behaviour after the lower branch is squash-merged into main while upper still has lower's commits. In that case BASE must switch back to `main` or upper must be rebased, and the comment's "has not merged yet" scoping does cover that.
**Legibility-target:** for-author

Scratch repo at `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/repo`, 2026-09-28T21:39:02Z. `lower` adds 100 code lines and 50 lines under `docs/`. `upper` adds 30 lines, deletes 5, adds 7 under `sub/docs/` and adds a binary file. Results: `BASE=main -> 142`, `BASE=lower -> 42`, and `from src BASE=lower -> 42`. With `BASE` set to the lower branch, the count is exactly upper's own 30 + 5 + 7.

**Evidence:** `workflows/pr-prep.md:89-91`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/stack.txt`

---

## Claim 12: "Added and removed lines both count; binary files count 0."

**Location:** `workflows/pr-prep.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers awk's `$1 + $2` over numstat, where binary files show as `-	-`. It does not establish how a rename-with-edits is counted beyond git's default rename detection.
**Legibility-target:** for-author

In the scratch repo, numstat printed `0	5	src/a.txt` (deletions counted) and `-	-	src/bin.dat`. The total, 142 = 5 + 100 + 30 + 7, shows that the binary row added 0, because awk coerces `-` to 0. A modified line counts twice (one removal and one addition), which is what "both count" says.

**Evidence:** `workflows/pr-prep.md:91`, `workflows/pr-prep.md:94`, `/home/node/.claude/jobs/9f431b13/tmp/q085-fc2/logs/stack.txt`

---

## Claim 13: "The gate fires above 400: the \"~\" marks a round number, not a tolerance band."

**Location:** `workflows/pr-prep.md:94`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers internal consistency of the threshold across the step heading, prose, completion criterion, quick-ref, completion-signals, chat-synthesis rule 2 and row 62. It does not establish enforcement: no script compares the printed number to 400, and the agent makes the comparison by hand.
**Legibility-target:** for-author

The heading still reads "hard cap: ~400 code lines" (`:86`), and the prose now pins it: "fires above 400". The completion criterion says "at most 400" (`:153`), completion-signals says "≤ 400" and chat-synthesis says ">400". All of these agree.

**Evidence:** `workflows/pr-prep.md:86`, `workflows/pr-prep.md:94`, `workflows/pr-prep.md:153`, `guides/completion-signals.md:82`, `skills/code-review/references/chat-synthesis.md:141`

---

## Claim 14: "record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line, as the [early split trigger](review-fix-loop.md#early-split-trigger-after-any-iteration) does"

**Location:** `workflows/pr-prep.md:94`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the recording duty and the anchor target. It does not establish that the other clause of review-fix-loop.md:52 ("In /active mode, propose the split and wait") is mirrored in step 1a, and it is not: step 1a is silent on /active behaviour apart from "Only the user can waive it".
**Legibility-target:** for-author

`workflows/review-fix-loop.md:52`: "In /away mode and autonomous loops, split without asking. Record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line." The heading at `:48`, "### Early split trigger (after any iteration)", slugs to `early-split-trigger-after-any-iteration`, so the link resolves.

**Evidence:** `workflows/pr-prep.md:94`, `workflows/review-fix-loop.md:48-52`

---

## Claim 15: "citing the `docs/working/questions.md` entry (`Q-NNN`, ANSWERED) where the user granted it; a waiver with no such entry is not a waiver."

**Location:** `workflows/pr-prep.md:99`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ANSWERED status vocabulary and where an answered entry ends up. It does not establish any check that the cited entry actually grants a waiver. That remains a manual read.
**Legibility-target:** for-author

The status vocabulary matches. The questions script's grammar comment reads `#     **Needs:** <route> · **Opened:** YYYY-MM-DD · **Status:** OPEN|ANSWERED` (`~/.claude/scripts/questions.sh:16`). The global rule says to "set `Status: ANSWERED`, run `archive`".

The location is imprecise. `archive` moves answered entries to `docs/working/questions-archive.md`. Q-085 itself shows this: on `answers-2026-09-28` it now sits at `docs/working/questions-archive.md:1589` ("**Status:** ANSWERED"), not in `questions.md`. A reader who looks for the waiver in "the `docs/working/questions.md` entry" will usually not find it there. A more precise wording is "the `Q-NNN` entry (ANSWERED, in `questions.md` or `questions-archive.md`)". The Q-NNN ID is the stable handle, so the rule still works in practice.

**Evidence:** `workflows/pr-prep.md:99`, `/home/node/.claude/scripts/questions.sh:16`, `/workspace/docs/working/questions-archive.md:1589-1591`

---

## Claim 16: "(a stacked unit runs step 1a's count with `BASE` set to the branch below it)" and the completion criterion "at most 400 changed code lines (outside `docs/`, counted with step 1a's command against its base) ... the PR description records the waiver with its `Q-NNN` entry"

**Location:** `workflows/pr-prep.md:101`, `workflows/pr-prep.md:153`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement of step 1b and the completion criterion with step 1a's `BASE` variable, threshold and waiver record (behaviour executed in Claims 10–12). It does not establish the "has not merged yet" qualifier that step 1a's comment carries and step 1b omits. Step 1b's own context ("If dependencies haven't landed") supplies it.
**Legibility-target:** for-author

Step 1a defines `BASE` as "that unit's branch" for a stacked unit (`:89`). Step 1b points to it using the same term. The criterion's "against its base" and "with its `Q-NNN` entry" match `:89` and `:99`.

**Evidence:** `workflows/pr-prep.md:89`, `workflows/pr-prep.md:99-101`, `workflows/pr-prep.md:153`

---

## Claim 17: Commit b516af2 message: "Align the other statements of the old ~500-line rule with the new gate (quick-ref, completion-signals, code-review's \"split PR\" next action), fix Step 0's stale comment, and make the gate command root-anchored (':(top)') so it counts the same from any directory. ... Deletions still count, as the user's rule says; raised as a question."

**Location:** `b516af2` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the finding-ID mapping, the list of aligned statements, the root-anchoring claim (executed in Claim 10) and the deletions sentence. It does not establish that every other "500" in the repo is a different rule. It checks only the three named hits (see below).
**Legibility-target:** for-author

The following parts check out:
- The subject's "A1-A6, C1-C4" matches rubric rows A1–A6 and C1–C4, each marked Fixed (`docs/reviews/q085-code-review-rubric-2026-09-28.md:24-29`, `:37-40`).
- The three named files were changed (Claims 5, 6, 8).
- Step 0's comment was changed (Claim 9).
- Root-anchoring was executed (Claim 10).
- The "Row 62: verbatim old quote, ~+3,600" part is covered by Claims 3 and 4.

The remaining "500" statements are different rules, so they are not misses:
- `guides/validation-gates.md:48-52` ("Gate 1b: Diff size cap ... does not exceed 500") is the SI loop's gate.
- `skills/code-review/SKILL.md:35` and `guides/skill-trigger-guide.md:93` (">500 lines") are the tech-debt-triage trigger.
- `workflows/research-plan-implement.md:442` is the per-file size limit.

The deletions sentence has two imprecise parts:
- **"as the user's rule says".** The user's answer reads only "[3] ~400 code lines, every unit" (`/workspace/docs/working/questions-archive.md:1591`) and says nothing about deletions. The iteration-1 rubric itself lists the question as open: "User judgment: whether deletions should count toward the cap ... Raised by api-consistency as a question; the rule is unchanged." (`docs/reviews/q085-code-review-rubric-2026-09-28.md:94`). Counting deletions is the agent's reading of "changed lines", not something the user said.
- **"raised as a question".** It is raised only in that rubric note and in api-consistency's Q1. No `Q-NNN` entry for it exists in `docs/working/questions.md` on this branch or on `answers-2026-09-28`. A grep for "delet" finds no such entry (paraphrased — no quote available because the claim covers the absence of a match). Under the global running-questions rule, a `you: judgment` item would normally be filed there.

**Evidence:** `docs/reviews/q085-code-review-rubric-2026-09-28.md:24-40`, `docs/reviews/q085-code-review-rubric-2026-09-28.md:94`, `/workspace/docs/working/questions-archive.md:1589-1591`, `guides/validation-gates.md:48-52`, `skills/code-review/SKILL.md:35`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 7** (`skills/code-review/references/chat-synthesis.md:128`): the ladder's inputs still name "the diff size from `git diff --stat`", but rule 2 now uses step 1a's count, which is 31 against 981 on this branch. Point line 128 at step 1a's command.

### Mostly Accurate
- **Claim 15** (`workflows/pr-prep.md:99`): answered entries are archived to `questions-archive.md`, so "the `docs/working/questions.md` entry" is usually the wrong place to look. Name the Q-NNN, which lives in either file.
- **Claim 17** (commit b516af2): the user's answer does not say deletions count. That is the agent's reading, still an open user judgment according to the rubric, and it was not filed as a `Q-NNN` entry.
- **Claim 3** is Verified, not Mostly accurate, and is listed here only as a note: the row's quote is a verbatim prefix cut before "before doing any other prep work", without an ellipsis.

### Unverifiable
- None.

## Goal-Alignment Note

- **Answered:** I fact-checked every non-`docs/reviews/` claim in the fix delta 49a3dbb..b516af2 against the code, covering all 8 items in the brief. I executed the gate command from the root and from subdirectories at both commits, in a scratch stacked repo with a binary file, and I executed Step 0's total. There are no Incorrect verdicts. One Stale item (chat-synthesis.md:128, made stale by the rule 2 edit) and two Mostly accurate items (the waiver entry's location after archive; the commit's deletions attribution) are for-author and cheap to fix.
- **Out of scope:** Commit 49a3dbb (checked in iteration 1) and the `docs/reviews/` artifacts from 93f3b4d were used as context only. Whether deletions *should* count, and how rule 2 should treat a user-waived unit, are design questions, not fact-checks, so I noted them in Scope fields without verdicting them.
- **Escalate:** The deletions question is described as raised but has no `Q-NNN` entry. The orchestrator should decide whether to file one as `you: judgment`. The brief did not allow writing execution logs into the repo, so the executed claims cite logs in the job scratch directory, which may not outlive the session.
