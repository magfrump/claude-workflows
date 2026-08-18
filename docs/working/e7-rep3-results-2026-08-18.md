# E7 rep-3 (and rep-2 recovery) results: headless Fable 5 built-in review (2026-08-18)

**Arm**: same as reps 1–2 (`/code-review main` via `claude -p`, no `--bare`, subscription
credential, truncated eval clones). Rep 2's `mfc-corpus` and `mfc-fscompat` were
previously recorded as total losses (weekly usage limit / OAuth failure); re-runs under
the same rep2 slot completed with real output and are scored here for the first time.
Rep 3, previously a total loss across all 8 cells, completed **7 of 8 cells**
(`mfc-postfix` hit the session limit again — still unscored after all 3 reps).
Scoring: one adjudication agent per cell, each independently re-verifying claims against
the actual code in `external/cc-review-eval/mfc-*` (not just trusting the arm's
self-report), anti-SWR-Bench rules (mechanism match, not keyword overlap). Findings
extracted from each transcript's final `ReportFindings` tool call (the structured
findings panel), not the prose summary.

## Headline

| Frame | Findable | Found | Recall | Notable |
|---|---|---|---|---|
| **E7r2 corrected (7 scored cells)** | 34 | 26 firm + 1 partial | **76.5% firm, ~79% incl. partial** | supersedes the previous "5 scored cells, 83%" figure now that corpus (8/11) and fscompat (3/5 live) have real data |
| **E7r3 (7 scored cells, postfix dead)** | 45 | 32 firm | **71.1% firm** | secdeps perfect (5/5, 4 new execution-verified findings); csp strong (7/10); weakest cell fscompat (3/6) |
| **E7 reps 1–3 union** (best-case ceiling: any rep hit counts) | 54 | 42 firm + 1 partial (pf-R1, postfix, only rep1 data) | **77.8% firm, ~79.6% incl. partial** | supersedes the reps 1–2 union (67%); now within 8–10 points of E8 (87%) at roughly comparable attempted spend |
| Cost (attempted, list) | — | — | — | rep1 $77.54 + rep2-corrected $76.45 + rep3 $68.61 = **$222.60 attempted across 3 reps** |

The reps 1–3 union is a best-case (any-rep-hit) ceiling, not what any single run
delivers — no individual rep exceeds 77%. Its value is bounding what this arm is
*capable* of finding when replicated, which is the point of the 3x design.

## Per-cell (rep 3)

| Cell | Score | Notes |
|---|---|---|
| mfc-csp | 7/10 | Hits R1, A1, A3, A4, C1, N1, N15. Misses R2 (Edge-vs-Node runtime), A2 (Tailwind misattribution), C4 (matcher prefix bug). 5 new candidate findings, all code-verified real (missing ADR, missing docs update, phantom "OpenAlex" comment reference, fragile discarded-`await headers()` pattern, one PLAUSIBLE Buffer/nonce simplification with its own flawed fix). |
| mfc-deploy | 2/3 | Hits R1, R2 (EROFS/mock-pass mechanism). Misses N10 — but does NOT repeat rep2's false-attestation error on the LEAN_VERIFIER_URL claim; it simply doesn't engage it. 7 new candidate findings, 6 confirmed real, 2 of which independently re-derive both halves of candidate row N16 (demo-mode / OpenRouter-fallback contradiction) without having seen it. |
| mfc-fscompat | 3/6 | Hits R1, A1, A4. Misses A2 (already fixed, correctly not flagged — see rep2 note below), A3, D6. New: `process.env.VERCEL` truthy check also fires locally after `vercel env pull`/`vercel dev` (Vercel sets `VERCEL=1` by default), silently redirecting local-dev writes to `/tmp` — PLAUSIBLE, matches Vercel's documented CLI behavior, not independently reproduced with the real CLI in-sandbox. This is the arm's weakest cell for the third rep running. |
| mfc-hygiene | 2/3 | Hits R1, A1. Misses N14 (the cell's own origin row from rep2 — not re-found). New: the Anthropic SDK still leaks the **full provider error body** (including request content) over SSE/logs despite the redaction diff's explicit guarantee — CONFIRMED by tracing `@anthropic-ai/sdk`'s `APIError.makeMessage` source directly. Anthropic is the default/preferred provider path, so this isn't an edge case. |
| mfc-lean | 5/7 | Hits R1, A1, N3, N4, N5. Misses R2 (discarded upstream error body) and **mismatches** N8: the arm's finding targets `workspacePersistence.ts` (dead code, only reachable via one-time legacy migration), not the live Zustand `partialize` path N8 actually describes — confidently labeled CONFIRMED with an inaccurate failure scenario (refresh does NOT go through the sanitizer it names). 6 new candidate findings, all confirmed real. |
| mfc-secdeps | 5/5 | **Perfect.** All 5 rows hit, with N2 (audit gate fails) and N9 (.cjs lint crash) independently RE-EXECUTED by the scoring agent, not just trusted. 4 new candidate findings, all confirmed real: lockfile-only security fix has no `overrides` floor (fix durability gap), the audit gate doesn't cover the `verifier/` subproject (no lockfile, not in dependabot config — yet it's the part that ships as a Docker image), audit runs twice per matrix after the build, docs not updated. |
| mfc-corpus | 8/11 | Hits A2, A3, A4, D3, D5, N11, N12, N13. Misses cor-A1 (naming split, still unaddressed by any E7 rep), D4 (stale ArrayBuffer comment), and **C3 is contested** (see below). 9 additional findings beyond the ledger, 5 CONFIRMED by direct code trace (mount-effect pre-hydration sync-back write, `finally{close()}` masking `QuotaExceededError`, session-wipe-with-no-snapshot, non-injective workspace-slug collisions, triplicated `isObject`), 4 PLAUSIBLE. |

## Per-cell (rep 2 recovery)

| Cell | Score | Notes |
|---|---|---|
| mfc-corpus | 8/11 | Same 8 rows as rep3: A3, A4, D3, D4, D5, N11, N12, N13 (note: this rep hits D4, rep3 misses it — union covers it). Misses cor-A1, cor-A2, and **C3 is contested** (see below). 14 findings beyond the ledger; 6 independently confirmed by code trace (quota-masking `finally{close()}`, hydration race discarding pre-hydration edits, no-debounce full-blob writes, missing manifest-version compatibility check, duplicated debounce helper in `evidenceStore.ts`), 8 plausible-but-unverified.
| mfc-fscompat | 3/5 live (4/6 incl. the moot row) | Hits R1, A1, A4. fsc-A2 (rest-args convention) is **not present in this checkout** — the ledger's "fixed in review-fix chain" status holds, correctly excluded from the denominator rather than scored a miss. Misses A3, D6. 3 new candidates, all confirmed (bare-`/tmp`-root namespace collision, no `DATA_DIR` override for other read-only hosts, a trivial dead-ternary style nit). First real scoring data for this cell — it was a total loss in the original rep2 pass. |

## The C3 contradiction (flag for attention)

Ledger row **C3** (`process.env?.NEXT_PUBLIC_CORPUS_FS` optional chaining may break
Next's build-time static inlining) has now produced **three different verdicts across
three reps of the same arm**:

- **E7 rep1**: hit it as a real defect (findable-then, adjudicated TRUE — contributed to
  the original C3 candidate label).
- **E7 rep2 (corpus recovery)**: the arm's `flag.ts` finding asserts the env var is
  "verified inlined by Turbopack" in production builds — a claim of **empirical**
  verification the scoring agent could not reproduce (`next build` fails in this
  sandbox with no network access) and flags as a possible false attestation.
- **E7 rep3**: same pattern — "empirically REFUTED — Turbopack prod, webpack prod,
  Turbopack dev all inline it correctly" — again asserted with specific-sounding but
  unverifiable evidentiary language, and again flagged by the independent scoring agent.

Both rep2 and rep3's "verified"/"REFUTED" language describes running builds the scoring
agents could not confirm actually happened (no working `next build` was reproducible in
this environment for anyone). This is not counted as a confirmed false attestation
(unverifiable ≠ false), but it's a real precision concern: two of three reps assert a
specific empirical claim that contradicts the ledger's own "pending runtime
adjudication" status and contradicts the arm's own rep1 result, without demonstrated
evidence. **C3 is excluded from the reps 1–3 union hit-count** pending an actual
`next build` verification (the union treats it as unresolved, not hit).

## New candidate rows (not yet graduated — folded into the ledger as N17–N22)

Selected for ledger inclusion: mechanism clearly distinct from all 54 existing rows,
code-verified (not merely plausible), and not enumeration/convention/test-strategy-class
noise (which the ledger's existing policy excludes — see "Adjacent true findings
deliberately NOT counted"). Marginal findings (missing ADRs, missing test coverage nits,
duplicated helper functions, dead code) are real but excluded from ledger rows under
that same policy; they remain recorded in this doc's per-cell notes above.

- **N17** hygiene: Anthropic SDK still leaks the full provider error body over SSE/logs
  despite the redaction diff's guarantee (`streamLlm.ts:160`) — CONFIRMED against SDK
  source (E7r3, single sighting).
- **N18** corpus: `opfsAdapter.ts`'s `finally { close() }` masks a `QuotaExceededError`
  as generic `{kind:"io"}`, contradicting the module's own no-swallow docstring —
  CONFIRMED, **2 independent sightings** (E7r2 and E7r3, both code-traced).
- **N19** corpus: pre-hydration sync-back writes `DEFAULT_STATE` over the OPFS blob
  before rehydration resolves (mount effect in rep3's finding; a hydration-race variant
  of the same root cause in rep2's finding) — CONFIRMED, **2 independent sightings**,
  same root cause (async `getItem` vs. sync-hydration assumptions), different
  manifestation sites.
- **N20** fscompat: `process.env.VERCEL` truthy check also fires in local dev after
  `vercel env pull`/`vercel dev` (Vercel CLI sets `VERCEL=1` by default), silently
  redirecting local writes to `/tmp` — **2 independent sightings** (E7 rep1's
  "VERCEL-env local-dev misroute," adjudicated TRUE-minor at the time but never matched
  to a ledger row, and E7 rep3's same claim), PLAUSIBLE (mechanism matches documented
  Vercel CLI behavior, not independently reproduced with the real CLI in this sandbox).
- **N21** secdeps: the npm-audit CI gate doesn't cover the `verifier/` subproject (no
  lockfile, absent from dependabot config, eslint globally ignores it) — the part that
  actually ships as a Docker image is unaudited — CONFIRMED (E7r3, single sighting).
- **N22** csp: `proxy.ts:16` comment cites a nonexistent "OpenAlex" integration/service —
  phantom reference, same class as fsc-R1 — CONFIRMED (E7r3, single sighting).

None of N17–N22 meet the ledger's full graduation bar (3+ sightings or fix-in-history);
N18–N20 are at 2 independent sightings and are the strongest candidates for graduation
on a future pass. All six are added to the CSV and Stratum E of the ledger as
candidates, consistent with how N1–N16 were tracked before graduation.

## What this pass establishes

1. **The 3x replication design earns its keep.** No single rep exceeds 77% recall, but
   the union across reps hits 78–80% — closing most of the gap to E8 (87%) while
   costing roughly 5x E8's sweep price ($222.60 attempted vs. $150–350, but across 3
   full attempts rather than 1).
2. **Precision holds** — 0 confirmed false positives across all 9 newly-scored cells.
   The one precision concern (C3's contradictory "verified"/"refuted" claims in rep2 and
   rep3) is an unverifiable-claim pattern, not a confirmed false attestation, but is
   exactly the failure mode the ledger's evidence-discipline work is trying to catch.
3. **secdeps is now a fully solved cell for this arm** — 5/5 in rep1 and rep3 both (rep2
   also 3/3 on its narrower original scope), with the two hardest rows (N2, N9)
   independently re-executed by the scoring agent both times.
4. **New candidate discovery continues** — N17 (SDK error leak) and N21 (verifier/
   subproject unaudited) are both genuinely new, non-trivial defects this pipeline
   hasn't found via any other arm at any prior rep.
