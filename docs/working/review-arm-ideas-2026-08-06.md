# New review-loop arm ideas (post-031) and their csp measurements

**Date**: 2026-08-06 · **Follows**: decision 031 (T implemented+validated; k=1/2-clean/L
proposed), the Q&A on carry-forward fact-check. These are runnable *process* arms layered
on the now-shipped tier policy T, defined so they can be measured the way arm1/arm2 were.
**Baseline**: arm2-under-T = T + full loop + k=3 + 1-clean (validated: 2 full passes to
0R+0A on csp).

## Arm definitions

All arms assume T on (031, shipped) and the 0R+0A merge standard.

- **Arm-K1** — k=1 fact-check per pass (one replicate, no merge step), else identical to
  baseline. Tests 031's K axis. Per-pass fact-check drops from ~3 replicates + merge to 1
  replicate.
- **Arm-K1C2** — Arm-K1 + require **2 consecutive clean passes** before merge + a lite
  drift-check on each fix commit. This is 031's chosen C2. The 2-clean requirement is what
  makes k=1 safe (031): it gives every finding a second independent pre-merge draw.
- **Arm-Carry** — full loop with **fact-check carry-forward**: at pass N+1, a prior
  **Verified** claim carries forward (no re-check) iff every file it cites is unchanged
  since the pass that produced it; fresh fact-check runs only over the **changed-set** =
  (files in the fix diff) ∪ (their one-hop import closure). Verdict = carried ∪ fresh.
  Purely provenance-driven matching (git `--name-only` + report `Location:`/`Evidence:`
  paths); no model call to decide carry-eligibility. Attention-restriction is the same
  mechanism applied to the fresh pass (decision 030's Stage-1 partial-scope rule, applied
  to fact-check).
- **Arm-Carry-K1** — the composite: T + carry-forward + k=1-on-the-changed-set + 2-clean +
  fix-drift lite-check. Cached (prior k=3) verdicts on the stable bulk; fresh k=1 draws on
  the churned surface where the risk actually is.

## Measured / reconstructed on csp (the first review)

Method: the k-axis arms are **reconstructed** from the existing E1/E3 per-replicate
corpus (dozens of single-replicate fact-checks across both arms × all passes) — a larger,
cleaner recall sample than one fresh loop and free of new-draw confound. Carry-forward is
**run live** (one scoped fact-check on the real pass-1→pass-2 transition) because
reconstruction can compute the carry *fraction* but not verify the scoped run's
correctness.

### Carry-forward: a large-diff lever; ~0 on csp, ~half on corpus

Carry-eligible fraction = changeset files the *next fix* leaves untouched (their claims
carry; the rest re-check). From the actual diffs:

| Instance | changeset files | fix blast-radius files | files unchanged by fix → carry-eligible |
|---|---|---|---|
| **csp** | 2 (`proxy.ts`, `layout.tsx`) | 5 (both changeset files + exportGraph + 2 tests) | **0 of 2 (0%)** — fix touched the whole reviewed surface |
| **corpus** | 15 (`app/`) | 7 | **8 of 15 (53%)** |

So on csp, carry saves essentially nothing on the reviewed surface — the changeset is so
small the fix touches all of it. The saving scales with **(changeset − fix)**: it is a
large-changeset / small-fix optimization. The corpus instance is where it pays (~half the
fact-check surface carries on the first fix round). *Live-run result and safety check
below.*

### k=1 recall: reconstructed from the replicate corpus (`k1-recall-reconstruction.md`)

Every behavioral red was **surfaced by all 3 replicates in every live state** — no blind
spot. The only single-draw exposure is a *severity split* (one replicate grading a
surfaced fact Incorrect, another Mostly-accurate), never a miss:

| Behavioral red | state | caught/ran | p (k=1) | 1−(1−p)² (2-clean) |
|---|---|---|---|---|
| csp R1 nonce-delivery | e1/csp-dirty | 3/3 | 1.00 | 1.00 |
| csp R1 nonce-delivery | arm1/full-1 | 2/3 | 0.67 | 0.89 |
| csp R2 connect-src | e1/csp-dirty | 2/3 | 0.67 | 0.89 |
| csp R2 connect-src | arm1/full-1 | 3/3 | 1.00 | 1.00 |
| corpus state/-path bypass | e1/corpus-dirty | 3/3 | 1.00 | 1.00 |
| corpus ArrayBuffer comment | e1/corpus-dirty | 3/3 | 1.00 | 1.00 |

Corpus reds are unanimous everywhere; the two csp root-cause reds have one state each at
p=2/3. 2-consecutive-clean lifts the p=2/3 worst case to 0.89 (0.96 at N=3). The only
p≤1/3 row is the *derivative* strict-dynamic consequence of R1 (🟡-class under T), not an
independent defect. **Verdict: k=1 + 2-clean is an acceptable substitute for k=3 on
behavioral-red recall for this corpus**; the residual is noisier Incorrect-vs-MA calls on
comment-level items — exactly the class T already routes to amber.

### Carry-forward live run on csp (`carry-arm2-pass2/`): 0 carried, safety held

Pass-1→pass-2 (d90d6bb→99e1229): **carried 0 / rechecked 15 / changed-set = 8 files**. All
three pass-1 Verified claims cite a fix-touched file, so nothing was carry-eligible — the
predicted near-zero-carry worst case. **Safety check passed**: every finding a full-scope
pass surfaces at 99e1229 is in the scoped output (all sit in the fix blast radius), with a
structural guarantee — a non-Verified finding is must-recheck by construction, and a
Verified claim can only go stale if the fix touched a file it cites, which *is* the recheck
trigger. So carry never hides a finding. Token saving on csp: **~0–10% (negligible)** —
and a newly-surfaced limit: **existential/absence claims** ("OpenAlex appears nowhere",
"no residual `fetch(data:)`") grep the whole tree and cannot be file-scoped, so they
re-run regardless of changed-set. Carry only saves on *located* claims over unchanged
files.

### Cost arithmetic (per-stage tokens measured in E3)

A csp full pass ≈ fact-check(k=3 ~370–400k incl. merge) + 5 critics(~370–450k) +
rubric(~120–160k) ≈ **~880k**. **k=1 removes 2 replicates + the merge ≈ −280–300k/pass
(~33%)**, so a k=1 pass ≈ ~590k. On the validated 2-full-pass csp loop under T:

| Arm | full passes | est. loop total (full passes only) | vs baseline |
|---|---|---|---|
| Baseline (T, k3, 1-clean) — validated | 2 | ~1.76M | — |
| Arm-K1 | 2 | ~1.18M | −~0.58M (−33%) |
| Arm-K1C2 (2-clean → +1 pass) | 3 | ~1.77M | ~wash, but every finding gets a 2nd draw |
| Arm-Carry | 2 | ~1.74M | ~0 on csp; **−~half fact-check on corpus-class diffs** |
| Arm-Carry-K1 | 2 | ~1.16M | −33% now, more on large diffs |

(Loop totals exclude the shared fix + amber-disposition + verify stages, which are
arm-invariant; the table isolates the review-stage delta each arm changes.)

## Conclusion (both runs complete)

- **Ship k=1 + 2-consecutive-clean** (Arm-K1C2, = 031's C2 minus carry) as the default:
  measured recall parity with k=3 on this corpus (every behavioral red surfaced by every
  replicate; 2-clean covers the p=2/3 severity-split states), ~33% cheaper per pass funding
  the extra clean pass, and every finding gets a genuine second pre-merge draw. The residual
  is comment-level severity noise, which T already sends to amber. Still n=1 instance — the
  031 falsifier (a merged behavioral red k=3 would have caught) stands.
- **Make carry-forward conditional on changeset size, not default-on.** It saved ~0 on csp
  (changeset ⊂ fix blast radius) and projects to ~half the *located*-claim fact-check on
  corpus-class diffs (8/15 files unchanged by the first fix). Gate: enable when
  changeset > ~10 files AND the fix touches < ~half of them. Two hard limits found:
  (1) existential/absence claims don't file-scope, so they re-run regardless — carry saves
  only on located claims; (2) the saving is on *fact-check only* (~30–45% of a pass), so
  even best-case corpus carry trims ~15–20% of a whole pass, not half.
- **Composite Arm-Carry-K1** is the large-diff default: k=1's 33% + carry's large-diff
  fact-check trim, with cached prior-k=3 verdicts on the stable bulk and fresh draws on the
  churn. On small diffs it degenerates to Arm-K1 (carry contributes nothing), which is
  fine.
- **Safety is not the deciding axis** — carry is provably non-hiding (structural: findings
  are must-recheck, Verified-goes-stale ⇒ file-touched ⇒ recheck), and k=1's exposure is
  severity calibration, not blindness. The deciding axes are cost (k=1 wins now; carry wins
  on big diffs) and the standing n=1 recall-falsifier.

Next: these arm definitions + measurements feed a follow-up to 031's K/C/L axes; a
second-instance (fscompat/corpus loop) run would move k=1+2-clean and carry from
"reconstructed/one-instance" to validated — and is the same fscompat run 031 already defers.
