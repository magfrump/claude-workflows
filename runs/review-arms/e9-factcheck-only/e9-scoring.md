# E9: fact-check-only recall — scoring the E8 code-fact-check-report in isolation

**Date:** 2026-08-18 · **Scorer:** 8 parallel code-verifying adjudication agents (one per cell,
same-mechanism matching, independent re-verification against the repo at the reviewed commit —
not keyword overlap, not trust-the-report) ·
**Arm:** NOT a new run. This re-scores the merged (k=2) `code-fact-check-report.md` already
produced by the E8 evidence-discipline pipeline sweep (`runs/review-arms/e8-evidence-pipeline/`),
in isolation from every other critic (security-review, performance-review, api-consistency-review,
architecture-review, tech-debt-triage-review, ui-visual-review, dependency-upgrade-review) and
from the rubric synthesis. Goal: measure the fact-check stage's own marginal recall against the
56-row ledger, separated from what the critics + synthesis add on top of it. ·
**Inputs:** `runs/review-arms/e9-factcheck-only/<instance>/code-fact-check-report.md` — a verbatim
copy of each instance's merged E8 fact-check report, nothing else. ·
**Base:** 56-row ledger of 2026-08-17, same findable-54 denominator as `e8-scoring.md`
(56 − D1 − D2, both defects introduced by fix commits no E8 dirty-state cell reviewed).

## Headline

- **E9 (fact-check-only) recall: 30/54 = 56%**, against **E8 full-pipeline recall: 47/54 = 87%**.
  The fact-check stage alone recovers **~64% of the full pipeline's catch** (30/47); the
  remaining critics (security/performance/architecture/api-consistency/tech-debt/UI) plus the
  provenance-ruled rubric synthesis contribute the other 17 rows (~31 points of recall).
- **Firm floor (excluding generous/partial-credit calls the scoring agents flagged as such):
  ~23-24/54 ≈ 43-44%.** Several "caught" credits were the agents' own judgment calls on
  same-mechanism-but-not-explicit matches (see per-cell notes) — the primary 56% figure includes
  them, matching the E8 scoring's own precedent of reporting a primary figure plus a firm floor.
- **0 confirmed false positives** across all 8 cells — matches E8's own precision claim; the
  fact-check stage alone is not a source of the corpus's historical FP hotspots.
- **1 confirmed false attestation** (fscompat, D6 — Claim 5's "stores exactly `{text, usage}`"
  overclaim, refuted by tracing the real `recordAndCache` call site, which also serializes
  `cacheKey`). This is the one place fact-check-only, unsupervised by a critic, asserted the
  *opposite* of the true behavior rather than merely missing it.
- **Both of the corpus's two historically diagnostic false-attestation traps were independently
  avoided by fact-check alone**: N10 (unset `LEAN_VERIFIER_URL`, deploy) and pf-A5 (`Math.max`/
  OpenAlex payload, postfix) were both correctly scoped as Incorrect / not-attested-safe, with
  executed evidence backing the refusal to certify. This is a fact-check-stage property, not
  something the critics or Stage 2.5 added on top — the mandatory-execution + scope-line rules
  do their diagnostic work even before a critic ever reads the claims.

## (a) Per-instance table

| Instance | Commit | Caught / findable | Notable catches | Notable misses |
|---|---|---|---|---|
| **csp** | d90d6bb | **5/10** (3 firm) | csp-R2 Node-runtime comment; csp-A2 Tailwind misattribution; csp-A3 `await headers()` misattribution — all clean comment-accuracy catches. csp-A1 (dead x-nonce) and N1 (prefetch bypass) credited via same-mechanism evidence surfaced incidentally, not asserted as the ledger's own framing. | **csp-R1** (`exportGraph.ts` is outside this report's diffed scope entirely — structural miss, not a reasoning failure); csp-A4 (untested directive list); C1 (dev unsafe-eval); C4 (matcher prefix semantics); N15 (img-src markdown) |
| **lean** | c95c9cb | **3/7** | lean-R1 (8 claims, docs staleness); lean-R2 (HTTP-error-masking, explicitly flagged as an incomplete-cause-list issue); N3 (localhost:3100 default removal, executed) | lean-A1 (near-miss — the report's own scope notes gesture at the reason/detail collapse but never assert it as a finding); N4/N5/N8 (all in files outside this report's 10-file diff scope) |
| **hygiene** | f2f149b | **2/3** | hyg-R1 SSE `{error,details}` drift (Stale verdict); hyg-A1 logging asymmetry (Mostly Accurate) | N14 (cache poisoning/never-evict — `cache.ts` is never referenced by any claim in the report at all) |
| **secdeps** | 8bde50c | **3/5** (2 firm) | sec-R1 warn-not-fail-loud (executed, exit code confirmed); N2 audit-gate-fails-green (executed, exit 1 confirmed — correctly NOT certified passing). sec-A1 (trust AST-selector gap) credited generously — only 1 of 3 bypass variants demonstrated. | C2 (require/dynamic-import bypass — not tested at all, independently confirmed real); N9 (.cjs unscoped-config crash — not tested at all, independently confirmed real) |
| **deploy** | 4329d6e | **3/3** | dep-R1 (CLAUDE.md `/tmp` claim, executed trace to `<cwd>/data`); **N10 correctly refused to attest** the unset-URL-means-mock claim, executed ×1 trace of the real fallback/catch-block behavior — avoids the historical trap cleanly. dep-R2 credited via the same evidence, diffusely (not explicitly tied back to the README's wrong-mechanism framing). | — (clean sweep) |
| **fscompat** | b64c1ca | **2/6** (1 firm) | fsc-R1 (phantom README section, grep-proved both replicates). fsc-A4 credited only via an inference-only scope note (no test file for `dataDir`). | fsc-A1 (docstring omission), fsc-A2 (convention inconsistency), fsc-A3 (Vercel hit-rate collapse) all missed — the report never leaves its literal diff scope (`callLlm.ts`/`streamLlm.ts` call sites) to find them. **D6 is a confirmed false attestation**, not just a miss (see below). |
| **corpus** | 2dc403e | **6/11** (4 firm) | cor-A3/cor-A4 (stale comment + docstring drift, firm); C3 (optional-chaining question, firm); D4 (false ArrayBuffer comment, executed, firm). N12/N13 credited only as "escalate to critics" side-notes rather than primary findings. | cor-A1 (naming split — never addressed); cor-A2 (choke-point bypass — explicitly disclaimed as out of scope); N11 (no NODE_ENV gate — gestured at, not asserted); D3 (migrateFromV2 bypass — not addressed); D5 (OPFS write race — not addressed, no concurrency reasoning attempted) |
| **postfix** | 7f30210 | **6/9** (5 firm) | pf-R1 (type-seam root, explicit); pf-A1 (fail-open eval default, explicit); pf-A2 (untested default branch, Incorrect verdict); pf-A4 (ambient NODE_ENV in default param, quoted directly); **pf-A5 correctly scoped** — explicitly states what it does/doesn't establish about the OpenAlex payload bound, avoiding the historical false-attestation trap. pf-A3 credited generously (framed as a testing convenience, not flagged as a security smell). | pf-A6 (array-presence-only guard — not discussed); pf-A7 (connect-src docstring omission — cross-file, out of diffed scope); pf-A8 (stale parity comment — report verifies it's *true*, never notices it's *stale residue* relative to a sibling edit) |

**Column sums:** caught 5+3+2+3+3+2+6+6 = **30**; findable 10+7+3+5+3+6+11+9 = **54**.

## (b) Overall recall — 30/54 = 56% (primary), ~23-24/54 = 43-44% (firm floor)

Primary figure counts every same-mechanism credit the scoring agents allowed, including several
they themselves flagged as generous (csp-A1/N1, secdeps sec-A1, corpus N12/N13, fscompat fsc-A4,
postfix pf-A3 — 6 credits total). Excluding those six generous/partial credits gives a firm floor
of **24/54 ≈ 44%** (30 − 6 = 24).

## (c) Comparison to the full E8 pipeline and other arms

| Process | Findable | Found | Recall |
|---|---|---|---|
| **E9 — fact-check stage alone** (this scoring) | 54 | 30 (24 firm) | **56% (44% firm)** |
| **E8 — full pipeline** (fact-check + all critics + rubric synthesis) | 54 | 47 | **87%** |
| E7 fable reps 1–3 union (different arm entirely, headless multi-rep) | 54 | 42 firm | 78% firm |
| E5 built-in `/code-review` | 54 | 23 firm | 43% firm |
| E4 opus-k3 union | 54 | 20 firm | 37% firm |

Fact-check alone, run once (k=2 merged) inside E8, lands in the same recall band as E5's and E4's
*full* pipelines — i.e. one stage of E8 alone is roughly as effective as some entire competing
arms. But it captures only ~64% of what E8's full pipeline catches (30/47); the critics
(security/performance/architecture/api-consistency/tech-debt/UI-visual) and the provenance-ruled
rubric synthesis are responsible for the other 17 rows and for most of the 31-point gap to 87%.

## (d) What fact-check alone is and isn't good at

**Strong at** (near-100% within its own scope): comment/docstring accuracy vs. actual code
behavior (csp-R2/A2/A3, lean-R1, hyg-R1, dep-R1), and refusing to certify unsafe-looking claims as
safe under the mandatory-execution rule (deploy-N10, postfix-pf-A5 — both historically diagnostic
false-attestation traps, both avoided cleanly by fact-check alone, with no critic or Stage 2.5
involvement needed).

**Structurally blind to:**
1. **Anything outside the literal diffed files/claims.** csp-R1 (`exportGraph.ts`), lean-N4/N5/N8
   (formalizeNode/decomposition/workspaceStore), hygiene-N14 (`cache.ts`), postfix-A7
   (`gitWorker.ts`) — none of these files were in any claim the report checked, because the diff
   scope or the commit-message claims never mentioned them. This is a scoping property of
   fact-check (it verifies *stated* claims), not a reasoning failure.
2. **Absence-type findings** (missing tests, missing directives, missing gates) — csp-A4, C1, C4,
   secdeps-C2/N9, corpus-N11, postfix-A6 — these require adversarially constructing a case the
   claim never asserted, which is closer to a critic's mandate (especially security-reviewer) than
   fact-check's verify-the-stated-claim mandate.
3. **Cross-file / architectural reasoning** — corpus-A1 (naming split across two files), corpus-A2
   (choke-point bypass), corpus-D3 (flag-bypass reachability) — all explicitly disclaimed as
   out-of-scope by the report's own claims rather than missed through error.
4. **Concurrency/dynamic-behavior reasoning without an explicit claim to verify** — corpus-D5 (OPFS
   write race) was never raised because no claim in the diff asserted anything about write
   ordering; the write-race classes elsewhere in the ledger (D3, D5 corpus; sc-writerace-probe
   evidence in the full E8 run) were caught by the full pipeline's Stage 2.5 endorsement-routing
   loop reacting to a *critic's* submitted claim — a mechanism fact-check-only doesn't have access
   to in isolation.

## (e) The one false attestation (fscompat D6)

Fact-check-only's single confirmed false attestation: Claim 5 in the fscompat report asserts the
on-disk cache file "stores exactly `{ text, usage }`," verified against a hand-built test object
passed directly to `setCachedResult`. The real production call site (`callLlm.ts`'s
`recordAndCache`) builds `{ text, usage, cacheKey }` and passes that whole object through — since
it isn't an object literal at the call site, TypeScript's structural typing doesn't strip the
extra field, and `JSON.stringify` serializes `cacheKey` (which embeds the full prompt) into the
cache file. This is exactly ledger row D6's mechanism. The report's test replicated the function's
*signature* but not its real call site, and its "stores exactly" verdict is an overclaim rather
than a hedge — the discipline that saved N10 and pf-A5 (explicit scope-narrowing to what was
actually tested) was not applied here.

## Caveats

- This is a re-score of already-generated artifacts, not a new run — no new fact-check execution
  occurred, so no new cost/token figures exist. The relevant comparison is recall-per-artifact, not
  cost.
- 8 independent scoring agents, no cross-cell consistency pass. Several per-cell "generous credit"
  judgment calls are called out explicitly in the per-instance notes and factored into the firm
  floor; a stricter/looser adjudicator could move any given cell by ±1.
- Ledger CSV/MD were not updated with a new "E9 raised" column — this is a diagnostic re-scoring of
  a subset of an existing arm's output, not a new arm entry, so it's recorded here and referenced
  from the ledger's revision history rather than given a full per-row column. Happy to add one if
  useful for future comparisons.
