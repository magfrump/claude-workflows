# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-postfix (meta-formalism-copilot)
**Commit:** 7f30210
**Scope:** Checkable claims in files changed in `git diff 9c9edf5...HEAD` — `proxy.ts`, `proxy.test.ts`, `app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx`, `app/components/panels/BalancedPerspectivesPanel.test.tsx`
**Checked:** 2026-08-17
**Total claims checked:** 9
**Summary:** 8 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Evidence logs (raw execution output) under `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/` (prefix `r2-`).

Note on the task's "optional chaining mischaracterization" hint: a repo-wide search (`rg "optional chain"` over the diff files and all of `app/`) returns zero hits. No comment in the changed files describes the `between` guard as "optional chaining"; the fix uses a logical-AND truthiness guard (`{t.between && (…)}`), not `?.`. There is no such comment claim to verdict.

---

## Claim 1: "Production output is genuinely eval-free, so `'unsafe-eval'` is added only when NODE_ENV !== \"production\""

**Location:** `proxy.ts:21-24`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the runtime effect of the `allowUnsafeEval` default parameter across NODE_ENV values (production, test, staging, development, undefined); does not establish that the *production build output* is in fact eval-free (that is a Next.js-toolchain property, not exercised here).

The default parameter derives `allowUnsafeEval` from NODE_ENV, and `'unsafe-eval'` is appended to `script-src` only when it is truthy:

```ts
// proxy.ts:26-32
export function buildCsp(
  nonce: string,
  allowUnsafeEval: boolean = process.env.NODE_ENV !== "production",
): string {
  const scriptSrc = `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${
    allowUnsafeEval ? " 'unsafe-eval'" : ""
  }`;
```

Executed a scratch vitest calling `buildCsp(NONCE)` (default param) with NODE_ENV mutated per case. Captured output (`r2-buildcsp-env-default.txt`): `production` → `unsafe-eval=false`; `test`, `staging`, `development`, and `undefined` → `unsafe-eval=true`. The mechanism is a strict `!== "production"` check, so the fail-open is real: any value other than the exact string `"production"` — including unset/undefined and unexpected values like `"staging"` — adds `'unsafe-eval'`. This matches the comment's stated rule.

**Evidence:** `proxy.ts:26-32`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/r2-buildcsp-env-default.txt` (5 tests passed; exit 1 is unrelated environment noise — an empty `/workspace/external/package.json` vitest tries to read — not a test failure)

---

## Claim 2: "form-action does NOT fall back to default-src (CSP3); set explicitly."

**Location:** `proxy.ts:43`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether `form-action` is emitted explicitly in the directive list and the CSP3 fallback behavior it cites; does not test browser enforcement.

`form-action 'self'` is present as an explicit entry in the directive array:

```ts
// proxy.ts:43-44
// form-action does NOT fall back to default-src (CSP3); set explicitly.
"form-action 'self'",
```

The spec claim is accurate: under CSP Level 3, `form-action` is a navigation directive that is not in the fetch-directive set that falls back to `default-src`; without an explicit `form-action`, form submissions are unrestricted. The code sets it explicitly as the comment states.

**Evidence:** `proxy.ts:33-45`

---

## Claim 3: "Pin the production CSP explicitly so these assertions don't depend on the ambient NODE_ENV the test runner happens to set."

**Location:** `proxy.test.ts:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether passing `false` as the second argument decouples the test from NODE_ENV; does not cover the other assertions in the file.

The test passes `allowUnsafeEval = false` explicitly:

```ts
// proxy.test.ts:12
const csp = buildCsp(NONCE, false);
```

Because the explicit argument overrides the `process.env.NODE_ENV !== "production"` default (`proxy.ts:28`), the resulting CSP is the production (eval-free) variant regardless of the runner's ambient NODE_ENV. The comment accurately describes what the explicit `false` accomplishes.

**Evidence:** `proxy.test.ts:10-12`, `proxy.ts:26-32`

---

## Claim 4: "The committed test suite covers `buildCsp`'s default (NODE_ENV-derived) `allowUnsafeEval` path."

**Location:** `proxy.test.ts:12,37` (call sites) vs. `proxy.ts:53` (production call site)
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether any committed test exercises the single-argument `buildCsp(nonce)` default-parameter branch; the two output shapes (with/without `'unsafe-eval'`) *are* covered via explicit `false`/`true` arguments — only the env-derivation branch is untested.

The only production call site relies on the default parameter:

```ts
// proxy.ts:53
const csp = buildCsp(nonce);
```

But every committed test passes the second argument explicitly — `buildCsp(NONCE, false)` (`proxy.test.ts:12`) and `buildCsp(NONCE, true)` (`proxy.test.ts:37`). A grep across `*.test.ts`/`*.test.tsx` (`r2-buildcsp-callsites.txt` content captured inline in the run log) shows no committed test calls `buildCsp(nonce)` with the default parameter. Therefore the NODE_ENV-reading branch that the real proxy path depends on is not exercised by the suite. (Both resulting CSP *shapes* are asserted via the explicit-argument tests, so the directive strings are covered; the env→boolean derivation is the untested gap.) The regression I ran to establish this used a scratch file (`buildCsp(NONCE)` with mutated NODE_ENV) that is not part of the committed suite and was deleted.

**Evidence:** `proxy.ts:53`, `proxy.test.ts:12`, `proxy.test.ts:37`, grep output recorded in `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/r2-committed-tests.txt` (committed suite: `proxy.test.ts` 5 tests + panel 2 tests, all passing)

---

## Claim 5: "Safe to spread: allWorks holds at most PER_QUERY_RESULTS per query — worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25), fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit."

**Location:** `app/api/evidence-search/route.ts:178-180`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the code-controlled bounds on `allWorks.length` (query-count caps and per-query request size) feeding `Math.max(...allWorks.map(...))`; the per-query ceiling assumes OpenAlex honors the `per_page` request parameter (external service behavior, not executable here).

Each query requests at most `PER_QUERY_RESULTS` results and returns them unmodified:

```ts
// route.ts:20
const PER_QUERY_RESULTS = 5;
// route.ts:114
url.searchParams.set("per_page", String(PER_QUERY_RESULTS));
// route.ts:126
return (data.results ?? []) as OpenAlexWork[];
```

Query count is bounded on both paths. The override path is capped at 5 by the sanitizer:

```ts
// app/api/evidence-search/querySanitize.ts
export const MAX_OVERRIDE_QUERIES = 5;
…
if (cleaned.length >= MAX_OVERRIDE_QUERIES) break;
```

The LLM path is capped at 3:

```ts
// route.ts:94
return parsed.queries.slice(0, 3);
```

So `allWorks` ≤ 5×5 = 25 (override) or ≤ 3×5 = 15 (LLM), and `Math.max(...allWorks.map(...))` (`route.ts:181`) spreads at most 25 arguments — far below the engine's argument-count limit (tens of thousands). The comment's arithmetic and both worst-case figures are correct. The `Math.max` runs before the final `.slice(0, MAX_RESULTS)` (8) at `route.ts:186`, so the 8-cap does not affect the spread size, but the comment reasons about `allWorks` (pre-slice), which is the correct array.

**Evidence:** `app/api/evidence-search/route.ts:19-20`, `:94`, `:114`, `:126`, `:166-186`, `app/api/evidence-search/querySanitize.ts:9,21`

---

## Claim 6: "Persists to localStorage with debounced writes (see the debounced storage adapter below) to avoid excessive serialization on rapid updates."

**Location:** `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the store's persist storage is the local debounced adapter with a real timer; does not verify the SSR-guard path or actual localStorage behavior in a browser.

The adapter debounces `setItem` with a 300 ms timer and is wired into the persist middleware:

```ts
// evidenceStore.ts:24-33
setItem: (name: string, value: string) => {
  if (pending) clearTimeout(pending);
  pending = setTimeout(() => {
    try { localStorage.setItem(name, value); } …
  }, 300);
},
// evidenceStore.ts:355-357
storage: typeof window !== "undefined"
  ? createJSONStorage(() => debouncedStorage)
  : undefined,
```

The comment's "debounced writes … to avoid excessive serialization" matches the coalescing timer.

**Evidence:** `app/lib/stores/evidenceStore.ts:20-41`, `:355-357`

---

## Claim 7: "Debounced localStorage adapter (same pattern as workspaceStore)"

**Location:** `app/lib/stores/evidenceStore.ts:16-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether workspaceStore uses the same debounced-write pattern; does not assert byte-identical code.

workspaceStore's default persist storage resolves to `createDebouncedLocalStorage`, whose `setItem` is the same 300 ms coalescing pattern:

```ts
// app/lib/corpus/storeAdapter.ts:41-51
setItem: (name, value) => {
  if (pending) clearTimeout(pending);
  pending = setTimeout(() => {
    try { localStorage.setItem(name, value); } …
  }, 300);
},
```

`workspaceStore.ts:533` wires it via `storage: createJSONStorage(resolveWorkspaceStorage)`, and `resolveWorkspaceStorage` returns `createDebouncedLocalStorage()` on the default (flag-off) path (`storeAdapter.ts:110-114`). The pattern (300 ms debounce, clear-on-remove) is identical to evidenceStore's, so "same pattern as workspaceStore" is accurate even though the workspace adapter now lives in `corpus/storeAdapter.ts` rather than inline in `workspaceStore.ts`.

**Evidence:** `app/lib/stores/evidenceStore.ts:16-33`, `app/lib/corpus/storeAdapter.ts:37-58`, `:110-114`, `app/lib/stores/workspaceStore.ts:533`

---

## Claim 8: "Partial map data from streaming (partial-JSON parsed)"

**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that `streamingPreview` is typed as the complete artifact type and used as a fallback display source; does not verify that the upstream producer actually emits partial-JSON parses (that producer is outside the changed files).

`streamingPreview` is declared with the full artifact type and fed to `mergeStreamingPreview` as the fallback display source:

```tsx
// BalancedPerspectivesPanel.tsx:12-13
/** Partial map data from streaming (partial-JSON parsed) */
streamingPreview?: BalancedPerspectivesResponse["balancedPerspectives"] | null;
// BalancedPerspectivesPanel.tsx:25-28
const { displayData: displayMap, hasDisplayData } = mergeStreamingPreview(
  balancedPerspectives, streamingPreview, …);
```

`mergeStreamingPreview<T>` returns `finalData ?? streamingPreview ?? null` (`app/lib/utils/mergeStreamingPreview.ts:13`), typing the partial preview as a complete `T`. The comment accurately labels this value as partial data typed as complete — which is precisely why the runtime guards (Claim 9) are needed. Medium confidence because "partial-JSON parsed" describes an upstream producer not present in the changed files.

**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:12-28`, `app/lib/utils/mergeStreamingPreview.ts:8-16`

---

## Claim 9: "partial-JSON streaming can yield a tension object before its `between` tuple has arrived. Indexing `between[0]` on undefined threw a runtime TypeError that crashed the whole panel."

**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:47-50`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that indexing `between[0]` when `between` is undefined throws a TypeError, that the new `{t.between && …}` guard prevents the crash, and that no error boundary would have contained it; does not reproduce the exact upstream partial-JSON stream that produces a `between`-less tension.

The type marks `between` required (`app/lib/types/artifacts.ts:99-102`: `between: [string, string]`), but a partial stream can deliver a tension without it. Before the fix, the render indexed it unconditionally; the diff wraps the endpoint row in a presence guard:

```tsx
// BalancedPerspectivesPanel.tsx:113-119
{t.between && (
  <div className="flex items-center gap-1 text-xs font-mono text-red-700">
    <span>{t.between[0]}</span>
    <span className="text-red-400">&harr;</span>
    <span>{t.between[1]}</span>
  </div>
)}
```

Executed confirmation of the TypeError mechanism (`r2-between-index-typeerror.txt`): indexing `t.between[0]` with `between` absent throws `TypeError - Cannot read properties of undefined (reading '0')`. Ran the committed regression test (`r2-committed-tests.txt`): "does not crash when a streamed tension is missing its between tuple" passes, and the description still renders — confirming the guard fixes the crash. A repo search for error boundaries (`componentDidCatch|ErrorBoundary|getDerivedStateFromError` across `app/`) returned zero hits, so an uncaught render throw would propagate and unmount the tree — i.e., "crashed the whole panel" is accurate (and would in fact crash more than the panel).

**Evidence:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:44-54`, `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`, `app/lib/types/artifacts.ts:99-102`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/r2-between-index-typeerror.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/r2-committed-tests.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`proxy.test.ts:12,37` vs `proxy.ts:53`): The committed tests always pass `allowUnsafeEval` explicitly (`false`/`true`), so `buildCsp`'s default NODE_ENV-derived branch — the branch the real proxy call site (`proxy.ts:53`) depends on — is never exercised. The two output shapes are covered; the env→boolean derivation is not. Add a test that stubs `process.env.NODE_ENV` and calls `buildCsp(nonce)` with the default parameter.

### Mostly Accurate
- (none)

### Unverifiable
- (none)
