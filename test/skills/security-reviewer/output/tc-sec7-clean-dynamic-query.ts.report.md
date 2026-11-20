# Security Review: subject.ts

**Scope:** `subject.ts` (the whole file, at the user's request)
**Date:** 2026-11-20
Commit: 349293961c44e567df88c09d94109efe9009d26a
**User goal:** Check the `GET /orders` handler in `subject.ts` for security weaknesses an attacker could exploit, and print the report to stdout.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

## Trust Boundary Map

```
B1: [HTTP request, req.query.{sort,dir,limit,status}] → [allowlist lookup / ternary / clamp / typeof check] → [SQL text + bind params]
B2: [requireAuth middleware, (req as AuthedRequest).user] → [unchecked cast]                                 → [o.customer_id = $1 tenant filter]
B3: [pool.query result rows / thrown pg error]          → [res.json / no error handler]                        → [HTTP response to client]
```

```
S1: req.query.sort    — request-time  — UNTRUSTED (all sinks); reaches SQL text only via SORT_COLUMNS lookup
S2: req.query.dir     — request-time  — UNTRUSTED (all sinks); collapsed to the "ASC"/"DESC" constants
S3: req.query.limit   — request-time  — UNTRUSTED (all sinks); parsed and clamped to an integer in [1,100], then bound as a parameter
S4: req.query.status  — request-time  — UNTRUSTED (all sinks); bound parameter only, never part of the SQL text
S5: user.id (auth)    — request-time  — trusted for tenant scoping only if requireAuth guarantees it is set
                                         (./auth was not in scope or available to read)
S6: SORT_COLUMNS, SQL fragments — code-constant — trusted (all sinks)
```

Everything that comes in from outside arrives as query-string parameters. The handler builds part of the SQL text dynamically. That text is meant to contain only code constants (S6), with values chosen by S1 and S2. S3 and S4 travel as bind parameters. Tenant isolation rests on S5, which comes from an auth module that wasn't available for review.

## Findings

#### Prototype-chain keys bypass the `SORT_COLUMNS` allowlist and can crash or hang the process

**Severity:** Medium
**Location:** `subject.ts:15-16, 32, 35`
**Boundary:** B1, B3
**Move:** #11 (bypass enumeration), #3 (error path)
**Confidence:** Medium

`SORT_COLUMNS` is a plain object literal, so the lookup also finds properties inherited from `Object.prototype`. Here is what `SORT_COLUMNS[sortKey]` returns for a few inherited keys:

- `?sort=constructor` returns the `Object` function.
- `?sort=toString` returns a function.
- `?sort=__proto__` returns `Object.prototype`.

None of these is nullish, so the `?? SORT_COLUMNS.created` fallback never runs. Each value is then stringified into the SQL text, producing something like `ORDER BY function Object() { [native code] } DESC` or `ORDER BY [object Object] DESC`.

The attacker can't choose the injected text, so this is not SQL injection. It does reliably make Postgres throw a syntax error. Nothing in the handler catches that error:

- **On Express 4,** the rejected promise from the async handler isn't passed to `next()`. The request hangs.
- **On Node ≥15,** where an unhandled rejection kills the process by default, the whole process crashes.

Under those conditions, any logged-in user can take the service down with a single request, as often as they like.

The same unhandled path is reached if `o.status` is a Postgres enum and `?status=` gets a value outside it. That is reachable through S4, a bound parameter.

There is no package manifest, so I couldn't confirm the Express version. That uncertainty is why confidence is Medium.

**Recommendation:**
- Check the key with `Object.hasOwn(SORT_COLUMNS, sortKey)`, or build the table with `Object.create(null)` or a `Map`.
- Wrap the query in `try/catch` or use Express 5, so database errors return a generic 4xx/500 instead of becoming unhandled rejections.

## Untested bypass candidates

- **Input:** `user` is undefined, or `user.id` is undefined or null, after `requireAuth`. **Not tested because:** `./auth` wasn't available. If `user` is absent, `user.id` throws a TypeError, which goes down the same unhandled-rejection path as the finding above. If `id` is undefined, pg binds NULL and `customer_id = NULL` matches no rows, which fails closed. Whether either can happen depends on code I couldn't read.

## Endorsement Claims

- **Claim:** The `status` and `limit` request values reach the database only as bind parameters, never as SQL text.
  **Location:** `subject.ts:23-28, 33, 35`
  **Evidence:** read-static
  **Verified:** I read the code. `params.push` is used for both values, and only the placeholder strings `$${params.length}` are added to `clauses` and the `LIMIT` clause.
  **Not verified:** Whether the `pool` exported from `./pg` passes `params` through to the driver's parameterized-query path, or wraps it with its own formatting.
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** `direction` can only be the literal `"ASC"` or `"DESC"`.
  **Location:** `subject.ts:17`
  **Evidence:** read-static
  **Verified:** I read the strict-equality ternary. Arrays and objects fail `=== "asc"` and fall to `"DESC"`.
  **Not verified:** Nothing further. The value is consumed directly at line 32.

- **Claim:** `limit` is clamped to an integer between 1 and 100, which bounds the response size.
  **Location:** `subject.ts:18`
  **Evidence:** read-static
  **Verified:** I traced `parseInt` inputs by hand: `NaN`, which becomes 20; negative numbers, which become 1; `"1e9"`, which becomes 1; and arrays, which `String()` joins before parsing.
  **Not verified:** Whether any rate limiting is applied upstream of this router.

- **Claim:** The response serializes only `id, status, total_cents, created_at`, filtered by `o.customer_id = $1`.
  **Location:** `subject.ts:20-21, 30, 36`
  **Evidence:** read-static
  **Verified:** I read the SELECT list and the WHERE clause in the SQL string.
  **Not verified:** That `requireAuth` always sets `user.id` to the authenticated customer's ID (in `./auth`, not available).
  **route: code-fact-check** (*pending execution verification*)

The `SORT_COLUMNS` allowlist is intentionally absent from this list because it has a confirmed bypass (Finding 1).

## Primitive sweep

```
Primitive: raw SQL (string-built query text → pool.query)
| Call site / interpolation | Source | Guard | Disposition |
|---|---|---|---|
| `subject.ts:31` `${clauses.join}` | S6 (placeholders only); S4 bound | constant fragments | cleared: no request data in the text |
| `subject.ts:32` `${column}` | S1 via SORT_COLUMNS | object-literal lookup + `??` | Finding 1 (prototype keys bypass the lookup; not injectable, but errors) |
| `subject.ts:32` `${direction}` | S2 | strict ternary | cleared: limited to two constants |
| `subject.ts:33` `LIMIT $n` | S3 bound | clamp + bind | cleared |
| `subject.ts:35` `pool.query(sql, params)` | S1–S6 | parameterized call | cleared for injection; error path is Finding 1 |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Prototype-key bypass of `SORT_COLUMNS`, plus an unhandled query error, crashes or hangs the process | Medium | B1, B3 | `subject.ts:16,35` | Medium |

## Overall Assessment

The handler mostly follows good practice. Values are bound as parameters, the sort column comes from an allowlist, the sort direction comes from a ternary, and the limit is clamped. I found no SQL injection on the paths I read. The one real problem can be fixed where it is: the allowlist is a plain object, so prototype keys get past it, and no error handling surrounds the query. Together, those let a logged-in user cause a denial of service. Whether that means a hung request or a crashed process depends on the Express and Node versions, which I couldn't see.

The most important fix is to check the key with `Object.hasOwn` (or use a `Map`) and add error handling around `pool.query`. Tenant isolation depends on `./auth` being correct, and I couldn't read it.

There are no findings within the code paths I read, beyond the one above. The endorsement claims are still waiting on execution verification.
