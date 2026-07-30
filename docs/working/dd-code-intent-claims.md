# DD: how should the review pipeline treat intent claims embedded in code?

**Date:** 2026-07-30 · **Status:** diverge/diagnose/match/decide complete (Path C). **The recommendation reversed at §4.2c** — superseded reasoning retained deliberately; round claim in §8. Nothing implemented.
**Calling context:** standalone (follows `docs/thoughts/code-review-evaluation-state.md` §5.4 trap 4, which names this as the dominant failure class and defers it here)

## Problem statement

A docstring that says a behaviour is deliberate is currently the strongest merge-relevant
signal in the pipeline, and nothing in the pipeline can contradict it. The same eleven
words — *"that's a deliberate small mercy and keeps the rule ... simple and total"* — have
now beaten two different agents in two separate measurement arms: an adjudicator (Result 7,
F18) and a reviewer (Result 15). The human's very next commit in that repo (`31fd3c4`)
fixes exactly the behaviour the docstring defends, as a blocking finding.

The symmetric failure is equally real. `skills/code-review/SKILL.md` Step 2 pastes
`<pr-intent>` into every critic prompt *precisely so* critics can scope findings to stated
intent, and Result 7's dominant false-positive class is also true-mechanism /
disputed-intent — 4 of 5 adjudicated invalids were "documented as intended," and three of
those four adjudications were correct. So the naive rule ("ignore intent claims") converts
a measured false-negative class into a measured false-positive class of comparable size.

The published evidence for the false-negative side is n=2 (Results 15 and 14a). §0 below
raises it: a sweep of the eleven archived run trees finds ~35–40 distinct intent-load-bearing
findings, splitting roughly **70% defer-was-right / 25% defer-was-wrong**. That base rate,
not the two headline anecdotes, is what the candidates are scored against.

The decision is therefore not *whether* to defer but *what an intent claim is evidence
of*, and it has 3+ viable designs on a real tradeoff axis. Hence DD rather than a patch.

## Prior pruning grep

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "intent|comment|docstring|review|fact-check|critic|severity"`

Two matches, both carried forward:

- **[017-polyglot-test-hermeticity, candidate 9] "code-review sub-critic as a gate"** —
  pruned there as *not a gate*, adopted as a complement: "an LLM critic is a detector, not
  an enforcement primitive." **Carried forward** as constraint H5 below. It is the reason
  candidate 4 (a dedicated intent-coherence critic) is scored as a detector whose output
  still has to reach a channel, not as a fix on its own.
- **[014-secure-tool-guidance-layers, candidate 8] "skill"** — pruned with *"skills trigger
  on intent, not tool failure."* **Carried forward** with a note that it cuts the other way
  here: the thing being detected *is* an intent claim, and the trigger is a diff the skill
  is already invoked on, so the prior objection (unreliable triggering) does not transfer.
  It is not re-proposed as a standalone skill regardless — see candidate 4's cost row.

No prior decision record addresses documentation-deference or intent adjudication directly;
`001-code-fact-checking.md` and `002-critic-style-code-review.md` predate the measurement
program and contain no `Pruned candidates` section.

## 0. What the artifact actually looks like

Everything below turns on the shape of the real claim, so it is quoted in full rather than
paraphrased. Pre-fix ND2, `packages/sim-core/src/sim.ts:623-627`:

> The post-state moods are set on EXIT (keyed on `from`) so they color the WANDER the
> creature returns to — exactly the "Post-ANGRY return / Post-SINGING return" rows of
> initial_concept.md's emotional flee table. **A FLEE-interrupted song still earns the
> CONTENT aftertaste; that's a deliberate small mercy and keeps the rule "leaving SINGING
> -> CONTENT" simple and total.**

And the design intent it contradicts, forty lines away in a sibling file,
`packages/sim-core/src/behavior.ts:152-154`:

> SINGING is the MOST skittish state (1.4): an absorbed-in-music creature spooks from
> farther — the design's "humming microstate is more skittish" inversion, **which makes
> interrupting a song (FLEE) the failure mode players learn to avoid.**

The mechanism: `onEnterState` sets `mood = "CONTENT"` on `from === "SINGING"` with no
guard on `to`, and `MOOD_MULTIPLIER.CONTENT = 0.5` *halves* the flee threshold for 6 s. So
the stated punished action is mechanically the largest approachability bonus in the table
apart from WARY. The fix the human shipped is a two-token guard, `to !== "FLEE"`.

**The load-bearing observation.** That docstring is not one claim. It is three, welded
together:

| Part | Text | Truth-apt? | Verdict on the real artifact |
|---|---|---|---|
| **D — descriptive** | "A FLEE-interrupted song still earns the CONTENT aftertaste" | Yes. | **True.** `nd2-fable-r2`'s fact-check rated exactly this **Verified / High** and closed it. |
| **N — normative** | "deliberate" | No. A statement of preference. | Defer. The author did choose this. |
| **V — valence** | "a small **mercy**" | Yes, but reads as normative. Asserts the effect is a *withheld penalty*. | **False.** It is an active 0.5× bonus, larger in magnitude than any other mood effect but WARY. |
| **C — coherence** | "keeps the rule ... simple and total" | Yes, and checkable against other stated intent. | Locally true, and **contradicts** `behavior.ts:152-154`'s stated design goal. |

The D row is the trap, and it is why "just fact-check the comment harder" is not the
answer. The comment is an *accurate* description of the code. `nd2-fable-r2` verified it at
high confidence and that verification is what closed the finding. What is wrong is V and C —
the valence word and the contradiction with a stated intent forty lines away in a sibling
file — and neither is reachable by asking "does the comment match the code?"

The corpus states the discriminator plainly. Across all eleven run trees, **every
defer-was-wrong case collapsed two distinct questions into one — *is the claim accurate?*
and *is the documented behaviour correct?*** The two cells that got ND2 right kept them
apart and said so in the same sentence: `nd3-fable-r1/architecture-review.md:56` —

> "So this is a *known, intentional* simplification, not an oversight. **But** 'simple and
> total' optimizes for rule tidiness over behavioral correctness: the rule's totality is
> what produces the inverted post-condition."

That is the whole design target: not *doubt the claim more*, but **make the second question
a separate, owned, answerable one.**

For calibration on the other side, the *fixed* version of the same docstring (ND3
`sim.ts:625-628`) reads: "a song the player SPOOKED into FLEE must NOT make the creature
more approachable — interrupting a song is the failure players should learn to avoid, so it
earns no aftertaste reward." Same normative force; coherent D, V and C. Any mechanism that
fires on this one is producing the false-positive class, and H4 below makes that hard.

### The base rate — this band is bigger than n=2, and deference is usually right

The state doc's evidence for this failure is two data points. The archived corpus supports a
much better count. Across the eleven run trees (9 r1 cells + 2 ND2 r2 cells): **23 of 255
rubric rows and 26 of 300 critic finding-blocks touch an intent claim (~9% each)**; deduped
across cells reviewing the same diff, roughly **35–40 distinct findings where an in-code
intent claim is load-bearing to the verdict.** The split:

| Outcome | Count | Where |
|---|---|---|
| **Defer-was-right** | ~26 (~70%) | ND3 persistence (`state`/`morph` intentionally not stored), the `Carry intentionally` tech-debt family (≥14 rows), ND2 C3 rarity re-tiering |
| **Defer-was-wrong** | ~9 (~25%) | ND2 "deliberate small mercy" — 4 clear misses + 1 tier-scoped; MD1 `style-src 'unsafe-inline'` — 3 downgrades to Informational + **1 promotion to ✅ Confirmed Good on the comment alone** |
| **Ambiguous / scoped-not-dismissed** | ~4 | e.g. `nd3-opus-r1/architecture-review.md:95` — deference acknowledged, then explicitly overridden |

**Read that 70/25 before designing anything.** Any rule that makes deference harder is
operating on a population where deference is right about three times out of four. That is
the quantitative form of the tension in the problem statement, and it is what prunes
candidate 9.

Three more corpus facts that change the design:

1. **`<pr-intent>` appears in zero artifacts.** A `grep -rn 'pr-intent'` across all eleven
   run trees returns nothing — no critic report, no rubric, no fact-check report ever
   echoes, cites, or adjudicates the intent the orchestrator injected. The channel the skill
   built *specifically* so critics could scope to stated intent leaves no trace in the
   output, so we cannot tell whether a deference was grounded in the author's stated purpose
   or in a comment the branch happens to contain. Both look identical on the page.
2. **Owner, not just channel, caps the severity.** ND2's one correct r2 reconstruction
   landed 🟢 partly by the escalation monopoly (state doc §1.2) and partly by a *second*
   structural rule: it was filed by **tech-debt-triage**, and `SKILL.md`, "Contextual critics are advisory" sends
   contextual-critic findings to 🟢 "regardless of their internal severity." The two ND3
   cells that got the same defect right filed it under **architecture-review**, which is the
   one auto-selected critic carrying its own 🔴-capable mapping. Same defect, same
   mechanism, three bands apart — decided by which critic happened to notice.
3. **Critics prescribe intent claims as a remedy.** Four separate reports recommend *adding*
   a comment saying a behaviour is deliberate as the fix for a finding (`nd2-opus-r1`
   security:98 and api:192, `nd2-fable-r1` api:121, `md1-sonnet-r1` security:72). The
   pipeline treats a docstring as discharge. Whatever rule lands has to survive the fact
   that the system is actively manufacturing more of the artifact that defeats it.

And the strongest statement of the opposing case, from the corpus itself
(`nd2-opus-r1/tech-debt-triage-review.md:216`):

> "This codebase is **deliberately comment-dense, and the comments are not decoration — they
> *are* the design spec.** There is no separate spec document for the FSM's priority
> ordering, the tier ladder, or the tuning rationale…"

That is true of both review corpora, and it is the counterargument the recommendation has to
answer rather than route around.

## 1. Diverge — 14 candidates

| # | Candidate | One line |
|---|---|---|
| 0 | **Status quo** | `<pr-intent>` pasted verbatim into every critic; in-code claims unregulated; `code-fact-check` non-goal #2 explicitly skips design rationale. |
| 1 | Prose nudge | One sentence in the critic preamble: "an in-code intent claim is evidence to be weighed, never dispositive." |
| 2 | **Intent-claim ledger** | Stage 1 extracts every intent claim in the diff verbatim into a `## Intent claims` section — no verdicts — and every critic receives it as a checklist. |
| 3 | **Claim splitting** | Narrow `code-fact-check`'s "not an intent reviewer" non-goal so the *behavioural / magnitude / valence* assertions inside a rationale comment become checkable claims under the existing verdict vocabulary. |
| 4 | Intent-coherence critic | A new core critic that maps stated design intents across the repo and flags intent-vs-intent contradictions, with its own severity mapping. |
| 5 | **Provenance tiering** | Only `<pr-intent>` (external, dated, author-attributable) may scope a finding; in-code claims annotate but never downgrade. |
| 6 | Intent-blind twin pass | Run the core critics twice — once with all intent stripped from the prompt and the diff — and report the deference delta. |
| 7 | **Rubric `Intent` column** | Every finding that touched an intent claim records `deferred / rejected / n-a` plus the claim verbatim. Auditability only, no behaviour change. |
| 8 | Test-backing rule | An intent claim may downgrade a finding only if a test asserts the claimed behaviour; unbacked claims annotate only. |
| 9 | Ban deference | Critics MUST NOT cite any comment or docstring as a reason to downgrade. |
| 10 | Human queue | Disputed-intent findings are never resolved in-run; they are filed to `docs/reviews/override-log.md` as questions. |
| 11 | Repo intent index | A maintained machine-readable `docs/design-intent.md` registry that critics diff the code against. |
| 12 | Reframe: fix the channel | Do nothing about intent; the observed damage is the escalation monopoly, not the deference. |
| 13 | Commit-message downgrade | Treat commit-derived `<pr-intent>` as lower authority than a PR body, since the branch author wrote it about the change under review. |

Deliberately included: a do-nothing (0), two that feel wrong (9, 12), two unconventional
(6, 10), one ideal-if-effort-were-free (11).

**Generation health check.** First pass produced 1, 3, 5, 9 — four different edits to
critic prompt text, i.e. dimensional anchoring on *agent text* with zero variety on agent
set, dispatch order, or communication topology. Added 4 (agent set), 6 (dispatch order), 2
and 7 (communication topology / output contract), 8 and 11 (success criteria and data
format). Clustering check: 3, 4, 8, 11 all assume *checking* the claim is the answer, so 10
and 12 were added to violate that assumption.

## 2. Diagnose — constraints

**Hard (H):**

- **H1 The mechanism resolves with no human present.** Gate 1h in
  `scripts/self-improvement.sh:1297` runs headless, mid-loop, per task per round.
  *success:* `run-review.sh nd2 opus` under `--no-gate` completes with `rc=0` and emits the
  nonced `CODE_REVIEW_RED[...]` sentinel, with no `AskUserQuestion` and no stdin read, on
  the same worktree recipe the nine existing cells used.
- **H2 Nothing may key on a tier boundary.** J_self on 🔴 rows is 0.14–0.25 within one
  tier on one diff (Result 14a); band-agnostic issue identity is ~0.5 (Results 1, 17).
  *success:* the mechanism's per-claim output text is byte-identical whether the associated
  finding lands 🔴, 🟡, or 🟢 — verifiable by grepping the archived rubrics for the new
  field and confirming its values are drawn from a fixed vocabulary that contains no tier
  glyph.
- **H3 The escalation rule is not silently redesigned.** The corroboration list
  (`skills/code-review/SKILL.md`, `### Escalation Rule` — line numbers deliberately omitted;
  concurrent work on this branch is moving them) is a separate open decision (state doc §1.2).
  *success:* the diff implementing the chosen candidate contains no edit to the lines
  between the `### Escalation Rule` heading and the following `### Rubric Status Line`
  heading.
- **H4 The true-positive deference path survives.** Intent claims are *usually* right; ND2
  C3 (a deliberate re-tiering) was correctly resolved as intentional-and-required, and 3 of
  Result 7's 4 "documented as intended" adjudications were correct.
  *success:* replayed against ND3's fixed `sim.ts:625-628` docstring and md1's
  `proxy.ts:14` ("documented as a deliberate carve-out, not an oversight"), the mechanism
  emits no finding above 🟢 and no fact-check `Incorrect` verdict.
- **H5 In-code claims are branch-authored, i.e. untrusted input.** The docstring is inside
  the artifact under review; the same reasoning that moved the review skill to a root-owned
  payload (decision 022) applies to text that can suppress a finding.
  *success:* the mechanism's text contains no rule under which an in-code comment alone
  lowers a finding's tier or removes it; every downgrade path requires evidence outside the
  comment (a test, a fact-check verdict, `<pr-intent>`, or a human).
- **H6 An LLM critic is a detector, not an enforcement primitive** *(carried from 017,
  candidate 9)*. *success:* the chosen mechanism names, explicitly, which existing channel
  carries its output to a rubric row — it does not assume that detecting the contradiction
  is the same as banding it.
- **H7 Cost multiplies per task × per round.** *success:* added cost ≤ one extra sub-agent
  dispatch per review, measured as the delta in `claude -p` invocations in Gate 1h.

**Soft (S):**

- **S1** Prefer mechanisms testable against the *existing* corpus — the nine r1 cells, the
  two r2 ND2 cells, and the three pre-fix worktrees — at zero new experiment cost. The
  corpus is the bottleneck for every open question in the state doc.
- **S2** Prefer mechanism over prose. The override-log failure is this repo's standing
  evidence that unenforced instructions do not execute.
- **S3** Prefer changes localized to skill files over new gate code in
  `scripts/self-improvement.sh`.
- **S4** Prefer surfacing an unresolved intent dispute to the human asynchronously over
  resolving it agentically — the override log is the only clean instrument for this band
  (Result 7's own conclusion).
- **S5** Prefer mechanisms that also produce measurement data; the intent-claim band is
  currently unmeasured except by hand-reading rubrics.

## 3. Match — compatibility matrix

| # | Candidate | H1 headless | H2 tier-free | H3 no escalation edit | H4 TP path | H5 untrusted | H6 named channel | H7 cost | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| 0 | Status quo | ✓ | ✓ | ✓ | ✓ | ⚠ | ✗ | ✓ | **baseline — is the thing being fixed** |
| 1 | Prose nudge | ✓ | ✓ | ✓ | ~ | ~ | ✗ | ✓ | ⚠ S2 |
| 2 | Intent-claim ledger | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ✓ | **survives** |
| 3 | Claim splitting | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | **survives** |
| 4 | Intent-coherence critic | ✓ | ✓ | ✓ | ~ | ✓ | ~ | ~ | **survives** |
| 5 | Provenance tiering | ✓ | ✓ | ✓ | ~ | ✓ | ✗ | ✓ | **survives** |
| 6 | Intent-blind twin pass | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ⚠ H7 |
| 7 | Rubric `Intent` column | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | **survives (instrumentation)** |
| 8 | Test-backing rule | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ | ✓ | pruned |
| 9 | Ban deference | ✓ | ✓ | ✓ | ⚠ | ✓ | ✗ | ✓ | pruned |
| 10 | Human queue | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | pruned as a gate; survives as artifact |
| 11 | Repo intent index | ✓ | ✓ | ✓ | ✓ | ⚠ | ~ | ✗ | pruned (deferred) |
| 12 | Reframe: fix the channel | ✓ | ✓ | ⚠ | ✓ | ⚠ | ✓ | ✓ | pruned (out of scope, honestly) |
| 13 | Commit-message downgrade | ✓ | ✓ | ✓ | ~ | ~ | ✗ | ✓ | absorbed into 5 |

Key: ✓ addresses · ~ partial/uncertain · ✗ doesn't address · ⚠ actively worse

**Prune reasoning:**

- **[1] Prose nudge** — ⚠ on S2, and it is *already the status quo in spirit*: the state doc
  already says "treat intent claims as evidence to be weighed, never as dispositive," and
  Result 14a shows a reviewer that had internalized exactly that still filed 🟢. Adding the
  same sentence one layer lower is the intervention the evidence has already falsified.
- **[6] Intent-blind twin pass** — the cleanest *measurement* instrument in the set and the
  only one that quantifies deference directly, but it doubles the core-critic dispatch on
  the most expensive gate in the loop (H7 ✗). Retained as **the experiment to run**, not the
  mechanism to ship: one offline twin pass on ND2 would put a number on a band currently
  known only from n=2.
- **[8] Test-backing rule** — fails H4 in the direction that matters. Opus r2's own words
  were *"invisible to tests, which assert only the transition, never the tick after"* — the
  defect and the intent claim are *both* untested, so the rule discriminates nothing here,
  while in a repo of doc-drift findings (state doc: most findings are not testable) it would
  discard the deference path wholesale. Right rule for a code-heavy repo, wrong one here.
- **[9] Ban deference** — ⚠ on H4 by construction, and §0's base rate is what kills it: it
  would disturb ~26 correct deferences to recover ~9 wrong ones. The naive option, kept in
  the list because it is exactly what "the docstring defeated us again" tempts you into, and
  because until §0 was counted it looked defensible.
- **[10] Human queue** — fails H1. A queue with no human at decision time is a gate that
  never gates, the same objection `dd-review-gate-signal.md` raised against its candidate 9.
  Survives as an *artifact* obligation: the override log is already the designated instrument
  for this band (S4), and any chosen candidate should write to it.
- **[11] Repo intent index** — the ideal-if-effort-were-free option, and genuinely
  attractive: it is the only candidate that makes intent-vs-intent contradiction a
  *mechanical* check rather than an LLM judgment. Fails H7 (a maintained registry per
  reviewed repo) and ⚠ H5 (the registry lives in the branch). Deferred; revive if a repo
  ever ships a design-intent doc the reviewer can trust.
- **[12] Reframe** — deserves the hearing it gets here, because it is *partly right*: Result
  14a proves comprehension was not the binding constraint on the sharpest observed case, and
  the escalation monopoly was. But it is pruned on scope (H3 makes it a different decision)
  and on evidence: Result 15 r1 and Result 7's F18 are two cases where deference happened
  *before* any escalation question arose. Fixing only the channel leaves both of those.
- **[13] Commit-message downgrade** — a real distinction (a commit-derived `<pr-intent>` is
  the branch author writing about the change under review, which is precisely H5's concern)
  but it is one clause of candidate 5, not a rival. Absorbed.

**Survivors: [2] [3] [4] [5] [7].**

Fix sketches for surviving weaknesses:

- **[3]** has a `~` on H4 — narrowing the fact-check carve-out risks fact-checking *every*
  rationale comment into noise, in two codebases that are comment-dense by policy. Fix: the
  narrowing is scoped to rationale comments containing a **behavioural, magnitude, or
  valence assertion** ("mercy", "halves", "never", "costs nothing", "keeps X total"); pure
  preference statements ("we prefer this shape") stay out of scope, as does the normative
  half of a split claim. The ND3 and md1 calibration docstrings in [3]'s hypothesis are the
  detector for whether the scoping held.
- **[4]** has a `~` on H6 — a new critic detects but cannot band. Fix: give it
  architecture-review's treatment, an explicit declared severity mapping in Step 4 of the
  orchestrator, which is the existing precedent for a non-core critic that may produce 🔴.
- **[5]** has a `~` on H4 — forbidding in-code claims from downgrading removes the true
  deference path for repos where the docstring *is* the only record of intent. Fix: in-code
  claims may still scope a finding's *description*, and may downgrade when corroborated by
  `<pr-intent>` or by a second stated intent that agrees.

## 4. Scorecard and decision

Per-criterion scoring was calibrated by `matrix-analysis` sub-agents — one per axis
(effort, risk, coverage), each framed higher-is-better, each passed the three axes as
*given* criteria (so no Stage-1 user prompt fires), and each seeing all five survivors on
its one dimension only. Their per-axis rankings are in §4.1; the stress-test pass in §4.2
is DD-owned and did revise one glyph.

### 4.1 Tradeoff matrix

Strong → ● · Adequate → ◐ · Weak → ○.

| # | Approach | Effort | Risk | Coverage | Key downside |
|---|---|---|---|---|---|
| 3 | **Claim splitting** | ● ~half a day | ● low | ● 5 hard, both directions | Routes through the Incorrect-vs-Mostly-Accurate boundary, the least stable verdict in the system |
| 7 | Rubric `Intent` column | ◐ ~half a day (golden lockstep) | ● low | ○ measures the failure, does not cover it | Can be filled `n-a` truthfully by a reviewer that is about to under-band |
| 2 | Intent-claim ledger | ◐ ~1 day (2 skills, 2 suites) | ◐ medium | ◐ substrate, changes no outcome alone | Gives branch-authored text a second privileged appearance in every critic prompt |
| 5 | Provenance tiering | ● ~2 hours | ◐ medium | ○ prohibition without falsification | Its corroboration escape hatch is inoperative in the headless path |
| 4 | Intent-coherence critic | ○ ~2–3 days | ○ high | ◐ hits the coherence half both others miss | Mints new 🔴 authority from an unvalidated LLM judgment with no eval corpus |

Per-axis rankings from the sub-agents, unedited:

- **effort** — `[3] > [5] > [7] > [2] > [4]`. Differentiator: *how far the change propagates
  past its own file.* [3] and [5] are single-file prose edits to text the pipeline already
  reads. [7] and [2] cross the rubric-format boundary, which
  `test/skills/code-review-format-contract.bats` deliberately makes a lockstep two-file
  edit. [4] is the only item adding an artifact-producing agent, which multiplies every cost
  class at once — new skill (~500 lines, per the architecture-review precedent), new format
  suite, ~7 registration sites in the orchestrator, per-review runtime, and a mandatory
  corpus re-run to calibrate.
- **risk** — `[3] > [7] > [2] > [5] > [4]`. Differentiator: *whether the mechanism checks the
  untrusted claim against code using vocabulary that already has a test corpus, or rules on
  it via unenforced prompt text and newly minted 🔴 authority.* The former fails quiet; the
  latter fails loud on exactly the coherent-docstring case that must not fire.
- **coverage** — `[3] ≫ [4] > [2] > [5] > [7]`. Differentiator: *whether the item converts
  the false half of the claim into an artifact the existing pipeline already knows how to
  route.* Only [3] produces a token — a fact-check `Incorrect` — that is simultaneously a 🔴
  mapping (the `Fact-Check` column of `### Unified Severity Mapping`) and one of the three corroborations the escalation rule already
  lists ("a fact-check verdict of **Incorrect**"). That is why it reaches the second failure direction without
  editing the escalation rule (H3) or spending the sub-agent budget (H7).

Two sub-agent escalations, recorded rather than absorbed:

- The risk agent disputes the step-3 matrix's `✓` for candidate **[2] on H5**: the ledger
  pastes branch-authored claims verbatim into every critic prompt in a section structurally
  parallel to `<pr-intent>`, which grants untrusted text a second privileged appearance it
  does not have today. Accepted — [2]'s H5 cell should read `~`, not `✓`. It does not change
  the ordering.
- The risk agent finds candidate **[5]'s fix sketch inoperative in the path that matters**:
  the sketch lets an in-code claim downgrade when corroborated by `<pr-intent>`, but in the
  headless Gate 1h path `<pr-intent>` is *itself* derived from the branch's commit messages
  (`SKILL.md`, Step 2's commit-log fallback), so the corroboration is the same author corroborating himself.
  Accepted; this is what moves [5]'s coverage to ○.

**Falsifiable hypotheses.**

- **[3]** — If we narrow the non-goal, a replay of `code-fact-check` over the pre-fix ND2
  worktree returns a **non-Verified** verdict on the valence half of `sim.ts:623-627` in ≥2
  of 3 replicates, while returning `Verified` on ND3's fixed `sim.ts:625-628` and on md1's
  `proxy.ts:14` carve-out in 3 of 3. Window: one replay session, no new experiment
  infrastructure. Counter-evidence = `Verified` on ND2 in ≥2 of 3 (the rule does not fire on
  the case it was designed for), **or** a single `Incorrect` on either calibration docstring
  (the rule fires on the 70% where deference is right).
- **[7]** — If we add the column, ≥5 non-`n-a` cells appear across the next 10 archived
  Gate-1h rubrics within two SI rounds. Counter-evidence = ≥8 of 10 rubrics carry the column
  entirely `n-a` while that run's own critic reports quote intent claims — i.e. the column
  is inert, which is the Result 14a failure reproduced in a new field.
- **[2]** — ≥80% of hand-identified intent claims in a diff appear in the ledger and are
  dispositioned in the rubric. Counter-evidence = ledger entries the rubric silently drops,
  or a rise in 🟢 rows whose sole content is "ledger entry N: not relevant."
- **[5]** — critic reports begin citing `<pr-intent>` explicitly; the count rises from its
  current **0 occurrences across 11 run trees**. Counter-evidence = still zero after 10 runs.
- **[4]** — on a replay over the three pre-fix worktrees it flags the ND2 intent-vs-intent
  contradiction and flags nothing on ND3's fixed docstring or md1's `proxy.ts:14`.
  Counter-evidence = any fire on the latter two, or >1 finding per diff on the ND3 tree,
  whose comment density is the same and whose intent claims are coherent.

### 4.2 Stress-test pass

Four moves, selected by trigger.

**Boring alternative** *(applied to [4], which was the intuitive pick before scoring — the
problem is intent-vs-intent contradiction, so build the contradiction detector)*. The boring
version: **don't build a critic; the corpus shows one already does this job.** Both cells
that got ND2 right filed it under `architecture-review`, the one auto-selected critic with
its own 🔴-capable severity mapping — `nd3-fable-r1/architecture-review.md:102`, *"Yes — this
is a genuine state-machine design defect, not a harmless simplification… Severity: Coupling
(🟡 Must Address)."* Adding an intent-coherence *move* to architecture-review's existing move
list costs no dispatch and inherits a validated mapping. **Matrix change: [4]'s effort glyph
would move ○ → ◐ in this boring form**, but its risk stays ○ (still an unvalidated judgment
minting 🔴s) and it acquires a new hole — `architecture-review` is *conditionally*
auto-selected, so an intent contradiction inside a pure-implementation diff would have no
owner at all. Recorded as the fallback if [3]'s hypothesis is refuted; not promoted.

**Invert the thesis** *(applied to [3], the front-runner)*. Sincerely: the fact-check verdict
channel is the **worst** place to put this. It is the least stable judgment in the system
(§1.1 of the state doc), the same comment defect flipped Incorrect↔Mostly-Accurate across
runs, and [3] deliberately loads more traffic onto it. What survives the inversion is that
[3] does not *widen* the 🔴 monopoly — it feeds the existing one — and that the instability
is pre-existing and already has a queued fix (k≥3 fact-check runs, combine by most-severe
verdict). What does *not* survive is any claim that [3] is independently safe: **[3]'s value
is conditional on §1.1 landing.** Matrix change: [3]'s risk glyph is recorded ● *given* k≥3,
and the dependency is written into the recommendation rather than left implicit.

**Revealed preferences** *(applied across all five)*. What do the critics in this corpus
actually do, as against what the skill tells them? Two answers, both uncomfortable. (i) They
never once cite `<pr-intent>` — 0 occurrences in 11 trees — so the "scope findings to stated
intent" channel is, revealed-preference-wise, dead, and candidate [5] proposes to load more
weight onto it. (ii) They repeatedly *prescribe* intent comments as remedies ("add an
explicit comment stating that it is deliberately…", four separate reports). The system's
revealed preference is that a docstring discharges an obligation. **Matrix change: [5]'s
coverage confirmed ○**, and a new obligation is attached to the recommendation — whichever
candidate lands must also stop critics from recommending a comment as a fix for a
behavioural finding, or it is fighting its own output.

**Failure-driven** *(applied to [3] and [7])*. New failure categories each enables. For [3]:
*valence inflation* — a fact-checker told to verdict magnitude words may start verdicting
every adjective in a comment-dense codebase, and both review corpora are comment-dense by
policy. The scoping clause (behavioural/magnitude assertions only; pure preference out of
scope) is the mitigation, and the ND3/md1 calibration cases in [3]'s hypothesis are what
detect it. For [7]: *audit-washing* — a column recording `deferred` makes an under-banded
finding look like a considered decision, which is worse than silence for a human skimming
the rubric. Mitigation: the column records the claim **verbatim with its location**, so the
reader can check the deference rather than trust the label. Both mitigations are cheap and
both are folded into the recommendation.

### 4.2b What-if pass on the top two — [3] claim splitting, [7] rubric `Intent` column

`what-if-analysis`'s seven moves, run on the two candidates that are being adopted. Findings
are labelled **(A)** for [3] and **(B)** for [7]. This is the pass that changed the
recommendation's shape most — three findings below are folded back into §4.4 as obligations.

**Assumptions examined** (ranked by load)

| # | Assumption | Source | If wrong |
|---|---|---|---|
| A1 | The false half of an intent claim is reliably *lexical* — a word like "mercy" or "costs nothing" that a fact-checker can isolate and check. | implicit in [3] | **full retreat.** [3] has no hook at all. |
| A2 | A fact-checker instructed to verdict valence words will not verdict *every* adjective in a comment-dense codebase. | implicit in [3] | redesign — the scoping clause has to become a positive list, not a negative one. |
| A3 | `Incorrect` on the valence half will be read by downstream critics as "the design is wrong," not "the wording is wrong." | implicit in [3] | redesign. The verdict fires but nothing acts on it. **This is the most under-examined of the three.** |
| B1 | A reviewer that under-bands a finding will still *record* the deference honestly. | implicit in [7] | tweak — the column becomes inert but harmless. |
| B2 | The rubric's readers (a human at pr-prep, and Gate 1h's parser) will actually consult the column. | implicit in [7] | tweak — it stays a measurement artifact, which is most of its stated value anyway. |

A3 deserves the emphasis. [3]'s whole coverage argument is that `Incorrect` is a token the
pipeline already routes. But what the pipeline routes it *to* is a documentation-accuracy
finding: the unified severity mapping's `Fact-Check` column is about comments matching code.
A critic reading "the word 'mercy' is Incorrect" may correctly file **"fix the comment"** —
and ND2's fix is not a comment fix, it is `to !== "FLEE"`. **`[UNEXAMINED ASSUMPTION]`**

**Consequence chains**

```
(A) → First-order: the valence half of a rationale comment gets an `Incorrect` verdict.
       → Second-order: the finding lands 🔴 and the reviewer proposes a remedy.
         → Third-order (good): the remedy is "the comment is wrong because the behaviour is
           wrong" → the guard gets added → ND2's actual fix.
         → Third-order (bad): the remedy is "reword the comment" → the docstring is
           corrected to accurately describe the defect → the defect is now *better
           documented and still shipped*, and the next reviewer defers to a claim that is
           now fully Verified. The pipeline has made the trap stronger.
       → Second-order: authors (human and agent) learn that evaluative words in comments
         draw 🔴s.
         → Third-order: comments get blander — "this is deliberate" with no explanation —
           which is exactly the D+N-only shape [3] cannot check at all. The rule selects
           for the comments that defeat it.
```

```
(B) → First-order: deference decisions become visible in an archived artifact.
       → Second-order: the 70/25 base rate becomes countable per-round instead of by a
         one-off hand sweep.
         → Third-order (good): the [3] hypothesis and the §1.2 escalation decision both
           get a real denominator; open question #2 in the state doc gets cheaper.
         → Third-order (bad): "audit-washing" — a `deferred` cell reads as a considered
           judgment to a skimming human, so a wrong deference is now *harder* to spot than
           when it was invisible, because it looks adjudicated.
```

The bad (A) third-order chain is the single most important finding in this pass.
**`[SECOND-ORDER EFFECT]`**

**Coupling analysis**

- **(A) → the fix-recommendation channel** *(invisible; convention)*. Four corpus reports
  recommend *adding* an intent comment as a remedy. [3] couples to that convention in the
  worst way: it creates pressure to edit comments, in a system that already treats comment
  edits as discharge. Neither the skill files nor the rubric name this coupling.
  **`[HIDDEN COUPLING]`**
- **(A) → §1.1 (k≥3 fact-check)** *(visible; stated in §4.2)*. Already mapped.
- **(A) → the reviewed repo's comment policy** *(invisible; convention)*. Both corpora are
  comment-dense *by policy* — `nd2-opus-r1/tech-debt-triage-review.md:216`, "the comments…
  *are* the design spec." [3]'s claim volume therefore scales with a property of the
  reviewed repo that the pipeline does not control and cannot detect in advance.
  **`[HIDDEN COUPLING]`**
- **(B) → the concurrent §1.3 work** *(visible)*. Both add columns to the same rubric tables
  behind the same golden-fixture lock. Sequencing, not design, but a real merge coupling.
- **(B) → Gate 1h's `count_rubric_red`** *(visible; `scripts/self-improvement.sh:1404`)*. The
  gate parses rubric tables positionally-ish. A new column must not break the red-row count,
  and the state doc already records a live selection bug at that line. **`[HIDDEN COUPLING]`**

**Confidence inversions**

- *"The descriptive half being true is a trap we can route around."* Invert it: the
  descriptive half being true is the **normal case**, and the valence half is the exception.
  Concretely — strip "mercy" from ND2's docstring and every remaining assertion is
  `Verified`. [3] is then silent on the exact defect it was designed for. §4.5 states this
  as the strongest counterargument; the what-if pass upgrades it from "possible" to
  "one-word-away," and adds a concrete pre-implementation test (validation step 1).
- *"[7] is obviously safe because it changes no behaviour."* Invert it: a field that records
  a judgment **is** a behaviour change, because it makes the judgment feel owned. The
  audit-washing chain above is what that looks like.

**Adversarial scenarios** (each ~10–20% likely, not apocalyptic)

1. **Goodhart by the code-writing agent.** The same model that reviews also writes code in
   this loop. Once [3] is in the payload, an agent authoring a rationale comment optimizes
   away the checkable words — not maliciously, just by writing what passes. Within a few
   rounds the repo's comments are `D + N` only. [3] degrades to a no-op **and the codebase
   is worse documented than before.** Realistic worst case, and it is the reason the §4.4
   obligation about remedy-shaped advice must ship *with* [3], not after it.
2. **Valence inflation on a genuinely comment-dense diff.** A 400-line diff in `md1` carries
   ~12 rationale comments with evaluative language ("narrow residual channel", "costs
   nothing", "rare"). Under [3] the fact-check report grows a dozen new claims; a handful
   land `Mostly accurate`, which maps to 🟡. The gate's red count is unchanged but the
   rubric's amber tier doubles, and pr-prep's human triage cost rises on every PR. Nobody
   reverts it because nothing is *wrong* — it is just noisier.
3. **The unstable-verdict coin flip lands wrong on the one case that matters.** [3] fires on
   ND2, returns `Mostly accurate` rather than `Incorrect` on 2 of 3 replicates, and the
   finding lands 🟡 — better than the observed 🟢, still not merge-gating, and now with the
   appearance of having been handled. Mitigated only by §1.1.

**Reversibility map**

| Horizon | [3] claim splitting | [7] `Intent` column |
|---|---|---|
| 1 week | Trivial — revert one frontmatter line and a paragraph. | Trivial — revert 3 tables + golden + 1 test, one commit. |
| 1 month | Still cheap, but the fact-check eval fixture `tc-c4-skip-targets.js` and its `expected-verdicts.bash` entry have been re-scoped; reverting means re-inverting those expectations. | Cheap. Archived rubrics carry a column later rubrics lack — a corpus inconsistency, not a blocker. |
| 6 months | **Cliff.** If the Goodhart chain has run, the reviewed repos' comments have already been rewritten to survive the rule. Reverting [3] does not restore the deleted rationale. The artifact the pipeline reads has been permanently reshaped by a rule that is no longer in force. **`[REVERSIBILITY CLIFF]`** | Still cheap. Its worst outcome is a column of `n-a`. |

The cliff is asymmetric and it is the reason [7] should ship *first* or simultaneously: [7]
is the instrument that would detect the Goodhart drift ([3]-only would hide it), and it has
no cliff of its own.

**Cost of success**

Assume both work perfectly. What is worse about that world?

- **Complexity:** `code-fact-check`'s scope becomes a judgment call rather than a bright
  line. The current non-goal is crisp — "design rationale: skip." The replacement requires
  the fact-checker to parse a comment into parts and decide which parts are truth-apt. That
  is a harder instruction to hold, and every future edit to that skill has to preserve the
  distinction. **`[SUCCESS COST]`**
- **Opportunity:** adopting [3] makes the fact-check verdict channel the pipeline's answer
  for *design* defects as well as documentation defects. That is one more reason not to
  redesign the escalation rule later, i.e. it quietly raises the cost of the §1.2 decision
  that this DD deliberately left open. **`[SUCCESS COST]`**
- **Maintenance:** two rubric columns (`Evidence` from the concurrent §1.3 work, `Intent`
  from here) added in one branch, each with a golden-fixture lock and a bats assertion. The
  rubric is becoming wide enough that its own format is a maintained artifact.
- **Optionality:** none material. Both are reversible inside a month.

**Findings summary**

| Tag | Finding |
|---|---|
| `[UNEXAMINED ASSUMPTION]` | (A3) `Incorrect` on a valence claim routes to a *documentation* remedy; ND2's fix is a code guard. Nothing makes the reviewer prefer the code fix. |
| `[SECOND-ORDER EFFECT]` | (A) The "reword the comment" remedy produces an accurately-documented, still-shipped defect — a *stronger* trap than the one being fixed. |
| `[SECOND-ORDER EFFECT]` | (A) Selection pressure toward `D + N`-only comments, which [3] cannot check. |
| `[SECOND-ORDER EFFECT]` | (B) Audit-washing — a `deferred` cell makes a wrong deference look adjudicated. |
| `[HIDDEN COUPLING]` | (A) Couples to the corpus's existing "add a comment" remedy convention. |
| `[HIDDEN COUPLING]` | (A) Claim volume scales with the reviewed repo's comment density, which the pipeline neither controls nor detects. |
| `[HIDDEN COUPLING]` | (B) `count_rubric_red` at `scripts/self-improvement.sh:1404` parses the rubric; a column change must not disturb it, and that line already carries a known selection bug. |
| `[REVERSIBILITY CLIFF]` | (A) At ~6 months, Goodhart drift has reshaped the reviewed comments; reverting the rule does not restore them. |
| `[SUCCESS COST]` | (A) `code-fact-check`'s scope stops being a bright line. |
| `[SUCCESS COST]` | (A) Raises the future cost of the §1.2 escalation decision. |
| `[PRIOR CONSIDERATION]` | `017-polyglot-test-hermeticity` candidate 9's "detector, not enforcement primitive" applies to [3] too, in inverted form: [3] *has* an enforcement channel, which is exactly why its remedy-direction ambiguity (A3) matters more than it would for a pure detector. Prior conclusion still applies. |

**Recommendations from this pass**

*Must address before proceeding:*

1. **(A3) Name the remedy direction in the rule.** The scoping paragraph must say that when a
   rationale comment's mechanical half is `Incorrect`, the finding is about the **behaviour**
   unless the code is demonstrably right and only the wording is wrong — and that "reword the
   comment" is not an acceptable standalone remedy for a behavioural mismatch. Without this,
   [3]'s best case produces a better-documented bug.
2. **Ship the anti-remedy clause with [3], not after it.** Critics must be forbidden from
   recommending "add a comment saying this is deliberate" as the fix for a behavioural
   finding. Already surfaced by the revealed-preferences move; the Goodhart scenario makes it
   a blocker rather than a nicety.
3. **Run validation step 1 (the stripped-valence probe) before implementing.** Ten minutes,
   and it directly tests A1 — the assumption whose failure is a full retreat.

*Worth mitigating:*

4. Ship [7] simultaneously, not later — it is the only proposed instrument that would detect
   the Goodhart drift that creates [3]'s reversibility cliff.
5. Watch signal for valence inflation: fact-check claim-count per 100 diff lines, compared
   against the archived corpus. A >2× rise means the scoping clause is too loose.
6. Confirm `count_rubric_red` tolerates the new column before the golden fixture lands.

**Independent replication of this pass.** The same two proposals were run through
`what-if-analysis` by a separate agent with no access to this document. It converged on four
of the findings above independently — lexical laundering under (A), the remedy-loop collision
with the corpus's "add an intent comment" convention, the verdict-instability coupling, and
audit-washing under (B), which it phrased as *"it converts an invisible bad call into a
visible-but-still-bad call with an audit trail that reads as due diligence."* Convergence
across two independent passes is the strongest evidence in this document for any of these
findings; note, though, that both passes are the same model, so their errors are correlated
by construction — the same caveat this repo applies to its own critics.

It also produced **two findings this pass did not**, and one of them is decisive:

- **A1 is worse than "one word away."** This pass framed the risk as: *strip "mercy" and [3]
  has no hook.* The independent pass argues [3] may not have a hook **on the artifact as it
  actually exists**: "mercy" sits inside a normative wrapper ("that's a deliberate small
  mercy and keeps the rule … simple and total"), and a fact-checker instructed to leave
  normative claims alone will plausibly decline the whole sentence rather than dissect it —
  which is precisely what `nd2-fable-r1` already did, ruling the design consequence *"out of
  scope … critic stages own those."* Its recommendation is blunt and correct: **either extend
  the scope to reach normative-wrapper phrasing — which contradicts the boundary [3] exists
  to preserve — or stop presenting [3] as the fix for the headline case.** This is what moves
  the decision off Path A. §4.2c then settled it against [3] entirely; see §4.4.
- **(B) is data without a consumer.** [7]'s success state is a faithful record of ~25–30%
  wrong deferrals with no mechanism that forces re-examination. Its mitigation is cheap and
  is adopted: pair the column with a periodic audit sampling of `deferred` rows, rather than
  treating the column itself as the fix. Without that, [7] is the repo's own standing lesson
  in table form — prose with a border.

### 4.2c Corpus falsification of [3] — the recommendation flipped here

A corpus sweep over all eleven run trees, run after §4.2b and **independently verified by
hand against the artifacts** (commands and outputs reproduced below), falsifies candidate
[3]'s central premise. This section is written last and changes the decision.

**Finding 1 — the headline case is not a near-miss; it is a verdict class the pipeline has
never produced.** Validation step 1 turns out to be largely *pre-run*, and it comes back
negative. Every nd2 cell that checked the mercy sentence rated it **`Verified` / `High`**:

| Cell | Claim | Verdict |
|---|---|---|
| `nd2-opus-r1` | Claim 25, `sim.ts:613` | Verified / High |
| `nd2-opus-r2` | Claim 18, `sim.ts:613-628` | Verified / High |
| `nd2-fable-r1` | Claim 25, `sim.ts:613-639` | Verified / High |
| `nd2-fable-r2` | Claim 18 | Verified / High |
| `nd2-sonnet-r1` | — | did not check it |

`nd2-fable-r1` even reasons *through* the defect and still lands Verified: *"Since the
`from === "SINGING"` branch is unconditional on `to`, a SINGING→FLEE transition also sets
CONTENT — the claimed 'small mercy.'"* It identified the exact mechanism and treated it as
**confirming** the comment. That is the failure in its purest form, and it is not a
verdict-vocabulary problem — the vocabulary worked correctly. The comment *is* accurate.

**Finding 2 — decisive. The class [3] proposes to bring into scope is already in scope, and
already produces 🔴 rows.** The sibling rationale comment *"Scaled down to the sim's faster
tempo but kept the LONGEST mood window"* is a behavioural/magnitude assertion embedded in a
rationale comment — exactly [3]'s target class — and under the **current, unmodified**
non-goal #2 it is rated `Incorrect / High` in `nd2-opus-r1`, `nd2-opus-r2` and
`nd2-fable-r1`, and in `nd2-opus-r2` it is **R1, the top 🔴 Must Fix row**:

> `| R1 | WARY_MOOD_DURATION doc comment claims the value was "scaled down to the sim's faster tempo", but 30.0 is numerically identical to the concept doc's "~30s" … | Fact-check | Incorrect (high confidence) | … | 🔴 Unresolved |`

So [3]'s benefit is entirely in a population the status quo **already covers**. Its true
marginal population is only the *residue*: valence and coherence claims with no checkable
numeric core — which is precisely the subjective, connotation-dependent, cross-file material
that §4.2b's A3 identified as the worst possible input to the least stable judgment in the
pipeline. **[3]'s demonstrated benefit is already banked; its marginal cost is all
downside.**

**Finding 3 — A3 confirmed empirically, on [3]'s own claim class.** Rationale claims are the
highest-variance claim type in the corpus. The same "Scaled down…" claim: `Incorrect/High`
in `nd2-fable-r1`, `Mostly accurate/High` in `nd2-fable-r2` — same model, same claim, same
evidence, one tier apart, 🔴 vs 🟡. And *"coverage is first-class but never dwarfs quality"*
drew `Incorrect/High` (`nd3-opus-r1`) vs `Verified/High` (`nd3-fable-r1`, `nd3-sonnet-r1`),
where both verifiers checked only the all-1.0 degenerate case — the single case opus had
identified as the *only* one where the claim holds. Three runs, three verdicts, spanning the
whole ladder. [3] proposes to expand this class.

**Finding 4 — [7]'s stated motivation is partly void.** `rg "pr-intent|What this PR is
trying"` over the *entire* `/home/node/cr-eval` tree, prompts included, returns **zero
hits** (verified). The run prompts contain no intent channel at all. So the corpus does not
show that critics ignore author-stated intent — it shows author-stated intent was **never
supplied**. §0's finding stands as an observation about the corpus, but the inference drawn
from it in [7]'s motivation ("we can't tell whether a deference was grounded in stated
purpose or in a branch comment") resolves trivially here: it was *always* the comment. [7]
would spend a column recording a constant until `<pr-intent>` is actually populated, which
nothing currently schedules.

**Finding 5 — the deferences [7] would capture live one layer down.** Two explicit,
quantified deferences exist, both in *critic reports*, neither reaching a rubric row:
`nd2-opus-r1/tech-debt-triage-review.md:262` — *"The docblock above it is careful and correct
about this, **which is why the cost is Low rather than Medium**"* — and `:264`, *"that choice
is fine."* A rubric column cannot capture what never reaches the rubric. This moves [7]'s
field from the rubric to the **critic-report template**, which was previously filed under
"worth mitigating" and is now the main point of doing [7] at all.

**Finding 6 — the one row that did describe the defect was tagged away from the author.**
`nd2-opus-r2` C1 carries the full correct reconstruction, is captioned "Highest-signal
advisory", holds native severity Medium from a critic that said "Fix now" — and is tagged
`Legibility-target: for-orchestrator-synthesis`, i.e. explicitly *not* surfaced to the
author. (All four Verified mercy-claims carry the same tag, verified above.) A third
independent reason [7]-on-the-rubric does not move this case.

**Finding 7 — the winning artifact shows what actually works.** The only cell that got ND2
right, `nd3-fable-r1/architecture-review.md:45-58`, quoted the comment, conceded its
deliberateness, and overrode it anyway — *"'simple and total' optimizes for rule tidiness
over behavioral correctness"* — landing 🟡 A1, which is the finding the human then shipped as
`31fd3c4`. It won by (a) being filed under **architecture-review**, the one auto-selected
critic with a 🔴-capable severity mapping, and (b) asking the second question — *is the
documented behaviour correct?* — which `code-fact-check`'s **first** non-goal ("not a code
reviewer") forbids and which [3] does not touch.

**One claim not verified.** The sweep reports that `nd3-sonnet-r1`'s freshly generated rubric
silently omits a mandated `Author note` column — which, if true, falsifies [7]'s compliance
assumption at n≥1 and is not catchable by the golden-fixture test. My path glob did not
resolve to that file; recorded as **reported, unverified**, and it is validation step 3's
first job.

**What this does to the decision.** [3]'s comparative dominance in §4.1 was scored against an
assumed marginal population that Finding 2 shows is already served. The Reverse branch of
this DD's own pre-named fallback fires, exactly as intended: the fallback was named in §4.2
precisely so that this reversal would be a binary check rather than a fresh debate under
pressure. §4.3 and §4.4 below are written post-flip.

### 4.3 Decision presentation

```
┌─ DECISION: how should the review pipeline treat intent claims embedded in code? ──────┐
│ 5 candidates survived step-3 pruning · scored on the step-4 axes                      │
└───────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                effort         risk       coverage        key downside
  ───  ────────────────────  ────────────  ──────────  ─────────────  ───────────────────────────
   4 ★ intent-coherence move  ◐ ~1 day      ◐ med       ● 5/7 hard     ◐ conditional auto-select leaves a gap
   7   intent field (critic)  ◐ ~0.5 day    ● low       ◐ 6/7 hard     ◐ constant until <pr-intent> is populated
   2   intent-claim ledger    ◐ ~1 day      ◐ med       ◐ 5/7 hard     ◐ 2nd privileged slot for branch text
   3   claim splitting        ● ~0.5 day    ○ high      ○ 6/7 hard     ○ marginal population already covered (§4.2c F2)
   5   provenance tiering     ● ~2 hours    ◐ med       ○ 5/7 hard     ○ corroboration inoperative headless

  drill-down: name a # to expand its card; only the recommended card is open by default.
```

Two glyphs moved after §4.2c, both recorded rather than silently rewritten: **[3] risk ● → ○**
(its marginal population is the corpus's highest-variance claim class, Finding 3) and
**[3] coverage ● → ○** (its demonstrated benefit is already banked under the status quo,
Finding 2). **[4] effort ○ → ◐** per the §4.2 boring-alternative mitigation, and **[4]
coverage ◐ → ●** on Finding 7. [7] is retained with its field relocated to the critic-report
template (Finding 5), which is what lifts its coverage ○ → ◐.

```
╭─ [4] intent-coherence move (boring form)   ★ recommended ───────────────╮
│ effort    ~1 day (a move added to architecture-review; no new dispatch) │
│ risk      medium — inherits a validated 🔴-capable severity mapping     │
│ coverage  5/7 hard · 4/5 soft — asks the question fact-check forbids    │
│ hypothesis  If chosen, a replay over the three pre-fix worktrees flags  │
│             the ND2 intent-vs-intent contradiction and flags nothing on │
│             ND3's fixed sim.ts:625-628 or md1's proxy.ts:14, within one │
│             replay session; counter-evidence = any fire on the latter   │
│             two, or >1 finding per diff on the ND3 tree.                │
│ stress-tests applied                                                    │
│   · boring alternative → no new critic; a move on architecture-review,  │
│     the critic that already got this defect right (§4.2c F7)            │
│   · failure-driven → gap: architecture-review is conditionally          │
│     auto-selected, so a pure-implementation diff has no owner           │
│ key downside  The conditional auto-select gap, plus the owner cap (§5)  │
│               remains unfixed for every other critic                    │
╰─────────────────────────────────────────────────────────────────────────╯

▶ recommend [4] intent-coherence move (boring form) · confidence 70% · runner-up [7], axis = fix the reasoning vs. measure the deference first
```

### 4.4 Decision

**Path C — no human present; the recommendation reversed mid-pass and the reversal itself is
what most needs review.** No `AskUserQuestion` was issued (a prompt in a non-interactive run
hangs); the static block above is the scrutiny surface and §8 carries the round claim.

**Adopt candidate [4] in its boring form: add an intent-coherence *move* to
`architecture-review`. Do not build a new critic. Ship [7]'s intent field in the
*critic-report* template alongside it. Do not adopt [3].**

The one-sentence rationale: the only artifact in the corpus that got this defect right did so
by asking *"is the documented behaviour correct?"* — the question `code-fact-check` is
forbidden to ask — from inside the one auto-selected critic that already carries a 🔴-capable
severity mapping; [4]-boring is that behaviour written down, at no extra dispatch.

Concretely:

1. **`skills/architecture-review/SKILL.md` — one new move.** When a rationale comment asserts
   a behaviour is deliberate, do not stop at whether the comment is accurate; check whether
   the documented behaviour is *coherent* with other stated intent in the repo and with its
   own mechanical effect. A claim that is accurate **and** contradicts a stated design goal
   elsewhere is a Structural or Coupling finding, not a resolution. Use
   `nd3-fable-r1/architecture-review.md:45-58` verbatim as the worked example — it is a
   validated in-corpus instance of exactly this reasoning, and the human shipped its fix.
2. **`skills/code-review/SKILL.md` Step 5 — widen architecture-review's auto-select trigger**
   to include diffs that modify state machines or transition logic, closing the gap the
   stress test found. This is the smallest change that removes "no owner" as a failure mode
   without making the critic unconditional.
3. **The critic-report template — an `Intent` field** (`deferred / rejected / n-a`, plus the
   claim verbatim and its `file:line`), per Finding 5. The rubric column is **deferred** until
   `<pr-intent>` is actually populated in the headless path; until then it records a constant.

Plus the two obligations that survive the flip unchanged, because they are properties of the
corpus rather than of any candidate:

- **Forbid the comment-shaped remedy.** Nine reports recommend adding an intent comment as a
  fix; in five, it is offered as an equal-weight *alternative* to the code fix. The loop
  closes: the recommended comment discharges the finding, and the next run's fact-check rates
  that comment Verified/High. This is the pipeline manufacturing its own blind spot and it
  must be cut regardless of which candidate lands.
- **Name the remedy direction.** When a documented behaviour is wrong, the remedy is the
  behaviour, not the wording.

**What changed and why it is recorded rather than smoothed.** §4.1–§4.2b recommended [3] at
65%. §4.2c falsified its premise: the claim class [3] would newly bring into scope is already
in scope and already producing 🔴 rows (Finding 2), while its true marginal population drew
`Verified / High` in 4 of 4 cells that checked it (Finding 1) and is the corpus's
highest-variance verdict class (Finding 3). The pre-named fallback fired as designed. This
document keeps the superseded reasoning in place deliberately — the sequence *is* the
finding, and a reader who sees only the conclusion cannot check whether the reversal was
earned.

**Axis of disagreement.** [4]-boring and [7] score within about one cell. The axis is **fix
the reasoning now vs. measure the deference first.** The project's stated preference points at
measurement — `dd-review-gate-signal.md`'s "the repo's failure mode is enforcing unvalidated
mechanisms," and the standing §2 rule against acting on unstable outputs. [4] wins anyway on a
narrow ground: it is the *only* candidate with an in-corpus validated instance of its own
mechanism working end-to-end to a shipped human fix, so it is the one intervention here that
is not unvalidated. That is a genuinely close call and it is the thing to push back on.

### 4.5 Strongest counterargument to the recommendation

**[4]-boring may be unfalsifiable prompt-engineering dressed as a mechanism.** Its entire
evidence base is a single artifact — `nd3-fable-r1` — that produced the right answer *without*
the move existing. That cell had no intent-coherence instruction; it simply reasoned well.
Adding a move that describes what one good run already did is precisely the intervention this
repo has falsified before: §3's prune of candidate [1] rests on Result 14a showing a reviewer
that had fully internalized "intent claims are evidence, not dispositive" and still
under-banded the defect. **The prose-nudge objection that killed [1] applies to [4]-boring
with only slightly more machinery**, and the honest reading of the corpus may be that
architecture-review's success was run-to-run variance (the same J_self ≈ 0.5 that governs
everything else here), not a property of the critic.

Three things hold it up, none decisively:

- The variance objection cuts both ways: `nd3-fable-r1` and `nd3-sonnet-r1` *both* engaged the
  comment, and the ND2 cells that missed it were reasoning in critics with no authority to act
  even if they had. Owner and authority are structural, not stochastic.
- [4]-boring's hypothesis is falsifiable in one replay session against three worktrees that
  already exist, with two pre-specified negative controls (ND3 fixed docstring, md1
  `proxy.ts:14`). If it fires on either, it is producing the 70% false-positive class and
  should be dropped.
- Its cost is one day and one skill file. The failure mode is a no-op, not a regression.

If the counterargument is right, the residual is that **none** of the fourteen candidates
addresses the ND2 miss, because the miss is a channel-and-owner failure (§5) rather than a
reasoning failure — and that is the state doc's §1.2 decision, deliberately out of scope here.
This DD's most durable output may turn out to be §0's base rate, §4.2c's falsifications, and
§5's owner-cap finding, rather than any candidate it selected.

## 5. Interaction with the escalation-channel gap (not a redesign of it)

Per H3 this decision does not touch `### Escalation Rule`. It is worth being precise about
where the two problems meet, because the corpus shows the interaction is more layered than
the state doc's §1.2 records.

ND2's one correct reconstruction (`nd2-opus-r2`, C1) landed 🟢 for **two** independent
structural reasons, not one:

1. The 🔴 monopoly — nothing but a fact-check `Incorrect` or an api-consistency `Breaking`
   can produce a red row (Result 16). This is §1.2's finding.
2. **The owner cap** — the finding was filed by `tech-debt-triage`, and `SKILL.md`, "Contextual critics are advisory" sends
   contextual-critic findings to 🟢 "regardless of their internal severity." Even a
   `Critical` from that critic cannot leave 🟢.

So the same defect, correctly described, has a ceiling set by *which critic happened to
notice it*: 🟢 under tech-debt-triage (ND2 r2), 🟡 and merge-gating under architecture-review
(the ND3 baselines). The recommended candidate sidesteps both caps by routing through Stage
1 instead — a fact-check verdict is neither owner-capped nor outside the monopoly. That is
the mechanism behind the coverage agent's ranking, and it is why [3] can be adopted without
pre-empting §1.2.

**Concurrent work, noted for the merge.** An in-flight change on this branch is implementing
the state doc's §1.3 (an `Evidence` column on ✅ Confirmed Good plus a
Confirmed-Good-vs-fact-check cross-check). That partially covers one cell of this DD's
evidence: MD1's `style-src 'unsafe-inline'` carve-out was **promoted to ✅ Confirmed Good on
the strength of its comment alone** (`md1-opus-r1/code-review-rubric.md:86`), and an
`Evidence:` requirement makes "the comment says so" visibly insufficient as a citation. The
two changes are complementary and touch different tables; the [7] `Intent` column must be
rebased onto whatever rubric template lands from that work, not written against the version
quoted here.

The owner cap is a **separate finding this DD surfaced and is not resolving.** It belongs in
the §1.2 decision, or its own log row: a contextual critic that reconstructs a live
behavioural inversion has nowhere to put it, and the rule that guarantees this
(`SKILL.md`, "Contextual critics are advisory") was written to stop advisory critics gaining blocking power — a good reason
that produces a bad outcome here. Flagged, not fixed.

## 6. What to do with the pruned candidates

- **[6] Intent-blind twin pass** is the best *measurement* instrument generated here and is
  the recommended follow-up experiment, run offline rather than shipped: one core-critic pass
  on ND2 with every intent claim stripped from the diff, compared against the archived r1/r2
  cells. It puts a number on deference — currently inferred, never measured — and unlike the
  shipped candidates it costs nothing per round because it never enters the loop.
- **[10] Human queue** should not gate, but the override log
  (`docs/reviews/override-log.md`) is still empty (`_(none yet)_`) in **every one of the
  eleven run trees**. The one instrument the program says is clean for this band has never
  been written to. Any human review of an intent-deference decision should land there; that
  is a process obligation, not a code change.
- **[11] Repo intent index** stays deferred, but note that ND2's contradiction was between
  two source comments, both of which cite the *same* external document
  (`initial_concept.md`'s emotional flee table). A design doc that both comments already
  reference is a cheaper index than a new registry, and revives [11] in a much smaller form
  if this recurs.

## 7. Validation plan — everything below runs against artifacts that already exist

Steps 1 and 2 of the original plan are **already executed** — that is §4.2c, and they returned
negative for [3]. What remains:

| Step | What | Against | Cost |
|---|---|---|---|
| 1 | **[4]-boring replay.** Run `architecture-review` with the new move over the three pre-fix worktrees. Pass = flags ND2's intent-vs-intent contradiction; fails if it fires on ND3's fixed `sim.ts:625-628` or md1's `proxy.ts:14`, or emits >1 finding per diff on ND3. | 3 worktrees | 1 session |
| 2 | **Variance control for the §4.5 objection.** Re-run `architecture-review` on ND2 ×3 *without* the move. If it recovers the defect ≥2/3 times unaided, the move is decoration and should be dropped — this is the single cheapest test of the strongest counterargument. | ND2 worktree | 1 session |
| 3 | **Verify the reported column drop.** Confirm or refute that `nd3-sonnet-r1`'s fresh rubric omits the mandated `Author note` column. If confirmed, the golden-fixture test does not catch silent column omission in generated output, which is a finding about the format contract independent of this decision. | `nd3-sonnet-r1` tree | ~10 min |
| 4 | **Base-rate recheck.** §0's 70/25 split is one unblinded pass by one agent. It is the number every candidate was scored against. | 11 run trees | worth a second reader |

**Where the evidence is thin, explicitly:** [4]-boring's supporting evidence is **n=1 cell**
(`nd3-fable-r1`) and it is confounded with run-to-run variance — step 2 exists because that
confound is not currently separable. The MD1 valence cluster is n=1 diff. The 70/25 base rate
is one unblinded pass. §4.2c's Findings 1, 2, 3 and 4 are the only claims in this document
verified directly against artifacts by hand; Findings 5, 6, 7 are single-agent reads, and the
column-drop claim is explicitly unverified. Nothing else here should be cited as measured.

## 8. Round claim

Emitted because this decision resolved down Path C — the recommendation reversed mid-pass, its
replacement rests on n=1, and there is no human at decision time. Framed as a predicted
*failure* per decision 012 pillar 2, and tagged `planner-authored` because it was invented by
this DD rather than sourced from `si-input.md`.

**Hypothesis.** Adding an intent-coherence move to `architecture-review` will *fail* to change
the outcome on ND2: the critic will recover the defect at about the same rate with and without
the move, because `nd3-fable-r1`'s success was run-to-run variance rather than a property the
instruction can transfer. If validation step 2 shows unaided recovery ≥2/3, [4]-boring is
decoration, the prose-nudge objection that pruned candidate [1] applies in full, and the ND2
miss should be re-routed to the §1.2 escalation/owner-cap decision rather than treated as a
reasoning defect fixable inside a critic.

- `evaluator: user` — the pillar-1 target-resolvability rule forces this: the claim names no
  counter in the invocation logger and no file in its own `files_touched` from which a script
  could read a verdict. Judging whether a replay "recovered the defect" is a human read of an
  architecture-review report.
- `requires: { invocations: 6 }` — three ND2 replays with the move and three without
  (validation steps 1 and 2). Fewer than six ⇒ INCONCLUSIVE, never REFUTED.
- `hypothesis_window: 1` — observable in the next round's artifacts; the worktrees and the
  skill file both already exist, so nothing has to accumulate.
- `hypothesis_source: planner-authored` — review the framing itself, not just the outcome. In
  particular: this DD reversed its own recommendation once already, on evidence that was
  available from the start and was not gathered until late. The framing most worth checking is
  whether the *second* answer was reached any more rigorously than the first.
