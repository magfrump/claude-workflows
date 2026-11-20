**User goal:** Get a security review of `subject.ts` (the authenticated `GET /orders` Express handler), printed to stdout.

Commit: 2cc8d9deec53a74579c881b47df4b019ed12b0d8

# Security Review: subject.ts

**Scope:** `subject.ts` (whole file, 39 lines)
**Date:** 2026-11-19
**Context limits:** `./auth` (`requireAuth`, `AuthedRequest`) and `./pg` (`pool`) are not in the repository. No `package.json` exists, so the Express and Node versions can't be checked. There is no `docs/constraints.md`, so every attacker the code exposes is in scope.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

## Trust Boundary Map

```
B1: [HTTP query string: sort, dir, limit, status] → [allowlist / ternary / clamp / typeof + $n param] → [SQL text + params → Postgres]
B2: [session/token credential]                    → [requireAuth (./auth, not in repo)]             → [user.id → o.customer_id = $1]
B3: [Postgres result rows / query errors]         → [res.json / async rejection path]               → [HTTP response to client]
```

**Input sources:**

```
S1: req.query.sort    — request-time  — UNTRUSTED (all sinks); reaches SQL text via an object-key lookup
S2: req.query.dir     — request-time  — UNTRUSTED (all sinks); reduced to a literal "ASC"/"DESC"
S3: req.query.limit   — request-time  — UNTRUSTED (all sinks); parsed to an integer, sent as a bound param
S4: req.query.status  — request-time  — UNTRUSTED (all sinks); sent as a bound param
S5: user.id (requireAuth) — request-time, derived from credential — trusted for row scoping only if ./auth
                         verifies the credential (not verifiable here)
S6: SORT_COLUMNS, SQL fragments — code-constant — trusted (all sinks)
```

All four query parameters come from the client. Three are turned into constants or bound parameters before they reach SQL. `sort` is the only one that affects SQL *text*, and it gets there through a lookup on a plain object. For every user, row scoping depends on `requireAuth` setting `user.id` correctly, and that code isn't in the repo.

## Findings

#### 1. Prototype keys in `sort` throw an SQL error that is never caught (possible process crash)

**Severity:** Medium
**Location:** `subject.ts:7-16`, `subject.ts:35`
**Boundary:** B1, B3
**Move:** #11 (guardrail bypass), #3 (error path)
**Confidence:** Medium (the impact depends on the Express and Node versions, which aren't visible)

`SORT_COLUMNS` is a plain object literal, so the lookup `SORT_COLUMNS[sortKey]` also finds inherited keys:

- `?sort=__proto__` returns `Object.prototype`. That is not nullish, so the `??` fallback never runs, and the value prints into the SQL as `ORDER BY [object Object] DESC`.
- `?sort=constructor` or `?sort=toString` returns a function. Its source text, `function Object() { [native code] }`, is put into the SQL.

The attacker can't choose what text gets injected. Only built-in prototype values can be reached, so this is **not** SQL injection. It does, however, reliably make Postgres return a syntax error. Nothing catches that error: there is no try/catch around `await pool.query(...)` (line 35).

- On Express 4, the rejected promise is unhandled. The request hangs until the socket times out.
- On Node ≥15, the default `--unhandled-rejections=throw` **ends the process**. Any logged-in user could then take the service down with one GET request, and repeat it.
- On Express 5, the error goes to the error handler. The impact drops to a 500 response, plus whatever that handler leaks from the pg error.

Every other DB failure (timeouts, pool exhaustion) takes the same unhandled path.

**Recommendation:** Check membership with `Object.hasOwn(SORT_COLUMNS, sortKey)`, or use a `Map` or `Object.create(null)`. Wrap the query in try/catch, or pass errors to `next(err)`, and return a generic 500 response.

#### 2. Row scoping depends entirely on unseen `requireAuth`

**Severity:** Informational
**Location:** `subject.ts:3`, `subject.ts:13-21`
**Boundary:** B2
**Move:** #5 (invert access control)
**Confidence:** Low (`./auth` is not in the repo)

The query is always limited to `o.customer_id = $1`, with `user.id` as a bound parameter. That shuts out filter-based IDOR from the query string. But the protection is only as good as `requireAuth`. If it ever calls `next()` with `user` undefined, line 21 throws `TypeError` inside the async handler, which leads to the same unhandled-rejection path as Finding 1. If it reads `user.id` from an unverified token, that is a full IDOR. Neither failure mode is visible from this file.

**Recommendation:** Review `./auth`: confirm it verifies the credential's signature or session and rejects requests before calling `next()` when there is no user.

## Untested bypass candidates

None. Every candidate below was traced through the code.

| Guardrail | Candidate | Outcome |
|---|---|---|
| `SORT_COLUMNS` allowlist (l.16) | `sort=__proto__` / `constructor` / `toString` | **Bypass:** a non-column value reaches the SQL text, causing a syntax error (Finding 1) |
| `SORT_COLUMNS` allowlist | `sort[]=total&sort[]=x` (qs array) | `String(arr)` gives `"total,x"`: no match, falls back to default |
| `SORT_COLUMNS` allowlist | `sort[a]=b` (qs object) | `"[object Object]"`: no match, falls back to default |
| `dir` ternary (l.17) | `dir=ASC`, `dir=asc%20`, `dir[]=asc` | Strict `===` fails, so `DESC`: only a constant is used |
| `limit` clamp (l.18) | `-5`, `abc`, `1e9`, `99999` | Becomes 1, 20, 1 and 100, all within [1,100], and sent as a bound param |
| `status` typeof (l.23) | `status[]=x`, `status=' OR 1=1--` | Array is skipped; the string is a bound `$n` param, so no injection |

## Endorsement Claims

- **Claim:** `status`, `limit` and `user.id` are sent to `pool.query` as positional parameters, not interpolated into the SQL text.
  **Location:** `subject.ts:20-35`
  **Evidence:** read-static
  **Verified:** Lines 24-25 and 28-33 interpolate only `$${params.length}` placeholder indices (numbers produced by code). The values themselves go only into `params`.
  **Not verified:** that the `pool` exported by `./pg` is a stock `pg.Pool` whose `query(text, values)` binds parameters on the server, not a wrapper that substitutes them as strings.
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** `direction` can only be one of two literal strings.
  **Location:** `subject.ts:17`
  **Evidence:** read-static
  **Verified:** The ternary compares with strict `===` against `"asc"` and yields only the literals `"ASC"` or `"DESC"`.
  **Not verified:** none needed for this property. The SQL concatenation on line 32 was read.

- **Claim:** The response includes four explicitly named columns, not whole rows.
  **Location:** `subject.ts:30`, `subject.ts:36`
  **Evidence:** read-static
  **Verified:** The SELECT list is `o.id, o.status, o.total_cents, o.created_at`, and `rows` is serialized directly.
  **Not verified:** the `orders` table schema, i.e. whether `status` could hold sensitive free text.

## Primitive sweep

Primitive: raw SQL (string-built query text)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.ts:31` `${clauses.join(" AND ")}` | S6 (+ numeric `$n` index) | values bound as params | cleared: clause text comes only from code |
| `subject.ts:32` `${column}` | S1 sort | `SORT_COLUMNS` lookup + `??` | Finding 1 (prototype-key bypass; not injectable) |
| `subject.ts:32` `${direction}` | S2 dir | strict-equality ternary | cleared: two constants only |
| `subject.ts:33` `$${params.length}` | S3 limit (as param) | parseInt + clamp, bound | cleared: only the index is interpolated |
| `subject.ts:35` `pool.query(sql, params)` | S1–S5 | parameterized | cleared for injection; error path is Finding 1 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Prototype keys in `sort` throw an SQL error that is never caught (possible process crash) | Medium | B1, B3 | `subject.ts:16,35` | Medium |
| 2 | Row scoping depends entirely on unseen `requireAuth` | Informational | B2 | `subject.ts:13-21` | Low |

## Overall Assessment

The handler is well built for injection resistance. Every value from the client either becomes a constant or is sent as a bound parameter. The sort column goes through an allowlist instead of being interpolated raw. The one real flaw is that the allowlist is a plain object, so `sort=__proto__` gets past it. Combined with an async handler that has no error handling, that lets any logged-in user cause an SQL error that is never caught. On Express 4 with modern Node, that can crash the process. Both fixes fit in a few lines and don't need any redesign: use `Object.hasOwn` (or a `Map`) for the lookup, and add try/catch or `next(err)`. Fixing the error handling matters most, because it also covers every other way the DB call can fail. Beyond that, there are no findings within the code paths read, and the endorsement claims are pending execution verification. This assessment is partial: `./auth` and `./pg` were not available.
