# Security Review — mfc-postfix (`git diff 9c9edf5...HEAD`)

**Commit:** 7f30210
**Scope:** `proxy.ts`, `proxy.test.ts`, `app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx` (+ its test)
**Date:** 2026-08-18
**Based on:** `code-fact-check-report.md` (k=2 merge, commit 7f30210) — its verdicts bind; documented behavior is not re-verified here.

No escalation block: no plaintext secrets, no unauthenticated privileged endpoint, no SQL/command injection, no disabled TLS, no hardcoded keys in the diff.

## Trust Boundary Map

```
B1: [HTTP request body: queries[], elementContent] → [sanitizeQueries / type+length checks] → [route handler]
B2: [OpenAlex API response: data.results] → [trusted-as-bounded, NO slice]            → [Math.max(...allWorks) spread]   (touched)
B3: [ambient process.env.NODE_ENV]         → [buildCsp default param, call-time read] → [CSP header on every navigation] (moved)
B4: [partial-JSON streamingPreview]        → [t.between presence guard]               → [React render / DOM]             (new guard)
```

The diff moves the eval-policy decision into a default parameter that reads ambient env at call time (B3), leaves the OpenAlex response array un-sliced before a spread whose safety argument rests only on the *request* `per_page` (B2), and adds a presence guard on a streamed tuple before indexing it (B4). B1 is unchanged by this diff except for a comment. Every finding below cross-references one of these labels.

## Findings

#### Fail-open eval-policy default: any NODE_ENV ≠ exactly "production" grants 'unsafe-eval'

**Severity:** Medium
**Location:** `proxy.ts:26-32` (default param), `proxy.ts:53` (sole default-arg call site)
**Boundary:** B3
**Move:** #5 (invert the access-control model), #11 (enumerate bypasses)
**Confidence:** Medium

`allowUnsafeEval` defaults to `process.env.NODE_ENV !== "production"`. This is a fail-open comparison: the CSP is hardened only for the *exact* string `"production"`, and every other value — `"staging"`, `"preview"`, `"test"`, empty string, and unset/undefined — appends `'unsafe-eval'` to `script-src`. The fact-check executed this sweep (Claim 1, Verified) and I independently reproduced it (`evidence/sec-buildcsp-nodeenv.txt`). Given the project's self-hosted single-tenant deploy model (each end user runs their own copy — CLAUDE.md "Deployment"), a user who runs under a custom server/Docker/start command that does not pin `NODE_ENV=production` ships a production CSP that permits `eval()`. `'unsafe-eval'` does not itself inject script — nonce + `strict-dynamic` still gate script execution — but it removes a defense-in-depth layer against any residual injection sink (e.g. an eval-based expression evaluator, or a gadget reachable past markdown sanitization the comment at `proxy.ts:9` itself worries about). Environmental unlikelihood on stock Vercel/`next start` (which force `NODE_ENV=production`) is reflected in Confidence, not Severity — the named mechanism (a dev-only flag enforceable in production) holds the Medium floor.

**Recommendation:** Make the default fail *closed*: `allowUnsafeEval = process.env.NODE_ENV === "development"` so only the explicit dev value opens the policy, and unset/staging/unknown values stay hardened. Add a test that stubs `process.env.NODE_ENV` and calls the single-arg `buildCsp(nonce)` default branch (currently untested — fact-check Claim 5, Incorrect).

#### Unbounded spread of the OpenAlex response array into `Math.max`

**Severity:** Medium
**Location:** `app/api/evidence-search/route.ts:126` (`return (data.results ?? [])`), `:168-181` (accumulate + spread)
**Boundary:** B2
**Move:** #8 ("what if there are a million of these?"), #2 (implicit sanitization assumption)
**Confidence:** Low

`searchOpenAlex` returns `(data.results ?? []) as OpenAlexWork[]` with **no slice to `PER_QUERY_RESULTS`** — `per_page=5` is only sent as a *request* parameter (`route.ts:114`); the response array is trusted verbatim. The "safe to spread" comment (verified by fact-check Claim 6) bounds only the *query count* (≤5 override / ≤3 LLM); it explicitly does **not** establish what happens if the upstream returns more rows than requested. All returned works are concatenated into `allWorks` (`route.ts:171`) and then spread as call arguments in `Math.max(...allWorks.map(...))` (`route.ts:181`). I measured the spread ceiling on this runtime: `Math.max(...arr)` throws `RangeError: Maximum call stack size exceeded` between 125k and 130k arguments (`evidence/sec-mathmax-spread-threshold.txt`, node v20). So if the OpenAlex response (or a network attacker on the server-to-server egress — there is no TLS pinning, and a single query alone would need to carry it) inflates one `results` array past ~125k entries, the spread throws, the handler's catch returns HTTP 500, and that request fails. Impact is a single self-limited request failure, not amplification or persistence — hence Low confidence: under OpenAlex's own `per_page` cap (max 200) this is unreachable; it requires upstream misbehavior or a compromised/MITM'd response.

**Recommendation:** Defensively bound the trusted-external array — slice each query's results to `PER_QUERY_RESULTS` at `route.ts:126` (`.slice(0, PER_QUERY_RESULTS)`), and/or replace the spread with a reduce (`allWorks.reduce((m,w)=>Math.max(m, w.relevance_score ?? 0), 1)`) which has no argument-count ceiling.

## Endorsement Claims

- **Claim:** The added `t.between &&` presence guard prevents a streamed tension whose `between` tuple is absent from throwing `TypeError: Cannot read properties of undefined (reading '0')` during render.
  **Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`
  **Evidence:** executed
  **Verified:** fact-check Claim 11 (Verified, executed k=2) removed the guard and observed the crash test fail with the exact TypeError, and confirmed the guarded suite passes; it also found zero error boundaries in `app/`, so the throw would unmount the tree.
  **Not verified:** behavior when `between` is present-but-not-a-2-tuple (e.g. `[]`, `{}`, or a truthy scalar) — the guard tests presence, not shape, so `between[0]`/`between[1]` would render `undefined` for a malformed-but-truthy value; no runtime schema validation covers this hop.
  **route: code-fact-check**

- **Claim:** `'unsafe-eval'`, when granted, is appended only to the `script-src` directive and appears exactly once — it does not leak into `default-src` or other directives.
  **Location:** `proxy.ts:30-32`
  **Evidence:** executed
  **Verified:** fact-check Claim 1 (Verified, executed) recorded `'unsafe-eval'` scoped to `script-src` across all NODE_ENV values; the new test `proxy.test.ts` asserts `devCsp.match(/'unsafe-eval'/g)` has length 1; my reproduction (`evidence/sec-buildcsp-nodeenv.txt`) shows the token only in `script-src`.
  **Not verified:** the composed multi-directive header as emitted by `proxy()` at `proxy.ts:61,66` on a live response (I read `buildCsp`'s string output, not the served header). This is the directive-scoping fact only, NOT an endorsement of the eval *policy* (see Untested bypass candidates — that guardrail is barred from endorsement).
  **route: code-fact-check**

Note: the eval-policy guardrail (buildCsp's dev/prod decision) is **deliberately absent** from Endorsement Claims — move #11 bars any guardrail carrying an untested bypass candidate (see below) from appearing here.

## Guardrail bypass enumeration (move #11) — eval-policy

At least 3 candidates for how `'unsafe-eval'` reaches production (or the policy is bypassed):

1. **NODE_ENV is any deployed value other than the exact string `"production"`** (`"staging"`, `"preview"`, `"test"`, `""`, unset). — **Tested.** Fact-check Claim 1 executed the sweep; independently reproduced in `evidence/sec-buildcsp-nodeenv.txt` (all non-`"production"` values GRANT unsafe-eval, including `<unset>` and `""`).
2. **A caller passes `allowUnsafeEval: true` (or any truthy value) explicitly.** `buildCsp` is `export`ed and the boolean is caller-selectable; dev-only-ness is enforced *solely* by there being one default-arg call site (`proxy.ts:53`). A second caller, a copy-paste, or a truthy non-boolean argument opens the policy regardless of NODE_ENV. — **Tested (read-static).** Signature exported at `proxy.ts:26-28`; fact-check Claim 5 confirmed `proxy.ts:53` is the only default-arg call site and both test call sites pass an explicit boolean.
3. **The default-parameter branch (`proxy.ts:53`, single-arg call) is untested**, so a regression in the `NODE_ENV`-derivation ships unnoticed. — **Tested (established).** Fact-check Claim 5 = **Incorrect**: no committed test exercises the env→boolean derivation; only the two output shapes (explicit `false`/`true`) are covered.

### Untested bypass candidates

- **Runtime mutation of `process.env.NODE_ENV` after boot.** Because the default parameter reads `process.env.NODE_ENV` at *call time* (not module load), any dependency or instrumentation that reassigns `process.env.NODE_ENV` during the process lifetime would flip subsequent `buildCsp(nonce)` outputs. — **Untested:** not traced through the dependency tree; would require auditing whether any transitive module mutates `NODE_ENV` in the Proxy/Edge runtime. Reason not tested: out of diff scope (no manifest change) and low prior, but it is a real ambient-state hop, so it is listed rather than claimed clean.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Fail-open eval-policy default (NODE_ENV ≠ "production" grants 'unsafe-eval') | Medium | B3 | `proxy.ts:26-32,53` | Medium |
| 2 | Unbounded OpenAlex response array spread into `Math.max` (RangeError DoS) | Medium | B2 | `route.ts:126,181` | Low |

## Overall Assessment

No findings within the code paths read rise above Medium, and both are fixable in place — neither indicates an architectural problem. The single most important thing to address is the **fail-open direction** of the eval-policy default (`!== "production"`): flipping it to `=== "development"` closes the guardrail against every misconfigured/unknown-NODE_ENV deployment at zero cost, and is the higher-leverage of the two since it ships in the CSP on every navigation. The `Math.max` spread is a defense-in-depth hardening (slice the trusted-external array; it is unreachable under OpenAlex's own `per_page` cap). Endorsement claims are execution-backed (both `Evidence: executed`, routed to code-fact-check) with their unread hops named; the eval-policy guardrail is excluded from endorsement because it carries an untested bypass candidate (runtime `NODE_ENV` mutation). This is not a categorical all-clear: it is *no findings above Medium within the paths read, with the eval-policy guardrail's endorsement withheld pending the untested-bypass check*.
