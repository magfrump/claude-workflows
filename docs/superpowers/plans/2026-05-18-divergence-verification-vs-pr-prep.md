# Divergence: `verification-before-completion` vs. `pr-prep` — extended option space

**Status:** Divergent option exploration; decision deferred.
**Companion to:** `docs/superpowers/plans/2026-05-18-superpowers-integration.md` Phase 4 (Paths 1–4 originate there).
**Goal:** Map the *full* design space for how the upstream `superpowers:verification-before-completion` skill composes with this repo's `workflows/pr-prep.md`. The companion plan listed four options; this doc extends past them and surfaces non-obvious candidates.

## What you should already know before reading the candidates

Read these first if you have not:

1. **`verification-before-completion` is a gate function, not a workflow.** It fires whenever any "done" claim is about to be expressed in chat (`Great!`, `Done!`, `Should pass now`, `Looks correct`). Iron law: *no completion claim without fresh executed evidence*. It refuses analytical inference, captured output from a prior run, and agent self-reports. It is a single-skill gate, scope-flexible — it can fire per-step or per-task; nothing in the skill text picks scope for you.
2. **`pr-prep` is much larger than verification.** It covers env scan, size check, dependent-PR check, pre-mortem fallback, draft PR open, review-fix loop (which invokes `code-review`), commit history cleanup, CI verification, PR description authoring, post-merge follow-up, and a retrospective. Its expensive load-bearing component is the **review-fix loop** + the **`code-review` orchestrator**.
3. **`code-review` is analytical, not executed.** It dispatches critic sub-agents that infer from diff structure; it does *not* run code. This is the central divergence with `verification-before-completion`: the two skills disagree about what counts as evidence.
4. **The four existing paths vary only on the enforcement/composition axis.** The candidates below vary on other axes — scope (per-commit/per-PR/per-merge), trigger (hook-enforced/CI-enforced/linguistic), authority (tests/agent/CI/human), evidence format (transcript/artifact/screenshot/CI log), and reframing (inverted relationships).

## The four existing paths (summary, not repeated in detail)

- **Path 1:** Per-task verification gate during execution; pr-prep stays as branch-scope outer workflow. Both run.
- **Path 2:** Replace pr-prep with `verification-before-completion` + `review-fix-loop` + `finishing-a-development-branch`. Maximum delegation.
- **Path 3:** Path 1 + explicit "inner-gate / outer-gate" naming convention.
- **Path 4:** Defer; keep both; mark `verification-before-completion` as advisory pre-pr-prep.

The new candidates start at Path 5.

---

## Extended candidate paths

### Path 5: Hook-enforced per-commit verification

**Mechanism:** Install a `pre-commit` git hook that refuses to allow a commit unless a `Verified:` trailer is present in the commit message AND the hook can find a captured verification artifact at `.git/verification/<sha>.txt` written within the last 15 minutes. The agent must run the verification command, capture its output to that path, and reference it in the commit body. `verification-before-completion`'s "iron law" stops being enforced by chat-discipline and starts being enforced by tooling. `pr-prep` becomes purely a packaging workflow (review-fix loop, PR description, commit cleanup) with no verification responsibility — verification has already happened, by tooling, at every commit boundary.

**Failure mode guarded against:** The two failure modes `verification-before-completion` is most worried about — sycophantic completion claims and trusting agent self-reports — are both **chat-level discipline failures**. A hook moves the gate below chat, where the discipline cannot lapse. Specifically prevents: committing broken code with a "tests pass" claim that wasn't run, committing without exit-code 0 evidence, deferring verification until "later in pr-prep".

**Failure modes NOT guarded against:** The hook can't tell whether the captured output is *relevant* to the diff — an agent could rerun an unrelated test suite, capture its `0 failures` output, and pass the hook. Bypassing with `--no-verify` is trivially easy (though CLAUDE.md already forbids this for Claude). Hooks don't catch the *aggregate*-state regression: each commit verifies locally but the branch tip may still fail because two passing commits interact badly. Doesn't address packaging quality at all.

**Composition:** `pr-prep` keeps its full scope minus the verification responsibility — review-fix loop, PR description, retrospective all still run. The hook fires per-commit, independent of any workflow. `code-review` runs once at pr-prep step 3 as before. `finishing-a-development-branch` can replace pr-prep step 5–6 if desired. RPI's Phase 4 (implement) gets the hook for free; no skill-level invocation needed.

**Implementation cost:** ~3–4 hours. Write the pre-commit hook (bash), wire it into a repo `.githooks/` directory, document the `Verified:` trailer convention, update CLAUDE.md to reference the hook as the verification authority, write tests for the hook's pass/fail behavior.

**Where this puts the agent on the design-space dimensions:**
- *Scope:* per-commit (finest enforced granularity short of per-step).
- *Trigger:* hook (mechanical, environment-enforced).
- *Authority:* the hook + the captured output file. Not the agent's self-report.
- *Evidence-format:* file-on-disk transcript, with timestamp window.

**Pros / Cons:**
- + Removes the chat-discipline failure mode entirely; verification can't be "skipped just this once".
- + Decouples verification from any workflow — works for ad-hoc commits, Ralph loops, single-line fixes.
- + Creates a forensic trail (`.git/verification/<sha>.txt`) that's auditable post-hoc.
- − Hook is bypassable (`--no-verify`); enforcement is only as strong as the policy forbidding bypass.
- − Captured-output relevance is unchecked; the hook can be satisfied with the wrong test suite's output.
- − Adds friction on commits that genuinely don't need verification (typo fix, doc-only).

---

### Path 6: CI-as-verification-authority; pr-prep narrows to packaging

**Mechanism:** Treat the **green CI signal on the remote branch** as the only valid form of "verification" for any completion claim that escapes the local environment (PRs, merges). Local invocations of `verification-before-completion` are downgraded to a heuristic pre-check. `pr-prep` step 5a (CI verify) becomes the *authoritative* gate; the review-fix loop is gated on CI green at iteration N before iteration N+1 begins. PR-prep is no longer permitted to open the draft PR (step 2) until at least one CI run has succeeded on the branch. The chat-level gate becomes advisory.

**Failure mode guarded against:** Environmental drift between the agent's machine and CI — tests that pass locally but fail on CI due to OS, env vars, Python version, missing fixtures, race conditions exposed under parallelism. The local-tests-pass-but-CI-fails failure mode is real and frequent, and chat-level `verification-before-completion` cannot catch it because the agent runs in the same environment as the local tests.

**Failure modes NOT guarded against:** Doesn't help projects without CI. Doesn't help during the offline-development phase (the agent has to wait for CI to know if a task is "done"). Slow — CI latency becomes a critical-path bottleneck for verification. Doesn't address sycophantic claims that *precede* the push (the agent can still say "fixed!" without proof until CI confirms). And the same blindspot as Path 5: CI passing doesn't prove the right thing was tested.

**Composition:** `pr-prep` step 2 (open draft PR) becomes the early step where CI starts running; step 5a (verify CI) is reframed as "CI is the authority". `verification-before-completion` invocations during execution become local heuristics, downgraded in CLAUDE.md. `code-review` still runs after CI passes, since it's analytical and doesn't require fresh tests. RPI Phase 4 picks up an "implementation is not done until CI passes on a draft PR" rule.

**Implementation cost:** ~2 hours. Update `pr-prep.md` to reframe step 5a as gate-authority. Update CLAUDE.md to demote `verification-before-completion` to "local heuristic; CI is authoritative for completion that crosses a boundary". Add a CI-required precondition to the review-fix loop iteration.

**Where this puts the agent on the design-space dimensions:**
- *Scope:* per-PR (CI fires on push).
- *Trigger:* push-to-remote (mechanical, environment-enforced).
- *Authority:* CI signal. Not the agent. Not local tests.
- *Evidence-format:* CI run URL and exit code.

**Pros / Cons:**
- + Eliminates the local-vs-CI environmental drift gap.
- + CI is already a hard gate for merge; aligning verification with it removes a layer.
- + Audit trail is the CI provider's run history (forever, queryable).
- − Slow feedback — agent can't claim a task done until a push has run through CI.
- − Useless for projects without CI or with slow CI; offline-first development breaks.
- − CI green ≠ feature works; this is a coarse signal that misses semantic bugs.

---

### Path 7: pr-prep as the *audit log* of verification (inverted relationship)

**Mechanism:** Reframe entirely. `verification-before-completion` is the **operational gate** — it fires constantly during work, on every chat-claim, and produces evidence artifacts at `docs/working/verification-log-<branch>.md` (one running log per branch). `pr-prep` is no longer a workflow that "checks" anything new; it is the **audit-log compilation step** that consumes the running verification log and rolls it up into the PR description. PR-prep's job becomes: read the verification log, summarize what was verified and when, write that into the PR's "Test plan" section, and verify the log is *complete* (every commit on the branch has at least one verification entry in the window of its authorship). If a commit has no verification entry, pr-prep refuses to proceed and surfaces the gap.

**Failure mode guarded against:** The verification trail going *unrecorded*. Currently, `verification-before-completion` runs in chat — the evidence lives in the conversation transcript, which is ephemeral, not committed, not surfaced to the reviewer. A reviewer cannot tell from looking at a PR which claims were verified vs. which were inferred. This path makes verification *legible to humans* and to other agents that pick up the branch.

**Failure modes NOT guarded against:** Doesn't enforce that the verification is *correct* — agent can write a verification entry without actually running the command, same as today. Doesn't catch environmental drift. Doesn't prevent the review-fix loop's analytical findings from contradicting the executed evidence (need separate reconciliation). Adds significant write overhead for every verification.

**Composition:** `verification-before-completion` keeps its iron law and gains an evidence-write side effect. `pr-prep` shrinks — review-fix loop still runs, but the verification responsibility moves out and becomes a log-completeness check. `code-review` operates on the diff AND the verification log, with critics able to cite "verified at log-entry-N" or flag "no verification recorded for this hunk". RPI's Phase 4 produces verification log entries as a natural byproduct. `finishing-a-development-branch` can replace pr-prep's tail.

**Implementation cost:** ~4–5 hours. Define the verification-log file format, update `verification-before-completion`'s description (or a local skill that wraps it) to write to the log, rewrite the verification-related parts of `pr-prep.md` to be a log-consumption + completeness-check step, update `code-review`'s `Before You Begin` to read the log.

**Where this puts the agent on the design-space dimensions:**
- *Scope:* per-claim (verification-time) writes; per-branch (pr-prep) reads.
- *Trigger:* linguistic (verification) → file write (artifact) → workflow consumption (pr-prep).
- *Authority:* the log + a completeness-check rule.
- *Evidence-format:* structured markdown log, one entry per claim, with commit-SHA / hunk anchors.

**Pros / Cons:**
- + Makes verification *visible* to the human reviewer (currently invisible).
- + Creates a reusable artifact other workflows can cite (a regression test fails → diff verification log → see if this surface was ever verified).
- + Forces the gap to surface — "no verification recorded for files X, Y" is a precise audit signal.
- − Adds write overhead to every verification (might trigger skipping if friction is too high).
- − Log can be falsified the same way claims can; not a stronger guarantee, just a more visible one.
- − Coupling `code-review` to the log adds reading load to the critic stage.

---

### Path 8: Split verification by failure-mode — different gates guard different failures

**Mechanism:** Acknowledge that the two skills guard genuinely different failure modes (the Phase 0 decision record already says this) and refuse to combine them into one gate. Instead, instantiate **three distinct gates**, each named after its failure mode, each fired at its right scope:
1. `regression-gate` (executed evidence): tests run, exit code 0, captured output. Fires per-task during execution. Powered by `verification-before-completion`.
2. `critic-gate` (analytical evidence): `code-review`'s critic ensemble, no executed code required. Fires per-branch at pr-prep step 3. Powered by `code-review`.
3. `packaging-gate` (presentation evidence): commit hygiene, PR description present, size justified, dependent PRs handled. Fires per-PR at pr-prep step 4–6.
Each gate is independently invokable. CLAUDE.md routes by *which failure the user is worried about*, not by lifecycle position. PR-prep becomes the workflow that *sequences all three*; the gates can also be invoked in isolation for ad-hoc work.

**Failure mode guarded against:** Confusion-of-gates. Currently, an agent reading the CLAUDE.md routing can plausibly think `verification-before-completion` is doing the work that `code-review` does (and vice versa). The two skills' failure-mode descriptions are not currently mapped to *named gates with stable identities*. This path makes the failure-mode-to-gate mapping the load-bearing routing dimension.

**Failure modes NOT guarded against:** Doesn't add new enforcement strength to any individual gate — each gate is exactly as strong as it was before. Doesn't handle the cases where a single failure spans two gates (a regression introduced by a refactor that critics also flag).

**Composition:** Each gate is a named skill or workflow. `pr-prep` is the **default sequencer**: `regression-gate → critic-gate → packaging-gate`. Ad-hoc work invokes whichever gate matches the worry. RPI Phase 4's "before declaring task complete" hook fires the regression-gate, not pr-prep in miniature. `finishing-a-development-branch` can wrap the packaging-gate.

**Implementation cost:** ~3 hours. Rename or alias `verification-before-completion` as the regression-gate, define the critic-gate as the `code-review` invocation, define the packaging-gate as a new short workflow extracted from pr-prep's tail. Update CLAUDE.md to add a "Which failure are you guarding against?" question to the routing.

**Where this puts the agent on the design-space dimensions:**
- *Scope:* per-failure-mode (cross-cutting; each gate has its own native scope).
- *Trigger:* failure-mode-keyed routing question, not lifecycle position.
- *Authority:* each gate has its own authority; the routing question chooses which.
- *Evidence-format:* per gate — executed transcript / structured critique / packaging checklist.

**Pros / Cons:**
- + Makes the failure-mode → gate mapping explicit; removes "which one do I run?" ambiguity.
- + Each gate is independently testable and invocable.
- + Maps cleanly onto the Phase 0 decision record's argument that the two skills are complementary.
- − Adds vocabulary the agent has to internalize (three gate names).
- − Risk of agent invoking only the gate matching their stated worry, missing failure modes they didn't articulate.

---

### Path 9: Verification embedded in the commit message itself; pr-prep validates trailer presence

**Mechanism:** Make verification evidence a **structured commit-message trailer**. Every commit on a feature branch must include a `Verified-by:` trailer naming the verification command and a `Verified-output:` trailer summarizing the result (`0 failures / 142 tests`, `exit 0`, etc.). The trailer is written by the agent immediately after running the verification command, while the output is still in the chat scrollback. `verification-before-completion` is reframed as: "before completing this commit, run the verification command AND write its result into the commit-message trailer." `pr-prep` adds one step: parse the trailers, surface any commits missing a `Verified-by:` trailer in the review artifact, and use the trailers to generate the PR's "Test plan" section automatically.

**Failure mode guarded against:** Verification evidence drifting away from the change that's supposed to be verified. Currently, a chat-claim "tests pass" can be temporally and contextually disconnected from any specific commit. Trailers bind verification to a commit SHA — `git log` queries can show "show me commits without verification trailers", and a future bisect can answer "was this regression introduced by a commit with a verification trailer or one without?"

**Failure modes NOT guarded against:** Trailer fabrication — agent writes a trailer claiming verification ran without running it. The hook in Path 5 would catch this; trailers alone do not. Doesn't catch the relevance gap (right tests for the change). Adds friction on every commit. Conventional-commits projects with rigid commit-message formats may find trailers awkward.

**Composition:** `verification-before-completion` reframed (description-only change) to write trailers; `pr-prep` gains a trailer-audit step; `code-review` can cite trailers when scoping its critics. RPI Phase 4's commit-discipline gets a new rule. `finishing-a-development-branch` can include trailer-completeness in its tests-pass check.

**Implementation cost:** ~2 hours. Document the trailer convention in CLAUDE.md, update `verification-before-completion` description (or wrap with a local skill), add the trailer-audit step to `pr-prep.md` step 3 or 4.

**Where this puts the agent on the design-space dimensions:**
- *Scope:* per-commit (trailer is bound to the commit SHA).
- *Trigger:* linguistic (still — the agent has to choose to add the trailer).
- *Authority:* the trailer text; weak (writable by anyone), but git-queryable.
- *Evidence-format:* structured commit trailer; human- and machine-readable.

**Pros / Cons:**
- + Verification binds to commits permanently; survives chat-transcript loss.
- + Auto-generates the PR's "Test plan" section.
- + `git log --grep` becomes a verification audit tool.
- − Trailer text is fabricable; no stronger than chat-level claims if discipline lapses.
- − Adds commit-message overhead.
- − Conventional-commits prefixes + trailers can feel heavy on small fixes.

---

### Path 10: Delete pr-prep entirely; absorb everything into the PR description template

**Mechanism:** Radical reframing. PR-prep currently encodes a lot of instructions imperatively ("now run X, now check Y"). Instead, replace the entire workflow with a single **PR description template** that has slots for every artifact pr-prep currently produces: verification evidence, review-fix loop outputs, size justification, dependent PR notes, pre-mortem reference, retrospective. The template is enforced by a `gh pr create --template` config + a PR-merge CI check that refuses to merge a PR with empty required slots. The agent's job becomes filling out the template; the structure of the workflow is encoded in the template's required fields. `verification-before-completion` produces the content for the "Verification" slot. `code-review` produces the content for the "Review evidence" slot. There is no "pr-prep workflow" anymore — there is only "fill out the PR template, gated by CI."

**Failure mode guarded against:** Workflow-vs-artifact mismatch. Currently, an agent can run all of pr-prep's steps and produce a PR with a sparse description that doesn't reflect any of them. The artifact (PR description) is the only thing the human reviewer sees; the workflow is invisible. This path makes the artifact the **single load-bearing thing** and removes the intermediate "workflow ran but artifact is empty" failure mode.

**Failure modes NOT guarded against:** Doesn't help with the *content quality* inside each slot — agent can write garbage into the "Verification" slot and CI can't tell. Doesn't address review-fix loop iteration (template doesn't encode the loop dynamics). Loses pr-prep's domain-specific imperative content (the failure-pattern coverage check, the size-check escalation logic, the 3-iteration ceiling) unless that content moves into checklists *inside the template*, which is awkward.

**Composition:** `verification-before-completion` and `code-review` become **content producers** for template slots. RPI Phase 4 → fills the template incrementally. The CI check is the gate. `finishing-a-development-branch` can be replaced by `gh pr create --template`. Subagents can be dispatched per-slot.

**Implementation cost:** ~5–6 hours. Design the template, write the merge-gate CI check, migrate pr-prep's imperative content to template-embedded checklists, update CLAUDE.md to reference the template-first model, deprecate pr-prep.

**Where this puts the agent on the design-space dimensions:**
- *Scope:* per-PR (one template per PR).
- *Trigger:* `gh pr create` → template fill-in → CI gate on merge.
- *Authority:* CI gate + template structural requirements.
- *Evidence-format:* PR description markdown (the GitHub UI is the rendering surface).

**Pros / Cons:**
- + Makes the artifact the single source of truth; no "workflow-ran-but-artifact-is-empty" gap.
- + Aligns with how humans actually consume PRs (they read the description, not the workflow log).
- + Encodes process-as-template; declarative rather than imperative.
- − Loses imperative content (escalation logic, loop dynamics) that doesn't fit in a template.
- − Slot content quality is unchecked; CI can verify presence but not substance.
- − Big migration; throws away a well-tuned 349-line workflow.

---

### Path 11: Verification as a per-step subagent dispatch (parallel to implementation)

**Mechanism:** Lean into `superpowers:subagent-driven-development`. For every implementation task, dispatch *two* subagents in parallel: one writes the code (the implementation subagent), one writes and runs the verification (the verification subagent). The verification subagent has the iron law of `verification-before-completion` and produces a captured-output artifact. The implementation subagent's "done" claim must reference the verification subagent's artifact, not its own self-report. The two subagents converge at a synthesis step that confirms (a) the code changed as expected (VCS diff) and (b) the verification confirms behavior (captured output). `pr-prep` keeps its full scope but no longer needs the per-task verification gate — verification already happened in the parallel dispatch.

**Failure mode guarded against:** Single-agent verification optimism. When the same agent implements and verifies, its theory of how the code should work biases the verification — it tests what it expected to test. A separate verification subagent, given the spec but not the implementation, designs verification independently. This catches "tests test what I wrote, not what the spec requires."

**Failure modes NOT guarded against:** Doubles compute cost per task. Doesn't help if the verification subagent inherits the same theory (which is likely if it's spawned from the same plan). The convergence step is a new failure surface (what if the two subagents disagree?). Doesn't address branch-scope packaging concerns.

**Composition:** Pairs with `superpowers:subagent-driven-development` directly — extends the single-subagent-per-task pattern to two subagents per task. `pr-prep` keeps full scope minus per-task verification (handled upstream). `code-review` runs at branch scope as before. RPI Phase 4 gets a parallel-dispatch instruction in the plan template.

**Implementation cost:** ~4 hours. Update the RPI Phase 4 instruction to dispatch a verification subagent alongside the implementation subagent, define the convergence step, document the failure-handling rule for subagent disagreement, update CLAUDE.md.

**Where this puts the agent on the design-space dimensions:**
- *Scope:* per-task, with parallelism.
- *Trigger:* explicit workflow invocation (RPI Phase 4 dispatches both).
- *Authority:* convergence between two independent subagents.
- *Evidence-format:* two separate subagent outputs (implementation VCS diff + verification transcript), reconciled.

**Pros / Cons:**
- + Decouples verification design from implementation theory.
- + Catches the class of bugs where "the tests test what the code does, not what it should do".
- + Naturally extends superpowers' subagent pattern.
- − Doubles compute cost.
- − Subagent disagreement adds a new failure surface.
- − Verification subagent quality depends on spec quality; weak spec → weak verification.

---

### Path 12: Two-track pr-prep — fast track skips the review-fix loop when verification is strong

**Mechanism:** Branch pr-prep into two tracks based on **strength of verification evidence accumulated during implementation**. If every commit on the branch has executed-evidence verification (e.g., a trailer per Path 9, or a hook artifact per Path 5, or a verification subagent per Path 11), pr-prep runs the **fast track**: skip the review-fix loop's full critic ensemble, run only the structural critic (`architecture-review`), and proceed directly to packaging. If verification evidence is sparse or missing (any commit lacks evidence), run the **slow track**: full review-fix loop with all critics as today. The model is: strong executed evidence reduces the need for analytical critique; weak evidence requires it as compensation.

**Failure mode guarded against:** Spending review-fix loop iterations on code that's already been thoroughly verified by execution. The current pr-prep treats every PR identically — small bug fix with strong tests and a large refactor with weak tests both go through the full critic ensemble. This path lets the verification investment pay off in cycle time.

**Failure modes NOT guarded against:** "Strong verification" can be fabricated (per Path 9's failure mode); the fast track trusts a signal that has its own failure mode. Analytical critique catches different bugs than executed verification (architecture, API consistency, performance under load) — skipping the critic ensemble loses those. Risk of the fast track becoming the default by erosion.

**Composition:** `verification-before-completion` (or its trailer/hook/subagent variant) becomes a **scope determinant** for pr-prep. The fast/slow choice is computed mechanically from branch state. `code-review` runs in full on the slow track, structural-only on the fast track. `finishing-a-development-branch` is unchanged.

**Implementation cost:** ~3 hours. Define the verification-strength heuristic (what counts as "strong" — trailer present? hook artifact present? subagent evidence?). Add the track-selection logic to `pr-prep.md` step 0 or 1. Document the fast-track's reduced critic set.

**Where this puts the agent on the design-space dimensions:**
- *Scope:* per-branch (pr-prep level); branch-state-dependent.
- *Trigger:* automatic, based on verification-evidence heuristic.
- *Authority:* the heuristic + the strong-evidence signal.
- *Evidence-format:* presence/absence of structured verification artifacts (trailers, hook outputs).

**Pros / Cons:**
- + Rewards verification discipline with faster pr-prep.
- + Aligns review effort with risk; small-and-well-verified PRs don't pay full critic cost.
- + Creates a soft pressure toward executed verification (faster path).
- − Risk of fast-track becoming default by erosion (skill drift toward the cheaper option).
- − Analytical critics catch bugs verification misses; skipping them is a real cost.
- − Heuristic-tuning is a new ongoing maintenance burden.

---

## Synthesis

### Design-space mapping (rows = paths; columns = key axes)

| Path | Scope | Trigger | Authority | Evidence format | Primary failure guarded |
|------|-------|---------|-----------|------------------|--------------------------|
| 1 (existing) | per-task + per-branch | linguistic (verification); workflow (pr-prep) | agent + analytical critics | chat transcript; review artifacts | regressions + packaging gaps |
| 2 (existing) | per-task + per-branch | linguistic + workflow | agent + critics | chat + review artifacts | redundancy reduction |
| 3 (existing) | per-task + per-branch | linguistic + workflow | named gates | chat + review artifacts | gate-confusion |
| 4 (existing) | none enforced | advisory | agent self-discipline | none required | (no real gate) |
| **5** | **per-commit** | **hook (mechanical)** | **hook + captured file** | **on-disk transcript** | **chat-discipline lapses** |
| **6** | **per-PR** | **push-to-remote + CI** | **CI signal** | **CI run** | **local-vs-CI drift** |
| **7** | **per-claim → per-branch** | **linguistic + file write + workflow consume** | **completeness check** | **structured markdown log** | **verification invisibility to humans** |
| **8** | **per-failure-mode** | **failure-mode-keyed routing** | **three independent gates** | **per-gate** | **gate-confusion (deeper than Path 3)** |
| **9** | **per-commit** | **linguistic (trailer write)** | **commit trailer** | **git-queryable trailer** | **verification-commit binding loss** |
| **10** | **per-PR** | **template + merge CI** | **template structure + CI gate** | **PR description markdown** | **workflow-vs-artifact mismatch** |
| **11** | **per-task (with parallelism)** | **explicit subagent dispatch** | **two-subagent convergence** | **two reconciled outputs** | **single-agent verification optimism** |
| **12** | **per-branch, evidence-conditional** | **automatic heuristic** | **verification-evidence strength** | **presence of structured artifacts** | **uniform review cost across diff risk levels** |

### Non-obvious candidates worth special attention

Three paths I'd flag as **non-obvious and worth special consideration** — not necessarily recommendations, but candidates the original four didn't touch and that change the question rather than answering it:

1. **Path 7 (pr-prep as audit log of verification).** This inverts the relationship that all four existing paths assume. Existing paths treat pr-prep as a workflow that *contains* or *triggers* verification; Path 7 treats verification as the operational reality and pr-prep as the read-side roll-up. The reframing changes what's load-bearing: instead of pr-prep being the place where verification happens, verification happens continuously and pr-prep is where it becomes visible to humans. The big win is *legibility* — currently a reviewer cannot tell from a PR which claims were verified. The big risk is that adding a log writes friction may suppress the verification itself.

2. **Path 8 (failure-mode-keyed gates).** This is the only path that names the failure modes as the routing dimension. All other paths route by lifecycle position (per-task, per-branch, per-PR). Routing by failure mode aligns with how the Phase 0 decision record already argues the two skills should be understood. The non-obvious move: instead of choosing one gate to dominate, accept that there are three distinct concerns and refuse to compose them under one label. The cost is vocabulary overhead; the win is that "which one do I run?" stops being ambiguous because the answer is *which failure am I worried about right now*.

3. **Path 11 (verification subagent in parallel to implementation).** This is the only path that introduces a *new structural failure mode* into the verification design — single-agent verification optimism, where the implementer's theory biases their tests. It's the only path that responds to a critique of `verification-before-completion` itself rather than to its composition with pr-prep. It uses superpowers' own `subagent-driven-development` machinery, so it's a natural fit; but it doubles compute and introduces a convergence-disagreement failure surface. Worth considering specifically when the user is worried about high-stakes correctness, not just process-shape.

Path 10 (delete pr-prep, PR template only) is the most radical and probably wrong, but it's worth keeping in the doc because it exposes a real assumption — that workflow shape needs to be imperative when it could be declarative. Path 5 (pre-commit hook) and Path 6 (CI authority) are non-obvious-but-conventional — they apply standard tooling moves to a problem that's currently solved by chat discipline.

### Recommendation (recommendation, not decision — the user decides)

If the user wants the **smallest delta from the existing plan**, Path 3 (already recommended in Phase 4) is the right answer. It's an explicit-naming layer on Path 1, costs almost nothing, and is reversible.

If the user wants to **address the failure mode `verification-before-completion` actually cares about** — that chat-level discipline lapses under pressure — Path 5 (pre-commit hook) is the strongest answer. It moves the gate below chat, where the discipline failure cannot happen. Combine with Path 3's naming convention for the inner/outer framing.

If the user wants to **change the question rather than answer it**, Path 7 (pr-prep as audit log) is the most generative reframing. It says the real failure isn't that verification doesn't happen — it's that verification isn't *visible*. That reframing is worth sitting with even if the final decision is Path 3.

The four existing paths and the eight new ones are all internally coherent. The decision is downstream of "which failure mode is the user most worried about *right now*" and "how much tooling investment is the user willing to make this quarter". This doc surfaces both questions; it does not answer them.

---

## Open questions the user must answer before this decides

1. **Which failure mode is the most painful in observed practice?** Chat-claims without verification (→ Path 5/9), local-vs-CI drift (→ Path 6), invisibility to human reviewers (→ Path 7), gate-confusion (→ Path 3/8), or single-agent verification optimism (→ Path 11)? The answer narrows the candidate set sharply.
2. **What's the tooling-investment budget?** Several paths require new infrastructure (hook in Path 5, CI gate in Path 6/10, log format in Path 7, dual-subagent dispatch in Path 11). A "markdown only, no new tooling" constraint reduces the candidate set to Paths 3, 4, 8, 9.
3. **Does the user want verification visible to *human* reviewers, or just to the agent?** Paths 7, 9, 10 make verification a first-class artifact for humans; Paths 1–6, 11–12 leave it agent-internal.
4. **Is the current pr-prep's review-fix loop pulling its weight?** Path 12's fast-track only makes sense if the answer is "sometimes no". If the loop's always pulling weight, Path 12 is incoherent.
