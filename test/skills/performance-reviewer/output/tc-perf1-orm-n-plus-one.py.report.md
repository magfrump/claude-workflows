> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

# Performance Review: subject.py

**Scope:** `subject.py` (the `recent_orders` view)
**Date:** 2026-11-19

## Data Flow and Hot Paths

`recent_orders` is a Django GET view for the admin dashboard. For every request it:

1. Filters `Order` by the user's store, newest first.
2. Splits the result into pages of 50.
3. For each order on the page, reads `customer` twice, `shipping_method` once and `items.count()` once.
4. Returns the rows as JSON.

**Path temperature: hot.** This is a request handler, and the loop body runs once per row (up to 50 times per request). I don't know how often the endpoint is called. An admin dashboard may get less traffic than a storefront, but it may also auto-refresh or be open in several tabs. Please check the real call rate.

**Data sizes:**
- The page size is fixed at 50 rows.
- The total number of orders matches the store's order history. It is unbounded and grows over time.

**Model definitions aren't in the repo.** I couldn't find `shop.models` in the working tree. So I'm assuming `customer` and `shipping_method` are `ForeignKey`s and `items` is a reverse FK or M2M manager, based on how they're used. Please confirm.

## Findings

#### 1. N+1 queries: customer, shipping method and item count are fetched per row

**Severity:** High
**Location:** `subject.py:16-27` (specifically lines 22, 24, 25)
**Move:** Count the hidden multiplications / Database interaction pattern (N+1)
**Classification:** Macro (N+1 query pattern) / Hot path (per-request handler, per-row loop body)
**Confidence:** High (assuming the FK/reverse-relation types above)
**Baseline:** no baseline available — flagged as speculative

The queryset has no `select_related` or `prefetch_related`, so every row triggers extra queries:

- **`order.customer`:** one lazy FK load per row. The second access on line 23 uses Django's per-instance cache, so this costs 1 query per row, not 2.
- **`order.shipping_method`:** one lazy FK load per row.
- **`order.items.count()`:** one `SELECT COUNT(*)` per row.

On a full page that is about 50 × 3 = **150 extra queries**, on top of:

- the page query,
- the paginator's `COUNT(*)`,
- possibly a lazy load of `request.user.store`.

That's roughly **153 round trips per request instead of about 3**. Latency grows linearly with page size times DB round-trip time. With 1 ms round trips, that's about 150 ms of pure query latency before any query execution time. The cost also multiplies database load by about 50× compared with a batched version.

If `customer.full_name` is a property that touches further relations, the count goes up again. I haven't verified this because the model isn't available.

**Recommendation:**
- Build the queryset as `Order.objects.filter(...).select_related("customer", "shipping_method").annotate(item_count=Count("items")).order_by("-created_at")`, and read `order.item_count` in the loop.
- If `shipping_method` is nullable, `select_related` still works, but line 25 will raise on `None`. Handle that separately.
- Capture a query count baseline before and after, using `assertNumQueries` or django-debug-toolbar on a 50-row page.

#### 2. Paginator runs an unbounded `COUNT(*)` and an OFFSET scan on every request; check the composite index

**Severity:** Medium
**Location:** `subject.py:12-13`, `subject.py:32`
**Move:** What's the size of N? / Database interaction pattern (missing indexes, unbounded results)
**Classification:** Macro (cost grows with the store's total order history) / Hot path (per request)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

There are two scaling costs here:

1. **`COUNT(*)`:** Django's `Paginator` computes `num_pages` (line 32) with a `COUNT(*)` over every order the store has ever had, on every request.
2. **OFFSET:** `get_page` uses `LIMIT 50 OFFSET (page-1)*50`, so deep pages scan and throw away every earlier row. Cost is linear in the page number.

Both are fine for small stores but grow without limit as order history builds up. The ordered page query also depends on an index covering `(store_id, created_at DESC)`. With only the default FK index on `store_id`, the database has to sort all of the store's orders on every request. I can't confirm the indexes from this file: **verify that the index exists.**

**Recommendation:**
- Make sure there is a composite index on `(store, -created_at)`, for example `Meta.indexes = [models.Index(fields=["store", "-created_at"])]`.
- If stores can reach large order volumes, think about:
  - keyset/cursor pagination on `created_at, id`, or
  - dropping or caching the exact `num_pages`.

  A "recent orders" dashboard rarely needs an exact total page count.

#### 3. Full `Order` rows fetched when only five columns are used

**Severity:** Low
**Location:** `subject.py:12`
**Move:** Database interaction pattern (overfetching) / Serialization tax
**Classification:** Micro (fixed per-row overhead, bounded at 50 rows) / Hot path
**Confidence:** Low (depends on whether `Order` has wide columns, which I can't see)
**Baseline:** no baseline available — flagged as speculative

The loop only reads `id`, `created_at`, `total` and the two FK ids. Any wide columns on `Order` (notes, JSON blobs, addresses) are fetched and turned into Python objects for nothing. Because the page is capped at 50 rows, this only matters if `Order` has large text or JSON fields.

**Recommendation:** Once Finding 1 is fixed, think about `.only("id", "created_at", "total", "customer__full_name", "customer__email", "shipping_method__label")`, but only if `Order` turns out to be wide. Check `full_name` first: if it's a property rather than a field, it can't go in `.only()`.

## Endorsements

- The page size is a hard-coded constant (50), and the client can't override it. That limits the per-request row count and the size of the loop in Finding 1. [read: subject.py:13]
- Claim: `Paginator.get_page` clamps out-of-range and invalid page numbers to a valid page instead of loading an unbounded result. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | N+1 queries for customer, shipping_method, items.count() (~150 extra queries/page) | High | `subject.py:16-27` | High |
| 2 | Per-request `COUNT(*)` and OFFSET scan over full store history; check `(store, created_at)` index | Medium | `subject.py:12-13, 32` | Medium |
| 3 | Overfetching full `Order` rows | Low | `subject.py:12` | Low |

## Overall Assessment

The view is limited per request by the fixed 50-row page, but it has a textbook N+1. One page costs about 150 extra queries where about 3 would do. This is the most important thing to fix. The fix is local and mechanical: add `select_related` for the two FKs and `annotate(Count("items"))` for the item count. It doesn't point to a structural problem.

The second concern, `COUNT(*)` plus OFFSET over a growing order history, is a slower-burning scaling issue. It mostly depends on having the right composite index.

All findings are speculative because no measurements were available. To confirm the impact of Finding 1, run a query count assertion and take one latency trace on a store with realistic order volume. Also confirm the model definitions (relation types, nullability of `shipping_method`, whether `full_name` is a property), since they weren't in the repo.

One note outside performance scope: `int(request.GET.get("page", 1))` on line 11 raises `ValueError` (a 500 error) on non-numeric input before `get_page` can handle it.
