# Code Review Rubric

**Commit:** 4329d6e
**Scope:** `d86d2dc..4329d6e` — docs-only diff: `CLAUDE.md` (new Deployment section), `README.md` (Deploy-with-Vercel button + section, Lean Verification Service edits) | **Reviewed:** 2026-08-18 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) unresolved

**Inputs:** merged Stage-1 fact-check (k=2, 25 claims, 1 Incorrect at high confidence/executed — Fact-Check Gate applied; run continued per run design), Stage-2.5 submitted-claims report (4 claims, 4 Verified — 3 executed, 1 static with covering Scope), security-review (1H/1M/1L), performance-review (1H/2M/1L/1I), api-consistency-review (1 Breaking/2 Inconsistent/3 Minor/1 Info).

**Docs-only severity note:** this diff ships no code, but the docs are the consumer-facing deploy contract. Doc findings are tiered per the Unified Severity Mapping's native columns (api-consistency `Breaking` in doc-contract terms → 🔴; fact-check doc-only Incorrect alone would be 🟡 under decision 031, but this diff's Incorrect claim documents a fallback contract that CLAUDE.md consumers — coding agents and deployers — bind to, and api-consistency independently graded it Breaking, which is the mapping's own 🔴 route for that class).

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | CLAUDE.md documents a fallback mechanism the route does not have: "when `LEAN_VERIFIER_URL` is unset **or** unreachable → mock `{valid:true, mock:true}`". Executed refutation ×2 (FC Claim 4a, Incorrect/high/executed): unset substitutes default `http://localhost:3100` and makes a **real** request (`route.ts:3-4`); mock fires only when the fetch throws (`route.ts:37-40`). In the documented dev setup the default port is exactly where the real verifier runs, so the claim is wrong precisely where a CLAUDE.md consumer relies on it — and it contradicts README:88 (correct form) inside the very sync pair the diff itself mandates. Fix: adopt README:88 phrasing in CLAUDE.md:76; drop "unset or". Convergence: api-consistency (Breaking) + fact-check (Incorrect, executed) + security (Low, B3) + performance (Informational, dev cost-expectation gap) — 4 sources, executed corroboration. | API Consistency + Fact-check | Breaking / Incorrect (high confidence, executed) | `CLAUDE.md:76` | for-author | No override log in run scope — none matched | 🔴 Unresolved |
| R2 | Deploy button + "self-hosted single-tenant … one trust boundary per deployment" framing invites a public, **unauthenticated** instance holding the deployer's paid API key. No `/api/*` route performs any auth check (grep: zero non-test `auth`/`Authorization`/token hits across `app/api` and `verifier/server.ts`); anyone with the URL can drive billed Anthropic/OpenRouter calls or the `/verify` build endpoint on the deployer's dime. The docs never warn the instance is world-reachable, and the "one trust boundary" language implies isolation the code does not provide. Fix is documentation: explicit public/unauthenticated warning + mitigation guidance (Vercel access control, proxy auth, key spend caps); drop or reword the single-tenant framing. | Security | High | `README.md:5`, `README.md:98-120`, `CLAUDE.md:71-77` | for-author | No override log in run scope — none matched | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | LLM cache is silently inoperative in the documented Vercel target: cache writes to `<cwd>/data/cache` (executed, FC Claim 6), not `/tmp`; under the diff's own platform claim every `setCachedResult` fails and is swallowed (`callLlm.ts:94`), so every repeated prompt is re-billed (~$0.022 output-side per repeated lean call at the repo's own baseline) with no log signal. The docs say "best-effort persistence" but never the billing/latency consequence. Convergence: performance + api-consistency A6 (same persistence surface). Escalation withheld: the executed evidence covers the dev-side write target only; the on-Vercel consequence rests on FC Claim 7 (Unverifiable), so no corroborated basis for 🔴. | Performance | High | Performance #1 (`app/lib/llm/cache.ts:6`, `callLlm.ts:92-96`, `CLAUDE.md:77`); convergence: api-consistency #3 | for-author | — | 🟡 Open | — |
| A2 | Docs newly recommend hosting the Lean verifier on a public provider; `POST /verify` has no auth and shells out to `lake build` (30 s timeout) on caller-supplied source — a public compute/DoS surface whose `MAX_QUEUE_LENGTH = 3` makes 503-ing legitimate users easy. Docs should warn the verifier is unauthenticated and needs network controls / shared secret / private networking. | Security | Medium | Security #2 (`README.md:115`, `verifier/server.ts:86-118,129-158`) | for-author | — | 🟡 Open | — |
| A3 | Analytics log: unbounded append (one line per LLM call, only user-initiated truncation), full-file read+`JSON.parse` per `GET /api/analytics`, synchronous `appendFileSync` on the LLM hot path — degrades linearly with lifetime use, worst exactly in the "dev-only" environment the diff scopes it to. Cap/rotate, add `?limit=`, or at minimum name the unbounded-growth caveat next to "dev-only". | Performance | Medium | Performance #2 (`app/lib/analytics/persist.ts:14-32`, `app/api/analytics/route.ts:4-7`, `README.md:120`) | for-author | — | 🟡 Open | — |
| A4 | The recommended remote-verifier setup routes each verify through a Vercel Function with a 35 s in-route timeout; if the plan's max function duration is below 35 s the platform kills the invocation before the route's own catch→mock fires, and the docs' "Limitations on Vercel" section never mentions this slow-verifier case — the very configuration it recommends. Add one line: check plan duration limit vs verifier worst-case build, and what a timed-out verify looks like. Requires a deployed data point to fully resolve. | Performance | Medium | Performance #3 (`app/api/verification/lean/route.ts:5`, `leanRetryLoop.ts:3,41-78`, `README.md:115,119`) | for-author | — | 🟡 Open | — |
| A5 | "Required" env var is not required: with no keys the app silently degrades to the mock LLM provider (FC Claim 1b caveat), yet the deploy contract discloses the analogous verifier-mock fallback in detail while this one appears nowhere — a keyless/mistyped-key deployment appears to work while returning mock content. Disclose the LLM mock fallback in the required-variable row or Limitations, or enforce the key at the deploy boundary. | API Consistency | Inconsistent | api-consistency #2 (`README.md:102-106,117-120`) | for-author | — | 🟡 Open | — |
| A6 | CLAUDE.md:77's `/tmp` persistence note mismatches where the code writes (`<cwd>/data`, executed — FC Claims 6/18a) and understates the failure shape: on the claimed read-only fs the writes *fail* (swallowed in the LLM paths, but unguarded in `DELETE /api/analytics` → 500), rather than persisting briefly in `/tmp`. Consumers get the wrong mental model of the failure mode. Convergence with A1 (same persistence surface). | API Consistency | Inconsistent | api-consistency #3 (`CLAUDE.md:77`, `persist.ts:5-6`, `cache.ts:6`, `app/api/analytics/route.ts:9-12`) | for-author | — | 🟡 Open | — |
| A7 | README's "when unset → mock-valid" (README:115) and "runs only when `LEAN_VERIFIER_URL` points at a … verifier" (README:119) are Vercel-context shorthands stated as general route semantics — executed evidence shows unset-plus-reachable-default runs *real* verification (FC Claims 16c, 17, both Mostly accurate; r2 E2). Adopt the fact-check's tightened phrasings ("unreachable on Vercel", "on Vercel, … only when"). README-side echo of R1, one notch milder. Convergence: fact-check + api-consistency. | Fact-check + API Consistency | Mostly Accurate / Minor | FC Claims 16c + 17; api-consistency #4 (`README.md:115,119`) | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings and improvement opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Documented fallback contract presents a binary real/mock outcome, but the route has a third response class: non-OK verifier responses are forwarded verbatim with status (`route.ts:32-34` — explicitly outside FC Claims 4b/12 scope), and missing `leanCode` returns 400 `{error}` in a different envelope shape. Add one clause to README:88. | api-consistency #5 (`README.md:64,88`) | Minor | for-author | — | 🟢 Open |
| C2 | Deploy button's `project-name`/`repository-name` (`metaformalism-copilot`) drop the hyphens of the source slug `meta-formalism-copilot` — two spellings of the project identifier inside one URL; cloned users' repos won't match upstream. | api-consistency #6 (`README.md:5`) | Minor | for-author | — | 🟢 Open |
| C3 | Env-var tables become the config schema of record but omit the app-read `SIMULATE_STREAM_FROM_CACHE` (`streamLlm.ts:105`); document it in CLAUDE.md or explicitly scope the tables as deploy-only. | api-consistency #7 (`README.md:108-115`) | Informational | for-author | — | 🟢 Open |
| C4 | On a read-only fs, `ensureCacheDir` never latches, so every LLM call re-attempts `mkdir`+`writeFile` and swallows two exceptions plus a guaranteed-miss `readFile` — cheap but invisible. Logging the first persistence failure once per instance would also serve A1. | performance #4 (`app/lib/llm/cache.ts:26-31,61-68`) | Low | for-author | — | 🟢 Open |
| C5 | Six doc claims are Unverifiable platform/external facts (FC 1a no-shared-instance; 3b/16b verifier-can't-run-on-Vercel; 7 `/tmp`-only fs; 14 clone flow; 18b cross-invocation non-persistence). Statically plausible, but they anchor A1/A4/A6 and could only be confirmed from a deployed instance — flag as "verify on first real deployment". | Fact-check (Unverifiable ×6) | Unverifiable | for-author | — | 🟢 Open |
| C6 | Two executable-guarantee claims blocked by missing Docker in both replicate sandboxes (FC 9a real-Lean type-checking; 11 curl examples' expected outputs). Static reading supports both; pending an environment with Docker. | Fact-check (Unverifiable ×2) | Unverifiable | for-author | — | 🟢 Open |
| C7 | Pre-existing, out of diff scope, cheap to sweep in the same pass: CLAUDE.md Prerequisites says Node v18+ while README says Node 20+. | api-consistency (overall assessment) | Informational | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No override log is present in this run's scope (`docs/reviews/override-log.md` unavailable to this synthesis-only stage). No prior overrides matched this diff.

---

## ✅ Confirmed Good

Every row cites its backing verdict per provenance rule 5; rows are narrowed to what each verdict's `Scope:` line actually establishes.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The silent-pass fail-open is disclosed, not hidden, and the disclosure is accurate **for the unreachable-verifier case**: README:64 / CLAUDE.md:76 state generated Lean code is reported valid without type-checking; executed ×2 — unreachable URL → `{"valid":true,"mock":true}` (`route.ts:37-40`; evidence `r2-e3-set-unreachable.txt`, `r1-vitest-lean-route.txt`). Scoped to `verifyLean` + `useFormalizationPipeline` handling — not every status-display panel; and only the *unreachable* half — the *unset* half of CLAUDE.md:76 is R1's refuted claim. | ✅ Confirmed | Stage-2.5 Claim 19 (executed) — `README.md:64`, `CLAUDE.md:76`, `app/api/verification/lean/route.ts:37-40`; underpinned by FC Claims 4b/9b/5 (executed) | security-reviewer endorsement → fact-check Verified | for-orchestrator-synthesis |
| The OpenRouter privacy disclosure is present and accurate: README:114's note that prompts (including source material) go to OpenRouter matches provider-selection order and outbound body (`callLlm.ts:170-175`); executed — fake OpenRouter key produced a real outbound request 401'd by openrouter.ai (`r2-e7-openrouter-fallback-path.txt`). Does **not** establish OpenRouter's server-side data handling. | ✅ Confirmed | Stage-2.5 Claim 20 (executed) — `README.md:114`, `app/lib/llm/callLlm.ts:162-177`; underpinned by FC Claim 15 (executed ×2) | security-reviewer endorsement → fact-check Verified | for-orchestrator-synthesis |
| In this codebase, API keys are read only from server-side env (`callLlm.ts:112-113`, `streamLlm.ts:87-88`) and no in-browser key-entry path exists (enumeration: `grep -rn -i "apiKey\|API_KEY" app/components/ app/hooks/` → zero non-test hits). Does **not** establish any particular deployment's env configuration, nor that no route's error body echoes key-adjacent data. | ✅ Confirmed | Stage-2.5 Claim 21 (static; Scope covers row as narrowed) — `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/streamLlm.ts:87-88`; concurs with FC Claim 2 (static, Verified) | security-reviewer endorsement → fact-check Verified | for-orchestrator-synthesis |
| Anthropic SDK client is constructed at most once **per warm module instance** and reused across `callLlm`/`streamLlm` (lazy singleton, `callLlm.ts:10-17`; executed probe: 3 `callLlm` + 2 `streamLlm` calls → construction count 1; no other construction site in `app/`). Does **not** cover separate serverless instances, separately-bundled module copies, or runtime key rotation (singleton ignores later `apiKey` args). | ✅ Confirmed | Stage-2.5 Claim 22 (executed) — `app/lib/llm/callLlm.ts:10-17`, evidence `sc-client-reuse-probe.txt` | performance-reviewer endorsement → fact-check Verified | for-orchestrator-synthesis |
| Deploy button integrity: the referenced GitHub repo resolves (HTTP 200, both replicates), the `env=ANTHROPIC_API_KEY` parameter names exactly the key the code reads, and the `envLink` anchor `#deploy-to-vercel` matches the README:98 heading. Does **not** establish that the GitHub repo's contents match this clone or that Vercel's clone flow succeeds end-to-end (Claim 14 Unverifiable → C5). | ✅ Confirmed | FC Claim 8 (executed) — `README.md:5`, `README.md:98`, evidence `r1-github-repo-head.txt`, `r2-e8-github-repo-exists.txt` | fact-check (Stage 1) | for-orchestrator-synthesis |
| README:88 and README:96 state the fallback mechanism correctly — env read, default `localhost:3100`, mock only on unreachable — and the app stays functional with no verifier (executed ×2 in both directions: reachable default → real response; unreachable → mock; keyless server stayed up and formalization API answered). API-layer only — full UI-level generation flows not exercised. | ✅ Confirmed | FC Claims 12 + 13 (executed) — `app/api/verification/lean/route.ts:3-4,37-40`, `leanRetryLoop.ts:63-73`, evidence `r2-e4-set-stub3101.txt`, `r1-mock-llm-and-analytics.txt` | fact-check (Stage 1); echoed by api-consistency "What Looks Good" | for-orchestrator-synthesis |

Confirmed-Good cross-check: performed against the merged report and Stage-2.5 scopes. The one candidate contradiction — CLAUDE.md:76's refuted *unset* half vs the silent-pass disclosure row — is resolved by scope narrowing (row 1 asserts only the unreachable case, which the Stage-2.5 report itself carves out); no ✅ row conflicts with any recorded observation. The performance-reviewer's two `[read:]`-tagged endorsements (cache-key hashing; cache-hit analytics rewrite) were **not** routed to fact-check and are not promoted here — they remain scoped prose in that report, per provenance rule 5.

---

## ⚠️ Unverified Findings

All findings' evidence resolved — accepted from the Stage-1/2/2.5 reports, whose citations carry verbatim quotes and executed-evidence artifacts under `evidence/`; independent repo re-reads are out of scope for this synthesis-only stage per run design.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.

Recommended next action (derivation: 2 🔴 in 2 domains, diff <500 lines → rule 4): fix red items then re-review.
