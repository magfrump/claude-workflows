Commit: 7f30210

# Architecture Review — postfix changeset (9c9edf5..7f30210)

**Scope:** `git diff 9c9edf5..7f30210` in worktree `wt-postfix` (meta-formalism-copilot)
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/postfix/fact-check.md` (9 claims: 7 verified, 2 unverifiable)
**PR intent:** Post-review-fix — CSP dev `unsafe-eval` gating, bounded evidence spreads, streaming crash guard, evidenceStore debounced persistence documentation.

## Trust-Boundary Cross-Reference scan

Security-reviewer outputs exist at `docs/reviews/security-review-s2.md` and `security-review-s3.md`, but both cover the DD-009 corpus subsystem (S2 FSA mirror, S3 git worker), not this changeset. The module-boundary findings below (evidenceStore ↔ storeAdapter) do not coincide with any trust boundary labeled in those reviews, so the cross-reference is a **no-op** here. The CSP change in `proxy.ts` is trust-boundary-relevant but is security-reviewer's domain; no security-review file exists for this diff, so no boundary label is available to reference.

## Dependency Map

Four independent changes, no shared state:

- `proxy.ts` — `buildCsp(nonce, allowUnsafeEval?)` gains an optional second parameter defaulting to `process.env.NODE_ENV !== "production"`. `proxy()` (the composition point) calls it with one arg; `proxy.test.ts` passes an explicit boolean. This is a cross-cutting concern (CSP header pipeline) and a public-API signature widening.
- `evidenceStore.ts` — docstring-only edit. The store defines its own inline `createDebouncedStorage()` (lines 20–41) and does **not** import from `lib/corpus/storeAdapter.ts`. `workspaceStore.ts:26,533` imports `resolveWorkspaceStorage` (→ `createDebouncedLocalStorage`) from the corpus module. Dependency direction: `workspaceStore → lib/corpus`; `evidenceStore → (nothing; self-contained copy)`.
- `BalancedPerspectivesPanel.tsx` — null-guard bug fix (`t.between &&`) plus a new isolated test. No public surface change.
- `evidence-search/route.ts` — comment-only edit.

## Findings

#### Debounced-storage logic duplicated across evidenceStore and storeAdapter
**Severity:** Coupling
**Location:** `app/lib/stores/evidenceStore.ts:20-41` vs `app/lib/corpus/storeAdapter.ts:37-58`
**Move:** #7 (coupling surface) / #2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** the 300ms debounce contract is expressed twice and must be kept in sync by hand.

Two near-verbatim copies of the debounced-localStorage adapter exist: `createDebouncedStorage()` in evidenceStore and `createDebouncedLocalStorage()` in storeAdapter (both same 300ms timer, clear-on-write, quota-catch). The inline comment at `evidenceStore.ts:17` still asserts "same pattern as workspaceStore," making the parity a stated invariant that nothing enforces — if the corpus copy changes its debounce interval or error handling, evidenceStore silently diverges. Note this duplication is **pre-existing**, not introduced by this diff (the diff only edits comments), and there is a real reason for the copy: importing `createDebouncedLocalStorage` from `storeAdapter.ts` would make evidenceStore depend on the entire `lib/corpus` module (that file's top-level imports pull in `opfsAdapter`, `mirrorFs`, `flag`, `paths`), coupling a simple evidence store to the DD-009 corpus subsystem. So the copy is the lesser of two evils as things stand — but the right fix removes both problems.

**Recommendation:** Extract the debounced-localStorage adapter into a neutral shared location (e.g., `lib/stores/debouncedStorage.ts` or `lib/utils/`) and have both storeAdapter and evidenceStore import it. This kills the duplication without dragging the corpus module graph into evidenceStore. Low priority; fold into the next storage touch.

#### buildCsp default parameter reads process.env, coupling a pure function to ambient environment
**Severity:** Minor
**Location:** `app/lib/../proxy.ts:26-32`
**Move:** #2 (responsibility boundaries) / #7 (coupling surface)
**Confidence:** High
**Legibility-target:** `buildCsp`'s output now silently depends on `NODE_ENV` unless the caller knows to override it.

`buildCsp` was a pure function of `nonce`; it now has an implicit dependency on `process.env.NODE_ENV` baked into the default argument. This is the standard, pragmatic Next.js idiom and is well-mitigated: the parameter is explicit and overridable, the production caller uses the default, and the test suite pins `false` (`proxy.test.ts:12`) precisely to decouple from ambient env. The only structural cost is that a reader of `buildCsp(nonce)` at the call site can't see that environment drives the result. This is acceptable as-is; flagged for completeness, not action.

**Recommendation:** None required. Optionally, resolve `allowUnsafeEval` once at the `proxy()` composition root and pass it explicitly, keeping `buildCsp` a total function of its arguments — but the current form is a reasonable convention.

#### Docstring/inline-comment drift on the workspaceStore-parity claim
**Severity:** Informational
**Location:** `app/lib/stores/evidenceStore.ts:8-9` vs `:17`
**Move:** #2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** the file now describes its persistence relationship to workspaceStore two different ways.

This diff's docstring edit removed "the same debounced write pattern as workspaceStore" and replaced it with "see the debounced storage adapter below" — a genuine accuracy improvement, since evidenceStore's copy is now independent of workspaceStore's (which routes through storeAdapter). But the inline comment at line 17 still reads "same pattern as workspaceStore," so the file half-retracts the parity claim and half-keeps it.

**Recommendation:** Update line 17 to match the docstring's framing (a local copy that happens to mirror the workspace debounce), or remove the parity reference entirely. Cosmetic; do it alongside the extraction above.

## What Looks Good

- The `allowUnsafeEval` gating is textbook: a single conditional interpolation into `scriptSrc`, `'unsafe-eval'` provably confined to `script-src` (test asserts exactly one occurrence), production caller untouched. The change widens the public surface minimally and the "why" comment (`proxy.ts:19-23`) documents the environment rationale.
- The evidence-spread comment (`route.ts:178-180`) tightens a bound claim to match the actual call graph (fact-check Claim 1 verified: override ≤25, LLM ≤15) — no structural change, just honest documentation.
- The `t.between &&` guard is the correct minimal fix at the correct layer (presentation guarding against partial-stream data), and it ships with an isolated regression test that mocks child components rather than reaching into them — clean boundary.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Debounced-storage logic duplicated (pre-existing) | Coupling | `evidenceStore.ts:20-41` vs `storeAdapter.ts:37-58` | Medium |
| 2 | buildCsp default reads process.env | Minor | `proxy.ts:26-32` | High |
| 3 | Docstring/inline-comment drift on parity claim | Informational | `evidenceStore.ts:8-9,17` | High |

## Overall Assessment

This changeset maintains the system's structural integrity — all four changes are localized, correctly layered, and improve documentation honesty. There are **no Structural (blocking) findings**. The only architectural observation with lasting weight is the pre-existing duplication of the debounced-storage adapter between `evidenceStore` and the corpus `storeAdapter`; the diff's docstring edit actually surfaces it by dropping the (no-longer-quite-true) workspaceStore-parity claim, but leaves a residual inline comment asserting parity. The single most useful follow-up is to extract the debounced adapter to a neutral shared module so both stores share one contract without evidenceStore taking on a dependency on the DD-009 corpus subsystem — but that is a Coupling-tier cleanup, not a gate on this fix.
