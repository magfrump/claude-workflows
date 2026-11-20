# Security Review: subject.ts

**Scope:** `subject.ts` (explicit file scope; `./db` and `./session` aren't in the repo, so I couldn't read them)
**Date:** 2026-11-20
Commit: b78daa3892a29bfb9c2648c1ef5d4c56285f4307
**User goal:** Run a security review of `subject.ts` and print the report to stdout.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

No HALT escalation. Authentication is present on both routes. The main flaw below is a missing authorization check (IDOR), not missing authentication, so it doesn't fit escalation pattern #2.

## Trust Boundary Map

```
B1: [HTTP cookie `session`]        → [requireAuth → verifySession()] → [req.user {id, orgId, role}]
B2: [URL param `req.params.id`]    → [none — no tenant check]         → [db.invoice.findUnique]
B3: [DB invoice + relations]       → [res.json(), no projection on :id] → [HTTP response to caller]
```

**Input-source classification:**

```
S1: req.cookies.session        — request-time    — UNTRUSTED (all sinks); trusted only after verifySession returns non-null
S2: req.user.orgId / req.user.id — request-time (derived from S1 via verifySession) — trusted as identity/tenant
                                   IF verifySession validates server-side (session.ts not read)
S3: req.params.id              — request-time    — UNTRUSTED (all sinks, including authorization decisions)
S4: invoice rows + lineItems + billingContact (DB) — runtime-mutable — trusted for its own content; sensitive
                                   (PII) toward response/serialization sinks
```

Untrusted input comes in two ways: the session cookie (S1), which becomes a trusted tenant identity (S2), and the invoice ID path parameter (S3). The list route uses S2 to scope its query. The detail route never uses S2 at all. It treats a valid session plus a caller-supplied ID as enough to return any invoice from any tenant, along with its full relations.

## Findings

#### 1. Cross-tenant IDOR on `GET /invoices/:id`

**Severity:** High (Critical if invoice IDs are sequential or otherwise guessable)
**Location:** `subject.ts:29-38`
**Boundary:** B2, B3
**Move:** #5 Invert the access control model; #2 Implicit sanitization assumption
**Confidence:** High

`requireAuth` only establishes *who* the caller is. The handler looks up the invoice by `req.params.id` alone and never compares `invoice.orgId` to `req.user.orgId`. Any authenticated user in any organization can fetch any other organization's invoice by ID. That includes `lineItems` and the whole `billingContact` record. The list route (`:23`) does scope by `orgId`, which suggests the author meant to enforce tenant isolation and missed it here. How exploitable this is depends on the ID format, which I couldn't see. Sequential IDs make it trivial to enumerate every tenant. UUIDs or CUIDs only slow an attacker down, because invoice IDs end up in emails, PDFs, URLs and logs. In both cases the trust assumption breaks at B2: an untrusted ID goes straight into the authorization-relevant lookup.

**Recommendation:** Scope the query to the tenant, e.g. `findFirst({ where: { id: req.params.id, orgId: req.user!.orgId } })`, and return 404 when there's no match. Return 404 rather than 403 so the endpoint doesn't confirm that an ID exists. Add a regression test with two orgs.

#### 2. Over-serialization of full relation records on the detail route

**Severity:** Medium
**Location:** `subject.ts:30-37`
**Boundary:** B3
**Move:** #7 Test the serialization boundary
**Confidence:** Medium

The detail route uses `include: { lineItems: true, billingContact: true }` without a `select`, so every column on the invoice, its line items and the billing contact goes into `res.json`. Depending on the schema, which I couldn't see, that may include internal fields (`orgId`, audit columns, payment processor references) and contact PII beyond what the UI needs. Combined with Finding 1, this leaks cross-tenant PII. On its own it still exposes more than necessary to same-org members, including `member`-role users. The `role` field exists but is never checked.

**Recommendation:** Use an explicit `select` on the invoice and on each relation, as the list route does, and return only the fields the client needs. Decide whether `member` users should see billing contact details at all.

#### 3. Unbounded invoice list query

**Severity:** Medium
**Location:** `subject.ts:21-27`
**Boundary:** B1
**Move:** #8 What if there are a million of these?
**Confidence:** Low

`findMany` has no `take` or pagination, and nothing in this file rate-limits the route. Any authenticated member can repeatedly ask for the full invoice set of their org. For large tenants that means memory pressure and DB load on every call. I put the confidence at Low because the real impact depends on tenant data volumes and on rate limiting upstream, and I can see neither.

**Recommendation:** Add cursor or offset pagination with a server-enforced maximum `take`. Confirm that a rate limiter covers this router.

#### 4. Async middleware rejection is unhandled (fails closed, but hangs)

**Severity:** Informational
**Location:** `subject.ts:11-19`
**Boundary:** B1
**Move:** #3 Check the error path
**Confidence:** Medium

If `verifySession` throws (malformed token, session-store outage), the rejected promise is never passed to `next(err)`. Under Express 4 the request hangs until timeout and the process logs an unhandled rejection. Under Express 5 it goes to the error handler. Either way `next()` is never called, so access is **denied**, which is correct. The problem is availability and log noise. The same applies to DB errors in both handlers. Those reach Express's default error handler under v5 or hang under v4, and the default handler prints stack traces when `NODE_ENV` isn't `production`.

**Recommendation:** Wrap the middleware in try/catch and return 401 or 503 from the catch, or use an async-handler wrapper. Make sure a production error handler doesn't expose stack traces.

## Untested bypass candidates

These apply to the `requireAuth` guardrail (`subject.ts:11-19`).

| # | Candidate input | Status |
|---|---|---|
| 1 | No `session` cookie, or `cookie-parser` not mounted (`req.cookies` undefined) | **Tested** (traced): `token` is undefined, `user` is null, response is 401. Fails closed. |
| 2 | Cookie that makes `verifySession` throw | **Tested** (traced): the rejection skips `next()`. Fails closed (see Finding 4). |
| 3 | Non-string cookie value, e.g. a `cookie-parser` JSON cookie `j:{...}` that parses to an object | **Listed**, not tested: `session.ts` is out of scope, so I can't tell whether `verifySession` type-checks its input. |
| 4 | Expired, revoked or forged token | **Listed**, not tested: depends entirely on `verifySession`, which I couldn't read. |
| 5 | Session whose payload has an attacker-influenced `orgId` (e.g. an unsigned or client-side token) | **Listed**, not tested: depends on whether `verifySession` loads the user server-side or trusts the token's claims. |

Because candidates 3–5 are untested, `requireAuth` doesn't appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** The `GET /invoices` query filters on `orgId` taken from `req.user`, not from any request parameter.
  **Location:** `subject.ts:22-25`
  **Evidence:** read-static
  **Verified:** I read the handler. The `where` clause uses `req.user!.orgId`, which `requireAuth` sets, and no query or body field reaches the `where`.
  **Not verified:** That `verifySession` (`./session`) gets `orgId` from server-side state rather than client-controlled token claims (bypass candidate 5).
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** The `GET /invoices` response is limited to the four selected columns `id`, `number`, `total` and `status`.
  **Location:** `subject.ts:24`
  **Evidence:** read-static
  **Verified:** I read the `select` clause passed to `db.invoice.findMany`.
  **Not verified:** That `./db` is a standard Prisma client with no middleware or extension that changes result shape.

- **Claim:** Neither query builds SQL from strings. Both pass structured `where` objects to the ORM.
  **Location:** `subject.ts:22-25, 30-33`
  **Evidence:** read-static
  **Verified:** I read both call sites. `req.params.id` is passed as an object value, not interpolated.
  **Not verified:** How `db` is implemented in `./db` (assumed Prisma, but not read).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. There's no raw SQL, exec, deserialization of untrusted formats, URL fetch, path construction or HTML interpolation in `subject.ts`. The ORM calls use structured query objects (see Endorsement Claims).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Cross-tenant IDOR on `GET /invoices/:id` | High | B2, B3 | `subject.ts:29-38` | High |
| 2 | Over-serialization of full relation records | Medium | B3 | `subject.ts:30-37` | Medium |
| 3 | Unbounded invoice list query | Medium | B1 | `subject.ts:21-27` | Low |
| 4 | Async middleware rejection unhandled (fails closed) | Informational | B1 | `subject.ts:11-19` | Medium |

## Overall Assessment

**Not safe to merge as-is.** `GET /invoices/:id` checks authentication but not authorization, so any logged-in user can read any tenant's invoice, line items and billing contact. That's a cross-tenant data leak. It's a local omission, not an architectural problem: the list route already scopes by tenant, and adding the same `orgId` condition to the detail lookup (plus an explicit `select`) fixes Findings 1 and 2. Fix the tenant scope first. Beyond the findings, the review is only partial: everything depends on `verifySession` and `./db`, which I couldn't read, and the endorsement claims are still waiting on execution verification.
