# DD: Improve the `performance-reviewer` critic persona (2026-08-17)

- **Goal**: Decide how to fix the `performance-reviewer` critic — worst measured track record of the code-review pipeline's personas (lowest ledger yield AND four provably false affirmative endorsements) — while composing with the upcoming execution-based upgrade of the code-fact-check stage.
- **Project state**: main · follows persona attribution (`docs/working/pipeline-persona-attribution-2026-08-17.md`) and decisions 031/033; upstream decision already taken: fact-check stage carries execution-based verification and its report feeds every critic · not blocked.
- **Task status**: complete (decision drafted Path A, autonomous; awaiting author review before SKILL.md edits land).

## Context

Attribution over 8 canon instances (`pipeline-persona-attribution-2026-08-17.md` §2 item 1):

- **Yield**: ~1 substantive ledger row per instance at best (fsc-A3 sole; lean-R2, csp-A3, pf-A5 co-source); **zero** in hygiene, deploy, corpus-ambers.
- **Four provably false affirmative endorsements**, one per instance across four instances:
  - lean: "no risk of `unavailable` accumulating in persisted blobs" (falsified by N8);
  - fscompat: "Hashing is computed once and reused (`callLlm.ts:121`, `streamLlm.ts:95`). `computeHash` is not called twice per request" — false; `getCachedResult` recomputes internally, and the bullet **cites the exact lines** whose callee falsifies it;
  - corpus: blob writes "debounced by zustand's own middleware" — false premise, contradicted by tech-debt's report in the same round;
  - deploy: restated the `/tmp` mechanism fact-check had just refuted as its own analysis.
- **Signature failure**: confident "this is free / already handled" verdicts without reading the mechanism.

**The load-bearing diagnostic** (from reading the two sample reports): all four falsehoods live in the **What Looks Good** section. The skill's Baseline Requirement (`SKILL.md:48-58`) gates *findings* with a hard evidence rule ("Findings without one of these two statements MUST NOT be emitted") — and across 8 instances no *finding* was provably false; both sample reports' findings are careful, hot/cold-tagged, and often explicitly speculative. What Looks Good (`SKILL.md:289-291`) has **no evidence rule at all**: "Note performance patterns in the diff that are correctly implemented… Confirms which parts don't need rework." The persona's one real strength is also clear: fsc-A3-class **cost-of-deployment reasoning** (fscompat Finding 1: cache-hit-rate collapse on Vercel `/tmp` quantified at $0.003→$0.40 per miss — sole-source, High, correct), which no move in the current move list actually names.

Design constraint (decided upstream): the fact-check stage is being upgraded to execution-based verification; its report feeds every critic. Candidates must consume that, not duplicate it.

## Step 1 — Diverge (13 candidates)

Pre-generation grep (`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "performance|critic|persona|endorse|fact-check"`): matches found for [critic, persona, endorsement, fact-check]:

- **[carried from 028-escalation-second-channel [10]]**: "dedicated soundness critic — mints new 🔴 authority from an unvalidated judgment at a full extra dispatch" → pre-prunes any candidate that adds a *new* critic dispatch to police this one.
- **[carried from 017-polyglot-test-hermeticity [9]]**: "an LLM critic is a detector, not an enforcement primitive" → the fix must live in evidence discipline + synthesis rules, not in trusting the critic to self-police via admonition alone.

Candidates (lenses: agent-text, agent-set, communication-topology, output-format, reframe):

| # | Candidate (one sentence) |
|---|---|
| 0 | **Status quo / do nothing** — rely on the upgraded execution-based fact-check alone; maybe verified inputs fix the endorsements. |
| 1 | **Retire the persona** — drop from the orchestrator; api-consistency + the planned runtime-falsification critic absorb the beat. |
| 2 | **Merge into architecture-review** — one structural critic carrying a scaling move-set. |
| 3 | **Narrow the mandate** to load/scale/deployment-cost reasoning with an explicit ban on unverified categorical endorsements ("this is free / already handled"). |
| 4 | **Convert What-Looks-Good into claims submitted to fact-check** — endorsements become verification *inputs*, never verdicts (topology change). |
| 5 | **Evidence-gate endorsements** — extend the Baseline Requirement symmetry: every What-Looks-Good bullet must carry a fact-check claim ID, a mechanism-trace citation, or an explicit `unverified` tag. |
| 6 | **Demote to contextual-only activation** (like architecture-review): run only when the diff's trigger list fires. |
| 7 | Give performance-reviewer its own execution/profiling budget. |
| 8 | **Delete the What Looks Good section entirely** — findings-only output. |
| 9 | **Post-draft self-verification pass** — before emitting, re-open every line range cited by an endorsement and every callee on the cited path. |
| 10 | **Full pivot to "deployment-cost analyst"** — rename and rescope to the fsc-A3 strength only (environment storage/lifecycle semantics → hit rates, quotas, $ per call). |
| 11 | Prompt admonition only — add "read the mechanism before endorsing" to Important (naive). |
| 12 | Ideal-if-free — per-review load-test harness with real measured baselines for every claim. |

Health check: initial set clustered on agent-text edits (3/4/5/8/9/11); added 1/2/6/10 (agent-set), 4 (topology), 8 (output format) to break dimensional anchoring — noted, resolved. Do-nothing (0), naive (11), ideal-if-free (12) present.

## Step 2 — Diagnose (7 constraints: 4 hard, 3 soft)

- **H1 (hard) — false-endorsement elimination.** No affirmative endorsement may assert a categorical runtime claim without evidence.
  `success:` in the next ≥3-instance canon replicate set, every What-Looks-Good/endorsement bullet carries a fact-check claim ID, a mechanism-trace citation whose quoted lines (including callees) contain the mechanism, or an explicit `unverified` tag; audit finds zero untagged categorical claims, and zero endorsements contradicting same-round fact-check or sibling-critic reports.
- **H2 (hard) — composes with the upgraded fact-check; no duplicated execution.**
  `success:` revised SKILL.md contains no instruction for performance-reviewer to execute, profile, or benchmark; categorical runtime endorsements are keyed to the execution-verified fact-check report by claim reference.
- **H3 (hard) — preserve the fsc-A3-class strength.**
  `success:` the mandate explicitly names deployment-environment cost semantics as a cognitive move, and an fscompat replay under the revised skill still yields the cache-hit-collapse/cost-per-miss finding as a High.
- **H4 (hard) — no added dispatch cost.**
  `success:` orchestrator dispatch count unchanged (no new agent, no second fact-check pass); per-instance token cost within ±10% of the E7 baseline for this critic.
- **S1 (soft) — yield recovery**: >1 substantive ledger row/instance where the diff genuinely has perf surface; honest "nothing here" (hygiene-style) is acceptable, forced findings are not.
- **S2 (soft) — rubric-synthesis compatibility**: verified endorsements should still be able to become Confirmed-Good rows (attribution rec 2: no Confirmed-Good on a bare static endorsement).
- **S3 (soft) — low churn**: prompt-level edits over orchestrator/agent-set restructuring.

## Step 3 — Match and prune

| # | Candidate | H1 | H2 | H3 | H4 | S1 | S2 | S3 |
|---|---|---|---|---|---|---|---|---|
| 0 | status quo | ✗ | ✓ | ✓ | ✓ | ✗ | ~ | ✓ |
| 1 | retire | ✓ | ✓ | ⚠ | ✓ | ✗ | ~ | ~ |
| 2 | merge into architecture | ~ | ✓ | ~ | ✓ | ~ | ~ | ✗ |
| 3 | narrow mandate + ban | ~ | ✓ | ✓ | ✓ | ~ | ~ | ✓ |
| 4 | endorsements → fact-check claims | ✓ | ~ | ✓ | ⚠ | ~ | ✓ | ~ |
| 5 | evidence-gated endorsements | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ |
| 6 | contextual-only activation | ✗ | ✓ | ~ | ✓ | ✗ | ~ | ✓ |
| 7 | own execution budget | ✓ | ⚠ | ✓ | ✗ | ✓ | ✓ | ✗ |
| 8 | delete What Looks Good | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ |
| 9 | self-verification pass | ~ | ✓ | ✓ | ~ | ~ | ~ | ✓ |
| 10 | deployment-cost analyst pivot | ~ | ✓ | ✓ | ✓ | ✗ | ~ | ~ |
| 11 | admonition only | ✗ | ✓ | ✓ | ✓ | ✗ | ~ | ✓ |
| 12 | per-review load-test harness | ✓ | ⚠ | ✓ | ✗ | ✓ | ✓ | ✗ |

Prune notes: **0** fails H1 — the false endorsements originate *downstream* of fact-check, in the critic's own new claims (deploy even contradicted the report it was handed). **1** ⚠ H3 — fsc-A3 was a sole-source High no other persona found. **2** ✗ S3 and inherits H1 unsolved. **6** fails H1 (orthogonal to the failure) and its trigger list ("caching, request handling paths…") fires on ~all 8 canon diffs anyway — near-zero savings. **7/12** violate the upstream constraint (H2) and H4. **11** refuted by evidence: `SKILL.md:313` already says "Read the actual implementation… Do not assume a function is cheap" and fscompat cited exact lines while still endorsing falsely. **9** alone is admonition-shaped (same enforcement gap as 11) but survives as a *component*. **4** as a standalone topology change needs a second fact-check pass (⚠ H4, per 028's carried pruning) — but its mechanism survives as the `unverified` tag inside 5. **10** amputates real co-source yield (lean-R2, csp-A3, pf-A5 were not deployment-cost findings).

Survivors → step 4: **[3∪5]** (they compose into one edit: narrowed mandate whose enforcement *is* the evidence gate — scored merged), **[4]**, **[8]**, and **[3 alone]** as the boring alternative.

## Step 4 — Tradeoff matrix and decision

| Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|
| **3∪5 evidence-gated endorsements + narrowed mandate** ★ | ~1-2 h prompt edits | low | 4/4 | tag theater — model stamps `[read:]` without opening callees (mitig., see stress test) |
| 4 endorsements → fact-check claims | ~half day (orchestrator loop change) | med | 3/4 (⚠ H4) | needs a second fact-check dispatch or the claims land nowhere |
| 8 delete What Looks Good | ~10 min | low | 4/4 | destroys the *true* endorsements too — rubric loses its Confirmed-Good input (✗ S2, ✗ S1) |
| 3 narrow mandate only | ~30 min | med | 3/4 (~H1) | ban without a per-bullet evidence mechanism = admonition; evidence says admonitions don't hold |

**Falsifiable hypotheses:**

- **[3∪5]**: If chosen, the next ≥3-instance canon replicate set shows zero untagged categorical endorsements and zero endorsements contradicting same-round reports, while an fscompat replay still produces the fsc-A3-class cache-cost finding, within one replicate cycle; counter-evidence = any bare "this is free / already handled" bullet, a `[read:]` tag whose cited lines don't contain the mechanism, or loss of fsc-A3 on replay.
- **[4]**: If chosen, endorsement-claims get execution verdicts and false ones die at stage 1 within one cycle; counter-evidence = pipeline cost rises >10% or claims are silently dropped by synthesis.
- **[8]**: If chosen, false endorsements go to zero immediately; counter-evidence = rubric Confirmed-Good coverage measurably thins on the perf domain in the next replicate.
- **[3]**: If chosen, endorsement wording softens within one cycle; counter-evidence = another lean/fscompat-shape falsehood, which the track record predicts.

**Stress tests applied:**

- *Boring alternative* (vs ★): candidate 8 (delete the section) is simpler and gets H1 — but it deletes the useful half: verified endorsements are exactly what attribution rec 2 wants Confirmed-Good rows built on, and "confirms which parts don't need rework" is real synthesis value. Candidate 3-alone is cheaper but is the admonition failure mode the track record already refuted. The tagging discipline earns its complexity. No matrix change.
- *Invert the thesis* (argue retirement, candidate 1): 1 sole-source row in 8 instances is thin; but that row (fsc-A3) was High-severity, $-quantified, and found by nobody else, and the persona co-sourced lean-R2/csp-A3/pf-A5. Marginal dispatch is already budgeted; retirement's savings are small and its loss concrete. Retained as **pre-named fallback**: revisit trigger added — if the next 3-instance replicate under the revised skill yields zero sole-or-co-source ledger rows, retire (candidate 1).
- *Failure-driven* (new failure modes of ★): (a) **tag theater** — fscompat proves the model will cite exact lines while wrong, so a bare citation cannot be sufficient evidence. Mitigation folded into the edit: `[read:]` is only valid for claims decidable from the quoted lines *plus every callee on the path*, and **categorical negative/absence claims are excluded from `[read:]` entirely** — they require a fact-check execution verdict or the `unverified` tag. Plus a synthesis-side backstop (rec 2 alignment): untagged or `[read:]`-tagged categorical runtime endorsements can never become Confirmed-Good rows. Risk stays low *because* enforcement is two-sided (emission rule + synthesis rule), honoring 017's "critic is a detector, not an enforcement primitive". (b) over-tagging noise — bounded by keeping the section short (≤5 bullets guidance).
- *Revealed preferences*: the same model under the same skill already obeys the Baseline Requirement on the findings side — 8 instances, careful hot/cold tags, honest "no baseline available — flagged as speculative" lines, zero false findings. The skill's own history is direct evidence that a mandatory per-item evidence field works where prose admonition fails. Confidence in ★ raised.

### Decision presentation

```
┌─ DECISION: fix performance-reviewer's false endorsements, keep its cost-of-deployment strength ─┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes                                 │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #     approach                        effort      risk    coverage      key downside
  ────  ─────────────────────────────  ──────────  ──────  ────────────  ──────────────────────────────
   3∪5  ★ evidence-gated endorsements   ● 1-2 h     ● low   ● 4/4 hard    ● tag theater (mitig.)
   8      delete What Looks Good        ● 10 min    ● low   ● 4/4 hard    ○ kills true endorsements too
   4      endorsements → FC claims      ◐ ~½ day    ◐ med   ✗ 3/4 hard    ○ second fact-check dispatch
   3      narrow mandate only           ● 30 min    ○ med   ✗ 3/4 hard    ○ admonition, already refuted

╭─ [3∪5] evidence-gated endorsements + narrowed mandate   ★ recommended ──╮
│ effort    1-2 h (prompt edits to one SKILL.md, ~5 edit sites)           │
│ coverage  4/4 hard · 3/3 soft (S1 partial: honest-empty allowed)        │
│ hypothesis  "If chosen, next ≥3-instance canon replicate shows zero     │
│             untagged categorical endorsements and none contradicting    │
│             same-round reports, and fscompat replay keeps fsc-A3,       │
│             within one replicate cycle; counter-evidence = any bare     │
│             'already handled' bullet, a [read:] tag whose lines lack    │
│             the mechanism, or loss of fsc-A3."                          │
│ stress-tests applied                                                    │
│   · failure-driven → excluded absence-claims from [read:]; added        │
│     synthesis backstop (no Confirmed-Good from static endorsement)      │
│   · boring alternative → rejected 8 (kills true endorsements) and 3     │
│     (admonition-only, empirically refuted)                              │
│   · invert thesis → retirement kept as pre-named fallback w/ trigger    │
│ key downside  tag theater (mitig. — two-sided enforcement)              │
╰─────────────────────────────────────────────────────────────────────────╯

▶ recommend [3∪5] evidence-gated endorsements + narrowed mandate · confidence 88% · Path A (dominates)
```

## Decision and rationale

**Chosen: [3∪5] — evidence-gate every endorsement and narrow the mandate, consuming the execution-upgraded fact-check report as the only admissible basis for categorical runtime endorsements.** Rationale in one sentence: every measured falsehood came from the one output section with no evidence rule, while the evidence-ruled sections produced zero falsehoods across the same 8 instances — so the fix is to extend the discipline that demonstrably works (the Baseline Requirement) to the endorsement side, key categorical claims to the upgraded fact-check's execution verdicts (composition, not duplication), and name the fsc-A3 deployment-cost strength as an explicit cognitive move so the persona's mandate centers on what it is actually good at.

See alternatives considered → **Pruned candidates and why** below.

### Concrete SKILL.md change list (`/home/node/.claude/skills/performance-reviewer/SKILL.md`)

**Edit 1 — replace the What Looks Good section (the failure site).** Current lines 289-291:

> ```
> ### What Looks Good
> Note performance patterns in the diff that are correctly implemented — proper pagination, efficient queries, appropriate caching. Confirms which parts don't need rework.
> ```

Replace with:

> ```
> ### Endorsements (evidence-gated)
>
> Note performance patterns in the diff that are correctly implemented — but an endorsement
> is a finding with the sign flipped, and it carries the same evidence burden the Baseline
> Requirement puts on findings. Every bullet MUST end with exactly one evidence tag:
>
> - `[fact-check: claim N — <verdict>]` — the claim was verified (for runtime behavior:
>   execution-verified) by the code-fact-check report. This is the ONLY tag that can carry
>   a categorical runtime claim ("X happens once", "no risk of Y", "Z is never called twice",
>   "already debounced/handled/free").
> - `[read: path:lines]` — permitted only for claims decidable from the quoted lines PLUS
>   every callee on the cited path, all of which you opened. A call site is not evidence
>   about its callee's internals. Never valid for categorical negatives or absence claims.
> - `[unverified — submitted as claim]` — you believe it but did not verify it. Phrase the
>   bullet as a checkable claim, not a verdict; synthesis treats it as a fact-check
>   candidate, never as a Confirmed-Good basis.
>
> Bullets without a tag MUST NOT be emitted. If an endorsement contradicts the fact-check
> report or a sibling critic's report from the same round, resolve or drop it — never
> restate a refuted mechanism as your own analysis. Keep the section to ≤5 bullets.
> ```

**Edit 2 — name the strength as a move.** After move 9 (current lines 159-164, "### 9. Check the asymptotic behavior, not just the constant"), append:

> ```
> ### 10. Price the deployment environment
>
> The platform's storage and lifecycle semantics are performance inputs: an ephemeral or
> per-instance filesystem collapses cache hit rates; quotas bound growth; cold starts reset
> warm state; serverless fan-out multiplies cold caches. When the diff changes where data
> lives or which environment runs the code, re-derive hit rates, quota headroom, and
> per-call cost (in dollars where the price is knowable) under the target platform's
> documented semantics — the same code can be near-free locally and expensive deployed.
> ```

**Edit 3 — sharpen the mandate sentence.** Current line 32:

> "Review code changes for performance problems. Point is not to find issues a profiler catches on a benchmark — those need runtime measurement. Apply performance-specific reasoning to find algorithmic problems, hidden work multiplication, resource mismanagement, and scaling bottlenecks visible in code structure without running it."

Append to that paragraph:

> "Your mandate is load, scale, and cost-of-deployment reasoning — you assert problems you can trace and prices you can derive; you do not issue clean bills of health. Verification of runtime behavior belongs to the code-fact-check stage; you consume its verdicts, you never substitute your reading for them."

**Edit 4 — update fact-check consumption for the execution upgrade.** In "Using the Code Fact-Check Report" (current lines 60-67), after the bullet list ending "**Focus on your cognitive moves**, which catch things fact-checking cannot." (line 67), add:

> ```
> - **Key categorical runtime endorsements to execution verdicts.** Where the fact-check
>   report carries execution-based verification, an execution verdict is the only
>   admissible basis for a categorical runtime endorsement (see Endorsements). If the
>   report refuted a mechanism, that refutation binds you — do not re-derive the refuted
>   mechanism from the code and present it as analysis.
> ```

**Edit 5 — extend the Important list.** Current lines 311-317 end with "…state your assumption and flag it as 'verify data size.'" Add two bullets:

> ```
> - An endorsement is a finding with the sign flipped and carries the same evidence burden.
>   Before writing "X happens once" or "no risk of Y", open every function on the cited
>   path — a call site that looks single-invocation can recompute internally.
> - Never emit a categorical negative ("not called twice", "no risk of accumulation")
>   without an execution-verified fact-check verdict; downgrade to an
>   `[unverified — submitted as claim]` bullet instead.
> ```

**Companion (out of this skill, cross-ref attribution rec 2):** add to `code-review` synthesis: no Confirmed-Good rubric row may rest on an untagged or `[read:]`-tagged categorical runtime endorsement — Confirmed-Good requires a fact-check execution verdict or scoping to what was actually checked. (One-line change; belongs to the code-review SKILL.md, tracked separately.)

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[0]: false endorsements originate downstream of fact-check, in the critic's own claims — deploy contradicted the very report it was handed. [1]: ⚠ H3 — fsc-A3 was a sole-source High; retained as pre-named fallback (see Revisit triggers). [2]: ✗ S3, and merging relocates the H1 failure without fixing it. [4]: needs a second fact-check dispatch (⚠ H4) [carried from 028-escalation-second-channel [10]: extra-dispatch policing pruned there]; its routing mechanism survives as the `unverified` tag. [6]: orthogonal to H1 and its trigger list fires on ~all 8 canon diffs anyway. [7]/[12]: violate the upstream no-duplicated-execution constraint (H2) and H4. [8]: discarded at step-4 stress test — kills the true endorsements the rubric needs (✗ S1/S2). [9]: alone it is admonition-shaped; absorbed into Edit 1's `[read:]` open-every-callee rule. [10]: amputates real co-source yield (lean-R2, csp-A3, pf-A5); absorbed as Edit 2's move 10 instead. [11]: empirically refuted — `SKILL.md:313` already admonishes "Read the actual implementation" and fscompat endorsed falsely while citing exact lines. [3-alone]: same admonition gap; absorbed into 3∪5.`
`Prior pruning grep: matches found for [critic, persona, endorsement, fact-check] — [carried from 028 [10]] and [carried from 017 [9]], both applied above.`

## Stress-test mitigations

- How to read: *Failure-driven* mitigation — tag theater (citing lines without reading callees, the exact fscompat failure) closed by excluding categorical negatives from `[read:]` entirely and adding the synthesis-side backstop; changed [3∪5]'s key-downside cell to `(mitig.)`.
- How to read: *Boring alternative* mitigation — candidates 8 and 3-alone evaluated as simpler substitutes and rejected on evidence (8 destroys verified-endorsement value; 3-alone repeats the refuted admonition pattern); no matrix change, confidence in ★ raised.
- How to read: *Invert-the-thesis* mitigation — retirement (candidate 1) argued sincerely and converted into the pre-named fallback with a thresholded revisit trigger rather than discarded silently.

## Consequences

- Easier: rubric synthesis gets machine-checkable endorsement provenance (tags), directly implementing attribution rec 2 for this persona; the fsc-A3 strength is now a named, repeatable move instead of an accident; false "already handled" verdicts cannot silently launder into Confirmed-Good rows.
- Harder: endorsement sections get shorter and more hedged (`unverified` bullets read weaker); reviewers lose the comforting-but-unearned "confirms which parts don't need rework" tone; a small prompt-length increase per instance.

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.

`if any post-edit canon replicate contains an untagged categorical endorsement or a [read:]-tagged absence claim → the gate is not holding, escalate to candidate 8 (delete the section). if the next ≥3-instance replicate set yields zero sole-or-co-source performance ledger rows → retire the persona (candidate 1, pre-named fallback). if fscompat replay under the revised skill loses the fsc-A3-class finding → Edit 2/3 over-narrowed, loosen the mandate. if the execution-verified fact-check upgrade ships with claim IDs in a different shape than "claim N" → update Edit 1/4 tag syntax to match.`
