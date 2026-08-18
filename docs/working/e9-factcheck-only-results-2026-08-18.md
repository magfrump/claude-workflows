# E9: E8's fact-check stage scored alone (2026-08-18)

**Not a new arm.** This re-scores the merged (k=2) `code-fact-check-report.md` that the E8
evidence-discipline pipeline already produced for each of the 8 canon instances
(`runs/review-arms/e8-evidence-pipeline/`), in isolation from every other critic
(security-review, performance-review, api-consistency-review, architecture-review,
tech-debt-triage-review, ui-visual-review, dependency-upgrade-review) and from the
provenance-ruled rubric synthesis. Goal: separate the fact-check stage's own marginal recall from
what the critics and synthesis contribute on top of it, since E8's headline 87% is the *full*
pipeline's number and doesn't by itself say how much of that is fact-check vs. everything else.

**Method**: copied only `code-fact-check-report.md` per instance into
`runs/review-arms/e9-factcheck-only/`, then ran one code-verifying adjudication agent per cell
(8 agents in parallel), each independently re-verifying against the repo at the reviewed commit —
same-mechanism matching against the 56-row ledger, not keyword overlap, not trust-the-report.
Full per-cell detail in `runs/review-arms/e9-factcheck-only/e9-scoring.md`.

## Headline

| Process | Findable | Found | Recall | Confirmed FPs | Confirmed false attestations |
|---|---|---|---|---|---|
| **E9 — fact-check stage alone** | 54 | 30 (24 firm) | **56% (44% firm)** | **0** | **1** (fscompat D6) |
| E8 — full pipeline | 54 | 47 | **87%** | 0 | 0 clean (1 over-broad-but-scoped) |

Fact-check alone recovers **~64% of the full pipeline's catch** (30/47). The critics and rubric
synthesis are responsible for the remaining 17 rows and most of the 31-point gap to 87%. Put
differently: one stage of E8, scored alone, lands in the same recall band as some *entire*
competing pipelines (E5's built-in `/code-review` at 43% firm, E4's opus-k3 union at 37% firm) —
fact-check is doing real, load-bearing work on its own, not just filling in details around the
critics.

## Per-instance

| Instance | Caught / findable | Notable |
|---|---|---|
| mfc-csp | 5/10 (3 firm) | Clean on comment-accuracy (R2, A2, A3). Structurally misses csp-R1 — `exportGraph.ts` is outside this report's diffed scope entirely, not a reasoning failure. |
| mfc-lean | 3/7 | R1/R2/N3 caught; A1 a near-miss (scope notes gesture at it, never assert it); N4/N5/N8 outside the 10-file diff scope. |
| mfc-hygiene | 2/3 | R1/A1 caught; N14 missed — `cache.ts` never referenced by any claim. |
| mfc-secdeps | 3/5 (2 firm) | sec-R1/N2 firm (N2 executed, exit 1 confirmed — correctly not certified passing); C2/N9 missed (neither tested at all; both independently confirmed real by the scoring agent). |
| mfc-deploy | 3/3 | Clean sweep. **N10 correctly refused to attest** — avoids the historical false-attestation trap with an executed trace of the real fallback path, no critic needed. |
| mfc-fscompat | 2/6 (1 firm) | Weakest cell. fsc-R1 caught; fsc-A1/A2/A3 all missed (report never leaves its literal diff scope). **D6 is a confirmed false attestation**, not just a miss — see below. |
| mfc-corpus | 6/11 (4 firm) | A3/A4/C3/D4 firm; N12/N13 only as "escalate to critics" side-notes. A1/A2/N11/D3/D5 missed — mostly cross-file/architectural/concurrency reasoning the report never attempts. |
| mfc-postfix | 6/9 (5 firm) | R1/A1/A2/A4 firm. **pf-A5 correctly scoped** — explicit about what it does/doesn't establish re: the OpenAlex payload bound, avoiding the other historical false-attestation trap. A6/A7/A8 missed. |

## The one false attestation: fscompat D6

Claim 5 asserts the on-disk cache file "stores exactly `{ text, usage }`," verified against a
hand-built test object passed directly to the caching function. The real production call site
(`callLlm.ts`'s `recordAndCache`) builds `{ text, usage, cacheKey }` and passes the whole object
through — TypeScript's structural typing doesn't strip the extra field since it isn't an object
literal at the call site, so `JSON.stringify` serializes `cacheKey` (which embeds the full prompt)
into the cache file. Exactly D6's mechanism. The claim tested the function's signature, not its
real call site, and its "stores exactly" verdict overclaims rather than hedges — the same
scope-narrowing discipline that correctly saved N10 and pf-A5 was not applied here.

## What this establishes

1. **Fact-check alone is a real, independently load-bearing stage** — 56% recall (44% firm) with
   0 confirmed false positives, matching or beating some competing arms' *full* pipelines.
2. **The two historically diagnostic false-attestation traps (N10, pf-A5) are caught by
   fact-check's execution + scope-line discipline alone**, before any critic or Stage 2.5
   endorsement-routing gets involved. This is evidence the evidence-discipline redesign's core
   mechanism (mandatory execution for executable guarantees, explicit scope lines) is doing its
   work at the fact-check layer itself, not only in the downstream synthesis.
3. **Fact-check's blind spots are structural, not incidental**: anything outside the literal
   diffed files/claims (csp-R1, lean-N4/N5/N8, hygiene-N14, postfix-A7), absence-type findings
   (untested paths, missing directives/gates — csp-A4/C1/C4, secdeps-C2/N9, corpus-N11,
   postfix-A6), and cross-file/architectural/concurrency reasoning with no claim to anchor to
   (corpus-A1/A2/D3/D5). These are exactly the classes the critics (security-reviewer especially)
   exist to cover — the split is clean, not overlapping waste.
4. **The one false attestation this arm produced (fscompat D6) came from a claim that broke its
   own discipline** — testing a function's signature via a synthetic call rather than its real
   call site, and overclaiming ("stores exactly") instead of scoping to what was actually tested.
   The same report got N10-class traps right elsewhere in the same instance set by doing the
   opposite.

## Caveats

- No new execution occurred — this is a re-score of an already-generated artifact, so there is no
  new cost/token figure to report; the comparison is recall-per-artifact, not cost-per-run.
- 8 independent scoring agents, no cross-cell consistency pass. Several "caught" credits are the
  scoring agents' own generous same-mechanism judgment calls, flagged explicitly per-cell; the 44%
  firm floor excludes them.
- No new ledger CSV column was added (this is a diagnostic slice of an existing arm's output, not
  a new arm) — recorded in the ledger's revision history and the process-recall table instead.
