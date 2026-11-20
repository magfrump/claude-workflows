# Security Review: subject.py

**Scope:** `subject.py` (single file, as you specified)
**Date:** 2026-11-20
Commit: 5234f64395418654cff149114718b717423f1c2d
**User goal:** Run a security review of `subject.py` and print the report to stdout.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

> 🚨 **HALT: ESCALATE TO HUMAN**
>
> **Pattern:** SQL injection in user-facing code
> **Location:** `subject.py:26,34`
> **Detail:** The `sort` query parameter comes straight from the request and is pasted into the SQL `ORDER BY` clause by an f-string. No authentication is needed. An attacker can put subqueries there to read any table in `catalog.db` one bit at a time, remove the row cap, or force expensive queries.
>
> This finding requires immediate human attention before the remaining review is actionable.
> Do not merge or deploy until this is resolved.

## Trust Boundary Map

```
B1: [HTTP query string: sort]      → [none, f-string interpolation]       → [SQL text executed by sqlite3]
B2: [HTTP query string: category]  → [sqlite3 bound parameter (?)]        → [SQL WHERE clause]
B3: [HTTP query string: limit]     → [int() + min(…, 200)]                → [SQL LIMIT bound parameter]
B4: [catalog.db rows]              → [dict(r) / jsonify]                  → [public JSON response]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `request.args["sort"]` | request-time | UNTRUSTED (all sinks) |
| S2 | `request.args["category"]` | request-time | UNTRUSTED (all sinks) |
| S3 | `request.args["limit"]` | request-time | UNTRUSTED (all sinks) |
| S4 | `DB_PATH` constant | code-constant | trusted (all sinks) |
| S5 | `products` rows (id, name, price, stock) | runtime-mutable (DB) | Trusted for the JSON response sink. `jsonify` escapes the values, and this file has no HTML sink. UNTRUSTED if any downstream consumer renders them as HTML (not in scope). |

All three inputs come from an unauthenticated query string. `category` is properly parameterized. `limit` is cast and capped, but only from above. `sort` gets no handling at all and reaches the SQL text directly. The code assumes, without enforcing it, that `sort` will be a column name.

## Findings

#### 1. SQL injection via `sort` in the ORDER BY clause

**Severity:** Critical
**Location:** `subject.py:26`, `subject.py:34`
**Boundary:** B1
**Move:** #2 (implicit sanitization assumption), #12 (primitive sweep)
**Confidence:** High

`sort` is read from `request.args` and inserted with `f" ORDER BY {sort} LIMIT ?"`. Nothing between the source and the sink checks it. Python's `sqlite3.execute` rejects multiple statements, so `; DROP TABLE` will not work. Expressions and subqueries inside `ORDER BY` do work, for example `sort=(CASE WHEN (SELECT substr(password,1,1) FROM users LIMIT 1)='a' THEN name ELSE price END)`. The row order then acts as a yes/no signal, which lets an attacker pull out any table in `catalog.db` one bit at a time (blind boolean exfiltration), with no authentication. The same hole also allows:
- **Cap bypass:** `sort=name LIMIT -1 OFFSET ?--` comments out the original `LIMIT ?` but keeps one placeholder for the bound value, so all rows come back (I traced this; I did not run it).
- **CPU/memory denial of service:** `randomblob(...)`, or a recursive CTE inside a subquery.

**Recommendation:** Map `sort` through an allowlist, e.g. `{"name": "name", "price": "price", "-price": "price DESC", ...}`, and reject or default anything not on it. Never interpolate the raw value.

#### 2. A negative `limit` removes the 200-row cap

**Severity:** Medium
**Location:** `subject.py:27`
**Boundary:** B3
**Move:** #11 (bypass enumeration), #8 (scale)
**Confidence:** High

`min(int(x), 200)` only caps the value from above. With `limit=-1`, `min(-1, 200)` gives `-1`, and SQLite treats a negative `LIMIT` as "no limit". Any anonymous caller can therefore get the whole `products` table in one response. Repeating that request against a large catalog drains memory and bandwidth. This is separate from Finding 1: fixing the `sort` injection leaves it in place.

**Recommendation:** Clamp both ends, e.g. `limit = max(1, min(limit, 200))`, or reject values below 1 with a 400.

#### 3. Non-integer `limit` returns an unhandled 500

**Severity:** Low
**Location:** `subject.py:27`
**Boundary:** B3
**Move:** #3 (error path)
**Confidence:** High

`limit=abc` raises `ValueError` and ends in a 500 error. `debug` is not turned on anywhere in this file, so no stack trace leaks. If the app runs with `FLASK_DEBUG=1` or the debugger enabled, though, the error page exposes internal details, and the Werkzeug debugger can run code. Injected `sort` values that cause SQL errors also hit this path, which helps an attacker using error-based probing.

**Recommendation:** Use `request.args.get("limit", 50, type=int)`, or catch `ValueError` and return a 400. Make sure debug mode is off in production.

## Untested bypass candidates

All candidates for the `limit` guard (B3) were traced through the code: `-1` gets past it (Finding 2), `abc` causes a 500 (Finding 3), `9999999999` is capped to 200, and `" 5 "` is accepted harmlessly by `int()`. Candidates for the `category` parameterization (B2) were also traced: `' OR 1=1--` and `?` both reach SQLite as bound literals. Neither guard was exercised by actually running the code.

- `limit=0` was not traced against the client's expectations. It returns zero rows, which is a functional question, not a security one.

## Endorsement Claims

- **Claim:** `category` reaches SQL only as a bound parameter, never as part of the SQL text.
  **Location:** `subject.py:31-33,37`
  **Evidence:** read-static
  **Verified:** Lines 32–33 append `" WHERE category = ?"` and push `category` onto `params`, and line 37 passes `params` to `execute`.
  **Not verified:** Whether any other route or module builds SQL from `category` (only this file was in scope). I also did not check the schema's collation or type affinity for `category`.
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** The DB connection is opened per app context and closed in the teardown handler.
  **Location:** `subject.py:9-20`
  **Evidence:** read-static
  **Verified:** `get_db` stores the connection on `g`, and `close_db` pops it and calls `close()`.
  **Not verified:** That teardown runs on every error path under the production WSGI server.

## Primitive sweep

Primitive: raw SQL construction and execution (sqlite3)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.py:29` base SELECT | n/a (literal) | n/a | cleared: string literal |
| `subject.py:32` `WHERE category = ?` | S2 | bound parameter | cleared: parameterized |
| `subject.py:34` `ORDER BY {sort}` | S1 | none | Finding 1 (SQLi) |
| `subject.py:34-35` `LIMIT ?` | S3 | int() + upper cap only | Finding 2 (negative-limit bypass) |
| `subject.py:37` `execute(sql, params)` | S1, S2, S3 | inherits from above | Findings 1, 2 |
| `subject.py:11` `sqlite3.connect(DB_PATH)` | S4 | code constant | cleared: no input reaches it |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | SQL injection via `sort` in ORDER BY | Critical | B1 | `subject.py:26,34` | High |
| 2 | Negative `limit` removes the row cap | Medium | B3 | `subject.py:27` | High |
| 3 | Non-integer `limit` causes an unhandled 500 | Low | B3 | `subject.py:27` | High |

## Overall Assessment

This endpoint should not be merged as written. The `ORDER BY` f-string is unauthenticated SQL injection. It cannot be used to run a second statement, but it is enough to read any table in `catalog.db` blind and to cause denial of service. All of the issues can be fixed in the code as it stands, without a redesign. Most important is putting an allowlist on `sort` (Finding 1), followed by clamping `limit` from below and handling bad `limit` values as a 400. The `category` handling follows the right pattern, but its endorsement claim is read-static only and still needs execution verification.

---

I printed this report to stdout only, as you asked. I did not save a copy to `docs/reviews/`.
