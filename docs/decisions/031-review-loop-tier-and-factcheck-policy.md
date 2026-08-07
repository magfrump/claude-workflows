# 031 — Review-fix loop policy: severity tiers for marginal reds, fact-check k, and clean-pass / lite integration

- **Goal**: Set the review-fix loop's stopping-cost policy now that E1–E3 have measured
  what actually drives loop length. Four interacting knobs: (T) severity tier for
  marginal red classes, (K) fact-check replication per pass, (C) clean-pass requirement,
  (L) lite-review integration.
- **Project state**: Follows E1 (`e1-results-2026-08-06.md`: pass cost findings-independent),
  E2 (`e2-results-2026-08-06.md`: lite arm), E3-loops (`e3-loops-0R0A-results-2026-08-06.md`:
  full loops under the production 0R+0A rule). Revises the k=3 mandate of decision 029 and
  the severity mapping in `skills/code-review/SKILL.md`. Merge standard is **0R + 0A**
  (amber resolvable by fix or ack-with-justification; comment fixes cost the same as an
  ack, so they are fixed).
- **Task status**: decision made (T high-confidence, K/C medium, L scoped); SKILL edits are
  follow-up.

## Context

E3-loops ran the two composition arms to termination under 0R+0A on the csp instance.
Both merged; arm 1 (lite-first) took 2 full passes / 3.08M tokens, arm 2 (full-only) took
3 / 4.04M. The one-pass gap was **not** lite-first preemption — lite blockers stayed
disjoint from full-review reds across all of E2/E3 — it was **verdict-draw variance on two
marginal red classes**: a comment whose runtime claim was wrong ("Edge runtime"; Next runs
proxy on Node) and a false verification claim in an *already-merged* commit message. Each
drew `Incorrect/High` in one arm's k=3 chain and amber/medium in the other's, and one High
draw costs an entire ~1M-token full pass. This is the same 0.14–0.25 red-band
self-agreement instability decision 029's k=3 was built to tame — but 029 tamed it *inside
a pass* by making any High draw win (most-severe-wins), which in a *loop* maximizes
marginal-red volatility across passes.

Two structural facts from E1 reframe the whole cost model:
1. A full pass costs ~0.8–1.1M tokens regardless of how many findings it has; **fact-check
   is ~30–45% of that** (3 replicates ~250–440k + merge ~90–160k, vs critics ~350–550k and
   rubric ~90–160k). k=1 saves ~250–370k *per pass*.
2. The loop re-runs the whole pipeline every pass, so within-pass resampling (k) and
   across-pass resampling (clean-pass count) are partial substitutes — a fact decision 029
   could not use because it predates the measured loop.

## Options considered

Knob-by-knob, then bundled into candidate configurations scored against four constraints —
**H1** loop terminates (no spiral on marginal reds), **H2** no recall regression on real
behavioral/security reds vs the 029 baseline, **H3** cost per merge ≤ the 0R+0A baseline
(C1 below), **H4** the clean/passing verdict is not a single unreplicated draw.

**T — tier policy for marginal reds** (the measured loop-length driver):
- `T-off`: status quo — fact-check `Incorrect(high)` → 🔴 regardless of subject; immutable
  commit-message claims → 🔴.
- `T-on` **(chosen)**: (a) `Incorrect(high)` whose subject is a *comment/doc whose only
  consequence is a misinformed reader* (code behavior correct) → 🟡; (b) a fact-check
  Incorrect about a claim in *immutable already-merged history* (prior commit messages) →
  routed to the override log as an accepted-immutable acknowledgment, never 🔴. Behavioral
  Incorrect (code does the wrong thing), and comment-Incorrect that is itself a
  consumer-binding contract or a security rationale a future change would rely on, stay
  🔴/handled by the existing api-consistency-Breaking and soundness-contradiction channels
  (decision 028).

**K — fact-check replication per pass**: `k=3` (029) · `k=2` · `k=1`.

**C — clean-pass requirement**: `1-clean` (current) · `2-consecutive-clean` · `3-clean`.

**L — lite integration**: `none` · `once-before` the full loop (arm 1) · `every-round`
full lite loop · `fix-drift-check` (a lite pass over each fix commit gated to comment/doc
drift only).

### Candidate bundles

| ID | T | K | C | L | Note |
|----|---|---|---|---|------|
| C0 | off | 3 | 1 | none | status quo; the high-round-count pain |
| **C1** | **on** | **3** | **1** | **none** | minimal change; kills the measured loop-length driver |
| **C2** | **on** | **1** | **2-clean** | **fix-drift** | k=1 savings fund a second attestation draw; **chosen** |
| C3 | on | 1 | 1 | none | k=1 with only one draw — a recall regression (see pruned) |
| C4 | on | 3 | 2-clean | every-round | max confidence, max cost; lite value decays across rounds |

## Decision and rationale

**Adopt T-on now (high confidence), and move the default configuration to C2: T-on + k=1 +
2-consecutive-clean + a fix-commit drift lite-check — with 2-clean scoped as the default
for behavior/security/contract-touching branches and opt-*down* to 1-clean for
comment/doc/test-only branches.**

**Why T-on, decisively.** It is near-free and it is the one change E3 proved collapses the
arm gap: both the 0-red and 0R+0A runs would have terminated both arms at 2 passes with it
in place. A comment-only Incorrect still gets fixed — under 0R+0A a comment fix costs the
same as an ack, so demoting it to 🟡 does not let it rot; it just stops a stale *comment*
from carrying the merge-blocking authority of a code defect. An immutable-history claim
cannot be fixed by any new commit, so blocking merge on it is a category error; the
override log is its correct home. This is the highest-leverage, lowest-risk edit in the
program: ~1M tokens saved per marginal-red pass avoided.

**Why k=1 is now defensible (revising 029).** 029's k=3 bought two things: (a) *stability*
of the blocking verdict (the coin-flip), and (b) a shot at *variance-class recall*. Both
are partially recoverable across passes in a loop, and 029's own evidence limits what k
was ever buying:
- 029 showed **brief quality, not k, governs systematic recall** — k=3-of-weak-brief
  missed the cross-file R1 defect 0/9 while k=1-of-strong-brief found it 3/3. Re-running
  k=1 across passes does *not* recover a *systematic* miss (same rich brief → same blind
  spot every pass), but neither does k=3; that risk is owned by the brief (029 stays in
  force: the rich shared brief is mandatory).
- For the parts k *does* address — verdict stability and variance-class recall — the loop
  substitutes. A variance-class defect caught with probability p per draw is caught within
  one k=3 pass at 1−(1−p)³; across N k=1 passes at 1−(1−p)ᴺ. **These are equal at N=3 and
  the loop favors k=1 for N≥3** — *provided the defect survives to be re-drawn*, i.e.
  provided we require more than one clean pass.
- With T-on, k=3's remaining liability (promoting a marginal comment-Incorrect to
  merge-blocking via most-severe-wins) is already defanged — that class is 🟡 regardless
  of k — so the reason to keep k=3 shrinks to behavioral/security recall, which the
  brief + multi-pass cover.

**Why k=1 must be paired with 2-clean, not shipped alone.** k=1 with 1-clean gives a
variance-class defect exactly one draw before merge — strictly worse recall than k=3
(candidate C3, pruned). k=1 + 2-consecutive-clean gives every finding — fact-check *and*
critics, not just fact-check — a second independent draw before merge, which is broader
resampling than k=3 ever provided (k only replicated the fact-check stage). So the pairing
is not belt-and-suspenders: **2-clean is what makes k=1 safe**, and it simultaneously
answers H4 (a passing verdict is no longer a single draw — the standing single-sample
label's exact weakness). Cost check (H3): k=1 saves ~30% of every pass (~300k); the second
clean pass at k=1 costs ~0.7M; on a ~3-pass loop the savings (~0.9M) roughly fund the extra
pass — a **wash on cost with strictly more resampling**.

**Why the fix-commit drift lite-check (L=fix-drift), not lite-every-round.** E1/E3's
recurring "fix introduces a defect" pattern was almost always a *comment/doc going stale
relative to the fix* (arm 2's hand-synced rationale; the "cost is nil" overclaim), which
is exactly the fact-check-shaped class lite catches for ~$0.08 (E2). Running a lite drift
check on each fix commit catches that class *before* it costs a full pass to rediscover. A
*full* lite loop every round is pruned: E2/E3 showed lite's value is the in-diff
behavioral/doc class, which is largely gone by later rounds where only structural/cross-file
reds remain — lite value decays across the loop, so pay for it once (on each fix diff),
narrowly.

**Scoping 2-clean.** The user's stated pain is high round counts, and 2-clean adds a round.
T-on removes rounds (spurious marginal reds stop re-blocking), so net-vs-status-quo is
still likely flat-to-lower; but to respect the pain, 2-clean is the default only where a
missed variance-class red is expensive — branches touching behavior, security, or a
consumer contract. Comment/doc/test-only branches opt down to 1-clean (a stale comment
missed on one draw is cheap and the next real change re-reviews it).

See alternatives considered → **Pruned candidates and why** below.

## Pruned candidates and why

`[C0 status quo]: fails H1 in practice — marginal reds keep merge-blocking authority, the measured cause of the arm gap and the high round counts.`
`[C3 T-on + k1 + 1-clean]: fails H2 — k=1 with a single pre-merge draw is a strict recall regression vs k=3 for the variance class; the loop cannot compensate because 1-clean grants no second draw. This is the trap of adopting k=1 for cost without the paired attestation.`
`[C4 T-on + k3 + 2-clean + lite-every-round]: fails H3 without buying proportional confidence — k=3 duplicates within-pass what 2-clean already provides across-pass, and lite-every-round pays for a signal that decays to near-zero in late rounds. Strictly dominated by C2 on cost at equal-or-better confidence.`
`[K=2]: dominated — halfway point that keeps a merge step (the k=2 partial merge) without k=3's recall or k=1's savings; no constraint prefers it.`
`[C=3-clean]: fails H3/round-count for routine work — a third consecutive clean pass buys little over two once T-on has removed spurious re-blocking; reserve as a manual escalation for irreversible/high-blast-radius changes only.`
`[L=once-before only]: this is arm 1's design; kept as allowed but not default — E3 showed it neither saved iterations nor hurt, and its value is subsumed by fix-drift (which also catches fix-introduced drift, the more common case).`

## Stress-test mitigations

- *Invert-the-thesis* (argue to keep k=3): surfaced that k=1's recall parity depends
  entirely on the defect *surviving* to a later pass — a red that gets masked by an
  adjacent red fixed first only gets its second draw if it's still open next pass. Mitigation
  folded into the decision: 2-clean is measured from the first *fully* clean pass, so a
  finding that surfaces late still forces a fresh clean pair after its fix.
- *Boring-alternative*: the boring option is C1 (tier-only, leave k=3 and 1-clean). It is
  the safe fallback and is explicitly the **minimum** ship if the k=1/2-clean pairing is
  judged too speculative on n=1 — C1 alone captures the decisive loop-length win. C2 is the
  cost/confidence improvement on top, carrying the medium-confidence axes.
- *Failure-driven*: the recurring fix-introduces-a-defect mode (E1 §2, E3 arm-2 C5) drove
  the L=fix-drift addition and the "2-clean counts every stage's second draw, not just
  fact-check" framing — the fix-introduced defects were as often in critics/comments as in
  fact-check.

## Consequences

**Easier**: marginal comment/history reds stop costing full passes (T); each pass ~30%
cheaper (k=1); a passing verdict is a replicated draw, not a coin flip (2-clean), retiring
the single-sample-label's core weakness on the branches that matter; fix-introduced comment
drift is caught for cents before it costs a pass (L). Net cost per merge ≈ the 0R+0A
baseline at higher confidence.

**Harder**: 2-clean adds one round on branches that were already one-pass-clean — a real
tax on the user's stated pain, hence the comment-only opt-down. k=1 revises a *validated*
decision (029) on n=1 loop evidence — a genuine bet that multi-pass resampling substitutes
for within-pass k; the falsifiers below must be watched. T's comment-only demotion relies
on the reviewer correctly distinguishing "misinformed reader" from "load-bearing contract"
— the carve-out (contracts/security rationales stay red via 028 / api-Breaking) is the
guard, but it is a judgment call, not mechanical.

## Revisit triggers

`if a behavioral or security red is merged that a k=3 pass would have caught and k=1 across the actual number of passes did not — k=1 is under-sampling; restore k=2+ (029's recall was real).`
`if 2-clean routinely fails to converge (a spurious red keeps resetting the clean counter) — T's carve-out is too narrow and marginal reds are still volatile; widen the comment-only demotion or add k back for stability.`
`if comment-only ambers are being acked-not-fixed and docs are rotting — the "fix costs the same as ack" assumption broke; make comment-Incorrect ambers fix-mandatory.`
`if the fix-drift lite-check misses a fix-introduced defect that a full pass then catches — the drift gate is too narrow; widen it or accept the full-pass cost.`
`if a replication on a second instance (fscompat, deferred behind this decision) shows the arm gap or round count is NOT variance-dominated — the "verdict-draw variance drives loop length" premise is wrong and this whole policy needs re-derivation.`
`if a comment-only demotion ever lets a load-bearing rationale (a future-change-misleading security comment) reach merge stale — the carve-out failed; make security/contract-rationale comment-Incorrect stay red explicitly.`
