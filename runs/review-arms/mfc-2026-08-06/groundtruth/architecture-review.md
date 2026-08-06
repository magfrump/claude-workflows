# Architecture Review — post-review fix batch (integration/6.1)

**Commit:** 7f30210
**Scope:** `git diff HEAD~3..HEAD` in `/workspace/external/meta-formalism-copilot` — commits 4d5f743, 2e23824, c0e0a35, merge 7f30210. Files: `proxy.ts`, `proxy.test.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx`, `app/components/panels/BalancedPerspectivesPanel.test.tsx` (new), `app/lib/stores/evidenceStore.ts`, `app/api/evidence-search/route.ts`.
**Date:** 2026-08-06
**Based on:** `code-fact-check-report.md` (k=3 merged; 0 Incorrect, 0 Stale) — taken as foundation, not re-verified.

**Scope check:** trigger confirmed. `buildCsp` is an exported function whose signature gained a parameter (`proxy.ts:26-29`), so category (2) *public APIs* applies. Categories (1) module structure and (3) data models do not; (4) cross-cutting concerns applies weakly — CSP construction is the app's security-header pipeline, and the change makes its output environment-dependent. Review proceeds.

**Trust-boundary cross-reference:** no `security-review.md` exists in the output directory at the time of writing, so the cross-reference step is a no-op. Recommendations that would relocate a security-relevant decision are still tagged **Security implication:** so a later security pass can pick them up.

---

## Dependency Map

**`proxy.ts` (edge / request-interception layer).** Imports `next/server` only. Before this change `buildCsp` was a pure function of its single argument: nonce in, directive string out. It now reads `process.env.NODE_ENV` in its default-argument expression, so the module's most stable unit acquired a dependency on ambient process state. Direction: pure formatter → runtime environment (volatile, implicit). Consumers: `proxy()` at `proxy.ts:53` (the only runtime caller) and `proxy.test.ts` (two call sites, both now passing the flag explicitly).

**`BalancedPerspectivesPanel.tsx` (presentation layer).** Imports `mergeStreamingPreview` (`app/lib/utils/mergeStreamingPreview.ts`), the `BalancedPerspectivesResponse` type (`app/lib/types/artifacts.ts`), plus `ArtifactPanelShell` and `EditableSection`. Direction is correct throughout — presentation depends on utility and type modules, nothing depends on the panel. The changed lines add no new imports; they add a runtime existence check on a field the type declares as required. That mismatch is the interesting edge: the panel depends on a *type contract* that the streaming seam does not actually honour.

**`mergeStreamingPreview<T>` (shared streaming seam).** Signature `(finalData: T | null, streamingPreview: T | null | undefined, hasContent) => { displayData: T | null }`. Four panels bind to it: `BalancedPerspectivesPanel`, `StatisticalModelPanel`, `PropertyTestsPanel`, `CausalGraphPanel` — each typing `streamingPreview?: <FullResponseType> | null`. This is the shared node that finding A1 concerns.

**`evidenceStore.ts` (state layer).** Imports `zustand` + `zustand/middleware` and defines a local `createDebouncedStorage()`. A functionally equivalent adapter already lives at `app/lib/corpus/storeAdapter.ts:33` ("moved verbatim from workspaceStore.ts"). No import edge connects them — the relationship is duplication documented in prose, which is what commit 4d5f743 was editing.

**`app/api/evidence-search/route.ts`.** Comment-only change; no dependency effect.

---

## Findings

### A1 — Panel guard patches a symptom of a streaming seam whose type contract is false

**Severity:** Structural
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`; seam at `app/lib/utils/mergeStreamingPreview.ts:8-16`; contract at `app/lib/types/artifacts.ts:99-102`
**Move:** 6 — verify substitutability (the runtime value does not satisfy the declared type) / 2 — responsibility boundaries
**Confidence:** High
**Evidence:**
> ```tsx
> {t.between && (
>   <div className="flex items-center gap-1 text-xs font-mono text-red-700">
>     <span>{t.between[0]}</span>
> ```
> — `BalancedPerspectivesPanel.tsx:113-115`
>
> ```ts
> export function mergeStreamingPreview<T>(
>   finalData: T | null,
>   streamingPreview: T | null | undefined,
> ```
> — `mergeStreamingPreview.ts:8-10`
>
> ```ts
>     tensions: Array<{
>       between: [string, string];
> ```
> — `artifacts.ts:99-100`
>
> ```tsx
>     const partialTension = { description: "Half-streamed tension" } as unknown as Tension
> ```
> — `BalancedPerspectivesPanel.test.tsx:48`

**Legibility-target:** for-orchestrator-synthesis

The consequence is that every future streaming panel discovers its crash sites in production rather than at compile time, one `TypeError` at a time. `mergeStreamingPreview<T>` hands back a value typed `T` — the *complete* response shape — while the runtime value on the streaming path is a partial-JSON parse where any field may be absent. The type therefore promises more than the producer delivers: a substitutability violation at a seam four panels bind to (`BalancedPerspectivesPanel`, `StatisticalModelPanel`, `PropertyTestsPanel`, `CausalGraphPanel` all declare `streamingPreview?: <FullType> | null`). The new test states this out loud — it can only construct the real-world input by casting through `unknown`, which is the type system reporting that the declared contract excludes a value the system actually produces. Responsibility for normalizing partiality currently sits nowhere, so it defaults to each panel's JSX, discovered empirically. This finding is about the seam, not about the two-line guard, which is a correct and appropriately minimal fix for the crash in front of it.

**Recommendation:** Type the partial path as partial: give `mergeStreamingPreview` a second type parameter or have the `streamingPreview` slot take `DeepPartial<T>`, so `displayData` on the streaming path is partial-typed and the compiler points at the remaining unguarded accesses across all four panels. That converts a class of runtime crashes into type errors at roughly the cost of one utility type. Do this outside this fix batch — the guard shipped here should stand as-is.

---

### A2 — `buildCsp`'s environment default pulls ambient process state into a pure builder

**Severity:** Coupling
**Location:** `proxy.ts:26-32`
**Move:** 1 — dependency direction
**Confidence:** High
**Evidence:**
> ```ts
> export function buildCsp(
>   nonce: string,
>   allowUnsafeEval: boolean = process.env.NODE_ENV !== "production",
> ): string {
> ```
> — `proxy.ts:26-29`

**Legibility-target:** for-author

The consequence is that the module's most stable, most testable unit now behaves differently depending on invisible process state, which is exactly why `proxy.test.ts:12` had to change its existing call to `buildCsp(NONCE, false)` and add a comment about the ambient `NODE_ENV`. A pure string formatter has taken on a dependency on the runtime environment — a dependency pointing from stable toward volatile, and an implicit one, since it lives in a default-argument expression rather than in a parameter the caller can see. `proxy()` at line 53 is the component that legitimately owns "which environment am I serving?", and it is one line away. The test's compensating change is the cost already being paid, and it will be paid again by every future caller that must remember the default exists.

**Recommendation:** Make `allowUnsafeEval` a required parameter and move the `process.env.NODE_ENV !== "production"` read into `proxy()` at the point of use, where environment selection already belongs. `buildCsp` returns to being a pure function of its arguments, and the existing tests get simpler rather than more defensive.

---

### A3 — The exported surface makes a security relaxation caller-selectable in every environment

**Severity:** Coupling
**Location:** `proxy.ts:26-32`, sole runtime caller `proxy.ts:53`
**Move:** 3 — module boundary audit
**Confidence:** High
**Evidence:**
> ```ts
>   const scriptSrc = `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${
>     allowUnsafeEval ? " 'unsafe-eval'" : ""
>   }`;
> ```
> — `proxy.ts:30-32`
>
> ```ts
>   const csp = buildCsp(nonce);
> ```
> — `proxy.ts:53`

**Legibility-target:** for-orchestrator-synthesis

The consequence is that the "dev-only" property the docstring asserts is enforced by a single call site rather than by the module's contract: any future caller of the exported `buildCsp` can pass `true` and obtain an `'unsafe-eval'` production CSP, with nothing in the type system or the tests objecting. The public surface grew from "build the app's CSP" to "build a CSP with the eval restriction optionally lifted", which is a wider reason-to-change than the module needs — the codebase has exactly one CSP policy, and it is not a parameter of the domain. The fact-check flagged the same widening independently. Today the blast radius is nil because there is one caller; the cost is that the invariant is now maintained by convention, and conventions decay quietly at exactly the sites where they matter.

**Recommendation:** Keep `buildCsp` exported for testability but treat the relaxation as internal — either compute the flag inside `proxy()` (see A2) and keep `buildCsp`'s parameter unexported/internal, or add a test asserting `proxy()`'s emitted header contains no `'unsafe-eval'` when `NODE_ENV === "production"`, so the invariant is pinned at the boundary that actually ships. **Security implication:** this recommendation relocates where the eval-policy decision is made; a security reviewer should confirm the chosen location before it moves.

---

### A4 — Boolean flag parameter is control coupling with no room for the second relaxation

**Severity:** Minor
**Location:** `proxy.ts:26-32`
**Move:** 5 — interface segregation / 8 — extension points
**Confidence:** Medium
**Evidence:**
> ```ts
>   allowUnsafeEval: boolean = process.env.NODE_ENV !== "production",
> ```
> — `proxy.ts:28`

**Legibility-target:** for-author

The consequence is a signature that grows by one positional boolean each time a dev-mode carve-out is needed, and positional booleans are the parameter shape readers most reliably misread at the call site (`buildCsp(nonce, false)` says nothing about what `false` means without jumping to the definition). This is control coupling: the caller passes a flag that switches the callee's output shape rather than passing data. It is entirely tolerable at one flag — pragmatic OCP says a single boolean does not warrant an abstraction — so this is noted for the *next* change, not this one. The realistic trigger is a second dev-only relaxation, at which point `(nonce, true, false)` becomes unreadable.

**Recommendation:** If a second relaxation ever appears, switch to a named options object (`buildCsp(nonce, { allowUnsafeEval })`) or a single `mode: "development" | "production"` discriminant rather than adding a second positional boolean. No change warranted now.

---

### A5 — Comment fix stopped one line short, leaving the drifted parity claim that motivated it

**Severity:** Minor
**Location:** `app/lib/stores/evidenceStore.ts:8-9` (changed) and `:17` (unchanged)
**Move:** 2 — responsibility boundaries / duplication of a cross-cutting concern
**Confidence:** High
**Evidence:**
> ```
>  * Persists to localStorage with debounced writes (see the debounced storage
>  * adapter below) to avoid excessive serialization on rapid updates.
> ```
> — `evidenceStore.ts:8-9` (after this change)
>
> ```
> // Debounced localStorage adapter (same pattern as workspaceStore)
> ```
> — `evidenceStore.ts:17` (unchanged)
>
> ```
> // Default: debounced localStorage (moved verbatim from workspaceStore.ts so the
> ```
> — `app/lib/corpus/storeAdapter.ts:33`

**Legibility-target:** for-author

The consequence is small but self-inflicted: commit 4d5f743 removed the cross-file parity claim from the module header precisely because it had drifted, then left the identical claim intact eleven lines down. A reader now gets both the corrected and the stale account of the same fact in one file. The underlying structural note is the one worth carrying forward: `evidenceStore` hand-rolls `createDebouncedStorage()` while the same adapter has already been extracted to `app/lib/corpus/storeAdapter.ts` for `workspaceStore` — a persistence concern duplicated across two stores with no shared edge, which is why prose-level parity claims drift in the first place. Per the partial-scope rule, `storeAdapter.ts` is outside this range and under no obligation to have absorbed `evidenceStore`; this is a pointer, not a missing-work claim.

**Recommendation:** Delete or reword the `(same pattern as workspaceStore)` parenthetical at `:17` in the same spirit as the header fix. Separately, consider having `evidenceStore` import the extracted debounced adapter from `app/lib/corpus/storeAdapter.ts` so the two stores share one implementation instead of a comment.

---

## What Looks Good

- **The panel guard is correctly scoped.** `{t.between && ...}` wraps only the endpoint row and leaves `{t.description}` rendering unconditionally, so a half-streamed tension degrades to partial content instead of vanishing or crashing. The new test asserts exactly that (`BalancedPerspectivesPanel.test.tsx:52-57`). This is the right size of fix for the layer it sits in — the structural note in A1 is about the seam upstream, not about this code.
- **The new test file mocks at module boundaries, not internals.** `EditableSection` and `ArtifactPanelShell` are stubbed via their import paths, so the test binds to the panel's public composition contract rather than its render internals; it will survive refactors of either child.
- **`proxy.test.ts` was updated to pin the environment explicitly rather than inherit it.** Changing the existing assertion to `buildCsp(NONCE, false)` and retitling it "in production" keeps the security-invariant test deterministic under any runner `NODE_ENV`. The added dev-path test also asserts `'unsafe-eval'` appears exactly once — a containment check on the directive string, not just a presence check, which is the stronger property.
- **The `allowUnsafeEval` rationale is documented at the definition** (`proxy.ts:21-24`), extending the file's existing convention of recording each CSP carve-out as a deliberate decision. A2/A3 dispute where the decision should live, not whether it was explained.
- **Both comment fixes make claims locally verifiable.** The `evidence-search/route.ts` comment now derives its bound from named constants on both code paths rather than asserting a single worst case, and the `evidenceStore` header now points at the adapter below it instead of at another file. Replacing cross-file assertions with local ones is the right direction for comment durability — A5 is only that one instance was missed.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| A1 | Panel guard patches a symptom of a streaming seam whose type contract is false | Structural | `BalancedPerspectivesPanel.tsx:113-119`; `mergeStreamingPreview.ts:8-16` | High |
| A2 | `buildCsp`'s environment default pulls ambient process state into a pure builder | Coupling | `proxy.ts:26-32` | High |
| A3 | Exported surface makes a security relaxation caller-selectable in every environment | Coupling | `proxy.ts:26-32`, `proxy.ts:53` | High |
| A4 | Boolean flag parameter is control coupling with no room for the second relaxation | Minor | `proxy.ts:26-32` | Medium |
| A5 | Comment fix stopped one line short, leaving the drifted parity claim | Minor | `evidenceStore.ts:8-9`, `:17` | High |

---

## Overall Assessment

This is a small, well-behaved fix batch and none of the findings should block it. Both substantive changes are minimal, both are tested, and the diff adds no new import edges anywhere — dependency direction is clean at the module graph level in every file touched. What the change surfaces is structural pressure that predates it.

The `buildCsp` signature change is where the batch pays real architectural cost, and it is concentrated rather than diffuse: one function acquired an implicit environment dependency (A2) and a public knob that makes a security property call-site-enforced rather than contract-enforced (A3). Both resolve with the same one-line move — read `NODE_ENV` in `proxy()`, pass the flag down explicitly — which is cheap enough to fold into this batch if the author wants it, and safe to defer if not, given there is exactly one runtime caller today. A4 is a note for the next change, not this one.

A1 is the finding worth escalating past this diff. The two-line guard is correct and should ship unchanged, but it exists because `mergeStreamingPreview<T>` returns the complete type for a value that is a partial parse — a contract that four panels bind to and that the new test could only exercise by casting through `unknown`. That cast is the diff telling you where the real problem is. Fixing it is a utility-type change, not a refactor, and it converts a recurring class of streaming crashes into compile errors. Recommend a follow-up ticket rather than scope creep here.

A5 is a two-word edit with a longer-lived note attached: two stores independently implement the same debounced persistence adapter, which is what made the comment drift possible.

---

## Goal-Alignment Note

- **Answered:** yes — architecture review of HEAD~3..HEAD delivered against the public-API trigger (`buildCsp` signature change), with dependency map, five findings, and severity ordering.
- **Out of scope:** correctness of the CSP directives themselves, whether `'unsafe-eval'` is the right dev-mode remedy, test coverage adequacy, and performance of `buildCsp` — owned by the security, test-strategy, and performance critics respectively. `mergeStreamingPreview.ts`, `storeAdapter.ts`, and the three sibling streaming panels are outside the reviewed range and were read as context only, per the partial-scope rule.
- **Escalate:** A1 — the false type contract at `mergeStreamingPreview` affects four panels and cannot be fixed inside this range; it needs a follow-up ticket. A3 carries a **Security implication:** tag and should be reconciled with the security review if one is produced for this range.
