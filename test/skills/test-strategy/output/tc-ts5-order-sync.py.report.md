# Test Strategy: Quillmark order sync (`subject.py`)

**Scope:** `subject.py`, the whole file: `iter_orders`, `sync_orders`, `Page` and the protocols (lines 1–44), plus the existing tests at lines 47–99, which live in `tests/test_order_sync.py` in the real project.
**Reviewed:** 2026-11-20

## Test Conventions

- **Framework:** pytest-style plain `test_*` functions with bare `assert`. There are no fixtures, no conftest, no parametrize and no classes.
- **Location:** `tests/test_order_sync.py`.
- **Naming:** each test name is a behaviour sentence, e.g. `test_skips_orders_already_in_ledger`.
- **Test doubles:** hand-written fakes satisfy the `Protocol`s instead of `unittest.mock`.
  - `FakeClient` records `(since, cursor, limit)` in `.calls`. It always returns **one page with `next_cursor=None`**.
  - `FakeLedger` is a dict that can be pre-filled with existing IDs.
- **Fixed input:** every test uses `since="2026-09-01"`.

The protocols make it cheap to test with fakes, so every recommendation below is a fast in-memory test. Integration tests against the real Quillmark API or a real ledger are outside this file.

## Untested Paths Touched by the Change

There is no diff, so this covers every path in the module that the existing tests don't reach.

- **G1** — `subject.py:30-32` — the pagination branch where `page.next_cursor` is truthy: the loop advances `cursor` and requests the next page. The existing `FakeClient` hard-codes `next_cursor=None`, so lines 30–31 only ever take the `return` arm. Line 32 has never run, and no test fetches more than one page — not covered
- **G2** — `subject.py:28` — on later pages, the `cursor`, `since` and `limit=PAGE_SIZE` sent to `list_orders`. `test_requests_first_page_with_page_size` checks only the first call (`cursor=None`) — not covered for page 2 onward
- **G3** — `subject.py:30` — `if not page.next_cursor` is a falsy check, so `next_cursor=""` ends pagination just like `None`. This is probably intended, but it's an unpinned contract — not covered
- **G4** — `subject.py:27-32` — the loop has no termination guard. If the API keeps returning the same `next_cursor`, or never stops returning one, `iter_orders` loops forever and re-yields the same orders. Today `ledger.has` hides the duplicates, so this shows up as a hang, not wrong data — not covered. **Open question:** should this raise?
- **G5** — `subject.py:29-30` — a page with `orders=[]` but a non-null `next_cursor` must keep paginating, not stop. Only the single empty, final page is tested (`test_empty_storefront_inserts_nothing`) — not covered
- **G6** — `subject.py:28` — `client.list_orders` raises on page N > 1, e.g. a timeout, a 5xx turned into an exception, or connection refused. There's no `try`/`except`, so the exception reaches `sync_orders`. Page 1 orders are **already inserted** and the `inserted` count is lost. Recovery depends on re-running and `ledger.has` making that safe — not covered
- **G7** — `subject.py:38` — `order.get("status") == "test"` when `status` is missing or `None`. `.get` returns `None`, so the order is **inserted**. Exact-match comparison means `"TEST"` or `"Test"` is also inserted. Only `"test"` and `"paid"` are tested — not covered. **Open question:** is case-sensitivity intended?
- **G8** — `subject.py:40` — `order["id"]` raises `KeyError` when an order has no `id` key. This aborts the sync partway and leaves earlier orders inserted. An order with `"id": None` passes straight through to `ledger.has(None)` and `ledger.insert`. Both are malformed-response modes — not covered
- **G9** — `subject.py:38-41` — the order of the two guards: the test filter runs before the ledger lookup, so `"test"` orders never touch the ledger, not even `has()`. Only the separate arms are tested, never their interaction — not covered
- **G10** — `subject.py:40-43` — the same `id` appears twice in one sync, either on two pages (common with cursor pagination over a moving dataset) or twice on one page. Correctness depends on `ledger.has` seeing an `insert` made earlier in the same run. Expected result: inserted once, count 1 — not covered
- **G11** — `subject.py:42` — `ledger.insert` raises, e.g. a constraint violation or DB down. The exception propagates, earlier inserts stay and the count is lost — not covered
- **G12** — `subject.py:43-44` — the returned `inserted` count across several pages. It's only asserted for single-page runs — not covered
- **G13** — `subject.py:42` — the exact dict passed to `insert` is the API order object, unmodified. `test_inserts_new_orders` checks the keys of `ledger.rows` but not the stored values — partially covered (keys yes, payload no)

## Recommended Tests

All tests below go in `tests/test_order_sync.py`. Most of them need a paging fake, which is the main infrastructure gap:

```python
class PagedFakeClient:
    """pages: dict mapping cursor (None for first) -> Page."""
    def __init__(self, pages):
        self.pages = pages
        self.calls = []

    def list_orders(self, since, cursor, limit):
        self.calls.append((since, cursor, limit))
        page = self.pages[cursor]
        if isinstance(page, Exception):
            raise page
        return page
```

A fake that maps cursor to page also catches requests for a cursor the API never handed out (`KeyError`). Keep the existing `FakeClient` for single-page tests. You could re-implement it as `PagedFakeClient({None: Page(orders, None)})`, but that's optional.

#### `test_follows_next_cursor_across_pages`

**Closes gaps:** G1, G2, G12
**Type:** unit
**Priority:** high
**What it verifies:** sync fetches every page by passing back the cursor the API returned, and inserts orders from all pages.
**Key cases:**
- Pages: `{None: Page([o1, o2], "c2"), "c2": Page([o3], "c3"), "c3": Page([o4], None)}` with all orders `"paid"`. Expect the return value `4` and `set(ledger.rows) == {"o1","o2","o3","o4"}`.
- `client.calls == [("2026-09-01", None, 100), ("2026-09-01", "c2", 100), ("2026-09-01", "c3", 100)]`. This pins that `since` and `limit` stay the same on every page and that cursors are passed through unchanged.

**Setup needed:** `PagedFakeClient`.

#### `test_empty_intermediate_page_does_not_stop_pagination`

**Closes gaps:** G5
**Type:** unit
**Priority:** high
**What it verifies:** a page with no orders but a `next_cursor` keeps the sync going. Real APIs return these after server-side filtering.
**Key cases:**
- `{None: Page([], "c2"), "c2": Page([o1], None)}` → returns `1`, and `len(client.calls) == 2`.

**Setup needed:** `PagedFakeClient`.

#### `test_empty_string_cursor_ends_pagination`

**Closes gaps:** G3
**Type:** unit
**Priority:** low
**What it verifies:** `next_cursor=""` counts as the last page.
**Key cases:**
- `{None: Page([o1], "")}` → returns `1`, and `len(client.calls) == 1`. `PagedFakeClient` would raise `KeyError("")` if the code tried to follow the empty cursor.

**Setup needed:** `PagedFakeClient`.

#### `test_order_repeated_across_pages_is_inserted_once`

**Closes gaps:** G10
**Type:** unit
**Priority:** high. This is the realistic failure under cursor drift, and if it breaks you get duplicate ledger rows, i.e. data corruption.
**What it verifies:** an `id` seen twice in one run is inserted once and counted once.
**Key cases:**
- `{None: Page([o1, o2], "c2"), "c2": Page([o2, o3], None)}` → returns `3`, and the ledger holds `{o1, o2, o3}`.
- Same `id` twice on one page: `FakeClient([o1, o1])` → returns `1`.

**Setup needed:** `PagedFakeClient`. To also catch double inserts, make a `FakeLedger` variant record `insert` calls in a list (e.g. `self.inserted = []`). Without it, the dict silently overwrites the duplicate and the test can't tell. Then assert `[o["id"] for o in ledger.inserted] == ["o1", "o2", "o3"]`.

#### `test_client_failure_mid_sync_propagates_and_rerun_completes`

**Closes gaps:** G6
**Type:** unit
**Priority:** high
**What it verifies:** if a later page fails, the error reaches the caller (it isn't swallowed), and re-running inserts only what's missing.
**Key cases:**
- `{None: Page([o1], "c2"), "c2": TimeoutError("storefront")}` → `pytest.raises(TimeoutError)`. Afterwards `set(ledger.rows) == {"o1"}`. This documents that the partial commit is current behaviour.
- Re-run with the same ledger and a recovered client `{None: Page([o1], "c2"), "c2": Page([o2], None)}` → returns `1`, and the ledger holds `{o1, o2}` with no duplicate insert.

**Setup needed:** `PagedFakeClient` (supports exception values) and the insert-recording ledger from the previous test.

#### `test_status_filter_only_excludes_exact_test_status`

**Closes gaps:** G7
**Type:** unit
**Priority:** medium. The impact is a silent wrong answer: test orders land in the real ledger.
**What it verifies:** which `status` values count as storefront test orders.
**Key cases:**
- `{"id": "o1"}` (no status) → inserted.
- `{"id": "o2", "status": None}` → inserted.
- `{"id": "o3", "status": "TEST"}` → **currently inserted**. Write this assertion only once the product owner confirms that's intended. If it isn't, it's a bug, and the test should assert exclusion together with the fix.

**Setup needed:** existing `FakeClient` and `FakeLedger`.

#### `test_test_orders_are_not_looked_up_in_ledger`

**Closes gaps:** G9
**Type:** unit
**Priority:** low
**What it verifies:** a `"test"` order whose `id` already exists in the ledger is skipped by the status filter, isn't counted, and doesn't overwrite the existing row.
**Key cases:**
- `FakeLedger(existing=["o1"])`, client returns `[{"id": "o1", "status": "test"}]` → returns `0`, and `ledger.rows["o1"] == {"id": "o1"}`, unchanged.

**Setup needed:** existing fakes.

#### `test_order_without_id_aborts_sync`

**Closes gaps:** G8
**Type:** unit
**Priority:** medium
**What it verifies:** the current contract for a malformed API order: `KeyError` propagates and earlier orders stay inserted.
**Key cases:**
- `[{"id": "o1", "status": "paid"}, {"status": "paid"}]` → `pytest.raises(KeyError)`. Afterwards the ledger holds `{"o1"}`.
- `{"id": None, "status": "paid"}` → currently inserted under key `None`. Decide whether to reject this before asserting either way; see the Summary.

**Setup needed:** existing fakes.

#### `test_ledger_insert_failure_propagates`

**Closes gaps:** G11
**Type:** unit
**Priority:** medium
**What it verifies:** a failing `insert` isn't swallowed and isn't counted.
**Key cases:**
- A ledger whose `insert` raises `RuntimeError` on `o2`, with client orders `[o1, o2, o3]` → `pytest.raises(RuntimeError)`. `o1` stays inserted and `o3` is never attempted.

**Setup needed:** a small `FailingLedger(FakeLedger)` subclass that raises when it sees a chosen `id`.

#### `test_inserts_order_payload_unchanged` (extend `test_inserts_new_orders`)

**Closes gaps:** G13
**Type:** unit
**Priority:** low
**What it verifies:** the ledger stores the API's order dict as-is.
**Key cases:**
- Add `assert ledger.rows["o1"] == {"id": "o1", "status": "paid"}` to the existing test, rather than writing a new one.

**Setup needed:** none.

#### `test_unbounded_cursor_loop_is_guarded` (deferred until behaviour is decided)

**Closes gaps:** G4
**Type:** unit
**Priority:** medium, but blocked.
**What it verifies:** a storefront that keeps returning the same cursor doesn't hang the sync.
**Key cases:**
- `{None: Page([o1], "c1"), "c1": Page([o1], "c1")}` → expect a clear error, e.g. `RuntimeError("cursor did not advance")`, or a stop after N pages.

**Setup needed:** a code change first. With the current code this test would hang, so don't add it until a guard exists. If you want a regression marker in the meantime, use `pytest.mark.timeout` (needs pytest-timeout) together with `xfail`.

## What NOT to Test

- **`Page` dataclass and the `StorefrontClient` / `Ledger` protocols (lines 7–19):** these are declarations with no logic. Testing that `Page` is frozen tests the `dataclasses` library.
- **`PAGE_SIZE` as a standalone value:** `test_requests_first_page_with_page_size` and the multi-page `calls` assertion already pin `limit=100` where it matters. A test asserting `PAGE_SIZE == 100` adds nothing.
- **Calling `iter_orders` directly:** it's private in practice, and every behaviour above is visible through `sync_orders` plus `client.calls`. Testing both levels would duplicate assertions and break if the generator were inlined. The exception would be another caller starting to use `iter_orders`.
- **Property-based tests:** the interesting inputs are few, structural cases (page shapes, cursor sequences), not a wide value space. The tests above are cheaper to read and enumerate those cases directly.
- **Re-testing the single-page arms of lines 38 and 40:** they're already covered by `test_skips_storefront_test_orders` and `test_skips_orders_already_in_ledger`.

## Coverage Gaps Beyond Current Scope

**1.** The real `StorefrontClient` implementation (HTTP adapter) isn't in this repository. Its mapping of HTTP status codes, malformed JSON and timeouts to exceptions decides how G6 behaves in production. It needs its own contract or integration tests against a recorded Quillmark API fixture.

**2.** The real `Ledger` implementation decides whether G10 holds: does `has()` see an `insert()` from the same run, e.g. inside an uncommitted transaction or a batched writer? That needs an integration test against the real store.

**3.** Concurrency: if two sync runs overlap (cron overlap, retries), `has()` then `insert()` is a check-then-act race. Only a unique constraint in the real ledger prevents duplicates. This should be verified where the ledger is implemented.

**4.** Whatever calls `sync_orders` chooses `since` and handles exceptions, e.g. whether a high-water mark advances after a partial failure. Nothing in scope tests that, and a wrong `since` would silently skip orders.

## Summary

The top priority is `test_follows_next_cursor_across_pages`. The existing `FakeClient` can never return a second page, so the pagination loop (line 32) has never run under test. Every storefront with more than 100 new orders depends on it. Add the cross-page duplicate test and the mid-sync failure-and-rerun test next. Together they show that a partial failure followed by a retry doesn't corrupt the ledger.

After the plan is done, the main remaining risk is a non-advancing cursor (G4). That's a guaranteed hang, and a code fix has to come before a test is possible.

Three questions need answers before the related assertions are written:
- Should `"TEST"`, other casings of `"test"`, and orders with no status be filtered out (G7)?
- Should a malformed order (missing or `None` `id`) abort the whole sync or be skipped and logged (G8)?
- Should `iter_orders` limit its page count or detect a repeated cursor (G4)?
