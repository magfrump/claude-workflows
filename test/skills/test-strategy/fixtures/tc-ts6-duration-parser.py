"""Parse human-written durations ("1h30m", "45s", "2d") for the Tollgate job
scheduler's config files."""

import re
from dataclasses import dataclass

_UNITS = {"d": 86_400, "h": 3_600, "m": 60, "s": 1}
_TOKEN = re.compile(r"(\d+)([a-z]+)")
MAX_SECONDS = 30 * 86_400


class DurationError(ValueError):
    pass


@dataclass(frozen=True)
class Duration:
    seconds: int

    @property
    def minutes(self) -> float:
        return self.seconds / 60

    def __repr__(self) -> str:
        return f"Duration({self.seconds}s)"


def parse_duration(text: str) -> Duration:
    s = text.strip().lower()
    if not s:
        raise DurationError("empty duration")

    pos = 0
    total = 0
    seen: set[str] = set()
    for match in _TOKEN.finditer(s):
        if match.start() != pos:
            raise DurationError(f"unexpected text at {pos}: {s[pos:match.start()]!r}")
        amount, unit = int(match.group(1)), match.group(2)
        if unit not in _UNITS:
            raise DurationError(f"unknown unit {unit!r}")
        if unit in seen:
            raise DurationError(f"unit {unit!r} given twice")
        seen.add(unit)
        total += amount * _UNITS[unit]
        pos = match.end()

    if pos != len(s):
        raise DurationError(f"unexpected text at {pos}: {s[pos:]!r}")
    if total == 0:
        raise DurationError("duration must be positive")
    if total > MAX_SECONDS:
        raise DurationError(f"duration exceeds {MAX_SECONDS} seconds")
    return Duration(total)


# --- tests (tests/test_duration.py) ---

import pytest


@pytest.mark.parametrize(
    "text, seconds",
    [
        ("45s", 45),
        ("1m", 60),
        ("1h30m", 5_400),
        ("2d", 172_800),
        ("1d2h3m4s", 93_784),
        ("  90M  ", 5_400),
        ("30d", 2_592_000),
    ],
)
def test_parses_valid_durations(text, seconds):
    assert parse_duration(text).seconds == seconds


def test_minutes_property():
    assert parse_duration("90s").minutes == 1.5


@pytest.mark.parametrize(
    "text, message",
    [
        ("", "empty"),
        ("   ", "empty"),
        ("10", "unexpected text"),
        ("h10", "unexpected text"),
        ("10x", "unknown unit"),
        ("5min", "unknown unit"),
        ("1h 30m", "unexpected text"),
        ("1h1h", "given twice"),
        ("0s", "must be positive"),
        ("0h0m", "must be positive"),
        ("31d", "exceeds"),
        ("30d1s", "exceeds"),
    ],
)
def test_rejects_invalid_durations(text, message):
    with pytest.raises(DurationError, match=message):
        parse_duration(text)
