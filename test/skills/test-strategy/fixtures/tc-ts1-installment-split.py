"""Split an order total into monthly installments for Fernbrook checkout."""

from dataclasses import dataclass
from datetime import date


@dataclass(frozen=True)
class Installment:
    number: int
    due: date
    amount_cents: int


class InstallmentError(ValueError):
    pass


MAX_INSTALLMENTS = 12


def _add_months(start: date, months: int) -> date:
    year = start.year + (start.month - 1 + months) // 12
    month = (start.month - 1 + months) % 12 + 1
    return date(year, month, min(start.day, 28))


def split_order(total_cents: int, count: int, first_due: date) -> list[Installment]:
    if total_cents <= 0:
        raise InstallmentError("total must be positive")
    if not 1 <= count <= MAX_INSTALLMENTS:
        raise InstallmentError(f"count must be between 1 and {MAX_INSTALLMENTS}")

    base, remainder = divmod(total_cents, count)
    amounts = [base] * count
    for i in range(remainder):
        amounts[count - 1 - i] += 1

    return [
        Installment(number=n + 1, due=_add_months(first_due, n), amount_cents=amounts[n])
        for n in range(count)
    ]


def schedule_summary(plan: list[Installment]) -> str:
    total = sum(i.amount_cents for i in plan)
    return f"{len(plan)} payments, {total / 100:.2f} total, first due {plan[0].due.isoformat()}"


# --- tests (tests/test_installments.py) ---

import pytest


def test_split_even_total_into_three():
    plan = split_order(12_000, 3, date(2026, 1, 15))
    assert [i.amount_cents for i in plan] == [4_000, 4_000, 4_000]
    assert [i.number for i in plan] == [1, 2, 3]


def test_single_installment_is_the_whole_total():
    plan = split_order(4_999, 1, date(2026, 3, 1))
    assert len(plan) == 1
    assert plan[0].amount_cents == 4_999


def test_due_dates_roll_over_the_year_and_clamp_to_28th():
    plan = split_order(6_000, 4, date(2026, 11, 30))
    assert [i.due for i in plan] == [
        date(2026, 11, 28),
        date(2026, 12, 28),
        date(2027, 1, 28),
        date(2027, 2, 28),
    ]


@pytest.mark.parametrize("total", [0, -500])
def test_non_positive_total_rejected(total):
    with pytest.raises(InstallmentError):
        split_order(total, 3, date(2026, 1, 1))


@pytest.mark.parametrize("count", [0, 13])
def test_count_out_of_range_rejected(count):
    with pytest.raises(InstallmentError):
        split_order(10_000, count, date(2026, 1, 1))


def test_schedule_summary_formats_total():
    plan = split_order(12_000, 3, date(2026, 1, 15))
    assert schedule_summary(plan) == "3 payments, 120.00 total, first due 2026-01-15"
