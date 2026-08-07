# Code Fact-Check Report

**Scope:** `git diff d86d2dc..HEAD` (5 files: `app/layout.tsx`, `app/lib/utils/exportGraph.ts` + `.test.ts`, `proxy.ts`, `proxy.test.ts`)
**Commit:** 99e1229
**Reviewer:** code-fact-check skill, standard rules — fresh independent draw (validate-T arm2, pass 2)
**Method:** ancestors of 99e1229 only, in worktree `wt-validate-arm2` (detached at 99e1229). No other worktrees, no e1/, no prior full-2 artifacts read.

---

## Claim 1: request-header CSP forwarding — nonce delivered where Next reads it

**Claim (proxy.ts comment + 99e1229 R1):** "Next.js reads the nonce off the *request* `Content-Security-Policy` header during render and stamps it onto the bootstrap `<script>` tags... Setting it only on the response is not enough... Both headers must carry the same policy."

**Verdict: Correct.**

`proxy()` builds one policy string `csp = buildCsp(nonce)` and sets it in two places:
1. On forwarded request headers: `requestHeaders.set("Content-Security-Policy", csp)`, passed via `NextResponse.next({ request: { headers: requestHeaders } })`.
2. On the response: `response.headers.set("Content-Security-Policy", csp)`.

This matches Next.js's documented nonce mechanism (Next parses the nonce out of the request CSP header and applies it to the scripts it emits; under `'strict-dynamic'` the `'self'` source is ignored, so un-nonced bootstrap scripts would be refused). Setting both headers to the identical string is exactly what the mechanism requires. The comment is accurate about *where* Next reads the nonce (request CSP header) and *why* response-only is insufficient.

Note: `requestHeaders.set("x-nonce", nonce)` is also written, but **nothing in the app reads `x-nonce`** (`rg -rn "x-nonce" app` → no consumers; no `headers()` call in any layout/page). Delivery does not depend on it — the CSP header is the sole live channel. `x-nonce` is a harmless, currently-unused extra (see Claim 6).

---

## Claim 2: exportGraph `dataUrlToBlob` — decode correct, both sites, no `data:` fetch remains

**Verdict: Correct.**

- **Decode correctness (base64):** `atob(payload)` → per-byte `charCodeAt` into a `Uint8Array` → `new Blob([bytes], {type})`. This is the standard binary-safe decode; it preserves non-UTF-8 bytes (the test `//79` → `[0xff,0xfe,0xfd]` confirms). Media-type parsing: strips `;base64`, then `.split(";")[0]` drops parameters (`text/plain;charset=utf-8;base64` → `text/plain`), falling back to `application/octet-stream` on empty. Non-base64 branch uses `decodeURIComponent`. All branches correct.
- **Both call sites replaced:** `downloadGraphAsPng` now calls `triggerDownload(dataUrlToBlob(dataUrl), filename)`; `graphToPngBlob` now `return dataUrlToBlob(dataUrl)`. Both previously did `await fetch(dataUrl)` → `.blob()`.
- **No `data:` fetch remains:** `rg "fetch"` in `exportGraph.ts` finds only line 19 (a comment). No live `fetch(dataUrl)` anywhere in `app/` (`rg "fetch\(dataUrl|fetch\(.*data:"` → comment only). Confirmed.

The `toPng` return shape assumed by the decoder (base64 image data URL) matches the code path, and the test uses a 1x1 GIF as a stand-in.

---

## Claim 3: proxy.test.ts — assertions match names; CSP-forwarding test falsifies broken wiring

**Verdict: Correct** (verified by static reading; tests not re-run — see caveat).

- **Directive-set assertion** matches `buildCsp` output exactly: the sorted key list `[base-uri, connect-src, default-src, font-src, frame-ancestors, img-src, object-src, script-src, style-src]` corresponds one-to-one to the 9 directives in `buildCsp`. Value spot-checks (`default-src 'self'`, `frame-ancestors 'none'`, `object-src 'none'`, `base-uri 'self'`) match.
- **Nonce + strict-dynamic** on `script-src`: asserted `'nonce-NONCE'` and `'strict-dynamic'` — both present in `buildCsp`.
- **style-src carve-out:** asserts `'unsafe-inline'` present — matches.
- **Falsifiability of the forwarding wiring (the file's stated purpose):** `forwardedRequestHeader()` decodes Next's internal forwarded-header encoding — reads `x-middleware-override-headers` (comma list of overridden names) and `x-middleware-request-<name>`. This is the correct encoding `NextResponse.next({request:{headers}})` produces. The test `"forwards the same CSP on the request"` asserts the forwarded `content-security-policy` is non-null and equals the response CSP. Against the pre-R1 wiring (CSP set only on the response, request headers untouched), `content-security-policy` would not appear in `x-middleware-override-headers`, so `forwardedRequestHeader` returns `null` and the test fails. The assertion genuinely falsifies the broken wiring. Confirmed.
- Other proxy tests (per-request freshness via two runs producing different CSP; `x-nonce` overwrite-not-append; `x-nonce` matches policy nonce) are internally consistent with `proxy()`.

**Caveat:** the worktree has no `node_modules`, so I could not re-run vitest. The 99e1229 message claims "26 files / 234 tests pass" (was 221 at d90d6bb). Arithmetic checks out: 8 new proxy tests (3 `buildCsp` + 5 `proxy`) + 5 new `exportGraph` tests = 13; 221 + 13 = 234. Consistent but not independently executed.

---

## Claim 4: layout `force-dynamic` comment mechanism

**Claim (layout.tsx comment):** static prerender would bake in one nonce and reuse it; `force-dynamic` forces per-request render; Next takes the nonce from the request CSP header; "nothing here reads it directly."

**Verdict: Correct.**

`export const dynamic = "force-dynamic"` is present. The comment's mechanism is accurate: per-request nonces cannot be reused across a cached/prerendered document, so the route must render per request. "Nothing here reads it directly" is verified — the layout has no `headers()` call and no `x-nonce` read; the nonce reaches scripts via Next's own CSP-header parsing, not via layout code. This comment correctly supersedes the earlier (pre-R4) `await headers()` + mis-describing comment.

---

## Claim 5: connect-src 'self' — client network calls re-enumerated

**Claim (proxy.ts):** `connect-src 'self'` is sufficient because external vendor calls are server-to-server (Next API routes), not browser-to-third-party.

**Verdict: Correct** (the load-bearing claim). **One stale vendor name — see Claim 6.**

Enumerated every browser-reachable network call in client code (`app/hooks`, `app/components`, and client-imported libs):

| Call site | Target | Origin |
|---|---|---|
| `useAnalytics.ts:11,30` | `/api/analytics` | self |
| `LeanCodeDisplay.tsx:88` | `/api/explanation/lean-error` | self |
| `ContextInput.tsx:25` | `/api/refine/context` | self |
| `formalization/api.ts` `fetchApi`/`fetchStreamingApi` | callers pass `/api/...` (all relative — verified `useDecomposition`, `useArtifactGeneration` via `ARTIFACT_ROUTE`, `generateLeanStreaming`, `generateSemiformal*`) | self |

All external-vendor fetches (`OPENROUTER_API_URL` in `streamLlm.ts`/`callLlm.ts`; Anthropic via `getAnthropicClient`) live in server-only modules — imported only by `app/api/**/route.ts` and `app/lib/formalization/artifactRoute.ts`, and use Node `crypto`/filesystem persistence. No browser-to-third-party call exists. `connect-src 'self'` is sufficient. Confirmed. (No `WebSocket`/`EventSource`/`sendBeacon` in client code; SSE streaming is done via `fetch` to same-origin `/api` routes.)

---

## Claim 6: remaining comment/doc claims from the feature commits

For each: whether the CODE is wrong or only the COMMENT (decisive downstream).

**6a. Runtime name — "Next.js 16 renamed Middleware → Proxy" (proxy.ts + 9b4e453):** **Correct.** `next` is `16.2.4` (package.json). File is `proxy.ts` (not `middleware.ts`). Consistent.

**6b. style-src 'unsafe-inline' rationale:** **Correct, code correct.** Two complementary justifications appear — proxy.ts cites "Tailwind v4 emits inline styles"; proxy.test.ts comment cites "React style={} attributes, reactflow's inline transforms and KaTeX." Both vendors are present (`tailwindcss ^4`, `reactflow ^11`, `katex ^0.16`). Not contradictory; both are plausible drivers of inline styles. `style-src 'self' 'unsafe-inline'` matches code. No issue.

**6c. x-nonce header:** **Comment-only imprecision, code correct, non-decisive.** proxy.ts writes `x-nonce` and comments "Overwrite (not append) so a client-supplied x-nonce cannot be smuggled through to a server component." No server component reads `x-nonce` anywhere in the app (verified: zero consumers). So the header is defense-in-depth for a consumer that does not yet exist — the *comment* implies an active smuggling path that isn't wired up. The **code is not wrong** (overwriting an unused header is harmless and correct-by-construction); only the comment overstates current relevance. proxy.test.ts spends two assertions on this unused header — testing belt-and-suspenders, not a live delivery path. Non-decisive for the CSP mechanism (delivery is via the CSP header, Claim 1).

**6d. connect-src vendor list — "Anthropic / OpenAlex / OpenRouter":** **Comment-only staleness (Stale), code correct, non-decisive.** Anthropic and OpenRouter are present and server-side (verified). **OpenAlex appears nowhere in the codebase** (`rg -rin openalex` over the repo, excluding node_modules/docs → no matches). The comment names a vendor that is not integrated (removed or never present). The **code is not wrong** — `connect-src 'self'` remains correct precisely because there are no client calls to OpenAlex (or anyone else). Only the comment's vendor enumeration is stale. Downstream-decisive note: this is a documentation nit, not a CSP defect.

---

## Claim 7: commit-message claims (incl. 9b4e453 verification claim)

**7a. 99e1229 R1–R4 dispositions:** All four map to real, verified code changes — R1 (dual-header CSP forwarding, Claim 1), R2 (`dataUrlToBlob` + both call sites, Claim 2), R3 (`buildCsp` exported + `proxy.test.ts`, Claim 3), R4 (`force-dynamic` replacing discarded `await headers()`, Claim 4). Accurate.

**7b. 99e1229 test count "234 pass (was 221)":** Arithmetically consistent (221 + 13 new = 234); not independently re-run (no `node_modules`). Lint/tsc claims not verified.

**7c. 9b4e453 verification claim — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates":** **Accepted as immutable per LOOP-OWNER OVERRIDE.** Recorded in the override log below, not treated as a fresh finding. (Contextually, the R1 blocker in 99e1229 states the nonce "never reached the document" under the pre-R1 wiring that shipped in 9b4e453 — i.e., this verification claim was not borne out at that commit — but per the override this is history and is not re-litigated here.)

---

## Claims Requiring Attention

1. **proxy.ts vendor list is stale (comment-only, Stale, non-decisive).** Lists "OpenAlex" among server-to-server vendors; OpenAlex is not referenced anywhere in the codebase. Code (`connect-src 'self'`) is correct regardless. Fix: drop "OpenAlex" from the comment. — **COMMENT-only.**
2. **proxy.ts x-nonce comment overstates an inactive path (comment-only, non-decisive).** Comment describes preventing smuggling "to a server component," but no server component reads `x-nonce`. The overwrite is harmless/correct; the header is currently unused. Fix: reword to note it is defense-in-depth for a future consumer, or drop the header. — **COMMENT-only.**

No code-wrong findings. No red-severity defect found in the diff: the CSP nonce is delivered through the channel Next reads (request CSP header), export decoding is correct with no residual `data:` fetch, and `connect-src 'self'` is consistent with an exhaustive enumeration of client network calls.

### Override log (immutable-history, not fresh findings)
- 9b4e453 commit message: "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates." Accepted-immutable per loop-owner override; not scored as a finding.

## Goal-Alignment Note
- **Answered:** All six brief items verified against the code that exercises them. (1) Request-header CSP forwarding is correct and Next reads the nonce there; (2) `dataUrlToBlob` decodes correctly at both call sites with no residual `data:` fetch; (3) `proxy.test.ts` assertions match names and the forwarding test genuinely falsifies broken wiring; (4) `force-dynamic` comment mechanism is accurate; (5) `connect-src 'self'` re-enumerated — all client calls are same-origin `/api`, all vendor calls server-side; (6) two comment-only inaccuracies flagged (stale OpenAlex vendor name; x-nonce comment overstates an inactive consumer), both COMMENT-only with code correct; (7) commit-message claims accurate, 9b4e453 verification claim handled per override.
- **Out of scope:** Independent test execution (no `node_modules` in worktree — 234-pass, tsc, and lint claims read but not re-run); the final 0-red tier-policy-T determination for arm2 full-review pass 2 (that judgment belongs to the loop owner; this report supplies the fact-check input); amber/green findings the R-pass deferred; other worktrees, e1/, and prior full-2 artifacts (excluded by historical rule).
- **Escalate:** None. No code-wrong or red-severity issue found; the two flagged items are comment-only documentation nits and do not, on the fact-check axis, constitute a red.
