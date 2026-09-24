# Order service — package source, concatenated into one file for review.
#
# Architecture: layered (ports and adapters).
#   orders/domain/          business rules: entities, value objects, domain services
#   orders/application/     use cases that orchestrate the domain
#   orders/infrastructure/  adapters for PostgreSQL, the message bus, and HTTP
#
# Each "# ---- file: <path> ----" marker starts a separate module.


# ---- file: orders/domain/model.py ----
from dataclasses import dataclass, field
from decimal import Decimal
from uuid import UUID, uuid4


@dataclass(frozen=True)
class LineItem:
    sku: str
    quantity: int
    unit_price: Decimal

    @property
    def subtotal(self) -> Decimal:
        return self.unit_price * self.quantity


@dataclass
class Order:
    customer_id: UUID
    items: list[LineItem]
    id: UUID = field(default_factory=uuid4)
    total: Decimal = Decimal("0")


# ---- file: orders/domain/pricing.py ----
import os
from decimal import ROUND_HALF_UP, Decimal
from uuid import UUID

from orders.domain.model import LineItem
from orders.infrastructure.pg_discounts import PostgresDiscountTable


class PricingService:
    """Computes order totals, applying the customer's negotiated discount."""

    def __init__(self) -> None:
        self._discounts = PostgresDiscountTable(dsn=os.environ["ORDERS_DSN"])

    def total_for(self, customer_id: UUID, items: list[LineItem]) -> Decimal:
        subtotal = sum((item.subtotal for item in items), Decimal("0"))
        percent = self._discounts.percent_for(customer_id)
        discounted = subtotal * (Decimal("100") - percent) / Decimal("100")
        return discounted.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


# ---- file: orders/infrastructure/pg_discounts.py ----
from decimal import Decimal
from uuid import UUID

import psycopg


class PostgresDiscountTable:
    def __init__(self, dsn: str) -> None:
        self._conn = psycopg.connect(dsn, autocommit=True)

    def percent_for(self, customer_id: UUID) -> Decimal:
        row = self._conn.execute(
            "SELECT percent FROM customer_discounts WHERE customer_id = %s",
            (customer_id,),
        ).fetchone()
        return Decimal(row[0]) if row else Decimal("0")


# ---- file: orders/infrastructure/pg_orders.py ----
import psycopg

from orders.domain.model import Order


class PostgresOrderRepository:
    def __init__(self, dsn: str) -> None:
        self._conn = psycopg.connect(dsn)

    def add(self, order: Order) -> None:
        with self._conn.transaction():
            self._conn.execute(
                "INSERT INTO orders (id, customer_id, total) VALUES (%s, %s, %s)",
                (order.id, order.customer_id, order.total),
            )
            for item in order.items:
                self._conn.execute(
                    "INSERT INTO order_items (order_id, sku, quantity, unit_price)"
                    " VALUES (%s, %s, %s, %s)",
                    (order.id, item.sku, item.quantity, item.unit_price),
                )


# ---- file: orders/application/ports.py ----
from typing import Protocol

from orders.domain.model import Order


class OrderRepository(Protocol):
    def add(self, order: Order) -> None: ...


# ---- file: orders/application/place_order.py ----
from uuid import UUID

from orders.application.ports import OrderRepository
from orders.domain.model import LineItem, Order
from orders.domain.pricing import PricingService


class PlaceOrder:
    def __init__(self, pricing: PricingService, orders: OrderRepository) -> None:
        self._pricing = pricing
        self._orders = orders

    def __call__(self, customer_id: UUID, items: list[LineItem]) -> Order:
        order = Order(customer_id=customer_id, items=items)
        order.total = self._pricing.total_for(customer_id, items)
        self._orders.add(order)
        return order
