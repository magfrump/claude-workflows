# Test Strategy: Fernbrook installment splitter (`subject.py`)

**Scope:** `subject.py`, the whole module: `Installment`, `InstallmentError`, `_add_months`, `split_order`, `schedule_summary`. The existing tests in the same file live at `tests/test_installments.py` in the real project.
**Reviewed:** 2026-11-19

## Test Conventions

- **Framework:** pytest. Tests are plain `test_*` functions with direct asserts, and `@pytest.mark.parametrize` is used for the rejection cases.
- **Location:** `tests/test_installments.py`, one flat module with no classes.
- **Naming:** descriptive sentence-style names, e.g. `test_due_dates_roll_over_the_year_and_clamp_to_28th`.
- **Infrastructure:** none. There are no fixtures, factories or mocks, and none are needed because everything is pure and deterministic and takes `first_due` as an argument, so there's no clock to mock. Hypothesis isn't visibly a dependency, so the invariant checks below use a parametrized table. Use Hypothesis only if the project already has it.
- **Coverage by function:**
  - `split_order`: tested for an even split (12,000 / 3), a single installment, 0 and negative totals, and counts of 0 and 13.
  - `_add_months`: tested once, starting from Nov 30 across a year rollover.
  - `schedule_summary`: tested once, with a whole-dollar total.

## Untested Paths Touched by the Change

- **G1** — `subject.py:35-36` — remainder distribution loop body (`remainder > 0`), where the extra cents go to the *last* installments — not covered. All three split tests use totals that divide evenly (12,000/3, 4,999/1, 6,000/4), so the loop never runs. This is the highest-risk logic in the file: a mistake here produces a wrong amount without raising any error.
- **G2** — `subject.py:33-36` — `total_cents < count` (e.g. `split_order(5, 12, ...)`) makes `base == 0`, so some installments are 0 cents — not covered. **Ambiguity:** nothing rejects a $0.00 installment. Confirm whether checkout should allow that before writing a test that locks it in.
- **G3** — `subject.py:30` — upper accept boundary `count == MAX_INSTALLMENTS` (12) — not covered. The lower accept boundary (1) and both reject boundaries (0, 13) are covered.
- **G4** — `subject.py:28` — accept boundary `total_cents == 1`, the smallest valid total — not covered. Only the reject side (0, −500) is tested.
- **G5** — `subject.py:21-24` — `_add_months` when `start.day <= 28`: the day should be kept in every following month — partially covered. Only `plan[0].due` is checked, in the summary test. No test checks that later due dates keep day 15.
- **G6** — `subject.py:22-23` — `_add_months` across a full 12-month span starting in December, where month index 11 wraps to the next year — not covered. Only a 4-month span starting in November is tested.
- **G7** — `subject.py:46` — `schedule_summary` with a total that has non-zero cents (e.g. 4,999 → `"49.99"`), which goes through float division and `.2f` rounding — not covered. Only `120.00` is tested.
- **G8** — `subject.py:46` — `schedule_summary([])`: `plan[0]` raises a bare `IndexError`, not `InstallmentError` — not covered. **Ambiguity:** `split_order` can never return an empty list, but `schedule_summary` is public. Decide whether an empty plan should be a defined error.
- **G9** — `subject.py:27-33` — non-`int` inputs are not validated. A float such as `split_order(100.5, 2, d)` makes `divmod` return floats, so `amount_cents` holds floats. `count=True` passes the range check as 1. — not covered. **Ambiguity:** confirm whether callers are trusted to pass ints.

## Recommended Tests

#### `test_remainder_cents_go_to_last_installments`

**Closes gaps:** G1
**Type:** unit (parametrized)
**Priority:** high
**File:** `tests/test_installments.py`
**What it verifies:** Leftover cents are spread one per installment, starting from the last one, and nothing is lost.
**Key cases:**
- `split_order(10_000, 3, date(2026, 1, 15))` → `[3_333, 3_333, 3_334]`
- `split_order(10_001, 3, ...)` → `[3_333, 3_334, 3_334]` (remainder 2)
- `split_order(100, 12, ...)` → eight `8`s followed by four `9`s (remainder 4)
- `split_order(4_999, 2, ...)` → `[2_499, 2_500]`

**Setup needed:** none

#### `test_split_preserves_total_and_shape` (invariant table)

**Closes gaps:** G1, G3, G5, G6
**Type:** unit, property-style (parametrize over a grid; or Hypothesis if already available)
**Priority:** high
**File:** `tests/test_installments.py`
**What it verifies:** Every valid `(total, count, first_due)` gives a plan that meets five conditions:
- `sum(amount_cents) == total`
- `len == count`
- `number` runs from 1 to `count`
- the largest and smallest amounts differ by at most 1, and amounts never decrease
- consecutive due dates are exactly one calendar month apart, with day `min(first_due.day, 28)`

**Key cases:**
- totals `{1, 7, 9_999, 12_000, 1_000_003}` × counts `{1, 2, 3, 7, 11, 12}` × first_due `{date(2026,1,15), date(2026,12,31), date(2028,1,29)}` (the last one is a leap year)
- explicit check: `split_order(12_000, 12, date(2026, 12, 15))` gives due dates from `2026-12-15` to `2027-11-15`, and the last one is `date(2027, 11, 15)`
- no due date ever has `day > 28` (so Feb 29/30/31 can never be produced)

**Setup needed:** none

#### `test_count_at_max_is_accepted` and `test_total_of_one_cent_is_accepted`

**Closes gaps:** G3, G4
**Type:** unit
**Priority:** medium. These are quick to write, and an off-by-one in the range check would block a supported checkout option.
**File:** `tests/test_installments.py`
**What it verifies:** The accept edges of both guards work.
**Key cases:**
- `split_order(12_000, MAX_INSTALLMENTS, date(2026, 1, 15))` returns 12 installments of 1,000
- `split_order(1, 1, date(2026, 1, 1))` returns `[Installment(1, date(2026,1,1), 1)]`

**Setup needed:** none. You could add `12` and `1` to the existing parametrize lists as "accepted" counterparts, but separate tests read more clearly.

#### `test_total_smaller_than_count_behavior`

**Closes gaps:** G2
**Type:** unit
**Priority:** medium, but write it **after** the product decision.
**File:** `tests/test_installments.py`
**What it verifies:** Whatever the confirmed behavior is when there are fewer cents than installments.
**Key cases:**
- If 0-cent installments are allowed: `split_order(5, 12, d)` gives seven `0`s followed by five `1`s, summing to 5.
- If they are not: `split_order(5, 12, d)` raises `InstallmentError`. This needs a code change, `total_cents < count` → error.

**Setup needed:** none

#### `test_schedule_summary_formats_cents`

**Closes gaps:** G7
**Type:** unit (parametrized)
**Priority:** medium. This string is shown to customers.
**File:** `tests/test_installments.py`
**What it verifies:** The summary shows cents correctly and uses the first installment's (clamped) due date.
**Key cases:**
- `split_order(4_999, 2, date(2026, 3, 1))` → `"2 payments, 49.99 total, first due 2026-03-01"`
- total `1` → `"1 payments, 0.01 total, ..."`. This also shows that a single payment reads "1 payments". Flag the grammar, but don't assert a fix nobody has asked for.
- total `100_000_005` → `"... 1000000.05 total ..."`, a large value to check float formatting holds up
- first_due `date(2026, 1, 31)` → `"first due 2026-01-28"`, confirming the summary reports the clamped date

**Setup needed:** none

#### `test_schedule_summary_empty_plan`

**Closes gaps:** G8
**Type:** unit
**Priority:** low. `split_order` can't produce an empty plan, so this only matters if callers build plans some other way.
**File:** `tests/test_installments.py`
**What it verifies:** What happens with an empty plan: either `pytest.raises(IndexError)` to document the current behavior, or `InstallmentError` if the team decides that's the contract.
**Key cases:** `schedule_summary([])`
**Setup needed:** none

## What NOT to Test

- **`Installment` dataclass and `frozen=True`:** this is standard-library behavior. A test that a frozen dataclass rejects assignment only tests Python.
- **`InstallmentError` subclassing `ValueError`:** trivial. Add one `pytest.raises(ValueError)` only if callers are known to catch `ValueError`.
- **Exact error message text** (`"total must be positive"`, `"count must be between 1 and 12"`): brittle, and no caller depends on it. The existing tests rightly check only the exception type.
- **`_add_months` on its own:** it's private, and the invariant table covers it fully through `split_order`. Testing it directly would tie the tests to the implementation.
- **G9 (non-int inputs):** deferred, not dropped. Leave it untested until someone decides whether the function should validate types. Today the behavior is accidental (float amounts, `True` treated as 1), and a test would lock that in. If validation gets added, add `split_order(100.5, 2, d)` and `split_order(100, True, d)` → `InstallmentError`.

## Coverage Gaps Beyond Current Scope

**1.** The repository has no checkout caller of `split_order`, so I couldn't check how `InstallmentError` reaches the user (e.g. a 400 with a message vs. a 500). That integration point needs its own test where the caller lives.

**2.** Clamping to the 28th applies to the **first** installment too. A customer who picks the 30th is charged on the 28th, *before* the date they chose. The existing test `test_due_dates_roll_over_the_year_and_clamp_to_28th` treats this as intended, but it should get explicit product sign-off. Charging early is a different kind of risk from charging late.

## Summary

The most valuable test to add is **`test_remainder_cents_go_to_last_installments`**, together with the sum-preserving invariant table. Every existing split test uses a total that divides evenly, so the remainder loop (`subject.py:35-36`) has never run under test. A bug there would charge customers the wrong amount without raising any error. After this plan, the main remaining risk is in behavior nobody has decided on yet, not in untested code. That covers three things:
- 0-cent installments when `total_cents < count` (G2)
- `schedule_summary([])` raising `IndexError` (G8)
- floats and bools not being validated (G9)

Two questions for the product owner: whether a $0.00 installment is acceptable, and whether clamping the *first* due date earlier than the date the customer picked is intended.
