**User goal:** You want a security review of `subject.ts`, an Express invoice router, with the report printed here rather than saved.

---

Commit: 22d0b0674b0b177cef9df2e2c07c24a547665e89
**User goal:** Security review of `subject.ts`, report printed to stdout.

# Security Review: subject.ts

**Scope:** `subject.ts` (whole file; no `main` branch exists, so this is not a diff)
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** Nobody has independently checked what the comments and docs say about security. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

The code this file calls (`./db`, `./session`, the app setup, cookie-parser, the Express version) is not in the repo. Findings that depend on it say so.

No HALT block: none of the escalation patterns matched. The authorization gap in Finding 1 is serious, but it isn't *missing authentication* on a privileged endpoint.

## Trust Boundary Map

```
B1: [HTTP cookie `session`]      → [requireAuth → verifySession()] → [req.user (id, orgId, role)]
B2: [URL param `:id`]            → [none]                          → [db.invoice.findUnique where id]
B3: [DB invoice + relations]     → [none (full include)]           → [res.json to authenticated caller]
B4: [authenticated user context] → [orgId filter (list route only)] → [tenant-scoped invoice data]
```

```
S1: req.cookies.session       — request-time    — UNTRUSTED (all sinks); trusted only after verifySession returns
S2: req.params.id             — request-time    — UNTRUSTED (all sinks: DB lookup key, authz decisions)
S3: req.user (from session)   — request-time, derived — trusted for identity/orgId if verifySession is sound (not read)
S4: invoice/lineItems/billingContact rows — runtime-mutable — UNTRUSTED for output-exposure decisions (full row shape unknown)
```

Untrusted input comes in through the session cookie (S1) and the invoice ID in the URL (S2). The list route ties what it returns to the caller's `orgId` (B4). The detail route skips that check entirely: an authenticated user from any organization can turn an invoice ID into the full record.

## Findings

#### 1. Any logged-in user can read any organization's invoices (IDOR) on `GET /invoices/:id`

**Severity:** High (Critical if invoice IDs can be guessed or counted up)
**Location:** `subject.ts:29-38`
**Boundary:** B2, B4
**Move:** #5 Invert the access control model; #2 Implicit sanitization assumption
**Confidence:** High

`requireAuth` only checks that the caller is logged in. The handler then looks up the invoice by `req.params.id` alone, without the `orgId` filter the list route uses on line 23. Any user from any organization can call `GET /invoices/<id>` and get back another organization's invoice, its line items and its billing contact. How easy this is depends on the ID format in `./db`, which isn't in the repo. With sequential or short IDs, an attacker can simply walk through every tenant's invoices. With UUIDs or cuids, IDs still leak in URLs, emails, logs, support tickets and PDFs, so the check can't rely on IDs being secret. A 404 for a missing invoice versus a 200 for one that exists also tells an attacker which IDs are real.

**Recommendation:** Filter on the caller's organization: `findFirst({ where: { id: req.params.id, orgId: req.user!.orgId } })`, or use a compound unique key. Return 404 whether the invoice is missing or belongs to another organization. Add a test that a user from org B gets a 404 for an org-A invoice ID.

#### 2. A session check that throws can hang requests or crash the server

**Severity:** Medium
**Location:** `subject.ts:11-19`
**Boundary:** B1
**Move:** #3 Check the error path; #8 "What if there are a million of these?"
**Confidence:** Low (depends on the Express version and on `verifySession`, neither of which I read)

`requireAuth` is an `async` function with no try/catch. Express 4 doesn't catch rejected promises from middleware. If `verifySession` throws on a malformed token (many JWT and crypto libraries do) or on a backend error, `next()` is never called and no response is sent, so the request hangs. On Node ≥15 with no `unhandledRejection` handler, the whole process can crash. Access is still denied when this happens. The risk is availability: anyone without an account can send a crafted `session` cookie and repeatedly stall or crash the service. Express 5 forwards the rejection to the error handler, which removes most of the risk.

**Recommendation:** Wrap the body in `try { … } catch { return res.status(401).json({ error: "unauthenticated" }) }`. Alternatively, confirm the app is on Express 5 and that `verifySession` never throws on bad input.

#### 3. The detail route returns whole related records, not a chosen set of fields

**Severity:** Low
**Location:** `subject.ts:30-37`
**Boundary:** B3
**Move:** #7 Test the serialization boundary
**Confidence:** Low (the schema isn't in the repo)

The list route picks four specific fields with `select`. The detail route instead returns the whole invoice row plus the full `lineItems` and `billingContact` rows with `include`. Any internal fields on those models go straight to the client: internal notes, payment-processor IDs, tax IDs, soft-delete flags, or columns added to the schema later. Combined with Finding 1, all of that is exposed across organizations.

**Recommendation:** Replace `include` with an explicit nested `select` listing only the fields the client needs (a defined response shape, or DTO).

#### 4. The `role` field is never checked

**Severity:** Informational
**Location:** `subject.ts:6`, `21-38`
**Boundary:** B4
**Move:** #5 Invert the access control model
**Confidence:** Medium

`req.user.role` (`member` or `admin`) is declared but no route reads it. Members and admins in an organization can see exactly the same invoices and billing contacts. If billing data is meant to be admin-only, that rule isn't enforced here. If it isn't meant to be, nothing needs to change.

**Recommendation:** Decide whether members should see billing contacts and full invoices. If not, add a role check to the detail route.

## Endorsement Claims

- **Claim:** The `GET /invoices` list query filters by `req.user.orgId` and returns only `id`, `number`, `total` and `status`.
  **Location:** `subject.ts:21-27`
  **Evidence:** read-static
  **Verified:** The Prisma-style `findMany` call has `where: { orgId: req.user!.orgId }` and an explicit `select` of four fields.
  **Not verified:** That `verifySession` (`./session`) returns an `orgId` that comes from the server-side session, not from anything the client can edit.
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** Requests with no `session` cookie, or one that `verifySession` rejects (returns a falsy value for), get a 401 before any route handler runs.
  **Location:** `subject.ts:11-16`
  **Evidence:** read-static
  **Verified:** If the token is missing, `user` is set to `null` and the middleware returns 401 without calling `next()`.
  **Not verified:** What `verifySession` does with a malformed token (throw vs. return null; see Finding 2), and whether cookie-parser is mounted upstream (if it isn't, every request gets a 401).

- **Claim:** In this file, both DB lookups pass the user-supplied value as an ORM query object, never as raw SQL text.
  **Location:** `subject.ts:22-33`
  **Evidence:** read-static
  **Verified:** Only `findMany` and `findUnique` are called, each with an object argument.
  **Not verified:** How `./db` implements them (it's assumed to be Prisma), and whether `req.params.id` reaches any raw query further down.

### Untested bypass candidates
The only guard in this file is `requireAuth`. Candidate inputs:
1. A malformed or oversized `session` cookie that makes `verifySession` throw. Not tested because the `./session` source isn't in the repo (see Finding 2).
2. A valid session token after logout or revocation. Not tested because the session store isn't available.
3. A session token signed with a key or algorithm other than the expected one (e.g. `alg: none`). Not tested because the verification code isn't in the repo.

Because of these, `requireAuth`'s rejection of forged sessions is not endorsed above. The only claim made is the narrow one about a missing token or a falsy return value.

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. There is no raw SQL, exec, deserialization of untrusted formats, HTML interpolation, path construction or URL fetch. The ORM calls are listed under Endorsement Claims.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Cross-org IDOR on `GET /invoices/:id` | High | B2, B4 | `subject.ts:29-38` | High |
| 2 | Session check can throw → request hang or process crash | Medium | B1 | `subject.ts:11-19` | Low |
| 3 | Full related records returned instead of chosen fields | Low | B3 | `subject.ts:30-37` | Low |
| 4 | `role` never checked | Informational | B4 | `subject.ts:6,21-38` | Medium |

## Overall Assessment

The file has a clear, fixable authorization bug, not a design problem. The list route scopes results to the caller's organization correctly, but the detail route leaves that check out. Any logged-in user can read any organization's invoice, line items and billing contact if they know or guess its ID. **The most important fix is adding `orgId: req.user.orgId` to the `/invoices/:id` lookup**, together with a cross-organization test. After that, harden `requireAuth`'s error path and switch the detail response to an explicit `select`. Do not merge as-is. Even after these fixes, the code paths I read show no other findings, but the endorsement claims are still waiting on execution verification, and `./session` and `./db` have not been reviewed.
