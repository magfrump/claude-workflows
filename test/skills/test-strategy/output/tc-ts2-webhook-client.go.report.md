# Test Strategy: `notify.Client.Send` webhook retry client

**Scope:** `subject.go` (the whole file): `Client`, `StatusError`, `retryable`, `backoff` and `Send` (lines 1–67), plus the existing tests (lines 69–113, which live in `client_test.go` in the real project)
**Reviewed:** 2026-11-20

## Test Conventions

- **Framework:** only the standard library `testing` package. No testify and no assertion helpers. Failures use `t.Fatalf` with `got = X, want Y` messages.
- **Location and package:** `client_test.go`, in the same `notify` package. That means unexported `retryable` and `backoff` can be unit-tested directly.
- **Naming:** `TestSend<Behavior>`, e.g. `TestSendSucceedsFirstTry` and `TestSendDoesNotRetryClientErrors`.
- **Style:** loosely table-driven. The tests loop over a slice of inputs (`[]int{400, 404, 410}`).
- **Infrastructure:**
  - `fakeTransport` (lines 71–80) returns a scripted list of status codes and counts calls. It always returns empty headers. It never returns an error. It ignores the request it receives. It panics with index-out-of-range if called more times than it has codes, which in practice works as an "unexpected extra call" check.
  - `newTestClient` (lines 82–89) builds a client with `MaxAttempts: 4` and a `Sleep` that does nothing, so tests run instantly.
- **What exists today:** two tests. They cover the first-try 2xx success (line 57–58, only with 204) and the "don't retry" branch (lines 61–62, only for 400/404/410). The retry loop has no coverage at all.

## Untested Paths Touched by the Change

- **G1** — `subject.go:44,66` — when `MaxAttempts <= 0` (including a zero-value `Client`), the loop never runs and `Send` returns `lastErr == nil`. It reports success without sending anything. **This is a silent wrong answer.** Not covered.
- **G2** — `subject.go:61-64` — the retryable arm: a 429/5xx response leads to `Sleep(backoff(...))` and another attempt, which then succeeds and returns `nil`. Not covered.
- **G3** — `subject.go:44,66` — exhaustion: every attempt gets a retryable code, the loop ends, and `Send` returns the *last* `StatusError` after exactly `MaxAttempts` calls. Not covered.
- **G4** — `subject.go:64` — `Sleep` is called even after the final attempt, so a failing `Send` waits one extra backoff before returning (4 sleeps for 4 attempts). Not covered. The intended contract is unclear; it is probably a bug.
- **G5** — `subject.go:28` — `retryable` boundaries. Covered: only the false arm, for 400/404/410. Missing:
  - the `== 429` true arm
  - the `>= 500` true arm (500, 503, 599)
  - boundary falses: 428, 499
  - whether 408 Request Timeout should be retryable. Today it is not; that is an open question.
- **G6** — `subject.go:57` — the `< 300` success boundary. Covered: 204 only. Missing:
  - 200 and 299, which should succeed
  - 300 and 304, which should become a non-retryable `StatusError` after one call
- **G7** — `subject.go:32-35` — when a `Retry-After` header holds a valid integer, its value in seconds is used as the sleep. Not covered, because `fakeTransport` cannot set headers.
- **G8** — `subject.go:33-34` — `Retry-After` present but rejected, which falls through to exponential backoff. Not covered. Cases:
  - the HTTP-date form (valid per RFC 9110, but ignored here)
  - a non-numeric value
  - a negative value (`secs >= 0` false arm)
  - `" 5"` with whitespace (`Atoi` fails)
  - `"0"`, which hits the `secs >= 0` true arm with a zero sleep
- **G9** — `subject.go:35` — `Retry-After` has no upper limit. A value of `86400` makes the client sleep for a day. Values above about 9.2e9 overflow `time.Duration` and wrap negative, which means an instant retry. Not covered. Whether to add a limit is an open question.
- **G10** — `subject.go:32,39` — the exponential schedule (attempt 0→250ms, 1→500ms, 2→1s, 3→2s) and the `resp == nil` arm. Not covered. `Send` never passes a nil `resp`, so that arm can only be reached through a direct unit test.
- **G11** — `subject.go:51-54` — `HTTP.Do` transport errors (connection refused, DNS failure, timeout) return immediately with **no retry**. That is inconsistent with retrying on 503. Not covered. Whether this is intended is an open question.
- **G12** — `subject.go:45-48` — the error branch of `NewRequestWithContext`, e.g. a malformed `Endpoint` like `"://bad"` or a nil ctx. It returns before any call is made. Not covered.
- **G13** — `subject.go:45,51,64` — context cancellation:
  - A ctx cancelled before or between attempts should end the loop with an error that wraps `context.Canceled`.
  - `Sleep` does not watch ctx, so a cancel during a long backoff is only noticed after the sleep finishes.

  Not covered.
- **G14** — `subject.go:45,49` — every attempt must send a POST to `Endpoint` with `Content-Type: application/json` and the **full, identical body**. This holds today only because a new `bytes.NewReader` is built on each iteration. Not covered: the fake ignores the request.
- **G15** — `subject.go:51,64` — a nil `HTTP` field or nil `Sleep` field panics. `Sleep` only panics on the first retryable response, so a misconfigured client works in the happy path and crashes under partner outages. Not covered.

## Recommended Tests

Prerequisite (all of these except T1, T5 and T11 need it): extend `fakeTransport` instead of adding a new fake. Give it a list of steps where each step is `{code int; header http.Header; err error}`. Have it record `r.Method`, `r.URL`, `r.Header.Clone()` and the body bytes (`io.ReadAll(r.Body)`). Have it return `r.Context().Err()` if the context is done, the way a real transport would. Keep the `codes []int` field working as a shorthand so the two existing tests still compile. Also add a `recordSleep(*[]time.Duration)` helper for `Sleep`.

#### T1 — `TestSendZeroMaxAttemptsDoesNotReportSuccess`

**Closes gaps:** G1
**Type:** unit
**Priority:** high
**File:** `client_test.go`
**What it verifies:** a client that cannot make any attempt never returns `nil`.
**Key cases:**
- `MaxAttempts: 0`, codes `{}` → `err != nil`, `ft.calls == 0`. **This fails today**; `Send` returns `nil`.
- `MaxAttempts: -1` → same.
- Pick a fix before writing the assertion: either treat `<= 0` as 1 attempt (then assert `calls == 1` with codes `{204}` → nil), or return a configuration error such as `errors.New("notify: MaxAttempts must be >= 1")`.

**Setup needed:** none beyond `newTestClient` with `MaxAttempts` overridden.

#### T2 — `TestSendRetriesRetryableThenSucceeds`

**Closes gaps:** G2, G10 (integration side), G5 (429 and 503 arms)
**Type:** unit (in-process fake transport)
**Priority:** high
**File:** `client_test.go`
**What it verifies:** a retryable status causes a backoff and another attempt, and a later 2xx returns `nil`.
**Key cases:**
- codes `{503, 429, 200}` → `err == nil`, `calls == 3`, sleeps `== [250ms, 500ms]`
- codes `{500, 204}` → `err == nil`, `calls == 2`, sleeps `== [250ms]`

**Setup needed:** `recordSleep` helper.

#### T3 — `TestSendExhaustsAttemptsReturnsLastStatus`

**Closes gaps:** G3, G4
**Type:** unit
**Priority:** high
**File:** `client_test.go`
**What it verifies:** after `MaxAttempts` retryable failures, `Send` stops and returns the last status.
**Key cases:**
- codes `{500, 502, 503, 504}`, `MaxAttempts: 4` → `err.(*StatusError).Code == 504` (not 500), `calls == 4`. The extra-call panic in the fake confirms there is no 5th call.
- Sleep count: decide the contract first. Today it is `4` (`[250ms, 500ms, 1s, 2s]`); the likely-correct value is `3`. Assert the decided value so the extra sleep after the last attempt is pinned or fixed.
- `err.Error() == "webhook returned 504"`. One line, and it also covers `StatusError.Error`.

**Setup needed:** `recordSleep`.

#### T4 — `TestRetryable`

**Closes gaps:** G5
**Type:** unit, table-driven
**Priority:** medium
**File:** `client_test.go`
**What it verifies:** the exact boundaries of the retry policy.
**Key cases:**
- `428→false`, `429→true`, `430→false`, `499→false`, `500→true`, `503→true`, `599→true`
- `408→false`. Add a comment pointing to the open question, so a policy change becomes a deliberate test edit.

**Setup needed:** none.

#### T5 — `TestSendStatusBoundaries`

**Closes gaps:** G6
**Type:** unit, table-driven
**Priority:** medium
**File:** `client_test.go`
**What it verifies:** `< 300` is treated as success, and 3xx is a non-retryable failure.
**Key cases:**
- `200`, `201`, `299` → `nil`, 1 call
- `300`, `304` → `*StatusError{Code}`, 1 call. A fake response without a `Location` header is returned as-is by `http.Client`, so the result is deterministic.

**Setup needed:** none. The current `fakeTransport` is enough.

#### T6 — `TestBackoff`

**Closes gaps:** G7, G8, G10
**Type:** unit, table-driven, calling `backoff` directly
**Priority:** medium
**File:** `client_test.go`
**What it verifies:** how `Retry-After` is parsed, and the exponential fallback.
**Key cases:**
- `resp == nil`, attempts 0/1/2/3 → `250ms / 500ms / 1s / 2s`
- `Retry-After: "7"` → `7s`, at any attempt
- `"0"` → `0`
- `"-1"`, `"abc"`, `" 5"`, `"Wed, 21 Oct 2015 07:28:00 GMT"` → exponential value for that attempt
- header absent on a non-nil resp → exponential

**Setup needed:** build `&http.Response{Header: http.Header{"Retry-After": {v}}}` inline.

#### T7 — `TestSendHonorsRetryAfter`

**Closes gaps:** G7 (seen from `Send`)
**Type:** unit
**Priority:** medium
**File:** `client_test.go`
**What it verifies:** `Send` passes the real response to `backoff`, so a partner's `Retry-After` reaches `Sleep`.
**Key cases:**
- steps `{503, Retry-After: 3}`, `{200}` → sleeps `== [3s]`
- steps `{429, Retry-After: bogus}`, `{200}` → sleeps `== [250ms]`

**Setup needed:** the extended fake with per-step headers.

#### T8 — `TestSendTransportErrorNotRetried`

**Closes gaps:** G11
**Type:** unit
**Priority:** medium
**File:** `client_test.go`
**What it verifies:** the current contract that transport errors are returned at once and wrapped by `http.Client`.
**Key cases:**
- step `{err: errSentinel}`, then `{200}` → `errors.Is(err, errSentinel)`, `calls == 1`, no sleeps
- If the team decides connection errors *should* be retried, flip this to `calls == 2, err == nil`. The test is written so that change has to be explicit.

**Setup needed:** the extended fake with error steps.

#### T9 — `TestSendRequestShapeStableAcrossRetries`

**Closes gaps:** G14
**Type:** unit
**Priority:** high. This is cheap insurance against a silent bug: if someone "optimizes" by building the reader once outside the loop, retries would send an empty body to the partner and the partner's 2xx would hide it.
**File:** `client_test.go`
**What it verifies:** every attempt is the same complete POST.
**Key cases:**
- codes `{500, 500, 200}`, body `{"id":"evt_1","n":42}` → 3 recorded requests, each with:
  - `Method == "POST"`
  - `URL.String() == Endpoint`
  - `Header.Get("Content-Type") == "application/json"`
  - body bytes exactly equal to the input

**Setup needed:** the fake records requests.

#### T10 — `TestSendStopsOnContextCancel`

**Closes gaps:** G13
**Type:** unit. Optionally also an integration variant with `httptest.Server` and the real transport.
**Priority:** medium
**File:** `client_test.go`
**What it verifies:** cancellation ends the retry loop with a context error, not with a later success or a `StatusError`.
**Key cases:**
- ctx already cancelled, codes `{200}` → `errors.Is(err, context.Canceled)`. The fake must check `r.Context().Err()`; without that check the test passes for the wrong reason.
- `Sleep` cancels ctx when called; codes `{503, 200}` → `errors.Is(err, context.Canceled)`, `calls` is 1 at the fake. Exactly where the error comes from (`Do` vs. transport) depends on the `http.Client` version, so only assert on `errors.Is`.
- Document, without testing yet, that `Sleep` ignores ctx (see Summary).

**Setup needed:** a fake that honors context, and `context.WithCancel`.

#### T11 — `TestSendInvalidEndpoint`

**Closes gaps:** G12
**Type:** unit
**Priority:** low
**File:** `client_test.go`
**What it verifies:** a request-construction failure is returned before any network call.
**Key cases:** `Endpoint: "://bad"` → `err != nil`, `ft.calls == 0`, no sleeps.
**Setup needed:** none.

#### T12 — `TestSendRequiresSleepAndHTTP` (only if validation is added)

**Closes gaps:** G15
**Type:** unit
**Priority:** low/medium, depending on how `Client` gets built in production
**File:** `client_test.go`
**What it verifies:** a nil `Sleep` falls back to `time.Sleep` (or a nil `HTTP` to `http.DefaultClient`), or else returns an error instead of panicking during an outage.
**Key cases:** `Sleep: nil`, codes `{503, 200}` → no panic. With a real-sleep fallback, use a stub that returns `Retry-After: 0` so the test stays fast.
**Setup needed:** the code change comes first. Today this would only pin down a panic, which is not worth doing.

## What NOT to Test

- **G9 (no limit or overflow on `Retry-After`):** don't write a test until there is a decision. A test now would only record the wrap-to-negative overflow. Once a limit exists (e.g. `min(secs, 60s)`), add two rows to T6: `"86400"` → the limit, and `"10000000000"` → the limit.
- **Exponential overflow at `attempt >= ~36`:** only reachable with absurd `MaxAttempts` values. Fix it with a limit at the same time as G9; it doesn't need its own test.
- **`resp.Body.Close()` at line 55:** can't be observed with `http.NoBody`, and testing it means asserting on implementation details. Draining before close (for connection reuse) is a performance question, not a correctness one.
- **A standalone test for `StatusError.Error()`:** a trivial formatter. It is covered by one assertion in T3.
- **Property-based, snapshot, contract or e2e tests:** there is no serializer and no invariant across a wide input space. Only the partner sees the wire contract, and T9 already covers the request shape. An end-to-end test against a real partner would be slow and flaky and would teach nothing new.

## Coverage Gaps Beyond Current Scope

**1.** **Duplicate deliveries.** `Send` retries a non-idempotent POST after 5xx and 429 responses but sends no idempotency key. If a partner commits the event and then returns 503, the event is delivered twice. This should be tested at whatever layer builds `body` or adds headers, if a key gets added.

**2.** **Callers of `Send` are not in this repository.** Given G1, it is worth checking whether any caller builds `Client` without `MaxAttempts` and treats `nil` as "delivered".

**3.** **The test fake panics with index-out-of-range on unexpected extra calls.** That still fails the test, but the message is poor. When extending it, make it `t.Fatalf("unexpected call %d", n)` instead; that needs a `*testing.T` field.

## Summary

The most valuable test is **T1**. A zero-value or misconfigured `MaxAttempts` makes `Send` return `nil` without sending anything, so lost webhooks go unnoticed. Next come **T3** and **T2**, because the whole retry loop (lines 61–66) has no coverage today, and **T9**, a cheap guard that retried requests carry the full body. Doing this plan needs one small infrastructure change: extending `fakeTransport` to support headers, errors, request recording and context checks.

The main risk that remains is timing. `Sleep` ignores ctx and `Retry-After` has no upper limit, so one partner header can block a caller for hours, and cancellation can't interrupt it. Fixing this needs a design change (a ctx-aware sleep plus a limit), not just more tests.

Open questions for the owner:
- Should the client sleep after the final attempt (G4)?
- Should transport errors and 408 be retried (G11, G5)?
- What limit, if any, should `Retry-After` have (G9)?
- Should a bad configuration return an error or fall back to defaults (G1, G15)?
