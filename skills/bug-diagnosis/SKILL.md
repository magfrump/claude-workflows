---
name: bug-diagnosis
description: >
  Run a rapid hypothesize-test-fix debugging loop inline during any workflow. Extracts the core
  diagnostic cycle from the bug-diagnosis workflow into a lightweight, invocable skill. Use when
  you hit unexpected behavior, a failing test, or a regression during implementation — without
  pivoting to a full workflow. Trigger phrases: "debug this", "why is this failing", "diagnose
  this bug", "hypothesis loop", "what's wrong here", "what's broken", "fix this error", "test is
  red", "this isn't working", "something's off", "trace this regression". Also trigger
  proactively whenever a test fails unexpectedly during RPI implementation, when a code change
  produces wrong output, when a stack trace appears, when a previously-passing build breaks,
  or when you need structured debugging within an existing workflow rather than pivoting away
  from it. This is the *skill* form — lightweight and inline. The standalone bug-diagnosis
  *workflow* is deprecated; the principles in CLAUDE.md's "Debugging defaults" apply, and this
  skill operationalizes them. Prefer this skill over ad-hoc debugging whenever a bug requires
  more than one guess to resolve.
when: >
  A bug, unexpected behavior, or test failure needs structured diagnosis inline — either
  standalone or mid-workflow. Use this skill whenever you would otherwise start guessing at
  fixes, or when one quick attempt has already failed.
---

> On bad output, see guides/skill-recovery.md
> Worked examples: guides/debugging-examples.md
> Deep reference (deprecated workflow, kept for techniques only): workflows/bug-diagnosis.md —
> consult for `git bisect`, characterization tests, and complex-bug templates.

# Bug Diagnosis Skill

You are running a structured hypothesis-test-fix loop to diagnose and fix a bug. This is the
core debugging cycle — rapid iteration between hypothesis and test, optimized for speed over
ceremony. The skill applies inside any workflow (RPI, spike, pr-prep) without pivoting away
from it.

**When to escalate:** If you test 3+ hypotheses without progress, pivot to RPI's research
phase. Your failed hypotheses are not wasted — they document what the bug *isn't* and narrow
the next investigation.

## Step 1: Reproduce

Confirm the bug exists and is reliable before diagnosing.

- Run the failing case. Record the exact error, wrong output, or unexpected behavior verbatim.
- Find the **minimal trigger** — the smallest input or sequence that produces the bug.
- Check for flakiness (run 2-3 times). If intermittent, note frequency and patterns; an
  intermittent bug often has a different shape than a deterministic one (race condition,
  ordering, state leak) and the hypotheses will differ.
- Write the minimal reproduction as a test if possible — it becomes your verification at step 6.

If the bug can't be reproduced, document what you tried and stop. Don't guess at fixes for a
bug you can't trigger — you have no way to know if the fix worked.

## Step 2: Isolate

Narrow the search space *before* forming hypotheses. Premature hypothesizing in a too-broad
space is the most common cause of the 3-hypothesis escape hatch firing.

- **Read the error first.** Stack traces, error messages, and log output frequently point
  directly to the problem. Spending two minutes reading is worth ten minutes of theorizing.
- **Binary search**: Comment out or bypass half the code path. Does the bug persist? Halve
  again. This is the fastest way to localize a bug whose location you can't infer.
- **Simplify inputs**: Reduce complex data until the bug disappears — the last removal is
  likely relevant.
- **Check boundaries**: Recent changes (`git log -p` on the affected files), integration
  points, edge cases, off-by-one, null/empty/timezone handling.

Goal: go from "something is wrong" to "the problem is in *this function* with *this input*."

## Step 3: Hypothesize

State a **specific, falsifiable** hypothesis. The shape matters more than the content — a
sloppy hypothesis produces a sloppy test that tells you nothing.

A good hypothesis names a **specific location**, a **specific mechanism**, and predicts a
**testable outcome**.

- **Good**: "The `parseDate` function returns null when input has a timezone offset, because
  the regex doesn't account for `+HH:MM`. If I pass `2025-01-01T00:00:00+05:00`, the test
  should fail; if I pass `2025-01-01T00:00:00Z`, it should pass."
- **Bad**: "Something is wrong with date parsing." (No location, no mechanism, no prediction.)

Record each hypothesis. After hypothesis #2, you **must** be writing these down — otherwise
the escape hatch won't fire reliably and you'll lose track of what you've already disproven.

## Step 4: Test

Design the smallest experiment that distinguishes "hypothesis correct" from "hypothesis wrong."

- Add a targeted assertion or log at the suspected point.
- Write a focused test case exercising the specific path.
- Temporarily patch the suspect code and see if the bug disappears.

### Interpret with the right verdict

Hypothesis verdicts are not optional vocabulary — they drive what happens next. Mis-classifying
a verdict will burn cycles or hide bugs.

- **CONFIRMED** — the experiment actually demonstrated the predicted outcome. Proceed to Fix.
- **REFUTED** — the experiment ran and produced a result inconsistent with the hypothesis.
  Record what you learned (the refutation narrows the space) and return to Step 3.
- **INCONCLUSIVE** — the experiment couldn't be run, the test setup didn't exercise the
  predicted path, the result was ambiguous, or you didn't actually test the claim. This is
  **not** the same as REFUTED. An untested hypothesis stays open; treating "never tried" as
  "tried and failed" will eliminate the actual cause from consideration.

If INCONCLUSIVE, refine the experiment — don't form a new hypothesis until the current one
is either CONFIRMED or REFUTED. Only REFUTED counts against the 3-hypothesis escape hatch.

### Escape hatch (3 REFUTED hypotheses)

Stop and reassess. Ask:

- Have I isolated well enough? (Most common cause of escape-hatch firing.)
- Do I understand the code, or am I theorizing from the outside?
- Is the bug actually where I think it is, or is the visible symptom downstream of the real
  cause?

Pivot to RPI's research phase. Carry your REFUTED hypotheses with you — they're evidence
about what the bug *isn't*.

## Step 5: Fix

- Fix the **root cause**, not the symptom. If a value is null, ask *why* — fixing upstream
  may be more correct than adding a defensive guard at the read site. Adding a guard when
  the upstream is the bug just moves the symptom.
- Keep the fix **minimal**. One fix per diagnosis. Don't refactor nearby code "while you're
  in there" — that mixes the fix with unrelated changes and makes the diagnosis log lie.
- Preserve existing behavior for all non-buggy cases. The reproduction should now pass; every
  other test should still pass.

## Step 6: Verify

- Run the reproduction from Step 1 — it should now pass.
- Run the full test suite — no regressions.
- Check adjacent edge cases near the fix (the same bug may exist in a sibling code path).

## Output Format

Always write a diagnosis log when more than one hypothesis was tested, or when the bug is
non-trivial. Save to `docs/reviews/bug-diagnosis.md` (or another location if the project
convention differs). For trivial single-hypothesis bugs, the inline commit-message summary
at the bottom of this section is sufficient.

The diagnosis log uses the following structure. Each tested hypothesis is a numbered section
with explicit fields, so the log doubles as a record of *what was disproven* if a future
debugger has to revisit the area.

```markdown
# Bug Diagnosis: <short description>

**Date:** <YYYY-MM-DD>
**Scope:** <file(s) or subsystem affected>

## Reproduction

<Exact command, input, or steps. Include the exact error/wrong output verbatim.>

## Hypotheses

### 1. <Short name>

**Statement:** <Specific, falsifiable claim — location, mechanism, predicted outcome>
**Test:** <The experiment you ran>
**Result:** <What actually happened>
**Verdict:** CONFIRMED | REFUTED | INCONCLUSIVE
**Confidence:** High | Medium | Low

### 2. <Short name>

**Statement:** ...
**Test:** ...
**Result:** ...
**Verdict:** ...
**Confidence:** ...

## Conclusion

**Root cause:** <What was actually wrong, and why>
**Fix:** <What was changed and why this addresses the root cause, not just the symptom>
**Verification:** <How you confirmed the fix; what tests cover it going forward>
```

For trivial bugs (single CONFIRMED hypothesis, obvious fix), a compact form in the commit
message is sufficient:

```
**Symptom:** <What went wrong>
**Hypotheses tested:** <N tested, which CONFIRMED>
**Root cause:** <What was actually wrong>
**Fix:** <What was changed and why>
```

## Tone

Direct and iterative. Each cycle should take minutes, not hours. Prefer fast experiments over
thorough analysis — you can always escalate to RPI if rapid iteration stalls. The diagnosis
log exists to make the reasoning auditable, not to slow it down: write it as you go, not at
the end.
