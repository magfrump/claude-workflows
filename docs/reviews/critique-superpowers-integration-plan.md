# Deep critique: superpowers integration plan

**Target:** `docs/superpowers/plans/2026-05-18-superpowers-integration.md` (six phases) + companion divergence doc.
**Reviewer brief:** Adversarial pressure-test. Find failure modes the plan would actually hit during execution. Do not soften.

---

## Top findings (ranked by severity)

### Finding 1: Failure-pattern library is severed but not redirected — Severity: Critical

**What's wrong:** Phase 2 deletes `workflows/bug-diagnosis.md` and `skills/bug-diagnosis/` but the plan never mentions the **failure-pattern library at `docs/thoughts/failure-patterns.md`**, which has *two* live couplings: (1) RPI's research step contains a *mandatory* "Failure-pattern grep" sub-step that reads it (workflows/research-plan-implement.md:117-148, with a `Done when` checkbox), and (2) `pr-prep.md:43-55` runs an advisory check that counts `fix(...)` commits vs. new `FP-NNN` entries and tells the user to "return to bug-diagnosis.md step 8 and append the entry before opening the PR." The *write side* (bug-diagnosis step 8) is being deleted. `superpowers:systematic-debugging` does **not** write to this library — there is no step 8 equivalent. So after Phase 2 you have a read-only library that decays into a fossil while RPI keeps requiring grep audits against it.

**Why it matters:** First execution after the deletion: pr-prep fires the FP-coverage warning, the message points the user at a deleted workflow. The Phase 2 verification grep (line 243) is scoped to live references but **explicitly excludes `docs/working`, `docs/thoughts`, `docs/decisions`, `docs/reviews`, `docs/human-author`** — `docs/thoughts/failure-patterns.md` matches that exclude pattern. The header of `failure-patterns.md` itself says `Relevant paths: workflows/bug-diagnosis.md` and `> Append-only one-line log of root-caused bugs from workflows/bug-diagnosis.md` — that's a self-declared dead link the plan will not catch.

**Source:** Cross-reading bug-diagnosis.md against RPI/pr-prep and the integration plan's verification grep.

**Recommended action:** Add a new task to Phase 2 (call it Task 2.4) covering the failure-pattern library specifically. Options the plan must pick between, in order of cost: (a) extend `superpowers:systematic-debugging` invocations with a local pre/post wrapper that does the grep-and-append, documented as the "local extension" the new CLAUDE.md text already alludes to; (b) move the grep-and-append discipline into the RPI research/PR-prep workflows themselves (read on research, write on PR-prep when a fix commit lacks an entry); (c) deprecate the failure-pattern library entirely and remove the read-side and write-side references in the same commit. Do **not** ship Phase 2 until one of these is chosen — silently severing this loop is the most concrete way the integration regresses something that currently works.

---

### Finding 2: Phase 0 framing pre-loaded the answer — Severity: Major

**What's wrong:** Phase 0's "decision" is announced before the divergence is even written: the section title says "Analysis: assumption differences," but the *Decision* heading immediately concludes "They are **complementary, not redundant**." There is no Option A/B/C of the form "merge them," "deprecate ours," "deprecate theirs." The five axes are all framed to support the chosen conclusion — for example, axis 5 ("what failure mode each guards against") is asymmetric on purpose: `code-review` is described by its *failure-class output* (a defect that slips), `verification-before-completion` by its *agent-behavior output* (sycophancy). That framing makes the two seem trivially complementary. A symmetric framing — "what behavior does each prevent in the agent right before commit?" — would show heavy overlap: both fire pre-PR, both demand the agent stop and check before claiming done, and `code-review` already calls itself out for being purely analytical, which is precisely the failure `verification-before-completion` exists to refuse.

**Why it matters:** The whole rest of the plan inherits this assumption. Phase 5's routing edits encode it ("Composition note (code-review vs. superpowers review skills)..."). Phase 4's twelve paths assume the two coexist as separate gates. If the truth is that `code-review` is doing 60% of the work that `verification-before-completion` does, but worse (analytical instead of executed), then the right move is to demote `code-review` from "always run before PR" to "run only when the diff is unverifiable by execution (architecture, API consistency, naming)" — and the Phase 4 design space contracts dramatically. The plan has not asked the symmetric question.

**Source:** pre-mortem lens (six months later, the chat-discipline failure that `verification-before-completion` was meant to fix happens anyway because `code-review` runs and the agent treats its green output as sufficient evidence).

**Recommended action:** Reopen Phase 0. Add an explicit Option B ("merge: code-review becomes a sub-step of verification-before-completion's evidence-gathering, runs only when execution is impossible") and Option C ("scope-narrow: code-review only fires for un-executable concerns — naming, architecture, API design"). Then pick. The current "complementary" framing should be the conclusion of a question, not the framing of one.

---

### Finding 3: Phase 4 is half-locked, half-deferred, in a way that breaks Phase 5 — Severity: Major

**What's wrong:** Phase 4 says "decision locked: Option A = Paths 6 + 11 + 8" and *also* "implementation is out of scope for this plan." But Phase 5's routing table edits (specifically the "Superpowers substrate (load first)" sub-section) include lines like `| About to claim a task complete | superpowers:verification-before-completion | Inner gate. Fires before every completion claim. Refuses analytical inference; requires executed evidence. |` — that's Path 1 / Path 3 wording, not Path 8 (failure-mode-keyed gates) wording. If Path 8 is locked, the routing table should already say "regression-gate" / "critic-gate" / "packaging-gate" with mappings; Phase 5 will need to be re-edited after the follow-up plan lands. Worse, Path 6 says CI-as-authority and Path 11 says verification-subagent: neither of those mechanisms is reflected in Phase 5's routing either. Phase 6 verification (cold-start trace) will pass *because the routing reflects Paths 1/3*, not because the routing reflects the locked Option A. The verification step will create false confidence.

**Why it matters:** When the follow-up Path-6+11+8 implementation plan finally lands, it will require ripping out the Phase 5 routing edits and rewriting them. The "decision locked" status is therefore *not* protective — it's an unrealized constraint that fights the routing the integration plan is shipping. Either Phase 5 should encode Path-8 vocabulary, or Phase 4 should be downgraded to "decision pending" until the follow-up lands, or Phase 5 should be split (5a: routing for what exists now; 5b: routing for Path 8 vocabulary, gated on follow-up).

**Source:** what-if-analysis on the "Option A is locked, implementation deferred" assumption — what if implementation reveals Path 8's naming forces a CLAUDE.md restructure the plan didn't budget for? It will, because the routing table is currently organized by *lifecycle position*, not failure mode.

**Recommended action:** Split Phase 5 explicitly. The portion that's safe to land now is the *substrate registration* (writing-plans, executing-plans, systematic-debugging, receiving-code-review). The portion that depends on Path 8 (gate naming, failure-mode routing) should be deferred to the follow-up plan as Step 5b. Or: downgrade Phase 4 from "locked" to "leaning toward Option A; final lock when follow-up plan starts."

---

### Finding 4: RPI's research-phase is more than a four-section template — Severity: Major

**What's wrong:** Task 3.1's "research-doc template" is 20 lines and lists four headers. The actual RPI step 2 has: a four-line drift-surfacing header (Goal · Problem framing · Project state · Task status), seven required body sections, **three confidence-provenance tag conventions** ([observed]/[inferred]/[assumed]), **research sufficiency signals** (minimum coverage + stop-researching signals), **DD invocation triggers**, the **failure-pattern grep audit token** ("Failure-pattern grep: <matches or 'no matches found'>"), and the **`## Files read` section with `Last verified:` for staleness tracking**. Cut from 502 to ~150 lines, those will be gone. The plan calls them "this repo's unique contribution" but treats them as a single template. Phase 3 task 3.2 also drops: the **plan-doc structure** (Approach, Steps, Implementation order, Size estimate, Estimated/Actual context cost, Test specification table, Failure modes considered, Risks); the **test-strategy auto-invoke** sub-step; the **checkpoint generation** ritual; the **codebase freshness check** (`git log --since=<plan-write-time>`) on fresh implementation sessions; and the **/away context-cost budget protocol**.

**Why it matters:** `superpowers:writing-plans` does not provide any of those — it produces tasks with TDD discipline but no problem-framing header, no failure-pattern grep, no [assumed]-tag honesty pressure, no checkpoint artifact, no fresh-session staleness audit. Phase 3 will silently delete a *lot* of this repo's accumulated discipline by collapsing into "RPI shrinks from 502 to 150 lines as a composition shell." The Phase 6 self-eval may flag this as "Weak" on multiple dimensions, but only after the deletion has shipped.

**Source:** pre-mortem (six months later, agents writing plans no longer surface [assumed] tags, no longer grep failure-patterns, no longer write checkpoints — and nobody noticed because the routing tree still says "RPI" and the discipline failure is silent).

**Recommended action:** Before Task 3.2 rewrites RPI, do an *inventory* sub-task that enumerates every load-bearing primitive in the current 502 lines and assigns each one a home in the new structure: (1) preserved in RPI shell, (2) moved into a local extension skill (e.g., a `research-discipline` skill), (3) moved into a local template, or (4) genuinely deleted as redundant with superpowers. The plan's current Task 3.1 is too small to absorb what's there. Specifically: the four-line header, the failure-pattern grep audit token, the [observed]/[inferred]/[assumed] tag convention, the checkpoint artifact pattern, and the freshness primitives all need explicit homes — not "implied by superpowers."

---

### Finding 5: Phase 2's grep-classification step is uncomputable as written — Severity: Major

**What's wrong:** Task 2.1 step 2 says "For each file, categorize the reference: routing / composition / historical / skill-description, then write to inventory." The grep on line 174 returns ~77 files (verified by running it). Many of those have multiple references each. The categorization rules in step 2 will produce conflicting answers for hybrid cases — e.g., `guides/workflow-selection.md` line 93 is both a routing reference *and* a deprecation note; `workflows/research-plan-implement.md` has references that are *composition narratives within a workflow file*, not routing entries, but the plan's classification scheme doesn't include that category. The line 175 expected-list says "~17 files" — actual is 77.

**Why it matters:** An agent executing this plan will either (a) wildly under-inventory and miss real broken refs, (b) over-inventory and produce a noisy checklist that masks the real broken ones, or (c) stall in an interpretive loop. Combined with Finding 1, the verification grep at step 2.2 line 225 will report "no output" because all the *surviving* references are in excluded directories — and the agent will believe the cleanup succeeded.

**Source:** Direct verification — ran `grep -rln "bug-diagnosis\|bug_diagnosis" --include="*.md" /home/magfrump/claude-workflows | wc -l` → 77.

**Recommended action:** Correct the "~17 files" estimate. Tighten the classification by exhaustively naming the categories with concrete file-anchored examples (e.g., "any `| <activate> |` entry in a decision-tree-style table → routing"). Add a fifth category: **composition-narrative-inside-workflow** (e.g., RPI's "→ Bug Diagnosis" section), which needs different handling — the narrative may need to be deleted entirely rather than redirected, because the destination workflow (RPI) is itself being restructured in Phase 3 and the composition path no longer makes sense.

---

### Finding 6: Plan-location override creates a working-doc fork — Severity: Major

**What's wrong:** Task 3.2 step 1 says "Override the default save location to `docs/working/plan-{topic}.md` instead of `docs/superpowers/plans/`." But (a) `writing-plans` SKILL.md line 18-19 hardcodes `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` with the note `(User preferences for plan location override this default)` — the override is honored *if the user states it*. The plan does not specify *how* the override is communicated: in CLAUDE.md? In a project-level setting? In the routing-table entry for RPI? (b) The integration plan itself is at `docs/superpowers/plans/2026-05-18-superpowers-integration.md` — the user has already started using the superpowers default for this very work. The plan asserts the user has "muscle memory" for `docs/working/`, but its own location contradicts that. (c) Existing in-flight artifacts are at `docs/working/` AND `docs/superpowers/plans/`; the freshness-tracking guide in `guides/doc-freshness.md` may track only one location.

**Why it matters:** After Phase 3, agents will produce plans in one of three places depending on which RPI invocation routes them: `docs/working/plan-*.md` (RPI's override), `docs/superpowers/plans/YYYY-MM-DD-*.md` (superpowers default if override isn't propagated), or wherever the agent guesses (a third location). The pr-prep workflow's `find` commands (line 106-115) hardcode `docs/working/`. None of the cleanup-of-old-plans scripts will sweep two locations.

**Source:** what-if-analysis on the location-override assumption.

**Recommended action:** Pick *one* location and update *every* reference. If `docs/working/` wins, the override must be encoded *in the routing entry itself* (the CLAUDE.md table for RPI). If `docs/superpowers/plans/` wins, pr-prep's `find` patterns must change. Either way, add a task to Phase 3 that does the global rewrite. Do not ship "preserve `docs/working/` by user preference" as a verbal convention — every previous "verbal convention" in this codebase has eroded.

---

### Finding 7: The "complementary not redundant" framing is shaped by author convergence with user, not by independent analysis — Severity: Major

**What's wrong:** The brief that produced this critique explicitly flags it: "Several rounds of refinement with the user, which means the author (me) and the user have converged on a shared mental model. That convergence is exactly where blind spots live." Phase 0's framing, Phase 1's recommendation of Option C, Phase 4's selection of Option A (Paths 6 + 11 + 8) — all three of these were preceded by user-author dialogue that pre-loaded the answer. A clean indicator: Phase 1's Options A, B, C have *six* pros/cons total between them, but the rationale text immediately under "Decision: **Option C**" uses arguments that don't appear in any of the pros/cons lists ("the research phase is genuinely additive — superpowers assumes brainstorming has already produced a clear spec"). That argument should have been a *con* on Option A (deprecate) — its absence from Option A's con list is a sign the comparison was constructed to support C, not to discover the right answer.

**Why it matters:** All three "locked" decisions in this plan are at risk of being load-bearing on the same blind spot. The plan's executor will not re-litigate them. Six months from now, when a contributor unfamiliar with the dialogue tries to understand why RPI is structured this way, they will read Phase 1 and find the rationale circular.

**Source:** Direct cross-reading of Phase 1 options vs. decision rationale; persona lens (hostile reviewer who suspects this is being done for the joy of restructuring).

**Recommended action:** For each locked decision (Phase 0, Phase 1, Phase 4), add a section titled "**Strongest argument against this decision**" written from the perspective of someone trying to defeat it. If the author can't name a serious counter-argument, the decision wasn't stress-tested. If they can, the counter-argument may turn out to be load-bearing.

---

### Finding 8: AGENTS.md and GEMINI.md edits are stated but not specified — Severity: Minor

**What's wrong:** Task 2.2 step 2 and Task 5.1 step 5 both say "Mirror edits to AGENTS.md and GEMINI.md, preserving any harness-specific notes." Neither plan task lists what the harness-specific notes are. AGENTS.md line 16 — verified just now — has the line `**@./workflows/bug-diagnosis.md** — Lightweight hypothesis-test debugging loop: reproduce → isolate → hypothesize → test → fix → verify.` That's a different *summary phrasing* than CLAUDE.md uses. Cross-harness mirroring is not a textual copy.

**Why it matters:** The plan will either (a) silently overwrite harness-specific phrasing, (b) skip the harness files because "mirror" is ambiguous, or (c) produce phrasing inconsistency between harnesses that gets noticed only on the next time AGENTS.md is edited.

**Source:** Direct read of AGENTS.md line 16.

**Recommended action:** Add explicit diff snippets for AGENTS.md and GEMINI.md in Task 2.2 and Task 5.1, the same way CLAUDE.md edits are shown. Two minutes of work; eliminates the ambiguity.

---

### Finding 9: Phase 6's cold-start trace will not catch the failures the integration introduces — Severity: Minor

**What's wrong:** Task 6.1 step 1 says "Pretend you have just loaded the file with no prior context. Trace through: 'I need to fix a bug' → debugging defaults → systematic-debugging; 'I need to add a feature' → ... ; 'I'm about to open a PR' → ...". Those are exactly the three traces the plan's author has been thinking about. A real cold-start would surface different traces — "I'm in the middle of debugging and just hit hypothesis #3; what now?" "I'm about to commit but the failure-pattern library was empty for my symptom — is that meaningful?" "I'm reading a PR and the description says 'verified by Path 6'; what does that mean?" The plan's cold-start trace is a smoke test of the happy paths; it will not detect Findings 1, 3, or 6.

**Why it matters:** Phase 6 will pass green and the integration will land. The first real-world session that hits a failure-pattern grep, or that needs to debug a fresh-session staleness drift, will be the regression report.

**Source:** persona lens (future-self inheriting the system six months from now, debugging an unfamiliar failure path).

**Recommended action:** Add to Task 6.1 step 1: at least one trace from a *failed path* — a 3-failed-hypothesis escape hatch (which exercises the bug-diagnosis-to-RPI handoff, the failure-pattern grep, and the writing-plans hand-off all at once); and a trace from a stale fresh implementation session (codebase freshness check, plan staleness). Both will catch real broken couplings.

---

### Finding 10: Iterative-spec-discovery deferral is plausibly load-bearing — Severity: Minor

**What's wrong:** The iterative-spec-discovery thoughts doc names a problem that *Path 11's verification subagent does not address* (it says so explicitly: "the tests *are* the spec"). The deferral note in the integration plan asserts "this is not a verification-gate problem and does not belong in this plan's Phase 4 candidate set." But Phase 4 locked Option A which includes Path 11. If iterative spec discovery is the *actual* failure mode for an important class of work (the user already gave a triggering instance), then Path 11 will be invoked, will produce a verification subagent that gets the wrong spec, and will rubber-stamp the wrong implementation.

**Why it matters:** The most-cited Path-11 failure mode (single-agent verification optimism) gets harder, not easier, when the spec is emerging. The plan acknowledges this in the Path-11 cons ("verification subagent quality depends on spec quality; weak spec → weak verification") but then defers the spec-quality fix and ships Path 11 anyway.

**Source:** what-if-analysis on the deferral of iterative-spec-discovery.

**Recommended action:** Either (a) defer Path 11 along with the spec-discovery workstream so the two land together, or (b) add a sub-section to Phase 4's decision record explicitly noting that Path 11's mechanism is *suppressed* (not invoked) when the work is flagged as iterative-spec-discovery shaped. Option (a) is cheaper.

---

## Pre-mortem narratives

### Narrative 1: The Failure-Pattern Loop Dies Quietly

Six months after the integration. The agent is researching a feature and dutifully runs the failure-pattern grep — sub-step is still in RPI. `Failure-pattern grep: no matches found`. The agent records the audit token and moves on. The next session, same thing. And the next. Failure-patterns.md still has the same entries it had on integration day — none have been added since. Why? Because the *write side* lived in bug-diagnosis.md step 8, which was deleted. `superpowers:systematic-debugging` does not write to the library; nothing else does either. The library has decayed into a fossil that the read-side audits forever. The discipline cost (write the audit token in every research doc) is now pure overhead — there's nothing real to find. The agent's `Files read` sections grow noisier; humans skim the audit token and tune it out. A year later someone notices the file hasn't been touched since 2026-05 and asks why we still grep it.

**Root cause:** Phase 2 severed the write side without checking the dependency.

### Narrative 2: The Two-Location Plan Fork

Three months after the integration. A new contributor invokes RPI to add a feature. RPI Phase 2 invokes `superpowers:writing-plans`, which honors *its* default `docs/superpowers/plans/YYYY-MM-DD-feature.md`. The plan lands there. The user (a different one, who learned the convention from CLAUDE.md after the edit) opens the implementation session, looks under `docs/working/plan-feature.md`, finds nothing, and assumes the plan was never written. They write it again — at `docs/working/`. PR-prep runs, finds two contradictory plans, panics. The "user preferences override the default" mechanism that Task 3.2 references was a verbal convention. No code enforces it. The location fork compounds with every session that doesn't refresh from CLAUDE.md.

**Root cause:** Task 3.2 step 1 specified "override the default" without specifying the override mechanism.

### Narrative 3: The Cold-Start Verifier That Passed Everything

Phase 6 ran the cold-start trace. The three happy paths all resolved cleanly. PR opened, integration merged. Six weeks later a user hits the 3-failed-hypothesis escape hatch and tries to pivot to RPI. The CLAUDE.md text says "emit a structured handoff doc at `docs/working/handoff-diagnosis-{bug-description}.md` containing a 'What this bug isn't' section." The agent does. Then it goes to invoke RPI's research phase — and the new 150-line RPI shell doesn't mention how to consume that handoff. The 502-line version had explicit handoff guidance under "← From Bug Diagnosis." That whole section was lost in the restructure because Task 3.1's template was four sections and that wasn't one of them. The agent improvises. The handoff narrative is lost. The next bug-diagnosis-to-RPI handoff repeats this.

**Root cause:** Phase 3's template extraction was too small to absorb RPI's composition surface.

### Narrative 4: The verification-subagent that Validates the Wrong Spec

Path 11 implementation lands in the follow-up plan three months after integration. The user starts using it. The first real task is an iterative-spec-discovery-shaped piece of work (the kind the deferred thoughts doc describes). The verification subagent is dispatched in parallel with the implementer; it reads the (incomplete) spec, writes verification that asserts the (locally-correct but globally-incomplete) tests pass, and returns green. The implementer ships. Two weeks later the aggregate behavior is wrong in a way no single test caught. The retro asks: "didn't we have a verification subagent for this?" Yes — and it did exactly what its design said. The failure was the deferred iterative-spec-discovery workstream.

**Root cause:** Phase 4 locked Option A (Path 11) without resolving the iterative-spec-discovery dependency.

### Narrative 5: The Routing Re-Edit That Reverted Phase 5

Eight weeks after the integration. The follow-up plan for Path 6 + 11 + 8 reaches Phase 8 (which renames `verification-before-completion` invocations as `regression-gate` and adds the `critic-gate` and `packaging-gate` vocabulary). Phase 5 of the integration plan had encoded Path-1/3-style routing — "Inner gate. Fires before every completion claim." That line now needs to come out and be replaced with three named gates. The agent doing the follow-up plan re-edits CLAUDE.md, and in the process loses (a) the "code review vs. external review" composition note, (b) the harness mirroring to AGENTS.md/GEMINI.md, and (c) the careful ordering of the routing tables. The follow-up plan's PR ships with regressions in the integration plan's edits. Code review catches some, not all. Trust in the routing tables erodes; the next time someone reads CLAUDE.md they don't believe it.

**Root cause:** Phase 4 was half-locked, half-deferred, and the Phase 5 edits encoded a routing the locked decision contradicted.

---

## What-if analysis (load-bearing assumptions)

### Assumption A: "Superpowers is stable enough to depend on."

The plan treats `superpowers` as a substrate — Layer 1. But it's a *cached plugin* at `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/`. **What if it updates?** The plan's references like `superpowers:writing-plans` are stable by name, but the *content* of those skills is not version-locked. `writing-plans`' default save location, task structure, even the names of its sub-skills could change in a 5.2.0 release. The integration plan has no version pinning, no migration story, no test that the substrate hasn't moved under it. RPI is shrinking to 150 lines that *delegate* to skills it cannot version-control.

**Recommended action:** Add to Phase 5 a CLAUDE.md note stating the superpowers version this integration targets and a manual upgrade-check protocol. Even just `Superpowers substrate version: 5.1.0 (verify on plugin update with: ls ~/.claude/plugins/cache/claude-plugins-official/superpowers)`. Cheap, prevents silent drift.

### Assumption B: "The substrate's behavior matches its description."

`writing-plans` says it produces TDD-disciplined task lists. The plan reads "writing-plans does X" and stops there. **What if writing-plans actually produces something subtly different from what its SKILL.md describes?** No one has tested the composition. RPI Phase 2 → writing-plans → executing-plans is going to be the new default for non-trivial work. The first time it runs is in production.

**Recommended action:** Before Phase 3 commits, run a tracer-bullet RPI invocation on a small real task and capture the output. If `writing-plans` produces a plan in an unexpected shape — a different header, missing TDD scaffolding, no Self-Review block — find out before 150-line-RPI ships.

### Assumption C: "The 'pivot signals' will fire."

The new RPI shell (Task 3.2) lists pivot signals: "if research surfaces a design fork → DD; if research can't answer feasibility → spike; if research reveals unfamiliar codebase → onboarding." But the *old* RPI had the pivot signals embedded in a longer narrative (with concrete examples, sufficiency signals, and stop-researching cues). In 150 lines, "if X → Y" reads like a glance-level rule. **What if the pivot triggers stop firing because there's no surrounding context to recognize the signal?**

**Recommended action:** Test this hypothesis in Phase 6: read the new RPI cold and ask "what would I notice that would make me invoke DD or spike?" If the answer is "I'd notice when 3+ approaches appear in research" — that's the same threshold the old RPI had explicitly. If the answer is vaguer, the shrinkage cut a load-bearing primitive.

### Assumption D: "/away mode will continue to work."

CLAUDE.md `/away` mode's autonomous commit format depends on the plan's *Confidence* field, the *Notes* field, and the *Context-cost budget* protocol. All three of those are currently specified in **RPI step 6** ("Implement"). When RPI shrinks to a composition shell, these specifications need to live somewhere. The plan does not say where.

**Recommended action:** Either move the /away protocol from RPI into CLAUDE.md proper (since it applies to all autonomous work, not just RPI), or list it as a required preserved section in Task 3.2's new RPI structure. Currently it falls into the gap.

---

## Persona findings

### Persona 1: The skeptical platform engineer (markdown-heavy workflows are LARP)

> Look. You have 502 lines of markdown for "research, plan, implement." You're going to replace it with 150 lines of markdown that *invokes* 1500+ lines of markdown in someone else's plugin. The total complexity has gone *up*. The only thing that's gone down is *your* line count, because the plugin's lines don't count against you.
>
> Worse — none of this is testable. There is no CI on these docs. There is no integration test that says "given this prompt, the agent picks RPI, follows it, lands on writing-plans, produces a plan in the expected location." All the verification in Phase 6 is "re-read the file from a cold-start perspective" — which is the author re-reading their own work.
>
> If you actually want this integration to work, write **one** runnable end-to-end test that exercises the composition on a real (toy) task. Use Claude Code itself. Record the trace. Diff that trace against a golden expected trace on every CLAUDE.md change. Until you have that, you are LARPing software engineering with markdown.

**Force this persona's strongest point through:** Phase 6 has no executable verification. The self-eval rubric is judgment-based. The cold-start trace is mental simulation by the author. Add an executable end-to-end test or accept that this integration will be validated post-hoc by failures.

### Persona 2: The TDD practitioner (this is overcomplication)

> What problem are you actually solving? Looking at the plan, the real motivating concerns seem to be: (a) drift between two debugging workflows you maintained, (b) too much overlap between code-review and verification-before-completion, (c) some chat-discipline lapses. Three concrete pain points.
>
> Your solution: 6 phases, 12-path divergence analysis, three locked decisions, three deferred workstreams, two new follow-up plans, restructure of the most-used workflow in the repo. That's a 50x complexity-to-problem ratio. The TDD answer is: pick the smallest thing that addresses the most painful pain point, ship it, see what's still painful, repeat. You're trying to design the right architecture before knowing what's actually causing the pain.
>
> Specifically: just doing Phase 2 (delete bug-diagnosis, redirect to systematic-debugging) would address concern (a). Just adding "before claiming done, invoke verification-before-completion" to pr-prep would address (b) and (c). Two small changes. Land them, observe, decide if more is needed. The current plan is trying to land 100% of the answer in one batch.

**Force this persona's strongest point through:** The plan would be more robust if it shipped only Phase 2 + a single-line pr-prep edit ("before review-fix-loop, invoke `superpowers:verification-before-completion`") and observed for a month. Then decide whether RPI restructure, Phase 4 paths, and the cross-project rollout are actually needed.

### Persona 3: The hostile reviewer (this is for the joy of restructuring)

> The recently-committed changes include a Ralph-loop commit rule, an `/away` mode flip, an SI-noninteractive feedback note, a memory file called `project_si_rewrite_needed.md`. You're in restructuring mode. The "evidence" for this integration is mostly internal: the author maintains workflows that overlap with superpowers; the author finds the overlap awkward to maintain; the author wants to simplify. None of that is a *user* problem.
>
> Look at the Phase 4 divergence doc: 12 paths, 304 lines, all addressing a question of the form "how do we name and compose two skills that already work." This is the kind of document a contributor writes when the *meta-problem* (the architectural shape) has become more interesting than the *object-problem* (the agent shipping correct code). The user gave a triggering instance — chat-discipline lapses, local-vs-CI drift — and the author returned with a 12-path matrix and three locked decisions. That ratio of analysis to ground-truth pain is suspicious.

**Force this persona's strongest point through:** Before committing to the integration as-is, re-read your own SI loop output for evidence that *external workflow output quality* has degraded under the current setup. If the SI loop has only flagged *internal* metrics (commit-scope prefix imbalance, etc.), this restructure is not user-validated.

### Persona 4: Future-self inheriting this six months from now

> I am you in November 2026. I have lost all context for why this is structured this way. I open CLAUDE.md and see "RPI (composition over `superpowers:writing-plans` + `superpowers:subagent-driven-development`)" — fine, I follow the links. RPI is now 150 lines of composition shell that says "Phase 2: invoke `superpowers:writing-plans`." I open writing-plans. It says save plans to `docs/superpowers/plans/`. But our repo's plans are at `docs/working/`. Why?
>
> I find the "user preferences override the default" note. I look for the override. It's not in CLAUDE.md. I check `docs/decisions/` — there are three NNN- prefix records the integration plan said would be created. The naming convention varies. One of them says "We chose Option C for RPI." It doesn't explain *why* the failure-pattern library got dropped or where the [observed]/[inferred]/[assumed] convention went. I check git log — feat(rpi): restructure as composition shell. That commit has 400 lines removed and 100 added; I can't tell from the diff what was preserved deliberately and what was deleted.
>
> Six months ago you knew exactly why. Now I don't. The plan didn't leave breadcrumbs for the *negative* decisions — the things deliberately dropped.

**Force this persona's strongest point through:** Add a *retained-and-dropped* table to the Phase 3 decision record. Every load-bearing primitive in the current 502-line RPI gets a row: "retained / moved to <location> / deleted (with reason)." Future-self reads that table and reconstructs intent in 30 seconds instead of 30 minutes.

---

## Items the plan got right (convergence check)

- **Phase 2's classify-then-redirect-then-delete sequencing is correct.** Even with Finding 5's classification problems, the *shape* (inventory → redirect → delete) is right. Doing the delete first would lose references; doing the redirect first without inventory would miss spots.
- **Phase 1's Option C analysis is honest about the migration cost.** The cons list for Option C mentions in-flight plan migration. Many plans of this shape hand-wave migration; this one names it (though it then defers it as out-of-scope, which Finding 4 covers).
- **The divergence doc's twelve paths are genuinely well-explored.** Even if Option A's lock is premature (Finding 3), the divergence work is good: it surfaces the failure-mode-keyed gates dimension, the inverted-relationship reframing of Path 7, and the single-agent-verification-optimism objection of Path 11. The doc is doing real work.
- **The decision to extract a research-doc template into `templates/` is correct in principle.** It's the right home. The problem (Finding 4) is the template is too thin, not that the location is wrong.
- **The plan does explicitly defer items.** "Out of scope (explicitly deferred)" at the end is a good practice; it's just that some items in that list (Phase 4 chosen-path implementation, cross-project rollout) are load-bearing on Phase 5's coherence.

---

## Open questions the author should answer before execution

1. **Where does the failure-pattern library write side live after Phase 2?** (See Finding 1.) The plan must answer this before Phase 2 commits, not after.
2. **Is Option C in Phase 1 actually load-bearing, or is the integration salvageable with Option A (full deprecate) and a much-smaller "research-discipline" skill?** (See Finding 4, Persona 2.) The shrinkage cost is large enough to ask the question again.
3. **What is the "user preferences override the default" mechanism for plan location?** (See Finding 6.) If verbal convention only, the plan is fragile. If encoded somewhere, where?
4. **Does the cold-start verifier in Phase 6 include any failure-path traces?** (See Finding 9.) The current happy-path-only traces will pass while couplings break.
5. **Should Phase 5 be split into 5a (substrate registration, safe) and 5b (Path-8 gate vocabulary, deferred)?** (See Finding 3.) Or should Phase 4 be unlocked and re-decided after the follow-up plan starts?
6. **Will Path 11 fire on iterative-spec-discovery-shaped work, and if so what suppresses it?** (See Finding 10.) Locking Path 11 without resolving this risks producing rubber-stamp verifications.
7. **What is the executable end-to-end test that proves the integration's composition works?** (See Persona 1.) If "self-eval rubric" is the answer, the integration has no real verification.
8. **What is the user-observed pain that motivates this integration, and how will the integration's success be measured against it?** (See Persona 3.) If the answer is "internal cleanliness," shrink scope.

---

## Verdict

**Not ready to execute as-is. Needs significant rework before execution — primarily on Phase 2 (Findings 1, 5) and Phase 3 (Finding 4), with secondary rework on Phase 5's locking-vs-deferral coherence (Finding 3).**

The plan's *direction* is reasonable and the divergence analysis is good. But three of the six phases ship with concrete, identified failure paths that the plan's own verification step will not catch. Executing as-is means landing the integration and then discovering Findings 1, 4, and 6 the hard way over the next two to six weeks.

A scoped-down version — just Phase 2 (with the failure-pattern fix) and a minimal pr-prep edit ("invoke verification-before-completion before review-fix-loop") — would address the two most-cited pain points (parallel debugging implementations, code-review-vs-verification overlap) at ~10% of the proposed plan's complexity, and would let the larger restructure be informed by real usage data rather than pre-restructure dialogue.
