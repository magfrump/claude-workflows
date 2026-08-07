Commit: c95c9cb

# Performance Review — Lean verifier unavailability handling (d86d2dc..c95c9cb)

**Scope:** branch diff d86d2dc..c95c9cb (7 source files + tests) in wt-lean worktree, pinned at c95c9cb
**Date:** 2026-08-06
**Based on:** code fact-check report at /workspace/runs/review-arms/baseline-2026-08-06/lean/fact-check.md

## Data Flow and Hot Paths

The change adds an `"unavailable"` verification state end-to-end: the API route (`app/api/verification/lean/route.ts`) now returns `{valid:false, unavailable:true, reason}` when the Lean verifier is not configured / unreachable / errored, instead of the old `{valid:true, mock:true}` fallback; `verifyLean` surfaces the flag; `verifyResultToStatus` maps it to a status; the retry loop bails on it; and the UI renders an amber "offline" banner/badge.

Call frequency: verification is **user-initiated** — one HTTP call per proof-verify or per Re-verify click, driven through `leanRetryLoop` (max 3 attempts). This is not a per-request server hot path or a per-item loop at scale; it is a low-frequency, human-paced path whose dominant cost is the LLM generation and the downstream verifier round-trip, not any code in this diff. All findings below are calibrated against that temperature.

There are no measured baselines available in the diff or surrounding repo; every finding is flagged speculative accordingly.

## Findings

#### Retry loop correctly short-circuits on unavailable — avoids wasted LLM generations (positive)

**Severity:** Informational
**Location:** `app/lib/formalization/leanRetryLoop.ts:71-77`
**Move:** Find the work that moved to the wrong place (positive) / Hidden multiplication
**Classification:** Macro (attempt-count control) / Cold path (user-initiated, ≤1 call per verify)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The `if (unavailable) { ... return }` bails out of the `for (attempt <= MAX_LEAN_ATTEMPTS)` loop on the first unavailable result. Each retained attempt would otherwise run a full `generateLean`/`generateLeanStreaming` (an LLM call — the single most expensive step in the loop) plus a verify round-trip. Bailing correctly avoids up to 2 additional wasted LLM generations when the verifier is structurally unable to check the proof. Net effect versus the base revision is neutral-to-positive: the old code returned `{valid:true, mock:true}`, which also exited on attempt 1, so no regression in attempt count, and the new path no longer mislabels an unchecked proof as valid.

**Recommendation:** None — this is the correct behavior. No retries against an unavailable verifier is the right call.

#### Manual Re-verify against an unreachable verifier waits the full 35s abort timeout per click

**Severity:** Low
**Location:** `app/api/verification/lean/route.ts:32-56`, `app/components/features/lean-display/LeanCodeDisplay.tsx:111`
**Move:** Question the cache / asymptotic worst case on a user-facing wait
**Classification:** Micro (fixed per-call latency ceiling) / Cold path (human-paced, one click per action)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

The diff extends the Re-verify button's render condition to include `"unavailable"`, so users can repeatedly re-trigger verification while the verifier is offline. For the `verifier-not-configured` case this is cheap — the route short-circuits at `if (!verifierUrl)` before any fetch. But for the `verifier-unreachable` case (env var set, service down), each Re-verify click issues a fetch that only resolves when `AbortController` fires at `REQUEST_TIMEOUT_MS` = 35_000 ms, so every click costs up to ~35s of amber "verifying" wait before landing back on "offline". This is inherent to the timeout, not newly introduced by the diff, but the new always-available Re-verify affordance makes the 35s wait easy to hit repeatedly. There is no rate-limit or backoff on repeated clicks.

**Recommendation:** Optional — consider a shorter timeout for interactive re-verify, or disabling/cooling-down the Re-verify button briefly after an `unreachable` result, so a user doesn't queue several 35s waits. Not blocking.

#### JSON parse moved after the ok-check — minor positive on the error path

**Severity:** Informational
**Location:** `app/api/verification/lean/route.ts:45-52`
**Move:** Identify the serialization tax (positive)
**Classification:** Micro (one avoided deserialization) / Cold path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`const data = await res.json()` now runs only on a 2xx response; the error path returns `unavailableResponse("verifier-error", ...)` without parsing the upstream body. This removes one JSON deserialization on the error branch. Impact is negligible at this call frequency but is a small correctness-and-efficiency improvement (the fact-check notes the upstream error body is now dropped, which is a behavior change but not a performance concern).

**Recommendation:** None.

## Note on retry backoff (per review brief)

The retry loop has **no delay/backoff between attempts** — attempts 2 and 3 fire immediately after `onErrors`. This is pre-existing behavior, untouched by this diff, and does not apply to the unavailable path (which bails before any retry). Because attempts are gated by an LLM generation each (seconds of latency), the absence of an explicit backoff sleep is not itself a throughput problem here — the generations are the natural spacing. Not a finding against this changeset; flagged only because the brief asked.

## What Looks Good

- **Bail-on-unavailable** (`leanRetryLoop.ts:73-77`) avoids up to 2 wasted LLM generations and is the right short-circuit.
- **`verifyResultToStatus`** (`api.ts:115-118`) is O(1), allocation-free, and short-circuits `unavailable` before `valid`.
- **`sanitizeVerificationStatus`** collapsing `"unavailable"` → `"none"` (whitelist) is O(1) and adds no persistence-path cost.
- **Deferred JSON parse** on the route error path (`route.ts:45-52`) trims one deserialization.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Retry loop short-circuits on unavailable (positive) | Informational | `leanRetryLoop.ts:71-77` | High |
| 2 | Re-verify vs unreachable verifier waits full 35s per click | Low | `route.ts:32-56`, `LeanCodeDisplay.tsx:111` | Medium |
| 3 | JSON parse deferred to ok path (positive) | Informational | `route.ts:45-52` | High |

## Overall Assessment

Performance posture is sound. This is a low-frequency, user-initiated verification path, not a server hot path, and the change is neutral-to-positive on work performed: it removes the misleading mock-valid fallback and correctly bails the retry loop on unavailability, avoiding wasted LLM generations, while deferring an error-path JSON parse. The only actionable-ish item is the Low-severity interaction between the always-available Re-verify button and the fixed 35s fetch timeout when the verifier is set-but-unreachable, which can make a user queue multiple 35s waits; it is optional and non-blocking. No profiling is required to ship this change; no algorithmic or scaling issues are present.
