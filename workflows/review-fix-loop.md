---
value-justification: "Replaces open-ended review-comment-fix cycles with a structured convergence loop that reaches clean code in fewer iterations."
---

# Review → Fix → Revalidate Loop

This document is reference material for the review-fix loop step in [pr-prep](pr-prep.md). See pr-prep Step 3 for the procedure itself.

## Loop dynamics

The key insight is that each iteration operates on a higher-quality baseline:

```
Loop 1: Fix obvious issues (wrong field names, broken regexes, UUOC)
Loop 2: Fix subtle issues revealed by Loop 1 fixes (scoping bugs, false passes)
Loop 3: Fix consistency issues across the now-correct test suite
```

Reviews get more useful as the code gets cleaner — early reviews are dominated by surface issues that mask deeper ones. This is why a single review pass is often insufficient.

In practice, most feature branches converge within a few loops, though this depends on the size and complexity of the change.

## Convergence ceiling

After **3 iterations**, if the reviewer is still surfacing new issues (not regressions introduced by prior fixes), **stop**. This mirrors the 3-hypothesis escape hatch in the debugging defaults — unbounded iteration has diminishing returns. Choose one of two exit paths:

1. **Ship with documented known issues.** If no Must Fix items remain but Must Address or Consider items persist, document the remaining findings in the PR description's "Areas of uncertainty" section and proceed to Phase 2 of pr-prep. The human reviewer sees the known issues and can make a judgment call about whether they block merge.
2. **Escalate to human review.** If Must Fix items remain, or if you're unsure whether remaining findings are safe to ship, stop and present the user with:
   - **Iteration count**: how many loops have run
   - **What changed**: a brief summary of fixes applied in each iteration
   - **What remains flagged**: the new (non-regression) findings from the latest review
   - **Assessment**: why the loop isn't converging (e.g., fixes are revealing deeper issues, the change is too large for incremental review, the review criteria are shifting)

This is a **soft ceiling**, not a hard stop. The user can say "continue" and the loop resumes for another iteration (the counter does not reset — iteration 4 still escalates after one more pass if new issues appear). But the default is to pause and let the human decide whether more iterations are productive or whether the approach needs to change (e.g., pivot to divergent-design, split the PR, or accept the remaining findings as known debt).

**Why this exists:** Review-fix loops have diminishing returns. Early iterations catch real issues; later iterations often churn on style or reveal that the underlying approach needs rethinking, not more polishing. Unbounded loops waste tokens without meaningful quality improvement.

**What counts as "new" vs. "regression":** A regression is a finding that was introduced by a fix from a prior iteration (e.g., a typo in a renamed variable, a broken import from a file move). A new issue is anything the reviewer surfaces that existed before the fix or that reflects a deeper problem. When in doubt, treat it as new — false positives on the ceiling are cheap (the user just says "continue"), while false negatives waste iterations.

**Tracking convergence:** To evaluate whether this ceiling is set at the right level, note in the PR description or commit message whether the loop converged cleanly (and in how many iterations) or hit the 3-iteration ceiling. This creates an audit trail for calibrating the threshold over time and for evaluating whether the bound prevents unbounded cycles in practice.

## Divergence detection (stuck-loop signal)

The convergence ceiling catches *progress without convergence* — new findings keep appearing across iterations. It does not catch a different failure mode: **the same finding keeps re-appearing after you claimed to have fixed it.** That is a stuck loop, and it usually means the prior fix targeted a symptom rather than the underlying cause.

### Signal

After any iteration in which a finding was marked resolved (the review artifact called it fixed, or a commit referenced fixing it), inspect the next iteration's findings. Treat a finding as a **re-fire** if any of the following match a prior "fixed" finding:

- **Identical text**, modulo trivial whitespace or numbering changes.
- **Near-duplicate text**, within a ≤2-line edit-distance heuristic — i.e., adding, removing, or rewording up to two lines of the finding description leaves it equivalent. Apply this by reading the two findings side-by-side; no tooling required.
- **Same location and category**: same file, same line ±5, same finding category (e.g., "missing null check", "race condition", "off-by-one").

One re-fire is enough to trigger the signal — do not wait for a pattern to develop.

### Action

When a re-fire is detected:

1. **Flag the loop as stuck.** Note in the current review artifact and in the next commit message which finding re-fired and which prior iteration claimed to fix it. This makes the stuck state visible in the audit trail rather than buried in diff churn.
2. **Pivot to a deeper read of the underlying issue.** Do not patch the re-fired finding again at the same surface. Instead:
   - Re-read the implementation around the finding, including callers and callees, not just the changed lines.
   - Ask whether the prior fix addressed a symptom (e.g., guarded one call site) rather than the cause (e.g., the function's contract is wrong, the data shape is unexpected upstream, the abstraction leaks).
   - Consider structural alternatives: refactor, change the contract, push the fix to a different layer, or accept the finding as a known limitation if the structural fix is out of scope.
3. **Surface to the user.** Present:
   - **Which finding re-fired**, with both the original and the new wording.
   - **What the prior fix attempted** (commit hash and one-line summary).
   - **The deeper-read result** — what you now believe the underlying issue is.
   - **A recommendation** — refactor at the deeper level, accept and document as a known issue, escalate, or split the structural fix into a separate PR.

### Flag only — never auto-abort

This signal **flags and pivots; it does not stop the loop**. The user decides what to do:

- "Continue patching" — they judge the re-fire is coincidental (e.g., two distinct bugs that happen to read alike). Resume the loop without further pivot.
- "Apply the deeper fix" — proceed with the structural change you proposed.
- "Accept and document" — record the finding as a known limitation in the PR description and exit the loop.
- "Escalate" — same path as the convergence ceiling: hand off to human review.

The cost of flagging a false positive is one short user prompt; the cost of missing a real stuck loop is iterations of churn that compound into the wrong kind of technical debt. Bias toward flagging.

**Why this exists:** Re-fires are the loop's analogue of the symptom-vs-root-cause split from the debugging defaults. Patching the same surface repeatedly produces a fix history that looks productive in the diff but leaves the underlying cause intact — and often makes the eventual structural fix harder, because each surface patch is now a constraint to preserve. Catching this on the first re-fire is much cheaper than catching it after three.

**Relationship to the convergence ceiling:** Divergence detection can fire on iteration 2 (one re-fire is enough), well before the 3-iteration ceiling. The ceiling is for *new* findings accumulating; this signal is for *old* findings recurring. Both surface to the user, both are flag-only, and a single loop can hit both — in which case the deeper-read pivot takes precedence over the ship/escalate choice from the ceiling.

## Re-flagged settled decisions (override-log filter)

The convergence ceiling watches for *new* findings that keep accumulating across iterations. Divergence detection watches for the *same* finding re-firing after a fix attempt. A third pattern sits between them: a finding re-fires because it was already resolved as **Won't-Fix** in the override log — either earlier in this PR's iteration history or in a prior PR. The critic does not read the log between iterations; you do.

This section extends the override-log work shipped in round 1 (which made `docs/reviews/override-log.md` readable inside the `code-review` skill on every run) to the iteration loop, which sees the same finding re-fire across rounds and would otherwise re-triage it each time.

### Signal

Before triaging an iteration N review's findings into Must-Fix / Must-Address / Consider, scan each new finding against `docs/reviews/override-log.md`. A finding matches an override-log row when:

- **Same location**: same file, same line ±5, AND/OR
- **Same category and substantively the same claim**: e.g., both are "missing null check on `user.email`" or both are "log statement leaks PII at `auth.ts:42`".

A row counts as a match only if its **Override verdict** is `Won't-Fix` (regardless of whether the row's `PR ref` is this PR or a prior one). Other override verdicts — `Defer`, promotions to `🔴 Must-Fix`, etc. — do not trigger this filter; only the explicit decision to *not* fix carries forward as noise-suppression.

### Action

A matched finding does **not** enter the Must-Fix / Must-Address / Consider triage. Instead, surface it under a separate **Re-flagged settled decisions** subsection in the review artifact (and in the PR description, if any of these findings persist to that stage). Each entry includes:

- The finding's wording in the new review.
- The override-log row it matched (date, PR ref, reason).
- A one-line acknowledgement: "no action — see override-log."

The Must-Fix/Must-Address triage proceeds on the remaining (un-matched) findings only. The "Re-flagged settled decisions" subsection is informational and does **not** block exit from the loop.

### Disagreeing with a prior Won't-Fix

If on review you believe the prior Won't-Fix call no longer applies — the code has changed, the reasoning has aged out, or the prior decision was wrong — promote the finding back into the normal triage by adding a fresh override-log row that supersedes the prior one (or by striking the original per the override-log's strikethrough convention). That promotion is a **deliberate, recorded act**, visible in the override-log diff, not a silent re-fire that the loop quietly re-triages.

### Why this exists

The same code is reviewed multiple times across the loop, and findings already settled as Won't-Fix can keep re-emerging because:

- The diff under review grows between iterations as fixes land,
- The critic is non-deterministic (slightly different wording or category each run),
- A different critic (e.g., a sub-critic invoked by `code-review`) surfaces the same code path.

Without this filter, settled decisions get re-litigated each round, churning both the triage step and the human's attention. With it, Won't-Fix carries forward as the default until someone deliberately revisits it.

### Relationship to divergence detection

Both this filter and divergence detection are "same finding re-appears" patterns, but they have opposite resolutions:

- *Divergence detection* fires when the prior iteration claimed to **fix** the finding and it re-fires anyway — meaning the fix was likely a symptom-patch and you should re-read for the underlying cause.
- *Re-flagged settled decisions* fires when the prior decision was **Won't-Fix** and the finding re-fires anyway — meaning the critic forgot a decision that was deliberately made, and the right action is to filter, not investigate.

If a finding could match both (a prior iteration's fix attempt *and* an override-log Won't-Fix entry), divergence detection takes precedence — the active fix attempt is more recent and more specific to this PR's iteration history than a prior Won't-Fix call.

## Anti-patterns

These supplement the guidance in pr-prep Step 3 (which covers verifying findings and the convergence ceiling):

- **Fixing Consider items before Must Fix items.** Tier order exists for a reason — fixing a style issue in code that has a correctness bug is wasted work.
- **Skipping the test run between fix and re-review.** The test run is where you catch issues the review didn't anticipate. Skipping it means the re-review may pass on code that doesn't actually work.

## Relationship to other workflows

This loop complements Research → Plan → Implement. RPI produces an implementation with a human-reviewed plan; the review-fix loop adds automated code review and iterates on findings. Together they cover the full path from "understand the problem" to "PR ready for human review."

The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow — use pr-prep, which sequences it within a two-phase process: content (gate checks → draft PR → review-fix loop) then packaging (commit cleanup → CI/annotation → description).

## Artifacts

This loop doesn't produce its own working documents. It operates on and updates:

- `docs/reviews/*.md` — review artifacts (overwritten each loop)
- Test files — fixed as findings are addressed
- The feature branch itself — commits accumulate naturally

The commit history serves as the audit trail for what was found and fixed in each loop.
