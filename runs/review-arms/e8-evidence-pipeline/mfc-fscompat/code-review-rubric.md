# Code Review Rubric

**Commit:** b64c1ca
**Scope:** `d86d2dc..b64c1ca` — `app/lib/utils/dataDir.ts` (new), `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts` (Vercel filesystem-compat: `dataDir()` routes persistence to `/tmp` under `VERCEL`) | **Reviewed:** 2026-08-18 | **Status: 🟡 CONDITIONAL PASS** — 5 amber item(s) awaiting resolution or justification

Fact-check: k=2 merged (1 Incorrect, 2 Mostly accurate, 14 Verified, 5 Unverifiable Vercel-platform claims). Stage 2.5: 4 submitted claims, all Verified (2 executed, 1 static, 1 resting on merged executed claims). Critics: security, performance, api-consistency (core) + test-strategy (contextual, advisory).

**Evidentiary limit (applies to A1–A3):** the Vercel-platform consequences (`/tmp` non-persistence across cold starts, per-instance filesystem, read-only bundle, world-readable exposure on the real platform) are **Unverifiable-in-sandbox** — fact-check Claims 1b, 8a, 8b, 11, 14b, all blocked on "no Vercel deployment/platform access from the review sandbox." The **mechanisms** these findings name are real and locally established; only their production magnitude cannot be closed by execution. Findings are surfaced at critic-native severity with the limit explicit, not inflated to 🔴 on unverifiable platform consequence, and not dropped (mechanism floor).

---

## 🔴 Must Fix

None.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| — | No red items. | — | — | — | — | — | — |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | LLM response bodies (`{text,usage}`, where `text` derives from user source) and `analytics.jsonl` are relocated to `/tmp` under `VERCEL` and land at mode **0644** (world-readable, probe-confirmed). Concrete reachable mechanism: a self-hosted deployment that sets `VERCEL` on a shared multi-user host lets any local user `cat /tmp/cache/*.json` and `/tmp/analytics.jsonl`; on genuine single-tenant Vercel the cross-tenant read is not reachable — that platform half is Unverifiable-in-sandbox. Mechanism (0644 in shared `/tmp`) is concrete → severity holds at Medium. | Security | Medium | Security | for-author | — | 🟡 Open | — |
| A2 | LLM cache hit-rate collapses across Vercel Function instances: `/tmp` is per-instance and warm-container-lived, so each instance builds/reads its own `/tmp/cache`; repeats landing on another instance (~1/M hit) and every cold start re-bill provider completions a single durable disk would have served free. Direction (hit rate falls, spend rises vs. pre-Vercel `data/cache`) is structural; magnitude needs a deployed-instance baseline (Unverifiable-in-sandbox, platform Claims 1b/8/14b). | Performance | High | Performance | for-author | — | 🟡 Open | — |
| A3 | Analytics log diverges per instance and is lost on cold start: `appendAnalyticsEntry` writes to the serving instance's `/tmp/analytics.jsonl`, `readAnalyticsEntries` reads only the local file — so writes fan out incompletely, a read from a different instance returns a partial/empty history, and cold starts silently drop the log. Feature quietly under-counts in production. Durability half Unverifiable-in-sandbox (Claim 1b); routing half executed-Verified (Claim 1a). | Performance | Medium | Performance | for-author | — | 🟡 Open | — |
| A4 | Analytics `DELETE`/`GET` route (`route.ts:4-12`, downstream of `persist.ts:37-40`) calls `clearAnalyticsEntries()`/`readAnalyticsEntries()` with no try/catch — the one persistence path fact-check flags as **not** swallowed (Claim 12, Mostly accurate). A filesystem failure surfaces as a framework 500 instead of the `{error}` envelope every sibling route returns; this diff moves the target to the more-failure-prone `/tmp`, raising the odds the divergent path is hit. | API Consistency | Inconsistent | API-consistency + Security (Low, F3) + Fact-check (Claim 12) `Convergence: api-consistency + security + fact-check` | for-author | — | 🟡 Open | — |
| A5 | Comment `see Deploy to Vercel in README` (`persist.ts:6-7`) points to a section that does not exist — both fact-check replicates grep-proved zero "Deploy to Vercel"/Vercel/deployment mentions in README or any doc file (Claim 2, Incorrect high). Code is correct; only a reader is misdirected → doc-only Incorrect maps to 🟡, not 🔴. The `dataDir()` docstring the same comment references carries the real, verified rationale. | Fact-check | Incorrect (high, comment/doc-only) | Fact-check (Claim 2) + API-consistency (Minor, F2) `Convergence: fact-check + api-consistency` | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `computeHash` cache key covers `{model, systemPrompt, userContent, maxTokens}` but omits `responseFormat` (`callLlm.ts:140`) — two requests differing only in output schema collide on one cache file, so a response built under one schema can be served to a request expecting another. Content/format confusion, not data exposure. Pre-existing (diff only moved `CACHE_DIR`). | Security (Low) | Low | for-author | — | 🟢 Open |
| C2 | Redundant sha256 recomputation on the get path: caller computes `cacheHash` (`callLlm.ts:121`, comment "compute once, reuse") but `getCachedResult` re-derives the identical hash internally (`cache.ts:40`); only the set path honors the reuse. **Executed-Verified** (submitted Claim 23): a `createHash`-counting probe measured exactly 2 invocations on the get path. `userContent` can be a whole document, but cost is negligible beside the LLM call. Pre-existing. (D6.) | Performance (Low) | Low | for-author | — | 🟢 Open |
| C3 | `DELETE /api/analytics` clears all history with no auth/authz — any client reaching the route can wipe the log. Identical at base d86d2dc (not introduced by this diff); recorded because the changed `persist.ts` is what the route writes through. | Security (Informational) | Informational | for-author | — | 🟢 Open |
| C4 | Neither the analytics append nor `setCachedResult` caps size/count or evicts; routed to Vercel's bounded `/tmp` tmpfs (~512 MB), sustained distinct-prompt traffic could exhaust it and fail writes. On-platform size/reachability Unverifiable-in-sandbox. | Security (Informational) | Informational | for-author | — | 🟢 Open |
| C5 | Two immediate callers of the brand-new `dataDir()` demonstrate two conventions: `cache.ts` uses `dataDir("cache")` (rest-args), `persist.ts` uses `dataDir()` then `join(DATA_DIR, "analytics.jsonl")`. Legitimate reason (`persist.ts` needs bare `DATA_DIR` for `ensureDir()`), but the split is the entire precedent and will propagate. Floored at Informational (no prior precedent). | API-consistency (Informational) | Informational | for-author | — | 🟢 Open |
| C6 | **Deploy-critical negative-write invariant untested (G5 / fsc-A4, highest-ranked test gap):** no committed test asserts that with `VERCEL` set a real analytics/cache write lands under `/tmp` **and creates nothing under `<cwd>/data`** — an inverted ternary, dropped branch, or future env-var change would pass a string-equality-only test yet break production silently. Fact-check exercised this only with throwaway scratch tests (deleted); at HEAD the changed behavior has zero committed coverage. Advisory (contextual critic). | Test-strategy (advisory) | — | for-author | — | 🟢 Open |
| C7 | Broader test gaps G1–G13: pure `dataDir()` branch-resolution unit (G1–G4, G6, incl. `VERCEL=""` truthiness edge), cache round-trip + usage override + `dirEnsured` memoization + `removeCachedResult` (G7–G10), analytics append/read + malformed-line tolerance (G11–G13). All require the `vi.resetModules()` + dynamic-import pattern because `DATA_DIR`/`CACHE_DIR` freeze at module load. Advisory. | Test-strategy (advisory) | — | for-author | — | 🟢 Open |
| C8 | Commit-message claim "Lint clean" (b64c1ca) is Mostly accurate — `npm run lint` exits 0 with zero errors but emits 2 pre-existing `react-hooks/exhaustive-deps` warnings in `app/page.tsx` (outside this diff). "No new lint problems" would be precise. Commit-message text is not editable; no code action. | Fact-check (Claim 18) | Mostly accurate | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| `dataDir()` extraction is behavior-preserving: `DATA_DIR` and `CACHE_DIR` resolve to identical strings in **both** env states (`/tmp`,`/tmp/cache`,`<cwd>/data`,`<cwd>/data/cache`) as the parent commit's inline ternary. | ✅ Confirmed | `dataDir.ts:13-14` — `const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");` — FC Claim 17 (executed; scratch tests asserted all four resolved values under both env states, identical in all four) | Fact-check | for-orchestrator-synthesis |
| Local (non-Vercel) behavior unchanged: with `VERCEL` unset the new code resolves to the base commit's `data/` paths and adds no new local write location; full suite 221/221 passed. | ✅ Confirmed | `dataDir.ts:12-15` — FC Claim 15 (executed) + FC submitted Claim 22 (executed; scope covers the four resolved values vs. parent 2136fd6) | Fact-check / Security endorsement | for-orchestrator-synthesis |
| Cache-hit usage override is correct: on-disk file stores the **original** `{text, usage}`, and `getCachedResult` returns `provider:"cache"`, `costUsd:0`, `latencyMs:0` with untouched fields (`inputTokens:10`) passed through and `cacheHash` = the sha256. | ✅ Confirmed | `cache.ts:44-53` — FC Claim 5 (executed; scratch test wrote via `setCachedResult` and verified file contents + return) | Fact-check | for-orchestrator-synthesis |
| Corrupt or missing cache file is treated as an ordinary miss — `getCachedResult` returns `null`, no crash. | ✅ Confirmed | `cache.ts:56-59` — `} catch { /* Corrupt or missing cache file — treat as miss */ return null; }` — FC Claim 6 (executed; corrupt-JSON and never-written cases both returned null) | Fact-check | for-orchestrator-synthesis |
| A newline inside an analytics entry field cannot forge an extra JSONL record: `appendAnalyticsEntry` writes `JSON.stringify(entry) + "\n"` (escaping embedded newlines to `\n`) and `readAnalyticsEntries` splits on `"\n"`, so one entry = one physical line. | ✅ Confirmed | `persist.ts:17-20,22-35` — FC submitted Claim 21 (executed; probe on `{endpoint:"a\nb\nfake-record"}` yielded exactly 1 non-empty line). Scope: does not establish whether any field is attacker-controlled. | Fact-check / Security endorsement | for-orchestrator-synthesis |
| No path traversal via cache filename **on the get/remove paths**: `computeHash` returns a bare `[0-9a-f]{64}` sha256 digest and both `getCachedResult`/`removeCachedResult` build `join(CACHE_DIR, `${hash}.json`)` from it, so the last segment is hex + `.json` and the join stays within `CACHE_DIR`. | ✅ Confirmed | `cache.ts:22-24,40-41,77-78` — FC submitted Claim 20 (static; scope covers get/remove paths, **excludes** `setCachedResult`'s caller-supplied `hash` — noted, not certified) | Fact-check / Security endorsement | for-orchestrator-synthesis |
| Zero new dependencies: the diff touches only the three source files; the new module imports only `path`. | ✅ Confirmed | `git diff --stat d86d2dc...HEAD` (no `package.json`/lockfile change) + `dataDir.ts:1` `import { join } from "path";` — FC Claim 13 (static; scope covers the manifest across the range) | Fact-check / Performance endorsement | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

To pass review: all 🔴 items resolved (none). All 🟡 items either fixed or carrying an author note. 🟢 items optional.
