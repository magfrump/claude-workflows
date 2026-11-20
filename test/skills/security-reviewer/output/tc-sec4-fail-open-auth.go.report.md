Here's the report. I printed it here as you asked and didn't save it to `docs/reviews/`.

---

Commit: c18a9350d9bfd69f227b6d52f68e089fcccb5b92

**User goal:** Security review of `subject.go` (the `RequireToken` bearer-token middleware), printed to stdout.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# Security Review: subject.go (RequireToken middleware)

**Scope:** `subject.go` (whole file; the repo has only this file and no callers, `Introspector` implementation or downstream handlers)
**Date:** 2026-11-19

**HALT not emitted:** Finding 1 is a fail-open authentication bypass. I've rated it Critical, but the HALT condition ("privileged endpoints reachable without authentication") depends on what `next` wraps and how it handles a missing principal. That code is outside the scope. If any wrapped route is privileged and doesn't check for the principal itself, treat Finding 1 as a HALT.

## Trust Boundary Map

```
B1: [HTTP Authorization header]        → [TrimPrefix "Bearer " / empty check] → [Introspector.Introspect]
B2: [Introspector response (p, err)]   → [err / nil branch in RequireToken]   → [next handler + principalKey in ctx]
B3: [Introspector error / ctx cancel]  → [err != nil branch (fail-open)]      → [next handler, NO principal]
```

```
S1: Authorization header       — request-time      — UNTRUSTED (all sinks)
S2: Introspector (p, err)      — request-time (ext)— trusted for identity when p != nil && err == nil;
                                                     err is attacker-INFLUENCEABLE (timeouts, malformed
                                                     tokens, load), so it is untrusted as an auth decision input
S3: r.Context() cancellation   — request-time      — UNTRUSTED (client controls it by closing the connection)
S4: 800ms timeout constant     — code-constant     — trusted
```

Untrusted header data goes to an external introspection service, and the result decides whether a request reaches `next`. The code assumes that an introspection *error* is a harmless outage and not a decision input. But errors can be caused from outside (S1 contents, S3 cancellation, load against S4's 800ms budget), and on every error path the request goes through unauthenticated.

## Findings

#### 1. Authentication fails open on any introspection error

**Severity:** Critical
**Location:** `subject.go:35-40`
**Boundary:** B3 (and B2)
**Move:** #3 (error path), #5 (invert access control), #11 (bypasses)
**Confidence:** High that the mechanism exists; Medium on impact, which depends on how downstream handlers treat a missing principal

When `Introspect` returns a non-nil `err`, the middleware logs it and calls `next.ServeHTTP(w, r)` with the original request. No principal is attached, but the request is still served. An attacker doesn't need a valid token, just an error. Three ways to get one:
(a) **Load-induced timeout.** Flood requests with random tokens so introspection takes longer than 800ms (each request makes one uncached upstream call; see Finding 3). Every request then passes, including legitimate-looking attack requests.
(b) **Client cancellation.** Send the request and close the connection while introspection is running. `r.Context()` is cancelled, `Introspect` returns `context.Canceled`, and `next` runs anyway. Any side effects that don't depend on the context still happen.
(c) **Contract ambiguity.** The interface doesn't say whether an inactive or invalid token gives `(nil, nil)` or `(nil, err)`. Many introspection clients return an error for inactive or malformed tokens. With such a client, *any garbage token* bypasses auth on every request.
Impact ranges from full authentication bypass, if handlers treat "no principal" as anonymous-allowed or don't check, to a panic per request, if they do an unchecked `ctx.Value(principalKey).(*Principal)` type assertion.

**Recommendation:** Fail closed. On `err != nil`, return `503 Service Unavailable`, or `401` for token-shaped errors, and never call `next`. If you really need degraded availability, make it an explicit per-route opt-in that runs downstream with an explicit "unauthenticated" marker. Document in the `Introspector` contract that invalid tokens return `(nil, nil)`, and treat any other result as a denial.

#### 2. Authorization scheme not validated; non-Bearer credentials forwarded as tokens

**Severity:** Medium
**Location:** `subject.go:26`
**Boundary:** B1
**Move:** #2 (implicit sanitization), #6 (follow the secrets), #11
**Confidence:** Medium

`strings.TrimPrefix` leaves the header unchanged when the prefix is missing. So `Authorization: Basic dXNlcjpwYXNz`, `bearer abc` (lowercase scheme, which RFC 6750/7235 says is case-insensitive) and `Bearer` (no trailing space) are all sent to the introspection service as the "token", and `"Bearer  "` (two spaces) is sent as `" "`. This forwards other credentials (Basic passwords, API keys) to a third-party introspection endpoint, and possibly into its logs and into the error string logged at line 37. It also gives an attacker a cheap way to send odd inputs that may trigger the error path in Finding 1(c).

**Recommendation:** Parse the scheme properly: split on the first space, compare the scheme case-insensitively with `bearer`, require a non-empty token after trimming, and return 401 for anything else without calling the introspector.

#### 3. Unauthenticated amplification to the introspection service

**Severity:** Medium
**Location:** `subject.go:32-35`
**Boundary:** B1, B2
**Move:** #8 (a million of these)
**Confidence:** Medium (rate limiting or caching might exist outside this file)

Any client with any non-empty header causes one outbound introspection call, with no caching, rate limit or token-format pre-check. On its own this is a DoS on the auth provider. Combined with Finding 1(a), it is the trigger that turns the outage into an auth bypass.

**Recommendation:** Reject obviously malformed tokens before the network call, cache positive and negative introspection results for a short TTL keyed by token hash, and rate-limit per client IP. Fixing Finding 1 removes the bypass part of this chain.

#### 4. Introspection errors logged verbatim

**Severity:** Low
**Location:** `subject.go:37`
**Boundary:** B3
**Move:** #6
**Confidence:** Low (depends on what the `Introspector` implementation puts in its errors)

`log.Printf("%v", err)` writes whatever the introspector returns. Errors that wrap HTTP request details or echo the submitted token would put bearer tokens, or the forwarded Basic credentials from Finding 2, into application logs. The message "continuing" also records the fail-open behaviour as intended.

**Recommendation:** Log a classified error (timeout, upstream status, or decode failure) without the token value, and make sure `Introspector` implementations never include the token in their errors.

## Untested bypass candidates

| Input | Why untested |
|---|---|
| Invalid or garbage token: does it give `(nil, err)` or `(nil, nil)`? | No `Introspector` implementation in scope; decides whether Finding 1(c) is trivially exploitable |
| Valid token whose principal has no or empty `Scopes` | Scope checks happen downstream (not in scope); this middleware attaches any non-nil principal |
| Revoked-but-cached token | Depends on whether the introspector caches; not visible |

Traced (tested by reading the code): a missing or empty header gives 401 (lines 27-29). Introspection timeout or cancel calls `next` with no principal (lines 36-39). `(nil, nil)` gives 401 (lines 41-43). A non-Bearer scheme is forwarded raw (line 26).

## Endorsement Claims

- **Claim:** A request with no `Authorization` header, or exactly `"Bearer "`, gets 401 and doesn't reach `next`.
  **Location:** `subject.go:26-30`
  **Evidence:** read-static
  **Verified:** `TrimPrefix` of `""` or `"Bearer "` gives `""`, which leads to `http.Error` + `return`.
  **Not verified:** how whitespace-only tokens such as `"Bearer  "` are handled by the introspector.
- **Claim:** The principal is stored under an unexported typed key (`contextKey`), so other packages can't set or overwrite it via `context.WithValue` with a string key.
  **Location:** `subject.go:11-13, 46`
  **Evidence:** read-static
  **Verified:** the key type is unexported and package-local.
  **Not verified:** the accessor (if any) that downstream handlers use to read `principalKey`, and whether it handles absence.

No guardrail is endorsed. `RequireToken` has untested bypass candidates and an open Critical finding.

## Primitive sweep

Primitive sweep: no dangerous primitives in scope (no exec, SQL, deserialization, HTML interpolation, path construction or `eval`-family calls. The only outbound call is the abstract `Introspect` interface method).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Auth fails open on introspection error | Critical | B3, B2 | `subject.go:35-40` | High (mechanism) / Medium (impact) |
| 2 | Scheme not validated; non-Bearer creds forwarded | Medium | B1 | `subject.go:26` | Medium |
| 3 | Unauthenticated amplification to introspector | Medium | B1, B2 | `subject.go:32-35` | Medium |
| 4 | Introspection errors logged verbatim | Low | B3 | `subject.go:37` | Low |

## Overall Assessment

This middleware should not be merged as written. The core problem is a design decision: an introspection error is treated as permission to continue. Anyone who can make introspection fail can get past the auth gate, by timing it out under load, by cancelling their own request mid-flight, or (depending on the client) by sending a malformed token. Everything is fixable in place. The most important change is to return 503 or 401 on `err != nil` and never call `next`. After that, parse the `Authorization` scheme strictly and add caching and rate limiting in front of introspection. Within the code paths read, the missing-header and nil-principal denials work as written. The endorsement claims are pending execution verification, and the real impact of Finding 1 depends on downstream handlers that weren't available for review.
