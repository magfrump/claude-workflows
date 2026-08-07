Commit: 7f30210

# API Consistency Review — postfix (git diff 9c9edf5..7f30210)

**Scope:** `app/api/evidence-search/route.ts`, `app/components/panels/BalancedPerspectivesPanel.{tsx,test.tsx}`, `app/lib/stores/evidenceStore.ts`, `proxy.{ts,test.ts}`
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/postfix/fact-check.md` (9 claims: 7 verified, 2 unverifiable, 0 incorrect/stale)

## Baseline Conventions

- **Exported functions:** plain camelCase verb-noun (`buildCsp`, `proxy`, `mergeStreamingPreview`, `resolveWorkspaceStorage`). Params are positional; optional behavior is expressed via defaulted params, not options objects (small arity).
- **Boolean flags:** two families coexist — state predicates use `is*` (`isLoading`, `isActive`, `isEmpirical`, `isRetry`, `isDecompMode`); imperative/capability flags use an action prefix (`forceLlm` in `GraphPanel.tsx:216`, `skipHydration` in `workspaceStore.ts:535` / `evidenceStore.ts:362`). No options-object wrapping for single flags.
- **Panel optional-field rendering:** every optional/streamed field is wrapped in a truthiness or length guard before it is dereferenced — `{displayMap.topic && …}`, `{(p.supportingArguments?.length ?? 0) > 0 && …}`, `{(displayMap.tensions?.length ?? 0) > 0 && …}` (all in `BalancedPerspectivesPanel.tsx`; mirrored across `CounterexamplesPanel.tsx`, `CausalGraphPanel.tsx`, `GraphPanel.tsx`).
- **Store persistence contract:** zustand `persist` with `createJSONStorage` over a debounced localStorage adapter, `skipHydration: true`, SSR guard `typeof window !== "undefined"` (established in `workspaceStore.ts:530-535` and `corpus/storeAdapter.ts`; followed by `evidenceStore.ts:355-362`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `allowUnsafeEval` | parameter (boolean) | `forceLlm`, `skipHydration`, `isRetry` | `app/components/panels/GraphPanel.tsx:216`, `app/lib/stores/workspaceStore.ts:535`, `app/api/formalization/lean/route.ts:62` | Consistent — capability flag using an action-verb prefix (`allow*`), matching the `force*`/`skip*` family for imperative flags; not a state predicate, so `is*` correctly not used |

No other new public names introduced. The panel change adds no new prop/type (the `t.between` guard is an internal JSX conditional). `evidenceStore.ts` is a comment-only edit. `proxy.test.ts` / `BalancedPerspectivesPanel.test.tsx` add only test-internal identifiers.

## Findings

No Breaking, Inconsistent, or Minor findings. Two Informational notes.

#### buildCsp signature extension is backward-compatible

**Severity:** Informational
**Location:** `proxy.ts:26-35`
**Move:** #3 (consumer contract), #6 (versioning impact)
**Confidence:** High

`buildCsp(nonce)` gained a second parameter `allowUnsafeEval` with a default (`process.env.NODE_ENV !== "production"`). Because the parameter is defaulted and appended at the end, the sole production caller `proxy()` (`proxy.ts:53`, `const csp = buildCsp(nonce)`) is unaffected — verified as the only non-test caller via `git grep buildCsp`. This is a textbook backward-compatible additive change: no version bump warranted, no consumer migration needed. The production default preserves prior behavior exactly (prod builds emitted no `'unsafe-eval'` before, and still don't).

**Recommendation:** None. Additive optional parameter is the right shape at this arity.

#### between-tuple render guard matches the panel's established optional-field pattern

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-120`
**Move:** #8 (nullability contract)
**Confidence:** High

The static type `Tension.between: [string, string]` (`app/lib/types/artifacts.ts:99-102`) marks the tuple required, but partial-JSON streaming can deliver a tension object before `between` arrives — so the runtime nullability contract is looser than the type. The new `{t.between && (…)}` guard resolves the type-vs-runtime mismatch and is consistent with how every sibling optional field in this same component is rendered (`displayMap.topic &&`, `p.supportingArguments?.length`, `displayMap.synthesis &&`). `t.description` correctly remains outside the guard since it renders independently. Consumer-facing behavior (the component prop contract) is unchanged; this is a pure crash-safety hardening.

**Recommendation:** None for consistency. Optionally, `between?` could be marked optional in the `artifacts.ts` type so the runtime reality is reflected in the contract and the test's `as unknown as Tension` cast becomes unnecessary — but that is a type-accuracy nicety, not an API-consistency issue.

## What Looks Good

- **buildCsp extension** follows the codebase's defaulted-positional-param convention rather than introducing an options object — appropriate for arity 2.
- **`allowUnsafeEval` naming** correctly distinguishes a capability flag (`allow*`) from state predicates (`is*`), matching the existing `forceLlm`/`skipHydration` precedent.
- **`'unsafe-eval'` scoping** — interpolated only into `scriptSrc`, never into other directives; the dev-CSP test pins exactly one occurrence, protecting the invariant (`proxy.test.ts:44`).
- **evidenceStore comment** dropped the "same pattern as workspaceStore" cross-reference in favor of pointing at the in-file adapter — reduces coupling of the doc to an external file while the underlying pattern remains genuinely identical (fact-check Claims 4-5, both Verified).
- **Test determinism** — pinning `buildCsp(NONCE, false)` decouples the production-CSP assertions from ambient `NODE_ENV`, a strict improvement.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | buildCsp signature extension backward-compatible | Informational | `proxy.ts:26-35` | High |
| 2 | between-tuple render guard matches panel pattern | Informational | `BalancedPerspectivesPanel.tsx:113-120` | High |

## Overall Assessment

Fully consistent with the codebase's API conventions. The only signature change (`buildCsp` gaining a defaulted boolean) is backward-compatible, correctly named against the existing `force*`/`skip*` flag family, and leaves its sole production caller untouched. The panel guard reuses the exact optional-field pattern already pervasive in that component and its siblings. The store and evidence-search changes are comment-only or internal and introduce no new consumer-facing surface. No breaking changes, no naming inconsistencies, no error/pagination/nullability contract drift. Nothing to fix.
