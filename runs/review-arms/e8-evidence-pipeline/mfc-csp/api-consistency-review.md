# API Consistency Review — mfc-csp CSP middleware/proxy

**Commit:** d90d6bb
**Scope:** `git diff d86d2dc...HEAD` (d90d6bb) — `proxy.ts` (new), `app/layout.tsx` — in `/workspace/external/cc-review-eval/mfc-csp`
**Date:** 2026-08-18
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/code-fact-check-report.md` (merged k=2; its verdicts bind — notably: served scripts DO carry nonces matching the response CSP header, so the nonce mechanism works end-to-end on self-hosted Next; Claims 1b, 5, 6b, 7c are Incorrect)

## Baseline Conventions

Surveyed before reviewing the diff:

- **No prior header surface.** `next.config.ts` is empty (`/* config options here */` only) — no `headers()` config, no security headers anywhere else. This diff establishes the project's first response-header contract and its first custom request header. There is no `middleware.ts` in history to be consistent with; `proxy.ts` is the Next 16 convention name (fact-check Claim 3, Verified).
- **API routes** (`app/api/**/route.ts`, 10+ files, e.g. `app/api/predict/route.ts`) export `GET`/`POST`, return `NextResponse.json(...)`, and use a flat `{ error: "<message>" }` error envelope with explicit status. None set custom headers.
- **Function naming** in `app/lib/**` is camelCase verb-noun (`predictCall`, `callLlm`, `streamLlm`).
- **No `next/script` usage anywhere** in `app/` (grep: zero matches) — relevant to the `<Script>` contract promised in `proxy.ts:39-40`.
- **No consumer of `x-nonce`** exists: repo-wide grep finds the header name only at its set-site (`proxy.ts:42`) and in the `app/layout.tsx:30` comment (corroborated by fact-check Claim 2's grep).

Because most of this surface is first-of-its-kind, the dominant consistency questions are *self*-consistency (do the two files agree with each other and with what the code does) and deliberateness of the conventions being established.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `proxy` (exported fn) | function | _(framework-mandated convention name; no sibling middleware)_ | `node_modules/next/dist/lib/constants.js:287-290` (`PROXY_FILENAME = 'proxy'`) | Consistent — required by Next 16's file convention; build recognized it (fact-check Claim 3) |
| `config` (exported const with `matcher`) | config export | _(framework-mandated)_ | Next proxy/middleware convention | Consistent — standard shape, `matcher` only |
| `buildCsp` | function (module-private) | `predictCall`, `callLlm`, `streamLlm` | `app/lib/llm/*.ts` | Consistent — camelCase verb-noun matches; private, so not expanded to a finding |
| `x-nonce` | request header field | _(no existing custom request headers found)_ | none — searched `app/`, `proxy.ts`, `next.config.ts` for header-set sites | New category — lowercase `x-`-prefixed; convention being established, but the header itself is unconsumed (Finding 1) |
| `Content-Security-Policy` | response header field | _(no existing response headers set by app code)_ | none — searched `app/api/**/route.ts`, `next.config.ts` | Consistent with the standard header name; note casing style differs from `x-nonce` (canonical Train-Case vs lowercase) — cosmetic only, HTTP headers are case-insensitive |
| `RootLayout` (now `async`) | component signature | `RootLayout` (previous sync form) | `app/layout.tsx` (pre-diff) | Consistent — sole consumer is the Next framework, which accepts async server components; not a consumer-visible break |

No new endpoint routes, error codes, or event names are introduced.

## Findings

#### 1. `x-nonce` request header is produced but never consumed — dead plumbing with a contract comment promising a consumer that doesn't exist

**Severity:** Inconsistent
**Location:** `proxy.ts:39-42` (with `app/layout.tsx:27-31`)
**Move:** #3 (trace the consumer contract)
**Confidence:** High

No existing precedent in `app/`, `proxy.ts`, `next.config.ts` (searched all header-set and header-read sites; this is the codebase's first custom request header)

`proxy.ts:39-40` states the header is forwarded "so layouts can read it via `headers()` and pass it to `<Script>` tags they render." Per the fact-check (Claim 2, Verified; Claim 8's Scope note), nothing in `app/` reads `x-nonce`, and there are zero `next/script` usages in the repo — the promised consumer does not exist. Meanwhile `app/layout.tsx:30` says the opposite: "we don't need to read x-nonce here ourselves." The two comments describe contradictory contracts for the same header: producer-side says "here's your channel, layouts"; consumer-side says "channel not needed." Scoped per the fact-check: this is *not* a functional break — Next tags its scripts from the response CSP header (Claim 2, executed) — it is dead API surface whose documentation misleads the next maintainer into thinking something binds to it (e.g., fearing a rename of `x-nonce` breaks layouts, or conversely adding a `<Script>` and hunting for why the comment's flow was never wired up).

**Recommendation:** Either delete the `x-nonce` forwarding (three lines: `requestHeaders` construction, `.set`, and the `request: { headers }` option, reverting to bare `NextResponse.next()`) or reword `proxy.ts:39-40` to say the header is *currently unused* provisioning for future manual `<Script>` tags, and cross-reference the `app/layout.tsx` comment so the two files tell one story.

#### 2. `style-src 'unsafe-inline'` rationale misattributes the constraint — a maintainer following the documented contract cannot tighten the directive correctly

**Severity:** Minor
**Location:** `proxy.ts:12-14`, `proxy.ts:23`
**Move:** #3 (documentation drift), building on fact-check Claim 5 (Incorrect, executed)
**Confidence:** High

The comment presents `'unsafe-inline'` as a Tailwind-v4 carve-out ("Tailwind v4 emits inline styles"). Fact-check Claim 5 refutes this by execution in both dev and prod: Tailwind ships external nonced stylesheets (0 inline `<style>` elements); the actual consumers of the carve-out are 4 `style={{...}}` attributes in the app's own components (`IconRail.tsx`, `ArtifactPanelShell.tsx`, ...). The directive value itself is fine, but the documented contract for *why* it exists points at the wrong dependency: someone attempting to tighten `style-src` would rework Tailwind's shipping and still break the app's own inline style attributes.

**Recommendation:** Reword to attribute the carve-out to the app's `style={{...}}` props (and any client-runtime injection), not Tailwind's output.

#### 3. Layout comment misstates the causal contract between rendering mode and proxy execution

**Severity:** Minor
**Location:** `app/layout.tsx:27-28`
**Move:** #3 (documentation drift), building on fact-check Claim 1b (Incorrect)
**Confidence:** Medium (matches the fact-check's Medium — the static-route counterfactual was not executed)

"Opt this layout out of static rendering so proxy.ts runs on every request" inverts the mechanism: proxy execution is governed solely by `config.matcher` (`proxy.ts:55-63`), not by any route's rendering mode. What `await headers()` actually buys is per-request HTML re-rendering so the baked-in nonce matches the fresh CSP header (Claims 1a/1c, Verified). A maintainer trusting this comment could conclude that removing `await headers()` stops the proxy running — it wouldn't; it would instead serve stale-nonce HTML against fresh CSP headers, a much subtler failure.

**Recommendation:** Reword to: "Opt this layout out of static rendering so the HTML is re-rendered per request and its embedded nonce matches the fresh CSP header that proxy.ts attaches."

#### 4. Comment references an `OpenAlex` integration that does not exist in this codebase

**Severity:** Minor
**Location:** `proxy.ts:16-17`
**Move:** #3 (documentation drift), building on fact-check Claim 6b (Incorrect, High)
**Confidence:** High

The `connect-src 'self'` justification enumerates "Anthropic / OpenAlex / OpenRouter" server-to-server calls. Per the fact-check, no OpenAlex call, client, URL, or symbol exists anywhere in the repo or its git history; Anthropic and OpenRouter are real (`app/lib/llm/callLlm.ts`). The conclusion (`connect-src 'self'` suffices) is unaffected, but the enumeration is part of the directive's documented contract — a future reader auditing whether `connect-src` can stay `'self'` will search for an integration that was never there.

**Recommendation:** Drop "OpenAlex" from the comment.

#### 5. Runtime claim in the nonce-generation comment is wrong (Edge vs Node.js)

**Severity:** Minor
**Location:** `proxy.ts:35-36`
**Move:** #3 (documentation drift), building on fact-check Claim 7c (Incorrect, High, executed build manifest `"runtime": "nodejs"`)
**Confidence:** High

"available in the Edge runtime that Next proxy runs in" — Next 16 always runs the proxy on the Node.js runtime (Next's own build analysis says so unconditionally, and the built manifest records `nodejs`). The code works either way (Claim 7b, Verified), but the documented environment contract steers maintainers toward Edge constraints (avoiding Node-only APIs, treating `Buffer` as a polyfill) that don't apply.

**Recommendation:** Change to "the Node.js runtime that Next 16's proxy always runs on."

#### 6. Matcher excludes by path *prefix*, broader than the "Skip API routes" contract the comment states

**Severity:** Minor
**Location:** `proxy.ts:52-63`
**Move:** #3 (consumer contract — subtle scope mismatch between documented and actual behavior)
**Confidence:** Medium

The negative lookahead `(?!api|_next/static|_next/image|favicon.ico)` anchors at the path start with no trailing `/` or boundary, so any future page route beginning with those strings — e.g. `/apikeys`, `/apidocs` — would silently receive no CSP header at all, not merely "API routes" as the comment promises. (Likewise `favicon.ico`'s unescaped `.` matches any character, e.g. `/favicon-ico`.) The fact-check verified the matcher's behavior on the probed route classes (Claim 9) but explicitly did not exhaustively cover all route shapes. Today no such colliding routes exist, so this is a latent contract gap rather than a live bug — but the failure mode is a page shipping with zero CSP, the exact thing this diff exists to prevent.

**Recommendation:** Tighten the exclusions to `api/` (`(?!api/|_next/static|_next/image|favicon\.ico)`) or note the prefix semantics in the comment so future route naming avoids the collision.

#### 7. First-of-its-kind conventions being established — worth making deliberate

**Severity:** Informational
**Location:** `proxy.ts` (whole file), `next.config.ts`
**Move:** #1 / #6
**Confidence:** High

This diff establishes three conventions with no prior codebase precedent: (a) security headers are set in the proxy rather than `next.config.ts#headers()` — a reasonable and necessary choice here since the nonce must be per-request, but future static headers (HSTS, `X-Content-Type-Options`, `Referrer-Policy`) now have two plausible homes; (b) custom request headers use lowercase `x-` prefix (`x-nonce`); (c) the CSP directive set itself (notably no explicit `frame-src`, `worker-src`, or `form-action` — all falling through to `default-src 'self'`, which is coherent) is now the contract every future asset class (workers, iframes, external fonts/images) must be checked against. None of these is a violation — there was nothing to violate — but they should be treated as deliberate precedent, ideally with a line in `docs/decisions/`.

## What Looks Good

- **The core nonce contract is sound and verified end-to-end**: fresh nonce per request (Claims 1c/7a), every generated `<script>` tag carries the value from the same response's CSP header (Claims 2, 12, executed in dev and prod). The response-side contract consumers actually depend on — the browser's CSP enforcement matching the served HTML — is internally consistent.
- **`proxy`/`config` naming and file placement** follow Next 16's convention exactly (Claim 3); no legacy `middleware.ts` left behind to create a dual-surface ambiguity.
- **The matcher's request-header conditions** (`next-router-prefetch`, `purpose: prefetch`) use Next's documented `missing` mechanism, and its skip behavior was execution-verified across route classes (Claim 9).
- **`RootLayout` going async is backward-compatible** — its only consumer is the framework; no props or exports changed.
- **The cleanup commit kept the directive set byte-identical** (Claim 13) — no contract churn across the three commits.
- **`buildCsp`** matches the codebase's camelCase verb-noun function naming (`callLlm`, `predictCall`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `x-nonce` produced but never consumed; proxy.ts and layout.tsx comments state contradictory contracts for it | Inconsistent | `proxy.ts:39-42` | High |
| 2 | `style-src 'unsafe-inline'` rationale misattributes the constraint to Tailwind | Minor | `proxy.ts:12-14` | High |
| 3 | Layout comment misstates why proxy runs per request | Minor | `app/layout.tsx:27-28` | Medium |
| 4 | Fabricated OpenAlex reference in `connect-src` rationale | Minor | `proxy.ts:16-17` | High |
| 5 | Edge-runtime claim wrong (proxy runs on Node.js) | Minor | `proxy.ts:35-36` | High |
| 6 | Matcher excludes by prefix, broader than the "Skip API routes" comment | Minor | `proxy.ts:52-63` | Medium |
| 7 | Three first-of-their-kind conventions established; make deliberate | Informational | `proxy.ts` | High |

## Overall Assessment

The consumer-facing mechanism this diff ships — per-request nonced CSP with `strict-dynamic` — is functionally consistent and execution-verified: the response header and the served HTML agree on every probe, and the framework-mandated names (`proxy`, `config`) are exactly right. The consistency problems are all in the *documented* contract rather than the enforced one: a dead `x-nonce` channel whose two comments contradict each other (Finding 1), and four comment claims the fact-check refuted (Findings 2-5) that would each steer a maintainer's next change in the wrong direction — misdirected style-src tightening, wrong causal model for the `headers()` opt-out, a phantom integration, and phantom Edge constraints. Everything is fixable in place with comment rewrites plus either deleting or honestly labeling the `x-nonce` plumbing; nothing requires re-architecting, and no existing consumer breaks. Since this surface has no prior precedent in the codebase, the main ask beyond the fixes is that the conventions it establishes (proxy-owned headers, `x-` header prefix, the directive set) be recorded as deliberate decisions.
