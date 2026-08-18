# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-postfix (meta-formalism-copilot)
**Commit:** 7f30210
**Replication:** k=2
**Scope:** Checkable claims in files changed in `git diff 9c9edf5...HEAD` — `proxy.ts`, `proxy.test.ts`, `app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx`, `app/components/panels/BalancedPerspectivesPanel.test.tsx`, and the two changed commit messages (`2e23824`, `c0e0a35`).
**Checked:** 2026-08-18
**Total claims checked:** 13
**Summary:** 10 verified, 1 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Merge note: this is a k=2 merge (adapted from the k=3 protocol) of `code-fact-check-report-r1.md` and `code-fact-check-report-r2.md`. Most-severe-wins across clustered claims; per-replicate verdicts recorded on every claim; claims surfaced by only one replicate are marked `single-replicate detection`. Both replicates recorded that vitest process exit code 1 is an environmental artifact — an empty `/workspace/external/package.json` (0 bytes) makes vitest's dependency probe throw `ERR_INVALID_PACKAGE_CONFIG` while the suite still runs to completion; pass/fail is read from vitest's own `Tests N passed` summary, not the process exit code.

---

## Claim 1: "'unsafe-eval' is added only when NODE_ENV !== \"production\""

**Location:** `proxy.ts:21-24`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers the runtime effect of the `allowUnsafeEval` default parameter across NODE_ENV values (production, test, staging, development, undefined) via the default-arg call path; does not establish that the production *build output* is in fact eval-free (that atom is Claim 2).

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

Both replicates executed a scratch vitest calling `buildCsp(NONCE)` (default second arg) with `process.env.NODE_ENV` mutated per case, and both got the same result: `production` yields no `'unsafe-eval'`; `test`, `development`, `staging`, and `undefined` each append it exactly once (scoped to `script-src`). The mechanism is a strict `!== "production"` check, so the **fail-open is real**: any value other than the exact string `"production"` — including unset/undefined and unexpected values like `"staging"` — adds `'unsafe-eval'`. This matches the comment's stated rule.

Command (both replicates): `npx vitest run` of a temporary spec · cwd `/workspace/external/cc-review-eval/mfc-postfix` · exit 1 (environmental, see merge note) · vitest summary `Tests 5 passed (5)` · 2026-08-18.

**Evidence:** `proxy.ts:26-32`, `./evidence/r1-buildcsp-nodeenv.txt`, `./evidence/r2-buildcsp-env-default.txt`

---

## Claim 2: "Production output is genuinely eval-free"

**Location:** `proxy.ts:22-24`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Replicate verdicts:** r1=Unverifiable · r2=Verified (folded into r2 Claim 1, whose Scope explicitly excluded establishing this — see reconciliation)
**Scope:** Covers only the assertion that the Next.js production bundle contains no `eval()`; does not affect Claim 1 (the CSP-construction behavior), which is independently Verified.

The comment justifies withholding `'unsafe-eval'` in production by asserting the production build emits no eval-based code (paraphrased — no quote available because the referenced artifact is the compiled production bundle, not repo source). r1 verdicted this atom **Unverifiable**: confirming it would require running `npm run build` and scanning the emitted chunks for `eval(` — framework build behavior outside the reviewable source. r2 did not surface it as a separate claim but folded it into its own Claim 1 and explicitly scoped that Verified verdict to *not* establish the production build is eval-free. Per the compound/atomic reconciliation rule (decision 033), the compound clusters with each of its parts and most-severe-wins governs: Unverifiable outranks Verified, so this atom carries **Unverifiable**. The two replicates agree in substance that the bundle-level property was not established.

**Evidence:** `proxy.ts:22-24` (paraphrased — no quote available because the referenced artifact is the compiled production bundle, not repo source)

---

## Claim 3: "form-action does NOT fall back to default-src (CSP3); set explicitly."

**Location:** `proxy.ts:43`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection
**Scope:** Covers whether `form-action` is emitted explicitly in the directive list and the CSP3 fallback behavior it cites; does not test browser enforcement.

`form-action 'self'` is present as an explicit entry in the directive array:

```ts
// proxy.ts:43-44
// form-action does NOT fall back to default-src (CSP3); set explicitly.
"form-action 'self'",
```

Under CSP Level 3, `form-action` is a navigation directive that is not in the fetch-directive set that falls back to `default-src`; without an explicit `form-action`, form submissions are unrestricted. The code sets it explicitly, as the comment states.

**Evidence:** `proxy.ts:33-45`

---

## Claim 4: "Pin the production CSP explicitly so these assertions don't depend on the ambient NODE_ENV the test runner happens to set."

**Location:** `proxy.test.ts:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers whether passing `false` as the second argument decouples the "no eval/wildcard/http in production" assertions from NODE_ENV; does not cover the env-derived default branch (Claim 5).

The test pins the boolean explicitly:

```ts
// proxy.test.ts:12
const csp = buildCsp(NONCE, false);
```

Because the explicit argument overrides the `process.env.NODE_ENV !== "production"` default (`proxy.ts:28`), the resulting CSP is the production (eval-free) variant regardless of the runner's ambient NODE_ENV, and the dev-scoping assertion uses `buildCsp(NONCE, true)`. Running the committed suite passed all assertions.

**Evidence:** `proxy.test.ts:10-12`, `proxy.ts:26-32`, `./evidence/r1-proxy-test.txt`

---

## Claim 5: "The committed test suite covers `buildCsp`'s default (NODE_ENV-derived) `allowUnsafeEval` path."

**Location:** `proxy.test.ts:12,37` (call sites) vs. `proxy.ts:53` (production call site)
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Incorrect
**Scope:** Covers whether any committed test exercises the single-argument `buildCsp(nonce)` default-parameter branch (the branch `proxy.ts:53` depends on); the two output shapes (with/without `'unsafe-eval'`) *are* covered via explicit `false`/`true` arguments — only the env→boolean derivation is untested.

Both replicates agree on the underlying reality: the only default-arg caller is production code `proxy()` at `proxy.ts:53` (`const csp = buildCsp(nonce);`), while every committed test passes the second argument explicitly — `buildCsp(NONCE, false)` (`proxy.test.ts:12`) and `buildCsp(NONCE, true)` (`proxy.test.ts:37`) — so the NODE_ENV-reading branch is not exercised by the suite.

```ts
// proxy.ts:53
const csp = buildCsp(nonce);
```

The replicates diverged only on framing. r1 verdicted "Verified", attaching the verdict to the *fact of non-coverage* it established by grep. r2 verdicted the doc/coverage assertion itself — "the committed suite covers the default path" — as **Incorrect**, since the suite does not cover it. Per most-severe-wins the merged verdict is **Incorrect**: a reader who believes the env-derivation branch is tested is misled. Fix: add a test that stubs `process.env.NODE_ENV` and calls `buildCsp(nonce)` with the default parameter.

**Evidence:** `proxy.ts:53`, `proxy.test.ts:12`, `proxy.test.ts:37`, `./evidence/r2-committed-tests.txt`, `./evidence/r1-buildcsp-nodeenv.txt`

---

## Claim 6: "allWorks holds at most PER_QUERY_RESULTS per query — worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25), fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit."

**Location:** `app/api/evidence-search/route.ts:178-180`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers the code-controlled bounds on `allWorks.length` (query-count caps and the per-query request size) feeding `Math.max(...allWorks.map(...))` — the query-count bound is what is checked; does NOT establish behavior if the upstream OpenAlex API returns more results than the `per_page` parameter requested (external service behavior, not executable here), and does not cover deduplication or the final `MAX_RESULTS` cap applied afterward.

`PER_QUERY_RESULTS = 5` (`route.ts:20`) is set as the OpenAlex `per_page` (`route.ts:114`), so each query is *requested* to contribute at most 5 works:

```ts
// route.ts:20
const PER_QUERY_RESULTS = 5;
// route.ts:114
url.searchParams.set("per_page", String(PER_QUERY_RESULTS));
```

Query count is bounded on both paths: the override path is capped by `MAX_OVERRIDE_QUERIES = 5` in the sanitizer (`querySanitize.ts:9,21`), and the LLM path by `parsed.queries.slice(0, 3)` (`route.ts:94`). So `allWorks` ≤ 5×5 = 25 (override) or ≤ 3×5 = 15 (LLM), and `Math.max(...allWorks.map(...))` (`route.ts:181`) spreads at most 25 arguments — far below V8's argument-count ceiling (tens of thousands). The arithmetic and both worst-case figures are correct. The spread runs before the final `.slice(0, MAX_RESULTS)`, which does not affect spread size.

**Evidence:** `app/api/evidence-search/route.ts:19-20`, `:94`, `:114`, `:126`, `:166-186`, `app/api/evidence-search/querySanitize.ts:9-21`

---

## Claim 7: "Persists to localStorage with debounced writes (see the debounced storage adapter below) to avoid excessive serialization on rapid updates."

**Location:** `app/lib/stores/evidenceStore.ts:8-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers the existence and behavior of the referenced debounced adapter and its wiring into the persist middleware; does not establish the 300ms window is optimal or that every write path routes through it.

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

It is wired into the persist middleware via `createJSONStorage(() => debouncedStorage)` (`evidenceStore.ts:355-356`). The "debounced writes … to avoid excessive serialization" matches the coalescing timer.

**Evidence:** `app/lib/stores/evidenceStore.ts:20-41`, `:355-357`

---

## Claim 8: "Debounced localStorage adapter (same pattern as workspaceStore)"

**Location:** `app/lib/stores/evidenceStore.ts:16-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers that workspaceStore uses the same 300ms debounced-setTimeout localStorage adapter shape; does not assert byte-identical code, and does not compare persisted-key sets or migration logic between the two stores.

workspaceStore's default persist storage resolves to `createDebouncedLocalStorage`, whose `setItem` is the identical 300ms coalescing pattern:

```ts
// app/lib/corpus/storeAdapter.ts:41-51
setItem: (name, value) => {
  if (pending) clearTimeout(pending);
  pending = setTimeout(() => {
    try { localStorage.setItem(name, value); } …
  }, 300);
},
```

`workspaceStore.ts:533` wires it via `storage: createJSONStorage(resolveWorkspaceStorage)`, and `resolveWorkspaceStorage` returns `createDebouncedLocalStorage()` on the default (flag-off) path (`storeAdapter.ts:110-114`). r1 additionally noted the adapter's own comment states it was "moved verbatim from workspaceStore.ts" (`storeAdapter.ts:33`). The pattern is identical even though the workspace adapter now lives in `corpus/storeAdapter.ts` rather than inline in `workspaceStore.ts`, so the residual comparison is accurate.

**Evidence:** `app/lib/stores/evidenceStore.ts:16-33`, `app/lib/corpus/storeAdapter.ts:33-58`, `:110-114`, `app/lib/stores/workspaceStore.ts:533`

---

## Claim 9: "During SSR, `storage` is `undefined` so the adapter is never called."

**Location:** `app/lib/stores/evidenceStore.ts:43-47`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection
**Scope:** Covers the SSR guard on the persist `storage` config; does not cover `skipHydration`/hydration ordering on the client.

The persist config gates the storage on `window`:

```ts
// app/lib/stores/evidenceStore.ts:355-357
storage: typeof window !== "undefined"
  ? createJSONStorage(() => debouncedStorage)
  : undefined,
```

When `window` is undefined (SSR), `storage` is `undefined`, so zustand's persist middleware has no adapter to invoke — matching the comment. (r2 quoted the same snippet inside its Claim 6 but explicitly scoped that verdict to *not* cover the SSR-guard path; only r1 verdicted this claim, hence single-replicate.)

**Evidence:** `app/lib/stores/evidenceStore.ts:355-357`

---

## Claim 10: "Partial map data from streaming (partial-JSON parsed)"

**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:12-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection
**Scope:** Covers that `streamingPreview` is typed as the complete artifact type and used as a fallback display source; does not verify that the upstream producer actually emits partial-JSON parses (that producer is outside the changed files).

`streamingPreview` is declared with the full artifact type and fed to `mergeStreamingPreview` as the fallback display source:

```tsx
// BalancedPerspectivesPanel.tsx:12-13
/** Partial map data from streaming (partial-JSON parsed) */
streamingPreview?: BalancedPerspectivesResponse["balancedPerspectives"] | null;
```

`mergeStreamingPreview<T>` returns `finalData ?? streamingPreview ?? null` (`app/lib/utils/mergeStreamingPreview.ts:13`), typing the partial preview as a complete `T` — which is precisely why the runtime guards (Claim 11) are needed. Medium confidence because "partial-JSON parsed" describes an upstream producer not present in the changed files.

**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:12-28`, `app/lib/utils/mergeStreamingPreview.ts:8-16`

---

## Claim 11: "partial-JSON streaming can yield a tension object before its `between` tuple has arrived. Indexing `between[0]` on undefined threw a runtime TypeError that crashed the whole panel."

**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:44-50`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified
**Scope:** Covers that indexing `t.between[0]` when `between` is undefined throws `TypeError: Cannot read properties of undefined (reading '0')`, that the shipped `{t.between && …}` guard prevents the crash, and (r2) that no error boundary would have contained it; does not reproduce the exact upstream partial-JSON stream that produces a `between`-less tension in production.

The type marks `between` required, but a partial stream can deliver a tension without it. The diff wraps the endpoint row in a presence guard:

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

Both replicates executed the reproduction. r1 removed the `t.between &&` guard and observed the "does not crash" test fail exactly as predicted (`AssertionError: expected [Function] to not throw … 'TypeError: Cannot read properties of undefined (reading '0')' was thrown`), then restored the panel via `git checkout`. r2 independently reproduced the TypeError mechanism and confirmed the committed guarded test passes; r2 also searched for error boundaries (`componentDidCatch|ErrorBoundary|getDerivedStateFromError` across `app/`) and found zero hits, so an uncaught render throw would propagate and unmount the tree — "crashed the whole panel" is accurate.

Commands: r1 `npx vitest run app/components/panels/BalancedPerspectivesPanel.test.tsx` (guarded: `Tests 2 passed (2)`; no-guard: `Tests 1 failed | 1 passed (2)`) · exit 1 (environmental) · 2026-08-18. r2 equivalent runs captured in its evidence files.

**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`, `app/lib/types/artifacts.ts:99-102`, `./evidence/r1-balanced-test.txt`, `./evidence/r1-regression-noguard.txt`, `./evidence/r2-between-index-typeerror.txt`, `./evidence/r2-committed-tests.txt`

---

## Claim 12: "`between` absent mid-stream — the static type marks it required, so cast."

**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection
**Scope:** Covers that the `Tension` type declares `between` as a required (non-optional) tuple, justifying the `as unknown as Tension` cast; does not cover runtime schema validation.

The tension shape declares `between` as a required 2-tuple:

```ts
// app/lib/types/artifacts.ts:100
between: [string, string];
```

There is no `?` optional marker, so constructing a tension without `between` is a type error — the test's `as unknown as Tension` cast is required, exactly as the comment states. (r2 established the same "type marks `between` required" fact inside its Claim 9, but only r1 verdicted the cast-justification comment as its own claim, hence single-replicate.)

**Evidence:** `app/lib/types/artifacts.ts:100`

---

## Claim 13: "Guard the endpoints row on `t.between` (matching the optional chaining already used for every other streamed field)"

**Location:** commit `c0e0a35` (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Mostly accurate · r2=— (non-finding: no referent located) · single-replicate detection
**Scope:** Covers whether the added guard, and the sibling field guards it claims to match, are "optional chaining"; does not dispute the fix's correctness (independently Verified in Claim 11).

The added guard is a JSX short-circuit / truthiness guard, not optional chaining:

```tsx
// app/components/panels/BalancedPerspectivesPanel.tsx:113
{t.between && (
```

r1 found the sibling top-level field guards are likewise `&&` truthiness guards, not `?.` — e.g. `{displayMap.topic && (` (`:46`), `{displayMap.summary && (` (`:56`), `{displayMap.synthesis && (` (`:129`). Optional chaining (`?.`) appears elsewhere in the file but only for *nested* access (`displayMap.perspectives?.map`, `p.supportingArguments?.length`), not for these presence guards. The practical conclusion — the new guard is consistent with the file's existing defensive pattern — is correct, but naming the construct "optional chaining" mischaracterizes both the added `&&` guard and the sibling guards. Precise wording: "matching the presence guards (`&&`) already used for every other streamed field."

Divergence noted: r2 ran a repo-wide search (`rg "optional chain"` over the diff files and all of `app/`) and reported zero hits, concluding there was "no such comment claim to verdict" — i.e., r2 did not locate the referent (the commit-message body of `c0e0a35`) that r1 checked. The merged claim carries r1's Mostly-accurate verdict and evidence; r2's non-finding is recorded for audit.

**Evidence:** `app/components/panels/BalancedPerspectivesPanel.tsx:46`, `:56`, `:113`, `:129`

---

## Verdict stability

- **Total merged claims (clusters):** 13
- **Two-replicate clusters (both reporting):** 8 — Claims 1, 2, 4, 5, 6, 7, 8, 11
- **Single-replicate detections:** 5 — Claims 3 (r2), 9 (r1), 10 (r2), 12 (r1), 13 (r1)
- **Two-replicate clusters in full agreement:** 6 (Claims 1, 4, 6, 7, 8, 11)
- **Two-replicate clusters with divergence:** 2
  - **Claim 5** (`proxy.test.ts` default-path coverage): r1=Verified · r2=Incorrect. Both replicates agree the env-derivation branch is uncovered; r2 framed the coverage assertion itself as Incorrect. Resolved most-severe-wins → **Incorrect**.
  - **Claim 2** (`proxy.ts` production eval-free): r1=Unverifiable · r2=Verified-but-scoped-out (compound/atomic split, decision 033). r2's Verified explicitly excluded establishing the bundle is eval-free, so the replicates agree in substance. Resolved most-severe-wins → **Unverifiable**.
- **Agreement rate on multi-reporting clusters:** 6/8 = 75%.

Note: both divergences resolved by escalation to the more-severe (Claim 5) or more-conservative (Claim 2) verdict; neither replicate proved a defect the other refuted — the divergences are framing/atomization differences, not contradictory evidence.
</content>
</invoke>
