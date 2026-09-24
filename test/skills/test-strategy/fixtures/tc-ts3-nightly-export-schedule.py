"""When should a tenant's nightly export run next? Exports run at a fixed local
wall-clock time in the tenant's own timezone; the worker compares in UTC."""

from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo


class ScheduleError(ValueError):
    pass


def _round_trips(local: datetime) -> bool:
    back = local.astimezone(timezone.utc).astimezone(local.tzinfo)
    return back.replace(tzinfo=None) == local.replace(tzinfo=None)


def _localize(day, at: time, tz: ZoneInfo) -> datetime:
    candidate = datetime.combine(day, at, tzinfo=tz)
    if not _round_trips(candidate):
        candidate = datetime.combine(day, at, tzinfo=tz) + timedelta(hours=1)
    return candidate


def next_run_utc(now_utc: datetime, run_at: time, tz_name: str) -> datetime:
    if now_utc.tzinfo is None:
        raise ScheduleError("now_utc must be timezone-aware")
    try:
        tz = ZoneInfo(tz_name)
    except Exception as exc:
        raise ScheduleError(f"unknown timezone {tz_name!r}") from exc

    local_now = now_utc.astimezone(tz)
    candidate = _localize(local_now.date(), run_at, tz)
    if candidate <= local_now:
        candidate = _localize(local_now.date() + timedelta(days=1), run_at, tz)
    return candidate.astimezone(timezone.utc)


# --- tests (tests/test_schedule.py) ---

import pytest

UTC = timezone.utc


def test_later_today_in_utc_tenant():
    now = datetime(2026, 1, 10, 1, 0, tzinfo=UTC)
    assert next_run_utc(now, time(2, 30), "UTC") == datetime(2026, 1, 10, 2, 30, tzinfo=UTC)


def test_already_ran_today_rolls_to_tomorrow():
    now = datetime(2026, 1, 10, 3, 0, tzinfo=UTC)
    assert next_run_utc(now, time(2, 30), "UTC") == datetime(2026, 1, 11, 2, 30, tzinfo=UTC)


def test_exactly_at_run_time_rolls_to_tomorrow():
    now = datetime(2026, 1, 10, 2, 30, tzinfo=UTC)
    assert next_run_utc(now, time(2, 30), "UTC") == datetime(2026, 1, 11, 2, 30, tzinfo=UTC)


def test_new_york_winter_offset():
    now = datetime(2026, 1, 10, 12, 0, tzinfo=UTC)
    assert next_run_utc(now, time(2, 30), "America/New_York") == datetime(
        2026, 1, 11, 7, 30, tzinfo=UTC
    )


def test_naive_now_rejected():
    with pytest.raises(ScheduleError):
        next_run_utc(datetime(2026, 1, 10, 1, 0), time(2, 30), "UTC")


def test_unknown_timezone_rejected():
    with pytest.raises(ScheduleError):
        next_run_utc(datetime(2026, 1, 10, 1, 0, tzinfo=UTC), time(2, 30), "Mars/Olympus")
