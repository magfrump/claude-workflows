# API Consistency Review: `GET /v1/invoices` (subject.ts)

**Scope:** `subject.ts`. The diff is the block from `BEGIN CHANGE UNDER REVIEW` to `END CHANGE UNDER REVIEW` (lines 79–93). Everything else in the file is the baseline.
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

## Baseline Conventions

These conventions come from the four existing endpoints and the shared helpers in `subject.ts`:

- **Routes:** versioned and plural, e.g. `/v1/<plural-resource>` (`/v1/customers`, `/v1/orders`, `/v1/products`). Single items use `/v1/<resource>/:id`.
- **Auth:** every route uses the `requireAuth` middleware and scopes queries with `account_id: req.auth.accountId`.
- **Pagination:** every list endpoint uses cursor pagination through the shared `paginate()` helper (lines 30–50):
  - Query params are `limit` and `cursor`. The comments on lines 52, 57 and 62 document them.
  - The cursor is an opaque base64url string that encodes the last `id`.
  - Results are sorted by `id asc`.
- **Limits:** `DEFAULT_LIMIT = 50` and `MAX_LIMIT = 200` (lines 7–8). Invalid, missing, zero or negative values quietly fall back to the default (`parseLimit`, lines 15–19).
- **List response:** `Page<T>`, which is `{ data: T[], next_cursor: string | null }` (lines 10–13). There is no total count. Clients know the list is finished when `next_cursor` is `null`.
- **Field casing:** snake_case on the wire (`next_cursor`, `account_id`).
- **Errors:** `{ error: { code, message } }` with lowercase snake_case codes (`not_found`, line 73).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `GET /v1/invoices` | route | `GET /v1/customers`, `GET /v1/orders`, `GET /v1/products` | `subject.ts:53,58,63` | Consistent: versioned, plural collection |
| `page` | query param | `cursor` | `subject.ts:36,52,57,62` | Inconsistent: list endpoints page by `cursor`, not page number |
| `per_page` | query param | `limit` | `subject.ts:35,52,57,62` | Inconsistent: page size is `limit` everywhere else |
| `items` | response field | `data` | `subject.ts:11,47` | Inconsistent: list results go in `data` |
| `total` | response field | _(no total-count field on any list)_ | none — searched all response shapes in `subject.ts` (`Page<T>`, lines 10–13, 46–49; order body, line 76; error body, line 73) | New field, no precedent. Establishes a convention |
| `page` | response field | `next_cursor` | `subject.ts:12,48` | Inconsistent: other lists return a continuation token, not a page number |
| `per_page` | response field | _(other lists don't echo the page size)_ | none — searched `Page<T>` and all `res.json` calls in `subject.ts` | New field, no precedent. Casing (snake_case) matches `next_cursor` |

## Findings

#### 1. Invoices uses offset/page pagination while every other list uses cursors

**Severity:** Inconsistent
**Location:** `subject.ts:80-91`
**Move:** #5 Pagination and filtering
**Confidence:** High

All three existing list endpoints share `paginate()`. That gives them cursor pagination, a stable `id asc` order and one response shape. The new handler skips the helper and writes its own offset pagination (`.offset((page - 1) * perPage)`) plus a separate `count(*)` query.

Consumers who already wrote a generic "fetch all pages" loop (keep requesting with `cursor=next_cursor` until it is `null`) can't reuse it for invoices. They have to write a second loop based on page numbers.

Offset paging also behaves differently. If invoices are added or removed while a client is paging, rows can be skipped or returned twice. A cursor on `id` doesn't have this problem. The extra count query also costs a second database round trip on every request, which the other lists don't pay.

**Recommendation:** Replace the handler body with `res.json(await paginate("invoices", req.auth.accountId, req));`. If invoices really need total counts or page jumps, make that a deliberate, documented change to `Page<T>` that applies to every list endpoint, not a one-off.

#### 2. Query params `page` / `per_page` don't match `cursor` / `limit`

**Severity:** Inconsistent
**Location:** `subject.ts:80,82-83`
**Move:** #2 Naming against the grain
**Confidence:** High

Precedent: `limit` and `cursor` query params used in `subject.ts:35-36` (via `paginate`) and documented at `subject.ts:52,57,62`

Every existing list endpoint takes `?limit=&cursor=`. A client that sends `limit=100` to `/v1/invoices` gets no error. The value is silently ignored and the client gets 25 rows. A client that sends `cursor=` always gets page 1 again. Both are easy integration bugs to miss, because nothing fails visibly.

**Recommendation:** Accept `limit` and `cursor`, which you get for free from Finding 1's fix. Drop `page` and `per_page`.

#### 3. Response envelope fields `items` / `page` don't match `data` / `next_cursor`

**Severity:** Inconsistent
**Location:** `subject.ts:91`
**Move:** #2 Naming against the grain / #7 Asymmetry
**Confidence:** High

Precedent: `{ data, next_cursor }` envelope (`Page<T>`) used in `subject.ts:10-13,46-49`

The new response is `{ items, total, page, per_page }`. Any shared client code that reads `response.data` gets `undefined` for invoices. Typed SDKs built around `Page<T>` can't describe this endpoint without a special case.

**Recommendation:** Return `Page<Invoice>`, i.e. `{ data, next_cursor }`.

#### 4. Different default and maximum page size (25/100 vs 50/200)

**Severity:** Inconsistent
**Location:** `subject.ts:83`
**Move:** #1 Baseline / #5 Pagination
**Confidence:** High

The other list endpoints default to 50 rows and cap at 200, using the shared `DEFAULT_LIMIT` and `MAX_LIMIT` constants (lines 7–8). Invoices hard-codes 25 and 100 inline. Clients tuned to request 200 rows silently get half as many, and the magic numbers will drift further if the shared constants ever change.

**Recommendation:** Use `parseLimit` and the shared constants.

#### 5. Bad input isn't sanitized, unlike `parseLimit`

**Severity:** Inconsistent
**Location:** `subject.ts:82-83`
**Move:** #4 Error consistency
**Confidence:** Medium

`parseLimit` handles NaN, zero and negative values by returning the default. The new code doesn't:

- `?page=abc`: `Math.max(1, NaN)` is `NaN`, so `.offset(NaN)` is passed to the query builder.
- `?per_page=abc`: `Math.min(NaN, 100)` is `NaN`.
- `?per_page=0` or `?per_page=-5`: produces `limit(0)` or a negative limit.
- `?page=1.5`: produces a fractional offset.

Depending on how the query builder and database handle these, the result is an unhandled error (probably a 500 without the `{ error: { code, message } }` envelope) or an empty or odd result. Existing endpoints never fail on a bad `limit`. They quietly use the default instead.

**Recommendation:** Use `parseLimit` and `decodeCursor`, as in Finding 1. If page numbers are kept, validate them the same way: integer, at least 1, otherwise fall back to the default.

#### 6. `total` and an echoed `per_page` add fields no other list returns

**Severity:** Informational (downgraded from Minor because there is no precedent)
**Location:** `subject.ts:91`
**Move:** #2 Naming against the grain / #5 Pagination
**Confidence:** Medium

No existing precedent in the response shapes of `subject.ts` (`Page<T>` at lines 10–13 and 46–49, the order body at line 76, the error body at line 73)

No existing list returns a total count or echoes the page size back. Adding them on one endpoint means clients can't rely on `total` being there in general. Choosing the name `total` also sets a precedent: the existing snake_case style might suggest `total_count`.

**Recommendation:** If total counts are wanted, decide the field name and whether it is optional across all lists, and add it to `Page<T>`. Otherwise drop both fields.

## What Looks Good

- The route `/v1/invoices` follows the versioned, plural collection pattern.
- `requireAuth` is applied, and the query is scoped by `account_id`, matching every sibling endpoint.
- Results are ordered by `id asc`, the same as `paginate()`.
- Response field casing is snake_case (`per_page`), consistent with `next_cursor`.
- It adds a new endpoint without touching existing ones, so there is no versioning impact and no breakage for current consumers.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Offset/page pagination instead of the shared cursor `paginate()` | Inconsistent | `subject.ts:80-91` | High |
| 2 | Query params `page`/`per_page` instead of `cursor`/`limit` | Inconsistent | `subject.ts:80,82-83` | High |
| 3 | Envelope `items`/`page` instead of `data`/`next_cursor` | Inconsistent | `subject.ts:91` | High |
| 4 | Default/max page size 25/100 instead of 50/200 | Inconsistent | `subject.ts:83` | High |
| 5 | NaN, zero, negative and fractional input not sanitized | Inconsistent | `subject.ts:82-83` | Medium |
| 6 | `total`/`per_page` fields with no precedent | Informational | `subject.ts:91` | Medium |

## Overall Assessment

The new endpoint gets the route, auth and scoping right. Its pagination contract, however, departs from every other list endpoint in the file: the params, the response envelope, the defaults, input handling and paging behavior are all different. It looks like it was written without the existing `paginate()` helper in mind, even though the helper sits a few lines above it.

Nothing breaks for existing consumers, since this is a new endpoint. But any client or SDK with generic list handling will silently misbehave on invoices. Requests with `limit` and `cursor` are ignored, and the client finds `data` missing.

All of this is easy to fix in place. Replacing the handler body with a single `paginate("invoices", ...)` call resolves Findings 1–5 at once. Total counts, if they're needed, should be a deliberate addition to `Page<T>` for all lists.
