# Test Strategy — Evaluation Criteria

Synthetic fixtures, each a single module with its existing tests below a
`--- tests (<real test path>) ---` marker. Five planted fixtures leave ONE
high-risk path untested while the tests cover the surrounding code. The
negative covers every risky path and leaves only trivial code untested. The
fixtures test SKILL.md's step 2 (survey existing coverage), step 3 (enumerate
untested paths as `**G<n>**` entries) and step 5 (prioritise by blast radius).

## Fixture → Expected Finding Map

| Fixture | Planted gap (category) | Expected Priority | Gap entry must name |
|---|---|---|---|
| tc-ts1-installment-split.py | `split_order`'s remainder loop that puts the leftover cents on the last installments; every test total divides evenly (money rounding) | high | the remainder / uneven-division path |
| tc-ts2-webhook-client.go | `Send`'s retry path: 429/5xx → `backoff` (incl. `Retry-After`) → next attempt, and returning the last error once `MaxAttempts` is used up; tests cover only 2xx and non-retryable 4xx (retry/error) | high | 429/5xx, backoff/Retry-After, or MaxAttempts exhaustion |
| tc-ts3-nightly-export-schedule.py | `_localize`'s branch for a local time that does not exist (spring-forward); tests use UTC and a January New York offset (timezone/DST) | high | DST / nonexistent local time / the round-trip check |
| tc-ts4-token-cache.ts | concurrent `get()` calls sharing the in-flight `refreshing` promise; every test awaits one call at a time (concurrency) | high | concurrent callers / in-flight refresh sharing |
| tc-ts5-order-sync.py | `iter_orders` following `next_cursor`; `FakeClient` always returns `next_cursor=None` (pagination) | high | multi-page / following the cursor |
| tc-ts6-duration-parser.py | **Negative.** Every error branch of `parse_duration` is in a parametrized reject table; only `__repr__` is untested | no high | must NOT list the unknown-unit branch as a gap |

tc-ts1, tc-ts4 and tc-ts6 also run `format_check` (test-strategy-format.bats).

## Notes

- **Gap patterns are anchored to gap entries.** Every pattern starts with
  `\*\*G[0-9]+\*\*`, so it matches only an enumerated gap line, never the
  fixture text or a passing mention elsewhere in the report. This is stricter
  than the other sets: a report that finds the path but mentions it only under
  Recommended Tests fails. SKILL.md makes the gap list mandatory and says every
  recommendation must trace to one, so that failure is real.
- **`field_match:Priority=high` is weak on its own.** It passes on any
  recommendation. The gap pattern is what ties the finding to the planted path.
- **Secondary gaps exist and are fine.** For example, ts2's transport-error
  return, ts4's rejected-refresh path and ts1's `schedule_summary` on an empty
  plan are also untested. The patterns avoid words those gaps would use (e.g.
  ts2 does not key on "retry" alone, because "transport error is not retried"
  is a different gap).
- **tc-ts6's `no_field:Priority=high`** rests on SKILL.md step 5: high value
  means "high blast radius, no existing coverage". Nothing in ts6 meets both,
  so a high-priority test there is either a covered path or trivial code. This
  is the check most likely to move on the first real run. A model may call a
  property test on the parser "high" even though the table already covers it.
  If that happens, decide whether the check or the rubric reading is wrong
  before loosening it.
- The Go and TS fixtures put tests in the same file as the code under test.
  The marker comment names the real test file (`client_test.go`,
  `tokenCache.test.ts`). The runner prompt says so and says no other files
  exist.
- Fixture files carry no comments naming the gap.
