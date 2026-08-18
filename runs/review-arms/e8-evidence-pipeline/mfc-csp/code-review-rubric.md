# Code Review Rubric

**Commit:** d90d6bb
**Scope:** `d86d2dc..d90d6bb` — `proxy.ts` (new CSP proxy, strict-dynamic per-request nonces), `app/layout.tsx` (static-render opt-out) | **Reviewed:** 2026-08-18 | **Status: 🔴 DOES NOT PASS** — 1 red item unresolved

Panel: fact-check (k=2, merged most-severe-wins) + security, performance, api-consistency (core) + test-strategy (contextual, advisory) + Stage-2.5 submitted-claims (3 routed, all Verified). Dispatch mode: parallel.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Cannot pass review with any red item unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | Matcher exclusions are prefix-matched, not segment-exact: the negative-lookahead `(?!api\|_next/static\|_next/image\|favicon.ico)` excludes any first path segment merely *beginning with* those literals, and the unescaped `.` widens `favicon.ico` to `favicon<any>ico`. A future `app/apikeys/page.tsx` (or `/apidocs`, `/faviconXico`) ships an HTML page with a real script surface and **no CSP header at all**, silently — the exact failure this diff exists to prevent. Latent today (only `/` is a page route), reachable by ordinary development. **Escalated 🟡→🔴** per the Escalation Rule: `Convergence: security (Medium) + api-consistency (#6 Minor)` — two core critics — plus corroboration by executed regex evidence (`evidence/sec-matcher-regex.txt`, which reproduces Next's compilation and confirms `/apidocs`,`/api-keys`,`/_next/staticx`,`/faviconXico` SKIP → no CSP while `/settings/apidata` correctly MATCHES). test-strategy G6 (top-ranked gap) agrees but is contextual and does not count toward escalation. Fix: anchor to whole segments `(?!api\|_next/static\|_next/image\|favicon\.ico)(?:/\|$)` and escape the dot. | Security | Medium (native) | `proxy.ts:57` (also `:52-63`) | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification. Each carries a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Root-layout `await headers()` opts the **entire site** out of static rendering — executed prod build shows every route (incl. `/`, `/_not-found`) as `ƒ (Dynamic)`. No route can be prerendered/CDN-cached; every page view pays a full server render + proxy, and on serverless every view is a billed invocation. Real requirement of nonce-based CSP with nonced markup, but paid site-wide, unmeasured, and (per A3) justified by a refuted comment. | Performance | High | Performance | for-author | — | 🟡 Open | — |
| A2 | `x-nonce` request header is produced but never consumed — dead plumbing. `proxy.ts:39-40` promises layouts will read it via `headers()` and pass to `<Script>` tags, but no `app/` code reads `x-nonce`, zero `next/script` usages exist, and `app/layout.tsx:30` states the opposite ("we don't need to read x-nonce here"). Two comments describe contradictory contracts for the same header; a per-request header-clone + request-override is paid on the hottest path with no reader. Submitted Claim 18 (Verified, static) confirms removing the block changes neither the served CSP nor the rendered script nonces. `Convergence: api-consistency (Inconsistent) + performance (Low)`. | API Consistency | Inconsistent (api-consistency); Low (performance) | API-consistency + Performance | for-author | — | 🟡 Open | — |
| A3 | Layout comment misstates the causal contract: "Opt this layout out of static rendering so proxy.ts runs on every request" inverts the mechanism — proxy execution is governed solely by `config.matcher`, not by rendering mode. What `await headers()` actually buys is per-request HTML re-render so the baked-in nonce matches the fresh CSP header. A maintainer trusting it could delete the line believing it only affects the proxy, silently serving stale-nonce HTML. Code is correct; reader is misinformed. `Convergence: fact-check Claim 1b (Incorrect) + api-consistency (#3 Minor) + performance (#1 note)`. | Fact-check (doc) | Incorrect, medium confidence (comment-only) | Fact-check + API-consistency | for-author | — | 🟡 Open | — |
| A4 | `style-src 'unsafe-inline'` rationale misattributes the carve-out: comment claims "Tailwind v4 emits inline styles," but executed dev+prod probes show Tailwind ships **external nonced stylesheets** (0 inline `<style>` elements). The carve-out is actually needed for 4 `style={{...}}` attributes in the app's own components (`IconRail.tsx`, `ArtifactPanelShell.tsx`). Directive value is fine; a maintainer following the comment would rework Tailwind's shipping and still break the app's inline attributes. `Convergence: fact-check Claim 5 (Incorrect) + api-consistency (#2 Minor)`. | Fact-check (doc) | Incorrect, medium confidence (comment-only) | Fact-check + API-consistency | for-author | — | 🟡 Open | — |
| A5 | `connect-src` rationale references an `OpenAlex` integration that does not exist anywhere in the repo or its git history (`git log --all -S "openalex"` shows the string only ever entered in the commit that added `proxy.ts`). Anthropic/OpenRouter are real; OpenAlex is fabricated relative to this codebase. Conclusion (`connect-src 'self'` suffices) holds vacuously, but a future reader auditing the directive will hunt for an integration that was never there. `Convergence: fact-check Claim 6b (Incorrect, High) + api-consistency (#4 Minor)`. | Fact-check (doc) | Incorrect, high confidence (comment-only) | Fact-check + API-consistency | for-author | — | 🟡 Open | — |
| A6 | Nonce-generation comment claims the "Edge runtime that Next proxy runs in" — Next 16 **always** runs the proxy on the Node.js runtime (Next's own build analysis states it unconditionally; executed build manifest records `"runtime": "nodejs"`; `proxy.ts` exports no `runtime` config). Code works either way (`Buffer`/`crypto` native to Node — Claim 7b Verified), but the comment steers maintainers toward Edge constraints (avoiding Node-only APIs, treating `Buffer` as a polyfill) and mis-prices capacity/cold-start/geo. `Convergence: fact-check Claim 7c (Incorrect, High, executed) + api-consistency (#5 Minor) + performance (#4 Info)`. | Fact-check (doc) | Incorrect, high confidence (comment-only) | Fact-check + API-consistency + Performance | for-author | — | 🟡 Open | — |
| A7 | Matcher `missing:` conditions strip CSP from any request carrying `next-router-prefetch` / `purpose: prefetch` (executed, Claim 9 — those requests received no CSP). Intent (don't burn a nonce on RSC prefetches) is reasonable, but the mechanism excludes *all* prefetch-headered responses, including a full HTML document if any prefetch path fetches one — that document then renders on navigation with **no** script-src/strict-dynamic/form-action/frame-ancestors. Not reachable via default `<Link>` prefetch (RSC payloads, not documents) → Low confidence; standing hole the moment a `<link rel="prefetch">`, Speculation Rules, or a document-speculating browser is added. Mechanism preserved intact. Security-only. | Security | Medium (Confidence Low) | Security | for-author | — | 🟡 Open | — |
| A8 | CSP omits `form-action` — locks scripted egress to `connect-src 'self'` but `form-action` does not fall back to `default-src` (CSP3). An injected/auto-submitting `<form action="https://attacker">` exfiltrates page data cross-origin **without executing any script**, outside everything `strict-dynamic` governs. Requires a non-script injection foothold, which Claim 10 indicates the app currently lacks → Low confidence; still a real gap in the exfil-prevention posture the rest of the policy carefully builds. Fix: add `form-action 'self'` (one line). Security-only. | Security | Medium (Confidence Low) | Security | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings — contextual-critic gaps and single-critic informational suggestions. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | **T3 — matcher route-coverage table (closes G6/G7), test-strategy's highest-ranked gap.** No test pins which paths get a CSP; a matcher regression fails *silently* (route drops out of protection, no error, no visual change). Table-driven contract test on `config.matcher`: `/` and 404s matched; `/api/*`,`/_next/static/*`,`/_next/image*`,`/favicon.ico` not; prefetch-headered not; and pin `/apidocs → not matched` to force the prefix-edge decision (relates to R1). | test-strategy | High (advisory) | for-author | — | 🟢 Open |
| C2 | **T1/T2 — `buildCsp` + `proxy()` header-contract unit tests (closes G1-G5).** Full-string assertion on the 9-directive output (dropped/reordered directive fails loudly); nonce lands exactly once inside `script-src`; extracted CSP-header nonce is 48-char base64-of-UUID and byte-identical to the forwarded `x-nonce`; consecutive calls yield distinct nonces. Cheapest pins turning the fact-check's one-off observations into regression gates; requires exporting the module-private `buildCsp`. | test-strategy | High (advisory) | for-author | — | 🟢 Open |
| C3 | **T4 — dev/prod CSP invariance guard (closes G8).** `buildCsp` has no env branch; assert `buildCsp("N")` is identical under dev vs prod `NODE_ENV` and never contains `'unsafe-eval'`, and `script-src` never contains `'unsafe-inline'` — so a future "loosen it for dev" change must consciously break the test. | test-strategy | Medium (advisory) | for-author | — | 🟢 Open |
| C4 | **T5 — served-header + nonce/HTML agreement smoke script (closes G4/G6 e2e, G9 partial).** Out-of-band `next build && next start` + curl probe mirroring the fact-check's r2 procedure (needs the Google-Fonts mock trick in sandboxed CI). Only path that confirms the real Next pipeline end-to-end, since matcher evaluation and HTML nonce-tagging live in Next, not this repo. | test-strategy | Medium (advisory) | for-author | — | 🟢 Open |
| C5 | `connect-src 'self'` sufficiency (Claim 6a) rests on "no browser code fetches absolute third-party URLs" — verified today by grep, enforceable tomorrow by a lint rule / repo-invariant test (`rg 'https?://'` allowlist over `app/components`,`app/hooks`,`app/lib`). Without it, the first client-side third-party fetch fails only at runtime in the browser console. | test-strategy | Low (advisory) | for-author | — | 🟢 Open |
| C6 | `buildCsp` re-allocates and re-joins the 9-element directive array per request though only the nonce varies. Trivial constant factor at any plausible traffic level — flagged for completeness; fold a template-with-nonce-slot only if `proxy.ts` is edited for A2 anyway. Mechanism preserved. | performance | Informational | for-author | — | 🟢 Open |
| C7 | Three first-of-their-kind conventions established with no codebase precedent: (a) security headers set in the proxy vs `next.config.ts#headers()`; (b) lowercase `x-` prefix for custom request headers; (c) the CSP directive set as the contract every future asset class must be checked against. None a violation — record as deliberate decisions, ideally a `docs/decisions/` line. | api-consistency | Informational | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (Run executed under blinding — the persistent override log was outside the readable scope; sentinel recorded so absence stays auditable across runs.)

---

## ✅ Confirmed Good

Every row's backing is an `executed`-mode fact-check verdict or a static `Verified` whose `Scope:` line covers the row's full breadth (provenance rule 5), cross-checked against the merged and per-replicate reports. api-consistency's legacy "What Looks Good" bullets carry no routing tag and were **not** promoted.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| CG1 | ✅ Confirmed (scoped: self-hosted Next, server-rendered `/`; not browser enforcement) | Every Next-generated `<script>` in the served `/` document carries a nonce **byte-identical** to that response's CSP header, and no app code reads `x-nonce` — established BY EXECUTION on both dev (r1: 36 script tags, 0 without a nonce, single distinct value = header's) and prod (r2). `evidence/r2-html-nonce-check.log`, `evidence/r2-root-headers.txt`, `evidence/r1-script-nonce-audit.txt`. Backing: **FC Claim 2 (executed)** + FC Claim 12 (executed) + **FC submitted Claim 17 (executed)**. Scope excludes in-browser execution (no browser in sandbox) and client-side navigation to other routes. | Fact-check (executed) | for-orchestrator-synthesis |
| CG2 | ✅ Confirmed (scoped: matched requests, dev+prod) | Each matched request receives a distinct, fresh nonce = base64 of `crypto.randomUUID()` (a v4-UUID cryptographic source, not `Math.random`/time) — `proxy.ts:37` `const nonce = Buffer.from(crypto.randomUUID()).toString("base64")`; consecutive requests observed with distinct well-formed base64-of-UUID values, e.g. `'nonce-MWY1...'` decoding to `1f529ad6-...`. `evidence/r1-nonce-freshness.txt`, `evidence/r2-curl-probes.log`. Backing: **FC Claims 1c/7a/7b (executed)** + **FC submitted Claim 16 (executed)**. Scope excludes excluded routes (which get no nonce). | Fact-check (executed) | for-orchestrator-synthesis |
| CG3 | ✅ Confirmed (scoped: `b25e939..d90d6bb` cleanup commit, the only files it changed) | The cleanup commit is behavior-neutral for CSP: the full diff touches only comments, an explicit return type, and inlining a single-use local — the directive-building code and every directive string are byte-identical. `git diff b25e939..d90d6bb` on `proxy.ts`/`app/layout.tsx`. Backing: **FC Claim 13 (static Verified; Scope covers the whole cleanup diff — no other files changed)**. | Fact-check (static; scope covers row) | for-orchestrator-synthesis |
| CG4 | ✅ Confirmed (scoped: current codebase's static browser call-sites; not runtime-constructed URLs or future additions) | Browser-reachable code fetches only relative `/api/...` URLs — the enumeration `rg 'https?://'` over `app/components`,`app/hooks`,`app/lib` returns only the server-side `OPENROUTER_API_URL` constant (imported exclusively by `app/api/**/route.ts`) and two SVG `xmlns` attributes; so `connect-src 'self'` blocks no current legitimate client request. `app/lib/llm/callLlm.ts:7`, `app/lib/formalization/api.ts:104`. Backing: **FC Claim 6a (static Verified; Scope = static import/call-site analysis of the current codebase, enumeration executed)**. | Fact-check (static; scope covers row) | for-orchestrator-synthesis |
| CG5 | ✅ Confirmed (scoped: the three named XSS mechanisms + KaTeX trust; not other XSS vectors) | The named XSS surface is defensive: `rg "dangerouslySetInnerHTML\|rehype-raw\|rehypeRaw" app` and the package.json grep return nothing, and KaTeX runs via `rehype-katex` with no options → `trust` coerces to `false` (`Boolean(undefined)`). `app/components/features/output-editing/LatexRenderer.tsx:6-10`, `node_modules/katex/dist/katex.mjs:349-350`. Backing: **FC Claim 10 (static Verified; Scope = greps for the three named mechanisms + KaTeX, enumeration executed; does not establish absence of other XSS vectors)**. | Fact-check (static; scope covers row) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (Every 🔴/🟡 row cites a `path:line` with verbatim source or executed evidence grounded in the fact-check/critic reports; no evidence block failed to locate.)

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (security, performance, api-consistency all returned; test-strategy ran as an advisory contextual critic.)

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
