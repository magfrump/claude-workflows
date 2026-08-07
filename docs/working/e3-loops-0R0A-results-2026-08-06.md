# E3-loops under the production 0R+0A criterion (csp instance, 2026-08-06)

**Supersedes** the 0-red-only reading in `e3-loops-results-2026-08-06.md`. Corrected
stopping rule (user's production standard): a branch merges only at **0 red AND 0 amber**,
where an amber resolves by a fix OR an explicit ack-with-justification; comment
corrections are fixed (same cost as an ack). Full loops, all fix/disposition tokens
counted. Instance: mfc csp (`d86d2dc..d90d6bb`). Ledger: `runs/review-arms/e3-loops/manifest.json`.
Branches `e3/csp-arm1` (tip `1eb081e`) and `e3/csp-arm2` (tip `ab4dbdb`) retained.

## Result: both arms MEET 0R+0A. Arm 1 = 3.08M tokens, Arm 2 = 4.04M (ratio 0.76).

| Phase | Arm 1 (lite-first) | Arm 2 (full only) |
|---|---|---|
| Lite loop (2 lite reviews + 1 fix) | 138.8k | — |
| Full pass 1 (+ fix) | 884.9k (+90.0k) | 817.6k (+77.4k) |
| Full pass 2 (+ fix) | 1,023.4k | 990.0k (+72.7k) |
| Full pass 3 | — | 1,082.1k |
| Amber-disposition round | 93.7k | 107.2k |
| Verification pass | 850.3k | 890.8k |
| **Total** | **3,081,056** | **4,037,880** |

Full-review passes to reach a mergeable state: **arm 1 = 2, arm 2 = 3.** Both then took one
amber-disposition round + one verification pass. Arm 1 came out ~24% cheaper.

## Does this vindicate the hypothesis? No — same mechanism finding as before, now clearer.

The hypothesis was *lite-first fixes reduce full-review iterations*. Arm 1 did run one
fewer full pass, but **not because lite-first fixes preempted full-review reds** — lite
blockers ∩ full reds was still ∅ (lite fixed dev-eval + waived dynamic-rendering; the full
reds were nonce-delivery, connect-src, untested policy, runtime comment). The extra arm-2
pass was caused, exactly as in the 0-red run, by **verdict-draw variance on two marginal
red classes** (the Edge-runtime comment and the immutable-history claim drew High in
arm 2's chain and amber/medium in arm 1's). Under the stricter 0R+0A rule the same
variance produced the same one-pass gap. So the 0.76 ratio is again variance around ~1.0,
not a lite-first effect — n=1, and the driver is calibration noise, not sequencing.

## What 0R+0A actually cost, and where the arms converged

- **The amber-disposition round is cheap and effective** (94–107k, ~2.5–3.5% of arm total).
  Under 0R-only these ambers would have been ignored; under 0R+0A they were dispositioned
  in one round — 8 fixed / 1 acked (arm 1), 8 fixed / 6 acked (arm 2). The stricter bar
  did **not** trigger extra full loops; it added one disposition round + one verify pass
  to each arm (~940–1000k combined, dominated by the verify pass).
- **The verification pass found no new reds and no *merge-gating* new ambers in either
  arm** — every new item (form-action absent, prefetch µs cost, matcher-anchor comment
  nit, a fix-introduced comment-pointer coupling) mapped Low/Info→🟢. So under 0R+0A the
  loop **terminated after exactly one disposition+verify cycle** — it did not spiral, which
  is consistent with your report of high-but-finite round counts.
- **The fix-introduced-defect pattern recurred but stayed sub-amber**: arm 2's
  single-owner style-src fix created a filename-pointer coupling (arch N1); arm 1's
  verify surfaced a missing `form-action` that arm 2 had fixed in its amber round. Both
  green under the mapping. The pattern is real (E1 flagged it) but the loop contains it.

## The decision-relevant findings (unchanged in direction, sharpened)

1. **Loop length is set by tier-policy on marginal red classes, not by review
   sequencing** — reconfirmed under 0R+0A. Two policy edits collapse the arm-2/arm-1 gap:
   (a) comment-only `Incorrect(high)` → 🟡, (b) immutable-history claims → override log,
   never 🔴. Each avoided marginal red saves a ~1M-token full pass. Highest-leverage
   change; worth a decision record + SKILL severity-mapping edit before any further loop
   spend. (This is exactly the edit that would also have let the 0-red run terminate both
   arms at 2 passes.)
2. **0R+0A is affordable on top of a clean loop**: ~1 disposition round + 1 verify pass,
   no extra full iterations, no spiral on this instance. The amber bar mostly buys
   comment/scope accuracy and small hardening (form-action, matcher anchoring, dead-seam
   deletion) that 0R-only leaves on the floor.
3. **Lite-first stays ~free and locally good, not an iteration reducer** (lite loop = 4.5%
   of arm 1's total; its fixes were fail-closed and upheld). Keep it as hygiene if
   desired; expect no loop-count savings.
4. **Amber dispositions themselves need review** — the disposition edits introduced
   (sub-amber) findings in both arms, so the verification pass is load-bearing, not
   ceremonial. Under 0R+0A you cannot skip it.

## Threats to validity (unchanged)

Single instance, single repo; iteration-1 states reused from E1/E2 (same pipeline,
verdicts are draws); lite transport was a no-tools sonnet subagent over the harness prompt
(byte-identical prompt, ~2.5× token cost — arm 1's real-harness lite share would be even
smaller); orchestrator waive-acceptance exercised per production rules. The n=1
variance caveat is the main one: the entire arm gap is one full pass driven by two
severity draws.

## Recommended next steps

1. **Tier-policy decision record + severity-mapping edit** (finding 1) — before any
   replication, so the next run measures sequencing rather than re-measuring the same
   draw variance.
2. Only then replicate on fscompat under 0R+0A (~8–10M tokens for the arm pair with
   full loops + disposition + verify).
3. Fold both arms' terminal states into the canon as new labeled clean states (both are
   genuinely 0R+0A-clean, unlike any historical rubric in the canon).
