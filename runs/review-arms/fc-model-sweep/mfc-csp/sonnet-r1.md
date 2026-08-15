# Code Fact-Check Report

Commit: d90d6bb

**Repository:** /workspace/external/cc-review-eval/mfc-csp
**Scope:** branch diff `main...review` (`app/layout.tsx`, `proxy.ts`) + commit messages on `main..review`
**Checked:** 2026-08-15
**Total claims checked:** 8
**Summary:** 3 verified, 1 mostly accurate, 3 incorrect, 0 stale, 1 unverifiable

---

## Claim 1: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:35-36`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High

The comment asserts Next proxy runs in the Edge runtime. The vendored Next.js 16.2.4 docs state the opposite:

```
node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:217-219
## Runtime
Proxy defaults to using the Node.js runtime. The `runtime` config option is not
available in Proxy files. Setting the `runtime` config option in Proxy will throw an error.
```

`proxy.ts` in this repo has no `runtime` export or declaration at all (`proxy.ts:1-64`, paraphrased — no quote available because the claim is about the absence of a runtime declaration, not a snippet), so it falls through to the documented default: Node.js runtime, not Edge. `package.json` pins `"next": "16.2.4"` (`package.json`, paraphrased — no quote available because the assertion is a single version-string field, not worth a multi-line snippet), confirming the docs bundled in `node_modules` apply to this project's installed version. `crypto.randomUUID` and `Buffer` are in fact available under Node.js runtime too, so the code itself works, but the stated *mechanism* — "the Edge runtime that Next proxy runs in" — misidentifies which runtime is in play.

**Evidence:** `proxy.ts:34-37`, `package.json` (next dependency line), `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:217-219`

---

## Claim 2: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** Medium

Tailwind v4 in this project is a PostCSS build plugin, not a runtime style injector:

```
postcss.config.mjs
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

and `app/globals.css:1,28` uses `@import "tailwindcss";` and `@theme inline { ... }` — both are Tailwind v4 *build-time CSS authoring syntax* (the `@theme inline` at-rule declares theme tokens that resolve to plain CSS variables at compile time), not a mechanism that writes `style="..."` attributes into rendered markup. Tailwind compiles utility classes into a static stylesheet; it does not "emit inline styles" onto elements.

What the app actually does that requires `style-src 'unsafe-inline'` is its own React `style={{...}}` usage, which React serializes to inline `style` attributes on the DOM:

```
app/components/panels/NodeDetailPanel.tsx:48
            style={{ backgroundColor: status.color }}
```

30 such `style={{` occurrences exist across `app/components/**/*.tsx` (paraphrased — no quote available because the count spans 10+ files and quoting all instances would not add information beyond the one representative snippet above). The comment attributes the CSP carve-out to a Tailwind mechanism that does not exist as described; the real driver is the app's own inline `style` props.

**Evidence:** `proxy.ts:12-14`, `postcss.config.mjs`, `app/globals.css:1,28`, `app/components/panels/NodeDetailPanel.tsx:48`

---

## Claim 3: "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server."

**Location:** `proxy.ts:16-17`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium

The Anthropic and OpenRouter calls do run server-side only: `app/lib/llm/callLlm.ts` imports `randomUUID` from Node's built-in `"crypto"` module —

```
app/lib/llm/callLlm.ts:1,7
import { randomUUID } from "crypto";
...
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

— which is only resolvable server-side, and every importer of `callLlm`/`streamLlm` is a file under `app/api/**/route.ts` or `app/lib/formalization/artifactRoute.ts` (paraphrased — no quote available because the caller list spans eight files across `app/api/` and is a grep-derived import graph rather than a single quotable block), confirming these fetches never run in a client component.

However, "OpenAlex" does not appear anywhere else in the codebase — no route, hook, lib module, `README.md`, or `docs/` file references it (paraphrased — no quote available because the claim covers absence of code across the whole repository, not a snippet to quote). It only occurs in this one comment and its originating commit message (`9b4e453`). The sufficiency argument for the two services that do exist (Anthropic, OpenRouter) checks out; the reference to a third, apparently nonexistent integration (OpenAlex) is either stale or was never implemented, and cannot be verified either way from the current codebase.

**Evidence:** `proxy.ts:16-17`, `app/lib/llm/callLlm.ts:1,7`, `app/api/edit/whole/route.ts:2`, `app/api/formalization/lean/route.ts:2-3`, repo-wide grep for "openalex" (no hits outside `proxy.ts`)

---

## Claim 4: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to `<Script>` tags they render."

**Location:** `proxy.ts:39-40`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** High

No code in the repository reads the `x-nonce` header. A repo-wide search for `x-nonce` (case-insensitive) turns up only its two touchpoints — the header being *set* in `proxy.ts` and a comment referencing it in `layout.tsx`:

```
proxy.ts:42
  requestHeaders.set("x-nonce", nonce);
```

```
app/layout.tsx:30
  // CSP header, so we don't need to read x-nonce here ourselves.
```

There is no `.get("x-nonce")` call anywhere, and a repo-wide search for `next/script` / `<Script` imports returns zero results (paraphrased — no quote available because this is an absence-of-code finding across the whole `app/` tree). So the comment's described consumption path — "layouts... read it via `headers()` and pass it to `<Script>` tags they render" — does not exist in the current code; `app/layout.tsx` deliberately does not read `x-nonce` (see Claim 5), and no `<Script>` component exists to receive it.

**Evidence:** `proxy.ts:39-42`, `app/layout.tsx:27-31`, repo-wide grep for "x-nonce" and "next/script"/"<Script" (no consuming call sites found)

---

## Claim 5: "Opt this layout out of static rendering so proxy.ts runs on every request... Next.js automatically tags its own bootstrap `<script>` elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:27-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Both parts of this claim match the vendored Next.js docs. First, `headers()` is documented as a dynamic-rendering trigger:

```
node_modules/next/dist/docs/01-app/03-api-reference/04-functions/headers.md:48
- `headers` is a [Request-time API]... Using it in will opt a route into
  **[dynamic rendering](/docs/app/glossary#dynamic-rendering)**.
```

Second, the automatic-nonce-tagging behavior is documented exactly as described:

```
node_modules/next/dist/docs/01-app/02-guides/content-security-policy.md:184-193
2. **Next.js extracts the nonce**: During rendering, Next.js parses the
   `Content-Security-Policy` header and extracts the nonce...
3. **Nonce is applied automatically** to:
   - Framework scripts (React, Next.js runtime)
   ...
Because of this automatic behavior, you don't need to manually add a nonce to each tag.
```

`app/layout.tsx:31` does call `await headers()` with no further use of the return value, consistent with "opt out of static rendering" being the sole purpose of the call in this file.

**Evidence:** `app/layout.tsx:27-31`, `node_modules/next/dist/docs/01-app/03-api-reference/04-functions/headers.md:48`, `node_modules/next/dist/docs/01-app/02-guides/content-security-policy.md:184-193`

---

## Claim 6: matcher config — "Apply CSP to page navigations only. Skip API routes..., Next's static assets..., and prefetches..."

**Location:** `proxy.ts:52-63`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

The matcher in the diff is a verbatim match (aside from comment wording) of the pattern the vendored Next.js CSP guide recommends for exactly this purpose:

```
proxy.ts:55-62
  matcher: [
    {
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
```

```
node_modules/next/dist/docs/01-app/02-guides/content-security-policy.md:137-155
{
  source: '/((?!api|_next/static|_next/image|favicon.ico).*)',
  missing: [
    { type: 'header', key: 'next-router-prefetch' },
    { type: 'header', key: 'purpose', value: 'prefetch' },
  ],
}
```

The negative-lookahead `source` regex excludes `api`, `_next/static`, `_next/image`, and `favicon.ico`; the `missing` conditions exclude requests carrying `next-router-prefetch` or `purpose: prefetch` headers, i.e. router prefetches. This matches the comment's description precisely.

**Evidence:** `proxy.ts:52-63`, `node_modules/next/dist/docs/01-app/02-guides/content-security-policy.md:137-155`

---

## Claim 7: Commit `9b4e453` — "File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning)."

**Location:** commit `9b4e453`, body
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High

The rename and version are documented:

```
node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:770
| `v16.0.0` | Middleware is deprecated and renamed to Proxy |
```

And the build-time warning text exists verbatim in the installed Next.js build code:

```
node_modules/next/dist/build/index.js:651
_log.warnOnce(`The "${_constants.MIDDLEWARE_FILENAME}" file convention is deprecated.
Please use "${_constants.PROXY_FILENAME}" instead. Learn more: https://nextjs.org/docs/messages/middleware-to-proxy`);
```

Since `package.json` pins `next@16.2.4`, this project is on the version where `middleware.ts` triggers exactly the described deprecation warning at build/dev time.

**Evidence:** commit `9b4e453` body, `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md:770`, `node_modules/next/dist/build/index.js:651`

---

## Claim 8: Commit `9b4e453` — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates."

**Location:** commit `9b4e453`, body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low

This is a claim about the observed output of running a production build and inspecting emitted HTML/headers at runtime. Static reading of `proxy.ts` and the Next.js docs supports that this *should* happen (see Claim 5/6 evidence), but confirming it actually occurred for this specific commit requires running `npm run build` and `npm start` (or equivalent) and inspecting the served response — runtime behavior outside what static analysis of the repository can establish. No build artifacts or CI logs are present in the repository to substitute for that verification (paraphrased — no quote available because this is an absence-of-evidence finding, not a snippet).

**Evidence:** commit `9b4e453` body — no corresponding build log, CI artifact, or test in the repo to confirm

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`proxy.ts:35-36`): Comment claims Edge runtime; Next.js 16 docs bundled in `node_modules` state proxy defaults to the Node.js runtime and disallows setting `runtime` explicitly. `proxy.ts` declares no runtime, so it runs on the documented Node.js default, not Edge.
- **Claim 2** (`proxy.ts:12-14`): Comment attributes `style-src 'unsafe-inline'` to "Tailwind v4 emits inline styles," but Tailwind v4 here is a PostCSS build plugin producing a static stylesheet; the actual source of inline styles is the app's own 30+ React `style={{...}}` usages.
- **Claim 4** (`proxy.ts:39-40`): Comment claims layouts read `x-nonce` via `headers()` and pass it to `<Script>` tags; no code reads `x-nonce` and no `<Script>` component exists in the repo.

### Mostly Accurate
- **Claim 3** (`proxy.ts:16-17`): Server-to-server sufficiency holds for Anthropic and OpenRouter (verified via `callLlm.ts`'s Node-only `crypto` import and its API-route-only callers), but "OpenAlex" is not referenced anywhere else in the codebase — the claim names a third service that appears nonexistent in the current repo.

### Unverifiable
- **Claim 8** (commit `9b4e453` body): "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag" is a runtime-observation claim with no build log or test artifact in the repo to confirm it for this commit.
