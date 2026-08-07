Commit: e59c7ed

# API Consistency Review — throttle utility (candA)

**Scope:** `app/lib/utils/throttle.ts` (new file), diff `e59c7ed^..e59c7ed`; consumers `app/hooks/useFormalizationPipeline.ts`, `app/hooks/useArtifactGeneration.ts`
**Date:** 2026-08-07
**Based on:** no code-fact-check report provided (candA-fact-check.md absent)

> ⚠️ **No code fact-check report provided.** API documentation claims (the JSDoc "trailing edge" contract, the advertised `.cancel()` method) have not been independently verified by an upstream fact-check pass. Verification below is from direct reading of the code at e59c7ed.

## Baseline Conventions

- `app/lib/utils/*.ts` export bare named functions (`stripCodeFences`, `topologicalSort`, `mergeStreamingPreview`, `getSelectionCoordinates`) — camelCase verbs, no `I`/`DTO` suffixes, generics where useful. `throttle` fits this shape.
- The codebase's one existing timer-deferral pattern lives in `useWorkspacePersistence.ts`: a `timerRef` holding `ReturnType<typeof setTimeout>` that is **explicitly cleared on cleanup / unmount** (lines 102, 124, 178, 223) and on session switch. The established expectation for deferred-work primitives here is that pending timers are cancelable by the owner.
- Term "debounce" is already used in the codebase (`useWorkspacePersistence`); `throttle` is a consistent sibling term.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `throttle` | function | `mergeStreamingPreview`, `stripCodeFences`, `topologicalSort`; term "debounce" in `useWorkspacePersistence` | `app/lib/utils/*.ts`, `app/hooks/useWorkspacePersistence.ts` | Consistent — bare camelCase util verb, matches debounce terminology |
| `.cancel()` (advertised method on return value) | method | timer-cancel via `clearTimeout(timerRef.current)` cleanup | `app/hooks/useWorkspacePersistence.ts:124,178,223` | Absent — advertised in PR surface but not present on the returned function (see Finding 1) |
| `ms`, `fn` params | param | `raw`, `nodes`, generic `<T>` in sibling utils | `app/lib/utils/*.ts` | Consistent |

## Findings

#### 1. Advertised `.cancel()` method is not implemented

**Severity:** Breaking
**Location:** `app/lib/utils/throttle.ts:9-25`
**Move:** #3 (consumer contract) / #7 (surface asymmetry)
**Confidence:** High
**Legibility-target:** returned closure has no `.cancel` property

The PR describes the utility as exporting a throttled function "with a `.cancel()` method," but the returned value is a plain `(...args) => void` closure with no `cancel` property attached. A consumer coding to the documented contract (`const t = throttle(fn, 50); ...; t.cancel();`) fails to typecheck/exists at runtime as `undefined`. This also blocks the codebase's established cleanup pattern: `throttle` schedules a trailing `setTimeout` that can fire after a React component unmounts (both consumers create the throttled fn inside async flows and never cancel it), calling `setStreamingJsonPreview` / `setSemiformal` on an unmounted component. The sibling `useWorkspacePersistence` timer is always cleared on unmount; throttle offers no equivalent, so the advertised escape hatch is exactly the one that is missing.

**Recommendation:** Attach a `.cancel()` (clear `timer`, null it) to the returned function and type the return as `T & { cancel: () => void }`, or remove `.cancel()` from the PR description if it is out of scope. Consumers should call it in their cleanup path.

#### 2. JSDoc "the last call is always delivered (trailing edge)" contradicts the implementation

**Severity:** Breaking
**Location:** `app/lib/utils/throttle.ts:1-2, 18-24`
**Move:** #3 (documentation drift)
**Confidence:** High
**Legibility-target:** trailing timer fires with stale (first-throttled) args, not the last

The docstring promises "The last call is always delivered (trailing edge)." The trailing branch schedules `setTimeout(..., remaining)` capturing the args of the *first* call that found `remaining > 0`, and every later call within the window hits `else if (!timer)` = false and is **silently dropped**. Trace (ms=50): call A runs immediately; B at +10ms arms the timer with B's args; C at +20ms and D at +30ms are dropped; at +50ms the timer fires with **B**, never D. So the *last* call is not delivered — an earlier one is. For the streaming consumers, `onToken`/`onPartial` receive the full accumulated string each call, so a stale trailing fire renders a **shorter/older** accumulated preview than the true latest token. (The final correct value is set outside throttle in both consumers, so the artifact is not permanently wrong — the staleness is transient in-stream, but the documented contract is still false.)

**Recommendation:** Store the latest args in a `let lastArgs` and have the trailing timer invoke `fn(...lastArgs)`, or soften the docstring to state that the *most recent args at fire time* — not "the last call" — are delivered. Prefer the code fix; "trailing edge" idiomatically means latest-args.

#### 3. Self-referential generic constraint

**Severity:** Minor
**Location:** `app/lib/utils/throttle.ts:3`
**Move:** #2 (naming/signature convention)
**Confidence:** Medium
No existing precedent in `app/lib/utils/*.ts` (surveyed all exported generic signatures; only `mergeStreamingPreview<T>` exists and it is not function-typed)

`T extends (...args: Parameters<T>) => void` is circular — `T` is constrained in terms of its own `Parameters<T>`. It compiles but is an unusual idiom for a public utility; the conventional form is `throttle<A extends unknown[]>(fn: (...args: A) => void, ms: number): (...args: A) => void`, which is clearer to callers reading the exported signature. Severity floored to Minor per the no-precedent downgrade rule.

**Recommendation:** Rewrite with an argument-tuple generic for legibility.

## What Looks Good

- `throttle` name and `(fn, ms)` parameter order match sibling utilities and the existing "debounce" terminology — no naming friction.
- Both consumers use it identically (`throttle(cb, 50)`), so the call-site contract is applied consistently.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Advertised `.cancel()` method not implemented | Breaking | `throttle.ts:9-25` | High |
| 2 | JSDoc "last call always delivered" contradicts impl | Breaking | `throttle.ts:1-2,18-24` | High |
| 3 | Self-referential generic constraint | Minor | `throttle.ts:3` | Medium |

## Overall Assessment

The name and signature are consistent with the codebase, but the utility's two documented contract points — the `.cancel()` method and the "last call is always delivered" trailing-edge guarantee — are both unmet by the implementation. Either the implementation must be brought up to the advertised surface (add `.cancel()`, deliver latest args) or the documentation/PR description must be corrected to match reality. Both gaps are fixable in place. Consumer impact is real but partially masked: the streaming previews can transiently show stale content and pending timers can fire post-unmount, though the final artifact value is set outside throttle.
