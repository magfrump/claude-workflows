Commit: b64c1ca

# Security Review — fscompat (dataDir persistence routing, d86d2dc..b64c1ca)

**Scope:** branch diff `d86d2dc..b64c1ca` — `app/lib/utils/dataDir.ts` (new), `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`
**Date:** 2026-08-06
**Based on:** `fscompat/fact-check.md` (5 claims: 3 verified, 1 incorrect [dead README ref], 1 unverifiable [Vercel FS semantics])

No escalation patterns matched. No High/Critical findings.

## Trust Boundary Map

```
B1: [dataDir(...subpaths) args]      → [path.join(base, ...subpaths)]  → [server filesystem path]   (new)
B2: [HTTP GET/DELETE /api/analytics] → [route handler, NO auth check]  → [read/clear analytics.jsonl]
B3: [cache file JSON on disk]        → [JSON.parse(...) as CachedResult] → [LLM cache consumer]
```

B1 is the boundary this diff introduces: a new utility that builds filesystem paths from a variadic argument list. B2 and B3 are pre-existing boundaries the diff re-points at a new base dir (`/tmp` on Vercel) but does not otherwise modify. The diff makes no change to input handling, auth, or deserialization — it only changes *where* trusted, app-internal data is stored.

## Findings

#### New `dataDir(...subpaths)` util has no path-containment contract

**Severity:** Low
**Location:** `app/lib/utils/dataDir.ts:12-15`
**Boundary:** B1
**Move:** #1 (trace trust boundaries), #2 (implicit sanitization assumption)
**Confidence:** High (that it is NOT currently exploitable); Medium (that it is a latent risk worth a guard)

`dataDir` accepts variadic `subpaths` and does `join(base, ...subpaths)`. `path.join` does not confine the result to `base` — a `..` segment escapes it (e.g., `dataDir("../../etc/foo")` resolves outside `data/`). Both current callers pass compile-time literals — `dataDir()` (persist.ts:8) and `dataDir("cache")` (cache.ts:7) — so there is **no exploitable path today**. The finding is about the util's API contract: it is a new, general-purpose helper explicitly documented for reuse ("analytics, LLM cache, etc."), and the natural next caller — one that derives a filename from a request field or artifact ID — would inherit a path-traversal / arbitrary-write primitive with no signal from the util that containment is the caller's responsibility.

**Evidence:**
- `app/lib/utils/dataDir.ts:13-14`: `const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");` / `return subpaths.length > 0 ? join(base, ...subpaths) : base;`

**Recommendation:** Either document that `subpaths` must be trusted/literal (a one-line JSDoc note), or normalize and assert containment (e.g., resolve the result and verify it starts with `base`, throwing otherwise). A guard now is cheap insurance against the future untrusted caller.
**Legibility-target:** the `dataDir` util's input contract (any future caller of this helper).

#### LLM cache read casts parsed JSON without shape validation (pre-existing, base now `/tmp`)

**Severity:** Low
**Location:** `app/lib/llm/cache.ts:44` (read path); base selection at `cache.ts:7` + `dataDir.ts:13`
**Boundary:** B3
**Move:** #7 (serialization boundary)
**Confidence:** Medium

`getCachedResult` does `JSON.parse(await readFile(...)) as CachedResult` with no runtime shape check, then returns `data.text` / `data.usage` to callers. This is pre-existing behavior, not introduced by the diff — I flag it only because the diff re-homes the cache to `/tmp` on Vercel. On Vercel, `/tmp` is scoped to the isolated Function container, so no other tenant can plant a malicious cache file; the trust level of the cache contents is unchanged from the previous `data/cache` location. The residual concern is defense-in-depth: if `VERCEL` were ever truthy on a shared/multi-tenant host (misconfiguration), cache files in a world-writable `/tmp` become an attacker-controllable deserialization input feeding `as CachedResult`. Low likelihood given `VERCEL` is set by the Vercel platform.

**Evidence:**
- `app/lib/llm/cache.ts:44`: `const data = JSON.parse(await readFile(filePath, "utf-8")) as CachedResult;`
- `app/lib/utils/dataDir.ts:13`: `/tmp` branch selected on `process.env.VERCEL`

**Recommendation:** No action required for the Vercel deployment as designed. If cache robustness matters, validate the parsed object's shape (`typeof data.text === "string"`, etc.) before use — the existing `catch` already degrades a parse failure to a cache miss, so validation failure can follow the same path.
**Legibility-target:** the cache read path / the `/tmp` base decision.

#### Analytics endpoint unauthenticated — unchanged by diff, noted for completeness

**Severity:** Informational
**Location:** `app/api/analytics/route.ts:4-12`
**Boundary:** B2
**Move:** #5 (invert access control)
**Confidence:** High

`GET /api/analytics` returns all persisted analytics and `DELETE` clears them, both with no authentication. This is entirely pre-existing and the diff does not touch this file — it only changes the storage location the handlers read/clear. Recorded so the review is explicit that this boundary was examined and found unchanged; it is out of scope for this PR.

**Evidence:**
- `app/api/analytics/route.ts:9-11`: `export async function DELETE() { clearAnalyticsEntries(); return NextResponse.json({ ok: true }); }`

**Recommendation:** Out of scope here; if the analytics history is sensitive, gate these handlers behind the app's auth in a separate change.
**Legibility-target:** the analytics route (future PR).

## What Looks Good

- The `VERCEL` guard (`dataDir.ts:13`) correctly preserves prior off-Vercel behavior — both call sites resolve to the identical `<cwd>/data` path they used before (confirmed against fact-check Claim 3), so the change is behavior-preserving outside Vercel.
- No user-controlled data flows into the new boundary B1: both callers pass static literals, so the variadic surface introduces no *current* injection path.
- The cache key is a SHA-256 hex digest (`cache.ts:22-25`) used as the filename, so cache filenames are inherently containment-safe (`[0-9a-f]{64}`, no traversal characters) even though `dataDir` itself does not enforce that.
- Diff adds no dependencies, no crypto changes, no new network calls, no secrets handling.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `dataDir` variadic subpaths lack containment contract | Low | B1 | `app/lib/utils/dataDir.ts:12-15` | High (not exploitable now) / Med (latent) |
| 2 | Cache JSON cast without shape validation; base now `/tmp` | Low | B3 | `app/lib/llm/cache.ts:44` | Medium |
| 3 | Analytics endpoint unauthenticated (pre-existing, untouched) | Informational | B2 | `app/api/analytics/route.ts:4-12` | High |

## Overall Assessment

This is a low-risk, behavior-preserving change. It moves server-side persistence behind a small `dataDir()` indirection and, on Vercel, redirects it to the platform-isolated `/tmp`. There is no currently-exploitable vulnerability in the diff: the one boundary it introduces (B1) is only ever fed compile-time literals, and the `/tmp` target is a single-tenant, container-scoped filesystem on Vercel. The single finding worth acting on is preventive — `dataDir` is a new reusable helper whose variadic `path.join` will silently accept `..` from whatever future caller reaches for it, so a one-line containment note or guard now is the cheapest place to close that gap. No blocking issues; safe to merge as-is, with the containment guard recommended as a follow-up hardening.
