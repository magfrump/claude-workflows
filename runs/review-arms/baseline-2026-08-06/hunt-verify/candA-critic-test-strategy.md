Commit: e59c7ed

# Test Strategy: throttle utility (candA, SSE partial-JSON preview throttling)

**Scope:** `app/lib/utils/throttle.ts` (new file, 26 lines, added in e59c7ed)
**Reviewed:** 2026-08-07
**Tier:** Advisory (green / Consider) — no existing test for this module

## Test Conventions

- **Framework:** Vitest 4.1 (`vitest run`), jsdom-style DOM available.
- **Location & naming:** tests colocated next to source as `*.test.ts` (e.g. `app/lib/utils/textSelection.test.ts`, `app/lib/utils/fileExtraction.test.ts`). The throttle test therefore belongs at `app/lib/utils/throttle.test.ts`.
- **Style:** `import { describe, it, expect } from 'vitest'`; plain arrange-act-assert; no custom fixtures.
- **Fake timers:** precedent exists — `app/hooks/useWorkspacePersistence.test.ts` uses `vi.useFakeTimers()` / `advanceTimersByTime`. This is the right tool here since throttle is entirely time- and `setTimeout`-driven; do NOT test with real sleeps.
- **Time source:** implementation reads `Date.now()` directly (lines 11, 20), so a test must control both `Date.now` and the timer queue. `vi.useFakeTimers()` in Vitest 4 mocks `Date.now` alongside `setTimeout`, so a single `vi.useFakeTimers()` + `vi.advanceTimersByTime(ms)` drives both consistently.

## Untested Paths Touched by the Change

- **G1** — `throttle.ts:14,16-17` — leading-edge branch: first-ever call (`lastRun = 0`, so `remaining <= 0`) invokes `fn` synchronously and sets `lastRun` — not covered
  - Severity: Consider | Location: throttle.ts:14-17 | Evidence: `if (remaining <= 0) { ... lastRun = now; fn(...args); }`, no test file exists | Confidence: High | Legibility-target: reviewer
- **G2** — `throttle.ts:18-23` — trailing-edge branch: a call inside the window with no timer pending schedules a `setTimeout(..., remaining)` that later fires `fn` — not covered
  - Severity: Consider | Location: throttle.ts:18-23 | Evidence: `else if (!timer) { timer = setTimeout(...) }` | Confidence: High | Legibility-target: reviewer
- **G3** — `throttle.ts:15` — `clearTimeout` sub-branch: a trailing timer is pending, then a later call arrives after the window has elapsed (`remaining <= 0`), which clears the pending timer before running immediately — not covered; this is the "flush-then-run" interaction and is the easiest path to leave silently broken
  - Severity: Consider | Location: throttle.ts:15 | Evidence: `if (timer) { clearTimeout(timer); timer = null; }` inside the `remaining <= 0` arm | Confidence: High | Legibility-target: reviewer
- **G4** — `throttle.ts:18` (implicit `else`) — dropped-call path: a 2nd+ call inside the window while `timer` is already set hits neither branch (`remaining > 0` and `timer != null`), so the call and its args are discarded — not covered. This path is the one that contradicts the docstring (see G5).
  - Severity: Consider | Location: throttle.ts:18 | Evidence: no `else` clause; when `remaining > 0 && timer` the closure returns without touching `fn` | Confidence: High | Legibility-target: reviewer
- **G5** — `throttle.ts:19-22` — trailing-arg semantics vs. docstring: the trailing `setTimeout` captures the `args` of the call that *created* the timer (first call in the window), so interim later calls' args are lost. The docstring line 2 claims "The last call is always delivered (trailing edge)" — the delivered args are the *first-in-window*, not the last. A test asserting last-args delivery would fail; a test is needed to pin the *actual* contract and surface the doc mismatch. — not covered
  - Severity: Consider | Location: throttle.ts:1-2 (doc) vs. 19-22 (behavior) | Evidence: closure body captures `args` at scheduling time; no reassignment on subsequent calls | Confidence: High | Legibility-target: author (decide intended contract before writing the assertion)

## Recommended Tests

#### Leading edge fires synchronously on first call
**Closes gaps:** G1
**Type:** unit
**Priority:** high
**File:** `app/lib/utils/throttle.test.ts`
**What it verifies:** the first invocation calls `fn` immediately (before any timer advance).
**Key cases:**
- `const spy = vi.fn(); const t = throttle(spy, 100); t('a')` → `spy` called once synchronously with `'a'`.
**Setup needed:** `vi.useFakeTimers()` in `beforeEach`, `vi.useRealTimers()` in `afterEach`; `vi.fn()` spy.

#### Trailing edge delivers a deferred call after the window
**Closes gaps:** G2, G5
**Type:** unit
**Priority:** high
**File:** `app/lib/utils/throttle.test.ts`
**What it verifies:** a call made inside the throttle window is delivered once, `remaining` ms after the leading call.
**Key cases:**
- `t('a')` (leading, runs now) → advance 40ms → `t('b')` (schedules trailing) → advance 59ms → `fn` still called once → advance 1ms (total 100 since leading) → `fn` called 2nd time.
- Assert the args the trailing call received. Per G5, decide with the author whether the intended value is `'b'` (only one interim call, so first==last here — keep this case unambiguous by having exactly one interim call).
**Setup needed:** fake timers; spy.

#### Interim calls inside a busy window are coalesced to first-in-window args (documents actual contract)
**Closes gaps:** G4, G5
**Type:** unit
**Priority:** medium
**File:** `app/lib/utils/throttle.test.ts`
**What it verifies:** when multiple calls land inside one window, exactly one trailing call fires and it carries the args of the *first* interim call, not the last — the behavior that contradicts the docstring.
**Key cases:**
- `t('a')` (leading) → advance 10ms → `t('b')` → advance 10ms → `t('c')` → advance 10ms → `t('d')` → advance to window end → `fn` fires exactly once with `'b'` (NOT `'d'`).
- This test will fail if the code is later "fixed" to match the docstring — that is intentional; it forces the doc and code to agree. Flag to author before committing the asserted value.
**Setup needed:** fake timers; spy asserting call count and last-call args.

#### Later call after window clears a pending trailing timer (no double fire)
**Closes gaps:** G3
**Type:** unit
**Priority:** medium
**File:** `app/lib/utils/throttle.test.ts`
**What it verifies:** a call arriving after the window elapses runs immediately AND cancels the still-pending trailing timer, so `fn` is not invoked a redundant third time.
**Key cases:**
- `t('a')` (leading) → advance 40ms → `t('b')` (schedules trailing for +60ms) → advance 70ms (past window; trailing already fired at +100... ) — construct timing so the trailing timer is still pending when the post-window call arrives: `t('a')` → advance 50ms → `t('b')` (trailing scheduled) → advance 60ms so `now-lastRun > ms` relative to the leading `lastRun`? Note: the trailing callback resets `lastRun`, so craft the sequence carefully. Simplest reliable form: `t('a')`; advance 100ms (trailing never scheduled since no interim call); `t('b')` runs immediately; assert `clearTimeout` path is exercised by a variant where an interim call scheduled a timer that the next leading call clears. Verify total call count matches expected (no extra fire).
**Setup needed:** fake timers; spy; optionally `vi.spyOn(global, 'clearTimeout')` to assert the branch is hit.

## What NOT to Test

- **Type-level generic constraint** (`T extends (...args) => void`) — enforced by `tsc`, not worth a runtime test.
- **`ms = 0`** as a dedicated correctness test is low value (degenerate config; SSE preview always passes a positive interval) — a single guard assertion is enough if desired, not a priority.
- **Real-timer / wall-clock behavior** — do not write tests that actually sleep; they are slow and flaky and add no coverage over the fake-timer tests.

## Coverage Gaps Beyond Current Scope

**1.** No `cancel()` / cleanup API. The throttled closure holds a live `setTimeout`. In an SSE React consumer, a pending trailing call can fire after the component unmounts (setState-after-unmount / stale-preview write). The diff introduces no cancel affordance and no test could cover cleanup because the API does not exist. This is a design gap for the SSE use case, not just a test gap — flag to author: does the streaming preview need a `.cancel()` the effect cleanup can call?

**2.** Docstring accuracy (line 2) is unverified anywhere. Independent of the throttle tests, the "last call is always delivered" claim is inaccurate given G4/G5; a code-fact-check pass would flag it. Noting here since the test that pins the real contract (G4/G5 test above) is the natural place to resolve it.

## Summary

The highest-value test is the leading-edge + trailing-edge pair (G1, G2) — it exercises both real branches of the throttle and is trivial to write with `vi.useFakeTimers()`, matching the existing `useWorkspacePersistence.test.ts` precedent. The most important *finding* the gap enumeration surfaced is that the docstring's "last call is always delivered" contract is false: the trailing call carries first-in-window args and interim calls are dropped (G4/G5) — resolve intended semantics with the author before asserting a value. Main residual risk after this plan: the missing `cancel()` API means no test can cover unmount-time cleanup for the SSE consumer, which is the failure mode most likely to bite in production. All findings are Consider-tier (advisory); the module is small, pure, and cheaply testable — there is no blocker, only an untested new utility with a doc/behavior mismatch worth pinning down.
