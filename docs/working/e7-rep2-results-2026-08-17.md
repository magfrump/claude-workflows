# E7 rep-2 (and rep-3 post-mortem) results: headless Fable 5 built-in review (2026-08-17)

**Arm**: same as rep 1 (`/code-review main` via `claude -p`, no `--bare`, subscription
credential, truncated eval clones) with the rep-1 open items applied: full
`--output-format stream-json` transcripts captured, hygiene re-run under a raised cap.
Scoring: living-ledger denominators, one adjudication agent per scored cell (5 agents,
session 2026-08-17), anti-SWR-Bench rules. All costs are `total_cost_usd` list-price
estimates under subscription, not billed spend.

**Model integrity**: every rep-2 main thread ran on `claude-fable-5`; the
`claude-opus-5` traffic in the transcripts is entirely the built-in review's own
subagents (finder/verifier agents carry `parent_tool_use_id`).

## What actually ran

| Cell | rep2 | rep3 |
|---|---|---|
| mfc-csp | scored, $18.24 | started, killed mid-run (no result.json) |
| mfc-deploy | scored, $5.14 | session limit, zero output |
| mfc-hygiene | scored, $9.90 (rep1's budget-cap death recovered) | session limit |
| mfc-lean | scored, $12.54 | session limit |
| mfc-secdeps | scored, $8.01 | session limit |
| mfc-corpus | **weekly usage limit, zero output** | session limit |
| mfc-postfix | **weekly usage limit, zero output** | session limit |
| mfc-fscompat | **OAuth refresh failure, zero output** | session limit |

Rep 3 is a total loss. The replication design collided with subscription usage
limits: rep 2's three dead cells and all of rep 3 are quota/auth casualties, not model
failures. Usable evidence from the 3× plan: rep 1 (7 cells, summary-only) + rep 2
(5 cells, full transcripts).

## Headline

| Frame | Findable | Found | Recall | FPs |
|---|---|---|---|---|
| **E7r2, 5 scored cells** ($53.83 list, ~$10.77/instance) | 18 | 15 firm + 1 partial | **83% firm** | 0 confirmed |
| **E7 reps 1–2 union** (~$131.37 attempted total) | 41 | 23 firm + 2 partial | **56% firm, ~61% incl. partials** | 0 confirmed across both reps |

The 83% is NOT sweep-comparable: the three unscored cells (fscompat 0/6, corpus
3/8+1p, postfix 3/9+1p in rep 1) are the arm's weakest. The union number is the fair
one — and it is the best non-pipeline recall to date, above E4's 49–54%.

## Per-cell (rep 2)

| Cell | Score | Notes |
|---|---|---|
| mfc-csp | 5/8 + 1p | Hits R1, **R2** (first E7 catch), **A4 as-worded** (first arm to take a test-strategy row), C1 (Turbopack HMR eval verified against the served runtime), C4 (matcher compiled with Next's own path-to-regexp). csp-A1 **partial**: a 9-agent verification pass reversed the 7-of-8-finder consensus by *running* self-hosted Next (dev + build/start) and proving the router merges middleware response headers into request headers — the break survives only as a Vercel-portability caveat + dead x-nonce plumbing. csp-A3 inverted (comment endorsed as accurate); csp-A2 missed. Re-found N1 (CONFIRMED with code citation); **refuted N7** with spec + WPT evidence. |
| mfc-lean | **3/3** | Clean sweep, exact mechanisms — R2 and A1 recovered from rep1's summary-truncation losses, confirming rep1's "measured recall is a lower bound" caveat. Re-found all of N3/N4/N5/N8. |
| mfc-hygiene | **2/2** | Both rows exact file:line. The cell that was a $15.24 zero-output death in rep 1. New verified find: edit/artifact cache-poisoning (→ **N14**). |
| mfc-secdeps | **3/3** | Second consecutive perfect cell; sec-R1/sec-A1/C2 all probe- or execution-verified. N2 re-run by execution (5 high advisories). N9 not re-found (adjacent files-scope note only). |
| mfc-deploy | **2/2** | dep-R1 full hit for the second consecutive rep (EROFS cites + cache.ts half); dep-R2's nothing-ever-written correction stated. But: **false attestation** — the fact-check pass stamped the CLAUDE.md "unset LEAN_VERIFIER_URL → mock" claim as Accurate, the exact claim N10 refutes (outcome coincidentally holds on Vercel where localhost is unreachable). N6 not re-sighted. |

## What rep 2 establishes

1. **Precision holds at full-transcript resolution: 0 confirmed FPs across 5 cells,
   ~40 itemized findings.** Rep 1's zero-FP result was not a summary-compression
   artifact.
2. **The adversarial-verifier pass cuts both ways.** It produced the two most
   interesting events of the rep: the empirical csp-A1 self-hosted refutation
   (correcting the *ledger's* implied severity — the row's mechanism is real but the
   here-and-now break is platform-conditional), and the N7 refutation
   (w3c/webappsec-csp#200 + WPT passing 3/3 engines), which likely demotes a ledger
   candidate and retro-corrects E6's and E7r1's credited hits. The same machinery
   also *dismissed* a true row's immediate impact (A1 scored partial, not yes).
3. **False attestation (H5) persists at ~1 per rep**: rep1 pf-A5, rep2 N10. Both are
   fact-check passes endorsing a doc claim that code contradicts.
4. **Stability across reps is high where both reps scored**: lean/secdeps/deploy
   rows agree rep-over-rep (deploy 2/2 twice, secdeps 3/3 twice); csp differs at the
   margins (rep1: A1+A3 firm, A4 partial; rep2: R2+A4 firm, A1 partial, A3
   inverted) — the union takes csp to 7/8, missing only csp-A2.
5. **New candidates: N14–N16** (hygiene cache-poisoning, csp img-src markdown-image
   block, deploy no-demo-mode/fallback contradiction), all code-verified or
   consistent-with-cited-source. Discovery yield stays positive even on re-reviewed
   instances.
6. **Operational lesson**: subscription quotas, not the $15/$25 caps, are now the
   binding constraint — 11 of 16 attempted rep2+rep3 cells died on limits/auth.
   Any rep 3 needs quota headroom scheduling (post-reset window) or API billing.

## Ledger changes (2026-08-17 revision)

- CSV: `E7r2 raised` column inserted for all rows; **N14–N16 appended**; N7 status →
  "candidate REFUTED by E7r2; pending demotion adjudication".
- MD: stratum E updated (N14–N16, N7 refutation, rep2 re-sighting note), headline
  table gains E7r2 and reps-1–2-union rows, found-by-pattern bullet rewritten (moat =
  enumeration/convention + comment-accuracy + type-seam, no longer cross-file).

## Open items

1. Adjudicate the N7 demotion (and the csp-A1 severity annotation) as a ledger
   re-adjudication entry; if N7 demotes, correct E6/E7r1 credited tallies.
2. HEAD adjudication for N14–N16.
3. If rep 3 is still wanted: rerun corpus/postfix/fscompat (the three cells with no
   rep2 data) after quota reset — those three are also where E7's recall story is
   weakest, so they carry most of the remaining information value.

## Records

`runs/review-arms/e7-fable-3x/<id>/rep{2,3}/{result.json,stderr.log,transcript.jsonl}`.
Adjudication: 5 scoring agents, session 2026-08-17 (verdict tables preserved in the
session transcript). Companion: `e7-rep1-results-2026-08-15.md`.
