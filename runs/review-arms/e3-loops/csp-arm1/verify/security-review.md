# Security Review — e3/csp-arm1 (verification pass, Arm 1)

Commit: 1eb081e
**User goal:** E3-loops experiment, 0R+0A merge standard. Arm 1 verification / critic stage. Confirm the amber-disposition commit `1eb081e` left 0 red AND surface any NEW amber it introduced.
**Scope:** `git diff d86d2dc..HEAD` on `e3/csp-arm1` (HEAD = `1eb081e`) — the full per-request-nonce CSP feature: `proxy.ts`, `app/lib/security/csp.ts`, `app/layout.tsx`, `app/lib/utils/exportGraph.ts`, and their tests.
**Date:** 2026-08-06
**Based on:** merged code-fact-check (k=3) at `../verify/code-fact-check-report.md` — 0 Incorrect / 0 Stale; residuals are comment-precision only. Prior full-2 rubric + `../amber-dispositions.md` (advisory; all 9 full-2 ambers fixed/acked in `1eb081e`).

Scope discipline: reviewed ancestors of worktree HEAD only. No main checkout, no other worktrees, no csp-arm2/e1 artifacts consulted.

---

## Trust Boundary Map

```
B1: [client HTTP request headers incl. attacker-supplied Content-Security-Policy] → [proxy.ts: new Headers(request.headers); .set("Content-Security-Policy", csp)] → [Next renderer nonce parse]   (new)
B2: [injected/markdown HTML rendered into browser DOM]                             → [CSP enforcement: script-src nonce+strict-dynamic, style-src, img/font/connect, base-uri, object-src, frame-ancestors] → [browser execution/network] (new)
B3: [React Flow graph DOM → canvas]                                                → [exportGraph.ts: toBlob() in-DOM decode (no fetch(data:))]           → [downloaded file / blob]        (moved)
B4: [process.env.NODE_ENV runtime environment]                                     → [proxy.ts → buildCsp(nonce, nodeEnv)]                                  → [policy strictness: dev-only 'unsafe-eval'] (new)
```

The diff introduces a Next.js Proxy (formerly Middleware) that mints a per-request nonce and stamps a CSP onto both the forwarded request headers (so Next's renderer nonces its bootstrap scripts) and the response. The load-bearing trust assumptions: (1) a client-supplied CSP request header must be overwritten, not merged (B1); (2) CSP coverage must be server-determined, never keyed on a client header (B1/B2); (3) the graph export path must not round-trip through `fetch(data:)`, which `connect-src 'self'` blocks (B3); (4) the permissive `'unsafe-eval'` branch must be reachable only when the environment is exactly `development` (B4).

---

## Findings

No Critical or High findings. No HALT-ESCALATE pattern present (no plaintext secrets, no unauthenticated privileged endpoint, no SQL/command injection, no disabled TLS, no hardcoded crypto keys). All previously-open ambers verified closed (see What Looks Good). One NEW Low amber and two Informational items below.

#### form-action directive absent from the policy

**Severity:** Low
**Location:** `app/lib/security/csp.ts:48-58` (directive array — no `form-action` entry)
**Boundary:** B2
**Move:** #5 (invert the access control model — enumerate what the policy does NOT prevent)
**Confidence:** High (that it is absent) / Medium (on materiality)

`form-action` does not fall back to `default-src`, so with no `form-action` directive the policy places no restriction on where a `<form>` may submit. The threat the CSP defends is HTML/markdown injection: script injection is already contained by `script-src 'nonce-…' 'strict-dynamic'`, but a *non-script* injected `<form action="https://evil…">` (with a submit affordance a user could click, or a formaction-bearing button) is not covered — it could exfiltrate to an attacker origin. This is defense-in-depth, not a live script-execution hole, hence Low. It was not added this round (Arm 1 did not add it); under the 0R+0A standard it is a live amber for this diff. The app contains no `<form>` and no client-side third-party call (same rationale that makes `connect-src 'self'` correct), so `form-action 'self'` is safe to add and breaks nothing.

**Evidence:** verbatim from `csp.ts` directive array:
```
"frame-ancestors 'none'",
"base-uri 'self'",
"object-src 'none'",
```
(no `form-action` line); and `git grep "<form"` / `action=` over `app/**` returns zero matches.
**Recommendation:** Add `"form-action 'self'"` to the directive array in `buildCsp`. Extend `csp.test.ts`'s directive-key assertion to include it so the guard fires if it is later dropped.
**Legibility-target:** the maintainer editing `buildCsp` — the directive array is the single obvious place, and the existing `frame-ancestors`/`object-src`/`base-uri` neighbours already establish the "lock down what default-src doesn't cover" pattern this slots into.

#### `data:` allowed in `img-src` and `font-src`

**Severity:** Informational
**Location:** `app/lib/security/csp.ts:53-54`
**Boundary:** B2
**Move:** #2 (implicit-sanitization / what an injected value can reach)
**Confidence:** High

`img-src 'self' data: blob:` and `font-src 'self' data:` permit `data:` URIs. `data:` in image/font contexts is a mild CSP relaxation (it can be a minor exfiltration/oracle channel and defeats some image-based protections), but it is a common and low-risk carve-out and is plausibly required by the graph/KaTeX rendering paths (blob/data-URL images, inline fonts). Not exploitable on its own given script execution is already contained. Noted for completeness only.

**Evidence:** verbatim:
```
"img-src 'self' data: blob:",
"font-src 'self' data:",
```
**Recommendation:** No change required. If a future hardening pass wants to tighten, confirm whether KaTeX/next-font/graph export actually emit `data:` images/fonts before removing; leave as-is otherwise (removing without that check would be security theater / breakage risk).
**Legibility-target:** a future hardening reviewer — the adjacent `connect-src`/`toBlob` comments already document why the export path needs `blob:`, giving the context to judge `data:` here.

#### `style-src 'unsafe-inline'` retained (acknowledged carve-out)

**Severity:** Informational
**Location:** `app/lib/security/csp.ts:52`; rationale documented `csp.ts:14-19`
**Boundary:** B2
**Move:** #2
**Confidence:** High

`'unsafe-inline'` for styles permits injected inline styles (CSS exfiltration / UI-redress vectors exist but are weak). The docstring enumerates the concrete dependents (React `style={{}}`, reactflow transforms, KaTeX, next/font, dev HMR) and states it is a deliberate carve-out. Nonce-based style-src is not currently feasible against those dependents. This is an accepted, documented residual, not a regression — recorded so the tally is complete, not re-raised as open.

**Evidence:** verbatim: `"style-src 'self' 'unsafe-inline'",`
**Recommendation:** No action. Revisit only if the inline-style dependents are eliminated.
**Legibility-target:** already served by the load-bearing docstring block above the directive array.

---

## What Looks Good

All nine full-2 ambers verified closed at `1eb081e` (confirm, per instruction — not re-raised):

- **B1 — client-header CSP bypass closed (prior "CSP skippable via client header").** The client-controllable `missing:` prefetch matcher clause is gone; `config.matcher` carries only a server-determined `source` regex, and `proxy.test.ts` asserts no entry carries `missing:`/`has:`. CSP coverage is no longer a function of a client-supplied header. (🟡-1)
- **B1 — client-supplied CSP request header is clobbered, not merged.** `requestHeaders.set("Content-Security-Policy", csp)` (not `.append`); `proxy.test.ts` "overwrites a client-supplied CSP request header" confirms an attacker `nonce-attacker` value does not survive to the renderer. This is the core B1 defense and it holds. (🟡-5 retarget)
- **B4 — `buildCsp(nonce, nodeEnv)` env param is required (no default).** The shipping production branch is now the branch the tests exercise; comparison is against the permissive value so unset/misspelled/unexpected environments fail closed to the stricter policy. `csp.test.ts` "fails closed for any environment that is not exactly 'development'" covers `undefined/""/"Development"/"dev"/"test"/"prod"`. (🟡-4)
- **B3 — export path cannot regress to `fetch(data:)`.** `exportGraph.ts` uses `toBlob`; `exportGraph.test.ts` asserts `toBlob` called, `toPng` not called, `globalThis.fetch` not called, and that a null blob throws rather than silently downloading nothing. The `connect-src 'self'` ↔ export invariant is now guarded from both sides. (🟡-3, 🟡-8)
- **B1 — matcher typo-safety.** `export const config: ProxyConfig` makes a mistyped matcher key fail `tsc` rather than silently changing which responses carry a CSP. (🟡-2)
- **x-nonce seam removed** (no published-but-unread header); `proxy.test.ts` asserts `x-nonce` is null, with the reinstate-with-a-consumer condition recorded. (🟡-5)
- **Nonce generation** uses `crypto.randomUUID()` (CSPRNG, 122 bits) base64-encoded, fresh per request; `proxy.test.ts` "mints a fresh nonce per request" confirms uniqueness. Node runtime guarantee for `crypto`/`Buffer` is documented.
- **Defense-in-depth response header:** the same policy is also set on the response (`response.headers.set`), and `frame-ancestors 'none'` / `base-uri 'self'` / `object-src 'none'` are all present and asserted.
- **Static-rendering opt-out** (`await headers()` in `layout.tsx`) is correctly required for per-request nonces, with honest cost accounting (🟡-6).

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | NEW/CARRIED |
|---|---------|----------|----------|----------|------------|-------------|
| 1 | `form-action` directive absent | Low | B2 | `csp.ts:48-58` | High/Med | NEW |
| 2 | `data:` in img-src/font-src | Informational | B2 | `csp.ts:53-54` | High | NEW |
| 3 | `style-src 'unsafe-inline'` (acked carve-out) | Informational | B2 | `csp.ts:52` | High | CARRIED (green/acked) |

**0R+0A tally:** 0 Critical · 0 High · **0 Red**. Ambers: **1** (finding #1, Low — a live pre-existing gap in the introduced policy, NEW to this security pass since no prior full-2 amber named form-action). Informational items (#2, #3) do not count toward the amber tally. All 9 prior full-2 ambers confirmed closed.

---

## Overall Assessment

The security posture of this change is strong and the amber-disposition commit `1eb081e` holds: every previously-open amber is verifiably closed, each with a test that fails if the fix is reverted, and the disposition introduced **no new red and no new script-execution exposure**. The two load-bearing trust assumptions — client-supplied CSP headers are clobbered (B1) and CSP coverage is server-determined (B1/matcher) — are both correct and test-guarded. The single NEW amber is the absence of `form-action`, a defense-in-depth directive that does not inherit from `default-src`; it is Low because script injection is already contained by `script-src` nonce + `strict-dynamic` and the app has no forms, but it is a genuine, cheaply-fixable gap and the safest single thing to address (`form-action 'self'` breaks nothing here). Everything else is either an acknowledged, documented residual (`style-src 'unsafe-inline'`, `data:` sources) or already correct. No architectural problem; the one amber is fixable in place with a one-line directive addition plus a test-key extension.

---

## Goal-Alignment Note

**Answered.** The pass confirms `1eb081e` left **0 red** and surfaced the NEW amber it did not add this round (`form-action` absence, Low). All 9 prior full-2 ambers are verified closed, so the standing tally under the 0R+0A standard is **0 red · 1 amber** (the Low `form-action` gap). To reach 0R+0A, add `form-action 'self'` and extend the `csp.test.ts` directive-key assertion; nothing else blocks. Out of scope (per historical rule): main, other worktrees, csp-arm2/e1 artifacts, and the 🟢-9 invisible-export-failure judgement call in `GraphPanel.tsx` (outside this diff).
