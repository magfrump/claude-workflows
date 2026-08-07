# Code Fact-Check Report

**Scope:** `git diff d86d2dc..HEAD` — arm 2 full-review pass 2 validation (decision 031 tier policy T)
**Worktree:** /workspace/runs/review-arms/e3-loops/wt-validate-arm2 (detached)
**Commit:** 99e1229 (`fix: address full-review blockers R1-R4 (e3 arm2 iter1)`)
**Files in range:** app/layout.tsx, app/lib/utils/exportGraph.ts (+.test.ts), proxy.ts (+proxy.test.ts)
**Draw:** fresh, independent (k=1 draw for this validation)

Constraint note: this is a fresh draw restricted to ancestors of 99e1229. Test execution
could not be run in this environment (no node_modules in the worktree; other worktrees are
off-limits per the historical rule), so test claims are verified by static assertion-vs-code
analysis, not by a green run. Every assertion in the two new test files is statically
consistent with the code under test.

---

## Claim 1 — Request-header CSP forwarding delivers the nonce where Next reads it
**Source:** proxy.ts lines 33-42 comment + code; layout.tsx comment; commit 99e1229 (R1).
**Claim:** Next.js reads the nonce off the *request* `Content-Security-Policy` header during
render and stamps it onto bootstrap `<script>` tags; setting CSP only on the response is
insufficient under `'strict-dynamic'`; therefore both request and response must carry the
same policy.
**Finding: Correct (code); the render-time behavioral half is Likely Correct (medium-high).**
- Code does exactly what it says: `requestHeaders.set("Content-Security-Policy", csp)` and
  `requestHeaders.set("x-nonce", nonce)` on a copy of the incoming headers, then
  `NextResponse.next({ request: { headers: requestHeaders } })`, and also
  `response.headers.set("Content-Security-Policy", csp)`. Same `csp` string on both. (proxy.ts:36-46)
- "Next reads the nonce off the request CSP header during render" is the documented Next.js
  CSP-nonce pattern and is consistent across proxy.ts, layout.tsx, and proxy.test.ts. It
  cannot be proven from a unit test (only from a real Next render/build); the commit itself
  flags manual browser verification as still recommended. The code correctly implements the
  documented contract, so this is not a code defect.

## Claim 2 — exportGraph dataUrlToBlob: correct decode, both call sites, no data: fetch remains
**Source:** exportGraph.ts:16-65; commit 99e1229 (R2).
**Finding: Correct.**
- Decode logic is sound: splits on first comma; validates `data:` prefix; detects `;base64`
  suffix; strips `;base64` then `split(";")[0]` to drop params (e.g. `charset=utf-8`);
  base64 path uses `atob` + `charCodeAt` into a `Uint8Array` (preserves non-UTF-8 bytes);
  non-base64 path uses `decodeURIComponent`. Fallback media type `application/octet-stream`.
  (exportGraph.ts:23-44)
- Both former `fetch(dataUrl)`/`res.blob()` sites replaced: `downloadGraphAsPng` →
  `triggerDownload(dataUrlToBlob(dataUrl), filename)` (line 54); `graphToPngBlob` →
  `return dataUrlToBlob(dataUrl)` (line 65).
- No `data:` fetch remains. The only surviving `fetch` token in the file is inside the
  docstring (line 19) explaining why fetch was removed. Confirmed via grep.
- The R2 rationale is accurate: `fetch("data:...")` is a `connect-src`-governed request, and
  `connect-src 'self'` refuses `data:`, so the old code would have broken PNG/zip export.

## Claim 3 — proxy.test.ts: assertions match names; CSP-forwarding test falsifies wiring if broken
**Source:** proxy.test.ts; commit 99e1229 (R3).
**Finding: Correct.**
- `buildCsp` is exported (proxy.ts:16) and imported by the test (proxy.test.ts:3). Directive-set
  test expects exactly the 9 directives buildCsp emits (default/script/style/img/font/connect-src,
  frame-ancestors, base-uri, object-src) — matches. Nonce + `'strict-dynamic'` on script-src,
  style-src `'unsafe-inline'` carve-out — all match the code.
- Falsifiability holds: the "forwards the same CSP on the request" test (lines 78-86) reads
  the forwarded header via Next's `x-middleware-override-headers` / `x-middleware-request-*`
  encoding and asserts non-null + equal to the response CSP. Against the pre-R1 wiring
  (CSP set only on the response, never on `requestHeaders`), `content-security-policy` would
  not appear in `x-middleware-override-headers`, so `forwardedRequestHeader` returns null and
  `.not.toBeNull()` fails. The test genuinely falsifies broken nonce-delivery wiring.
- Other assertions verified consistent: fresh-nonce-per-request (two runs' CSP differ, nonce
  is randomUUID→base64), x-nonce overwrite-not-append (`requestHeaders.set` overwrites the
  copied client value), x-nonce matches `'nonce-...'` in policy.
- The `x-middleware-*` encoding is documented in the test file as a Next.js internal and is
  the accurate mechanism for inspecting forwarded request headers from a unit test.

## Claim 4 — layout force-dynamic comment mechanism
**Source:** layout.tsx:21-24 comment + `export const dynamic = "force-dynamic"`; commit 99e1229 (R4).
**Finding: Correct.**
- Comment states each route must render per request or a static prerender would bake in one
  reused nonce; Next takes the nonce from the request CSP header (set in proxy.ts) and stamps
  it on bootstrap scripts; "nothing here reads it directly." Consistent with the actual
  layout (no `headers()` call remains) and with proxy.ts.
- R4's own account is accurate: at the prior commit (d90d6bb) layout.tsx had
  `import { headers }` + a discarded `await headers();` (verified via `git show d90d6bb`).
  99e1229 replaced that with the `dynamic` export, moving the per-request contract to the
  module's public surface.

## Claim 5 — connect-src 'self' (re-enumerated client network calls)
**Source:** proxy.ts:12-14 comment; commit 9b4e453.
**Finding: Correct.**
Enumerated every non-test `fetch(` in app/:
- Browser-originating calls all hit same-origin `/api/*` routes → covered by `'self'`:
  ContextInput.tsx (`/api/refine/context`), LeanCodeDisplay.tsx (`/api/explanation/lean-error`),
  useAnalytics.ts (`/api/analytics` GET + DELETE), formalization/api.ts (`fetchApi`/
  `fetchStreamingApi` — callers pass relative `/api/...` URLs, e.g. `/api/verification/lean`).
- Third-party calls are all server-side, never browser-to-third-party: callLlm.ts /
  streamLlm.ts fetch `https://openrouter.ai/...` but import `crypto`, `@anthropic-ai/sdk`,
  and filesystem analytics persistence, and are imported only by `app/api/*` route handlers
  and other server libs — they run in Node route handlers, not the client. The Lean verifier
  fetch is in `app/api/verification/lean/route.ts` (a server route).
- Conclusion: no browser-to-third-party request exists, so `connect-src 'self'` is sufficient
  and the comment's Anthropic/OpenAlex/OpenRouter server-to-server claim holds.

## Claim 6 — Remaining comment/doc claims from the feature commits
For each: is the CODE wrong or only the COMMENT? (All resolve to neither — accurate.)
- **Runtime name ("Edge runtime")**, proxy.ts:34-35: comment says `crypto.randomUUID` and
  `Buffer` "are both available in the Edge runtime that Next proxy runs in." This is the
  known marginal-red class from decision 031's context (Next runs proxy/middleware on the
  Node runtime by default, not Edge, unless `runtime: "edge"` is configured — no such config
  here). **Assessment: comment imprecise/Stale on the runtime label.** Decisive downstream:
  the CODE is correct either way — `crypto.randomUUID()` and `Buffer` are available in both
  Node and Edge runtimes, so the behavior the comment guards is right; only the reader-facing
  runtime name is off. This is comment-only (misinformed-reader), not a behavioral defect,
  and not a security/contract rationale. Under tier policy T it is 🟡, not 🔴.
- **style-src 'unsafe-inline' rationale:** proxy.ts:24-27 attributes it to Tailwind v4 inline
  styles; proxy.test.ts:60-61 attributes it to React `style={}` attributes, reactflow inline
  transforms, and KaTeX. Both rationales are individually true and both justify the same
  `'unsafe-inline'` carve-out; `'unsafe-inline'` in style-src does cover inline style
  attributes. Not contradictory, not wrong — Correct.
- **x-nonce (overwrite-not-append):** proxy.ts:44-45 comment matches the code
  (`requestHeaders.set`, which overwrites); the test enforces it. Correct.
- **connect-src vendor list (Anthropic/OpenAlex/OpenRouter server-to-server):** verified under
  Claim 5. Correct.

## Claim 7 — Commit-message claims, incl. 9b4e453 verification claim
- 99e1229 body (R1-R4 dispositions, "234 tests pass (was 221)", tsc/lint clean): the R1-R4
  code dispositions are all accurate per Claims 1-4. The test-count and clean-build numbers
  could not be independently re-run here (no deps); they are plausible and internally
  consistent (13 new tests added across the two new files ≈ 221→234). Not a code claim.
- d90d6bb / b25e939 bodies (rename middleware→proxy, "no behavior change", comment
  corrections): consistent with the observed file states. Correct.
- **9b4e453 verification claim** — "Verified prod build emits the CSP header and Next applies
  the nonce to every `<script>` tag it generates." This claim was in fact FALSE at 9b4e453
  (R1 later established the nonce never reached the document because the policy was set only
  on the response). Per the LOOP-OWNER OVERRIDE and decision 031 tier policy T(b), this is a
  fact-check Incorrect about a claim in *immutable already-merged history*: it is routed to
  the **override log as an accepted-immutable acknowledgment**, never 🔴, and is recorded here
  as an override-log entry, **not as a fresh finding**.

---

## Claims Requiring Attention

| # | Claim | Verdict | Tier T disposition | Code-wrong vs comment-only |
|---|-------|---------|--------------------|-----------------------------|
| 6 | proxy.ts "Edge runtime that Next proxy runs in" | Stale/Incorrect (comment) | 🟡 (comment/doc, code correct; not a security/contract rationale) | **comment-only** — `crypto.randomUUID`/`Buffer` work on both runtimes; code behavior unaffected |
| 7 | 9b4e453 "Verified prod build … Next applies the nonce to every `<script>`" | Incorrect (was false at that commit) | Override log — accepted-immutable, never 🔴 (T(b)); not a fresh finding | immutable history — no code change can fix a merged commit message |

No behavioral (code-wrong) Incorrect findings. No consumer-binding-contract or security-rationale
comment-Incorrect findings. **Red count under tier policy T: 0.**

## Goal-Alignment Note
- **Answered:** Under decision 031 tier policy T, arm 2's full-review pass 2 (99e1229) reaches
  **0-red**. Every code claim in scope is Correct: R1 CSP request-forwarding, R2 dataUrlToBlob
  (both sites, no data: fetch remaining), R3 proxy.test.ts assertions + falsifiable
  CSP-forwarding test, R4 force-dynamic, and connect-src 'self'. The two Incorrect items both
  fall in T's demote/override carve-outs — one comment-only "Edge runtime" stale label (🟡,
  code correct) and one immutable-history verification claim (override log, per LOOP-OWNER
  OVERRIDE) — neither is a red.
- **Out of scope:** Amber/green findings from prior passes (per commit body, remain open);
  execution of the test suite (no node_modules in worktree; other worktrees off-limits) —
  test claims verified statically instead; the truth of the 9b4e453 claim is not re-litigated
  (accepted-immutable).
- **Escalate:** None. If a later policy wants the "Edge runtime" comment fixed, it is a
  cents-level comment edit, not a merge blocker under T.
