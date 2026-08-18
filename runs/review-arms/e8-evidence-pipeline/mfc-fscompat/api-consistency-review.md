# API Consistency Review — mfc-fscompat (dataDir/tmp routing)

**Commit:** b64c1ca
**Scope:** `git diff d86d2dc...HEAD` — `app/lib/utils/dataDir.ts` (new), `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`
**Date:** 2026-08-17
**Based on:** code-fact-check report at `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/code-fact-check-report.md` (commit b64c1ca)

The diff introduces one new exported helper (`dataDir()`) and reroutes two persistence modules through it. The consumer-facing surface here is small: `dataDir()` is an internal library export, and the analytics HTTP routes that sit downstream of these modules (`GET`/`DELETE /api/analytics`) are the true external contract. I reviewed the new helper's call convention, the docstring/comment contracts, and the analytics route's error/return shapes against sibling routes.

## Baseline Conventions

Surveyed `app/lib/utils/*.ts` (18 util modules) and `app/api/**/route.ts` (16 routes):

- **Util exports** — camelCase; predominantly verb-prefixed (`getSelectionCoordinates`, `getGraphViewportElement`, `extractTextFromFile`, `triggerDownload`, `sanitizeText`), with a minority of bare verbs/nouns (`throttle`, `topologicalSort`). Variadic path helpers mirror `path.join`'s `...parts` shape.
- **Route error envelope** — failure paths return `{ error: string }` (optionally `{ error, details }`) with an explicit HTTP status: `predict/route.ts:9-12` (`{ error }`, 400), `edit/inline/route.ts:28-37` (`{ error }`/`{ error, details }`, 502), `decomposition/extract/route.ts:105` (`{ error }`, 400). LLM routes wrap their handler body in try/catch and map thrown errors to this envelope.
- **Route success shape** — the payload is returned directly under a descriptive key: `{ entries }`, `{ text }`, `{ leanCode }`, `{ explanation }`, and boolean-status shapes `{ valid: true, mock: true }` / `{ ok: true }`.
- **Persistence error handling** — call sites of `appendAnalyticsEntry`/`setCachedResult`/`getCachedResult` are wrapped in try/catch that swallows write failures as non-fatal (verified in fact-check Claim 12); `getCachedResult`/`removeCachedResult` swallow internally.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `dataDir` | function | `getGraphViewportElement`, `getSelectionCoordinates`, `throttle`, `topologicalSort` | `app/lib/utils/*.ts` | Weak/mixed precedent — most util getters are `get`-prefixed, but bare-noun/verb exports (`throttle`, `topologicalSort`) also exist. A path-returning bare noun is defensible; see Finding 3. |
| `subpaths` (rest param) | parameter | `path.join(...parts)` idiom; no in-repo variadic-path analog | searched `app/lib/utils/`, `app/lib/**` | New but idiomatic — mirrors `path.join`'s variadic signature. Consistent. |

No new routes, types, enums, error codes, or event names are introduced by this diff.

## Findings

### Finding 1 — Analytics route write/read paths bypass the established `{ error }` envelope

**Severity:** Inconsistent
**Location:** `app/api/analytics/route.ts:4-12` (downstream of `app/lib/analytics/persist.ts:37-40`)
**Move:** #4 (error consistency), #7 (asymmetry)
**Confidence:** High

The `DELETE` handler calls `clearAnalyticsEntries()` (a `writeFileSync`) and `GET` calls `readAnalyticsEntries()` (a `readFileSync`) with no try/catch — this diff makes those writes land in `/tmp` on Vercel, exactly the filesystem where a write/read can fail. Fact-check Claim 12 (Mostly accurate) confirms the DELETE-route write is the one persistence path that is **not** swallowed: unlike every `appendAnalyticsEntry`/`setCachedResult` call site (wrapped in non-fatal try/catch), a failure in `clearAnalyticsEntries()` surfaces as an unhandled route error. That produces a framework-generated 500 rather than the `{ error: string }` + status envelope that `predict`, `edit/inline`, and `decomposition/extract` return, so a consumer of `/api/analytics` gets a different error contract than every sibling route. This is an existing asymmetry the diff doesn't introduce, but the diff moves the target directory to the ephemeral, more-failure-prone `/tmp`, raising the probability the divergent path is hit.

**Recommendation:** Wrap the `GET`/`DELETE` bodies in try/catch and return `{ error: <message> }` with a 500 (matching sibling routes), or route the persistence failure through the same swallow-and-degrade pattern the append/cache call sites use. Keeping the envelope consistent means clients can handle `/api/analytics` failures the same way they handle every other route.

### Finding 2 — Comment points to a "Deploy to Vercel" README section that does not exist

**Severity:** Minor
**Location:** `app/lib/analytics/persist.ts:6-7`
**Move:** #3 (documentation drift)
**Confidence:** High

The new comment says `see Deploy to Vercel in README`. Fact-check Claim 2 (Incorrect, High) grep-proved that the README — and every other doc file — contains no "Deploy to Vercel" section and no mention of Vercel or deployment at all. A maintainer following this pointer to understand the `/tmp` routing finds nothing; the actual rationale lives in the `dataDir()` docstring (`app/lib/utils/dataDir.ts:3-11`), which the same comment already references and which the fact-check verified as accurate (Claims 3, 8, 9). The dangling half of the reference is pure noise that will mislead the next reader.

**Recommendation:** Drop the "see Deploy to Vercel in README" clause (the `dataDir()` reference already carries the rationale), or add the README section it promises. Prefer dropping it — the docstring is the single source of truth here.

### Finding 3 — Divergent `dataDir()` call convention across the two new call sites

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:8-9` vs `app/lib/llm/cache.ts:7`
**Move:** #2 / #7 (usage asymmetry of a new API)
**Confidence:** High
No existing precedent in `app/lib/**` (searched all `dataDir` call sites; this diff creates the only two).

`dataDir()` exposes a variadic `...subpaths` API so a caller can name the full target in one call. `cache.ts` uses it that way — `dataDir("cache")`. `persist.ts` does not — it calls `dataDir()` for the base and then joins the filename at the call site: `FILE_PATH = join(DATA_DIR, "analytics.jsonl")`. Two immediate callers of a brand-new helper thus demonstrate two different conventions for the same operation. There is a real reason for the split (persist.ts needs the bare `DATA_DIR` for `ensureDir()`), so this is not a defect — but because these two call sites are the entire precedent for how `dataDir()` should be used, the inconsistency will propagate: the next caller has two contradictory examples to copy. Per the no-precedent rule this is floored at Informational.

**Recommendation:** No change required, but consider a one-line comment at the `persist.ts` call site noting that it keeps `DATA_DIR` separate because `ensureDir()` needs the directory, so future readers don't treat the join-at-callsite form as the preferred convention. Alternatively `dataDir("analytics.jsonl")` for `FILE_PATH` while retaining `dataDir()` for the mkdir target would make the rest-args form the single demonstrated pattern.

## What Looks Good

- **`dataDir(...subpaths)` signature** mirrors `path.join`'s variadic shape — an idiomatic, discoverable API for a path builder; the `subpaths.length > 0` guard correctly returns the bare base when called with no args.
- **`dataDir()` docstring** accurately states the `/tmp`-only-writable and warm-container-lifetime rationale (fact-check Claims 3/8/9 verified) — the contract description matches behavior.
- **No behavior change and no new dependencies** — `DATA_DIR`/`CACHE_DIR` resolve to the same four values as before (fact-check Claims 13, 17), so no existing consumer of the persistence modules is broken by the refactor.
- **`{ ok: true }` success shape** on `DELETE /api/analytics` is consistent with the boolean-status precedent `{ valid: true, mock: true }` (`verification/lean/route.ts:39`) — not a finding.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Analytics route write/read bypasses `{ error }` envelope (unguarded DELETE/GET) | Inconsistent | `app/api/analytics/route.ts:4-12` | High |
| 2 | Comment references nonexistent "Deploy to Vercel" README section | Minor | `app/lib/analytics/persist.ts:6-7` | High |
| 3 | Divergent `dataDir()` call convention (join-at-callsite vs rest-args) | Informational | `persist.ts:8-9` vs `cache.ts:7` | High |

## Overall Assessment

The refactor itself is clean and behavior-preserving: the new `dataDir()` helper is idiomatic and its docstring contract is accurate. The consistency issues are at the edges. The one that matters for consumers is Finding 1 — the analytics route's unguarded write/read path now targets the more-failure-prone `/tmp` while still bypassing the `{ error }` envelope that every sibling route honors, so a `/api/analytics` failure looks different to a client than any other route failure. Finding 2 is a stale documentation pointer (a Fact-check-confirmed Incorrect reference) that should be trimmed. Finding 3 is a benign but propagation-prone usage split in how the brand-new helper is called. All three are fixable in place; none indicate the author misread existing conventions.
