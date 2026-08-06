# Security Review — strict CSP with per-request nonces

**Commit:** e5d95a9
**Range:** `d86d2dc..HEAD` (9b4e453 → b25e939 → d90d6bb → e5d95a9)
**Worktree:** `/workspace/runs/review-arms/e3-loops/wt-csp-arm1` (branch `e3/csp-arm1`)
**Files in scope:** `proxy.ts` (new, 71 lines), `app/layout.tsx` (+18/-1)
**Foundation:** merged code-fact-check (k=3) supplied by the orchestrator. Findings below build on it and are not a re-verification of it.

---

## Trust boundaries map

This change introduces a security control whose enforcement point is *in the browser*, configured by a header written *at the edge of the server*, describing scripts emitted by a *third layer* (the Next.js renderer). The boundaries that matter are the seams between those three layers — and the seams where the control is silently skipped.

B1: [untrusted client request headers] → [`new Headers(request.headers)` then `.set("x-nonce", nonce)` in `proxy.ts:47–49`] → [server-component render context readable via `headers()`]
B2: [origin server response header `Content-Security-Policy` set in `proxy.ts:54`] → [browser CSP enforcement engine parses and applies the policy] → [script execution, style application, and network egress inside the rendered document]
B3: [LLM output and user-supplied document text] → [`react-markdown` / `rehype-katex` render into the DOM] → [browser DOM governed by the B2 policy]
B4: [in-page generated `data:` URLs from `html-to-image`] → [`fetch(dataUrl)` at `app/lib/utils/exportGraph.ts:24,37`] → [browser `connect-src` enforcement]
B5: [request paths and request headers matching the `config.matcher` exclusions — `api`, `_next/static`, `_next/image`, `favicon.ico`, and any request carrying `next-router-prefetch` or `purpose: prefetch`] → [proxy never executes] → [response served with **no** CSP header and with request headers **unmodified**]

Prose reading of the map. The intended security story runs B3 → B2: even if injected markup reaches the DOM, the policy at B2 refuses to execute it. That story has two structural dependencies the diff does not establish. First, B2 is only a real boundary if the nonce in the header also appears on the document's own `<script>` tags — the header and the markup are produced by different layers, and nothing in this diff couples them (the fact-check foundation records this as Incorrect/High). Second, B1 and B5 are *asymmetric*: the proxy normalizes `x-nonce` on the paths it runs on, and does nothing at all on the paths it skips. Any code that later reads `x-nonce` inherits a header that is trustworthy on some routes and attacker-controlled on others, with no marker distinguishing them. Most of the findings below live at those two seams rather than inside `buildCsp` itself.

---

## Findings

#### The advertised protection is not established — nonce never reaches the document, and the fallback for non-`strict-dynamic` browsers is a materially weaker policy

**Severity:** High
**Location:** `proxy.ts:29`, `proxy.ts:46–54`, `app/layout.tsx:27–40`
**Boundary:** B2
**Move:** implicit sanitization (the control is assumed to have been applied by a layer that was never asked to apply it)
**Confidence:** High (mechanism), Medium (per-deployment outcome — the fact-check's r1 dissent notes an undocumented router-mirroring path may deliver the nonce self-hosted but not on split infrastructure)
**Evidence:**
```
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${devOnly}`,
```
```
  // Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
```
**Legibility-target:** a reader should be able to confirm this by loading any page and diffing the `nonce=` attribute on the rendered `<script>` tags against the `nonce-` token in the response `Content-Security-Policy` header; if the attribute is absent or differs, this finding holds.

The header at B2 and the markup at B3 are produced independently, and the diff contains no code that joins them: `x-nonce` is written onto the *request* headers, nothing reads it, and the layout explicitly declines to. The comment asserts Next tags its bootstrap scripts from the *response* CSP header — an assumption the fact-check found unsupported and which 9b4e453's claimed end-to-end verification statically contradicts.

The security consequence is not only "the app may break." Two things follow. (1) In browsers that support `'strict-dynamic'`, the `'self'` source expression is discarded by specification, so a nonce mismatch is total: every script is blocked, the app is inoperable, and the realistic remediation under production pressure is to loosen the policy — the control is likely to be *weakened* by its own failure mode rather than fixed. (2) In browsers that do **not** support `'strict-dynamic'` (the specified compatibility path), the policy degrades to `script-src 'self'`, which permits any same-origin response the browser will execute as script. This application exposes 16 same-origin API routes returning attacker-influenced LLM output; `script-src 'self'` is the classic bypass surface, and it is the *silent* branch — no error appears, so the weaker policy is the one that runs unnoticed.

The deeper issue is that a security control whose correct operation is indistinguishable from a rendering coincidence has no verification story at all. `proxy.ts` has no test file, and there is a working vitest harness in the repo.

**Recommendation:** Do not merge on the current mechanism. Either (a) read `x-nonce` in the layout and pass it explicitly to the elements that need it, making the coupling visible in code, or (b) drop nonces for hashes, which decouples the policy from per-request rendering entirely. In either case add a test asserting that the nonce token in the response header appears as a `nonce=` attribute in the rendered HTML, and roll out via `Content-Security-Policy-Report-Only` first (see the reporting finding below).

---

#### `x-nonce` is normalized on proxied paths and attacker-controlled on skipped paths, with nothing marking the difference

**Severity:** Medium
**Location:** `proxy.ts:47–49`, `proxy.ts:59–70`
**Boundary:** B1, B5
**Move:** inverted access control (the trustworthiness of a value depends on which route received it, and the routes that skip sanitization are exactly the ones defined furthest from the reader)
**Confidence:** High (mechanism), Medium (impact — latent; the fact-check records `x-nonce` as stale with no current reader)
**Evidence:**
```
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
```
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```
**Legibility-target:** a reader should be able to confirm this by issuing `curl -H 'x-nonce: attacker' /api/analytics` and observing that no layer strips or overwrites the header before it reaches route code.

The `.set()` (rather than `.append()`) is correct and deliberately clobbers a client-supplied `x-nonce` — on the paths where the proxy runs. On the excluded paths it never runs, so a client-supplied `x-nonce` arrives at server code verbatim. The header therefore has two populations with identical names and no distinguishing marker: authentic on page navigations, forgeable on API routes and on any request carrying a prefetch header.

Today this is inert because nothing reads `x-nonce` — which is precisely what makes it dangerous to leave in. The header exists solely as an affordance for a future reader, its docstring invites that reader ("so layouts can read it via `headers()` and pass it to `<Script>` tags"), and the first developer who accepts the invitation will write `const nonce = (await headers()).get("x-nonce")` without re-deriving the matcher's exclusion list. Stamping an attacker-supplied string into a `nonce=` attribute is a direct CSP bypass primitive, and it will look correct in review because the sanitizing `.set()` is visibly present seventy lines away.

**Recommendation:** Delete the `x-nonce` forwarding — it has no reader and, per the previous finding, the design that would need it should be reconsidered anyway. If it is retained, either widen the matcher so every request is normalized, or move the read behind a helper that fails closed when the request was not proxied.

---

#### CSP can be skipped by a request header the client chooses

**Severity:** Medium
**Location:** `proxy.ts:62–68`
**Boundary:** B5, B2
**Move:** inverted access control (an untrusted input decides whether the security control applies)
**Confidence:** High (mechanism), Low–Medium (exploitability — no straightforward cross-origin path to set the header on a top-level navigation)
**Evidence:**
```
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```
**Legibility-target:** a reader should be able to confirm this with `curl -I -H 'purpose: prefetch' /` and observe no `Content-Security-Policy` header in the response.

The comment justifies the exclusion on resource grounds ("would otherwise burn a nonce on a request that may never paint"), which frames a *policy applicability* decision as a *cost* decision. The effect is that a fully-rendered HTML document is served with no CSP whenever the request carries either header. A prefetched document is not inert: Next's client router may commit prefetched payloads into the live page, and any client that sets the header — an extension, an embedded webview, a same-origin `fetch`, a proxy that normalizes hints — receives the unprotected variant. Cross-origin exploitation is blocked by CORS preflight on the custom header, which is why this is Medium and not High; the objection is that the control's coverage is decided by data the attacker can influence rather than by the server.

There is also a correctness edge: the exclusion matches the legacy `purpose: prefetch` and Next's own `next-router-prefetch`, but not the standard `Sec-Purpose: prefetch;prerender` sent by browser speculation rules — so the stated intent is only partially achieved even on its own terms.

**Recommendation:** Set the CSP header unconditionally for HTML responses. If prefetch nonce churn is a genuine concern, address it by making the policy nonce-free (hashes) rather than by making enforcement conditional on request headers.

---

#### No `form-action` directive — the exact residual vector the policy claims to cover

**Severity:** Medium
**Location:** `proxy.ts:26–36`
**Boundary:** B3 → B2
**Move:** million-of-these (enumerating directives by memory rather than against the threat model, so the one that matches the stated threat is the one omitted)
**Confidence:** High
**Evidence:**
```
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${devOnly}`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self' data:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
```
**Legibility-target:** a reader should be able to confirm this by noting `form-action` is absent from the list and that CSP Level 3 does not fall it back to `default-src`.

`form-action` does not inherit from `default-src`; omitting it leaves form submission entirely unrestricted. The stated threat model is markdown injection — "a hypothetical injected `<script>` tag ... even if something slipped past markdown sanitization." When script is blocked, the next-best injected-markup primitive is a form posting to an attacker origin, optionally auto-submitted by a user click on injected UI. That is precisely the case this policy exists to cover, and it is the one directive that would cover it. `base-uri 'self'` and `object-src 'none'` are present, which shows the checklist was consulted; `form-action` is the gap in it.

**Recommendation:** Add `form-action 'self'`. Consider `frame-src 'none'` for explicitness (it currently inherits `'self'` from `default-src`, which is acceptable) and `require-trusted-types-for 'script'` if the DOM-sink surface is ever expanded.

---

#### No violation reporting and no Report-Only rollout — the policy ships blind

**Severity:** Medium
**Location:** `proxy.ts:26–37`, `proxy.ts:54`
**Boundary:** B2
**Move:** error paths (the failure mode of the control produces no signal on the server side)
**Confidence:** High
**Evidence:**
```
  response.headers.set("Content-Security-Policy", buildCsp(nonce));
```
**Legibility-target:** a reader should be able to confirm this by grepping the diff for `report-to`, `report-uri`, and `Report-Only` and finding none.

Every CSP failure in this design is client-side and silent from the server's perspective. The nonce-delivery defect in the first finding, the `connect-src` export regression below, and any future third-party addition all manifest as a browser console message on one user's machine and nothing else. This matters more than usual here because the diff is a *first* CSP: there is no prior policy to compare against and no baseline of expected violations. A `Content-Security-Policy-Report-Only` deployment with a reporting endpoint would have surfaced the nonce defect before enforcement, at essentially zero risk.

**Recommendation:** Ship as `Content-Security-Policy-Report-Only` with a `report-to` endpoint first; promote to enforcing once the report stream is quiet. Keep the reporting directive after promotion.

---

#### `connect-src 'self'` blocks the PNG/zip graph export

**Severity:** Medium
**Location:** `proxy.ts:32`; affected call sites `app/lib/utils/exportGraph.ts:24` and `:37`
**Boundary:** B4
**Move:** error paths (a security control silently removes an existing capability, and the obvious repair widens the policy)
**Confidence:** High (per fact-check foundation, Incorrect/High)
**Evidence:**
```
    "connect-src 'self'",
```
```
  const res = await fetch(dataUrl);
  const blob = await res.blob();
  triggerDownload(blob, filename);
```
**Legibility-target:** a reader should be able to confirm this by exporting the proof graph as PNG with the policy enforced and observing the `fetch` rejected by `connect-src`.

`toPng` returns a `data:` URL which the export path re-fetches to obtain a `Blob`. `connect-src 'self'` does not permit `data:`, so both export functions fail. The security concern is the repair pressure: the minimal-diff fix is to append `data:` to `connect-src`, which grants the page a general-purpose channel and is a strictly worse policy than the alternative. The docstring's `connect-src` rationale — that Anthropic/OpenAlex/OpenRouter traffic is server-to-server — is correct and independently confirmed (`OPENROUTER_API_URL` is referenced only from `app/lib/llm/*` reached through API routes, none of which are client components), so the directive itself is right; only the in-page `data:` consumer was missed.

**Recommendation:** Change `exportGraph.ts` to use `html-to-image`'s `toBlob` and drop the `fetch(dataUrl)` round trip entirely. Do not add `data:` to `connect-src`.

---

#### `style-src 'unsafe-inline'` is retained for the wrong stated reason

**Severity:** Low
**Location:** `proxy.ts:12–15`, `proxy.ts:30`
**Boundary:** B3 → B2
**Move:** implicit sanitization (a carve-out documented against a dependency that does not require it)
**Confidence:** High (per fact-check foundation, Incorrect/Medium)
**Evidence:**
```
 * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
 * to nonces would require rebuilding how Tailwind ships styles in dev and
 * SSR. Documented as a deliberate carve-out, not an oversight.
```
**Legibility-target:** a reader should be able to confirm this by removing Tailwind from the picture (the real dependents are React `style` attributes, reactflow, KaTeX, and dev-time injection) and observing the carve-out is still required.

The carve-out is defensible on the merits; the recorded reason is not the one that makes it necessary. That is a security-relevant documentation defect rather than a policy defect: the comment is written specifically to be the artifact consulted when someone later asks "can we tighten this?", and it will produce the wrong answer — a reader who confirms Tailwind no longer needs it will remove the carve-out and break KaTeX and reactflow rendering, or will conclude the whole directive was cargo-culted.

Residual risk from the carve-out itself is genuinely low here: `react-markdown` v10 does not render raw HTML by default and `rehype-raw` is not installed, so injected `style` attributes are not currently reachable; and because `img-src` lists no external host, the usual CSS-based exfiltration channel (`background: url(https://evil/…)`) is already closed.

**Recommendation:** Rewrite the rationale to name the actual dependents (React inline `style` props, reactflow's transform styles, KaTeX, dev-time style injection) and state the condition under which it could be dropped.

---

#### Dev-only `'unsafe-eval'` is gated on a runtime environment variable rather than a build-time constant

**Severity:** Low
**Location:** `proxy.ts:25–26`, `proxy.ts:17–22`
**Boundary:** B2
**Move:** error paths / secrets-adjacent configuration trust
**Confidence:** High (mechanism verified in fact-check foundation as fail-closed and correct as written)
**Evidence:**
```
  const devOnly =
    process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : "";
```
**Legibility-target:** a reader should be able to confirm this by running `NODE_ENV=development next start` against a production build and observing `'unsafe-eval'` in the served policy.

The gate is written the right way round — it fails closed, defaulting to the strict policy for any value other than the literal `"development"` — and this is the strongest part of the diff. The residual concern is only that `NODE_ENV` is ambient process state, not a property of the artifact: a production build served with `NODE_ENV=development`, or a `next dev` instance exposed over a tunnel for a demo, ships `'unsafe-eval'` while the claim "never ships" continues to read as true. The comment's absolute phrasing ("Production builds contain no eval, so the carve-out is gated on NODE_ENV and never ships") is what makes this worth flagging: it asserts a build-time guarantee for a runtime check.

**Recommendation:** Keep the gate; soften the comment to state what is actually guaranteed. If stronger assurance is wanted, add an assertion at startup that `NODE_ENV !== "development"` when the build is a production build.

---

#### `img-src` grants `blob:` and `data:` without an identified consumer

**Severity:** Low
**Location:** `proxy.ts:31`
**Boundary:** B3 → B2
**Move:** million-of-these (permissive sources added by convention rather than by demonstrated need)
**Confidence:** Medium
**Evidence:**
```
    "img-src 'self' data: blob:",
```
**Legibility-target:** a reader should be able to confirm this by removing `blob:` and `data:` and exercising PDF upload, graph export, and markdown rendering to see whether anything regresses.

`export.ts` uses `URL.createObjectURL` for download anchors, which is a navigation, not an image load; nothing located in the diff or the surrounding code demonstrably renders a `blob:` or `data:` image. Both sources are low-risk in isolation, but a first CSP is the cheapest moment to establish which sources are actually load-bearing, and unexplained grants become permanent because no one can later prove they are unused. This is the same failure the `style-src` comment already exhibits, one directive over.

**Recommendation:** Drop what is unused, or add a one-line note naming the consumer for each retained source.

---

#### API routes and static assets are served with no CSP at all

**Severity:** Informational
**Location:** `proxy.ts:62`
**Boundary:** B5
**Move:** trust-boundary mapping
**Confidence:** High
**Evidence:**
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
**Legibility-target:** a reader should be able to confirm this with `curl -I /api/analytics` and observe no `Content-Security-Policy` header.

The comment's reasoning is sound for `script-src` — API routes do not render HTML. It does not hold for the document-independent directives: `frame-ancestors 'none'` and `object-src 'none'` also fail to apply, so an API response directly navigated to or framed carries no protection. With 16 routes returning LLM-derived content, a content-type or sniffing mistake in any of them lands on an unprotected response. This is informational rather than actionable because the routes return JSON with correct content types today.

**Recommendation:** Consider applying a minimal policy (`default-src 'none'; frame-ancestors 'none'`) to API responses; it costs nothing and removes the exception from the map.

---

#### The security control has no tests

**Severity:** Informational
**Location:** `proxy.ts` (whole file)
**Boundary:** B2
**Move:** error paths
**Confidence:** High
**Legibility-target:** a reader should be able to confirm this by globbing for `proxy.test.ts` / `csp` test files and finding none, while `vitest.config.ts` and `vitest.setup.ts` exist.

`buildCsp` is a pure function of one string and an env var — the single most testable thing in the diff — and the environment gate, the directive list, and the nonce interpolation are all assertable in a few lines. Their absence is why the nonce-delivery defect in the first finding survived a commit that claimed end-to-end verification.

**Recommendation:** Add unit tests over `buildCsp` (directive presence, dev/prod gate both ways, nonce interpolation) and one integration assertion that the served header token matches a `nonce=` attribute in the rendered HTML.

---

## What Looks Good

- **The dev-eval gate fails closed.** `process.env.NODE_ENV === "development"` against a literal, with the strict policy as the default branch, is the correct polarity — the common mistake (`!== "production"`) would ship `'unsafe-eval'` from any unset or misspelled environment. This is the best-reasoned line in the diff.
- **`.set("x-nonce", …)`, not `.append`.** On proxied paths a client-supplied `x-nonce` is clobbered rather than joined into a comma-list, which is the failure mode that turns header forwarding into an injection primitive. The instinct was right; the finding above is about the paths where the line does not run.
- **`base-uri 'self'` and `object-src 'none'` are present.** Both are commonly forgotten, both are load-bearing (`base-uri` in particular defeats a `<base>`-tag rewrite of every relative script URL, which would otherwise survive `strict-dynamic`).
- **The `connect-src 'self'` rationale is correct.** All Anthropic/OpenRouter/lean-verifier traffic genuinely is server-to-server: `OPENROUTER_API_URL` is referenced only from `app/lib/llm/*`, reached exclusively through API routes, and no client component is in that import path. The directive is right; only the in-page `data:` consumer was missed.
- **Nonce entropy is sound.** `crypto.randomUUID()` is CSPRNG-backed and carries 122 bits; base64-encoding the string form preserves it. No `Math.random`, no counter, no per-process reuse — a fresh value per request, which is the property that matters.
- **The static-rendering opt-out is correctly reasoned.** The expanded comment in `layout.tsx` identifies a real and non-obvious constraint — per-request nonces and prerendered documents are mutually exclusive — and states the condition (moving to hashes) under which the constraint lifts. This is the kind of "why", not "what", comment that survives contact with a future reader.
- **The underlying injection surface is already defended.** `react-markdown` v10 renders no raw HTML by default and `rehype-raw` is absent, so this CSP is genuine defense-in-depth rather than the only thing standing between LLM output and script execution. That materially lowers the real-world risk of every finding above.

---

## Summary Table

| # | Finding | Severity | Boundary | Confidence |
|---|---------|----------|----------|------------|
| 1 | Nonce never delivered to document; `'self'` fallback weakens policy on non-`strict-dynamic` browsers | High | B2 | High / Med |
| 2 | `x-nonce` trustworthy on proxied paths, forgeable on skipped paths (latent) | Medium | B1, B5 | High / Med |
| 3 | CSP skippable via client-chosen `purpose: prefetch` header | Medium | B5, B2 | High / Low-Med |
| 4 | No `form-action` — the residual vector the threat model names | Medium | B3→B2 | High |
| 5 | No violation reporting, no Report-Only rollout | Medium | B2 | High |
| 6 | `connect-src 'self'` breaks `fetch(dataUrl)` graph export | Medium | B4 | High |
| 7 | `style-src 'unsafe-inline'` documented against the wrong dependency | Low | B3→B2 | High |
| 8 | Dev `'unsafe-eval'` gated on runtime `NODE_ENV`, comment claims build-time guarantee | Low | B2 | High |
| 9 | `img-src` grants `blob:`/`data:` with no identified consumer | Low | B3→B2 | Medium |
| 10 | API routes and static assets served with no CSP at all | Informational | B5 | High |
| 11 | No tests over `buildCsp` or nonce delivery | Informational | B2 | High |

---

## Overall Assessment

**Do not merge as-is.** The change is a net security improvement in intent and its directive list is above average for a first CSP, but the control it advertises is not demonstrably in force. Finding 1 is blocking on its own: the policy's entire value rests on a nonce reaching the document, the diff contains no code establishing that, and the two possible outcomes are total outage (which invites emergency loosening) or, on `strict-dynamic`-unsupporting browsers, a silent degradation to `script-src 'self'` across an application with sixteen same-origin routes returning LLM-derived content.

The pattern connecting the findings is that this diff is confident about the parts that are hard to get wrong and silent about the seams. `buildCsp` is careful. The nonce is generated correctly. The env gate has the right polarity. What is missing is treatment of the boundaries *between* layers — the coupling between the header and the markup (B2), the two populations of `x-nonce` created by the matcher (B1/B5), and the conditions under which the control does not run at all (B5). Three of the six non-informational findings live at that seam, and none of them are visible from inside `proxy.ts` alone, which is also why the commentary — extensive and thoughtful about mechanism — does not cover them.

Suggested order: fix or replace the nonce-delivery mechanism and add the test that would have caught it (1, 11); delete the unused `x-nonce` forwarding (2); add `form-action 'self'` (4); make enforcement unconditional (3); switch `exportGraph.ts` to `toBlob` (6); then ship Report-Only with a reporting endpoint before enforcing (5). Findings 7–10 are comment and hygiene work that can ride along.

No HALT-ESCALATE condition applies: the diff contains no hardcoded credential, no authentication or authorization bypass, no injection into an interpreter or query language, no unsafe deserialization of untrusted input, and no disabled or downgraded cryptographic verification.

---

## Goal-Alignment Note

- **Answered:** Whether the introduced CSP actually constitutes an enforced security boundary (it does not, as written); which trust boundaries the change creates or moves, and which of them are asymmetric or skippable; whether the policy's directive set matches its own stated threat model; whether the dev-only `'unsafe-eval'` carve-out from e5d95a9 is safely gated (it is, with a caveat about runtime vs. build-time framing); what the security consequences are of the documentation defects the fact-check identified.
- **Out of scope:** The correctness of the merged fact-check itself, which was taken as foundation and not re-verified — specifically the nonce-delivery mechanism, the Edge-vs-Node runtime attribution, the Tailwind/`style-src` rationale, and the `x-nonce` staleness. Non-security code quality, performance, API-shape consistency, and the pre-existing security posture of the 16 API routes and the markdown pipeline outside their interaction with this policy. Deployment topology beyond what `docker-compose.yml` shows, which bears on the fact-check's r1 dissent about split infrastructure but could not be resolved from the repository.
- **Escalate:** Nothing meets the HALT-ESCALATE bar. Two items warrant a human decision before merge rather than a reviewer's judgement: (a) whether the nonce approach is retained at all or replaced with hashes — findings 1, 2, 3, and part of 8 all dissolve under the hash design, so this is a fork worth deciding before further patching; and (b) confirmation of the actual deployment topology, since the fact-check's dissent means the severity of finding 1 differs between self-hosted and split infrastructure and the repository alone cannot settle it.
