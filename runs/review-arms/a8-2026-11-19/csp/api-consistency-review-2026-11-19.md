Commit: d90d6bb

# API Consistency Review — meta-formalism-copilot d86d2dc..d90d6bb (strict CSP proxy)

**Scope:** `git diff d86d2dc..d90d6bb` (proxy.ts new, app/layout.tsx modified), 3 commits
**Date:** 2026-11-19
**Based on:** code-fact-check-report.md (merged k=3, same directory); documented behaviour is taken from it and not re-verified

## Baseline Conventions

The change adds no HTTP endpoints. What it publishes is (a) the module exports Next.js picks up by name from `proxy.ts` (`proxy`, `config`), (b) one request header (`x-nonce`) that it injects for server components, (c) one response header (`Content-Security-Policy`) that every in-repo browser-side consumer now has to work within, and (d) a change to the root layout's render mode. Here is the baseline I compared it against:

- **Route-handler modules** (`app/api/**/route.ts`, 17 route/page files): one import line, `import { NextRequest, NextResponse } from "next/server";`, and HTTP-verb exports with no return type annotation (`export async function POST(request: NextRequest) {`, for example `app/api/edit/inline/route.ts:10`, `app/api/refine/context/route.ts:29`). Library helpers in `app/lib/**` usually do annotate return types (46 `): string|Promise|NextResponse|void` hits).
- **Helper naming:** `build<Noun>` for pure constructors (`buildUserMessage` at `app/lib/formalization/artifactRoute.ts:10`, `buildLine` / `buildPropositionIndex` at `app/lib/utils/pdfPropositionParser.ts:189,354`). Acronyms use camelCase with only the first letter capitalized (`streamLlm` in `app/lib/llm/streamLlm.ts`).
- **Shared header sets:** live as exported `as const` objects in `app/lib/` (`SSE_HEADERS` at `app/lib/llm/streamLlm.ts:12-16`). The repo has no custom `x-*` headers before this change (`rg 'x-[a-z-]+'` over `app/` finds only CSS class hits).
- **Browser-side consumers of the response policy:** `app/lib/utils/exportGraph.ts` (`fetch(dataUrl)`), `app/lib/utils/fileExtraction.ts` and `app/lib/utils/pdfPropositionParser.ts` (pdf.js module worker), KaTeX, React Flow and React `style={{}}` props.
- **Project docs:** `CLAUDE.md` "Directory Layout (under `app/`)" lists every top-level file with a one-line role, including `layout.tsx — Sets up fonts ... and metadata`. Nothing in `README.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `docs/` or `documentation/` mentions CSP, proxy or middleware (rg for `csp|content-security|middleware|proxy|nonce` found only unrelated Zustand-middleware notes).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `proxy` (export) | exported function | `middleware` (the pre-16 name); `GET`/`POST`/`DELETE` route exports | `app/api/**/route.ts`; Next 16 file convention | Consistent: Next requires this name for `proxy.ts` |
| `config` (export) | exported config object | none in repo (`rg 'export const (config\|runtime\|dynamic)' app` finds no hits) | none — searched `app/**` | New category; Next requires this name |
| `buildCsp` | module-private function | `buildUserMessage`, `buildPropositionIndex`, `buildLine` | `app/lib/formalization/artifactRoute.ts:10`, `app/lib/utils/pdfPropositionParser.ts:189,354` | Consistent: `build<Noun>`, acronym cased like `streamLlm` |
| `x-nonce` | request header | none (no custom headers in repo); `SSE_HEADERS` keys are standard headers | none — searched `app/**` for `x-[a-z-]+` and `headers.set` | New category; follows Next's own docs example. See Finding 2 for the contract problem, which is not a naming issue |
| `Content-Security-Policy` | response header | `Content-Type`, `Cache-Control` in `SSE_HEADERS` | `app/lib/llm/streamLlm.ts:12-16` | Consistent casing. Defined inline rather than as a shared const (fine, since it has one producer) |

None of these names is inconsistent, so no naming finding comes out of this table.

## Findings

#### 1. The published CSP breaks existing in-repo consumers that the policy does not account for

**Severity:** Breaking
**Location:** `proxy.ts:26` (directive), with consumers at `app/lib/utils/exportGraph.ts:24,37` and `app/lib/utils/fileExtraction.ts:26-29`
**Move:** 3 (trace the consumer contract)
**Confidence:** High for the export path (fact-check Claim 8, 3/3 replicates). Medium for the pdf.js worker (fact-check Claim 5 caveat, E3; not executed).
**Legibility-target:** for-author

Evidence (`proxy.ts:26`):
```
    "connect-src 'self'",
```
Evidence (`app/lib/utils/exportGraph.ts:20-26`, enclosing `downloadGraphAsPng` runs from :16 to :27, all of it read):
```
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
```
Evidence (`app/lib/utils/fileExtraction.ts:26-29`, enclosing `getPdfjs()` runs from :24 to :31, all of it read):
```
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url,
  ).toString();
```
The response header acts as a contract that every browser-side caller in the repo must now satisfy. Code that worked before this change, `fetch(dataUrl)` in `downloadGraphAsPng` and `graphToPngBlob` (:30-39), does not satisfy it: `data:` is not in `connect-src`, so PNG export and Export All fail, and the user sees only a console.error. The commit body justifies `connect-src 'self'` by naming the server-to-server callers (Anthropic, OpenAlex, OpenRouter) and does not list the in-browser callers, so the author audited the wrong set of consumers. The policy also has no `worker-src`, which means workers fall back to `script-src`, whose `'strict-dynamic'` ignores `'self'`. That may block the pdf.js worker that two utilities configure (E3).

**Recommendation:** List the browser-side fetch/worker/style consumers (the four files above, plus KaTeX and React Flow) and either widen the policy for them (`connect-src 'self' data: blob:`, `worker-src 'self' blob:`) or change the consumers (for example, decode the data URL without `fetch`). Add a test or a manual checklist item that exercises graph export and PDF upload under the header.

#### 2. `x-nonce` is published with a documented consumer that the same change says does not exist

**Severity:** Inconsistent
**Location:** `proxy.ts:39-42`, `app/layout.tsx:27-31`
**Move:** 7 (asymmetry between producer and consumer) and 3 (documentation drift)
**Confidence:** High (fact-check Claim 11: no reader of `x-nonce` and no `<Script>` in the repo)
**Legibility-target:** for-author

Evidence (`proxy.ts:39-42`, enclosing `proxy()` continues to :49, read):
```
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```
Evidence (`app/layout.tsx:27-31`, enclosing `RootLayout` continues to :42, read):
```
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```
The producer documents an interface ("layouts can read it via `headers()`"), and the only layout explicitly declines to use it. A future author who adds a `<Script>` will find two comments that disagree about how a nonce is supposed to reach it. Neither comment describes the mechanism Next actually reads, which is the `Content-Security-Policy` *request* header (fact-check Claim 3; see Finding 3). The d90d6bb body ("the nonce is only written, never read by the layout") shows the author noticed that the header has no reader but kept the producer-side comment that advertises one.

**Recommendation:** Pick one contract and state it in one place. Either remove `x-nonce` and rewrite proxy.ts:39-40 to say what the forwarded request headers are for, or keep it, mark it as reserved for future `<Script nonce>` use, and make layout.tsx's comment point there.

#### 3. The nonce handoff to Next relies on an undocumented router side effect rather than Next's published contract

**Severity:** Inconsistent
**Location:** `proxy.ts:41-47`
**Move:** 3 (consumer contract, where the consumer is the Next renderer)
**Confidence:** Medium (static replicates r1/r2 say no nonce reaches Next. Executed replicate r3 found 15/15 scripts carrying the nonce on `next start` because of `resolve-routes.js:443-446`. Vercel behaviour is unconfirmed. Already escalated as E1.)
**Legibility-target:** for-orchestrator-synthesis

Evidence (`proxy.ts:41-47`):
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```
Next's documented interface for nonce extraction is a CSP header on the forwarded *request*. The proxy sets CSP only on the response, so nonce tagging works only if the self-hosted router copies response headers onto `req.headers`. That copy is internal behaviour with no contract behind it, and it can differ on the deploy target the commit names (Vercel preview). I am raising this as a contract-consistency observation and leave exploitability and availability to security-reviewer and architecture-review under E1.

**Recommendation:** Also set `Content-Security-Policy` on `requestHeaders` before `NextResponse.next`, so the renderer receives the nonce through the documented path whatever the host does.

#### 4. The new request-path component and the layout's changed render mode are missing from the project's directory map

**Severity:** Minor
**Location:** `CLAUDE.md` "Directory Layout (under `app/`)", `layout.tsx` row; `proxy.ts` (repo root, not listed)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`CLAUDE.md`, Directory Layout section):
```
- `layout.tsx` — Sets up fonts (EB Garamond serif + Geist Mono) and metadata
```
`CLAUDE.md` is where this repo describes each top-level file's role, and agents working in the repo rely on it. After the change, `layout.tsx` also forces dynamic rendering for the whole app, and a root-level `proxy.ts` sets a policy that constrains every future client-side fetch, worker, inline script and external asset. Neither fact appears in it. Future work such as adding an external image, a browser-side fetch or a `<Script>` would hit the CSP with no hint from the docs. Finding 1 is an example of exactly that.

**Recommendation:** Add a `proxy.ts` entry that names the CSP and its carve-outs, and update the `layout.tsx` row to say it is intentionally dynamic. Optionally add a Code Guidelines bullet such as "new browser-side origins/data: fetches/workers require a proxy.ts CSP update".

#### 5. Matcher exclusions are prefix-based and do not line up with the repo's route layout

**Severity:** Informational
**Location:** `proxy.ts:57`
**Move:** 3 (contract scope)
**Confidence:** Medium (fact-check Claim 12, "Mostly accurate")
**Legibility-target:** for-author

Evidence (`proxy.ts:57`, enclosing `config` runs from :51 to :64, read):
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
The repo's API convention is `app/api/<domain>/...`, so the intended exclusion is the `api/` segment. `(?!api` also excludes any future page whose path starts with `api` (for example `/apiary`), and that page would then ship without a CSP. `public/` files (`*.svg`) still match. The repo does not use `next/image`, so the `_next/image` exclusion has no effect. Only `app/page.tsx` exists today, so none of this causes a problem yet.

**Recommendation:** Anchor the exclusion as `api/` and `_next/image/`, or leave it and add a comment that the exclusions are prefix matches.

#### 6. The proxy module's import and signature style differs from the sibling `next/server` modules

**Severity:** Informational
**Location:** `proxy.ts:1-2`, `proxy.ts:34`
**Move:** 1/2 (baseline style, not a naming finding)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`proxy.ts:1-2`, `proxy.ts:34`):
```
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
```
```
export function proxy(request: NextRequest): NextResponse {
```
The route handlers that import from `next/server` use a single `import { NextRequest, NextResponse } from "next/server";` and omit return types (`app/api/edit/inline/route.ts:1,10`). The `app/lib` helpers do annotate return types, so the explicit `: NextResponse` added in d90d6bb matches one local convention and not the other. This is harmless and recorded only so the author knows the choice is visible.

**Recommendation:** None required.

## What Looks Good

- `proxy` and `config` follow the Next 16 file convention. The commit body records why the file is not named `middleware.ts` (route: code-fact-check. The rename and its deprecation warning come from the commit body, and this review did not verify them).
- `buildCsp` matches the repo's `build<Noun>` helper pattern and its acronym casing, and it is module-private, so it adds no exported surface.
- The `style-src 'unsafe-inline'` carve-out is written down in the module docblock rather than left implicit. The stated reason is wrong (fact-check Claim 6: React `style` props, KaTeX and React Flow need it, not Tailwind), but documenting a deliberate carve-out is the right practice.
- The change is additive for `/api` consumers: route handlers are excluded from the matcher, so their JSON/SSE contracts (`SSE_HEADERS`) are unchanged (route: code-fact-check, matcher exclusion of `/api/*`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | CSP breaks existing browser-side consumers (graph PNG / Export All via `fetch(data:)`; pdf.js worker likely) | Breaking | `proxy.ts:26`; `exportGraph.ts:24,37`; `fileExtraction.ts:26-29` | High / Medium |
| 2 | `x-nonce` published with a documented reader the layout says doesn't exist | Inconsistent | `proxy.ts:39-42`, `app/layout.tsx:27-31` | High |
| 3 | Nonce handoff relies on router side effect, not Next's request-header contract | Inconsistent | `proxy.ts:41-47` | Medium |
| 4 | `CLAUDE.md` directory map omits `proxy.ts` and the layout's dynamic mode | Minor | `CLAUDE.md` Directory Layout | High |
| 5 | Matcher exclusions are unanchored prefixes | Informational | `proxy.ts:57` | Medium |
| 6 | Import and return-type style differs from sibling `next/server` modules | Informational | `proxy.ts:1-2,34` | High |

## Overall Assessment

The new names are consistent with the codebase. The problems are in the contracts. The CSP header is a new constraint on every browser-side caller in the repo, and the author justified it against the server-side callers instead. As a result, existing graph export breaks and the pdf.js worker is at risk. Inside the change, the `x-nonce` interface is documented by its producer and disowned by its only consumer, and the real handoff to Next goes through an undocumented router copy rather than the request-header path Next documents. All of this can be fixed in place: widen `connect-src`/`worker-src` or adjust the consumers, set CSP on the forwarded request headers, settle the `x-nonce` story, and add `proxy.ts` to `CLAUDE.md`. Consumer impact before any fix is a user-visible regression in export and possibly PDF upload, plus a nonce path that may not hold on Vercel.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: d90d6bb` as its first line, structured per the api-consistency-reviewer skill.
- Answered: yes
- Out of scope: Exploitability of the CSP gaps and whether 'strict-dynamic' fully blocks scripts on Vercel (security-reviewer, E1/E3); module-structure placement of proxy.ts (architecture-review). Pagination, error-envelope, idempotency and nullability moves do not apply because the change adds no endpoint or field.
- Escalate: (a) Finding 1: the export breakage via `connect-src` is Breaking for existing in-repo consumers, which reinforces E2 and E3 for security-reviewer; the pdf.js worker blockage needs an executed check. (b) Finding 3 duplicates E1: setting CSP on `requestHeaders` is the contract-level fix, and Vercel behaviour remains unconfirmed. (c) E4 (OpenAlex named with no code) is unchanged by this review.
- Decisions I made: I treated the CSP response header and the `x-nonce` request header as the change's "public surface" because there are no endpoints. I rated Finding 1 as Breaking under move 3 because previously working in-repo callers stop working, and I relied on the fact-check's 3/3 verdict instead of re-executing it.
