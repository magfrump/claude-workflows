# Test Strategy: dataDir() environment-branch routing + cache/analytics persistence

**Commit:** b64c1ca
**Scope:** `git diff d86d2dc...HEAD` — `app/lib/utils/dataDir.ts` (new), `app/lib/llm/cache.ts`, `app/lib/analytics/persist.ts`
**Reviewed:** 2026-08-18

## Test Conventions

- **Framework:** Vitest (`npm test` → `vitest run`), config in `vitest.config.ts`; `environment: 'jsdom'`, `globals: true`, `@` alias → repo root, setup `vitest.setup.ts` (jest-dom only).
- **Location:** tests sit **next to** the code they cover, `*.test.ts` / `*.test.tsx` (e.g. `app/lib/utils/fileExtraction.test.ts`, `app/lib/llm/costs.test.ts`). A recommended test for `dataDir.ts` therefore belongs at `app/lib/utils/dataDir.test.ts`, cache at `app/lib/llm/cache.test.ts`, analytics at `app/lib/analytics/persist.test.ts`.
- **Style:** `describe` / `it` with `expect`, arrange-act-assert (see `fileExtraction.test.ts`). `vi.mock` used at module top for unmockable deps (`pdfjs-dist`). No existing fixture/temp-dir helper.
- **Existing coverage of the changed files: none.** No repo test imports `dataDir`, `cache.ts` (`setCachedResult`/`getCachedResult`/`removeCachedResult`), or the analytics `persist.ts` functions. The "cache/persist" test hits in the tree are all **localStorage** workspace-persistence tests (`useWorkspacePersistence.test.ts`, `workspacePersistence.test.ts`), unrelated to server-side filesystem persistence. The fact-check report exercised these paths only with throwaway scratch tests that were deleted after the run — so at HEAD the changed behavior has **zero** committed coverage.

## Critical testing subtlety (applies to every recommendation below)

`DATA_DIR` (`persist.ts:8`) and `CACHE_DIR` (`cache.ts:7`) are **module-level constants evaluated once at import time**. `dataDir()` reads `process.env.VERCEL` at call time, but each caller calls it exactly once during module load and freezes the result. Consequently a test cannot toggle `VERCEL`, re-import, and see a new path unless it calls `vi.resetModules()` and re-imports the module under test with `await import(...)` inside each env state (this is exactly what the fact-check scratch tests had to do). A naive test that sets `process.env.VERCEL` after the module is already imported will silently test the wrong branch and pass vacuously. Every recommendation below assumes the `vi.resetModules()` + dynamic-import pattern and restores `process.env.VERCEL` in `afterEach`.

## Untested Paths Touched by the Change

- **G1** — `app/lib/utils/dataDir.ts:13` — truthy branch: `process.env.VERCEL` set → `base === "/tmp"` — not covered (scratch test deleted; no committed test). **Deploy-critical branch.**
- **G2** — `app/lib/utils/dataDir.ts:13` — falsy branch: `VERCEL` unset → `base === join(process.cwd(), "data")` — not covered.
- **G3** — `app/lib/utils/dataDir.ts:14` — no-subpath arm: `dataDir()` returns `base` unchanged (used by `persist.ts:8`) — not covered.
- **G4** — `app/lib/utils/dataDir.ts:14` — with-subpath arm: `dataDir("cache")` → `join(base, "cache")` (used by `cache.ts:7`); also multi-arg `dataDir("a","b")` — not covered.
- **G5** — `app/lib/utils/dataDir.ts:13` — **deploy-critical negative invariant**: when `VERCEL` is set, a real analytics/cache write must land under `/tmp` and must **not** create anything under `<cwd>/data`. No test asserts the *absence* of a cwd/data write, so an inverted ternary, a dropped branch, or a future edit that reads a different env var would pass a string-equality-only test yet still break production silently — not covered.
- **G6** — `app/lib/utils/dataDir.ts:13` — env-value edge: `VERCEL=""` (empty string, falsy → local) vs `VERCEL="1"` (truthy → `/tmp`). The guard is truthiness, not presence; an empty-string env value routes to `data/`. Contract is untested — not covered.
- **G7** — `app/lib/llm/cache.ts:7,62-69,34-60` — cache **round-trip** through the env-resolved `CACHE_DIR`: `setCachedResult(hash, {text,usage})` writes `<base>/cache/<sha256>.json`, then `getCachedResult(...)` reads it back and returns `provider:"cache"`, `costUsd:0`, `latencyMs:0` with other usage fields (`inputTokens`) passed through and `cacheHash === hash`. No committed test reaches this module — not covered.
- **G8** — `app/lib/llm/cache.ts:56-59` — `getCachedResult` catch arm: corrupt JSON on disk **and** missing file both return `null` (miss). Reroute onto env-dependent path means this now runs against `/tmp` under Vercel — not covered.
- **G9** — `app/lib/llm/cache.ts:28-32` — `ensureCacheDir` memoization: first call `mkdir(CACHE_DIR, {recursive:true})`, `dirEnsured` latches so the second `setCachedResult` skips `mkdir`. `dirEnsured` is module-level state — not covered.
- **G10** — `app/lib/llm/cache.ts:79-83` — `removeCachedResult` unlink success vs. catch-when-absent (resolves without throwing) — not covered.
- **G11** — `app/lib/analytics/persist.ts:8-9,11-19` — analytics round-trip through env-resolved `DATA_DIR`: `appendAnalyticsEntry(entry)` creates `<base>/analytics.jsonl` (via `ensureDir` `existsSync`→`mkdirSync`) and `readAnalyticsEntries()` reads it back; append-twice yields two entries — not covered.
- **G12** — `app/lib/analytics/persist.ts:23,30-32` — `readAnalyticsEntries` edge arms: missing file → `[]` (line 23 guard); corrupt line → skipped via the line-level `catch` (line 30); blank line → skipped (line 27) — not covered.
- **G13** — `app/lib/analytics/persist.ts:37-40` — `clearAnalyticsEntries` writes empty string; a subsequent `readAnalyticsEntries()` returns `[]` — not covered.

## Recommended Tests

#### dataDir() environment-branch resolution
**Closes gaps:** G1, G2, G3, G4, G6
**Type:** unit
**Priority:** high
**File:** `app/lib/utils/dataDir.test.ts`
**What it verifies:** `dataDir()` resolves to the correct base and joins subpaths correctly in each `VERCEL` state.
**Key cases:**
- `VERCEL="1"` → `dataDir()` === `"/tmp"`; `dataDir("cache")` === `"/tmp/cache"`; `dataDir("a","b")` === `"/tmp/a/b"` (G1, G3, G4)
- `VERCEL` unset → `dataDir()` === `join(process.cwd(),"data")`; `dataDir("cache")` === `join(process.cwd(),"data","cache")` (G2, G3, G4)
- `VERCEL=""` (empty string) → resolves to the local `data/` base, documenting that the guard is truthiness not presence (G6)

**Setup needed:** `dataDir()` reads env at call time and takes no frozen constant, so this file needs no `resetModules` — just set/delete `process.env.VERCEL` per case and restore in `afterEach`. No filesystem needed (pure string assertions).

#### Deploy-critical: Vercel writes land in /tmp and never in cwd/data
**Closes gaps:** G5, G1
**Type:** integration
**Priority:** high
**File:** `app/lib/analytics/persist.test.ts` (and mirror in `app/lib/llm/cache.test.ts`)
**What it verifies:** With `VERCEL` set, an actual `appendAnalyticsEntry` / `setCachedResult` write creates a file under `/tmp` and creates **nothing** under `<cwd>/data` — the exact property that breaks silently in production if the branch regresses.
**Key cases:**
- `VERCEL="1"`, fresh import: `appendAnalyticsEntry({...})` → `existsSync("/tmp/analytics.jsonl")` true **and** `existsSync(join(cwd,"data","analytics.jsonl"))` false (the negative assertion is the load-bearing half)
- `VERCEL="1"`: `setCachedResult(hash, {...})` → file exists under `/tmp/cache/`, and no `<cwd>/data/cache/` entry created
- Regression sentinel: an inverted ternary or dropped branch must fail this test even though a string-equality test might not

**Setup needed:** `vi.resetModules()` + `await import("./persist")` (resp. `./cache`) **after** setting `process.env.VERCEL`, because `DATA_DIR`/`CACHE_DIR` freeze at import (see subtlety above). Use a unique temp filename or clean `/tmp/analytics.jsonl` and `<cwd>/data` in `beforeEach`/`afterEach` to avoid cross-test bleed; restore `VERCEL`. Because these constants read `process.cwd()`, consider chdir into an OS temp dir so the "no cwd/data write" assertion doesn't collide with a real repo `data/`.

#### LLM cache round-trip and usage override
**Closes gaps:** G7, G8, G9, G10
**Type:** integration
**Priority:** high
**File:** `app/lib/llm/cache.test.ts`
**What it verifies:** A cached result written to disk is read back with cache-hit usage semantics, and the miss/remove error paths behave.
**Key cases:**
- Write `setCachedResult(computeHash(m,s,u,mt), {text, usage:{provider:"anthropic",costUsd:0.5,latencyMs:999,inputTokens:10}})`, then `getCachedResult(m,s,u,mt)` returns `text` unchanged, `usage.provider==="cache"`, `usage.costUsd===0`, `usage.latencyMs===0`, `usage.inputTokens===10` (passthrough), `cacheHash===` the sha256 (G7)
- On-disk file stores the **original** usage (not the override) — read the raw JSON and assert `provider==="anthropic"` (G7)
- `getCachedResult` for a never-written hash → `null`; for a file containing `"{not valid json"` → `null` (G8)
- Two `setCachedResult` calls in one run: `mkdir` invoked once (spy on `fs/promises.mkdir`), proving the `dirEnsured` latch (G9)
- `removeCachedResult` after a write deletes the file; a second `removeCachedResult` (file absent) resolves without throwing (G10)

**Setup needed:** run under `VERCEL="1"` (or a chdir'd temp cwd) so writes hit a scratch dir; `vi.resetModules()`+dynamic import as above; clean the cache dir between tests. Spy on `fs/promises.mkdir` for the memoization case.

#### Analytics JSONL append/read round-trip and malformed-line tolerance
**Closes gaps:** G11, G12, G13
**Type:** integration
**Priority:** medium
**File:** `app/lib/analytics/persist.test.ts`
**What it verifies:** Analytics entries append and read back through the env-resolved `DATA_DIR`, and reads tolerate missing files, blank lines, and corrupt lines.
**Key cases:**
- Append two entries → `readAnalyticsEntries()` returns both, in order (G11)
- `readAnalyticsEntries()` before any write (file absent) → `[]` (G12)
- File with one valid line, one blank line, one `"{corrupt"` line → returns only the valid entry (G12)
- `clearAnalyticsEntries()` then `readAnalyticsEntries()` → `[]` (G13)

**Setup needed:** same import-freeze + temp-cwd/cleanup discipline as above.

## What NOT to Test

- **Vercel platform properties** — that `/tmp` is the only writable path, that `/tmp` is wiped on cold start, and that the project bundle is read-only (fact-check Claims 1b, 8a, 8b, 11, 14b, all Unverifiable). These are runtime properties of Vercel, not of this repo; no sandbox test can establish them. The code's *routing* to `/tmp` (G1/G5) is testable and is the correct thing to pin; the *consequences* of that routing on the real platform are documented in comments and out of scope for unit/integration tests. If desired, cover with a deploy smoke test, not a repo test.
- **`computeHash` determinism as a standalone concern** — it's a thin `createHash("sha256").update(JSON.stringify(...))` wrapper; the round-trip test (G7) already exercises it end-to-end. A separate hash-stability test adds little unless the field order in the hashed object becomes a contract you want to freeze.
- **The unguarded `clearAnalyticsEntries()` DELETE route** (`app/api/analytics/route.ts:9-12`, fact-check Claim 12) — real risk, but **outside this diff** (unchanged since d86d2dc). Noted below, not folded into this plan.

## Coverage Gaps Beyond Current Scope

**1.** `app/api/analytics/route.ts:9-12` — `DELETE` calls `clearAnalyticsEntries()` (a `writeFileSync`) with **no** try/catch, unlike every other write site, which is wrapped and swallowed. On a read-only filesystem this surfaces as an unhandled 500 rather than silent degradation. Worth an integration test asserting the route's failure contract (and a decision on whether it should be swallowed like the others). Pre-existing, not introduced by this diff.

**2.** LLM call-site swallowing (`callLlm.ts:85-94`, `streamLlm.ts:56,64,149`) — every `appendAnalyticsEntry`/`setCachedResult` call is wrapped in a silent `catch`. No test asserts that a persistence failure leaves the LLM response intact. This is the actual production-visible behavior of the rerouted writes; a test that forces `appendAnalyticsEntry` to throw and asserts the LLM call still returns would pin the "non-fatal persistence" contract. Pre-existing.

## Summary

The highest-value test is the **deploy-critical negative-write assertion (G5/G1)**: with `VERCEL` set, a real analytics/cache write must land in `/tmp` and create nothing under `<cwd>/data`. This is the one property whose regression breaks production silently and which a mere path-string-equality test would miss (an inverted ternary passes string checks in isolation but fails the negative-write check). Close it alongside the pure `dataDir()` branch-resolution unit test (G1–G4, G6), which is cheap and documents the four resolved paths plus the truthiness edge. The main residual risk after this plan is entirely off the sandbox: the Vercel platform assumptions (ephemeral `/tmp`, read-only bundle) remain unverifiable here and must be validated by a deploy smoke test. The gap enumeration also surfaced a real ambiguity worth a maintainer decision — the module-load-time freezing of `DATA_DIR`/`CACHE_DIR` means `process.env.VERCEL` must be set before first import, which is fine in production but makes every test require `vi.resetModules()` + dynamic import; and the unguarded DELETE-route write (out of scope) is the one persistence path that is not silently swallowed.
