---
name: bug-diagnosis
description: >
  Run a rapid hypothesize-test-fix debugging loop inline during any workflow. Extracts the core
  diagnostic cycle from the bug-diagnosis workflow into a lightweight, invocable skill. Use when
  you hit unexpected behavior, a failing test, or a regression during implementation — without
  pivoting to a full workflow. Trigger phrases: "debug this", "why is this failing", "diagnose
  this bug", "hypothesis loop", "what's wrong here". Also trigger when a test fails unexpectedly
  during RPI implementation, when a code change produces wrong output, or when you need structured
  debugging within an existing workflow rather than switching to the full bug-diagnosis workflow.
when: >
  A bug, unexpected behavior, or test failure needs structured diagnosis inline — either standalone
  or mid-workflow. Use this skill instead of the full bug-diagnosis workflow when you're already in
  a workflow and don't want to pivot, or when the bug is small enough that a full workflow is
  overkill.
---

> On bad output, see guides/skill-recovery.md
> Full reference: workflows/bug-diagnosis.md — consult for detailed techniques (git bisect,
> characterization tests, when-to-pivot guidance).

# Bug Diagnosis Skill

You are running a structured hypothesis-test-fix loop to diagnose and fix a bug. This is the
core debugging cycle — rapid iteration between hypothesis and test, optimized for speed over
ceremony.

**When to escalate:** If you test 3+ hypotheses without progress, pivot to the full
bug-diagnosis workflow or RPI research phase. Your failed hypotheses become valuable input.

## Step 1: Reproduce

Confirm the bug exists and is reliable before diagnosing.

- Run the failing case. Record the exact error, wrong output, or unexpected behavior.
- Find the **minimal trigger** — the smallest input or sequence that produces the bug.
- Check for flakiness (run 2-3 times). If intermittent, note frequency and patterns.
- Write the minimal reproduction as a test if possible — it becomes your verification.

If the bug can't be reproduced, document what you tried and stop. Don't guess at fixes.

## Step 2: Isolate

Narrow the search space before forming hypotheses:

- **Read the error**: Stack traces and log output often point directly to the problem.
- **Binary search**: Comment out or bypass half the code path. Does the bug persist? Narrow.
- **Simplify inputs**: Reduce complex data until the bug disappears — the last removal is relevant.
- **Check boundaries**: Recent changes, integration points, edge cases, off-by-one, null handling.

Goal: go from "something is wrong" to "the problem is in *this function* with *this input*."

## Step 3: Hypothesize

State a **specific, falsifiable** hypothesis:

- **Good**: "The `parseDate` function returns null when input has a timezone offset, because
  the regex doesn't account for `+HH:MM`. [from error message]"
- **Bad**: "Something is wrong with date parsing."

A good hypothesis names a **specific location**, a **specific mechanism**, and predicts a
**testable outcome**.

### Tag the source

Every recorded hypothesis must carry one source tag indicating where the idea came from:

- `[from error message]` — derived directly from a stack trace, exception text, or assertion message
- `[from log analysis]` — derived from runtime/application/system logs or telemetry
- `[from code reading]` — derived from reading source code, control flow, or data structures
- `[from intuition]` — developer hunch or pattern recognition with no concrete evidence yet
- `[from prior bug]` — analogous to a previously-seen bug in this or a similar codebase

Why tag: provenance turns the hypothesis log into a dataset. Over time we can analyze which
sources actually produce confirmed root causes — and tune debugging guidance accordingly. An
`[from intuition]` hypothesis that gets refuted is still useful data; an untagged one is noise.

Record each hypothesis with its tag. After hypothesis #2, you must be writing these down.

## Step 4: Test

Design the smallest experiment that distinguishes "correct" from "wrong":

- Add a targeted assertion or log at the suspected point.
- Write a focused test case exercising the specific path.
- Temporarily fix the suspect code and see if the bug disappears.

**Interpret:**
- **Confirmed** → proceed to Fix (step 5).
- **Refuted** → record what you learned, return to step 3. The refutation narrows the space.
- **Ambiguous** → refine the experiment, don't form a new hypothesis yet.

**Escape hatch (3 failed hypotheses):** Stop and reassess. Are you isolating well enough?
Do you understand the code? Is the bug where you think it is? Consider pivoting to RPI.

## Step 5: Fix

- Fix the **root cause**, not the symptom. If a value is null, ask *why* — fixing upstream
  may be more correct than adding a guard.
- Keep the fix **minimal**. One fix per diagnosis. Don't refactor nearby code.
- Preserve existing behavior for all non-buggy cases.

## Step 6: Verify

- Run the reproduction from step 1 — it should now pass.
- Run the full test suite — no regressions.
- Check edge cases near the fix.

## Output Format

When documenting the diagnosis (in a commit message, PR description, or diagnosis log):

```
**Symptom:** [What went wrong]
**Hypotheses tested:** [N tested, which confirmed; include source tags so the
  confirmed-vs-refuted breakdown by provenance is preserved]
**Root cause:** [What was actually wrong]
**Fix:** [What was changed and why]
```

For non-trivial diagnoses, create `docs/working/diagnosis-{description}.md` using the full
template from workflows/bug-diagnosis.md.

## Tone

Direct and iterative. Each cycle should take minutes, not hours. Prefer fast experiments over
thorough analysis — you can always escalate to the full workflow if rapid iteration stalls.
