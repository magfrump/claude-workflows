"""Pull new orders from the Quillmark storefront API into the local ledger."""

from dataclasses import dataclass
from typing import Iterator, Protocol


@dataclass(frozen=True)
class Page:
    orders: list[dict]
    next_cursor: str | None


class StorefrontClient(Protocol):
    def list_orders(self, since: str, cursor: str | None, limit: int) -> Page: ...


class Ledger(Protocol):
    def has(self, order_id: str) -> bool: ...
    def insert(self, order: dict) -> None: ...


PAGE_SIZE = 100


def iter_orders(client: StorefrontClient, since: str) -> Iterator[dict]:
    cursor = None
    while True:
        page = client.list_orders(since=since, cursor=cursor, limit=PAGE_SIZE)
        yield from page.orders
        if not page.next_cursor:
            return
        cursor = page.next_cursor


def sync_orders(client: StorefrontClient, ledger: Ledger, since: str) -> int:
    inserted = 0
    for order in iter_orders(client, since):
        if order.get("status") == "test":
            continue
        if ledger.has(order["id"]):
            continue
        ledger.insert(order)
        inserted += 1
    return inserted


# --- tests (tests/test_order_sync.py) ---


class FakeClient:
    def __init__(self, orders):
        self.orders = orders
        self.calls = []

    def list_orders(self, since, cursor, limit):
        self.calls.append((since, cursor, limit))
        return Page(orders=list(self.orders), next_cursor=None)


class FakeLedger:
    def __init__(self, existing=()):
        self.rows = {o: {"id": o} for o in existing}

    def has(self, order_id):
        return order_id in self.rows

    def insert(self, order):
        self.rows[order["id"]] = order


def test_inserts_new_orders():
    client = FakeClient([{"id": "o1", "status": "paid"}, {"id": "o2", "status": "paid"}])
    ledger = FakeLedger()
    assert sync_orders(client, ledger, since="2026-09-01") == 2
    assert set(ledger.rows) == {"o1", "o2"}


def test_skips_orders_already_in_ledger():
    client = FakeClient([{"id": "o1", "status": "paid"}, {"id": "o2", "status": "paid"}])
    ledger = FakeLedger(existing=["o1"])
    assert sync_orders(client, ledger, since="2026-09-01") == 1


def test_skips_storefront_test_orders():
    client = FakeClient([{"id": "o1", "status": "test"}, {"id": "o2", "status": "paid"}])
    ledger = FakeLedger()
    assert sync_orders(client, ledger, since="2026-09-01") == 1
    assert "o1" not in ledger.rows


def test_empty_storefront_inserts_nothing():
    client = FakeClient([])
    assert sync_orders(client, FakeLedger(), since="2026-09-01") == 0


def test_requests_first_page_with_page_size():
    client = FakeClient([])
    sync_orders(client, FakeLedger(), since="2026-09-01")
    assert client.calls == [("2026-09-01", None, 100)]
