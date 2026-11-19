Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (reviewed worktree `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-token-measurement/wt-csp`, detached at d90d6bb)
**Scope:** Stage 2.5 submitted claims only (S1-S6 from security-reviewer, performance-reviewer, api-consistency-reviewer) on d86d2dc..d90d6bb (`proxy.ts`, `app/layout.tsx`). No harvested claims; numbering continues from the merged report's Claim 18.
**Checked:** 2026-11-19
**Total claims checked:** 7 (6 submitted; S5 split into 23a/23b)
**Summary:** 5 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution environment: the Stage-1 r3 copy `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/csp-fc-r3`, whose `proxy.ts` and `app/layout.tsx` are byte-identical to d90d6bb (checked with `diff`). No source file there was changed. A `next build` attempt (log: `stage25-logs/build.log`, exit 1) failed because `next/font/google` cannot reach fonts.googleapis.com from this sandbox. The only way to build would be the r3 font stub, which edits `app/layout.tsx`, and this pass may not edit source. The failed build also cleared part of that copy's `.next` output. Build output is not source, but the r3 copy no longer holds a startable prod build. The executed verdicts below call the exported `proxy()` and Next's own matcher compiler directly from `node_modules` (next 16.2.4). They do not use a server. Logs are in `/workspace/.claude/wt-2026-11-19-a8-token-measurement/runs/review-arms/a8-2026-11-19/csp/stage25-logs/`. No process was left running. No `docs/reviews/hallucination-patterns.md` exists in the reviewed repo.

---

## Submitted Claims

## Claim 19: "The nonce comes from `crypto.randomUUID()` (122 random bits), is generated inside the per-request `proxy` function, and is base64-encoded into a character set valid for a nonce-source."

**Submitted by:** security-reviewer
**Location:** `proxy.ts:34-37`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the source of the nonce, where it is generated (inside `proxy()` on each call, with no module-level reuse), that three calls gave three distinct nonces, and that the encoded value matches the CSP nonce-source charset. It does not establish that no cache layer (CDN, Vercel, or Next's full-route cache on routes that later go static) serves one rendered nonce to several requests. It also does not establish whether Next stamps that nonce onto its scripts (merged-report claims), or the Edge-runtime premise in the `proxy.ts:35-36` comment.

The nonce is created inside the exported function's body:

```ts
// proxy.ts:34-37
export function proxy(request: NextRequest): NextResponse {
  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
  // available in the Edge runtime that Next proxy runs in.
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```
(excerpt ends :37; enclosing `proxy()` continues to :49 — read. The nonce flows to `x-nonce` at :42 and to `buildCsp(nonce)` at :47. No module-level variable holds it.)

What gets base64-encoded is the 36-character UUID *text*, not 16 raw bytes. Entropy is still the UUIDv4's 122 random bits, and the encoding is 48 characters long. In the executed run, `proxy()` was called three times with a real `NextRequest`. Every nonce decoded to a valid UUIDv4 string of 36 bytes and matched `/^[A-Za-z0-9+\/_-]+={0,2}$/` (the CSP `base64-value` grammar), and the run printed `distinct nonces 3 of 3`. Quoted from the log: `nonce: NDUzMTM5NjktOTA1MS00ODNkLTgxNjgtNTMwZjllYTNlNmQ4 len 48 valid-nonce-source-charset true decoded: 45313969-9051-483d-8168-530f9ea3e6d8 isUUIDv4 true decodedBytes 36`.

Corroboration only, not part of this verdict: r3's self-hosted `next start` capture shows `Cache-Control: private, no-cache, no-store, max-age=0, must-revalidate` on `/` (`fc-r3-logs/root-headers.txt`). That supports the critic's open cache question for self-hosting only.

Command: `timeout 60 node --no-warnings --experimental-strip-types --import 'data:text/javascript,<register resolve hook next/server -> next/server.js>' --input-type=module -e "<probe>"`, cwd `.../csp-fc-r3`, 2026-11-19T18:35:52Z, exit 0. The hook works around Node ESM's lack of extension resolution for `next/server`. It does not change the module that loads.

**Evidence:** `proxy.ts:34-49`, `stage25-logs/proxy-invoke.log`, `stage25-logs/proxy-invoke.probe.mjs.txt`

---

## Claim 20: "The emitted script-src contains neither 'unsafe-inline' nor 'unsafe-eval', and the policy sets object-src 'none', base-uri 'self' and frame-ancestors 'none'."

**Submitted by:** security-reviewer
**Location:** `proxy.ts:20-30`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exact header string `proxy()` sets on its `NextResponse`. It does not establish that this header reaches the browser unmodified on every deployment (Vercel, other hosts), or that the policy is functionally correct. That correctness is the subject of other claims: Next's nonce stamping and `connect-src` versus `fetch(data:)` in the merged report. It also does not establish anything about `style-src`, which does carry `'unsafe-inline'`.

```ts
// proxy.ts:20-30
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
  ];
```
(excerpt ends :30; enclosing `buildCsp()` continues to :32 — read: `return directives.join("; ");`. Its value goes to `response.headers.set("Content-Security-Policy", buildCsp(nonce))` at `proxy.ts:47`.)

In the executed run, all three calls printed `script-src: script-src 'self' 'nonce-…' 'strict-dynamic' has unsafe-inline false has unsafe-eval false`, `directive count 9`, and a full header ending `frame-ancestors 'none'; base-uri 'self'; object-src 'none'`. The policy has no other `script-src`-family directive (no `script-src-elem` or `-attr`), so nothing else loosens it.

Command: the same probe and provenance as Claim 19 (cwd `.../csp-fc-r3`, 2026-11-19T18:35:52Z, exit 0).

**Evidence:** `proxy.ts:19-32`, `proxy.ts:47`, `stage25-logs/proxy-invoke.log`

---

## Claim 21: "The only HTML sink for LLM output in `app/` is ReactMarkdown in `LatexRenderer.tsx:34-39`, configured with rehypeKatex only (no rehype-raw); no `dangerouslySetInnerHTML`, `innerHTML`, `eval(` or `new Function` in `app/`."

**Submitted by:** security-reviewer
**Location:** `app/components/features/output-editing/LatexRenderer.tsx:9-10,34-39`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers source under `app/` at d90d6bb: the plugin configuration of the one ReactMarkdown use, and the absence of the named raw-HTML and code-eval sinks plus their near relatives. It does not establish that third-party libraries rendering LLM-derived data (reactflow node labels, KaTeX output under default options, react-markdown's default `urlTransform` for link hrefs) have no internal sink. It also does not cover code outside `app/` or sinks added after d90d6bb.

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:9-10
const remarkPlugins = [remarkGfm, remarkMath];
const rehypePlugins = [rehypeKatex];
```

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:34-39
      <ReactMarkdown
        remarkPlugins={remarkPlugins}
        rehypePlugins={rehypePlugins}
      >
        {value}
      </ReactMarkdown>
```
(excerpt ends :39; enclosing `LatexRenderer()` runs :17-42 — read. The empty-value branch at :18-27 renders a static string.)

The component passes no `allowDangerousHtml`, `skipHtml`, `urlTransform` or KaTeX `trust` option. Grep for those option names in `app/` (excluding tests) found nothing (paraphrased — no quote available because the claim covers absence of code: no matching grep results). `rg -n "dangerouslySetInnerHTML|innerHTML|eval\(|new Function|rehype-raw|rehypeRaw" app` also found nothing. So did a wider sweep for `.html(`, `renderToString`, `katex.render`, `DOMParser`, `createContextualFragment`, `outerHTML`, `setHTML`, `insertAdjacentHTML`, `document.write`, `srcDoc` and `iframe` (paraphrased — no quote available because the claim covers absence of code: no matching grep results). `ReactMarkdown` appears only in `LatexRenderer.tsx` (`:3`, `:34`, `:39`), and `LatexRenderer` has one caller, `app/components/features/output-editing/EditableOutput.tsx:139` (`<LatexRenderer value={value} />`). The one HTML-converting dependency imported in `app/`, mammoth, is called as `mammoth.extractRawText({ arrayBuffer: buffer })` (`app/lib/utils/fileExtraction.ts:62`). That returns text, not HTML, and its input is the user's file, not LLM output.

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:1-42`, `app/components/features/output-editing/EditableOutput.tsx:139`, `app/lib/utils/fileExtraction.ts:62`

---

## Claim 22: "The proxy's per-request work is a constant amount of CPU (one randomUUID, one base64 encode of 36 bytes, one copy of the request headers, one join of a 9-element array) with no I/O, no awaits and no module-level state that could grow."

**Submitted by:** performance-reviewer
**Location:** `proxy.ts:34-49`
**Type:** Performance / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the body of `proxy()` and `buildCsp()` and the module's top-level bindings. It does not establish Next's own per-request cost of running a proxy (request cloning, `x-middleware-*` header plumbing). It also does not establish the cost of the dynamic rendering that `await headers()` in `app/layout.tsx:31` forces on every request, which is likely the larger performance effect of this change.

```ts
// proxy.ts:34-49
export function proxy(request: NextRequest): NextResponse {
  ...
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  ...
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
  return response;
}
```
(The `...` elides only the comment lines :35-36 and :39-40. Unit read in full.)

Every enumerated operation is present. The function is synchronous, with no `async` and no `await`, and the executed run in Claim 19 printed `return type NextResponse is promise false` and `decodedBytes 36`. The only module-level bindings are the function `buildCsp` (`proxy.ts:19`) and the constant `config` object (`proxy.ts:51-64`), and neither is mutated. One qualifier is missing. `new Headers(request.headers)` (`proxy.ts:41`) is linear in the number of request headers, not constant. The server's header-size limits cap that cost, and the cost does not grow with app state. "Constant" is therefore right in practice but imprecise: per-request work is O(request headers) plus constant work.

**Evidence:** `proxy.ts:19-32`, `proxy.ts:34-49`, `proxy.ts:51-64`, `stage25-logs/proxy-invoke.log`

---

## Claim 23a: "`proxy` and `config` follow the Next 16 file convention (middleware.ts renamed to proxy.ts)."

**Submitted by:** api-consistency-reviewer
**Location:** `proxy.ts:1-64`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Next 16.2.4's recognition of a root `proxy.ts` with a named `proxy` function export and a `config.matcher` in object form (`source` plus `missing`). It does not establish behavior on other Next versions, a `src/`-layout move, or whether the runtime is Edge or Node.js. The comment at `proxy.ts:35-36` asserts Edge, and this claim does not cover that.

Next's constants define the convention:

```js
// node_modules/next/dist/lib/constants.js:289-290 (csp-fc-r3 copy, next 16.2.4)
const PROXY_FILENAME = 'proxy';
const PROXY_LOCATION_REGEXP = `(?:src/)?${PROXY_FILENAME}`;
```

The export check accepts a named `proxy` function declaration:

```js
// node_modules/next/dist/build/analysis/get-page-static-info.js:263-265
            if (id === 'proxy') {
                hasProxyExport = true;
            }
```
(excerpt ends :265; the enclosing export-scan function continues to the `hasValidExport` computation at :297 and the error branch after it — read: `const hasValidExport = hasDefaultExport || isMiddleware && hasMiddlewareExport || isProxy && hasProxyExport;`.)

`proxy.ts:34` is `export function proxy(request: NextRequest): NextResponse {`, so the check passes. Next's own `getMiddlewareMatchers` compiled the object-form matcher without error (Claim 24's executed run). Corroboration from Stage-1 r3's executed build: its output lists `ƒ Proxy (Middleware)` (`fc-r3-logs/build3.log`).

**Evidence:** `proxy.ts:34`, `proxy.ts:51-64`, `csp-fc-r3/node_modules/next/dist/lib/constants.js:289-290`, `csp-fc-r3/node_modules/next/dist/build/analysis/get-page-static-info.js:255-299`, `fc-r3-logs/build3.log`, `stage25-logs/matcher-compile.log`

---

## Claim 23b: "(Next 16 emits) a deprecation warning for middleware.ts."

**Submitted by:** api-consistency-reviewer
**Location:** `proxy.ts:1-64` (subject: `next build` behavior)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the presence and trigger condition of the warning in next 16.2.4's build source. It does not establish that a build actually prints it. That is a build-command behavior, so execution is required, and execution was blocked here.

The library source has the warning, and it fires whenever a middleware file is found (and throws if a proxy file is also present):

```js
// node_modules/next/dist/build/index.js:640-652 (csp-fc-r3 copy)
            if (middlewareFilePath) {
                if (proxyFilePath) {
                    ...throw ... `Both ${MIDDLEWARE_FILENAME} file ... and ${PROXY_FILENAME} file ... are de...`
                }
                _log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated. Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
            }
```
(the `...` elides the path-joining and error-construction lines :642-649 — read. The block ends :652.)

Statically, the claim is consistent with the source. It concerns what `next build` does, which is an executable guarantee, so static reading caps the verdict at Unverifiable. The blocker: `next build` in the r3 copy fails without egress (`stage25-logs/build.log`: `Failed to fetch \`EB Garamond\` from Google Fonts`, exit 1). Getting past that would mean editing `app/layout.tsx` or creating a probe app, and this pass may do neither. To verify, run `next build` on a copy with fonts stubbed and `proxy.ts` renamed to `middleware.ts`, and look for the warning line.

**Evidence:** `csp-fc-r3/node_modules/next/dist/build/index.js:640-652`, `stage25-logs/build.log`

---

## Claim 24: "The change is additive for `/api` consumers: route handlers are excluded from the matcher, so their JSON/SSE contracts are unchanged."

**Submitted by:** api-consistency-reviewer
**Location:** `proxy.ts:55-62`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that Next's own matcher compiler excludes every `/api…` path (all 16 route handlers live under `app/api/`), so the proxy never runs on them, and that no route handler reads `x-nonce`. It does not establish the side effect that the negative lookahead `(?!api…)` also excludes non-API page paths that merely start with "api" (for example `/apiary` gets no CSP). It also does not establish behavior for route handlers added outside `app/api/` later.

```ts
// proxy.ts:55-62
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
```
(excerpt ends :62; enclosing `config` continues to :64 — read: `  ],` / `};`.)

`getMiddlewareMatchers` from `next/dist/build/analysis/get-page-static-info.js` compiled this to `^(?:\/(_next\/data\/[^/]{1,}))?(?:\/((?!api|_next\/static|_next\/image|favicon.ico).*))(\.json)?[\/#\?]?$`. In the executed run, `/api/analytics`, `/api/edit/inline`, `/api/formalization/lean`, `/api` and `/api/` all printed `matches-proxy: false`, while `/` and `/foo` printed `true` (and `/apiary` printed `false`, the residue named in Scope). `rg --files -g 'route.ts'` lists 16 handlers, all under `./app/api/` (paraphrased — no quote available because the claim is about file layout, not a snippet). `rg -n "x-nonce|headers\(\)" app` matches only `app/layout.tsx:30-31`. Root layouts do not wrap route handlers, so the `await headers()` change does not reach them either. Corroboration from r3's live server: `/api/analytics -> HTTP/1.1 200 OK` with no CSP header (`fc-r3-logs/matcher.txt`).

Command: `timeout 60 node -e "<probe>"`, cwd `.../csp-fc-r3`, 2026-11-19 (timestamp in log header), exit 0.

**Evidence:** `proxy.ts:51-64`, `app/layout.tsx:30-31`, `stage25-logs/matcher-compile.log`, `fc-r3-logs/matcher.txt`

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- **Claim 22** (`proxy.ts:41`): per-request work is O(number of request headers) because of the `new Headers(request.headers)` copy. It is bounded, but "constant" is imprecise.

### Unverifiable
- **Claim 23b** (`node_modules/next/dist/build/index.js:651`): the middleware.ts deprecation warning is in the 16.2.4 build source. Confirming it requires running `next build`, which no egress for Google Fonts blocked here, as did the no-source-edits rule for this pass.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: d90d6bb` as its first line and a `## Submitted Claims` section verdicting each listed claim.
- Answered: yes
- Out of scope: new claims harvested from the diff (Stage 1 owns those); browser-side CSP enforcement and Next's nonce stamping (merged-report claims); cache-layer behavior on Vercel (S1's open residue)
- Escalate: (1) My failed `next build` partly cleared `.next` in `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/csp-fc-r3`, so that copy no longer has a startable prod build. r3's logs in `fc-r3-logs/` are intact. (2) Claim 24's Scope residue: the `(?!api…)` lookahead also strips the CSP from any page path that starts with "api" (`/apiary`). This is a low-severity matcher precision issue the API-consistency or security critic may want to file.
