# Architecture Review — mfc-postfix (`9c9edf5...7f30210`)

**Commit:** 7f30210
**Scope:** `git diff 9c9edf5...HEAD` — `proxy.ts`, `proxy.test.ts`, `app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx` (+ test)
**Date:** 2026-08-18
**Based on:** `code-fact-check-report.md` (k=2, commit 7f30210) — its verdicts are treated as established; this review does not re-verify behavior, it analyzes structure.

**Trust-boundary cross-reference:** security-review outputs exist at `docs/reviews/security-review-s2.md` / `-s3.md`, but their Trust Boundary Map (B1–B6) covers only the DD-009 corpus git-worker pipeline (`gitFs`, `gitCore`, `gitWorker`, OPFS, remote git). None of those labeled boundaries coincide with this diff's module boundaries (the streaming-preview type seam in `app/components/panels` / `app/lib/utils`, or CSP construction in `proxy.ts`). The cross-reference is therefore a **no-op** for the findings below — no finding references a B-label, and none relocates a labeled crossing.

---

## Dependency Map

Two independent structural areas are touched.

**1. Streaming-preview display seam (the architecturally significant change).** Dependency flow:

```
useArtifactGeneration.ts            (producer — honest type)
  streamingJsonPreview: Partial<Record<ArtifactType, unknown>>
        │  parsePartialJson(...) → unknown
        ▼
app/page.tsx:951-994                (the type-laundering seam)
  streamingPreview={ ... as CausalGraphResponse["causalGraph"] | undefined }
  streamingPreview={ ... as BalancedPerspectivesResponse["balancedPerspectives"] | undefined }  (+2 more)
        │  `as` cast mints the false "complete" identity
        ▼
mergeStreamingPreview<T> / useStreamingMerge<T>   (propagator)
  return finalData ?? streamingPreview ?? null   typed as T
        ▼
BalancedPerspectivesPanel, CausalGraphPanel,       (consumers — trust the complete type)
StatisticalModelPanel, PropertyTestsPanel
  dereference required fields: t.between[0], displayMap.synthesis.equilibrium, ...
```

The producer types its output honestly as `unknown`. The `as` cast at `page.tsx:951-994` is the exact point where a partial-JSON parse is given a *complete-artifact* type identity. The generic merge utilities carry that `T` outward unchanged, and four panel modules bind to it as if every required field were present. There is **no error boundary anywhere in `app/`** (fact-check Claim 11), so a dereference of an absent-but-required field unmounts the whole tree, not just the panel.

**2. CSP construction.** `proxy.ts` `buildCsp` is a pure directive-string formatter with a single caller, `proxy()` at `proxy.ts:53`. The diff adds a second parameter whose default reads `process.env.NODE_ENV`, coupling the formatter to ambient module-load-time global state.

The `evidence-search/route.ts` and `evidenceStore.ts` changes are comment-only (fact-check Claims 6–9) and carry no structural weight.

---

## Findings

#### The streaming-preview seam types partial data as a complete artifact, defeating the compiler at the one boundary that most needs it

**Severity:** Structural
**Location:** `app/lib/utils/mergeStreamingPreview.ts:8-16`, `app/hooks/useStreamingMerge.ts:8-16`, `app/page.tsx:951-994`, `app/components/panels/BalancedPerspectivesPanel.tsx:12-13`
**Move:** #3 (module boundary), #6 (substitutability)
**Confidence:** High

`mergeStreamingPreview<T>(finalData, streamingPreview, hasContent): { displayData: T | null }` returns `finalData ?? streamingPreview ?? null` typed as `T`. But `streamingPreview` originates as `unknown` from `parsePartialJson` (`useArtifactGeneration.ts:28,75`) and is cast to the complete artifact type at the seam (`page.tsx:951-994`). The type `T` promises every required field is present; the *value* is a mid-stream partial where any field may be absent. This is a type-level Liskov violation: a partial `T` is substituted where a complete `T` is contractually required, and they are not substitutable — a consumer that dereferences a required-but-absent field (`t.between[0]`) throws `TypeError` (fact-check Claim 11). The damage is not the single crash the diff patches; it is that **the type system actively tells every consumer the guard is unnecessary.** The compiler cannot flag the next unguarded required-field access because, as far as it knows, the field is always there. With no error boundary as a backstop, each such access is a whole-tree crash waiting for the field-arrival ordering that triggers it.

**Recommendation:** Fix the seam, not the field. Model the preview honestly as `DeepPartial<T>` (or normalize/fill-defaults at the seam so the complete type becomes *true*) so the compiler forces a guard at every required-field dereference across all panels. The generic `<T>` silently absorbing partial-ness is the root defect; per-field `&&` guards only paper over instances of it.

#### The false contract is shared by four panels, but only one is guarded — the fix is a spot-patch, not a boundary repair

**Severity:** Coupling
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113`, `CausalGraphPanel.tsx:114`, `StatisticalModelPanel.tsx:44`, `PropertyTestsPanel.tsx:25`
**Move:** #3 (module boundary), #7 (coupling / change propagation)
**Confidence:** High

All four artifact panels consume the same falsely-typed seam (`CausalGraph`, `StatisticalModel`, `PropertyTests` via `useStreamingMerge`; `BalancedPerspectives` via `mergeStreamingPreview`). The `between[0]` crash is one *instance* of a class: any panel that dereferences a required nested field (`.synthesis.equilibrium`, graph edges, model params) without a defensive guard is exposed to the identical whole-tree crash. Because the type says "complete," nothing forces consistency — each panel independently reinvents its own guard discipline, and `BalancedPerspectivesPanel` happens to guard `topic`/`summary`/`perspectives`/`synthesis` but *had missed* `between`. The change-propagation cost is structural: every time any artifact type gains a required field, it becomes a latent crash in up to four panels until someone remembers to guard it in each — the wrong number of places to have to remember.

**Recommendation:** Repair at the seam (previous finding). Treat the shipped `t.between &&` guard as a stopgap and audit the three sibling panels for the same class of unguarded required-field access, or — preferably — let a `DeepPartial<T>` seam make the compiler surface them.

#### Two byte-identical merge utilities each claim to be "the" shared implementation

**Severity:** Coupling
**Location:** `app/lib/utils/mergeStreamingPreview.ts`, `app/hooks/useStreamingMerge.ts`
**Move:** #7 (coupling / DRY), #3 (module boundary)
**Confidence:** High

`mergeStreamingPreview` and `useStreamingMerge` are line-for-line identical (same signature, same `finalData ?? streamingPreview ?? null` body, same docstring asserting "All artifact panels need the same logic"). Neither is actually the single source: three panels use the hook, one uses the plain function. This is two sources of truth for one cross-cutting concern, and it directly obstructs the structural fix the first two findings require — any honest-typing repair to the seam must now be applied in two files or the two copies drift. The `use*` naming on `useStreamingMerge` is also misleading: it calls no React hooks, so it is a plain function wearing a hook's name.

**Recommendation:** Collapse to one utility (keep the non-hook `mergeStreamingPreview`, delete `useStreamingMerge`, repoint the three panels) so the seam has a single place to fix and a single type to correct.

#### `buildCsp` couples a pure formatter to ambient `process.env` via a default parameter

**Severity:** Coupling
**Location:** `proxy.ts:26-32`
**Move:** #2 (responsibility boundary), #7 (coupling to global state)
**Confidence:** High

`allowUnsafeEval: boolean = process.env.NODE_ENV !== "production"` bakes an environment-policy decision into what is otherwise a pure directive-string builder. Three structural consequences: (a) the function is no longer referentially transparent — its output depends on hidden mutable global state, so exercising the default branch requires stubbing a global, which is precisely why that branch sits **untested** (fact-check Claim 5 — Incorrect); (b) the policy "development gets `'unsafe-eval'`" now lives inside a formatting utility rather than at the composition root / config layer where deployment policy belongs; (c) the branch is a fail-open string compare — any `NODE_ENV` other than exactly `"production"` (including unset) yields `'unsafe-eval'` (fact-check Claim 1). Environment decisions read at each call to a leaf formatter is a small instance of the "module depends on information it shouldn't need" erosion pattern.

**Recommendation:** Make `allowUnsafeEval` a required parameter and have the single caller `proxy()` (`proxy.ts:53`) read `NODE_ENV` and pass it explicitly. That keeps `buildCsp` pure and unit-testable across both output shapes without touching globals, and relocates the env-policy decision to the composition boundary.

---

## What Looks Good

- **The producer is typed honestly.** `useArtifactGeneration.ts:28` declares `streamingJsonPreview` as `Partial<Record<ArtifactType, unknown>>` — the partial-ness is truthful at the source. The type lie is introduced *downstream* at the `as` cast, so the fix has a clean anchor: the producer already tells the truth.
- **`hasContent` is correctly injected** into the merge utility rather than hardcoded per artifact type — the one part of the seam that is properly parameterized and reusable.
- **The `between` guard matches the file's existing presence-guard convention** (`&&` short-circuits on `topic`/`summary`/`synthesis`), so the stopgap is at least locally consistent (fact-check Claim 13).
- **CSP directives are otherwise well-structured** — `form-action` set explicitly rather than relying on the `default-src` fallback (fact-check Claim 3) shows deliberate boundary awareness.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Streaming-preview seam types partial data as complete `T`; compiler defeated at the boundary that needs it, no error boundary as backstop | Structural | `mergeStreamingPreview.ts:8-16`, `page.tsx:951-994` | High |
| 2 | False contract shared by 4 panels; fix is a per-field spot-patch leaving siblings exposed to the same crash class | Coupling | `BalancedPerspectivesPanel.tsx:113` + 3 siblings | High |
| 3 | Two byte-identical merge utilities, each claiming to be the shared one; obstructs the seam fix | Coupling | `mergeStreamingPreview.ts`, `useStreamingMerge.ts` | High |
| 4 | `buildCsp` couples pure formatter to ambient `process.env` via default param; policy in the wrong layer, branch untestable/untested | Coupling | `proxy.ts:26-32` | High |

---

## Overall Assessment

This change slightly *degrades* structural integrity even though every changed line is individually correct. The single most important concern is Finding 1: the streaming-preview seam gives partial data a complete-type identity, which converts a compiler that could have caught the whole class of "required field absent mid-stream" crashes into one that guarantees it won't. The diff responds to that class with a one-field runtime guard — a symptom fix that leaves three sibling panels carrying the same latent defect and adds no structural pressure to prevent the next one. All four findings are fixable in place and point to the same small repair: make the seam's type honest (`DeepPartial<T>` or normalize-at-boundary) in a single deduplicated merge utility, add an error boundary as a backstop, and lift the CSP env-policy decision out of the leaf formatter up to its caller. None of the findings coincide with a labeled security trust boundary (B1–B6 are corpus-git only), so no security implication attaches to these structural recommendations.
