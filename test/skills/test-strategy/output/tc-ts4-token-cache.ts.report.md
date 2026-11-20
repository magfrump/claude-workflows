# Test Strategy: TokenCache (Larkspur inventory API OAuth token cache)

**Scope:** `subject.ts`, the whole file: `TokenCache` (lines 1–46) and its existing tests (lines 48–88, which live in `tokenCache.test.ts` in the real project)
**Reviewed:** 2026-11-20

## Test Conventions

- **Framework:** Vitest (`describe` / `it` / `expect` / `vi`). Tests live in `tokenCache.test.ts` next to the module.
- **Style:** Each `it` builds its own cache. There are no shared fixtures or `beforeEach` blocks. Test names are short plain-English sentences ("invalidate forces a refetch").
- **Test doubles:**
  - `fetchToken` is a `vi.fn()` using `mockResolvedValue` / `mockResolvedValueOnce`.
  - Time is controlled by passing a clock closure (`() => clock`) as the `now` argument. Fake timers are not used.
- **No other infrastructure:** no test config, helpers or factories. Everything below is unit tests that use only those two seams: the `fetchToken` stub and the injected clock. For the concurrency tests I add one small "deferred promise" helper, defined inline in the test file.

## Untested Paths Touched by the Change

There is no diff, so this list covers every path in the module that the existing four tests don't reach.

- **G1** — `subject.ts:29-39`: two callers call `get()` while a refresh is in flight. The second caller should skip the `refreshing === null` branch and await the shared promise, giving one `fetchToken` call and the same value for both. **Not covered.** Every existing test awaits each `get()` before the next, so the "join the in-flight refresh" path (the `false` arm of line 29) never runs.
- **G2** — `subject.ts:30-37`: `fetchToken()` rejects (non-200, timeout, connection refused). The rejection should reach the caller, `.then` should not run (so `current` stays as it was), and `.finally` should reset `refreshing` to `null` so the next `get()` tries again. **Not covered.** All stubs resolve.
- **G3** — `subject.ts:30-39`: `fetchToken()` rejects while several callers are waiting. Every caller should get the same error from one fetch, and the next call should start a new fetch. **Not covered.** This is G1 and G2 combined.
- **G4** — `subject.ts:22`: the exact boundary of the skew check (`expiresAt - SKEW_MS > now`, a strict `>`). With `expiresAt = 100_000`, `now = 69_999` should count as fresh and `now = 70_000` as stale. **Partially covered.** The existing skew test only checks `now = 75_000`, which is 5 s inside the window. An off-by-one (`>=`), a wrong sign or a changed `SKEW_MS` would still pass.
- **G5** — `subject.ts:26-27`: the cached-return path gives back `this.current.value`. **Partially covered.** "reuses a fresh token" checks the fetch count but never checks what the second `get()` returns.
- **G6** — `subject.ts:43-45` together with `subject.ts:31-33`: `invalidate()` is called while a refresh is in flight. `invalidate` only clears `current`, not `refreshing`. The in-flight `.then` then writes its token back into `current`, and a `get()` made after `invalidate()` joins the old refresh instead of starting a new one. **Not covered.** This is an ambiguity: the existing test name says "invalidate forces a refetch", which does not hold in this case. The intended contract needs confirming (see the Summary).
- **G7** — `subject.ts:22, 26, 30-33`: `fetchToken` returns a token that is already inside the skew window, for example `expiresAt = now + 10_000`, or a malformed `expiresAt` such as `NaN`, `undefined` or epoch seconds instead of ms. `get()` still returns that token, but it is never fresh, so every later `get()` calls the token endpoint again. **Not covered.** This is a silent failure mode: callers see working tokens while the token endpoint gets one request per API call.
- **G8** — `subject.ts:18, 22`: the default clock `Date.now`. If it were mistakenly captured as a value instead of a function, the clock would freeze and the cache would never refresh. **Not covered.** Every test injects a clock.

## Recommended Tests

All tests below go in `tokenCache.test.ts`, inside the existing `describe("TokenCache", …)` block. The concurrency tests use this inline helper:

```ts
function deferred<T>() {
  let resolve!: (v: T) => void, reject!: (e: unknown) => void;
  const promise = new Promise<T>((res, rej) => { resolve = res; reject = rej; });
  return { promise, resolve, reject };
}
```

#### Concurrent callers share a single in-flight refresh

**Closes gaps:** G1
**Type:** unit
**Priority:** high
**File:** `tokenCache.test.ts`
**What it verifies:** while a fetch is pending, any number of `get()` calls produce exactly one `fetchToken` call, and all of them resolve to that token.
**Key cases:**
- `const d = deferred<Token>()` and `fetchToken = vi.fn(() => d.promise)`, clock `() => 0`. Call `const p1 = cache.get(); const p2 = cache.get(); const p3 = cache.get();` without awaiting. Then `expect(fetchToken).toHaveBeenCalledTimes(1)`. This check is valid because an `async` function body runs synchronously up to its first `await`, so `refreshing` is already set before `p2` starts.
- `d.resolve({ value: "a", expiresAt: 1_000_000 })`. Then `await Promise.all([p1, p2, p3])` should equal `["a", "a", "a"]`, and the fetch count should still be 1.
- After the refresh settles, `await cache.get()` returns `"a"` with no new fetch. This shows the shared path filled `current`.

**Setup needed:** the `deferred` helper.

#### A failed fetch propagates and the next get() retries

**Closes gaps:** G2
**Type:** unit
**Priority:** high
**File:** `tokenCache.test.ts`
**What it verifies:** a rejected `fetchToken` rejects `get()`, and it does not leave `refreshing` stuck on a rejected promise, which would make the cache fail forever.
**Key cases:**
- `fetchToken.mockRejectedValueOnce(new Error("token endpoint 503")).mockResolvedValueOnce({ value: "a", expiresAt: 1_000_000 })`, clock `() => 0`.
  - `await expect(cache.get()).rejects.toThrow("token endpoint 503")`.
  - Then `expect(await cache.get()).toBe("a")` and the fetch count is 2.
- Failure after a good token has expired: first fetch returns `{ value: "a", expiresAt: 100_000 }`, then move the clock to `75_000`.
  - The next fetch rejects, so `get()` rejects. The stale `"a"` is **not** served.
  - The fetch after that resolves `{ value: "b", … }`, and `get()` returns `"b"`.

**Setup needed:** none beyond `vi.fn()`.

#### Concurrent callers all receive the same refresh failure

**Closes gaps:** G3
**Type:** unit
**Priority:** medium
**File:** `tokenCache.test.ts`
**What it verifies:** a single failed fetch rejects every waiting caller, and recovery afterwards takes exactly one new fetch.
**Key cases:**
- Use a deferred stub. Start `p1 = cache.get(); p2 = cache.get();` and call `d.reject(new Error("ECONNREFUSED"))`.
  - Both `p1` and `p2` reject with `ECONNREFUSED`, and `fetchToken` was called once.
  - Attach `expect(...).rejects` to both promises before rejecting, to avoid unhandled-rejection warnings.
- Make the stub resolve next. `await cache.get()` returns the new token and the fetch count is 2.

**Setup needed:** the `deferred` helper.

#### Skew boundary is exact and the cached value is returned

**Closes gaps:** G4, G5
**Type:** unit (table-driven with `it.each` is fine)
**Priority:** medium
**File:** `tokenCache.test.ts`
**What it verifies:** a token is reused only while `now < expiresAt - 30_000`, and the reuse path returns the cached token's value.
**Key cases:**
- Stub returns `{ value: "a", expiresAt: 100_000 }` and then `{ value: "b", expiresAt: 500_000 }`. Start with clock `0`; `get()` returns `"a"`.
- Clock `69_999`: `get()` returns `"a"` (checks G5's return value) and the fetch count is still 1.
- Clock `70_000`: `get()` returns `"b"` and the fetch count is 2. This is exactly `expiresAt - SKEW_MS`, which is stale because the check is strict `>`.
- Optionally, strengthen the existing "reuses a fresh token" test with `expect(await cache.get()).toBe("a")` on the second call. That costs one line.

**Setup needed:** mutable `clock` variable, same as the existing skew test.

#### A token that is already near expiry triggers a refetch on every call (characterization)

**Closes gaps:** G7
**Type:** unit
**Priority:** medium
**File:** `tokenCache.test.ts`
**What it verifies:** it pins down current behaviour when the token server, or a broken `fetchToken`, returns a token with no usable lifetime, so any future change here is deliberate.
**Key cases:**
- Clock `0`, stub always returns `{ value: "a", expiresAt: 10_000 }`, which is inside the 30 s skew. Three sequential `get()` calls each return `"a"` and `fetchToken` is called 3 times.
- `expiresAt: NaN` behaves the same way: the value is returned and the endpoint is fetched every time.
- If the team decides this should instead throw or log (see Summary), change these assertions to that contract.

**Setup needed:** none.

#### invalidate() during an in-flight refresh

**Closes gaps:** G6
**Type:** unit
**Priority:** medium. Confirm the contract first.
**File:** `tokenCache.test.ts`
**What it verifies:** what `invalidate()` guarantees when a fetch is already pending.
**Key cases:**
- Deferred stub for the first fetch. Run `p1 = cache.get()`, then `cache.invalidate()`, then `p2 = cache.get()`.
  - **Current behaviour:** `fetchToken` is called once, `p2` joins `p1`, and after resolving `{ value: "a", … }` both return `"a"` and `current` is `"a"`.
  - **If "invalidate always forces a refetch" is the intended contract:** `p2` should start a second fetch. That would need `invalidate()` to clear or generation-tag `refreshing`, and the `.then` to skip writing into `current` when the generation is out of date.
- Either way, after `p1` settles and `invalidate()` is called again, the next `get()` must call `fetchToken` again. This part is unambiguous.

**Setup needed:** the `deferred` helper.

#### Default clock reads the real time on each call

**Closes gaps:** G8
**Type:** unit
**Priority:** low
**File:** `tokenCache.test.ts`
**What it verifies:** when no clock is injected, the cache follows wall-clock time.
**Key cases:**
- `vi.useFakeTimers(); vi.setSystemTime(0)`. Create `new TokenCache(fetchToken)` with a stub returning `expiresAt: 100_000`, then `"b"`. `get()` returns `"a"`.
- `vi.setSystemTime(70_000)`. `get()` returns `"b"`.
- `vi.useRealTimers()` in a `finally` or `afterEach`.

**Setup needed:** Vitest fake timers. This is the only test that needs them; the others keep the existing injected-clock style.

## What NOT to Test

- **`fetchToken` throwing synchronously instead of returning a rejected promise (line 30).** `FetchToken` is typed `() => Promise<Token>`, and any `async` implementation can only reject. If it did throw synchronously, `get()` (which is `async`) would still reject and `refreshing` would stay `null`, so it recovers anyway. A test would only cover a type violation.
- **`SKEW_MS` as a separate constant.** It isn't exported. The boundary test (G4) already pins its value through behaviour. Exporting it just to assert `30_000` would test an implementation detail.
- **The `t is Token` type guard on `isFresh`.** This is checked at compile time. It is private and fully exercised through `get()`.
- **The value of `current` after a failed refresh.** It keeps the old, expired token. That is invisible to callers, because the token is stale by definition and `invalidate`/`get` treat it the same as `null`. The G2 case "stale token is not served" covers the only part that matters.
- **Tests that read private fields** (`refreshing`, `current`) through casts. Every behaviour above can be seen through `get()` and the `fetchToken` call count. Keep it that way so refactors don't break the tests.

## Coverage Gaps Beyond Current Scope

**1.** **The real `FetchToken` implementation**, which is not in this repository. It turns the OAuth response into `expiresAt`. A seconds-vs-ms mix-up, or using `expires_in` without adding `Date.now()`, would produce exactly the G7 failure: every API call silently re-fetches the token. It needs its own test that checks `expiresAt ≈ now + expires_in * 1000`.

**2.** **The callers that call `invalidate()`**, presumably the Larkspur API client's 401 handling. Nothing here shows whether they invalidate and retry once, or loop. An integration test against a stubbed Larkspur server that returns 401 once and then 200 should confirm there is a single retry and a single token refetch.

**3.** **Scope of the cache instance.** If `TokenCache` is created per request rather than once per process, none of the deduplication or caching behaviour applies. Worth a quick check where it is wired up.

## Summary

The highest-value tests are the two concurrency tests: shared refresh (G1) and failed-fetch recovery (G2/G3). Deduplicating concurrent refreshes and recovering from a failed fetch are the main jobs of this class, and right now no test covers either. If the `finally` reset broke, one token-endpoint error would leave the cache failing permanently, and the current tests would still pass. The boundary test (G4/G5) is cheap and catches off-by-one or skew-constant mistakes that the current 75 s test can't. After this plan is done, the main remaining risk is outside this file: a bad `expiresAt` from the real `fetchToken`. The cache would accept it silently and hit the token endpoint on every call (G7, Beyond Scope 1).

Two open questions came out of the gap list:
- **G6:** should `invalidate()` during an in-flight refresh force a *new* fetch, as the existing test name suggests, or is joining the in-flight one acceptable?
- **G7:** should a token with no usable lifetime be rejected or logged instead of quietly causing a refetch on every call?

Get answers to both before turning those two characterization tests into contract tests.
