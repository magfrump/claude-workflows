---
value-justification: "Replaces solving the wrong problem well — surfaces and converges on what should actually be solved before any solution-space work begins, with an explicit exit path when the solution becomes obvious from the framing alone."
---

# Problem Framing Workflow

*Extracted from `divergent-design.md`'s original Double Diamond (Purpose-First) variant. The diverge → diagnose → converge structure mirrors DD steps 1-3 but operates over candidate **framings of the problem** rather than candidate **solutions**. The output is a chosen framing record; whether a solution-space pass follows is a separate decision recorded in the record itself.*

## When to use

Use Problem Framing when any of the following hold:

- **(a) Stakeholders disagree on the goal** — different parties describe the problem in incompatible terms (e.g., "this is a performance issue" vs. "this is an API design issue"). Solving any one framing won't satisfy the others, so the framing must be settled before solutions are generated.
- **(b) A prior attempt solved the wrong problem** — a previous implementation, DD pass, or RPI loop produced a working solution that didn't address the underlying need. The failure mode is "we built it, it works, but the original pain remains." Re-running a solution-space workflow without re-framing will likely repeat the miss.
- **(c) Diagnosis keeps surfacing contradictory constraints** — DD or RPI's constraint list contains pairs no approach can satisfy simultaneously (e.g., "must support all legacy data" + "must remove all legacy code paths"). Contradictory hard constraints usually signal that two distinct problems are being conflated under one effort.
- **(d) Keyword triggers** — "what should we actually be solving?", "what problem are we solving?", "problem framing", "reframe", "are we even working on the right thing?", "wrong problem", "are we solving the right problem?".

This workflow is **standalone**. Many problems exit at "we now know what we're solving; the solution path is obvious" — no DD pass needed. The chosen-framing record explicitly declares which exit path applies (see step 4).

## When to skip

Skip this workflow when **the problem is concrete and uncontested**: a single owner can state the problem in one unambiguous sentence, no prior attempt has misfired, and any current diagnosis converges on a coherent constraint set. Most architectural and library-selection decisions fall here — running Problem Framing on a well-scoped problem is ceremony, not clarity. Go directly to DD (for solution choice) or RPI (for default implementation work).

## When to pivot

The chosen framing record (step 4) declares the follow-up path. Choose from:

- **→ Divergent Design** (`divergent-design.md`): The chosen framing requires choosing among multiple solution approaches with non-obvious tradeoffs. Carry the framing record into DD as input to step 1's divergent generation. The success criterion enters DD step 2 as a hard constraint; the "leaves out" list pre-prunes candidates that solve a different framing (DD step 3 discards them as out-of-scope rather than evaluating them as alternatives).
- **→ Research-Plan-Implement** (`research-plan-implement.md`): The chosen framing makes the solution path obvious — a single approach is clearly correct and the next step is implementation, not solution-space exploration. Use the framing record's one-sentence statement as RPI's scope (step 1) and its success criterion as a built-in verification target.
- **→ Bug diagnosis defaults** (in `CLAUDE.md`, "Debugging defaults"): The chosen framing turns the question into "why is X happening?" rather than "what should we build?" — proceed with the debugging defaults using the framing's success criterion as the reproduction target.
- **→ Spike** (`spike.md`): The chosen framing depends on a feasibility question that can't be answered by reading code (e.g., "can library Y meet the success criterion?"). Run a timeboxed spike before committing the framing to a follow-up solution workflow.
- **Exit (no follow-up)**: The framing reveals the problem is already solved elsewhere, is out of scope, or isn't worth solving. Record the chosen framing, note the exit reason, and stop.

A framing record that names a follow-up path of "DD" or "RPI" should be referenced by path from the receiving workflow's input doc (DD's decision context section, or RPI's research doc) so the framing isn't reconstructed implicitly.

## Working document

Produces a single artifact in the project:

- `docs/working/framing-{topic}.md` — the chosen framing record (the load-bearing paragraph) at the top, followed by the diverge / diagnose / converge work that produced it.

This file is committed to the repo but treated as disposable, same as RPI working docs. If a framing has lasting cross-task value (e.g., it reframes a long-running initiative), promote a copy to `docs/thoughts/` after the immediate work concludes.

## Process

### 1. Diverge — generate candidate framings

Generate **6-10 candidate framings** of the problem. Each framing is a one-sentence statement of "what we are actually trying to solve." Requirements:

- Include at least one framing each known stakeholder would recognize as their version of the problem
- Include at least one framing that recasts the problem at a different scale — zoom in to a sub-problem, or zoom out to the broader system
- Include at least one "null" framing — the problem doesn't exist, is already solved elsewhere, or is measurement noise
- One sentence each, no evaluation yet
- Number them for reference

#### Generation health check

After generating your initial candidates, scan for common gaps. This is not evaluation — you're checking whether the *framing search space* is broad enough. If a gap is found, generate additional candidates to fill it; never remove existing ones.

- **Stakeholder clustering**: Do 3+ framings reuse one stakeholder's vocabulary (e.g., three different "performance" framings when product is also a stakeholder)? Name the missing perspective and add 1-2 framings from it.
- **Missing perspectives**: Is the maintainer's view represented as well as the user's? The naive newcomer's view? The "do nothing" view (the null framing)?
- **Excessive vagueness**: Can each framing imply at least one falsifiable success criterion? A framing like "improve the developer experience" is too vague to test in step 2 — replace it with a specific one.
- **Dimensional anchoring**: Do 5+ framings all move on the same axis — e.g., all about scope, all about timing, all about ownership? Name the axis and add 1-2 framings on a different one.

If the health check triggers additional generation, note it briefly (e.g., "Added 3 framings after health check flagged clustering around the engineering stakeholder's vocabulary").

**Done when...**
- [ ] At least 6 candidate framings are listed
- [ ] Each known stakeholder's framing is represented
- [ ] A scale-shift framing (zoom in or zoom out) is included
- [ ] A "null" framing is included
- [ ] No evaluation or ranking has been applied yet — only generation
- [ ] Generation health check passed: no unaddressed stakeholder clustering, missing perspectives, vague framings, or dimensional anchoring

### 2. Diagnose — what would each framing imply?

For each candidate framing, briefly note three things:

- **Success criterion**: how would we know this problem was solved? Must be falsifiable — name an observable condition, not a vague aspiration.
- **Implied solution space**: what kind of approaches does this framing suggest? (Not which specific solution — just the *space* of solutions it points toward.)
- **What it leaves out**: which concerns from the triggering situation does this framing fail to address?

This step makes anchoring visible. If two framings have nearly identical success criteria, one is redundant — collapse them. If a framing's "leaves out" list contains a hard concern from the triggering situation (something that *must* be addressed), it cannot be the chosen framing — flag it as ineligible.

**Done when...**
- [ ] Every framing has a falsifiable success criterion, an implied solution space, and an explicit "leaves out" list
- [ ] Redundant framings (same success criterion) are collapsed
- [ ] Framings whose "leaves out" list contains a hard concern are flagged as ineligible
- [ ] No success criterion uses vague language like "better" or "easier" without a measurable qualifier

### 3. Converge — choose one framing

Select the framing that:

- Best explains the symptoms that triggered this workflow
- Has a success criterion stakeholders can agree on (or articulate disagreement against)
- Leaves out the fewest hard concerns

If two framings tie and the choice is unclear, **stop and consult the user** rather than picking silently — the same gate as DD's step 4. Surface the tie, name the axis of disagreement (e.g., "scope vs. ownership"), and ask which axis the user wants to optimize for.

Record one-line reasons for each discarded framing. This is the anti-portfolio: future readers (and future framing sessions in adjacent areas) can grep these reasons to avoid regenerating already-pruned framings.

**Done when...**
- [ ] One framing is chosen with a one-sentence rationale grounded in success criteria or constraint coverage
- [ ] If two framings tied, the user was consulted before the choice was finalized
- [ ] Every discarded framing carries a one-line reason for discard

### 4. Document — chosen framing record

Produce a one-paragraph **chosen framing record** at the top of `docs/working/framing-{topic}.md`. The diverge / diagnose / converge work follows below as supporting evidence; the chosen-framing paragraph is the *only* artifact downstream workflows need to consume.

The record uses this template:

> **Chosen framing**: [one-sentence statement of the problem]. We selected this over [1-2 alternative framings, by number or short name] because [reason — usually grounded in success criteria or "leaves out" coverage]. Success criterion: [observable, falsifiable condition]. **Follow-up path**: [DD | RPI | spike | bug diagnosis | exit] — [one-line reason for that exit].

The follow-up path declaration is required and must match one of the options in the **When to pivot** section. This is the explicit handoff: a record with `Follow-up path: DD` is consumed by the DD step-1 invocation; a record with `Follow-up path: RPI` is consumed as RPI's scope statement; a record with `Follow-up path: exit` ends the workflow.

If the chosen framing has lasting consequences worth documenting beyond the immediate task — e.g., it represents a deliberate reframing of a multi-quarter initiative — also add a row to `docs/decisions/log.md` (or open a full `docs/decisions/NNN-title.md` record) pointing back to this framing doc.

**Done when...**
- [ ] Chosen framing record exists at the top of `docs/working/framing-{topic}.md` with all four parts (framing, alternatives, success criterion, follow-up path)
- [ ] The follow-up path matches one of the **When to pivot** options and the rationale is recorded on the same line
- [ ] If the follow-up is DD, RPI, or spike, the calling workflow's input doc references this framing record by path (so the framing isn't reconstructed implicitly)
- [ ] If the framing record was produced after a tie at step 3, the user-consultation outcome is noted in the supporting work below the record

## Worked examples

### Example A — exit at framing (no follow-up DD)

**Trigger**: Two engineers disagree on the next investment for the deploy process. One wants to "fix bugs in the deploy script"; the other wants to "rewrite the deploy runbook." Deploys keep failing for new contributors.

**Diverge** (abbreviated to six of the eight generated):
1. The deploy script has bugs that need fixing.
2. The runbook is out of date and misleads new contributors.
3. New contributors lack the prerequisite knowledge to deploy.
4. The deploy process is fundamentally fragile and should be replaced wholesale.
5. (Null) Deploys don't actually fail at a rate that justifies investment.
6. The deploy script's error messages are unactionable for new contributors.

**Diagnose** (abbreviated):
- #1 has success criterion "no bugs in the script," but observation shows the script works for veterans — leaves out the "new contributors specifically fail" symptom. Flagged ineligible.
- #2 and #6 have overlapping success criteria; #2's success ("runbook reflects current process") is achievable without fixing #6, but #6's success ("a new contributor recovers from a deploy failure without help") implies #2 will follow naturally.
- #5 is refuted by the incident log (4 failed first-time deploys in 6 weeks).
- #4 leaves out the "we can't replace the deploy process this quarter" constraint. Flagged ineligible.

**Converge**: Framing #6 wins — it explains the specific failure mode ("new contributors fail, veterans don't"), its success criterion is observable in the next quarter, and it subsumes #2's benefit.

**Chosen framing record**:

> **Chosen framing**: New contributors fail deploys because the script's error messages don't tell them what to fix. We selected this over #1 (bugs in script) and #2 (stale runbook) because the script works for veterans, ruling out #1, and #2's symptoms are downstream of #6 — fixing the runbook alone leaves the unactionable errors in place. Success criterion: at least 3 new contributors recover from a deploy failure within 10 minutes without help, over the next quarter. **Follow-up path**: RPI — the solution is obvious (rewrite the four error paths with actionable messages), so a full DD pass is unnecessary.

**Outcome**: The next session loads the framing doc as RPI's scope and goes straight to research. No DD round was needed.

### Example B — pivot to DD

**Trigger**: Stakeholders disagree on the goal of a "feedback-loop" initiative. Product wants more user signal; engineering wants fewer support tickets; design wants better in-product affordances.

**Diverge** (abbreviated to six of nine generated):
1. Users can't find the feedback button.
2. We lack quantitative product analytics.
3. We have data but no internal process to act on it.
4. Support tickets are how users actually communicate friction; we should mine them.
5. (Null) We already have all the feedback signal we need; the bottleneck is elsewhere.
6. The product team and the engineering team are optimizing for different definitions of "user friction."

**Diagnose** (abbreviated):
- #1's success criterion ("feedback button click rate up 30%") leaves out engineering's ticket-reduction concern.
- #2 implies an analytics-pipeline solution space; leaves out the design team's affordance concerns.
- #3 implies an internal-process solution space; presupposes #2 is already solved.
- #4 implies a support-ticket-mining solution space; partially covers all three stakeholders' concerns.
- #5 is refuted by the support-ticket volume trend.
- #6 reframes the problem as alignment rather than tooling — leaves out the "we still need a channel" concern.

**Converge**: A new synthesized framing emerges as covering all three stakeholders' core concerns — but it admits multiple distinct implementation approaches.

**Chosen framing record**:

> **Chosen framing**: We lack a structured channel for converting in-product user friction into actionable product signal. We selected this over #1 (button visibility) because that framing leaves out engineering's ticket-reduction goal, and over #6 (team alignment) because #6 leaves out the "we still need a channel" concern. Success criterion: at least 40% of new feature decisions in the next two quarters cite a specific user-friction signal originating from this channel. **Follow-up path**: DD — three viable implementation approaches (in-product survey, analytics-pipeline expansion, support-ticket categorization) need explicit comparison before commitment.

**Outcome**: The follow-up DD round consumes this record as input. DD's step 1 generates candidate implementations against this framing; approaches that primarily solve #1 (e.g., "make the feedback button more visible") are discarded in DD step 3 as out-of-scope rather than evaluated as alternatives, because the chosen framing's "leaves out" list pre-pruned them.

### Example C — exit at framing because the problem isn't real

**Trigger**: A teammate proposes "we should rewrite the auth middleware — it's confusing." No specific incident, just a vibe.

**Diverge** (abbreviated to six of seven generated):
1. The auth middleware is genuinely confusing and should be rewritten.
2. The auth middleware is poorly documented — docs would fix the perceived confusion.
3. The team's mental model of auth is out of date; a knowledge-share session would fix the confusion.
4. (Null) The middleware isn't actually confusing in observed practice — the proposer just hasn't touched it recently.
5. The middleware is fine, but the surrounding code lies about what it does (e.g., misleading variable names).
6. The team's tooling makes auth changes scary, regardless of the middleware's clarity.

**Diagnose** (abbreviated):
- #1's success criterion ("rewrite passes review without confusion comments"): no incident log of recent confusion-tagged review comments to ground this against.
- #4's success criterion ("show that no recent PRs touching auth had >2 confusion-tagged comments"): checkable in git history.
- #2, #3, #5, #6 each have observable success criteria, but each presupposes confusion exists.

**Converge**: Framing #4 is testable in 15 minutes — checking the last 6 months of PRs touching auth. The check shows zero confusion-tagged comments and three PRs that landed without re-review. #4 holds.

**Chosen framing record**:

> **Chosen framing**: The auth middleware is not actually confusing in observed practice; the proposer hasn't touched it recently and is reacting to memory rather than current state. We selected this over #1 (rewrite-justified-confusion) because a six-month review of PRs touching auth showed zero confusion-tagged comments and three clean re-review-free landings. Success criterion: already verified — no rewrite needed. **Follow-up path**: exit — no problem to solve. Re-evaluate if a future PR touching auth attracts ≥3 confusion-tagged review comments.

**Outcome**: The proposer agrees, the rewrite is dropped, and the framing doc serves as the record of why. The "re-evaluate if…" clause acts as a revisit trigger.

## Notes on the original Double Diamond compose path

This workflow was originally the "Diamond 1" half of a Double Diamond pattern, where it was always followed by DD's solution-space "Diamond 2." That compose path still works — see `divergent-design.md`'s pointer back to this workflow. The change is that follow-up to DD is now an *explicit choice* recorded in the framing doc (`Follow-up path: DD`) rather than a default assumption. Most framings exit before Diamond 2.
