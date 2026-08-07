# Tech Debt Triage — code-review token-lever calibration

Commit: 2f5ad0b
Range: `HEAD~3..HEAD` (de9ccf7, 45fa1df, 2f5ad0b) · 14 files, ~1133 insertions
Reviewer: tech-debt-triage (contextual critic, auto-selected on diff size)
Date: 2026-08-07

**Scope note.** Only content introduced or surfaced by `HEAD~3..HEAD` is triaged. Everything else in
the repo — including the rest of `skills/code-review/SKILL.md`, the canon `token-ledger.md`, and the
`runs/review-arms/` sibling directories — is *already committed, context only*. Where an item cites a
pre-existing line as debt, it is because this range's changes made that line wrong or made it matter.

---

## Tech Debt Triage: three un-updated self-read instructions contradict the new conditional diff-inlining policy

**Location:** `skills/code-review/SKILL.md:340-344`, `:634`, `:1406` (contradicting `:99` and `:228-285`)
**Nature:** documentation-consistency (in a repo where the documentation *is* the executable process)
**Cost of Deferral:** +1 mis-dispatched pipeline stage per orchestrator run that reads the Stage-1/Stage-2 dispatch steps instead of the Step-1 policy line
**Failure Cost:** Med × Med — an orchestrator that follows `:634` verbatim never inlines, so #3 captures nothing, and the next measurement run silently re-measures the pre-#3 structure while believing it measures the post-#3 one.
**Legibility-target:** for-author

**Evidence** — the new policy, `SKILL.md:99`:
> Diff delivery to agents is conditional (decision 032 #3, see [Inline shared-context prefix](#inline-shared-context-prefix-decision-032-3)): for a normal-sized diff, inline it once as the shared cacheable prefix of every agent prompt; for a **large diff** (the ~1000-line / >40%-churn threshold below), do **not** inline — pass the scope specification so each agent runs its own `git diff`, avoiding context-budget blowup. When in doubt on size, prefer self-read.

The three un-updated instructions, verbatim:
> `:340-344` — `3. Include the scope specification (e.g., "Review files changed on the current branch relative / to main using `git diff main...HEAD`"). If the scope is partial (`--range`, `--staged`, / `--files`, or a partial `--pr`), also include the labelling block required by Step 1's / partial-scope rule — the "already committed — context only, not under review" statement and / the check-siblings-before-flagging-missing directive apply to fact-check replicates too.`

> `:634` — `3. Include the scope specification so the agent runs its own `git diff`. If the scope is`

> `:1406` — `- **Pass scope, not diffs.** Each agent runs its own `git diff` to avoid context budget issues.`

### Carrying Cost: Medium

`:1406` is the worst of the three: it sits in the skill's terminal "non-negotiables"-style bullet list,
which is the section an orchestrator is most likely to treat as the authoritative summary, and it states
the *inverse* of the new policy as an unconditional rule ("Pass scope, **not** diffs"). `:634` is the
Stage-2 dispatch step — the exact instruction an orchestrator executes when building critic prompts —
so it is not merely descriptive prose but the operative step. `:340-344` is milder: it commands
including the scope spec, which remains true in both modes, and only implies self-read by omission of
the diff. The contradiction is invisible to any automated check: the format-contract test
(`test/skills/code-review-format-contract.bats:143-193`) synchronizes only the rubric template's
section headings and table headers against `SKILL.md`, never the pipeline prose, so nothing in the
suite fails today or would fail after the fix.

### Fix Cost
- **Scope:** Localized. Three edits in one file; no consumer file reads these lines (`rg` over
  `test/`, `scripts/` finds only the rubric-template sync in
  `test/skills/code-review-format-contract.bats:152`).
- **Effort:** ~15 minutes. Reword `:1406` to the conditional form, add a "(or inline it per the
  size guard)" clause at `:634`, and a parallel clause at `:340-344` so Stage 1 matches Stage 2.
- **Risk:** Low, with one real trap: `:99` already carries the full conditional statement, so
  restating it three more times grows the very redundancy that item 5 flags. Prefer a one-clause
  cross-reference at each site (`see Step 1's diff-delivery rule`) over a copy of the policy — copies
  are what produced this drift in the first place.
- **Incremental?** Yes, fully. Each of the three is independent; `:1406` alone removes most of the risk.

### Urgency Triggers
- The next `--loop-pass` production review run that is supposed to exercise #3 — an orchestrator
  reading `:634` or `:1406` dispatches in self-read mode and the run's cache numbers are wrong.
- Any future measurement of #3 against the canon (the natural follow-up to
  `levers-3-4-measurement.md`), which would be silently invalidated by a self-read dispatch.
- A `code-review` run over this repo itself — the skill is its own subject, so the contradiction is
  in-scope for its own fact-check (this is precisely how it was found).

### Recommendation
**Recommendation:** Fix now

Trivial by the skill's own bar (single file, three one-line edits, well under 50 LOC), so fix in place
rather than routing to RPI. The reason to do it now rather than opportunistically is that the whole
point of commit 2f5ad0b was to make #3 real; leaving the operative dispatch step (`:634`) and the
summary bullet (`:1406`) telling the orchestrator to do the opposite means the change may not actually
take effect in the next run, and the failure is silent.

---

## Tech Debt Triage: decision 032's #3 verdict still describes the pre-inlining loop in the present tense

**Location:** `docs/decisions/032-review-loop-token-reduction-levers.md:120-126`
**Nature:** documentation-consistency / decision-record provenance
**Cost of Deferral:** +0 — inert (the paragraph's numeric conclusion, ~5% cost / 0% token count, remains correct; only its "not yet done" framing is stale)
**Failure Cost:** *(omitted — no material blast radius; a decision record is read by humans, not executed)*
**Legibility-target:** for-author

**Evidence** — `032:120-126`, verbatim:
> - **#3 prompt-cache: ~5% cost-equivalent, 0% token-count — NOT 20–40%.** The 20–40% estimate was
>   inherited from the cross-model harness, which *inlines the whole diff into the prompt*. The
>   production Agent-tool loop does **not** inline — critic agents self-read the diff/files/fact-check
>   via tools — so the shared cacheable *prefix* is small (~330 tok as-run). Caching is also a
>   billing-rate effect, invisible to the token-count metric. Realizing even the ~5% needs a SKILL
>   restructure to inline the shared diff+fact-check prefix. **Verdict: leave caching on (free),
>   but it is a single-digit-% cost lever on this path, not an H3-clearing one.**

And `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:56-59`, which recommends against
the restructure that the same range then performed:
> **Where #3 does earn more**: *across passes* in a fix loop, the diff+context prefix is stable
> between a fix and its re-review, so the cache stays warm pass-to-pass. That's a loop-only multiplier
> on the ~5% above — still cost-side, still invisible to token counts. Worth having (caching is
> free to leave on), not worth a big SKILL rewrite to force-inline.

### Carrying Cost: Low

Both statements were accurate when written and neither is a *number* that is now wrong — the ~5% and
~330-token figures still stand. What is stale is the tense and the recommendation: "does **not**
inline" and "needs a SKILL restructure" describe a world that commit 2f5ad0b ended, and the levers
doc's "not worth a big SKILL rewrite to force-inline" is now a recommendation the repo declined to
take, with no note saying so. The cost is confined to a future reader reconstructing why the SKILL
inlines when the decision record says it doesn't — genuine confusion, but slow-acting and self-
correcting once they check `git log`. Note the asymmetry with item 1: 032 is a *record*, so a reader
who trusts it is merely misinformed; `SKILL.md` is an *instruction*, so a reader who trusts it acts
wrongly. That is why these two rate differently despite being the same drift class.

### Fix Cost
- **Scope:** Localized — one sentence in 032, optionally a one-line "superseded 2026-08-07" note in
  `levers-3-4-measurement.md`.
- **Effort:** ~10 minutes.
- **Risk:** Low, but with a convention question: run artifacts under `runs/` are arguably an
  append-only measurement record (the canon `review-canon.md` is explicitly append-only), in which
  case the levers doc should *not* be edited in place and the amendment belongs in 032 only. The
  levers doc already carries an `**EMPIRICAL UPDATE (2026-08-06, ...)**` block at `:94`, which
  establishes append-a-dated-block as the in-repo precedent — follow that, don't rewrite `:56-59`.
- **Incremental?** Yes — the 032 sentence and the levers note are independent.

### Urgency Triggers
- None imminent. Escalates only if a future decision cites 032's #3 paragraph as evidence that the
  loop self-reads (e.g. when scoping a #3 re-measurement, or when deciding whether the cross-model
  harness guard at `SKILL.md:281-285` still applies for the stated reason).

### Recommendation
**Recommendation:** Fix opportunistically

Bundle it with item 1 — the same reader who is fixing the SKILL's three stale lines has the full
context loaded, and 032 is the record that explains those lines. Doing it standalone is not worth a
context load; doing it alongside item 1 costs almost nothing.

---

## Tech Debt Triage: per-agent token figures exist only as prose, sourced from ephemeral task notifications

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-verify/results.md:3-4,9-19,23-31,57-59`;
compare the canon ledger `runs/review-arms/baseline-2026-08-06/token-ledger.md:1-3`
**Nature:** measurement-provenance
**Cost of Deferral:** +1 unreproducible headline figure per measurement run that reports tokens without a ledger row
**Failure Cost:** Med × High — the 73% figure now propagates into `SKILL.md:276-282`, `032:127-138`, and `log.md` row 34; if it is wrong or was mis-transcribed there is no artifact against which to catch it, and every downstream doc inherits the error with no way to detect it.
**Legibility-target:** for-author

**Evidence** — `hunt-verify/results.md:3-4`, the entire stated provenance:
> Per-agent tokens from task notifications. Both candidates run as a single `--loop-pass`: fact-check
> first, then (absent a short-circuit) the Stage-1.5-gated critic panel.

and `:57-59`:
> ## Measurement cost
> A pass 252,992 (fc 66,717 + panel 186,275) + B panel 238,155 + B fc 86,824 = **577,971 tokens**
> (plus the earlier 3-agent history hunt ≈ 335k).

Contrast the canon's persisted instrument, `token-ledger.md:1-3`:
> # Baseline token ledger (current 031+032 setup, single pass, k=1)
>
> Tokens = subagent_tokens from task notifications (same instrument as E1/E3). Append as stages land.

### Carrying Cost: Medium

The canon run established the right pattern — a standing `token-ledger.md` with a per-cell, per-stage
table, appended as stages land, so every aggregate in a downstream doc traces to a row. The
hunt-verify run did not follow it: the eight per-agent numbers live only inside two prose tables in
`results.md`, and their source (task notifications) is gone the moment the session ends. Three of the
four arithmetic claims are self-checking — 86,824 + 238,155 = 324,979 and 238,155/324,979 = 73.3%
both verify, as does 66,717 + 186,275 = 252,992 — so the *derivations* are sound; it is the eight
*inputs* that are unreproducible. The ≈335k hunt figure is worse: it carries no table at all, only
the "≈", and it feeds the measurement-cost total that justifies the run's expense. Note this is
narrower than "the measurement is untrustworthy": the numbers are internally consistent and the
qualitative conclusion (rare trigger, large when it fires) rests on the 1-of-2 candidate split, not
on the token precision, so a transcription error would move the 73% but not the verdict.

A second, smaller strand of the same debt: `SKILL.md:276-277` labels the #3 benefit **"Measured"** —
> - **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a
>   billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect
>   it to move the token-count ledger.

but `levers-3-4-measurement.md:33-34` is explicit that the ≈157k figure behind it is a **projection**
from measured *sizes* ("measured sizes; tokens ≈ chars/4; saving = prefix_tok × (N−1) × 0.9"), not a
measured saving. "Measured" is doing work it hasn't earned there.

### Fix Cost
- **Scope:** Localized for the retrospective part (add a ledger section to the existing
  `token-ledger.md`, or a sibling `hunt-verify/token-ledger.md`, transcribing the eight figures with
  their stage and candidate); cross-cutting for the preventive part (making "measurement runs emit a
  ledger" a stated convention rather than a habit the canon happened to follow).
- **Effort:** ~20 minutes retrospective; a half-day if the preventive convention is written into the
  SKILL or a run-artifact template.
- **Risk:** Low retrospectively — but the retrospective fix is *cosmetic*, and worth naming as such.
  Transcribing prose numbers into a table does not restore provenance; it relocates the same
  unverifiable figures. The honest version adds a "source: task notifications, session
  session_01VTX7uRsrHmGcxektthfbWX, not independently re-derivable" caveat rather than implying the
  ledger is a primary record.
- **Incremental?** Yes. The one-line "Measured" → "Projected" correction at `SKILL.md:276` is
  independent and immediate; the ledger and the convention are separable.

### Urgency Triggers
- The next measurement run (a #3 re-measurement after inlining is the obvious one) — that is the
  moment to have the convention in place, because it is cheap during the run and impossible after.
- Any attempt to compare the hunt-verify numbers against a future run: without a ledger the
  comparison has nothing to join on.
- Uncertainty flag: I cannot tell from the artifacts whether task notifications are recoverable from
  session storage. If they are, this item is nearly free to close properly; if not, the retrospective
  half is permanently cosmetic.

### Recommendation
**Recommendation:** Fix opportunistically

The one-line `SKILL.md:276` "Measured" → "Projected" correction should ride along with item 1 — it is
the same file and the same edit session. The ledger and the emit-a-ledger convention should wait for
the next measurement run, where the cost is marginal and the artifact is a primary record rather than
a retrospective transcription. Fixing it now, in isolation, buys the appearance of provenance without
the substance.

---

## Tech Debt Triage: two factual defects frozen into committed, decision-feeding run artifacts

**Location:** `runs/review-arms/baseline-2026-08-06/hunt-factcheck-behavioral-lie.md:58-61`;
`runs/review-arms/baseline-2026-08-06/hunt-verify/candB-fact-check.md:8-9` and `:129-131`
**Nature:** documentation-consistency / evidence-artifact integrity
**Cost of Deferral:** +0 — inert (both errors are self-refuting from adjacent lines in the same file; neither is cited by a downstream doc)
**Failure Cost:** Low × Med — a reader who quotes the hunt doc's "both already fixed, HEAD clean" conclusion without reading the candidate entries would mis-describe the upstream repo's state, but the range's own decision text does not rely on it.
**Legibility-target:** for-author

**Evidence** — the hunt doc's conclusion, `:58-61`:
> - **The scarcity IS the result.** One clean fact-check trigger (throttle) and one cross-file/prompt
>   case (evidence-integrate) in 225 commits, both already fixed, HEAD clean. In a maintained repo the
>   condition that fires #4's high-value path is rare — matching the canon's 0/8. #4 stays a
>   loop-safety option, not a reliable token reducer.

contradicted by the same document's own candidate-A entry, `:12-13`:
> - **Exhibiting commit**: `e59c7ed` (feat: SSE streaming partial-JSON previews, #94) — introduced the
>   utility + the false comment; the comment persists **unchanged at HEAD**.

And the candB report's header, `candB-fact-check.md:8-9`:
> **Total claims checked:** 9
> **Summary:** 7 verified, 0 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

contradicted by its own body: the file contains nine `## Claim` sections whose verdicts are
Verified ×8 (claims 1, 2, 4, 5, 6, 7, 8, 9) and Incorrect ×1 (claim 3) — i.e. 8 verified / 1 incorrect
/ 0 unverifiable. A third, cosmetic instance sits at `:129`, which cites
`integrateValidation.ts:56` where the fact-check's own quoted evidence line resolves to `:51`.

### Carrying Cost: Low

These are errors in a *finished* artifact, which is what caps the cost. Nobody edits a run report;
its only consumers are readers, and both defects are refuted by text within a few dozen lines of
themselves — the hunt doc's own line 13 says the comment persists at HEAD, and the candB body's nine
verdicts are individually labelled. The claim-count error is the more embarrassing of the two given
the artifact is itself a fact-check report, but it changes no conclusion: candidate B fires #4 because
of the one Incorrect(High) behavioral claim, and that claim is present and correctly analyzed at
`:68-131` regardless of whether the header says 7 or 8 verified. The hunt doc's "HEAD clean" is the
one with actual reach, because it is the doc's *summary* line and the kind of sentence that gets
quoted forward.

### Fix Cost
- **Scope:** Localized — three single-line corrections across two files.
- **Effort:** ~10 minutes.
- **Risk:** Low on the mechanics, but the convention question from item 2 applies with more force
  here: these are measurement artifacts, and silently correcting a committed fact-check report
  removes the evidence that the report was wrong. Prefer an appended, dated correction note over an
  in-place rewrite of the header — the same pattern the levers doc already uses at `:94`.
- **Incremental?** Yes; the three are independent.

### Urgency Triggers
- If the hunt doc's "HEAD clean" line is ever cited as evidence about the upstream repo's current
  state — e.g. when selecting a fixture commit for a future #4 run, where believing HEAD is clean
  would rule out a candidate that is in fact still live at HEAD.
- If `candB-fact-check.md` is used as a golden fixture or a worked example of report format, where
  the header/body mismatch would be copied into a template.

### Recommendation
**Recommendation:** Fix opportunistically

The hunt doc's summary line is worth a dated correction note whenever that file is next opened,
because it is the sentence most likely to be quoted forward and it is flatly wrong about the state of
an external repo. The candB header and the `:56`/`:51` line ref are genuinely cosmetic and can ride
along or never be fixed at all — correcting a finished artifact's arithmetic changes no downstream
claim, and an appended note costs more attention than the error does.

---

## Tech Debt Triage: SKILL.md accretion — 857 → 1440 lines in 17 days, with no mechanical guard on the prose

**Location:** `skills/code-review/SKILL.md` (whole file); measured-caveat prose added this range at
`:99`, `:228-285`, `:491-507`
**Nature:** structural
**Cost of Deferral:** +~35 lines per decision-implementation commit, compounding on every future read of the file by an orchestrator or an editor
**Failure Cost:** Med × Med — the larger the file, the more places a policy is restated, and item 1 is the demonstrated failure mode: a policy changed in one place and stayed wrong in three others. Each accretion round adds new sites for the next drift.
**Legibility-target:** for-author

**Evidence** — measured line counts at each commit touching the file:

| date | commit | lines |
|---|---|---|
| 2026-07-21 | 4582f97 (terse-imperative rewrite of all 25 SKILL.md files) | 857 |
| 2026-07-30 | 923ffca | 1000 |
| 2026-07-30 | b7d71ca | 1274 |
| 2026-07-31 | bcccdc2 | 1318 |
| 2026-08-06 | 2587fea (decision 031 T) | 1335 |
| 2026-08-06 | 09eb87a (decision 032 bundle) | 1415 |
| 2026-08-07 | 2f5ad0b (this range) | 1440 |

For scale, the next-largest skill in the repo is `skills/fact-check/SKILL.md` at 681 lines; the
median critic skill is ~430. `code-review` is 2.1× the largest sibling and ~3.3× the median.

The accretion is *measured-caveat prose* — this range's additions are three blocks explaining what
the numbers turned out to be, e.g. `SKILL.md:276-278`:
> - **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a
>   billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect
>   it to move the token-count ledger.

### Carrying Cost: Medium

The growth is not padding — every added block is a real empirical correction, and a skill that
documents *why* a lever is small is more honest than one that silently drops it. But the file has
absorbed a 68% line increase in 17 days while remaining a single flat document that an orchestrator
is expected to hold in working context, and the mechanism by which that hurts is no longer
hypothetical: item 1 exists because the #3 policy is now stated at `:99`, elaborated at `:228-285`,
and contradicted at `:340`, `:634`, and `:1406` — five sites for one rule. Test coverage does not
help. `test/skills/code-review-format-contract.bats` synchronizes the golden rubric against the
SKILL's *template* (`:143-193`) and nothing else; there is no check that the pipeline prose is
internally consistent, so drift of the item-1 kind is caught only by a human or by running
`code-review` on the repo itself.

Countervailing consideration, stated plainly: the file's size partly reflects that this skill *is*
the product's most-developed surface, and a "split it up" fix has its own failure mode — a policy
split across three files drifts at least as readily as one stated five times in one file, and the
orchestrator would then need to load all three. Size alone is not the problem; restatement is.

### Fix Cost
- **Scope:** Systemic if treated as "restructure the skill" (extract the measured-caveat prose into a
  companion rationale doc, leave imperatives in the SKILL); localized if treated as "stop restating
  policies" (a convention: state each rule once, cross-reference elsewhere — which is exactly the
  item-1 fix done properly).
- **Effort:** Hours for the localized version; days for a split, plus a re-validation pass, since any
  restructure of a skill that has been empirically tuned across decisions 021/028/031/032 risks
  perturbing behavior that was measured against the current text.
- **Risk:** Medium-to-high for the split. This file's content has been validated by measured
  experiments (the 021 partial-scope labelling at `:101` cites a 0/8-vs-6/11 FP result); moving text
  between documents changes what the orchestrator actually reads, which is the independent variable
  those experiments controlled. A restructure would want its own before/after recall check — which is
  a multi-hundred-thousand-token run, i.e. the fix costs more than a measurement round.
- **Incremental?** Partially. The "state once, cross-reference" convention can be applied one policy
  at a time as each is next edited. A structural split cannot be done incrementally with confidence.

### Urgency Triggers
- A second occurrence of item-1-style drift — one instance is a bug, two is a pattern and would
  justify the convention becoming a checked rule.
- A measured recall regression traceable to context length, or an orchestrator visibly failing to
  apply a rule stated late in the file.
- Adoption of the next decision-032-style lever bundle, which would add another ~50-80 lines and put
  the file past ~1500.
- Absent those, no horizon forces this: the file is read by machines with large context windows, and
  1440 lines is not near any hard limit.

### Recommendation
**Recommendation:** Defer and monitor

The accretion is a symptom whose one confirmed harm — policy restatement drift — is better addressed
by fixing item 1 with a cross-reference rather than a copy, and by adopting that as the convention for
the next edit. A structural split is not justified by current evidence and carries real risk of
perturbing empirically tuned text; the honest position is that we do not yet know whether length is
costing recall. Monitor: re-check line count and restatement sites at the next lever-bundle adoption,
and treat a second drift instance as the trigger to act.

---

## Tech Debt Triage: coverage note — what this triage did not evaluate

**Location:** `runs/review-arms/baseline-2026-08-06/` (24M on disk), `.gitignore:45`
**Nature:** scope/coverage
**Cost of Deferral:** +0 — inert
**Legibility-target:** for-orchestrator-synthesis

Three things a reader might expect in this report and will not find, with why:

1. **Run-artifact directory growth.** `runs/review-arms/baseline-2026-08-06/` is 24M on disk, but the
   bulk is the candidate worktrees, which are gitignored —
   `.gitignore:45: runs/review-arms/baseline-2026-08-06/wt-*` matches `wt-candA`/`wt-candB`. The
   committed portion of this range is 1,073 lines of markdown across 11 files. There is no repository-
   weight debt here; I checked specifically because ~1000 lines of run artifacts in a 1133-line diff
   invites the assumption.
2. **Correctness of the empirical conclusions.** Whether #4 genuinely saves ~73% when it fires, and
   whether the 1-of-2 candidate split supports "rare", are fact-check and critic questions, not
   tech-debt ones. This triage takes the conclusions as given and evaluates only the durability of
   the artifacts recording them (item 3) and the consistency of the docs restating them (items 1, 2).
3. **`docs/decisions/log.md` row ordering.** Row 34 is filed above row 33, which is out of numeric
   order. This predates the range — 45fa1df modified row 34's text in place without moving it — so it
   is out of scope per the partial-scope rule. Flagging it only so a later reader does not mistake it
   for something this range introduced.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 1 | Three stale self-read instructions contradict conditional inlining (`SKILL.md:340-344`, `:634`, `:1406`) | Medium | +1 mis-dispatched stage per run | Med × Med | ~15 min, localized | Next `--loop-pass` run or #3 re-measurement | **Fix now** |
| 2 | 032 `:120-126` describes the pre-inlining loop as current | Low | +0 — inert | — | ~10 min, localized | None imminent | **Fix opportunistically** |
| 3 | Per-agent tokens only in prose; no ledger (`hunt-verify/results.md`) | Medium | +1 unreproducible figure per run | Med × High | 20 min retro / ~½ day preventive | Next measurement run | **Fix opportunistically** |
| 4 | Defect records frozen in run artifacts (hunt doc `:58-61`, candB `:8-9`, `:129`) | Low | +0 — inert | Low × Med | ~10 min, localized | Only if quoted forward | **Fix opportunistically** |
| 5 | `SKILL.md` accretion 857→1440 (+68%/17d), no prose guard | Medium | +~35 lines per lever adoption | Med × Med | Hours (convention) / days (split) | 2nd drift instance; next lever bundle | **Defer and monitor** |
| 6 | Coverage note — what was not evaluated | — | +0 — inert | — | — | — | *(informational)* |

### Recommended Order

1. **Item 1 now, as a cross-reference not a copy.** It is the only item with a live failure mode: the
   commit's stated purpose was to make #3 real, and the operative dispatch step still says otherwise.
   Fixing it by pointing at `:99` rather than restating the policy simultaneously pays down item 5's
   root cause, which is why the *manner* of the fix matters as much as the fix.
2. **Items 2 and 3's one-liner, in the same edit session.** The 032 sentence and the
   `SKILL.md:276` "Measured" → "Projected" correction both need exactly the context item 1 loads.
   Marginal cost near zero; standalone cost is a whole context load each.
3. **Item 4's hunt-doc line, as an appended dated note, whenever that file is next opened.** Not
   worth opening the file for. The candB header and line-ref are optional and can be left.
4. **Item 3's ledger convention at the next measurement run**, not before — that is when it is cheap
   and when it produces a primary record instead of a retrospective transcription.
5. **Item 5 monitored, not acted on.** Re-check at the next lever-bundle adoption; treat a second
   item-1-style drift as the trigger.

Items 1–4 together are well under an hour and none is a rewrite. The sequencing above deliberately
avoids the trap of "fix all the documentation drift" as a batch: item 1 is urgent because it is an
*instruction*, items 2 and 4 are records, and the difference is what sets their priority.

## Goal-Alignment Note
- Answered: yes — all four candidate items triaged plus one found during reading (032's stale #3 verdict) and one coverage note
- Out of scope: correctness of the #3/#4 empirical conclusions (fact-check/critic territory, not debt); `docs/decisions/log.md` row-34-above-row-33 ordering (predates the range); the gitignored candidate worktrees
- Escalate: item 1 is the only **Fix now** and is a live correctness risk for the next production run — the operative Stage-2 dispatch step (`SKILL.md:634`) and the summary bullet (`:1406`) still instruct the opposite of the policy this commit shipped, so #3 may not take effect and a #3 re-measurement would silently measure the wrong structure. Recommend it be fixed before the next `--loop-pass`, and fixed by cross-reference rather than by restating the policy a fourth and fifth time.
