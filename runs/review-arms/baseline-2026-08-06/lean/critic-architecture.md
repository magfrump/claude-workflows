Commit: c95c9cb

# Architecture Review — Lean verifier "unavailable" status threading

**Scope:** `git diff d86d2dc..c95c9cb` (wt-lean, pinned at c95c9cb)
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/lean/fact-check.md` (15 claims: 12 verified, 3 mostly accurate)
**PR intent:** Add an `unavailable` verification status threaded route → api → store → UI; short-circuit `unavailable` over `valid`; amber offline UI; bail retries.

## Dependency Map

The change threads a new union member through a clean, one-directional pipeline:

- `lib/types/session.ts` — canonical `VerificationStatus` union (stable core type). Widened with `"unavailable"`.
- `api/verification/lean/route.ts` — server boundary. Emits `{ valid, unavailable, reason, detail? }`.
- `lib/formalization/api.ts` — client HTTP adapter. `verifyLean` → `VerifyLeanResult`; `verifyResultToStatus` centralizes the `{valid,unavailable} → VerificationStatus` mapping.
- `lib/formalization/leanRetryLoop.ts` — consumes `unavailable`, bails the retry loop.
- `hooks/useFormalizationPipeline.ts` — calls `verifyResultToStatus`, writes store.
- `lib/stores/workspaceStore.ts` (imports `VerificationStatus`) + `lib/utils/workspacePersistence.ts` (`sanitizeVerificationStatus`) — persistence layer.
- UI: `LeanCodeDisplay`, `VerificationBadge`, `OutputPanel`, `LeanPanel`, `SessionBanner`.

Dependency direction is correct throughout: UI and adapters depend on the core `VerificationStatus` type; nothing in the core reaches back toward infrastructure. The single mapping function (`verifyResultToStatus`) is the right place for the `unavailable`-wins-over-`valid` invariant and removes the duplicated `result.valid ? "valid" : "invalid"` ternary that previously lived in two hook call-sites. This is a structural improvement, not just an addition.

## Findings

#### Persisted status type is a hand-maintained subset of the canonical union

**Severity:** Coupling
**Location:** `app/lib/types/persistence.ts:22`, `app/lib/utils/workspacePersistence.ts:34-37`
**Move:** #7 (coupling surface) / #3 (module boundary)
**Confidence:** Medium

The persisted shape declares `verificationStatus: "none" | "valid" | "invalid"` as a literal union rather than deriving from `VerificationStatus`, and `sanitizeVerificationStatus` independently repeats the same three-value subset as its return type. Evidence: `persistence.ts:22` — `verificationStatus: "none" | "valid" | "invalid";`. When the canonical union grew to include `"unavailable"`, correctness depended on a human noticing that two other places encode the same subset by hand. It happened to stay coherent this time (the sanitizer intentionally collapses `"unavailable" → "none"`, so the narrow persisted type is *by design* — see fact-check Claim 14), but the coupling means every future union change forces reasoning across three sites with no compiler link between them.

**Recommendation:** Derive the persisted/sanitized subset from the canonical type (e.g. `Exclude<VerificationStatus, "verifying" | "unavailable">`, or type `sanitizeVerificationStatus`'s return as the persisted field's type) so the "transient states are not persisted" rule is expressed once and enforced by the compiler.

#### Server-side `reason`/`detail` vocabulary is dropped at the api adapter

**Severity:** Minor
**Location:** `app/lib/formalization/api.ts:120-132` (vs `app/api/verification/lean/route.ts:4-14`)
**Move:** #3 (module boundary — leaky/lossy narrowing)
**Confidence:** High

The route emits a structured discriminator — `reason: "verifier-not-configured" | "verifier-unreachable" | "verifier-error"` plus optional `detail` (`route.ts:5`, `route.ts:11-13`) — but `verifyLean` collapses the whole thing to a single `unavailable: boolean` (`api.ts:127-131`), so `reason`/`detail` never reach the store or UI. The three UI surfaces show one generic "Verifier offline" message regardless of cause. This is a defensible product choice today, but it means the PR's stated "route → api → store → UI" thread actually terminates at `api`: the richest part of the server contract is defined and then discarded one layer in. If the UI later wants to distinguish "not configured" (actionable: set `LEAN_VERIFIER_URL`) from "unreachable" (transient), the `reason` enum will have to be re-threaded through every layer.

**Recommendation:** Either carry `reason` onto `VerifyLeanResult` (cheap, keeps the contract intact end-to-end even if the UI ignores it for now) or drop the enum from the route to a comment, so the server surface doesn't advertise a discriminator no consumer can observe.

#### SessionBanner status dot has no `unavailable` case — falls through to neutral grey

**Severity:** Minor
**Location:** `app/components/features/session-banner/SessionBanner.tsx:18-23`
**Move:** #8 (extension point / exhaustiveness)
**Confidence:** Medium

`statusDot` special-cases `valid`/`invalid`/`verifying` and lets everything else fall through to the grey `#9A9590` dot (`SessionBanner.tsx:22`). An in-memory session at `"unavailable"` therefore renders the same neutral dot as `"none"`, which is inconsistent with the amber "offline" treatment the PR gives every other surface (`VerificationBadge`, `LeanCodeDisplay`). The falls-through is memory-safe (unavailable is sanitized to none before persistence, so it can only appear pre-save), and amber is already taken by `verifying` here — so the grey default is arguable, not wrong. But it's a consumer of the widened union that the diff did not revisit, so the "amber offline UI" intent is not uniform. The `if`-chain also has no exhaustiveness guard, so the next union member will silently inherit grey too.

**Recommendation:** Add an explicit `"unavailable"` arm (or a `default:`/`never` exhaustiveness check via a `switch`) so the missing case is a compile error rather than a silent grey dot.

## What Looks Good

- **Centralized mapping.** `verifyResultToStatus` (`api.ts:114-118`) is the correct single home for the `unavailable`-precedence invariant; it replaced two duplicated ternaries in `useFormalizationPipeline`. Adding future statuses now touches one function.
- **`unavailableResponse` helper** (`route.ts:6-14`) keeps the three server exit points (`route.ts:28`, `:48`, `:54`) consistent in shape — no drifting response schemas.
- **Retry bail placement** (`leanRetryLoop.ts:71-77`) is at the right layer: the loop, which owns retry policy, decides not to retry an unchecked proof — not pushed up into the hook or down into the adapter.
- **Type-driven threading.** `workspaceStore` imports `VerificationStatus` rather than re-declaring it (`workspaceStore.ts:17,56,74`), so the store automatically picked up the new member.

## Note (out of scope for this diff)

Two verification vocabularies coexist in the codebase: session-domain `VerificationStatus` (`valid`/`invalid`/…) and node-domain `NodeVerificationStatus` (`verified`/`unverified`, used in `leanContext.ts:43`, `useAutoFormalizeQueue.ts:106`, `NodeDetailPanel.tsx:37`). This split predates the diff and is not introduced by it, but it is the kind of divergent status vocabulary a future "unavailable"-for-nodes change would have to reconcile. Informational only.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Persisted status type is a hand-maintained subset of canonical union | Coupling | `lib/types/persistence.ts:22` | Medium |
| 2 | Server `reason`/`detail` vocabulary dropped at api adapter | Minor | `lib/formalization/api.ts:120-132` | High |
| 3 | SessionBanner dot has no `unavailable` case (grey fallthrough) | Minor | `components/features/session-banner/SessionBanner.tsx:18-23` | Medium |

## Overall Assessment

This change **improves** structural health. The new union member flows one direction along the existing pipeline, the mapping logic is centralized rather than scattered, and the core type is the single source consumers import. There are no dependency-inversion, layering, or circular-dependency problems — no Structural findings. The single most important issue is the Coupling item: three sites (`session.ts`, `persistence.ts`, `sanitizeVerificationStatus`) encode overlapping subsets of the same union by hand with no compiler link, so the "which statuses persist" rule must be re-reasoned on every future status change. All findings are fixable in place; none warrant restructuring.
