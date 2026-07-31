# Code review: what the evaluation program has established

> Living synthesis across every measurement arm run against this repo's `code-review`
> skill. Read this before designing a new arm, changing the skill, or interpreting a
> cross-model result. It is the shortest path to "what do we actually know."

Last verified: 2026-07-30
Relevant paths: skills/code-review/SKILL.md · skills/code-fact-check/SKILL.md · scripts/self-improvement.sh · scripts/cross-model-review.py · scripts/dd-cross-model-sweep.py · runs/dd-cross-model-2026-07-30/ · docs/working/experiment-results-code-review-2026-07-29.md · docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md · docs/working/experiment-cross-model-review-2026-07-30.md · docs/decisions/021-reviewer-context-management.md · docs/working/research-cross-model-review-hypotheses.md

Two distinct arms carry the "2026-07-30" date and must not be conflated: the
**full-pipeline tiers** arm (`experiment-results-full-pipeline-tiers-…`, agentic, source of
Results 11–17) and the **OpenRouter cross-model** arm (`experiment-cross-model-review-…`,
headless diff-inline, four vendors). Each has its own "Result N" numbering; §5.0 records the
cross-model arm by finding *name* to avoid the collision.

## Who this is for

- Anyone changing `skills/code-review/SKILL.md` or its critics.
- **The cross-model track** (Gemini, Kimi K3, other vendors via
  `scripts/cross-model-review.py`). §5 is written for you specifically — it lists the
  comparability rules and the four traps that have already cost this program real work, and
  §5.0 records what the first run of this arm actually found (and the context-management
  decision, 021, that came out of it).
- Anyone touching Gate 1h in `scripts/self-improvement.sh`.

## 1.0 The one-paragraph state of things

The pipeline **detects** well and **tiers** badly. Across every arm, whether a real defect
gets *found and correctly described* is far more stable than what severity band it lands
in. The single gate that converts a finding into a blocker — a `code-fact-check` verdict of
Incorrect, or an api-consistency Breaking — is both unstable run-to-run and structurally
unreachable for whole classes of real defect. Every high-value action below follows from
that one sentence.

---

## 1. Definitely needed (evidence is direct, and the failure has been observed)

### 1.1 Run `code-fact-check` k≥3 times and combine, before anything downstream — **implemented** (log row 27)

**Status 2026-07-30:** implemented in `skills/code-review/SKILL.md` Stage 1 as shaped
below (k=3, byte-identical prompts, cluster + most-severe-wins, per-replicate verdict
logging, agreement rate reported per run in the merged report's `## Verdict stability`
section), with one deliberate deviation: clustering matches claim *substance* within a
±5-line range, not the literal "claim text" named below — replicates word the same claim
differently, so textual matching would under-cluster. Cross-model corroboration: all four families in the DD sweep
(`runs/dd-cross-model-2026-07-30/`) independently ranked this action first. The falsifier
below is now *measurable in every run* — open question #2 resolves itself as agreement
data accumulates. First measurements exist (see open question #2); the noise floor
is still unquantified.

**Why.** Per Result 16, a fact-check Incorrect verdict is one of the two verdict-driven
promotions to 🔴 (§1.0: fact-check Incorrect or api-consistency Breaking) and the only one
reachable by documentation-class findings. Per Result 14a, that verdict is unstable on identical input: the same
`WARY_MOOD_DURATION` comment defect was rated **Incorrect** by one run and **Mostly
Accurate** by another, flipping the same finding between 🔴 and 🟡. Both runs described the
defect correctly — only the verdict moved.

So the pipeline's entire blocking channel currently rests on a single sample of the least
stable judgment in it. J_self restricted to 🔴 rows is **0.14–0.25**; band-agnostic it is
~0.5. This is the highest-leverage change available and it is cheap: fact-check is one
agent, and the diff is already in context.

**Shape.** k=3 fact-check agents on byte-identical prompts; cluster claims by
(file, line-range, claim text); take the **most severe verdict** any run assigned, not the
majority — a defect one run proves Incorrect is Incorrect regardless of what two others
concluded, and the observed failure mode is under-calling, not over-calling. Log per-run
verdicts so the disagreement rate becomes a tracked metric rather than an invisible coin
flip.

**Falsifier worth checking first:** if k=3 fact-check verdicts agree ≥90% of the time on a
20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2.

**Known bound — replication cannot reach correctly-documented bad design.** On ND2, all
**4 of the 4 cells that checked it** rated the "a FLEE-interrupted song still earns the
CONTENT aftertaste" docstring `Verified / High` — *correctly*, because the code does
exactly what the comment says. The defect is that the documented behaviour is wrong as
design, which is outside `code-fact-check`'s scope by construction (see its first
non-goal). Resampling makes an unstable verdict stable; it does not make an out-of-scope
question in-scope. This class needs §1.2 and the intent-claim decision, not k≥3.

### 1.2 Give the escalation rule a second corroboration channel

**Why.** Result 15 + 14a. On ND2, opus reached the ground-truth defect (a FLEE-interrupted
song still grants CONTENT, so the intended penalty is mechanically a *reward*), explicitly
**rejected** the docstring calling it "a deliberate small mercy," reconstructed the full
consequence, noted it is invisible to tests — and filed it **🟢**, because no
fact-check-Incorrect or api-Breaking verdict can attach to a state-machine soundness
defect. The historical human panel filed the same finding 🟡 and gated the merge on it.

Nothing was missed. The reasoning was complete and correct. It landed two bands low because
the promotion gate had no channel it could use.

This is a design decision with real options (a soundness-corroboration channel keyed on
quoted-intent-vs-quoted-code contradiction; a failing-test requirement per Thread 7;
routing such findings to a human queue) — **route it through `divergent-design`**, don't
patch it ad hoc. What is *not* in question is that the gap is real and observed.

**There are two structural causes here, not one.** Besides the fact-check monopoly above,
there is an **owner cap**: opus found ND2's defect inside `tech-debt-triage`, and
`SKILL.md:933` caps every contextual critic's findings at 🟢 *regardless of internal
severity* while `:969` bars them from escalation entirely. So even a critic that fully
reconstructs a live behavioural inversion cannot exceed 🟢 if it happens to be the one that
found it. Any fix for §1.2 that addresses only the corroboration channel leaves this half
untouched.

**Status 2026-07-30: decided and implemented — decision 028** (log row 28,
`docs/decisions/028-escalation-second-channel.md`, DD at
`docs/working/dd-escalation-second-channel.md`). The escalation gate gained a
**Soundness-Contradiction Channel**: a Stage-3 cross-check that lifts a finding to 🟡
`Contested-Soundness` when its critic report quotes a stated intent verbatim (file:line),
quotes/reconstructs the actual mechanism (file:line), and states the inversion — applying
**regardless of which critic filed it**, the one evidence-gated exception to the
contextual-critic 🟢 cap, so both structural causes above are addressed. Terminal at 🟡
(the human panel's band for ND2) and excluded from escalation corroboration, because the
mechanism is unvalidated and unvalidated mechanisms get no blocking authority.
**Validated 2026-07-30, pass-with-recalibration-needed**
(`docs/working/validation-soundness-channel-2026-07-30.md`): the falsifier passed 3/3 as
written — ND2's C1 lifts 🟢→🟡, md1 `proxy.ts:14` holds non-vacuously, ND3 `sim.ts:625-628`
holds but vacuously (no ND3 report text touches it) — while the full-corpus sweep (315
findings, 11 cells) measured recall 1/1 on cells that filed the defect and 4 clear false
lifts (~1.3%, dominant shape: convention-contradiction findings quoting module-header
principles), so trigger condition 3 needs tightening to *behavioral* inversion, "verbatim"
must admit bracketed alterations, and an already-≥🟡 no-op clause is needed. The 🟡 cap
stands (the cap-raise precondition also requires a ≥10-correct-lift corpus).
The adjacent DD on intent claims (`docs/working/dd-code-intent-claims.md`, intent-coherence
move inside `architecture-review`) remains its own track with its own falsifier.

### 1.3 Stop treating `✅ Confirmed Good` as an output; treat it as a claim requiring evidence

**Why.** Result 12. On MD1, **two of three tiers filed the branch's actual blocking defect
under Confirmed Good.** Fable's own fact-check report recorded the disconfirming evidence
verbatim — *"client fetches are all relative `/api/…` paths or `data:` URLs in
`app/lib/utils/exportGraph.ts:24,37`"* — and its security review then certified
`connect-src 'self'` as **"matches reality."** Sonnet did the same.

Result 8b observed this shape at haiku and it was recorded as a small-model property. It is
**not tier-bounded.** Confirmed Good is the highest-assurance row the rubric emits and
nothing currently checks it.

**Shipped (`a9fa0ba`, log row 25) — with a measured partial.** The rubric's Confirmed Good
table gained an `Evidence` column bound to the existing evidence-grounding format; an
ungrounded row is *deleted* rather than downgraded; universally quantified rows ("no X
anywhere", "no unintended carve-outs") must cite the enumeration actually executed; and
Stage 3 cross-checks every ✅ row against the fact-check report — explicitly including
observations recorded in passing *under a claim the fact-check itself marked Verified*,
which is where the fable evidence was buried. A contradicting row moves to 🟡 with
`Severity: Contested`, and is barred from counting as escalation corroboration.

Validated retrospectively against the archived cells rather than asserted:

- **fable — caught.** The enumeration rule and the cross-check both fire on it.
- **sonnet — not caught, and it cannot be by this mechanism.** Its fact-check contains zero
  occurrences of `connect-src`, `data:`, or `exportGraph` — there is no observation to
  contradict. The enumeration rule covers it only weakly: a ✅ row can no longer assert the
  branch is fine *without having looked*, but a run that never observed the fact is not
  made to observe it. Closing that needs §1.1.
- **0 of 82** Confirmed Good rows across all archived cells carried a checkable citation
  before this change.

### 1.4 Never let a single run's clean verdict stand as assurance

Corollary of 1.3 and H5. A "no findings" result from one run is not evidence of absence —
it is one sample from a distribution whose 🔴-level self-agreement is ~0.2. Anywhere a
verdict is *consumed as assurance* (Gate 1h, pr-prep sign-off), require either
corroboration or an explicit "single-sample, not an attestation" label.

**Label shipped (`a9fa0ba`).** A passing rubric status and a `merge` recommendation both
carry the single-sample caveat, bounded by a test so it cannot spread into per-section
hedging. The *corroboration* half is not shipped — that is §1.1 and §5.0's second-vendor
finding, which compose: resample one family for stability, add a family for coverage.

### 1.5 Done — headless flags (`96166d5`, log row 24)

Every `claude -p` in `scripts/self-improvement.sh` that writes files or reads outside cwd
now carries `--permission-mode acceptEdits` and the needed `--add-dir`. Before this, 7 of
10 invocations could not persist anything, and Gate 1h's critics ran on the orchestrator's
*paraphrase* of the role prompt rather than the real skill file. Result 8a measured the
role prompt (not the tier) taking sonnet 0/2 → 2/2 on a validated blocking defect, so that
was a materially weaker reviewer than the model pinning in decision 022 believed it bought.

**Verified constraint for future work:** `--add-dir` does **not** propagate to `Agent`
sub-agents. It is harmless here only because `skills/code-review/SKILL.md:260` has the
orchestrator read-and-paste critic files precisely because "sub-agents cannot read your
files." Any future skill expecting a sub-agent to read a payload path directly cannot work
today.

---

## 2. Settled enough to act on, lower urgency

- **Do not gate on 🟡-vs-🟢.** Tier assignment is the least stable output (Result 1, 17,
  14a). Gates should key on issue identity or the blocking band only.
- **Never run a critic on haiku.** Its clean verdicts are false attestations (Result 7/8).
  Unchanged.
- **`sonnet` is acceptable only with the role-skill prompts.** Result 8a, reconfirmed by
  Result 13 — under the full pipeline all three tiers recovered ND3's blocking defect.
- **Reviewer model ≠ fixer model.** Thread 6; independent of everything measured here.
- **Role critics stay.** Abstention is clean (Result 3); roles partition rather than
  duplicate (Result 2). The restructure-to-generalist proposal is closed twice over.
- **A second *vendor* buys recall the incumbent structurally cannot** (§5.0). The OpenRouter
  arm surfaced four real defects that survived up to seven Claude-family rounds; on one diff
  the incumbent abstained 0/6 while another vendor caught both real bugs. Blind spots are
  correlated within a family, so this is orthogonal to §1.1's k≥3 (which resamples one family
  for *stability*, not *coverage*). The two compose: add a vendor for coverage, resample for
  stability.
- **Reviewer context management is decided — 021.** The pipeline sits on a staged path from
  diff-only toward agentic: Stage 1 (git-only) enriches the harness with the full logical
  changeset + enclosing files to kill the sibling-commit false-positive class; the production
  agentic critic stays the Stage-3 re-verification authority. "Must have repo access" is
  honoured at *verification*, not at cheap generation. See §5.0 and decision 021.

## 3. Open, and now the highest-value unknowns

| # | Question | Why it matters | Status |
|---|---|---|---|
| 1 | Does MD1 R1's recovery replicate? | It is the sole evidence that the pipeline clears the cross-file ceiling, and the basis for "config, not model." **n=1.** | **Closed with a split verdict** (`docs/working/experiment-md1-r1-replication-2026-07-30.md`, 5 fresh opus cells): the **original config recovers R1 reliably** — oc 3/3 incl. Result 11 (🔴, both call sites, `toBlob`) — so Result 11 was *not* variance and "config, not model" stands. But the **current k=3 config went 1/3** (two affirmative clears; the one recovery came at 🟡 via architecture-review + the 028/Confirmed-Good cross-checks, not fact-check): 0/9 cc fact-check replicates reached `exportGraph.ts` vs 3/3 oc runs (p≈0.0045). Cause: orchestrators read the k=3 uniformity clause as license for lean generic replicate briefs — k=3 of a weak brief < k=1 of a strong one. **Fixed in SKILL.md Stage 1 step 3b** (rich shared brief, identical across replicates) and **validated n=1** (`md1-opus-fix-r1`, doc §Validation): brief written (7,834 chars ×3, identical except the permitted output path, claims list + exercising-code directive), fact-check reached `exportGraph.ts` **3/3 replicates** (vs 0/9 pre-fix), R1 recovered at 🔴 via the restored fact-check-led path incl. `toBlob` — plus a new finding beyond ground truth (`exportAll.ts:61-69` swallows the blocked PNG, ZIP silently omits it). Caveat: SKILL quotes this defect class as a worked example, so binary outcomes are hint-advantaged; the mechanism evidence (brief richness → replicate detection) is the generalizable part. |
| 2 | How often do fact-check verdicts disagree across replicates? | Sets k in §1.1 and quantifies the blocking channel's noise floor. | **Instrumented** (log row 27): every k=3 run now reports its cluster agreement rate in the merged report's `## Verdict stability` section. Two samples now exist, pointing in opposite directions: this repo's own reviews measured 21/23 ≈ 0.91 (2026-07-30) and 20/26 ≈ 0.77 (2026-07-31, disagreements all on the Verified↔Mostly-Accurate boundary), while the MD1 cc cells ran ~47% — neither side of the §1.1 falsifier (≥90% on a ≥20-claim *cumulative* sample → k=2) is settled; keep accumulating. |
| 3 | Is the MD1 nonce-delivery issue really 🔴? | Three independent configs say 🔴, history says 🟡. Settled empirically by one prod build. | Unresolved since Result 8b |
| 4 | Does a Confirmed-Good-vs-fact-check cross-check actually catch the misses? | Cheap to test retrospectively against the 9 existing cells. | **Closed** (full retrospective, `docs/working/retrospective-confirmed-good-2026-07-30.md`): 90 ✅ rows / 11 cells — rule 4 catches 2/2 observation-backed misses (fable MD1 ×2, one newly found beyond decision 25's sample) with 0 wrong kills; the 1 observation-free miss (sonnet MD1) is unreachable by any cross-check widening (all 8 run artifacts silent) — only rule 3's rewording touches it, so closing it stays with §1.1 k≥3. Decision-25's "82 rows" corrected to 90. Rule 4's exact "is the ✅ claim still true?" phrasing is load-bearing: 4 near-miss rows are correctly spared by it. |
| 5 | Is the intent-coherence move in `architecture-review` load-bearing, or prose-nudging? | Decides the DD recommendation in `dd-code-intent-claims.md`; its own author names this the strongest objection. | Falsifier specified: re-run `architecture-review` on ND2 ×3 *without* the move; unaided recovery ≥2/3 means it is decoration. |
| 6 | Does removing the owner cap change ND2's outcome? | The second structural cause in §1.2, and untested — opus's finding was 🟢-capped by critic ownership, not only by the escalation rule. | Partially instrumented by decision 028: the Soundness-Contradiction Channel is a narrow, evidence-gated cap exception whose every lift is an auditable row, so the replay falsifier in 028 answers this directly for the quote-pair subclass. Full cap removal remains untested. |

## 4. What each measured arm actually covers

Do not cite a result without its config — the arms are not interchangeable.

| Arm | Config | Answers |
|---|---|---|
| Results 1–4 | role critics, in-session, k=3 | stability, abstention, quote-anchoring |
| Results 5–6 | historical rubric corpora | precision, but **acceptance-filtered** |
| Result 7 | single-pass generalist, agentic | tier gradient |
| Result 8a | single role skill | prompt-vs-tier isolation |
| Result 9 | fable, generalist | non-total ordering |
| Result 10 | **headless, diff inline, no tools** | model-only; the arm comparable to OpenRouter |
| Results 11–17, 14a | **full pipeline**, headless + flags | pipeline-vs-single-pass, escalation behavior |
| OpenRouter cross-model (§5.0) | **4 vendors, headless diff-inline, no tools, k=3** | multi-vendor recall vs. incumbent blind spots; diff-only precision cost. **Config-comparable only to Result 10** |

---

## 5. For the cross-model track (Gemini, Kimi K3, other vendors)

### 5.0 The arm has now run — OpenRouter cross-model sweep (2026-07-30)

Four vendors (Kimi K3, GPT-5.6 Sol, Gemini 3.1 Pro, and the incumbent Sonnet 5), **diff-inline
/ no-tools / single-pass** — the Result-10-comparable config of §5.1 — over four ground-truth
diffs from the arithmetic-eval review-fix chain, where the *next* commit's message is the
answer key. Full write-up: `docs/working/experiment-cross-model-review-2026-07-30.md`. Findings
are named, not numbered, here — that doc's "Result N" namespace collides with this one's.

What it established:

- **A second vendor buys recall on the incumbent's blind spots.** Four real weaknesses that
  survived up to seven Claude-family review rounds were surfaced by non-Claude families: a
  heredoc-delimiter-collision RCE, an unblocked UDP egress path in `confine.py`, a `pipefail`
  loop-abort, and an `np.load` fail-open/doc mismatch. On the sharpest diff — two real High
  bugs, one silently breaking the skill's primary path — **the incumbent Sonnet returned "no
  findings" on all six replicates** while Sol caught both for ~$0.10. This is §1.4 ("a single
  clean verdict is not assurance") observed cross-vendor: the incumbent's blind spots are
  *correlated*, so resampling the same family cannot find them; a different family does. All
  four are now fixed on this branch.

- **Three of the four wins are Trap-4 (§5.4) cases** — true-mechanism / disputed-or-overstated
  intent. The heredoc "guarantee," the "network disabled" prose, and the `np.load` line-305
  claim each assert a property the code does not hold. `np.load` is textbook: an inline
  "require a truthy literal" comment made every vendor except Kimi treat the gap as intended.
  §5.4 named this the dominant false-negative/false-positive class from the adjudicator side;
  the cross-model arm confirms it from the generation side, and it is *why* the fact-check
  critic is the highest-value place to add a vendor (below).

- **Union buys recall; consensus does not buy precision.** Cross-family issue-level Jaccard ran
  well below within-family (every Sonnet-involving pair far below its own self-overlap) — §5.2's
  "score on detection" in action. But the two most severe false positives were confident,
  sometimes *unanimous*, claims about code that existed in a **sibling commit** the single-commit
  diff hid; cross-family consensus *amplified* the error. This is the concrete cost §5.1 warned
  of: diff-only is not the pipeline.

- **Context management is now decided — 021; Stage 1 built and validated 2026-07-31.**
  `scripts/cross-model-review.py --context-base <ref>` now assembles the Stage-1 prompt
  (labelled sibling-branch diff + whole enclosing files; `--dry-run` for no-spend cost
  projection). Offline measurement (`docs/working/stage1-context-cost-2026-07-31.md`):
  prompts grow 2–6× to ~2k–41k tokens (18k–41k on the non-trivial cells); worst call $0.248, full 4-model×2 sweep $4.37 —
  both 021 guardrails hold. **FP-kill validation ran 2026-07-31**
  (`docs/working/experiment-stage1-fp-kill-2026-07-31.md`, D3/D4, same 4 families × 2
  replicates): Results 3c and 5 reproduced **0/8 each**; Sonnet r2 even cited the
  labelled sibling context correctly ("gate 1h, already committed") — the failure mode
  inverted into correct use. Side signals: D3 cross-family Jaccard rose to 0.28–0.40
  (families converge on real issues under shared context), Sonnet found the Result-3b
  `np.load` issue 2/2 (was 0/3 diff-only), and a new grounded 4-family consensus finding
  emerged (bwrap `--tmpfs /tmp` vs `--chdir "$PWD"`, untriaged). Actual spend $3.53,
  median call $0.226 — no cost trigger fired. That sibling-commit FP class forced the
  diff-only↔agentic question §5.1 raises. Decision `021-reviewer-context-management.md` resolves
  it as a staged path: **Stage 1 (git-only)** feeds the harness the full logical changeset
  (sibling commits labelled "already committed — context only") plus enclosing files — killing
  the FP class while keeping the sweep provider-portable, deterministic, and confound-controlled
  (§5.1/§5.2's whole basis); **Stage 3** keeps the production agentic critic as a re-verification
  gate, so "must have repo access" is honoured at *verification*, not at the cheap generation
  fan-out. Recall win and precision cost reconciled without importing agentic non-determinism
  into the portable sweep. Stage 1 explicitly does **not** recover cross-file interaction bugs
  (the MD1-R1 class of Result 11) — that recall lives only in the Stage-3 agentic gate, which is
  why Result 11's n=1 recovery (open question #1) is load-bearing, not incidental.

- **Where to add a vendor — the fact-check critic first (hypothesis, tied to §1.1 and H5).**
  Rather than run a whole second-family review (expensive, and the diff-only variant is the FP
  machine above), scope the vendor to the least-stable, highest-leverage gate: `code-fact-check`
  (§1.1). Independent evidence from a skill-suite rebuild is that many missed issues *originate*
  in the fact-check stage; the three Trap-4 wins above corroborate it. Two refinements from this
  doc are load-bearing: run the cross-vendor fact-check **k≥3, most-severe-wins** (§1.1), and
  **audit the vendor's *clean* verdicts, not just its findings** (H5 — false attestation was
  seen at sonnet and fable, and the D2 abstention above is a third instance). A narrower variant
  routes only the specific critics with correlated incumbent blind spots. Both still require
  021's Stage-1 context to avoid the sibling-commit FPs. (Full framing: follow-ups 5–6 of the
  cross-model write-up.)

- **Harness tooling now in place** (`scripts/cross-model-review.py`): reasoning-model
  empty-content is recorded as an *errored* run, not a clean one (Kimi returns `content:null`
  when the budget is spent inside the reasoning trace — it fired twice for real on D2); the
  degraded stage-1 Jaccard double-count that could exceed 1.0 is fixed; and a per-model
  **abstention rate** is reported, so a vendor that abstains its way to a perfect self-overlap
  (the D2 Sonnet artifact) is legible rather than hidden — the discipline §5.2 and §1.4 demand.

### 5.1 Comparability — the rule that governs everything

`scripts/cross-model-review.py` runs **diff inline, no tools, single pass**. The full
pipeline runs **agentic, multi-critic, with fact-check and synthesis**. These measure
different objects and their numbers must never be placed in one table without the config
column.

- The **only** prior rows directly comparable to an OpenRouter sweep are **Result 10**
  (opus 5 vs opus 4.8, headless diff-inline).
- A Gemini or Kimi run without the role-skill prompts measures *that model plus a
  paraphrase*, not the pipeline. Given Result 8a, that gap is larger than the tier gap you
  are trying to measure. If the goal is "would this model be a good critic here," it must
  run the actual role prompts.

### 5.2 Score on detection, not on tier

Tier is the least stable output in the system (J_self on 🔴 rows: 0.14–0.25). Cross-model
J computed over *bands* will measure noise. Compute it over **issue identity** — same file,
same underlying mechanism, band-agnostic — which is what §1.1 of
`experiment-results-full-pipeline-tiers-2026-07-30.md` uses and what Result 14a's 0.49/0.56
figures are.

### 5.3 Hypothesis updates from the 2026-07-30 full-pipeline arm

Amend `research-cross-model-review-hypotheses.md` before using it (the OpenRouter cross-model
arm, §5.0, adds a second corroboration to **H5** — the incumbent's D2 abstention is false
assurance from a third model, sonnet/fable being the first two — and independent confirmation
of **H7/Trap-4** from the generation side):

- **H4 (cross-file defects above the ceiling for every model) — falsified as stated.**
  MD1 R1 was recovered by opus under the full pipeline, with both call sites and the exact
  fix the human shipped. The ceiling is a property of the **single-pass config**, not of
  models. H4's decision ("no amount of model spend fixes this — it's a context problem")
  is wrong as written: multi-critic breadth sufficed, with no retrieval layer. **Caveat:
  n=1** — this is open question #1 above.
- **H5 (small models are net-negative as gates) — widen it.** False attestation on a
  branch's actual 🔴 was observed at **sonnet and fable**, with the disconfirming evidence
  present in the same run's own fact-check. A precision floor keyed on model size will not
  catch this. Any vendor added to a panel needs its *clean verdicts* audited, not just its
  findings.
- **H7 (adjudicator blind spot, doc-deferent) — extends to reviewers.** Result 15: opus r1
  reached ND2's defect and cleared it by deferring to the docstring. Result 14a: opus r2
  rejected the docstring and *still* under-tiered it, via the §1.2 gate. Doc-deference and
  the escalation gap are two separate failure modes that produce the same outcome.
- **H1 (non-total ordering) — replicated per-row.** On MD1: opus found R1 and demoted R2;
  fable found R2 and cleared R1. Neither set contains the other.

### 5.4 Four traps this program has already hit

1. **Rubric selection by filename.** These repos carry *older* rubrics in-tree from
   previous branches. `ls docs/reviews/code-review-rubric*.md | head -1` silently returns
   the wrong file. Select by **content** — match the reviewed commit SHA and the run date.
   (`scripts/self-improvement.sh:1404` still has this bug.)
2. **Acceptance-filtered corpora.** Persisted historical rubrics are ~99% "precise" by
   construction — findings the author rejected never got committed. Worse, per Result 14
   they are also blind to defects the original panel never raised. Retrospective precision
   measurement is exhausted; only fresh runs give raw numbers.
3. **Temporal leakage.** Reconstruct pre-fix state in a detached worktree and **verify** no
   worktree contains its own rubric — do not assume. Reading files at current HEAD leaks
   the fix.
4. **`documented as intended`.** The dominant false-negative *and* false-positive class is
   true-mechanism / disputed-intent. An in-code comment asserting a behavior is deliberate
   has repeatedly beaten correct reasoning — in adjudicators (Result 7's F18) and in
   reviewers (Result 15). The same docstring ("a deliberate small mercy") has now defeated
   two separate agents in two separate arms, and §5.0 confirms it from the *generation*
   side across three of four cross-vendor wins. Treat intent claims as evidence to be
   weighed, never as dispositive.

   **The pipeline manufactures this trap for itself.** Across the archived reports, nine
   recommend *adding an intent comment* as the remedy — five as an equal-weight alternative
   to fixing the code — and the next run's fact-check then rates that new comment
   `Verified`. A review that closes a finding by documenting the behaviour has converted a
   defect into a permanent blind spot. Cut this remedy regardless of which candidate in
   `docs/working/dd-code-intent-claims.md` lands.

### 5.5 Reusable harness

Full-pipeline runner and worktree recipe: §Reproduction of
`docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md`. Headless invocations
need `--permission-mode acceptEdits` and `--add-dir` (§1.5) or they silently degrade.
Ground-truth diffs with reconstructable pre-fix state and surviving rubrics: ND2
`2d0ee3c`, ND3 `319f229` (nature_photographer), MD1 `d86d2dc..d90d6bb`
(meta-formalism-copilot).
