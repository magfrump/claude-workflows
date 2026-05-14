# Plan: Add 'failure modes introduced' check to skills/code-review.md

## Goal

Add a structural, forward-looking check that names 3 failure modes the diff introduces
across data validation, error handling, state corruption, and performance degradation.
The check is scoped to non-trivial behavior-adding diffs and is distinct from
security-reviewer's trust-boundary focus.

## Design decisions

### Placement: Stage 3 synthesis-time check, not a sub-agent

Reasoning:
- The check is meta-analytical: it projects forward from critic findings to
  failure-mode space, rather than re-analyzing the code from scratch.
- Sibling synthesis-time activities (goal-alignment scan, considered-overrides
  scan, convergence detection) already live in Stage 3 and are orchestrator-run.
- Dispatching a sub-agent would require re-pasting all critic output as context,
  which is redundant when the orchestrator already holds it.
- Honoring file-scope constraint (only `skills/code-review.md` may change) means
  no new skill file is created.

### Trigger

The check fires when **both** are true:

1. **Line-count threshold:** the diff adds more than 50 lines of new behavior
   (defined as `added - deleted` from `git diff --shortstat`, since pure refactors
   typically have added ≈ deleted).
2. **Not refactor-only:** the branch is not a pure refactor. Signals that mark a
   diff refactor-only:
   - All commits on the branch use a `refactor:` / `chore:` / `style:` conventional
     prefix.
   - OR the PR title explicitly says "refactor", "rename", "move", "extract".
   - OR `git diff --shortstat` shows added/deleted within 20% of each other AND
     no new public exports were added.

If either condition fails, the check is **skipped with a recorded reason**.

### What the check produces

When triggered, the orchestrator names exactly 3 failure modes the diff introduces.
Each failure mode:
- Names a **category** drawn from: data validation, error handling, state corruption,
  performance degradation. At least 3 of the 4 categories must be covered across the
  3 modes (so a single category cannot dominate).
- Cites a **location** in the diff (`path/to/file:line`).
- States a concrete **scenario** — what input, state, or load triggers the failure.

The check is *forward-looking*: it projects what could go wrong with the new code
in production, not what static review already caught. Findings already raised by
critics are not restated as failure modes — the check fills the *gap between*
critic findings and unknown unknowns.

### Security-reviewer integration

If security-reviewer ran in Stage 2 and produced findings, those findings are
loaded as **input context** for the failure-mode check. The orchestrator reads
them and uses them as priors:
- A security finding about input handling sharpens the data-validation projection.
- A security finding about trust boundaries sharpens the state-corruption projection.

The check does **not** restate security findings as failure modes — its job is
forward-looking across all four failure categories, not security-specific.

### Avoiding security-reviewer overlap

This is explicit in the prompt scoping:

> The failure-mode check is structural and forward-looking across all failure types
> (data validation, error handling, state corruption, performance degradation). It
> is **not** a trust-boundary review — security-reviewer covers that territory.
> When both run, security-reviewer findings inform but do not replace this check.

## Edits to `skills/code-review.md`

1. **Add a new Stage 3 subsection** titled `#### Failure-mode introduction scan
   (run after goal-alignment scan)`. This lives between the goal-alignment scan
   and the contrastive note, before deliverables are produced. Specifies trigger,
   refactor-only carve-out, the 3-failure-mode requirement, the category coverage
   rule, the security-reviewer integration rule, and how to record skips.

2. **Add `### Failure modes introduced` section to Deliverable 1** (chat synthesis).
   Placed near the end, after "Cross-critic findings" and before "What the code gets
   right". When skipped, renders a single line stating the reason.

3. **Add `## 🔬 Failure Modes Introduced` section to Deliverable 2** (rubric).
   Placed after `⏭️ Skipped Core Critics`, before the closing pass/fail line.
   Table format: `# | Category | Location | Scenario`. Skip line if the check
   didn't fire.

4. **Update the rubric scaffold** (the ```markdown code block) to include the new
   section so authors and re-runs see it.

5. **Add a one-line entry to "Important Reminders"** noting the failure-mode scan
   exists and that the line threshold is documented in the Stage 3 subsection.

## Out of scope

- Creating a separate `failure-mode-check.md` skill file (file scope restricts to
  `skills/code-review.md`).
- Changing security-reviewer.md (file scope restriction).
- Adding the check as a contextual critic in Step 5 (rejected — the check needs
  panel context, so it fits synthesis better than a Stage 2 dispatch).
- Adding mechanical AST-level refactor detection (the prose-level heuristic is
  sufficient; mechanical detection is over-engineering for this round).

## Test/verification

This is a process change to a skill file — verification is via re-reading the
final document for: (a) trigger logic is unambiguous, (b) carve-out is explicit,
(c) security-reviewer integration is clear without duplicating territory, (d)
deliverables surface the new content in both chat and rubric.
