# Security Review: subject.go (`RequireToken` middleware)

**Scope:** `subject.go` (single file, scope given by the user)
**Date:** 2026-11-20
Commit: c13fa1bae85005a982881720a8cfde7d7cf9a1bd
**User goal:** Security review of `subject.go`, with the report printed to stdout instead of saved to `docs/reviews/`.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

> 🚨 **HALT: ESCALATE TO HUMAN**
>
> **Pattern:** Missing authentication on privileged endpoints (the auth middleware lets requests through when it fails)
> **Location:** `subject.go:36-40`
> **Detail:** When `Introspect` returns an error, `RequireToken` logs it and calls `next.ServeHTTP` anyway. That includes timeouts (the 800 ms deadline), network failures, and any introspector that reports an invalid token as an error. So any request with a non-empty `Authorization` header can reach the protected handler without authenticating, and an attacker can make this happen on purpose by overloading or slowing the introspection service.
>
> This finding requires immediate human attention before the remaining review is actionable.
> Do not merge or deploy until this is resolved.

## Trust Boundary Map

```
B1: [HTTP Authorization header (client)] → [TrimPrefix "Bearer " + empty check] → [Introspector.Introspect (outbound)]
B2: [Introspector result / error]        → [err / nil-principal branch]         → [next handler (authenticated zone)]
B3: [Introspector error text]            → [log.Printf]                         → [application logs]
```

**Input sources:**

```
S1: Authorization request header — request-time — UNTRUSTED (all sinks; sent outbound to the introspector)
S2: Introspect() (*Principal, error) — request-time, external service — trusted for the principal's content
                                        when err==nil && p!=nil; its *availability* is attacker-influenceable
                                        (load, slow responses), so availability is UNTRUSTED for the auth decision
S3: 800ms timeout constant           — code-constant — trusted
```

The client-controlled header (S1) is the only input. The security decision is made at B2, and it depends on the introspector being reachable. Because the error branch lets the request through, an attacker who can influence S2's availability decides whether authentication happens at all.

## Findings

#### 1. Introspection errors let the request through without authentication

**Severity:** Critical
**Location:** `subject.go:35-40`
**Boundary:** B2
**Move:** #3 (error path), #5 (invert access control)
**Confidence:** High that the mechanism exists. Medium on impact, which depends on downstream handlers.

Any error from `Introspect` sends the request on to `next` without a principal. Attack paths:

- **(a)** Send any non-empty token while the introspector is slow or down.
- **(b)** Flood requests until introspection goes over the 800 ms deadline. Each request also starts its own outbound call, so the attacker's traffic drives the outage (see Finding 3).
- **(c)** Send a bad token, if the `Introspector` implementation returns `error` for invalid or inactive tokens rather than `(nil, nil)`. Many do, for example on HTTP 401 or 400 from the server. Then every garbage token bypasses the check with no outage needed.

If downstream handlers use `RequireToken` as their only gate, this is a complete auth bypass. They are safe only if each one separately rejects a missing principal, and nothing in this file guarantees that.

**Recommendation:** Deny when introspection fails: return 503 (or 401) on any error and never call `next`. If you need resilience, add a short-lived cache of tokens that were already validated, not a bypass.

#### 2. Non-Bearer credentials are forwarded to the introspection service

**Severity:** Medium
**Location:** `subject.go:26`
**Boundary:** B1
**Move:** #2 (implicit sanitization), #6 (follow the secrets)
**Confidence:** Medium

`strings.TrimPrefix` leaves the header unchanged when the `Bearer ` prefix is missing. So `Authorization: Basic dXNlcjpwYXNz`, `bearer xyz` (lowercase), or any other scheme is sent to the introspector verbatim as a "token". That has two effects:

- Unrelated credentials, such as Basic username/password, leak to the introspection endpoint. They may also land in logs through Finding 4.
- Malformed values reach the introspector's error path, which in turn triggers Finding 1(c).

A header of `Bearer ` followed by whitespace also produces a non-empty token.

**Recommendation:** Parse the scheme explicitly. Require a case-insensitive `Bearer` followed by a non-empty token with no whitespace, and return 401 for anything else before making any outbound call.

#### 3. One outbound introspection call per request, with no cache or rate limit

**Severity:** Medium
**Location:** `subject.go:32-35`
**Boundary:** B1, B2
**Move:** #8 (a million of these)
**Confidence:** High

Every request with a non-empty header triggers a synchronous introspection call lasting up to 800 ms. Valid tokens are not cached, and there is no per-client limit before the call. An unauthenticated attacker can multiply their traffic onto the introspection service. Because of Finding 1, overloading that service doesn't just cause an outage: it turns off authentication.

**Recommendation:** Fix Finding 1 first. Then add a bounded TTL cache keyed by a hash of the token, plus rate limiting ahead of introspection.

#### 4. Introspector error text logged without redaction

**Severity:** Low
**Location:** `subject.go:37`
**Boundary:** B3
**Move:** #6 (follow the secrets)
**Confidence:** Low. It depends on the `Introspector` implementation, which is not in scope.

`%v` writes out the full error. Many HTTP client and introspection errors include the request URL, the response body, or the submitted token. Combined with Finding 2, that could put bearer tokens or Basic credentials into application logs.

**Recommendation:** Log a fixed message plus an error category, never the raw error, and never the token itself.

## Untested bypass candidates

The guardrail here is the token check at lines 26-44. These candidates were traced through this file, but their outcomes depend on code outside the scope:

- **`(nil, nil)` versus `(nil, err)` for a revoked or expired token:** depends on the `Introspector` implementation, which was not provided. This decides whether Finding 1(c) is reachable with no outage at all.
- **A principal returned with empty `Subject` or `Scopes`:** the middleware accepts any non-nil `*Principal`. Whether downstream handlers check scopes is not visible here.
- **Downstream handlers' behavior when `principalKey` is absent from the context:** no handlers were provided. This determines the real impact of Finding 1.

## Endorsement Claims

- **Claim:** Requests with an empty `Authorization` header, or one that is exactly `Bearer `, get a 401 before any outbound call is made.
  **Location:** `subject.go:26-30`
  **Evidence:** read-static
  **Verified:** I read the `TrimPrefix` and empty-string check.
  **Not verified:** `Bearer ` followed by more whitespace (produces a non-empty token, see Finding 2).
- **Claim:** When `Introspect` returns `(nil, nil)`, the request gets a 401 and `next` is not called.
  **Location:** `subject.go:41-44`
  **Evidence:** read-static
  **Verified:** I read the nil-principal branch.
  **Not verified:** whether the actual `Introspector` implementation ever returns `(nil, nil)` rather than an error.

## Primitive sweep

No dangerous primitives in scope. The only outbound call is `in.Introspect` through an interface, and its implementation is not in scope. Nothing in this file does exec, deserialization, SQL, HTML interpolation, or path construction.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Introspection errors let requests through unauthenticated | Critical | B2 | `subject.go:35-40` | High (mechanism) / Medium (impact) |
| 2 | Non-Bearer credentials forwarded to introspector | Medium | B1 | `subject.go:26` | Medium |
| 3 | Per-request introspection, no cache or rate limit | Medium | B1, B2 | `subject.go:32-35` | High |
| 4 | Raw introspector error logged | Low | B3 | `subject.go:37` | Low |

## Overall Assessment

The most serious problem is a design flaw that is easy to fix in place: `RequireToken` lets requests through when introspection fails, so attackers who can degrade the introspection service, or send tokens the introspector rejects with an error, can skip authentication entirely. The volume and parsing issues (Findings 2 and 3) make it easier to exploit. The most important fix is to return 503 or 401 on any `Introspect` error and never call `next` in that branch. After that, tighten the parsing of the `Bearer` scheme and add caching and rate limiting. The project is **not safe to merge** as written. There are no other findings within the code paths I read. The endorsement claims have not been verified by running the code.
