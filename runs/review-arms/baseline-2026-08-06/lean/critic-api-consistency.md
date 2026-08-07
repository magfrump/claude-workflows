Commit: c95c9cb

# API Consistency Review — Lean verifier "unavailable" status

**Scope:** `git diff d86d2dc..c95c9cb` (wt-lean worktree, pinned at c95c9cb)
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/lean/fact-check.md` (code-fact-check, 15 claims: 12 verified, 3 mostly accurate)

The changed interfaces: the `POST /api/verification/lean` HTTP response envelope, the `verifyLean` SDK wrapper + `VerifyLeanResult` type in `app/lib/formalization/api.ts`, the new `verifyResultToStatus` mapper, the `VerificationStatus` union (added `"unavailable"`), and `LeanRetryResult.unavailable`.

## Baseline Conventions

- **API route error/result envelopes.** Validation failures return `{ error: string }` with an explicit HTTP status (`route.ts:20-23`, matching `app/api/edit/*`, `app/api/formalization/*`). Structured error detail across the codebase is consistently spelled **`details`** (plural): `callLlm.ts:21-26`, `streamLlm.ts:25-35,164`, `artifactRoute.ts:109,116`, and every `edit/*` and `formalization/*` route (`{ error, details }`). Success/result envelopes for verification are a flat JSON object the client re-parses (`verifyLean` reads `data.valid`/`data.errors`/`data.unavailable`).
- **Result-status pattern.** LLM fallbacks signal degraded state with a flag inside a 200 body (`provider: "mock"`), consumed by the caller — not via HTTP status. The new `unavailable` flag follows this same 200-with-flag idiom (previously `{ valid: true, mock: true }`).
- **Status enums.** `VerificationStatus` members are single lowercase words (`none|verifying|valid|invalid`); per-node `NodeVerificationStatus` is a parallel union (`unverified|in-progress|verified|failed`) bridged by `toNodeVerificationStatus`/`fromNodeVerificationStatus` (`decomposition.ts:28-50`).
- **api.ts helper naming.** Verb-first: `verifyLean`, `generateLean`, `generateSemiformal`, `fetchApi`. Result types use a `<Domain>Result` suffix (`StreamResult`, `LeanRetryResult`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `unavailable` | response/type field | `valid`, `errors`, `mock` (removed) | `app/lib/formalization/api.ts`, `route.ts` | Consistent — single lowercase boolean flag, mirrors `mock` idiom |
| `reason` | response field | none (routes carry prose `error`, not machine codes) | none — searched `app/api/**/route.ts` | New category — establishing a machine-readable code field |
| `detail` | response field | `details` (plural) everywhere | `callLlm.ts:21`, `streamLlm.ts:25-35`, `artifactRoute.ts:109,116`, `app/api/{edit,formalization}/**/route.ts` | **Inconsistent** — codebase uses `details`, this uses `detail` |
| `UnavailableReason` | type | `LoadingPhase`, `VerificationStatus` (string-union aliases) | `app/lib/types/session.ts` | Consistent — string-literal union alias |
| `"verifier-not-configured"` / `-unreachable` / `-error` | enum values | none (no kebab-case code enum exists) | none — searched `app/**/*.ts` | New category — kebab-case reason codes, deliberate |
| `unavailableResponse` | function | `mockResponse` (per-route helper) | `app/api/**/route.ts` | Consistent — `<adjective>Response` local helper |
| `verifyResultToStatus` | function | `verifyLean`, `toNodeVerificationStatus`, `fromNodeVerificationStatus` | `api.ts`, `decomposition.ts:28-50` | Consistent — mapper naming matches `toX`/`fromX` neighbors |
| `VerifyLeanResult` | type | `LeanRetryResult`, `StreamResult` | `leanRetryLoop.ts:22`, `api.ts:25` | Consistent — `Result` suffix |
| `"unavailable"` | enum variant | `none`, `verifying`, `valid`, `invalid` | `app/lib/types/session.ts:1` | Consistent — single lowercase word |

## Findings

#### Producer emits `reason`/`detail`; SDK wrapper drops them

**Severity:** Inconsistent
**Location:** `app/lib/formalization/api.ts:104-132` (consumer) vs `app/api/verification/lean/route.ts:7-14,45-55` (producer)
**Move:** #7 (asymmetry) / #3 (consumer contract)
**Confidence:** High
**Legibility-target:** `VerifyLeanResult` type in `api.ts` — a reader comparing it to the route body sees the field set is narrower.

The route returns `{ valid, unavailable, reason, detail? }` with three distinct `reason` codes (`verifier-not-configured` / `-unreachable` / `-error`) and, for the error case, a `detail` of `HTTP <status>`. But `verifyLean` maps the body to `{ valid, errors, unavailable }` only (`api.ts:127-131`) and `VerifyLeanResult` (`api.ts:104-109`) has no `reason`/`detail` field — so every consumer downstream (`verifyResultToStatus`, `useFormalizationPipeline`, `leanRetryLoop`, the amber banner, the badge) collapses all three offline causes into one undifferentiated `"unavailable"`. The fact-check flagged the same gap (Claim 4: the `unavailable` docstring omits the `verifier-error` case). Consumer impact: the PR added machine-readable diagnostics on the producer side that no consumer can reach — the banner (`LeanCodeDisplay.tsx:132-143`) and tooltip (`VerificationBadge.tsx:11-19`) hardcode "not configured or unreachable" and cannot say *which*, undercutting the PR's own goal of distinguishing offline states. This is a producer/consumer field asymmetry: emit-but-never-read is the mirror of the classic read-but-never-emit bug.

**Recommendation:** Either surface `reason` (and optionally `detail`) through `VerifyLeanResult` and thread it to the banner copy, or, if the single-message UX is intended, drop `reason`/`detail` from the route body so the contract doesn't advertise data no consumer consumes. Pick one so producer and consumer agree.

#### Response field `detail` diverges from codebase-wide `details`

**Severity:** Inconsistent
**Location:** `app/api/verification/lean/route.ts:7,12`
**Move:** #2 (naming) / #4 (error consistency)
**Confidence:** Medium
Precedent: `details` (plural) used in `app/lib/llm/callLlm.ts:21-26`, `app/lib/llm/streamLlm.ts:25-35,164`, `app/lib/formalization/artifactRoute.ts:109,116`, and every `app/api/{edit,formalization}/**/route.ts` error body (`{ error, details }`).
**Legibility-target:** the HTTP response body — a client that already destructures `details` from other routes' errors will miss this one.

Every other structured error payload in the codebase spells the supplementary-info field `details`. This new route introduces `detail` (singular) in the same position. A consumer that has learned the `{ error, details }` shape from the LLM/edit/formalization routes will not find `detail`. The inconsistency is currently masked because `verifyLean` drops the field entirely (see finding above), but the HTTP contract is still public and inconsistent on its face.

**Recommendation:** Rename `detail` → `details` to match the established convention. Trivial and removes a cross-route asymmetry.

#### `"unavailable"` silently collapses to `"unverified"`/`"none"` in the per-node (decomposition) scope

**Severity:** Inconsistent
**Location:** `app/lib/types/decomposition.ts:32-37` (`toNodeVerificationStatus` default branch)
**Move:** #3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** the `VerificationStatus` ↔ `NodeVerificationStatus` bridge — the new enum member has no explicit case here.

The global→node mapper's `switch` has no `case "unavailable"`, so it hits `default: return "unverified"`. In the decomposition workflow, `page.tsx:348-350` pushes a verify result through `setVerificationStatus` → `toNodeVerificationStatus`, and the display reads back via `fromNodeVerificationStatus` (`"unverified"` → `"none"`). Net effect: for a node-scoped verification, an unavailable verifier round-trips to `"none"` — the amber offline banner and the Re-verify affordance (both gated on `verificationStatus === "unavailable"` in `LeanCodeDisplay.tsx:111,132`) never appear, and the node is indistinguishable from never-attempted. The offline UX the PR adds therefore works only in the global scope, not the per-node scope. Contrast: `sanitizeVerificationStatus` collapsing `"unavailable"` → `"none"` *is* intentional and tested (persistence is artifact-state, `persistence.ts:22`); this node-mapper collapse is neither documented nor tested and reads as an unhandled new-variant oversight.

**Recommendation:** Decide whether nodes should carry an offline state. If yes, add a node status (or map `"unavailable"` to a distinct existing one) so the round-trip preserves it; if no, add an explicit `case "unavailable": return "unverified"` with a comment so the swallow is deliberate, mirroring the persistence sanitizer.

#### Icon-rail `statusSummary` not updated for `"unavailable"`

**Severity:** Minor
**Location:** `app/hooks/usePanelDefinitions.tsx:110-116`
**Move:** #3 (consumer contract)
**Confidence:** High
**Legibility-target:** the Lean panel's rail status label.

The `statusSummary` ternary handles `"valid"` → "Verified" and `"invalid"` → "Failed", then falls through to `activeLeanCode ? "Code ready" : "No code yet"`. For `"unavailable"` the rail label reads "Code ready" — no hint the verifier is offline, while the panel body shows the amber banner. A consumer scanning the rail sees a benign "Code ready" for an unchecked proof.

**Recommendation:** Add an `activeVerificationStatus === "unavailable" ? "Verifier offline"` arm to keep the rail consistent with the badge/banner.

#### `unavailable` optionality differs across the three new type surfaces

**Severity:** Informational
**Location:** `api.ts:108` (required) · `leanRetryLoop.ts:27` (optional) · `api.ts:115` (`verifyResultToStatus` param, optional)
**Move:** #7 (asymmetry)
**Confidence:** High
**Legibility-target:** the three type declarations read side by side.

`VerifyLeanResult.unavailable` is required, `LeanRetryResult.unavailable` is optional, and the `verifyResultToStatus` parameter is optional. Each is individually defensible (the retry result only sets it on one branch), but the mixed optionality is a small cognitive tax when reading the cluster.

**Recommendation:** Optional; consider making `LeanRetryResult.unavailable` required with an explicit `false` on the success/invalid returns for uniformity, or leave as-is if the optional-means-false idiom is preferred.

#### `reason` introduces a machine-readable error-code convention with no precedent

**Severity:** Informational
**Location:** `app/api/verification/lean/route.ts:5-14`
**Move:** #2 (naming) / #4 (error consistency)
**Confidence:** Medium
No existing precedent in `app/api/**/route.ts` (searched all route error bodies; they carry prose `error` strings, not machine codes).
**Legibility-target:** future routes that may want machine-readable codes.

The `reason` field with kebab-case coded values is the first machine-readable error/status code in the API surface — everywhere else callers branch on a prose `error` string or a boolean flag. This is establishing a new convention rather than violating an existing one (hence Informational, no-precedent floor). Worth being deliberate: if coded reasons are the intended direction, the kebab-case shape is a reasonable choice to standardize on.

**Recommendation:** No change required. If coded reasons will spread to other routes, record the kebab-case-code convention in a decision note so siblings follow it.

## What Looks Good

- **`unavailable` wins over `valid` in `verifyResultToStatus` (`api.ts:115-118`)** — short-circuiting before `valid` is exactly right; a missing verifier can never read as a passing proof (fact-check Claim 5, verified). This is the core safety property and it's correct.
- **200-with-flag envelope** matches the existing `provider:"mock"` degraded-state idiom rather than inventing a new HTTP-status scheme — consistent with how the codebase already signals fallbacks.
- **`unavailableResponse` / `VerifyLeanResult` / `verifyResultToStatus` naming** all match neighbor conventions (per-route `Response` helper, `Result` suffix, `to/from` mapper style).
- **Persistence deliberately excludes `"unavailable"`** (`persistence.ts:22`, `sanitizeVerificationStatus`) with a test asserting the collapse — the right call for transient-vs-artifact state, and done explicitly.
- **`leanRetryLoop` bail-on-unavailable (`leanRetryLoop.ts:73-77`)** correctly short-circuits the retry loop and returns the generated code with `valid:false` — no wasted retries against an absent verifier.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Route emits `reason`/`detail`; `verifyLean`/`VerifyLeanResult` drop them | Inconsistent | `api.ts:104-132` vs `route.ts:7-55` | High |
| 2 | Response field `detail` diverges from codebase `details` | Inconsistent | `route.ts:7,12` | Medium |
| 3 | `"unavailable"` collapses to `"none"` via node mapper — offline UI absent in decomposition scope | Inconsistent | `decomposition.ts:32-37` | Medium |
| 4 | Icon-rail `statusSummary` not updated for `"unavailable"` | Minor | `usePanelDefinitions.tsx:110-116` | High |
| 5 | `unavailable` optionality differs across three types | Informational | `api.ts:108,115`, `leanRetryLoop.ts:27` | High |
| 6 | `reason` machine-code convention has no precedent | Informational | `route.ts:5-14` | Medium |

## Overall Assessment

The change is broadly consistent with the codebase and the central safety invariant (unavailable never reads as valid) is implemented correctly across the producer, the mapper, and the primary UI. The two Inconsistent findings worth fixing before merge are the producer/consumer field asymmetry (F1: the route advertises `reason`/`detail` that no consumer can reach — either wire them through or drop them) and the `detail`→`details` naming slip (F2, trivial). F3 is the most consequential functionally: the new offline UX silently disappears in the per-node decomposition scope because the `VerificationStatus`→`NodeVerificationStatus` mapper has no case for the new member — this looks like an unhandled-new-variant oversight rather than a deliberate collapse, and it undercuts the PR's goal in half the app's verification paths. All findings are fixable in place; none require rearchitecting. The author surveyed most consumers (badge, banner, pipeline, persistence, retry loop all updated) but missed the node-status bridge and the rail summary.
