# Code review: what the evaluation program has established

> Living synthesis across every measurement arm run against this repo's `code-review`
> skill. Read this before designing a new arm, changing the skill, or interpreting a
> cross-model result. It is the shortest path to "what do we actually know."

Last verified: 2026-07-30
Relevant paths: skills/code-review/SKILL.md · skills/code-fact-check/SKILL.md · scripts/self-improvement.sh · scripts/cross-model-review.py · docs/working/experiment-results-code-review-2026-07-29.md · docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md · docs/working/experiment-cross-model-review-2026-07-30.md · docs/decisions/021-reviewer-context-management.md · docs/working/research-cross-model-review-hypotheses.md

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

## The one-paragraph state of things

The pipeline **detects** well and **tiers** badly. Across every arm, whether a real defect
gets *found and correctly described* is far more stable than what severity band it lands
in. The single gate that converts a finding into a blocker — a `code-fact-check` verdict of
Incorrect, or an api-consistency Breaking — is both unstable run-to-run and structurally
unreachable for whole classes of real defect. Every high-value action below follows from
that one sentence.

---

## 1. Definitely needed (evidence is direct, and the failure has been observed)

### 1.1 Run `code-fact-check` k≥3 times and combine, before anything downstream

**Why.** Per Result 16, a fact-check Incorrect verdict is the *only* thing that promotes a
finding to 🔴. Per Result 14a, that verdict is unstable on identical input: the same
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

### 1.3 Stop treating `✅ Confirmed Good` as an output; treat it as a claim requiring evidence

**Why.** Result 12. On MD1, **two of three tiers filed the branch's actual blocking defect
under Confirmed Good.** Fable's own fact-check report recorded the disconfirming evidence
verbatim — *"client fetches are all relative `/api/…` paths or `data:` URLs in
`app/lib/utils/exportGraph.ts:24,37`"* — and its security review then certified
`connect-src 'self'` as **"matches reality."** Sonnet did the same.

Result 8b observed this shape at haiku and it was recorded as a small-model property. It is
**not tier-bounded.** Confirmed Good is the highest-assurance row the rubric emits and
nothing currently checks it.

**Minimum action:** require every Confirmed Good row to carry an `Evidence:` citation, and
add a synthesis-stage cross-check that no Confirmed Good row contradicts an observation in
the fact-check report. That specific cross-check would have caught the fable miss.

### 1.4 Never let a single run's clean verdict stand as assurance

Corollary of 1.3 and H5. A "no findings" result from one run is not evidence of absence —
it is one sample from a distribution whose 🔴-level self-agreement is ~0.2. Anywhere a
verdict is *consumed as assurance* (Gate 1h, pr-prep sign-off), require either
corroboration or an explicit "single-sample, not an attestation" label.

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
| 1 | Does MD1 R1's recovery replicate? | It is the sole evidence that the pipeline clears the cross-file ceiling, and the basis for "config, not model." **n=1.** | **Run this next.** |
| 2 | How often do fact-check verdicts disagree across replicates? | Sets k in §1.1 and quantifies the blocking channel's noise floor. | Unmeasured |
| 3 | Is the MD1 nonce-delivery issue really 🔴? | Three independent configs say 🔴, history says 🟡. Settled empirically by one prod build. | Unresolved since Result 8b |
| 4 | Does a Confirmed-Good-vs-fact-check cross-check actually catch the misses? | Cheap to test retrospectively against the 9 existing cells. | Not attempted |

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

- **Context management is now decided — 021.** That sibling-commit FP class forced the
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
   two separate agents in two separate arms. Treat intent claims as evidence to be weighed,
   never as dispositive.

### 5.5 Reusable harness

Full-pipeline runner and worktree recipe: §Reproduction of
`docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md`. Headless invocations
need `--permission-mode acceptEdits` and `--add-dir` (§1.5) or they silently degrade.
Ground-truth diffs with reconstructable pre-fix state and surviving rubrics: ND2
`2d0ee3c`, ND3 `319f229` (nature_photographer), MD1 `d86d2dc..d90d6bb`
(meta-formalism-copilot).
