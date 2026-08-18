# Code Fact-Check Report — Submitted Claims (Stage 2.5)

**Repository:** cc-review-eval / mfc-fscompat (`/workspace/external/cc-review-eval/mfc-fscompat`)
**Scope:** Endorsement claims routed by Stage-2 critics (`security-review.md` ×3, `performance-review.md` ×1); api-consistency and test-strategy routed none
**Checked:** 2026-08-18
**Commit:** b64c1ca
**Total claims checked:** 4
**Summary:** 4 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

---

## Submitted Claims

## Claim 20: "Every cache filename in `cache.ts` is constructed by `join(CACHE_DIR, ...)` over a value from `createHash(\"sha256\").digest(\"hex\")` on the `getCachedResult`/`removeCachedResult` paths, giving a hex-only last path segment on those paths."

**Submitted by:** security-reviewer
**Location:** `app/lib/llm/cache.ts:22-24,41,78`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the filename-segment derivation on the `getCachedResult` and `removeCachedResult` paths (both re-derive `hash` from `computeHash`); does not establish the segment for `setCachedResult`, whose `hash` is caller-supplied (the critic's own `Not verified` hop — traced only to the two current callers).

`computeHash` returns a bare sha256 hex digest, no separators:

```ts
// app/lib/llm/cache.ts:22-24
return createHash("sha256")
  .update(JSON.stringify({ model, systemPrompt, userContent, maxTokens }))
  .digest("hex");
```

Both read/remove paths derive the filename segment from that digest via `join(CACHE_DIR, `${hash}.json`)`:

```ts
// app/lib/llm/cache.ts:40-41  (getCachedResult)
const hash = computeHash(model, systemPrompt, userContent, maxTokens);
const filePath = join(CACHE_DIR, `${hash}.json`);
```

```ts
// app/lib/llm/cache.ts:77-78  (removeCachedResult)
const hash = computeHash(model, systemPrompt, userContent, maxTokens);
const filePath = join(CACHE_DIR, `${hash}.json`);
```

A `[0-9a-f]{64}` digest plus the literal `.json` suffix is the entire last path segment on these two paths — no separator or `..` can appear, so the join stays within `CACHE_DIR`. The `Not verified` hop the critic names is accurate: `setCachedResult(hash, ...)` (cache.ts:62-68) trusts its caller's `hash` string; both live callers pass `computeHash` output (`callLlm.ts:121→94/159/199`), so no untrusted string reaches it today.

**Evidence:** `app/lib/llm/cache.ts:22-24`, `app/lib/llm/cache.ts:40-41`, `app/lib/llm/cache.ts:62-68`, `app/lib/llm/cache.ts:77-78`, `app/lib/llm/callLlm.ts:121`

---

## Claim 21: "`appendAnalyticsEntry` serializes each entry as `JSON.stringify(entry) + \"\\n\"`, and `readAnalyticsEntries` splits on `\"\\n\"`, so a newline inside an entry field is escaped rather than starting a new JSONL record."

**Submitted by:** security-reviewer
**Location:** `app/lib/analytics/persist.ts:17-20,22-35`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the append serialization and the read-back line split — a field newline cannot forge an extra JSONL record; does not establish whether any `AnalyticsEntry` field is actually attacker-controlled (the critic's own `Not verified` hop — record-site fields not traced field-by-field).

The append writes one `JSON.stringify` line, and the read-back splits on `"\n"` with per-line `JSON.parse`:

```ts
// app/lib/analytics/persist.ts:17-20
export function appendAnalyticsEntry(entry: AnalyticsEntry): void {
  ensureDir();
  appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
}
```

```ts
// app/lib/analytics/persist.ts:22-35 (readAnalyticsEntries, excerpt)
for (const line of content.split("\n")) {
  if (!line.trim()) continue;
  try { entries.push(JSON.parse(line)); } catch { /* skip corrupt lines */ }
}
```

`JSON.stringify` escapes embedded newlines to the two-character sequence `\n`, so an entry containing a raw newline still serializes to exactly one physical line. Confirmed by execution: a probe stringifying `{ endpoint: "a\nb\nfake-record" }`, suffixing `"\n"`, then splitting on `"\n"` and dropping blank lines yields exactly **one** non-empty line and the serialized string contains the literal escape `\\n` (not a real newline). Test passed 2/2.

**Evidence:** `app/lib/analytics/persist.ts:17-20`, `app/lib/analytics/persist.ts:22-35`, `./evidence/sc-double-hash-jsonl.txt` (probe: `npx vitest run app/lib/llm/scDoubleHash.scratch.test.ts`, cwd `/workspace/external/cc-review-eval/mfc-fscompat`, 2026-08-18T06:58:29Z, "Tests 2 passed (2)"; note: the harness process exit was 1 due to an unrelated jsdom-env probe error on `/workspace/external/package.json`, not a test failure — the `Test Files 1 passed (1) / Tests 2 passed (2)` line is authoritative)

---

## Claim 22: "With `VERCEL` unset, `dataDir()` / `dataDir(\"cache\")` resolve to the same paths the pre-diff hardcoded constants used, so the diff adds no new local (non-Vercel) write location."

**Submitted by:** security-reviewer
**Location:** `app/lib/utils/dataDir.ts:12-15`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four resolved values (`DATA_DIR`, `CACHE_DIR`) in both env states against parent 2136fd6, established by the merged fact-check's executed Claims 15 & 17; does not address the `VERCEL`-set `/tmp` destinations' exposure (security Finding 1) nor actual Vercel platform filesystem behavior (merged Claims 8/11/14b, Unverifiable).

Covered by the merged Stage-1 report (`code-fact-check-report.md`), which executed this exact question and rated it Verified twice:

- **Merged Claim 15** ("Local dev is unchanged"): with `VERCEL` unset the new code resolves to `join(process.cwd(), "data")` and `join(process.cwd(), "data", "cache")` — the base commit's paths; scratch tests asserted the return values and write destinations (r1 6/6, r2, both exit 0; r1 full suite 221 passed).
- **Merged Claim 17** ("No behavior change; both DATA_DIR and CACHE_DIR resolve to the same paths"): scratch tests asserted all four resolved values under both env states — identical strings in all four cases (r1 and r2, exit 0).

The extraction itself is a direct substitution of the prior inline ternary:

```ts
// app/lib/utils/dataDir.ts:12-15
export function dataDir(...subpaths: string[]): string {
  const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
  return subpaths.length > 0 ? join(base, ...subpaths) : base;
}
```

Re-execution is unnecessary and would only duplicate merged Claims 15 & 17, which already carry `executed` provenance at HEAD b64c1ca.

**Evidence:** `app/lib/utils/dataDir.ts:12-15`, merged `code-fact-check-report.md` Claim 15 (`./evidence/r1-datadir-scratch-vitest.txt`, `./evidence/r1-npm-test.txt`, `./evidence/r2-vitest-local.txt`), merged Claim 17 (`./evidence/r2-vitest-vercel.txt`, `./evidence/r2-vitest-local.txt`)

---

## Claim 23: "`getCachedResult` recomputes `computeHash` internally (`cache.ts:40`) despite the caller having already computed `cacheHash` (`callLlm.ts:121`), so the sha256 over `userContent` executes twice on the get path."

**Submitted by:** performance-reviewer
**Location:** `app/lib/llm/cache.ts:40`; caller `app/lib/llm/callLlm.ts:121,125`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the get path — the caller's `computeHash` at callLlm.ts:121 plus `getCachedResult`'s internal `computeHash` at cache.ts:40 equal two sha256 computations per call; does not assert the redundancy is worth fixing (a critic-severity question, out of fact-check scope) and does not cover the set path, which correctly reuses the hash.

The caller computes the hash once and comments that it will be reused, then calls `getCachedResult` with the raw params rather than the hash:

```ts
// app/lib/llm/callLlm.ts:120-125
// Compute hash once, reuse for cache get and set
const cacheHash = computeHash(effectiveModel, systemPrompt, userContent, maxTokens);
const cacheKey: CacheKey = { model: effectiveModel, systemPrompt, userContent, maxTokens };
// Check cache before making any LLM call
const cached = await getCachedResult(effectiveModel, systemPrompt, userContent, maxTokens);
```

`getCachedResult` then re-derives the identical hash internally:

```ts
// app/lib/llm/cache.ts:40
const hash = computeHash(model, systemPrompt, userContent, maxTokens);
```

Only the set path honors the "reuse": `setCachedResult(hash, ...)` takes the hash directly (cache.ts:62-68) and is passed `cacheHash` at `callLlm.ts:94/159/199`. So the "compute once" comment holds for set but not get; the get path hashes twice.

Confirmed by execution: a probe mocked the `crypto` module to count `createHash` invocations (delegating to the real implementation), then ran the caller's get sequence — `computeHash(...)` (mirroring callLlm.ts:121) followed by `getCachedResult(...)` (a miss → returns `null`). `createHash` was invoked exactly **2** times (assertion `toHaveBeenCalledTimes(2)` passed): once in the caller's `computeHash`, once inside `getCachedResult`. Test passed 2/2. **This corroborates the D6-adjacent double-hash claim: it verifies.** (Pre-existing per the critic — the diff changed only `CACHE_DIR`, not `computeHash`/`getCachedResult`.)

**Evidence:** `app/lib/llm/callLlm.ts:120-125`, `app/lib/llm/cache.ts:40`, `app/lib/llm/cache.ts:62-68`, `./evidence/sc-double-hash-jsonl.txt` (probe: `npx vitest run app/lib/llm/scDoubleHash.scratch.test.ts`, cwd `/workspace/external/cc-review-eval/mfc-fscompat`, 2026-08-18T06:58:29Z, "Tests 2 passed (2)"; harness exit 1 from an unrelated jsdom-env probe error on `/workspace/external/package.json`, not a test failure)

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.

All four submitted endorsement claims verified. Each is admissible backing for a ✅ Confirmed-Good row per Stage-2.5 feed-back rule 5 (submitted claim verdicted `Verified`, with its verification mode and `Scope:` line). Claims 21 and 23 carry fresh `executed` provenance from the Stage-2.5 probe; Claim 22 rests on the merged report's executed Claims 15 & 17; Claim 20 is a static structural invariant. The double-hash claim (Claim 23, D6-adjacent) verifies — `createHash` runs exactly twice on the get path.
