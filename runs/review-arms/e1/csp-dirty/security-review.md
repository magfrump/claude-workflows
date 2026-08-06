# Security Review — csp-dirty (d86d2dc..d90d6bb)

**Scope:** `git diff d86d2dc..d90d6bb` — new `proxy.ts` (buildCsp + proxy + matcher config) and `app/layout.tsx` becoming an async server component that awaits `headers()`. Commits outside this range are context only.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3), treated as foundation and not re-verified.

`Commit: d90d6bb`

No HALT-ESCALATE conditions found: no plaintext secrets, no missing auth on privileged endpoints, no injection sink, no disabled TLS verification, no hardcoded keys in this range.

### Trust Boundary Map

This change introduces a new response-header security control and a new request-header channel, so the boundaries are all new with this diff.

- **B1: Untrusted browser request headers → `config.matcher.missing` evaluation in `proxy.ts:55-63` → decision whether the CSP is applied at all** *(new)*. The proxy's own activation is conditioned on two client-settable request headers (`next-router-prefetch`, `purpose: prefetch`). The requester therefore participates in deciding whether the security header is emitted — a control-plane input crossing from untrusted to trusted without validation.
- **B2: `proxy.ts:41-46` → `x-nonce` request header → server components / route handlers reading `headers()`** *(new)*. The proxy overwrites any inbound `x-nonce` with its own value for matched paths, which makes the header trustworthy *on matched paths only*; unmatched paths (notably everything under `/api`) pass a caller-controlled `x-nonce` straight through.
- **B3: Server response → `Content-Security-Policy` response header (`proxy.ts:47`) → browser policy engine governing LLM-generated and markdown-derived DOM** *(new)*. This is the boundary the whole feature exists to establish: the browser is asked to distrust any script the server did not explicitly nonce. Its integrity depends on the nonce in the header matching a nonce actually present in the served HTML.
- **B4: Response → any intermediary or browser cache → a later request, possibly a different user** *(new, implicit)*. Nothing in the diff pins `Cache-Control`, so the header/HTML nonce pairing established at B3 is only durable for as long as no shared cache stores the pair.

### Findings

#### F1 — The nonce never reaches the document, so `'strict-dynamic'` blocks every script and the control delivers no protection

**Severity:** High
**Location:** `proxy.ts:22`, `proxy.ts:41-47`, `app/layout.tsx:26-30`
**Boundary:** B3
**Move:** Trace the trust boundary end-to-end — the policy is only a boundary if the thing it authorizes actually carries the credential.
**Confidence:** High (fact-check established the wiring defect; the security consequence follows from `'strict-dynamic'` semantics).
**Evidence:**
```
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```
```
  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```
```
  // Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();
```
Next reads the nonce from the *request's* `Content-Security-Policy` header; this code only sets it on the response and forwards `x-nonce`, which Next does not read. No rendered script therefore carries `nonce-…`. Because `'strict-dynamic'` instructs conforming browsers to ignore `'self'` and all host-source expressions in `script-src`, the effect is not "weaker CSP" but "no script executes at all" — the bootstrap and chunk loads for a `"use client"` app (`app/page.tsx:1`) are all refused, so the page never hydrates. The security impact is twofold: the advertised XSS mitigation is worth zero, and the failure mode is severe and user-visible enough that the pressure under incident conditions will be to delete or broadly loosen the policy rather than to fix the wiring. There is no `Content-Security-Policy-Report-Only` staging step and no test covering the header, so nothing catches this before production.
**Legibility-target:** for-author
**Recommendation:** Set the CSP on the *forwarded request* headers as well as the response (`requestHeaders.set("Content-Security-Policy", csp)`) so Next's renderer picks up the nonce, and verify in a browser that the served HTML contains `nonce=` on the bootstrap scripts. Ship first as `Content-Security-Policy-Report-Only` and only promote to enforcing after reports are clean.

#### F2 — CSP application is conditioned on client-controlled request headers (default-allow inversion)

**Severity:** Medium
**Location:** `proxy.ts:55-63`
**Boundary:** B1
**Move:** Invert the access control — ask what the check does *not* cover, and who controls the inputs to the check.
**Confidence:** Medium
**Evidence:**
```
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```
Any requester who sends `purpose: prefetch` or `next-router-prefetch` receives the document with **no** `Content-Security-Policy` header at all — the caller decides whether the security control applies. The realistic exploitation path is not a direct attacker fetch (an attacker attacking their own browser gains nothing) but cache-mediated: a prefetched, CSP-less HTML response can be stored and then reused to satisfy the subsequent real navigation, so a victim ends up viewing a policy-free document through no fault of their own. The stated rationale — "would otherwise burn a nonce on a request that may never paint" — is a performance concern; nonces are free to generate, so the exclusion buys nothing that justifies a security header whose presence the client can toggle.
**Legibility-target:** for-author
**Recommendation:** Drop the `missing` clause and apply the CSP to prefetches too. If prefetch responses must be treated differently, make the difference something other than omitting the security header.

#### F3 — Nonce/HTML pairing has no cache barrier; a shared cache would serve one user's nonce to everyone

**Severity:** Medium
**Location:** `proxy.ts:47`, `app/layout.tsx:26-30`
**Boundary:** B4
**Move:** TOCTOU / lifetime analysis — the nonce is generated at time T and validated by the browser at time T+n, with an unbounded store in between.
**Confidence:** Medium
**Evidence:**
```
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```
```
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce.
  await headers();
```
A per-request nonce is only meaningful if the (header, HTML) pair is never reused. The only thing preventing reuse here is the `await headers()` dynamic-rendering opt-out, which is a *rendering* control, not a *caching* one — nothing in the diff or in `next.config.ts` sets `Cache-Control: no-store` on the CSP-bearing responses or adds `Vary`. Deploying behind a CDN or any shared proxy that decides these HTML responses are cacheable would freeze a single nonce for all users, at which point an attacker who can read one page can predict the value that authorizes script execution for everyone. The proxy also has no way to know whether the response it is stamping was served from Next's own route cache with an older nonce baked into the HTML.
**Legibility-target:** for-orchestrator-synthesis
**Recommendation:** Explicitly set `Cache-Control: no-store` (or at minimum `private, no-cache`) on responses that carry a nonce, and state the CDN assumption in the file's header comment so the next deployment change does not silently break it.

#### F4 — `form-action` is absent, leaving the stated injected-HTML threat model half-covered

**Severity:** Medium
**Location:** `proxy.ts:20-30`
**Boundary:** B3
**Move:** Ask what the policy's own threat model implies but the directive list omits.
**Confidence:** High
**Evidence:**
```
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
```
The file's rationale is defence against markup "that slipped past markdown sanitization" into LLM-derived output. Injected markup does not need script to be dangerous: a `<form action="https://attacker.example">` wrapping visible content will exfiltrate whatever the user types on submit, and `default-src 'self'` does not constrain form submission targets — only an explicit `form-action` does. The policy already picks up the two sibling non-script vectors (`base-uri`, `object-src`), which makes the omission look accidental rather than deliberate; there are no cross-origin forms in the app, so `form-action 'self'` is free to add.
**Legibility-target:** for-author
**Recommendation:** Add `"form-action 'self'"` to the `directives` array.

#### F5 — Matcher exclusions are prefix matches, not path-segment matches

**Severity:** Low
**Location:** `proxy.ts:57`
**Boundary:** B1
**Move:** Invert access control — enumerate the paths the negative lookahead unintentionally exempts.
**Confidence:** High
**Evidence:**
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
The lookahead tests a literal prefix immediately after the leading `/`, with no trailing `/` or end anchor, so it exempts more than the four intended targets: any future top-level route whose name starts with those strings — `/api-docs`, `/apidocs`, `/apiary`, `/_next/imageproxy` — silently ships without a CSP. Today no such route exists, so this is latent rather than live; the risk is that the exemption is invisible at the point where someone later adds a route named `/api-explorer` and reasonably assumes site-wide CSP coverage.
**Legibility-target:** for-author
**Recommendation:** Anchor each alternative to a path segment, e.g. `"/((?!api/|_next/static/|_next/image/|favicon\\.ico$).*)"`, and note that `favicon.ico` needs an end anchor rather than a slash.

#### F6 — `/api` is fully exempt from CSP with no `nosniff` backstop elsewhere in the repo

**Severity:** Low
**Location:** `proxy.ts:52-57`
**Boundary:** B1, B2
**Move:** Follow what leaves the system — the exempted surface returns attacker-influenced bytes to a browser.
**Confidence:** Medium
**Evidence:**
```
  // Apply CSP to page navigations only. Skip API routes (they don't render
  // HTML), Next's static assets (no scripts to nonce), and prefetches (which
```
The justification "they don't render HTML" is about intent, not about what a browser does with the bytes. These routes return LLM-generated and user-supplied content (`app/api/**/route.ts`, including the SSE/stream paths), and a document-typed or sniffed response reaching a browser directly via top-level navigation would execute with no policy at all — `X-Content-Type-Options: nosniff` is not set anywhere in the repo, and `next.config.ts` defines no `headers()` block. The same exemption also means B2 is one-sided: on `/api` paths the proxy never runs, so any future handler reading `x-nonce` from `headers()` would be reading a caller-supplied value while the naming implies a server-generated one.
**Legibility-target:** for-author
**Recommendation:** Apply at least `default-src 'none'; sandbox` (or the full policy) to API responses rather than exempting them, and add `X-Content-Type-Options: nosniff` globally in the same proxy.

#### F7 — `connect-src 'self'` breaks `fetch()` on data: URLs, and the obvious fix widens the exfiltration surface

**Severity:** Low
**Location:** `proxy.ts:26`, `app/lib/utils/exportGraph.ts:24,37`
**Boundary:** B3
**Move:** Trace what legitimately crosses the boundary before deciding what to close.
**Confidence:** High (breakage established by fact-check; the remediation-pressure argument is the security-relevant part)
**Evidence:**
```
    "connect-src 'self'",
```
```
  const res = await fetch(dataUrl);
  const blob = await res.blob();
```
`connect-src` governs `fetch()` against `data:` URLs, so PNG graph export and the zip-embedding path both fail under this policy. The security-relevant consequence is the repair pressure: the shortest fix is `connect-src 'self' data:`, which re-opens a channel usable for exfiltration and is much broader than what the call site needs. The file's stated rationale for `'self'` also cites OpenAlex, which is not referenced anywhere in the repo, so the directive's justification does not match the actual egress set.
**Legibility-target:** for-author
**Recommendation:** Replace the two `fetch(dataUrl)` calls with direct data-URL-to-Blob decoding (no network fetch involved), keeping `connect-src 'self'` intact, and correct the comment to list only the hosts actually contacted.

#### F8 — Nonce derivation is indirect: base64 of a UUID *string*, not of raw random bytes

**Severity:** Informational
**Location:** `proxy.ts:37`
**Boundary:** B3
**Move:** Follow the secret — check its source of entropy, its encoding, and whether the encoding can escape its container.
**Confidence:** High
**Evidence:**
```
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```
This is safe but round-about: `crypto.randomUUID()` is CSPRNG-backed and carries 122 bits of entropy, which clears the CSP spec's 128-bit *recommendation* only narrowly, and base64-encoding the 36-character ASCII form inflates it to 48 characters on every response for no added randomness. There is no injection risk — the base64 alphabet cannot break out of the `'nonce-…'` quoted token — so this is a hygiene note, not a vulnerability. Worth fixing mainly because the current form invites a reader to assume 256 bits where there are 122.
**Legibility-target:** for-author
**Recommendation:** Use `Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64")` and drop the now-incorrect comment about the Edge runtime (Next 16 proxy defaults to the Node runtime).

#### F9 — `x-nonce` is a dangling trust-labeled header with zero readers

**Severity:** Informational
**Location:** `proxy.ts:39-46`
**Boundary:** B2
**Move:** Serialization/naming boundary — a header that looks authoritative but is unconsumed will eventually be consumed by someone who does not check where it came from.
**Confidence:** High
**Evidence:**
```
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```
Nothing in `app/` reads `x-nonce`, and there are no `<Script>` elements for it to decorate, so the header currently does nothing. It is correctly implemented for what it is — `.set()` (not `.append()`) overwrites any client-supplied `x-nonce`, so header smuggling on matched paths is prevented — but the same guarantee does not extend to `/api`, which the matcher excludes (see F6). Either wire it to a real consumer or remove it; leaving an authoritative-looking but unvalidated-on-some-paths header is how confused-deputy bugs get planted.
**Legibility-target:** for-author
**Recommendation:** Remove the `x-nonce` forwarding, or keep it and extend the matcher so no path can reach a handler with a caller-supplied `x-nonce`.

#### F10 — No `worker-src`; pdf.js's blob-worker fallback path would be blocked

**Severity:** Informational
**Location:** `proxy.ts:20-30`, `app/lib/utils/fileExtraction.ts:26-29`
**Boundary:** B3
**Move:** Enumerate the fetch destinations the app actually uses against the directives the policy declares.
**Confidence:** Medium
**Evidence:**
```
    "default-src 'self'",
```
```
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url,
  ).toString();
```
`worker-src` is unset and falls back to `default-src 'self'`. The normal path is fine (the worker URL is same-origin), but pdf.js has a fallback that constructs the worker from a `blob:` URL when direct loading fails, and that fallback is refused under `'self'` — it degrades to the slow single-threaded "fake worker" or to an outright PDF-parsing failure. Calling the directive out explicitly documents the decision rather than leaving it to a fallback chain.
**Legibility-target:** for-author
**Recommendation:** Add an explicit `"worker-src 'self' blob:"` and note in the comment that pdf.js needs it.

#### F11 — The control fails open silently: no report endpoint, no test, no staging mode

**Severity:** Informational
**Location:** `proxy.ts:34-49` (whole module), no corresponding test file
**Boundary:** B3
**Move:** Check the error path — what is observable when the control does not run?
**Confidence:** High
**Evidence:**
```
export function proxy(request: NextRequest): NextResponse {
```
If the proxy throws, is not picked up by a deployment target, or is excluded by a matcher edit, responses simply ship without a `Content-Security-Policy` header and nothing in the system notices — there is no `report-uri`/`report-to`, no `Content-Security-Policy-Report-Only` rollout, and `rg --files -g '*proxy*'` returns only `proxy.ts` itself, so no test asserts the header is present. F1 is the concrete instance of exactly this class: a total failure of the control that shipped across three commits without detection.
**Legibility-target:** for-automated-gate
**Recommendation:** Add a test asserting `proxy(req).headers.get("Content-Security-Policy")` contains `nonce-` and that two calls produce different nonces, and add a `report-to` endpoint so violations are visible in production.

### What Looks Good

- `frame-ancestors 'none'`, `object-src 'none'`, and `base-uri 'self'` (`proxy.ts:27-29`) are the right non-script hardening trio and are often the ones omitted; `base-uri` in particular closes the base-tag hijack that would otherwise defeat `'strict-dynamic'` even when the nonce wiring is correct.
- `requestHeaders.set("x-nonce", nonce)` uses `set`, not `append`, so a client-supplied `x-nonce` cannot be smuggled through to a server component on matched paths (B2).
- The nonce is interpolated into the header from a base64 alphabet only, so there is no CSP-header-injection path from `buildCsp`.
- The carve-outs are documented in prose with reasons rather than left bare, which is what makes the fact-check's corrections possible at all — the rationale being wrong is a smaller problem than there being no rationale to check.
- The underlying XSS exposure this policy is defending is genuinely thin: `react-markdown` is used without `rehype-raw`, there is no `dangerouslySetInnerHTML` anywhere in `app/`, and KaTeX runs at its default `trust: false`. The CSP is defence-in-depth over an already-sanitized surface, which is the correct posture.

### Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Nonce never reaches document; `'strict-dynamic'` blocks all scripts, control delivers no protection | High | B3 | proxy.ts:22,41-47; app/layout.tsx:26-30 | High |
| F2 | CSP application conditioned on client-controlled request headers | Medium | B1 | proxy.ts:55-63 | Medium |
| F3 | No cache barrier on nonce/HTML pairing; shared cache reuses one nonce | Medium | B4 | proxy.ts:47; app/layout.tsx:26-30 | Medium |
| F4 | `form-action` absent; injected-form exfiltration uncovered | Medium | B3 | proxy.ts:20-30 | High |
| F5 | Matcher exclusions are prefix, not segment, matches | Low | B1 | proxy.ts:57 | High |
| F6 | `/api` fully exempt from CSP, no `nosniff` backstop | Low | B1, B2 | proxy.ts:52-57 | Medium |
| F7 | `connect-src 'self'` breaks data-URL fetch; fix pressure widens exfil surface | Low | B3 | proxy.ts:26; exportGraph.ts:24,37 | High |
| F8 | Nonce is base64 of a UUID string (122 bits, inflated encoding) | Informational | B3 | proxy.ts:37 | High |
| F9 | `x-nonce` forwarded with zero readers; unguarded on `/api` | Informational | B2 | proxy.ts:39-46 | High |
| F10 | No `worker-src`; pdf.js blob-worker fallback blocked | Informational | B3 | proxy.ts:20-30; fileExtraction.ts:26-29 | Medium |
| F11 | Control fails open silently — no report endpoint, test, or report-only stage | Informational | B3 | proxy.ts:34-49 | High |

### Overall Assessment

The directive list is close to a good policy and the non-script hardening is better than typical, but the feature does not currently establish the trust boundary it claims (B3): the nonce is generated and advertised in the response header while never being attached to any script, and `'strict-dynamic'` converts that gap from "weak policy" into "no script runs." Everything else in this review is secondary to F1, because until the nonce reaches the document there is no policy to evaluate in production — and the way F1 will surface (a blank app) creates pressure toward exactly the wrong repair. Beyond that, two design patterns deserve attention independent of the wiring fix: the control's activation is partly delegated to the client (F2), and its per-request guarantee has no cache barrier behind it (F3). I would not enforce this policy in production as written; ship it `Report-Only` with the request-header nonce fix, a `form-action` directive, and a test that asserts the header exists, then promote.

## Goal-Alignment Note

- **Answered:** Security design review of `d86d2dc..d90d6bb` as of `d90d6bb`, covering the new CSP proxy and the layout's dynamic-rendering opt-out. Trust boundaries traced end-to-end from client request headers through nonce generation to browser enforcement and cache lifetime; all findings reported down to Informational, each with verbatim evidence and a boundary cross-reference. Merged fact-check taken as foundation and not re-verified.
- **Out of scope:** Pre-existing security posture outside the diff — API-route input validation and authentication (`app/api/**`), the Lean verifier fetch in `app/api/verification/lean/route.ts` and its SSRF characteristics, LLM prompt-injection handling, dependency-manifest review (`package.json` is unchanged in this range), and transport-layer headers such as HSTS that no file in the range attempts to set. F6's `nosniff` observation is included only because the diff's matcher decision creates the uncovered surface.
- **Escalate:** Nothing meets the HALT-ESCALATE bar. For orchestrator synthesis, F1 is the item that should dominate the merged report — it is simultaneously a security-control failure and an availability break, and it is the finding most likely to be "fixed" by weakening the policy rather than by correcting the wiring. F3 is the one finding whose severity depends on deployment topology the reviewer cannot see from the repo, so it warrants a direct question to the author about CDN placement.
