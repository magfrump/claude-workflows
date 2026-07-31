# 028 — A second corroboration channel for the escalation gate: the Soundness-Contradiction channel, terminal at 🟡

**Goal**: Decide what second corroboration channel (and/or owner-cap change) the
`code-review` escalation gate gets, so a correctly-reasoned soundness defect (the ND2
FLEE/CONTENT inversion class) can reach a merge-relevant band.
**Project state**: `exp/cross-model-openrouter-sweep` branch delivering the cross-model
evaluation program's fixes to the review pipeline · implements
`docs/thoughts/code-review-evaluation-state.md` §1.2, which routed this decision to
divergent-design explicitly · not blocked.
**Task status**: complete (decided, implemented, and validation replay run 2026-07-30 —
falsifier passed with recalibration needed; see Addendum. The 🟡 cap stands.)

## Context

On ND2, opus reached the ground-truth defect (a FLEE-interrupted song still grants
CONTENT, mechanically converting the intended penalty into the table's largest
approachability bonus), explicitly rejected the "deliberate small mercy" docstring,
reconstructed the full consequence, noted it is invisible to tests — and filed it **🟢**
(Results 15 + 14a). The historical human panel filed the same finding **🟡 and gated the
merge on it**. Nothing was missed; the finding landed two bands low because the promotion
gate had no channel it could use. Two structural causes (state doc §1.2): (a) promotion
requires a fact-check `Incorrect` or api-consistency `Breaking`, verdicts a
correctly-documented soundness defect can never earn (all 4 of 4 cells that fact-checked
the docstring rated it `Verified / High` — *correctly*); (b) the **owner cap** —
"Contextual critics are advisory" hard-caps contextual-critic findings at 🟢 regardless of
internal severity, and the Escalation Rule bars them from escalation entirely; ND2's one
correct reconstruction was filed by `tech-debt-triage`, while the two ND3 cells that got
the same defect right filed it under 🔴-capable `architecture-review` and landed 🟡.

Full diverge/diagnose/match prose: `docs/working/dd-escalation-second-channel.md`.
Adjacent DD (constraining input): `docs/working/dd-code-intent-claims.md`, which fixed the
*reasoning* half (intent-coherence move on architecture-review) and deliberately left the
channel and owner cap to this decision.

## Options considered

Fifteen candidates (full list and matrix in the working doc): status quo; defer until
validated; a fourth corroboration bullet (🔴-capable, and a 🟡-capped variant 2′); a
failing-test requirement (Thread 7); in-run and async human queues; full owner-cap
removal; severity-keyed cap softening; ownership re-file under a 🔴-capable domain;
a fact-check soundness verdict; a dedicated soundness critic; restoring convergence
escalation; a Stage-3 **Contested-Soundness cross-check** (chosen); instrument-only
annotation; and validate-then-authorize (ideal-if-free). Scored against eight hard
constraints, the load-bearing ones being: **H2** no blocking authority for unvalidated
mechanisms (the Escalation Rule's own "Why this changed" history removed
convergence-escalation for carrying merge-blocking authority on untested n≈5; decision
25's Contested mechanism shipped 🟡-terminal for the same reason), **H3** the trigger must
be artifact-checkable rather than a same-model severity opinion, **H4** the coherent-doc
deference path (right ~70% of the time) must survive, **H7** both structural causes must
be addressed, and **H8** the destination band must equal the human panel's ground truth
(🟡).

## Decision and rationale

**Adopt candidate [12]: a Soundness-Contradiction channel, implemented as a Stage-3
cross-check in `skills/code-review/SKILL.md`, terminal at 🟡.**

- **Trigger (all three parts required, artifact-checkable):** a critic report — from any
  critic, contextual critics included — (1) quotes a **stated intent** verbatim with
  `path/to/file:line` (design doc, sibling comment/docstring, spec the code cites, or
  `<pr-intent>`), (2) quotes or reconstructs the **code's actual mechanism** verbatim with
  `path/to/file:line`, and (3) itself states that the mechanism **defeats or inverts** the
  stated intent. An intent claim alone, a missing quote on either side, or disagreement
  with a design's *wisdom* never qualifies.
- **Action:** the finding is placed in (or moved to) `## 🟡 Must Address` with
  `Severity: Contested-Soundness`, `Source: Soundness cross-check (found by <critic>)`,
  both quotes verbatim as evidence, and the lift named in the chat synthesis.
- **Owner-cap exception (the one exception):** the cross-check applies regardless of which
  critic filed the finding — this is the only path by which a contextual-critic finding
  leaves 🟢. The advisory rule otherwise stands unchanged.
- **🟡 is terminal:** the lift never promotes to 🔴 and does not count as corroboration
  under the Escalation Rule (mirroring decision 25's Contested precedent). The existing
  executed-evidence corroboration remains the path by which such a finding can reach 🔴 —
  if someone produces the failing test, the current rule already promotes it.

One-sentence rationale: this is the only candidate that addresses **both** structural
causes while granting no blocking authority to an unvalidated mechanism — it reuses,
symmetrically, the one adjacent mechanism this program has actually validated (decision
25's cross-check: retrospectively 2/2 catches, 0 wrong kills), lands the ND2 class on
exactly the band the human panel used (🟡: "fix it or say on the record why it stands"),
keys on quotes a human can re-verify in seconds rather than on any critic's severity
label, and costs zero extra dispatches.

Falsifiable hypothesis (chosen candidate): a Stage-3 pass over the archived
`nd2-opus-r2` artifacts lifts its C1 reconstruction to 🟡 `Contested-Soundness`, while
replays over ND3's fixed `sim.ts:625-628` docstring and md1's `proxy.ts:14` carve-out
lift nothing (3/3), within one replay session; counter-evidence = any lift on a negative
control, or no lift on ND2 because critics in practice never quote both sides verbatim.

See alternatives considered → **Pruned candidates and why** below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in
adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[0 status quo]: is the thing being fixed (fails H7/H8 — the ND2 class has no channel).`
`[1 defer-until-validated]: honest but leaves the observed miss unhandled; survives as a revisit trigger (if the falsifier's negative controls fail, revert to this).`
`[2 🔴-capable corroboration bullet]: ⚠ H2 — an unvalidated trigger reaching 🔴 is the exact shape the Escalation Rule's "Why this changed" history removed.`
`[2′ 🟡-capped bullet]: step-4 runner-up (within ~1 cell); loses on H7 — leaves the owner cap intact, so tech-debt-triage-found ND2 still lands 🟢; fixing that converges it to [12] anyway.`
`[3 failing-test requirement]: ⚠ H6 and the ND2 defect is untested by construction ("invisible to tests"); executed evidence is already a listed corroboration — kept as the existing 🟡→🔴 path, not a firing requirement [carried from dd-code-intent-claims [8]: fails the true-positive path].`
`[4 in-run human queue]: fails H1 — headless Gate 1h has no human at decision time [carried from dd-code-intent-claims [10]: "a gate that never gates"].`
`[5 async queue only]: changes no outcome (✗ H7/H8) and the override log is empty in all 11 run trees — unforced write channels don't get written; absorbed as an obligation (lifts are named in synthesis; adjudications land in the override log Step 3.5 re-reads).`
`[6 full owner-cap removal]: ⚠ H2 / ✗ H3 — grants 🔴-capable native mappings on an opinion, and open question #6 (does removing the cap change ND2?) is untested.`
`[7 severity-keyed softening]: ✗ H3 — keys banding on the critic's internal severity label, an opinion, in the least stable output dimension.`
`[8 ownership re-file]: absorbed into [12] — with a mechanical trigger and a 🟡 cap it is [12]; without them it is an orchestrator opinion inheriting an unvalidated 🔴 path.`
`[9 fact-check soundness verdict]: [carried from dd-code-intent-claims §4.2c: the checkable half of this class is already in scope and already produces 🔴s; the marginal population is the corpus's highest-variance verdict class].`
`[10 dedicated soundness critic]: ⚠ H2 / ✗ H6 — mints new 🔴 authority from an unvalidated judgment at a full extra dispatch; its boring form already shipped as the intent-coherence move.`
`[11 restore convergence escalation]: ✗ H3 by the rule's own history — critics are the same model, errors correlated by construction; the most-converged historical escalation was human-waived.`
`[13 instrument only]: ✗ H7/H8 — Result 14a is standing evidence that recording correct reasoning does not move the band; data without a consumer.`
`[14 validate-then-authorize]: staged into [12] — [12] plus its falsifier and revisit triggers is stage 1 of [14] with the 🟡 cap as the safety interlock; the standalone program risks never running (override-log precedent).`
`Prior pruning grep: matches found for [escalation, corroboration, severity, contextual critic, owner cap, tier, blocking, gate] — [carried from 017-polyglot-test-hermeticity candidate 9: "an LLM critic is a detector, not an enforcement primitive" → constraint H3]; [revived from dd-code-intent-claims candidate 12 ("reframe: fix the channel"): pruned there only by that DD's own scope constraint H3, and the state doc routes §1.2 here explicitly].`

## Stress-test mitigations

- How to read: *Invert-the-thesis* mitigation — arguing sincerely that the escalation gap
  should stay (the rule's history shows true-but-unwanted escalations, the most-converged
  one human-waived) promoted the 🟡 cap from a design choice into hard constraint H2's
  success line: the channel must never mint 🔴 from opinion; what does not survive the
  inversion is leaving 🟢, whose meaning ("consider") mis-states a live behavioural
  inversion the human panel merge-gated.
- How to read: *Boring-alternative* mitigation — the measure-first candidate [13] was
  tested as the 80% version and refuted by Result 14a (the correct reasoning and native
  severity were already recorded and the band did not move); the genuinely boring form is
  reusing decision 25's already-validated cross-check template, which [12] does verbatim
  (Contested-style severity, terminal 🟡, barred from escalation corroboration, named
  revocation/lift in synthesis).
- How to read: *Failure-driven* mitigation — three new failure classes were enumerated
  and guarded: false lifts on coherent rationale docstrings (the three-part verbatim
  quote-pair trigger plus the ND3/md1 negative controls in the falsifier); confusion with
  the Confirmed-Good cross-check's rows (distinct fixed vocabulary: `Contested` vs
  `Contested-Soundness`, distinct `Source:` values); Goodhart pressure on authors to stop
  stating intent near code (trigger scope includes design docs and `<pr-intent>`, not
  only adjacent comments, and dd-code-intent-claims' anti-comment-remedy obligation
  stands).
- How to read: *Organizational-survival* mitigation — the mechanism deliberately reuses
  the decision-25 shape rather than introducing a second one, so a future maintainer
  meets one cross-check template twice; a false lift's cost is bounded by design (a 🟡
  dismissal costs the author one on-the-record sentence, which is the intended behaviour
  for a contested soundness question, not a failure).

## Consequences

**Easier:** the ND2 class (correctly-reasoned soundness defects, including
correctly-documented bad design) now has a band-reaching channel regardless of which
critic finds it; the owner cap gains a principled, narrow, evidence-gated exception
instead of an untested removal (this also begins answering open question #6 with per-run
data); every lift is an auditable row carrying re-verifiable verbatim evidence; the
Gate-1h loop is unaffected (the gate is red-only and the channel is 🟡-terminal).

**Harder:** 🟡 may acquire false lifts until the firing precision is measured — the
mechanism is **unvalidated**, which is why it ships with no blocking authority; the
rubric vocabulary grows a second Contested-variant severity; authors must adjudicate
contested soundness rows on the record.

**Implementation status:** implemented in `skills/code-review/SKILL.md` (new
`### Soundness-Contradiction Channel` section, a Stage-3 cross-check step, and
exception cross-references in the advisory rule, the Escalation Rule, and Important
Reminders), with a bats contract suite at
`test/skills/code-review-soundness-crosscheck.bats`. Implementation proceeded because the
change is small, skill-text-only, and consistent with the repo's "advisory first, no
blocking authority for unvalidated mechanisms" rule — the channel grants 🟡 (conditional
pass) at most, exactly the decision-25 precedent. **The validation replay (the falsifier
above) has not run**; until it passes, the 🟡 cap must not be lifted.

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt
re-evaluating this decision. Future readers can grep this section when their context
changes to see whether earlier decisions still apply.

`if the falsifier's replay lifts a row on ND3's fixed sim.ts:625-628 or md1's proxy.ts:14 (either negative control) → tighten the trigger or revert to candidate [1]. if the ND2 replay produces no lift in 2/3 sessions because critics don't quote both sides → the quote-pair bar is unreachable in practice; consider requiring critics to emit the quote pair explicitly. if ≥3 Contested-Soundness rows across 10 archived rubrics are adjudicated wrong by the author → the precision guard is too loose; re-run this DD's step 4. if the replay validation passes (ND2 lift ≥2/3, negative controls 0/3) and a corpus of ≥10 correct lifts accumulates → a follow-up decision may consider the 🟡→🔴 question, which this record deliberately does not grant. if open question #6 is answered directly (an owner-cap-removal replay on ND2) → fold its result into the exception's scope. if the Escalation Rule is redesigned wholesale → this channel's "does not corroborate escalation" bar must be re-derived, not assumed.`

## Addendum

**2026-07-30 — validation replay run** (`docs/working/validation-soundness-channel-2026-07-30.md`): falsifier **passes 3/3 as written** (ND2 C1 lifts 🟢→🟡 with both verbatim quotes; md1 `proxy.ts:14` 0 lifts across 7 probes, precision guard held; ND3 `sim.ts:625-628` 0 lifts but **vacuous** — no ND3 report text touches it), yet the full-corpus sweep (315 findings) finds 4 clear false lifts (~1.3%, 3 distinct issues; dominant shape: convention-contradiction findings that quote a module-header principle) plus 2 debatable — adjacent to the "≥3 adjudicated wrong" revisit trigger — so the verdict is **pass-with-recalibration-needed**: tighten trigger condition 3 to *behavioral* defeat/inversion (excluding convention/hygiene contradictions and fact-check-`Incorrect`-class doc falsehoods), add an already-≥🟡 no-op clause, and define "verbatim" to admit bracketed alterations (the positive case needs the `[is]` bracket to count). The 🟡 cap stands; do not loosen the trigger's file:line bar.
