# Architecture Review — corpus-clean (dc6dfb0..4de2b00, app/ only)

**Scope:** `git diff dc6dfb0..4de2b00 -- app/` — the new `app/lib/corpus/` subtree (types, paths, flag, manifest, opfsAdapter, storeAdapter + tests) and the storage-seam change in `app/lib/stores/workspaceStore.ts`. Structural integrity only: dependency direction, responsibility boundaries, module boundaries, layering, interface segregation, substitutability, coupling surface, extension points. `docs/**` read as context (intended structure), not under review.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3) for `corpus-clean`. Findings verified there are taken as foundation and not re-verified: A2 (state blob routes through `paths.ts stateBlobPath()`); the "fresh ArrayBuffer view" comment is Incorrect (fake copies, adapter does not); the contract-suite OPFS run is documented-but-not-run; `workspaceStore.ts:498`'s "seam is typed as CorpusFS" comment mislocates the seam (that line is `StateStorage`; the `CorpusFS` injection is `storeAdapter.createCorpusBackedStorage`); the corpus branch is un-debounced (author-carried to S2/S3).
No `security-review.md` was present in `/workspace/runs/review-arms/e1/corpus-clean/` at write time, so no boundary-label cross-references are made.

Commit: 4de2b00

---

### Dependency Map

```
app/lib/stores/workspaceStore.ts
        │  imports resolveWorkspaceStorage
        ▼
app/lib/corpus/storeAdapter.ts ──────────────► zustand/middleware (StateStorage)   ⟵ inbound-framework dep inside corpus/
        │            │              │
        │            │              └────────► ./flag.ts ──► process.env, window.localStorage (globals, read directly)
        │            └───────────────────────► ./paths.ts (stateBlobPath, STATE_DIR)
        └────────────────────────────────────► ./opfsAdapter.ts (createOpfsCorpusFs — constructed, not injected)
                                                      │
                                                      ▼
                                               ./types.ts (CorpusFS, CorpusError)   ⟵ the intended single seam
        ┌──────────────────────────────────────────────┘
        │
   ./paths.ts, ./manifest.ts ──► types.ts        (no production consumer at this commit;
                                                  reached only from __tests__/)

Also live, and NOT routed through the seam:
app/lib/stores/workspaceStore.ts:533-534 ──► window.localStorage (direct read of the persist key)
app/lib/utils/workspacePersistence.ts     ──► window.localStorage (workspace-v2 / workspace-v1 legacy path)
```

Direction is broadly correct: `types.ts` is the leaf (depends on nothing), adapters depend on it, the store depends on the adapter module. Two edges point the wrong way — `corpus/ → zustand`, and `workspaceStore → localStorage` in parallel with the seam it just installed.

---

### Findings

#### 1. The S1 substrate swap is incomplete: `onRehydrateStorage` reads the persist key straight from `localStorage`, bypassing the seam it sits next to

**Severity:** Structural
**Location:** `app/lib/stores/workspaceStore.ts:528-543` (specifically 533-534), against `storage: createJSONStorage(resolveWorkspaceStorage)` at line 499
**Move:** Trace one execution path (flag ON, first load) end-to-end rather than reading the seam declaration in isolation.
**Confidence:** High
**Evidence:**
```ts
        if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {
          const zustandRaw = localStorage.getItem("workspace-zustand-v1");
          let hasZustandData = false;
          try { hasZustandData = !!(zustandRaw && JSON.parse(zustandRaw)?.state?.sourceText); }
          catch { /* corrupted localStorage — proceed with migration */ }
          if (!hasZustandData) {
            migrateFromV2();
          }
        }
```
**Legibility-target:** A reader should be able to see, from `storeAdapter.ts` alone, every place the persist blob is read or written. They cannot: one reader lives in the store and hard-codes the substrate.

The docstrings frame S1 as "a pure substrate swap" (`storeAdapter.ts:12`), but the store retains a second, substrate-hard-coded reader of the same logical value. With the flag ON the blob lives at `state/workspace-zustand-v1.json` in OPFS, so `localStorage.getItem("workspace-zustand-v1")` returns `null`, `hasZustandData` is `false`, and `migrateFromV2()` fires on **every** rehydrate — re-importing workspace-v2 data over corpus-persisted state each load, silently. The persist key is also duplicated as a bare literal here (line 534) and at line 495, so the two readers can drift independently. This is precisely the seam S4's migration is supposed to build on, which makes it the highest-leverage item in the diff.

**Recommendation:** Route the "do we already have zustand state?" probe through the resolved `StateStorage` (it is async on the corpus branch, so the probe must be awaited inside the rehydrate callback), or move the migration decision behind a `hasPersistedState(): Promise<boolean>` exported from `storeAdapter.ts`. Export the persist name as a constant from one place and use it at both call sites.

---

#### 2. No composition root: `resolveWorkspaceStorage()` takes no parameters, constructs the concrete adapter itself, and fuses flag policy with wiring

**Severity:** Structural
**Location:** `app/lib/corpus/storeAdapter.ts:73-79`
**Move:** Ask what the next sub-task (S2 FSA mirror, S3 worker proxy) has to edit in order to land — if the answer is "the inside of an existing function", the extension point is missing.
**Confidence:** High
**Evidence:**
```ts
/** Selected once when the store's persist middleware initializes. */
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```
**Legibility-target:** Which `CorpusFS` implementation the app runs on should be readable (and changeable) at the wiring layer, without editing corpus internals.

`createCorpusBackedStorage(fs: CorpusFS)` is a genuine, well-typed DI seam — but its only production caller closes it over `createOpfsCorpusFs()` with no parameter, no factory argument, and no registry, so the seam is unreachable from outside the module. The cost is already visible in the test suite: `workspaceStore-corpus-flag.test.ts:63-75` has to hand-build a fake OPFS root and `Object.defineProperty(navigator, "storage", …)` to exercise the flag-ON branch, because it cannot inject a `CorpusFS`. Forward-looking, DD-009 §Write path calls for OPFS-plus-async-FSA-mirror with degraded modes, and §Failure-driven states "Silent fallback is disallowed" — a composed/decorated `CorpusFS` and a status surface both need a place to be assembled, and this three-line `if` is not one. Note also that when the flag is ON and OPFS is unavailable (SSR, unsupported browser), every `getItem` rejects with `{kind:"unavailable"}` and nothing at this layer catches it or degrades.

**Recommendation:** Give the resolver a parameter — `resolveWorkspaceStorage(makeFs: () => CorpusFS = createOpfsCorpusFs)` at minimum — and split flag evaluation from construction so S2 can pass a composite (`createMirroredCorpusFs(opfs, fsa)`) without touching this function. Keep `isCorpusEnabled()` at the call site in `workspaceStore.ts` so the policy decision is visible at the wiring layer.

---

#### 3. Substitutability is asserted in comments but not verified: the contract suite is bound to one implementation, and the two implementations already diverge

**Severity:** Structural
**Location:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-8`; `__tests__/inMemoryCorpusFs.ts:4-6,25-28`; `opfsAdapter.ts:122-125`
**Move:** Check whether the second binding of a "shared contract" actually exists in the tree, not just in the docstring.
**Confidence:** High
**Evidence:**
```ts
/** Runs the shared CorpusFS contract against the in-memory fake (DD-009 S1).
 *  The OPFS adapter is held to the same suite out-of-CI (Playwright); jsdom has
 *  no OPFS so the real adapter cannot run here. */
```
**Legibility-target:** A reader deciding whether it is safe to bind S2-S5 to `CorpusFS` needs to know how many implementations have passed the contract. Today the honest answer is one.

`inMemoryCorpusFs.ts:5-6` states the fake and the adapter "are both asserted against the same shared contract suite … so substitutability (LSP) is verified, not assumed." There is no Playwright config, spec, or dependency anywhere in the repository, so the second binding does not exist in any form — the contract is a single-implementation test suite wearing a contract-suite shape. The divergence this is supposed to catch is already present and confirmed by the fact-check: the fake copies on write (`files.set(normalize(path), bytes.slice())`) while the adapter passes the caller's view straight to `createWritable()` despite the comment claiming otherwise. Aliasing is not among the eight contract cases, so even a wired-up second run would not catch it. Every later sub-task binds to `CorpusFS` on the strength of this guarantee.

**Recommendation:** Add an aliasing case to `corpusFsContract.ts` ("mutating the caller's array after `writeFile` must not change stored bytes"), decide which semantics `CorpusFS` mandates and document it in `types.ts`, and make the adapter conform. Either land the second contract binding (a jsdom-shimmed OPFS harness is enough to exercise the adapter's own logic) or downgrade the docstrings from "verified" to "one implementation covered; OPFS run pending".

---

#### 4. `corpus/` depends on zustand — the substrate module knows about the state-management framework

**Severity:** Coupling
**Location:** `app/lib/corpus/storeAdapter.ts:17` (`import type { StateStorage } from "zustand/middleware"`); the whole file sits under `app/lib/corpus/`
**Move:** Read the import block of each new module and ask which direction each dependency points relative to the subtree's stated purpose.
**Confidence:** High
**Evidence:**
```ts
import type { StateStorage } from "zustand/middleware";
import type { CorpusFS } from "./types";
```
**Legibility-target:** `app/lib/corpus/` should read as "how bytes reach a substrate". A reader should not have to know what zustand is to work in it.

`types.ts:4` declares `CorpusFS` "the single FS seam every later sub-task binds to" — an outbound port. `storeAdapter.ts` is the *inbound* adapter that maps one particular consumer (the zustand persist middleware) onto that port, and it has been placed inside the port's own module. The consequences are ordinary but real: S2-S5 modules importing anything from `corpus/` pull a state-management dependency into their graph; the directory now hosts two unrelated seams (`CorpusFS` and `StateStorage`) which is likely part of why the `workspaceStore.ts:498` comment conflates them (fact-check: mislocated seam); and `createDebouncedLocalStorage`, which has nothing to do with the corpus at all, lives in `corpus/` because it was moved verbatim from the store.

**Recommendation:** Move `storeAdapter.ts` to `app/lib/stores/corpusStorage.ts` (or `app/lib/stores/storage/`), leaving `corpus/` framework-free and containing only `types`, `paths`, `manifest`, `flag`, and substrate adapters. This is a file move plus one import path; doing it before S2 costs almost nothing and gets steadily more expensive as sub-tasks accumulate importers.

---

#### 5. Write-coalescing is fused to the localStorage implementation instead of being a decorator over `StateStorage`

**Severity:** Coupling
**Location:** `app/lib/corpus/storeAdapter.ts:28-49` vs `55-71`
**Move:** Identify the cross-cutting concern in the old implementation and check whether the refactor preserved it as something reusable or copied it into one branch.
**Confidence:** High
**Evidence:**
```ts
export function createDebouncedLocalStorage(): StateStorage {
  let pending: ReturnType<typeof setTimeout> | null = null;
```
**Legibility-target:** "Writes are coalesced at 300ms" should be a property of the storage pipeline that a reader can see applied (or deliberately not applied) to each branch.

The debounce was moved verbatim from `workspaceStore.ts` — correct for preserving the OFF path byte-for-byte (and the characterization test pins that), but it means the 300ms coalescing that exists precisely because the store writes on every keystroke is now available to exactly one of the two branches. The corpus branch issues an OPFS write per `setItem` (fact-check: un-debounced; author-carried to S2/S3), and S2's FSA mirror and S3's worker hop both multiply the cost of that. Because the timer state is captured inside the localStorage factory, the only ways to fix it later are duplicating the logic in `createCorpusBackedStorage` or retrofitting a decorator.

**Recommendation:** Extract `withDebounce(inner: StateStorage, ms: number): StateStorage` and apply it in the resolver to whichever branch is selected. `createDebouncedLocalStorage` then becomes `withDebounce(localStorageAdapter, 300)`, the characterization test still pins OFF-path behavior, and S2/S3 inherit coalescing for free.

---

#### 6. The adapter's path-validation boundary is applied to four of five methods — `readdir` re-implements splitting and skips the C1 traversal rejection

**Severity:** Minor
**Location:** `app/lib/corpus/opfsAdapter.ts:58-71` (`splitPath`) vs `137`
**Move:** After a guard is added at a boundary, enumerate every entry point at that boundary and check each one goes through it.
**Confidence:** High
**Evidence:**
```ts
        const dirs = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
```
(compare `splitPath`, which rejects: ``if (seg === "." || seg === ".." || seg.includes("\\")) { throw new CorpusError({ kind: "io", path, reason: `unsafe path segment: ${seg}` }); }``)

`splitPath`'s comment states the intent well — "paths.ts is the sanitizing choke point, but the adapter must not trust callers to have used it" — and C1 correctly implements rejection rather than resolution. But `readdir` needs no filename component, so it splits inline and inherits none of the guard; `readdir("workspaces/../../x")` reaches `getDirectoryHandle("..")`. In practice OPFS rejects `".."` at the handle API, so the observable behavior is a wrapped `io` error rather than an escape — the problem is structural, not (as far as this review can tell) exploitable: the module's stated invariant holds on some entry points and not others, which is exactly the shape that later reads as "validated" and gets relied on. A security review may weigh the runtime risk differently.

**Recommendation:** Factor the segment check into `safeSegments(path: string): string[]` and have both `splitPath` and `readdir` call it, so the guard is structurally impossible to bypass from inside the adapter.

---

#### 7. Workspace folder identity is derived from the title at path-build time; there is no stored slug and no allocation authority

**Severity:** Minor
**Location:** `app/lib/corpus/paths.ts:36-47, 87-89`; `app/lib/corpus/manifest.ts:37-45`
**Move:** For a new persisted layout, ask what the primary key is and who guarantees it is stable and unique.
**Confidence:** Medium-High (the layout has no production consumer yet, so the consequence is prospective)
**Evidence:**
```ts
export function workspaceDir(slug: string): string {
  return `workspaces/${workspaceSlug(slug)}`;
}
```
**Legibility-target:** Given a workspace, a reader should be able to name the one field that determines its folder, and be sure two workspaces cannot claim the same folder.

`WorkspaceManifest` carries `title` but no `slug`, and `workspaceDir` re-derives the folder name by running `workspaceSlug` over its argument each time. Two consequences follow for S2/S4: renaming a workspace silently relocates its folder (the FSA mirror and any git history see a delete plus an add, not a rename), and distinct titles collapse onto the same directory — `"My Work!"`, `"My Work?"`, and `"my  work"` all slug to `my-work`, so two workspaces would interleave into one folder with no collision detection anywhere in the module. The sanitizer itself is sound; what is missing is the decision that a slug is allocated once, checked for uniqueness, and persisted.

**Recommendation:** Add `slug: string` to `WorkspaceManifest`, allocate it once at workspace creation (with a uniqueness check against `readdir("workspaces")` and a `-2` suffix on collision), and change `workspaceDir(slug)` to assert its argument is already-sanitized rather than re-deriving it. Settle this before S4 writes folders, since changing it afterward is a data migration.

---

#### 8. The manifest codec is fail-loud for top-level fields but silently drops malformed array entries, contradicting its own stated contract

**Severity:** Minor
**Location:** `app/lib/corpus/manifest.ts:89-107`, against the contract at lines 10-16
**Move:** Compare a codec's stated contract against its behavior on each shape of bad input, not just the missing-field case.
**Confidence:** High
**Evidence:**
```ts
  const customArtifactTypeIds: string[] = Array.isArray(raw.customArtifactTypeIds)
    ? raw.customArtifactTypeIds.filter((x): x is string => typeof x === "string")
    : fail("missing or invalid field: customArtifactTypeIds");
```
**Legibility-target:** "Fail loud for content, default only metadata" should be checkable by reading the function; today it holds at the field level and inverts at the element level.

The header states that "A malformed or absent manifest surfaces as a typed `CorpusError` … never a silent default-empty manifest that would masquerade as 'this workspace has no work in it' and mask data loss," and that every content field fails loud. `sources` and `artifacts` apply `.filter(isObject)` before validating, and `customArtifactTypeIds` filters non-strings outright — so a manifest whose entries are all corrupt parses successfully as an empty list, which is the exact failure mode the docstring says is disallowed, one level down. Two smaller notes in the same function: `createdAt`/`updatedAt` fall back to `new Date().toISOString()`, making the codec non-deterministic and non-injectable (unlike `createManifest`, which takes `now`); and lines 101 re-assert `a.type as string` after `fail()` has already narrowed, suggesting `fail`'s `never` return is not being used to full effect.

**Recommendation:** Replace the element filters with per-element validation that calls `fail()` (e.g. `raw.sources.map((s, i) => { if (!isObject(s)) fail(\`sources[${i}] is not an object\`); … })`), and give `parseManifest` a `now` parameter mirroring `createManifest`.

---

#### 9. `flag.ts` fuses release policy with flag mechanism and reads globals directly

**Severity:** Minor
**Location:** `app/lib/corpus/flag.ts:15-31`
**Move:** Ask what S5 ("production default") has to edit, and whether the edit is at a wiring layer or inside a leaf function.
**Confidence:** Medium-High
**Evidence:**
```ts
  if (typeof process !== "undefined" && process.env?.NODE_ENV === "production") return false;

  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
```
**Legibility-target:** "Is the corpus on?" and "is the corpus allowed to be on in this environment?" are two questions; a reader should be able to answer each without reading the other's implementation.

The C2 hard-refuse is the right call for S1 and is well commented. Structurally, though, `isCorpusEnabled()` now answers a policy question and a configuration question in one boolean, reading `process.env`, `window.localStorage`, and their existence guards inline. The result is unmockable except by mutating globals (which the flag tests do), and S5 lands as a deletion inside a leaf predicate rather than a change at the wiring layer. Minor because the fix is small and the current behavior is the safe one; worth doing before S5 rather than during.

**Recommendation:** Split into `corpusFlagRequested(env = process.env, storage = globalThis.localStorage): boolean` and `corpusAllowedInEnvironment(env): boolean`, with `isCorpusEnabled()` as their conjunction. S5 then changes the allow-list function, and tests inject rather than patch globals.

---

#### 10. `paths.ts` and `manifest.ts` have no production consumer; `STATE_DIR` is exported bare, inviting concatenation around the choke point

**Severity:** Informational
**Location:** `app/lib/corpus/paths.ts:82-85`; reachability of `paths.ts`/`manifest.ts` exports
**Move:** Grep every exported symbol of a new module for non-test callers.
**Confidence:** High
**Evidence:**
```ts
export const STATE_DIR = "state";
export function stateBlobPath(name: string): string {
  return `${STATE_DIR}/${safeSegment(name)}.json`;
}
```
**Legibility-target:** A reader should be able to tell which parts of the new subtree are load-bearing today and which are scaffolding for S4.

A2's fix works and the docstring explaining *why* the namespace fork is greppable is genuinely good. Two observations for the record. First, `stateBlobPath` is the only path builder with a production caller — `workspaceManifestPath`, `sourcePath`, `artifactVersionPath`, `artifactMetaPath`, `customTypePath`, `decompositionDir`, `decompositionGraphLayoutPath`, `SETTINGS_PATH`, and all of `manifest.ts` are reached only from `__tests__/`. That is expected for S0 scaffolding, but it means the layout's shape is validated solely against tests written from the same understanding, and it will not be exercised against a real consumer until S4. Second, `STATE_DIR` is exported alongside the builder that uses it; the module's own header says "callers must never hand-concatenate", and an exported directory constant is the most likely way that rule gets broken (`\`${STATE_DIR}/…\``) during S4 migration.

**Recommendation:** Either drop the `export` on `STATE_DIR` and add a `isStateBlobPath(p)` / `listStateBlobs()` helper for S4's reconciliation needs, or note in the header that `STATE_DIR` is exported for greppability only and must not be concatenated.

---

#### 11. The worker error codec is asymmetric — `toWorkerError` exists, the inverse does not

**Severity:** Informational
**Location:** `app/lib/corpus/types.ts:61-75`
**Move:** For any serialization pair, check that both directions are code, not prose.
**Confidence:** High
**Evidence:**
```ts
/** Serializable twin for crossing a worker boundary (S3). Reconstruct with
 *  `new CorpusError(payload.detail, payload.message)` on the main thread. */
```
**Legibility-target:** The worker boundary should have exactly one encode and one decode function, both testable.

The error model is otherwise a strength (see below). The reconstruction step is documented as an instruction rather than provided as a function, so S3 will inline `new CorpusError(payload.detail, payload.message)` at each `onmessage` handler, and the round-trip has no test. Cheap to close now.

**Recommendation:** Add `export function fromWorkerError(p: CorpusWorkerError): CorpusError` next to `toWorkerError`, and a round-trip test over every `CorpusErrorKind` variant.

---

#### 12. `CorpusFS` takes plain `string` paths, so the `paths.ts` choke point is convention-only

**Severity:** Informational
**Location:** `app/lib/corpus/types.ts:112-125`; `paths.ts:15-19`
**Move:** Ask whether a stated invariant is enforced by the compiler, by a runtime guard, or only by a comment.
**Confidence:** High
**Evidence:**
```
 * All builders return POSIX-style paths relative to the corpus root (no leading
 * slash), suitable for passing straight to a `CorpusFS`. The only source of
 * corpus paths is this module — callers must never hand-concatenate, so the
 * traversal guard in `workspaceSlug` is the single choke point that keeps
 * untrusted workspace titles inside `workspaces/`.
```
**Legibility-target:** "The only source of corpus paths is `paths.ts`" should be something a reviewer can verify mechanically rather than by inspection of every call site.

Because every `CorpusFS` method accepts `string`, nothing prevents a future S2-S5 caller from passing a hand-built path; the only backstop is `opfsAdapter.splitPath`'s rejection, which finding 6 shows is not applied uniformly, and which the in-memory fake does not implement at all (so a test-only caller never sees the rejection the production adapter would give). Note also that `workspaceSlug` is not the only guard — `safeSegment` and `safeExt` carry equal weight for ids and extensions — so the header slightly understates its own design.

**Recommendation:** Consider a branded type (`export type CorpusPath = string & { readonly __corpusPath: unique symbol }`) returned by every builder and accepted by `CorpusFS`. The compiler then enforces the choke point at zero runtime cost. If that is judged too heavy, mirror `splitPath`'s validation into `inMemoryCorpusFs` so the fake and adapter agree on what an invalid path is.

---

### What Looks Good

- **`CorpusFS` is correctly narrow, and the ISP reasoning is explicit.** Five methods, bytes-and-paths, async everywhere, with `types.ts:19-22` spelling out that git belongs on a separate `CorpusGit` interface operating *over* a `CorpusFS` so the fake and non-git consumers never stub unused operations. That is the single most important structural decision in the diff and it is right.
- **The error model is a genuine single source of truth.** One discriminated `CorpusErrorKind` union, an `assertNever` exhaustiveness guard, a substrate field on `quota-exceeded` so S2's FSA path reuses the kind instead of minting a parallel one, and `describeCorpusError` as the only place default messages live. Adding a kind is a compile error at every consumer — exactly what DD-009's failure-driven-UI mandate requires.
- **Failure reification at the adapter boundary.** `getRoot` converts a missing `navigator.storage` into `{kind:"unavailable"}` instead of a raw `TypeError`, and `wrap` converts quota into a typed kind rather than the legacy `console.warn` swallow. The contrast with `createDebouncedLocalStorage`'s swallow sits in the same file, which makes the improvement legible.
- **`STATE_DIR`/`stateBlobPath` (A2) is the right shape of fix.** Routing the blob path through `paths.ts` rather than hand-building it in `storeAdapter` makes the S1/S4 namespace fork greppable from one place and subjects the name to the same `safeSegment` sanitization as every other path — and the docstring explains the fork and its retirement condition instead of just moving the string.
- **`createDebouncedLocalStorage` was moved verbatim and pinned by a characterization test.** Extracting the OFF path unchanged, then locking it, is the correct sequencing for a substrate swap.
- **The contract-suite *shape* is right even though only one implementation runs against it.** A `defineCorpusFsContract(label, makeFs)` parameterized over a factory is the correct structure; finding 3 is about the missing second binding and a missing case, not about the design.
- **Sanitizers throw on empty rather than returning `""`.** `workspaceSlug` and `safeSegment` both refuse to let an all-unsafe input silently become an empty segment — the failure mode that turns a path builder into a directory-escape.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Rehydrate reads the persist key from `localStorage`, bypassing the seam; migration re-fires every load when flag is ON | Structural | `workspaceStore.ts:528-543` | High |
| 2 | No composition root: `resolveWorkspaceStorage()` hard-wires `createOpfsCorpusFs()`, no parameter for S2 composition or degraded modes | Structural | `storeAdapter.ts:73-79` | High |
| 3 | Contract suite bound to one implementation; no Playwright harness exists; fake/adapter already diverge on aliasing | Structural | `corpusFs.contract.test.ts`, `inMemoryCorpusFs.ts:25-28`, `opfsAdapter.ts:122-125` | High |
| 4 | `corpus/` imports zustand — inbound framework adapter placed inside the outbound port module | Coupling | `storeAdapter.ts:17` | High |
| 5 | Debounce fused to the localStorage implementation instead of a `StateStorage` decorator; corpus branch cannot reuse it | Coupling | `storeAdapter.ts:28-49` | High |
| 6 | `readdir` re-implements path splitting and skips the C1 traversal rejection | Minor | `opfsAdapter.ts:137` vs `58-71` | High |
| 7 | Folder identity derived from title at build time; no stored slug, no uniqueness authority (rename moves, titles collide) | Minor | `paths.ts:87-89`, `manifest.ts:37-45` | Med-High |
| 8 | Manifest codec fails loud on fields but silently filters malformed array entries; non-deterministic timestamp defaults | Minor | `manifest.ts:89-107` | High |
| 9 | `flag.ts` fuses prod-refuse policy with flag mechanism and reads globals directly | Minor | `flag.ts:15-31` | Med-High |
| 10 | `paths.ts`/`manifest.ts` have no production consumer; bare `STATE_DIR` export invites concatenation | Informational | `paths.ts:82-85` | High |
| 11 | Worker error codec asymmetric — no `fromWorkerError` | Informational | `types.ts:61-75` | High |
| 12 | `CorpusFS` takes plain `string`; choke point is convention-only, and the fake does not mirror the adapter's rejection | Informational | `types.ts:112-125` | High |

---

### Overall Assessment

The *interface* work in this diff is strong and the *wiring* work is not yet finished. `CorpusFS`, the error model, and the folder-layout builders are well-segregated, correctly directed, and unusually well-argued in their own docstrings — S2-S5 have a sound port to bind to, and the A1-A4/C1-C2 fixes each moved the structure in the right direction rather than papering over the finding. What has not landed is the composition layer: `resolveWorkspaceStorage()` is a three-line `if` that constructs its own dependency, and the store still reads the persist key directly from `localStorage` beside the seam it just installed. Findings 1 and 2 are the same underlying gap seen from two sides — there is no single place that owns "which substrate is the app on, and who else is allowed to know."

That gap is worth closing before S2 rather than during it, for a specific reason: S2 (FSA mirror), S3 (worker proxy), and S4 (migration) all need to *compose* over `CorpusFS` and all need somewhere to surface the degraded modes DD-009 explicitly forbids handling silently. Each will otherwise land as another edit inside `resolveWorkspaceStorage`, and finding 1's direct-`localStorage` read is precisely the code S4's migration must build on. Finding 3 compounds this: three sub-tasks are about to bind to a contract that exactly one implementation has ever been run against, and the one known divergence (aliasing) is invisible to the suite as written.

Recommended sequencing before S2 opens: (1) close finding 1 — route the migration probe through the resolved storage and de-duplicate the persist key; (2) parameterize the resolver and split flag policy from construction (finding 2); (3) add the aliasing case and fix the adapter to match (finding 3); (4) move `storeAdapter.ts` out of `corpus/` while it has one importer (finding 4). Findings 5-9 are cheap and can ride along; 10-12 are notes for whoever picks up S4.

---

## Goal-Alignment Note

- **Answered:** Dependency direction across the new subtree and into the store; responsibility boundaries within `corpus/`; the post-fix module-boundary audit (the `paths.ts` choke point holds for the state blob and is greppable, but is convention-only, is bypassed by `readdir`'s inline split, and is weakened by the bare `STATE_DIR` export); layer violations (`corpus/ → zustand`; store → `localStorage` in parallel with the seam); interface segregation (`CorpusFS` is correctly narrow; git correctly excluded); substitutability (the contract suite is still bound to one implementation, no Playwright harness exists in the tree, and the fake/adapter aliasing divergence is untested); coupling surface (zustand inside `corpus/`; `resolveWorkspaceStorage` still hard-wires `createOpfsCorpusFs()` at call time with no parameter, which does not meet S2's composed-fallthrough need); extension points for S2-S5 (composition root, debounce decorator, worker error round-trip, slug identity).
- **Out of scope:** Implementation quality, security exploitability (finding 6 is reported as a boundary-consistency issue; a security reviewer may weight the runtime risk differently), performance and quota behavior under load, API naming conventions, test coverage adequacy beyond what bears on substitutability, and everything in `docs/**` (read as context only). Claims verified by the merged code fact-check were taken as foundation and not re-verified. No `security-review.md` existed at write time, so no boundary labels are cross-referenced.
- **Escalate:** Finding 1 warrants author attention before any further sub-task — with the flag ON, `migrateFromV2()` re-fires on every rehydrate and overwrites corpus-persisted state; this review did not execute the flag-ON path, so confirm the behavior empirically before scoping the fix. Findings 2 and 3 are decisions the author should make deliberately rather than by default: whether the composition root lands now or in S2, and whether the OPFS contract binding is landed or the "verified" language in `inMemoryCorpusFs.ts` and `corpusFsContract.ts` is downgraded to match reality. Finding 7 (slug allocation and storage) is a data-model decision that becomes a migration if deferred past S4.
