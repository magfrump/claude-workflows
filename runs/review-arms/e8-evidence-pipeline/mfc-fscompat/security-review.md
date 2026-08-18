# Security Review — mfc-fscompat (Vercel filesystem-compat routing)

**Commit:** b64c1ca
**Scope:** `git diff d86d2dc...HEAD` — `app/lib/utils/dataDir.ts` (new), `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`
**Date:** 2026-08-17
**Based on:** `runs/review-arms/e8-evidence-pipeline/mfc-fscompat/code-fact-check-report.md` (k=2 merged, HEAD b64c1ca)

No escalation pattern matched (no plaintext secrets, no injection, no TLS disable, no hardcoded keys, no auth-check *removed* by this diff). Proceeding with the normal review.

## Trust Boundary Map

```
B1 (new): user source text (userContent) → LLM call → response `text` persisted to /tmp/cache/<sha256>.json   [persisted data → filesystem → other host users/processes]
B2 (new): analytics entries              → appendFileSync             → /tmp/analytics.jsonl                    [persisted data → filesystem → other host users/processes]
B3:       HTTP client (unauthenticated)  → DELETE /api/analytics      → clearAnalyticsEntries() writeFileSync   [network → route handler → filesystem write]
B4:       {model, systemPrompt, userContent, maxTokens} → computeHash (sha256 hex) → join(CACHE_DIR, `${hash}.json`)  [key tuple → content address → filename]
```

The diff's security-relevant delta is B1/B2: under `VERCEL`, both the LLM cache (response bodies) and the analytics log are relocated from the repo's `data/` dir to `/tmp`. `/tmp` on a typical Linux host is a world-traversable shared directory (sticky bit `1777`), and files land at the process umask (0644 — probe below). B3 and B4 are guardrail-like paths the diff routes through; B3's write target and B4's key are both reached by every changed module.

## Findings

#### LLM response bodies and analytics relocated to world-readable `/tmp` files

**Severity:** Medium
**Location:** `app/lib/utils/dataDir.ts:13`, `app/lib/llm/cache.ts:7,68`, `app/lib/analytics/persist.ts:8,19`
**Boundary:** B1, B2
**Move:** #6 (follow the secrets/sensitive data), #8 (data at rest under multi-tenant conditions)
**Confidence:** Low–Medium

Under `VERCEL`, cache files (`{text, usage}` — where `text` is the model's response derived from user-submitted source material) and `analytics.jsonl` are written to `/tmp/...` with no explicit mode. The probe below confirms Node's `writeFile`/`appendFileSync` produce mode **0644** — world-readable — in `/tmp`. On genuine Vercel the function container is single-tenant per deployment, so a cross-tenant read is not reachable there; the concrete reachable mechanism is (a) a **self-hosted deployment that sets `VERCEL`** on a shared multi-user host, where any other local user can `cat /tmp/cache/*.json` and `/tmp/analytics.jsonl` and read cached LLM outputs, or (b) any co-resident process/dependency inside the same function reading `/tmp`. The pre-diff `data/` path inherited the repo directory's perms; `/tmp` broadens the readership. The mechanism (0644 in shared `/tmp`) is concrete, so severity holds at Medium per the floor rule; the environmental caveat lives in Confidence.

**Recommendation:** Create the cache/analytics dirs and files with restrictive modes (e.g., `mkdir` mode `0700`, `writeFile` mode `0600`), or scope the `/tmp` path per-deployment (e.g., `/tmp/<app-id>/...`). If `VERCEL` is only ever set on real Vercel, document that the branch is not intended for shared self-hosted hosts.

#### Cache key omits `responseFormat` — cross-schema response confusion

**Severity:** Low
**Location:** `app/lib/llm/cache.ts:16-25`; callers `app/lib/llm/callLlm.ts:121,140-147`
**Boundary:** B4
**Move:** #11 (guardrail bypass — key completeness)
**Confidence:** High (that the field is omitted); Low (security impact)

`computeHash` covers `{model, systemPrompt, userContent, maxTokens}` but **not** `responseFormat` (the JSON-schema passed to the model, `callLlm.ts:140`). Two requests identical in the four hashed fields but differing in `responseFormat` collide on the same cache file, so a response generated under one output schema (or none) can be served to a request expecting a different schema. Impact is content/format confusion rather than data exposure. Pre-existing: the key derivation is unchanged by this diff (the diff only moved `CACHE_DIR`); flagged because the task scopes B4 as guardrail-like and move #11 requires the enumeration.

**Recommendation:** Include `responseFormat` (or a stable digest of it) in the `computeHash` tuple so schema-divergent requests key to distinct files.

#### Unguarded write in the analytics DELETE route surfaces filesystem errors

**Severity:** Low
**Location:** `app/api/analytics/route.ts:9-12`, `app/lib/analytics/persist.ts:37-40`
**Boundary:** B3
**Move:** #3 (check the error path)
**Confidence:** Medium

`clearAnalyticsEntries()` calls `writeFileSync` with no `try/catch`, and the `DELETE` handler does not wrap it, so a write failure (EROFS/ENOSPC/EACCES) propagates as an unhandled exception → a 500. This is the one write path the fact-check (Claim 12) flags as *not* swallowed, unlike every other persistence call site. Note the diff's routing change makes the *common* Vercel case succeed (writes now target writable `/tmp` instead of the read-only bundle `data/`), so it reduces the everyday failure; the residual is a fragile error contract (inconsistent with the swallowed paths, and a potential detail leak in non-production Next.js error rendering). Info-disclosure is limited because production Next.js masks stack traces.

**Recommendation:** Wrap the `clearAnalyticsEntries()` call (or the route body) in `try/catch` and return a controlled error response, matching the non-fatal handling used at the other write sites.

#### Unauthenticated analytics DELETE endpoint (pre-existing, out of diff)

**Severity:** Informational
**Location:** `app/api/analytics/route.ts:9-12`
**Boundary:** B3
**Move:** #5 (invert the access-control model)
**Confidence:** High

`DELETE /api/analytics` clears all analytics history with no authentication or authorization check — any client that can reach the route can wipe the log. Identical at base commit d86d2dc, so **not introduced by this diff** and out of primary scope; recorded because the changed `persist.ts` module is what the route writes through. Not escalated for that reason.

**Recommendation:** If analytics history has any integrity value, gate the DELETE (and likely GET) route behind the app's auth boundary.

#### Unbounded cache/analytics growth on Vercel's small `/tmp`

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:17-20`, `app/lib/llm/cache.ts:62-69`
**Boundary:** B1, B2
**Move:** #8 (what if there are a million of these?)
**Confidence:** Low

Neither the append path nor `setCachedResult` caps size or count, and there is no eviction. On a self-hosted disk this is unremarkable, but the diff routes writes to `/tmp`, which on Vercel Functions is a bounded tmpfs (~512 MB). Sustained distinct-prompt traffic could exhaust `/tmp` and start failing writes. Reachability/size on the actual platform is Unverifiable from the sandbox (consistent with fact-check Claims 8/14b).

**Recommendation:** Consider an LRU/size cap or TTL-based eviction for the cache dir if Vercel is a target runtime.

## Move #11 — guardrail bypass enumeration

**B4 — cache-key / filename derivation** (`cache.ts`):
- **Path traversal via the hash → filename** — *Tested.* `computeHash` returns `createHash("sha256").digest("hex")` (`[0-9a-f]{64}`, no separators); `getCachedResult`/`removeCachedResult` build `filePath` from that digest, so `join(CACHE_DIR, ...)` stays within `CACHE_DIR`. No traversal on these paths.
- **`setCachedResult(hash, ...)` accepting an arbitrary string** — *Tested (callers traced).* Both call sites pass `computeHash` output (`callLlm.ts:94`←`121`; `streamLlm.ts:64`←`95`), all hex. No user-controlled string reaches the `hash` param today. Latent hazard: the signature trusts its caller — a future caller passing untrusted input is one hop from a traversal write. Noted, not a current finding.
- **sha256 collision / cross-user cache hit** — *Tested (by construction).* A hit requires a byte-identical key tuple → sha256 preimage/collision, infeasible; content-addressing across users is the intended semantics, not a bypass.
- **Key omits `responseFormat`** — *Tested (read).* Confirmed omitted → cross-schema content confusion. Elevated to Finding 2.

**B3/B2 — analytics write path** (`persist.ts`, `route.ts`):
- **Unauthenticated DELETE wipes analytics** — *Tested (route read).* Elevated to Finding 4.
- **JSONL log injection via newlines in entry fields** — *Tested.* `appendAnalyticsEntry` writes `JSON.stringify(entry) + "\n"`; `JSON.stringify` escapes embedded newlines/control chars, and `readAnalyticsEntries` splits on `"\n"`, so one entry maps to one line — a field value cannot forge an extra JSONL record.
- **Unbounded growth / `/tmp` exhaustion** — *Tested (read: no cap).* Elevated to Finding 5.

No guardrail carries an *untested* bypass candidate, so there is no "Untested bypass candidates" section. (B4's path-derivation candidates are all traced; the one confirmed gap — `responseFormat` — is reported as a finding, which is why B4 does not appear as a clean Endorsement Claim.)

## Endorsement Claims

- **Claim:** Every cache filename in `cache.ts` is constructed by `join(CACHE_DIR, ...)` over a value from `createHash("sha256").digest("hex")` on the `getCachedResult`/`removeCachedResult` paths, giving a hex-only last path segment on those paths.
  **Location:** `app/lib/llm/cache.ts:22-24,41,78`
  **Evidence:** read-static
  **Verified:** Read `computeHash` (sha256 hex digest) and the two read/remove paths that build `filePath` from it.
  **Not verified:** `setCachedResult`'s `hash` parameter is caller-supplied; the two current callers pass `computeHash` output, but a caller passing untrusted input is one hop away and was not exhaustively traced beyond `callLlm.ts`/`streamLlm.ts`.
  **route: code-fact-check**

- **Claim:** `appendAnalyticsEntry` serializes each entry as `JSON.stringify(entry) + "\n"`, and `readAnalyticsEntries` splits on `"\n"`, so a newline inside an entry field is escaped rather than starting a new JSONL record.
  **Location:** `app/lib/analytics/persist.ts:17-20,22-35`
  **Evidence:** read-static
  **Verified:** Read the append (`JSON.stringify`) and read-back (`split("\n")` + per-line `JSON.parse`) paths.
  **Not verified:** Whether any `AnalyticsEntry` field originates from untrusted user input — the entry objects are assembled by callers (`callLlm.ts`/`streamLlm.ts` record sites) not traced field-by-field here.
  **route: code-fact-check**

- **Claim:** With `VERCEL` unset, `dataDir()` / `dataDir("cache")` resolve to the same paths the pre-diff hardcoded constants used, so the diff adds no new *local* (non-Vercel) write location.
  **Location:** `app/lib/utils/dataDir.ts:12-15`
  **Evidence:** executed (via fact-check Claims 15 & 17, both Verified/executed at HEAD b64c1ca)
  **Verified:** Fact-check executed the four resolved values under both env states and against base d86d2dc; identical strings locally.
  **Not verified:** The `VERCEL`-set destinations are `/tmp` (Finding 1 addresses their exposure); no claim is made about the actual Vercel platform's filesystem behavior (fact-check Claims 8/11/14b Unverifiable).
  **route: code-fact-check**

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Response bodies + analytics in world-readable `/tmp` (0644) | Medium | B1,B2 | `dataDir.ts:13`, `cache.ts:68`, `persist.ts:19` | Low–Medium |
| 2 | Cache key omits `responseFormat` → cross-schema confusion | Low | B4 | `cache.ts:16-25` | High/Low |
| 3 | Unguarded DELETE-route write → unhandled error surface | Low | B3 | `route.ts:9-12` | Medium |
| 4 | Unauthenticated analytics DELETE (pre-existing) | Informational | B3 | `route.ts:9-12` | High |
| 5 | Unbounded `/tmp` growth on Vercel | Informational | B1,B2 | `persist.ts:17`, `cache.ts:62` | Low |

## Overall Assessment

The change is a small, dependency-free path-routing refactor, and its correctness (no local behavior change, identical resolved paths) is executed-verified upstream. Its one genuinely new security surface is data-at-rest: relocating LLM response bodies and the analytics log to `/tmp` widens their file readership to any co-resident host user/process (mode 0644, confirmed by probe) — a Medium concern that matters on shared self-hosted hosts that set `VERCEL`, and is largely mitigated by single-tenant isolation on genuine Vercel. Everything else is fixable in place: the unguarded DELETE write is a one-line `try/catch`, the `responseFormat` key gap is a one-field addition, and the unauthenticated DELETE endpoint is pre-existing and out of this diff. The single most important thing to address is restrictive file modes (0600 / 0700) on the `/tmp` cache and analytics paths. No findings force an architectural rethink; endorsement claims are scoped with their `Not verified` hops named and pending execution verification via code-fact-check.
