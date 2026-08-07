Commit: 7f30210

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree wt-postfix)
**Scope:** git diff 9c9edf5..7f30210 (full changeset)
**Checked:** 2026-08-06
**Total claims checked:** 9
**Summary:** 7 verified, 0 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

---

## Claim 1: "Safe to spread: allWorks holds at most PER_QUERY_RESULTS per query — worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25), fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit."

**Location:** `app/api/evidence-search/route.ts:178-180`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High

`PER_QUERY_RESULTS` is 5 and is the `per_page` cap sent to OpenAlex, so each query yields at most 5 works:

```ts
// app/api/evidence-search/route.ts:20
const PER_QUERY_RESULTS = 5;
// app/api/evidence-search/route.ts:114
url.searchParams.set("per_page", String(PER_QUERY_RESULTS));
```

The override path is bounded to 5 queries by `MAX_OVERRIDE_QUERIES`:

```ts
// app/api/evidence-search/querySanitize.ts:9,20
export const MAX_OVERRIDE_QUERIES = 5;
...
if (cleaned.length >= MAX_OVERRIDE_QUERIES) break;
```

The LLM path is capped at 3 queries:

```ts
// app/api/evidence-search/route.ts:94
return parsed.queries.slice(0, 3);
```

`allWorks` is the accumulation of all per-query results and is spread into `Math.max(...)`. Worst case 5×5 = 25 (override), 3×5 = 15 (LLM). Both well under any argument-count limit. All three referenced constants and the arithmetic are correct.

**Evidence:** `app/api/evidence-search/route.ts:20,94,114,167-173,181`, `app/api/evidence-search/querySanitize.ts:9,20`

---

## Claim 2: "'unsafe-eval' is added only when NODE_ENV !== \"production\""

**Location:** `proxy.ts:23-24`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The default of `allowUnsafeEval` is exactly `NODE_ENV !== "production"`, and `'unsafe-eval'` is appended to `script-src` only when that flag is truthy:

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

The production caller (`proxy()`) invokes `buildCsp(nonce)` with no second argument, so it uses the NODE_ENV-derived default:

```ts
// proxy.ts:53
const csp = buildCsp(nonce);
```

**Evidence:** `proxy.ts:26-35,53`

---

## Claim 3: "Production output is genuinely eval-free"

**Location:** `proxy.ts:22-23`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low

This asserts that the Next.js production build emits no `eval()`-based code, justifying dropping `'unsafe-eval'` in production. This is a claim about the Next.js bundler's build output, not about code in this repo, and cannot be confirmed by static analysis of the codebase (paraphrased — no quote available because the claim concerns runtime build artifacts produced by an external toolchain, not source in this repo). Verifying it would require inspecting a real production build's emitted bundles.

**Evidence:** `proxy.ts:22-24`

---

## Claim 4: "Persists to localStorage with debounced writes (see the debounced storage adapter below) to avoid excessive serialization on rapid updates."

**Location:** `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

A debounced localStorage adapter is defined below in the same file and wired into the persist middleware's `storage`; `setItem` clears a pending timer and re-schedules a 300ms write:

```ts
// app/lib/stores/evidenceStore.ts:24-33
setItem: (name: string, value: string) => {
  if (pending) clearTimeout(pending);
  pending = setTimeout(() => {
    try {
      localStorage.setItem(name, value);
    ...
  }, 300);
},
// app/lib/stores/evidenceStore.ts:355-357
storage: typeof window !== "undefined"
  ? createJSONStorage(() => debouncedStorage)
  : undefined,
```

**Evidence:** `app/lib/stores/evidenceStore.ts:8-9,20-41,355-357`

---

## Claim 5: "Debounced localStorage adapter (same pattern as workspaceStore)"

**Location:** `app/lib/stores/evidenceStore.ts:17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

workspaceStore's default persistence is a debounced localStorage adapter with the same 300ms setTimeout/clearTimeout pattern, factored into `storeAdapter.resolveWorkspaceStorage()`:

```ts
// app/lib/corpus/storeAdapter.ts:33-50
// Default: debounced localStorage (moved verbatim from workspaceStore.ts ...
// Reads are synchronous (instant); writes are debounced by 300ms.
  let pending: ReturnType<typeof setTimeout> | null = null;
  ...
  pending = setTimeout(() => { ... }, 300);
```

```ts
// app/lib/stores/workspaceStore.ts:533
storage: createJSONStorage(resolveWorkspaceStorage),
```

The evidenceStore adapter (300ms debounce) matches this pattern. Claim accurate.

**Evidence:** `app/lib/stores/evidenceStore.ts:17,20-41`, `app/lib/stores/workspaceStore.ts:5,530-533`, `app/lib/corpus/storeAdapter.ts:33-50,110`

---

## Claim 6: "partial-JSON streaming can yield a tension object before its `between` tuple has arrived. Indexing `between[0]` on undefined threw a runtime TypeError that crashed the whole panel."

**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:44-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The pre-fix code indexed `t.between[0]` / `t.between[1]` with no guard (per the diff at 9c9edf5), which throws `TypeError: Cannot read properties of undefined` when `between` is absent. The fix wraps the endpoint block in a `t.between &&` guard while still rendering `t.description`:

```tsx
// app/components/panels/BalancedPerspectivesPanel.tsx:113-120
{t.between && (
  <div className="flex items-center gap-1 text-xs font-mono text-red-700">
    <span>{t.between[0]}</span>
    <span className="text-red-400">&harr;</span>
    <span>{t.between[1]}</span>
  </div>
)}
<p className="mt-1 text-xs text-red-800">{t.description}</p>
```

The test renders a tension lacking `between` and asserts no throw plus that the description still renders, matching the described bug and fix.

**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-120`, `app/components/panels/BalancedPerspectivesPanel.test.tsx:38-55`, diff 9c9edf5..7f30210

---

## Claim 7: "`between` absent mid-stream — the static type marks it required, so cast."

**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:49`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High

The Tension type declares `between` as a required non-optional tuple, so constructing a tension without it requires the `as unknown as Tension` cast the test uses:

```ts
// app/lib/types/artifacts.ts:99-102
tensions: Array<{
  between: [string, string];
  description: string;
}>;
```

**Evidence:** `app/lib/types/artifacts.ts:99-102`, `app/components/panels/BalancedPerspectivesPanel.test.tsx:49-50`

---

## Claim 8: "Pin the production CSP explicitly so these assertions don't depend on the ambient NODE_ENV the test runner happens to set."

**Location:** `proxy.test.ts:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The test passes `false` as the second `buildCsp` argument, overriding the NODE_ENV-derived default so the CSP under test is deterministic regardless of the runner's environment:

```ts
// proxy.test.ts:12
const csp = buildCsp(NONCE, false);
```

Because `allowUnsafeEval` is an explicit parameter (Claim 2), passing `false` fully decouples this suite from `process.env.NODE_ENV`. Accurate.

**Evidence:** `proxy.test.ts:12`, `proxy.ts:26-32`

---

## Claim 9: "'unsafe-eval' must remain scoped to script-src — never leaks elsewhere."

**Location:** `proxy.test.ts:44`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

In `buildCsp`, `'unsafe-eval'` is interpolated only into the `scriptSrc` string; no other directive references it:

```ts
// proxy.ts:30-45
const scriptSrc = `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${
  allowUnsafeEval ? " 'unsafe-eval'" : ""
}`;
const directives = [
  "default-src 'self'",
  scriptSrc,
  "style-src 'self' 'unsafe-inline'",
  ...
];
```

The test asserts exactly one `'unsafe-eval'` occurrence in the dev CSP and that it lives on `script-src`, which the implementation guarantees.

**Evidence:** `proxy.ts:30-45`, `proxy.test.ts:36-45`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- **Claim 3** (`proxy.ts:22-23`): "Production output is genuinely eval-free" concerns Next.js build artifacts, not repo source; would need inspection of a real production bundle to confirm.
