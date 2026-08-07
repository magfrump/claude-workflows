# Performance Review — code-review pipeline levers #3/#4 calibration

**Scope:** `HEAD~3..HEAD` (de9ccf7, 45fa1df, 2f5ad0b)
**Commit:** 2f5ad0b
**Date:** 2026-08-07
**Based on:** merged code-fact-check report (k=3), supplied by the orchestrator

---

### Data Flow and Hot Paths

The reviewed "code" is a pipeline specification. `skills/code-review/SKILL.md` is executed by an
orchestrator agent on every review pass; its prose directly determines how many tokens are moved
per pass and at what billing rate. The pipeline shape is: Step 1 scope/triage → Stage 1 fact-check
(k=1 since decision 031) → Stage 1.5 critic gating (lever #1) → Stage 2 critic fan-out (3–6 agents
in one parallel wave) → synthesis. This is the **hot path**: every pass of every review-fix loop
runs it, and the repo's own baseline measures a single 8-cell pass at **2,986,091 subagent tokens
across 38 agents (≈78,581 tokens/agent)**
(`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`, `token-ledger.md`).

The diff changes two levers on that path:

- **#3** converts the shared-context block from a *discipline note* (agents self-read via tools;
  measured shared prefix ≈330 tokens, capturing ~nothing) into **actual inlining** of the unified
  diff plus decision-021 enclosing-file context as the byte-identical cacheable prefix of every
  agent prompt, with a large-diff self-read fallback. Fan-out N per cell in the baseline is 3–6
  critics; the assembled prefix per cell was measured at 1,916–17,394 tokens.
- **#4** recalibrates the first-red short-circuit prose: the fact-check gate is now documented as
  ~73% of a pass when it fires but rare, and the critic-stage trigger as saving ~0.

The measurement docs under `runs/review-arms/baseline-2026-08-06/` are evidence artifacts, not
executed code — they carry no runtime cost and are reviewed here only as the **baselines** for the
findings below.

---

### Findings

#### Stale self-read instructions survive alongside the new inline mandate, so a literal orchestrator pays transport twice

**Severity:** High
**Location:** `skills/code-review/SKILL.md:340-341`, `skills/code-review/SKILL.md:634`, `skills/code-review/SKILL.md:1406` (vs. the new `skills/code-review/SKILL.md:99`, `247-250`)
**Move:** 1 (count the hidden multiplications) — per-agent token cost multiplied by fan-out
**Confidence:** High
**Classification:** Macro (changes what every agent prompt contains) / Hot path (every Stage-1 and Stage-2 dispatch of every pass)
**Baseline:** 2,986,091 subagent tokens / 38 agents ≈ 78,581 tokens per agent on the 8-cell single-pass baseline (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`); assembled shared prefix 1,916–17,394 tokens/cell (same doc, #3 table)
**Evidence:**
```
99:Diff delivery to agents is conditional (decision 032 #3, see [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)): for a normal-sized diff, inline it once as the shared cacheable prefix of every agent prompt;
340:3. Include the scope specification (e.g., "Review files changed on the current branch relative
341:   to main using `git diff main...HEAD`").
634:3. Include the scope specification so the agent runs its own `git diff`. If the scope is
1406:- **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.
```
**Legibility-target:** for-author

Step 1 and the new prefix section mandate inlining, but the three places an orchestrator actually
reads while *composing prompts* — Stage-1 dispatch step 3, Stage-2 dispatch step 3, and the
Important Reminders bullet — still instruct scope-only delivery and self-read. An orchestrator
following both gets the additive worst case rather than a substitution: the diff and enclosing
files are inlined in the prompt **and** each of the 3–6 critics is told to run its own `git diff`
and re-read the same files. On the corpus cell that is a 17,394-token inlined prefix per agent on
top of the tool-read traffic the inlining was meant to replace. The stale text also makes the
policy non-deterministic — two orchestrators on the same diff can pick different modes, which
destroys the cross-pass cache warmth #3 depends on. (Fact-check claims 21, 24, 25 flag these lines
as Stale; this finding is the cost consequence.)

**Recommendation:** Rewrite lines 340-341, 634, and 1406 to point at the Step 1 conditional rather
than mandating self-read — e.g. "Deliver the diff per the Step 1 inline/self-read decision; the
chosen mode must be identical for every agent in the pass." Do not leave any imperative that reads
as unconditional.

---

#### The inlined enclosing-file context has no numeric budget, and "up to the budget below" points at a budget that does not exist

**Severity:** High
**Location:** `skills/code-review/SKILL.md:247-250`, `skills/code-review/SKILL.md:261-266`
**Move:** 2 (what's the size of N?) and 4 (trace the memory lifecycle — here, context-window budget)
**Confidence:** High
**Classification:** Macro (unbounded inlined payload) / Hot path (assembled once per pass, replicated across every agent prompt)
**Baseline:** measured per-cell shared material ranged 7,663–69,575 chars (≈1,916–17,394 tokens), corpus being the outlier (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`, #3 table)
**Evidence:**
```
247:2. **The unified diff itself** (`git diff <scope>`), inlined — plus the decision-021 Stage-1
248:   enclosing-file context (the post-scope contents of the files the diff touches), up to the
249:   budget below. This is the bulk of the shared prefix; inlining it once and caching it across the
263:threshold (the ~1000-line / >40%-churn triage in Step 1) **or** the assembled shared block would be
264:very large, **fall back to the pre-#3 behavior**: pass the scope spec and let each agent run its own
```
**Legibility-target:** for-author

Line 248 forward-references "the budget below," but the size guard at 261-266 contains no number —
it defers to the ~1000-line/40%-churn triage and to the qualitative "would be very large." Those
two proxies measure the wrong quantity. The guard's stated binding constraint is the context
window, which is a function of **inlined bytes**, and the dominant term is the *enclosing-file
context* — the full post-scope contents of every touched file — not diff line count. The two are
only loosely coupled: a 60-line diff touching eight 1,500-line files inlines far more than a
1,200-line diff touching two small files, yet only the latter trips the guard. The corpus cell
already demonstrates the spread (69,575 chars, ~9× the fscompat cell) with no threshold separating
them. The failure mode is a cliff, not graceful degradation: the shared block is assembled before
dispatch, so an over-budget prefix truncates or fails every agent in the wave simultaneously.

**Recommendation:** Replace "up to the budget below" and "would be very large" with one measured
number on the quantity that actually binds — e.g. "assemble the block, measure it, and fall back to
self-read if it exceeds ~20k tokens (~80k chars)" — and instruct the orchestrator to size the
*enclosing-file set* (not just `git diff --stat`) before choosing the mode.

---

#### Placing the diff at prefix position 2 invalidates the whole shared block on every fix commit, forfeiting the cross-pass reuse that is #3's largest component

**Severity:** Medium
**Location:** `skills/code-review/SKILL.md:246-255`, `skills/code-review/SKILL.md:271-275`
**Move:** 8 (question the cache — invalidation and hit rate)
**Confidence:** High
**Classification:** Macro (prefix ordering is the cache's whole design) / Hot path (every non-first pass of every review-fix loop)
**Baseline:** #3's within-pass value ≈157,400 cost-equivalent tokens ÷ 2,986,091 ≈ **5.3% of input cost, 0% of token count**; the measurement doc names cross-pass warmth as the multiplier on top of that ("Where #3 does earn more: *across passes* in a fix loop … That's a loop-only multiplier on the ~5% above") — `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`
**Evidence:**
```
246:1. The goal preamble (what a review pass is).
247:2. **The unified diff itself** (`git diff <scope>`), inlined — plus the decision-021 Stage-1
251:3. The partial-scope labelling block, if the scope is partial (Step 1).
252:4. `## What this PR is trying to accomplish` — the `<pr-intent>` captured in Step 2.
253:5. `## Prior review findings (advisory …)` — `<prior-findings>` from Step 3, if any.
271:- Across loop passes, the block's prefix stays cache-warm up to the parts that changed: parts
272:  1–5 are stable across a fix→re-review cycle only if the diff/enclosing files are unchanged (a
273:  fix mutates them, so cross-pass reuse is partial); the fact-check summary (part 6) changes each
```
**Legibility-target:** for-author

Prompt-cache reuse is prefix-matched: the first differing byte invalidates everything after it. The
new ordering puts the *most* volatile large item — the diff, which by construction changes on every
fix commit — at position 2, ahead of four items (scope label, PR intent, prior findings) that are
stable across the entire loop. The stability rule at 271-275 acknowledges this only as "reuse is
partial," but the actual consequence is stronger: on pass 2 and after, the cache-warm region is
just part 1 (the goal preamble), so cross-pass reuse of the diff-sized bulk is ~0, not partial. The
same reasoning the doc correctly applies to part 6 (put the per-pass-volatile fact-check summary
last) argues for demoting the diff too. This does not affect within-pass fan-out reuse — the ~5.3%
stands — it forfeits the loop multiplier the measurement doc identifies as where #3 earns more.

**Recommendation:** Reorder the shared block by mutation rate, stable-first: goal preamble → partial
-scope label → PR intent → prior findings → **diff + enclosing-file context** → fact-check summary.
Then rewrite the 271-275 bullet to say the stable head survives a fix commit intact, which is the
behavior that ordering buys.

---

#### "0% of token count" holds for caching in the abstract but not for this change, which adds tokens agents previously never read

**Severity:** Medium
**Location:** `skills/code-review/SKILL.md:276-278`, `skills/code-review/SKILL.md:257-259`
**Move:** 3 (find the work that moved to the wrong place) and 5 (the N+1 analog — agents re-reading shared material)
**Confidence:** Medium
**Classification:** Macro (per-agent prompt size across the fan-out) / Hot path (Stage-2 dispatch, 3–6 agents per cell)
**Baseline:** the #3 saving model in `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md` is `prefix_tok × (N−1) × 0.9`; corpus row = 17,394 tok × 5 × 0.9 ≈ 78,273 cost-equivalent, against 17,394 × 6 ≈ 104,364 tokens of prefix actually processed across that fan-out
**Evidence:**
```
257:Agents still have repo access and may read further files on demand (e.g. a cross-file consumer not
258:in the enclosing set); inlining the diff + enclosing files just means they don't re-fetch the
259:*shared* material, so it can be cached.
276:- **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a
277:  billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect
278:  it to move the token-count ledger.
```
**Legibility-target:** for-author

The `prefix_tok × (N−1) × 0.9` model assumes every inlined token is one the agent would have paid
for anyway — true for the diff, questionable for the enclosing-file context. The same measurement
doc states the opposite about the pre-change behavior: "the enclosing-source files (the bulk)
aren't a shared prefix because each critic reads different parts." If critics read *different
parts*, inlining the *union* hands each agent material it previously skipped. Those extra tokens
are processed (so the `subagent_tokens` ledger moves **up**, not 0%) and billed at full rate for
the first agent, cache-read for the rest. Whether the net is a saving depends on the ratio of
union-size to per-critic-read-size, which no measurement in the repo pins down. The "free" framing
at 277-278 is therefore not established for the enclosing-file half of the payload — the diff half
is safe.

**Recommendation:** Soften 276-278 to scope the "0% token count / free" claim to the diff and
fact-check summary, and flag the enclosing-file inlining as expected to *raise* token count in
exchange for cost-rate saving. **Verify data size:** measure post-change `subagent_tokens` on one
cell against the 2.99M baseline before treating #3 as ledger-neutral.

---

#### The headline "~73% of the pass" rests on n=1 and the expected value is never computed

**Severity:** Low
**Location:** `skills/code-review/SKILL.md:493-499`
**Move:** 9 (check the asymptotic behavior, not just the constant) — here, the expectation vs. the conditional
**Confidence:** High
**Classification:** Micro (prose calibration, no dispatch behavior changes) / Hot path (read every pass by the orchestrator deciding whether to short-circuit)
**Baseline:** 238,155 tokens skipped / 324,979-token pass = 73.3%, single observation (candidate B, commit 6cf4b0d); trigger rate 0/8 canon and ~1 clean trigger in 225 commits (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`)
**Evidence:**
```
494:   the **entire** Stage-1.5/Stage-2 critic panel for this pass. This is the largest saving (the
495:   whole critic block) — measured at **~73% of the pass** on the one canon-adjacent case that
496:   fired it (`runs/review-arms/baseline-2026-08-06/hunt-verify/results.md`). But it is **not** the
499:   fact-check. So this trigger is high-value but low-frequency; do not expect it most passes.
```
**Legibility-target:** for-author

The prose is honestly hedged — it says "the one canon-adjacent case," names the low frequency, and
tells the reader not to expect it — which is a real improvement over the prior "the common case."
The residual issue is that a bolded **~73%** next to an unquantified "rare" invites budgeting on
the conditional. Composing the doc's own two numbers gives an expectation of roughly
73.3% × 1/225 ≈ **0.33%** of loop tokens, three orders below the banked levers (031 k=1 ≈ 29%,
032 #1 gating ≈ 17%). Stating that once would settle the question permanently. Note also that the
hunt found 2 candidates and only 1 fired, so even the 1-in-225 rate is an upper bound on firing.

**Recommendation:** Add one clause giving the expectation alongside the conditional — "≈73% when it
fires × a trigger rate near 1-in-225 ⇒ well under 1% expected" — and mark the 73.3% as n=1.

---

#### The inline-vs-self-read mode decision is reported in prose, so no downstream gate can check it

**Severity:** Low
**Location:** `skills/code-review/SKILL.md:265`
**Move:** 6 (identify the serialization tax — the mode must be consistent across every prompt boundary in the wave)
**Confidence:** Medium
**Classification:** Micro (reporting format) / Cold path (plan-summary emission, once per pass)
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
```
265:`git diff` and read what it needs. State which mode you used in the plan summary. (This is why Step 1
```
**Legibility-target:** for-automated-gate

The mode choice is the single decision that determines whether a pass pays inlined-prefix transport
or tool-read transport, and it must be uniform across all agents in the wave or the byte-identical
prefix requirement at line 269 is violated. "State which mode you used in the plan summary" is free
prose — a downstream gate or ledger script cannot parse it, and a mixed-mode pass would not be
detected. Directive for the gate: emit the mode as a fixed key-value line (e.g.
`shared-context-mode: inline|self-read`) plus the measured assembled-block size, so a gate can
assert (a) exactly one mode per pass and (b) that `inline` was not chosen above the size threshold
from the second finding.

**Recommendation:** Specify a literal `shared-context-mode: inline|self-read` line with the
assembled block size in the plan summary, and reference it from the size guard.

---

#### The 5.3% figure was measured on the pre-inlining structure and does not survive the change it motivated

**Severity:** Informational
**Location:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md` (#3 section), `docs/decisions/032-review-loop-token-reduction-levers.md:124-136`
**Move:** 8 (question the cache — hit rate after the change)
**Confidence:** High
**Classification:** Macro (the number every downstream doc now cites) / Cold path (documentation, not executed)
**Baseline:** ≈157,400 cost-equivalent ÷ 2,986,091 ≈ 5.3% of input cost, computed analytically from pre-change prompt sizes (`levers-3-4-measurement.md`, "Potential #3 saving IF the shared diff + fact-check report are inlined + cached")
**Legibility-target:** for-orchestrator-synthesis

Coverage note for synthesis, not an author action. The 5.3% is explicitly a *conditional projection*
— "**IF** the shared diff + fact-check report are inlined + cached" — computed against the
self-read structure. This diff implements that restructure, which means the figure is now a
prediction awaiting confirmation rather than a measurement, and findings 3 and 4 above both bear on
whether it will be met (prefix ordering suppresses the loop multiplier; enclosing-file union may
add token count). Decision 032 and log row 34 now carry 5.3% as settled. Every finding in this
review is structural reasoning over the specification; none of it substitutes for re-running one
cell post-change.

---

### What Looks Good

- **The core direction of #3 is right.** Re-sending the same shared material to 3–6 agents per cell
  is the pipeline's N+1 analog, and the measurement correctly diagnosed why the prior "discipline
  note" form captured nothing (~330-token shared prefix). Converting it to an actual inlined prefix
  is the only structure that can capture the effect.
- **Volatile-last ordering for the fact-check summary** (part 6, lines 254-255) applies exactly the
  right cache reasoning. Finding 3 asks only that the same reasoning be extended to part 2.
- **The >200-line rule on the fact-check summary** (deferred to Stage 2 step 5) already trims the
  one component that would otherwise grow without bound — a serialization-tax control that predates
  this diff and correctly survives it.
- **The size guard exists at all.** Recognizing that "for a large diff the window, not the bill, is
  the binding constraint" (line 261-262) is the right framing; only its threshold needs numbers.
- **Honest downgrades throughout.** "Measured benefit is modest," "this saves little in practice
  (measured: a critic-surfaced red saved 0)," and the removal of "the common case" all move claims
  toward their evidence. The prior review's empirical-warrant concern does not recur in the same
  form here — the new #4 prose names its single case as a single case.
- **Candidate A is documented as a negative result.** Recording that a genuine behavioral red still
  produced 0 saving is the finding that actually calibrates #4, and it was kept rather than dropped.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Stale self-read instructions contradict the inline mandate → double transport | High | `skills/code-review/SKILL.md:340-341,634,1406` | High |
| 2 | Inlined enclosing-file context has no numeric budget; guard measures diff lines, not bytes | High | `skills/code-review/SKILL.md:247-250,261-266` | High |
| 3 | Diff at prefix position 2 invalidates the block on every fix commit | Medium | `skills/code-review/SKILL.md:246-255,271-275` | High |
| 4 | "0% token count / free" not established for the enclosing-file half | Medium | `skills/code-review/SKILL.md:257-259,276-278` | Medium |
| 5 | "~73%" is n=1; expected value (~0.33%) never computed | Low | `skills/code-review/SKILL.md:493-499` | High |
| 6 | Mode decision emitted as prose, unparseable by a gate | Low | `skills/code-review/SKILL.md:265` | Medium |
| 7 | 5.3% is a pre-change projection now cited as settled | Informational | `levers-3-4-measurement.md`, `032:124-136` | High |

---

### Overall Assessment

The diff moves lever #3 from a form that provably captured nothing to one that can capture the
measured ~5.3% cost effect, and it recalibrates #4's prose toward its evidence — both are net
improvements to a hot path that costs ~2.99M tokens per 8-cell pass. The performance risk is
concentrated in the transition being incomplete rather than in the design being wrong: three
dispatch-time instructions still mandate the behavior the new policy replaces, so a literal
orchestrator pays for both mechanisms at once (finding 1); the size guard that protects the context
window keys off diff line count while the payload is dominated by enclosing-file bytes, with no
number to check against (finding 2); and the prefix ordering places the one item guaranteed to
change every pass ahead of four stable ones, forfeiting the cross-pass warmth the measurement doc
identifies as where #3 earns more than 5% (finding 3). None of these are large in absolute terms —
#3's entire ceiling is single-digit-% of cost — but findings 1 and 2 can make the pass *more*
expensive than before the change, which inverts the lever's sign. All three fixes are prose edits.
The honest caveat: everything here is structural reasoning over a specification whose only
measurements predate the restructure; one post-change cell measurement would settle findings 4 and
7 directly.

---

## Goal-Alignment Note
- Answered: yes — performance review of the pipeline the docs prescribe, 7 findings
- Out of scope: correctness/accuracy defects in the measurement-evidence docs (fact-check claims 11, 12, 13, 16 — miscounts and citation errors carrying no token cost); the actual token cost of re-running a cell post-change, which requires execution not available in a read-only review
- Escalate: findings 1 and 2 can raise per-pass cost above the pre-change baseline, inverting #3's sign — these should be fixed before the next production loop pass runs under the new policy, and they overlap the fact-check Stale claims (21, 24, 25), so a single edit pass closes both
- Questions I would have asked: Is there a post-restructure measurement of any cell against the 2.99M baseline, or is 5.3% still purely projected? Does the enclosing-file inlining cover all files the diff touches, or only those a critic's domain gate selects?
