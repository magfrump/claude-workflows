# k=1 Recall Reconstruction from k=3 Replicate-Agreement

**Question:** Would a single-draw (k=1) fact-check have caught the same RED-mapped findings (🔴/🟡) that k=3 merged (most-severe-wins) caught? Validates decision 031's k=1 proposal against the real draw corpus, using the per-claim `Replicate verdicts: r1/r2/r3` lines already recorded in each merged report — no fresh run.

**Method:** For every merged fact-check claim whose verdict is **Incorrect** (any confidence) or **Stale** (the findings that map to 🔴 or 🟡), I mined the per-replicate verdicts. A replicate is counted as **caught** if it recorded that claim at Incorrect or Stale; **ran-on-it** = replicates that recorded any verdict for the cluster (a `—` / "not checked" entry = did not surface = not in the denominator, per the task's formula). Single-draw catch rate `p = caught / ran`. Across-N-pass catch rate = `1 − (1 − p)^N`.

**Classification (decision 031 tier policy T):**
- **behavioral** = code is wrong → 🔴 under T (the real defects: csp R1 nonce-delivery, R2 connect-src; corpus `state/`-path bypass; corpus ArrayBuffer comment-vs-code — see note).
- **comment-only / immutable** = code correct, reader misinformed, or immutable commit-message history → 🟡 or override log under T.

**Caveat on the denominator.** `p` divides by replicates that *surfaced* the cluster. A stricter "any of 3 draws" reading (absent = a k=1 miss) would lower `p` for the single-replicate-detection rows (denominator forced to 3). This only affects comment-only/immutable rows here; every behavioral red was surfaced by all 3 replicates in every live state, so their denominators are 3 regardless.

---

## 1. Full findings table

| Report (state) | Claim / location | Behavioral? | caught/ran | p | 1−(1−p)² | 1−(1−p)³ |
|---|---|---|---|---|---|---|
| e1/csp-dirty (d90d6bb, pre-fix) | C2 nonce-delivery (layout.tsx:28-30) — **R1** | **behavioral** | 3/3 | 1.00 | 1.00 | 1.00 |
| e1/csp-dirty | C6 connect-src `'self'` (proxy.ts:16-17) — **R2** | **behavioral** | 2/3 | 0.667 | 0.889 | 0.963 |
| e1/csp-dirty | C5 Tailwind style-src rationale (proxy.ts:12-14) | comment-only | 1/3 | 0.333 | 0.556 | 0.704 |
| e1/csp-dirty | C7 "Edge runtime" (proxy.ts:35-37) [Stale] | comment-only | 1/3 | 0.333 | 0.556 | 0.704 |
| e1/csp-dirty | C12 commit 9b4e453 verification claim | immutable-history | 2/2 | 1.00 | 1.00 | 1.00 |
| e1/corpus-dirty (2dc403e) | C8 paths.ts "only source" invariant — **state/-path** | **behavioral** | 3/3 | 1.00 | 1.00 | 1.00 |
| e1/corpus-dirty | C20 "fresh ArrayBuffer view" comment vs code | behavioral* | 3/3 | 1.00 | 1.00 | 1.00 |
| e1/corpus-dirty | C12 storeAdapter "layout.ts" dangling ref [Stale] | comment-only | 3/3 | 1.00 | 1.00 | 1.00 |
| e1/corpus-dirty | C19 opfsAdapter stale line ref (ws.ts:44-46) [Stale] | comment-only | 3/3 | 1.00 | 1.00 | 1.00 |
| e3 csp-arm2/full-2 (99e1229, R1/R2 fixed) | C7 Tailwind style-src rationale | comment-only | 3/3 | 1.00 | 1.00 | 1.00 |
| e3 csp-arm2/full-2 | C9 "Edge runtime" | comment-only | 3/3 | 1.00 | 1.00 | 1.00 |
| e3 csp-arm2/full-2 | C17 commit 9b4e453 verification claim | immutable-history | 2/2 | 1.00 | 1.00 | 1.00 |
| e3 csp-arm2/full-2 | C19 commit-msg "Layout reads headers()" [Stale] | immutable-history | 1/1 | 1.00 | 1.00 | 1.00 |
| e3 csp-arm2/full-3 (2544a19, fully fixed) | C17 commit-msg "Layout reads headers()" [Stale] | immutable-history | 1/1 | 1.00 | 1.00 | 1.00 |
| e3 csp-arm1/full-1 (e5d95a9, pre-fix) | C1 nonce-delivery — **R1** | **behavioral** | 2/3 | 0.667 | 0.889 | 0.963 |
| e3 csp-arm1/full-1 | C4 strict-dynamic protection (derivative of C1) | behavioral | 1/3 | 0.333 | 0.556 | 0.704 |
| e3 csp-arm1/full-1 | C6 connect-src `'self'` — **R2** | **behavioral** | 3/3 | 1.00 | 1.00 | 1.00 |
| e3 csp-arm1/full-1 | C5 Tailwind style-src rationale | comment-only | 2/3 | 0.667 | 0.889 | 0.963 |
| e3 csp-arm1/full-1 | C8 "Edge runtime" | comment-only | 3/3 | 1.00 | 1.00 | 1.00 |
| e3 csp-arm1/full-1 | C9 x-nonce dead plumbing [Stale] | comment-only | 1/3 | 0.333 | 0.556 | 0.704 |
| e3 csp-arm1/full-1 | C13 commit 9b4e453 verification claim | immutable-history | 2/3 | 0.667 | 0.889 | 0.963 |
| e3 csp-arm1/full-2 (f25d968, fixed) | — none (0 Incorrect, 0 Stale) | — | — | — | — | — |
| e3 validate-T-arm2 (99e1229) | Cluster A OpenAlex stale name [Stale] | comment-only | 1/3 | 0.333 | 0.556 | 0.704 |
| e3 validate-T-arm2 | Cluster B x-nonce overstatement [Stale] | comment-only | 1/3 | 0.333 | 0.556 | 0.704 |
| e3 validate-T-arm2 | Cluster C "Edge runtime" label | comment-only | 1/2 | 0.500 | 0.750 | 0.875 |
| e3 validate-T-arm2 | Cluster D 9b4e453 verification claim | immutable-history | 3/3 | 1.00 | 1.00 | 1.00 |

\* **ArrayBuffer (corpus C20):** the task groups it with the behavioral reds; strictly it is a comment-vs-code *mismatch* (comment claims a fresh view; code passes `bytes` unmodified). Code isn't provably wrong today (a copy may be unnecessary), so under T it reads 🟡/comment-only, but it may mask a real shared-buffer bug at S3. Either way it was caught 3/3 (p=1), so its classification does not move any headline.

---

## 2. Headline — were the BEHAVIORAL reds caught unanimously (p=1)?

**Not uniformly. Two of the four behavioral reds have a live state where p < 1.0 — but never below 2/3, and never a true miss.**

| Behavioral red | State(s) | caught/ran | p | Unanimous? |
|---|---|---|---|---|
| **csp R1 nonce-delivery** | csp-dirty | 3/3 | 1.00 | yes |
| **csp R1 nonce-delivery** | arm1/full-1 | 2/3 | 0.667 | **no** (r1 → Mostly accurate) |
| **csp R2 connect-src** | csp-dirty | 2/3 | 0.667 | **no** (r2 → Mostly accurate) |
| **csp R2 connect-src** | arm1/full-1 | 3/3 | 1.00 | yes |
| **corpus state/-path bypass** | corpus-dirty | 3/3 | 1.00 | yes |
| **corpus ArrayBuffer comment** | corpus-dirty | 3/3 | 1.00 | yes |
| *(derivative)* strict-dynamic protection (C4, tracks R1) | arm1/full-1 | 1/3 | 0.333 | **no** — genuine k=1 risk class |

- **Corpus reds: unanimous (p=1) everywhere.** No k=1 exposure.
- **Both csp behavioral root-cause reds: each has one state at p=2/3.** Crucially, in every p<1 case **all three replicates still surfaced the underlying fact** — the split is a *severity-calibration* disagreement (Incorrect vs. Mostly accurate/Stale), not a replicate failing to notice. In arm1/full-1, r1 downgraded R1 to Mostly accurate because it found a real additional code path (the Node router mirroring proxy response headers into `req.headers`), i.e. evidence-backed, not a blind spot.
- **One genuine p≤1/3 behavioral row:** C4 (strict-dynamic protection) in arm1/full-1, caught by only r3. But C4 is not an independent defect — it is the security *consequence* of R1 (nonce-delivery), whose root cause was caught 2/3 in the same state. Fixing R1 resolves C4.

---

## 3. Verdict — does k=1 regress behavioral-red recall, and does N=2 close the gap?

k=1 introduces a **modest, bounded** regression in behavioral-red recall relative to k=3-merged-most-severe (which, by catching anything ≥1 replicate flagged, is effectively p=1 for every surfaced finding). On this corpus the regression is not a *miss* problem: in all seven reports every behavioral red was **surfaced by all three replicates in every live state** — the only single-draw exposure is that a given draw may **downgrade** a real 🔴 to 🟡 (Incorrect → Mostly accurate/Stale) on a severity-calibration split. The worst single-draw catch rate for any behavioral root-cause red is **p=2/3** (csp R1 in arm1, csp R2 in csp-dirty); the corpus reds sit at p=1.0. The one p=1/3 behavioral row is a derivative security-consequence claim (C4) whose root cause (R1) is caught at p=2/3, so it rides along with the fix. The two fully-fixed terminal states (arm1/full-2, csp-arm2/full-3) carry zero Incorrect/Stale, so k=1 has nothing to regress there. **Net: k=1 does not lose any behavioral red outright on this corpus; it risks a one-tier severity under-call on the two csp root-cause reds with per-pass probability ≤ 1/3.**

The **2-consecutive-clean (N=2) termination rule closes most of this gap**: a red that survives gets ≥2 independent k=1 draws before the loop can terminate, so its effective catch rate is `1−(1−p)^N`. For the p=2/3 csp reds that is **0.889 at N=2** and **0.963 at N=3** — i.e. a real 🔴 escapes both of two consecutive passes only ~11% of the time, and that "escape" is a severity downgrade of an already-surfaced fact, not an unseen defect. The residual weak spot is the p=1/3 comment-only/immutable rows and the derivative C4 (N=2 → 0.556, N=3 → 0.704); these are 🟡/override-log class under T, not behavioral blockers, so the consequence of a k=1 under-call there is documentation-accuracy debt rather than a shipped bug. Recommendation stands: k=1 with the N=2-clean gate is an acceptable substitute for k=3 on behavioral-red recall for this corpus, with the understood tradeoff that borderline Incorrect-vs-Mostly-accurate calls on comment-level items will be noisier per pass.
