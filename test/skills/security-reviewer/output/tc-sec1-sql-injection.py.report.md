**User goal:** Security review of `subject.py`, with the report printed here rather than saved.

Commit: 18e4c58e5791f799af0a59ff2c31c1df126a643a

> 🚨 **HALT — ESCALATE TO HUMAN**
>
> **Pattern:** SQL injection in user-facing code
> **Location:** `subject.py:26,34`
> **Detail:** The `sort` query parameter is pasted straight into the SQL `ORDER BY` clause on a public `GET /api/products` endpoint. An attacker can use it to read any table in `catalog.db` one bit at a time.
>
> This finding requires immediate human attention before the remaining review is actionable.
> Do not merge or deploy until this is resolved.

# Security Review: subject.py

**Scope:** `subject.py` (whole file; the repo has a single commit, so there is no diff against main)
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. (The file has no security-relevant comments or docstrings, so this matters less here.)

No `docs/constraints.md` exists, so every attacker the code exposes is in scope.

## Trust Boundary Map

```
B1: [HTTP query string: sort]      → [none: f-string interpolation, :34]   → [SQLite SQL text]
B2: [HTTP query string: category]  → [sqlite3 bound parameter, :32-33]      → [SQLite WHERE value]
B3: [HTTP query string: limit]     → [int() + min(...,200), :27]            → [SQLite LIMIT value]
B4: [SQLite rows]                  → [dict(r) → jsonify, :38]               → [HTTP response to anonymous client]
```

**Input sources:**

```
S1: request.args["sort"]      — request-time   — UNTRUSTED (all sinks)
S2: request.args["category"]  — request-time   — UNTRUSTED (all sinks)
S3: request.args["limit"]     — request-time   — UNTRUSTED (all sinks)
S4: DB_PATH constant          — code-constant  — trusted (all sinks)
S5: products rows (DB)        — runtime-mutable — UNTRUSTED toward HTML sinks; the
                                                  JSON output here isn't an HTML sink
```

All three inputs come from an anonymous HTTP client, since no auth is visible in this file. `category` crosses into SQL safely as a bound parameter. `sort` crosses with no check at all. `limit` passes a check that only handles the upper end, and the code assumes that check bounds the result size.

## Findings

#### 1. SQL injection through the `sort` parameter in `ORDER BY`

**Severity:** Critical
**Location:** `subject.py:26, 34, 37`
**Boundary:** B1
**Move:** #2 (implicit sanitization assumption), #12
**Confidence:** High

`sort` is read from the query string and inserted with `f" ORDER BY {sort} LIMIT ?"`. Nothing checks it on the way. Python's `sqlite3.execute` refuses to run more than one statement, and SQLite won't accept `UNION` after `ORDER BY`. So stacked queries like `; DROP TABLE` are blocked, but an expression inside `ORDER BY` can still contain any scalar subquery. That gives an attacker two ways to read data:

- **Sort-order oracle:** `sort=(CASE WHEN (SELECT substr(password,1,1) FROM users LIMIT 1)='a' THEN name ELSE price END)`. The order of the returned rows reveals whether the condition is true.
- **Error oracle:** `CASE WHEN <cond> THEN 1 ELSE abs(-9223372036854775808) END` returns 200 when true and 500 (integer overflow) when false.

Either way, any table in the database file can be read with no login. The attacker can also enumerate the schema through `sqlite_master`. Expensive expressions such as `randomblob(...)` or recursive CTEs in a subquery let them burn CPU on the server. Writes are out of reach because only one statement can run.

**Recommendation:** Map `sort` through an allowlist, e.g. `SORTS = {"name": "name", "price": "price", "-price": "price DESC", ...}`. Reject any other value with a 400, or fall back to the default. Column names can't be bound as parameters, so an allowlist is the correct fix. Escaping or quoting is not.

#### 2. Negative `limit` gets past the 200-row cap

**Severity:** Medium
**Location:** `subject.py:27, 35`
**Boundary:** B3
**Move:** #11 (guardrail bypass), #8
**Confidence:** High

`min(int(x), 200)` has no lower bound. `limit=-1` passes through unchanged, and in SQLite a negative `LIMIT` means no limit. One anonymous request therefore returns the whole `products` table. Repeating that request is a cheap way to drain memory and bandwidth, since `fetchall()` loads every row before serializing. This rates Medium because it's a named, reachable way to bypass the intended cap.

**Recommendation:** Use `limit = max(1, min(limit, 200))` and reject input that doesn't parse (see finding 3). Adding an `offset` and paginating is better still.

#### 3. Bad `limit` values and SQL errors cause unhandled 500s

**Severity:** Low
**Location:** `subject.py:27, 37`
**Boundary:** B1, B3
**Move:** #3 (error path)
**Confidence:** Medium

`int("abc")` raises `ValueError`, and an invalid `sort` raises `sqlite3.OperationalError`. Neither is caught. In production Flask this is a generic 500, and that 200-versus-500 difference is exactly the error oracle in finding 1. If the app ever runs with `debug=True`, the traceback would expose the SQL text and file paths. Confidence is Medium because the deployment config isn't visible.

**Recommendation:** Parse `limit` with `request.args.get("limit", 50, type=int)` or an explicit try/except that returns 400. Once finding 1 is fixed, no user input can produce an `OperationalError` from this query.

#### 4. Database connection is opened read-write for a read-only endpoint

**Severity:** Informational
**Location:** `subject.py:11`
**Boundary:** B1
**Move:** #5 (least privilege)
**Confidence:** High

The endpoint only reads, but `sqlite3.connect(DB_PATH)` opens the file read-write. This isn't exploitable today because only one statement can run. A read-only connection would still contain the damage if a later change brought in `executescript` or a second injection point.

**Recommendation:** `sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)`.

## Untested bypass candidates

All `limit` bypass candidates I came up with were traced through the code: `-1` (finding 2), `abc` and `1e3` (500 error, finding 3), and Unicode digits like `٣` (parsed by `int()` and capped correctly). None are left untested.

## Endorsement Claims

- **Claim:** `category` reaches SQLite as a bound `?` parameter, not as SQL text.
  **Location:** `subject.py:31-33`
  **Evidence:** read-static
  **Verified:** I read lines 31–37. `category` is appended only to `params` and passed as the second argument to `execute`.
  **Not verified:** Whether any other route or module builds SQL from `category`. Only `subject.py` was read.
  **route: code-fact-check** (pending execution verification)

- **Claim:** The response serializes only `id`, `name`, `price` and `stock`, as named in the SELECT.
  **Location:** `subject.py:29, 38`
  **Evidence:** read-static
  **Verified:** The fixed column list in the SELECT string on line 29.
  **Not verified:** The extra expressions finding 1 makes possible. They affect row order and errors but add no columns. Also unchecked: whether `stock` is meant to be public.

## Primitive sweep

```
Primitive: raw SQL (sqlite3 execute)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.py:34` (ORDER BY interpolation → :37 execute) | S1 sort | none | Finding 1 (SQLi) |
| `subject.py:32-33` (WHERE → :37 execute) | S2 category | bound parameter | cleared: parameterized |
| `subject.py:35` (LIMIT → :37 execute) | S3 limit | int() + upper cap | Finding 2 (negative bypass); injection cleared (bound int) |
| `subject.py:11` sqlite3.connect | S4 DB_PATH | n/a | cleared: code constant |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | SQL injection through `sort` in `ORDER BY` | Critical | B1 | `subject.py:34` | High |
| 2 | Negative `limit` gets past the 200-row cap | Medium | B3 | `subject.py:27` | High |
| 3 | Unhandled 500s on bad input / SQL errors | Low | B1, B3 | `subject.py:27,37` | Medium |
| 4 | Read-write connection for a read-only endpoint | Informational | B1 | `subject.py:11` | High |

## Overall Assessment

This endpoint should not ship as written. Anyone can reach the `ORDER BY` injection without logging in and use it to read every table in `catalog.db`. The fix is small and local: map `sort` through an allowlist. Bounding `limit` from below and returning 400 on bad input closes the other two issues in the same edit. There's no deeper design problem: `category` already shows the right pattern, and `sort` just needs an allowlist because column names can't be bound as parameters. The most important fix is the `sort` allowlist. The endorsement claims are still waiting on execution-backed verification.
