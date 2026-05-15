---
value-justification: "Retained as reference for the full diagnosis log template and detailed process. Core patterns (reproduce-first, hypothesis-test loop, 3-hypothesis escape hatch) have been absorbed into CLAUDE.md's Debugging defaults and now apply to all bug-fixing work automatically."
status: deprecated
---

# Bug Diagnosis Workflow

> **Deprecated.** The core patterns from this workflow (reproduce-first, hypothesis-test loop, 3-hypothesis escape hatch) have been absorbed into CLAUDE.md's "Debugging defaults" section and now apply to all bug-fixing work automatically. This file is retained as a reference for the full diagnosis log template and detailed process steps, but is no longer a standalone workflow entry in the decision tree.

## When to use
- Bug fixes where you already know the area of code involved
- Regressions where something that worked before now doesn't
- Bugs with observable symptoms (errors, wrong output, crashes)
- Any debugging task where rapid hypothesis-test iteration is more valuable than upfront research

This workflow is optimized for speed. Unlike RPI, there is **no plan approval gate** — debugging iterates rapidly between hypothesis and test. The goal is to shrink the problem space as fast as possible.

## When to pivot

- **→ RPI**: If you've tested 3+ hypotheses without progress, you likely don't understand the code well enough. Pivot to RPI's research phase — your failed hypotheses become valuable input (they document what the bug *isn't*). Before pivoting, emit the handoff doc described in step 5's "Handoff doc (required when escape hatch fires)" sub-section: `docs/working/handoff-diagnosis-{bug-description}.md` with a "What this bug isn't" section the next RPI research doc opens with verbatim. Use RPI for bugs in unfamiliar code where you need to build understanding before you can form good hypotheses.
- **→ Spike**: If the fix requires using an unfamiliar library or technique, spike it before implementing the fix.
- **← From RPI**: When RPI research reveals the root cause of a bug, you can skip straight to this workflow's Fix and Verify steps (steps 6-7) rather than writing a full implementation plan. RPI's research doc serves as the diagnosis record.

**Choosing between this workflow and RPI for bugs:** Use bug-diagnosis when you can point to the area of code that's likely broken. Use RPI when you can't — when the symptom is clear but the location is unknown, or when the code is unfamiliar enough that you need to build a mental model before debugging.

## Working documents

This workflow produces a lightweight diagnosis log rather than separate research and plan docs:

- `docs/working/diagnosis-{bug-description}.md` — records symptoms, hypotheses tested, and the root cause

These follow the same conventions as RPI working docs: committed to the repo, treated as disposable, collapsed in GitHub diffs via `linguist-generated`.

## Process

### 0. Pre-check — verify the failure isn't preexisting

Before forming a hypothesis, confirm the failure does not exist on the base branch unmodified. A failure that reproduces on a clean base isn't a bug *you* introduced — it's environmental, upstream, or a preexisting issue. Chasing it as part of your current work wastes effort and conflates root causes; fix or report it where it actually lives.

**Quick check:**
```bash
git stash
<repro-command>
git stash pop
```

Interpret the result:
- **Failure does not reproduce on the clean base** → the failure is specific to your current changes; proceed to step 1.
- **Failure reproduces on the clean base** → it's environmental or upstream. Stop diagnosing it as part of your current work. Examples: a flaky test on `main`, a broken dependency version, a misconfigured local environment, a regression introduced by an upstream merge. Fix it in its real location or escalate it as a separate issue.

If your working changes can't easily be stashed (large schema migrations, untracked build artifacts, in-progress refactors that span many files), use `git worktree add` to check out the base branch in a separate directory and run the reproduction there instead.

**Done when...**
- [ ] The reproduction has been run on the unmodified base branch (via stash or worktree)
- [ ] If the failure reproduces on the base, it has been escalated as environmental/upstream and is not being treated as part of the current work
- [ ] If the failure does not reproduce on the base, it is confirmed to be specific to current changes — proceed to step 1

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

Write the minimal reproduction as a test if possible. This test becomes your verification that the fix works (step 7).

**Done when...**
- [ ] The bug can be triggered reliably with a specific, documented sequence
- [ ] The exact error, wrong output, or unexpected behavior is recorded
- [ ] A minimal reproduction exists (ideally as a failing test)
- [ ] If the bug is intermittent, the frequency and any patterns are noted
- [ ] If the bug cannot be reproduced, this is documented and escalated — do not proceed to step 2

### 2. Check prior patterns — search the failure-pattern library

Before forming a hypothesis, grep `docs/thoughts/failure-patterns.md` for the symptom signature from step 1. The library is an append-only one-line log of root-caused bugs (schema documented in the file's header). A match is a strong prior: a past bug with the same observable signature often has the same cause, and the recorded fix shape narrows what to test first. Skipping this step is how the library becomes write-only.

**How to search:**

```bash
# By keyword drawn from the error message or observed behavior:
grep -i '<keyword>' docs/thoughts/failure-patterns.md

# By suspected cause category, if you already have one in mind:
grep 'cause:<category>' docs/thoughts/failure-patterns.md
```

Try several keyword angles — the exact symptom phrasing rarely matches verbatim, but root tokens (e.g., `null`, `timezone`, `n+1`, `race`, `stale`, `boundary`) often will. Search recipes are documented in the failure-patterns.md header.

**Interpret the result:**

- **One or more matches** → record the matched IDs in your diagnosis log. When a hypothesis derives from a matched pattern, tag it `[from prior bug FP-NNN]` in step 4 so the prior is traceable. The matched fix shape is often the first thing to test.
- **No matches** → proceed normally; the bug is novel relative to the library. Step 8 (Record the pattern) will add a new entry once you've root-caused it.
- **File does not exist yet** → this is the first-ever diagnosis to consult it. Note the absence in your diagnosis log and let step 8 bootstrap the file from the schema.

The library is intentionally lossy — only root-caused bugs get appended (see step 8). Absence of a match does not prove the bug is novel; it may just be unrecorded. But a match is meaningful signal and should not be ignored.

**Done when...**
- [ ] `docs/thoughts/failure-patterns.md` has been grep'd for terms drawn from the symptom (or noted as absent if the file does not exist)
- [ ] Any matched pattern IDs are recorded in the diagnosis log
- [ ] If a pattern matched, its recorded fix shape has been considered as a candidate starting point for hypothesis formation

### 3. Isolate — narrow the search space

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

**Done when...**
- [ ] The problem is narrowed to a specific function, module, or code path
- [ ] The input or condition that triggers the bug within that location is identified
- [ ] At least one isolation technique was applied (error reading, bisect, binary search, input simplification, or boundary check)

### 4. Hypothesize — form a testable prediction

State a specific, falsifiable hypothesis:

- **Good**: "The `parseDate` function returns null when the input has a timezone offset, because the regex doesn't account for `+HH:MM`."
- **Bad**: "Something is wrong with date parsing."

**Example hypotheses by bug category:**

- **Regression** *[from prior bug]*: "The `UserService.getById` query returns stale data because commit `a1b2c3d` switched from `findOne` to a cached lookup that doesn't invalidate on update." *Confirm*: bisect lands on that commit; reverting it fixes the issue. *Refute*: the cache is correctly invalidated and the stale data predates that commit.
- **Performance degradation** *[from log analysis]*: "The `/api/reports` endpoint P95 latency doubled because `buildReport` issues N+1 queries after the `Report` model added an eager-loaded `comments` association." *Confirm*: profiling shows `buildReport` generating O(N) SQL queries; removing the eager load restores prior latency. *Refute*: query count is unchanged and the latency increase is elsewhere (e.g., serialization).
- **Intermittent failure** *[from code reading]*: "The `processQueue` worker test fails ~20% of runs because two jobs share a `tmp/output.csv` path and overwrite each other under concurrent execution." *Confirm*: running with `--parallel=1` eliminates the failure; adding per-job temp paths fixes it. *Refute*: the failure occurs even in serial execution, pointing to a different race condition or flaky assertion.

A good hypothesis:
- Names a **specific location** (function, line, module)
- Identifies a **specific mechanism** (what's going wrong and why)
- Predicts a **testable outcome** (if I do X, I should see Y)
- Carries exactly one **source tag** from the taxonomy below

#### Source tag

Every recorded hypothesis must carry exactly one inline tag from the following taxonomy, naming the kind of evidence that produced it. The source is a strong prior on the hypothesis's likelihood of being correct, and the mix of sources across hypotheses is a useful diagnostic when invoking the 3-hypothesis escape hatch (step 5) — three intuition-tagged misses signal a different kind of stuckness than three error-message-tagged misses.

- **`[from error message]`** — Derived from the exception text, status code, panic, or error string itself. *Strongest signal*: the error usually names the proximal failure. Default starting point whenever an error is in hand.
- **`[from log analysis]`** — Derived from log lines, traces, metrics, telemetry, or surrounding output that is distinct from the error itself. *Strong but more interpretive* — log evidence is suggestive rather than definitive, and correlation/causation confusion is common.
- **`[from code reading]`** — Derived from reading the relevant source and reasoning about its control or data flow (e.g., spotting a missing null check on the function on the stack trace). *Strong when the suspect path is small* and on the trace; weaker as the surface grows or as you reason further from the failure point.
- **`[from intuition]`** — Pattern-matching from prior debugging experience without a concrete signal in hand ("this kind of bug usually means X"). *Cheapest to form, most likely to be wrong*. Useful as a tiebreaker or when stronger sources are exhausted, but deprioritize when error-message, log, or code evidence is available.
- **`[from prior bug]`** — Derived from a similar past bug, an entry in a known-issues / bug graveyard log, or institutional memory ("we hit this exact thing in module X last quarter"). *Strong when the prior bug is well-documented and the analogy is tight*; weak when the analogy is loose or the original was never root-caused. When the prior is a pattern from `docs/thoughts/failure-patterns.md` (i.e., it came out of step 2), cite the pattern ID directly: `[from prior bug FP-NNN]`. The recorded fix shape is the natural first thing to test.

Place the tag inline at the start of the hypothesis statement (e.g., `[from error message] parseDate returns null when the input has a timezone offset...`). When two sources jointly produced the hypothesis, pick the one that did the most work — the tag names the dominant evidence, not every piece that contributed. If you genuinely can't pick a single source, that's a signal the hypothesis is too vague: tighten it before testing.

Record the hypothesis in your diagnosis log. If you're past hypothesis #2, you should definitely be writing these down — debugging without records leads to testing the same thing twice.

**Done when...**
- [ ] The hypothesis names a specific location (function, line, module)
- [ ] The hypothesis identifies a specific mechanism (what's going wrong and why)
- [ ] The hypothesis predicts a testable outcome (if I do X, I should see Y)
- [ ] The hypothesis carries exactly one source tag from the taxonomy (`[from error message]` / `[from log analysis]` / `[from code reading]` / `[from intuition]` / `[from prior bug]`)
- [ ] The hypothesis is recorded in the diagnosis log (with its source tag)

### 5. Test — confirm or refute the hypothesis

Design the smallest experiment that distinguishes "hypothesis is correct" from "hypothesis is wrong":

- **Add a targeted assertion or log**: Confirm the value at the suspected point matches (or doesn't match) your prediction.
- **Write a focused test case**: A unit test that exercises the specific path your hypothesis identifies. This is often the minimal reproduction from step 1, refined.
- **Modify the suspect code**: If your hypothesis says "this condition is wrong," temporarily fix it and see if the bug disappears.

**Interpret the result — every hypothesis ends in exactly one of three states:**

- **CONFIRMED** — the experiment ran, the precondition was met, and the predicted outcome occurred. → Proceed to Fix (step 6).
- **REFUTED** — a designed experiment ran, the precondition was met, and the predicted outcome did *not* occur. The hypothesis has been falsified. → Record what you learned and return to step 4 with a new hypothesis. The refutation narrows the search space — use it.
- **INCONCLUSIVE** — the experiment did not actually distinguish the hypothesis. Includes: no experiment was designed or executed; the precondition was never met (the suspect path was never exercised, the feature flag was off, the input never reached the branch); the experiment ran but was not specific enough to confirm or refute. → Redesign the experiment so it actually tests the hypothesis, or discard the hypothesis as untestable and form a new one.

**Default state**: every hypothesis is INCONCLUSIVE until a designed experiment with met preconditions either confirms or refutes it. REFUTED is reserved for genuinely falsified hypotheses — "never tried" is not the same as "tried and failed," and conflating the two inflates the apparent failure rate and feeds misleading signal back into the next hypothesis.

**Escape hatch**: If you've **REFUTED** 3+ hypotheses without confirming one, stop iterating and reassess. INCONCLUSIVE hypotheses do *not* tick this counter — the search space has not actually narrowed when an experiment failed to test what it claimed to test. If you're accumulating INCONCLUSIVE results, the problem is experimental design, not exhausted hypothesis space; fix the experiment before counting the hypothesis as a failure. Reassessment questions:
- Are you isolating well enough? (Return to step 3)
- Do you understand the code well enough? (Pivot to RPI — see "Handoff doc" below)
- Is the bug actually where you think it is? (Widen the search)

#### Handoff doc (required when escape hatch fires and you're pivoting to RPI)

When the escape hatch fires *and* the chosen reassessment is "pivot to RPI" (the most common outcome), emit a structured handoff doc at `docs/working/handoff-diagnosis-{bug-description}.md` *before* opening the RPI research doc. The handoff is what carries refuted-hypothesis evidence across the workflow boundary — without it, three rounds of falsification work get re-derived from scratch, or worse, the next session re-tests one of the same hypotheses.

The handoff is a **derivation** of the diagnosis log (the hypothesis table is already there), reframed for an RPI reader. The framing flip is the load-bearing move: "hypotheses we tested" → "things this bug isn't." That reframing turns falsification work into a narrowed search space the research phase can start from rather than a list of past attempts.

**Content rules:**

- Include only **REFUTED** hypotheses. INCONCLUSIVE ones did not eliminate anything from the search space, so they don't belong in "what this bug isn't" — list them under "Open / untested" instead so the next session knows they're unresolved.
- For each refuted hypothesis, one entry with two lines: `tested:` (the prediction the experiment ran — what would have been true if the hypothesis held) and `learned:` (the region of the search space the refutation eliminates — phrased as a negative claim about the bug, not as a verdict on the hypothesis).
- Keep entries short. Each `tested:` / `learned:` pair is 1-2 sentences.
- Reference the source diagnosis log so a deeper reader can recover the full experiment.

**Template:**

```markdown
# Handoff: bug-diagnosis → RPI for {bug description}
Date: {YYYY-MM-DD}
Diagnosis log: docs/working/diagnosis-{bug-description}.md
Reason for pivot: escape hatch fired after N refuted hypotheses

## What this bug isn't

The following hypotheses were tested and refuted. Each entry names a region of
the search space that the RPI research phase does not need to re-examine.

1. **Not: {one-line negative claim about the bug}**
   - tested: {what the experiment predicted would happen if the hypothesis held}
   - learned: {what the refutation lets us say the bug is not — phrased as a constraint on where to look next}
   - ref: hypothesis #{N} in diagnosis log

2. **Not: {...}**
   - tested: {...}
   - learned: {...}
   - ref: hypothesis #{N} in diagnosis log

3. **Not: {...}**
   - tested: {...}
   - learned: {...}
   - ref: hypothesis #{N} in diagnosis log

## Open / untested

[INCONCLUSIVE hypotheses from the diagnosis log, plus regions of the code
the diagnosis never reached. These are starting points for RPI research,
not eliminated regions.]

## Instruction to the next RPI research doc

The RPI research doc for this bug must open with the "What this bug isn't"
section copied verbatim from this handoff. The refutation work was expensive;
preserving it as the opening of research is what makes the pivot pay off.
After that section, proceed with RPI research as normal: What exists,
Invariants, Prior art, Gotchas.
```

**Worked example.** A bug-diagnosis loop investigating "PDF export occasionally produces blank pages" tested three hypotheses, all refuted: (a) the PDF library was returning null for certain glyphs, (b) a font cache was being evicted mid-render, (c) the worker was timing out on large jobs. The handoff doc's "What this bug isn't" section reads:

> 1. **Not: a glyph-rendering null in the PDF library** — tested: corrupt or missing glyphs in the input would surface as `RenderError` in logs. learned: logs show clean render completion on every blank-page job, so the bug is not in glyph rendering. ref: hypothesis #1.
> 2. **Not: font-cache eviction during render** — tested: pinning the font cache to never evict would eliminate the blank pages. learned: blank pages still occur with the cache pinned, so the bug is not cache-related. ref: hypothesis #2.
> 3. **Not: worker timeout on large jobs** — tested: blank pages would correlate with job size > 10MB. learned: blank pages occur on small jobs too (median 1.2MB), so the bug is not timeout-related. ref: hypothesis #3.

The "Open / untested" section then points RPI research at the rendering pipeline downstream of glyph emission — the region the three refutations have collectively narrowed to.

**Done when...**
- [ ] The hypothesis state is recorded as exactly one of CONFIRMED, REFUTED, or INCONCLUSIVE
- [ ] CONFIRMED → proceed to step 6
- [ ] REFUTED → the refutation explicitly narrows the search space, and a new hypothesis is formed (return to step 4)
- [ ] INCONCLUSIVE → the experiment is redesigned to actually test the hypothesis (precondition met, prediction specific enough), or the hypothesis is discarded as untestable. INCONCLUSIVE results are *not* counted toward the escape hatch
- [ ] The test result, the hypothesis state, and what was learned are recorded in the diagnosis log
- [ ] If 3+ hypotheses have been **REFUTED** (INCONCLUSIVE ones do not count), the escape hatch has been evaluated (re-isolate, pivot to RPI, or widen search)
- [ ] If the escape hatch fired and the chosen reassessment is "pivot to RPI", the handoff doc has been emitted at `docs/working/handoff-diagnosis-{bug-description}.md` per the "Handoff doc" sub-section: one "Not: ..." entry per refuted hypothesis with `tested:` / `learned:` / `ref:` lines, an "Open / untested" section for inconclusive hypotheses and unexamined regions, and the verbatim instruction that the next RPI research doc must open with the "What this bug isn't" section copied across
- [ ] The subsequent RPI research doc (if started in the same session) opens with the handoff's "What this bug isn't" section copied verbatim, before its standard body sections (What exists, Invariants, Prior art, Gotchas)

### 6. Fix — apply the minimal correct change

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

**Done when...**
- [ ] The fix addresses the root cause, not just the symptom
- [ ] The change is minimal — no unrelated refactoring, improvements, or other bug fixes included
- [ ] If the code had poor test coverage, characterization tests were written before applying the fix
- [ ] The fix is committed separately from any characterization tests

### 7. Verify — confirm the fix and check for collateral damage

- **Run the reproduction from step 1**: It should now pass. If it doesn't, your fix is incomplete — return to step 6.
- **Run the full test suite**: Your fix should not break other tests. If it does, assess whether those tests were testing buggy behavior (update them) or whether your fix has unintended side effects (revise the fix).
- **Check edge cases**: Does your fix handle related edge cases, or did it only fix the specific case from the reproduction? Consider adding test cases for nearby boundaries.
- **Review the diagnosis log**: Update it with the confirmed root cause and the fix applied. This log is useful context for PR review and for future debugging if the bug recurs.

**Done when...**
- [ ] The reproduction from step 1 now passes
- [ ] The full test suite passes with no new failures
- [ ] Edge cases related to the fix have been considered (and test cases added if warranted)
- [ ] The diagnosis log is updated with the confirmed root cause and the fix applied

### 8. Record the pattern — append to the failure-pattern library

Once the fix is verified, append a one-line entry to `docs/thoughts/failure-patterns.md` capturing the {symptom, cause, fix} signature of this diagnosis. The library is a write-and-read tool — step 2 of every future diagnosis greps it. Records that aren't written don't help anyone; this step is what keeps step 2 from being write-only.

**Format** (the full schema lives in the failure-patterns.md header — read it before your first entry):

    - **FP-NNN** YYYY-MM-DD symptom:<keywords> cause:<category> fix:<category> ref:<diagnosis-doc-or-commit>

Pick the next sequential `FP-NNN` (zero-padded to 3 digits) — look at the last entry in the file. Choose `symptom` keywords a future grep would actually try (root tokens from the error message and observable behavior, e.g., `null`, `timezone`, `n+1`, `race`, `stale`, plus a discriminator that ties them to this bug). Choose `cause` and `fix` categories from the starter vocabularies in failure-patterns.md, and only invent a new category when none fit — in which case add it to the vocabulary in the same commit so the next diagnosis can reuse it.

**Examples:**

    - **FP-001** 2026-05-13 symptom:null-from-parseDate-tz-offset cause:incomplete-regex fix:extend-regex ref:docs/working/diagnosis-date-parsing.md
    - **FP-002** 2026-05-14 symptom:p95-doubled-reports-endpoint-eager-comments cause:n+1-query fix:remove-eager-load ref:docs/working/diagnosis-reports-perf.md

**Skip pattern recording when:**

- The diagnosis was abbreviated (obvious one-line bug — see "When to skip or abbreviate" below). Trivial typos and one-character fixes do not yield reusable {symptom, cause, fix} signatures.
- The bug was confirmed environmental/upstream in step 0 (it was never your bug). Record it in the upstream project's tracker, not your library.
- A matched pattern from step 2 was an exact recurrence with the same root cause and the same fix. In that case, don't add a duplicate — instead, leave a one-line note in your diagnosis log citing the matched `FP-NNN`, and (optionally) edit the matched entry's `ref` to point to the more recent diagnosis if it documents the recurrence better.

**Done when...**
- [ ] A new line has been appended to `docs/thoughts/failure-patterns.md` using the schema in the file header — this is the default outcome of step 8 and the only way the library grows
- [ ] If — and only if — one of the explicit skip conditions above applies, the diagnosis log names which skip condition (trivial bug / environmental-upstream / exact recurrence of FP-NNN) and why it applies. A bare "skipped" without a named condition is not acceptable; the default is to append
- [ ] The new entry's `symptom` keywords are tokens a future bug-diagnosis would plausibly grep — not full sentences, not bug-specific identifiers
- [ ] The new entry's `cause` and `fix` fields reuse existing vocabulary, or introduce a new category that is also added to the vocabulary section of failure-patterns.md in the same commit
- [ ] The `ref` field points to the diagnosis log or fix commit so future readers can find the full reasoning
- [ ] If step 2 matched a prior pattern, the new entry's relationship to it is noted in the diagnosis log (recurrence with same cause+fix → no new entry; same symptom but different cause → new entry, cite the near-miss `FP-NNN` for contrast)

## Diagnosis log template

```markdown
# Diagnosis: {bug description}
Date: {YYYY-MM-DD}

## Symptom
[What's going wrong — error message, wrong output, crash, etc.]

## Reproduction
[Minimal steps or test case that triggers the bug]

## Prior patterns matched (step 2)
[List matched pattern IDs from docs/thoughts/failure-patterns.md, or "none" if no match. Cite as FP-NNN. If a match drove a hypothesis, that hypothesis should carry the tag [from prior bug FP-NNN] below.]

## Hypotheses tested
| # | Source | Hypothesis | Test | State | Notes |
|---|--------|-----------|------|-------|-------|
| 1 | [from error message \| from log analysis \| from code reading \| from intuition \| from prior bug \| from prior bug FP-NNN] | [specific claim] | [experiment designed and run, or "not yet tested"] | [CONFIRMED \| REFUTED \| INCONCLUSIVE — default INCONCLUSIVE if no experiment ran or precondition unmet] | [what you learned; for INCONCLUSIVE, why the experiment didn't distinguish] |

**State rules**: Use REFUTED only when a designed experiment ran with its precondition met and falsified the prediction. Use INCONCLUSIVE when no experiment ran, the precondition was never met, or the test wasn't specific enough to confirm or refute. Only REFUTED hypotheses count toward the 3-hypothesis escape hatch in step 5.

## Root cause
[What's actually wrong, confirmed by hypothesis #N]

## Fix
[What was changed and why this is the correct fix]

## Pattern recorded (step 8)
[The one-line entry appended to docs/thoughts/failure-patterns.md, e.g.:
`- **FP-042** 2026-05-13 symptom:<keywords> cause:<category> fix:<category> ref:<this-doc-or-commit>`
Or note "skip — trivial bug" / "skip — recurrence of FP-NNN, no new entry".]
```

## When to skip or abbreviate

- **Obvious one-line bugs** (typo, wrong variable name): Fix directly, no diagnosis log or pattern entry needed. Trivial typos do not yield reusable {symptom, cause, fix} signatures, so step 8 is a no-op.
- **Test failures with clear assertion messages**: The test *is* your reproduction and verification — skip steps 1 and 7. Still run step 2 (a one-second `grep` is cheap and may save iteration), and still run step 8 if the bug had a non-trivial cause.
- **Bugs found during RPI implementation**: If a bug surfaces while implementing a plan, fix it inline if trivial, or pause implementation and run this workflow if non-trivial. Record the diagnosis in a commit message rather than a separate doc, and still append to `docs/thoughts/failure-patterns.md` if the cause is reusable — point the `ref` field at the commit SHA.
