# Test Strategy: `parse_duration` (Tollgate duration parser)

**Scope:** `subject.py`, the whole module (lines 1–54) and its existing tests (lines 57–101, which live at `tests/test_duration.py` in the real project)
**Reviewed:** 2026-11-20

## Test Conventions

- **Framework:** pytest. Tests are table-driven with `@pytest.mark.parametrize`: one table for valid inputs (`text, seconds`) and one for invalid inputs (`text, message`).
- **Error assertions:** `pytest.raises(DurationError, match=<substring>)`. They only match a short prefix such as `"unexpected text"` or `"exceeds"`, so the position and snippet in the message are never checked.
- **File:** `tests/test_duration.py`. There are no fixtures, mocks or helpers, and none are needed because the code is pure.
- **Recommendation:** add rows to the two existing tables wherever possible. Write a new test function only when the assertion has a different shape, such as a different exception type or an exact message.

The existing tests are good. Every `raise` on lines 31–53 is reached at least once, and both edges of the `MAX_SECONDS` limit are tested (`30d` passes, `30d1s` and `31d` fail). The gaps below are about inputs that get through, or fail with the wrong exception, more than about lines that never run.

## Untested Paths Touched by the Change

- **G1**: `subject.py:39`. `int(match.group(1))` with a digit run longer than Python's int-parsing limit (4300 digits by default on 3.11+). This raises a plain `ValueError`, not `DurationError`, so callers that catch `DurationError` miss it. Not covered.
- **G2**: `subject.py:29`. Input that isn't a `str`. If YAML or TOML gives an `int` (e.g. `timeout: 30`) or `None`, `.strip()` raises `AttributeError` and never reaches the `DurationError` contract. Not covered. **Ambiguity:** should a bare int count as seconds, or should it be rejected with `DurationError`?
- **G3**: `subject.py:8,39`. `\d` on a `str` pattern matches all Unicode decimal digits, and `int()` accepts them too, so `"１h"` (full-width) and `"١٢m"` (Arabic-Indic) are silently accepted. Not covered. **Ambiguity:** this is probably unintended for config files, and the fix would be `[0-9]` or `re.ASCII`.
- **G4**: `subject.py:37-38`. Text before the first token, e.g. a leading sign (`"-5m"`, `"+5m"`) or a letter (`"x1h"`). This raises at line 38 with `pos=0`. Not covered: the only existing line-38 case is `"1h 30m"`, which has junk in the middle. The `-5m` case matters because it is how a negative duration would get in.
- **G5**: `subject.py:48-49`. Trailing junk *after a valid token* (`"1h30"`, `"1h30m5"`), where `pos > 0`. Partly covered: `"10"` and `"h10"` reach line 49, but only with `pos == 0` and no match at all. The common user mistake `"1h30"` (meaning 1h30m) is not tested.
- **G6**: `subject.py:42-45`. A zero component inside a positive total (`"0h30m"` → 1800) and leading zeros (`"01h"` → 3600). Both are accepted because there is no per-token zero check. Not covered: the tests only check zero *totals*.
- **G7**: `subject.py:36-46`. Units in a non-canonical order (`"30m1h"`, `"4s3m2h1d"`). These are accepted, since nothing checks order. Not covered. **Ambiguity:** confirm that any order is intended.
- **G8**: `subject.py:42-43`. A duplicate unit that isn't adjacent (`"1h30m1h"`) or differs only by case (`"1H1h"`, which matches only after `.lower()`). Partly covered: only the adjacent `"1h1h"` is tested.
- **G9**: `subject.py:38,41,49`. The content of error messages (the position index and the `repr` snippet). Not covered, because the `match=` checks only the prefix. One quirk: positions refer to the stripped, lowercased string, not to what the user typed.
- **G10**: `subject.py:24-25`. `Duration.__repr__` output. Not covered.

## Recommended Tests

#### Huge digit runs raise `DurationError`, not a bare `ValueError`

**Closes gaps:** G1
**Type:** unit
**Priority:** high
**File:** `tests/test_duration.py`
**What it verifies:** every rejection keeps to the `DurationError` contract, including input that hits the interpreter's int-conversion limit.
**Key cases:**
- `parse_duration("9" * 5000 + "s")` → `pytest.raises(DurationError)`. This **fails today** with a plain `ValueError`. The fix is to catch `ValueError` around `int()` on line 39, or to reject digit runs above a sane length.
- `parse_duration("99999999999999999999s")` (20 digits) → `DurationError, match="exceeds"`. This should already pass; it confirms the code handles big ints that are still under the limit.

**Setup needed:** none. Use `pytest.raises(DurationError)` without a `match`, because the point is the exception type.

#### Non-string input has a defined behaviour

**Closes gaps:** G2
**Type:** unit
**Priority:** high (config loaders really do produce ints)
**File:** `tests/test_duration.py`
**What it verifies:** `parse_duration(30)` and `parse_duration(None)` fail with `DurationError`, or `30` means 30 seconds, whichever the owners decide.
**Key cases:**
- `parse_duration(30)` → `DurationError` (or `Duration(30)` if bare ints should be allowed). It currently raises `AttributeError`.
- `parse_duration(None)` → `DurationError`. It currently raises `AttributeError`.

**Setup needed:** the owners need to settle the ambiguity before this test can be written. If the type hint is the contract and callers should be fixed instead, move this to "What NOT to Test" and add a test where the config is loaded.

#### Only ASCII digits are accepted

**Closes gaps:** G3
**Type:** unit
**Priority:** medium. A silently wrong answer is unlikely, but the cost is three table rows.
**File:** `tests/test_duration.py`, as rows in `test_rejects_invalid_durations`
**What it verifies:** amounts must be ASCII `0-9`.
**Key cases:**
- `("１h", "unexpected text")`: full-width 1. This **fails today**, because the input parses as 3600.
- `("١٢m", "unexpected text")`: Arabic-Indic 12. Also **fails today**.

**Setup needed:** change `_TOKEN` to `re.compile(r"([0-9]+)([a-z]+)")` or add `re.ASCII`. If Unicode digits are meant to be accepted, add these to the valid table instead, so the behaviour is written down.

#### Rejecting leading signs and junk, and trailing digits after a token

**Closes gaps:** G4, G5
**Type:** unit
**Priority:** high. `"-5m"` and `"1h30"` are realistic config typos, and a negative duration getting through would have a large impact.
**File:** `tests/test_duration.py`, as rows in `test_rejects_invalid_durations`
**Key cases:**
- `("-5m", "unexpected text")`
- `("+5m", "unexpected text")`
- `("x1h", "unexpected text")`
- `("1h30", "unexpected text")`
- `("1h30m5", "unexpected text")`

**Setup needed:** none.

#### Accepted-but-unusual forms are pinned down

**Closes gaps:** G6, G7
**Type:** unit
**Priority:** medium. These rows document current behaviour so a later "tightening" change breaks them on purpose, not by accident.
**File:** `tests/test_duration.py`, as rows in `test_parses_valid_durations`
**Key cases:**
- `("0h30m", 1_800)`
- `("01h", 3_600)`
- `("30m1h", 5_400)`
- `("4s3m2h1d", 93_784)`. This has the same total as the existing `"1d2h3m4s"` row, which makes it clear that order doesn't matter.

**Setup needed:** confirm G7 with the owners first. If canonical order should be enforced, move the order rows to the invalid table.

#### Duplicate detection: non-adjacent and case-folded

**Closes gaps:** G8
**Type:** unit
**Priority:** low to medium (two cheap rows)
**File:** `tests/test_duration.py`, as rows in `test_rejects_invalid_durations`
**Key cases:**
- `("1h30m1h", "given twice")`
- `("1H1h", "given twice")`

#### Exact error messages for the position-reporting errors

**Closes gaps:** G9
**Type:** unit
**Priority:** low to medium. Users read these messages when fixing config files.
**File:** `tests/test_duration.py`, as a new parametrized test that passes `re.escape`'d full messages to `match=`
**Key cases:**
- `"1h 30m"` → `"unexpected text at 2: ' '"`
- `"1h30"` → `"unexpected text at 2: '30'"`
- `"  10X "` → `"unknown unit 'x'"`. The unit is shown lowercased, which pins down that messages describe the normalised string.

**Setup needed:** none. Keep this to these three cases so changes to message wording break only a small, clearly named test.

## What NOT to Test

- **`Duration.__repr__` (G10):** a one-line f-string with no logic. If it breaks, the only effect is uglier log output. Skip it, unless something downstream parses the repr.
- **`Duration` being frozen and its equality/hashing:** these come from `@dataclass(frozen=True)`, so a test would be testing the standard library.
- **`minutes` beyond the existing case:** a single division, and `90s → 1.5` already covers it.
- **More `MAX_SECONDS` boundary variants** (`"720h"`, `"2592001s"`): the boundary is checked on the total, after summing, so unit choice doesn't matter, and `30d` / `30d1s` already cover both edges.
- **Property-based testing (Hypothesis):** the main invariant ("the sum of distinct unit tokens equals `.seconds`") is real, but the project has no Hypothesis dependency and the explicit table already covers the grammar well. It isn't worth adding a dependency for.
- **Whitespace variants** (tabs, newlines, Unicode spaces around the value): `str.strip()` handles them, and `"  90M  "` already covers the strip path.

## Coverage Gaps Beyond Current Scope

**1.** The code that loads config and calls `parse_duration` is not in this repository. Whether it passes raw YAML/TOML values, which can be ints or `None` (G2), and whether it catches `DurationError` or `ValueError` (G1), should be checked with an integration test at that call site.

**2.** Nothing here says how the Tollgate scheduler uses `Duration.seconds` (as a timeout, an interval or a deadline), or whether the 30-day cap matches what the scheduler can actually handle. A contract test between the parser's `MAX_SECONDS` and the scheduler's limits would catch drift.

## Summary

The existing tests reach every `raise` in `parse_duration` and cover the `MAX_SECONDS` boundary. The remaining risk is in inputs that get through or fail the wrong way. The highest-value test is the oversized-digit-run case (G1). It fails today, because `int()` raises a bare `ValueError` that callers catching `DurationError` won't handle, and it costs one line. Close behind it are rows for leading signs and trailing digits (`"-5m"`, `"1h30"`; G4/G5) and the Unicode-digit check (G3), which is also a current bug if ASCII-only input is intended. Three questions came out of the gap list and should be answered before the related tests are written:
- Should non-`str` input (G2) be coerced or rejected?
- Should units be allowed in any order (G7)?
- Should Unicode digits be accepted (G3)?

Once the plan is done, the main remaining risk is outside this module: how the config loader calls the parser and handles its errors.
