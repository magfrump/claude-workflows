Commit: a94e01c7

# Self-Evaluation: review-fix-loop

**Target:** `workflows/review-fix-loop.md` (companion: `workflows/pr-prep.md`) | **Type:** Workflow (sub-procedure of pr-prep step 3; `router: none`) | **Evaluated:** 2026-10-15
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

Scope: branch `fix/q160-iteration-cap` at a94e01c7, focused on the new `### Size re-check (after any iteration)` section (Q-104 [2], Q-160) and its links from pr-prep step 1a, step 3e, the step 3 completion criteria, `guides/pr-prep-quick-ref.md`, `guides/completion-signals.md`, `skills/code-review/references/chat-synthesis.md` rule 2 and decision log row 62. Prior assessment: `docs/reviews/self-eval-review-fix-loop.md` (2026-03-24), which evaluated a much shorter document (loop dynamics plus two anti-patterns); the file has since become the owner of the loop's control rules.

Checks run: `bats test/cross-reference-integrity.bats` (ok) and `bats test/workflow-required-sections.bats` (5/5 ok); both new anchors (`#size-re-check-after-any-iteration`, `#early-split-trigger-after-any-iteration`) resolve against the heading slugs.

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | Unchanged from the prior rating in kind: the rules govern process, and no script or test can observe whether the re-check ran (the plan says "no script enforcement (the entry gate is also by hand)"). The new rule does add two checkable traces, a `Size: N code lines against <BASE>` line in review artifacts and a quoted `Q-NNN` waiver in the merge message, plus a partial backstop in chat-synthesis rule 2 (>800 with a 🔴 on a later pass recommends "split PR"), but nothing greps for any of them. |
| Trigger clarity | Adequate | The doc's own trigger stays clear (runs only inside pr-prep step 3). The new rule's in-loop trigger point is weaker: it fires "After each iteration's fix commits", which falls between pr-prep 3c (tests) and 3d (re-review), yet only 3e and the completion criteria link it; the "before the unit merges" re-check has no host step in Phase 2. Precedence against the iteration-4 gate's /away `split` default is not stated (see Key Questions). |
| Overlap and redundancy | Adequate | The single-owner rule is mostly kept: the rule text lives once in review-fix-loop.md, and pr-prep 1a/3e, the quick-ref, completion-signals and chat-synthesis link or summarise it. But the 800 figure and the /away stop are now restated in five places (quick-ref, completion-signals, pr-prep criterion, chat-synthesis rule 2, log row 62), and the rule overlaps the early split trigger and the iteration-4 gate (all three can end in a split) with only one of the two interactions stated. |
| Test coverage | Adequate | Up from Weak: real use is now well documented (91 code-review rubric artifacts in `docs/reviews/`, 31 carrying `Iteration N of 3` headers; the Q-076, Q-104 and Q-160 incidents cited in the doc are drawn from real loops). No test pins any of the doc's content; `workflow-required-sections.bats` only lists it as an exclusion, and no test pins the new section, the 800 figure or chat-synthesis rule 2. |
| Pipeline readiness | Strong | Embedded in pr-prep step 3, which exists and is in daily use; it composes code-review (with `--loop-pass`), self-eval and `lite-review.py`. The new rule plugs into existing machinery (step 1a's count command, the questions.md `you: judgment` route, the step 1a waiver-recording convention) and adds no new dependency. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does:** Owns the control rules of pr-prep's review-fix loop: a hard 3-iteration cap with a written `escalate | split | abandon` gate, a per-iteration header, the early split trigger, the new size re-check (re-run step 1a's count after each iteration's fixes and before merge; tolerate ~800; past it, stop for a user waiver even in /away mode), a lite fix-drift check, divergence detection, and an override-log filter for re-flagged Won't-Fix findings.

**What ad-hoc process achieves:** Without the size re-check, an agent running the loop would measure size once at entry and never again; the cited incidents (396 to 1861 lines over 37 passes; 102 to 842; 217 to 538) show this is what happened. Generic prompting would not produce an in-loop size measurement at all. The gap is a *reminder* gap, not an analytical one: the move is simple, the value is in it being stated and in the stop holding in /away mode.

**What built-in tools cover:** Nothing built-in tracks review-unit growth across iterations.

**Questions for the reviewer:**
- Is 800 (2x the entry cap) the right tolerance, given that U2a3b at 842 and Q-120's waiver at 794 sit right on the line? Will most growth incidents now become a `you: judgment` entry, spending attention the dev cycle tries to save?
- Does making this the one loop rule the agent may not decide in /away mode (unlike the early split and the iteration-4 split default) reflect your intent, or should a separable >800 unit split autonomously, as at entry?

### User-Specific Fit

**Triggering situations:**
- Any pr-prep run whose fixes add code (every multi-iteration loop).
- Build loops dispatched by dev-cycle in /away mode, where the 800 stop blocks a unit until you answer.
- Stacked units, where `BASE` is the branch below.

**Questions for the reviewer:**
- How often do you expect to see size waiver entries? The new row 62 revisit trigger ("two or more units need a waiver past the in-loop ~800 re-check within any 14 days") assumes rare; does recent history (Q-120, Q-131) agree?
- Will you actually want to be asked, or would you rather the agent split and record an interim, as step 1a does at entry?

### Failure Mode Gracefulness

**Output structure:** The rule leaves three traces: a `Size: N code lines against <BASE>` line per iteration, a `Needs: you: judgment` entry when tripped, and a quoted waiver in the merge message. A missing `Size:` line is detectable on inspection, but only by someone who looks.

**Potential silent failures:**
1. **Skipped re-check.** The check is purely by hand; nothing in pr-prep 3c/3d prompts it at the point it runs. The only automatic backstop is chat-synthesis rule 2, which fires only when a 🔴 exists, and only if code-review computes the unit size against the right base on a `--loop-pass --range <sha>..HEAD` run (the range is the fix diff, not the unit).
2. **Wrong `BASE`.** Inherited from step 1a: a wrong base prints a low count and passes. "The same `BASE`" can also go stale when a lower stacked unit merges and the unit is rebased onto main during Phase 2.
3. **Lost growth history.** The doc's Artifacts section says review artifacts are "overwritten each loop", while the new section relies on the per-iteration `Size:` line so "a later pass and the audit trail can see the growth". The history survives only in git (artifacts are committed per iteration), which the text does not say.
4. **Conflicting defaults at iteration 3.** A unit >800 that also hits the cap meets two rules: the gate's /away default is `split` (agent-decided), the re-check says the agent does not decide. An agent may pick either.

**Pipeline mitigations:** chat-synthesis rule 2 (partial, see 1); completion-signals' PR-description checklist line, and the new pr-prep step 3 completion criterion, give a late, self-reported check before merge.

**Questions for the reviewer:**
- Is a by-hand rule with a 🔴-conditional backstop enough, given the entry gate it mirrors is also by hand and still let units balloon?
- Would a one-line check in the merge step (step 1a's command run against `BASE`, compared to 800 and to a cited waiver) be worth adding as a follow-up?

### Condition for Value

**Stated or inferred conditions:**
1. pr-prep is the landing path for every unit (true; memory says solo local merges via pr-prep).
2. Units do grow during review (verified: the plan's table re-counts four merges; two clearly grew past or near 800 during review).
3. The agent remembers to run a by-hand check at a point pr-prep's step text does not mark.

**Automated findings:**
- pr-prep, code-review, self-eval, `lite-review.py`: EXIST.
- step 1a count command: EXISTS and is reused verbatim by reference.
- Mechanical enforcement of the re-check (script, hook or bats test): DOES NOT EXIST (by plan choice).
- Cross-references from pr-prep 1a/3e to the new anchor: RESOLVE (test passes; slugs checked).

**Questions for the reviewer:**
- Condition 3 is the weak one. Is adding a short pointer in pr-prep 3c (or 3d) and in the merge-time description gate (6c) acceptable scope for this branch, or a follow-up?
- Does the new row 62 revisit trigger give you enough signal to retune 800 later?

---

## Key Questions

1. **The /away stop conflicts with the iteration-4 gate's /away split default.** The new text says "This holds in /away mode too: unlike the early split trigger, the agent does not decide this one", but the gate still says "In /away mode and autonomous loops, `split` is the default when the unit has separable parts", and neither section says which wins when iteration 3 ends with the unit over 800, or whether an early split that brings the remainder under 800 lifts the stop. Should one sentence settle that precedence before merge?
2. **The rule fires at a point pr-prep's step text never marks.** It runs "After each iteration's fix commits, and again before the unit merges", i.e. between 3c and 3d and at Phase 2's merge, but only 3e and the completion criteria link it, and the merge-time re-check has no host step. Should 3c/3d and 6c each carry a one-clause pointer, so an agent following pr-prep in order meets the check where it runs?
3. **Nothing mechanical can tell the re-check was skipped.** The `Size:` line and the waiver quote are greppable, but no test or script looks, and chat-synthesis rule 2 only catches >800 when a 🔴 is also present. Is a by-hand rule enough here, given the by-hand entry gate is exactly what let units balloon?
