Commit: e59c7ed

# Performance Review — throttle utility (candA, e59c7ed)

**Scope:** `app/lib/utils/throttle.ts` (new file, 26 lines) at e59c7ed
**Date:** 2026-08-07
**Based on:** no candA code-fact-check report on disk (only `candB-fact-check.md` present) — proceeding on code analysis only.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

`throttle(fn, ms)` wraps a callback and rate-limits invocation to at most once per `ms`, with a
trailing timer that fires the pending call after the window closes. Consumers create one throttled
wrapper per generation run:

- `useFormalizationPipeline.ts:66` and `:179` — `onToken = throttle((accumulated) => setSemiformal(accumulated), 50)`, passed as the streaming token callback for semiformal/lean SSE.
- `useArtifactGeneration.ts:47` — `onPartial = throttle((accumulated) => ..., ...)` for partial-JSON preview parsing.

Call frequency: the wrapped function is invoked once per streamed token (potentially thousands of
times over a 15–85s generation), each time with the **full accumulated string so far**. The
throttle exists precisely to collapse that per-token firing into a bounded re-render rate — this is
a hot path (per-token callback during active streaming), and throttling it is the correct instinct.
The throttle body itself is O(1): two `Date.now()` reads, one comparison, at most one
`setTimeout`/`clearTimeout` per call. No allocation beyond the returned closure and one captured
args reference. The utility is not itself a bottleneck.

## Findings

#### Trailing edge delivers first-in-window args, not the latest — contradicts the docstring

**Severity:** Low
**Location:** `app/lib/utils/throttle.ts:19-25`
**Move:** Find the work that moved to the wrong place (redundant/stale hot-path render)
**Classification:** Micro (renders a stale, superseded value) / Hot path (per-token streaming callback)
**Confidence:** High (behavior), Low (perf magnitude)
**Baseline:** no baseline available — flagged as speculative

The docstring claims "The last call is always delivered (trailing edge)." The implementation does
not do this. Once a timer is armed (`else if (!timer)`), every subsequent call inside the window is
dropped because `!timer` is false, and the timer fires with the args captured from the **first**
call that armed it — evidence: `timer = setTimeout(() => { ... fn(...args); }, remaining)` closes
over the `args` of the arming call, and no later call updates a "pending args" slot. So during
continuous streaming each window renders content that is one-window stale and omits every token that
arrived after the arming call. The performance dimension: the trailing `setState` pushes an
already-superseded (shorter) accumulated string into React, causing a re-render whose content is
immediately overwritten by the next window's leading edge — wasted render work with visible preview
regression/flicker. Impact is bounded (≤ one 50ms window of lag per update) and the final
correctness is masked by the post-stream `setSemiformal(proof)` in the consumers, so user-visible
damage is limited to intermediate flicker.

**Recommendation:** Store the latest args in a mutable slot the timer reads at fire time
(`let pendingArgs; ... pendingArgs = args;` update on every call; `fn(...pendingArgs)` in the
timer), so the trailing edge delivers the newest accumulated string as the docstring promises. This
also removes the redundant stale render.

#### No cancel/cleanup handle — pending timer fires after unmount or after a new generation starts

**Severity:** Informational
**Location:** `app/lib/utils/throttle.ts:3-25`
**Move:** Trace the memory lifecycle (callback registered without deregistration)
**Classification:** Micro (one orphaned timer + captured string, self-clearing in ≤ `ms`) / Hot path (streaming)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

The returned throttled function exposes no `.cancel()`. Consumers create a fresh throttle per
generation run (`useFormalizationPipeline.ts:66`, `useArtifactGeneration.ts:47`) but never cancel a
prior run's pending timer. If a component unmounts or a new generation begins while a timer is armed,
the timer still fires an orphaned `setState` (a wasted render / dev-time warning under older React;
a no-op under React 18) and the captured accumulated string is retained until it fires. The window
is at most `ms` (50ms), so the leak is transient and not a scaling concern — flagged for lifecycle
correctness, not throughput.

**Recommendation:** Return a handle with a `cancel()` that runs `clearTimeout(timer)`, and call it
from an effect cleanup / at the start of each new generation. Low priority given the 50ms bound.

## What Looks Good

- The core design is the right performance move: collapsing a per-token callback (thousands of
  invocations) into at most one `fn` call per `ms` bounds React re-renders to ~20/sec at `ms=50`,
  which is exactly the intended win for SSE preview streaming. Leading-edge fires immediately so the
  first token renders with no added latency.
- O(1) body, no per-call heap allocation beyond the unavoidable closure; `clearTimeout` is correctly
  called before an immediate leading-edge run to avoid a double-fire.
- Creating a fresh throttle per generation run (rather than one shared instance) is correct — it
  avoids cross-run `lastRun` bleed.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Trailing edge delivers stale first-in-window args (docstring says last) | Low | `throttle.ts:19-25` | High |
| 2 | No cancel handle; pending timer fires post-unmount / cross-run | Informational | `throttle.ts:3-25` | Medium |

## Overall Assessment

Performance posture is sound: the utility is the correct, cheap mechanism for rate-limiting a hot
per-token streaming callback, and it is not itself a bottleneck. No High or Critical performance
findings — nothing here needs load testing to clear for merge. The one substantive issue is that the
trailing edge delivers stale (first-in-window) args rather than the latest, which both contradicts
the docstring and causes a redundant, immediately-superseded render; it is fixable in place with a
pending-args slot and is primarily a correctness/flicker concern with negligible throughput cost. No
baselines were available, so all impact statements are reasoned from code structure, not measurement.
