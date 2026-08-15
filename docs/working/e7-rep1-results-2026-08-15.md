# E7 rep-1 results: headless Fable 5 built-in review, replication 1 of 3 (2026-08-15)

**Arm**: E7 = built-in `/code-review main` via `claude -p` (no `--bare` — it blocks all
subscription auth; see run-host.sh header), model `claude-fable-5`, CLI 2.1.232, fresh
node:22 container whose `~/.claude` holds only a copied subscription credential,
$15/instance budget cap, subscription-billed (**all costs below are list-price
estimates from `total_cost_usd`, not billed spend**). Inputs: the truncated eval clones.
Scoring: living-ledger denominators (43-row ledger of 2026-08-14), one adjudication
agent per cell (7 agents, session 2026-08-15), anti-SWR-Bench rules. This is rep 1 of a
planned 3× replication; per-hit stability and union-of-reps land with reps 2–3.

## Headline

| Arm | Found / findable | Recall | Confirmed FPs | Cost per instance (list) | Attempted sweep (list) |
|---|---|---|---|---|---|
| **E7r1 fable (7 of 8 cells)** | 17 firm + 3 partial / 39 | **~44% firm, ~51% incl. partials** | **0** | $4.14–$15.24 (~$8.90 avg scored) | **$77.54** (incl. hygiene's wasted $15.24) |
| (E5 opus built-in, for reference) | 18 firm + 1 partial / 41 | ~46% | 0 | ~$0.88 | $7.06 |
| (E4 opus-k3) | 20–22 / 41 | 49–54% | 1 | ~$0.69 | $5.51 |
| (pipeline as operated) | 33 / 43 | 77% | unmeasurable | ~$14.60 | ~$116.80 |

Aggregate recall ties the E4/E5 band at ~10× E5's list cost — but the aggregate is not
the story. Three cells and one caveat are.

## Per-instance

| Instance | Recall | Cost (list) | Hits | Notable |
|---|---|---|---|---|
| mfc-csp | 5/8 + 1p | $7.98 | R1, **A1**, A3, C1, C4 (+A4 partial) | **Best csp cell of any arm ever** (E5 and E6: 3/8). A1 stated with the exact request-header mechanism and one-line fix; R1 cross-file; re-found N1 and N7. Misses only the two comment-accuracy rows R2/A2. |
| mfc-lean | 1/3 | $14.87 | R1 | R1 code-verified cross-file. R2/A1 absent *from the summary* — the run claimed "10 findings reported" but only the final paragraph survives (§evidence caveat). All of N3/N4/N5 firmly re-found; +1 TRUE-substantive (N8 persist-path). Cost sat at the cap's edge. |
| mfc-hygiene | **not scored** | $15.24 wasted | — | `error_max_budget_usd` at the $15 cap, zero output. The one hard failure; needs a re-run at a higher cap. |
| mfc-secdeps | 3/3 | $6.96 | R1, A1, C2 | Perfect cell, second arm running (E5 also 3/3). Reproduced N2's failing audit gate **by execution** (5 high advisories) and the C2 bypass by lint fixture. +1 TRUE-substantive (N9 unscoped-rules lint crash, also by execution). |
| mfc-deploy | 2/2 | $5.99 | **R1**, R2 | **First non-pipeline arm to fully land dep-R1** (E4/E5 both near-missed): EROFS-swallowed mechanism, refuting files, and the Clear-button 500 consequence. +1 TRUE-substantive (N10) + 6 true minors. N6 not re-found. |
| mfc-fscompat | 0/6 | $4.14 | — | Worst cell, but largely artifactual: the arm reported "1 correctness, 1 docs, 1 test-coverage" and the docs/test-coverage contents (plausibly fsc-R1/fsc-A4) are not in the saved summary. The one contentful finding (VERCEL-env local-dev misroute) adjudicated TRUE-minor. |
| mfc-corpus | 3/8 + 1p | $12.86 | C3, **D3**, **D5** (+A4 partial) | The deep-bug profile again (E5's corpus shape): live-at-HEAD D3/D5 exact-mechanism, C3 hedged to precisely the ledger's own epistemic state. Whiffs the enumeration tier (A1/A2) and forfeits A3/D4 to an unitemized "two misleading comments" line. +3 TRUE-substantive (N11–N13 flag-on data-loss cluster). |
| mfc-postfix | 3/9 + 1p | $9.50 | A1, A2, A6 (+R1 partial) | pf-R1 partial is new ground: found the *more severe* latent CausalGraphPanel crash (code-verified) though not the type-seam root. **A1 flagged, not endorsed** — the E5 H5 failure did not recur. One false attestation: certified pf-A5's cap arithmetic as checking out. 0 FPs on the historically FP-prone instance. |

## What rep 1 establishes

1. **Precision is the cleanest result: 0 confirmed FPs across all 7 cells,** on strict
   adjudication with code verification, including the instance (postfix) that produced
   both prior headless FPs. Every affirmative defect claim in every summary checked out.
2. **The cross-file moat is breached in three places.** dep-R1 (first non-pipeline full
   hit), csp-R1, lean-R1 — all cross-file-verification class, all landed in one rep.
   Combined with E5, the "headless can't cross files" generalization is now dead; what
   survives as pipeline-only: enumeration/convention (cor-A1/A2, fsc-A2, pf-A7),
   test-strategy as-worded, comment-accuracy sweeps (csp-R2/A2, cor-A3, D4, pf-A8), and
   the pf-R1 type-seam root (though E7 uniquely found its worst symptom).
3. **False attestation (H5) is reduced but not gone**: E5's three csp
   certified-clean rows and the pf-A1 endorsement did not recur; one new instance
   (pf-A5's spread-safety arithmetic certified clean) did. 1 attestation vs E5's 3+.
4. **Discovery yield is the highest of any arm**: 6 new TRUE-substantive candidates
   (N8–N13) in one rep — vs E5's 6 across a full sweep — plus independent re-sightings
   of 6 of the 7 E5/E6 candidates (N1–N5, N7; N2 by execution). The corpus flag-on
   data-loss cluster (N11–N13) and the secdeps lint-crash (N9) are the standouts.
5. **The evidence base is the arm's own bottleneck.** Only the final summary paragraph
   survives (`result` field); the runs themselves claim "10 findings" / "17 verified
   findings" / itemized reports that are lost. lean-R2/A1, fsc-R1/A4, cor-A3, D4 are
   all plausibly-found-but-unscoreable. **Measured recall is therefore a lower bound**,
   and reps 2–3 should capture full transcripts (`--output-format stream-json` or
   `--verbose`) before drawing model-vs-model conclusions against E5 (whose scoring had
   the same summary-only limitation — the comparison is fair but both are floors).
6. **Cost profile changes the arm's tier.** ~$8.90/scored instance (list) is ~10× E5
   and approaches the pipeline's ~$14.60. hygiene shows the $15 cap is reachable by
   normal runs; raise to ~$25 for reps 2–3 (subscription-billed, so the cap spends
   usage limits, not dollars). Under subscription the marginal dollar cost is $0, but
   the weekly-limit draw is real.

## Ledger changes

- CSV: new `E7r1 raised` column populated for all 43 rows + N1–N7; six new candidate
  rows **N8–N13** appended (all TRUE-substantive, code-verified or
  execution-reproduced; see CSV for one-liners).
- MD: stratum E retitled E5/E6/E7, N8–N13 listed, E7 row added to the headline recall
  table.
- Denominator note: figures above use the 43-row ledger; as N-rows graduate the
  denominators grow and E7's own finds will count against other arms' recall.

## Open items for reps 2–3

1. Re-run hygiene rep1 with a raised cap (`--max-budget-usd 25`) — the skip logic will
   pick it up automatically (`num_turns 0` ⇒ not completed).
2. Capture full output (stream-json) so hits aren't lost to summary compression.
3. After rep 3: per-hit stability table, union-of-reps recall, and the E5-vs-E7
   model comparison (only on rows where both evidence bases are comparable).

## Records

`runs/review-arms/e7-fable-3x/<id>/rep1/{result.json,stderr.log}` (`total_cost_usd` =
list-price estimate under subscription). Adjudication: 7 scoring agents, session
2026-08-15. Auth/`--bare` forensics: run-host.sh + debug-auth-host.sh headers and the
2026-08-15 session log.
