# API Consistency Review — mfc-postfix (`git diff 9c9edf5...HEAD`)

**Commit:** 7f30210
**Scope:** `proxy.ts`, `proxy.test.ts`, `app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx`, `app/components/panels/BalancedPerspectivesPanel.test.tsx` (diff `9c9edf5...HEAD`)
**Date:** 2026-08-18
**Based on:** `runs/review-arms/e8-evidence-pipeline/mfc-postfix/code-fact-check-report.md` (k=2 merged code-fact-check, commit 7f30210)

This review evaluates whether the changed public surfaces match conventions already established in the codebase. Behavioral facts (fail-open `!== "production"` default, `between`-index crash, partial-as-complete typing) are taken as established by the fact-check report and not re-verified — the question here is consistency of the *contracts*.

## Baseline Conventions

Surveyed the existing surfaces most analogous to the changed code:

- **Exported builders** (`build*`/`make*`/`create*`): `buildUserMessage`, `buildInputHash`, `buildProvenance`, `buildArtifactEditHandlers`, `buildRelationsFromRefs`, `makeVersion`, `createDebouncedLocalStorage` (`app/lib/**`). `buildCsp` fits the `build<Noun>` family. Parameter ordering is required-first: e.g. `buildInputHash(text, context)`. `buildCsp(nonce, allowUnsafeEval = …)` follows this (required `nonce`, then optional-with-default).
- **Boolean parameters/fields** are overwhelmingly `is*`-prefixed: `isDecompMode`, `isBold`, `isItalic`, `isBusy`, `isRetry`, `isLoading`, `isConfounder`, `isActive`, `isEmpirical` (`app/hooks/**`, `app/components/**`, `app/api/**`). A small verb-prefixed *imperative-toggle* micro-family also exists: `skipHydration` (`workspaceStore.ts:535`, `evidenceStore.ts:362`) and `forceLlm` (`GraphPanel.tsx:216`).
- **Dev-only gating** has exactly one established sibling: `isCorpusEnabled()` (`app/lib/corpus/flag.ts:15-32`). Its production guard is `process.env.NODE_ENV === "production"` returning `false` — **fail-closed** (production *disables* the dev-only capability) and **uncircumventable** (no parameter lets a caller re-enable it in production).
- **Streaming-preview props**: all four streaming panels type the preview as the *complete* artifact type, never `Partial<…>`: `BalancedPerspectivesPanel.tsx:13`, `StatisticalModelPanel.tsx:16`, `CausalGraphPanel.tsx:16`, `PropertyTestsPanel.tsx:13`. `mergeStreamingPreview<T>` (`app/lib/utils/mergeStreamingPreview.ts:8-16`) returns `displayData: T` from a `finalData ?? streamingPreview ?? null` fallback — the partial preview is typed as complete `T`.
- **Artifact response types** (`app/lib/types/artifacts.ts:89-112`) mark every field required — no `?` optional markers, including `tensions[].between: [string, string]`.

## Name-Pattern Audit

The diff introduces exactly one new public name (`allowUnsafeEval`, a parameter). `buildCsp` gained a parameter but its name is unchanged and pre-existing; `streamingPreview`, `between`, and `mergeStreamingPreview` are all pre-existing names carried by context, not introduced here. `scriptSrc` is a private local (skipped per audit rules).

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `allowUnsafeEval` | parameter (boolean) | `skipHydration`, `forceLlm` (verb-prefix imperative toggles); `isRetry`, `isEmpirical` (dominant `is*` family) | `app/lib/stores/workspaceStore.ts:535`, `app/components/panels/GraphPanel.tsx:216`; `app/api/formalization/lean/route.ts:62` | Acceptable — `allow*` prefix is new, but fits the imperative-toggle micro-family and mirrors the `'unsafe-eval'` CSP token it controls (see Finding 3) |
| `buildCsp` (2-arg) | function (modified) | `buildInputHash`, `buildProvenance`, `buildUserMessage` | `app/lib/utils/provenance.ts:43-50`, `app/lib/formalization/artifactRoute.ts:10` | Consistent — `build<Noun>` name unchanged; required-before-optional param order preserved |

## Findings

### 1. `allowUnsafeEval` gate diverges from the codebase's only sibling dev-only gate — fail-open and caller-overridable where the sibling is fail-closed and sealed

**Severity:** Inconsistent
**Location:** `proxy.ts:26-32` (vs. `app/lib/corpus/flag.ts:15-32`)
**Move:** #1 (baseline conventions) / #3 (consumer contract)
**Confidence:** High

The codebase's established pattern for a dev-only capability is `isCorpusEnabled()`: it hard-guards production with `NODE_ENV === "production"` returning the *safe* value, and no caller can override that guard — production is sealed by construction (the comment at `flag.ts:16-20` calls this out explicitly as a security decision). `buildCsp`'s new `allowUnsafeEval` inverts both properties of that contract:

1. **Failure direction is opposite.** The default is `NODE_ENV !== "production"`, so per fact-check Claim 1 the gate is **fail-open**: every value other than the exact string `"production"` (unset, `"staging"`, typos) *enables* `'unsafe-eval'`. The sibling gate fails closed — anything other than `"production"` is handled by the safe branch only for the *enabling* env, and production is the hard stop.
2. **It is caller-overridable.** Because `allowUnsafeEval` is an exported parameter, any future caller can pass `true` and emit `'unsafe-eval'` in a production build — precisely the escape hatch `flag.ts` deliberately refuses to provide. Today the only production caller is `proxy()` at `proxy.ts:53` using the default, so "dev-only" holds *only by call-site discipline*, not by the API's construction. A reader who has learned the `flag.ts` gate will reasonably assume the same production-sealing here and be wrong.

This won't break existing consumers (single default caller), but it establishes a second, contradictory shape for the same "dev-only behavior" concept in the same repo, which is exactly the cognitive-load/foot-gun class this review exists to catch.

**Recommendation:** Make the production-sealing match `isCorpusEnabled`'s contract. Either derive the boolean from a shared helper that hard-guards production (so `true` cannot leak `'unsafe-eval'` into a production build regardless of caller), or, if the caller-selectable seam is intended for tests only, narrow it — e.g. keep the exported `buildCsp(nonce)` sealed and expose the eval-toggling variant under a test-only name — and document that production sealing is not caller-overridable.

### 2. `Tension.between` nullability contract disagrees between producer and consumer; the diff patches the one field that bit rather than the seam

**Severity:** Minor
**Location:** `app/lib/types/artifacts.ts:99-102`, `app/components/panels/BalancedPerspectivesPanel.tsx:110-119`, `app/lib/utils/mergeStreamingPreview.ts:8-16`
**Move:** #8 (nullability contract)
**Confidence:** High

`tensions[].between` is typed as a required `[string, string]` (no `?`), and `streamingPreview` is typed as the *complete* `balancedPerspectives` shape (`BalancedPerspectivesPanel.tsx:13`). But the producer is a partial-JSON stream that can deliver a tension before `between` arrives (fact-check Claims 10, 11), and `mergeStreamingPreview<T>` launders that partial value into a value typed as complete `T` (`mergeStreamingPreview.ts:13`). The type system therefore actively *hides* the nullability the runtime has — indexing `between[0]` type-checks, then crashes mid-stream (Claim 11). The new `{t.between && …}` guard (`:113`) fixes this specific field, but the underlying producer/consumer contract mismatch is unaddressed: every other field in `BalancedPerspectivesResponse` (`artifacts.ts:89-111`) is likewise typed required, and the panel already hand-guards each one (`topic`, `summary`, `perspectives?.`, `synthesis`, `howAddressed?.`) — the guards are a manual stand-in for a nullability contract the types refuse to express. `between` was simply the one field a developer indexed positionally without the guard.

This is an established convention rather than a deviation — all four streaming panels type their preview as complete (`StatisticalModelPanel.tsx:16`, `CausalGraphPanel.tsx:16`, `PropertyTestsPanel.tsx:13`), so this is Minor, not a violation. But it is a repeatable foot-gun: the next positionally-indexed field added to a streamed artifact type will type-check and crash mid-stream exactly as `between` did, with no compiler help.

**Recommendation:** Make the streaming seam's type honest so the compiler forces the guards instead of leaving them to reviewer memory. Type `streamingPreview` (and `mergeStreamingPreview`'s preview arg) as a `DeepPartial<T>` — `Partial<…>` is already used elsewhere in the codebase (`app/hooks/useDecomposition.ts:167`, `app/hooks/useArtifactGeneration.ts:28`) — so that indexing `between[0]` on the preview path is a compile error until guarded. This is a codebase-wide change (all four panels) and belongs in its own PR; at minimum, note the latent risk on the untouched sibling panels.

### 3. `allowUnsafeEval` introduces the `allow*` boolean-prefix; consistent enough with the imperative-toggle family to keep, worth a deliberate note

**Severity:** Informational
**Location:** `proxy.ts:26-28`
**Move:** #2 (naming against the grain)
**Confidence:** High

Precedent: verb-prefix imperative-toggle booleans (`skipHydration`, `forceLlm`) used in `app/lib/stores/workspaceStore.ts:535`, `app/lib/stores/evidenceStore.ts:362`, `app/components/panels/GraphPanel.tsx:216`; dominant `is*` boolean family in `app/api/formalization/lean/route.ts:62`, `app/components/panels/CounterexamplesPanel.test.tsx`.

The codebase's dominant boolean convention is the `is*` predicate prefix, but a verb-prefix *imperative-toggle* micro-family already exists (`skip*`, `force*`) for parameters that command an action rather than describe a state. `allowUnsafeEval` reads as an imperative toggle (it commands the builder to permit a token), so it fits that micro-family, and the name mirrors the exact CSP token `'unsafe-eval'` it controls — which is good for grep-ability. The `allow*` prefix itself is new to the repo, so this is establishing a third verb in the `skip/force/allow` family rather than deviating from an existing one; keep it, but be deliberate that the family now has three members.

**Recommendation:** Keep the name. If the `skip/force/allow` verb-toggle family grows, consider documenting it so future booleans reach for one of the three rather than reinventing.

## What Looks Good

- **Guard symmetry restored.** Before the diff, `between` was the sole positionally-indexed field in the panel rendered without a presence guard while its siblings (`topic`, `summary`, `perspectives`, `synthesis`) were all guarded; the `{t.between && …}` addition (`:113-119`) brings it in line with the file's own convention. (Fact-check Claim 13 notes the commit message calls this "optional chaining" when the siblings actually use `&&` truthiness guards — a wording nit, not a consistency defect.)
- **Test pins the production contract explicitly.** `buildCsp(NONCE, false)` (`proxy.test.ts:9`) decouples the production assertions from ambient `NODE_ENV`, and the new dev-path test (`proxy.test.ts:30-46`) asserts `'unsafe-eval'` stays scoped to `script-src` and appears exactly once — a good symmetric pairing of the two output shapes. (Caveat, not a consistency finding: fact-check Claim 5 marks the *default* env-derivation branch untested; that is a coverage gap, out of scope here.)
- **Parameter ordering** (`nonce` required, `allowUnsafeEval` optional-with-default) matches the required-before-optional convention of the sibling `build*` functions.
- **Comment/behavior alignment** on the evidence-search spread bound (`route.ts:175-180`) and the evidenceStore debounce doc (`evidenceStore.ts:5-9`) — both verified accurate by fact-check (Claims 6, 7) and consistent with sibling patterns (`storeAdapter.ts` debounce).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `allowUnsafeEval` gate fail-open + caller-overridable vs. sealed fail-closed `isCorpusEnabled` | Inconsistent | `proxy.ts:26-32` | High |
| 2 | `Tension.between` nullability contract producer/consumer mismatch; seam unaddressed | Minor | `artifacts.ts:99-102`, `BalancedPerspectivesPanel.tsx:110-119` | High |
| 3 | `allow*` boolean prefix is new; fits imperative-toggle family, note deliberately | Informational | `proxy.ts:26-28` | High |

## Overall Assessment

The diff is largely consistent with the codebase's conventions — `buildCsp` keeps its `build<Noun>` name and required-first parameter order, and the `between` guard restores symmetry with the panel's own defensive pattern. The one finding with real consumer weight is #1: the repo already has a dev-only gating contract (`isCorpusEnabled`, fail-closed and sealed), and `buildCsp`'s new exported `allowUnsafeEval` parameter introduces a contradictory shape for the same concept — fail-open and caller-overridable — so "dev-only" holds only by call-site discipline rather than by construction. That is fixable in place by routing the production-sealing through a shared guard. Finding #2 is a latent type-seam the codebase carries everywhere (partial-JSON typed as complete); the diff correctly patches the field that crashed but the honest-typing fix is a separate, codebase-wide change. Nothing here breaks existing consumers.
