Commit: c95c9cb

# Security Review — Lean verifier "unavailable" status (branch d86d2dc..c95c9cb)

**Scope:** branch diff d86d2dc..c95c9cb — Lean verification route + client status plumbing + UI states
**Date:** 2026-08-06
**Based on:** /workspace/runs/review-arms/baseline-2026-08-06/lean/fact-check.md (12 verified, 3 mostly-accurate, 0 stale/incorrect)

## Trust Boundary Map

```
B1: [browser POST /api/verification/lean, leanCode]  → [route.ts POST handler]        → [server-side verify request]
B2: [server]                                          → [fetch(${LEAN_VERIFIER_URL}/verify)] → [external Lean verifier service]
B3: [verifier HTTP response / route unavailable envelope] → [verifyLean + verifyResultToStatus] → [client VerificationStatus + UI]
```

B1 is user-controlled Lean source entering the server. B2 is a server-to-service call whose destination is set by the operator-controlled `LEAN_VERIFIER_URL` env var (not user-controlled). B3 is the verifier's verdict (or a synthesized "unavailable" envelope) flowing back to the UI, where the security-critical assumption is that a missing/broken verifier must never render as a passing proof. The central change on this branch replaces a fail-OPEN default with a fail-CLOSED "unavailable" state — an integrity improvement.

## Findings

#### Verifier `reason`/`detail` returned to the client leaks backend infrastructure state

**Severity:** Low
**Location:** `app/api/verification/lean/route.ts:7-14, 29, 48`
**Boundary:** B3
**Move:** #3 (error path) / #6-adjacent (information exposure)
**Confidence:** Medium

The unavailable envelope surfaces `reason` (`verifier-not-configured` | `verifier-unreachable` | `verifier-error`) and, for the error case, `detail: \`HTTP ${res.status}\`` to any caller of the public route. Quoted:

```ts
return NextResponse.json({ valid: false, unavailable: true, reason, ...(detail ? { detail } : {}) });
```

This lets an unauthenticated caller distinguish "no verifier is configured" from "verifier is deployed but returning HTTP 5xx", i.e. it discloses whether `LEAN_VERIFIER_URL` is set and the backend's raw status code. Impact is minor reconnaissance value only — no secret or upstream error body is exposed (the prior code returned the full upstream body verbatim, so this is strictly *less* disclosure than before). Fail direction is safe.

**Recommendation:** Acceptable as-is for this app's threat model. If tightening is desired, keep `reason` for the UI's amber-state logic but drop `detail`/HTTP status from the client payload and log it server-side instead.
Legibility-target: author.

#### `await request.json()` is unguarded — malformed body throws before validation

**Severity:** Informational
**Location:** `app/api/verification/lean/route.ts:17`
**Boundary:** B1
**Move:** #3 (error path)
**Confidence:** High

`const { leanCode } = await request.json();` runs with no try/catch, so a non-JSON body yields an unhandled rejection → generic 500 rather than the route's own 400/unavailable envelope. This is pre-existing (not introduced by this diff) and the failure is a safe reject, not a bypass. Noted only because the diff reworks this handler's surrounding response contract into a deliberate `unavailable` shape that this path does not participate in.

**Recommendation:** Optionally wrap parsing to return the existing `{ error: "leanCode is required" }` 400 on parse failure, for contract consistency. No security urgency.
Legibility-target: author.

## What Looks Good

- **Fail-open → fail-closed is the headline, and it is correct.** The prior `catch` returned `{ valid: true, mock: true }`, meaning a missing/unreachable verifier rendered as a *passing* proof — a genuine integrity flaw. This branch replaces every non-verified path (unconfigured, unreachable, HTTP error, timeout) with `valid:false, unavailable:true`. (B2/B3)
- **`unavailable` short-circuits `valid` at the single mapping chokepoint** (`verifyResultToStatus`, `api.ts:115-118`): `if (result.unavailable) return "unavailable"` before `valid` is consulted, so no downstream consumer can mis-read unavailable as valid. (B3)
- **Retry loop bails on unavailable** (`leanRetryLoop.ts:73-77`) rather than burning `MAX_LEAN_ATTEMPTS` LLM generations against a dead verifier — removes an amplification path (move #8) where a low-cost request triggers repeated expensive downstream generations.
- **Verifier destination is operator-controlled**, not user-controlled: `LEAN_VERIFIER_URL` comes from `process.env`, and `leanCode` is passed as a JSON-serialized body (`JSON.stringify`), so there is no SSRF or injection surface opened at B2 by this change.
- **Persistence sanitizer treats `unavailable` as transient** (`workspacePersistence`), collapsing it to `none` so a stale "offline" verdict is never rehydrated as a trusted artifact state.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `reason`/`detail` leak backend verifier state | Low | B3 | `route.ts:7-14,48` | Medium |
| 2 | Unguarded `request.json()` (pre-existing) | Informational | B1 | `route.ts:17` | High |

## Overall Assessment

Security posture of this change is **positive** — it closes a real fail-open integrity hole (missing verifier previously read as a valid proof) and centralizes the unavailable-over-valid precedence at one auditable function. No High/Critical findings; the two items are a Low info-disclosure (strictly less than the prior behavior) and a pre-existing Informational parse-guard gap. The single most important thing is already done correctly: `unavailable` can never be mistaken for `valid` at any boundary. Safe to merge from a security standpoint.
