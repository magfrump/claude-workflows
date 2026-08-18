# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-postfix
**Commit:** 7f30210
**Scope:** `git diff 9c9edf5...HEAD` — checkable claims in changed regions of `proxy.ts`, `proxy.test.ts`, `app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx` + its new test, and the two changed commit messages (`2e23824`, `c0e0a35`).
**Checked:** 2026-08-18
**Total claims checked:** 11
**Summary:** 8 verified, 1 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Execution note: all three vitest invocations returned process **exit code 1**, but this is an environmental artifact — the empty parent file `/workspace/external/package.json` (0 bytes) makes vitest's dependency probe throw `ERR_INVALID_PACKAGE_CONFIG` and emit a spurious `MISSING DEPENDENCY jsdom` line while still running the suite to completion. Pass/fail below is read from vitest's own test summary (`Tests N passed`), which is authoritative, not from the process exit code. Captured output files retain both the error banner and the summary.

---

## Claim 1: "'unsafe-eval' is added only when NODE_ENV !== \"production\""

**Location:** `proxy.ts:22-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the runtime effect of the `allowUnsafeEval` default parameter across NODE_ENV = production / test / development / undefined via the default-arg call path; does not cover whether Next.js's actual production bundle is eval-free (Claim 2).

The default parameter derives the flag from the environment:

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

Executed via a temporary vitest spec that calls `buildCsp(NONCE)` (default second arg) after overriding `process.env.NODE_ENV`. All five assertions passed: `production` yields `script-src 'self' 'nonce-n' 'strict-dynamic'` with **no** `'unsafe-eval'`; `test`, `development`, and `undefined` each append `'unsafe-eval'`; and in dev the token appears exactly once (scoped to `script-src`).

Command: `npx vitest run _factcheck_tmp.test.ts` · cwd `/workspace/external/cc-review-eval/mfc-postfix` · exit 1 (environmental, see note) · vitest summary `Tests 5 passed (5)` · 2026-08-18T06:55Z.

**Evidence:** `proxy.ts:26-32`, `runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/r1-buildcsp-nodeenv.txt`

---

## Claim 2: "Production output is genuinely eval-free"

**Location:** `proxy.ts:23`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only the assertion that the Next.js production bundle contains no `eval()`; does not affect Claim 1 (the CSP-construction behavior), which is independently Verified.

The comment justifies withholding `'unsafe-eval'` in production by asserting the production build emits no eval-based code (paraphrased — no quote available because the claim is about Next.js's compiled bundle output, which is not present in this source tree). Confirming it would require running `npm run build` and scanning the emitted chunks for `eval(` — framework build behavior outside the reviewable source. Not executed: the cost (full production build + bundle scan) exceeds this claim's criticality, and a wrong result would not be blocking-grade for a CSP-comment fact-check.

**Evidence:** `proxy.ts:22-24` (paraphrased — no quote available because the referenced artifact is the compiled production bundle, not repo source)

---

## Claim 3: "Pin the production CSP explicitly so these assertions don't depend on the ambient NODE_ENV the test runner happens to set"

**Location:** `proxy.test.ts:10-11`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `buildCsp(NONCE, false)` produces the production CSP independent of NODE_ENV and that the dev-scoping test asserts the `'unsafe-eval'` split; does not cover the env-derived default branch (that is Claim 4).

The suite pins the boolean explicitly (`const csp = buildCsp(NONCE, false);`, `proxy.test.ts:12`), so the "no eval/wildcard/http in production" assertions and the "allows 'unsafe-eval' only in development" assertion (`buildCsp(NONCE, true)`) do not read `process.env`. Running the committed suite passed all assertions.

Command: `npx vitest run proxy.test.ts` · cwd `/workspace/external/cc-review-eval/mfc-postfix` · exit 1 (environmental) · vitest summary `Test Files 1 passed (1)` · 2026-08-18T06:55Z.

**Evidence:** `proxy.test.ts:12`, `proxy.test.ts:30-46`, `runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/r1-proxy-test.txt`

---

## Claim 4: "The committed test suite exercises the env-derived default `buildCsp` call path"

**Location:** `proxy.test.ts` (whole file) / `proxy.ts:28`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether any committed test invokes `buildCsp` with the default second argument (thereby evaluating `process.env.NODE_ENV !== "production"`); does not assert the branch is untestable (my temporary spec exercised it — Claim 1).

This is the corollary of Claim 3's explicit pinning. Every committed `buildCsp` call site in the test passes an explicit boolean — `buildCsp(NONCE, false)` (`proxy.test.ts:12`) and `buildCsp(NONCE, true)` (`proxy.test.ts:37`). The only default-arg caller is production code `proxy()` at `proxy.ts:53` (`const csp = buildCsp(nonce);`), and no committed test renders `proxy()`. Therefore the env-derived default branch is **not** covered by the committed suite; it was covered only by my (now-deleted) temporary spec. Verdict "Verified" attaches to the fact of non-coverage, established by grep over the test file.

**Evidence:** `proxy.test.ts:12`, `proxy.test.ts:37`, `proxy.ts:53` (paraphrased — no quote available because the claim covers the absence of a default-arg call in the test file, an absence confirmed by grep)

---

## Claim 5: "allWorks holds at most PER_QUERY_RESULTS per query — worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25), fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit."

**Location:** `app/api/evidence-search/route.ts:178-180`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the maximum length of `allWorks` (the spread argument to `Math.max`) on both the override and LLM paths; does not cover deduplication or the final `MAX_RESULTS` cap applied afterward.

`PER_QUERY_RESULTS = 5` (`route.ts:20`) and is the OpenAlex `per_page` (`route.ts:114`), so each query contributes at most 5 works. Override path: `sanitizeQueries` caps at `MAX_OVERRIDE_QUERIES = 5` (`querySanitize.ts:9,20`) → 5 × 5 = 25. LLM path: `generateSearchQueries` returns `parsed.queries.slice(0, 3)` (`route.ts:94`) → ≤3 × 5 = 15. Both are far below V8's function argument-count ceiling (~65k), so the `Math.max(...allWorks.map(...))` spread at `route.ts:181` is safe.

**Evidence:** `app/api/evidence-search/route.ts:19-20`, `app/api/evidence-search/route.ts:94`, `app/api/evidence-search/route.ts:114`, `app/api/evidence-search/querySanitize.ts:9-20`

---

## Claim 6: "Persists to localStorage with debounced writes (see the debounced storage adapter below) to avoid excessive serialization on rapid updates."

**Location:** `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and behavior of the referenced debounced adapter; does not establish the 300ms window is optimal or that every write path routes through it.

The referenced adapter exists directly below and debounces `setItem` on a 300ms timer:

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
```

It is wired into the persist middleware via `createJSONStorage(() => debouncedStorage)` (`evidenceStore.ts:355-356`).

**Evidence:** `app/lib/stores/evidenceStore.ts:20-41`, `app/lib/stores/evidenceStore.ts:355-356`

---

## Claim 7: "Debounced localStorage adapter (same pattern as workspaceStore)"

**Location:** `app/lib/stores/evidenceStore.ts:17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that workspaceStore uses the same 300ms debounced-setTimeout localStorage adapter shape; does not compare persisted-key sets or migration logic between the two stores.

workspaceStore's default storage is `createDebouncedLocalStorage()` (`app/lib/corpus/storeAdapter.ts:37`, returned by `resolveWorkspaceStorage` at `storeAdapter.ts:110-114` and wired at `workspaceStore.ts:533`). That adapter uses the identical pattern — `if (pending) clearTimeout(pending); pending = setTimeout(() => {...}, 300)` (`storeAdapter.ts:42-50`) — and its own comment states it was "moved verbatim from workspaceStore.ts" (`storeAdapter.ts:33`). The residual comparison is accurate.

**Evidence:** `app/lib/corpus/storeAdapter.ts:33-53`, `app/lib/corpus/storeAdapter.ts:110-114`, `app/lib/stores/workspaceStore.ts:533`

---

## Claim 8: "During SSR, `storage` is `undefined` so the adapter is never called."

**Location:** `app/lib/stores/evidenceStore.ts:43-47`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the SSR guard on the persist `storage` config; does not cover `skipHydration`/hydration ordering on the client.

The persist config gates the storage on `window`:

```ts
// app/lib/stores/evidenceStore.ts:355-357
storage: typeof window !== "undefined"
  ? createJSONStorage(() => debouncedStorage)
  : undefined,
```

When `window` is undefined (SSR), `storage` is `undefined`, so zustand's persist middleware has no adapter to invoke — matching the comment.

**Evidence:** `app/lib/stores/evidenceStore.ts:355-357`

---

## Claim 9: "partial-JSON streaming can yield a tension object before its `between` tuple has arrived. Indexing `between[0]` on undefined threw a runtime TypeError that crashed the whole panel."

**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:44-46`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the pre-fix `t.between[0]` access throws `TypeError: Cannot read properties of undefined (reading '0')` when a tension lacks `between`, and that the shipped `t.between &&` guard prevents it; does not cover whether the streaming layer actually emits such partial tensions in production.

Two executions. (a) Committed test (guard present, `BalancedPerspectivesPanel.tsx:113` `{t.between && (`): both tests pass — `Tests 2 passed (2)`. (b) With the guard temporarily removed (reverting to bare `<span>{t.between[0]}</span>`), the "does not crash" test failed exactly as the comment predicts:

```
AssertionError: expected [Function] to not throw an error but
'TypeError: Cannot read properties of undefined (reading '0')' was thrown
```

The panel was restored via `git checkout` afterward (working tree clean).

Command (a): `npx vitest run app/components/panels/BalancedPerspectivesPanel.test.tsx` · cwd repo root · exit 1 (environmental) · summary `Tests 2 passed (2)` · 2026-08-18T06:55Z.
Command (b): same, after removing the `t.between &&` guard · summary `Tests 1 failed | 1 passed (2)` · 2026-08-18T06:56Z.

**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`, `runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/r1-balanced-test.txt`, `runs/review-arms/e8-evidence-pipeline/mfc-postfix/evidence/r1-regression-noguard.txt`

---

## Claim 10: "`between` absent mid-stream — the static type marks it required, so cast."

**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the `Tension` type declares `between` as a required (non-optional) tuple, justifying the `as unknown as Tension` cast; does not cover runtime schema validation.

The tension shape declares `between` as a required 2-tuple:

```ts
// app/lib/types/artifacts.ts:100
between: [string, string];
```

There is no `?` optional marker, so constructing a tension without `between` is a type error — the test's `as unknown as Tension` cast is required, exactly as the comment states.

**Evidence:** `app/lib/types/artifacts.ts:100`

---

## Claim 11: "Guard the endpoints row on `t.between` (matching the optional chaining already used for every other streamed field)"

**Location:** commit `c0e0a35` (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the added guard is "optional chaining"; does not dispute the fix's correctness (independently Verified in Claim 9).

The added guard is a JSX short-circuit / truthiness guard, not optional chaining:

```tsx
// app/components/panels/BalancedPerspectivesPanel.tsx:113
{t.between && (
```

The other top-level field guards it "matches" are likewise `&&` truthiness guards, not `?.` — e.g. `{displayMap.topic && (` (`BalancedPerspectivesPanel.tsx:46`), `{displayMap.summary && (` (`:56`), `{displayMap.synthesis && (` (`:129`). Optional chaining (`?.`) does appear elsewhere in the file, but for *nested* access (`displayMap.perspectives?.map`, `p.supportingArguments?.length`, `:66,78`), not for the presence guards the commit is comparing against. The practical conclusion — the new guard is consistent with the file's existing defensive pattern — is correct, but naming the construct "optional chaining" mischaracterizes both the added `&&` guard and the sibling guards. Precise wording: "matching the presence guards (`&&`) already used for every other streamed field."

**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:46`, `app/components/panels/BalancedPerspectivesPanel.tsx:56`, `app/components/panels/BalancedPerspectivesPanel.tsx:113`, `app/components/panels/BalancedPerspectivesPanel.tsx:129`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 11** (commit `c0e0a35`): the added `t.between &&` guard and the sibling field guards are `&&` truthiness guards, not "optional chaining" — reword the commit rationale to "presence guards (`&&`)".

### Unverifiable
- **Claim 2** (`proxy.ts:23`): "Production output is genuinely eval-free" — needs `npm run build` + a scan of the emitted bundles for `eval(`; framework build behavior not present in source.
