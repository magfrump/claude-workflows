# Draft Review: Prior-Round Context for Idea Generation

**Commit:** 7ab4b9e (fix/round2-idea-generation-context)
**Reviewed:** 2026-03-24
**Status:** CONDITIONAL PASS

## Problem Statement

Round 2 idea generation prematurely returned "DONE" (no more good ideas) because the prompt lacked context about what happened in round 1. The agent saw ~80 prior ideas in the archive and concluded the idea space was exhausted, despite 2 of 3 round-1 tasks being rejected and several DD survivors never being attempted.

Evidence from `round-history.json`: round 2 recorded `"ideas": {"generated": false, "count": 0}` and `"outcome": "exhausted"` after round 1 approved only 1 of 3 tasks.

## Does This Solve the Stated Problem?

**Mostly yes.** The change addresses the root cause directly: the idea generation prompt now explicitly tells the agent what was approved (off-limits), what was rejected (re-attempt encouraged), and what survived DD but was never attempted (strong candidates). It also redefines the "at least 3 new ideas" threshold to count re-attempts and unattempted survivors.

**Remaining gap:** The context only covers the immediately prior round (`PREV=$((ROUND - 1))`), not all prior rounds. If round 1 rejects task A, round 2 re-attempts and also rejects task A, round 3 will only see round 2's rejection. It will not see the full history of attempts. For the current MAX_ROUNDS=5 this is probably fine, but it means cumulative learning across multiple failed re-attempts is limited.

## Is the Approach Proportional?

**The approved/rejected logic (lines 172-193) is proportional.** It uses existing data (`round-history.json` and `tasks-round-N.json`) with straightforward jq queries. No new files, no new dependencies. The information is formatted as a simple text block injected into the prompt.

**The unattempted survivors detection (lines 198-206) is disproportionate.** It invokes `claude -p` to do fuzzy matching between the ideas file and the tasks file. This is a full LLM call to answer a question that could be answered deterministically: compare the list of DD survivor idea names against task IDs/descriptions. The cost is:

- An additional API call per round (latency + tokens)
- Non-deterministic output (the LLM might misidentify which ideas became tasks)
- A failure mode where `claude -p` produces unexpected output that silently becomes part of the prompt

The DD survivors are already structured (section headers in the ideas file, task IDs in the JSON). A deterministic approach (grep or jq matching) would be more reliable and faster.

## Simpler Alternatives

1. **Skip unattempted survivor detection entirely.** The rejected-tasks list already gives the agent enough signal to avoid premature convergence. The agent can read the prior round's ideas file directly (it's already told to `Review docs/working/completed-tasks.md`). Simply telling the agent "round N-1 rejected these tasks; consider re-attempting them or proposing new ideas" might suffice without enumerating unattempted survivors.

2. **Deterministic survivor extraction.** Instead of calling `claude -p`, grep the survivors section of the ideas file and diff against task IDs. The survivors section has a predictable format (`- **#N Name** -- description`). This avoids the LLM call entirely.

3. **Pass the raw files as context.** Instead of summarizing, tell the agent to read `tasks-round-N.json` and `feature-ideas-round-N.md` directly. The agent already reads `completed-tasks.md`; adding two more files is minimal overhead and avoids all the shell processing.

## What Could Go Wrong in Practice

1. **jq query for verdict may return unexpected values.** The query `.validation[$tid].verdict` assumes the round-history entry has a `verdict` field per task. Looking at the actual data, the verdict is stored as `.validation[$tid].verdict` = `"rejected"` or `"approved"`. But if a task was launched but never completed (e.g., the worktree creation failed at line 387), it won't have a validation entry at all. The `// "unknown"` fallback handles this, but such tasks would land in the "rejected" list even though they were never evaluated.

2. **`echo -e` portability.** Lines 214-215 use `echo -e "$APPROVED_LIST"` to interpret `\n` escape sequences. The script uses `#!/bin/bash` (not `#!/bin/sh`), so this works on most Linux systems, but `echo -e` behavior varies across bash versions and configurations. Using `printf '%b'` would be more portable.

3. **Empty sections in the prompt.** If `APPROVED_LIST` is empty but `REJECTED_LIST` has content, the prompt will contain `APPROVED (already implemented, do not re-propose):` followed by nothing, then the rejected section. This is cosmetic but could confuse the downstream LLM. Similarly, if `UNATTEMPTED` is "NONE" (the expected output when all survivors became tasks), the prompt will say "UNATTEMPTED SURVIVORS: NONE" which is fine, but if the claude call fails silently, `UNATTEMPTED` will be empty and the section header will dangle.

4. **The `claude -p` call for unattempted survivors has no timeout.** If the LLM hangs or takes a long time, it blocks the entire self-improvement loop with no feedback. The `|| UNATTEMPTED=""` fallback only catches exit-code failures, not hangs.

5. **Only looks at round N-1, not all prior rounds.** A task rejected in round 1, re-attempted and rejected again in round 2, would only show round 2's rejection in round 3's context. The agent might not know the task has been attempted twice and might not account for why it failed both times.

## What's Missing

1. **No test coverage.** The self-improvement loop is the hardest part of this codebase to test, but the jq queries and the conditional logic could be tested with mock data. At minimum, a smoke test that runs Step 0b with a known `round-history.json` and `tasks-round-1.json` and checks the output would catch regressions.

2. **No logging of what context was injected.** The round log (`update_round_log`) does not record that prior-round context was built or what it contained. If the context injection causes unexpected behavior in idea generation, there's no way to diagnose what was passed to the prompt without re-running the script.

3. **The `FAIL_GATE` extraction (line 188-190) assumes exactly one gate failed.** The `head -1` picks the first failed gate, but tasks can fail multiple gates (though the current validation logic short-circuits on first failure, so in practice there is typically only one). If validation logic changes to continue checking after a failure, this would show incomplete information.

## Verification Rubric

Before merging, manually verify or test the following:

### Must-check (blocking)

- [ ] **jq queries return expected values against real data.** Run the verdict query against the actual `round-history.json` and `tasks-round-1.json` from the last run. Confirm `failure-incident-journal` shows as "approved" and `workflow-exit-criteria`/`workflow-onboarding-tiers` show as "rejected" with correct fail gates (`self_eval`).
- [ ] **PRIOR_CONTEXT is non-empty for round 2.** Manually simulate (or add an `echo "$PRIOR_CONTEXT"` debug line) to confirm the assembled context block contains the expected approved/rejected/unattempted sections.
- [ ] **The modified prompt (lines 232-244) is syntactically correct.** Verify that `${PRIOR_CONTEXT}` expands correctly inside the heredoc-style string, including when PRIOR_CONTEXT is empty (round 1) and when it contains newlines and special characters.

### Should-check (non-blocking but recommended)

- [ ] **The `claude -p` call for unattempted survivors produces stable output.** Run it manually against `feature-ideas-round-1.md` and `tasks-round-1.json`. Check that it correctly identifies survivors #1 (parallel exploration), #4 (pattern extraction), and #6 (skill invocation recipes) as unattempted.
- [ ] **Round 1 is unaffected.** Confirm that `PRIOR_CONTEXT` remains empty when `ROUND=1` and the idea generation prompt is unchanged from the pre-patch behavior.
- [ ] **Empty-state behavior.** What happens if `round-history.json` exists but the previous round's entry has no `validation` key (e.g., it was an "exhausted" round like round 2 currently is)? The jq queries should return empty/unknown rather than erroring.

### Nice-to-have (future improvement)

- [ ] Replace the `claude -p` unattempted-survivor call with deterministic text extraction.
- [ ] Add `PRIOR_CONTEXT` summary to the round log for debuggability.
- [ ] Consider accumulating context from all prior rounds, not just the immediately preceding one.
