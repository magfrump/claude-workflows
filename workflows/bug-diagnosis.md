---
value_justification: "Structures the reproduce-isolate-fix loop to prevent shotgun debugging, reducing time spent on fixes that don't address root causes."
---

# Bug Diagnosis Workflow

## When to use
- Bug fixes where you already know the area of code involved
- Regressions where something that worked before now doesn't
- Bugs with observable symptoms (errors, wrong output, crashes)
- Any debugging task where rapid hypothesis-test iteration is more valuable than upfront research

This workflow is optimized for speed. Unlike RPI, there is **no plan approval gate** — debugging iterates rapidly between hypothesis and test. The goal is to shrink the problem space as fast as possible.

## When to pivot

- **→ RPI**: If you've tested 3+ hypotheses without progress, you likely don't understand the code well enough. Pivot to RPI's research phase — your failed hypotheses become valuable input (they document what the bug *isn't*). Use RPI for bugs in unfamiliar code where you need to build understanding before you can form good hypotheses.
- **→ Spike**: If the fix requires using an unfamiliar library or technique, spike it before implementing the fix.
- **← From RPI**: When RPI research reveals the root cause of a bug, you can skip straight to this workflow's Fix and Verify steps (steps 5-6) rather than writing a full implementation plan. RPI's research doc serves as the diagnosis record.

**Choosing between this workflow and RPI for bugs:** Use bug-diagnosis when you can point to the area of code that's likely broken. Use RPI when you can't — when the symptom is clear but the location is unknown, or when the code is unfamiliar enough that you need to build a mental model before debugging.

## Working documents

This workflow produces a lightweight diagnosis log rather than separate research and plan docs:

- `docs/working/diagnosis-{bug-description}.md` — records symptoms, hypotheses tested, and the root cause

These follow the same conventions as RPI working docs: committed to the repo, treated as disposable, collapsed in GitHub diffs via `linguist-generated`.

## Process

### 1. Reproduce — confirm the bug exists

Before diagnosing, confirm you can trigger the bug reliably. A bug you can't reproduce is a bug you can't verify as fixed.

- **Run the failing case**: Execute the test, request, or user action that triggers the bug. Record the exact error, wrong output, or unexpected behavior.
- **Identify the minimal trigger**: Strip away unrelated setup. What is the smallest input or sequence that produces the bug?
- **Check for flakiness**: Run it 2-3 times. If the bug is intermittent, note the frequency and any patterns (timing-dependent, order-dependent, environment-dependent).

If the bug can't be reproduced, document what you tried and escalate to the user — don't guess at fixes for phantom bugs.

#### Minimal reproduction

A good minimal reproduction:
- Uses the **fewest lines of code** or **simplest input** that triggers the bug
- Removes unrelated dependencies, configuration, and setup
- Can be run in isolation (ideally as a standalone test)
- Makes the failure **obvious** — assert on the wrong behavior, don't just print output

Write the minimal reproduction as a test if possible. This test becomes your verification that the fix works (step 6).

### 2. Isolate — narrow the search space

Reduce the problem space before forming hypotheses. Techniques, in rough order of usefulness:

- **Read the error**: Stack traces, error messages, and log output often point directly to the problem. Start here.
- **Git bisect**: If this is a regression (it worked before, it doesn't now), bisect to find the commit that broke it. This is the single most powerful isolation technique for regressions.
  ```bash
  git bisect start
  git bisect bad          # current commit is broken
  git bisect good <hash>  # known-good commit
  # bisect will check out commits for you to test
  git bisect run <test-command>  # automate if you have a quick test
  git bisect reset        # when done
  ```
- **Binary search by code**: Comment out or bypass half the relevant code path. Does the bug persist? Narrow to the half that matters. Repeat.
- **Simplify inputs**: If the bug involves complex data, reduce it. Remove fields, shorten strings, use minimal valid inputs until the bug disappears — the last thing you removed is relevant.
- **Check boundaries**: Recent changes, integration points, edge cases in input validation, off-by-one errors, null/empty handling.

The goal of isolation is to go from "something is wrong" to "the problem is in *this function* with *this input*."

### 3. Hypothesize — form a testable prediction

State a specific, falsifiable hypothesis:

- **Good**: "The `parseDate` function returns null when the input has a timezone offset, because the regex doesn't account for `+HH:MM`."
- **Bad**: "Something is wrong with date parsing."

**Example hypotheses by bug category:**

- **Regression**: "The `UserService.getById` query returns stale data because commit `a1b2c3d` switched from `findOne` to a cached lookup that doesn't invalidate on update." *Confirm*: bisect lands on that commit; reverting it fixes the issue. *Refute*: the cache is correctly invalidated and the stale data predates that commit.
- **Performance degradation**: "The `/api/reports` endpoint P95 latency doubled because `buildReport` issues N+1 queries after the `Report` model added an eager-loaded `comments` association." *Confirm*: profiling shows `buildReport` generating O(N) SQL queries; removing the eager load restores prior latency. *Refute*: query count is unchanged and the latency increase is elsewhere (e.g., serialization).
- **Intermittent failure**: "The `processQueue` worker test fails ~20% of runs because two jobs share a `tmp/output.csv` path and overwrite each other under concurrent execution." *Confirm*: running with `--parallel=1` eliminates the failure; adding per-job temp paths fixes it. *Refute*: the failure occurs even in serial execution, pointing to a different race condition or flaky assertion.

A good hypothesis:
- Names a **specific location** (function, line, module)
- Identifies a **specific mechanism** (what's going wrong and why)
- Predicts a **testable outcome** (if I do X, I should see Y)

Record the hypothesis in your diagnosis log. If you're past hypothesis #2, you should definitely be writing these down — debugging without records leads to testing the same thing twice.

### 4. Test — confirm or refute the hypothesis

Design the smallest experiment that distinguishes "hypothesis is correct" from "hypothesis is wrong":

- **Add a targeted assertion or log**: Confirm the value at the suspected point matches (or doesn't match) your prediction.
- **Write a focused test case**: A unit test that exercises the specific path your hypothesis identifies. This is often the minimal reproduction from step 1, refined.
- **Modify the suspect code**: If your hypothesis says "this condition is wrong," temporarily fix it and see if the bug disappears.

**Interpret the result:**
- **Hypothesis confirmed** → proceed to Fix (step 5).
- **Hypothesis refuted** → record what you learned, return to step 3 with a new hypothesis. The refutation narrows the search space — use it.
- **Result is ambiguous** → your test wasn't specific enough. Refine the experiment, don't form a new hypothesis yet.

**Escape hatch**: If you've tested 3+ hypotheses without confirming one, stop iterating and reassess:
- Are you isolating well enough? (Return to step 2)
- Do you understand the code well enough? (Pivot to RPI)
- Is the bug actually where you think it is? (Widen the search)

### 5. Fix — apply the minimal correct change

Once the root cause is confirmed:

- **Fix the root cause, not the symptom**. If the bug is a missing null check, ask *why* the value is null — fixing upstream may be more correct than adding a guard.
- **Keep the fix minimal**. Don't refactor surrounding code, don't "improve" nearby logic, don't fix other bugs you noticed. One fix per diagnosis.
- **Preserve existing behavior** for all non-buggy cases. If you're unsure whether your fix changes other behavior, write a characterization test first (see below).

#### Characterization tests

When fixing a bug in code with poor test coverage, write a **characterization test** before applying the fix:

1. Write tests that document the code's *current behavior* — including the buggy behavior.
2. Verify these tests pass (they capture what the code does now, bugs and all).
3. Apply your fix.
4. Update only the test assertions that correspond to the buggy behavior. All other assertions should still pass — if they don't, your fix changed more than intended.

Characterization tests are especially valuable when:
- The code has no existing tests
- The code has complex branching or side effects
- You're not confident about the blast radius of your change

### 6. Verify — confirm the fix and check for collateral damage

- **Run the reproduction from step 1**: It should now pass. If it doesn't, your fix is incomplete — return to step 5.
- **Run the full test suite**: Your fix should not break other tests. If it does, assess whether those tests were testing buggy behavior (update them) or whether your fix has unintended side effects (revise the fix).
- **Check edge cases**: Does your fix handle related edge cases, or did it only fix the specific case from the reproduction? Consider adding test cases for nearby boundaries.
- **Review the diagnosis log**: Update it with the confirmed root cause and the fix applied. This log is useful context for PR review and for future debugging if the bug recurs.

## Diagnosis log template

```markdown
# Diagnosis: {bug description}
Date: {YYYY-MM-DD}

## Symptom
[What's going wrong — error message, wrong output, crash, etc.]

## Reproduction
[Minimal steps or test case that triggers the bug]

## Hypotheses tested
| # | Hypothesis | Test | Result |
|---|-----------|------|--------|
| 1 | [specific claim] | [what you did] | [confirmed/refuted + what you learned] |

## Root cause
[What's actually wrong, confirmed by hypothesis #N]

## Fix
[What was changed and why this is the correct fix]
```

## When to skip or abbreviate

- **Obvious one-line bugs** (typo, wrong variable name, off-by-one): Fix directly, no diagnosis log needed.
- **Test failures with clear assertion messages**: The test *is* your reproduction and verification — skip steps 1 and 6.
- **Bugs found during RPI implementation**: If a bug surfaces while implementing a plan, fix it inline if trivial, or pause implementation and run this workflow if non-trivial. Record the diagnosis in a commit message rather than a separate doc.
