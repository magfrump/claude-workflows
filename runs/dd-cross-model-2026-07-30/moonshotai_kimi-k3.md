# DD run — "Which actions should be taken next to improve this repo's code-review process?"

**Framing check:** the problem is concrete and uncontested (the evaluation doc states it in one paragraph: detects well, tiers badly; the blocking gate is unstable and structurally unreachable; attestations unchecked) — no Diamond 1. This is "what should we do," not "what's true" — no epistemic variant. Standard DD, steps 1–5. Note: §1.2 of the state doc explicitly says "route it through `divergent-design`" — this run therefore also serves as the required DD routing for the escalation-channel design (candidates 6/7/13 below are its three named options).

---

## Step 1 — Diverge

**1.0 Pre-generation grep:** `Prior pruning grep: not runnable in this setting`

**Prior-decision scan:** the state doc references decisions 004, 012, 021, 022. Decision 021 (reviewer context management, staged path) is *decided* — it enters as a precondition (constraint H6), not a candidate. The state doc's own §1 ordering is the relevant status quo, so it enters as **candidate 0** per the workflow.

**Candidates (14):**

0. **Doc-as-written (status quo):** implement §1.1 → §1.2-via-DD → §1.3 → §1.4 in the doc's order, exactly as specced.
1. **Minimal/defer** *(do-nothing)*: ship only already-decided work (021 Stage 1) plus the zero-cost trap-1 fix at `self-improvement.sh:1404`, and defer all skill changes until open questions #1–#4 resolve.
2. **Measurement-first:** before any skill edit, run the cheap queued arms — the §1.1 falsifier (k=3 agreement on 20 claims, open q #2), the MD1-R1 replication (open q #1, doc: "run this next"), and the 9-cell Confirmed-Good cross-check retrospective (open q #4) — and let their outputs set k and validate §1.3's cross-check.
3. **Resample the blocking verdict (§1.1):** run `code-fact-check` k≥3 on byte-identical prompts, cluster claims by (file, line-range, claim text), combine most-severe-wins, and log per-run verdicts as a tracked metric.
4. **Attestation hardening (§1.3):** require an `Evidence:` citation on every `✅ Confirmed Good` row and add a synthesis-stage cross-check that no Confirmed Good row contradicts the run's own fact-check report.
5. **Label single-sample verdicts at consumption points (§1.4):** anywhere a clean verdict is consumed as assurance (Gate 1h, pr-prep), require corroboration or an explicit "single-sample, not an attestation" label.
6. **Automated soundness channel (§1.2 option A):** extend the escalation rule so a quoted-intent-vs-quoted-code contradiction, affirmed by an automated corroboration pass, promotes a finding to 🔴 with no human involvement.
7. **Human-gating channel (§1.2 option C):** route findings where the reviewer affirmatively rejects a quoted intent claim with quoted contradicting code to a merge-gating human queue — the historical panel's ND2 behavior (Result 15) — surfaced through the morning-summary mechanism.
8. **Cross-vendor fact-check (§5.0 hypothesis):** scope a second vendor to the `code-fact-check` critic — actual role prompts per §5.1, k≥3 most-severe-wins, clean-verdict and abstention audits — once 021 Stage-1 context exists.
9. **Full parallel second-family pipeline** *(naive)*: run a complete cross-vendor duplicate review, diff-inline, over every change.
10. **Tier upgrade** *(naive/newcomer)*: move every critic to the top model tier and buy quality with compute.
11. **Abolish severity bands** *(unconventional)*: since tier is the least stable output (Results 1, 17, 14a), drop bands from pipeline output entirely — emit deduplicated issue-identity findings with evidence and let merge policy/humans assign severity.
12. **Total assurance stack** *(ideal-if-free)*: k≥3 × multi-vendor fact-check on every claim, agentic re-verification of every finding, nightly ground-truth regression replay over the §5.5 corpus, and a stability-metrics dashboard.
13. **Reframe to tests** *(unconventional)*: stop hardening the reviewer — a soundness finding blocks only when accompanied by a generated failing test (Thread 7's option promoted to the primary channel).

**Generation health check notes:**
- **Clustering fired:** 3/4/5/6/7 are five variants of "adopt one §1 item as the next action" (shared assumption: the answer is a single doc item executed alone). Violated by adding 0 (bundle, doc order), 2 (measure before acting), 12 (everything at once), 13 (the fix lives outside the review pipeline entirely).
- **Dimensional anchoring:** mapped onto the multi-agent taxonomy — *agent text*: 4, 5; *agent set*: 8, 9, 10; *dispatch order*: 3; *communication topology*: 6, 7, plus 4's synthesis cross-check; *something else*: 11 (output contract), 13 (assurance moved to tests), 2 (measurement), 0/1 (sequencing). Max 3 on any dimension — no anchoring.
- **Missing perspectives:** do-nothing (1), naive (9, 10), ideal (12) present.
- **Vagueness:** 13 tightened from "invest in tests" to the failing-test-as-channel mechanism; all others name a concrete artifact.

```
◇ step 1 diverge    14 candidates (inline; no working doc in this setting)
◇ step 2 diagnose   10 constraints (6 hard · 4 soft)
◇ step 3 match      5 of 14 survived → [3] [2] [7] [0] [8]
```

---

## Step 2 — Diagnose

**Decision goal (one line, used in the step-4 banner):** *Pick the next action(s) that make the pipeline's blocking signal trustworthy — detection is stable, so target the unstable promotion verdict (Result 14a), the unreachable soundness class (Result 15), and unchecked attestations (Result 12) — without re-opening §2-settled questions or corrupting the measurement arms.*

**Hard constraints:**

- **H1 — Evidence-direct target.** The action must target a failure mode with an observed instance, not a hypothetical capability gap.
  `success: the action's motivating failure cites a specific Result number or §5.0 finding name plus diff ID (ND2 2d0ee3c, MD1 d86d2dc..d90d6bb, D2); an action whose premise has no observed instance — or is contradicted by one — scores ✗`
- **H2 — No re-opening settled ground (§2).**
  `success: the action's mechanism contains none of the six §2-closed items (gating on 🟡-vs-🟢; haiku critics; sonnet without role-skill prompts; reviewer=fixer; generalist restructure; treating single-family panels as sufficient), checked item-by-item against the §2 list`
- **H3 — Arm comparability preserved (§4 / §5.1).**
  `success: every number the action produces is labeled with its arm/config per the §4 table and compared only within a comparable row (OpenRouter sweeps vs Result 10 only); a measurement action with no declared config column scores ✗`
- **H4 — Trap hygiene (§5.4).**
  `success: any action touching historical rubrics or pre-fix state names (a) content-based rubric selection by commit SHA + run date, not filename (the live :1404 bug), (b) the acceptance-filter caveat on any retrospective claim, (c) detached-worktree reconstruction with verified absence of the rubric; actions not touching rubrics/pre-fix state score ✓ by N/A`
- **H5 — No new single-sample assurance surface (Results 12, 14a; H5-widened §5.3).**
  `success: every new verdict, label, or gate the action introduces is either computed from ≥2 independent samples combined most-severe-wins, or labeled at its consumption point (Gate 1h, pr-prep) as single-sample/non-attesting; a new unlabeled single-sample output consumed as assurance scores ⚠`
- **H6 — Cross-vendor diff work only on Stage-1 context (§5.0 / decision 021).**
  `success: any action running non-incumbent vendors over diffs lists "021 Stage-1 changeset + enclosing files" as an explicit precondition; cross-vendor comparison over raw single-commit diffs scores ✗ (sibling-commit FP class, §5.0)`

**Soft constraints:** **S1** cheap-first (≤ ~1 engineer-week preferred — the doc's own economy: §1.1 "cheap", §3 #4 "cheap to test retrospectively") · **S2** converts an invisible coin flip into a logged metric (§1.1 verdict logging; §5.0 abstention-rate reporting) · **S3** advances the second corroboration channel for soundness-class findings (§1.2; Result 15 — "not in question is that the gap is real and observed") · **S4** composes with decided work (021 staged path; §2 "the two compose") rather than substituting for it.

---

## Step 3 — Match and prune

**Compatibility matrix** (key: ✓ addresses well · ~ partial/conditional · ✗ doesn't address · ⚠ actively makes worse; `*` = fixed by sketch below):

| # | Candidate | H1 | H2 | H3 | H4 | H5 | H6 | S1 | S2 | S3 | S4 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Doc-order | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ |
| 1 | Minimal/defer | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ~ |
| 2 | Measurement-first | ✓ | ✓ | ✓ | ~* | ✓ | ✓ | ✓ | ✓ | ~ | ✓ |
| 3 | k≥3 fact-check | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| 4 | CG-evidence | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ✓ |
| 5 | Labeling | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ |
| 6 | Auto-soundness | ✓ | ✓ | ✓ | ~ | ⚠ | ✓ | ~ | ✓ | ✓ | ✓ |
| 7 | Human-gate | ✓ | ✓ | ✓ | ~* | ✓ | ✓ | ~ | ~ | ✓ | ✓ |
| 8 | Vendor fact-check | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ✓ | ~ | ✓ |
| 9 | Full 2nd pipeline | ~ | ~ | ✗ | ~ | ✗ | ✗ | ✗ | ~ | ~ | ✗ |
| 10 | Tier upgrade | ✗ | ✓ | ✓ | ✓ | ~ | ✓ | ✗ | ✗ | ✗ | ✗ |
| 11 | Abolish tiers | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ~ | ~ | ~ |
| 12 | Total stack | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ |
| 13 | Test-gen channel | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ | ~ |

**Discards:**
- **[1]** leaves every §1 observed failure unaddressed (S2/S3 ✗); its one worthy component — the `:1404` trap-1 fix — is zero-cost hygiene, folded directly into the decision.
- **[4], [5]** survive the matrix cleanly but are **sub-threshold** per DD's own rule (hours-scale, no tradeoff, uncontested, low reversal cost) → exit the competition into the portfolio as log-row-scale changes; 4's cross-check half is additionally gated on open-q-#4's retrospective (day-scale, part of 2).
- **[6]** ⚠ on H5 — a fully automated, single-sample blocking gate recreates the exact Result-14a failure one channel over; and H7/§5.4-trap-4 (the same docstring has now beaten two agents in two arms) makes an auto-*blocker* the riskiest possible form. Its fixed form (k≥3 trigger + human gate) is the composition 7∘3 — discarded in favor of that composition.
- **[9]** ✗ H3/H6 — §5.0 measured this: diff-only vendor review is the sibling-commit FP machine and cross-family consensus *amplified* the error; §5.1 forbids conflating it with the pipeline; §5.0's own recommendation is the scoped form (8).
- **[10]** ✗ H1 — targets no observed failure. The observed failures are stability/gap/attestation, not tier quality: Result 8a (role prompt moved sonnet 0/2→2/2), Result 13 (all three tiers recovered ND3's blocker), H4 falsified as stated ("config, not model"); §5.0 shows blind spots are family-correlated, which a bigger same-family model cannot fix.
- **[11]** dominated for this decision — its valuable kernel (gates key on issue identity, not bands) is already §2-settled and adopted here; its radical remainder breaks the band comparability open q #3 and the historical human panels (Result 8b history) rely on, at ✗ S1 cost, while 3 stabilizes the one band that gates for ~2–4 days. Revivable if band noise persists as a *reporting* problem after gating is stable.
- **[12]** composite of 3+4+5+7+8 — evaluated via its components, which is the grain this matrix and the task's portfolio note require; ✗ S1 as a single "next" action.
- **[13]** no observed success instance: Result 15 records the ND2 defect as "invisible to tests" — authoring the test is the bottleneck, and nothing measured shows the pipeline can do it. Retained as a revisit trigger and as a preferred resolution artifact inside 7's queue.

**Fix sketches for survivors:**
- **[2]** (H4 ~): apply the `:1404` fix *before* the 9-cell retrospective; select rubrics by content (SHA + run date); reconstruct MD1 pre-fix state in a verified detached worktree per §5.5.
- **[7]** (H4 ~): double-quote trigger — quoted intent claim + quoted contradicting code + explicit reviewer rejection — and resample the *trigger itself* through 3's k≥3 machinery so routing isn't a new single-sample gate; cap and log queue volume.
- **[3]** (S3 ✗ is structural — accepted; portfolio covers via 7): scope resampling to promotion-candidate claims to bound the ~3× token cost; pre-flight the §1.1 falsifier to set k empirically.
- **[8]** (H6 ~): hard-sequence behind 021 Stage-1; run the vendor under actual role prompts per §5.1; audit clean verdicts and abstention rate (the harness already records both).
- **[0]** (S1 ~): reorder serial → cheap-parallel; its content is adopted wholesale — only its schedule is its weakness.

**Survivors (5): [3], [2], [7], [0], [8]**

---

## Step 4 — Tradeoff matrix and decision

| Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|
| **[3]** k≥3 most-severe-wins | ~2–4 eng-days; ~3× fact-check-stage tokens/run | **Low** — over-promotion bounded by the observed under-calling baseline (§1.1) (mitig.) | 6/6 · soft 3/4 | Stabilizes only the channel that exists; ND2-class gap + Confirmed-Good attestation untouched (mitig. via portfolio) |
| **[2]** Measurement-first | ~3–5 eng-days on the existing §5.5 harness | **Med** — blocking channel stays single-sample during the window; garbage-in risk if :1404 unfixed (mitig.) | 6/6 · soft 3/4 | Produces knowledge, not assurance — delays the doc's highest-leverage fix (mitig.: day-scale/week-scale split) |
| **[7]** Human-gate channel | ~2–3 eng-days + standing triage per routed finding | **Med** — trigger instability and queue fatigue (mitig.: trigger inherits 3's resampling; volume logged) | 6/6 · soft 3/4 | Standing human dependency in a headless-tuned pipeline (mitig.: morning-summary surfacing) |
| **[0]** Doc-order | ~8–12 eng-days serial | **Med** — order asserted, not derived: over-provisions k if the falsifier passes; validates §1.3's cross-check in production rather than retrospectively | 6/6 · soft 3/4 | Serial schedule ignores the doc's own cheap-first options (§1.1 falsifier; §3 "run this next") |
| **[8]** Vendor fact-check | ~5–10 eng-days after Stage-1 + per-sweep vendor cost (~$0.10/run scale, §5.0) | **Med** — abstention/false-attestation artifacts (D2; H5-widened) (mitig.: audits); hypothesis-stage evidence | 5/6 (H6 preconditioned) · soft 3/4 | Blocked on Stage-1; buys coverage, not stability — composes with, never substitutes for, 3 (§2) |

**Falsifiable hypotheses:**
- **[3]** *If chosen, J_self on 🔴 rows rises from 0.14–0.25 to ≥0.6 within the next 10 full-pipeline runs, and per-run verdict disagreement becomes a logged metric; counter-evidence = ≥90% agreement on the 20-claim pre-flight sample (drop to k=2 per §1.1) or J_self🔴 unchanged after 10 runs.*
- **[2]** *If chosen, within 2 weeks we hold: a measured verdict-disagreement rate setting k (q #2), a replicated or refuted MD1-R1 recovery (q #1), and a retrospective verdict on the cross-check (q #4); counter-evidence = any arm inconclusive from harness corruption (:1404), or >30% disagreement on the 20-claim sample — instability worse than modeled, meaning the skill fixes should not have waited even days.*
- **[7]** *If chosen, the ND2 replay (ground-truth 2d0ee3c) is promoted to merge-gating status instead of filed 🟢 within one replay cycle; counter-evidence = replay still files 🟢 (trigger misfires), or >30% of routed findings human-rejected as non-issues (over-routing).*
- **[0]** *If chosen, all four §1 changes are live within ~2 weeks and J_self🔴 ≥0.6 plus zero Confirmed-Good contradictions on MD1/ND2 replays within a month; counter-evidence = falsifier passes (1.1 over-provisioned at k=3) or the cross-check fails open-q-#4 retrospective validation.*
- **[8]** *If chosen, the first two post-Stage-1 sweeps surface ≥1 real defect the incumbent missed (§5.0 base rate: 4 defects over 4 diffs) with zero sibling-commit FPs; counter-evidence = sweeps add only findings the incumbent also made, or vendor clean verdicts fail audit (abstention artifact) twice.*

**Stress tests (moves chosen by trigger match):**

- **[3]** — **Boring alternative:** is k=2 enough? The §1.1 falsifier already answers this — *changed: k is set by a day-scale pre-flight measurement, not fixed at 3 (effort cell refined).* **Push to extreme:** k≥3 on every claim of every run triples the stage's token cost forever, and most-severe-wins monotonically raises the 🔴 rate — *changed: resampling scoped to promotion-candidate claims; block-rate logged to catch over-promotion (risk cell).* **Invert the thesis:** "gates shouldn't key on bands anyway (§2), so band instability is harmless" — what survives: §2 permits keying on the *blocking band*, and 14a shows that band flipping on identical input; only the **promotion decision** needs k≥3 — reporting bands may stay noisy. *Changed: scope narrowed, same conclusion.*
- **[2]** — **Invert the thesis:** "the failures are observed; measuring before fixing is procrastination." Lands a partial hit: §1.1's fan-out needs no new knowledge to start safely (most-severe-wins is dominance-safe under under-calling) — but the doc itself marks the falsifier "worth checking first" and q #1 "run this next." *Changed: 2 splits into day-scale (20-claim sample, 9-cell retrospective) vs week-scale (MD1 replication) — the day-scale pre-flights the fixes, the week-scale runs in parallel. This is the move that turns 2 from competitor into the portfolio's lead-in.* **Revealed preferences:** the program's costliest retraction (H4 falsified as stated, n=1 caveat) came from acting ahead of measurement; and trap 1 is *still live* at :1404 — *changed: :1404 fix made an explicit precondition of 2's retrospective arm.*
- **[7]** — **Failure-driven:** (a) over-routing floods the queue → rubber-stamping = false attestation in human form; (b) the routing trigger is itself a model judgment with 14a-class instability → a new single-sample gate (H5 violation). *Changed: trigger inherits 3's k≥3 resampling; queue volume capped and logged (risk cell held at ◐ only with this mitigation — strengthens the ordering 3-before/with-7).* **Push to extreme:** routing every intent claim in every diff → unusable queue — *changed: double-quote rule; route only affirmative contradictions, never mere absence of corroboration.* **Organizational survival:** overnight headless SI loops can't staff a live queue — *changed: routed findings surface through the existing decision-012 morning-summary mechanism; acceptable latency by design.*
- **[8]** — **Boring alternative:** is same-family resampling enough? No — §5.0: blind spots correlated within family (0/6 incumbent abstention vs Sol catching both for ~$0.10). *Confirms premise; no cell change.* **Invert the thesis:** "the vendor's wins were sibling-commit artifacts that Stage-1 makes moot" — false on evidence: three of four wins were Trap-4 true-mechanism cases (§5.0 explicit). *Changed: none; H6 precondition reconfirmed as load-bearing.* **Failure-driven:** new failure modes — vendor abstains its way to a perfect-looking clean record (D2 artifact; Kimi `content:null`); vendor false attestation (H5-widened). *Changed: clean-verdict audit + abstention-rate legibility made explicit spec preconditions (harness already implements both).*
- **[0]** — **Boring alternative:** do only §1.1 now — does full doc-order earn its serialization? No: 1.3/1.4 are hours-scale and independent; there is no reason to serialize them behind 1.1. *Changed: 0's serial schedule is its disqualifier — content adopted, schedule rejected.* **Invert the thesis:** "the doc's prioritization is the program's distilled judgment; re-ordering is hubris" — survives partially: the portfolio adopts the doc's *content* wholesale and optimizes only *order*.

**Decision presentation block:**

```
┌─ DECISION: make the code-review pipeline's blocking signal trustworthy ─┐
│ 5 candidates survived step-3 pruning · scored on the step-4 axes        │
└─────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint
  drill-down: name a # to expand that candidate's card (e.g. "show #2")

   #    approach                effort        risk       coverage    key downside
  ───  ─────────────────────  ────────────  ──────────  ───────────  ─────────────────────────────────
   3 ★  k≥3 fact-check         ● ~2–4d       ● low       ● 6/6 hard   gap + attestation untouched (mitig.)
   2    measurement-first      ● ~3–5d       ◐ med       ● 6/6 hard   knowledge, not assurance (mitig.)
   7    human-gate channel     ◐ ~2–3d+      ◐ med       ● 6/6 hard   standing human dependency (mitig.)
   0    doc-order verbatim     ○ ~2wks       ◐ med       ● 6/6 hard   serial order vs doc's own cheap-first
   8    vendor fact-check      ◐ ~1–2wk*     ◐ med       ◐ 5/6 hard   blocked on Stage-1; coverage≠stability
                                          (*after 021 Stage-1 lands)

╭─ [3] k≥3 fact-check, most-severe-wins   ★ recommended ──────────────────────────╮
│ effort    ● ~2–4 eng-days (+~3× fact-check-stage tokens/run)   risk  ● low      │
│ coverage  6/6 hard · 3/4 soft                                                   │
│ hypothesis  If chosen, J_self on 🔴 rows rises from 0.14–0.25 to ≥0.6 within    │
│   the next 10 full-pipeline runs, and per-run verdict disagreement becomes a    │
│   logged metric; counter-evidence = ≥90% agreement on the 20-claim pre-flight   │
│   sample (drop to k=2) or J_self🔴 unchanged after 10 runs.                     │
│ stress-tests applied                                                            │
│   · Boring alternative → k set by pre-flight falsifier, not fixed at 3          │
│   · Push to extreme → resampling scoped to promotion-candidate claims;          │
│     block-rate logged to catch over-promotion                                   │
│   · Invert the thesis → only the promotion decision needs k≥3; reporting        │
│     bands may stay noisy (scope narrowed)                                       │
│ key downside  stabilizes only the existing channel — ND2-class gap (Result 15)  │
│   and Confirmed-Good attestation (Result 12) untouched (mitig.: portfolio       │
│   covers via [7] and adopted [4]/[5]; see Stress-test mitigations, step 5)      │
╰─────────────────────────────────────────────────────────────────────────────────╯

▶ recommend [3] k≥3 fact-check, most-severe-wins · confidence 75% · runner-up [2],
  axis = assurance-now vs evidence-first — resolved: [2]'s day-scale measurements
  pre-flight [3] (they set k); its week-scale arm runs in parallel and gates nothing
```

**Decision path: C.** No single approach dominates at >80%: [3] and [2] score within ~1 cell, and the honest answer is a sequencing, not a winner. **Axis of disagreement:** *assurance-now vs evidence-first*. Project preference exists in the doc's own text and serves as the tiebreaker — §1.1 ("highest-leverage and it is cheap"; "falsifier worth checking first") and §3 ("Run this next") jointly imply: cheap measurements pre-flight the fixes; slow arms parallelize and gate nothing. No human is present, so per Path C: static block rendered (above), tentative recommendation recorded, no `AskUserQuestion` issued; the `## Round claim` subsection is skipped per this run's constraints.

---

## Step 5 — Decision record (inline)

**Goal:** Choose the next action(s) to improve this repo's code-review process from the evaluation program's established state.
**Project state:** Consumes `docs/thoughts/code-review-evaluation-state.md` (last verified 2026-07-30, arms through Results 11–17 + OpenRouter sweep) · standalone prioritization decision · not blocked.
**Task status:** complete (single-shot headless run; Path C tentative recommendation recorded statically — no live consultation possible).

### Context
The pipeline detects well and tiers badly. The entire blocking channel rests on a single sample of the least stable judgment in it (Result 14a; J_self🔴 = 0.14–0.25; Result 16); a whole defect class is structurally unpromotable (Result 15, ND2 filed 🟢 where the human panel gated the merge); the highest-assurance row is unchecked (Result 12, MD1 — the blocker filed under Confirmed Good with the disconfirming evidence in the run's own fact-check); clean verdicts are consumed as assurance at Gate 1h/pr-prep (§1.4). The state doc proposes §1.1–1.4, lists open questions #1–#4, and records the §5.0 cross-vendor hypothesis — candidates, not a decided order.

### Options considered
Fourteen candidates (0–13, step 1): the doc's own ordering, a defer/minimal baseline, measurement-first, each §1 item individually, the three §1.2 channel designs (automated / human-gate / failing-test), scoped and whole-panel vendor redundancy, a tier upgrade, abolishing bands, and the ideal total-assurance stack. Full analysis in steps 1–4 above.

### Decision and rationale
Adopt this ordered portfolio (the tentative Path-C recommendation):

1. **Today (day-scale):** fix the trap-1 rubric-selection bug at `self-improvement.sh:1404` (folded in from pruned [1]); run [2]'s day-scale measurements — the §1.1 falsifier (k=3 agreement on 20 claims) and the open-q-#4 retrospective on the 9 existing cells.
2. **Week 1:** implement **[3]** (k≥3 fact-check, most-severe-wins, per-run verdict logging) with k set by step-1's result — the doc's highest-leverage, cheapest fix, targeting the observed 14a instability; in parallel, adopt **[4]** (Evidence: citations; synthesis cross-check contingent on the retrospective) and **[5]** (single-sample labels at Gate 1h/pr-prep) as sub-threshold log-row changes.
3. **Next:** implement **[7]** — the human-gating channel for double-quote intent contradictions — as the §1.2 design choice this DD was convened to make: chosen over the fully automated channel ([6], ⚠ H5: a single-sample auto-blocker recreates 14a one channel over, and the same docstring has beaten two agents per H7/§5.3) and over failing-test-first ([13], no observed success instance; Result 15's "invisible to tests" makes authorship the bottleneck). Trigger resampled through [3]'s machinery; surfaced via the morning summary.
4. **Deferred, preconditioned:** **[8]** cross-vendor fact-check starts when 021 Stage-1 lands (H6) — role prompts per §5.1, k≥3 most-severe-wins, clean-verdict + abstention audits. Composes with [3] (coverage vs stability, §2); never substitutes.
5. **Parallel arm (gates nothing):** MD1-R1 replication (open q #1 — the doc's "run this next"; load-bearing for how much recall lives only in the Stage-3 agentic gate, §5.0/021).

Rationale in one line: the evidence supports the doc's *content* wholesale but not an untested serial *order* — the doc's own falsifier and "run this next" markers imply cheap-measure-first, fix-second, defer what's precondition-blocked.

See alternatives considered → Pruned candidates below.

### Pruned candidates and why
How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
`[1]: defers every observed §1 failure; :1404 kernel folded into portfolio. [4]/[5]: sub-threshold — hours-scale, no tradeoff; adopted as log-row changes. [6]: ⚠H5 — single-sample automated blocking gate recreates Result-14a one channel over; H7 doc-deference makes auto-blocking the riskiest form; fixed form = 7∘3. [9]: ✗H3/H6 — §5.0's measured sibling-commit FP machine; breaks §5.1 comparability; §5.0 recommends the scoped form [8]. [10]: ✗H1 — no observed target failure; contradicted by Results 8a/13 and H4-falsified ("config, not model"); family-correlated blind spots (§5.0). [11]: dominated — kernel (issue-identity gating) already §2-settled; radical form breaks band comparability open q #3 and human-panel history rely on; revivable if band noise persists as a reporting problem post-[3]. [12]: composite of 3+4+5+7+8 — evaluated via components. [13]: no observed success instance; test authorship is the bottleneck (Result 15); retained as revisit trigger and as a resolution artifact inside [7]. Prior pruning grep: not runnable in this setting.`

### Stress-test mitigations
- How to read: *Boring alternative* mitigation (on [3]/[0]) — k is set by the §1.1 20-claim falsifier pre-flight rather than fixed at 3; changed [3]'s effort cell and removed [0]'s reason to serialize.
- How to read: *Push to extreme* mitigation (on [3]) — resampling scoped to promotion-candidate claims with block-rate logging; changed [3]'s risk cell from "token cost and over-promotion unbounded" to low.
- How to read: *Invert the thesis* mitigation (on [2]) — split into day-scale (pre-flights the fixes) vs week-scale (parallel, gates nothing); converted the runner-up from competitor into the portfolio's lead-in.
- How to read: *Failure-driven* mitigation (on [7]) — routing trigger inherits [3]'s k≥3 resampling and queue volume is capped/logged, preventing a new single-sample gate and rubber-stamp fatigue; [7]'s risk cell holds at ◐ only with this.
- How to read: *Failure-driven* mitigation (on [8]) — clean-verdict audits and abstention-rate legibility made explicit preconditions (D2 artifact; H5-widened); risk held at ◐ with mitigation.

### Consequences
**Easier:** the blocking signal becomes reproducible (target J_self🔴 ≥0.6); verdict disagreement and queue volume become tracked metrics rather than invisible coin flips; soundness findings get a route to merge-gating matching historical panel behavior; the vendor addition is pre-solved for the day Stage-1 lands; measurement arms get clean inputs (:1404). **Harder:** ~3× token cost on the fact-check stage (scoped); a standing human-triage obligation in a headless-tuned pipeline; Gate 1h/pr-prep labels may slow sign-off; most-severe-wins may initially raise the false-block rate (monitored via block-rate logging).

### Revisit triggers
How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
`if k=3 verdict agreement ≥90% on the 20-claim sample → drop to k=2 (§1.1 falsifier). if J_self🔴 <0.6 after 10 full-pipeline runs post-[3] → redesign the combination rule. if >30% of [7]-routed findings are human-rejected → tighten the double-quote trigger. if the MD1-R1 replication fails → re-weight investment from detection config toward Stage-3 context (open q #1; H4 caveat). if the q-#4 retrospective shows the cross-check catches <1 known miss → descope [4] to Evidence:-only. if a third family-correlated blind-spot class surfaces after [8] → revive [9] (whole-panel vendor). if band noise persists as a reporting problem after gating stabilizes → revive [11].`