# Test Strategy: `subject.py` (Tollgate duration parser)

**Scope:** `subject.py`, the whole file: `DurationError`, `Duration`, `parse_duration` (lines 1–62), plus the existing tests at lines 65–140 (`tests/test_duration.py` in the real project)
**Reviewed:** 2026-11-20

## Test Conventions

- **Framework:** pytest. Tests are plain functions named `test_*` with no classes.
- **Style:** table-driven with `@pytest.mark.parametrize`. Valid inputs are `(text, seconds)` pairs that assert on `.seconds`. Invalid inputs are `(text, message)` pairs that use `pytest.raises(DurationError, match=re.escape(message))`, so the message is matched as a literal substring.
- **Location:** `tests/test_duration.py`. There are no fixtures, conftest, mocks or property-testing library. The module is pure and has no I/O, so none are needed.
- **Existing coverage is strong.** Every branch in `parse_duration` (lines 31–61) is reached by at least one case. The tests also check the order of errors (for example, "too long" is raised before "unknown unit", "unknown unit" before a gap, and a trailing-text error before "positive" or "exceeds"). They cover the `MAX_SECONDS` boundary on both sides, leading-zero stripping, case folding, non-ASCII digits and the 5,000-digit input. The remaining gaps are in the `Duration`/`DurationError` types and a few partly asserted details, not in the parsing branches.

## Untested Paths Touched by the Change

- **G1** — `subject.py:14-15` — `DurationError` subclasses `ValueError`, so callers (such as config loaders) can catch it with a plain `except ValueError`. No test checks this. Every test catches `DurationError` itself, so changing the base class would break no test. — not covered
- **G2** — `subject.py:26-27` — `Duration.__repr__` returns `"Duration(<n>s)"`. This is the format that shows up in logs and assertion diffs. — not covered
- **G3** — `subject.py:18-20` — `@dataclass(frozen=True)` behaviour: assigning to `.seconds` raises `FrozenInstanceError`, two equal durations compare equal, and equal durations hash the same (needed if they're used as dict keys or set members). — not covered
- **G4** — `subject.py:18-20` vs `58-61` — `Duration(0)`, `Duration(-5)` and `Duration(MAX_SECONDS + 1)` can be built directly. The parser's invariant (`0 < seconds <= MAX_SECONDS`) is only enforced inside `parse_duration`. — not covered; **this is an ambiguity**: decide whether it's intended before writing a test (see Summary)
- **G5** — `subject.py:33` — `strip()` with whitespace other than the space character (`"\t1h\n"`, `"\u00a0"`-padded input, or input that is only `"\n"`). — partially covered: only ASCII spaces are tested (`"  90M  "`, `"   "`)
- **G6** — `subject.py:46` — the "too long" message gives the first 12 *significant* digits followed by `...`. — partially covered: tests only match `"amount too long"`, so nothing checks the truncation or that the shown digits start after the leading zeros
- **G7** — `subject.py:32` — the non-string message includes `type(text).__name__`. — partially covered: tests only match `"must be a string"`, so the type name (`int`, `NoneType`, `bytes`) isn't checked
- **G8** — `subject.py:56-57` — the trailing-text branch when no token matched at all (`"10"`, `"h10"`) should report position 0 and the whole string. — partially covered: those cases match `"unexpected text"` without the position or the quoted text, unlike `"1h30"`

## Recommended Tests

#### `DurationError` can be caught as `ValueError`

**Closes gaps:** G1
**Type:** unit
**Priority:** high
**File:** `tests/test_duration.py`
**What it verifies:** callers that catch `ValueError` still catch parse failures.
**Key cases:**
- `with pytest.raises(ValueError): parse_duration("10x")`
- `assert issubclass(DurationError, ValueError)`

**Setup needed:** none

#### `Duration` value semantics and repr

**Closes gaps:** G2, G3
**Type:** unit
**Priority:** medium
**File:** `tests/test_duration.py`
**What it verifies:** `Duration` is an immutable, hashable value with a stable repr.
**Key cases:**
- `repr(parse_duration("1h30m")) == "Duration(5400s)"`
- `parse_duration("90m") == parse_duration("1h30m")`, and both hash the same (`len({...}) == 1`)
- `d = parse_duration("1h"); d.seconds = 5` raises `dataclasses.FrozenInstanceError`

**Setup needed:** `import dataclasses`

#### Non-space whitespace is stripped

**Closes gaps:** G5
**Type:** unit
**Priority:** medium. Config files edited by hand often contain tabs, CRLF line endings or a non-breaking space pasted from docs.
**File:** `tests/test_duration.py`. Add rows to the existing parametrize tables.
**What it verifies:** the documented "ignores surrounding whitespace" covers all of `str.strip()`'s whitespace, and error positions are counted from the stripped text.
**Key cases:**
- valid: `("\t1h\r\n", 3_600)`, `("\u00a01h30m\u00a0", 5_400)`
- invalid: `("\n\t", "empty")`, `("\t1h30", "unexpected text at 2: '30'")`

**Setup needed:** none

#### Error messages carry the right details

**Closes gaps:** G6, G7, G8
**Type:** unit
**Priority:** low. These are messages that users read, not behaviour other code depends on. Add them as rows in the existing tables, where they cost almost nothing.
**File:** `tests/test_duration.py`
**What it verifies:** each message names the offending value or position precisely.
**Key cases:**
- `("000" + "1234567890123" + "s", "amount too long: 123456789012...")`: leading zeros are excluded and the digits are truncated at 12
- `("10", "unexpected text at 0: '10'")` and `("h10", "unexpected text at 0: 'h10'")`: replace the looser existing rows
- non-string: `parse_duration(30)` matches `"got int"`, `None` matches `"got NoneType"`, `b"1h"` matches `"got bytes"`. Change `test_rejects_non_string_input` to parametrize `(value, type_name)`.

**Setup needed:** none

#### (Conditional) Invalid `Duration` construction is rejected

**Closes gaps:** G4
**Type:** unit
**Priority:** medium, **if** the team decides `Duration` should enforce the invariant. In that case it's a code change (a `__post_init__` check) with tests attached, not just a test.
**File:** `tests/test_duration.py`
**What it verifies:** a `Duration` can never hold a value the parser would reject.
**Key cases:**
- `Duration(0)`, `Duration(-1)` and `Duration(MAX_SECONDS + 1)` raise `DurationError`
- `Duration(1)` and `Duration(MAX_SECONDS)` succeed

**Setup needed:** none. If the answer is "`Duration` is a plain value type", move G4 to What NOT to Test.

## What NOT to Test

- **More `MAX_SECONDS` boundaries in other units** (`"720h"`, `"43200m"`, `"999999999999d"`): every unit goes through the same `total += amount * _UNITS[unit]` line, and the boundary is already pinned with `30d`, `2592000s` and `2592001s`. Python integers can't overflow.
- **Every ordering of units:** `"30m1h"` and `"1d2h3m4s"` already show that order doesn't matter. All the permutations would add rows without testing any new path.
- **Unicode characters whose `lower()` turns into an ASCII unit letter:** none of `d`, `h`, `m` or `s` can be produced that way with `str.lower()` (the long s `ſ` only becomes `s` under `casefold()`). Non-ASCII digits are already rejected (`"１h"`).
- **`minutes` beyond the existing `90s → 1.5` case:** it's a single division.
- **Property-based roundtrip tests (Hypothesis):** a generated "format a random subset of units in random order, then parse" check would be thorough. But the project has no Hypothesis dependency, and the parametrized tables already cover each branch and the ordering rules. Revisit this if the grammar grows (for example, fractional amounts or `ms`).
- **Performance on very long input:** the 5,000-digit case already covers the realistic risk. The regex has no nested quantifiers, so catastrophic backtracking isn't possible.

## Coverage Gaps Beyond Current Scope

**1.** The scheduler code that reads Tollgate config files and calls `parse_duration` isn't in this repository. Check that it either catches `DurationError`/`ValueError` and reports the config key and file, or lets the error fail startup on purpose. A contract or integration test at that layer is worth more than any test left to add here.

## Summary

The existing suite already covers every branch of `parse_duration`, including the order in which errors are raised and both sides of the `MAX_SECONDS` limit. What's left is mostly about the types around the parser. The most valuable addition is the cheap check that `DurationError` can be caught as a `ValueError` (G1): it's a public contract that no current test protects. After that come `Duration`'s repr, equality and immutability (G2, G3) and stripping of whitespace other than spaces (G5), which is a realistic input from hand-edited config files. The main remaining risk is G4: `Duration` can be constructed directly with zero, negative or over-limit seconds, which bypasses the parser's checks. Someone needs to decide whether that's intended before writing any test for it. Everything else is a low-priority tightening of error messages, done as extra rows in the existing tables.
