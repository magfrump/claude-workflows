# DD: Synthesis-stage fragment composition (decision-record draft)

- **Goal**: Choose the synthesis-stage mechanism by which the code-review skill composes co-located finding/claim fragments from different sources into a unified finding — closing the GR1 false-negative class without reintroducing correlated-critics escalation.
- **Project state**: standalone DD session against `main` · feeds a future edit to `skills/code-review/SKILL.md` (not applied here — another session holds that file) · not blocked.
- **Task status**: complete (decision drafted; skill edit deliberately deferred).

---

## Context

Benchmark cell grafana-PR79265 (GR1, artifacts in `/workspace/external/crb-eval/grafana-PR79265/docs/reviews/`) was scored a **false negative** despite the pipeline detecting every fragment of the golden-comment bug:

- **Fact-check Claim 6** (`code-fact-check-report.md:106-116`, at `anonstore/database.go:72`): the `updateDevice` comment says "between the given times" but *"both bounds are derived internally from `device.UpdatedAt`"* — the mechanism, stated verbatim.
- **Fact-check Claim 7** (`:122-134`, at `database.go:88-99`): four causes of `rowsAffected == 0`; case (ii) dormant device 30–61 days, case (iii) future-dated `updated_at` past the +1m grace — the consequences. Reached the rubric as red **R3**.
- **Architecture finding 4** (constants duplicated; body text places *"the count window for the cap (`database.go:110`)"* beside *"the eligibility window for the update-only path (`database.go:81`)"*). Crucially, architecture **finding 2's Evidence block quotes the sibling derivation verbatim** (`CountDevices(ctx, time.Now().UTC().Add(-anonymousDeviceExpiration), time.Now().UTC().Add(time.Minute))` at `database.go:102-110`) and **finding 8's Evidence block quotes the defective one** (`device.UpdatedAt.UTC().Add(-anonymousDeviceExpiration), device.UpdatedAt.UTC().Add(time.Minute)` at `database.go:80-85`).
- **Security review** (`security-review.md:157, :274`): carried the clock-skew consequence and the +1m-grace analysis.

Four artifacts, one defect, unanimous — and no stage drew the one-line conclusion: *the `BETWEEN` bounds in `updateDevice` should derive from `time.Now().UTC()` like the sibling `CountDevices` call, which removes causes (ii) and (iii).* Every ingredient of that sentence exists as a verbatim quote in the run's own reports. The gap is a **composition** gap in Stage 3, not a detection gap in Stages 1–2.

**Boundary with the retired convergence-escalation mechanism** (must be treated explicitly): the retired rule used cross-critic agreement to *raise severity* — authority manufactured from correlated opinions (critics are the same model under different role prompts; see the Escalation Rule's "Why this changed"). This problem uses co-location to *compose content* into a better-stated finding at **unchanged severity**. The design below keeps that line bright: composition inherits the max fragment tier, never lifts, and never counts as Escalation-Rule corroboration.

---

## Options considered

### Pre-generation grep (step 1.0)

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "synthes|compos|converg|escalat"` → **matches found**, chiefly decision 028 (escalation second channel — the Soundness-Contradiction Channel's own DD) and 030/021. Dispositions:

- `[028 #2 🔴-capable corroboration bullet]` — **carried forward**: an unvalidated trigger must not reach 🔴 on its own authority. Encoded here as "composed row inherits max fragment tier, never lifts."
- `[028 #4 in-run human queue]` — **carried forward**: headless runs have no human at decision time; composition must resolve without a prompt.
- `[028 #7 severity-keyed softening]` — **carried forward**: never key banding on a critic's internal severity label; composition is severity-neutral by construction.
- `[021/030 #10 agentic multi-sample union]` — **carried forward** (cost): pruned there on token cost; the analogous "dedicated composition agent" candidate here is pruned on the same ~1M-tokens/pass economics.

### Candidates (diverge — one line each, generated before evaluation)

0. **Status quo**: rely on the existing evidence-gated channels (Soundness-Contradiction, Confirmed-Good cross-check, Escalation-Rule convergence notes) to eventually surface composition.
1. **Do nothing**: accept the GR1 class as a known miss; document it in the eval state doc.
2. **Mechanical line-overlap clustering pass** before rubric assembly: group all findings/claims by file + overlapping line ranges across sources, force a per-cluster question.
3. **Per-cluster composition question**: "is there a single root defect these fragments jointly describe? state it in one sentence with the fix" — answered inline at synthesis, logged either way.
4. **Fact-check merge composition**: make cross-claim composition a responsibility of the Stage-1 most-severe-wins merge (a "related claims → joint statement" step inside the merged report).
5. **Sibling-inconsistency detector**: a special-cased finding class — two call sites deriving "the same quantity" differently is itself a finding (`device.UpdatedAt` vs `time.Now()` for the same window).
6. **Strengthen per-critic prompts** to state conclusions and fixes, not observations ("every finding names the fix in one line").
7. **Cheap post-rubric self-check**: after assembling the rubric, ask "does any set of rubric rows citing the same lines jointly imply a defect none states?"
8. **Convergence joint-statement upgrade**: wherever the Escalation Rule records `Convergence:`, additionally require a one-sentence joint root-defect statement.
9. **`Fix:` column forcing**: mandate every 🔴/🟡 rubric row carry a concrete one-line fix cell; deriving it forces synthesis to resolve mechanism questions.
10. **Dedicated composition agent** (ideal-if-effort-free): a new Stage-2.75 sub-agent that reads all reports + diff and emits composed findings, verified via the Stage-2.5 submitted-claims intake.
11. **Human-facing clusters** (social lens): don't compose in-pipeline; present co-located row clusters to the author as adjudication prompts.
12. **Root-cause cross-references**: require rows sharing a root cause to name it (`Root: X — shared with R3/A1`), composing implicitly through the shared label.
13. **Observation-index extension**: extend the Stage-1 merge's existing observation index (built for the Confirmed-Good cross-check) with per-observation cited locations, powering any downstream clustering for free.
14. **Machine-readable `cites:` substrate** (interface lens): require critics to emit a structured list of *all* file:line references (Location + Evidence + body), enabling mechanical clustering.

### Generation health check

- *Clustering*: 2, 3, 7, 8, 9, 12, 13 all sit in the "synthesis-stage procedure" region — flagged; 4 (topology: Stage-1), 6 (agent text), 10 (agent set), 11 (social), 14 (data contract) were generated to break the anchor.
- *Missing perspectives*: do-nothing (1), naive brute-force (7), ideal-if-free (10) present.
- *Vagueness*: candidate 6 as stated is the vaguest; sharpened to "every finding carries a one-line fix" for scoring.
- *Dimensional anchoring*: dimensions covered — synthesis procedure (2/3/7/8/9/12), agent set (10), agent text (6), communication topology (4/13/14), social (11). Adequate spread.

---

## Diagnosis — constraints

Hard (each with a success observable):

- **H1 — composes the GR1 class.** success: replaying the mechanism against the GR1 artifacts produces a composed finding stating the unifying mechanism *and* the fix ("bounds should derive from `time.Now().UTC()` like the sibling `CountDevices` call"), traceable to fragment quotes.
- **H2 — no blocking authority from correlated agreement.** success: mechanism text states composed-row severity = max of fragment tiers (inherit-only, never lift), and composition explicitly does not count as corroboration under the Escalation Rule.
- **H3 — auditable/falsifiable in the house channel style.** success: skill text names explicit trigger conditions (what clusters, what question, what dispositions), requires fragment quotes verbatim as the composed row's evidence, and logs every cluster's disposition (compose / distinct) so precision is measurable after the fact.
- **H4 — false-composition guard.** success: replaying against a negative control (cal_com-PR11059: the salesforce `CalendarService.ts` cluster R1/R11/R12/R13 and the `parseRefreshTokenResponse.ts` cluster R5/R10/A16) leaves distinct defects distinct — no fabricated mega-finding, no deletion or rewording of fragment rows.
- **H5 — bounded token cost.** success: no new mandatory agent dispatch per pass (a pass is ~1M tokens measured; an added agent stage is ~65–100k+ every pass); the mechanism runs inline over artifacts already in Stage-3 context.
- **H6 — non-destructive.** success: fragment rows keep their tiers, wording, and evidence; the composed row is additive and cross-referenced both ways.

Soft:

- **S1** — lands where the chat synthesis's existing "Cross-critic findings" section can reuse it.
- **S2** — low prompt-surface churn (prefer one Stage-3 edit over touching every critic skill).
- **S3** — generalizes beyond the sibling-derivation shape (GR1) to other fragment shapes.
- **S4** — clustering input must include Evidence-block and body-text citations, not only the `Location:` header. success: the GR1 replay's decisive quotes (arch findings 2 and 8) are reachable — both live in Evidence blocks whose finding headers point elsewhere.

---

## Compatibility matrix (step 3)

| # | Approach | H1 compose | H2 no-escalate | H3 audit | H4 no-overfire | H5 cost | H6 non-destr | S4 body-cites |
|---|---|---|---|---|---|---|---|---|
| 0/1 | status quo / do nothing | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| 2+3 | clustering pass + forced composition question (combined: one mechanism) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 4 | fact-check merge composition | ~ (FC-only; can't see critic fragments — Stage 1 runs first) | ✓ | ✓ | ✓ | ✓ | ✓ | ~ |
| 5 | sibling-inconsistency detector | ✓ (GR1 by construction) | ✓ | ~ | ✓ | ✓ | ✓ | ~ (narrow — fails S3) |
| 6 | stronger per-critic prompts | ~ (no critic sees all reports; cross-source composition impossible per-critic) | ✓ | ~ | ~ | ✓ | ✓ | — |
| 7 | post-rubric self-check question | ~ (rubric rows lose body citations; GR1's decisive quotes not in row cells) | ✓ | ~ | ~ | ✓ | ✓ | ✗ |
| 8 | convergence joint-statement | ~ (clusters by same-concern, not same-lines-different-concerns — GR1's shape) | ✓ | ✓ | ✓ | ✓ | ✓ | ~ |
| 9 | `Fix:` column forcing | ~ (forces per-row resolution, not cross-row composition) | ✓ | ~ | ✓ | ✓ | ✓ | — |
| 10 | dedicated composition agent | ✓ | ✓ | ~ | ~ | ✗ (new agent every pass) | ✓ | ✓ |
| 11 | human-facing clusters | ✗ (benchmark still scores the miss; headless runs have no human — 028 #4 carried) | ✓ | ✓ | ✓ | ✓ | ✓ | ~ |
| 12 | root-cause cross-refs | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| 13 | observation-index extension | (substrate, not a mechanism — folded into 2+3) | | | | | | |
| 14 | `cites:` substrate | (substrate — folded into 2+3 as its input spec) | | | | | | |

**Survivors:** [2+3] (with 13/14 folded in as its input substrate, and 5 folded in as a named cluster shape), [7], [9], [4]. Fix sketches: [7]'s weakness (lost body citations) is fixable only by re-reading all reports post-rubric — at which point it *is* [2+3] run later and blinder; [9] survives as a cheap complement, not a competitor.

---

## Tradeoff matrix and stress tests (step 4)

*(matrix-analysis sub-skill not engaged: the axes here are mostly mechanically determined — cost is a known token figure, coverage comes from the two replays — and one candidate dominates at >80% confidence, the workflow's stated skip condition.)*

| Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|
| **[2+3] Composition cross-check** ★ | ~1 session (one SKILL.md section + rubric section + reminder bullet) | low | 6/6 | orchestrator authors one new sentence per composed row — grazes Mandatory Rule 1 (mitig. — entailment discipline, see below) |
| [7] post-rubric self-check | ~½ session | med | 4/6 (H1 ~, S4 ✗) | blind to Evidence/body citations; GR1 replay likely still misses |
| [9] Fix-column forcing | ~½ session | med | 4/6 (H1 ~) | per-row, not cross-row; composition only happens by accident |
| [4] FC-merge composition | ~½ session | med | 4/6 (H1 ~) | structurally cannot reach critic fragments (Stage 1 precedes Stage 2) |

**Falsifiable hypotheses:**

- **[2+3]**: If adopted, we expect a replay of GR1 to produce the composed `time.Now().UTC()` finding, and — within the next 5 benchmark cells containing ≥1 multi-source co-located cluster — ≥1 correct composed finding with **0 false compositions** (a composed row a human adjudicates as gluing unrelated defects). Counter-evidence: any adjudicated false composition, or 3 consecutive cells where clusters fire and every composed row is wrong or vacuous, or measurable cluster-examination cost >5% of a pass.
- [7]: If adopted, we expect a GR1 replay to compose from rubric-row cells alone within 1 replay; counter-evidence: replay shows the decisive sibling quote is unreachable from row cells (it is — see Replay below), refuting immediately.
- [9]: If adopted, we expect each 🔴/🟡 row's `Fix:` cell to state a concrete change; counter-evidence: R3-shaped rows filled with "investigate the four causes" (symptom restatement) rather than the composed fix.
- [4]: If adopted, we expect FC-only clusters (Claims 6+7) to yield a joint statement; counter-evidence: the joint statement still lacks the sibling contrast that lives in critic reports.

**Stress tests applied to [2+3]:**

- *Boring alternative* → [7] is the boring version; refuted by the GR1 replay itself: the two decisive verbatim quotes (arch findings 2 and 8 Evidence blocks) never reach rubric-row cells, so the post-rubric question is asked of an input that no longer contains the answer. The complexity of clustering over full reports earns its keep. ([9] is retained as a free complement — one column — but not as the mechanism.)
- *Invert the thesis* ("composition belongs upstream, in critics or fact-check") → no single Stage-1/2 agent ever holds all fragments: critics run in parallel and must not see each other's output (a load-bearing invariant), and fact-check precedes critics. Stage 3 is the only place all fragments coexist. Inversion fails on the pipeline's own topology.
- *Push to extreme* (2,000-line diff, 40 findings, dozens of clusters) → unbounded cluster enumeration could bloat synthesis. Mitigation adopted: only clusters containing ≥2 **distinct sources** and ≥1 🔴/🟡 row get the forced question; pure-🟢 clusters are logged unexamined. Caps the question count near the red/amber count.
- *Failure-driven* (new failure modes) → (a) **false composition**: guarded by the entailment discipline — every clause of the composed sentence must be traceable to a quoted fragment; if stating the root requires reading code beyond the quoted evidence, do not compose — log the cluster as `possible shared root — needs adjudication` at 🟢. (b) **Mandatory-Rule-1 breach creep**: the one permitted authored sentence is bounded (one sentence, mechanism + fix, entailed by quotes); anything more belongs to a sub-agent. (c) **duplicate surfacing**: the chat synthesis's existing "Cross-critic findings" section must *reference* composed rows rather than restate them.

**Decision presentation (Path A — one approach dominates, >80% confidence; non-interactive run, no prompt issued):**

```
┌─ DECISION: synthesis mechanism to compose co-located fragments into unified findings ─┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes                      │
└───────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high

   #     approach                     effort        risk    coverage      key downside
  ────  ─────────────────────────── ───────────  ───────  ──────────  ─────────────────────────────
  [2+3] ★ composition cross-check    ● ~1 session  ● low    ● 6/6 hard   ◐ one authored sentence/row (mitig.)
  [9]     Fix-column forcing         ● ~½ session  ◐ med    ◐ 4/6 hard   ○ per-row only, no cross-row
  [7]     post-rubric self-check     ● ~½ session  ◐ med    ◐ 4/6 hard   ○ blind to body citations
  [4]     FC-merge composition       ● ~½ session  ◐ med    ◐ 4/6 hard   ○ cannot reach critic fragments

▶ recommend [2+3] composition cross-check · confidence ~90% · no runner-up within 1 cell
```

---

## Decision and rationale

**Adopt a third required Stage-3 cross-check — the Fragment-Composition Cross-check — run immediately after the Soundness-Contradiction cross-check, before either deliverable is written.** It is the [2+3] combination: a mechanical co-location clustering pass over *all cited locations* (Location headers, Evidence blocks, and body-text `file:line` references — the S4 requirement, seeded from the Stage-1 observation index), followed by one forced, logged question per qualifying cluster: *is there a single root defect these fragments jointly describe that no single fragment states? If yes, state it in one sentence naming the mechanism and the fix, entailed by the fragments' own quotes; if no, record `distinct defects` with a one-clause reason.* A "yes" adds one composed row at the **max of the fragment tiers** (inherit-only, never lift, never Escalation-Rule corroboration); fragments stay in place and cross-reference it. Both dispositions are logged in a small rubric audit section, so the mechanism's precision has a denominator from day one — the same auditable, evidence-gated, capped-authority shape as the Soundness-Contradiction Channel, and the same shape decision 028 already litigated for what an unvalidated mechanism may and may not do.

Rationale in one sentence: Stage 3 is the only point where all fragments coexist, the mechanism's entire evidence base is quotes the run already produced (making it cheap, auditable, and falsifiable), and the two replays below confirm it fires on GR1 and stays quiet on the negative control.

[9] (`Fix:` cells on 🔴/🟡 rows) is adopted as a **complement** — one rubric column, independently useful — not as the composition mechanism.

See alternatives considered → **Pruned candidates and why** below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[0/1 status quo / do nothing]: fails H1 — GR1 is the observed miss; existing channels cluster by same-concern or intent-inversion, not co-located-different-concerns.` `[4 FC-merge composition]: Stage 1 precedes Stage 2, so critic fragments are structurally unreachable; the joint statement's sibling contrast lives in critic reports.` `[5 sibling-inconsistency detector]: absorbed — named as one cluster shape inside the winner's question, not a standalone special case (fails S3 alone).` `[6 stronger critic prompts]: no critic sees all reports; per-critic conclusions cannot compose across sources; high prompt churn (S2).` `[7 post-rubric self-check]: refuted by replay — the decisive quotes never reach rubric-row cells (S4 ✗).` `[8 convergence joint-statement]: clusters by same-concern; GR1's shape is different-concerns-same-lines, so it under-clusters exactly the target class.` `[9 Fix-column]: adopted as complement, pruned as mechanism — per-row, not cross-row.` `[10 dedicated composition agent]: fails H5 — new agent every ~1M-token pass [carried from 021/030 #10: agentic multi-sample union pruned on cost/latency].` `[11 human-facing clusters]: fails H1 headless [carried from 028 #4: a gate that never gates].` `[12 root-cause cross-refs]: labeling presupposes the composition it was meant to produce.` `[13/14 substrates]: folded into the winner as its clustering input spec.` `[028 #2 🔴-capable corroboration]: carried from 028 — encoded as inherit-only severity.` `[028 #7 severity-keyed softening]: carried from 028 — composition is severity-neutral.`

## Stress-test mitigations

- How to read: *Push to extreme* mitigation — bounded the forced question to clusters with ≥2 distinct sources AND ≥1 🔴/🟡 row; pure-🟢 clusters logged unexamined, capping cost near the red/amber count.
- How to read: *Failure-driven* mitigation — added the entailment discipline (every clause of the composed sentence traceable to a quoted fragment; otherwise log `possible shared root — needs adjudication` at 🟢 instead of composing), which is what keeps the mechanism inside Mandatory Execution Rule 1's spirit: collation of agent-produced content plus one bounded connective sentence, never fresh analysis.
- How to read: *Boring alternative* mitigation — retained [9]'s `Fix:` column as a complementary rubric change after the move showed it is nearly free and independently closes the "consequences without a fix" reading of R3.

## Consequences

Easier: GR1-class defects (fragments detected, conclusion uncomposed) surface as one actionable row with the fix stated; composed rows are human-verifiable in seconds (all evidence is verbatim quotes with `file:line`); the mechanism's precision is measurable from the logged dispositions; the chat synthesis's "Cross-critic findings" section gains a concrete substrate.
Harder: Stage 3 grows another required pre-deliverable pass (three cross-checks now); the orchestrator authors one sentence per composed row, a carefully-bounded exception to "orchestrator never analyzes" that future edits could erode; cluster bookkeeping adds modest synthesis tokens on finding-dense diffs.

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.

`if any composed row is adjudicated a false composition (glued unrelated defects) → tighten the entailment rule or revert to log-only.` `if 5 benchmark cells pass with clusters fired and 0 correct compositions → mechanism is vacuous; remove.` `if a prospective corpus of ≥10 correct compositions accumulates → consider letting a composed row participate in Escalation-Rule corroboration (mirror of 028's cap-raise precondition).` `if cluster examination measurably exceeds ~5% of a pass's tokens → move clustering into the Stage-1 observation index build.` `if critics gain structured cites: output (candidate 14 implemented) → replace the citation-harvest step with the structured field.`

---

## Replay validation

### Positive direction — GR1 (grafana-PR79265): would the mechanism have produced the composed finding?

**Clustering.** Harvesting all cited locations (headers + Evidence + body): FC Claim 6 (`database.go:72`), FC Claim 7 (`database.go:16, 88-99`), architecture finding 2 (Evidence quotes `database.go:105-118`, incl. the `time.Now().UTC()` derivation at `:110`), finding 4 (body cites `:81` and `:110`), finding 8 (Evidence quotes the `device.UpdatedAt.UTC()` bounds at `:80-85`), security review (`:157` restating FC-7; `:274` clock-skew on the `updateDevice` BETWEEN bound). All fall in `anonstore/database.go:72-118` — one cluster, **three distinct sources** (fact-check, architecture, security), containing a 🔴 row (R3). The forced question fires.

**Composition.** Joint statement, every clause entailed by a quoted fragment: *"`updateDevice` derives both `BETWEEN` bounds from `device.UpdatedAt` (arch f8 Evidence: `device.UpdatedAt.UTC().Add(-anonymousDeviceExpiration), device.UpdatedAt.UTC().Add(time.Minute)`; FC-6: 'both bounds derived internally from `device.UpdatedAt`') while the sibling admission check derives the same window from the clock (arch f2 Evidence: `CountDevices(ctx, time.Now().UTC().Add(-anonymousDeviceExpiration), time.Now().UTC().Add(time.Minute))`), which is what makes FC-7 causes (ii) dormant-device and (iii) clock-skew reachable — deriving the bounds from `time.Now().UTC()` like the sibling call removes both."* No fragment states this; the conjunction does. Composed row tier = max fragment tier = 🔴 (inherited from R3's fact-check `Incorrect (high, behavioral)` — no lift occurred). **The golden-comment finding is produced.**

**Surprise worth recording:** the two load-bearing quotes sit in architecture findings **2 and 8** — findings whose `Location:` headers point at *other* concerns (layering; arg-mutation). A clusterer reading only `Location:` headers (or only rubric-row cells, candidate [7]) never reaches them. S4 — harvest Evidence-block and body citations — is not a nicety; it is the difference between hit and miss on the very case that motivated the mechanism.

### Negative direction — cal_com-PR11059: does it over-fire?

Two qualifying clusters in `code-review-rubric-2026-08-20-review.md`:

1. **`salesforce/lib/CalendarService.ts`** — R1 (`:96` missing `prisma` import), R11 (`:55-99` unconditional OAuth round trip per availability query), R12 (`:84-86` `statusText !== "OK"` predicate), R13 (`:20,76-99` half-migration); sources: architecture, security, performance, fact-check. Forced question: single root defect no fragment states? **No** — no one-sentence mechanism+fix is entailed that covers a missing import *and* a wrong success predicate *and* a constructor-placement cost *and* a partial migration; the nearest common frame ("salesforce is half-migrated") is *already its own row* (R13), so the conjunction adds nothing absent from every fragment. Disposition logged: `distinct defects — nearest common context already stated as R13`. No mega-finding; all four rows untouched (H4, H6 hold).
2. **`parseRefreshTokenResponse.ts`** — R5 (`:5-27` `"[object Object]"` schema collapse), R10 (`:13-30` weaker schema for the less-trusted source; envelope noise), A16 (`:26` `refresh_token` literal one-way door). The run itself already adjudicated independence ("Independent of the `[object Object]` bug" in R10). Forced question: **No** — each row states its own mechanism and fix fully; composing would *erase* R10's recorded independence, the exact false-composition failure the guard names. Disposition logged: `distinct defects — independence explicitly established by R10`.

The mechanism stays quiet on both. The discriminator that does the work, extracted from the replays: **compose only when the conjunction adds a defect-or-fix statement absent from every fragment; when each fragment already states its own mechanism completely, the answer is "distinct" by construction.**

---

## Proposed skill-text sketch (NOT applied — target file is being edited by another session)

Target: `/workspace/skills/code-review/SKILL.md`. Four anchored insertions.

**(a) New required cross-check in Stage 3** — insert immediately after the `#### Soundness-contradiction cross-check` block (currently ending near line 934, before `#### Contrastive note`):

```markdown
#### Fragment-Composition cross-check (required before producing deliverables)

Immediately after the Soundness-contradiction cross-check, harvest every cited location
from every report in the run — `Location:` headers, `Evidence` blocks, and `file:line`
references in finding/claim body text alike (the Stage-1 observation index seeds this;
critic-report citations are added on top). Cluster them: same file, line ranges
overlapping or within ±15 lines. A cluster **qualifies** when it spans **2+ distinct
sources** (the merged fact-check counts as one source; each critic is one) **and**
contains at least one 🔴 or 🟡 finding. For each qualifying cluster, answer one forced
question and log the answer either way:

> Is there a single root defect these fragments jointly describe that **no single
> fragment states**? If yes, state it in **one sentence** naming the mechanism and the
> fix. If no, record `distinct defects` with a one-clause reason.

**Entailment discipline (the false-composition guard).** Every clause of the composed
sentence must be traceable to a fragment's own quoted evidence. If stating the root
would require reading code beyond what the fragments quote, do **not** compose — log the
cluster as `possible shared root — needs adjudication` and add it as a 🟢 Consider row
instead. When each fragment already states its own mechanism and fix completely, the
answer is `distinct defects` by construction — composition exists to state what only the
conjunction implies, never to staple complete findings together.

**On a "yes":**

- Add **one** composed row in the tier equal to the **maximum of the fragment tiers** —
  inherit-only, never a lift. `Source: Composition cross-check (fragments: <list>)`,
  `Severity: Composed (inherits <max fragment severity>)`.
- The row's evidence is the fragments' quotes **verbatim**, each with `path/to/file:line`,
  so the author can re-verify the composition in seconds without re-deriving it.
- Fragment rows are untouched: they keep their tiers, wording, and evidence, and gain a
  cross-reference to the composed row (e.g., `Composed into X1`). Composition is
  additive, never a merge-and-delete.
- **Composition grants no authority.** A composed row never counts as corroboration
  under the [Escalation Rule](#escalation-rule), never raises any fragment's tier, and a
  cluster of contextual-critic-only fragments composes at 🟢. This is the boundary with
  the retired convergence-escalation mechanism: that rule used correlated agreement to
  *raise severity* and was retired on measured evidence; this check uses co-location to
  *compose content* at unchanged severity. Severity continues to come only from the
  evidence-gated channels the fragments already passed through.
- Name the composition in the chat synthesis under **Cross-critic findings** (reference
  the composed row; do not restate it) and under **Actionable guidance**.

**Logging.** The rubric gains a `## 🧩 Composition check` section listing every
qualifying cluster — file, line span, fragment IDs, and disposition (`composed → X1` /
`distinct defects: <reason>` / `needs adjudication → C<n>`). If no cluster qualified,
render the single line "No multi-source co-located clusters qualified." The heading must
still appear so the check is auditable across runs and its precision is measurable.

Like the two cross-checks above, run this **before** writing either deliverable — it
changes the rubric's contents.
```

**(b) Rubric template** — add the `## 🧩 Composition check` section skeleton to the Deliverable-2 template (after `## ⏭️ Skipped Core Critics`), and mirror it in `test/skills/code-review/rubric-current-format.md` in the same commit (the format-contract bats suite asserts against it).

**(c) Important Reminders** — add one bullet:

```markdown
- **Co-located fragments get one composition question, at unchanged severity.** The
  Fragment-Composition cross-check clusters all cited locations (headers, Evidence, and
  body citations) across sources; a qualifying cluster's forced question is answered and
  logged either way; a composed row inherits the max fragment tier, never lifts, and
  never corroborates escalation. See
  [Fragment-Composition cross-check](#fragment-composition-cross-check-required-before-producing-deliverables).
```

**(d) Complement (optional, separable commit)** — add a `Fix` column to the 🔴/🟡 rubric tables requiring a concrete one-line change per row (candidate [9]); rows resolved by a composed row may point at it (`see X1`).

**Validation status to carry in the skill text once landed:** retrospective only (GR1 positive replay + cal.com negative replay, this document); per the 028 precedent, no authority increase (escalation participation) until a prospective corpus of ≥10 correct compositions accumulates — see Revisit triggers.
