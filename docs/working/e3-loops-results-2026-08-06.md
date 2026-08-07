# E3-loops results: lite-first vs full-only review-fix loops (csp instance, 2026-08-06)

**Design** (user-specified): arm 1 = lite review → (fix lite blockers → lite review) until
clean → full review-fix loop; arm 2 = full review-fix loop only. FULL loops, fix-stage
tokens counted. Instance: mfc csp (`d86d2dc..d90d6bb` dirty state). Caps: 3 lite / 3 full
iterations; fix-or-waive with recorded justification; loop terminates at 0 🔴.
Hypothesis: *fixes driven by lite review reduce the number of full-review iterations.*
Ledger: `runs/review-arms/e3-loops/manifest.json` (per-stage). Branches `e3/csp-arm1`
(`f25d968`) and `e3/csp-arm2` (`2544a19`) retained in the mfc repo; worktrees removed.

## Headline numbers

| | Arm 1 (lite-first) | Arm 2 (full only) |
|---|---|---|
| Shape | lite×2 + lite-fix + **full×2** + full-fix | **full×3** + full-fix×2 |
| Lite loop | 138.8k tok (6.5% of arm total); clean after 2 lite iterations | — |
| Full passes | 884.9k + 1,023.4k | 817.6k + 990.0k + 1,082.1k |
| Fix stages | 56.4k (lite) + 90.0k (full) | 77.4k + 72.7k |
| Terminal verdict | 🟡 PASSES WITH AMBERS (0R/9A) at full iter 2 | ✅ PASSES (0R/14A) at full iter 3 |
| **Total** | **2,137,136** | **3,039,841** (ratio 0.70) |

Arm 1 finished 30% cheaper with one fewer full pass. **But the hypothesis is NOT what
produced the win.**

## Why the hypothesis fails as a mechanism (on this instance)

Lite blockers ∩ full-loop reds = **∅**. The lite loop fixed the dev-eval carve-out and
waived dynamic rendering — neither appears among the full loop's reds (nonce delivery,
connect-src export break, untested policy, runtime comment). Arm 1's full-loop iteration 1
found essentially the same 4-red set arm 2's iteration 1 did. Lite-first did not preempt
full-review work; it prepended a (cheap, harmless, locally-good) loop.

## What actually decided the iteration count: verdict-draw variance on marginal reds

The same two facts got different severity draws in the two arms' fact-checks, and that
alone cost arm 2 its third pass:

- **Edge-runtime comment**: arm 1's k=3 merge drew `Incorrect/High` → red in full-1 →
  fixed in the same round as the big reds. Arm 2's iteration-1 merge (E1) drew
  `Stale/High` → amber → survived to iteration 2, where a fresh draw made it red →
  forced a third pass.
- **Immutable commit-message claim (9b4e453)**: arm 1 drew `Incorrect/Medium` → amber,
  never blocked. Arm 2 drew `Incorrect/High` → red → unfixable-by-construction → waive
  machinery + a pass to confirm it.

Both are instances of the known 0.14–0.25 red-band self-agreement problem — now shown to
directly control *loop length*, at ~1M tokens per marginal pass. n=1, variance-dominated;
treat the 0.70 ratio as noise around ~1.0, not as a lite-first effect.

## The decision-relevant findings

1. **Loop length is governed by tier-policy on marginal red classes, not by review
   sequencing.** Two policy changes would have terminated BOTH arms at 2 full passes:
   (a) fact-check `Incorrect(high)` on *non-behavioral comment text* maps 🟡, not 🔴;
   (b) claims in *immutable history* auto-route to the override log (acknowledged),
   never 🔴. Each marginal red avoided saves a full pass (~1M tokens). This is the
   highest-leverage intervention this experiment surfaced — worth a decision record
   and a SKILL.md severity-mapping edit before any further loop spend.
2. **Lite-first is ~free and locally beneficial, but not an iteration reducer.** 6.5%
   of arm cost; its fix picked the fail-closed `NODE_ENV === "development"` design
   (avoiding the fail-open bug the historical fix shipped); its waive was upheld by all
   full critics. Keep it as a hygiene stage if desired; don't expect loop savings.
3. **One consolidated fix round beats two small ones.** Arm 1's single full-fix round
   (90k) closed all four reds *well* (extracted `app/lib/security/csp.ts` — the
   placement arm 2's critics kept flagging as Coupling for two passes; mutation-verified
   falsifier; toBlob). Fix quality, not fix count, carried arm 1's terminal state.
4. **Loops do terminate under fix-or-acknowledge** — contra the E1 pass-1-only
   extrapolation. With fixes + waives in play, both arms reached 0 🔴 within caps. The
   E1 "reviewer-novelty exhaustion" worry applies to *pass-1 verdicts on unfixed
   states*, not to genuine loops.
5. **Fix-introduced-defect pattern recurred mildly** (arm 2's rationale hand-sync →
   new Coupling finding C5; both arms' silent-export-failure affordances left open) but
   nothing red — the loop contained it.

## Threats to validity

Single instance; single repo; the lite transport was a no-tools sonnet subagent over the
harness-built prompt (byte-identical prompt, different plumbing, ~2.5× the OpenRouter
token cost — arm 1's lite share would be even smaller via the real harness); both arms'
iteration-1 states reused E1/E2 outputs (same pipeline, but verdicts are draws — a fresh
arm-2 iteration 1 might have drawn differently); orchestrator judgment (waive
acceptance) exercised once, per production rules.

## Recommended next steps (in order)

1. **Tier-policy fix first** (finding 1): decision record + severity-mapping edit
   (comment-only Incorrect(high)→🟡; immutable-history→override log). Cheap, addresses
   the measured driver of loop cost.
2. **Replicate on fscompat** only *after* the tier fix (else the same variance
   dominates again): ~4–5M tokens for the pair of arms.
3. Fold results into the canon: both arm branches' terminal states are new
   labeled clean-ish states; the arms' finding sets enrich csp labels.
