# Test Strategy: nightly export scheduler (`next_run_utc`)

**Scope:** `subject.py`, lines 1–36 (module), plus its existing tests (lines 39–75, which live at `tests/test_schedule.py` in the real project)
**Reviewed:** 2026-11-20

## Test Conventions

- **Framework:** pytest. Tests are plain module-level `test_*` functions with no classes and no fixtures.
- **Style:** one call and one `assert` per test, inline literal datetimes, and a module constant `UTC = timezone.utc`. Error cases use `pytest.raises(ScheduleError)`.
- **Naming:** each test name describes a scenario, e.g. `test_already_ran_today_rolls_to_tomorrow`.
- **Infrastructure:** none. No mocks are needed because the function is pure and takes `now_utc` as a parameter. The only outside dependency is the IANA tz database (the system zoneinfo or the `tzdata` package), and only `"UTC"` and `"America/New_York"` are used today.
- **Suggested addition:** `@pytest.mark.parametrize` for the timezone tables. It's built into pytest, so nothing new to install.
- **What's covered today:** the naive-`now` rejection (line 25), the "zone not found" rejection (lines 29–30), both arms of `candidate <= local_now` (line 34) for UTC, and the rollover arm for one fixed winter offset. Every test uses a date with no DST transition, so `_round_trips` always returns `True` and line 20 never runs.

## Untested Paths Touched by the Change

- **G1** — subject.py:19-20, 33-34 — `_round_trips` returns `False` for today's candidate (`run_at` falls in a spring-forward gap, e.g. 02:30 in America/New_York on 2026-03-08), so it shifts +1h to 03:30 EDT. The useful case is `now` *inside the hour after the gap* (e.g. 07:15 UTC = 03:15 EDT). Without line 20, the 02:30 wall time compares as already passed and rolls to tomorrow. With line 20, it runs today at 07:30 UTC. — not covered. Note: for a 60-minute gap, 02:30 EST and 03:30 EDT are the same instant (07:30 UTC). So a test with `now` before the gap can't tell whether line 20 runs at all. Only the comparison case pins it.
- **G2** — subject.py:35 → 19-20 — the rollover branch where *tomorrow* is the gap day (now = 2026-03-07 12:00 UTC, `run_at` 02:30 NY, so the result is 2026-03-08 07:30 UTC) — not covered.
- **G3** — subject.py:20 — the +1h shift is hardcoded, so gaps that aren't 60 minutes are handled wrongly:
  - Australia/Lord_Howe has a 30-minute gap (02:00→02:30 on 2026-10-04). `run_at` 02:15 becomes 03:15 (+11) = 16:15 UTC. Interpreting it with the pre-transition offset gives 02:45 = 15:45 UTC.
  - Pacific/Apia skipped all of 2011-12-30. +1h is still inside the skipped day, the code doesn't check again, and it returns a nonexistent local time.
  - Not covered. **The contract is unclear:** decide whether a gap time should run at "same instant as pre-transition offset", "first valid minute after the gap", or "+1h". For Lord_Howe, the current code is *later* than it would be if line 20 were simply deleted.
- **G4** — subject.py:34 — **probable defect.** In the fall-back repeated hour, `candidate` and `local_now` share the same `ZoneInfo` instance. Python compares same-tzinfo datetimes by wall clock and ignores `fold`. Example: now = 2026-11-01 06:00 UTC = 01:00 EST (fold=1, second occurrence), `run_at` 01:30. The candidate is 01:30 EDT (fold=0) = 05:30 UTC. `01:30 <= 01:00` is False, so the function returns **05:30 UTC, half an hour before `now`**. A worker recomputing during 06:00–06:30 UTC (after a restart, schedule edit or new tenant) gets a time in the past, which likely means a duplicate export. — not covered.
- **G5** — subject.py:17-21, 33 — `run_at` that occurs twice on the fall-back day (01:30 NY on 2026-11-01, now = 2026-11-01 04:00 UTC). `fold=0` picks the first occurrence, 05:30 UTC. That pins the "run once, at the first occurrence" contract. — not covered.
- **G6** — subject.py:32-33 — the local date is *ahead* of the UTC date. Example: Asia/Tokyo, now = 2026-01-10 20:00 UTC = Jan 11 05:00 JST, `run_at` 02:30, so the next run is Jan 12 02:30 JST = 2026-01-11 17:30 UTC. Also untested: offsets that aren't whole hours (Asia/Kolkata +05:30, Asia/Kathmandu +05:45). — not covered (only UTC and the date-behind NY case are tested).
- **G7** — subject.py:25, 32 — `now_utc` is aware but not UTC (e.g. `timezone(timedelta(hours=5))`). It passes the guard and is converted by `astimezone` — not covered.
- **G8** — subject.py:27-30 — other `ZoneInfo` failure types are wrapped by the broad `except Exception`: `""` and `"../etc/passwd"` raise `ValueError`, and `None` raises `TypeError`. Partially covered: only the `ZoneInfoNotFoundError` arm (`"Mars/Olympus"`) is tested. The error message and `__cause__` chaining aren't checked either.
- **G9** — subject.py:36 — the return value's `tzinfo is timezone.utc`. Existing asserts compare by instant (`==` across timezones), so returning a NY-aware datetime would still pass them — not covered.
- **G10** — subject.py:18 — `run_at` that has its own `tzinfo` (silently replaced by `tz`) or `fold=1` (carried into `combine`, which selects the *second* occurrence on fall-back day) — not covered.

## Recommended Tests

#### Fall-back: recomputing in the second occurrence never returns a past time

**Closes gaps:** G4
**Type:** unit
**Priority:** high
**File:** `tests/test_schedule.py`
**What it verifies:** the result is always later than `now_utc`, even when `now` is in the repeated hour.

**Key cases:**
- `next_run_utc(datetime(2026,11,1,6,0,tzinfo=UTC), time(1,30), "America/New_York")` → must be `> now`. Today it returns `2026-11-01 05:30 UTC`. The expected value is `2026-11-02 06:30 UTC` (01:30 EST tomorrow), because today's 01:30 already happened at 05:30 UTC.
- now = 06:29 UTC (01:29 EST, fold=1) → same expectation.
- now = 05:29 UTC (01:29 EDT, first occurrence) → `2026-11-01 05:30 UTC`. This is a control case that should still pass after the fix.

**Setup needed:** none. Mark it `xfail(strict=True)` until line 34 compares instants, e.g. `candidate.astimezone(timezone.utc) <= now_utc`, or fix it in the same change.

#### Spring-forward gap: shift applies to today's and tomorrow's candidates

**Closes gaps:** G1, G2
**Type:** unit (parametrized)
**Priority:** high
**File:** `tests/test_schedule.py`
**What it verifies:** a `run_at` that doesn't exist that day resolves to the shifted time and isn't skipped.

**Key cases:**
- now = `2026-03-08 07:15 UTC` (03:15 EDT), `run_at` 02:30 NY → `2026-03-08 07:30 UTC`. This is the case that catches line 20 being removed; without it the result would roll to Mar 9.
- now = `2026-03-08 05:00 UTC` (00:00 EST) → `2026-03-08 07:30 UTC`.
- now = `2026-03-07 12:00 UTC` (rollover path at line 35) → `2026-03-08 07:30 UTC`.
- now = `2026-03-08 07:45 UTC` (03:45 EDT, after the shifted time) → `2026-03-09 06:30 UTC`.

**Setup needed:** none.

#### Ambiguous `run_at` on fall-back day uses the first occurrence

**Closes gaps:** G5, G10 (the `fold` part)
**Type:** unit
**Priority:** medium
**File:** `tests/test_schedule.py`
**What it verifies:** the documented once-per-night behaviour on the 25-hour day.

**Key cases:**
- now = `2026-11-01 04:00 UTC`, `run_at` 01:30 NY → `2026-11-01 05:30 UTC`.
- The same call with `time(1,30, fold=1)` → today returns `06:30 UTC`. Either assert that and document it, or normalize `run_at.replace(fold=0, tzinfo=None)` in the function and assert `05:30 UTC`. This depends on the product decision.

**Setup needed:** none.

#### Gaps that aren't 60 minutes

**Closes gaps:** G3
**Type:** unit
**Priority:** medium. Write it **after** deciding the contract.
**File:** `tests/test_schedule.py`
**What it verifies:** the gap shift is correct for 30-minute and multi-hour transitions.

**Key cases:**
- now = `2026-10-03 12:00 UTC`, `run_at` 02:15 `"Australia/Lord_Howe"`. Today the result is `2026-10-03 16:15 UTC` (03:15 +11). The pre-transition offset gives `15:45 UTC` (02:45 +11), and "first valid minute" gives `15:30 UTC`. Assert whichever is chosen.
- (Optional, historical) `"Pacific/Apia"`, now on 2011-12-29 with the next local day skipped. Assert the result is > now and lands on 2011-12-31 local.

**Setup needed:** none. The real fix is to stop hardcoding 1h, e.g. use the offset difference `tz.utcoffset(fold=1) - tz.utcoffset(fold=0)`, or step forward until the time round-trips.

#### Timezones east of UTC and with fractional offsets

**Closes gaps:** G6, G9
**Type:** unit (parametrized over `(now, run_at, tz, expected)`)
**Priority:** medium
**File:** `tests/test_schedule.py`
**What it verifies:** the local date (not the UTC date) drives "today", and the result is in UTC.

**Key cases:**
- `Asia/Tokyo`, now `2026-01-10 20:00 UTC`, 02:30 → `2026-01-11 17:30 UTC`.
- `Asia/Tokyo`, now `2026-01-10 16:00 UTC` (01:00 JST Jan 11), 02:30 → `2026-01-10 17:30 UTC`.
- `Asia/Kathmandu`, now `2026-01-10 00:00 UTC`, 02:30 → `2026-01-10 20:45 UTC`.
- In every row, also assert `result.tzinfo is timezone.utc`.

**Setup needed:** none.

#### Aware but non-UTC `now_utc`

**Closes gaps:** G7
**Type:** unit
**Priority:** low
**File:** `tests/test_schedule.py`
**What it verifies:** any aware input is treated as an instant.

**Key cases:**
- `datetime(2026,1,10,6,0,tzinfo=timezone(timedelta(hours=5)))` (= 01:00 UTC), 02:30 `"UTC"` → `2026-01-10 02:30 UTC`.

**Setup needed:** none.

#### Malformed timezone names are wrapped as `ScheduleError`

**Closes gaps:** G8
**Type:** unit (parametrized)
**Priority:** low
**File:** `tests/test_schedule.py`
**What it verifies:** every bad `tz_name` gives `ScheduleError` (still a `ValueError`) with the cause chained.

**Key cases:**
- `""`, `"../etc/passwd"` and `"America/New_York "` (trailing space) → `ScheduleError`, with `excinfo.value.__cause__` not `None`.
- `None` → `ScheduleError` (pins the current broad-catch behaviour).

**Setup needed:** none.

#### Invariant sweep across zones and the transition days

**Closes gaps:** G1, G2, G4, G5, G6 (as a safety net); none on its own
**Type:** property (use Hypothesis if the project accepts it; otherwise a parametrized sweep over every 15 minutes of 2026-03-07..09 and 2026-10-31..11-02 for NY, Lord_Howe, Tokyo, Kolkata)
**Priority:** medium
**File:** `tests/test_schedule.py`
**What it verifies:** for any aware `now` and `run_at`:
- (a) `now < result <= now + 26h`
- (b) `result.tzinfo is timezone.utc`
- (c) `result.astimezone(tz).time()` equals `run_at`, unless `run_at` doesn't exist on that local date
- (d) no two consecutive "runs" fall on the same local date: feed `result` back in as `now`.

**Key cases:** invariant (a) alone would have caught G4. Invariant (d) catches double runs on fall-back day.

**Setup needed:** `hypothesis` (with `st.timezones()`) if adopted. Otherwise none.

## What NOT to Test

- **`_round_trips` and `_localize` directly.** They're private helpers and are fully reachable through `next_run_utc`. Testing them directly would tie the tests to an implementation the G3 fix will probably replace.
- **`run_at` that carries its own `tzinfo`** (the rest of G10). `combine(..., tzinfo=tz)` silently overriding it is stdlib behaviour. If it matters, reject it in the function and add a one-line `pytest.raises` test then.
- **More plain winter/summer offset tests for other zones.** The NY winter test plus the parametrized table already cover the "fixed offset" logic. More rows wouldn't add anything new.
- **`ScheduleError` being a `ValueError` subclass.** It's a class declaration, and the G8 test covers it indirectly.
- **Leap seconds and dates near `datetime.max`.** Python doesn't model leap seconds, and a nightly export won't run near year 9999.

## Coverage Gaps Beyond Current Scope

**1.** **Dependency on the tz database.** On hosts without system zoneinfo (Windows, slim containers) and without the `tzdata` package, `ZoneInfo("America/New_York")` fails. The broad `except` then reports it as `unknown timezone`, which misleads operators. Pin `tzdata` as a dependency or add a startup check. The NY tests will fail confusingly on such CI images.

**2.** **The worker that uses `next_run_utc`.** It isn't in this repository. Whether G4 actually causes a duplicate export depends on whether the worker compares `result <= now` and fires immediately, and on when it recomputes (after each run, or also after restarts and schedule edits). An integration test should cover the worker's "recompute after restart during the repeated hour" path.

**3.** **Validating tenant timezones when they're saved.** Bad `tz_name`s are only caught when the schedule is computed. If tenant config isn't validated on save, a typo shows up as a failed nightly job rather than a form error.

## Summary

The highest-value test is the fall-back case (G4). By reading the code, `next_run_utc(2026-11-01 06:00 UTC, 01:30, "America/New_York")` returns 05:30 UTC, which is already in the past. Same-tzinfo datetime comparison ignores `fold`, and that would likely cause a duplicate export. I haven't run this; confirm it by running the test, and fix line 34 to compare in UTC.

The spring-forward tests (G1/G2) are the next most important. Any test where `now` is before the gap passes whether or not line 20 runs, so at least one test needs `now` in the hour just after the transition.

After this plan, the main remaining risk is G3. The hardcoded +1h is wrong for Lord_Howe's 30-minute shift and for skipped days. The open question is which time a gap `run_at` should map to, and that needs a product decision before the test can assert a value. The other open question is what `run_at` with `fold=1` should mean (G5/G10).
