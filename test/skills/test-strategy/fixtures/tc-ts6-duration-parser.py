"""Parse human-written durations ("1h30m", "45s", "2d") for the Tollgate job
scheduler's config files. Units may come in any order, each at most once.
Matching ignores case and surrounding whitespace, and error positions refer to
the stripped, lowercased text."""

import re
from dataclasses import dataclass

_UNITS = {"d": 86_400, "h": 3_600, "m": 60, "s": 1}
_TOKEN = re.compile(r"([0-9]+)([a-z]+)")
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
    if not isinstance(text, str):
        raise DurationError(f"duration must be a string, got {type(text).__name__}")
    s = text.strip().lower()
    if not s:
        raise DurationError("empty duration")

    pos = 0
    total = 0
    seen: set[str] = set()
    for match in _TOKEN.finditer(s):
        if match.start() != pos:
            raise DurationError(f"unexpected text at {pos}: {s[pos:match.start()]!r}")
        digits, unit = match.group(1), match.group(2)
        significant = digits.lstrip("0") or "0"
        if len(significant) > 12:
            raise DurationError(f"amount too long: {digits[:12]}...")
        amount = int(significant)
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
        ("2592000s", 2_592_000),
        ("0h30m", 1_800),
        ("01h", 3_600),
        ("30m1h", 5_400),
        ("0000000000001h", 3_600),
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
        ("-5m", "unexpected text at 0"),
        ("x1h", "unexpected text at 0"),
        ("1h30", "unexpected text at 2: '30'"),
        ("１h", "unexpected text"),
        ("9" * 5_000 + "s", "amount too long"),
        ("9" * 13 + "s", "amount too long"),
        ("9" * 12 + "s", "exceeds"),
        ("10x", "unknown unit 'x'"),
        ("10X", "unknown unit 'x'"),
        ("1hX", "unknown unit 'hx'"),
        ("  1h30", "unexpected text at 2: '30'"),
        ("5min", "unknown unit 'min'"),
        ("1hm", "unknown unit 'hm'"),
        ("1h 30m", "unexpected text at 2: ' '"),
        ("1h1h", "given twice"),
        ("1h30m1h", "given twice"),
        ("1H1h", "given twice"),
        ("0s", "must be positive"),
        ("0h0m", "must be positive"),
        ("31d", "exceeds"),
        ("30d1s", "exceeds"),
        ("2592001s", "exceeds"),
        ("1x1x", "unknown unit 'x'"),
        ("9999999999999x", "amount too long"),
        ("1h9999999999999h", "amount too long"),
        ("1h1h1x", "given twice"),
        ("0s!", "unexpected text at 2"),
        ("31d!", "unexpected text at 3"),
    ],
)
def test_rejects_invalid_durations(text, message):
    with pytest.raises(DurationError, match=re.escape(message)):
        parse_duration(text)


@pytest.mark.parametrize("value", [30, None, b"1h"])
def test_rejects_non_string_input(value):
    with pytest.raises(DurationError, match="must be a string"):
        parse_duration(value)
