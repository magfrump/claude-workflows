⚠️ **No code fact-check report provided.** Performance claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# Performance Review: subject.py

**Scope:** `subject.py` (the only file in the repo; `app.auth` and `app.db` aren't present, and there is no schema or migrations)
**Date:** 2026-11-19

## Data Flow and Hot Paths

`GET /orgs/me/audit-events` is a sync FastAPI handler. FastAPI runs it in its threadpool, and it holds a DB session from `get_session`. It runs one SQL statement that pulls every audit event for the caller's org, optionally filtered by `event_type`, newest first. It loads the whole result into memory with `.mappings().all()`, copies each row into a `dict`, and returns everything as one JSON response.

**Path temperature: hot.** It's a request handler that runs every time someone opens the org settings page, and a user is waiting on it. It's not a high-QPS endpoint, but its cost grows with data size, not with how often it's called.

**Size of N:** According to the docstring, a row is written for *every API call, login and permission change* by an org's members. I haven't verified that claim. If it's true, `audit_events` is append-only and grows with total API traffic. The per-org row count has no upper bound in this code and only ever goes up. A busy org making about 10k API calls a day would build up about 3.6M rows a year. That's an estimate, so check real per-org row counts.

## Findings

#### 1. Unbounded result set: the handler returns an org's entire audit history in one response

**Severity:** Critical
**Location:** `subject.py:19-35`
**Move:** What's the size of N? / Database interaction pattern (unbounded results) / Memory lifecycle
**Classification:** Macro (missing pagination over an unbounded, append-only collection) / Hot path (user-facing request handler)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The query has no `LIMIT`, no cursor and no time window. One request makes the database read and sort every matching row, sends all of them over the wire, and turns each one into a SQLAlchemy `RowMapping` and then a `dict`. FastAPI then JSON-encodes the whole list. Peak memory, latency and response size all grow linearly with the org's lifetime activity, and the endpoint gets slower every day without any code change. At millions of rows, one page load can use hundreds of MB to GBs of worker memory and hit request timeouts. The query holds a threadpool slot and a pooled DB connection the whole time (see #3). Any org member can trigger this, so it can also be used for DoS: a few reloads of the settings page from a large org can exhaust worker memory.

**Recommendation:** Add keyset pagination with `ORDER BY created_at DESC, id DESC LIMIT :limit`, where `limit` is capped server-side (for example 50–200). Accept a `(created_at, id)` cursor from the last row and return a `next_cursor`. Don't use `OFFSET`, because it gets slower as users page deeper. Change `count` to mean "rows in this page". If the UI needs a total, get it some other way, since `COUNT(*)` over the same unbounded set has the same scaling problem.

#### 2. The filter and sort need a composite index; without one, each request sorts the org's whole history

**Severity:** Medium (becomes High if the index is missing)
**Location:** `subject.py:22-28`
**Move:** Database interaction pattern (missing indexes)
**Classification:** Macro (cost of a full scan and sort grows with table size) / Hot path
**Confidence:** Low (the schema isn't in the repo, so I can't confirm which indexes exist)
**Baseline:** no baseline available — flagged as speculative

The query shape is `WHERE org_id = ? [AND event_type = ?] ORDER BY created_at DESC`. If the only index is on `org_id`, or there is none, the database has to fetch every row for the org and sort it before returning anything. Adding a `LIMIT` won't fix that, because the sort still sees the full set. When `event_type` is used, an `(org_id, created_at)` index has to walk past every non-matching event type. That gets expensive when the filter picks out a rare type, such as permission changes among millions of API-call events.

**Recommendation:** Check that an index on `(org_id, created_at DESC, id DESC)` exists, and add `(org_id, event_type, created_at DESC, id DESC)` for the filtered case. Run `EXPLAIN ANALYZE` against a large org to confirm the plan is an index scan with no sort node.

#### 3. A long-running sync query holds a threadpool slot and a DB connection for its whole duration

**Severity:** Medium
**Location:** `subject.py:12-16, 30`
**Move:** Find the contention point
**Classification:** Macro (how long the resource is held grows with N, per #1) / Hot path
**Confidence:** Medium (depends on pool sizes in `app.db`, which isn't in the repo)
**Baseline:** no baseline available — flagged as speculative

FastAPI runs a sync `def` handler in its threadpool, which defaults to 40 threads in AnyIO. `get_session` holds a pooled connection, which defaults to 5 plus 10 overflow in SQLAlchemy. For a large org, each request holds both while the query, the materialization and the JSON encoding run. A handful of concurrent settings-page loads can use up the DB connection pool, and every other endpoint on the same worker then waits for a connection. This is a consequence of #1 and mostly goes away once results are bounded.

**Recommendation:** Fixing #1 is the main fix. As defense in depth, set a statement timeout on this query, for example `SET LOCAL statement_timeout`.

#### 4. Rows are materialized twice before serialization

**Severity:** Low
**Location:** `subject.py:30, 34`
**Move:** Identify the serialization tax
**Classification:** Micro (an extra per-row copy) / Hot path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`.mappings().all()` builds a list of `RowMapping` objects. `[dict(r) for r in rows]` then builds a second list of dicts, so both exist in memory at the same moment. FastAPI then runs `jsonable_encoder` over the result because there's no `response_model`, which converts `datetime` and IP values and walks the data again. While N is unbounded, this roughly doubles peak per-row memory. Once results are paginated it barely matters.

**Recommendation:** Fix #1 first. After that, you can build the dicts straight from the result iterator, or declare a `response_model`. With the page size bounded, neither change is urgent.

## Endorsements

- The query selects six explicit columns instead of `SELECT *`, so any large columns added to `audit_events` later won't be fetched automatically. `[read: subject.py:19-21]`
- The `event_type` filter runs in SQL (`AND event_type = :event_type`), not in Python after the fetch, so the database can use an index for it once one exists. `[read: subject.py:25-27]`
- Claim to check: the handler sends one SQL statement per request and has no per-row follow-up queries, so there's no N+1 pattern. `current_org` and `get_session` weren't available to inspect. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Unbounded result set, no pagination | Critical | `subject.py:19-35` | High |
| 2 | Composite index needed for filter and sort | Medium | `subject.py:22-28` | Low |
| 3 | Long sync query holds a threadpool slot and DB connection | Medium | `subject.py:12-16,30` | Medium |
| 4 | Rows materialized twice before serialization | Low | `subject.py:30,34` | High |

## Overall Assessment

The main problem is that a user-facing endpoint returns all rows from an append-only table, and that table grows with every API call the org makes. The endpoint will get slower and use more memory for as long as the product exists, and any org member can trigger the worst case. You can fix it in place: add capped keyset pagination (#1) backed by the right composite indexes (#2), and the contention (#3) and double-copy (#4) issues mostly go away with it. Do #1 first. All of these findings are speculative because there are no measurements. Before and after the change, record per-org row counts for the largest orgs, `EXPLAIN ANALYZE` output, and p99 latency and peak worker RSS for this endpoint against a large org, so the fix can be checked against real numbers.
