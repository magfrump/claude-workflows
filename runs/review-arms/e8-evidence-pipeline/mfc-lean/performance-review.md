# Performance Review — mfc-lean Lean-verifier error handling (`d86d2dc...c95c9cb`)

**Commit:** c95c9cb
**Scope:** `git diff d86d2dc...HEAD` — `app/api/verification/lean/route.ts`, `app/lib/formalization/{api.ts,leanRetryLoop.ts}`, `app/hooks/useFormalizationPipeline.ts`, `app/lib/types/session.ts`, UI components/tests; plus unchanged fan-out consumers read for context (`app/lib/formalization/formalizeNode.ts`, `app/hooks/useAutoFormalizeQueue.ts`)
**Date:** 2026-08-17
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/code-fact-check-report.md` (k=2 merged, execution-verified route and retry-loop behavior)

## Data Flow and Hot Paths

The change replaces a mock-success fallback with a three-reason unavailability taxonomy in the Lean verification route (`verifier-not-configured` / `verifier-unreachable` / `verifier-error`), threads an `unavailable` flag through `verifyLean` → `leanRetryLoop` → `useFormalizationPipeline`, and adds a no-retry short-circuit in the retry loop.

Two paths consume this code:

1. **Interactive path (hot, user-triggered):** `handleGenerateLean` runs `leanRetryLoop` — up to `MAX_LEAN_ATTEMPTS = 3` iterations, each paying one LLM generation call (`generateLeanStreaming`, an Anthropic streaming call — seconds to tens of seconds and token-billed) plus one verifier round-trip capped server-side at `REQUEST_TIMEOUT_MS = 35_000` ms.
2. **Decomposition fan-out path (hot, per-node loop):** `useAutoFormalizeQueue.start` iterates topologically over N proposition nodes, calling `formalizeNode` per node — each node pays one semiformal LLM call + the full retry loop, and failures cascade skips to dependents. N is user-data-scale (nodes in a decomposition graph); no upper bound is enforced in the queue.

No measured baselines (latency, cost, node counts) exist anywhere in the repo or the fact-check report; every finding below is speculative per the Baseline Requirement.

## Findings

#### Decomposition fan-out discards `unavailable` — verifier-down converts to N× wasted LLM generation and has no queue-level short-circuit

**Severity:** High
**Location:** `app/lib/formalization/formalizeNode.ts:61`, `app/hooks/useAutoFormalizeQueue.ts:57-59,128-139`
**Move:** Hidden multiplication (move 1) + work in the wrong place (move 3)
**Classification:** Macro (fan-out over user-scale N with per-item LLM + timeout cost) / Hot path (per-node queue loop)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The retry loop's new unavailability signal stops one hop short of the fan-out consumer. `formalizeNode` collapses it: `deductiveResult = result.valid ? "verified" : "failed"` (`formalizeNode.ts:61`) — `result.unavailable` is never read, so a down verifier is indistinguishable from a failed proof at the queue level. Consequences per queue run with the verifier down: (a) every independent root node still pays its full price — one semiformal LLM call + one Lean-generation LLM call + one verifier attempt (up to 35 s if the verifier hangs rather than refuses) — before being marked `failed`; with R independent roots that is R × (2 LLM calls + up to 35 s) spent to rediscover, serially, the same outage the first node already proved. (b) All dependents are skipped with `"Skipped: dependency <id> failed"` — the outage masquerades as proof failure. (c) On the next queue run, the filter at `useAutoFormalizeQueue.ts:59` reprocesses everything not `"verified"`, so all N nodes re-pay both LLM generations even though their generated code was fine and only the check was missing. The per-run retry-loop short-circuit (execution-verified, fact-check Claim 20) saves cost *within* one node but the saving is not propagated *across* nodes or across runs.

**Recommendation:** Propagate `unavailable` out of `formalizeNode` (e.g., a third return value or a distinct node status such as `"unverified"` with a reason) and short-circuit the queue on first unavailability — pause or abort the run rather than converting the remaining roots to `failed`. On re-run, nodes with stored `leanCode` and an unavailability marker should re-verify only, not regenerate.

#### 35 s route timeout is priced against the wrong platform — on duration-limited serverless deploys the taxonomy is bypassed and hung verifiers bill full function duration

**Severity:** Medium
**Location:** `app/api/verification/lean/route.ts:3,32-40`, `app/lib/formalization/api.ts:120-131`, `app/hooks/useFormalizationPipeline.ts:127-132`
**Move:** Price the deployment environment (move 10)
**Classification:** Macro (failure-mode routing changes with the platform) / Hot path (request handler)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

The route's own comment prices the not-configured branch for Vercel ("typical on Vercel deploys…"), but the timeout branch is not priced for the same platform: the file exports no `maxDuration`, and no `vercel.json`/`next.config` duration override exists in the repo (checked). Where the platform's default function duration limit is below 35 s, the `AbortController` at `route.ts:33-34` can never fire — the platform kills the function first, the client gets a non-JSON platform error page, `verifyLean`'s unconditional `res.json()` (`api.ts:120-126`) throws, the throw propagates out of `leanRetryLoop`, and `handleGenerateLean`'s catch marks the proof **`invalid`** (`useFormalizationPipeline.ts:131-132`) — precisely the "missing verifier reads as a verdict on the proof" failure this change was built to eliminate. Cost side: every hung-verifier request is billed for the full duration limit of the invocation, once per attempt, multiplied by the fan-out in the finding above. The specific platform-limit value is submitted as a claim below rather than asserted.

**Recommendation:** Export `maxDuration` from the route sized above `REQUEST_TIMEOUT_MS` (or lower `REQUEST_TIMEOUT_MS` below the deploy target's limit), and make `verifyLean` tolerate non-JSON error responses by mapping them to `unavailable: true` instead of throwing, so platform-level timeouts land in the taxonomy instead of bypassing it.

#### Transient unavailability (brief 503) forfeits the run with no cheap automatic recovery — but the expensive recovery was correctly not taken

**Severity:** Low
**Location:** `app/lib/formalization/leanRetryLoop.ts:73-77`
**Move:** Question the retry economics (moves 1 and 3)
**Classification:** Macro (retry-policy structure) / Hot path (interactive pipeline)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The tasked both-ways cost analysis of the no-retry short-circuit. **Saved:** with the verifier down, the loop exits after exactly one generation + one verification (execution-verified, fact-check Claims 18/20) instead of up to 3+3 — avoiding up to 2 further token-billed LLM generations and up to 2 further verifier waits (up to 35 s each in the hang case, ~105 s worst-case latency avoided). Retrying *through the existing loop* would also be the wrong recovery: each loop retry regenerates the Lean code via LLM before re-verifying, paying the most expensive step to recover from a failure the code did not cause. The short-circuit is therefore economically correct as written. **Lost:** a verifier that 503s for one second during a rolling restart permanently downgrades the run to `unavailable`; the only recovery is the manual Re-verify button (verify-only, cheap — `useFormalizationPipeline.ts:150-170`), and in the queue path no manual recovery exists at all (previous finding). The missing piece is not loop re-entry but a *verify-only* retry: one or two re-calls of `verifyLean` with short backoff on `unavailable`, costing one HTTP round-trip each and no LLM tokens, would recover transient blips at negligible cost.

**Recommendation:** On `unavailable`, retry `verifyLean` alone (not the generation) once or twice with ~1–2 s backoff before returning `unavailable: true`. Keep the generation short-circuit exactly as is.

#### `clearTimeout` skipped on the throw path — abort timer and controller outlive the response by up to 35 s

**Severity:** Low
**Location:** `app/api/verification/lean/route.ts:32-56`
**Move:** Trace the memory lifecycle (move 4)
**Classification:** Micro (per-request timer/closure) / Hot path (request handler)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`clearTimeout(timeout)` runs only after a successful `fetch` (`route.ts:43`); when `fetch` rejects (connection refused — the common down-verifier case, execution-verified to reach this catch) or `res.json()` throws, the response returns immediately from the catch while the 35 s timer and its `AbortController` closure remain live. On a long-lived Node server under the fan-out load above, that is one orphaned timer per failed verify — bounded memory, minor. On serverless it can extend instance lifetime past the response. Per-operation cost is small; flagged because the failure path is exactly the path this change makes common.

**Recommendation:** Move `clearTimeout(timeout)` into a `finally` block.

#### Reload drops the cheap recovery path — `unavailable` sanitized to `none` removes the Re-verify affordance while the generated code persists

**Severity:** Low
**Location:** `app/lib/utils/workspacePersistence.ts:34-37,89,182`, `app/components/features/lean-display/LeanCodeDisplay.tsx:109-119`
**Move:** Work moved to the expensive place (move 3)
**Classification:** Macro (recovery path routing) / Cold-ish path (post-reload user action)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

Persistence maps `"unavailable"` to `"none"` on save and load (execution-verified, fact-check Claim 21) while `leanCode` itself persists (`workspacePersistence.ts:87,180`). The Re-verify button renders only for `leanEdited || invalid || unavailable` (`LeanCodeDisplay.tsx:111`), so after a reload the state is generated-code-present + status `none` + no Re-verify affordance. The user's cheapest recovery from the outage — one verifier round-trip, zero LLM cost — is gone; the visible paths re-run generation (2 LLM calls) to arrive back at the same verify. Not persisting transient verifier state is reasonable; losing the verify-only affordance for unverified persisted code is the cost.

**Recommendation:** Show Re-verify whenever code exists with status `none` (or persist an artifact-side "generated, never checked" marker), so post-reload recovery costs one verify call instead of a regeneration.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Fan-out discards `unavailable`; N× LLM waste, no queue short-circuit, re-runs regenerate | High | `formalizeNode.ts:61`, `useAutoFormalizeQueue.ts:57-139` | High |
| 2 | 35 s timeout unpriced vs serverless duration limits; taxonomy bypassed, full-duration billing | Medium | `route.ts:3,32-40`, `api.ts:120-131` | Medium |
| 3 | Transient 503 forfeits run; missing verify-only retry (short-circuit itself economically correct) | Low | `leanRetryLoop.ts:73-77` | High |
| 4 | `clearTimeout` missed on throw path; timer outlives response 35 s | Low | `route.ts:32-56` | High |
| 5 | Reload sanitizes `unavailable`→`none`, dropping the cheap Re-verify recovery | Low | `workspacePersistence.ts:34-37`, `LeanCodeDisplay.tsx:111` | Medium |

## Endorsements (evidence-gated)

- The unavailable short-circuit exits the retry loop after exactly one generation call and one verification call (out of a possible 3+3), capping per-run LLM and verifier cost when the verifier is down. [fact-check: claim 20 — Verified (executed: `verifyLean` called exactly once; one call each to the generation and verification routes)]
- The not-configured branch returns before any network I/O — zero verifier fetches when `LEAN_VERIFIER_URL` is unset. [fact-check: claim 7 — Verified (executed: detector stub on 127.0.0.1:3100 logged zero incoming requests)]
- Removing the `localhost:3100` default means unconfigured deploys never spend a fetch (or a 35 s timeout) against a dead default address; the doc claiming the default is what went stale, not the behavior. [fact-check: claim 4 — Stale (doc); execution showed no request reaches 3100 with the var unset]
- All three failure modes return well-formed JSON without throwing, so the route's failure paths stay cheap for callers — no exception-driven error handling per unavailable request. [fact-check: claim 5 — Verified (executed: HTTP 200 with structured unavailable body for not-configured and unreachable cases)]
- Manual Re-verify recovery is verify-only: `handleReVerify` → `verifyWithDeps` → `verifyLean` performs one verifier round-trip with no LLM regeneration. [read: app/hooks/useFormalizationPipeline.ts:139-170 → app/lib/formalization/api.ts (verifyLean body, opened in full)]

### Submitted claims (for fact-check intake)

- "On a default Vercel Node.js deployment of this repo (no `maxDuration` export in `app/api/verification/lean/route.ts` and no duration override in the repo), the platform's default function duration limit is below `REQUEST_TIMEOUT_MS = 35_000` ms, so the route's abort timer never fires there and hung-verifier requests surface to `verifyLean` as platform errors (non-JSON), which throw and are recorded as status `invalid` rather than `unavailable`." [unverified — submitted as claim]

## Overall Assessment

The interactive path of this change is economically sound: the no-retry short-circuit is the right call because loop retries pay a full LLM generation to recover from a failure the generated code did not cause, and the execution-verified single-attempt exit plus the pre-fetch not-configured branch make the down-verifier case cheap per run. The performance exposure is concentrated where the new signal is *not* consumed: the decomposition fan-out drops `unavailable` on the floor, so an outage costs R independent roots × two LLM calls each (plus up to 35 s per verify if the verifier hangs), cascades misleading skips, and forces full regeneration on re-run — the single most important fix. Second priority is pricing the deployment environment the route's own comment names: without a `maxDuration` matching the 35 s timeout and non-JSON tolerance in `verifyLean`, duration-limited serverless deploys bypass the entire taxonomy on hangs. No measured baselines exist anywhere in the repo, so all impact estimates here are structural; capturing one queue-run trace (N nodes, wall time, LLM calls) against a stopped verifier would convert findings 1 and 3 into measurable numbers.
