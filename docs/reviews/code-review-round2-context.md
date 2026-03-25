# Code Review: Prior-Round Context for Idea Generation

**Commit:** 7ab4b9e — `fix: Provide prior-round context to idea generation prompt`
**File:** `self-improvement.sh` (Step 0b addition)
**Reviewer:** Claude (automated review)
**Date:** 2026-03-24

---

## Critical

*None found.*

---

## Important

### 1. `claude -p` for unattempted-survivors detection is fragile and expensive

**Lines 200-206.** The unattempted survivors detection delegates entirely to a `claude -p` call that reads two files and performs fuzzy matching between "Survivors" section names and task IDs/descriptions.

Problems:
- **Hallucination risk.** The LLM must match free-text idea names (e.g., "#2 Workflow exit criteria") to task IDs (e.g., `workflow-exit-criteria`) via semantic similarity. There is no structured key linking ideas to tasks, so the model could mis-match or hallucinate non-existent survivors.
- **Cost.** This invokes a full LLM call during what is otherwise a deterministic shell preprocessing step. Every round > 1 pays this cost even if there are no unattempted survivors.
- **Output format is uncontrolled.** The prompt says "one idea per line" and "output NONE if empty," but there is no parsing or validation of the response. If the model outputs preamble like "Here are the unattempted survivors:" that text lands verbatim in `PRIOR_CONTEXT` and may confuse the downstream idea-generation prompt.

**Suggestion:** Consider a deterministic approach -- the tasks file contains structured IDs and the ideas file's Survivors section has a predictable format (`- **#N Idea name**`). A `grep` + set-difference could handle this without an LLM call. Alternatively, at minimum add output-format validation (check if the response starts with "NONE" or matches the expected line pattern).

### 2. Only looks at the immediately prior round (PREV), not all prior rounds

**Line 167.** `PREV=$((ROUND - 1))` means round 3 only sees round 2's results, not round 1's. If round 2 rejected a task and round 3 re-attempted and also rejected it, round 4 would only see round 3's rejection -- losing the history of why round 2 also rejected it.

More importantly, approved tasks from round 1 would not appear in round 3's APPROVED list, meaning the prompt's instruction "do not re-propose approved ideas" only covers the single prior round. The `completed-tasks.md` review partially mitigates this (the prompt also says "Review docs/working/completed-tasks.md for what has already been done"), but the structured context block could actively mislead by omission -- presenting an incomplete picture of what's already been tried.

**Suggestion:** Either iterate over all prior rounds (1..PREV) or explicitly note in the prompt that the APPROVED/REJECTED lists cover only the most recent round and that `completed-tasks.md` is the authoritative source for all prior work.

### 3. Empty verdict treated as rejection for unvalidated tasks

**Line 178-180.** If a task exists in the tasks file but round-history.json has no validation entry for it (e.g., validation hadn't run yet, or the round entry has empty validation like round 2's `"validation": {}`), the jq query returns `"unknown"`. The code's if/else on line 184 sends anything that isn't `"approved"` into the rejected list -- including `"unknown"`.

This means tasks that were never validated would appear as "REJECTED (failed: unknown)" in the context, which is actively misleading.

**Suggestion:** Add an explicit check: if `VERDICT` equals `"unknown"`, either skip the task or put it in a separate "unvalidated" category.

---

## Minor

### 4. `echo -e` interprets escape sequences in task descriptions

**Lines 214-215.** The `$(echo -e "$APPROVED_LIST")` and `$(echo -e "$REJECTED_LIST")` calls interpret `\n` as newlines (intentional for the separator), but they will also interpret any `\t`, `\\`, `\a`, etc. that happen to appear in task descriptions. For example, a description mentioning "use `\n` as delimiter" would have the literal `\n` converted to a newline.

**Suggestion:** Use `printf '%b'` instead of `echo -e` for more predictable behavior, or build the list using actual newlines instead of `\n` escape sequences.

### 5. The condition for assembling PRIOR_CONTEXT may produce empty sections

**Line 210.** The guard checks `[ -n "$APPROVED_LIST" ] || [ -n "$REJECTED_LIST" ] || [ -n "$UNATTEMPTED" ]`. If only one is non-empty, the others produce empty sections in the output. For example, if only APPROVED_LIST is non-empty, the output includes:

```
REJECTED (failed validation -- consider re-proposing with improvements):

UNATTEMPTED SURVIVORS (validated but never implemented -- strong candidates):
```

These empty sections add noise and could confuse the downstream LLM into thinking there genuinely are no rejected/unattempted ideas rather than that the data wasn't available.

**Suggestion:** Conditionally include each section only when it has content.

### 6. UNATTEMPTED variable checked with `-n` but could contain "NONE"

**Line 210.** If the `claude -p` call returns "NONE" (as instructed when all survivors became tasks), `$UNATTEMPTED` is non-empty (it contains the string "NONE"), so the condition passes and the context block is assembled. The UNATTEMPTED SURVIVORS section then reads "NONE" which is semantically fine but slightly misleading -- the section header says "strong candidates" and then the content is "NONE."

**Suggestion:** Strip "NONE" responses: `[ "$UNATTEMPTED" = "NONE" ] && UNATTEMPTED=""`.

---

## Nit

### 7. Trailing whitespace removed on line 244

The diff shows a trailing whitespace removal on the final line of the prompt (line 244). This is fine but is a cosmetic-only change mixed into a functional commit.

### 8. Comment says "already in completed-tasks.md, but summarize here too"

**Line 171.** The comment is helpful but slightly misleading -- the approved list is not just a summary of completed-tasks.md. It serves a different purpose: explicitly telling the LLM not to re-propose these ideas. The comment could be clearer about this intent.

---

## Summary

The change is well-structured and addresses a real problem (premature convergence due to lack of prior-round context). The jq queries are correct against the actual data structure. Shell quoting is safe -- no double-expansion risks.

The two most impactful issues to address are: (1) the `claude -p` call for unattempted-survivor detection could be replaced with deterministic text processing for better reliability and lower cost, and (2) the single-prior-round limitation should at minimum be documented in the prompt so the LLM knows the context is incomplete. The "unknown verdict treated as rejection" issue (finding #3) is a correctness bug that should be fixed before merging.

---

## Loop 2 Re-review

**Reviewed commit:** latest fix commit (deterministic extraction, conditional sections, literal newlines)
**Date:** 2026-03-24

### Prior findings status

All six prior findings were addressed:

1. **claude -p replaced with deterministic extraction** -- FIXED. Lines 197-229 now use `sed` to extract the Survivors section, `grep` to filter survivor lines, and kebab-case conversion + substring matching to compare against task IDs. No LLM call involved.

2. **Single-round limitation documented in prompt** -- FIXED. Lines 254-255 now include an explicit note: "This covers only the most recent round. See docs/working/completed-tasks.md for the complete history of all approved work across all rounds."

3. **Unknown verdict now skipped** -- FIXED. Line 186 changed from bare `else` to `elif [ "$VERDICT" = "rejected" ]`, with an explicit comment at line 193 explaining that unknown-verdict tasks are skipped.

4. **echo -e replaced with literal newlines** -- FIXED. Lines 184-191 build lists using actual newlines in the string (heredoc-style concatenation), eliminating `echo -e` entirely.

5. **Empty sections conditionally included** -- FIXED. Lines 234-249 now check each of `APPROVED_LIST`, `REJECTED_LIST`, and `UNATTEMPTED` independently, only appending the corresponding section header + content to `CONTEXT_SECTIONS` when non-empty.

6. **NONE stripping no longer relevant** -- N/A. The deterministic extraction starts with `UNATTEMPTED=""` and only appends when unmatched survivors are found. No "NONE" sentinel is ever produced.

### New issues introduced by the fixes

**Minor:**

**M1. Bidirectional substring matching can false-match on short names.** Line 219 checks `[[ "$EXISTING_TID" == *"$SURVIVOR_KEBAB"* ]] || [[ "$SURVIVOR_KEBAB" == *"$EXISTING_TID"* ]]`. If a survivor name produces a very short kebab string (e.g., a survivor named "Exit" -> kebab "exit"), it would match any task ID containing that substring (e.g., `workflow-exit-criteria`). With current data all survivor names are 2+ words and produce sufficiently specific kebab strings, so this is not a practical concern today. It could become one if future DD rounds produce terse survivor names.

**M2. Empty SURVIVOR_KEBAB matches everything.** If a survivor line is malformed (e.g., `- **#1 ** — desc` where the name is empty), `SURVIVOR_KEBAB` would be empty, and `[[ "$EXISTING_TID" == *""* ]]` is always true. The survivor would be incorrectly classified as matched (already a task) and excluded from the unattempted list. This is a silent data-loss edge case, though unlikely given the DD output format. A guard like `[ -z "$SURVIVOR_KEBAB" ] && continue` would make this explicit.

**Nit:**

**N1. Leading newline in list variables.** `APPROVED_LIST`, `REJECTED_LIST`, and `UNATTEMPTED` each start with a leading newline because the first concatenation appends to an empty string. For example, `APPROVED_LIST` ends up as `\n  - task-id: desc` rather than `  - task-id: desc`. This produces a blank line before the first item in each section. Functionally harmless but slightly untidy in the assembled prompt.

### Sed extraction robustness

The `sed -n '/^### Survivors$/,/^### /{...}'` pattern is correct for the current file structure. Verified against `feature-ideas-round-1.md`:
- `### Survivors` appears at line 96 as an exact heading match.
- `### Fixing weaknesses` follows at line 105, properly terminating the range.
- The `grep -E '^\- \*\*#[0-9]'` filter correctly picks up only the bullet-point survivor entries, ignoring blank lines or commentary within the section.
- If Survivors were the last `###` heading (no terminating heading), sed would read to EOF, but the grep filter would still only match survivor-format lines. So this is safe.
- The `|| true` on grep prevents set -e failures when no survivors match.

### Verdict

All prior findings addressed. Two minor new issues found (M1 and M2), neither blocking. The deterministic extraction is a clear improvement over the `claude -p` approach -- it is faster, cheaper, and deterministic. The kebab-case matching works correctly for the actual data and is robust against most realistic inputs.
