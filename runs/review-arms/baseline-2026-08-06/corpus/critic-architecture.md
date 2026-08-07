Commit: 2dc403e

# Architecture Review — Corpus filesystem/OPFS storage layer

**Scope:** `git diff dc6dfb0..2dc403e -- app/` (app/lib/corpus/*, app/lib/stores/workspaceStore.ts + tests)
**Date:** 2026-08-06
**Based on:** fact-check.md (corpus/, 2dc403e) — used as behavioral foundation; not re-verified.
**PR intent:** Corpus FS/OPFS storage layer — adapters, manifest parsing, path safety, v2→v3 migration/rehydration seam.

## Dependency Map

Dependency direction is mostly clean and points the right way:

- `types.ts` is the stable core: `CorpusFS` interface + `CorpusError` kind union. Depends on nothing.
- `opfsAdapter.ts`, `inMemoryCorpusFs.ts` (test) → implement `CorpusFS` (depend on `types.ts`). Volatile substrate detail depends on the stable seam. Correct DIP.
- `manifest.ts`, `paths.ts` → depend only on `types.ts` (manifest) or nothing (paths). Leaf modules.
- `storeAdapter.ts` (composition root) → depends on `CorpusFS` (type), `createOpfsCorpusFs` (concrete, for wiring), `flag.ts`. Selects the substrate; typed on the interface below the factory line. Correct.
- `workspaceStore.ts` → depends on `resolveWorkspaceStorage` (seam) for persist storage, BUT its `onRehydrateStorage` migration block depends directly on `localStorage` (concrete substrate) and `loadWorkspace()` (v2 codec).

The break in the otherwise-clean flow is the last edge: the rehydration/migration logic reaches around the `CorpusFS` seam to a concrete substrate. Everything below `storeAdapter` is substrate-agnostic; the migration seam is not.

## Findings

#### Migration/rehydration seam bypasses the CorpusFS abstraction and can re-fire against the wrong substrate

**Severity:** Structural
**Location:** `app/lib/stores/workspaceStore.ts:528-543`
**Move:** #1 (dependency direction), #4 (layer violation), #7 (content coupling)
**Confidence:** High (mechanism); Medium (real-world blast radius, given default-off/dev-only in S1)

The whole point of `storeAdapter.ts` is stated in its own header: the persist seam is "typed as `CorpusFS` ... so the store [never knows] which adapter it talks to." The `onRehydrateStorage` callback violates exactly that. After the persist middleware hydrates from whatever storage `resolveWorkspaceStorage()` selected (localStorage OR OPFS `state/workspace-zustand-v1.json`), the migration guard probes a hardcoded concrete substrate instead of the seam:

```ts
// workspaceStore.ts:533-539
if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {
  const zustandRaw = localStorage.getItem("workspace-zustand-v1");
  let hasZustandData = false;
  try { hasZustandData = !!(zustandRaw && JSON.parse(zustandRaw)?.state?.sourceText); }
  catch { /* corrupted localStorage — proceed with migration */ }
  if (!hasZustandData) {
    migrateFromV2();
```

When the corpus flag is ON the store's data lives in OPFS, so `localStorage.getItem("workspace-zustand-v1")` is `null` regardless of how much real work sits in the OPFS-backed store. The "do I already have data?" question is asked of the wrong store. The rehydrated state is available as the callback's first argument but is deliberately ignored (`(_state, error) =>`), so the substrate-agnostic signal that WOULD keep this correct is discarded in favor of a direct localStorage read.

Consequence chain (ON mode, second-run-with-work): OPFS holds real work → rehydrate loads it → probe reads localStorage `workspace-zustand-v1` = null → `hasZustandData` false → `migrateFromV2()` fires → `useWorkspaceStore.setState(...)` (workspaceStore.ts:269) overwrites the OPFS-hydrated state with legacy v2 data, and because the active persist seam is now OPFS, that clobbered state is written straight back into `state/workspace-zustand-v1.json`. The seam bypass turns a read-probe mistake into a write-through data-loss path in the corpus the layer was built to protect. This is the "rehydration re-fires migration / bypasses the seam" trap the seam exists to prevent.

Mitigating context (why Structural-but-not-catastrophic today): `flag.ts:5-7` documents corpus mode as default-off, dev-only, and explicitly "no localStorage→corpus migration until S4," and the fresh-ON path starts empty, so the destructive case requires a dev-specific localStorage state (v2 present, localStorage `workspace-zustand-v1` absent) after having done OPFS work. The mechanism is nonetheless live in committed code and is the seam-soundness defect for this layer, not a hypothetical.

**Legibility-target:** The migration guard should decide "already have data" from the seam / rehydrated `_state`, not from a hardcoded `localStorage` read; and migration must not run when the active substrate is not the localStorage generation the v2 path assumes.

**Recommendation:** Gate the whole `onRehydrateStorage` migration block on `!isCorpusEnabled()` (v2→zustand-v1 is a localStorage-only concern until the S4 corpus migration exists), and/or drive the `hasZustandData` decision from the callback's rehydrated `_state` argument rather than re-reading `localStorage` directly. Either restores the seam's "store never knows the substrate" invariant.

#### Cross-generation migration orchestration embedded in the persist config will not scale to S4

**Severity:** Coupling
**Location:** `app/lib/stores/workspaceStore.ts:527-543`, `:251-285`
**Move:** #2 (responsibility boundaries), #8 (extension points)
**Confidence:** Medium

The migration decision (which generation exists, whether to migrate) lives inline in the `persist` options object and already spans two persistence generations (v2 `loadWorkspace()` + zustand-v1). DD-009 plans a third migration at S4 (folder-layout corpus). Each new substrate/generation adds another branch to this inline block, which must learn about every substrate that ever existed — the classic OCP-violating switch that grows with every feature. Because it is wired into the store's construction rather than a dedicated migration module, it cannot be unit-tested or extended without touching the store. Finding 1's substrate-bypass is a symptom of this: migration logic has no home of its own, so it reaches for whatever concrete API is in scope.

**Recommendation:** Extract a `migrateWorkspaceStorage(fs | substrate)` step into a dedicated module keyed on the target substrate, invoked once from `onRehydrateStorage`. S4 then adds a case there rather than editing the store's persist config.

#### `browser-storage-cleared` error kind is declared but unreachable from the manifest codec

**Severity:** Minor
**Location:** `app/lib/corpus/types.ts:48`, `app/lib/corpus/manifest.ts:10-13, 64-66`
**Move:** #5 (interface segregation / surface minimality)
**Confidence:** High

The `CorpusError` kind union exposes `browser-storage-cleared`, and the manifest docstring names it as a possible throw for absent/malformed manifests, but `parseManifest` only ever throws `kind: "io"` (fact-check Claim 4). A declared-but-unraised kind widens the public error surface every exhaustive `switch` must handle without any producer, and the docstring overstates the contract. Low harm now (the union is intentionally forward-looking for S2+ substrates), but the manifest docstring is a legibility defect.

**Recommendation:** Drop `browser-storage-cleared` from the manifest docstring (it is an S2-substrate concern, not a codec concern); keep the union kind if a future substrate will raise it, otherwise defer adding it until a producer exists.

## What Looks Good

- **`CorpusFS` seam design (`types.ts`) is exemplary.** Bytes-and-paths (not strings-and-keys), async everywhere (worker-swap is a transport change, not an interface change), `null`/`[]`/throw contract with no `undefined` leakage, and git deliberately kept OFF the interface (ISP) so the in-memory fake and non-git consumers don't stub unused ops. The design-note comments name the arch-review findings they satisfy — high legibility.
- **Single error-kind source of truth** with `assertNever` exhaustiveness guard and a serializable worker twin (`CorpusWorkerError`) that differs only in transport. Adding a kind forces every consumer to handle it at compile time.
- **Substitutability enforced structurally:** one shared `defineCorpusFsContract` suite runs against both the fake and (out-of-CI) the real OPFS adapter, so the fake can't drift from the adapter (Liskov by construction).
- **Path safety is well-bounded:** `paths.ts` is the sole producer of corpus paths, with `workspaceSlug`/`safeSegment` traversal guards centralized. `storeAdapter.ts` keeps concrete-adapter construction at the composition root and types the seam on `CorpusFS` below it — correct DIP wiring.
- **S1 kept a pure substrate swap:** blob-mode persist (one file under `state/`) with the folder layout built but unused until S4, and the OFF path moved verbatim (characterization-tested). Good staging discipline.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Migration/rehydration seam bypasses CorpusFS, can re-fire against wrong substrate | Structural | `workspaceStore.ts:528-543` | High |
| 2 | Cross-generation migration orchestration embedded in persist config | Coupling | `workspaceStore.ts:527-543,251-285` | Medium |
| 3 | `browser-storage-cleared` kind declared but unreachable from codec | Minor | `types.ts:48`, `manifest.ts:10-13` | High |

## Overall Assessment

The corpus FS layer itself (`types.ts`, `opfsAdapter.ts`, `paths.ts`, `manifest.ts`, `storeAdapter.ts`) is structurally strong — a clean, minimal, substrate-agnostic seam with correct dependency direction, ISP respected, and substitutability enforced by a shared contract suite. The single important structural concern is not in the new modules but at the point where they meet the existing store: the `onRehydrateStorage` migration seam reaches around the `CorpusFS` abstraction to a hardcoded `localStorage` probe (ignoring the rehydrated state it is handed), so when the seam points at OPFS the migration decision is made against the wrong store and can re-fire `migrateFromV2()`, writing legacy data back through the OPFS seam. It is fixable in place (Finding 1's recommendation) and its blast radius is currently bounded by the default-off/dev-only flag, but it is precisely the seam-soundness defect this layer was designed to avoid and should be closed before the flag is ever widened toward S4.
