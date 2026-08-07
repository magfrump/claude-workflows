Commit: e59c7ed

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree wt-candA, pinned at e59c7ed)
**Scope:** `git diff e59c7ed^..e59c7ed -- app/lib/utils/throttle.ts` (new throttle utility); Stage-1 context: consumers `app/hooks/useFormalizationPipeline.ts`, `app/hooks/useArtifactGeneration.ts`
**Checked:** 2026-08-07
**Total claims checked:** 2
**Summary:** 1 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

---

## Claim 1: "Returns a throttled version of `fn` that runs at most once per `ms` milliseconds."

**Location:** `app/lib/utils/throttle.ts:1`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The returned wrapper gates every invocation on a time budget. A call runs synchronously only when the window has elapsed, otherwise it either schedules a single trailing timer or is dropped:

```ts
// app/lib/utils/throttle.ts:11-24
return (...args: Parameters<T>) => {
  const now = Date.now();
  const remaining = ms - (now - lastRun);

  if (remaining <= 0) {
    if (timer) { clearTimeout(timer); timer = null; }
    lastRun = now;
    fn(...args);
  } else if (!timer) {
    timer = setTimeout(() => {
      lastRun = Date.now();
      timer = null;
      fn(...args);
    }, remaining);
  }
};
```

Both the leading branch (`fn(...args)`) and the trailing timer set `lastRun`, so no two actual invocations of `fn` occur less than `ms` apart. The "at most once per `ms`" rate limit holds.

**Evidence:** `app/lib/utils/throttle.ts:11-24`

---

## Claim 2: "The last call is always delivered (trailing edge)."

**Location:** `app/lib/utils/throttle.ts:2`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

When two or more calls arrive inside one throttle window, the trailing timer fires with the **first blocked call's** args, not the last. The `args` captured by the `setTimeout` closure are frozen at scheduling time, and every subsequent in-window call is dropped by the `else if (!timer)` guard (the timer already exists, so nothing re-arms or updates it):

```ts
// app/lib/utils/throttle.ts:19-24
} else if (!timer) {
  timer = setTimeout(() => {
    lastRun = Date.now();
    timer = null;
    fn(...args);      // args frozen from the FIRST blocked call
  }, remaining);
}
```

Trace with `ms = 50` and cumulative-snapshot calls A(t=0), B(t=10), C(t=20), D(t=30):
- A: `remaining <= 0` (first call, `lastRun` starts at 0) → runs immediately (leading edge), `lastRun = now`.
- B: `remaining = 40 > 0`, `timer` is null → schedules timer capturing **B's** args.
- C: `remaining = 30 > 0`, `timer` exists → `else if (!timer)` is false → **dropped**.
- D: `remaining = 20 > 0`, `timer` exists → **dropped**.
- Timer fires (~t=50): calls `fn` with **B's** args.

So D (the actual last call) is never delivered; B is. The claim's "always ... the last call" is false whenever ≥2 calls land in a window. A correct trailing-edge throttle would store the latest args in a mutable variable the timer reads (paraphrased — no quote available because the fix is absent from the code; this describes the missing mechanism, not a snippet present in the file).

**Consumer impact and subject classification.** All three consumer call sites pass a *cumulative snapshot* and perform a *final flush* with the complete value outside the throttle:

```ts
// app/hooks/useFormalizationPipeline.ts:66-72
const onToken = throttle((accumulated: string) => {
  acc.current.setSemiformal(accumulated);
}, 50);
const proof = await generateSemiformalStreaming(inputText, undefined, onToken);
a.setSemiformal(proof);           // final flush with full text, not throttled
```

```ts
// app/hooks/useFormalizationPipeline.ts:179-192
const onToken = throttle((accumulated: string) => {
  acc.current.setLeanCode(accumulated);
}, 50);
const newCode = await generateLeanStreaming(...onToken);
a.setLeanCode(newCode);           // final flush with full text
```

```ts
// app/hooks/useArtifactGeneration.ts:47-65
const onPartial = throttle((accumulated: string) => { ... setStreamingJsonPreview(...) }, 50);
const { text: finalText } = await fetchStreamingApi(route, request, { onToken: onPartial });
const parsed = JSON.parse(stripCodeFences(finalText));   // final value parsed from finalText, not the throttled preview
```

Because `accumulated` is monotonic (each token call carries the full string so far), a trailing frame carrying the *first* blocked snapshot instead of the *last* is merely a transient rendering lag of up to one window — never permanently stale, because the post-stream flush sets the complete value. No consumer retains dropped or stale data in its end state.

Therefore the subject is **comment/doc-only** for these consumers: the JSDoc misinforms a reader, but the cumulative-snapshot + final-flush pattern masks any behavioral consequence. The masking is what changes the classification from behavioral to doc-only — the utility itself genuinely drops/mis-delivers calls (a behavioral defect in isolation), but no *current* consumer observes stale/dropped output. Latent risk: a future caller that debounces distinct (non-cumulative) events, or relies on the trailing frame without a final flush, would get genuinely wrong behavior on the strength of this comment.

**Evidence:** `app/lib/utils/throttle.ts:2`, `app/lib/utils/throttle.ts:19-24`, `app/hooks/useFormalizationPipeline.ts:66-72`, `app/hooks/useFormalizationPipeline.ts:179-192`, `app/hooks/useArtifactGeneration.ts:47-65`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/lib/utils/throttle.ts:2`): Trailing edge delivers the *first* blocked call's args and drops all later in-window calls, not "the last call." Fix the comment to say the throttle drops intermediate calls and re-delivers the first blocked call, OR fix the implementation to capture the latest args in a mutable variable the timer reads. Subject is comment/doc-only for current consumers (cumulative snapshots + final flush mask it); latent behavioral risk for future non-cumulative callers.
