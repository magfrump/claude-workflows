# DD: what second corroboration channel (and/or owner-cap change) should the escalation rule get?

**Date:** 2026-07-30 · **Status:** diverge/diagnose/match/decide complete (Path A). Implemented.
**Calling context:** standalone. Routed here explicitly by `docs/thoughts/code-review-evaluation-state.md` §1.2 ("route it through `divergent-design`, don't patch it ad hoc"). Adjacent DD: `docs/working/dd-code-intent-claims.md`, whose §5 surfaced the owner-cap half of this problem and deliberately did not resolve it (its H3 barred any edit to the Escalation Rule).

## Problem statement

The pipeline's escalation gate has no channel by which a correctly-reasoned **soundness
defect** can reach a merge-relevant band. On ND2, opus reached the ground-truth defect (a
FLEE-interrupted song still grants CONTENT, so the intended penalty is mechanically a
*reward* — `MOOD_MULTIPLIER.CONTENT = 0.5` halves the flee threshold for 6 s), explicitly
**rejected** the "deliberate small mercy" docstring, reconstructed the full consequence,
noted it is invisible to tests — and filed it **🟢**, because promotion requires a
fact-check `Incorrect` or an api-consistency `Breaking`, and neither verdict can attach to
a state-machine soundness defect (Result 15 + 14a). The historical human panel filed the
same finding **🟡 and gated the merge on it**.

There are **two structural causes, not one** (state doc §1.2):

1. **The 🔴 monopoly** — the Escalation Rule's corroboration list (a failing test, a
   fact-check `Incorrect`, or explicit human confirmation) is structurally unreachable for
   correctly-documented bad design: the comment is *accurate* (all 4 of 4 cells that
   fact-checked it rated it `Verified / High`, correctly), the defect is untested by
   construction, and the headless Gate-1h path has no human.
2. **The owner cap** — `skills/code-review/SKILL.md`'s "Contextual critics are advisory"
   rule sends every contextual-critic finding to 🟢 "regardless of their internal
   severity", and the Escalation Rule bars them from escalation entirely. ND2's one
   correct reconstruction was filed by `tech-debt-triage`; the two ND3 cells that got the
   same defect right filed it under `architecture-review` (🔴-capable mapping) and landed
   🟡. Same defect, same reasoning, three bands apart — decided by which critic noticed.

Nothing was missed; the reasoning was complete and correct. Any fix that addresses only
the corroboration channel leaves the owner-cap half untouched (state doc §1.2, verbatim).
The state doc names candidate directions — a soundness-corroboration channel keyed on
quoted-intent-vs-quoted-code contradiction, a failing-test requirement (Thread 7), routing
to a human queue — as **inputs, not the field**.

## 1.0 Prior pruning grep

```
grep -B 1 -A 20 "Pruned candidates" docs/decisions/*.md | rg -i "escalat|corrobor|severity|contextual critic|owner cap|blocking|tier|gate"
```

One relevant match in `docs/decisions/*.md`:

- **[017-polyglot-test-hermeticity, candidate 9] "code-review sub-critic as a gate"** —
  pruned there as *"not a gate … an LLM critic is a detector, not an enforcement
  primitive."* **Carried forward** as constraint **H3** below: whatever new channel lands,
  its trigger must be artifact-checkable evidence, not an LLM's severity opinion promoted
  to enforcement. (021's pruned list also surfaced under the grep — full-agentic /
  on-demand-read candidates pruned on sweep portability — not transferable to this field;
  noted and not re-proposed.)

Additionally, the adjacent DD working doc `dd-code-intent-claims.md` (not a
`docs/decisions` record, but named input per the brief) pruned three candidates that
re-enter this field:

- **[dd-code-intent-claims, 10] human queue** — pruned on headless resolution ("a queue
  with no human at decision time is a gate that never gates"). **Carried forward** → H1;
  its async residue (override-log filing) survives as an obligation, not a gate.
- **[dd-code-intent-claims, 8] test-backing rule** — pruned on the true-positive path
  (defect and intent claim are *both* untested on ND2; "invisible to tests, which assert
  only the transition, never the tick after"). **Carried forward** — it shapes candidate 3
  below into "keep executed evidence as the existing 🟡→🔴 path" rather than a firing
  requirement.
- **[dd-code-intent-claims, 12] "reframe: fix the channel"** — pruned *there* as
  out-of-scope (its H3 forbade touching the Escalation Rule). **Revived here by design**:
  this DD *is* that candidate's home; the state doc routes §1.2 here explicitly. Why this
  time is different: the scope boundary that pruned it was the prior DD's own constraint,
  not an argument against the fix.

## 1. Diverge — 15 candidates

| # | Candidate | One line |
|---|---|---|
| 0 | **Status quo** | Escalation Rule as rewritten (corroboration = failing test / fact-check `Incorrect` / human); owner cap intact. Decisions 25 and 27 both explicitly left §1.2 open, so this is the standing prior decision. |
| 1 | Defer until validated | Change nothing; run the ND2/ND3/md1 replay validation first, decide after. |
| 2 | Fourth corroboration bullet | Add "a quoted intent-vs-code contradiction, both sides cited verbatim with file:line" to the Escalation Rule's corroboration list; normal one-tier escalation applies (🟢→🟡→🔴). |
| 3 | Failing-test requirement | A soundness finding escalates only when the reviewer authors a failing test demonstrating the inversion (Thread 7). |
| 4 | In-run human queue | Soundness findings block on a human decision before the rubric closes. |
| 5 | Async human queue | File soundness findings to `docs/reviews/override-log.md` as open questions; band unchanged in-run. |
| 6 | Full owner-cap removal | Contextual critics use the Unified Severity Mapping like architecture-review; the advisory rule is deleted. |
| 7 | Severity-keyed cap softening | Contextual findings with native High/Critical may land 🟡; the rest stay 🟢. |
| 8 | Ownership re-file | Stage 3 re-files a soundness defect found by a contextual critic under a 🔴-capable domain owner (architecture-review's mapping). |
| 9 | Fact-check soundness verdict | Extend `code-fact-check`'s scope so soundness contradictions earn `Incorrect` (claim-splitting adjacent). |
| 10 | Dedicated soundness critic | A new critic with its own 🔴-capable severity mapping for intent-vs-mechanism contradictions. |
| 11 | Restore convergence escalation | 2+ critics flagging the same issue escalates a tier — the pre-rewrite rule. |
| 12 | **Contested-Soundness cross-check** | A Stage-3 cross-check: when any critic report (contextual included) contains a verbatim-quoted stated intent, a verbatim-quoted/reconstructed code mechanism, and reasoning that the mechanism defeats the intent, the finding is lifted to 🟡 `Contested-Soundness` — terminal at 🟡, barred from escalation corroboration, applies regardless of filing critic (the one owner-cap exception). Mirrors decision 25's Confirmed-Good template. |
| 13 | Instrument only | A `Soundness-candidate` annotation records such findings without changing any band; decide the channel later on accumulated data. |
| 14 | Ideal-if-free | Build a full replay harness over the 11 archived cells + 3 pre-fix worktrees, validate a soundness mechanism's precision, then grant it 🔴 authority. |

Deliberately included: do-nothing family (0, 1), naive/wrong (11 — the exact rule the
"Why this changed" history removed; 6 — untested per open question #6), unconventional
(5, 8), ideal-if-effort-were-free (14).

**Generation health check.** First pass produced 2, 3, 9, 12 — clustering on *"make the
corroboration list reachable"* (agent-text/policy dimension) — so 6, 7, 8 were added on
the authority dimension (who may band what), 5 and 13 on routing/communication topology,
10 on agent set, and 1/14 as time-shifted. Dimensional coverage after the fix: agent text
(2, 12), agent set (10), routing (5, 8, 13), authority policy (6, 7, 11), time-shifted
(1, 14), reframe (9). No candidate is untestably vague; each names its edit site.

## 2. Diagnose — constraints

**Hard (H):**

- **H1 The mechanism resolves with no human present.** Gate 1h runs headless, mid-loop.
  `success:` a full pipeline run under Gate 1h completes `rc=0` with no `AskUserQuestion`
  and no stdin read; any human involvement is asynchronous (override log, adjudicated at
  pr-prep), never in-run. *(Carried from dd-code-intent-claims H1 / its pruned [10].)*
- **H2 No blocking authority for unvalidated mechanisms.** The Escalation Rule's own "Why
  this changed" history removed convergence-escalation precisely because it carried
  merge-blocking authority on an untested n≈5; decision 25's Contested mechanism shipped
  🟡-terminal for the same reason, and open question #6 (does removing the owner cap
  change ND2's outcome?) is explicitly *not attempted*. `success:` the implementing diff
  grants no new path to 🔴; any new channel is capped at 🟡, and the skill text carries
  the validation falsifier (fires on pre-fix ND2; silent on ND3's fixed `sim.ts:625-628`
  and md1's `proxy.ts:14`) that must pass before a future decision may lift the cap.
- **H3 The trigger is artifact-checkable, not a same-model opinion.** The critics are the
  same model differing by role prompt; their errors are correlated by construction, which
  is why the rewritten rule demands corroboration "that does not come from another critic
  sampling the same model". `success:` the channel's firing condition is re-verifiable by
  a human from the rubric row alone — verbatim quotes with `file:line` on both sides of
  the contradiction — with no reference to any critic's severity label. *(Carried from
  017 candidate [9]: detector, not enforcement primitive.)*
- **H4 The coherent-doc path survives.** The intent-claim base rate is ~70%
  defer-was-right / ~25% defer-was-wrong (dd-code-intent-claims §0); a channel that fires
  on coherent rationale docstrings converts a false-negative class into a larger
  false-positive class. `success:` replayed on ND3's fixed `sim.ts:625-628` docstring and
  md1's `proxy.ts:14` carve-out, the mechanism lifts zero rows in 3/3.
- **H5 Nothing keys on a tier boundary.** Tier is the least stable output (J_self on 🔴
  rows 0.14–0.25; Results 1, 17, 14a). `success:` the trigger reads report *content*
  (quotes + stated inversion), never the tier a finding initially landed; the output
  vocabulary is fixed (`Contested-Soundness`, destination 🟡) with no tier-conditional
  branching.
- **H6 No new per-review dispatch.** Cost multiplies per task × per round in Gate 1h.
  `success:` delta in `Agent` invocations per review = 0 — the mechanism is a Stage-3
  re-read of reports already in context, like the Confirmed-Good cross-check.
- **H7 Both structural causes are addressed.** State doc §1.2: "Any fix … that addresses
  only the corroboration channel leaves this half untouched." `success:` on an ND2-shaped
  replay, a qualifying finding filed by `tech-debt-triage` reaches 🟡 — i.e. the
  mechanism contains an explicit, named exception to the "Contextual critics are
  advisory" cap, wired to the same trigger, verifiable by reading the two rules together.
- **H8 The ground-truth band is reachable.** The human panel filed ND2 🟡 and gated the
  merge on it; 🟡 in this pipeline means "the author must fix this or say on the record
  why it stands". `success:` under the mechanism, ND2's finding lands exactly 🟡 — the
  band the only available ground truth assigned — verified against Result 15's record in
  the state doc.

**Soft (S):**

- **S1** Testable against the archived corpus (11 cells, 3 pre-fix worktrees) at zero new
  experiment cost.
- **S2** Mechanism over prose — fixed behaviour, bats-pinned, per the repo's standing
  "unenforced prose does not execute" evidence.
- **S3** Localized to skill files; no `scripts/self-improvement.sh` changes.
- **S4** Produces measurement data — each lift is a countable, auditable rubric row
  (answers open question #6 as a side effect of normal runs).

## 3. Match — compatibility matrix

| # | Candidate | H1 | H2 | H3 | H4 | H5 | H6 | H7 | H8 | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Status quo | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | baseline — is the thing being fixed |
| 1 | Defer until validated | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | pruned (honest; becomes a revisit trigger) |
| 2 | Fourth bullet (🔴-capable) | ✓ | ⚠ | ✓ | ~ | ✓ | ✓ | ✗ | ✓ | ⚠ H2 → survives only as **2′** (🟡-capped variant) |
| 3 | Failing-test requirement | ✓ | ✓ | ✓ | ✓ | ✓ | ⚠ | ✗ | ~ | pruned |
| 4 | In-run human queue | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | pruned [carried from dd-code-intent-claims [10]] |
| 5 | Async queue only | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | pruned as gate; absorbed as obligation |
| 6 | Full owner-cap removal | ✓ | ⚠ | ✗ | ~ | ~ | ✓ | ✓ | ~ | pruned |
| 7 | Severity-keyed softening | ✓ | ~ | ✗ | ~ | ~ | ✓ | ✓ | ~ | pruned |
| 8 | Ownership re-file | ✓ | ~ | ~ | ~ | ✓ | ✓ | ✓ | ✓ | absorbed into 12 |
| 9 | Fact-check soundness verdict | ✓ | ~ | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ | pruned [carried from dd-code-intent-claims §4.2c] |
| 10 | Dedicated soundness critic | ✓ | ⚠ | ~ | ~ | ✓ | ✗ | ~ | ✓ | pruned |
| 11 | Convergence restoration | ✓ | ⚠ | ✗ | ~ | ✓ | ✓ | ✗ | ✓ | pruned (the reverted rule) |
| 12 | **Contested-Soundness cross-check** | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | **survives** |
| 13 | Instrument only | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | **survives** (as the measure-first alternative) |
| 14 | Ideal-if-free: validate-then-authorize | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓* | ✓* | **survives** (*eventually) |

Key: ✓ addresses · ~ partial/uncertain · ✗ doesn't address · ⚠ actively worse.

**Prune reasoning (beyond the matrix glyphs):**

- **[2] as written** grants a one-tier escalation path that reaches 🔴 (a 🟡 finding +
  contradiction → 🔴) on an unvalidated trigger — exactly the shape H2's history removed.
  Its 🟡-capped variant **2′** ("the contradiction corroborates, but escalation via this
  corroboration terminates at 🟡, and contextual critics remain excluded") survives to
  step 4 as the minimal-edit rival.
- **[3]** — executed evidence is *already* a listed corroboration; the gap is that nobody
  produces it, and on ND2 the defect is untested by construction ("invisible to tests,
  which assert only the transition, never the tick after") — authoring the missing test
  in-run is the fix's verification work, not review work, and it adds a heavy in-run step
  to the most expensive gate (⚠ H6). Kept as the *existing* validated path by which a
  Contested-Soundness 🟡 can later reach 🔴: a failing test is already corroboration.
- **[6]/[7]** — both key banding on the critic's internal severity label, an opinion
  (✗ H3), and open question #6 is untested — granting native mappings to contextual
  critics is precisely "blocking authority for an unvalidated mechanism" (⚠/~ H2).
- **[8]** — re-filing under architecture-review's mapping inherits an unvalidated 🔴 path
  and, without a mechanical trigger, the re-file decision is an orchestrator opinion.
  With the trigger made mechanical and the destination capped, it *is* candidate 12.
  Absorbed.
- **[9]** — falsified in the adjacent DD (§4.2c): the checkable half of this claim class
  is already in scope and already produces 🔴s; the marginal population is the corpus's
  highest-variance verdict class, and `code-fact-check`'s first non-goal ("not a code
  reviewer") is load-bearing. Carried, not re-litigated.
- **[10]** — mints new 🔴 authority from an unvalidated judgment (⚠ H2) at a full extra
  dispatch (✗ H6); the boring form of this idea already shipped as the intent-coherence
  move on architecture-review (dd-code-intent-claims §4.4).
- **[11]** — the Escalation Rule's own "Why this changed" section is its refutation:
  critics are the same model, errors correlated by construction; the most-converged
  historical escalation was the one the human waived. Re-proposing it would revert a
  measured decision on no new evidence.
- **[4]** — fails H1 outright; **[5]** alone changes no outcome (✗ H7/H8) and the
  override log's history (empty in all 11 run trees) says an unforced write channel does
  not get written. Absorbed: every lift under [12] is named in the chat synthesis, and
  its adjudication lands in the override log, which Step 3.5 already re-reads on
  subsequent runs — that is the asynchronous human loop H1 permits.

**Survivors: [12] [2′] [13] [14].**

Fix sketches for surviving weaknesses:

- **[12]** has a `~` on H4 (unvalidated firing precision). Fix: a three-part trigger —
  verbatim intent quote with `file:line`, verbatim/reconstructed mechanism quote with
  `file:line`, and the report's own stated inversion — with an explicit precision guard
  (an intent claim alone, or disagreement with a design's *wisdom*, never qualifies), plus
  the negative-control falsifier written into the skill text.
- **[2′]** has ✗ on H7. Fix requires bolting on a separate owner-cap exception — at which
  point it has converged to [12] minus the reusable 025 template. No independent fix.
- **[13]**'s ✗ on H7/H8 is constitutive — it is the measure-first position, not a fix
  target.
- **[14]**'s cost: stage it — which is exactly what [12] + its falsifier + revisit
  triggers amount to ([12] *is* stage 1 of [14] with the 🟡 cap as the safety interlock).

## Notes for step 4 (rendered in the console block; recorded here for the archive)

Scoring rationale for the tradeoff matrix:

- **[12]** effort ● (~half a day: one skill-file section + cross-references + one bats
  contract suite, mirroring the shipped 025 mechanism); risk ◐ (unvalidated firing
  precision, but 🟡-capped, quote-guarded, and structurally identical to a mechanism
  retrospectively validated 2/2 catches with 0 wrong kills); coverage ● (8/8 hard — the
  only candidate addressing both structural causes).
- **[2′]** effort ● (~2 h, one bullet + one cap note); risk ◐ (same unvalidated trigger,
  same cap); coverage ◐ (6/8 — H7 ✗ by construction, and H8 fails for contextual-found
  findings: the ND2 replay still lands 🟢 whenever `tech-debt-triage` is the finder,
  which is what actually happened).
- **[13]** effort ● (~2 h); risk ● (no behaviour change); coverage ○ (2/8 — changes no
  outcome; Result 14a is the standing evidence that recording correct reasoning does not
  move the band, and the [7]-column analysis in the adjacent DD names the same failure:
  data without a consumer).
- **[14]** effort ○ (weeks: replay harness + blinded adjudication across 11 cells); risk
  ● eventually; coverage ◐ (eventual — meanwhile the ND2 class stays unhandled, and the
  program-never-runs precedent is live: the override log is empty in all 11 trees).

Stress-test moves applied (4): boring alternative, invert the thesis, failure-driven,
organizational survival — full text in the decision record's Stress-test mitigations and
the step-4 block. One matrix consequence: the invert-the-thesis move promoted the 🟡 cap
from a design choice to part of H2's success line (the inversion's surviving core is
"true-but-unwanted escalations were the measured failure — never mint 🔴 from opinion").

Axis of disagreement (runner-up [2′], within ~1 cell): **cover both structural causes vs.
make the minimal edit.** The project's stated preference is explicit — state doc §1.2:
"Any fix for §1.2 that addresses only the corroboration channel leaves this half
untouched." That preference decides it for [12].

## 4. Decision presentation (rendered block, archived)

```
┌─ DECISION: what second corroboration channel (and/or owner-cap change) should the escalation rule get? ─┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes                                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                       effort        risk      coverage      key downside
  ───  ───────────────────────────  ────────────  ─────────  ────────────  ─────────────────────────────
   12 ★ Contested-Soundness x-check  ● ~0.5 day    ◐ med      ● 8/8 hard    ◐ false lifts pollute 🟡 (mitig.)
   2′   🟡-capped corroboration      ● ~2 hours    ◐ med      ◐ 6/8 hard    ○ owner-capped ND2 still lands 🟢
   13   instrument only              ● ~2 hours    ● low      ○ 2/8 hard    ○ data without a consumer
   14   validate-then-authorize      ○ ~weeks      ● low      ◐ eventual    ○ ND2 class unhandled meanwhile

  drill-down: name a # to expand its card; only the recommended card is open by default.
```

```
╭─ [12] Contested-Soundness cross-check   ★ recommended ──────────────────╮
│ effort    ~0.5 day (one SKILL.md section + cross-refs + 1 bats suite)   │
│ risk      med — unvalidated firing precision, capped at 🟡              │
│ coverage  8/8 hard · 4/4 soft                                           │
│ hypothesis  If chosen, a Stage-3 pass over archived nd2-opus-r2 lifts   │
│             its C1 reconstruction to 🟡 Contested-Soundness, and replays│
│             on ND3's fixed sim.ts:625-628 and md1 proxy.ts:14 lift      │
│             nothing (3/3), within one replay session; counter-evidence  │
│             = any lift on a negative control, or no lift on ND2 because │
│             critics never quote both sides.                             │
│ stress-tests applied                                                    │
│   · boring alternative → [13] refuted by Result 14a (recording correct  │
│     reasoning did not move the band); 025 template is the boring form   │
│   · invert thesis → 🟡 cap promoted into H2's success line              │
│   · failure-driven → quote-pair guard; Contested vs Contested-Soundness │
│     kept distinguishable; Goodhart covered by design-doc/<pr-intent>    │
│     trigger scope + the standing anti-comment-remedy obligation         │
│   · organizational survival → exact reuse of decision-25's shape        │
│ key downside  a wrong lift makes 🟡 noisier — but a 🟡 dismissal costs  │
│               one on-the-record sentence, which is the designed         │
│               behaviour (mitig., cross-ref Stress-test mitigations)     │
╰─────────────────────────────────────────────────────────────────────────╯

▶ recommend [12] Contested-Soundness cross-check · confidence 85% · runner-up [2′], axis = cover both structural causes vs minimal edit
```

**Decision path: A** — one approach dominates at >80% confidence. No `AskUserQuestion`
(non-interactive run); the static block above is the scrutiny surface. Runner-up noted
because [2′] sits within ~1 cell: the axis is *cover both structural causes vs. minimal
edit*, and the project's stated preference (state doc §1.2: a corroboration-only fix
"leaves this half untouched") resolves it for [12].
