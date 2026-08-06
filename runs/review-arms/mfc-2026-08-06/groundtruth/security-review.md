# Security Review — meta-formalism-copilot `HEAD~3..HEAD` (post-review fix batch on integration/6.1)

Commit: 7f30210
**Scope:** `git diff HEAD~3..HEAD` — 4d5f743 (comment fixes), 2e23824 (dev-only CSP `'unsafe-eval'`), c0e0a35 (streaming crash guard + test), merge 7f30210. Files: `proxy.ts`, `proxy.test.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx`, `app/components/panels/BalancedPerspectivesPanel.test.tsx`, `app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`.
**Date:** 2026-08-06
**Based on:** code-fact-check report (k=3 merged) — 0 Incorrect, 0 Stale; attention items on the `connect-src` rationale, the `NODE_ENV !== "production"` polarity, and the `allowUnsafeEval` public-parameter escalation. Documented behavior from that report is taken as given and not re-verified.

No HALT-ESCALATE conditions were detected: no plaintext credentials, no unauthenticated privileged endpoint added, no SQL/command injection, no TLS/cert-verification disablement, no hardcoded keys in this range.

---

## Trust Boundary Map

```
B1: Server env (process.env.NODE_ENV at build/run)
      → proxy.ts:28 default-parameter evaluation in buildCsp
      → Content-Security-Policy header on every page navigation (browser enforcement point)   (modified)

B2: Browser DOM / any injected script in a page
      → the CSP script-src directive emitted by B1
      → JS execution privilege in the app origin   (weakened in non-production builds)

B3: Client HTTP POST body (untrusted: body.queries, body.elementContent)
      → app/api/evidence-search/route.ts:160 sanitizeQueries / :156 length cap
      → outbound OpenAlex request URL (route.ts:113-115) and OpenRouter/Anthropic LLM prompt

B4: OpenAlex HTTP response (third-party, semi-trusted)
      → route.ts:125 `res.json()` + `as OpenAlexWork[]` cast, no shape or length validation
      → allWorks array → `Math.max(...)` spread at route.ts:181 → API response body

B5: LLM streaming output (partial-JSON parsed, structurally untrusted)
      → mergeStreamingPreview → BalancedPerspectivesPanel.tsx:110-120 render
      → React DOM (text children only; no HTML sink)   (guard added)

B6: Browser (corpus git worker, dev-only) → app/lib/corpus/gitCore.ts:203-218 push/pull with onAuth
      → user-configured `remoteUrl` (arbitrary third-party host)   (context only — not in this diff)
```

The diff's centre of gravity is B1→B2: an environment variable now controls whether the strongest script-execution restriction in the app is present. Everything else in the range is either a hardening of B5 (the streaming crash guard) or a comment change describing B3/B4 without altering enforcement. B6 is the boundary the `connect-src` docstring — extended in this diff — does not mention.

---

## Findings

#### F1. `'unsafe-eval'` gate is fail-open: any non-`"production"` NODE_ENV ships it

**Severity:** Medium
**Location:** `proxy.ts:26-32`
**Boundary:** B1 → B2
**Move:** 5 (invert the access-control model — enumerate the uncovered cases)
**Confidence:** High (behavior) / Medium (real-world exposure)
**Evidence:**
> ```ts
> export function buildCsp(
>   nonce: string,
>   allowUnsafeEval: boolean = process.env.NODE_ENV !== "production",
> ): string {
> ```

The predicate is allow-by-default: it enumerates the one value that turns the relaxation *off* and grants `'unsafe-eval'` for every other value — unset, `"test"`, `"staging"`, `"qa"`, or any custom string. A team that builds a publicly reachable pre-production environment with `NODE_ENV=staging next build`, or that self-hosts via `next build --output standalone` and runs `node server.js` without exporting `NODE_ENV`, gets a real, internet-reachable deployment whose CSP permits `eval()` — silently, with no warning and no failing test. The documented Vercel path (README:99-105) does set `NODE_ENV=production` at build, so the shipped happy path is safe; the failure mode is a deployment variant, which is exactly the case a fail-open default should not decide by omission. The repo already contains the correct polarity for the same class of dev-only gate: `app/lib/corpus/flag.ts:21` refuses when `NODE_ENV === "production"` — that guard is fail-*closed* against enablement, and this one is not.
**Recommendation:** Invert to an explicit allowlist: `process.env.NODE_ENV === "development"`. If the test environment genuinely needs the dev CSP, name it (`["development", "test"].includes(...)`) rather than falling through by default.
**Legibility-target:** for-author

---

#### F2. The no-`'unsafe-eval'` regression test no longer covers the shipped call path

**Severity:** Medium
**Location:** `proxy.test.ts:9-12`, `proxy.test.ts:30-32`; call path `proxy.ts:53`
**Boundary:** B1 → B2
**Move:** 3 (check the path that isn't the happy path) / 5
**Confidence:** High
**Evidence:**
> ```ts
> // Pin the production CSP explicitly so these assertions don't depend on the
> // ambient NODE_ENV the test runner happens to set.
> const csp = buildCsp(NONCE, false);
> ```
> ```ts
>   it("does not allow eval, wildcards, or http: schemes in production", () => {
>     expect(csp).not.toMatch(/'unsafe-eval'/);
> ```

Before this change, the guard test exercised the same one-argument call the proxy actually makes (`buildCsp(nonce)`, `proxy.ts:53`) and would have failed if the production CSP ever gained `'unsafe-eval'`. After it, every assertion runs against an explicitly-pinned `false`, so the test now verifies the *formatting* of the flag rather than the *policy decision* that selects it. If the default expression at `proxy.ts:28` were later broadened — inverted polarity, a typo'd env name, or hard-coded `true` — the suite stays green. The file's own header comment ("updating this test is the explicit acknowledgement") describes a tripwire that this edit disconnected from the wire. Note that this is the security-relevant consequence of an otherwise reasonable fix: the pin does correctly remove ambient-`NODE_ENV` flakiness.
**Recommendation:** Keep the pinned cases and add one that exercises the default-argument path under a stubbed production env — `vi.stubEnv("NODE_ENV", "production")` then assert `buildCsp(NONCE)` contains no `'unsafe-eval'`; ideally add the mirror case asserting a `"staging"` value also excludes it, which would fail today and pin F1's fix.
**Legibility-target:** for-author

---

#### F3. `allowUnsafeEval` is a public parameter whose "dev-only" property rests on a single call site

**Severity:** Low
**Location:** `proxy.ts:26-32`, `proxy.ts:53`
**Boundary:** B1 → B2
**Move:** 1 (a trust boundary was moved without being made explicit)
**Confidence:** High
**Evidence:**
> ```ts
> const scriptSrc = `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${
>   allowUnsafeEval ? " 'unsafe-eval'" : ""
> }`;
> ```
> ```ts
>   const csp = buildCsp(nonce);
> ```

`buildCsp` is exported (for testability) and now takes environment sensitivity as an *overridable* argument. The invariant "`'unsafe-eval'` only in dev" is therefore not a property of the function — it is a property of the fact that exactly one runtime caller exists and it omits the argument. Any future caller (a second proxy matcher, a route handler emitting its own CSP, a preview-mode branch) that passes `true`, or that copies the test file's two-argument form, ships eval-permissive CSP to production with no signal. The docstring asserts the invariant in prose but nothing enforces it. This is defense-in-depth rather than a live vulnerability, and it compounds F1 and F2: with the default fail-open and the default path untested, the parameter is the third independent way this policy can be wrong without anything noticing.
**Recommendation:** Either make the parameter non-overridable in production (`allowUnsafeEval && process.env.NODE_ENV !== "production"` inside the body, so an explicit `true` still cannot escape), or keep the parameter test-only and mark it clearly (e.g. `/** @internal — test seam; production callers must omit */`).
**Legibility-target:** for-author

---

#### F4. Development CSP loses `eval` protection on the environment that handles the least-trusted inputs

**Severity:** Low
**Location:** `proxy.ts:21-32`
**Boundary:** B2
**Move:** 2 (implicit sanitization assumption) / 3
**Confidence:** Medium
**Evidence:**
> ```
>  * Why `allowUnsafeEval` in development only: Next.js's dev server (HMR + eval
>  * source maps) injects `eval()`-based code that a strict CSP blocks, flooding
>  * the browser console with EvalErrors.
> ```

Development is where uploaded `.docx`/PDF documents (`mammoth`, `pdfjs-dist`), arbitrary LLM output, and the dev-only corpus/git paths are exercised most aggressively, and it is now the environment with the weakest script policy. The mitigating facts are substantial and worth stating: a grep of `app/` finds **no** `dangerouslySetInnerHTML` or `innerHTML` sink, markdown is rendered by `react-markdown` without `rehype-raw`, and `'strict-dynamic'` plus the per-request nonce still block injected `<script>` tags — so `'unsafe-eval'` alone is not an exploitable path, it is the removal of a backstop. The residual risk is that `next dev` bound to a non-loopback interface (`-H 0.0.0.0`, common in WSL/devcontainer setups, which this repo's environment is) exposes that weakened origin to the local network, where the dev browser holds all workspace localStorage content.
**Recommendation:** Accept, but note in the docstring that the relaxation assumes `next dev` stays bound to loopback. No code change required.
**Legibility-target:** for-author

---

#### F5. Spread-safety comment asserts a bound that only the third party enforces

**Severity:** Low
**Location:** `app/api/evidence-search/route.ts:175-181`; source of the unbounded value at `route.ts:114`, `route.ts:125`, `route.ts:171`
**Boundary:** B4
**Move:** 2 (implicit sanitization assumption) / 8 (what if there are a million of these)
**Confidence:** Medium
**Evidence:**
> ```ts
>     // Safe to spread: allWorks holds at most PER_QUERY_RESULTS per query —
>     // worst case MAX_OVERRIDE_QUERIES (5) queries on the override path (25),
>     // fewer on the LLM path (≤3 queries → 15). Well under the arg-count limit.
>     const topScore = Math.max(...allWorks.map((w) => w.relevance_score ?? 0), 1);
> ```
> ```ts
>     const data = await res.json();
>     return (data.results ?? []) as OpenAlexWork[];
> ```

The query-count half of the claim is enforced locally and correct (`querySanitize.ts:20` breaks at `MAX_OVERRIDE_QUERIES = 5`). The per-query half is not: `PER_QUERY_RESULTS` is sent to OpenAlex as a `per_page` *request* parameter, and the response is consumed with `data.results ?? []` cast straight to `OpenAlexWork[]` with no length check and no shape validation. The stated bound of 25 is therefore a property of OpenAlex's behavior, not of this code — an API change, an error envelope shaped differently, or a compromised/impersonated upstream yields an unbounded array, and `Math.max(...allWorks…)` on a large enough array throws `RangeError: Maximum call stack size exceeded`, converted by the catch block into a 500. This commit's purpose was to make the safety argument more precise; it makes the argument tighter without making the bound enforceable, which is the failure mode where a comment increases false confidence. Impact is a self-inflicted 500 on one route, not data exposure — hence Low.
**Recommendation:** Make the comment true by construction: `allWorks.push(...result.value.slice(0, PER_QUERY_RESULTS))` at route.ts:171, or replace the spread with a `reduce`, which removes the argument-count concern entirely and makes the comment unnecessary.
**Legibility-target:** for-author

---

#### F6. Override queries can inject additional OpenAlex filter clauses

**Severity:** Low
**Location:** `app/api/evidence-search/route.ts:113`; sanitizer at `app/api/evidence-search/querySanitize.ts:13-23`
**Boundary:** B3
**Move:** 2 (format-but-not-content validation)
**Confidence:** Medium
**Evidence:**
> ```ts
>     url.searchParams.set("filter", `title_and_abstract.search:${query}`);
> ```
> ```ts
>     const trimmed = entry.trim().slice(0, MAX_QUERY_LENGTH);
>     if (trimmed.length > 0) cleaned.push(trimmed);
> ```

`sanitizeQueries` validates *shape* — type, emptiness, length, count — but not *content*, and the value is then interpolated into OpenAlex's filter mini-DSL, where `,` separates AND-clauses and `|` separates OR-clauses. A query of `x,is_oa:true` or `x|y` is URL-encoded correctly by `searchParams` (so this is not URL injection) but is parsed by OpenAlex as extra filter terms, letting a caller steer the upstream query beyond the intended `title_and_abstract.search` predicate. Impact is genuinely small: OpenAlex is a public, read-only, unauthenticated corpus, the caller is already choosing the search text, and `per_page` still bounds the response — the realistic outcome is confusing results rather than disclosure. Flagged because the sanitizer's own docstring claims it "bounds untrusted input before it is sent to OpenAlex," which reads as stronger than what it does. This is sibling context, not code changed in this range; the changed comment two lines away is what put the sanitizer's guarantees in scope.
**Recommendation:** Strip or reject `,`, `|`, and `:` in `sanitizeQueries`, and amend its docstring to say it bounds size and type only.
**Legibility-target:** for-author

---

#### F7. Streaming guard is a truthiness check, not a shape check

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`
**Boundary:** B5
**Move:** 7 (test the serialization boundary — verify-shape or cast-and-hope)
**Confidence:** Medium
**Evidence:**
> ```tsx
>                       {t.between && (
>                         <div className="flex items-center gap-1 text-xs font-mono text-red-700">
>                           <span>{t.between[0]}</span>
>                           <span className="text-red-400">&harr;</span>
>                           <span>{t.between[1]}</span>
>                         </div>
>                       )}
> ```

The fix correctly closes the reported crash (`between` absent mid-stream) and the new regression test pins it. It does not close the adjacent cases a partial-JSON parser over model output can also produce, because the condition only asks "is this truthy," then indexes. `between: "AB"` (a string arriving before the array does, or a model emitting the wrong type) renders as `A ↔ B` — wrong data, silently. `between: [{…}]` — an object where a string was expected — still throws *Objects are not valid as a React child*, reproducing exactly the whole-panel crash this commit set out to prevent. This is an availability/robustness concern at a structurally-untrusted boundary rather than an exploitable vulnerability; there is no HTML sink here and React escapes all text children, so no XSS path exists. Worth noting that the guard is the only such index-into-streamed-array in the panels directory (grep across `app/components/panels/*.tsx` finds no sibling occurrences), so this is not a systemic gap.
**Recommendation:** If cheap, tighten to `Array.isArray(t.between) && typeof t.between[0] === "string"`, or render via a small `String(x ?? "")` coercion. Otherwise accept and record the residual.
**Legibility-target:** for-author

---

#### F8. Extended `connect-src` rationale omits the corpus git worker's browser-context third-party egress

**Severity:** Informational
**Location:** `proxy.ts:17-24`; omitted path at `app/lib/corpus/gitWorker.ts:33`, `app/lib/corpus/gitCore.ts:203-218`
**Boundary:** B6 (unmentioned) vs. the docstring's claim about B2
**Move:** 1 (map the trust boundaries — a boundary exists that the doc says does not)
**Confidence:** High (per fact-check finding; not re-verified)
**Evidence:**
> ```
>  * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter
>  * calls are server-to-server (Next API routes), not browser-to-third-party.
> ```
> ```ts
>         await git.push({ fs, http, dir, url: remoteUrl, onAuth });
> ```

This commit extended this docstring block with the `allowUnsafeEval` paragraph, leaving the adjacent "not browser-to-third-party" claim standing while the DD-009 corpus worker does exactly that: `isomorphic-git`'s web HTTP client pushing and pulling from a user-configured `remoteUrl` inside a Web Worker, with credentials supplied via `onAuth`. The claim is true of shipped defaults (the corpus path is gated off in production by `app/lib/corpus/flag.ts:21`), so nothing is currently exposed. The security consequence is directional: the corpus feature is currently *broken* under `connect-src 'self'` in dev, and the next engineer who debugs that will read this docstring, see no reason `connect-src` is tight, and is likely to widen it to `*` or `https:` to unblock themselves — turning a correct restriction into a permanent hole. Separately, the browser-side flow sends credentials to a user-supplied URL, which deserves its own review when the flag graduates.
**Recommendation:** Add one sentence: "Exception: the dev-only corpus git worker (DD-009) makes browser→remote requests; it is gated off in production by `corpus/flag.ts`. If that flag graduates, `connect-src` must be revisited deliberately — do not widen it ad hoc."
**Legibility-target:** for-author

---

#### F9. Coverage note — the touched API route remains unauthenticated and unthrottled

**Severity:** Informational
**Location:** `app/api/evidence-search/route.ts:141-160`; matcher exclusion at `proxy.ts:74-81`
**Boundary:** B3
**Move:** 8 (what if there are a million of these)
**Confidence:** High
**Evidence:**
> ```ts
>   matcher: [
>     {
>       source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
> ```
> ```ts
>     const override = sanitizeQueries(body.queries);
>     const queries =
>       override.length > 0
>         ? override
>         : await generateSearchQueries(elementContent, body.contextSummary);
> ```

Recorded for synthesis, not as an action item for this diff. `POST /api/evidence-search` performs a billable LLM call plus up to five outbound third-party requests per invocation, with no authentication, no rate limit, and no CSP (API routes are excluded from the proxy matcher by design). Anyone who can reach a deployed instance can drive the owner's Anthropic/OpenRouter spend and the app's OpenAlex polite-pool reputation. This is consistent with the project's stated model — README:7, "Each user runs their own copy with their own LLM provider key" — so it is a documented posture rather than a defect, and the per-request caps (`MAX_ELEMENT_CONTENT_LENGTH`, `MAX_OVERRIDE_QUERIES`, `OPENALEX_TIMEOUT_MS`) bound each call's cost. It belongs in the synthesis because two findings in this range (F5, F6) sit on this route's input path and their severity would rise materially if the deployment model ever became multi-tenant or publicly linked.
**Recommendation:** No change now. If the deploy model changes, add a per-IP throttle in front of the LLM call before anything else.
**Legibility-target:** for-orchestrator-synthesis

---

## What Looks Good

- **The nonce itself is done right.** `crypto.getRandomValues(new Uint8Array(16))` (`proxy.ts:52`) is a CSPRNG with 128 bits of entropy, generated fresh per request, and the value flows to server components via a request header rather than a shared module-level variable — no cross-request reuse, no `Math.random()`. `'strict-dynamic'` plus that nonce remains the load-bearing control even in the relaxed dev configuration.
- **`'unsafe-eval'` is correctly scoped.** The relaxation is built into the `script-src` string only, and `proxy.test.ts:38-46` explicitly asserts `devCsp.match(/'unsafe-eval'/g)` has length exactly 1 — a well-chosen test that pins the *containment* property, not just the presence. `default-src`, `object-src 'none'`, `base-uri`, `frame-ancestors 'none'`, and `form-action 'self'` are all untouched.
- **The relaxation is scoped to the weakest directive available.** `'unsafe-eval'` does not permit new script *sources*; combined with an intact nonce+`strict-dynamic` policy and the repo's complete absence of `dangerouslySetInnerHTML`/`innerHTML` sinks, there is no realistic injection path this change opens on its own.
- **The crash-guard commit is properly evidenced.** The regression test (`BalancedPerspectivesPanel.test.tsx:44-55`) reproduces the exact partial-stream shape that caused the fault and asserts both non-throw and continued rendering of the surviving field — the right pair of assertions for a resilience fix.
- **`sanitizeQueries` exists at all**, applied before any use of `body.queries`, with both a per-item length cap and a list-count cap. F6 is a content gap within an otherwise correctly-placed boundary check.
- **The `evidenceStore.ts:5-9` docstring fix** removes a stale cross-reference to `workspaceStore` and points at the actual adapter. No security content; correct as written.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Fail-open `NODE_ENV` default ships `'unsafe-eval'` to staging/test/unset builds | Medium | B1→B2 | `proxy.ts:26-32` | High |
| F2 | No-eval regression test no longer covers the production call path | Medium | B1→B2 | `proxy.test.ts:9-12,30-32` | High |
| F3 | `allowUnsafeEval` overridable by any future caller; invariant unenforced | Low | B1→B2 | `proxy.ts:26-32,53` | High |
| F4 | Dev environment loses eval backstop where untrusted inputs are exercised | Low | B2 | `proxy.ts:21-32` | Medium |
| F5 | Spread-safety comment asserts a bound only OpenAlex enforces | Low | B4 | `route.ts:175-181` | Medium |
| F6 | Override queries can inject OpenAlex filter clauses (`,` / `\|`) | Low | B3 | `route.ts:113`, `querySanitize.ts:13-23` | Medium |
| F7 | Streaming guard checks truthiness, not shape | Informational | B5 | `BalancedPerspectivesPanel.tsx:113-119` | Medium |
| F8 | `connect-src` rationale omits corpus git worker egress | Informational | B6 | `proxy.ts:17-24` | High |
| F9 | Touched route remains unauthenticated/unthrottled (synthesis note) | Informational | B3 | `route.ts:141-160` | High |

---

## Overall Assessment

This is a small, well-intentioned fix batch whose security surface is concentrated almost entirely in one line: the default-parameter expression at `proxy.ts:28`. The change itself is defensible — Next.js dev genuinely requires `'unsafe-eval'`, the relaxation is correctly confined to `script-src`, the nonce and `'strict-dynamic'` remain intact, and there is a test asserting the flag does not leak into other directives. What warrants attention is that the same commit made the policy decision *fail-open* (F1), *untested on the path that actually runs* (F2), and *overridable by argument* (F3) — three independent ways for `'unsafe-eval'` to reach a production response without anything failing, introduced together. None is exploitable today on the documented Vercel deploy path, and the repo already demonstrates the correct polarity a few files away in `corpus/flag.ts:21`, so the fix is cheap and local: invert the predicate to `=== "development"` and add one `stubEnv` test on the zero-argument call. The remaining findings are lower-stakes: the streaming crash guard closes the reported fault but not its neighbours (F7), and the two comment-accuracy commits — the point of which was to make safety arguments more precise — each leave a claim that is stronger than what the code enforces (F5, F8), which is worth a second pass since the whole purpose of that commit was accuracy. Nothing here blocks the merge; F1 and F2 should be fixed before anything deploys to a non-`production` `NODE_ENV`.

---

## Goal-Alignment Note
- Answered: yes — full security review of the range, findings down to Informational
- Out of scope: production bundle and `pdfjs-dist` eval-freeness (not inspectable from source; carried over as Unverifiable from the fact-check); the credentials-to-user-supplied-`remoteUrl` flow in `corpus/gitCore.ts` (outside the range, flagged in F8 as deserving its own review when the flag graduates)
- Escalate: nothing — no HALT-ESCALATE pattern present
